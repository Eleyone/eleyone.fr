# Story 3.13 : Checks workflow on main forge

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.13.

## Revue de spec

### 19/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `4f3c2fb`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9394321e29b14ee385d6303f

Ce document existe pour aider un développeur (ou un agent) à implémenter le workflow de CI sur la forge principale Gitea (story 3.13), en définissant les prérequis, les actions manuelles et les critères d'acceptation attendus.
Modèle de structure retenu : **Prompt/Task Definition (Functional)**.

##### Lens : adversarial

**1. Location** : Critères d'acceptation
**Trigger Condition** : Le chemin exact de `checks-job.sh` n'est pas spécifié.
**Guard Snippet** : Remplacer par `scripts/ci/checks-job.sh`.
**Potential Consequence** : Le développeur pourrait créer un nouveau script à la racine ou chercher le fichier au mauvais endroit, provoquant un échec ou une duplication.

**2. Location** : Critères d'acceptation
**Trigger Condition** : La méthode d'exécution du script shell n'est pas précisée.
**Guard Snippet** : Préciser l'exécution explicite (ex. via `run: bash scripts/ci/checks-job.sh`).
**Potential Consequence** : Échec de l'exécution dans le runner si le script perd ses droits d'exécution (`+x`) ou si le shell par défaut du runner n'est pas compatible avec la syntaxe attendue.

**3. Location** : Critères d'acceptation
**Trigger Condition** : L'épinglage par SHA de l'action de checkout n'est pas exigé.
**Guard Snippet** : Ajouter "l'action de checkout épinglée par SHA, comme exigé par AD-11".
**Potential Consequence** : Risque de sécurité par compromission de la chaîne logistique : AD-11 cite cette sécurité pour GitHub, elle est tout aussi vitale pour Gitea.

**4. Location** : Opération manuelle (Arnaud)
**Trigger Condition** : L'ajout de la vérification de statut obligatoire (status check) aux protections de branches n'est pas demandé.
**Guard Snippet** : Ajouter à l'opération manuelle : "Ajouter le statut de ce workflow comme contrôle obligatoire pour `dev` et `main`."
**Potential Consequence** : La CI tournera à chaque PR, mais rien n'empêchera techniquement de fusionner une PR avec une CI rouge, annulant l'intérêt du verrou.

**5. Location** : Critères d'acceptation (test d'échec)
**Trigger Condition** : Le test d'échec ne valide que la vérification de parité (C3), ignorant le garde-fou (C1).
**Guard Snippet** : Ajouter "et une modification introduisant un motif privé (C1) échouent".
**Potential Consequence** : Un dysfonctionnement du garde-fou dans l'environnement du runner (ex. absence d'accès au fichier de motifs) pourrait passer inaperçu, exposant des données privées sur le miroir (FR-28).

**6. Location** : Critères d'acceptation
**Trigger Condition** : Le nommage du job n'est pas imposé.
**Guard Snippet** : Préciser le nom du job (ex: `checks`) pour la configuration de la protection de branche.
**Potential Consequence** : Sans nom prévisible, il sera difficile pour Arnaud de configurer le nom exact de la vérification obligatoire dans les paramètres Gitea.

**7. Location** : Questions à poser avant de commencer
**Trigger Condition** : L'action tierce exacte à utiliser sur Gitea pour le checkout n'est pas précisée (usage de `actions/checkout` via GitHub ou autre).
**Guard Snippet** : Ajouter : "Quelle action (et quel SHA exact) de checkout utiliser sur Gitea ?"
**Potential Consequence** : Perte de temps, ou intégration par le développeur d'une action de checkout tierce non approuvée.

