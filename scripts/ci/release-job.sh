#!/usr/bin/env bash
# Job de mise en ligne (story 11.5, AD-11, AD-14, AD-22). Le workflow .gitea/workflows/release.yaml
# ne contient que son déclencheur, le checkout et l'appel de ce script : toute la logique vit ici,
# pour qu'aucune forge n'en porte une version à elle (règle d'AD-11, constat S1 de la revue de spec).
#
#   scripts/ci/release-job.sh    vérifie le tag, puis enchaîne contrôles, construction et livraison
#
# Le tag n'est pas un argument : il est lu dans **GITHUB_REF**, que Gitea Actions pose comme
# « refs/tags/<tag> » pour un push de tag. Le YAML n'a donc rien à calculer, pas même une expression.
# Rejouer le job à la main depuis le poste (plan de secours d'AD-14, homelab arrêté) se fait en
# posant cette variable : GITHUB_REF=refs/tags/v1.2.3 scripts/ci/release-job.sh
#
# Les quatre vérifications qui précèdent **toute** construction :
#
#   1. GITHUB_REF désigne un tag. Un push de branche n'a rien à faire ici ;
#   2. le tag est nommé « vX.Y.Z » (production) ou « vX.Y.Z-rc.N » (répétition), sans zéro de tête ;
#   3. il **descend** de sa branche : origin/main pour la production, origin/dev pour la répétition
#      (AD-11, AD-22, AD-24). La question est posée à « git merge-base --is-ancestor », dont le
#      **code de sortie** distingue les trois réponses — 0 descend, 1 ne descend pas, tout autre code
#      est une anomalie —, là où une liste de branches à filtrer les confondrait (décision A4) ;
#   4. pour « v1.0.0 » **seulement**, un tag « v1.0.0-rc.N » de même arbre doit exister (AD-22, D-6).
#      Pour tout autre tag de production, son absence n'est qu'un avertissement.
#
# Ce script ne lit aucun secret : il les laisse dans son environnement, d'où scripts/release/
# build-image.sh et scripts/release/ship.sh tirent les leurs. Il leur demande seulement, avant les
# dix minutes de contrôles, si la livraison serait possible (« ship.sh --check-env ») : découvrir un
# secret manquant après la construction coûterait tout le job. La liste des noms n'est pas recopiée
# ici — c'est ship.sh qui la porte, une seule fois (point 19 d'AGENTS.md).
# Codes de sortie : 0 mis en ligne ; 1 refus (ref, tag, branche, répétition manquante) ; 2 anomalie ;
# au-delà, le code de l'étape en échec.
# Procédure : docs/procedures/release-workflow.md
set -euo pipefail
# La chaîne appelée porte les valeurs légales et la clé de déploiement dans son environnement : une
# trace de shell écrirait dans le journal de la CI ce que les scripts appelés prennent soin de taire.
set +x

script_name=release-job
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"

die() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

