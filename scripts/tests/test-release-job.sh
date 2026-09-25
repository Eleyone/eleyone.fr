#!/usr/bin/env bash
# Job de mise en ligne (story 11.5, AD-11, AD-14, AD-22) : ce qu'il vérifie avant de lancer quoi que
# ce soit, et comment il enchaîne. **Aucun cas ne lance Docker, ni ssh, ni le vrai job de contrôles** :
# les trois étapes de la chaîne sont remplacées par des scripts témoins qui enregistrent leurs
# arguments et rendent le code qu'on leur demande.
#
# **Le dépôt git, lui, est réel — et jetable.** Ce que ce job vérifie, ce sont les codes de sortie de
# « git merge-base --is-ancestor » et de « git diff --quiet » : un faux git ne prouverait que le
# comportement du faux. Chaque cas construit donc son propre dépôt dans $work (new_repo, comme
# test-check-private.sh depuis la story 0.9), y pose ses commits, ses tags et ses références
# origin/*, et y recopie le script éprouvé. Le dépôt du projet n'est jamais touché : aucun tag n'y
# est créé, aucune commande n'y tourne. Un faux git n'intervient que là où un vrai ne sait pas
# aider — forcer un code de sortie anormal, celui qui n'est ni 0 ni 1.
#
# **Point 19 d'AGENTS.md — l'aîné et ses gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-checks-job.sh et test-ship.sh. Gardes reprises : l'affirmation du code de sortie
# avant de compter quoi que ce soit ; la vérification qu'**aucune** étape n'a tourné après un refus ;
# un environnement réduit (« env -i ») ; le marqueur qui ne doit apparaître ni dans un message ni
# sous « bash -x ». Le tableau complet est dans le fichier de story.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

source_job=$root/scripts/ci/release-job.sh
job=$work/depot/scripts/ci/release-job.sh
etapes=$work/etapes

# Un script témoin à la place d'une étape de la chaîne : il note son nom et ses arguments, puis rend
# le code écrit dans $work/code-<nom> (0 par défaut). « ship » distingue ses deux appels, celui de
# « --check-env » et celui de la livraison.
temoin() { # $1 = nom, $2 = chemin dans le dépôt de test
  mkdir -p "$(dirname "$work/depot/$2")"
  {
    printf '#!/bin/sh\n'
    printf 'if [ $# -eq 0 ]; then printf "%%s\\n" "%s" >> %s; else printf "%%s %%s\\n" "%s" "$*" >> %s; fi\n' \
      "$1" "$etapes" "$1" "$etapes"
    printf 'cle=%s\n' "$1"
    printf 'if [ "$1" = "--check-env" ]; then cle=%s-check-env; fi\n' "$1"
    printf 'if [ -f "%s/code-$cle" ]; then exit "$(cat "%s/code-$cle")"; fi\n' "$work" "$work"
    printf 'exit 0\n'
  } > "$work/depot/$2"
  chmod +x "$work/depot/$2"
}

code_etape() { printf '%s' "$2" > "$work/code-$1"; }

etapes_lancees() { [[ -f $etapes ]] && cat "$etapes"; return 0; }
aucune_etape() {
  [[ ! -f $etapes ]] || { printf 'une étape a tourné malgré le refus :\n%s\n' "$(etapes_lancees)" >&2; exit 1; }
}

# Le dépôt de test : un commit, les trois témoins, et les références qu'un checkout « fetch-depth: 0 »
# aurait ramenées. Affiche le SHA du commit de base.
depot_de_test() {
  new_repo
  mkdir -p "$work/depot/scripts/ci" "$work/depot/scripts/release"
  cp "$source_job" "$work/depot/scripts/ci/release-job.sh"
  chmod +x "$work/depot/scripts/ci/release-job.sh"
  temoin checks-job scripts/ci/checks-job.sh
  temoin build-image scripts/release/build-image.sh
  temoin ship scripts/release/ship.sh
  printf 'le site\n' > "$work/depot/site.txt"
  commit_all "base"
}

git_test() { git -C "$work/depot" "$@"; }

