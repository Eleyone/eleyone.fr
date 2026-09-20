# Story 3.16 : Green CI gate in verify-and-merge-pr

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.16.

## Revue de spec

### 20/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `b82780b`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0cc62b15fe4aa91909444ade

##### Rapport de revue de spécification (BMAD)

###### Lentille : Adversarial (Edge-cases et failles de logique)

- **Emplacement :** Critères d'acceptation 1 et 2
  **Déclencheur :** Le comportement n'est décrit que sous la condition « Quand on lance `verify-and-merge-pr --merge` ».
  **Fix proposé :** Couvrir explicitement le fonctionnement en mode audit (sans `--merge`), qui doit nommer et afficher l'état du run Gitea sans tenter de fusion.
  **Conséquence :** Le développeur pourrait conditionner la vérification de la CI à la présence du flag `--merge`, rendant la commande d'audit aveugle à l'état réel de la CI.

- **Emplacement :** Critères d'acceptation 1 et 3
  **Déclencheur :** L'état « absent » est déclaré bloquant de façon inconditionnelle dans l'AC1, ce qui contredit l'AC3 et la règle d'amorçage (qui tolère l'absence si `.gitea/workflows/checks.yaml` n'existe pas sur la base).
  **Fix proposé :** Préciser dans l'AC1 que l'état « absent » bloque la fusion *uniquement* si `checks.yaml` est présent sur la base.
  **Conséquence :** Le script refusera à tort des fusions légitimes sur des branches historiques ou d'amorçage où la CI n'a pas encore été configurée.

- **Emplacement :** Critère d'acceptation 3
  **Déclencheur :** La vérification de la présence de `.gitea/workflows/checks.yaml` sur « la base de la PR » manque de précision technique.
  **Fix proposé :** Indiquer si le script doit vérifier cette présence via l'API Gitea ou via l'arbre Git local (`git ls-tree <base>`).
  **Conséquence :** Si le script vérifie l'arbre local, la PR qui introduit le fichier (présent localement mais pas sur la base) sera bloquée par erreur.

- **Emplacement :** Critère d'acceptation 1
  **Déclencheur :** Seuls les statuts « en échec », « en cours » ou « absent » sont listés pour le blocage. L'API Gitea connaît d'autres états (`cancelled`, `skipped`, `warning`).
  **Fix proposé :** Définir ces états explicitement comme bloquants, ou définir que *tout état différent de success* est bloquant.
  **Conséquence :** Une CI annulée ou sautée pourrait être ignorée et autoriser une fusion dangereuse.

- **Emplacement :** Critère d'acceptation 1
  **Déclencheur :** Le nom du run est mentionné comme `checks`, mais l'API peut renvoyer les statuts de plusieurs workflows parallèles (ex: `parity-agent.yaml`, présent dans AD-11).
  **Fix proposé :** Exiger que le script filtre spécifiquement le contexte/nom du workflow `checks` pour évaluer le verrou.
  **Conséquence :** Un statut « vert » provenant d'un workflow secondaire masquerait l'échec du workflow principal, autorisant la fusion de code cassé.

- **Emplacement :** Ensemble du document
  **Déclencheur :** Aucune gestion des erreurs n'est spécifiée pour les appels à l'API Gitea (timeout, erreur réseau, jeton expiré).
  **Fix proposé :** Ajouter un critère : « En cas d'erreur de l'API lors de la récupération du statut, l'audit échoue et la fusion est refusée. »
  **Conséquence :** Une erreur réseau pourrait être interprétée silencieusement comme un état « absent » autorisé (si mal implémenté) ou faire planter le script sans message clair.

- **Emplacement :** Ensemble du document
  **Déclencheur :** Le comportement du verrou CI n'est pas croisé avec l'« exception documentaire » (règle 3 des stories) implantée précédemment.
  **Fix proposé :** Ajouter un critère confirmant que le verrou CI s'applique (ou comment il interagit) même lorsque l'exception documentaire est active.
  **Conséquence :** Risque de régression complexe si la logique du script entremêle mal l'exception documentaire et l'exigence de CI.

