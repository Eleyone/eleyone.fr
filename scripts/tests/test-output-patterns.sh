#!/usr/bin/env bash
# C22 (story 11.2) : aucun motif interdit dans la sortie de production, sauf contenu dans une valeur
# HUGO_LEGAL_* injectée sur les deux pages des mentions légales.
#
# Les cas montent un petit rendu dans $work — deux accueils, les deux pages légales, un sitemap, un
# robots.txt — et les deux manifestes qui le décrivent, écrits à la main : la logique d'un contrôle
# se teste sans Hugo (docs/procedures/check.md).
#
# **Aucun motif réel n'entre ici.** La liste des motifs de ce fichier est fabriquée de toutes
# pièces, et les valeurs légales aussi : le contrôle cherche ce qu'on lui donne, et la vraie liste
# ne vit que dans docs/private/, hors du dépôt.
#
# Les fixtures imitent le **build de production** : minifié, attributs sans guillemets, encodage
# déclaré. Une fixture écrite à la main, aérée et non échappée, ferait passer au vert un contrôle
# incapable de lire la vraie sortie — c'est exactement ce qui est arrivé à C23 (point 16
# d'AGENTS.md). Trois cas écrivent donc le motif comme Hugo l'écrirait : en entités HTML, en
# séquences « \uXXXX » du JSON-LD, et coupé par un saut de ligne.
#
# Chaque cas éprouve une **garde**, et chacune a été lancée une fois contre un contrôle privé de
# cette garde : elles échouent alors, sans quoi elles ne prouveraient rien (point 9 d'AGENTS.md).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# --- les motifs et les valeurs légales, tous factices ----------------------------------------------
readonly motif="VILLEFACTICE-SUR-ESSAI"
readonly motif_deux="MOTIF-FACTICE-DEUX"
# Un motif portant une **espace** : c'est lui que la minification met sur une ligne quand la source
# l'écrivait sur deux, et c'est lui qui prouve qu'un grep ligne à ligne reste sûr après normalisation.
readonly motif_espace="MOTIF FACTICE COUPE"
# Un motif portant une apostrophe et une esperluette, les deux caractères que Hugo échappe.
readonly motif_echappable="ESSAI & L'AUTRE"

# L'adresse légale **contient** le motif : c'est tout l'objet de l'exception d'AD-9, et la commune
# d'une adresse est précisément le genre de chaîne que la liste des motifs porte.
readonly adresse_legale="1 rue de l'Essai & Cie, 00000 $motif"
readonly nom_legal="Nom Factice"
# Un nom d'hébergeur **contenu dans** l'adresse ci-dessus : il éprouve l'ordre d'expurgation.
readonly hote_legal="1 rue de l'Essai"

liste_motifs() { # $1… = motifs ; écrit la liste et affiche son chemin
  {
    printf '# liste factice, aucun motif réel (story 11.2)\n'
    printf '\n'
    printf '%s\n' "$@"
  } > "$work/motifs.txt"
  printf '%s' "$work/motifs.txt"
}

page() { # $1 = chemin relatif dans public/, $2 = corps, $3 = contenu de <head> en plus
  mkdir -p "$(dirname "$work/public/$1")"
  printf '<!doctype html><html lang=fr><head><meta charset=utf-8><title>%s</title>%s</head><body>%s</body></html>' \
    "$1" "${3:-}" "$2" > "$work/public/$1"
}

manifeste() { # $1 = chemin, $2 = langue, $3 = url de la page légale
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<JSON
{
  "lang": "$2",
  "stack": [],
  "rubrics": [],
  "files": [
    {"file": "_index.$2.md", "lang": "$2", "kind": "home", "role": "home",
     "translationKey": "home", "url": "/", "draft": false, "front_matter": {}},
    {"file": "legal-notice.$2.md", "lang": "$2", "kind": "page", "role": "page",
     "translationKey": "legal-notice", "url": "$3", "draft": false, "front_matter": {}}
  ]
}
JSON
}

