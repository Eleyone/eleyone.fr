# Story 13.1 : Integrate and release case 03

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 13.1.

Dernier cas de l'epic 13 (point 21) : le cas 03 (« Chiliz, batch de transactions ») est **rédigé par
Arnaud** — `content/cases/chiliz/case-03-chiliz.{fr,en}.md`, en brouillon. Restent trois `[TODO]` par
langue : la période, la stack, et une ligne « stack » dans le contexte. Blocages Q2, Q4 et Q5 levés le
05/10/2026 (PR n° 146) :

- **Q2** : période « août 2024 – octobre 2024 » (archive d'Arnaud du 03/10/2026, confirmée) ;
- **Q4** : close — le site est cohérent ;
- **Q5** : stack — PHP, Symfony, AWS SQS/SNS, PostgreSQL, Node.js, TypeScript, Fireblocks ; la règle
  « seules les technologies citées dans le cas » (`docs/format-cas.md`, FR-6) oblige le texte à les
  citer : formulation soumise à Arnaud.

**Mise en ligne** : arbitrage d'Arnaud du 06/10/2026 — les cas 03, 04 et 06 partent en production
ensemble, par un seul tag, après cette story ; écart assumé avec « un par un » de l'epic 13.

## Revue de spec

### 06/10/2026 — `gemini-3.1-pro-high` (angles : adversarial, structure, prose), `dev` à `a88f530`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 556b5e108fb4e5de2c0509cc

**Objectif identifié :** Ce document existe pour aider un agent développeur (LLM) à implémenter de manière vérifiable l'intégration du cas 03.
**Modèle de structure :** Spécification technique.

##### Lentille : Adversarial
- BLOQUANT : L'AC3 affirme que « le cas est mis en ligne seul », ce qui contredit directement la décision d'Arnaud du 06/10/2026 exigeant que les cas 03, 04 et 06 partent en production ensemble par un seul tag.
- BLOQUANT : L'opération manuelle mentionne un « tag de mise en ligne par le skill release » pour cette story, or cela déclencherait la mise en production isolée du cas 03 en violation de l'arbitrage de déploiement groupé.
- BLOQUANT : Le titre de la story (« Integrate and release case 03 ») mentionne la mise en production (release), ce qui est devenu faux et hors de la portée de la story suite à la nouvelle décision.
- BLOQUANT : L'AC2 stipule que la stack doit être citée, mais les notes de PR précisent que la formulation a été « soumise à Arnaud ». Le critère est invérifiable et inatteignable par l'agent sans attendre cette validation.
- BLOQUANT : La spec omet de fournir une instruction pour traiter le `[TODO]` de la période (août 2024 – octobre 2024) explicitement mentionné dans les notes, ce qui laissera le document final incomplet et erroné.
- BLOQUANT : La mention `(*relecture*)` dans l'AC2 est ambiguë et ne définit pas qui (l'agent ou l'humain) doit effectuer cette action, la rendant invérifiable automatiquement par l'agent ou la CI.
- BLOQUANT : L'AC1 exige la valeur statique `order: 2`. Sans vérifier le contenu actuel du cas 02 (qui pourrait déjà utiliser 2 ou un autre modèle d'ordonnancement), ce critère est présomptueux et risque de créer un conflit d'ordre.
- BLOQUANT : L'AC1 exige que « les numéros "02.x" ne changent pas », un critère invérifiable de manière statique puisqu'il ne précise pas la cible technique (frontmatter, ancres HTML, variables globales ou texte rendu).
- NON BLOQUANT : L'AC1 utilise le masque de fichier `case-03-<nom-court>.{fr,en}.md` au lieu de nommer explicitement le fichier attendu `case-03-chiliz.{fr,en}.md`.
- NON BLOQUANT : L'AC1 indique que « le poste Chiliz gagne un lien », une formulation floue quant à la nature et la localisation exactes de ce lien, ce qui complexifie la vérification.

##### Lentille : Structure
- NON BLOQUANT : (CUT) Puisque l'arbitrage annule la publication immédiate, l'ensemble de l'AC3 et de la ligne "Opération manuelle" doivent être retirés (économie estimée de ~25 mots, supprime un risque d'erreur).
- NON BLOQUANT : (CONDENSE) Les balises d'en-tête ("Couvre", "Dépendances", "Bloquée par") n'apportent pas de valeur pour l'implémentation de la story elle-même et peuvent être regroupées.
- NON BLOQUANT : (MOVE) Le bloc "Prérequis de contenu" et les notes de levée des blocages seraient plus utiles s'ils étaient déplacés juste au-dessus des critères d'acceptation qu'ils justifient.

