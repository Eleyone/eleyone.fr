#!/usr/bin/env bash
# Publie dev sur main en fast-forward, pose le tag vX.Y.Z et laisse la livraison au workflow release.
#
#   release.sh <tag>           audit : ouvre la PR si besoin, affiche chaque verrou, ne fusionne rien
#   release.sh <tag> --merge   fusionne en fast-forward-only, puis pose et pousse le tag
#
# Code de sortie : 0 tous les verrous passent (avec --merge, la publication est faite) ; 1 refus
# (verrou bloquant, invariant rompu, refus de la forge) ; 2 anomalie (usage, outil absent, .env
# absent, forge injoignable, réponse illisible, état incohérent après la fusion).
#
# **--merge est l'affaire d'Arnaud** : le script ne le déduit jamais (AD-24). Il n'a aucune option
# --force, n'envoie jamais force_merge ni merge_when_checks_succeed, et ne supprime aucune branche :
# la publication ne détruit pas dev.
#
# **Le tag est le point dangereux.** La fusion passe par l'API de la forge et ne met pas à jour le
# dépôt local : sans relecture explicite, « git tag » se poserait sur l'ancien main, et le workflow
# release livrerait en production un arbre qui n'est pas celui qu'on croit publier. Le script relit
# donc les branches après la fusion et **refuse de taguer** si origin/main ne porte pas le commit
# publié.
# Procédure : docs/procedures/release.md
set -euo pipefail
set +x # même lancé avec bash -x, la trace s'arrête ici, avant la lecture du jeton

script_name=release
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/gitea.sh
. "$script_dir/lib/gitea.sh"
# shellcheck source=lib/merge-gates.sh
. "$script_dir/lib/merge-gates.sh"
# shellcheck source=lib/release.sh
. "$script_dir/lib/release.sh"

# gitea.sh définit die() avec le code 1 ; ici 1 est réservé aux refus, et 2 dit l'anomalie, comme
# dans verify-and-merge-pr.sh.
die() { printf '%s: %b\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %b\n' "$script_name" "$*" >&2; exit 1; }

readonly stories_dir="_bmad-output/implementation-artifacts"
readonly status_file="$stories_dir/sprint-status.yaml"
readonly ci_workflow=".gitea/workflows/checks.yaml"
readonly bootstrap_file="ci/bootstrap-commits.txt"
readonly base_pages_file="ci/base-pages.txt"
readonly release_pages_file="ci/release-pages.txt"
readonly first_release=v1.0.0
readonly max_pr_pages=100
readonly retry_max=5     # reprises d'un 405 « try again later » et d'un « mergeable » encore nul
readonly retry_delay=3   # secondes entre deux reprises ; les tests posent un faux sleep en tête de PATH
readonly usage="usage : release.sh <tag vX.Y.Z> [--merge]"

require_tools

tag="" merge=""
while (($#)); do
  case $1 in
    --merge) [[ -z $merge ]] || die "$usage"; merge=1; shift ;;
    -*) die "option inconnue : $(printf '%q' "$1"). $usage" ;;
    *) [[ -z $tag ]] || die "$usage"; tag=$1; shift ;;
  esac
done
[[ -n $tag ]] || die "$usage"
if [[ $tag =~ $release_tag_rehearsal ]]; then
  die "tag $(printf '%q' "$tag") : une répétition générale se pose sur dev par le skill rehearse-release, jamais par release (AD-22)."
fi
[[ $tag =~ $release_tag_production ]] || die "tag $(printf '%q' "$tag") refusé : une mise en ligne porte « vX.Y.Z » (AD-14). $usage"

root=$(git rev-parse --show-toplevel 2>/dev/null) || die "à lancer dans le dépôt."
cd "$root"
check_origin
for tool in check-private sprint-consistency; do
  [[ -x $root/scripts/$tool.sh ]] || die "scripts/$tool.sh absent ou non exécutable."
done
patterns_file=${PRIVATE_PATTERNS_FILE:-$root/docs/private/forbidden-patterns.txt}
require_patterns_file "$patterns_file" "aucune mise en ligne sans audit"

