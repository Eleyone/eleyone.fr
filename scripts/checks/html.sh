#!/usr/bin/env bash
# C10 et la moitié « sortie » de C5 (AD-8, AD-10, AD-20).
#
# C10 et C11 lisent **les deux rendus**, travail et production (arbitrage d'Arnaud, 22/09/2026).
# Tant qu'un cas est en brouillon, la production ne le contient pas : avec les six cas en brouillon,
# elle ne portait que les deux accueils, et ces contrôles n'avaient jamais vu une page de cas — pas
# même celle de la story 6.1. C5 reste en production seule, puisqu'un « [TODO » est légitime dans un
# brouillon (c'est même ce que le format des cas prescrit).
#
#   C10  aucune balise <script> hors du bloc JSON-LD de l'accueil, aucun attribut on*, aucune iframe,
#        aucun formulaire, aucune ressource chargée depuis une autre origine (HTML et CSS) ;
#        le bloc JSON-LD, s'il existe, est un JSON valide de @type Person aux seules clés de FR-35
#   C5   aucune occurrence de « [TODO » dans les fichiers de texte publiés (production seule)
#   C11  accessibilité automatisable (AD-17) : langue de la page, titre, plan des titres,
#        identifiants uniques, images décrites et dimensionnées, liens nommés, hreflang,
#        aucun tabindex positif
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
travail=${CHECK_WORK_ROOT:-build/work}
# Les racines que C10 et C11 parcourent. Le rendu de travail n'est ajouté que s'il existe : un
# contrôle lancé sur une sortie seule (essais, image de CI) reste possible.
#
# Un fichier présent dans les deux rendus est lu deux fois. C'est voulu : dédupliquer sur le chemin
# relatif écarterait la copie de travail d'une page qui existe aussi en production **avec un
# contenu différent** — c'est exactement le cas d'un cas passé de brouillon à publié, ou d'une page
# qui porte le marqueur « Brouillon » d'un seul côté. Le coût est une seconde lecture de la feuille
# de style et des deux accueils ; le risque, celui de ne pas voir un défaut propre à un rendu.
racines=("$public")
[[ ! -d $travail || $travail -ef $public ]] || racines+=("$travail")
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

# Ligne d'identité, lue dans le manifeste du rendu de travail plutôt qu'écrite en dur : elle vient du
# front matter de l'accueil (AD-19). Le rendu de travail précède les contrôles dans check.sh.
identity=""
if manifest=$(checks_manifests "${CHECK_WORK_ROOT:-build/work}" 2> /dev/null | head -1) && [[ -n $manifest ]]; then
  identity=$(jq -r 'first(.files[] | select(.role == "home") | .front_matter.identity // "") // ""' "$manifest") \
    || checks_die "lecture de la ligne d'identité impossible dans $manifest."
fi
[[ -n $identity ]] || checks_die "ligne d'identité introuvable dans le manifeste : lancer scripts/build.sh work."

# Résultat d'une requête XPath sur un fichier HTML, sans la sortie d'erreur (AD-10 : le parseur de
# libxml2 signale les balises HTML5 comme invalides).
# Valeurs d'un attribut, une par ligne. La version de libxml2 du poste en rend déjà une par ligne,
# mais d'autres les concatènent : la découpe ne dépend donc pas de la version (constat de la revue
# de la PR n° 43, rejoué : le défaut n'existait pas ici, la parade le rend impossible partout).
# Les accueils : index.html à la racine de chaque langue, jamais celui d'un sous-dossier.
est_accueil() { # $1 = chemin relatif à $public
  [[ $1 == index.html || $1 =~ ^[a-z]{2}/index\.html$ ]]
}

