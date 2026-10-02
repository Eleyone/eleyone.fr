#!/usr/bin/env bash
# Répétition générale de la mise en ligne (story 11.8, AD-13, AD-15, AD-22) : ce que le skill
# refuse, ce qu'il envoie, à quel compte, et ce qu'il **n'arrête pas** après un échec.
#
# **Aucun cas ne lance ssh, ssh-agent, ssh-add, ssh-keygen, curl, docker ni git push.** De faux
# binaires sont posés en tête de PATH
# et enregistrent leurs appels ; le vrai git ne sert que dans un dépôt jetable, et aucun tag n'est
# posé ailleurs que là. La suite reste hors ligne (story 0.9), et ne lit jamais le .env du dépôt :
# chaque cas écrit le sien dans sa racine jetable.
#
# **Point 19 d'AGENTS.md — les aînés et leurs gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-ship.sh (faux binaires qui enregistrent leurs appels et **échouent bruyamment**
# plutôt que d'avaler une erreur, affirmation du code de sortie avant de compter quoi que ce soit,
# vérification qu'aucun effet de bord n'a eu lieu après un refus, environnement réduit par « env -i »,
# TMPDIR qui n'appartient qu'au cas, marqueur qui ne doit apparaître ni dans un message ni sous
# « bash -x », égalité du nom du dépôt d'images) et « comme » scripts/tests/test-release.sh (dépôt
# git réel et jetable, faux git qui ne dévie que pour « fetch » et « push », faux sleep qui n'attend
# pas). Garde ajoutée ici, qu'aucun aîné n'avait : un faux ssh qui **survit** quand on lui demande un
# tunnel, pour qu'un cas puisse constater que le piège de sortie l'a bien tué. Le tableau complet est
# dans le fichier de story. Le faux ssh-agent reprend cette garde pour le second processus durable du
# script, l'agent privé : il survit, et les cas constatent qu'il est tué sur chaque chemin de sortie.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

script=$root/scripts/rehearse-release.sh
depot=$work/depot
readonly empreinte=bd27f17b4cdf1f59db762ba0134a38954024211f646f3fd5290b8b9b3a3e1075
readonly css=/css/main.min.$empreinte.css
readonly svg=/diagrams/schema.$empreinte.svg
readonly conteneur=a1b2c3d4e5f6

# --- les faux binaires ------------------------------------------------------------------------------

# Le faux ssh enregistre, pour chaque appel, la destination et la commande distante — c'est ce qui
# permet de vérifier que les deux comptes ne se mélangent pas. Une demande de tunnel (« -N ») le fait
# **survivre** : il écrit son PID et s'endort, pour qu'un cas puisse constater ensuite qu'il a été tué.
faux_ssh() {
  local vrai_sleep
  vrai_sleep=$(command -v sleep) || { echo "sleep introuvable" >&2; exit 2; }
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    printf 'dors=%q\n' "$vrai_sleep"
    cat <<'FAUX'
printf '%s\n' "$*" >> "$w/ssh-args"
dest=""; cmd=""; tunnel=0; config=0
while [ $# -gt 0 ]; do
  case "$1" in
    -o|-L|-i) shift 2 ;;
    -N) tunnel=1; shift ;;
    -G) config=1; shift ;;
    -*) shift ;;
    *) if [ -z "$dest" ]; then dest=$1; else cmd="$cmd $1"; fi; shift ;;
  esac
done
cmd=${cmd# }
# « ssh -G » ne se connecte pas : il affiche la configuration résolue. Comme le vrai, il y écrit
# **le nom de l'hôte** — le script ne doit jamais afficher cette sortie —, puis les « identityfile »
# posés par le cas, tels que ssh les écrit : « ~ » et « %d » non développés (vérifié, OpenSSH 10.2p1).
if [ "$config" = 1 ]; then
  printf '%s\n' "$dest" >> "$w/ssh-G"
  [ -f "$w/ssh-G-code" ] && exit "$(cat "$w/ssh-G-code")"
  echo "user ${dest%@*}"
  echo "hostname ${dest#*@}"
  [ -f "$w/identityfiles" ] && cat "$w/identityfiles"
  exit 0
fi
printf '%s\t%s\n' "$dest" "$cmd" >> "$w/ssh-appels"
# L'agent que reçoit chaque connexion : c'est ce qui prouve que la socket de l'agent privé n'entre que
# dans les appels au compte de déploiement.
# La commande vient en dernier : vide pour le tunnel, elle disparaîtrait au milieu d'une ligne lue
# par « read » avec IFS=tab, deux tabulations de suite comptant pour une.
printf '%s\t%s\t%s\n' "$dest" "${SSH_AUTH_SOCK:-}" "$cmd" >> "$w/ssh-env"
if [ "$tunnel" = 1 ]; then
  if [ -f "$w/tunnel-meurt" ]; then
    # **Le vrai ssh nomme la destination dans ses erreurs**, et c'est tout l'enjeu de NFR-9 : un
    # bouchon qui l'omet rend le test aveugle à une fuite. Le message imite donc la forme réelle
    # (constat bloquant de la revue du code de la PR n° 123, point 16 d'AGENTS.md).
    echo "ssh: Could not resolve hostname ${dest#*@}: Name or service not known" >&2
    echo "$dest: Permission denied (publickey)." >&2
    exit 255
  fi
  printf '%s' "$$" > "$w/tunnel-pid"
  : > "$w/tunnel-ouvert"
  # Le vrai sleep, par son chemin absolu : celui du PATH est le faux, qui n'attend pas.
  exec "$dors" 300
fi
lit() { [ -f "$w/$1" ] && cat "$w/$1"; return 0; }
case "$cmd" in
  true)
    # La sonde du compte d'administration.
    if [ -f "$w/admin-refuse" ]; then
      echo "$dest: Permission denied (publickey)." >&2
      exit 255
    fi
    exit 0 ;;
  status)
    # **La clé du poste, protégée par une phrase de passe** : tant qu'elle n'est pas dans l'agent que
    # reçoit cet appel, le vrai ssh, en BatchMode, ne peut pas s'en servir et rend 255.
    if [ -f "$w/sonde-refusee" ] && { [ ! -f "$w/agent-charge" ] || [ "$(cat "$w/agent-charge")" != "${SSH_AUTH_SOCK:-}" ]; }; then
      echo "$dest: Permission denied (publickey)." >&2
      exit 255
    fi
    if [ -f "$w/status-code" ]; then
      echo "deploy-site: commande refusée." >&2
      exit "$(cat "$w/status-code")"
    fi
    # Les « status » muets de l'attente : comptés **après le premier push** seulement, pour que la
    # vérification des connexions, qui précède tout tag, ne consomme pas un échec destiné à l'attente.
    n=0
    if [ -f "$w/git-push" ]; then
      n=1
      [ -f "$w/status-n" ] && n=$(($(cat "$w/status-n") + 1))
      printf '%s' "$n" > "$w/status-n"
    fi
    echecs=0
    [ -f "$w/status-echecs" ] && echecs=$(cat "$w/status-echecs")
    if [ "$n" -ge 1 ] && [ "$n" -le "$echecs" ]; then
      # Même raison que pour le tunnel : la forme réelle, destination comprise.
      echo "ssh: connect to host ${dest#*@} port 22: Connection refused" >&2
      exit 255
    fi
    tag=$(lit en-service)
    echo "deploy-site: production : aucun conteneur en service"
    if [ -n "$tag" ]; then
      echo "deploy-site: répétition : eleyone-site:$tag"
    else
      echo "deploy-site: répétition : aucun conteneur en service"
    fi
    exit 0 ;;
  "rehearse rollback "*)
    code=0
    [ -f "$w/rollback-code" ] && code=$(cat "$w/rollback-code")
    if [ "$code" != 0 ]; then echo "deploy-site: image absente de ce serveur." >&2; exit "$code"; fi
    printf '%s' "${cmd#rehearse rollback }" > "$w/en-service"
    echo "deploy-site: eleyone-site:${cmd#rehearse rollback } en service sur le projet site-rehearsal."
    exit 0 ;;
  "rehearse stop")
    code=0
    [ -f "$w/stop-code" ] && code=$(cat "$w/stop-code")
    if [ "$code" != 0 ]; then echo "deploy-site: arrêt impossible." >&2; exit "$code"; fi
    rm -f "$w/en-service"
    echo "deploy-site: projet site-rehearsal arrêté."
    exit 0 ;;
  "docker ps"*)
    code=0
    [ -f "$w/ps-code" ] && code=$(cat "$w/ps-code")
    [ "$code" = 0 ] || exit "$code"
    lit conteneur
    exit 0 ;;
  "docker logs"*)
    code=0
    [ -f "$w/logs-code" ] && code=$(cat "$w/logs-code")
    [ "$code" = 0 ] || exit "$code"
    lit journal
    exit 0 ;;
esac
# Un bouchon n'avale pas ce qu'il ne comprend pas : il échoue bruyamment, sans quoi un cas
# conclurait sur une commande que personne n'a lue (constat bloquant de la revue de la PR n° 120).
printf 'faux ssh : commande distante inattendue « %s »\n' "$cmd" >&2
exit 95
FAUX
  } > "$work/bin/ssh"
  chmod +x "$work/bin/ssh"
}

# Le faux curl ne répond **que lorsque le tunnel est ouvert** : avant, la connexion est refusée
# (code 7), comme elle le serait sur un port que personne n'écoute. Les réponses viennent de
# $work/http, une par chemin.
faux_curl() {
  mkdir -p "$work/bin" "$work/http"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    cat <<'FAUX'
entetes=""; corps=""; url=""; tete=0
while [ $# -gt 0 ]; do
  case "$1" in
    -D) entetes=$2; shift 2 ;;
    -o) corps=$2; shift 2 ;;
    -w|--max-time) shift 2 ;;
    -I) tete=1; shift ;;
    -*) shift ;;
    *) url=$1; shift ;;
  esac
