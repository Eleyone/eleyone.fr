# Outils communs des contrôles bloquants (AD-10), chargés par « . scripts/checks/lib.sh ».
#
#   checks_manifests <racine>   affiche les manifestes de la racine du rendu de travail, triés ;
#                               code 2 si la racine ou les manifestes manquent
#   checks_die <message>        message sur la sortie d'erreur, code 2 (anomalie)
#   checks_report <fichier> <écart>   un signalement « <fichier>: <écart> » sur la sortie d'erreur
#   checks_xpath <fichier> <requête>  résultat d'une requête XPath ; anomalie si le fichier est illisible
#   shell_grep <arguments…>           grep qui distingue « rien trouvé » (1) d'une erreur (2 et plus)
#   checks_attributes <fichier> <requête> <attribut>   valeurs d'un attribut, une par ligne
#   checks_find <arguments…>          find qui s'arrête sur une erreur de parcours
#   checks_page_de_url <RelPermalink> chemin du fichier rendu, relatif à la racine du rendu
#   decoder_echappements        filtre : ramène les sérialisations d'une chaîne (entités HTML,
#                               séquences \uXXXX du JSON) à sa forme brute
#   normaliser_blancs           filtre : ramène tout blanc à une espace simple, sur **une seule ligne**
#   checks_is_todo <valeur>     la valeur commence par « [TODO »
#   checks_tolerated <brouillon> <valeur>
#                               la valeur est tolérée : fichier en brouillon **et** valeur « [TODO »
#
# Règle des brouillons (AD-10) : sur un fichier en « draft: true », une valeur qui commence par
# « [TODO » passe toutes les règles de **forme** (valeurs autorisées, longueur, comptage, vocabulaire,
# rattachement à un poste). La parité (C3), la liste des rubriques (C4) et le garde-fou s'appliquent
# aux brouillons comme au reste : cette bibliothèque n'écarte donc rien d'elle-même, elle donne
# l'outil, et chaque contrôle décide règle par règle.
#
# Convention de code de sortie du projet : 0 conforme, 1 refus, 2 anomalie.
#
# ## Forme du manifeste
#
# Le rendu de travail émet un manifeste par langue : « build/work/checks.json » (français, à la
# racine du site) et « build/work/<langue>/checks.json » pour les autres. Sa forme n'est définie
# qu'à un endroit, « layouts/home.checks.json » ; ce qui suit la décrit, sans la redéfinir.
#
#   {
#     "lang":  "fr",                        langue du manifeste
#     "stack": ["PHP", …],                  vocabulaire de data/stack.yaml, une seule fois (C6)
#     "rubrics": [{"fr": "Contexte", "en": "Context"}, …],   rubriques de data/rubrics.yaml,
#                                           dans l'ordre, avec leurs deux écritures (C3, C4)
#     "files": [                            tous les fichiers Markdown de content/ pour cette langue
#       {
#         "file":           "cases/chiliz/case-02-chiliz.fr.md",   chemin relatif à content/
#         "lang":           "fr",
#         "kind":           "page",         kind de Hugo : home, section, page
#         "role":           "case",         home, group, case, position, education, section, page
#         "url":            "/cas/chiliz/", RelPermalink de la page, **vide** quand Hugo ne la rend
#                                            pas à une URL propre : cas groupé (cascade
#                                            « render: never », AD-4), poste, formation. C15 s'en
#                                            sert pour distinguer une page attendue à
#                                            « public/<url>index.html » d'une simple section à
#                                            retrouver dans la page de son groupe (story 11.1)
#         "translationKey": "case-02",
#         "draft":          true,
#         "front_matter":   { … },          le front matter tel qu'écrit dans le fichier
#         "headings":       [{"level": 2, "text": "Contexte"}, …],   titres du Markdown brut, dans
#                                            l'ordre, avec leur niveau et leur texte sans les dièses
#         "placed":         ["diagram-ncs-cs-flow", …],  identifiants des appels live-material
#         "material":       [{"id": …, "type": …, "status": …, "source": …, "source_found": …}],
#                                            matériel vivant déclaré, avec la source qu'AD-6 lui
#                                            donne dans la langue du fichier et son existence (C7)
#         "todo":           false           « [TODO » apparaît dans le fichier, front matter compris
#       }
#     ]
#   }
#
# Cas particuliers :
# - « role » vaut « section » pour un _index technique (cases/_index, career/_index) et « group »
#   pour l'_index d'un dossier de groupe (cases/chiliz/_index) ;
# - un fichier sans suffixe de langue sort dans **les deux** manifestes, avec « lang » vide et une
#   clé « error » : aucun fichier de content/ n'échappe aux contrôles ;
# - « error » apparaît aussi si le fichier n'a pas de front matter, ou si Hugo ne résout aucune page
#   pour lui. Les clés qui en dépendent manquent alors : un contrôle lit « error » avant tout le reste.

