#!/usr/bin/env bash
# C23 (AD-9, FR-18, FR-33, NFR-9) : l'adresse de l'éditeur reste confinée aux deux pages des
# mentions légales, et à leur corps.
#
# L'adresse de l'éditeur porte une **commune**. AD-9 la tolère sur `/mentions-legales/` et
# `/en/legal-notice/`, et nulle part ailleurs : ni sur une autre page, ni dans un `<title>`, une
# meta `description`, un JSON-LD ou `sitemap.xml` — pas même sur les pages légales elles-mêmes, où
# ces emplacements nourrissent les moteurs de recherche et les aperçus de partage.
#
# `_partials/legal-value.html` refuse déjà toute lecture hors d'une page de `translationKey`
# `legal-notice`, mais un gabarit ne sait pas **qui** l'appelle, seulement sur quelle page il
# tourne : sur la page légale, il ne peut pas distinguer le corps du `<title>`. AD-9 répartit donc
# le travail — le partial prévient, ce contrôle constate sur la sortie. C'est la moitié que seul un
# contrôle peut tenir.
#
# **Le contrôle a besoin de la valeur**, pas seulement du nom de la variable : il cherche la chaîne
# réelle dans le rendu. Elle vient du chargeur unique, `scripts/env.sh`, sous lequel `check.sh`
# lance chaque contrôle. Son absence est une **anomalie** (code 2), jamais un succès : un contrôle
# qui chercherait une chaîne vide ne se déclencherait jamais et passerait pour vert — la faute
# exacte que sept gardes du projet ont commise avant lui (constat de la revue de spec, story 9.1).
#
# **Aucun message n'affiche l'adresse.** Un écart nomme la page et l'endroit, jamais la valeur —
# même règle que le garde-fou public/privé, et pour la même raison : le journal d'une CI publique
# se lit.
#
# Codes de sortie : 0 conforme, 1 écart constaté, 2 anomalie.
set -euo pipefail

script_name=legal-address
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

public=${CHECK_PUBLIC_ROOT:-public}
[[ -d $public ]] || checks_die "build de production absent ($public) : lancer scripts/build.sh production."
command -v xmllint > /dev/null 2>&1 \
  || checks_die "xmllint est introuvable (paquet libxml2-utils) : prérequis du poste, présent dans CHECK_IMAGE (AD-1)."

adresse=${HUGO_LEGAL_PUBLISHER_ADDRESS:-}
[[ -n $adresse ]] \
  || checks_die "HUGO_LEGAL_PUBLISHER_ADDRESS est absente : ce contrôle chercherait une chaîne vide et ne verrait rien. Lancer par scripts/check.sh, qui passe par le chargeur unique (AD-9)."

fail=0
signaler() { checks_report "$1" "$2"; fail=1; }

# Les deux pages où l'adresse est admise, dans leur corps seulement. Les chemins viennent des
# permaliens décidés le 13/09/2026 (ARCHITECTURE-SPINE, « Slugs des pages simples »).
readonly pages_legales=(mentions-legales/index.html en/legal-notice/index.html)

est_page_legale() { # $1 = chemin relatif à la racine du rendu
  local page
  for page in "${pages_legales[@]}"; do [[ $1 != "$page" ]] || return 0; done
  return 1
}

# **Le texte cherché est normalisé, l'adresse ne l'est pas.** Une adresse portant une apostrophe
# ou une esperluette s'écrit différemment selon qui l'a sérialisée : Hugo rend « L'adresse » en
# « L&#39;adresse » ; le minifieur redécode certaines entités ; libxml2, en extrayant un nœud par
# XPath, laisse l'apostrophe et réécrit l'esperluette en « &amp; ». Trois écritures, et il y en a
# d'autres.
#
# Chercher plusieurs formes fixes est une impasse : leur nombre est combinatoire, et celle qu'on
# oublie est celle qui fuite. Une seule forme canonique, obtenue en **décodant** le texte avant de
# le lire, couvre toutes les sérialisations d'un coup. Sans cela, le contrôle cherchait la chaîne
# brute dans un HTML échappé, ne trouvait rien, et se déclarait vert — il aurait laissé passer la
# commune de l'éditeur dans un titre (constat bloquant de la revue de la PR n° 98).
#
# **Les deux filtres vivaient ici** ; depuis la story 11.2 ils vivent dans « scripts/checks/lib.sh »,
# chargée en tête, parce que C22 (scripts/checks/output-patterns.sh) en a besoin pour les mêmes
# raisons : une seconde écriture aurait été la faute du point 19 d'AGENTS.md. Leur comportement n'a
# pas changé, et les cas de scripts/tests/test-legal-address.sh continuent de les éprouver à travers
# ce contrôle — l'adresse échappée, l'adresse minifiée et l'adresse sérialisée en JSON-LD.
#
# Le texte est normalisé des **deux** côtés : l'adresse d'AD-9 tient souvent sur deux lignes.
adresse_normalisee=$(printf '%s' "$adresse" | normaliser_blancs)

