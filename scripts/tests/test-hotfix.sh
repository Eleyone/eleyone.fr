#!/usr/bin/env bash
# Correctif de production (story 11.12, AD-24, D-14) : ce que le skill hotfix refuse, ce qu'il envoie
# à la forge, sur quel commit il pose le tag, et **comment il réécrit dev** — jamais sans --push, jamais
# par-dessus un push concurrent, jamais par cherry-pick.
#
# **Aucun cas n'appelle le réseau.** La forge est un **vrai dépôt nu** dans $work/forge : le faux git
# ne fait que rediriger « fetch », « push » et « ls-remote » vers lui (url.<dossier>.insteadOf passé
# par « -c », si bien que « git remote get-url origin » garde l'adresse canonique que check_origin
# vérifie), et remettre l'adresse canonique dans les messages de git, pour que le masquage de NFR-9
# soit éprouvé sur ce que la vraie forge écrirait. Le bail de --force-with-lease, le refus d'une
# branche protégée (un hook pre-receive du dépôt nu) et le rebase sont donc ceux de git, pas d'un
# faux. Le faux curl répond à la place de l'API depuis $work/api, et déplace main dans le dépôt nu
# quand une fusion réussit. Chaque appel à git est noté dans $work/git-appels.
#
# **Règle 8 commune — l'aîné et ses gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-release.sh : environnement réduit par « env -i », faux curl et réponses de la
# forge en fichiers (repris tels quels, avec la variante « .apres » après fusion), faux sleep, témoins
# à la place du garde-fou et du suivi de sprint, affirmation du code de sortie avant tout, et
# vérification qu'aucun effet n'a eu lieu après un refus. Il s'en écarte sur un point, écrit : la forge
# git n'est plus deux fichiers recopiés par un faux « fetch », mais un dépôt nu — le push forcé de dev
# est le geste de cette story, et seul git peut prouver ce que fait son bail. Le tableau complet est
# dans le fichier de story.
. "$(dirname "${BASH_SOURCE[0]}")/../../.working-method/tests/lib.sh"

script=$root/scripts/hotfix.sh
depot=$work/depot
readonly repo=Eleyone/eleyone.fr
readonly url_forge=ssh://git@forge.invalide/
forge=$work/forge/$repo.git

# --- les faux binaires --------------------------------------------------------------------------

faux_git() {
  local vrai
  vrai=$(command -v git) || { echo "git introuvable" >&2; exit 2; }
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    printf 'vrai=%q\n' "$vrai"
    printf 'forge=%q\n' "$forge"
    printf 'url=%q\n' "$url_forge"
    cat <<'FAUX'
printf '%s\n' "$*" >> "$w/git-appels"
premier=""
attend_valeur=""
for a in "$@"; do
  if [ -n "$attend_valeur" ]; then attend_valeur=""; continue; fi
  case "$a" in
    -c|-C) attend_valeur=1 ;;
    -*) ;;
    *) premier=$a; break ;;
  esac
done
case "$premier" in
  fetch|push|ls-remote)
    if [ "$premier" = fetch ] && [ -f "$w/fetch-inerte-apres-fusion" ] && [ -f "$w/fusionnee" ]; then exit 0; fi
    if [ "$premier" = push ] && [ -f "$w/concurrent" ]; then
      # Un push concurrent arrive sur la forge juste avant le nôtre, **et** un fetch lancé ailleurs
      # (un éditeur, un autre terminal) l'a déjà recopié dans refs/remotes/origin/dev : c'est le cas
      # où un --force-with-lease nu, qui compare à cette référence, écraserait le commit concurrent.
      "$vrai" --git-dir="$forge" update-ref refs/heads/dev "$(cat "$w/concurrent")" || exit 1
      "$vrai" update-ref refs/remotes/origin/dev "$(cat "$w/concurrent")" || exit 1
      rm -f "$w/concurrent"
    fi
    code=0
    "$vrai" -c "url.$w/forge/.insteadOf=$url" "$@" 2> "$w/.git-err" || code=$?
    if [ "$premier" = push ] && [ "$code" = 0 ] && [ -f "$w/apres-push" ]; then
      # quelqu'un pousse sur dev juste après nous
      "$vrai" --git-dir="$forge" update-ref refs/heads/dev "$(cat "$w/apres-push")" || exit 1
      rm -f "$w/apres-push"
    fi
    # la vraie forge se nomme par son adresse dans les messages de git : on la remet
    sed "s#$w/forge/#$url#g" "$w/.git-err" >&2
    exit "$code"
    ;;
esac
exec "$vrai" "$@"
FAUX
  } > "$work/bin/git"
  chmod +x "$work/bin/git"
}

# Le faux curl de test-release.sh, plus le déplacement de main **dans le dépôt nu** quand un
# fast-forward aboutit : le dépôt local, lui, ne le sait pas tant qu'il n'a pas relu la forge.
faux_curl() {
  mkdir -p "$work/bin" "$work/api"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    printf 'forge=%q\n' "$forge"
    cat <<'FAUX'
cat > /dev/null 2>&1
out=""; methode=GET; url=""; corps=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift 2 ;;
    -X) methode=$2; shift 2 ;;
    -H) shift 2 ;;
    -w) shift 2 ;;
    -K) shift 2 ;;
    --data) corps=${2#@}; shift 2 ;;
    -s) shift ;;
    *) url=$1; shift ;;
  esac
done
chemin=${url#*/api/v1}
cle=$(printf '%s %s' "$methode" "$chemin" | sed 's#[^A-Za-z0-9]#_#g')
printf '%s %s\n' "$methode" "$chemin" >> "$w/api-appels"
if [ -n "$corps" ]; then cat "$corps" >> "$w/api-corps"; printf '\n' >> "$w/api-corps"; fi
n=1
[ -f "$w/api-rang-$cle" ] && n=$(($(cat "$w/api-rang-$cle") + 1))
printf '%s' "$n" > "$w/api-rang-$cle"
rep="$w/api/$cle.$n"
[ -f "$rep" ] || rep="$w/api/$cle"
if [ -f "$w/fusionnee" ] && [ -f "$w/api/$cle.apres" ]; then rep="$w/api/$cle.apres"; fi
if [ -f "$rep" ]; then cat "$rep" > "$out"; else printf '{}' > "$out"; fi
code="$w/api/$cle.$n.code"
[ -f "$code" ] || code="$w/api/$cle.code"
valeur=200
[ -f "$code" ] && valeur=$(cat "$code")
case "$chemin" in
  */merge)
    if [ "$methode" = POST ] && [ "$valeur" = 200 ]; then
      : > "$w/fusionnee"
      tete=$(sed -n 's/.*"head_commit_id": *"\([0-9a-f]*\)".*/\1/p' "$corps")
      git --git-dir="$forge" update-ref refs/heads/main "$tete" || exit 1
    fi
    ;;
esac
printf '%s' "$valeur"
exit 0
FAUX
  } > "$work/bin/curl"
  chmod +x "$work/bin/curl"
}

faux_sleep() {
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$*" >> %q\n' "$work/sleeps"
    printf 'exit 0\n'
  } > "$work/bin/sleep"
  chmod +x "$work/bin/sleep"
}

# --- les réponses de l'API ----------------------------------------------------------------------

cle_api() { printf '%s %s' "$1" "$2" | sed 's#[^A-Za-z0-9]#_#g'; }

api() { # $1 = méthode, $2 = chemin, $3 = code HTTP, $4 = corps JSON
  local c; c=$(cle_api "$1" "$2"); mkdir -p "$work/api"
  printf '%s' "$4" > "$work/api/$c"
  printf '%s' "$3" > "$work/api/$c.code"
}

