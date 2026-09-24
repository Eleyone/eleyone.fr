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
# $2, facultatif : « seul » pour ajouter un cas sans groupe, hors de tout dossier de groupe.
construire() {
  local corps=${1:-} seul=${2:-}
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
  if [[ $seul == seul ]]; then
    local langue
    for langue in fr en; do
      sed -e '/^group: /d' -e "s/^slug: .*/slug: \"cas-seul\"/" -e 's/^translationKey: .*/translationKey: case-08/' \
        -e 's/^number: .*/number: "08"/' \
        "$fixtures/site/content/cases/groupe/case-09-fixture.$langue.md" \
        > "$work/site/content/cases/case-08-seul.$langue.md"
    done
  fi
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
  printf -- '---\ntitle: "Accueil"\nidentity: "Essai · Pseudo"\njob_title: "Essai"\n---\n' > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\nidentity: "Essai · Pseudo"\njob_title: "Test"\n---\n' > "$work/site/content/_index.en.md"
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

# La page française du cas sans groupe.
page_seule() { printf '%s' "$work/site/sortie/cas/cas-seul/index.html"; }

case_cas_sans_groupe_a_sa_page() {
  run construire "" seul
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  [[ -f $(page_seule) ]] || { echo "aucune page rendue pour un cas sans groupe" >&2; exit 1; }
  [[ -f $work/site/sortie/en/cases/cas-seul/index.html ]] \
    || { echo "la page anglaise du cas sans groupe manque (FR-20)" >&2; exit 1; }
  # Les deux langues sont vérifiées, pas seulement la française : un libellé i18n ou un rôle qui
  # manquerait du seul côté anglais passerait sinon inaperçu, alors que FR-20 exige la parité
  # (constat retenu de la revue du code de la PR n° 80).
  local page html
  for page in "$(page_seule)" "$work/site/sortie/en/cases/cas-seul/index.html"; do
    html=$(cat "$page")
    # Le cas est le sujet de la page : son titre est le titre de la page, et « page.html » est bien
    # le gabarit trouvé — sans clé « layout » dans le front matter du cas.
    assert_contains 'class="page-title"' "$html" "le titre du cas porte le rôle de titre de page ($page)"
    [[ $html != *'class="case-title"'* ]] \
      || { echo "le titre porte le rôle d une section de groupe sur $page" >&2; exit 1; }
    assert_contains 'class="nav-links"' "$html" "la page porte le retour au parcours ($page)"
    assert_contains '#position-' "$html" "le retour vise l ancre du poste ($page)"
  done
}

case_cas_seul_porte_lancre_de_son_cas() {
  # Le sommaire de la page d'un cas seul émet un lien vers l'ancre du cas — « #case-08 » ici. Sur une
  # page de groupe, c'est la « section » enveloppante qui la porte ; sur la page d'un cas seul, elle
  # manquait, et le lien du sommaire ne menait nulle part. C12 le refuse, mais **seulement une fois un
  # cas non groupé publié** : le cas 05 a été le premier, à la story 10.7 (24/09/2026), et le défaut
  # venait de la story 6.2.
  #
  # Les deux langues sont vérifiées : le gabarit est le même, mais rien ne le garantit à l'avenir.
  run construire "" seul
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local page html
  for page in "$(page_seule)" "$work/site/sortie/en/cases/cas-seul/index.html"; do
    html=$(cat "$page")
    assert_contains 'id="case-08"' "$html" "la page du cas seul porte l ancre de son cas ($page)"
    # La contre-épreuve : le sommaire y renvoie bien, sinon l'ancre serait posée pour personne.
    assert_contains 'href="#case-08"' "$html" "et le sommaire y renvoie ($page)"
  done
}

case_cas_sans_groupe_garde_ses_niveaux_de_titre() {
  # Le hook ne descend d un niveau que les cas groupés (AD-4, FR-8) : ici les « ## » restent des h2,
  # numérotés « 08.r ». Le même cas, dans un groupe, sort en h3 — c est ce que garde ce cas.
  run construire "" seul
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local seule groupe
  seule=$(cat "$(page_seule)")
  groupe=$(cat "$(page_groupe)")
  assert_contains '<h2 id="case-08-contexte" class="rubric-heading">' "$seule" "une rubrique de cas seul est un h2"
  assert_contains '<h3 id="case-09-contexte" class="rubric-heading">' "$groupe" "la même rubrique groupée est un h3"
  assert_contains '>08.1<' "$seule" "la rubrique porte le numéro du cas"
}

case_resume_du_sommaire_dun_cas_seul() {
  # Une page de cas seul n annonce que ses rubriques : le nombre de cas n aurait pas de sens.
  run construire "" seul
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local resume
  resume=$(sed -n 's/.*<summary[^>]*>\([^<]*\)<\/summary>.*/\1/p' "$(page_seule)" | head -1)
  assert_eq "Sommaire · 2 rubriques" "$resume" "le résumé ne compte que les rubriques"
}

run_case "$@"