# Cherche l'adresse dans un texte, sans jamais l'afficher. Rend 0 si trouvée.
#
# La comparaison est celle de bash, « == *"$adresse"* », et non « grep -F ». Trois raisons, dans
# l'ordre de leur poids :
#
#   - **grep travaille ligne par ligne.** Une adresse postale tenant sur deux lignes ne lui serait
#     jamais apparue entière, et le contrôle serait passé au vert en laissant fuiter l'adresse
#     complète (constat bloquant de la revue de la PR n° 98) ;
#   - la comparaison de bash traite la chaîne comme une chaîne, sans qu'on ait à le demander : pas
#     d'expression régulière, donc pas de point qui filtre ni de parenthèse qui groupe ;
#   - un outil de moins, donc un code de retour de moins à interpréter.
contient_adresse() { # $1 = texte
  local decode
  # Le décodage est **capturé**, il n'alimente pas grep par un tuyau : ainsi le code de « sed » se
  # lit pour lui-même, au lieu de se confondre avec celui du pipeline sous « pipefail ». Le
  # relecteur craignait qu'un « grep -q » fermant tôt tue « sed » par SIGPIPE et fasse rendre 141
  # au pipeline, lu comme une anomalie. **Constaté : cela ne se produit pas**, ni à 400 Ko ni à
  # 20 Mo — grep lit jusqu'au bout et sed rend 0. Le doute se ferme quand même, parce que cette
  # forme est plus claire et ne coûte rien (revue de la PR n° 98).
  decode=$(printf '%s' "$1" | decoder_echappements | normaliser_blancs) \
    || checks_die "décodage impossible (sed) : rien n'est affirmé."
  [[ $decode == *"$adresse_normalisee"* ]]
}

# --- toute page HTML ------------------------------------------------------------------------------
pages=$(checks_find "$public" -type f -name '*.html' -printf '%P\n' | LC_ALL=C sort) || exit $?
[[ -n $pages ]] || checks_die "aucune page HTML sous $public : le rendu est vide, rien ne serait contrôlé."

