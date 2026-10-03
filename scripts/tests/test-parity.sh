#!/usr/bin/env bash
# C3, parité FR/EN (story 3.3), sur des manifestes écrits à la main : la logique du contrôle se teste
# sans Hugo. La forme du manifeste, elle, est prouvée une seule fois par test-checks-manifest.sh.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Prépare $work/rendu à partir des fixtures, chaque langue pouvant être transformée par un filtre jq.
rendu() { # $1 = filtre jq pour le manifeste FR, $2 = filtre pour l'EN (« . » pour ne rien changer)
  mkdir -p "$work/rendu/en"
  jq "${1:-.}" "$fixtures/manifests/fr.json" > "$work/rendu/checks.json"
  jq "${2:-.}" "$fixtures/manifests/en.json" > "$work/rendu/en/checks.json"
}

parite() {
  run env CHECK_WORK_ROOT="$work/rendu" bash "$root/scripts/checks/parity.sh"
}

case_parity_paire_complete_passe() {
  rendu
  parite
  assert_eq 0 "$rc" "une paire complète passe (messages : $err)"
  assert_contains "parité FR/EN vérifiée" "$out" "le contrôle le dit"
}

case_parity_rubrique_manquante() {
  rendu . '.files[2].headings = [{"level": 2, "text": "Context"}]'
  parite
  assert_eq 1 "$rc" "une rubrique en moins fait échouer"
  assert_contains "cases/groupe/case-09-essai.en.md: 1 rubrique(s) en anglais, 2 en français" "$err" \
    "le signalement nomme le fichier et le compte"
}

case_parity_rubrique_qui_ne_correspond_pas() {
  rendu . '.files[2].headings = [{"level": 2, "text": "Context"}, {"level": 2, "text": "The problem"}]'
  parite
  assert_eq 1 "$rc" "une rubrique qui ne fait pas la paire fait échouer"
  assert_contains 'rubrique 2 : « The problem » en anglais, « Outcome » attendu en face de « Résultat »' "$err" \
    "le signalement dit ce qui était attendu, par data/rubrics.yaml"
}

case_parity_rubrique_hors_liste() {
  rendu '.files[2].headings = [{"level": 2, "text": "Contexte"}, {"level": 2, "text": "Inventée"}]' '.files[2].headings = [{"level": 2, "text": "Context"}, {"level": 2, "text": "Invented"}]'
  parite
  assert_eq 1 "$rc" "une rubrique hors liste fait échouer"
  assert_contains 'rubrique « Inventée » absente de data/rubrics.yaml' "$err" "le signalement nomme la rubrique"
}

case_parity_titres_libres_hors_dun_cas() {
  # La liste des rubriques ne vaut que pour un cas : une page simple ou un poste a des titres libres,
  # seulement comptés (constat de la revue de la PR n° 37).
  rendu '.files[1].headings = [{"level": 2, "text": "Missions"}]' '.files[1].headings = [{"level": 2, "text": "Assignments"}]'
  parite
  assert_eq 0 "$rc" "des titres libres hors d'un cas passent (messages : $err)"
  rendu '.files[1].headings = [{"level": 2, "text": "Missions"}, {"level": 2, "text": "Équipe"}]' '.files[1].headings = [{"level": 2, "text": "Assignments"}]'
  parite
  assert_eq 1 "$rc" "mais leur nombre doit rester le même"
  assert_contains "1 titre(s) de niveau 2 en anglais, 2 en français" "$err" "le mot n'est pas « rubrique » hors d'un cas"
}

case_parity_cle_non_traduite_differente() {
  rendu . '.files[2].front_matter.order = 2'
  parite
  assert_eq 1 "$rc" "une clé non traduite différente fait échouer"
  assert_contains 'clé non traduite « order » : 1 en français, 2 en anglais' "$err" "le signalement donne les deux valeurs"
}

case_parity_label_de_poste_se_traduit() {
  # « label » nomme un poste qui n'est pas une société et **se traduit** (AD-18, 24/09/2026) :
  # « Parcours antérieur » d'un côté, « Earlier career » de l'autre. Elle n'entre donc pas dans les
  # clés que C3 compare. Le cas vaut par sa paire : « company », elle, y reste.
  rendu '.files[1].front_matter.label = "Parcours antérieur"' '.files[1].front_matter.label = "Earlier career"'
  parite
  assert_eq 0 "$rc" "deux écritures d'un même label passent (messages : $err)"
  rendu '.files[1].front_matter.company = "Société"' '.files[1].front_matter.company = "Societe"'
  parite
  assert_eq 1 "$rc" "la même différence sur company fait échouer"
  assert_contains 'clé non traduite « company »' "$err" "le signalement nomme la clé restée comparée"
}

case_parity_cle_de_contexte_differente() {
  rendu . '.files[2].front_matter.context.stack = ["PHP", "Redshift"]'
  parite
  assert_eq 1 "$rc" "la stack est une clé non traduite"
  assert_contains 'clé non traduite « context.stack »' "$err" "le signalement nomme la clé du contexte"
}

