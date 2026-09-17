#!/usr/bin/env bash
# Seul appel à hugo des scripts et du Dockerfile (AD-5). Les options et les dossiers de sortie sont fixes :
#
#   scripts/build.sh production   site publiable    → public/
#   scripts/build.sh work         rendu de travail  → build/work/   (brouillons compris)
#
# Les deux sorties ne se mélangent jamais. La version de Hugo est vérifiée avant l'appel : un autre
# Hugo dans le PATH produirait un rendu qui diverge de celui des CI et de l'image (AD-1).
# Codes de sortie : 0 build réussi, 1 refus (version, build en échec), 2 usage ou anomalie.
set -euo pipefail

script_name=build
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$root/scripts/lib/tools.sh"

environment=${1:-}
(($# <= 1)) || { printf '%s: un seul argument attendu, %s reçus.\nusage : %s production | work\n' "$script_name" "$#" "$0" >&2; exit 2; }
case "$environment" in
  production|work) ;;
  "") echo "usage : $0 production | work" >&2; exit 2 ;;
  *) printf '%s: environnement inconnu « %s ».\nusage : %s production | work\n' "$script_name" "$environment" "$0" >&2; exit 2 ;;
esac

load_tools_env "${TOOLS_ENV_FILE:-$root/tools.env}"

# D-15 : les outils épinglés du poste passent devant ceux du système, s'ils sont installés.
# TOOLS_LOCAL_DIR nomme ce dossier, comme dans install-tools.sh ; seuls les tests s'en servent.
tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
[[ -d $tools_dir ]] && PATH="$tools_dir:$PATH"
export PATH

require_tool_version hugo hugo "$HUGO_VERSION" || exit 1

cd "$root"
# --cleanDestinationDir ne supprime pas les fichiers d'un build précédent (constaté avec Hugo 0.166 :
# une page déposée à la main dans public/ survit au build suivant). Le dossier est donc vidé ici, sans
# quoi une page retirée du site resterait servie et le contrôle des pages publiées passerait sur une
# sortie sale. Le drapeau est gardé : il reste celui d'AD-5, et il ne coûte rien.
# BUILD_DESTINATION_ROOT ne sert qu'aux tests, comme TOOLS_ENV_FILE et TOOLS_LOCAL_DIR ; la CI et le
# poste écrivent toujours dans le dépôt.
destination_root=${BUILD_DESTINATION_ROOT:-$root}
relative=$( [[ $environment == production ]] && echo public || echo build/work )
destination="${destination_root:?}/$relative"
rm -rf "$destination" || { echo "$script_name: nettoyage impossible de $relative." >&2; exit 2; }

# AD-9 : tout appel à hugo passe par le chargeur, seul à décider de ce que voit le processus.
if [[ $environment == production ]]; then
  exec "$root/scripts/env.sh" hugo --environment production --minify --cleanDestinationDir --panicOnWarning --destination "$destination"
else
  exec "$root/scripts/env.sh" hugo --environment work --buildDrafts --cleanDestinationDir --panicOnWarning --destination "$destination"
fi
