#!/usr/bin/env bash
# Commande forcée du serveur de production (story 11.4, AD-14, AD-15, AD-22) : ce qu'elle refuse, ce
# qu'elle lance, et ce qu'elle ne lance pas. **Aucun cas ne lance Docker** : un faux « docker » est
# posé en tête de PATH et enregistre ses appels, exactement comme scripts/tests/test-build-image.sh
# le fait depuis la story 4.1. La suite reste hors ligne (story 0.9). La chaîne réelle est éprouvée
# sur le serveur par les stories 11.5 et 11.6.
#
# **Point 19 d'AGENTS.md — l'aîné et ses gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-release-build-image.sh, lui-même écrit comme test-build-image.sh. Gardes
# reprises : le faux docker en tête de PATH ; l'affirmation du code de sortie **avant** de compter
# quoi que ce soit ; la vérification que docker n'a **pas** été lancé après un refus ; un
# environnement réduit (« env -i ») pour qu'un cas rende le même verdict sur le poste et en CI ; un
# TMPDIR qui n'appartient qu'au cas. Garde ajoutée ici, qu'aucun aîné n'avait : un faux « rm » et un
# faux « id » en tête de PATH, qui prouvent qu'une demande hostile n'a lancé **aucune** commande — et
# qui, accessoirement, empêchent la suite elle-même de jouer un « rm -rf / ». Le tableau complet est
# dans le fichier de story.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

script=$root/deploy/remote/deploy-site.sh
compose_production=$root/deploy/compose.yaml
compose_repetition=$root/deploy/compose.rehearsal.yaml

# Le faux docker écrit une ligne par appel : les arguments, puis la valeur de SITE_TAG dans son
# environnement — c'est le seul moyen de voir que la variable est bien posée pour « compose up » et
# pour lui seul. Les sorties et les codes se règlent par sous-commande, dans $work/sorties et
# $work/codes, parce que « image inspect » et « image ls » doivent pouvoir répondre différemment.
faux_docker() {
  mkdir -p "$work/bin" "$work/sorties" "$work/codes"
  {
    printf '#!/bin/sh\n'
    printf 'appels="%s"\n' "$work/appels"
    printf 'sorties="%s"\n' "$work/sorties"
    printf 'codes="%s"\n' "$work/codes"
    cat <<'FAUX'
printf '%s | SITE_TAG=%s\n' "$*" "${SITE_TAG-}" >> "$appels"
case "$1 $2" in
  "image inspect") cle=image-inspect ;;
  "image ls")      cle=image-ls ;;
  "image rm")      cle=image-rm ;;
  *)               cle=$1 ;;
esac
if [ -f "$sorties/$cle" ]; then cat "$sorties/$cle"; fi
if [ -f "$codes/$cle" ]; then exit "$(cat "$codes/$cle")"; fi
exit 0
FAUX
  } > "$work/bin/docker"
  chmod +x "$work/bin/docker"
}

sortie_docker() { # $1 = clé de sous-commande, $2 = ce que le faux docker imprime
  mkdir -p "$work/sorties"
  printf '%s' "$2" > "$work/sorties/$1"
}

code_docker() { # $1 = clé de sous-commande, $2 = code de sortie
  mkdir -p "$work/codes"
  printf '%s' "$2" > "$work/codes/$1"
}

# Un faux « rm » et un faux « id », qui n'effacent rien et n'apprennent rien : ils enregistrent leurs
# arguments. Une demande hostile qui parviendrait à lancer une seconde commande laisserait sa trace
# ici. Le faux « rm » sert deux fois : il est aussi ce qui empêche un « rm -rf / » d'exister
# réellement pendant la suite, si jamais la garde du script venait à tomber.
faux_temoin() { # $1 = commande espionnée
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$*" >> "%s/temoins-%s"\n' "$work" "$1"
    printf 'exit 0\n'
  } > "$work/bin/$1"
  chmod +x "$work/bin/$1"
}

temoin_lignes() { # $1 = commande espionnée ; affiche ce qu'elle a reçu
  [[ -f $work/temoins-$1 ]] && cat "$work/temoins-$1"
  return 0
}

appels() { [[ -f $work/appels ]] && cat "$work/appels"; return 0; }
docker_lance() { [[ -f $work/appels ]]; }

refus_sans_docker() { # $1 = code attendu, $2 = libellé
  assert_eq "$1" "$rc" "$2 (messages : $err)"
  ! docker_lance || { printf 'docker a été lancé malgré le refus : %s\n' "$(appels)" >&2; exit 1; }
}

