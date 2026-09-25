#!/usr/bin/env bash
# Les secrets d'Actions du dépôt sur la forge portent-ils exactement les noms de l'architecture ?
# (story 11.6, second critère d'acceptation ; AD-9, AD-12, AD-14.)
#
#   scripts/release/check-forge-secrets.sh
#
# **Ce script ne lit aucune valeur de secret, et ne le peut pas.** L'API de Gitea rend, pour chaque
# secret, son nom, sa description et sa date de création — jamais sa valeur (mesuré le 25/09/2026,
# fichier de la story 11.6). Lister les noms ne divulgue donc rien, et ce script n'a aucun moyen de
# vérifier qu'un secret porte la **bonne** valeur : ce qu'il vérifie, c'est que les douze existent,
# sous leurs noms exacts. Une valeur fausse se voit à la mise en ligne, pas ici.
#
# Les douze noms ne sont **pas recopiés** ici (point 19 d'AGENTS.md) :
#
#   - les huit valeurs légales sont nommées dans ci/legal-placeholder.env, dont C18 vérifie qu'il
#     porte exactement les noms d'AD-9, comme scripts/release/build-image.sh les y lit déjà ;
#   - les quatre autres sont nommées dans ci/release-secrets.txt, que scripts/release/ship.sh lit
#     aussi et qu'un cas de test confronte à .gitea/workflows/release.yaml.
#
# Un secret **manquant** est un refus : le workflow release échouerait, et mieux vaut l'apprendre
# ici. Un secret **inattendu** est nommé sans bloquer — ANTHROPIC_API_KEY appartient à l'epic 12 et
# peut être posé d'avance (AD-16). Toute **variable** d'Actions est nommée sans bloquer aussi :
# l'architecture n'en attend aucune, mais une variable posée par erreur mérite d'être vue.
#
# Codes de sortie : 0 les douze sont là ; 1 au moins un manque ; 2 vérification impossible (jeton,
# dépôt, réponse de la forge, liste de noms illisible).
# Procédures : docs/procedures/serveur-de-production.md, docs/procedures/release-workflow.md
set -euo pipefail
set +x # même lancé avec bash -x, la trace s'arrête ici, avant la lecture du jeton

script_name=release/check-forge-secrets
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../lib/gitea.sh
. "$script_dir/lib/gitea.sh"
# shellcheck source=../lib/shell.sh
. "$script_dir/lib/shell.sh"
# shellcheck source=../lib/secrets.sh
. "$script_dir/lib/secrets.sh"

