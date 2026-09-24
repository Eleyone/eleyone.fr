#!/usr/bin/env bash
# C3 — parité FR/EN (AD-10, FR-20, FR-23). Tout fichier de content/ a son jumeau dans l'autre langue,
# leurs clés non traduites sont égales, et leurs rubriques se correspondent une à une.
#
# Les titres des rubriques sont traduits : le rapprochement passe par data/rubrics.yaml, que le
# manifeste expose sous « rubrics » (décidé le 18/09/2026). Deux rubriques de même rang doivent être
# les deux écritures de la même entrée de cette liste.
#
# La parité s'applique **aussi aux brouillons** (AD-10) : un `[TODO` n'excuse pas un écart entre les
# deux langues, puisque les deux fichiers doivent porter le même marqueur.
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=parity
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

manifests=$(checks_manifests "${CHECK_WORK_ROOT:-build/work}")
mapfile -t manifest_files <<< "$manifests"
((${#manifest_files[@]} == 2)) \
  || checks_die "parité : ${#manifest_files[@]} manifeste(s) trouvé(s), deux attendus (une langue chacun)."

# Le programme jq compare les deux manifestes et affiche une ligne « fichier<TAB>écart » par écart.
# Il ne sort jamais en erreur : le décompte des lignes décide du code de sortie.
read -r -d '' program <<'JQ' || true
# Les clés qu'une traduction ne doit pas faire bouger. Ce qui n'y figure **pas** y est absent
# volontairement : « label » nomme un poste qui n'est pas une société et se traduit — « Parcours
# antérieur » en français, « Earlier career » en anglais —, donc elle n'entre pas dans cette liste
# (AD-18, 24/09/2026). « company », elle, y reste, pour que « Mister Auto » ne devienne jamais
# « MisterAuto » d'un seul côté. Même raison pour « role », « period » et « location », traduites
# depuis l'origine.
def untranslated($role):
  {
    case:      ["number", "group", "order", "draft", "position"],
    position:  ["company", "via", "company_url", "setup", "track", "order", "draft"],
    education: ["kind", "order", "draft"],
    home:      ["identity"],
    page:      ["email", "linkedin", "github"]
  }[$role] // [];

def context_keys($role): if $role == "case" then ["setup", "stack"] else [] end;

def material($entry):
  [($entry.front_matter.live_material // [])[] | {id: .id, type: .type, status: .status}];

def entries($manifest):
  [$manifest.files[] | select(.lang != "")];

def show: if . == null then "absente" else tojson end;

def titles($entry): [($entry.headings // [])[] | select(.level == 2) | .text];

. as [$fr, $en]
| ($fr.rubrics // []) as $rubrics
| (entries($fr)) as $frf
| (entries($en)) as $enf
| (
    # 1. ce qui empêche tout rapprochement : erreur du manifeste, translationKey absent ou en double
    ([$frf[], $enf[]] | map(select(.error != null)) | .[] | [.file, .error])
    ,
    ([$frf[], $enf[]] | map(select(.error == null and (.translationKey // "") == ""))
       | .[] | [.file, "translationKey absent : aucun rapprochement FR/EN possible"])
    ,
    ([$frf, $enf] | .[] | group_by(.translationKey) | .[] | select(length > 1)
       | .[] | [.file, "translationKey « \(.translationKey) » porté par plusieurs fichiers de la même langue"])
    ,
    # 2. fichiers sans jumeau
    ( ($enf | map(select(.error == null) | .translationKey)) as $enkeys
      | $frf[] | select(.error == null and (.translationKey // "") != "")
      | select(.translationKey as $k | $enkeys | index($k) | not)
      | [.file, "aucun fichier anglais ne porte le translationKey « \(.translationKey) »"])
    ,
    ( ($frf | map(select(.error == null) | .translationKey)) as $frkeys
      | $enf[] | select(.error == null and (.translationKey // "") != "")
      | select(.translationKey as $k | $frkeys | index($k) | not)
      | [.file, "aucun fichier français ne porte le translationKey « \(.translationKey) »"])
    ,
    # 3. paires : rôle, clés non traduites, matériel vivant, rubriques
    ( $frf[] | select(.error == null and (.translationKey // "") != "") as $f
      | ($enf[] | select(.translationKey == $f.translationKey and .error == null)) as $e
      | (
          (if $f.role != $e.role then
             [$e.file, "rôle « \($e.role) » côté anglais, « \($f.role) » côté français"]
           else empty end)
          ,
          (untranslated($f.role)[] as $key
           | select(($f.front_matter[$key] // null) != ($e.front_matter[$key] // null))
           | [$e.file, "clé non traduite « \($key) » : \($f.front_matter[$key] | show) en français, \($e.front_matter[$key] | show) en anglais"])
          ,
          (context_keys($f.role)[] as $key
           | select((($f.front_matter.context // {})[$key] // null) != (($e.front_matter.context // {})[$key] // null))
           | [$e.file, "clé non traduite « context.\($key) » : \((($f.front_matter.context // {})[$key]) | show) en français, \((($e.front_matter.context // {})[$key]) | show) en anglais"])
          ,
          (select($f.role == "case" and material($f) != material($e))
           | [$e.file, "live_material : \(material($f) | tojson) en français, \(material($e) | tojson) en anglais (identifiants, types et statuts, dans le même ordre)"])
          ,
          # Titres : les deux langues en ont autant. Hors d'un cas, la parité s'arrête là — les titres
          # d'une page simple sont libres, et data/rubrics.yaml ne porte que les rubriques d'un cas
          # (portée de C4 ; constat de la revue de la PR n° 37).
          (select((titles($f) | length) != (titles($e) | length))
           | [$e.file, (if $f.role == "case" then "rubrique(s)" else "titre(s) de niveau 2" end) as $mot
              | "\((titles($e) | length)) \($mot) en anglais, \((titles($f) | length)) en français"])
          ,
          (select($f.role == "case" and ((titles($f) | length) == (titles($e) | length)))
           | range(0; titles($f) | length) as $i
           | ((titles($f)[$i]) as $frt
              | (titles($e)[$i]) as $ent
              | ($rubrics | map(select(.fr == $frt)) | first) as $expected
              | if $expected == null then
                  [$f.file, "rubrique « \($frt) » absente de data/rubrics.yaml"]
                elif $expected.en != $ent then
                  [$e.file, "rubrique \($i + 1) : « \($ent) » en anglais, « \($expected.en) » attendu en face de « \($frt) »"]
                else empty end))
        ))
  )
| @tsv
JQ

report=$(jq -r -s "$program" "${manifest_files[0]}" "${manifest_files[1]}") \
  || checks_die "parité : lecture des manifestes impossible."

if [[ -z $report ]]; then
  printf '%s: parité FR/EN vérifiée.\n' "$script_name"
  exit 0
fi

while IFS=$'\t' read -r file gap; do
  [[ -n $file ]] || continue
  checks_report "content/$file" "$gap"
done <<< "$report"
exit 1