api_rang() { # $1 = méthode, $2 = chemin, $3 = rang de l'appel, $4 = code HTTP, $5 = corps JSON
  local c; c=$(cle_api "$1" "$2"); mkdir -p "$work/api"
  printf '%s' "$5" > "$work/api/$c.$3"
  printf '%s' "$4" > "$work/api/$c.$3.code"
}

api_apres() { # $1 = méthode, $2 = chemin, $3 = corps JSON servi une fois la fusion faite
  local c; c=$(cle_api "$1" "$2"); mkdir -p "$work/api"
  printf '%s' "$3" > "$work/api/$c.apres"
}

appels_api() { [[ -f $work/api-appels ]] && cat "$work/api-appels"; return 0; }
appels_git() { [[ -f $work/git-appels ]] && cat "$work/git-appels"; return 0; }
aucun_appel_api() {
  [[ ! -f $work/api-appels ]] \
    || { printf 'la forge a été appelée malgré le refus :\n%s\n' "$(appels_api)" >&2; exit 1; }
}
aucun_push() {
  local pushes; pushes=$(grep -E '(^| )push( |$)' "$work/git-appels" 2>/dev/null || true)
  [[ -z $pushes ]] || { printf 'un push a eu lieu :\n%s\n' "$pushes" >&2; exit 1; }
}
aucune_fusion() {
  assert_eq "" "$(grep -o '/merge' "$work/api-appels" 2>/dev/null || true)" "aucune fusion n'est demandée"
}
aucun_cherry_pick() {
  assert_eq "" "$(grep -E '(^| )cherry-pick( |$)' "$work/git-appels" 2>/dev/null || true)" "aucun cherry-pick n'est lancé"
}
aucune_adresse() {
  assert_eq "" "$(grep -oi 'forge.invalide\|jeton-essai' <<< "$out$err" || true)" "aucune adresse ni jeton affiché"
}

# État de la forge : une branche du dépôt nu.
forge_ref() { git --git-dir="$forge" rev-parse --verify --quiet "refs/heads/$1" || true; }

pr_json() { # $1 = SHA de tête, $2 = branche (défaut hotfix/lien-casse), $3 = base (défaut main), $4 = champs jq en plus
  jq -nc --arg s "$1" --arg h "${2:-hotfix/lien-casse}" --arg b "${3:-main}" \
    "{number: 7, state: \"open\", draft: false, mergeable: true, merged: false, title: \"Correctif\",
      base: {ref: \$b}, head: {ref: \$h, sha: \$s}} ${4:-}"
}

rapport() { # $1 = SHA, $2 = base, $3 = verdict : un commentaire llm-review dans la timeline
  jq -nc --arg l "llm-review sha=$1 base=$2 model=modele-essai verdict=$3" \
    '{type: "comment", user: {login: "compte-essai"}, body: ($l + "\n\nrapport")}'
}

# --- le dépôt de test ------------------------------------------------------------------------------

temoin() { # $1 = nom, $2 = dossier du témoin dans le dépôt (scripts)
  local dossier=${2:-scripts}
  mkdir -p "$depot/$dossier"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s %%s\\n" "%s" "$*" >> %q\n' "$1" "$work/controles"
    # shellcheck disable=SC2016 # script écrit pour un autre shell : ses « $ » s'y développent, pas ici
    printf 'if [ -f %q/code-%s ]; then printf "refus de %s\\n" >&2; exit "$(cat %q/code-%s)"; fi\n' \
      "$work" "$1" "$1" "$work" "$1"
    printf 'exit 0\n'
  } > "$depot/$dossier/$1.sh"
  chmod +x "$depot/$dossier/$1.sh"
}

controles_lances() { [[ -f $work/controles ]] && cat "$work/controles"; return 0; }

commit() { # $1 = message, $2 = fichier modifié (défaut : site.txt), $3 = contenu (défaut : le message)
  printf '%s\n' "${3:-$1}" >> "$depot/${2:-site.txt}"
  git -C "$depot" add -A
  git -C "$depot" commit -q -m "$1"
  git -C "$depot" rev-parse HEAD
}

vers_forge() { # pousse des références vers le dépôt nu, sans passer par le faux git
  git -C "$depot" push -q --force "$forge" "$@" 2>/dev/null
}

relit_forge() { # met refs/remotes/origin/* du dépôt local à jour, sans passer par le faux git
  git -C "$depot" fetch -q --tags "$forge" '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null
}

# Le dépôt de test : main tagué v1.0.0 puis v1.0.1, dev qui le prolonge d'un commit, la forge à
# l'identique, et la branche locale dev en tête. $1 = 0 pour un main sans workflow des contrôles.
depot_de_test() {
  local avec_ci=${1:-1}
  new_repo
  git -C "$depot" config advice.detachedHead false
  mkdir -p "$depot/scripts"
  temoin check-private
  temoin sprint-consistency .working-method/gates
  cp "$root/workflow.config" "$depot/workflow.config"
  printf '.env\n' > "$depot/.gitignore"
  if [[ $avec_ci == 1 ]]; then
    mkdir -p "$depot/.gitea/workflows"
    printf 'name: checks\n' > "$depot/.gitea/workflows/checks.yaml"
  fi
  printf 'ligne 1\nligne 2\nligne 3\n' > "$depot/site.txt"
  commit "socle (#1)" autre.txt > /dev/null
  git -C "$depot" branch -M main
  git -C "$depot" tag v1.0.0
  commit "feat(1.1): quelque chose (#2)" autre.txt > /dev/null
  git -C "$depot" tag v1.0.1
  git -C "$depot" checkout -q -b dev
  commit "feat(2.1): travail de dev (#3)" dev.txt > /dev/null
  mkdir -p "$(dirname "$forge")"
  git init -q --bare -b main "$forge"
  git --git-dir="$forge" config core.hooksPath "$forge/hooks"
  vers_forge refs/heads/main:refs/heads/main refs/heads/dev:refs/heads/dev --tags
  git -C "$depot" remote add origin "${url_forge}$repo.git"
  relit_forge
  printf 'GITEA_URL=https://forge.invalide\nGITEA_USER=compte-essai\nGITEA_TOKEN=jeton-essai\n' > "$depot/.env"
  printf 'MOTIFFACTICE\n' > "$work/motifs.txt"
  faux_git; faux_curl; faux_sleep
}

# La forge refuse les push qui touchent une référence : un hook pre-receive du dépôt nu, comme la
# protection de branche de Gitea. $1 = motif de référence (refs/tags/ ou refs/heads/dev).
forge_refuse() {
  mkdir -p "$forge/hooks"
  {
    printf '#!/bin/sh\n'
    printf 'while read old new ref; do\n'
    # shellcheck disable=SC2016 # script écrit pour un autre shell : ses « $ » s'y développent, pas ici
    printf '  case "$ref" in %s*) echo "branch is protected from force push" >&2; exit 1 ;; esac\n' "$1"
    printf 'done\nexit 0\n'
  } > "$forge/hooks/pre-receive"
  chmod +x "$forge/hooks/pre-receive"
}

# Une branche de correctif poussée : hotfix/<nom> depuis main, un commit, sur la forge. Affiche sa tête.
branche_correctif() { # $1 = nom (défaut lien-casse)
  local nom=${1:-lien-casse} sha
  git -C "$depot" checkout -q -b "hotfix/$nom" main
  sha=$(commit "fix: lien du CV cassé" correctif.txt)
  vers_forge "refs/heads/hotfix/$nom:refs/heads/hotfix/$nom"
  relit_forge
  printf '%s\n' "$sha"
}

