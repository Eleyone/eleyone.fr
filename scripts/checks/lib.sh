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
