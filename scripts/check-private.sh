#!/usr/bin/env bash
# Empêche des fichiers ou contenus privés d'entrer dans l'historique git.
#
#   check-private.sh staged              hook pre-commit : vérifie l'index
#   check-private.sh history [<rev>...]  audit : tout l'historique par défaut
#   check-private.sh pre-receive         hook serveur : lit "old new ref" sur stdin
#
# Les motifs sensibles (une chaîne fixe par ligne, # pour commenter) vivent hors dépôt :
# $PRIVATE_PATTERNS_FILE, sinon docs/private/forbidden-patterns.txt.
# En staged et history, sans ce fichier ou sans aucun motif, seuls les chemins interdits sont vérifiés.
# En pre-receive, PRIVATE_PATTERNS_FILE est obligatoire, et une liste absente ou sans motif refuse le push.
# Une alerte n'affiche jamais le contenu trouvé ni le motif : seulement l'emplacement
# (commit, fichier, ligne) et le numéro de ligne du motif dans le fichier de motifs.
# Un chemin qui reprend un motif n'est pas affiché non plus : l'afficher reviendrait à afficher le motif.
#
# Quatre surfaces sont regardées (story 1.5) : le contenu des fichiers, leur chemin, le chemin confronté
# aux motifs, et le message des commits (en history et pre-receive ; en staged le message n'existe pas encore).
set -euo pipefail

# Les chemins sont comparés sans tenir compte de la casse : « Docs/Private/ » est aussi refusé.
# Une interdiction reste temporaire, le temps que le hook sache lire ce binaire :
#   assets/cv/*.pdf tant que C21 n'est pas dans le hook (AD-21, story 7.x)
# L'interdiction des extensions d'images est **levée sous assets/** depuis la story 5.4 : C20 y lit
# désormais les métadonnées de chaque image, dans le hook comme en CI (AD-19, AD-12). Ailleurs elle
# tient : C20 sait dire qu'une image ne porte pas de données de prise de vue, pas ce qu'elle montre.
# Le périmètre a été arbitré par Arnaud le 21/09/2026.
# .env est refusé seul ou suffixé (.env.production, .env.local) ; .environment.md est admis.
# Trois exceptions nommées : .env.example, commité par conception (AGENTS.md) et sans aucune valeur ;
# les captures des branches de design (design/<branche>/screenshots/), déjà publiées et produites par un
# navigateur ; et les images d'assets/, que C20 contrôle.
forbidden_paths='^docs/(private|context)/|(^|/)\.env($|\.)|^assets/cv/.*\.pdf$|\.(jpe?g|png|gif|webp|avif|tiff?|bmp|heic|heif|ico)$'
allowed_paths='(^|/)\.env\.example$|^design/[^/]+/screenshots/|^assets/.*\.(jpe?g|png|gif|webp|avif|tiff?|bmp|heic|heif|ico)$'
# Les chemins que C20 doit lire : les images admises ci-dessus.
image_paths='^assets/.*\.(jpe?g|png|gif|webp|avif|tiff?|bmp|heic|heif|ico)$'

# C20 vit dans scripts/lib/image.sh, copiée à côté de ce script sur la forge (procédure du hook).
# Son absence **refuse** : un garde-fou qui s'ignore en silence ne garde rien.
image_lib="$(dirname "${BASH_SOURCE[0]}")/lib/image.sh"
if [[ -r $image_lib ]]; then
  . "$image_lib"
else
  echo "check-private: scripts/lib/image.sh absent ou illisible ($image_lib) : C20 ne peut pas s'exécuter." >&2
  exit 1