# Les réponses nominales de l'API pour la PR n° 7 de la branche : jeton reconnu, aucune PR ouverte,
# création acceptée, rapport pass sur la tête, CI verte, fusion acceptée.
forge_prete() { # $1 = SHA de tête, $2 = branche (défaut hotfix/lien-casse)
  local tete=$1 branche=${2:-hotfix/lien-casse}
  api GET /user 200 '{"login":"compte-essai"}'
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 '[]'
  api POST "/repos/$repo/pulls" 201 '{"number": 7}'
  api GET "/repos/$repo/pulls/7" 200 "$(pr_json "$tete" "$branche")"
  api GET /settings/api 200 '{"max_response_items": 50}'
  api GET "/repos/$repo/issues/7/timeline?limit=50&page=1" 200 "[$(rapport "$tete" main pass)]"
  api GET "/repos/$repo/commits/$tete/status" 200 '{"statuses": [{"context": "checks / checks (pull_request)", "status": "success"}]}'
  api POST "/repos/$repo/pulls/7/merge" 200 '{}'
  api_apres GET "/repos/$repo/pulls/7" "$(pr_json "$tete" "$branche" main '| .merged = true')"
}

# L'état que laisse un correctif publié : main porte un commit (et le tag v1.0.2) que dev n'a pas.
# $1 = contenu de la ligne 2 de site.txt dans le correctif (défaut : un fichier à part, sans conflit)
correctif_publie() {
  local ligne=${1:-} sha
  git -C "$depot" checkout -q -b hotfix/publie main
  if [[ -n $ligne ]]; then
    sed -i "2s/.*/$ligne/" "$depot/site.txt"
    git -C "$depot" commit -q -am "fix: correctif en conflit"
    sha=$(git -C "$depot" rev-parse HEAD)
  else
    sha=$(commit "fix: correctif publié" correctif.txt)
  fi
  git -C "$depot" tag v1.0.2
  vers_forge "$sha:refs/heads/main" refs/tags/v1.0.2
  git -C "$depot" checkout -q dev
  git -C "$depot" branch -q -D hotfix/publie
  printf '%s\n' "$sha"
}

lance() { # arguments de hotfix.sh
  # shellcheck disable=SC2016 # script écrit pour un autre shell : ses « $ » s'y développent, pas ici
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work" LC_ALL=C \
    PRIVATE_PATTERNS_FILE="$work/motifs.txt" \
    bash -c 'cd "$1" && shift && exec bash "$@"' _ "$depot" "$script" "$@"
}

etat_sync() { git -C "$depot" rev-parse --git-path hotfix-sync | sed "s#^#$depot/#"; }

# --- usage -------------------------------------------------------------------------------------------

case_hotfix_usage_sans_sous_commande() {
  depot_de_test
  lance
  assert_eq 2 "$rc" "sans sous-commande, c'est une anomalie d'usage (messages : $err)"
  assert_contains "usage" "$err" "le message donne l'usage"
  aucun_appel_api
}

case_hotfix_usage_sous_commande_inconnue() {
  depot_de_test
  lance finish
  assert_eq 2 "$rc" "une sous-commande inconnue est une anomalie (messages : $err)"
  assert_contains "sous-commande inconnue" "$err" "le message la nomme"
}

case_hotfix_usage_option_inconnue() {
  # Il n'existe aucune option --force, et --merge n'appartient qu'à publish, --push qu'à sync.
  depot_de_test
  local essai
  for essai in "publish --force" "sync --force" "publish --push" "sync --merge" "start lien --merge"; do
    # shellcheck disable=SC2086 # découpage voulu : chaque essai est une ligne de commande
    lance $essai
    assert_eq 2 "$rc" "« $essai » est une anomalie d'usage (messages : $err)"
  done
  aucun_appel_api
  aucun_push
}

# --- start -------------------------------------------------------------------------------------------

case_hotfix_start_nom_refuse() {
  depot_de_test
  local nom
  for nom in Lien 1-2-lien lien_casse lien--casse lien/casse lien- "lien casse" ""; do
    lance start "$nom"
    assert_eq 2 "$rc" "le nom $(printf '%q' "$nom") est refusé (messages : $err)"
  done
  assert_eq "" "$(git -C "$depot" branch --list 'hotfix/*')" "aucune branche n'est créée"
  assert_eq "" "$(grep -E '(^| )fetch( |$)' "$work/git-appels" 2>/dev/null || true)" "la forge n'est pas lue"
}

case_hotfix_start_nominal() {
  # La branche part de main **relue sur la forge**, pas de la main locale en retard.
  depot_de_test
  git -C "$depot" checkout -q main
  local nouveau; nouveau=$(commit "feat: arrivé par release (#4)" autre.txt)
  vers_forge refs/heads/main:refs/heads/main refs/heads/main:refs/heads/dev
  git -C "$depot" reset -q --hard HEAD~1
  git -C "$depot" update-ref refs/remotes/origin/main HEAD
  git -C "$depot" checkout -q dev
  lance start lien-casse
  assert_eq 0 "$rc" "la branche est créée (messages : $err)"
  assert_eq "hotfix/lien-casse" "$(git -C "$depot" symbolic-ref --short HEAD)" "et on s'y trouve"
  assert_eq "$nouveau" "$(git -C "$depot" rev-parse HEAD)" "elle part de main relue sur la forge"
  assert_eq "" "$(git -C "$depot" config --get branch.hotfix/lien-casse.merge || true)" "sans suivre main"
  assert_contains "git push -u origin hotfix/lien-casse" "$out" "la suite est dite"
  assert_contains "llm-review.sh" "$out" "revue comprise"
  assert_contains "tant qu'elle n'a pas eu lieu" "$out" "les apostrophes des consignes sont rendues"
  assert_contains "publish --merge" "$out" "et la fusion par Arnaud"
  aucun_push
  aucun_appel_api
  assert_eq "" "$(forge_ref hotfix/lien-casse)" "rien n'est créé sur la forge"
}

case_hotfix_start_invariant_rompu() {
  # Un correctif précédent non synchronisé : main porte un commit que dev n'a pas.
  depot_de_test
  correctif_publie > /dev/null
  lance start lien-casse
  assert_eq 1 "$rc" "main hors de dev est un refus (messages : $err)"
  assert_contains "sync" "$err" "le message renvoie à sync"
  assert_eq "" "$(git -C "$depot" branch --list 'hotfix/*')" "aucune branche n'est créée"
}

case_hotfix_start_branche_locale_existante() {
  depot_de_test
  git -C "$depot" branch hotfix/lien-casse main
  lance start lien-casse
  assert_eq 1 "$rc" "une branche locale du même nom est un refus (messages : $err)"
  assert_contains "existe déjà dans ce dépôt" "$err" "le message le dit"
  assert_eq "dev" "$(git -C "$depot" symbolic-ref --short HEAD)" "on reste sur dev"
}

case_hotfix_start_branche_distante_existante() {
  depot_de_test
  vers_forge refs/heads/main:refs/heads/hotfix/lien-casse
  lance start lien-casse
  assert_eq 1 "$rc" "une branche du même nom sur la forge est un refus (messages : $err)"
  assert_contains "existe déjà sur la forge" "$err" "le message le dit"
  assert_eq "" "$(git -C "$depot" branch --list 'hotfix/*')" "aucune branche n'est créée"
}

