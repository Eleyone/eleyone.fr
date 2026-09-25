#!/usr/bin/env bash
# Mise en ligne de dev sur main (story 11.7, AD-14, AD-22, AD-24) : ce que le skill refuse, ce qu'il
# envoie à la forge, et surtout **sur quel commit il accepte de poser le tag**.
#
# **Aucun cas n'appelle le réseau.** Un faux curl répond à la place de la forge depuis $work/api, et
# un faux git n'intercepte que les deux sous-commandes qui sortent de la machine — « fetch » et
# « push » — en déléguant tout le reste au vrai git : ce que ce script vérifie, ce sont des codes de
# sortie de git (merge-base --is-ancestor, diff --quiet) et des SHA réels, qu'un faux ne prouverait
# pas. Le dépôt du projet n'est jamais touché : chaque cas construit le sien dans $work, et aucun tag
# n'est poussé nulle part.
#
# **L'état de la forge est simulé à part** : $work/forge-main et $work/forge-dev portent ce que la
# forge sait, refs/remotes/origin/* ce que le dépôt local en sait. Seul « git fetch » recopie l'un
# dans l'autre, et le faux curl déplace forge-main quand la fusion réussit. C'est ce décalage qui
# rend visible la faute que cette story doit empêcher : un tag posé sur l'ancien main.
#
# **Point 19 d'AGENTS.md — l'aîné et ses gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-release-job.sh (dépôt git réel et jetable, faux git qui ne dévie que pour une
# sous-commande, environnement réduit par « env -i », affirmation du code de sortie avant de compter
# quoi que ce soit, vérification qu'aucun effet n'a eu lieu après un refus) et comme
# test-merge-gates.sh (réponses de la forge en fichiers). Le tableau complet est dans le fichier de
# story.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

script=$root/scripts/release.sh
depot=$work/depot
readonly repo=Eleyone/eleyone.fr

# --- les faux binaires --------------------------------------------------------------------------

# Le faux git ne dévie que pour « fetch » et « push » ; tout le reste va au vrai git, sur un vrai
# dépôt. « fetch » recopie l'état de la forge dans refs/remotes/origin/*, sauf si $work/fetch-inerte
# existe : c'est la mutation qui met à nu le danger du tag.
faux_git() {
  local vrai
  vrai=$(command -v git) || { echo "git introuvable" >&2; exit 2; }
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    printf 'vrai=%q\n' "$vrai"
    cat <<'FAUX'
premier=""
for a in "$@"; do case "$a" in -*) continue ;; *) premier=$a; break ;; esac; done
case "$premier" in
  fetch)
    printf '%s\n' "$*" >> "$w/git-fetch"
    if [ ! -f "$w/fetch-inerte" ]; then
      for b in main dev; do
        if [ -f "$w/forge-$b" ]; then
          "$vrai" update-ref "refs/remotes/origin/$b" "$(cat "$w/forge-$b")" || exit 1
        fi
      done
    fi
    exit 0
    ;;
  push)
    printf '%s\n' "$*" >> "$w/git-push"
    if [ -f "$w/code-push" ]; then exit "$(cat "$w/code-push")"; fi
    exit 0
    ;;
esac
exec "$vrai" "$@"
FAUX
  } > "$work/bin/git"
  chmod +x "$work/bin/git"
}

# Le faux curl répond à la place de la forge. Il consomme l'entrée standard — le jeton y passe par
# « -K - » — sans jamais l'écrire nulle part. Chaque appel est noté (méthode et chemin seulement,
# jamais l'adresse), et le corps envoyé est conservé pour être relu par les cas.
faux_curl() {
  mkdir -p "$work/bin" "$work/api"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
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
# Après une fusion réussie, une lecture de la PR sert la variante « .apres » si elle existe : la
# séquence des appels peut changer (reprises), pas l'état de la PR.
if [ -f "$w/fusionnee" ] && [ -f "$w/api/$cle.apres" ]; then rep="$w/api/$cle.apres"; fi
if [ -f "$rep" ]; then cat "$rep" > "$out"; else printf '{}' > "$out"; fi
code="$w/api/$cle.$n.code"
[ -f "$code" ] || code="$w/api/$cle.code"
valeur=200
[ -f "$code" ] && valeur=$(cat "$code")
# La forge déplace main sur la tête de dev quand un fast-forward aboutit : le dépôt local, lui, ne
# le sait pas encore.
case "$chemin" in
  */merge)
    if [ "$methode" = POST ] && [ "$valeur" = 200 ]; then
      : > "$w/fusionnee"
      [ -f "$w/forge-dev" ] && cp "$w/forge-dev" "$w/forge-main"
    fi
    ;;
