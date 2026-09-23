#!/usr/bin/env bash
# Mentions légales : le partial lecteur, le shortcode et la page rendue (story 9.1, AD-9, FR-18).
#
# Les cas montent un petit site dans $work et le construisent avec le Hugo épinglé, comme
# test-cv-links.sh : les trois refus du partial **arrêtent le build**, et rien d'autre qu'un vrai
# build ne peut le montrer. Chacun a été lancé une fois sans sa garde, pour le voir passer.
#
# **Les valeurs d'essai sont fabriquées ici.** Elles portent toutes « ESSAI », n'ont rien de réel,
# et aucune valeur du poste n'entre dans un cas : l'environnement est posé explicitement, jamais
# hérité. Un cas qui hériterait de « .env » lirait de vraies coordonnées et les écrirait dans un
# rendu de test.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-legal-page
. "$root/scripts/lib/tools.sh"

# Les huit variables d'AD-9, lues dans le chargeur : un test qui recopierait la liste deviendrait
# faux le jour où elle change, et le deviendrait en silence.
valeurs_essai() {
  local nom
  while IFS= read -r nom; do
    printf '%s=ESSAI-%s\n' "$nom" "${nom#HUGO_LEGAL_}"
  done < <(grep -oE '^  HUGO_LEGAL_[A-Z_]+$' "$root/scripts/env.sh" | tr -d ' ')
}

# $1 = contenu supplémentaire à poser dans une page qui n'est PAS les mentions légales
# $2 = contenu du corps de la page de mentions légales ; vide pour le contenu nominal
construire() {
  local hors_page=${1:-} corps=${2:-}
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$root/assets" "$work/site/"
  printf -- '---\ntitle: "Accueil"\nidentity: "Essai · Pseudo"\njob_title: "Essai"\n---\n%s\n' "$hors_page" > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\nidentity: "Essai · Pseudo"\njob_title: "Test"\n---\n' > "$work/site/content/_index.en.md"
  [[ -n $corps ]] || corps=$'## Éditeur\n\n{{< legal-list "publisher" >}}\n\n## Hébergeur\n\n{{< legal-list "host" >}}\n'
  printf -- '---\ntitle: "Mentions légales"\ntranslationKey: legal-notice\nslug: mentions-legales\n---\n\n%s\n' \
    "$corps" > "$work/site/content/legal-notice.fr.md"
  printf -- '---\ntitle: "Legal notice"\ntranslationKey: legal-notice\nslug: legal-notice\n---\n\n%s\n' \
    "$corps" > "$work/site/content/legal-notice.en.md"
  # La page de confidentialité (story 9.2) : le pied de page doit porter son lien au bon slug dans
  # chaque langue, comme celui des mentions légales. Elle ne lit aucune valeur légale.
  printf -- '---\ntitle: "Confidentialité"\ntranslationKey: privacy\nslug: confidentialite\n---\n\nTexte.\n' \
    > "$work/site/content/privacy.fr.md"
  printf -- '---\ntitle: "Privacy"\ntranslationKey: privacy\nslug: privacy\n---\n\nText.\n' \
    > "$work/site/content/privacy.en.md"
  # « env -i » n'est pas employé : hugo a besoin de PATH et de HOME. Les valeurs légales sont
  # posées une à une, et aucune ne vient du poste.
  local -a env_args=()
  while IFS= read -r ligne; do env_args+=("$ligne"); done < <(valeurs_essai)
  (cd "$work/site" && env "${env_args[@]}" hugo --environment production --minify --destination sortie) \
    > "$work/hugo.out" 2>&1
}

# Comme construire, mais une seule variable est vidée.
construire_sans() { # $1 = nom complet de la variable à vider
  construire
  local -a env_args=()
  while IFS= read -r ligne; do env_args+=("$ligne"); done < <(valeurs_essai)
  env_args+=("$1=")
  (cd "$work/site" && env "${env_args[@]}" hugo --environment production --minify --destination sortie) \
    > "$work/hugo.out" 2>&1
}

page() { cat "$work/site/sortie/$1"; }

