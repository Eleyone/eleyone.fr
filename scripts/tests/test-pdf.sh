#!/usr/bin/env bash
# C21 (story 7.1) : les CV PDF, ensemble ou rien, et rien de privé dedans.
#
# Les PDF d'essai sont **fabriqués octet par octet** dans le cas de test, comme les images de
# test-images.sh : aucun PDF n'entre dans le dépôt, aucun générateur n'est ajouté, et chaque cas
# écrit exactement le défaut qu'il veut prouver. Un PDF minimal est du texte ; poppler reconstruit
# la table des références croisées, donc il n'y a rien à calculer.
#
# Hors ligne. Dépend de poppler-utils, prérequis du poste et présent dans CHECK_IMAGE.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# La bibliothèque est chargée pour être éprouvée **en direct**, comme test-images.sh le fait de
# lib/image.sh : depuis qu'elle porte la confrontation aux motifs, son chemin « code 2 » n'est
# atteignable par aucun test d'intégration (constat A2, rétrospective de l'epic 7).
. "$root/scripts/lib/pdf.sh"

readonly motif=MOTIFFACTICE

# Le PDF d'essai est fabriqué par « tests_pdf » de scripts/tests/lib.sh : une seule écriture
# pour les trois fichiers de test qui en avaient chacun la sienne (constat A3).
liste() { # écrit une liste de motifs et rend son chemin
  printf '# commentaire\n%s\n' "$motif" > "$work/motifs.txt"
  printf '%s' "$work/motifs.txt"
}

# Le contrôle se replie sur « docs/private/forbidden-patterns.txt » du dépôt quand la variable
# n'est pas posée : les cas passent donc toujours une valeur, et « aucune liste » vaut un chemin
# inexistant, comme sur GitHub — jamais une valeur vide, qui ferait chercher la vraie liste.
controle() { # $1 = chemin de la liste des motifs, vide pour aucune
  run env CHECK_CV_DIR="$work/cv" PRIVATE_PATTERNS_FILE="${1:-$work/liste-absente.txt}" \
    bash "$root/scripts/checks/pdf.sh"
}

vide() { rm -rf "$work/cv"; mkdir -p "$work/cv"; }

# Un TMPDIR **qui n'appartient qu'au cas** : « ${TMPDIR:-/tmp} » est partagé avec le reste de la
# machine, et un cas qui compte là-dedans suppose son environnement (piège connu de
# docs/procedures/shell-scripts.md). Ici, tout ce qui s'y trouve vient du script qu'on éprouve.
#
# La fonction rend le chemin et ne lance rien : une première écriture lançait la commande et
# rendait le seul compte, en avalant le code de sortie par un « || true ». Un script mort avant
# d'avoir créé son premier temporaire laissait alors 0 fichier, et le cas passait au vert sur un
# script qui n'avait rien fait (constat bloquant de la deuxième revue de la PR n° 92). Le cas
# lance donc lui-même, par « run », et affirme le code **avant** de compter.
tmpdir_a_soi() {
  local tmp=$work/tmp-a-soi
  rm -rf "$tmp"; mkdir -p "$tmp"
  printf '%s' "$tmp"
}

restes_dans() { find "$1" -mindepth 1 | wc -l; }

case_pdf_aucune_page() {
  # Branche sans test jusqu'ici (constat A10, rétrospective de l'epic 7). En l'écrivant, on
  # constate que **la branche « aucune page » de C21 est inatteignable avec poppler** : pdfinfo
  # refuse un arbre de pages vide avant de compter quoi que ce soit (« Invalid page count 0 »,
  # code 99), si bien que « pdf_pages » échoue et que le contrôle prend la branche « ne sait pas
  # lire ». Le test porte donc sur **l'invariant qu'AD-21 veut** — un CV sans page ne passe pas —
  # et non sur la formulation du message, qui dépend de ce que l'outil accepte de lire.
  vide
  tests_pdf "$work/cv/cv-en.pdf"
  printf '%%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[]/Count 0>>endobj\ntrailer<</Root 1 0 R/Size 10>>\n%%%%EOF\n' \
    > "$work/cv/cv-fr.pdf"
  controle "$(liste)"
  assert_eq 1 "$rc" "un PDF sans page ne passe pas"
  assert_contains "cv-fr.pdf" "$err" "le fichier fautif est nommé"
}