case_hotfix_start_arbre_sale() {
  depot_de_test
  printf 'travail en cours\n' >> "$depot/dev.txt"
  lance start lien-casse
  assert_eq 2 "$rc" "un arbre modifié arrête tout (messages : $err)"
  assert_contains "non commitées" "$err" "le message dit pourquoi"
  assert_eq "" "$(git -C "$depot" branch --list 'hotfix/*')" "aucune branche n'est créée"
}

# --- publish : ce qui se vérifie avant la forge ---------------------------------------------------

case_hotfix_publish_hors_branche_hotfix() {
  depot_de_test
  lance publish
  assert_eq 1 "$rc" "publish sur dev est un refus (messages : $err)"
  assert_contains "hotfix/<nom>" "$err" "le message dit où le lancer"
  aucun_appel_api
}

case_hotfix_publish_branche_non_poussee() {
  depot_de_test
  git -C "$depot" checkout -q -b hotfix/lien-casse main
  commit "fix: pas encore poussé" correctif.txt > /dev/null
  lance publish
  assert_eq 1 "$rc" "une branche absente de la forge est un refus (messages : $err)"
  assert_contains "git push -u origin hotfix/lien-casse" "$err" "le message dit quoi faire"
  aucun_appel_api
}

case_hotfix_publish_tete_locale_differente() {
  depot_de_test
  branche_correctif > /dev/null
  commit "fix: second commit, non poussé" correctif.txt > /dev/null
  lance publish
  assert_eq 1 "$rc" "une tête locale différente de la forge est un refus (messages : $err)"
  assert_contains "n'est pas celle de la forge" "$err" "le message le dit"
  aucun_appel_api
}

case_hotfix_publish_main_a_avance() {
  # main a bougé depuis le début du correctif : le fast-forward est impossible.
  depot_de_test
  branche_correctif > /dev/null
  git -C "$depot" checkout -q main
  commit "feat: main a avancé (#5)" autre.txt > /dev/null
  vers_forge refs/heads/main:refs/heads/main
  git -C "$depot" checkout -q hotfix/lien-casse
  lance publish
  assert_eq 1 "$rc" "une branche qui ne descend plus de main est un refus (messages : $err)"
  assert_contains "Rebaser la branche" "$err" "le message dit quoi faire"
  aucun_appel_api
}

case_hotfix_publish_commit_de_fusion() {
  depot_de_test
  branche_correctif > /dev/null
  git -C "$depot" checkout -q -b cote main
  commit "fix: de côté" cote.txt > /dev/null
  git -C "$depot" checkout -q hotfix/lien-casse
  git -C "$depot" merge -q --no-ff -m "Merge branch 'cote'" cote
  vers_forge refs/heads/hotfix/lien-casse:refs/heads/hotfix/lien-casse
  lance publish
  assert_eq 1 "$rc" "un commit de fusion est un refus (messages : $err)"
  assert_contains "commit de fusion" "$err" "le message le nomme"
  aucun_appel_api
}

case_hotfix_publish_rien_a_publier() {
  depot_de_test
  git -C "$depot" checkout -q -b hotfix/lien-casse main
  vers_forge refs/heads/hotfix/lien-casse:refs/heads/hotfix/lien-casse
  lance publish
  assert_eq 1 "$rc" "une branche sans commit est un refus (messages : $err)"
  assert_contains "aucun correctif à publier" "$err" "le message le dit"
  aucun_appel_api
}

# --- le tag calculé (arbitrage Q4) -------------------------------------------------------------------

case_hotfix_tag_calcule_numerique() {
  # v1.10.0 est plus haut que v1.9.0 (un tri de texte dirait l'inverse) ; un -rc atteignable depuis
  # main n'est jamais retenu ; un tag posé hors de main non plus.
  depot_de_test
  git -C "$depot" tag v1.9.0 main
  git -C "$depot" tag v1.10.0 main
  git -C "$depot" tag v1.10.7-rc.1 main
  git -C "$depot" tag v2.0.0 dev
  vers_forge --tags
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  lance publish
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  assert_contains "correctif v1.10.1 (après v1.10.0)" "$out" "le tag suivant est v1.10.1"
  assert_contains "Correctif de production v1.10.1" "$(cat "$work/api-corps")" "il est dans le titre de la PR"
}

case_hotfix_tag_aucun_tag_de_production() {
  # Seuls des tags de répétition : aucune version de production à corriger.
  depot_de_test
  git -C "$depot" tag -d v1.0.0 v1.0.1 > /dev/null
  git --git-dir="$forge" tag -d v1.0.0 v1.0.1 > /dev/null
  git -C "$depot" tag v1.0.0-rc.1 main
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  lance publish
  assert_eq 1 "$rc" "sans tag vX.Y.Z, c'est un refus (messages : $err)"
  assert_contains "aucun tag vX.Y.Z" "$err" "le message le dit"
  aucun_appel_api
}

case_hotfix_tag_calcule_deja_pris() {
  # v1.0.2 existe déjà, hors de main : le numéro suivant n'est pas libre.
  depot_de_test
  git -C "$depot" tag v1.0.2 dev
  vers_forge --tags
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  lance publish
  assert_eq 1 "$rc" "un tag calculé déjà posé est un refus (messages : $err)"
  assert_contains "v1.0.2" "$err" "le message nomme le tag"
  aucun_appel_api
}

case_hotfix_tag_repetition_du_meme_numero() {
  # Une répétition de dev porte déjà v1.0.2-rc.1 : le correctif prend le numéro, et le dit.
  depot_de_test
  git -C "$depot" tag v1.0.2-rc.1 dev
  vers_forge --tags
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  lance publish
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  assert_contains "avertissement" "$out" "l'avertissement est affiché"
  assert_contains "v1.0.2-rc.1" "$out" "il nomme la répétition"
}

# --- la PR et les verrous ------------------------------------------------------------------------------

case_hotfix_publish_ouvre_la_pr_sans_rien_fusionner() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  lance publish
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  local corps; corps=$(cat "$work/api-corps")
  assert_contains '"base": "main"' "$corps" "la PR va vers main"
  assert_contains '"head": "hotfix/lien-casse"' "$corps" "depuis la branche du correctif"
  assert_contains "publish --merge" "$out" "le script dit où il s'arrête"
  aucune_fusion
  aucun_push
  assert_eq "" "$(git -C "$depot" tag --list v1.0.2)" "aucun tag n'est posé"
  assert_eq "$(git -C "$depot" rev-parse v1.0.1)" "$(forge_ref main)" "main n'a pas bougé"
}

case_hotfix_publish_pr_deja_ouverte() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 "[$(pr_json "$tete")]"
  lance publish
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  assert_eq "" "$(grep -x "POST /repos/$repo/pulls" "$work/api-appels" || true)" "aucune seconde PR n'est ouverte"
  assert_contains "déjà ouverte" "$out" "le script le dit"
}

case_hotfix_publish_pr_trouvee_en_seconde_page() {
  depot_de_test
  local tete page; tete=$(branche_correctif)
  forge_prete "$tete"
  page=$(jq -nc '[range(50) | {number: (100 + .), head: {ref: "feat/autre"}, base: {ref: "dev"}}]')
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 "$page"
  api GET "/repos/$repo/pulls?state=open&limit=50&page=2" 200 "[$(pr_json "$tete")]"
  lance publish
  assert_eq 0 "$rc" "la PR de la seconde page est retrouvée (messages : $err)"
  assert_eq "" "$(grep -x "POST /repos/$repo/pulls" "$work/api-appels" || true)" "aucune seconde PR n'est ouverte"
}

