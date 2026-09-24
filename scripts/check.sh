#!/usr/bin/env bash
# Point d'entrée unique des contrôles bloquants (AD-10), identique sur le poste, sur Gitea et sur GitHub.
#
#   scripts/check.sh              contrôles standard
#   scripts/check.sh --release    ajoute le niveau « release », celui des contrôles de mise en ligne
#                                 (C15, scripts/checks/release-pages.sh)
#
# Il construit le rendu de travail puis le build de production par scripts/build.sh (C14 : un
# avertissement de Hugo fait échouer le build, donc les contrôles), puis lance tous les scripts de
# scripts/checks/ : découverte dynamique, triés, lib.sh exclu — une story qui ajoute un contrôle ne
# modifie pas ce script. Tous tournent, même après un échec, et tous les écarts s'affichent avant le
# résumé (décidé le 18/09/2026). Aucun appel à git : le script fonctionne sans dossier .git.
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie (outil ou fichier manquant).
# Procédure : docs/procedures/check.md
set -euo pipefail

script_name=check
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

level=standard
while (($#)); do
  case $1 in
    --release) level=release; shift ;;
    *) printf '%s: option inconnue « %s ».\nusage : %s [--release]\n' "$script_name" "$1" "$0" >&2; exit 2 ;;
  esac
done
export CHECK_LEVEL=$level

tmp=$(mktemp -d) || { echo "$script_name: dossier temporaire impossible." >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT

build() { # $1 = environnement
  # La sortie du build est retenue, puis affichée après la ligne de check.sh : Hugo écrit sur la
  # sortie d'erreur au fil de l'eau, si bien qu'un simple « || printf » la ferait suivre au lieu de
  # la précéder (constat de la revue de la PR n° 36). Elle est ensuite gardée telle quelle : elle
  # nomme déjà le fichier et la ligne mieux qu'un reformatage.
  "$root/scripts/build.sh" "$1" > "$tmp/build.out" 2>&1 || {
    printf '%s: le build %s a échoué : les contrôles ne tournent pas sur une sortie périmée (C14).\n' \
      "$script_name" "$1" >&2
    cat "$tmp/build.out" >&2
    return 1
  }
}

build work || exit 1
build production || exit 1

shopt -s nullglob
scripts=()
for candidate in "$root"/scripts/checks/*.sh; do
  [[ $(basename "$candidate") != lib.sh ]] || continue
  scripts+=("$candidate")
done
shopt -u nullglob

failed=()
anomaly=0
# Chaque contrôle tourne **sous le chargeur unique** (AD-9). Sans lui, aucun contrôle ne voit un
# « HUGO_LEGAL_* » : « scripts/env.sh » n'enveloppait que hugo, appelé par build.sh, et check.sh
# était lancé nu. C23, qui doit chercher dans la sortie la **valeur** de l'adresse de l'éditeur,
# aurait cherché une chaîne vide et ne se serait jamais déclenché — un garde-fou qui ne garde rien,
# dans la story dont c'est l'objet (constat de la revue de spec de la story 9.1).
#
# Le chargeur plutôt qu'une lecture propre à C23 : AD-9 veut « un seul chargeur », et une deuxième
# lecture de .env aurait été une deuxième vérité. Il n'exporte que les huit variables légales ; les
# jetons du même .env n'entrent jamais dans l'environnement d'un contrôle.
chargeur="$root/scripts/env.sh"
[[ -x $chargeur ]] \
  || { printf '%s: chargeur des valeurs légales absent ou non exécutable (%s) : les contrôles ne verraient aucun HUGO_LEGAL_* (AD-9).\n' \
       "$script_name" "${chargeur#"$root"/}" >&2; exit 2; }

for candidate in "${scripts[@]}"; do
  name=$(basename "$candidate" .sh)
  rc=0
  "$chargeur" bash "$candidate" || rc=$?
  case $rc in
    0) ;;
    1) failed+=("$name") ;;
    *) failed+=("$name (code $rc)"); anomaly=1 ;;
  esac
done

if ((${#scripts[@]} == 0)); then
  printf '%s: aucun script de contrôle dans scripts/checks/ ; builds seuls, niveau %s.\n' "$script_name" "$level"
  exit 0
fi

if ((${#failed[@]})); then
  printf '%s: %s contrôle(s) en échec sur %s : %s\n' \
    "$script_name" "${#failed[@]}" "${#scripts[@]}" "${failed[*]}" >&2
  ((anomaly == 0)) || exit 2
  exit 1
fi

printf '%s: %s contrôle(s) passés, niveau %s.\n' "$script_name" "${#scripts[@]}" "$level"
