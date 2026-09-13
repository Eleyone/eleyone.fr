# Maquette « Dossier d'architecture »

Prototype visuel statique (HTML + CSS), pas le site : ni Hugo ni gabarits. À comparer avec la direction « Suisse ».

- `index.html` : accueil FR.
- `cas-chiliz.html` : page du groupe Chiliz avec le contenu réel du cas 02.
- `style.css` : feuille unique, jetons en tête (couleurs, échelle typographique, espacements).
- `diagram-example.svg` : copie de `experiments/d2-bilingue/svg/reconciliation.fr.elk.svg` (branche `experiment/d2-bilingue`).
- `screenshots/` : captures de revue.

## Intention

Le site se lit comme un document technique bien composé : une ADR ou une RFC soignée. La hiérarchie vient de la taille, de la graisse et de l'espace, pas de la décoration.

- Texte en serif système, métadonnées (dates, numéros, stack, étiquettes) en monospace système.
- Une colonne de lecture d'environ 68 caractères, des marges larges.
- Encre sombre sur papier clair, une seule couleur d'accent : un rouge brique, comme l'annotation d'un relecteur sur un plan. Il marque les liens, les numéros de cas et de sections, et le focus.
- Encarts façon RFC : « En bref » est un résumé à filet d'accent ; « Contexte mission » est une note de marge. Sur grand écran (≥ 72 rem, soit 1 296 px à 18 px), il passe dans la marge droite et le sommaire se fixe dans la marge gauche.
- Sections numérotées comme un dossier (1.1 Contexte, 1.2 Le problème…), sommaire assorti.
- Accueil : le titre, le pitch, puis un index des cas, avec des numéros suspendus dans la marge sur grand écran.
- Ni dégradé, ni ombre, ni photo, ni icône.

## Palette et contrastes

Ratios WCAG 2.x calculés avec la formule de luminance relative (script Python hors dépôt). Les deux fonds de texte sont le papier et la teinte des encarts.

### Clair

| Rôle | Couleur | sur papier `#FBFAF7` | sur encart `#F0F2F4` |
|---|---|---|---|
| Texte (`--ink`, = texte des schémas D2) | `#1F2933` | 14,14 | 13,15 |
| Texte secondaire (`--muted`) | `#52606D` | 6,19 | **5,75** (pire paire de texte) |
| Accent : liens, numéros, focus | `#9C3B1B` | 6,59 | 6,13 |
| Filets de structure (`--rule`) | `#7B8794` | 3,51 | 3,26 |
| Filets décoratifs (`--hairline`) | `#D9DEE3` | 1,30 | décoratif seulement |

### Sombre (`prefers-color-scheme: dark`)

| Rôle | Couleur | sur papier `#15191E` | sur encart `#1E252C` |
|---|---|---|---|
| Texte | `#E4E7EB` | 14,23 | 12,48 |
| Texte secondaire | `#A3AEBA` | 7,83 | **6,87** (pire paire de texte) |
| Accent | `#F0A07E` | 8,43 | 7,40 |
| Filets de structure | `#6B7785` | 3,87 | 3,39 |
| Filets décoratifs | `#2E3740` | 1,46 | décoratif seulement |

Toutes les paires de texte dépassent 4,5:1. Le focus (accent) et les filets porteurs de sens (bordure en tirets du « En bref à venir ») dépassent 3:1. Seuls les filets décoratifs restent sous ce seuil, ce que WCAG autorise.

L'accent et le texte courant ne se distinguent que par 2,15:1 (clair) et 1,69:1 (sombre). **Les liens sont donc toujours soulignés** (critère 1.4.1) : la couleur ne porte jamais seule l'information.

### Accord avec les schémas D2

L'encre `#1F2933` est celle du thème D2 ; le gris-bleu des filets vient de la même famille que les bordures `#334E68`/`#486581`. L'accent brique est la seule couleur chaude de la page : il ne concurrence pas les schémas, qui restent entièrement ardoise. Dans le SVG lui-même : `#1F2933` sur `#F8FAFC` = 14,1 ; `#3E4C59` sur `#E4E7EB` = 7,1 ; `#616E7C` sur blanc = 5,21.

