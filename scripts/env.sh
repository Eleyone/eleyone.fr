#!/usr/bin/env bash
# Chargeur unique des valeurs légales (AD-9). Enveloppe : il prépare l'environnement, puis lance la
# commande qu'on lui donne. Hugo ne lit pas .env ; lui seul décide de ce que voit le processus.
#
#   scripts/env.sh <commande> [<arguments>…]   hors mise en ligne : variables déjà définies, puis
#                                              .env, puis ci/legal-placeholder.env, variable par variable
#   ENV_MODE=release LEGAL_ENV_FILE=<fichier> scripts/env.sh <commande>…
#                                              mise en ligne : le fichier désigné est obligatoire,
#                                              .env et le fichier factice sont refusés, et toute
#                                              variable manquante fait échouer le chargeur
#
# Seules les lignes ^HUGO_LEGAL_ sont lues : les jetons qui vivent dans le même .env (GITEA_*, AD-24)
# n'entrent jamais dans l'environnement du processus lancé. Aucun message n'affiche de valeur.
# Codes de sortie : celui de la commande ; 1 refus (mise en ligne mal configurée) ; 2 usage ou anomalie.
set -euo pipefail
set +x # même lancé avec bash -x, la trace s'arrête ici : .env porte aussi des jetons

script_name=env
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$root/scripts/lib/dotenv.sh"

(($#)) || { printf 'usage : %s <commande> [<arguments>…]\n' "$0" >&2; exit 2; }

readonly legal_variables=(
  HUGO_LEGAL_PUBLISHER_NAME
  HUGO_LEGAL_PUBLISHER_ADDRESS
  HUGO_LEGAL_PUBLISHER_CONTACT
  HUGO_LEGAL_PUBLISHER_REGISTRATION
  HUGO_LEGAL_HOST_NAME
  HUGO_LEGAL_HOST_ADDRESS
  HUGO_LEGAL_HOST_CONTACT
)

env_file="${ENV_FILE:-$root/.env}"
placeholder_file="${LEGAL_PLACEHOLDER_FILE:-$root/ci/legal-placeholder.env}"
mode="${ENV_MODE:-local}"

# chemin canonique, pour qu'un « ./.env » ou un « ../ailleurs/.env » ne se fasse pas passer pour autre chose
canonical() { local path=$1; [[ -e $path ]] || { printf '%s' "$path"; return 0; }; readlink -f -- "$path"; }

# $1 fichier ; charge les variables légales absentes de l'environnement, sans écraser ce qui est défini
charger_absentes() {
  local file=$1 lines line key name
  lines=$(dotenv_read "$file" HUGO_LEGAL_) || { echo "$script_name: fichier de valeurs illisible ($file)." >&2; exit 2; }
  while IFS= read -r line; do
    [[ -n $line ]] || continue
    key=${line%%=*}
    for name in "${legal_variables[@]}"; do
      [[ $key == "$name" ]] || continue
      [[ -n ${!name:-} ]] && break   # déjà définie : priorité à l'environnement
      export "$name=${line#*=}"
      break
    done
  done <<< "$lines"
}

if [[ $mode == release ]]; then
  [[ -n ${LEGAL_ENV_FILE:-} ]] || { echo "$script_name: ENV_MODE=release sans LEGAL_ENV_FILE : mise en ligne refusée." >&2; exit 1; }
  [[ -r $LEGAL_ENV_FILE ]] || { echo "$script_name: LEGAL_ENV_FILE introuvable ou illisible." >&2; exit 1; }
  # deux refus : le fichier lui-même (chemin canonique), et tout fichier nommé .env, d'où qu'il vienne
  designated=$(canonical "$LEGAL_ENV_FILE")
  for forbidden in "$env_file" "$placeholder_file"; do
    [[ $designated != "$(canonical "$forbidden")" ]] || { echo "$script_name: LEGAL_ENV_FILE désigne un fichier de travail du dépôt : mise en ligne refusée." >&2; exit 1; }
  done
  [[ $(basename -- "$designated") != .env ]] || { echo "$script_name: LEGAL_ENV_FILE nommé .env : une mise en ligne emploie un fichier de secrets dédié." >&2; exit 1; }
  charger_absentes "$LEGAL_ENV_FILE"
  for name in "${legal_variables[@]}"; do
    [[ -n ${!name:-} ]] || { echo "$script_name: $name absente : mise en ligne refusée." >&2; exit 1; }
  done
else
  [[ ! -r $env_file ]] || charger_absentes "$env_file"
  [[ ! -r $placeholder_file ]] || charger_absentes "$placeholder_file"
fi

exec "$@"
