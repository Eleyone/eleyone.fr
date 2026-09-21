#!/usr/bin/env bash
# Feuille de style unique (story 5.1) : elle ne porte que des valeurs de DESIGN.md, et aucune police.
#
# Le critère « aucune valeur de design hors DESIGN.md » ne se relit pas : une couleur inventée d'un
# chiffre ressemble à la bonne. Ces cas confrontent la feuille au bloc de tokens en tête de
# DESIGN.md, qui est la source. Les valeurs purement fonctionnelles (100%, 0, calc()) n'en sont pas :
# elles ne portent aucune décision, et le cas ne les regarde pas.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

css="$root/assets/css/main.css"
design="$root/_bmad-output/planning-artifacts/ux-designs/ux-eleyone.fr-2026-09-13/DESIGN.md"

# La feuille sans ses commentaires. Sans ce retrait, un commentaire qui *explique* qu'on n'emploie
# pas « @font-face » ferait échouer le cas qui l'interdit — ce qui est arrivé en l'écrivant.
# L'automate suit les « /* » et « */ » même lorsqu'ils s'ouvrent ou se ferment en milieu de ligne.
css_nu() {
  awk '{
    ligne = $0; sortie = ""
    while (length(ligne)) {
      if (dans) {
        p = index(ligne, "*/")
        if (p == 0) { ligne = "" } else { ligne = substr(ligne, p + 2); dans = 0 }
      } else {
        p = index(ligne, "/*")
        if (p == 0) { sortie = sortie ligne; ligne = "" }
        else { sortie = sortie substr(ligne, 1, p - 1); ligne = substr(ligne, p + 2); dans = 1 }
      }
    }
    print sortie
  }' "$1"
}

# L'automate ci-dessus ne connaît pas les chaînes : un « content: "/*" » lui ferait prendre tout le
# reste du fichier pour un commentaire (constat de la revue de la PR n° 66). Le sens de l'erreur
# serait un **faux vert** — les couleurs situées après la troncature échapperaient au contrôle —,
# et c'est le seul sens qui ne se pardonne pas. Une troncature déséquilibre forcément les accolades :
# ce garde-fou la transforme en échec bruyant. Il coûte trois lignes, contre un analyseur CSS.
css_equilibre() { # $1 = la feuille dépouillée ; échoue si des accolades manquent
  local ouvrantes fermantes
  ouvrantes=$(tr -cd '{' <<< "$1" | wc -c)
  fermantes=$(tr -cd '}' <<< "$1" | wc -c)
  ((ouvrantes == fermantes && ouvrantes > 0)) || {
    printf 'feuille dépouillée déséquilibrée : %s accolades ouvrantes, %s fermantes.\n' \
      "$ouvrantes" "$fermantes" >&2
    echo "Un « /* » dans une chaîne CSS a probablement fait avaler la fin du fichier." >&2
    exit 1
  }
}

case_css_et_design_existent() {
  [[ -f $css ]] || { echo "feuille de style absente : $css" >&2; exit 1; }
  [[ -f $design ]] || { echo "DESIGN.md absent : $design" >&2; exit 1; }
}

case_aucune_couleur_hors_design() {
  # Toute couleur de la feuille doit figurer dans DESIGN.md. La comparaison se fait en minuscules :
  # DESIGN.md écrit « #FBFBF9 », le CSS « #fbfbf9 », et ce sont la même couleur.
  local dans_css dans_design couleur intruses="" nu
  nu=$(css_nu "$css")
  css_equilibre "$nu"
  shell_grep_into dans_css -oiE '#[0-9a-f]{3,8}\b' <<< "$nu"
  [[ -n $dans_css ]] || { echo "aucune couleur dans la feuille : le cas ne prouverait rien" >&2; exit 1; }
  shell_grep_into dans_design -oiE '#[0-9a-f]{3,8}\b' "$design"
  local liste_design
  liste_design=$(tr 'A-F' 'a-f' <<< "$dans_design" | sort -u)
  while IFS= read -r couleur; do
    [[ -n $couleur ]] || continue
    couleur=$(tr 'A-F' 'a-f' <<< "$couleur")
    grep -qxF "$couleur" <<< "$liste_design" || intruses+="$couleur "
  done <<< "$(tr 'A-F' 'a-f' <<< "$dans_css" | sort -u)"
  assert_eq "" "${intruses% }" "chaque couleur de la feuille vient de DESIGN.md"
}