# L'entrée standard de la commande. Par défaut vide : seule une demande « deploy » a une archive.
entree=/dev/null

demande() { # $1 = contenu de SSH_ORIGINAL_COMMAND ; $2 = chemin du script, par défaut celui du dépôt
  mkdir -p "$work/tmp"
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work/tmp" \
    SSH_ORIGINAL_COMMAND="$1" bash "${2:-$script}" < "$entree"
}

archive() { # une fausse archive, pour que l'entrée standard ne soit pas vide
  printf 'ceci-n-est-pas-un-tar\n' > "$work/archive.tgz"
  entree=$work/archive.tgz
}

# Un PATH qui porte les outils du script mais pas docker : « env -i PATH=/usr/bin » en porterait un.
path_sans_docker() {
  local outil chemin
  mkdir -p "$work/outils"
  for outil in bash dirname mktemp head cat rm; do
    chemin=$(command -v "$outil") || { echo "outil introuvable : $outil" >&2; exit 2; }
    ln -sf "$chemin" "$work/outils/$outil"
  done
  printf '%s' "$work/outils"
}

# --- la demande elle-même -------------------------------------------------------------------------

case_deploy_site_sans_demande() {
  faux_docker
  mkdir -p "$work/tmp"
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work/tmp" bash "$script" < /dev/null
  refus_sans_docker 1 "une session sans demande est refusée"
  assert_contains "aucune demande" "$err" "le message dit que la clé n'ouvre pas de session"
}

case_deploy_site_demande_vide() {
  faux_docker
  demande "   "
  refus_sans_docker 1 "une demande faite d'espaces est refusée"
}

case_deploy_site_demandes_inconnues() {
  faux_docker
  local mauvaise
  for mauvaise in "bidule" "deploy-site" "rehearse" "rehearse bidule" "status deploy" "DEPLOY v1.0.0"; do
    demande "$mauvaise"
    refus_sans_docker 1 "« $mauvaise » est refusée"
  done
}

case_deploy_site_arguments_en_trop() {
  faux_docker
  local mauvaise
  for mauvaise in "deploy v1.0.0 autre-chose" "rollback v1.0.0 v1.0.1" \
    "rehearse deploy v1.0.0-rc.1 encore" "rehearse stop v1.0.0-rc.1" "status quoi"; do
    demande "$mauvaise"
    refus_sans_docker 1 "« $mauvaise » est refusée"
    assert_contains "attend" "$err" "le message dit ce qui était attendu"
  done
}

# Le mot de trop vient du réseau : il ne doit pas revenir brut dans le message. « status » est le
# seul cas où il se glisse à côté d'une commande valide.
case_deploy_site_argument_en_trop_non_recopie() {
  faux_docker
  demande "status $(printf 'sale\033[31m')"
  refus_sans_docker 1 "un argument de trop après status est refusé"
  [[ $err != *$'\033'* ]] || { echo "le message a recopié un octet de contrôle venu du réseau" >&2; exit 1; }
}

# Le **nom de la commande** revient lui aussi dans le message, et c'est le chemin le plus direct vers
# « visible() » : contrairement au tag, il n'est filtré par aucune expression avant d'y arriver — une
# demande inconnue est refusée *parce qu'*elle est inconnue, quel que soit ce qu'elle contient. Ce cas
# lui donne donc la charge complète, métacaractères shell compris, là où
# « case_deploy_site_argument_en_trop_non_recopie » n'éprouve qu'un octet de contrôle après une
# commande valide (constat de la revue du code de la PR n° 119).
case_deploy_site_nom_de_commande_hostile_cite() {
  faux_docker
  demande '$(id)`whoami`;rm -rf /'
  refus_sans_docker 1 "un nom de commande portant des métacaractères est refusé"
  assert_contains "demande inconnue" "$err" "le refus nomme la cause"
  # Cité par « printf %q » : le dollar, les parenthèses, l'accent grave et le point-virgule y sont
  # tous échappés. Sans « visible() », le message les recopierait tels quels dans le journal du job.
  assert_contains '\$\(id\)' "$err" "le nom hostile est cité, jamais recopié brut"
  [[ $err != *'$(id) '* ]] || { echo "le message a recopié une substitution de commande" >&2; exit 1; }
}

# Le tag vient du réseau et revient dans le message de refus : il y passe par « printf %q », sans
# quoi un octet de contrôle irait tel quel dans le journal du job qui a lancé la demande.
case_deploy_site_tag_hostile_cite() {
  faux_docker
  demande "deploy $(printf 'v1.0.0\033[31m')"
  refus_sans_docker 1 "un tag portant un octet de contrôle est refusé"
  [[ $err != *$'\033'* ]] || { echo "le message a recopié un octet de contrôle venu du réseau" >&2; exit 1; }
  assert_contains "v1.0.0" "$err" "le tag reste lisible, cité"
}

