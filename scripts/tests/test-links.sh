#!/usr/bin/env bash
# C12 (story 3.10) : liens internes, ancres, pages orphelines, liens conditionnels. Les cas montent
# un petit site dans $work : deux accueils, une page de groupe et ses ancres, comme la vraie sortie.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

page() { # $1 = chemin relatif, $2 = contenu du body
  mkdir -p "$(dirname "$work/public/$1")"
  printf '<!doctype html><html lang=fr><head><meta charset=utf-8><title>%s</title></head><body>%s</body></html>' \
    "$1" "$2" > "$work/public/$1"
}

# Site conforme : chaque accueil mène à la page de groupe de sa langue, qui porte ses ancres.
site() {
  rm -rf "$work/public"
  mkdir -p "$work/public"
  page index.html '<h1>Accueil</h1><p><a href="/cas/chiliz/#case-02">Cas 02</a></p>'
  page en/index.html '<h1>Home</h1><p><a href="/en/cases/chiliz/#case-02">Case 02</a></p>'
  page cas/chiliz/index.html '<h1>Chiliz</h1><p><a href="/#position-chiliz">Retour</a></p><section id=case-02><h2 id=case-02-contexte>Contexte</h2></section>'
  page en/cases/chiliz/index.html '<h1>Chiliz</h1><p><a href="/en/#position-chiliz">Back</a></p><section id=case-02><h2 id=case-02-context>Context</h2></section>'
  # L'accueil porte l'ancre du poste, cible du « Retour au parcours ».
  sed -i 's#<h1>Accueil</h1>#<h1>Accueil</h1><div id=position-chiliz>Poste</div>#' "$work/public/index.html"
  sed -i 's#<h1>Home</h1>#<h1>Home</h1><div id=position-chiliz>Poste</div>#' "$work/public/en/index.html"
  page 404.html '<h1>Introuvable</h1>'
  page en/404.html '<h1>Not found</h1>'
}

liens() {
  run env CHECK_PUBLIC_ROOT="$work/public" CHECK_CONFIG_FILE="$work/hugo.yaml" bash "$root/scripts/checks/links.sh"
}

config() { # $1 = valeur de source_url, vide pour aucune
  if [[ -n ${1:-} ]]; then printf 'params:\n  source_url: %s\n' "$1" > "$work/hugo.yaml"
  else printf 'params:\n  source_url:\n' > "$work/hugo.yaml"; fi
}

case_links_site_conforme() {
  site; config
  liens
  assert_eq 0 "$rc" "un site conforme passe (messages : $err)"
  assert_contains "liens internes, ancres, pages atteignables" "$out" "le contrôle le dit"
}

case_links_page_absente() {
  site; config
  sed -i 's#href="/cas/chiliz/\#case-02"#href="/cas/absente/"#' "$work/public/index.html"
  liens
  assert_eq 1 "$rc" "un lien vers une page absente fait échouer"
  assert_contains "vers une page absente (cas/absente/index.html)" "$err" "le signalement donne la cible résolue"
}

case_links_ancre_absente() {
  site; config
  sed -i 's/id=case-02-contexte/id=case-02-autre/' "$work/public/cas/chiliz/index.html"
  liens
  assert_eq 0 "$rc" "aucun lien ne visait cette ancre (messages : $err)"
  sed -i 's#href="/cas/chiliz/\#case-02"#href="/cas/chiliz/\#case-02-contexte"#' "$work/public/index.html"
  liens
  assert_eq 1 "$rc" "une ancre absente de la page visée fait échouer"
  assert_contains "ancre « #case-02-contexte » absente de cas/chiliz/index.html" "$err" "le signalement nomme l'ancre et la page"
}

case_links_ancre_de_poste() {
  # « Retour au parcours » vise #position-<id> sur l'accueil (AD-18).
  site; config
  sed -i 's/id=position-chiliz/id=position-autre/' "$work/public/index.html"
  liens
  assert_eq 1 "$rc" "un retour au parcours sans sa cible fait échouer"
  assert_contains "ancre « #position-chiliz » absente de index.html" "$err" "le signalement le dit"
}

