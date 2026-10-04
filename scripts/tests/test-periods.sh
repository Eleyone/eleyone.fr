#!/usr/bin/env bash
# C25 (story 10.9, AD-18) : la période d'un cas est comprise dans celle de son poste, sur des
# manifestes écrits à la main. La forme du manifeste est prouvée par test-checks-manifest.sh ; les
# manifestes d'ici en reprennent la structure (une entrée par fichier, rôle, brouillon, front matter
# tel qu'écrit), pour que le contrôle lise ce que le rendu de travail lui donne vraiment (point 16
# d'AGENTS.md).
#
# Chaque garde a son cas, et chaque cas exerce l'entrée que la garde doit **refuser** (point 9).
. "$(dirname "${BASH_SOURCE[0]}")/../../.working-method/tests/lib.sh"

# Écrit les deux manifestes. $1 = période du poste en FR, $2 = du cas en FR, $3 et $4 = en EN ;
# $5 = filtre jq appliqué aux deux manifestes (« . » par défaut).
rendu() { # $1 poste FR, $2 cas FR, $3 poste EN, $4 cas EN, $5 filtre
  mkdir -p "$work/rendu/en"
  local langue poste cas destination
  for langue in fr en; do
    if [[ $langue == fr ]]; then poste=$1 cas=$2 destination="$work/rendu/checks.json"
    else poste=$3 cas=$4 destination="$work/rendu/en/checks.json"; fi
    jq -n --arg lang "$langue" --arg poste "$poste" --arg cas "$cas" '
      {
        lang: $lang,
        stack: ["PHP"],
        rubrics: [{fr: "Contexte", en: "Context"}],
        files: [
          {file: "_index.\($lang).md", lang: $lang, kind: "home", role: "home", url: "/",
           translationKey: "home", draft: false, todo: false, headings: [], placed: [], material: [],
           front_matter: {title: "Accueil", identity: "Prénom Nom · Pseudo"}},
          {file: "career/position-essai.\($lang).md", lang: $lang, kind: "page", role: "position",
           url: "", translationKey: "position-essai", draft: false, todo: false, headings: [],
           placed: [], material: [],
           front_matter: {translationKey: "position-essai", company: "Société", role: "Rôle",
                          period: $poste, setup: "employee", track: "main", order: 1, draft: false}},
          {file: "cases/case-09-essai.\($lang).md", lang: $lang, kind: "page", role: "case",
           url: "/cas/essai/", translationKey: "case-09", draft: false, todo: false,
           headings: [{level: 2, text: "Contexte"}], placed: [], material: [],
           front_matter: {title: "Cas", translationKey: "case-09", number: "09",
                          position: "position-essai", order: 9, draft: false,
                          context: {company: "Société", role: "Rôle", period: $cas,
                                    setup: "employee", stack: ["PHP"]}}}
        ]
      } | '"${5:-.}" > "$destination"
  done
}

periodes() {
  run env CHECK_WORK_ROOT="$work/rendu" bash "$root/scripts/checks/periods.sh"
}

# Les formes d'aujourd'hui, une à une : ce que le contrôle doit accepter. Sans ce cas, un contrôle
# qui refuserait tout passerait pour un contrôle strict.
case_periods_formes_lues_acceptees() {
  rendu "Juillet 2022 – avril 2026" "septembre 2025 – février 2026" "July 2022 – April 2026" "September 2025 – February 2026"
  periodes
  assert_eq 0 "$rc" "un intervalle dans un intervalle passe (messages : $err)"
  assert_contains "comprise dans celle de son poste" "$out" "le contrôle le dit"
  rendu "Depuis février 2024" "depuis mai 2025" "Since February 2024" "since May 2025"
  periodes
  assert_eq 0 "$rc" "une activité en cours sous une activité en cours passe (messages : $err)"
  rendu "Janvier 2017 – décembre 2017" "2017" "January 2017 – December 2017" "2017"
  periodes
  assert_eq 0 "$rc" "une année seule vaut de janvier à décembre (messages : $err)"
  rendu "2017" "mars 2017 – mai 2017" "2017" "March 2017 – May 2017"
  periodes
  assert_eq 0 "$rc" "un intervalle dans une année seule passe (messages : $err)"
  rendu "Depuis février 2024" "mars 2024 – avril 2025" "Since February 2024" "March 2024 – April 2025"
  periodes
  assert_eq 0 "$rc" "un intervalle fermé sous une fin ouverte passe (messages : $err)"
  rendu "Juillet 2022 – avril 2026" "juillet 2022 – avril 2026" "July 2022 – April 2026" "July 2022 – April 2026"
  periodes
  assert_eq 0 "$rc" "les bornes sont incluses (messages : $err)"
  # La casse ne compte pas, accents compris : « DÉCEMBRE » est « décembre ».
  rendu "JANVIER 2017 – DÉCEMBRE 2017" "Août 2017 – Décembre 2017" "JANUARY 2017 – DECEMBER 2017" "august 2017 – december 2017"
  periodes
  assert_eq 0 "$rc" "la casse est ignorée, lettres accentuées comprises (messages : $err)"
}

