#!/usr/bin/env bash
# Contrôle des secrets d'Actions de la forge (story 11.6, second critère d'acceptation) : ce qu'il
# refuse, ce qu'il signale sans bloquer, et ce qu'il n'affiche jamais.
#
# **Aucun cas n'appelle le réseau.** Un faux curl répond à la place de la forge depuis $work/api,
# exactement comme scripts/tests/test-release.sh le fait depuis la story 11.7, et chaque cas tourne
# dans un dépôt git jetable de $work dont les fichiers `ci/` sont des copies de ceux du dépôt : les
# douze noms attendus sont donc les vrais, sans qu'aucun ne soit recopié dans ce fichier.
#
# **Point 19 d'AGENTS.md — l'aîné et ses gardes.** Ce fichier est écrit « comme »
# scripts/tests/test-release.sh. Gardes reprises : le faux curl en tête de PATH, qui consomme
# l'entrée standard sans jamais écrire le jeton ; la trace des appels d'API (méthode et chemin
# seulement, jamais l'adresse) ; la vérification qu'**aucun** appel n'a eu lieu après un refus qui
# précède la forge ; un environnement réduit par « env -i » pour qu'un cas rende le même verdict sur
# le poste et dans CHECK_IMAGE ; un dépôt de test qui n'est jamais celui du projet. Garde ajoutée
# ici, qu'aucun aîné n'avait : l'affirmation qu'aucune méthode d'écriture n'est jamais envoyée — un
# contrôle qui poserait ou supprimerait un secret serait bien pire que pas de contrôle du tout.
# Le tableau complet est dans le fichier de la story 11.6.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

script=$root/scripts/release/check-forge-secrets.sh
depot=$work/depot
readonly repo=Eleyone/eleyone.fr

# --- le faux curl ----------------------------------------------------------------------------------

# Il répond à la place de la forge. Il consomme l'entrée standard — le jeton y passe par « -K - » —
# sans jamais l'écrire nulle part, et note méthode et chemin, jamais l'adresse.
faux_curl() {
  mkdir -p "$work/bin" "$work/api"
  {
    printf '#!/bin/sh\n'
    printf 'w=%q\n' "$work"
    cat <<'FAUX'
cat > /dev/null 2>&1
out=""; methode=GET; url=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift 2 ;;
    -X) methode=$2; shift 2 ;;
    -H) shift 2 ;;
    -w) shift 2 ;;
    -K) shift 2 ;;
    --data) shift 2 ;;
    -s) shift ;;
    *) url=$1; shift ;;
  esac
done
chemin=${url#*/api/v1}
cle=$(printf '%s %s' "$methode" "$chemin" | sed 's#[^A-Za-z0-9]#_#g')
printf '%s %s\n' "$methode" "$chemin" >> "$w/api-appels"
rep="$w/api/$cle"
if [ -f "$rep" ]; then cat "$rep" > "$out"; else printf '{}' > "$out"; fi
valeur=200
[ -f "$w/api/$cle.code" ] && valeur=$(cat "$w/api/$cle.code")
printf '%s' "$valeur"
exit 0
FAUX
  } > "$work/bin/curl"
  chmod +x "$work/bin/curl"
}

cle_api() { printf '%s %s' "$1" "$2" | sed 's#[^A-Za-z0-9]#_#g'; }

api() { # $1 = méthode, $2 = chemin, $3 = code HTTP, $4 = corps
  local c; c=$(cle_api "$1" "$2"); mkdir -p "$work/api"
  printf '%s' "$4" > "$work/api/$c"
  printf '%s' "$3" > "$work/api/$c.code"
}

appels_api() { [[ -f $work/api-appels ]] && cat "$work/api-appels"; return 0; }

aucun_appel_api() {
  [[ ! -f $work/api-appels ]] \
    || { printf "la forge a été appelée malgré le refus :\n%s\n" "$(appels_api)" >&2; exit 1; }
}

