#!/usr/bin/env bash
# Construction de l'image du site (story 4.1) : la commande que le script assemble et ses refus.
# Aucun cas ne lance Docker : la suite reste hors ligne (story 0.9). Le build réel est joué à la
# main et consigné dans le fichier de story ; la procédure dit comment le rejouer.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

faux_docker() { # $1 = code de sortie du build
  mkdir -p "$work/bin"
  {
    printf '#!/bin/sh\n'
    printf 'case "$1" in build) printf "%%s\\n" "$@" > %s ;; esac\n' "$work/arguments"
    printf 'exit %s\n' "${1:-0}"
  } > "$work/bin/docker"
  chmod +x "$work/bin/docker"
}

secret() { # un fichier de valeurs légales jetable, hors du dépôt
  printf 'HUGO_LEGAL_PUBLISHER_NAME=Essai\n' > "$work/legal.env"
  printf '%s' "$work/legal.env"
}

image() { run env PATH="$work/bin:$PATH" bash "$root/scripts/build-image.sh" "$@"; }

case_build_image_commande() {
  faux_docker 0
  image --secret "$(secret)"
  assert_eq 0 "$rc" "le build passe (messages : $err)"
  local args
  args=$(cat "$work/arguments")
  assert_contains "--secret
id=legal_env,src=$work/legal.env" "$args" "le secret est monté sous le nom qu'exige le Dockerfile"
  assert_contains "--build-arg
CHECK_IMAGE=$(sed -n 's/^CHECK_IMAGE=//p' "$root/tools.env")" "$args" "l'image des outils vient de tools.env"
  assert_contains "--build-arg
CHECK_LEVEL=standard" "$args" "le niveau par défaut est standard"
  assert_contains "--tag
eleyone-site:dev" "$args" "l'étiquette par défaut"
}

case_build_image_release() {
  faux_docker 0
  image --release --secret "$(secret)"
  assert_eq 0 "$rc" "le mode release passe (messages : $err)"
  assert_contains "CHECK_LEVEL=release" "$(cat "$work/arguments")" "le niveau suit --release"
  assert_contains "niveau release" "$out" "le script l'annonce"
}

case_build_image_etiquette() {
  faux_docker 0
  image --tag "essai:42" --secret "$(secret)"
  assert_contains "essai:42" "$(cat "$work/arguments")" "l'étiquette demandée"
}

