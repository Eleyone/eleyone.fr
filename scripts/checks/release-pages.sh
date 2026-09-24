#!/usr/bin/env bash
# C15 (AD-5, AD-10, D-5) : une mise en ligne est refusée si une page attendue manque du build de
# production, si une page de groupe y est vide, ou s'il y reste une trace de travail.
#
#   - inclusion : chaque clé de « ci/release-pages.txt » désigne une page présente en FR **et** en
#     EN, ou — pour un cas groupé — une section présente dans la page de son groupe ; et aucune page
#     de groupe ne sort vide ;
#   - exclusion : aucun « checks.json » publié, aucune chaîne « VALEUR-FACTICE », « noindex » ou
#     « draft-marker » dans une page.
#
# Les deux familles sont séparées et nommées : l'une dit ce qui doit être là, l'autre ce qui ne doit
# pas y être, et leurs messages ne se confondent pas — un **fichier** publié n'est pas une **chaîne**
# trouvée dans une page (constats NB1 et NB2 de la revue de spec de la story 11.1).
#
# « ci/release-pages.txt » est **cumulative** et ne vaut qu'à ce commit (D-5) : C15 vérifie que ce qui
# y est listé est en ligne, jamais que le socle est complet — cela, seule « release » le vérifie pour
# v1.0.0 (stories 11.7 et 11.11).
#
# Page ou section : la distinction vient de Hugo, pas d'une déduction. Le manifeste porte « url »,
# la RelPermalink de la page, **vide** pour un cas groupé dont la cascade dit « render: never »
# (AD-4). Une url non vide attend un fichier à « public/<url>index.html » ; une url vide sur un rôle
# « case » attend l'identifiant du cas dans la page de son groupe (mesuré le 24/09/2026, constat B3).
#
# Le contrôle ne tourne qu'au niveau « release » (scripts/check.sh --release) : « dev » porte des cas
# en brouillon et les valeurs légales factices, et il y échouerait à chaque PR. Hors « release » il le
# **dit** avant de rendre 0 — un « exit 0 » muet cacherait un nom de variable mal écrit (constat B1).
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=release-pages
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

level=${CHECK_LEVEL:-standard}
if [[ $level != release ]]; then
  printf "%s: niveau « %s » : contrôle de mise en ligne sauté, il ne tourne qu'au niveau « release » (scripts/check.sh --release).\n" \
    "$script_name" "$level"
  exit 0
fi

public=${CHECK_PUBLIC_ROOT:-public}
work=${CHECK_WORK_ROOT:-build/work}
expected_file=${CHECK_RELEASE_PAGES_FILE:-ci/release-pages.txt}

