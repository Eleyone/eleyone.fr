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

# Codes de xmllint : un faux binaire en tête du PATH rejoue chacun, puisque la version du poste ne
# sait pas produire le 11 de CHECK_IMAGE (constat de la story 3.12).
faux_xmllint() { # $1 = code de sortie
  mkdir -p "$work/bin"
  printf '#!/bin/sh\nexit %s\n' "$1" > "$work/bin/xmllint"
  chmod +x "$work/bin/xmllint"
}

xpath_avec_code() { # $1 = code rendu par xmllint
  faux_xmllint "$1"
  run env PATH="$work/bin:$PATH" bash -c 'script_name=essai; . "$1/scripts/checks/lib.sh"; checks_xpath "$1/tools.env" "//p"' _ "$root"
}

case_checks_xpath_aucun_noeud_selon_la_version() {
  # libxml2 2.9 (poste) rend 10 pour un résultat vide ; 2.13 (CHECK_IMAGE) rend 11, et garde 10 pour
  # une requête mal écrite. Les deux passent pour « rien trouvé ».
  xpath_avec_code 10
  assert_eq 0 "$rc" "le code 10 n'est pas une anomalie (messages : $err)"
  xpath_avec_code 11
  assert_eq 0 "$rc" "le code 11 non plus (messages : $err)"
}

case_checks_xpath_fichier_illisible_reste_une_anomalie() {
  xpath_avec_code 1
  assert_eq 2 "$rc" "le code 1, rendu des deux côtés sur un fichier illisible, est une anomalie"
  assert_contains "lecture XPath impossible" "$err" "le message nomme le fichier et l'outil"
  xpath_avec_code 9
  assert_eq 2 "$rc" "tout autre code aussi"
}

run_case "$@"
