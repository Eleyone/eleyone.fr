#!/usr/bin/env bash
# C13 (story 3.11) : budgets de poids et d'éléments. Les cas montent une sortie dans $work, avec des
# fichiers de taille choisie — aucun ne dépasse quelques centaines de kilo-octets.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

octets() { # $1 = fichier, $2 = taille voulue
  mkdir -p "$(dirname "$1")"
  head -c "$2" /dev/zero | tr '\0' 'x' > "$1"
}

sortie() { # $1 = contenu du body de la page
  rm -rf "$work/public"
  mkdir -p "$work/public"
  printf '<!doctype html><html lang=fr><head><meta charset=utf-8><title>P</title></head><body>%s</body></html>' \
    "${1:-<h1>Page</h1>}" > "$work/public/index.html"
}

budget() {
  run env CHECK_PUBLIC_ROOT="$work/public" bash "$root/scripts/checks/budget.sh"
}

case_budget_sortie_conforme() {
  sortie
  budget
  assert_eq 0 "$rc" "une sortie légère passe (messages : $err)"
  assert_contains "dans les budgets" "$out" "le contrôle le dit"
}

case_budget_html_trop_lourd() {
  sortie
  octets "$work/public/index.html" 50001
  budget
  assert_eq 1 "$rc" "un HTML de plus de 50 000 octets fait échouer"
  assert_contains "HTML de 50001 octets ; 50000 au plus" "$err" "le signalement donne la mesure"
}

case_budget_css_totale() {
  sortie '<link rel=stylesheet href=/a.css>'
  octets "$work/public/a.css" 12000
  octets "$work/public/b.css" 9000
  budget
  assert_eq 1 "$rc" "21 000 octets de CSS font échouer, même répartis sur deux fichiers"
  assert_contains "21000 octets de CSS pour tout le site" "$err" "le signalement additionne le site entier"
}

case_budget_svg_trop_lourd() {
  sortie
  octets "$work/public/schema.svg" 60001
  budget
  assert_eq 1 "$rc" "un SVG de plus de 60 000 octets fait échouer"
  assert_contains "SVG de 60001 octets" "$err" "le signalement nomme le fichier"
}

case_budget_page_complete() {
  sortie '<img src=/photo.webp alt=Photo width=10 height=10>'
  octets "$work/public/photo.webp" 199500
  budget
  assert_eq 0 "$rc" "199 500 octets plus le document restent sous le plafond (messages : $err)"
  octets "$work/public/photo.webp" 200000
  budget
  assert_eq 1 "$rc" "le document et ses médias dépassent alors 200 000 octets"
  assert_contains "page complète de" "$err" "le signalement donne le total"
}

case_budget_variantes_dune_image() {
  # Décidé le 19/09/2026 : une image déclinée ne pèse qu'une fois, par sa variante la plus lourde.
  sortie '<img src=/photo.webp srcset="/photo.webp 1x, /photo@2x.webp 2x" alt=Photo width=10 height=10>'
  octets "$work/public/photo.webp" 120000
  octets "$work/public/photo@2x.webp" 150000
  budget
  assert_eq 0 "$rc" "seule la variante la plus lourde compte : 150 000 + le HTML (messages : $err)"
  octets "$work/public/photo@2x.webp" 199900
  budget
  assert_eq 1 "$rc" "au-delà, la page dépasse"
}

case_budget_nombre_de_ressources() {
  local corps=""
  for i in 1 2 3 4 5 6 7 8 9 10 11; do
    corps+="<img src=/i$i.webp alt=x width=10 height=10>"
  done
  sortie "$corps"
  for i in 1 2 3 4 5 6 7 8 9 10 11; do octets "$work/public/i$i.webp" 100; done
  budget
  assert_eq 1 "$rc" "onze ressources font échouer"
  assert_contains "11 ressources chargées ; 10 au plus" "$err" "le signalement compte"
}

case_budget_html_pas_une_ressource() {
  # Le document n'est pas une ressource qu'il charge : dix images passent, onze non.
  local corps=""
  for i in 1 2 3 4 5 6 7 8 9 10; do corps+="<img src=/i$i.webp alt=x width=10 height=10>"; done
  sortie "$corps"
  for i in 1 2 3 4 5 6 7 8 9 10; do octets "$work/public/i$i.webp" 100; done
  budget
  assert_eq 0 "$rc" "dix ressources passent (messages : $err)"
}

