#!/usr/bin/env bash
# C4, C5 et C6 (AD-10, FR-6, FR-8, FR-26), lus dans les manifestes du rendu de travail.
#
#   C4  les rubriques d'un cas viennent de data/rubrics.yaml, dans l'ordre de cette liste, et un cas
#       n'a pas de titre plus profond que ### (décidé le 18/09/2026) : un cas groupé descend chaque
#       titre d'un niveau, et un ###### y produirait un <h7>, balise qui n'existe pas
#   C5  aucun fichier publié ne contient « [TODO », où que ce soit dans le fichier
#   C6  la stack d'un cas ne cite que des technologies de data/stack.yaml
#   C16 « En bref » : au plus 3 phrases et 400 points de code par langue
#   C18 règles du format : title ≤ 70, valeurs de setup, type et status, concordance du numéro
#       de fichier avec number et le translationKey, encart complet (FR-6, décidé le 18/09/2026),
#       et les noms de variables de .env.example et de ci/legal-placeholder.env (jamais leurs valeurs)
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
    ,
    # C16 — « En bref » : au plus 3 phrases et 400 points de code (définition de la liste des contrôles)
    (select($f.role == "case")
     | ($f.front_matter.summary // "") as $summary
     | select($summary != "" and (($f.draft == true and ($summary | startswith("[TODO"))) | not))
     | (($summary | explode | length)) as $length
     | ([$summary | scan("[.!?…](?:\\s|$)")] | length) as $sentences
     | select($length > 400 or $sentences > 3)
     | [$f.file, "C16 : « En bref » de \($length) points de code et \($sentences) phrase(s) ; au plus 400 et 3"])
    ,
    # C18 — règles du format d'un cas
    (select($f.role == "case")
     | (
         (($f.front_matter.title // "") as $title
          | select($title != "" and (($f.draft == true and ($title | startswith("[TODO"))) | not))
          | select(($title | explode | length) > 70)
          | [$f.file, "C18 : title de \($title | explode | length) caractères ; 70 au plus"])
         ,
         (($f.front_matter.context.setup // "") as $setup
          | select($setup != "" and (($f.draft == true and ($setup | startswith("[TODO"))) | not))
          | select(["employee", "freelance", "agency", "ton-pote-le-geek"] | index($setup) | not)
          | [$f.file, "C18 : setup « \($setup) » ; attendu employee, freelance, agency ou ton-pote-le-geek"])
         ,
         (($f.material // [])[] as $m
          | select(["planned", "ready"] | index($m.status) | not)
          | [$f.file, "C18 : status « \($m.status) » de l'élément « \($m.id) » ; attendu planned ou ready"])
         ,
         # numéro du nom de fichier, clé number et suffixe du translationKey : les trois concordent.
         # « capture » ne produit rien quand le nom ne suit pas le format (vérifié : jq ne s'arrête
         # pas) ; le nom hors format est donc signalé pour lui-même, sinon il passerait en silence
         # (constat de la revue de la PR n° 41).
         (($f.file | [match("case-(?<n>[0-9]+)-"; "g")] | if length == 0 then "" else .[0].captures[0].string end) as $from_name
          | select($from_name == "")
          | [$f.file, "C18 : nom de fichier hors format ; attendu case-NN-<nom-court>.<langue>.md"])
         ,
         (($f.file | [match("case-(?<n>[0-9]+)-"; "g")] | if length == 0 then "" else .[0].captures[0].string end) as $from_name
          | select($from_name != "")
          | (
              (select($from_name != ($f.front_matter.number // ""))
               | [$f.file, "C18 : numéro « \($from_name) » dans le nom de fichier, number « \($f.front_matter.number // "absent") »"])
              ,
              (select($from_name != (($f.translationKey // "") | ltrimstr("case-")))
               | [$f.file, "C18 : numéro « \($from_name) » dans le nom de fichier, translationKey « \($f.translationKey // "absent") »"])
            ))
         ,
         # encart « Contexte mission » complet sur un cas publié (FR-6, décidé le 18/09/2026)
         (["company", "role", "period"][] as $key
          | (($f.front_matter.context // {})[$key] // "") as $value
          | select(($value | tostring | length) == 0 or (($f.draft != true) and ($value | tostring | startswith("[TODO"))))
          | [$f.file, "C18 : context.\($key) \(if ($value | tostring | length) == 0 then "absent ou vide" else "encore en [TODO dans un cas publié" end) (FR-6)"])
         ,
         ((($f.front_matter.context // {}).stack // []) as $stack
          | select(($stack | length) == 0)
          | [$f.file, "C18 : context.stack absente ou vide (FR-6)"])
       ))
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

# C18 — les deux fichiers d'environnement portent exactement les noms attendus (AD-9, AD-24). Seuls
# les noms sont lus et affichés : une valeur ne sort jamais d'ici.
legal_names="HUGO_LEGAL_HOST_ADDRESS HUGO_LEGAL_HOST_CONTACT HUGO_LEGAL_HOST_NAME HUGO_LEGAL_PUBLISHER_ADDRESS HUGO_LEGAL_PUBLISHER_CONTACT HUGO_LEGAL_PUBLISHER_NAME HUGO_LEGAL_PUBLISHER_REGISTRATION"
env_names() { # $1 = fichier ; les noms de variables, triés
  grep -oE '^[A-Z][A-Z0-9_]*=' "$1" | tr -d '=' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//'
}
check_env_file() { # $1 = fichier, $2 = noms attendus
  local found
  [[ -f $1 ]] || { checks_report "$1" "C18 : fichier absent"; return 1; }
  found=$(env_names "$1") || { checks_report "$1" "C18 : lecture impossible"; return 1; }
  [[ $found == "$2" ]] || { checks_report "$1" "C18 : variables « $found » ; attendu « $2 »"; return 1; }
  return 0
}
env_rc=0
check_env_file ci/legal-placeholder.env "$legal_names" || env_rc=1
check_env_file .env.example "$(printf '%s GITEA_TOKEN GITEA_URL GITEA_USER' "$legal_names" | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//')" || env_rc=1

if [[ -z ${report//[$'\n']/} ]] && ((env_rc == 0)); then
  printf '%s: rubriques, marqueurs [TODO, vocabulaire, matériel vivant, groupes, encarts et format vérifiés.\n' "$script_name"
  exit 0
fi

while IFS=$'\t' read -r file gap; do
  [[ -n $file ]] || continue
  checks_report "content/$file" "$gap"
done <<< "$report"
exit 1
