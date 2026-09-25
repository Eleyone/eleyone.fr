#!/usr/bin/env bash
# Enveloppe de mise en ligne (story 11.3, AD-9, AD-12, AD-13, AD-14, AD-21).
#
#   scripts/release/build-image.sh <tag>     vX.Y.Z (mise en ligne) ou vX.Y.Z-rc.N (répétition)
#
# **Elle ne construit rien elle-même.** Une seule commande de build vit dans le dépôt,
# scripts/build-image.sh, et c'est elle qui porte le « docker build », les secrets BuildKit et les
# arguments (AD-13, décidé par Arnaud le 21/09/2026). Ce script est ce qui se trouve **au-dessus** :
# il valide le tag, relève les valeurs de l'environnement — celles que la CI livre en secrets —, les
# écrit dans des fichiers temporaires, délègue, et supprime ces fichiers même en cas d'échec.
#
# Ce qu'il exige dans l'environnement :
#
#   - les HUGO_LEGAL_* d'AD-9. **Leurs noms ne sont pas recopiés ici** : ils sont lus dans
#     ci/legal-placeholder.env, dont C18 (scripts/checks/content.sh) vérifie qu'il porte exactement
#     les noms attendus. Une quatrième copie de cette liste serait la faute que le point 19
#     d'AGENTS.md nomme, celle qui a laissé les deux noms de CV vivre sous quatre orthographes ;
#   - PRIVATE_PATTERNS, la liste des motifs interdits, une par ligne. .dockerignore exclut
#     docs/private/ du contexte de build : sans ce second secret, C21 ne confronte rien et C22 rend
#     une anomalie (AD-12, AD-21).
#
# Aucune valeur n'est affichée, ni dans un message, ni dans un journal : un message nomme la
# variable, jamais son contenu. La trace est coupée dès l'en-tête, même sous « bash -x ».
# Codes de sortie : 0 image construite, 1 refus (tag, variable absente, build en échec), 2 anomalie.
# Procédure : docs/procedures/build-image.md
set -euo pipefail
# Même lancé avec « bash -x », la trace s'arrête ici : les valeurs légales passent par ce script,
# et une trace de shell les écrirait en clair dans le journal de la CI (modèle de scripts/env.sh).
set +x

script_name=release/build-image
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
. "$root/scripts/lib/shell.sh"

die() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 2; }
refuse() { printf '%s: %s\n' "$script_name" "$*" >&2; exit 1; }

