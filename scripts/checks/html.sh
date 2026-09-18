#!/usr/bin/env bash
# C10 et la moitié « sortie » de C5 (AD-8, AD-10, AD-20), sur le build de production.
#
#   C10  aucune balise <script> hors du bloc JSON-LD de l'accueil, aucun attribut on*, aucune iframe,
#        aucun formulaire, aucune ressource chargée depuis une autre origine (HTML et CSS) ;
#        le bloc JSON-LD, s'il existe, est un JSON valide de @type Person aux seules clés de FR-35
#   C5   aucune occurrence de « [TODO » dans les fichiers de texte publiés
#
# Les attributs se lisent par XPath avec « xmllint --html » (AD-10) : sur du HTML minifié, un grep
# sur des attributs serait faux dès qu'une valeur contient le motif cherché. Le parseur de libxml2
# signale les balises HTML5 comme invalides ; sa sortie d'erreur est donc écartée, et seule la sortie
# XPath est lue (AD-10). « grep » ne sert qu'aux chaînes : CSS et marqueurs.
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=html
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

public=${CHECK_PUBLIC_ROOT:-public}
[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
command -v xmllint > /dev/null 2>&1 \
  || checks_die "xmllint est introuvable (paquet libxml2-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1)."
command -v jq > /dev/null 2>&1 || checks_die "jq est introuvable."

# Hôte du site, lu dans la configuration : une URL absolue vers lui-même n'est pas une origine tierce.
# Les hreflang d'AD-2 sont justement des URL absolues vers le site (constaté sur la production).
site_host=${CHECK_SITE_HOST:-$(sed -n 's#^baseURL:[[:space:]]*["'"'"']\?https\?://\([^/"'"'"']*\).*#\1#p' config/_default/hugo.yaml | head -1)}
[[ -n $site_host ]] || checks_die "baseURL introuvable dans config/_default/hugo.yaml : impossible de distinguer une origine tierce."

# Relations qui **chargent** une ressource. « alternate », « canonical » ou « me » ne chargent rien :
# ce sont des déclarations, et les hreflang du site en sont (AD-2).
readonly loading_rels="stylesheet preload prefetch preconnect dns-prefetch icon apple-touch-icon manifest modulepreload"

# Vrai si l'URL désigne une autre origine que le site.
origine_tierce() { # $1 = valeur d'attribut
  # Schéma et hôte se comparent en minuscules : « HTTP:// » est un schéma valide, et sans cela une
  # ressource tierce passait en jouant sur la casse (constat de la quatrième revue de la PR n° 43).
  local url=${1#\"} lower host
  url=${url%\"}
  lower=${url,,}
  case $lower in
    http://*|https://*) host=${lower#*://}; host=${host%%[/?#]*} ;;
    //*) host=${lower#//}; host=${host%%[/?#]*} ;;
    *) return 1 ;;
  esac
  [[ $host != "${site_host,,}" ]]
}

# Clés autorisées dans le bloc JSON-LD (FR-35, AD-20). Rien d'autre : ni ville, ni téléphone, ni photo.
readonly jsonld_keys='["@context","@type","name","alternateName","jobTitle","address","url","sameAs"]'

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# Résultat d'une requête XPath sur un fichier HTML, sans la sortie d'erreur (AD-10 : le parseur de
# libxml2 signale les balises HTML5 comme invalides).
xpath() { # $1 = fichier, $2 = requête
  xmllint --html --xpath "$2" "$1" 2> /dev/null || true
}

# Valeurs d'un attribut, une par ligne. La version de libxml2 du poste en rend déjà une par ligne,
# mais d'autres les concatènent : la découpe ne dépend donc pas de la version (constat de la revue
# de la PR n° 43, rejoué : le défaut n'existait pas ici, la parade le rend impossible partout).
xpath_attributs() { # $1 = fichier, $2 = requête, $3 = nom de l'attribut
  xpath "$1" "$2" | grep -oE "$3=\"[^\"]*\"" | sed -E "s/^$3=\"(.*)\"$/\1/" || true
}

# Les accueils : index.html à la racine de chaque langue, jamais celui d'un sous-dossier.
est_accueil() { # $1 = chemin relatif à $public
  [[ $1 == index.html || $1 =~ ^[a-z]{2}/index\.html$ ]]
}

while IFS= read -r page; do
  relative=${page#"$public"/}

  # --- scripts : un seul type toléré, jamais de src (C10, AD-20) -------------------------------
  # La valeur est extraite, jamais découpée à l'indice : la sérialisation de xmllint varie d'une
  # version à l'autre (constat de la quatrième revue de la PR n° 43).
  while IFS= read -r type; do
    [[ -n $type ]] || continue
    [[ $type == "application/ld+json" ]] \
      || signaler "$relative" "C10 : balise <script> de type «$type» ; seul application/ld+json est toléré (AD-20)"
  done < <(xpath_attributs "$page" '//script[@type]/@type' type)
  count_scripts=$(xpath "$page" 'count(//script)'); count_scripts=${count_scripts:-0}
  count_typed=$(xpath "$page" 'count(//script[@type])'); count_typed=${count_typed:-0}
  [[ ${count_scripts%%.*} == "${count_typed%%.*}" ]] \
    || signaler "$relative" "C10 : balise <script> sans type ; seul un bloc application/ld+json est toléré (AD-20)"
  [[ $(xpath "$page" 'count(//script[@src])') == 0 ]] \
    || signaler "$relative" "C10 : balise <script src> : aucune page ne charge de JavaScript (NFR-12)"

  # --- gestionnaires d'événements, iframes, formulaires ----------------------------------------
  [[ $(xpath "$page" "count(//@*[starts-with(name(), 'on')])") == 0 ]] \
    || signaler "$relative" "C10 : attribut on… : aucune page n'exécute de script (NFR-12)"
  [[ $(xpath "$page" 'count(//iframe)') == 0 ]] \
    || signaler "$relative" "C10 : <iframe> : interdite (FR-14, une vidéo est un lien)"
  [[ $(xpath "$page" 'count(//form)') == 0 ]] \
    || signaler "$relative" "C10 : <form> : hors périmètre v1 (FR-17)"

  # --- ressources d'une autre origine : ce qui compte est l'attribut de chargement, pas la balise
  # Un lien <a href> vers un site tiers reste permis : il ne charge rien.
  for attribut in src poster data; do
    while IFS= read -r valeur; do
      [[ -n $valeur ]] || continue
      origine_tierce "$valeur" || continue
      signaler "$relative" "C10 : ressource d'une autre origine dans un attribut $attribut : $valeur"
    done < <(xpath_attributs "$page" "//*[@$attribut]/@$attribut" "$attribut")
  done
  # srcset porte plusieurs URL séparées par des virgules, chacune suivie d'un descripteur (« 2x ») :
  # la valeur entière est découpée, sinon une URL tierce placée après une URL locale passerait
  # (constat de la troisième revue de la PR n° 43).
  while IFS= read -r valeur; do
    while IFS= read -r candidat; do
      [[ -n $candidat ]] || continue
      origine_tierce "$candidat" || continue
      signaler "$relative" "C10 : ressource d'une autre origine dans un attribut srcset : $candidat"
    done < <(tr ',' '\n' <<< "$valeur" | awk 'NF { print $1 }')
  done < <(xpath_attributs "$page" "//*[@srcset]/@srcset" srcset)
  # Un rel peut en combiner plusieurs (« preload stylesheet ») : la comparaison porte sur le jeton,
  # jamais sur la chaîne entière (même constat).
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    rel_value=${ligne%%$'\t'*}
    href=${ligne#*$'\t'}
    [[ -n $href ]] || continue
    origine_tierce "$href" || continue
    for rel in $loading_rels; do
      [[ " ${rel_value,,} " == *" $rel "* ]] || continue
      signaler "$relative" "C10 : ressource « $rel » chargée depuis une autre origine : $href"
      break
    done
  done < <(xpath "$page" "//link[@rel][@href]" \
            | grep -oE '<link[^>]*>' \
            | while IFS= read -r balise; do
                r=$(grep -oE 'rel="[^"]*"' <<< "$balise" | head -1); r=${r#rel=\"}; r=${r%\"}
                h=$(grep -oE 'href="[^"]*"' <<< "$balise" | head -1); h=${h#href=\"}; h=${h%\"}
                printf '%s\t%s\n' "$r" "$h"
              done)

  # --- bloc JSON-LD : au plus un, sur l'accueil seulement ---------------------------------------
  # story 9.6 : la règle passera de « au plus un » à « exactement un » sur l'accueil de chaque langue.
  # Une sortie vide ne doit jamais casser l'évaluation arithmétique, quelle que soit la version de
  # libxml2 (parade de la troisième revue de la PR n° 43 ; le cas ne se produit pas ici).
  nombre=$(xpath "$page" 'count(//script[@type="application/ld+json"])')
  nombre=${nombre:-0}; nombre=${nombre%%.*}; nombre=${nombre:-0}
  if ((nombre > 0)); then
    if ! est_accueil "$relative"; then
      signaler "$relative" "C10 : bloc JSON-LD hors de l'accueil ; il n'appartient qu'à l'accueil (AD-20)"
    elif ((nombre > 1)); then
      signaler "$relative" "C10 : $nombre blocs JSON-LD ; au plus un (AD-20)"
    else
      contenu=$(xpath "$page" 'string(//script[@type="application/ld+json"])')
      if ! jq -e . > /dev/null 2>&1 <<< "$contenu"; then
        signaler "$relative" "C10 : le bloc JSON-LD n'est pas un JSON valide (AD-20)"
      else
        # Un JSON valide qui n'est pas un objet (un tableau, une chaîne) doit être signalé, pas faire
        # mourir le script : « jq » sort en code 5 sur une indexation impossible (constat de la revue
        # de la PR n° 43, rejoué : code 5 et arrêt du contrôle).
        if [[ $(jq -r 'type' <<< "$contenu") != object ]]; then
          signaler "$relative" "C10 : le bloc JSON-LD n'est pas un objet JSON ; un objet Person est attendu (FR-35)"
        else
          type_jsonld=$(jq -r '."@type" // ""' <<< "$contenu")
          [[ $type_jsonld == Person ]] \
            || signaler "$relative" "C10 : bloc JSON-LD de @type « $type_jsonld » ; Person attendu (FR-35)"
          while IFS= read -r cle; do
            [[ -n $cle ]] || continue
            signaler "$relative" "C10 : clé « $cle » dans le bloc JSON-LD ; seules les clés de FR-35 sont permises"
          done < <(jq -r --argjson permises "$jsonld_keys" 'keys[] | select(. as $k | $permises | index($k) | not)' <<< "$contenu")
        fi
      fi
    fi
  fi
done < <(find "$public" -type f -name '*.html' | LC_ALL=C sort)

# --- ressources tierces appelées depuis le CSS, que XPath ne voit pas -----------------------------
while IFS= read -r fichier; do
  relative=${fichier#"$public"/}
  # Chaque URL absolue citée par le CSS est confrontée à l'hôte du site : une feuille peut légitimement
  # pointer vers le site lui-même.
  while IFS= read -r cible; do
    [[ -n $cible ]] || continue
    origine_tierce "$cible" || continue
    signaler "$relative" "C10 : appel CSS vers une autre origine : $cible"
    # -i : les mots-clés CSS ne sont pas sensibles à la casse, « URL( » et « @IMPORT » en sont
    # (constat de la deuxième revue de la PR n° 43).
  done < <(grep -oiE "(url\(|@import[[:space:]]+(url\()?)[[:space:]]*['\"]?((https?:)?//[^)'\" ]+)" "$fichier" \
             | grep -oiE "(https?:)?//[^)'\" ]+" || true)
done < <(find "$public" -type f \( -name '*.html' -o -name '*.css' \) | LC_ALL=C sort)

# --- C5, moitié « sortie » : aucun marqueur dans les fichiers de texte publiés --------------------
while IFS= read -r fichier; do
  relative=${fichier#"$public"/}
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    signaler "$relative" "C5 : « [TODO » dans la sortie de production, ligne ${ligne%%:*}"
  done < <(grep -nF '[TODO' "$fichier" || true)
done < <(find "$public" -type f \( -name '*.html' -o -name '*.xml' -o -name '*.css' -o -name '*.txt' -o -name '*.json' \) | LC_ALL=C sort)

((fail == 0)) || exit 1
printf '%s: zéro script, aucune ressource tierce, aucun marqueur dans la production.\n' "$script_name"