# Chemin absolu : un contrôle lancé par un chemin relatif, puis un « cd », ne retrouverait pas
# l'enveloppe commune (constaté en rejouant la suite de tests).
checks_lib_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 2
# shellcheck source=../lib/shell.sh
. "$checks_lib_dir/../lib/shell.sh"

checks_die() { printf '%s: %s\n' "${script_name:-check}" "$*" >&2; exit 2; }

checks_manifests() { # $1 = racine du rendu de travail (par défaut build/work)
  local root=${1:-build/work} found
  [[ -d $root ]] || checks_die "rendu de travail absent ($root) : lancer scripts/build.sh work."
  found=$(find "$root" -name checks.json -type f | LC_ALL=C sort) \
    || checks_die "lecture de $root impossible."
  [[ -n $found ]] || checks_die "aucun manifeste dans $root : le format checks n'a pas été émis."
  printf '%s\n' "$found"
}

# Enveloppes des trois outils que les contrôles lancent en boucle. Chacune distingue « rien trouvé »
# d'une vraie erreur, plutôt que de tout avaler par « || true » (constat de la revue de la PR n° 47).
#
#   xmllint : 0 résultat, 10 et 11 aucun nœud ne correspond, autre chose = fichier illisible ou fatal
#   find    : 0 seulement ; tout le reste est une anomalie
#
# La garde de grep n'est pas ici : elle est commune à tout le dépôt (« shell_grep » et
# « shell_grep_into », scripts/lib/shell.sh). Elle y avait fini en quatre exemplaires
# (rétrospective de l'epic 3, constat A2).
#
# Les deux codes de « rien trouvé » viennent d'une divergence de libxml2, constatée en lançant le job
# de contrôles (story 3.12) : la 2.9 du poste rend 10 pour un résultat vide comme pour une requête
# mal écrite, la 2.13 de CHECK_IMAGE sépare les deux (11 vide, 10 requête invalide). Les deux sont
# donc tolérés, et une requête mal écrite passe pour un résultat vide : les requêtes sont des
# littéraux des scripts de contrôle, et leurs tests les rejouent toutes. Un fichier illisible rend 1
# des deux côtés et reste une anomalie.
checks_xpath() { # $1 = fichier, $2 = requête XPath ; la sortie d'erreur de libxml2 est écartée (AD-10)
  local rc=0
  xmllint --html --xpath "$2" "$1" 2> /dev/null || rc=$?
  ((rc == 0 || rc == 10 || rc == 11)) || checks_die "lecture XPath impossible sur $1 (xmllint, code $rc)."
  return 0
}

# Valeurs d'un attribut, une par ligne, quelle que soit la sérialisation de libxml2. Le XPath est lu
# **avant** le filtrage : un « exit » dans un élément de pipeline ne quitte que son sous-shell, et un
# « || true » final transformerait l'anomalie en succès (constat de la troisième revue de la PR
# n° 47). Le code de checks_xpath est donc propagé tel quel.
#
# Trois contrôles en portaient chacun sa copie, dont deux identiques au caractère près, si bien que
# le correctif ci-dessus a dû être appliqué trois fois (rétrospective de l'epic 3, constat A1).
checks_attributes() { # $1 = fichier, $2 = requête, $3 = nom de l'attribut
  local brut rc=0
  brut=$(checks_xpath "$1" "$2") || rc=$?
  ((rc == 0)) || return "$rc"
  local valeurs
  shell_grep_into valeurs -oE "$3=\"[^\"]*\"" <<< "$brut"
  [[ -z $valeurs ]] || sed -E "s/^$3=\"(.*)\"$/\1/" <<< "$valeurs"
}

checks_find() { # arguments de find ; s'arrête sur une erreur
  local rc=0
  find "$@" || rc=$?
  ((rc == 0)) || checks_die "parcours impossible (find, code $rc) : $1"
}

checks_report() { # $1 = fichier, $2 = écart ; format commun à tous les contrôles
  printf '%s: %s\n' "$1" "$2" >&2
}

checks_is_todo() { # $1 = valeur
  [[ ${1-} == '[TODO'* ]]
}

