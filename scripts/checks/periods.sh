#!/usr/bin/env bash
# C25 (AD-18, FR-2, NFR-10) : la période d'un cas est comprise dans celle de son poste, dans chaque
# langue, lue dans les manifestes du rendu de travail (story 10.9).
#
# La période reste le texte de l'auteur : rien n'est calculé ni affiché, le contrôle compare des
# bornes. Il lit, insensible à la casse, mois en toutes lettres et dans la langue du manifeste :
#
#   fr   « mois AAAA – mois AAAA »    « depuis mois AAAA »    « AAAA »    « AAAA – AAAA »
#   en   « Month YYYY – Month YYYY »  « since Month YYYY »    « YYYY »    « YYYY – YYYY »
#
# Le séparateur est le tiret demi-cadratin entouré d'une espace de chaque côté, celui des fichiers
# d'aujourd'hui. Une année seule vaut de janvier à décembre ; « depuis » / « since » n'a pas de
# borne de fin. L'intervalle d'années « AAAA – AAAA » (story 10.10 : la période du cas 01 donnée
# par Arnaud, « 2025 – 2026 ») va du 1er janvier de la première au 31 décembre de la seconde ; une
# forme mêlée, « mois AAAA – AAAA » ou « AAAA – mois AAAA », reste illisible. Inclusion : début du cas ≥ début du poste **et** fin du cas ≤ fin du poste, une fin
# ouverte valant l'infini — un cas en cours sous un poste terminé déborde donc. Un intervalle dont
# la fin précède le début est refusé. **Toute autre forme est refusée**, jamais laissée passer :
# un contrôle qui sauterait ce qu'il ne sait pas lire passerait au vert sur une période fausse
# (règles tranchées par le constat A3 de la revue de spec de la story 10.9).
#
# Ce qui est lu :
#   - la période de **chaque poste**, qu'un cas le désigne ou non : `docs/format-parcours.md` dit
#     qu'une période de poste a l'une de ces formes, et c'est ici qu'elle se vérifie ;
#   - la période de chaque cas qui porte une clé `position` (`context.period`), confrontée à celle
#     du poste de **même translationKey dans le même manifeste**, donc de sa langue.
#
# Ce qui est sauté, et pourquoi :
#   - une valeur « [TODO » dans un **brouillon** (règle des brouillons d'AD-10, checks_tolerated) :
#     le cas 03 porte aujourd'hui « [TODO: période] », et le site doit passer. Dans un fichier
#     publié, le même marqueur est une forme illisible, refusée ici comme C5 la refuse déjà ;
#   - un cas sans `position`, ou dont le poste n'existe pas dans sa langue : le rattachement est la
#     règle de C19, qui refuse le cas publié dans les deux situations. C25 ne compare que ce qui
#     est rattaché ;
#   - la comparaison d'un cas dont le poste a une période illisible : le poste est déjà refusé pour
#     elle, et le cas le dit en nommant les deux fichiers, sans conclure sur des bornes inconnues.
#
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=periods
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

manifests=$(checks_manifests "${CHECK_WORK_ROOT:-build/work}")

read -r -d '' program <<'JQ' || true
def months($lang):
  if $lang == "fr" then ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
                         "septembre", "octobre", "novembre", "décembre"]
  elif $lang == "en" then ["january", "february", "march", "april", "may", "june", "july",
                           "august", "september", "october", "november", "december"]
  else [] end;

def since_word($lang): if $lang == "fr" then "depuis" elif $lang == "en" then "since" else null end;

# Rang d'un mois écrit en toutes lettres, de 1 à 12, ou null. La comparaison passe par « test » avec
# le drapeau « i » d'Oniguruma, qui replie aussi les lettres accentuées (« Décembre », « AOÛT ») :
# « ascii_downcase » ne les replierait pas. Les noms de mois ne portent aucun caractère spécial
# d'expression régulière.
def month_rank($lang; $name):
  [months($lang) | to_entries[] | select(.value as $m | $name | test("^" + $m + "$"; "i")) | .key + 1]
  | first // null;

# Une borne est un nombre de mois depuis l'an zéro : année × 12 + mois.
def bound($lang; $name; $year):
  month_rank($lang; $name) as $m
  | if $m == null then null else ($year | tonumber) * 12 + $m end;

