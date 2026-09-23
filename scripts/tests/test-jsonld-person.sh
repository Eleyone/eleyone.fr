#!/usr/bin/env bash
# Données structurées « Person » : le partial qui les produit, et la règle de C10 qui les garde
# (story 9.6, FR-35, AD-20, D-7).
#
# Deux surfaces, deux façons de les éprouver :
#
#   - le **partial** se juge sur un vrai build : ses trois refus arrêtent Hugo, et rien d'autre
#     qu'un build ne le montre ;
#   - la **règle de C10** se juge sur un rendu doctoré, parce qu'il faut lui présenter des blocs
#     qu'aucun gabarit correct ne produirait — une clé manquante, un pays autre que FR, une entrée
#     vide. Un contrôle qu'on ne nourrit que de sorties conformes ne prouve rien.
#
# Les valeurs d'essai sont fabriquées ici et ne ressemblent à aucune vraie.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-jsonld-person
. "$root/scripts/lib/tools.sh"

readonly linkedin='https://exemple.invalide/in/essai/'
readonly github='https://exemple.invalide/essai'

# $1 = valeur d'identity, $2 = valeur de job_title, $3… = clés de contact à poser
construire() {
  local identity=$1 job=$2; shift 2
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content" "$work/site/assets"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$root/assets/css" "$work/site/assets/"
  local avant=""
  [[ -z $job ]] || avant="job_title: \"$job\""$'\n'
  printf -- '---\ntitle: "Accueil"\ntranslationKey: home\nidentity: "%s"\n%s---\n' \
    "$identity" "$avant" > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\ntranslationKey: home\nidentity: "%s"\n%s---\n' \
    "$identity" "$avant" > "$work/site/content/_index.en.md"
  local contact="" cle
  for cle in "$@"; do
    case $cle in
      linkedin) contact+="linkedin: $linkedin"$'\n' ;;
      github) contact+="github: $github"$'\n' ;;
    esac
  done
  printf -- '---\ntitle: "Contact"\ntranslationKey: contact\nslug: contact\nemail: e@exemple.invalide\n%s---\n\nTexte.\n' \
    "$contact" > "$work/site/content/contact.fr.md"
  printf -- '---\ntitle: "Contact"\ntranslationKey: contact\nslug: contact\nemail: e@exemple.invalide\n%s---\n\nText.\n' \
    "$contact" > "$work/site/content/contact.en.md"
  # Le code du build de **production** est celui que la fonction rend : les cas qui éprouvent les
  # refus du partial en dépendent. Une première écriture s'arrêtait par « … && return 0 » quand le
  # journal portait une erreur — donc rendait « réussi » précisément quand le build avait échoué.
  # Le cas de l'identity sans séparateur l'a dit tout de suite.
  local code=0
  (cd "$work/site" && hugo --environment production --minify --destination sortie) \
    > "$work/hugo.out" 2>&1 || code=$?
  # Le **rendu de travail** est construit aussi, quand la production a tenu : C10 y lit la ligne
  # d'identité, par le manifeste (AD-19), exactement comme check.sh le fait. Le fabriquer ici
  # plutôt que d'ajouter un crochet d'environnement au contrôle : une fixture qui ne ressemble pas
  # au vrai enchaînement ferait juger un contrôle sur un montage qui n'existe nulle part (point 16).
  # L'échec du rendu de travail est **propagé**, jamais avalé par un « || true » : les cas qui
  # éprouvent C10 s'appuient sur son manifeste, et un manifeste absent les aurait fait juger sur
  # rien (constat bloquant de la revue de la PR n° 102).
  if ((code == 0)); then
    (cd "$work/site" && hugo --environment work --buildDrafts --destination rendu) \
      >> "$work/hugo.out" 2>&1 || code=$?
  fi
  return "$code"
}

