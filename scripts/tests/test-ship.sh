#!/usr/bin/env bash
# Livraison de l'image vers le serveur de production (story 11.5, AD-14, AD-22) : ce qu'elle refuse,
# ce qu'elle envoie, et ce qu'elle n'envoie pas. **Aucun cas ne lance ssh ni Docker** : de faux
# binaires sont posés en tête de PATH et enregistrent leurs appels, exactement comme
# scripts/tests/test-build-image.sh le fait depuis la story 4.1. La suite reste hors ligne (story 0.9).
# La chaîne réelle est éprouvée sur le serveur par la story 11.6.
#
# **Point 19 d'AGENTS.md — l'aîné et ses gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-release-build-image.sh. Gardes reprises : le faux docker en tête de PATH ;
# l'affirmation du code de sortie **avant** de compter quoi que ce soit ; la vérification qu'aucun
# effet de bord n'a eu lieu après un refus ; un environnement réduit (« env -i ») pour qu'un cas
# rende le même verdict sur le poste et en CI ; un TMPDIR qui n'appartient qu'au cas, et dont on
# compte les restes ; le marqueur qui ne doit apparaître ni dans un message, ni sous « bash -x ».
# Gardes ajoutées ici : un faux ssh qui relève les **droits** du fichier de clé qu'on lui donne, et
# la lecture de PIPESTATUS, que le pipeline de livraison rend nécessaire. Le tableau complet est dans
# le fichier de story.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

script=$root/scripts/release/ship.sh

# --- les faux binaires ------------------------------------------------------------------------------

# Le faux docker enregistre chaque appel. « save » écrit quelques octets sur sa sortie standard —
# l'archive que le pipeline transporte — puis sort avec le code demandé : c'est ainsi qu'un cas
# fabrique une **archive tronquée** sans rien construire.
faux_docker() { # $1 = code de « save » (0 par défaut), $2 = code de « image inspect » (0 par défaut)
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$*" >> %s\n' "$work/appels-docker"
    printf 'case "$1 $2" in\n'
    printf '  "image inspect") exit %s ;;\n' "${2:-0}"
    printf 'esac\n'
    printf 'if [ "$1" = save ]; then printf "FAUSSE-ARCHIVE-DE-%%s" "$2"; exit %s; fi\n' "${1:-0}"
    printf 'exit 0\n'
  } > "$work/bin/docker"
  chmod +x "$work/bin/docker"
}

# Le faux ssh enregistre, pour chaque appel : la ligne d'arguments, la commande distante (le dernier
# mot), les droits du fichier désigné par « -i », le contenu reçu sur l'entrée standard. Il rend le
# code écrit dans $work/ssh-code.<n>, et affiche ce qui est écrit dans $work/ssh-sortie.<n>.
faux_ssh() {
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'w=%s\n' "$work"
    cat <<'FAUX'
n=1
[ -f "$w/ssh-compteur" ] && n=$(($(cat "$w/ssh-compteur") + 1))
printf '%s' "$n" > "$w/ssh-compteur"
printf '%s\n' "$*" >> "$w/ssh-args"
prev=""; cle=""; connus=""; last=""
for a in "$@"; do
  [ "$prev" = "-i" ] && cle=$a
  case "$a" in UserKnownHostsFile=*) connus=${a#UserKnownHostsFile=} ;; esac
  prev=$a
  last=$a
done
printf '%s\n' "$last" >> "$w/ssh-commandes"
if [ -n "$cle" ]; then
  ls -ld "$cle" | awk '{ print $1 }' >> "$w/ssh-droits-cle"
  # Pas de « || true » : un bouchon fait partie du dispositif de test, et une copie qui échoue
  # sans le dire laisserait un cas conclure sur un fichier absent. Le faux ssh **échoue** alors,
  # bruyamment, plutôt que de faire semblant d'avoir lu la clé (constat bloquant de la revue du
  # code de la PR n° 120 ; la règle vient de la rétrospective de l'epic 3).
  cp "$cle" "$w/ssh-cle.$n" || { echo "faux ssh : copie de la clé impossible" >&2; exit 97; }
fi
if [ -n "$connus" ]; then
  cp "$connus" "$w/ssh-connus.$n" || { echo "faux ssh : copie des empreintes impossible" >&2; exit 97; }
fi
cat > "$w/ssh-entree.$n"
[ -f "$w/ssh-sortie.$n" ] && cat "$w/ssh-sortie.$n"
code=0
[ -f "$w/ssh-code.$n" ] && code=$(cat "$w/ssh-code.$n")
exit "$code"
FAUX
  } > "$work/bin/ssh"
  chmod +x "$work/bin/ssh"
}

