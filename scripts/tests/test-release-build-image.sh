#!/usr/bin/env bash
# Enveloppe de mise en ligne (story 11.3) : ce qu'elle exige avant de déléguer, ce qu'elle écrit, et
# ce qu'elle supprime. Aucun cas ne lance Docker : la suite reste hors ligne (story 0.9). Le vrai
# build est joué à la main et consigné dans le fichier de story.
#
# **Point 19 d'AGENTS.md — l'aîné et ses gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-build-image.sh, dont il reprend le faux docker et la lecture des arguments. Il
# en reprend aussi les trois gardes de cas : affirmer le code **avant** de compter quoi que ce soit ;
# vérifier que docker n'a **pas** été lancé après un refus ; retirer de l'environnement les variables
# que le poste porte et la CI non. La quatrième garde de l'aîné — le repli sur docs/private/ affirmé
# dans ses deux issues — n'a pas d'objet ici : l'enveloppe ne lit aucun fichier du dépôt privé, elle
# écrit les siens. Le tableau complet est dans le fichier de story.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Le faux docker écrit ses arguments **et recopie les fichiers de secrets** : c'est le seul moyen de
# voir ce que l'enveloppe a écrit dedans, puisqu'elle les supprime en sortant. Les copies vivent
# dans $work, supprimé avec le cas.
faux_docker() { # $1 = code de sortie du build
  mkdir -p "$work/bin" "$work/secrets"
  {
    printf '#!/bin/sh\n'
    printf 'if [ "$1" = build ]; then\n'
    printf '  printf "%%s\\n" "$@" > %s\n' "$work/arguments"
    printf '  for arg in "$@"; do\n'
    printf '    case "$arg" in\n'
    printf '      id=*,src=*)\n'
    printf '        nom=${arg%%%%,src=*}; nom=${nom#id=}; src=${arg#*,src=}\n'
    printf '        cp "$src" "%s/$nom" 2>/dev/null || true ;;\n' "$work/secrets"
    printf '    esac\n'
    printf '  done\n'
    printf 'fi\n'
    printf 'exit %s\n' "${1:-0}"
  } > "$work/bin/docker"
  chmod +x "$work/bin/docker"
}

# Un TMPDIR **qui n'appartient qu'au cas** : « ${TMPDIR:-/tmp} » est partagé avec le reste de la
# machine, et y compter supposerait son environnement (piège connu, shell-scripts.md). Ici, tout ce
# qui s'y trouve vient du script qu'on éprouve.
tmpdir_a_soi() {
  local tmp=$work/tmp-a-soi
  rm -rf "$tmp"; mkdir -p "$tmp"
  printf '%s' "$tmp"
}

restes_dans() { find "$1" -mindepth 1 | wc -l; }

# Les huit noms viennent de ci/legal-placeholder.env, comme dans le script : une neuvième variable
# d'AD-9 serait exigée par les deux sans retouche, et le cas ne porte pas de liste à lui (point 19).
noms_legaux() {
  local ligne
  shell_grep_into ligne -oE '^HUGO_LEGAL_[A-Z0-9_]+=' "$root/ci/legal-placeholder.env"
  sed 's/=$//' <<< "$ligne"
}

# L'environnement complet d'une mise en ligne, sous forme d'arguments pour « env ».
environnement() { # $@ = paires NOM=valeur qui remplacent ou retirent (NOM= pour vider)
  local -a arguments=(PRIVATE_PATTERNS=$'# liste factice\nMOTIFFACTICE\n')
  local nom
  while IFS= read -r nom; do
    [[ -n $nom ]] || continue
    arguments+=("$nom=valeur-essai-${nom#HUGO_LEGAL_}")
  done <<< "$(noms_legaux)"
  arguments+=("$@")
  printf '%s\0' "${arguments[@]}"
}

enveloppe() { # $1 = tag, $2… = surcharges d'environnement
  local tag=$1; shift
  local -a variables=()
  mapfile -d '' -t variables < <(environnement "$@")
  run env -i \
    PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" \
    bash "$root/scripts/release/build-image.sh" "$tag"
}

docker_lance() { [[ -f $work/arguments ]]; }

refus_sans_build() { # $1 = code attendu, $2 = libellé
  assert_eq "$1" "$rc" "$2 (messages : $err)"
  ! docker_lance || { echo "docker a été lancé malgré le refus" >&2; exit 1; }
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste"
}