case_hotfix_publish_pr_vers_dev_bloque() {
  # Une PR hotfix/* → dev ouverte à la main ne passe pas inaperçue.
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 "[$(pr_json "$tete" hotfix/lien-casse dev)]"
  api GET "/repos/$repo/pulls/7" 200 "$(pr_json "$tete" hotfix/lien-casse dev)"
  lance publish --merge
  assert_eq 1 "$rc" "une PR vers dev bloque (messages : $err)"
  assert_contains "hotfix/lien-casse → dev" "$out" "le verrou la nomme"
  assert_eq "" "$(grep -x "POST /repos/$repo/pulls" "$work/api-appels" || true)" "elle est retrouvée : aucune seconde PR n'est ouverte"
  aucune_fusion
}

case_hotfix_publish_motif_prive_dans_le_titre() {
  depot_de_test
  printf 'motifprive\n' > "$work/motifs.txt"
  local tete; tete=$(branche_correctif motifprive-lien)
  forge_prete "$tete" hotfix/motifprive-lien
  lance publish
  assert_eq 1 "$rc" "un motif dans le titre arrête tout (messages : $err)"
  assert_contains "motif privé" "$err" "le message le dit sans recopier le motif"
  assert_eq "" "$(grep -x "POST /repos/$repo/pulls" "$work/api-appels" || true)" "aucune PR n'est ouverte"
}

case_hotfix_publish_tete_de_pr_decalee() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/pulls/7" 200 "$(pr_json 0000000000000000000000000000000000000000)"
  lance publish --merge
  assert_eq 1 "$rc" "une tête décalée bloque (messages : $err)"
  assert_contains "n'est pas celle de la branche poussée" "$out" "le verrou le dit"
  aucune_fusion
}

case_hotfix_publish_pr_en_brouillon() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/pulls/7" 200 "$(pr_json "$tete" "" "" '| .draft = true')"
  lance publish
  assert_eq 1 "$rc" "une PR en brouillon bloque (messages : $err)"
  assert_contains "brouillon" "$out" "le verrou le dit"
}

case_hotfix_publish_mergeable_nul_puis_vrai() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api_rang GET "/repos/$repo/pulls/7" 1 200 "$(pr_json "$tete" "" "" '| .mergeable = null')"
  lance publish
  assert_eq 0 "$rc" "la seconde lecture tranche (messages : $err)"
  assert_contains "3" "$(cat "$work/sleeps")" "le script a attendu entre les deux lectures"
}

case_hotfix_revue_absente() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/issues/7/timeline?limit=50&page=1" 200 '[]'
  lance publish --merge
  assert_eq 1 "$rc" "sans rapport, la revue bloque (messages : $err)"
  assert_contains "llm-review.sh 7" "$out" "le verrou dit quelle commande lancer"
  aucune_fusion
}

case_hotfix_revue_bloquante() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/issues/7/timeline?limit=50&page=1" 200 "[$(rapport "$tete" main pass), $(rapport "$tete" main block)]"
  lance publish
  assert_eq 1 "$rc" "le dernier rapport block bloque (messages : $err)"
  assert_contains "block" "$out" "le verrou le dit"
}

case_hotfix_revue_sur_le_parent_ne_suffit_pas() {
  # Aucun commit de statut ne suit la revue d'un correctif : un rapport sur le parent ne vaut rien.
  depot_de_test
  local tete parent; tete=$(branche_correctif)
  parent=$(git -C "$depot" rev-parse "$tete^")
  forge_prete "$tete"
  api GET "/repos/$repo/issues/7/timeline?limit=50&page=1" 200 "[$(rapport "$parent" main pass)]"
  lance publish
  assert_eq 1 "$rc" "un rapport sur le parent bloque (messages : $err)"
  assert_contains "aucun rapport" "$out" "le verrou le dit"
}

case_hotfix_revue_sur_une_autre_base_ne_suffit_pas() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/issues/7/timeline?limit=50&page=1" 200 "[$(rapport "$tete" dev pass)]"
  lance publish
  assert_eq 1 "$rc" "un rapport base=dev bloque (messages : $err)"
}

case_hotfix_garde_fou_refuse() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  printf '1' > "$work/code-check-private"
  lance publish
  assert_eq 1 "$rc" "le garde-fou bloque (messages : $err)"
  assert_contains "check-private.sh refuse" "$out" "le verrou le dit"
  assert_contains "history $(git -C "$depot" rev-parse v1.0.1)..$tete" "$(controles_lances)" "lancé sur main..branche"
}

case_hotfix_ci_rouge() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/commits/$tete/status" 200 '{"statuses": [{"context": "checks / checks (pull_request)", "status": "failure"}]}'
  lance publish
  assert_eq 1 "$rc" "une CI rouge bloque (messages : $err)"
  assert_contains "failure" "$out" "l'état fautif est nommé"
}

case_hotfix_ci_absente_refuse_l_amorcage() {
  # Sans checks.yaml sur main, ci_gate rend « amorçage » : un correctif ne s'en contente pas.
  depot_de_test 0
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api GET "/repos/$repo/commits/$tete/status" 200 '{"statuses": []}'
  lance publish
  assert_eq 1 "$rc" "une CI sans statut bloque (messages : $err)"
  assert_contains "substitut d'amorçage" "$out" "le verrou dit que le régime est refusé"
}

case_hotfix_suivi_de_sprint_global() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  lance publish
  assert_eq 0 "$rc" "le suivi est cohérent (messages : $err)"
  assert_contains "sprint-consistency --rev $tete" "$(controles_lances)" "appelé en mode global"
  assert_eq "" "$(grep -o -- '--merge' <<< "$(controles_lances)" || true)" "jamais avec --merge <n.m>"
}

case_hotfix_suivi_de_sprint_incoherent() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  printf '1' > "$work/code-sprint-consistency"
  lance publish
  assert_eq 1 "$rc" "un suivi incohérent bloque (messages : $err)"
  assert_contains "suivi de sprint" "$out" "le verrou est nommé"
}

case_hotfix_publish_env_incomplet() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  printf 'GITEA_URL=https://forge.invalide\nGITEA_USER=compte-essai\n' > "$depot/.env"
  lance publish
  assert_eq 2 "$rc" "une variable Gitea manquante est une anomalie (messages : $err)"
  assert_contains "GITEA_TOKEN" "$err" "le message nomme la variable"
  assert_contains "gitea-token.md" "$err" "et renvoie à la procédure du jeton (story 0.1)"
  aucun_appel_api
}

# --- la fusion et le tag ---------------------------------------------------------------------------------

case_hotfix_merge_nominal() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  lance publish --merge
  assert_eq 0 "$rc" "la publication aboutit (messages : $err)"
  local corps; corps=$(cat "$work/api-corps")
  assert_contains '"Do": "fast-forward-only"' "$corps" "le style de fusion est imposé (AD-24)"
  assert_contains "\"head_commit_id\": \"$tete\"" "$corps" "sur le SHA relu"
  assert_eq "" "$(grep -o 'force_merge\|merge_when_checks_succeed\|delete_branch_after_merge' <<< "$corps" || true)" \
    "ni force, ni suppression de branche"
  assert_eq "$tete" "$(forge_ref main)" "main porte le correctif sur la forge"
  assert_eq "$tete" "$(git --git-dir="$forge" rev-parse 'v1.0.2^{commit}')" "le tag v1.0.2 est poussé sur la tête fusionnée"
  assert_eq "tag" "$(git --git-dir="$forge" cat-file -t v1.0.2)" "c'est un tag annoté"
  assert_contains "sync" "$out" "la suite est dite"
  aucun_cherry_pick
  aucune_adresse
}

