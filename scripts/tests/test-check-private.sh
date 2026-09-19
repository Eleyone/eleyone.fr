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
  skip_if_root "la liste des motifs"
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

# --- mode pre-receive : dépôt nu jetable muni d'un vrai hook, push depuis un clone (story 1.1) ---------------

# $1 valeur de PRIVATE_PATTERNS_FILE pour le hook ; vide : variable absente
bare_with_hook() {
  git init -q --bare "$work/nu.git"
  git -C "$work/nu.git" config core.hooksPath "$work/nu.git/hooks"
  if [[ -n $1 ]]; then
    printf "#!/bin/sh\nPRIVATE_PATTERNS_FILE='%s' exec bash '%s' pre-receive\n" "$1" "$root/scripts/check-private.sh" \
      > "$work/nu.git/hooks/pre-receive"
  else
    printf "#!/bin/sh\nunset PRIVATE_PATTERNS_FILE\nexec bash '%s' pre-receive\n" "$root/scripts/check-private.sh" \
      > "$work/nu.git/hooks/pre-receive"
  fi
  chmod +x "$work/nu.git/hooks/pre-receive"
  new_repo
  git -C "$work/depot" remote add origin "$work/nu.git"
}

push_branch() { # push de HEAD vers la branche essai du dépôt nu ; code dans rc, messages dans err
  run git -C "$work/depot" push origin HEAD:refs/heads/essai
}

branch_on_bare() { git -C "$work/nu.git" rev-parse --verify --quiet refs/heads/essai > /dev/null; }

refused_push() { # $1 libellé ; le push doit être refusé et la branche absente du dépôt nu
  push_branch
  [[ $rc != 0 ]] || { echo "$1 : push admis" >&2; exit 1; }
  if branch_on_bare; then echo "$1 : la branche existe sur le dépôt nu" >&2; exit 1; fi
}

case_pre_receive_sans_variable() {
  motifs
  bare_with_hook ""
  printf 'rien\n' > "$work/depot/a.txt"
  commit_all "essai" > /dev/null
  refused_push "sans PRIVATE_PATTERNS_FILE"
  assert_contains "sans PRIVATE_PATTERNS_FILE" "$err" "cause retransmise à l'auteur du push"
}

case_pre_receive_liste_absente() {
  bare_with_hook "$work/absente.txt"
  printf 'rien\n' > "$work/depot/a.txt"
  commit_all "essai" > /dev/null
  refused_push "liste absente"
  assert_contains "liste des motifs absente" "$err" "cause retransmise"
}

case_pre_receive_liste_sans_motif() {
  printf '# commentaire\n\n   \n\t\n' > "$work/vide.txt"
  bare_with_hook "$work/vide.txt"
  printf 'rien\n' > "$work/depot/a.txt"
  commit_all "essai" > /dev/null
  refused_push "liste sans motif"
  assert_contains "aucun motif dans la liste des motifs" "$err" "cause retransmise"
}

# Un commit de base admis, puis chaque ajout interdit repart de cette base.
base_pushed() {
  motifs
  bare_with_hook "$work/motifs.txt"
  mkdir -p "$work/depot/publique"
  printf 'page publique\n' > "$work/depot/publique/a.txt"
  base=$(commit_all "base")
  push_branch
  assert_eq 0 "$rc" "push de base admis (messages : $err)"
}

from_base() {
  git -C "$work/depot" reset -q --hard "$base"
  git -C "$work/nu.git" update-ref refs/heads/essai "$base"
}

case_pre_receive_chemins_interdits() {
  base_pushed
  local path
  for path in docs/private/notes.txt docs/context/cas.md .env sous/dossier/.env assets/cv/cv-fr.pdf; do
    from_base
    mkdir -p "$(dirname "$work/depot/$path")"
    printf 'contenu\n' > "$work/depot/$path"
    commit_all "ajout de $path" > /dev/null
    push_branch
    [[ $rc != 0 ]] || { echo "$path : push admis" >&2; exit 1; }
    [[ $(git -C "$work/nu.git" rev-parse refs/heads/essai) == "$base" ]] || { echo "$path : branche avancée sur le dépôt nu" >&2; exit 1; }
    assert_contains "$path" "$err" "chemin refusé nommé"
  done
}