# Un faux gzip, pour le seul cas qui le fait échouer : ailleurs, le gzip du système fait très bien
# l'affaire et le pipeline reste celui de la production.
faux_gzip() { # $1 = code de sortie
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'cat > /dev/null\n'
    printf 'exit %s\n' "${1:-0}"
  } > "$work/bin/gzip"
  chmod +x "$work/bin/gzip"
}

code_ssh() { printf '%s' "$2" > "$work/ssh-code.$1"; }
sortie_ssh() { printf '%s\n' "$2" > "$work/ssh-sortie.$1"; }

appels_docker() { [[ -f $work/appels-docker ]] && cat "$work/appels-docker"; return 0; }
commandes_ssh() { [[ -f $work/ssh-commandes ]] && cat "$work/ssh-commandes"; return 0; }
args_ssh() { [[ -f $work/ssh-args ]] && cat "$work/ssh-args"; return 0; }
nombre_ssh() { local n=0; [[ -f $work/ssh-compteur ]] && n=$(cat "$work/ssh-compteur"); printf '%s' "$n"; }

docker_a_sauvegarde() { [[ -f $work/appels-docker ]] && grep -q '^save ' "$work/appels-docker"; }
ssh_lance() { [[ -f $work/ssh-compteur ]]; }

# Un TMPDIR **qui n'appartient qu'au cas** : « ${TMPDIR:-/tmp} » est partagé avec le reste de la
# machine, et y compter supposerait son environnement (piège connu, shell-scripts.md).
tmpdir_a_soi() {
  local tmp=$work/tmp-a-soi
  rm -rf "$tmp"; mkdir -p "$tmp"
  printf '%s' "$tmp"
}

restes_dans() { find "$1" -mindepth 1 | wc -l; }

# Une clé privée factice : ce qui compte est qu'elle porte l'en-tête qu'OpenSSH exige, pas qu'elle
# soit utilisable — aucun ssh réel ne la lit.
cle_factice=$'-----BEGIN OPENSSH PRIVATE KEY-----\nAAAAFAUSSECLEDESSAI\n-----END OPENSSH PRIVATE KEY-----'
empreintes_factices=$'# empreinte du serveur\nserveur-essai ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAUSSEEMPREINTE'

# L'environnement complet d'une livraison, sous forme d'arguments pour « env ».
environnement() { # $@ = paires NOM=valeur qui remplacent ou retirent (NOM= pour vider)
  local -a arguments=(
    "DEPLOY_SSH_KEY=$cle_factice"
    "DEPLOY_HOST=compte-essai@serveur-essai"
    "DEPLOY_KNOWN_HOSTS=$empreintes_factices"
  )
  arguments+=("$@")
  printf '%s\0' "${arguments[@]}"
}

livre() { # $1 = tag ou option, $2… = surcharges d'environnement
  local premier=$1; shift
  local -a variables=()
  mapfile -d '' -t variables < <(environnement "$@")
  run env -i PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" bash "$script" "$premier"
}

refus_sans_rien_envoyer() { # $1 = code attendu, $2 = libellé
  assert_eq "$1" "$rc" "$2 (messages : $err)"
  ! ssh_lance || { printf 'ssh a été lancé malgré le refus : %s\n' "$(args_ssh)" >&2; exit 1; }
  ! docker_a_sauvegarde || { printf 'docker save a été lancé malgré le refus : %s\n' "$(appels_docker)" >&2; exit 1; }
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste"
}

# --- la livraison nominale, et l'exclusivité des canaux -----------------------------------------------

case_ship_livraison_de_production() {
  faux_docker; faux_ssh
  sortie_ssh 2 "deploy-site: production : eleyone-site:v1.2.3"
  livre v1.2.3
  assert_eq 0 "$rc" "une livraison de production passe (messages : $err)"
  assert_contains "save eleyone-site:v1.2.3" "$(appels_docker)" "docker save nomme l'image, tag compris"
  # Les commandes distantes, dans l'ordre : la livraison, puis la confirmation. Et **rien d'autre**.
  assert_eq "deploy v1.2.3
status" "$(commandes_ssh)" "une seule commande de livraison, puis status"
  assert_contains "eleyone-site:v1.2.3" "$out" "la sortie de status est affichée"
}