case_release_build_image_construit_le_bon_appel() {
  faux_docker 0
  enveloppe v1.2.3
  assert_eq 0 "$rc" "une mise en ligne bien configurée passe (messages : $err)"
  local args
  args=$(cat "$work/arguments")
  assert_contains "--tag
eleyone-site:v1.2.3" "$args" "l'image porte le tag demandé"
  assert_contains "--build-arg
CHECK_LEVEL=release" "$args" "les contrôles tournent au niveau release"
  assert_contains "--no-cache-filter
build,runtime" "$args" "ni le build ni l'étape servie ne se mettent en cache : un secret n'entre pas dans leur clé"
  assert_contains "id=legal_env,src=" "$args" "les valeurs légales sont un secret BuildKit"
  assert_contains "id=private_patterns,src=" "$args" "la liste des motifs en est un second"
}

case_release_build_image_tag_de_repetition() {
  faux_docker 0
  enveloppe v1.2.3-rc.4
  assert_eq 0 "$rc" "un tag de répétition passe (messages : $err)"
  assert_contains "eleyone-site:v1.2.3-rc.4" "$(cat "$work/arguments")" "l'image porte le tag de répétition"
}

case_release_build_image_tags_refuses() {
  # Chaque forme est refusée **avant** le docker build. La liste couvre ce que la garde laisse
  # passer si on l'écrit trop large : sans préfixe, sans correctif, un « rc » sans numéro, un zéro de
  # tête, une pré-version qui n'est pas une répétition, et une injection derrière une espace.
  local mauvais
  for mauvais in "1.2.3" "v1.2" "v1.2.3.4" "v1.2.3-rc" "v1.2.3-rc.x" "v01.2.3" "v1.2.3-beta.1" \
                 "v1.2.3 ; echo raté" "vX.Y.Z" "" "V1.2.3" $'v1.2.3\nv9.9.9'; do
    faux_docker 0
    rm -f "$work/arguments"
    enveloppe "$mauvais"
    ! docker_lance || { printf 'docker a été lancé pour le tag %q\n' "$mauvais" >&2; exit 1; }
    ((rc == 1 || rc == 2)) || { printf 'le tag %q a été accepté (code %s)\n' "$mauvais" "$rc" >&2; exit 1; }
  done
  # Et la forme juste passe, sans quoi la garde ne prouverait rien : un « refuse tout » refuserait
  # aussi les tags corrects (point 11 — mesurer le cas court **et** le cas long).
  faux_docker 0
  enveloppe v0.0.0
  assert_eq 0 "$rc" "« v0.0.0 » est une version valide (messages : $err)"
}

case_release_build_image_valeur_legale_absente() {
  faux_docker 0
  enveloppe v1.2.3 HUGO_LEGAL_HOST_EMAIL=
  refus_sans_build 1 "une valeur légale vide est un refus"
  assert_contains "HUGO_LEGAL_HOST_EMAIL" "$err" "le message nomme la variable manquante"
}

case_release_build_image_toutes_les_absences_dun_coup() {
  # Une CI mal configurée apprend d'un coup ce qui lui manque, au lieu d'un nom par exécution.
  faux_docker 0
  enveloppe v1.2.3 HUGO_LEGAL_HOST_EMAIL= HUGO_LEGAL_PUBLISHER_PHONE=
  refus_sans_build 1 "deux valeurs absentes sont un refus"
  assert_contains "HUGO_LEGAL_HOST_EMAIL" "$err" "la première est nommée"
  assert_contains "HUGO_LEGAL_PUBLISHER_PHONE" "$err" "la seconde aussi"
}

case_release_build_image_valeur_factice() {
  # La garde 8 de scripts/build-image.sh refuse les **fichiers** de travail du dépôt comme secret ;
  # par l'environnement, les mêmes valeurs entreraient sans passer par un fichier. C15 les
  # rattraperait dans la sortie, mais cinq minutes de build plus tard.
  faux_docker 0
  enveloppe v1.2.3 HUGO_LEGAL_HOST_NAME=VALEUR-FACTICE-hebergeur-nom
  refus_sans_build 1 "une valeur factice ne construit pas une mise en ligne"
  assert_contains "HUGO_LEGAL_HOST_NAME" "$err" "le message nomme la variable"
}

case_release_build_image_valeur_avec_guillemet() {
  # scripts/lib/dotenv.sh coupe une valeur entre guillemets au guillemet suivant : la valeur serait
  # tronquée en silence, et l'image servirait des mentions légales fausses sans qu'un contrôle
  # puisse le voir.
  faux_docker 0
  enveloppe v1.2.3 'HUGO_LEGAL_PUBLISHER_NAME=Société « Essai " tronqué »'
  refus_sans_build 1 "un guillemet double dans une valeur est un refus"
  assert_contains "guillemet" "$err" "le message dit pourquoi"
}

