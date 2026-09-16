#!/usr/bin/env bash
# Installe les outils épinglés par tools.env (AD-1), vérifiés par sha256.
#
#   scripts/ci/install-tools-bootstrap.sh  image de contrôle et étape « tools » du Dockerfile : en sh
#                                          POSIX, il pose bash (absent d'alpine) puis lance ce script
#   scripts/ci/install-tools.sh            même travail, une fois bash présent : paquets de contrôle
#                                          par apk, puis Hugo et D2
#   scripts/ci/install-tools.sh --local    poste de développement : Hugo et D2 seulement, dans .tools/
#
# Les versions, les empreintes et l'adresse des archives ne sont déclarées que dans tools.env.
# Trois variables ne servent qu'aux tests hors ligne, jamais à la CI : TOOLS_ENV_FILE (autre tools.env),
# TOOLS_BASE_URL (adresse de téléchargement, un dossier local file://…) et TOOLS_LOCAL_DIR (dossier
# d'installation de --local, .tools/ par défaut). TOOLS_TARGET_DIR fait de même hors --local.
# Codes de sortie : 0 installé, 1 refus (empreinte, version), 2 anomalie (tools.env, outil manquant).
set -euo pipefail

script_name=install-tools
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
. "$root/scripts/lib/tools.sh"

local_only=0
case "${1:-}" in
  --local) local_only=1 ;;
  "") ;;
  *) echo "usage : $0 [--local]" >&2; exit 2 ;;
esac

load_tools_env "${TOOLS_ENV_FILE:-$root/tools.env}"

# Dans l'image de contrôle, les paquets viennent d'abord : alpine:3.24 n'a ni curl ni certificats,
# donc rien ne peut être téléchargé avant cet apk.
if ((local_only == 0)); then
  command -v apk >/dev/null 2>&1 || tools_die "apk est introuvable : cette forme s'exécute dans l'image de contrôle (CHECK_IMAGE)."
  # shellcheck disable=SC2086
  apk add --no-cache $CHECK_BASE_PACKAGES $CHECK_PACKAGES >/dev/null || { echo "$script_name: installation des paquets de contrôle impossible." >&2; exit 1; }
fi

for tool in curl tar sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || tools_die "$tool est introuvable : installation impossible."
done

if ((local_only)); then
  target=${TOOLS_LOCAL_DIR:-$root/.tools}
else
  target=${TOOLS_TARGET_DIR:-/usr/local/bin}
fi
mkdir -p "$target" || tools_die "création impossible de $target."

tmp=$(mktemp -d) || tools_die "dossier temporaire impossible."
trap 'rm -rf "$tmp"' EXIT

# $1 nom de l'outil, $2 adresse, $3 nom de l'archive, $4 empreinte attendue, $5 chemin du binaire dans l'archive
install_tool() {
  local tool=$1 url=$2 archive=$3 sha=$4 member=$5 rc=0
  [[ -z ${TOOLS_BASE_URL:-} ]] || url="$TOOLS_BASE_URL/$archive"
  curl -sSfL --max-time 600 -o "$tmp/$archive" "$url" || rc=$?
  ((rc == 0)) || { echo "$script_name: téléchargement de $tool impossible (code $rc)." >&2; exit 1; }
  # comparaison faite ici plutôt que par « sha256sum -c » : le sha256sum de BusyBox, celui de l'image de
  # contrôle, ne connaît ni --status ni le format long de GNU. Une empreinte n'est pas un secret.
  local actual
  actual=$(sha256sum "$tmp/$archive" | cut -d' ' -f1) || { echo "$script_name: empreinte de $tool incalculable." >&2; exit 2; }
  [[ -n $actual ]] || { echo "$script_name: empreinte de $tool vide : rien n'est installé." >&2; exit 2; }
  [[ $actual == "$sha" ]] || { echo "$script_name: empreinte de $tool différente de celle de tools.env ($actual) : rien n'est installé." >&2; exit 1; }
  tar -xzf "$tmp/$archive" -C "$tmp" "$member" || { echo "$script_name: $member absent de l'archive de $tool." >&2; exit 1; }
  # le binaire est remplacé sans rien demander : .tools/ est un cache, et une montée de version se fait
  # en modifiant tools.env seul (décision d'Arnaud, story 2.1)
  install -m 0755 "$tmp/$member" "$target/$tool" || { echo "$script_name: installation de $tool impossible dans $target." >&2; exit 1; }
}

install_tool hugo "$HUGO_URL" "$HUGO_ARCHIVE" "$HUGO_SHA256" hugo
install_tool d2 "$D2_URL" "$D2_ARCHIVE" "$D2_SHA256" "d2-v$D2_VERSION/bin/d2"

require_tool_version hugo "$target/hugo" "$HUGO_VERSION"
require_tool_version d2 "$target/d2" "$D2_VERSION"

printf '%s: hugo %s et d2 %s installés dans %s.\n' "$script_name" "$HUGO_VERSION" "$D2_VERSION" "$target"
