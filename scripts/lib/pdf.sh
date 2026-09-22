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
#
# À charger par « . "$(dirname "${BASH_SOURCE[0]}")/lib/pdf.sh" » ou son équivalent.
#
#   pdf_cv_names                      les deux seuls CV qu'AD-21 nomme
#   pdf_cv_names_regex                affiche « (cv-fr\.pdf|cv-en\.pdf) », le groupe d'une regex étendue
#   pdf_missing_tool                  affiche l'outil poppler manquant, ou rend 1 si les deux sont là
#   pdf_text <fichier>                affiche le texte du PDF
#   pdf_metadata <fichier>            affiche les métadonnées lisibles
#   pdf_xmp <fichier>                 affiche le paquet XMP, s'il existe
#   pdf_pages <fichier>               affiche le nombre de pages
#   pdf_has_header <fichier>          rend 0 si le fichier commence par « %PDF- »

# Les deux seuls noms de CV qu'AD-21 connaît. **Seule liste du dépôt** : le garde-fou en tire ses
# motifs de chemin, C21 sa paire attendue et sa règle « tout autre fichier est refusé », et C12 les
# fichiers qu'il cherche dans le rendu. Ils vivaient en quatre exemplaires sous quatre formes —
# un tableau, deux « ! -name », trois expressions régulières, deux « resources.Get » — ce qui est
# exactement la configuration qui avait ouvert le contournement de C20 et que la rétrospective de
# l'epic 5 avait fermée pour les images, sans que la leçon passe dans la bibliothèque jumelle
# écrite sept jours plus tard (constat A1 et point 19 d'AGENTS.md, rétrospective de l'epic 7).
#
# Le dossier des sources et celui de publication sont distincts, et les confondre a rendu la
# clause CV de C12 inerte pendant tout l'epic : Hugo sort une ressource de « assets/cv/x » à
# « /cv/x » (constat B2).
readonly pdf_cv_names=(cv-fr.pdf cv-en.pdf)
readonly pdf_cv_assets_dir=assets/cv
readonly pdf_cv_published_dir=cv

# Les noms sont alternés **entiers**, et non décomposés en « cv-(fr|en)\.pdf » : une première
# écriture découpait le préfixe et le suffixe, si bien qu'un nom ne suivant pas cette forme aurait
# produit une regex qui ne l'autorise pas — et le commentaire d'à côté promettait pourtant qu'un
# troisième nom ne demanderait aucune retouche (revue de la PR n° 94). La forme entière tient cette
# promesse, au prix de quelques caractères.
pdf_cv_names_regex() { # affiche « (cv-fr\.pdf|cv-en\.pdf) », le groupe d'une expression régulière étendue
  local nom motifs=()
  for nom in "${pdf_cv_names[@]}"; do motifs+=("${nom//./\\.}"); done
  local IFS='|'
  printf '(%s)' "${motifs[*]}"
}

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
