#!/usr/bin/env bash
# C4, C5, C6 (story 3.4), sur des manifestes écrits à la main : rubriques d'un cas, marqueurs [TODO
# publiés, vocabulaire de la stack. La forme du manifeste est prouvée par test-checks-manifest.sh.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

rendu() { # $1 = filtre jq pour le manifeste FR, $2 = filtre pour l'EN
  mkdir -p "$work/rendu/en"
  jq "${1:-.}" "$fixtures/manifests/fr.json" > "$work/rendu/checks.json"
  jq "${2:-.}" "$fixtures/manifests/en.json" > "$work/rendu/en/checks.json"
}

contenu() {
  run env CHECK_WORK_ROOT="$work/rendu" bash "$root/scripts/checks/content.sh"
}

case_content_fixtures_passent() {
  rendu
  contenu
  assert_eq 0 "$rc" "les fixtures conformes passent (messages : $err)"
  assert_contains "vérifiés" "$out" "le contrôle le dit"
}

case_content_c4_rubrique_inconnue() {
  rendu '.files[2].headings = [{"level": 2, "text": "Inventée"}]'
  contenu
  assert_eq 1 "$rc" "une rubrique hors liste fait échouer"
  assert_contains 'C4 : rubrique « Inventée » absente de data/rubrics.yaml' "$err" "le signalement nomme la rubrique"
}

case_content_c4_rubriques_dans_le_desordre() {
  rendu '.files[2].headings = [{"level": 2, "text": "Résultat"}, {"level": 2, "text": "Contexte"}]'
  contenu
  assert_eq 1 "$rc" "l'ordre de data/rubrics.yaml est imposé"
  assert_contains "C4 : rubriques dans le désordre" "$err" "le signalement donne l'ordre attendu"
  assert_contains "ordre attendu : Contexte ; Le problème ; Résultat" "$err" "l'ordre attendu vient de la liste"
}

case_content_c4_rubrique_en_double() {
  rendu '.files[2].headings = [{"level": 2, "text": "Contexte"}, {"level": 2, "text": "Contexte"}]'
  contenu
  assert_eq 1 "$rc" "une rubrique écrite deux fois fait échouer"
  assert_contains 'écrite deux fois' "$err" "le signalement le dit"
}

case_content_c4_titre_trop_profond() {
  # Entrée reportée de la story 2.6 : un cas groupé descend chaque titre d'un niveau, un ###### y
  # produirait un <h7>. La règle décidée le 18/09/2026 refuse tout titre au-delà de ###.
  rendu '.files[2].headings += [{"level": 4, "text": "Trop profond"}]'
  contenu
  assert_eq 1 "$rc" "un titre de niveau 4 dans un cas fait échouer"
  assert_contains "titre de niveau 4 « Trop profond »" "$err" "le signalement nomme le niveau et le titre"
  rendu '.files[2].headings += [{"level": 3, "text": "Sous-titre libre"}]'
  contenu
  assert_eq 0 "$rc" "un sous-titre de niveau 3 reste libre (messages : $err)"
}

case_content_c4_ne_vise_que_les_cas() {
  rendu '.files[1].headings = [{"level": 2, "text": "Missions"}, {"level": 4, "text": "Détail"}]' \
        '.files[1].headings = [{"level": 2, "text": "Assignments"}, {"level": 4, "text": "Detail"}]'
  contenu
  assert_eq 0 "$rc" "les titres d'un poste ne relèvent ni de la liste ni de la profondeur (messages : $err)"
}

case_content_c4_sapplique_aux_brouillons() {
  # AD-10 : la liste des rubriques s'applique aussi à un brouillon.
  rendu '.files[2].draft = true | .files[2].headings = [{"level": 2, "text": "Inventée"}]'
  contenu
  assert_eq 1 "$rc" "un brouillon n'échappe pas à C4"
}

case_content_c5_todo_publie() {
  rendu '.files[1].draft = false | .files[1].todo = true'
  contenu
  assert_eq 1 "$rc" "un [TODO dans un fichier publié fait échouer"
  assert_contains "C5 : le fichier est publié et contient « [TODO »" "$err" "le signalement le dit"
}

case_content_c5_todo_dans_un_brouillon() {
  rendu '.files[1].draft = true | .files[1].todo = true'
  contenu
  assert_eq 0 "$rc" "le même [TODO dans un brouillon passe (messages : $err)"
}

