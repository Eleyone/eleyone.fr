#!/usr/bin/env bash
# Chargeur des valeurs légales (story 2.4, AD-9) : priorité des sources, isolement des jetons,
# refus d'une mise en ligne mal configurée. Hors ligne, sur des fichiers d'essai jetables.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# fichiers d'essai : un « .env » qui porte un jeton et une seule valeur légale, et un fichier factice complet
fichiers() {
  mkdir -p "$work/ci"
  cat > "$work/env-essai" <<'ENV'
GITEA_URL=https://exemple.invalide
GITEA_TOKEN=jeton-factice-de-test
HUGO_LEGAL_PUBLISHER_NAME="Nom Avec Espaces"   # commentaire de fin
ENV
  cat > "$work/ci/placeholder.env" <<'ENV'
HUGO_LEGAL_PUBLISHER_NAME=VALEUR-FACTICE-editeur-nom
HUGO_LEGAL_PUBLISHER_ADDRESS=VALEUR-FACTICE-editeur-adresse
HUGO_LEGAL_PUBLISHER_EMAIL=VALEUR-FACTICE-editeur-courriel
HUGO_LEGAL_PUBLISHER_PHONE=VALEUR-FACTICE-editeur-telephone
HUGO_LEGAL_PUBLISHER_REGISTRATION=VALEUR-FACTICE-editeur-immatriculation
HUGO_LEGAL_HOST_NAME=VALEUR-FACTICE-hebergeur-nom
HUGO_LEGAL_HOST_ADDRESS=VALEUR-FACTICE-hebergeur-adresse
HUGO_LEGAL_HOST_PHONE=VALEUR-FACTICE-hebergeur-telephone
ENV
}

# Le nombre attendu est **lu dans le chargeur**, jamais écrit ici : AD-9 est passé de sept variables
# à huit le 23/09/2026, et deux cas comptaient « 7 » en dur. Un test qui recopie un nombre devient
# faux le jour où la source change, et il le devient en silence jusqu'à ce qu'il échoue pour une
# raison qui n'est pas la sienne (constat de la story 9.1).
attendues() { grep -cE '^  HUGO_LEGAL_[A-Z_]+$' "$root/scripts/env.sh"; }

charge() { # $1… commande passée au chargeur ; les fichiers d'essai remplacent ceux du dépôt
  run env ENV_FILE="$work/env-essai" LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" \
    "$root/scripts/env.sh" "$@"
}

case_env_jetons_isoles() {
  fichiers
  charge sh -c 'env | grep -c "^GITEA_" || true'
  assert_eq 0 "$rc" "chargeur lancé (messages : $err)"
  assert_contains "0" "$out" "aucune variable GITEA_ dans l environnement de la commande"
}

case_env_toutes_les_valeurs_presentes() {
  fichiers
  charge sh -c 'env | grep -c "^HUGO_LEGAL_"'
  assert_contains "$(attendues)" "$out" "toutes les variables légales d AD-9 sont définies"
}

case_env_variable_definie_vide_reste_prioritaire() {
  # Une variable **définie mais vide** est déjà définie : le critère de la story 2.4 lui donne la
  # priorité sur le fichier. Elle n'a donc pas à être remplacée par une valeur factice — et le
  # build s'arrêtera plus loin, ce que l'opérateur a demandé en la vidant. Avec « -n » au lieu de
  # « -v », elle était écrasée en silence (constat de la revue de la PR n° 98).
  fichiers
  run env HUGO_LEGAL_PUBLISHER_NAME= ENV_FILE="$work/env-essai" \
    LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" "$root/scripts/env.sh" \
    sh -c 'printf "[%s]" "${HUGO_LEGAL_PUBLISHER_NAME-absente}"'
  assert_eq 0 "$rc" "le chargeur passe la main (messages : $err)"
  assert_eq "[]" "$out" "la variable vide de l environnement survit au repli"
}

case_env_entree_vide_dun_fichier_nempeche_pas_le_repli() {
  # Le pendant du cas précédent, et la frontière entre les deux : **pour un fichier, une valeur
  # vide vaut absence.** Un .env obtenu en copiant .env.example et en remplissant ce qu'on sait
  # porte des entrées vides ; le critère de la story 2.4 exige qu'il ne fasse pas échouer le build.
  # Une première écriture confondait les deux vides et cassait le build du poste (constat fait en
  # lançant les contrôles après la revue de la PR n° 98).
  fichiers
  printf 'HUGO_LEGAL_PUBLISHER_NAME=\n' > "$work/env-essai"
  charge sh -c 'printf "[%s]" "$HUGO_LEGAL_PUBLISHER_NAME"'
  assert_eq 0 "$rc" "le chargeur passe la main (messages : $err)"
  assert_contains "VALEUR-FACTICE" "$out" "l entrée vide du fichier laisse le repli opérer"
}