case_periods_cas_qui_commence_avant() {
  rendu "Juillet 2022 – avril 2026" "juin 2022 – février 2026" "July 2022 – April 2026" "September 2025 – February 2026"
  periodes
  assert_eq 1 "$rc" "un cas qui commence avant son poste fait échouer"
  assert_contains 'content/cases/case-09-essai.fr.md: C25 : période « juin 2022 – février 2026 » hors de celle du poste content/career/position-essai.fr.md (« Juillet 2022 – avril 2026 »)' \
    "$err" "le signalement nomme les deux fichiers et les deux périodes"
  [[ $err != *case-09-essai.en.md* ]] || { echo "le cas anglais, conforme, est signalé : $err" >&2; exit 1; }
}

case_periods_cas_qui_finit_apres() {
  rendu "Juillet 2022 – avril 2026" "septembre 2025 – février 2026" "July 2022 – April 2026" "September 2025 – May 2026"
  periodes
  assert_eq 1 "$rc" "un cas qui finit après son poste fait échouer, ici côté anglais"
  assert_contains 'content/cases/case-09-essai.en.md: C25 : période « September 2025 – May 2026 » hors de celle du poste content/career/position-essai.en.md' \
    "$err" "chaque langue est lue de son côté"
}

case_periods_annee_seule_qui_deborde() {
  # « 2017 » vaut jusqu'en décembre : sous un poste qui finit en juin, l'année seule déborde.
  rendu "Janvier 2017 – juin 2017" "2017" "January 2017 – June 2017" "March 2017 – May 2017"
  periodes
  assert_eq 1 "$rc" "une année seule qui déborde d'un poste plus court fait échouer"
  assert_contains 'case-09-essai.fr.md: C25 : période « 2017 » hors de celle du poste' "$err" "le signalement le dit"
}

case_periods_cas_ouvert_sous_poste_ferme() {
  rendu "Juillet 2022 – avril 2026" "depuis septembre 2025" "July 2022 – April 2026" "since September 2025"
  periodes
  assert_eq 1 "$rc" "un cas en cours sous un poste terminé déborde"
  assert_contains 'case-09-essai.fr.md: C25 : période « depuis septembre 2025 » hors de celle du poste' "$err" "côté français"
  assert_contains 'case-09-essai.en.md: C25 : période « since September 2025 » hors de celle du poste' "$err" "et côté anglais"
}

case_periods_cas_avant_un_poste_ouvert() {
  # Une fin ouverte n'efface pas le début : un cas d'avant le poste en cours déborde quand même.
  rendu "Depuis février 2024" "janvier 2024 – mars 2024" "Since February 2024" "since May 2025"
  periodes
  assert_eq 1 "$rc" "un cas commencé avant un poste en cours fait échouer"
  assert_contains 'case-09-essai.fr.md: C25 : période « janvier 2024 – mars 2024 »' "$err" "le signalement nomme le cas"
}

case_periods_forme_illisible_dans_le_cas() {
  # Chaque forme a son pas : la garde qui n'en refuserait qu'une passerait le cas suivant.
  local forme
  for forme in "2025-2026" "2025 - 2026" "2025–2026" "2025 — 2026" "juillet 2022 – 2026" "2022 – avril 2026" \
               "25 – 26" "juillet 2022 - avril 2026" "juillet 2022 — avril 2026" "juillet 2022–avril 2026" \
               "07/2022 – 04/2026" "juil. 2022 – avril 2026" "July 2022 – April 2026" "since mai 2025" \
               "de juillet 2022 à avril 2026" " juillet 2022 – avril 2026" "" "[TODO: période]"; do
    rendu "Juillet 2022 – avril 2026" "$forme" "July 2022 – April 2026" "September 2025 – February 2026"
    periodes
    assert_eq 1 "$rc" "la forme « $forme » est refusée dans un cas publié"
    assert_contains "case-09-essai.fr.md: C25 : période « $forme » illisible ; formes lues : « mois AAAA – mois AAAA »" "$err" \
      "le signalement cite la forme « $forme » et les formes lues"
  done
}

