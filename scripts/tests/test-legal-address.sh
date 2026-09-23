#!/usr/bin/env bash
# C23 (story 9.1, AD-9) : l'adresse de l'éditeur reste confinée au corps des deux pages des
# mentions légales. Les cas montent un petit rendu dans $work, comme test-links.sh.
#
# **L'adresse d'essai est fabriquée ici**, et n'a rien à voir avec une vraie : le contrôle cherche
# la valeur de HUGO_LEGAL_PUBLISHER_ADDRESS, quelle qu'elle soit, et les cas la lui donnent. Aucune
# donnée réelle n'entre dans un test, et la vraie valeur ne vit que dans .env, hors du dépôt.
#
# Chaque cas éprouve une **place** où l'adresse ne doit pas être. Ils ont tous été lancés une fois
# contre un contrôle qui ne regardait pas cette place : ils échouent, sans quoi ils ne prouveraient
# rien (point 9 d'AGENTS.md).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# L'adresse d'essai porte **trois familles de caractères**, et chacune éprouve une faute possible :
#
#   - un point, un tiret et des parenthèses : si le contrôle cherchait par expression régulière au
#     lieu de chaîne littérale, le point filtrerait n'importe quel caractère et les parenthèses
#     ouvriraient un groupe. « grep -F » est la seule forme correcte ;
#   - une **apostrophe et une esperluette**, que Hugo échappe en « &#39; » et « &amp; ». Une
#     première écriture n'en avait aucune, et masquait une faille réelle : le contrôle cherchait la
#     chaîne brute dans un HTML échappé, ne trouvait rien, et se déclarait vert. C'est la règle 15
#     d'AGENTS.md — un contrôle écrit par l'auteur du code hérite de son angle mort, et la fixture
#     avec lui (constat bloquant de la revue de la PR n° 98).
readonly adresse="12 rue de l'Église-Test & Cie, 00000 VILLEFACTICE (S.A.R.L.)"

controle() {
  run env CHECK_PUBLIC_ROOT="$work/public" HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse" \
    bash "$root/scripts/checks/legal-address.sh"
}

page() { # $1 = chemin relatif, $2 = contenu de <head> en plus, $3 = body, $4 = titre
  mkdir -p "$(dirname "$work/public/$1")"
  printf '<!doctype html><html lang=fr><head><meta charset=utf-8><title>%s</title>%s</head><body>%s</body></html>' \
    "${4:-$1}" "${2:-}" "${3:-<h1>Page</h1>}" > "$work/public/$1"
}

# La page est **réécrite**, jamais retouchée par « sed » : dans un remplacement sed, « & » désigne
# toute la correspondance, et l'adresse d'essai en contient une. Une première écriture injectait le
# titre par sed et posait donc autre chose que ce qu'elle croyait — le cas échouait sans que le
# contrôle soit en cause (piège connu, docs/procedures/shell-scripts.md).

# Un rendu conforme : l'adresse est dans le corps des deux pages légales, et nulle part ailleurs.
site() {
  rm -rf "$work/public"
  mkdir -p "$work/public"
  page index.html "" '<h1>Accueil</h1>'
  page en/index.html "" '<h1>Home</h1>'
  page mentions-legales/index.html "" "<h1>Mentions légales</h1><address>$adresse</address>"
  page en/legal-notice/index.html "" "<h1>Legal notice</h1><address>$adresse</address>"
  printf '<?xml version="1.0" encoding="utf-8"?><urlset><url><loc>https://exemple.invalide/</loc></url></urlset>' \
    > "$work/public/sitemap.xml"
  printf 'User-agent: *\nAllow: /\n' > "$work/public/robots.txt"
}

case_legal_rendu_conforme() {
  site
  controle
  assert_eq 0 "$rc" "l adresse dans le corps des deux pages légales passe (messages : $err)"
  assert_contains "ne sort pas du corps" "$out" "le contrôle le dit"
}

case_legal_adresse_sur_une_autre_page() {
  site
  page index.html "" "<h1>Accueil</h1><p>$adresse</p>"
  controle
  assert_eq 1 "$rc" "l adresse sur l accueil fait échouer"
  assert_contains "index.html" "$err" "la page fautive est nommée"
  assert_contains "qui n'est pas les mentions légales" "$err" "le signalement dit pourquoi"
}

case_legal_adresse_dans_le_titre() {
  # La place que le partial ne peut pas garder : sur la page légale, il ne sait pas d'où on
  # l'appelle. C'est la moitié qu'AD-9 confie à ce contrôle.
  site
  page mentions-legales/index.html "" "<h1>Mentions légales</h1><address>$adresse</address>" "$adresse"
  controle
  assert_eq 1 "$rc" "l adresse dans le <title> d une page légale fait échouer"
  assert_contains "dans le <title>" "$err" "le signalement nomme l endroit"
}

