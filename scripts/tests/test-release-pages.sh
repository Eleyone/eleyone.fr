#!/usr/bin/env bash
# C15 (story 11.1) : pages et sections attendues en FR et en EN, aucune page de groupe vide, aucune
# trace de travail dans le build de production.
#
# Les cas montent un petit site dans $work — deux accueils, une page simple, une page de groupe et
# son cas groupé — et les deux manifestes qui le décrivent, écrits à la main : la logique d'un
# contrôle se teste sans Hugo (docs/procedures/check.md).
#
# La sortie imite le **build de production**, qui est minifié : Hugo y écrit « id=case-09 » et
# « class=case-section » sans guillemets. Une fixture qui n'écrirait que la forme guillemetée
# laisserait passer un motif qui exige le guillemet, lequel compterait zéro sur le vrai site (faute
# B2 de la rétrospective de l'epic 7). Chaque page déclare aussi son encodage : sans
# « <meta charset=utf-8> », xmllint la lit en Latin-1 et les motifs cessent de correspondre en
# silence (point 16 d'AGENTS.md).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

page() { # $1 = chemin relatif dans public/, $2 = contenu du body
  mkdir -p "$(dirname "$work/public/$1")"
  printf '<!doctype html><html lang=fr><head><meta charset=utf-8><title>%s</title></head><body>%s</body></html>' \
    "$1" "$2" > "$work/public/$1"
}

# Manifeste d'une langue. Le cas groupé porte une « url » **vide** : c'est ce que Hugo rend pour une
# page dont la cascade dit « render: never » (AD-4), et c'est par là que le contrôle distingue une
# page d'une section (constat B3 de la revue de spec).
manifeste() { # $1 = chemin, $2 = langue, $3 = url accueil, $4 = url page simple, $5 = url du groupe
  local chemin=$1 langue=$2 accueil=$3 simple=$4 groupe=$5
  mkdir -p "$(dirname "$chemin")"
  cat > "$chemin" <<JSON
{
  "lang": "$langue",
  "stack": [],
  "rubrics": [],
  "files": [
    {"file": "_index.$langue.md", "lang": "$langue", "kind": "home", "role": "home",
     "translationKey": "home", "url": "$accueil", "draft": false, "front_matter": {}},
    {"file": "about.$langue.md", "lang": "$langue", "kind": "page", "role": "page",
     "translationKey": "about", "url": "$simple", "draft": false, "front_matter": {}},
    {"file": "cases/groupe/_index.$langue.md", "lang": "$langue", "kind": "section", "role": "group",
     "translationKey": "group-groupe", "url": "$groupe", "draft": false, "front_matter": {}},
    {"file": "cases/groupe/case-09-essai.$langue.md", "lang": "$langue", "kind": "page", "role": "case",
     "translationKey": "case-09", "url": "", "draft": false, "front_matter": {"group": "groupe"}}
  ]
}
JSON
}

