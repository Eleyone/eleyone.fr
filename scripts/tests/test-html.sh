#!/usr/bin/env bash
# C10 et la moitié « sortie » de C5 (story 3.8) : zéro JavaScript, aucune ressource tierce, aucun
# marqueur dans la production. Les cas travaillent sur une copie des fixtures HTML, transformée par
# « sed » : le HTML est minifié comme celui de la production, guillemets d'attributs compris.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# $1 = ce qui est inséré avant </body> de la page d'accueil ; $2 = même chose pour la page simple.
# Manifeste minimal : le contrôle y lit la ligne d'identité (AD-19), plutôt que de l'écrire en dur.
manifeste() {
  mkdir -p "$work/rendu"
  printf '{"lang":"fr","files":[{"file":"_index.fr.md","lang":"fr","role":"home","front_matter":{"identity":"Prénom Nom · Pseudo"}}]}\n' \
    > "$work/rendu/checks.json"
}

sortie() {
  rm -rf "$work/public"
  mkdir -p "$work/public"
  manifeste
  cp "$fixtures/html/index.html" "$fixtures/html/page.html" "$work/public/"
  [[ -z ${1:-} ]] || sed -i "s#</body>#${1}</body>#" "$work/public/index.html"
  [[ -z ${2:-} ]] || sed -i "s#</body>#${2}</body>#" "$work/public/page.html"
}

controle() {
  run env CHECK_PUBLIC_ROOT="$work/public" CHECK_WORK_ROOT="$work/rendu" CHECK_SITE_HOST=eleyone.fr \
    bash "$root/scripts/checks/html.sh"
}

case_html_production_conforme() {
  sortie
  controle
  assert_eq 0 "$rc" "une production conforme passe (messages : $err)"
  assert_contains "zéro script" "$out" "le contrôle le dit"
}

case_html_script_interdit() {
  sortie '<script>console.log(1)</script>'
  controle
  assert_eq 1 "$rc" "une balise script fait échouer"
  assert_contains "seul un bloc application/ld+json est toléré" "$err" "le signalement renvoie à AD-20"
}

case_html_script_avec_src() {
  sortie '<script type="application/ld+json" src=/app.js></script>'
  controle
  assert_eq 1 "$rc" "un script avec src fait échouer"
  assert_contains "C10 : balise <script src>" "$err" "le signalement le dit"
}

case_html_script_dun_autre_type() {
  sortie '<script type=module>export default 1</script>'
  controle
  assert_eq 1 "$rc" "un script de type module fait échouer"
  assert_contains "balise <script> de type «module»" "$err" "le signalement nomme le type"
}

case_html_attribut_evenement() {
  sortie '<p onclick=alerte()>Texte</p>'
  controle
  assert_eq 1 "$rc" "un attribut on… fait échouer"
  assert_contains "C10 : attribut on…" "$err" "le signalement le dit"
}

case_html_iframe_et_formulaire() {
  sortie '<iframe src=https://www.youtube.com/embed/x></iframe>'
  controle
  assert_eq 1 "$rc" "une iframe fait échouer"
  assert_contains "C10 : <iframe>" "$err" "le signalement renvoie à FR-14"
  sortie '<form action=/envoi><input name=a></form>'
  controle
  assert_eq 1 "$rc" "un formulaire fait échouer"
  assert_contains "C10 : <form>" "$err" "le signalement renvoie à FR-17"
}

case_html_ressource_tierce() {
  sortie '<img src=https://cdn.exemple.invalide/photo.webp alt=Photo width=10 height=10>'
  controle
  assert_eq 1 "$rc" "une image d'un autre site fait échouer"
  assert_contains "ressource d'une autre origine dans un attribut src" "$err" "le signalement nomme l'attribut"
  sortie '<link rel=stylesheet href=https://fonts.exemple.invalide/police.css>'
  controle
  assert_eq 1 "$rc" "une feuille de style d'un autre site fait échouer"
  assert_contains "ressource « stylesheet » chargée depuis une autre origine" "$err" "le signalement nomme la relation"
}