origin() { # $1 = branche, $2 = commit
  git_test update-ref "refs/remotes/origin/$1" "$2"
}

# Un faux git qui ne dévie que pour une sous-commande, et délègue tout le reste au vrai : c'est le
# seul moyen d'obtenir un code « ni 0 ni 1 », celui que le job doit lire comme une anomalie.
faux_git() { # $1 = sous-commande déviée, $2 = code rendu
  local vrai
  vrai=$(command -v git) || { echo "git introuvable" >&2; exit 2; }
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'for a in "$@"; do case "$a" in -*) continue ;; *) premier=$a; break ;; esac; done\n'
    printf 'if [ "${premier:-}" = "%s" ]; then exit %s; fi\n' "$1" "$2"
    # « %q » et non « %s » : le chemin du vrai git vient de « command -v » et peut porter une
    # espace — un dossier d'installation quelconque suffit. Interpolé tel quel, il serait découpé
    # en deux mots par le shell du bouchon, qui n'exécuterait plus rien (constat de la revue du
    # code de la PR n° 120).
    printf 'exec %q "$@"\n' "$vrai"
  } > "$work/bin/git"
  chmod +x "$work/bin/git"
}

lance() { # $1 = valeur de GITHUB_REF (vide pour l'absence), $2… = arguments du job
  local ref=$1; shift
  local -a environnement=(PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work")
  [[ -z $ref ]] || environnement+=("GITHUB_REF=$ref")
  run env -i "${environnement[@]}" bash "$job" "$@"
}

# --- la chaîne nominale ---------------------------------------------------------------------------

case_release_job_enchaine_les_quatre_etapes() {
  local base
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.2.3 "$base"
  git_test tag v1.2.3-rc.1 "$base"
  lance refs/tags/v1.2.3
  assert_eq 0 "$rc" "une mise en ligne bien formée passe (messages : $err)"
  # L'ordre compte : la livraison est éprouvée avant les dix minutes de contrôles, la construction
  # après les contrôles, la livraison en dernier.
  assert_eq "ship --check-env
checks-job
build-image v1.2.3
ship v1.2.3" "$(etapes_lancees)" "les quatre étapes, dans l'ordre, avec le tag"
  assert_contains "répétition générale trouvée" "$out" "le tag -rc de même arbre est nommé"
}

case_release_job_repetition_sur_dev() {
  local base
  base=$(depot_de_test)
  origin dev "$base"
  git_test tag v1.2.3-rc.4 "$base"
  lance refs/tags/v1.2.3-rc.4
  assert_eq 0 "$rc" "une répétition bien formée passe (messages : $err)"
  assert_contains "build-image v1.2.3-rc.4" "$(etapes_lancees)" "l'image porte le tag de répétition"
  assert_contains "ship v1.2.3-rc.4" "$(etapes_lancees)" "la livraison aussi"
  # La règle du -rc de même arbre ne s'applique qu'aux tags de production.
  [[ $out != *avertissement* ]] || { echo "une répétition n'a pas à chercher de répétition" >&2; exit 1; }
}

# --- la référence et le nom du tag ------------------------------------------------------------------

case_release_job_ref_qui_nest_pas_un_tag() {
  # « Un push sur dev ou sur main ne déclenche pas release » : le déclencheur du YAML le garantit
  # déjà, cette garde-ci le répète là où elle se vérifie hors ligne.
  local base
  base=$(depot_de_test)
  origin main "$base"
  lance refs/heads/dev
  assert_eq 1 "$rc" "une référence de branche est refusée (messages : $err)"
  aucune_etape
  assert_contains "ne tourne que sur un tag" "$err" "le message le dit"
}

case_release_job_sans_github_ref() {
  local base
  base=$(depot_de_test)
  origin main "$base"
  lance ""
  assert_eq 2 "$rc" "sans GITHUB_REF, c'est une anomalie (messages : $err)"
  aucune_etape
  assert_contains "GITHUB_REF" "$err" "le message nomme la variable"
}

case_release_job_tags_mal_nommes() {
  local base mauvais
  base=$(depot_de_test)
  origin main "$base"
  origin dev "$base"
  for mauvais in "1.2.3" "v1.2" "v1.2.3.4" "v1.2.3-rc" "v1.2.3-rc.x" "v01.2.3" "v1.2.3-rc.01" \
                 "v1.2.3-beta.1" "vX.Y.Z" "V1.2.3"; do
    rm -f "$etapes"
    lance "refs/tags/$mauvais"
    assert_eq 1 "$rc" "$(printf 'le tag %q est refusé (messages : %s)' "$mauvais" "$err")"
    aucune_etape
  done
}

case_release_job_arguments() {
  local base
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.2.3 "$base"
  lance refs/tags/v1.2.3 v1.2.3
  assert_eq 2 "$rc" "un argument positionnel est une anomalie d'usage (messages : $err)"
  aucune_etape
  assert_contains "GITHUB_REF" "$err" "le message dit où le tag est lu"
}

# --- l'appartenance du tag à sa branche ----------------------------------------------------------------

case_release_job_tag_de_production_hors_de_main() {
  # Le tag est posé sur un commit que origin/main ne contient pas : c'est exactement l'entrée que la
  # garde doit refuser (point 9).
  local base ailleurs
  base=$(depot_de_test)
  origin main "$base"
  printf 'autre chose\n' > "$work/depot/site.txt"
  ailleurs=$(commit_all "hors de main")
  git_test tag v1.2.3 "$ailleurs"
  lance refs/tags/v1.2.3
  assert_eq 1 "$rc" "un tag de production hors de main est refusé (messages : $err)"
  aucune_etape
  assert_contains "ne descend pas de origin/main" "$err" "le message nomme la branche attendue"
}

case_release_job_tag_de_repetition_hors_de_dev() {
  local base ailleurs
  base=$(depot_de_test)
  origin dev "$base"
  printf 'autre chose\n' > "$work/depot/site.txt"
  ailleurs=$(commit_all "hors de dev")
  git_test tag v1.2.3-rc.1 "$ailleurs"
  lance refs/tags/v1.2.3-rc.1
  assert_eq 1 "$rc" "un tag de répétition hors de dev est refusé (messages : $err)"
  aucune_etape
  assert_contains "ne descend pas de origin/dev" "$err" "le message nomme la branche attendue"
}

case_release_job_tag_absent_du_depot() {
  local base
  base=$(depot_de_test)
  origin main "$base"
  lance refs/tags/v1.2.3
  assert_eq 2 "$rc" "un tag absent est une anomalie (messages : $err)"
  aucune_etape
  assert_contains "fetch-depth: 0" "$err" "le message dit ce qui manque au checkout"
}

case_release_job_sans_branche_distante() {
  # origin/main absente : le job ne conclut pas « ce tag ne descend pas de main » sur une information
  # qu'il n'a pas, il dit que le checkout est incomplet.
  local base
  base=$(depot_de_test)
  git_test tag v1.2.3 "$base"
  lance refs/tags/v1.2.3
  assert_eq 2 "$rc" "sans origin/main, c'est une anomalie (messages : $err)"
  aucune_etape
  assert_contains "fetch-depth: 0" "$err" "le message dit ce qui manque au checkout"
}

case_release_job_merge_base_en_anomalie() {
  # « --is-ancestor » a trois réponses : 0 descend, 1 ne descend pas, tout autre code est une
  # anomalie. Sans cette distinction, un git cassé passerait pour « le tag ne descend pas ».
  local base
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.2.3 "$base"
  faux_git merge-base 3
  lance refs/tags/v1.2.3
  assert_eq 2 "$rc" "un code inattendu de merge-base est une anomalie (messages : $err)"
  aucune_etape
  assert_contains "code 3" "$err" "le message donne le code"
}

# --- la règle du -rc de même arbre (AD-22, D-6) ------------------------------------------------------------

case_release_job_v1_0_0_sans_rc() {
  local base
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.0.0 "$base"
  lance refs/tags/v1.0.0
  assert_eq 1 "$rc" "v1.0.0 sans répétition est refusé (messages : $err)"
  aucune_etape
  assert_contains "v1.0.0-rc.N" "$err" "le message dit ce qui manque"
}

case_release_job_v1_0_0_avec_rc_de_meme_arbre() {
  # Un commit vide par-dessus porte **le même arbre** : c'est le cas réel, où la publication
  # dev → main ou une signature change le commit sans changer une ligne du site.
  local base rc_sha
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.0.0 "$base"
  git_test commit -q --allow-empty -m "répétition"
  rc_sha=$(git_test rev-parse HEAD)
  git_test tag v1.0.0-rc.1 "$rc_sha"
  lance refs/tags/v1.0.0
  assert_eq 0 "$rc" "v1.0.0 avec une répétition de même arbre passe (messages : $err)"
  assert_contains "v1.0.0-rc.1" "$out" "la répétition trouvée est nommée"
  assert_contains "ship v1.0.0" "$(etapes_lancees)" "la chaîne est allée jusqu'à la livraison"
}

case_release_job_v1_0_0_avec_rc_dun_autre_arbre() {
  # Un tag -rc existe, mais il ne porte pas le même site : ce n'est pas une répétition de **cette**
  # mise en ligne. Sans la comparaison d'arbre, sa seule existence suffirait.
  local base autre
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.0.0 "$base"
  printf 'un autre site\n' > "$work/depot/site.txt"
  autre=$(commit_all "autre arbre")
  git_test tag v1.0.0-rc.1 "$autre"
  lance refs/tags/v1.0.0
  assert_eq 1 "$rc" "un -rc d'un autre arbre ne vaut pas répétition (messages : $err)"
  aucune_etape
}

case_release_job_v1_0_0_avec_rc_a_zero_de_tete() {
  # « v1.0.0-rc.01 » n'est pas un tag de répétition valide : le job ne doit pas le compter, même
  # posé sur le bon arbre. La garde du nom vit au même endroit pour les deux canaux.
  local base rc_sha
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.0.0 "$base"
  git_test commit -q --allow-empty -m "répétition mal nommée"
  rc_sha=$(git_test rev-parse HEAD)
  git_test tag v1.0.0-rc.01 "$rc_sha"
  lance refs/tags/v1.0.0
  assert_eq 1 "$rc" "un -rc à zéro de tête ne vaut pas répétition (messages : $err)"
  aucune_etape
}

case_release_job_autre_tag_de_production_sans_rc_avertit_et_continue() {
  # **La moitié qui n'est pas un refus.** Pour tout tag de production autre que v1.0.0, l'absence
  # d'un -rc de même arbre est un avertissement : ce cas prouve que le job **continue**.
  local base
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.2.3 "$base"
  lance refs/tags/v1.2.3
  assert_eq 0 "$rc" "la mise en ligne continue (messages : $err)"
  assert_contains "avertissement" "$out" "l'absence est dite"
  assert_contains "ce n'est pas un refus" "$out" "et qualifiée"
  assert_eq "ship --check-env
checks-job
build-image v1.2.3
ship v1.2.3" "$(etapes_lancees)" "les quatre étapes ont tourné quand même"
}

case_release_job_comparaison_darbre_en_anomalie() {
  # « git diff --quiet » a les mêmes trois réponses que grep : 0 identique, 1 différent, au-delà une
  # erreur. Un git cassé ne doit pas passer pour « pas de répétition ».
  local base rc_sha
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.0.0 "$base"
  git_test commit -q --allow-empty -m "répétition"
  rc_sha=$(git_test rev-parse HEAD)
  git_test tag v1.0.0-rc.1 "$rc_sha"
  faux_git diff 3
  lance refs/tags/v1.0.0
  assert_eq 2 "$rc" "un code inattendu de git diff est une anomalie (messages : $err)"
  aucune_etape
}

case_release_job_liste_des_tags_en_anomalie() {
  local base
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.0.0 "$base"
  faux_git tag 3
  lance refs/tags/v1.0.0
  assert_eq 2 "$rc" "une liste de tags illisible est une anomalie (messages : $err)"
  aucune_etape
}

# --- l'enchaînement et ses arrêts --------------------------------------------------------------------------

case_release_job_environnement_de_livraison_incomplet() {
  # Le refus arrive **avant** les dix minutes de contrôles : découvrir un secret manquant après la
  # construction coûterait tout le job.
  local base
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.2.3 "$base"
  git_test tag v1.2.3-rc.1 "$base"
  code_etape ship-check-env 1
  lance refs/tags/v1.2.3
  assert_eq 1 "$rc" "un environnement de livraison incomplet arrête le job (messages : $err)"
  assert_eq "ship --check-env" "$(etapes_lancees)" "les contrôles n'ont pas tourné"
}

case_release_job_arret_a_la_premiere_etape_en_echec() {
  # Chaque étape en échec arrête la chaîne, avec son code : rien n'est construit après des contrôles
  # rouges, rien n'est livré après une construction ratée.
  local couple nom code_voulu base
  for couple in "checks-job:1" "build-image:1" "ship:2"; do
    nom=${couple%%:*}
    code_voulu=${couple#*:}
    rm -rf "$work/depot" "$etapes" "$work"/code-*
    base=$(depot_de_test)
    origin main "$base"
    git_test tag v1.2.3 "$base"
    git_test tag v1.2.3-rc.1 "$base"
    code_etape "$nom" "$code_voulu"
    lance refs/tags/v1.2.3
    assert_eq "$code_voulu" "$rc" "le code de $nom ressort tel quel (messages : $err)"
    assert_contains "$nom" "$err" "le message nomme l'étape en échec"
    local suivantes=""
    case $nom in
      checks-job) suivantes="build-image" ;;
      build-image) suivantes="ship v1.2.3" ;;
    esac
    if [[ -n $suivantes ]]; then
      local vu
      shell_grep_into vu -F -- "$suivantes" <<< "$(etapes_lancees)"
      assert_eq "" "$vu" "rien n'a tourné après $nom"
    fi
  done
}

