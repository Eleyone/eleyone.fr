# Maquette « Suisse » — accueil CV

Deuxième tour de maquettes. L'accueil devient le CV d'Arnaud : chaque poste montre les cas qui le prouvent. Page d'accueil seule, en français, en HTML et CSS statiques.

- `index-bleu.html` : `<body class="accent-blue">`
- `index-vert.html` : `<body class="accent-green">`
- `style.css` : feuille commune aux deux variantes
- `screenshots/` : captures

## Intention

Graphisme suisse : une grille de 12 colonnes, une seule famille de polices (celle du système), une hiérarchie très marquée, de petites étiquettes en capitales espacées et beaucoup de blanc. L'accent est toujours un aplat ou un filet : la barre du haut de page, le filet vertical des cas et le bloc du numéro de cas. Il n'y a ni dégradé, ni ombre, ni icône.

Une entrée du CV se lit comme une ligne de tableau : **période → poste → cas qui le prouvent**. Un recruteur parcourt la colonne de gauche pour la chronologie, celle du milieu pour les employeurs et celle de droite pour les preuves.

Corrections par rapport au premier tour :

- **Taille du nom plafonnée** : `clamp(1.75rem, 1.2rem + 2.2vw, 3rem)`, soit 28 px sur mobile et 48 px au maximum. À 1440×900, le parcours commence à 445 px et le titre du cas 02 est à 498 px.
- **Typographie française** :
  - pas de césure automatique (`hyphens: manual`, valeur calculée vérifiée dans le navigateur) ;
  - espace insécable avant « : » ;
  - `white-space: nowrap` sur « on-chain », « dix-huit », « ci-dessous » et « PHP/Symfony » ;
  - insécables dans les dates (« juillet 2022 – avril 2026 ») et devant les points médians ;
  - apostrophes typographiques.

## Comment les cas s'accrochent au CV

- **Sur bureau**, une troisième colonne porte l'en-tête « Cas qui le prouvent ». Chaque cas y occupe une ligne :
  - un **bloc d'accent avec le numéro** (`02`) ;
  - le **titre en lien souligné** ;
  - dessous, soit l'« En bref » (étiquette en tête de paragraphe, pour le cas 02), soit l'étiquette « En bref à venir ».
- Un **filet vertical d'accent de 3 px** relie tous les cas d'un même poste : on voit d'un coup d'œil que Chiliz en compte trois, April et Orange un chacun.
- **Sur mobile**, la colonne passe sous le poste et garde son filet et ses numéros. Le lien visuel ne dépend pas de l'en-tête de colonne.
- **Pour un lecteur d'écran**, la liste des cas s'intitule « Cas qui prouvent ce poste ». Chaque lien est annoncé « Cas 02 : Faire d'une application… » : le préfixe est masqué visuellement, et le numéro visible est en `aria-hidden`.
- **Postes sans cas** (Synolia, Mister Auto, Parcours antérieur) : la ligne reste pleine, avec période, secteur, lieu et rôle. Sur bureau, un tiret cadratin gris occupe la cellule, comme dans un tableau imprimé où une case vide est voulue. Sur mobile, rien n'est affiché. Le tiret est masqué aux lecteurs d'écran.
- **Parcours antérieur** : la mission chez April pour le compte de CGI (2013 – 2014) est une ligne de détail sous le rôle, marquée d'un filet fin. Ce n'est pas un cas.
- **Cas 06** : il reste sous April Technologies. Un commentaire HTML signale que son rattachement est à confirmer. Rien n'est visible.
- **En parallèle — Ton Pote le Geek** : un panneau à fond teinté, ouvert par un filet épais, reprend la même grille. Il est nettement séparé de la chronologie mais se lit de la même façon.
- **Lieux de travail** : sous la période, en gris (« Lyon, prestation Modis », « Full remote, équipe internationale »…). « Basé en France » reste la seule mention du lieu de résidence, dans le bloc d'identité.

## Palettes et contrastes

Les neutres reprennent le thème D2 **Neutral Grey** : texte ardoise `#0a0f25` (N1), filets `#cfd2dd` (N4), placeholder `#dee1eb` (N5) et surface `#eef1f8` (N6). Les schémas D2 s'intégreront donc sans rupture. Le mode sombre est en CSS pur (`prefers-color-scheme`).

Rapports calculés avec la formule de luminance relative WCAG 2.x (script Python, valeurs arrondies au centième).

### Clair — fond `#ffffff`, surface `#eef1f8`

| Paire | Rapport |
|---|---|
| Texte `#0a0f25` / fond | 18,95 |
| Texte / surface | 16,76 |
| Texte secondaire `#4f5566` / fond | 7,44 |
| Texte secondaire / surface | 6,58 |
| Étiquette « Photo » `#4f5566` / placeholder `#dee1eb` | 5,69 |
| « FR » actif `#ffffff` / `#0a0f25` | 18,95 |
| **Bleu** `#1f45c4` (liens, focus, filets) / fond | 7,76 |
| Bleu / surface | 6,86 |
| Numéro `#ffffff` / bleu | 7,76 |
| **Vert** `#0a6e38` (liens, focus, filets) / fond | 6,36 |
| Vert / surface | 5,63 |
| Numéro `#ffffff` / vert | 6,36 |

### Sombre — fond `#0e1220`, surface `#171c2c`

| Paire | Rapport |
|---|---|
| Texte `#e6e9f2` / fond | 15,37 |
| Texte / surface | 13,97 |
| Texte secondaire `#a3a9bb` / fond | 7,95 |
| Texte secondaire / surface | 7,22 |
| Étiquette « Photo » / placeholder `#262c3d` | 5,93 |
| « FR » actif `#0e1220` / `#e6e9f2` | 15,37 |
| **Bleu** `#8fb0ff` / fond | 8,72 |
| Bleu / surface | 7,93 |
| Numéro `#0e1220` / bleu | 8,72 |
| **Vert** `#5cd08a` / fond | 9,63 |
| Vert / surface | 8,75 |
| Numéro `#0e1220` / vert | 9,63 |

