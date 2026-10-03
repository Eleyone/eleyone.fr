# Story 10.9 : Full mission context on the CV

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.9.

Deuxième des trois stories ajoutées à l'epic 10 par la proposition de changement du 02/10/2026
(arbitrages Q1 à Q8 d'Arnaud). L'en-tête de l'epic (point 21) dit que 10.8 et 10.9 ne sont pas des
stories d'intégration : elles préparent la 10.10, qui apporte le contenu rédigé par Arnaud.

Elle rend le contexte complet de chaque poste — secteur sur la ligne de rôle, corps et stack du projet
dans un `<details>` fermé par défaut, après les cas — avec des clés **facultatives**, étend C3, C6 et
C19 aux postes et crée C25 (période d'un cas comprise dans celle de son poste). Elle dépend de la
10.8 (`done`, PR n° 130) : `docs/format-parcours.md` fixe les clés qu'elle lit.

## Revue de spec

### 02/10/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `9075a59`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c1d2d96c0903f15fb4e6a606

### Rapport de revue de spec (BMAD)

#### Lentille adverse (Adversarial)

- **BLOQUANT** : Contradiction sur l'affichage du bloc pour les postes sans contexte. Le critère 1 stipule que « ce bloc existe pour **tout** poste, qu'il ait des cas ou non ; ce qui manque n'est pas rendu ». Cependant, la section finale demande s'il faut « pas de bloc du tout, ou un bloc réduit à ce qui existe » pour un poste sans corps ni stack. Ces deux directives s'opposent directement et forceront le développeur à faire un choix architectural hasardeux (générer un `<details>` vide/invalide ou ignorer le premier critère).
- **BLOQUANT** : Oubli de vérification sur la vacuité du corps. Le critère 4 impose aux contrôles C3, C6 et C19 d'échouer si `sector` ou `stack` sont présents mais vides (liste vide, espaces). Toutefois, il omet complètement de spécifier la règle pour le corps (le texte de la mission). Un corps composé uniquement d'espaces pourrait donc passer silencieusement et casser le design (encart vide).
- **BLOQUANT** : Critère invérifiable sur l'analyse et la comparaison des périodes (C25). Le critère 5 mentionne la vérification des périodes avec « l'une des formes lues » et donne des exemples français (« mois AAAA – mois AAAA », « depuis mois AAAA », « AAAA »), mais n'indique aucune chaîne de caractère attendue pour l'anglais. De plus, la logique de comparaison entre deux granularités différentes (comment le script valide-t-il que "2020" est compris dans "Janvier 2020 - Décembre 2021" ?) est absente, ce qui empêche d'écrire un test déterministe.
- **BLOQUANT** : Emplacement du secteur indéfini sur la ligne de rôle. Le critère 1 demande l'affichage du secteur « sur la ligne de rôle », mais la question finale avoue que la place précise (avant ou après le lieu, le cadre et via) n'est pas décidée. L'implémentation exige un gabarit strict : cette ambiguïté bloquera l'intégration UX.

#### Lentille structure (Structure)

- **NON BLOQUANT** : Présence de questions de conception non résolues au sein d'une story prête au développement. Les « Questions à poser avant de commencer » touchent à des règles de rendu et des libellés d'interface. Bien que le fait de poser des questions soit une bonne pratique (point 1 des règles de conduite), une story ne devrait pas être implémentée si ses propres critères d'acceptation dépendent de questions bloquantes.

#### Lentille prose (Prose)

- **NON BLOQUANT** : Terminologie du mot « corps ». Le mot est clair sémantiquement, mais dans le contexte de Hugo, il pourrait induire un doute technique (s'agit-il du paramètre `.Content` natif issu du corps du fichier Markdown, ou d'une clé de métadonnées `corps` dans le front-matter ?). Bien que l'architecture suggère `.Content`, le préciser ôterait toute hésitation.

##### À trancher avant d'implémenter

- **Rendu d'un poste sans corps ni stack :** Le `<details>` doit-il être totalement masqué ou être rendu vide/partiel ?
- **Emplacement du `sector` :** Où doit-il s'afficher exactement sur la ligne de rôle (avant ou après le lieu, le cadre, et via) ?
- **Libellé du `<summary>` :** Confirmer le texte exact à utiliser dans les fichiers de traduction (`i18n`) en français et en anglais.
- **Parseur de dates C25 :** Quels sont les motifs lexicaux exacts attendus pour l'anglais (ex. "since", "to"), et quelle est la règle pour évaluer l'inclusion lorsqu'on compare une simple année ("AAAA") à un mois précis ("mois AAAA") ?

### Tri des constats (02/10/2026, auteur Claude)

| # | Constat | Décision |
|---|---|---|
| A1 | « Le bloc existe pour tout poste » contredit la question « pas de bloc du tout ? » (BLOQUANT) | **Retenu : question posée à Arnaud** (la troisième de la spec). Sa réponse fixe le cas d'un poste sans corps ni stack, et le critère se lit ainsi : tout poste **qui a de quoi remplir le bloc** le porte. |
| A2 | Un corps fait de blancs n'est couvert par aucune règle (BLOQUANT) | **Retenu.** Le corps est le contenu Markdown du fichier (`.Content`), pas une clé : un corps vide ou fait de blancs est traité comme absent — non rendu — et la story le teste. C19 ne le refuse pas : un corps reste facultatif jusqu'à la 10.10, qui le rend obligatoire. |
| A3 | C25 : formes anglaises et comparaison de granularités non écrites (BLOQUANT) | **Retenu, tranché ici (règle technique, pas de contenu).** Formes lues, insensibles à la casse, mois en toutes lettres : FR « mois AAAA – mois AAAA », « depuis mois AAAA », « AAAA » ; EN « Month YYYY – Month YYYY », « since Month YYYY », « YYYY » ; le tiret est le tiret demi-cadratin entouré d'espaces, celui des fichiers d'aujourd'hui. Une année seule vaut de janvier à décembre ; « depuis » / « since » n'a pas de borne de fin. Inclusion : début du cas ≥ début du poste **et** fin du cas ≤ fin du poste, une fin ouverte valant l'infini — un cas ouvert sous un poste fermé déborde donc. Toute autre forme est refusée en anomalie. Les deux langues sont lues et comparées chacune de son côté. |
| A4 | Place du secteur sur la ligne de rôle non décidée (BLOQUANT) | **Retenu : question posée à Arnaud** (la deuxième de la spec). |
| S1 | Questions ouvertes dans une story prête | **Pris acte** : c'est le mode de travail du projet — les questions sont posées et tranchées avant l'implémentation, et leurs réponses sont écrites ici. |
| P1 | « Corps » : `.Content` ou une clé ? | **Retenu** : `.Content`, le corps Markdown du fichier (AD-18, `docs/format-parcours.md`). |

**Arbitrages d'Arnaud (02/10/2026), en réponse aux trois questions de la spec :**

1. **Le bloc repliable ne contient que la stack, et il se nomme « Stack ».** Ses mots : « le bloc
   repliable comprend uniquement la stack. Le contexte de mission doit être lisible. Le bloc se nomme
   stack. » Le corps du poste (le périmètre) est donc **toujours visible**, rendu en `body-sm` après la
   liste des cas ; seul `<details><summary>Stack</summary>` est replié. Libellé identique en FR et en
   EN, depuis `i18n/`. **C'est une révision de l'arbitrage Q1** de la proposition du 02/10/2026, qui
   mettait périmètre et stack dans le bloc : la PR de cette story corrige les documents qui portent
   encore Q1 (PRD FR-2, AD-18, `DESIGN.md`, `EXPERIENCE.md`, `epics.md` UX-DR8 et story 10.9,
   `docs/format-parcours.md`, et une note de révision dans la proposition), point 12 d'AGENTS.md.
   Conséquence à mesurer : le premier écran mobile (FR-37), puisque le périmètre de Chiliz est
   déployé — il vient **après** la liste des cas, donc le lien « Cas 02 » le précède.
2. **Le secteur vient juste après le rôle** sur la ligne de rôle : rôle · secteur · lieu · cadre · via.
3. **Un poste n'affiche que ce qui existe** : sans stack, pas de bloc ; sans corps, pas de périmètre ;
   ni l'un ni l'autre, rien après la liste des cas. Aucune mention d'absence. Ce qui tranche A1.

## Implémentation

### Ce qui est écrit

- **`layouts/_partials/position.html`** : le secteur entre en tête des détails de la ligne de rôle —
  rôle · secteur · lieu · cadre · via (arbitrage 2). Après la liste des cas : le corps
  (`.cv-position__content`, `body-sm`) **toujours visible**, puis, si `stack` n'est pas vide,
  `<details class="cv-position__stack"><summary class="label">Stack</summary><ul class="stack">…</ul></details>`
  (arbitrage 1). L'ancienne branche « corps seulement sans cas » est retirée, avec le commentaire
  d'en-tête qui la décrivait (point 13). Ce qui n'existe pas n'est pas rendu (arbitrage 3) :
  `with .Content`, `with .Params.stack`, `with .Params.sector`.
- **`i18n/{fr,en}.yaml`** : `position_stack: Stack` dans les deux langues. Une clé à elle plutôt que
  la clé `stack` de l'encart des cas : `EXPERIENCE.md` garde le résumé « retouchable après le test
  des trente secondes », et un retouche ne doit pas changer l'encart.
- **`assets/css/main.css`** : le résumé « Stack » rejoint les sélecteurs du résumé du sommaire, son
  jumeau — cible de 24 px (`inline-block` et marge intérieure) et marqueur « ▸ » / « ▾ » —, sans
  règle nouvelle. CSS publiée : 9 927 → 10 033 octets, budget C13 de 20 000.
- **C3** (`scripts/checks/parity.sh`) : `stack` ajoutée aux clés non traduites d'un poste ;
  `sector` n'y entre pas.
- **C6** (`scripts/checks/content.sh`) : la stack d'un poste confrontée à `data/stack.yaml`, avec la
  tolérance des brouillons.
- **C19** (`scripts/checks/content.sh`) : `sector` dans le tamis « présente mais vide » des chaînes ;
  `stack` dans un tamis à elle — liste vide, liste dont aucun terme ne renseigne rien, valeur qui
  n'est pas une liste. Les deux clés restent facultatives (la 10.10 les rend obligatoires).
- **C25** : nouveau contrôle **`scripts/checks/periods.sh`**, découvert par `check.sh` sans le
  modifier, sur le modèle de `content.sh` (lecture des manifestes, programme `jq`, une ligne
  `fichier<TAB>écart` par refus, codes 0 / 1 / 2).
- **Tests** : `scripts/tests/test-periods.sh` (nouveau, 14 cas), et des cas ajoutés à
  `test-career-position.sh` (6), `test-content.sh` (3) et `test-parity.sh` (2).

### C25 tel qu'il est écrit

Les règles du constat A3, sans écart, plus trois décisions prises en écrivant :

- **Formes lues**, dans la langue du manifeste seulement : FR « mois AAAA – mois AAAA »,
  « depuis mois AAAA », « AAAA » ; EN « Month YYYY – Month YYYY », « since Month YYYY », « YYYY ».
  Mois en toutes lettres, casse ignorée — par le drapeau `i` d'Oniguruma, qui replie aussi
  « Décembre » et « AOÛT », là où `ascii_downcase` ne replierait pas les lettres accentuées.
  Séparateur : tiret demi-cadratin entre deux espaces simples. Toute autre forme est refusée,
  y compris un mois anglais dans un fichier français et une espace en tête.
- **Bornes** : année × 12 + mois. Une année seule vaut de janvier à décembre ; « depuis » / « since »
  n'a pas de fin. Inclusion : début du cas ≥ début du poste **et** fin du cas ≤ fin du poste, une fin
  ouverte valant l'infini — un cas ouvert sous un poste fermé déborde.
- **Décision 1 — un intervalle inversé est illisible** (« avril 2026 – juillet 2022 ») : il a la forme
  lue, mais pas le sens d'une période, et le comparer donnerait un verdict arbitraire.
- **Décision 2 — la période de tout poste est lue**, qu'un cas le désigne ou non :
  `docs/format-parcours.md` fixe les formes d'une période de poste en renvoyant à C25. Un cas dont le
  poste est illisible le dit en nommant les deux fichiers, sans conclure sur des bornes inconnues.
- **Décision 3 — ce qui est sauté** : une valeur `[TODO` **dans un brouillon** (règle d'AD-10,
  `checks_tolerated` ; le cas 03 porte aujourd'hui « [TODO: période] ») ; un cas sans `position`, ou
  rattaché à un poste absent de sa langue — c'est le rattachement de C19, qui refuse le cas publié
  dans ces deux situations. Dans un fichier **publié**, un `[TODO` est une forme illisible, refusée
  ici comme C5 la refuse déjà : le site publié ne peut donc pas échouer à cause d'un brouillon, et un
  publié n'échappe à rien. Les brouillons dont la période est écrite sont comparés : les cas 04 et 06
  le sont aujourd'hui, et passent.

Sur le site d'aujourd'hui : `periods: période de chaque cas comprise dans celle de son poste,
périodes lisibles.` Pour s'assurer que ce vert compare bien quelque chose, les manifestes réels ont
été recopiés hors du dépôt avec toutes les périodes de cas remplacées par une période hors bornes :
C25 refuse alors les cas 01, 02, 04, 05 et 06 en FR, 02, 04, 05 et 06 en EN (le cas 01 anglais, écrit
« since May 2030 » sous « Since February 2024 », est légitimement dedans) — les cinq cas rattachés
sont donc lus dans les deux langues, et le cas 03 est sauté pour son `[TODO`.

### Aînés et cadets (point 19)

**Le rendu de la stack de `_partials/case.html` → le bloc « Stack » de `position.html`.**

| Garde de l'aîné | La cadette en a-t-elle besoin ? |
|---|---|
| `with .stack` : rien n'est rendu sans stack | **Oui**, reprise (`with .Params.stack`), et étendue au `<details>` entier : sans stack, ni résumé ni liste (arbitrage 3). |
| classe `.stack`, virgules posées par la feuille de style, jamais dans le gabarit | **Oui**, reprise telle quelle. |
| un `<li>` par terme, échappé par Hugo | **Oui**, même `range`. |
| un libellé d'`i18n/`, jamais dans le gabarit (AD-3) | **Oui** : `position_stack`, clé à elle (voir plus haut). |
| la stack d'un cas publié est exigée non vide (C18) | **Non, pas encore** : la clé d'un poste est facultative jusqu'à la 10.10 ; seul son vide écrit est refusé (C19). |
| `.stack` ne fixe que la taille, la famille vient du parent | **Écart hérité, reporté** : `DESIGN.md` veut la stack d'un poste en `meta` (monospace), et les deux stacks sortent en serif. Le critère demande la classe de l'encart ; la corriger touche les deux rendus — `deferred-work.md`. |

**Le résumé du sommaire (`_partials/toc.html`) → le résumé « Stack ».** Son jumeau d'interaction,
pas nommé par la spec mais le seul `<summary>` du site : cible de 24 px (la règle `inline-block` de
WCAG 2.5.8), marqueur reposé par `::before` puisque `inline-block` retire le marqueur natif, libellé
en `label`. **Les trois repris**, en ajoutant le sélecteur aux règles existantes plutôt qu'en les
recopiant (« une parade s'écrit une fois »). La garde du sommaire qui masque son résumé dès md
(`display: none` et `::details-content`) **n'est pas reprise** : le bloc « Stack » reste repliable à
toutes les largeurs.

**C6 sur les cas → C6 sur les postes.**

| Garde de l'aîné | La cadette en a-t-elle besoin ? |
|---|---|
| `select($vocabulary \| index($t) \| not)` : un terme hors vocabulaire est refusé | **Oui**. |
| tolérance `draft == true` **et** terme qui commence par `[TODO` — les deux à la fois | **Oui**, à l'identique ; testée dans les deux sens (brouillon toléré, publié refusé) et par mutation. |
| `// []` : une clé absente ne produit rien | **Oui**. |
| ne lit que `role == "case"` | Remplacé par `role == "position"` ; la clé est à la racine du front matter, pas sous `context`. |
| *(manque)* un terme qui n'est pas une chaîne fait tomber `jq` sur `startswith` : anomalie code 2, sans nommer le fichier | **La cadette ne l'hérite pas** : le terme est lu par sa forme textuelle, et refusé en nommant le fichier (cas `[42]`). L'aîné garde son anomalie, bruyante et non silencieuse : laissé tel quel. |
| *(manque)* une stack qui n'est pas une liste fait aussi tomber `jq` | Pour la cadette, **C19** la refuse (« n'est pas une liste ») et C6 la saute, pour ne pas la signaler deux fois. |

**Le tamis « présente mais vide » de C19 → `sector` et `stack`.** Le tamis des chaînes (`blank`)
convient à `sector`, ajoutée à sa liste. Il **ne convient pas** à `stack` : il lit une liste par sa
forme textuelle, `[]` ou `["  "]`, qui n'est jamais blanche — le tamis aurait laissé passer exactement
ce qu'il doit refuser. `stack` a donc sa règle, qui nomme les trois formes vides, chacune testée à
part (une liste vérifiée en bloc laisserait passer la forme oubliée). Un terme blanc parmi de vrais
termes relève de C6.

### Ce que la story change sur le site publié

Les corps des postes **Chiliz**, **Orange** et **Ton Pote le Geek**, cachés jusqu'ici parce que ces
postes ont des cas publiés, sont désormais visibles sous leurs cas, sur l'accueil de production.
C'est l'arbitrage 1 appliqué aux postes d'aujourd'hui, dont la story 10.10 réécrit les corps ; le
contenu n'est pas touché ici (point 21 : 10.9 n'est pas une story d'intégration). `check.sh` passe,
typographie (C24) et liens (C12) compris.

### Premier écran à 390 × 844 (FR-37, point 11)

**Méthode.** Les stories 5.2, 5.5 et 10.1 ont mesuré au navigateur, en émulation 390 × 844 de
densité 3 ; aucun navigateur n'est installé sur le poste, la mesure est donc faite dans un conteneur :
Chromium sans tête et Puppeteer (`zenika/alpine-chrome:with-puppeteer`), auquel une image locale
ajoute `font-dejavu`, `font-noto` et `font-bitstream-type1`. Le dépôt est copié hors de lui-même, le
poste Chiliz modifié dans la copie (jamais dans le dépôt), le site construit par
`scripts/build.sh production` de la copie, servi par un petit serveur dans le conteneur, sans réseau,
et mesuré par `getBoundingClientRect`, bloc fermé, en FR et en EN, avec la pile du site (qui retient
Noto Serif ici), puis DejaVu Serif, Noto Serif et Bitstream Charter imposées.

**Variantes du premier poste** : le site actuel au nouveau gabarit ; **vide** (ni secteur, ni corps, ni
stack) ; **court** (secteur d'un mot, corps d'une phrase, un terme) ; **moyen** (secteur de trois mots,
corps de six phrases à la première personne tiré des faits du corps actuel, stack de six termes du
vocabulaire) ; **le plus long** (secteur de huit mots, même corps et même stack) ; et le plus long avec
le corps actuel (un paragraphe et six puces, plus long que six phrases).

| Premier poste (Chiliz) — lien « Cas 02 » | Noto Serif FR / EN | DejaVu Serif FR / EN |
|---|---|---|
| actuel, sans secteur ni stack | 791 → 844 / 791 → 844 | 841 → 893 / 818 → 870 |
| vide | 791 → 844 / 791 → 844 | 841 → 893 / 818 → 870 |
| court | 791 → 844 / 791 → 844 | 841 → 893 / 818 → 870 |
| moyen | 791 → 844 / 791 → 844 | 867 → 920 / 818 → 870 |
| le plus long (les deux corps) | 818 → 870 / 818 → 870 | 894 → 946 / 844 → 896 |

Le haut de page ne varie pas avec le poste : identité 134 → 194, titre 202 → 249, pitch 292 → 572 en
Noto Serif ; avec DejaVu Serif, le titre prend deux lignes et le pitch finit à 622 (FR) et 599 (EN).

**Ce que cela dit, sans l'arrondir.**

1. **Le périmètre et le bloc ne repoussent pas « Cas 02 »** : le lien est au même pixel avec six
   phrases, une phrase ou aucun corps. La spec le prévoyait, la mesure le confirme.
2. **Avec Noto Serif, le critère tient au pixel près** (le lien finit à 844 sur 844) tant que la ligne
   de rôle tient sur deux lignes ; un secteur long la fait passer à trois lignes et pousse le lien à
   818 → 870, sous le pli.
3. **Avec DejaVu Serif — la serif de repli large que demande le critère —, il ne tient pas, et ne
   tenait déjà pas avant la story** : le lien commence à 841 px en FR et 818 en EN sous le pitch
   actuel, sans aucun secteur. La story 10.1 avait mesuré le pitch, pas le premier poste.
4. **Charter n'a pas pu être mesurée** : Chromium n'affiche pas la Bitstream Charter Type 1 d'Alpine
   et retombe sur DejaVu Serif (chiffres identiques au pixel).

Le critère « on voit le lien Cas 02 » n'est donc **pas** tenu avec une serif de repli large, et il ne
l'était pas avant cette story. Le corriger — raccourcir le pitch, plafonner le secteur, ou accepter le
pli sous une serif large — est un arbitrage de contenu et de mise en page pour Arnaud ; la story ne
le tranche pas par un correctif de gabarit. Chiffres consignés dans `docs/accessibility.md`.

**Accessibilité du bloc** (même environnement, variante la plus longue) : le résumé est atteint au
clavier juste après le lien du cas 02 ; Entrée l'ouvre, Espace le referme, le marqueur passe de « ▸ »
à « ▾ » ; anneau de focus de 2 px `accent` en clair et en sombre ; cible 62 × 26,2 px ; à 320 px, bloc
ouvert, FR et EN, clair et sombre, `scrollWidth` 320 et aucun élément qui dépasse.

### Gardes retirées une fois (point 9)

Chaque mutation est appliquée au fichier, le fichier de test concerné relancé, puis le fichier
restauré. **Toutes font échouer leur test** (code 1) :

| # | Mutation | Test qui échoue |
|---|---|---|
| M1 | `stack` retirée des clés non traduites d'un poste (C3) | `test-parity.sh` |
| M2 | règle C6 des postes neutralisée | `test-content.sh` |
| M2b | tolérance des brouillons retirée de C6 des postes | `test-content.sh` |
| M3 | `sector` retirée du tamis C19 | `test-content.sh` |
| M4, M4b, M4c | tamis de `stack` : liste vide, liste de blancs, non-liste, chacun neutralisé à part | `test-content.sh` |
| M5a, M5b | C25 : comparaison du début, puis de la fin, retirée | `test-periods.sh` |
| M5c | C25 : un cas ouvert sous un poste fermé accepté | `test-periods.sh` |
| M5d | C25 : période illisible d'un cas sautée | `test-periods.sh` |
| M5e | C25 : intervalle inversé accepté | `test-periods.sh` |
| M5f | C25 : périodes de poste non lues | `test-periods.sh` |
| M5g | C25 : mois des deux langues mêlés | `test-periods.sh` |
| M5h, M5i | C25 : tolérance `[TODO` retirée, puis étendue aux publiés | `test-periods.sh` |
| M5j | C25 : une année seule vaut janvier seulement | `test-periods.sh` |
| M5k | C25 : casse respectée | `test-periods.sh` |
| M5l | C25 : tout tiret accepté, espaces facultatives | `test-periods.sh` |
| M5m | C25 : un cas sous un poste illisible passé sous silence | `test-periods.sh` |
| M6a | gabarit : branche « corps seulement sans cas » remise | `test-career-position.sh` |
| M6b, M6f | gabarit : corps rendu sans garde, puis jamais rendu | `test-career-position.sh` |
| M6c | gabarit : secteur après le lieu | `test-career-position.sh` |
| M6d | gabarit : bloc ouvert au chargement | `test-career-position.sh` |
| M6e | gabarit : bloc rendu sans stack | `test-career-position.sh` |
| M6g | gabarit : corps remis dans le bloc (l'ancien Q1) | `test-career-position.sh` |
| M6h | gabarit : libellé du résumé écrit en dur | `test-career-position.sh` |

Une garde **n'a pas survécu** à cet exercice : le gabarit testait d'abord un corps blanc par
`strings.TrimSpace`. Retirée, aucun test n'échouait — Hugo rend déjà un corps fait de blancs en
contenu vide, ce que le cas `position_corps_blanc_pas_de_perimetre` constate. Une garde qu'aucun test
ne distingue n'en est pas une : elle est remplacée par `with .Content`, que M6b éprouve.

### Documents corrigés (points 8, 12 et 13)

L'arbitrage 1 révise Q1 de la proposition approuvée ; chaque document qui portait encore Q1 ou un
futur « à partir de la story 10.9 » est corrigé, l'ancien texte gardé en note de révision datée là où
le document le fait déjà :

- **PRD** : §0, glossaire « Poste », description du §4.1, FR-2 (secteur après l'intitulé, périmètre
  visible, stack seule repliée), note de FR-37 (ce qui repousse le lien, renvoi aux mesures), §11.1
  (ligne du 13/09 réannotée, ligne du 02/10 renvoyée, ligne de révision ajoutée).
- **`ARCHITECTURE-SPINE.md`** : statut, AD-18 (stack au présent, rendu, révision datée, C25 nommé),
  description de l'accueil, portée des contrôles, lignes C3, C6, C19 et **C25** (règles et script
  `scripts/checks/periods.sh`), I-6, décision 77, arborescence de `scripts/checks/` (qui omettait
  aussi `release-pages.sh`).
- **`DESIGN.md`** : mise en page de l'accueil, `cv-position` (ligne de rôle, secteur, périmètre, bloc
  « Stack », révision datée qui garde le texte du 02/10), poste sans cas, décision 5.
- **`EXPERIENCE.md`** : « Voice and Tone » (libellés tranchés), `cv-position`, « State Patterns »,
  « Interaction Primitives », note du premier écran (avec le résultat de la mesure), test des trente
  secondes, décision 10.
- **`epics.md`** : présentation, FR-2, AD-18, UX-DR8, notes des stories 2.7 et 5.2, et une note après
  les questions de la story 10.9 — son texte validé n'est pas réécrit, comme les notes des 2.7 et 5.2.
- **`docs/format-parcours.md`** (C3, C19, formes de période, inclusion, rendu), **`docs/procedures/check.md`**
  (C3, C4–C19, ligne C25), **`docs/accessibility.md`** (ligne de l'accueil et mesures), et une section
  « Révision (02/10/2026, story 10.9) » en fin de proposition.

Chaque document a été relu sur ses sections touchées, puis balayé en entier pour les formules de
l'ancien état (« à partir de la story 10.9 », « fixé par la story 10.9 », « le vérifiera »,
« Mission : périmètre et stack », « corps et stack », « bloc repliable ») : il ne reste que des
citations datées de l'ancien texte. `test-docs-headings.sh` passe.

### Vérifications

- `bash scripts/tests/run.sh` → `tests: 933 cas réussis, 1 ignorés` (l'ignoré : `pdf_repli_sur_la_liste_du_depot`, pas de `docs/private/` dans ce worktree).
- `scripts/check.sh` → `check: 12 contrôle(s) passés, niveau standard.`, dont `periods` et `budget` (C13).
- `bash scripts/tests/run.sh scripts/tests/test-docs-headings.sh` et `test-design-tokens.sh` passent.
- `scripts/ci/checks-job.sh` n'a pas été lancé : le worktree n'a qu'un fichier `.git` qui pointe vers le dépôt principal, que le conteneur ne monte pas, et le garde-fou en mode historique y échouerait pour une raison étrangère à la story.

## Revue du code

### 03/10/2026 — PR n° 131, `gemini-3.1-pro-high`, SHA `c461ab8`, verdict `pass`

Rapport recopié de la PR (le script a tourné depuis le dépôt principal, sur une autre branche : la
copie de travail de la story n'a pas de `.env`). La branche avait été rebasée sur `dev` après la
fusion de la 11.9 ; suite (933 cas, 1 ignoré faute de `docs/private/` dans la copie), contrôles
(12) et garde-fou rejoués par l'orchestrateur sur la tête rebasée.

llm-review sha=c461ab850e5aed198922acfb83de9341205e26e6 base=dev model=gemini-3.1-pro-high verdict=pass

_Revue par `scripts/llm-review.sh` : `agy --mode plan`, copie isolée hors du dépôt au SHA relu, sans `.env` ni `docs/private/` ; skill `bmad-review` appliqué par le relecteur (angles : edge-case-hunter, verification-gap, plus la couche propre au projet). Fichiers créés ou modifiés par le relecteur dans la copie : aucun._

JETON: d316f3ed4d9770fa0759002a

### Rapport de revue (BMAD)

#### Lentille edge-case-hunter
- NON BLOQUANT : Dans `scripts/checks/content.sh` (C19), l'expression `($stack | blank)` est évaluée lorsque `stack` n'est pas une liste ; si un auteur saisit par erreur un objet (dictionnaire) ou un booléen dans le front matter, la fonction `blank` fera planter `jq` avec une erreur de type au lieu d'afficher le message prévu « n'est pas une liste » (cette erreur fera néanmoins échouer le script bruyamment, elle n'est donc pas silencieuse).

#### Lentille verification-gap
- NON BLOQUANT : Aucune faille de vérification identifiée ; les règles de rattachement (C19), la lecture asymétrique des périodes (C25 avec années seules vs mois précis) et la gestion stricte du marqueur de brouillon `[TODO` couvrent exhaustivement les branches attendues sans angle mort.

### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (le secteur se trouve bien sur la ligne de rôle, le périmètre est toujours visible après les cas, et la stack est seule dans le bloc `<details>` nommé « Stack »).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent : le document `docs/procedures/check.md` reflète exactement l'ajout de `C25` et les nouvelles règles de `C19`.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md (testé avec suppression de gardes pour prouver leur utilité, relu en intégralité) et les décisions d'architecture (AD-18 mis à jour avec les arbitrages).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (les appels à `jq` sont suivis de `|| checks_die` pour intercepter toute défaillance inattendue).

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue (orchestrateur)

| # | Constat | Décision |
|---|---|---|
| E1 | C19 : `blank` appliqué à une `stack` objet ou booléenne fait échouer `jq` au lieu du message « n'est pas une liste » | **Retenu, reporté** dans `deferred-work.md` avec son jumeau : C6 sur les cas tombe de même en anomalie sur un terme qui n'est pas une chaîne (marche du jumeau de la section « Implémentation »). L'échec est bruyant (code 2), jamais silencieux ; le corriger maintenant rouvrirait la revue d'une PR verte pour un message. Point 18 : les deux se corrigent ensemble. |
| V1 | Aucune faille de vérification | Pris acte. |
| P1 | Critères satisfaits | Pris acte, avec l'arbitrage FR-37 ci-dessous. |
| P2 | Aucune donnée privée ni secret | Pris acte ; garde-fou rejoué, code 0. |
| P3 | `check.md` concorde avec C19 et C25 | Pris acte. |
| P4 | Cohérent avec AGENTS.md et AD-18 | Pris acte. Le relecteur écrit « relu en intégralité » : la sous-tâche a dit elle-même avoir relu les sections modifiées du PRD, de l'architecture et d'`epics.md`, puis cherché les formulations périmées dans tout le fichier, sans relire chaque ligne — réserve consignée ici plutôt que tue. |
| P5 | Aucune erreur silencieuse | Pris acte. |

**Arbitrage d'Arnaud sur FR-37 (03/10/2026) : option 3, le dépassement est accepté avec une serif de
repli large.** Mesures de la section « Implémentation » : avec Noto Serif, le lien « Cas 02 » tient
au pixel près (791→844) quel que soit le périmètre ; avec DejaVu Serif, il passe sous le pli
(841→893 en FR) **sur le site d'avant la story**, du fait du pitch ; un secteur long ajoute une ligne
de rôle (26 px). Rien n'est changé : ni plafond du secteur dans le contrat, ni pitch raccourci.
Options écartées : plafonner le secteur à 1–4 mots (recommandée par l'orchestrateur) ; raccourcir le
pitch ; mesurer d'abord avec Charter dans le navigateur d'Arnaud. La 11.10 revérifie FR-37 à chaque
retouche du haut de l'accueil, comme elle le prévoit déjà.