case_release_build_image_valeur_avec_saut_de_ligne() {
  faux_docker 0
  enveloppe v1.2.3 "$(printf 'HUGO_LEGAL_PUBLISHER_ADDRESS=1 rue Untel\n75000 Ville')"
  refus_sans_build 1 "un saut de ligne dans une valeur est un refus"
  assert_contains "saut de ligne" "$err" "le message dit pourquoi"
}

case_release_build_image_sans_liste_de_motifs() {
  faux_docker 0
  enveloppe v1.2.3 PRIVATE_PATTERNS=
  refus_sans_build 1 "sans la liste des motifs, aucune mise en ligne"
  # Le message affirmé est **celui de cette garde-ci**, et non « aucun motif » : les deux refus
  # nomment PRIVATE_PATTERNS, et une assertion sur le seul nom de la variable aurait laissé la garde
  # de l'absence sans test, la garde de la liste vide la couvrant (point 9, mesuré par mutation).
  assert_contains "PRIVATE_PATTERNS absente de l'environnement" "$err" "le message dit qu'elle manque"
}

case_release_build_image_liste_sans_aucun_motif() {
  # Un fichier **présent mais vide** n'est pas une conformité (piège connu, story 0.8) : une liste
  # faite de commentaires seuls désactiverait C22 tout en ayant l'air d'une liste.
  faux_docker 0
  enveloppe v1.2.3 "$(printf 'PRIVATE_PATTERNS=# rien que des commentaires\n\n   \n# encore')"
  refus_sans_build 1 "une liste sans motif est un refus"
  assert_contains "ne porte aucun motif" "$err" "le message distingue « vide » de « absente »"
}

case_release_build_image_les_temporaires_disparaissent() {
  faux_docker 0
  enveloppe v1.2.3
  assert_eq 0 "$rc" "le build passe (messages : $err)"
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste après un succès"
}

case_release_build_image_les_temporaires_disparaissent_apres_un_echec() {
  # **La raison pour laquelle l'enveloppe n'emploie pas « exec »**, à la différence de son aîné
  # scripts/build-image.sh : « exec » remplace le processus, et le piège EXIT ne tournerait jamais.
  # Les deux temporaires — dont l'un porte les vraies valeurs légales — resteraient sur le disque du
  # runner. Ce cas échoue si quelqu'un réintroduit le « exec ».
  faux_docker 1
  enveloppe v1.2.3
  assert_eq 1 "$rc" "un build en échec se voit (messages : $err)"
  assert_eq 0 "$(restes_dans "$work/tmp-a-soi")" "aucun fichier temporaire ne reste après un échec"
}

