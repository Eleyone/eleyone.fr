#!/usr/bin/env bash
# C12 (AD-3, AD-4, AD-18, AD-21) : tout lien interne mène quelque part, toute ancre existe, aucune
# page n'est orpheline, et les liens conditionnels sont cohérents avec ce qui est publié.
#
#   - un lien interne désigne un fichier de public/ qui existe ;
#   - un fragment (#…) désigne un identifiant présent dans la page visée ; aucune forme d'ancre n'est
#     écrite ici (« #case-02 », « #case-02-contexte », « #position-chiliz » se vérifient donc seuls) ;
#   - toute page est atteignable **depuis l'accueil de sa langue**, par un chemin de liens (FR-15) ;
#     les deux pages 404 en sont exemptées, nginx les sert sur une URL inconnue (AD-13) ;
#   - le lien « Retour au parcours » d'une page de cas vise l'ancre de son poste sur l'accueil de
#     **sa** langue ; cette règle seule lit aussi le rendu de travail, les cas étant en brouillon ;
#   - les liens de CV apparaissent si et seulement si les **deux** PDF sont publiés (AD-21) ;
#   - le lien du dépôt apparaît si et seulement si « params.source_url » est renseignée.
#
# Le contrôle porte sur le build de production (AD-10). Le rendu de travail contient des brouillons
# volontairement non liés : la règle des pages orphelines y serait fausse.
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=links
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# Les deux noms de CV et leur dossier de publication viennent de lib/pdf.sh : la clause des liens
# conditionnels cherchait « /assets/cv/ », le dossier **source**, quand Hugo publie sous « /cv/ »,
# et elle ne pouvait donc jamais se déclencher (constat B2, rétrospective de l'epic 7).
. "$(dirname "${BASH_SOURCE[0]}")/../lib/pdf.sh"

