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
  mkdir -p "$work/depot/scripts/checks" "$work/depot/scripts/lib" "$work/depot/ci"
  cp "$root/scripts/checks/content.sh" "$root/scripts/checks/lib.sh" "$work/depot/scripts/checks/"
  # lib.sh charge les enveloppes communes du dépôt : le dépôt d'essai les emporte aussi
  cp "$root/scripts/lib/shell.sh" "$work/depot/scripts/lib/"
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

case_content_c19_cas_publie_sans_position() {
  rendu '.files[2] |= (.draft = false | .todo = false | del(.front_matter.position))' \
        '.files[2] |= (.draft = false | .todo = false | del(.front_matter.position))'
  contenu
  assert_eq 1 "$rc" "un cas publié sans position fait échouer"
  assert_contains "C19 : cas publié sans clé position (AD-18)" "$err" "le signalement le dit"
}

case_content_c19_poste_en_brouillon() {
  rendu '.files[2] |= (.draft = false | .todo = false)' '.files[2] |= (.draft = false | .todo = false)'
  contenu
  assert_eq 1 "$rc" "un cas publié rattaché à un poste en brouillon fait échouer"
  assert_contains "aucun poste publié de cette langue ne porte ce translationKey" "$err" "le signalement le dit"
  rendu '.files[2] |= (.draft = false | .todo = false) | .files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026")' \
        '.files[2] |= (.draft = false | .todo = false) | .files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026")'
  contenu
  assert_eq 0 "$rc" "avec son poste publié, le cas passe (messages : $err)"
}

case_content_c19_translation_key_du_poste() {
  rendu '.files[1].translationKey = "position-autre"'
  contenu
  assert_eq 1 "$rc" "un translationKey qui ne suit pas le nom de fichier fait échouer"
  assert_contains 'le nom de fichier dit « position-essai » (AD-18)' "$err" "le signalement donne le nom attendu"
  rendu '.files[1].translationKey = "essai" | .files[1].file = "career/essai.fr.md"' \
        '.files[1].translationKey = "essai" | .files[1].file = "career/essai.en.md"'
  contenu
  assert_eq 1 "$rc" "un translationKey sans le préfixe position- fait échouer"
  assert_contains 'préfixe « position- » attendu (AD-18)' "$err" "le signalement donne le préfixe"
}

case_content_c19_url_de_societe() {
  # « company_url » est facultative : son absence ne dit rien. Présente, elle fait du nom de la
  # société un lien, et une valeur relative ou vide donnerait un lien mort qu'aucun contrôle ne
  # verrait — C12 ne lit que les liens internes (clé ajoutée le 21/09/2026, story 5.2).
  rendu '.files[1].front_matter.company_url = "https://exemple.invalid/"' \
        '.files[1].front_matter.company_url = "https://exemple.invalid/"'
  contenu
  assert_eq 0 "$rc" "une adresse absolue en https:// passe (messages : $err)"

  rendu '.files[1].front_matter.company_url = "exemple.invalid"' \
        '.files[1].front_matter.company_url = "exemple.invalid"'
  contenu
  assert_eq 1 "$rc" "une adresse sans protocole fait échouer"
  assert_contains 'C19 : company_url « exemple.invalid »' "$err" "le signalement cite la valeur"

  rendu '.files[1].front_matter.company_url = ""' '.files[1].front_matter.company_url = ""'
  contenu
  assert_eq 1 "$rc" "une valeur vide fait échouer"
  assert_contains 'company_url présente mais vide' "$err" "le signalement distingue le vide de la valeur fausse"

  rendu '.files[1].front_matter.company_url = "http://exemple.invalid/"' \
        '.files[1].front_matter.company_url = "http://exemple.invalid/"'
  contenu
  assert_eq 1 "$rc" "http:// sans TLS fait échouer aussi"

  # Le protocole seul passait le test du préfixe (constat de la revue de la PR n° 67).
  rendu '.files[1].front_matter.company_url = "https://"' '.files[1].front_matter.company_url = "https://"'
  contenu
  assert_eq 1 "$rc" "le protocole sans hôte fait échouer"
  assert_contains 'avec un hôte est attendue' "$err" "le signalement dit ce qui manque"
}