# die redéfinit celui de scripts/lib/gitea.sh : ici, une lecture impossible est une **anomalie**
# (code 2), pas un refus. Les fonctions de la bibliothèque appellent cette définition-ci.
die() { printf '%s: %b\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

readonly usage="usage : scripts/release/check-forge-secrets.sh (aucun argument)"
(($# == 0)) || die "$usage"

# Au-delà de ce nombre d'entrées, rien ne dit que la réponse n'est pas une **page** : la pagination
# de cet endpoint n'a pas pu être mesurée, puisque le dépôt n'avait aucun secret le jour où sa forme
# a été relevée, et le projet s'est déjà fait prendre par une pagination supposée (shell-scripts.md,
# story 0.8). Le script refuse alors de conclure plutôt que de déclarer manquant un secret qui
# serait simplement sur la page suivante. Le seuil est très au-dessus des douze attendus et très
# au-dessous de toute taille de page plausible.
readonly plafond_liste=20

root=$(git rev-parse --show-toplevel 2>/dev/null) || die "à lancer dans le dépôt."
cd "$root"

require_tools
# Le dépôt distant est confronté au dépôt canonique **avant** tout appel : sans cela, le jeton
# partirait interroger les secrets d'un dépôt que personne n'a demandé (garde de l'aîné
# scripts/verify-and-merge-pr.sh).
check_origin

tmp=$(mktemp -d) || die "dossier temporaire impossible."
trap 'rm -rf "$tmp"' EXIT

# --- les douze noms attendus, lus et non recopiés ------------------------------------------------
attendus=()
secrets_read_env_names "$root/ci/legal-placeholder.env" legaux HUGO_LEGAL_
((${#legaux[@]} > 0)) \
  || die "aucune variable HUGO_LEGAL_* dans ci/legal-placeholder.env : la liste d'AD-9 est vide, il n'y aurait rien à vérifier."
secrets_read_names "$root/ci/release-secrets.txt" autres
((${#autres[@]} > 0)) \
  || die "aucun nom dans ci/release-secrets.txt : la liste d'AD-12 et d'AD-14 est vide, il n'y aurait rien à vérifier."
attendus=("${legaux[@]}" "${autres[@]}")

# Les deux fichiers refusent chacun leurs propres doublons ; un même nom présent dans les **deux**
# ne serait vu par aucun des deux, et ferait annoncer treize attendus dont douze distincts.
declare -A vus=()
for nom in "${attendus[@]}"; do
  [[ -z ${vus[$nom]:-} ]] \
    || die "le nom $nom est attendu deux fois : ci/legal-placeholder.env et ci/release-secrets.txt le portent tous les deux."
  vus[$nom]=1
done

# --- ce que la forge en dit ------------------------------------------------------------------------
load_gitea_env "$root/.env"
check_token_owner "$tmp/user.json"

# Un code HTTP par cause, jamais « erreur » : c'est ce qui distingue un jeton sans la portée voulue
# d'un dépôt absent, et ces deux-là ne se corrigent pas au même endroit (garde de l'aîné).
lire_liste() { # $1 chemin d'API, $2 fichier de réponse, $3 ce dont il s'agit
  local code
  code=$(gitea_api GET "$1" "$2")
  case $code in
    200) return 0 ;;
    401|403)
      die "la forge refuse le jeton pour $3 (HTTP $code) : il lui manque la portée des secrets du dépôt (« write:repository » ou l'accès administrateur du dépôt). Procédure : $gitea_token_procedure" ;;
    404)
      die "$3 : dépôt ou point d'API absent (HTTP 404). Soit le dépôt n'est pas celui que le jeton peut lire, soit cette version de la forge n'a pas cet endpoint." ;;
    000)
      die "aucune réponse de la forge pour $3 : la forge est injoignable. Son adresse n'est pas affichée (NFR-9)." ;;
    *)
      die "réponse inattendue de la forge pour $3 (HTTP $code) : $(forge_message "$2")" ;;
  esac
}

# Les noms sont lus **une entrée à la fois, par son rang**. Ils viennent de la forge et pourraient
# porter n'importe quel octet, saut de ligne compris : une lecture ligne par ligne en ferait deux
# entrées, et un nom fabriqué exprès pourrait alors se faire passer pour un autre. Rien ne passe par
# une substitution de processus, qui masquerait l'échec de jq (piège connu, shell-scripts.md).
noms_de() { # $1 fichier de réponse, $2 nom du tableau à remplir, $3 ce dont il s'agit
  local -n noms_destination=$2
  local annonce i nom
  noms_destination=()
  jq -e 'type == "array"' "$1" > /dev/null 2>&1 \
    || die "$3 : la forge n'a pas rendu un tableau. Sa réponse n'est pas affichée, elle pourrait porter n'importe quoi."
  annonce=$(jq -r 'length' "$1") || die "$3 : longueur de la réponse illisible."
  [[ $annonce =~ ^[0-9]+$ ]] || die "$3 : longueur de la réponse illisible."
  ((annonce <= plafond_liste)) \
    || die "$3 : la forge en rend $annonce, au-delà des $plafond_liste que ce script sait lire d'un coup. La pagination de cet endpoint n'a jamais été mesurée : le script refuse de conclure plutôt que de déclarer manquant ce qui serait sur la page suivante."
  for ((i = 0; i < annonce; i++)); do
    jq -e --argjson i "$i" '.[$i].name as $n | (($n | type) == "string") and (($n | length) > 0)' "$1" > /dev/null 2>&1 \
      || die "$3 : une entrée de la réponse n'a pas de nom."
    nom=$(jq -r --argjson i "$i" '.[$i].name' "$1") || die "$3 : les noms de la réponse sont illisibles."
    noms_destination+=("$nom")
  done
}

lire_liste "/repos/$gitea_canonical_repo/actions/secrets" "$tmp/secrets.json" "les secrets d'Actions du dépôt"
noms_de "$tmp/secrets.json" presents "les secrets d'Actions du dépôt"

lire_liste "/repos/$gitea_canonical_repo/actions/variables" "$tmp/variables.json" "les variables d'Actions du dépôt"
noms_de "$tmp/variables.json" variables "les variables d'Actions du dépôt"

# --- la confrontation --------------------------------------------------------------------------------
declare -A presents_index=()
for nom in "${presents[@]}"; do presents_index[$nom]=1; done

manquants=()
for nom in "${attendus[@]}"; do
  [[ -n ${presents_index[$nom]:-} ]] || manquants+=("$nom")
done

# Un nom venu de la forge n'est pas une chaîne sûre : il s'affiche par « %q », qui neutralise les
# octets de contrôle qu'un journal interpréterait, et laisse un nom ordinaire tel quel (même garde
# que deploy/remote/deploy-site.sh pour un mot venu du réseau).
inattendus=()
for nom in "${presents[@]}"; do
  [[ -n ${vus[$nom]:-} ]] || inattendus+=("$(printf '%q' "$nom")")
done

signalees=()
for nom in "${variables[@]}"; do signalees+=("$(printf '%q' "$nom")"); done

# --- le rapport, lisible même quand tout passe ------------------------------------------------------
printf '%s: %s secrets attendus, %s présents sur le dépôt, %s variable(s).\n' \
  "$script_name" "${#attendus[@]}" "${#presents[@]}" "${#variables[@]}"
if ((${#manquants[@]})); then
  printf '  manquant   %s\n' "${manquants[@]}"
fi
if ((${#inattendus[@]})); then
  printf '  inattendu  %s\n' "${inattendus[@]}"
  printf "%s: %s secret(s) inattendu(s) ci-dessus. Ils ne bloquent pas — ANTHROPIC_API_KEY relève de l'epic 12 (AD-16) et peut être posé d'avance —, mais une faute de frappe se lit ici **et** dans les manquants.\n" \
    "$script_name" "${#inattendus[@]}"
fi
if ((${#signalees[@]})); then
  printf '  variable   %s\n' "${signalees[@]}"
  printf "%s: l'architecture n'attend aucune variable d'Actions : celles-ci ne bloquent pas, mais rien ne les lit.\n" "$script_name"
fi

if ((${#manquants[@]})); then
  refuse "${#manquants[@]} secret(s) manquant(s) : le workflow release échouerait. Les poser : docs/procedures/serveur-de-production.md."
fi
printf "%s: les %s secrets attendus sont présents, sous leurs noms exacts. Aucune valeur n'a été lue.\n" \
  "$script_name" "${#attendus[@]}"