# La trace du shell est coupée en tête : lancé « bash -x » pour être débogué sur le serveur, le
# script ne doit pas écrire les chemins d'installation — donc le nom du compte — dans une sortie qui
# repart par SSH.
case_deploy_site_trace_coupee() {
  faux_docker
  mkdir -p "$work/tmp"
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work/tmp" \
    SSH_ORIGINAL_COMMAND="status" bash -x "$script" < /dev/null
  assert_eq 0 "$rc" "status passe (messages : $err)"
  [[ $err != *"+ docker"* ]] || { echo "la trace du shell n'est pas coupée" >&2; exit 1; }
}

# --- les demandes hostiles ------------------------------------------------------------------------

case_deploy_site_injection_point_virgule() {
  faux_docker
  faux_temoin rm
  faux_temoin id
  demande "deploy v1.0.0; rm -rf /"
  refus_sans_docker 1 "« deploy v1.0.0; rm -rf / » est refusée"
  # Le script efface son propre dossier temporaire en sortant : le faux rm voit donc un appel
  # légitime. Ce qui ne doit exister nulle part, c'est l'appel demandé par la chaîne hostile.
  local vu
  shell_grep_into vu -Fx -- '-rf /' <<< "$(temoin_lignes rm)"
  assert_eq "" "$vu" "aucun « rm -rf / » n'a été lancé"
  assert_eq "" "$(temoin_lignes id)" "aucune autre commande n'a été lancée"
}

case_deploy_site_injection_substitution() {
  faux_docker
  faux_temoin rm
  faux_temoin id
  # Entre apostrophes : c'est le shell du serveur qui ne doit pas relire « $(id) », pas celui du test.
  demande 'deploy $(id)'
  refus_sans_docker 1 "« deploy $(printf '$')(id) » est refusée"
  assert_eq "" "$(temoin_lignes id)" "« id » n'a pas été exécuté"
  assert_contains "refusé" "$err" "le message parle d'un tag refusé"
}

# Le développement des globs est coupé (set -f) **avant** le découpage. Sans cette ligne, « v1.2.* »
# se développerait sur le disque du serveur : le dossier ci-dessous contient exactement un fichier
# nommé « v1.2.3 », donc la demande deviendrait un déploiement valide que personne n'a demandé.
case_deploy_site_globs_coupes() {
  faux_docker
  mkdir -p "$work/glob" "$work/tmp"
  : > "$work/glob/v1.2.3"
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work/tmp" \
    SSH_ORIGINAL_COMMAND='deploy v1.2.*' \
    bash -c 'cd "$1" || exit 9; exec bash "$2"' bash "$work/glob" "$script" < /dev/null
  refus_sans_docker 1 "un motif de glob n'est pas développé"
  assert_contains "refusé" "$err" "il est lu comme un tag, et refusé comme tel"
}

# --- les tags -------------------------------------------------------------------------------------

case_deploy_site_tags_malformes() {
  faux_docker
  local mauvais
  for mauvais in "v1.2" "v1.2.3.4" "v01.2.3" "v1.02.3" "v1.2.03" "1.2.3" "vX.Y.Z" \
    "v1.2.3x" "xv1.2.3" "v1.2.3-rc" "v1.2.3-rc.x" "v1.2.3-rc.01" "v1.2.3;" "latest"; do
    demande "deploy $mauvais"
    refus_sans_docker 1 "le tag « $mauvais » est refusé en production"
    demande "rehearse deploy $mauvais"
    refus_sans_docker 1 "le tag « $mauvais » est refusé en répétition"
  done
  # Et la forme juste passe, sans quoi la garde ne prouverait rien : un « refuse tout » refuserait
  # aussi les tags corrects (point 11 — éprouver le cas court **et** le cas long).
  sortie_docker load "Loaded image: eleyone-site:v0.0.0
"
  archive
  demande "deploy v0.0.0"
  assert_eq 0 "$rc" "le tag minimal passe (messages : $err)"
}

# Première des trois gardes contre le croisement des canaux (constat S2) : un tag -rc en production.
case_deploy_site_tag_rc_en_production() {
  faux_docker
  archive
  demande "deploy v1.2.3-rc.1"
  refus_sans_docker 1 "un tag -rc est refusé en production"
  assert_contains "répétition" "$err" "le message nomme le canal auquel ce tag appartient"
  demande "rollback v1.2.3-rc.1"
  refus_sans_docker 1 "un rollback de production refuse aussi un tag -rc"
}

