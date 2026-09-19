#!/bin/sh
# Part du job de contrôles qui tourne **dans** CHECK_IMAGE (AD-11), lancée par scripts/ci/checks-job.sh.
# En sh POSIX du début à la fin : alpine:3.24 n'a pas bash avant l'amorçage, et rien n'oblige la
# suite à en changer.
#
#   sh scripts/ci/checks-job-container.sh           dans le conteneur : outils, puis bascule de compte
#   sh scripts/ci/checks-job-container.sh --steps   les contrôles eux-mêmes, sous le compte de l'hôte
#
# Deux temps, parce que les droits ne sont pas les mêmes :
#   1. en root, parce qu'apk l'exige : scripts/ci/install-tools-bootstrap.sh pose bash, les outils de
#      contrôle, Hugo et D2 ;
#   2. sous l'UID et le GID de l'appelant, par su-exec : tout ce qui écrit dans le dépôt monté
#      (public/, build/) appartient alors à l'appelant et non à root, si bien qu'un scripts/check.sh
#      lancé ensuite sur le poste sait encore vider ses sorties.
#
# ENV_FILE désigne un chemin inexistant : le dépôt est monté tel quel, .env compris, et scripts/env.sh
# le lirait avant le fichier factice. Les valeurs légales du job sont donc celles d'AD-9
# (ci/legal-placeholder.env), chargées par scripts/env.sh dans le seul processus du conteneur.
# Codes de sortie : celui du contrôle en échec (1 écart, 2 anomalie) ; 2 si le contexte manque.
# Procédure : docs/procedures/checks-job.md
set -eu

script_name=checks-job-container
root=$(cd "$(dirname "$0")/../.." && pwd)

die() { echo "$script_name: $1" >&2; exit 2; }

if [ "${1:-}" = "--steps" ]; then
  # Le .env du dépôt monté n'est pas lu : voir l'en-tête.
  ENV_FILE=/nonexistent/.env
  # HOME appartient à root dans l'image ; git et hugo écriraient leur cache dans un dossier interdit.
  HOME=/tmp
  # Le dépôt monté peut porter le .tools/ du poste, que scripts/build.sh place en tête du PATH : le
  # job emploierait alors les binaires du poste au lieu de ceux qu'il vient d'installer dans l'image.
  # TOOLS_LOCAL_DIR désigne donc un dossier inexistant (constat de la story 3.13).
  TOOLS_LOCAL_DIR=/nonexistent/.tools
  export ENV_FILE HOME TOOLS_LOCAL_DIR
  cd "$root"
  # Chaque étape s'annonce : le garde-fou et les tests ne disent rien quand tout va bien, et un
  # journal de CI muet ne permet pas de savoir ce qui a tourné.
  echo "$script_name: garde-fou public/privé sur tout l'historique."
  "$root/scripts/check-private.sh" history
  echo "$script_name: tests des scripts."
  "$root/scripts/tests/run.sh"
  echo "$script_name: contrôles."
  "$root/scripts/check.sh"
  exit 0
fi

[ $# -eq 0 ] || die "argument inconnu « $1 » ; usage : $0 [--steps]"

case "${HOST_UID:-}" in
  '') die "HOST_UID absente : ce script est lancé par scripts/ci/checks-job.sh, jamais à la main." ;;
  *[!0-9]*) die "HOST_UID n'est pas un nombre." ;;
esac
case "${HOST_GID:-}" in
  '') die "HOST_GID absente : ce script est lancé par scripts/ci/checks-job.sh, jamais à la main." ;;
  *[!0-9]*) die "HOST_GID n'est pas un nombre." ;;
esac

command -v apk > /dev/null 2>&1 \
  || die "apk est introuvable : ce script s'exécute dans CHECK_IMAGE (AD-1), pas sur le poste."

"$root/scripts/ci/install-tools-bootstrap.sh"

command -v su-exec > /dev/null 2>&1 \
  || die "su-exec est introuvable après l'installation : vérifier CHECK_BASE_PACKAGES dans tools.env."

exec su-exec "$HOST_UID:$HOST_GID" sh "$0" --steps