case_legal_adresse_dans_la_meta_description() {
  site
  page en/legal-notice/index.html "<meta name=\"description\" content=\"$adresse\">" \
    "<h1>Legal notice</h1><address>$adresse</address>"
  controle
  assert_eq 1 "$rc" "l adresse dans la meta description fait échouer"
  assert_contains "balise meta" "$err" "le signalement nomme l endroit"
}

case_legal_adresse_dans_le_json_ld() {
  # **La fixture sérialise comme Hugo le fait vraiment.** L'encodeur JSON de Go n'écrit pas
  # d'entités HTML mais des séquences Unicode : « \u0026 » pour l'esperluette, « \u003c » et
  # « \u003e » pour les chevrons — mesuré sur un build. Une première écriture injectait l'adresse
  # brute dans le JSON et masquait donc une fuite réelle : le contrôle ne décodait que les
  # entités, et une adresse portant un « & » serait passée (constat de la revue de la PR n° 98,
  # règle 16 d'AGENTS.md).
  site
  local json_go
  json_go=$(printf '%s' "$adresse" | sed -e 's/&/\\u0026/g' -e 's/</\\u003c/g' -e 's/>/\\u003e/g')
  page mentions-legales/index.html \
    "<script type=\"application/ld+json\">{\"address\":\"$json_go\"}</script>" \
    "<h1>Mentions légales</h1><address>$adresse</address>"
  controle
  assert_eq 1 "$rc" "l adresse sérialisée par l encodeur de Go est vue dans le JSON-LD"
  assert_contains "JSON-LD" "$err" "le signalement nomme l endroit"
}

case_legal_adresse_dans_le_sitemap() {
  site
  printf '<?xml version="1.0" encoding="utf-8"?><urlset><url><loc>%s</loc></url></urlset>' "$adresse" \
    > "$work/public/sitemap.xml"
  controle
  assert_eq 1 "$rc" "l adresse dans le sitemap fait échouer"
  assert_contains "sitemap.xml" "$err" "le fichier fautif est nommé"
}

case_legal_adresse_dans_une_sortie_quelconque() {
  # Le sitemap est la sortie qu'AD-9 nomme, mais borner la recherche à ce qu'on imagine est la
  # faute que la rétrospective de l'epic 7 a nommée. Toute sortie texte est lue.
  site
  printf 'User-agent: *\n# %s\n' "$adresse" > "$work/public/robots.txt"
  controle
  assert_eq 1 "$rc" "l adresse dans robots.txt fait échouer"
  assert_contains "robots.txt" "$err" "le fichier fautif est nommé"
}

case_legal_adresse_echappee_par_hugo_est_vue() {
  # **La faille que la revue a trouvée.** Hugo rend une apostrophe « &#39; » et une esperluette
  # « &amp; » : le contrôle doit reconnaître l'adresse sous cette forme aussi, sans quoi il laisse
  # fuiter la commune de l'éditeur en se déclarant vert.
  site
  local echappee
  echappee=$(printf '%s' "$adresse" | sed -e 's/&/\&amp;/g' -e "s/'/\&#39;/g")
  page index.html "" "<h1>Accueil</h1><p>$echappee</p>"
  controle
  assert_eq 1 "$rc" "l adresse échappée par Hugo est vue comme l adresse"
  assert_contains "qui n'est pas les mentions légales" "$err" "et signalée pour la bonne raison"
}

case_legal_adresse_echappee_dans_le_titre() {
  # Même faille, à l'endroit qui compte le plus : le titre nourrit les moteurs et les partages.
  site
  local echappee
  echappee=$(printf '%s' "$adresse" | sed -e 's/&/\&amp;/g' -e "s/'/\&#39;/g")
  page mentions-legales/index.html "" "<h1>Mentions légales</h1><address>$adresse</address>" "$echappee"
  controle
  assert_eq 1 "$rc" "l adresse échappée dans le <title> est vue"
  assert_contains "dans le <title>" "$err" "le signalement nomme l endroit"
}