# Deuxième garde : un tag sans -rc en répétition.
case_deploy_site_tag_de_production_en_repetition() {
  faux_docker
  archive
  demande "rehearse deploy v1.2.3"
  refus_sans_docker 1 "un tag sans -rc est refusé en répétition"
  assert_contains "production" "$err" "le message nomme le canal auquel ce tag appartient"
  demande "rehearse rollback v1.2.3"
  refus_sans_docker 1 "un rollback de répétition refuse aussi un tag de production"
}

# --- deploy ------------------------------------------------------------------------------------------

case_deploy_site_deploy_nominal() {
  faux_docker
  sortie_docker load "Loaded image: eleyone-site:v1.2.3
"
  sortie_docker image-ls "v1.2.3
"
  archive
  demande "deploy v1.2.3"
  assert_eq 0 "$rc" "le déploiement passe (messages : $err)"
  local vus
  vus=$(appels)
  assert_contains "load | SITE_TAG=" "$vus" "l'archive est lue sur l'entrée standard"
  assert_contains "compose --project-name site -f $compose_production up -d | SITE_TAG=v1.2.3" "$vus" \
    "le service de production repart avec SITE_TAG posée"
}

# Troisième garde contre le croisement des canaux (constat S2) : le nom de l'image chargée.
case_deploy_site_image_mal_nommee() {
  faux_docker
  sortie_docker load "Loaded image: autre-site:v1.2.3
"
  archive
  demande "deploy v1.2.3"
  assert_eq 1 "$rc" "une image au mauvais nom est refusée (messages : $err)"
  assert_contains "autre-site:v1.2.3" "$err" "le message nomme l'image trouvée"
  local vus
  vus=$(appels)
  [[ $vus != *"up -d"* ]] || { echo "le service a été relancé malgré le refus" >&2; exit 1; }
}

case_deploy_site_archive_a_plusieurs_images() {
  faux_docker
  sortie_docker load "Loaded image: eleyone-site:v1.2.3
Loaded image: autre-site:v1.2.3
"
  archive
  demande "deploy v1.2.3"
  assert_eq 1 "$rc" "une archive à deux images est refusée (messages : $err)"
  local vus
  vus=$(appels)
  [[ $vus != *"up -d"* ]] || { echo "le service a été relancé malgré le refus" >&2; exit 1; }
}

# « docker load » d'une image sauvegardée sans nom imprime « Loaded image ID: sha256:… ». Rien ne
# permet alors de dire que c'est la bonne image : c'est un refus, pas un cas nominal silencieux.
case_deploy_site_image_sans_nom() {
  faux_docker
  sortie_docker load "Loaded image ID: sha256:0123456789abcdef
"
  archive
  demande "deploy v1.2.3"
  assert_eq 1 "$rc" "une image sans nom est refusée (messages : $err)"
}

# La sortie de « docker load » vient de l'archive : le nom d'image qu'elle imprime est écrit par
# l'émetteur. Elle est affichée citée, ligne à ligne, comme le tag.
case_deploy_site_sortie_de_load_citee() {
  faux_docker
  sortie_docker load $'Loaded image: eleyone-site:v1.2.3\nLoaded image: \033[31mautre:v1.2.3\n' 
  archive
  demande "deploy v1.2.3"
  assert_eq 1 "$rc" "une archive à deux images est refusée (messages : $err)"
  [[ $err != *$'\033'* ]] || { echo "la sortie de docker load a été affichée brute" >&2; exit 1; }
  assert_contains "autre:v1.2.3" "$err" "le nom reste lisible, cité"
}

# « docker load » finit ses lignes par un saut de ligne, mais une lecture qui compte dessus perd le
# dernier élément de toute sortie qui n'en met pas — ici, la seconde image, celle qui fait le refus.
case_deploy_site_derniere_ligne_sans_saut() {
  faux_docker
  sortie_docker load $'Loaded image: eleyone-site:v1.2.3\nLoaded image: autre:v1.2.3'
  archive
  demande "deploy v1.2.3"
  assert_eq 1 "$rc" "la seconde image est vue même sans saut de ligne final (messages : $err)"
  local vus
  vus=$(appels)
  [[ $vus != *"up -d"* ]] || { echo "le service a été relancé malgré la seconde image" >&2; exit 1; }
}

case_deploy_site_load_en_echec() {
  faux_docker
  code_docker load 1
  archive
  demande "deploy v1.2.3"
  assert_eq 1 "$rc" "une archive illisible est un refus (messages : $err)"
  local vus
  vus=$(appels)
  [[ $vus != *"up -d"* ]] || { echo "le service a été relancé après un load en échec" >&2; exit 1; }
}

