# Story 2.6 : Case section numbers and table of contents

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 2.6.

## Revue de spec

### 17/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `45ef661`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 3fa13059cc4a5a463e187f87

Ce document existe pour définir avec précision l'implémentation de la numérotation des rubriques de cas et du sommaire, afin d'orienter correctement le développement tout en respectant l'architecture (AD-4) et l'expérience utilisateur (EXPERIENCE.md).

##### Lentille Adversarial (Edge Cases & Gaps)

| Localisation | Problème (Trigger Condition) | Fix / Amélioration (Guard Snippet) | Conséquence si ignoré |
|---|---|---|---|
| AC (1er bloc) | Le préfixe de l'identifiant est codé en dur (`case-02-`). | Remplacer par une règle dynamique : « préfixé par le `translationKey` du cas » (AD-4). | Les ancres des autres cas (ex: 05, 03) auraient toutes le préfixe erroné `case-02-`. |
| AC (1er bloc) | Le numéro du cas est codé en dur (`02.r`). | Préciser « `<span ...>NN.r</span>` où NN est le numéro du cas courant ». | Le numéro "02" s'afficherait de façon statique pour tous les cas du site. |
| AC (1er bloc) | Incomplet sur le niveau de titre pour les cas isolés. | Préciser que `##` descend en `<h3>` **uniquement** pour un cas groupé. Pour un cas seul (ex: cas 05), `##` reste `<h2>` (cf. plan des titres UX). | Un cas non groupé aurait des rubriques en `<h3>` directement après son `<h1>`, créant un saut de niveau invalide (WCAG). |
| AC (1er bloc) | Omission du comportement pour les sous-rubriques (`###`). | Préciser que le hook descend **tous** les titres d'un niveau pour un groupe, pas seulement les `##`. | Les sous-rubriques ne seraient pas adaptées et créeraient des incohérences hiérarchiques. |
| AC (3e bloc) | Il manque la balise `<nav>` autour du sommaire. | Envelopper le `<details>` dans une `<nav>` avec un `aria-label` traduit (ex: "Sommaire" / "Contents"). | Violation de `EXPERIENCE.md` (repères d'accessibilité) et échec du contrôle WCAG 2.2. |
| AC (3e bloc) | Flou technique : comment le sommaire liste les rubriques d'un groupe ? | Préciser que pour une page de groupe, le gabarit itère sur `.RegularPages` et récupère les rubriques via `.Fragments.Headings` de chaque cas publié. | Le développeur risque de ne lister aucune rubrique, le `_index.md` de Chiliz n'en contenant pas lui-même. |
| AC (3e bloc) | Le calcul du nombre total de rubriques n'est pas clair pour un groupe. | Spécifier que c'est la somme de toutes les rubriques de **tous les cas publiés** du groupe. | Le compteur du sommaire pourrait être faux (ex: afficher seulement le compte du cas 02 au lieu de 02 + 03 + 04). |
| AC (1er / 3e bloc) | Les styles CSS liés à l'ancre (`:target`) sont omis. | Ajouter un critère pour s'assurer que `.rubric-heading` porte `scroll-margin-top` et que la cible `:target` affiche le filet vert (UX-DR12). | Le clic sur le sommaire masquera le titre sous le bord haut, et la rubrique ciblée n'aura pas sa mise en évidence visuelle. |

##### Lentilles Éditoriales (Structure et Prose)

Modèle de structure choisi : **Prompt/Task Definition (Functional)**.

| Pass | Texte original | Texte révisé | Changements |
|---|---|---|---|
| prose | `chaque ## est rendu en <h3>, avec un identifiant préfixé par case-02-, la classe rubric-heading et <span class="rubric-number" aria-hidden="true">02.r</span>` | `pour un cas groupé, chaque titre descend d'un niveau (## devient <h3>) ; pour un cas seul, ## reste <h2>. L'identifiant est préfixé par le translationKey, avec la classe rubric-heading et <span class="rubric-number" aria-hidden="true">NN.r</span>` | Remplacement des valeurs en dur par des règles dynamiques d'architecture. Précision vitale sur la distinction entre cas de groupe et cas isolé. |
| prose | `un <details> natif liste les sections publiées et leurs rubriques, avec le nombre de rubriques calculé par le gabarit, sans JavaScript` | `une <nav> étiquetée ("Sommaire" / "Contents") contenant un <details> natif liste les sections publiées et leurs rubriques (récupérées via les cas enfants pour un groupe). Le total des rubriques est calculé par le gabarit.` | Ajout de la balise `<nav>` indispensable pour l'accessibilité. Clarification de la technique de récupération pour les groupes. |
| structure | `Libellé du résumé du sommaire (« Sommaire · N rubriques », « à valider » dans EXPERIENCE.md) ?` | PRESERVE | Question pertinente et à conserver. Le libellé doit être figé et la gestion du pluriel via `i18n` doit être anticipée. |

*(Bilan éditorial : 3 recommandations. La taille de la spec reste similaire mais gagne considérablement en précision et en robustesse).*

##### À trancher avant d'implémenter

- **Libellés du sommaire (`i18n`)** : Valider avec Arnaud le libellé définitif ("Sommaire · N rubriques" / "Contents · N sections") et la méthode de traduction pour gérer proprement le pluriel et les variables dans Hugo.
- **Plan des titres des cas isolés** : Confirmer explicitement que pour le cas 05 (cas isolé), le hook doit laisser les rubriques en `<h2>` et ne pas les descendre en `<h3>` comme il le fait pour les cas groupés de Chiliz.
- **Gestion des sous-rubriques Markdown (`###`)** : Confirmer que les éventuelles sous-rubriques ne reçoivent pas de numéro de rubrique, mais qu'elles doivent tout de même être descendues d'un niveau par le hook s'il s'agit d'un cas groupé.

### Triage des constats (17/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — préfixe `case-02-` écrit en dur | **retenu** (formulation) | le critère porte sur le pilote, donc `case-02-` y reste juste ; il énonce la règle d'AD-4 (préfixe = `translationKey`) et garde `case-02-` comme valeur attendue sur le pilote |
| A2 — numéro `02.r` écrit en dur | **retenu** (formulation) | même traitement : `NN.r`, où `NN` vient de `number`, soit `02.1` à `02.6` sur le pilote |
| A3 — cas sans groupe : `##` reste `<h2>` | **retenu**, vérification reportée | AD-4 ne descend les titres que pour un cas groupé : le hook porte la condition dès cette story. Aucun gabarit de cas sans groupe n'existe encore ; le rendu en `<h2>` est vérifié par la story 6.2, qui le demande déjà |
| A4 — titres `###` libres | **retenu** | AD-4 descend **chaque** titre d'un cas groupé : `###` sort en `<h4>`, avec l'identifiant préfixé, mais sans numéro, sans classe `rubric-heading` et sans entrée de sommaire (seules les rubriques, titres de niveau 2, en ont : `docs/format-cas.md`, `EXPERIENCE.md`) |
| A5 — `<nav>` absente du critère | **retenu** | `EXPERIENCE.md` l'exige déjà (« `nav` étiquetée « Sommaire » », repères) : le critère la nomme, avec un nom accessible venant d'`i18n/` |
| A6 — rubriques d'une page de groupe | **retenu** | le sommaire parcourt les cas publiés du groupe dans l'ordre `order`, et lit les rubriques de chacun ; le `_index` du groupe n'en porte aucune |
| A7 — nombre de rubriques sur une page de groupe | **question à Arnaud** | total des cas publiés, ou autre chose ; identique tant que seul le cas 02 est publié |
| A8 — `:target` et `scroll-margin-top` | **refusé** | UX-DR12 partage le travail : structure en 2.6, forme en 6.1, dont un critère porte exactement ces deux points. Aucun CSS dans cette story |
| Prose 1 et 2 | **retenus** | fondus dans A1 à A6 |
| Structure — question du libellé | **conservée** | question à Arnaud, avec le pluriel (`one`/`other` d'`i18n/`) |

Constat de l'auteur, hors rapport, trouvé en essayant le hook sur une copie jetable (02.1 à 02.6 en FR et en EN, `<h3>`, préfixe correct) : les identifiants produits par Hugo gardent les accents (`case-02-le-problème`), qu'un lien copié encode en `%C3%A8`. **Question à Arnaud.**

### Réponses d'Arnaud (17/09/2026)

- **Libellé** : la proposition d'`EXPERIENCE.md`, « Sommaire · N rubriques » / « Contents · N sections », au singulier « 1 rubrique » / « 1 section » ; la `nav` s'appelle « Sommaire » / « Contents ». `EXPERIENCE.md` passe la ligne `toc` en « décidé ».
- **Décompte (A7)** : sur une page de groupe, `N` est le total des rubriques des cas publiés, donc ce que liste le sommaire.
- **Identifiants** : en ASCII, par `markup.goldmark.parser.autoHeadingIDType: github-ascii` (`case-02-le-probleme`). Réglage global, noté dans AD-4.

La story est réécrite dans `epics.md` en conséquence ; sa question est close.

## Ce qui est livré

- `layouts/_markup/render-heading.html` : dans un cas, identifiant préfixé par le `translationKey`, titres descendus d'un niveau pour un cas groupé, classe `rubric-heading` et numéro `NN.r` masqué aux lecteurs d'écran sur les seules rubriques. Hors d'un cas, un titre est rendu comme Hugo le rendrait.
- `layouts/_partials/case-rubrics.html` : la liste ordonnée des rubriques d'un cas, lue dans `.Fragments.Headings`. Le hook y prend le rang, le sommaire ses entrées et son décompte : le numéro d'un titre et celui de son entrée de sommaire ne peuvent pas diverger.
- `layouts/_partials/toc.html`, appelé par `layouts/cases/section.html` entre le `h1` et les sections : `nav` étiquetée, `<details>` natif, une entrée « Cas 02 — titre » par cas publié puis ses rubriques numérotées.
- `i18n/` : `toc_label`, `toc` (singulier et pluriel), `toc_case`.
- `config/_default/hugo.yaml` : `autoHeadingIDType: github-ascii`.

Aucun CSS, aucun JavaScript.

### Essais, tous avec des copies locales défaites ensuite

| Essai | Constat |
| --- | --- |
| rendu de travail, pilote tel que commité | FR et EN : six `<h3 class="rubric-heading">`, 02.1 à 02.6, identifiants `case-02-contexte` … `case-02-ce-que-ca-montre` (ASCII) ; sommaire « Sommaire · 6 rubriques » / « Contents · 6 sections » ; ordre du DOM `main`, `h1`, `nav`, `section#case-02` ; « Contexte mission » et « En bref » sans identifiant, sans numéro, hors sommaire |
| `### Un titre libre é` ajouté sous « Le problème » | rendu `<h4 id="case-02-un-titre-libre-e">`, sans classe ni numéro, absent du sommaire ; la rubrique suivante reste 02.3 |
| cas 03 `order: 2`, une rubrique, `draft: false`, en rendu de travail | section 03 après la 02, `03.1`, entrées `#case-03` et `#case-03-contexte` ; les numéros du 02 ne changent pas ; « Sommaire · 7 rubriques » / « Contents · 7 sections » |
| même cas 03, `_index` Chiliz en `draft: false`, build de production | le pilote, brouillon, est absent (aucune occurrence de `case-02`) ; « Sommaire · 1 rubrique » / « Contents · 1 section » |
| `## Un titre hors cas é` ajouté à l'accueil | `<h2 id="un-titre-hors-cas-e">`, sans préfixe ni numéro |

Les fichiers suivis ont été restaurés depuis une copie faite avant l'essai, et les deux fichiers du cas 03, non suivis, supprimés : la leçon de la story 2.5 (`git checkout` ne défait pas un fichier non suivi) est appliquée. `git status` ne montre ensuite que les fichiers de la story ; les deux builds, refaits, sortent sans avertissement, et la production ne contient que ses quatre pages.

## Revue du code

### 17/09/2026 — `99fe2e9` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 31. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 69978970e2bc58c86e7ed7ce

##### Revue de code BMAD

###### Lentille : edge-case-hunter
- **location** : `layouts/_markup/render-heading.html` (calcul de la variable `$level`)
- **trigger_condition** : Présence d'un titre Markdown de niveau 6 (`######`) dans un cas groupé.
- **guard_snippet** : `{{- $level := math.Min (cond (isset $page.Params "group") (add .Level 1) .Level) 6 -}}`
- **potential_consequence** : Le hook génère une balise `<h7>` qui est invalide en spécification HTML5.

###### Lentille : verification-gap
- **Résultat** : Aucune faille de vérification détectée. La modification relève de la logique de rendu statique des gabarits Hugo. La vérification manuelle documentée dans la story couvre bien le comportement attendu, ce qui est conforme au processus actuel du dépôt (qui ne possède pas encore de tests automatisés d'interface).

##### Couche propre au projet

- NON BLOQUANT : La potentielle balise `<h7>` pour un titre de niveau 6 est un cas très à la marge qui ne casse aucun critère d'accessibilité immédiat sur les contenus prévus.
- NON BLOQUANT : Les critères d'acceptation de la story sont pleinement satisfaits et l'intention de la fonctionnalité (sommaire natif, identifiants ASCII) est respectée.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité ni susceptible d'être affiché.
- NON BLOQUANT : Aucun script, procédure ou skill n'est impacté par ce patch ; leur concordance reste intacte.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (zéro JavaScript, respect WCAG).
- NON BLOQUANT : Il n'y a aucun script shell dans les modifications, aucune erreur ne passe en silence.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 31 (`99fe2e9`, verdict `pass`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| E1 — `######` dans un cas groupé rendu en `<h7>` | **reporté** à la story 3.4 | réel, mais aucun cas n'a de titre au-delà du niveau 3 (`docs/format-cas.md` ne prévoit que `##` et des `###` libres). Borner le niveau dans le hook masquerait un titre hors format au lieu de le signaler : la place de la règle est le contrôle de titres C4, qui refusera un titre de niveau 6 dans un cas groupé. Entrée ajoutée à `deferred-work.md` |
| Couche projet (six points) | confirmations | aucune suite |

## Reporté

- `######` dans un cas groupé rendu en `<h7>` : story 3.4 (C4), voir `deferred-work.md`.
