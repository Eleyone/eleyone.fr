#!/usr/bin/env bash
# Typographie française au build (story 6.3) : le partial _partials/typo-fr.html et le contrôle C24.
#
# Les cas du contrôle travaillent sur du HTML écrit à la main, comme ceux de test-html.sh. Les cas
# du partial lancent un vrai build de site fixture avec le Hugo épinglé : c'est le seul moyen de
# prouver qu'un attribut « href="mailto:…" » ou « title="Note :" » traverse la composition sans une
# égratignure, ce qui est la façon la plus probable de rater cette story.
#
# Hors ligne : aucun téléchargement, le binaire vient de .tools/ ou du PATH (CHECK_IMAGE).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-typo
. "$root/scripts/lib/tools.sh"

readonly fine=$' '
readonly insecable=$' '

# La page déclare son encodage, comme toute page du site : sans « meta charset », xmllint lit le
# fichier en Latin-1 et rend du mojibake, sur lequel les motifs UTF-8 ne collent plus — le contrôle
# passerait alors pour vert. La fixture doit ressembler à la sortie réelle, jusque-là.
page() { # $1 = chemin relatif, $2 = langue, $3 = corps
  mkdir -p "$(dirname "$work/public/$1")"
  printf '<!doctype html><html lang=%s><head><meta charset="utf-8"><title>T</title></head><body>%s</body></html>' \
    "$2" "$3" > "$work/public/$1"
}

sortie() {
  rm -rf "$work/public" "$work/rendu"
  mkdir -p "$work/public" "$work/rendu"
  page index.html fr '<p>Texte sans piege.</p>'
  page en/index.html en '<p>Plain text.</p>'
}

controle() {
  run env CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    bash "$root/scripts/checks/typo.sh"
}

# --- le contrôle C24 -------------------------------------------------------------------------

case_typo_site_conforme() {
  sortie
  controle
  assert_eq 0 "$rc" "un site conforme passe (messages : $err)"
  assert_contains "typographie française posée" "$out" "le contrôle le dit"
}

case_typo_espace_ordinaire_sur_une_page_fr() {
  sortie
  page index.html fr "<p>Le verdict : net.</p>"
  controle
  assert_eq 1 "$rc" "une espace ordinaire devant « : » sur une page FR fait échouer"
  assert_contains 'espace ordinaire devant « : » sur une page FR' "$err" "le signalement nomme le signe"
}

case_typo_chaque_signe_est_nomme() {
  # Les quatre signes et les deux guillemets sont vérifiés séparément : un contrôle qui n'en
  # regarderait qu'un passerait pour vert sur les autres.
  local signe
  for signe in ';' '!' '?' ':'; do
    sortie
    page index.html fr "<p>Mot ${signe} suite.</p>"
    controle
    assert_eq 1 "$rc" "une espace ordinaire devant « $signe » fait échouer"
    assert_contains "devant « $signe » sur une page FR" "$err" "le signalement nomme « $signe »"
  done
}

case_typo_guillemets_places_nommees() {
  # « devant eux » ne veut rien dire pour une paire : le message dit après « « » ou avant « » ».
  sortie
  page index.html fr "<p>Il dit « oui» tout net.</p>"
  controle
  assert_eq 1 "$rc" "une espace ordinaire après « « » fait échouer"
  assert_contains 'après « « » sur une page FR' "$err" "le signalement nomme la place"

  sortie
  page index.html fr "<p>Il dit «${fine}oui » tout net.</p>"
  controle
  assert_eq 1 "$rc" "une espace ordinaire avant « » » fait échouer"
  assert_contains 'avant « » » sur une page FR' "$err" "le signalement nomme la place"
}

case_typo_insecables_interdites_sur_une_page_en() {
  # Les deux espèces sont refusées : le critère initial n'en traquait qu'une, et une fine insécable
  # sur une page anglaise serait tout aussi fautive (constat de la revue de spec).
  sortie
  page en/index.html en "<p>The verdict${fine}: clear.</p>"
  controle
  assert_eq 1 "$rc" "une fine insécable sur une page EN fait échouer"
  assert_contains "espace fine insécable devant « : » sur une page en" "$err" "le signalement le dit"

  sortie
  page en/index.html en "<p>The verdict${insecable}: clear.</p>"
  controle
  assert_eq 1 "$rc" "une insécable sur une page EN fait échouer"
  assert_contains "espace insécable devant « : » sur une page en" "$err" "le signalement le dit"
}

