#!/usr/bin/env bash
# C20 et la lecture d'images sans outil d'image (story 5.4).
#
# Les fichiers d'essai sont **fabriqués octet par octet** par ces cas, et aucun n'est commité.
# La story posait la question : une image commitée sous fixtures/ ne démontrerait rien. Une image
# porteuse de métadonnées serait refusée par C20 lui-même et par le garde-fou ; une image qui n'en
# porte pas ne prouverait pas que le contrôle les voit. Fabriquer les octets règle les deux, et
# n'ajoute aucune dépendance : ni Python, ni PIL, ni outil d'image (AD-19).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$root/scripts/lib/image.sh"

# Un WebP VP8 simple, sans aucune métadonnée. Les données du chunk ne sont pas une vraie image —
# rien ici ne décode le contenu, seuls l'en-tête et les identifiants de chunk sont lus.
webp_simple() { # $1 = fichier, $2 = largeur, $3 = hauteur, $4 = octets de bourrage (défaut 32)
  local f=$1 l=$2 h=$3 bourre=${4:-32}
  {
    printf 'RIFF'; printf '\377\377\000\000'
    printf 'WEBP'
    printf 'VP8 '; printf '\377\377\000\000'
    printf '\000\000\000'                                   # tag de trame
    printf '\235\001\052'                                   # code de synchronisation
    # largeur et hauteur sur 14 bits, petit-boutistes
    printf "$(printf '\\%03o' $((l & 0xff)) $(((l >> 8) & 0x3f)) $((h & 0xff)) $(((h >> 8) & 0x3f)))"
    head -c "$bourre" /dev/zero
  } > "$f"
}

# Le même, mais en conteneur étendu porteur d'un chunk EXIF : le cas que C20 doit refuser.
webp_avec_metadonnees() { # $1 = fichier
  {
    printf 'RIFF'; printf '\070\000\000\000'
    printf 'WEBP'
    printf 'VP8X'; printf '\012\000\000\000'
    printf '\010\000\000\000'                               # drapeaux : bit EXIF
    printf '\177\002\000'; printf '\037\003\000'            # 640 × 800, moins un
    printf 'EXIF'; printf '\014\000\000\000'
    printf 'Exif\000\000MM\000\052\000\000'
  } > "$1"
}

case_image_dimensions_sans_outil() {
  local f="$work/simple.webp"
  webp_simple "$f" 640 800
  assert_eq "640x800" "$(image_webp_dimensions "$f")" "les dimensions se lisent dans l'en-tête VP8"
  webp_simple "$f" 120 150
  assert_eq "120x150" "$(image_webp_dimensions "$f")" "une petite variante aussi"
  # 16383 est le maximum d'un champ de 14 bits : au-delà, la lecture se tromperait en silence.
  webp_simple "$f" 16383 16383
  assert_eq "16383x16383" "$(image_webp_dimensions "$f")" "la borne des 14 bits est lue juste"
}

case_image_marqueurs_de_metadonnees() {
  local propre="$work/propre.webp" sale="$work/sale.webp"
  webp_simple "$propre" 640 800
  assert_eq "" "$(image_metadata_markers "$propre")" "un VP8 simple ne porte aucun marqueur"

  webp_avec_metadonnees "$sale"
  local marqueurs
  marqueurs=$(image_metadata_markers "$sale")
  local attendu
  for attendu in Exif EXIF VP8X; do
    assert_contains "$attendu" "$marqueurs" "le marqueur « $attendu » est vu"
  done

  # Un PNG porteur d'un chunk de texte, et un JPEG porteur de XMP : les deux autres formats que
  # assets/ peut désormais accueillir.
  printf '\211PNG\r\n\032\n' > "$work/p.png"; printf 'tEXtComment\000essai' >> "$work/p.png"
  assert_contains "tEXt" "$(image_metadata_markers "$work/p.png")" "un chunk de texte PNG est vu"
  printf '\377\330\377\341' > "$work/j.jpg"; printf 'http://ns.adobe.com/xap/1.0/\000' >> "$work/j.jpg"
  assert_contains "ns.adobe.com/xap" "$(image_metadata_markers "$work/j.jpg")" "le XMP d'un JPEG est vu"
}

case_image_vp8x_na_pas_de_dimensions_lisibles() {
  # VP8X est refusé comme marqueur : ses dimensions ne sont pas lues, l'image ne doit pas exister.
  local f="$work/etendu.webp"
  webp_avec_metadonnees "$f"
  local rc=0
  image_webp_dimensions "$f" > /dev/null || rc=$?
  assert_eq 1 "$rc" "un conteneur étendu n'est pas mesuré"
  printf 'pas une image' > "$work/x.webp"
  rc=0; image_webp_dimensions "$work/x.webp" > /dev/null || rc=$?
  assert_eq 1 "$rc" "un fichier qui n'est pas un RIFF non plus"
}

c20() { # lance le contrôle sur les racines d'essai
  run env CHECK_ASSETS_ROOT="$work/assets" CHECK_PUBLIC_ROOT="$work/public" \
    bash "$root/scripts/checks/images.sh"
}

