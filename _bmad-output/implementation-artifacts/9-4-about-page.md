# Story 9.4 : About page

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.4.

## Revue de spec

### 23/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `ddbbf6d`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0424c1cf6a94b8e7c558d25e

### Rapport de revue de spécification (Story 9.4)

#### Lentille : Adversarial (Critique adverse, cas limites et vides de vérification)

* **BLOQUANT** : Contradiction avec les règles de séparation du code et du contenu. La spec exige que le texte traite de « *ce qu'il ne veut être [...] et qu'il utilise Claude Code au quotidien* ». Cela viole la règle 4 d'`epics.md` (« Le backlog ne contient, pour le contenu, que des stories d'intégration ») et la NFR-10 (Rien d'inventé). C'est le Markdown d'Arnaud qui fixe le contenu, le développeur n'a pas à l'imposer ni à le vérifier dans un critère d'acceptation.
* **BLOQUANT** : Cas limite oublié sur les CV PDF. La spec teste l'état « publiés » (les deux présents) et « absents », mais oublie le cas où **un seul des deux fichiers** est présent. Selon l'AD-21 (« ensemble ou rien »), la présence d'un seul fichier doit aboutir au même résultat qu'aucun fichier (aucun lien affiché).
* **BLOQUANT** : Critère incomplet sur la disposition responsive du portrait. La spec demande « portrait [...], bloc CV [...] puis le texte », ignorant le comportement défini dans `DESIGN.md` : le portrait se place sous le titre sur mobile (`sous md`), mais dans la colonne de marge sur grand écran (`dès md`).
* **BLOQUANT** : Critère manquant sur le composant de l'en-tête. La spec vérifie que l'en-tête porte le lien « À propos », mais omet de vérifier que sur cette même page, ce lien porte l'attribut `aria-current="page"` (exigence d'`EXPERIENCE.md` pour `site-header`).
* **BLOQUANT** : Vides de vérification sur les slugs et `ci/release-pages.txt`. La spec dit ajouter `about` au fichier de vérification de mise en ligne. Or, l'AD-2 fixe le slug français à `/a-propos/` et l'anglais à `/en/about/`. Les slugs des deux langues doivent être vérifiés et déclarés explicitement dans le front matter (`slug: a-propos` pour le fichier `.fr.md`).
* **BLOQUANT** : Oubli d'un élément visuel obligatoire. La spec mentionne un « bloc CV en `note-block` », mais oublie de préciser qu'il doit contenir l'étiquette « CV » en composant `label` (exigence UX-DR14 de `DESIGN.md`).

#### Lentille : Structure (Organisation du document)

* **NON BLOQUANT** : Les « Prérequis de contenu » indiquent bien que le texte est « rédigé par Arnaud », mais le dernier critère d'acceptation fixe le contenu de manière stricte. Il faut purger la section des critères d'acceptation de tout ce qui relève de la responsabilité rédactionnelle.

#### Lentille : Prose (Clarté et expression)

* **NON BLOQUANT** : L'expression « portrait (variante "À propos") » gagnerait à être plus explicite en référençant directement les tailles exigées par l'AD-19 et `DESIGN.md` (160×200 et 320×400) pour guider le recadrage au niveau du gabarit sans ambiguïté.

#### À trancher avant d'implémenter

* Confirmer le retrait des directives de contenu (références à Claude Code, etc.) des critères d'acceptation pour respecter la séparation contenu/intégration technique.
* Intégrer le cas de test "un seul fichier PDF présent" pour valider la règle "ensemble ou rien" (AD-21).
* Ajuster les critères de l'en-tête et du manifeste `release-pages.txt` avec les bons slugs (`a-propos` et `about`) et la vérification de l'attribut d'accessibilité `aria-current="page"`.

### Triage des constats (23/09/2026)

**Retenus, et tous vérifiés dans `DESIGN.md`** — la spec de la story est plus courte que la conception, et c'est la conception qui fait foi.

- *Disposition du portrait* — `DESIGN.md:476` et `:561` : la variante « À propos », 120 × 150 sous md **sous le titre**, 160 × 200 **dans la colonne de marge** dès md, en srcset 1x/2x. Le partial `portrait.html` porte déjà cette variante depuis la story 5.5.
- *L'étiquette du bloc CV* — `DESIGN.md:618` : « dans un `note-block` placé juste sous le titre, avec l'étiquette “CV” en `label` et les deux liens en `body`, chacun sur sa ligne ». La spec disait « bloc CV en `note-block` » sans l'étiquette.
- *`aria-current="page"` sur le lien de l'en-tête* — la mécanique existe depuis la story 9.3 et vaut pour toute page ; la vérifier ici est légitime.
- *Les deux slugs* — `/a-propos/` et `/en/about/`, décidés le 13/09. Les fichiers d'Arnaud les portent déjà.
- *Le cas « un seul PDF »* — juste dans son principe. Il est déjà tenu : le bloc réutilise `cv-links.html`, dont la règle « ensemble ou rien » est éprouvée depuis la story 7.2. Un cas l'exerce néanmoins sur **cette page**, parce que c'est un nouvel emplacement et que la garantie vient du partial, pas de la page.

**Refusé**

- *« Le critère d'acceptation impose le contenu, ce qui viole la séparation code/contenu »* — le critère porte la marque **_(relecture)_**, qui l'assigne explicitement à une lecture humaine et non à une vérification automatique ni à une rédaction par l'agent. C'est la forme employée dans tout le backlog pour ce qui se juge à l'œil. Le texte reste celui d'Arnaud ; le critère dit seulement ce qu'on vérifiera en le lisant — et il se trouve que son texte traite bien les trois points.

