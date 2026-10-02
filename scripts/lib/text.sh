# Filtres de lecture d'une chaîne dans une sortie de Hugo, chargés par « . scripts/lib/text.sh ».
#
#   decoder_echappements          filtre : ramène les sérialisations d'une chaîne (entités HTML,
#                                 séquences \uXXXX du JSON) à sa forme brute
#   normaliser_blancs             filtre : ramène tout blanc à une espace simple, sur une seule ligne
#   decoder_espaces_insecables    filtre : ramène les entités des deux espaces insécables (« &nbsp; »,
#                                 « &#160; », « &#8239; »…) à leur caractère ; **avant**
#                                 decoder_echappements
#   replier_espaces_insecables    filtre : ramène U+00A0 et U+202F à une espace ordinaire
#
# Les deux premiers sont nés dans C23 (story 9.1), puis ont vécu dans scripts/checks/lib.sh pour C22
# et C23 (story 11.2). Ils sont ici depuis la story 11.9, parce que la répétition générale en a
# besoin à son tour pour lire les valeurs légales dans les pages servies : scripts/lib/ est la
# bibliothèque commune à tous les scripts, et une seconde écriture aurait été la faute du point 19
# d'AGENTS.md. scripts/checks/lib.sh les charge d'ici ; leur comportement n'a pas changé.
#
# Les deux derniers sont nés à la story 11.9 et **ne servent qu'à la répétition**. C22 et C23 ne
# replient pas les insécables, et c'est voulu : le faire suppose de transformer aussi les listes de
# motifs, décision consignée dans deferred-work.md (« C22 et C23 ne rapprochent pas deux caractères
# différents »). Pour la répétition, la question ne se pose pas : la valeur cherchée est connue, et
# la typographie française du site (layouts/_partials/typo-fr-texte.html) **remplace** une espace
# ordinaire par U+00A0 devant « : » et par U+202F devant « ; », « ! », « ? » et à l'intérieur des
# guillemets — mesuré sur un vrai build de production le 02/10/2026. Une valeur légale « Bât. B :
# 2e étage » s'affiche donc, sur la page française seulement, avec une insécable que la valeur
# n'a pas.
#
# Aucune fonction n'affiche rien d'elle-même hors de ce qu'on lui donne à filtrer.

# --- lire une chaîne dans une sortie de Hugo -------------------------------------------------------
#
# Deux filtres, employés ensemble et dans cet ordre : « decoder_echappements | normaliser_blancs ».
# Ils viennent de C23 (scripts/checks/legal-address.sh, story 9.1), où huit tours de revue les ont
# écrits ; C22 (scripts/checks/output-patterns.sh, story 11.2) en a besoin pour les mêmes raisons,
# et une seconde écriture aurait été la faute du point 19 d'AGENTS.md.
#
# **Une même chaîne a six sérialisations constatées dans une sortie de Hugo.** Chercher plusieurs
# formes fixes est une impasse : leur nombre est combinatoire, et celle qu'on oublie est celle qui
# fuite. Une seule forme canonique, obtenue en décodant le texte avant de le lire, les couvre d'un
# coup. Sans cela, un contrôle cherche la chaîne brute dans un HTML échappé, ne trouve rien, et se
# déclare vert (constat bloquant de la revue de la PR n° 98).
decoder_echappements() {
  # **Deux familles d'échappement, pas une.** Le HTML écrit des entités ; le JSON-LD, sérialisé par
  # l'encodeur de Go, écrit des séquences Unicode — « & » pour l'esperluette, « < » et
  # « > » pour les chevrons. Une adresse portant un « & » fuyait donc par le JSON-LD sans que
  # rien ne le dise, le décodeur ne connaissant que les entités (constat de la revue de la PR n° 98,
  # vérifié en mesurant ce que « jsonify » produit).
  #
  # Dans chaque famille, les trois écritures d'un caractère sont couvertes : décimale, hexadécimale
  # et nommée pour le HTML ; la casse du « x » et des chiffres hexadécimaux varie. Celle qu'on omet
  # est celle qui fuite.
  #
  # Les séquences « \n », « \r » et « \t » du JSON deviennent une **espace**, et non le caractère
  # qu'elles désignent : « normaliser_blancs » ramènera de toute façon tout blanc à une espace
  # simple. Une adresse multi-lignes s'écrit « Ligne 1\nLigne 2 » dans un JSON-LD, et sans cette
  # ligne elle n'y était reconnue sous aucune forme (huitième tour de la revue de la PR n° 98 —
  # la sixième sérialisation de la même chaîne).
  #
  # L'esperluette et la barre oblique inverse se décodent **en dernier** dans leur famille :
  # l'inverse transformerait « &amp;lt; », qui désigne le texte « &lt; », en « < ».
  #
  # **« &rsquo; » est la seule entité que la sortie de production de ce site émet**, et elle y
  # apparaît 236 fois — Hugo convertit l'apostrophe droite du Markdown en apostrophe typographique,
  # que le minifieur écrit en entité (mesuré sur public/ le 25/09/2026, story 11.2). Un motif
  # portant une apostrophe typographique n'était donc reconnu dans aucune page : la seule
  # sérialisation que le rendu produit vraiment était celle qui manquait. Ce qui reste, et que le
  # décodage ne peut pas régler, est une différence de **caractère** et non d'écriture : un motif
  # écrit avec l'apostrophe droite ne correspond pas à un texte qui porte la typographique, comme
  # un motif écrit sans accent ne correspond pas à un texte accentué (consigné dans
  # deferred-work.md).
  sed -E -e "s/&(#0*39|#[xX]0*27|apos);/'/g" \
         -e 's/&(#0*8217|#[xX]0*2019|rsquo);/’/g' \
         -e 's/&(#0*8216|#[xX]0*2018|lsquo);/‘/g' \
         -e 's/&(#0*34|#[xX]0*22|quot);/"/g' \
         -e 's/&(#0*43|#[xX]0*2[bB]);/+/g' \
         -e 's/&(#0*60|#[xX]0*3[cC]|lt);/</g' \
         -e 's/&(#0*62|#[xX]0*3[eE]|gt);/>/g' \
         -e 's/&(#0*38|#[xX]0*26|amp);/\&/g' \
         -e 's/\\u0*3[cC]/</g' \
         -e 's/\\u0*3[eE]/>/g' \
         -e "s/\\\\u0*27/'/g" \
         -e 's/\\"/"/g' \
         -e 's/\\u0*26/\&/g' \
         -e 's/\\[nrt]/ /g' \
         -e 's/\\\\/\\/g'
}