- **Emplacement :** Critère d'acceptation 1
  **Déclencheur :** L'expression « absent pour le SHA de tête » présume que le statut récupéré appartient formellement au SHA de la PR.
  **Fix proposé :** Confirmer que l'API est interrogée spécifiquement avec le SHA de tête exact récupéré depuis la forge, pour contrer les éventuels délais de propagation.
  **Conséquence :** Un statut périmé (vert sur l'avant-dernier commit) autoriserait la fusion d'un dernier commit cassé.

- **Emplacement :** Ensemble du document
  **Déclencheur :** Le statut de la CI sur GitHub (miroir) est ignoré.
  **Fix proposé :** Mentionner explicitement que seule la CI Gitea fait autorité pour le verrou.
  **Conséquence :** Ambiguïté pour le développeur qui pourrait chercher à fédérer ou attendre les résultats de la CI GitHub.

- **Emplacement :** Ligne 29
  **Déclencheur :** La mise à jour de la documentation est demandée pour l'état « absent », mais pas la mise à jour des messages de la console.
  **Fix proposé :** Exiger que le terminal différencie clairement un état `absent` (bloquant car CI attendue) d'un état `absent` (autorisé par la règle d'amorçage).
  **Conséquence :** Frustration et confusion de l'utilisateur face à un verrou affiché « absent » sans contexte.

###### Lentille : Structure (Organisation et flux)

- **Emplacement :** Critères d'acceptation 1 et 3
  **Déclencheur :** La logique du statut « absent » est fragmentée sur deux critères éloignés.
  **Fix proposé :** Regrouper sous un seul arbre de décision le comportement face à l'absence de CI (selon l'existence de `checks.yaml`), pour en faire une exigence unitaire.
  **Conséquence :** Implémentation redondante ou contradictoire dans le script shell.

- **Emplacement :** Section Critères d'acceptation
  **Déclencheur :** Aucune séparation entre l'étape de contrôle (audit) et l'étape d'exécution (fusion).
  **Fix proposé :** Regrouper les cas sous « Comportement en mode audit » puis « Comportement avec `--merge` ».
  **Conséquence :** Logique spaghetti dans le script final rendant l'ajout de futurs verrous complexe.

###### Lentille : Prose (Clarté et ambiguïté)

- **Emplacement :** Ligne 7
  **Déclencheur :** Formulation narrative « afin que le verrou signalé "absent" depuis la story 0.7 devienne réel ».
  **Fix proposé :** Recentrer sur le but métier : « afin d'empêcher l'intégration de code défaillant en vérifiant le succès de la CI. »
  **Conséquence :** Perte de clarté sur l'objectif fondamental de sécurité du processus.

- **Emplacement :** Ligne 29
  **Déclencheur :** Tournure négative complexe « ne décrit plus l'état absent qu'au titre de... ».
  **Fix proposé :** Reformuler en positif : « précise que l'état absent est désormais bloquant, sauf pour la règle d'amorçage. »
  **Conséquence :** Ralentissement de la compréhension lors de la rédaction de la documentation.

---

##### À trancher avant d'implémenter

1. **Périmètre du mode Audit :** Le comportement du script doit-il vérifier et nommer l'état de la CI même lorsqu'il est appelé sans le paramètre `--merge` ?
2. **Identification formelle du workflow :** Faut-il explicitement filtrer les statuts de Gitea pour s'assurer que c'est bien le run `checks` qui est évalué, afin de ne pas valider la PR sur le succès d'un autre workflow parallèle ?
3. **Statuts Gitea non listés :** Les statuts tels que `cancelled`, `skipped` ou `warning` doivent-ils être explicitement définis comme bloquants ?
4. **Vérification de la base :** Pour la règle d'amorçage, la présence de `.gitea/workflows/checks.yaml` sur la branche de base doit-elle être constatée via l'API Gitea ou via l'arbre Git local ?

### Triage (20/09/2026)

**Retenu, et c'est le constat qui valait la revue — le verrou doit nommer le workflow.** Il lit aujourd'hui l'état **combiné** de tous les statuts du commit. Tant qu'un seul workflow en pose, cela revient au même ; ce ne sera plus vrai à la story de l'agent de parité (AD-16), qui **commente sans bloquer** : son statut entrerait dans l'état combiné et verrouillerait la fusion, exactement ce qu'AD-16 refuse. Le verrou ne regarde donc plus que les statuts du workflow `checks`.

Deux détails de l'API, constatés sur un vrai commit plutôt que supposés : le contexte d'un statut s'écrit `checks / checks (push)`, soit `<workflow> / <job> (<événement>)`, et la clé de l'état d'un statut est `status`, non `state` — `state` n'existe qu'au niveau combiné. Un filtre écrit de mémoire serait tombé à côté.