case_content_c6_technologie_hors_vocabulaire() {
  rendu '.files[2].draft = false | .files[2].todo = false | .files[2].front_matter.context.stack = ["Cobol"]'
  contenu
  assert_eq 1 "$rc" "une technologie hors vocabulaire fait échouer"
  assert_contains 'C6 : technologie « Cobol » absente de data/stack.yaml' "$err" "le signalement nomme la technologie"
}

case_content_c6_todo_tolere_dans_un_brouillon() {
  rendu '.files[2].front_matter.context.stack = ["[TODO: stack]"]'
  contenu
  assert_eq 0 "$rc" "un [TODO de stack passe dans un brouillon (messages : $err)"
  rendu '.files[2].draft = false | .files[2].todo = false | .files[2].front_matter.context.stack = ["[TODO: stack]"]'
  contenu
  assert_eq 1 "$rc" "le même [TODO ne passe pas dans un cas publié"
}

case_content_c7_declare_non_place() {
  rendu '.files[2].placed = []'
  contenu
  assert_eq 1 "$rc" "un élément déclaré mais non placé fait échouer"
  assert_contains 'C7 : élément « diagram-essai » déclaré mais jamais placé' "$err" "le signalement nomme l'élément"
}

case_content_c7_place_non_declare() {
  rendu '.files[2].placed += ["callout-fantome"]'
  contenu
  assert_eq 1 "$rc" "un identifiant placé mais non déclaré fait échouer"
  assert_contains 'C7 : identifiant « callout-fantome » placé dans le texte mais absent de live_material' "$err" \
    "le signalement nomme l'identifiant"
}

case_content_c7_place_deux_fois() {
  rendu '.files[2].placed = ["diagram-essai", "diagram-essai"]'
  contenu
  assert_eq 1 "$rc" "le même identifiant placé deux fois fait échouer"
  assert_contains "placé deux fois dans le même cas" "$err" "le signalement le dit"
}

case_content_c7_prefixe_du_type() {
  rendu '.files[2].material[0].id = "schema-essai" | .files[2].placed = ["schema-essai"]'
  contenu
  assert_eq 1 "$rc" "un identifiant non préfixé par son type fait échouer"
  assert_contains '« diagram- » attendu (AD-6)' "$err" "le signalement donne le préfixe attendu"
}

case_content_c7_ready_sans_source() {
  rendu '.files[2].material[0].status = "ready"'
  contenu
  assert_eq 1 "$rc" "un élément ready sans source fait échouer"
  assert_contains "en status ready sans source : assets/diagrams/diagram-essai.fr.svg est absent" "$err" \
    "le signalement donne le chemin attendu, dans la langue du fichier"
  rendu '.files[2].material[0].status = "ready" | .files[2].material[0].source_found = true'
  contenu
  assert_eq 0 "$rc" "avec sa source, l'élément passe (messages : $err)"
}

case_content_c7_video_sans_url() {
  rendu '.files[2].material[0] = {"id": "video-essai", "type": "video", "status": "ready", "source": "", "source_found": false} | .files[2].placed = ["video-essai"]'
  contenu
  assert_eq 1 "$rc" "une vidéo ready sans url fait échouer"
  assert_contains "C7 : vidéo « video-essai » en status ready sans url" "$err" "le message est propre à la vidéo"
}

case_content_c8_group_different_du_dossier() {
  rendu '.files[2].front_matter.group = "autre"'
  contenu
  assert_eq 1 "$rc" "une clé group qui ne suit pas le dossier fait échouer"
  assert_contains 'C8 : clé group « autre » alors que le dossier est « groupe »' "$err" "le signalement donne les deux"
}

case_content_c8_cas_autonome_avec_group() {
  rendu '.files[2].file = "cases/case-05-essai.fr.md"' '.files[2].file = "cases/case-05-essai.en.md"'
  contenu
  assert_eq 1 "$rc" "un cas hors dossier de groupe ne porte pas de clé group"
  assert_contains "cas hors d'un dossier de groupe mais porteur d'une clé group" "$err" "le signalement le dit"
}

case_content_c8_cas_trop_profond() {
  rendu '.files[2].file = "cases/groupe/sous/case-09-essai.fr.md"' '.files[2].file = "cases/groupe/sous/case-09-essai.en.md"'
  contenu
  assert_eq 1 "$rc" "un cas rangé trop profond fait échouer"
  assert_contains "C8 : cas rangé trop profond" "$err" "le signalement renvoie à AD-4"
}