case_deploy_site_mise_en_service_en_echec() {
  faux_docker
  sortie_docker load "Loaded image: eleyone-site:v1.2.3
"
  code_docker compose 1
  archive
  demande "deploy v1.2.3"
  assert_eq 2 "$rc" "un « compose up » en échec est une anomalie (messages : $err)"
}

# --- rétention ------------------------------------------------------------------------------------------

case_deploy_site_retention_garde_trois_images() {
  faux_docker
  sortie_docker load "Loaded image: eleyone-site:v2.0.0
"
  # « docker image ls » trie de la plus récente à la plus ancienne.
  sortie_docker image-ls "v2.0.0
v1.9.0
v1.8.0
v1.7.0
v1.6.0
v1.5.0-rc.1
<none>
"
  archive
  demande "deploy v2.0.0"
  assert_eq 0 "$rc" "le déploiement passe (messages : $err)"
  local vus
  vus=$(appels)
  assert_contains "image rm eleyone-site:v1.7.0 |" "$vus" "la quatrième image de production part"
  assert_contains "image rm eleyone-site:v1.6.0 |" "$vus" "la cinquième aussi"
  local gardee
  for gardee in v2.0.0 v1.9.0 v1.8.0; do
    [[ $vus != *"image rm eleyone-site:$gardee |"* ]] \
      || { echo "l'image $gardee, dans les trois plus récentes, a été supprimée" >&2; exit 1; }
  done
  # Les images -rc ne sont pas soumises à la rétention des trois (constat S3), et un tag que ce
  # script ne sait pas nommer n'est pas de son ressort.
  [[ $vus != *"image rm eleyone-site:v1.5.0-rc.1 |"* ]] \
    || { echo "une image -rc a été prise dans la rétention de la production" >&2; exit 1; }
  [[ $vus != *"image rm eleyone-site:<none> |"* ]] \
    || { echo "une image sans tag a été supprimée" >&2; exit 1; }
}

# Redéployer un tag ancien : « docker image ls » trie par date de construction, donc ce tag n'est pas
# dans les trois plus récents. Le supprimer reviendrait à effacer l'image qu'on vient de mettre en
# service.
case_deploy_site_retention_epargne_le_tag_en_service() {
  faux_docker
  sortie_docker load "Loaded image: eleyone-site:v0.9.0
"
  sortie_docker image-ls "v3.0.0
v2.0.0
v1.0.0
v0.9.0
"
  archive
  demande "deploy v0.9.0"
  assert_eq 0 "$rc" "le déploiement passe (messages : $err)"
  local vus
  vus=$(appels)
  [[ $vus != *"image rm eleyone-site:v0.9.0 |"* ]] \
    || { echo "l'image qu'on vient de mettre en service a été supprimée" >&2; exit 1; }
}

case_deploy_site_retention_en_echec_est_une_anomalie() {
  faux_docker
  sortie_docker load "Loaded image: eleyone-site:v2.0.0
"
  sortie_docker image-ls "v2.0.0
v1.9.0
v1.8.0
v1.7.0
"
  code_docker image-rm 1
  archive
  demande "deploy v2.0.0"
  assert_eq 2 "$rc" "une suppression impossible est une anomalie, pas un silence (messages : $err)"
  assert_contains "suppression impossible" "$err" "le message nomme ce qui n'a pas pu être supprimé"
}

# --- rollback ---------------------------------------------------------------------------------------------

case_deploy_site_rollback_nominal() {
  faux_docker
  archive # l'entrée standard porte quelque chose : rollback ne doit rien en lire
  demande "rollback v1.2.3"
  assert_eq 0 "$rc" "le retour arrière passe (messages : $err)"
  local vus
  vus=$(appels)
  assert_contains "image inspect eleyone-site:v1.2.3" "$vus" "l'image est vérifiée présente"
  assert_contains "compose --project-name site -f $compose_production up -d | SITE_TAG=v1.2.3" "$vus" \
    "le service repart sur l'image déjà présente"
  [[ $vus != *"load |"* ]] || { echo "rollback a lu l'entrée standard" >&2; exit 1; }
  # Et aucune rétention : rollback ne construit rien, il ne fait pas le ménage non plus.
  [[ $vus != *"image ls"* ]] || { echo "rollback a lancé la rétention" >&2; exit 1; }
}

