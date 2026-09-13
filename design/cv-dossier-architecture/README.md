# Maquette « Dossier d'architecture » — accueil CV

Deuxième tour de maquettes. L'accueil devient le CV : chaque poste montre les cas qui le prouvent. HTML et CSS statiques, français seulement, sans JavaScript.

- `index-bleu.html` : `<body class="accent-blue">`
- `index-vert.html` : `<body class="accent-green">` (seule différence avec la version bleue : cette classe)
- `style.css` : feuille commune
- `screenshots/` : captures

## Intention

Un document technique bien composé, qui se lit comme un bon ADR : texte en serif système, métadonnées en chasse fixe, mesure confortable, marges larges. La hiérarchie vient de la taille, de la graisse et de l'espace. Pas de dégradé, pas d'ombre, pas d'icône, pas de carte. Les seuls traits sont des filets de séparation.

Sur écran large, la page suit une grille de document à deux colonnes :

- **colonne de marge** (13,5 rem, alignée à droite) : photo, numéros de section (`§ 1`, `§ 2`, `§ 3`), dates et lieu de travail ;
- **colonne de texte** (40 rem au plus) : nom, titre, pitch, sociétés, rôles et cas.

Chaque poste se lit comme une ligne de registre : période et lieu à gauche, société en gras puis rôle et secteur à droite. Sur mobile, les deux colonnes s'empilent : la période vient au-dessus de la société.

L'en-tête corrige le premier tour. Il porte `eleyone.fr`, « À propos », « Contact » (ancre vers le pied de page), le choix de langue FR / EN et les deux liens « CV (PDF, français) » et « CV (PDF, English) », chacun avec un poids à compléter `[— Ko]`.

## Rattachement des cas au CV

Les cas sont une sous-liste du poste, sous le rôle, marquée par **un filet vertical de 2 px dans la couleur d'accent**. C'est l'équivalent d'une barre de révision dans la marge d'une RFC : on repère d'un coup d'œil les postes qui ont des preuves.

- Chaque cas porte son numéro en chasse fixe (`Cas 02`), en retrait suspendu sur écran large. Les numéros forment une colonne lisible verticalement.
- Le titre est un lien souligné, en demi-gras.
- Le cas 02 affiche son « En bref » (le `summary` de `content/cases/chiliz/case-02-chiliz.fr.md`). Les autres affichent « En bref à venir » en chasse fixe grisée.
- Un poste sans cas s'arrête après la ligne rôle · secteur. La colonne de marge (période, lieu) et le filet qui sépare les postes suffisent à le rendre complet. Aucune mention « aucun cas » ne vient souligner l'absence.
- Les listes de cas portent un `aria-label` (« Cas qui prouvent ce poste »), et les titres `h3` des sociétés structurent la page pour la navigation au lecteur d'écran.
- Le cas 06 reste sous April Technologies. Un commentaire HTML invisible signale que son rattachement est à confirmer (April Technologies 2017 ou mission CGI chez April 2013-2014).
- « En parallèle » est une section distincte (`§ 2`), avec le lien vers Ton Pote le Geek et le cas 01 rattaché de la même façon. Cette activité n'a pas de période dans les données : la colonne de marge reste vide plutôt que d'inventer une date.

## Palettes et contrastes

Contrastes WCAG 2.x calculés avec la formule de luminance relative (script Python dans le dossier temporaire de travail).

### Commun

| Rôle | Clair | Sombre |
|---|---|---|
| Fond | `#fbfbf9` | `#14161d` |
| Texte | `#1c2030` — 15,61:1 | `#e6e8ee` — 14,75:1 |
| Texte secondaire (dates, lieu, secteur, « En bref à venir ») | `#555b6e` — 6,52:1 | `#a3a9b8` — 7,68:1 |
| Libellé « Photo » sur le gris du cadre | `#4a5063` sur `#dfe2e9` — 6,18:1 | `#b8bdca` sur `#2b2f3a` — 7,11:1 |
| Filets de séparation (décoratifs) | `#c9cdd8` — 1,53:1 | `#3a3f4d` — 1,72:1 |

Les filets ne portent aucune information : la séparation des postes tient aussi à l'espace et aux titres. Ils ne relèvent donc pas du seuil de 3:1. Le filet de rattachement des cas, lui, est dans la couleur d'accent et dépasse 3:1.

### Accent bleu

| Mode | Couleur | Sur le fond | Usage |
|---|---|---|---|
| Clair | `#1f4f8f` | **7,88:1** | liens, filet des cas, contour de focus |
| Sombre | `#8db4ea` | **8,47:1** | idem |

Un bleu ardoise profond, de la même famille que les gris bleutés du thème D2 Neutral Grey : il ne jure pas avec les schémas.

### Accent vert

| Mode | Couleur | Sur le fond | Usage |
|---|---|---|---|
| Clair | `#1c6b45` | **6,26:1** | liens, filet des cas, contour de focus |
| Sombre | `#7cc79d` | **9,05:1** | idem |

