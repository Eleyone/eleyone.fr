#!/usr/bin/env bash
# Corrige la production sans merge commit ni cherry-pick : branche hotfix/* tirée de main, fusion en
# fast-forward, tag vX.Y.(Z+1), puis dev rebasée sur main (AD-24, D-14, story 11.12).
#
#   hotfix.sh start <nom>       crée hotfix/<nom> depuis origin/main et s'y place ; ne pousse rien
#   hotfix.sh publish           audit : ouvre la PR hotfix/<nom> → main si besoin, affiche chaque verrou
#   hotfix.sh publish --merge   fusionne en fast-forward-only, puis pose et pousse le tag calculé
#   hotfix.sh sync              rebase une dev locale, tirée de origin/dev, sur origin/main ; ne pousse rien
#   hotfix.sh sync --push       pousse dev par --force-with-lease, puis liste les PR vers dev à reprendre
#
# Code de sortie : 0 l'étape est faite, ou tous les verrous passent, ou il n'y a rien à synchroniser ;
# 1 refus (nom ou branche refusés, invariant rompu, verrou bloquant, refus de la forge, conflit de
# rebase à résoudre, push refusé) ; 2 anomalie (usage, outil absent, .env absent, fichier de motifs
# absent, forge injoignable, réponse illisible, état incohérent après une fusion ou un push).
#
# **--merge et --push sont l'affaire d'Arnaud** (arbitrage Q2) : le script ne les déduit jamais et
# ne pose aucune question au clavier. Sans eux, il ne fusionne, ne tague et ne pousse rien, et dit
# l'état. Il n'a aucune option --force, n'envoie jamais force_merge ni merge_when_checks_succeed, ne
# supprime aucune branche et n'emploie **jamais cherry-pick** : un commit recopié casserait le
# fast-forward suivant (ADR-18).
#
# **Les deux points dangereux.** Le tag, d'abord, comme dans release : la fusion passe par l'API et
# ne met pas à jour le dépôt local, donc le script relit main sur la forge et refuse de taguer si
# origin/main ne porte pas la tête fusionnée. Le push forcé de dev, ensuite : son bail porte la tête
# de origin/dev **lue avant le rebase** et conservée entre deux lancements, jamais relue au moment du
# push — un push concurrent sur dev est refusé par git au lieu d'être écrasé.
# Procédure : docs/procedures/hotfix.md
set -euo pipefail
set +x # même lancé avec bash -x, la trace s'arrête ici, avant la lecture du jeton

script_name=hotfix
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# L'adaptateur de la forge et les décisions des verrous vivent dans l'outillage commun (sous-module
# .working-method) ; l'adaptateur exige le lecteur de workflow.config.
# shellcheck source=../.working-method/lib/config.sh
. "$script_dir/../.working-method/lib/config.sh"
# shellcheck source=../.working-method/gitea/gitea.sh
. "$script_dir/../.working-method/gitea/gitea.sh"
# shellcheck source=../.working-method/gates/merge-gates.sh
. "$script_dir/../.working-method/gates/merge-gates.sh"
# hotfix.sh charge release.sh : expressions des tags et fonctions communes aux deux chemins vers main
# shellcheck source=lib/hotfix.sh
. "$script_dir/lib/hotfix.sh"

# gitea.sh définit die() avec le code 1 ; ici 1 est réservé aux refus, et 2 dit l'anomalie, comme
# dans release.sh et verify-and-merge-pr.sh.
die() { printf '%s: %b\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %b\n' "$script_name" "$*" >&2; exit 1; }

readonly max_pr_pages=100
readonly max_timeline_pages=100
readonly retry_max=5     # reprises d'un 405 « try again later » et d'un « mergeable » encore nul
readonly retry_delay=3   # secondes entre deux reprises ; les tests posent un faux sleep en tête de PATH
readonly sprint_consistency=.working-method/gates/sprint-consistency.sh
readonly usage="usage : hotfix.sh start <nom> | hotfix.sh publish [--merge] | hotfix.sh sync [--push]"

require_tools

# --- les arguments ---------------------------------------------------------------------------------
(($#)) || die "$usage"
command=$1
shift
slug="" merge="" push=""
case $command in
  start)
    (($# == 1)) || die "$usage"
    [[ $1 != -* ]] || die "option inconnue : $(printf '%q' "$1"). $usage"
    slug=$1
    # Le nom devient une branche, puis un titre de PR : kebab-case, une lettre en tête. Une lettre en
    # tête interdit aussi un numéro de story — une branche hotfix/* n'en porte jamais (AGENTS.md,
    # point 1) : elle ne livre pas une story, elle corrige la production.
    [[ $slug =~ $hotfix_slug_pattern ]] \
      || die "nom $(printf '%q' "$slug") refusé : minuscules, chiffres et tirets, une lettre en tête (exemple : lien-cv-casse). $usage"
    ;;
  publish | sync)
    while (($#)); do
      case $command:$1 in
        publish:--merge) [[ -z $merge ]] || die "$usage"; merge=1; shift ;;
        sync:--push) [[ -z $push ]] || die "$usage"; push=1; shift ;;
        *) die "option inconnue : $(printf '%q' "$1"). $usage" ;;
      esac
    done
    ;;
  *) die "sous-commande inconnue : $(printf '%q' "$command"). $usage" ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || die "à lancer dans le dépôt."
cd "$root"
# workflow.config, lu par l'outillage commun : le dépôt canonique, les deux branches, la CI
config_load "$root/workflow.config" || exit 2
gitea_configure
base_branch="" release_branch="" ci_workflow="" ci_context="" forge_env_file=""
config_get base_branch forge.base
config_get release_branch forge.release-branch
config_get ci_workflow ci.workflow
config_get ci_context ci.status-context
config_get forge_env_file forge.env-file
readonly base_branch release_branch ci_workflow ci_context forge_env_file
[[ $release_branch != none ]] || die "forge.release-branch = none : sans branche de publication, il n'y a pas de production à corriger."
check_origin

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- outils communs aux trois sous-commandes --------------------------------------------------------