case_parity_materiel_vivant_dans_un_autre_ordre() {
  rendu '.files[2].front_matter.live_material += [{"id": "callout-essai", "type": "callout", "status": "planned"}]' \
        '.files[2].front_matter.live_material = [{"id": "callout-essai", "type": "callout", "status": "planned"}] + .files[2].front_matter.live_material'
  parite
  assert_eq 1 "$rc" "un autre ordre de déclaration fait échouer (décidé le 18/09/2026)"
  assert_contains "live_material" "$err" "le signalement nomme la clé"
}

case_parity_jumeau_absent() {
  rendu . 'del(.files[2])'
  parite
  assert_eq 1 "$rc" "un fichier sans jumeau fait échouer"
  assert_contains 'aucun fichier anglais ne porte le translationKey « case-09 »' "$err" "le signalement nomme la clé"
}

case_parity_fichier_en_trop_cote_anglais() {
  rendu 'del(.files[1])'
  parite
  assert_eq 1 "$rc" "un fichier anglais sans jumeau français fait échouer"
  assert_contains 'aucun fichier français ne porte le translationKey « position-essai »' "$err" "le sens inverse est vu aussi"
}

case_parity_translation_key_absente() {
  rendu '.files[2].translationKey = ""'
  parite
  assert_eq 1 "$rc" "un fichier sans translationKey fait échouer"
  assert_contains "translationKey absent" "$err" "le signalement le dit avant tout rapprochement"
}

case_parity_translation_key_en_double() {
  rendu '.files[1].translationKey = "case-09"'
  parite
  assert_eq 1 "$rc" "deux fichiers de même clé dans une langue font échouer"
  assert_contains "porté par plusieurs fichiers de la même langue" "$err" "le signalement le dit"
}

case_parity_entree_en_erreur_signalee() {
  rendu '.files += [{"file": "sans-langue.md", "lang": "", "error": "suffixe de langue absent"}]'
  parite
  assert_eq 0 "$rc" "une entrée sans langue n'entre pas dans la parité (messages : $err)"
  rendu '.files[2].error = "front matter absent"'
  parite
  assert_eq 1 "$rc" "une entrée en erreur fait échouer"
  assert_contains "front matter absent" "$err" "l'erreur du manifeste est reprise telle quelle"
}

case_parity_role_different() {
  rendu . '.files[2].role = "page"'
  parite
  assert_eq 1 "$rc" "un rôle différent fait échouer"
  assert_contains 'rôle « page » côté anglais, « case » côté français' "$err" "le signalement donne les deux rôles"
}

case_parity_un_seul_manifeste() {
  mkdir -p "$work/seul"
  cp "$fixtures/manifests/fr.json" "$work/seul/checks.json"
  run env CHECK_WORK_ROOT="$work/seul" bash "$root/scripts/checks/parity.sh"
  assert_eq 2 "$rc" "un seul manifeste est une anomalie"
  assert_contains "deux attendus" "$err" "le message dit ce qui manque"
}

case_parity_stack_de_poste_comparee() {
  # Story 10.9 : la stack d'un poste est celle du projet, en termes de data/stack.yaml, identique
  # dans les deux langues (AD-18). Le cas exerce l'écart qu'elle doit refuser — un terme de plus
  # d'un côté —, puis un ordre différent, qui en est un aussi, et enfin la stack absente d'un seul
  # côté.
  rendu '.files[1].front_matter.stack = ["PHP", "Symfony"]' '.files[1].front_matter.stack = ["PHP", "Symfony"]'
  parite
  assert_eq 0 "$rc" "la même stack des deux côtés passe (messages : $err)"
  rendu '.files[1].front_matter.stack = ["PHP", "Symfony"]' '.files[1].front_matter.stack = ["PHP"]'
  parite
  assert_eq 1 "$rc" "une stack de poste différente entre FR et EN fait échouer"
  assert_contains 'career/position-essai.en.md: clé non traduite « stack » : ["PHP","Symfony"] en français, ["PHP"] en anglais' "$err" \
    "le signalement nomme le fichier, la clé et les deux valeurs"
  rendu '.files[1].front_matter.stack = ["PHP", "Symfony"]' '.files[1].front_matter.stack = ["Symfony", "PHP"]'
  parite
  assert_eq 1 "$rc" "le même vocabulaire dans un autre ordre fait échouer"
  rendu '.files[1].front_matter.stack = ["PHP"]' .
  parite
  assert_eq 1 "$rc" "une stack présente d'un seul côté fait échouer"
  assert_contains 'clé non traduite « stack » : ["PHP"] en français, absente en anglais' "$err" "le signalement dit laquelle manque"
}

case_parity_secteur_de_poste_se_traduit() {
  # « sector » se traduit (AD-18, arbitrage Q3 du 02/10/2026) : deux écritures ne sont pas un écart.
  rendu '.files[1].front_matter.sector = "Assurance"' '.files[1].front_matter.sector = "Insurance"'
  parite
  assert_eq 0 "$rc" "deux écritures d'un même secteur passent (messages : $err)"
}

run_case "$@"
