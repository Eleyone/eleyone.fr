#!/usr/bin/env bash
# C4, C5, C6 (story 3.4), sur des manifestes écrits à la main : rubriques d'un cas, marqueurs [TODO
# publiés, vocabulaire de la stack. La forme du manifeste est prouvée par test-checks-manifest.sh.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

rendu() { # $1 = filtre jq pour le manifeste FR, $2 = filtre pour l'EN
  mkdir -p "$work/rendu/en"
  jq "${1:-.}" "$fixtures/manifests/fr.json" > "$work/rendu/checks.json"
  jq "${2:-.}" "$fixtures/manifests/en.json" > "$work/rendu/en/checks.json"
}

contenu() {
  run env CHECK_WORK_ROOT="$work/rendu" bash "$root/scripts/checks/content.sh"
}

case_content_fixtures_passent() {
  rendu
  contenu
  assert_eq 0 "$rc" "les fixtures conformes passent (messages : $err)"
  assert_contains "vérifiés" "$out" "le contrôle le dit"
}

case_content_c4_rubrique_inconnue() {
  rendu '.files[2].headings = [{"level": 2, "text": "Inventée"}]'
  contenu
  assert_eq 1 "$rc" "une rubrique hors liste fait échouer"
  assert_contains 'C4 : rubrique « Inventée » absente de data/rubrics.yaml' "$err" "le signalement nomme la rubrique"
}

case_content_c4_rubriques_dans_le_desordre() {
  rendu '.files[2].headings = [{"level": 2, "text": "Résultat"}, {"level": 2, "text": "Contexte"}]'
  contenu
  assert_eq 1 "$rc" "l'ordre de data/rubrics.yaml est imposé"
  assert_contains "C4 : rubriques dans le désordre" "$err" "le signalement donne l'ordre attendu"
  assert_contains "ordre attendu : Contexte ; Le problème ; Résultat" "$err" "l'ordre attendu vient de la liste"
}

case_content_c4_rubrique_en_double() {
  rendu '.files[2].headings = [{"level": 2, "text": "Contexte"}, {"level": 2, "text": "Contexte"}]'
  contenu
  assert_eq 1 "$rc" "une rubrique écrite deux fois fait échouer"
  assert_contains 'écrite deux fois' "$err" "le signalement le dit"
}

case_content_c4_titre_trop_profond() {
  # Entrée reportée de la story 2.6 : un cas groupé descend chaque titre d'un niveau, un ###### y
  # produirait un <h7>. La règle décidée le 18/09/2026 refuse tout titre au-delà de ###.
  rendu '.files[2].headings += [{"level": 4, "text": "Trop profond"}]'
  contenu
  assert_eq 1 "$rc" "un titre de niveau 4 dans un cas fait échouer"
  assert_contains "titre de niveau 4 « Trop profond »" "$err" "le signalement nomme le niveau et le titre"
  rendu '.files[2].headings += [{"level": 3, "text": "Sous-titre libre"}]'
  contenu
  assert_eq 0 "$rc" "un sous-titre de niveau 3 reste libre (messages : $err)"
}

case_content_c4_ne_vise_que_les_cas() {
  rendu '.files[1].headings = [{"level": 2, "text": "Missions"}, {"level": 4, "text": "Détail"}]' \
        '.files[1].headings = [{"level": 2, "text": "Assignments"}, {"level": 4, "text": "Detail"}]'
  contenu
  assert_eq 0 "$rc" "les titres d'un poste ne relèvent ni de la liste ni de la profondeur (messages : $err)"
}

case_content_c4_sapplique_aux_brouillons() {
  # AD-10 : la liste des rubriques s'applique aussi à un brouillon.
  rendu '.files[2].draft = true | .files[2].headings = [{"level": 2, "text": "Inventée"}]'
  contenu
  assert_eq 1 "$rc" "un brouillon n'échappe pas à C4"
}

case_content_c5_todo_publie() {
  rendu '.files[1].draft = false | .files[1].todo = true'
  contenu
  assert_eq 1 "$rc" "un [TODO dans un fichier publié fait échouer"
  assert_contains "C5 : le fichier est publié et contient « [TODO »" "$err" "le signalement le dit"
}

case_content_c5_todo_dans_un_brouillon() {
  rendu '.files[1].draft = true | .files[1].todo = true'
  contenu
  assert_eq 0 "$rc" "le même [TODO dans un brouillon passe (messages : $err)"
}

case_content_c6_technologie_hors_vocabulaire() {
  rendu '.files[2].draft = false | .files[2].todo = false | .files[2].front_matter.context.stack = ["Cobol"]'
  contenu
  assert_eq 1 "$rc" "une technologie hors vocabulaire fait échouer"
  assert_contains 'C6 : technologie « Cobol » absente de data/stack.yaml' "$err" "le signalement nomme la technologie"
}

case_content_c6_todo_tolere_dans_un_brouillon() {
  rendu '.files[2].front_matter.context.stack = ["[TODO: stack]"]'
  contenu
  assert_eq 0 "$rc" "un [TODO de stack passe dans un brouillon (messages : $err)"
  rendu '.files[2].draft = false | .files[2].todo = false | .files[2].front_matter.context.stack = ["[TODO: stack]"]'
  contenu
  assert_eq 1 "$rc" "le même [TODO ne passe pas dans un cas publié"
}

case_content_entree_en_erreur_ignoree() {
  rendu '.files[2].error = "front matter absent"'
  contenu
  assert_eq 0 "$rc" "une entrée en erreur relève de la parité, pas du contenu (messages : $err)"
}

run_case "$@"