# Une période lue : {"start": n, "end": n ou null pour une fin ouverte}, ou null si illisible.
def parse_period($lang):
  (if type == "string" then . elif type == "number" then tostring else "" end) as $text
  | since_word($lang) as $since
  | if $since == null then null
    elif ($text | test("^[0-9]{4}$")) then
      ($text | tonumber) as $y | {start: ($y * 12 + 1), end: ($y * 12 + 12)}
    elif ($text | test("^[0-9]{4} – [0-9]{4}$")) then
      ($text | capture("^(?<y1>[0-9]{4}) – (?<y2>[0-9]{4})$")) as $c
      | {start: (($c.y1 | tonumber) * 12 + 1), end: (($c.y2 | tonumber) * 12 + 12)}
    elif ($text | test("^[^ ]+ [0-9]{4} – [^ ]+ [0-9]{4}$")) then
      ($text | capture("^(?<m1>[^ ]+) (?<y1>[0-9]{4}) – (?<m2>[^ ]+) (?<y2>[0-9]{4})$")) as $c
      | bound($lang; $c.m1; $c.y1) as $start
      | bound($lang; $c.m2; $c.y2) as $end
      | if $start == null or $end == null then null else {start: $start, end: $end} end
    elif ($text | test("^" + $since + " [^ ]+ [0-9]{4}$"; "i")) then
      ($text | capture("^[^ ]+ (?<m>[^ ]+) (?<y>[0-9]{4})$")) as $c
      | bound($lang; $c.m; $c.y) as $start
      | if $start == null then null else {start: $start, end: null} end
    else null end;

def todo_value: (. // "") | tostring | startswith("[TODO");
def tolerated($entry; $value): $entry.draft == true and ($value | todo_value);
def show: if . == null then "absente" elif type == "string" then . else tojson end;

def forms($lang):
  if $lang == "en" then "« Month YYYY – Month YYYY », « since Month YYYY », « YYYY » ou « YYYY – YYYY »"
  else "« mois AAAA – mois AAAA », « depuis mois AAAA », « AAAA » ou « AAAA – AAAA »" end;

# Une période lue mais dont la fin précède le début n'est pas une période.
def readable($p): $p != null and ($p.end == null or $p.end >= $p.start);

.lang as $lang
| [.files[] | select(.error == null and .lang != "" and .role == "position")] as $positions
| [.files[] | select(.error == null and .lang != "" and .role == "case")] as $cases
| (
    # 1. la période de chaque poste se lit
    ( $positions[]
      | . as $p
      | ($p.front_matter.period) as $value
      | select(tolerated($p; $value) | not)
      | ($value | parse_period($lang)) as $period
      | select(readable($period) | not)
      | [$p.file, "C25 : période « \($value | show) » illisible ; formes lues : \(forms($lang))"] )
    ,
    # 2. chaque cas rattaché : sa période se lit et tient dans celle de son poste
    ( $cases[]
      | . as $c
      | ($c.front_matter.position // "") as $key
      | select(($key | tostring | gsub("^\\s+|\\s+$"; "")) != "")
      | ([$positions[] | select(.translationKey == $key)] | first) as $p
      | select($p != null)
      | (($c.front_matter.context // {}).period) as $value
      | select(tolerated($c; $value) | not)
      | ($value | parse_period($lang)) as $case_period
      | ($p.front_matter.period) as $position_value
      | if (readable($case_period) | not) then
          [$c.file, "C25 : période « \($value | show) » illisible ; formes lues : \(forms($lang))"]
        elif tolerated($p; $position_value) then
          empty
        else
          ($position_value | parse_period($lang)) as $position_period
          | if (readable($position_period) | not) then
              [$c.file, "C25 : comparaison impossible avec content/\($p.file), dont la période « \($position_value | show) » est illisible"]
            elif $case_period.start < $position_period.start
                 or ($position_period.end != null
                     and ($case_period.end == null or $case_period.end > $position_period.end)) then
              [$c.file, "C25 : période « \($value) » hors de celle du poste content/\($p.file) (« \($position_value | show) ») ; la période d'un cas est comprise dans celle de son poste (AD-18)"]
            else empty end
        end )
  )
| @tsv
JQ

report=""
while IFS= read -r manifest; do
  [[ -n $manifest ]] || continue
  lines=$(jq -r "$program" "$manifest") || checks_die "lecture de $manifest impossible."
  [[ -z $lines ]] || report+="$lines"$'\n'
done <<< "$manifests"

if [[ -z ${report//[$'\n']/} ]]; then
  printf '%s: période de chaque cas comprise dans celle de son poste, périodes lisibles.\n' "$script_name"
  exit 0
fi

while IFS=$'\t' read -r file gap; do
  [[ -n $file ]] || continue
  checks_report "content/$file" "$gap"
done <<< "$report"
exit 1
