# Story 10.10 : Mission context content

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.10.

Troisième des stories ajoutées à l'epic 10 par la proposition de changement du 02/10/2026, et la seule
d'intégration (point 21) : le contenu **fourni par Arnaud** passe les contrôles. Elle dépend de la
10.9 (`done`, PR n° 131), qui rend secteur, périmètre et bloc « Stack » et a créé C25.

## Le contenu fourni

Le 03/10/2026, Arnaud a remis une archive produite avec un agent de rédaction dédié
(`site-v2.zip` : 14 fichiers de poste, `stack.yaml`, pages « À propos », 7 cas). Elle n'est pas
commitée ; son contenu intégré l'est, dans les fichiers publics qu'il alimente. **Tout le contenu
vient d'Arnaud et de son parcours** (sa réponse du 03/10/2026) : c'est la confirmation que NFR-10
exige pour chaque fait absent des sources.

L'archive allait au-delà du périmètre et portait des régressions, relevées par l'orchestrateur et
tranchées par Arnaud le 03/10/2026 :

| # | Dans l'archive | Décision |
|---|---|---|
| 1 | Cas 01 : « Julie » à la place de « ma cliente » (5 occurrences) | **Refusé** — règle 8 de `format-cas.md`, décision d'Arnaud du 21/09 : aucune personne physique nommée. Le texte publié est gardé, Institut Lionne compris. |
| 2 | `draft: true` sur les cas publiés 01, 02, 05 | **Refusé** — ils restent publiés (`draft: false`) ; les brouillons 03, 04, 06 ne bougent pas. |
| 3 | Cas 01 : période « 2025–2026 » au lieu de « depuis mai 2025 » | **Retenu** — « la période publiée n'était pas correcte ». Écrite « 2025 – 2026 » (tiret demi-cadratin entouré d'espaces) ; C25 apprend la forme « AAAA – AAAA ». |
| 4 | Cas 05 EN : slug `orange-crv-performance` | **Retenu, après rappel de l'historique** : la story 10.7 avait remplacé ce slug par `orange-visit-reports-performance`, « crv » ne disant rien à un lecteur anglophone. Options présentées à Arnaud : garder celui de la 10.7 (recommandé par l'orchestrateur), revenir à `orange-crv-performance`, ou un troisième. **Réponse : `orange-crv-performance`** (03/10/2026). Le site n'est pas en ligne : aucune URL publique ne casse, et aucun lien du dépôt ne cite l'ancien slug (grep). |
| 5 | « À propos » sans `layout: about` | **Refusé** — le gabarit en dépend ; la clé est gardée. « depuis avril 2008 » → « depuis 2008 » est retenu (incohérence du début de carrière). |
| 6 | `stack.yaml` réécrit en objets (`name`, `cases`, `positions`), exclusions décidées effacées | **Refusé par défaut** — le manifeste et C6 lisent une liste de chaînes. Le format actuel est gardé ; les termes sont ajoutés, avec l'en-tête prévu par la story et les exclusions. |
| 7 | Chiliz : lieu « Lyon · full remote » ; April : « Région de Lyon » | **Par défaut, « Full remote » et « Lyon » sont gardés** : pour un poste en télétravail, nommer la ville dit le lieu de résidence (AGENTS.md, frontière public/privé). Arnaud peut lever ce choix. |
| 8 | Cas 05 : rôle « Expert Zend Framework 1 » | **Retiré** après la revue de spec (A3) : seule la stack du cas 05 change. |
| 9 | Cas 02 (dates de 2024), 03 (période, stack vide), 06 (ligne de contexte EN) | **Hors périmètre** : gardés de côté pour l'epic 13 (stories 13.1, 13.3) ; les pages de cas ne changent pas ici. |

## Revue de spec

### 03/10/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `3b64e00`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: cc8720b52222522dede02f2e

##### Revue de spécification (Story 10.10)

