#!/usr/bin/env bash
# Build du site (story 2.2) : arguments de build.sh, commandes exactes d'AD-5, vérification de version.
# Hors ligne : hugo est bouchonné et consigne ses arguments ; aucun site n'est construit ici.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# tools.env d'essai : seule la version de Hugo compte pour ces cas
essai_env() { # $1 version annoncée par le hugo bouchonné
  cat > "$work/tools.env" <<ENV
HUGO_VERSION=$1
HUGO_ARCHIVE=hugo.tar.gz
HUGO_URL=https://exemple.invalide/hugo.tar.gz
HUGO_SHA256=0000000000000000000000000000000000000000000000000000000000000000
D2_VERSION=4.5.6
D2_ARCHIVE=d2.tar.gz
D2_URL=https://exemple.invalide/d2.tar.gz
D2_SHA256=0000000000000000000000000000000000000000000000000000000000000000
CHECK_IMAGE=alpine@sha256:0000000000000000000000000000000000000000000000000000000000000000
CHECK_BOOTSTRAP_PACKAGES=bash
CHECK_BASE_PACKAGES=curl ca-certificates
CHECK_PACKAGES=git grep jq
ENV
}

stub_hugo() { # $1 version annoncée ; consigne ses arguments dans $work/hugo.log
  mkdir -p "$work/bin"
  printf '#!/bin/sh\nif [ "$1" = version ]; then echo "hugo v%s-abcdef linux/amd64"; exit 0; fi\necho "$@" >> "%s/hugo.log"\n' "$1" "$work" > "$work/bin/hugo"
  chmod +x "$work/bin/hugo"
  : > "$work/hugo.log"
}

build() { # lance build.sh avec le hugo bouchonné, le tools.env d'essai et une destination jetable :
          # aucun cas de test n'écrit ni n'efface dans le dépôt
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/tools.env" TOOLS_LOCAL_DIR="$work/bin" \
    BUILD_DESTINATION_ROOT="$work/sortie" "$root/scripts/build.sh" "$@"
}

case_build_production() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  build production
  assert_eq 0 "$rc" "build de production (messages : $err)"
  assert_contains "--environment production --minify --cleanDestinationDir --panicOnWarning --destination $work/sortie/public" "$(cat "$work/hugo.log")" "commande d AD-5, sans --buildDrafts"
  [[ $(cat "$work/hugo.log") != *--buildDrafts* ]] || { echo "la production a construit les brouillons" >&2; exit 1; }
}

case_build_travail() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  build work
  assert_eq 0 "$rc" "rendu de travail (messages : $err)"
  assert_contains "--environment work --buildDrafts --cleanDestinationDir --panicOnWarning --destination $work/sortie/build/work" "$(cat "$work/hugo.log")" "commande d AD-5, brouillons compris"
}

case_build_sans_argument() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  build
  assert_eq 2 "$rc" "code 2 : usage"
  assert_contains "usage :" "$err" "message d usage"
  assert_eq "" "$(cat "$work/hugo.log")" "hugo n est pas lancé"
}

case_build_argument_inconnu() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  build recette
  assert_eq 2 "$rc" "code 2 : usage"
  assert_contains "environnement inconnu" "$err" "argument nommé"
  assert_eq "" "$(cat "$work/hugo.log")" "hugo n est pas lancé"
}

case_build_version_differente() {
  essai_env 1.2.3
  stub_hugo 9.9.9
  build production
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "hugo en version 9.9.9" "$err" "version trouvée nommée"
  assert_eq "" "$(cat "$work/hugo.log")" "aucun build n est lancé avec le mauvais hugo"
}

case_dev_verifie_la_version() {
  essai_env 1.2.3
  stub_hugo 9.9.9
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/tools.env" TOOLS_LOCAL_DIR="$work/bin" "$root/scripts/dev.sh"
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "hugo en version 9.9.9" "$err" "dev.sh vérifie la version comme build.sh"
  assert_eq "" "$(cat "$work/hugo.log")" "aucun serveur n est lancé"
}

case_dev_commande_ad5() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/tools.env" TOOLS_LOCAL_DIR="$work/bin" "$root/scripts/dev.sh"
  assert_eq 0 "$rc" "serveur lancé (messages : $err)"
  assert_contains "server --environment work --buildDrafts" "$(cat "$work/hugo.log")" "commande d AD-5"
  [[ $(cat "$work/hugo.log") != *--panicOnWarning* ]] || { echo "dev.sh a passé --panicOnWarning" >&2; exit 1; }
}

case_build_prefere_les_outils_epingles() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  # un autre hugo, plus loin dans le PATH, ne doit jamais être choisi (D-15)
  mkdir -p "$work/systeme"
  printf '#!/bin/sh\nif [ "$1" = version ]; then echo "hugo v9.9.9 linux/amd64"; exit 0; fi\necho "SYSTEME $@" >> "%s/hugo.log"\n' "$work" > "$work/systeme/hugo"
  chmod +x "$work/systeme/hugo"
  run env PATH="$work/systeme:$PATH" TOOLS_ENV_FILE="$work/tools.env" TOOLS_LOCAL_DIR="$work/bin" \
    BUILD_DESTINATION_ROOT="$work/sortie" "$root/scripts/build.sh" production
  assert_eq 0 "$rc" "le hugo épinglé est choisi (messages : $err)"
  [[ $(cat "$work/hugo.log") != *SYSTEME* ]] || { echo "le hugo du système a été lancé" >&2; exit 1; }
}

case_build_argument_surnumeraire() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  build production inutile
  assert_eq 2 "$rc" "code 2 : usage"
  assert_contains "un seul argument attendu" "$err" "nombre d arguments nommé"
  assert_eq "" "$(cat "$work/hugo.log")" "hugo n est pas lancé"
}

case_build_vide_sa_destination() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  # le hugo bouchonné n'écrit rien : seule compte la disparition de la page périmée
  mkdir -p "$work/sortie/public/cas/perimee"
  printf '<html>page périmée</html>\n' > "$work/sortie/public/cas/perimee/index.html"
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/tools.env" TOOLS_LOCAL_DIR="$work/bin" \
    BUILD_DESTINATION_ROOT="$work/sortie" "$root/scripts/build.sh" production
  assert_eq 0 "$rc" "build lancé (messages : $err)"
  [[ ! -e $work/sortie/public/cas/perimee/index.html ]] || { echo "la page périmée a survécu au build" >&2; exit 1; }
  assert_contains "--destination $work/sortie/public" "$(cat "$work/hugo.log")" "hugo écrit dans la destination demandée"
}

case_dev_transmet_ses_arguments() {
  essai_env 1.2.3
  stub_hugo 1.2.3
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/tools.env" TOOLS_LOCAL_DIR="$work/bin" \
    "$root/scripts/dev.sh" --port 4242 --bind 0.0.0.0
  assert_eq 0 "$rc" "serveur lancé avec des arguments (messages : $err)"
  assert_contains "server --environment work --buildDrafts --port 4242 --bind 0.0.0.0" "$(cat "$work/hugo.log")" "arguments transmis après ceux d AD-5"
}

run_case "$@"