case_pdf_illisible_est_un_ecart_pas_une_anomalie() {
  # L'autre branche sans test. Le fichier commence bien par « %PDF- » — donc il passe l'en-tête —
  # mais sa structure est inexploitable. L'en-tête de checks/pdf.sh l'annonce : « le fichier est
  # là, il est simplement mauvais », donc **code 1** et non 2.
  vide
  tests_pdf "$work/cv/cv-en.pdf"
  printf '%%PDF-1.4\nces octets ne sont pas un PDF\n' > "$work/cv/cv-fr.pdf"
  controle "$(liste)"
  assert_eq 1 "$rc" "un PDF illisible est un écart, pas une anomalie (code 2)"
  assert_contains "ne sait pas lire ce fichier" "$err" "le signalement nomme l outil qui a renoncé"
}

case_pdf_une_liste_sans_motif_ne_laisse_rien() {
  # Le chemin qui fuyait : la liste existe, mais ne porte que des commentaires. Le contrôle créait
  # alors deux fichiers temporaires, puis **vidait les variables qui les désignaient** pour dire
  # « aucun motif » — et le nettoyage, qui lisait ces mêmes variables, ne supprimait plus rien
  # (constat B1, rétrospective de l'epic 7).
  #
  # Deux cas existants tenaient chacun une moitié de ce qu'il fallait : l'un exerçait la liste sans
  # motif sans regarder le disque, l'autre regardait le disque sur le chemin nominal. Aucun
  # croisement, et la fuite a vécu deux stories. Ce cas est le croisement.
  vide
  tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"
  printf '# que des commentaires\n\n#\n' > "$work/motifs-sans-motif.txt"
  local tmp; tmp=$(tmpdir_a_soi)
  run env TMPDIR="$tmp" CHECK_CV_DIR="$work/cv" \
    PRIVATE_PATTERNS_FILE="$work/motifs-sans-motif.txt" bash "$root/scripts/checks/pdf.sh"
  assert_eq 0 "$rc" "le contrôle va jusqu'au bout, sans quoi zéro reste ne prouverait rien (messages : $err)"
  assert_eq 0 "$(restes_dans "$tmp")" "C21 ne laisse aucun fichier temporaire quand la liste ne porte aucun motif"
}

case_pdf_une_liste_normale_ne_laisse_rien() {
  # La contre-épreuve : sans elle, un contrôle qui ne créerait jamais de temporaire passerait pour
  # un contrôle qui nettoie bien.
  vide
  tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"
  local tmp; tmp=$(tmpdir_a_soi)
  run env TMPDIR="$tmp" CHECK_CV_DIR="$work/cv" \
    PRIVATE_PATTERNS_FILE="$(liste)" bash "$root/scripts/checks/pdf.sh"
  assert_eq 0 "$rc" "le contrôle va jusqu'au bout (messages : $err)"
  assert_eq 0 "$(restes_dans "$tmp")" "C21 ne laisse aucun fichier temporaire avec une liste normale"
}

case_pdf_un_code_inattendu_nest_pas_un_fichier_propre() {
  # **Le contrôle ne doit jamais s'ouvrir en cas de panne.** Une première écriture testait
  # « code != 2 » puis « code == 1 » : un code inattendu — sous-shell tué, commande introuvable,
  # arrêt sur « set -e » — retombait sur « rien trouvé » et déclarait le CV propre (revue de la
  # PR n° 95). Aucun test d'intégration ne peut produire un tel code ; celui-ci le fabrique, en
  # dégradant la bibliothèque dans un arbre jetable.
  local arbre=$work/arbre
  rm -rf "$arbre"; mkdir -p "$arbre/scripts/checks" "$arbre/scripts/lib" "$arbre/cv"
  cp "$root/scripts/checks/pdf.sh" "$root/scripts/checks/lib.sh" "$arbre/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$arbre/scripts/lib/"
  # La bibliothèque copiée rend 7 : ni « rien », ni « trouvé », ni « recherche impossible ».
  printf '\npdf_confront() { return 7; }\n' >> "$arbre/scripts/lib/pdf.sh"
  tests_pdf "$arbre/cv/cv-fr.pdf" "Parcours"
  tests_pdf "$arbre/cv/cv-en.pdf" "Experience"
  run env CHECK_CV_DIR="$arbre/cv" PRIVATE_PATTERNS_FILE="$(liste)" bash "$arbre/scripts/checks/pdf.sh"
  assert_eq 1 "$rc" "un code inattendu fait échouer le contrôle, il ne le laisse pas passer"
  assert_contains "recherche des motifs impossible" "$err" "et le message dit que la recherche a échoué"
  assert_contains "code 7" "$err" "en donnant le code, pour qu on puisse le chercher"
}

# --- pdf_confront, éprouvée en direct -------------------------------------------------------------