# --- le tag, avant tout le reste --------------------------------------------------------------------
(($# == 1)) || die "usage : $0 <tag>, où <tag> vaut vX.Y.Z ou vX.Y.Z-rc.N."
tag=$1

# Les zéros de tête sont refusés (« v01.2.3 »), comme le veut la numérotation sémantique : deux tags
# qui désignent la même version produiraient deux images différentes sur le serveur. L'ancrage
# ^…$ ferme la chaîne entière — un saut de ligne suivi d'autre chose ne passe pas, « $ » ne valant
# en bash que la fin de la chaîne.
[[ $tag =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-rc\.(0|[1-9][0-9]*))?$ ]] \
  || refuse "tag « $tag » refusé : une mise en ligne porte « vX.Y.Z », une répétition « vX.Y.Z-rc.N » (AD-14). Aucun build n'a été lancé."

# --- les fichiers temporaires, et leur suppression ---------------------------------------------------
# Le nettoyage ne lit que « temporaires », jamais une variable qui porte aussi un chemin : confondre
# les deux sens avait laissé deux temporaires par exécution dans C21 (constat B1, rétrospective de
# l'epic 7). Ici, ces temporaires portent les vraies valeurs légales : les laisser sur le disque d'un
# runner serait le défaut que tout ce montage existe pour empêcher.
temporaires=()
trap '((${#temporaires[@]} == 0)) || rm -f "${temporaires[@]}"' EXIT

# --- les noms des valeurs légales, lus et non recopiés -----------------------------------------------
reference=$root/ci/legal-placeholder.env
[[ -f $reference && -r $reference ]] \
  || die "ci/legal-placeholder.env introuvable ou illisible : c'est lui qui nomme les variables d'AD-9 (C18)."
shell_grep_into noms_bruts -oE '^HUGO_LEGAL_[A-Z0-9_]+=' "$reference"
noms=()
while IFS= read -r ligne; do
  [[ -n $ligne ]] || continue
  noms+=("${ligne%=}")
done <<< "$noms_bruts"
((${#noms[@]} > 0)) \
  || die "aucune variable HUGO_LEGAL_* dans ci/legal-placeholder.env : la liste d'AD-9 est vide, rien ne serait injecté."

# --- ce que l'environnement doit porter --------------------------------------------------------------
# Les absences sont **toutes** relevées avant de refuser : une CI mal configurée apprend d'un coup ce
# qui lui manque, au lieu d'un nom par exécution.
manquantes=()
for nom in "${noms[@]}"; do
  [[ -n ${!nom:-} ]] || manquantes+=("$nom")
done
((${#manquantes[@]} == 0)) \
  || refuse "valeur(s) légale(s) absente(s) de l'environnement : ${manquantes[*]} (AD-9). Aucun docker build n'a été lancé."

# Trois refus sur la **forme** d'une valeur, tous avant le build, tous sans citer la valeur :
#
#   - un guillemet double : le fichier écrit plus bas est relu par scripts/lib/dotenv.sh, qui coupe
#     une valeur entre guillemets au guillemet suivant. La valeur serait tronquée en silence, et
#     l'image servirait des mentions légales fausses sans qu'aucun contrôle ne le voie ;
#   - un saut de ligne : un fichier dotenv y lirait deux entrées, dont la seconde n'est pas une clé ;
#   - « VALEUR-FACTICE » : c'est la garde 8 de scripts/build-image.sh, qui refuse les **fichiers** de
#     travail du dépôt comme secret de mise en ligne. Par l'environnement, ces mêmes valeurs
#     entreraient sans passer par un fichier. C15 les rattraperait dans la sortie, mais cinq minutes
#     de build plus tard, et une répétition générale serait signée de valeurs factices.
for nom in "${noms[@]}"; do
  valeur=${!nom}
  [[ $valeur != *'"'* ]] \
    || refuse "$nom contient un guillemet double, que le chargeur des valeurs légales tronque en silence (scripts/lib/dotenv.sh)."
  [[ $valeur != *$'\n'* ]] \
    || refuse "$nom contient un saut de ligne : un fichier de valeurs en lirait deux entrées, dont la seconde serait perdue."
  [[ $valeur != *VALEUR-FACTICE* ]] \
    || refuse "$nom porte encore une valeur factice : une mise en ligne ne se construit pas avec ci/legal-placeholder.env (AD-9)."
done

# --- la liste des motifs -------------------------------------------------------------------------------
[[ -n ${PRIVATE_PATTERNS:-} ]] \
  || refuse "PRIVATE_PATTERNS absente de l'environnement : sans la liste des motifs, C21 ne confronte rien et C22 rend une anomalie (AD-12, AD-21). Aucun docker build n'a été lancé."

# Un fichier **présent mais vide** n'est pas une conformité : le piège est consigné
# (docs/procedures/shell-scripts.md, story 0.8), et une liste faite de commentaires seuls
# désactiverait C22 tout en ayant l'air d'une liste.
motif_utile=0
while IFS= read -r ligne || [[ -n $ligne ]]; do
  [[ $ligne =~ ^[[:space:]]*(#|$) ]] || { motif_utile=1; break; }
done <<< "$PRIVATE_PATTERNS"
((motif_utile == 1)) \
  || refuse "PRIVATE_PATTERNS ne porte aucun motif : que des lignes vides ou des commentaires. C22 ne chercherait rien et passerait pour vert."

# --- écriture des secrets ------------------------------------------------------------------------------
# Deux commandes séparées, chacune avec son arrêt : « a && b || die » suspend « set -e » pour tout le
# bloc (piège connu, docs/procedures/shell-scripts.md). Chaque fichier entre dans « temporaires »
# **juste après** sa création, jamais après son remplissage : un échec d'écriture laisserait sinon le
# fichier sur le disque.
legal=$(mktemp) || die "fichier temporaire des valeurs légales impossible."
temporaires+=("$legal")
motifs=$(mktemp) || die "fichier temporaire des motifs impossible."
temporaires+=("$motifs")

# « --secret id=…,src=… » sépare ses champs par des virgules (constat de la revue de la PR n° 59).
# scripts/build-image.sh refuse déjà un chemin qui en contient une ; le refus est répété ici parce
# que ces chemins-ci ne viennent pas de l'utilisateur mais de TMPDIR, et que le message doit dire
# **où** est la virgule, sans quoi il accuserait un chemin que personne n'a écrit.
for chemin in "$legal" "$motifs"; do
  [[ $chemin != *,* ]] \
    || die "le dossier des fichiers temporaires contient une virgule ($chemin), que « docker build --secret » lit comme un séparateur : poser TMPDIR ailleurs."
done

# Les valeurs sont écrites **entre guillemets doubles** : sans eux, scripts/lib/dotenv.sh retirerait
# d'une valeur ce qui suit « <espace># » et ses espaces de fin. Le guillemet a été refusé plus haut,
# donc la valeur se relit à l'identique.
for nom in "${noms[@]}"; do
  printf '%s="%s"\n' "$nom" "${!nom}" >> "$legal" \
    || die "écriture impossible dans le fichier temporaire des valeurs légales."
done
printf '%s\n' "$PRIVATE_PATTERNS" > "$motifs" \
  || die "écriture impossible dans le fichier temporaire des motifs."

# --- délégation ------------------------------------------------------------------------------------------
# **Pas de « exec » ici**, à la différence de scripts/build-image.sh : « exec » remplace le processus,
# et le piège EXIT ne tournerait jamais. Les deux temporaires — dont l'un porte les vraies valeurs
# légales — resteraient sur le disque du runner. Le build tourne donc en enfant, son code est retenu,
# et le nettoyage a lieu quoi qu'il arrive.
printf '%s: mise en ligne %s, image eleyone-site:%s.\n' "$script_name" "$tag" "$tag"
code=0
"$root/scripts/build-image.sh" --release \
  --tag "eleyone-site:$tag" \
  --secret "$legal" \
  --patterns "$motifs" || code=$?
((code == 0)) || exit "$code"

printf '%s: image eleyone-site:%s construite, contrôles de mise en ligne passés.\n' "$script_name" "$tag"
