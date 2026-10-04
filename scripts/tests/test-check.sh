#!/usr/bin/env bash
# Point d'entrée des contrôles (story 3.2) : ordre des builds, niveau, codes de sortie, et sa
# délégation au mécanisme commun. Hors ligne : check.sh est copié dans un faux dépôt, avec un
# build.sh bouchonné et des contrôles d'essai. Le vrai build est exercé par les essais de la story,
# pas ici.
#
# Le mécanisme (découverte, cumul des écarts, anomalie en 2, lib.sh écarté, tri) vit dans l'outillage
# commun depuis la story outillage-14 : ses cas — check_cumule_les_echecs, check_anomalie_rend_2,
# check_ignore_lib_et_trie — tournent dans le dépôt commun (.working-method/tests/test-run-checks.sh),
# au mot près. Restent ici ce que check.sh fait lui-même : les builds, --release, son option inconnue,
# et sa délégation, sans .git, comme dans le contexte de build de l'image.
. "$(dirname "${BASH_SOURCE[0]}")/../../.working-method/tests/lib.sh"

faux_depot() { # prépare $work/faux : check.sh réel, build.sh bouchonné, dossier de contrôles vide
  mkdir -p "$work/faux/scripts/checks" "$work/faux/scripts/lib" "$work/faux/.working-method/checks" "$work/faux/.working-method/lib"
  cp "$root/scripts/check.sh" "$work/faux/scripts/"
  cp "$root/scripts/checks/lib.sh" "$work/faux/scripts/checks/"
  cp "$root/scripts/lib/text.sh" "$work/faux/scripts/lib/"
  # le mécanisme commun et ce qu'il charge, comme dans le sous-module, et le workflow.config du projet
  cp "$root/.working-method/checks/run-checks.sh" "$work/faux/.working-method/checks/"
  cp "$root/.working-method/lib/config.sh" "$root/.working-method/lib/shell.sh" "$root/.working-method/lib/dotenv.sh" \
    "$work/faux/.working-method/lib/"
  cp "$root/workflow.config" "$work/faux/"
  # Le chargeur unique et sa bibliothèque : check.sh lance chaque contrôle par lui depuis la story
  # 9.1, sans quoi aucun contrôle ne verrait un HUGO_LEGAL_* (AD-9). Une fixture qui ne le porte pas
  # ne ressemble plus au dépôt qu'elle imite (point 16 d'AGENTS.md).
  cp "$root/scripts/env.sh" "$work/faux/scripts/"
  mkdir -p "$work/faux/ci"
  cp "$root/ci/legal-placeholder.env" "$work/faux/ci/"
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


case_check_release_pose_le_niveau() {
  faux_depot
  controle a 0
  run bash "$work/faux/scripts/check.sh" --release
  assert_eq 0 "$rc" "--release est reconnue (messages : $err)"
  assert_contains "niveau=release a" "$(cat "$work/faux/controles.log")" "le niveau est transmis au contrôle"
  assert_contains "niveau release" "$out" "le résumé nomme le niveau"
}

case_check_mecanisme_absent_rend_2() {
  # Sans le sous-module, aucun contrôle ne tournerait : c'est une anomalie, jamais une conformité.
  faux_depot
  controle a 0
  rm -rf "$work/faux/.working-method"
  run bash "$work/faux/scripts/check.sh"
  assert_eq 2 "$rc" "mécanisme absent : anomalie"
  assert_contains "sous-module .working-method non initialisé" "$err" "le message dit le remède"
  [[ ! -e $work/faux/controles.log ]] || { echo "un contrôle a tourné sans le mécanisme" >&2; exit 1; }
}

case_check_les_controles_tournent_sous_le_chargeur() {
  # Chaque contrôle voit les valeurs légales du chargeur (AD-9), à travers le mécanisme commun.
  faux_depot
  printf '#!/usr/bin/env bash\necho "editeur=${HUGO_LEGAL_PUBLISHER_NAME:-absent}" >> "%s/faux/controles.log"\n' "$work" \
    > "$work/faux/scripts/checks/valeurs.sh"
  run env ENV_FILE=/nonexistent/.env bash "$work/faux/scripts/check.sh"
  assert_eq 0 "$rc" "les contrôles passent (messages : $err)"
  [[ $(cat "$work/faux/controles.log") != "editeur=absent" ]] || { echo "le contrôle ne voit aucune valeur légale" >&2; exit 1; }
}

case_check_option_inconnue() {
  faux_depot
  run bash "$work/faux/scripts/check.sh" --inconnue
  assert_eq 2 "$rc" "une option inconnue est une anomalie"
  assert_contains "option inconnue" "$err" "le message nomme l'option"
  [[ ! -s $work/faux/build.log ]] || { echo "un build a été lancé malgré l'option inconnue" >&2; exit 1; }
}

run_case "$@"