motifs_confront() { # écrit les deux fichiers de motifs, affiche « numérotés nus »
  printf '1:%s\n3:AUTREMOTIF\n' "$motif" > "$work/numerotes.txt"
  printf '%s\nAUTREMOTIF\n' "$motif" > "$work/nus.txt"
}

case_pdf_confront_rend_les_numeros_de_ligne() {
  motifs_confront
  local lignes code=0
  lignes=$(pdf_confront "$work/numerotes.txt" "$work/nus.txt" "un texte avec $motif dedans") || code=$?
  assert_eq 1 "$code" "un motif trouvé rend 1"
  assert_eq "1" "${lignes# }" "le numéro de ligne du motif, et lui seul"
}

case_pdf_confront_plusieurs_motifs() {
  motifs_confront
  local lignes code=0
  lignes=$(pdf_confront "$work/numerotes.txt" "$work/nus.txt" "$motif puis AUTREMOTIF") || code=$?
  assert_eq 1 "$code" "deux motifs trouvés rendent 1"
  assert_eq "1 3" "${lignes# }" "les deux numéros, dans l ordre de la liste"
}

case_pdf_confront_rien_a_trouver() {
  motifs_confront
  local lignes code=0
  lignes=$(pdf_confront "$work/numerotes.txt" "$work/nus.txt" "un texte parfaitement anodin") || code=$?
  assert_eq 0 "$code" "aucun motif rend 0"
  assert_eq "" "$lignes" "et rien n est affiché"
}

case_pdf_confront_naffiche_jamais_le_motif() {
  # La garantie qui compte : la fonction rend des numéros, jamais le motif ni l'extrait.
  motifs_confront
  local lignes code=0
  lignes=$(pdf_confront "$work/numerotes.txt" "$work/nus.txt" "un texte avec $motif dedans" 2>&1) || code=$?
  assert_eq 1 "$code" "le motif est trouvé"
  [[ $lignes != *"$motif"* ]] || { echo "le motif apparaît dans la sortie" >&2; exit 1; }
  [[ $lignes != *"un texte"* ]] || { echo "l extrait apparaît dans la sortie" >&2; exit 1; }
}

case_pdf_confront_recherche_impossible_rend_2() {
  # Le chemin qu'aucun test d'intégration n'atteint : grep rend 2 sur une liste illisible. Le
  # confondre avec « pas trouvé » laisserait passer un motif sans un mot — c'est la classe d'erreur
  # que les six tours de la story 7.1 ont poursuivie.
  skip_if_root "la liste des motifs"
  motifs_confront
  chmod 000 "$work/nus.txt"
  local code=0
  pdf_confront "$work/numerotes.txt" "$work/nus.txt" "un texte avec $motif dedans" > /dev/null 2>&1 || code=$?
  chmod 644 "$work/nus.txt"
  assert_eq 2 "$code" "une recherche impossible rend 2, et n affirme rien"
}

case_pdf_confront_sans_liste_ne_dit_rien() {
  local code=0
  pdf_confront "" "" "un texte avec $motif dedans" > /dev/null || code=$?
  assert_eq 0 "$code" "sans liste, la fonction ne conclut rien"
}

case_pdf_aucun_fichier() {
  vide
  controle "$(liste)"
  assert_eq 0 "$rc" "aucun CV ne fait pas échouer (messages : $err)"
  assert_contains "aucun CV PDF" "$out" "le contrôle le dit"
}

case_pdf_les_deux() {
  vide; tests_pdf "$work/cv/cv-fr.pdf" "Parcours"; tests_pdf "$work/cv/cv-en.pdf" "Experience"
  controle "$(liste)"
  assert_eq 0 "$rc" "les deux CV passent (messages : $err)"
  assert_contains "aucun motif privé" "$out" "le contrôle dit qu'il a confronté le contenu"
}

case_pdf_un_seul() {
  # « Ensemble ou rien » (AD-21) : la règle vaut pour le contrôle, pas seulement pour les liens.
  vide; tests_pdf "$work/cv/cv-fr.pdf"
  controle "$(liste)"
  assert_eq 1 "$rc" "un seul CV fait échouer"
  assert_contains "ensemble ou rien" "$err" "le signalement nomme la règle"
  assert_contains "cv-en.pdf manquant" "$err" "le signalement nomme le fichier absent"
}

case_pdf_sans_entete() {
  vide; tests_pdf "$work/cv/cv-en.pdf"
  printf 'ceci nest pas un pdf\n' > "$work/cv/cv-fr.pdf"
  controle "$(liste)"
  assert_eq 1 "$rc" "un fichier sans en-tête PDF fait échouer"
  assert_contains "ce n'est pas un PDF" "$err" "le signalement le dit"
}

