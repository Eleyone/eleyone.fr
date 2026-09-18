#!/usr/bin/env bash
# Contrat du manifeste (stories 3.1 et 3.2) : un site fixture construit avec le Hugo épinglé, puis
# ses manifestes lus à jq. Les autres contrôles se testent sur des manifestes écrits à la main ; ce
# cas-ci est le seul à lancer un vrai build, pour prouver que le manifeste réel a bien cette forme.
# Hors ligne : aucun téléchargement, le binaire vient de .tools/ ou du PATH (CHECK_IMAGE).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-checks-manifest
. "$root/scripts/lib/tools.sh"

# Le site fixture emprunte les gabarits, la configuration et les données du dépôt : c'est bien le
# gabarit livré que ce cas exerce, sur un contenu à lui.
construire() {
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  mkdir -p "$work/site"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$fixtures/site/content" "$work/site/content"
  (cd "$work/site" && hugo --environment work --buildDrafts --panicOnWarning --destination sortie) \
    > "$work/hugo.out" 2>&1
}

case_manifeste_decrit_le_site_fixture() {
  run construire
  assert_eq 0 "$rc" "le build du site fixture réussit (sortie : $(cat "$work/hugo.out"))"
  local fr=$work/site/sortie/checks.json en=$work/site/sortie/en/checks.json
  jq -e . "$fr" > /dev/null || { echo "manifeste FR illisible" >&2; exit 1; }
  jq -e . "$en" > /dev/null || { echo "manifeste EN illisible" >&2; exit 1; }

  assert_eq "fr" "$(jq -r .lang "$fr")" "le manifeste porte sa langue"
  # La fixture est volontairement déséquilibrée : « sans-front » n'existe qu'en français, écart que
  # la parité (C3, story 3.3) doit voir. Chaque manifeste liste donc les fichiers de sa langue, plus
  # ceux qui n'en portent aucune.
  assert_eq 6 "$(jq '.files|length' "$fr")" "le manifeste FR liste les fichiers français et sans langue"
  assert_eq 5 "$(jq '.files|length' "$en")" "le manifeste EN liste les fichiers anglais et sans langue"

  local roles
  roles=$(jq -r '[.files[] | "\(.file) \(.role)"] | sort | join(", ")' "$fr")
  assert_eq "_index.fr.md home, cases/_index.fr.md section, cases/groupe/_index.fr.md group, cases/groupe/case-09-fixture.fr.md case, sans-front.fr.md page, sans-langue.md null" \
    "$roles" "chaque fichier reçoit son rôle, y compris les _index hors collections"

  local cas
  cas=$(jq -c '.files[] | select(.file|test("case-09"))' "$fr")
  assert_eq '["## Contexte","## Résultat"]' "$(jq -c .h2 <<< "$cas")" "les titres H2 sortent du Markdown brut"
  assert_eq '["diagram-fixture"]' "$(jq -c .placed <<< "$cas")" "l'identifiant placé est extrait"
  assert_eq "true" "$(jq -r .todo <<< "$cas")" "un [TODO du front matter est vu"
  assert_eq "true" "$(jq -r .draft <<< "$cas")" "le brouillon est rapporté"
  assert_eq "case-09" "$(jq -r .translationKey <<< "$cas")" "le translationKey est rapporté"
  assert_eq "position-fixture" "$(jq -r .front_matter.position <<< "$cas")" "le front matter garde ses valeurs"
  assert_eq "translationKey" "$(jq -r '.front_matter | keys[] | select(. == "translationKey")' <<< "$cas")" \
    "le front matter garde la casse de ses clés"
  assert_eq "null" "$(jq -r '.front_matter.build // "null"' <<< "$cas")" "ce que la cascade ajoute n'y est pas"

  assert_contains "front matter absent" "$(jq -r '.files[] | select(.file=="sans-front.fr.md") | .error' "$fr")" \
    "un fichier sans front matter est signalé"
  assert_contains "suffixe de langue absent" "$(jq -r '.files[] | select(.file=="sans-langue.md") | .error' "$fr")" \
    "un fichier sans suffixe de langue est signalé en FR"
  assert_contains "suffixe de langue absent" "$(jq -r '.files[] | select(.file=="sans-langue.md") | .error' "$en")" \
    "le même fichier est signalé en EN"

  assert_eq "true" "$(jq '.stack | index("PHP") != null' "$fr")" "le vocabulaire de data/stack.yaml est à la racine"
}

run_case "$@"