liste_9=$(checks_find "${racines[@]}" -type f -name '*.html' | LC_ALL=C sort) || exit $?
# Une liste vide ferait sortir ce contrôle en « conforme » sans avoir rien lu : un CHECK_PUBLIC_ROOT
# erroné, ou une sortie de build vide, passeraient pour un succès (rétrospective de l'epic 3, A3).
[[ -n $liste_9 ]] || checks_die "aucune page HTML dans ${racines[*]} : rien à contrôler."
while IFS= read -r page; do
  relative=${page#"$public"/}
  relative=${relative#"$travail"/}

  # --- scripts : un seul type toléré, jamais de src (C10, AD-20) -------------------------------
  # La valeur est extraite, jamais découpée à l'indice : la sérialisation de xmllint varie d'une
  # version à l'autre (constat de la quatrième revue de la PR n° 43).
  liste_1=$(checks_attributes "$page" '//script[@type]/@type' type) || exit $?
  while IFS= read -r type; do
    [[ -n $type ]] || continue
    [[ $type == "application/ld+json" ]] \
      || signaler "$relative" "C10 : balise <script> de type «$type» ; seul application/ld+json est toléré (AD-20)"
  done <<< "$liste_1"
  count_scripts=$(checks_xpath "$page" 'count(//script)'); count_scripts=${count_scripts:-0}
  count_typed=$(checks_xpath "$page" 'count(//script[@type])'); count_typed=${count_typed:-0}
  [[ ${count_scripts%%.*} == "${count_typed%%.*}" ]] \
    || signaler "$relative" "C10 : balise <script> sans type ; seul un bloc application/ld+json est toléré (AD-20)"
  [[ $(checks_xpath "$page" 'count(//script[@src])') == 0 ]] \
    || signaler "$relative" "C10 : balise <script src> : aucune page ne charge de JavaScript (NFR-12)"

  # --- gestionnaires d'événements, iframes, formulaires ----------------------------------------
  [[ $(checks_xpath "$page" "count(//@*[starts-with(name(), 'on')])") == 0 ]] \
    || signaler "$relative" "C10 : attribut on… : aucune page n'exécute de script (NFR-12)"
  [[ $(checks_xpath "$page" 'count(//iframe)') == 0 ]] \
    || signaler "$relative" "C10 : <iframe> : interdite (FR-14, une vidéo est un lien)"
  [[ $(checks_xpath "$page" 'count(//form)') == 0 ]] \
    || signaler "$relative" "C10 : <form> : hors périmètre v1 (FR-17)"

  # --- ressources d'une autre origine : ce qui compte est l'attribut de chargement, pas la balise
  # Un lien <a href> vers un site tiers reste permis : il ne charge rien.
  for attribut in src poster data; do
    liste_2=$(checks_attributes "$page" "//*[@$attribut]/@$attribut" "$attribut") || exit $?
    while IFS= read -r valeur; do
      [[ -n $valeur ]] || continue
      origine_tierce "$valeur" || continue
      signaler "$relative" "C10 : ressource d'une autre origine dans un attribut $attribut : $valeur"
    done <<< "$liste_2"
  done
  # srcset porte plusieurs URL séparées par des virgules, chacune suivie d'un descripteur (« 2x ») :
  # la valeur entière est découpée, sinon une URL tierce placée après une URL locale passerait
  # (constat de la troisième revue de la PR n° 43).
  liste_4=$(checks_attributes "$page" "//*[@srcset]/@srcset" srcset) || exit $?
  while IFS= read -r valeur; do
    liste_3=$(tr ',' '\n' <<< "$valeur" | awk 'NF { print $1 }') || exit $?
    while IFS= read -r candidat; do
      [[ -n $candidat ]] || continue
      origine_tierce "$candidat" || continue
      signaler "$relative" "C10 : ressource d'une autre origine dans un attribut srcset : $candidat"
    done <<< "$liste_3"
  done <<< "$liste_4"
  # Un rel peut en combiner plusieurs (« preload stylesheet ») : la comparaison porte sur le jeton,
  # jamais sur la chaîne entière (même constat).
  # Chaque lecture passe par une variable, jamais par un pipeline : un « exit » en tête de pipeline
  # ne quitte que son sous-shell (constat de la première revue de plage, 21/09/2026).
  brut_liens=$(checks_xpath "$page" "//link[@rel][@href]") || exit $?
  shell_grep_into balises_link -oE '<link[^>]*>' <<< "$brut_liens"
  liens_declares=""
  while IFS= read -r balise; do
    [[ -n $balise ]] || continue
    shell_grep_into r -oE 'rel="[^"]*"' <<< "$balise"
    shell_grep_into h -oE 'href="[^"]*"' <<< "$balise"
    r=${r%%$'\n'*}; r=${r#rel=\"}; r=${r%\"}
    h=${h%%$'\n'*}; h=${h#href=\"}; h=${h%\"}
    liens_declares+="$r"$'\t'"$h"$'\n'
  done <<< "$balises_link"
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
  done <<< "$liens_declares"

  # --- bloc JSON-LD : au plus un, sur l'accueil seulement ---------------------------------------
  # story 9.6 : la règle passera de « au plus un » à « exactement un » sur l'accueil de chaque langue.
  # Une sortie vide ne doit jamais casser l'évaluation arithmétique, quelle que soit la version de
  # libxml2 (parade de la troisième revue de la PR n° 43 ; le cas ne se produit pas ici).
  nombre=$(checks_xpath "$page" 'count(//script[@type="application/ld+json"])')
  nombre=${nombre:-0}; nombre=${nombre%%.*}; nombre=${nombre:-0}
  if ((nombre > 0)); then
    if ! est_accueil "$relative"; then
      signaler "$relative" "C10 : bloc JSON-LD hors de l'accueil ; il n'appartient qu'à l'accueil (AD-20)"
    elif ((nombre > 1)); then
      signaler "$relative" "C10 : $nombre blocs JSON-LD ; au plus un (AD-20)"
    else
      contenu=$(checks_xpath "$page" 'string(//script[@type="application/ld+json"])')
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
          liste_5=$(jq -r --argjson permises "$jsonld_keys" 'keys[] | select(. as $k | $permises | index($k) | not)' <<< "$contenu") || exit $?
          while IFS= read -r cle; do
            [[ -n $cle ]] || continue
            signaler "$relative" "C10 : clé « $cle » dans le bloc JSON-LD ; seules les clés de FR-35 sont permises"
          done <<< "$liste_5"
        fi
      fi
    fi
  fi
  # --- C11 : accessibilité automatisable (AD-17) ------------------------------------------------
  lang=$(checks_attributes "$page" '/html/@lang' lang | head -1)
  [[ -n $lang ]] || signaler "$relative" "C11 : <html lang> absent : la langue de la page n'est pas déclarée (3.1.1)"

  titre=$(checks_xpath "$page" 'string(//title)')
  if [[ -z ${titre// /} ]]; then
    signaler "$relative" "C11 : <title> vide (2.4.2)"
  elif ! est_accueil "$relative" && [[ $titre != *"$identity"* ]]; then
    # L'accueil fait exception : son titre porte déjà le nom (AD-2, story 2.2).
    signaler "$relative" "C11 : <title> « $titre » sans la ligne d'identité « $identity » (AD-2)"
  fi
  # Hugo donne son propre titre aux pages qu'aucun fichier de contenu ne porte — « 404 Page not
  # found », en anglais quelle que soit la langue de la page. Le <h1> et le corps de la 404
  # passaient par i18n/, pas son <title> : la page française s'annonçait en anglais dans l'onglet
  # et dans l'historique du navigateur, et rien ne le voyait (constat C1 de la rétrospective de
  # l'epic 4, 21/09/2026). Le libellé est écrit en toutes lettres : c'est le seul titre que le
  # générateur fournit sur ce site, et une règle plus large se tromperait de cible.
  [[ $titre != *"404 Page not found"* ]] \
    || signaler "$relative" "C11 : <title> « $titre » est celui du générateur, non traduit (3.1.1)"

  h1=$(checks_xpath "$page" 'count(//h1)'); h1=${h1:-0}; h1=${h1%%.*}
  ((h1 == 1)) || signaler "$relative" "C11 : $h1 balise(s) <h1> ; exactement une est attendue (1.3.1)"

  # Plan des titres : aucun saut de niveau vers le bas (h2 puis h4).
  precedent=0
  brut_titres=$(checks_xpath "$page" '//h1|//h2|//h3|//h4|//h5|//h6') || exit $?
  shell_grep_into balises_titres -oE '<h[1-6]' <<< "$brut_titres"
  liste_6=$(tr -d '<h' <<< "$balises_titres")
  while IFS= read -r niveau; do
    [[ -n $niveau ]] || continue
    if ((precedent > 0 && niveau > precedent + 1)); then
      signaler "$relative" "C11 : saut de niveau de titre, h$precedent suivi de h$niveau (1.3.1)"
    fi
    precedent=$niveau
  # « || true » : sans titre, grep rend 1, et l'échec passerait en silence dans la substitution
  # de processus (constat de la deuxième revue de la PR n° 45 ; pièges connus de shell-scripts.md).
  done <<< "$liste_6"

  liste_7=$(checks_attributes "$page" '//*[@id]/@id' id | LC_ALL=C sort | uniq -d) || exit $?
  while IFS= read -r identifiant; do
    [[ -n $identifiant ]] || continue
    signaler "$relative" "C11 : identifiant « $identifiant » en double (4.1.1)"
  done <<< "$liste_7"

  images=$(checks_xpath "$page" 'count(//img)'); images=${images:-0}; images=${images%%.*}
  if ((images > 0)); then
    sans_alt=$(checks_xpath "$page" 'count(//img[not(@alt) or normalize-space(@alt) = ""])'); sans_alt=${sans_alt%%.*}
    ((${sans_alt:-0} == 0)) || signaler "$relative" "C11 : ${sans_alt} image(s) sans alternative textuelle (1.1.1)"
    sans_dimensions=$(checks_xpath "$page" 'count(//img[not(@width) or not(@height)])'); sans_dimensions=${sans_dimensions%%.*}
    ((${sans_dimensions:-0} == 0)) \
      || signaler "$relative" "C11 : ${sans_dimensions} image(s) sans width ni height : la page se décale au chargement (CLS, AD-17)"
  fi

  # Nom accessible d'un lien : du texte, un aria-label, un title, ou une image au alt non vide.
  # Un aria-label ou un title **vide** ne nomme rien : l'attribut doit porter du texte
  # (constat de la revue de la PR n° 45).
  liens_muets=$(checks_xpath "$page" "count(//a[@href][normalize-space(string(.)) = ''][not(@aria-label) or normalize-space(@aria-label) = ''][not(@title) or normalize-space(@title) = ''][not(.//img[@alt][normalize-space(@alt) != ''])])")
  liens_muets=${liens_muets%%.*}
  ((${liens_muets:-0} == 0)) || signaler "$relative" "C11 : ${liens_muets} lien(s) sans nom accessible (2.4.4)"

  hreflangs=$(checks_xpath "$page" "count(//link[@rel='alternate'][@hreflang])"); hreflangs=${hreflangs%%.*}
  ((${hreflangs:-0} > 0)) || signaler "$relative" "C11 : aucun lien hreflang : la page ne déclare pas ses traductions (AD-2)"

  # « +1 », « 01 » et «  1  » sont des tabindex positifs valides en HTML5 : la valeur est normalisée
  # avant comparaison (constat de la revue de la PR n° 45).
  liste_8=$(checks_attributes "$page" '//*[@tabindex]/@tabindex' tabindex) || exit $?
  while IFS= read -r valeur; do
    [[ -n $valeur ]] || continue
    normalisee=${valeur//[[:space:]]/}
    normalisee=${normalisee#+}
    normalisee=$(sed -E 's/^0+([0-9])/\1/' <<< "$normalisee")
    [[ $normalisee =~ ^[1-9][0-9]*$ ]] || continue
    signaler "$relative" "C11 : tabindex positif « $valeur » : l'ordre de tabulation suit l'ordre du DOM (2.4.3)"
  done <<< "$liste_8"
done <<< "$liste_9"

# --- ressources tierces appelées depuis le CSS, que XPath ne voit pas -----------------------------
liste_10=$(checks_find "${racines[@]}" -type f \( -name '*.html' -o -name '*.css' \) | LC_ALL=C sort) || exit $?
while IFS= read -r fichier; do
  relative=${fichier#"$public"/}
  relative=${relative#"$travail"/}
  # Chaque URL absolue citée par le CSS est confrontée à l'hôte du site : une feuille peut légitimement
  # pointer vers le site lui-même.
  # Le fichier est lu d'abord, avec son code : « || true » sur le pipeline entier masquerait un
  # fichier illisible (constat de la quatrième revue de la PR n° 47).
  rc_css=0
  brut_css=$(shell_grep -oiE "(url\(|@import[[:space:]]+(url\()?)[[:space:]]*['\"]?((https?:)?//[^)'\" ]+)" "$fichier") || rc_css=$?
  ((rc_css <= 1)) || exit "$rc_css"
  shell_grep_into appels_css -oiE "(https?:)?//[^)'\" ]+" <<< "$brut_css"
  while IFS= read -r cible; do
    [[ -n $cible ]] || continue
    origine_tierce "$cible" || continue
    signaler "$relative" "C10 : appel CSS vers une autre origine : $cible"
    # -i : les mots-clés CSS ne sont pas sensibles à la casse, « URL( » et « @IMPORT » en sont
    # (constat de la deuxième revue de la PR n° 43).
  done <<< "$appels_css"
done <<< "$liste_10"

# --- C5, moitié « sortie » : aucun marqueur dans les fichiers de texte publiés --------------------
liste_11=$(checks_find "$public" -type f \( -name '*.html' -o -name '*.xml' -o -name '*.css' -o -name '*.txt' -o -name '*.json' \) | LC_ALL=C sort) || exit $?
while IFS= read -r fichier; do
  relative=${fichier#"$public"/}
  rc_todo=0
  marqueurs=$(shell_grep -nF '[TODO' "$fichier") || rc_todo=$?
  ((rc_todo <= 1)) || exit "$rc_todo"
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    signaler "$relative" "C5 : « [TODO » dans la sortie de production, ligne ${ligne%%:*}"
  done <<< "$marqueurs"
done <<< "$liste_11"

((fail == 0)) || exit 1
printf '%s: zéro script, aucune ressource tierce, aucun marqueur, structure accessible.\n' "$script_name"
