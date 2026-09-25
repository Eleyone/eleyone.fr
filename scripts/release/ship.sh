#!/usr/bin/env bash
# Livraison de l'image vers le serveur de production (story 11.5, AD-14, AD-22).
#
#   scripts/release/ship.sh <tag>          vX.Y.Z (production) ou vX.Y.Z-rc.N (répétition)
#   scripts/release/ship.sh --check-env    vérifie seulement ce que l'environnement doit porter
#
# **Livraison sans registre** (AD-14) : l'image est exportée, compressée et poussée par SSH dans un
# seul flux, « docker save | gzip | ssh ». Rien n'est écrit sur le disque du runner, et le serveur
# lit l'archive sur son entrée standard (deploy/remote/deploy-site.sh, story 11.4).
#
# **Les deux canaux sont exclusifs.** Un tag « vX.Y.Z » donne « deploy <tag> », un tag
# « vX.Y.Z-rc.N » donne « rehearse deploy <tag> ». Jamais les deux : deux expressions **disjointes**
# choisissent la commande, et c'est cette variable unique qui part. Lu comme une séquence, le
# critère d'acceptation aurait fait partir un « -rc » en production (constat P1 de la revue de spec).
# Dans les deux cas, la livraison se termine par un « status », dont la sortie s'affiche : c'est la
# seule confirmation que le job donne de ce qui tourne réellement (constat P2).
#
# Ce qu'il exige dans l'environnement — ce que la CI livre en secrets Gitea (AD-14) :
#
#   - DEPLOY_SSH_KEY     la clé privée du compte de déploiement ;
#   - DEPLOY_HOST        la destination, au format « utilisateur@hôte ». **Il n'y a pas de secret
#                        DEPLOY_USER** : l'architecture ne liste que trois secrets de déploiement, et
#                        un nom de compte séparé n'ajouterait qu'un second secret à tenir à jour
#                        (décision A5 de la revue de spec). Le format n'étant pas devinable, la
#                        procédure le dit noir sur blanc ;
#   - DEPLOY_KNOWN_HOSTS l'empreinte de l'hôte, pour « StrictHostKeyChecking=yes ».
#
# Aucune de ces valeurs n'est affichée, ni dans un message, ni dans un journal : un message nomme la
# variable, jamais son contenu (NFR-9). La trace est coupée dès l'en-tête, même sous « bash -x ».
# Codes de sortie : 0 livrée ; 1 refus (tag, variable, refus du serveur) ; 2 anomalie (outil absent,
# image absente, temporaire impossible, transport en échec).
# Procédure : docs/procedures/release-workflow.md
set -euo pipefail
# Même lancé avec « bash -x », la trace s'arrête ici : la clé privée passe par ce script, et une
# trace de shell l'écrirait en clair dans le journal de la CI (modèle de scripts/release/build-image.sh).
set +x
# La clé privée et les empreintes naissent lisibles par leur seul propriétaire, et ssh **refuse** de
# lire une clé plus ouverte. Mesuré (point 10 : une règle sur le comportement d'un outil n'est vraie
# qu'une fois lancée) : « mktemp » crée en 0600 quel que soit l'umask, si bien que retirer cette
# ligne seule ne change rien aujourd'hui — le cas de test qui affirme les droits continue de passer.
# Elle reste parce qu'elle garde **la suite** : dès qu'un fichier naîtrait autrement qu'avec mktemp,
# il naîtrait en 0644. La mutation qui remplace mktemp par une redirection le montre, et elle fait
# alors tomber le cas.
umask 077

script_name=release/ship
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"

die() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

# Le dépôt d'images. Le même nom vit dans scripts/release/build-image.sh, qui le construit, et dans
# deploy/remote/deploy-site.sh, qui ne peut rien partager avec le dépôt (il est recopié seul sur le
# serveur). Les trois ne peuvent pas lire une source commune ; c'est donc un cas de test qui les
# tient égaux (scripts/tests/test-ship.sh, point 19 d'AGENTS.md).
depot_image=eleyone-site

# --- les arguments, avant tout le reste ---------------------------------------------------------------
mode=livraison
tag=""
case $# in
  1)
    if [[ $1 == --check-env ]]; then
      mode=verification
    else
      tag=$1
    fi
    ;;
  *) die "usage : $0 <tag>, où <tag> vaut vX.Y.Z ou vX.Y.Z-rc.N ; $0 --check-env pour n'éprouver que l'environnement." ;;
esac

# --- le tag et son canal ------------------------------------------------------------------------------
# Deux expressions **disjointes**, une par canal, ancrées « ^…$ » et sans zéro de tête, comme
# scripts/release/build-image.sh et deploy/remote/deploy-site.sh : deux tags qui désignent la même
# version produiraient deux images sur le serveur. Un tag accepté par l'une est refusé par l'autre,
# et c'est cela qui rend les canaux exclusifs : « commande » ne porte qu'une valeur, toujours.
motif_production='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
motif_repetition='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)-rc\.(0|[1-9][0-9]*)$'

