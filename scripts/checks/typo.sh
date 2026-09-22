#!/usr/bin/env bash
# C24 (AD-23, FR-20, NFR-10) : la typographie française est posée par le build, et seulement sur les
# pages françaises.
#
#   - page FR : aucun nœud de texte ne garde une espace ordinaire devant « ; », « ! », « ? », « : »,
#     après « « » ni avant « » » — ni une insécable **qui n'est pas la sienne** : U+00A0 là où
#     DESIGN.md veut la fine U+202F, ou l'inverse devant « : ». Le partial les corrige toutes ;
#   - page EN : aucune espace insécable (U+00A0) ni fine insécable (U+202F) **à ces mêmes places**.
#     Ailleurs elles sont légitimes dans les deux langues — le séparateur « · » de la ligne
#     d'identité en porte une, que DESIGN.md prescrit sans distinction de langue ;
#   - la feuille de style ne contient aucun « hyphens: auto » (UX-DR17).
#
# Les nœuds de texte sont extraits par XPath, hors « pre », « code », « script » et « style » : un
# grep sur le HTML verrait les attributs, où un « href="mailto:…" » n'a rien de fautif. Une URL en
# texte brut n'a pas d'espace devant ses « : », donc rien à signaler.
#
# Le contrôle lit **les deux rendus**, comme C10 et C11 depuis la story 6.2 : les six cas sont en
# brouillon, donc la production ne contient que les deux accueils, et une page de cas mal composée
# n'y serait pas vue.
#
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=typo
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

public=${CHECK_PUBLIC_ROOT:-public}
[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
travail=${CHECK_WORK_ROOT:-build/work}
racines=("$public")
[[ ! -d $travail || $travail -ef $public ]] || racines+=("$travail")
command -v xmllint > /dev/null 2>&1 \
  || checks_die "xmllint est introuvable (paquet libxml2-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1)."

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# Espace fine insécable U+202F et espace insécable U+00A0, nommées une fois.
readonly fine=$' '
readonly insecable=$' '

# Les nœuds de texte d'une page, hors blocs de code et de script.
texte_de() { # $1 = fichier
  checks_xpath "$1" '//text()[not(ancestor::pre) and not(ancestor::code) and not(ancestor::script) and not(ancestor::style)]'
}

# La langue d'une page, lue sur <html lang="…"> plutôt que déduite du chemin : c'est ce que le
# navigateur et les lecteurs d'écran lisent, donc la seule source qui fasse foi.
langue_de() { # $1 = fichier
  checks_attributes "$1" '//html/@lang' lang | head -1
}

liste_24=$(checks_find "${racines[@]}" -type f -name '*.html' | LC_ALL=C sort) || exit $?
[[ -n $liste_24 ]] || checks_die "aucune page HTML dans ${racines[*]} : rien à contrôler."

while IFS= read -r page; do
  relative=${page#"$public"/}
  relative=${relative#"$travail"/}
  langue=$(langue_de "$page") || exit $?
  texte=$(texte_de "$page") || exit $?
  [[ -n $texte ]] || continue

  if [[ $langue == fr ]]; then
    # Chaque place est nommée séparément : « devant eux » ne veut rien dire pour une paire de
    # guillemets, et le message doit dire quoi corriger (constat de la revue de spec).
    #
    # Une insécable **mal choisie** est un écart au même titre qu'une espace ordinaire : U+00A0
    # devant un « ? » là où DESIGN.md veut U+202F donne un texte qui paraît composé et ne l'est
    # pas, et le contrôle ne le voyait pas (constat de la revue du code de la PR n° 81). Chaque
    # signe refuse donc l'espace ordinaire **et** l'insécable qui n'est pas la sienne.
    for signe in ';' '!' '?'; do
      ! shell_grep -qF -- " $signe" <<< "$texte" \
        || signaler "$relative" "C24 : espace ordinaire devant « $signe » sur une page FR ; typo-fr.html ne l'a pas composée"
      ! shell_grep -qF -- "$insecable$signe" <<< "$texte" \
        || signaler "$relative" "C24 : espace insécable U+00A0 devant « $signe » sur une page FR ; DESIGN.md y veut une fine U+202F"
    done
    ! shell_grep -qF -- ' :' <<< "$texte" \
      || signaler "$relative" "C24 : espace ordinaire devant « : » sur une page FR ; typo-fr.html ne l'a pas composée"
    ! shell_grep -qF -- "$fine:" <<< "$texte" \
      || signaler "$relative" "C24 : espace fine U+202F devant « : » sur une page FR ; DESIGN.md y veut une insécable U+00A0"
    ! shell_grep -qF -- '« ' <<< "$texte" \
      || signaler "$relative" "C24 : espace ordinaire après « « » sur une page FR"
    ! shell_grep -qF -- "«$insecable" <<< "$texte" \
      || signaler "$relative" "C24 : espace insécable U+00A0 après « « » sur une page FR ; DESIGN.md y veut une fine U+202F"
    ! shell_grep -qF -- ' »' <<< "$texte" \
      || signaler "$relative" "C24 : espace ordinaire avant « » » sur une page FR"
    ! shell_grep -qF -- "$insecable»" <<< "$texte" \
      || signaler "$relative" "C24 : espace insécable U+00A0 avant « » » sur une page FR ; DESIGN.md y veut une fine U+202F"
  else
    for signe in ';' '!' '?' ':'; do
      ! shell_grep -qF -- "$fine$signe" <<< "$texte" \
        || signaler "$relative" "C24 : espace fine insécable devant « $signe » sur une page $langue"
      ! shell_grep -qF -- "$insecable$signe" <<< "$texte" \
        || signaler "$relative" "C24 : espace insécable devant « $signe » sur une page $langue"
    done
    # Les deux espèces, aux deux places : la branche anglaise n'en vérifiait qu'une sur les
    # guillemets (constat de la revue du code de la PR n° 81).
    ! shell_grep -qF -- "«$fine" <<< "$texte" \
      || signaler "$relative" "C24 : espace fine insécable après « « » sur une page $langue"
    ! shell_grep -qF -- "«$insecable" <<< "$texte" \
      || signaler "$relative" "C24 : espace insécable après « « » sur une page $langue"
    ! shell_grep -qF -- "$fine»" <<< "$texte" \
      || signaler "$relative" "C24 : espace fine insécable avant « » » sur une page $langue"
    ! shell_grep -qF -- "$insecable»" <<< "$texte" \
      || signaler "$relative" "C24 : espace insécable avant « » » sur une page $langue"
  fi
done <<< "$liste_24"

# --- césure automatique interdite (UX-DR17) -------------------------------------------------------
liste_25=$(checks_find "${racines[@]}" -type f -name '*.css' | LC_ALL=C sort) || exit $?
while IFS= read -r feuille; do
  [[ -n $feuille ]] || continue
  relative=${feuille#"$public"/}
  relative=${relative#"$travail"/}
  ! shell_grep -qE 'hyphens[[:space:]]*:[[:space:]]*auto' "$feuille" \
    || signaler "$relative" "C24 : « hyphens: auto » dans la feuille de style ; la césure automatique est interdite (UX-DR17)"
done <<< "$liste_25"

((fail == 0)) || exit 1
printf '%s: typographie française posée sur les pages FR, absente des pages EN, aucune césure automatique.\n' "$script_name"
