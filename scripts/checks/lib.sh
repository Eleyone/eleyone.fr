# Outils communs des contrôles bloquants (AD-10), chargés par « . scripts/checks/lib.sh ».
#
#   checks_manifests <racine>   affiche les manifestes de la racine du rendu de travail, triés ;
#                               code 2 si la racine ou les manifestes manquent
#   checks_die <message>        message sur la sortie d'erreur, code 2 (anomalie)
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
#     "files": [                            tous les fichiers Markdown de content/ pour cette langue
#       {
#         "file":           "cases/chiliz/case-02-chiliz.fr.md",   chemin relatif à content/
#         "lang":           "fr",
#         "kind":           "page",         kind de Hugo : home, section, page
#         "role":           "case",         home, group, case, position, education, section, page
#         "translationKey": "case-02",
#         "draft":          true,
#         "front_matter":   { … },          le front matter tel qu'écrit dans le fichier
#         "h2":             ["## Contexte", …],   titres de niveau 2 du Markdown brut, dans l'ordre
#         "placed":         ["diagram-ncs-cs-flow", …],  identifiants des appels live-material
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

checks_die() { printf '%s: %s\n' "${script_name:-check}" "$*" >&2; exit 2; }

checks_manifests() { # $1 = racine du rendu de travail (par défaut build/work)
  local root=${1:-build/work} found
  [[ -d $root ]] || checks_die "rendu de travail absent ($root) : lancer scripts/build.sh work."
  found=$(find "$root" -name checks.json -type f | LC_ALL=C sort) \
    || checks_die "lecture de $root impossible."
  [[ -n $found ]] || checks_die "aucun manifeste dans $root : le format checks n'a pas été émis."
  printf '%s\n' "$found"
}
