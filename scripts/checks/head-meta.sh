#!/usr/bin/env bash
# C26 (AD-25, FR-40, story 9.8) : description et aperçu de partage de chaque page, sur la sortie de
# production.
#
# Le partial layouts/_partials/head-meta.html arrête déjà le build quand une description manque.
# Ce contrôle constate le **résultat**, comme C23 le fait pour l'adresse légale : un gabarit qui
# écrirait deux fois la balise, une valeur d'un autre champ, une URL relative ou une image d'aperçu
# passerait le build sans rien dire. Sur chaque page HTML de « public/ » :
#
#   description          exactement une <meta name="description">, non blanche, sans « [TODO »
#   og:description       exactement une, égale à la description
#   og:title             exactement une, égale au texte du <title>
#   og:type              exactement une : « website » sur l'accueil de chaque langue, « article »
#                        ailleurs (404 comprises)
#   og:url               exactement une, absolue en https://, égale à l'URL de la page dans le build :
#                        baseURL + son chemin (« index.html » final retiré)
#   og:locale            exactement une, cohérente avec <html lang> : fr → fr_FR, en → en_US
#   og:locale:alternate  la locale de chaque traduction de la page, une fois, et rien d'autre : elle
#                        est présente si et seulement si une traduction existe
#   og:image, og:image:* aucune (arbitrage d'Arnaud du 04/10/2026 : aperçu sans image)
#
# **D'où il sait qu'une traduction existe** : des liens « hreflang » du <head>, que baseof.html écrit
# à partir des traductions de la page, indépendamment du partial (AD-2), et dont C11 exige la
# présence. Le contrôle ne relit donc pas sa propre source.
#
# **Les locales sont écrites ici une seconde fois**, en plus du partial, et c'est voulu : un contrôle
# qui lirait la table du gabarit hériterait de sa faute (point 15 d'AGENTS.md). Ce sont les deux
# valeurs qu'AD-25 fixe ; une langue ajoutée au site sans la sienne est signalée.
#
# Une balise compte **quelle que soit sa casse et son attribut** : « NAME=Description », ou une
# balise Open Graph posée en « name= » au lieu de « property= », sont lues par les moteurs et les
# aperçus — un doublon ainsi écrit doit se voir. Les balises se lisent par XPath (« xmllint
# --html »), jamais par grep : sur du HTML minifié, un attribut se repère mal à la main (AD-10).
#
# Production seule : le rendu de travail porte des brouillons, dont un « summary » en « [TODO: … ] »
# est légitime (docs/format-cas.md).
#
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=head-meta
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

public=${CHECK_PUBLIC_ROOT:-public}
[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
command -v xmllint > /dev/null 2>&1 \
  || checks_die "xmllint est introuvable (paquet libxml2-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1)."

# baseURL, lue dans la configuration comme html.sh lit l'hôte ; CHECK_BASE_URL ne sert qu'aux tests.
config=config/_default/hugo.yaml
base_url=${CHECK_BASE_URL:-}
if [[ -z $base_url ]]; then
  [[ -r $config ]] || checks_die "$config illisible : baseURL introuvable, og:url ne peut pas être vérifiée."
  base_url=$(sed -n 's#^baseURL:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'[:space:]]*\).*#\1#p' "$config" | head -1) \
    || checks_die "lecture de baseURL impossible dans $config."
