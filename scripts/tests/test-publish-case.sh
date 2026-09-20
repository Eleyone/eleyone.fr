#!/usr/bin/env bash
# Décision de publication d'un cas (story 3.17) : ce que publish_case_plan accepte, refuse et nomme.
# Les manifestes sont écrits à la main, comme ceux des contrôles : aucun build, aucune forge.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Un fichier du manifeste. $1 = fichier, $2 = rôle, $3 = clé, $4 = brouillon, $5 = todo,
# $6 = poste (vide si aucun), $7 = groupe (vide si aucun).
entree() {
  jq -nc --arg f "$1" --arg r "$2" --arg k "$3" --argjson d "$4" --argjson t "$5" \
    --arg p "${6:-}" --arg g "${7:-}" '
    { file: $f, lang: "fr", kind: "page", role: $r, translationKey: $k, draft: $d, todo: $t,
      front_matter: ({ draft: $d }
        + (if $p == "" then {} else { position: $p } end)
        + (if $g == "" then {} else { group: $g } end)) }'
}

manifeste() { # $1 = fichier de sortie, $2… = entrées JSON
  local sortie=$1; shift
  mkdir -p "$(dirname "$sortie")"
  printf '%s\n' "$@" | jq -s '{ lang: "fr", stack: {}, rubrics: {}, files: . }' > "$sortie"
}

# Un cas groupé complet : le cas dans les deux langues, son poste publié, la page du groupe.
# $1 = brouillon du cas, $2 = todo du cas, $3 = brouillon du poste, $4 = brouillon du groupe fr,
# $5 = brouillon du groupe en (par défaut le même que fr), $6 = todo du groupe.
site_groupe() {
  local case_draft=${1:-true} case_todo=${2:-false} poste_draft=${3:-false}
  local index_fr=${4:-true}
  # En deux temps : bash développe tous les mots d'un « local » avant d'affecter, si bien que
  # « local a=1 b=${2:-$a} » laisserait $a sans liaison sous set -u.
  local index_en=${5:-$index_fr} index_todo=${6:-false}
  manifeste "$work/fr/checks.json" \
    "$(entree career/position-chiliz.fr.md position position-chiliz "$poste_draft" false)" \
    "$(entree cases/chiliz/_index.fr.md group group-chiliz "$index_fr" "$index_todo" "" chiliz)" \
    "$(entree cases/chiliz/case-02-chiliz.fr.md case case-02 "$case_draft" "$case_todo" position-chiliz chiliz)"
  manifeste "$work/en/checks.json" \
    "$(entree career/position-chiliz.en.md position position-chiliz "$poste_draft" false)" \
    "$(entree cases/chiliz/_index.en.md group group-chiliz "$index_en" "$index_todo" "" chiliz)" \
    "$(entree cases/chiliz/case-02-chiliz.en.md case case-02 "$case_draft" "$case_todo" position-chiliz chiliz)"
}

plan() { # $1 = clé
  run bash -c 'script_name=essai; . "$1/scripts/lib/publish-case.sh"; publish_case_plan "$2/fr/checks.json" "$2/en/checks.json" "$3"' \
    _ "$root" "$work" "$1"
}

case_publish_case_groupe_premier_cas() {
  # La page du groupe part avec son premier cas publié (D-3, AD-4).
  site_groupe
  plan case-02
  assert_eq 0 "$rc" "le plan est rendu (messages : $err)"
  assert_eq "case=cases/chiliz/case-02-chiliz.fr.md
case=cases/chiliz/case-02-chiliz.en.md
index=cases/chiliz/_index.fr.md
index=cases/chiliz/_index.en.md
release=case-02
release=group-chiliz" "$out" "le cas, la page du groupe et les deux clés"
}

