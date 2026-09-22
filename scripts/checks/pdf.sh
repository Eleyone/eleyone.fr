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
# Le garde-fou ne peut pas chercher dans un binaire (« git grep -I ») : il charge donc la même
# bibliothèque, scripts/lib/pdf.sh, et confronte lui-même chaque PDF poussé ou indexé (story 7.3).
# Ce contrôle, lui, juge la paire publiée : présence, forme, poids, et contenu.
#
# **Aucun message n'affiche le motif ni le texte trouvé** : un motif est cité par son numéro de
# ligne dans la liste, comme le fait check-private.sh. Le seuil de 500 Ko est propre à cette story :
# AD-8 sort les CV du budget de page, et rien d'autre ne les borne.
#
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie (outil ou fichier illisible).
set -euo pipefail

script_name=pdf
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# La lecture d'un PDF vit dans scripts/lib/pdf.sh, copiée à côté du garde-fou sur la forge, qui la
# charge aussi : une seule écriture de « ce qu'est lire un PDF » pour le contrôle et pour le hook.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/pdf.sh"

readonly attendus=(cv-fr.pdf cv-en.pdf)
readonly poids_max=500000

cv_dir=${CHECK_CV_DIR:-assets/cv}

# Les deux outils sont exigés, et leur absence est une **anomalie**, jamais un succès : un PDF non
# lu passerait sinon pour un PDF propre, ce qui est exactement ce que ce contrôle existe pour
# empêcher. Même règle que xmllint dans html.sh.
if manquant=$(pdf_missing_tool); then
  checks_die "$manquant est introuvable (paquet poppler-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1, AD-21)."
fi

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# Le nettoyage ne lit que « temporaires », jamais une variable qui désigne aussi autre chose :
# « patterns » porte **deux sens** — le chemin du fichier, et « la liste contient-elle au moins un
# motif ». Le vider pour dire « aucun motif » effaçait l'adresse du fichier à supprimer, et deux
# temporaires restaient à chaque exécution (constat B1 de la rétrospective de l'epic 7, mesuré).
# Séparer les deux sens ferme le piège ; une condition de plus ne l'aurait que déplacé.
temporaires=()
trap '((${#temporaires[@]} == 0)) || rm -f "${temporaires[@]}"' EXIT

# La liste des motifs, sous la forme « numéro:motif », et les motifs seuls pour un premier passage.
# Même variable que le garde-fou : PRIVATE_PATTERNS_FILE. Sans elle — GitHub, clone sans
# docs/private/ — seules présence, en-tête, pages et taille s'appliquent, et le script le dit.
# Le repli sur le chemin du dépôt est **volontaire** : sans lui, « scripts/check.sh » lancé sur le
# poste ne confrontait rien, et se contentait de la forme alors que la liste était là, à deux pas
# (constaté à la story 7.2, en lançant les contrôles avec les deux PDF en place). AD-21 veut la
# confrontation « quand la liste est disponible » — sur le poste, elle l'est. Sur GitHub le fichier
# n'existe pas, le repli ne trouve rien, et le script dit ce qu'il n'a pas vérifié.
#
# La racine vient de l'emplacement du script, pas de git : un contrôle tourne sans dossier .git.
patterns="" patterns_text=""
racine_depot=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
patterns_file=${PRIVATE_PATTERNS_FILE:-$racine_depot/docs/private/forbidden-patterns.txt}
if [[ -n $patterns_file && -f $patterns_file ]]; then
  # Deux commandes, chacune avec son arrêt : « a && b || die » suspend « set -e » pour tout le
  # bloc, ce que docs/procedures/shell-scripts.md proscrit.
  patterns=$(mktemp) || checks_die "fichier temporaire impossible."
  temporaires+=("$patterns")
  patterns_text=$(mktemp) || checks_die "fichier temporaire impossible."
  temporaires+=("$patterns_text")
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
  pdf_has_header "$fichier" \
    || { signaler "$nom" "C21 : ce n'est pas un PDF (en-tête « %PDF- » absent)"; continue; }

  octets=$(wc -c < "$fichier")
  ((octets <= poids_max)) \
    || signaler "$nom" "C21 : $octets octets ; $poids_max au plus"

  # pdfinfo échoue sur un PDF corrompu : son code est lu, et l'échec est un écart, pas une anomalie
  # — le fichier est là, il est simplement mauvais.
  infos=$(pdf_metadata "$fichier") || { signaler "$nom" "C21 : pdfinfo ne sait pas lire ce fichier"; continue; }
  pages=$(pdf_pages "$fichier") || { signaler "$nom" "C21 : pdfinfo ne sait pas lire ce fichier"; continue; }
  [[ -n $pages ]] && ((pages >= 1)) \
    || signaler "$nom" "C21 : aucune page"

  texte=$(pdf_text "$fichier") || { signaler "$nom" "C21 : pdftotext ne sait pas lire ce fichier"; continue; }
  xmp=$(pdf_xmp "$fichier")

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