case_pdf_trop_lourd() {
  vide; tests_pdf "$work/cv/cv-en.pdf"
  # 500 Ko est le seuil : on le dépasse par du bourrage dans un commentaire, le PDF restant lisible.
  tests_pdf "$work/cv/cv-fr.pdf"
  { printf '%%'; head -c 500001 /dev/zero | tr '\0' 'A'; printf '\n'; } >> "$work/cv/cv-fr.pdf"
  controle "$(liste)"
  assert_eq 1 "$rc" "un PDF au-delà de 500 Ko fait échouer"
  assert_contains "500000 au plus" "$err" "le signalement donne le seuil"
}

case_pdf_motif_dans_le_texte() {
  vide; tests_pdf "$work/cv/cv-en.pdf"; tests_pdf "$work/cv/cv-fr.pdf" "$motif ici"
  controle "$(liste)"
  assert_eq 1 "$rc" "un motif dans le texte fait échouer"
  assert_contains "contenu privé dans le texte" "$err" "le signalement nomme la source"
  assert_contains "motif ligne 2" "$err" "le motif est cité par son numéro de ligne"
}

case_pdf_motif_dans_les_metadonnees() {
  # Un téléphone ou une ville vit souvent là, et personne ne regarde les métadonnées d'un export.
  vide; tests_pdf "$work/cv/cv-en.pdf"; tests_pdf "$work/cv/cv-fr.pdf" "Rien" "$motif"
  controle "$(liste)"
  assert_eq 1 "$rc" "un motif dans les métadonnées fait échouer"
  assert_contains "contenu privé dans les métadonnées" "$err" "le signalement nomme la source"
}

case_pdf_motif_dans_le_xmp() {
  vide; tests_pdf "$work/cv/cv-en.pdf"; tests_pdf "$work/cv/cv-fr.pdf" "Rien" "" "$motif"
  controle "$(liste)"
  assert_eq 1 "$rc" "un motif dans le XMP fait échouer"
  assert_contains "contenu privé dans le XMP" "$err" "le signalement nomme la source"
}

case_pdf_le_motif_nest_jamais_affiche() {
  # La règle qui compte : une alerte dit où, jamais quoi.
  vide; tests_pdf "$work/cv/cv-en.pdf"; tests_pdf "$work/cv/cv-fr.pdf" "$motif ici" "$motif" "$motif"
  controle "$(liste)"
  assert_eq 1 "$rc" "le PDF est refusé"
  [[ $err != *"$motif"* && $out != *"$motif"* ]] \
    || { echo "le motif apparaît dans la sortie du contrôle" >&2; exit 1; }
}

case_pdf_sans_liste_de_motifs() {
  # Sur GitHub, la liste n'existe pas : le contrôle se limite à la forme et le dit, plutôt que de
  # laisser croire que le contenu a été confronté.
  vide; tests_pdf "$work/cv/cv-en.pdf"; tests_pdf "$work/cv/cv-fr.pdf" "$motif ici"
  controle ""
  assert_eq 0 "$rc" "sans liste, un motif dans le texte ne fait pas échouer (messages : $err)"
  assert_contains "liste des motifs absente" "$out" "le contrôle dit ce qu'il n'a pas vérifié"
}