# Le bloc JSON-LD d'une page, tel quel. La **présence** du repère est affirmée : « ${x#*motif} »
# rend la chaîne inchangée quand le motif manque, et la fonction aurait rendu la page entière.
bloc() { # $1 = page
  local html repere='<script type=application/ld+json>'
  html=$(cat "$work/site/sortie/$1") || { echo "$1 : page illisible" >&2; return 1; }
  [[ $html == *"$repere"* ]] || { echo "$1 : aucun bloc JSON-LD" >&2; return 1; }
  html=${html#*"$repere"}
  [[ $html == *'</script>'* ]] || { echo "$1 : bloc JSON-LD non fermé" >&2; return 1; }
  printf '%s' "${html%%</script>*}"
}

cle() { # $1 = page, $2 = requête jq
  bloc "$1" | jq -r "$2"
}

# --- le partial -----------------------------------------------------------------------------------

case_jsonld_bloc_conforme() {
  run construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_eq 'Person' "$(cle index.html '."@type"')" "le type est Person"
  assert_eq 'Prénom Nom' "$(cle index.html '.name')" "name est le premier segment d identity"
  assert_eq 'Pseudo' "$(cle index.html '.alternateName')" "alternateName est le second"
  assert_eq 'Développeur' "$(cle index.html '.jobTitle')" "jobTitle vient de job_title"
  assert_eq 'PostalAddress' "$(cle index.html '.address."@type"')" "l adresse est une PostalAddress"
  assert_eq 'FR' "$(cle index.html '.address.addressCountry')" "et ne dit que le pays"
  assert_eq '2' "$(cle index.html '.sameAs | length')" "sameAs porte les deux profils"
}

case_jsonld_le_bloc_est_un_objet_et_non_une_chaine() {
  # Dans un « script », Go encode la sortie en **chaîne** JavaScript échappée si rien ne l'en
  # empêche : le bloc devenait « "{\"@type\":…}" » et aucun moteur ne l'aurait lu. Constaté sur le
  # rendu avant que « safeJS » ne soit posé.
  run construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  assert_eq 0 "$rc" "le build réussit"
  assert_eq 'object' "$(cle index.html 'type')" "le bloc est un objet JSON, pas une chaîne"
}

case_jsonld_lurl_est_celle_de_la_page() {
  # « baseURL » aurait fait annoncer la même adresse aux deux accueils, et l'anglais aurait
  # désigné la page française comme sienne (constat de la revue de spec).
  run construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  assert_eq 0 "$rc" "le build réussit"
  local fr en
  fr=$(cle index.html '.url'); en=$(cle en/index.html '.url')
  [[ $fr != "$en" ]] || { echo "les deux accueils annoncent la même url : $fr" >&2; exit 1; }
  assert_contains '/en/' "$en" "l accueil anglais annonce son propre chemin"
}

case_jsonld_le_nom_na_pas_despace_insecable_residuelle() {
  # Le séparateur de la ligne d'identité est précédé d'une espace **insécable** (DESIGN.md). Un
  # « trim » sur l'espace ordinaire la laissait, et « name » sortait avec une espace finale
  # invisible, dans un bloc destiné aux moteurs.
  run construire $'Prénom Nom · Pseudo' 'Développeur' linkedin github
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local nom; nom=$(cle index.html '.name')
  assert_eq 'Prénom Nom' "$nom" "l espace insécable est retirée comme les autres"
}

case_jsonld_un_lien_vide_est_omis() {
  # « Un lien vide est omis de sameAs, jamais remplacé par une valeur factice. »
  run construire 'Prénom Nom · Pseudo' 'Développeur' linkedin
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_eq '1' "$(cle index.html '.sameAs | length')" "seul le profil renseigné y figure"
  assert_eq "$linkedin" "$(cle index.html '.sameAs[0]')" "et c est bien lui"
}

case_jsonld_aucun_lien_omet_la_cle() {
  # Plutôt qu'un tableau vide, qui annoncerait une absence de profils comme une donnée.
  run construire 'Prénom Nom · Pseudo' 'Développeur'
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_eq 'false' "$(cle index.html 'has("sameAs")')" "sameAs disparaît entièrement"
}

case_jsonld_identity_sans_separateur_arrete_le_build() {
  run construire 'Prénom Nom' 'Développeur' linkedin github
  assert_eq 1 "$rc" "une identity sans séparateur arrête le build"
  assert_contains "exactement un séparateur" "$(cat "$work/hugo.out")" "et le message dit pourquoi"
}

case_jsonld_job_title_absent_arrete_le_build() {
  run construire 'Prénom Nom · Pseudo' '' linkedin github
  assert_eq 1 "$rc" "un job_title absent arrête le build"
  assert_contains "job_title" "$(cat "$work/hugo.out")" "et le message nomme la clé"
}

case_jsonld_seulement_sur_les_accueils() {
  run construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  assert_eq 0 "$rc" "le build réussit"
  # Le code du **premier** grep est lu : « … | grep -v … || true » absorbe tout le pipeline, et un
  # dossier illisible aurait rendu une liste vide que le cas aurait prise pour « rien hors des
  # accueils ». Quatrième instance de cette classe dans cette seule story (revue de la PR n° 102).
  local porteuses autres code=0
  porteuses=$(grep -rl 'application/ld+json' "$work/site/sortie" --include='*.html') || code=$?
  ((code <= 1)) || { echo "recherche impossible (grep, code $code) : rien n est affirmé" >&2; exit 1; }
  autres=$(grep -vE '/(en/)?index\.html$' <<< "$porteuses") || code=$?
  ((code <= 1)) || { echo "filtrage impossible (grep, code $code)" >&2; exit 1; }
  [[ -z ${autres//[[:space:]]/} ]] || { echo "un bloc JSON-LD hors des accueils : $autres" >&2; exit 1; }
}

# --- la règle de C10 ------------------------------------------------------------------------------

# Le contrôle est lancé sur un rendu **doctoré** : il faut lui présenter des blocs qu'aucun gabarit
# correct ne produit. Un bloc conforme seul ne prouve rien d'un contrôle.
#
# **Aucun outil hors de ceux que le projet déclare** : `jq` et `awk` seulement. Une première
# écriture doctorait le JSON en Python — absent de `CHECK_IMAGE`, dont `tools.env` ne liste que
# `git grep findutils jq libxml2-utils poppler-utils`. La suite passait au vert sur le poste et
# échouait en CI : un test qui dépend d'un outil non déclaré ne teste que la machine de celui qui
# l'écrit (constat de la CI de la PR n° 102).

# Remplace une occurrence **littérale** dans un fichier, sans expression régulière : le JSON porte
# des « / » et peut porter des « & », que `sed` interpréterait. Les deux chaînes passent par
# l'environnement et non par « awk -v », qui traite les séquences d'échappement de sa valeur.
remplacer_litteral() { # $1 = fichier, $2 = ancien, $3 = nouveau
  local fichier=$1
  ANCIEN=$2 NOUVEAU=$3 awk '
    BEGIN { a = ENVIRON["ANCIEN"]; b = ENVIRON["NOUVEAU"] }
    { i = index($0, a); if (i > 0) { $0 = substr($0, 1, i - 1) b substr($0, i + length(a)) } ; print }
  ' "$fichier" > "$fichier.doctore" || { echo "$fichier : remplacement impossible" >&2; exit 1; }
  mv "$fichier.doctore" "$fichier"
}

# Le bloc JSON-LD tel qu'il est écrit dans la page, balises comprises. Le JSON ne contient aucun
# « < », donc « [^<]* » le délimite sans ambiguïté sur un rendu minifié.
bloc_brut() { # $1 = fichier
  grep -o '<script type=application/ld+json>[^<]*</script>' "$1" \
    || { echo "$1 : aucun bloc JSON-LD à doctorer" >&2; exit 1; }
}

controle_sur_bloc_doctore() { # $1 = nom de la transformation
  local page=$work/site/sortie/index.html bloc json remplacement
  bloc=$(bloc_brut "$page")
  json=${bloc#*>}; json=${json%</script>}
  case $1 in
    aucun)             remplacement="" ;;
    deux-blocs)        remplacement="$bloc$bloc" ;;
    sans-jobtitle)     json=$(jq -c 'del(.jobTitle)' <<< "$json") ;;
    pays-autre)        json=$(jq -c '.address.addressCountry = "BE"' <<< "$json") ;;
    sans-type-adresse) json=$(jq -c 'del(.address."@type")' <<< "$json") ;;
    sameas-vide)       json=$(jq -c '.sameAs += [""]' <<< "$json") ;;
    adresse-chaine)    json=$(jq -c '.address = "FR"' <<< "$json") ;;
    sameas-chaine)     json=$(jq -c '.sameAs = "https://exemple.invalide/"' <<< "$json") ;;
    *) echo "transformation inconnue : $1" >&2; exit 1 ;;
  esac
  [[ -n ${remplacement+x} && ( $1 == aucun || $1 == deux-blocs ) ]] \
    || remplacement="<script type=application/ld+json>$json</script>"
  remplacer_litteral "$page" "$bloc" "$remplacement"
  run env CHECK_PUBLIC_ROOT="$work/site/sortie" CHECK_WORK_ROOT="$work/site/rendu" \
    bash "$root/scripts/checks/html.sh"
}

