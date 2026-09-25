# Lecture des **noms** des secrets d'Actions de la forge, dans les fichiers qui les portent.
#
# À charger par « . scripts/lib/secrets.sh » depuis un script qui a défini script_name, une fonction
# die, et qui a chargé scripts/lib/shell.sh (secrets_read_env_names y prend shell_grep_into).
# Aucune fonction ne lit ni n'affiche une **valeur** : ces fichiers n'en contiennent pas, et c'est
# tout l'intérêt de les commiter.
#
#   secrets_read_names <fichier> <tableau à remplir> [<préfixe à retenir>]
#       un nom par ligne (ci/release-secrets.txt)
#   secrets_read_env_names <fichier> <tableau à remplir> <préfixe>
#       les clés « NOM=valeur » qui portent le préfixe (ci/legal-placeholder.env)
#
# **Une seule écriture**, parce que deux scripts lisent ces listes — scripts/release/ship.sh et
# scripts/release/check-forge-secrets.sh — et que dupliquer une garde correcte est un défaut au
# même titre que l'oublier (docs/procedures/shell-scripts.md, rétrospective de l'epic 3).
#
# Les deux fonctions **arrêtent le script** par die plutôt que de rendre un code : une liste de noms
# comprise à moitié ferait exiger ou vérifier moins de secrets qu'il n'en faut, sans que rien ne le
# dise. C'est la garde de require_patterns_file (scripts/lib/gitea.sh), pour la même raison.

# Un nom par ligne ; « # » commente jusqu'à la fin de la ligne, les lignes vides sont ignorées.
# Tout le reste doit être un nom de variable d'environnement, sans quoi le script s'arrête en
# nommant la ligne. Un doublon arrête aussi : il ferait compter deux fois le même secret, et une
# faute de frappe recopiée passerait pour une seconde entrée.
# Le tableau rendu peut être **vide** si aucun nom ne porte le préfixe : c'est à l'appelant d'en
# décider, parce que la conséquence n'est pas la même pour tous.
secrets_read_names() { # $1 fichier, $2 nom du tableau, $3 préfixe (facultatif)
  local secrets_fichier=$1 secrets_prefixe=${3:-} secrets_ligne secrets_nom secrets_numero=0
  local -n secrets_destination=$2
  local -A secrets_vus=()
  secrets_destination=()
  [[ -f $secrets_fichier && -r $secrets_fichier ]] \
    || die "liste de noms de secrets absente ou illisible : $secrets_fichier."
  while IFS= read -r secrets_ligne || [[ -n $secrets_ligne ]]; do
    secrets_numero=$((secrets_numero + 1))
    secrets_ligne=${secrets_ligne%%#*}
    if [[ $secrets_ligne =~ ^[[:space:]]*$ ]]; then continue; fi
    [[ $secrets_ligne =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*$ ]] \
      || die "$secrets_fichier, ligne $secrets_numero : ce n'est ni un commentaire, ni un nom de secret."
    secrets_nom=${BASH_REMATCH[1]}
    [[ -z ${secrets_vus[$secrets_nom]:-} ]] \
      || die "$secrets_fichier, ligne $secrets_numero : ce nom est écrit deux fois."
    secrets_vus[$secrets_nom]=1
    if [[ -z $secrets_prefixe || $secrets_nom == "$secrets_prefixe"* ]]; then
      secrets_destination+=("$secrets_nom")
    fi
  done < "$secrets_fichier"
}

# Les clés d'un fichier « NOM=valeur » qui portent le préfixe demandé. La **valeur** n'est ni lue ni
# gardée : seule la partie qui précède le « = » sort d'ici. C'est ainsi que scripts/release/
# build-image.sh lit les huit noms d'AD-9 dans ci/legal-placeholder.env plutôt que de les recopier ;
# le préfixe est un paramètre pour que cette fonction ne connaisse aucune liste en particulier.
# Un doublon arrête, comme ci-dessus.
# Le préfixe entre dans une expression régulière : il vient d'une **constante de l'appelant**, jamais
# d'une entrée, sans quoi un caractère spécial casserait le motif (piège connu, shell-scripts.md).
secrets_read_env_names() { # $1 fichier, $2 nom du tableau, $3 préfixe
  local secrets_fichier=$1 secrets_prefixe=$3 secrets_brut secrets_ligne secrets_nom
  local -n secrets_destination=$2
  local -A secrets_vus=()
  secrets_destination=()
  [[ -f $secrets_fichier && -r $secrets_fichier ]] \
    || die "fichier de noms de secrets absent ou illisible : $secrets_fichier."
  # shell_grep_into distingue « rien trouvé » d'une erreur de lecture et remplit une variable :
  # dans « $(…) », l'arrêt de la fonction ne quitterait que le sous-shell (piège connu).
  shell_grep_into secrets_brut -oE "^${secrets_prefixe}[A-Za-z0-9_]*=" "$secrets_fichier"
  while IFS= read -r secrets_ligne; do
    [[ -n $secrets_ligne ]] || continue
    secrets_nom=${secrets_ligne%=}
    [[ -z ${secrets_vus[$secrets_nom]:-} ]] \
      || die "$secrets_fichier : la clé $secrets_nom est écrite deux fois."
    secrets_vus[$secrets_nom]=1
    secrets_destination+=("$secrets_nom")
  done <<< "$secrets_brut"
}