case_pdf_outil_absent_est_une_anomalie() {
  # Un PDF non lu ne doit pas passer pour un PDF propre : code 2, jamais 0.
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"
  # Un PATH qui porte tout **sauf** poppler : les outils sont liés depuis leur emplacement réel,
  # jamais depuis un chemin supposé — « bash » n'est pas au même endroit partout.
  rm -rf "$work/bin-nu"; mkdir -p "$work/bin-nu"
  local outil cible
  for outil in bash sh head wc sed grep tr cut sort find mktemp rm cat dirname basename; do
    cible=$(command -v "$outil" 2>/dev/null) || continue
    ln -sf "$cible" "$work/bin-nu/$outil"
  done
  run env PATH="$work/bin-nu" CHECK_CV_DIR="$work/cv" bash "$root/scripts/checks/pdf.sh"
  assert_eq 2 "$rc" "l'absence de poppler-utils est une anomalie, pas un succès"
  assert_contains "poppler-utils" "$err" "le message nomme le paquet à installer"
}
case_pdf_le_pre_commit_lance_c21_avant_le_garde_fou() {
  # Le critère demande une **démonstration**, pas une relecture : un « cat » sur le hook laisserait
  # passer une erreur de syntaxe ou un plantage à l'exécution (constat de la revue du code de la
  # PR n° 84). Le cas monte donc un dépôt jetable, y pose le vrai hook, et tente un vrai commit.
  #
  # L'interdiction de chemin d'AD-21 est retirée dans cette copie seule : sans cela le garde-fou
  # refuserait le PDF avant que C21 ait parlé, et c'est précisément l'ordre que ce cas vérifie.
  local depot=$work/depot
  rm -rf "$depot"; mkdir -p "$depot/scripts/checks" "$depot/scripts/lib" "$depot/.githooks" "$depot/assets/cv"
  git -C "$depot" init -q .
  git -C "$depot" config user.email essai@exemple.invalide
  git -C "$depot" config user.name Essai
  cp "$root/scripts/checks/pdf.sh" "$root/scripts/checks/lib.sh" "$depot/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$depot/scripts/lib/"
  # La seule règle retirée est celle du chemin des PDF ; tout le reste du garde-fou est le vrai.
  cp "$root/scripts/check-private.sh" "$depot/scripts/check-private.sh"
  chmod +x "$depot/scripts/check-private.sh"
  cp "$root/.githooks/pre-commit" "$depot/.githooks/"
  git -C "$depot" config core.hooksPath .githooks
  printf '# faux\n%s\n' "$motif" > "$depot/motifs.txt"

  # 1. Un PDF porteur du motif dans ses métadonnées : refusé, et c'est C21 qui parle.
  tests_pdf "$depot/assets/cv/cv-fr.pdf" "Rien" "$motif"
  tests_pdf "$depot/assets/cv/cv-en.pdf"
  git -C "$depot" add assets >/dev/null
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "essai"
  assert_eq 1 "$rc" "le commit d un PDF porteur d un motif est refusé"
  assert_contains "C21 : contenu privé dans les métadonnées" "$err" "C21 nomme la source"
  [[ $err != *"$motif"* ]] || { echo "le motif apparaît dans la sortie du hook" >&2; exit 1; }
  run git -C "$depot" rev-parse --verify HEAD
  assert_eq 128 "$rc" "aucun commit n a été créé"

  # 2. Deux PDF propres : C21 passe, le hook laisse le commit se faire.
  tests_pdf "$depot/assets/cv/cv-fr.pdf" "Parcours"
  git -C "$depot" add assets >/dev/null
  local avant apres
  avant=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -type d -name 'tmp.*' 2>/dev/null | wc -l)
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "essai propre"
  assert_eq 0 "$rc" "un PDF propre passe le hook (messages : $err)"
  assert_contains "aucun motif privé" "$out$err" "C21 a bien tourné et le dit"

  # 3. Le dossier temporaire ne survit pas au succès. Un « exec » sur le garde-fou annulerait le
  # « trap EXIT » du hook, et les CV extraits de l'index resteraient dans /tmp à chaque commit —
  # une fuite dans le hook qui existe pour l'empêcher (cinquième revue de la PR n° 84).
  apres=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -type d -name 'tmp.*' 2>/dev/null | wc -l)
  ((apres <= avant)) || {
    printf 'le hook laisse %s dossier(s) temporaire(s) derrière lui après un commit réussi.\n' \
      "$((apres - avant))" >&2
    exit 1
  }
}

case_pdf_le_pre_commit_ne_lance_c21_que_pour_assets_cv() {
  # Lancer poppler à chaque commit serait payer pour rien : le hook ne réveille C21 que si un
  # fichier de assets/cv/ est indexé.
  local depot=$work/depot2
  rm -rf "$depot"; mkdir -p "$depot/scripts/checks" "$depot/scripts/lib" "$depot/.githooks"
  git -C "$depot" init -q .
  git -C "$depot" config user.email essai@exemple.invalide
  git -C "$depot" config user.name Essai
  cp "$root/scripts/checks/pdf.sh" "$root/scripts/checks/lib.sh" "$depot/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$depot/scripts/lib/"
  cp "$root/scripts/check-private.sh" "$depot/scripts/"
  cp "$root/.githooks/pre-commit" "$depot/.githooks/"
  git -C "$depot" config core.hooksPath .githooks
  printf '# faux\n%s\n' "$motif" > "$depot/motifs.txt"
  printf 'du texte\n' > "$depot/lisez-moi.txt"
  git -C "$depot" add lisez-moi.txt >/dev/null
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "sans pdf"
  assert_eq 0 "$rc" "un commit sans PDF passe (messages : $err)"
  [[ $out$err != *"C21"* && $out$err != *"pdf:"* ]] \
    || { echo "C21 a tourné alors qu aucun fichier de assets/cv/ n est indexé" >&2; exit 1; }
}