# Un contrôle **lit**. Une méthode d'écriture envoyée par ce script poserait ou supprimerait un
# secret du dépôt : c'est la seule faute de cette story qui serait irréparable.
que_des_lectures() {
  local ligne
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    [[ $ligne == GET\ * ]] \
      || { printf "le contrôle a envoyé autre chose qu'une lecture : %s\n" "$ligne" >&2; exit 1; }
  done <<< "$(appels_api)"
}

# --- les réponses de la forge ------------------------------------------------------------------------

# Un tableau de secrets à la forme mesurée le 25/09/2026 : name, description, created_at, et jamais
# de valeur. Sans argument, le tableau vide — l'état réel du dépôt avant cette story.
# Les noms passent par « jq -n … --args » et non par « printf | jq -R » : ce dernier lit **ligne par
# ligne**, et un nom qui porte un saut de ligne y devenait deux entrées — le cas du nom hostile ne
# fabriquait donc pas ce qu'il prétendait fabriquer, et il passait même sans la garde (mesuré par
# mutation ; point 16 d'AGENTS.md, une fixture déclare ce que la vraie réponse déclare).
liste_json() {
  if (($# == 0)); then printf '[]'; return 0; fi
  jq -nc '[$ARGS.positional[] | {name: ., description: "", created_at: "2026-09-25T09:00:00Z"}]' --args "$@"
}

secrets_de_la_forge() { api GET "/repos/$repo/actions/secrets" 200 "$(liste_json "$@")"; }
variables_de_la_forge() { api GET "/repos/$repo/actions/variables" 200 "$(liste_json "$@")"; }

# Les douze noms attendus, lus **dans les fichiers du dépôt de test** : ce fichier de test n'en
# recopie aucun, comme le script lui-même n'en recopie aucun.
noms_attendus() {
  sed -n -E 's/^(HUGO_LEGAL_[A-Za-z0-9_]*)=.*/\1/p' "$depot/ci/legal-placeholder.env"
  grep -E '^[A-Za-z_][A-Za-z0-9_]*$' "$depot/ci/release-secrets.txt"
}

# --- le dépôt de test ---------------------------------------------------------------------------------

depot_de_test() {
  new_repo
  mkdir -p "$depot/ci"
  cp "$root/ci/legal-placeholder.env" "$depot/ci/legal-placeholder.env"
  cp "$root/ci/release-secrets.txt" "$depot/ci/release-secrets.txt"
  printf 'site\n' > "$depot/site.txt"
  git -C "$depot" add -A
  git -C "$depot" commit -q -m "dépôt d'essai"
  git -C "$depot" remote add origin "ssh://git@forge.invalide/$repo.git"
  printf 'GITEA_URL=https://forge.invalide\nGITEA_USER=compte-essai\nGITEA_TOKEN=jeton-essai\n' > "$depot/.env"
  faux_curl
  api GET /user 200 '{"login":"compte-essai"}'
}

lance() { # arguments du script
  run env -i PATH="$work/bin:$PATH" HOME="$work" TMPDIR="$work" LC_ALL=C \
    bash -c 'cd "$1" && shift && exec bash "$@"' _ "$depot" "$script" "$@"
}

# Les lignes « manquant … » du rapport, sans leur libellé.
manquants() { sed -n -E 's/^ +manquant +//p' <<< "$out"; }
inattendus() { sed -n -E 's/^ +inattendu +//p' <<< "$out"; }
variables_vues() { sed -n -E 's/^ +variable +//p' <<< "$out"; }

# --- l'état réel du dépôt avant la story : aucun secret --------------------------------------------------

case_forge_secrets_aucun_secret_les_douze_manquent() {
  # C'est le cas nominal de départ, et le seul que la story ait pu confronter au réel : le 25/09/2026
  # la forge rendait [] pour les deux listes.
  depot_de_test
  secrets_de_la_forge
  variables_de_la_forge
  lance
  assert_eq 1 "$rc" "douze secrets manquants sont un refus (messages : $err)"
  assert_eq "$(noms_attendus | LC_ALL=C sort)" "$(manquants | LC_ALL=C sort)" \
    "les douze attendus sont nommés un à un"
  assert_eq "" "$(inattendus)" "aucun secret inattendu"
  assert_eq "" "$(variables_vues)" "aucune variable"
  assert_contains "manquant(s)" "$err" "le refus dit combien il en manque"
  que_des_lectures
}

case_forge_secrets_douze_attendus() {
  # Le nombre, et non la liste : la liste vit dans ci/legal-placeholder.env et ci/release-secrets.txt.
  # Un treizième secret ajouté à l'architecture sans décision fait échouer ce cas.
  depot_de_test
  assert_eq 12 "$(noms_attendus | wc -l)" "huit valeurs légales et quatre autres"
  secrets_de_la_forge
  variables_de_la_forge
  lance
  assert_contains "12 secrets attendus" "$out" "le rapport annonce douze attendus"
}

# --- l'installation faite ------------------------------------------------------------------------------

case_forge_secrets_les_douze_presents() {
  local noms=()
  depot_de_test
  mapfile -t noms < <(noms_attendus)
  secrets_de_la_forge "${noms[@]}"
  variables_de_la_forge
  lance
  assert_eq 0 "$rc" "les douze présents passent (messages : $err)"
  assert_eq "" "$(manquants)" "rien ne manque"
  assert_contains "Aucune valeur n'a été lue" "$out" "le rapport le dit, même quand tout passe"
  que_des_lectures
}

case_forge_secrets_un_seul_manquant() {
  # Le rapport ne nomme que celui-là : un rapport qui relisterait les douze ferait chercher l'erreur
  # partout.
  local noms=() garde=()
  depot_de_test
  mapfile -t noms < <(noms_attendus)
  local nom
  for nom in "${noms[@]}"; do
    [[ $nom == DEPLOY_KNOWN_HOSTS ]] || garde+=("$nom")
  done
  secrets_de_la_forge "${garde[@]}"
  variables_de_la_forge
  lance
  assert_eq 1 "$rc" "un seul manquant reste un refus (messages : $err)"
  assert_eq "DEPLOY_KNOWN_HOSTS" "$(manquants)" "seul le manquant est nommé"
}

# --- ce qui est signalé sans bloquer ---------------------------------------------------------------------

case_forge_secrets_inattendu_ne_bloque_pas() {
  # ANTHROPIC_API_KEY appartient à l'epic 12 (AD-16) : posé d'avance, il est nommé et ne fait pas
  # échouer une installation par ailleurs complète.
  local noms=()
  depot_de_test
  mapfile -t noms < <(noms_attendus)
  secrets_de_la_forge "${noms[@]}" ANTHROPIC_API_KEY
  variables_de_la_forge
  lance
  assert_eq 0 "$rc" "un secret inattendu ne bloque pas (messages : $err)"
  assert_eq "ANTHROPIC_API_KEY" "$(inattendus)" "il est nommé"
  assert_contains "epic 12" "$out" "le rapport dit pourquoi il ne bloque pas"
}

case_forge_secrets_faute_de_frappe_apparait_deux_fois() {
  # Un DEPLOY_HOSTS posé à la place de DEPLOY_HOST se lit deux fois : manquant **et** inattendu.
  # C'est exactement ce qu'on veut voir, et ce qu'une simple liste des manquants ne montrerait pas.
  local noms=() garde=()
  depot_de_test
  mapfile -t noms < <(noms_attendus)
  local nom
  for nom in "${noms[@]}"; do
    [[ $nom == DEPLOY_HOST ]] || garde+=("$nom")
  done
  secrets_de_la_forge "${garde[@]}" DEPLOY_HOSTS
  variables_de_la_forge
  lance
  assert_eq 1 "$rc" "la faute de frappe est un refus (messages : $err)"
  assert_eq "DEPLOY_HOST" "$(manquants)" "le vrai nom manque"
  assert_eq "DEPLOY_HOSTS" "$(inattendus)" "le nom fautif est signalé"
}

case_forge_secrets_variable_signalee_sans_bloquer() {
  # L'architecture n'attend **aucune** variable (ARCHITECTURE-SPINE.md, « Secrets et variables CI ») :
  # celles qu'on trouve sont nommées, et rien de plus.
  local noms=()
  depot_de_test
  mapfile -t noms < <(noms_attendus)
  secrets_de_la_forge "${noms[@]}"
  variables_de_la_forge SITE_TAG
  lance
  assert_eq 0 "$rc" "une variable ne bloque pas (messages : $err)"
  assert_eq "SITE_TAG" "$(variables_vues)" "elle est nommée"
  assert_contains "n'attend aucune variable" "$out" "le rapport dit pourquoi elle est là"
}

# --- aucune valeur, jamais ---------------------------------------------------------------------------------

case_forge_secrets_aucune_valeur_affichee() {
  # L'API ne rend pas la valeur d'un secret ; elle rend une description, qu'un jour quelqu'un pourrait
  # remplir d'une valeur. Rien de ce qui vient de la réponse, hors le nom, n'atteint la sortie.
  local noms=() corps
  depot_de_test
  mapfile -t noms < <(noms_attendus)
  corps=$(liste_json "${noms[@]}" | jq -c '[.[] | .description = "MARQUEUR-A-NE-PAS-AFFICHER"]')
  api GET "/repos/$repo/actions/secrets" 200 "$corps"
  variables_de_la_forge
  lance
  assert_eq 0 "$rc" "la réponse est lue normalement (messages : $err)"
  [[ $out != *MARQUEUR-A-NE-PAS-AFFICHER* && $err != *MARQUEUR-A-NE-PAS-AFFICHER* ]] \
    || { echo "la description de la réponse est apparue dans la sortie" >&2; exit 1; }
}

case_forge_secrets_nom_hostile_neutralise() {
  # Un nom vient de la forge, pas du dépôt : il s'affiche par « %q ». Sans cela, un saut de ligne
  # dans un nom fabriquerait une ligne de rapport entière.
  local noms=()
  depot_de_test
  mapfile -t noms < <(noms_attendus)
  # La charge imite **exactement** une ligne du rapport, indentation comprise : sans les deux
  # espaces de tête, l'injection ne ressemblerait à rien et le cas passerait même sans la garde
  # (mesuré par mutation — la première version de ce cas ne tombait pas).
  secrets_de_la_forge "${noms[@]}" "$(printf 'MAUVAIS\n  manquant   DEPLOY_HOST')"
  variables_de_la_forge
  lance
  assert_eq 0 "$rc" "les douze sont là malgré le nom hostile (messages : $err)"
  assert_eq "" "$(manquants)" "le saut de ligne n'a pas fabriqué de ligne « manquant »"
  assert_contains "MAUVAIS" "$(inattendus)" "le nom hostile est signalé"
}

# --- ce que la forge répond mal ------------------------------------------------------------------------------

case_forge_secrets_jeton_sans_la_portee() {
  # 401 et 403 disent la même chose et ne se corrigent pas au même endroit qu'un 404 : un message
  # par cause, jamais « erreur ».
  local code
  # Le dépôt de test est bâti **une seule fois** : un second « git remote add origin » échoue, et son
  # code 3 serait compté par run.sh comme un cas « ignoré », pas comme un échec (constaté ici).
  depot_de_test
  for code in 401 403; do
    rm -f "$work/api-appels"
    api GET "/repos/$repo/actions/secrets" "$code" '{"message":"token does not have at least one of required scope(s)"}'
    lance
    assert_eq 2 "$rc" "HTTP $code est une anomalie (messages : $err)"
    assert_contains "portée" "$err" "le message dit ce qui manque au jeton"
    assert_contains "$code" "$err" "le message donne le code"
  done
}

case_forge_secrets_depot_ou_endpoint_absent() {
  depot_de_test
  api GET "/repos/$repo/actions/secrets" 404 '{"message":"Not Found"}'
  lance
  assert_eq 2 "$rc" "un 404 est une anomalie (messages : $err)"
  assert_contains "404" "$err" "le message donne le code"
  assert_contains "endpoint" "$err" "le message distingue le dépôt du point d'API"
  [[ $err != *portée* ]] || { echo "le message du 404 parle de la portée du jeton" >&2; exit 1; }
}

case_forge_secrets_forge_injoignable() {
  # curl sans réponse : gitea_api rend 000. Le message ne cite jamais l'adresse de la forge (NFR-9).
  depot_de_test
  api GET "/repos/$repo/actions/secrets" 000 ''
  lance
  assert_eq 2 "$rc" "une forge injoignable est une anomalie (messages : $err)"
  assert_contains "injoignable" "$err" "le message le dit"
  [[ $err != *forge.invalide* ]] || { echo "l'adresse de la forge est apparue (NFR-9)" >&2; exit 1; }
}

case_forge_secrets_code_inattendu() {
  depot_de_test
  api GET "/repos/$repo/actions/secrets" 500 '{"message":"internal"}'
  lance
  assert_eq 2 "$rc" "un 500 est une anomalie (messages : $err)"
  assert_contains "500" "$err" "le message donne le code"
}

case_forge_secrets_reponse_pas_un_tableau() {
  # La forme de la réponse a été mesurée : un tableau. Si elle change, le script s'arrête au lieu de
  # conclure « aucun secret » sur une réponse qu'il ne comprend pas — le pire des deux résultats.
  depot_de_test
  api GET "/repos/$repo/actions/secrets" 200 '{"secrets":[]}'
  lance
  assert_eq 2 "$rc" "une réponse qui n'est pas un tableau est une anomalie (messages : $err)"
  assert_contains "tableau" "$err" "le message dit ce qui cloche"
}

case_forge_secrets_entree_sans_nom() {
  depot_de_test
  api GET "/repos/$repo/actions/secrets" 200 '[{"description":"","created_at":"2026-09-25T09:00:00Z"}]'
  lance
  assert_eq 2 "$rc" "une entrée sans nom est une anomalie (messages : $err)"
  assert_contains "pas de nom" "$err" "le message dit ce qui manque"
}

case_forge_secrets_liste_trop_longue() {
  # La pagination de cet endpoint n'a jamais pu être mesurée : le dépôt n'avait aucun secret le jour
  # de la mesure. Au-delà du plafond, le script refuse de conclure plutôt que de déclarer manquant
  # ce qui serait sur la page suivante.
  local noms=() i
  depot_de_test
  for ((i = 1; i <= 21; i++)); do noms+=("SECRET_$i"); done
  secrets_de_la_forge "${noms[@]}"
  lance
  assert_eq 2 "$rc" "une liste trop longue est une anomalie (messages : $err)"
  assert_contains "pagination" "$err" "le message dit pourquoi"
}

# --- ce qui est refusé avant tout appel ---------------------------------------------------------------------

case_forge_secrets_argument_refuse() {
  depot_de_test
  lance --tout-poser
  assert_eq 2 "$rc" "ce script ne prend aucun argument (messages : $err)"
  assert_contains "usage" "$err" "le message donne l'usage"
  aucun_appel_api
}

case_forge_secrets_origine_non_canonique() {
  # Le jeton n'interroge pas les secrets d'un dépôt que personne n'a demandé.
  depot_de_test
  git -C "$depot" remote set-url origin "ssh://git@forge.invalide/quelquun/autre-chose.git"
  lance
  assert_eq 2 "$rc" "un autre dépôt distant est une anomalie (messages : $err)"
  assert_contains "Eleyone/eleyone.fr" "$err" "le message nomme le dépôt attendu"
  aucun_appel_api
}

case_forge_secrets_liste_des_quatre_absente() {
  depot_de_test
  rm -f "$depot/ci/release-secrets.txt"
  lance
  assert_eq 2 "$rc" "sans la liste des quatre, il n'y a rien à vérifier (messages : $err)"
  assert_contains "release-secrets.txt" "$err" "le message nomme le fichier"
  aucun_appel_api
}

case_forge_secrets_liste_des_quatre_vide() {
  # Un fichier **présent mais vide** n'est pas une conformité (piège connu, shell-scripts.md) : sans
  # cette garde, le contrôle vérifierait huit noms sur douze et passerait pour vert.
  depot_de_test
  printf '# que des commentaires\n\n' > "$depot/ci/release-secrets.txt"
  lance
  assert_eq 2 "$rc" "une liste sans nom est une anomalie (messages : $err)"
  assert_contains "vide" "$err" "le message le dit"
  aucun_appel_api
}

case_forge_secrets_liste_des_quatre_mal_formee() {
  depot_de_test
  printf 'PRIVATE_PATTERNS\nDEPLOY SSH KEY\n' > "$depot/ci/release-secrets.txt"
  lance
  assert_eq 2 "$rc" "une ligne mal formée est une anomalie (messages : $err)"
  assert_contains "ligne 2" "$err" "le message donne le numéro de la ligne"
  aucun_appel_api
}

case_forge_secrets_valeurs_legales_absentes() {
  depot_de_test
  rm -f "$depot/ci/legal-placeholder.env"
  lance
  assert_eq 2 "$rc" "sans les noms d'AD-9, il n'y a rien à vérifier (messages : $err)"
  assert_contains "legal-placeholder.env" "$err" "le message nomme le fichier"
  # Le message affirmé est **celui de cette garde-ci**, et non l'erreur de lecture de grep, qui
  # arrêterait aussi le script en citant le même chemin : sans cette ligne, retirer la garde ne
  # ferait pas tomber le cas (mesuré par mutation).
  assert_contains "absent ou illisible" "$err" "c'est bien le refus du fichier absent"
  aucun_appel_api
}

case_forge_secrets_valeurs_legales_vides() {
  depot_de_test
  printf '# aucune variable\n' > "$depot/ci/legal-placeholder.env"
  lance
  assert_eq 2 "$rc" "un fichier de valeurs légales sans variable est une anomalie (messages : $err)"
  assert_contains "AD-9" "$err" "le message dit ce qui manque"
  aucun_appel_api
}

case_forge_secrets_nom_attendu_deux_fois() {
  # Chaque fichier refuse ses propres doublons ; un nom présent dans les **deux** ne serait vu par
  # aucun des deux, et ferait annoncer treize attendus dont douze distincts.
  depot_de_test
  printf 'HUGO_LEGAL_HOST_EMAIL\n' >> "$depot/ci/release-secrets.txt"
  lance
  assert_eq 2 "$rc" "un nom attendu deux fois est une anomalie (messages : $err)"
  # Le message du **script**, celui qui croise les deux fichiers ; la bibliothèque, elle, dit
  # « ce nom est écrit deux fois » et cite une ligne. Les deux gardes se ressemblent assez pour que
  # chaque cas doive affirmer la sienne, sans quoi l'une couvrirait la mutation de l'autre
  # (mesuré par mutation).
  assert_contains "est attendu deux fois" "$err" "c'est la garde qui croise les deux fichiers"
  aucun_appel_api
}

case_forge_secrets_doublon_dans_la_liste() {
  depot_de_test
  printf 'DEPLOY_HOST\n' >> "$depot/ci/release-secrets.txt"
  lance
  assert_eq 2 "$rc" "un nom écrit deux fois dans la liste est une anomalie (messages : $err)"
  assert_contains "ce nom est écrit deux fois" "$err" "c'est la garde de la bibliothèque"
  assert_contains "ligne" "$err" "et elle donne la ligne fautive"
  aucun_appel_api
}

run_case "$@"