**Retenu — les états inconnus bloquent, et le disent.** `pending` garde son message « en cours » ; tout ce qui n'est pas `success` bloque en nommant l'état lu, `cancelled`, `skipped` ou `warning` compris. Aucun état n'est traité par omission.

**Refusé, parce que déjà vrai — le SHA interrogé.** Le script lit l'état du **SHA de tête rendu par la forge**, jamais d'un commit local : un statut vert sur l'avant-dernier commit ne peut pas passer pour celui de la tête.

**Refusé, parce que déjà vrai — la présence du workflow sur la base.** Le relecteur se demandait s'il fallait l'API ou l'arbre local. Le script lance d'abord `git fetch origin <base> <branche>`, puis lit le fichier à `refs/remotes/origin/<base>` : c'est l'arbre local, mais rafraîchi depuis la forge à la seconde. Un clone périmé ne peut donc pas désactiver le verrou en silence. Ce point est écrit dans la procédure, puisqu'il se pose naturellement.

**Refusé, parce que déjà vrai — le comportement en mode audit.** Le verrou est évalué et affiché que `--merge` soit passé ou non : c'est le même chemin de code, et l'audit sert précisément à voir les verrous avant de fusionner.

**Retenu — les deux états « absent » doivent se distinguer à l'écran.** Ils le font déjà dans le texte du message, mais la story ne l'exigeait pas ; elle le dit désormais, et un cas de test le garde : `absent de la base : règle d'amorçage` d'un côté, `existe sur la base : CI absente sur la tête` de l'autre.

**Refusé — la CI de GitHub ne compte pas.** Le miroir est public et peut être en retard d'une synchronisation ; la forge principale fait foi, et elle seule. La story le dit maintenant, pour qu'on ne cherche pas à fédérer les deux.

**Retenu — l'exception documentaire et la CI ne se confondent pas.** Une PR qui ne touche que `_bmad-output/` est dispensée de **revue**, jamais de CI : la CI tourne sur toutes les PR et son échec bloque. Écrit dans la story et dans la procédure.

**Retenu — la formulation.** L'intention de la story était écrite en termes de mécanique (« le verrou signalé absent devient réel ») plutôt que de finalité. Elle dit maintenant ce qu'elle empêche.

## Ce qui est livré

- `scripts/lib/merge-gates.sh` — `ci_gate` ne lit plus l'état combiné, mais les statuts du workflow **`checks`** : tous verts passent, un `pending` bloque en disant « en cours », tout autre état bloque en se nommant. Sans aucun statut `checks`, il bloque si le workflow est sur la base, et rend « amorçage » sinon.
- `scripts/tests/test-merge-gates.sh` — les cas de CI sont réécrits sur la **vraie forme** de la réponse de la forge (`statuses[].status`, contexte `<workflow> / <job> (<événement>)`), et trois cas nouveaux : un autre workflow en échec ne bloque pas, un autre workflow vert ne remplace pas `checks`, et un workflow dont le nom commence par `checks` sans être lui ne compte pas.
- `docs/procedures/verify-and-merge-pr.md` — le verrou y est décrit tel qu'il est, l'amorçage n'y figure plus que comme le régime révolu qu'il est, et deux points qui se posent naturellement y sont écrits : la base est lue après un `fetch`, et l'exception documentaire ne dispense jamais de CI.

### Ce que la story a vraiment changé

Le comportement attendu par les trois critères était déjà en place depuis la story 3.13 : `absent` bloque, `pending` bloque, vert passe. Ce que cette story corrige est ailleurs, et la revue de spec l'a trouvé : **le verrou jugeait l'état combiné de tous les statuts du commit**. Tant qu'un seul workflow en pose, cela revient au même ; ce ne l'est plus à la story de l'agent de parité, qui commente sans bloquer (AD-16) et dont le statut aurait verrouillé les fusions.

Deux détails de l'API ont été constatés sur un vrai commit plutôt que supposés : l'état d'un statut vit sous `status`, pas sous `state`, et le contexte s'écrit `checks / checks (push)`. Un filtre écrit de mémoire serait tombé à côté, et les tests l'auraient confirmé — ils employaient une réponse inventée, sans tableau `statuses`.

### Essais

- `scripts/tests/run.sh` : 290 cas réussis.
- Cette PR est sa propre démonstration : son verrou CI est passé de « en cours » à « verte sur la tête » sous le nouveau code.

## Revue du code

### 20/09/2026 — `f6fcf57` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 52. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 125fe2db13116c89f1298bfc

##### Rapport de revue BMAD