case_release_job_hors_depot_git() {
  # Le job se lance dans le checkout du tag : ailleurs, il le dit au lieu de laisser git répondre
  # sur le dépôt du dossier courant.
  local base
  base=$(depot_de_test)
  origin main "$base"
  rm -rf "$work/hors-depot"
  mkdir -p "$work/hors-depot/scripts/ci"
  cp "$source_job" "$work/hors-depot/scripts/ci/release-job.sh"
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work" GITHUB_REF=refs/tags/v1.2.3 \
    bash "$work/hors-depot/scripts/ci/release-job.sh"
  assert_eq 2 "$rc" "hors d'un dépôt git, c'est une anomalie (messages : $err)"
  aucune_etape
  assert_contains "dépôt git" "$err" "le message le dit"
}

# --- les secrets --------------------------------------------------------------------------------------------

case_release_job_aucune_valeur_dans_les_messages() {
  # Le job ne lit aucun secret : il les laisse dans son environnement. Ni ses messages ni sa trace
  # de shell ne doivent en écrire un, même lancé avec « bash -x ».
  local base marqueur=CHAINE-QUI-NE-DOIT-PAS-SORTIR
  base=$(depot_de_test)
  origin main "$base"
  git_test tag v1.2.3 "$base"
  git_test tag v1.2.3-rc.1 "$base"
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work" GITHUB_REF=refs/tags/v1.2.3 \
    "DEPLOY_SSH_KEY=$marqueur" "HUGO_LEGAL_PUBLISHER_EMAIL=$marqueur" "PRIVATE_PATTERNS=$marqueur" \
    bash -x "$job"
  assert_eq 0 "$rc" "la chaîne passe sous bash -x (messages : $err)"
  [[ $out != *"$marqueur"* ]] || { echo "un secret est apparu sur la sortie standard" >&2; exit 1; }
  [[ $err != *"$marqueur"* ]] || { echo "bash -x a écrit un secret dans la trace" >&2; exit 1; }
  local rallumage
  shell_grep_into rallumage -nE '^[[:space:]]*set[[:space:]]+-[a-z]*x' "$source_job"
  assert_eq "" "$rallumage" "aucun « set -x » dans le script"
}

run_case "$@"