liste() { # les clés attendues, une par argument
  {
    printf '# clés attendues, liste cumulative (D-5).\n'
    printf '\n'
    (($# == 0)) || printf '%s\n' "$@"
  } > "$work/release-pages.txt"
}

site() {
  rm -rf "$work/public" "$work/rendu"
  mkdir -p "$work/public" "$work/rendu/en"
  page index.html '<h1>Accueil</h1>'
  page a-propos/index.html '<h1>À propos</h1>'
  page cas/groupe/index.html '<h1>Groupe</h1><section id=case-09 class=case-section><h2>Le cas</h2></section>'
  page en/index.html '<h1>Home</h1>'
  page en/about/index.html '<h1>About</h1>'
  page en/cases/groupe/index.html '<h1>Group</h1><section id=case-09 class=case-section><h2>The case</h2></section>'
  manifeste "$work/rendu/checks.json" fr "/" "/a-propos/" "/cas/groupe/"
  manifeste "$work/rendu/en/checks.json" en "/en/" "/en/about/" "/en/cases/groupe/"
  liste home about group-groupe case-09
}

# CHECK_RELEASE_PAGES_FILE, CHECK_PUBLIC_ROOT et CHECK_WORK_ROOT sont **toujours** posés : sans eux
# le contrôle retomberait sur le build, le rendu et la liste du dépôt, et les cas dépendraient de
# l'état d'un build voisin.
c15() { # $1 = niveau, « release » par défaut
  run env CHECK_LEVEL="${1:-release}" CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    CHECK_RELEASE_PAGES_FILE="$work/release-pages.txt" bash "$root/scripts/checks/release-pages.sh"
}

# --- niveau ---------------------------------------------------------------------------------------

case_release_pages_site_conforme() {
  site
  c15
  assert_eq 0 "$rc" "un site conforme passe (messages : $err)"
  assert_contains "pages et sections attendues présentes" "$out" "le contrôle le dit"
}

case_release_pages_hors_release_saute_en_le_disant() {
  # Les deux niveaux sur **la même sortie fautive** : « standard » passe, « release » échoue. Un
  # « exit 0 » muet cacherait un nom de variable mal écrit (constat B1 de la revue de spec).
  site
  rm -r "$work/public/a-propos"
  c15 standard
  assert_eq 0 "$rc" "hors release, le contrôle ne juge rien (messages : $err)"
  assert_contains "contrôle de mise en ligne sauté" "$out" "il dit qu'il est sauté, il ne se tait pas"
  assert_contains "standard" "$out" "et il nomme le niveau qu'il a lu"
  c15
  assert_eq 1 "$rc" "au niveau release, la même sortie échoue"
}

case_release_pages_niveau_absent_vaut_standard() {
  # « CHECK_LEVEL » absent : le contrôle ne doit pas se croire en mise en ligne.
  site
  rm -r "$work/public/a-propos"
  run env -u CHECK_LEVEL CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    CHECK_RELEASE_PAGES_FILE="$work/release-pages.txt" bash "$root/scripts/checks/release-pages.sh"
  assert_eq 0 "$rc" "sans niveau, le contrôle est sauté (messages : $err)"
  assert_contains "contrôle de mise en ligne sauté" "$out" "et il le dit"
}

# --- anomalies : ce qui empêche de juger -----------------------------------------------------------

case_release_pages_sans_build() {
  site
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/absent" CHECK_WORK_ROOT="$work/rendu" \
    CHECK_RELEASE_PAGES_FILE="$work/release-pages.txt" bash "$root/scripts/checks/release-pages.sh"
  assert_eq 2 "$rc" "une production absente est une anomalie, pas un écart"
  assert_contains "scripts/build.sh production" "$err" "le message dit quoi lancer"
}

case_release_pages_sans_rendu_de_travail() {
  site
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/absent" \
    CHECK_RELEASE_PAGES_FILE="$work/release-pages.txt" bash "$root/scripts/checks/release-pages.sh"
  assert_eq 2 "$rc" "sans manifeste, le contrôle ne sait rien des pages attendues"
  assert_contains "scripts/build.sh work" "$err" "le message dit quoi lancer"
}

case_release_pages_sans_xmllint() {
  # PATH réduit à un dossier qui n'a que dirname : le contrôle s'arrête avant de rien lire.
  site
  mkdir -p "$work/bin-nu"
  ln -sf "$(command -v dirname)" "$work/bin-nu/dirname"
  run env PATH="$work/bin-nu" CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" \
    CHECK_WORK_ROOT="$work/rendu" CHECK_RELEASE_PAGES_FILE="$work/release-pages.txt" \
    "$(command -v bash)" "$root/scripts/checks/release-pages.sh"
  assert_eq 2 "$rc" "xmllint absent est une anomalie"
  assert_contains "libxml2-utils" "$err" "le message nomme le paquet"
}

case_release_pages_sans_jq() {
  site
  mkdir -p "$work/bin-xml"
  ln -sf "$(command -v dirname)" "$work/bin-xml/dirname"
  ln -sf "$(command -v xmllint)" "$work/bin-xml/xmllint"
  run env PATH="$work/bin-xml" CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" \
    CHECK_WORK_ROOT="$work/rendu" CHECK_RELEASE_PAGES_FILE="$work/release-pages.txt" \
    "$(command -v bash)" "$root/scripts/checks/release-pages.sh"
  assert_eq 2 "$rc" "jq absent est une anomalie"
  assert_contains "jq est introuvable" "$err" "le message nomme l'outil"
}

case_release_pages_liste_absente() {
  site
  rm "$work/release-pages.txt"
  c15
  assert_eq 2 "$rc" "sans la liste, le contrôle ne sait pas ce qu'il doit trouver"
  assert_contains "liste des pages attendues absente" "$err" "le message nomme le fichier"
}

case_release_pages_liste_vide_nest_pas_une_conformite() {
  # Un fichier **présent mais vide** — ou qui n'a que des commentaires — passerait pour une
  # conformité : c'est le piège déjà rencontré avec le fichier de motifs, qui désactivait l'audit
  # sans rien dire (docs/procedures/shell-scripts.md).
  site
  liste
  c15
  assert_eq 2 "$rc" "une liste sans aucune clé est une anomalie"
  assert_contains "une liste vide n'est pas une conformité" "$err" "le message le dit"
}

case_release_pages_manifeste_sans_cle_url() {
  # Un manifeste antérieur à la story 11.1 n'émet pas « url » : toute page passerait pour une
  # section, et le contrôle se tairait sur l'essentiel.
  site
  local fichier
  for fichier in "$work/rendu/checks.json" "$work/rendu/en/checks.json"; do
    jq 'del(.files[].url)' "$fichier" > "$fichier.sans-url"
    mv "$fichier.sans-url" "$fichier"
  done
  c15
  assert_eq 2 "$rc" "un manifeste sans « url » est une anomalie"
  assert_contains "layouts/home.checks.json" "$err" "le message nomme le gabarit à corriger"
}

case_release_pages_manifeste_sans_entree() {
  site
  jq '.files = []' "$work/rendu/checks.json" > "$work/rendu/checks.json.vide"
  mv "$work/rendu/checks.json.vide" "$work/rendu/checks.json"
  c15
  assert_eq 2 "$rc" "un manifeste sans entrée est une anomalie"
  assert_contains "une liste vide n'est pas une conformité" "$err" "le message le dit"
}

case_release_pages_sans_page_html() {
  # Sans page, aucun marqueur n'est trouvé : les règles d'exclusion passeraient toutes au vert sur
  # une racine erronée. Une liste vide n'est jamais une conformité (rétrospective de l'epic 3).
  site
  find "$work/public" -name '*.html' -delete
  c15
  assert_eq 2 "$rc" "une production sans page HTML est une anomalie"
  assert_contains "aucune page HTML" "$err" "le message le dit"
}

case_release_pages_decompte_illisible_est_une_anomalie() {
  # Le décompte des cas d'une page de groupe est un nombre : si libxml2 rend autre chose — une autre
  # version, une requête qui cesse d'être un « count() » —, le contrôle doit s'arrêter, et non
  # comparer une chaîne à zéro et conclure que la page est pleine. Un faux xmllint rend le décompte
  # illisible et délègue tout le reste au vrai : le contrat se vérifie sans dépendre d'une version.
  site
  mkdir -p "$work/bin-faux"
  cat > "$work/bin-faux/xmllint" <<FAUX
#!/usr/bin/env bash
for argument in "\$@"; do
  [[ \$argument != count\(* ]] || { printf 'beaucoup'; exit 0; }
done
exec $(command -v xmllint) "\$@"
FAUX
  chmod +x "$work/bin-faux/xmllint"
  run env PATH="$work/bin-faux:$PATH" CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" \
    CHECK_WORK_ROOT="$work/rendu" CHECK_RELEASE_PAGES_FILE="$work/release-pages.txt" \
    bash "$root/scripts/checks/release-pages.sh"
  assert_eq 2 "$rc" "un décompte illisible est une anomalie"
  assert_contains "décompte des cas illisible" "$err" "le message nomme la page et ce qui a été rendu"
}

case_release_pages_page_illisible_est_une_anomalie() {
  skip_if_root "la page du groupe"
  site
  chmod 000 "$work/public/cas/groupe/index.html"
  c15
  chmod 644 "$work/public/cas/groupe/index.html"
  assert_eq 2 "$rc" "une page illisible est une anomalie, pas une section absente"
  assert_contains "lecture XPath impossible" "$err" "le message nomme le fichier"
}

# --- règles d'inclusion : ce qui doit être là --------------------------------------------------------

case_release_pages_cle_inconnue_du_manifeste() {
  # Une clé que le manifeste ignore est un écart, pas un silence : la liste et le contenu ont divergé.
  site
  liste home about group-groupe case-09 case-42
  c15
  assert_eq 1 "$rc" "une clé inconnue fait échouer"
  assert_contains "clé « case-42 » inconnue du manifeste fr" "$err" "le signalement nomme la clé et la langue"
  assert_contains "clé « case-42 » inconnue du manifeste en" "$err" "dans les deux langues"
}

case_release_pages_page_absente_en_francais() {
  site
  rm -r "$work/public/a-propos"
  c15
  assert_eq 1 "$rc" "une page attendue absente fait échouer"
  assert_contains "a-propos/index.html: C15 : page attendue absente" "$err" "le signalement nomme la page"
  assert_contains "clé « about », fr" "$err" "et la clé et la langue"
}

case_release_pages_page_absente_en_anglais() {
  # La même page, du côté anglais : les deux langues sont exigées, pas seulement celle de la racine.
  site
  rm -r "$work/public/en/about"
  c15
  assert_eq 1 "$rc" "une page absente en anglais fait échouer aussi"
  assert_contains "en/about/index.html: C15 : page attendue absente" "$err" "le signalement nomme la page anglaise"
  assert_contains "clé « about », en" "$err" "et la langue"
}

case_release_pages_accueil_absent() {
  # « / » doit se résoudre en « index.html », et non rester une URL.
  site
  rm "$work/public/index.html"
  c15
  assert_eq 1 "$rc" "un accueil absent fait échouer"
  assert_contains "index.html: C15 : page attendue absente" "$err" "la racine se résout en index.html"
}

case_release_pages_section_dun_cas_groupe_absente() {
  # Le cas groupé n'a pas de page à lui : sa clé désigne une **section** de la page du groupe.
  site
  sed -i 's/id=case-09/id=case-autre/' "$work/public/cas/groupe/index.html"
  c15
  assert_eq 1 "$rc" "une section absente fait échouer"
  assert_contains "cas/groupe/index.html: C15 : section « case-09 » absente" "$err" "le signalement nomme la page et la section"
}

case_release_pages_section_guillemetee_passe_aussi() {
  # Le site de référence est minifié ; une sortie non minifiée guillemette ses attributs. Les deux
  # formes désignent le même identifiant, et le contrôle les lit par XPath, jamais par grep.
  site
  page cas/groupe/index.html '<h1>Groupe</h1><section id="case-09" class="case-section"><h2>Le cas</h2></section>'
  c15
  assert_eq 0 "$rc" "la forme guillemetée est vue elle aussi (messages : $err)"
}

case_release_pages_page_de_groupe_absente() {
  site
  rm -r "$work/public/cas/groupe"
  c15
  assert_eq 1 "$rc" "sans page de groupe, la section n'est nulle part"
  assert_contains "page du groupe « groupe » absente" "$err" "le signalement le dit"
  assert_contains "section « case-09 »" "$err" "et nomme la section qu'on cherchait"
}

case_release_pages_cas_groupe_sans_cle_group() {
  site
  local fichier
  for fichier in "$work/rendu/checks.json" "$work/rendu/en/checks.json"; do
    jq '(.files[] | select(.translationKey == "case-09") | .front_matter) = {}' "$fichier" > "$fichier.sans-groupe"
    mv "$fichier.sans-groupe" "$fichier"
  done
  c15
  assert_eq 1 "$rc" "un cas sans URL et sans groupe fait échouer"
  assert_contains "sans clé « group »" "$err" "le signalement le dit"
}

case_release_pages_cle_sans_url_et_sans_role_de_cas() {
  # Un poste ou une formation n'est pas une page publiable : listé, il ne peut pas être « trouvé »,
  # et le contrôle doit le dire plutôt que de chercher une section qui n'existe pas.
  site
  local langue fichier
  for langue in fr en; do
    fichier=$work/rendu/checks.json
    [[ $langue == fr ]] || fichier=$work/rendu/en/checks.json
    jq --arg langue "$langue" '.files += [{"file": "career/position-essai.\($langue).md",
                    "lang": $langue, "kind": "page", "role": "position",
                    "translationKey": "position-essai", "url": "", "draft": false, "front_matter": {}}]' \
      "$fichier" > "$fichier.poste"
    mv "$fichier.poste" "$fichier"
  done
  liste home about group-groupe case-09 position-essai
  c15
  assert_eq 1 "$rc" "une clé qui ne désigne aucune page publiable fait échouer"
  assert_contains "ne désigne aucune page publiable" "$err" "le signalement le dit"
  assert_contains "rôle « position »" "$err" "et nomme le rôle qu'il a lu"
}

case_release_pages_page_de_groupe_vide() {
  # « Vide » se lit sur la page : un titre de groupe sans un seul cas (constat B4).
  site
  page cas/groupe/index.html '<h1>Groupe</h1><p>Aucun cas publié.</p>'
  c15
  assert_eq 1 "$rc" "une page de groupe sans cas fait échouer"
  assert_contains "cas/groupe/index.html: C15 : page de groupe vide" "$err" "le signalement nomme la page"
}

case_release_pages_page_de_groupe_vide_en_anglais() {
  site
  page en/cases/groupe/index.html '<h1>Group</h1><p>No published case.</p>'
  c15
  assert_eq 1 "$rc" "la règle vaut pour les deux langues"
  assert_contains "en/cases/groupe/index.html: C15 : page de groupe vide" "$err" "le signalement nomme la page anglaise"
}

case_release_pages_classe_voisine_ne_compte_pas_pour_un_cas() {
  # « case-section-titre » contient « case-section » : un motif qui ne borne pas la classe compterait
  # cette page pour pleine. Le prédicat encadre la classe d'espaces (point 15 d'AGENTS.md : quelles
  # *autres formes* la faute peut prendre).
  site
  page cas/groupe/index.html '<h1>Groupe</h1><section id=case-09 class=case-section-titre><h2>Le cas</h2></section>'
  c15
  assert_eq 1 "$rc" "une classe seulement voisine ne remplit pas la page de groupe"
  assert_contains "page de groupe vide" "$err" "le signalement le dit"
}

case_release_pages_classe_parmi_dautres_compte() {
  # L'inverse : « class="case-section encart" » est bien une section de cas.
  site
  page cas/groupe/index.html '<h1>Groupe</h1><section id=case-09 class="encart case-section"><h2>Le cas</h2></section>'
  c15
  assert_eq 0 "$rc" "une classe accompagnée d'une autre compte (messages : $err)"
}

# --- règles d'exclusion : ce qui ne doit pas y être ---------------------------------------------------

case_release_pages_manifeste_publie() {
  # Un **fichier**, pas une chaîne : le message ne doit pas parler de « trace trouvée dans la page ».
  site
  cp "$work/rendu/checks.json" "$work/public/checks.json"
  c15
  assert_eq 1 "$rc" "un manifeste publié fait échouer"
  assert_contains "checks.json: C15 : fichier de manifeste publié" "$err" "le signalement nomme le fichier"
}

case_release_pages_manifeste_publie_dans_un_sous_dossier() {
  site
  mkdir -p "$work/public/en"
  cp "$work/rendu/en/checks.json" "$work/public/en/checks.json"
  c15
  assert_eq 1 "$rc" "un manifeste publié ailleurs qu'à la racine fait échouer aussi"
  assert_contains "en/checks.json: C15 : fichier de manifeste publié" "$err" "le signalement nomme le fichier"
}

case_release_pages_valeur_factice() {
  site
  page mentions-legales/index.html '<h1>Mentions</h1><p>VALEUR-FACTICE-editeur-nom</p>'
  c15
  assert_eq 1 "$rc" "une valeur factice fait échouer"
  assert_contains "mentions-legales/index.html: C15 : trace de travail « VALEUR-FACTICE »" "$err" \
    "le signalement nomme la page et la chaîne"
}

case_release_pages_noindex_minifie() {
  # La forme que produit le build : « <meta name=robots content=noindex> », sans guillemets.
  site
  page index.html '<h1>Accueil</h1><meta name=robots content=noindex>'
  c15
  assert_eq 1 "$rc" "un noindex minifié fait échouer"
  assert_contains "index.html: C15 : trace de travail « noindex »" "$err" "le signalement le dit"
}

case_release_pages_noindex_autres_formes() {
  # Les autres formes que la faute peut prendre : majuscules, guillemets, directive accompagnée.
  site
  page index.html '<h1>Accueil</h1><meta name="robots" content="NOINDEX, nofollow">'
  c15
  assert_eq 1 "$rc" "un noindex en majuscules, guillemeté et accompagné fait échouer"
  assert_contains "trace de travail « noindex »" "$err" "le signalement le dit"
}

case_release_pages_draft_marker() {
  site
  page cas/groupe/index.html '<h1>Groupe</h1><section id=case-09 class=case-section><h2><span class=draft-marker>Brouillon</span> Le cas</h2></section>'
  c15
  assert_eq 1 "$rc" "un marqueur de brouillon fait échouer"
  assert_contains "cas/groupe/index.html: C15 : trace de travail « draft-marker »" "$err" "le signalement le dit"
}

case_release_pages_marqueur_hors_dune_page_ne_compte_pas() {
  # La recherche porte sur les pages : la feuille de style porte légitimement le nom de la classe, et
  # ce que C15 refuse est une trace **rendue au lecteur** (constat NB2 de la revue de spec).
  site
  mkdir -p "$work/public/css"
  printf '.draft-marker { color: red }\n' > "$work/public/css/main.css"
  c15
  assert_eq 0 "$rc" "le nom de la classe dans la feuille de style ne compte pas (messages : $err)"
}

case_release_pages_tous_les_ecarts_sont_listes() {
  # Le second critère d'acceptation : le contrôle ne s'arrête pas au premier écart, il les liste.
  site
  rm -r "$work/public/a-propos"
  page en/cases/groupe/index.html '<h1>Group</h1><p>No published case.</p>'
  page index.html '<h1>Accueil</h1><p>VALEUR-FACTICE-editeur-nom</p>'
  c15
  assert_eq 1 "$rc" "plusieurs écarts font échouer"
  assert_contains "a-propos/index.html: C15 : page attendue absente" "$err" "la page absente est listée"
  assert_contains "en/cases/groupe/index.html: C15 : page de groupe vide" "$err" "la page de groupe vide aussi"
  assert_contains "index.html: C15 : trace de travail « VALEUR-FACTICE »" "$err" "et la valeur factice"
}

run_case "$@"
