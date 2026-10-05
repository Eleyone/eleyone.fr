# Décisions de la mise en ligne (scripts/release.sh), séparées des appels à la forge pour être
# éprouvées sur des fichiers et sur un dépôt git jetable — comme .working-method/gates/merge-gates.sh l'est
# pour les verrous de fusion.
#
# À charger par « . scripts/lib/release.sh ». Dépendances : bash, git, grep GNU.
# Les fonctions ne comptent pas sur set -e : un appel suivi de || le suspendrait pour toute la
# fonction, donc chaque étape vérifie son résultat. Elles répondent par leur code de retour et
# n'écrivent rien sur la sortie standard en cas d'erreur.
#
#   release_tag_production                 expression d'un tag de mise en ligne (vX.Y.Z)
#   release_tag_rehearsal                  expression d'un tag de répétition (vX.Y.Z-rc.N)
#   release_rc_same_tree <tag> <arbre>     cherche un tag « <tag>-rc.N » de même arbre que <arbre> :
#                                          0 trouvé (son nom dans release_rc_found), 1 aucun, 2 anomalie
#   release_unverified_commits <plage> <fichier d'amorçage> <sortie>
#                                          écrit dans <sortie> un commit par ligne — « <sha court>
#                                          <TAB> <raison> <TAB> <sujet> » — pour chaque commit de la
#                                          plage qui n'est pas le squash d'une PR : 0 lu, 2 anomalie
#   release_missing_base_pages <socle> <attendues> <sortie>
#                                          écrit dans <sortie> les clés du socle absentes de la liste
#                                          cumulative : 0 lu, 2 anomalie
#
# Les quatre suivantes sont communes aux deux chemins vers main, release et hotfix (story 11.12) :
# écrites une fois, pour qu'une garde apprise par l'un ne manque pas à l'autre (règle 8 commune).
#
#   release_find_open_pr <fonction> <tête> <base|*> <plafond> <sortie>
#                                          cherche, page par page, la PR ouverte depuis la branche
#                                          <tête> (vers <base>, ou vers toute base avec « * ») et
#                                          écrit son numéro dans <sortie>, vide si aucune : 0 lu,
#                                          2 page illisible, 3 plafond de pages atteint
#   release_private_text <motifs> <scratch> <fichier>…
#                                          un motif privé figure-t-il dans les fichiers : 0 oui,
#                                          1 non, 2 lecture impossible
#   release_merge_response <code HTTP> <message de la forge>
#                                          classe la réponse d'une fusion fast-forward-only : écrit
#                                          ok, retry, style, diverging ou refused ; rend 0
#   release_push_tag <tag> <commit> <message>
#                                          pose le tag annoté et le pousse sur origin : 0 poussé,
#                                          1 création impossible, 2 push refusé et tag local retiré,
#                                          3 push refusé et tag local resté en place
#
# Procédure : docs/procedures/release.md, docs/procedures/hotfix.md

release_lib_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 2
# shell.sh vit dans l'outillage commun (sous-module .working-method, story outillage-14)
# shellcheck source=../../.working-method/lib/shell.sh
. "$release_lib_dir/../../.working-method/lib/shell.sh"

# Les deux canaux, en expressions **disjointes** et ancrées, sans zéro de tête. Le même couple vit
# dans scripts/release/ship.sh et dans deploy/remote/deploy-site.sh, qui est recopié seul sur le
# serveur de production et ne peut donc rien partager avec le dépôt : un cas de test tient les trois
# égaux (scripts/tests/test-release.sh, point 19 d'AGENTS.md).
readonly release_tag_production='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
readonly release_tag_rehearsal='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)-rc\.(0|[1-9][0-9]*)$'

# « même arbre » et non « même commit » : la publication dev → main est un fast-forward, mais un
# hotfix ou une signature changeraient le commit sans changer une ligne du site. Les codes de
# « git diff --quiet » se distinguent comme ceux de grep : 0 aucune différence, 1 des différences,
# au-delà une erreur. <arbre> est le tag lui-même quand il existe déjà (scripts/ci/release-job.sh,
# qui tourne après le push du tag) et la tête de dev quand il reste à poser (scripts/release.sh).
release_rc_same_tree() { # $1 = tag de production, $2 = commit ou tag dont on compare l'arbre
  release_rc_found=""
  local prefix=$1 tree=$2 list rc number code
  # Le motif est un **glob littéral** : « . » n'y est pas un joker, à la différence d'une expression
  # régulière construite depuis une variable (piège connu, .working-method/procedures/shell-scripts.md).
  list=$(git tag --list "$prefix-rc.*") || return 2
  while IFS= read -r rc; do
    [[ -n $rc ]] || continue
    # Comparaison **littérale**, sans regex construite : le préfixe exact, puis un numéro entier.
    [[ $rc == "$prefix-rc."* ]] || continue
    number=${rc#"$prefix-rc."}
    [[ $number =~ ^(0|[1-9][0-9]*)$ ]] || continue
    code=0
    git diff --quiet "$tree^{tree}" "$rc^{tree}" || code=$?
    case $code in
      0) release_rc_found=$rc; return 0 ;;
      1) ;;
      *) return 2 ;;
    esac
  done <<< "$list"
  return 1
}

