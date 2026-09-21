#!/usr/bin/env bash
# Prépare la copie commitée de la photo (AD-19).
#
#   scripts/photo/prepare.sh <original> <ancrage>
#
# <original> est le fichier source, **hors du dépôt** : il n'est jamais commité ni même placé sous
# le dossier du dépôt, et le script le refuse s'il s'y trouve.
# <ancrage> est obligatoire : Top, Center, Bottom, Left, Right, TopLeft, TopRight, BottomLeft,
# BottomRight. « Smart » est refusé — le cadrage d'un portrait se choisit à l'œil, pas par un
# algorithme, et un résultat différent d'une version de Hugo à l'autre ne se verrait pas.
#
# Le travail est fait par le **Hugo épinglé de tools.env** sur un mini-projet temporaire hors du
# dépôt : « .Process "fill 640x800 <ancrage> webp q80" ». **fill et non crop** : dans Hugo, « crop »
# découpe une fenêtre de 640 × 800 pixels *de l'original*, sans redimensionner — sur une photo de
# 1360 × 2048, cela donne un gros plan qui coupe le menton. « fill » met à l'échelle puis recadre
# au ratio, ce qu'AD-19 décrit en toutes lettres (« recadre au ratio 4:5 et le ramène à 640 × 800 »)
# mais prescrivait mal (constaté le 21/09/2026, story 5.5). Aucun autre outil d'image n'est ajouté
# (AD-19). Le spike, revérifié le 21/09/2026, montre qu'un JPEG portant EXIF et GPS ressort en
# WebP sans aucune trace d'Exif, de XMP ni de VP8X — donc sans emplacement de métadonnées.
#
# Codes de sortie : 0 copie écrite, 1 refus (ancrage, original, résultat non conforme), 2 anomalie.
# Procédure : docs/procedures/photo.md
set -euo pipefail

script_name=photo/prepare
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
# Le dossier d'appel est retenu avant de se placer à la racine : un original désigné en relatif se
# résout depuis là où l'utilisateur l'a écrit (même règle que scripts/build-image.sh).
appel=$PWD
cd "$root"
. "$root/scripts/lib/tools.sh"
. "$root/scripts/lib/image.sh"

die() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