public=${CHECK_PUBLIC_ROOT:-public}
config=${CHECK_CONFIG_FILE:-config/_default/hugo.yaml}
[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
command -v xmllint > /dev/null 2>&1 \
  || checks_die "xmllint est introuvable (paquet libxml2-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1)."

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# Page visée par un lien, en chemin relatif à $public ; vide si le lien ne désigne pas une page.
page_visee() { # $1 = page courante (relative), $2 = cible du lien sans fragment
  local courante=$1 cible=$2 dossier resultat
  [[ -n $cible ]] || { printf '%s' "$courante"; return 0; }
  if [[ $cible == /* ]]; then
    resultat=${cible#/}
  else
    dossier=$(dirname "$courante")
    [[ $dossier != . ]] || dossier=""
    resultat="${dossier:+$dossier/}$cible"
  fi
  # « /cas/chiliz/ » désigne « cas/chiliz/index.html », « / » désigne « index.html »
  [[ $resultat != */ && -n $resultat ]] || resultat="${resultat}index.html"
  printf '%s' "$resultat"
}

liste_pages=$(cd "$public" && checks_find . -type f -name '*.html' | sed 's#^\./##' | LC_ALL=C sort) || exit $?
# La liste est éprouvée **avant** mapfile : sur une liste vide, « mapfile <<< » rend un tableau d'un
# seul élément vide, jamais un tableau vide, et la garde ne se déclenchait donc jamais (constaté en
# écrivant le cas de test de l'action 3 de la rétrospective de l'epic 3).
[[ -n $liste_pages ]] || checks_die "aucune page HTML dans $public : rien à contrôler."
mapfile -t pages <<< "$liste_pages"

# --- liens internes et ancres ---------------------------------------------------------------------
declare -A liens_sortants=()
for page in "${pages[@]}"; do
  sortants=""
  liste_1=$(checks_attributes "$public/$page" '//a[@href]/@href' href) || exit $?
  while IFS= read -r href; do
    [[ -n $href ]] || continue
    # Liens externes et protocoles : hors de C12, qui ne juge que l'intérieur du site.
    [[ $href != http://* && $href != https://* && $href != //* ]] || continue
    [[ $href != mailto:* && $href != tel:* ]] || continue
    cible=${href%%#*}
    fragment=${href#*#}
    [[ $href == *#* ]] || fragment=""
    visee=$(page_visee "$page" "$cible")
    if [[ ! -f $public/$visee ]]; then
      signaler "$page" "C12 : lien « $href » vers une page absente ($visee)"
      continue
    fi
    [[ -z $cible ]] || sortants+="$visee"$'\n'
    if [[ -n $fragment ]]; then
      identifiants=$(checks_attributes "$public/$visee" '//*[@id]/@id' id)
      shell_grep -qxF "$fragment" <<< "$identifiants" \
        || signaler "$page" "C12 : ancre « #$fragment » absente de $visee"
    fi
  done <<< "$liste_1"
  liens_sortants[$page]=$sortants
done

# --- pages orphelines : parcours en largeur depuis l'accueil de chaque langue ----------------------
# Une page atteignable seulement depuis une autre page orpheline reste orpheline : c'est pourquoi le
# parcours part des accueils, et ne se contente pas de compter les liens entrants.
declare -A atteintes=()
file=()
for page in "${pages[@]}"; do
  [[ $page == index.html || $page =~ ^[a-z]{2}/index\.html$ ]] || continue
  atteintes[$page]=1
  file+=("$page")
done
((${#file[@]} > 0)) || checks_die "aucun accueil dans $public : impossible de juger les pages orphelines."

while ((${#file[@]} > 0)); do
  courante=${file[0]}
  file=("${file[@]:1}")
  while IFS= read -r voisine; do
    [[ -n $voisine ]] || continue
    [[ -z ${atteintes[$voisine]:-} ]] || continue
    atteintes[$voisine]=1
    file+=("$voisine")
  done <<< "${liens_sortants[$courante]:-}"
done

for page in "${pages[@]}"; do
  [[ -z ${atteintes[$page]:-} ]] || continue
  # Les deux pages 404 ne sont liées par personne : nginx les sert sur une URL inconnue (AD-13).
  [[ $page != 404.html && ! $page =~ ^[a-z]{2}/404\.html$ ]] || continue
  signaler "$page" "C12 : page orpheline, aucun chemin de liens depuis l'accueil de sa langue (FR-15)"
done

# --- retour au parcours : l'ancre du poste, pas l'accueil seul (AD-18) ----------------------------
#
# « career-url.html » est la seule construction de ce lien, mais rien ne gardait ce qu'il produit :
# un lien vers « / » sans ancre résout parfaitement, et les règles ci-dessus l'auraient accepté.
# C'est pourtant l'ancre qui ramène Claire au poste qu'elle lisait ; sans elle, elle retombe en haut
# du CV et doit retrouver sa place (constat de la revue de spec de la story 6.1).
# **Cette règle lit les deux rendus**, contrairement au reste du contrôle. Les six cas sont en
# brouillon : la production ne contient que les deux accueils, si bien que la règle ajoutée par la
# story 6.1 ne s'exécutait sur **aucune page de cas** (rétrospective de l'epic 6, A4). La règle des
# pages orphelines, elle, reste en production seule — un rendu de travail contient des brouillons
# volontairement non liés, et elle y serait fausse. Deux portées dans un même contrôle, parce que
# les deux règles ne jugent pas la même chose.
checks_roots_into racines_retour "$public"
pages_retour=$(checks_find "${racines_retour[@]}" -type f -name 'index.html' | LC_ALL=C sort) || exit $?
while IFS= read -r chemin; do
  [[ -n $chemin ]] || continue
  page=$(checks_relative "$chemin" "$public")
  [[ $page == cas/*/index.html || $page == en/cases/*/index.html ]] || continue
  retours=$(checks_attributes "$chemin" '//p[contains(@class,"nav-links")]/a/@href' href) || exit $?
  # Une liste vide n'est jamais passée sous silence : sans lien de retour, la page manque à AD-18,
  # et un « continue » ici rendrait la règle muette au lieu de la faire échouer.
  if [[ -z $retours ]]; then
    signaler "$page" "C12 : page de cas sans lien de retour au parcours (AD-18)"
    continue
  fi
  # L'ancre ne suffit pas : « /ailleurs#position-chiliz » la porte aussi. La cible doit être
  # **l'accueil d'une langue**, seul endroit où vit le parcours (AD-18). Les règles de lien et
  # d'ancre ci-dessus rendaient déjà ce cas improbable — elles exigent que la page visée existe et
  # porte l'identifiant — mais elles ne disent pas *quelle* page, et l'intention du critère se
  # perdait là (constat de la revue du code de la PR n° 79).
  # L'accueil attendu est celui de **la langue de la page**, déduit de son propre chemin : la
  # langue par défaut est à la racine, les autres sous leur préfixe. Un accueil quelconque ne
  # suffit pas — une page française qui renverrait vers « /en/#position-chiliz » ramènerait Claire
  # sur un CV qu'elle ne lisait pas (constat de la deuxième revue du code de la PR n° 79).
  if [[ $page =~ ^([a-z]{2})/ ]]; then attendu="${BASH_REMATCH[1]}/index.html"; else attendu=index.html; fi
  conforme=0
  while IFS= read -r href; do
    [[ -n $href ]] || continue
    [[ $href == *"#position-"* ]] || continue
    visee=$(page_visee "$page" "${href%%#*}")
    [[ $visee == "$attendu" ]] || continue
    conforme=1
    break
  done <<< "$retours"
  ((conforme == 1)) \
    || signaler "$page" "C12 : le retour au parcours ne vise pas l'ancre de son poste sur $attendu (AD-18)"
done <<< "$pages_retour"

# --- liens conditionnels : CV et dépôt --------------------------------------------------------------
# **Le chemin publié est « /cv/ », pas « /assets/cv/ »** : Hugo sort une ressource de « assets/x »
# à « /x ». La clause visait la source au lieu de la sortie, si bien que « cv_publies » et
# « liens_cv » valaient **toujours 0** — les deux branches exigent l'inverse, aucune ne pouvait se
# déclencher, et le critère d'acceptation de la story 7.2 la déclarait passante. Mesuré sur le
# build réel après la publication des CV : deux PDF publiés, quatre pages y menant, et le contrôle
# comptait zéro des deux côtés (constat B2, rétrospective de l'epic 7).
#
# Ce que la fixture du test écrivait sous « /assets/cv/ » reproduisait l'hypothèse fausse : les
# deux cas passaient au vert sur un contrôle qui ne pouvait rien voir. C'est le point 16 d'AGENTS.md.
#
# Le délimiteur de fin accepte le guillemet, l'espace **et** « > », parce que le rendu de production
# est **minifié** : Hugo y écrit « href=/cv/cv-fr.pdf », sans guillemets, alors que les fixtures des
# tests en portent. Un motif exigeant le guillemet fermant passe les tests et compte zéro lien sur le
# vrai site — la même faute que celle qu'on corrige ici, retrouvée dans son correctif, et vue en le
# mesurant sur « public/ » plutôt qu'en le relisant.
# « ?# » y figure aussi : « /cv/cv-fr.pdf#page=2 » est un lien de CV valide, et l'exclure
# recréerait un compteur aveugle à une forme légitime.
cv_publies=1
for cv_nom in "${pdf_cv_names[@]}"; do
  [[ -f $public/$pdf_cv_published_dir/$cv_nom ]] || cv_publies=0
done
# Le comptage passe par une variable, jamais par « shell_grep … | wc -l » : un « exit » en tête de
# pipeline ne quitte que son sous-shell, et un répertoire illisible se compterait pour zéro lien
# (constat de la première revue de plage, 21/09/2026).
shell_grep_into fichiers_cv -rlE \
  "href=\"?/$pdf_cv_published_dir/$(pdf_cv_names_regex)([?#]|\"|[[:space:]]|>)" "$public" --include='*.html'
liens_cv=0
[[ -z $fichiers_cv ]] || liens_cv=$(wc -l <<< "$fichiers_cv")
if ((cv_publies == 1 && liens_cv == 0)); then
  signaler "$pdf_cv_published_dir/" "C12 : les deux CV sont publiés mais aucune page n'y mène (AD-21)"
elif ((cv_publies == 0 && liens_cv > 0)); then
  signaler "$pdf_cv_published_dir/" "C12 : $liens_cv page(s) mènent à un CV alors que les deux PDF ne sont pas publiés (AD-21)"
fi

source_url=""
[[ ! -f $config ]] || source_url=$(sed -n 's#^[[:space:]]*source_url:[[:space:]]*["'"'"']\?\([^"'"'"'[:space:]]*\).*#\1#p' "$config" | head -1)
liens_depot=0
if [[ -n $source_url ]]; then
  shell_grep_into fichiers_depot -rlF "$source_url" "$public" --include='*.html'
  [[ -z $fichiers_depot ]] || liens_depot=$(wc -l <<< "$fichiers_depot")
fi
if [[ -n $source_url ]] && ((liens_depot == 0)); then
  signaler "$config" "C12 : params.source_url est renseignée mais aucune page ne mène au dépôt"
fi

((fail == 0)) || exit 1
printf '%s: liens internes, ancres, pages atteignables et liens conditionnels vérifiés.\n' "$script_name"
