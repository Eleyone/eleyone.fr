#!/usr/bin/env bash
# Bibliothèque des contrôles (story 3.1) : découverte des manifestes du rendu de travail.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# checks_die s'arrête par « exit » : chaque appel tourne dans son propre bash, comme un contrôle réel,
# sinon l'arrêt terminerait le cas de test lui-même.
manifests() { # $1 = racine
  run bash -c 'script_name=essai; . "$1/scripts/checks/lib.sh"; checks_manifests "$2"' _ "$root" "$1"
}

case_checks_manifests_liste_les_deux_langues() {
  mkdir -p "$work/rendu/en"
  : > "$work/rendu/checks.json"
  : > "$work/rendu/en/checks.json"
  manifests "$work/rendu"
  assert_eq 0 "$rc" "deux manifestes trouvés (messages : $err)"
  assert_eq "$work/rendu/checks.json
$work/rendu/en/checks.json" "$out" "les manifestes sont listés, triés"
}

case_checks_manifests_sans_rendu() {
  manifests "$work/absent"
  assert_eq 2 "$rc" "une racine absente est une anomalie"
  assert_contains "scripts/build.sh work" "$err" "le message dit quoi lancer"
}

case_checks_manifests_rendu_sans_manifeste() {
  mkdir -p "$work/vide"
  manifests "$work/vide"
  assert_eq 2 "$rc" "un rendu sans manifeste est une anomalie"
  assert_contains "aucun manifeste" "$err" "le message nomme la cause"
}

case_checks_is_todo() {
  run bash -c '. "$1/scripts/checks/lib.sh"; checks_is_todo "[TODO: période]"' _ "$root"
  assert_eq 0 "$rc" "une valeur [TODO est reconnue"
  run bash -c '. "$1/scripts/checks/lib.sh"; checks_is_todo "septembre 2025"' _ "$root"
  assert_eq 1 "$rc" "une vraie valeur ne l'est pas"
  run bash -c '. "$1/scripts/checks/lib.sh"; checks_is_todo ""' _ "$root"
  assert_eq 1 "$rc" "une valeur vide ne l'est pas"
}

case_checks_tolerated_seulement_sur_un_brouillon() {
  run bash -c '. "$1/scripts/checks/lib.sh"; checks_tolerated true "[TODO: période]"' _ "$root"
  assert_eq 0 "$rc" "un [TODO dans un brouillon est toléré (AD-10)"
  run bash -c '. "$1/scripts/checks/lib.sh"; checks_tolerated false "[TODO: période]"' _ "$root"
  assert_eq 1 "$rc" "le même [TODO dans un fichier publié ne l'est pas"
  run bash -c '. "$1/scripts/checks/lib.sh"; checks_tolerated true "septembre 2025"' _ "$root"
  assert_eq 1 "$rc" "une vraie valeur n'a rien à tolérer"
}

case_checks_report_ecrit_le_format_commun() {
  run bash -c '. "$1/scripts/checks/lib.sh"; checks_report "content/cases/x.fr.md" "rubrique hors liste"' _ "$root"
  assert_eq 0 "$rc" "le signalement n'échoue pas de lui-même"
  assert_eq "content/cases/x.fr.md: rubrique hors liste" "$err" "le format est <fichier>: <écart>, sur la sortie d'erreur"
  assert_eq "" "$out" "rien sur la sortie standard"
}

run_case "$@"