esac
printf '%s' "$valeur"
exit 0
FAUX
  } > "$work/bin/curl"
  chmod +x "$work/bin/curl"
}

# Le faux sleep n'attend pas : il note seulement qu'on lui a demandé d'attendre.
faux_sleep() {
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$*" >> %q\n' "$work/sleeps"
    printf 'exit 0\n'
  } > "$work/bin/sleep"
  chmod +x "$work/bin/sleep"
}

# --- les réponses de la forge -------------------------------------------------------------------

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
aucun_appel_api() {
  [[ ! -f $work/api-appels ]] \
    || { printf 'la forge a été appelée malgré le refus :\n%s\n' "$(appels_api)" >&2; exit 1; }
}
aucun_tag() { # aucun tag posé dans le dépôt de test, et rien de poussé
  local tags; tags=$(git -C "$depot" tag --list 'v*' | grep -v -- '-rc\.' || true)
  [[ -z $tags ]] || { printf 'un tag de production a été posé : %s\n' "$tags" >&2; exit 1; }
  [[ ! -f $work/git-push ]] \
    || { printf 'un push a eu lieu :\n%s\n' "$(cat "$work/git-push")" >&2; exit 1; }
}

pr_ouverte() { # $1 = SHA de tête ; la réponse d'une PR dev → main fusionnable
  jq -nc --arg s "$1" '{number: 42, state: "open", draft: false, mergeable: true, merged: false,
    title: "Mise en ligne", base: {ref: "main"}, head: {ref: "dev", sha: $s}}'
}

# --- le dépôt de test ------------------------------------------------------------------------------

# Un script témoin à la place d'un contrôle : il note son nom et ses arguments, puis rend le code
# écrit dans $work/code-<nom> (0 par défaut).
temoin() { # $1 = nom
  mkdir -p "$depot/scripts"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s %%s\\n" "%s" "$*" >> %q\n' "$1" "$work/controles"
    printf 'if [ -f %q/code-%s ]; then printf "refus de %s\\n" >&2; exit "$(cat %q/code-%s)"; fi\n' \
      "$work" "$1" "$1" "$work" "$1"
    printf 'exit 0\n'
  } > "$depot/scripts/$1.sh"
  chmod +x "$depot/scripts/$1.sh"
}

controles_lances() { [[ -f $work/controles ]] && cat "$work/controles"; return 0; }

commit() { # $1 = message, $2 = fichier modifié (défaut : site.txt)
  printf '%s\n' "$1" >> "$depot/${2:-site.txt}"
  git -C "$depot" add -A
  git -C "$depot" commit -q -m "$1"
  git -C "$depot" rev-parse HEAD
}

# Le dépôt de test : main, puis des commits de dev qui sont tous des squashs de PR. Les deux SHA sont
# affichés, « main dev », et l'état de la forge est posé sur les mêmes.
# $1 = contenu de ci/release-pages.txt (défaut : le socle complet)
depot_de_test() {
  local pages=${1:-"home
about
contact
legal-notice
privacy
case-01
group-chiliz
case-02
case-05"}
  new_repo
  mkdir -p "$depot/ci" "$depot/scripts"
  temoin check-private
  temoin sprint-consistency
  printf '.env\n' > "$depot/.gitignore"
  cp "$root/ci/bootstrap-commits.txt" "$depot/ci/bootstrap-commits.txt"
  cp "$root/ci/base-pages.txt" "$depot/ci/base-pages.txt"
  printf '%s\n' "$pages" > "$depot/ci/release-pages.txt"
  local main_sha dev_sha
  main_sha=$(commit "socle (#1)")
  commit "feat(1.1): quelque chose (#15)" > /dev/null
  dev_sha=$(commit "feat(1.2): autre chose (#16)")
  git -C "$depot" update-ref refs/remotes/origin/main "$main_sha"
  git -C "$depot" update-ref refs/remotes/origin/dev "$dev_sha"
  git -C "$depot" remote add origin "ssh://git@forge.invalide/$repo.git"
  printf 'GITEA_URL=https://forge.invalide\nGITEA_USER=compte-essai\nGITEA_TOKEN=jeton-essai\n' > "$depot/.env"
  printf 'MOTIFFACTICE\n' > "$work/motifs.txt"
  printf '%s' "$main_sha" > "$work/forge-main"
  printf '%s' "$dev_sha" > "$work/forge-dev"
  faux_git; faux_curl; faux_sleep
  printf '%s %s\n' "$main_sha" "$dev_sha"
}

# Les réponses nominales de la forge : jeton reconnu, aucune PR ouverte, création acceptée, CI verte.
forge_prete() { # $1 = SHA de tête de dev
  api GET /user 200 '{"login":"compte-essai"}'
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 '[]'
  api POST "/repos/$repo/pulls" 201 '{"number": 42}'
  api GET "/repos/$repo/pulls/42" 200 "$(pr_ouverte "$1")"
  api GET "/repos/$repo/commits/$1/status" 200 '{"statuses": [{"context": "checks / checks (pull_request)", "status": "success"}]}'
  api POST "/repos/$repo/pulls/42/merge" 200 '{}'
  api_apres GET "/repos/$repo/pulls/42" "$(jq -nc --arg s "$1" '{number: 42, state: "open", draft: false,
    mergeable: true, merged: true, title: "Mise en ligne", base: {ref: "main"}, head: {ref: "dev", sha: $s}}')"
}