# Les blancs sont ramenés à une espace simple. Le rendu de production est **minifié** : une adresse
# postale écrite sur deux lignes y arrive sur une seule, et la comparer à la chaîne d'origine, sauts
# de ligne compris, ne trouvait rien — le contrôle passait au vert en laissant fuiter l'adresse
# (constat de la revue de la PR n° 98). Les fixtures des tests, écrites par « printf » sans passer
# par Hugo, ne pouvaient pas le montrer.
#
# **Le résultat tient sur une seule ligne** : les sauts de ligne deviennent des espaces, et un
# fichier entier passé à ce filtre en sort en une ligne. C'est ce qui rend sûre une recherche par
# « grep », qui travaille ligne par ligne et ne verrait jamais une chaîne à cheval sur deux lignes
# (pdf_confront, employée par C21 et par C22).
#
# **Le retour chariot en fait partie**, et l'oublier était un faux négatif mesuré : un fichier de
# static/ copié tel quel depuis un poste Windows porte des fins de ligne « \r\n », et « \r »
# survivait au filtre. Un motif à cheval sur deux lignes y devenait « Ville\r Cedex », que la
# recherche d'« Ville Cedex » ne trouve pas — même contenu, même motif, code 0 en CRLF contre code 1
# en LF (constat de la revue du code de la PR n° 117, reproduit avant d'être corrigé). C'est la même
# classe que l'entité « &rsquo; » ci-dessus : une écriture non couverte, et le garde-fou passe au
# vert sur une fuite. Le dépôt en porte la trace — les fichiers « *:Zone.Identifier » de
# docs/private/context/ viennent d'un téléchargement Windows.
normaliser_blancs() { tr '\r\n\t' '   ' | tr -s ' '; }

# Les entités des deux espaces insécables, ramenées à leur **caractère** (et non à une espace) : ce
# filtre décode, il ne replie pas — « replier_espaces_insecables » s'en charge ensuite. La sortie de
# production n'en porte aucune (le minifieur écrit U+00A0 et U+202F en clair, mesuré le 02/10/2026),
# mais une autre sérialisation de la même page — un minifieur réglé autrement, un gabarit qui écrit
# « &nbsp; » — les écrirait ainsi, et celle qu'on omet est celle qui fait échouer la vérification.
# **À passer avant « decoder_echappements »** : après lui, « &amp;nbsp; », qui désigne le texte
# « &nbsp; », serait déjà devenu « &nbsp; » et serait lu comme une insécable.
# Les caractères sont écrits par leurs octets UTF-8, que sed reçoit tels quels quelle que soit la
# locale : C sur CHECK_IMAGE et dans scripts/rehearse-release.sh, fr_FR.UTF-8 sur le poste.
decoder_espaces_insecables() {
  sed -E -e $'s/&(nbsp|#0*160|#[xX]0*[aA]0);/\xc2\xa0/g' \
         -e $'s/&(#0*8239|#[xX]0*202[fF]);/\xe2\x80\xaf/g'
}

# U+00A0 (insécable) et U+202F (fine insécable) deviennent une espace ordinaire, que
# « normaliser_blancs » repliera ensuite avec les autres. Pas U+2009 ni les autres espaces Unicode :
# la typographie du site ne pose que ces deux-là (DESIGN.md, layouts/_partials/typo-fr-texte.html).
replier_espaces_insecables() {
  sed -e $'s/\xc2\xa0/ /g' -e $'s/\xe2\x80\xaf/ /g'
}
