#!/usr/bin/env bash
# C12 (AD-3, AD-4, AD-18, AD-21) : tout lien interne mène quelque part, toute ancre existe, aucune
# page n'est orpheline, et les liens conditionnels sont cohérents avec ce qui est publié.
#
#   - un lien interne désigne un fichier de public/ qui existe ;
#   - un fragment (#…) désigne un identifiant présent dans la page visée ; aucune forme d'ancre n'est
#     écrite ici (« #case-02 », « #case-02-contexte », « #position-chiliz » se vérifient donc seuls) ;
#   - toute page est atteignable **depuis l'accueil de sa langue**, par un chemin de liens (FR-15) ;
#     les deux pages 404 en sont exemptées, nginx les sert sur une URL inconnue (AD-13) ;
#   - les liens de CV apparaissent si et seulement si les **deux** PDF sont publiés (AD-21) ;
#   - le lien du dépôt apparaît si et seulement si « params.source_url » est renseignée.
#
# Le contrôle porte sur le build de production (AD-10). Le rendu de travail contient des brouillons
# volontairement non liés : la règle des pages orphelines y serait fausse.
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=links
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

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

# --- liens conditionnels : CV et dépôt --------------------------------------------------------------
cv_publies=0
[[ ! -f $public/assets/cv/cv-fr.pdf || ! -f $public/assets/cv/cv-en.pdf ]] || cv_publies=1
# Le comptage passe par une variable, jamais par « shell_grep … | wc -l » : un « exit » en tête de
# pipeline ne quitte que son sous-shell, et un répertoire illisible se compterait pour zéro lien
# (constat de la première revue de plage, 21/09/2026).
shell_grep_into fichiers_cv -rlE 'href="?/assets/cv/' "$public" --include='*.html'
liens_cv=0
[[ -z $fichiers_cv ]] || liens_cv=$(wc -l <<< "$fichiers_cv")
if ((cv_publies == 1 && liens_cv == 0)); then
  signaler "assets/cv/" "C12 : les deux CV sont publiés mais aucune page n'y mène (AD-21)"
elif ((cv_publies == 0 && liens_cv > 0)); then
  signaler "assets/cv/" "C12 : $liens_cv page(s) mènent à un CV alors que les deux PDF ne sont pas publiés (AD-21)"
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
