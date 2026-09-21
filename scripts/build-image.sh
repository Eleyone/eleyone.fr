#!/usr/bin/env bash
# Construit l'image du site (AD-13). Une seule commande de build dans le dépôt, donc une seule à
# maintenir : l'epic 11 appellera ce script avec --release plutôt que d'en écrire un second
# (décidé par Arnaud le 21/09/2026).
#
#   scripts/build-image.sh                     contrôles au niveau standard
#   scripts/build-image.sh --release           y ajoute les contrôles de mise en ligne (epic 11)
#   scripts/build-image.sh --tag <étiquette>   étiquette de l'image, « eleyone-site:dev » par défaut
#   scripts/build-image.sh --secret <fichier>  autre fichier de valeurs légales
#
# Les valeurs légales passent par un **secret BuildKit** : monté le temps d'une instruction, il
# n'entre dans aucune couche, et « docker history » n'en montre rien (AD-9). Le fichier vit dans le
# dépôt privé — docs/private/legal-release.env par défaut : ENV_MODE=release refuse aussi bien le
# .env du poste que le fichier factice commité, et c'est voulu.
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
while (($#)); do
  case $1 in
    --release) level=release; shift ;;
    --tag) (($# >= 2)) || die "--tag attend une valeur."; tag=$2; shift 2 ;;
    --secret) (($# >= 2)) || die "--secret attend une valeur."; secret=$2; shift 2 ;;
    *) die "option inconnue « $1 ».\nusage : $0 [--release] [--tag <étiquette>] [--secret <fichier>]" ;;
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

printf '%s: image %s, contrôles au niveau %s, outils de %s.\n' "$script_name" "$tag" "$level" "$CHECK_IMAGE"

# Le secret est nommé « legal_env » dans le Dockerfile, qui l'exige (required=true) : un build sans
# lui échoue au lieu de produire une image aux mentions légales vides.
exec docker build \
  --secret "id=legal_env,src=$secret" \
  --build-arg "CHECK_IMAGE=$CHECK_IMAGE" \
  --build-arg "CHECK_LEVEL=$level" \
  --tag "$tag" \
  "$root"