while IFS= read -r page; do
  [[ -n $page ]] || continue
  fichier=$public/$page
  corps_admis=0
  ! est_page_legale "$page" || corps_admis=1

  # 1. Hors des deux pages légales, l'adresse ne doit apparaître nulle part dans le fichier.
  if ((corps_admis == 0)); then
    # Le fichier est lu **avant** la condition, jamais en argument d'un « if » : « set -e » y est
    # neutralisé, et un « cat » en échec — droits, fichier disparu — aurait rendu une chaîne vide
    # que le contrôle aurait lue comme « pas d'adresse ». Un fichier illisible serait sorti du
    # contrôle en silence (constat bloquant de la revue de la PR n° 98).
    contenu=$(cat "$fichier") || checks_die "lecture impossible de $page : rien n'est affirmé."
    if contient_adresse "$contenu"; then
      signaler "$page" "C23 : l'adresse de l'éditeur apparaît sur une page qui n'est pas les mentions légales (AD-9)"
    fi
    continue
  fi

  # 2. Sur les deux pages légales, elle est admise dans le corps, mais pas dans ce qui nourrit les
  #    moteurs et les aperçus. Chaque emplacement est extrait par XPath plutôt que par grep : le
  #    HTML n'est pas du texte, et un « <title> » repéré à la main raterait un attribut.
  #    Le code des lecteurs XPath est **propagé**, jamais transformé en valeur vide : « checks_xpath »
  #    s'arrête par « checks_die » en cas d'anomalie, et comme il tourne ici dans une substitution,
  #    ce « exit 2 » ne quitte que le sous-shell. Un « || titre="" » l'aurait avalé et le contrôle
  #    aurait conclu « rien dans le titre » sur un fichier illisible.
  rc=0
  titre=$(checks_xpath "$fichier" '//head/title/text()') || rc=$?
  ((rc == 0)) || exit "$rc"
  if [[ -n $titre ]] && contient_adresse "$titre"; then
    signaler "$page" "C23 : l'adresse de l'éditeur apparaît dans le <title> (AD-9)"
  fi

  # **Toutes** les balises « meta », pas la seule « description ». Une première écriture ne visait
  # qu'elle : « og:description » et « twitter:description », que Hugo pose couramment et qui
  # nourrissent les aperçus de partage, auraient laissé fuiter l'adresse en silence. Énumérer les
  # noms qu'on imagine est la faute que la rétrospective de l'epic 7 a nommée ; on prend donc tout
  # ce qui porte un « content » (constat de la revue de la PR n° 98).
  rc=0
  metas=$(checks_attributes "$fichier" '//head/meta[@content]' content) || rc=$?
  ((rc == 0)) || exit "$rc"
  if [[ -n $metas ]] && contient_adresse "$metas"; then
    signaler "$page" "C23 : l'adresse de l'éditeur apparaît dans une balise meta (AD-9)"
  fi

  rc=0
  jsonld=$(checks_xpath "$fichier" '//script[@type="application/ld+json"]/text()') || rc=$?
  ((rc == 0)) || exit "$rc"
  if [[ -n $jsonld ]] && contient_adresse "$jsonld"; then
    signaler "$page" "C23 : l'adresse de l'éditeur apparaît dans le JSON-LD (AD-9)"
  fi
done <<< "$pages"

# --- sitemap et autres sorties non HTML -------------------------------------------------------------
# Le sitemap est nommé par AD-9. Les autres sorties du site (flux, manifeste de contrôles) sont
# balayées avec lui : ce que la règle vise, c'est que l'adresse ne sorte pas du corps de deux pages,
# et énumérer les seules sorties qu'on imagine est la faute que la rétrospective de l'epic 7 a
# nommée « borner la recherche à ce qu'on imagine ».
autres=$(checks_find "$public" -type f ! -name '*.html' ! -name '*.pdf' -printf '%P\n' | LC_ALL=C sort) || exit $?
while IFS= read -r fichier_relatif; do
  [[ -n $fichier_relatif ]] || continue
  # Les binaires sont écartés : une image ne porte pas de texte, et « grep -F » sur des octets
  # rendrait un résultat que personne ne saurait lire. C20 garde les images par ailleurs.
  #
  # Quand « file » échoue — outil absent, fichier illisible —, le fichier est **lu quand même**.
  # Une première écriture le traitait comme binaire et le sautait : l'échec d'un outil faisait
  # alors sortir un fichier du contrôle, en silence, ce qui est la définition d'un garde-fou qui
  # s'ouvre en cas de panne (constat de la revue de la PR n° 98). Se tromper en lisant ne coûte
  # qu'un faux signalement ; se tromper en sautant laisse fuiter une adresse.
  encodage=$(file --mime-encoding -b "$public/$fichier_relatif" 2>/dev/null) || encodage=inconnu
  # Un encodage **inconnu se lit**. Une première écriture le traitait comme binaire et sautait le
  # fichier : l'échec d'un outil sortait alors un fichier du contrôle, en silence. Une seconde
  # ajoutait une condition sur le code de « file » — mais aucun cas de test ne savait la
  # distinguer, parce qu'un « file » en échec rend déjà une chaîne vide qui n'est pas « binary ».
  # Une garde qu'aucun test ne distingue n'est pas une garde : la valeur de repli est donc écrite
  # en clair, et c'est elle qui porte l'intention (revue de la PR n° 98).
  [[ $encodage != *binary* ]] || continue
  contenu=$(cat "$public/$fichier_relatif") \
    || checks_die "lecture impossible de $fichier_relatif : rien n'est affirmé."
  if contient_adresse "$contenu"; then
    signaler "$fichier_relatif" "C23 : l'adresse de l'éditeur apparaît dans une sortie qui n'est pas une page (AD-9)"
  fi
done <<< "$autres"

((fail == 0)) || exit 1
printf '%s: l adresse de l éditeur ne sort pas du corps des deux pages des mentions légales.\n' "$script_name"
