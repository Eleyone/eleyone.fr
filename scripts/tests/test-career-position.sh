#!/usr/bin/env bash
# Le nom affiché d'un poste sur l'accueil (story 10.2, AD-18, `_partials/position.html`), puis le
# contexte de sa mission — secteur, périmètre et bloc « Stack » (story 10.9), en fin de fichier.
#
# La clé `label` nomme un poste qui n'est **pas** une société — « Parcours antérieur » —, passe
# devant `company` quand elle est là, et se traduit. Aucune de ces trois phrases ne se relit dans le
# gabarit : la priorité entre deux clés, le repli sur l'autre et le lien construit autour du nom ne
# se constatent que dans la sortie de Hugo. C'est le pendant, au niveau du rendu, des cas de
# `test-content.sh` (C19 exige l'une des deux) et de `test-parity.sh` (C3 ne compare pas `label`).
#
# Le site d'essai n'emprunte au dépôt que ses gabarits, sa configuration, ses données et ses
# libellés : le contenu est écrit par chaque cas, pour que le résultat ne dépende jamais de l'état
# de `content/career/` — qui change à chaque poste publié.
. "$(dirname "${BASH_SOURCE[0]}")/../../.working-method/tests/lib.sh"
script_name=test-career-position
. "$root/scripts/lib/tools.sh"

# Écrit un poste dans le site d'essai. $1 = langue, $2 = identifiant, $3… = lignes de front matter
# ajoutées telles quelles (`company`, `label`, `company_url`…). Le corps vient de POSTE_CORPS.
poste() { # $1 = langue, $2 = identifiant, $3… = clés supplémentaires
  local langue=$1 id=$2; shift 2
  local fichier="$work/site/content/career/position-$id.$langue.md"
  mkdir -p "$(dirname "$fichier")"
  {
    printf -- '---\ntranslationKey: position-%s\n' "$id"
    local ligne
    for ligne in "$@"; do printf '%s\n' "$ligne"; done
    printf 'role: "Rôle"\nperiod: "2024"\nsetup: "employee"\ntrack: "main"\norder: 1\ndraft: false\n---\n\n'
    # Le corps vaut « Corps. » par défaut ; POSTE_CORPS le remplace, vide ou fait de blancs compris.
    printf '%s\n' "${POSTE_CORPS-Corps.}"
  } > "$fichier"
}

# Construit le site d'essai. Les postes sont posés avant l'appel, par `poste`.
preparer() {
  load_tools_env "$root/tools.env"
  local tools_dir=${TOOLS_LOCAL_DIR:-$root/.tools}
  [[ ! -d $tools_dir ]] || PATH="$tools_dir:$PATH"
  export PATH
  require_tool_version hugo hugo "$HUGO_VERSION" || exit 2
  rm -rf "$work/site"
  mkdir -p "$work/site/content/career" "$work/site/assets"
  cp -r "$root/layouts" "$root/config" "$root/data" "$root/i18n" "$work/site/"
  cp -r "$root/assets/css" "$work/site/assets/"
  printf -- '---\ntitle: "Accueil"\nidentity: "Essai · Pseudo"\njob_title: "Essai"\n---\n' > "$work/site/content/_index.fr.md"
  printf -- '---\ntitle: "Home"\nidentity: "Essai · Pseudo"\njob_title: "Test"\n---\n' > "$work/site/content/_index.en.md"
}

construire() {
  (cd "$work/site" && hugo --environment production --minify --destination sortie) > "$work/hugo.out" 2>&1
}

page() { cat "$work/site/sortie/$1"; }

