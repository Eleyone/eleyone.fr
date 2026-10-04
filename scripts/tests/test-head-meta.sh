#!/usr/bin/env bash
# Description et aperçu de partage de chaque page (story 9.8, AD-25, FR-40) : le partial qui les
# écrit, et C26 (scripts/checks/head-meta.sh) qui les vérifie.
#
# Deux surfaces, deux façons de les éprouver, comme test-jsonld-person.sh :
#
#   - le **partial** se juge sur un vrai build : son refus d'une description absente arrête Hugo, et
#     rien d'autre qu'un build ne le montre ;
#   - **C26** se juge sur un rendu doctoré, parce qu'il faut lui présenter des pages qu'aucun gabarit
#     correct ne produirait. Les pages d'essai reprennent la forme d'une page de la production —
#     doctype, <meta charset>, ordre et sérialisation minifiée des balises (point 16 d'AGENTS.md) —,
#     et un cas fait aussi tourner C26 sur la sortie d'un vrai build.
#
# Chaque cas qui éprouve une garde a été lancé une fois la garde retirée, pour le voir échouer
# (point 9 d'AGENTS.md ; la liste est dans le fichier de la story 9.8, § Implémentation).
#
# Les valeurs d'essai sont fabriquées ici et ne ressemblent à aucune vraie.
. "$(dirname "${BASH_SOURCE[0]}")/../../.working-method/tests/lib.sh"
script_name=test-head-meta
. "$root/scripts/lib/tools.sh"

readonly base_essai=https://exemple.invalide/
readonly nbsp=$' '

# ===================================================================================================
# C26 sur un rendu doctoré
# ===================================================================================================

controle() {
  run env CHECK_PUBLIC_ROOT="$work/public" CHECK_BASE_URL="$base_essai" bash "$root/scripts/checks/head-meta.sh"
}

# Les balises d'une page conforme, dans l'ordre et la sérialisation du build minifié.
# $1 description (déjà échappée pour un attribut), $2 titre, $3 og:type, $4 og:url, $5 og:locale,
# $6… og:locale:alternate (aucune si absent)
balises() {
  local description=$1 titre=$2 type=$3 url=$4 locale=$5; shift 5
  local s
  s="<meta name=description content=\"$description\"><meta property=\"og:title\" content=\"$titre\">"
  s+="<meta property=\"og:description\" content=\"$description\"><meta property=\"og:type\" content=\"$type\">"
  s+="<meta property=\"og:url\" content=\"$url\"><meta property=\"og:locale\" content=\"$locale\">"
  local alternate
  for alternate in "$@"; do s+="<meta property=\"og:locale:alternate\" content=\"$alternate\">"; done
  printf '%s' "$s"
}