###### Lentille : Edge-case-hunter
- NON BLOQUANT : **Condition de déclenchement :** Le commit possède plusieurs jobs pour le workflow `checks` qui génèrent des statuts terminés distincts au même instant (par exemple, un job en `success` et un autre en `failure`). **Conséquence potentielle :** Le script bloquera la fusion de façon sécurisée (ce qui est l'essentiel), mais affichera un message brut juxtaposant littéralement les états récupérés (ex. `état success failure sur la tête.`) au lieu d'un message synthétique d'échec. **Garde :** Ajouter une condition `[[ " $etats " == *" failure "* ]]` pour nommer explicitement un échec partiel, ou accepter ce comportement marginal.

###### Lentille : Verification-gap
- NON BLOQUANT : **Régression non couverte (Regression gap) :** La suite de tests `scripts/tests/test-merge-gates.sh` ne vérifie pas le comportement du verrou lorsqu'un workflow `checks` remonte simultanément un `success` et un `failure` (échec partiel d'un sous-job). **Conséquence :** Si une évolution future de l'expression régulière ou de la structure conditionnelle altère la gestion des statuts multiples mixtes, les tests actuels ne capteront pas cette régression. **Garde :** Ajouter un cas de test avec `ci_reponse "checks / job1=success" "checks / job2=failure"` pour s'assurer que le verrou continue de bloquer.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont entièrement satisfaits : le script cible exclusivement le workflow `checks` (isolant l'agent de parité), distingue correctement l'absence de statut d'un état d'amorçage, et vérifie de manière fiable les statuts sur le SHA de tête.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte, aucune adresse de serveur et aucun secret n'est commité ou exposé dans le code modifié ni dans les tests.
- NON BLOQUANT : L'implémentation, la procédure documentée et les modifications de script concordent parfaitement (les évolutions du verrou `ci_gate` sont fidèlement répercutées et justifiées dans `verify-and-merge-pr.md`).
- NON BLOQUANT : Le changement est rigoureusement cohérent avec les instructions générales du dépôt (`AGENTS.md`) et la philosophie de l'architecture statique basée sur des scripts shell simples et sans dépendances superflues.
- NON BLOQUANT : La sûreté d'exécution sous `set -euo pipefail` est respectée : le traitement du flux JSON par `jq` est proprement encapsulé avec une bascule `|| return 2` qui intercepte toute erreur (JSON invalide, objet inattendu) sans interruption silencieuse du script.

VERDICT: NON BLOQUANT — aucune

#### Décisions sur ces constats (20/09/2026)

Les deux sont retenus, et ils n'en font qu'un : avec deux jobs du même workflow, l'un vert et l'autre non, le message juxtaposait les états lus — « état success failure sur la tête ». Le verrou bloquait bien, mais mal dit. Il ne nomme désormais que les états **fautifs**, chacun une fois : « état failure sur la tête », ou « état failure cancelled » s'il y en a deux. Trois cas de test gardent ce comportement, dont celui que la revue signalait manquant.

### 20/09/2026 — `87b1206` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 52. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: fc2bb3b8c4c9d823a66bff44

##### Rapport de revue BMAD

###### Lentille : Edge-case-hunter
- NON BLOQUANT : L'API Gitea pagine les résultats au-delà d'une certaine limite, or le script ne lit ici que le premier tableau `statuses` renvoyé par le JSON. Si un grand nombre de statuts d'autres workflows submergeaient la première page, les statuts `checks` pourraient être évincés et déclencher un faux positif d'absence, bien que ce cas de figure soit très improbable vu l'échelle des workflows du projet.
- NON BLOQUANT : La boucle `for etat in $etats; do` utilise le découpage par mots du bash. Si la valeur de secours `"sans état"` est déclenchée, elle sera découpée en deux itérations (`"sans"` et `"état"`). Ces deux mots s'accumuleront dans `$fautifs` bloquant la fusion de manière sécurisée mais affichant un message de log cosmétiquement éclaté.

###### Lentille : Verification-gap
- NON BLOQUANT : L'utilisation de la valeur de repli `(.status // "sans état")` dans le flux `jq` pour traiter les données inattendues de Gitea n'a pas de couverture de test équivalente dans `test-merge-gates.sh`, ce qui masquerait une éventuelle régression liée à cette mécanique de sauvegarde.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (le ciblage exclusif et prioritaire du workflow `checks` est respecté).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent : la documentation a bien été révisée pour correspondre au nouveau comportement strict du verrou `absent` et de la lecture limitative du workflow.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (pas d'outil lourd introduit, pure logique shell statique).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail (les assignations `jq` sont suivies de `|| return 2` et la gestion des chaînes non encadrées sert ici spécifiquement l'itération sans provoquer de rupture).

VERDICT: NON BLOQUANT — aucune

#### Décisions sur ces constats (20/09/2026, troisième passe)

- **Retenus, corrigés** : la valeur de repli d'un statut sans état s'écrivait en deux mots, que la boucle des états fautifs aurait comptés pour deux ; elle s'écrit désormais `sans-état`, et un cas de test la rejoue.
- **Accepté sans changement — la pagination des statuts.** L'appel lit l'**état combiné** du commit, qui ne rend que le dernier statut de chaque contexte : un par job, et le projet en compte deux workflows au plus. Surtout, le défaut supposé échoue du bon côté : des statuts `checks` évincés donneraient « aucun statut », donc un **blocage**, jamais une fusion indue. Ajouter une pagination pour un cas qui ne peut que trop bloquer coûterait plus qu'il ne protège.

### 20/09/2026 — `8876052` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 52. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 4ce242294bfc64df57bfc940

##### Rapport de revue de code (BMAD & Projet)

###### Lentille : Edge-case-hunter
- NON BLOQUANT : **Condition de déclenchement :** La boucle `for etat in $etats; do` s'appuie sur le découpage par mots (word splitting) de bash sur une variable non protégée par des guillemets. Bien que voulu pour itérer sur la liste des statuts, cela laisse aussi passer le *globbing* (développement des chemins). **Conséquence :** Si, par suite d'une anomalie de l'API Gitea, le champ retourné contenait un astérisque `*` ou un `?`, Bash le remplacerait par la liste des fichiers du répertoire courant. La fusion serait correctement refusée (sécurité métier respectée), mais le terminal afficherait ces fichiers dans le motif de refus au lieu de l'état réel.
- NON BLOQUANT : **Condition de déclenchement :** L'API renvoie un type inattendu pour le champ `.status` (par exemple un objet ou un tableau imbriqué au lieu d'une chaîne). **Conséquence :** La fonction `join(" ")` de `jq` échouera. Cependant, grâce à la construction stricte de l'assignation `etats=$(jq -er ...) || return 2`, le script interceptera l'erreur technique de `jq` et refusera la fusion en toute sécurité, sans laisser passer le plantage en silence.