case_pdf_fichier_inattendu_dans_le_dossier() {
  # Un « cv-ancien.pdf » oublié là ne serait lu par aucune boucle : il est refusé (revue du code
  # de la PR n° 84).
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"; tests_pdf "$work/cv/cv-ancien.pdf" "$motif"
  controle "$(liste)"
  assert_eq 1 "$rc" "un PDF inattendu fait échouer"
  assert_contains "fichier inattendu" "$err" "le signalement le dit"
  assert_contains "cv-ancien.pdf" "$err" "le signalement le nomme"
}

case_pdf_le_pre_commit_voit_un_nom_non_ascii() {
  # git cite et échappe en octal tout chemin non-ASCII : « assets/cv/café.pdf » devient
  # « "assets/cv/caf\303\251.pdf" », et un motif « ^assets/cv/ » ne colle plus. C21 serait sauté
  # en silence. Mot pour mot le trou que la rétrospective de l'epic 5 avait fermé dans le
  # garde-fou, et que je n'avais pas reporté dans ce hook neuf (deuxième revue de la PR n° 84).
  local depot=$work/depot3
  rm -rf "$depot"; mkdir -p "$depot/scripts/checks" "$depot/scripts/lib" "$depot/.githooks" "$depot/assets/cv"
  git -C "$depot" init -q .
  git -C "$depot" config user.email essai@exemple.invalide
  git -C "$depot" config user.name Essai
  cp "$root/scripts/checks/pdf.sh" "$root/scripts/checks/lib.sh" "$depot/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$depot/scripts/lib/"
  cp "$root/scripts/check-private.sh" "$depot/scripts/check-private.sh"
  chmod +x "$depot/scripts/check-private.sh"
  cp "$root/.githooks/pre-commit" "$depot/.githooks/"
  git -C "$depot" config core.hooksPath .githooks
  printf '# faux\n%s\n' "$motif" > "$depot/motifs.txt"

  # Un nom non-ASCII, donc cité par git ; le fichier est par ailleurs un intrus, ce que C21 doit
  # dire — et ne dira que s il a été réveillé.
  tests_pdf "$depot/assets/cv/cv-café.pdf"
  git -C "$depot" add assets >/dev/null
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "nom non ascii"
  assert_eq 1 "$rc" "un PDF au nom non-ASCII réveille bien C21"
  assert_contains "fichier inattendu" "$err" "C21 a parlé, donc le hook l a vu"
}

case_pdf_le_pre_commit_voit_une_suppression() {
  # Retirer un CV casse « ensemble ou rien » aussi sûrement qu'en ajouter un mauvais. Le filtre
  # « ACMR » excluait les suppressions : le hook ne réveillait pas C21, et un commit local pouvait
  # laisser un CV seul (troisième revue du code de la PR n° 84).
  local depot=$work/depot4
  rm -rf "$depot"; mkdir -p "$depot/scripts/checks" "$depot/scripts/lib" "$depot/.githooks" "$depot/assets/cv"
  git -C "$depot" init -q .
  git -C "$depot" config user.email essai@exemple.invalide
  git -C "$depot" config user.name Essai
  cp "$root/scripts/checks/pdf.sh" "$root/scripts/checks/lib.sh" "$depot/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$depot/scripts/lib/"
  cp "$root/scripts/check-private.sh" "$depot/scripts/check-private.sh"
  chmod +x "$depot/scripts/check-private.sh"
  cp "$root/.githooks/pre-commit" "$depot/.githooks/"
  git -C "$depot" config core.hooksPath .githooks
  printf '# faux\n%s\n' "$motif" > "$depot/motifs.txt"

  tests_pdf "$depot/assets/cv/cv-fr.pdf" "Parcours"
  tests_pdf "$depot/assets/cv/cv-en.pdf" "Experience"
  git -C "$depot" add assets >/dev/null
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "les deux"
  assert_eq 0 "$rc" "les deux CV se commitent (messages : $err)"

  git -C "$depot" rm -q assets/cv/cv-en.pdf
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "un seul reste"
  assert_eq 1 "$rc" "supprimer un CV réveille C21 et le commit est refusé"
  assert_contains "ensemble ou rien" "$err" "C21 nomme la règle"
}