# Un rendu conforme : les valeurs légales sur les deux pages légales, aucun motif ailleurs.
site() {
  rm -rf "$work/public" "$work/rendu"
  mkdir -p "$work/public" "$work/rendu/en"
  page index.html '<h1>Accueil</h1><p>Rien de privé ici.</p>'
  page en/index.html '<h1>Home</h1><p>Nothing private here.</p>'
  page mentions-legales/index.html \
    "<h1>Mentions légales</h1><address>$nom_legal, $adresse_legale</address><p>$hote_legal</p>"
  page en/legal-notice/index.html \
    "<h1>Legal notice</h1><address>$nom_legal, $adresse_legale</address><p>$hote_legal</p>"
  printf '<?xml version="1.0" encoding="utf-8"?><urlset><url><loc>https://exemple.invalide/</loc></url></urlset>' \
    > "$work/public/sitemap.xml"
  printf 'User-agent: *\nAllow: /\n' > "$work/public/robots.txt"
  manifeste "$work/rendu/checks.json" fr /mentions-legales/
  manifeste "$work/rendu/en/checks.json" en /en/legal-notice/
}

# CHECK_PUBLIC_ROOT, CHECK_WORK_ROOT et PRIVATE_PATTERNS_FILE sont **toujours** posés : sans eux le
# contrôle retomberait sur le build du dépôt et sur la vraie liste des motifs, et les cas
# dépendraient de l'état du poste.
c22() { # $1 = niveau (« release » par défaut), $2… = motifs de la liste
  local niveau=${1:-release}; shift || true
  (($#)) || set -- "$motif"
  run env CHECK_LEVEL="$niveau" CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    PRIVATE_PATTERNS_FILE="$(liste_motifs "$@")" \
    HUGO_LEGAL_PUBLISHER_NAME="$nom_legal" HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    HUGO_LEGAL_HOST_NAME="$hote_legal" \
    bash "$root/scripts/checks/output-patterns.sh"
}

# --- niveau -----------------------------------------------------------------------------------------

case_output_patterns_site_conforme() {
  site
  c22
  assert_eq 0 "$rc" "un rendu sans motif hors des valeurs légales passe (messages : $err)"
  assert_contains "confrontés à la liste des motifs" "$out" "le contrôle dit ce qu'il a lu"
}

case_output_patterns_hors_release_saute_en_le_disant() {
  # Les deux niveaux sur **la même sortie fautive** : « standard » passe, « release » échoue. Un
  # « exit 0 » muet cacherait un nom de variable mal écrit (modèle de C15).
  site
  page index.html "<h1>Accueil</h1><p>$motif</p>"
  c22 standard
  assert_eq 0 "$rc" "hors release, le contrôle ne juge rien (messages : $err)"
  assert_contains "contrôle de mise en ligne sauté" "$out" "il dit qu'il est sauté, il ne se tait pas"
  assert_contains "standard" "$out" "et il nomme le niveau qu'il a lu"
  c22
  assert_eq 1 "$rc" "au niveau release, la même sortie échoue"
}

case_output_patterns_niveau_absent_vaut_standard() {
  site
  page index.html "<h1>Accueil</h1><p>$motif</p>"
  run env -u CHECK_LEVEL CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 0 "$rc" "sans niveau, le contrôle est sauté (messages : $err)"
  assert_contains "contrôle de mise en ligne sauté" "$out" "et il le dit"
}

# --- ce que le contrôle doit voir ---------------------------------------------------------------------

case_output_patterns_motif_dans_une_page() {
  # Le premier critère d'acceptation : C22 échoue en nommant la page, sans recopier le motif.
  site
  page index.html "<h1>Accueil</h1><p>$motif</p>"
  c22
  assert_eq 1 "$rc" "un motif dans une page fait échouer le contrôle"
  assert_contains "index.html" "$err" "la page fautive est nommée"
  assert_contains "motif ligne 3" "$err" "le motif est cité par son numéro de ligne dans la liste"
}

case_output_patterns_le_message_naffiche_jamais_le_motif() {
  # La garantie qui compte : le journal d'une CI publique se lit.
  site
  page index.html "<h1>Accueil</h1><p>$motif</p>"
  c22
  assert_eq 1 "$rc" "l écart est bien constaté"
  [[ $err != *"$motif"* ]] || { echo "le motif apparaît dans les messages" >&2; exit 1; }
  [[ $out != *"$motif"* ]] || { echo "le motif apparaît sur la sortie standard" >&2; exit 1; }
}

case_output_patterns_motif_dans_une_sortie_non_html() {
  # Énumérer les seules sorties qu'on imagine est la faute que la rétrospective de l'epic 7 a
  # nommée : le sitemap, le robots.txt et tout format à venir sont lus comme une page.
  site
  printf 'User-agent: *\n# %s\n' "$motif" > "$work/public/robots.txt"
  c22
  assert_eq 1 "$rc" "un motif dans robots.txt fait échouer le contrôle"
  assert_contains "robots.txt" "$err" "le fichier fautif est nommé"
}

case_output_patterns_motif_echappe_par_hugo_est_vu() {
  # **La faille que la revue de spec n'a pas vue.** Hugo rend une apostrophe « &#39; » et une
  # esperluette « &amp; » : sans décodage, le contrôle cherche la chaîne brute dans un HTML échappé,
  # ne trouve rien, et se déclare vert (huit tours de revue sur la PR n° 98).
  site
  local echappe
  echappe=$(printf '%s' "$motif_echappable" | sed -e 's/&/\&amp;/g' -e "s/'/\&#39;/g")
  page index.html "<h1>Accueil</h1><p>$echappe</p>"
  c22 release "$motif" "$motif_echappable"
  assert_eq 1 "$rc" "le motif échappé par Hugo est reconnu"
  assert_contains "index.html" "$err" "la page fautive est nommée"
}

case_output_patterns_motif_serialise_en_json_ld_est_vu() {
  # L'encodeur JSON de Go n'écrit pas d'entités HTML mais des séquences Unicode : « & » pour
  # l'esperluette, « ' » pour l'apostrophe. Une deuxième famille d'échappement, et celle qu'on
  # oublie est celle qui fuite.
  site
  local json_go
  json_go=$(printf '%s' "$motif_echappable" | sed -e 's/&/\\u0026/g' -e "s/'/\\\\u0027/g")
  page index.html '<h1>Accueil</h1>' \
    "<script type=\"application/ld+json\">{\"nom\":\"$json_go\"}</script>"
  c22 release "$motif" "$motif_echappable"
  assert_eq 1 "$rc" "le motif sérialisé par l encodeur de Go est reconnu"
  assert_contains "index.html" "$err" "la page fautive est nommée"
}

case_output_patterns_motif_a_apostrophe_typographique_est_vu() {
  # **La seule entité que la vraie sortie de production émet**, et celle que le décodeur ne
  # connaissait pas : Hugo convertit l'apostrophe droite du Markdown en apostrophe typographique, et
  # le minifieur l'écrit « &rsquo; » — 236 fois dans public/ au 25/09/2026. Un motif portant cette
  # apostrophe n'était donc vu dans aucune page. Mesuré sur le vrai build, pas déduit.
  site
  page index.html "<h1>Accueil</h1><p>aujourd&rsquo;hui</p>"
  c22 release "aujourd’hui"
  assert_eq 1 "$rc" "un motif à apostrophe typographique est vu là où la page écrit « &rsquo; »"
  assert_contains "index.html" "$err" "la page fautive est nommée"
}

case_output_patterns_motif_coupe_par_un_crlf_est_vu() {
  # Même faute que le cas ci-dessus, une écriture plus loin : un fichier copié tel quel depuis un
  # poste Windows porte des fins de ligne « \r\n ». Le filtre ne ramenait que « \n » et « \t » à
  # une espace, si bien que « \r » survivait et que « Ville\r Cedex » ne correspondait plus à
  # « Ville Cedex ». Mesuré avant le correctif : **code 0 en CRLF, code 1 en LF**, même contenu et
  # même motif — un garde-fou vert sur une fuite (revue du code de la PR n° 117).
  #
  # Le fichier est écrit sous « static/ » plutôt qu'en page : Hugo ne produit pas de CRLF, mais il
  # copie sans les toucher les fichiers qu'on lui donne, et le dépôt porte déjà des artefacts
  # Windows (« *:Zone.Identifier » dans docs/private/context/).
  site
  printf 'adresse : Villefactice-sur-Essai\r\nCedex fin\r\n' > "$work/public/note-windows.txt"
  c22 release "Villefactice-sur-Essai Cedex"
  assert_eq 1 "$rc" "un motif coupé par un CRLF est vu comme celui coupé par un LF"
  assert_contains "note-windows.txt" "$err" "le fichier fautif est nommé"
}

case_output_patterns_motif_coupe_par_un_saut_de_ligne_est_vu() {
  # **Pourquoi un grep ligne à ligne reste sûr ici.** « pdf_confront » cherche avec grep, qui ne
  # verrait jamais une chaîne à cheval sur deux lignes ; c'est la normalisation qui ramène le
  # fichier entier à une seule ligne avant la recherche. Ce cas écrit le motif coupé là où le
  # minifieur l'aurait recollé : sans « normaliser_blancs », il échappe au contrôle.
  site
  local coupe=${motif_espace// /$'\n'}
  page index.html "<h1>Accueil</h1><p>$coupe</p>"
  c22 release "$motif_espace"
  assert_eq 1 "$rc" "un motif coupé par un saut de ligne est tout de même reconnu"
  assert_contains "index.html" "$err" "la page fautive est nommée"
}

# --- l'exception des mentions légales -----------------------------------------------------------------

case_output_patterns_page_legale_valeur_injectee_passe() {
  # Le second critère, première moitié : le motif y apparaît **contenu dans** une valeur injectée.
  # Le site conforme porte déjà l'adresse, qui contient le motif, sur les deux pages légales.
  site
  c22
  assert_eq 0 "$rc" "une occurrence contenue dans une valeur légale passe (messages : $err)"
}

case_output_patterns_page_legale_motif_hors_valeur_echoue() {
  # Le second critère, seconde moitié : **la même chaîne**, écrite hors des valeurs injectées, sur
  # la même page. C'est la lecture « expurger les occurrences » ; la lecture naïve — dispenser le
  # motif parce qu'il est sous-chaîne d'une valeur — laisserait passer cette fuite sans un mot.
  site
  page mentions-legales/index.html \
    "<h1>Mentions légales</h1><address>$nom_legal, $adresse_legale</address><p>J'habite $motif.</p>"
  c22
  assert_eq 1 "$rc" "la même chaîne écrite hors des valeurs injectées fait échouer"
  assert_contains "mentions-legales/index.html" "$err" "la page fautive est nommée"
  assert_contains "hors des valeurs légales injectées" "$err" "et le signalement dit pourquoi"
}

case_output_patterns_valeur_legale_sur_une_autre_page_echoue() {
  # L'exception est attachée aux **deux pages**, pas aux valeurs : l'adresse recopiée sur l'accueil
  # y porte le motif, et rien ne l'y dispense.
  site
  page index.html "<h1>Accueil</h1><address>$adresse_legale</address>"
  c22
  assert_eq 1 "$rc" "une valeur légale hors des pages légales ne dispense rien"
  assert_contains "index.html" "$err" "la page fautive est nommée"
  assert_contains "dans la sortie de production" "$err" "et le signalement n'est pas celui d'une page légale"
}

case_output_patterns_valeur_legale_echappee_est_expurgee() {
  # **L'expurgation porte sur le texte décodé.** Sur la vraie page, l'adresse est échappée par Hugo ;
  # si le contrôle la cherchait sous sa forme brute dans un HTML échappé, il ne la retrouverait pas,
  # ne l'expurgerait pas, et une mise en ligne parfaitement propre échouerait sur sa propre adresse.
  site
  local echappee
  echappee=$(printf '%s' "$adresse_legale" | sed -e 's/&/\&amp;/g' -e "s/'/\&#39;/g")
  page mentions-legales/index.html "<h1>Mentions légales</h1><address>$echappee</address>"
  c22
  assert_eq 0 "$rc" "l adresse échappée est reconnue puis expurgée (messages : $err)"
}

case_output_patterns_valeur_legale_minifiee_est_expurgee() {
  # Une adresse écrite sur deux lignes dans la valeur injectée arrive sur une seule dans le rendu
  # minifié. Les deux côtés sont normalisés, sans quoi la valeur ne se reconnaîtrait pas elle-même.
  local multi="1 rue de l'Essai"$'\n'"00000 $motif"
  site
  page mentions-legales/index.html "<h1>Mentions légales</h1><address>1 rue de l'Essai 00000 $motif</address>"
  page en/legal-notice/index.html "<h1>Legal notice</h1><address>1 rue de l'Essai 00000 $motif</address>"
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$multi" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 0 "$rc" "une valeur écrite sur deux lignes est expurgée d une page minifiée (messages : $err)"
}

case_output_patterns_une_valeur_courte_ne_decoupe_pas_une_longue() {
  # **L'ordre d'expurgation.** « HUGO_LEGAL_HOST_NAME » vaut ici « 1 rue de l'Essai », contenu dans
  # l'adresse. Expurgé le premier, il découpe l'adresse, que la valeur complète ne reconnaît plus —
  # et la commune ressort, faisant échouer une mise en ligne propre. Le tri par longueur
  # décroissante ferme le piège ; sans lui, ce cas échoue.
  site
  c22
  assert_eq 0 "$rc" "une valeur contenue dans une autre ne la découpe pas (messages : $err)"
}

# --- le périmètre : ce qu'un autre contrôle couvre ------------------------------------------------------

case_output_patterns_les_images_ne_sont_pas_lues() {
  # C20 garde les images : il y refuse tout EXIF, tout XMP et tout conteneur étendu, si bien qu'une
  # image publiée ne peut porter aucune métadonnée textuelle. Les lire ici ne rendrait que du bruit.
  site
  mkdir -p "$work/public/images"
  printf 'octets factices %s\n' "$motif" > "$work/public/images/photo.webp"
  c22
  assert_eq 0 "$rc" "une image n est pas confrontée (messages : $err)"
}

case_output_patterns_une_extension_en_majuscules_est_une_image() {
  site
  mkdir -p "$work/public/images"
  printf 'octets factices %s\n' "$motif" > "$work/public/images/PHOTO.PNG"
  c22
  assert_eq 0 "$rc" "la casse de l extension ne change pas le périmètre (messages : $err)"
}

case_output_patterns_un_fichier_sans_extension_est_lu() {
  # « ${base##*.} » rend le nom entier quand il ne porte aucun point : sans garde, un fichier nommé
  # « webp » passerait pour une image et sortirait du contrôle.
  site
  printf 'un fichier sans extension : %s\n' "$motif" > "$work/public/webp"
  c22
  assert_eq 1 "$rc" "un fichier nommé comme une extension est lu, pas écarté"
  assert_contains "webp" "$err" "le fichier fautif est nommé"
}

case_output_patterns_les_cv_publies_ne_sont_pas_lus() {
  # C21 confronte le texte, les métadonnées et le XMP des deux CV à la même liste.
  site
  mkdir -p "$work/public/cv"
  printf '%%PDF-1.4 %s\n' "$motif" > "$work/public/cv/cv-fr.pdf"
  printf '%%PDF-1.4 %s\n' "$motif" > "$work/public/cv/cv-en.pdf"
  c22
  assert_eq 0 "$rc" "les deux CV publiés relèvent de C21 (messages : $err)"
}

case_output_patterns_un_autre_pdf_est_lu() {
  # L'exclusion s'arrête là où s'arrête C21 : les **deux noms** qu'AD-21 connaît. Écarter « tout ce
  # qui est un PDF » aurait ouvert le trou que C22 existe pour fermer.
  site
  mkdir -p "$work/public/cv"
  printf '%%PDF-1.4 %s\n' "$motif" > "$work/public/cv/cv-ancien.pdf"
  c22
  assert_eq 1 "$rc" "un PDF que C21 ne regarde pas est confronté"
  assert_contains "cv-ancien.pdf" "$err" "le fichier fautif est nommé"
}

# --- anomalies : ce qui empêche de juger -----------------------------------------------------------

case_output_patterns_liste_absente_est_une_anomalie() {
  # **La différence assumée avec C21.** Pour C21, une liste absente laisse jouer les autres règles et
  # il le dit ; pour C22, la liste **est** le contrôle. Une mise en ligne ne se valide pas sur un
  # garde-fou qui n'a rien lu.
  site
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    PRIVATE_PATTERNS_FILE="$work/liste-absente.txt" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 2 "$rc" "une liste absente est une anomalie, jamais un succès"
  assert_contains "n'a rien lu" "$err" "et le message dit pourquoi"
}

case_output_patterns_liste_sans_motif_est_une_anomalie() {
  # Un fichier **présent mais vide** n'est pas une conformité : le piège est consigné depuis la
  # story 0.8, et ici il désactiverait le contrôle entier.
  site
  printf '# que des commentaires\n\n#\n' > "$work/motifs-sans-motif.txt"
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    PRIVATE_PATTERNS_FILE="$work/motifs-sans-motif.txt" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 2 "$rc" "une liste sans aucun motif est une anomalie"
  assert_contains "passerait pour vert" "$err" "et le message dit pourquoi"
}

case_output_patterns_valeurs_legales_absentes_est_une_anomalie() {
  # Même règle que C23 : un contrôle qui ne peut pas appliquer l'exception d'AD-9 ne peut pas juger
  # les deux pages légales. Toute variable « HUGO_LEGAL_* » est retirée, quel que soit
  # l'environnement où la suite tourne (piège connu : un cas qui suppose son environnement).
  site
  local nom retires=()
  while IFS= read -r nom; do
    [[ $nom == HUGO_LEGAL_* ]] || continue
    retires+=(-u "$nom")
  done <<< "$(compgen -v)"
  run env ${retires[@]+"${retires[@]}"} CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" \
    CHECK_WORK_ROOT="$work/rendu" PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 2 "$rc" "sans valeur légale, le contrôle rend une anomalie et non un succès"
  assert_contains "aucune valeur HUGO_LEGAL_" "$err" "et il dit pourquoi"
}

case_output_patterns_sans_build_de_production() {
  site
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/absent" CHECK_WORK_ROOT="$work/rendu" \
    PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 2 "$rc" "une production absente est une anomalie, pas un écart"
  assert_contains "scripts/build.sh production" "$err" "le message dit quoi lancer"
}

case_output_patterns_sortie_vide_est_une_anomalie() {
  # Une racine erronée ou un build vide ne feraient trouver aucun motif et passeraient pour une
  # conformité (rétrospective de l'epic 3).
  site
  rm -rf "$work/public"
  mkdir -p "$work/public"
  c22
  assert_eq 2 "$rc" "un rendu sans aucun fichier est une anomalie"
  assert_contains "le rendu est vide" "$err" "et il dit pourquoi"
}

case_output_patterns_sortie_tout_exclue_est_une_anomalie() {
  # La contre-épreuve de la précédente : une sortie qui n'a que des images et les deux CV n'est pas
  # un site. Sans cette garde, le contrôle rendrait 0 sans avoir rien confronté.
  site
  rm -rf "$work/public"
  mkdir -p "$work/public/images" "$work/public/cv"
  printf 'octets factices\n' > "$work/public/images/photo.webp"
  printf '%%PDF-1.4\n' > "$work/public/cv/cv-fr.pdf"
  c22
  assert_eq 2 "$rc" "une sortie entièrement couverte par d autres contrôles est une anomalie"
  assert_contains "aucun fichier lu" "$err" "et il dit pourquoi"
}

case_output_patterns_manifeste_sans_page_legale_est_une_anomalie() {
  # Sans page légale connue, l'exception ne s'applique nulle part : les valeurs légitimes des
  # mentions légales feraient échouer la mise en ligne. Le dire vaut mieux que le subir.
  site
  manifeste "$work/rendu/checks.json" fr ""
  manifeste "$work/rendu/en/checks.json" en ""
  c22
  assert_eq 2 "$rc" "un manifeste sans page légale est une anomalie"
  assert_contains "legal-notice" "$err" "et le message nomme la clé cherchée"
}

case_output_patterns_manifeste_absent_est_une_anomalie() {
  site
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/sans-rendu" \
    PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 2 "$rc" "un rendu de travail absent est une anomalie"
  assert_contains "scripts/build.sh work" "$err" "le message dit quoi lancer"
}

case_output_patterns_fichier_illisible_est_une_anomalie() {
  # Un fichier lu dans un « if » aurait rendu une chaîne vide que le contrôle aurait lue comme
  # « aucun motif » : un fichier illisible serait sorti du contrôle en silence.
  skip_if_root "une page du rendu"
  site
  chmod 000 "$work/public/index.html"
  c22
  chmod 644 "$work/public/index.html"
  assert_eq 2 "$rc" "un fichier illisible est une anomalie, jamais « aucun motif »"
  assert_contains "rien n'est affirmé" "$err" "et le message le dit"
}

case_output_patterns_parcours_impossible_est_une_anomalie() {
  # Le code de « checks_find » est **propagé** : un dossier illisible sous la racine arrête le
  # contrôle au lieu de lui faire lire la liste tronquée que find a eu le temps d'écrire.
  skip_if_root "un dossier du rendu"
  site
  mkdir -p "$work/public/ferme"
  printf 'rien\n' > "$work/public/ferme/page.html"
  chmod 000 "$work/public/ferme"
  c22
  chmod 755 "$work/public/ferme"
  assert_eq 2 "$rc" "un parcours impossible est une anomalie, pas une liste tronquée"
  assert_contains "parcours impossible" "$err" "et le message le dit"
}

case_output_patterns_un_code_inattendu_nest_pas_un_fichier_propre() {
  # **Le contrôle ne doit jamais s'ouvrir en cas de panne.** Aucun cas d'intégration ne peut produire
  # un code autre que 0 ou 1 ; celui-ci le fabrique, en dégradant la bibliothèque dans un arbre
  # jetable (même technique que C21, revue de la PR n° 95).
  local arbre=$work/arbre
  rm -rf "$arbre"; mkdir -p "$arbre/scripts/checks" "$arbre/scripts/lib"
  cp "$root/scripts/checks/output-patterns.sh" "$root/scripts/checks/lib.sh" "$arbre/scripts/checks/"
  cp "$root"/scripts/lib/*.sh "$arbre/scripts/lib/"
  printf '\npdf_confront() { return 7; }\n' >> "$arbre/scripts/lib/pdf.sh"
  site
  run env CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" \
    PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$arbre/scripts/checks/output-patterns.sh"
  assert_eq 1 "$rc" "un code inattendu fait échouer le contrôle, il ne le laisse pas passer"
  assert_contains "recherche des motifs impossible" "$err" "et le message dit que la recherche a échoué"
  assert_contains "code 7" "$err" "en donnant le code, pour qu on puisse le chercher"
}

# --- les fichiers temporaires -------------------------------------------------------------------------

tmpdir_a_soi() {
  local tmp=$work/tmp-a-soi
  rm -rf "$tmp"; mkdir -p "$tmp"
  printf '%s' "$tmp"
}

restes_dans() { find "$1" -mindepth 1 | wc -l; }

case_output_patterns_aucun_temporaire_apres_un_succes() {
  site
  local tmp; tmp=$(tmpdir_a_soi)
  run env TMPDIR="$tmp" CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" \
    CHECK_WORK_ROOT="$work/rendu" PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 0 "$rc" "le contrôle va jusqu au bout, sans quoi zéro reste ne prouverait rien (messages : $err)"
  assert_eq 0 "$(restes_dans "$tmp")" "C22 ne laisse aucun fichier temporaire après un succès"
}

case_output_patterns_aucun_temporaire_apres_un_ecart() {
  # La variable qui porte le chemin d'un temporaire n'est jamais celle qui dit « la liste est-elle
  # vide » : les confondre laissait deux fichiers par exécution (constat B1, epic 7).
  site
  page index.html "<h1>Accueil</h1><p>$motif</p>"
  local tmp; tmp=$(tmpdir_a_soi)
  run env TMPDIR="$tmp" CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" \
    CHECK_WORK_ROOT="$work/rendu" PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 1 "$rc" "l écart est bien constaté"
  assert_eq 0 "$(restes_dans "$tmp")" "C22 ne laisse aucun fichier temporaire après un écart"
}

case_output_patterns_aucun_temporaire_apres_une_anomalie() {
  # Le chemin où les deux temporaires existent déjà et où le contrôle s'arrête par « checks_die » :
  # le « trap … EXIT » doit les emporter aussi.
  site
  manifeste "$work/rendu/checks.json" fr ""
  manifeste "$work/rendu/en/checks.json" en ""
  local tmp; tmp=$(tmpdir_a_soi)
  run env TMPDIR="$tmp" CHECK_LEVEL=release CHECK_PUBLIC_ROOT="$work/public" \
    CHECK_WORK_ROOT="$work/rendu" PRIVATE_PATTERNS_FILE="$(liste_motifs "$motif")" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse_legale" \
    bash "$root/scripts/checks/output-patterns.sh"
  assert_eq 2 "$rc" "l anomalie est bien constatée"
  assert_eq 0 "$(restes_dans "$tmp")" "C22 ne laisse aucun fichier temporaire après une anomalie"
}

# --- plusieurs motifs, plusieurs fichiers ---------------------------------------------------------------

case_output_patterns_chaque_fichier_fautif_est_nomme() {
  # Tous les écarts s'affichent : un contrôle nomme chaque fichier, jamais le seul premier.
  site
  page index.html "<h1>Accueil</h1><p>$motif</p>"
  page en/index.html "<h1>Home</h1><p>$motif_deux</p>"
  c22 release "$motif" "$motif_deux"
  assert_eq 1 "$rc" "deux pages fautives font échouer le contrôle"
  assert_contains "index.html" "$err" "la première page est nommée"
  assert_contains "en/index.html" "$err" "la seconde aussi"
}
run_case "$@"