case_ship_livraison_de_repetition() {
  faux_docker; faux_ssh
  sortie_ssh 2 "deploy-site: répétition : eleyone-site:v1.2.3-rc.4"
  livre v1.2.3-rc.4
  assert_eq 0 "$rc" "une répétition passe (messages : $err)"
  assert_contains "save eleyone-site:v1.2.3-rc.4" "$(appels_docker)" "docker save nomme l'image de répétition"
  assert_eq "rehearse deploy v1.2.3-rc.4
status" "$(commandes_ssh)" "une seule commande de livraison, sur le canal de répétition, puis status"
  assert_contains "v1.2.3-rc.4" "$out" "la sortie de status est affichée"
}

# Le plus dangereux des constats de la revue de spec (P1) : lu comme une séquence, le critère
# d'acceptation faisait partir **les deux** commandes pour un même tag — un « -rc » en production,
# ou l'inverse. Ce cas compte les commandes de livraison, canal par canal : il doit y en avoir une.
case_ship_un_seul_canal_par_tag() {
  local tag interdit vu
  for tag in v1.2.3 v1.2.3-rc.4; do
    rm -rf "$work/bin" "$work/ssh-compteur" "$work/ssh-commandes" "$work/ssh-args" "$work/appels-docker"
    faux_docker; faux_ssh
    livre "$tag"
    assert_eq 0 "$rc" "la livraison de $tag passe (messages : $err)"
    assert_eq 2 "$(nombre_ssh)" "deux appels ssh pour $tag : la livraison et status"
    if [[ $tag == *-rc.* ]]; then interdit="deploy $tag"; else interdit="rehearse deploy $tag"; fi
    shell_grep_into vu -Fx -- "$interdit" <<< "$(commandes_ssh)"
    assert_eq "" "$vu" "le canal opposé n'a rien reçu pour $tag"
  done
}

case_ship_status_dans_les_deux_canaux() {
  local tag vu
  for tag in v1.2.3 v1.2.3-rc.4; do
    rm -rf "$work/bin" "$work/ssh-compteur" "$work/ssh-commandes" "$work/ssh-args" "$work/appels-docker"
    faux_docker; faux_ssh
    livre "$tag"
    assert_eq 0 "$rc" "la livraison de $tag passe (messages : $err)"
    shell_grep_into vu -Fx -- "status" <<< "$(commandes_ssh)"
    assert_eq "status" "$vu" "status est envoyé pour $tag"
  done
}

# --- les tags ----------------------------------------------------------------------------------------

case_ship_tags_refuses() {
  # Chaque forme est refusée **avant** que quoi que ce soit ne parte. La liste couvre ce que la garde
  # laisse passer si on l'écrit trop large : sans préfixe, sans correctif, un « rc » sans numéro, un
  # zéro de tête, une pré-version qui n'est pas une répétition, et une injection derrière une espace.
  local mauvais
  for mauvais in "1.2.3" "v1.2" "v1.2.3.4" "v1.2.3-rc" "v1.2.3-rc.x" "v01.2.3" "v1.2.3-rc.01" \
                 "v1.2.3-beta.1" "v1.2.3 ; echo raté" "vX.Y.Z" "" "V1.2.3" $'v1.2.3\nv9.9.9'; do
    rm -rf "$work/bin" "$work/ssh-compteur" "$work/ssh-commandes" "$work/ssh-args" "$work/appels-docker"
    faux_docker; faux_ssh
    livre "$mauvais"
    refus_sans_rien_envoyer 1 "$(printf 'le tag %q est refusé' "$mauvais")"
  done
  # Et les formes justes passent, sans quoi la garde ne prouverait rien : un « refuse tout »
  # refuserait aussi les tags corrects (point 11 — mesurer le cas court **et** le cas long).
  local bon
  for bon in v0.0.0 v10.20.30 v0.1.0-rc.0; do
    rm -rf "$work/bin" "$work/ssh-compteur" "$work/ssh-commandes" "$work/ssh-args" "$work/appels-docker"
    faux_docker; faux_ssh
    livre "$bon"
    assert_eq 0 "$rc" "« $bon » est un tag valide (messages : $err)"
  done
}

# --- l'environnement ---------------------------------------------------------------------------------

