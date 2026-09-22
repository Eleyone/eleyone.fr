#!/usr/bin/env bash
# Gabarit de la page de groupe (story 6.1). Un site fixture construit avec le Hugo épinglé, puis sa
# sortie lue : ce sont les gabarits livrés qui sont exercés, sur un contenu à eux.
#
# Ces cas gardent des comportements que la revue de spec a signalés comme « déjà vrais mais non
# gardés » : le corps du _index d'un groupe n'est jamais rendu (question 9, tranchée le 13/09/2026),
# et le résumé du sommaire annonce les deux nombres, accordés (arbitrage d'Arnaud du 22/09/2026).
# Chacun a été lancé une fois sans son correctif, pour le voir échouer.
#
# Hors ligne : aucun téléchargement, le binaire vient de .tools/ ou du PATH (CHECK_IMAGE).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-case-page
. "$root/scripts/lib/tools.sh"

# $1, facultatif : un corps à écrire sous le front matter du _index du groupe français.
construire() {
  local corps=${1:-}
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$fixtures/site/content" "$work/site/content"
  [[ -z $corps ]] || printf '\n%s\n' "$corps" >> "$work/site/content/cases/groupe/_index.fr.md"
  (cd "$work/site" && hugo --environment work --buildDrafts --panicOnWarning --destination sortie) \
    > "$work/hugo.out" 2>&1
}

# La page de groupe française du site fixture.
page_groupe() { printf '%s' "$work/site/sortie/cas/groupe/index.html"; }

case_page_de_groupe_sans_introduction() {
  # Un _index qui porte un corps ne doit rien afficher de plus : la page est un titre et des
  # sections. Sans la règle, Hugo n'écrirait toujours rien — c'est le gabarit qui doit le garantir,
  # et ce cas échoue dès qu'on y ajoute « {{ .Content }} ».
  run construire "Cette introduction ne doit jamais paraitre sur la page."
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local html
  html=$(cat "$(page_groupe)")
  assert_contains "page-title" "$html" "la page porte bien son titre"
  [[ $html != *"ne doit jamais paraitre"* ]] \
    || { echo "le corps du _index du groupe est rendu sur la page (question 9)" >&2; exit 1; }
}

case_resume_du_sommaire_annonce_cas_et_rubriques() {
  run construire
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local fr en
  fr=$(sed -n 's/.*<summary[^>]*>\([^<]*\)<\/summary>.*/\1/p' "$(page_groupe)" | head -1)
  en=$(sed -n 's/.*<summary[^>]*>\([^<]*\)<\/summary>.*/\1/p' "$work/site/sortie/en/cases/groupe/index.html" | head -1)
  # La fixture porte **un** cas et **deux** rubriques : chaque nombre exerce donc un accord
  # différent, ce qu'un contenu à trois cas ne montrerait pas. Le singulier de « cas » est
  # invisible en français, où le mot est invariable ; il se voit en anglais, d'où la vérification
  # des deux langues — c'est précisément pour cette asymétrie que chaque langue porte ses formes.
  assert_eq "Sommaire · 1 cas, 2 rubriques" "$fr" "le résumé français annonce les deux nombres"
  assert_eq "Contents · 1 case, 2 sections" "$en" "le résumé anglais accorde « case » au singulier"
}

case_le_lien_de_retour_porte_lancre_du_poste() {
  run construire
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local retour
  retour=$(sed -n 's/.*class="nav-links"><a href="\([^"]*\)".*/\1/p' "$(page_groupe)" | head -1)
  assert_contains "#position-" "$retour" "le retour au parcours vise l'ancre du poste (AD-18)"
}
case_groupe_sans_aucun_cas() {
  # La revue du code de la PR n° 79 donnait « index $cases 0 » pour fatal sur un groupe vide
  # (« index out of range »). Essayé : le build passe, Hugo rend nil et le « with » saute. Le cas
  # reste, parce que le comportement d'un outil n'est vrai qu'une fois vérifié (point 10
  # d'AGENTS.md) : si une version future rendait bien une erreur, elle échouerait ici.
  rm -rf "$work/site"
  mkdir -p "$work/site"
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  mkdir -p "$work/site/content/cases/vide"
  printf -- '---\ntitle: "Accueil"\n---\n' > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\n---\n' > "$work/site/content/_index.en.md"
  printf -- '---\ntitle: "Cas"\n---\n' > "$work/site/content/cases/_index.fr.md"
  printf -- '---\ntitle: "Cases"\n---\n' > "$work/site/content/cases/_index.en.md"
  printf -- '---\ntitle: "Groupe vide"\ntranslationKey: group-vide\n---\n' > "$work/site/content/cases/vide/_index.fr.md"
  printf -- '---\ntitle: "Empty group"\ntranslationKey: group-vide\n---\n' > "$work/site/content/cases/vide/_index.en.md"
  run bash -c 'cd "$1" && hugo --environment work --buildDrafts --panicOnWarning --destination sortie' _ "$work/site"
  assert_eq 0 "$rc" "un groupe sans aucun cas se construit sans erreur (sortie : $out $err)"
  local html
  html=$(cat "$work/site/sortie/cas/vide/index.html")
  assert_contains "page-title" "$html" "la page du groupe vide est bien rendue"
  [[ $html != *"nav-links"* ]] \
    || { echo "un groupe sans cas ne peut pas porter de retour au parcours" >&2; exit 1; }
}

run_case "$@"
