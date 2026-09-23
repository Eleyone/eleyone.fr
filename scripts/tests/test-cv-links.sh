#!/usr/bin/env bash
# Liens conditionnels vers les CV PDF (story 7.2, AD-21, FR-38).
#
# Les trois états se jouent sur un vrai build : deux PDF, un seul, aucun. La règle « ensemble ou
# rien » ne se relit pas dans un gabarit, elle se constate dans la sortie — c'est tout l'intérêt
# d'un partial qui doit n'émettre **rien**.
#
# Les PDF d'essai sont fabriqués octet par octet, comme dans test-pdf.sh : aucun n'entre dans le
# dépôt. Hors ligne, avec le Hugo épinglé.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-cv-links
. "$root/scripts/lib/tools.sh"

readonly insecable=$' '

# Le PDF d'essai vient de « tests_pdf » (scripts/tests/lib.sh) : son cinquième paramètre est le
# bourrage, qui pèse le fichier pour vérifier le poids annoncé dans le libellé.
# $1… : les noms de CV à poser dans assets/cv/ ; aucun argument pour un dossier vide.
construire() {
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content" "$work/site/assets/cv"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$root/assets/css" "$work/site/assets/"
  printf -- '---\ntitle: "Accueil"\n---\n' > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\n---\n' > "$work/site/content/_index.en.md"
  local nom
  for nom in "$@"; do tests_pdf "$work/site/assets/cv/$nom" "" "" "" 311000; done
  (cd "$work/site" && hugo --environment work --buildDrafts --panicOnWarning --destination sortie) \
    > "$work/hugo.out" 2>&1
}

pied() { # $1 = page ; le pied de page, ramené sur une ligne
  tr '\n' ' ' < "$work/site/sortie/$1" | sed -n 's/.*\(<ul class="site-footer__list">.*<\/ul>\).*/\1/p'
}

case_cv_les_deux_pdf() {
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr en
  fr=$(pied index.html)
  en=$(pied en/index.html)
  assert_contains 'href="/cv/cv-fr.pdf"' "$fr" "le CV français est lié"
  assert_contains 'href="/cv/cv-en.pdf"' "$fr" "le CV anglais aussi"
  assert_contains 'type="application/pdf"' "$fr" "le type du fichier est annoncé"
  # Le libellé est autonome : format, langue, poids. Même construction dans les deux langues.
  assert_contains "CV (PDF, français, 311${insecable}Ko)" "$fr" "le libellé français dit tout"
  assert_contains "CV (PDF, English, 311${insecable}KB)" "$en" "le libellé anglais dit tout"
}

case_cv_le_cv_de_la_langue_vient_en_premier() {
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr en
  fr=$(pied index.html)
  en=$(pied en/index.html)
  # La position du premier lien de chaque CV, dans la chaîne : c'est l'ordre du DOM.
  #
  # La **présence** des deux est affirmée d'abord : « ${x%%motif*} » rend la chaîne inchangée quand
  # le motif manque, donc « très loin », et un lien absent passait pour un lien venant en dernier.
  # Le cas validait alors un pied de page amputé. Trouvé en balayant cette classe d'erreur après un
  # constat de la revue de la PR n° 100 sur un autre fichier — le constat ne visait pas celui-ci.
  premier_des_deux "$fr" cv-fr.pdf cv-en.pdf "sur une page FR, le CV français ne vient pas en premier"
  premier_des_deux "$en" cv-en.pdf cv-fr.pdf "sur une page EN, le CV anglais ne vient pas en premier"
}

premier_des_deux() { # $1 = texte, $2 = attendu en premier, $3 = attendu ensuite, $4 = message
  local texte=$1 premier=$2 second=$3 message=$4
  [[ $texte == *"$premier"* ]] || { echo "$message (« $premier » absent)" >&2; exit 1; }
  [[ $texte == *"$second"* ]] || { echo "$message (« $second » absent)" >&2; exit 1; }
  local avant_premier=${texte%%"$premier"*} avant_second=${texte%%"$second"*}
  ((${#avant_premier} < ${#avant_second})) || { echo "$message" >&2; exit 1; }
}

case_cv_un_seul_pdf_nemet_rien() {
  # « Ensemble ou rien » : ni lien, ni ligne, ni étiquette, ni « bientôt ».
  run construire cv-fr.pdf
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr
  fr=$(pied index.html)
  [[ $fr != *"/cv/"* ]] || { echo "un CV est lié alors qu'un seul fichier existe" >&2; exit 1; }
  [[ $fr != *"cv-links__item"* ]] || { echo "une ligne vide de CV subsiste" >&2; exit 1; }
}

case_cv_aucun_pdf_nemet_rien() {
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr
  fr=$(pied index.html)
  [[ $fr != *"/cv/"* ]] || { echo "un CV est lié alors qu'aucun fichier n'existe" >&2; exit 1; }
  assert_contains "Code source du site" "$fr" "le reste du pied de page est intact"
}

case_cv_aucun_lien_dans_len_tete() {
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local entete
  entete=$(tr '\n' ' ' < "$work/site/sortie/index.html" | sed -n 's/.*\(<header.*<\/header>\).*/\1/p')
  [[ -n $entete ]] || { echo "aucun en-tête rendu" >&2; exit 1; }
  [[ $entete != *"/cv/"* ]] || { echo "un lien de CV dans l'en-tête (DESIGN.md l'interdit)" >&2; exit 1; }
}

case_cv_un_petit_fichier_ne_sannonce_jamais_a_zero() {
  # 405 octets font « 1 Ko », pas « 0 Ko » : un poids nul ferait douter du lien.
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit"
  # Reconstruit avec des fichiers minuscules, sans bourrage.
  tests_pdf "$work/site/assets/cv/cv-fr.pdf"
  tests_pdf "$work/site/assets/cv/cv-en.pdf"
  (cd "$work/site" && hugo --environment work --buildDrafts --panicOnWarning --destination sortie) \
    > "$work/hugo.out" 2>&1
  local fr
  fr=$(pied index.html)
  assert_contains "1${insecable}Ko" "$fr" "un fichier minuscule s'annonce à 1 Ko"
  [[ $fr != *"0${insecable}Ko"* ]] || { echo "un CV s'annonce à 0 Ko" >&2; exit 1; }
}

case_cv_le_poids_ne_se_coupe_pas() {
  # Le nombre et son unité tiennent ensemble : une espace ordinaire les laisserait se séparer en
  # fin de ligne, dans un pied de page étroit.
  run construire cv-fr.pdf cv-en.pdf
  assert_eq 0 "$rc" "le build réussit"
  local fr
  fr=$(pied index.html)
  [[ $fr != *" Ko)"* ]] || { echo "une espace ordinaire sépare le poids de son unité" >&2; exit 1; }
}
run_case "$@"