case_pdf_le_pre_commit_voit_un_changement_de_type() {
  # Le filtre de type de changement a coûté trois tours de revue ; il n'y en a plus. Un CV
  # remplacé par un lien symbolique est un changement de type (« T »), que « ACDMR » n'aurait pas
  # vu non plus — c'est le cas suivant de la même série, écrit sans attendre qu'une revue le
  # trouve.
  local depot=$work/depot5
  rm -rf "$depot"; mkdir -p "$depot/scripts/checks" "$depot/scripts/lib" "$depot/.githooks" "$depot/assets/cv"
  git -C "$depot" init -q .
  git -C "$depot" config user.email essai@exemple.invalide
  git -C "$depot" config user.name Essai
  cp "$root/scripts/checks/pdf.sh" "$root/scripts/checks/lib.sh" "$depot/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$depot/scripts/lib/"
  cp "$root/scripts/check-private.sh" "$depot/scripts/check-private.sh"
  chmod +x "$depot/scripts/check-private.sh"
  cp "$root/.githooks/pre-commit" "$depot/.githooks/"
  git -C "$depot" config core.hooksPath .githooks
  printf '# faux\n%s\n' "$motif" > "$depot/motifs.txt"

  tests_pdf "$depot/assets/cv/cv-fr.pdf" "Parcours"
  tests_pdf "$depot/assets/cv/cv-en.pdf" "Experience"
  git -C "$depot" add assets >/dev/null
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "les deux"
  assert_eq 0 "$rc" "les deux CV se commitent (messages : $err)"

  # cv-en.pdf devient un lien symbolique vers un PDF porteur du motif : le contenu suivi change de
  # nature, et le commit doit être refusé.
  #
  # **Le garde-fou ne suit pas le lien, et c'est voulu.** Git range un lien symbolique comme un blob
  # contenant le chemin visé ; « git cat-file blob » rend donc ce texte, pas le PDF. C21 constate
  # l'absence d'en-tête « %PDF- » et refuse. Suivre le lien serait pire : il pointe hors du dépôt,
  # et le garde-fou lirait un fichier que personne ne commite.
  #
  # Le commentaire d'origine annonçait l'inverse — « C21 doit lire ce que le lien désigne » — et
  # personne ne l'a vu, parce que le lien était mort : le cas échouait par « ensemble ou rien », un
  # code 1 pour la mauvaise raison (revue de la PR n° 94). D'où l'assertion sur le **message**.
  tests_pdf "$depot/ailleurs.pdf" "Rien" "$motif"
  rm "$depot/assets/cv/cv-en.pdf"
  ln -s ../../ailleurs.pdf "$depot/assets/cv/cv-en.pdf"
  [[ -e $depot/assets/cv/cv-en.pdf ]] || { echo "le lien symbolique est mort : le cas ne prouverait rien" >&2; exit 1; }
  git -C "$depot" add assets >/dev/null
  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "changement de type"
  assert_eq 1 "$rc" "un changement de type réveille C21 et le commit est refusé"
  # Le refus vient de C21 qui refuse de traiter le lien comme un PDF — et **non** de la règle
  # « ensemble ou rien », qui aurait parlé si le lien était mort. Affirmer le message, et pas
  # seulement le code, est ce qui distingue les deux.
  assert_contains "ce n'est pas un PDF" "$err" "C21 refuse le lien plutôt que de le suivre hors du dépôt"
  [[ $err != *"ensemble ou rien"* ]] || { echo "le refus vient d un CV manquant, pas du changement de type" >&2; exit 1; }
}

case_pdf_sous_dossier_inattendu() {
  # Borner la recherche à la profondeur 1 était la même faute que borner le filtre du hook :
  # « assets/cv/vieux/cv.pdf » n'était lu par personne.
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"; tests_pdf "$work/cv/vieux/cv.pdf" "$motif"
  controle "$(liste)"
  assert_eq 1 "$rc" "un PDF dans un sous-dossier fait échouer"
  assert_contains "vieux/cv.pdf" "$err" "le signalement donne le chemin depuis le dossier des CV"
}

case_pdf_le_pre_commit_lit_lindex_et_non_larbre() {
  # Indexer un PDF porteur d'un motif, puis nettoyer le fichier sur le disque : c'est la version
  # **indexée** qui entrerait dans l'historique, et c'est donc elle que C21 doit lire. Lire l'arbre
  # de travail aurait fait passer le commit au vert (quatrième revue du code de la PR n° 84).
  local depot=$work/depot6
  rm -rf "$depot"; mkdir -p "$depot/scripts/checks" "$depot/scripts/lib" "$depot/.githooks" "$depot/assets/cv"
  git -C "$depot" init -q .
  git -C "$depot" config user.email essai@exemple.invalide
  git -C "$depot" config user.name Essai
  cp "$root/scripts/checks/pdf.sh" "$root/scripts/checks/lib.sh" "$depot/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$depot/scripts/lib/"
  cp "$root/scripts/check-private.sh" "$depot/scripts/check-private.sh"
  chmod +x "$depot/scripts/check-private.sh"
  cp "$root/.githooks/pre-commit" "$depot/.githooks/"
  git -C "$depot" config core.hooksPath .githooks
  printf '# faux\n%s\n' "$motif" > "$depot/motifs.txt"

  # La version privée est indexée…
  tests_pdf "$depot/assets/cv/cv-fr.pdf" "Rien" "$motif"
  tests_pdf "$depot/assets/cv/cv-en.pdf" "Experience"
  git -C "$depot" add assets >/dev/null
  # … puis l'arbre de travail est nettoyé. L'index, lui, garde le PDF porteur du motif.
  tests_pdf "$depot/assets/cv/cv-fr.pdf" "Parcours"

  run env PRIVATE_PATTERNS_FILE="$depot/motifs.txt" git -C "$depot" commit -q -m "index sale, arbre propre"
  assert_eq 1 "$rc" "c est la version indexée qui est contrôlée, pas celle du disque"
  assert_contains "contenu privé dans les métadonnées" "$err" "C21 a lu l index"
}