checks_tolerated() { # $1 = « true » si le fichier est un brouillon, $2 = valeur
  [[ ${1-} == true ]] && checks_is_todo "${2-}"
}

# Les racines que parcourt un contrôle qui lit **les deux rendus** : la production, et le rendu de
# travail quand il existe et n'est pas la même chose. Écrite une seule fois (rétrospective de
# l'epic 6, A5) : le bloc était recopié dans html.sh puis dans typo.sh, et c'est précisément parce
# qu'il vivait en silos qu'un troisième contrôle, links.sh, est resté en arrière avec sa règle
# neuve qui ne s'exécutait sur aucune page de cas (A4).
#
# Tant qu'un cas est en brouillon, la production ne le contient pas : un contrôle qui ne lit
# qu'elle ne voit rien du travail en cours. Le rendu de travail n'est ajouté que s'il existe, pour
# qu'un contrôle lancé sur une sortie seule (essais, image de CI) reste possible.
#
# Emploi : « checks_roots_into racines "$public" » puis « checks_relative <chemin> ».
checks_roots_into() { # $1 = nom du tableau à remplir, $2 = racine de production
  local -n checks_roots_destination=$1
  local public=$2
  checks_roots_destination=("$public")
  local travail=${CHECK_WORK_ROOT:-build/work}
  [[ ! -d $travail || $travail -ef $public ]] || checks_roots_destination+=("$travail")
}