case_content_c19_valeurs_du_poste() {
  rendu '.files[1].front_matter.track = "annexe"'
  contenu
  assert_eq 1 "$rc" "un track hors valeurs fait échouer"
  assert_contains 'C19 : track « annexe » ; attendu main ou parallel' "$err" "le signalement liste les valeurs"
  # AD-10 et le critère de la story : un brouillon peut porter la valeur en [TODO (constat de la
  # deuxième revue de la PR n° 42, où track faisait exception à sa propre règle).
  rendu '.files[1].front_matter.track = "[TODO: track]"' '.files[1].front_matter.track = "[TODO: track]"'
  contenu
  assert_eq 0 "$rc" "un track en [TODO passe dans un brouillon (messages : $err)"
  rendu '.files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026" | .front_matter.track = "[TODO: track]")' \
        '.files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026" | .front_matter.track = "[TODO: track]")'
  contenu
  assert_eq 1 "$rc" "le même track en [TODO ne passe pas dans un poste publié"
  rendu 'del(.files[1].front_matter.track)' 'del(.files[1].front_matter.track)'
  contenu
  assert_eq 1 "$rc" "un track absent fait échouer"
  assert_contains "C19 : track absent ou vide" "$err" "le signalement distingue l'absence d'une valeur fausse"
  rendu 'del(.files[1].front_matter.setup)' 'del(.files[1].front_matter.setup)'
  contenu
  assert_eq 1 "$rc" "un poste sans location ni setup fait échouer"
  assert_contains "ni location ni setup" "$err" "le signalement renvoie à FR-2"
  rendu 'del(.files[1].front_matter.setup) | .files[1].front_matter.location = "Full remote"' \
        'del(.files[1].front_matter.setup) | .files[1].front_matter.location = "Full remote"'
  contenu
  assert_eq 0 "$rc" "une location seule suffit (messages : $err)"
}

case_content_c19_order_en_double() {
  rendu '.files += [(.files[1] | .file = "career/position-autre.fr.md" | .translationKey = "position-autre")]' \
        '.files += [(.files[1] | .file = "career/position-autre.en.md" | .translationKey = "position-autre")]'
  contenu
  assert_eq 1 "$rc" "deux postes du même track au même order font échouer, brouillons compris"
  assert_contains 'C19 : order 1 déjà pris dans le track « main »' "$err" "le signalement nomme les deux fichiers"
}

case_content_c19_formation() {
  rendu '.files += [{"file": "education/education-essai.fr.md", "lang": "fr", "kind": "page", "role": "education", "translationKey": "education-essai", "draft": false, "front_matter": {"translationKey": "education-essai", "kind": "diplome", "order": 1}, "headings": [], "placed": [], "material": [], "todo": false}]' \
        '.files += [{"file": "education/education-essai.en.md", "lang": "en", "kind": "page", "role": "education", "translationKey": "education-essai", "draft": false, "front_matter": {"translationKey": "education-essai", "kind": "diplome", "order": 1}, "headings": [], "placed": [], "material": [], "todo": false}]'
  contenu
  assert_eq 1 "$rc" "une formation sans title et au kind inconnu fait échouer"
  assert_contains "C19 : title absent ou vide (AD-18)" "$err" "le title manquant est signalé"
  assert_contains 'C19 : kind « diplome » ; attendu education, certification ou language' "$err" "le kind est signalé"
}

case_content_c19_cles_obligatoires_du_poste() {
  # Constat de la revue de la PR n° 42 : ces clés n'avaient pas de cas de test — elles étaient trois ; « company » en est sortie à la story 10.2, pour son tamis propre.
  local cle
  for cle in role period; do
    rendu "del(.files[1].front_matter.$cle)" "del(.files[1].front_matter.$cle)"
    contenu
    assert_eq 1 "$rc" "un poste sans $cle fait échouer"
    assert_contains "C19 : $cle absent ou vide (AD-18)" "$err" "le signalement nomme la clé $cle"
  done
}