(($# == 2)) || die "usage : $0 <original> <ancrage>
Ancrages : Top, Center, Bottom, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight."
original=$1
ancrage=$2

readonly ancrages=(Top Center Bottom Left Right TopLeft TopRight BottomLeft BottomRight)
connu=0
for a in "${ancrages[@]}"; do [[ $ancrage == "$a" ]] && connu=1; done
((connu)) || refuse "ancrage « $ancrage » refusé ; attendu l'un de : ${ancrages[*]}.
« Smart » est refusé par AD-19 : le cadrage d'un portrait se choisit à l'œil."

[[ $original == /* ]] || original="$appel/$original"
[[ -f $original && -r $original ]] || refuse "original introuvable ou illisible ($original)."

# L'original ne doit jamais entrer dans **l'historique de ce dépôt** (AD-19). La comparaison porte
# sur le chemin canonique : un lien symbolique posé dans le dépôt ne passe pas.
#
# docs/private/ fait exception, et c'est le lieu prévu : c'est un **autre dépôt**, ignoré par
# celui-ci, refusé par check-private.sh et par le hook de la forge, et AGENTS.md y place l'original
# de la photo. Sa position physique sous le dossier de travail n'en fait pas un fichier de ce
# dépôt (précision apportée par Arnaud le 21/09/2026, story 5.5 ; AD-19 disait « sous le dossier
# du dépôt », ce qui visait l'historique et non le disque).
#
# **Les deux côtés sont canonisés.** « pwd » rend le chemin logique : atteint par un lien
# symbolique, $root garde la forme du lien, tandis que readlink -f rend la forme réelle. La
# comparaison échouait alors pour *tout* fichier du dépôt, et le garde-fou ne gardait rien —
# vérifié en appelant le script à travers un lien (constat bloquant de la revue de la PR n° 70).
canonique=$(readlink -f -- "$original") || die "chemin de l'original illisible."
racine=$(readlink -f -- "$root") || die "chemin du dépôt illisible."
prive=$(readlink -f -- "$racine/docs/private" 2>/dev/null || printf '%s' "$racine/docs/private")
if [[ $canonique == "$racine"/* && $canonique != "$prive"/* ]]; then
  refuse "l'original est dans ce dépôt ($canonique) : AD-19 veut qu'il n'entre jamais dans son historique.
Le lieu prévu est docs/private/assets/, qui est un autre dépôt, ignoré par celui-ci (AGENTS.md)."
fi

load_tools_env "${TOOLS_ENV_FILE:-$root/tools.env}"
hugo=${TOOLS_LOCAL_DIR:-$root/.tools}/hugo
[[ -x $hugo ]] || hugo=$(command -v hugo) \
  || die "hugo est introuvable : lancer scripts/ci/install-tools.sh --local."

# Le mini-projet est temporaire et hors du dépôt : rien n'y est laissé, et un échec ne dépose aucun
# fichier à moitié écrit dans assets/.
travail=$(mktemp -d) || die "dossier temporaire impossible."
trap 'rm -rf "$travail"' EXIT

mkdir -p "$travail/assets/images" "$travail/layouts"
# Hugo reconnaît le format par l'extension : elle est reportée telle quelle, et un original qui
# n'en a pas est refusé plutôt que copié sous un nom que Hugo ne saurait pas lire.
nom_original=$(basename -- "$original")
[[ $nom_original == *.* ]] \
  || refuse "l'original n'a pas d'extension ($nom_original) : Hugo reconnaît le format par elle."
source_nom="source.${nom_original##*.}"
cp -- "$original" "$travail/assets/images/$source_nom" || die "copie de l'original impossible."

cat > "$travail/hugo.toml" <<EOF
baseURL = "https://exemple.invalid/"
title = "preparation-photo"
disableKinds = ["taxonomy", "term", "rss", "sitemap", "robotsTXT", "404"]
EOF

# « .Publish » écrit la ressource même si la page ne la référence pas dans son HTML.
cat > "$travail/layouts/home.html" <<EOF
{{- with resources.Get "images/$source_nom" -}}
  {{- \$p := .Process "fill 640x800 $ancrage webp q80" -}}
  {{- \$p.Publish -}}
  {{ \$p.RelPermalink }}
{{- end -}}
EOF

printf '%s: %s, ancrage %s, par Hugo %s.\n' "$script_name" "$canonique" "$ancrage" "${HUGO_VERSION:-?}"
(cd "$travail" && "$hugo" --quiet --destination "$travail/public") \
  || refuse "Hugo n'a pas pu traiter l'original ; format non pris en charge, ou fichier abîmé."

# « -print -quit » plutôt que « | head -1 » : sous « set -o pipefail », head fermerait le flux,
# find recevrait un SIGPIPE, et le script s'arrêterait sur un code 141 qui n'explique rien
# (constat de la revue de la PR n° 69).
produit=$(find "$travail/public" -type f -name '*.webp' -print -quit)
[[ -n $produit ]] || refuse "Hugo n'a produit aucun WebP ; vérifier que l'original est bien une image."

# Le résultat est contrôlé **avant** d'entrer dans le dépôt : mieux vaut refuser ici que laisser
# C20 le découvrir après un commit.
marqueurs=$(image_metadata_markers "$produit") || die "lecture du résultat impossible."
[[ -z $marqueurs ]] \
  || refuse "le WebP produit porte des métadonnées ($(tr '\n' ' ' <<< "$marqueurs")) : ne pas le commiter, et signaler l'écart — AD-19 repose sur le fait que Hugo n'en laisse aucune."
dims=$(image_webp_dimensions "$produit") || dims=""
[[ $dims == 640x800 ]] || refuse "le WebP produit fait ${dims:-un format non reconnu} ; 640x800 attendu."
octets=$(wc -c < "$produit")
((octets <= 150000)) || refuse "le WebP produit fait $octets o, au-delà des 150 000 o d'AD-19 ; baisser la qualité plutôt que la taille."

mkdir -p "$root/assets/images"
cp -- "$produit" "$root/assets/images/portrait.webp" || die "écriture de la copie impossible."
printf '%s: assets/images/portrait.webp écrit, %s, %s o.\n' "$script_name" "$dims" "$octets"
printf '%s: regarder le cadrage avant de commiter ; un autre ancrage se rejoue par la même commande.\n' "$script_name"