case_pdf_repli_sur_la_liste_du_depot() {
  # Sans variable, le contrôle doit trouver la liste du dépôt : « scripts/check.sh » ne la lui
  # passe pas, et sans ce repli il se contentait de la forme alors que la liste était là
  # (constaté à la story 7.2).
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"
  if [[ ! -f $root/docs/private/forbidden-patterns.txt ]]; then
    skip_case "pas de docs/private/ dans ce clone"
    return
  fi
  run env CHECK_CV_DIR="$work/cv" bash "$root/scripts/checks/pdf.sh"
  assert_eq 0 "$rc" "deux CV propres passent (messages : $err)"
  assert_contains "aucun motif privé" "$out" "la liste du dépôt a été trouvée et le contenu confronté"
}

controle_release() { # $1 = chemin de la liste des motifs, vide pour aucune
  run env CHECK_LEVEL=release CHECK_CV_DIR="$work/cv" \
    PRIVATE_PATTERNS_FILE="${1:-$work/liste-absente.txt}" bash "$root/scripts/checks/pdf.sh"
}

case_pdf_release_exige_la_liste() {
  # Hors « release », une liste absente laisse les règles de forme valoir et le contrôle le dit
  # (case_pdf_sans_liste_de_motifs). Au niveau d'une mise en ligne, non : l'image partirait avec deux
  # CV dont ni le texte, ni les métadonnées, ni le XMP n'auraient été confrontés — précisément les
  # endroits où un téléphone ou une commune se cachent sans qu'on les voie (story 11.3).
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"
  controle_release ""
  assert_eq 2 "$rc" "au niveau release, une liste absente est une anomalie, jamais un succès"
  assert_contains "liste des motifs absente" "$err" "le message le dit"
  assert_contains "release" "$err" "et nomme le niveau qui l'exige"
}

case_pdf_release_liste_sans_motif_est_une_anomalie() {
  # Le fichier **présent mais vide** : le piège est consigné (shell-scripts.md, story 0.8). Une liste
  # faite de commentaires passe le test d'existence et ne cherche rien.
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"
  printf '# que des commentaires\n\n   \n' > "$work/motifs-sans-motif.txt"
  controle_release "$work/motifs-sans-motif.txt"
  assert_eq 2 "$rc" "une liste sans motif ne vaut pas une liste"
  assert_contains "liste des motifs absente ou sans motif" "$err" "le message le dit"
}

case_pdf_release_sans_cv_exige_quand_meme_la_liste() {
  # Même sans CV à lire : l'absence de liste au niveau release est une anomalie de **configuration**,
  # pas un manque de contenu. Sans cette lecture, un dossier vide aurait rendu 0 et le garde-fou
  # serait resté ouvert le jour où les deux CV arrivent (point 18 : que laisse passer cette
  # condition ?).
  vide
  controle_release ""
  assert_eq 2 "$rc" "la liste est exigée avant même de regarder s'il y a des CV"
}

case_pdf_release_avec_la_liste() {
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf"
  controle_release "$(liste)"
  assert_eq 0 "$rc" "deux CV propres passent au niveau release (messages : $err)"
  assert_contains "aucun motif privé" "$out" "le contenu a bien été confronté"
}

case_pdf_release_trouve_le_motif() {
  vide; tests_pdf "$work/cv/cv-fr.pdf"; tests_pdf "$work/cv/cv-en.pdf" "$motif ici"
  controle_release "$(liste)"
  assert_eq 1 "$rc" "un motif dans un CV reste un écart, pas une anomalie"
  assert_contains "contenu privé" "$err" "le signalement est celui de C21"
}

run_case "$@"