case_html_lien_vers_un_tiers_permis() {
  # Un lien ne charge rien : il reste permis, y compris vers un autre site (critère de la story).
  sortie '<p><a href=https://www.linkedin.com/in/exemple/>LinkedIn</a></p>'
  controle
  assert_eq 0 "$rc" "un lien vers un site tiers passe (messages : $err)"
}

case_html_hreflang_du_site_permis() {
  # Les hreflang d'AD-2 sont des URL absolues vers le site : ce ne sont pas des origines tierces,
  # et « alternate » ne charge rien (constaté sur la production réelle avant correction).
  sortie '<link rel=alternate hreflang=x-default href=https://eleyone.fr/>'
  controle
  assert_eq 0 "$rc" "un hreflang absolu vers le site passe (messages : $err)"
}

case_html_appel_css_tiers() {
  sortie '<style>body { background: url("https://cdn.exemple.invalide/fond.png"); }</style>'
  controle
  assert_eq 1 "$rc" "un appel CSS vers un autre site fait échouer"
  assert_contains "appel CSS vers une autre origine" "$err" "le signalement le dit"
  sortie '<style>body { background: url("https://eleyone.fr/fond.png"); }</style>'
  controle
  assert_eq 0 "$rc" "le même appel vers le site lui-même passe (messages : $err)"
}

case_html_marqueur_todo() {
  sortie '<p>[TODO: à écrire]</p>'
  controle
  assert_eq 1 "$rc" "un marqueur dans la production fait échouer"
  assert_contains "C5 : « [TODO » dans la sortie de production" "$err" "le signalement donne la ligne"
}

case_html_jsonld_hors_accueil() {
  sortie '' '<script type="application/ld+json">{"@type":"Person"}</script>'
  controle
  assert_eq 1 "$rc" "un bloc JSON-LD hors de l'accueil fait échouer"
  assert_contains "bloc JSON-LD hors de l'accueil" "$err" "le signalement renvoie à AD-20"
}

case_html_jsonld_en_double() {
  sortie '<script type="application/ld+json">{"@type":"Person"}</script>'
  controle
  assert_eq 1 "$rc" "deux blocs sur l'accueil font échouer"
  assert_contains "2 blocs JSON-LD ; au plus un" "$err" "le signalement compte les blocs"
}

case_html_jsonld_invalide_ou_hors_regles() {
  rm -rf "$work/public"; mkdir -p "$work/public"
  manifeste
  cp "$fixtures/html/page.html" "$work/public/"
  printf '<!doctype html><html lang=fr><head><title>A</title><script type="application/ld+json">{ pas du json }</script></head><body></body></html>' \
    > "$work/public/index.html"
  controle
  assert_eq 1 "$rc" "un bloc JSON-LD invalide fait échouer"
  assert_contains "n'est pas un JSON valide" "$err" "le signalement le dit"

  printf '<!doctype html><html lang=fr><head><title>A</title><script type="application/ld+json">{"@type":"Organization","name":"X"}</script></head><body></body></html>' \
    > "$work/public/index.html"
  controle
  assert_eq 1 "$rc" "un @type autre que Person fait échouer"
  assert_contains "@type « Organization » ; Person attendu" "$err" "le signalement donne le type"

  printf '<!doctype html><html lang=fr><head><title>A</title><script type="application/ld+json">{"@type":"Person","telephone":"x"}</script></head><body></body></html>' \
    > "$work/public/index.html"
  controle
  assert_eq 1 "$rc" "une clé hors FR-35 fait échouer"
  assert_contains 'clé « telephone » dans le bloc JSON-LD' "$err" "le signalement nomme la clé"
}

case_html_plusieurs_ressources_sur_une_page() {
  # Constat de la revue de la PR n° 43 : une ressource tierce précédée d'une ressource du site ne doit
  # pas passer, quelle que soit la façon dont libxml2 rend les attributs.
  sortie '<img src=https://eleyone.fr/1.webp alt=a width=10 height=10><img src=https://tiers.invalide/2.webp alt=b width=10 height=10>'
  controle
  assert_eq 1 "$rc" "la seconde image, tierce, est vue"
  assert_contains "tiers.invalide/2.webp" "$err" "le signalement nomme la bonne URL"
  [[ $err != *"eleyone.fr/1.webp"* ]] || { echo "l'image du site a été signalée à tort" >&2; exit 1; }
}