# Un tag de répétition sur la tête de dev : sans lui, la mise en ligne n'est qu'avertie (AD-22, D-6).
repetition() { # $1 = tag de production, $2 = commit
  git -C "$depot" tag "$1-rc.1" "$2"
}

lance() { # arguments de release.sh
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work" LC_ALL=C \
    PRIVATE_PATTERNS_FILE="$work/motifs.txt" \
    bash -c 'cd "$1" && shift && exec bash "$@"' _ "$depot" "$script" "$@"
}

# --- usage -------------------------------------------------------------------------------------------

case_release_usage_sans_tag() {
  depot_de_test > /dev/null
  lance
  assert_eq 2 "$rc" "sans tag, c'est une anomalie d'usage (messages : $err)"
  assert_contains "usage" "$err" "le message donne l'usage"
  aucun_appel_api
}

case_release_usage_tag_mal_forme() {
  depot_de_test > /dev/null
  lance 1.2.3
  assert_eq 2 "$rc" "un tag sans « v » est refusé (messages : $err)"
  assert_contains "vX.Y.Z" "$err" "le message dit la forme attendue"
  aucun_appel_api
}

case_release_usage_tag_de_repetition() {
  # Un « -rc.N » se pose sur dev par rehearse-release : release ne le prend pas pour un tag
  # de production, et ne le refuse pas non plus en disant « mal formé ».
  depot_de_test > /dev/null
  lance v1.2.3-rc.1
  assert_eq 2 "$rc" "un tag de répétition n'entre pas ici (messages : $err)"
  assert_contains "rehearse-release" "$err" "le message renvoie au bon skill"
  aucun_appel_api
}

case_release_usage_option_inconnue() {
  # Il n'existe aucune option --force : elle ne doit pas être avalée comme un tag.
  depot_de_test > /dev/null
  lance v1.2.3 --force
  assert_eq 2 "$rc" "une option inconnue est une anomalie d'usage (messages : $err)"
  assert_contains "option inconnue" "$err" "le message la nomme"
  aucun_appel_api
}

case_release_arbre_sale() {
  local sha; sha=$(depot_de_test); sha=${sha##* }
  printf 'travail en cours\n' >> "$depot/site.txt"
  forge_prete "$sha"
  lance v1.2.3
  assert_eq 2 "$rc" "un arbre modifié arrête la publication (messages : $err)"
  assert_contains "non commitées" "$err" "le message dit pourquoi"
  aucun_appel_api
}

# --- l'invariant d'AD-24 -------------------------------------------------------------------------------

case_release_main_pas_ancetre() {
  # L'état que laisse un hotfix : main porte un commit que dev n'a pas.
  local shas main_sha dev_sha
  shas=$(depot_de_test); main_sha=${shas%% *}; dev_sha=${shas##* }
  git -C "$depot" checkout -q -b correctif "$main_sha"
  local hotfix; hotfix=$(commit "hotfix: urgence (#99)")
  git -C "$depot" update-ref refs/remotes/origin/main "$hotfix"
  printf '%s' "$hotfix" > "$work/forge-main"
  git -C "$depot" checkout -q "$dev_sha"
  git -C "$depot" reset -q --hard "$dev_sha"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 1 "$rc" "main hors de dev est un refus, pas une anomalie (messages : $err)"
  assert_contains "hotfix" "$err" "le message renvoie au skill hotfix"
  aucun_appel_api
  aucun_tag
}

case_release_rien_a_publier() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  git -C "$depot" update-ref refs/remotes/origin/main "$dev_sha"
  printf '%s' "$dev_sha" > "$work/forge-main"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 1 "$rc" "main et dev au même commit : rien à publier (messages : $err)"
  assert_contains "rien à publier" "$err" "le message le dit"
  aucun_appel_api
}

case_release_tag_deja_existant() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  git -C "$depot" tag v1.2.3 "$dev_sha"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 1 "$rc" "un tag déjà posé arrête tout (messages : $err)"
  assert_contains "existe déjà" "$err" "le message le dit"
  aucun_appel_api
}