En sombre, le schéma reste une **planche claire** (le thème sombre D2 n'a pas été testé), posée sur un fond `#EBEBEB` et atténuée par `filter: brightness(0.92)` pour éviter l'éblouissement.

## Typographie

- **Serif** : `Charter, "Bitstream Charter", "Sitka Text", Cambria, "Noto Serif", "DejaVu Serif", serif`. Charter sur macOS et iOS, Sitka Text ou Cambria sur Windows, Noto Serif sur Android et la plupart des Linux.
- **Monospace** : `ui-monospace, "SF Mono", Menlo, Consolas, "Liberation Mono", "DejaVu Sans Mono", monospace`.
- **Corps** : 17 px sous 48 rem, 18 px au-delà, en pourcentage de la taille du navigateur (le réglage utilisateur est respecté). Interligne 1,55.
- **Échelle** : rapport 1,2 (tierce mineure), en rem : `-1` 0,833 · `0` 1 · `1` 1,2 · `2` 1,44 · `3` 1,728 · `4` 2,074.

| Élément | Mobile | Grand écran |
|---|---|---|
| Titre d'accueil (h1) | 1,44 rem, 700 | 1,728 rem |
| Pitch | 1 rem | 1,2 rem |
| Titre de page de groupe (h1) | 2,074 rem | 2,074 rem |
| Titre du cas (h2) | 1,728 rem | 1,728 rem |
| Sections (h3) | 1,44 rem, numéro mono 0,7 em en accent | idem |
| Titre de cas sur l'accueil | 1,2 rem | 1,2 rem |
| Métadonnées, étiquettes | mono 0,833 rem (étiquettes en capitales, +0,08 em) | idem |

- **Mesure** : colonne de 38 rem, soit environ 68 caractères en serif.

Sur l'accueil, le titre est découpé en deux segments insécables au « · ». Sur grand écran, il tient donc en deux lignes, sans « · » orphelin en début de ligne.

## Poids mesurés

Mesurés avec `wc -c` (octets, non minifié ; gzip -9 entre parenthèses).

| Fichier | Octets |
|---|---|
| `style.css` | 10 145 (3 163 gzip) : **budget 20 Ko respecté** |
| `index.html` | 3 291 |
| `cas-chiliz.html` | 9 830 |
| `diagram-example.svg` | 20 438 (10 356 gzip ; polices du schéma embarquées en base64 par D2) |

| Page | Total transféré | Budget 200 Ko |
|---|---|---|
| Accueil (HTML + CSS) | **13 436 o** | respecté |
| Page Chiliz (HTML + CSS + SVG de maquette) | **40 413 o** | respecté |

- Aucun `<script>`, aucune URL externe : vérifié par `grep` sur `<script`, `http`, `@import` et `url(`. Les seules URL du SVG sont ses espaces de noms XML.
- Aucune police web dans la page. Le SVG embarque ses propres polices : c'est le rendu D2 standard, et ce n'est pas une ressource externe.

## Visible sans défilement à 390×844

Mesuré avec Chromium sans interface (Playwright, installé hors dépôt), en relevant les positions `getBoundingClientRect()` à 390×844 :

| Élément de l'accueil | Position verticale (px) |
|---|---|
| En-tête `eleyone.fr` · FR / EN | 0 – 44 |
| Titre (4 lignes) | 69 – 186 |
| Pitch (7 lignes) | 203 – 388 |
| « Cas mis en avant » | 430 – 457 |
| **Cas 01** « Calculette de rentabilité » + « En bref à venir » | 474 – 569 |
| Titre du cas 02 | 587 – 660 |
| Méta et début du résumé du cas 02 | jusqu'à 844 |

**Verdict : l'objectif tient, avec de la marge.**

- **Viewport complet de 844 px** : on voit le titre, le pitch, le premier cas en entier et le début du cas 02.
- **Safari iOS avec ses barres (environ 660 à 750 px utiles)** : le cas 01 reste entièrement visible, et le titre du cas 02 affleure.

Limite de la mesure : cette machine n'a ni Charter ni Sitka. Le rendu utilise DejaVu Serif, nettement plus large que Charter. Sur iPhone, le texte devrait donc occuper moins de lignes : l'estimation est prudente.

Sur la page Chiliz mobile, l'ordre est le suivant : fil d'Ariane, « Chiliz », sommaire (177–407), titre du cas (476–617), puis « En bref » (642–991), qui commence dans le premier écran. « Contexte mission » vient ensuite.

## Accessibilité

- `lang="fr"`, repères `header` / `nav` / `main` / `footer`, lien d'évitement « Aller au contenu » visible au focus.
- Titres dans l'ordre :
  - accueil : h1 titre, h2 « Cas mis en avant » et « Contact », h3 par cas ;
  - page Chiliz : h1 « Chiliz », h2 sommaire et titre du cas, h3 sections et « En bref ».
- Fil d'Ariane en liste ordonnée avec `aria-current="page"`. Langue courante marquée par `aria-current`, lien EN avec `lang="en"` et `hreflang`.
- « En bref » est une `section` titrée ; « Contexte mission » est un `aside` étiqueté, avec une liste de définitions. La stack est une liste.
- L'ordre du DOM suit l'ordre de lecture mobile : « En bref » puis « Contexte mission ». Le passage en marge utilise la grille CSS, pas un flottant qui aurait imposé l'ordre inverse.
- Focus visible : contour de 2 px en accent, décalé de 3 px (6,59:1 en clair, 8,43:1 en sombre).
- Liens soulignés en permanence, trait plus épais au survol.
- Tailles en rem, suivant le réglage du navigateur. Vérifié avec Chromium :
  - aucun défilement horizontal à 320 px (équivalent d'un zoom à 400 % sur 1 280 px, critère 1.4.10) ;
  - aucun défilement horizontal à 390 px avec le texte agrandi à 200 % (`overflow-wrap: break-word`).
- Schéma : `alt` qui décrit le flux complet, dimensions intrinsèques déclarées (pas de décalage de mise en page), lien vers la taille réelle.
- Matériel vivant `planned` : rien n'est rendu, seulement un commentaire HTML à l'emplacement du marqueur.
- Non vérifié ici : lecteur d'écran réel, mode contraste forcé de Windows.

## Captures

Rendu Chromium, `device_scale_factor` 1, polices de repli DejaVu :

- `screenshots/{index,cas-chiliz}-390x844-{light,dark}.png` : premier écran mobile ;
- `screenshots/{index,cas-chiliz}-1440x900-{light,dark}.png` : premier écran bureau ;
- `screenshots/cas-chiliz-1440x900-dark-full.png` : page entière en sombre, avec la planche de schéma ;
- `screenshots/cas-chiliz-390x844-light-full.png` : page entière sur mobile.

## Limites connues et points à décider

1. **Police réelle non vue.** Les captures montrent DejaVu Serif. Charter, Sitka ou Cambria donneront un gris typographique plus fin et des lignes plus courtes. À vérifier sur un iPhone et sous Windows avant de trancher.
2. **Accent brique ou accent ardoise.** Le brique donne le caractère « annotation de relecteur » et reste distinct des schémas. Un accent ardoise (`#334E68`) serait plus fondu avec D2, mais les liens se distingueraient mal du texte. À choisir.
3. **Schéma en mode sombre.** Planche claire atténuée : lisible, mais c'est un rectangle clair dans une page sombre. Tester `dark-theme-overrides` dans D2 (deux SVG par langue, ou `<picture>` avec `prefers-color-scheme`) reste une décision d'architecture.
4. **Schéma sur mobile.** À 390 px, le SVG de 876 px est réduit à environ 36 % : les libellés deviennent illisibles, d'où le lien « Ouvrir en taille réelle ». Il faudra des schémas pensés en hauteur, ou une variante mobile.
5. **Sommaire sur mobile.** Il occupe environ 230 px avant le cas. Pour un seul cas publié, on peut le masquer ; il deviendra utile avec trois cas Chiliz.
6. **Page de groupe.** La page Chiliz n'a pas encore de contenu propre (`_index` à écrire) : seul « Chiliz » en titre. La numérotation « 1.x » suppose un cas par chapitre ; avec 02, 03 et 04, elle deviendra 1.x, 2.x, 3.x.
7. **Accueil, cas 01 et 05.** Seuls leurs titres courts et « En bref à venir » sont affichés : rien n'est inventé. La ligne de méta (entreprise · période) n'existe que pour le cas 02.
8. **Activité annexe.** Texte provisoire, signalé par un commentaire HTML, avec un lien `#`.
9. **Contact.** `[email]` et `[LinkedIn]` sont des emplacements réservés, non remplis.
10. **`hanging-punctuation`** n'est pris en charge que par Safari ; ailleurs, sans effet.