# Vérifie que deux entrées sont présentes dans le pied de page d'une page, **dans cet ordre**.
#
# Trois précautions, chacune pour une faute que la revue de la PR n° 99 a trouvée dans une première
# écriture :
#
#   - le pied de page est extrait par « shell_grep_into » et son absence est dite : un « grep » nu
#     dans une affectation fait sortir le script **sans un mot** sous « set -e », et le cas échouait
#     alors pour une raison qu'il n'affichait pas ;
#   - la **présence** de chaque entrée est affirmée avant de comparer leurs positions : sans cela,
#     une entrée absente donnait un préfixe égal à toute la chaîne, donc « très loin », et l'ordre
#     paraissait bon. Le cas passait au vert sur un pied de page amputé ;
#   - les deux langues sont vérifiées, et non la seule française.
ordre_du_pied() { # $1 = page, $2 = entrée attendue en premier, $3 = entrée attendue ensuite
  local page_lue=$1 premier=$2 second=$3 pied
  pied=$(page "$page_lue") || { echo "$page_lue : page illisible" >&2; exit 1; }
  pied=${pied#*<ul class=site-footer__list>}
  [[ $pied != "$(page "$page_lue")" ]] || { echo "$page_lue : aucun pied de page" >&2; exit 1; }
  pied=${pied%%</ul>*}
  [[ $pied == *"$premier"* ]] || { echo "$page_lue : « $premier » absent du pied de page" >&2; exit 1; }
  [[ $pied == *"$second"* ]] || { echo "$page_lue : « $second » absent du pied de page" >&2; exit 1; }
  local avant_premier=${pied%%"$premier"*} avant_second=${pied%%"$second"*}
  ((${#avant_premier} < ${#avant_second})) \
    || { echo "$page_lue : « $second » précède « $premier » dans le pied de page" >&2; exit 1; }
}

case_legal_page_rendue() {
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr
  fr=$(page mentions-legales/index.html)
  assert_contains 'class=legal-list' "$fr" "la liste porte sa classe"
  assert_contains 'ESSAI-PUBLISHER_NAME' "$fr" "le nom de l éditeur est rendu"
  assert_contains 'ESSAI-PUBLISHER_ADDRESS' "$fr" "l adresse aussi"
  assert_contains '<address>' "$fr" "l adresse est dans un élément address"
  assert_contains 'id=content' "$fr" "la cible du lien d évitement existe"
}

case_legal_page_les_deux_langues() {
  run construire
  assert_eq 0 "$rc" "le build réussit"
  [[ -f $work/site/sortie/mentions-legales/index.html ]] || { echo "page FR absente" >&2; exit 1; }
  [[ -f $work/site/sortie/en/legal-notice/index.html ]] || { echo "page EN absente" >&2; exit 1; }
  # L'assertion porte sur un **terme** de la liste, pas sur un titre de section : la fixture écrit
  # le même titre dans les deux langues, et assertionner dessus aurait mesuré la fixture au lieu du
  # produit. « Immatriculation » / « Registration number » ne se ressemblent dans aucune langue.
  assert_contains 'Registration number' "$(page en/legal-notice/index.html)" "les termes anglais viennent de i18n"
  assert_contains 'Immatriculation' "$(page mentions-legales/index.html)" "et les français sur la page FR"
}

case_legal_lien_du_pied_de_page() {
  # Le lien porte le slug de **sa** langue : un chemin écrit à la main en aurait mis un seul.
  run construire
  assert_eq 0 "$rc" "le build réussit"
  assert_contains 'href=/mentions-legales/>Mentions légales' "$(page index.html)" "l accueil FR mène aux mentions FR"
  assert_contains 'href=/en/legal-notice/>Legal notice' "$(page en/index.html)" "l accueil EN mène aux mentions EN"
}

case_legal_lien_de_confidentialite_dans_le_pied_de_page() {
  # Chaque page simple de l'epic 9 ajoute une entrée au pied de page, et chacune porte le slug de
  # **sa** langue : « /confidentialite/ » et « /en/privacy/ ». Un chemin écrit à la main n'en aurait
  # mis qu'un. Le mécanisme est celui de la story 9.1, « site.GetPage » (story 9.2).
  run construire
  assert_eq 0 "$rc" "le build réussit (messages : $err)"
  assert_contains 'href=/confidentialite/>Confidentialité' "$(page index.html)" "l accueil FR mène à la page FR"
  assert_contains 'href=/en/privacy/>Privacy' "$(page en/index.html)" "l accueil EN mène à la page EN"
  # Et les deux entrées coexistent, **dans les deux langues**, dans l'ordre prévu par DESIGN.md :
  # « Mentions légales » avant « Confidentialité ».
  ordre_du_pied index.html mentions-legales confidentialite
  ordre_du_pied en/index.html en/legal-notice en/privacy
}

case_legal_valeur_absente_arrete_le_build() {
  # AD-9 : « le partial fait échouer tout build si une valeur est vide ». Une page légale à demi
  # remplie est pire qu'un build en échec : elle se publie.
  run construire_sans HUGO_LEGAL_HOST_ADDRESS
  assert_eq 1 "$rc" "une valeur vide arrête le build"
  assert_contains "HUGO_LEGAL_HOST_ADDRESS est vide" "$(cat "$work/hugo.out")" "et le message nomme la variable"
}

case_legal_lecture_hors_page_legale_arrete_le_build() {
  # Le cœur d'AD-9 : l'adresse porte une commune, et elle n'appartient qu'à ces deux pages.
  run construire '{{< legal "publisher_address" >}}'
  assert_eq 1 "$rc" "lire une valeur légale depuis l accueil arrête le build"
  assert_contains "n'appartiennent qu'aux pages de mentions légales" "$(cat "$work/hugo.out")" \
    "et le message dit pourquoi"
}

case_legal_nom_de_valeur_inconnu_arrete_le_build() {
  # Une faute de frappe rendrait une page vide plutôt qu'une erreur.
  run construire "" '{{< legal "publisher_adress" >}}'
  assert_eq 1 "$rc" "un nom inconnu arrête le build"
  assert_contains "n'est pas une valeur légale" "$(cat "$work/hugo.out")" "et le message le dit"
}

case_legal_groupe_inconnu_arrete_le_build() {
  run construire "" '{{< legal-list "editeur" >}}'
  assert_eq 1 "$rc" "un groupe inconnu arrête le build"
  assert_contains "groupe « editeur » inconnu" "$(cat "$work/hugo.out")" "et le message nomme les trois"
}

case_legal_aucune_valeur_dans_le_titre_ni_la_description() {
  # La moitié que le partial ne peut pas tenir, et que C23 constate sur la sortie. Ce cas vérifie
  # que le rendu nominal ne l'enfreint pas déjà.
  run construire
  assert_eq 0 "$rc" "le build réussit"
  local tete
  tete=$(page mentions-legales/index.html | sed -n 's/.*<head>\(.*\)<\/head>.*/\1/p')
  [[ $tete != *"ESSAI-PUBLISHER_ADDRESS"* ]] || { echo "l adresse apparaît dans le <head>" >&2; exit 1; }
  [[ $tete != *"ESSAI-PUBLISHER_PHONE"* ]] || { echo "le téléphone apparaît dans le <head>" >&2; exit 1; }
}

case_legal_courriel_et_telephone_sont_des_liens() {
  # Le lien se décide d'après ce que la valeur **est**. Ici les valeurs d'essai ne ressemblent ni à
  # une adresse ni à un numéro : elles doivent rester en clair, sans lien mort.
  run construire
  assert_eq 0 "$rc" "le build réussit"
  local fr
  fr=$(page mentions-legales/index.html)
  [[ $fr != *"mailto:ESSAI-PUBLISHER_EMAIL"* ]] || { echo "une valeur sans @ a produit un mailto:" >&2; exit 1; }
  [[ $fr != *"tel:ESSAI-PUBLISHER_PHONE"* ]] || { echo "une valeur sans chiffre a produit un tel:" >&2; exit 1; }
}

case_legal_un_vrai_courriel_devient_un_lien() {
  construire
  local -a env_args=()
  while IFS= read -r ligne; do env_args+=("$ligne"); done < <(valeurs_essai)
  env_args+=("HUGO_LEGAL_PUBLISHER_EMAIL=essai@exemple.invalide" "HUGO_LEGAL_PUBLISHER_PHONE=+33 1 23 45 67 89")
  run bash -c 'cd "$1" && env "${@:3}" hugo --environment production --minify --destination sortie' \
    _ "$work/site" _ "${env_args[@]}"
  assert_eq 0 "$rc" "le build réussit (messages : $err)"
  local fr
  fr=$(page mentions-legales/index.html)
  assert_contains 'href=mailto:essai@exemple.invalide' "$fr" "une adresse devient un lien mailto:"
  # Le « + » ne doit pas être échappé : « tel:&#43;… » est un lien mort.
  assert_contains 'href=tel:+33123456789' "$fr" "un numéro devient un lien tel: sans espaces"
  [[ $fr != *"tel:&#43;"* ]] || { echo "le + du numéro est échappé : le lien tel: est mort" >&2; exit 1; }
}
case_legal_le_tel_ne_garde_que_les_chiffres() {
  # La RFC 3966 n'admet ni point, ni tiret, ni parenthèse. Un numéro écrit « 01.23.45.67.89 »
  # laissait ses points dans le lien, que certains navigateurs refusent (constat de la revue de la
  # PR n° 98). Le texte affiché, lui, garde la ponctuation : c'est elle qui se lit.
  construire
  local -a env_args=()
  while IFS= read -r ligne; do env_args+=("$ligne"); done < <(valeurs_essai)
  env_args+=("HUGO_LEGAL_PUBLISHER_PHONE=01.23.45.67.89" "HUGO_LEGAL_HOST_PHONE=(+33) 1-23-45-67-89")
  run bash -c 'cd "$1" && env "${@:3}" hugo --environment production --minify --destination sortie' \
    _ "$work/site" _ "${env_args[@]}"
  assert_eq 0 "$rc" "le build réussit (messages : $err)"
  local fr
  fr=$(page mentions-legales/index.html)
  assert_contains 'href=tel:0123456789' "$fr" "les points disparaissent du lien"
  assert_contains '>01.23.45.67.89<' "$fr" "mais le texte affiché les garde"
  assert_contains 'href=tel:+33123456789' "$fr" "tirets et parenthèses aussi, le + de tête reste"
}

run_case "$@"