case_ship_variables_absentes() {
  local nom
  for nom in DEPLOY_SSH_KEY DEPLOY_HOST DEPLOY_KNOWN_HOSTS; do
    rm -rf "$work/bin" "$work/ssh-compteur" "$work/appels-docker"
    faux_docker; faux_ssh
    livre v1.2.3 "$nom="
    refus_sans_rien_envoyer 1 "sans $nom, rien ne part"
    assert_contains "$nom" "$err" "le message nomme la variable absente"
    # Le message affirmé est **celui de cette garde-ci**, et non celui du contrôle de forme qui
    # suit : les deux nomment la variable, et une assertion sur le seul nom aurait laissé la garde
    # de l'absence sans test, les gardes de forme la couvrant (point 9, mesuré par mutation).
    assert_contains "absente(s) de l'environnement" "$err" "c'est bien le refus de l'absence"
  done
}

case_ship_toutes_les_absences_dun_coup() {
  # Une CI mal configurée apprend d'un coup ce qui lui manque, au lieu d'un nom par exécution.
  faux_docker; faux_ssh
  livre v1.2.3 DEPLOY_HOST= DEPLOY_KNOWN_HOSTS=
  refus_sans_rien_envoyer 1 "deux variables absentes sont un refus"
  assert_contains "DEPLOY_HOST" "$err" "la première est nommée"
  assert_contains "DEPLOY_KNOWN_HOSTS" "$err" "la seconde aussi"
}

case_ship_host_qui_commence_par_un_tiret() {
  # « -E/tmp/journal » ou « -oProxyCommand=… » seraient lus par ssh comme des **options**, et la
  # destination viendrait alors d'ailleurs. Le refus a son propre message, pour ne pas faire chercher
  # une faute de frappe là où il y a une injection d'option.
  # La valeur choisie **passe le contrôle de format** : seule la garde du tiret peut la refuser.
  # Une valeur que le format rejetterait aussi n'aurait rien prouvé (point 9).
  faux_docker; faux_ssh
  livre v1.2.3 'DEPLOY_HOST=-E@journal'
  refus_sans_rien_envoyer 1 "une destination qui commence par un tiret est refusée"
  assert_contains "option" "$err" "le message dit pourquoi"
  [[ $err != *journal* ]] || { echo "la valeur de DEPLOY_HOST est apparue dans le message (NFR-9)" >&2; exit 1; }
}

case_ship_host_mal_forme() {
  local mauvais
  for mauvais in "serveur-sans-compte" "compte@" "@serveur" "compte@serveur avec espace" "compte@serveur;id"; do
    rm -rf "$work/bin" "$work/ssh-compteur" "$work/appels-docker"
    faux_docker; faux_ssh
    livre v1.2.3 "DEPLOY_HOST=$mauvais"
    refus_sans_rien_envoyer 1 "$(printf 'la destination %q est refusée' "$mauvais")"
    assert_contains "utilisateur@" "$err" "le message rappelle le format attendu"
  done
}

case_ship_cle_qui_nest_pas_une_cle_privee() {
  # L'erreur de configuration la plus plausible de la story 11.6 : la clé **publique** déposée dans
  # le secret. ssh échouerait alors à la connexion, après que « docker save » a commencé à couler.
  faux_docker; faux_ssh
  livre v1.2.3 'DEPLOY_SSH_KEY=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAUSSECLEPUBLIQUE compte'
  refus_sans_rien_envoyer 1 "une clé publique n'est pas une clé privée"
  assert_contains "DEPLOY_SSH_KEY" "$err" "le message nomme la variable"
}

case_ship_empreintes_sans_aucune_empreinte() {
  # Un fichier **présent mais vide** n'est pas une conformité (piège connu, story 0.8) : des
  # empreintes faites de commentaires donneraient un known_hosts valide et vide, et la vérification
  # stricte refuserait la connexion une fois l'archive en train de partir.
  faux_docker; faux_ssh
  livre v1.2.3 "$(printf 'DEPLOY_KNOWN_HOSTS=# rien que des commentaires\n\n   \n# encore')"
  refus_sans_rien_envoyer 1 "des empreintes sans empreinte sont un refus"
  assert_contains "aucune empreinte" "$err" "le message distingue « vide » de « absente »"
}

