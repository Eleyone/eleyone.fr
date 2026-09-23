#!/usr/bin/env bash
# Le pied de page et ses **règles d'existence** (story 9.5, FR-29, AD-3, DESIGN.md § site-footer).
#
# Le pied de page ne porte que ce qui existe : les CV s'ils sont deux, les pages légales si elles
# sont là, le lien du dépôt si `params.source_url` est renseignée. Et il **disparaît entièrement**
# quand il n'a rien à dire.
#
# Ces règles sont conditionnelles : elles ne se relisent pas dans un gabarit, elles se constatent
# dans la sortie. Chacune était en service sans test au niveau du rendu — `test-links.sh` éprouve
# C12 sur du HTML fabriqué, ce qui ne dit rien de ce que Hugo produit ; et la disparition du pied
# de page, posée par la story 5.1, n'était éprouvée nulle part.
#
# Les autres fichiers de test touchent au pied de page pour ce qu'il **contient** — le libellé et
# le poids d'un CV (`test-cv-links.sh`), les liens des pages simples (`test-legal-page.sh`). Celui-ci
# ne juge que sa présence et celle de ses entrées.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-site-footer
. "$root/scripts/lib/tools.sh"

readonly depot='https://exemple.invalide/depot'

# $1 = valeur de source_url, vide pour aucune
# $2… = ce qui existe en plus : « cv », « legal », « privacy »
construire() {
  local source=$1; shift
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  # Les feuilles de style sont copiées, les CV non : « assets/cv/ » est peuplé par les cas qui en
  # veulent, pour que le défaut soit « pas de CV ».
  mkdir -p "$work/site/assets"
  cp -r "$root/assets/css" "$work/site/assets/"
  printf -- '---\ntitle: "Accueil"\nidentity: "Essai · Pseudo"\njob_title: "Essai"\n---\n' > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\nidentity: "Essai · Pseudo"\njob_title: "Test"\n---\n' > "$work/site/content/_index.en.md"
  # La valeur de « source_url » est réécrite dans la copie de la configuration : le cas décide,
  # jamais le dépôt.
  local config=$work/site/config/_default/hugo.yaml
  if [[ -n $source ]]; then
    sed -i "s#^\([[:space:]]*\)source_url:.*#\1source_url: $source#" "$config"
  else
    sed -i "s#^\([[:space:]]*\)source_url:.*#\1source_url:#" "$config"
  fi
  local quoi
  for quoi in "$@"; do
    case $quoi in
      cv)
        mkdir -p "$work/site/assets/cv"
        local nom
        for nom in cv-fr.pdf cv-en.pdf; do tests_pdf "$work/site/assets/cv/$nom" "" "" "" 1000; done ;;
      legal)
        printf -- '---\ntitle: "Mentions"\ntranslationKey: legal-notice\nslug: mentions-legales\n---\n\nTexte.\n' \
          > "$work/site/content/legal-notice.fr.md"
        printf -- '---\ntitle: "Legal"\ntranslationKey: legal-notice\nslug: legal-notice\n---\n\nText.\n' \
          > "$work/site/content/legal-notice.en.md" ;;
      privacy)
        printf -- '---\ntitle: "Confidentialité"\ntranslationKey: privacy\nslug: confidentialite\n---\n\nTexte.\n' \
          > "$work/site/content/privacy.fr.md"
        printf -- '---\ntitle: "Privacy"\ntranslationKey: privacy\nslug: privacy\n---\n\nText.\n' \
          > "$work/site/content/privacy.en.md" ;;
    esac
  done
  (cd "$work/site" && hugo --environment production --minify --destination sortie) \
    > "$work/hugo.out" 2>&1
}

page() { cat "$work/site/sortie/$1"; }

