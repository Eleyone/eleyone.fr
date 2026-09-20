#!/usr/bin/env bash
# README public (story 3.15) : sa trame de cas et ses liens. Un lien relatif qui pointe vers un
# fichier disparu ne se voit pas à la relecture, et jamais tant qu'on ne clique pas ; sur un dépôt
# public, il coûte plus qu'il ne rapporte. Ces cas le rejouent à chaque suite.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readme="$root/README.md"

case_readme_existe() {
  [[ -f $readme ]] || { echo "README absent : $readme" >&2; exit 1; }
}

# Les six rubriques de la trame, dans l'ordre du récit. La story demande la trame narrative d'un cas,
# pas le gabarit d'une page de cas : ni encart « Contexte mission », ni front matter.
trame=(
  'Context'
  'The problem'
  'The easy solution, and why I dropped it'
  'What I decided'
  'What pushed back'
  'Outcome'
)

case_readme_trame_de_cas() {
  local brut titres
  tests_grep_into brut -E '^## ' "$readme"
  [[ -n $brut ]] || { echo "aucun titre de niveau 2 dans le README" >&2; exit 1; }
  titres=$(sed 's/^## //' <<< "$brut")
  local titre
  for titre in "${trame[@]}"; do
    assert_contains "$titre" "$titres" "la trame garde la rubrique « $titre »"
  done
  # L'ordre compte autant que la présence : un cas se lit dans le sens du récit. Les autres titres
  # (références, modèle de branches) sont écartés, puis la suite restante est comparée à la trame.
  # La liste passe par un fichier, jamais par une substitution de processus : l'échec de la commande
  # qui l'écrit y serait invisible (piège connu, docs/procedures/shell-scripts.md).
  local restants
  printf '%s\n' "${trame[@]}" > "$work/trame"
  tests_grep_into restants -xF -f "$work/trame" <<< "$titres"
  assert_eq "$(printf '%s\n' "${trame[@]}")" "$restants" "les six rubriques sont dans l'ordre du récit"
}

case_readme_liens_relatifs_existent() {
  # Tout lien « ](cible) » qui n'est ni externe ni une ancre doit mener à un chemin du dépôt.
  local cibles
  tests_grep_into cibles -oE '\]\([^)]+\)' "$readme"
  [[ -n $cibles ]] || { echo "aucun lien dans le README" >&2; exit 1; }
  local cible chemin morts=""
  while IFS= read -r cible; do
    cible=${cible#](}
    cible=${cible%)}
    case $cible in
      http://*|https://*|mailto:*|'#'*) continue ;;
    esac
    chemin=${cible%%#*}
    [[ -n $chemin ]] || continue
    [[ -e $root/$chemin ]] || morts+="$chemin"$'\n'
  done <<< "$cibles"
  assert_eq "" "${morts%$'\n'}" "aucun lien relatif ne pointe vers un chemin absent"
}

case_readme_liens_attendus() {
  # Les références que la story exige nommément.
  local contenu
  contenu=$(cat "$readme")
  local cible
  for cible in scripts/check.sh scripts/checks/ scripts/ci/checks-job.sh \
    .github/workflows/checks.yaml .gitea/workflows/checks.yaml \
    docs/format-cas.md docs/measures/ AGENTS.md \
    ARCHITECTURE-SPINE.md brief.md prd.md epics.md; do
    assert_contains "$cible" "$contenu" "le README renvoie à $cible"
  done
  for cible in experiment/d2-bilingue design/dossier-architecture design/suisse; do
    assert_contains "/tree/$cible" "$contenu" "le README renvoie à la branche $cible"
  done
  assert_contains "/actions" "$contenu" "le README renvoie aux exécutions publiques"
}

case_readme_modele_de_branches() {
  local contenu
  contenu=$(cat "$readme")
  local motif
  for motif in 'feat/*' 'fix/*' 'chore/*' 'docs/*' 'hotfix/*' 'squash' 'fast-forward'; do
    assert_contains "$motif" "$contenu" "le modèle de branches nomme « $motif »"
  done
  assert_contains "no merge commits" "$contenu" "l'absence de merge commit est dite"
}

case_readme_en_anglais_a_la_premiere_personne() {
  # Deux marqueurs suffisent : la langue et la voix, décidées le 20/09/2026.
  local contenu
  contenu=$(cat "$readme")
  assert_contains "I decided" "$contenu" "la voix est celle d'un cas, à la première personne"
  local accents
  tests_grep_into accents -cE '^[^|]*\b(le|la|les|des|une) ' "$readme"
  ((accents == 0)) || { printf 'le README contient %s ligne(s) qui semblent en français\n' "$accents" >&2; exit 1; }
}

run_case "$@"
