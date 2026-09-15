# Story 0.9 : Shared sprint reading and script tests

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.9, réécrite après la revue de spec ci-dessous. Origine : rétrospective de l'epic 0, `_bmad-output/implementation-artifacts/epic-0-retro-2026-09-15.md`, section « Constats » (D4, D7, P1).

## Revue de spec

### 15/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `8fc807d`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 52df49fb620ebf24bcdeb3e1

### Rapport de revue

**Analyse du document :** Cette spécification (story 0.9) a pour but de définir les exigences pour centraliser la lecture du suivi de sprint et ajouter des tests automatisés rejouables hors ligne pour les scripts bash du projet. Ce document s'adresse à l'agent de développement qui implémentera la story.

#### Lentille Adversarial (Recherche de failles et cas limites)

- **Localisation :** Critère d'acceptation 1 (Lecture du suivi)
  - **Condition :** Le comportement de la fonction en cas de valeur "illisible" (erreur) n'est pas spécifié.
  - **Correction / Garde-fou :** Préciser comment la fonction signale une erreur (code de retour non nul, sortie vide sur `stdout`, ou message d'erreur spécifique).
  - **Conséquence :** Les scripts appelants pourraient mal interpréter une erreur de lecture silencieuse et prendre une mauvaise décision, comme valider une vérification qui aurait dû échouer.

- **Localisation :** Critère d'acceptation 2 (Logique de décision et fichiers en entrée)
  - **Condition :** La mécanique exacte séparant l'appel réseau (I/O) de la logique pure n'est pas détaillée.
  - **Correction / Garde-fou :** Expliciter que l'appel `curl` reste dans le corps du script appelant, qui sauvegarde la réponse dans un fichier temporaire pour la passer ensuite à la fonction de `lib/`.
  - **Conséquence :** L'agent pourrait tenter de créer un système complexe de mocks réseau au lieu de simplement isoler la logique pure, compliquant inutilement les tests.

- **Localisation :** Critère d'acceptation 2 (Duplications D7)
  - **Condition :** La phrase "ne sont mises en commun que si ces tests sollicitent le code concerné" est subjective et difficilement vérifiable.
  - **Correction / Garde-fou :** Soit lister explicitement les duplications à factoriser (comme le parsing du nom de branche ou la pagination), soit exiger la factorisation de toutes les duplications couvertes par les tests de D7.
  - **Conséquence :** Désaccord probable lors de la revue de code LLM sur ce qui "devait" ou non être factorisé, causant des itérations superflues.

- **Localisation :** Critère d'acceptation 3 (Tests hors ligne)
  - **Condition :** L'environnement d'exécution des tests n'est pas défini (le runner local x86_64 Ubuntu ou l'image `CHECK_IMAGE` Alpine).
  - **Correction / Garde-fou :** Spécifier où les tests bash doivent tourner. Les comportements de GNU `grep`/`bash` (local) et Busybox (Alpine) peuvent différer.
  - **Conséquence :** Des tests qui passent en local mais échoueraient dans l'environnement cible (ou vice versa) à cause de subtilités d'outillage.

- **Localisation :** Critère d'acceptation 3 (Pagination)
  - **Condition :** La méthode pour simuler la pagination de l'API Gitea hors ligne n'est pas décrite.
  - **Correction / Garde-fou :** Préciser que la pagination nécessite des fichiers de fixtures multiples (corps de réponse et en-têtes HTTP de lien) pour tester correctement la boucle.
  - **Conséquence :** Le test de la pagination D1 pourrait être simpliste ou mal implémenté, et ne pas tester la vraie gestion de la boucle de requêtes.

- **Localisation :** Critère d'acceptation 3 (Tests des pièges P1)
  - **Condition :** Les tests vérifient la logique des scripts actuels, mais aucun mécanisme ne s'assure que les pièges du shell (P1) ne sont pas réintroduits dans les tests eux-mêmes ou dans de futurs scripts.
  - **Correction / Garde-fou :** Demander l'ajout d'un linter (ex: ShellCheck) si disponible, ou exiger explicitement que les pièges P1 soient traqués dans les PRs.
  - **Conséquence :** Les pièges identifiés sont documentés mais resteront susceptibles d'être réintroduits silencieusement.