case_html_jsonld_valide_mais_pas_un_objet() {
  # Constat de la revue de la PR n° 43 : jq sortait en code 5 et tuait le contrôle.
  rm -rf "$work/public"; mkdir -p "$work/public"
  manifeste
  cp "$fixtures/html/page.html" "$work/public/"
  printf '<!doctype html><html lang=fr><head><title>A</title><script type="application/ld+json">[]</script></head><body></body></html>' \
    > "$work/public/index.html"
  controle
  assert_eq 1 "$rc" "un JSON valide qui n'est pas un objet est signalé, pas un plantage"
  assert_contains "n'est pas un objet JSON" "$err" "le signalement le dit"
  printf '<!doctype html><html lang=fr><head><title>A</title><script type="application/ld+json">"texte"</script></head><body></body></html>' \
    > "$work/public/index.html"
  controle
  assert_eq 1 "$rc" "une chaîne JSON non plus"
}

case_html_css_insensible_a_la_casse() {
  sortie '<style>body { background: URL("https://cdn.exemple.invalide/fond.png"); }</style>'
  controle
  assert_eq 1 "$rc" "URL( en majuscules ne contourne pas le contrôle"
  sortie '<style>@IMPORT "https://cdn.exemple.invalide/police.css";</style>'
  controle
  assert_eq 1 "$rc" "@IMPORT en majuscules non plus"
}

case_html_url_du_site_avec_requete() {
  # Sans découpe sur « ? », l'hôte valait « eleyone.fr?q=1 » et la ressource du site était refusée.
  sortie '<img src="https://eleyone.fr/photo.webp?v=2" alt=a width=10 height=10>'
  controle
  assert_eq 0 "$rc" "une URL du site suivie d'une requête passe (messages : $err)"
}

case_html_accueil_traduit() {
  # La regex des accueils traduits n'était couverte par aucun cas : le bloc JSON-LD y est permis.
  rm -rf "$work/public"; mkdir -p "$work/public/en"
  manifeste
  cp "$fixtures/html/index.html" "$work/public/"
  cp "$fixtures/html/index.html" "$work/public/en/"
  cp "$fixtures/html/page.html" "$work/public/"
  controle
  assert_eq 0 "$rc" "un bloc JSON-LD sur l'accueil anglais passe (messages : $err)"
  mkdir -p "$work/public/cas/chiliz"
  cp "$fixtures/html/index.html" "$work/public/cas/chiliz/"
  controle
  assert_eq 1 "$rc" "le même bloc dans l'index d'un sous-dossier est refusé"
  assert_contains "cas/chiliz/index.html" "$err" "le signalement nomme la page"
}

case_html_srcset_multiple() {
  # Constat de la troisième revue de la PR n° 43 : une URL tierce placée après une URL locale dans un
  # srcset échappait au contrôle, le prédicat XPath ne regardant que le début de l'attribut.
  sortie '<img src=/local.webp srcset="/local.webp 1x, https://tiers.invalide/ext.webp 2x" alt=a width=10 height=10>'
  controle
  assert_eq 1 "$rc" "une URL tierce au milieu d'un srcset est vue"
  assert_contains "attribut srcset : https://tiers.invalide/ext.webp" "$err" "le signalement nomme l'URL"
  sortie '<img src=/local.webp srcset="/local.webp 1x, /local@2x.webp 2x" alt=a width=10 height=10>'
  controle
  assert_eq 0 "$rc" "un srcset entièrement local passe (messages : $err)"
}

case_html_rel_combine() {
  # Même revue : « rel="preload stylesheet" » échappait à la comparaison exacte.
  sortie '<link rel="preload stylesheet" href=https://tiers.invalide/style.css>'
  controle
  assert_eq 1 "$rc" "un rel combiné ne masque pas le chargement"
  assert_contains "chargée depuis une autre origine" "$err" "le signalement le dit"
  sortie '<link rel="alternate me" href=https://tiers.invalide/profil>'
  controle
  assert_eq 0 "$rc" "un rel combiné qui ne charge rien passe (messages : $err)"
}

