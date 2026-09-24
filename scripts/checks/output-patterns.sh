#!/usr/bin/env bash
# C22 (AD-9, AD-12, FR-18, FR-33, NFR-9) : aucun motif interdit dans la sortie de production, sauf
# sur les deux pages des mentions légales, où une occurrence **contenue dans une valeur
# HUGO_LEGAL_* injectée** est légitime.
#
# C'est le dernier filet entre le build de production et le serveur. Il ne juge que la **sortie**,
# jamais les sources : celles-ci relèvent du garde-fou (AD-12), qui tourne sur la forge avant que le
# miroir publie. Un fichier de « public/ » n'est vu par aucun des deux, et c'est ce trou que C22
# ferme : un motif peut arriver dans une page par un gabarit, une donnée de « data/ », une valeur
# injectée au build, sans jamais avoir été écrit dans un fichier suivi.
#
# ## Ce qu'il lit
#
# **Tout « public/ »**, et non les seules extensions qu'on imagine : borner la recherche à ce qu'on
# imagine est la faute que la rétrospective de l'epic 7 a nommée, et C23 l'a déjà tranchée dans
# l'autre sens. Un format de sortie nouveau — un flux, un manifeste, une carte de site — est donc
# inspecté par défaut, jamais oublié par omission. Seuls sont écartés les fichiers qu'un autre
# contrôle couvre, désignés par les **listes uniques** du dépôt :
#
#   - les images, par « image_extensions » de scripts/lib/image.sh (C20, qui refuse tout EXIF, tout
#     XMP et tout conteneur étendu : une image publiée ne peut porter aucune métadonnée textuelle) ;
#   - les deux CV publiés, par « pdf_cv_published_dir » et « pdf_cv_names » de scripts/lib/pdf.sh
#     (C21, qui confronte leur texte, leurs métadonnées et leur XMP à la même liste).
#
# L'exclusion des PDF s'arrête là où s'arrête C21 : **les deux noms qu'AD-21 connaît**, et pas
# « tout fichier qui commence par %PDF- ». Un troisième PDF déposé dans la sortie n'est couvert par
# personne, et l'écarter par son extension aurait ouvert exactement le trou que C22 existe pour
# fermer.
#
# ## Comment il cherche
#
# La recherche elle-même vit dans « pdf_confront » (scripts/lib/pdf.sh), partagée avec C21 et le
# garde-fou. Son nom dit le PDF ; ce qu'elle fait est « confronter un extrait à la liste des motifs
# sans jamais l'afficher », et en réécrire une seconde aurait été la faute A2 de la rétrospective
# de l'epic 7 — les deux copies avaient divergé sur la lecture du code de grep.
#
# **Chaque fichier est décodé puis normalisé avant d'être confronté** (decoder_echappements,
# normaliser_blancs, scripts/checks/lib.sh). Sans cela le contrôle serait décoratif : une même
# chaîne a six sérialisations constatées dans une sortie de Hugo — entités décimales, hexadécimales
# ou nommées, séquences « \uXXXX » du JSON-LD de Go — et celle qu'on oublie est celle qui fuite.
# C'est ce qui a coûté huit tours de revue à la PR n° 98 (C23), et ce qu'aucune lentille de la revue
# de spec de cette story n'avait vu.
#
# **« pdf_confront » cherche avec grep, qui travaille ligne par ligne** ; un motif à cheval sur deux
# lignes lui échapperait. C'est sûr **ici, et seulement grâce à la normalisation** : « tr '\n\t' »
# ramène le fichier entier à une seule ligne, si bien qu'aucune coupure de ligne ne subsiste où une
# chaîne pourrait se couper. Le rendu de production est minifié et le passage à la ligne y est déjà
# arbitraire : c'est la normalisation, pas le hasard du minifieur, qui tient cette propriété. Un cas
# de test l'éprouve sur un motif coupé par un saut de ligne.
#
# ## L'exception des mentions légales
#
# AD-9 admet les valeurs légales sur ces deux pages, et une de ces valeurs peut contenir un motif de
# la liste — la commune de l'éditeur vit dans son adresse. Deux lectures du critère étaient
# possibles, et la naïve est fausse :
#
#   - **dispenser le motif** : s'il est sous-chaîne d'une valeur légale, l'admettre partout sur la
#     page. La commune de résidence écrite dans un paragraphe passerait alors sans un mot, alors que
#     c'est précisément la fuite que FR-33 vise ;
#   - **expurger les occurrences** : retirer du texte de la page les valeurs injectées, puis
#     confronter ce qui reste. Une occurrence à l'intérieur d'une valeur disparaît avec elle ; la
#     même chaîne écrite ailleurs subsiste et fait échouer le contrôle.
#
# La seconde est retenue : c'est ce que le critère décrit mot pour mot, et la seule qui distingue une
# occurrence légitime d'une fuite. L'expurgation porte sur le texte **déjà décodé et normalisé**,
# avec les valeurs elles-mêmes normalisées : sinon une valeur échappée dans la page ne serait pas
# reconnue, et sa propre occurrence légitime ferait échouer la mise en ligne.
#
# ## Ce qui n'est jamais un succès
#
#   - **liste des motifs absente ou vide** : anomalie (code 2). C'est une **différence assumée avec
#     C21**, qui se contente alors de la forme et le dit : pour C21 la liste ajoute une règle à
#     d'autres, pour C22 la liste **est** le contrôle. Une mise en ligne ne se valide pas sur un
#     garde-fou qui n'a rien lu ;
#   - **aucune valeur HUGO_LEGAL_* dans l'environnement** : anomalie (code 2), comme C23 le fait pour
#     l'adresse. Sans elles, l'exception d'AD-9 ne peut pas s'appliquer, et les valeurs légitimes des
#     deux pages feraient échouer la mise en ligne ;
#   - **aucune page de mentions légales dans le manifeste** : anomalie, pour la même raison ;
#   - **un code de « pdf_confront » autre que 0 ou 1** : la recherche a échoué, et c'est un écart
#     signalé, jamais « rien trouvé » — un garde-fou ne s'ouvre pas en cas de panne.
#
# **Aucun message n'affiche le motif ni l'extrait trouvé** : un motif est cité par son numéro de
# ligne dans la liste, comme le font C21 et check-private.sh. Le journal d'une CI publique se lit.
#
# Le contrôle ne tourne qu'au niveau « release » (scripts/check.sh --release) : « dev » porte des cas
# en brouillon et les valeurs légales factices. Hors « release » il le **dit** avant de rendre 0 —
# un « exit 0 » muet cacherait un nom de variable mal écrit (modèle de C15).
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=output-patterns
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# Chargées pour leurs **listes uniques** et pour la recherche partagée, jamais pour lire un PDF ou
# une image : C22 n'appelle ni poppler ni od, et n'exige donc aucun outil de plus que les contrôles
# voisins.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/pdf.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../lib/image.sh"

