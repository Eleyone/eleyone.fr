#!/usr/bin/env bash
# Construit l'image du site (AD-13). Une seule commande de build dans le dépôt, donc une seule à
# maintenir : l'enveloppe de mise en ligne, scripts/release/build-image.sh, appelle ce script avec
# --release plutôt que d'écrire un second « docker build » (décidé par Arnaud le 21/09/2026).
#
#   scripts/build-image.sh                       contrôles au niveau standard
#   scripts/build-image.sh --release             y ajoute les contrôles de mise en ligne (epic 11)
#   scripts/build-image.sh --tag <étiquette>     étiquette de l'image, « eleyone-site:dev » par défaut
#   scripts/build-image.sh --secret <fichier>    autre fichier de valeurs légales
#   scripts/build-image.sh --patterns <fichier>  autre liste de motifs interdits
#
# Les valeurs légales passent par un **secret BuildKit** : monté le temps d'une instruction, il
# n'entre dans aucune couche, et « docker history » n'en montre rien (AD-9). Le fichier vit dans le
# dépôt privé — docs/private/legal-release.env par défaut : ENV_MODE=release refuse aussi bien le
# .env du poste que le fichier factice commité, et c'est voulu.
#
# La **liste des motifs interdits** passe par un second secret, pour la même raison : .dockerignore
# exclut docs/private/ du contexte de build, et sans elle C21 ne confronte rien et C22 rend une
# anomalie (AD-12, AD-21). Elle est facultative — un build ordinaire n'en a pas besoin —, et le
# défaut est la liste du dépôt privé, absente d'un clone qui ne l'a pas.
# Codes de sortie : 0 image construite, 1 refus (build en échec, secret manquant), 2 anomalie.
# Procédure : docs/procedures/build-image.md
set -euo pipefail

script_name=build-image
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Le dossier d'appel est retenu avant de se placer à la racine : un « --secret ../legal.env » se
# résout depuis là où l'utilisateur l'a écrit, pas depuis la racine du dépôt (constat de la revue
# de la PR n° 59).
appel=$PWD
cd "$root"
. "$root/scripts/lib/tools.sh"

die() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

