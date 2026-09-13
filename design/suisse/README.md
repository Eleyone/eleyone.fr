# Maquette de direction visuelle « Suisse »

Prototype statique HTML/CSS, à comparer avec la direction « Dossier d'architecture ». Ce n'est pas le site : ni Hugo, ni gabarits. Le contenu est réel (titre, pitch, cas 02) ou signalé comme provisoire.

| Fichier | Rôle |
|---|---|
| `index.html` | Accueil FR : titre du site, pitch, cas mis en avant 01, 02, 05, activité parallèle, contact |
| `cas-chiliz.html` | Page Chiliz avec la section du cas 02, puis un bloc « Exemple de schéma (maquette) » |
| `style.css` | Feuille unique : jetons, grille, composants |
| `diagram-example.svg` | Copie de `experiments/d2-bilingue/svg/reconciliation.fr.elk.svg` (branche `experiment/d2-bilingue`) |
| `screenshots/` | Captures de relecture (Chromium sans interface, hors dépôt) |

Ouvrir `index.html` directement dans un navigateur : aucun serveur n'est nécessaire.

## Intention

Graphisme suisse appliqué à un portfolio : net, moderne, sans date.

- **Le texte fait la mise en page.** Une police système, deux graisses (400 et 700, 500 et 600 pour les valeurs et les libellés). La hiérarchie repose sur la taille et sur de petits libellés en capitales espacées, pas sur des couleurs ou des cadres.
- **Une grille stricte, un axe.** Sur grand écran, douze colonnes : les libellés de section occupent les colonnes 1 à 3 et tout le contenu s'aligne sur la colonne 4. Le titre du site part de la colonne 1, le pitch se décale sur l'axe : l'asymétrie est voulue.
- **Un seul accent, en aplat ou en filet.** Un rouge suisse pour le bandeau de tête, le carré de la marque, les numéros de cas, le filet de l'encart « En bref », les tirets de liste et l'anneau de focus. Aucun dégradé, aucune ombre, aucun arrondi, aucune image décorative.
- **Des filets pour structurer.** Filet fort (2 px, couleur du texte) en ouverture de section, filet fin (1 px) entre éléments.
- **Des encarts traités comme des blocs de grille.** « Contexte mission » est une liste libellé / valeur (`<dl>`) : en colonnes libellé | valeur sur mobile, en bande de cinq cellules sur grand écran. « En bref » est un aplat clair coiffé d'un filet rouge, avec un texte plus grand.

## Palette et contrastes

Le texte (`#1F2933`), les filets fins (`#D9E2EC`) et l'aplat reprennent les valeurs du thème D2 Neutral Grey du schéma, pour que schéma et page parlent la même langue. Le rouge est la seule couleur saturée.

Rapports de contraste calculés selon la formule WCAG 2.x (luminance relative sRGB), avec le script de relecture.

### Thème clair