case_typo_separateur_insecable_tolere_en_anglais() {
  # DESIGN.md prescrit une insécable devant le séparateur « · » sans distinction de langue : la
  # ligne d'identité en porte une sur les pages EN, et ce n'est pas un écart.
  sortie
  page en/index.html en "<p>Arnaud Grousset${insecable}· Eleyone</p>"
  controle
  assert_eq 0 "$rc" "une insécable devant « · » ne fait pas échouer une page EN (messages : $err)"
}

case_typo_blocs_de_code_ignores() {
  sortie
  page index.html fr '<pre>commande : valeur</pre><p>Texte.</p>'
  controle
  assert_eq 0 "$rc" "un « : » dans un pre ne fait pas échouer (messages : $err)"
  sortie
  page index.html fr '<p>Voir <code>cle : valeur</code> ici.</p>'
  controle
  assert_eq 0 "$rc" "un « : » dans un code ne fait pas échouer (messages : $err)"
}

case_typo_attribut_ignore() {
  # Un grep sur le HTML verrait l'attribut ; le XPath ne lit que les nœuds de texte.
  sortie
  page index.html fr '<p><a href="/x" title="Note : ici">Lien</a></p>'
  controle
  assert_eq 0 "$rc" "un « : » dans un attribut ne fait pas échouer (messages : $err)"
}

case_typo_cesure_automatique_refusee() {
  sortie
  printf 'body { hyphens: auto; }\n' > "$work/public/style.css"
  controle
  assert_eq 1 "$rc" "« hyphens: auto » fait échouer"
  assert_contains "césure automatique est interdite" "$err" "le signalement renvoie à UX-DR17"
}

case_typo_page_du_rendu_de_travail_controlee() {
  # Comme C10 et C11 : les cas sont en brouillon, donc absents de la production.
  sortie
  mkdir -p "$work/rendu"
  printf '<!doctype html><html lang=fr><head><meta charset="utf-8"><title>T</title></head><body><p>Verdict : net.</p></body></html>' \
    > "$work/rendu/brouillon.html"
  controle
  assert_eq 1 "$rc" "une page qui n'existe que dans le rendu de travail est contrôlée"
  assert_contains "brouillon.html" "$err" "le signalement la nomme"
}

case_typo_insecable_mal_choisie_sur_une_page_fr() {
  # U+00A0 devant un « ? » donne un texte qui paraît composé et ne l'est pas : DESIGN.md y veut la
  # fine U+202F. Le contrôle ne le voyait pas (revue du code de la PR n° 81).
  sortie
  page index.html fr "<p>Vous voyez${insecable}?</p>"
  controle
  assert_eq 1 "$rc" "une insécable U+00A0 devant « ? » fait échouer sur une page FR"
  assert_contains "insécable U+00A0 devant « ? » sur une page FR" "$err" "le signalement dit laquelle est attendue"

  # Et l'inverse devant « : », qui veut l'insécable et non la fine.
  sortie
  page index.html fr "<p>Le verdict${fine}: net.</p>"
  controle
  assert_eq 1 "$rc" "une fine U+202F devant « : » fait échouer sur une page FR"
  assert_contains "fine U+202F devant « : » sur une page FR" "$err" "le signalement dit laquelle est attendue"
}

case_typo_insecable_mal_choisie_dans_les_guillemets_fr() {
  sortie
  page index.html fr "<p>Il dit «${insecable}oui${fine}» net.</p>"
  controle
  assert_eq 1 "$rc" "une insécable U+00A0 après « « » fait échouer sur une page FR"
  assert_contains "insécable U+00A0 après « « » sur une page FR" "$err" "le signalement nomme la place"

  sortie
  page index.html fr "<p>Il dit «${fine}oui${insecable}» net.</p>"
  controle
  assert_eq 1 "$rc" "une insécable U+00A0 avant « » » fait échouer sur une page FR"
  assert_contains "insécable U+00A0 avant « » » sur une page FR" "$err" "le signalement nomme la place"
}

case_typo_insecable_dans_les_guillemets_dune_page_en() {
  # La branche anglaise ne vérifiait que la fine sur les guillemets (revue du code de la PR n° 81).
  sortie
  page en/index.html en "<p>He says «${insecable}yes» now.</p>"
  controle
  assert_eq 1 "$rc" "une insécable après « « » fait échouer sur une page EN"
  assert_contains "espace insécable après « « » sur une page en" "$err" "le signalement le dit"

  sortie
  page en/index.html en "<p>He says «yes${insecable}» now.</p>"
  controle
  assert_eq 1 "$rc" "une insécable avant « » » fait échouer sur une page EN"
  assert_contains "espace insécable avant « » » sur une page en" "$err" "le signalement le dit"
}

# --- le partial, sur un vrai build -------------------------------------------------------------