case_content_c8_order_en_double() {
  rendu '.files += [(.files[2] | .file = "cases/groupe/case-10-essai.fr.md" | .translationKey = "case-10")]' \
        '.files += [(.files[2] | .file = "cases/groupe/case-10-essai.en.md" | .translationKey = "case-10")]'
  contenu
  assert_eq 1 "$rc" "deux cas du même groupe avec le même order font échouer"
  assert_contains "C8 : order 1 déjà pris dans le groupe « groupe »" "$err" "le signalement nomme les deux fichiers"
}

case_content_c7_type_inconnu() {
  rendu '.files[2].material[0] = {"id": "image-essai", "type": "image", "status": "planned", "source": "", "source_found": false} | .files[2].placed = ["image-essai"]'
  contenu
  assert_eq 1 "$rc" "un type hors d'AD-6 fait échouer (constat de la revue de la PR n° 40)"
  assert_contains 'de type « image » ; attendu diagram, video, snippet ou callout' "$err" "le signalement liste les types"
}

case_content_c8_order_absent() {
  rendu 'del(.files[2].front_matter.order)' 'del(.files[2].front_matter.order)'
  contenu
  assert_eq 1 "$rc" "un cas sans order fait échouer"
  assert_contains "C8 : clé order absente" "$err" "le signalement le dit, plutôt qu'une collision sur null"
  assert_eq "" "$(grep -c "déjà pris" <<< "$err" | tr -d '0')" "aucun message de doublon sur une clé absente"
}

case_content_c16_resume_trop_long() {
  rendu '.files[2].front_matter.summary = ("x" * 401)'
  contenu
  assert_eq 1 "$rc" "un « En bref » de plus de 400 points de code fait échouer"
  assert_contains "C16 : « En bref » de 401 points de code" "$err" "le signalement donne la mesure"
}

case_content_c16_quatre_phrases() {
  rendu '.files[2].front_matter.summary = "Une. Deux. Trois. Quatre."'
  contenu
  assert_eq 1 "$rc" "quatre phrases font échouer"
  assert_contains "4 phrase(s) ; au plus 400 et 3" "$err" "le compte des phrases suit la définition de C16"
}

case_content_c16_trois_phrases_passent() {
  # « … » termine une phrase, comme « . », « ! » et « ? » (définition de C16) : la chaîne ci-dessous
  # en compte donc exactement trois.
  rendu '.files[2].front_matter.summary = "Une première phrase ! Une deuxième ? Une troisième…"'
  contenu
  assert_eq 0 "$rc" "trois phrases terminées par !, ? et … passent (messages : $err)"
}

case_content_c16_todo_dans_un_brouillon() {
  rendu '.files[2].front_matter.summary = ("[TODO: résumé " + ("x" * 500))'
  contenu
  assert_eq 0 "$rc" "un résumé en [TODO passe dans un brouillon (messages : $err)"
}

case_content_c18_title_trop_long() {
  rendu '.files[2].front_matter.title = ("T" * 71)'
  contenu
  assert_eq 1 "$rc" "un title de plus de 70 caractères fait échouer"
  assert_contains "C18 : title de 71 caractères ; 70 au plus" "$err" "le signalement donne la longueur"
}

case_content_c18_setup_hors_valeurs() {
  rendu '.files[2].front_matter.context.setup = "stagiaire"'
  contenu
  assert_eq 1 "$rc" "un setup hors valeurs fait échouer"
  assert_contains "attendu employee, freelance, agency ou ton-pote-le-geek" "$err" "le signalement liste les valeurs"
}

case_content_c18_status_hors_valeurs() {
  rendu '.files[2].material[0].status = "brouillon"'
  contenu
  assert_eq 1 "$rc" "un status hors valeurs fait échouer"
  assert_contains "attendu planned ou ready" "$err" "le signalement liste les valeurs"
}

case_content_c18_numero_incoherent() {
  rendu '.files[2].front_matter.number = "07"'
  contenu
  assert_eq 1 "$rc" "un number qui ne suit pas le nom de fichier fait échouer"
  assert_contains 'numéro « 09 » dans le nom de fichier, number « 07 »' "$err" "le signalement donne les deux"
  rendu '.files[2].translationKey = "case-07"' '.files[2].translationKey = "case-07"'
  contenu
  assert_eq 1 "$rc" "un translationKey qui ne suit pas le nom de fichier fait échouer aussi"
  assert_contains 'translationKey « case-07 »' "$err" "le signalement le dit"
}

