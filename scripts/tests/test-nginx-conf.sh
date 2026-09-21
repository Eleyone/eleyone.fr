#!/usr/bin/env bash
# Configuration nginx de l'image (story 4.2). Les cas lisent le fichier : la suite reste hors ligne
# et sans démon (story 0.9). Le comportement réel est éprouvé contre un vrai conteneur, à la main,
# et la recette est dans docs/procedures/build-image.md.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

conf="$root/deploy/nginx/site.conf"

case_nginx_conf_existe() {
  [[ -f $conf ]] || { echo "configuration absente : $conf" >&2; exit 1; }
}

case_nginx_conf_reglages_de_base() {
  local contenu directive
  contenu=$(cat "$conf")
  for directive in 'server_tokens off;' 'absolute_redirect off;' 'log_not_found off;' \
    'error_log /dev/stderr crit;' 'add_header_inherit merge;' 'gzip on;' 'gzip_vary on;'; do
    assert_contains "$directive" "$contenu" "la configuration porte « $directive »"
  done
}

case_nginx_conf_aucun_realip() {
  # Aucun module realip : l'adresse du visiteur ne doit être reconstituée nulle part (NFR-3).
  local trouve
  shell_grep_into trouve -n 'real_ip' "$conf"
  assert_eq "" "$trouve" "aucune directive real_ip"
}

# Les variables que le format a le droit de citer. Le cas raisonne par liste blanche, pas par liste
# noire : une liste noire est toujours en retard d'une variable. La règle précédente interdisait
# « $request » suivi d'autre chose qu'un « _ », pour épargner $request_method — et laissait donc
# passer $request_uri, qui porte la chaîne de requête. Elle serait restée verte sur une
# configuration qui la journalise (constat B1 de la rétrospective de l'epic 4, 21/09/2026).
format_admet=' time_local request_method uri status body_bytes_sent '

variables_intruses() { # $1 = fichier de configuration ; affiche les variables non admises
  local fichier=$1 ligne variables variable intruses=""
  shell_grep_into ligne -E '^[[:space:]]*log_format' "$fichier"
  [[ -n $ligne ]] || { echo "aucune directive log_format hors commentaire dans $fichier" >&2; exit 1; }
  shell_grep_into variables -oE '\$[a-z_]+' <<< "$ligne"
  [[ -n $variables ]] || { echo "le format ne cite aucune variable dans $fichier" >&2; exit 1; }
  while IFS= read -r variable; do
    [[ -n $variable ]] || continue
    [[ $format_admet == *" ${variable#$} "* ]] || intruses+="$variable "
  done <<< "$variables"
  printf '%s' "${intruses% }"
}

case_nginx_conf_journal_regle_attrape_la_fuite() {
  # Sans ce cas, la règle pourrait n'attraper personne et passer pour verte — ce qu'a fait la
  # précédente pendant toute la story 4.2.
  local fuite=$work/fuite.conf
  sed 's|"\$request_method \$uri"|"$request_method $request_uri"|' "$conf" > "$fuite"
  assert_eq '$request_uri' "$(variables_intruses "$fuite")" "\$request_uri est vue comme une intruse"

  sed 's|\$time_local|$remote_addr|' "$conf" > "$fuite"
  assert_eq '$remote_addr' "$(variables_intruses "$fuite")" "une adresse dans le format est vue aussi"
}

case_nginx_conf_journal_sans_adresse() {
  # Le format ne cite ni $remote_addr, ni $request (qui porte la chaîne de requête), ni
  # $http_user_agent, ni $http_referer.
  local format interdit trouve
  shell_grep_into format -n 'log_format' "$conf"
  assert_contains 'log_format sans_ip' "$format" "le format est nommé"
  assert_contains '$uri' "$format" "le chemin est journalisé sans sa chaîne de requête"
  for interdit in 'remote_addr' 'http_user_agent' 'http_referer' 'binary_remote_addr'; do
    shell_grep_into trouve -n "\$$interdit" "$conf"
    assert_eq "" "$trouve" "le journal ne cite pas \$$interdit"
  done
  assert_eq "" "$(variables_intruses "$conf")" \
    "le format ne cite que les variables voulues, \$uri et jamais \$request ni \$request_uri"
  assert_contains 'access_log /dev/stdout sans_ip;' "$(cat "$conf")" "le journal emploie ce format"
}

