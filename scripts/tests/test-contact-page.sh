#!/usr/bin/env bash
# Page Contact, lien de l'en-tête et appel à contact sur l'accueil (story 9.3, FR-3, FR-17, AD-3).
#
# Les cas montent un petit site et le construisent avec le Hugo épinglé : ce qui compte ici — un
# lien absent quand la page n'existe pas, « aria-current » sur la bonne page, une clé de front
# matter manquante qui n'affiche rien — ne se relit pas dans un gabarit, se constate dans la sortie.
#
# **Les valeurs d'essai sont fabriquées ici** et ne ressemblent à aucune vraie : un test ne recopie
# pas les coordonnées du site.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-contact-page
. "$root/scripts/lib/tools.sh"

readonly courriel='essai@exemple.invalide'
readonly linkedin='https://exemple.invalide/in/essai/'
readonly github='https://exemple.invalide/essai'

# $1… : les clés de front matter à poser (« email », « linkedin », « github ») ; aucune pour une
# page Contact absente du site.
construire() {
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$root/assets" "$work/site/"
  printf -- '---\ntitle: "Accueil"\nidentity: "Essai"\n---\n' > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\nidentity: "Essai"\n---\n' > "$work/site/content/_index.en.md"
  local cles=("$@")
  if (( ${#cles[@]} )); then
    local avant="" nom
    for nom in "${cles[@]}"; do
      case $nom in
        email) avant+="email: $courriel"$'\n' ;;
        linkedin) avant+="linkedin: $linkedin"$'\n' ;;
        github) avant+="github: $github"$'\n' ;;
      esac
    done
    printf -- '---\ntitle: "Contact"\ntranslationKey: contact\nslug: contact\n%s---\n\nTexte.\n\n{{< contact-list >}}\n' \
      "$avant" > "$work/site/content/contact.fr.md"
    printf -- '---\ntitle: "Contact"\ntranslationKey: contact\nslug: contact\n%s---\n\nText.\n\n{{< contact-list >}}\n' \
      "$avant" > "$work/site/content/contact.en.md"
  fi
  (cd "$work/site" && hugo --environment production --minify --destination sortie) \
    > "$work/hugo.out" 2>&1
}