## Le texte d'Arnaud

Reçu le 23/09/2026, en français et en anglais. Deux choses à traiter avant de le poser :

1. **`[TODO: url]`** pour « Ton Pote le Geek ». Aucune URL n'existait nulle part dans le dépôt ; Arnaud l'a donnée : `https://tonpotelegeek.fr`. Sans elle, C4 aurait refusé le marqueur et la page aurait porté un lien mort.
2. **`draft: true`** dans les deux fichiers. La story publie la page et l'inscrit dans `ci/release-pages.txt` : le brouillon est retiré.

## Implémentation

- `content/about.{fr,en}.md` — le texte d'Arnaud, tel quel ;
- `layouts/about.html` (nouveau) — l'ordre de `DESIGN.md` : titre, portrait, bloc CV s'il existe, texte ;
- `assets/css/main.css` — `note-block`, `cv-links` en liste, et la variante « À propos » du portrait ;
- `layouts/_partials/site-header.html` — le lien « À propos », **avant** « Contact », le sélecteur de langue restant dernier ;
- `i18n/{fr,en}.yaml` — `nav_about`, `cv_block_label` ; `ci/release-pages.txt` gagne `about`.

Le bloc CV **réutilise `cv-links.html`**, d'où lui vient « ensemble ou rien » : le partial n'émet rien si un seul fichier existe, et l'encart disparaît avec lui, étiquette comprise. Le rendu du partial est capturé pour le savoir — sans cette capture, l'encart aurait été rendu vide.

### Ce que la mesure a corrigé

**Le portrait n'était pas à hauteur du titre.** En placement automatique, il suivait le titre dans l'ordre du DOM et tombait à la rangée d'après — 67 px plus bas, dans la bonne colonne. Une position a deux axes (point 14 d'AGENTS.md) ; vérifier la colonne ne suffisait pas.

`grid-row: 1` l'a ramené sur la rangée du titre, mais **a étiré cette rangée** : le bloc CV est passé de 206 à 323 px, laissant un vide sous le titre. `grid-row: 1 / span 2` le laisse s'étendre sur deux rangées sans en gonfler aucune — le bloc CV est revenu à 206.

Un numéro **positif** : les lignes négatives comptent depuis la grille explicite, qui n'existe pas ici. C'est la faute de la story 6.1, évitée en s'en souvenant.

### Vérification au navigateur, aperçu sans `.env`

| | 1280 px clair | 360 px sombre |
|---|---|---|
| Ordre | titre 123, bloc 206, texte 350 | titre 153, portrait 205, bloc 378, texte 502 |
| Portrait | 160 × 200, colonne de marge, à hauteur du titre | 120 × 150, sous le titre |
| Chevauchements avec le texte | 0 | — |
| Contraste lien / étiquette sur l'encart | — | 7,97 / 13 |
| Débordement, cibles < 24 px | aucun | aucun |

### Constats

| | |
|---|---|
| `scripts/tests/run.sh` | **531 cas** (524 avant) |
| Dans `CHECK_IMAGE` | 524 réussis, 7 ignorés sous root, **aucun échec** |
| `scripts/check.sh` | 9 contrôles, dont C3, C11, C12, C20 |
| `check-private.sh staged` | code 0 |

Quatre gardes dégradées une à une — l'encart sans CV, l'étiquette, la variante du portrait, `aria-current` — pour voir leurs cas échouer.

## Revue du code

### 23/09/2026 — `666810d` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 103. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 101e5afe189bf10c7d705fb9

##### Lentille : Edge Cases (Cas limites)
- NON BLOQUANT : L'étirement de la grille par le portrait (quand il rejoint la colonne de marge sur grand écran) a été solidement anticipé avec `grid-row: 1 / span 2` pour éviter de déformer la ligne de titre ou d'ajouter de l'espace vide au-dessus du bloc CV.
- NON BLOQUANT : La disparition conditionnelle du bloc CV (règle "ensemble ou rien") emporte bien son conteneur `note-block` et son étiquette, évitant le cas limite d'une étiquette seule affichée au-dessus de rien.

##### Lentille : Verification Gap (Vides de vérification)
- NON BLOQUANT : Le test vérifiant l'ordre des éléments de l'en-tête (`case_about_lordre_de_len_tete`) effectue sa recherche uniquement sur `/a-propos/` et `hreflang=en`, ce qui prouve la version française mais omet de vérifier symétriquement la version anglaise.
- NON BLOQUANT : Dans `case_about_un_seul_cv_ne_rend_rien`, l'absence de l'étiquette et du lien n'est pas testée formellement pour le cas d'un fichier unique, le test s'appuyant judicieusement sur l'absence du `note-block` englobant.

##### Couche projet (Critères, vie privée, scripts et architecture)
- NON BLOQUANT : Les critères d'acceptation sont entièrement satisfaits, le texte respecte le cahier des charges et l'ajout à l'en-tête maintient l'état actif (`aria-current="page"`).
- NON BLOQUANT : Aucune donnée privée, aucun secret ni nom de serveur n'est commité. Les mentions biographiques respectent strictement les autorisations géographiques (pays uniquement) définies dans AGENTS.md.
- NON BLOQUANT : Le code est parfaitement cohérent avec les décisions d'architecture : les slugs respectent AD-2, l'internationalisation des libellés (AD-3) passe bien par `i18n/`, et aucun JavaScript n'a été ajouté (AD-8).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne peut passer en silence. L'appel à Hugo capte le code de retour avec `|| code=$?` et la séparation de la déclaration (`local fr; fr=$(page ...)`) préserve les codes d'échec sous `set -euo pipefail`.

VERDICT: NON BLOQUANT — aucune

## Reporté