# « --is-ancestor » répond par son code, et les trois réponses se distinguent : 0 descend, 1 ne
# descend pas, au-delà une anomalie — jamais confondue avec un « non ».
is_ancestor() { # $1 ancêtre présumé, $2 descendant présumé : 0 oui, 1 non ; meurt sur une anomalie
  local code=0
  git merge-base --is-ancestor "$1" "$2" 2>/dev/null || code=$?
  ((code <= 1)) || die "« git merge-base --is-ancestor » a rendu le code $code : ni « descend » (0) ni « ne descend pas » (1). Rien n'a été fait."
  return "$code"
}

require_clean_tree() { # $1 conséquence affichée
  local pending
  pending=$(git status --porcelain 2>/dev/null) || die "lecture de l'état du dépôt impossible."
  [[ -z $pending ]] || die "modifications non commitées dans l'arbre de travail : $1"
}

# Les messages de git portent l'adresse de la forge (NFR-9) : ils restent muets, et chaque échec se
# dit par une phrase du script.
fetch_branches() { # $1 moment, pour le message
  git fetch --quiet --tags origin "$release_branch" "$base_branch" 2>/dev/null \
    || die "lecture des branches $release_branch et $base_branch sur la forge impossible ($1)."
  main_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/$release_branch^{commit}") \
    || die "origin/$release_branch introuvable après lecture sur la forge."
  dev_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/$base_branch^{commit}") \
    || die "origin/$base_branch introuvable après lecture sur la forge."
}

refuse_if_rebase_in_progress() {
  local code=0
  hotfix_rebase_dir || code=$?
  case $code in
    0) refuse "un rebase est en cours dans ce dépôt ($hotfix_rebase_path) : le terminer ou l'abandonner d'abord. Rien n'a été fait." ;;
    1) ;;
    *) die "lecture du dossier git impossible." ;;
  esac
}

load_forge() {
  load_gitea_env "$root/$forge_env_file"
  check_token_owner "$tmp/user.json"
}

# --- start -----------------------------------------------------------------------------------------
cmd_start() {
  local branch="$hotfix_branch_prefix$slug" code local_ref remote_line
  refuse_if_rebase_in_progress
  require_clean_tree "elles suivraient la branche du correctif. Rien n'a été fait."
  fetch_branches "avant de créer la branche"

  # L'invariant d'AD-24 : un correctif précédent dont dev n'a pas été rebasée laisserait main hors de
  # dev. En commencer un second empilerait deux réécritures de dev à faire d'un coup.
  if ! is_ancestor "$main_sha" "$dev_sha"; then
    refuse "$release_branch n'est pas un ancêtre de $base_branch : un correctif précédent n'a pas été synchronisé. Lancer « scripts/hotfix.sh sync », puis Arnaud lance « scripts/hotfix.sh sync --push », avant d'en commencer un autre. Rien n'a été fait."
  fi

  # Le code de « show-ref » est lu, jamais avalé : 0 la branche existe, 1 elle n'existe pas, au-delà
  # le dépôt est illisible.
  code=0
  git show-ref --verify --quiet "refs/heads/$branch" || code=$?
  case $code in
    0) refuse "la branche $branch existe déjà dans ce dépôt : choisir un autre nom, ou reprendre celle-ci. Rien n'a été fait." ;;
    1) ;;
    *) die "lecture des branches locales impossible (git show-ref, code $code). Rien n'a été fait." ;;
  esac
  remote_line=$(git ls-remote --heads origin "refs/heads/$branch" 2>/dev/null) \
    || die "lecture des branches de la forge impossible. Rien n'a été fait."
  [[ -z $remote_line ]] \
    || refuse "la branche $branch existe déjà sur la forge : choisir un autre nom. Rien n'a été fait."

  # La branche part du commit relu sur la forge, pas d'une main locale qui pourrait être en retard,
  # et sans suivi : son premier push la crée sur la forge sous son propre nom.
  git checkout --quiet --no-track -b "$branch" "$main_sha" 2>/dev/null \
    || die "création de la branche $branch impossible."
  local_ref=$(git rev-parse --verify --quiet "HEAD^{commit}") || die "relecture de la branche créée impossible."
  [[ $local_ref == "$main_sha" ]] || die "la branche $branch ne part pas de origin/$release_branch : état incohérent."

  printf '%s: branche %s créée depuis origin/%s (%s), rien n'"'"'est poussé.\n' "$script_name" "$branch" "$release_branch" "${main_sha:0:7}"
  printf 'Suite :\n'
  printf '  1. commiter le correctif sur %s (aucun fichier de story : un correctif de production ne livre pas de story) ;\n' "$branch"
  printf '  2. pousser la branche : git push -u origin %s ;\n' "$branch"
  printf '  3. scripts/hotfix.sh publish — ouvre la PR vers %s et affiche les verrous ; la revue bloque tant qu'"'"'elle n'"'"'a pas eu lieu ;\n' "$release_branch"
  printf '  4. .working-method/review/llm-review.sh <numéro de PR> — la revue du code, sur la tête de la PR ;\n'
  printf '  5. scripts/hotfix.sh publish — tous les verrous au vert, puis Arnaud lance scripts/hotfix.sh publish --merge ;\n'
  printf '  6. scripts/hotfix.sh sync, puis Arnaud lance scripts/hotfix.sh sync --push.\n'
}