# Les liens hreflang de baseof.html : $1… = « langue=url » ; x-default vers le français s'il existe.
hreflangs() {
  local s="" paire defaut=""
  for paire in "$@"; do
    s+="<link rel=alternate hreflang=${paire%%=*} href=${paire#*=}>"
    [[ ${paire%%=*} != fr ]] || defaut=${paire#*=}
  done
  [[ -z $defaut ]] || s+="<link rel=alternate hreflang=x-default href=$defaut>"
  printf '%s' "$s"
}

# $1 chemin, $2 langue, $3 titre, $4 balises, $5 liens hreflang, $6 balises ajoutées en fin de <head>
page() {
  mkdir -p "$(dirname "$work/public/$1")"
  printf '<!doctype html><html lang=%s><head><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1"><title>%s</title>%s%s<link rel=stylesheet href=/css/main.min.0123.css>%s</head><body><a class=skip-link href=#content>Aller au contenu</a><main id=content class=frame><h1>%s</h1><p>Texte.</p></main></body></html>' \
    "$2" "$3" "$4" "$5" "${6:-}" "$3" > "$work/public/$1"
}

readonly desc_fr="Une description d'essai${nbsp}: un &amp; deux, « trois »."
readonly desc_en="A test description: one &amp; two."
readonly titre_accueil_fr="Prénom Nom · Développeur"
readonly titre_accueil_en="Prénom Nom · Developer"
readonly titre_fr="À propos${nbsp}· Prénom Nom · Pseudo"
readonly titre_en="About${nbsp}· Prénom Nom · Pseudo"

# Les pages d'un rendu conforme : deux accueils, une page traduite, les deux 404, et une page
# française **sans traduction** (le cas où og:locale:alternate doit manquer).
accueil_fr() { page index.html fr "$titre_accueil_fr" "$(balises "$desc_fr" "$titre_accueil_fr" website "$base_essai" fr_FR en_US)" "$(hreflangs "fr=$base_essai" "en=${base_essai}en/")" "${1:-}"; }
apropos_fr() { page a-propos/index.html fr "$titre_fr" "${1:-$(balises "$desc_fr" "$titre_fr" article "${base_essai}a-propos/" fr_FR en_US)}" "$(hreflangs "fr=${base_essai}a-propos/" "en=${base_essai}en/about/")" "${2:-}"; }
seule_fr() { page cas/seule/index.html fr "$titre_fr" "${1:-$(balises "$desc_fr" "$titre_fr" article "${base_essai}cas/seule/" fr_FR)}" "$(hreflangs "fr=${base_essai}cas/seule/")"; }

site() {
  rm -rf "$work/public"
  mkdir -p "$work/public"
  accueil_fr
  page en/index.html en "$titre_accueil_en" "$(balises "$desc_en" "$titre_accueil_en" website "${base_essai}en/" en_US fr_FR)" "$(hreflangs "fr=$base_essai" "en=${base_essai}en/")"
  apropos_fr
  page en/about/index.html en "$titre_en" "$(balises "$desc_en" "$titre_en" article "${base_essai}en/about/" en_US fr_FR)" "$(hreflangs "fr=${base_essai}a-propos/" "en=${base_essai}en/about/")"
  page 404.html fr "Page introuvable${nbsp}· Prénom Nom" "$(balises "$desc_fr" "Page introuvable${nbsp}· Prénom Nom" article "${base_essai}404.html" fr_FR en_US)" "$(hreflangs "fr=${base_essai}404.html" "en=${base_essai}en/404.html")"
  page en/404.html en "Page not found${nbsp}· Prénom Nom" "$(balises "$desc_en" "Page not found${nbsp}· Prénom Nom" article "${base_essai}en/404.html" en_US fr_FR)" "$(hreflangs "fr=${base_essai}404.html" "en=${base_essai}en/404.html")"
  seule_fr
  printf '<?xml version="1.0" encoding="utf-8"?><urlset></urlset>' > "$work/public/sitemap.xml"
}

# La page « À propos » avec une balise retirée ou remplacée. $1 = motif de la balise à retirer
# (sous-chaîne exacte, retirée par l'expansion de bash et non par sed : « & » n'y a pas de sens
# spécial), $2 = balise à mettre à la place.
apropos_modifiee() {
  local tags
  tags=$(balises "$desc_fr" "$titre_fr" article "${base_essai}a-propos/" fr_FR en_US)
  [[ $tags == *"$1"* ]] || { echo "motif absent des balises : $1" >&2; exit 1; }
  apropos_fr "${tags/"$1"/"${2:-}"}"
}

case_c26_rendu_conforme() {
  site
  controle
  assert_eq 0 "$rc" "un rendu conforme passe (messages : $err)"
  assert_contains "chaque page porte sa description" "$out" "le contrôle le dit"
}

case_c26_description_absente() {
  site
  apropos_modifiee "<meta name=description content=\"$desc_fr\">"
  controle
  assert_eq 1 "$rc" "une page sans description fait échouer"
  assert_contains "a-propos/index.html: C26 : 0 balise(s) <meta name=\"description\">" "$err" "la page et le défaut sont nommés"
}

case_c26_deux_descriptions() {
  site
  apropos_fr "" "<meta name=description content=\"$desc_fr\">"
  controle
  assert_eq 1 "$rc" "deux descriptions font échouer"
  assert_contains "a-propos/index.html: C26 : 2 balise(s) <meta name=\"description\">" "$err" "le doublon est nommé"
}

case_c26_doublon_ecrit_dans_une_autre_casse() {
  # Un moteur lit « NAME=DESCRIPTION » comme l'autre : un doublon ainsi écrit doit se voir.
  site
  apropos_fr "" "<meta NAME=DESCRIPTION content=\"Autre\">"
  controle
  assert_eq 1 "$rc" "le doublon en majuscules fait échouer"
  assert_contains "2 balise(s) <meta name=\"description\">" "$err" "il est compté"
}

case_c26_description_vide() {
  site
  local tags
  tags=$(balises "  " "$titre_fr" article "${base_essai}a-propos/" fr_FR en_US)
  apropos_fr "$tags"
  controle
  assert_eq 1 "$rc" "une description blanche fait échouer"
  assert_contains "a-propos/index.html: C26 : <meta name=\"description\"> vide" "$err" "le défaut est nommé"
}

case_c26_description_todo() {
  site
  apropos_fr "$(balises "[TODO: description]" "$titre_fr" article "${base_essai}a-propos/" fr_FR en_US)"
  controle
  assert_eq 1 "$rc" "un [TODO dans la description fait échouer"
  assert_contains "a-propos/index.html: C26 : la description porte un marqueur [TODO" "$err" "le défaut est nommé"
}

case_c26_og_description_differente() {
  site
  apropos_modifiee "<meta property=\"og:description\" content=\"$desc_fr\">" \
    "<meta property=\"og:description\" content=\"Une autre description\">"
  controle
  assert_eq 1 "$rc" "une og:description différente fait échouer"
  assert_contains "a-propos/index.html: C26 : og:description diffère" "$err" "le défaut est nommé"
}

case_c26_chaque_balise_og_absente() {
  # Les cinq balises qu'AD-25 exige, retirées une à une : chacune doit être réclamée par son nom.
  local balise motif
  for balise in og:title og:description og:type og:url og:locale; do
    site
    motif=$(balises "$desc_fr" "$titre_fr" article "${base_essai}a-propos/" fr_FR en_US)
    motif=${motif#*"<meta property=\"$balise\" content=\""}
    motif="<meta property=\"$balise\" content=\"${motif%%\">*}\">"
    apropos_modifiee "$motif"
    controle
    assert_eq 1 "$rc" "$balise absente fait échouer"
    assert_contains "a-propos/index.html: C26 : 0 balise(s) $balise, une seule attendue" "$err" "$balise est réclamée par son nom"
  done
}

case_c26_balise_og_en_double() {
  site
  apropos_fr "" "<meta name=\"og:type\" content=\"article\">"
  controle
  assert_eq 1 "$rc" "une balise Open Graph doublée en name= fait échouer"
  assert_contains "2 balise(s) og:type" "$err" "le doublon est compté quel que soit l attribut"
}

case_c26_og_title_different_du_titre() {
  site
  apropos_modifiee "<meta property=\"og:title\" content=\"$titre_fr\">" "<meta property=\"og:title\" content=\"À propos\">"
  controle
  assert_eq 1 "$rc" "un og:title différent du <title> fait échouer"
  assert_contains "a-propos/index.html: C26 : og:title « À propos » diffère du <title>" "$err" "le défaut est nommé"
}

case_c26_og_url_relative() {
  site
  apropos_modifiee "<meta property=\"og:url\" content=\"${base_essai}a-propos/\">" "<meta property=\"og:url\" content=\"/a-propos/\">"
  controle
  assert_eq 1 "$rc" "un og:url relatif fait échouer"
  assert_contains "n'est pas une URL absolue en https://" "$err" "le défaut est nommé"
}

case_c26_og_url_en_http() {
  site
  apropos_modifiee "<meta property=\"og:url\" content=\"${base_essai}a-propos/\">" "<meta property=\"og:url\" content=\"http://exemple.invalide/a-propos/\">"
  controle
  assert_eq 1 "$rc" "un og:url en http fait échouer"
  assert_contains "n'est pas une URL absolue en https://" "$err" "le défaut est nommé"
}

case_c26_og_url_dune_autre_page() {
  site
  apropos_modifiee "<meta property=\"og:url\" content=\"${base_essai}a-propos/\">" "<meta property=\"og:url\" content=\"${base_essai}\">"
  controle
  assert_eq 1 "$rc" "un og:url qui désigne une autre page fait échouer"
  assert_contains "« ${base_essai}a-propos/ » attendue pour cette page" "$err" "l URL attendue est dite"
}

case_c26_og_url_dun_autre_hote() {
  site
  apropos_modifiee "<meta property=\"og:url\" content=\"${base_essai}a-propos/\">" "<meta property=\"og:url\" content=\"https://autre.invalide/a-propos/\">"
  controle
  assert_eq 1 "$rc" "un og:url sur un autre hôte fait échouer"
}

case_c26_og_url_encodee_dun_chemin_non_ascii() {
  # Un slug accentué : Hugo encode le chemin en %XX dans le permalien, le fichier porte le chemin
  # brut. Les deux désignent la même page.
  site
  page "cas/éé/index.html" fr "$titre_fr" "$(balises "$desc_fr" "$titre_fr" article "${base_essai}cas/%C3%A9%C3%A9/" fr_FR)" "$(hreflangs "fr=${base_essai}cas/%C3%A9%C3%A9/")"
  controle
  assert_eq 0 "$rc" "l URL encodée d un chemin accentué passe (messages : $err)"
}

case_c26_og_type_de_laccueil() {
  site
  local tags
  tags=$(balises "$desc_fr" "$titre_accueil_fr" article "$base_essai" fr_FR en_US)
  page index.html fr "$titre_accueil_fr" "$tags" "$(hreflangs "fr=$base_essai" "en=${base_essai}en/")"
  controle
  assert_eq 1 "$rc" "un accueil en og:type article fait échouer"
  assert_contains "index.html: C26 : og:type « article », « website » attendu" "$err" "le défaut est nommé"
}

case_c26_og_type_dune_page() {
  site
  apropos_modifiee "<meta property=\"og:type\" content=\"article\">" "<meta property=\"og:type\" content=\"website\">"
  controle
  assert_eq 1 "$rc" "une page en og:type website fait échouer"
  assert_contains "a-propos/index.html: C26 : og:type « website », « article » attendu" "$err" "le défaut est nommé"
}

case_c26_og_locale_incoherente() {
  site
  apropos_modifiee "<meta property=\"og:locale\" content=\"fr_FR\">" "<meta property=\"og:locale\" content=\"en_US\">"
  controle
  assert_eq 1 "$rc" "une locale anglaise sur une page française fait échouer"
  assert_contains "og:locale « en_US », « fr_FR » attendue pour <html lang=\"fr\">" "$err" "le défaut est nommé"
}

case_c26_langue_sans_locale() {
  site
  page de/index.html de "Titel" "$(balises "$desc_en" "Titel" website "${base_essai}de/" de_DE)" "$(hreflangs "de=${base_essai}de/")"
  controle
  assert_eq 1 "$rc" "une langue sans locale connue fait échouer"
  assert_contains "de/index.html: C26 : <html lang=\"de\"> sans locale Open Graph connue" "$err" "le défaut est nommé"
}

case_c26_alternate_sans_traduction() {
  site
  seule_fr "$(balises "$desc_fr" "$titre_fr" article "${base_essai}cas/seule/" fr_FR en_US)"
  controle
  assert_eq 1 "$rc" "une alternative sur une page sans traduction fait échouer"
  assert_contains "cas/seule/index.html: C26 : og:locale:alternate présente alors que la page n'a pas de traduction" "$err" "le défaut est nommé"
}

case_c26_alternate_absente_avec_traduction() {
  site
  apropos_modifiee "<meta property=\"og:locale:alternate\" content=\"en_US\">"
  controle
  assert_eq 1 "$rc" "une page traduite sans alternative fait échouer"
  assert_contains "a-propos/index.html: C26 : og:locale:alternate absente alors que la page a une traduction (en_US)" "$err" "le défaut est nommé"
}

case_c26_alternate_fausse_ou_doublee() {
  site
  apropos_modifiee "<meta property=\"og:locale:alternate\" content=\"en_US\">" "<meta property=\"og:locale:alternate\" content=\"en_US\"><meta property=\"og:locale:alternate\" content=\"en_US\">"
  controle
  assert_eq 1 "$rc" "une alternative doublée fait échouer"
  site
  apropos_modifiee "<meta property=\"og:locale:alternate\" content=\"en_US\">" "<meta property=\"og:locale:alternate\" content=\"en_GB\">"
  controle
  assert_eq 1 "$rc" "une alternative qui n est pas la locale de la traduction fait échouer"
  assert_contains "og:locale:alternate « en_GB », « en_US » attendue(s)" "$err" "les deux valeurs sont dites"
}

case_c26_og_image_refusee() {
  site
  apropos_fr "" "<meta property=\"og:image\" content=\"${base_essai}images/portrait.webp\">"
  controle
  assert_eq 1 "$rc" "une og:image fait échouer"
  assert_contains "a-propos/index.html: C26 : 1 balise(s) og:image" "$err" "le défaut est nommé"
  site
  apropos_fr "" "<meta property=\"og:image:width\" content=\"640\">"
  controle
  assert_eq 1 "$rc" "une balise og:image:* seule fait échouer aussi"
}

case_c26_aucune_page_est_une_anomalie() {
  rm -rf "$work/public"; mkdir -p "$work/public"
  printf 'User-agent: *\n' > "$work/public/robots.txt"
  controle
  assert_eq 2 "$rc" "un rendu sans page HTML est une anomalie, jamais un succès"
  assert_contains "aucune page HTML" "$err" "le message le dit"
}

case_c26_page_illisible_est_une_anomalie() {
  # Une lecture XPath en échec ne doit pas devenir « balise absente » : l'anomalie de checks_xpath,
  # levée dans une substitution, est propagée par « lire » au lieu d'être avalée (même garde que
  # C23, legal-address.sh).
  skip_if_root "une page rendue illisible par chmod"
  site
  chmod 000 "$work/public/a-propos/index.html"
  controle
  assert_eq 2 "$rc" "une page illisible est une anomalie, pas un écart de contenu (messages : $err)"
}

case_c26_rendu_absent_est_une_anomalie() {
  rm -rf "$work/public"
  controle
  assert_eq 2 "$rc" "un rendu absent est une anomalie"
}

case_c26_baseurl_en_http_est_une_anomalie() {
  site
  run env CHECK_PUBLIC_ROOT="$work/public" CHECK_BASE_URL=http://exemple.invalide/ bash "$root/scripts/checks/head-meta.sh"
  assert_eq 2 "$rc" "une baseURL en http est une anomalie de configuration"
  assert_contains "n'est pas en https://" "$err" "le message le dit"
}

case_c26_baseurl_lue_dans_la_configuration() {
  # Sans CHECK_BASE_URL, la baseURL vient de config/_default/hugo.yaml, comme pour html.sh : un
  # rendu fait pour une autre adresse doit être refusé.
  site
  run env CHECK_PUBLIC_ROOT="$work/public" bash "$root/scripts/checks/head-meta.sh"
  assert_eq 1 "$rc" "des og:url d un autre hôte que la baseURL du dépôt font échouer"
  assert_contains "https://eleyone.fr/a-propos/" "$err" "l URL attendue vient de la configuration"
}

# ===================================================================================================
# Le partial, sur un vrai build
# ===================================================================================================

# $1 = description de l'accueil français (vide : pas de clé), $2 = description de « À propos » en
# français (vide : pas de clé), $3 = summary du cas (vide : pas de clé)
construire() {
  local desc_accueil=$1 desc_apropos=$2 resume=$3
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content/cases" "$work/site/assets"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$root/assets/css" "$work/site/assets/"
  local cle
  cle=""; [[ -z $desc_accueil ]] || cle="description: '${desc_accueil//\'/\'\'}'"$'\n'
  printf -- '---\ntitle: "Prénom Nom · Développeur"\ntranslationKey: home\nidentity: "Prénom Nom · Pseudo"\njob_title: "Développeur"\n%s---\n' \
    "$cle" > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Prénom Nom · Developer"\ntranslationKey: home\nidentity: "Prénom Nom · Pseudo"\njob_title: "Developer"\ndescription: "Home page : test."\n---\n' \
    > "$work/site/content/_index.en.md"
  cle=""; [[ -z $desc_apropos ]] || cle="description: '${desc_apropos//\'/\'\'}'"$'\n'
  printf -- '---\ntitle: "À propos"\ntranslationKey: about\nslug: a-propos\n%s---\n\nTexte.\n' \
    "$cle" > "$work/site/content/about.fr.md"
  printf -- '---\ntitle: "About"\ntranslationKey: about\nslug: about\ndescription: "About : test."\n---\n\nText.\n' \
    > "$work/site/content/about.en.md"
  # Un cas sans traduction : og:locale:alternate doit y manquer.
  printf -- '---\ntranslationKey: cases\nbuild:\n  render: never\n  list: never\n---\n' > "$work/site/content/cases/_index.fr.md"
  cle=""; [[ -z $resume ]] || cle="summary: '${resume//\'/\'\'}'"$'\n'
  printf -- '---\ntitle: "Cas d essai"\ntranslationKey: case-09\nnumber: "09"\nslug: essai\ndraft: false\n%scontext:\n  company: "Essai"\n  role: "Rôle"\n  period: "2020"\n  stack: ["PHP"]\n---\n\n## Contexte\n\nTexte.\n' \
    "$cle" > "$work/site/content/cases/case-09-essai.fr.md"
  (cd "$work/site" && hugo --environment production --minify --destination sortie) > "$work/hugo.out" 2>&1
}

contenu_meta() { # $1 = page, $2 = sélecteur de la balise
  xmllint --html --xpath "string($2/@content)" "$work/site/sortie/$1" 2> /dev/null
}

case_partial_balises_rendues_et_c26_passe_sur_un_vrai_build() {
  run construire "Accueil d'essai : texte." "À propos d'essai." "Résumé du cas d'essai."
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_eq "Résumé du cas d'essai." "$(contenu_meta cas/essai/index.html '//meta[@name="description"]')" "la description d un cas est son summary"
  assert_eq "À propos d'essai." "$(contenu_meta a-propos/index.html '//meta[@name="description"]')" "celle d une page est sa clé description"
  assert_eq "website" "$(contenu_meta index.html '//meta[@property="og:type"]')" "l accueil est un website"
  assert_eq "article" "$(contenu_meta a-propos/index.html '//meta[@property="og:type"]')" "une page est un article"
  assert_eq "https://eleyone.fr/en/about/" "$(contenu_meta en/about/index.html '//meta[@property="og:url"]')" "og:url est le permalien absolu"
  assert_eq "en_US" "$(contenu_meta a-propos/index.html '//meta[@property="og:locale:alternate"]')" "une page traduite annonce sa traduction"
  assert_eq "" "$(contenu_meta cas/essai/index.html '//meta[@property="og:locale:alternate"]')" "une page sans traduction n en annonce aucune"
  assert_eq "https://eleyone.fr/404.html" "$(contenu_meta 404.html '//meta[@property="og:url"]')" "la 404 porte son propre permalien (constat N1)"
  assert_contains "Cette page n'existe pas." "$(contenu_meta 404.html '//meta[@name="description"]')" "la 404 a sa description, lue dans i18n/"
  assert_contains "This page does not exist." "$(contenu_meta en/404.html '//meta[@name="description"]')" "en anglais aussi"
  [[ -z $(contenu_meta index.html '//meta[starts-with(@property,"og:image")]') ]] || { echo "une og:image est rendue" >&2; exit 1; }
  run env CHECK_PUBLIC_ROOT="$work/site/sortie" CHECK_BASE_URL=https://eleyone.fr/ bash "$root/scripts/checks/head-meta.sh"
  assert_eq 0 "$rc" "C26 passe sur la sortie d un vrai build (messages : $err)"
}

case_partial_description_absente_arrete_le_build() {
  run construire "Accueil." "" "Résumé."
  assert_eq 1 "$rc" "une page sans description arrête le build"
  assert_contains "content/about.fr.md (fr) n'a pas de description" "$(cat "$work/hugo.out")" "le message nomme la page"
}

case_partial_description_blanche_arrete_le_build() {
  run construire "Accueil." "   " "Résumé."
  assert_eq 1 "$rc" "une description blanche arrête le build"
  assert_contains "content/about.fr.md (fr) n'a pas de description" "$(cat "$work/hugo.out")" "le message nomme la page"
}

case_partial_accueil_sans_description_arrete_le_build() {
  run construire "" "À propos." "Résumé."
  assert_eq 1 "$rc" "un accueil sans description arrête le build"
  assert_contains "content/_index.fr.md (fr) n'a pas de description" "$(cat "$work/hugo.out")" "le message nomme l accueil"
}

case_partial_cas_sans_summary_arrete_le_build() {
  run construire "Accueil." "À propos." ""
  assert_eq 1 "$rc" "un cas sans summary arrête le build"
  assert_contains "content/cases/case-09-essai.fr.md (fr) n'a pas de description — « summary »" "$(cat "$work/hugo.out")" "le message nomme le cas et la clé"
}

case_partial_404_sans_description_arrete_le_build() {
  run construire "Accueil." "À propos." "Résumé."
  assert_eq 0 "$rc" "le build nominal réussit"
  # La clé est retirée des **deux** langues : Hugo comble une clé i18n absente par celle de la langue
  # par défaut (constaté : retirée du seul anglais, la 404 anglaise prenait le texte français et le
  # build passait). Une 404 anglaise décrite en français est un défaut de contenu que C3 ne voit
  # pas, mais ce n'est pas une balise vide : ce n'est pas la garde éprouvée ici.
  local langue lignes=""
  for langue in fr en; do
    shell_grep_into lignes -v '^not_found_description:' "$root/i18n/$langue.yaml"
    printf '%s\n' "$lignes" > "$work/site/i18n/$langue.yaml"
  done
  run bash -c 'cd "$1/site" && hugo --environment production --minify --destination sortie' _ "$work"
  assert_eq 1 "$rc" "une 404 sans description arrête le build"
  assert_contains "/404 (fr) n'a pas de description — « not_found_description d'i18n/ »" "$err$out" "le message nomme la 404 et sa source"
  assert_contains "/404 (en) n'a pas de description" "$err$out" "dans chaque langue"
}

case_partial_echappement_des_caracteres_speciaux() {
  # Guillemet, esperluette, apostrophe et chevron : la valeur relue par un parseur HTML est
  # exactement le texte écrit, et la balise reste un attribut valide (point 15 d'AGENTS.md).
  local texte='Un "guillemet", une esperluette & une apostrophe '"'"' et un < chevron.'
  run construire "Accueil." "$texte" "Résumé."
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_eq "$texte" "$(contenu_meta a-propos/index.html '//meta[@name="description"]')" "la description relue est le texte exact"
  assert_eq "$texte" "$(contenu_meta a-propos/index.html '//meta[@property="og:description"]')" "og:description aussi"
  assert_eq "1" "$(xmllint --html --xpath 'count(//head/meta[@property="og:type"])' "$work/site/sortie/a-propos/index.html" 2> /dev/null)" \
    "la valeur n a pas débordé de son attribut : les balises suivantes sont intactes"
}

case_partial_typographie_francaise_sur_la_description() {
  # Le français est composé comme le <title> (AD-23) ; l'anglais ne l'est jamais.
  run construire "Accueil : texte." "À propos." "Résumé."
  assert_eq 0 "$rc" "le build réussit"
  assert_eq "Accueil${nbsp}: texte." "$(contenu_meta index.html '//meta[@name="description"]')" "une insécable précède le deux-points en français"
  assert_eq "Home page : test." "$(contenu_meta en/index.html '//meta[@name="description"]')" "l anglais reste tel qu il est écrit"
}

case_partial_og_title_est_le_titre() {
  run construire "Accueil." "À propos." "Résumé."
  assert_eq 0 "$rc" "le build réussit"
  local titre
  titre=$(xmllint --html --xpath 'string(//title)' "$work/site/sortie/a-propos/index.html" 2> /dev/null)
  assert_eq "À propos${nbsp}· Prénom Nom · Pseudo" "$titre" "le titre de la page porte la ligne d identité"
  assert_eq "$titre" "$(contenu_meta a-propos/index.html '//meta[@property="og:title"]')" "og:title est le <title>"
}

run_case "$@"
