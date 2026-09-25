#!/usr/bin/env bash
# Répétition générale de la mise en ligne, sur le canal de répétition du serveur (story 11.8, AD-22).
#
#   rehearse-release.sh <tag vX.Y.Z-rc.N>         audit : vérifie tout, n'agit sur rien
#   rehearse-release.sh <tag vX.Y.Z-rc.N> --run   joue la répétition, deux tags poussés compris
#
# Ce que « --run » enchaîne, et rien d'autre :
#
#   1. le tag <tag> est posé sur origin/dev et poussé — le workflow « release » construit l'image et
#      la livre au canal de répétition (scripts/release/ship.sh, story 11.5) ;
#   2. le script **attend** de voir ce tag en service, en interrogeant « deploy-site status » ;
#   3. il ouvre le tunnel SSH vers 127.0.0.1:18080, puis vérifie le site servi ;
#   4. le tag suivant (<tag> avec N+1) est posé, poussé, attendu, vérifié ;
#   5. « rehearse rollback <tag> » remet le premier en service, attendu, vérifié ;
#   6. « rehearse stop » arrête la répétition et supprime les images -rc.
#
# ## Les deux comptes, et pourquoi ils ne se mélangent pas
#
#   - le **compte de déploiement** (DEPLOY_HOST) porte « rehearse rollback » et « rehearse stop », et
#     répond à « status ». Sa clé est posée avec « restrict », qui **refuse une redirection de
#     port** : c'est le premier critère d'acceptation de la story 11.6, vérifié par ses quatre essais ;
#   - le **compte d'administration** (ADMIN_HOST) ne sert qu'à deux choses : ouvrir le tunnel, et
#     lire les journaux du conteneur (« docker logs »). Le tunnel ne transporte que du HTTP : un
#     « docker logs » lancé en local parlerait au démon Docker du poste.
#
# AD-22 (« ssh -L … ») et la story 11.6 (« la clé de déploiement refuse un tunnel ») ne se
# contredisent qu'en apparence : ils portent sur deux comptes différents.
#
# ## Ce que le script ne fait pas
#
#   - il **ne suit pas le run de la forge** : il n'appelle pas son API. L'état vrai est celui que le
#     serveur renvoie, et il ne dépend pas d'un homelab qui peut tomber (AD-14) ;
#   - il **ne touche ni à la production, ni au proxy, ni au DNS** : le canal de répétition est un
#     projet Compose distinct, hors du réseau du proxy, publié sur la seule boucle locale (AD-22) ;
#   - il **n'arrête pas la répétition après un échec**. Voir le nettoyage, plus bas.
#
# Codes de sortie : 0 la répétition s'est déroulée en entier et tout est vérifié ; 1 refus ou
# vérification en échec (rien n'est arrêté, voir le message) ; 2 anomalie (usage, outil absent, .env,
# dépôt, tunnel, serveur injoignable).
# Procédure : docs/procedures/rehearse-release.md
set -euo pipefail
# Même lancé avec « bash -x », la trace s'arrête ici : .env porte le nom du compte et de l'hôte du
# serveur, que NFR-9 tient hors de tout ce qui se lit ailleurs que sur le poste.
set +x
# Une **plage** de caractères ne dit pas la même chose selon la locale : sur le poste, en
# fr_FR.UTF-8, « [0-9a-f] » laisse entrer les octets d'un caractère accentué, là où la même
# expression s'arrête avant dans CHECK_IMAGE, en C (piège connu, docs/procedures/shell-scripts.md,
# mesuré à la story 11.5). Ce script compare des empreintes, des identifiants de conteneur et des
# adresses IP, tous écrits en plages : la locale est donc fixée une fois pour toutes.
export LC_ALL=C

script_name=rehearse-release
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# gitea.sh n'est chargé que pour « check_origin » : sans lui, un tag partirait vers un dépôt qui
# n'est pas celui du projet. Aucune fonction d'API n'est appelée, et « require_tools » non plus — ce
# script n'a pas besoin de jq. Une parade s'écrit une fois (docs/procedures/shell-scripts.md).
# shellcheck source=lib/gitea.sh
. "$script_dir/lib/gitea.sh"
# release.sh porte les deux expressions de tags, et charge lui-même shell.sh.
# shellcheck source=lib/release.sh
. "$script_dir/lib/release.sh"

# gitea.sh définit die() avec le code 1 ; ici 1 est réservé aux refus et aux vérifications en échec,
# et 2 dit l'anomalie, comme dans release.sh et verify-and-merge-pr.sh.
die() { printf '%s: %b\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %b\n' "$script_name" "$*" >&2; exit 1; }