case_deploy_site_rollback_image_absente() {
  faux_docker
  code_docker image-inspect 1
  demande "rollback v1.2.3"
  assert_eq 1 "$rc" "un retour arrière sur une image absente est refusé (messages : $err)"
  assert_contains "absente" "$err" "le message le dit"
  local vus
  vus=$(appels)
  [[ $vus != *"up -d"* ]] || { echo "le service a été relancé sur une image absente" >&2; exit 1; }
}

# --- canal de répétition -------------------------------------------------------------------------------------

case_deploy_site_rehearse_deploy_nominal() {
  faux_docker
  sortie_docker load "Loaded image: eleyone-site:v1.2.3-rc.1
"
  archive
  demande "rehearse deploy v1.2.3-rc.1"
  assert_eq 0 "$rc" "la répétition démarre (messages : $err)"
  local vus
  vus=$(appels)
  assert_contains "load | SITE_TAG=" "$vus" "l'archive est lue sur l'entrée standard"
  assert_contains "compose --project-name site-rehearsal -f $compose_repetition up -d | SITE_TAG=v1.2.3-rc.1" \
    "$vus" "le projet de répétition repart avec son fichier et son tag"
  [[ $vus != *"$compose_production"* ]] || { echo "la répétition a touché le fichier de production" >&2; exit 1; }
  # Constat S3 : les images -rc ne sont pas soumises à la rétention des trois.
  [[ $vus != *"image ls"* ]] || { echo "la répétition a lancé la rétention de la production" >&2; exit 1; }
}

case_deploy_site_rehearse_rollback_nominal() {
  faux_docker
  archive
  demande "rehearse rollback v1.2.3-rc.1"
  assert_eq 0 "$rc" "le retour arrière de répétition passe (messages : $err)"
  local vus
  vus=$(appels)
  assert_contains "image inspect eleyone-site:v1.2.3-rc.1" "$vus" "l'image -rc est vérifiée présente"
  assert_contains "compose --project-name site-rehearsal -f $compose_repetition up -d | SITE_TAG=v1.2.3-rc.1" \
    "$vus" "le projet de répétition repart"
  [[ $vus != *"load |"* ]] || { echo "rehearse rollback a lu l'entrée standard" >&2; exit 1; }
}

case_deploy_site_rehearse_stop() {
  faux_docker
  sortie_docker image-ls "v1.2.3-rc.2
v1.2.3-rc.1
v1.2.3
v1.1.0
"
  demande "rehearse stop"
  assert_eq 0 "$rc" "l'arrêt passe (messages : $err)"
  local vus
  vus=$(appels)
  # La ligne **entière** de l'appel, pas un fragment : « -f <fichier> » arriverait avant « down », et
  # un motif « down…-f » ne peut donc jamais correspondre — il aurait l'air d'une garde sans en être
  # une (point 9). Sans fichier Compose, le « :? » de SITE_TAG ne peut pas faire échouer un arrêt.
  assert_contains "compose --project-name site-rehearsal down | SITE_TAG=" "$vus" \
    "le projet de répétition est arrêté par son nom seul, sans fichier Compose"
  assert_contains "image rm eleyone-site:v1.2.3-rc.2 |" "$vus" "la première image -rc est supprimée"
  assert_contains "image rm eleyone-site:v1.2.3-rc.1 |" "$vus" "la seconde aussi"
  local production
  for production in v1.2.3 v1.1.0; do
    [[ $vus != *"image rm eleyone-site:$production |"* ]] \
      || { echo "l'arrêt de la répétition a supprimé l'image de production $production" >&2; exit 1; }
  done
}

case_deploy_site_rehearse_stop_sans_image_rc() {
  faux_docker
  sortie_docker image-ls "v1.2.3
"
  demande "rehearse stop"
  assert_eq 0 "$rc" "l'arrêt passe même sans image -rc (messages : $err)"
  local vus
  vus=$(appels)
  [[ $vus != *"image rm"* ]] || { echo "une image a été supprimée alors qu'aucune n'est -rc" >&2; exit 1; }
}

# --- status ------------------------------------------------------------------------------------------------------

case_deploy_site_status() {
  faux_docker
  sortie_docker ps "eleyone-site:v1.2.3
"
  demande "status"
  assert_eq 0 "$rc" "status passe (messages : $err)"
  assert_contains "production" "$out" "la production est affichée"
  assert_contains "répétition" "$out" "la répétition aussi"
  assert_contains "eleyone-site:v1.2.3" "$out" "avec le tag en service"
  local vus
  vus=$(appels)
  assert_contains "ps --filter label=com.docker.compose.project=site --format" "$vus" "il lit le projet de production"
  assert_contains "ps --filter label=com.docker.compose.project=site-rehearsal --format" "$vus" "et celui de la répétition"
  local touche
  for touche in "up -d" "down" "load |" "image rm"; do
    [[ $vus != *"$touche"* ]] || { echo "status a touché un service : $touche" >&2; exit 1; }
  done
}