case_jsonld_c10_refuse_un_accueil_sans_bloc() {
  # La règle neuve : « au plus un » laissait passer zéro, et le site aurait perdu ses données
  # structurées sans que rien ne le dise.
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore aucun
  assert_eq 1 "$rc" "un accueil sans bloc fait échouer C10"
  assert_contains "aucun bloc JSON-LD sur l'accueil" "$err" "et le message le dit"
}

case_jsonld_c10_refuse_une_cle_requise_absente() {
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore sans-jobtitle
  assert_eq 1 "$rc" "une clé requise absente fait échouer C10"
  assert_contains "jobTitle" "$err" "et le message la nomme"
}

case_jsonld_c10_refuse_un_pays_autre_que_fr() {
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore pays-autre
  assert_eq 1 "$rc" "un pays autre que FR fait échouer C10"
  assert_contains "addressCountry" "$err" "et le message le nomme"
}

case_jsonld_c10_refuse_une_adresse_sans_type() {
  # La garde que j'avais d'abord écrite excusait ce cas : « [[ -z $type || $type == … ]] »
  # tolérait la valeur vide, donc l'absence — exactement ce qu'elle devait refuser.
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore sans-type-adresse
  assert_eq 1 "$rc" "une adresse sans @type fait échouer C10"
  assert_contains "PostalAddress" "$err" "et le message dit ce qui est attendu"
}