case_links_page_orpheline() {
  site; config
  page cas/orpheline/index.html '<h1>Orpheline</h1>'
  liens
  assert_eq 1 "$rc" "une page que rien ne lie fait échouer"
  assert_contains "cas/orpheline/index.html: C12 : page orpheline" "$err" "le signalement nomme la page"
}

case_links_orpheline_liee_par_une_orpheline() {
  # Une page liée seulement depuis une page orpheline reste injoignable : c'est pourquoi le parcours
  # part des accueils (refus de la simplification proposée par la revue de spec).
  site; config
  page cas/a/index.html '<h1>A</h1><p><a href="/cas/b/">B</a></p>'
  page cas/b/index.html '<h1>B</h1>'
  liens
  assert_eq 1 "$rc" "les deux pages sont orphelines"
  assert_contains "cas/a/index.html: C12 : page orpheline" "$err" "la première est signalée"
  assert_contains "cas/b/index.html: C12 : page orpheline" "$err" "la seconde aussi, bien qu'elle soit liée"
}

case_links_404_exemptees() {
  site; config
  liens
  assert_eq 0 "$rc" "les deux 404, que rien ne lie, ne sont pas signalées (messages : $err)"
}

case_links_lien_externe_ignore() {
  site; config
  sed -i 's#<h1>Accueil</h1>#<h1>Accueil</h1><p><a href="https://www.linkedin.com/in/x/">LinkedIn</a><a href="mailto:contact@exemple.invalide">Mail</a></p>#' \
    "$work/public/index.html"
  liens
  assert_eq 0 "$rc" "les liens externes et mailto sortent du périmètre (messages : $err)"
}

case_links_cv_incoherents() {
  site; config
  sed -i 's#<h1>Accueil</h1>#<h1>Accueil</h1><p><a href="/assets/cv/cv-fr.pdf">CV</a></p>#' "$work/public/index.html"
  liens
  assert_eq 1 "$rc" "un lien de CV sans les deux PDF fait échouer"
  assert_contains "mènent à un CV alors que les deux PDF ne sont pas publiés" "$err" "le signalement renvoie à AD-21"
  mkdir -p "$work/public/assets/cv"
  : > "$work/public/assets/cv/cv-fr.pdf"; : > "$work/public/assets/cv/cv-en.pdf"
  liens
  assert_eq 0 "$rc" "avec les deux PDF publiés, le lien passe (messages : $err)"
}

case_links_cv_publies_sans_lien() {
  site; config
  mkdir -p "$work/public/assets/cv"
  : > "$work/public/assets/cv/cv-fr.pdf"; : > "$work/public/assets/cv/cv-en.pdf"
  liens
  assert_eq 1 "$rc" "deux CV publiés sans lien font échouer"
  assert_contains "aucune page n'y mène" "$err" "le signalement le dit"
}

case_links_depot_sans_lien() {
  site; config https://github.com/Eleyone/eleyone.fr
  liens
  assert_eq 1 "$rc" "une source_url renseignée sans lien fait échouer"
  assert_contains "aucune page ne mène au dépôt" "$err" "le signalement le dit"
  sed -i 's#<h1>Accueil</h1>#<h1>Accueil</h1><p><a href="https://github.com/Eleyone/eleyone.fr">Source</a></p>#' \
    "$work/public/index.html"
  liens
  assert_eq 0 "$rc" "avec le lien, le contrôle passe (messages : $err)"
}

case_links_page_illisible_est_une_anomalie() {
  skip_if_root "la page"
  site; config
  chmod 000 "$work/public/cas/chiliz/index.html"
  liens
  chmod 644 "$work/public/cas/chiliz/index.html"
  assert_eq 2 "$rc" "une page illisible est une anomalie"
  assert_contains "lecture XPath impossible" "$err" "le message nomme le fichier"
}

case_links_sans_build() {
  run env CHECK_PUBLIC_ROOT="$work/absent" bash "$root/scripts/checks/links.sh"
  assert_eq 2 "$rc" "une production absente est une anomalie"
  assert_contains "scripts/build.sh production" "$err" "le message dit quoi lancer"
}

run_case "$@"
