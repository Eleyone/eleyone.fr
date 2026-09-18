#!/usr/bin/env bash
# C4, C5 et C6 (AD-10, FR-6, FR-8, FR-26), lus dans les manifestes du rendu de travail.
#
#   C4  les rubriques d'un cas viennent de data/rubrics.yaml, dans l'ordre de cette liste, et un cas
#       n'a pas de titre plus profond que ### (décidé le 18/09/2026) : un cas groupé descend chaque
#       titre d'un niveau, et un ###### y produirait un <h7>, balise qui n'existe pas
#   C5  aucun fichier publié ne contient « [TODO », où que ce soit dans le fichier
#   C6  la stack d'un cas ne cite que des technologies de data/stack.yaml
#
# Portée (AD-10) : C4 s'applique **aussi aux brouillons**, C5 ne vise que les fichiers publiés, et C6
# tolère une valeur « [TODO… » dans un brouillon. C4 et C6 ne portent que sur les cas.
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=content
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

manifests=$(checks_manifests "${CHECK_WORK_ROOT:-build/work}")

read -r -d '' program <<'JQ' || true
# Écriture attendue d'une rubrique dans la langue du manifeste.
def rubric_names($rubrics; $lang): [$rubrics[] | .[$lang]] | map(select(. != null));

def titles($entry): [($entry.headings // [])[] | select(.level == 2) | .text];

.lang as $lang
| (.rubrics // []) as $rubrics
| (rubric_names($rubrics; $lang)) as $known
| (.stack // []) as $vocabulary
| [.files[] | select(.error == null and .lang != "" and .role == "case")] as $cases
| (
  # C8 — deux cas d'un même groupe ne partagent pas un « order » (un manifeste, une langue)
  ( $cases | map(select(.front_matter.order == null))
    | .[] | [.file, "C8 : clé order absente ; elle donne la place du cas dans son groupe"] )
  ,
  ( $cases | map(select(.front_matter.order != null))
    | group_by([.front_matter.group // "", .front_matter.order]) | .[] | select(length > 1)
    | . as $doublon | .[]
    | [.file, "C8 : order \(.front_matter.order) déjà pris dans le groupe « \(.front_matter.group // "sans groupe") » par \($doublon | map(.file) | join(", "))"] )
  ,
  ( .files[]
| select(.error == null and .lang != "")
| . as $f
| (
    # C4 — rubriques d'un cas : connues, dans l'ordre de la liste, sans doublon ; titres pas trop profonds
    (select($f.role == "case")
     | (titles($f)[] as $t | select($known | index($t) | not)
        | [$f.file, "C4 : rubrique « \($t) » absente de data/rubrics.yaml"])
       ,
       ((titles($f) | map(. as $t | $known | index($t)) | map(select(. != null))) as $ranks
        | select($ranks != ($ranks | sort))
        | [$f.file, "C4 : rubriques dans le désordre : \(titles($f) | join(" ; ")) ; ordre attendu : \($known | join(" ; "))"])
       ,
       (titles($f) | group_by(.) | .[] | select(length > 1) | .[0] as $t
        | [$f.file, "C4 : rubrique « \($t) » écrite deux fois"])
       ,
       (($f.headings // [])[] | select(.level > 3)
        | [$f.file, "C4 : titre de niveau \(.level) « \(.text) » : un cas n'a que des rubriques ## et des sous-titres ###, sans quoi un cas groupé produirait un <h7>"]))
    ,
    # C7 — matériel vivant : déclaré ⇔ placé, sans doublon, préfixé par son type, source présente
    #      pour un élément « ready » (la source vient du manifeste, Hugo étant seul à voir assets/)
    (select($f.role == "case")
     | (($f.material // [])[] as $m
        | select(($f.placed // []) | index($m.id) | not)
        | [$f.file, "C7 : élément « \($m.id) » déclaré mais jamais placé dans le texte"])
       ,
       (($f.placed // [])[] as $id
        | select((($f.material // []) | map(.id)) | index($id) | not)
        | [$f.file, "C7 : identifiant « \($id) » placé dans le texte mais absent de live_material"])
       ,
       (($f.placed // []) | group_by(.) | .[] | select(length > 1) | .[0] as $id
        | [$f.file, "C7 : identifiant « \($id) » placé deux fois dans le même cas"])
       ,
       (($f.material // []) | group_by(.id) | .[] | select(length > 1) | .[0].id as $id
        | [$f.file, "C7 : identifiant « \($id) » déclaré deux fois"])
       ,
       (($f.material // [])[] as $m
        | select($m.type != "" and (($m.id | startswith($m.type + "-")) | not))
        | [$f.file, "C7 : identifiant « \($m.id) » non préfixé par son type : « \($m.type)- » attendu (AD-6)"])
       ,
       (($f.material // [])[] as $m
        | select(["diagram", "video", "snippet", "callout"] | index($m.type) | not)
        | [$f.file, "C7 : élément « \($m.id) » de type « \($m.type) » ; attendu diagram, video, snippet ou callout (AD-6)"])
       ,
       (($f.material // [])[] as $m
        | select($m.status == "ready" and $m.source_found == false)
        | [$f.file, (if $m.type == "video" then "C7 : vidéo « \($m.id) » en status ready sans url" else "C7 : élément « \($m.id) » en status ready sans source : \($m.source) est absent" end)])
    )
    ,
    # C5 — aucun « [TODO » dans un fichier publié
    (select($f.todo == true and $f.draft != true)
     | [$f.file, "C5 : le fichier est publié et contient « [TODO » ; le marqueur impose draft: true"])
    ,
    # C8 — groupe : la clé « group » est le dossier parent direct, et deux cas du groupe n'ont pas le
    #      même « order » dans une langue (chaque manifeste ne porte qu'une langue)
    (select($f.role == "case")
     | ($f.file | split("/")) as $parts
     | (if ($parts | length) == 3 then $parts[1] else null end) as $folder
     | (
         (select($folder != null and (($f.front_matter.group // "") != $folder))
          | [$f.file, "C8 : clé group « \($f.front_matter.group // "absente") » alors que le dossier est « \($folder) »"])
         ,
         (select($folder == null and (($f.front_matter.group // "") != ""))
          | [$f.file, "C8 : cas hors d'un dossier de groupe mais porteur d'une clé group « \($f.front_matter.group) »"])
         ,
         (select(($parts | length) > 3)
          | [$f.file, "C8 : cas rangé trop profond ; un cas groupé vit dans cases/<groupe>/ (AD-4)"])
       ))
    ,
    # C6 — vocabulaire de la stack, avec la tolérance des brouillons
    (select($f.role == "case")
     | (($f.front_matter.context.stack // [])[] as $t
        | select($vocabulary | index($t) | not)
        | select(($f.draft == true and ($t | startswith("[TODO"))) | not)
        | [$f.file, "C6 : technologie « \($t) » absente de data/stack.yaml"]))
  ))
)
| @tsv
JQ

report=""
while IFS= read -r manifest; do
  [[ -n $manifest ]] || continue
  lines=$(jq -r "$program" "$manifest") || checks_die "content : lecture de $manifest impossible."
  [[ -z $lines ]] || report+="$lines"$'\n'
done <<< "$manifests"

if [[ -z ${report//[$'\n']/} ]]; then
  printf '%s: rubriques, marqueurs [TODO, vocabulaire, matériel vivant et groupes vérifiés.\n' "$script_name"
  exit 0
fi

while IFS=$'\t' read -r file gap; do
  [[ -n $file ]] || continue
  checks_report "content/$file" "$gap"
done <<< "$report"
exit 1