case_jsonld_c10_refuse_une_entree_vide_dans_sameas() {
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore sameas-vide
  assert_eq 1 "$rc" "une entrée vide dans sameAs fait échouer C10"
  assert_contains "sameAs" "$err" "et le message la nomme"
}

case_jsonld_c10_refuse_une_adresse_qui_nest_pas_un_objet() {
  # « address » réduite à une chaîne : schema.org attend un objet, et « .address.addressCountry »
  # ferait échouer jq. Sans la lecture du code de jq, ce bloc passait pour conforme — la
  # suppression d'erreur que la revue de la PR n° 102 a trouvée.
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore adresse-chaine
  assert_eq 1 "$rc" "une adresse qui n est pas un objet fait échouer C10"
  assert_contains "un objet PostalAddress est attendu" "$err" "et le message dit ce qui est attendu"
}

case_jsonld_c10_refuse_un_sameas_mal_type() {
  # « sameAs » réduit à une chaîne : le comptage des entrées vides échouait, et le bloc passait.
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore sameas-chaine
  assert_eq 1 "$rc" "un sameAs mal typé fait échouer C10, en écart et non en anomalie"
  assert_contains "un tableau est attendu" "$err" "et le message dit ce qui est attendu"
}

case_jsonld_c10_refuse_deux_blocs_sur_laccueil() {
  # La cardinalité exacte, éprouvée par le haut : « au plus un » est une règle ancienne de C10, et
  # rien ne la tenait par un cas isolé. L'injecteur portait déjà cette branche ; le cas qui
  # l'emploie manquait (constat de la revue de la PR n° 102).
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  controle_sur_bloc_doctore deux-blocs
  assert_eq 1 "$rc" "deux blocs sur l accueil font échouer C10"
  assert_contains "blocs JSON-LD" "$err" "et le message en donne le nombre"
}

case_jsonld_c10_refuse_un_bloc_hors_de_laccueil() {
  # L'autre moitié de la règle : un profil répété ailleurs dirait à un moteur que chaque page est
  # la personne. Le cas du partial vérifie que Hugo n'en produit pas ; celui-ci vérifie que C10 le
  # refuserait s'il en apparaissait un.
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  local bloc_accueil cible=$work/site/sortie/contact/index.html
  bloc_accueil=$(bloc_brut "$work/site/sortie/index.html")
  grep -q '</head>' "$cible" || { echo "$cible : pas de </head> où insérer" >&2; exit 1; }
  remplacer_litteral "$cible" '</head>' "$bloc_accueil</head>"
  run env CHECK_PUBLIC_ROOT="$work/site/sortie" CHECK_WORK_ROOT="$work/site/rendu" \
    bash "$root/scripts/checks/html.sh"
  assert_eq 1 "$rc" "un bloc hors de l accueil fait échouer C10"
  assert_contains "hors de l'accueil" "$err" "et le message le dit"
}

case_jsonld_c10_accepte_le_rendu_conforme() {
  # La contre-épreuve : sans elle, un contrôle qui refuserait tout passerait pour un contrôle
  # qui marche.
  construire 'Prénom Nom · Pseudo' 'Développeur' linkedin github
  run env CHECK_PUBLIC_ROOT="$work/site/sortie" CHECK_WORK_ROOT="$work/site/rendu" \
    bash "$root/scripts/checks/html.sh"
  assert_eq 0 "$rc" "le rendu conforme passe (messages : $err)"
}
run_case "$@"