case_hotfix_merge_refuse_si_verrou_bloque() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  printf '1' > "$work/code-check-private"
  lance publish --merge
  assert_eq 1 "$rc" "un verrou bloquant arrête --merge (messages : $err)"
  assert_contains "aucun tag n'est posé" "$out" "le script le dit"
  aucune_fusion
  aucun_push
}

case_hotfix_merge_tete_bougee_pendant_l_audit() {
  # La relecture d'avant fusion trouve une autre tête : rien n'est fusionné sur un SHA non audité.
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api_rang GET "/repos/$repo/pulls/7" 2 200 "$(pr_json 4444444444444444444444444444444444444444)"
  lance publish --merge
  assert_eq 2 "$rc" "une tête qui a bougé est une anomalie (messages : $err)"
  assert_contains "a bougé pendant l'audit" "$err" "le message le dit"
  aucune_fusion
  aucun_push
}

case_hotfix_merge_405_transitoire() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api_rang POST "/repos/$repo/pulls/7/merge" 1 405 '{"message": "Please try again later"}'
  lance publish --merge
  assert_eq 0 "$rc" "la reprise aboutit (messages : $err)"
  assert_contains "405 transitoire" "$out" "la reprise est dite"
  assert_eq "$tete" "$(git --git-dir="$forge" rev-parse 'v1.0.2^{commit}')" "et le tag est posé"
}

case_hotfix_merge_405_persistant() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api POST "/repos/$repo/pulls/7/merge" 405 '{"message": "Merge style is not allowed"}'
  lance publish --merge
  assert_eq 1 "$rc" "un 405 de style est un refus (messages : $err)"
  assert_contains "style de fusion" "$err" "le message le dit"
  assert_eq "" "$(cat "$work/sleeps" 2>/dev/null || true)" "aucune reprise pour un refus"
  aucun_push
}

case_hotfix_merge_500_divergence() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api POST "/repos/$repo/pulls/7/merge" 500 '{"message": "Merge DivergingFastForwardOnly"}'
  lance publish --merge
  assert_eq 1 "$rc" "une divergence est un refus (messages : $err)"
  assert_contains "divergé" "$err" "le message la nomme"
  aucun_push
}

case_hotfix_fusion_non_confirmee() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  api_apres GET "/repos/$repo/pulls/7" "$(pr_json "$tete")"
  lance publish --merge
  assert_eq 2 "$rc" "une fusion non confirmée est une anomalie (messages : $err)"
  assert_contains "n'apparaît pas fusionnée" "$err" "le message le dit"
  aucun_push
}

case_hotfix_tag_refuse_si_main_non_relue() {
  # La fusion passe par l'API : sans relecture, origin/main est l'ancien main. Le faux git rend le
  # fetch d'après-fusion inerte — le script doit refuser de taguer, jamais taguer l'ancien commit.
  depot_de_test
  local tete ancien; tete=$(branche_correctif)
  ancien=$(git -C "$depot" rev-parse v1.0.1)
  forge_prete "$tete"
  : > "$work/fetch-inerte-apres-fusion"
  lance publish --merge
  assert_eq 2 "$rc" "un état incohérent après la fusion est une anomalie (messages : $err)"
  assert_contains "aucun tag n'est posé" "$err" "le message le dit"
  assert_contains "${ancien:0:7}" "$err" "et nomme le commit trouvé sur main"
  assert_eq "" "$(git -C "$depot" tag --list v1.0.2)" "aucun tag local"
  aucun_push
}

case_hotfix_push_du_tag_en_echec() {
  depot_de_test
  local tete; tete=$(branche_correctif)
  forge_prete "$tete"
  forge_refuse refs/tags/
  lance publish --merge
  assert_eq 2 "$rc" "un push de tag refusé est une anomalie (messages : $err)"
  assert_eq "" "$(git -C "$depot" tag --list v1.0.2)" "le tag local est retiré"
  assert_eq "" "$(git --git-dir="$forge" tag --list v1.0.2)" "et rien n'est sur la forge"
  assert_contains "git push origin refs/tags/v1.0.2" "$err" "le message dit comment le poser à la main"
  aucune_adresse
}

# --- sync --------------------------------------------------------------------------------------------------

case_hotfix_sync_rien_a_synchroniser() {
  depot_de_test
  lance sync
  assert_eq 0 "$rc" "rien à faire n'est pas une erreur (messages : $err)"
  assert_contains "rien à synchroniser" "$out" "le script le dit"
  assert_eq "" "$(ls "$(etat_sync)" 2>/dev/null || true)" "aucun état n'est écrit"
  aucun_push
}

case_hotfix_sync_arbre_sale() {
  depot_de_test
  correctif_publie > /dev/null
  printf 'travail en cours\n' >> "$depot/dev.txt"
  lance sync
  assert_eq 2 "$rc" "un arbre modifié arrête tout (messages : $err)"
  assert_contains "non commitées" "$err" "le message dit pourquoi"
  assert_eq "" "$(grep -E '(^| )rebase( |$)' "$work/git-appels" || true)" "aucun rebase n'est lancé"
}

case_hotfix_sync_audit_ne_pousse_rien() {
  depot_de_test
  local correctif dev_forge; correctif=$(correctif_publie)
  dev_forge=$(forge_ref dev)
  lance sync
  assert_eq 0 "$rc" "l'audit va au bout (messages : $err)"
  git -C "$depot" merge-base --is-ancestor "$correctif" dev \
    || { echo "dev locale ne contient pas le correctif" >&2; exit 1; }
  assert_eq "$dev_forge" "$(forge_ref dev)" "dev n'a pas bougé sur la forge"
  assert_contains "git push --force-with-lease=dev:$dev_forge origin dev" "$out" "le script dit ce que --push ferait"
  assert_contains "rien n'est poussé" "$out" "et qu'il ne l'a pas fait"
  [[ -f $(etat_sync) ]] || { echo "l'état n'est pas conservé pour --push" >&2; exit 1; }
  aucun_push
  aucun_cherry_pick
}

case_hotfix_sync_dev_locale_perimee_remise() {
  # dev locale en retard sur la forge : elle est remise sur origin/dev, jamais rebasée telle quelle.
  depot_de_test
  local perime; perime=$(git -C "$depot" rev-parse dev)
  commit "feat(2.2): autre travail de dev (#6)" dev.txt > /dev/null
  vers_forge refs/heads/dev:refs/heads/dev
  git -C "$depot" reset -q --hard "$perime"
  correctif_publie > /dev/null
  lance sync
  assert_eq 0 "$rc" "la synchronisation va au bout (messages : $err)"
  assert_contains "feat(2.2): autre travail de dev (#6)" "$(git -C "$depot" log --format=%s dev)" \
    "la dev rebasée porte le dernier commit de la forge"
}

case_hotfix_sync_dev_locale_en_avance_refusee() {
  depot_de_test
  correctif_publie > /dev/null
  commit "un commit local jamais poussé" dev.txt > /dev/null
  lance sync
  assert_eq 1 "$rc" "une dev locale en avance est un refus (messages : $err)"
  assert_contains "porte des commits absents" "$err" "le message le dit"
  assert_contains "un commit local jamais poussé" "$(git -C "$depot" log -1 --format=%s dev)" "le commit local est intact"
  assert_eq "" "$(ls "$(etat_sync)" 2>/dev/null || true)" "aucun état n'est écrit"
}