case_c20_refuse_les_metadonnees() {
  mkdir -p "$work/assets/images" "$work/public"
  webp_simple "$work/assets/images/portrait.webp" 640 800
  c20
  assert_eq 0 "$rc" "une copie conforme passe (messages : $err)"

  webp_avec_metadonnees "$work/assets/images/autre.webp"
  c20
  assert_eq 1 "$rc" "une image porteuse de métadonnées fait échouer"
  assert_contains "C20 : métadonnées dans l'image" "$err" "le signalement le dit"
  assert_contains "VP8X" "$err" "et nomme les marqueurs"
  rm "$work/assets/images/autre.webp"
}

case_c20_dimensions_et_poids() {
  mkdir -p "$work/assets/images" "$work/public/images"
  webp_simple "$work/assets/images/portrait.webp" 640 800
  c20
  assert_eq 0 "$rc" "la copie conforme passe (messages : $err)"

  webp_simple "$work/assets/images/portrait.webp" 500 800
  c20
  assert_eq 1 "$rc" "une copie hors dimensions fait échouer"
  assert_contains "500x800 ; 640x800 attendu" "$err" "le signalement donne les deux"

  webp_simple "$work/assets/images/portrait.webp" 640 800 160000
  c20
  assert_eq 1 "$rc" "une copie trop lourde fait échouer"
  assert_contains "au-delà des 150000 o" "$err" "le signalement donne la limite"

  webp_simple "$work/assets/images/portrait.webp" 640 800
  webp_simple "$work/public/images/portrait_hu_x.webp" 120 150
  c20
  assert_eq 0 "$rc" "une variante conforme passe (messages : $err)"

  webp_simple "$work/public/images/portrait_hu_x.webp" 300 300
  c20
  assert_eq 1 "$rc" "une variante hors dimensions fait échouer"
  assert_contains "attendu l'une des variantes d'AD-19" "$err" "le signalement liste les variantes"

  webp_simple "$work/public/images/portrait_hu_x.webp" 120 150 50000
  c20
  assert_eq 1 "$rc" "une variante trop lourde fait échouer"
  assert_contains "au-delà des 40000 o" "$err" "le signalement donne la limite de variante"
}

case_image_fichier_tronque() {
  # Un WebP correctement entêté mais coupé : sans borne, « $4 » n'existe pas et « set -u » arrête
  # le shell sur un message qui n'explique rien (constat de la revue de la PR n° 69).
  local f="$work/tronque.webp"
  printf 'RIFF\377\377\000\000WEBPVP8 \377\377\000\000\000\000' > "$f"
  local rc=0
  image_webp_dimensions "$f" > /dev/null || rc=$?
  assert_eq 1 "$rc" "un fichier tronqué est refusé, pas fatal"
}

case_c20_ne_confond_pas_une_autre_image_avec_une_variante() {
  # « portrait-equipe.webp » n'est pas une variante du portrait : le préfixe nu l'aurait attrapée
  # et refusée sur ses dimensions (constat de la revue de la PR n° 69). Hugo nomme une ressource
  # transformée « <base>_hu_<clé>.<empreinte>.<ext> ».
  mkdir -p "$work/assets/images" "$work/public/images"
  webp_simple "$work/assets/images/portrait.webp" 640 800
  webp_simple "$work/public/images/portrait-equipe.webp" 700 300
  c20
  assert_eq 0 "$rc" "une autre image n'est pas jugée sur les dimensions du portrait (messages : $err)"
  webp_simple "$work/public/images/portrait_hu_z.webp" 700 300
  c20
  assert_eq 1 "$rc" "une vraie variante, elle, l'est"
}

case_c20_ignore_ce_qui_nest_pas_une_image() {
  mkdir -p "$work/assets/images" "$work/public"
  webp_simple "$work/assets/images/portrait.webp" 640 800
  # Un fichier qui contient « Exif » mais n'est pas une image : C20 ne regarde que les extensions
  # d'images, sinon un script qui *parle* de métadonnées ferait échouer le contrôle.
  printf 'ce texte parle de Exif et de VP8X\n' > "$work/assets/notes.txt"
  c20
  assert_eq 0 "$rc" "un fichier qui n'est pas une image est ignoré (messages : $err)"
}

case_prepare_refuse_un_original_du_depot_meme_par_un_lien() {
  # « pwd » rend le chemin logique : atteint par un lien symbolique, la racine gardait la forme du
  # lien tandis que readlink -f rendait la forme réelle, et la comparaison échouait pour *tout*
  # fichier du dépôt — le garde-fou ne gardait rien (constat bloquant de la revue de la PR n° 70).
  local piege="$root/assets/.essai-original-du-depot.jpg"
  # Un fichier qui n'est pas une image : le refus doit tomber **avant** que Hugo soit lancé.
  printf 'pas une image\n' > "$piege"
  local lien="$work/lien-depot"
  ln -s "$root" "$lien"

  run bash "$root/scripts/photo/prepare.sh" "$piege" Top
  assert_eq 1 "$rc" "un original du dépôt est refusé par son chemin réel"
  assert_contains "est dans ce dépôt" "$err" "le refus le dit"

  run bash "$lien/scripts/photo/prepare.sh" "$lien/assets/.essai-original-du-depot.jpg" Top
  assert_eq 1 "$rc" "et aussi lorsqu'on passe par un lien symbolique"
  assert_contains "est dans ce dépôt" "$err" "le refus le dit aussi"
  rm -f "$piege"
}

run_case "$@"