case_publish_case_groupe_deja_publie() {
  site_groupe true false false false false
  plan case-02
  assert_eq 0 "$rc" "le plan est rendu (messages : $err)"
  assert_eq "case=cases/chiliz/case-02-chiliz.fr.md
case=cases/chiliz/case-02-chiliz.en.md
release=case-02
release=group-chiliz" "$out" "la page du groupe déjà publiée n'est pas retouchée ; la clé reste proposée"
}

case_publish_case_sans_groupe() {
  manifeste "$work/fr/checks.json" \
    "$(entree career/position-seul.fr.md position position-seul false false)" \
    "$(entree cases/case-01-seul.fr.md case case-01 true false position-seul)"
  manifeste "$work/en/checks.json" \
    "$(entree career/position-seul.en.md position position-seul false false)" \
    "$(entree cases/case-01-seul.en.md case case-01 true false position-seul)"
  plan case-01
  assert_eq 0 "$rc" "un cas hors groupe passe (messages : $err)"
  assert_eq "case=cases/case-01-seul.fr.md
case=cases/case-01-seul.en.md
release=case-01" "$out" "deux fichiers, une seule clé"
}

case_publish_case_poste_en_brouillon() {
  # Le script ne publie jamais le poste à la place de la story qui en a la charge.
  site_groupe true false true
  plan case-02
  assert_eq 1 "$rc" "un poste en brouillon fait échouer la publication"
  assert_contains "position-chiliz" "$err" "le message nomme le poste"
  assert_contains "career/position-chiliz.fr.md" "$err" "et son fichier"
  assert_contains "C19" "$err" "et le contrôle concerné"
}

case_publish_case_todo_restant() {
  site_groupe true true
  plan case-02
  assert_eq 1 "$rc" "un marqueur [TODO fait échouer"
  assert_contains "case-02-chiliz.fr.md" "$err" "le message nomme le fichier"
  assert_contains "C5" "$err" "et le contrôle concerné"
}

case_publish_case_todo_dans_la_page_de_groupe() {
  site_groupe true false false true true true
  plan case-02
  assert_eq 1 "$rc" "un [TODO dans la page du groupe fait échouer : elle est publiée avec le cas"
  assert_contains "_index.fr.md" "$err" "le message nomme le fichier"
}

case_publish_case_deja_publie() {
  site_groupe false
  plan case-02
  assert_eq 1 "$rc" "un cas déjà publié n'est pas republié"
  assert_contains "déjà publié" "$err" "le message le dit"
}

case_publish_case_cle_inconnue() {
  site_groupe
  plan case-99
  assert_eq 1 "$rc" "une clé inconnue est refusée"
  assert_contains "case-99" "$err" "le message nomme la clé"
}

case_publish_case_pas_un_cas() {
  site_groupe
  plan position-chiliz
  assert_eq 1 "$rc" "publish-case ne publie que des cas"
  assert_contains "position" "$err" "le message nomme le rôle rencontré"
}

case_publish_case_sans_poste() {
  manifeste "$work/fr/checks.json" "$(entree cases/case-01.fr.md case case-01 true false)"
  manifeste "$work/en/checks.json" "$(entree cases/case-01.en.md case case-01 true false)"
  plan case-01
  assert_eq 1 "$rc" "un cas sans poste est refusé (AD-18)"
  assert_contains "position" "$err" "le message nomme la clé manquante"
}

case_publish_case_poste_introuvable() {
  manifeste "$work/fr/checks.json" "$(entree cases/case-01.fr.md case case-01 true false position-absent)"
  manifeste "$work/en/checks.json" "$(entree cases/case-01.en.md case case-01 true false position-absent)"
  plan case-01
  assert_eq 1 "$rc" "un poste introuvable est refusé"
  assert_contains "position-absent" "$err" "le message nomme le poste"
}

case_publish_case_groupe_boiteux() {
  # Publiée d'un côté, en brouillon de l'autre : la parité (C3) ne le voit pas, elle compare
  # l'existence des fichiers, pas leur brouillon.
  site_groupe true false false true false
  plan case-02
  assert_eq 1 "$rc" "une page de groupe publiée dans une seule langue est refusée"
  assert_contains "une langue" "$err" "le message le dit"
}

