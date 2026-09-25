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

motifs() { # une liste de motifs jetable, hors du dépôt
  printf '# commentaire\nMOTIFFACTICE\n' > "$work/motifs.txt"
  printf '%s' "$work/motifs.txt"
}

# PRIVATE_PATTERNS_FILE est **retirée** de l'environnement de chaque appel : le poste d'Arnaud porte
# docs/private/, la CI non, et sans ce retrait un cas rendrait deux verdicts selon l'endroit où la
# suite tourne (piège connu, docs/procedures/shell-scripts.md). Les cas qui veulent une liste la
# désignent par --patterns ; ceux qui n'en veulent pas la pointent vers un chemin inexistant.
image() { run env -u PRIVATE_PATTERNS_FILE PATH="$work/bin:$PATH" bash "$root/scripts/build-image.sh" "$@"; }

# L'instruction RUN du build, repliée en une seule ligne logique : les cas qui la lisent partagent
# cette extraction plutôt que d'en écrire chacun la sienne.
instruction_run() {
  local instruction
  instruction=$(awk '/^RUN --mount=type=secret/ { dans = 1 } dans { print; if ($0 !~ /\\$/) exit }' "$root/Dockerfile")
  [[ -n $instruction ]] || { echo "instruction RUN du build introuvable" >&2; exit 1; }
  sed -e 's/\\$//' <<< "$instruction" | tr '\n' ' '
}

case_build_image_commande() {
  faux_docker 0
  image --secret "$(secret)" --patterns "$(motifs)"
  assert_eq 0 "$rc" "le build passe (messages : $err)"
  local args
  args=$(cat "$work/arguments")
  assert_contains "--secret
id=legal_env,src=$work/legal.env" "$args" "le secret est monté sous le nom qu'exige le Dockerfile"
  assert_contains "--secret
id=private_patterns,src=$work/motifs.txt" "$args" "la liste des motifs est le second secret"
  # Un secret n'entre pas dans la clé de cache de BuildKit : sans ce drapeau, une valeur légale
  # modifiée entre deux constructions ne rebâtit rien, et la seconde image sert les mentions légales
  # de la première (story 11.3). L'étape « tools », la longue, garde son cache.
  #
  # **Les deux étapes, et pas seulement « build »** : mesuré, « --no-cache-filter build » rejoue bien
  # l'instruction RUN, mais le « COPY --from=build » de l'étape « runtime » reste servi depuis le
  # cache et l'image finale sort identique à la précédente. Le cas affirme donc la liste entière ;
  # avec la seule étape « build », il échoue.
  assert_contains "--no-cache-filter
build,runtime" "$args" "ni le build ni l'étape servie ne se mettent en cache"
  assert_contains "--build-arg
CHECK_IMAGE=$(sed -n 's/^CHECK_IMAGE=//p' "$root/tools.env")" "$args" "l'image des outils vient de tools.env"
  assert_contains "--build-arg
CHECK_LEVEL=standard" "$args" "le niveau par défaut est standard"
  assert_contains "--tag
eleyone-site:dev" "$args" "l'étiquette par défaut"
}

case_build_image_release() {
  faux_docker 0
  image --release --secret "$(secret)" --patterns "$(motifs)"
  assert_eq 0 "$rc" "le mode release passe (messages : $err)"
  assert_contains "CHECK_LEVEL=release" "$(cat "$work/arguments")" "le niveau suit --release"
  assert_contains "niveau release" "$out" "le script l'annonce"
}

case_build_image_etiquette() {
  faux_docker 0
  image --tag "essai:42" --secret "$(secret)" --patterns "$(motifs)"
  assert_contains "essai:42" "$(cat "$work/arguments")" "l'étiquette demandée"
}