# --- publish ---------------------------------------------------------------------------------------
cmd_publish() {
  local branch head_sha remote_line pushed merges count code tag rc_list pr fields
  local state draft mergeable merged base pr_branch pr_head attempt outcome forge_said
  local tag_existant tag_rc main_after

  for tool in scripts/check-private.sh "$sprint_consistency"; do
    [[ -x $root/$tool ]] || die "$tool absent ou non exécutable."
  done
  patterns_file=${PRIVATE_PATTERNS_FILE:-$root/docs/private/forbidden-patterns.txt}
  require_patterns_file "$patterns_file" "aucun correctif de production sans audit"

  refuse_if_rebase_in_progress
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) \
    || refuse "HEAD détachée : publish se lance sur la branche du correctif, hotfix/<nom>. Rien n'a été fait."
  slug=${branch#"$hotfix_branch_prefix"}
  [[ $branch == "$hotfix_branch_prefix"* && $slug =~ $hotfix_slug_pattern ]] \
    || refuse "branche $branch : publish se lance sur une branche hotfix/<nom>, créée par « scripts/hotfix.sh start <nom> ». Rien n'a été fait."
  require_clean_tree "elles ne seraient pas publiées. Rien n'a été fait."
  head_sha=$(git rev-parse --verify --quiet "HEAD^{commit}") || die "tête de la branche illisible."

  fetch_branches "avant l'audit"
  # La tête publiée est celle de la forge, et elle doit être celle qu'on a sous les yeux : une tête
  # locale en avance n'est pas relue, une tête en retard serait publiée sans qu'on l'ait vue.
  remote_line=$(git ls-remote --heads origin "refs/heads/$branch" 2>/dev/null) \
    || die "lecture des branches de la forge impossible. Rien n'a été fait."
  [[ -n $remote_line ]] \
    || refuse "la branche $branch n'est pas poussée : git push -u origin $branch, puis relancer. Rien n'a été fait."
  pushed=${remote_line%%[[:space:]]*}
  [[ $pushed == "$head_sha" ]] \
    || refuse "la tête locale de $branch (${head_sha:0:7}) n'est pas celle de la forge (${pushed:0:7}) : pousser, ou se remettre à jour, puis relancer. Rien n'a été fait."

  [[ $head_sha != "$main_sha" ]] \
    || refuse "$branch pointe sur origin/$release_branch : aucun correctif à publier. Rien n'a été fait."
  if ! is_ancestor "$main_sha" "$head_sha"; then
    refuse "$branch ne descend pas de origin/$release_branch (${main_sha:0:7}) : main a avancé depuis le début du correctif, et le fast-forward est impossible. Rebaser la branche sur origin/$release_branch, la repousser, puis relancer — la revue est à refaire sur la nouvelle tête. Rien n'a été fait."
  fi
  # Le fast-forward porte la branche telle quelle jusqu'à main : un commit de fusion y entrerait.
  merges=$(git rev-list --merges "$main_sha..$head_sha") || die "lecture des commits de la branche impossible."
  [[ -z $merges ]] \
    || refuse "$branch contient un commit de fusion (${merges:0:7}) : le flux linéaire d'AD-24 n'en admet aucun sur main. Rien n'a été fait."
  count=$(git rev-list --count "$main_sha..$head_sha") || die "comptage des commits de la branche impossible."

  # --- le tag, calculé (arbitrage Q4) ---
  code=0
  hotfix_next_tag "refs/remotes/origin/$release_branch" || code=$?
  case $code in
    0) ;;
    1) refuse "aucun tag vX.Y.Z n'est atteignable depuis origin/$release_branch : un correctif suit une mise en ligne, et la première passe par le skill release. Rien n'a été fait." ;;
    *) die "lecture des tags du dépôt impossible. Rien n'a été fait." ;;
  esac
  tag=$hotfix_tag_next
  # Même lecture que release : 0 le tag existe, 1 il n'existe pas, au-delà le dépôt est illisible.
  tag_existant="" tag_rc=0
  tag_existant=$(git rev-parse --verify --quiet "refs/tags/$tag") || tag_rc=$?
  ((tag_rc <= 1)) || die "lecture des tags du dépôt impossible (git rev-parse, code $tag_rc) : rien n'a été fait."
  [[ -z $tag_existant ]] \
    || refuse "le tag calculé $tag (après $hotfix_tag_last) existe déjà, hors de origin/$release_branch : le numéro suivant n'est pas libre, vérifier les tags sur la forge. Rien n'a été fait."
  rc_list=$(git tag --list "$tag-rc.*") || die "lecture des tags de répétition impossible."

  printf '%s: correctif %s (après %s), %s %s → %s %s, %s commit(s)\n' "$script_name" "$tag" "$hotfix_tag_last" \
    "$release_branch" "${main_sha:0:7}" "$branch" "${head_sha:0:7}" "$count"
  if [[ -n $rc_list ]]; then
    printf "%s: avertissement — une répétition porte déjà ce numéro (%s) : la prochaine mise en ligne de dev devra prendre le numéro suivant.\n" \
      "$script_name" "$(tr '\n' ' ' <<< "$rc_list" | sed 's/ $//')"
  fi

  # --- la PR du correctif ---
  load_forge
  fetch_open_page() { # $1 numéro de page, $2 fichier de réponse
    local code
    code=$(gitea_api GET "/repos/$gitea_canonical_repo/pulls?state=open&limit=50&page=$1" "$2")
    [[ $code == 200 ]] || die "lecture des PR ouvertes impossible (HTTP $code) : $(forge_message "$2")"
  }
  # Toute PR ouverte depuis la branche est retenue, quelle que soit sa base : une PR hotfix/* → dev
  # ouverte à la main doit bloquer, pas passer inaperçue à côté d'une seconde PR.
  code=0
  release_find_open_pr fetch_open_page "$branch" "*" "$max_pr_pages" "$tmp/pr-ouverte" || code=$?
  ((code != 3)) || die "liste des PR ouvertes plus longue que $max_pr_pages pages."
  ((code == 0)) || die "liste des PR ouvertes illisible."
  pr=$(cat "$tmp/pr-ouverte")

  if [[ -z $pr ]]; then
    printf 'Correctif de production %s : %s\n' "$tag" "$slug" > "$tmp/titre.txt"
    # shellcheck disable=SC2016 # accents graves du Markdown du corps, pas des substitutions
    {
      printf 'Correctif de production `%s` → `%s`, fusionné en fast-forward, sans merge commit ni\n' "$branch" "$release_branch"
      printf 'cherry-pick (AD-24, D-14).\n\n'
      printf 'Verrous appliqués par `scripts/hotfix.sh publish` (`docs/procedures/hotfix.md`) : PR fusionnable,\n'
      printf 'revue LLM sur la tête, garde-fou public/privé, CI verte sur la tête, suivi de sprint.\n\n'
      printf 'La fusion est faite par `scripts/hotfix.sh publish --merge`, lancé par Arnaud, puis le tag\n'
      printf 'calculé (`%s` à l'"'"'ouverture de cette PR) déclenche le workflow `release`. `%s` est ensuite\n' "$tag" "$base_branch"
      printf 'rebasée sur `%s` par `scripts/hotfix.sh sync --push`, lancé par Arnaud.\n' "$release_branch"
    } > "$tmp/corps.txt"
    # Le titre et le corps partent sur la forge, puis sur le miroir public : ils passent d'abord la
    # liste des motifs. Le nom du correctif est le seul morceau qui vienne de la ligne de commande.
    code=0
    release_private_text "$patterns_file" "$tmp/patterns" "$tmp/titre.txt" "$tmp/corps.txt" || code=$?
    ((code != 0)) || refuse "le titre ou le corps de la PR contient un motif privé (contenu masqué) : rien n'est ouvert."
    ((code == 1)) || die "vérification du titre et du corps impossible : rien n'est ouvert."
    jq -n --arg h "$branch" --arg b "$release_branch" --rawfile titre "$tmp/titre.txt" --rawfile corps "$tmp/corps.txt" \
      '{head: $h, base: $b, title: ($titre | rtrimstr("\n")), body: $corps}' > "$tmp/creation.json" \
      || die "préparation de la PR impossible."
    code=$(gitea_api POST "/repos/$gitea_canonical_repo/pulls" "$tmp/creee.json" "$tmp/creation.json")
    [[ $code == 201 ]] || die "la forge refuse la création de la PR (HTTP $code) : $(forge_message "$tmp/creee.json")"
    pr=$(jq -r '.number // empty' "$tmp/creee.json" 2>/dev/null) || die "réponse de la forge illisible après la création."
    [[ $pr =~ ^[1-9][0-9]*$ ]] || die "numéro de PR illisible après la création."
    printf '%s: PR n° %s ouverte : %s → %s.\n' "$script_name" "$pr" "$branch" "$release_branch"
  else
    printf '%s: PR n° %s déjà ouverte depuis %s.\n' "$script_name" "$pr" "$branch"
  fi

  read_pr() { # $1 fichier de réponse
    local code
    code=$(gitea_api GET "/repos/$gitea_canonical_repo/pulls/$pr" "$1")
    [[ $code == 200 ]] || die "PR n° $pr illisible (HTTP $code) : $(forge_message "$1")"
  }
  # Juste après la création, la forge répond « mergeable: null » le temps de calculer : attendre est
  # la seule réponse juste — bloquer serait un faux refus, passer lirait un état inconnu comme vert.
  attempt=1
  while :; do
    read_pr "$tmp/pr.json"
    fields=$(jq -er '[.state, (.draft | tostring), (.mergeable | tostring), (.merged | tostring), .base.ref, .head.ref, .head.sha] | @tsv' "$tmp/pr.json" 2>/dev/null) \
      || die "réponse de la forge illisible pour la PR n° $pr."
    IFS=$'\t' read -r state draft mergeable merged base pr_branch pr_head <<< "$fields"
    [[ $mergeable == null ]] || break
    ((attempt < retry_max)) || break
    attempt=$((attempt + 1))
    sleep "$retry_delay"
  done
  [[ $pr_head =~ ^[0-9a-f]{40}$ ]] || die "SHA de tête de la PR n° $pr illisible."

  blocked=0
  report() { # état (passe, bloque), verrou, détail
    printf '  %-7s %-16s %b\n' "$1" "$2" "$3"
    [[ $1 != bloque ]] || blocked=1
  }
  indent() { sed 's/^/            /'; }

  # --- verrou 1 : PR fusionnable ---
  if [[ $merged == true || $state != open ]]; then
    report bloque "PR fusionnable" "PR $([[ $merged == true ]] && echo "déjà fusionnée" || echo "fermée") : rien à fusionner."
    printf '%s: au moins un verrou bloque.\n' "$script_name"
    exit 1
  fi
  if [[ $base != "$release_branch" || $pr_branch != "$branch" ]]; then
    report bloque "PR fusionnable" "PR n° $pr : $pr_branch → $base, alors qu'un correctif va de $branch vers $release_branch. La fermer sur la forge, puis relancer."
  elif [[ $pr_head != "$head_sha" ]]; then
    report bloque "PR fusionnable" "la tête de la PR (${pr_head:0:7}) n'est pas celle de la branche poussée (${head_sha:0:7}) : relancer dans quelques secondes."
  elif [[ $draft == true ]]; then
    report bloque "PR fusionnable" "PR en brouillon."
  elif [[ $mergeable != true ]]; then
    report bloque "PR fusionnable" "PR non fusionnable pour la forge (mergeable=$mergeable) : relancer dans quelques secondes."
  else
    report passe "PR fusionnable" "ouverte, pas en brouillon, fusionnable, $branch → $release_branch, tête ${head_sha:0:7}."
  fi

  # --- verrou 2 : revue LLM sur la tête ---
  # Les rapports sont lus dans la timeline de la PR, page par page, avec les fonctions de
  # verify-and-merge-pr (.working-method/gates/merge-gates.sh). **Seul un rapport sur la tête elle-même
  # compte** : un correctif ne livre aucune story, donc aucun commit de statut ne peut suivre la revue,
  # et le rapport sur le parent que verify-and-merge-pr admet dans ce seul cas n'a pas d'objet ici.
  local page_size head_report model
  code=$(gitea_api GET "/settings/api" "$tmp/settings.json")
  [[ $code == 200 ]] || die "lecture des réglages de l'API impossible (HTTP $code) : $(forge_message "$tmp/settings.json")"
  page_size=$(jq -er '.max_response_items' "$tmp/settings.json" 2>/dev/null) || die "réglages de l'API illisibles."
  [[ $page_size =~ ^[1-9][0-9]*$ ]] || die "réglages de l'API illisibles."
  fetch_timeline_page() { # $1 numéro de page, $2 fichier de réponse
    local code
    code=$(gitea_api GET "/repos/$gitea_canonical_repo/issues/$pr/timeline?limit=$page_size&page=$1" "$2")
    [[ $code == 200 ]] || die "lecture de la timeline de la PR impossible (HTTP $code) : $(forge_message "$2")"
  }
  code=0
  read_timeline_reports fetch_timeline_page "$gitea_user" "$page_size" "$max_timeline_pages" "$tmp/reviews.tsv" || code=$?
  ((code != 3)) || die "timeline de la PR plus longue que $max_timeline_pages pages : lecture des rapports incomplète."
  ((code == 0)) || die "page de la timeline de la PR illisible."
  head_report=$(last_report "$tmp/reviews.tsv" "$head_sha" "$release_branch") || die "lecture des rapports de revue impossible."
  if [[ -z $head_report ]]; then
    report bloque "revue LLM" "aucun rapport llm-review sur la tête ${head_sha:0:7} : lancer .working-method/review/llm-review.sh $pr, puis relancer."
  else
    model=${head_report#*model=}; model=${model%% *}
    if [[ $head_report == *verdict=pass ]]; then
      report passe "revue LLM" "rapport pass sur la tête ($model)."
    else
      report bloque "revue LLM" "dernier rapport sur la tête : block ($model). Traiter les constats, pousser, puis relancer la revue."
    fi
  fi

  # --- verrou 3 : garde-fou public/privé ---
  local guard_out
  if guard_out=$(PRIVATE_PATTERNS_FILE=$patterns_file "$root/scripts/check-private.sh" history "$main_sha..$head_sha" 2>&1); then
    report passe "garde-fou" "check-private.sh history sur $release_branch..$branch, avec la liste des motifs."
  else
    report bloque "garde-fou" "check-private.sh refuse le correctif :"
    indent <<< "$guard_out"
  fi

  # --- verrou 4 : CI verte sur la tête ---
  # Le régime d'amorçage est refusé, comme dans release (story 11.7) : la production ne se corrige pas
  # sur un scripts/check.sh relancé dans une copie locale, mais sur la CI réelle de ce commit même.
  local ci_on_base ci_out ci_decision ci_detail
  code=$(gitea_api GET "/repos/$gitea_canonical_repo/commits/$head_sha/status" "$tmp/status.json")
  [[ $code == 200 ]] || die "lecture de l'état de la CI impossible (HTTP $code) : $(forge_message "$tmp/status.json")"
  ci_on_base=0
  if git cat-file -e "$main_sha:$ci_workflow" 2>/dev/null; then ci_on_base=1; fi
  ci_out=$(ci_gate "$tmp/status.json" "$ci_on_base" "$ci_workflow" "$ci_context") || die "état de la CI illisible."
  ci_decision=${ci_out%%$'\t'*}
  ci_detail=${ci_out#*$'\t'}
  if [[ $ci_decision == amorçage ]]; then
    report bloque "CI" "aucun statut du workflow « $ci_context » sur la tête : un correctif de production ne se valide pas sur le substitut d'amorçage."
  else
    report "$ci_decision" "CI" "$ci_detail"
  fi

  # --- verrou 5 : suivi de sprint ---
  # Contrôle **global** : une branche hotfix/* ne porte aucun numéro de story. Un suivi incohérent
  # bloque un correctif comme il bloque une story.
  local sprint_out
  if sprint_out=$("$root/$sprint_consistency" --rev "$head_sha" 2>&1); then
    report passe "suivi de sprint" "contrôle global sur la tête du correctif : cohérent."
  else
    report bloque "suivi de sprint" "contrôle global sur la tête du correctif :"
    indent <<< "$sprint_out"
  fi

  # --- résultat ---
  if ((blocked)); then
    local refusal=""
    [[ -z $merge ]] || refusal=" : rien n'est fusionné, aucun tag n'est posé"
    printf '%s: au moins un verrou bloque%s.\n' "$script_name" "$refusal"
    exit 1
  fi
  if [[ -z $merge ]]; then
    printf '%s: tous les verrous passent. Fusion possible avec « publish --merge », lancé par Arnaud ; le tag sera %s.\n' "$script_name" "$tag"
    exit 0
  fi

  # --- fusion en fast-forward ---
  read_pr "$tmp/pr-avant-fusion.json"
  [[ $(jq -r '.head.sha' "$tmp/pr-avant-fusion.json") == "$head_sha" ]] || die "la tête de la PR a bougé pendant l'audit : relancer."
  # Ni force_merge, ni merge_when_checks_succeed, ni delete_branch_after_merge. Le style
  # fast-forward-only ne crée aucun commit : aucun message de fusion n'est composé.
  jq -n --arg h "$head_sha" '{Do: "fast-forward-only", head_commit_id: $h}' > "$tmp/fusion.json" \
    || die "préparation de la fusion impossible."
  attempt=1
  while :; do
    code=$(gitea_api POST "/repos/$gitea_canonical_repo/pulls/$pr/merge" "$tmp/fusion-reponse.json" "$tmp/fusion.json")
    forge_said=$(forge_message "$tmp/fusion-reponse.json")
    outcome=$(release_merge_response "$code" "$forge_said")
    [[ $outcome == retry ]] || break
    ((attempt < retry_max)) || break
    attempt=$((attempt + 1))
    printf '%s: la forge demande de réessayer (405 transitoire) ; reprise %s sur %s.\n' "$script_name" "$attempt" "$retry_max"
    sleep "$retry_delay"
  done
  case $outcome in
    ok) ;;
    retry | style) refuse "la forge refuse le style de fusion (HTTP 405) : $forge_said. Les styles du dépôt sont squash et fast-forward-only (docs/procedures/gitea-branches.md). Aucun tag n'est posé." ;;
    diverging) refuse "$release_branch a divergé de $branch pendant la publication (HTTP 500, DivergingFastForwardOnly) : rien n'est réécrit en silence (AD-24). Rebaser la branche sur origin/$release_branch, la repousser et relancer — la revue est à refaire. Aucun tag n'est posé." ;;
    *) refuse "la forge refuse la fusion (HTTP $code) : $forge_said. Aucun tag n'est posé." ;;
  esac
  read_pr "$tmp/pr-apres-fusion.json"
  [[ $(jq -r '.merged' "$tmp/pr-apres-fusion.json") == true ]] \
    || die "fusion annoncée mais la PR n'apparaît pas fusionnée : aucun tag n'est posé, vérifier sur la forge."

  # --- le tag, après avoir relu ce que la forge a réellement fait ---
  # La fusion a eu lieu **sur la forge** : refs/remotes/origin/main est encore celle d'avant. Sans ce
  # fetch, « git tag » se poserait sur l'ancien main, et le workflow release livrerait cet arbre-là.
  # Une fois la PR fusionnée, relancer publish ne sait plus poser le tag (la PR n'est plus ouverte) :
  # chaque message d'échec donne donc les deux commandes qui le posent à la main.
  local by_hand="git fetch origin $release_branch, puis git tag -a $tag -m \"Correctif de production $tag\" $head_sha et git push origin refs/tags/$tag"
  git fetch --quiet --tags origin "$release_branch" 2>/dev/null \
    || die "relecture de $release_branch après la fusion impossible : aucun tag n'est posé. La PR est fusionnée ; le tag se pose à la main, une fois origin/$release_branch relue sur ${head_sha:0:7} : $by_hand."
  main_after=$(git rev-parse --verify --quiet "refs/remotes/origin/$release_branch^{commit}") \
    || die "origin/$release_branch illisible après la fusion : aucun tag n'est posé."
  [[ $main_after == "$head_sha" ]] \
    || die "après la fusion, origin/$release_branch pointe sur ${main_after:0:7} et non sur la tête fusionnée ${head_sha:0:7} : **aucun tag n'est posé**. Vérifier l'état de $release_branch sur la forge avant toute autre chose."

  code=0
  release_push_tag "$tag" "$main_after" "Correctif de production $tag" || code=$?
  case $code in
    0) ;;
    1) die "création du tag $tag impossible (déjà posé entre-temps ?). La PR est fusionnée ; vérifier les tags, puis : $by_hand." ;;
    2) die "le tag $tag n'a pas pu être poussé : il a été retiré du dépôt local. La PR est fusionnée ; le poser à la main : $by_hand." ;;
    *) die "le tag $tag n'a pas pu être poussé, et le tag local n'a pas pu être retiré : le supprimer (git tag -d $tag), puis : $by_hand." ;;
  esac

  printf '%s: PR n° %s fusionnée en fast-forward ; %s posé sur %s (%s) et poussé. La livraison appartient maintenant au workflow release.\n' \
    "$script_name" "$pr" "$tag" "$release_branch" "${main_after:0:7}"
  printf '  suivi du run    : onglet « Actions » du dépôt sur la forge, workflow « release », tag %s\n' "$tag"
  printf "  état du service : « deploy-site status » envoyé par ssh au compte de déploiement, une fois le run terminé (docs/procedures/release.md)\n"
  printf '  suite           : scripts/hotfix.sh sync, puis Arnaud lance scripts/hotfix.sh sync --push — %s n'"'"'est plus un ancêtre de %s.\n' \
    "$release_branch" "$base_branch"
}

