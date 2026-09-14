# Story 0.6 : Sprint-consistency skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.6.

## Revue de spec

### 14/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `c7376d9`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 32969152183dfaadcdbac379

##### Rapport de revue (bmad-review)

###### Lentille : Adversarial (Recherche de failles et cas limites)

*   **Oubli du modèle de skill**
    *   **Emplacement :** Critères d'acceptation
    *   **Problème :** La spec exige le développement de `scripts/sprint-consistency.sh` mais omet la création de `.claude/skills/sprint-consistency/SKILL.md`, des liens symboliques et de la procédure `docs/procedures/sprint-consistency.md`.
    *   **Conséquence :** Incohérence avec `AGENTS.md` (règle 7) et l'Epic 0 qui imposent le pattern à trois niveaux pour les skills de développement. Le skill ne sera pas documenté ni utilisable par les autres agents.
    *   **Correction suggérée :** Ajouter les critères d'acceptation pour la création et le contenu du `SKILL.md` et de la procédure.

*   **Identification de la story depuis la PR impossible**
    *   **Emplacement :** Critères d'acceptation, 3e scénario ("Étant donné la PR d'une story...")
    *   **Problème :** Le script doit vérifier que "la story" de la PR est à `done`. Aucune mécanique n'est définie pour extraire l'identifiant de la story concernée à partir de la PR.
    *   **Conséquence :** Le script ne saura pas quelle clé chercher dans `sprint-status.yaml` pour appliquer sa validation lors de la fusion.
    *   **Correction suggérée :** Définir explicitement si la clé de la story est lue depuis le préfixe de la branche (ex: `feat/0-6-...`) ou passée en argument.

