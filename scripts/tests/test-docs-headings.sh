#!/usr/bin/env bash
# Intégrité structurelle des documents du projet (action 1 de la rétrospective de l'epic 4).
#
# Le 21/09/2026, « epics.md » portait quatre copies partielles des epics 0 à 4 : deux insertions
# pures (+1713 puis +3505 lignes, aucune suppression) y avaient préfixé un fichier réécrit au lieu
# de le remplacer. Aucune copie n'était complète, chaque story ayant écrit dans une autre. La
# corruption a vécu six stories sans être vue : « sprint-consistency » lit sprint-status.yaml,
# « check.sh » lit le site rendu, et une revue lit un diff — où +1713 lignes de backlog plausible
# se lisent comme du détail ajouté. Aucun verrou ne lisait le document dans son ensemble.
#
# Un titre de niveau 1 ou 2 répété dans un même document est la trace que laisse ce genre d'accident,
# et le seul signal mécanique qui le révèle sans rien comprendre au contenu. Le cas aurait attrapé
# la duplication dès la story 3.17, à la première copie.
#
# Pourquoi s'arrêter au niveau 2 : à partir du niveau 3, une répétition est légitime et courante —
# un fichier de story porte une rubrique de lentille de revue par revue subie (« Lentille :
# edge-case-hunter » y figure autant de fois qu'il y a eu de revues). Les niveaux 1 et 2 nomment
# des parties de document, qui sont uniques par construction.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Les documents du projet, à l'exclusion des skills installés sous .claude/, .agent/ et .agents/ :
# ceux-là sont réinstallés par BMAD, ne nous appartiennent pas, et quelques-uns répètent un titre
# (ou ouvrent un bloc de script par « # /// », qu'une règle sur les titres lit comme un niveau 1).
documents() {
  git -C "$root" ls-files -- \
    '*.md' \
    ':(exclude).claude/**' ':(exclude).agent/**' ':(exclude).agents/**' ':(exclude)_bmad/**'
}

# Les titres d'un document, blocs de code retirés. Sans ce retrait, un commentaire shell d'un
# exemple (« # Copier ce fichier… ») passerait pour un titre de niveau 1, et deux exemples se
# ressemblant feraient échouer le cas sur un document sain (constat de la revue de la PR n° 64).
titres_de_document() { # $1 = chemin du document ; affiche ses lignes de titre de niveau 1 ou 2
  local hors_bloc titres
  hors_bloc=$(awk '/^[[:space:]]*(```|~~~)/ { dans = !dans; next } !dans' "$1")
  shell_grep_into titres -E '^#{1,2} ' <<< "$hors_bloc"
  printf '%s' "$titres"
}

case_documents_sans_titre_repete() {
  local liste document titres doublons faute=""
  liste=$(documents)
  [[ -n $liste ]] || { echo "aucun document suivi : la liste est vide, le cas ne prouverait rien" >&2; exit 1; }
  while IFS= read -r document; do
    [[ -n $document ]] || continue
    # Le fichier peut être suivi sans être présent (suppression non encore commitée) : l'ignorer
    # plutôt que d'échouer sur un absent, qui n'est pas ce que ce cas surveille.
    [[ -f $root/$document ]] || continue
    titres=$(titres_de_document "$root/$document")
    [[ -n $titres ]] || continue
    doublons=$(sort <<< "$titres" | uniq -d)
    [[ -z $doublons ]] || faute+="$document :"$'\n'"$(sed 's/^/    /' <<< "$doublons")"$'\n'
  done <<< "$liste"
  assert_eq "" "${faute%$'\n'}" "aucun titre de niveau 1 ou 2 n'est répété dans un même document"
}

case_la_regle_attrape_une_duplication() {
  # Sans ce cas, une règle qui ne trouverait jamais rien passerait pour verte. On lui donne
  # exactement l'accident de la story 3.17 : un document préfixé par une copie de lui-même.
  local document=$work/faux-backlog.md
  {
    printf '# Backlog\n\n## Epic 0 : outillage\n\ndu texte\n\n## Epic 1 : garde-fou\n\ndu texte\n'
  } > "$document"
  local titres doublons
  titres=$(titres_de_document "$document")
  doublons=$(sort <<< "$titres" | uniq -d)
  assert_eq "" "$doublons" "un document sain ne déclenche rien"

  cat "$document" "$document" > "$document.duplique"
  titres=$(titres_de_document "$document.duplique")
  doublons=$(sort <<< "$titres" | uniq -d)
  assert_contains "## Epic 0 : outillage" "$doublons" "la copie préfixée est vue"
  assert_contains "# Backlog" "$doublons" "le titre de niveau 1 aussi"
}

case_les_blocs_de_code_ne_sont_pas_des_titres() {
  # Deux exemples shell qui se ressemblent ne sont pas deux titres répétés.
  local document=$work/avec-blocs.md
  printf '# Guide\n\n```bash\n# Copier le fichier\ncp a b\n```\n\n## Suite\n\n```bash\n# Copier le fichier\ncp c d\n```\n' \
    > "$document"
  local titres doublons
  titres=$(titres_de_document "$document")
  doublons=$(sort <<< "$titres" | uniq -d)
  assert_eq "" "$doublons" "un commentaire d'exemple n'est pas un titre"
  assert_contains "# Guide" "$titres" "les vrais titres sont bien lus"
  assert_contains "## Suite" "$titres" "celui de niveau 2 aussi"
}

case_epics_porte_ses_quatorze_epics_une_fois() {
  # La reconstitution du 21/09/2026 a rétabli un exemplaire de chaque epic. Le cas précédent
  # interdit la répétition ; celui-ci vérifie que rien ne s'est perdu au passage.
  local fichier=$root/_bmad-output/planning-artifacts/epics.md titres
  [[ -f $fichier ]] || { echo "backlog introuvable : $fichier" >&2; exit 1; }
  shell_grep_into titres -cE '^## Epic [0-9]+ ' "$fichier"
  assert_eq 14 "$titres" "le backlog porte les 14 epics, une fois chacun"
}

run_case "$@"