case_legal_sans_loutil_file_le_fichier_est_lu_quand_meme() {
  # Si « file » manque, le contrôle doit **lire** le fichier plutôt que le sauter : l'échec d'un
  # outil ne doit pas sortir un fichier du contrôle en silence. Sans ce cas, la garde serait
  # indétectable — « file » réussit toujours sur le poste et dans CHECK_IMAGE (constat de la revue
  # de la PR n° 98).
  site
  printf 'User-agent: *\n# %s\n' "$adresse" > "$work/public/robots.txt"
  # Un PATH réduit à un dossier vide : ni « file », ni rien d'autre. Les outils dont le contrôle a
  # besoin sont appelés par chemin absolu ou sont des primitives du shell.
  mkdir -p "$work/sans-outils"
  run env PATH="$work/sans-outils:/usr/bin:/bin" CHECK_PUBLIC_ROOT="$work/public" \
    HUGO_LEGAL_PUBLISHER_ADDRESS="$adresse" \
    bash -c 'file() { return 127; }; export -f file; bash "$0"' "$root/scripts/checks/legal-address.sh"
  assert_eq 1 "$rc" "sans « file », l adresse dans robots.txt est tout de même vue"
  assert_contains "robots.txt" "$err" "le fichier fautif est nommé"
}

# Une adresse postale tient souvent sur deux lignes. Le constat de la revue de la PR n° 98 visait
# juste en concluant qu'il fallait la comparaison native de bash, mais **son mécanisme était
# faux** : « grep -F » avec un motif contenant un saut de ligne ne rate pas l'adresse, il découpe
# le motif en autant d'alternatives. Le risque n'était donc pas un faux négatif silencieux, mais
# un faux **positif** — une page ne portant qu'une ligne de l'adresse aurait été signalée comme
# portant l'adresse. Constaté en essayant de faire échouer le cas avec grep, et en n'y arrivant pas.
#
# Les deux cas ci-dessous distinguent les deux implémentations : le premier vérifie que l'adresse
# entière est vue, le second qu'une ligne seule ne suffit pas. C'est ce second que grep échouait.
multi_lignes() { printf "12 rue de l'Église-Test\n00000 VILLEFACTICE"; }

controle_multi() { # $1 = contenu du corps de l'accueil
  local multi; multi=$(multi_lignes)
  rm -rf "$work/public"; mkdir -p "$work/public"
  page index.html "" "$1"
  page mentions-legales/index.html "" "<h1>Mentions</h1><address>$multi</address>"
  page en/legal-notice/index.html "" "<h1>Legal</h1><address>$multi</address>"
  run env CHECK_PUBLIC_ROOT="$work/public" HUGO_LEGAL_PUBLISHER_ADDRESS="$multi" \
    bash "$root/scripts/checks/legal-address.sh"
}

case_legal_adresse_sur_plusieurs_lignes() {
  controle_multi "<h1>Accueil</h1><p>$(multi_lignes)</p>"
  assert_eq 1 "$rc" "une adresse sur deux lignes est vue entière hors des pages légales"
  assert_contains "index.html" "$err" "la page fautive est nommée"
}

case_legal_une_seule_ligne_de_ladresse_ne_suffit_pas() {
  # Ce que C23 garde, c'est **l'adresse**. Une commune seule relève de la liste des motifs
  # interdits et de C22 sur la sortie de production, qui sont faits pour elle : signaler ici sur
  # une ligne isolée rendrait le contrôle bruyant sans rien garder de plus.
  controle_multi '<h1>Accueil</h1><p>00000 VILLEFACTICE</p>'
  assert_eq 0 "$rc" "une ligne seule de l adresse ne déclenche pas C23 (messages : $err)"
}

case_legal_adresse_minifiee_sur_une_seule_ligne() {
  # Le rendu de production est **minifié** : une adresse écrite sur deux lignes y arrive sur une
  # seule. Comparer à la chaîne d'origine, sauts de ligne compris, ne trouvait rien — le contrôle
  # passait au vert (constat de la revue de la PR n° 98). Les fixtures écrites par « printf » sans
  # passer par Hugo ne pouvaient pas le montrer : celle-ci écrase les blancs elle-même.
  local multi aplatie
  multi=$(multi_lignes)
  aplatie=$(printf '%s' "$multi" | tr '\n' ' ')
  rm -rf "$work/public"; mkdir -p "$work/public"
  page index.html "" "<h1>Accueil</h1><p>$aplatie</p>"
  page mentions-legales/index.html "" "<h1>Mentions</h1><address>$multi</address>"
  page en/legal-notice/index.html "" "<h1>Legal</h1><address>$multi</address>"
  run env CHECK_PUBLIC_ROOT="$work/public" HUGO_LEGAL_PUBLISHER_ADDRESS="$multi" \
    bash "$root/scripts/checks/legal-address.sh"
  assert_eq 1 "$rc" "l adresse aplatie par la minification est vue"
  assert_contains "index.html" "$err" "la page fautive est nommée"
}