# --- sync ------------------------------------------------------------------------------------------
state_file=""

# Arrêt sur conflit (arbitrage Q3) : le rebase reste en cours, et la consigne dit exactement quoi
# faire. Aucun « git rebase --abort » n'est lancé : le travail de résolution n'est jamais jeté.
stop_on_rebase_failure() {
  local code=0
  hotfix_rebase_dir || code=$?
  case $code in
    0)
      printf '%s: conflit pendant le rebase de %s sur %s : le rebase reste en cours, rien n'"'"'est poussé.\n' "$script_name" "$base_branch" "$release_branch" >&2
      printf '  1. résoudre les conflits dans les fichiers signalés ;\n' >&2
      printf '  2. git add <fichiers résolus> ;\n' >&2
      printf '  3. git rebase --continue ;\n' >&2
      printf '  4. relancer scripts/hotfix.sh sync.\n' >&2
      exit 1
      ;;
    1)
      # le rebase n'a pas démarré : dev locale est restée sur origin/dev, l'état n'a plus d'objet
      rm -f "$state_file"
      die "le rebase de $base_branch sur $release_branch a échoué sans laisser de rebase en cours : rien n'est poussé."
      ;;
    *) die "lecture du dossier git impossible après l'échec du rebase." ;;
  esac
}