### Pire contraste de texte, par variante et par mode

| Variante | Mode | Pire contraste | Accent seul |
|---|---|---|---|
| Bleu | clair | 5,69 (étiquette « Photo ») | 6,86 |
| Vert | clair | 5,63 (lien vert sur surface) | 5,63 |
| Bleu | sombre | 5,93 (étiquette « Photo ») | 7,93 |
| Vert | sombre | 5,93 (étiquette « Photo ») | 8,75 |

Tout texte et tout lien dépasse 4,5:1. L'anneau de focus (3 px, couleur d'accent, décalé de 3 px) dépasse 3:1 partout, avec 5,63 au minimum.

Les filets fins (`#cfd2dd` en clair, `#2e3446` en sombre, 1,51:1) sont décoratifs. La séparation des lignes est aussi portée par l'espacement et par les titres, ce qui les exclut du critère 1.4.11.

**Liens reconnaissables sans la couleur** : tous sont soulignés en permanence, et le soulignement s'épaissit au survol. « FR » (langue courante) est un aplat inversé, « EN » un lien souligné.

## Poids mesurés

| Fichier | Octets | gzip -9 |
|---|---|---|
| `style.css` | 11 615 | 3 130 |
| `index-bleu.html` | 9 460 | 2 550 |
| `index-vert.html` | 9 461 | ≈ 2 550 |
| **Page complète** (HTML + CSS) | **21 075** | **≈ 5 680** |

- Le CSS pèse 11,6 Ko, sous la limite de 20 Ko.
- Aucun `<script>` (vérifié par `grep`), aucune ressource externe : la seule référence est `style.css`. Aucune requête hors `file://` n'a été relevée pendant les captures. Aucune police téléchargée.

## Ce qui tient sans défiler à 390×844

Positions mesurées dans le navigateur (`getBoundingClientRect`, en px depuis le haut de l'écran, clair et sombre identiques) :

| Élément | Haut → bas |
|---|---|
| Nom « Arnaud Grousset · Eleyone » (2 lignes) | 74 → 134 |
| Titre de rôle | 142 → 188 |
| Pitch complet | 228 → 372 |
| Liens CV (PDF) | 388 → 442 |
| Première entrée : « Chiliz », puis « Senior Backend Developer » | 512 → 536 |
| Période, secteur, lieu | 562 → ≈ 600 |
| **Premier cas : numéro 02 et titre complet** | **619 → 662** |
| « En bref » du cas 02 | commence à 666, coupé au pli (844) |
| Deuxième cas (03) | 904, sous le pli |

**Ça tient**, avec environ 180 px de marge sous le titre du premier cas. La page ne défile pas horizontalement : `scrollWidth` vaut 390 à 390 px et 1440 à 1440 px.

Méthode : Playwright 1.55 et Chromium sans interface, installés dans un dossier temporaire hors du dépôt (build de repli Ubuntu 24.04, trois bibliothèques extraites localement sans installation système). Script : viewport 390×844 puis 1440×900, `colorScheme` clair puis sombre, mesures relevées avant chaque capture.

## Captures

- `screenshots/bleu-390-clair.png`, `screenshots/vert-390-clair.png`
- `screenshots/bleu-390-sombre.png`, `screenshots/vert-390-sombre.png`
- `screenshots/bleu-1440-clair.png`, `screenshots/vert-1440-clair.png`
- `screenshots/bleu-1440-clair-page-entiere.png` (page entière)

## Limites

- **Polices** : les captures sont rendues sous Linux, où `system-ui` donne DejaVu ou Ubuntu, assez larges. San Francisco (iOS, macOS) et Segoe UI sont plus étroites : le pli mobile y sera plutôt plus confortable, mais les retours à la ligne différeront.
- **Photo** : un `div` avec `role="img"` et un `aria-label` tient lieu de photo, puisqu'aucune vraie image n'est utilisée. En production, ce sera un `<img>` avec `alt`, `width` et `height`.
- **Tiret des postes sans cas** : c'est un pari. Si Arnaud le lit comme « manquant », on peut retirer le tiret et laisser la cellule vide, ou y remonter le lieu.
- **Largeur des colonnes** : à 1440 px, « Mister Auto (groupe PSA) » et la ligne de détail CGI passent sur plusieurs lignes dans la colonne du milieu (3/12). C'est acceptable, mais c'est la colonne la plus serrée.
- **Mode sombre** : il suit uniquement le système, sans bouton, faute de JavaScript.
- **Espaces** : « : » est précédé d'une insécable normale (U+00A0). Aucun « ; », « ? » ou « ! » n'apparaît dans le texte actuel ; ils prendront une fine insécable (U+202F) quand il y en aura.
- **Libellés d'interface ajoutés** : « Parcours », « Poste », « Cas qui le prouvent », « En bref », « Repères », « Formation », « Certification », « Langues », « Contact », « Aller au parcours ». Ce sont des étiquettes d'interface, pas des faits.
- **Colophon « Maquette statique »** : il est propre à la maquette et est à retirer.
- **Placeholders** : `[poids Ko]`, `[email]` et `[LinkedIn]` restent à remplir ; tous les liens pointent vers `#`.
- **Villes** : les villes de travail et « IUT2 Grenoble » sont affichées à la demande d'Arnaud. La règle de `AGENTS.md` (« ni ville ») vise la résidence ; elle mériterait d'être précisée pour ne pas contredire la maquette.