**8. Location** : Critères d'acceptation (règle des déclencheurs)
**Trigger Condition** : Le critère "chaque événement lance exactement un run" est ambigu pour une PR issue de `dev` vers `main`.
**Guard Snippet** : Préciser "les PR depuis `feat/*` vers `dev` ne déclenchent qu'un run".
**Potential Consequence** : Confusion lors des tests de validation ; par exemple, un push sur `dev` dans le cadre d'une PR vers `main` déclencherait à la fois l'événement `push` et `pull_request`, créant deux runs et faisant échouer le critère sans raison.

**9. Location** : Opération manuelle
**Trigger Condition** : Les prérequis de droits Docker pour l'utilisateur du runner Gitea sont trop vagues.
**Guard Snippet** : Préciser "dont l'utilisateur accède au démon Docker sans `sudo`".
**Potential Consequence** : Le workflow échouera dès le lancement de `docker run` par `checks-job.sh` (mentionné dans AD-11) en raison d'une permission refusée.

**10. Location** : Critères d'acceptation
**Trigger Condition** : L'absence de mention du workflow pour GitHub pourrait induire le développeur en erreur, croyant devoir tout traiter.
**Guard Snippet** : Préciser "(la CI pour le miroir GitHub relève d'une story distincte)".
**Potential Consequence** : Le développeur pourrait créer le workflow `.github/workflows/checks.yaml` de son propre chef pour satisfaire sa lecture d'AD-11, dépassant ainsi le périmètre de la story actuelle.


##### Lens : structure & prose