case_build_image_sans_secret() {
  faux_docker 0
  image --secret "$work/absent.env" --patterns "$(motifs)"
  assert_eq 1 "$rc" "un fichier de valeurs absent est un refus, pas une anomalie"
  assert_contains "introuvable, illisible, ou qui n'est pas un fichier" "$err" "le message le dit"
  assert_contains "build-image.md" "$err" "et renvoie à la procédure"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_refuse_les_fichiers_du_depot() {
  # ENV_MODE=release les refuse aussi, mais un message qui arrive après cinq minutes de build ne
  # sert à personne : le refus est immédiat.
  faux_docker 0
  image --secret "$root/ci/legal-placeholder.env" --patterns "$(motifs)"
  assert_eq 1 "$rc" "le fichier factice ne peut pas servir de secret de mise en ligne"
  assert_contains "fichier de travail du dépôt" "$err" "le message nomme la cause"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_code_du_build() {
  faux_docker 1
  image --secret "$(secret)" --patterns "$(motifs)"
  assert_eq 1 "$rc" "un build en échec se voit"
}

case_build_image_option_inconnue() {
  faux_docker 0
  image --inconnue --secret "$(secret)" --patterns "$(motifs)"
  assert_eq 2 "$rc" "une option inconnue est une anomalie d'usage"
  assert_contains "option inconnue" "$err" "le message le dit"
}

case_build_image_sans_docker() {
  mkdir -p "$work/bin-nu"
  ln -sf "$(command -v dirname)" "$work/bin-nu/dirname"
  run env -u PRIVATE_PATTERNS_FILE PATH="$work/bin-nu" "$(command -v bash)" "$root/scripts/build-image.sh" --secret "$(secret)"
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
  # L'instruction est d'abord repliée en une seule ligne logique : un « if » écrit sur plusieurs
  # lignes échapperait sinon au retrait, et le cas échouerait à tort (constat de la revue de la
  # PR n° 60). Le comptage porte sur les occurrences, pas sur les lignes, pour la même raison.
  local une_ligne reste
  une_ligne=$(instruction_run)
  # Les segments s'écrivent « [^;]* » et non « .* » : gourmand, le second engloutirait tout entre le
  # premier « if » et le dernier « fi », et masquerait un « ; » illégal entre deux blocs. Le « else »
  # est facultatif (constats de la revue de la PR n° 60).
  reste=$(sed -E 's/if [^;]*; then [^;]*(; else [^;]*)?; fi//g' <<< "$une_ligne")
  assert_eq "" "$(tr -cd ';' <<< "$reste")" "aucun « ; » hors du if : les commandes sont enchaînées par &&"
  # Comptage sans commande externe : « grep -o … | wc -l » rend 1 quand il ne trouve rien, ce que
  # pipefail transforme en arrêt silencieux du cas, avant même son assertion.
  local sans_et=${une_ligne//&&/}
  # Trois commandes — export, contrôles, chmod — font deux enchaînements. Le « scripts/build.sh »
  # qui ouvrait l'instruction a disparu à la story 11.3 : voir case_dockerfile_un_seul_build.
  assert_eq 2 "$(( (${#une_ligne} - ${#sans_et}) / 2 ))" "deux enchaînements pour trois commandes"
}

case_dockerfile_aucune_affectation_hors_export() {
  # **Le cas le plus important de ce fichier** (story 11.3). En shell, « FOO=x cmd1 && cmd2 » ne pose
  # FOO que pour cmd1. L'instruction RUN écrivait ENV_MODE et LEGAL_ENV_FILE devant scripts/build.sh,
  # et scripts/check.sh — la commande suivante — tournait sans elles : l'image emportait des mentions
  # légales factices. Le défaut a survécu à une revue de code et à deux epics, parce qu'il se lit
  # comme du Dockerfile ordinaire et que le « if », lui, marchait (Docker interpole ${CHECK_LEVEL}
  # avant le shell).
  #
  # La garde vit dans le **Dockerfile**, pas dans un script : le cas la lit donc, au lieu de
  # construire une image d'essai. Deux raisons, et la seconde décide. La suite est hors ligne et ne
  # lance jamais Docker (story 0.9) ; et surtout un build réel ne prouverait la portée des variables
  # que pour la forme écrite ce jour-là, alors que la règle porte sur **toutes** les formes qu'une
  # réécriture peut prendre — c'est une propriété du texte, et c'est le texte qu'on éprouve.
  #
  # La règle : dans l'instruction, aucun jeton « NOM=valeur » ne peut apparaître ailleurs qu'en
  # argument d'« export ». Un « export » porte pour tout le reste du shell ; un préfixe, pour une
  # seule commande.
  local une_ligne
  une_ligne=$(instruction_run)
  # « read -ra » découpe sur les blancs **sans** développer les jokers : un « a+rX » ou un « *. »
  # passeraient au filtre de bash avec un « for jeton in $une_ligne » nu.
  local -a jetons
  read -ra jetons <<< "$une_ligne"
  local jeton apres_export=0
  for jeton in "${jetons[@]}"; do
    if [[ $jeton == export ]]; then apres_export=1; continue; fi
    # « --mount=type=secret,… » commence par un tiret : il ne peut pas être pris pour une affectation.
    if [[ $jeton =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      ((apres_export == 1)) || {
        printf 'affectation « %s » hors d'"'"'un export : elle ne vaudrait que pour la commande qui suit,\n' "${jeton%%=*}=…" >&2
        printf 'et les autres commandes de l'"'"'instruction RUN ne la verraient pas (story 11.3).\n' >&2
        exit 1
      }
      continue
    fi
    # Tout autre jeton — « && », « if », une commande — ferme la série d'affectations de l'export.
    apres_export=0
  done
  # Ceinture : les quatre variables que l'instruction doit poser y sont bien, et par export.
  assert_contains "export ENV_MODE=release" "$une_ligne" "les variables sont posées par export"
  local nom
  for nom in LEGAL_ENV_FILE PRIVATE_PATTERNS_FILE TOOLS_LOCAL_DIR; do
    assert_contains "$nom=" "$une_ligne" "$nom est posée dans l'instruction"
  done
}

case_dockerfile_un_seul_build() {
  # scripts/check.sh reconstruit lui-même le rendu de travail **et** le rendu de production avant de
  # contrôler. Un « scripts/build.sh production » avant lui est donc écrasé — et c'est cette
  # redondance qui a caché le défaut de portée ci-dessus : un build correct précédait le build
  # fautif, dont sortait pourtant le public/ copié dans l'image (mesuré, story 11.3).
  local une_ligne
  une_ligne=$(instruction_run)
  [[ $une_ligne != *build.sh* ]] || {
    echo "l'instruction RUN appelle scripts/build.sh : ce build est écrasé par celui de check.sh" >&2
    exit 1
  }
  assert_contains "check.sh" "$une_ligne" "les contrôles, eux, sont bien lancés"
}

case_dockerfile_second_secret_des_motifs() {
  # .dockerignore exclut docs/private/ du contexte : la liste des motifs ne peut entrer que par un
  # secret. Sans elle, C22 rend une anomalie et C21 ne confronte rien (AD-12, AD-21, story 11.3).
  local une_ligne
  une_ligne=$(instruction_run)
  assert_contains "--mount=type=secret,id=private_patterns" "$une_ligne" "le second secret est monté"
  assert_contains "PRIVATE_PATTERNS_FILE=/run/secrets/private_patterns" "$une_ligne" \
    "et la variable que lisent C21 et C22 le désigne"
  # **Facultatif, et il doit le rester** : un « required=true » ferait échouer tout build ordinaire
  # du poste, qui n'a pas à confronter quoi que ce soit. Vérifié : sans secret fourni, BuildKit ne
  # monte rien et le fichier n'existe pas, ce que C21 lit comme « liste absente ».
  [[ $une_ligne != *"id=private_patterns,required=true"* ]] || {
    echo "le secret des motifs est exigé : un build ordinaire ne pourrait plus tourner" >&2
    exit 1
  }
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
  # La liste est **complète** : trois entrées y manquaient — « .env.* », « experiment/ » et
  # « design/ » —, et leur retrait du .dockerignore serait passé en CI (constat B4 de la
  # rétrospective de l'epic 4, 21/09/2026).
  local attendus=(
    '.git/' '.env' '.env.*' '!.env.example' 'docs/private/' '_bmad*/' '.claude/' '.agent/'
    '.agents/' 'experiments/' 'experiment/' 'design/' 'public/' 'build/' '.tools/'
    '.pr-body.md' '*.bak*'
  )
  local chemin ligne
  for chemin in "${attendus[@]}"; do
    shell_grep_into ligne -xF "$chemin" "$root/.dockerignore"
    assert_eq "$chemin" "$ligne" "le contexte de build exclut $chemin, sur sa propre ligne"
  done
  # Le compte ferme la liste : une entrée ajoutée sans passer par ce cas se verrait aussi, et la
  # liste ci-dessus cesserait d'être une description partielle du fichier.
  local effectives
  shell_grep_into effectives -cE '^[^#[:space:]]' "$root/.dockerignore"
  assert_eq "${#attendus[@]}" "$effectives" "le .dockerignore ne porte rien d'autre que ces entrées"
}

case_build_image_secret_par_defaut_dans_le_depot_prive() {
  # Le défaut vit dans le dépôt privé, et il est **absolu** : résolu depuis le dossier d'appel, il
  # changerait de sens selon l'endroit d'où le script est lancé. Le cas se joue depuis /tmp pour
  # que la différence se voie, et sans LEGAL_RELEASE_ENV_FILE, qui masquerait le défaut.
  faux_docker 0
  local attendu=$root/docs/private/legal-release.env
  run env -u LEGAL_RELEASE_ENV_FILE -u PRIVATE_PATTERNS_FILE PATH="$work/bin:$PATH" \
    bash -c 'cd "$1" && bash "$2/scripts/build-image.sh" --patterns "$3"' _ "$work" "$root" "$(motifs)"
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
  printf 'MOTIFFACTICE\n' > "$work/ailleurs/motifs.txt"
  run env -u PRIVATE_PATTERNS_FILE PATH="$work/bin:$PATH" \
    bash -c 'cd "$1" && bash "$2/scripts/build-image.sh" --secret legal.env --patterns motifs.txt' \
    _ "$work/ailleurs" "$root"
  assert_eq 0 "$rc" "un chemin relatif est résolu depuis le dossier d'appel (messages : $err)"
  assert_contains "src=$work/ailleurs/legal.env" "$(cat "$work/arguments")" "le bon fichier est monté"
}

case_build_image_secret_qui_est_un_dossier() {
  # Un dossier lisible passait le test de lisibilité, et Docker échouait plus tard en langage de
  # démon (constat de la revue de la PR n° 59).
  faux_docker 0
  mkdir -p "$work/dossier-secret"
  image --secret "$work/dossier-secret" --patterns "$(motifs)"
  assert_eq 1 "$rc" "un dossier n'est pas un fichier de valeurs légales"
  assert_contains "qui n'est pas un fichier" "$err" "le message le dit"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_secret_avec_virgule() {
  # « --secret id=…,src=… » sépare ses champs par des virgules (constat de la revue de la PR n° 59).
  faux_docker 0
  mkdir -p "$work/avec,virgule"
  printf 'HUGO_LEGAL_PUBLISHER_NAME=Essai\n' > "$work/avec,virgule/legal.env"
  image --secret "$work/avec,virgule/legal.env" --patterns "$(motifs)"
  assert_eq 1 "$rc" "un chemin à virgule est refusé avant le build"
  assert_contains "contient une virgule" "$err" "le message dit pourquoi"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_patterns_option_mais_absente() {
  # « --patterns » est un acte explicite : le fichier qu'il nomme doit exister, à tout niveau. Sans
  # cette garde, un chemin mal écrit se serait tu, et l'image serait sortie d'un contrôle qui n'a
  # rien confronté. Le cas se joue au niveau **standard**, pour que la garde de la mise en ligne ne
  # la couvre pas : deux gardes qui refusent la même entrée n'en font éprouver qu'une (point 9).
  faux_docker 0
  image --secret "$(secret)" --patterns "$work/motifs-absents.txt"
  assert_eq 1 "$rc" "une liste nommée par --patterns et introuvable est un refus"
  assert_contains "liste des motifs introuvable" "$err" "le message le dit"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_patterns_par_la_variable() {
  # PRIVATE_PATTERNS_FILE est une **configuration ambiante**, comme le défaut : introuvable, elle
  # laisse le build ordinaire continuer sans second secret, et le script le dit. C'est ce qui permet
  # au cas ci-dessus d'éprouver la garde de l'option, et au cas de mise en ligne d'éprouver la
  # sienne, chacun sans l'autre.
  faux_docker 0
  run env PRIVATE_PATTERNS_FILE="$work/rien.txt" PATH="$work/bin:$PATH" \
    bash "$root/scripts/build-image.sh" --secret "$(secret)"
  assert_eq 0 "$rc" "un build ordinaire continue sans liste (messages : $err)"
  assert_contains "liste des motifs absente" "$err" "le script dit ce qu'il n'aura pas"
  [[ $(cat "$work/arguments") != *private_patterns* ]] \
    || { echo "un secret de motifs a été monté sans fichier" >&2; exit 1; }
}

case_build_image_patterns_la_variable_designe_bien_la_liste() {
  # Et quand le fichier est là, la variable le monte : sans ce cas, la branche « ambiante » pourrait
  # ne jamais rien monter et les deux cas voisins resteraient verts (point 11 — éprouver aussi ce
  # que la garde doit **laisser passer**).
  faux_docker 0
  run env PRIVATE_PATTERNS_FILE="$(motifs)" PATH="$work/bin:$PATH" \
    bash "$root/scripts/build-image.sh" --secret "$(secret)"
  assert_eq 0 "$rc" "le build passe (messages : $err)"
  assert_contains "id=private_patterns,src=$work/motifs.txt" "$(cat "$work/arguments")" \
    "la liste désignée par la variable est montée"
}

case_build_image_patterns_defaut_absent() {
  # Le défaut, lui, peut manquer : un clone sans docs/private/ construit une image ordinaire sans
  # second secret. Le script le **dit** plutôt que de se taire — un montage silencieusement absent
  # est exactement ce qui a rendu le défaut de la story 11.3 invisible.
  faux_docker 0
  local defaut=$root/docs/private/forbidden-patterns.txt
  # Le fichier existe sur le poste d'Arnaud et pas en CI : les deux issues sont affirmées.
  run env -u PRIVATE_PATTERNS_FILE PATH="$work/bin:$PATH" \
    bash "$root/scripts/build-image.sh" --secret "$(secret)"
  assert_eq 0 "$rc" "le build ordinaire passe dans les deux cas (messages : $err)"
  if [[ -f $defaut ]]; then
    assert_contains "id=private_patterns,src=$defaut" "$(cat "$work/arguments")" \
      "le défaut est la liste du dépôt privé"
  else
    assert_contains "liste des motifs absente" "$err" "le script dit qu'il n'en a pas"
    [[ $(cat "$work/arguments") != *private_patterns* ]] \
      || { echo "un secret de motifs a été monté sans fichier" >&2; exit 1; }
  fi
}

case_build_image_release_sans_liste() {
  # Au niveau release, C21 et C22 exigent tous deux la liste : le refus est immédiat, plutôt
  # qu'après plusieurs minutes de build (même raison que le refus du fichier de travail du dépôt).
  # La liste est désignée par la **variable**, pas par --patterns : sans cela, la garde de l'option
  # refuserait la première et ce cas n'éprouverait rien de ce qu'il croit éprouver — c'est
  # exactement ce qu'une première écriture faisait, et la mutation restait verte.
  faux_docker 0
  run env PRIVATE_PATTERNS_FILE="$work/rien.txt" PATH="$work/bin:$PATH" \
    bash "$root/scripts/build-image.sh" --release --secret "$(secret)"
  assert_eq 1 "$rc" "une mise en ligne sans liste des motifs est refusée"
  assert_contains "C21 et C22 l'exigent" "$err" "le message nomme les deux contrôles"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_patterns_avec_virgule() {
  # Le même piège que pour le fichier de valeurs légales : « --secret id=…,src=… » sépare ses champs
  # par des virgules (constat de la revue de la PR n° 59, balayé à la story 11.3 — point 18).
  faux_docker 0
  mkdir -p "$work/motifs,ici"
  printf 'MOTIFFACTICE\n' > "$work/motifs,ici/liste.txt"
  image --secret "$(secret)" --patterns "$work/motifs,ici/liste.txt"
  assert_eq 1 "$rc" "un chemin de liste à virgule est refusé avant le build"
  assert_contains "contient une virgule" "$err" "le message dit pourquoi"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_patterns_qui_est_un_dossier() {
  faux_docker 0
  mkdir -p "$work/dossier-motifs"
  image --secret "$(secret)" --patterns "$work/dossier-motifs"
  assert_eq 1 "$rc" "un dossier n'est pas une liste de motifs"
  assert_contains "qui n'est pas un fichier" "$err" "le message le dit"
  [[ ! -f $work/arguments ]] || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
}

case_build_image_patterns_relatif_au_dossier_dappel() {
  # Le script se place à la racine du dépôt : un chemin relatif s'y résoudrait, alors qu'il est
  # écrit depuis le dossier de l'appelant (constat de la revue de la PR n° 59, appliqué à la
  # nouvelle option — point 18 : un constat d'une classe connue est un ordre de balayage).
  faux_docker 0
  mkdir -p "$work/ailleurs2"
  printf 'HUGO_LEGAL_PUBLISHER_NAME=Essai\n' > "$work/ailleurs2/legal.env"
  printf 'MOTIFFACTICE\n' > "$work/ailleurs2/liste.txt"
  run env -u PRIVATE_PATTERNS_FILE PATH="$work/bin:$PATH" \
    bash -c 'cd "$1" && bash "$2/scripts/build-image.sh" --secret legal.env --patterns liste.txt' \
    _ "$work/ailleurs2" "$root"
  assert_eq 0 "$rc" "un chemin relatif est résolu depuis le dossier d'appel (messages : $err)"
  assert_contains "id=private_patterns,src=$work/ailleurs2/liste.txt" "$(cat "$work/arguments")" \
    "la bonne liste est montée"
}

run_case "$@"