case_release_build_image_le_fichier_legal_se_relit_a_lidentique() {
  # Ce que l'enveloppe écrit doit ressortir **identique** du chargeur unique : sans les guillemets,
  # dotenv.sh retire d'une valeur ce qui suit « <espace># » et ses espaces de fin, et l'image
  # servirait une adresse amputée sans qu'aucun contrôle ne s'en aperçoive.
  faux_docker 0
  local valeur='1 rue Untel # bâtiment B  '
  enveloppe v1.2.3 "HUGO_LEGAL_PUBLISHER_ADDRESS=$valeur"
  assert_eq 0 "$rc" "le build passe (messages : $err)"
  [[ -f $work/secrets/legal_env ]] || { echo "le secret legal_env n'a pas été monté" >&2; exit 1; }
  . "$root/scripts/lib/dotenv.sh"
  local lignes relue=""
  lignes=$(dotenv_read "$work/secrets/legal_env" HUGO_LEGAL_)
  while IFS= read -r ligne; do
    [[ ${ligne%%=*} == HUGO_LEGAL_PUBLISHER_ADDRESS ]] || continue
    relue=${ligne#*=}
  done <<< "$lignes"
  assert_eq "$valeur" "$relue" "la valeur se relit à l'identique, espaces et dièse compris"
}

case_release_build_image_les_noms_viennent_du_placeholder() {
  # Les noms ne sont pas recopiés dans le script : ils sont lus dans ci/legal-placeholder.env, dont
  # C18 vérifie qu'il porte exactement ceux d'AD-9. Une quatrième copie serait la faute du point 19.
  faux_docker 0
  enveloppe v1.2.3
  assert_eq 0 "$rc" "le build passe (messages : $err)"
  local attendus obtenus
  attendus=$(noms_legaux | LC_ALL=C sort)
  shell_grep_into obtenus -oE '^HUGO_LEGAL_[A-Z0-9_]+=' "$work/secrets/legal_env"
  obtenus=$(sed 's/=$//' <<< "$obtenus" | LC_ALL=C sort)
  assert_eq "$attendus" "$obtenus" "le fichier écrit porte exactement les variables d'AD-9"
}

case_release_build_image_la_liste_des_motifs_est_ecrite_telle_quelle() {
  faux_docker 0
  enveloppe v1.2.3 "$(printf 'PRIVATE_PATTERNS=# commentaire\nMOTIFFACTICE\nAUTREMOTIF')"
  assert_eq 0 "$rc" "le build passe (messages : $err)"
  [[ -f $work/secrets/private_patterns ]] || { echo "le secret private_patterns n'a pas été monté" >&2; exit 1; }
  assert_eq "# commentaire
MOTIFFACTICE
AUTREMOTIF" "$(cat "$work/secrets/private_patterns")" "la liste est écrite ligne pour ligne"
}

case_release_build_image_aucune_valeur_dans_les_messages() {
  # Le journal d'une CI se lit. Un message nomme la variable, jamais son contenu — y compris quand
  # tout se passe bien, et y compris quand ça échoue.
  faux_docker 1
  local marqueur=CHAINE-QUI-NE-DOIT-PAS-SORTIR
  enveloppe v1.2.3 "HUGO_LEGAL_PUBLISHER_EMAIL=$marqueur" "PRIVATE_PATTERNS=$marqueur-motif"
  [[ $out != *"$marqueur"* ]] || { echo "une valeur légale est apparue sur la sortie standard" >&2; exit 1; }
  [[ $err != *"$marqueur"* ]] || { echo "une valeur légale est apparue sur la sortie d'erreur" >&2; exit 1; }
}

case_release_build_image_aucune_trace_de_shell() {
  # « set +x » dès l'en-tête : même lancé avec « bash -x », le script n'écrit pas ses valeurs dans le
  # journal. Le cas le **lance** ainsi plutôt que de relire le fichier.
  faux_docker 0
  local marqueur=CHAINE-QUI-NE-DOIT-PAS-SORTIR
  local -a variables=()
  mapfile -d '' -t variables < <(environnement "HUGO_LEGAL_PUBLISHER_EMAIL=$marqueur")
  run env -i PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    "${variables[@]}" bash -x "$root/scripts/release/build-image.sh" v1.2.3
  assert_eq 0 "$rc" "le build passe sous bash -x (messages : $err)"
  [[ $err != *"$marqueur"* ]] || { echo "bash -x a écrit une valeur légale dans la trace" >&2; exit 1; }
  # Et le script ne rallume jamais la trace de lui-même.
  local rallumage
  shell_grep_into rallumage -nE '^[[:space:]]*set[[:space:]]+-[a-z]*x' "$root/scripts/release/build-image.sh"
  assert_eq "" "$rallumage" "aucun « set -x » dans le script"
}

case_release_build_image_tmpdir_avec_virgule() {
  # « --secret id=…,src=… » sépare ses champs par des virgules (constat de la revue de la PR n° 59).
  # Ces chemins-ci ne viennent pas de l'utilisateur mais de TMPDIR : le message doit dire où est la
  # virgule, sans quoi il accuserait un chemin que personne n'a écrit.
  faux_docker 0
  local tmp=$work/tmp,virgule
  rm -rf "$tmp"; mkdir -p "$tmp"
  local -a variables=()
  mapfile -d '' -t variables < <(environnement)
  run env -i PATH="$work/bin:$PATH" TMPDIR="$tmp" HOME="$work" \
    "${variables[@]}" bash "$root/scripts/release/build-image.sh" v1.2.3
  assert_eq 2 "$rc" "un TMPDIR à virgule est une anomalie (messages : $err)"
  assert_contains "virgule" "$err" "le message dit pourquoi"
  ! docker_lance || { echo "docker a été lancé malgré l'anomalie" >&2; exit 1; }
  assert_eq 0 "$(restes_dans "$tmp")" "les temporaires déjà créés sont supprimés"
}

case_release_build_image_usage() {
  faux_docker 0
  run env -i PATH="$work/bin:$PATH" TMPDIR="$(tmpdir_a_soi)" HOME="$work" \
    bash "$root/scripts/release/build-image.sh"
  assert_eq 2 "$rc" "sans tag, c'est une anomalie d'usage"
  assert_contains "usage" "$err" "le message le dit"
  ! docker_lance || { echo "docker a été lancé sans tag" >&2; exit 1; }
}

run_case "$@"