| Jeton | Valeur | Sur fond `#FFFFFF` | Sur aplat `#F4F6F8` | Usage |
|---|---|---|---|---|
| `--text` | `#1F2933` | **14,76:1** | **13,62:1** | texte, titres, filets forts |
| `--muted` | `#52606D` | **6,46:1** | 5,96:1 (non utilisé) | libellés, métadonnées, légendes, bordure du repère « à venir » |
| `--accent` | `#D52B1E` | **5,01:1** | non utilisé | numéros, libellé du bloc maquette, survol des liens, focus |
| `--line` | `#D9E2EC` | 1,31:1 | | filets fins décoratifs, bordure des étiquettes de stack (le texte porte l'information) |
| lien d'évitement | `#FFFFFF` sur `#1F2933` | **14,76:1** | | |

### Thème sombre (`prefers-color-scheme: dark`)

| Jeton | Valeur | Sur fond `#12161B` | Sur aplat `#1C232B` | Usage |
|---|---|---|---|---|
| `--text` | `#E4E7EB` | **14,64:1** | **12,78:1** | |
| `--muted` | `#9AA5B1` | **7,26:1** | 6,33:1 (non utilisé) | |
| `--accent` | `#FF6B5B` | **6,49:1** | non utilisé | |
| `--line` | `#323F4B` | 1,68:1 | | décoratif |
| lien d'évitement | `#12161B` sur `#E4E7EB` | **14,64:1** | | |
| plaque du schéma | `#FFFFFF` | 18,16:1 | | fond blanc du SVG D2, conservé |

**Pire paire effectivement utilisée :** clair, accent sur fond, **5,01:1** ; sombre, accent sur fond, **6,49:1**. Tout le texte passe 4,5:1, petits libellés de 12 px compris. L'anneau de focus (accent) dépasse 3:1 sur les deux fonds.

## Échelle typographique

Pile : `system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`. Tailles en `rem` (elles suivent le zoom et la taille de texte du navigateur) ; les tailles fluides combinent `rem` et `vw` dans un `clamp()`.

| Rôle | Jeton | Taille | Graisse, interlignage |
|---|---|---|---|
| Titre du site, titre de page | `--fs-display` | 32 → 76 px | 700, 1,05, approche −0,03 em |
| Titre de cas, liens de contact | `--fs-h2` | 26 → 44 px | 700, 1,12 |
| Pitch, texte « En bref » | `--fs-lead` | 18 → 24 px | 400, 1,45 |
| Titre de rubrique, titre de cas en liste | `--fs-h3` | 19 px (24 px en liste sur grand écran) | 700, 1,25 |
| Texte courant | `--fs-base` | 17 px | 400, 1,55, 40 em de mesure au plus |
| Métadonnées, légendes, étiquettes | `--fs-small` | 14 px | 400 |
| Libellés | `--fs-label` | 12 px, capitales, +0,08 em | 600 |

Numéros de cas en chiffres tabulaires (`font-variant-numeric: tabular-nums`). `text-wrap: balance` sur les titres et `pretty` sur les paragraphes (amélioration progressive).

## Grille et espacements

- **Mobile (base) :** une colonne, marges de 20 px, gouttière de 16 px.
- **À partir de 64 rem (1024 px) :** douze colonnes, largeur utile de 76 rem au plus (1216 px), marges de 40 px, gouttière de 24 px. Classes : `.col-label` (1-3), `.col-main` (4-12), `.col-text` (4-10, mesure de lecture), `.col-wide` (1-10).
- **Espacements :** pas de 4 px, `--s-1` à `--s-7` = 4, 8, 16, 24, 40, 64, 96 px.
- Une seule rupture de mise en page : le mobile est la mise en page de référence, pas une réduction du bureau.

## Poids mesurés

Octets non compressés (`wc -c`), même unité que le budget AD-8. Gzip entre parenthèses, pour information.

| Fichier | Octets | Gzip |
|---|---|---|
| `style.css` | 11 008 (10,7 Ko) | 3 405 |
| `index.html` | 4 450 (4,3 Ko) | 1 710 |
| `cas-chiliz.html` | 10 434 (10,2 Ko) | 3 972 |
| `diagram-example.svg` | 20 438 (20,0 Ko) | 10 381 |

| Page | Ressources | Poids total | Éléments HTML |
|---|---|---|---|
| Accueil | 2 (HTML, CSS) | **15 458 octets (15,1 Ko)** | 73 |
| Page Chiliz, avec le schéma d'exemple | 3 (HTML, CSS, SVG) | **41 880 octets (40,9 Ko)** | 118 |

Budget AD-8 : CSS ≤ 20 Ko, HTML ≤ 50 Ko, SVG ≤ 60 Ko, page ≤ 200 Ko, 10 ressources et 800 éléments au plus. Tout est respecté, avec une large marge. Aucun JavaScript, aucune police web, aucune ressource externe (vérifié par recherche de `<script`, `http`, `@import` et `url(` dans les fichiers).

## Ce qui tient sans défiler à 390 × 844

**Oui, ça tient.** Mesure faite dans Chromium sans interface, viewport CSS de 390 × 844, en relevant la position des éléments (`getBoundingClientRect`).

La police système de la machine de relecture est **DejaVu Sans**, nettement plus large que San Francisco (iOS) ou Roboto (Android) : c'est un cas défavorable. Seconde mesure avec **Ubuntu Sans** injectée pour l'occasion, plus proche des métriques de Roboto (l'injection est un outil de relecture et ne figure pas dans `style.css`).

| Élément (haut → bas, px) | DejaVu Sans | Ubuntu Sans |
|---|---|---|
| En-tête (marque, navigation, FR / EN) | 6 → 92 (deux lignes) | 6 → 56 (une ligne) |
| Titre du site | 116 → 252 | 80 → 217 |
| Pitch, trois phrases | 268 → 454 | 233 → 419 |
| Libellé « Cas mis en avant » | 520 → 536 | 485 → 500 |
| Cas 01, titre et repère « En bref à venir » | 552 → 636 | 516 → 600 |
| Cas 02, titre | 672 → 743 | 637 → 684 |

Sans défiler, on voit donc le titre du site, le pitch, **tout le premier cas mis en avant (01)**, et le libellé, le titre et la ligne de métadonnées du cas 02, voire le début de son résumé.

Réserve : 844 px est la hauteur d'écran. Dans Safari sur iPhone, les barres du navigateur laissent à peu près 660 à 750 px visibles. Le cas 01 se termine à 600-636 px : il reste visible dans ce cas aussi, mais le cas 02 passe sous la ligne de flottaison. Voir `screenshots/accueil-390x844-light.png`.

## Accessibilité (WCAG 2.2 AA)

- `lang="fr"` sur la page et `lang="en"` sur le lien EN ; `<title>` propre à chaque page ; `meta color-scheme`.
- Repères : `header`, deux `nav` nommés (« Navigation principale », « Langue »), `main`, `footer` ; fil d'Ariane nommé sur la page Chiliz. Lien d'évitement « Aller au contenu », visible au focus.
- Ordre des titres : accueil h1 → h2 (sections) → h3 (cas) ; page Chiliz h1 « Chiliz » → h2 titre du cas → h3 encarts et rubriques, ce qui correspond au niveau 2 prévu par l'architecture pour un cas dans une section de groupe.
- Chaque section et chaque encart est relié à son titre (`aria-labelledby`). « Contexte mission » est une vraie liste de définitions.
- Numéros de cas de l'accueil masqués aux aides techniques (`aria-hidden`) et repris dans le lien sous la forme « Cas 01 : … », texte visuellement masqué.
- Le « · » du titre du site est gardé dans le DOM (masqué visuellement) : le titre se lit et se copie en entier, alors que l'affichage le coupe en deux lignes.
- Langue courante signalée par `aria-current="page"`, pas seulement par le soulignement rouge. Le séparateur « / » est un contenu CSS au texte alternatif vide.
- Focus visible : contour de 3 px couleur accent, décalé de 3 px (mesuré : `solid 3px`). Voir `screenshots/focus-accueil-390x844-light.png`.
- Cibles : liens de navigation d'au moins 24 px de haut (critère 2.5.8).
- Redimensionnement et redistribution : tailles en `rem`, aucune hauteur fixe ; à 320 px de large (équivalent zoom 400 %), `scrollWidth` = 320 sur les deux pages, sans défilement horizontal.
- Mode sombre en CSS pur, contrastes vérifiés ci-dessus. `forced-colors` : le carré de la marque et les tirets de liste restent visibles.
- Schéma : `width` et `height` explicites (pas de décalage de mise en page) et texte alternatif qui décrit le flux.
- **Non fait :** audit automatisé (axe ou équivalent) et test avec un lecteur d'écran. Les points ci-dessus sont vérifiés à la main ou par mesure.

## Limites connues et points à trancher

1. **Accent rouge ou bleu ardoise.** Le rouge distingue nettement cette direction et fonctionne avec le schéma gris-bleu, mais il n'appartient pas à la palette D2. Un bleu ardoise (`#334E68`, déjà dans le schéma) serait plus fondu et moins marqué. À trancher.
2. **Schéma en thème sombre.** Le SVG D2 porte un fond blanc codé en dur, et un `<img>` ne se restyle pas en CSS. La maquette le pose sur une plaque blanche : lisible et honnête, mais c'est un rectangle clair dans une page sombre. Les alternatives sont un second rendu D2 en thème sombre avec `<picture>` et `prefers-color-scheme` (deux SVG par schéma et par langue) ou un SVG en ligne restylé, ce qui change la chaîne des schémas.
3. **Polices du schéma.** Le SVG embarque ses propres polices (deux fontes en `data:`, dans les 20 Ko). Ce n'est pas une ressource externe, mais c'est une exception à « police système seulement ». Dans la capture, certains libellés touchent le bord de leur boîte (« Import et normalisation des données exportées ») : à signaler sur la branche d'expérimentation.
4. **En-tête mobile.** Avec une police large, la marque, « À propos », « Contact » et « FR / EN » passent sur deux lignes (36 px de plus). Avec les polices des téléphones, ils tiennent sur une ligne. On peut garder le retour à la ligne, ou sortir « À propos » de l'en-tête sur mobile.
5. **Typographie française.** Le contenu est rendu tel qu'il est dans le fichier, avec des espaces ordinaires devant « : » et « ; ». Un deux-points peut donc ouvrir une ligne. Les mots à trait d'union se coupent au trait (« on-/chain », « ci-/dessous » sur mobile). Il faut une règle : espaces insécables dans le contenu, ou traitement au rendu.
6. **Cas mis en avant (question 7 du PRD).** La maquette propose, pour le cas 02 : le titre court en libellé, le titre du cas, « Chiliz · période », puis le résumé « En bref » complet. Les cas 01 et 05, pas encore rédigés, n'ont que leur titre court et le repère « En bref à venir ». L'asymétrie disparaîtra quand ils existeront. Leurs liens sont fictifs (`#`).
7. **Libellés d'interface FR proposés, non décidés :** « Salarié » (cadre `employee`), « Cas mis en avant », « Activité parallèle », « Accueil / Cas », « Aller au contenu », « Mentions légales ». Ils iront dans `i18n/fr.yaml`.
8. **Mention de l'activité parallèle :** texte provisoire, marqué comme tel par un commentaire HTML. Son emplacement (accueil ou « À propos ») reste la question 8 du PRD.
9. **Titre du site sur grand écran :** 76 px sur quatre lignes, avec du blanc à droite. C'est le parti pris suisse (asymétrie, blanc actif), mais cela repousse les cas vers le bas : à 1440 × 900, le cas 01 est visible, le cas 02 n'apparaît qu'en haut de ligne. On peut plafonner `--fs-display` plus bas.
10. **Page Chiliz :** titre seul, sans introduction (question 9 du PRD). Les trois éléments `live_material` du cas 02 sont `planned` et ne produisent rien. Le bloc « Exemple de schéma (maquette) » n'appartient pas au cas.
11. **Captures :** densité 1×, rendues avec DejaVu Sans : le rendu réel sur macOS, iOS, Windows ou Android sera plus serré et plus fin. Les captures pèsent environ 1,3 Mo au total, dont 556 Ko pour la page Chiliz entière : à garder ou non dans le dépôt public.

## Comment les captures ont été faites

Playwright (Python) et Chromium sans interface, installés dans un dossier temporaire hors du dépôt avec `uv`. Les bibliothèques système manquantes ont été extraites de paquets `.deb` dans ce même dossier, sans droits administrateur. Aucun outil n'est une dépendance du projet.

Captures produites : accueil et page Chiliz, à 390 × 844 et 1440 × 900, en clair et en sombre (viewport seul). S'y ajoutent la page Chiliz entière à 1440 px en clair, le bloc de schéma en sombre et l'état de focus sur mobile.