case_deploy_site_status_sans_conteneur() {
  faux_docker
  demande "status"
  assert_eq 0 "$rc" "status passe sans conteneur (messages : $err)"
  assert_contains "aucun conteneur en service" "$out" "il le dit plutôt que d'afficher une ligne vide"
}

# --- l'installation du serveur ----------------------------------------------------------------------------------------

# La règle de l'aîné scripts/check-private.sh : ce qui manque **arrête**, il ne fait pas sauter une
# étape. Ici, les fichiers Compose ne sont pas chargés mais attendus à côté du script.
case_deploy_site_compose_absent() {
  faux_docker
  mkdir -p "$work/installation/remote"
  cp "$script" "$work/installation/remote/deploy-site.sh"
  archive
  demande "deploy v1.2.3" "$work/installation/remote/deploy-site.sh"
  assert_eq 2 "$rc" "une installation sans fichier Compose est une anomalie (messages : $err)"
  assert_contains "installation" "$err" "le message dit que l'installation est incomplète"
}

case_deploy_site_docker_absent() {
  mkdir -p "$work/tmp"
  run env -i PATH="$(path_sans_docker)" HOME="$work" TMPDIR="$work/tmp" \
    SSH_ORIGINAL_COMMAND="status" bash "$script" < /dev/null
  assert_eq 2 "$rc" "sans docker, c'est une anomalie (messages : $err)"
  assert_contains "docker introuvable" "$err" "le message le dit"
}

# --- les fichiers Compose -------------------------------------------------------------------------------------------------

case_compose_production_service() {
  local contenu
  contenu=$(cat "$compose_production")
  assert_contains 'image: "eleyone-site:${SITE_TAG:?' "$contenu" \
    "le tag est exigé : sans lui, Compose échoue au lieu de tirer un « latest » (constat A3)"
  assert_contains "external: true" "$contenu" "le réseau du proxy existe déjà, Compose ne le crée pas"
  assert_contains 'name: "${PROXY_NETWORK:?' "$contenu" "il est nommé par variable (NFR-9), et exigée"
  assert_contains "driver: json-file" "$contenu" "journaux json-file (AD-15)"
  assert_contains 'max-size: "10m"' "$contenu" "10 m"
  assert_contains 'max-file: "3"' "$contenu" "fois 3"
}

# Aucun port publié en production (AD-14) : le conteneur ne s'atteint que par le réseau du proxy.
case_compose_production_sans_port_publie() {
  local trouve
  shell_grep_into trouve -nE '^[[:space:]]*(ports|expose):' "$compose_production"
  assert_eq "" "$trouve" "aucune section « ports » ni « expose » en production"
}

case_compose_repetition_hors_du_proxy() {
  local contenu trouve
  contenu=$(cat "$compose_repetition")
  assert_contains "name: site-rehearsal" "$contenu" "le projet est celui de la répétition (AD-22)"
  assert_contains '- "127.0.0.1:18080:80"' "$contenu" "publié sur la boucle locale seulement"
  assert_contains 'image: "eleyone-site:${SITE_TAG:?' "$contenu" "le tag est exigé ici aussi"
  assert_contains "driver: json-file" "$contenu" "mêmes journaux qu'en production, pour répéter la même chose"
  # Rien du réseau du proxy : ni la variable, ni un réseau externe.
  shell_grep_into trouve -n 'PROXY_NETWORK\|external' "$compose_repetition"
  assert_eq "" "$trouve" "la répétition ne rejoint pas le réseau du proxy"
}

# Le script arrête et démarre les projets **par leur nom**. Si un fichier Compose changeait de
# « name: » sans que le script suive, « rehearse stop » arrêterait un projet qui n'existe pas et
# laisserait la répétition tourner.
case_deploy_site_projets_concordent() {
  local dans_script dans_fichier
  shell_grep_into dans_script -oE '^projet_production=[a-z-]+' "$script"
  assert_eq "projet_production=site" "$dans_script" "le script connaît le projet de production"
  shell_grep_into dans_fichier -oE '^name: [a-z-]+' "$compose_production"
  assert_eq "name: ${dans_script#projet_production=}" "$dans_fichier" \
    "le fichier de production porte le même nom de projet que le script"
  shell_grep_into dans_script -oE '^projet_repetition=[a-z-]+' "$script"
  assert_eq "projet_repetition=site-rehearsal" "$dans_script" "le script connaît le projet de répétition"
  shell_grep_into dans_fichier -oE '^name: [a-z-]+' "$compose_repetition"
  assert_eq "name: ${dans_script#projet_repetition=}" "$dans_fichier" \
    "le fichier de répétition porte le même nom de projet que le script"
}

