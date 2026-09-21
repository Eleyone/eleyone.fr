#!/usr/bin/env bash
# Point d'entrée des contrôles (story 3.2) : ordre des builds, découverte, cumul, codes de sortie.
# Hors ligne : check.sh est copié dans un faux dépôt, avec un build.sh bouchonné et des contrôles
# d'essai. Le vrai build est exercé par les essais de la story, pas ici.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

faux_depot() { # prépare $work/faux : check.sh réel, build.sh bouchonné, dossier de contrôles vide
  mkdir -p "$work/faux/scripts/checks" "$work/faux/scripts/lib"
  cp "$root/scripts/check.sh" "$work/faux/scripts/"
  cp "$root/scripts/checks/lib.sh" "$work/faux/scripts/checks/"
  cp "$root/scripts/lib/shell.sh" "$work/faux/scripts/lib/"
  : > "$work/faux/build.log"
  printf '#!/usr/bin/env bash\necho "$1" >> "%s/faux/build.log"\n[ "${BUILD_FAIL:-}" != "$1" ] || { echo "hugo: avertissement" >&2; exit 1; }\n' "$work" \
    > "$work/faux/scripts/build.sh"
  chmod +x "$work/faux/scripts/build.sh"
}

controle() { # $1 = nom, $2 = code de sortie ; écrit un signalement au format commun
  printf '#!/usr/bin/env bash\necho "contenu/%s.md: écart de %s" >&2\necho "niveau=${CHECK_LEVEL:-absent} %s" >> "%s/faux/controles.log"\nexit %s\n' \
    "$1" "$1" "$1" "$work" "$2" > "$work/faux/scripts/checks/$1.sh"
}

case_check_lance_les_deux_builds_puis_les_controles() {
  faux_depot
  controle a 0
  controle b 0
  run bash "$work/faux/scripts/check.sh"
  assert_eq 0 "$rc" "tout passe (messages : $err)"
  assert_eq "work
production" "$(cat "$work/faux/build.log")" "le rendu de travail précède le build de production"
  assert_contains "2 contrôle(s) passés" "$out" "le résumé compte les contrôles"
  [[ ! -e $work/faux/.git ]] || { echo "le faux dépôt ne doit pas avoir de .git" >&2; exit 1; }
}

case_check_cumule_les_echecs() {
  faux_depot
  controle a 1
  controle b 1
  controle c 0
  run bash "$work/faux/scripts/check.sh"
  assert_eq 1 "$rc" "un écart rend 1"
  assert_contains "contenu/a.md: écart de a" "$err" "le premier écart est affiché"
  assert_contains "contenu/b.md: écart de b" "$err" "le contrôle suivant tourne quand même"
  assert_contains "2 contrôle(s) en échec sur 3 : a b" "$err" "le résumé nomme les contrôles en échec"
}

case_check_anomalie_rend_2() {
  faux_depot
  controle a 2
  run bash "$work/faux/scripts/check.sh"
  assert_eq 2 "$rc" "une anomalie rend 2"
  assert_contains "a (code 2)" "$err" "le résumé nomme le code"
}

case_check_build_en_echec_arrete_avant_les_controles() {
  faux_depot
  controle a 0
  run env BUILD_FAIL=work bash "$work/faux/scripts/check.sh"
  assert_eq 1 "$rc" "un build en échec rend 1"
  assert_contains "le build work a échoué" "$err" "le message nomme le build"
  assert_contains "hugo: avertissement" "$err" "la sortie de Hugo est gardée telle quelle"
  # L'ordre est un critère : la ligne de check.sh précède la sortie de Hugo, qui s'écoulerait avant
  # elle si le build n'était pas retenu (constat de la revue de la PR n° 36).
  assert_eq "check: le build work a échoué : les contrôles ne tournent pas sur une sortie périmée (C14).
hugo: avertissement" "$err" "la ligne de check.sh précède la sortie de Hugo"
  [[ ! -e $work/faux/controles.log ]] || { echo "un contrôle a tourné après un build en échec" >&2; exit 1; }
}

case_check_ignore_lib_et_trie() {
  faux_depot
  controle b 0
  controle a 0
  run bash "$work/faux/scripts/check.sh"
  assert_eq 0 "$rc" "lib.sh n'est pas un contrôle (messages : $err)"
  assert_eq "niveau=standard a
niveau=standard b" "$(cat "$work/faux/controles.log")" "les contrôles tournent triés, sans lib.sh"
}

case_check_release_pose_le_niveau() {
  faux_depot
  controle a 0
  run bash "$work/faux/scripts/check.sh" --release
  assert_eq 0 "$rc" "--release est reconnue (messages : $err)"
  assert_contains "niveau=release a" "$(cat "$work/faux/controles.log")" "le niveau est transmis au contrôle"
  assert_contains "niveau release" "$out" "le résumé nomme le niveau"
}

case_check_option_inconnue() {
  faux_depot
  run bash "$work/faux/scripts/check.sh" --inconnue
  assert_eq 2 "$rc" "une option inconnue est une anomalie"
  assert_contains "option inconnue" "$err" "le message nomme l'option"
  [[ ! -s $work/faux/build.log ]] || { echo "un build a été lancé malgré l'option inconnue" >&2; exit 1; }
}

run_case "$@"