- **Localisation :** Check-list de fin (Travail reporté)
  - **Condition :** Il est demandé d'ajouter un renvoi à la story par "ajout seulement" à l'entrée `deferred-work.md`, ce qui implique de ne pas fermer cette entrée.
  - **Correction / Garde-fou :** Préciser explicitement si l'entrée doit être considérée comme résolue à la fin de cette story, ou pourquoi elle doit rester ouverte.
  - **Conséquence :** Le travail reporté ne sera jamais vidé, créant une ligne de dette technique obsolète.

- **Localisation :** Check-list de fin (Intégration CI)
  - **Condition :** `scripts/tests/run.sh` est lancé manuellement sur la tête de la PR, mais aucune intégration permanente n'est prévue dans `scripts/check.sh` ou `checks-job.sh`.
  - **Correction / Garde-fou :** Exiger l'ajout de l'appel à `run.sh` dans la suite de contrôles bloquants pour l'avenir.
  - **Conséquence :** Sans exécution automatique continue, les tests pourraient se casser dans le futur (régression silencieuse) sans faire échouer la CI.

- **Localisation :** Général
  - **Condition :** Le nom et l'organisation des fichiers de destination dans `scripts/lib/` ne sont pas spécifiés.
  - **Correction / Garde-fou :** Indiquer si les nouvelles fonctions communes vont dans `gitea.sh`, ou si de nouveaux fichiers (ex: `sprint.sh`, `core.sh`) doivent être créés.
  - **Conséquence :** L'agent pourrait regrouper toutes les fonctions sans rapport dans le fichier existant `gitea.sh` ou créer une prolifération de micro-fichiers, dégradant la structure.

- **Localisation :** Critère d'acceptation 1
  - **Condition :** Adopter les tolérances larges de `sprint-consistency.sh` (guillemets, commentaires) pour tous les scripts diminue la rigueur attendue jusqu'ici par `verify-and-merge-pr.sh`.
  - **Correction / Garde-fou :** Confirmer que cet assouplissement de la validation (notamment lors du merge) est intentionnel et souhaité.
  - **Conséquence :** Un statut "brouillon" ou mal formaté mais toléré pourrait passer les verrous, créant un précédent dangereux pour les vérifications de la CI.


#### Lentille Structure (Cohérence et densité)

- **Modèle retenu :** Document d'exigences / Spec.
- **Résultat :** Le document est concis, sans redondance manifeste, et suit rigoureusement la syntaxe comportementale (Étant donné / Quand / Alors). Le niveau de détail est approprié à la taille de la story.
- **Bilan :** 0 recommandation (Passage propre).


#### Lentille Prose (Clarté et fluidité)

| Pass | Texte Original | Texte Révisé | Changements |
|---|---|---|---|
| prose | `limitée à la section development_status, qui garde les tolérances actuelles de sprint-consistency.sh [...] et traite comme illisible toute valeur` | `limitée à la section development_status, en gardant les tolérances actuelles de sprint-consistency.sh [...] et en traitant comme illisible toute valeur` | Formulation plus active qui clarifie que ce sont des propriétés inhérentes à la fonction commune. |
| prose | `qui prennent des fichiers en entrée (réponses JSON de la forge, diff, suivi) et que les scripts appellent ;` | `prenant des fichiers en entrée (réponses JSON de la forge, diff, suivi) et appelées par les scripts ;` | Simplification de la syntaxe par la suppression des propositions subordonnées relatives superflues. |


#### À trancher avant d'implémenter

- **Intégration automatique des tests :** Faut-il ajouter l'appel à `scripts/tests/run.sh` dans `scripts/check.sh` (ou le workflow de CI) pour que ces tests soient joués automatiquement à l'avenir, plutôt que d'être juste lancés manuellement sur cette PR ?
- **Architecture d'appel (réseau vs logique) :** Confirmer le design attendu : les appels `curl` restent-ils dans le corps des scripts principaux, qui écrivent la réponse dans un fichier temporaire avant d'appeler la fonction pure de la librairie ?
- **Emplacement des fonctions :** Dans quel(s) fichier(s) précis de `scripts/lib/` les nouvelles fonctions doivent-elles être créées (ex: `sprint.sh` pour la lecture du YAML) ?
- **Signalement des erreurs :** Comment la nouvelle fonction de lecture du suivi doit-elle remonter au script appelant qu'une valeur est "illisible" (code de retour non nul, mot-clé spécifique en sortie) ?
- **Statut du travail reporté :** L'entrée « aucun test automatisé » dans `deferred-work.md` doit-elle finalement être close/supprimée une fois les tests ajoutés, ou intentionnellement laissée ouverte ?