case_content_c18_encart_incomplet() {
  rendu '.files[2].draft = false | .files[2].todo = false | del(.files[2].front_matter.context.role)' \
        '.files[2].draft = false | .files[2].todo = false'
  contenu
  assert_eq 1 "$rc" "un cas publié sans rôle dans son encart fait échouer (FR-6)"
  assert_contains "C18 : context.role absent ou vide (FR-6)" "$err" "le signalement nomme la clé"
  rendu '.files[2].front_matter.context.role = "[TODO: rôle]"'
  contenu
  assert_eq 0 "$rc" "la même clé en [TODO passe dans un brouillon (messages : $err)"
}

case_content_c18_encart_todo_publie() {
  rendu '.files[2].draft = false | .files[2].todo = false | .files[2].front_matter.context.period = "[TODO: période]"' \
        '.files[2].draft = false | .files[2].todo = false'
  contenu
  assert_eq 1 "$rc" "un [TODO d'encart dans un cas publié fait échouer"
  assert_contains "encore en [TODO dans un cas publié" "$err" "le signalement le dit"
}

case_content_c18_nom_de_fichier_hors_format() {
  # « capture » ne produit rien sur un nom hors format : sans règle propre, le cas passait en silence
  # (constat de la revue de la PR n° 41).
  rendu '.files[2].file = "cases/groupe/essai.fr.md"' '.files[2].file = "cases/groupe/essai.en.md"'
  contenu
  assert_eq 1 "$rc" "un nom de fichier hors format fait échouer"
  assert_contains "C18 : nom de fichier hors format ; attendu case-NN-<nom-court>.<langue>.md" "$err" \
    "le signalement donne le format attendu"
}

# Les deux fichiers d'environnement sont lus dans le dépôt, pas dans le manifeste : ces cas travaillent
# donc sur une copie du dépôt, avec le contrôle lancé depuis cette copie.
copie_depot() {
  mkdir -p "$work/depot/scripts/checks" "$work/depot/ci"
  cp "$root/scripts/checks/content.sh" "$root/scripts/checks/lib.sh" "$work/depot/scripts/checks/"
  cp "$root/.env.example" "$work/depot/"
  cp "$root/ci/legal-placeholder.env" "$work/depot/ci/"
  mkdir -p "$work/depot/rendu/en"
  jq . "$fixtures/manifests/fr.json" > "$work/depot/rendu/checks.json"
  jq . "$fixtures/manifests/en.json" > "$work/depot/rendu/en/checks.json"
}

contenu_depot() {
  run env CHECK_WORK_ROOT="$work/depot/rendu" bash -c 'cd "$1" && bash scripts/checks/content.sh' _ "$work/depot"
}

case_content_c18_fichiers_env_conformes() {
  copie_depot
  contenu_depot
  assert_eq 0 "$rc" "les deux fichiers du dépôt passent (messages : $err)"
}

case_content_c18_env_example_incomplet() {
  copie_depot
  grep -v '^GITEA_USER=' "$root/.env.example" > "$work/depot/.env.example"
  contenu_depot
  assert_eq 1 "$rc" "une variable manquante dans .env.example fait échouer"
  assert_contains ".env.example: C18 : variables" "$err" "le signalement nomme le fichier"
  assert_contains "GITEA_USER" "$err" "les noms attendus sont affichés"
  [[ $err != *"="* ]] || { echo "une valeur a pu être affichée" >&2; exit 1; }
}

case_content_c18_legal_placeholder_en_trop() {
  copie_depot
  printf 'HUGO_LEGAL_EXTRA=VALEUR-FACTICE-extra\n' >> "$work/depot/ci/legal-placeholder.env"
  contenu_depot
  assert_eq 1 "$rc" "une variable en trop dans le fichier factice fait échouer"
  assert_contains "ci/legal-placeholder.env: C18 : variables" "$err" "le signalement nomme le fichier"
}

case_content_c18_fichier_env_absent() {
  copie_depot
  rm "$work/depot/.env.example"
  contenu_depot
  assert_eq 1 "$rc" "un fichier d'environnement absent fait échouer"
  assert_contains ".env.example: C18 : fichier absent" "$err" "le signalement le dit"
}

case_content_entree_en_erreur_ignoree() {
  rendu '.files[2].error = "front matter absent"'
  contenu
  assert_eq 0 "$rc" "une entrée en erreur relève de la parité, pas du contenu (messages : $err)"
}

run_case "$@"
