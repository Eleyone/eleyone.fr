#!/usr/bin/env bash
# Page « À propos » (story 9.4, FR-16, FR-34, FR-38, DESIGN.md § À propos).
#
# Ce qui se joue ici est un **ordre** et une **condition** : titre, portrait, bloc CV s'il existe,
# puis le texte. Ni l'un ni l'autre ne se relit dans un gabarit ; les deux se constatent dans la
# sortie. Le cas qui compte le plus est celui où les CV manquent — l'encart doit disparaître
# **avec son étiquette**, parce qu'un « CV » au-dessus de rien annonce ce qui n'existe pas.
#
# Les PDF d'essai sont fabriqués par « tests_pdf » : aucun n'entre dans le dépôt.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-about-page
. "$root/scripts/lib/tools.sh"

# $1… : les CV à poser dans assets/cv/ ; aucun argument pour aucun.
construire() {
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content" "$work/site/assets/cv"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$root/assets/css" "$root/assets/images" "$work/site/assets/"
  printf -- '---\ntitle: "Accueil"\ntranslationKey: home\nidentity: "Essai · Pseudo"\njob_title: "Essai"\nportrait_alt: "Texte alternatif d essai"\n---\n' \
    > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\ntranslationKey: home\nidentity: "Essai · Pseudo"\njob_title: "Test"\nportrait_alt: "Test alternative text"\n---\n' \
    > "$work/site/content/_index.en.md"
  printf -- '---\ntitle: "À propos"\ntranslationKey: about\nslug: a-propos\nlayout: about\n---\n\n## Une section\n\nDu texte.\n' \
    > "$work/site/content/about.fr.md"
  printf -- '---\ntitle: "About"\ntranslationKey: about\nslug: about\nlayout: about\n---\n\n## A section\n\nSome text.\n' \
    > "$work/site/content/about.en.md"
  local nom
  for nom in "$@"; do tests_pdf "$work/site/assets/cv/$nom" "" "" "" 1000; done
  local code=0
  (cd "$work/site" && hugo --environment production --minify --destination sortie) \
    > "$work/hugo.out" 2>&1 || code=$?
  return "$code"
}

page() { cat "$work/site/sortie/$1"; }

# La position d'un repère dans la page, en octets. Sa **présence** est affirmée d'abord :
# « ${x%%motif*} » rend la chaîne inchangée quand le motif manque, donc « très loin », et un
# élément absent passerait pour un élément venant en dernier.
position() { # $1 = html, $2 = repère
  [[ $1 == *"$2"* ]] || { echo "repère « $2 » absent de la page" >&2; exit 1; }
  local avant=${1%%"$2"*}
  printf '%s' "${#avant}"
}

case_about_ordre_des_elements() {
  # L'ordre de DESIGN.md : titre, portrait, bloc CV, puis le texte.
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr; fr=$(page a-propos/index.html)
  local p_titre p_portrait p_bloc p_texte
  p_titre=$(position "$fr" 'class=page-title')
  p_portrait=$(position "$fr" 'portrait--about')
  p_bloc=$(position "$fr" 'class="note-block about-page__cv"')
  p_texte=$(position "$fr" '<h2')
  ((p_titre < p_portrait)) || { echo "le portrait précède le titre" >&2; exit 1; }
  ((p_portrait < p_bloc)) || { echo "le bloc CV précède le portrait" >&2; exit 1; }
  ((p_bloc < p_texte)) || { echo "le texte précède le bloc CV" >&2; exit 1; }
}

case_about_le_bloc_cv_porte_son_etiquette() {
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit"
  local fr; fr=$(page a-propos/index.html)
  assert_contains 'class=label' "$fr" "l étiquette est en composant label (DESIGN.md § note-block)"
  assert_contains '>CV</p>' "$fr" "et elle dit « CV »"
  assert_contains 'href=/cv/cv-fr.pdf' "$fr" "le CV français est lié"
  assert_contains 'href=/cv/cv-en.pdf' "$fr" "le CV anglais aussi"
}

case_about_sans_cv_le_bloc_disparait_avec_son_etiquette() {
  # Le cas qui compte : « ni ligne vide, ni étiquette seule, ni mention bientôt » (DESIGN.md).
  run construire
  assert_eq 0 "$rc" "le build réussit sans CV (sortie : $(cat "$work/hugo.out"))"
  local fr; fr=$(page a-propos/index.html)
  [[ $fr != *"note-block"* ]] || { echo "l encart subsiste sans CV" >&2; exit 1; }
  [[ $fr != *">CV</p>"* ]] || { echo "l étiquette « CV » subsiste seule" >&2; exit 1; }
  [[ $fr != *"/cv/"* ]] || { echo "un lien de CV subsiste" >&2; exit 1; }
  assert_contains 'portrait--about' "$fr" "le portrait, lui, reste"
}

case_about_un_seul_cv_ne_rend_rien() {
  # « Ensemble ou rien » (AD-21) : la garantie vient du partial, mais elle est éprouvée **ici**,
  # parce que le bloc est un nouvel emplacement (constat de la revue de spec).
  run construire cv-fr.pdf
  assert_eq 0 "$rc" "le build réussit avec un seul CV (sortie : $(cat "$work/hugo.out"))"
  local fr; fr=$(page a-propos/index.html)
  [[ $fr != *"note-block"* ]] || { echo "l encart est rendu avec un seul CV" >&2; exit 1; }
}

case_about_le_portrait_est_la_variante_about() {
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit"
  local fr; fr=$(page a-propos/index.html)
  assert_contains 'portrait--about' "$fr" "la classe désigne la variante"
  assert_contains 'width=160 height=200' "$fr" "aux dimensions intrinsèques d AD-19"
  assert_contains ' 2x' "$fr" "avec sa variante 2x"
  assert_contains 'alt="Texte alternatif d essai"' "$fr" "et le texte alternatif de la langue"
}

case_about_lien_dans_len_tete_et_aria_current() {
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit"
  assert_contains 'href=/a-propos/' "$(page index.html)" "l accueil FR mène à la page"
  assert_contains 'href=/en/about/' "$(page en/index.html)" "l accueil EN mène à la sienne"
  assert_contains 'href=/a-propos/ aria-current=page' "$(page a-propos/index.html)" "la page courante est signalée"
  [[ $(page index.html) != *'aria-current'* ]] \
    || { echo "l accueil porte aria-current alors qu il n est pas la page À propos" >&2; exit 1; }
}

case_about_lordre_de_len_tete() {
  # DESIGN.md : « À propos », « Contact », puis le sélecteur de langue — toujours dernier.
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit"
  local nav; nav=$(page index.html)
  nav=${nav#*<nav class=site-header__nav}
  [[ $nav != "$(page index.html)" ]] || { echo "aucune navigation dans l en-tête" >&2; exit 1; }
  nav=${nav%%</nav>*}
  local p_about p_langue
  p_about=$(position "$nav" '/a-propos/')
  p_langue=$(position "$nav" 'hreflang=en')
  ((p_about < p_langue)) || { echo "le sélecteur de langue n est pas le dernier élément" >&2; exit 1; }
}
run_case "$@"