# Le seul article d'un poste, découpé sur son ancre. La **présence** du repère est affirmée avant
# de couper : « ${x#*motif} » rend la chaîne inchangée quand le motif manque, et la fonction
# aurait rendu la page entière (constat de la revue de la PR n° 100).
poste_de() { # $1 = page, $2 = identifiant
  local html repere="id=position-$2>"
  html=$(page "$1") || { echo "$1 : page illisible" >&2; return 1; }
  [[ $html == *"$repere"* ]] || { echo "$1 : aucun poste « position-$2 »" >&2; return 1; }
  html=${html#*"$repere"}
  [[ $html == *'</article>'* ]] || { echo "$1 : poste non fermé" >&2; return 1; }
  printf '%s' "${html%%</article>*}"
}

case_position_company_seule_est_affichee() {
  # La contre-épreuve : sans elle, un gabarit qui n'afficherait **jamais** de nom passerait pour un
  # gabarit qui donne la priorité à `label`.
  preparer
  poste fr societe 'company: "Mister Auto"'
  poste en societe 'company: "Mister Auto"'
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_contains '>Mister Auto</h3>' "$(poste_de index.html societe)" "le nom de la société est le titre du poste"
}

case_position_label_seule_est_affichee() {
  # Le premier des deux cas que le critère de la story exige : un poste à `label` seule est accepté
  # **et affiche son libellé**. Sans la clé, le titre serait vide — et un titre vide ne fait
  # échouer aucun autre contrôle.
  preparer
  poste fr earlier-career 'label: "Parcours antérieur"'
  poste en earlier-career 'label: "Earlier career"'
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local fr en
  fr=$(poste_de index.html earlier-career)
  en=$(poste_de en/index.html earlier-career)
  assert_contains '>Parcours antérieur</h3>' "$fr" "le libellé français est le titre du poste"
  assert_contains '>Earlier career</h3>' "$en" "et le libellé anglais sur la page anglaise"
  # Une langue ne dit rien de l'autre : le libellé français ne doit pas traverser.
  [[ $en != *'Parcours antérieur'* ]] || { echo "le libellé français apparaît sur la page anglaise" >&2; exit 1; }
}

case_position_label_prime_sur_company() {
  # La priorité, que le gabarit applique sans la nommer. Un `default` écrit à l'envers donnerait
  # « Société » là où AD-18 veut le libellé, et les deux valeurs étant présentes, rien ne manquerait
  # à l'œil.
  preparer
  poste fr mixte 'company: "Société"' 'label: "Parcours antérieur"'
  poste en mixte 'company: "Société"' 'label: "Earlier career"'
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local titre; titre=$(poste_de index.html mixte)
  assert_contains '>Parcours antérieur</h3>' "$titre" "le libellé passe devant la société"
  [[ $titre != *'Société<'* ]] || { echo "le nom de la société est affiché malgré le libellé" >&2; exit 1; }
}

case_position_label_devient_un_lien_avec_company_url() {
  # `company_url` fait du **nom affiché** un lien (story 5.2). La règle a été écrite quand ce nom
  # était forcément `company` ; elle porte désormais sur celui des deux qui s'affiche, et une
  # reprise distraite aurait laissé un lien vide autour d'un `company` absent.
  preparer
  poste fr lien 'label: "Ton Pote le Geek"' 'company_url: "https://exemple.invalid/"'
  poste en lien 'label: "Ton Pote le Geek"' 'company_url: "https://exemple.invalid/"'
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local titre; titre=$(poste_de index.html lien)
  assert_contains 'href=https://exemple.invalid/>Ton Pote le Geek</a>' "$titre" "le libellé est le texte du lien"
}

# --- contexte de la mission (story 10.9) -----------------------------------------------------------
#
# Arbitrages d'Arnaud du 02/10/2026 : le secteur vient juste après le rôle ; après la liste des cas,
# le corps — toujours visible —, puis la stack seule dans un <details> fermé nommé « Stack » ; ce
# qui n'existe pas n'est pas rendu. Comme pour le nom affiché, rien de cela ne se lit dans le
# gabarit : seul le HTML produit par Hugo le montre.

# Écrit un cas publié rattaché à un poste, dans les deux langues. $1 = identifiant du poste.
cas_publie() { # $1 = identifiant du poste
  local langue titre
  for langue in fr en; do
    if [[ $langue == fr ]]; then titre="Titre du cas d'essai"; else titre="Test case title"; fi
    mkdir -p "$work/site/content/cases"
    printf -- '---\ntitle: "%s"\ntranslationKey: "case-07"\nnumber: "07"\nslug: "essai"\nposition: "position-%s"\norder: 7\ndraft: false\ncontext:\n  company: "Société"\n  setup: "employee"\n  role: "Rôle"\n  period: "2024"\n  stack: ["PHP"]\n---\n\n## Contexte\n\nTexte.\n' \
      "$titre" "$1" > "$work/site/content/cases/case-07-essai.$langue.md"
  done
}

# Position d'une chaîne dans un texte, en octets, ou -1. Sert à vérifier l'ordre des blocs.
rang() { # $1 = texte, $2 = chaîne cherchée
  local avant=${1%%"$2"*}
  if [[ $avant == "$1" ]]; then echo -1; else echo "${#avant}"; fi
}

case_position_contexte_complet_dans_lordre() {
  # Le poste complet : cas, puis corps, puis le bloc « Stack ». L'ordre est celui de l'arbitrage 1 ;
  # un gabarit qui rendrait le corps dans le <details>, ou avant les cas, échoue ici.
  preparer
  POSTE_CORPS="Périmètre de la mission d'essai." poste fr complet 'company: "Société"' 'sector: "Paris sportifs"' 'stack: ["PHP", "Symfony UX"]'
  POSTE_CORPS="Scope of the test mission." poste en complet 'company: "Société"' 'sector: "Sports betting"' 'stack: ["PHP", "Symfony UX"]'
  cas_publie complet
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local langue page article cas corps bloc
  for langue in fr en; do
    page=index.html; [[ $langue == fr ]] || page=en/index.html
    article=$(poste_de "$page" complet)
    cas=$(rang "$article" 'class=attached-case')
    corps=$(rang "$article" 'class=cv-position__content')
    bloc=$(rang "$article" '<details class=cv-position__stack>')
    ((cas >= 0 && corps > cas && bloc > corps)) \
      || { echo "$langue : ordre attendu cas < corps < bloc, constaté $cas, $corps, $bloc" >&2; echo "$article" >&2; exit 1; }
    # Fermé par défaut : aucun attribut « open ».
    [[ $article != *'<details class=cv-position__stack open'* && $article != *' open>'* ]] \
      || { echo "$langue : le bloc est ouvert au chargement" >&2; exit 1; }
    assert_contains '<summary class=label>Stack</summary>' "$article" "$langue : le résumé se nomme « Stack »"
    assert_contains '<ul class=stack><li>PHP</li><li>Symfony UX</li></ul></details>' "$article" \
      "$langue : la stack est la seule chose du bloc, avec la classe des encarts de cas"
    # Le corps est hors du bloc : il est fermé avant que le <details> ne s'ouvre.
    [[ ${article#*'<details class=cv-position__stack>'} != *cv-position__content* ]] \
      || { echo "$langue : le corps est rendu dans le bloc repliable" >&2; exit 1; }
  done
  assert_contains 'Périmètre de la mission d' "$(poste_de index.html complet)" "le corps français est rendu"
  assert_contains 'Scope of the test mission.' "$(poste_de en/index.html complet)" "le corps anglais est rendu"
}

case_position_secteur_apres_le_role() {
  # Arbitrage 2 : rôle · secteur · lieu · cadre · via. Le secteur se traduit, chaque langue a le sien.
  preparer
  poste fr secteur 'company: "Société"' 'sector: "Assurance"' 'location: "Lyon"' 'via: "Modis"'
  poste en secteur 'company: "Société"' 'sector: "Insurance"' 'location: "Lyon, France"' 'via: "Modis"'
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  assert_contains 'Rôle · <span class=cv-position__detail>Assurance</span> · <span class=cv-position__detail>Lyon</span> · <span class=cv-position__detail>Salarié</span> · <span class=cv-position__detail>prestation Modis</span></p>' \
    "$(poste_de index.html secteur)" "le secteur vient juste après le rôle, avant le lieu, le cadre et via"
  assert_contains 'Rôle · <span class=cv-position__detail>Insurance</span> · <span class=cv-position__detail>Lyon, France</span>' \
    "$(poste_de en/index.html secteur)" "et sa traduction sur la page anglaise"
}

case_position_sans_stack_pas_de_bloc() {
  # Arbitrage 3 : sans stack, pas de bloc — ni <details> vide, ni mention. Le corps reste rendu.
  preparer
  poste fr sans-stack 'company: "Société"'
  poste en sans-stack 'company: "Société"'
  cas_publie sans-stack
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local article; article=$(poste_de index.html sans-stack)
  [[ $article != *'<details'* ]] || { echo "un bloc est rendu sans stack" >&2; echo "$article" >&2; exit 1; }
  assert_contains 'class=cv-position__content' "$article" "le corps reste rendu sous les cas"
  assert_contains 'class=attached-case' "$article" "les cas aussi"
}

case_position_corps_blanc_pas_de_perimetre() {
  # Constat A2 de la revue de spec : un corps fait de blancs vaut un corps absent. Le bloc de la
  # stack, lui, reste rendu : chaque partie dépend de ce qu'elle a à montrer.
  preparer
  POSTE_CORPS=$'   \n\t\n' poste fr corps-blanc 'company: "Société"' 'stack: ["PHP"]'
  POSTE_CORPS=$'   \n\t\n' poste en corps-blanc 'company: "Société"' 'stack: ["PHP"]'
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local article; article=$(poste_de index.html corps-blanc)
  [[ $article != *cv-position__content* ]] || { echo "un corps blanc est rendu" >&2; echo "$article" >&2; exit 1; }
  assert_contains '<details class=cv-position__stack>' "$article" "le bloc de la stack est rendu"
}

case_position_ni_corps_ni_stack_rien_apres_les_cas() {
  # Ni l'un ni l'autre : rien après la liste des cas, et aucune mention d'absence.
  preparer
  POSTE_CORPS="" poste fr nu 'company: "Société"'
  POSTE_CORPS="" poste en nu 'company: "Société"'
  cas_publie nu
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local article; article=$(poste_de index.html nu)
  [[ $article != *cv-position__content* && $article != *'<details'* ]] \
    || { echo "un périmètre ou un bloc est rendu pour un poste qui n'a ni corps ni stack" >&2; echo "$article" >&2; exit 1; }
  # Ce qui suit la liste des cas : la fermeture de la liste, puis celle du corps de l'article.
  [[ ${article##*'</ol>'} =~ ^[[:space:]]*'</div>'[[:space:]]*$ ]] \
    || { echo "quelque chose suit la liste des cas : « ${article##*'</ol>'} »" >&2; exit 1; }
}

case_position_corps_rendu_sans_cas() {
  # L'ancienne règle rendait le corps **seulement** sans cas ; la nouvelle le rend toujours. Un poste
  # sans cas publié garde donc son corps, et gagne son bloc si la stack existe.
  preparer
  POSTE_CORPS="Périmètre seul." poste fr seul 'company: "Société"' 'stack: ["PHP"]'
  POSTE_CORPS="Scope only." poste en seul 'company: "Société"' 'stack: ["PHP"]'
  run construire
  assert_eq 0 "$rc" "le build réussit (sortie : $(cat "$work/hugo.out"))"
  local article; article=$(poste_de index.html seul)
  [[ $article != *attached-case* ]] || { echo "une zone de cas est rendue sans cas" >&2; exit 1; }
  assert_contains 'Périmètre seul.' "$article" "le corps est rendu"
  assert_contains '<details class=cv-position__stack>' "$article" "et le bloc de la stack après lui"
}

run_case "$@"
