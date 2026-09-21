#!/usr/bin/env bash
# Publie un cas : tous les contrôles, puis draft: false dans une PR, toujours de la même façon.
#
#   scripts/publish-case.sh <translationKey>           contrôle et affiche le plan, ne modifie rien
#   scripts/publish-case.sh <translationKey> --relu     publie, commit, pousse et ouvre la PR
#
# Sans --relu, rien n'est touché : le format exige une relecture humaine avant qu'un cas devienne
# public, et ce drapeau en est la trace explicite (décidé par Arnaud le 21/09/2026). Il couvre aussi
# la page du groupe, qui part dans la même PR que son premier cas publié (D-3, AD-4).
#
# Le script ne publie jamais le poste du cas : un poste en brouillon fait échouer la publication et
# le script le nomme. Les fichiers se trouvent par le manifeste du rendu de travail, jamais par un
# chemin deviné (AD-10) ; la décision vit dans scripts/lib/publish-case.sh, éprouvée hors ligne.
# Codes de sortie : 0 conforme, 1 refus (le message dit quoi corriger), 2 anomalie.
# Procédure : docs/procedures/publish-case.md
set -euo pipefail

script_name=publish-case
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
. "$root/scripts/lib/shell.sh"
. "$root/scripts/lib/publish-case.sh"

die() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

cle="" relu=0
while (($#)); do
  case $1 in
    --relu) relu=1; shift ;;
    -*) die "option inconnue « $1 ».\nusage : $0 <translationKey> [--relu]" ;;
    *) [[ -z $cle ]] || die "une seule clé attendue.\nusage : $0 <translationKey> [--relu]"; cle=$1; shift ;;
  esac
done
[[ -n $cle ]] || die "usage : $0 <translationKey> [--relu]"

command -v jq > /dev/null 2>&1 || die "jq est introuvable : prérequis du poste."

# La réécriture passe par un fichier temporaire hors du dépôt, supprimé quoi qu'il arrive : un arrêt
# au milieu ne laisse ni fichier orphelin dans content/, ni dossier à nettoyer à la main (constat de
# la revue de la PR n° 55).
tmp=$(mktemp -d) || die "dossier temporaire impossible."
trap 'rm -rf "$tmp"' EXIT
readonly pages_file="ci/release-pages.txt"
[[ -f $pages_file ]] || die "$pages_file est introuvable."

# Rien ne se publie depuis un arbre sale : le commit emporterait des modifications étrangères.
[[ -z $(git status --porcelain) ]] || refuse "l'arbre de travail n'est pas propre : commiter ou ranger avant de publier."

# --- 1. les contrôles, sur l'état courant --------------------------------------------------------
# D'abord, pour ne rien modifier sur un dépôt déjà en écart : les faux positifs ne se mêlent pas aux
# vrais. Le build de travail qu'ils lancent produit aussi les manifestes que la décision lit.
printf '%s: contrôles sur l'"'"'état courant…\n' "$script_name"
sortie_controles=""
if ! sortie_controles=$(scripts/check.sh 2>&1); then
  printf '%s: les contrôles échouent avant toute modification : rien n'"'"'est touché.\n' "$script_name" >&2
  printf '%s\n' "$sortie_controles" >&2
  exit 1
fi

work=${CHECK_WORK_ROOT:-build/work}
plan=$(publish_case_plan "$work/checks.json" "$work/en/checks.json" "$cle") || exit $?

# --- 2. le plan ------------------------------------------------------------------------------------
fichiers=()
cles=()
while IFS= read -r ligne; do
  [[ -n $ligne ]] || continue
  case $ligne in
    case=*|index=*) fichiers+=("content/${ligne#*=}") ;;
    release=*) cles+=("${ligne#*=}") ;;
    *) die "plan illisible : $ligne" ;;
  esac
done <<< "$plan"

printf '%s: %s fichier(s) à passer hors brouillon :\n' "$script_name" "${#fichiers[@]}"
printf '  %s\n' "${fichiers[@]}"
ajouts=()
for entree in "${cles[@]}"; do
  if grep -qxF "$entree" "$pages_file"; then
    printf '  %s est déjà dans %s\n' "$entree" "$pages_file"
  else
    ajouts+=("$entree")
    printf '  %s à ajouter à %s\n' "$entree" "$pages_file"
  fi
done

if ((relu == 0)); then
  printf '%s: rien n'"'"'a été modifié. Relire ces fichiers, puis relancer avec --relu.\n' "$script_name"
  exit 0
fi