# --- la répétition générale (AD-22, D-6) ----------------------------------------------------------------

case_release_v1_sans_repetition() {
  # v1.0.0 **seulement** : sans répétition de même arbre, c'est un refus.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  lance v1.0.0
  assert_eq 1 "$rc" "la première mise en ligne se répète avant de se faire (messages : $err)"
  assert_contains "v1.0.0-rc.N" "$err" "le message nomme ce qui manque"
  aucun_appel_api
}

case_release_v1_repetition_d_un_autre_arbre() {
  # Un tag -rc existe, mais il pointe sur un arbre différent : il ne vaut pas répétition.
  local shas main_sha dev_sha
  shas=$(depot_de_test); main_sha=${shas%% *}; dev_sha=${shas##* }
  repetition v1.0.0 "$main_sha"
  forge_prete "$dev_sha"
  lance v1.0.0
  assert_eq 1 "$rc" "un -rc d'un autre arbre ne vaut pas répétition (messages : $err)"
  assert_contains "arbre identique" "$err" "le message dit que c'est l'arbre qui compte"
}

case_release_tag_suivant_sans_repetition() {
  # Pour un tag de production autre que v1.0.0, l'absence de -rc n'est qu'un avertissement.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 0 "$rc" "l'audit va au bout (messages : $err)"
  assert_contains "avertissement" "$out" "l'absence de répétition est dite"
  assert_contains "tous les verrous passent" "$out" "et n'empêche rien"
}

# --- la complétude du socle (FR-32, D-5) ------------------------------------------------------------------

case_release_v1_socle_incomplet() {
  local dev_sha; dev_sha=$(depot_de_test "home
about"); dev_sha=${dev_sha##* }
  repetition v1.0.0 "$dev_sha"
  forge_prete "$dev_sha"
  lance v1.0.0
  assert_eq 1 "$rc" "v1.0.0 ne part pas sans le socle (messages : $err)"
  assert_contains "case-05" "$err" "chaque clé manquante est nommée"
  assert_contains "group-chiliz" "$err" "y compris la page de groupe"
  aucun_appel_api
}

case_release_v1_socle_complet() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  repetition v1.0.0 "$dev_sha"
  forge_prete "$dev_sha"
  lance v1.0.0
  assert_eq 0 "$rc" "socle complet et répétition trouvée (messages : $err)"
  assert_contains "socle complet" "$out" "le contrôle est affiché"
  assert_contains "v1.0.0-rc.1" "$out" "la répétition trouvée est nommée"
}

case_release_socle_hors_v1_non_verifie() {
  # La complétude ne se vérifie qu'une fois, pour v1.0.0 : un tag suivant ne la rejoue pas.
  local dev_sha; dev_sha=$(depot_de_test "home"); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 0 "$rc" "un tag suivant ne vérifie pas le socle (messages : $err)"
  assert_eq "" "$(grep -o 'socle complet' <<< "$out" || true)" "et n'affiche pas le contrôle"
}

case_release_socle_liste_de_reference_vide() {
  # Une liste de référence sans clé ferait passer le contrôle sans rien vérifier : c'est une anomalie,
  # comme un fichier de motifs sans motif.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  printf '# rien que des commentaires\n' > "$depot/ci/base-pages.txt"
  dev_sha=$(commit "chore: liste vide (#17)")
  git -C "$depot" update-ref refs/remotes/origin/dev "$dev_sha"
  printf '%s' "$dev_sha" > "$work/forge-dev"
  repetition v1.0.0 "$dev_sha"
  forge_prete "$dev_sha"
  lance v1.0.0
  assert_eq 2 "$rc" "une liste de référence vide est une anomalie (messages : $err)"
  aucun_appel_api
}

# --- la PR de publication ---------------------------------------------------------------------------------

case_release_audit_ouvre_la_pr() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  assert_contains "POST /repos/$repo/pulls" "$(appels_api)" "la PR est ouverte"
  assert_contains '"base": "main"' "$(cat "$work/api-corps")" "vers main"
  assert_contains '"head": "dev"' "$(cat "$work/api-corps")" "depuis dev"
  # sans --merge, rien d'autre : ni fusion, ni tag
  assert_eq "" "$(grep -o '/merge' "$work/api-appels" || true)" "aucune fusion demandée"
  assert_contains "Publication possible avec --merge" "$out" "le script dit où il s'arrête"
  aucun_tag
}

