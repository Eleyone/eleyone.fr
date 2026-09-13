#!/usr/bin/env bash
# Régénère tous les SVG : chaque schéma, chaque langue, moteurs ELK et dagre.
#
#   ./render.sh [dossier_de_sortie]     (défaut : svg/ à côté de ce script)
#
# Un schéma = un dossier contenant structure.d2 et un point d'entrée par langue
# (fr.d2, en.d2) qui définit les variables puis importe la structure.
# Binaire D2 : $D2 si défini, sinon d2 dans le PATH.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/svg}
d2=${D2:-d2}
# Le thème vient de theme.d2 (importé par chaque structure.d2). Pas de --theme :
# ce flag écraserait theme-id (voir README).
unset D2_THEME D2_LAYOUT D2_PAD D2_SKETCH
layouts=(elk dagre)
langs=(fr en)

mkdir -p "$out"
out=$(cd "$out" && pwd)

for dir in "$here"/*/; do
  [[ -f $dir/structure.d2 ]] || continue
  schema=$(basename "$dir")
  for lang in "${langs[@]}"; do
    for layout in "${layouts[@]}"; do
      target="$out/$schema.$lang.$layout.svg"
      # cd : les imports sont résolus relativement au fichier d'entrée
      (cd "$dir" && "$d2" --omit-version --no-xml-tag --pad 24 \
        --layout "$layout" "$lang.d2" "$target" 2>/dev/null) \
        || { echo "échec : $schema ($lang, $layout)" >&2; exit 1; }
      echo "$target"
    done
  done
done