**Lentille Adversarial (Failles, Sécurité, Contradictions majeures)**
- BLOQUANT : Fuite de données privées. La note de l'auteur (point 7) indique conserver par défaut "Lyon" pour un poste en télétravail, tout en notant que cela révèle le lieu de résidence. Cela viole frontalement `AGENTS.md` ("city of residence"). La ville doit être refusée, et non gardée par défaut.
- BLOQUANT : Contradiction de source de vérité. Le prérequis de contenu exige de se baser sur le fichier de brouillon `docs/private/drafts/contexte-des-missions-v0.md`. Or, l'auteur indique utiliser une archive `site-v2.zip` contenant les 14 fichiers déjà découpés. La spec doit désigner clairement la source unique de vérité.
- BLOQUANT : Modification non autorisée d'une page de cas. Le critère 3 stipule que la mise à jour de la stack du cas 05 est "la seule modification d'une page de cas". Cependant, la note de l'auteur (point 8) valide la modification du rôle en "Expert Zend Framework 1" pour ce même cas 05, ce qui crée une deuxième modification en contradiction directe avec ce critère.
- BLOQUANT : Modification silencieuse d'un contrôle de l'architecture. La note de l'auteur (point 3) indique que le contrôle C25 "apprend la forme AAAA – AAAA", mais la spec ne mentionne aucune évolution de ce contrôle. Selon les règles du projet, une évolution d'un contrôle existant doit figurer explicitement dans les critères d'acceptation.

**Lentille Structure (Vérifiabilité, Ordre, Manques)**
- BLOQUANT : Fichier manquant dans le périmètre d'action. Le critère 4 demande de corriger l'incohérence sur la page "À propos" (changement en "depuis 2008"). Or, le premier bloc "Étant donné" ne couvre que les quatorze fichiers de poste et le fichier de données de stack, oubliant de déclarer la modification du fichier de la page "À propos", ce qui rend le critère invérifiable sur la portée des fichiers.
- BLOQUANT : Incohérence manquante dans la liste exhaustive du critère 4. La note de l'auteur (point 3) retient le changement de période "2025 – 2026" au lieu de "depuis mai 2025" pour le cas 01, mais cette incohérence n'est pas listée dans les cas traités par le critère d'acceptation 4. Le critère ne peut donc pas valider formellement cette correction.