prs_vers_dev() { # deux PR vers dev et une vers main, sur la page 1
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 "$(jq -nc '[
    {number: 21, head: {ref: "feat/9-1-quelque-chose", sha: "1111111111111111111111111111111111111111"}, base: {ref: "dev"}},
    {number: 22, head: {ref: "hotfix/autre", sha: "2222222222222222222222222222222222222222"}, base: {ref: "main"}},
    {number: 23, head: {ref: "fix/9-2-autre-chose", sha: "3333333333333333333333333333333333333333"}, base: {ref: "dev"}}]')"
}

case_hotfix_sync_push_nominal() {
  depot_de_test
  local correctif lease; correctif=$(correctif_publie)
  lease=$(forge_ref dev)
  api GET /user 200 '{"login":"compte-essai"}'
  prs_vers_dev
  lance sync --push
  assert_eq 0 "$rc" "la synchronisation est poussée (messages : $err)"
  assert_eq "$(git -C "$depot" rev-parse dev)" "$(forge_ref dev)" "la forge porte la dev rebasée"
  git --git-dir="$forge" merge-base --is-ancestor "$correctif" refs/heads/dev \
    || { echo "main n'est pas un ancêtre de dev sur la forge" >&2; exit 1; }
  assert_contains "push --force-with-lease=dev:$lease origin dev" "$(appels_git)" "le bail porte la valeur lue avant le rebase"
  assert_eq "" "$(ls "$(etat_sync)" 2>/dev/null || true)" "l'état est supprimé"
  assert_contains "PR n° 21" "$out" "la première PR vers dev est listée"
  assert_contains "PR n° 23" "$out" "la seconde aussi"
  assert_eq "" "$(grep -o 'PR n° 22' <<< "$out" || true)" "pas la PR vers main"
  assert_contains "git rebase --onto origin/dev $lease" "$out" "avec la commande de rebase"
  assert_contains "llm-review.sh 21" "$out" "et la revue à refaire"
  aucun_cherry_pick
  aucune_adresse
}

case_hotfix_sync_puis_push_en_deux_temps() {
  # L'audit d'abord, --push plus tard : le bail est celui de l'audit, relu dans l'état.
  depot_de_test
  local lease; correctif_publie > /dev/null
  lease=$(forge_ref dev)
  lance sync
  assert_eq 0 "$rc" "l'audit va au bout (messages : $err)"
  local rebasee; rebasee=$(git -C "$depot" rev-parse dev)
  api GET /user 200 '{"login":"compte-essai"}'
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 '[]'
  lance sync --push
  assert_eq 0 "$rc" "le push aboutit (messages : $err)"
  assert_eq "$rebasee" "$(forge_ref dev)" "la dev de l'audit est poussée, sans second rebase"
  assert_eq "1" "$(grep -cE '(^| )rebase --quiet' "$work/git-appels")" "un seul rebase pour les deux lancements"
  assert_contains "aucune PR ouverte" "$out" "aucune PR à reprendre"
}

case_hotfix_sync_push_bail_refuse() {
  # Un push concurrent arrive sur dev juste avant le nôtre : git le refuse par le bail, et rien n'est
  # écrasé. Avec un --force-with-lease nu, ce cas passerait si refs/remotes/origin/dev avait été relue.
  depot_de_test
  correctif_publie > /dev/null
  git -C "$depot" checkout -q -b concurrent dev
  local concurrent; concurrent=$(commit "feat(2.3): fusionné pendant ce temps (#8)" dev.txt)
  vers_forge refs/heads/concurrent:refs/heads/concurrent
  git -C "$depot" checkout -q dev
  printf '%s' "$concurrent" > "$work/concurrent"
  api GET /user 200 '{"login":"compte-essai"}'
  lance sync --push
  assert_eq 1 "$rc" "le bail refuse le push (messages : $err)"
  assert_eq "$concurrent" "$(forge_ref dev)" "le commit concurrent n'est pas écrasé"
  assert_contains "bail" "$err" "le message nomme le bail"
  assert_contains "<adresse>" "$err" "les messages de git sont affichés, adresse masquée"
  assert_eq "1" "$(grep -cE '(^| )push( |$)' "$work/git-appels")" "aucune reprise"
  aucune_adresse
}

case_hotfix_sync_push_branche_protegee() {
  depot_de_test
  correctif_publie > /dev/null
  local dev_forge; dev_forge=$(forge_ref dev)
  forge_refuse refs/heads/dev
  api GET /user 200 '{"login":"compte-essai"}'
  lance sync --push
  assert_eq 1 "$rc" "un push refusé par la forge est un refus (messages : $err)"
  assert_contains "refusé par la forge" "$err" "le message le dit"
  assert_eq "$dev_forge" "$(forge_ref dev)" "dev n'a pas bougé"
  assert_eq "1" "$(grep -cE '(^| )push( |$)' "$work/git-appels")" "aucune reprise"
  aucune_adresse
}

case_hotfix_sync_push_forge_a_bouge_depuis_l_audit() {
  depot_de_test
  correctif_publie > /dev/null
  lance sync
  assert_eq 0 "$rc" "l'audit va au bout (messages : $err)"
  git -C "$depot" checkout -q -b concurrent origin/dev
  commit "feat(2.3): fusionné entre l'audit et le push (#8)" dev.txt > /dev/null
  vers_forge refs/heads/concurrent:refs/heads/dev
  git -C "$depot" checkout -q dev
  api GET /user 200 '{"login":"compte-essai"}'
  lance sync --push
  assert_eq 1 "$rc" "une dev qui a bougé depuis l'audit est un refus (messages : $err)"
  assert_contains "a bougé sur la forge" "$err" "le message le dit"
  assert_contains "Pour recommencer" "$err" "et comment recommencer"
  aucun_push
}

case_hotfix_sync_push_main_a_bouge_depuis_l_audit() {
  depot_de_test
  correctif_publie > /dev/null
  lance sync
  assert_eq 0 "$rc" "l'audit va au bout (messages : $err)"
  git -C "$depot" checkout -q -b second "$(forge_ref main)"
  commit "fix: un second correctif" second.txt > /dev/null
  vers_forge refs/heads/second:refs/heads/main
  git -C "$depot" checkout -q dev
  api GET /user 200 '{"login":"compte-essai"}'
  lance sync --push
  assert_eq 1 "$rc" "une main qui a bougé depuis l'audit est un refus (messages : $err)"
  assert_contains "main a bougé sur la forge" "$err" "le message le dit"
  aucun_push
}

case_hotfix_sync_rebase_abandonne() {
  # Le rebase arrêté sur un conflit a été abandonné à la main : l'état reste, mais dev ne contient pas
  # main. sync le dit, et ne présente pas cette dev comme prête à pousser.
  conflit
  lance sync
  assert_eq 1 "$rc" "premier arrêt (messages : $err)"
  git -C "$depot" rebase --abort
  lance sync
  assert_eq 1 "$rc" "un rebase abandonné est un refus (messages : $err)"
  assert_contains "abandonné" "$err" "le message le dit"
  assert_contains "Pour recommencer" "$err" "et comment recommencer"
}

case_hotfix_sync_push_hors_de_dev() {
  depot_de_test
  correctif_publie > /dev/null
  lance sync
  assert_eq 0 "$rc" "l'audit va au bout (messages : $err)"
  git -C "$depot" checkout -q main
  api GET /user 200 '{"login":"compte-essai"}'
  lance sync --push
  assert_eq 1 "$rc" "une synchronisation entamée se pousse depuis dev (messages : $err)"
  assert_contains "git checkout dev" "$err" "le message dit quoi faire"
  aucun_push
}

