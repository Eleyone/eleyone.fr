#!/usr/bin/env bash
# Outils épinglés (story 2.1) : lecture de tools.env, vérification de version, installation.
# Hors ligne : les archives sont factices et servies depuis un dossier local (file://), jamais le réseau.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# tools.env d'essai, avec des empreintes calculées sur les archives factices
fake_env() { # $1 empreinte hugo, $2 empreinte d2
  cat > "$work/tools.env" <<ENV
HUGO_VERSION=1.2.3
HUGO_ARCHIVE=hugo-essai.tar.gz
HUGO_URL=https://exemple.invalide/hugo-essai.tar.gz
HUGO_SHA256=$1
D2_VERSION=4.5.6
D2_ARCHIVE=d2-essai.tar.gz
D2_URL=https://exemple.invalide/d2-essai.tar.gz
D2_SHA256=$2
CHECK_IMAGE=alpine@sha256:0000000000000000000000000000000000000000000000000000000000000000
CHECK_BOOTSTRAP_PACKAGES=bash
CHECK_BASE_PACKAGES=curl ca-certificates
CHECK_PACKAGES=git grep jq
ENV
}

# archives factices : un « hugo » à la racine, un « d2-v4.5.6/bin/d2 », chacun annonçant sa version
fake_archives() {
  mkdir -p "$work/source/d2-v4.5.6/bin" "$work/depot-archives"
  printf '#!/bin/sh\necho "hugo v1.2.3-abcdef linux/amd64"\n' > "$work/source/hugo"
  printf '#!/bin/sh\necho "v4.5.6"\n' > "$work/source/d2-v4.5.6/bin/d2"
  chmod +x "$work/source/hugo" "$work/source/d2-v4.5.6/bin/d2"
  tar -czf "$work/depot-archives/hugo-essai.tar.gz" -C "$work/source" hugo
  tar -czf "$work/depot-archives/d2-essai.tar.gz" -C "$work/source" d2-v4.5.6
  hugo_sha=$(sha256sum "$work/depot-archives/hugo-essai.tar.gz" | cut -d' ' -f1)
  d2_sha=$(sha256sum "$work/depot-archives/d2-essai.tar.gz" | cut -d' ' -f1)
}

install_local() { # lance l'installation hors ligne dans un dossier jetable
  run env TOOLS_ENV_FILE="$work/tools.env" TOOLS_BASE_URL="file://$work/depot-archives" \
    TOOLS_LOCAL_DIR="$work/outils" "$root/scripts/ci/install-tools.sh" --local
}

charge_env() { # $1 fichier tools.env ; lance load_tools_env dans un processus à part, car il sort
  run bash -c 'script_name=essai; . "$1/scripts/lib/tools.sh"; load_tools_env "$2"; echo "$HUGO_VERSION $D2_VERSION $CHECK_PACKAGES"' _ "$root" "$1"
}

case_tools_env_lu() {
  fake_archives
  fake_env "$hugo_sha" "$d2_sha"
  charge_env "$work/tools.env"
  assert_eq 0 "$rc" "tools.env lu"
  assert_contains "1.2.3 4.5.6 git grep jq" "$out" "valeurs épinglées lues, espaces compris"
}

case_tools_env_absent() {
  charge_env "$work/absent.env"
  assert_eq 2 "$rc" "code 2 : anomalie"
  assert_contains "tools.env introuvable" "$err" "fichier nommé"
}

case_tools_env_variable_manquante() {
  fake_archives
  fake_env "$hugo_sha" "$d2_sha"
  grep -v '^D2_SHA256=' "$work/tools.env" > "$work/incomplet.env"
  charge_env "$work/incomplet.env"
  assert_eq 2 "$rc" "code 2 : anomalie"
  assert_contains "D2_SHA256 absente ou vide" "$err" "variable nommée"
}

case_tools_env_variable_vide() {
  fake_archives
  fake_env "$hugo_sha" ""
  charge_env "$work/tools.env"
  assert_eq 2 "$rc" "une valeur vide ne passe pas pour une empreinte"
  assert_contains "D2_SHA256 absente ou vide" "$err" "variable nommée"
}

case_installation_locale() {
  fake_archives
  fake_env "$hugo_sha" "$d2_sha"
  install_local
  assert_eq 0 "$rc" "installation hors ligne réussie (messages : $err)"
  [[ -x $work/outils/hugo && -x $work/outils/d2 ]] || { echo "binaires absents de $work/outils" >&2; exit 1; }
  assert_contains "1.2.3" "$("$work/outils/hugo" version)" "hugo installé annonce sa version"
  assert_contains "4.5.6" "$("$work/outils/d2" --version)" "d2 installé annonce sa version"
}

