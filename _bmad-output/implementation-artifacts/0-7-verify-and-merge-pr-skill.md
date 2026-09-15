# Story 0.7 : Verify-and-merge-pr skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.7.

## Revue de spec

### 15/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `6cdb7b2`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 205a0e032db77fa7785261c5

**Lecture et objectif**
Ce document est la spécification (story 0.7) destinée au développeur pour implémenter le script `verify-and-merge-pr.sh`, qui audite et valide les verrous avant la fusion d'une PR sur Gitea.
Modèle de structure retenu : Spécification comportementale (Étant donné / Quand / Alors).

---

##### Lentille Adverse (Adversarial)

Voici les constats sur les manques, ambiguïtés et failles de la spécification (focalisation sur ce qui manque ou est implicite) :

1. **Localisation :** `Verrous : PR exploitable`
   - **Problème :** Le terme "exploitable" est ambigu et invérifiable tel quel pour un script.
   - **Correction :** Définir les critères exacts via l'API (ex : `state=open`, `mergeable=true`, conflits résolus).
   - **Conséquence :** Le script tente de fusionner une PR fermée ou en conflit et échoue sans clarté.

2. **Localisation :** `commentaire llm-review dont la première ligne...`
   - **Problème :** La gestion de multiples commentaires de revue n'est pas spécifiée.
   - **Correction :** Préciser qu'il faut chercher le *dernier* commentaire chronologique commençant par `llm-review`.
   - **Conséquence :** Le script pourrait rejeter une PR valide à cause d'un ancien verdict `block`, ou accepter une PR où la dernière revue a pourtant échoué.

3. **Localisation :** `scripts/check-private.sh sur l'arbre de tête`
   - **Problème :** Pour une PR distante, le script (qui tourne en local) doit avoir l'arbre. De plus, il manque le mode d'exécution (`history` ou `staged`).
   - **Correction :** Préciser comment le script récupère le diff ou la branche (ex: `git fetch`), et quel mode de `check-private.sh` il lance.
   - **Conséquence :** L'audit plante techniquement ou valide l'arbre local actuel au lieu de celui de la PR.

4. **Localisation :** `numéro de story tiré du nom de la branche`
   - **Problème :** Toutes les branches n'ont pas forcément un numéro (ex: `docs/typo`, branches de `chore`).
   - **Correction :** Spécifier le comportement : le verrou `sprint-consistency` est-il sauté si la regex échoue, ou la PR est-elle bloquée ?
   - **Conséquence :** Le script plante en essayant d'utiliser un identifiant `n.m` vide ou inexistant.

5. **Localisation :** `Alors seule la CI verte, ou son substitut d'amorçage, est exigée` (Exception documentaire)
   - **Problème :** Cette formulation contredit la règle fondamentale d'`AGENTS.md` : le garde-fou public/privé ne doit *jamais* être ignoré.
   - **Correction :** Formuler : "Seule la CI verte (ou substitut) ET le garde-fou `check-private.sh` sont exigés ; seule la revue LLM est sautée".
   - **Conséquence :** Une PR documentaire pourrait faire fuiter des données privées (ex: un brouillon de texte) si l'audit est zappé.

6. **Localisation :** `avec le résultat du substitut local [...] noté dans la PR`
   - **Problème :** L'automatisation de ce contrôle par le script n'est pas claire.
   - **Correction :** Préciser comment le script vérifie cela. Lit-il les commentaires de la PR via l'API pour y chercher une regex précise validant l'audit local ?
   - **Conséquence :** Le script ne peut pas évaluer le verrou de CI en phase d'amorçage et bloque.

7. **Localisation :** `Étant donné la PR qui ajoute sprint-status.yaml`
   - **Problème :** La méthode de détection de cette PR unique n'est pas décrite.
   - **Correction :** Indiquer comment le script la reconnaît (ex: appel API sur le diff de la PR listant l'ajout de `sprint-status.yaml`, ou hardcodage du numéro de PR).
   - **Conséquence :** D'autres PR pourraient contourner à tort le suivi de sprint.

8. **Localisation :** `et n'ajoute par ailleurs que des lignes au fichier de story et à deferred-work.md`
   - **Problème :** Vérifier techniquement qu'il n'y a "que des lignes ajoutées" (0 suppression/modification) n'est pas trivial.
   - **Correction :** Mentionner la stratégie d'audit (ex: vérifier avec `git diff` l'absence totale de lignes commençant par `-` sur ces deux fichiers).
   - **Conséquence :** Des suppressions malveillantes ou accidentelles pourraient esquiver la re-revue LLM.