case_pre_receive_motif_factice() {
  base_pushed
  from_base
  printf 'texte avec motif-interdit-essai\n' > "$work/depot/publique/notes.md"
  commit_all "motif" > /dev/null
  push_branch
  [[ $rc != 0 ]] || { echo "motif factice : push admis" >&2; exit 1; }
  assert_contains "publique/notes.md:1 (motif ligne 2)" "$err" "commit et chemin, sans le motif"
  [[ $err != *motif-interdit-essai* ]] || { echo "le motif apparaît dans les messages" >&2; exit 1; }
}

case_pre_receive_renommage_vers_docs_private() {
  base_pushed
  from_base
  mkdir -p "$work/depot/docs/private"
  git -C "$work/depot" mv publique/a.txt docs/private/a.txt
  commit_all "renommage" > /dev/null
  push_branch
  [[ $rc != 0 ]] || { echo "renommage vers docs/private : push admis" >&2; exit 1; }
  assert_contains "docs/private/a.txt" "$err" "chemin renommé refusé"
}

case_pre_receive_noms_proches_admis() {
  base_pushed
  from_base
  mkdir -p "$work/depot/docs"
  printf 'Les notes brutes restent sous docs/private/, jamais publiées.\n' > "$work/depot/mon-docs-private.md"
  printf 'notes publiques\n' > "$work/depot/docs/private-notes.md"
  commit_all "noms proches" > /dev/null
  push_branch
  assert_eq 0 "$rc" "push admis (NFR-9) (messages : $err)"
}

case_staged_et_history_sans_liste_inchanges() {
  new_repo
  printf 'x\n' > "$work/depot/a.txt"
  commit_all "essai" > /dev/null
  cd "$work/depot"
  run env PRIVATE_PATTERNS_FILE="$work/absente.txt" "$root/scripts/check-private.sh" history
  assert_eq 0 "$rc" "history sans liste : repli sur les chemins"
  assert_contains "chemins seulement" "$err" "avertissement"
  run env PRIVATE_PATTERNS_FILE="$work/absente.txt" "$root/scripts/check-private.sh" staged
  assert_eq 0 "$rc" "staged sans liste : repli sur les chemins"
  assert_contains "chemins seulement" "$err" "avertissement"
}

# --- surfaces ajoutées par la story 1.5 : variantes de .env, images, noms de chemin, messages ----------------

case_pre_receive_env_derives() {
  base_pushed
  local path
  for path in .env.production config/.env.local; do
    from_base
    mkdir -p "$(dirname "$work/depot/$path")"
    printf 'SECRET=x\n' > "$work/depot/$path"
    commit_all "ajout de $path" > /dev/null
    push_branch
    [[ $rc != 0 ]] || { echo "$path : push admis" >&2; exit 1; }
    assert_contains "$path" "$err" "variante de .env refusée, chemin nommé"
  done
}

case_pre_receive_noms_env_proches_admis() {
  base_pushed
  from_base
  mkdir -p "$work/depot/docs"
  printf 'notes\n' > "$work/depot/.environment.md"
  printf 'CLE=\n' > "$work/depot/env.example"
  printf 'notes\n' > "$work/depot/docs/env.md"
  commit_all "noms proches de .env" > /dev/null
  push_branch
  assert_eq 0 "$rc" "push admis (NFR-9) (messages : $err)"
}

case_pre_receive_image_refusee_svg_admis() {
  base_pushed
  from_base
  printf 'faux binaire\n' > "$work/depot/photo.PNG"
  commit_all "image" > /dev/null
  push_branch
  [[ $rc != 0 ]] || { echo "image : push admis" >&2; exit 1; }
  assert_contains "photo.PNG" "$err" "extension d image refusée, casse ignorée"
  from_base
  printf '<svg></svg>\n' > "$work/depot/schema.svg"
  commit_all "schema d2" > /dev/null
  push_branch
  assert_eq 0 "$rc" "SVG admis, les schémas D2 sont commités (messages : $err)"
}