level=${CHECK_LEVEL:-standard}
if [[ $level != release ]]; then
  printf "%s: niveau « %s » : contrôle de mise en ligne sauté, il ne tourne qu'au niveau « release » (scripts/check.sh --release).\n" \
    "$script_name" "$level"
  exit 0
fi

public=${CHECK_PUBLIC_ROOT:-public}
work=${CHECK_WORK_ROOT:-build/work}

[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
command -v jq > /dev/null 2>&1 || checks_die "jq est introuvable."

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# --- la liste des motifs ---------------------------------------------------------------------------
# Le nettoyage ne lit que « temporaires », jamais une variable qui désigne aussi autre chose : dans
# C21, « patterns » portait **deux sens** — le chemin du fichier, et « la liste contient-elle au
# moins un motif ». Le vider pour dire « aucun motif » effaçait l'adresse du fichier à supprimer, et
# deux temporaires restaient à chaque exécution (constat B1 de la rétrospective de l'epic 7, mesuré).
temporaires=()
trap '((${#temporaires[@]} == 0)) || rm -f "${temporaires[@]}"' EXIT

# Même variable que le garde-fou et que C21 : PRIVATE_PATTERNS_FILE, avec le repli sur le chemin du
# dépôt. La racine vient de l'emplacement du script, pas de git : un contrôle tourne sans dossier
# .git (image du site, conteneur de contrôle).
racine_depot=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
patterns_file=${PRIVATE_PATTERNS_FILE:-$racine_depot/docs/private/forbidden-patterns.txt}
[[ -n $patterns_file && -f $patterns_file ]] \
  || checks_die "liste des motifs introuvable ($patterns_file) : au niveau « release », une mise en ligne ne se valide pas sur un garde-fou qui n'a rien lu. Poser PRIVATE_PATTERNS_FILE (AD-12)."

# Les deux fichiers qu'exige « pdf_confront » : la liste sous la forme « numéro:motif », pour que le
# signalement cite un numéro de ligne, et les motifs nus pour le premier passage « grep -f ».
# Deux commandes, chacune avec son arrêt : « a && b || die » suspend « set -e » pour tout le bloc,
# ce que docs/procedures/shell-scripts.md proscrit.
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
# Un fichier **présent mais vide** n'est pas une conformité : le piège est déjà consigné
# (docs/procedures/shell-scripts.md, story 0.8), et ici il désactiverait le contrôle entier.
[[ -s $patterns ]] \
  || checks_die "aucun motif dans $patterns_file : le contrôle ne chercherait rien et passerait pour vert."

# --- les valeurs légales injectées -------------------------------------------------------------------
# **Relevées par leur préfixe, jamais énumérées.** AD-9 en nomme huit, et les huit noms vivent déjà
# dans scripts/env.sh et dans scripts/checks/content.sh : en écrire une troisième copie serait la
# faute du point 19 d'AGENTS.md, celle qui a laissé les deux noms de CV vivre sous quatre
# orthographes. Le préfixe « HUGO_LEGAL_ » est le contrat d'AD-9 ; une neuvième variable y serait
# expurgée sans retouche, et le contrôle ne peut pas rester en arrière d'une liste qu'il ne porte pas.
#
# Une variable **manquante** ne peut pas créer de faux négatif : sa valeur n'est alors pas non plus
# dans la page, puisque le build et le contrôle passent par le même chargeur (AD-9, scripts/check.sh).
# Si les deux environnements divergeaient, la valeur resterait dans la page sans être expurgée, et le
# contrôle échouerait bruyamment — le bon sens d'erreur.
noms_definis=$(compgen -v) || checks_die "lecture de l'environnement impossible."
valeurs=()
while IFS= read -r nom; do
  [[ $nom == HUGO_LEGAL_* ]] || continue
  valeur=${!nom-}
  # Une valeur vide est écartée : « ${texte//""/ } » ne retire rien, mais laisser entrer une chaîne
  # vide dans la boucle d'expurgation serait une invitation à une faute plus tard.
  [[ -n $valeur ]] || continue
  valeurs+=("$(printf '%s' "$valeur" | normaliser_blancs)")
done <<< "$noms_definis"

((${#valeurs[@]} > 0)) \
  || checks_die "aucune valeur HUGO_LEGAL_* dans l'environnement : l'exception d'AD-9 ne pourrait pas s'appliquer et les valeurs légitimes des mentions légales feraient échouer la mise en ligne. Lancer par scripts/check.sh, qui passe par le chargeur unique."

# **Les valeurs sont expurgées de la plus longue à la plus courte.** Sans cet ordre, une valeur
# courte contenue dans une plus longue la découpe : retirer « ACME » de « ACME, 1 rue …, VILLE »
# laisse « , 1 rue …, VILLE », que la valeur complète ne reconnaît plus — et la commune qu'elle
# portait ressort, faisant échouer une mise en ligne parfaitement propre. Tri par insertion : huit
# valeurs au plus, et aucun outil de plus. « j=$((j - 1)) » plutôt que « ((j--)) », qui rend 1 quand
# j vaut 0 et arrêterait le script sous « set -e » (piège connu, shell-scripts.md).
for ((i = 1; i < ${#valeurs[@]}; i++)); do
  courante=${valeurs[i]}
  j=$((i - 1))
  while ((j >= 0)) && ((${#valeurs[j]} < ${#courante})); do
    valeurs[j + 1]=${valeurs[j]}
    j=$((j - 1))
  done
  valeurs[j + 1]=$courante
done

# --- les deux pages des mentions légales ------------------------------------------------------------
# Trouvées par le manifeste, jamais codées en dur : « translationKey » vaut « legal-notice » dans les
# deux langues, et la clé « url » livrée par la story 11.1 donne la RelPermalink de chaque page.
# C23 (scripts/checks/legal-address.sh) code encore les deux chemins en dur ; la divergence est
# réelle et consignée dans deferred-work.md plutôt qu'élargir cette story.
manifestes=$(checks_manifests "$work")
mapfile -t fichiers_manifeste <<< "$manifestes"

declare -A pages_legales=()
for manifeste in "${fichiers_manifeste[@]}"; do
  urls=$(jq -r '.files[] | select((.translationKey // "") == "legal-notice") | .url // ""' "$manifeste") \
    || checks_die "lecture impossible de $manifeste (jq)."
  while IFS= read -r url; do
    [[ -n $url ]] || continue
    chemin=$(checks_page_de_url "$url")
    pages_legales["$chemin"]=1
  done <<< "$urls"
done

((${#pages_legales[@]} > 0)) \
  || checks_die "aucune page de « translationKey » legal-notice avec une url dans les manifestes de $work : C22 ne saurait pas où l'exception d'AD-9 s'applique."

# --- ce que d'autres contrôles couvrent déjà ---------------------------------------------------------
est_exclu() { # $1 = chemin relatif à la racine de production ; rend 0 si un autre contrôle le couvre
  local chemin=$1 base=${1##*/} extension="" ext nom
  # Un nom sans point n'a pas d'extension : sans cette garde, « ${base##*.} » rendrait le nom entier,
  # et un fichier nommé « png » sortirait du contrôle (point 15 : quelles *autres formes* ?).
  [[ $base != *.* ]] || extension=${base##*.}
  # La casse de l'extension est ramenée en bas : Hugo écrit en minuscules, mais un fichier statique
  # copié tel quel peut porter « .PNG », et la liste unique est en minuscules.
  extension=${extension,,}
  if [[ -n $extension ]]; then
    for ext in "${image_extensions[@]}"; do [[ $extension != "$ext" ]] || return 0; done
  fi
  for nom in "${pdf_cv_names[@]}"; do [[ $chemin != "$pdf_cv_published_dir/$nom" ]] || return 0; done
  return 1
}

# --- confrontation -----------------------------------------------------------------------------------
confronter() { # $1 = chemin affiché, $2 = texte déjà décodé et normalisé, $3 = 1 si page légale
  local chemin=$1 texte=$2 legale=$3 lignes code=0
  [[ -n $texte ]] || return 0
  # L'affectation est séparée de la déclaration : « local x=$(…) » rend le code de « local », pas
  # celui de la substitution, et le code 2 serait perdu (piège connu, shell-scripts.md).
  lignes=$(pdf_confront "$patterns" "$patterns_text" "$texte") || code=$?
  # **Tout code autre que 0 ou 1 est un échec de recherche**, et non « rien trouvé ». Une première
  # écriture de C21 testait « code != 2 » puis « code == 1 », si bien qu'un code inattendu —
  # sous-shell tué, commande introuvable, arrêt sur « set -e » — retombait sur « rien trouvé » et
  # déclarait le fichier propre : un garde-fou qui s'ouvre en cas de panne (revue de la PR n° 95).
  case $code in
    0) return 0 ;;
    1) ;;
    *) signaler "$chemin" "C22 : recherche des motifs impossible (code $code)"; return 0 ;;
  esac
  if ((legale == 1)); then
    signaler "$chemin" \
      "C22 : motif privé hors des valeurs légales injectées (contenu masqué) ; motif ligne${lignes}"
  else
    signaler "$chemin" \
      "C22 : motif privé dans la sortie de production (contenu masqué) ; motif ligne${lignes}"
  fi
}

# --- toute la sortie de production ---------------------------------------------------------------
# La liste est lue dans une variable, hors de tout pipeline, pour que l'anomalie de checks_find
# arrête vraiment le contrôle, et elle est éprouvée **non vide** : une racine erronée ou un build
# vide ne feraient trouver aucun motif et passeraient pour une conformité (rétrospective de l'epic 3).
liste=$(checks_find "$public" -type f -printf '%P\n' | LC_ALL=C sort) || exit $?
[[ -n $liste ]] || checks_die "aucun fichier sous $public : le rendu est vide, rien ne serait contrôlé."

lus=0
while IFS= read -r relatif; do
  [[ -n $relatif ]] || continue
  if est_exclu "$relatif"; then continue; fi
  fichier=$public/$relatif

  # Le fichier est lu **avant** la condition, jamais en argument d'un « if » : « set -e » y est
  # neutralisé, et une lecture en échec — droits, fichier disparu — aurait rendu une chaîne vide que
  # le contrôle aurait lue comme « aucun motif ». Un fichier illisible serait sorti du contrôle en
  # silence (constat bloquant de la revue de la PR n° 98, sur C23).
  #
  # « tr -d '\0' » plutôt qu'un « cat » : une substitution de commande avale les octets nuls en
  # écrivant un avertissement sur la sortie d'erreur, qu'un lecteur prendrait pour un signalement.
  # C23 saute les binaires en interrogeant « file » ; C22 les **lit** — aucun autre contrôle ne
  # regarde un format de sortie inconnu, et une chaîne ASCII se voit très bien dans des octets.
  contenu=$(tr -d '\0' < "$fichier") || checks_die "lecture impossible de $relatif : rien n'est affirmé."
  # Le décodage est **capturé** plutôt que branché sur un tuyau vers grep : ainsi le code de « sed »
  # se lit pour lui-même, au lieu de se confondre avec celui du pipeline sous « pipefail ».
  texte=$(printf '%s' "$contenu" | decoder_echappements | normaliser_blancs) \
    || checks_die "décodage impossible (sed) sur $relatif : rien n'est affirmé."

  legale=0
  [[ -z ${pages_legales[$relatif]+presente} ]] || legale=1
  if ((legale == 1)); then
    # Chaque valeur est remplacée par une **espace**, et non retirée : coller les deux voisins
    # forgerait une chaîne que personne n'a écrite, et qu'un motif pourrait traverser. La
    # substitution de bash avec un motif entre guillemets est littérale — ni regex, ni glob.
    for valeur in "${valeurs[@]}"; do
      texte=${texte//"$valeur"/ }
    done
  fi

  confronter "$relatif" "$texte" "$legale"
  lus=$((lus + 1))
done <<< "$liste"

# Tout exclure serait passer pour vert sans rien lire : une sortie qui ne contiendrait que des images
# et les deux CV n'est pas un site, et le dire vaut mieux que se taire.
((lus > 0)) \
  || checks_die "aucun fichier lu sous $public : tout y est couvert par un autre contrôle (images, CV), rien n'a été confronté."

((fail == 0)) || exit 1
printf '%s: %s fichier(s) de %s confrontés à la liste des motifs ; aucune occurrence hors des valeurs légales injectées des mentions légales.\n' \
  "$script_name" "$lus" "$public"
