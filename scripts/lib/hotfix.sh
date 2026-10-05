# shellcheck shell=bash
# Décisions du correctif de production (scripts/hotfix.sh, story 11.12), séparées des appels à la
# forge pour être éprouvées sur un dépôt git jetable — comme scripts/lib/release.sh l'est pour la
# mise en ligne, dont celle-ci charge les expressions de tags et les fonctions communes.
#
# À charger par « . scripts/lib/hotfix.sh ». Dépendances : bash, git, sed, jq.
# Les fonctions ne comptent pas sur set -e : un appel suivi de || le suspendrait pour toute la
# fonction, donc chaque étape vérifie son résultat. Elles répondent par leur code de retour et
# n'écrivent rien sur la sortie standard en cas d'erreur.
#
#   hotfix_branch_prefix                   préfixe réservé aux branches issues de main (D-14)
#   hotfix_slug_pattern                    expression d'un nom de correctif : kebab-case, qui commence
#                                          par une lettre — une branche hotfix/* ne porte jamais de
#                                          numéro de story (AGENTS.md, point 1)
#   hotfix_next_tag <révision>             calcule le tag suivant : le plus haut vX.Y.Z atteignable
#                                          depuis <révision>, correctif + 1. Remplit hotfix_tag_last
#                                          et hotfix_tag_next : 0 calculé, 1 aucun vX.Y.Z, 2 anomalie
#   hotfix_rebase_dir                      dossier d'un rebase en cours dans ce dépôt, dans
#                                          hotfix_rebase_path : 0 en cours, 1 aucun, 2 anomalie
#   hotfix_state_read <fichier>            lit l'état d'une synchronisation entamée, dans
#                                          hotfix_state_lease et hotfix_state_main : 0 lu, 1 absent,
#                                          2 illisible ou mal formé
#   hotfix_state_write <fichier> <bail> <main>
#                                          écrit cet état : 0 écrit, 2 impossible
#   hotfix_mask_remote                     filtre : remplace les adresses de dépôt distant par
#                                          « <adresse> » dans le texte lu sur l'entrée standard
#   hotfix_open_prs <fonction> <base> <plafond> <sortie>
#                                          écrit dans <sortie> une ligne « numéro TAB branche TAB
#                                          SHA de tête » par PR ouverte vers <base>, toutes pages
#                                          lues : 0 lu, 2 page illisible, 3 plafond atteint
#
# Procédure : docs/procedures/hotfix.md

hotfix_lib_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 2
# release.sh porte les expressions des deux canaux de tags et les fonctions communes aux deux chemins
# vers main ; il charge lui-même shell.sh. Une seule expression de tag dans tout le dépôt côté poste.
# shellcheck source=release.sh
. "$hotfix_lib_dir/release.sh"

# shellcheck disable=SC2034 # lue par scripts/hotfix.sh, qui charge cette bibliothèque
readonly hotfix_branch_prefix=hotfix/
# shellcheck disable=SC2034 # lue par scripts/hotfix.sh, qui charge cette bibliothèque
readonly hotfix_slug_pattern='^[a-z][a-z0-9]*(-[a-z0-9]+)*$'

# Q4 de la story 11.12 : le numéro est **calculé**, jamais donné. Seuls comptent les tags de
# production (release_tag_production) : un vX.Y.Z-rc.N, posé sur dev par une répétition, n'est
# jamais retenu comme dernière version, même s'il est atteignable depuis main après une publication.
# La comparaison est numérique, champ par champ : v1.10.0 est plus haut que v1.9.9, ce qu'un tri de
# texte dirait à l'envers.
hotfix_next_tag() { # $1 révision dont on lit les tags atteignables (origin/main)
  hotfix_tag_last="" hotfix_tag_next=""
  local rev=$1 list tag major minor patch best_major=-1 best_minor=-1 best_patch=-1
  list=$(git tag --list 'v*' --merged "$rev" 2>/dev/null) || return 2
  while IFS= read -r tag; do
    [[ -n $tag ]] || continue
    [[ $tag =~ $release_tag_production ]] || continue
    major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=${BASH_REMATCH[3]}
    if ((major > best_major || (major == best_major && minor > best_minor) \
      || (major == best_major && minor == best_minor && patch > best_patch))); then
      best_major=$major best_minor=$minor best_patch=$patch hotfix_tag_last=$tag
    fi
  done <<< "$list"
  [[ -n $hotfix_tag_last ]] || return 1
  # shellcheck disable=SC2034 # résultat lu par scripts/hotfix.sh
  hotfix_tag_next="v$best_major.$best_minor.$((best_patch + 1))"
  return 0
}