**Lentille Prose (Clarté, Ambiguïté)**
- NON BLOQUANT : Ambiguïté sur la gestion des exclusions dans `stack.yaml`. Le critère 2 demande que les termes refusés (CI, VPS, etc.) n'y soient pas, puis précise que "les exclusions de n8n et Stripe pour le cas 01 restent". Il n'est pas clair si de nouvelles exclusions explicites doivent être ajoutées pour bloquer les termes refusés (s'ils venaient à être cités), ou s'ils doivent simplement être omis de la liste des termes.
- NON BLOQUANT : Formulation perfectible au critère 3. L'expression "c'est la seule modification d'une page de cas" pourrait être rendue plus explicite en écrivant "aucune autre section du cas 05 ni aucune autre page de cas n'est modifiée", évitant toute ambiguïté d'interprétation.

##### À trancher avant d'implémenter
- Faut-il supprimer "Lyon" du poste April pour respecter l'interdiction stricte de publier la ville de résidence (`AGENTS.md`) ?
- La source du contenu à intégrer est-elle le fichier brut `contexte-des-missions-v0.md` ou l'archive `site-v2.zip` remise par la suite ?
- La modification du rôle ("Expert Zend Framework 1") est-elle autorisée sur la page du cas 05, et le critère 3 doit-il être assoupli en conséquence ?
- Le contrôle C25 doit-il être formellement mis à jour dans la spec pour accepter le tiret "AAAA – AAAA" ?
- Le fichier "À propos" et l'incohérence de période du cas 01 ("2025 – 2026") doivent-ils être explicitement ajoutés aux critères d'acceptation pour être validés ?

### Tri des constats (03/10/2026, orchestrateur)

| # | Constat | Décision |
|---|---|---|
| A1 | « Lyon » gardé pour un poste en télétravail révèle la résidence (BLOQUANT) | **Réfuté, lecture corrigée.** Le poste en télétravail est Chiliz, et c'est précisément lui qui **garde « Full remote » sans ville** (décision 7). « Lyon » reste pour April Technologies, mission en prestation sur site, déjà publiée ainsi : une ville de mission est autorisée (AGENTS.md ; `format-cas.md`, règle 5 ; `format-parcours.md`). |
| A2 | Deux sources : le premier jet v0 ou l'archive ? (BLOQUANT) | **Retenu.** La source est **l'archive remise par Arnaud le 03/10/2026**, qu'il déclare entièrement issue de lui et de son parcours ; elle remplace le premier jet v0, qui en était l'étape préparatoire. Le prérequis de contenu — un contenu validé par Arnaud, sans `[TODO]` ni `[À TRANCHER]` — est rempli par elle : aucun marqueur n'y reste dans les fichiers intégrés. |
| A3 | Le rôle « Expert Zend Framework 1 » est une seconde modification du cas 05, contraire au critère 3 (BLOQUANT) | **Retenu : la décision 8 est retirée.** Le rôle du cas 05 n'est pas modifié ; seule sa stack l'est, comme le critère le demande. Arnaud ne l'avait pas tranché explicitement. |
| A4 | C25 évolue sans critère qui le dise (BLOQUANT) | **Retenu, écrit ici.** La période correcte du cas 01, donnée par Arnaud (« 2025 – 2026 »), n'a aucune forme lue par C25 : la story ajoute la forme « AAAA – AAAA » (FR et EN, tiret demi-cadratin entouré d'espaces, début au 1er janvier, fin au 31 décembre), avec un test qui échoue sans elle (point 9), et met à jour la ligne C25 de l'architecture et de `docs/procedures/check.md`. |
| S1 | « À propos » hors du périmètre déclaré (BLOQUANT) | **Réfuté.** Le critère 4 cite cette incohérence nommément (« juillet 2008 au parcours, avril 2008 sur « À propos » ») : la corriger sur la page « À propos » est dans le critère. |
| S2 | La période du cas 01 n'est pas dans la liste du critère 4 (BLOQUANT) | **Retenu comme arbitrage d'Arnaud, écrit ici** (décision 3) : une correction de fait par l'auteur. Avec le slug du cas 05 (décision 4, tranchée le même jour), ce sont les modifications de pages de cas que le critère 3 ne prévoyait pas ; elles sont décidées par Arnaud, et listées. |
| P1 | Exclusions de `stack.yaml` ambiguës | **Retenu.** Les notions refusées sont simplement absentes de la liste ; l'en-tête dit qu'elles vont dans le corps d'un poste (`format-parcours.md`). Les exclusions décidées pour les cas (Python, n8n et Stripe pour le cas 01, REST) restent écrites. |
| P2 | Formulation du critère 3 | **Pris acte.** |

## Implémentation

### Fichiers

- **Les quatorze postes** `content/career/position-*.{fr,en}.md` : repris de l'archive, front matter et
  corps, avec deux exceptions (décision 7) — Chiliz garde « Full remote » / « Fully remote », April
  Technologies 2017 garde « Lyon » / « Lyon, France ». Les commentaires YAML déjà présents dans le
  dépôt (pourquoi « Parcours antérieur » n'a pas de `company` ; d'où vient la période de Ton Pote le
  Geek) sont gardés : ils ne sont pas rendus et l'archive ne les contredit pas. Aucun `[TODO` ni
  `[À TRANCHER` dans les quatorze fichiers. Ce que l'archive change aussi, au-delà de `sector`,
  `stack` et du corps : Mister Auto, période « Janvier 2018 – octobre 2019 » et rôle « Architecte
  technique · team lead » ; Ton Pote le Geek, rôle « Fondateur · automatisation et outils sur
  mesure », `setup: ton-pote-le-geek` et `location: "Full remote"` ; Parcours antérieur, rôle
  « Développeur puis consultant PHP / Zend Framework » et lieux « Grenoble, Paris, Lyon » (villes de
  mission).