level=standard
tag=eleyone-site:dev
# Le défaut est absolu : une valeur relative se résout depuis le dossier d'appel (voir plus bas),
# ce qui ferait dépendre le défaut de l'endroit d'où le script est lancé.
secret=${LEGAL_RELEASE_ENV_FILE:-$root/docs/private/legal-release.env}
# La liste des motifs suit la même règle de défaut absolu. Deux régimes, et un seul critère les
# sépare — **l'option, pas la variable** :
#
#   - « --patterns <fichier> » est un acte explicite : le fichier doit être là, sinon refus. Sans
#     cela, un chemin mal écrit se serait tu et l'image serait sortie d'un contrôle qui n'a rien
#     confronté ;
#   - PRIVATE_PATTERNS_FILE et le défaut sont une **configuration ambiante** : absents, le build
#     ordinaire continue sans second secret, et le script le dit. Au niveau release, où C21 et C22
#     exigent tous deux la liste, l'absence redevient un refus.
#
# Les deux gardes sont **séparées** exprès, pour qu'un cas de test puisse en exercer une sans que
# l'autre ne la couvre : mesuré, une première écriture faisait refuser les deux par la même ligne, et
# la mutation de la seconde restait verte (point 9 — le test doit exercer l'entrée que la garde
# refuse, et être joué une fois sans la garde).
patterns=${PRIVATE_PATTERNS_FILE:-$root/docs/private/forbidden-patterns.txt}
patterns_exigee=0
while (($#)); do
  case $1 in
    --release) level=release; shift ;;
    --tag) (($# >= 2)) || die "--tag attend une valeur."; tag=$2; shift 2 ;;
    --secret) (($# >= 2)) || die "--secret attend une valeur."; secret=$2; shift 2 ;;
    --patterns) (($# >= 2)) || die "--patterns attend une valeur."; patterns=$2; patterns_exigee=1; shift 2 ;;
    *) die "option inconnue « $1 ».\nusage : $0 [--release] [--tag <étiquette>] [--secret <fichier>] [--patterns <fichier>]" ;;
  esac
done

command -v docker > /dev/null 2>&1 || die "docker est introuvable : prérequis du poste."
load_tools_env "${TOOLS_ENV_FILE:-$root/tools.env}"

[[ $secret == /* ]] || secret="$appel/$secret"
# « -f » et pas seulement « -r » : un dossier lisible passerait ce test, et Docker échouerait plus
# tard sur un montage de secret impossible, en langage de démon (constat de la revue de la PR n° 59).
[[ -f $secret && -r $secret ]] \
  || refuse "fichier de valeurs légales introuvable, illisible, ou qui n'est pas un fichier ($secret) : le créer dans le dépôt privé, ou en désigner un autre par --secret (docs/procedures/build-image.md)."

# Les deux fichiers du dépôt sont refusés ici, avant le build : scripts/env.sh les refuse aussi en
# mode release, mais un message qui arrive après cinq minutes de build ne sert à personne.
canonique() { local chemin=$1; [[ -e $chemin ]] || { printf '%s' "$chemin"; return 0; }; readlink -f -- "$chemin"; }
secret_canonique=$(canonique "$secret")
for interdit in "$root/.env" "$root/ci/legal-placeholder.env"; do
  [[ $secret_canonique != "$(canonique "$interdit")" ]] \
    || refuse "un fichier de travail du dépôt ne peut pas servir de secret de mise en ligne : ${interdit#"$root"/}."
done

# « --secret id=…,src=… » sépare ses champs par des virgules : un chemin qui en contient une serait
# coupé, et le démon répondrait sur un champ inconnu (constat de la revue de la PR n° 59).
[[ $secret != *,* ]] \
  || refuse "le chemin du fichier de valeurs légales contient une virgule, que « docker build --secret » lit comme un séparateur : le déplacer."

# --- la liste des motifs, second secret ------------------------------------------------------------
# Les mêmes gardes, une par une, parce que le piège est exactement le même : chemin relatif résolu
# depuis le dossier d'appel, fichier régulier et lisible, aucune virgule (point 18 d'AGENTS.md — un
# constat d'une classe connue est un ordre de balayage, pas une ligne à corriger).
[[ $patterns == /* ]] || patterns="$appel/$patterns"
monter_patterns=1
if [[ ! -f $patterns || ! -r $patterns ]]; then
  monter_patterns=0
  # Garde 1 — l'option a été écrite : le fichier qu'elle nomme doit exister, à tout niveau.
  ((patterns_exigee == 0)) \
    || refuse "liste des motifs introuvable, illisible, ou qui n'est pas un fichier ($patterns) : « --patterns » désigne un fichier qui doit exister (docs/procedures/build-image.md)."
  # Garde 2 — mise en ligne : C21 et C22 exigent tous deux la liste, et le build échouerait après
  # plusieurs minutes. Le refus est immédiat, comme celui du fichier de travail du dépôt plus haut.
  [[ $level != release ]] \
    || refuse "liste des motifs absente ($patterns) : au niveau « release », C21 et C22 l'exigent (AD-12, AD-21). La désigner par --patterns ou par PRIVATE_PATTERNS_FILE (docs/procedures/build-image.md)."
  # Build ordinaire sans liste : le script le **dit** plutôt que de se taire — un montage
  # silencieusement absent est exactement ce qui a rendu le défaut de la story 11.3 invisible.
  printf '%s: liste des motifs absente (%s) : le build ne la recevra pas, et C21 se contentera de la forme.\n' \
    "$script_name" "$patterns" >&2
fi
if ((monter_patterns == 1)); then
  [[ $patterns != *,* ]] \
    || refuse "le chemin de la liste des motifs contient une virgule, que « docker build --secret » lit comme un séparateur : le déplacer."
fi

printf '%s: image %s, contrôles au niveau %s, outils de %s.\n' "$script_name" "$tag" "$level" "$CHECK_IMAGE"

# Le secret est nommé « legal_env » dans le Dockerfile, qui l'exige (required=true) : un build sans
# lui échoue au lieu de produire une image aux mentions légales vides. « private_patterns » y est
# facultatif : sans lui, BuildKit ne monte rien et le fichier n'existe pas (vérifié le 25/09/2026).
arguments=(--secret "id=legal_env,src=$secret")
((monter_patterns == 0)) || arguments+=(--secret "id=private_patterns,src=$patterns")

# **Les étapes « build » et « runtime » ne se mettent jamais en cache.** Un secret n'entre pas dans
# la clé de cache de BuildKit : une valeur légale modifiée entre deux constructions ne la change pas,
# et la seconde image servirait les mentions légales de la première. C'est le même mécanisme qui fait
# qu'un build sans secret réussit sur une couche déjà construite (docs/procedures/build-image.md).
#
# **« build » seule ne suffit pas**, et c'est une mesure, pas une déduction (point 10 d'AGENTS.md).
# Avec « --no-cache-filter build », l'instruction RUN se rejoue bien — « docker build --target build »
# le montre : la page porte la nouvelle valeur —, mais le « COPY --from=build /src/public/ » de
# l'étape « runtime » est **servi depuis le cache**, et l'image finale sort identique à la
# précédente, au condensat de manifeste près, qui est le même. Mesuré le 25/09/2026 avec Docker
# 29.8.1 / buildx 0.37.1 : trois constructions successives avec trois valeurs différentes ont toutes
# exporté « sha256:4e9d3d2d… ». Avec « build,runtime », la même construction exporte un manifeste
# différent et la page porte la bonne valeur.
#
# L'étape « tools », elle, garde son cache : c'est la longue — elle télécharge et installe Hugo et
# D2 — et elle ne dépend d'aucun secret. C'est tout l'intérêt de nommer les étapes plutôt que
# d'employer « --no-cache ».
exec docker build \
  --no-cache-filter build,runtime \
  "${arguments[@]}" \
  --build-arg "CHECK_IMAGE=$CHECK_IMAGE" \
  --build-arg "CHECK_LEVEL=$level" \
  --tag "$tag" \
  "$root"