case_publish_case_entree_en_erreur() {
  manifeste "$work/fr/checks.json" \
    "$(entree cases/case-01.fr.md case case-01 true false position-x | jq -c '. + {error: "front matter illisible"}')"
  manifeste "$work/en/checks.json" "$(entree cases/case-01.en.md case case-01 true false position-x)"
  plan case-01
  assert_eq 1 "$rc" "une entrée en erreur est refusée avant tout le reste"
  assert_contains "front matter illisible" "$err" "le message reprend l'erreur du manifeste"
}

case_publish_case_manifeste_absent() {
  rm -rf "$work/fr" "$work/en"
  plan case-02
  assert_eq 2 "$rc" "un manifeste absent est une anomalie"
  assert_contains "scripts/build.sh work" "$err" "le message dit quoi lancer"
}

case_publish_case_manifeste_sans_fichiers() {
  mkdir -p "$work/fr" "$work/en"
  printf '{"lang":"fr"}\n' > "$work/fr/checks.json"
  printf '{"lang":"en"}\n' > "$work/en/checks.json"
  plan case-02
  assert_eq 2 "$rc" "un manifeste sans liste de fichiers est une anomalie"
}

case_publish_case_sans_cle() {
  site_groupe
  plan ""
  assert_eq 2 "$rc" "une clé vide est une anomalie d'usage"
}

case_publish_case_trois_niveaux() {
  # Le skill suit le principe des trois niveaux, et les deux copies sont des liens, jamais des
  # doublons : une copie dériverait (AGENTS.md).
  [[ -f $root/.claude/skills/publish-case/SKILL.md ]] || { echo "SKILL.md absent" >&2; exit 1; }
  [[ -f $root/docs/procedures/publish-case.md ]] || { echo "procédure absente" >&2; exit 1; }
  [[ -x $root/scripts/publish-case.sh ]] || { echo "script absent ou non exécutable" >&2; exit 1; }
  local contenu
  contenu=$(cat "$root/.claude/skills/publish-case/SKILL.md")
  assert_contains "name: publish-case" "$contenu" "le skill se nomme"
  assert_contains "À utiliser quand" "$contenu" "la description dit quand l'employer"
  assert_contains "docs/procedures/publish-case.md" "$contenu" "le skill renvoie à sa procédure"
  local dossier
  for dossier in .agents .agent; do
    [[ -L $root/$dossier/skills/publish-case ]] \
      || { printf '%s/skills/publish-case n'"'"'est pas un lien\n' "$dossier" >&2; exit 1; }
    [[ $(readlink "$root/$dossier/skills/publish-case") == ../../.claude/skills/publish-case ]] \
      || { printf '%s/skills/publish-case ne pointe pas vers .claude/skills/publish-case\n' "$dossier" >&2; exit 1; }
  done
}

case_publish_case_liste_sans_saut_de_ligne_final() {
  # Constat de la revue de la PR n° 53 : sans saut de ligne final, la première clé ajoutée se
  # collerait à la dernière ligne. L'idiome employé par le script est rejoué ici.
  printf 'home' > "$work/pages.txt"
  bash -c 'f=$1; [[ -s $f && $(tail -c 1 "$f") == "" ]] || printf "\n" >> "$f"; printf "%s\n" case-02 >> "$f"' _ "$work/pages.txt"
  assert_eq "home
case-02" "$(cat "$work/pages.txt")" "la clé arrive sur sa propre ligne"
  bash -c 'f=$1; [[ -s $f && $(tail -c 1 "$f") == "" ]] || printf "\n" >> "$f"; printf "%s\n" group-chiliz >> "$f"' _ "$work/pages.txt"
  assert_eq "home
case-02
group-chiliz" "$(cat "$work/pages.txt")" "un fichier déjà terminé par un saut n'en gagne pas un second"
}

run_case "$@"
