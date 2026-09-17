#!/usr/bin/env bash
# Serveur local du rendu de travail (AD-5) : brouillons compris, jamais la production.
#
#   scripts/dev.sh [<options hugo server>]
#
# Sans --panicOnWarning, à la différence de build.sh : un serveur qui meurt au premier avertissement,
# à chaque sauvegarde, est inutilisable (décidé le 16/09/2026, story 2.2). Les avertissements restent
# bloquants dans build.sh et dans les deux CI.
# Codes de sortie : ceux de hugo server ; 1 si la version de Hugo ne correspond pas, 2 anomalie.
set -euo pipefail

script_name=dev
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$root/scripts/lib/tools.sh"

load_tools_env "${TOOLS_ENV_FILE:-$root/tools.env}"

tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
[[ -d $tools_dir ]] && PATH="$tools_dir:$PATH"
export PATH

require_tool_version hugo hugo "$HUGO_VERSION" || exit 1

cd "$root"
# AD-9 : le serveur de travail passe par le même chargeur que build.sh.
exec "$root/scripts/env.sh" hugo server --environment work --buildDrafts "$@"