(($# == 0)) || die "aucun argument attendu, $# reçu(s) : le tag est lu dans GITHUB_REF.
usage : $0"

# --- l'environnement du job, avant d'agir -------------------------------------------------------------
# L'aîné scripts/ci/checks-job.sh vérifie ce dont il a besoin (UID et GID numériques) avant de lancer
# quoi que ce soit. Ce que ce job-ci exige, c'est un dépôt git complet : les trois vérifications de
# branche et de répétition ne répondent juste que si le checkout a ramené tout l'historique, les
# branches distantes et les tags (« fetch-depth: 0 »).
command -v git > /dev/null 2>&1 || die "git est introuvable : le job vérifie le tag dans l'historique."
git rev-parse --git-dir > /dev/null 2>&1 \
  || die "ce dossier n'est pas un dépôt git : le job se lance dans le checkout du tag."

# --- la référence, puis le tag ---------------------------------------------------------------------------
ref=${GITHUB_REF:-}
[[ -n $ref ]] \
  || die "GITHUB_REF absente : le job est déclenché par un push de tag, qui la pose (AD-11). Rien n'a été lancé."
[[ $ref == refs/tags/* ]] \
  || refuse "GITHUB_REF vaut $(printf '%q' "$ref") : ce job ne tourne que sur un tag. Un push sur dev ou sur main ne met rien en ligne (AD-14). Rien n'a été lancé."
tag=${ref#refs/tags/}

# Mêmes expressions **disjointes** que scripts/release/ship.sh et deploy/remote/deploy-site.sh :
# ancrées, sans zéro de tête, un canal chacune.
motif_production='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
motif_repetition='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)-rc\.(0|[1-9][0-9]*)$'

if [[ $tag =~ $motif_production ]]; then
  canal=production
  branche=main
elif [[ $tag =~ $motif_repetition ]]; then
  canal=repetition
  branche=dev
else
  refuse "tag $(printf '%q' "$tag") refusé : une mise en ligne porte « vX.Y.Z », une répétition « vX.Y.Z-rc.N » (AD-14). Rien n'a été lancé."
fi

printf '%s: tag %s, canal %s, branche attendue origin/%s.\n' "$script_name" "$tag" "$canal" "$branche"

# --- le tag descend-il de sa branche ? -----------------------------------------------------------------------
existe() { # $1 = référence git ; 0 si elle désigne un commit
  git rev-parse --verify --quiet "$1^{commit}" > /dev/null 2>&1
}

existe "refs/tags/$tag" \
  || die "tag $tag absent de ce dépôt : le checkout n'a pas ramené les tags (« fetch-depth: 0 » exigé, AD-11). Rien n'a été lancé."
existe "refs/remotes/origin/$branche" \
  || die "origin/$branche absente de ce dépôt : le checkout n'a pas ramené les branches distantes (« fetch-depth: 0 » exigé, AD-11). Rien n'a été lancé."

# « --is-ancestor » répond par son code, et les trois réponses se distinguent. Une liste de branches
# à filtrer, elle, rendrait 0 avec une sortie vide aussi bien pour « ne descend pas » que pour
# « git a échoué » (décision A4 de la revue de spec).
code=0
git merge-base --is-ancestor "refs/tags/$tag^{commit}" "refs/remotes/origin/$branche^{commit}" || code=$?
case $code in
  0) ;;
  1) refuse "le tag $tag ne descend pas de origin/$branche : un tag $canal se pose sur cette branche-là (AD-11, AD-22, AD-24). Rien n'a été lancé." ;;
  *) die "« git merge-base --is-ancestor » a rendu le code $code : ni « descend » (0) ni « ne descend pas » (1), donc une anomalie. Rien n'a été lancé." ;;
esac
printf '%s: le tag %s descend de origin/%s.\n' "$script_name" "$tag" "$branche"

# --- la répétition générale (AD-22, D-6) ----------------------------------------------------------------------
# Règle, telle quelle : pour le tag **v1.0.0 seulement**, si aucun tag « v1.0.0-rc.N » ne pointe sur
# un commit de même arbre, le job échoue **avant toute construction** ; pour tout autre tag de
# production, cette absence n'est qu'un **avertissement**, jamais un refus.
#
# « même arbre » et non « même commit » : la publication dev → main est un fast-forward, mais un
# hotfix ou une signature changeraient le commit sans changer une ligne du site. C'est ce que
# « git diff --quiet <tag> <rc> » compare, et ses codes se distinguent comme ceux de grep : 0 aucune
# différence, 1 des différences, au-delà une erreur.
rc_de_meme_arbre() { # $1 = tag de production ; remplit « repetition_trouvee »
  repetition_trouvee=""
  local liste rc numero code_diff
  # Le motif est un **glob littéral** : « . » n'y est pas un joker, à la différence d'une expression
  # régulière construite depuis une variable (piège connu, docs/procedures/shell-scripts.md).
  liste=$(git tag --list "$1-rc.*") || return 2
  while IFS= read -r rc; do
    [[ -n $rc ]] || continue
    # Comparaison **littérale**, sans regex construite : le préfixe exact, puis un numéro entier.
    [[ $rc == "$1-rc."* ]] || continue
    numero=${rc#"$1-rc."}
    [[ $numero =~ ^(0|[1-9][0-9]*)$ ]] || continue
    code_diff=0
    git diff --quiet "$1^{tree}" "$rc^{tree}" || code_diff=$?
    case $code_diff in
      0) repetition_trouvee=$rc; return 0 ;;
      1) ;;
      *) return 2 ;;
    esac
  done <<< "$liste"
  return 1
}

if [[ $canal == production ]]; then
  repetition_trouvee=""
  code=0
  rc_de_meme_arbre "$tag" || code=$?
  case $code in
    0) printf '%s: répétition générale trouvée sur le même arbre : %s.\n' "$script_name" "$repetition_trouvee" ;;
    1)
      if [[ $tag == v1.0.0 ]]; then
        refuse "aucun tag v1.0.0-rc.N ne pointe sur un commit de même arbre : la première mise en ligne se répète avant de se faire (AD-22, D-6). Rien n'a été lancé."
      fi
      printf "%s: avertissement — aucun tag %s-rc.N de même arbre. Pour un tag de production autre que v1.0.0, ce n'est pas un refus (AD-22, D-6) ; la mise en ligne continue.\n" \
        "$script_name" "$tag"
      ;;
    *) die "comparaison des tags de répétition impossible (git, code $code). Rien n'a été lancé." ;;
  esac
fi

# --- la chaîne ------------------------------------------------------------------------------------------------------
# Chaque étape **s'annonce** avant de tourner : un journal de CI muet ne permet pas de savoir ce qui
# a tourné (garde de l'aîné scripts/ci/checks-job.sh). Et la chaîne s'arrête à la première étape en
# échec, avec son code : elle ne construit pas après des contrôles rouges, et ne livre pas après une
# construction ratée.
# L'annonce et le refus nomment tous deux le **script** en plus du libellé : « échec de l'étape de
# construction » envoie chercher dans le journal, « échec de scripts/release/build-image.sh » envoie
# lire le bon fichier.
etape() { # $1 = libellé, $2 = script, $3… = ses arguments
  local libelle=$1 script=$2
  shift 2
  local relatif=${script#"$root"/}
  printf '%s: %s (%s)\n' "$script_name" "$libelle" "$relatif"
  local code_etape=0
  bash "$script" "$@" || code_etape=$?
  ((code_etape == 0)) || {
    printf '%s: %s (%s) : échec (code %s). La chaîne est abandonnée ici.\n' \
      "$script_name" "$libelle" "$relatif" "$code_etape" >&2
    exit "$code_etape"
  }
}

etape "livraison : ce que l'environnement doit porter" "$root/scripts/release/ship.sh" --check-env
etape "contrôles (AD-10, AD-11)" "$root/scripts/ci/checks-job.sh"
etape "construction de l'image $tag (AD-13)" "$root/scripts/release/build-image.sh" "$tag"
etape "livraison de $tag (AD-14)" "$root/scripts/release/ship.sh" "$tag"

printf '%s: %s mis en ligne sur le canal %s.\n' "$script_name" "$tag" "$canal"