- **`data/stack.yaml`** : format inchangé (liste de chaînes, notes en fin de ligne). En-tête du
  critère 2 (« … dans la `stack` d'un cas ; la `stack` d'un poste porte celles du projet entier »),
  plus la ligne qui renvoie les notions — DEX, microservices, APIs, CI, VPS ou infrastructure
  auto-hébergée — au corps d'un poste. Exclusions gardées (Python pour le cas 02, REST pour le cas
  06) ; celle de n8n et Stripe **pour le cas 01** est récrite, puisque les deux termes existent
  désormais pour le poste Ton Pote le Geek. « En attente : cas 03 » gardée (epic 13). « Zend
  Framework » scindé ; plus aucune stack ne le porte seul.
- **Cas 05** (FR et EN) : `context.stack` « Zend Framework » → « Zend Framework 1 » ; slug EN →
  `orange-crv-performance` (décision 4). Rôle, période et texte inchangés.
- **Cas 01** (FR et EN) : `context.period` → « 2025 – 2026 » (décision 3). Rien d'autre.
- **« À propos »** (FR et EN) : « depuis avril 2008 » → « depuis 2008 », « since April 2008 » →
  « since 2008 » ; `layout: about` gardé, aucune clé `draft` ajoutée. Le reste du corps est identique
  à celui de l'archive (comparé).
- Cas 02, 03, 04, 06 et le reste de l'archive : non touchés (décision 9).

**Termes ajoutés au vocabulaire (28)** : AWS SQS/SNS, BackboneJS, CakePHP, Chiliz Chain, DFNS,
Docker, Drupal, Ethereum, ethers.js, GitHub Actions, GitLab CI, Hibernate, JavaScript, jQuery,
Marionette, MySQL, n8n, Node.js, RabbitMQ, Redis, Solana, Stripe, SugarCRM, TypeScript, viem.js,
WordPress, Zend Framework 1, Zend Framework 2 (« Zend Framework » retiré). 43 termes en tout, tous
utilisés par au moins un cas ou un poste. GitHub Actions et GitLab CI sont des outils nommés, pas la
notion générique « CI » refusée par le critère 2 : l'archive d'Arnaud les porte, et leur note le dit.

### Le contrat du corps (`docs/format-parcours.md`)