fi
patterns_file="${PRIVATE_PATTERNS_FILE:-$(git rev-parse --show-toplevel 2>/dev/null || true)/docs/private/forbidden-patterns.txt}"
[[ $patterns_file == /* ]] || patterns_file="$PWD/$patterns_file"
# depuis un sous-dossier, git ls-files, git ls-tree et git grep ne verraient que ce sous-dossier :
# l'audit part de la racine du dépôt (un dépôt nu, côté serveur, n'a pas de racine de travail)
if top=$(git rev-parse --show-toplevel 2>/dev/null) && [[ -n $top ]]; then
  cd "$top"
fi
mode=${1:-}
# le hook serveur ne se replie jamais sur les chemins : un dépôt nu n'a pas de chemin par défaut pour la liste
if [[ $mode == pre-receive && -z ${PRIVATE_PATTERNS_FILE:-} ]]; then
  echo "check-private: pre-receive sans PRIVATE_PATTERNS_FILE : push refusé, la liste des motifs est obligatoire." >&2
  exit 1
fi
status=0
sep=$'\001' # séparateur des champs de git grep -z : absent des noms de fichier, contrairement à la tabulation

fail() { printf 'check-private: %b\n' "$*" >&2; status=1; }

patterns=""
if [[ -f $patterns_file ]]; then
  patterns=$(mktemp)
  patterns_text=$(mktemp)
  trap 'rm -f "$patterns" "$patterns_text"' EXIT
  # "numéro de ligne:motif", pour citer un motif par son numéro sans l'afficher
  rc=0
  grep -nvE '^[[:space:]]*(#|$)' "$patterns_file" > "$patterns" 2>/dev/null || rc=$?
  ((rc <= 1)) || { echo "check-private: fichier de motifs illisible ($patterns_file)" >&2; exit 2; }
  # les motifs seuls, pour un premier passage avec tous les motifs à la fois
  rc=0
  grep -vE '^[[:space:]]*(#|$)' "$patterns_file" > "$patterns_text" 2>/dev/null || rc=$?
  ((rc <= 1)) || { echo "check-private: fichier de motifs illisible ($patterns_file)" >&2; exit 2; }
  if [[ ! -s $patterns ]]; then
    patterns=""
    if [[ $mode == pre-receive ]]; then
      echo "check-private: aucun motif dans la liste des motifs ($patterns_file) : push refusé." >&2
      exit 1
    fi
    echo "check-private: aucun motif dans le fichier de motifs ($patterns_file), chemins seulement" >&2
  fi
else
  if [[ $mode == pre-receive ]]; then
    echo "check-private: liste des motifs absente ($patterns_file) : push refusé." >&2
    exit 1
  fi
  echo "check-private: pas de fichier de motifs ($patterns_file), chemins seulement" >&2
fi

# C20 dans le garde-fou (AD-19, AD-12) : une image porteuse de métadonnées est refusée **avant
# publication**. La CI seule arriverait après que le miroir a poussé, et un commit poussé sur
# GitHub reste atteignable par son SHA même après un push forcé.
#
# Le contenu passe par un fichier temporaire : un blob binaire ne tient pas dans une variable
# shell, que le premier octet nul tronque — l'image paraîtrait vide, donc propre.
check_images() { # $1 = libellé, $2 = révision (« --cached » pour l'index), $3 = liste des chemins
  local label=$1 rev=$2 listing=$3 images chemin marqueurs prc=0 blob
  images=$(printf '%s\n' "$listing" | grep -E -i "$image_paths") || prc=$?
  ((prc <= 1)) || { fail "recherche des images impossible dans $label"; return 0; }
  [[ -n $images ]] || return 0
  blob=$(mktemp) || { fail "fichier temporaire impossible pour $label"; return 0; }
  while IFS= read -r chemin; do
    [[ -n $chemin ]] || continue
    if [[ $rev == --cached ]]; then
      git cat-file blob ":$chemin" > "$blob" 2>/dev/null || { fail "lecture impossible d'une image de $label"; continue; }
    else
      git cat-file blob "$rev:$chemin" > "$blob" 2>/dev/null || { fail "lecture impossible d'une image de $label"; continue; }
    fi
    marqueurs=$(image_metadata_markers "$blob") || { fail "lecture impossible d'une image de $label"; continue; }
    # Le chemin est affiché, pas le contenu : un marqueur de métadonnée n'est pas un motif privé,
    # et l'auteur doit savoir quel fichier reprendre.
    [[ -z $marqueurs ]] \
      || fail "C20 : métadonnées dans une image de $label : $chemin ($(tr '\n' ' ' <<< "$marqueurs" | sed 's/ $//'))"
  done <<< "$images"
  rm -f "$blob"
}

check_tree() { # $1 = libellé, reste = arguments git (commit ou --cached)
  local label=$1; shift
  local listing paths entry hits="" err rc=0 prc=0
  if [[ $1 == --cached ]]; then
    listing=$(git -c core.quotePath=false ls-files) || { fail "lecture impossible de $label"; return 0; }
  else
    listing=$(git -c core.quotePath=false ls-tree -r --name-only "$1") || { fail "lecture impossible de $label"; return 0; }
  fi
  # « core.quotePath=false » : sans lui, git cite entre guillemets et échappe en octal tout chemin
  # non-ASCII — « "assets/images/caf\303\251.webp" ». Les motifs de chemin ne collaient alors plus,
  # et l'image **n'était pas même sélectionnée** pour C20 : elle passait avec ses métadonnées, en
  # silence. Reproduit à la rétrospective de l'epic 5, constat B5.
  #

  # grep rend 1 quand il ne trouve rien et 2 sur une erreur : une erreur ne vaut jamais « aucun chemin privé »
  paths=$(printf '%s\n' "$listing" | grep -E -i "$forbidden_paths") || prc=$?
  if ((prc > 1)); then
    fail "recherche des chemins impossible dans $label"
    return 0
  fi
  if [[ -n $paths ]]; then # l'exception nommée, retirée après coup : une erreur de grep ne l'élargit jamais
    prc=0
    paths=$(printf '%s\n' "$paths" | grep -E -i -v "$allowed_paths") || prc=$?
    ((prc <= 1)) || { fail "exception de chemin illisible dans $label"; return 0; }
  fi
  [[ -z $paths ]] || fail "chemin privé dans $label :\n$paths"
  # Un chemin reste cité par git s'il contient un saut de ligne ou un caractère de contrôle, que
  # « core.quotePath=false » ne désarme pas. Celui-là est **refusé** plutôt qu'analysé de travers :
  # la lecture ligne à ligne de ce script ne saurait de toute façon pas le traiter, et un garde-fou
  # qui doute refuse. La vérification vient après celle des chemins interdits, pour que l'échec de
  # grep garde son propre message.
  local cites prc_cite=0
  cites=$(printf '%s\n' "$listing" | grep -c '^"') || prc_cite=$?
  ((prc_cite <= 1)) || { fail "comptage des chemins cités impossible dans $label"; return 0; }
  ((cites == 0)) || fail "chemin illisible dans $label : $cites fichier(s) dont le nom porte un saut de ligne ou un caractère de contrôle ; les renommer"
  check_images "$label" "$1" "$listing"
  [[ -n $patterns ]] || return 0
  # les chemins eux-mêmes, confrontés aux motifs : un dossier ou un fichier nommé d'après un client fuit
  # autant que son contenu. Le chemin fautif n'est jamais affiché, il contient le motif.
  prc=0
  printf '%s\n' "$listing" | grep -q -i -F -f "$patterns_text" || prc=$?
  if ((prc > 1)); then
    fail "recherche des motifs dans les chemins impossible dans $label"
    return 0
  fi
  if ((prc == 0)); then
    local names=""
    while IFS= read -r entry; do
      if printf '%s\n' "$listing" | grep -q -i -F -e "${entry#*:}"; then
        names+="  motif ligne ${entry%%:*}"$'\n'
      fi
    done < "$patterns"
    fail "chemin qui reprend un motif dans $label (chemin masqué) :\n${names%$'\n'}"
  fi
  # un seul passage avec tous les motifs ; le détail motif par motif seulement s'il trouve.
  # Un objet illisible donne une erreur mais le code 1 (« rien trouvé ») : toute erreur fait échouer.
  err=$(git grep -q -I -i -F -f "$patterns_text" "$@" -- . 2>&1 >/dev/null) || rc=$?
  if ((rc > 1)) || [[ -n $err ]]; then
    fail "recherche impossible dans $label (code $rc)"
    return 0
  fi
  ((rc == 0)) || return 0
  while IFS= read -r entry; do
    # -z sépare fichier, ligne et contenu par NUL : cut garde fichier et ligne, jamais le contenu
    hits+=$(git grep -z -I -n -i -F -e "${entry#*:}" "$@" -- . \
      | tr '\0' '\001' | cut -d "$sep" -f1-2 | tr '\001' ':' \
      | sed "s/\$/ (motif ligne ${entry%%:*})/" || true)$'\n'
  done < "$patterns"
  hits=$(printf '%s' "$hits" | grep -v '^$' | sort -u || true)
  fail "contenu privé dans $label (contenu masqué) :\n$hits"
}

check_message() { # $1 = commit ; le message n'est jamais affiché
  local c=$1 label=${1:0:7} msg entry lines="" rc=0
  [[ -n $patterns ]] || return 0
  msg=$(git log -1 --format=%B "$c") || { fail "lecture impossible du message de $label"; return 0; }
  printf '%s\n' "$msg" | grep -q -i -F -f "$patterns_text" || rc=$?
  if ((rc > 1)); then
    fail "recherche impossible dans le message de $label"
    return 0
  fi
  ((rc == 0)) || return 0
  while IFS= read -r entry; do
    if printf '%s\n' "$msg" | grep -q -i -F -e "${entry#*:}"; then
      lines+="  motif ligne ${entry%%:*}"$'\n'
    fi
  done < "$patterns"
  fail "message de commit privé dans $label (message masqué) :\n${lines%$'\n'}"
}

case "$mode" in
  staged)
    check_tree "l'index" --cached
    ;;
  history)
    shift
    if (($#)); then revs=$(git rev-list "$@"); else revs=$(git rev-list --all); fi
    for c in $revs; do check_tree "${c:0:7}" "$c"; check_message "$c"; done
    ;;
  pre-receive)
    zero=0000000000000000000000000000000000000000
    while read -r _old new _ref; do
      [[ $new == "$zero" ]] && continue
      for c in $(git rev-list "$new" --not --all); do check_tree "${c:0:7}" "$c"; check_message "$c"; done
    done
    ;;
  *)
    echo "usage : $0 staged | history [<rev>...] | pre-receive" >&2
    exit 2
    ;;
esac

((status == 0)) || echo "check-private: refusé. Retire le contenu privé avant de continuer." >&2
exit "$status"
