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
# **L'interdiction des CV PDF est levée depuis la story 7.3**, et seulement pour les **deux noms
# qu'AD-21 connaît** : le garde-fou lit désormais le texte, les métadonnées et le XMP de chaque PDF
# poussé ou indexé, par scripts/lib/pdf.sh. Tout autre PDF sous assets/cv/ reste un chemin interdit
# — AD-21 n'en prévoit pas, et ce que le hook ne sait pas nommer, il le refuse.
# L'interdiction des extensions d'images est **levée sous assets/** depuis la story 5.4 : C20 y lit
# désormais les métadonnées de chaque image, dans le hook comme en CI (AD-19, AD-12). Ailleurs elle
# tient : C20 sait dire qu'une image ne porte pas de données de prise de vue, pas ce qu'elle montre.
# Le périmètre a été arbitré par Arnaud le 21/09/2026.
# .env est refusé seul ou suffixé (.env.production, .env.local) ; .environment.md est admis.
# Trois exceptions nommées : .env.example, commité par conception (AGENTS.md) et sans aucune valeur ;
# les captures des branches de design (design/<branche>/screenshots/), déjà publiées et produites par un
# navigateur ; et les images d'assets/, que C20 contrôle.
# C20 et la liste des extensions d'images vivent dans scripts/lib/image.sh, copiée à côté de ce
# script sur la forge (procédure du hook). Son absence **refuse** : un garde-fou qui s'ignore en
# silence ne garde rien. Elle est chargée **avant** les motifs, qui en dérivent.
image_lib="$(dirname "${BASH_SOURCE[0]}")/lib/image.sh"
if [[ -r $image_lib ]]; then
  . "$image_lib"
else
  echo "check-private: scripts/lib/image.sh absent ou illisible ($image_lib) : C20 ne peut pas s'exécuter." >&2
  exit 1
fi
# Même règle pour la lecture des PDF (story 7.3) : son absence refuse, plutôt que de laisser passer
# un CV dont personne n'aurait lu les métadonnées.
pdf_lib="$(dirname "${BASH_SOURCE[0]}")/lib/pdf.sh"
if [[ -r $pdf_lib ]]; then
  . "$pdf_lib"
else
  echo "check-private: scripts/lib/pdf.sh absent ou illisible ($pdf_lib) : les PDF ne peuvent pas être lus." >&2
  exit 1
fi
images_ext=$(image_extensions_regex)
forbidden_paths="^docs/(private|context)/|(^|/)\.env($|\.)|^assets/cv/.*\.pdf$|\.$images_ext\$"
allowed_paths="(^|/)\.env\.example\$|^design/[^/]+/screenshots/|^assets/.*\.$images_ext\$|^assets/cv/cv-(fr|en)\.pdf\$"
# Les chemins que C20 doit lire : les images admises ci-dessus.
image_paths="^assets/.*\.$images_ext\$"
# Ceux que la lecture des PDF doit lire : les deux CV admis, et eux seuls.
pdf_paths="^assets/cv/cv-(fr|en)\.pdf\$"
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
# **Un seul fichier temporaire pour tout le script**, réutilisé, nettoyé une fois à la sortie.
#
# Trois écritures ont été nécessaires pour arriver là, et les trois ratées se ressemblent : un
# « rm » final ne couvre pas un arrêt en chemin ; un « trap … RETURN » posé dans une fonction se
# déclenche au retour de la **suivante** ; et un « mktemp » par appel écrase la variable, si bien
# que le nettoyage n'emporte que le dernier — or le mode pre-receive appelle une fois **par
# commit poussé**, donc un push de dix commits laissait neuf CV extraits sur la forge (constats de
# la story 7.1, de l'essai sur un vrai dépôt, et de la revue du code de la PR n° 86).
#
# La quatrième écriture est la bonne parce qu'elle n'est plus astucieuse : le fichier est créé
# **une fois, tout de suite**, et nettoyé une fois. Une variante « à la demande » par fonction
# paraissait plus économe ; appelée en « $(…) », elle tournait dans un sous-shell et son
# affectation était perdue, si bien que chaque appel créait un fichier que plus personne ne
# connaissait. Mesuré : un fichier de 297 octets — le PDF extrait — laissé par un seul push.
#
# Le coût est un fichier vide quand il n'y a ni image ni PDF à lire. C'est le prix de n'avoir
# plus rien à compter.
blob_temporaire=$(mktemp) || { echo "check-private: fichier temporaire impossible." >&2; exit 2; }
nettoyer() {
  rm -f "$blob_temporaire"
  [[ -z $patterns ]] || rm -f "$patterns" "$patterns_text"
}
trap nettoyer EXIT
sep=$'\001' # séparateur des champs de git grep -z : absent des noms de fichier, contrairement à la tabulation

fail() { printf 'check-private: %b\n' "$*" >&2; status=1; }