case_html_schema_en_majuscules() {
  # Constat de la quatrième revue de la PR n° 43 : « HTTP:// » est un schéma valide, et la casse
  # permettait de contourner le contrôle.
  sortie '<img src="HtTpS://tiers.invalide/photo.webp" alt=a width=10 height=10>'
  controle
  assert_eq 1 "$rc" "un schéma en casse mixte ne contourne pas le contrôle"
  assert_contains "tiers.invalide/photo.webp" "$err" "le signalement nomme l'URL"
  sortie '<img src="HTTPS://ELEYONE.FR/photo.webp" alt=a width=10 height=10>'
  controle
  assert_eq 0 "$rc" "le site lui-même, en majuscules, reste accepté (messages : $err)"
}

# --- C11 : accessibilité automatisable (story 3.9) ------------------------------------------------

case_c11_langue_absente() {
  sortie
  sed -i 's/<html lang=fr>/<html>/' "$work/public/page.html"
  controle
  assert_eq 1 "$rc" "une page sans lang fait échouer"
  assert_contains "C11 : <html lang> absent" "$err" "le signalement renvoie à 3.1.1"
}

case_c11_titre_sans_identite() {
  sortie
  sed -i 's#<title>Page · Prénom Nom · Pseudo</title>#<title>Page</title>#' "$work/public/page.html"
  controle
  assert_eq 1 "$rc" "un titre sans la ligne d'identité fait échouer"
  assert_contains "sans la ligne d'identité « Prénom Nom · Pseudo »" "$err" "le signalement donne l'identité attendue"
}

case_c11_accueil_exempte_de_lidentite() {
  # AD-2, story 2.2 : l'accueil fait exception, son titre portant déjà le nom. Sans cette exception,
  # le contrôle refuserait les deux accueils du site réel (constaté avant écriture).
  sortie
  controle
  assert_eq 0 "$rc" "l'accueil passe avec son titre propre (messages : $err)"
}

case_c11_titre_vide() {
  sortie
  sed -i 's#<title>Page · Prénom Nom · Pseudo</title>#<title></title>#' "$work/public/page.html"
  controle
  assert_eq 1 "$rc" "un titre vide fait échouer"
  assert_contains "C11 : <title> vide" "$err" "le signalement renvoie à 2.4.2"
}

case_c11_nombre_de_h1() {
  sortie '' '<h1>Deuxième titre</h1>'
  controle
  assert_eq 1 "$rc" "deux h1 font échouer"
  assert_contains "2 balise(s) <h1> ; exactement une est attendue" "$err" "le signalement compte"
  sortie
  sed -i 's#<h1>Page</h1>##' "$work/public/page.html"
  controle
  assert_eq 1 "$rc" "aucun h1 fait échouer aussi"
  assert_contains "0 balise(s) <h1>" "$err" "le signalement le dit"
}

case_c11_saut_de_niveau() {
  sortie '' '<h4>Sous-titre sauté</h4>'
  controle
  assert_eq 1 "$rc" "un saut de h2 à h4 fait échouer"
  assert_contains "saut de niveau de titre, h2 suivi de h4" "$err" "le signalement nomme les deux niveaux"
}

case_c11_identifiant_en_double() {
  sortie '' '<p id=repere>un</p><p id=repere>deux</p>'
  controle
  assert_eq 1 "$rc" "un identifiant en double fait échouer"
  assert_contains "identifiant « repere » en double" "$err" "le signalement nomme l'identifiant"
}

case_c11_image_sans_alternative_ni_dimensions() {
  sortie '' '<img src=/photo.webp width=10 height=10>'
  controle
  assert_eq 1 "$rc" "une image sans alt fait échouer"
  assert_contains "image(s) sans alternative textuelle" "$err" "le signalement renvoie à 1.1.1"
  sortie '' '<img src=/photo.webp alt=Photo>'
  controle
  assert_eq 1 "$rc" "une image sans dimensions fait échouer"
  assert_contains "sans width ni height" "$err" "le signalement renvoie au CLS"
}