fi
[[ -n $base_url ]] || checks_die "baseURL introuvable : og:url ne peut pas être vérifiée."
# Une baseURL en http:// rendrait des og:url fausses sur toutes les pages à la fois : c'est la
# configuration qu'il faut corriger, et le contrôle le dit une fois plutôt que page par page.
[[ $base_url == https://* ]] || checks_die "baseURL « $base_url » n'est pas en https:// : AD-25 veut un og:url absolu en https."
base_url=${base_url%/}/
readonly base_url

declare -A locales=([fr]=fr_FR [en]=en_US)
readonly -A locales

readonly majuscules=ABCDEFGHIJKLMNOPQRSTUVWXYZ minuscules=abcdefghijklmnopqrstuvwxyz

# Sélecteur XPath des <meta> dont l'attribut $1 vaut $2, casse et blancs ignorés.
meta_attr() { # $1 = attribut, $2 = valeur en minuscules
  printf "translate(normalize-space(@%s),'%s','%s')='%s'" "$1" "$majuscules" "$minuscules" "$2"
}
# Une balise Open Graph, qu'elle soit posée en « property= » ou en « name= ».
og() { # $1 = propriété en minuscules
  printf '//meta[%s or %s]' "$(meta_attr property "$1")" "$(meta_attr name "$1")"
}

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# Lit une requête XPath sur la page courante dans une variable. L'anomalie de checks_xpath est
# **propagée** : lancée dans une substitution, elle ne quitterait que le sous-shell, et une valeur
# vide passerait pour « balise absente » sur un fichier illisible.
lire() { # $1 = variable, $2 = requête
  local -n lire_destination=$1
  local lire_resultat
  lire_resultat=$(checks_xpath "$fichier" "$2") || exit $?
  # shellcheck disable=SC2034 # variable de l'appelant, remplie par référence
  lire_destination=$lire_resultat
}

compter() { # $1 = variable, $2 = requête sans « count( ) »
  local -n compter_destination=$1
  local compter_brut
  lire compter_brut "count($2)"
  compter_destination=${compter_brut%%.*}
  [[ $compter_destination =~ ^[0-9]+$ ]] || checks_die "$page : décompte XPath illisible (« $compter_brut »)."
}

# Une URL dont les octets non ASCII sont encodés en %XX désigne le même fichier que le chemin brut
# que « find » rend : la comparaison se fait sur la forme décodée.
decoder_url() { # $1 = URL
  local url=$1
  [[ $url == *%* ]] || { printf '%s' "$url"; return 0; }
  printf '%b' "${url//%/\\x}"
}

pages=$(checks_find "$public" -type f -name '*.html' -printf '%P\n' | LC_ALL=C sort) || exit $?
# Une liste vide ferait sortir le contrôle en « conforme » sans avoir rien lu (rétrospective de
# l'epic 3, A3).
[[ -n $pages ]] || checks_die "aucune page HTML sous $public : le rendu est vide, rien ne serait contrôlé."

selecteur_description="//meta[$(meta_attr name description)]"
readonly selecteur_description

# Remplies par référence (lire, compter) : déclarées ici, shellcheck ne voyant pas l'affectation.
n=0 description="" valeur="" titre="" lang=""

while IFS= read -r page; do
  [[ -n $page ]] || continue
  fichier=$public/$page

  # --- description ---------------------------------------------------------------------------------
  compter n "$selecteur_description"
  lire description "string(($selecteur_description)[1]/@content)"
  if ((n != 1)); then
    signaler "$page" "C26 : $n balise(s) <meta name=\"description\">, une seule attendue (AD-25)"
  fi
  if ((n > 0)); then
    if [[ -z ${description//[[:space:]]/} ]]; then
      signaler "$page" "C26 : <meta name=\"description\"> vide (AD-25)"
    elif [[ $description == *'[TODO'* ]]; then
      signaler "$page" "C26 : la description porte un marqueur [TODO : une page publiée n'en a aucun (FR-40)"
    fi
  fi

  # --- og:description, égale à la description -----------------------------------------------------
  compter n "$(og og:description)"
  lire valeur "string(($(og og:description))[1]/@content)"
  if ((n != 1)); then
    signaler "$page" "C26 : $n balise(s) og:description, une seule attendue (AD-25)"
  elif [[ $valeur != "$description" ]]; then
    signaler "$page" "C26 : og:description diffère de la <meta name=\"description\"> (AD-25)"
  fi

  # --- og:title, égal au <title> -----------------------------------------------------------------
  compter n "$(og og:title)"
  lire valeur "string(($(og og:title))[1]/@content)"
  lire titre 'string((//title)[1])'
  if ((n != 1)); then
    signaler "$page" "C26 : $n balise(s) og:title, une seule attendue (AD-25)"
  elif [[ -z ${valeur//[[:space:]]/} ]]; then
    signaler "$page" "C26 : og:title vide (AD-25)"
  elif [[ $valeur != "$titre" ]]; then
    signaler "$page" "C26 : og:title « $valeur » diffère du <title> « $titre » (AD-25)"
  fi

  # --- og:type ---------------------------------------------------------------------------------------
  attendu=article
  ! checks_est_accueil "$page" || attendu=website
  compter n "$(og og:type)"
  lire valeur "string(($(og og:type))[1]/@content)"
  if ((n != 1)); then
    signaler "$page" "C26 : $n balise(s) og:type, une seule attendue (AD-25)"
  elif [[ $valeur != "$attendu" ]]; then
    signaler "$page" "C26 : og:type « $valeur », « $attendu » attendu sur cette page (AD-25)"
  fi

  # --- og:url ----------------------------------------------------------------------------------------
  chemin=$page
  [[ $chemin != index.html && $chemin != */index.html ]] || chemin=${chemin%index.html}
  attendu=$base_url$chemin
  compter n "$(og og:url)"
  lire valeur "string(($(og og:url))[1]/@content)"
  if ((n != 1)); then
    signaler "$page" "C26 : $n balise(s) og:url, une seule attendue (AD-25)"
  elif [[ $valeur != https://* ]]; then
    signaler "$page" "C26 : og:url « $valeur » n'est pas une URL absolue en https:// (AD-25)"
  elif [[ $(decoder_url "$valeur") != "$attendu" ]]; then
    signaler "$page" "C26 : og:url « $valeur », « $attendu » attendue pour cette page (AD-25)"
  fi

  # --- og:locale, cohérente avec <html lang> --------------------------------------------------------
  lire lang 'string(/html/@lang)'
  locale=""
  [[ -z $lang ]] || locale=${locales[$lang]:-}
  compter n "$(og og:locale)"
  lire valeur "string(($(og og:locale))[1]/@content)"
  if ((n != 1)); then
    signaler "$page" "C26 : $n balise(s) og:locale, une seule attendue (AD-25)"
  elif [[ -z $locale ]]; then
    signaler "$page" "C26 : <html lang=\"$lang\"> sans locale Open Graph connue (fr → fr_FR, en → en_US, AD-25)"
  elif [[ $valeur != "$locale" ]]; then
    signaler "$page" "C26 : og:locale « $valeur », « $locale » attendue pour <html lang=\"$lang\"> (AD-25)"
  fi

  # --- og:locale:alternate, présente si et seulement si une traduction existe -----------------------
  # Les langues des traductions : les hreflang du <head>, sauf x-default et la langue de la page.
  hreflangs=$(checks_attributes "$fichier" "//head/link[contains(concat(' ',normalize-space(@rel),' '),' alternate ')][@hreflang]" hreflang) \
    || exit $?
  attendues=()
  while IFS= read -r autre; do
    [[ -n $autre && $autre != x-default && $autre != "$lang" ]] || continue
    if [[ -z ${locales[$autre]:-} ]]; then
      signaler "$page" "C26 : traduction en « $autre » sans locale Open Graph connue (AD-25)"
      continue
    fi
    attendues+=("${locales[$autre]}")
  done <<< "$hreflangs"
  selecteur_alternates=$(og og:locale:alternate)
  alternates=$(checks_attributes "$fichier" "$selecteur_alternates" content) || exit $?
  attendues_triees=$(printf '%s\n' ${attendues[@]+"${attendues[@]}"} | LC_ALL=C sort -u | sed '/^$/d')
  trouvees_triees=$(printf '%s\n' "$alternates" | LC_ALL=C sort | sed '/^$/d')
  if [[ $trouvees_triees != "$attendues_triees" ]]; then
    if [[ -z $attendues_triees ]]; then
      signaler "$page" "C26 : og:locale:alternate présente alors que la page n'a pas de traduction (AD-25)"
    elif [[ -z $trouvees_triees ]]; then
      signaler "$page" "C26 : og:locale:alternate absente alors que la page a une traduction ($(tr '\n' ' ' <<< "$attendues_triees" | sed 's/ $//')) (AD-25)"
    else
      signaler "$page" "C26 : og:locale:alternate « $(tr '\n' ' ' <<< "$trouvees_triees" | sed 's/ $//') », « $(tr '\n' ' ' <<< "$attendues_triees" | sed 's/ $//') » attendue(s) d'après les traductions de la page (AD-25)"
    fi
  fi

  # --- aucune image d'aperçu -------------------------------------------------------------------------
  compter n "//meta[starts-with(translate(normalize-space(@property),'$majuscules','$minuscules'),'og:image') or starts-with(translate(normalize-space(@name),'$majuscules','$minuscules'),'og:image')]"
  ((n == 0)) || signaler "$page" "C26 : $n balise(s) og:image : l'aperçu de partage est sans image (AD-25)"
done <<< "$pages"

((fail == 0)) || exit 1
printf '%s: chaque page porte sa description et son aperçu de partage (C26).\n' "$script_name"