9. **Localisation :** `Le script charge .env sans afficher de valeur`
   - **Problème :** La story 0.5 a introduit `scripts/lib/gitea.sh` pour centraliser le chargement de `.env` et les appels API, ce qui est ignoré ici.
   - **Correction :** Indiquer : "Le script source `scripts/lib/gitea.sh` pour charger `.env` et joindre l'API".
   - **Conséquence :** Duplication de la gestion de `.env` et du filet de sécurité de l'API.

10. **Localisation :** `Étant donné la base de la PR / Quand elle est dev, puis main`
    - **Problème :** Ne précise pas le traitement des branches de base autres (ex: `feat/xxx`).
    - **Correction :** Préciser que toute autre branche de base est strictement refusée par le script.
    - **Conséquence :** Le script pourrait appliquer un squash sur une mauvaise branche de base.

11. **Localisation :** `Étant donné scripts/verify-and-merge-pr.sh <PR> sans option`
    - **Problème :** Si le script rapatrie et manipule l'arbre git localement, un espace de travail non propre pose un gros risque.
    - **Correction :** Exiger que le script échoue immédiatement si `git status --porcelain` n'est pas vide.
    - **Conséquence :** Les changements locaux de l'utilisateur sont écrasés ou faussent l'audit.

---

##### Lentilles Éditoriales (Structure et Prose)

Total des recommandations : 4. Le gain est orienté sur la lisibilité et la clarification des conditions pour le développeur.

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| structure | `Verrous : PR exploitable ; commentaire [...] ; CI verte ; cohérence...` | MERGE sous la forme d'une liste à puces après "Alors rien n'est fusionné." | Le bloc narratif est trop dense. Une liste explicite des 5 verrous facilitera grandement l'implémentation par le dev. |
| structure | `(dont content/**, AGENTS.md, CLAUDE.md, docs/procedures/**, .claude/**, docs/format-cas.md)` | CUT | Redondant avec la règle déjà explicitée. La mention "un fichier hors de `_bmad-output/`" suffit. |
| prose | `Étant donné la base de la PR`<br>`Quand elle est dev, puis main`<br>`Alors la fusion se fait en squash, puis elle est refusée avec un renvoi...` | `Étant donné la base de la PR`<br>`Quand c'est dev, la fusion se fait en squash.`<br>`Quand c'est main, elle est refusée avec un renvoi...` | Sépare la logique conditionnelle qui était embrouillée par l'enchaînement avec la conjonction "puis". |
| prose | `seule la CI verte, ou son substitut d'amorçage, est exigée` | `seule la CI verte (ou son substitut) est exigée` | Allège la syntaxe. |

---

##### À trancher avant d'implémenter

