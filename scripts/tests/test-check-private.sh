#!/usr/bin/env bash
# Garde-fou public/privé : constats D2 (fichier de motifs sans motif) et D3 (audit depuis un sous-dossier)
# de la rétrospective de l'epic 0. Motifs et contenus d'essai seulement, jamais docs/private/.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

motifs() { printf '# motifs d essai\nmotif-interdit-essai\n' > "$work/motifs.txt"; }

depot_avec_motif() { # le motif est à la racine, l'audit est lancé depuis sous/
  new_repo
  mkdir -p "$work/depot/sous"
  printf 'texte avec motif-interdit-essai\n' > "$work/depot/racine.md"
  printf 'rien\n' > "$work/depot/sous/fichier.txt"
  commit_all "essai" > /dev/null
}

require_patterns() { # $1 fichier de motifs ; lance require_patterns_file dans un processus à part, car die sort
  run bash -c 'script_name=essai; . "$1/scripts/lib/gitea.sh"; require_patterns_file "$2" "aucun envoi sans audit"' _ "$root" "$1"
}

case_d3_historique_depuis_un_sous_dossier() {
  motifs
  depot_avec_motif
  cd "$work/depot/sous"
  run env PRIVATE_PATTERNS_FILE="$work/motifs.txt" "$root/scripts/check-private.sh" history
  assert_eq 1 "$rc" "motif trouvé hors du sous-dossier"
  assert_contains "racine.md:1 (motif ligne 2)" "$err" "emplacement du motif, sans son contenu"
}

case_d3_index_depuis_un_sous_dossier() {
  motifs
  depot_avec_motif
  cd "$work/depot/sous"
  run env PRIVATE_PATTERNS_FILE="$work/motifs.txt" "$root/scripts/check-private.sh" staged
  assert_eq 1 "$rc" "motif trouvé dans l'index hors du sous-dossier"
  assert_contains "racine.md:1 (motif ligne 2)" "$err" "emplacement du motif"
}

case_d3_chemin_de_motifs_relatif() {
  motifs
  depot_avec_motif
  cd "$work/depot/sous"
  run env PRIVATE_PATTERNS_FILE=../../motifs.txt "$root/scripts/check-private.sh" history
  assert_eq 1 "$rc" "chemin relatif lu depuis le dossier de lancement"
}

case_recherche_des_chemins_en_erreur() {
  new_repo
  printf 'x\n' > "$work/depot/a.txt"
  commit_all "essai" > /dev/null
  # un grep qui échoue toujours, placé en tête du PATH : l'erreur ne doit jamais valoir « aucun chemin privé »
  mkdir -p "$work/bin"
  printf '#!/bin/sh\nexit 2\n' > "$work/bin/grep"
  chmod +x "$work/bin/grep"
  cd "$work/depot"
  run env PATH="$work/bin:$PATH" PRIVATE_PATTERNS_FILE="$work/absent.txt" "$root/scripts/check-private.sh" history
  assert_eq 1 "$rc" "refus"
  assert_contains "recherche des chemins impossible" "$err" "raison"
}

case_d2_fichier_sans_motif() {
  printf '# commentaire\n\n   \n\t\n\r\n  # autre\n' > "$work/vide.txt"
  motifs
  depot_avec_motif
  cd "$work/depot"
  run env PRIVATE_PATTERNS_FILE="$work/vide.txt" "$root/scripts/check-private.sh" history
  assert_eq 0 "$rc" "chemins seulement : aucun contenu cherché"
  assert_contains "aucun motif dans le fichier de motifs" "$err" "repli annoncé"
  assert_contains "chemins seulement" "$err" "repli annoncé"
  require_patterns "$work/vide.txt"
  assert_eq 1 "$rc" "refusé par les scripts qui exigent l'audit"
  assert_contains "sans aucun motif" "$err" "raison"
}

case_d2_fichier_absent() {
  require_patterns "$work/absent.txt"
  assert_eq 1 "$rc" "fichier absent refusé"
  assert_contains "fichier de motifs absent" "$err" "raison"
}

case_d2_fichier_avec_motif() {
  motifs
  require_patterns "$work/motifs.txt"
  assert_eq 0 "$rc" "fichier avec au moins un motif admis"
}

case_d2_fichier_illisible() {
  if [[ $(id -u) == 0 ]]; then
    echo "cas sans objet sous root, qui lit tout fichier"
    return 0
  fi
  motifs
  chmod 000 "$work/motifs.txt"
  require_patterns "$work/motifs.txt"
  assert_eq 1 "$rc" "fichier illisible refusé"
  assert_contains "illisible" "$err" "raison"
  new_repo
  printf 'x\n' > "$work/depot/a.txt"
  commit_all "essai" > /dev/null
  cd "$work/depot"
  run env PRIVATE_PATTERNS_FILE="$work/motifs.txt" "$root/scripts/check-private.sh" history
  assert_eq 2 "$rc" "check-private.sh s'arrête en code 2"
}

run_case "$@"