case_release_audit_pr_deja_ouverte() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api GET "/repos/$repo/pulls?state=open&limit=50&page=1" 200 \
    "[$(jq -nc --arg s "$dev_sha" '{number: 42, head: {ref: "dev"}, base: {ref: "main"}}')]"
  lance v1.2.3
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  assert_eq "" "$(grep -x "POST /repos/$repo/pulls" "$work/api-appels" || true)" "aucune seconde PR n'est ouverte"
  assert_contains "déjà ouverte" "$out" "le script le dit"
}

case_release_motif_prive_dans_le_titre() {
  # Le titre et le corps partent sur la forge : ils passent la liste des motifs avant l'envoi.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  printf 'Mise en ligne\n' > "$work/motifs.txt"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 1 "$rc" "un motif dans le titre arrête la publication (messages : $err)"
  assert_contains "motif privé" "$err" "le message le dit sans recopier le motif"
  assert_eq "" "$(grep -x "POST /repos/$repo/pulls" "$work/api-appels" || true)" "aucune PR n'est ouverte"
}

case_release_pr_en_brouillon() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api GET "/repos/$repo/pulls/42" 200 "$(jq -nc --arg s "$dev_sha" '{number: 42, state: "open", draft: true,
    mergeable: true, merged: false, title: "x", base: {ref: "main"}, head: {ref: "dev", sha: $s}}')"
  lance v1.2.3
  assert_eq 1 "$rc" "une PR en brouillon bloque (messages : $err)"
  assert_contains "brouillon" "$out" "le verrou le dit"
}

case_release_tete_de_pr_decalee() {
  # La PR ne porte pas la tête de origin/dev : publier reviendrait à publier autre chose.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api GET "/repos/$repo/pulls/42" 200 "$(pr_ouverte 0000000000000000000000000000000000000000)"
  lance v1.2.3
  assert_eq 1 "$rc" "une tête décalée bloque (messages : $err)"
  assert_contains "PR publiable" "$out" "le verrou est nommé"
}

case_release_mergeable_nul_puis_vrai() {
  # Juste après la création, la forge répond « mergeable: null » le temps de calculer : attendre est
  # la seule réponse juste — bloquer serait un faux refus, passer serait lire un état inconnu.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api_rang GET "/repos/$repo/pulls/42" 1 200 "$(jq -nc --arg s "$dev_sha" '{number: 42, state: "open",
    draft: false, mergeable: null, merged: false, title: "x", base: {ref: "main"}, head: {ref: "dev", sha: $s}}')"
  lance v1.2.3
  assert_eq 0 "$rc" "la seconde lecture tranche (messages : $err)"
  assert_contains "fusionnable" "$out" "le verrou passe"
  assert_contains "3" "$(cat "$work/sleeps")" "le script a attendu entre les deux lectures"
}

# --- verrou de revue : la provenance des commits (D-13) ---------------------------------------------------

case_release_revue_tous_squashs() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 0 "$rc" "tous les commits portent un numéro de PR (messages : $err)"
  assert_contains "squashs de PR" "$out" "le verrou le dit"
}

case_release_revue_commit_sans_numero() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  dev_sha=$(commit "un commit poussé à la main")
  git -C "$depot" update-ref refs/remotes/origin/dev "$dev_sha"
  printf '%s' "$dev_sha" > "$work/forge-dev"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 1 "$rc" "un commit sans numéro de PR bloque (messages : $err)"
  assert_contains "aucun numéro de PR" "$out" "le verrou nomme la raison"
  assert_contains "${dev_sha:0:7}" "$out" "et le commit fautif"
}