case_build_image_sans_secret() {
  faux_docker 0
  image --secret "$work/absent.env"
  assert_eq 1 "$rc" "un fichier de valeurs absent est un refus, pas une anomalie"
  assert_contains "introuvable, illisible, ou qui n'est pas un fichier" "$err" "le message le dit"
  assert_contains "build-image.md" "$err" "et renvoie à la procédure"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_refuse_les_fichiers_du_depot() {
  # ENV_MODE=release les refuse aussi, mais un message qui arrive après cinq minutes de build ne
  # sert à personne : le refus est immédiat.
  faux_docker 0
  image --secret "$root/ci/legal-placeholder.env"
  assert_eq 1 "$rc" "le fichier factice ne peut pas servir de secret de mise en ligne"
  assert_contains "fichier de travail du dépôt" "$err" "le message nomme la cause"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_code_du_build() {
  faux_docker 1
  image --secret "$(secret)"
  assert_eq 1 "$rc" "un build en échec se voit"
}

case_build_image_option_inconnue() {
  faux_docker 0
  image --inconnue --secret "$(secret)"
  assert_eq 2 "$rc" "une option inconnue est une anomalie d'usage"
  assert_contains "option inconnue" "$err" "le message le dit"
}

case_build_image_sans_docker() {
  mkdir -p "$work/bin-nu"
  ln -sf "$(command -v dirname)" "$work/bin-nu/dirname"
  run env PATH="$work/bin-nu" "$(command -v bash)" "$root/scripts/build-image.sh" --secret "$(secret)"
  assert_eq 2 "$rc" "docker absent est une anomalie"
  assert_contains "docker est introuvable" "$err" "le message nomme l'outil"
}

case_dockerfile_trois_etapes() {
  local contenu
  contenu=$(cat "$root/Dockerfile")
  assert_contains "AS tools" "$contenu" "l'étape des outils"
  assert_contains "AS build" "$contenu" "l'étape du build et des contrôles"
  assert_contains "AS runtime" "$contenu" "l'étape servie"
  assert_contains "--mount=type=secret,id=legal_env,required=true" "$contenu" "le secret est exigé"
  assert_contains "ENV_MODE=release" "$contenu" "le build de l'image est un build de mise en ligne"
  assert_contains "chmod -R a+rX public" "$contenu" "les fichiers servis sont lisibles"
  # Un « ; » laisserait passer un contrôle en échec. Le cas ne cherche plus le point-virgule à un
  # seul endroit : il extrait l'instruction entière, retire le « if … ; then … ; else … ; fi » qui en
  # contient légitimement, et exige qu'il n'en reste aucun (constat de la revue de la PR n° 59).
  local instruction
  instruction=$(awk '/^RUN --mount=type=secret/ { dans = 1 } dans { print; if ($0 !~ /\\$/) exit }' "$root/Dockerfile")
  [[ -n $instruction ]] || { echo "instruction RUN du build introuvable" >&2; exit 1; }
  # L'instruction est d'abord repliée en une seule ligne logique : un « if » écrit sur plusieurs
  # lignes échapperait sinon au retrait, et le cas échouerait à tort (constat de la revue de la
  # PR n° 60). Le comptage porte sur les occurrences, pas sur les lignes, pour la même raison.
  local une_ligne reste
  une_ligne=$(sed -e 's/\\$//' <<< "$instruction" | tr '\n' ' ')
  # Les segments s'écrivent « [^;]* » et non « .* » : gourmand, le second engloutirait tout entre le
  # premier « if » et le dernier « fi », et masquerait un « ; » illégal entre deux blocs. Le « else »
  # est facultatif (constats de la revue de la PR n° 60).
  reste=$(sed -E 's/if [^;]*; then [^;]*(; else [^;]*)?; fi//g' <<< "$une_ligne")
  assert_eq "" "$(tr -cd ';' <<< "$reste")" "aucun « ; » hors du if : les commandes sont enchaînées par &&"
  # Comptage sans commande externe : « grep -o … | wc -l » rend 1 quand il ne trouve rien, ce que
  # pipefail transforme en arrêt silencieux du cas, avant même son assertion.
  local sans_et=${une_ligne//&&/}
  # Trois commandes — build, contrôles, chmod — font deux enchaînements.
  assert_eq 2 "$(( (${#une_ligne} - ${#sans_et}) / 2 ))" "deux enchaînements pour trois commandes"
}

case_dockerfile_image_nginx_epinglee() {
  local uses
  shell_grep_into uses -nE '^FROM nginx' "$root/Dockerfile"
  assert_contains "@sha256:" "$uses" "l'image servie est épinglée par digest, le tag n'étant que lisible"
}

case_dockerfile_directives_en_tete() {
  # Une directive placée derrière un commentaire est lue comme un commentaire : les deux premières
  # lignes du fichier en sont (constaté au premier build, 21/09/2026).
  local premiere seconde
  premiere=$(head -n 1 "$root/Dockerfile")
  seconde=$(sed -n '2p' "$root/Dockerfile")
  assert_eq "# syntax=docker/dockerfile:1" "$premiere" "la directive de syntaxe est la première ligne"
  assert_contains "# check=skip=" "$seconde" "la directive des vérifications suit immédiatement"
}

case_dockerignore_exclut_le_privé_et_les_sorties() {
  # La comparaison porte sur la **ligne entière** : « .env » est une sous-chaîne de « !.env.example »,
  # et retirer l'exclusion aurait laissé le cas passer (constat de la revue de la PR n° 59).
  local chemin ligne
  for chemin in '.git/' '.env' 'docs/private/' '_bmad*/' '.claude/' '.agent/' '.agents/' 'experiments/' 'public/' 'build/' '.tools/'; do
    shell_grep_into ligne -xF "$chemin" "$root/.dockerignore"
    assert_eq "$chemin" "$ligne" "le contexte de build exclut $chemin, sur sa propre ligne"
  done
}

case_build_image_secret_par_defaut_dans_le_depot_prive() {
  # Le défaut vit dans le dépôt privé, et il est **absolu** : résolu depuis le dossier d'appel, il
  # changerait de sens selon l'endroit d'où le script est lancé. Le cas se joue depuis /tmp pour
  # que la différence se voie, et sans LEGAL_RELEASE_ENV_FILE, qui masquerait le défaut.
  faux_docker 0
  local attendu=$root/docs/private/legal-release.env
  run env -u LEGAL_RELEASE_ENV_FILE PATH="$work/bin:$PATH" \
    bash -c 'cd "$1" && bash "$2/scripts/build-image.sh"' _ "$work" "$root"
  # Le fichier existe sur le poste d'Arnaud et pas en CI : les deux issues nomment le même chemin.
  if ((rc == 0)); then
    assert_contains "src=$attendu" "$(cat "$work/arguments")" "le défaut est le fichier du dépôt privé"
  else
    assert_eq 1 "$rc" "sans le fichier, le script refuse (messages : $err)"
    assert_contains "$attendu" "$err" "le refus nomme le chemin par défaut"
    assert_contains "dépôt privé" "$err" "et dit où le créer"
  fi
}

case_build_image_secret_relatif_au_dossier_dappel() {
  # Le script se place à la racine du dépôt : un chemin relatif s'y résoudrait, alors qu'il est
  # écrit depuis le dossier de l'appelant (constat de la revue de la PR n° 59).
  faux_docker 0
  mkdir -p "$work/ailleurs"
  printf 'HUGO_LEGAL_PUBLISHER_NAME=Essai\n' > "$work/ailleurs/legal.env"
  run env PATH="$work/bin:$PATH" bash -c 'cd "$1" && bash "$2/scripts/build-image.sh" --secret legal.env' \
    _ "$work/ailleurs" "$root"
  assert_eq 0 "$rc" "un chemin relatif est résolu depuis le dossier d'appel (messages : $err)"
  assert_contains "src=$work/ailleurs/legal.env" "$(cat "$work/arguments")" "le bon fichier est monté"
}

case_build_image_secret_qui_est_un_dossier() {
  # Un dossier lisible passait le test de lisibilité, et Docker échouait plus tard en langage de
  # démon (constat de la revue de la PR n° 59).
  faux_docker 0
  mkdir -p "$work/dossier-secret"
  image --secret "$work/dossier-secret"
  assert_eq 1 "$rc" "un dossier n'est pas un fichier de valeurs légales"
  assert_contains "qui n'est pas un fichier" "$err" "le message le dit"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_secret_avec_virgule() {
  # « --secret id=…,src=… » sépare ses champs par des virgules (constat de la revue de la PR n° 59).
  faux_docker 0
  mkdir -p "$work/avec,virgule"
  printf 'HUGO_LEGAL_PUBLISHER_NAME=Essai\n' > "$work/avec,virgule/legal.env"
  image --secret "$work/avec,virgule/legal.env"
  assert_eq 1 "$rc" "un chemin à virgule est refusé avant le build"
  assert_contains "contient une virgule" "$err" "le message dit pourquoi"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

run_case "$@"