case_legal_adresse_dans_une_meta_sociale() {
  # « og:description » et « twitter:description » nourrissent les aperçus de partage. Ne viser que
  # « description » laissait fuiter l'adresse par elles, en silence.
  site
  page mentions-legales/index.html \
    "<meta property=\"og:description\" content=\"$adresse\">" \
    "<h1>Mentions légales</h1><address>$adresse</address>"
  controle
  assert_eq 1 "$rc" "l adresse dans une meta OpenGraph est vue"
  assert_contains "balise meta" "$err" "le signalement nomme l endroit"
}

case_legal_adresse_multilignes_dans_le_json_ld() {
  # La sixième sérialisation de la même chaîne : dans un JSON-LD, un saut de ligne s'écrit « \n »,
  # deux caractères littéraux. Le cas voisin ne le montrait pas, son adresse tenant sur une ligne
  # (constat de la revue de la PR n° 98, huitième tour).
  local multi json_go
  multi=$(multi_lignes)
  json_go=$(printf '%s' "$multi" | sed -e 's/&/\\u0026/g' | awk 'NR>1{printf "\\n"} {printf "%s", $0}')
  rm -rf "$work/public"; mkdir -p "$work/public"
  page index.html "" '<h1>Accueil</h1>'
  page en/legal-notice/index.html "" "<h1>Legal</h1><address>$multi</address>"
  page mentions-legales/index.html \
    "<script type=\"application/ld+json\">{\"address\":\"$json_go\"}</script>" \
    "<h1>Mentions</h1><address>$multi</address>"
  run env CHECK_PUBLIC_ROOT="$work/public" HUGO_LEGAL_PUBLISHER_ADDRESS="$multi" \
    bash "$root/scripts/checks/legal-address.sh"
  assert_eq 1 "$rc" "l adresse multi-lignes sérialisée en JSON est vue"
  assert_contains "JSON-LD" "$err" "le signalement nomme l endroit"
}

case_legal_le_message_naffiche_jamais_l_adresse() {
  # La garantie qui compte : le journal d'une CI publique se lit.
  site
  page index.html "" "<h1>Accueil</h1><p>$adresse</p>"
  controle
  assert_eq 1 "$rc" "l écart est bien constaté"
  [[ $err != *"$adresse"* ]] || { echo "l adresse apparaît dans les messages" >&2; exit 1; }
  [[ $out != *"$adresse"* ]] || { echo "l adresse apparaît sur la sortie standard" >&2; exit 1; }
}

case_legal_valeur_absente_est_une_anomalie() {
  # **Jamais un succès.** Un contrôle qui cherche une chaîne vide ne se déclenche jamais et passe
  # pour vert : c'est la faute que sept gardes de ce projet ont commise, et celle que la revue de
  # spec de cette story a vue venir.
  site
  run env CHECK_PUBLIC_ROOT="$work/public" HUGO_LEGAL_PUBLISHER_ADDRESS="" \
    bash "$root/scripts/checks/legal-address.sh"
  assert_eq 2 "$rc" "sans la valeur, le contrôle rend une anomalie et non un succès"
  assert_contains "chercherait une chaîne vide" "$err" "et il dit pourquoi"
}

case_legal_rendu_vide_est_une_anomalie() {
  # Un rendu sans page ferait passer le contrôle sans rien lire : une liste vide est une anomalie,
  # règle du point 14 de la rétrospective de l'epic 3.
  rm -rf "$work/public"
  mkdir -p "$work/public"
  controle
  assert_eq 2 "$rc" "un rendu sans page est une anomalie"
  assert_contains "aucune page HTML" "$err" "et il dit pourquoi"
}

case_legal_l_adresse_est_cherchee_litteralement() {
  # L'adresse est une **chaîne**, pas une expression régulière. Lue comme une regex étendue, ses
  # points filtreraient n'importe quel caractère et ses parenthèses deviendraient un groupe — si
  # bien qu'un texte que personne n'a écrit serait signalé comme étant l'adresse de l'éditeur.
  #
  # La chaîne voisine ci-dessous est construite pour ne différer **que là où les métacaractères
  # agissent** : chaque « . » de « S.A.R.L. » y est un « x », et les parenthèses ont disparu,
  # comme un groupe ERE les ferait disparaître. Le tiret de « Test-Factice » est gardé tel quel.
  # Un premier jet remplaçait aussi le tiret : la chaîne ne correspondait alors dans aucun des
  # deux modes, et le cas passait au vert même avec « grep -E » — il ne prouvait rien. Constaté en
  # dégradant le contrôle, pas en le relisant.
  site
  page index.html "" "<h1>Accueil</h1><p>12 rue de l'Église-Test &amp; Cie, 00000 VILLEFACTICE SxAxRxLx</p>"
  controle
  assert_eq 0 "$rc" "une chaîne que seule une regex ferait correspondre ne déclenche rien (messages : $err)"
}
run_case "$@"