case_nginx_conf_entetes_de_securite() {
  local contenu
  contenu=$(cat "$conf")
  assert_contains 'add_header X-Content-Type-Options nosniff always;' "$contenu" "nosniff, toujours"
  assert_contains 'add_header Referrer-Policy strict-origin-when-cross-origin always;' "$contenu" "la politique de referer"
  assert_contains 'add_header Content-Security-Policy $csp always;' "$contenu" "la CSP passe par la variable"
  assert_contains 'add_header Cache-Control $cache_control always;' "$contenu" "le cache aussi"
  # « always » sur chacun : sans lui, l'en-tête manque sur une 404. Les lignes sont examinées une
  # par une : une expression régulière « qui ne contient pas » se trompe de cible trop facilement.
  local lignes ligne sans_always=""
  shell_grep_into lignes -nE '^[[:space:]]*add_header [A-Za-z]' "$conf"
  while IFS= read -r ligne; do
    [[ -n $ligne ]] || continue
    [[ $ligne == *" always;"* ]] || sans_always+="$ligne"$'\n'
  done <<< "$lignes"
  assert_eq "" "${sans_always%$'\n'}" "aucun add_header sans « always »"
}

case_nginx_conf_csp_sur_le_html_seulement() {
  local contenu
  contenu=$(cat "$conf")
  assert_contains 'map $sent_http_content_type $csp' "$contenu" "la CSP dépend du type servi"
  assert_contains "~^text/html" "$contenu" "elle n'est posée que sur le HTML"
  assert_contains "default      \"\";" "$contenu" "une valeur vide supprime l'en-tête ailleurs"
  assert_contains "default-src 'none'; style-src 'self'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'" \
    "$contenu" "la politique exacte d'AD-13"
}

case_nginx_conf_cache_selon_le_fichier() {
  local contenu
  contenu=$(cat "$conf")
  assert_contains 'map $uri $cache_control' "$contenu" "le cache dépend du chemin"
  assert_contains '[0-9a-f]{64}' "$contenu" "les fichiers empreintés sont reconnus par leur condensat"
  assert_contains 'public, max-age=31536000, immutable' "$contenu" "un an pour eux"
  assert_contains 'default                            "no-cache"' "$contenu" "tout le reste est revérifié (décidé le 21/09/2026)"
}

case_nginx_conf_404_par_langue() {
  local contenu
  contenu=$(cat "$conf")
  assert_contains 'error_page 404 /404.html;' "$contenu" "la 404 française"
  assert_contains 'location /en/' "$contenu" "le bloc anglais"
  assert_contains 'error_page 404 /en/404.html;' "$contenu" "la 404 anglaise"
}

case_nginx_conf_gzip_couvre_les_types_servis() {
  # « text/xml » autant qu'« application/xml » : nginx sert un .xml en text/xml, et le sitemap
  # partait non compressé (constaté au premier essai du conteneur, 21/09/2026).
  local types
  shell_grep_into types -n 'gzip_types' "$conf"
  local type
  for type in 'text/css' 'text/xml' 'image/svg+xml' 'application/json' 'application/xml'; do
    assert_contains "$type" "$types" "gzip couvre $type"
  done
}

case_dockerfile_copie_la_configuration() {
  assert_contains 'COPY deploy/nginx/site.conf /etc/nginx/conf.d/default.conf' "$(cat "$root/Dockerfile")" \
    "l'image emporte sa configuration"
}

run_case "$@"