case_empreinte_differente() {
  fake_archives
  fake_env "0000000000000000000000000000000000000000000000000000000000000000" "$d2_sha"
  install_local
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "empreinte de hugo différente" "$err" "outil nommé"
  [[ ! -e $work/outils/hugo ]] || { echo "le binaire a été installé malgré l'empreinte" >&2; exit 1; }
}

case_binaire_obsolete_remplace() {
  fake_archives
  fake_env "$hugo_sha" "$d2_sha"
  mkdir -p "$work/outils"
  printf '#!/bin/sh\necho "hugo v0.0.1 linux/amd64"\n' > "$work/outils/hugo"
  chmod +x "$work/outils/hugo"
  install_local
  assert_eq 0 "$rc" "le binaire obsolète est remplacé sans intervention (messages : $err)"
  assert_contains "1.2.3" "$("$work/outils/hugo" version)" "version de tools.env installée"
}

case_version_differente_refusee() {
  mkdir -p "$work/outils"
  printf '#!/bin/sh\necho "hugo v9.9.9 linux/amd64"\n' > "$work/outils/hugo"
  chmod +x "$work/outils/hugo"
  run bash -c 'script_name=essai; . "$1/scripts/lib/tools.sh"; require_tool_version hugo "$2" 1.2.3' _ "$root" "$work/outils/hugo"
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "hugo en version 9.9.9" "$err" "version trouvée nommée"
  assert_contains "tools.env épingle 1.2.3" "$err" "version attendue nommée"
}

case_version_conforme_admise() {
  mkdir -p "$work/outils"
  printf '#!/bin/sh\necho "v4.5.6"\n' > "$work/outils/d2"
  chmod +x "$work/outils/d2"
  run bash -c 'script_name=essai; . "$1/scripts/lib/tools.sh"; require_tool_version d2 "$2" 4.5.6' _ "$root" "$work/outils/d2"
  assert_eq 0 "$rc" "version conforme admise (messages : $err)"
}

case_binaire_absent() {
  run bash -c 'script_name=essai; . "$1/scripts/lib/tools.sh"; require_tool_version hugo "$2" 1.2.3' _ "$root" "$work/nulle-part/hugo"
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "hugo introuvable" "$err" "outil nommé"
}

case_valeur_avec_espace_de_fin() {
  fake_archives
  fake_env "$hugo_sha" "$d2_sha"
  # une espace invisible en fin de ligne ne doit pas entrer dans l'empreinte
  sed -i "s/^D2_SHA256=$d2_sha\$/D2_SHA256=$d2_sha   /" "$work/tools.env"
  install_local
  assert_eq 0 "$rc" "l espace de fin est retiré, l installation passe (messages : $err)"
}

# --- amorçage POSIX de l'image de contrôle, avec un apk bouchonné (hors ligne) --------------------------------

stub_apk() { # apk factice : consigne ses arguments et ne fait rien d'autre
  mkdir -p "$work/bin"
  printf '#!/bin/sh\necho "$@" >> "%s/apk.log"\n' "$work" > "$work/bin/apk"
  chmod +x "$work/bin/apk"
  : > "$work/apk.log"
}

case_amorcage_pose_bash_puis_passe_la_main() {
  fake_archives
  fake_env "$hugo_sha" "$d2_sha"
  stub_apk
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/tools.env" \
    TOOLS_BASE_URL="file://$work/depot-archives" TOOLS_TARGET_DIR="$work/outils" \
    "$root/scripts/ci/install-tools-bootstrap.sh"
  assert_eq 0 "$rc" "amorçage puis installation (messages : $err)"
  assert_contains "add --no-cache bash" "$(cat "$work/apk.log")" "paquet d amorçage lu dans tools.env"
  assert_contains "curl ca-certificates git grep jq" "$(cat "$work/apk.log")" "prérequis et outils de contrôle posés avant tout téléchargement"
  [[ -x $work/outils/hugo && -x $work/outils/d2 ]] || { echo "binaires absents de $work/outils" >&2; exit 1; }
}

case_amorcage_sans_variable() {
  fake_archives
  fake_env "$hugo_sha" "$d2_sha"
  grep -v "^CHECK_BOOTSTRAP_PACKAGES=" "$work/tools.env" > "$work/sans-amorcage.env"
  stub_apk
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/sans-amorcage.env" \
    "$root/scripts/ci/install-tools-bootstrap.sh"
  assert_eq 2 "$rc" "code 2 : anomalie"
  assert_contains "CHECK_BOOTSTRAP_PACKAGES absente ou vide" "$err" "variable nommée"
  assert_eq "" "$(cat "$work/apk.log")" "aucun apk lancé sans la variable"
}

case_amorcage_tools_env_absent() {
  stub_apk
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/absent.env" \
    "$root/scripts/ci/install-tools-bootstrap.sh"
  assert_eq 2 "$rc" "code 2 : anomalie"
  assert_contains "tools.env introuvable ou illisible" "$err" "fichier nommé"
}

run_case "$@"