case_periods_forme_anglaise_lue_en_anglais_seulement() {
  # Les deux langues sont lues chacune de son côté : un mois anglais n'est pas un mois français, et
  # « depuis » n'est pas de l'anglais.
  rendu "July 2022 – April 2026" "September 2025 – February 2026" "Depuis février 2024" "since May 2025"
  periodes
  assert_eq 1 "$rc" "les mots d'une langue ne se lisent pas dans l'autre"
  assert_contains 'career/position-essai.fr.md: C25 : période « July 2022 – April 2026 » illisible' "$err" "le poste français écrit en anglais"
  assert_contains 'career/position-essai.en.md: C25 : période « Depuis février 2024 » illisible ; formes lues : « Month YYYY – Month YYYY »' \
    "$err" "le poste anglais écrit en français, avec les formes anglaises"
}

case_periods_forme_illisible_dans_le_poste() {
  rendu "2022 - 2026" "septembre 2025 – février 2026" "July 2022 – April 2026" "September 2025 – February 2026"
  periodes
  assert_eq 1 "$rc" "une période de poste illisible fait échouer"
  assert_contains 'content/career/position-essai.fr.md: C25 : période « 2022 - 2026 » illisible' "$err" "le poste est nommé"
  assert_contains 'content/cases/case-09-essai.fr.md: C25 : comparaison impossible avec content/career/position-essai.fr.md' "$err" \
    "et le cas dit qu'il n'a pas été comparé, en nommant les deux fichiers"
}

case_periods_poste_sans_cas_lu_aussi() {
  # La période d'un poste se lit qu'un cas le désigne ou non (docs/format-parcours.md).
  rendu "Juillet 2008 à juin 2014" "x" "July 2008 – June 2014" "x" 'del(.files[2])'
  periodes
  assert_eq 1 "$rc" "un poste sans cas à la période illisible fait échouer"
  assert_contains 'career/position-essai.fr.md: C25 : période « Juillet 2008 à juin 2014 » illisible' "$err" "le signalement nomme le poste"
}

# Story 10.10 : l'intervalle d'années « AAAA – AAAA », la période du cas 01 donnée par Arnaud. Sans
# la forme, ce cas échoue (période illisible) : c'est le test qui échoue sans elle (point 9).
case_periods_intervalle_d_annees_lu() {
  rendu "Depuis février 2024" "2025 – 2026" "Since February 2024" "2025 – 2026"
  periodes
  assert_eq 0 "$rc" "un intervalle d'années sous une fin ouverte passe, en FR et en EN (messages : $err)"
  rendu "2025 – 2026" "janvier 2025 – décembre 2026" "2025 – 2026" "January 2025 – December 2026"
  periodes
  assert_eq 0 "$rc" "un intervalle d'années va du 1er janvier au 31 décembre, bornes incluses (messages : $err)"
  rendu "2025 – 2025" "2025" "2025 – 2025" "2025"
  periodes
  assert_eq 0 "$rc" "un intervalle d'une seule année vaut l'année seule (messages : $err)"
  rendu "Juillet 2022 – avril 2026" "2023 – 2025" "July 2022 – April 2026" "2023 – 2025"
  periodes
  assert_eq 0 "$rc" "un intervalle d'années dans un intervalle de mois passe (messages : $err)"
}

case_periods_intervalle_d_annees_qui_deborde() {
  # « 2026 » finit en décembre : sous un poste qui finit en avril 2026, le cas déborde. Et le début
  # de « 2022 – … » est janvier, avant un poste commencé en juillet 2022.
  rendu "Juillet 2022 – avril 2026" "2025 – 2026" "July 2022 – April 2026" "2022 – 2025"
  periodes
  assert_eq 1 "$rc" "un intervalle d'années qui déborde fait échouer"
  assert_contains 'case-09-essai.fr.md: C25 : période « 2025 – 2026 » hors de celle du poste' "$err" "la fin, côté français"
  assert_contains 'case-09-essai.en.md: C25 : période « 2022 – 2025 » hors de celle du poste' "$err" "le début, côté anglais"
  # Un poste en intervalle d'années borne aussi ses cas.
  rendu "2017 – 2018" "mars 2019 – mai 2019" "2017 – 2018" "March 2018 – May 2018"
  periodes
  assert_eq 1 "$rc" "un cas après un poste en intervalle d'années fait échouer"
  assert_contains 'case-09-essai.fr.md: C25 : période « mars 2019 – mai 2019 » hors de celle du poste content/career/position-essai.fr.md (« 2017 – 2018 »)' \
    "$err" "le signalement cite la période du poste"
}

