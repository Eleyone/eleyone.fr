#!/usr/bin/env bash
# C21 (AD-12, AD-21, FR-28, FR-38, NFR-9) : les CV PDF, ensemble ou rien, et rien de privé dedans.
#
#   - « ensemble ou rien » : aucun des deux fichiers, ou les deux. Un seul fait échouer, parce que
#     les liens du pied de page n'apparaissent qu'à deux et qu'un CV seul dans l'historique est un
#     CV qui ne sera jamais publié ;
#   - chaque fichier présent commence par « %PDF- », a au moins une page et pèse au plus 500 Ko ;
#   - quand la liste des motifs est disponible, le **texte** (pdftotext), les **métadonnées**
#     (pdfinfo) et le **XMP** (pdfinfo -meta) lui sont confrontés. Un téléphone ou une ville de
#     résidence vit souvent dans les métadonnées d'un PDF exporté, que personne ne regarde.
#
# Le garde-fou ne peut pas faire ce travail : il ignore les binaires (« git grep -I »). C'est
# pourquoi ce contrôle tourne aussi au pre-commit et dans le hook pre-receive (AD-21).
#
# **Aucun message n'affiche le motif ni le texte trouvé** : un motif est cité par son numéro de
# ligne dans la liste, comme le fait check-private.sh. Le seuil de 500 Ko est propre à cette story :
# AD-8 sort les CV du budget de page, et rien d'autre ne les borne.
#
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie (outil ou fichier illisible).
set -euo pipefail

script_name=pdf
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly attendus=(cv-fr.pdf cv-en.pdf)
readonly poids_max=500000

cv_dir=${CHECK_CV_DIR:-assets/cv}

# Les deux outils sont exigés, et leur absence est une **anomalie**, jamais un succès : un PDF non
# lu passerait sinon pour un PDF propre, ce qui est exactement ce que ce contrôle existe pour
# empêcher. Même règle que xmllint dans html.sh.
for outil in pdftotext pdfinfo; do
  command -v "$outil" > /dev/null 2>&1 \
    || checks_die "$outil est introuvable (paquet poppler-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1, AD-21)."
done

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# La liste des motifs, sous la forme « numéro:motif », et les motifs seuls pour un premier passage.
# Même variable que le garde-fou : PRIVATE_PATTERNS_FILE. Sans elle — GitHub, clone sans
# docs/private/ — seules présence, en-tête, pages et taille s'appliquent, et le script le dit.
patterns="" patterns_text=""
patterns_file=${PRIVATE_PATTERNS_FILE:-}
if [[ -n $patterns_file && -f $patterns_file ]]; then
  patterns=$(mktemp) && patterns_text=$(mktemp) || checks_die "fichier temporaire impossible."
  trap 'rm -f "$patterns" "$patterns_text"' EXIT
  rc=0
  grep -nvE '^[[:space:]]*(#|$)' "$patterns_file" > "$patterns" 2>/dev/null || rc=$?
  ((rc <= 1)) || checks_die "liste des motifs illisible ($patterns_file)"
  rc=0
  grep -vE '^[[:space:]]*(#|$)' "$patterns_file" > "$patterns_text" 2>/dev/null || rc=$?
  ((rc <= 1)) || checks_die "liste des motifs illisible ($patterns_file)"
  [[ -s $patterns ]] || { patterns=""; patterns_text=""; }
fi

# Confronte un extrait à la liste sans jamais l'afficher, ni lui ni le motif.
confronter() { # $1 = nom du fichier, $2 = source (texte, métadonnées, XMP), $3 = extrait
  local nom=$1 source=$2 extrait=$3 rc=0 entry lignes=""
  [[ -n $patterns ]] || return 0
  [[ -n $extrait ]] || return 0
  printf '%s\n' "$extrait" | grep -q -i -F -f "$patterns_text" || rc=$?
  ((rc <= 1)) || { signaler "$nom" "C21 : recherche des motifs impossible dans $source"; return 0; }
  ((rc == 0)) || return 0
  # « shell_grep » plutôt que « grep » nu dans la condition : un code 2 y serait lu comme « pas
  # trouvé », et le motif manquerait sans un mot. Même classe d'erreur que le « if git diff | grep »
  # du hook, corrigé une ligne plus haut dans la même PR — la deuxième occurrence était à trois
  # lignes de la première (deuxième revue du code de la PR n° 84).
  while IFS= read -r entry; do
    local trouve=0
    shell_grep -q -i -F -e "${entry#*:}" <<< "$extrait" || trouve=$?
    ((trouve == 0)) && lignes+=" ${entry%%:*}"
  done < "$patterns"
  signaler "$nom" "C21 : contenu privé dans $source (contenu masqué) ; motif ligne${lignes}"
}

