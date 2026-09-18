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
| .files[]
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
    # C5 — aucun « [TODO » dans un fichier publié
    (select($f.todo == true and $f.draft != true)
     | [$f.file, "C5 : le fichier est publié et contient « [TODO » ; le marqueur impose draft: true"])
    ,
    # C6 — vocabulaire de la stack, avec la tolérance des brouillons
    (select($f.role == "case")
     | (($f.front_matter.context.stack // [])[] as $t
        | select($vocabulary | index($t) | not)
        | select(($f.draft == true and ($t | startswith("[TODO"))) | not)
        | [$f.file, "C6 : technologie « \($t) » absente de data/stack.yaml"]))
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
  printf '%s: rubriques, marqueurs [TODO et vocabulaire de la stack vérifiés.\n' "$script_name"
  exit 0
fi

while IFS=$'\t' read -r file gap; do
  [[ -n $file ]] || continue
  checks_report "content/$file" "$gap"
done <<< "$report"
exit 1