case_periods_intervalle_inverse() {
  rendu "Avril 2026 – juillet 2022" "septembre 2025 – février 2026" "July 2022 – April 2026" "September 2025 – February 2026"
  periodes
  assert_eq 1 "$rc" "un intervalle dont la fin précède le début est refusé"
  assert_contains 'career/position-essai.fr.md: C25 : période « Avril 2026 – juillet 2022 » illisible' "$err" "le poste est nommé"
  rendu "Juillet 2022 – avril 2026" "février 2026 – septembre 2025" "July 2022 – April 2026" "September 2025 – February 2026"
  periodes
  assert_eq 1 "$rc" "et dans un cas aussi"
  assert_contains 'case-09-essai.fr.md: C25 : période « février 2026 – septembre 2025 » illisible' "$err" "le cas est nommé"
  # L'intervalle d'années (story 10.10) passe par la même garde.
  rendu "Juillet 2022 – avril 2026" "2026 – 2025" "July 2022 – April 2026" "2026 – 2025"
  periodes
  assert_eq 1 "$rc" "un intervalle d'années inversé est refusé"
  assert_contains 'case-09-essai.fr.md: C25 : période « 2026 – 2025 » illisible ; formes lues : « mois AAAA – mois AAAA », « depuis mois AAAA », « AAAA » ou « AAAA – AAAA »' \
    "$err" "côté français, avec les formes lues"
  assert_contains 'case-09-essai.en.md: C25 : période « 2026 – 2025 » illisible ; formes lues : « Month YYYY – Month YYYY », « since Month YYYY », « YYYY » ou « YYYY – YYYY »' \
    "$err" "côté anglais"
}

case_periods_todo_tolere_dans_un_brouillon() {
  # Règle des brouillons (AD-10) : le cas 03 porte aujourd'hui « [TODO: période] » et doit passer.
  local brouillon='(.files[2].draft = true | .files[2].front_matter.draft = true)'
  rendu "Juillet 2022 – avril 2026" "[TODO: période]" "July 2022 – April 2026" "[TODO: période]" "$brouillon"
  periodes
  assert_eq 0 "$rc" "un cas en brouillon dont la période est en [TODO passe (messages : $err)"
  # Le même brouillon reste comparé quand sa période est écrite : seul le [TODO est toléré.
  rendu "Juillet 2022 – avril 2026" "juin 2022 – juillet 2022" "July 2022 – April 2026" "September 2025 – February 2026" "$brouillon"
  periodes
  assert_eq 1 "$rc" "un brouillon dont la période déborde fait échouer"
  # Un poste en brouillon dont la période est en [TODO : ni lu ni comparé.
  rendu "[TODO: période]" "septembre 2025 – février 2026" "[TODO: période]" "September 2025 – February 2026" \
    '(.files[1].draft = true | .files[1].front_matter.draft = true)'
  periodes
  assert_eq 0 "$rc" "un poste en brouillon dont la période est en [TODO passe (messages : $err)"
  # Publié, le poste en [TODO est une forme illisible (C5 le refuse aussi).
  rendu "[TODO: période]" "septembre 2025 – février 2026" "July 2022 – April 2026" "September 2025 – February 2026"
  periodes
  assert_eq 1 "$rc" "un poste publié dont la période est en [TODO fait échouer"
  assert_contains 'career/position-essai.fr.md: C25 : période « [TODO: période] » illisible' "$err" "le signalement le dit"
}

case_periods_rattachement_releve_de_c19() {
  # Sans « position », ou vers un poste absent de sa langue, le cas n'est pas comparé : c'est C19
  # qui refuse ce rattachement. La période du poste, elle, reste lue.
  rendu "Juillet 2022 – avril 2026" "juin 1990 – juillet 1990" "July 2022 – April 2026" "June 1990 – July 1990" \
    'del(.files[2].front_matter.position)'
  periodes
  assert_eq 0 "$rc" "un cas sans position n'est pas comparé (messages : $err)"
  rendu "Juillet 2022 – avril 2026" "juin 1990 – juillet 1990" "July 2022 – April 2026" "June 1990 – July 1990" \
    '.files[2].front_matter.position = "position-absent"'
  periodes
  assert_eq 0 "$rc" "un cas rattaché à un poste absent n'est pas comparé (messages : $err)"
}

case_periods_sans_manifeste() {
  run env CHECK_WORK_ROOT="$work/absent" bash "$root/scripts/checks/periods.sh"
  assert_eq 2 "$rc" "un rendu de travail absent est une anomalie, jamais un succès"
}

run_case "$@"