# Une publication n'est pas le moment de découvrir du travail en attente : ce qui n'est pas commité
# ne sera pas publié, et l'opérateur ne verrait rien le lui dire.
pending=$(git status --porcelain 2>/dev/null) || die "lecture de l'état du dépôt impossible."
[[ -z $pending ]] || die "modifications non commitées dans l'arbre de travail : elles ne seraient pas publiées."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- l'invariant d'AD-24, avant toute action ---------------------------------------------------
git fetch --quiet --tags origin main dev 2>/dev/null || die "lecture des branches main et dev sur la forge impossible."
main_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/main^{commit}") || die "origin/main introuvable après lecture sur la forge."
dev_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/dev^{commit}") || die "origin/dev introuvable après lecture sur la forge."

printf '%s: mise en ligne %s, main %s → dev %s\n' "$script_name" "$tag" "${main_sha:0:7}" "${dev_sha:0:7}"

code=0
git merge-base --is-ancestor "$main_sha" "$dev_sha" || code=$?
case $code in
  0) ;;
  1) refuse "main n'est pas un ancêtre de dev : la publication en fast-forward est impossible. C'est l'état que laisse un correctif de production — passer par le skill hotfix, qui rebase dev sur main (AD-24). Rien n'a été fait." ;;
  *) die "« git merge-base --is-ancestor » a rendu le code $code : ni « descend » (0) ni « ne descend pas » (1). Rien n'a été fait." ;;
esac
[[ $main_sha != "$dev_sha" ]] || refuse "main et dev pointent déjà sur le même commit : il n'y a rien à publier. Rien n'a été fait."

# Un tag déjà posé serait poussé sur un autre commit, ou refusé par la forge après la fusion : la
# question se pose **avant** d'ouvrir quoi que ce soit.
# Le code de « git rev-parse » est lu, jamais avalé par « || true » : il vaut 0 quand le tag existe,
# 1 quand il n'existe pas — le cas nominal — et autre chose quand le dépôt est illisible. Un
# « || true » confondrait les deux derniers et laisserait une publication continuer sur un dépôt
# cassé (classe de faute nommée par la revue du code de la PR n° 120, balayée ici au titre du
# point 18 d'AGENTS.md).
tag_existant=""
tag_rc=0
tag_existant=$(git rev-parse --verify --quiet "refs/tags/$tag") || tag_rc=$?
((tag_rc <= 1)) || die "lecture des tags du dépôt impossible (git rev-parse, code $tag_rc) : rien n'a été fait."
[[ -z $tag_existant ]] \
  || refuse "le tag $tag existe déjà dans ce dépôt (relu depuis la forge) : choisir le numéro suivant. Rien n'a été fait."

# --- la répétition générale (AD-22, D-6) ---------------------------------------------------------
release_rc_found=""
code=0
release_rc_same_tree "$tag" "$dev_sha" || code=$?
case $code in
  0) printf '%s: répétition générale trouvée sur le même arbre : %s.\n' "$script_name" "$release_rc_found" ;;
  1)
    [[ $tag != "$first_release" ]] \
      || refuse "aucun tag $first_release-rc.N ne pointe sur un arbre identique à la tête de dev : la première mise en ligne se répète avant de se faire (AD-22, D-6). Rien n'a été fait."
    printf "%s: avertissement — aucun tag %s-rc.N de même arbre. Pour un tag de production autre que %s, ce n'est pas un refus (AD-22, D-6) ; la mise en ligne continue.\n" \
      "$script_name" "$tag" "$first_release"
    ;;
  *) die "comparaison des tags de répétition impossible (git, code $code). Rien n'a été fait." ;;
esac

