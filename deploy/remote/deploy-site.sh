#!/usr/bin/env bash
# Commande forcée du serveur de production (story 11.4, AD-14, AD-15, AD-22).
#
# La clé de déploiement est restreinte dans authorized_keys par « restrict,command="…/deploy-site.sh" » :
# quoi que le client demande, c'est ce script qui tourne, et la demande lui arrive dans
# SSH_ORIGINAL_COMMAND. Une clé volée ne donne donc rien d'autre que le protocole ci-dessous.
#
#   deploy <tag>            vX.Y.Z    archive sur l'entrée standard, chargée, vérifiée, mise en service
#   rollback <tag>          vX.Y.Z    remet en service une image **déjà présente** ; ne lit rien sur stdin
#   status                            les tags en service, production et répétition
#   rehearse deploy <tag>   vX.Y.Z-rc.N   comme deploy, sur le projet site-rehearsal
#   rehearse rollback <tag> vX.Y.Z-rc.N   comme rollback, sur le projet site-rehearsal
#   rehearse stop                     arrête la répétition et supprime les images -rc
#
# Tout le reste est refusé **sans qu'aucun service ne soit touché**.
#
# ## SSH_ORIGINAL_COMMAND vient du réseau
#
# Elle est non fiable, et trois règles la tiennent :
#
#   - elle est **découpée par le shell en tableau**, jamais passée à « eval », jamais interpolée dans
#     une chaîne de commande. « deploy v1.0.0; rm -rf / » devient cinq mots dont le premier seul est
#     lu comme une commande ; le « ; » n'est qu'un caractère. « deploy $(id) » devient deux mots :
#     une expansion de paramètre ne se relit pas, donc « $(id) » reste le texte « $(id) » ;
#   - le **développement des globs est coupé (set -f) avant le découpage**, sinon « deploy v1.2.* »
#     se développerait sur le disque du serveur et pourrait désigner un tag que personne n'a demandé ;
#   - le tag est validé par une expression **ancrée**, sans zéro de tête, **avant** tout usage, et le
#     nombre d'arguments est vérifié : « deploy v1.0.0 autre-chose » est refusé.
#
# Ce qu'une demande refusée peut encore faire : rien. Aucun refus n'arrive après un appel à Docker.
#
# ## Pourquoi ce script ne dépend d'aucun fichier du dépôt (point 19 d'AGENTS.md)
#
# scripts/check-private.sh, l'aîné « recopié sur une machine distante », charge scripts/lib/image.sh
# et scripts/lib/pdf.sh par un chemin relatif à lui-même et **refuse de s'exécuter** si la
# bibliothèque manque. Ce script-ci va plus loin : il ne charge rien. La raison est le coût de la
# copie, que docs/procedures/gitea-pre-receive-hook.md paie déjà — chaque bibliothèque ajoutée est un
# fichier de plus à recopier à la main à chaque changement, et une occasion de plus de faire vivre
# sur le serveur une version qui n'est plus celle du dépôt. Le serveur de production n'est pas la
# forge : il n'a pas de dépôt, il n'a que ce dossier. Un seul fichier exécutable, donc, et aucune
# logique partagée. En échange, ce qu'il attend **à côté de lui** est vérifié comme l'aîné vérifie sa
# bibliothèque : les fichiers Compose absents ou illisibles arrêtent le script, ils ne le font pas
# sauter une étape.
#
# Codes de sortie : 0 fait ; 1 refus (demande, tag, image) ; 2 anomalie (installation, Docker).
# Prérequis : bash 4.4 ou plus récent, docker et le greffon « compose ».
# Procédure : docs/procedures/deploy-site.md
set -euo pipefail
# **Avant** tout découpage de SSH_ORIGINAL_COMMAND : la place de cette ligne dans le fichier fait
# partie de la garde. Après le découpage, elle ne servirait plus à rien.
set -f
# Les messages de ce script repartent par le canal SSH et finissent dans le journal d'un job de la
# forge. Une trace de shell y écrirait les chemins d'installation du serveur, donc le nom du compte
# de déploiement, que NFR-9 tient hors de tout ce qui se lit ailleurs que sur le serveur.
set +x

