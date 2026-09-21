#!/usr/bin/env bash
# C20 — images : aucune métadonnée, dimensions et poids d'AD-19.
#
#   Aucune métadonnée   ni EXIF, ni XMP, ni conteneur WebP étendu (VP8X), dans assets/ comme dans
#                       public/. C'est la règle de vie privée : les données de prise de vue d'une
#                       photo portent l'appareil, la date et, souvent, les coordonnées GPS.
#   Copie commitée      assets/images/portrait.webp en 640 × 800, ≤ 150 000 o (AD-19)
#   Variantes publiées  dimensions parmi celles d'AD-19, ≤ 40 000 o chacune
#
# Le texte alternatif d'une image publiée n'est **pas** contrôlé ici : C11 le fait déjà pour tout
# <img> du site, avec ses dimensions (scripts/checks/html.sh). Le redire ici ferait deux gardes
# pour une règle, ce que la rétrospective de l'epic 3 a déjà coûté au projet.
#
# Aucun outil d'image n'est employé (AD-19) : la lecture des octets vit dans scripts/lib/image.sh,
# que le hook pre-receive de la forge charge aussi.
# Un kilo-octet vaut 1 000 octets, comme pour C13 (décidé par Arnaud le 19/09/2026).
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=images
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
. "$checks_lib_dir/../lib/image.sh"

public=${CHECK_PUBLIC_ROOT:-public}
assets=${CHECK_ASSETS_ROOT:-assets}

readonly copie=images/portrait.webp
readonly max_copie=150000
readonly max_variante=40000
readonly dimensions_copie=640x800
# Les quatre variantes d'AD-19 : accueil 120 × 150 et 240 × 300, « À propos » 160 × 200 et
# 320 × 400. Toutes au ratio 4:5, aucune au-delà de 640 px de large.
readonly variantes=(120x150 240x300 160x200 320x400)

status=0
signaler() { checks_report "$1" "$2"; status=1; }

# Toutes les images des deux arbres. « find » et non une liste écrite à la main : une image ajoutée
# sans passer par la story qui l'attendait doit être vue elle aussi.
# La liste vient de scripts/lib/image.sh : une seule écriture pour le garde-fou et pour C20
# (constat B3 de la rétrospective de l'epic 5).
lister() { # $1 = racine
  local racine=$1 args=() ext premier=1
  [[ -d $racine ]] || return 0
  for ext in "${image_extensions[@]}"; do
    ((premier)) || args+=(-o)
    args+=(-iname "*.$ext"); premier=0
  done
  checks_find "$racine" -type f \( "${args[@]}" \)
}

verifier_metadonnees() { # $1 = fichier
  local marqueurs code=0
  marqueurs=$(image_metadata_markers "$1") || code=$?
  ((code == 0)) || checks_die "lecture impossible de $1 (code $code)."
  [[ -z $marqueurs ]] \
    || signaler "$1" "C20 : métadonnées dans l'image ($(tr '\n' ' ' <<< "$marqueurs" | sed 's/ $//')) ; l'original ne doit jamais être commité, et la copie se prépare par scripts/photo/prepare.sh (AD-19)"
}

for racine in "$assets" "$public"; do
  liste=$(lister "$racine")
  [[ -n $liste ]] || continue
  while IFS= read -r fichier; do
    [[ -n $fichier ]] || continue
    verifier_metadonnees "$fichier"
  done <<< "$liste"
done

# La copie commitée : le seul fichier dont AD-19 fixe les dimensions exactes.
fichier_copie="$assets/$copie"
if [[ -f $fichier_copie ]]; then
  octets=$(wc -c < "$fichier_copie")
  ((octets <= max_copie)) \
    || signaler "$fichier_copie" "C20 : $octets o, au-delà des $max_copie o de la copie commitée (AD-19)"
  dims=$(image_webp_dimensions "$fichier_copie") || dims=""
  [[ $dims == "$dimensions_copie" ]] \
    || signaler "$fichier_copie" "C20 : ${dims:-format WebP non reconnu} ; $dimensions_copie attendu (AD-19)"
fi

# Les variantes publiées. Seules les images de public/ produites depuis la copie sont concernées :
# elles portent son nom de base, suivi de l'empreinte que pose Hugo.
liste=$(lister "$public")
if [[ -n $liste ]]; then
  # « portrait_hu_ » et non « portrait » : Hugo nomme une ressource transformée
  # « <base>_hu_<clé>.<empreinte>.<ext> », et le préfixe nu aurait aussi attrapé un futur
  # « portrait-equipe.webp », qui n'a aucune raison de tenir dans les dimensions du portrait
  # (constat de la revue de la PR n° 69).
  base=$(basename "$copie" .webp)_hu_
  while IFS= read -r fichier; do
    [[ -n $fichier ]] || continue
    [[ $(basename "$fichier") == "$base"* ]] || continue
    octets=$(wc -c < "$fichier")
    ((octets <= max_variante)) \
      || signaler "$fichier" "C20 : $octets o, au-delà des $max_variante o d'une variante publiée (AD-19)"
    dims=$(image_webp_dimensions "$fichier") || dims=""
    connue=0
    for attendue in "${variantes[@]}"; do [[ $dims == "$attendue" ]] && connue=1; done
    ((connue)) \
      || signaler "$fichier" "C20 : ${dims:-format WebP non reconnu} ; attendu l'une des variantes d'AD-19 (${variantes[*]})"
  done <<< "$liste"
fi

((status == 0)) || exit 1
printf '%s: aucune métadonnée, dimensions et poids des images conformes à AD-19.\n' "$script_name"
