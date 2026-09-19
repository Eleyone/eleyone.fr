#!/usr/bin/env bash
# Job de contrôles partagé (story 3.12) : la commande docker que le script hôte construit, les refus
# du script du conteneur, et le scénario C1 du clone jetable. Aucun cas ne lance Docker : la suite
# reste hors ligne (story 0.9). La recette du job complet vit dans docs/procedures/checks-job.md.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Faux docker : il écrit ses arguments, un par ligne, puis rend le code voulu.
faux_docker() { # $1 = code de sortie
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$@" > %s\n' "$work/arguments"
    printf 'exit %s\n' "$1"
  } > "$work/bin/docker"
  chmod +x "$work/bin/docker"
}

job() { # lance le script hôte avec le faux docker en tête du PATH
  run env PATH="$work/bin:$PATH" bash "$root/scripts/ci/checks-job.sh" "$@"
}

arguments() { cat "$work/arguments"; }

case_checks_job_commande_docker() {
  faux_docker 0
  job
  assert_eq 0 "$rc" "le job rend le code du conteneur (messages : $err)"
  local args
  args=$(arguments)
  assert_contains $'run\n--rm' "$args" "le conteneur est jetable"
  assert_contains "--volume
$root:/repo" "$args" "le dépôt est monté sur /repo"
  assert_contains "--workdir
/repo" "$args" "le répertoire de travail est le dépôt monté"
  assert_contains "HOST_UID=$(id -u)" "$args" "l'UID de l'appelant est passé au conteneur"
  assert_contains "HOST_GID=$(id -g)" "$args" "le GID aussi"
  assert_contains "sh
/repo/scripts/ci/checks-job-container.sh" "$args" "le conteneur lance la part qui lui revient"
}

case_checks_job_image_de_tools_env() {
  # L'image n'est déclarée que dans tools.env (AD-1) : le script l'y lit, il ne l'écrit pas.
  faux_docker 0
  job
  local image
  image=$(sed -n 's/^CHECK_IMAGE=//p' "$root/tools.env" | head -1)
  [[ -n $image ]] || { echo "CHECK_IMAGE absente de tools.env" >&2; exit 1; }
  assert_contains "$image" "$(arguments)" "l'image lancée est celle de tools.env"
  assert_contains "$image" "$out" "le script annonce l'image"
}

case_checks_job_autre_tools_env() {
  faux_docker 0
  sed 's#^CHECK_IMAGE=.*#CHECK_IMAGE=exemple/image@sha256:0000#' "$root/tools.env" > "$work/tools.env"
  run env PATH="$work/bin:$PATH" TOOLS_ENV_FILE="$work/tools.env" bash "$root/scripts/ci/checks-job.sh"
  assert_eq 0 "$rc" "le job passe (messages : $err)"
  assert_contains "exemple/image@sha256:0000" "$(arguments)" "l'image suit le tools.env désigné"
}

case_checks_job_code_du_conteneur() {
  # Tout échec rend un code non nul, et le code du conteneur ressort tel quel : un écart (1) ne se
  # confond pas avec une anomalie (2).
  faux_docker 1
  job
  assert_eq 1 "$rc" "un écart dans le conteneur fait échouer le job"
  faux_docker 2
  job
  assert_eq 2 "$rc" "une anomalie aussi, avec son code"
}

case_checks_job_sans_docker() {
  # PATH réduit à un dossier qui n'a que dirname : le script s'arrête avant de rien lancer.
  mkdir -p "$work/bin-nu"
  ln -sf "$(command -v dirname)" "$work/bin-nu/dirname"
  run env PATH="$work/bin-nu" "$(command -v bash)" "$root/scripts/ci/checks-job.sh"
  assert_eq 2 "$rc" "docker absent est une anomalie"
  assert_contains "docker est introuvable" "$err" "le message nomme l'outil manquant"
}