canal=""
commande=""
if [[ $mode == livraison ]]; then
  if [[ $tag =~ $motif_production ]]; then
    canal=production
    commande="deploy $tag"
  elif [[ $tag =~ $motif_repetition ]]; then
    canal=repetition
    commande="rehearse deploy $tag"
  else
    refuse "tag « $tag » refusé : une mise en ligne porte « vX.Y.Z », une répétition « vX.Y.Z-rc.N » (AD-14). Rien n'a été envoyé."
  fi
fi

# --- ce que l'environnement doit porter -----------------------------------------------------------------
# Les absences sont **toutes** relevées avant de refuser : une CI mal configurée apprend d'un coup ce
# qui lui manque, au lieu d'un nom par exécution (garde de l'aîné scripts/release/build-image.sh).
variables=(DEPLOY_SSH_KEY DEPLOY_HOST DEPLOY_KNOWN_HOSTS)
manquantes=()
for nom in "${variables[@]}"; do
  [[ -n ${!nom:-} ]] || manquantes+=("$nom")
done
((${#manquantes[@]} == 0)) \
  || refuse "variable(s) de livraison absente(s) de l'environnement : ${manquantes[*]} (AD-14, secrets de la forge). Rien n'a été envoyé."

# Un « - » en tête ferait lire la destination comme une **option** par ssh : « -E/tmp/journal » ou
# « -ofoo=bar » deviendraient des réglages que personne n'a demandés, et la destination viendrait
# alors du reste de la ligne. Ce refus précède le contrôle de format pour que le message dise la
# vraie cause.
[[ $DEPLOY_HOST != -* ]] \
  || refuse "DEPLOY_HOST commence par « - » : ssh y lirait une option, pas une destination. Sa valeur n'est pas affichée (NFR-9). Rien n'a été envoyé."
[[ $DEPLOY_HOST =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$ ]] \
  || refuse "DEPLOY_HOST ne suit pas le format « utilisateur@hôte » (AD-14, décision A5). Sa valeur n'est pas affichée (NFR-9). Rien n'a été envoyé."

# Une clé publique à la place de la clé privée est l'erreur de configuration la plus plausible de la
# story 11.6 : ssh échouerait alors à la connexion, après que « docker save » a commencé à couler.
[[ $DEPLOY_SSH_KEY == *"PRIVATE KEY"* ]] \
  || refuse "DEPLOY_SSH_KEY ne porte pas de clé privée OpenSSH (« -----BEGIN … PRIVATE KEY----- » attendu). Sa valeur n'est pas affichée (NFR-9). Rien n'a été envoyé."

# Un fichier **présent mais vide** n'est pas une conformité : le piège est consigné
# (docs/procedures/shell-scripts.md, story 0.8). Des empreintes faites de commentaires seuls
# donneraient un known_hosts valide et vide, et « StrictHostKeyChecking=yes » refuserait la
# connexion une fois l'archive déjà en train de partir.
empreinte_utile=0
while IFS= read -r ligne || [[ -n $ligne ]]; do
  [[ $ligne =~ ^[[:space:]]*(#|$) ]] || { empreinte_utile=1; break; }
done <<< "$DEPLOY_KNOWN_HOSTS"
((empreinte_utile == 1)) \
  || refuse "DEPLOY_KNOWN_HOSTS ne porte aucune empreinte : que des lignes vides ou des commentaires. La vérification stricte de l'hôte n'aurait rien à comparer. Rien n'a été envoyé."

if [[ $mode == verification ]]; then
  printf '%s: environnement de livraison complet (%s).\n' "$script_name" "${variables[*]}"
  exit 0
fi

# --- les outils, puis l'image -----------------------------------------------------------------------------
# Tout ce qui précède refuse **sans rien écrire et sans rien envoyer**. À partir d'ici seulement, le
# script touche à la machine (garde de l'aîné : les refus arrivent avant tout effet de bord).
for outil in docker gzip ssh; do
  command -v "$outil" > /dev/null 2>&1 \
    || die "$outil est introuvable : la livraison est « docker save | gzip | ssh » (AD-14). Rien n'a été envoyé."
done

image=$depot_image:$tag
docker image inspect "$image" > /dev/null 2>&1 \
  || die "image $image absente de ce runner : scripts/release/build-image.sh doit tourner avant. Rien n'a été envoyé."

# --- les fichiers temporaires, et leur suppression -------------------------------------------------------------
# Le nettoyage ne lit que « temporaires », jamais une variable qui porte aussi un chemin : confondre
# les deux sens avait laissé deux temporaires par exécution dans C21 (constat B1, rétrospective de
# l'epic 7). Chaque fichier y entre **juste après** sa création, jamais après son remplissage : un
# échec d'écriture laisserait sinon la clé privée sur le disque du runner.
temporaires=()
trap '((${#temporaires[@]} == 0)) || rm -f "${temporaires[@]}"' EXIT

cle=$(mktemp) || die "fichier temporaire de la clé impossible."
temporaires+=("$cle")
connus=$(mktemp) || die "fichier temporaire des empreintes impossible."
temporaires+=("$connus")

# « printf '%s\n' » garantit le saut de ligne final : OpenSSH refuse une clé qui n'en a pas, et un
# secret de forge saisi à la main en manque souvent. Un saut de ligne en trop ne gêne pas la lecture.
printf '%s\n' "$DEPLOY_SSH_KEY" > "$cle" || die "écriture impossible dans le fichier temporaire de la clé."
printf '%s\n' "$DEPLOY_KNOWN_HOSTS" > "$connus" || die "écriture impossible dans le fichier temporaire des empreintes."

# Les options sont écrites **une seule fois** (docs/procedures/shell-scripts.md) : la livraison et le
# « status » qui la suit partent avec exactement les mêmes.
#   - StrictHostKeyChecking=yes : l'hôte doit être celui dont on a l'empreinte, sans quoi la clé
#     privée partirait vers une machine que personne n'a vérifiée ;
#   - UserKnownHostsFile : ce fichier-ci, et pas celui du compte du runner ;
#   - IdentitiesOnly=yes : la clé donnée, et pas celles qu'un agent proposerait ;
#   - BatchMode=yes : aucune question interactive. Sans lui, un mot de passe demandé bloquerait le
#     job jusqu'au délai du runner au lieu d'échouer tout de suite.
ssh_options=(
  -o StrictHostKeyChecking=yes
  -o "UserKnownHostsFile=$connus"
  -o IdentitiesOnly=yes
  -o BatchMode=yes
  -i "$cle"
)

# --- la livraison ------------------------------------------------------------------------------------------------
printf '%s: livraison de %s vers le canal %s, commande « %s ».\n' "$script_name" "$image" "$canal" "$commande"

# **Le piège du pipeline.** « docker save | gzip | ssh » est un pipeline de trois commandes, et le
# projet s'est déjà fait mordre deux fois par leurs codes de retour (docs/procedures/shell-scripts.md).
# Le code d'un pipeline est celui de sa **dernière** commande — « set -o pipefail » le corrige en
# rendant le dernier code non nul —, mais ici même pipefail ne suffirait pas à dire **laquelle** des
# trois a lâché, et c'est la seule chose qui compte : un « docker save » interrompu envoie une
# archive tronquée que le serveur recevrait en entier. PIPESTATUS est donc lu dans les deux branches
# du « if », **avant toute autre commande** : une affectation intermédiaire l'écraserait (vérifié).
etats=()
if docker save "$image" | gzip | ssh "${ssh_options[@]}" "$DEPLOY_HOST" "$commande"; then
  etats=("${PIPESTATUS[@]}")
else
  etats=("${PIPESTATUS[@]}")
fi
((${#etats[@]} == 3)) || die "codes du pipeline de livraison illisibles (${#etats[@]} au lieu de 3) : anomalie du script."

# **L'ordre de lecture est celui des causes, pas celui du pipeline.** Un ssh qui s'arrête ferme le
# tube, et « docker save » meurt alors d'un SIGPIPE (code 141) : lire l'amont d'abord ferait accuser
# l'exportation de l'image là où le transport a lâché. Le canal aval est donc jugé le premier, et
# l'amont n'est cité qu'en complément.
if ((etats[2] != 0)); then
  ((etats[0] == 0 && etats[1] == 0)) \
    || printf "%s: l'amont du tube a lâché aussi (docker save %s, gzip %s) : c'est la conséquence attendue d'un canal fermé, pas une seconde panne.\n" \
      "$script_name" "${etats[0]}" "${etats[1]}" >&2
  ((etats[2] != 1)) \
    || refuse "le serveur a refusé « $commande » (deploy-site, code 1) : le message du serveur est au-dessus."
  die "la livraison par ssh a échoué (code ${etats[2]}) : anomalie du serveur, du transport ou de la connexion."
fi

# ssh a rendu 0 : le serveur a donc lu le flux jusqu'au bout. Si l'amont a lâché, ce qu'il a lu est
# une archive **tronquée**, et c'est le pire résultat possible de cette story.
((etats[0] == 0)) \
  || die "« docker save » a échoué (code ${etats[0]}) : l'archive envoyée est tronquée. Le serveur refuse une archive illisible, mais ne considérez pas $image comme livrée."
((etats[1] == 0)) \
  || die "« gzip » a échoué (code ${etats[1]}) : l'archive envoyée est tronquée. Ne considérez pas $image comme livrée."
printf '%s: %s livrée par « %s ».\n' "$script_name" "$image" "$commande"

# --- la confirmation ---------------------------------------------------------------------------------------------
# « status » part dans les deux canaux et sa sortie s'affiche telle quelle : c'est la seule chose que
# le job sache dire de ce qui tourne réellement sur le serveur (constat P2). Son entrée standard est
# fermée : elle ne doit rien lire de ce qui reste du flux précédent.
printf '%s: état du serveur après livraison.\n' "$script_name"
code_status=0
ssh "${ssh_options[@]}" "$DEPLOY_HOST" status < /dev/null || code_status=$?
((code_status == 0)) \
  || die "« status » n'a pas répondu (code $code_status) : $image est livrée, mais l'état du serveur n'a pas pu être lu."
