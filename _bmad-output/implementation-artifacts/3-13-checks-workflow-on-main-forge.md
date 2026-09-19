# Story 3.13 : Checks workflow on main forge

Status: in-progress

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

## Revue du code

## Reporté