case_release_revue_commit_de_fusion() {
  # Gitea compose « Merge pull request … (#N) » : le marqueur ne suffit donc pas, et le flux linéaire
  # d'AD-24 interdit un commit de fusion dans main..dev.
  local shas main_sha dev_sha
  shas=$(depot_de_test); main_sha=${shas%% *}; dev_sha=${shas##* }
  git -C "$depot" checkout -q -b cote "$main_sha"
  commit "feat: de côté (#50)" "de-cote.txt" > /dev/null
  git -C "$depot" checkout -q "$dev_sha"
  git -C "$depot" reset -q --hard "$dev_sha"
  git -C "$depot" merge -q --no-ff -m "Merge pull request 'cote' (#51) from cote into dev" cote
  dev_sha=$(git -C "$depot" rev-parse HEAD)
  git -C "$depot" update-ref refs/remotes/origin/dev "$dev_sha"
  printf '%s' "$dev_sha" > "$work/forge-dev"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 1 "$rc" "un commit de fusion bloque malgré son « (#N) » (messages : $err)"
  assert_contains "commit de fusion" "$out" "le verrou nomme la raison"
}

case_release_revue_amorcage_liste() {
  # Un commit nommé dans ci/bootstrap-commits.txt échappe au verrou : c'est l'exemption d'Arnaud du
  # 25/09/2026, et rien d'autre ne l'accorde.
  local exempte dev_sha
  depot_de_test > /dev/null
  # le commit fautif d'abord, puis un second commit — régulier, lui — qui l'inscrit dans la liste :
  # un commit ne peut pas porter son propre SHA.
  exempte=$(commit "un squash fusionné à la main")
  printf '%s exemption d'"'"'essai\n' "$exempte" >> "$depot/ci/bootstrap-commits.txt"
  git -C "$depot" add -A
  git -C "$depot" commit -q -m "chore: exemption (#18)"
  dev_sha=$(git -C "$depot" rev-parse HEAD)
  git -C "$depot" update-ref refs/remotes/origin/dev "$dev_sha"
  printf '%s' "$dev_sha" > "$work/forge-dev"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 0 "$rc" "le commit listé ne bloque plus (messages : $err)"
  assert_contains "hors amorçage listé" "$out" "le verrou dit d'où vient l'exemption"
}

case_release_revue_sha_mal_forme() {
  # Un SHA tronqué silencieusement ignoré transformerait une faute de frappe en exemption perdue.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  printf 'c2c789e trop court\n' >> "$depot/ci/bootstrap-commits.txt"
  git -C "$depot" add -A
  git -C "$depot" commit -q -m "chore: liste abîmée (#19)"
  dev_sha=$(git -C "$depot" rev-parse HEAD)
  git -C "$depot" update-ref refs/remotes/origin/dev "$dev_sha"
  printf '%s' "$dev_sha" > "$work/forge-dev"
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 2 "$rc" "un SHA mal formé est une anomalie (messages : $err)"
  assert_contains "bootstrap-commits.txt" "$err" "le message nomme le fichier"
}

# --- verrou garde-fou, CI, suivi de sprint -------------------------------------------------------------------

case_release_garde_fou_refuse() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  printf '1' > "$work/code-check-private"
  lance v1.2.3
  assert_eq 1 "$rc" "le garde-fou bloque la publication (messages : $err)"
  assert_contains "check-private.sh refuse" "$out" "le verrou le dit"
  assert_contains "history" "$(controles_lances)" "il a été lancé sur la plage"
}

case_release_ci_verte() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 0 "$rc" "la CI verte passe (messages : $err)"
  assert_contains "verte sur la tête" "$out" "le verrou le dit"
}

case_release_ci_en_echec() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api GET "/repos/$repo/commits/$dev_sha/status" 200 \
    '{"statuses": [{"context": "checks / checks (pull_request)", "status": "failure"}]}'
  lance v1.2.3
  assert_eq 1 "$rc" "une CI rouge bloque (messages : $err)"
  assert_contains "failure" "$out" "l'état fautif est nommé"
}