page() { cat "$work/site/sortie/$1"; }
# L'en-tête seul. La **présence** du repère est affirmée avant de l'employer : « ${x#*motif} »
# rend la chaîne **inchangée** quand le motif manque, si bien qu'un en-tête disparu aurait renvoyé
# la page entière, et le cas du lien l'aurait trouvé dans l'appel à contact de l'accueil — un faux
# positif de vérification (constat bloquant de la revue de la PR n° 100).
#
# C'est la faute que « ordre_du_pied » de test-legal-page.sh venait de fermer, reproduite dans le
# fichier écrit juste après : une parade corrigée à un endroit ne se reporte pas d'elle-même
# (points 18 et 19 d'AGENTS.md).
entete() { # $1 = page ; l'en-tête seul
  local html repere='<header class=site-header>'
  html=$(page "$1") || { echo "$1 : page illisible" >&2; return 1; }
  [[ $html == *"$repere"* ]] || { echo "$1 : aucun en-tête" >&2; return 1; }
  html=${html#*"$repere"}
  [[ $html == *"</header>"* ]] || { echo "$1 : en-tête non fermé" >&2; return 1; }
  printf '%s' "${html%%</header>*}"
}

case_contact_les_trois_entrees_sont_des_liens() {
  run construire email linkedin github
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr
  fr=$(page contact/index.html)
  assert_contains "href=mailto:$courriel" "$fr" "le courriel est un lien mailto:"
  assert_contains "href=$linkedin" "$fr" "LinkedIn est un lien"
  assert_contains "href=$github" "$fr" "GitHub aussi"
  assert_contains 'class="legal-list contact-list"' "$fr" "la liste réutilise le composant de DESIGN.md"
}

case_contact_les_termes_viennent_de_i18n() {
  run construire email linkedin github
  assert_eq 0 "$rc" "le build réussit"
  assert_contains 'Courriel' "$(page contact/index.html)" "le terme français vient de i18n"
  assert_contains 'Email' "$(page en/contact/index.html)" "et le terme anglais aussi"
}

case_contact_une_cle_absente_naffiche_rien() {
  # « Ce qui n'existe pas reste vide » : ni terme, ni ligne vide, ni « à venir ».
  run construire email
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr
  fr=$(page contact/index.html)
  assert_contains "href=mailto:$courriel" "$fr" "le courriel reste"
  [[ $fr != *LinkedIn* ]] || { echo "le terme LinkedIn subsiste sans sa valeur" >&2; exit 1; }
  [[ $fr != *GitHub* ]] || { echo "le terme GitHub subsiste sans sa valeur" >&2; exit 1; }
}

case_contact_aucune_cle_arrete_le_build() {
  # Une page Contact sans aucun moyen de contact est une page qui ment : le build s'arrête plutôt
  # que de la publier.
  construire email
  # La page est réécrite sans aucune des trois clés.
  printf -- '---\ntitle: "Contact"\ntranslationKey: contact\nslug: contact\n---\n\nTexte.\n\n{{< contact-list >}}\n' \
    > "$work/site/content/contact.fr.md"
  run bash -c 'cd "$1" && hugo --environment production --minify --destination sortie' _ "$work/site"
  assert_eq 1 "$rc" "une page Contact sans aucune clé arrête le build"
  assert_contains "ne porte aucune des clés" "$err" "et le message dit laquelle manque"
}

case_contact_lien_dans_len_tete() {
  run construire email linkedin github
  assert_eq 0 "$rc" "le build réussit"
  assert_contains 'href=/contact/' "$(entete index.html)" "l en-tête FR porte le lien"
  assert_contains 'href=/en/contact/' "$(entete en/contact/index.html)" "l en-tête EN porte le sien"
}

case_contact_aria_current_sur_la_seule_page_contact() {
  # Sans « aria-current », une personne au lecteur d'écran ne sait pas où elle se trouve. Avec lui
  # sur toutes les pages, elle est trompée : le cas vérifie les deux.
  run construire email linkedin github
  assert_eq 0 "$rc" "le build réussit"
  assert_contains 'aria-current=page' "$(entete contact/index.html)" "la page Contact FR le porte"
  assert_contains 'aria-current=page' "$(entete en/contact/index.html)" "la page Contact EN aussi"
  local accueil; accueil=$(entete index.html)
  [[ $accueil != *aria-current* ]] || { echo "l accueil porte aria-current alors qu il n est pas la page Contact" >&2; exit 1; }
}

case_contact_appel_sur_laccueil() {
  # Dernier bloc avant le pied de page, « titre de bloc, puis un lien » (DESIGN.md).
  run construire email linkedin github
  assert_eq 0 "$rc" "le build réussit"
  assert_contains 'id=block-contact>Contact</h2><p class=contact-cta><a href=/contact/>Me contacter</a>' \
    "$(page index.html)" "l accueil FR mène à la page FR, avec son libellé propre"
  assert_contains 'id=block-contact>Contact</h2><p class=contact-cta><a href=/en/contact/>Get in touch</a>' \
    "$(page en/index.html)" "l accueil EN mène à la page EN"
}

case_contact_sans_page_aucun_lien_nulle_part() {
  # La règle qui protège C12 : un lien vers une page absente ferait échouer le contrôle. L'en-tête
  # et l'accueil doivent donc se taire tant que la page n'existe pas — ce qui était l'état du site
  # avant cette story.
  run construire
  assert_eq 0 "$rc" "le build réussit sans page Contact (sortie : $(cat "$work/hugo.out"))"
  local accueil entete_fr
  accueil=$(page index.html)
  entete_fr=$(entete index.html)
  [[ $entete_fr != *"/contact/"* ]] || { echo "l en-tête mène à une page Contact absente" >&2; exit 1; }
  [[ $accueil != *block-contact* ]] || { echo "l accueil porte un appel à contact sans page" >&2; exit 1; }
}

case_contact_aucun_formulaire() {
  # FR-17 et C10 : jamais de formulaire. Le cas le dit aussi, pour que la page ne puisse pas en
  # gagner un sans qu'on le voie.
  run construire email linkedin github
  assert_eq 0 "$rc" "le build réussit"
  local fr; fr=$(page contact/index.html)
  [[ $fr != *"<form"* ]] || { echo "la page Contact porte un formulaire" >&2; exit 1; }
  [[ $fr != *"<input"* ]] || { echo "la page Contact porte un champ de saisie" >&2; exit 1; }
}
run_case "$@"
