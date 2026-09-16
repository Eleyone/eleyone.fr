#!/bin/sh
# Amorçage de l'image de contrôle (AD-1) : alpine:3.24 n'a pas bash, que scripts/ci/install-tools.sh
# utilise. Ce script-ci est donc en sh POSIX. Il pose les paquets d'amorçage déclarés par tools.env,
# puis passe la main. Rien n'est déclaré ici : les paquets viennent de CHECK_BOOTSTRAP_PACKAGES.
#
#   scripts/ci/install-tools-bootstrap.sh   dans l'image de contrôle et à l'étape « tools » du Dockerfile
#
# Codes de sortie : ceux de install-tools.sh ; 2 si tools.env manque ou n'a pas la variable d'amorçage.
set -eu

script_name=install-tools-bootstrap
root=$(cd "$(dirname "$0")/../.." && pwd)
env_file=${TOOLS_ENV_FILE:-$root/tools.env}

[ -r "$env_file" ] || { echo "$script_name: tools.env introuvable ou illisible ($env_file)." >&2; exit 2; }
# tr -d '\r' : un tools.env passé par un éditeur Windows donnerait « bash\r », et apk échouerait.
# scripts/lib/tools.sh fait de même pour les lectures en bash ; les deux chemins lisent donc pareil.
packages=$(sed -n 's/^CHECK_BOOTSTRAP_PACKAGES=//p' "$env_file" | head -n 1 | tr -d '\r')
[ -n "$packages" ] || { echo "$script_name: CHECK_BOOTSTRAP_PACKAGES absente ou vide dans $env_file." >&2; exit 2; }

command -v apk > /dev/null 2>&1 || { echo "$script_name: apk est introuvable : cet amorçage s'exécute dans l'image de contrôle (CHECK_IMAGE)." >&2; exit 2; }
# shellcheck disable=SC2086
apk add --no-cache $packages > /dev/null || { echo "$script_name: installation des paquets d'amorçage impossible." >&2; exit 1; }

exec bash "$root/scripts/ci/install-tools.sh" "$@"