# Un rebase arrêté sur un conflit laisse son dossier dans le dossier git **de cet arbre de travail**
# (« git rev-parse --git-path » le situe aussi dans un worktree) : rebase-merge pour le moteur par
# défaut, rebase-apply pour l'ancien.
hotfix_rebase_dir() {
  hotfix_rebase_path=""
  local name path
  for name in rebase-merge rebase-apply; do
    path=$(git rev-parse --git-path "$name" 2>/dev/null) || return 2
    [[ -n $path ]] || return 2
    if [[ -d $path ]]; then
      # shellcheck disable=SC2034 # résultat lu par scripts/hotfix.sh
      hotfix_rebase_path=$path
      return 0
    fi
  done
  return 1
}

# L'état d'une synchronisation tient en deux SHA, lus **avant** le rebase : la tête de origin/dev,
# qui sera la valeur du bail du push forcé, et celle de origin/main, sur laquelle dev est rebasée.
# Il survit entre deux lancements (conflit résolu à la main, puis « sync --push » lancé plus tard par
# Arnaud) : relu après coup, origin/dev pourrait avoir bougé, et un bail relu à ce moment-là
# validerait précisément le push concurrent qu'il doit refuser.
hotfix_state_read() { # $1 fichier d'état
  hotfix_state_lease="" hotfix_state_main=""
  local file=$1 line key value lease="" main=""
  [[ -e $file ]] || return 1
  [[ -f $file && -r $file ]] || return 2
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -n $line ]] || continue
    key=${line%%=*} value=${line#*=}
    case $key in
      lease) [[ -z $lease ]] || return 2; lease=$value ;;
      main) [[ -z $main ]] || return 2; main=$value ;;
      *) return 2 ;;
    esac
  done < "$file" || return 2
  [[ $lease =~ ^[0-9a-f]{40}$ && $main =~ ^[0-9a-f]{40}$ ]] || return 2
  # shellcheck disable=SC2034 # résultats lus par scripts/hotfix.sh
  hotfix_state_lease=$lease hotfix_state_main=$main
  return 0
}

hotfix_state_write() { # $1 fichier d'état, $2 SHA de origin/dev (bail), $3 SHA de origin/main
  [[ $2 =~ ^[0-9a-f]{40}$ && $3 =~ ^[0-9a-f]{40}$ ]] || return 2
  printf 'lease=%s\nmain=%s\n' "$2" "$3" > "$1" 2>/dev/null || return 2
  return 0
}

# Les messages de git nomment le dépôt distant : « To ssh://git@<hôte>/… », « failed to push some
# refs to '<hôte>:…' ». NFR-9 tient l'adresse de la forge hors de tout ce qui s'affiche : une adresse
# à schéma (« ssh:// », « https:// », « file:// ») ou de la forme « compte@hôte: » est remplacée.
hotfix_mask_remote() {
  sed -E 's#[a-zA-Z][a-zA-Z0-9+.-]*://[^[:space:]'"'"'"]+#<adresse>#g; s#[^[:space:]'"'"'"@]+@[^[:space:]'"'"'":]+:[^[:space:]'"'"'"]*#<adresse>#g'
}

# Après le push forcé de dev, chaque PR ouverte vers dev est à rebaser puis à relire (D-14) : la liste
# est lue en entier, page par page, avec la fonction que le script fait appeler la forge — comme
# release_find_open_pr. Une ligne mal formée est une anomalie : la liste sert à écrire des commandes.
hotfix_open_prs() { # $1 fonction, $2 base, $3 plafond de pages, $4 sortie
  local fetch=$1 base=$2 max=$3 out=$4 page=1 count lines line number branch sha
  [[ $max =~ ^[1-9][0-9]*$ && -n $base ]] || return 2
  : > "$out" || return 2
  while :; do
    ((page <= max)) || { rm -f "$out.page"; return 3; }
    "$fetch" "$page" "$out.page" || { rm -f "$out.page"; return 2; }
    lines=$(jq -r --arg b "$base" \
      '.[] | select(.base.ref == $b) | [(.number | tostring), .head.ref, .head.sha] | @tsv' \
      "$out.page" 2>/dev/null) || { rm -f "$out.page"; return 2; }
    while IFS= read -r line; do
      [[ -n $line ]] || continue
      IFS=$'\t' read -r number branch sha <<< "$line"
      [[ $number =~ ^[1-9][0-9]*$ && $sha =~ ^[0-9a-f]{40}$ && -n $branch ]] || { rm -f "$out.page"; return 2; }
      printf '%s\t%s\t%s\n' "$number" "$branch" "$sha" >> "$out" || { rm -f "$out.page"; return 2; }
    done <<< "$lines"
    count=$(jq 'length' "$out.page" 2>/dev/null) || { rm -f "$out.page"; return 2; }
    [[ $count =~ ^[0-9]+$ ]] || { rm -f "$out.page"; return 2; }
    ((count == 50)) || break
    page=$((page + 1))
  done
  rm -f "$out.page"
  return 0
}