*Résumé structurel : 3 recommandations, ciblant principalement la suppression de la section de mise en ligne devenue obsolète. Les objectifs de concision pour l'agent sont respectés.*

##### Lentille : Prose
- NON BLOQUANT : (PROSE) Original : "le poste Chiliz gagne un lien" -> Révision : "la page de la section Chiliz affiche un nouveau lien vers le cas 03". 
- NON BLOQUANT : (PROSE) Original : "sans modifier le `_index` ni les gabarits" -> Révision : "en s'intégrant dynamiquement sans modifier les fichiers `_index` ou les gabarits existants".
- NON BLOQUANT : (PROSE) Original : "afin de voir comment Arnaud arbitre quand un sujet n'aboutit pas" -> Révision : "afin de documenter les décisions d'Arnaud sur un projet non déployé".
- NON BLOQUANT : (PROSE) Original : "les deux versions" -> Révision : "les versions française et anglaise du cas".

##### À trancher avant d'implémenter
- Faut-il supprimer l'AC3, retirer l'opération manuelle de release et renommer la story pour s'aligner sur la décision de grouper la mise en production des cas 03, 04 et 06 ?
- L'agent doit-il rédiger lui-même la phrase d'intégration de la stack ou l'implémentation est-elle suspendue en l'attente de la formulation qu'Arnaud doit fournir ?
- Comment l'agent doit-il gérer le remplacement du `[TODO]` correspondant à la période (août 2024 – octobre 2024), qui est actuellement absent des critères d'acceptation de la spécification ?
- Quelle est la définition technique et la responsabilité exacte attendue pour la mention `(*relecture*)` de l'AC2 ?

### Tri des constats (06/10/2026, orchestrateur)