case_ship_check_env_ne_livre_rien() {
  # « --check-env » est ce que scripts/ci/release-job.sh appelle **avant** les dix minutes de
  # contrôles : il éprouve l'environnement et ne touche à rien.
  faux_docker; faux_ssh
  local -a variables=()
  mapfile -d '' -t variables < <(environnement)
  run env -i PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" bash "$script" --check-env
  assert_eq 0 "$rc" "un environnement complet passe (messages : $err)"
  ! ssh_lance || { echo "--check-env a lancé ssh" >&2; exit 1; }
  ! docker_a_sauvegarde || { echo "--check-env a lancé docker save" >&2; exit 1; }

  mapfile -d '' -t variables < <(environnement DEPLOY_HOST=)
  run env -i PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" bash "$script" --check-env
  assert_eq 1 "$rc" "un environnement incomplet est refusé"
  assert_contains "DEPLOY_HOST" "$err" "le message nomme la variable"
  assert_contains "absente(s) de l'environnement" "$err" "c'est bien le refus de l'absence"
}

# --- les outils et l'image -----------------------------------------------------------------------------

case_ship_image_absente() {
  # Refusée **avant** d'ouvrir le canal : sans cette garde, « docker save » échouerait une fois le
  # pipeline lancé, et le serveur recevrait un flux vide.
  faux_docker 0 1
  faux_ssh
  livre v1.2.3
  assert_eq 2 "$rc" "une image absente est une anomalie (messages : $err)"
  ! ssh_lance || { echo "ssh a été lancé alors que l'image n'existe pas" >&2; exit 1; }
  ! docker_a_sauvegarde || { echo "docker save a été lancé alors que l'image n'existe pas" >&2; exit 1; }
  assert_contains "eleyone-site:v1.2.3" "$err" "le message nomme l'image"
}

case_ship_outil_absent() {
  # Un PATH qui porte les outils du script mais ni docker ni ssh : « env -i PATH=/usr/bin » en
  # porterait peut-être.
  local outil chemin
  mkdir -p "$work/outils"
  for outil in bash dirname mktemp rm find gzip; do
    chemin=$(command -v "$outil") || { echo "outil introuvable : $outil" >&2; exit 2; }
    ln -sf "$chemin" "$work/outils/$outil"
  done
  local -a variables=()
  mapfile -d '' -t variables < <(environnement)
  run env -i PATH="$work/outils" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" bash "$script" v1.2.3
  assert_eq 2 "$rc" "un outil absent est une anomalie (messages : $err)"
  assert_contains "introuvable" "$err" "le message le dit"
}

# --- le pipeline, cœur de cette story ---------------------------------------------------------------------

# « docker save | gzip | ssh » est un pipeline de trois commandes. Le projet s'est déjà fait mordre
# deux fois par leurs codes de retour (docs/procedures/shell-scripts.md). Ces trois cas exercent
# chacun des trois éléments en échec : c'est **l'entrée que la garde doit refuser** (point 9).
case_ship_docker_save_en_echec() {
  # Le pire résultat possible de cette story : une archive tronquée livrée en production. Le faux
  # docker écrit quelques octets puis échoue, le faux ssh accepte tout et rend 0.
  faux_docker 1
  faux_ssh
  livre v1.2.3
  ((rc != 0)) || { printf 'ship.sh a rendu 0 alors que docker save a échoué (archive tronquée).\nsortie : %s\n' "$out" >&2; exit 1; }
  assert_eq 2 "$rc" "un « docker save » en échec est une anomalie (messages : $err)"
  assert_contains "docker save" "$err" "le message nomme l'élément fautif"
  assert_contains "tronquée" "$err" "et dit ce que le serveur a reçu"
  # La confirmation ne part pas : la chaîne s'arrête à la première étape en échec.
  assert_eq 1 "$(nombre_ssh)" "aucun status après une livraison en échec"
}

case_ship_gzip_en_echec() {
  faux_docker; faux_ssh; faux_gzip 1
  livre v1.2.3
  ((rc != 0)) || { echo "ship.sh a rendu 0 alors que gzip a échoué" >&2; exit 1; }
  assert_eq 2 "$rc" "un « gzip » en échec est une anomalie (messages : $err)"
  assert_contains "gzip" "$err" "le message nomme l'élément fautif"
}