# « company » ou « label » : la clé « label » nomme un poste qui n'est pas une société (AD-18,
# 24/09/2026). Elle rend « company » facultative, ce qui ouvrirait un poste sans aucun nom : la
# règle porte donc sur le couple, et ces cas l'éprouvent des deux côtés — ce que le critère de la
# story exige (point 9 d'AGENTS.md).
case_content_c19_company_ou_label() {
  # 1. « label » seule suffit : c'est « Parcours antérieur », qui n'a pas de société.
  rendu 'del(.files[1].front_matter.company) | .files[1].front_matter.label = "Parcours antérieur"' \
        'del(.files[1].front_matter.company) | .files[1].front_matter.label = "Earlier career"'
  contenu
  assert_eq 0 "$rc" "un poste à label seule passe (messages : $err)"

  # 2. Ni l'une ni l'autre : le poste sortirait avec un titre vide.
  rendu 'del(.files[1].front_matter.company)' 'del(.files[1].front_matter.company)'
  contenu
  assert_eq 1 "$rc" "un poste sans company ni label fait échouer"
  assert_contains "C19 : ni company ni label ne nomme le poste" "$err" "le signalement nomme les deux clés"

  # 3. « company » seule reste valable : rien n'est demandé aux six postes qui sont des sociétés.
  rendu 'del(.files[1].front_matter.label)' 'del(.files[1].front_matter.label)'
  contenu
  assert_eq 0 "$rc" "un poste à company seule passe toujours (messages : $err)"

  # 4. Une valeur d'espaces ne nomme rien — même tamis que pour les autres clés (report 3.6).
  rendu 'del(.files[1].front_matter.company) | .files[1].front_matter.label = "   "' \
        'del(.files[1].front_matter.company) | .files[1].front_matter.label = "   "'
  contenu
  assert_eq 1 "$rc" "un label fait d'espaces ne remplace pas company"
  assert_contains "C19 : ni company ni label ne nomme le poste" "$err" "le signalement est le même"

  # 5. « label » en [TODO : toléré dans un brouillon (AD-10), refusé une fois le poste publié.
  rendu 'del(.files[1].front_matter.company) | .files[1].front_matter.label = "[TODO: libellé]"' \
        'del(.files[1].front_matter.company) | .files[1].front_matter.label = "[TODO: libellé]"'
  contenu
  assert_eq 0 "$rc" "un label en [TODO passe dans un brouillon (messages : $err)"
  rendu 'del(.files[1].front_matter.company) | .files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026" | .front_matter.label = "[TODO: libellé]")' \
        'del(.files[1].front_matter.company) | .files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026" | .front_matter.label = "[TODO: libellé]")'
  contenu
  assert_eq 1 "$rc" "le même label en [TODO ne nomme rien dans un poste publié"

  # 6. Une clé **présente mais vide** est refusée, même quand l'autre nomme le poste. Ce pas
  #    affirmait le contraire jusqu'au 24/09/2026 : il constatait que le gabarit retombe sur l'autre
  #    clé (« with » ignore une chaîne vide) et en concluait que tout allait bien. C'est justement
  #    ce qui rend la faute invisible — la page s'affiche juste, et rien ne dit que la clé est vide.
  #    Constat de la revue de la PR n° 109, dont la conclusion était fausse (un label vide n'écrase
  #    aucune company) mais dont l'intuition désignait ce trou.
  rendu '.files[1].front_matter.label = ""' '.files[1].front_matter.label = ""'
  contenu
  assert_eq 1 "$rc" "un label présent mais vide est refusé, même à côté d'une company"
  assert_contains "C19 : « label » présente mais vide" "$err" "et le signalement nomme la clé"

  # 7. Le même tamis pour « company », pour qu'aucune des deux n'hérite d'une tolérance que
  #    l'autre n'a pas — c'est la faute que le point 19 d'AGENTS.md décrit sur son plus petit objet.
  rendu '.files[1].front_matter.label = "Parcours antérieur" | .files[1].front_matter.company = ""' \
        '.files[1].front_matter.label = "Earlier career" | .files[1].front_matter.company = ""'
  contenu
  assert_eq 1 "$rc" "une company présente mais vide est refusée, même à côté d'un label"
  assert_contains "C19 : « company » présente mais vide" "$err" "et le signalement nomme l'autre clé"
}