script_name=deploy-site

# --- ce qui est installé à côté ----------------------------------------------------------------------
# Le dossier « deploy » du dépôt est recopié tel quel sur le serveur : ce script est dans son
# sous-dossier « remote », les deux fichiers Compose et le .env du serveur sont un cran au-dessus.
base=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || base=
if [[ -z $base ]]; then
  printf "%s: dossier d'installation introuvable.\n" "$script_name" >&2
  exit 2
fi

depot_image=eleyone-site
projet_production=site
projet_repetition=site-rehearsal
compose_production=$base/compose.yaml
compose_repetition=$base/compose.rehearsal.yaml

die() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

# Un mot venu du réseau ne s'affiche jamais brut : « %q » le rend citable et neutralise les octets de
# contrôle, qu'un terminal ou un journal de CI interpréterait sinon comme des commandes d'affichage.
visible() { printf '%q' "$1"; }

# --- les temporaires, et leur suppression -------------------------------------------------------------
# Un seul dossier, inscrit **juste après** sa création : le piège de l'epic 7 est d'avoir un nom qui
# porte un chemin sans être celui que le nettoyage lit.
temporaires=()
trap '((${#temporaires[@]} == 0)) || rm -rf "${temporaires[@]}"' EXIT
travail=$(mktemp -d) || die "dossier temporaire impossible."
temporaires+=("$travail")

# --- la demande ---------------------------------------------------------------------------------------
if [[ -z ${SSH_ORIGINAL_COMMAND:-} ]]; then
  refuse "aucune demande. Cette clé n'ouvre pas de session : elle ne porte que les commandes de $script_name."
fi
# Découpage en mots par le shell, globs coupés plus haut. Pas de « mapfile » ici : c'est exactement le
# découpage par IFS que l'on veut, et lui seul.
# shellcheck disable=SC2206
demande=($SSH_ORIGINAL_COMMAND)
if ((${#demande[@]} == 0)); then
  refuse "demande vide. Commandes : deploy <tag>, rollback <tag>, status, rehearse deploy|rollback <tag>, rehearse stop."
fi

inconnue() { # $1 = le mot fautif
  refuse "demande inconnue « $(visible "$1") ». Commandes : deploy <tag>, rollback <tag>, status, rehearse deploy|rollback <tag>, rehearse stop. Aucun service n'a été touché."
}

canal=production
action=${demande[0]}
arguments=("${demande[@]:1}")
case $action in
  deploy | rollback | status) ;;
  rehearse)
    canal=repetition
    if ((${#demande[@]} < 2)); then
      refuse "« rehearse » attend une commande : deploy <tag>, rollback <tag> ou stop. Aucun service n'a été touché."
    fi
    action=${demande[1]}
    arguments=("${demande[@]:2}")
    case $action in
      deploy | rollback | stop) ;;
      *) inconnue "rehearse $action" ;;
    esac
    ;;
  *) inconnue "$action" ;;
esac

# Le nombre d'arguments, avant le tag : « deploy v1.0.0 autre-chose » ne doit pas même être lu comme
# un tag juste suivi de bruit.
#
# Le libellé du refus est construit des seuls mots **déjà validés** par le « case » ci-dessus, jamais
# de « ${demande[*]} » : pour « status bidule », ce tableau-là porte encore le mot de trop, venu du
# réseau, et le message l'afficherait brut.
libelle=$action
if [[ $canal == repetition ]]; then
  libelle="rehearse $action"
fi
attendus=1
case $action in
  status | stop) attendus=0 ;;