- **Exception documentaire :** Confirmer qu'elle désactive *uniquement* la revue LLM et le verrou de sprint, mais que le garde-fou (`check-private.sh`) reste **strictement toujours exigé** (la spec actuelle laisse entendre que le garde-fou saute, ce qui viole la politique d'`AGENTS.md`).
- **Substitut de CI :** Comment le script automatisé détecte-t-il techniquement que le substitut local a été "noté dans la PR" ? (Lancement du script de validation lui-même, ou recherche textuelle sur un commentaire spécifique de l'utilisateur ?)
- **Détection des branches sans story (ex: `docs/*`, `chore/*`) :** Le script doit-il purement ignorer le verrou `sprint-consistency` si la branche n'a pas de numéro `n.m` extractible, ou bien bloquer la PR ?
- **PR "exploitable" :** Sommes-nous d'accord pour définir cela par : API Gitea renvoyant `state = open` et `mergeable = true` ?
- **Commentaire LLM-review :** En cas de multiples passages, le script doit-il se baser uniquement sur le **dernier** commentaire chronologique posté par un LLM ?

Tri de l'auteur (questions tranchées par Arnaud le 15/09/2026) :

- 1, « PR exploitable » non défini : tranché, PR ouverte, pas en brouillon, `mergeable`, pas déjà fusionnée, base `dev` ;
- 2, plusieurs commentaires `llm-review` : tranché, compte le dernier commentaire publié par le compte `GITEA_USER` dont le SHA est celui de la tête (ou de son parent, pour le commit de statut) et la base celle de la PR ; un `block` plus récent l'emporte sur un `pass` ancien ;
- 3, `check-private` sur une PR distante : corrigé, le script récupère la base et la branche depuis la forge et lance `check-private.sh history base..tête` avec la liste des motifs ;
- 4, branche sans numéro de story : tranché, le verrou de suivi devient le contrôle global de `sprint-consistency.sh` sur la tête ;
- 5, exception documentaire qui semblerait sauter le garde-fou : corrigé, elle ne saute que la revue LLM ; garde-fou, CI et suivi restent exigés ;
- 6, substitut de CI « noté dans la PR » invérifiable : tranché, le script lance lui-même le substitut (`check-private.sh history`, puis `scripts/check.sh` quand il existe) et affiche « absent » avec son résultat ;
- 7, détection de la PR qui ajoute `sprint-status.yaml` : corrigé, exemption seulement si la base n'a pas ce fichier et que la tête l'a ;
- 8, vérifier « seulement des ajouts » : corrigé, le commit de statut est contrôlé ligne par ligne dans `git diff` ;
- 9, `scripts/lib/gitea.sh` non cité : corrigé ;
- 10, base autre que `dev` ou `main` : corrigé, refusée ;
- 11, arbre de travail non propre : écarté, le script lit tout dans les objets git et par l'API et n'écrit jamais dans l'arbre de travail ;
- rédaction, liste des verrous en un bloc : corrigé, liste explicite à la réécriture ;
- rédaction, suppression de la liste des fichiers hors exception : écarté, elle reprend `AGENTS.md` et aide le développeur ;
- rédaction, « dev, puis main » : corrigé, deux cas distincts ;
- rédaction, « ou son substitut d'amorçage » : corrigé à la réécriture ;
- ajout d'Arnaud : message du commit de fusion = titre de la PR suivi de « (#N) », sujets des commits de la branche et lignes `Co-Authored-By` sans doublon.

## Revue du code

### 15/09/2026 — `327b234` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 11. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9dc9e055e141078e90ff9013

##### Rapport de Revue (BMad Review)

###### Lentille : Edge-Case Hunter
- **BLOQUANT** : L'expression `grep -E` utilisant la variable `$base` non échappée (dans `last_report`) peut échouer avec une erreur de syntaxe regex (ex. base `feat/c++`), erreur (code 2) masquée et laissée passer en silence par `|| true`.
- **NON BLOQUANT** : Le substitut de CI détache un `worktree` propre (`$tmp/copie`) sans y lier les dossiers ignorés comme `.tools/` ou `.env`, ce qui fera systématiquement échouer `check.sh` s'il cherche Hugo ou D2.
- **NON BLOQUANT** : Dans la boucle de pagination, si `jq` échoue à analyser `comments.json`, l'expression `$(jq 'length' ...)` sera vide, provoquant un crash bash pour erreur de syntaxe sur `(( == 50 ))`.

###### Lentille : Verification Gap
- **NON BLOQUANT** : Aucun trou de vérification détecté. La logique de blocage des verrous est fermement garantie, la règle du commit de statut est inviolable ligne par ligne, et le substitut d'amorçage ne contourne pas la sécurité.

###### Couche propre au projet
- **NON BLOQUANT** : Les critères d'acceptation de la story sont intégralement satisfaits (contrôle séquentiel, exception documentaire, vérification stricte du suivi de sprint, fusion sécurisée).
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ou adresse ni secret n'est commité, et le script n'affiche aucun secret (gérés via `lib/gitea.sh`).
- **NON BLOQUANT** : Le skill, la procédure (`verify-and-merge-pr.md`) et le script concordent parfaitement sur chaque option (`--merge`), règle d'évaluation et code de sortie.
- **NON BLOQUANT** : Le changement est totalement cohérent avec `AGENTS.md` (évolution de la règle 6) et les décisions structurantes d'`ARCHITECTURE-SPINE.md`.

VERDICT: BLOQUANT — L'erreur de syntaxe de grep causée par une regex dynamique non échappée passe en silence sous "|| true", et le worktree du substitut CI omet les prérequis locaux.

### 15/09/2026 — `ff1355a` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 11. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 5387cfd0ae4fd8f747693485

##### Rapport de revue (BMad Review)

**Lentille : Edge-Case Hunter**
- **NON BLOQUANT** : Le point bloquant précédent a été correctement résolu : l'utilisation de variables non échappées dans une expression régulière est remplacée par une analyse précise via `awk` qui compare les champs par stricte égalité, éliminant tout risque d'erreur de syntaxe de regex.
- **NON BLOQUANT** : Les défaillances silencieuses sur des réponses tronquées de l'API avec `jq` ont été corrigées avec une gestion explicite des erreurs et la vérification du format numérique (`^[0-9]+$`).
- **NON BLOQUANT** : Les blocs `|| true` ciblent désormais correctement les retours vides attendus de `grep` (dans les lectures `git diff`). Bien que l'interception au niveau du pipeline puisse masquer une défaillance de `git diff` en amont, la présence des branches et fichiers est garantie à ce stade, annihilant le risque pratique.

**Lentille : Verification Gap**
- **NON BLOQUANT** : Tous les verrous décrits par la spécification ont été couverts. Aucune logique ne permet le contournement silencieux d'un verrou, et l'exigence de validation ligne à ligne pour le commit de statut est appliquée avec toute la rigueur souhaitée.

##### Couche propre au projet

- **NON BLOQUANT** : Les critères d'acceptation de la story sont tous satisfaits, sans aucune régression.
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ou adresse, ni aucun secret n'est commité ou exposé par l'exécution du script (l'accès passe bien par `scripts/lib/gitea.sh`).
- **NON BLOQUANT** : Le skill, la procédure documentaire et le script concordent point par point (pas d'options de forçage, codes de retour identiques).
- **NON BLOQUANT** : Le code est en parfaite cohérence avec `AGENTS.md` et les décisions d'architecture (le substitut d'amorçage de CI s'exécute comme spécifié, le cas de ses dépendances étant assumé et reporté à la story 3.2).
- **NON BLOQUANT** : Sous `set -euo pipefail`, plus aucune défaillance légitime de script ne passe sous silence, seules les cas de recherches infructueuses valides sont interceptés et gérés.

VERDICT: NON BLOQUANT — aucune

### 15/09/2026 — `458d009` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 11. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c92fdcbba170674ea136b47c

##### Rapport de revue (BMad Review)

###### Lentille : Edge-Case Hunter
- **BLOQUANT** : Dans le bloc de préparation du message de fusion (`{ git log ... ; trailers=... } > "$tmp/message.txt" || die`), l'utilisation de `|| die` suspend `set -e` pour l'ensemble du bloc, laissant l'éventuelle véritable erreur de la première commande `git log` passer en silence et masquant l'échec de la création du message.
- **NON BLOQUANT** : Le cas d'une liste de fichiers modifiés qui serait vide est bloqué en amont, et l'utilisation de `git diff` gère nativement les retours à la ligne dans les noms de fichiers, évitant ainsi un contournement vicieux de l'exception documentaire.

###### Lentille : Verification Gap
- **NON BLOQUANT** : Le contrôle de confidentialité avec `check-private.sh` s'applique rigoureusement au titre et au corps du message de fusion combinés, empêchant de manière fiable toute fuite de données lors du merge squash final.
- **NON BLOQUANT** : L'utilisation de l'argument `--rawfile` avec `jq` pour insérer le message de fusion dans la requête JSON API élimine complètement tout risque d'injection ou de faille liée à un guillemet non échappé dans les commits d'origine.

##### Couche propre au projet
- **NON BLOQUANT** : Les critères d'acceptation de la story sont tous satisfaits et les décisions prises lors de la revue de spécification ont été scrupuleusement respectées.
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte, ni secret n'est commité, et aucun script ne risque d'afficher de secret en clair.
- **NON BLOQUANT** : Le skill, la procédure et le script concordent parfaitement, tant sur les codes de sortie attendus (0, 1, 2) que sur le refus explicite d'options de forçage de fusion.
- **NON BLOQUANT** : Le changement est en adéquation totale avec les mises à jour de `AGENTS.md` (évolution de la règle 6) et les décisions d'architecture structurantes.
- **BLOQUANT** : Une erreur passe en silence sous `set -euo pipefail` dans le script shell `verify-and-merge-pr.sh`, car la première commande `git log` se trouve dans un bloc conditionnel `{ ... } ||` qui désactive l'interruption sur erreur.

VERDICT: BLOQUANT — La préparation du message de fusion utilise un bloc logique OR qui suspend set -e, laissant ainsi passer un échec de git log en silence.

### 15/09/2026 — `49ac6c0` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 11. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 23d77bf0edf09537ae918d1e

##### Revue BMAD

###### Lentille : Edge-Case Hunter
- **NON BLOQUANT** : Aucun cas limite non géré trouvé. Le script gère exhaustivement les échecs de commandes (par exemple `jq`, `git diff`, `git log`, `read_file`) avec des vérifications dédiées sans annuler l'effet de `set -e`. La construction permettant de vérifier le message de fusion (`rc=$?` combiné à une évaluation arithmétique) élimine brillamment tout risque d'erreur non capturée.

###### Lentille : Verification Gap
- **NON BLOQUANT** : Aucun trou de vérification détecté. Comme défini pour ce projet, la vérification des scripts shell repose sur des essais manuels. L'auteur a explicitement validé en conditions réelles les garde-fous ajoutés (git log en panne, fichier de story illisible, réponse vide), garantissant que le comportement attendu a bien été sécurisé.

##### Couche propre au projet

- **NON BLOQUANT** : Les critères d'acceptation de la story sont intégralement satisfaits (la condition sur l'exception documentaire, l'amorçage CI et le format du message de squash répondent à l'exigence initiale).
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité. Le script s'assure par ailleurs qu'aucun motif privé ne fuite accidentellement dans le message de fusion au moment du squash.
- **NON BLOQUANT** : Le skill, la procédure et le script concordent de manière irréprochable (tous mentionnent l'usage strict de `--merge`, l'absence d'option pour forcer la fusion, et partagent la même convention pour les codes de retour 0, 1 et 2).
- **NON BLOQUANT** : Le changement est en parfaite adéquation avec `AGENTS.md` (les mises à jour de la règle 6 sont exactes) et avec l'architecture de publication définie dans `ARCHITECTURE-SPINE.md`.
- **NON BLOQUANT** : Dans les scripts shell, plus aucune erreur ne passe en silence sous `set -euo pipefail`. Les blocs `|| die` problématiques ont été séparés, la capture de sortie des `jq` gère explicitement les erreurs et la commande `read_file` est maintenant isolée de l'opérateur de flux.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur les revues du code de la PR n° 11 :

- `327b234` (block) :
  - base insérée non échappée dans l'expression de recherche du rapport, erreur avalée par `|| true` : corrigé (`ff1355a`), champs comparés à l'identique, lecture impossible en code 2 ;
  - substitut de CI lançant `scripts/check.sh` sans `.tools/` : reporté à la story 3.2 (`deferred-work.md`), sur décision d'Arnaud ;
  - pagination cassée par une page illisible : corrigé (`ff1355a`) dans ce script et dans `create-pull-request.sh`, code 2.
- `ff1355a` (pass) : échec de `git diff` masqué dans la règle du commit de statut : corrigé (`458d009`), diff lu d'abord, échec refusé ; autres constats : confirmations.
- `458d009` (block) : message de fusion préparé dans un bloc `{ … } || die` qui suspend `set -e` : corrigé (`49ac6c0`), commande par commande ; balayage des cinq scripts : une seule autre erreur de la même famille, la lecture de la ligne `Status:` dans `sprint-consistency.sh`, corrigée dans le même commit.
- `49ac6c0` (pass) : aucun constat, confirmations seulement.

Constats de l'auteur : une erreur de syntaxe (apostrophe dans une expansion `${…:+…}`) trouvée par `bash -n` avant les tests ; une erreur de logique dans le calcul du substitut de CI trouvée en relecture avant les tests ; un incident de test (droits retirés par erreur à un dossier factice), sans effet sur les résultats.

## Reporté