Un vert sapin désaturé, qui reste sobre à côté du texte ardoise. Il est un peu plus sombre qu'un vert « web » pour tenir le 4,5:1 sur un fond presque blanc.

### Pire contraste par variante et par mode (texte et composants)

| Variante | Clair | Sombre |
|---|---|---|
| Bleu | 6,18:1 (libellé « Photo ») ; texte courant 6,52:1 | 7,11:1 (libellé « Photo ») ; texte courant 7,68:1 |
| Vert | 6,18:1 (libellé « Photo ») ; accent 6,26:1 | 7,11:1 (libellé « Photo ») ; texte courant 7,68:1 |

Tout dépasse 4,5:1 pour le texte et 3:1 pour le focus. Les liens restent soulignés (1 px, 2 px au survol), donc la couleur n'est jamais le seul indice. Le focus clavier est un contour de 2 px dans la couleur d'accent, décalé de 3 px ; il a été vérifié à la tabulation sur la capture.

## Poids mesurés

Mesurés avec `wc -c` et `gzip -9`.

| Fichier | Octets | gzip |
|---|---|---|
| `style.css` | 6 207 (6,1 Ko) | 2 134 |
| `index-bleu.html` | 7 620 | 2 431 |
| `index-vert.html` | 7 621 | — |
| **Page complète** (HTML + CSS) | **13 827 (13,5 Ko)** | ≈ 4,6 Ko |

- Budget AD-8 respecté : CSS ≤ 20 Ko, HTML ≤ 50 Ko, page ≤ 200 Ko.
- 2 ressources : HTML et CSS. L'image de la photo est un GIF transparent de 1 px en `data:`.
- 150 éléments HTML (budget 800), 0 script, 0 police web, 0 ressource externe.

## Mobile 390×844 sans défiler : ça tient

Tout ce qui est demandé est visible sans défiler :

- la ligne de nom ;
- le titre de rôle ;
- « Basé en France » ;
- le pitch en entier ;
- la première entrée du CV (période, lieu, Chiliz, rôle et secteur) ;
- le numéro et le titre complet du cas 02, et le début de son « En bref ».

Vérifié par Chromium sans interface (Playwright installé hors dépôt, dans un dossier temporaire), JavaScript de page désactivé. Le script lit les boîtes englobantes des éléments à 390×844, puis prend les captures. Deux jeux de polices ont été testés :

| Polices réellement rendues (lues par le protocole DevTools) | Bas du titre du cas 02 | Début de l'« En bref » |
|---|---|---|
| Sitka Text + Consolas (polices Windows) | 646 px | 655 px |
| DejaVu Serif + DejaVu Sans Mono (repli Linux, très large) | 747 px | 755 px |

- Charter (macOS, iOS) est plus étroit que ces deux polices : le résultat sur iPhone devrait être au moins aussi bon.
- Les captures utilisent les polices Windows : c'est le rendu le plus proche de la pile déclarée qui soit disponible ici.
- Contrôle de reflow à 320 px de large : pas de défilement horizontal (`scrollWidth` = 320).
- Sur mobile, l'en-tête tient en deux lignes (69 px) : navigation, puis les deux liens de CV.

## Captures

- `bleu-390-clair.png`, `vert-390-clair.png` (390×844, densité 2)
- `bleu-390-sombre.png`, `vert-390-sombre.png`
- `bleu-1440-clair.png`, `vert-1440-clair.png` (1440×900)
- `bleu-1440-clair-pleine-page.png` (pleine page)

## Limites

- **Photo** : cadre gris avec le libellé « Photo » et une `<img>` transparente qui porte `alt`, `width` et `height`, comme le fera la vraie photo. Le texte alternatif « Portrait d'Arnaud Grousset » décrit la photo à venir, pas le cadre.
- **Liens factices** : tous en `href="#"` (cas, À propos, EN, CV, contact). Les poids des PDF restent `[— Ko]`.
- **« En bref à venir »** : quand les résumés des cas 01, 03 à 06 arriveront, le bloc Chiliz s'allongera sur mobile. Seul le premier cas compte pour le pli, donc le pli n'est pas touché.
- **Charter non testé** : il n'est pas installé ici. Les mesures ont été faites avec Sitka Text et DejaVu Serif, qui sont plus larges.
- **Android** : sans Charter, Sitka ni Cambria, le navigateur prend sa serif par défaut (Noto Serif), proche en largeur de DejaVu Serif. Le pli tient aussi dans ce cas.
- **Grand écran** : l'« En bref » du cas 02 fait six lignes dans une colonne de 40 rem, ce qui est dense à côté des postes sans cas. On pourrait le raccourcir sur l'accueil, mais ce n'est pas le rôle d'une maquette.
- **Pied de page** : il ne contient pas les liens vers les mentions légales, prévus dans la version finale.
- **Sections numérotées** : les `§` sont masqués aux lecteurs d'écran (`aria-hidden`). C'est un choix de ton « document » qu'Arnaud peut refuser sans que la grille ne change.
- **Mode sombre** : il suit seulement `prefers-color-scheme`, sans bascule manuelle, puisqu'il n'y a pas de JavaScript.