[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
command -v xmllint > /dev/null 2>&1 \
  || checks_die "xmllint est introuvable (paquet libxml2-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1)."
command -v jq > /dev/null 2>&1 || checks_die "jq est introuvable."
[[ -f $expected_file ]] \
  || checks_die "liste des pages attendues absente ($expected_file) : C15 ne saurait pas ce qu'il doit trouver."

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# Chemin d'une page dans le build, à partir de sa RelPermalink. Même résolution que C12 : « / » désigne
# « index.html », « /cas/chiliz/ » désigne « cas/chiliz/index.html », et une URL qui ne finit pas par
# « / » (uglyURLs) désigne le fichier lui-même.
page_de_url() { # $1 = RelPermalink
  local url=${1#/}
  [[ $url != */ && -n $url ]] || url="${url}index.html"
  printf '%s' "$url"
}

# --- la liste attendue ----------------------------------------------------------------------------
# Commentaires et lignes vides écartés. Un fichier **présent mais vide** n'est pas une conformité :
# c'est le piège déjà rencontré avec le fichier de motifs, qui désactivait l'audit sans rien dire
# (docs/procedures/shell-scripts.md).
shell_grep_into liste_attendues -vE '^[[:space:]]*(#|$)' "$expected_file"
liste_attendues=$(sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "$liste_attendues")
[[ -n $liste_attendues ]] \
  || checks_die "aucune clé dans $expected_file : une liste vide n'est pas une conformité."
mapfile -t attendues <<< "$liste_attendues"

# --- l'index du manifeste -------------------------------------------------------------------------
# checks_manifests meurt si la racine ou les manifestes manquent : la liste est donc éprouvée avant
# mapfile, qui rendrait sinon un tableau d'un seul élément vide au lieu d'un tableau vide.
manifestes=$(checks_manifests "$work")
mapfile -t fichiers_manifeste <<< "$manifestes"

declare -A role_de=() url_de=() groupe_de=() fichier_de=() page_groupe=()
langues=()
for manifeste in "${fichiers_manifeste[@]}"; do
  langue=$(jq -r '.lang // ""' "$manifeste") || checks_die "lecture impossible de $manifeste (jq)."
  [[ -n $langue ]] || checks_die "$manifeste ne porte pas de langue : aucun rapprochement possible."
  langues+=("$langue")

  # Un manifeste antérieur à la story 11.1 n'émet pas « url » : toutes les urls seraient vides, toute
  # page passerait pour une section, et le contrôle se tairait sur l'essentiel. Une entrée dont Hugo a
  # résolu la page (elle porte « role ») doit porter « url ».
  sans_url=$(jq '[.files[] | select(has("role") and (has("url") | not))] | length' "$manifeste") \
    || checks_die "lecture impossible de $manifeste (jq)."
  ((sans_url == 0)) \
    || checks_die "$manifeste : $sans_url entrée(s) sans clé « url » — layouts/home.checks.json ne l'émet pas, C15 ne peut pas distinguer une page d'une section."

  # « jq @tsv » laisserait les antislashs doublés (piège connu) ; l'interpolation les rend tels quels.
  #
  # Le séparateur est U+001F, **pas une tabulation** : la tabulation est un blanc, et « read » traite
  # une suite de blancs de l'IFS comme un seul délimiteur. L'url vide d'un cas groupé — le champ que
  # tout ce contrôle lit — disparaissait alors, et « chiliz » passait pour l'url de « case-02 »
  # (constaté en lançant le contrôle sur le dépôt réel). Avec un séparateur qui n'est pas un blanc,
  # les champs vides sont conservés. Aucune des cinq valeurs — clé, rôle, URL, nom de groupe, chemin
  # — ne peut contenir un caractère de commande.
  entrees=$(jq -r '.files[]
      | select((.translationKey // "") != "")
      | "\(.translationKey)\(.role // "")\(.url // "")\(.front_matter.group // "")\(.file)"' \
    "$manifeste") || checks_die "lecture impossible de $manifeste (jq)."
  [[ -n $entrees ]] \
    || checks_die "$manifeste ne décrit aucun fichier porteur d'un translationKey : une liste vide n'est pas une conformité."

  while IFS=$'\x1f' read -r cle role url groupe fichier; do
    [[ -n $cle ]] || continue
    role_de["$langue/$cle"]=$role
    url_de["$langue/$cle"]=$url
    groupe_de["$langue/$cle"]=$groupe
    fichier_de["$langue/$cle"]=$fichier
    # Le nom d'un groupe est son dossier sous content/cases/ : « cases/chiliz/_index.fr.md » → chiliz.
    # C'est la clé « group » d'un cas, que C8 tient déjà égale au dossier (scripts/checks/content.sh).
    if [[ $role == group && $fichier == cases/*/_index.* ]]; then
      nom=${fichier#cases/}
      nom=${nom%%/*}
      page_groupe["$langue/$nom"]=$url
    fi
  done <<< "$entrees"
done

# ==================================================================================================
# Règles d'inclusion — ce qui doit être là
# ==================================================================================================

for cle in "${attendues[@]}"; do
  for langue in "${langues[@]}"; do
    index="$langue/$cle"
    # Une clé que le manifeste ignore est un écart, pas un silence : la liste et le contenu ont
    # divergé, et personne ne le verrait si le contrôle se contentait des clés qu'il retrouve.
    if [[ -z ${role_de[$index]+presente} ]]; then
      signaler "$expected_file" \
        "C15 : clé « $cle » inconnue du manifeste $langue, aucune page ni section ne lui correspond"
      continue
    fi

    url=${url_de[$index]}
    if [[ -n $url ]]; then
      page=$(page_de_url "$url")
      [[ -f $public/$page ]] \
        || signaler "$page" "C15 : page attendue absente du build de production (clé « $cle », $langue)"
      continue
    fi

    # url vide : Hugo ne rend pas cette page à une URL propre. Pour un cas, c'est la cascade
    # « render: never » d'un groupe (AD-4), et la clé désigne alors une **section**. Pour tout autre
    # rôle, la clé ne désigne aucune page publiable, et la liste se trompe.
    if [[ ${role_de[$index]} != case ]]; then
      signaler "${fichier_de[$index]}" \
        "C15 : clé « $cle » ($langue) rendue à aucune URL et de rôle « ${role_de[$index]} » : elle ne désigne aucune page publiable"
      continue
    fi
    groupe=${groupe_de[$index]}
    if [[ -z $groupe ]]; then
      signaler "${fichier_de[$index]}" \
        "C15 : cas « $cle » ($langue) sans URL propre et sans clé « group » : sa section est introuvable"
      continue
    fi
    if [[ -z ${page_groupe[$langue/$groupe]+presente} || -z ${page_groupe[$langue/$groupe]} ]]; then
      signaler "${fichier_de[$index]}" \
        "C15 : le groupe « $groupe » n'a aucune page rendue en $langue, la section « $cle » n'est donc nulle part"
      continue
    fi
    page=$(page_de_url "${page_groupe[$langue/$groupe]}")
    if [[ ! -f $public/$page ]]; then
      signaler "$page" \
        "C15 : page du groupe « $groupe » absente du build de production, la section « $cle » ($langue) n'y est donc pas"
      continue
    fi
    # L'identifiant est lu par XPath, jamais par grep sur du HTML : le build de production est
    # **minifié** et Hugo y écrit « id=case-02 » sans guillemets, là où une fixture écrite à la main
    # en porte. Un motif qui exigerait le guillemet passerait les tests et compterait zéro sur le
    # vrai site — la faute B2 de la rétrospective de l'epic 7. Mesuré sur public/ le 24/09/2026.
    identifiants=$(checks_attributes "$public/$page" '//*[@id]/@id' id) || exit $?
    shell_grep -qxF "$cle" <<< "$identifiants" \
      || signaler "$page" "C15 : section « $cle » absente de la page du groupe « $groupe » ($langue)"
  done
done

# --- aucune page de groupe vide -------------------------------------------------------------------
# « Vide » se lit sur la page, pas dans le manifeste : une page de groupe qui ne porte aucune
# « <section class="case-section"> » montre au lecteur un titre de groupe sans un seul cas (constat
# B4). Un décompte tiré du manifeste compterait des cas en brouillon, absents de la production.
#
# Le parcours part des groupes du manifeste et ne retient que ceux dont la page est publiée : un
# groupe en brouillon n'est pas en ligne, et la règle d'inclusion ci-dessus se charge de celui qui
# manquerait alors qu'il est listé. Aucun groupe du tout n'est pas un trou de contrôle : ce sont la
# liste attendue et le manifeste qui sont éprouvés non vides plus haut, et eux seuls disent que la
# racine lue est la bonne.
for index in "${!page_groupe[@]}"; do
  url=${page_groupe[$index]}
  [[ -n $url ]] || continue
  page=$(page_de_url "$url")
  [[ -f $public/$page ]] || continue
  # Le prédicat encadre la classe d'espaces : « case-section-titre » n'est pas « case-section », et
  # l'ordre des attributs est celui du minifieur (« <section id=case-02 class=case-section> »).
  nombre=$(checks_xpath "$public/$page" \
    'count(//section[contains(concat(" ", normalize-space(@class), " "), " case-section ")])') || exit $?
  [[ $nombre =~ ^[0-9]+$ ]] \
    || checks_die "décompte des cas illisible sur $page (xmllint a rendu « $nombre »)."
  ((nombre > 0)) || signaler "$page" "C15 : page de groupe vide, aucun cas publié n'y figure"
done

# ==================================================================================================
# Règles d'exclusion — ce qui ne doit pas y être
# ==================================================================================================

# Un **fichier** publié. « checks.json » est le manifeste du rendu de travail : le trouver dans la
# production signale que les deux sorties se sont mélangées (AD-5).
manifestes_publies=$(checks_find "$public" -type f -name checks.json) || exit $?
while IFS= read -r chemin; do
  [[ -n $chemin ]] || continue
  signaler "$(checks_relative "$chemin" "$public")" \
    "C15 : fichier de manifeste publié, le rendu de travail a fui dans le build de production (AD-5)"
done <<< "$manifestes_publies"

# Une **chaîne** trouvée dans une page. La liste des pages est éprouvée non vide d'abord : sans cela,
# une racine erronée ou un build vide ne ferait trouver aucun marqueur et passerait pour une
# conformité. Elle est lue dans une variable, hors de tout pipeline, pour que l'anomalie de
# checks_find arrête vraiment le contrôle.
liste_pages=$(checks_find "$public" -type f -name '*.html') || exit $?
[[ -n $liste_pages ]] || checks_die "aucune page HTML dans $public : rien à contrôler."

# Les trois marqueurs, cherchés **sans tenir compte de la casse** et sans regex : « noindex » se
# présente aussi bien en « <meta name="robots" content="noindex">» qu'en « content=noindex » minifié,
# en majuscules ou noyé dans « noindex, nofollow » — toutes ces formes contiennent la chaîne
# (point 15 d'AGENTS.md : demander quelles *autres formes* la faute peut prendre).
#
# Deux formes sont écartées, et c'est une décision, pas un oubli :
#   - « content="none" », équivalent de « noindex, nofollow » pour les robots, n'est écrit par aucun
#     gabarit du dépôt, et chercher le mot « none » dans du HTML ne rendrait que du bruit ;
#   - le **libellé** du marqueur de brouillon est traduit (« Brouillon », « Draft ») et ces mots
#     peuvent figurer légitimement dans une page ; c'est la classe « draft-marker » émise par
#     layouts/_partials/draft-marker.html qui en est la signature invariante.
#
# La recherche porte sur les pages, non sur tout public/ : la feuille de style peut légitimement
# porter le nom d'une classe, et ce que C15 refuse est une trace **rendue au lecteur** (constat NB2).
for motif in VALEUR-FACTICE noindex draft-marker; do
  shell_grep_into pages_fautives -rliF "$motif" "$public" --include='*.html'
  [[ -n $pages_fautives ]] || continue
  while IFS= read -r chemin; do
    [[ -n $chemin ]] || continue
    signaler "$(checks_relative "$chemin" "$public")" \
      "C15 : trace de travail « $motif » trouvée dans la page"
  done <<< "$pages_fautives"
done

((fail == 0)) || exit 1
printf '%s: pages et sections attendues présentes en FR et en EN, aucune page de groupe vide, aucune trace de travail.\n' \
  "$script_name"