# --- la complétude du socle, pour v1.0.0 seulement (FR-32, D-5) -----------------------------------
# Les deux listes sont lues **à la tête**, l'état qui serait publié, et non dans l'arbre de travail :
# ci/release-pages.txt est un fichier versionné, pas un artefact de CI — il n'y a rien à télécharger
# ni à construire (décision S4 de la revue de spec).
if [[ $tag == "$first_release" ]]; then
  git show "$dev_sha:$base_pages_file" > "$tmp/base-pages.txt" 2>/dev/null \
    || die "$base_pages_file absent de la tête de dev : la liste du socle est ce qui définit la première mise en ligne."
  git show "$dev_sha:$release_pages_file" > "$tmp/release-pages.txt" 2>/dev/null \
    || die "$release_pages_file absent de la tête de dev."
  release_missing_base_pages "$tmp/base-pages.txt" "$tmp/release-pages.txt" "$tmp/manquantes.txt" \
    || die "lecture des listes de pages impossible."
  if [[ -s $tmp/manquantes.txt ]]; then
    printf '%s: %s ne contient pas tout le socle. Pages manquantes :\n' "$script_name" "$release_pages_file" >&2
    sed 's/^/  /' "$tmp/manquantes.txt" >&2
    refuse "le socle de FR-32 est incomplet : $first_release ne se publie pas sans lui (D-5). Rien n'a été fait."
  fi
  printf '%s: socle complet — les %s clés de %s figurent dans %s.\n' "$script_name" \
    "$(grep -cvE '^[[:space:]]*(#|$)' "$tmp/base-pages.txt")" "$base_pages_file" "$release_pages_file"
fi

# --- la PR de publication -------------------------------------------------------------------------
load_gitea_env "$root/.env"
check_token_owner "$tmp/user.json"

pr=""
page=1
while :; do
  ((page <= max_pr_pages)) || die "liste des PR ouvertes plus longue que $max_pr_pages pages."
  code=$(gitea_api GET "/repos/$gitea_canonical_repo/pulls?state=open&limit=50&page=$page" "$tmp/open.json")
  [[ $code == 200 ]] || die "lecture des PR ouvertes impossible (HTTP $code) : $(forge_message "$tmp/open.json")"
  pr=$(jq -r '[.[] | select(.head.ref == "dev" and .base.ref == "main") | .number] | first // empty' "$tmp/open.json" 2>/dev/null) \
    || die "liste des PR ouvertes illisible."
  [[ -z $pr ]] || break
  count=$(jq 'length' "$tmp/open.json" 2>/dev/null) || die "liste des PR ouvertes illisible."
  [[ $count =~ ^[0-9]+$ ]] || die "liste des PR ouvertes illisible."
  ((count == 50)) || break
  page=$((page + 1))
done

if [[ -z $pr ]]; then
  printf 'Mise en ligne %s\n' "$tag" > "$tmp/titre.txt"
  {
    printf 'Publication de `dev` sur `main` en fast-forward, sans merge commit (AD-24).\n\n'
    printf 'Verrous appliqués par `scripts/release.sh` (`docs/procedures/release.md`) : PR publiable,\n'
    printf 'revue (chaque commit de `main..dev` est le squash d'"'"'une PR vérifiée), garde-fou public/privé,\n'
    printf 'CI verte sur la tête, suivi de sprint.\n\n'
    printf 'La fusion est faite par `scripts/release.sh %s --merge`, lancé par Arnaud, puis le tag `%s`\n' "$tag" "$tag"
    printf 'déclenche le workflow `release`.\n'
  } > "$tmp/corps.txt"
  # Le titre et le corps partent sur la forge : ils passent d'abord la liste des motifs, comme le
  # fait create-pull-request. Le tag est le seul morceau qui vienne de la ligne de commande.
  code=0
  grep -vE '^[[:space:]]*(#|$)' "$patterns_file" > "$tmp/patterns" 2>/dev/null || code=$?
  ((code <= 1)) || die "lecture du fichier de motifs impossible : rien n'est ouvert."
  if [[ -s $tmp/patterns ]]; then
    code=0
    grep -qiF -f "$tmp/patterns" "$tmp/titre.txt" "$tmp/corps.txt" || code=$?
    ((code != 0)) || refuse "le titre ou le corps de la PR contient un motif privé (contenu masqué) : rien n'est ouvert."
    ((code == 1)) || die "vérification du titre et du corps impossible : rien n'est ouvert."
  fi
  jq -n --rawfile titre "$tmp/titre.txt" --rawfile corps "$tmp/corps.txt" \
    '{head: "dev", base: "main", title: ($titre | rtrimstr("\n")), body: $corps}' > "$tmp/creation.json" \
    || die "préparation de la PR impossible."
  code=$(gitea_api POST "/repos/$gitea_canonical_repo/pulls" "$tmp/creee.json" "$tmp/creation.json")
  [[ $code == 201 ]] || die "la forge refuse la création de la PR (HTTP $code) : $(forge_message "$tmp/creee.json")"
  pr=$(jq -r '.number // empty' "$tmp/creee.json" 2>/dev/null) || die "réponse de la forge illisible après la création."
  [[ $pr =~ ^[1-9][0-9]*$ ]] || die "numéro de PR illisible après la création."
  printf '%s: PR n° %s ouverte : dev → main.\n' "$script_name" "$pr"