case_pre_receive_message_de_commit() {
  base_pushed
  from_base
  # le motif est dans le message du premier commit, pas dans celui de la tête
  printf 'rien\n' > "$work/depot/publique/b.txt"
  commit_all "message avec motif-interdit-essai" > /dev/null
  printf 'rien\n' > "$work/depot/publique/c.txt"
  commit_all "message anodin" > /dev/null
  push_branch
  [[ $rc != 0 ]] || { echo "message de commit : push admis" >&2; exit 1; }
  assert_contains "message de commit privé" "$err" "message fautif signalé"
  assert_contains "motif ligne 2" "$err" "numéro de ligne du motif"
  [[ $err != *motif-interdit-essai* ]] || { echo "le motif apparaît dans les messages" >&2; exit 1; }
}

case_pre_receive_chemin_reprend_un_motif() {
  base_pushed
  from_base
  mkdir -p "$work/depot/motif-interdit-essai"
  printf 'contenu anodin\n' > "$work/depot/motif-interdit-essai/notes.md"
  commit_all "dossier nommé d apres un motif" > /dev/null
  push_branch
  [[ $rc != 0 ]] || { echo "chemin qui reprend un motif : push admis" >&2; exit 1; }
  assert_contains "chemin qui reprend un motif" "$err" "refus signalé"
  assert_contains "motif ligne 2" "$err" "numéro de ligne du motif"
  [[ $err != *motif-interdit-essai* ]] || { echo "le chemin fautif, donc le motif, apparaît dans les messages" >&2; exit 1; }
}

case_staged_memes_refus_que_le_hook() {
  motifs
  new_repo
  cd "$work/depot"
  printf 'SECRET=x\n' > "$work/depot/.env.local"
  git -C "$work/depot" add -A
  run env PRIVATE_PATTERNS_FILE="$work/motifs.txt" "$root/scripts/check-private.sh" staged
  assert_eq 1 "$rc" "variante de .env refusée dans l index"
  git -C "$work/depot" rm -q --cached .env.local
  rm "$work/depot/.env.local"
  mkdir -p "$work/depot/motif-interdit-essai"
  printf 'anodin\n' > "$work/depot/motif-interdit-essai/a.txt"
  printf 'faux binaire\n' > "$work/depot/vue.jpg"
  git -C "$work/depot" add -A
  run env PRIVATE_PATTERNS_FILE="$work/motifs.txt" "$root/scripts/check-private.sh" staged
  assert_eq 1 "$rc" "chemin qui reprend un motif et image refusés dans l index"
  assert_contains "vue.jpg" "$err" "image nommée"
  assert_contains "chemin qui reprend un motif" "$err" "chemin masqué mais signalé"
}

case_history_message_et_chemin() {
  motifs
  new_repo
  printf 'anodin\n' > "$work/depot/a.txt"
  commit_all "message avec motif-interdit-essai" > /dev/null
  cd "$work/depot"
  run env PRIVATE_PATTERNS_FILE="$work/motifs.txt" "$root/scripts/check-private.sh" history
  assert_eq 1 "$rc" "message fautif trouvé par l audit"
  assert_contains "message de commit privé" "$err" "surface nommée"
  [[ $err != *motif-interdit-essai* ]] || { echo "le motif apparaît dans les messages" >&2; exit 1; }
}

case_pre_receive_exceptions_nommees() {
  base_pushed
  from_base
  mkdir -p "$work/depot/design/suisse/screenshots"
  printf 'CLE=\n' > "$work/depot/.env.example"
  printf 'faux binaire\n' > "$work/depot/design/suisse/screenshots/accueil.png"
  commit_all "exceptions nommées" > /dev/null
  push_branch
  assert_eq 0 "$rc" ".env.example et captures de design admis (messages : $err)"
  from_base
  mkdir -p "$work/depot/assets/images"
  printf 'faux binaire\n' > "$work/depot/assets/images/portrait.webp"
  commit_all "image hors des captures de design" > /dev/null
  push_branch
  [[ $rc != 0 ]] || { echo "image du site : push admis" >&2; exit 1; }
  assert_contains "assets/images/portrait.webp" "$err" "image du site refusée d ici C20"
}

run_case "$@"
