#!/usr/bin/env bash
# Hook pre-receive de Gitea (scripts/gitea/pre-receive-check-private), story 1.2 : dépôt nu jetable dont le
# hook pre-receive imite celui que Gitea génère, et dossier $GITEA_CUSTOM jetable. Motif factice seulement.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# $1 « sans-variable » pour lancer le hook sans GITEA_CUSTOM
install_hook() {
  local custom_line
  mkdir -p "$work/custom/eleyone-check-private"
  cp "$root/scripts/check-private.sh" "$work/custom/eleyone-check-private/check-private.sh"
  # La bibliothèque de lecture d'images est copiée sous le même chemin relatif que dans le dépôt,
  # comme la procédure du hook le prescrit depuis la story 5.4 : check-private.sh la charge par
  # « dirname $0 »/lib/image.sh, et ce chemin doit valoir des deux côtés.
  mkdir -p "$work/custom/eleyone-check-private/lib"
  cp "$root/scripts/lib/image.sh" "$work/custom/eleyone-check-private/lib/image.sh"
  printf '# motifs d essai\nmotif-interdit-essai\n' > "$work/custom/eleyone-check-private/forbidden-patterns.txt"
  git init -q --bare "$work/nu.git"
  git -C "$work/nu.git" config core.hooksPath "$work/nu.git/hooks"
  mkdir -p "$work/nu.git/hooks/pre-receive.d"
  cp "$root/scripts/gitea/pre-receive-check-private" "$work/nu.git/hooks/pre-receive.d/check-private"
  chmod 0755 "$work/nu.git/hooks/pre-receive.d/check-private"
  custom_line="export GITEA_CUSTOM='$work/custom'"
  [[ ${1:-} != sans-variable ]] || custom_line="unset GITEA_CUSTOM"
  # comme le hook pre-receive généré par Gitea : chaque script exécutable de pre-receive.d reçoit l'entrée standard
  cat > "$work/nu.git/hooks/pre-receive" <<EOF
#!/bin/sh
$custom_line
data=\$(cat)
for hook in '$work/nu.git/hooks/pre-receive.d'/*; do
  [ -x "\$hook" ] || continue
  printf '%s\n' "\$data" | "\$hook" || exit 1
done
EOF
  chmod +x "$work/nu.git/hooks/pre-receive"
  new_repo
  git -C "$work/depot" remote add origin "$work/nu.git"
}

commit_file() { # $1 chemin, $2 contenu
  mkdir -p "$(dirname "$work/depot/$1")"
  printf '%s\n' "$2" > "$work/depot/$1"
  commit_all "ajout de $1" > /dev/null
}

push_branch() { run git -C "$work/depot" push origin HEAD:refs/heads/essai; }

refused() { # $1 libellé, $2 texte attendu dans les messages retransmis
  push_branch
  [[ $rc != 0 ]] || { echo "$1 : push admis" >&2; exit 1; }
  if git -C "$work/nu.git" rev-parse --verify --quiet refs/heads/essai > /dev/null; then
    echo "$1 : la branche existe sur le dépôt nu" >&2
    exit 1
  fi
  assert_contains "$2" "$err" "$1 : cause retransmise à l'auteur du push"
}

case_push_propre_admis() {
  install_hook
  commit_file publique/a.txt "page publique"
  push_branch
  assert_eq 0 "$rc" "push propre admis (messages : $err)"
}

case_chemin_interdit_refuse() {
  install_hook
  commit_file docs/private/notes.txt "contenu"
  refused "fichier sous docs/private" "docs/private/notes.txt"
}

case_motif_factice_refuse() {
  install_hook
  commit_file publique/notes.md "texte avec motif-interdit-essai"
  refused "motif factice" "publique/notes.md:1 (motif ligne 2)"
  [[ $err != *motif-interdit-essai* ]] || { echo "le motif apparaît dans les messages" >&2; exit 1; }
}

case_sans_gitea_custom() {
  install_hook sans-variable
  commit_file publique/a.txt "page publique"
  refused "GITEA_CUSTOM absente" "GITEA_CUSTOM non définie"
}

case_script_du_garde_fou_absent() {
  install_hook
  rm "$work/custom/eleyone-check-private/check-private.sh"
  commit_file publique/a.txt "page publique"
  refused "script absent" "script du garde-fou absent ou illisible"
}

case_bibliotheque_dimages_absente() {
  # Sans elle, C20 ne s'exécute pas : le hook refuse le push plutôt que de laisser passer une
  # image porteuse de métadonnées. Un garde-fou qui s'ignore en silence ne garde rien.
  install_hook
  rm "$work/custom/eleyone-check-private/lib/image.sh"
  commit_file publique/a.txt "page publique"
  refused "bibliothèque absente" "bibliothèque de lecture d'images absente ou illisible"
}

case_liste_absente() {
  install_hook
  rm "$work/custom/eleyone-check-private/forbidden-patterns.txt"
  commit_file publique/a.txt "page publique"
  refused "liste absente" "liste des motifs absente ou illisible"
}

case_liste_sans_motif() {
  install_hook
  printf '# commentaire\n\n' > "$work/custom/eleyone-check-private/forbidden-patterns.txt"
  commit_file publique/a.txt "page publique"
  refused "liste sans motif" "aucun motif dans la liste des motifs"
}

case_liste_illisible() {
  skip_if_root "la liste des motifs"
  install_hook
  chmod 000 "$work/custom/eleyone-check-private/forbidden-patterns.txt"
  commit_file publique/a.txt "page publique"
  refused "liste illisible" "liste des motifs absente ou illisible"
}

run_case "$@"