case_content_c19_cles_facultatives_vides() {
  # **Le balayage que la story 10.2 n'avait pas fait.** Elle a posé le tamis « présente mais vide »
  # sur « company » et « label », en citant le point 18 d'AGENTS.md — puis a laissé les cinq autres
  # clés facultatives que « position.html » lit par « with ». Un « location: "" » passait donc sans
  # un mot, même faute et même silence (rétrospective de l'epic 10).
  #
  # Chaque clé a son pas : une liste vérifiée en bloc laisserait passer celle qu'on a oublié
  # d'ajouter à la règle, puisque le cas échouerait déjà sur les autres.
  local cle
  for cle in location setup via; do
    rendu ".files[1].front_matter.$cle = \"\"" ".files[1].front_matter.$cle = \"\""
    contenu
    assert_eq 1 "$rc" "« $cle » présente mais vide est refusée"
    assert_contains "C19 : « $cle » présente mais vide" "$err" "et le signalement nomme « $cle »"
  done
}

case_content_c19_cles_facultatives_vides_formation() {
  # Le même tamis sur une entrée de « content/education/ », qu'« education.html » lit de la même
  # façon. La story 10.3 ne l'avait pas non plus, la règle de la 10.2 s'étant arrêtée aux postes :
  # c'est le point 19 sur son plus petit objet — deux gabarits jumeaux, une seule garde.
  local cle
  for cle in institution level; do
    rendu ".files[3].front_matter.$cle = \"\"" ".files[3].front_matter.$cle = \"\""
    contenu
    assert_eq 1 "$rc" "« $cle » présente mais vide est refusée dans une formation"
    assert_contains "C19 : « $cle » présente mais vide" "$err" "et le signalement nomme « $cle »"
  done
}

case_content_c19_order_absent() {
  rendu 'del(.files[1].front_matter.order)' 'del(.files[1].front_matter.order)'
  contenu
  assert_eq 1 "$rc" "un poste sans order fait échouer"
  assert_contains "C19 : clé order absente" "$err" "le signalement le dit, plutôt qu'un doublon sur null"
}