case_les_huit_roles_de_couleur_sont_la() {
  # Les deux modes, huit rôles chacun (DESIGN.md § Colors). Un rôle oublié en sombre laisserait la
  # valeur claire s'appliquer, sans que rien n'échoue.
  local contenu role
  contenu=$(cat "$css")
  for role in paper surface plate ink ink-muted accent rule border-strong; do
    assert_contains "--$role:" "$contenu" "le rôle « $role » est défini"
  done
  # Le bloc sombre redéfinit les huit.
  local sombre nb
  sombre=$(awk '/@media \(prefers-color-scheme: dark\)/ { d = 1 } d { print; if (/^}/) exit }' "$css")
  for role in paper surface plate ink ink-muted accent rule border-strong; do
    assert_contains "--$role:" "$sombre" "le mode sombre redéfinit « $role »"
  done
  shell_grep_into nb -c 'color-scheme: light dark' "$css"
  assert_eq 1 "$nb" "« color-scheme: light dark » accompagne les tokens (DESIGN.md § Colors)"
}

case_les_piles_de_polices_sont_celles_de_design() {
  # Les deux piles sont recopiées caractère pour caractère : une police retirée de la liste
  # changerait le rendu sur une plateforme sans que rien ne le signale.
  local ligne pile
  for pile in serif mono; do
    shell_grep_into ligne -E "^  --font-$pile:" "$css"
    [[ -n $ligne ]] || { echo "pile « $pile » absente de la feuille" >&2; exit 1; }
    # La valeur, sans le nom de la propriété ni le point-virgule final.
    local valeur
    valeur=$(sed -e "s/^  --font-$pile: *//" -e 's/;$//' <<< "$ligne")
    local dans_design
    shell_grep_into dans_design -F "$valeur" "$design"
    assert_contains "$valeur" "$dans_design" "la pile « $pile » est celle de DESIGN.md"
  done
}

case_aucune_police_chargee() {
  # AD-8 : aucune police web, ni fichier local, ni appel réseau. C10 refuse par ailleurs toute
  # origine tierce dans le CSS ; ce cas le dit sur la source, avant même le build.
  local trouve motif
  local nu
  nu=$(css_nu "$css")
  css_equilibre "$nu"
  for motif in '@font-face' '@import' 'src:[[:space:]]*url' 'fonts.googleapis' 'fonts.gstatic'; do
    shell_grep_into trouve -nE "$motif" <<< "$nu"
    assert_eq "" "$trouve" "la feuille ne charge aucune police ($motif)"
  done
  local fichiers
  fichiers=$(find "$root/assets" -type f \( -name '*.woff*' -o -name '*.ttf' -o -name '*.otf' -o -name '*.eot' \) 2>/dev/null)
  assert_eq "" "$fichiers" "aucun fichier de police dans assets/"
}

case_la_feuille_tient_dans_le_budget() {
  # AD-8 : 20 Ko au plus pour la CSS totale. La mesure porte sur la source non minifiée, qui est
  # toujours la plus grosse : si elle passe, la feuille servie passe.
  local octets
  octets=$(wc -c < "$css")
  ((octets <= 20480)) \
    || { printf 'la feuille fait %s octets, au-delà des 20 Ko d’AD-8\n' "$octets" >&2; exit 1; }
}