# Verrou de revue de la PR de publication (AD-24, D-13). Le marqueur « (#N) » ne prouve pas qu'une
# PR a été relue : Gitea l'ajoute à **tout** squash. Il prouve seulement que le commit est un squash
# de la forge, et non un commit poussé directement. Ce qui distingue les squashs déjà vérifiés des
# autres, c'est la **liste d'amorçage** : elle énumère nommément les seuls squashs fusionnés à la
# main, avant que verify-and-merge-pr existe (décision d'Arnaud du 25/09/2026). Tout autre commit de
# la plage doit donc porter le marqueur **et** n'avoir qu'un parent — un commit de fusion, que le
# flux linéaire interdit, porte lui aussi « (#N) » dans le message que Gitea lui compose.
#
# Une liste d'amorçage vide est admise : elle rend le verrou plus strict, jamais plus permissif.
# Un SHA mal formé, en revanche, est une anomalie : silencieusement ignoré, il transformerait une
# faute de frappe en exemption perdue, ou pire en exemption accordée à un préfixe.
release_unverified_commits() { # $1 = plage, $2 = fichier d'amorçage, $3 = fichier de sortie
  local range=$1 bootstrap=$2 out=$3
  local entries="" shas="" line sha parents subject code
  : > "$out" || return 2
  [[ -f $bootstrap ]] || return 2
  code=0
  shell_grep_status entries -vE -- '^[[:space:]]*(#|$)' "$bootstrap" || code=$?
  ((code <= 1)) || return 2
  while IFS= read -r line; do
    [[ -n $line ]] || continue
    sha=${line%%[[:space:]]*}
    [[ $sha =~ ^[0-9a-f]{40}$ ]] || return 2
    shas+="$sha"$'\n'
  done <<< "$entries"
  local log
  log=$(git log --format='%H%x09%P%x09%s' "$range") || return 2
  while IFS=$'\t' read -r sha parents subject; do
    [[ -n $sha ]] || continue
    [[ $'\n'$shas != *$'\n'$sha$'\n'* ]] || continue
    if [[ $parents == *' '* ]]; then
      printf '%s\t%s\t%s\n' "${sha:0:7}" "commit de fusion (plusieurs parents)" "$subject" >> "$out" || return 2
    elif [[ ! $subject =~ \ \(#[1-9][0-9]*\)$ ]]; then
      printf '%s\t%s\t%s\n' "${sha:0:7}" "aucun numéro de PR dans le sujet" "$subject" >> "$out" || return 2
    fi
  done <<< "$log"
  return 0
}

# Complétude du socle, vérifiée pour v1.0.0 seulement (FR-32, D-5). Le fichier de référence est la
# liste **figée** des pages du socle ; la liste cumulative, elle, grandit à chaque page publiée. Une
# liste de référence vide est refusée comme un fichier de motifs sans motif : elle ferait passer le
# contrôle sans rien vérifier.
release_missing_base_pages() { # $1 = liste du socle, $2 = liste cumulative, $3 = fichier de sortie
  local base=$1 expected=$2 out=$3 keys="" key found code
  : > "$out" || return 2
  [[ -f $base && -f $expected ]] || return 2
  code=0
  shell_grep_status keys -vE -- '^[[:space:]]*(#|$)' "$base" || code=$?
  ((code <= 1)) || return 2
  [[ -n $keys ]] || return 2
  while IFS= read -r key; do
    [[ -n $key ]] || continue
    [[ $key =~ ^[a-z0-9][a-z0-9-]*$ ]] || return 2
    code=0
    shell_grep_status found -qxF -- "$key" "$expected" || code=$?
    ((code <= 1)) || return 2
    ((code == 0)) || { printf '%s\n' "$key" >> "$out" || return 2; }
  done <<< "$keys"
  return 0
}

# --- communs à release et hotfix (story 11.12) ------------------------------------------------------

# La liste des PR ouvertes se lit par pages de 50 : la PR cherchée peut être au-delà de la première.
# <fonction> écrit la page <numéro> dans <fichier> : le script lui fait appeler la forge (et meurt
# lui-même sur un code HTTP inattendu), les tests lui font lire des fixtures — comme
# read_timeline_reports de .working-method/gates/merge-gates.sh. Le résultat va dans un fichier, et
# non sur la sortie standard : appelée dans « $(…) », la fonction de lecture ne pourrait pas arrêter
# le script sur une erreur de la forge (piège connu, .working-method/procedures/shell-scripts.md).
release_find_open_pr() { # $1 fonction, $2 branche de tête, $3 base ou « * », $4 plafond de pages, $5 sortie
  local fetch=$1 head=$2 base=$3 max=$4 out=$5 page=1 number count
  [[ $max =~ ^[1-9][0-9]*$ && -n $head && -n $base ]] || return 2
  : > "$out" || return 2
  while :; do
    ((page <= max)) || { rm -f "$out.page"; return 3; }
    "$fetch" "$page" "$out.page" || { rm -f "$out.page"; return 2; }
    number=$(jq -r --arg h "$head" --arg b "$base" \
      '[.[] | select(.head.ref == $h and ($b == "*" or .base.ref == $b)) | .number] | first // empty' \
      "$out.page" 2>/dev/null) || { rm -f "$out.page"; return 2; }
    if [[ -n $number ]]; then
      rm -f "$out.page"
      [[ $number =~ ^[1-9][0-9]*$ ]] || return 2
      printf '%s\n' "$number" > "$out" || return 2
      return 0
    fi
    count=$(jq 'length' "$out.page" 2>/dev/null) || { rm -f "$out.page"; return 2; }
    [[ $count =~ ^[0-9]+$ ]] || { rm -f "$out.page"; return 2; }
    ((count == 50)) || break
    page=$((page + 1))
  done
  rm -f "$out.page"
  return 0
}

# Le titre et le corps d'une PR partent sur la forge, et de là sur le miroir public : ils passent la
# liste des motifs avant l'envoi, comme le fait create-pull-request. Les codes de grep sont lus,
# jamais avalés : 1 « aucun motif » n'est pas 2 « fichier illisible ».
release_private_text() { # $1 fichier de motifs, $2 fichier de travail, $3… fichiers à vérifier
  local patterns=$1 scratch=$2 code=0
  shift 2
  (($# > 0)) || return 2
  grep -vE '^[[:space:]]*(#|$)' "$patterns" > "$scratch" 2>/dev/null || code=$?
  ((code <= 1)) || return 2
  # un fichier de motifs sans motif est refusé en amont (require_patterns_file) ; ici, il ne
  # trouverait rien, et ne doit pas pour autant passer pour une vérification faite
  [[ -s $scratch ]] || return 2
  code=0
  grep -qiF -f "$scratch" -- "$@" || code=$?
  case $code in
    0) return 0 ;;
    1) return 1 ;;
    *) return 2 ;;
  esac
}

# Réponses constatées de l'API de fusion (AD-24, docs/procedures/gitea-branches.md) : 200 fusionné ;
# 405 « Please try again later », transitoire juste après le déplacement de la base ; 405 autre, un
# style refusé ; 500 DivergingFastForwardOnly, la base a divergé. Les deux 405 se distinguent par le
# message, jamais par le code.
release_merge_response() { # $1 code HTTP, $2 message de la forge
  local code=$1 message=${2,,}
  case $code in
    200) printf 'ok\n' ;;
    405)
      if [[ $message == *"try again later"* ]]; then printf 'retry\n'; else printf 'style\n'; fi
      ;;
    500)
      if [[ $message == *divergingfastforwardonly* ]]; then printf 'diverging\n'; else printf 'refused\n'; fi
      ;;
    *) printf 'refused\n' ;;
  esac
  return 0
}

# Le tag poussé déclenche le workflow release : c'est le dernier geste, et le plus lourd. Si le push
# échoue, le tag local est retiré pour qu'une reprise le repose sur le même commit ; un tag local
# resté en place se dit par un code à part, pour que le message de l'appelant décrive la situation
# que l'opérateur retrouvera. Les messages de git restent muets : ils portent l'adresse de la forge
# (NFR-9).
release_push_tag() { # $1 tag, $2 commit, $3 message du tag
  local tag=$1 commit=$2 message=$3
  git tag -a "$tag" -m "$message" "$commit" > /dev/null 2>&1 || return 1
  git push --quiet origin "refs/tags/$tag" > /dev/null 2>&1 && return 0
  git tag -d "$tag" > /dev/null 2>&1 || return 3
  return 2
}