case_release_ci_absente_refuse_l_amorcage() {
  # **Le cœur de la story.** La base d'une publication est main, où .gitea/workflows/checks.yaml
  # n'existe pas encore : le régime d'amorçage de verify-and-merge-pr se réveillerait exactement à la
  # première mise en ligne et remplacerait la CI de la forge par un scripts/check.sh local. release
  # le refuse : la tête est un commit de dev, elle porte les statuts, et un « absent » est un refus.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api GET "/repos/$repo/commits/$dev_sha/status" 200 '{"statuses": []}'
  lance v1.2.3
  assert_eq 1 "$rc" "une CI sans statut bloque la publication (messages : $err)"
  assert_contains "bloque  CI" "$out" "le verrou CI bloque, il n'est pas affiché « absent »"
  assert_contains "substitut d'amorçage" "$out" "le verrou dit que le régime est refusé"
  assert_eq "" "$(grep -o 'check.sh' <<< "$(controles_lances)" || true)" "aucun substitut local n'est lancé"
  aucun_tag
}

case_release_suivi_de_sprint_global() {
  # La branche entrante est dev, qui ne porte aucun numéro de story : le contrôle est global.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  lance v1.2.3
  assert_eq 0 "$rc" "le suivi est cohérent (messages : $err)"
  assert_contains "sprint-consistency --rev $dev_sha" "$(controles_lances)" "appelé en mode global"
  assert_eq "" "$(grep -o -- '--merge' <<< "$(controles_lances)" || true)" "jamais avec --merge <n.m>"
}

case_release_suivi_de_sprint_incoherent() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  printf '1' > "$work/code-sprint-consistency"
  lance v1.2.3
  assert_eq 1 "$rc" "un suivi incohérent bloque la publication (messages : $err)"
  assert_contains "suivi de sprint" "$out" "le verrou est nommé"
}

# --- la fusion et le tag ---------------------------------------------------------------------------------

case_release_merge_nominal() {
  local shas main_sha dev_sha
  shas=$(depot_de_test); main_sha=${shas%% *}; dev_sha=${shas##* }
  forge_prete "$dev_sha"
  lance v1.2.3 --merge
  assert_eq 0 "$rc" "la publication aboutit (messages : $err)"
  local corps; corps=$(cat "$work/api-corps")
  assert_contains '"Do": "fast-forward-only"' "$corps" "le style de fusion est imposé (AD-24)"
  assert_contains "\"head_commit_id\": \"$dev_sha\"" "$corps" "sur le SHA relu, pas sur « la tête »"
  assert_eq "" "$(grep -o 'force_merge\|merge_when_checks_succeed\|delete_branch_after_merge' <<< "$corps" || true)" \
    "ni force, ni suppression de branche : dev survit à sa publication"
  assert_eq "$dev_sha" "$(git -C "$depot" rev-parse 'v1.2.3^{commit}')" "le tag porte le commit publié"
  assert_contains "refs/tags/v1.2.3" "$(cat "$work/git-push")" "et il est poussé"
  assert_contains "Actions" "$out" "le suivi du run est indiqué"
  assert_contains "deploy-site status" "$out" "ainsi que la commande d'état"
  assert_eq "" "$(grep -oi 'forge.invalide\|jeton-essai' <<< "$out$err" || true)" "aucune adresse ni jeton affiché"
}

case_release_merge_refuse_si_verrou_bloque() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  printf '1' > "$work/code-check-private"
  lance v1.2.3 --merge
  assert_eq 1 "$rc" "un verrou bloquant arrête --merge (messages : $err)"
  assert_contains "aucun tag n'est posé" "$out" "le script le dit"
  assert_eq "" "$(grep -o '/merge' "$work/api-appels" || true)" "aucune fusion demandée"
  aucun_tag
}

case_release_merge_405_transitoire() {
  # Juste après le déplacement de la base, la forge peut répondre 405 « Please try again later » :
  # ce n'est pas un refus (AD-24).
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api_rang POST "/repos/$repo/pulls/42/merge" 1 405 '{"message": "Please try again later"}'
  lance v1.2.3 --merge
  assert_eq 0 "$rc" "la reprise aboutit (messages : $err)"
  assert_contains "405 transitoire" "$out" "la reprise est dite"
  assert_contains "3" "$(cat "$work/sleeps")" "le script a attendu avant de reprendre"
  assert_eq "$dev_sha" "$(git -C "$depot" rev-parse 'v1.2.3^{commit}')" "et le tag est posé"
}

case_release_merge_405_persistant() {
  # Un 405 qui dit autre chose est un refus de style, et il le reste : les deux se distinguent par le
  # message de la forge, jamais par le code.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api POST "/repos/$repo/pulls/42/merge" 405 '{"message": "Merge style is not allowed"}'
  lance v1.2.3 --merge
  assert_eq 1 "$rc" "un 405 de style est un refus (messages : $err)"
  assert_contains "style de fusion" "$err" "le message le dit"
  assert_eq "" "$(cat "$work/sleeps" 2>/dev/null || true)" "aucune reprise pour un refus"
  aucun_tag
}