case_c11_lien_sans_nom() {
  sortie '' '<a href=/quelque-part></a>'
  controle
  assert_eq 1 "$rc" "un lien vide fait échouer"
  assert_contains "lien(s) sans nom accessible" "$err" "le signalement renvoie à 2.4.4"
  sortie '' '<a href=/quelque-part aria-label=""></a>'
  controle
  assert_eq 1 "$rc" "un aria-label vide ne nomme rien (constat de la revue de la PR n° 45)"
  sortie '' '<a href=/quelque-part title="  "></a>'
  controle
  assert_eq 1 "$rc" "un title fait d'espaces non plus"
  sortie '' '<a href=/quelque-part aria-label="Aller quelque part"></a>'
  controle
  assert_eq 0 "$rc" "un aria-label suffit (messages : $err)"
  sortie '' '<a href=/quelque-part><img src=/i.webp alt=Illustration width=10 height=10></a>'
  controle
  assert_eq 0 "$rc" "une image décrite suffit aussi (messages : $err)"
}

case_c11_hreflang_absent() {
  sortie
  sed -i '/rel=alternate/d' "$work/public/page.html"
  controle
  assert_eq 1 "$rc" "une page sans hreflang fait échouer"
  assert_contains "aucun lien hreflang" "$err" "le signalement renvoie à AD-2"
}

case_c11_tabindex_positif() {
  sortie '' '<div tabindex=1>Cible</div>'
  controle
  assert_eq 1 "$rc" "un tabindex positif fait échouer"
  assert_contains "tabindex positif « 1 »" "$err" "le signalement renvoie à 2.4.3"
  sortie '' '<div tabindex="+1">Cible</div>'
  controle
  assert_eq 1 "$rc" "« +1 » est un tabindex positif valide (constat de la revue de la PR n° 45)"
  sortie '' '<div tabindex=" 01 ">Cible</div>'
  controle
  assert_eq 1 "$rc" "« 01 » entouré d'espaces aussi"
  sortie '' '<div tabindex=0>Cible</div>'
  controle
  assert_eq 0 "$rc" "tabindex=0 reste permis, il rend un conteneur focalisable (messages : $err)"
  sortie '' '<div tabindex=-1>Cible</div>'
  controle
  assert_eq 0 "$rc" "tabindex=-1 aussi : il sort de l'ordre de tabulation sans le perturber (messages : $err)"
}

case_c11_sans_manifeste() {
  sortie
  rm -f "$work/rendu/checks.json"
  controle
  assert_eq 2 "$rc" "sans manifeste, la ligne d'identité manque : anomalie"
  assert_contains "scripts/build.sh work" "$err" "le message dit quoi lancer"
}

case_c11_page_sans_aucun_titre() {
  # Constat de la deuxième revue de la PR n° 45 : sans titre, le grep du plan rendait 1 et l'échec
  # passait en silence dans la substitution de processus.
  rm -rf "$work/public"; mkdir -p "$work/public"
  manifeste
  cp "$fixtures/html/index.html" "$work/public/"
  printf '<!doctype html><html lang=fr><head><title>Page · Prénom Nom · Pseudo</title><link rel=alternate hreflang=en href=/en/p.html></head><body><p>Sans titre.</p></body></html>' \
    > "$work/public/page.html"
  controle
  assert_eq 1 "$rc" "une page sans h1 est signalée, et rien d'autre ne casse"
  assert_contains "0 balise(s) <h1>" "$err" "le signalement porte bien sur le h1 manquant"
  [[ $err != *"saut de niveau"* ]] || { echo "un saut de niveau a été inventé sur une page sans titre" >&2; exit 1; }
}

case_html_sans_build() {
  run env CHECK_PUBLIC_ROOT="$work/absent" bash "$root/scripts/checks/html.sh"
  assert_eq 2 "$rc" "une production absente est une anomalie"
  assert_contains "scripts/build.sh production" "$err" "le message dit quoi lancer"
}

run_case "$@"
