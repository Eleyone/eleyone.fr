#!/usr/bin/env bash
# Enveloppes communes (.working-method/lib/shell.sh, actions de la rétrospective de l'epic 3) : ce
# que le projet en fait. Leur contrat — trouver, ne rien trouver, s'arrêter sur une erreur de lecture,
# rendre le code de grep — se vérifie dans l'outillage commun depuis la story outillage-14
# (.working-method/tests/test-shell-lib.sh, cinq cas au mot près). Restent ici les cas qui lisent les
# scripts de ce dépôt : la règle du pipeline sur les scripts du projet, et les deux constats de la
# rétrospective sur les contrôles.
. "$(dirname "${BASH_SOURCE[0]}")/../../.working-method/tests/lib.sh"

case_checks_attributes_ecrite_une_fois() {
  # Constat A1 de la rétrospective : la fonction vivait en trois exemplaires.
  local copies
  shell_grep_into copies -lE '^(attributs|xpath_attributs)\(\)' "$root"/scripts/checks/*.sh
  assert_eq "" "$copies" "aucun contrôle ne garde sa copie de l'extraction d'attributs"
  local contenu
  contenu=$(cat "$root/scripts/checks/lib.sh")
  assert_contains "checks_attributes()" "$contenu" "elle vit dans la bibliothèque des contrôles"
}

case_liste_vide_nest_pas_une_conformite() {
  # Constat A3 : un contrôle qui ne trouve aucun fichier annonçait « conforme ».
  #
  # Chaque contrôle reçoit tout ce qu'il lui faut **sauf** des pages : html.sh lit le manifeste avant
  # la liste des pages, et sans lui le cas s'arrêtait sur une autre anomalie — vrai sur un poste où
  # un rendu de travail traîne, faux en CI, où la suite tourne avant tout build. Le cas a échoué
  # ainsi à sa première exécution en CI : un cas doit rendre le même verdict des deux côtés.
  mkdir -p "$work/vide" "$work/rendu"
  printf '{"lang":"fr","files":[{"file":"_index.fr.md","lang":"fr","role":"home","front_matter":{"identity":"Prénom Nom · Pseudo"}}]}\n' \
    > "$work/rendu/checks.json"
  printf 'params:\n  source_url:\n' > "$work/hugo.yaml"
  local nom
  for nom in budget html links; do
    run env CHECK_PUBLIC_ROOT="$work/vide" CHECK_WORK_ROOT="$work/rendu" \
      CHECK_CONFIG_FILE="$work/hugo.yaml" CHECK_SITE_HOST=eleyone.fr \
      bash "$root/scripts/checks/$nom.sh"
    assert_eq 2 "$rc" "$nom : une sortie sans page est une anomalie, pas une conformité"
    assert_contains "aucune page HTML" "$err" "$nom : le message dit ce qui manque"
  done
}

case_shell_grep_jamais_en_tete_de_pipeline() {
  # « shell_grep » promet d'arrêter le script sur une erreur de lecture. En tête d'un pipeline, son
  # « exit » ne quitte que son sous-shell : la promesse y serait fausse. La règle est vérifiée plutôt
  # qu'écrite en note (constat de la première revue de plage, 21/09/2026).
  #
  # Le motif cherche un tube précédé d'autre chose qu'un tube et suivi d'une commande, l'espace
  # étant facultative — « shell_grep x|wc » se cache sinon (constat de la revue de la PR n° 56).
  # Ni « || », ni un « | » d'alternative dans une expression régulière n'en sont.
  local trouves
  shell_grep_into trouves -rnE 'shell_grep[[:space:]].*[^|]\|[[:space:]]*[a-z]' --include='*.sh' "$root/scripts"
  local restants="" ligne code
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    # ce cas parle de la règle ; un commentaire n'est pas un appel. La bibliothèque, elle, vit
    # désormais dans .working-method/ : elle n'est plus sous scripts/, et le même cas la vérifie là-bas
    case $ligne in
      *test-shell-lib.sh:*) continue ;;
    esac
    code=${ligne#*:*:}
    [[ ${code#"${code%%[![:space:]]*}"} != \#* ]] || continue
    restants+="$ligne"$'\n'
  done <<< "$trouves"
  assert_eq "" "${restants%$'\n'}" "aucun « shell_grep … | commande » : dans un pipeline, lire d'abord dans une variable"
}

run_case "$@"