# Le chemin d'un fichier, dépouillé de la racine d'où il vient, pour que le signalement nomme la
# page et non l'arborescence de build. Le dépouillement était écrit quatre fois.
checks_relative() { # $1 = chemin du fichier, $2 = racine de production
  local chemin=${1#"$2"/}
  printf '%s' "${chemin#"${CHECK_WORK_ROOT:-build/work}"/}"
}

# Chemin du fichier rendu pour une RelPermalink : « / » désigne « index.html », « /cas/chiliz/ »
# désigne « cas/chiliz/index.html », et une URL qui ne finit pas par « / » (uglyURLs) désigne le
# fichier lui-même.
#
# Écrite ici parce qu'elle avait déjà deux exemplaires — la fin de « page_visee » dans links.sh
# (C12) et « page_de_url » dans release-pages.sh (C15) —, et qu'un troisième est né avec C22
# (story 11.2). « Une parade s'écrit une fois » : c'est le mécanisme du constat A1 de la
# rétrospective de l'epic 3, où le même correctif avait dû être appliqué trois fois. C12 garde la
# sienne pour l'instant, sa résolution enveloppant aussi les liens relatifs et les fragments
# (écart consigné dans deferred-work.md).
checks_page_de_url() { # $1 = RelPermalink
  local url=${1#/}
  [[ $url != */ && -n $url ]] || url="${url}index.html"
  printf '%s' "$url"
}

# --- lire une chaîne dans une sortie de Hugo -------------------------------------------------------
#
# Deux filtres, employés ensemble et dans cet ordre : « decoder_echappements | normaliser_blancs ».
# Ils viennent de C23 (scripts/checks/legal-address.sh, story 9.1), où huit tours de revue les ont
# écrits ; C22 (scripts/checks/output-patterns.sh, story 11.2) en a besoin pour les mêmes raisons,
# et une seconde écriture aurait été la faute du point 19 d'AGENTS.md.
#
# **Une même chaîne a six sérialisations constatées dans une sortie de Hugo.** Chercher plusieurs
# formes fixes est une impasse : leur nombre est combinatoire, et celle qu'on oublie est celle qui
# fuite. Une seule forme canonique, obtenue en décodant le texte avant de le lire, les couvre d'un
# coup. Sans cela, un contrôle cherche la chaîne brute dans un HTML échappé, ne trouve rien, et se
# déclare vert (constat bloquant de la revue de la PR n° 98).
decoder_echappements() {
  # **Deux familles d'échappement, pas une.** Le HTML écrit des entités ; le JSON-LD, sérialisé par
  # l'encodeur de Go, écrit des séquences Unicode — « & » pour l'esperluette, « < » et
  # « > » pour les chevrons. Une adresse portant un « & » fuyait donc par le JSON-LD sans que
  # rien ne le dise, le décodeur ne connaissant que les entités (constat de la revue de la PR n° 98,
  # vérifié en mesurant ce que « jsonify » produit).
  #
  # Dans chaque famille, les trois écritures d'un caractère sont couvertes : décimale, hexadécimale
  # et nommée pour le HTML ; la casse du « x » et des chiffres hexadécimaux varie. Celle qu'on omet
  # est celle qui fuite.
  #
  # Les séquences « \n », « \r » et « \t » du JSON deviennent une **espace**, et non le caractère
  # qu'elles désignent : « normaliser_blancs » ramènera de toute façon tout blanc à une espace
  # simple. Une adresse multi-lignes s'écrit « Ligne 1\nLigne 2 » dans un JSON-LD, et sans cette
  # ligne elle n'y était reconnue sous aucune forme (huitième tour de la revue de la PR n° 98 —
  # la sixième sérialisation de la même chaîne).
  #
  # L'esperluette et la barre oblique inverse se décodent **en dernier** dans leur famille :
  # l'inverse transformerait « &amp;lt; », qui désigne le texte « &lt; », en « < ».
  #
  # **« &rsquo; » est la seule entité que la sortie de production de ce site émet**, et elle y
  # apparaît 236 fois — Hugo convertit l'apostrophe droite du Markdown en apostrophe typographique,
  # que le minifieur écrit en entité (mesuré sur public/ le 25/09/2026, story 11.2). Un motif
  # portant une apostrophe typographique n'était donc reconnu dans aucune page : la seule
  # sérialisation que le rendu produit vraiment était celle qui manquait. Ce qui reste, et que le
  # décodage ne peut pas régler, est une différence de **caractère** et non d'écriture : un motif
  # écrit avec l'apostrophe droite ne correspond pas à un texte qui porte la typographique, comme
  # un motif écrit sans accent ne correspond pas à un texte accentué (consigné dans
  # deferred-work.md).
  sed -E -e "s/&(#0*39|#[xX]0*27|apos);/'/g" \
         -e 's/&(#0*8217|#[xX]0*2019|rsquo);/’/g' \
         -e 's/&(#0*8216|#[xX]0*2018|lsquo);/‘/g' \
         -e 's/&(#0*34|#[xX]0*22|quot);/"/g' \
         -e 's/&(#0*43|#[xX]0*2[bB]);/+/g' \
         -e 's/&(#0*60|#[xX]0*3[cC]|lt);/</g' \
         -e 's/&(#0*62|#[xX]0*3[eE]|gt);/>/g' \
         -e 's/&(#0*38|#[xX]0*26|amp);/\&/g' \
         -e 's/\\u0*3[cC]/</g' \
         -e 's/\\u0*3[eE]/>/g' \
         -e "s/\\\\u0*27/'/g" \
         -e 's/\\"/"/g' \
         -e 's/\\u0*26/\&/g' \
         -e 's/\\[nrt]/ /g' \
         -e 's/\\\\/\\/g'
}

# Les blancs sont ramenés à une espace simple. Le rendu de production est **minifié** : une adresse
# postale écrite sur deux lignes y arrive sur une seule, et la comparer à la chaîne d'origine, sauts
# de ligne compris, ne trouvait rien — le contrôle passait au vert en laissant fuiter l'adresse
# (constat de la revue de la PR n° 98). Les fixtures des tests, écrites par « printf » sans passer
# par Hugo, ne pouvaient pas le montrer.
#
# **Le résultat tient sur une seule ligne** : les sauts de ligne deviennent des espaces, et un
# fichier entier passé à ce filtre en sort en une ligne. C'est ce qui rend sûre une recherche par
# « grep », qui travaille ligne par ligne et ne verrait jamais une chaîne à cheval sur deux lignes
# (pdf_confront, employée par C21 et par C22).
#
# **Le retour chariot en fait partie**, et l'oublier était un faux négatif mesuré : un fichier de
# static/ copié tel quel depuis un poste Windows porte des fins de ligne « \r\n », et « \r »
# survivait au filtre. Un motif à cheval sur deux lignes y devenait « Ville\r Cedex », que la
# recherche d'« Ville Cedex » ne trouve pas — même contenu, même motif, code 0 en CRLF contre code 1
# en LF (constat de la revue du code de la PR n° 117, reproduit avant d'être corrigé). C'est la même
# classe que l'entité « &rsquo; » ci-dessus : une écriture non couverte, et le garde-fou passe au
# vert sur une fuite. Le dépôt en porte la trace — les fichiers « *:Zone.Identifier » de
# docs/private/context/ viennent d'un téléchargement Windows.
normaliser_blancs() { tr '\r\n\t' '   ' | tr -s ' '; }
