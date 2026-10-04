# Les valeurs légales d'AD-9, telles qu'un script hors de Hugo les lit et les cherche dans une page
# rendue. À charger par « . scripts/lib/legal.sh » ; charge lui-même dotenv.sh et text.sh.
#
#   legal_page_fr, legal_page_en, legal_page_urls
#                               les deux pages des mentions légales, en chemins d'URL. Les permaliens
#                               viennent d'ARCHITECTURE-SPINE (« Slugs des pages simples ») ; C23
#                               (scripts/checks/legal-address.sh) en tire ses chemins de fichiers
#   legal_names_into <tableau> <fichier>
#                               les noms « HUGO_LEGAL_* » d'un fichier modèle (.env.example), dans
#                               l'ordre, sans doublon ; rend 1 si le fichier est illisible
#   legal_values_into <tableau associatif> <tableau des manquants> <fichier> <nom>…
#                               la valeur de chaque nom dans un fichier dotenv ; les noms absents ou
#                               vides vont dans le second tableau ; rend 1 si le fichier est illisible
#   legal_comparable_value <variable> <valeur>
#                               la forme sous laquelle une valeur se cherche dans une page
#   legal_comparable_text       filtre : la forme sous laquelle une page se lit
#
# **Aucune fonction n'affiche une valeur.** Les valeurs légales de mise en ligne vivent dans le
# dépôt privé ; elles sont publiques une fois le site en ligne, mais pas avant, et un journal se
# colle dans une conversation (NFR-9, AD-9). Tout ce qui sort d'ici remplit une variable de
# l'appelant (piège connu de « $(…) », .working-method/procedures/shell-scripts.md).
#
# Né à la story 11.9, pour que la répétition générale vérifie elle-même que les pages légales
# servies portent les vraies valeurs (arbitrage d'Arnaud du 02/10/2026 : « la vérif doit se faire
# systématiquement et automatiquement »).

legal_lib_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || return 2
# dotenv.sh vit dans l'outillage commun (sous-module .working-method, story outillage-14)
# shellcheck source=../../.working-method/lib/dotenv.sh
. "$legal_lib_dir/../../.working-method/lib/dotenv.sh" || return 2
# shellcheck source=text.sh
. "$legal_lib_dir/text.sh" || return 2

# AD-9 fixe ces deux pages, et elles seules portent les valeurs (layouts/_partials/legal-value.html
# refuse toute autre lecture). Écrites une fois : C23 les lisait en chemins de fichiers, la
# répétition les interroge en chemins d'URL, et deux écritures auraient fini par diverger.
legal_page_fr=/mentions-legales/
legal_page_en=/en/legal-notice/
legal_page_urls=("$legal_page_fr" "$legal_page_en")

# Les noms, lus dans le modèle plutôt qu'écrits ici : .env.example est la liste qui fait foi, et un
# nombre écrit en dur est devenu faux trois fois à la story 9.1 (legal-value.html le raconte).
legal_names_into() { # $1 = nom du tableau à remplir, $2 = fichier modèle
  local -n legal_names_destination=$1
  local lignes ligne cle connu deja
  legal_names_destination=()
  lignes=$(dotenv_read "$2" HUGO_LEGAL_) || return 1
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    cle=${ligne%%=*}
    deja=0
    for connu in "${legal_names_destination[@]}"; do [[ $connu != "$cle" ]] || deja=1; done
    ((deja == 1)) || legal_names_destination+=("$cle")
  done <<< "$lignes"
  return 0
}

# La règle de scripts/env.sh, le chargeur que le build emploie : **pour un fichier, une valeur vide
# vaut absence**, et la première valeur non vide d'un nom est la sienne. Une autre règle ici
# comparerait la page à une valeur que le build n'aurait pas retenue.
# La clé est comparée **entière** : le préfixe de dotenv_read laisserait passer
# « HUGO_LEGAL_HOST_NAMES » pour « HUGO_LEGAL_HOST_NAME ».
legal_values_into() { # $1 = tableau associatif, $2 = tableau des manquants, $3 = fichier, $4… = noms
  local -n legal_values_destination=$1
  local -n legal_missing_destination=$2
  local fichier=$3 lignes ligne cle valeur nom
  shift 3
  legal_values_destination=()
  legal_missing_destination=()
  lignes=$(dotenv_read "$fichier" HUGO_LEGAL_) || return 1
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    cle=${ligne%%=*}
    valeur=${ligne#*=}
    for nom in "$@"; do
      [[ $cle == "$nom" ]] || continue
      # Une seule garde, comme dans env.sh : la valeur n'est écrite que si le nom n'en a pas encore
      # de non vide. Elle couvre les deux cas d'un coup — une entrée vide n'empêche pas la suivante,
      # et une valeur retenue n'est pas écrasée par une plus loin.
      [[ -n ${legal_values_destination[$nom]:-} ]] || legal_values_destination[$nom]=$valeur
    done
  done <<< "$lignes"
  for nom in "$@"; do
    [[ -n ${legal_values_destination[$nom]:-} ]] || legal_missing_destination+=("$nom")
  done
  return 0
}

# **La valeur et la page sont ramenées à la même forme**, comme C23 le fait pour l'adresse de
# l'éditeur. Ce que le rendu fait d'une valeur, mesuré sur un vrai build de production le 02/10/2026
# (story 11.9, commandes dans le fichier de story) :
#
#   - le minifieur replie toute suite d'espaces en une seule : « 123  456 » devient « 123 456 » ;
#   - sur la page française seulement, la typographie remplace l'espace devant « : » par U+00A0, et
#     celle devant « ; », « ! », « ? » ou à l'intérieur des guillemets par U+202F ;
#   - le minifieur écrit « < » en « &lt; », laisse « & », « ' » et « " » en clair, et une valeur qui
#     porte déjà « &amp; » sort en « &amp;amp; ». Une autre sérialisation de la même page écrirait
#     « &amp; », « &#39; » ou « &#43; » : le décodage les couvre toutes, comme pour C23.
#
# La valeur n'est **pas décodée** : elle est le texte voulu, et le rendu la ré-encode. Décoder la
# page suffit, et décoder aussi la valeur ferait correspondre « &amp; » écrit dans le fichier à
# « & » affiché sur la page — deux textes différents.
legal_comparable_value() { # $1 = variable à remplir, $2 = valeur
  local legal_comparable_forme
  legal_comparable_forme=$(printf '%s' "$2" | replier_espaces_insecables | normaliser_blancs) || return 1
  # Les espaces de bord ne s'affichent pas : le minifieur les retire autour d'un élément.
  legal_comparable_forme=${legal_comparable_forme# }
  legal_comparable_forme=${legal_comparable_forme% }
  printf -v "$1" '%s' "$legal_comparable_forme"
}

# L'ordre compte : les entités d'insécables avant le décodage général (voir text.sh), le repli
# après, et la normalisation des blancs en dernier, qui met tout sur une seule ligne.
legal_comparable_text() {
  decoder_espaces_insecables | decoder_echappements | replier_espaces_insecables | normaliser_blancs
}
