# Lecture d'un PDF, sans autre outil que poppler (AD-21). Chargée par le contrôle C21 et par le
# garde-fou, comme lib/image.sh l'est pour C20 — et pour la même raison : le garde-fou tourne sur
# la forge, loin du dépôt, et ne peut dépendre que de ce qu'on lui recopie à côté.
#
# Trois sources, parce qu'un téléphone ou une ville de résidence s'y cachent différemment :
#   - le **texte**, ce que le lecteur voit ;
#   - les **métadonnées**, qu'un export remplit tout seul et que personne ne regarde ;
#   - le **XMP**, paquet XML que les outils Adobe y laissent.
#
# Aucune fonction n'affiche ce qu'elle lit : elles rendent l'extrait, et c'est à l'appelant de le
# confronter sans jamais le montrer.

# Les deux commandes nécessaires. Rend 1 si l'une manque, et nomme le paquet : l'appelant décide
# si c'est une anomalie (contrôle) ou un refus (garde-fou), mais jamais un succès.
pdf_missing_tool() {
  local outil
  for outil in pdftotext pdfinfo; do
    command -v "$outil" > /dev/null 2>&1 || { printf '%s' "$outil"; return 0; }
  done
  return 1
}

# Le texte d'un PDF. Rend 1 si poppler ne sait pas le lire — un fichier corrompu n'est pas un
# fichier vide, et le confondre ferait passer un PDF illisible pour un PDF propre.
pdf_text() { # $1 = fichier
  pdftotext "$1" - 2> /dev/null
}

# Les métadonnées lisibles (Title, Author, Subject, Keywords, Producer…).
pdf_metadata() { # $1 = fichier
  pdfinfo "$1" 2> /dev/null
}

# Le paquet XMP, s'il existe. Son absence n'est pas une erreur : la plupart des PDF n'en ont pas.
pdf_xmp() { # $1 = fichier
  pdfinfo -meta "$1" 2> /dev/null || true
}

# Le nombre de pages, ou rien si pdfinfo ne sait pas lire le fichier.
pdf_pages() { # $1 = fichier
  local infos
  infos=$(pdfinfo "$1" 2> /dev/null) || return 1
  sed -n 's/^Pages:[[:space:]]*\([0-9]\+\).*/\1/p' <<< "$infos" | head -1
}

# Un fichier commence-t-il par l'en-tête PDF ? Lu sur cinq octets, jamais par grep : un binaire
# n'est pas du texte.
pdf_has_header() { # $1 = fichier
  [[ $(head -c 5 "$1" 2> /dev/null) == '%PDF-' ]]
}