esac
if ((${#arguments[@]} != attendus)); then
  if ((attendus == 0)); then
    refuse "« $libelle » n'attend aucun argument, ${#arguments[@]} reçu(s). Aucun service n'a été touché."
  fi
  refuse "« $libelle » attend exactement un tag, ${#arguments[@]} reçu(s). Aucun service n'a été touché."
fi

# --- le tag, ancré, avant tout usage --------------------------------------------------------------------
# Deux expressions **disjointes**, une par canal : un tag accepté par l'une est refusé par l'autre, et
# c'est cela qui sépare les canaux. Les zéros de tête sont refusés (« v01.2.3 ») comme le veut la
# numérotation sémantique et comme le fait déjà scripts/release/build-image.sh : deux tags qui
# désignent la même version produiraient deux images sur le serveur. L'ancrage « ^…$ » ferme la
# chaîne entière.
tag_production='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
tag_repetition='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)-rc\.(0|[1-9][0-9]*)$'

valide_tag() { # $1 = canal, $2 = tag
  local ou_quoi
  case $1 in
    production)
      if [[ $2 =~ $tag_production ]]; then return 0; fi
      # Le croisement des canaux a son propre message : c'est la faute qu'AD-22 existe pour empêcher,
      # et la confondre avec « tag mal formé » ferait chercher une faute de frappe là où il y a une
      # erreur de canal.
      if [[ $2 =~ $tag_repetition ]]; then
        refuse "tag $(visible "$2") refusé en production : « -rc » désigne le canal de répétition (AD-22). Aucun service n'a été touché."
      fi
      ou_quoi="la production attend « vX.Y.Z », sans zéro de tête" ;;
    repetition)
      if [[ $2 =~ $tag_repetition ]]; then return 0; fi
      if [[ $2 =~ $tag_production ]]; then
        refuse "tag $(visible "$2") refusé en répétition : un tag sans « -rc » désigne la production (AD-22). Aucun service n'a été touché."
      fi
      ou_quoi="la répétition attend « vX.Y.Z-rc.N », sans zéro de tête" ;;
    *) die "canal inconnu « $1 » : anomalie du script." ;;
  esac
  refuse "tag $(visible "$2") refusé : $ou_quoi. Aucun service n'a été touché."
}

tag=""
if ((attendus == 1)); then
  tag=${arguments[0]}
  valide_tag "$canal" "$tag"
fi

# --- ce qu'il faut pour agir ------------------------------------------------------------------------------
# À partir d'ici seulement, on touche à la machine. Tout ce qui précède refuse sans rien lancer.
command -v docker > /dev/null 2>&1 || die "docker introuvable sur ce serveur."

compose_du_canal=$compose_production
projet_du_canal=$projet_production
if [[ $canal == repetition ]]; then
  compose_du_canal=$compose_repetition
  projet_du_canal=$projet_repetition
fi

# Un fichier Compose absent **arrête** le script, il ne le fait pas continuer sans lui : c'est la
# règle de l'aîné (scripts/check-private.sh et ses bibliothèques). « rehearse stop » et « status »
# n'en ont pas besoin — ils travaillent par nom de projet — et ne l'exigent donc pas.
exige_compose() {
  [[ -f $compose_du_canal && -r $compose_du_canal ]] \
    || die "fichier Compose du canal $canal absent ou illisible : l'installation du serveur est incomplète (docs/procedures/deploy-site.md)."
}

# Enveloppe unique des appels à Docker : le code est rendu, la sortie est gardée dans un fichier du
# dossier de travail. Écrite une fois (docs/procedures/shell-scripts.md) plutôt qu'une fois par appel.
docker_rc=0
docker_sortie=$travail/sortie
docker_appel() { # $@ = arguments de docker ; sortie et erreur dans $docker_sortie
  docker_rc=0
  docker "$@" > "$docker_sortie" 2>&1 || docker_rc=$?
  return 0
}

# La sortie de « docker load » est la seule qui vienne de l'archive, donc du réseau : un nom d'image
# forgé y passerait ses octets de contrôle jusqu'au journal du job. Elle s'affiche citée, ligne à
# ligne. Les autres sorties de Docker viennent de l'état du serveur et de tags déjà validés.
# La lecture retient la dernière ligne même sans saut de ligne final (« || [[ -n $ligne ]] »,
# comme scripts/release/build-image.sh) : sans cela, une sortie qui ne finit pas par un saut de
# ligne perd son dernier élément — une image chargée de plus, ou un tag de moins à supprimer.
affiche_sortie_citee() {
  local ligne
  while IFS= read -r ligne || [[ -n $ligne ]]; do printf '%q\n' "$ligne" >&2; done < "$docker_sortie"
}