case_release_merge_500_divergence() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api POST "/repos/$repo/pulls/42/merge" 500 '{"message": "DivergingFastForwardOnly"}'
  lance v1.2.3 --merge
  assert_eq 1 "$rc" "une divergence est un refus (messages : $err)"
  assert_contains "divergé" "$err" "le message la nomme"
  aucun_tag
}

case_release_fusion_non_confirmee() {
  # « fusion annoncée mais la PR n'apparaît pas fusionnée » est une anomalie, pas un succès.
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  api_apres GET "/repos/$repo/pulls/42" "$(pr_ouverte "$dev_sha")"
  lance v1.2.3 --merge
  assert_eq 2 "$rc" "une fusion non confirmée est une anomalie (messages : $err)"
  assert_contains "n'apparaît pas fusionnée" "$err" "le message le dit"
  aucun_tag
}

case_release_tag_refuse_si_la_relecture_ne_ramene_rien() {
  # **Le cas le plus important de la story.** La fusion passe par l'API et ne met pas à jour le dépôt
  # local : sans le « git fetch » d'après-fusion, refs/remotes/origin/main porte encore l'ancien
  # commit, et « git tag » livrerait en production un arbre qui n'est pas celui qu'on publie. Le faux
  # git rend ici « fetch » inerte — le script doit **refuser de taguer**, jamais taguer le mauvais
  # commit. Retirer la vérification de release.sh fait tomber ce cas en posant le tag sur main.
  local shas main_sha dev_sha
  shas=$(depot_de_test); main_sha=${shas%% *}; dev_sha=${shas##* }
  forge_prete "$dev_sha"
  : > "$work/fetch-inerte"
  lance v1.2.3 --merge
  assert_eq 2 "$rc" "un état incohérent après la fusion est une anomalie (messages : $err)"
  assert_contains "aucun tag n'est posé" "$err" "le message le dit"
  assert_contains "${main_sha:0:7}" "$err" "et nomme le commit trouvé sur main"
  aucun_tag
}

case_release_push_du_tag_en_echec() {
  local dev_sha; dev_sha=$(depot_de_test); dev_sha=${dev_sha##* }
  forge_prete "$dev_sha"
  printf '1' > "$work/code-push"
  lance v1.2.3 --merge
  assert_eq 2 "$rc" "un push refusé est une anomalie (messages : $err)"
  assert_eq "" "$(git -C "$depot" tag --list v1.2.3)" "le tag local est retiré, pour qu'une reprise le repose"
  assert_contains "relancer" "$err" "le message dit quoi faire"
}

# --- les deux canaux, une seule écriture (point 19 d'AGENTS.md) -----------------------------------------------

case_release_expressions_des_canaux_identiques() {
  # deploy/remote/deploy-site.sh est recopié seul sur le serveur de production : il ne peut rien
  # partager avec le dépôt. scripts/release/ship.sh garde sa copie pour la même raison historique.
  # Ce cas tient les trois égales, comme test-ship.sh le fait pour le nom du dépôt d'images.
  local ici la_bas motif
  for motif in production repetition; do
    local nom_lib=$motif
    [[ $motif != repetition ]] || nom_lib=rehearsal
    shell_grep_into ici -oE "^readonly release_tag_$nom_lib='.+'\$" "$root/scripts/lib/release.sh"
    [[ -n $ici ]] || { echo "release_tag_$nom_lib introuvable dans la bibliothèque" >&2; exit 1; }
    ici=${ici#*=}
    local fichier
    for fichier in scripts/release/ship.sh deploy/remote/deploy-site.sh; do
      # Les deux fichiers ne nomment pas la variable pareil — « motif_ » ici, « tag_ » là-bas —, ce
      # qui est précisément la raison pour laquelle un cas doit comparer leur contenu.
      shell_grep_into la_bas -oE "^(motif|tag)_$motif='.+'\$" "$root/$fichier"
      [[ -n $la_bas ]] || { echo "l'expression $motif est introuvable dans $fichier" >&2; exit 1; }
      assert_eq "$ici" "${la_bas#*=}" "l'expression $motif diffère entre la bibliothèque et $fichier"
    done
  done
}

run_case "$@"