restart_hint() {
  printf "Pour recommencer depuis l'état de la forge : rm %s ; git fetch origin ; git checkout -B %s origin/%s ; puis relancer scripts/hotfix.sh sync." \
    "$state_file" "$base_branch" "$base_branch"
}

fetch_open_prs_page() { # $1 numéro de page, $2 fichier de réponse
  local code
  code=$(gitea_api GET "/repos/$gitea_canonical_repo/pulls?state=open&limit=50&page=$1" "$2")
  [[ $code == 200 ]] || die "$base_branch est poussée, mais la liste des PR ouvertes est illisible (HTTP $code) : $(forge_message "$2"). La relire sur la forge : chaque PR vers $base_branch est à rebaser puis à relire."
}

# Après le rebase, qu'il vienne de ce lancement ou d'un lancement précédent : l'état enregistré doit
# encore décrire la forge, dev locale doit contenir main, puis, avec --push seulement, dev est poussée.
finish_sync() { # $1 bail (origin/dev lue avant le rebase), $2 origin/main sur laquelle dev est rebasée
  local lease=$1 main_then=$2 current local_dev ahead push_out code
  current=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || current="(HEAD détachée)"
  [[ $current == "$base_branch" ]] \
    || refuse "une synchronisation est entamée, mais HEAD est sur $current et non sur $base_branch : git checkout $base_branch, puis relancer. $(restart_hint)"
  require_clean_tree "elles ne seraient pas poussées. Rien n'a été fait."
  fetch_branches "avant de vérifier le rebase"
  [[ $main_sha == "$main_then" ]] \
    || refuse "$release_branch a bougé sur la forge depuis le début de la synchronisation (${main_then:0:7} → ${main_sha:0:7}) : rien n'est poussé. $(restart_hint)"
  [[ $dev_sha == "$lease" ]] \
    || refuse "$base_branch a bougé sur la forge depuis le début de la synchronisation (${lease:0:7} → ${dev_sha:0:7}), une PR fusionnée entre-temps par exemple : la pousser l'effacerait. Rien n'est poussé. $(restart_hint)"
  local_dev=$(git rev-parse --verify --quiet "refs/heads/$base_branch^{commit}") || die "$base_branch locale illisible."
  if ! is_ancestor "$main_sha" "$local_dev"; then
    refuse "$release_branch n'est pas un ancêtre de $base_branch locale : le rebase n'est pas allé au bout (abandonné ?). Rien n'est poussé. $(restart_hint)"
  fi
  ahead=$(git rev-list --count "$main_sha..$local_dev") || die "comptage des commits de $base_branch impossible."

  printf '%s: %s locale rebasée sur origin/%s (%s) : %s, %s commit(s) au-dessus de %s.\n' "$script_name" \
    "$base_branch" "$release_branch" "${main_sha:0:7}" "${local_dev:0:7}" "$ahead" "$release_branch"
  if [[ -z $push ]]; then
    printf '%s: rien n'"'"'est poussé. « sync --push », lancé par Arnaud, remplacera origin/%s (%s) par %s :\n' \
      "$script_name" "$base_branch" "${lease:0:7}" "${local_dev:0:7}"
    printf '  git push --force-with-lease=%s:%s origin %s\n' "$base_branch" "$lease" "$base_branch"
    printf "  puis listera les PR ouvertes vers %s, à rebaser et à relire : leurs rapports de revue portent sur des SHA réécrits (D-14).\n" "$base_branch"
    exit 0
  fi

  # Le bail porte une valeur **explicite**, la tête de origin/dev lue avant le rebase. Un
  # « --force-with-lease » nu comparerait à refs/remotes/origin/dev, qu'un fetch lancé entre-temps
  # (le script lui-même, un éditeur) aurait déjà avancée sur le commit concurrent : il l'écraserait.
  # Constaté avec git 2.53 (fichier de story, « Comportements de git vérifiés »).
  code=0
  push_out=$(git push --force-with-lease="$base_branch:$lease" origin "$base_branch" 2>&1) || code=$?
  if ((code != 0)); then
    printf '%s: git a refusé le push forcé de %s ; ses messages, adresse masquée :\n' "$script_name" "$base_branch" >&2
    hotfix_mask_remote <<< "$push_out" | sed 's/^/  /' >&2
    if [[ $push_out == *"stale info"* ]]; then
      refuse "le bail a refusé le push : origin/$base_branch n'est plus ${lease:0:7}, quelqu'un a poussé entre-temps. Rien n'a été écrasé, aucune reprise n'est tentée. $(restart_hint)"
    fi
    refuse "push forcé de $base_branch refusé par la forge (branche protégée, compte hors de la liste du force-push ?) : aucune reprise n'est tentée (docs/procedures/gitea-branches.md)."
  fi

  git fetch --quiet origin "$release_branch" "$base_branch" 2>/dev/null \
    || die "$base_branch est poussée, mais sa relecture sur la forge est impossible : vérifier que origin/$release_branch est un ancêtre de origin/$base_branch."
  local dev_after main_after
  dev_after=$(git rev-parse --verify --quiet "refs/remotes/origin/$base_branch^{commit}") || die "origin/$base_branch illisible après le push."
  main_after=$(git rev-parse --verify --quiet "refs/remotes/origin/$release_branch^{commit}") || die "origin/$release_branch illisible après le push."
  [[ $dev_after == "$local_dev" ]] \
    || die "après le push, origin/$base_branch pointe sur ${dev_after:0:7} et non sur ${local_dev:0:7} : vérifier sur la forge."
  if ! is_ancestor "$main_after" "$dev_after"; then
    die "après le push, origin/$release_branch n'est pas un ancêtre de origin/$base_branch : vérifier sur la forge."
  fi
  rm -f "$state_file" || die "suppression de l'état $state_file impossible : le supprimer à la main."
  printf '%s: origin/%s poussée (%s → %s) ; origin/%s en est de nouveau un ancêtre (AD-24).\n' "$script_name" \
    "$base_branch" "${lease:0:7}" "${dev_after:0:7}" "$release_branch"

  # Les PR ouvertes vers dev reposent sur l'ancienne dev, et leurs rapports llm-review sur des SHA
  # qui n'existent plus dans dev (D-14) : chacune est à rebaser, puis à relire.
  code=0
  hotfix_open_prs fetch_open_prs_page "$base_branch" "$max_pr_pages" "$tmp/pr-vers-dev" || code=$?
  ((code != 3)) || die "liste des PR ouvertes plus longue que $max_pr_pages pages."
  ((code == 0)) || die "$base_branch est poussée, mais la liste des PR ouvertes est illisible : la relire sur la forge."
  if [[ ! -s $tmp/pr-vers-dev ]]; then
    printf '%s: aucune PR ouverte vers %s : rien à reprendre.\n' "$script_name" "$base_branch"
    exit 0
  fi
  printf '%s: PR ouvertes vers %s, à rebaser puis à relire (leurs rapports portent sur des SHA réécrits) :\n' "$script_name" "$base_branch"
  local number branch sha
  while IFS=$'\t' read -r number branch sha; do
    printf '  PR n° %s (%s, tête %s)\n' "$number" "$branch" "${sha:0:7}"
    printf '    git fetch origin && git checkout %s && git rebase --onto origin/%s %s\n' "$branch" "$base_branch" "$lease"
    printf '    git push --force-with-lease=%s:%s origin %s\n' "$branch" "$sha" "$branch"
    printf '    .working-method/review/llm-review.sh %s\n' "$number"
  done < "$tmp/pr-vers-dev"
}