# --- status -------------------------------------------------------------------------------------------------
# Ne touche à rien : il lit les conteneurs en cours par l'étiquette de projet que Compose leur pose.
tag_en_service() { # $1 = projet ; remplit « en_service »
  en_service=""
  docker_appel ps --filter "label=com.docker.compose.project=$1" --format '{{.Image}}'
  ((docker_rc == 0)) || return "$docker_rc"
  en_service=$(head -n 1 "$docker_sortie")
  return 0
}

if [[ $action == status ]]; then
  anomalie=0
  for couple in "production:$projet_production" "répétition:$projet_repetition"; do
    nom=${couple%%:*}
    projet=${couple#*:}
    if tag_en_service "$projet"; then
      printf '%s: %s : %s\n' "$script_name" "$nom" "${en_service:-aucun conteneur en service}"
    else
      printf '%s: %s : état illisible.\n' "$script_name" "$nom" >&2
      cat "$docker_sortie" >&2
      anomalie=1
    fi
  done
  ((anomalie == 0)) || exit 2
  exit 0
fi

# --- les images du dépôt eleyone-site ---------------------------------------------------------------------
# « docker image ls » trie de la plus récente à la plus ancienne ; l'ordre de la liste est celui de la
# rétention. Les tags qui ne sont pas ceux d'un canal connu (« <none> », un tag posé à la main) sont
# ignorés : ce script ne supprime que ce qu'il sait nommer.
liste_des_tags() { # $1 = expression du canal ; remplit le tableau « tags »
  tags=()
  docker_appel image ls --format '{{.Tag}}' "$depot_image"
  ((docker_rc == 0)) || return "$docker_rc"
  local ligne
  while IFS= read -r ligne || [[ -n $ligne ]]; do
    [[ -n $ligne ]] || continue
    [[ $ligne =~ $1 ]] || continue
    tags+=("$ligne")
  done < "$docker_sortie"
  return 0
}

supprime_images() { # $@ = tags ; rend 1 si l'une des suppressions échoue
  local echec=0 t
  for t in "$@"; do
    docker_appel image rm "$depot_image:$t"
    if ((docker_rc != 0)); then
      printf '%s: suppression impossible de %s:%s.\n' "$script_name" "$depot_image" "$t" >&2
      cat "$docker_sortie" >&2
      echec=1
    else
      printf '%s: image %s:%s supprimée.\n' "$script_name" "$depot_image" "$t"
    fi
  done
  return "$echec"
}

# --- rehearse stop -------------------------------------------------------------------------------------------
# Par nom de projet, sans fichier Compose : « docker compose -p <projet> down » retrouve les
# conteneurs par leurs étiquettes (vérifié sur Compose v5.5.1). C'est ce qui évite d'exiger SITE_TAG
# pour arrêter un service — le « :? » du fichier Compose ferait échouer l'interpolation, et un arrêt
# ne doit pas dépendre du tag qui tourne.
if [[ $action == stop ]]; then
  docker_appel compose --project-name "$projet_repetition" down
  if ((docker_rc != 0)); then
    printf '%s: arrêt du projet %s impossible.\n' "$script_name" "$projet_repetition" >&2
    cat "$docker_sortie" >&2
    exit 2
  fi
  printf '%s: projet %s arrêté.\n' "$script_name" "$projet_repetition"
  # Une répétition est faite pour ne rien laisser (constat S3) : **toutes** les images -rc partent,
  # et elles seules. La rétention des trois plus récentes ne vaut que pour la production.
  liste_des_tags "$tag_repetition" || die "liste des images illisible : $(cat "$docker_sortie")"
  if ((${#tags[@]} == 0)); then
    printf '%s: aucune image -rc à supprimer.\n' "$script_name"
    exit 0
  fi
  supprime_images "${tags[@]}" || exit 2
  exit 0
fi

# --- deploy et rollback ------------------------------------------------------------------------------------
exige_compose
image=$depot_image:$tag

if [[ $action == deploy ]]; then
  # L'archive arrive sur l'entrée standard, par le canal SSH. Rien n'en est écrit sur le disque :
  # « docker load » la lit au fil de l'eau et décompresse lui-même.
  docker_appel load
  if ((docker_rc != 0)); then
    printf '%s: « docker load » a échoué : archive illisible ou tronquée, ou démon Docker indisponible.\n' "$script_name" >&2
    affiche_sortie_citee
    exit 1
  fi
  # Troisième garde contre le croisement des canaux (constat S2) : le tag demandé a été validé, mais
  # rien ne dit encore que l'archive porte **cette** image-là. Une archive nommée autrement mettrait
  # en service ce que l'émetteur veut, pas ce que la demande dit.
  chargees=()
  while IFS= read -r ligne || [[ -n $ligne ]]; do
    [[ $ligne == "Loaded image: "* ]] || continue
    chargees+=("${ligne#"Loaded image: "}")
  done < "$docker_sortie"
  if ((${#chargees[@]} != 1)); then
    printf "%s: l'archive a chargé %s image(s) nommée(s), une seule est attendue (%s). Aucun service n'a été touché.\n" \
      "$script_name" "${#chargees[@]}" "$image" >&2
    affiche_sortie_citee
    exit 1
  fi
  if [[ ${chargees[0]} != "$image" ]]; then
    refuse "l'image chargée s'appelle $(visible "${chargees[0]}") et non $image. Aucun service n'a été touché."
  fi
  printf '%s: image %s chargée.\n' "$script_name" "$image"
else
  # rollback : **rien** n'est lu sur l'entrée standard et aucune archive n'est chargée. L'image doit
  # être déjà présente, sinon « up » tirerait ou échouerait sur une image que personne n'a vérifiée.
  docker_appel image inspect "$image"
  if ((docker_rc != 0)); then
    refuse "image $image absente de ce serveur : un retour arrière ne charge rien, il remet en service ce qui est déjà là. Aucun service n'a été touché."
  fi
fi

# Mise en service. SITE_TAG est posée dans l'environnement de cette commande seulement : elle
# n'existe dans aucun fichier du serveur, et le « :? » du fichier Compose fait échouer l'appel si
# elle venait à manquer. L'entrée standard est fermée : après « docker load » elle est à sa fin, et
# pour un rollback elle ne doit pas être lue du tout.
SITE_TAG=$tag docker compose --project-name "$projet_du_canal" -f "$compose_du_canal" up -d \
  < /dev/null > "$docker_sortie" 2>&1 || docker_rc=$?
if ((docker_rc != 0)); then
  printf '%s: mise en service de %s impossible.\n' "$script_name" "$image" >&2
  cat "$docker_sortie" >&2
  exit 2
fi
cat "$docker_sortie"
printf '%s: %s en service sur le projet %s.\n' "$script_name" "$image" "$projet_du_canal"

# --- rétention ------------------------------------------------------------------------------------------------
# Trois images de production gardées (AD-14), et **seulement** en production : les images -rc n'y sont
# pas soumises (constat S3), « rehearse stop » les supprime toutes.
if [[ $canal != production || $action != deploy ]]; then
  exit 0
fi
liste_des_tags "$tag_production" || die "liste des images illisible : $(cat "$docker_sortie")"
a_supprimer=()
gardes=0
for t in "${tags[@]}"; do
  if ((gardes < 3)); then
    gardes=$((gardes + 1))
    continue
  fi
  # Le tag qu'on vient de mettre en service n'est jamais supprimé, même s'il n'est pas dans les trois
  # plus récents : « docker image ls » trie par date de **construction** de l'image, et redéployer un
  # tag ancien le mettrait en service puis le supprimerait dans la foulée. C'est la seule exception
  # aux trois, et elle ne peut garder qu'une image de plus.
  if [[ $t == "$tag" ]]; then continue; fi
  a_supprimer+=("$t")
done
if ((${#a_supprimer[@]} == 0)); then
  exit 0
fi
supprime_images "${a_supprimer[@]}" || exit 2
exit 0