case_hotfix_sync_push_dev_rebougee_apres_le_push() {
  # Quelqu'un pousse sur dev juste après nous : la relecture le voit, et l'état n'est pas effacé.
  # Le commit poussé ensuite est main elle-même : origin/main reste un ancêtre de origin/dev, si bien
  # que seule la comparaison de origin/dev à la dev poussée voit le changement.
  depot_de_test
  local correctif; correctif=$(correctif_publie)
  printf '%s' "$correctif" > "$work/apres-push"
  api GET /user 200 '{"login":"compte-essai"}'
  lance sync --push
  assert_eq 2 "$rc" "une dev qui a bougé après le push est une anomalie (messages : $err)"
  assert_contains "vérifier sur la forge" "$err" "le message le dit"
  [[ -f $(etat_sync) ]] || { echo "l'état a été effacé" >&2; exit 1; }
}

case_hotfix_sync_push_env_absent() {
  # Avec --push, .env se vérifie avant tout geste : ni rebase, ni état écrit.
  depot_de_test
  correctif_publie > /dev/null
  rm "$depot/.env"
  lance sync --push
  assert_eq 2 "$rc" ".env absent est une anomalie (messages : $err)"
  assert_eq "" "$(grep -E '(^| )rebase( |$)' "$work/git-appels" || true)" "aucun rebase n'est lancé"
  assert_eq "" "$(ls "$(etat_sync)" 2>/dev/null || true)" "aucun état n'est écrit"
  aucun_push
}

conflit() { # dev et le correctif changent la même ligne
  depot_de_test
  sed -i '2s/.*/ligne 2 selon dev/' "$depot/site.txt"
  git -C "$depot" commit -q -am "feat(2.2): dev change la ligne 2 (#4)"
  vers_forge refs/heads/dev:refs/heads/dev
  correctif_publie "ligne 2 selon le correctif" > /dev/null
}

case_hotfix_sync_conflit_laisse_le_rebase_en_cours() {
  conflit
  lance sync
  assert_eq 1 "$rc" "un conflit arrête la synchronisation (messages : $err)"
  [[ -d $depot/.git/rebase-merge ]] || { echo "le rebase n'est plus en cours" >&2; exit 1; }
  assert_contains "1. résoudre les conflits" "$err" "consigne 1"
  assert_contains "2. git add" "$err" "consigne 2"
  assert_contains "3. git rebase --continue" "$err" "consigne 3"
  assert_contains "4. relancer scripts/hotfix.sh sync" "$err" "consigne 4"
  assert_eq "" "$(grep -E 'rebase --abort' "$work/git-appels" || true)" "le rebase n'est pas abandonné"
  aucun_push
}

case_hotfix_sync_relance_sur_conflit_non_resolu() {
  conflit
  lance sync
  assert_eq 1 "$rc" "premier arrêt (messages : $err)"
  lance sync
  assert_eq 1 "$rc" "un conflit non résolu arrête encore (messages : $err)"
  assert_contains "3. git rebase --continue" "$err" "la consigne est redite"
  assert_eq "1" "$(grep -cE '(^| )rebase --quiet' "$work/git-appels")" "aucun second rebase n'est commencé"
  [[ -d $depot/.git/rebase-merge ]] || { echo "le rebase n'est plus en cours" >&2; exit 1; }
}

case_hotfix_sync_reprise_apres_git_add() {
  # Le conflit est résolu et ajouté, mais « git rebase --continue » n'est pas lancé : sync le reprend.
  conflit
  lance sync
  assert_eq 1 "$rc" "premier arrêt (messages : $err)"
  printf 'ligne 1\nligne 2 résolue\nligne 3\n' > "$depot/site.txt"
  git -C "$depot" add site.txt
  lance sync
  assert_eq 0 "$rc" "la reprise va au bout (messages : $err)"
  assert_contains "reprise du rebase" "$out" "le script dit qu'il reprend"
  assert_eq "" "$(ls -d "$depot/.git/rebase-merge" 2>/dev/null || true)" "le rebase est terminé"
  git -C "$depot" merge-base --is-ancestor "$(forge_ref main)" dev \
    || { echo "dev locale ne contient pas main" >&2; exit 1; }
  assert_eq "1" "$(grep -cE '(^| )rebase --quiet' "$work/git-appels")" "aucun second rebase n'est commencé"
  aucun_push
  aucun_cherry_pick
}

case_hotfix_sync_reprise_apres_rebase_continue() {
  # L'opérateur a lui-même terminé le rebase : sync reprend avec le bail de l'état, puis --push.
  conflit
  local lease; lease=$(forge_ref dev)
  lance sync
  assert_eq 1 "$rc" "premier arrêt (messages : $err)"
  printf 'ligne 1\nligne 2 résolue\nligne 3\n' > "$depot/site.txt"
  git -C "$depot" add site.txt
  GIT_EDITOR=true git -C "$depot" rebase --continue > /dev/null 2>&1
  api GET /user 200 '{"login":"compte-essai"}'
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 '[]'
  lance sync --push
  assert_eq 0 "$rc" "la reprise est poussée (messages : $err)"
  assert_contains "push --force-with-lease=dev:$lease origin dev" "$(appels_git)" "avec le bail de l'état"
  assert_eq "$(git -C "$depot" rev-parse dev)" "$(forge_ref dev)" "la forge porte la dev résolue"
}

case_hotfix_sync_rebase_etranger_refuse() {
  # Un rebase d'une autre branche est en cours : sync n'y touche pas.
  depot_de_test
  git -C "$depot" checkout -q -b autre main
  sed -i '2s/.*/ligne 2 selon autre/' "$depot/site.txt"
  git -C "$depot" commit -q -am "autre"
  git -C "$depot" checkout -q -b base-autre main
  sed -i '2s/.*/ligne 2 selon base/' "$depot/site.txt"
  git -C "$depot" commit -q -am "base"
  git -C "$depot" checkout -q autre
  git -C "$depot" rebase base-autre > /dev/null 2>&1 || true
  lance sync
  assert_eq 1 "$rc" "un rebase étranger est un refus (messages : $err)"
  assert_contains "un autre rebase est en cours" "$err" "le message le dit"
  aucun_push
}

case_hotfix_sync_rebase_de_dev_non_commence_par_sync() {
  conflit
  git -C "$depot" rebase "$(forge_ref main)" > /dev/null 2>&1 || true
  lance sync
  assert_eq 1 "$rc" "un rebase de dev commencé à la main est un refus (messages : $err)"
  assert_contains "n'a pas été commencé par" "$err" "le message le dit"
}

# --- jamais de cherry-pick, dans aucun chemin ----------------------------------------------------------

case_hotfix_aucun_cherry_pick_dans_le_code() {
  # Le contrôle dynamique (aucun_cherry_pick) ne voit que les chemins que les cas parcourent : celui-ci
  # lit le script et sa bibliothèque, où « cherry-pick » ne doit apparaître que dans les commentaires
  # et les messages, jamais comme une sous-commande de git.
  local fichier lignes
  for fichier in scripts/hotfix.sh scripts/lib/hotfix.sh scripts/lib/release.sh; do
    shell_grep_into lignes -nE '^[^#]*\bgit\b[^#]*cherry-pick' "$root/$fichier"
    assert_eq "" "$lignes" "$fichier lance cherry-pick"
  done
}

run_case "$@"
