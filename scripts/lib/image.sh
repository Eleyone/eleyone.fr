# Lecture d'images sans outil d'image (AD-19 : « aucun autre outil d'image n'est ajouté »).
#
# À charger par « . "$(dirname "${BASH_SOURCE[0]}")/lib/image.sh" » ou son équivalent.
#
#   image_metadata_markers <fichier>   affiche les marqueurs de métadonnées trouvés, un par ligne
#   image_webp_dimensions <fichier>    affiche « <largeur>x<hauteur> » d'un WebP, ou rien
#
# **Cette bibliothèque est copiée sur la forge**, à côté de check-private.sh, parce que le hook
# pre-receive refuse une image porteuse de métadonnées avant publication (AD-19, AD-12) : la CI
# seule arriverait après que le miroir a publié. Elle n'a donc aucune dépendance en dehors de
# grep, od et des outils de base, et ne charge aucun autre fichier du dépôt.
#
# Pourquoi pas exiftool ni ImageMagick : AD-19 l'interdit, et un outil de plus à installer là où
# tourne Gitea est une charge de plus. La démonstration du 21/09/2026 (story 5.4) montre que grep
# et od suffisent — dimensions lues correctement, métadonnées détectées.

# Marqueurs cherchés dans les octets du fichier. Ce sont des chaînes littérales : les identifiants
# de chunk d'un conteneur (RIFF, PNG) et les en-têtes de segment (JPEG) sont en ASCII.
#
# « GPS » n'y figure pas, et c'est délibéré : **ce n'est pas un marqueur**. Une image d'essai
# portant de vraies coordonnées (48°51'N, 2°21'E) ne contient pas une seule fois la chaîne « GPS »
# — les coordonnées vivent en binaire dans l'IFD EXIF (constaté le 21/09/2026, story 5.4). La règle
# juste est donc : aucun EXIF, aucun XMP, aucun conteneur étendu. Sans eux, pas de GPS possible.
# AD-19 citait « GPS » parmi les marqueurs ; la précision y a été portée.
#
# Un faux positif refuse une image : c'est le bon sens d'erreur pour un garde-fou de vie privée.
readonly image_markers=(
  'Exif'                          # segment APP1 d'un JPEG, chunk EXIF d'un WebP (casse mixte)
  'EXIF'                          # chunk RIFF d'un WebP
  'eXIf'                          # chunk PNG
  'XMP '                          # chunk RIFF d'un WebP (l'identifiant fait quatre octets)
  'ns.adobe.com/xap'              # XMP dans un JPEG ou un PNG
  'VP8X'                          # WebP étendu : le seul format WebP qui puisse porter des chunks
  'tEXt'                          # texte d'un PNG
  'iTXt'
  'zTXt'
)

# Les extensions qu'un fichier image porte. **Seule liste du dépôt** : le garde-fou public/privé
# en tire ses motifs de chemin, et C20 sa recherche de fichiers. Elle existait en deux exemplaires
# — une expression régulière dans check-private.sh, un tableau dans checks/images.sh —, et un
# format ajouté à l'un et pas à l'autre aurait ouvert un trou, exactement le mécanisme du
# contournement de C20 (constat B3 de la rétrospective de l'epic 5).
readonly image_extensions=(jpg jpeg png gif webp avif tif tiff bmp heic heif ico)

image_extensions_regex() { # affiche « (jpg|jpeg|…) », le groupe d'une expression régulière étendue
  local IFS='|'
  printf '(%s)' "${image_extensions[*]}"
}

image_metadata_markers() { # $1 = fichier ; affiche les marqueurs trouvés, un par ligne
  local fichier=$1 marqueur code
  [[ -f $fichier && -r $fichier ]] || return 2
  for marqueur in "${image_markers[@]}"; do
    code=0
    # « -a » traite le binaire comme du texte : sans lui, grep se contente d'annoncer « binary file
    # matches » et l'appelant ne saurait pas lequel. « -F » et « -q » : chaîne fixe, réponse par le
    # code de retour, rien sur la sortie.
    grep -aqF -- "$marqueur" "$fichier" || code=$?
    ((code <= 1)) || return 2
    ((code == 0)) && printf '%s\n' "$marqueur"
  done
  return 0
}

image_webp_dimensions() { # $1 = fichier WebP ; affiche « <largeur>x<hauteur> », ou rien
  local fichier=$1 entete fourcc octets
  [[ -f $fichier && -r $fichier ]] || return 2
  # « RIFF » aux octets 0-3, « WEBP » aux octets 8-11, l'identifiant du premier chunk aux 12-15.
  #
  # Une lecture qui échoue rend **1 et non 2** : un fichier plus court que l'octet demandé n'est
  # pas une panne — c'est un fichier qui n'est pas un WebP lisible, et l'appelant doit pouvoir le
  # refuser sans arrêter la suite. Le 2 reste pour ce qui est illisible, testé en tête
  # (constat de la revue de la PR n° 69).
  entete=$(od -A n -c -N 4 "$fichier" 2>/dev/null | tr -d ' \n') || return 1
  [[ $entete == RIFF ]] || return 1
  fourcc=$(od -A n -c -j 12 -N 4 "$fichier" 2>/dev/null | tr -d ' \n') || return 1
  case $fourcc in
    # VP8 simple (avec perte) : après l'en-tête de chunk, le tag de trame (3 octets), le code de
    # synchronisation (3 octets), puis largeur et hauteur sur 14 bits, petit-boutistes.
    'VP8') octets=$(od -A n -t u1 -j 26 -N 4 "$fichier" 2>/dev/null) || return 1
           set -- $octets
           # Un fichier tronqué rend moins de quatre octets : sans cette borne, « $4 » n'existe
           # pas et « set -u » arrête le shell sur un message qui n'explique rien (constat de la
           # revue de la PR n° 69).
           (($# >= 4)) || return 1
           printf '%sx%s\n' "$(( ($1 | ($2 << 8)) & 0x3fff ))" "$(( ($3 | ($4 << 8)) & 0x3fff ))" ;;
    # VP8L (sans perte) : signature 0x2F, puis largeur-1 et hauteur-1 sur 14 bits, à cheval sur
    # les octets — d'où la lecture d'un entier de 32 bits et deux décalages.
    VP8L)  octets=$(od -A n -t u1 -j 21 -N 4 "$fichier" 2>/dev/null) || return 1
           set -- $octets
           (($# >= 4)) || return 1
           local mot=$(( $1 | ($2 << 8) | ($3 << 16) | ($4 << 24) ))
           printf '%sx%s\n' "$(( (mot & 0x3fff) + 1 ))" "$(( ((mot >> 14) & 0x3fff) + 1 ))" ;;
    # VP8X est refusé ailleurs comme marqueur de métadonnées : ses dimensions ne sont pas lues,
    # l'image ne doit pas exister.
    *)     return 1 ;;
  esac
}