construire() {
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  printf -- '---\ntitle: "Accueil"\n---\n' > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\n---\n' > "$work/site/content/_index.en.md"
  # Le même texte dans les deux langues : seule la composition doit différer.
  local corps='Le verdict : net ; vraiment ! Vous voyez ? Il dit « oui » sans hésiter.

À corrige ? et deja : composé.

Un lien [écrire](mailto:contact@exemple.invalide) et un `code : brut`.

    bloc : indenté
'
  printf -- '---\ntitle: "Essai : la typographie"\n---\n\n%s' "$corps" > "$work/site/content/essai.fr.md"
  printf -- '---\ntitle: "Trial : typography"\n---\n\n%s' "$corps" > "$work/site/content/essai.en.md"
  (cd "$work/site" && hugo --environment work --buildDrafts --panicOnWarning --destination sortie) \
    > "$work/hugo.out" 2>&1
}

case_typo_partial_compose_les_pages_fr() {
  run construire
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local fr
  fr=$(cat "$work/site/sortie/essai/index.html")
  assert_contains "verdict${insecable}:" "$fr" "le « : » reçoit une insécable U+00A0"
  assert_contains "net${fine};" "$fr" "le « ; » reçoit une fine insécable U+202F"
  assert_contains "vraiment${fine}!" "$fr" "le « ! » reçoit une fine insécable"
  assert_contains "voyez${fine}?" "$fr" "le « ? » reçoit une fine insécable"
  assert_contains "«${fine}oui${fine}»" "$fr" "les guillemets reçoivent leurs fines des deux côtés"
  # L'auteur a tapé une insécable U+00A0 devant le « ? » : elle est corrigée en fine, comme une
  # espace ordinaire l'aurait été. La règle est donc idempotente sur un texte déjà composé.
  assert_contains "corrige${fine}?" "$fr" "une insécable mal choisie est corrigée en fine"
  assert_contains "deja${insecable}:" "$fr" "un texte déjà composé ressort identique"
}

case_typo_partial_epargne_code_et_attributs() {
  run construire
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local fr
  fr=$(cat "$work/site/sortie/essai/index.html")
  # L'attribut d'un lien mailto : le « : » y est sans espace devant, mais l'URL entière doit sortir
  # intacte — un caractère insécable dedans casserait le lien en silence.
  assert_contains 'href="mailto:contact@exemple.invalide"' "$fr" "l'URL du lien est intacte"
  assert_contains '<code>code : brut</code>' "$fr" "le contenu d'un code n'est pas composé"
  assert_contains 'bloc : indenté' "$fr" "le contenu d'un bloc préformaté n'est pas composé"
  [[ $fr != *"bloc${insecable}:"* ]] \
    || { echo "un bloc préformaté a été composé" >&2; exit 1; }
}

case_typo_partial_epargne_les_pages_en() {
  run construire
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local en
  en=$(cat "$work/site/sortie/en/essai/index.html")
  assert_contains "verdict : net ; vraiment ! Vous voyez ?" "$en" "la page anglaise garde ses espaces ordinaires"
  [[ $en != *"$fine"* ]] || { echo "une fine insécable est apparue sur une page anglaise" >&2; exit 1; }
}

case_typo_le_titre_de_la_page_est_compose() {
  # Le <title> vit hors du corps : le partial appliqué par les gabarits ne l'atteint pas, et il
  # s'affiche dans l'onglet comme dans un résultat de recherche. C24 l'a trouvé sur le cas 01.
  run construire
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local fr en
  fr=$(sed -n 's#.*<title>\(.*\)</title>.*#\1#p' "$work/site/sortie/essai/index.html")
  en=$(sed -n 's#.*<title>\(.*\)</title>.*#\1#p' "$work/site/sortie/en/essai/index.html")
  assert_contains "Essai${insecable}:" "$fr" "le titre français est composé"
  assert_contains "Trial : typography" "$en" "le titre anglais garde son espace ordinaire"
}

case_typo_tout_gabarit_principal_passe_par_le_partial() {
  # La règle ne tient que si aucun gabarit ne l'oublie. Un « define \"main\" » qui n'appellerait pas
  # typo-fr.html livrerait une page entière non composée, et C24 ne la verrait que si elle contient
  # par hasard un des signes. Ce cas refuse l'oubli à la source.
  local fichier oublis=()
  while IFS= read -r fichier; do
    shell_grep -qF 'partial "typo-fr.html"' "$fichier" || oublis+=("$fichier")
  done < <(shell_grep -rlF 'define "main"' "$root/layouts")
  ((${#oublis[@]} == 0)) || {
    printf 'gabarit(s) qui définissent « main » sans passer par typo-fr.html : %s\n' "${oublis[*]}" >&2
    exit 1
  }
}
run_case "$@"