done
printf '%s\n' "$url" >> "$w/curl-urls"
[ -f "$w/tunnel-ouvert" ] || exit 7
chemin=${url#http://127.0.0.1:18080}
cle=$(printf '%s' "$chemin" | sed 's#[^A-Za-z0-9]#_#g')
base="$w/http/$cle"
if [ ! -f "$base.entetes" ]; then
  printf 'faux curl : aucune réponse préparée pour « %s »\n' "$chemin" >&2
  exit 96
fi
if [ -n "$entetes" ]; then
  cp "$base.entetes" "$entetes" || { echo "faux curl : copie des en-têtes impossible" >&2; exit 97; }
fi
if [ -n "$corps" ] && [ "$corps" != /dev/null ]; then
  if [ "$tete" = 1 ]; then
    : > "$corps"
  else
    cp "$base.corps" "$corps" || { echo "faux curl : copie du corps impossible" >&2; exit 97; }
  fi
fi
cat "$base.code"
exit 0
FAUX
  } > "$work/bin/curl"
  chmod +x "$work/bin/curl"
}

# Le faux git ne dévie que pour « fetch » et « push » ; tout le reste va au vrai git, sur un vrai
# dépôt. Un « push » de tag simule la chaîne de livraison : le tag poussé entre en service sur le
# canal de répétition, sauf si $work/livraison-inerte existe.
faux_git() {
  local vrai
  vrai=$(command -v git) || { echo "git introuvable" >&2; exit 2; }
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    printf 'vrai=%q\n' "$vrai"
    cat <<'FAUX'
premier=""
for a in "$@"; do case "$a" in -*) continue ;; *) premier=$a; break ;; esac; done
case "$premier" in
  fetch)
    printf '%s\n' "$*" >> "$w/git-fetch"
    if [ -f "$w/fetch-code" ]; then exit "$(cat "$w/fetch-code")"; fi
    if [ -f "$w/forge-dev" ]; then
      "$vrai" update-ref refs/remotes/origin/dev "$(cat "$w/forge-dev")" || exit 1
    fi
    exit 0
    ;;
  push)
    printf '%s\n' "$*" >> "$w/git-push"
    if [ -f "$w/push-code" ]; then exit "$(cat "$w/push-code")"; fi
    for a in "$@"; do
      case "$a" in
        refs/tags/*) [ -f "$w/livraison-inerte" ] || printf '%s' "${a#refs/tags/}" > "$w/en-service" ;;
      esac
    done
    exit 0
    ;;
esac
exec "$vrai" "$@"
FAUX
  } > "$work/bin/git"
  chmod +x "$work/bin/git"
}

# Le faux sleep n'attend pas : il note seulement qu'on lui a demandé d'attendre.
# Avec $work/sleep-bloque, il attend vraiment une seconde : le temps qu'un cas envoie un signal au
# script pendant une attente.
faux_sleep() {
  local vrai_sleep
  vrai_sleep=$(command -v sleep) || { echo "sleep introuvable" >&2; exit 2; }
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'printf "%%s\\n" "$*" >> %q\n' "$work/sleeps"
    printf '[ ! -f %q ] || %q 1\n' "$work/sleep-bloque" "$vrai_sleep"
    printf 'exit 0\n'
  } > "$work/bin/sleep"
  chmod +x "$work/bin/sleep"
}

# L'agent ssh, ssh-add et ssh-keygen : **aucun cas ne lance les vrais**. Le faux ssh-agent imite
# « -D -a <socket> » : il pose sa socket (un fichier ordinaire tient lieu de socket), écrit son PID et
# **survit**, comme le tunnel, pour qu'un cas constate que le piège l'a tué.
faux_agent() {
  local vrai_sleep
  vrai_sleep=$(command -v sleep) || { echo "sleep introuvable" >&2; exit 2; }
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    printf 'dors=%q\n' "$vrai_sleep"
    cat <<'FAUX'
printf '%s\n' "$*" >> "$w/agent-appels"
sock=""
while [ $# -gt 0 ]; do
  case "$1" in
    -a) sock=$2; shift 2 ;;
    -D) shift ;;
    *) printf 'faux ssh-agent : option inattendue « %s »\n' "$1" >&2; exit 95 ;;
  esac
done
[ -n "$sock" ] || { echo "faux ssh-agent : aucune socket demandée" >&2; exit 95; }
if [ -f "$w/agent-meurt" ]; then
  echo "unix_listener: path \"$sock\" too long for Unix domain socket" >&2
  exit 1
fi
: > "$sock"
printf '%s' "$$" > "$w/agent-pid"
exec "$dors" 300
FAUX
  } > "$work/bin/ssh-agent"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    cat <<'FAUX'
printf '%s\t%s\t%s\n' "${SSH_AUTH_SOCK:-}" "${SSH_ASKPASS_REQUIRE:-}" "$*" >> "$w/ssh-add-appels"
if [ "${1:-}" = -l ]; then
  if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -e "$SSH_AUTH_SOCK" ]; then echo "The agent has no identities."; exit 1; fi
  echo "Error connecting to agent: No such file or directory" >&2
  exit 2
fi
# Sans terminal, le vrai ssh-add écrit son invite sur la sortie d'erreur, lit une fin de fichier et
# rend 1 aussitôt (mesuré, OpenSSH 10.2p1).
if [ -f "$w/ssh-add-code" ]; then
  printf 'Enter passphrase for %s: ' "$1" >&2
  exit "$(cat "$w/ssh-add-code")"
fi
[ -f "$w/agent-sans-effet" ] || printf '%s' "${SSH_AUTH_SOCK:-}" > "$w/agent-charge"
for f in "$@"; do echo "Identity added: $f (poste eleyone.fr)" >&2; done
exit 0
FAUX
  } > "$work/bin/ssh-add"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    cat <<'FAUX'
printf '%s\n' "$*" >> "$w/ssh-keygen-appels"
f=""
while [ $# -gt 0 ]; do
  case "$1" in
    -f|-P) [ "$1" = -f ] && f=$2; shift 2 ;;
    -y) shift ;;
    *) printf 'faux ssh-keygen : option inattendue « %s »\n' "$1" >&2; exit 95 ;;
  esac
done
# Comme le vrai : un fichier absent est une erreur (255), pas une clé en clair.
if [ ! -f "$f" ]; then
  echo "$f: No such file or directory" >&2
  exit 255
fi
if grep -q PROTEGEE "$f"; then
  echo "Load key \"$f\": incorrect passphrase supplied to decrypt private key" >&2
  exit 255
fi
echo "ssh-ed25519 AAAAessai poste"
exit 0
FAUX
  } > "$work/bin/ssh-keygen"
  chmod +x "$work/bin/ssh-agent" "$work/bin/ssh-add" "$work/bin/ssh-keygen"
}

# --- les réponses HTTP --------------------------------------------------------------------------------

entetes_html() { # $1 = code HTTP
  printf 'HTTP/1.1 %s\r\n' "$1"
  printf 'Server: nginx\r\n'
  printf 'Content-Type: text/html\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf 'Referrer-Policy: strict-origin-when-cross-origin\r\n'
  printf "Content-Security-Policy: default-src 'none'; style-src 'self'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'\r\n"
  printf 'Cache-Control: no-cache\r\n'
  printf '\r\n'
}

# Une ressource qui n'est pas du HTML : **aucune CSP**, c'est le « map » de deploy/nginx/site.conf
# qui la supprime par une valeur vide.
entetes_ressource() { # $1 = content-type, $2 = valeur de Cache-Control
  printf 'HTTP/1.1 200\r\n'
  printf 'Server: nginx\r\n'
  printf 'Content-Type: %s\r\n' "$1"
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf 'Referrer-Policy: strict-origin-when-cross-origin\r\n'
  printf 'Cache-Control: %s\r\n' "$2"
  printf '\r\n'
}

readonly immutable="public, max-age=31536000, immutable"

cle_http() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#_#g'; }

pose_reponse() { # $1 = chemin, $2 = code, $3 = en-têtes, $4 = corps
  local cle
  cle=$(cle_http "$1")
  mkdir -p "$work/http"
  printf '%s' "$3" > "$work/http/$cle.entetes"
  printf '%s' "$4" > "$work/http/$cle.corps"
  printf '%s' "$2" > "$work/http/$cle.code"
}

# Le corps des pages est minifié comme Hugo le minifie : **sans guillemets d'attribut**. Une fixture
# qui n'en porterait pas ferait passer un contrôle qui échouerait sur la vraie page (point 16).
page() { # $1 = langue, $2… = liens supplémentaires
  printf '<!doctype html><html lang=%s><head><meta charset=utf-8><link rel=stylesheet href=%s>' "$1" "$css"
  local lien
  for lien in "${@:2}"; do printf '<img src=%s>' "$lien"; done
  printf '</head><body>Bonjour</body></html>'
}

site_conforme() { # $1 = « avec-svg » pour qu'un SVG figure dans la page d'accueil
  local liens=()
  [[ ${1:-} != avec-svg ]] || liens=("$svg")
  pose_reponse / 200 "$(entetes_html 200)" "$(page fr "${liens[@]}")"
  pose_reponse /en/ 200 "$(entetes_html 200)" "$(page en "${liens[@]}")"
  pose_reponse /page-absente-de-la-repetition/ 404 "$(entetes_html 404)" "$(page fr)"
  pose_reponse /en/page-absente-de-la-repetition/ 404 "$(entetes_html 404)" "$(page en)"
  pose_reponse "$css" 200 "$(entetes_ressource text/css "$immutable")" ""
  [[ ${1:-} != avec-svg ]] || pose_reponse "$svg" 200 "$(entetes_ressource image/svg+xml "$immutable")" ""
  printf '[25/Sep/2026:14:03:11 +0200] "GET /" 200 4096\n[25/Sep/2026:14:03:12 +0200] "GET %s" 200 8192\n' "$css" \
    > "$work/journal"
  printf '%s' "$conteneur" > "$work/conteneur"
}

# Remplace une ligne d'en-tête d'une réponse déjà posée. Le remplacement passe par un fichier, pas
# par une regex construite depuis une variable (piège connu, docs/procedures/shell-scripts.md).
change_entete() { # $1 = chemin, $2 = nom de l'en-tête, $3 = ligne de remplacement (vide = retrait)
  local cle fichier ligne sortie=""
  cle=$(cle_http "$1")
  fichier=$work/http/$cle.entetes
  [[ -f $fichier ]] || { printf 'aucune réponse posée pour %s\n' "$1" >&2; exit 1; }
  while IFS= read -r ligne || [[ -n $ligne ]]; do
    ligne=${ligne%$'\r'}
    if [[ ${ligne%%:*} == "$2" ]]; then
      [[ -z $3 ]] || sortie+="$3"$'\r'$'\n'
      continue
    fi
    sortie+="$ligne"$'\r'$'\n'
  done < "$fichier"
  printf '%s' "$sortie" > "$fichier"
}

# --- le dépôt jetable et son .env -----------------------------------------------------------------------

# Un TMPDIR **qui n'appartient qu'au cas** : « ${TMPDIR:-/tmp} » est partagé avec le reste de la
# machine, et y compter supposerait son environnement (piège connu, shell-scripts.md).
tmpdir_a_soi() {
  local tmp=$work/tmp-a-soi
  rm -rf "$tmp"
  mkdir -p "$tmp"
  printf '%s' "$tmp"
}

restes_dans() { find "$1" -mindepth 1 | wc -l; }

readonly admin_essai=compte-admin@serveur-essai
readonly deploiement_essai=compte-deploiement@serveur-essai

ecris_env() { # $@ = lignes de .env ; sans argument, les deux destinations d'essai
  if (($#)); then
    printf '%s\n' "$@" > "$depot/.env"
  else
    printf 'ADMIN_HOST=%s\nDEPLOY_HOST=%s\n' "$admin_essai" "$deploiement_essai" > "$depot/.env"
  fi
}

# Un cas qui boucle repart d'un état vierge. **Tout** l'état y passe, pas seulement le dépôt et les
# faux binaires : un « tunnel-ouvert » laissé par l'itération précédente ferait refuser la suivante
# sur le port local, et le cas conclurait sur un refus qui n'est pas le sien.
reinitialise() {
  rm -rf "$depot" "$work/bin" "$work/http" \
    "$work/ssh-args" "$work/ssh-appels" "$work/curl-urls" "$work/git-push" "$work/git-fetch" \
    "$work/sleeps" "$work/tunnel-ouvert" "$work/tunnel-pid" "$work/tunnel-meurt" \
    "$work/en-service" "$work/status-n" "$work/status-echecs" "$work/livraison-inerte" \
    "$work/push-code" "$work/fetch-code" "$work/rollback-code" "$work/stop-code" \
    "$work/ps-code" "$work/logs-code" "$work/journal" "$work/conteneur" \
    "$work/ssh-env" "$work/ssh-G" "$work/ssh-G-code" "$work/identityfiles" "$work/sonde-refusee" \
    "$work/status-code" "$work/admin-refuse" "$work/agent-appels" "$work/agent-pid" "$work/agent-meurt" \
    "$work/ssh-add-appels" "$work/ssh-add-code" "$work/agent-charge" "$work/ssh-keygen-appels" "$work/.ssh" \
    "$work/agent-sans-effet" "$work/sleep-bloque" "$work/sys"
}

depot_de_test() { # $1 = URL du dépôt distant (défaut : le dépôt canonique)
  new_repo
  git -C "$depot" remote add origin "${1:-https://exemple.invalide/Eleyone/eleyone.fr.git}"
  printf 'site\n' > "$depot/site.txt"
  local sha
  sha=$(commit_all "socle")
  git -C "$depot" update-ref refs/remotes/origin/dev "$sha"
  printf '%s' "$sha" > "$work/forge-dev"
  ecris_env
  faux_git
  faux_ssh
  faux_curl
  faux_sleep
  faux_agent
  site_conforme "${2:-}"
}

# Le script se lance **depuis le dépôt jetable** : « git rev-parse --show-toplevel » l'y place, et
# c'est donc son .env qui est lu, jamais celui du dépôt du projet.
# L'utilisateur a **son** agent (SSH_AUTH_SOCK posé) : c'est lui que les appels au compte
# d'administration doivent garder.
readonly agent_utilisateur=/run/agent-de-l-utilisateur.sock
repete() { # $@ = arguments du script
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$(tmpdir_a_soi)" LC_ALL=C SSH_AUTH_SOCK="$agent_utilisateur" \
    bash -c 'cd "$1" || exit 99; shift; exec bash "$@"' bash "$depot" "$script" "$@"
}

appels_ssh() { [[ -f $work/ssh-appels ]] && cat "$work/ssh-appels"; return 0; }
commandes_ssh() { local ligne; while IFS=$'\t' read -r _ ligne; do printf '%s\n' "$ligne"; done <<< "$(appels_ssh)"; }
pushs() { [[ -f $work/git-push ]] && cat "$work/git-push"; return 0; }
urls_curl() { [[ -f $work/curl-urls ]] && cat "$work/curl-urls"; return 0; }
tags_poses() { git -C "$depot" tag --list; }

aucun_effet_de_bord() { # $1 = libellé
  [[ ! -f $work/git-push ]] || { printf 'un push a eu lieu malgré le refus (%s) :\n%s\n' "$1" "$(pushs)" >&2; exit 1; }
  [[ -z $(tags_poses) ]] || { printf 'un tag a été posé malgré le refus (%s) : %s\n' "$1" "$(tags_poses)" >&2; exit 1; }
  [[ ! -f $work/ssh-appels ]] || { printf 'ssh a été lancé malgré le refus (%s) :\n%s\n' "$1" "$(appels_ssh)" >&2; exit 1; }
}

# Ce qui reste permis quand rien n'est poussé : les deux sondes de la vérification des connexions, et
# elles seules — « status » au compte de déploiement, « true » au compte d'administration.
seules_les_sondes() { # $1 = libellé
  [[ ! -f $work/git-push ]] || { printf 'un push a eu lieu (%s) :\n%s\n' "$1" "$(pushs)" >&2; exit 1; }
  assert_eq "$deploiement_essai	status
$admin_essai	true" "$(appels_ssh)" "seules les deux sondes ont été envoyées ($1)"
}

aucun_arret_de_la_repetition() { # $1 = libellé
  local vu
  shell_grep_into vu -Fx -- "rehearse stop" <<< "$(commandes_ssh)"
  [[ -z $vu ]] \
    || { printf "« rehearse stop » a été envoyé après un échec (%s) : la répétition et ses images -rc sont détruites, décision A7.\n" "$1" >&2; exit 1; }
  assert_contains "la répétition tourne encore" "$err" "le message dit que la répétition tourne encore ($1)"
  assert_contains "rehearse stop" "$err" "et donne la commande pour l'arrêter ($1)"
}

# La clé du poste : protégée par une phrase de passe, donnée au compte de déploiement par l'entrée
# « Match » du ~/.ssh/config. Tant qu'elle n'est pas dans l'agent que reçoit l'appel, « status »
# rend 255. « ssh -G » la liste parmi d'autres, **telles que ssh les écrit** : une clé par défaut
# absente du disque, une clé sans phrase de passe, la clé du poste sous « ~ », une seconde clé
# protégée sous « %d », et un chemin à jeton que le script ne doit pas deviner. Ce dernier **existe**
# sous son nom littéral, et il est protégé : sans la garde du jeton, il serait chargé.
cle_du_poste() {
  mkdir -p "$work/.ssh"
  printf 'CLE PRIVEE PROTEGEE\n' > "$work/.ssh/cle_poste"
  printf 'CLE PRIVEE PROTEGEE\n' > "$work/.ssh/cle_seconde"
  printf 'CLE PRIVEE EN CLAIR\n' > "$work/.ssh/cle_libre"
  printf 'CLE PRIVEE PROTEGEE\n' > "$work/.ssh/cle_%r"
  {
    printf 'identityfile ~/.ssh/id_rsa\n'
    printf 'identityfile ~/.ssh/cle_libre\n'
    printf 'identityfile ~/.ssh/cle_poste\n'
    printf 'identityfile %%d/.ssh/cle_seconde\n'
    printf 'identityfile ~/.ssh/cle_%%r\n'
  } > "$work/identityfiles"
  : > "$work/sonde-refusee"
}

appels_ssh_add() { [[ -f $work/ssh-add-appels ]] && cat "$work/ssh-add-appels"; return 0; }

# Le pendant de tunnel_ferme : l'agent privé ne survit au script sur aucun chemin de sortie.
agent_ferme() { # $1 = libellé
  local pid
  [[ -f $work/agent-pid ]] || { printf "l'agent privé n'a jamais été démarré (%s)\n" "$1" >&2; exit 1; }
  pid=$(cat "$work/agent-pid")
  ! kill -0 "$pid" 2> /dev/null \
    || { printf "l'agent privé (pid %s) tourne encore après la fin du script (%s)\n" "$pid" "$1" >&2; kill "$pid" 2>/dev/null; exit 1; }
}

aucun_agent() { # $1 = libellé
  [[ ! -f $work/agent-appels ]] || { printf 'un agent a été démarré (%s) :\n%s\n' "$1" "$(cat "$work/agent-appels")" >&2; exit 1; }
  [[ ! -f $work/ssh-add-appels ]] || { printf 'ssh-add a été appelé (%s) :\n%s\n' "$1" "$(appels_ssh_add)" >&2; exit 1; }
}

aucune_destination_dans() { # $1 = libellé, $2… = textes
  local texte interdit
  for texte in "${@:2}"; do
    for interdit in "$admin_essai" "$deploiement_essai" "${admin_essai#*@}"; do
      [[ $texte != *"$interdit"* ]] \
        || { printf 'une destination apparaît dans la sortie (%s, NFR-9) : %s\n' "$1" "$interdit" >&2; exit 1; }
    done
  done
}

tunnel_ferme() {
  local pid
  [[ -f $work/tunnel-pid ]] || { echo "le tunnel n'a jamais été ouvert" >&2; exit 1; }
  pid=$(cat "$work/tunnel-pid")
  ! kill -0 "$pid" 2> /dev/null \
    || { printf 'le tunnel (pid %s) tourne encore après la fin du script\n' "$pid" >&2; kill "$pid" 2>/dev/null; exit 1; }
}

# --- les refus, avant tout effet de bord --------------------------------------------------------------

case_rehearse_sans_argument() {
  depot_de_test
  repete
  assert_eq 2 "$rc" "sans tag, c'est une anomalie d'usage (messages : $err)"
  assert_contains "usage" "$err" "le message le dit"
  aucun_effet_de_bord "sans argument"
}

case_rehearse_option_inconnue() {
  depot_de_test
  repete v0.1.0-rc.1 --merge
  assert_eq 2 "$rc" "une option inconnue est une anomalie d'usage (messages : $err)"
  assert_contains "option inconnue" "$err" "le message le dit"
  aucun_effet_de_bord "option inconnue"
}

case_rehearse_tags_refuses() {
  # Chaque forme est refusée **avant** que quoi que ce soit ne parte. La liste couvre ce que la garde
  # laisse passer si on l'écrit trop large : sans préfixe, sans correctif, un « rc » sans numéro, un
  # zéro de tête, une pré-version qui n'est pas une répétition, une injection derrière une espace.
  local mauvais
  for mauvais in "1.2.3-rc.1" "v1.2-rc.1" "v1.2.3.4-rc.1" "v1.2.3-rc" "v1.2.3-rc.x" "v01.2.3-rc.1" \
                 "v1.2.3-rc.01" "v1.2.3-beta.1" "v1.2.3-rc.1 ; echo raté" "vX.Y.Z-rc.N" "" \
                 "V1.2.3-rc.1" $'v1.2.3-rc.1\nv9.9.9-rc.9'; do
    reinitialise
    depot_de_test
    repete "$mauvais"
    assert_eq 2 "$rc" "$(printf 'le tag %q est refusé' "$mauvais") (messages : $err)"
    aucun_effet_de_bord "$(printf 'tag %q' "$mauvais")"
  done
}

case_rehearse_tags_acceptes() {
  # Un « refuse tout » refuserait aussi les tags corrects : les formes justes doivent passer l'audit
  # (point 11 — mesurer le cas court **et** le cas long).
  local bon
  for bon in v0.0.0-rc.0 v10.20.30-rc.7 v1.2.3-rc.123; do
    reinitialise
    depot_de_test
    repete "$bon"
    assert_eq 0 "$rc" "« $bon » est un tag de répétition valide (messages : $err)"
  done
}

case_rehearse_tag_de_production_refuse() {
  depot_de_test
  repete v1.0.0
  assert_eq 2 "$rc" "un tag de production n'est pas une répétition (messages : $err)"
  # Le message affirmé est **celui de cette garde-ci**, et non celui du contrôle de forme qui suit :
  # « vX.Y.Z » est aussi refusé comme « pas une répétition », et une assertion sur le seul mot
  # « release » passait au vert sur ce second message — le nom du script le contient (mesuré par
  # mutation, garde de l'aîné scripts/tests/test-ship.sh, case_ship_variables_absentes).
  assert_contains "se pose sur main par le skill release" "$err" "le message renvoie au bon skill"
  assert_contains "AD-22" "$err" "et dit pourquoi les deux canaux ne se croisent pas"
  aucun_effet_de_bord "tag de production"
}

case_rehearse_numero_demesure() {
  # « $((numero + 1)) » sur un numéro de vingt chiffres déborderait en silence, et le tag suivant
  # serait un tag que personne n'a demandé.
  depot_de_test
  repete v1.2.3-rc.12345678901234567890
  assert_eq 2 "$rc" "un numéro démesuré est refusé (messages : $err)"
  aucun_effet_de_bord "numéro démesuré"
}

case_rehearse_audit_ne_fait_rien() {
  depot_de_test
  repete v0.1.0-rc.1
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  assert_contains "v0.1.0-rc.2" "$out" "le tag suivant est calculé et annoncé"
  assert_contains "--run" "$out" "et le second appel est nommé"
  # L'audit éprouve désormais les deux comptes : c'est tout ce qu'il envoie.
  seules_les_sondes "audit"
  assert_eq "" "$(tags_poses)" "l'audit ne pose aucun tag"
  assert_contains "les deux connexions répondent" "$out" "et le message final le dit"
  # Le seul curl de l'audit est le contrôle du port local, qui ne reçoit aucune réponse : aucune
  # page du site n'est interrogée.
  local vu
  shell_grep_into vu -F -- "18080/en/" <<< "$(urls_curl)"
  assert_eq "" "$vu" "l'audit n'interroge pas le site"
}

case_rehearse_tag_suivant_calcule() {
  # « vaut pour tout tag vX.Y.Z-rc.N » : le numéro suivant n'est ni 2 en dur, ni une concaténation.
  local couple
  for couple in "v0.1.0-rc.1:v0.1.0-rc.2" "v1.0.0-rc.9:v1.0.0-rc.10" "v2.3.4-rc.0:v2.3.4-rc.1"; do
    reinitialise
    depot_de_test
    repete "${couple%%:*}"
    assert_eq 0 "$rc" "l'audit de ${couple%%:*} passe (messages : $err)"
    assert_contains "${couple#*:}" "$out" "${couple%%:*} annonce ${couple#*:}"
  done
}

case_rehearse_env_absent() {
  depot_de_test
  rm -f "$depot/.env"
  repete v0.1.0-rc.1
  assert_eq 2 "$rc" "sans .env, rien ne part (messages : $err)"
  assert_contains "ADMIN_HOST" "$err" "le message nomme la variable d'administration"
  assert_contains "DEPLOY_HOST" "$err" "et celle du déploiement"
  aucun_effet_de_bord ".env absent"
}

case_rehearse_variable_absente() {
  local nom
  for nom in ADMIN_HOST DEPLOY_HOST; do
    reinitialise
    depot_de_test
    if [[ $nom == ADMIN_HOST ]]; then
      ecris_env "DEPLOY_HOST=$deploiement_essai"
    else
      ecris_env "ADMIN_HOST=$admin_essai"
    fi
    repete v0.1.0-rc.1
    assert_eq 2 "$rc" "sans $nom, rien ne part (messages : $err)"
    assert_contains "$nom" "$err" "le message nomme la variable absente"
    # Le message affirmé est **celui de cette garde-ci**, et non celui du contrôle de forme qui
    # suit : une destination absente est aussi une destination mal formée, et une assertion sur le
    # seul nom de la variable laissait la garde de l'absence sans test (mesuré par mutation ; garde
    # de l'aîné scripts/tests/test-ship.sh, case_ship_variables_absentes).
    assert_contains "absente de .env" "$err" "c'est bien le refus de l'absence"
    aucun_effet_de_bord "$nom absente"
  done
}

case_rehearse_variable_vide() {
  # Une entrée présente mais vide n'est pas une conformité (piège connu, story 0.8) : ssh y lirait
  # une destination vide et chercherait une session locale.
  depot_de_test
  ecris_env "ADMIN_HOST=" "DEPLOY_HOST=$deploiement_essai"
  repete v0.1.0-rc.1
  assert_eq 2 "$rc" "une destination vide est refusée (messages : $err)"
  assert_contains "ADMIN_HOST" "$err" "le message nomme la variable"
  assert_contains "absente de .env, ou vide" "$err" "et ne la confond pas avec une valeur mal formée"
  aucun_effet_de_bord "destination vide"
}

case_rehearse_destination_qui_commence_par_un_tiret() {
  # « -E/tmp/journal » ou « -oProxyCommand=… » seraient lus par ssh comme des **options**, et la
  # destination viendrait alors d'ailleurs. La valeur choisie **passe le contrôle de format** : seule
  # la garde du tiret peut la refuser (point 9).
  depot_de_test
  ecris_env "ADMIN_HOST=-E@journal" "DEPLOY_HOST=$deploiement_essai"
  repete v0.1.0-rc.1
  assert_eq 2 "$rc" "une destination qui commence par un tiret est refusée (messages : $err)"
  assert_contains "option" "$err" "le message dit pourquoi"
  [[ $err != *journal* ]] || { echo "la valeur d'ADMIN_HOST est apparue dans le message (NFR-9)" >&2; exit 1; }
  aucun_effet_de_bord "destination en tiret"
}

case_rehearse_destination_mal_formee() {
  local mauvais
  for mauvais in "serveur-sans-compte" "compte@" "@serveur" "compte@serveur avec espace" "compte@serveur;id" "compte@serveur:22"; do
    reinitialise
    depot_de_test
    ecris_env "ADMIN_HOST=$mauvais" "DEPLOY_HOST=$deploiement_essai"
    repete v0.1.0-rc.1
    assert_eq 2 "$rc" "$(printf 'la destination %q est refusée' "$mauvais") (messages : $err)"
    assert_contains "ne suit pas le format" "$err" "le message rappelle le format attendu"
    aucun_effet_de_bord "destination mal formée"
  done
}

case_rehearse_depot_inconnu() {
  depot_de_test "https://exemple.invalide/quelquun/autre-chose.git"
  repete v0.1.0-rc.1
  assert_eq 2 "$rc" "un dépôt distant qui n'est pas celui du projet arrête tout (messages : $err)"
  aucun_effet_de_bord "dépôt inconnu"
}

case_rehearse_port_deja_occupe() {
  # Si quelque chose répond déjà sur le port, les vérifications interrogeraient ce service-là en
  # croyant parler au serveur. Le refus arrive **avant** le premier tag.
  depot_de_test
  : > "$work/tunnel-ouvert"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un port déjà occupé arrête tout (messages : $err)"
  assert_contains "18080" "$err" "le message nomme le port"
  aucun_effet_de_bord "port occupé"
}

case_rehearse_tag_deja_pose() {
  local deja
  for deja in v0.1.0-rc.1 v0.1.0-rc.2; do
    reinitialise
    depot_de_test
    git -C "$depot" tag "$deja"
    repete v0.1.0-rc.1 --run
    assert_eq 1 "$rc" "le tag $deja déjà posé est un refus (messages : $err)"
    assert_contains "$deja" "$err" "le message nomme le tag"
    # Les **deux** tags sont exigés libres avant le premier push : sans cela, un second tag occupé
    # laisserait une répétition à moitié jouée.
    [[ ! -f $work/git-push ]] || { printf 'un push a eu lieu alors que %s existe :\n%s\n' "$deja" "$(pushs)" >&2; exit 1; }
    [[ ! -f $work/ssh-appels ]] || { printf 'ssh a été lancé alors que %s existe\n' "$deja" >&2; exit 1; }
  done
}

case_rehearse_fetch_en_echec() {
  # Sans relecture des tags depuis la forge, un tag jugé libre ici est peut-être déjà posé là-bas.
  depot_de_test
  printf '1' > "$work/fetch-code"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "une lecture de la forge en échec arrête tout (messages : $err)"
  aucun_effet_de_bord "fetch en échec"
}

case_rehearse_fetch_explicite() {
  depot_de_test
  repete v0.1.0-rc.1
  assert_eq 0 "$rc" "l'audit passe (messages : $err)"
  local vu
  shell_grep_into vu -F -- "--tags" "$work/git-fetch"
  [[ -n $vu ]] || { printf 'aucun « git fetch --tags » :\n%s\n' "$(cat "$work/git-fetch" 2>/dev/null)" >&2; exit 1; }
}

case_rehearse_arbre_modifie_avertit() {
  depot_de_test
  printf 'travail en cours\n' >> "$depot/site.txt"
  repete v0.1.0-rc.1
  assert_eq 0 "$rc" "un arbre modifié n'empêche pas la répétition (messages : $err)"
  assert_contains "avertissement" "$out" "mais il est signalé"
}

# --- la séquence complète ---------------------------------------------------------------------------------

case_rehearse_sequence_nominale() {
  depot_de_test
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "la répétition se déroule en entier (messages : $err)"
  # Les deux tags, dans l'ordre, et rien d'autre.
  assert_eq "push --quiet origin refs/tags/v0.1.0-rc.1
push --quiet origin refs/tags/v0.1.0-rc.2" "$(pushs)" "deux tags poussés, dans l'ordre"
  assert_eq "v0.1.0-rc.1
v0.1.0-rc.2" "$(tags_poses)" "et posés localement sur le même commit"
  # Les commandes distantes : des « status » d'attente, le retour arrière, puis l'arrêt.
  local vu
  shell_grep_into vu -Fx -- "rehearse rollback v0.1.0-rc.1" <<< "$(commandes_ssh)"
  assert_eq "rehearse rollback v0.1.0-rc.1" "$vu" "le retour arrière vise le premier tag"
  shell_grep_into vu -Fx -- "rehearse stop" <<< "$(commandes_ssh)"
  assert_eq "rehearse stop" "$vu" "la répétition est arrêtée à la fin"
  # Et jamais une commande de production.
  shell_grep_into vu -E -- '^(deploy|rollback) ' <<< "$(commandes_ssh)"
  assert_eq "" "$vu" "aucune commande du canal de production n'est envoyée (AD-22)"
  assert_contains "répétition générale terminée" "$out" "le rapport final est lisible"
  tunnel_ferme
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste"
}

case_rehearse_les_deux_comptes_ne_se_melangent_pas() {
  # Le premier critère d'acceptation de la story 11.6 : la clé de déploiement **refuse** une
  # redirection de port. Le tunnel et « docker logs » passent donc par le compte d'administration, et
  # les commandes de deploy-site par le compte de déploiement. Jamais l'inverse.
  depot_de_test
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "la répétition se déroule en entier (messages : $err)"
  local destination commande vues_admin="" vues_deploiement=""
  while IFS=$'\t' read -r destination commande; do
    [[ -n $destination ]] || continue
    case $destination in
      "$admin_essai") vues_admin+="$commande"$'\n' ;;
      "$deploiement_essai") vues_deploiement+="$commande"$'\n' ;;
      *) printf 'destination inattendue : %s\n' "$destination" >&2; exit 1 ;;
    esac
  done <<< "$(appels_ssh)"
  local vu
  # Le compte d'administration : le tunnel (commande vide) et les deux lectures Docker, rien d'autre.
  shell_grep_into vu -E -- '^(status|rehearse )' <<< "$vues_admin"
  assert_eq "" "$vu" "aucune commande de deploy-site ne part par le compte d'administration"
  shell_grep_into vu -E -- '^docker (ps|logs) ' <<< "$vues_admin"
  [[ -n $vu ]] || { printf "les lectures Docker ne passent pas par le compte d'administration :\n%s\n" "$vues_admin" >&2; exit 1; }
  # Le compte de déploiement : jamais de tunnel — sa clé le refuserait — ni de commande Docker.
  shell_grep_into vu -E -- '^docker ' <<< "$vues_deploiement"
  assert_eq "" "$vu" "aucune commande docker ne part par le compte de déploiement"
  shell_grep_into vu -F -- "-L 18080" "$work/ssh-args"
  assert_contains "$admin_essai" "$vu" "le tunnel part par le compte d'administration"
  [[ $vu != *"$deploiement_essai"* ]] \
    || { echo "un tunnel a été demandé au compte de déploiement, dont la clé le refuse (story 11.6)" >&2; exit 1; }
}

case_rehearse_attente_avant_les_verifications() {
  # Sans attente, les « curl » tomberaient sur l'image précédente ou sur rien. Le tag n'entre jamais
  # en service ici : le script doit refuser **sans avoir interrogé le site**.
  depot_de_test
  : > "$work/livraison-inerte"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "un tag jamais mis en service est un refus (messages : $err)"
  assert_contains "Actions" "$err" "le message dit où regarder le run"
  assert_contains "status" "$err" "et quelle commande donne l'état du service"
  local vu
  shell_grep_into vu -F -- "18080/en/" <<< "$(urls_curl)"
  assert_eq "" "$vu" "aucune vérification n'a été lancée avant que le tag soit en service"
  aucun_arret_de_la_repetition "attente dépassée"
}

case_rehearse_attente_ne_confond_pas_rc1_et_rc11() {
  # « eleyone-site:v0.1.0-rc.1 » est une sous-chaîne de « eleyone-site:v0.1.0-rc.11 » : une
  # comparaison par sous-chaîne verrait le mauvais tag en service et lancerait les vérifications sur
  # l'image d'à côté. La comparaison porte donc sur le jeton entier.
  depot_de_test
  : > "$work/livraison-inerte"
  printf 'v0.1.0-rc.11' > "$work/en-service"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "rc.11 en service ne vaut pas rc.1 (messages : $err)"
  local vu
  shell_grep_into vu -F -- "18080/en/" <<< "$(urls_curl)"
  assert_eq "" "$vu" "aucune vérification n'a été lancée sur le mauvais tag"
}

case_rehearse_status_muet_trois_fois() {
  # Une clé refusée ou un serveur éteint ne s'améliore pas en trente minutes.
  depot_de_test
  printf '3' > "$work/status-echecs"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "trois status muets de suite sont une anomalie (messages : $err)"
  assert_contains "status" "$err" "le message le dit"
  aucun_arret_de_la_repetition "status muet"
}

case_rehearse_status_muet_une_fois_nempeche_rien() {
  # Le pendant du cas précédent : un échec **isolé** n'interrompt pas une attente longue. Sans cette
  # frontière, le compteur d'échecs consécutifs serait un compteur d'échecs tout court.
  depot_de_test
  printf '2' > "$work/status-echecs"
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "deux status muets suivis d'une réponse ne cassent rien (messages : $err)"
}

case_rehearse_tunnel_impossible() {
  depot_de_test
  : > "$work/tunnel-meurt"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un tunnel qui ne s'ouvre pas est une anomalie (messages : $err)"
  assert_contains "tunnel" "$err" "le message le dit"
  aucun_arret_de_la_repetition "tunnel impossible"
}

# NFR-9 à l'exécution, et non plus seulement dans le dépôt : quand ssh échoue, **c'est ssh qui
# parle**, et son message porte la destination. Ce cas le prouve sur les deux chemins où cela peut
# arriver — le tunnel, dont la sortie d'erreur partait autrefois droit au terminal, et une demande
# au serveur, dont la sortie est relue puis affichée. Le bouchon imite désormais la forme réelle
# (« Could not resolve hostname <hôte> », « <dest>: Permission denied »), sans quoi le cas ne
# prouverait rien : point 16 d'AGENTS.md, et constat bloquant de la revue du code de la PR n° 123.
case_rehearse_aucune_destination_dans_la_sortie() {
  local hote=${admin_essai#*@}
  depot_de_test
  : > "$work/tunnel-meurt"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un tunnel qui ne s'ouvre pas reste une anomalie (messages : $err)"
  for interdit in "$admin_essai" "$deploiement_essai" "$hote"; do
    [[ $err != *"$interdit"* ]] \
      || { printf 'la sortie d erreur porte une destination (NFR-9) : %s\n' "$interdit" >&2; exit 1; }
    [[ $out != *"$interdit"* ]] \
      || { printf 'la sortie standard porte une destination (NFR-9) : %s\n' "$interdit" >&2; exit 1; }
  done
  assert_contains "compte d" "$err" "la destination est remplacée par son rôle"

  # Le second chemin : « status » qui ne répond jamais. Le message de ssh y passe par sortie_serveur.
  reinitialise
  depot_de_test
  printf '99' > "$work/status-echecs"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un status qui ne répond jamais reste une anomalie (messages : $err)"
  for interdit in "$admin_essai" "$deploiement_essai" "$hote"; do
    [[ $err != *"$interdit"* ]] \
      || { printf 'la sortie d erreur porte une destination (NFR-9) : %s\n' "$interdit" >&2; exit 1; }
  done
}

case_rehearse_push_en_echec_retire_le_tag_local() {
  depot_de_test
  printf '1' > "$work/push-code"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un push en échec est une anomalie (messages : $err)"
  assert_eq "" "$(tags_poses)" "le tag local est retiré pour qu'une reprise le repose sur le même commit"
  # Les deux sondes précèdent le push ; rien d'autre ne part après son échec.
  assert_eq "$deploiement_essai	status
$admin_essai	true" "$(appels_ssh)" "aucune connexion après le push en échec"
}

case_rehearse_rollback_refuse() {
  depot_de_test
  printf '1' > "$work/rollback-code"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "un retour arrière refusé arrête la répétition (messages : $err)"
  assert_contains "rehearse rollback" "$err" "le message nomme la demande refusée"
  aucun_arret_de_la_repetition "retour arrière refusé"
}

# --- les en-têtes d'AD-13, relevés dans la configuration et non récités ---------------------------------------

case_rehearse_entetes_communs_manquants() {
  local cas
  # Chaque en-tête est retiré à son tour d'une **réponse conforme par ailleurs** : c'est l'entrée que
  # la garde doit refuser, et elle ne doit refuser qu'à cause de celle-là.
  for cas in "X-Content-Type-Options:nosniff" "Referrer-Policy:Referrer-Policy"; do
    reinitialise
    depot_de_test
    change_entete / "${cas%%:*}" ""
    repete v0.1.0-rc.1 --run
    assert_eq 1 "$rc" "sans ${cas%%:*}, la vérification échoue (messages : $err)"
    assert_contains "${cas#*:}" "$err" "le message nomme l'en-tête"
    aucun_arret_de_la_repetition "${cas%%:*} absent"
  done
}

case_rehearse_version_de_nginx_dans_server() {
  depot_de_test
  change_entete / Server "Server: nginx/1.30.4"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "« server_tokens off » est vérifié (messages : $err)"
  assert_contains "Server" "$err" "le message nomme l'en-tête"
}

case_rehearse_csp_exigee_sur_le_html() {
  depot_de_test
  change_entete / Content-Security-Policy ""
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "une page HTML sans CSP est un échec (messages : $err)"
  assert_contains "Content-Security-Policy" "$err" "le message nomme l'en-tête"
}

case_rehearse_csp_interdite_hors_du_html() {
  # Le « map » de deploy/nginx/site.conf n'envoie la CSP que sur « ~^text/html » : une valeur vide
  # supprime l'en-tête. La voir ailleurs est un écart à la configuration, pas une conformité.
  depot_de_test
  change_entete "$css" Cache-Control "Cache-Control: $immutable"
  local cle
  cle=$(cle_http "$css")
  printf 'Content-Security-Policy: default-src %s\r\n\r\n' "'none'" >> "$work/http/$cle.entetes"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "une CSP hors du HTML est un échec (messages : $err)"
  assert_contains "hors du HTML" "$err" "le message dit pourquoi"
}

case_rehearse_un_svg_sans_csp_passe() {
  # **Le piège mesuré.** Un SVG ne porte pas de CSP, par conception : les schémas D2 embarquent
  # leurs styles, qu'une politique « style-src 'self' » casserait. Une vérification qui exigerait la
  # CSP partout échouerait sur un fichier parfaitement conforme — c'est ce cas qui l'interdit.
  depot_de_test "" avec-svg
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "un SVG sans CSP est conforme (messages : $err)"
  local vu
  shell_grep_into vu -F -- "$svg" <<< "$(urls_curl)"
  [[ -n $vu ]] || { echo "le SVG de la page d'accueil n'a pas été interrogé" >&2; exit 1; }
}

case_rehearse_svg_absent_est_dit() {
  depot_de_test
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "l'absence de SVG n'est pas un échec (messages : $err)"
  assert_contains "sans objet" "$out" "mais elle est dite, jamais tue"
}

case_rehearse_cache_control_du_fichier_empreinte() {
  depot_de_test
  change_entete "$css" Cache-Control "Cache-Control: no-cache"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "un fichier empreinté servi en no-cache est un échec (messages : $err)"
  assert_contains "immutable" "$err" "le message dit ce qui était attendu"
}

case_rehearse_cache_control_du_html() {
  depot_de_test
  change_entete / Cache-Control "Cache-Control: $immutable"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "une page HTML servie en immutable est un échec (messages : $err)"
  assert_contains "no-cache" "$err" "le message dit ce qui était attendu"
}

case_rehearse_aucun_fichier_empreinte() {
  # Sans fichier empreinté dans la page servie, la règle « immutable » n'a rien à interroger : un
  # contrôle qui ne lit rien passerait au vert sans rien prouver (point 9).
  depot_de_test
  pose_reponse / 200 "$(entetes_html 200)" '<!doctype html><html lang=fr><head><meta charset=utf-8></head><body>Bonjour</body></html>'
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "une page d'accueil sans fichier empreinté est un échec (messages : $err)"
  assert_contains "empreinté" "$err" "le message dit ce qui manque"
}

case_rehearse_les_deux_404() {
  # Chacune dans sa langue : c'est le « error_page » du « location /en/ » qui le décide, et une seule
  # requête ne le prouverait pas.
  local couple
  for couple in "/page-absente-de-la-repetition/:fr:en" "/en/page-absente-de-la-repetition/:en:fr"; do
    reinitialise
    depot_de_test
    local chemin=${couple%%:*} reste=${couple#*:}
    pose_reponse "$chemin" 404 "$(entetes_html 404)" "$(page "${reste#*:}")"
    repete v0.1.0-rc.1 --run
    assert_eq 1 "$rc" "$chemin servie dans la mauvaise langue est un échec (messages : $err)"
    assert_contains "404" "$err" "le message nomme la cible"
  done
}

case_rehearse_404_qui_repond_200() {
  depot_de_test
  pose_reponse /page-absente-de-la-repetition/ 200 "$(entetes_html 200)" "$(page fr)"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "une URL absente qui répond 200 est un échec (messages : $err)"
  assert_contains "attendu 404" "$err" "le message dit ce qui était attendu"
}

# --- les journaux (AD-15) -------------------------------------------------------------------------------------

case_rehearse_journal_avec_une_ip() {
  depot_de_test
  printf '[25/Sep/2026:14:03:11 +0200] "GET /" 200 4096\n192.168.1.42 - - "GET /" 200\n' > "$work/journal"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "une adresse IP dans le journal est un échec (messages : $err)"
  assert_contains "adresse IP" "$err" "le message le dit"
  assert_contains "ligne(s) 2" "$err" "et donne le numéro de la ligne fautive"
  [[ $err != *192.168* ]] || { echo "l'adresse IP a été recopiée dans le message (AD-15, NFR-3)" >&2; exit 1; }
}

case_rehearse_journal_ipv6() {
  depot_de_test
  printf '[25/Sep/2026:14:03:11 +0200] "GET /" 200 4096\n2001:db8::1 "GET /" 200\n' > "$work/journal"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "une adresse IPv6 dans le journal est un échec (messages : $err)"
  [[ $err != *db8* ]] || { echo "l'adresse IPv6 a été recopiée dans le message" >&2; exit 1; }
}

case_rehearse_journal_sans_ip_ne_leve_rien() {
  # L'horodatage « 25/Sep/2026:14:03:11 » ressemble à une IPv6 abrégée, et un condensat de 64
  # caractères à une suite d'octets : un contrôle trop large refuserait un journal conforme, et le
  # skill deviendrait inutilisable (point 11 — mesurer aussi ce qui doit passer).
  depot_de_test
  {
    printf '[25/Sep/2026:14:03:11 +0200] "GET /" 200 4096\n'
    printf '[25/Sep/2026:14:03:12 +0200] "GET %s" 200 8192\n' "$css"
    printf '[25/Sep/2026:14:03:13 +0200] "GET /page-absente/" 404 512\n'
    printf '/docker-entrypoint.sh: Configuration complete; ready for start up\n'
    printf 'nginx/1.30.4\n'
  } > "$work/journal"
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "un journal conforme passe (messages : $err)"
}

case_rehearse_identifiant_de_conteneur_illisible() {
  # L'identifiant revient du serveur et repart dans une commande distante : il est confronté à une
  # expression ancrée **avant** d'y entrer. Ce cas vérifie qu'aucune commande « docker logs » n'a été
  # envoyée avec le mot fautif.
  depot_de_test
  printf 'a1b2c3; rm -rf /' > "$work/conteneur"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "un identifiant de conteneur illisible est un échec (messages : $err)"
  local vu
  shell_grep_into vu -F -- "docker logs" <<< "$(commandes_ssh)"
  assert_eq "" "$vu" "aucune commande docker logs n'est partie avec l'identifiant fautif"
}

case_rehearse_aucun_conteneur_de_repetition() {
  depot_de_test
  : > "$work/conteneur"
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "sans conteneur de répétition, la vérification échoue (messages : $err)"
  assert_contains "site-rehearsal" "$err" "le message nomme le projet attendu"
}

# --- le nettoyage, et ce qu'il ne fait pas (décision A7) ---------------------------------------------------------

case_rehearse_un_echec_narrete_pas_la_repetition() {
  # **La décision A7.** « rehearse stop » supprime toutes les images -rc, donc justement ce qu'il faut
  # inspecter après une répétition ratée. Le piège tue le tunnel — un processus laissé sur le poste
  # est un déchet — et **dit** que la répétition tourne encore.
  depot_de_test
  change_entete / X-Content-Type-Options ""
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "la vérification échoue (messages : $err)"
  aucun_arret_de_la_repetition "vérification en échec"
  tunnel_ferme
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste après un échec"
}

case_rehearse_aucun_exec() {
  # « exec » remplacerait le processus, et le piège EXIT ne tournerait jamais : le tunnel resterait
  # ouvert sur le poste.
  local exec_trouve
  shell_grep_into exec_trouve -nE '^[[:space:]]*exec[[:space:]]' "$script"
  assert_eq "" "$exec_trouve" "aucun « exec » dans le script"
}

# --- les connexions, avant le premier tag, et l'agent privé -------------------------------------------

case_rehearse_sonde_ok_aucun_agent() {
  # La clé est déjà dans un agent, ou sans phrase de passe : « status » répond du premier coup, et
  # rien n'est démarré — ni agent, ni ssh-add, ni même la lecture de la configuration.
  local mode
  for mode in audit --run; do
    reinitialise
    depot_de_test
    if [[ $mode == audit ]]; then repete v0.1.0-rc.1; else repete v0.1.0-rc.1 --run; fi
    assert_eq 0 "$rc" "la sonde répond, $mode passe (messages : $err)"
    aucun_agent "sonde qui répond, $mode"
    [[ ! -f $work/ssh-G ]] || { printf 'ssh -G a été lancé alors que la sonde répondait (%s)\n' "$mode" >&2; exit 1; }
    [[ ! -f $work/ssh-keygen-appels ]] || { printf 'ssh-keygen a été lancé alors que la sonde répondait (%s)\n' "$mode" >&2; exit 1; }
    assert_contains "compte de déploiement : « status » répond" "$out" "la sonde du déploiement est dite ($mode)"
    assert_contains "compte d'administration : la connexion répond" "$out" "celle de l'administration aussi ($mode)"
  done
}

case_rehearse_sondes_avant_le_premier_tag() {
  # Les deux sondes partent **avant** le premier push : la première connexion de la séquence est
  # « status » au compte de déploiement, la deuxième « true » au compte d'administration.
  depot_de_test
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "la répétition se déroule en entier (messages : $err)"
  local premieres
  premieres=$(head -n 2 "$work/ssh-appels")
  assert_eq "$deploiement_essai	status
$admin_essai	true" "$premieres" "les deux sondes ouvrent la séquence"
}

case_rehearse_agent_prive_charge_la_cle() {
  local mode
  for mode in audit --run; do
    reinitialise
    depot_de_test
    cle_du_poste
    if [[ $mode == audit ]]; then repete v0.1.0-rc.1; else repete v0.1.0-rc.1 --run; fi
    assert_eq 0 "$rc" "la clé chargée dans l'agent privé, $mode passe (messages : $err)"
    assert_contains "agent privé" "$out" "le chargement est annoncé ($mode)"
    # Seules les clés protégées sont chargées, en un appel : ni la clé absente du disque, ni la clé
    # en clair, ni le chemin à jeton — « ~ » et « %d » sont développés, « %r » n'est pas deviné.
    local chargements
    shell_grep_into chargements -v -- $'\t-l$' <<< "$(appels_ssh_add)"
    assert_eq "$work/.ssh/cle_poste $work/.ssh/cle_seconde" "${chargements##*$'\t'}" "ssh-add charge les seules clés protégées ($mode)"
    assert_contains $'\tnever\t' "$chargements" "sans fenêtre graphique : SSH_ASKPASS_REQUIRE=never ($mode)"
    agent_ferme "succès, $mode"
    if [[ $mode == audit ]]; then
      assert_eq "$deploiement_essai	status
$deploiement_essai	status
$admin_essai	true" "$(appels_ssh)" "l'audit envoie la sonde, la resonde et la sonde d'administration"
      [[ ! -f $work/git-push ]] || { echo "l'audit a poussé un tag" >&2; exit 1; }
    else
      [[ -f $work/git-push ]] || { echo "la répétition ne s'est pas poursuivie après le chargement" >&2; exit 1; }
      tunnel_ferme
    fi
    assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "la socket de l'agent ne reste pas sur le disque ($mode)"
  done
}

case_rehearse_agent_tue_apres_un_echec_plus_tard() {
  # L'agent démarré à la vérification des connexions meurt aussi quand la répétition échoue bien
  # plus loin, sur une vérification d'en-tête.
  depot_de_test
  cle_du_poste
  change_entete / X-Content-Type-Options ""
  repete v0.1.0-rc.1 --run
  assert_eq 1 "$rc" "la vérification échoue (messages : $err)"
  agent_ferme "vérification en échec"
  tunnel_ferme
  aucun_arret_de_la_repetition "échec avec agent"
}

case_rehearse_agent_tue_sur_sigterm() {
  # Le piège TERM : le script est arrêté pendant l'attente du premier tag, l'agent doit mourir avec
  # lui. (SIGINT n'est pas rejouable ici : un shell non interactif lancé en tâche de fond l'ignore, et
  # bash ne laisse pas piéger un signal ignoré à l'entrée.)
  depot_de_test
  cle_du_poste
  : > "$work/livraison-inerte"
  : > "$work/sleep-bloque"
  local pid essai=0 code=0
  env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$(tmpdir_a_soi)" LC_ALL=C SSH_AUTH_SOCK="$agent_utilisateur" \
    bash -c 'cd "$1" || exit 99; shift; exec bash "$@"' bash "$depot" "$script" v0.1.0-rc.1 --run \
    > "$work/.out" 2> "$work/.err" &
  pid=$!
  while [[ ! -f $work/git-push ]]; do
    ((essai < 100)) || { kill "$pid" 2>/dev/null; echo "le script n'a jamais atteint l'attente" >&2; cat "$work/.err" >&2; exit 1; }
    essai=$((essai + 1))
    sleep 0.1
  done
  kill -TERM "$pid"
  wait "$pid" || code=$?
  assert_eq 143 "$code" "le script sort en 143 sur SIGTERM ($(cat "$work/.err"))"
  agent_ferme "SIGTERM"
}

case_rehearse_ssh_add_sans_terminal() {
  # Sans terminal, ssh-add ne peut pas demander la phrase de passe : il rend 1 aussitôt. Le script
  # s'arrête en le disant, rien n'est poussé, et l'agent déjà démarré est tué.
  depot_de_test
  cle_du_poste
  printf '1' > "$work/ssh-add-code"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "une clé impossible à charger est une anomalie (messages : $err)"
  assert_contains "aucun terminal" "$err" "le message nomme la cause probable"
  assert_contains "Lancer le script dans un terminal" "$err" "et dit quoi faire"
  [[ ! -f $work/git-push ]] || { echo "un tag a été poussé alors que la clé n'a pas été chargée" >&2; exit 1; }
  assert_eq "" "$(tags_poses)" "aucun tag posé"
  agent_ferme "ssh-add en échec"
  aucune_destination_dans "ssh-add en échec" "$out" "$err"
}

case_rehearse_sonde_toujours_refusee_apres_chargement() {
  depot_de_test
  cle_du_poste
  : > "$work/agent-sans-effet"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "une sonde refusée clé chargée est une anomalie (messages : $err)"
  assert_contains "ne répond toujours pas" "$err" "le message le dit"
  [[ ! -f $work/git-push ]] || { echo "un tag a été poussé malgré la sonde refusée" >&2; exit 1; }
  agent_ferme "resonde refusée"
  aucune_destination_dans "resonde refusée" "$out" "$err"
}

case_rehearse_aucune_cle_protegee() {
  # La sonde échoue, mais aucune clé proposée n'a de phrase de passe : un agent n'y changerait rien.
  depot_de_test
  cle_du_poste
  printf 'identityfile ~/.ssh/id_rsa\nidentityfile ~/.ssh/cle_libre\n' > "$work/identityfiles"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "une sonde refusée sans clé protégée est une anomalie (messages : $err)"
  assert_contains "aucune des clés" "$err" "le message dit pourquoi aucun agent n'est démarré"
  aucun_agent "aucune clé protégée"
  [[ ! -f $work/git-push ]] || { echo "un tag a été poussé malgré la sonde refusée" >&2; exit 1; }
  assert_contains "Permission denied" "$err" "le message de ssh est montré"
  assert_contains "<compte de déploiement>" "$err" "expurgé"
  aucune_destination_dans "aucune clé protégée" "$out" "$err"
}

case_rehearse_status_refuse_par_le_serveur() {
  # Un code autre que 255 est la réponse du serveur : la connexion passe, charger une clé n'y
  # changerait rien. Ni « ssh -G », ni agent.
  depot_de_test
  cle_du_poste
  rm -f "$work/sonde-refusee"
  printf '1' > "$work/status-code"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un status refusé par le serveur arrête tout (messages : $err)"
  assert_contains "c'est le serveur qui répond non" "$err" "le message distingue le refus du serveur"
  aucun_agent "status refusé par le serveur"
  [[ ! -f $work/ssh-G ]] || { echo "ssh -G a été lancé pour un refus du serveur" >&2; exit 1; }
  [[ ! -f $work/git-push ]] || { echo "un tag a été poussé" >&2; exit 1; }
}

case_rehearse_agent_qui_meurt_aussitot() {
  depot_de_test
  cle_du_poste
  : > "$work/agent-meurt"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un agent qui ne démarre pas est une anomalie (messages : $err)"
  assert_contains "s'est arrêté aussitôt" "$err" "le message le dit"
  # « ssh-add -l » peut avoir interrogé la socket avant que la mort de l'agent soit constatée ; aucune
  # clé, elle, n'a été chargée.
  local chargements
  shell_grep_into chargements -v -- $'\t-l$' <<< "$(appels_ssh_add)"
  assert_eq "" "$chargements" "aucune clé chargée sans agent vivant"
  [[ ! -f $work/git-push ]] || { echo "un tag a été poussé" >&2; exit 1; }
}

case_rehearse_admin_refuse() {
  local mode
  for mode in audit --run; do
    reinitialise
    depot_de_test
    : > "$work/admin-refuse"
    if [[ $mode == audit ]]; then repete v0.1.0-rc.1; else repete v0.1.0-rc.1 --run; fi
    assert_eq 2 "$rc" "un compte d'administration injoignable arrête tout ($mode, messages : $err)"
    assert_contains "le compte d'administration ne répond pas" "$err" "le message nomme le rôle ($mode)"
    assert_contains "<compte d'administration>" "$err" "le message de ssh est montré expurgé ($mode)"
    [[ ! -f $work/git-push ]] || { printf 'un tag a été poussé (%s)\n' "$mode" >&2; exit 1; }
    assert_eq "" "$(tags_poses)" "aucun tag posé ($mode)"
    aucune_destination_dans "administration refusée, $mode" "$out" "$err"
  done
}

case_rehearse_admin_refuse_tue_l_agent() {
  # L'agent démarré pour le compte de déploiement meurt aussi quand c'est l'autre sonde qui échoue.
  depot_de_test
  cle_du_poste
  : > "$work/admin-refuse"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "un compte d'administration injoignable arrête tout (messages : $err)"
  agent_ferme "administration refusée"
}

case_rehearse_seul_le_compte_de_deploiement_recoit_l_agent() {
  # L'agent privé n'entre que dans les appels au compte de déploiement. Le compte d'administration
  # garde l'agent de l'utilisateur, où vit peut-être sa propre clé.
  depot_de_test
  cle_du_poste
  repete v0.1.0-rc.1 --run
  assert_eq 0 "$rc" "la répétition se déroule en entier (messages : $err)"
  local socket_privee destination commande socket n=0 deploiement_prive=0 admin=0
  socket_privee=$(cat "$work/agent-charge")
  [[ -n $socket_privee && $socket_privee != "$agent_utilisateur" ]] \
    || { echo "la socket de l'agent privé est vide ou celle de l'utilisateur" >&2; exit 1; }
  while IFS=$'\t' read -r destination socket commande; do
    [[ -n $destination ]] || continue
    n=$((n + 1))
    case $destination in
      "$admin_essai")
        assert_eq "$agent_utilisateur" "$socket" "« $commande » au compte d'administration garde l'agent de l'utilisateur"
        admin=$((admin + 1)) ;;
      "$deploiement_essai")
        if ((n == 1)); then
          assert_eq "$agent_utilisateur" "$socket" "la première sonde part avec l'agent de l'utilisateur"
        else
          assert_eq "$socket_privee" "$socket" "« $commande » au compte de déploiement reçoit l'agent privé"
          deploiement_prive=$((deploiement_prive + 1))
        fi ;;
    esac
  done < "$work/ssh-env"
  ((admin >= 3 && deploiement_prive >= 3)) \
    || { printf 'trop peu d appels relevés : %s admin, %s déploiement\n' "$admin" "$deploiement_prive" >&2; exit 1; }
  # Et « IdentityAgent=SSH_AUTH_SOCK », pour qu'une entrée du ~/.ssh/config ne désigne pas un autre
  # agent : sur les appels de déploiement avec l'agent privé, jamais sur ceux d'administration.
  local vu
  shell_grep_into vu -F -- "IdentityAgent=SSH_AUTH_SOCK" "$work/ssh-args"
  [[ -n $vu ]] || { echo "aucun appel ne force IdentityAgent=SSH_AUTH_SOCK" >&2; exit 1; }
  [[ $vu != *"$admin_essai"* ]] || { echo "un appel au compte d'administration force l'agent privé" >&2; exit 1; }
}

case_rehearse_outils_de_l_agent_absents() {
  # Sans ssh-keygen, « ! ssh-keygen » rendrait 127 et une clé en clair passerait pour protégée. Les
  # outils sont exigés avant. Le PATH du cas est fait de liens vers les outils du poste, ssh-keygen
  # excepté : le vrai, plus loin dans le PATH, serait sinon trouvé.
  depot_de_test
  cle_du_poste
  rm -f "$work/bin/ssh-keygen"
  mkdir -p "$work/sys"
  local dossier fichier
  local -a dossiers
  IFS=: read -r -a dossiers <<< "$PATH"
  for dossier in "${dossiers[@]}"; do
    [[ -d $dossier ]] || continue
    for fichier in "$dossier"/*; do
      [[ -f $fichier && -x $fichier ]] || continue
      [[ ${fichier##*/} != ssh-keygen ]] || continue
      [[ -e $work/sys/${fichier##*/} ]] || ln -s "$fichier" "$work/sys/${fichier##*/}"
    done
  done
  run env -i PATH="$work/bin:$work/sys" HOME="$work" TMPDIR="$(tmpdir_a_soi)" LC_ALL=C SSH_AUTH_SOCK="$agent_utilisateur" \
    bash -c 'cd "$1" || exit 99; shift; exec bash "$@"' bash "$depot" "$script" v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "sans ssh-keygen, le script s'arrête (messages : $err)"
  assert_contains "ssh-keygen est introuvable" "$err" "le message nomme l'outil"
  aucun_agent "outils absents"
  [[ ! -f $work/git-push ]] || { echo "un tag a été poussé" >&2; exit 1; }
}

# --- l'hygiène du dépôt et des messages -------------------------------------------------------------------------

case_rehearse_aucune_valeur_dans_les_messages() {
  # Un message nomme la variable, jamais son contenu (NFR-9). La destination choisie est refusée par
  # le contrôle de format : c'est le chemin le plus direct vers un message qui parlerait d'elle.
  depot_de_test
  local marqueur=CHAINE-QUI-NE-DOIT-PAS-SORTIR
  ecris_env "ADMIN_HOST=compte-$marqueur@serveur-$marqueur;id" "DEPLOY_HOST=$deploiement_essai"
  repete v0.1.0-rc.1 --run
  assert_eq 2 "$rc" "la destination est refusée (messages : $err)"
  [[ $out != *"$marqueur"* ]] || { echo "une valeur de .env est apparue sur la sortie standard" >&2; exit 1; }
  [[ $err != *"$marqueur"* ]] || { echo "une valeur de .env est apparue sur la sortie d'erreur" >&2; exit 1; }
}

case_rehearse_aucune_trace_de_shell() {
  # « set +x » dès l'en-tête : même lancé avec « bash -x », le script n'écrit pas le nom du compte ni
  # celui de l'hôte dans la trace. Le cas le **lance** ainsi plutôt que de relire le fichier.
  depot_de_test
  local marqueur=CHAINE-QUI-NE-DOIT-PAS-SORTIR
  ecris_env "ADMIN_HOST=compte-$marqueur@serveur-$marqueur" "DEPLOY_HOST=compte2-$marqueur@serveur-$marqueur"
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$(tmpdir_a_soi)" LC_ALL=C \
    bash -c 'cd "$1" || exit 99; shift; exec bash -x "$@"' bash "$depot" "$script" v0.1.0-rc.1
  assert_eq 0 "$rc" "l'audit passe sous bash -x (messages : $err)"
  [[ $err != *"$marqueur"* ]] || { echo "bash -x a écrit la destination dans la trace" >&2; exit 1; }
  [[ $out != *"$marqueur"* ]] || { echo "bash -x a écrit la destination sur la sortie standard" >&2; exit 1; }
  local rallumage
  shell_grep_into rallumage -nE '^[[:space:]]*set[[:space:]]+-[a-z]*x' "$script"
  assert_eq "" "$rallumage" "aucun « set -x » dans le script"
}

case_rehearse_aucune_adresse_de_forge() {
  # Le chemin, jamais l'adresse (docs/procedures/shell-scripts.md, tranché à la story 0.4) : les
  # messages de « git fetch » et « git push » portent l'URL de la forge, et ils sont écartés.
  local vu
  # Les **appels**, et non les lignes qui en parlent : un message qui cite « git push » n'écarte
  # aucune sortie d'erreur.
  shell_grep_into vu -nE '^[[:space:]]*(if ! )?git (fetch|push) ' "$script"
  [[ -n $vu ]] || { echo "ni fetch ni push dans le script ?" >&2; exit 1; }
  local nombre=0
  local ligne
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    [[ $ligne == *"2> /dev/null"* ]] \
      || { printf "la sortie d'erreur de git n'est pas écartée, l'adresse de la forge s'y trouve : %s\n" "$ligne" >&2; exit 1; }
    nombre=$((nombre + 1))
  done <<< "$vu"
  ((nombre >= 2)) || { printf 'un seul appel réseau à git relevé (%s) : le motif ne lit pas tout\n' "$nombre" >&2; exit 1; }
}

case_rehearse_pipefail_declare() {
  local entete
  shell_grep_into entete -nE '^set -euo pipefail$' "$script"
  [[ -n $entete ]] || { echo "set -euo pipefail absent de l'en-tête" >&2; exit 1; }
}

case_rehearse_meme_depot_dimages_que_ship() {
  # Le nom du dépôt d'images vit à quatre endroits qui ne peuvent pas lire une source commune —
  # deploy/remote/deploy-site.sh est recopié **seul** sur le serveur. Faute de source unique, c'est
  # ce cas qui les tient égaux, comme case_ship_meme_depot_dimages_partout le fait pour les trois
  # autres (point 19 d'AGENTS.md).
  local ici la_bas
  shell_grep_into ici -oE '^readonly depot_image=.+$' "$script"
  shell_grep_into la_bas -oE '^depot_image=.+$' "$root/scripts/release/ship.sh"
  [[ -n $ici ]] || { echo "depot_image introuvable dans rehearse-release.sh" >&2; exit 1; }
  assert_eq "${la_bas#depot_image=}" "${ici#readonly depot_image=}" \
    "rehearse-release.sh et ship.sh nomment le même dépôt d'images"
}

case_rehearse_meme_projet_de_repetition_que_deploy_site() {
  local ici la_bas
  shell_grep_into ici -oE '^readonly projet_repetition=.+$' "$script"
  shell_grep_into la_bas -oE '^projet_repetition=.+$' "$root/deploy/remote/deploy-site.sh"
  [[ -n $ici ]] || { echo "projet_repetition introuvable dans rehearse-release.sh" >&2; exit 1; }
  assert_eq "${la_bas#projet_repetition=}" "${ici#readonly projet_repetition=}" \
    "rehearse-release.sh et deploy-site.sh nomment le même projet de répétition"
}

case_rehearse_meme_port_que_le_compose_de_repetition() {
  local ici la_bas
  shell_grep_into ici -oE '^readonly port=[0-9]+$' "$script"
  shell_grep_into la_bas -oF '127.0.0.1:18080' "$root/deploy/compose.rehearsal.yaml"
  assert_eq "readonly port=18080" "$ici" "le script vise le port d'AD-22"
  [[ -n $la_bas ]] || { echo "le fichier Compose de répétition ne publie pas 127.0.0.1:18080" >&2; exit 1; }
}

# --- le skill, ses trois niveaux et ses deux liens ------------------------------------------------------------------

case_rehearse_skill_en_trois_niveaux() {
  local skill=$root/.claude/skills/rehearse-release/SKILL.md
  [[ -f $skill ]] || { printf 'SKILL.md absent : %s\n' "$skill" >&2; exit 1; }
  [[ -f $root/docs/procedures/rehearse-release.md ]] || { echo "la procédure est absente" >&2; exit 1; }
  [[ -x $script ]] || { echo "le script n'est pas exécutable" >&2; exit 1; }
  local dossier cible
  for dossier in .agents .agent; do
    cible=$(readlink "$root/$dossier/skills/rehearse-release") \
      || { printf '%s/skills/rehearse-release n est pas un lien symbolique\n' "$dossier" >&2; exit 1; }
    assert_eq "../../.claude/skills/rehearse-release" "$cible" "$dossier : lien **relatif** vers l'unique copie"
    [[ -f $root/$dossier/skills/rehearse-release/SKILL.md ]] \
      || { printf '%s/skills/rehearse-release ne mène à rien\n' "$dossier" >&2; exit 1; }
  done
}

case_rehearse_env_example_nomme_les_deux_destinations() {
  local exemple=$root/.env.example vu
  local nom
  for nom in ADMIN_HOST DEPLOY_HOST; do
    shell_grep_into vu -xF -- "$nom=" "$exemple"
    assert_eq "$nom=" "$vu" ".env.example nomme $nom, **sans valeur**"
  done
}

run_case "$@"