| Pass | Original Text | Revised Text | Changes |
|------|---------------|--------------|---------|
| structure | `Opération manuelle (Arnaud)` : (toute la ligne) | PRESERVE, mais ajouter explicitement l'action de protection des branches. | L'exécution manuelle est essentielle (modèle *Functional* respecté), mais il manque l'activation administrative du verrou de CI sur la forge. |
| prose | ...l'appel de `checks-job.sh`... | ...l'appel de `scripts/ci/checks-job.sh` avec `bash`... | Complète le chemin et l'exécutable pour lever toute ambiguïté technique. |
| prose | ...une PR qui retire une rubrique EN du pilote échoue et nomme le fichier. | ...une PR qui retire une rubrique EN du cas pilote 02 échoue et nomme le fichier. | Précision de la référence (le cas "pilote" seul force l'inférence, alors qu'il s'agit du 02). |

**Résumé de la passe éditoriale :** 3 recommandations. Aucun impact significatif sur la longueur (quelques mots ajoutés). Le niveau de compréhension, la précision et la testabilité sont renforcés pour garantir que la tâche technique soit claire et exhaustive.

---

##### À trancher avant d'implémenter
- **Action de checkout :** Quelle action de checkout tierce officielle (et quel SHA exact) doit-on utiliser sur Gitea ?
- **Protection de branche :** Dois-je inclure explicitement dans tes opérations manuelles l'ajout du job (par ex. `checks`) comme condition obligatoire pour fusionner sur `dev` et `main` ?
- **Périmètre du test d'échec :** Le test de validation en PR doit-il s'assurer que le garde-fou bloque bien la CI si un motif privé fuit, en plus de vérifier le test de parité ?
- **Nommage du job :** Quel nom de job exact (ex: `checks`) faut-il fixer dans le YAML pour faciliter ta configuration côté Gitea ?

### Triage (19/09/2026)

**Retenu — chemin et lancement du script.** Le critère nomme désormais `scripts/ci/checks-job.sh`, lancé par `bash` : un bit d'exécution perdu ne doit pas faire échouer la CI.

**Retenu — action de checkout épinglée par SHA, source comprise.** AD-11 n'exige l'épinglage que sur GitHub ; il vaut autant ici. Le `uses` porte une **URL absolue** : elle fixe à la fois la source et le commit, et ne dépend pas du réglage `DEFAULT_ACTIONS_URL` de la forge. Version retenue : `v4.4.0` (`11d5960a326750d5838078e36cf38b85af677262`, `gitea.com/actions/checkout`), parce qu'elle tourne sur node 20 ; `v5` et au-delà demandent node 24, que le runner en mode hôte devrait fournir lui-même.

**Retenu — nom du job.** Le job s'appelle `checks` : c'est ce nom qu'Arnaud désignera dans les protections de branche, et que le verrou « CI verte » cherchera (story 3.16).

**Retenu — protection de branche.** Un workflow qui tourne sans être exigé ne verrouille rien. L'opération manuelle gagne l'ajout du statut `checks` comme contrôle obligatoire sur `dev` et sur `main`, **après** la première exécution verte : Gitea ne propose un statut dans cette liste qu'une fois qu'il a été rapporté au moins une fois.

**Retenu — accès au démon Docker sans `sudo`, et `node` sur la machine.** Le premier parce que `checks-job.sh` lance `docker run` ; le second parce qu'en mode hôte, c'est le node de la machine qui exécute les actions JavaScript, celle du checkout comprise.

**Retenu — un seul run par événement, dit précisément.** Une PR de `feat/*` vers `dev` ne déclenche que `pull_request` (le `push` n'écoute que `dev` et `main`) ; sa fusion déclenche un `push` sur `dev`. Le critère le dit ainsi, plutôt que « chaque événement lance exactement un run », qui se lisait mal pour une PR `dev` → `main`, où les deux déclencheurs jouent légitimement.

**Retenu — le workflow de GitHub est hors périmètre**, il relève de la story 3.14. Écrit dans la story.

**Refusé — éprouver aussi C1 par une PR qui fait fuir un motif privé.** Un tel commit ne peut pas arriver sur la forge : le hook `pre-receive` le refuse au push, et c'est précisément pourquoi il est l'autorité (AD-12). Le mode `history` en CI est un second filet, en chemins seulement ; il est déjà éprouvé par les tests hors ligne du garde-fou et par ceux du job (story 3.12). Un essai « pour voir » consisterait à retirer le hook de la forge, ce qui coûterait plus que ce qu'il prouverait.

### Réponses d'Arnaud (19/09/2026)

- **Label du runner** : `linux_amd64:host`, l'exemple de l'architecture et la convention de la documentation Gitea ; le suffixe dit de lui-même que le job ne tourne pas dans un conteneur, donc qu'il peut lancer Docker.
- **Ordre** : le runner est déclaré maintenant, avant la fusion de cette story, puisque le verrou « CI verte » passe de `absent` à bloquant dès que `.gitea/workflows/checks.yaml` est sur `dev`.

## Ce qui est livré

- `.gitea/workflows/checks.yaml` — déclencheurs (`push` sur `dev` et `main`, `pull_request`), checkout `fetch-depth: 0`, et `bash scripts/ci/checks-job.sh`. Rien d'autre : le job s'appelle `checks`, tourne sur le label `linux_amd64` et n'embarque aucune logique de contrôle.
- `docs/procedures/gitea-actions.md` — le mode hôte et pourquoi il est imposé, le label déclaré côté runner (`linux_amd64:host`) dont `runs-on` ne porte que le nom, les prérequis de la machine, l'épinglage du checkout, les deux dossiers de workflows, la protection de branche et le tableau des déclencheurs.
- `scripts/tests/test-workflows.sh` — 5 cas qui gardent la règle « rien que le déclencheur, le checkout et l'appel du script » : une seule commande `run`, l'action désignée par une URL absolue épinglée par SHA et suivie de son commentaire de version.

### Le runner existait déjà

La première interrogation de la forge n'a regardé que les runners du **dépôt** et du **compte**, tous deux vides, et j'en ai conclu à tort qu'il n'y en avait aucun. Arnaud l'a corrigé : deux runners sont en ligne au niveau de l'**instance** (`/api/v1/admin/actions/runners`). Ce qui manquait n'était donc pas un runner, mais un label en mode hôte, ajouté aux deux sur sa décision (19/09/2026). Le piège est noté dans la procédure : chercher au mauvais niveau fait conclure à l'absence.

### Un correctif de la story 3.12, nommé

Dans le conteneur, `scripts/build.sh` place `.tools/` en tête du `PATH` s'il existe : le dépôt monté porte celui du poste, et le job employait ses binaires au lieu de ceux qu'il venait d'installer dans l'image. Les deux sont épinglés à la même version, donc rien n'a divergé, mais l'image doit tourner avec **ses** outils. `TOOLS_LOCAL_DIR` désigne dans le conteneur un dossier inexistant, comme `ENV_FILE` déjà. Un cas de test le garde.

### Essais

- `scripts/ci/checks-job.sh` : code 0, 272 cas de test et les 5 contrôles, avec les outils de l'image.
- La vérification en conditions réelles — un run par événement, et un run rouge sur une PR qui retire une rubrique EN — se lit sur cette PR même, une fois le label posé sur les runners.


### Ce que la première exécution en CI a appris (19/09/2026)

Le run a démarré, le checkout a réussi, le conteneur de contrôle a vu le **vrai** dépôt — et la suite de tests a échoué sur trois cas. Aucun n'était un défaut de l'infrastructure.

**Trois pièges, dont deux dans mes propres affirmations :**

1. **Le mode d'un label est invisible depuis l'administration de Gitea.** J'ai lu `["docker","linux","x64","ubuntu-latest","self-hosted"]` et j'en ai conclu que les runners étaient en mode conteneur. Gitea ne stocke que les **noms** : les cinq labels étaient déjà en `:host` depuis le début. Le diagnostic du poste d'Arnaud l'a établi en lisant les fichiers `.runner`.
2. **Un runner conteneurisé n'est pas la machine.** Les deux runners tournent eux-mêmes dans des conteneurs : le « mode hôte » y désignait l'intérieur de leur conteneur, dont l'espace de travail vit sous `/tmp` — chemin absent de la machine. Le `docker run -v "$PWD"` du job aurait monté un dossier vide, et **les contrôles seraient passés au vert sans rien lire**. Corrigé par `host.workdir_parent` pointé sur un dossier monté au même chemin des deux côtés. La preuve se lit pendant un run : le dossier de travail existe sur la machine.
3. **Trois cas de test supposaient de ne pas être `root`.** En CI, le job tourne en `root`, qui lit tout fichier quelles que soient ses permissions : un `chmod 000` suivi de « ceci doit être une anomalie » constate l'inverse. Deux autres cas, plus anciens, avaient déjà une parade — écrite à la main, et **silencieuse**.

**Ce que la parade devient.** `skip_case "<raison>"` (code 3) et `skip_if_root "<ce qui est rendu illisible>"` vivent dans `scripts/tests/lib.sh`, et `run.sh` compte les cas ignorés **en affichant leur raison** :

```
tests: 266 cas réussis, 6 ignorés :
  scripts/tests/test-budget.sh : budget_fichier_illisible_est_une_anomalie — root lit la page malgré ses permissions
  …
```

La couverture peut donc différer d'un environnement à l'autre, mais plus jamais en silence. Le contrat lui-même — code 1 de `xmllint` ou de `grep` = anomalie — reste vérifié sans permissions par `test-checks-lib.sh`, avec un faux binaire qui rend le code voulu.

**Ce qu'Arnaud a appliqué sur le homelab** (rapport de son agent, 19/09/2026) : `runner.labels` complété des six entrées dans le `config.yaml` partagé — la clé l'emporte bien sur `.runner` en 0.2.10 —, `host.workdir_parent` créé, le dossier de travail monté au même chemin des deux côtés, et `bash` ajouté à l'image du runner, qui ne l'avait pas.

## Revue du code

### 19/09/2026 — `4fc7ede` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 49. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ca747da20359787bf0520f98

##### Revue BMAD

###### Lentille : verification-gap

- **Location** : `scripts/tests/test-workflows.sh` (`case_workflow_gitea_appelle_le_job_partage`)
  **Trigger condition** : Le test vérifie la déclaration du label `linux_amd64` et la commande lancée, mais omet de vérifier le nom du job (`checks:`), pourtant explicitement exigé par les critères d'acceptation ("dans un job nommé checks").
  **Guard snippet** : Ajouter une assertion vérifiant le nom, par exemple : `assert_contains "checks:" "$contenu"`.
  **Potential consequence** : Un développeur pourrait renommer le job par mégarde, ce qui passerait la CI au vert mais briserait le verrou des branches de la forge, ce dernier attendant un statut qui s'appelle strictement `checks`.
  NON BLOQUANT

- **Location** : `scripts/tests/test-workflows.sh` (`case_workflow_gitea_action_epinglee`)
  **Trigger condition** : Le test valide que l'action `uses` utilise une URL absolue (`https://`) avec un SHA en suffixe, mais il ne valide pas *quelle* action est appelée (`gitea.com/actions/checkout`).
  **Guard snippet** : Ajouter une assertion stricte sur le domaine et le chemin : `assert_contains "https://gitea.com/actions/checkout@" "$ligne"`.
  **Potential consequence** : Une action tierce non officielle (ex: `https://github.com/malicious/action@...`) pourrait être utilisée : le test passerait tant que la syntaxe absolue et le SHA sont respectés, créant une vulnérabilité.
  NON BLOQUANT

###### Lentille : edge-case-hunter

- **Location** : `scripts/tests/test-workflows.sh` (`case_workflow_gitea_une_seule_commande` et `case_workflow_gitea_action_epinglee`)
  **Trigger condition** : En cas de disparition du déclencheur ou du mot-clé `uses` dans le YAML, la substitution `uses=$(grep ...)` (ou `commandes=...`) retournera un code d'erreur 1. Sous `set -euo pipefail`, le script plantera immédiatement sans jamais atteindre les blocs prévus (`[[ -n $uses ]] || { echo ... }`).
  **Guard snippet** : Insérer une tolérance pour la liste vide, par exemple : `uses=$(grep -E '^\s*- uses:' "$gitea_workflow" || true) | sed ...`.
  **Potential consequence** : L'échec de la CI sera bien effectif et bloquant, mais le harnais crashera sans afficher le message d'erreur d'assertion que le développeur avait pris soin de rédiger.
  NON BLOQUANT

##### Couche propre au projet

- **Location** : `.gitea/workflows/checks.yaml` et implémentation générale de la story 3.13
  **Trigger condition** : Les critères d'acceptation (déclencheurs limités, checkout complet et épinglé, nom du job, appel du script avec bash, paramètres du conteneur) sont formellement satisfaits dans le code et les scripts de tests.
  **Guard snippet** : N/A
  **Potential consequence** : L'intention fonctionnelle est conservée et implémentée sans être altérée.
  NON BLOQUANT

- **Location** : Ensemble du correctif (patch)
  **Trigger condition** : L'adresse privée de la forge, d'éventuels secrets ou des données privées n'apparaissent nulle part (seule l'URL publique `gitea.com` est utilisée).
  **Guard snippet** : N/A
  **Potential consequence** : Aucun risque de fuite de sécurité ou d'identité protégée sur le miroir GitHub. Le garde-fou fonctionne comme prévu.
  NON BLOQUANT

- **Location** : Fichiers `docs/procedures/gitea-actions.md` et `docs/procedures/checks-job.md`
  **Trigger condition** : Les procédures documentent exhaustivement les prérequis manuels du runner hôte et de l'environnement, en parfaite concordance avec le correctif appliqué au conteneur (`TOOLS_LOCAL_DIR`).
  **Guard snippet** : N/A
  **Potential consequence** : Maintien de l'harmonie entre le code exécuté (script), l'intention fonctionnelle (skill/story) et sa trace opérationnelle (procédure).
  NON BLOQUANT

- **Location** : Scripts shell modifiés
  **Trigger condition** : L'utilisation de `local var` suivie sur une autre ligne de `var=$(...)` est correctement appliquée, évitant le masquage de code d'erreur (qui surviendrait si on écrivait `local var=$(...)`).
  **Guard snippet** : N/A
  **Potential consequence** : Aucune erreur d'exécution bash n'est passée sous silence sous `set -euo pipefail`, préservant la stabilité du pipeline.
  NON BLOQUANT

VERDICT: NON BLOQUANT — Les critères sont satisfaits et l'implémentation est sûre. Seuls quelques trous de vérification dans les assertions des tests peuvent être renforcés (nom du job, vérification stricte de l'URL de l'action de checkout) pour anticiper d'éventuelles régressions.

#### Décisions sur ces constats (19/09/2026)

Les trois sont retenus et corrigés dans `scripts/tests/test-workflows.sh` :

1. **Le nom du job est vérifié** (`checks`) : c'est le nom du statut que les protections de branche et le verrou « CI verte » cherchent ; le renommer passerait la CI au vert en cassant le verrou.
2. **La source de l'action est vérifiée**, pas seulement sa forme : une URL absolue épinglée par SHA vers n'importe quel dépôt passait. Le cas exige `https://gitea.com/actions/`.
3. **`grep` ne tue plus le harnais** : une fonction commune distingue « rien trouvé » (code 1, liste vide, le cas dit alors ce qui manque) d'une vraie erreur (code 2 et plus), comme `checks_grep` le fait pour les contrôles.

### 19/09/2026 — `b69a9c9` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 49. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 139687edfb77af0fbe8f73ec

##### BMad Review

###### Edge-Case Lens
Aucun cas aux limites non géré n'a été trouvé.

###### Verification-Gap Lens
- **location**: `.gitea/workflows/checks.yaml:18-22`
  **trigger_condition**: Le test valide la présence des déclencheurs attendus, mais pas l'absence d'autres événements non autorisés.
  **guard_snippet**: `assert_eq "push pull_request" "$(grep -E '^\s*([a-z_]+):' $gitea_workflow | tr -d ' :')"`
  **potential_consequence**: L'ajout d'un événement abusif (comme `release` ou `schedule`) sous `on:` passerait inaperçu.
  **gap_shape**: `regression-gap`
  **consumer**: `scripts/tests/test-workflows.sh:case_workflow_gitea_declencheurs`
  **evidence**: Le test utilise uniquement des instructions `assert_contains` qui ne garantissent pas l'exhaustivité stricte des clés.

- **location**: `.gitea/workflows/checks.yaml:23-25`
  **trigger_condition**: Le test vérifie que le job `checks` est déclaré, mais pas qu'il est le seul job du workflow.
  **guard_snippet**: `assert_eq "checks" "$(grep -E '^  [a-z_-]+:' $gitea_workflow | tr -d ' :')"`
  **potential_consequence**: Un second job non désiré inséré dans le fichier ne ferait pas échouer la CI.
  **gap_shape**: `regression-gap`
  **consumer**: `scripts/tests/test-workflows.sh:case_workflow_gitea_appelle_le_job_partage`
  **evidence**: Le code se contente d'un `assert_contains "  checks:" "$contenu"`, ignorant l'éventuelle présence d'autres nœuds de jobs.

- **location**: `scripts/ci/checks-job-container.sh:33-35`
  **trigger_condition**: La variable `TOOLS_LOCAL_DIR` est testée uniquement via sa présence textuelle dans le fichier source.
  **guard_snippet**: Une exécution vérifiant concrètement l'environnement, ou une assertion stricte confirmant qu'elle n'est assignée qu'une fois.
  **potential_consequence**: Une redéfinition malheureuse de la variable plus bas dans le script laisserait ce test au vert.
  **gap_shape**: `broken-verification-gap`
  **consumer**: `scripts/tests/test-checks-job.sh:case_checks_job_conteneur_ignore_les_outils_du_poste`
  **evidence**: L'utilisation de `assert_contains "TOOLS_LOCAL_DIR=/nonexistent/.tools" "$contenu"` sur le texte ne protège pas contre un écrasement ultérieur dans le même script.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont intégralement satisfaits et l'intention respectée (le workflow délègue toute logique au script partagé et lance un seul job sur un runner hôte sans imbrication Docker).
- NON BLOQUANT : Aucune donnée privée, aucune adresse de serveur interne ni aucun secret n'est exposé. L'URL `gitea.com` appelée est publique.
- NON BLOQUANT : Le skill, la procédure et les scripts concordent parfaitement ; `docs/procedures/gitea-actions.md` clarifie judicieusement la limite d'usage de la syntaxe `runs-on` par rapport au vrai nom du label.
- NON BLOQUANT : Le changement est en adéquation avec les décisions d'architecture (AD-11) et avec les règles de `AGENTS.md`.
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne peut passer sous silence avec `set -euo pipefail`. La substitution `sortie=$(grep ...) || rc=$?` utilisée dans les assertions protège l'exécution de tout arrêt inopiné en traitant le code de sortie 1 proprement.

VERDICT: NON BLOQUANT — Les implémentations sont rigoureuses et sûres, avec pour seule réserve quelques trous dans les harnais de tests statiques qui pourraient vérifier plus formellement l'absence d'éléments intrus dans le YAML.

### 19/09/2026 — `86f1ba2` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 49. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9767902e2cf3bd3c5e269d2e

##### Lentille : edge-case-hunter

- **location** : `scripts/tests/run.sh:55` (Extraction de la raison d'ignorance)
  **trigger_condition** : Le pipeline `sed -n 's/^IGNORÉ : //p' "$logs/sortie" | head -n 1` est fonctionnel, mais `sed` parcourt potentiellement tout le fichier de log si aucune occurrence n'est trouvée (ou jusqu'à ce que `head` coupe la sortie si une occurrence est trouvée). Ce comportement n'échouera pas mais est sous-optimal.
  **guard_snippet** : Utiliser `sed -n '/^IGNORÉ : /{s/^IGNORÉ : //p;q}' "$logs/sortie"` pour s'arrêter immédiatement après avoir trouvé et traité la première ligne.
  **potential_consequence** : Lenteur marginale si les fichiers de sortie des tests deviennent très volumineux, bien que négligeable en pratique ici.
  NON BLOQUANT

##### Lentille : verification-gap

- **location** : `.gitea/workflows/checks.yaml:26-34`
  **trigger_condition** : L'appel au script de vérification se fait simplement avec `run: bash scripts/ci/checks-job.sh`. Bien que Gitea Actions échoue si le script retourne un code non nul (comportement par défaut des actions), il n'y a pas de vérification préalable explicite de la disponibilité des prérequis (ex. le démon Docker) avant de lancer le script complet. 
  **guard_snippet** : N/A (le script `checks-job.sh` est lui-même conçu pour valider l'environnement, l'approche retenue est donc correcte pour éviter de dupliquer la logique dans le YAML).
  **potential_consequence** : L'échec éventuel lié à l'environnement se produira à l'intérieur du script `checks-job.sh` plutôt que de bloquer immédiatement au niveau du YAML, ce qui reste conforme à la volonté de centraliser la logique hors du workflow.
  NON BLOQUANT

##### Couche propre au projet

- **location** : Critères d'acceptation de la story 3.13
  **trigger_condition** : Les critères imposent un workflow sur un runner hôte, n'écoutant que certains événements (`push` sur `dev`/`main` et `pull_request`), sans logique métier, et pointant vers une action de checkout épinglée par SHA absolu. L'implémentation satisfait chacune de ces règles formelles.
  **guard_snippet** : N/A
  **potential_consequence** : L'intention fonctionnelle et de sécurité de la story est intégralement respectée.
  NON BLOQUANT

- **location** : Données privées, secrets et adresses
  **trigger_condition** : Le patch ne contient aucune donnée de `docs/private/`, aucun jeton codé en dur, ni aucune URL de serveur local (l'action pointe vers l'URL publique `gitea.com`). Les scripts modifiés n'exposent aucune variable sensible.
  **guard_snippet** : N/A
  **potential_consequence** : Aucune fuite d'information ne viendra compromettre le miroir public. Le niveau de confidentialité est maintenu.
  NON BLOQUANT

- **location** : Concordance skill, procédure et script
  **trigger_condition** : La nouvelle procédure `docs/procedures/gitea-actions.md` décrit avec une grande clarté le fonctionnement de Gitea vis-à-vis des labels hôtes (`runs-on: linux_amd64` configuré dans le YAML sans le suffixe `:host`). L'export manuel `TOOLS_LOCAL_DIR=/nonexistent/.tools` dans `scripts/ci/checks-job-container.sh` correspond précisément à l'explication donnée dans `docs/procedures/checks-job.md`.
  **guard_snippet** : N/A
  **potential_consequence** : Alignement strict entre le comportement réel des scripts et la documentation opérationnelle.
  NON BLOQUANT

- **location** : Cohérence avec AGENTS.md et décisions d'architecture
  **trigger_condition** : L'utilisation d'un label hôte et de chemins relatifs isolés, ainsi que la configuration exclusive de la branche de travail et des tags dans un flux de branche linéaire respectent le PRD (AD-11).
  **guard_snippet** : N/A
  **potential_consequence** : Le projet poursuit son évolution de façon cohérente vis-à-vis des décisions architecturales actées.
  NON BLOQUANT

- **location** : Scripts shell et silence des erreurs sous `set -euo pipefail`
  **trigger_condition** : L'ajout de la fonction `skip_if_root` s'appuie sur une évaluation protégée `[[ $(id -u) != 0 ]] || skip_case ...` et l'interception du code 3 dans `run.sh` s'effectue sans violer le mode strict (l'exécution `rc=$?` protège le lanceur principal).
  **guard_snippet** : N/A
  **potential_consequence** : Les harnais de test demeurent inflexibles ; aucune erreur bash ne peut se dissimuler.
  NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

#### Décision sur ce constat (19/09/2026)

**Refusé — `sed … | head -n 1` remplacé par `sed -n '/…/{s///p;q}'`.** Le fichier lu est la sortie d'un **seul** cas de test ignoré, soit une ligne. Le gain est nul, et le motif proposé est moins lisible que l'idiome employé partout ailleurs dans le dépôt. Une optimisation qui ne se mesure pas ne vaut pas une ligne moins claire.

### Vérification en conditions réelles (19/09/2026)

Faite sur la PR elle-même, une fois le homelab réglé :

- **run 1885, vert** sur `86f1ba2` : un run `pull_request` et un seul, le déclencheur `push` n'écoutant que `dev` et `main` ;
- **run 1886, rouge** sur un commit d'essai qui renomme la rubrique `What pushed back` du cas pilote 02 en `Resistance`. Les deux contrôles concernés nomment le fichier :

  ```
  content/cases/chiliz/case-02-chiliz.en.md: C4 : rubrique « Resistance » absente de data/rubrics.yaml
  content/cases/chiliz/case-02-chiliz.en.md: rubrique 4 : « Resistance » en anglais, « What pushed back » attendu…
  check: 2 contrôle(s) en échec sur 5 : content parity
  ```

  Le commit d'essai a été retiré de la branche aussitôt le run rouge constaté ; la branche est revenue à `86f1ba2`.
- Le checkout a réussi sans histoire de version de node : l'action `v4` a tourné sur le node 24 du runner.

## Reporté
