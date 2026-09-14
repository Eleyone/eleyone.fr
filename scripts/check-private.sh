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
# Une alerte n'affiche jamais le contenu trouvé ni le motif : seulement l'emplacement
# (commit, fichier, ligne) et le numéro de ligne du motif dans le fichier de motifs.
set -euo pipefail

# assets/cv/*.pdf reste interdit tant que le pre-receive Gitea ne sait pas lire les PDF (AD-21)
forbidden_paths='^docs/(private|context)/|(^|/)\.env$|^assets/cv/.*\.pdf$'
patterns_file="${PRIVATE_PATTERNS_FILE:-$(git rev-parse --show-toplevel 2>/dev/null || true)/docs/private/forbidden-patterns.txt}"
status=0
sep=$'\001' # séparateur des champs de git grep -z : absent des noms de fichier, contrairement à la tabulation

fail() { printf 'check-private: %b\n' "$*" >&2; status=1; }

patterns=""
if [[ -f $patterns_file ]]; then
  patterns=$(mktemp)
  patterns_text=$(mktemp)
  trap 'rm -f "$patterns" "$patterns_text"' EXIT
  # "numéro de ligne:motif", pour citer un motif par son numéro sans l'afficher
  grep -nvE '^[[:space:]]*(#|$)' "$patterns_file" > "$patterns" || true
  # les motifs seuls, pour un premier passage avec tous les motifs à la fois
  grep -vE '^[[:space:]]*(#|$)' "$patterns_file" > "$patterns_text" || true
  [[ -s $patterns ]] || patterns=""
else
  echo "check-private: pas de fichier de motifs ($patterns_file), chemins seulement" >&2
fi

check_tree() { # $1 = libellé, reste = arguments git (commit ou --cached)
  local label=$1; shift
  local listing paths entry hits="" err rc=0
  if [[ $1 == --cached ]]; then
    listing=$(git ls-files) || { fail "lecture impossible de $label"; return 0; }
  else
    listing=$(git ls-tree -r --name-only "$1") || { fail "lecture impossible de $label"; return 0; }
  fi
  paths=$(printf '%s\n' "$listing" | grep -E "$forbidden_paths" || true)
  [[ -z $paths ]] || fail "chemin privé dans $label :\n$paths"
  [[ -n $patterns ]] || return 0
  # un seul passage avec tous les motifs ; le détail motif par motif seulement s'il trouve.
  # Un objet illisible donne une erreur mais le code 1 (« rien trouvé ») : toute erreur fait échouer.
  err=$(git grep -q -I -i -F -f "$patterns_text" "$@" -- . 2>&1 >/dev/null) || rc=$?
  if ((rc > 1)) || [[ -n $err ]]; then
    fail "recherche impossible dans $label (code $rc)"
    return 0
  fi
  ((rc == 0)) || return 0
  while IFS= read -r entry; do
    # -z sépare fichier, ligne et contenu par NUL : cut garde fichier et ligne, jamais le contenu
    hits+=$(git grep -z -I -n -i -F -e "${entry#*:}" "$@" -- . \
      | tr '\0' '\001' | cut -d "$sep" -f1-2 | tr '\001' ':' \
      | sed "s/\$/ (motif ligne ${entry%%:*})/" || true)$'\n'
  done < "$patterns"
  hits=$(printf '%s' "$hits" | grep -v '^$' | sort -u || true)
  fail "contenu privé dans $label (contenu masqué) :\n$hits"
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