# Le pied de page seul. La **présence** du repère est affirmée avant de l'employer : « ${x#*motif} »
# rend la chaîne inchangée quand le motif manque, et la fonction aurait rendu la page entière
# (constat de la revue de la PR n° 100, sur deux autres fichiers de test).
pied_de() { # $1 = page
  local html repere='<footer class=site-footer>'
  html=$(page "$1") || { echo "$1 : page illisible" >&2; return 1; }
  [[ $html == *"$repere"* ]] || { echo "$1 : aucun pied de page" >&2; return 1; }
  html=${html#*"$repere"}
  [[ $html == *'</footer>'* ]] || { echo "$1 : pied de page non fermé" >&2; return 1; }
  printf '%s' "${html%%</footer>*}"
}

case_footer_source_renseignee_le_lien_est_la() {
  run construire "$depot"
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_contains "href=$depot" "$(page index.html)" "la page FR mène au dépôt"
  assert_contains "href=$depot" "$(page en/index.html)" "la page EN aussi"
  assert_contains 'Code source du site' "$(page index.html)" "avec le libellé français"
  assert_contains 'Site source code' "$(page en/index.html)" "et le libellé anglais"
}

case_footer_source_vide_aucun_lien_ni_factice() {
  # Le premier critère d'acceptation de la story, jamais vérifié au niveau du rendu : « ni lien
  # factice, ni # ». Un gabarit qui rendrait « href="" » ou « href="#" » satisferait un contrôle
  # qui ne cherche que l'absence de l'URL.
  run construire "" legal
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  # L'assertion porte sur le **pied de page**, pas sur la page : le lien d'évitement « #content »
  # est un « href=# » parfaitement légitime, et le chercher partout donnait un faux positif.
  local pied; pied=$(pied_de index.html)
  assert_contains 'site-footer__list' "$pied" "le pied de page existe, porté par la page légale"
  [[ $pied != *"Code source du site"* ]] || { echo "le libellé du dépôt apparaît sans URL" >&2; exit 1; }
  [[ $pied != *'href=#'* && $pied != *'href="#"'* ]] || { echo "un lien « # » a été rendu" >&2; exit 1; }
  [[ $pied != *'href=>'* && $pied != *'href=""'* ]] || { echo "un lien vide a été rendu" >&2; exit 1; }
}

case_footer_disparait_quand_il_na_rien_a_dire() {
  # La règle de la story 5.1, restée sans test : « un filet surmontant du vide n'apprend rien, et
  # le HTML porterait un repère de navigation sans contenu ». Aucun CV, aucune page simple, aucune
  # source_url : il ne doit rien rester, pas même la balise.
  run construire ""
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr en
  fr=$(page index.html); en=$(page en/index.html)
  [[ $fr != *'<footer'* ]] || { echo "la page FR porte un pied de page vide" >&2; exit 1; }
  [[ $en != *'<footer'* ]] || { echo "la page EN porte un pied de page vide" >&2; exit 1; }
}

case_footer_une_seule_entree_suffit_a_le_faire_exister() {
  # La contre-épreuve de la précédente : sans elle, un pied de page qui ne s'afficherait **jamais**
  # passerait pour un pied de page qui disparaît à bon escient.
  run construire "$depot"
  assert_eq 0 "$rc" "le build réussit"
  assert_contains '<footer' "$(page index.html)" "le seul lien du dépôt fait exister le pied de page"
}

case_footer_les_quatre_entrees_dans_lordre() {
  # L'ordre de DESIGN.md : les CV, puis les mentions légales, puis la confidentialité, puis le
  # dépôt. Vérifié d'un bout à l'autre, une seule fois, plutôt que par paires.
  run construire "$depot" cv legal privacy
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local pied repere='<ul class=site-footer__list>'
  pied=$(page index.html)
  [[ $pied == *"$repere"* ]] || { echo "aucune liste dans le pied de page" >&2; exit 1; }
  pied=${pied#*"$repere"}
  [[ $pied == *'</ul>'* ]] || { echo "liste du pied de page non fermée" >&2; exit 1; }
  pied=${pied%%</ul>*}
  local attendu=(cv-fr.pdf cv-en.pdf mentions-legales confidentialite "$depot") precedent=-1 entree position
  for entree in "${attendu[@]}"; do
    [[ $pied == *"$entree"* ]] || { echo "« $entree » absent du pied de page" >&2; exit 1; }
    position=${pied%%"$entree"*}
    ((${#position} > precedent)) || { echo "« $entree » n est pas à sa place dans l ordre" >&2; exit 1; }
    precedent=${#position}
  done
}
run_case "$@"