case_le_lien_devitement_et_lancre() {
  # Un lien d'évitement vers une ancre absente n'évite rien (constat de la revue de spec).
  local baseof="$root/layouts/baseof.html" gabarit manquants=""
  assert_contains 'href="#content"' "$(cat "$baseof")" "le lien d'évitement vise #content"
  assert_contains 'i18n "skip_to_content"' "$(cat "$baseof")" "son libellé vient d'i18n, pas du gabarit"
  # Chaque gabarit qui définit « main » porte l'ancre.
  local liste
  liste=$(git -C "$root" ls-files -- 'layouts/*.html' 'layouts/**/*.html')
  while IFS= read -r gabarit; do
    [[ -n $gabarit ]] || continue
    local contenu
    contenu=$(cat "$root/$gabarit")
    [[ $contenu == *"<main"* ]] || continue
    [[ $contenu == *'<main id="content"'* ]] || manquants+="$gabarit "
  done <<< "$liste"
  assert_eq "" "${manquants% }" "chaque <main> porte id=\"content\", cible du lien d'évitement"
  local cle cle_fr cle_en
  for cle in skip_to_content nav_site footer_source block_parallel block_education via_label; do
    shell_grep_into cle_fr -n "^$cle:" "$root/i18n/fr.yaml"
    assert_contains "$cle" "$cle_fr" "la clé « $cle » existe en français"
    shell_grep_into cle_en -n "^$cle:" "$root/i18n/en.yaml"
    assert_contains "$cle" "$cle_en" "la clé « $cle » existe en anglais"
  done
}

case_la_feuille_est_empreintee_dans_le_gabarit() {
  # L'empreinte est ce qui autorise le cache d'un an posé par nginx sur les fichiers empreintés
  # (story 4.2). Sans elle, un visiteur garderait l'ancienne feuille un an.
  local baseof
  baseof=$(cat "$root/layouts/baseof.html")
  # Les fragments sont cherchés dans leur enchaînement, pas séparément : deux présences isolées
  # laisseraient passer une seconde feuille minifiée à la place de la première (constat de la
  # revue de la PR n° 66). Les espaces variables sont tolérés, l'ordre ne l'est pas.
  local sans_espaces
  sans_espaces=$(tr -s ' \n' '  ' < "$root/layouts/baseof.html")
  assert_contains 'with resources.Get "css/main.css" }} {{ with . | minify | fingerprint }}' \
    "$sans_espaces" "la feuille du dépôt est celle qui est minifiée puis empreintée"
  assert_contains 'href="{{ .RelPermalink }}"' "$baseof" "le <link> porte l'URL empreintée"
}

case_le_poste_nemploie_pas_la_cle_url_de_hugo() {
  # « url » est réservée par Hugo : elle force l'adresse d'une page, et une valeur à protocole fait
  # échouer le build (« URLs with protocol (http*) not supported »), constaté le 21/09/2026 en
  # écrivant la story 5.2. L'adresse du site d'une société vit donc dans « company_url ».
  local partial="$root/layouts/_partials/position.html" contenu
  contenu=$(cat "$partial")
  assert_contains '.Params.company_url' "$contenu" "le lien de société passe par company_url"
  local trouve
  shell_grep_into trouve -nE '\.Params\.url\b' "$partial"
  assert_eq "" "$trouve" "le gabarit n'emploie pas .Params.url, que Hugo réserve"
  # Les deux contrôles connaissent la clé : la parité la traite en non traduite, C19 la valide.
  assert_contains '"company_url"' "$(cat "$root/scripts/checks/parity.sh")" "C3 la compte parmi les clés non traduites"
  assert_contains 'company_url' "$(cat "$root/scripts/checks/content.sh")" "C19 la valide"
}

case_laccueil_necrit_aucun_texte() {
  # AD-3 : tout le texte vient du contenu ou d'i18n. Un libellé écrit dans le gabarit échapperait
  # à la traduction et à la parité FR/EN.
  local home
  home=$(cat "$root/layouts/home.html")
  local bloc
  for bloc in block_career block_parallel; do
    assert_contains "i18n \"$bloc\"" "$home" "le titre du bloc « $bloc » vient d'i18n"
  done
  # Les deux blocs sont conditionnés à l'existence d'un poste : pas de titre au-dessus du néant
  # (constat de la revue de spec de la story 5.2).
  local nb
  shell_grep_into nb -c 'Params.track' "$root/layouts/home.html"
  assert_eq 2 "$nb" "les deux blocs filtrent sur track, chacun dans son « with »"
}

run_case "$@"