case_checks_job_argument_refuse() {
  faux_docker 0
  job --release
  assert_eq 2 "$rc" "un argument inattendu est refusé"
  assert_contains "aucun argument attendu" "$err" "le message le dit"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

# Les deux variables sont d'abord retirées : dans CHECK_IMAGE, la suite tourne à l'intérieur du job,
# qui les a définies, et le cas hériterait de celle qu'il veut absente (constaté au premier essai).
conteneur() { run env -u HOST_UID -u HOST_GID "$@" sh "$root/scripts/ci/checks-job-container.sh"; }

case_checks_job_conteneur_sans_compte() {
  conteneur HOST_GID=1000
  assert_eq 2 "$rc" "sans HOST_UID, le script du conteneur s'arrête"
  assert_contains "HOST_UID absente" "$err" "le message nomme la variable"
  conteneur HOST_UID=1000
  assert_eq 2 "$rc" "sans HOST_GID non plus"
  assert_contains "HOST_GID absente" "$err" "le message nomme la variable"
}

case_checks_job_conteneur_compte_invalide() {
  conteneur HOST_UID=arnaud HOST_GID=1000
  assert_eq 2 "$rc" "un UID qui n'est pas un nombre est refusé"
  assert_contains "HOST_UID n'est pas un nombre" "$err" "le message le dit"
}

case_checks_job_conteneur_hors_image() {
  # Sans apk, le script refuse plutôt que d'installer quoi que ce soit. Le PATH est réduit à un
  # dossier qui n'a que dirname : sinon le cas dépendrait de l'endroit où tourne la suite, et dans
  # CHECK_IMAGE, où apk existe, il relancerait le job entier (constaté au premier essai du job).
  mkdir -p "$work/bin-nu"
  ln -sf "$(command -v dirname)" "$work/bin-nu/dirname"
  run env PATH="$work/bin-nu" HOST_UID=1000 HOST_GID=1000 \
    "$(command -v sh)" "$root/scripts/ci/checks-job-container.sh"
  assert_eq 2 "$rc" "hors de l'image de contrôle, le script du conteneur s'arrête"
  assert_contains "apk est introuvable" "$err" "le message dit où ce script s'exécute"
}

case_checks_job_conteneur_argument_refuse() {
  run sh "$root/scripts/ci/checks-job-container.sh" --autre
  assert_eq 2 "$rc" "un argument inconnu est refusé"
  assert_contains "argument inconnu" "$err" "le message le dit"
}

case_checks_job_garde_fou_sur_un_clone_jetable() {
  # Deuxième scénario de la story : un commit fait sans hook ajoute un fichier sous docs/private/.
  # Le job lance le garde-fou en mode historique ; C1 doit échouer en nommant le commit et le chemin.
  new_repo
  mkdir -p "$work/depot/docs/private"
  echo "note" > "$work/depot/docs/private/note.md"
  local sha
  sha=$(commit_all "ajout hors hook")
  run env -u PRIVATE_PATTERNS_FILE bash -c "cd '$work/depot' && '$root/scripts/check-private.sh' history"
  assert_eq 1 "$rc" "le garde-fou refuse l'historique"
  assert_contains "${sha:0:7}" "$err$out" "le signalement nomme le commit"
  assert_contains "docs/private/note.md" "$err$out" "et le chemin interdit"
}

case_checks_job_garde_fou_clone_propre() {
  new_repo
  echo "contenu" > "$work/depot/README.md"
  commit_all "premier commit" > /dev/null
  run env -u PRIVATE_PATTERNS_FILE bash -c "cd '$work/depot' && '$root/scripts/check-private.sh' history"
  assert_eq 0 "$rc" "un historique propre passe (messages : $err)"
}

case_checks_job_conteneur_ignore_les_outils_du_poste() {
  # Le dépôt monté peut porter le .tools/ du poste : le conteneur doit employer les binaires qu'il a
  # installés lui-même (constat de la story 3.13).
  local contenu
  contenu=$(cat "$root/scripts/ci/checks-job-container.sh")
  assert_contains "TOOLS_LOCAL_DIR=/nonexistent/.tools" "$contenu" "le conteneur écarte le .tools du dépôt monté"
  assert_contains "export ENV_FILE HOME TOOLS_LOCAL_DIR" "$contenu" "et l'exporte, comme ENV_FILE"
}

run_case "$@"
