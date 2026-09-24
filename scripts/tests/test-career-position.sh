#!/usr/bin/env bash
# Le nom affiché d'un poste sur l'accueil (story 10.2, AD-18, `_partials/position.html`).
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
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
script_name=test-career-position
. "$root/scripts/lib/tools.sh"

# Écrit un poste dans le site d'essai. $1 = langue, $2 = identifiant, $3… = lignes de front matter
# ajoutées telles quelles (`company`, `label`, `company_url`…).
poste() { # $1 = langue, $2 = identifiant, $3… = clés supplémentaires
  local langue=$1 id=$2; shift 2
  local fichier="$work/site/content/career/position-$id.$langue.md"
  mkdir -p "$(dirname "$fichier")"
  {
    printf -- '---\ntranslationKey: position-%s\n' "$id"
    local ligne
    for ligne in "$@"; do printf '%s\n' "$ligne"; done
    printf 'role: "Rôle"\nperiod: "2024"\nsetup: "employee"\ntrack: "main"\norder: 1\ndraft: false\n---\n\nCorps.\n'
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

run_case "$@"