# --- 3. la branche -----------------------------------------------------------------------------------
# La branche de publication part de dev, comme toute branche de travail. La règle ne vaut qu'ici :
# le mode sans --relu ne modifie rien, et se consulte depuis n'importe où.
branche_courante=$(git branch --show-current) || die "branche courante illisible."
[[ $branche_courante == dev ]] \
  || refuse "une publication part de dev, pas de « $branche_courante » : se placer sur dev à jour."

branche="feat/publish-case-$cle"
# « git rev-parse … && refuse » ferait sortir le script sous set -e quand la branche n'existe pas,
# le « et » rendant alors un code non nul : le cas normal est écrit en clair.
if git rev-parse --verify --quiet "refs/heads/$branche" > /dev/null; then
  refuse "la branche $branche existe déjà : la supprimer ou la reprendre à la main."
fi
git switch --quiet --create "$branche" || die "création de la branche $branche impossible."

# --- 4. draft: false, dans le front matter seulement --------------------------------------------------
# La réécriture est bornée au front matter, entre les deux premiers « --- » : un « draft: » cité dans
# le corps du texte n'est pas touché. Le script vérifie qu'il a changé une ligne, et une seule.
for fichier in "${fichiers[@]}"; do
  [[ -f $fichier ]] || die "fichier annoncé par le manifeste mais absent : $fichier"
  # L'enveloppe commune distingue « rien trouvé » d'une erreur de lecture : grep -c affiche « 0 »
  # et rend 1 quand rien ne correspond.
  shell_grep_into avant -c '^draft: *false *$' "$fichier"
  awk '
    NR == 1 && $0 == "---" { dans = 1; print; next }
    dans && $0 == "---" { dans = 0; print; next }
    dans && /^draft:[[:space:]]*true[[:space:]]*$/ { print "draft: false"; next }
    { print }
  ' "$fichier" > "$tmp/publie" || die "réécriture impossible de $fichier."
  shell_grep_into apres -c '^draft: *false *$' "$tmp/publie"
  ((apres == avant + 1)) || die "front matter inattendu dans $fichier : $avant puis $apres ligne(s) « draft: false ». La ligne attendue s'écrit « draft: true », seule sur sa ligne et sans commentaire ; rien n'a été remplacé."
  cp "$tmp/publie" "$fichier" || die "remplacement impossible de $fichier."
done

if ((${#ajouts[@]})); then
  # Un fichier qui ne finit pas par un saut de ligne collerait la première clé à la dernière ligne
  # (constat de la revue de la PR n° 53). Le cas se règle avant d'ajouter, pas après.
  [[ -s $pages_file && $(tail -c 1 "$pages_file") == "" ]] \
    || printf '\n' >> "$pages_file" || die "écriture impossible dans $pages_file."
  printf '%s\n' "${ajouts[@]}" >> "$pages_file" || die "écriture impossible dans $pages_file."
fi

# --- 5. le commit, les contrôles, la PR ---------------------------------------------------------------
git add -- "${fichiers[@]}" "$pages_file" || die "ajout à l'index impossible."
message="feat: publie le cas $cle"$'\n\n'"Passé hors brouillon :"$'\n'
for fichier in "${fichiers[@]}"; do message+="- $fichier"$'\n'; done
if ((${#ajouts[@]})); then
  message+=$'\n'"Ajouté à $pages_file :"$'\n'
  for entree in "${ajouts[@]}"; do message+="- $entree"$'\n'; done
fi
git commit --quiet -m "$message" || die "commit impossible."

printf '%s: contrôles sur le cas publié…\n' "$script_name"
if ! sortie_controles=$(scripts/check.sh 2>&1); then
  printf '%s: les contrôles refusent le cas publié. Le commit est sur %s ; corriger, puis relancer les contrôles.\n' \
    "$script_name" "$branche" >&2
  printf '%s\n' "$sortie_controles" >&2
  exit 1
fi

git push --quiet --set-upstream origin "$branche" || die "push de $branche impossible."

corps="$root/.pr-body.md"
{
  printf 'Publication du cas `%s`.\n\n' "$cle"
  printf 'Passé hors brouillon :\n\n'
  printf -- '- `%s`\n' "${fichiers[@]}"
  if ((${#ajouts[@]})); then
    printf '\nAjouté à `%s` (D-5) :\n\n' "$pages_file"
    printf -- '- `%s`\n' "${ajouts[@]}"
  fi
  printf '\nLes contrôles passent avant et après la modification (`scripts/check.sh`). '
  printf 'Le poste du cas n'"'"'est pas touché : `publish-case` ne le publie jamais à la place de la story qui en a la charge.\n'
} > "$corps" || die "écriture du corps de la PR impossible."

scripts/create-pull-request.sh --title "feat: publie le cas $cle" --body-file "$corps"
printf '%s: cas %s publié sur %s.\n' "$script_name" "$cle" "$branche"
