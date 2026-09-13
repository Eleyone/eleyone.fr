#!/usr/bin/env bash
# Vérifie que le rendu est déterministe :
#   1. deux rendus successifs dans des dossiers temporaires distincts sont identiques à l'octet ;
#   2. ils sont identiques aux SVG commités dans svg/ (équivalent local du git diff --exit-code de la CI).
# Code retour 0 si tout est identique, 1 sinon.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

"$here/render.sh" "$tmp/run1" >/dev/null
"$here/render.sh" "$tmp/run2" >/dev/null

status=0
for f in "$tmp"/run1/*.svg; do
  name=$(basename "$f")
  if ! cmp -s "$f" "$tmp/run2/$name"; then
    echo "ÉCART entre deux rendus : $name"
    cmp "$f" "$tmp/run2/$name" | head -1
    status=1
  elif [[ ! -f $here/svg/$name ]]; then
    echo "ABSENT de svg/ : $name (lancer ./render.sh)"
    status=1
  elif ! cmp -s "$f" "$here/svg/$name"; then
    echo "ÉCART avec svg/ : $name (lancer ./render.sh et commiter)"
    status=1
  else
    echo "identique : $name  $(sha256sum < "$f" | cut -c1-16)"
  fi
done

for f in "$here"/svg/*.svg; do
  [[ -f $tmp/run1/$(basename "$f") ]] || { echo "OBSOLÈTE dans svg/ : $(basename "$f")"; status=1; }
done

if ((status == 0)); then echo "OK : rendu déterministe"; else echo "KO : écarts détectés" >&2; fi
exit "$status"