patterns=""
if [[ -f $patterns_file ]]; then
  patterns=$(mktemp)
  patterns_text=$(mktemp)
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
# Les PDF poussés ou indexés, confrontés à la liste (AD-21, story 7.3). Le garde-fou ne peut pas
# chercher dans un binaire — « git grep -I » les ignore —, donc chaque CV est extrait dans un
# fichier temporaire et lu par poppler.
#
# **Le fichier temporaire est supprimé quoi qu'il arrive** : un PDF extrait qui survit sur la forge
# est une fuite, et le disque finirait par saturer. Le nettoyage est posé à la sortie du script,
# pas au retour de cette fonction, et couvre donc aussi un arrêt en chemin — ce qu'un « rm » final
# ne ferait pas (constat de la revue de spec, et leçon de la story 7.1 où un « exec » avait annulé
# un nettoyage).
#
# L'absence de poppler **refuse le push** plutôt que de le laisser passer : un PDF non lu ne vaut
# pas un PDF propre.
check_pdfs() { # $1 = libellé, $2 = révision (« --cached » pour l'index), $3 = liste des chemins
  local label=$1 rev=$2 listing=$3 fichiers chemin prc=0 blob manquant source extrait
  [[ -n $patterns ]] || return 0
  fichiers=$(printf '%s\n' "$listing" | grep -E -i "$pdf_paths") || prc=$?
  ((prc <= 1)) || { fail "recherche des PDF impossible dans $label"; return 0; }
  [[ -n $fichiers ]] || return 0
  if manquant=$(pdf_missing_tool); then
    fail "$manquant absent (paquet poppler-utils) : un PDF de $label ne peut pas être lu"
    return 0
  fi
  blob=$blob_temporaire
  while IFS= read -r chemin; do
    [[ -n $chemin ]] || continue
    if [[ $rev == --cached ]]; then
      git cat-file blob ":$chemin" > "$blob" 2>/dev/null || { fail "lecture impossible d'un PDF de $label"; continue; }
    else
      git cat-file blob "$rev:$chemin" > "$blob" 2>/dev/null || { fail "lecture impossible d'un PDF de $label"; continue; }
    fi
    pdf_has_header "$blob" || { fail "ce n'est pas un PDF dans $label : $chemin"; continue; }
    # Les trois sources, parce qu'un téléphone se cache plus souvent dans les métadonnées d'un
    # export que dans le texte que le lecteur voit (FR-38).
    for source in texte métadonnées XMP; do
      case $source in
        texte) extrait=$(pdf_text "$blob") || { fail "pdftotext ne sait pas lire un PDF de $label : $chemin"; continue 2; } ;;
        métadonnées) extrait=$(pdf_metadata "$blob") || { fail "pdfinfo ne sait pas lire un PDF de $label : $chemin"; continue 2; } ;;
        XMP) extrait=$(pdf_xmp "$blob") ;;
      esac
      check_extract "$label" "$chemin" "$source" "$extrait"
    done
  done <<< "$fichiers"
}

# Un extrait confronté à la liste, sans que rien de ce qu'il contient ne soit affiché : le fichier
# et la source sont nommés, le motif cité par son numéro de ligne.
check_extract() { # $1 = libellé, $2 = chemin, $3 = source, $4 = extrait
  local label=$1 chemin=$2 source=$3 extrait=$4 rc=0 entry lignes="" trouve
  [[ -n $extrait ]] || return 0
  printf '%s\n' "$extrait" | grep -q -i -F -f "$patterns_text" || rc=$?
  ((rc <= 1)) || { fail "recherche des motifs impossible dans $source d'un PDF de $label"; return 0; }
  ((rc == 0)) || return 0
  while IFS= read -r entry; do
    trouve=0
    printf '%s\n' "$extrait" | grep -q -i -F -e "${entry#*:}" || trouve=$?
    ((trouve <= 1)) || { fail "recherche d'un motif impossible dans $source d'un PDF de $label"; return 0; }
    ((trouve == 0)) && lignes+=" ${entry%%:*}"
  done < "$patterns"
  fail "contenu privé dans $source d'un PDF de $label (contenu masqué) : $chemin ; motif ligne${lignes}"
}

check_images() { # $1 = libellé, $2 = révision (« --cached » pour l'index), $3 = liste des chemins
  local label=$1 rev=$2 listing=$3 images chemin marqueurs prc=0 blob
  images=$(printf '%s\n' "$listing" | grep -E -i "$image_paths") || prc=$?
  ((prc <= 1)) || { fail "recherche des images impossible dans $label"; return 0; }
  [[ -n $images ]] || return 0
  blob=$blob_temporaire
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
  check_pdfs "$label" "$1" "$listing"
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
    local names="" trouve
    while IFS= read -r entry; do
      # Le code de grep est lu : dans un « if … | grep -q …; then », un code 2 se lirait « pas
      # trouvé », et le motif manquerait sans un mot. Même classe d'erreur que celle trouvée dans
      # pdf.sh à la même revue — deux occurrences de plus, ici, dans le garde-fou lui-même
      # (quatrième revue du code de la PR n° 84).
      trouve=0
      printf '%s\n' "$listing" | grep -q -i -F -e "${entry#*:}" || trouve=$?
      ((trouve <= 1)) || { fail "recherche d'un motif impossible dans $label (code $trouve)"; return 0; }
      ((trouve == 0)) && names+="  motif ligne ${entry%%:*}"$'\n'
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
  local trouve
  while IFS= read -r entry; do
    trouve=0
    printf '%s\n' "$msg" | grep -q -i -F -e "${entry#*:}" || trouve=$?
    ((trouve <= 1)) || { fail "recherche d'un motif impossible dans le message de $label (code $trouve)"; return 0; }
    ((trouve == 0)) && lines+="  motif ligne ${entry%%:*}"$'\n'
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
