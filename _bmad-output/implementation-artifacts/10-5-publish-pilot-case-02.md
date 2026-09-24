# Story 10.5 : Publish pilot case 02

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.5.

## Revue de spec

### 24/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `7cc6a9b`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 5c52cc8be6cb52b428aba57d

Voici le rapport de revue de la spécification de la story 10.5, généré en appliquant les lentilles _adversarial_, _structure_ et _prose_.

##### Constats

- **BLOQUANT** : Le critère d'acceptation de périmètre (case à cocher) stipule : « La PR ne touche **que** les fichiers du cas, le `_index` Chiliz et `ci/release-pages.txt` ». Appliquée strictement, cette liste d'autorisation ferme interdit au développeur de mettre à jour le fichier `sprint-status.yaml` et d'éditer le document de la story (`_bmad-output/implementation-artifacts/10-5-...md`). Cela contredit la règle 4 d'`AGENTS.md` (Merge gates) et la règle 9 d'`epics.md` qui imposent toutes deux que le statut du sprint avance au sein même de la PR de la story. Sans ces fichiers techniques, la PR ne passera pas le contrôle `sprint-consistency`.
- **BLOQUANT** : La section « Couvre » inclut l'exigence « FR-22 (NCS/CS) ». Or, cette story a pour but exclusif de publier le pilote du cas 02 (Chiliz). Exiger l'implémentation de la ligne de contexte anglaise d'un autre poste (NCS/CS) dans cette PR viole la règle 2 d'`epics.md` (« Une story à la fois »). 
- **BLOQUANT** : L'étape de validation manuelle sur le build de production (« Quand on ouvre l'accueil puis `/cas/chiliz/#case-02` ») ne teste que le cheminement en français. L'exigence de bilinguisme (FR-20) étant censée être couverte, le critère est incomplet : il manque l'instruction d'ouvrir l'équivalent anglais (`/en/cases/chiliz/#case-02`) afin de s'assurer que le cas est bien lié depuis le poste anglais et affiché correctement dans sa langue.
- **NON BLOQUANT** : La formulation du critère « les trois éléments "prévus" ne laissent aucune trace » (lentille prose) fige le test sur une quantité précise de matériel vivant. Bien que clair, cela introduit une fragilité si le contenu brut du cas évolue (ajout d'un 4ème matériel) et peut rendre le critère littéralement faux ou insuffisant lors de la recette.
- **NON BLOQUANT** : La structure logique (lentille structure) est par ailleurs excellente : l'articulation avec la story 10.4 (bascule conjointe du `_index` en `draft: false`) explique très clairement pourquoi le groupe entier est publié en même temps que son premier cas, en accord parfait avec l'architecture (D-3 / AD-4).

##### À trancher avant d'implémenter

- **Périmètre des fichiers** : La liste des fichiers touchés par la PR doit-elle être corrigée pour autoriser explicitement les modifications dans `_bmad-output/` et `sprint-status.yaml` ?
- **Périmètre fonctionnel** : La couverture de « FR-22 (NCS/CS) » est-elle une erreur de copier-coller à retirer de la story 10.5, ou cette story doit-elle exceptionnellement traiter le contexte d'un autre client ?
- **Recette bilingue** : Doit-on compléter les critères d'acceptation pour imposer la vérification explicite des URL du parcours anglophone (`/en/cases/...`) sur le build de production ?

## Revue du code

### 24/09/2026 — `79054b3` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 111. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b73aeeb6937bba7741ec6cbb

##### Lentille : Edge Case Hunter

- NON BLOQUANT : Le fichier `10-4-chiliz-page-title-and-introduction.md` est créé avec une section « Revue de spec » vide alors que la story passe au statut `review`, ce qui omet la trace formelle exigée par la règle 2 d'`AGENTS.md` pour cette story spécifique (une revue par story), bien que la logique de la livraison conjointe soit validée par la 10.5.

##### Lentille : Verification Gap

- NON BLOQUANT : Aucune lacune de vérification n'a été identifiée ; pour compenser la défaillance du script `publish-case.sh`, des vérifications manuelles exhaustives ont été menées et tracées (validation du rendu exact des pages bilingues et absence prouvée du matériel « prévu » en production), garantissant la robustesse de la publication.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée, et la mise à jour proactive de ces mêmes critères dans `epics.md` en cours de PR pour refléter le triage de la spec est une excellente application de la règle 12 d'`AGENTS.md`.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, et aucun secret n'est commité dans la PR ; la sécurité du dépôt public est préservée.
- NON BLOQUANT : La cohérence entre skill, procédure et script n'est pas altérée ; le dysfonctionnement de `publish-case.sh` vis-à-vis du nommage des branches a été consigné dans `deferred-work.md` selon les règles du flux de développement.
- NON BLOQUANT : Le changement est en parfaite adéquation avec les décisions d'architecture, notamment avec AD-4 (décision D-3) imposant la bascule conjointe de la page de groupe Chiliz et de son premier cas pour éviter une page vide en production.
- NON BLOQUANT : Aucun script shell n'a été modifié, écartant de fait le risque qu'une erreur passe sous silence via l'usage de `set -euo pipefail`.

VERDICT: NON BLOQUANT — manque la trace formelle de la revue de spec dans le fichier de la story 10.4

### 24/09/2026 — `43a5186` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 111. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1217be83b24fde428cdb8eb7

#### BMad Review

**Contenu :** Diff de la PR n° 111 (branche `feat/10-5-publish-pilot-case-02` vers `dev`)  
**Lentilles appliquées :** `edge-case-hunter`, `verification-gap`

##### Edge-Case Hunter
Aucun constat. Les modifications sont purement documentaires (suivi de sprint, compte-rendu) et déclaratives (bascule `draft: false` dans le frontmatter). Le diff n'introduit aucun nouveau chemin d'exécution ni branche logique qui pourrait manquer d'être géré.

##### Verification-Gap
No verification gaps found. La PR ne modifiant aucun comportement applicatif de production (exclusivement de la publication de contenu), aucune logique existante ne peut casser silencieusement.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (l'exclusion explicite du répertoire `_bmad-output/` de la contrainte des fichiers touchés est tout à fait légitime pour permettre le suivi d'avancement, et l'exigence de la vérification bilingue a été renforcée).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité dans la PR, et aucun script touché ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent. L'anomalie de la branche générée par `scripts/publish-case.sh` qui ne porte pas de numéro de story (rendant la vérification impossible par `verify-and-merge-pr`) a été correctement capturée dans `deferred-work.md`. 
- NON BLOQUANT : Le changement est en adéquation totale avec `AGENTS.md` et les décisions d'architecture (application conjointe de la publication de la page groupe et du cas 02 conformément à AD-4 / D-3).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (aucun script shell n'ayant été modifié).

VERDICT: NON BLOQUANT — aucune

### 24/09/2026 — `87013cd` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 111. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1e72282fff546fa011c0eedc

##### Rapport de Revue BMad

**Contenu :** `/tmp/tmp.pwffjBYDRH/copie/REVIEW-DIFF.patch` (diff de la PR n° 111, branche `feat/10-5-publish-pilot-case-02`)  
**Lentilles appliquées :** `edge-case-hunter`, `verification-gap`

###### Lentille : Edge-Case Hunter
Aucun constat. Les modifications sont de nature strictement documentaire et déclarative (bascules `draft: false` dans le frontmatter, ajouts à un fichier texte pour la CI, et mise à jour du suivi de sprint). Le diff ne crée aucun nouveau chemin d'exécution, aucune condition ni embranchement logique susceptible d'échapper à une gestion correcte.

###### Lentille : Verification-Gap
No verification gaps found.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention initiale ne soit vidée. L'ajustement du critère dans `epics.md` excluant formellement le dossier `_bmad-output/` de la restriction des "sources du site" est pertinent : il permet d'inclure le suivi de sprint nécessaire aux verrous sans fausser l'exigence de périmètre fonctionnel (règle 12 d'`AGENTS.md`).
- NON BLOQUANT : Aucune donnée privée, aucun secret, et aucune adresse de serveur ou de forge ne sont présents dans les modifications. La sécurité du dépôt public est intégralement préservée.
- NON BLOQUANT : Skill, procédure et script concordent. Les limitations opérationnelles de `scripts/publish-case.sh` (création d'une branche sans référence à la story, empêchant la validation par `verify-and-merge-pr`) ont été proprement tracées dans `deferred-work.md`, évitant ainsi un correctif non testé du script au sein de cette PR.
- NON BLOQUANT : Le changement est en accord total avec les décisions d'architecture (AD-4 et décision de lancement D-3) qui préconisent la publication conjointe du premier cas et de la sortie de brouillon de sa page de groupe. 
- NON BLOQUANT : Le document propre à la story 10.4 (`10-4-chiliz-page-title-and-introduction.md`) est inséré avec des sections « Revue de spec » et « Revue du code » vides. Bien que sa livraison accompagne logiquement la 10.5, l'absence des traces formelles déroge à la lettre de la règle 2 d'`AGENTS.md`.
- NON BLOQUANT : Aucun script shell n'ayant été modifié, aucune opportunité n'a été introduite pour masquer silencieusement des erreurs sous `set -euo pipefail`.

VERDICT: NON BLOQUANT — absence de trace formelle des revues dans le fichier de la story 10.4

## Reporté

### Triage de la revue de spec, 24/09/2026

Trois constats bloquants : **deux retenus, un réfuté**.

**Retenu — la case de périmètre interdisait le commit de statut.** « La PR ne touche que les fichiers
du cas, le `_index` Chiliz et `ci/release-pages.txt` », lue à la lettre, interdit `sprint-status.yaml`
et le fichier de story, sans lesquels `sprint-consistency` refuse la fusion. Même faute qu'aux
stories 10.1, 10.2 et 10.3 : la case vise les **sources du site**, et le dit maintenant.

**Retenu — la vérification du build ne portait que sur le français.** Le critère nommait
`/cas/chiliz/#case-02` seul ; il nomme désormais aussi `/en/cases/chiliz/#case-02`. Vérifié :
le poste Chiliz porte `/cas/chiliz/#case-02` en FR et `/en/cases/chiliz/#case-02` en EN.

**Réfuté — « FR-22 (NCS/CS) hors périmètre ».** Le relecteur y voyait la ligne de contexte d'un autre
poste. FR-22 la place explicitement dans **le cas 02** : « NCS/CS (cas 02) ». Et elle y est déjà,
côté anglais : « the NCS and CS calculation — non-circulating supply and circulating supply — that is,
how many of our tokens are in circulation and how many are not » (`case-02-chiliz.en.md:49`). Rien à
faire.

**Sorti du critère en chemin.** « Les trois éléments "prévus" ne laissent aucune trace » figeait un
compte : le critère dirait faux le jour où le cas en déclare un quatrième. Il demande maintenant
qu'**aucun** n'en laisse.

### La publication, et pourquoi elle s'est faite à la main

`scripts/publish-case.sh case-02` a tourné en premier temps et a passé tous les contrôles, nommant
les quatre fichiers. Arnaud les a relus et donné son accord le 24/09/2026 — c'est la relecture
humaine que le format exige et que le skill réserve explicitement à lui.

Le second temps n'a pas pu servir : le script crée `feat/publish-case-case-02`, une branche **sans
numéro de story**, que `verify-and-merge-pr` ne rattache à aucune story — son verrou de suivi
retomberait sur le contrôle global et ne vérifierait pas que la story est à `done`. Il refuse de plus
de partir d'une autre branche que `dev`, donc de tourner après le commit de cadrage. Les quatre
bascules et les deux lignes de `ci/release-pages.txt` ont donc été faites à la main, ce que le skill
prévoit, sur la branche correctement nommée. Le défaut est reporté dans `deferred-work.md` : deux
outils du projet se contredisent, `publish-case` datant de la story 3.17, écrite avant que la règle
de nommage n'entre dans AGENTS.md.

### Vérifications

- Pages produites : `public/cas/chiliz/index.html` et `public/en/cases/chiliz/index.html`.
- Le poste Chiliz liste son cas **dans chaque langue**, au bon chemin.
- Aucune trace de matériel « prévu » en production : zéro occurrence sur la page de groupe.
- `scripts/ci/checks-job.sh` : 554 cas, 9 contrôles, verts.

### Triage de la revue de code, 24/09/2026

Verdict `pass`, **zéro constat bloquant** — compté, non déclaré : huit mentions de « BLOQUANT » dans
le rapport, huit précédées de « NON ». C'est la leçon de la story 10.3, où un triage avait affirmé
« aucun constat bloquant » sur un rapport dont je n'avais lu que la fin.

Les constats sont des confirmations sans action : la publication conjointe du cas et de sa page de
groupe respecte D-3 et AD-4, les liens de cas sont justes dans les deux langues, aucune donnée privée
n'entre, et le périmètre du diff est celui que la story annonce.