# NFR-9 : rien de ce qui désigne le serveur n'entre dans le dépôt. La seule adresse admise est la
# boucle locale du canal de répétition, qui ne désigne aucune machine en particulier.
#
# **docs/procedures/serveur-de-production.md est dans la liste depuis la story 11.6** (constat S2 de
# sa revue de spec) : c'est le fichier du dépôt qui parle le plus du serveur — commandes `ssh`,
# `authorized_keys`, nom du réseau du proxy — et donc celui qui court le plus grand risque d'y écrire
# une valeur réelle. Il emploie des substituts, `<utilisateur>@<hôte>` et `<réseau-du-proxy>`.
#
# **Les quatre fichiers de la story 11.8 s'y ajoutent** : le skill de répétition parle des deux
# comptes du serveur, et `.env.example` est le fichier qui *invite* à écrire une valeur — deux
# destinations y sont nommées, sans valeur. Étendre une liste existante plutôt que d'en écrire une
# seconde ailleurs est le point 19 d'AGENTS.md appliqué à un contrôle.
fichiers_qui_parlent_du_serveur() {
  printf '%s\n' \
    "$script" \
    "$compose_production" \
    "$compose_repetition" \
    "$root/docs/procedures/deploy-site.md" \
    "$root/docs/procedures/serveur-de-production.md" \
    "$root/docs/procedures/rehearse-release.md" \
    "$root/scripts/rehearse-release.sh" \
    "$root/.claude/skills/rehearse-release/SKILL.md" \
    "$root/.env.example"
}

case_deploy_site_aucune_adresse() {
  local fichier trouve ligne
  while IFS= read -r fichier; do
    [[ -f $fichier ]] || { printf 'fichier attendu absent : %s\n' "$fichier" >&2; exit 1; }
    shell_grep_into trouve -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$fichier"
    while IFS= read -r ligne; do
      [[ -n $ligne ]] || continue
      [[ $ligne == 127.0.0.1 ]] \
        || { printf 'adresse IP dans %s (NFR-9)\n' "$fichier" >&2; exit 1; }
    done <<< "$trouve"
  done <<< "$(fichiers_qui_parlent_du_serveur)"
}

# La garde que ce fichier n'avait pas et que son jumeau scripts/tests/test-ship.sh portait déjà
# (case_ship_aucun_nom_de_compte) : une adresse IP n'est pas la seule façon de nommer le serveur, et
# « compte@machine.domaine » en est une autre. Point 19 d'AGENTS.md — une leçon ne se porte pas toute
# seule dans le fichier jumeau. Les substituts `<utilisateur>@<hôte>` ne correspondent pas au motif :
# il exige des caractères de nom de part et d'autre du « @ ».
#
# **Le point n'est pas exigé dans la partie droite**, et c'est un correctif : le motif le demandait,
# si bien qu'un nom d'hôte court — « compte@serveur », courant sur un réseau local — passait sans
# être vu. Les chevrons des substituts suffisent à écarter le faux positif : « <utilisateur>@<hôte> »
# ne correspond pas, « <hôte> » commençant par un caractère hors de la classe (constat de la revue
# du code de la PR n° 122).
case_deploy_site_aucun_nom_de_compte() {
  local fichier trouve ligne
  while IFS= read -r fichier; do
    # La garde de l'aîné, « case_deploy_site_aucune_adresse » : sans elle, un fichier renommé ou
    # déplacé ne produit aucune correspondance et le cas passe au vert sur un contrôle qui n'a rien
    # lu. La leçon ne s'était pas portée d'une déclinaison à l'autre **du même fichier** — point 19
    # d'AGENTS.md, et constat bloquant de la revue du code de la PR n° 122.
    [[ -f $fichier ]] || { printf 'fichier attendu absent : %s\n' "$fichier" >&2; exit 1; }
    shell_grep_into trouve -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+' "$fichier"
    while IFS= read -r ligne; do
      [[ -n $ligne ]] || continue
      printf 'compte@serveur écrit en clair dans %s (NFR-9) : %s\n' "$fichier" "$ligne" >&2
      exit 1
    done <<< "$trouve"
  done <<< "$(fichiers_qui_parlent_du_serveur)"
}

run_case "$@"