*   **Absence d'interface d'exécution (CLI)**
    *   **Emplacement :** Critères d'acceptation (Scénarios 1 et 3)
    *   **Problème :** Le script a deux comportements : une validation globale de l'état (scénario 1) et une validation spécifique à une PR avant fusion (scénario 3).
    *   **Conséquence :** L'agent développeur devra deviner l'interface. Sans arguments bien définis, l'intégration future dans `verify-and-merge-pr` risque de casser.
    *   **Correction suggérée :** Définir les arguments du script (ex: aucune option pour la vérification globale, `--branch <nom>` pour vérifier le contexte d'une PR).

*   **Absence ou malformation de l'en-tête `Status:`**
    *   **Emplacement :** Scénario 1
    *   **Problème :** Que se passe-t-il si un fichier de story existe mais ne contient aucune ligne `Status:`, ou si la casse diffère (ex: `status: done`) ?
    *   **Conséquence :** Le script pourrait planter, l'ignorer silencieusement, ou renvoyer un faux positif.
    *   **Correction suggérée :** Spécifier que l'absence de l'en-tête est une erreur bloquante, et définir la tolérance syntaxique de la recherche (casse, espaces).

*   **Fichiers de story prématurés**
    *   **Emplacement :** Scénario 1 ("toute story présente d'un seul côté")
    *   **Problème :** Une story à l'état `backlog` dans le YAML n'exige pas de fichier. Mais que doit faire le script si un fichier Markdown existe *déjà* pour une story en `backlog` ?
    *   **Conséquence :** Le cas limite n'est pas couvert.
    *   **Correction suggérée :** Préciser si la présence anticipée d'un fichier pour une story en `backlog` est une erreur de cohérence ou si elle est tolérée.

*   **Cohérence du statut de l'Epic**
    *   **Emplacement :** Contexte général / `AGENTS.md`
    *   **Problème :** La règle 4 d'`AGENTS.md` précise que l'état de l'epic doit être mis à jour "when the story closes its epic". La spec ne dit pas si ce script valide le statut des epics.
    *   **Conséquence :** Les epics pourraient rester indéfiniment à `in-progress` dans le suivi sans déclencher d'erreur.
    *   **Correction suggérée :** Indiquer si la vérification des statuts des epics fait partie de la story 0.6 ou non.

###### Lentille : Structure (Organisation du document)

*   **Questions bloquantes non résolues**
    *   **Emplacement :** Section "Questions à poser avant de commencer"
    *   **Problème :** Les questions posées (méthode de lien PR-story, emplacement des fichiers) relèvent de la conception de base et conditionnent tout le code.
    *   **Conséquence :** L'implémentation est bloquée ou devra être improvisée si ces questions restent ouvertes.
    *   **Correction suggérée :** Ces choix doivent être tranchés par le mainteneur et réintégrés dans la liste des critères d'acceptation.

###### Lentille : Prose (Clarté et vocabulaire)

*   **Ambiguïté technique**
    *   **Emplacement :** Scénario 3
    *   **Problème :** L'expression "évalue la tête de la PR" manque de précision technique.
    *   **Correction suggérée :** Reformuler en décrivant l'action réelle du script. Par exemple : "Quand le script vérifie la cohérence sur le checkout local de la branche de la PR".

*   **Formulation alambiquée**
    *   **Emplacement :** Scénario 1
    *   **Problème :** "(une story hors backlog sans fichier de story, ou un fichier de story sans entrée dans le suivi)" alourdit inutilement le critère.
    *   **Correction suggérée :** Simplifier avec des termes directs : "toute story orpheline (fichier sans entrée YAML correspondante) ou non matérialisée (entrée YAML avec statut autre que 'backlog' sans fichier Markdown)".

##### À trancher avant d'implémenter

1. **Lien PR ↔ Story :** Comment le script déduit-il l'identifiant de la story à partir de la PR ? (Est-ce lu depuis le nom de la branche, ex: `feat/0-6-…`, par un argument passé au script, ou par le titre de la PR ?)
2. **Interface du script :** Quels sont les modes d'appel exacts pour distinguer la vérification globale de la vérification d'une PR précise ?
3. **Périmètre documentaire :** Confirmez-vous que les livrables documentaires (`SKILL.md` et `docs/procedures/sprint-consistency.md`) doivent être ajoutés aux critères d'acceptation de cette story pour se conformer au standard défini dans `AGENTS.md` ?
4. **Cas limites :** L'absence d'en-tête `Status:` dans un fichier de story existant doit-elle faire échouer le script ? Un fichier existant pour une story encore en `backlog` est-il une erreur ?
5. **Emplacement exact :** Confirmez-vous que les fichiers de story et `sprint-status.yaml` sont toujours situés dans `_bmad-output/implementation-artifacts/` ?

Tri de l'auteur (questions tranchées par Arnaud le 14/09/2026) :

- procédure, `SKILL.md` et liens absents de la spec : corrigé, ajoutés aux critères de la story ;
- lien entre une PR et sa story : tranché, il relève de `verify-and-merge-pr` (story 0.7), qui tire le numéro du nom de la branche ; ce script reçoit `--merge <n.m>` ;
- interface du script : tranché, contrôle global sans option, `--merge <n.m>` pour exiger la story à `done`, `--rev <commit>` pour lire un commit ;
- en-tête `Status:` absent ou mal formé : tranché, c'est un écart ; seule la première ligne `Status:` du fichier compte ;
- fichier présent pour une story en `backlog` : tranché, accepté s'il porte `Status: backlog` (la revue de spec crée ce fichier avant le premier commit) ;
- statut des epics : tranché, vérifié d'après ses stories (`backlog`, `in-progress` ou `done`) ; rétrospectives non vérifiées ;
- questions de conception laissées ouvertes dans la spec : corrigé, décisions intégrées à la story réécrite ;
- « évalue la tête de la PR » : corrigé, `--rev <commit>` lit le commit voulu ;
- formulation du critère 1 : corrigé à la réécriture ;
- emplacement des fichiers : confirmé, `_bmad-output/implementation-artifacts/`.

## Revue du code

### 14/09/2026 — `47a946d` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 10. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 05dcb471e324d22e794ec93f

##### Lentille : edge-case-hunter

- **location** : scripts/sprint-consistency.sh (lignes 434-439)
  **trigger_condition** : `find` échoue dans la fonction `list_names` à cause de l'option non portable `-printf` (absente sur macOS/BSD ou Alpine/Busybox) ou `git ls-tree` plante.
  **guard_snippet** : Utiliser `$(list_names)` plutôt que `< <(list_names)`, ou remplacer `find -printf` par une syntaxe plus portable si l'on sort de l'environnement GNU.
  **potential_consequence** : La commande crashe mais le script continue silencieusement, masquant d'éventuels fichiers orphelins.

- **location** : scripts/sprint-consistency.sh (lignes 458-464)
  **trigger_condition** : Il existe dans le suivi deux stories distinctes partageant le même préfixe (ex: `0-6-a` et `0-6-b`) lors d'un appel avec `--merge 0.6`.
  **guard_snippet** : S'assurer de l'unicité stricte de la correspondance ou déclencher une erreur en cas de correspondances multiples.
  **potential_consequence** : Le script écrase `merge_key` avec la dernière clé itérée aléatoirement, vérifiant ainsi la mauvaise story sans s'en rendre compte.

- **location** : scripts/sprint-consistency.sh (lignes 442-456)
  **trigger_condition** : Un epic est déclaré dans le fichier YAML mais n'a aucune story à son actif.
  **guard_snippet** : Traiter le cas `total == 0` spécifiquement, par exemple en exigeant le statut `backlog`.
  **potential_consequence** : Le script ignore cet epic via `((total > 0)) || continue`, lui permettant d'avoir un statut incorrect (`in-progress` ou `done`) sans lever d'écart.

##### Lentille : verification-gap

- **location** : scripts/sprint-consistency.sh (lignes 434-439)
  **trigger_condition** : L'utilisation de la process substitution `< <(list_names)` masque le code de retour de la fonction à l'environnement principal de bash.
  **guard_snippet** : Lire dans une variable `noms=$(list_names)` puis utiliser le here-string `<<< "$noms"` afin de laisser la substitution de commande déclencher le `set -e`.
  **potential_consequence** : Le bouclier de sécurité `set -euo pipefail` ne détecte pas l'échec interne, autorisant le script à afficher "0 écart" sur un système où `list_names` plante systématiquement.

##### Couche propre au projet

- **Critères d'acceptation** : Satisfaits. Les options sans argument (contrôle global), `--merge` et `--rev` sont fidèlement implémentées, validant les en-têtes et le suivi. Les codes de sortie sont stricts (0 pour cohérence, 1 pour écarts, 2 pour les erreurs fatales).
- **Données privées / Secrets** : Satisfait. Aucune donnée privée, nom d'hôte ni secret n'est lu, commité ou exposé par erreur.
- **Concordance documentation / code** : Satisfait. Le `SKILL.md` et `docs/procedures/sprint-consistency.md` correspondent scrupuleusement au code, aussi bien pour les arguments que pour les critères d'écart.
- **Cohérence architecture / AGENTS.md** : Satisfait. Le motif à trois couches pour l'implémentation est respecté, et le bash standard sans Python ni dépendance est bien utilisé. 
- **Erreurs silencieuses sous set -euo pipefail** : Non satisfait. Comme détaillé dans la lentille verification-gap, la process substitution laisse une erreur de liste de fichiers passer inaperçue.

##### Classement des constats

BLOQUANT : La substitution de processus `< <(list_names)` masque silencieusement l'échec de la fonction sous `set -euo pipefail`, violant les règles du projet sur la gestion des erreurs shell.
NON BLOQUANT : Utilisation de `find -printf` non portable (l'écosystème du projet étant basé sur Ubuntu/WSL, ce n'est pas bloquant en soi, mais rend le point précédent plus probable si exécuté ailleurs).
NON BLOQUANT : Le match de préfixe pour `--merge` pourrait entrer en collision, mais l'unicité de numérotation des stories le rend très théorique.
NON BLOQUANT : Les epics vides sautent la vérification de statut, ce qui est une tolérance acceptable.
NON BLOQUANT : Tous les autres critères du projet (acceptation, données privées, concordance doc/code, architecture) sont satisfaits.

VERDICT: BLOQUANT — Une erreur (échec de la fonction list_names) passe en silence sous set -euo pipefail en raison de l'utilisation d'une process substitution.

### 15/09/2026 — `ed7fccd` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 10. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 8a0ec2f15c625aa30e1c54a7

##### Rapport de revue (bmad-review)

###### Lentille : edge-case-hunter

- **location** : `scripts/sprint-consistency.sh` (boucle d'évaluation des epics, ligne 498)
- **trigger_condition** : Un epic est accidentellement absent du fichier YAML, mais les stories associées y sont bien présentes.
- **guard_snippet** : `for number in "${!epic_total[@]}"; do` (avec vérification de l'existence dans `epic_status`)
- **potential_consequence** : L'absence de l'epic dans le suivi n'est pas signalée comme un écart, la vérification ignorant les epics non listés.

###### Lentille : verification-gap

No verification gaps found. (Aucun écart de vérification identifié ; la régression signalée précédemment a bien été corrigée et aucune logique comportementale sans vérification manuelle n'a été ajoutée).

##### Couche propre au projet

- **Critères d'acceptation** : Satisfaits. Les options `--merge` et `--rev` fonctionnent comme exigé. La clé unique est bien contrôlée et les epics sans stories génèrent désormais correctement un écart. Les tolérances décrites dans la spécification sont respectées.
- **Données privées / Secrets** : Satisfait. Le code ne manipule ni n'expose aucune donnée privée, URL, adresse IP ou secret.
- **Concordance documentation / code** : Satisfait. Le skill (`.claude/skills/sprint-consistency/SKILL.md`), la procédure et l'interface réelle du script concordent scrupuleusement, tant pour les options que pour les définitions des écarts et des tolérances.
- **Cohérence architecture / AGENTS.md** : Satisfait. L'architecture à trois niveaux (skill, doc, script) est implémentée. Le script respecte les choix techniques du projet en n'utilisant que du bash standard (l'option GNU non portable `find -printf` a été supprimée, aucune dépendance à Python ou `jq` ajoutée).
- **Erreurs silencieuses sous set -euo pipefail** : Satisfait. L'utilisation de la substitution de commande `$(list_names)` au lieu de la substitution de processus (`< <(...)`) garantit que toute erreur lors du listage des fichiers fait bien échouer le script grâce à `set -e`.

##### Classement des constats

NON BLOQUANT : L'absence de signalement d'un epic manquant dans le fichier YAML alors que ses stories y sont présentes (edge-case-hunter) ne casse aucun critère ; la validation structurelle du fichier relève de l'outil de planification de BMAD.
NON BLOQUANT : Les critères d'acceptation de la story sont entièrement satisfaits.
NON BLOQUANT : Aucune donnée privée, adresse ou secret n'est mis en danger ou exposé.
NON BLOQUANT : La documentation, la procédure et l'exécution du script concordent parfaitement.
NON BLOQUANT : Le code respecte fidèlement les décisions d'architecture et les règles édictées dans `AGENTS.md`.
NON BLOQUANT : Plus aucune erreur ne passe sous silence grâce au respect de `set -euo pipefail` avec des mécanismes adéquats.

VERDICT: NON BLOQUANT — aucune

### 15/09/2026 — `65e2a33` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 10. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 32fb305bcd5d098e69148746

##### Rapport de revue (bmad-review)

###### Lentille : edge-case-hunter

- **location** : `scripts/sprint-consistency.sh` (lecture du YAML par `awk`, lignes 465-475)
  **trigger_condition** : Le fichier `sprint-status.yaml` est édité accidentellement à la main (malgré l'interdiction par la procédure) avec une indentation différente de 2 espaces (ex: 4 espaces) pour les éléments sous `development_status`.
  **guard_snippet** : Assouplir l'expression régulière dans `awk` pour tolérer une indentation variable : `inside && /^[[:space:]]+[^[:space:]#][^:]*:/` au lieu de `^  [^[:space:]#]`.
  **potential_consequence** : Les entrées ne sont pas identifiées par `awk`, la variable `entries` reste vide, et le script échoue en déclarant à tort que la section est vide.

- **location** : `scripts/sprint-consistency.sh` (fonction `list_names` en mode `--rev`, ligne 446)
  **trigger_condition** : Un sous-dossier finissant par `.md` est créé par erreur dans `_bmad-output/implementation-artifacts/` (ex: `0-6-brouillon.md/`).
  **guard_snippet** : S'assurer que le mode `--rev` ne liste que les fichiers réguliers (blobs), par exemple avec une vérification `git cat-file -t "$commit:$stories_dir/$f"`.
  **potential_consequence** : La commande `git ls-tree` liste le dossier, qui passe le filtre `sed`. Le script s'attend à un fichier et pourrait reporter des faux positifs ou échouer lors de la validation du statut, alors que le mode local sans `--rev` s'en prémunit correctement avec `[[ -f $f ]]`.

###### Lentille : verification-gap

- Aucun écart de vérification identifié. Toutes les commandes susceptibles d'échouer (`git rev-parse`, `awk`, etc.) sont capturées, vérifiées ou gérées avec `|| true` et ne laissent pas de comportement imprévu sous `set -euo pipefail`. Les cas limites précédents (epic vide ou missing) sont bien corrigés par l'itération minutieuse sur les tableaux associatifs.

##### Couche propre au projet

- **Critères d'acceptation** : Satisfaits. Le contrôle global, ainsi que les comportements des drapeaux `--merge` et `--rev`, sont correctement implémentés et couvrent tous les écarts listés dans la story 0.6 sans en vider l'intention.
- **Données privées / Secrets** : Satisfait. Aucune donnée privée, adresse serveur ou secret n'est lu, affiché ou exposé.
- **Concordance documentation / code** : Satisfait. L'interface (`--merge <n.m>`, `--rev <SHA>`) et les tolérances documentées dans `.claude/skills/sprint-consistency/SKILL.md` et `docs/procedures/sprint-consistency.md` correspondent scrupuleusement à l'exécution de `scripts/sprint-consistency.sh`.
- **Cohérence architecture / AGENTS.md** : Satisfait. Le script utilise uniquement bash POSIX et les utilitaires standards (awk, grep) sans recourir à Python ou `jq`, et l'architecture des skills à 3 niveaux est respectée.
- **Erreurs silencieuses sous set -euo pipefail** : Satisfait. Les retours d'erreurs sont traités ; l'abandon de la substitution de processus `< <(...)` au profit d'une substitution de commande `$(...)` garantit la propagation de l'erreur en cas de dysfonctionnement.

##### Classement des constats

NON BLOQUANT : La stricte attente de 2 espaces d'indentation dans le script `awk` repose sur le comportement prédictible de l'outil de planification de BMAD, qui génère le fichier YAML de façon déterministe.
NON BLOQUANT : Le risque de faux positif sur un sous-dossier finissant par `.md` en mode `--rev` est purement théorique et n'impacte pas la logique métier de la vérification.
NON BLOQUANT : L'ensemble des critères d'acceptation et des règles de l'architecture du projet sont scrupuleusement respectés.

VERDICT: NON BLOQUANT — aucune

### 15/09/2026 — `a18dfb1` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 10. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 97336377fc8ab188ae539223

##### Rapport de revue (bmad-review)

###### Lentille : edge-case-hunter
Aucun cas limite non géré n'a été identifié. Les correctifs apportés lors du dernier commit (assouplissement de l'expression régulière awk pour tolérer une indentation variable et vérification rigoureuse du type de fichier `blob` via `git ls-tree` en mode `--rev`) couvrent efficacement les failles soulevées lors des revues précédentes. Le filtrage des préfixes est robuste (ex. `--merge 0.6` matchera strictement `0-6-*` sans fausse collision avec un éventuel `0.60`).

###### Lentille : verification-gap
Aucun écart de vérification identifié. Toutes les exécutions susceptibles d'échouer sont encadrées (soit testées, soit évaluées via des structures conditionnelles), empêchant l'apparition de faux positifs ou de comportements silencieux imprévus.

##### Couche propre au projet

- **Critères d'acceptation** : Satisfaits. Les options `--merge` et `--rev` de `scripts/sprint-consistency.sh` s'exécutent comme exigé. Les vérifications croisées entre fichiers de story, epics et le fichier YAML valident exhaustivement les statuts sans vider l'intention des règles.
- **Données privées / Secrets** : Satisfait. Aucune donnée privée, aucun nom d'hôte, aucune adresse de serveur ni secret n'est manipulé, écrit, commité ou exposé en sortie.
- **Concordance documentation / code** : Satisfait. Le fichier `.claude/skills/sprint-consistency/SKILL.md`, la procédure `docs/procedures/sprint-consistency.md` et le script sont parfaitement synchronisés quant aux options appelables et à la définition formelle des écarts de sprint.
- **Cohérence architecture / AGENTS.md** : Satisfait. L'architecture à trois niveaux est en place. Le recours à un bash POSIX strict avec outils standards (sans Python, sans dépendance logicielle supplémentaire) est fidèle aux choix techniques.
- **Erreurs silencieuses sous set -euo pipefail** : Satisfait. Les substitutions de processus ont été expurgées ; l'utilisation de substitutions de commande (ex: `names=$(list_names)`) empêche les erreurs de sombrer dans le silence et fait trébucher le script comme il se doit.

##### Classement des constats

NON BLOQUANT : Les critères d'acceptation de la story sont entièrement satisfaits.
NON BLOQUANT : Aucune donnée privée, adresse de serveur ni secret n'est compromis.
NON BLOQUANT : Le skill, la procédure et le script concordent parfaitement.
NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture.
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur les revues du code de la PR n° 10 :

- `47a946d` (block) :
  - liste des fichiers de story lue par une substitution de processus, échec silencieux sous `set -e` : corrigé (`ed7fccd`), liste lue dans une variable, code 2 si illisible ;
  - `find -printf` propre aux outils GNU : corrigé (`ed7fccd`), joker du shell ;
  - `--merge` sur deux stories partageant un préfixe : corrigé (`ed7fccd`), écart si plusieurs clés ;
  - epic sans story ignoré : corrigé (`ed7fccd`), écart.
- `ed7fccd` (pass) : stories dont l'epic n'a pas de ligne dans le suivi non signalées : corrigé (`65e2a33`), écart ; autres constats : confirmations.
- `65e2a33` (pass) :
  - suivi indenté autrement que par deux espaces : corrigé (`a18dfb1`), toute indentation acceptée ;
  - dossier nommé `*.md` avec `--rev` : corrigé (`a18dfb1`), seuls les fichiers comptent.
- `a18dfb1` (pass) : aucun constat, confirmations seulement.

Constat de l'auteur : le premier essai du cas « aucun fichier de story » avait une préparation fautive (clés du suivi amputées) ; refait correctement avant le commit `ed7fccd`, code 0 obtenu.

## Reporté