Première personne partout ; aucun mot de durée de poste (« ans », « years », « mois »… : seul « chaque
semaine » / « every week » apparaît, chez Ton Pote le Geek, et décrit le travail manuel supprimé, pas
la durée de l'activité). Phrases par corps, FR / EN : Chiliz 5 / 6, Synolia 3 / 3, Mister Auto 3 / 4,
April 3 / 5, Orange 4 / 6, Ton Pote le Geek 4 / 5 — l'anglais ajoute les lignes de contexte prévues
(ce qu'est la société, la société de prestation). **Écart non corrigé : Parcours antérieur a 2 phrases
en FR comme en EN**, sous le minimum de 3. Le corriger reviendrait à redécouper le texte d'Arnaud ;
c'est à lui de dire s'il le garde ainsi. Aucun contrôle ne compte les phrases d'un poste.

### Incohérences du critère 4

| Incohérence | Décision |
|---|---|
| Début de carrière : juillet 2008 au parcours, avril 2008 sur « À propos » | **Corrigée** : « depuis 2008 » sur « À propos » (décision 5). |
| Chiliz, « quatre ans » à l'accueil contre la période | **Non traitée ici** : la phrase est dans le pitch (`content/_index.{fr,en}.md`, story 10.1), que l'archive ne contient pas. Reste ouverte, à trancher par Arnaud. |
| Mister Auto et Synolia sur janvier 2020 | **Corrigée** par l'archive : Mister Auto finit en octobre 2019. |
| Chiliz, « traitement par lots on-chain » | **Corrigée** : le corps dit « arrivé en environnement de test mais jamais mis en production » (règle 6). |
| Chiliz, « conçue from scratch » | **Corrigée** : le corps dit l'application « démarrée en Python en janvier 2024 puis abandonnée », reconstruite en Symfony à partir de mai 2024. |
| Mister Auto, « Chef de projet » | **Corrigée** : « Architecte technique · team lead ». |
| Orange et cas 05 | Pas une incohérence (Q2), C25 le confirme. |

### C25 — la forme « AAAA – AAAA »

`scripts/checks/periods.sh` lit l'intervalle d'années, FR et EN, tiret demi-cadratin entre deux
espaces : début au 1er janvier de la première année, fin au 31 décembre de la seconde. Un intervalle
inversé (« 2026 – 2025 ») passe par la garde existante de lecture (`readable`) et reste illisible ;
une forme mêlée (« juillet 2022 – 2026 », « 2022 – avril 2026 ») aussi. Les formes lues que cite le
message d'erreur ont été mises à jour.

Aîné et cadette (point 19) : la nouvelle branche est la jumelle de l'intervalle de mois. Ses gardes :
séparateur exact (oui, même regex) ; bornes en mois (oui) ; intervalle inversé illisible (oui, par
`readable`, que les deux formes partagent) ; mois dans la langue du fichier (sans objet : aucun mot).

Tests (`test-periods.sh`) : `periods_intervalle_d_annees_lu` (sous une fin ouverte, comme le cas 01 ;
bornes incluses ; « 2025 – 2025 » ; dans un intervalle de mois) et
`periods_intervalle_d_annees_qui_deborde` (fin après le poste en FR, début avant en EN, poste en
intervalle d'années) ; l'intervalle d'années inversé ajouté au cas des intervalles inversés, avec les
nouvelles formes citées en FR et en EN. « 2025 – 2026 » sort de la liste des formes illisibles,
remplacé par ses variantes mal écrites (« 2025-2026 », « 2025 - 2026 », « 2025–2026 », « 2025 —
2026 », « 25 – 26 ») et les deux formes mêlées ; le poste illisible du cas existant s'écrit désormais
« 2022 - 2026 ».

### C19 — `sector` et `stack` obligatoires dans un poste publié

`scripts/checks/content.sh` : un poste **publié** sans `sector`, sans `stack`, ou dont le `sector` est
resté en `[TODO`, fait échouer ; un brouillon les tolère absentes. Le partage avec le tamis « présente
mais vide » de la story 10.9 est net pour qu'une faute ne soit dite qu'une fois : ici la clé absente
(ou le `[TODO` du secteur), là la clé écrite vide. Un terme `[TODO` dans la stack d'un poste publié
reste refusé par C6.

Aîné et cadette (point 19) : la règle « `role` et `period` exigés ». Ses gardes : clé absente refusée
(oui) ; valeur blanche refusée, brouillon compris (oui, déjà par le tamis de la 10.9) ; `[TODO` toléré
dans un brouillon, refusé publié (oui pour `sector` ; pour `stack`, par C6) ; **absence refusée même
dans un brouillon — non** : c'est la différence voulue par la story (« les brouillons tolérés comme les
autres clés de contenu »), testée dans les deux sens.

Test (`test-content.sh`) : `content_c19_secteur_et_stack_obligatoires_publie` — les deux présentes
passent ; sans `sector`, refus FR et EN, et la stack n'est pas signalée ; sans `stack`, refus, et le
secteur n'est pas signalé ; `sector` en `[TODO` passe en brouillon et échoue publié ; `sector` vide
dit une seule fois. Le cas `content_c19_poste_en_brouillon` publie désormais un poste complet ; le cas
de la 10.9 dit « absentes d'un brouillon, elles passent ».

**Gardes retirées une fois (point 9)**, fichier restauré après chaque mutation :

| Mutation | Résultat |
|---|---|
| C25 sans la branche « AAAA – AAAA » | échec, `periods_intervalle_d_annees_lu` (attendu 0, obtenu 1) |
| C19 sans la règle « sector absent » | échec, `test-content.sh` (attendu 1, obtenu 0) |
| C19 sans la règle « stack absente » | échec, `test-content.sh` (attendu 1, obtenu 0) |
| C19 sans la règle « sector en [TODO publié » | échec, `test-content.sh` (attendu 1, obtenu 0) |
| C19 sans la tolérance des brouillons | échec, `test-content.sh` (attendu 0, obtenu 1) |

### Documents passés au présent (points 8 et 13)

`grep` de « 10.10 » et de « facultativ » dans `docs/` et `_bmad-output/planning-artifacts/` :
`docs/format-parcours.md` (tableau des clés, clés vides, formes de période, scission de Zend
Framework ; `updated`), `ARCHITECTURE-SPINE.md` (statut, AD-18 `sector` et `stack`, lignes C19 et
C25), `docs/procedures/check.md` (lignes C19 et C25), `EXPERIENCE.md` (ligne « poste sans stack »).
Les mentions restantes de la 10.10 dans `epics.md`, le PRD et la proposition du 02/10/2026 sont
historiques ou de calendrier, laissées telles quelles.

### Résultats

- `scripts/check.sh` : 12 contrôles passés, niveau standard (C3, C6, C13, C19, C24, C25 compris) ;
  avec `PRIVATE_PATTERNS_FILE`, C21 confronte aussi les CV PDF, sans motif.
- `bash scripts/tests/run.sh` : 955 cas réussis, 1 ignoré (`pdf_repli_sur_la_liste_du_depot` : pas de
  `docs/private/` dans ce worktree).
- `scripts/build.sh production` : sans avertissement.

### Premier écran à 390 × 844 (FR-37)

Méthode de la story 10.9 : Chromium sans tête et Puppeteer dans le conteneur `local/chrome-fonts`,
sans réseau, sur la sortie de `scripts/build.sh production` copiée hors du dépôt, 390 × 844 en
densité 3, `getBoundingClientRect` du lien « Cas 02 » (puis de sa ligne de liste), FR et EN, pile du
site puis polices imposées.

| Lien « Cas 02 » (haut → bas) | FR | EN |
|---|---|---|
| pile du site (Charter absente, Noto Serif retenue) | 791 → 844 | 791 → 844 |
| Noto Serif imposée | 791 → 844 | 791 → 844 |
| DejaVu Serif imposée | 867 → 920 | 818 → 870 |

Avec Noto Serif, le lien tient au pixel près, en FR comme en EN, avec le contenu livré : le secteur
« Blockchain · fan tokens » ne fait pas passer la ligne de rôle à trois lignes. Avec DejaVu Serif, il
passe sous le pli : en EN comme avant la story (818 → 870), en FR plus bas qu'avant (841 → 893 sur le
site de la 10.9, sans secteur), le secteur ajoutant une ligne de rôle — le même chiffre que la
variante « moyen » de la 10.9. C'est le dépassement que l'arbitrage d'Arnaud du 03/10/2026 accepte
avec une serif de repli large.

### Hors périmètre, noté

- **Le CV PDF de la story 7.4**, fourni à la main, ne porte pas ce contexte (secteur, périmètre, stack
  du projet) : la divergence entre le CV en ligne et le PDF est notée, sans être corrigée ici — les PDF
  générés depuis les mêmes données relèvent de la v1.1 (PRD §8.2).
- Aucun contenu de `docs/private/` n'est recopié ; le garde-fou passe.

## Revue du code

### 03/10/2026 — PR n° 132, `gemini-3.1-pro-high`, SHA `539cc98`, verdict `pass`

Rapport recopié de la PR (le script a tourné depuis le dépôt principal, sur une autre branche).

llm-review sha=539cc988799761bea637f34ee6bd4ffad4c7b941 base=dev model=gemini-3.1-pro-high verdict=pass

_Revue par `scripts/llm-review.sh` : `agy --mode plan`, copie isolée hors du dépôt au SHA relu, sans `.env` ni `docs/private/` ; skill `bmad-review` appliqué par le relecteur (angles : edge-case-hunter, verification-gap, plus la couche propre au projet). Fichiers créés ou modifiés par le relecteur dans la copie : aucun._

JETON: 25006667d3f6b2b0778e8495

### BMad Review

**Lentille : edge-case-hunter**
Aucun cas limite non géré trouvé. Les règles ajoutées dans `content.sh` (vérification stricte de `sector` et `stack` selon le statut de publication et le type de valeur) et dans `periods.sh` (expression régulière rigoureuse pour l'intervalle `AAAA – AAAA`) couvrent de manière exhaustive toutes les branches (valeurs absentes, vides, `[TODO`, ou mal formatées).

**Lentille : verification-gap**
No verification gaps found. (Aucune faille de vérification n'a été trouvée). Les nouveaux comportements introduits ont tous été systématiquement couverts par des tests équivalents dans `test-content.sh` et `test-periods.sh` (y compris les tests d'échec sur les bords et l'inclusion des années dans les mois). 

### Couche propre au projet

* **Critères d'acceptation** : Les critères de la story 10.10 sont satisfaits (intégration du contenu fourni pour les quatorze postes, évolution de `stack.yaml`, correction des incohérences du « À propos » et du cas 01). L'intention n'est pas vidée et les arbitrages actés par Arnaud sont respectés. (NON BLOQUANT)
* **Données privées et secrets** : Aucune donnée privée, adresse de forge ou secret n'est commité ni affiché. La conservation de la ville "Lyon" pour April Technologies respecte les règles, puisqu'il s'agit d'une mission sur site et non du lieu de résidence en télétravail (le poste Chiliz affiche d'ailleurs rigoureusement "Full remote"). (NON BLOQUANT)
* **Concordance skill, procédure et script** : Une parfaite concordance. Les ajouts et modifications de comportements dans `content.sh` (règles C19 pour les postes publiés) et `periods.sh` (règles C25 pour la forme « AAAA – AAAA ») ont été fidèlement répercutés dans `docs/procedures/check.md`. (NON BLOQUANT)
* **Cohérence AGENTS.md et architecture** : Le changement s'aligne scrupuleusement avec les décisions documentées. `ARCHITECTURE-SPINE.md` consigne correctement l'évolution de la décision AD-18, et `format-parcours.md` reflète ces modifications sans contradiction. (NON BLOQUANT)
* **Scripts shell (set -euo pipefail)** : Aucune erreur ne passe sous silence. Dans les tests, les constructions conditionnelles d'assertion comme `[[ $err != *"stack absente"* ]] || { ... exit 1; }` utilisent correctement l'opérateur OU (`||`) pour échouer explicitement en cas d'erreur inattendue, garantissant ainsi la robustesse sous `set -e`. (NON BLOQUANT)

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue (orchestrateur)

Aucun constat ne demande de changement ; les sept sont des constats de conformité, **pris acte** un par un :
edge-case-hunter (C19 et C25 couverts) ; verification-gap (aucune faille) ; critères satisfaits et
arbitrages respectés ; aucune donnée privée — « Lyon » pour April, mission sur site, « Full remote »
pour Chiliz (triage A1) ; concordance de `check.md` ; cohérence avec AD-18 et `format-parcours.md` ;
aucune erreur silencieuse dans les tests. L'orchestrateur a relu lui-même les différences des pages
publiées hors postes (cas 01, cas 05, « À propos ») : elles se limitent aux décisions 3, 4 et 5.

## Arbitrages d'Arnaud sur les deux points laissés ouverts (03/10/2026)

1. **« Quatre ans chez Chiliz » dans le pitch de l'accueil** (`content/_index.{fr,en}.md`), contre
   3 ans et 10 mois d'après la période publiée : **gardé, arrondi assumé** (option a). Le contrat
   sans durée (`docs/format-parcours.md`, Q2) vise les postes, pas le pitch. Options écartées :
   « près de quatre ans » ; retirer la durée du pitch. Le fichier n'est pas modifié.
2. **« Parcours antérieur » à deux phrases**, sous le minimum de trois du contrat : **accepté tel
   quel** (option a), exception notée ici. Options écartées : couper la seconde phrase à la jonction
   Avenue Web Système / FHM Solutions ; réécriture par Arnaud.

Les six incohérences du critère 4 sont ainsi toutes tranchées : début de carrière, recouvrement
Mister Auto / Synolia, batch du cas 03, « from scratch », « Chef de projet » (corrigés par le contenu
fourni), et « quatre ans » (confirmé).