Tri de l'auteur (questions tranchées par Arnaud le 15/09/2026) :

- signalement d'une valeur illisible par la fonction de lecture du suivi : tranché, codes de retour `0` trouvée, `1` absente, `2` illisible ou ambiguë, rien sur la sortie standard en cas d'erreur ;
- frontière entre appel à la forge et logique : corrigé, les appels restent dans le script, les fonctions lisent des fichiers ou des commits ; la lecture paginée de la timeline reçoit le nom de la fonction qui écrit une page ;
- D7 subjectif : corrigé, liste exacte de ce qui est mis en commun (numéro de story tiré du nom de branche, clé et statut d'une story) ;
- environnement des tests : tranché, sur le poste et en CI ; les tests ne dépendent que de `bash`, `git`, `jq`, `grep` GNU et des outils de base de `CHECK_IMAGE` (Alpine avec bash et grep GNU, table des conventions d'AD-24) ; preuve dans un conteneur `alpine:3.24` ;
- simulation de la pagination : corrigé, fixtures d'une page par fichier avec page `null` finale ; la timeline n'utilise pas d'en-tête de lien ;
- ShellCheck : écarté, absent du poste et aucun nouvel outil ; la section « Pièges connus » et les tests couvrent le besoin ;
- renvoi dans `deferred-work.md` sans fermeture : corrigé, l'entrée est close par une ligne ajoutée, les entrées existantes ne se modifient pas ;
- intégration de `run.sh` à la CI : tranché, ajoutée à la story 3.12 (job de contrôle partagé) ;
- emplacement des fonctions : tranché, `scripts/lib/sprint.sh` et `scripts/lib/merge-gates.sh` ;
- tolérances de lecture contre rigueur du verrou : écarté, la règle du commit de statut compare toujours les lignes du diff à l'identique ; la fonction commune ne sert qu'à retrouver la clé et le statut d'une story ;
- rédaction (deux reformulations) : corrigé à la réécriture ;
- mesure de la taille (question de l'auteur) : tranché, seul le code de production compte (`scripts/*.sh`, `scripts/lib/`) ; les tests et leurs fixtures en sont indissociables.

## Revue du code

### 15/09/2026 — `9c22536` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 14. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ffc38b833f997e41deda9c65

**Annonce de la revue**
Classe de contenu : diff de PR (`REVIEW-DIFF.patch`).
Lentilles sélectionnées : `edge-case-hunter`, `verification-gap`.

##### Lentille : edge-case-hunter

- **lens** : edge-case-hunter
- **location** : `scripts/lib/merge-gates.sh` (fonction `status_commit_ok`)
- **trigger_condition** : L'extraction des lignes `removed` et `added` emploie la construction `grep -vE ... || true` pour éviter l'échec si le motif n'est pas trouvé.
- **guard_snippet** : Conserver et analyser le code de retour pour distinguer l'absence de correspondance (1) d'une erreur système (2).
- **potential_consequence** : Une erreur interne de `grep` (code 2) sera silencieusement avalée et interprétée comme une liste vide, ce qui annule la protection de `set -euo pipefail`.
BLOQUANT : laisse passer une erreur en silence.

##### Lentille : verification-gap

- **lens** : verification-gap
- **location** : `_bmad-output/implementation-artifacts/0-9-shared-sprint-reading-and-script-tests.md`
- **trigger_condition** : La section `## Revue du code` ne contient que le titre `## Reporté` et omet la consignation demandée.
- **guard_snippet** : Inscrire formellement sous `## Revue du code` le SHA du commit résolvant D4, D7 et P1.
- **potential_consequence** : Un élément explicite de la check-list n'est pas respecté, causant une rupture de traçabilité avec la rétrospective de l'epic 0.
BLOQUANT : casse un critère d'acceptation.

##### Couche propre au projet

- **location** : `scripts/lib/merge-gates.sh` et `docs/procedures/shell-scripts.md`
- **trigger_condition** : Le masquage des erreurs via `grep || true` est formellement recensé comme un piège connu dans le nouveau fichier de procédure `shell-scripts.md`, mais le code copié dans la nouvelle bibliothèque reproduit ce même défaut.
- **guard_snippet** : Appliquer rigoureusement la parade (différencier les codes 1 et 2) à toutes les lignes modifiées ou déplacées, y compris `status_commit_ok`.
- **potential_consequence** : Incohérence frontale entre la procédure créée par la story et le code livré avec.
BLOQUANT : laisse passer une erreur en silence.

- **location** : Sécurité, confidentialité et cohérence des procédures
- **trigger_condition** : Analyse globale des modifications, des fixtures ajoutées (`titre-special.json`, `pleine-1.json`, etc.) et des scripts de test.
- **guard_snippet** : Aucun changement requis.
- **potential_consequence** : Aucune donnée privée, adresse de forge ou secret n'est exposé. Les tests tournent strictement en local/CI de test (`compte-essai`). Les commandes documentées par les procédures correspondent bien au contenu réel des scripts. L'architecture respecte les spécifications (pas de `jq` dans `sprint.sh`).
NON BLOQUANT : règles d'intégrité respectées.

VERDICT: BLOQUANT — le fichier de story omet le commit requis par la check-list, et la bibliothèque de fusion réintroduit un grep || true qui masquerait une erreur en silence.

### 15/09/2026 — `e1f847a` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 14. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: bfe4bdb83e614e3d85a20281

##### Rapport de revue BMAD

###### Lentille : edge-case-hunter
- **lens** : edge-case-hunter
- **location** : `scripts/lib/merge-gates.sh` (fonction `select_lines`), `scripts/check-private.sh`, `scripts/create-pull-request.sh`, `scripts/verify-and-merge-pr.sh`
- **trigger_condition** : Le masquage des erreurs par `grep ... || true` a été systématiquement retiré et remplacé par l'évaluation du code de retour `rc=$?` combiné à la condition `((rc <= 1))` pour une assignation de variable sans faille, ou par des conditions `((rc != 0))` et `((rc == 1))` pour des vérifications directes. 
- **guard_snippet** : Aucun. La méthode est parfaitement implémentée.
- **potential_consequence** : Les erreurs fatales (code 2 de `grep`) entraînent un rejet ou un arrêt explicite sans masquer le fonctionnement normal d'une recherche infructueuse (code 1), sécurisant ainsi totalement l'exécution sous `set -euo pipefail`.
NON BLOQUANT

###### Lentille : verification-gap
- **lens** : verification-gap
- **location** : `_bmad-output/implementation-artifacts/0-9-shared-sprint-reading-and-script-tests.md`
- **trigger_condition** : Le SHA du commit fermant D4, D7 et P1 n'est pas formellement inscrit sous la section "Revue du code" du fichier de story, contrairement à la demande d'une itération précédente.
- **guard_snippet** : Inscrire cette valeur lors du commit final faisant passer le statut de la story de `review` à `done`.
- **potential_consequence** : Les règles du projet autorisent ce comportement : le diff indique bien le statut en cours à `review`, ce qui justifie techniquement l'absence du SHA final. L'intention du critère reste préservée jusqu'au commit d'achèvement de la story.
NON BLOQUANT

###### Couche propre au projet
- **location** : Intégrité des données privées (`scripts/check-private.sh` et fixtures de test)
- **trigger_condition** : Les corrections corrigent la faille du filtrage du fichier de motifs et des chemins interdits. Une erreur de lecture est désormais considérée comme un échec global de validation.
- **guard_snippet** : Aucune intervention nécessaire.
- **potential_consequence** : Le garde-fou empêche formellement qu'une défaillance inattendue de `grep` ne laisse passer une donnée sensible. Aucune donnée privée, adresse serveur ou secret n'a été exposée, et les nouvelles fonctions garantissent la sécurité requise.
NON BLOQUANT

- **location** : Cohérence architecture et procédures (`docs/procedures/shell-scripts.md`)
- **trigger_condition** : Le remaniement des scripts est solidement documenté dans le nouveau fichier de procédure. Les fonctions `sprint.sh` et `merge-gates.sh` agissent conformément aux D-1 à D-17, isolant les appels API de la forge de la logique pure de vérification.
- **guard_snippet** : Aucune intervention nécessaire.
- **potential_consequence** : Les procédures reflètent fidèlement le comportement du nouveau code shell, documentant parfaitement les pièges `grep` et les tests ajoutés sans ambiguïté.
NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur les revues du code de la PR n° 14 :

- `9c22536` (block) :
  - `grep … || true` dans `status_commit_ok`, qui avalerait une erreur de grep : corrigé (`e1f847a`), fonction `select_lines` qui distingue « rien trouvé » d'une erreur ; balayage des scripts sur décision d'Arnaud, cinq autres cas où une erreur pouvait laisser passer corrigés (chemins interdits et filtrage des motifs de `check-private.sh`, filtrage des motifs de `verify-and-merge-pr.sh`, `create-pull-request.sh` et `llm-review.sh`), quatre cas déjà en refus laissés ; deux cas de test ajoutés ;
  - commits fermant D4, D7 et P1 absents du fichier de story : écarté, case remplie par le présent commit de statut ;
  - couche propre au projet : même constat que le premier, corrigé.
- `e1f847a` (pass) : aucun constat nouveau ; confirmation que la case D4, D7, P1 se remplit au commit `done`.

Constats de l'auteur : Docker était absent du shell WSL, alors qu'il figure parmi les prérequis du poste ; installé par Arnaud (`docker.io`, groupe `docker`) pour la preuve dans `alpine:3.24`. Le cas « fichier de motifs illisible » est sans objet dans le conteneur, qui tourne en root.

Preuves : `scripts/tests/run.sh` réussit sur la tête `e1f847a`, 34 cas sur le poste et 34 cas dans `alpine:3.24` (bash 5.3.9, grep GNU 3.12, git 2.54, jq 1.8.2) ; lecture commune du suivi identique à l'ancienne pour les 88 stories du suivi réel.

Constats de la rétrospective fermés par cette story (`_bmad-output/implementation-artifacts/epic-0-retro-2026-09-15.md`, section « Constats ») :

| Code | Fermé par | Preuve |
|---|---|---|
| D4 | `76c64bc` | `scripts/lib/sprint.sh`, utilisée par `sprint-consistency.sh`, `llm-review.sh` et `verify-and-merge-pr.sh` ; cas de `scripts/tests/test-sprint.sh` ; comparaison sur le suivi réel |
| D7 | `76c64bc` | numéro de story tiré du nom de branche et lecture du suivi mis en commun, et eux seuls ; décisions des verrous séparées des appels à la forge dans `scripts/lib/merge-gates.sh` |
| P1 | `76c64bc`, `e1f847a` | `scripts/tests/run.sh` (34 cas, poste et `alpine:3.24`), `docs/procedures/shell-scripts.md` et sa section « Pièges connus » ; entrée de `deferred-work.md` close par ajout |

### 15/09/2026 — `2eb0672` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 14. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 3994ee9063c42060c0690e96

**Annonce de la revue**
Classe de contenu : diff de PR (`REVIEW-DIFF.patch`).
Lentilles sélectionnées : `edge-case-hunter`, `verification-gap`, plus la couche propre au projet.

##### Lentille : edge-case-hunter

- **lens** : edge-case-hunter
- **location** : `scripts/lib/merge-gates.sh` et `scripts/lib/sprint.sh`
- **trigger_condition** : Vérification des limites, codes de retour et variables locales pour éviter les erreurs masquées ou les conflits de noms (ex. l'utilisation de `rule_status_file` à la place de `status_file` pour esquiver avec succès les collisions avec les constantes déclarées en `readonly` par les scripts appelants).
- **guard_snippet** : La logique implémentée (tests explicites de `$?`, boucle de timeline testant `size` et `max`, préfixes des noms locaux) couvre complètement ces cas. Aucun changement supplémentaire n'est requis.
- **potential_consequence** : L'absence de failles sur ces cas garantit que le comportement des bibliothèques sera prédictible et conforme à l'intention, évitant la reprise des valeurs parentes par erreur et l'échec de bash.
NON BLOQUANT

##### Lentille : verification-gap

- **lens** : verification-gap
- **location** : `_bmad-output/implementation-artifacts/0-9-shared-sprint-reading-and-script-tests.md`
- **trigger_condition** : Le SHA de résolution (D4, D7, P1) n'est pas encore consigné dans la check-list, mais l'auteur a formellement explicité le recul intentionnel du statut de la story à `review` via un commit correctif.
- **guard_snippet** : S'assurer que ce SHA soit bien ajouté lors du prochain commit qui actera le passage effectif de la story à `done`.
- **potential_consequence** : La traçabilité sera validée au moment opportun (le passage effectif à done). Le processus est intact et respecte la règle rigoureuse du commit de statut unique pour l'achèvement.
NON BLOQUANT

##### Couche propre au projet

- **location** : Critères d'acceptation et architecture
- **trigger_condition** : Les critères d'acceptation de la story 0.9 (lecture de sprint sans dépendre de `jq`, tests bash rejouables hors ligne, absence d'appels à la forge dans les bibliothèques d'évaluation) sont tous respectés, et les modifications de variables pallient exactement le défaut mentionné dans la PR sans vider l'intention initiale.
- **guard_snippet** : Aucun.
- **potential_consequence** : L'implémentation adhère strictement à `AGENTS.md` et aux décisions d'architecture (AD-24).
NON BLOQUANT

- **location** : Fuite de données et sécurité
- **trigger_condition** : L'analyse complète des scripts bash modifiés, des historiques de tests ajoutés et des fichiers de fixtures JSON montre une étanchéité parfaite vis-à-vis des données privées.
- **guard_snippet** : Aucun.
- **potential_consequence** : Aucune donnée privée, aucun secret, ni aucun nom de domaine spécifique à la forge n'est exposé. Le dépôt public reste sain.
NON BLOQUANT

- **location** : Cohérence procédure / script
- **trigger_condition** : Le fichier de documentation `docs/procedures/shell-scripts.md` mentionne très précisément les cas d'utilisation de `scripts/tests/run.sh` et les méthodes de gestion d'erreur (pièges connus), en parfaite concordance avec la logique réellement déployée dans les scripts.
- **guard_snippet** : Aucun.
- **potential_consequence** : Les procédures documentées sont fidèles à l'implémentation effective.
NON BLOQUANT

- **location** : Gestion des erreurs (`set -euo pipefail`)
- **trigger_condition** : Tous les `grep -vE ... || true` et potentielles évaluations qui masquaient l'échec ont été remplacés par la récupération fine des codes (ex. `rc=$?` puis `((rc <= 1))`), différenciant clairement l'absence de correspondance (code 1) d'une erreur fatale (code 2+).
- **guard_snippet** : Aucun.
- **potential_consequence** : Absolument aucune erreur inattendue de pipeline bash ne peut désormais être ignorée silencieusement. L'intégrité de l'exécution est garantie.
NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur, suite :

- Défaut trouvé par l'audit réel de la PR n° 14 sur le premier commit `done` (`6804098`), après la revue `pass` de `e1f847a` : `status_commit_ok` déclarait en `local` deux noms que `verify-and-merge-pr.sh` déclare en `readonly` (`local: status_file: readonly variable`), et utilisait alors les valeurs du script au lieu de ses arguments. Corrigé (`2eb0672`) sur décision d'Arnaud : variables préfixées `rule_status_file` et `rule_stories_dir` ; cas de test qui déclare ces noms en `readonly`, vérifié en échec sur l'ancienne bibliothèque puis réussi sur la nouvelle. La story est repassée à `review` et l'epic 0 à `in-progress` dans ce commit, pour que le présent commit de statut respecte la règle.
- `2eb0672` (pass) : aucun constat nouveau.

Preuves mises à jour sur la tête `2eb0672` : `scripts/tests/run.sh`, 35 cas réussis sur le poste et 35 cas dans `alpine:3.24` ; P1 fermé aussi par `2eb0672`.

## Reporté

- D6 (codes de sortie hétérogènes) : hors périmètre, décision d'Arnaud à la rétrospective de l'epic 0.
- Lancement de `scripts/tests/run.sh` par le job de contrôle partagé et présence de `git` et `jq` dans `CHECK_IMAGE` : story 3.12.
