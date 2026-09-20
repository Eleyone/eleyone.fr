#!/usr/bin/env bash
# Job de contrôles partagé (AD-11) : la même exécution sur le poste, sur Gitea et sur GitHub. Les
# workflows ne contiennent que leur déclencheur, le checkout et l'appel de ce script ; toute la
# logique est ici, pour qu'aucune forge n'en porte une version à elle.
#
#   scripts/ci/checks-job.sh    lance le conteneur de contrôle et y enchaîne les contrôles
#
# Le script lance « docker run --rm » sur CHECK_IMAGE, déclarée par tools.env seul (AD-1), le dépôt
# monté et pris pour répertoire de travail. Le conteneur fait le reste (scripts/ci/checks-job-container.sh) :
# outils épinglés posés en root, puisque apk l'exige, puis bascule vers le compte de l'appelant pour
# le garde-fou en mode historique, les tests des scripts et scripts/check.sh.
#
# L'UID et le GID de l'appelant lui sont passés : sans cette bascule, public/ et build/, écrits dans
# le dépôt monté, appartiendraient à root, et le scripts/check.sh suivant échouerait à les vider
# (décidé par Arnaud le 19/09/2026, revue de spec de la story 3.12).
#
# Le job ne lit aucun secret et ne construit aucune image : docker run part d'un environnement vide,
# et le conteneur désigne ENV_FILE sur un chemin inexistant, si bien qu'un .env présent dans le dépôt
# monté n'est pas lu. Les valeurs légales sont les valeurs factices d'AD-9.
# Codes de sortie : celui du conteneur (0 conforme, 1 écart, 2 anomalie) ; 2 si Docker ou tools.env manque.
# Procédure : docs/procedures/checks-job.md
set -euo pipefail

script_name=checks-job
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
. "$root/scripts/lib/tools.sh"

(($# == 0)) || { printf '%s: aucun argument attendu, %s reçu(s).\nusage : %s\n' "$script_name" "$#" "$0" >&2; exit 2; }

load_tools_env "${TOOLS_ENV_FILE:-$root/tools.env}"

command -v docker > /dev/null 2>&1 \
  || tools_die "docker est introuvable : les contrôles tournent dans CHECK_IMAGE (AD-1, prérequis du poste)."

uid=$(id -u) || tools_die "UID de l'appelant illisible."
gid=$(id -g) || tools_die "GID de l'appelant illisible."

# L'image est tirée à part, et seulement si elle manque : le registre limite les tirages anonymes par
# adresse IP, or les runners publics partagent les leurs (constat de la story 3.14). Un refus
# temporaire ferait rougir la CI sans que rien ne soit en cause ; trois tentatives espacées
# suffisent, et l'échec définitif est une anomalie, nommée comme telle. CHECKS_JOB_RETRY_DELAY ne
# sert qu'aux tests, comme TOOLS_ENV_FILE ailleurs.
delai=${CHECKS_JOB_RETRY_DELAY:-10}
tirer_image() {
  local essai=1 rc
  while ((essai <= 3)); do
    rc=0
    docker pull --quiet "$CHECK_IMAGE" > /dev/null || rc=$?
    ((rc != 0)) || return 0
    printf '%s: tirage de l'"'"'image refusé (docker, code %s), tentative %s sur 3.\n' "$script_name" "$rc" "$essai" >&2
    ((essai == 3)) || sleep $((delai * essai))
    essai=$((essai + 1))
  done
  return 1
}
if ! docker image inspect "$CHECK_IMAGE" > /dev/null 2>&1; then
  tirer_image \
    || tools_die "image de contrôle intirable après 3 tentatives : registre indisponible, ou tirages anonymes limités."
fi

printf '%s: contrôles dans %s, dépôt monté sur /repo, compte %s:%s.\n' "$script_name" "$CHECK_IMAGE" "$uid" "$gid"

# Le code du conteneur est celui du dernier contrôle en échec : il ressort tel quel.
exec docker run --rm \
  --volume "$root:/repo" \
  --workdir /repo \
  --env "HOST_UID=$uid" \
  --env "HOST_GID=$gid" \
  "$CHECK_IMAGE" \
  sh /repo/scripts/ci/checks-job-container.sh
