#!/usr/bin/env bash
# C13 — budget de poids et d'éléments (AD-8, NFR-5), sur le build de production, en octets non
# compressés. Un kilo-octet vaut 1 000 octets (décidé par Arnaud le 19/09/2026) : c'est l'unité des
# navigateurs et de PageSpeed, celle avec laquelle la mesure de mise en ligne sera comparée.
#
#   HTML d'une page          ≤  50 000 o
#   CSS de tout le site      ≤  20 000 o
#   chaque SVG               ≤  60 000 o
#   page complète            ≤ 200 000 o   le document, la CSS et les médias qu'il charge
#   ressources d'une page    ≤ 10          ce qu'elle charge en plus d'elle-même
#   éléments d'une page      ≤ 800
#   JavaScript et polices    aucun fichier dans public/, aucune référence depuis une page
#
# Une image déclinée en 1x et 2x ne compte qu'une fois dans le poids, par sa **variante la plus
# lourde** (décidé par Arnaud le 19/09/2026) : un navigateur n'en télécharge qu'une, et le budget
# doit refléter le pire cas réel. Chaque variante reste comptée comme ressource.
# Les PDF du CV sont des liens, hors budget (AD-21).
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=budget
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

public=${CHECK_PUBLIC_ROOT:-public}
[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
command -v xmllint > /dev/null 2>&1 \
  || checks_die "xmllint est introuvable (paquet libxml2-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1)."

readonly max_html=50000
readonly max_css_total=20000
readonly max_svg=60000
readonly max_page=200000
readonly max_ressources=10
readonly max_elements=800

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

attributs() { # $1 = fichier, $2 = requête, $3 = nom de l'attribut
  # Le XPath est lu **avant** le filtrage : un « exit » dans un élément de pipeline ne quitte que son
  # sous-shell, et un « || true » final transformerait l'anomalie en succès (constat de la troisième
  # revue de la PR n° 47). Le code de checks_xpath est donc propagé tel quel.
  local brut rc=0
  brut=$(checks_xpath "$1" "$2") || rc=$?
  ((rc == 0)) || return "$rc"
  { checks_grep -oE "$3=\"[^\"]*\"" <<< "$brut" || true; } | sed -E "s/^$3=\"(.*)\"$/\1/"
}

poids() { # $1 = fichier ; 0 si absent
  [[ -f $1 ]] && stat -c %s "$1" || echo 0
}

# Chemin d'une ressource référencée, relatif à $public ; vide si elle n'est pas servie par le site.
ressource_locale() { # $1 = page (relative), $2 = URL
  local page=$1 url=$2 dossier
  url=${url%%\?*}; url=${url%%#*}
  [[ -n $url ]] || return 1
  case $url in
    http://*|https://*|//*|data:*|mailto:*|tel:*) return 1 ;;
    /*) printf '%s' "${url#/}" ;;
    *) dossier=$(dirname "$page"); [[ $dossier != . ]] || dossier=""; printf '%s' "${dossier:+$dossier/}$url" ;;
  esac
}

# --- fichiers interdits partout dans la sortie ----------------------------------------------------
liste_1=$(checks_find "$public" -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.eot' \) | LC_ALL=C sort) || exit $?
while IFS= read -r fichier; do
  [[ -n $fichier ]] || continue
  signaler "${fichier#"$public"/}" "C13 : fichier JavaScript ou de police dans la sortie ; le site n'en charge aucun (NFR-12, AD-8)"
done <<< "$liste_1"

# --- CSS de tout le site --------------------------------------------------------------------------
css_total=0
liste_2=$(checks_find "$public" -type f -name '*.css' | LC_ALL=C sort) || exit $?
while IFS= read -r fichier; do
  [[ -n $fichier ]] || continue
  css_total=$((css_total + $(poids "$fichier")))
done <<< "$liste_2"
((css_total <= max_css_total)) \
  || signaler "public/**.css" "C13 : $css_total octets de CSS pour tout le site ; $max_css_total au plus (AD-8)"

# --- chaque SVG -----------------------------------------------------------------------------------
liste_3=$(checks_find "$public" -type f -name '*.svg' | LC_ALL=C sort) || exit $?
while IFS= read -r fichier; do
  [[ -n $fichier ]] || continue
  taille=$(poids "$fichier")
  ((taille <= max_svg)) || signaler "${fichier#"$public"/}" "C13 : SVG de $taille octets ; $max_svg au plus (AD-8)"
done <<< "$liste_3"

# --- page par page ---------------------------------------------------------------------------------
liste_4=$(checks_find "$public" -type f -name '*.html' | LC_ALL=C sort) || exit $?
while IFS= read -r page; do
  relative=${page#"$public"/}

  taille_html=$(poids "$page")
  ((taille_html <= max_html)) \
    || signaler "$relative" "C13 : HTML de $taille_html octets ; $max_html au plus (AD-8)"

  elements=$(checks_xpath "$page" 'count(//*)'); elements=${elements:-0}; elements=${elements%%.*}
  ((elements <= max_elements)) \
    || signaler "$relative" "C13 : $elements éléments HTML ; $max_elements au plus (AD-8)"

  # Ressources chargées : feuilles de style, images, schémas. Un lien <a> ne charge rien.
  ressources=()
  urls_chargees=$({
    attributs "$page" "//link[@rel='stylesheet']/@href" href
    attributs "$page" '//img/@src' src
    attributs "$page" '//*[@poster]/@poster' poster
    attributs "$page" '//img/@srcset' srcset | tr ',' '\n' | awk 'NF { print $1 }'
    # <picture><source srcset> : ces images-là chargent aussi (constat de la cinquième revue
    # de la PR n° 47).
    attributs "$page" '//source/@src' src
    attributs "$page" '//source/@srcset' srcset | tr ',' '\n' | awk 'NF { print $1 }'
  }) || exit $?
  while IFS= read -r url; do
    [[ -n $url ]] || continue
    cible=$(ressource_locale "$relative" "$url") || continue
    ressources+=("$cible")
  done <<< "$urls_chargees"

  # Une image déclinée ne pèse qu'une fois, par sa variante la plus lourde : les fichiers sont
  # regroupés par leur nom sans le suffixe de densité (« portrait@2x.webp » et « portrait.webp »).
  declare -A poids_par_media=()
  for cible in "${ressources[@]:-}"; do
    [[ -n $cible ]] || continue
    if [[ ! -f $public/$cible ]]; then
      signaler "$relative" "C13 : ressource chargée mais absente de la sortie : $cible"
      continue
    fi
    base=$(sed -E 's/@[0-9]+x(\.[a-z0-9]+)$/\1/' <<< "$cible")
    taille=$(poids "$public/$cible")
    ((taille <= ${poids_par_media[$base]:-0})) || poids_par_media[$base]=$taille
  done

  # Une même URL citée deux fois n'est qu'une requête : le décompte porte sur les ressources
  # distinctes (constat de la sixième revue de la PR n° 47).
  nombre=0
  if ((${#ressources[@]} > 0)) && [[ ${ressources[0]:-} != "" ]]; then
    nombre=$(printf '%s\n' "${ressources[@]}" | LC_ALL=C sort -u | wc -l)
  fi
  ((nombre <= max_ressources)) \
    || signaler "$relative" "C13 : $nombre ressources chargées ; $max_ressources au plus (AD-8)"

  total=$taille_html
  for base in "${!poids_par_media[@]}"; do total=$((total + poids_par_media[$base])); done
  ((total <= max_page)) \
    || signaler "$relative" "C13 : page complète de $total octets ; $max_page au plus (AD-8)"
  unset poids_par_media
done <<< "$liste_4"

((fail == 0)) || exit 1
printf '%s: poids et nombre d'"'"'éléments dans les budgets d'"'"'AD-8.\n' "$script_name"