else
  printf '%s: PR n° %s déjà ouverte : dev → main.\n' "$script_name" "$pr"
fi

read_pr() { # $1 fichier de réponse
  local code
  code=$(gitea_api GET "/repos/$gitea_canonical_repo/pulls/$pr" "$1")
  [[ $code == 200 ]] || die "PR n° $pr illisible (HTTP $code) : $(forge_message "$1")"
}
# Juste après la création, la forge n'a pas fini de calculer la fusionnabilité et répond « mergeable:
# null ». Attendre est la seule réponse juste : bloquer serait un faux refus, passer serait lire un
# état inconnu comme un état vert.
attempt=1
while :; do
  read_pr "$tmp/pr.json"
  fields=$(jq -er '[.state, (.draft | tostring), (.mergeable | tostring), (.merged | tostring), .base.ref, .head.ref, .head.sha] | @tsv' "$tmp/pr.json" 2>/dev/null) \
    || die "réponse de la forge illisible pour la PR n° $pr."
  IFS=$'\t' read -r state draft mergeable merged base branch head_sha <<< "$fields"
  [[ $mergeable == null ]] || break
  ((attempt < retry_max)) || break
  attempt=$((attempt + 1))
  sleep "$retry_delay"
done
[[ $head_sha =~ ^[0-9a-f]{40}$ ]] || die "SHA de tête de la PR n° $pr illisible."

blocked=0
report() { # état (passe, bloque), verrou, détail
  printf '  %-7s %-16s %b\n' "$1" "$2" "$3"
  [[ $1 != bloque ]] || blocked=1
}
indent() { sed 's/^/            /'; }

# --- verrou 1 : PR publiable ---------------------------------------------------------------------
if [[ $merged == true || $state != open ]]; then
  report bloque "PR publiable" "PR $([[ $merged == true ]] && echo "déjà fusionnée" || echo "fermée") : rien à publier."
  printf '%s: au moins un verrou bloque.\n' "$script_name"
  exit 1
fi
if [[ $base != main || $branch != dev ]]; then
  report bloque "PR publiable" "PR n° $pr : $branch → $base, alors qu'une publication va de dev vers main."
elif [[ $head_sha != "$dev_sha" ]]; then
  report bloque "PR publiable" "la tête de la PR (${head_sha:0:7}) n'est pas celle de origin/dev (${dev_sha:0:7}) : relancer."
elif [[ $draft == true ]]; then
  report bloque "PR publiable" "PR en brouillon."
elif [[ $mergeable != true ]]; then
  report bloque "PR publiable" "PR non fusionnable pour la forge (mergeable=$mergeable) : relancer dans quelques secondes."
else
  report passe "PR publiable" "ouverte, pas en brouillon, fusionnable, dev → main."
fi

# --- verrou 2 : revue, par la provenance des commits (AD-24, D-13) --------------------------------
if release_unverified_commits "$main_sha..$dev_sha" "$root/$bootstrap_file" "$tmp/non-verifies.txt"; then
  total=$(git rev-list --count "$main_sha..$dev_sha") || die "comptage des commits de la plage impossible."
  if [[ -s $tmp/non-verifies.txt ]]; then
    report bloque "revue" "$(grep -c . "$tmp/non-verifies.txt") commit(s) sur $total ne sont pas le squash d'une PR vérifiée :"
    sed 's/^/  /' "$tmp/non-verifies.txt" | indent
  else
    report passe "revue" "les $total commits de main..dev sont des squashs de PR, hors amorçage listé ($bootstrap_file)."
  fi
else
  die "lecture de $bootstrap_file ou des commits de main..dev impossible : SHA mal formé, ou fichier absent."
fi

# --- verrou 3 : garde-fou public/privé ------------------------------------------------------------
if guard_out=$(PRIVATE_PATTERNS_FILE=$patterns_file "$root/scripts/check-private.sh" history "$main_sha..$dev_sha" 2>&1); then
  report passe "garde-fou" "check-private.sh history sur main..dev, avec la liste des motifs."