cmd_sync() {
  local code head_name local_dev
  state_file=$(git rev-parse --git-path hotfix-sync 2>/dev/null) || die "lecture du dossier git impossible."
  [[ -n $state_file ]] || die "lecture du dossier git impossible."
  # Avec --push, tout ce qui peut manquer se vérifie avant le premier geste : un .env incomplet
  # découvert après le push forcé laisserait dev réécrite sans la liste des PR à reprendre.
  [[ -z $push ]] || load_forge

  # --- un rebase arrêté sur un conflit : on le reprend, on n'en commence pas un second ---
  code=0
  hotfix_rebase_dir || code=$?
  ((code <= 1)) || die "lecture du dossier git impossible."
  if ((code == 0)); then
    head_name=""
    [[ ! -f $hotfix_rebase_path/head-name ]] || head_name=$(< "$hotfix_rebase_path/head-name")
    [[ $head_name == "refs/heads/$base_branch" ]] \
      || refuse "un autre rebase est en cours (${head_name:-branche inconnue}) : le terminer ou l'abandonner avant de synchroniser. Rien n'a été fait."
    code=0
    hotfix_state_read "$state_file" || code=$?
    case $code in
      0) ;;
      1) refuse "un rebase de $base_branch est en cours, mais il n'a pas été commencé par « scripts/hotfix.sh sync » : le terminer ou l'abandonner (git rebase --abort) à la main. Rien n'a été fait." ;;
      *) die "état de synchronisation illisible ($state_file). $(restart_hint)" ;;
    esac
    printf '%s: reprise du rebase de %s entamé par sync.\n' "$script_name" "$base_branch"
    GIT_EDITOR=true git rebase --continue || stop_on_rebase_failure
    finish_sync "$hotfix_state_lease" "$hotfix_state_main"
    return
  fi

  # --- un rebase terminé lors d'un lancement précédent (conflit résolu, ou audit avant --push) ---
  code=0
  hotfix_state_read "$state_file" || code=$?
  case $code in
    0) finish_sync "$hotfix_state_lease" "$hotfix_state_main"; return ;;
    1) ;;
    *) die "état de synchronisation illisible ($state_file). $(restart_hint)" ;;
  esac

  # --- une synchronisation neuve ---
  require_clean_tree "le rebase les emporterait. Rien n'a été fait."
  fetch_branches "avant le rebase"
  if is_ancestor "$main_sha" "$dev_sha"; then
    printf "%s: rien à synchroniser : origin/%s (%s) est déjà un ancêtre de origin/%s (%s).\n" "$script_name" \
      "$release_branch" "${main_sha:0:7}" "$base_branch" "${dev_sha:0:7}"
    exit 0
  fi
  # dev locale est **remise** sur origin/dev, jamais rebasée telle quelle : une dev locale en retard
  # pousserait une dev qui a perdu des PR. Mais une dev locale **en avance** porte des commits que la
  # forge n'a pas — un push direct sur dev est interdit par la procédure — et la remettre les jetterait.
  code=0
  git show-ref --verify --quiet "refs/heads/$base_branch" || code=$?
  case $code in
    0)
      local_dev=$(git rev-parse --verify --quiet "refs/heads/$base_branch^{commit}") || die "$base_branch locale illisible."
      if ! is_ancestor "$local_dev" "$dev_sha"; then
        refuse "$base_branch locale (${local_dev:0:7}) porte des commits absents de origin/$base_branch : la remettre sur la forge les jetterait. Les mettre de côté sur une autre branche (git branch <nom> $base_branch), puis relancer. Rien n'a été fait."
      fi
      ;;
    1) ;;
    *) die "lecture des branches locales impossible (git show-ref, code $code). Rien n'a été fait." ;;
  esac

  # L'état est écrit **avant** le rebase : un conflit arrête ce lancement, et le suivant doit pousser
  # avec le bail lu ici, pas avec une origin/dev relue plus tard.
  hotfix_state_write "$state_file" "$dev_sha" "$main_sha" || die "écriture de l'état $state_file impossible. Rien n'a été fait."
  if ! git checkout --quiet -B "$base_branch" "$dev_sha" 2>/dev/null; then
    rm -f "$state_file"
    die "remise de $base_branch locale sur origin/$base_branch impossible. Rien n'a été fait."
  fi
  printf '%s: %s locale remise sur origin/%s (%s), rebase sur origin/%s (%s).\n' "$script_name" \
    "$base_branch" "$base_branch" "${dev_sha:0:7}" "$release_branch" "${main_sha:0:7}"
  # Les réglages du poste qui changeraient ce que fait le rebase sont neutralisés : ni remisage
  # automatique, ni réordonnancement « fixup! », ni déplacement d'autres branches.
  git -c rebase.autoStash=false -c rebase.autoSquash=false -c rebase.updateRefs=false \
    rebase --quiet "$main_sha" || stop_on_rebase_failure
  finish_sync "$dev_sha" "$main_sha"
}

case $command in
  start) cmd_start ;;
  publish) cmd_publish ;;
  sync) cmd_sync ;;
esac
