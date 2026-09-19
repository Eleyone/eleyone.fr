#!/usr/bin/env bash
# Workflows des forges (story 3.13) : un workflow ne contient que son déclencheur, le checkout et
# l'appel du job partagé (AD-11). Ces cas gardent cette règle : dès qu'une logique de contrôle
# s'écrirait dans le YAML, ou qu'une action perdrait son épinglage, un cas échoue.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

gitea_workflow="$root/.gitea/workflows/checks.yaml"

case_workflow_gitea_existe() {
  [[ -f $gitea_workflow ]] || { echo "workflow absent : $gitea_workflow" >&2; exit 1; }
}

case_workflow_gitea_declencheurs() {
  local contenu
  contenu=$(cat "$gitea_workflow")
  assert_contains "branches: [dev, main]" "$contenu" "le push n'écoute que dev et main (AD-11)"
  assert_contains "pull_request:" "$contenu" "les PR déclenchent aussi"
}

case_workflow_gitea_appelle_le_job_partage() {
  local contenu
  contenu=$(cat "$gitea_workflow")
  assert_contains "bash scripts/ci/checks-job.sh" "$contenu" "le workflow appelle le job partagé"
  assert_contains "fetch-depth: 0" "$contenu" "tout l'historique, pour le garde-fou"
  assert_contains "runs-on: linux_amd64" "$contenu" "le label du runner en mode hôte, sans son schéma"
  # Le nom du job est le nom du statut : c'est lui que les protections de branche et le verrou
  # « CI verte » cherchent (constat de la revue de la PR n° 49).
  assert_contains "  checks:" "$contenu" "le job s'appelle checks"
}

# Lecture d'une liste de lignes du workflow : « rien trouvé » (grep 1) donne une liste vide et laisse
# le cas dire ce qui manque, au lieu de tuer le harnais sous set -e ; une vraie erreur (2) échoue.
lignes() { # $1 = motif étendu
  local sortie rc=0
  sortie=$(grep -E "$1" "$gitea_workflow") || rc=$?
  ((rc <= 1)) || { printf 'lecture impossible du workflow (grep, code %s)\n' "$rc" >&2; exit 1; }
  printf '%s' "$sortie"
}

case_workflow_gitea_une_seule_commande() {
  # Aucune logique dans le YAML : une seule étape « run », et c'est l'appel du job.
  local commandes
  commandes=$(lignes '^\s*- run:|^\s*run:' | sed -E 's/^\s*- ?run:\s*//')
  assert_eq "bash scripts/ci/checks-job.sh" "$commandes" "une seule commande, celle du job partagé"
}

case_workflow_gitea_action_epinglee() {
  # Une URL absolue épinglée par SHA : la source et le commit sont fixés, et rien ne dépend du
  # réglage DEFAULT_ACTIONS_URL de la forge.
  local uses
  uses=$(lignes '^\s*- uses:' | sed -E 's/^\s*- uses:\s*//')
  [[ -n $uses ]] || { echo "aucune action utilisée : le checkout a disparu" >&2; exit 1; }
  while IFS= read -r ligne; do
    local reference=${ligne%%#*}
    reference=${reference%"${reference##*[![:space:]]}"}
    # La source est vérifiée, pas seulement la forme : une URL absolue épinglée par SHA vers un
    # dépôt quelconque passerait sinon (constat de la revue de la PR n° 49).
    assert_contains "https://gitea.com/actions/" "$reference" "l'action vient des actions officielles, par une URL absolue : $ligne"
    [[ $reference =~ @[0-9a-f]{40}$ ]] \
      || { printf 'action non épinglée par SHA : %s\n' "$ligne" >&2; exit 1; }
    assert_contains "#" "$ligne" "le SHA est suivi du commentaire de version : $ligne"
  done <<< "$uses"
}

run_case "$@"