# Le port des deux côtés du tunnel : le conteneur de répétition n'est publié que sur
# « 127.0.0.1:18080 » du serveur (AD-22, deploy/compose.rehearsal.yaml).
readonly port=18080
readonly projet_repetition=site-rehearsal
# Le dépôt d'images. Le même nom vit dans scripts/release/ship.sh, scripts/release/build-image.sh et
# deploy/remote/deploy-site.sh, qui ne peuvent pas lire une source commune (le dernier est recopié
# seul sur le serveur). Un cas de test tient celui-ci égal aux autres (point 19 d'AGENTS.md).
readonly depot_image=eleyone-site
readonly attente_max=120   # 120 × 15 s = 30 min, le temps d'un run « release » et de sa livraison
readonly attente_delai=15  # secondes ; les tests posent un faux sleep en tête de PATH
readonly attente_echecs=3  # « status » muet trois fois de suite : ce n'est plus une attente
readonly tunnel_max=20     # 20 × 1 s pour que le tunnel réponde
readonly tunnel_delai=1
readonly journal_lignes=500
readonly absente_fr=/page-absente-de-la-repetition/
readonly absente_en=/en/page-absente-de-la-repetition/
readonly usage="usage : rehearse-release.sh <tag vX.Y.Z-rc.N> [--run]"

# --- les arguments, avant tout le reste ----------------------------------------------------------
tag="" run=""
while (($#)); do
  case $1 in
    --run) [[ -z $run ]] || die "$usage"; run=1; shift ;;
    -*) die "option inconnue : $(printf '%q' "$1"). $usage" ;;
    *) [[ -z $tag ]] || die "$usage"; tag=$1; shift ;;
  esac
done
[[ -n $tag ]] || die "$usage"

# Les deux expressions sont disjointes et ancrées (scripts/lib/release.sh) : un tag accepté par l'une
# est refusé par l'autre. Le croisement des canaux a son propre message — c'est la faute qu'AD-22
# existe pour empêcher, et la confondre avec « tag mal formé » ferait chercher une faute de frappe.
if [[ $tag =~ $release_tag_production ]]; then
  die "tag $(printf '%q' "$tag") : une mise en ligne se pose sur main par le skill release, jamais ici (AD-22). Rien n'a été fait."
fi
[[ $tag =~ $release_tag_rehearsal ]] \
  || die "tag $(printf '%q' "$tag") refusé : une répétition générale porte « vX.Y.Z-rc.N », sans zéro de tête (AD-22). $usage. Rien n'a été fait."