case_content_c19_formation_order_en_double() {
  local entree='{"file": "education/education-a.LANG.md", "lang": "LANG", "kind": "page", "role": "education", "translationKey": "education-a", "draft": false, "front_matter": {"translationKey": "education-a", "title": "Titre", "kind": "certification", "order": 1}, "headings": [], "placed": [], "material": [], "todo": false}'
  local fr=${entree//LANG/fr} en=${entree//LANG/en}
  rendu ".files += [$fr, ($fr | .file = \"education/education-b.fr.md\" | .front_matter.translationKey = \"education-b\" | .translationKey = \"education-b\")]" \
        ".files += [$en, ($en | .file = \"education/education-b.en.md\" | .front_matter.translationKey = \"education-b\" | .translationKey = \"education-b\")]"
  contenu
  assert_eq 1 "$rc" "deux formations du même kind au même order font échouer"
  assert_contains 'C19 : order 1 déjà pris pour le kind « certification »' "$err" "le signalement nomme le kind"
}

case_content_c18_valeur_faite_despaces() {
  # Report de la story 3.6 : « non vide » ne suffit pas, une valeur d'espaces ne renseigne rien.
  rendu '.files[2] |= (.draft = false | .todo = false | .front_matter.context.role = "   ")' \
        '.files[2] |= (.draft = false | .todo = false)'
  contenu
  assert_eq 1 "$rc" "une valeur faite uniquement d'espaces ne renseigne rien"
  assert_contains "C18 : context.role absent ou vide (FR-6)" "$err" "le signalement est le même qu'une clé absente"
}

# Un brouillon tolère la valeur « [TODO » pour toute règle de forme (AD-10). Ce cas passe en revue
# toutes les clés concernées d'un coup : les trois blocages successifs de la PR n° 42 venaient de
# règles qui faisaient exception chacune à son tour.
case_content_todo_tolere_partout_dans_un_brouillon() {
  rendu '.files[1] |= (.front_matter.track = "[TODO: track]" | .front_matter.setup = "[TODO: cadre]")
         | .files[2] |= (.front_matter.number = "[TODO: numéro]" | .front_matter.group = "[TODO: groupe]"
                         | .front_matter.context.setup = "[TODO: cadre]"
                         | .material[0].type = "[TODO: type]" | .material[0].status = "[TODO: statut]")' \
        '.files[1] |= (.front_matter.track = "[TODO: track]" | .front_matter.setup = "[TODO: cadre]")
         | .files[2] |= (.front_matter.number = "[TODO: numéro]" | .front_matter.group = "[TODO: groupe]"
                         | .front_matter.context.setup = "[TODO: cadre]"
                         | .material[0].type = "[TODO: type]" | .material[0].status = "[TODO: statut]")'
  contenu
  assert_eq 0 "$rc" "toutes ces clés en [TODO passent dans un brouillon (messages : $err)"
}

case_content_todo_refuse_dans_un_fichier_publie() {
  rendu '.files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026" | .front_matter.setup = "[TODO: cadre]")' \
        '.files[1] |= (.draft = false | .front_matter.draft = false | .front_matter.period = "2025 – 2026" | .front_matter.setup = "[TODO: cadre]")'
  contenu
  assert_eq 1 "$rc" "la même valeur en [TODO est refusée dans un poste publié"
  assert_contains "C19 : setup « [TODO: cadre] »" "$err" "le signalement montre la valeur refusée"
}

case_content_translation_key_jamais_en_todo() {
  # La tolérance des brouillons porte sur les valeurs de contenu, jamais sur la clé d'identité :
  # le translationKey est égal au nom du fichier et sert à la parité (décidé le 18/09/2026).
  rendu '.files[1].translationKey = "[TODO: clé]" | .files[1].front_matter.translationKey = "[TODO: clé]"' \
        '.files[1].translationKey = "[TODO: clé]" | .files[1].front_matter.translationKey = "[TODO: clé]"'
  contenu
  assert_eq 1 "$rc" "un translationKey en [TODO est refusé, même dans un brouillon"
  assert_contains "le nom de fichier dit « position-essai » (AD-18)" "$err" "le signalement donne le nom attendu"
}

case_content_c19_kind_en_todo() {
  local base='{"file": "education/education-a.LANG.md", "lang": "LANG", "kind": "page", "role": "education", "translationKey": "education-a", "draft": true, "front_matter": {"translationKey": "education-a", "title": "Titre", "kind": "[TODO: nature]", "order": 1}, "headings": [], "placed": [], "material": [], "todo": true}'
  rendu ".files += [${base//LANG/fr}]" ".files += [${base//LANG/en}]"
  contenu
  assert_eq 0 "$rc" "un kind en [TODO passe dans un brouillon (messages : $err)"
  rendu ".files += [$(sed 's/"draft": true/"draft": false/g' <<< "${base//LANG/fr}")]" \
        ".files += [$(sed 's/"draft": true/"draft": false/g' <<< "${base//LANG/en}")]"
  contenu
  assert_eq 1 "$rc" "le même kind en [TODO est refusé une fois publié"
}

case_content_c19_order_en_todo_ne_collisionne_pas() {
  rendu '.files += [(.files[1] | .file = "career/position-autre.fr.md" | .translationKey = "position-autre" | .front_matter.translationKey = "position-autre" | .front_matter.order = "[TODO: ordre]")]
         | .files[1].front_matter.order = "[TODO: ordre]"' \
        '.files += [(.files[1] | .file = "career/position-autre.en.md" | .translationKey = "position-autre" | .front_matter.translationKey = "position-autre" | .front_matter.order = "[TODO: ordre]")]
         | .files[1].front_matter.order = "[TODO: ordre]"'
  contenu
  assert_eq 0 "$rc" "deux brouillons dont l'order est en [TODO ne se télescopent pas (messages : $err)"
}

case_content_entree_en_erreur_ignoree() {
  rendu '.files[2].error = "front matter absent"'
  contenu
  assert_eq 0 "$rc" "une entrée en erreur relève de la parité, pas du contenu (messages : $err)"
}

run_case "$@"
