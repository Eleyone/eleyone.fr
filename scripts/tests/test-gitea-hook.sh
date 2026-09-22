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
  # « dirname $0 »/lib/image.sh, et ce chemin doit valoir des deux côtés. Depuis la story 7.3,
  # lib/pdf.sh l'accompagne : le garde-fou lit aussi le texte et les métadonnées des CV PDF.
  mkdir -p "$work/custom/eleyone-check-private/lib"
  cp "$root/scripts/lib/image.sh" "$work/custom/eleyone-check-private/lib/image.sh"
  cp "$root/scripts/lib/pdf.sh" "$work/custom/eleyone-check-private/lib/pdf.sh"
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

# Un PDF minimal, fabriqué octet par octet : aucun PDF n'entre dans le dépôt, et le motif éventuel
# va dans les **métadonnées**, là où il se cache dans un vrai export.
ecrire_pdf() { # $1 = chemin, $2 = motif à poser en auteur, ou rien
  local chemin=$1 auteur=${2:-} flux="BT /F1 12 Tf 20 150 Td (CV) Tj ET" info="" objets=""
  mkdir -p "$(dirname "$chemin")"
  objets+="1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj"$'\n'
  objets+="2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj"$'\n'
  objets+="3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 300 300]/Contents 4 0 R>>endobj"$'\n'
  objets+="4 0 obj<</Length ${#flux}>>stream"$'\n'"$flux"$'\n'"endstream endobj"$'\n'
  if [[ -n $auteur ]]; then
    objets+="98 0 obj<</Author ($auteur)>>endobj"$'\n'
    info="/Info 98 0 R"
  fi
  printf '%%PDF-1.4\n%s\ntrailer<</Root 1 0 R%s/Size 100>>\n%%%%EOF\n' "$objets" "$info" > "$chemin"
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

case_bibliotheque_de_pdf_absente() {
  # Sans elle, le texte et les métadonnées d'un CV ne seraient lus par personne : le hook refuse
  # plutôt que de laisser passer (story 7.3, même règle que pour les images).
  install_hook
  rm "$work/custom/eleyone-check-private/lib/pdf.sh"
  commit_file publique/a.txt "page publique"
  refused "bibliothèque de PDF absente" "bibliothèque de lecture des PDF absente ou illisible"
}

case_cv_pdf_avec_un_motif_refuse() {
  # Le cœur de la story 7.3 : un CV dont le **motif est dans les métadonnées** est refusé côté
  # serveur. C'est là qu'un téléphone se cache dans un export, et c'est la moitié de FR-38 qu'un
  # contrôle du seul texte manquerait.
  install_hook
  mkdir -p "$work/depot/assets/cv"
  ecrire_pdf "$work/depot/assets/cv/cv-fr.pdf" motif-interdit-essai
  ecrire_pdf "$work/depot/assets/cv/cv-en.pdf"
  commit_all "ajout des CV" > /dev/null
  refused "CV avec un motif dans les métadonnées" "C21 : contenu privé dans métadonnées d'un PDF"
  assert_contains "assets/cv/cv-fr.pdf" "$err" "le fichier fautif est nommé"
  # Le PDF fabriqué ici est du texte, donc « git grep -I » le voit aussi : ses deux signalements
  # se superposent. Sur un vrai PDF compressé, git l'ignorerait et seule la lecture par poppler
  # le trouverait — c'est précisément le trou que cette story ferme.
  [[ $err != *"motif-interdit-essai"* ]] || { echo "le motif apparaît dans les messages" >&2; exit 1; }
}

case_cv_pdf_propre_admis() {
  # La contre-épreuve : sans quoi un hook qui refuse tout passerait pour un hook qui marche.
  install_hook
  mkdir -p "$work/depot/assets/cv"
  ecrire_pdf "$work/depot/assets/cv/cv-fr.pdf"
  ecrire_pdf "$work/depot/assets/cv/cv-en.pdf"
  commit_all "ajout des CV" > /dev/null
  push_branch
  assert_eq 0 "$rc" "deux CV propres sont admis (messages : $err)"
}

case_pdf_inattendu_sous_assets_cv_refuse() {
  # L'interdiction n'est levée que pour les deux noms d'AD-21. Tout autre PDF à cet endroit reste
  # un chemin interdit : ce que le hook ne sait pas nommer, il le refuse.
  install_hook
  mkdir -p "$work/depot/assets/cv"
  ecrire_pdf "$work/depot/assets/cv/cv-ancien.pdf"
  commit_all "ajout d un PDF inattendu" > /dev/null
  refused "PDF inattendu" "assets/cv/cv-ancien.pdf"
}

case_plusieurs_commits_avec_des_cv_ne_laissent_rien() {
  # Le mode pre-receive contrôle **un commit à la fois** : un « mktemp » par appel écrasait la
  # variable, et le nettoyage n'emportait que le dernier — un push de dix commits laissait neuf CV
  # extraits sur la forge (revue du code de la PR n° 86). Un seul cas à un commit ne pouvait pas
  # le voir : c'est la pluralité qui le révèle.
  install_hook
  local avant apres i
  avant=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -type f -name 'tmp.*' 2>/dev/null | wc -l)
  mkdir -p "$work/depot/assets/cv"
  ecrire_pdf "$work/depot/assets/cv/cv-fr.pdf"
  ecrire_pdf "$work/depot/assets/cv/cv-en.pdf"
  commit_all "ajout des CV" > /dev/null
  # Trois commits de plus, chacun retouchant un CV : trois passages dans la lecture des PDF.
  for i in 1 2 3; do
    mkdir -p "$work/depot/publique"
    ecrire_pdf "$work/depot/assets/cv/cv-fr.pdf"
    printf '%s\n' "$i" > "$work/depot/publique/tour.txt"
    commit_all "tour $i" > /dev/null
  done
  push_branch
  assert_eq 0 "$rc" "quatre commits avec des CV propres sont admis (messages : $err)"
  apres=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -type f -name 'tmp.*' 2>/dev/null | wc -l)
  ((apres <= avant)) || {
    printf 'le garde-fou laisse %s fichier(s) temporaire(s) après un push de plusieurs commits.\n' \
      "$((apres - avant))" >&2
    exit 1
  }
}

run_case "$@"