# Le tag suivant se calcule, il ne se demande pas : la procédure vaut pour tout « vX.Y.Z-rc.N ».
# L'expression ci-dessus a déjà refusé un zéro de tête, si bien que « $((numero + 1)) » ne peut pas
# lire « 08 » comme un octal — c'est cette garde-là qui rend le calcul sûr, et elle est plus haut.
numero=${tag##*-rc.}
base=${tag%-rc.*}
((${#numero} <= 9)) \
  || die "le numéro de répétition de $tag ne tient pas dans un entier raisonnable : choisir un numéro plus court. Rien n'a été fait."
suivant="$base-rc.$((numero + 1))"

# --- les outils, le dépôt, les destinations ------------------------------------------------------
for outil in git ssh curl; do
  command -v "$outil" > /dev/null 2>&1 \
    || die "$outil est introuvable : la répétition est « git push », « ssh » et « curl ». Rien n'a été fait."
done

root=$(git rev-parse --show-toplevel 2> /dev/null) || die "à lancer dans le dépôt."
cd "$root"
check_origin

env_file=$root/.env
[[ -f $env_file ]] \
  || die ".env absent à la racine du dépôt : il porte ADMIN_HOST et DEPLOY_HOST (.env.example, docs/procedures/rehearse-release.md). Rien n'a été fait."

# Une fonction remplit une variable de l'appelant plutôt que d'écrire sur la sortie standard :
# appelée dans « $(…) », son « die » ne quitterait que le sous-shell (piège connu,
# docs/procedures/shell-scripts.md). Aucune valeur de .env n'est jamais affichée (NFR-9).
destination=""
lit_destination() { # $1 = nom de la variable ; 0 trouvée, 1 absente ou vide, 2 .env illisible
  local nom=$1 lignes ligne
  destination=""
  lignes=$(dotenv_read "$env_file" "$nom") || return 2
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    # Le préfixe de dotenv_read laisserait passer « ADMIN_HOSTNAME » : la clé est comparée entière.
    [[ ${ligne%%=*} == "$nom" ]] || continue
    destination=${ligne#*=}
    [[ -n $destination ]] || return 1
    return 0
  done <<< "$lignes"
  return 1
}

exige_destination() { # $1 = nom de la variable de .env, $2 = variable du script à remplir
  local code=0 role
  case $1 in
    ADMIN_HOST) role="le compte d'administration (tunnel et journaux)" ;;
    *) role="le compte de déploiement (rehearse rollback, rehearse stop, status)" ;;
  esac
  lit_destination "$1" || code=$?
  ((code != 2)) || die ".env illisible. Rien n'a été fait."
  ((code == 0)) \
    || die "$1 absente de .env, ou vide : la répétition a besoin de $role. Voir .env.example et docs/procedures/rehearse-release.md. Rien n'a été fait."
  # Un « - » en tête ferait lire la destination comme une **option** par ssh : « -E/tmp/journal » ou
  # « -oProxyCommand=… » deviendraient des réglages que personne n'a demandés. Ce refus précède le
  # contrôle de format pour que le message dise la vraie cause. La garde est celle de
  # scripts/release/ship.sh ; elle est réécrite ici parce que la source diffère — là-bas un secret de
  # la forge lu dans l'environnement d'un job, ici une ligne de .env sur le poste, et le message doit
  # nommer la variable que l'opérateur doit corriger.
  [[ $destination != -* ]] \
    || die "$1 commence par « - » : ssh y lirait une option, pas une destination. Sa valeur n'est pas affichée (NFR-9). Rien n'a été fait."
  [[ $destination =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$ ]] \
    || die "$1 ne suit pas le format « <utilisateur>@<hôte> », sans port (story 11.6). Sa valeur n'est pas affichée (NFR-9). Rien n'a été fait."
  printf -v "$2" '%s' "$destination"
}

admin_host=""
deploy_host=""
exige_destination ADMIN_HOST admin_host
exige_destination DEPLOY_HOST deploy_host

# Les mêmes options pour toutes les connexions, écrites une fois :
#   - BatchMode=yes : aucune question interactive, donc aucun script qui attend indéfiniment ;
#   - StrictHostKeyChecking=yes : l'hôte doit être celui dont le poste a déjà l'empreinte ;
#   - ConnectTimeout : un serveur muet est une anomalie, pas une attente.
ssh_options=(-o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10)

# --- le port local, avant de pousser quoi que ce soit --------------------------------------------
# Si quelque chose écoute déjà sur ce port, ssh refuserait la redirection (ExitOnForwardFailure) —
# mais surtout, les vérifications interrogeraient ce service-là en croyant parler au serveur. Le
# contrôle est **ici**, avant le premier tag : un refus ne doit rien laisser derrière lui.
if curl -sS -o /dev/null --max-time 3 "http://127.0.0.1:$port/" 2> /dev/null; then
  die "quelque chose répond déjà sur 127.0.0.1:$port : le tunnel ne pourrait pas s'y poser, et les vérifications interrogeraient ce service-là. Fermer ce qui occupe le port. Rien n'a été fait."
fi

# --- l'état des tags, relu depuis la forge --------------------------------------------------------
# « git fetch » explicite : la forge et le dépôt local divergent en silence, et un tag jugé libre sur
# un dépôt qui n'a pas relu ses références est un tag déjà pris sur la forge. Les messages de git
# portent l'adresse de la forge, qui ne s'affiche jamais (NFR-9, docs/procedures/shell-scripts.md).
git fetch --quiet --tags origin dev 2> /dev/null \
  || die "lecture de dev et des tags sur la forge impossible. Rien n'a été fait."
dev_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/dev^{commit}") \
  || die "origin/dev introuvable après lecture sur la forge. Rien n'a été fait."

# Le code de « git rev-parse » est lu, jamais avalé par « || true » : 0 le tag existe, 1 il n'existe
# pas — le cas nominal —, autre chose le dépôt est illisible. Un « || true » confondrait les deux
# derniers et laisserait la répétition continuer sur un dépôt cassé.
exige_tag_libre() { # $1 = tag
  local existant="" code=0
  existant=$(git rev-parse --verify --quiet "refs/tags/$1") || code=$?
  ((code <= 1)) || die "lecture des tags du dépôt impossible (git rev-parse, code $code). Rien n'a été fait."
  [[ -z $existant ]] \
    || refuse "le tag $1 existe déjà dans ce dépôt (relu depuis la forge) : choisir le numéro suivant. Rien n'a été fait."
}
# Les **deux** tags sont exigés libres avant le premier push : découvrir le second occupé après avoir
# poussé le premier laisserait une répétition à moitié jouée.
exige_tag_libre "$tag"
exige_tag_libre "$suivant"

# Un arbre modifié n'empêche pas la répétition — elle porte sur origin/dev, pas sur l'arbre de
# travail —, mais l'opérateur doit savoir que ce qu'il a sous la main n'est pas ce qui est répété.
pending=$(git status --porcelain 2> /dev/null) || die "lecture de l'état du dépôt impossible."
if [[ -n $pending ]]; then
  printf "%s: avertissement — %s fichier(s) modifiés dans l'arbre de travail. La répétition porte sur origin/dev (%s), pas sur eux.\n" \
    "$script_name" "$(printf '%s\n' "$pending" | wc -l)" "${dev_sha:0:7}"
fi

# --- le programme, affiché avant d'agir ------------------------------------------------------------
printf '%s: répétition générale %s puis %s, sur origin/dev (%s).\n' "$script_name" "$tag" "$suivant" "${dev_sha:0:7}"
printf '  canal        : répétition, projet %s, publié sur 127.0.0.1:%s du serveur (AD-22)\n' "$projet_repetition" "$port"
printf '  enchaînement : tag %s → attente → tunnel → vérifications → tag %s → attente → vérifications\n' "$tag" "$suivant"
printf '                 → rehearse rollback %s → attente → vérifications → rehearse stop\n' "$tag"

if [[ -z $run ]]; then
  printf "%s: rien n'a été fait. Pour jouer la répétition : scripts/rehearse-release.sh %s --run.\n" "$script_name" "$tag"
  printf "  --run pousse deux tags sur la forge, et un tag poussé ne se reprend pas : il se demande, il ne se déduit jamais.\n"
  exit 0
fi

# --- le nettoyage, et ce qu'il ne fait pas (décision A7 de la revue de spec) ------------------------
# Le tunnel est un processus **sur le poste** : le laisser ouvert est un déchet, et le piège le tue
# toujours. « rehearse stop », lui, arrête le projet distant **et supprime toutes les images -rc**
# (story 11.4) : le lancer automatiquement après un échec détruirait exactement ce qu'il faut
# inspecter — le conteneur qui tournait, ses journaux, l'image qui a servi. Une répétition qui rate
# est précisément le moment où l'on veut regarder. Le canal de répétition est par ailleurs isolé
# (projet Compose distinct, hors du réseau du proxy, boucle locale seule) : un conteneur qui survit à
# un échec ne gêne ni la production, ni le proxy, ni personne. Le piège **dit** donc que la
# répétition tourne encore, et donne la commande pour l'arrêter.
tmp=$(mktemp -d) || die "dossier temporaire impossible."
# La sortie d'erreur du tunnel y est retenue plutôt que laissée filer vers le terminal : « nettoie »
# supprime tout le dossier, ce journal compris.
tunnel_journal="$tmp/tunnel.err"
tunnel_pid=""
repetition_en_cours=0

ferme_le_tunnel() {
  [[ -n $tunnel_pid ]] || return 0
  local pid=$tunnel_pid code=0
  tunnel_pid=""
  if kill -0 "$pid" 2> /dev/null; then
    if ! kill "$pid" 2> /dev/null; then
      printf "%s: le tunnel (pid %s) n'a pas pu être arrêté : le fermer à la main.\n" "$script_name" "$pid" >&2
    fi
  fi
  # 143 est le code attendu d'un processus qu'on vient d'arrêter : il n'apprend rien, et il est lu
  # plutôt qu'avalé par un « || true », qui masquerait aussi un « wait » impossible.
  wait "$pid" 2> /dev/null || code=$?
  if ((code != 0 && code != 143)); then
    printf "%s: le tunnel (pid %s) s'est terminé avec le code %s.\n" "$script_name" "$pid" "$code" >&2
  fi
}

nettoie() {
  local code=$?
  ferme_le_tunnel
  rm -rf "$tmp"
  if ((code != 0 && repetition_en_cours == 1)); then
    printf "%s: **la répétition tourne encore sur le serveur** — elle n'est pas arrêtée automatiquement.\n" "$script_name" >&2
    printf "  « rehearse stop » supprime toutes les images -rc, donc justement ce qu'il faut inspecter après un échec.\n" >&2
    printf "  regarder : ssh <compte de déploiement> status, puis ssh <compte d'administration> docker logs …\n" >&2
    printf "  arrêter  : ssh <compte de déploiement> 'rehearse stop'\n" >&2
  fi
}
# Aucun « exec » dans ce script : il remplacerait le processus, et ce piège-ci ne tournerait jamais.
trap nettoie EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- parler au serveur ------------------------------------------------------------------------------
# Le canal restreint : « rehearse rollback », « rehearse stop » et « status » partent par le compte de
# **déploiement**, dont la clé n'ouvre rien d'autre (story 11.6). La demande part en un seul mot
# composé, comme le fait scripts/release/ship.sh, et le serveur la redécoupe lui-même.
# **Rien de ce que ssh écrit n'est affiché tel quel** (NFR-9). Quand la connexion échoue, le message
# vient de ssh lui-même et porte la destination : « ssh: Could not resolve hostname <hôte> », « <hôte>:
# Permission denied », « Warning: Permanently added '<hôte>' … ». Ces messages finissent dans un
# terminal, une capture d'écran ou un collage — et l'adresse du serveur d'Arnaud avec eux. Les deux
# destinations sont donc remplacées par leur rôle avant tout affichage.
#
# Le remplacement porte sur la destination entière **et** sur sa partie hôte seule, ssh n'écrivant pas
# toujours le « utilisateur@ » (constat bloquant de la revue du code de la PR n° 123).
masque_destinations() { # lit l'entrée standard, écrit la sortie expurgée
  local admin_hote=${admin_host#*@} deploy_hote=${deploy_host#*@}
  # « sed » avec des chaînes littérales : les valeurs viennent de .env et pourraient porter un
  # caractère que sed lirait comme une expression. Bash remplace sans rien interpréter.
  local ligne
  while IFS= read -r ligne || [[ -n $ligne ]]; do
    ligne=${ligne//"$admin_host"/<compte d\'administration>}
    ligne=${ligne//"$deploy_host"/<compte de déploiement>}
    [[ -z $admin_hote ]] || ligne=${ligne//"$admin_hote"/<hôte d\'administration>}
    [[ -z $deploy_hote ]] || ligne=${ligne//"$deploy_hote"/<hôte de déploiement>}
    printf '%s\n' "$ligne"
  done
}

sortie_serveur=""
demande_au_serveur() { # $@ = mots de la demande ; remplit sortie_serveur, rend le code de ssh
  local code=0 brute
  brute=$(ssh "${ssh_options[@]}" "$deploy_host" "$*" < /dev/null 2>&1) || code=$?
  sortie_serveur=$(printf '%s\n' "$brute" | masque_destinations)
  return "$code"
}

# Le tag réellement en service sur le canal de répétition, lu dans la sortie de « status ». La
# comparaison porte sur le **jeton entier** « eleyone-site:<tag> » : chercher la sous-chaîne
# « …-rc.1 » trouverait « …-rc.11 ». Un tag de production ne peut pas porter « -rc » — deploy-site le
# refuse —, si bien qu'un jeton -rc trouvé dans cette sortie ne peut venir que du canal de répétition.
status_porte_le_tag() { # $1 = sortie de status, $2 = tag attendu
  local jetons jeton
  shell_grep_into jetons -oE "$depot_image:[^[:space:]]+" <<< "$1"
  while IFS= read -r jeton; do
    if [[ $jeton == "$depot_image:$2" ]]; then return 0; fi
  done <<< "$jetons"
  return 1
}

# L'attente se fait par « deploy-site status », **jamais par l'API de la forge** : c'est l'état vrai
# — ce que le serveur sert —, et non l'état d'un run ; et il ne dépend pas d'un homelab qui peut
# tomber (AD-14). Appelée derrière « || », cette fonction ne profiterait pas de set -e : chaque étape
# vérifie donc son résultat elle-même (docs/procedures/shell-scripts.md).
attends_le_tag() { # $1 = tag attendu en service ; 0 en service, 1 délai dépassé
  local essai=0 echecs=0 code
  printf '%s: attente de %s sur le canal de répétition (au plus %s min).\n' \
    "$script_name" "$1" "$((attente_max * attente_delai / 60))"
  while :; do
    code=0
    demande_au_serveur status || code=$?
    if ((code == 0)); then
      echecs=0
      if status_porte_le_tag "$sortie_serveur" "$1"; then
        printf '%s: %s:%s en service sur le canal de répétition.\n' "$script_name" "$depot_image" "$1"
        return 0
      fi
    else
      # Un « status » muet n'est pas une attente : inutile de patienter trente minutes sur une clé
      # refusée ou un serveur éteint. Trois échecs **consécutifs** suffisent à trancher, et un échec
      # isolé n'interrompt pas une attente longue.
      echecs=$((echecs + 1))
      ((echecs < attente_echecs)) \
        || die "« status » n'a pas répondu $attente_echecs fois de suite (dernier code $code) : $sortie_serveur"
    fi
    ((essai < attente_max)) || return 1
    essai=$((essai + 1))
    sleep "$attente_delai"
  done
}

# --- le tunnel ----------------------------------------------------------------------------------------
# **Pas de « -f ».** Avec « -f », ssh passe en arrière-plan en se dédoublant : le processus lancé ici
# se termine aussitôt, et le PID retenu serait celui d'un processus déjà mort — le piège tuerait un
# fantôme et laisserait le tunnel ouvert. Lancé en tâche de fond du script, « $! » est le tunnel
# lui-même : on peut lui demander s'il vit encore, et le piège l'arrête vraiment.
# « ExitOnForwardFailure » : sans lui, une redirection refusée laisserait un ssh vivant et muet.
ouvre_le_tunnel() {
  printf "%s: ouverture du tunnel vers 127.0.0.1:%s, par le compte d'administration.\n" "$script_name" "$port"
  # La sortie d'erreur du tunnel est **retenue**, jamais laissée filer vers le terminal : elle
  # porterait la destination (NFR-9). Elle est relue expurgée si le tunnel meurt.
  ssh "${ssh_options[@]}" -o ExitOnForwardFailure=yes -N -L "$port:127.0.0.1:$port" "$admin_host" \
    < /dev/null > "$tunnel_journal" 2>&1 &
  tunnel_pid=$!
  local essai=0
  while :; do
    if ! kill -0 "$tunnel_pid" 2> /dev/null; then
      tunnel_pid=""
      printf '%s: ce que ssh a répondu, destinations masquées (NFR-9) :\n' "$script_name" >&2
      masque_destinations < "$tunnel_journal" >&2
      die "le tunnel SSH s'est arrêté aussitôt : port occupé, hôte inconnu du poste, ou clé refusée."
    fi
    if curl -sS -o /dev/null --max-time 5 "http://127.0.0.1:$port/" 2> /dev/null; then
      printf '%s: tunnel ouvert (pid %s).\n' "$script_name" "$tunnel_pid"
      return 0
    fi
    ((essai < tunnel_max)) \
      || die "le tunnel est ouvert mais rien ne répond sur 127.0.0.1:$port après $((tunnel_max * tunnel_delai)) s : le conteneur de répétition est-il en service ?"
    essai=$((essai + 1))
    sleep "$tunnel_delai"
  done
}

# --- les vérifications -----------------------------------------------------------------------------------
verifs_ko=0
verif_ko() { printf '  ÉCHEC   %s\n' "$*" >&2; verifs_ko=$((verifs_ko + 1)); }
verif_ok() { printf '  ok      %s\n' "$*"; }

http_code=""
interroge() { # $1 = head|get, $2 = chemin ; remplit http_code, $tmp/entetes et $tmp/corps
  local methode=$1 chemin=$2 code=0
  local -a arguments=(-sS -D "$tmp/entetes" -o "$tmp/corps" -w '%{http_code}' --max-time 20)
  # « -I » là où seuls les en-têtes comptent (AD-13) ; « get » là où le corps sert : la page
  # d'accueil livre le nom du fichier empreinté, et chaque page HTML sa langue.
  [[ $methode != head ]] || arguments+=(-I)
  : > "$tmp/entetes"
  : > "$tmp/corps"
  http_code=$(curl "${arguments[@]}" "http://127.0.0.1:$port$chemin") || code=$?
  return "$code"
}

valeur_entete=""
lit_entete() { # $1 = nom de l'en-tête, en minuscules ; remplit valeur_entete, vide s'il est absent
  local lignes ligne valeur
  valeur_entete=""
  # Les noms d'en-tête sont insensibles à la casse, et les lignes se terminent par un retour chariot.
  shell_grep_into lignes -i -- "^$1:" "$tmp/entetes"
  [[ -n $lignes ]] || return 0
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    ligne=${ligne%$'\r'}
    valeur=${ligne#*:}
    valeur=${valeur#"${valeur%%[![:space:]]*}"}
    # Un en-tête envoyé deux fois n'est pas une valeur : les deux sont jointes, la comparaison
    # échoue, et le message montre ce que le serveur a réellement envoyé.
    if [[ -z $valeur_entete ]]; then valeur_entete=$valeur; else valeur_entete="$valeur_entete | $valeur"; fi
  done <<< "$lignes"
}

# Les en-têtes qu'AD-13 fait porter à **toute** réponse, HTML ou non.
verifie_entetes_communs() { # $1 = libellé
  lit_entete x-content-type-options
  [[ $valeur_entete == nosniff ]] \
    || verif_ko "$1 : X-Content-Type-Options « $valeur_entete », attendu « nosniff » (AD-13)"
  lit_entete referrer-policy
  [[ $valeur_entete == strict-origin-when-cross-origin ]] \
    || verif_ko "$1 : Referrer-Policy « $valeur_entete », attendu « strict-origin-when-cross-origin » (AD-13)"
  lit_entete server
  # « server_tokens off » : l'en-tête dit « nginx », jamais « nginx/1.30.4 ».
  [[ $valeur_entete != *[0-9]* ]] \
    || verif_ko "$1 : l'en-tête Server porte une version, « server_tokens off » ne s'applique pas (AD-13)"
}

# Une page HTML : la CSP y est **exigée**, et le Cache-Control y vaut « no-cache ».
verifie_html() { # $1 = chemin, $2 = code HTTP attendu, $3 = langue attendue, $4 = libellé
  local code=0 vu guillemet=$'["\']?'
  interroge get "$1" || code=$?
  if ((code != 0)); then
    verif_ko "$4 : aucune réponse par le tunnel (curl, code $code)"
    return 0
  fi
  if [[ $http_code == "$2" ]]; then
    verif_ok "$4 : HTTP $http_code"
  else
    verif_ko "$4 : HTTP $http_code, attendu $2"
  fi
  lit_entete content-type
  [[ $valeur_entete == text/html* ]] \
    || verif_ko "$4 : Content-Type « $valeur_entete », attendu du HTML"
  verifie_entetes_communs "$4"
  lit_entete content-security-policy
  [[ $valeur_entete == *"default-src 'none'"* ]] \
    || verif_ko "$4 : Content-Security-Policy absente ou inattendue sur du HTML (AD-13)"
  lit_entete cache-control
  [[ $valeur_entete == no-cache ]] \
    || verif_ko "$4 : Cache-Control « $valeur_entete », attendu « no-cache » (AD-13)"
  # La langue servie. Hugo minifie et n'écrit pas les guillemets d'attribut : « <html lang=fr> ».
  shell_grep_into vu -oiE "<html[^>]*lang=$guillemet$3" "$tmp/corps"
  [[ -n $vu ]] || verif_ko "$4 : la page servie n'est pas en « $3 »"
}

# Une ressource qui n'est pas du HTML. La CSP y est **absente par conception** : le « map » de
# deploy/nginx/site.conf ne l'envoie que sur « ~^text/html », et une valeur vide supprime l'en-tête —
# les schémas D2 portent des <style> et des polices embarquées, qu'une politique « style-src 'self' »
# casserait. Exiger la CSP partout ferait échouer un fichier parfaitement conforme.
# Le Cache-Control, lui, vaut « immutable » pour un fichier empreinté d'un condensat et « no-cache »
# pour tout le reste : l'attente se déduit du nom, exactement comme le « map » la déduit de l'URI.
verifie_ressource() { # $1 = chemin, $2 = libellé
  local code=0 attendu=no-cache
  interroge head "$1" || code=$?
  if ((code != 0)); then
    verif_ko "$2 : aucune réponse par le tunnel (curl, code $code)"
    return 0
  fi
  if [[ $http_code == 200 ]]; then
    verif_ok "$2 : HTTP 200"
  else
    verif_ko "$2 : HTTP $http_code, attendu 200"
  fi
  verifie_entetes_communs "$2"
  lit_entete content-security-policy
  [[ -z $valeur_entete ]] \
    || verif_ko "$2 : Content-Security-Policy envoyée hors du HTML — la valeur vide du « map » doit supprimer l'en-tête (AD-13)"
  [[ ! $1 =~ \.[0-9a-f]{64}\.(css|svg|webp)$ ]] || attendu="public, max-age=31536000, immutable"
  lit_entete cache-control
  [[ $valeur_entete == "$attendu" ]] \
    || verif_ko "$2 : Cache-Control « $valeur_entete », attendu « $attendu » (AD-13)"
}

# Les deux ressources relevées **dans la page d'accueil servie**, et non supposées : c'est le seul
# moyen de vérifier le Cache-Control d'un fichier empreinté sans inventer un nom de fichier.
ressource_empreintee=""
ressource_svg=""
releve_les_ressources() { # lit $tmp/corps, celui de la page d'accueil
  local trouves ligne
  ressource_empreintee=""
  ressource_svg=""
  # Hugo minifie et n'écrit pas les guillemets d'attribut : le chemin est relevé tel quel, sans
  # supposer « href="…" ». Le motif est celui du « map » de nginx, condensat de 64 caractères compris.
  shell_grep_into trouves -oE '/[A-Za-z0-9._/-]*\.[0-9a-f]{64}\.(css|svg|webp)' "$tmp/corps"
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    ressource_empreintee=$ligne
    break
  done <<< "$trouves"
  shell_grep_into trouves -oE '/[A-Za-z0-9._/-]*\.svg' "$tmp/corps"
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    ressource_svg=$ligne
    break
  done <<< "$trouves"
}

# Les journaux se lisent par ssh, sur le **compte d'administration** : le tunnel ne transporte que du
# HTTP, et un « docker logs » lancé en local parlerait au démon Docker du poste.
verifie_les_journaux() { # $1 = libellé
  local code=0 identifiants identifiant="" journal lignes numeros
  identifiants=$(ssh "${ssh_options[@]}" "$admin_host" \
    "docker ps --quiet --filter label=com.docker.compose.project=$projet_repetition" < /dev/null 2>&1) || code=$?
  if ((code != 0)); then
    verif_ko "$1 : liste des conteneurs de répétition illisible (ssh, code $code)"
    return 0
  fi
  while IFS= read -r identifiant; do [[ -z $identifiant ]] || break; done <<< "$identifiants"
  # L'identifiant revient du serveur et repart dans une commande distante : il est confronté à une
  # expression ancrée avant d'y entrer, comme un tag l'est dans deploy/remote/deploy-site.sh.
  if [[ ! $identifiant =~ ^[0-9a-f]{12,64}$ ]]; then
    verif_ko "$1 : aucun conteneur du projet $projet_repetition en service, ou identifiant illisible"
    return 0
  fi
  code=0
  journal=$(ssh "${ssh_options[@]}" "$admin_host" "docker logs --tail $journal_lignes $identifiant" < /dev/null 2>&1) || code=$?
  if ((code != 0)); then
    verif_ko "$1 : journal du conteneur illisible (ssh, code $code)"
    return 0
  fi
  # AD-15 : le format de journal du conteneur ne porte ni IP, ni chaîne de requête, ni user-agent, ni
  # referer. Le **contenu** des lignes fautives n'est pas recopié — une adresse IP est précisément ce
  # qu'on ne veut voir nulle part —, seuls leurs numéros le sont.
  # L'horodatage « 25/Sep/2026:14:03:11 » ressemble à une adresse IPv6 abrégée : l'expression exige
  # donc un « :: » ou huit groupes, formes qu'un horodatage n'a pas (vérifié sur une ligne réelle).
  shell_grep_into lignes -nE '(^|[^0-9.])[0-9]{1,3}(\.[0-9]{1,3}){3}([^0-9.]|$)|([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}|[0-9a-f]{1,4}::[0-9a-f]{0,4}' <<< "$journal"
  if [[ -n $lignes ]]; then
    numeros=$(printf '%s\n' "$lignes" | cut -d: -f1 | paste -sd ',' -)
    verif_ko "$1 : le journal du conteneur de répétition porte une adresse IP, ligne(s) $numeros — contenu non recopié (AD-15, NFR-3)"
    return 0
  fi
  verif_ok "$1 : journal du conteneur de répétition sans adresse IP"
}

# Une tournée complète : la page d'accueil dans les deux langues, les deux 404, un fichier empreinté,
# un SVG s'il en existe un, et les journaux.
verifie_le_site() { # $1 = libellé de l'étape ; le nombre d'échecs reste dans verifs_ko
  verifs_ko=0
  printf '%s: vérifications — %s\n' "$script_name" "$1"
  verifie_html / 200 fr "accueil FR"
  releve_les_ressources
  verifie_html /en/ 200 en "accueil EN"
  verifie_html "$absente_fr" 404 fr "404 FR"
  verifie_html "$absente_en" 404 en "404 EN"
  if [[ -n $ressource_empreintee ]]; then
    verifie_ressource "$ressource_empreintee" "fichier empreinté ($ressource_empreintee)"
  else
    # Sans fichier empreinté, la règle « immutable » n'a rien à interroger : un contrôle qui ne lit
    # rien passerait au vert sans rien prouver.
    verif_ko "aucun fichier empreinté dans la page d'accueil servie : le Cache-Control « immutable » n'a rien à vérifier"
  fi
  if [[ -n $ressource_svg ]]; then
    verifie_ressource "$ressource_svg" "SVG ($ressource_svg)"
  else
    printf "  sans objet  aucun SVG dans la page d'accueil servie : le site n'en porte pas encore\n"
  fi
  verifie_les_journaux "journaux"
}

exige_un_site_conforme() { # $1 = libellé de l'étape
  verifie_le_site "$1"
  ((verifs_ko == 0)) \
    || refuse "$verifs_ko contrôle(s) en échec ($1) : la répétition s'arrête ici."
}

# --- les tags ---------------------------------------------------------------------------------------
pose_le_tag() { # $1 = tag
  local retrait=0
  git tag -a "$1" -m "Répétition générale $1" "$dev_sha" || die "création du tag $1 impossible."
  # Les messages de git portent l'adresse de la forge, qui ne s'affiche jamais (NFR-9) : la sortie
  # d'erreur de « push » est donc écartée, et le message ci-dessous dit ce qu'il faut savoir.
  if ! git push --quiet origin "refs/tags/$1" 2> /dev/null; then
    git tag -d "$1" > /dev/null 2>&1 || retrait=$?
    ((retrait == 0)) \
      || printf "%s: le tag local %s n'a pas pu être retiré non plus : le supprimer à la main avant de relancer.\n" "$script_name" "$1" >&2
    die "le tag $1 n'a pas pu être poussé : il a été retiré du dépôt local pour qu'une reprise le repose sur le même commit."
  fi
  printf '%s: tag %s posé sur origin/dev (%s) et poussé. Le workflow release fait le reste.\n' \
    "$script_name" "$1" "${dev_sha:0:7}"
}

# --- la répétition ------------------------------------------------------------------------------------
pose_le_tag "$tag"
# À partir d'ici, quelque chose tourne sur le serveur : le piège doit le dire si le script s'arrête.
repetition_en_cours=1
attends_le_tag "$tag" \
  || refuse "$tag n'est pas en service sur le canal de répétition après $((attente_max * attente_delai / 60)) min. Regarder le run « release » dans l'onglet Actions du dépôt sur la forge, puis « ssh <compte de déploiement> status »."

ouvre_le_tunnel
exige_un_site_conforme "$tag, première mise en service"

pose_le_tag "$suivant"
attends_le_tag "$suivant" \
  || refuse "$suivant n'est pas en service sur le canal de répétition après $((attente_max * attente_delai / 60)) min. Regarder le run « release » dans l'onglet Actions du dépôt sur la forge, puis « ssh <compte de déploiement> status »."
exige_un_site_conforme "$suivant, deuxième mise en service"

printf '%s: retour arrière vers %s.\n' "$script_name" "$tag"
code=0
demande_au_serveur rehearse rollback "$tag" || code=$?
((code == 0)) || refuse "le serveur a refusé « rehearse rollback $tag » (code $code) : $sortie_serveur"
printf '%s\n' "$sortie_serveur"
attends_le_tag "$tag" \
  || refuse "$tag n'est pas revenu en service après le retour arrière. Regarder « ssh <compte de déploiement> status »."
exige_un_site_conforme "$tag, après retour arrière"

# Tout est vérifié : la répétition peut ne rien laisser derrière elle.
ferme_le_tunnel
printf '%s: arrêt de la répétition.\n' "$script_name"
code=0
demande_au_serveur rehearse stop || code=$?
((code == 0)) || refuse "le serveur a refusé « rehearse stop » (code $code) : $sortie_serveur"
printf '%s\n' "$sortie_serveur"
repetition_en_cours=0

printf '%s: répétition générale terminée.\n' "$script_name"
printf '  %s posé, livré, vérifié\n' "$tag"
printf '  %s posé, livré, vérifié\n' "$suivant"
printf '  retour arrière vers %s, vérifié\n' "$tag"
printf '  répétition arrêtée, images -rc supprimées\n'
printf "  ni la production, ni le proxy, ni le DNS n'ont été touchés (AD-22)\n"