case_budget_elements() {
  local corps="<h1>P</h1>"
  local i=0
  while ((i < 801)); do corps+="<p>x</p>"; i=$((i + 1)); done
  sortie "$corps"
  budget
  assert_eq 1 "$rc" "plus de 800 éléments font échouer"
  assert_contains "éléments HTML ; 800 au plus" "$err" "le signalement compte"
}

case_budget_javascript_ou_police() {
  sortie
  octets "$work/public/app.js" 10
  budget
  assert_eq 1 "$rc" "un fichier JavaScript dans la sortie fait échouer"
  assert_contains "fichier JavaScript ou de police" "$err" "le signalement le dit"
  rm "$work/public/app.js"
  octets "$work/public/police.woff2" 10
  budget
  assert_eq 1 "$rc" "un fichier de police aussi"
}

case_budget_ressource_absente() {
  sortie '<img src=/manquante.webp alt=x width=10 height=10>'
  budget
  assert_eq 1 "$rc" "une ressource chargée mais absente fait échouer"
  assert_contains "ressource chargée mais absente de la sortie : manquante.webp" "$err" "le signalement nomme le fichier"
}

case_budget_pdf_hors_budget() {
  # Les PDF du CV sont des liens, jamais chargés par la page (AD-21).
  sortie '<p><a href=/assets/cv/cv-fr.pdf>CV</a></p>'
  octets "$work/public/assets/cv/cv-fr.pdf" 400000
  budget
  assert_eq 0 "$rc" "un PDF lié ne pèse pas dans le budget de la page (messages : $err)"
}

case_budget_fichier_illisible_est_une_anomalie() {
  # Constat de la revue de la PR n° 47 : « || true » avalait aussi les vraies erreurs. Désormais
  # xmllint code 10 (aucun nœud) passe, code 1 (fichier illisible) est une anomalie.
  sortie
  chmod 000 "$work/public/index.html"
  budget
  chmod 644 "$work/public/index.html"
  assert_eq 2 "$rc" "un fichier illisible est une anomalie, pas un écart"
  assert_contains "lecture XPath impossible" "$err" "le message nomme le fichier et l'outil"
}

case_budget_source_dune_picture() {
  # Constat de la cinquième revue de la PR n° 47 : les images d'un <picture> chargent aussi.
  sortie '<picture><source srcset="/grande.webp 2x" type=image/webp><img src=/petite.webp alt=x width=10 height=10></picture>'
  octets "$work/public/petite.webp" 1000
  octets "$work/public/grande.webp" 199500
  budget
  assert_eq 1 "$rc" "l'image d'un <source> pèse dans la page"
  assert_contains "page complète de" "$err" "le signalement donne le total"
}

case_budget_css_dans_la_page_complete() {
  sortie '<link rel=stylesheet href=/a.css>'
  octets "$work/public/a.css" 19500
  budget
  assert_eq 0 "$rc" "une CSS sous les deux plafonds passe (messages : $err)"
  # La CSS compte dans la page complète : avec une image, le total dépasse.
  sortie '<link rel=stylesheet href=/a.css><img src=/photo.webp alt=x width=10 height=10>'
  octets "$work/public/a.css" 19500
  octets "$work/public/photo.webp" 181000
  budget
  assert_eq 1 "$rc" "la CSS entre bien dans le total de la page"
  assert_contains "page complète de" "$err" "le signalement le dit"
}

case_budget_toutes_les_extensions_interdites() {
  local ext
  for ext in js mjs woff woff2 ttf otf eot; do
    sortie
    octets "$work/public/fichier.$ext" 10
    budget
    assert_eq 1 "$rc" "un fichier .$ext dans la sortie fait échouer"
  done
}

case_budget_ressource_citee_deux_fois() {
  # Constat de la sixième revue de la PR n° 47 : une même URL n'est qu'une requête réseau.
  local corps=""
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do corps+="<img src=/i$i.webp alt=x width=10 height=10>"; done
  corps+="<img src=/i1.webp alt=x width=10 height=10><img src=/i2.webp alt=x width=10 height=10>"
  sortie "$corps"
  for i in 1 2 3 4 5 6 7 8 9 10; do octets "$work/public/i$i.webp" 100; done
  budget
  assert_eq 0 "$rc" "douze balises pour dix ressources distinctes passent (messages : $err)"
}

case_budget_sans_build() {
  run env CHECK_PUBLIC_ROOT="$work/absent" bash "$root/scripts/checks/budget.sh"
  assert_eq 2 "$rc" "une production absente est une anomalie"
  assert_contains "scripts/build.sh production" "$err" "le message dit quoi lancer"
}

run_case "$@"