case_env_valeur_avec_espaces() {
  fichiers
  charge sh -c 'printf "[%s]" "$HUGO_LEGAL_PUBLISHER_NAME"'
  assert_contains "[Nom Avec Espaces]" "$out" "guillemets retirés, espaces gardés, commentaire de fin ôté"
}

case_env_repli_variable_par_variable() {
  fichiers
  charge sh -c 'printf "[%s]" "$HUGO_LEGAL_HOST_NAME"'
  assert_contains "[VALEUR-FACTICE-hebergeur-nom]" "$out" "une variable absente du .env vient du fichier factice"
}

case_env_priorite_a_l_environnement() {
  fichiers
  run env ENV_FILE="$work/env-essai" LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" \
    HUGO_LEGAL_PUBLISHER_NAME="Déjà définie" "$root/scripts/env.sh" sh -c 'printf "[%s]" "$HUGO_LEGAL_PUBLISHER_NAME"'
  assert_contains "[Déjà définie]" "$out" "la variable déjà définie l emporte sur le fichier"
}

case_env_sans_aucun_fichier() {
  fichiers
  run env ENV_FILE="$work/absent" LEGAL_PLACEHOLDER_FILE="$work/absent" "$root/scripts/env.sh" \
    sh -c 'env | grep -c "^HUGO_LEGAL_" || true'
  assert_eq 0 "$rc" "sans fichier, le chargeur lance quand même la commande"
  assert_contains "0" "$out" "aucune valeur légale inventée"
}

case_release_sans_fichier_designe() {
  fichiers
  run env ENV_MODE=release ENV_FILE="$work/env-essai" "$root/scripts/env.sh" true
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "sans LEGAL_ENV_FILE" "$err" "cause nommée"
}

case_release_refuse_le_env_de_travail() {
  fichiers
  run env ENV_MODE=release ENV_FILE="$work/env-essai" LEGAL_ENV_FILE="$work/env-essai" \
    LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" "$root/scripts/env.sh" true
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "fichier de travail du dépôt" "$err" "cause nommée"
}

case_release_refuse_le_fichier_factice() {
  fichiers
  run env ENV_MODE=release ENV_FILE="$work/env-essai" LEGAL_ENV_FILE="$work/ci/placeholder.env" \
    LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" "$root/scripts/env.sh" true
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "fichier de travail du dépôt" "$err" "cause nommée"
}

case_release_refuse_un_chemin_detourne() {
  fichiers
  mkdir -p "$work/ailleurs"
  cp "$work/ci/placeholder.env" "$work/ailleurs/.env"
  run env ENV_MODE=release ENV_FILE="$work/env-essai" LEGAL_ENV_FILE="$work/ailleurs/.env" \
    LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" "$root/scripts/env.sh" true
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "nommé .env" "$err" "refus par le nom de base, même hors du dépôt"
}

case_release_variable_manquante() {
  fichiers
  printf 'HUGO_LEGAL_PUBLISHER_NAME=Nom reel\n' > "$work/secrets.env"
  run env ENV_MODE=release ENV_FILE="$work/env-essai" LEGAL_ENV_FILE="$work/secrets.env" \
    LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" "$root/scripts/env.sh" true
  assert_eq 1 "$rc" "code 1 : refus"
  assert_contains "absente : mise en ligne refusée" "$err" "variable manquante nommée"
  [[ $err != *VALEUR-FACTICE* ]] || { echo "une valeur factice apparaît dans un message" >&2; exit 1; }
}

case_release_fichier_dedie_complet() {
  fichiers
  sed 's/VALEUR-FACTICE/valeur-reelle/' "$work/ci/placeholder.env" > "$work/secrets.env"
  run env ENV_MODE=release ENV_FILE="$work/env-essai" LEGAL_ENV_FILE="$work/secrets.env" \
    LEGAL_PLACEHOLDER_FILE="$work/ci/placeholder.env" "$root/scripts/env.sh" \
    sh -c 'env | grep -c "^HUGO_LEGAL_"; env | grep -c VALEUR-FACTICE || true'
  assert_eq 0 "$rc" "mise en ligne acceptée (messages : $err)"
  assert_contains "$(attendues)" "$out" "toutes les valeurs viennent du fichier dédié"
  assert_contains "0" "$out" "aucune valeur factice ne subsiste"
}

case_env_sans_commande() {
  fichiers
  charge
  assert_eq 2 "$rc" "code 2 : usage"
  assert_contains "usage :" "$err" "message d usage"
}

run_case "$@"