case_ship_ssh_en_echec() {
  # Trois codes, trois lectures : 1 est le refus du serveur (deploy-site), le reste est une anomalie
  # du transport — 255 est ce que rend ssh quand il ne se connecte pas.
  local couple code_distant code_attendu
  for couple in "1:1" "2:2" "255:2"; do
    code_distant=${couple%%:*}
    code_attendu=${couple#*:}
    rm -rf "$work/bin" "$work/ssh-compteur" "$work/ssh-commandes" "$work/appels-docker" "$work/ssh-code.1"
    faux_docker; faux_ssh
    code_ssh 1 "$code_distant"
    livre v1.2.3
    assert_eq "$code_attendu" "$rc" "ssh code $code_distant donne $code_attendu (messages : $err)"
    assert_eq 1 "$(nombre_ssh)" "aucun status après une livraison en échec (code $code_distant)"
  done
}

# Un ssh qui s'arrête ferme le tube, et « docker save » meurt alors d'un SIGPIPE : les deux éléments
# rendent un code non nul, mais la cause est **en aval**. Ce cas fixe l'ordre de lecture — sans lui,
# le message accuserait l'exportation de l'image là où le transport a lâché.
case_ship_ssh_en_echec_avec_amont_en_sigpipe() {
  faux_docker 141
  faux_ssh
  code_ssh 1 255
  livre v1.2.3
  assert_eq 2 "$rc" "la livraison échoue (messages : $err)"
  assert_contains "la livraison par ssh a échoué (code 255)" "$err" "le message nomme le transport, la vraie cause"
  assert_contains "amont du tube a lâché aussi" "$err" "et cite l'amont en conséquence, pas en panne"
  # Et le message de l'archive tronquée, lui, ne sort **que** quand ssh a rendu 0 : l'employer ici
  # ferait chercher une panne d'exportation.
  [[ $err != *"l'archive envoyée est tronquée"* ]] \
    || { echo "le message d'archive tronquée sort alors que ssh a lâché" >&2; exit 1; }
}

case_ship_status_en_echec() {
  # La livraison est passée, mais l'état du serveur n'a pas pu être lu : le job ne passe pas au vert
  # sur une confirmation muette.
  faux_docker; faux_ssh
  code_ssh 2 1
  livre v1.2.3
  assert_eq 2 "$rc" "un status muet est une anomalie (messages : $err)"
  assert_contains "status" "$err" "le message le dit"
}

case_ship_pipefail_declare() {
  # Le code d'un pipeline est celui de sa **dernière** commande : sans pipefail, l'échec de
  # « docker save » serait masqué par un ssh à 0. La lecture de PIPESTATUS le rattrape déjà — les cas
  # ci-dessus le prouvent —, mais la règle du projet reste « set -euo pipefail » en tête.
  local entete
  shell_grep_into entete -nE '^set -euo pipefail$' "$script"
  [[ -n $entete ]] || { echo "set -euo pipefail absent de l'en-tête de ship.sh" >&2; exit 1; }
}

# --- les temporaires et les secrets ------------------------------------------------------------------------

case_ship_les_temporaires_disparaissent() {
  faux_docker; faux_ssh
  livre v1.2.3
  assert_eq 0 "$rc" "la livraison passe (messages : $err)"
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste après un succès"
}

case_ship_les_temporaires_disparaissent_apres_un_echec() {
  # **La raison pour laquelle ship.sh n'emploie pas « exec »** : « exec » remplace le processus, et
  # le piège EXIT ne tournerait jamais. La **clé privée** resterait sur le disque du runner. Ce cas
  # échoue si quelqu'un introduit un « exec ».
  faux_docker; faux_ssh
  code_ssh 1 2
  livre v1.2.3
  assert_eq 2 "$rc" "une livraison en échec se voit (messages : $err)"
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste après un échec"
}

case_ship_aucun_exec() {
  local exec_trouve
  shell_grep_into exec_trouve -nE '^[[:space:]]*exec[[:space:]]' "$script"
  assert_eq "" "$exec_trouve" "aucun « exec » : il remplacerait le processus et le piège EXIT ne tournerait jamais"
}

case_ship_la_cle_nest_lisible_que_par_son_proprietaire() {
  # « umask 077 » en tête : ssh refuse une clé trop ouverte, et une clé privée lisible par tout le
  # monde sur un runner partagé est exactement ce que ce montage existe pour empêcher.
  faux_docker; faux_ssh
  livre v1.2.3
  assert_eq 0 "$rc" "la livraison passe (messages : $err)"
  local droits
  droits=$(head -n 1 "$work/ssh-droits-cle")
  assert_eq "-rw-------" "$droits" "le fichier de clé n'est lisible que par son propriétaire"
}

case_ship_la_cle_et_les_empreintes_sont_celles_de_lenvironnement() {
  faux_docker; faux_ssh
  livre v1.2.3
  assert_eq 0 "$rc" "la livraison passe (messages : $err)"
  assert_contains "FAUSSECLEDESSAI" "$(cat "$work/ssh-cle.1")" "la clé écrite est celle du secret"
  assert_contains "FAUSSEEMPREINTE" "$(cat "$work/ssh-connus.1")" "les empreintes écrites sont celles du secret"
  # Le saut de ligne final : OpenSSH refuse une clé qui n'en a pas, et un secret saisi à la main en
  # manque souvent.
  local dernier
  dernier=$(tail -c 1 "$work/ssh-cle.1" | od -An -c | tr -d ' ')
  assert_eq '\n' "$dernier" "la clé écrite se termine par un saut de ligne"
}

case_ship_les_options_ssh() {
  faux_docker; faux_ssh
  livre v1.2.3
  assert_eq 0 "$rc" "la livraison passe (messages : $err)"
  local ligne
  ligne=$(head -n 1 "$work/ssh-args")
  assert_contains "-o StrictHostKeyChecking=yes" "$ligne" "l'empreinte de l'hôte est vérifiée strictement"
  assert_contains "-o UserKnownHostsFile=$work/tmp-a-soi/" "$ligne" "les empreintes sont celles du temporaire, pas celles du compte du runner"
  assert_contains "-o IdentitiesOnly=yes" "$ligne" "seule la clé donnée est proposée"
  assert_contains "-o BatchMode=yes" "$ligne" "aucune question interactive ne peut bloquer le job"
  assert_contains "-i $work/tmp-a-soi/" "$ligne" "la clé est le temporaire du script"
  # Les mêmes options pour la confirmation : un status qui partirait sans vérification d'hôte
  # ouvrirait le même trou que la livraison.
  local ligne_status
  ligne_status=$(sed -n '2p' "$work/ssh-args")
  assert_contains "-o StrictHostKeyChecking=yes" "$ligne_status" "status part avec les mêmes options"
  assert_contains "-o BatchMode=yes" "$ligne_status" "status aussi"
}

case_ship_aucune_valeur_dans_les_messages() {
  # Le journal d'une CI se lit. Un message nomme la variable, jamais son contenu (NFR-9).
  faux_docker 1
  faux_ssh
  local marqueur=CHAINE-QUI-NE-DOIT-PAS-SORTIR
  livre v1.2.3 \
    "DEPLOY_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
$marqueur
-----END OPENSSH PRIVATE KEY-----" \
    "DEPLOY_HOST=compte-$marqueur@serveur-$marqueur" \
    "DEPLOY_KNOWN_HOSTS=serveur $marqueur"
  [[ $out != *"$marqueur"* ]] || { echo "une valeur de secret est apparue sur la sortie standard" >&2; exit 1; }
  [[ $err != *"$marqueur"* ]] || { echo "une valeur de secret est apparue sur la sortie d'erreur" >&2; exit 1; }
}

case_ship_aucune_trace_de_shell() {
  # « set +x » dès l'en-tête : même lancé avec « bash -x », le script n'écrit pas la clé privée dans
  # le journal. Le cas le **lance** ainsi plutôt que de relire le fichier.
  faux_docker; faux_ssh
  local marqueur=CHAINE-QUI-NE-DOIT-PAS-SORTIR
  local -a variables=()
  mapfile -d '' -t variables < <(environnement \
    "DEPLOY_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
$marqueur
-----END OPENSSH PRIVATE KEY-----" \
    "DEPLOY_KNOWN_HOSTS=serveur $marqueur")
  run env -i PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" bash -x "$script" v1.2.3
  assert_eq 0 "$rc" "la livraison passe sous bash -x (messages : $err)"
  [[ $err != *"$marqueur"* ]] || { echo "bash -x a écrit la clé privée dans la trace" >&2; exit 1; }
  [[ $out != *"$marqueur"* ]] || { echo "bash -x a écrit la clé privée sur la sortie standard" >&2; exit 1; }
  # Et le script ne rallume jamais la trace de lui-même.
  local rallumage
  shell_grep_into rallumage -nE '^[[:space:]]*set[[:space:]]+-[a-z]*x' "$script"
  assert_eq "" "$rallumage" "aucun « set -x » dans le script"
}

case_ship_usage() {
  faux_docker; faux_ssh
  local -a variables=()
  mapfile -d '' -t variables < <(environnement)
  run env -i PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" bash "$script"
  assert_eq 2 "$rc" "sans tag, c'est une anomalie d'usage"
  assert_contains "usage" "$err" "le message le dit"
  ! ssh_lance || { echo "ssh a été lancé sans tag" >&2; exit 1; }
}

# --- ce que le dépôt ne doit pas porter -----------------------------------------------------------------------

# NFR-9 : rien de ce qui désigne le serveur n'entre dans le dépôt — ni adresse, ni nom de compte, ni
# dans un exemple, ni dans un commentaire, ni dans la procédure. La seule adresse admise est la
# boucle locale, qui ne désigne aucune machine en particulier, comme dans test-deploy-site.sh.
#
# Le motif des comptes exige un **domaine pointé** après le « @ » : « compte@serveur.exemple.net » est
# refusé, le gabarit « utilisateur@hôte » de la procédure ne l'est pas. Écrire la classe de façon à
# s'arrêter sur le « ô » aurait été plus strict, mais le verdict aurait alors dépendu de la machine :
# mesuré le 25/09/2026, le grep du poste (ugrep 7.8.4) fait entrer les octets de « ô » dans
# « [A-Za-z0-9._-] », là où le grep GNU de CHECK_IMAGE s'arrête avant — et un cas ne doit jamais
# rendre deux verdicts selon l'endroit où la suite tourne (piège connu, shell-scripts.md). Le motif
# ci-dessous donne le même résultat des deux côtés. Ce qu'il ne voit pas — un nom de serveur sans
# point — est couvert par la relecture, pas par ce cas.
fichiers_de_la_story() {
  printf '%s\n' \
    "$root/scripts/release/ship.sh" \
    "$root/scripts/ci/release-job.sh" \
    "$root/.gitea/workflows/release.yaml" \
    "$root/docs/procedures/release-workflow.md"
}

case_ship_aucune_adresse() {
  local fichier trouve ligne
  while IFS= read -r fichier; do
    [[ -f $fichier ]] || { printf 'fichier de la story absent : %s\n' "$fichier" >&2; exit 1; }
    shell_grep_into trouve -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$fichier"
    while IFS= read -r ligne; do
      [[ -n $ligne ]] || continue
      [[ $ligne == 127.0.0.1 ]] \
        || { printf 'adresse IP dans %s (NFR-9)\n' "$fichier" >&2; exit 1; }
    done <<< "$trouve"
  done <<< "$(fichiers_de_la_story)"
}

case_ship_aucun_nom_de_compte() {
  local fichier trouve ligne
  while IFS= read -r fichier; do
    shell_grep_into trouve -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z0-9.-]+' "$fichier"
    while IFS= read -r ligne; do
      [[ -n $ligne ]] || continue
      printf 'compte@serveur écrit en clair dans %s (NFR-9) : %s\n' "$fichier" "$ligne" >&2
      exit 1
    done <<< "$trouve"
  done <<< "$(fichiers_de_la_story)"
}

# Le nom du dépôt d'images vit à trois endroits qui ne peuvent pas lire une source commune :
# scripts/release/build-image.sh le construit, scripts/release/ship.sh l'exporte, et
# deploy/remote/deploy-site.sh le charge — ce dernier est recopié **seul** sur le serveur et ne
# charge aucune bibliothèque du dépôt. Faute de source unique, c'est ce cas qui les tient égaux
# (point 19 d'AGENTS.md : deux copies avaient laissé un fichier passer devant C20).
case_ship_meme_depot_dimages_partout() {
  local ici la_bas
  shell_grep_into ici -oE '^depot_image=.+$' "$script"
  shell_grep_into la_bas -oE '^depot_image=.+$' "$root/deploy/remote/deploy-site.sh"
  [[ -n $ici ]] || { echo "depot_image introuvable dans ship.sh" >&2; exit 1; }
  assert_eq "$la_bas" "$ici" "ship.sh et deploy-site.sh nomment le même dépôt d'images"
  local nom=${ici#depot_image=}
  local construit
  shell_grep_into construit -oF "$nom:\$tag" "$root/scripts/release/build-image.sh"
  [[ -n $construit ]] \
    || { printf 'scripts/release/build-image.sh ne construit pas %s:$tag\n' "$nom" >&2; exit 1; }
}

run_case "$@"
