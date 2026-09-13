#!/usr/bin/env bash
# Empêche des fichiers ou contenus privés d'entrer dans l'historique git.
#
#   check-private.sh staged              hook pre-commit : vérifie l'index
#   check-private.sh history [<rev>...]  audit : tout l'historique par défaut
#   check-private.sh pre-receive         hook serveur : lit "old new ref" sur stdin
#
# Les motifs sensibles (une chaîne fixe par ligne, # pour commenter) vivent hors dépôt :
# $PRIVATE_PATTERNS_FILE, sinon docs/private/forbidden-patterns.txt.
# Sans ce fichier, seuls les chemins interdits sont vérifiés.
set -euo pipefail

forbidden_paths='^docs/(private|context)/'
patterns_file="${PRIVATE_PATTERNS_FILE:-$(git rev-parse --show-toplevel 2>/dev/null || true)/docs/private/forbidden-patterns.txt}"
status=0

fail() { printf 'check-private: %b\n' "$*" >&2; status=1; }

patterns=""
if [[ -f $patterns_file ]]; then
  patterns=$(mktemp)
  trap 'rm -f "$patterns"' EXIT
  grep -vE '^[[:space:]]*(#|$)' "$patterns_file" > "$patterns" || true
  [[ -s $patterns ]] || patterns=""
else
  echo "check-private: pas de fichier de motifs ($patterns_file), chemins seulement" >&2
fi

check_tree() { # $1 = libellé, reste = arguments git (commit ou --cached)
  local label=$1; shift
  local paths hits
  if [[ $1 == --cached ]]; then
    paths=$(git ls-files | grep -E "$forbidden_paths" || true)
  else
    paths=$(git ls-tree -r --name-only "$1" | grep -E "$forbidden_paths" || true)
  fi
  [[ -z $paths ]] || fail "chemin privé dans $label :\n$paths"
  if [[ -n $patterns ]]; then
    hits=$(git grep -I -n -i -F -f "$patterns" "$@" -- . || true)
    [[ -z $hits ]] || fail "contenu privé dans $label :\n$hits"
  fi
}

case "${1:-}" in
  staged)
    check_tree "l'index" --cached
    ;;
  history)
    shift
    if (($#)); then revs=$(git rev-list "$@"); else revs=$(git rev-list --all); fi
    for c in $revs; do check_tree "${c:0:7}" "$c"; done
    ;;
  pre-receive)
    zero=0000000000000000000000000000000000000000
    while read -r _old new _ref; do
      [[ $new == "$zero" ]] && continue
      for c in $(git rev-list "$new" --not --all); do check_tree "${c:0:7}" "$c"; done
    done
    ;;
  *)
    echo "usage : $0 staged | history [<rev>...] | pre-receive" >&2
    exit 2
    ;;
esac

((status == 0)) || echo "check-private: refusé. Retire le contenu privé avant de continuer." >&2
exit "$status"