| # | Constat | Décision |
|---|---|---|
| 1 | AC3 « mis en ligne seul » contredit la mise en ligne groupée (BLOQUANT) | **Retenu** : arbitrage d'Arnaud du 06/10/2026 — 03, 04 et 06 partent par un seul tag après cette story. L'AC3 se lit « aucune autre page ne change de contenu » ; la story se clôt à la fusion (comme 13.2, constat 5) et la vérification en ligne est consignée avec la publication groupée. |
| 2 | L'opération manuelle déclencherait une publication isolée (BLOQUANT) | **Réfuté** : aucun tag n'est posé par cette story ; `release` reste lancé par Arnaud, une fois, pour les trois cas. Rien à exécuter de plus ici. |
| 3 | Le titre « and release » est devenu faux (BLOQUANT) | **Réfuté** : la clé `13-1-integrate-and-release-case-03` est figée (branche, sprint, verrous) ; le cas est bien publié, par le tag groupé. Titre inchangé. |
| 4 | AC2 : la formulation de la stack attend Arnaud (BLOQUANT) | **Retenu** : la phrase est soumise à Arnaud avant toute modification du contenu ; les sources (cas privé, résumé condensé) ne disent pas le rôle de chaque technologie, donc rien ne leur en attribue sans sa validation. |
| 5 | La période n'est pas dans les critères (BLOQUANT) | **Retenu** : `context.period` passe à « août 2024 – octobre 2024 » / « August 2024 – October 2024 » (Q2), dans la casse des cas 02 et 04 ; C25 la vérifie dans la période du poste Chiliz, C5 refuse tout `[TODO` restant. |
| 6 | « *(relecture)* » : qui ? (BLOQUANT) | **Retenu comme lecture** : la relecture d'Arnaud, tracée par son « relu » avant les gestes de `publish-case --relu` (story 3.17), comme pour 13.2 et 13.3. |
| 7 | `order: 2` présomptueux (BLOQUANT) | **Réfuté** : vérifié — cas 02 `order: 1`, cas 04 `order: 3` ; le cas 03 porte déjà `order: 2`. |
| 8 | « 02.x ne changent pas » invérifiable (BLOQUANT) | **Retenu comme lecture** : les numéros de rubrique rendus (`case-rubrics.html`, « 02.3 ») de la section du cas 02 dans `public/cas/chiliz/index.html` — vérifiés sur le build de production. |
| 9 | Masque `case-03-<nom-court>` | **Réfuté** : gabarit de nommage de `docs/format-cas.md` (même décision qu'en 13.2, constat 1). |
| 10 | « Le poste Chiliz gagne un lien » flou | **Retenu comme lecture** : le lien du cas 03 sous le poste Chiliz de l'accueil (CV), vérifié dans le build de production. |
| 11–13 | Structure : couper l'AC3, regrouper les en-têtes, déplacer les prérequis | **Refusés** : `epics.md` garde la forme commune aux stories de l'epic 13 ; l'AC3 est lu au constat 1. |
| 14–17 | Prose : quatre reformulations | **Refusées** : le texte de l'epic n'est pas réécrit pour cette story ; le sens est déjà fixé par les lectures ci-dessus. |

## Publication (06/10/2026)

- Stack (Q5) : formulation de l'option 1, choisie par Arnaud le 06/10/2026 — une ligne neutre dans
  « Contexte », sans rôle attribué aux technologies (les sources ne le disent pas) ; « pour les wallets »
  reprend le cas 04. Options écartées : une phrase avec les rôles (à confirmer par Arnaud), une phrase
  écrite par lui.
- Période : « août 2024 – octobre 2024 » / « August 2024 – October 2024 » (Q2), comprise dans celle du
  poste Chiliz (C25).
- `scripts/publish-case.sh case-03` (audit) : contrôles verts ; deux fichiers à passer hors brouillon,
  `case-03` à ajouter à `ci/release-pages.txt`, `group-chiliz` déjà présent.
- **Relecture d'Arnaud** : « relu » (06/10/2026).
- Gestes de `--relu` faits sur la branche de la story, comme en 13.2 et 13.3 : `draft: false` dans le
  front matter seul ; `case-03` ajouté à `ci/release-pages.txt`.
- Build de production : `public/cas/chiliz/index.html` porte les sections `case-02`, `case-03`,
  `case-04` dans cet ordre ; numéros « 02.1 » à « 02.6 » inchangés ; l'accueil FR et EN porte le lien
  du cas 03 sous le poste Chiliz ; `_index`, postes et gabarits inchangés (constats 8 et 10 du tri).
- `scripts/check.sh --release` avec les vraies valeurs légales : 13 contrôles passés.
- Mise en ligne : groupée avec les cas 04 et 06, par un seul tag après la fusion (constat 1).

## Revue du code

### 06/10/2026 — `0ce3fca` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 149. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: cc261052ef4d5a7b06401897

##### Lentille : edge-case-hunter
Aucun constat. Le diff concerne exclusivement du contenu statique (Markdown, YAML, texte) et ne comporte aucune logique d'exécution, branche conditionnelle ou frontière technique à évaluer pour des chemins non gérés.

##### Lentille : verification-gap
No verification gaps found. (Le changement est strictement non comportemental : modification de métadonnées, passage du statut de brouillon à publié, et ajout à la liste statique de mise en ligne).

##### Contrôles propres au projet
- **Critères d'acceptation** : Satisfaits. Les métadonnées `period` et `stack` ont été renseignées selon les arbitrages confirmés d'Arnaud, le texte a été mis à jour avec les technologies correspondantes, le statut `draft` est passé à `false`, et la page a été ajoutée au fichier de release.
- **Données privées et secrets** : Aucune donnée privée, aucun nom d'hôte, aucune adresse de serveur et aucun secret n'est commité.
- **Concordance des skills, procédures et scripts** : Non applicable (aucun script ou procédure modifié).
- **Cohérence architecture et AGENTS.md** : Respectée. Le flux de travail linéaire et l'architecture sont suivis à la lettre (le suivi de sprint `sprint-status.yaml` passe bien à l'état `review`, la trace de la revue de spécification est présente, le fichier `ci/release-pages.txt` est mis à jour).
- **Scripts shell (set -euo pipefail)** : Non applicable (aucun script shell modifié).

VERDICT: NON BLOQUANT — aucune réserve


### Décisions (06/10/2026, orchestrateur)

Verdict `pass`, aucun constat sur les deux lentilles ni sur la couche projet : rien à retenir, réfuter ni reporter.

## Mise en ligne (06/10/2026)

Publiée en `v1.1.0` avec les cas 03, 04 et 06, par un seul tag (arbitrage d'Arnaud du 06/10/2026) :
répétition `v1.1.0-rc.1` / `rc.2` verte sur `5f3538a`, audit `release` vert (PR n° 150), `--merge`
lancé par Arnaud, run `release` du tag `v1.1.0` en succès. Vérifié sur le site servi à 10:31 UTC :
la page Chiliz porte les sections `case-02`, `case-03`, `case-04` en FR et en EN, la ligne « Côté
technique » / « On the technical side » du cas 03 est servie, l'accueil FR et EN lie les cas 02, 03
et 04 sous le poste Chiliz et le cas 06 (`/cas/april-hors-perimetre/`,
`/en/cases/april-beyond-scope/`, réponse 200, une `<meta name="description">` chacune).