# --- « ensemble ou rien », et rien d'autre --------------------------------------------------------
presents=() absents=()
for nom in "${attendus[@]}"; do
  if [[ -f $cv_dir/$nom ]]; then presents+=("$nom"); else absents+=("$nom"); fi
done

# Un PDF qui n'est ni cv-fr.pdf ni cv-en.pdf serait ignoré par la boucle ci-dessous : un
# « cv-ancien.pdf » oublié là, avec un téléphone dedans, passerait sans être lu (constat de la
# revue du code de la PR n° 84). AD-21 nomme exactement deux fichiers ; tout autre est refusé,
# plutôt que contrôlé, parce qu'il n'a rien à faire là et que le dire est plus utile.
if [[ -d $cv_dir ]]; then
  # Sans profondeur limitée : un « assets/cv/vieux/cv.pdf » serait sinon ignoré, ce qui est la
  # même faute que celle du filtre du hook — borner la recherche à ce qu'on imagine.
  inattendus=$(checks_find "$cv_dir" -type f ! -name 'cv-fr.pdf' ! -name 'cv-en.pdf' -printf '%P\n' | LC_ALL=C sort) || exit $?
  while IFS= read -r intrus; do
    [[ -n $intrus ]] || continue
    signaler "$intrus" "C21 : fichier inattendu dans $cv_dir ; AD-21 n'y nomme que ${attendus[*]}"
  done <<< "$inattendus"
fi

if ((${#presents[@]} > 0)) && ((${#absents[@]} > 0)); then
  signaler "$cv_dir" "C21 : « ensemble ou rien » (AD-21) : ${presents[*]} présent(s), ${absents[*]} manquant(s)"
fi

# --- chaque fichier présent -----------------------------------------------------------------------
for nom in "${presents[@]}"; do
  fichier=$cv_dir/$nom

  # L'en-tête est lu sur les cinq premiers octets, jamais par grep : un binaire n'est pas du texte.
  entete=$(head -c 5 "$fichier") || { signaler "$nom" "C21 : lecture impossible"; continue; }
  [[ $entete == '%PDF-' ]] \
    || { signaler "$nom" "C21 : ce n'est pas un PDF (en-tête « %PDF- » absent)"; continue; }

  octets=$(wc -c < "$fichier")
  ((octets <= poids_max)) \
    || signaler "$nom" "C21 : $octets octets ; $poids_max au plus"

  # pdfinfo échoue sur un PDF corrompu : son code est lu, et l'échec est un écart, pas une anomalie
  # — le fichier est là, il est simplement mauvais.
  infos=$(pdfinfo "$fichier" 2>/dev/null) || { signaler "$nom" "C21 : pdfinfo ne sait pas lire ce fichier"; continue; }
  pages=$(sed -n 's/^Pages:[[:space:]]*\([0-9]\+\).*/\1/p' <<< "$infos" | head -1)
  [[ -n $pages ]] && ((pages >= 1)) \
    || signaler "$nom" "C21 : aucune page"

  texte=$(pdftotext "$fichier" - 2>/dev/null) || { signaler "$nom" "C21 : pdftotext ne sait pas lire ce fichier"; continue; }
  xmp=$(pdfinfo -meta "$fichier" 2>/dev/null) || xmp=""

  confronter "$nom" "le texte" "$texte"
  confronter "$nom" "les métadonnées" "$infos"
  confronter "$nom" "le XMP" "$xmp"
done

((fail == 0)) || exit 1
if ((${#presents[@]} == 0)); then
  printf '%s: aucun CV PDF dans %s ; rien à contrôler (AD-21).\n' "$script_name" "$cv_dir"
elif [[ -n $patterns ]]; then
  printf '%s: les %s CV PDF ont leur en-tête, leurs pages, leur poids, et aucun motif privé.\n' \
    "$script_name" "${#presents[@]}"
else
  printf '%s: les %s CV PDF ont leur en-tête, leurs pages et leur poids ; liste des motifs absente, contenu non confronté.\n' \
    "$script_name" "${#presents[@]}"
fi