else
  report bloque "garde-fou" "check-private.sh refuse la publication :"
  indent <<< "$guard_out"
fi

# --- verrou 4 : CI verte sur la tête --------------------------------------------------------------
# **Le régime d'amorçage est refusé ici** (story 11.7). Le substitut de verify-and-merge-pr se
# déclenche quand le workflow manque à la **base** de la PR : pour une publication, la base est main,
# où checks.yaml n'est pas encore arrivé, si bien que le régime se réveillerait exactement à la
# première mise en ligne, le moment le plus critique du projet. La tête, elle, est un commit de dev
# et porte donc les statuts de checks.yaml : une mise en ligne se valide sur la CI réelle qui a
# tourné sur ce commit même, jamais sur un scripts/check.sh relancé dans une copie locale.
code=$(gitea_api GET "/repos/$gitea_canonical_repo/commits/$dev_sha/status" "$tmp/status.json")
[[ $code == 200 ]] || die "lecture de l'état de la CI impossible (HTTP $code) : $(forge_message "$tmp/status.json")"
ci_on_base=0
if git cat-file -e "$main_sha:$ci_workflow" 2>/dev/null; then ci_on_base=1; fi
ci_out=$(ci_gate "$tmp/status.json" "$ci_on_base" "$ci_workflow") || die "état de la CI illisible."
ci_decision=${ci_out%%$'\t'*}
ci_detail=${ci_out#*$'\t'}
if [[ $ci_decision == amorçage ]]; then
  report bloque "CI" "aucun statut du workflow « checks » sur la tête : une mise en ligne ne se valide pas sur le substitut d'amorçage (story 11.7)."
else
  report "$ci_decision" "CI" "$ci_detail"
fi

# --- verrou 5 : suivi de sprint --------------------------------------------------------------------
# Contrôle **global** : la branche entrante est dev, qui ne porte aucun numéro de story
# (docs/procedures/verify-and-merge-pr.md). Un suivi incohérent bloque une publication comme il
# bloque une story.
if sprint_out=$("$root/scripts/sprint-consistency.sh" --rev "$dev_sha" 2>&1); then
  report passe "suivi de sprint" "contrôle global sur la tête de dev : cohérent."
else
  report bloque "suivi de sprint" "contrôle global sur la tête de dev :"
  indent <<< "$sprint_out"
fi

# --- résultat ---------------------------------------------------------------------------------------
if ((blocked)); then
  refusal=""
  [[ -z $merge ]] || refusal=" : rien n'est fusionné, aucun tag n'est posé"
  printf '%s: au moins un verrou bloque%s.\n' "$script_name" "$refusal"
  exit 1
fi
if [[ -z $merge ]]; then
  printf '%s: tous les verrous passent. Publication possible avec --merge, lancé par Arnaud (AD-24).\n' "$script_name"
  exit 0
fi

# --- fusion en fast-forward -------------------------------------------------------------------------
read_pr "$tmp/pr-avant-fusion.json"
[[ $(jq -r '.head.sha' "$tmp/pr-avant-fusion.json") == "$head_sha" ]] || die "la tête de la PR a bougé pendant l'audit : relancer."

# Ni force_merge, ni merge_when_checks_succeed, ni delete_branch_after_merge : une publication ne
# supprime pas dev. Le style fast-forward-only ne crée aucun commit, donc aucun message de fusion
# n'est composé ici — il n'y a rien à confronter à la liste des motifs.
jq -n --arg h "$head_sha" '{Do: "fast-forward-only", head_commit_id: $h}' > "$tmp/fusion.json" \
  || die "préparation de la fusion impossible."
attempt=1
while :; do
  code=$(gitea_api POST "/repos/$gitea_canonical_repo/pulls/$pr/merge" "$tmp/fusion-reponse.json" "$tmp/fusion.json")
  forge_said=$(forge_message "$tmp/fusion-reponse.json")
  # Un 405 « Please try again later » est **transitoire** : la forge n'a pas fini de recalculer la
  # fusionnabilité (AD-24). Un 405 qui dit autre chose est un refus de style, et il reste un refus.
  [[ $code == 405 && ${forge_said,,} == *"try again later"* ]] || break
  ((attempt < retry_max)) || break
  attempt=$((attempt + 1))
  printf '%s: la forge demande de réessayer (405 transitoire) ; reprise %s sur %s.\n' "$script_name" "$attempt" "$retry_max"
  sleep "$retry_delay"
done
case $code in
  200) ;;
  405) refuse "la forge refuse le style de fusion (HTTP 405) : $forge_said. Les styles du dépôt sont squash et fast-forward-only (docs/procedures/gitea-branches.md). Aucun tag n'est posé." ;;
  500)
    if [[ $forge_said == *DivergingFastForwardOnly* ]]; then
      refuse "main a divergé de dev pendant la publication (HTTP 500, DivergingFastForwardOnly) : rien n'est réécrit en silence (AD-24). Relancer après avoir relu l'état des deux branches. Aucun tag n'est posé."
    fi
    refuse "la forge refuse la fusion (HTTP 500) : $forge_said. Aucun tag n'est posé."
    ;;
  *) refuse "la forge refuse la fusion (HTTP $code) : $forge_said. Aucun tag n'est posé." ;;