###### Lentille : Verification-gap
- NON BLOQUANT : **Régression non couverte :** Le script de test valide correctement le comportement du code face à un tableau vide de statuts (`{"statuses": []}` généré par `ci_reponse` sans argument). Néanmoins, il ne couvre pas explicitement le cas où la clé `statuses` est *totalement absente* de l'objet JSON racine. L'implémentation est robuste face à ce manque grâce à l'expression de repli `(.statuses // [])`, mais l'absence de test spécifique pourrait laisser passer une future modification qui casserait cette sécurité.

##### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont intégralement satisfaits : l'évaluation cible correctement et de manière exclusive le workflow `checks` sur la tête, fait correctement la distinction avec l'agent de parité qui ne bloque plus, et gère proprement l'affichage séparé entre état d'amorçage et réelle absence de CI.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ou de serveur, ni aucun secret n'est commité dans ces modifications ; la lecture s'effectue sur les variables d'environnement gérées par le proxy existant, sans exposition.
- NON BLOQUANT : La cohérence entre script, procédure et tests est parfaite. La mise à jour de la documentation `verify-and-merge-pr.md` reflète rigoureusement le nouveau comportement en vigueur codé dans `merge-gates.sh` et les tests ajoutés s'alignent avec précision sur ce qui est décrit.
- NON BLOQUANT : Les choix opérés respectent à la lettre `AGENTS.md` et les décisions d'architecture (AD) : aucune dépendance logicielle supplémentaire n'a été ajoutée, et l'exigence d'un script Bash lisible et autonome est maintenue. L'exception documentaire qui n'exempte pas de CI est par ailleurs strictement codifiée.
- NON BLOQUANT : En vertu de `set -euo pipefail`, la robustesse du script est assurée. Aucun échec de parsing JSON, aucune chaîne vide inattendue ou variable non initialisée ne sera passée sous silence ; toute erreur arrête l'exécution et met en échec le script, bloquant de facto la PR.

VERDICT: NON BLOQUANT — aucune

## Reporté