esac
read_pr "$tmp/pr-apres-fusion.json"
[[ $(jq -r '.merged' "$tmp/pr-apres-fusion.json") == true ]] \
  || die "fusion annoncée mais la PR n'apparaît pas fusionnée : aucun tag n'est posé, vérifier sur la forge."

# --- le tag, après avoir relu ce que la forge a réellement fait ---------------------------------------
# La fusion a eu lieu **sur la forge** : refs/remotes/origin/main est encore celle d'avant. Sans ce
# fetch, « git tag » se poserait sur l'ancien main, et le workflow release livrerait cet arbre-là.
git fetch --quiet origin main dev 2>/dev/null || die "relecture des branches après la fusion impossible : aucun tag n'est posé. La PR est fusionnée ; relancer pour poser le tag."
main_after=$(git rev-parse --verify --quiet "refs/remotes/origin/main^{commit}") || die "origin/main illisible après la fusion : aucun tag n'est posé."
dev_after=$(git rev-parse --verify --quiet "refs/remotes/origin/dev^{commit}") || die "origin/dev illisible après la fusion : aucun tag n'est posé."
[[ $main_after == "$dev_sha" ]] \
  || die "après la fusion, origin/main pointe sur ${main_after:0:7} et non sur le commit publié ${dev_sha:0:7} : **aucun tag n'est posé**. Vérifier l'état de main sur la forge avant toute autre chose."
[[ $dev_after == "$dev_sha" ]] \
  || die "dev a bougé pendant la publication (${dev_after:0:7}) : aucun tag n'est posé, main et dev ne portent pas le même commit."

git tag -a "$tag" -m "Mise en ligne $tag" "$main_after" || die "création du tag $tag impossible."
if ! git push --quiet origin "refs/tags/$tag" 2>/dev/null; then
  # Le retrait du tag local est le seul « best effort » du script, et il est écrit comme tel : on
  # meurt à la ligne suivante de toute façon, et un tag local resté en place ne casse qu'une reprise
  # — que le message annonce. Son code est tout de même lu, pour que le message dise laquelle des
  # deux situations l'opérateur retrouvera.
  retrait_rc=0
  git tag -d "$tag" > /dev/null 2>&1 || retrait_rc=$?
  ((retrait_rc == 0)) || printf '%s: le tag local %s n'"'"'a pas pu être retiré non plus : le supprimer à la main avant de relancer.\n' "$script_name" "$tag" >&2
  die "le tag $tag n'a pas pu être poussé : il a été retiré du dépôt local pour qu'une reprise le repose sur le même commit. La PR est fusionnée ; relancer."
fi

printf '%s: %s posé sur main (%s) et poussé. La livraison appartient maintenant au workflow release.\n' \
  "$script_name" "$tag" "${main_after:0:7}"
printf '  suivi du run    : onglet « Actions » du dépôt sur la forge, workflow « release », tag %s\n' "$tag"
printf "  état du service : « deploy-site status » envoyé par ssh au compte de déploiement, une fois le run terminé (docs/procedures/release.md)\n"
