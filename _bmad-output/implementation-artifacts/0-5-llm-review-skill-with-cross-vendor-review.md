# Story 0.5 : LLM-review skill with cross-vendor review

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.5, réécrite après la revue de spec ci-dessous.

## Revue de spec

### 14/09/2026 — revue manuelle, `gemini-3.1-pro-high`, `bmad-review` (angles adverse, structure, prose)

Faite à la main, avant l'existence du script, dans une copie isolée à la tête de `dev` (`19763e0`) : jeton de lecture cité, aucun fichier écrit par le relecteur. Le rapport commençait par deux lignes d'instructions internes d'`agy`, sans rapport avec la revue : le script ne retient le rapport qu'à partir de la ligne du jeton.

| # | Constat | Décision |
|---|---|---|
| 1 | L'entrée `<PR>` n'est pas définie : numéro de PR ou branche ? D'où viennent la base et le SHA ? | Corrigé dans la spec : numéro de PR ; base, branche et SHA de tête lus par l'API. |
| 2 | Les modèles relecteurs ne sont pas écrits comme constantes. | Corrigé : constantes dans la spec, sans option pour en changer (décision d'Arnaud). |
| 3 | `--context` serait une option d'`agy` à ajouter à l'appel. | Écarté : `--context` est une option du script ; la précision donnée au relecteur était ambiguë. |
| 4 | Les deux temps de revue et l'usage de `bmad-review` sont absents du texte. | Corrigé : décisions et critères ajoutés. |
| 5 | L'échec de publication du commentaire n'est pas contrôlé : le script finirait « avec succès » sans verdict sur la PR. | Corrigé : HTTP 201 exigé, sinon échec. |
| 6 | Contradiction entre la première ligne `llm-review` du commentaire et la dernière ligne `VERDICT:` demandée au relecteur. | Corrigé : la spec distingue la ligne lue dans le rapport et la ligne écrite en tête du commentaire. |
| 7 | La mise en commun de l'accès à l'API dans `scripts/lib/gitea.sh` n'apparaît pas. | Corrigé : critère ajouté, `create-pull-request.sh` l'utilise aussi. |
| 8 | Des modifications locales non commitées pourraient fausser le diff relu. | Corrigé : la copie relue part du SHA de tête de la PR récupéré sur la forge, jamais de l'arbre local. |
| 9 | La suppression de la copie n'est pas garantie après une interruption (Ctrl+C). | Corrigé : nettoyage à la sortie, y compris sur interruption. |
| 10 | Structure : les critères suivent l'ordre d'ajout, pas l'ordre d'exécution du script. | Corrigé : critères réécrits dans l'ordre d'exécution. |
| 11 | Structure : des obligations sont rangées dans les cases à cocher de fin. | Corrigé : intégrées aux critères ; les cases restantes ne portent que des constats et la preuve. |
| 12 | Prose : « le script la publie » puis « elle est postée » brouille qui agit. | Corrigé dans la réécriture : le script est le sujet de chaque action. |

Questions « à trancher » du rapport, toutes réglées par Arnaud : format du verdict (constats 6), choix du mode (`--story` ou numéro de PR), extraction de `scripts/lib/gitea.sh` dans cette story, définition de `<PR>`.

## Revue du code

### 14/09/2026 — `2c17e38` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 9. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f40be6aa6e0462f48da5a532

##### Revue du code (Lentilles BMAD et couche propre au projet)

**Lentille : edge-case-hunter**
NON BLOQUANT : Si un fichier créé ou modifié par le relecteur contient une virgule dans son nom, l'affichage des fichiers modifiés sera légèrement déformé par l'instruction `sed 's/,/, /g'` (ligne 181 de `scripts/llm-review.sh`). L'impact est purement cosmétique et informatif.
NON BLOQUANT : Si l'API Gitea renvoie un corps inattendu ou un JSON invalide (par exemple une erreur HTTP 500), la commande `jq` échouera silencieusement, ce qui produira une chaîne vide. Le script s'arrêtera alors de façon sécurisée avec le message générique « la PR n'est pas ouverte » au lieu d'une erreur de format, respectant ainsi l'exigence de ne pas continuer sur une donnée invalide.

**Lentille : verification-gap**
NON BLOQUANT : L'absence de tests automatisés pour `scripts/llm-review.sh` et `scripts/lib/gitea.sh` constitue une faille de vérification classique. Cependant, ce point précis est déjà assumé et consigné dans le document `_bmad-output/implementation-artifacts/deferred-work.md`.

**Couche propre au projet**
NON BLOQUANT : Le jeton d'accès Gitea est manipulé de manière hautement sécurisée. Il est lu hors de la trace du shell (`set +x`), n'est jamais exporté dans l'environnement, et est transmis à `curl` par l'entrée standard (`-K -`), ce qui empêche toute fuite dans la liste des processus système (`ps`). Les URL distantes sont systématiquement masquées des erreurs via `forge_message`. Aucune donnée privée n'est exposée.
NON BLOQUANT : La robustesse sous `set -euo pipefail` est garantie. L'intégralité des commandes susceptibles de renvoyer un code non nul (grep, jq, git diff, awk) sont correctement encadrées par des conditions `if`, ou neutralisées explicitement avec `|| true` et `|| die`. Aucune erreur système ne peut être ignorée silencieusement.
NON BLOQUANT : Les critères d'acceptation de la story 0.5 sont intégralement satisfaits sans être vidés de leur intention. La stricte isolation du worktree, le contrôle systématique par `check-private.sh`, et la validation du jeton aléatoire de lecture sont implémentés.
NON BLOQUANT : La cohérence entre le code, l'architecture et les processus est totale. Le fichier `AGENTS.md`, le document `ARCHITECTURE-SPINE.md` et la procédure `docs/procedures/llm-review.md` concordent scrupuleusement avec les arguments et le comportement des scripts livrés (modèles désignés, mode plan d'Antigravity, cycle de statut).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur :

- virgule dans le nom d'un fichier écrit par le relecteur : acceptée telle quelle, elle ne touche que l'affichage ;
- JSON illisible renvoyé par la forge : corrigé, le script dit « réponse de la forge illisible » au lieu de « PR pas ouverte » ;
- tests automatisés : déjà reportés dans `deferred-work.md` ;
- autres constats : confirmations, sans action.

### 14/09/2026 — `2c17e38` — `claude-opus-4-6-thinking` — verdict `pass`

Rapport publié en commentaire de la PR n° 9. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 988a4d62fdc8ed346cd69586

#### Rapport de revue — PR n° 9, `chore/0-5-llm-review-skill`, SHA `2c17e38`

**Contenu** : diff (code et documentation), story 0.5.  
**Lentilles** : edge-case-hunter, verification-gap, puis couche propre au projet.

---

#### Lentille 1 — Edge-case-hunter

##### Constat ECH-1 — `gitea_api` : `curl` en échec réseau donne `000`, pas une chaîne vide

- **Localisation** : `scripts/lib/gitea.sh:68-74`
- **Condition** : `curl` échoue (réseau injoignable, résolution DNS) → `|| true` avale l'erreur, `-w '%{http_code}'` affiche `000`
- **Guard** : tous les appelants comparent ensuite `$code` à un code HTTP attendu (`200`, `201`) et appellent `die` sinon → l'erreur est détectée
- **Conséquence** : aucune, la construction est correcte ; chaque appelant dans `llm-review.sh` (l. 93, 218) et `create-pull-request.sh` teste le code retourné

**→ Aucun chemin non gardé.**

##### Constat ECH-2 — `git diff` avec triple point vs double point

- **Localisation** : `scripts/llm-review.sh:105,149`
- **Condition** : ligne 105 utilise `git diff --name-only "$base_sha...$head_sha"` (triple point, merge-base relatif), ligne 149 utilise `git diff "$base_sha...$head_sha"` (même). C'est cohérent entre la détection de type de fichiers et le diff envoyé au relecteur
- **Conséquence** : aucune incohérence

**→ Aucun chemin non gardé.**

##### Constat ECH-3 — Revue de spec : `grep` sur `sprint-status.yaml` avec le story_key construit à partir d'un numéro fourni par l'utilisateur

- **Localisation** : `scripts/llm-review.sh:130-131`
- **Condition** : `story_num` vient de l'argument utilisateur (validé par la regex `^[0-9]+\.[0-9]+[a-z]?$`, l. 41). Le `.` est remplacé par `-` (`${story_num//./-}`), puis injecté dans le motif regex de `grep -oE`. Le `-` n'est pas un caractère spécial de regex dans ce contexte (`^  0-5-…:`)
- **Conséquence** : pas d'injection de regex. Le `[a-z0-9-]+` du motif grep est bien ancré par `^  ` et `:` final

**→ Aucun chemin non gardé.**

##### Constat ECH-4 — `awk` pour extraire la story d'`epics.md` : le heading doit commencer exactement par `### Story $story :`

- **Localisation** : `scripts/llm-review.sh:151-152`
- **Condition** : l'ancre `awk -v h="### Story $story :"` utilise `index($0, h) == 1` (pas un regex), donc aucune injection via `$story`. La story est extraite jusqu'au prochain `^##`, ce qui est correct pour le format de `epics.md`
- **Conséquence** : si le format change (par ex. `#### Story`), le script échoue proprement (`[[ -s $tmp/spec.md ]] || die`)

**→ Aucun chemin non gardé.**

##### Constat ECH-5 — `check-private.sh history` en mode spec avec `audit_range=(-1 "$head_sha")`

- **Localisation** : `scripts/llm-review.sh:123,142`
- **Condition** : `-1` est passé comme argument à `git rev-list "$@"` dans `check-private.sh` l. 72, ce qui donne `git rev-list -1 <sha>` = un seul commit. Correct. Mais : en mode spec, la copie isolée est au SHA de `dev`, et on n'audite qu'un commit ; le contenu envoyé est seulement le texte de la story extrait d'`epics.md`, pas le commit entier
- **Conséquence** : acceptable — le garde-fou vérifie le commit HEAD de `dev`, qui couvre le fichier `epics.md` d'où la story est extraite

**→ Aucun chemin non gardé.**

##### Constat ECH-6 — `written` détecte les fichiers créés par le relecteur : le filtre `grep -vxF "?? $content_name"` suppose le format porcelaine de `git status`

- **Localisation** : `scripts/llm-review.sh:179`
- **Condition** : si le relecteur modifie le fichier `$content_name` lui-même (le diff), `git status --porcelain` le montrera comme `M  REVIEW-DIFF.patch` ou `MM …`, pas `?? …`. Le filtre `grep -vxF "?? $content_name"` ne l'exclura pas → il sera correctement listé dans `$written`
- **Conséquence** : correctement gardé

**→ Aucun chemin non gardé.**

##### Constat ECH-7 — `load_gitea_env` : valeur avec `=` dans la partie droite

- **Localisation** : `scripts/lib/gitea.sh:41`
- **Condition** : `value=${line#*=}` supprime la première occurrence de `=` et garde le reste. Si la valeur contient un `=` (ex. un token base64), `line#*=` ne prend que depuis le premier `=` → la valeur complète est bien conservée. Avec des guillemets doubles, `value=${value#\"}; value=${value%%\"*}` tronque après le premier guillemet fermant → une valeur avec des guillemets internes serait tronquée. Mais les tokens Gitea ne contiennent pas de guillemets, et la procédure `gitea-token.md` ne prescrit pas de guillemets pour les tokens
- **Conséquence** : pas de risque réaliste

**→ Aucun chemin non gardé pour l'usage documenté.**

##### Constat ECH-8 — `sed -E 's/^(#{1,4}) /\1## /'` pour abaisser les titres de 2 niveaux

- **Localisation** : `scripts/llm-review.sh:208`
- **Condition** : un titre `#####` (h5) deviendrait `#######` (h7), ce qui n'est pas du Markdown valide. Un titre `######` (h6) deviendrait `########` (h8)
- **Conséquence** : le rapport du relecteur contient au maximum des titres de niveau 2 ou 3 (le skill `bmad-review` structure par lentille). Un h5 ou h6 dans le rapport est improbable, et le résultat ne serait qu'un titre non rendu dans le fichier de story, sans perte de données

NON BLOQUANT — titre Markdown profond (h5+) mal abaissé, cas improbable et sans conséquence fonctionnelle.

##### Constat ECH-9 — `contains_private` sur le rapport : un faux positif bloque la publication

- **Localisation** : `scripts/llm-review.sh:202-204`
- **Condition** : si le rapport du relecteur contient par hasard un mot qui est aussi un motif privé (nom de ville, etc.), la publication est bloquée et le script échoue. C'est voulu : faux positif > fuite
- **Conséquence** : le script échoue ; l'utilisateur relance. Comportement correct par conception

**→ Aucun chemin non gardé.**

---

#### Lentille 2 — Verification-gap

##### Constat VG-1 — Aucun test automatisé des scripts

- **Localisation** : `scripts/llm-review.sh`, `scripts/lib/gitea.sh`, `scripts/create-pull-request.sh`
- **Écart** : les trois scripts n'ont aucun test automatisé. La vérification repose entièrement sur des essais manuels consignés dans les PR
- **Constatation** : ce point est déjà identifié et reporté dans [`deferred-work.md`](file:///tmp/tmp.AAghDJQ2ef/copie/_bmad-output/implementation-artifacts/deferred-work.md), et la story 0.5 y ajoute une entrée explicite
- **Gap shape** : `regression-gap` — une régression dans `load_gitea_env` ou `gitea_api` ne serait attrapée par aucun test
- **Consumer** : tout script qui source `scripts/lib/gitea.sh`

NON BLOQUANT — reporté explicitement dans `deferred-work.md`, reconnu comme dette technique acceptée à ce stade du projet.

##### Constat VG-2 — Changement comportemental : la refactorisation de `create-pull-request.sh` change l'ordre des vérifications

- **Localisation** : `scripts/create-pull-request.sh:40-78` (après refactorisation)
- **Comportement changé** : `.env` était lu en étape 3 (avant `check_origin`), il est maintenant lu en étape 10 (après `check_origin`, après le garde-fou). La procédure et le script concordent sur ce nouvel ordre
- **Vérification** : aucun test n'assure que l'ordre des vérifications n'a pas changé, mais l'ordre est volontairement modifié et documenté
- **Conséquence** : en cas de `.env` absent, le script exécute maintenant plus de vérifications avant de mourir, ce qui est préférable (pas de lecture de secrets inutile)

NON BLOQUANT — changement d'ordre intentionnel et documenté.

---

#### Couche propre au projet

##### Constat PP-1 — Critères d'acceptation de la story 0.5

Vérification de chaque critère d'acceptation contre le code livré :

| Critère | Vérifié | Remarque |
|---|---|---|
| Coupe la trace du shell avant `.env` | ✅ | `set +x` l. 12, avant tout `load_gitea_env` |
| Échoue sans `jq` avec `sudo apt install jq` | ✅ | via `require_tools` → `gitea.sh` l. 23 |
| Refuse `AUTHOR_LLM` hors `claude`/`gemini` | ✅ | l. 47-51 |
| Refuse un appel hors des deux usages | ✅ | l. 39-40 |
| Charge `.env` par `scripts/lib/gitea.sh` sans valeur | ✅ | l. 91, via `load_gitea_env` |
| Refuse une PR fermée | ✅ | l. 95 |
| Lit base, branche, SHA par l'API | ✅ | l. 93-98 |
| Crée la copie isolée au SHA de tête, pas l'arbre local | ✅ | l. 100, 137 : `git fetch` + `git worktree add ... $head_sha` |
| Diff = branche entière | ✅ | l. 149 : `git diff "$base_sha...$head_sha"` |
| Revue de spec : texte extrait d'`epics.md` à la tête de `dev` sur la forge | ✅ | l. 118-119, 151-154 |
| Story introuvable → échec | ✅ | l. 133, 153 |
| Copie isolée = worktree hors du dépôt, sans `.env`/`docs/private`/`.pr-body.md` | ✅ | l. 136-140, l. 61-63 (vérifie `$tmp` hors de `$root`) |
| `check-private.sh history` avant envoi | ✅ | l. 142-143 |
| Jeton de lecture aléatoire | ✅ | l. 145-146 |
| `agy --mode plan` avec `--add-dir`, constante du modèle, consigne versionnée | ✅ | l. 173-174 |
| Délai dépassé → échec sans publication | ✅ | `timeout 900`, l. 175 |
| Fichiers créés par le relecteur signalés | ✅ | l. 177-185 |
| Rapport doit citer le jeton | ✅ | l. 187-188 |
| Rapport retenu à partir de la ligne du jeton | ✅ | l. 189 |
| Dernière ligne = `VERDICT:` en revue du code | ✅ | l. 192-199 |
| Verdict `block` publié normalement | ✅ | l. 196-199, puis l. 218 |
| Rapport ne contient pas de motif privé | ✅ | l. 202-204 |
| Commentaire HTTP 201 | ✅ | l. 219 |
| Rapport ajouté au fichier de story | ✅ | l. 246-268 |
| Revue de spec : fichier de story créé si absent | ✅ | l. 247-255 |
| Copie isolée supprimée en fin, même sur échec/interruption | ✅ | `trap cleanup EXIT`, `trap exit INT/TERM` |
| Identifiant des modèles dans la procédure | ✅ | `llm-review.md` l. 16-19 |
| Fichiers d'historique 0.1 à 0.4 | ✅ | 4 fichiers dans le diff |
| Preuve : PR relue par le script lui-même | ⬜ | à vérifier à l'exécution, pas dans le diff |

NON BLOQUANT — tous les critères vérifiables dans le code sont satisfaits. Le critère de preuve (relecture de la PR par le script) est vérifiable à l'exécution seulement.

##### Constat PP-2 — Données privées, secrets, adresses

- Aucune adresse de forge ni nom d'hôte n'apparaît dans le diff.
- `forge_message` dans `gitea.sh` (l. 78) remplace toute URL par `<adresse>`.
- Aucun `die` ou `printf` n'affiche `gitea_url`, `gitea_token` ou `gitea_user`.
- `set +x` en tête de chaque script.
- Le jeton Gitea passe à `curl` par stdin (`-K -`), pas en argument.
- Les variables `.env` ne sont pas exportées (l. 29 du commentaire).
- Le commentaire de PR (l. 211-214) ne contient aucune valeur de `.env`.
- `.env`, `docs/private/` et `.pr-body.md` sont explicitement absents de la copie isolée.
- `--dangerously-skip-permissions` n'expose que la copie isolée.

NON BLOQUANT — aucune fuite détectée.

##### Constat PP-3 — Concordance skill / procédure / script

| Élément de la procédure (`llm-review.md`) | Script (`llm-review.sh`) | Concordance |
|---|---|---|
| 1. Trace coupée | l. 12 : `set +x` | ✅ |
| 2. Exactement un usage | l. 39-41 | ✅ |
| 3. Origin = dépôt canonique | l. 55 : `check_origin` | ✅ |
| 4. Fichier de motifs | l. 57-58 | ✅ |
| 5. `.env` lu par `lib/gitea.sh` | l. 91 | ✅ |
| 5. PR ouverte | l. 95 | ✅ |
| 5. Base, branche, SHA par l'API | l. 93-98 | ✅ |
| 5. Branche n'a pas bougé | l. 103-104 | ✅ |
| 5. Revue de spec : tête de dev sur la forge, story dans le suivi | l. 118-119, 133 | ✅ |
| 6. Worktree hors dépôt, sans `.env`/`docs/private`/`.pr-body.md` | l. 136-140 | ✅ |
| 7. `check-private.sh history` | l. 142 | ✅ |
| 8. Jeton aléatoire en tête | l. 145-154 | ✅ |
| 9. `agy --mode plan`, `--add-dir`, 15 min | l. 173-174 | ✅ |
| 10. Fichiers créés signalés | l. 177-185 | ✅ |
| 11. Jeton cité, rapport à partir du jeton | l. 187-189 | ✅ |
| 12. Dernière ligne = verdict | l. 192-199 | ✅ |
| 13. Rapport sans motif privé | l. 202-204 | ✅ |
| 14. HTTP 201 | l. 219 | ✅ |
| 15. Rapport ajouté au fichier de story | l. 246-268 | ✅ |
| 16. Nettoyage à la sortie | l. 65-74 | ✅ |

Le skill (`SKILL.md`) renvoie à la procédure, qui renvoie au script. Les trois niveaux concordent.

Pour `create-pull-request` : la procédure mise à jour (étapes renumérotées 3→10) concorde avec le script refactorisé. Le skill `create-pull-request/SKILL.md` n'est pas modifié dans ce diff, et il renvoie à sa procédure.

NON BLOQUANT — concordance complète.

##### Constat PP-4 — Cohérence avec AGENTS.md et l'architecture

- Les modifications d'`AGENTS.md` ajoutent les descriptions des deux temps de revue, du fichier de story, et du commit de statut étendu au fichier de story. Ces ajouts sont cohérents avec les décisions AD-24, et avec les modifications de l'`ARCHITECTURE-SPINE.md` (décisions 62 à 66).
- La description du flux dans `epics.md` (règle 9) est mise à jour pour mentionner le fichier de story et la revue de spec, en cohérence avec le reste.
- La story 0.6 (sprint-consistency) est ajustée pour clarifier la détection des fichiers de story orphelins/manquants — cohérent avec le nouveau fichier de story.
- La story 0.7 (verify-and-merge-pr) est ajustée pour que le commit de statut `done` puisse aussi modifier le fichier de story — cohérent avec AGENTS.md §4.
- `sprint-status.yaml` : story 0.5 passe à `review`, les 0.1 à 0.4 restent `done`. Cohérent.

NON BLOQUANT — toutes les modifications de documentation sont cohérentes entre elles et avec les décisions d'architecture.

##### Constat PP-5 — Erreurs silencieuses dans les scripts shell

Examen sous `set -euo pipefail` :

| Pattern | Localisation | Silencieux ? |
|---|---|---|
| `gitea_api … \| curl … \|\| true` | `gitea.sh:73` | Non : le code HTTP est capturé ; tout appelant vérifie `$code` |
| `forge_message … \|\| true` | `gitea.sh:78` | Non : fonction d'affichage, un échec donne une chaîne vide, le message d'erreur `die` est quand même émis |
| `grep … \|\| true` (motifs) | `llm-review.sh:76` | Non : `$tmp/patterns` est vérifié par `[[ -s … ]]` dans `contains_private` |
| `grep -vxF … \|\| true` (written) | `llm-review.sh:179` | Non : `$written` vide → `written_label="aucun"` → correct |
| `shopt -u patsub_replacement … \|\| true` | `llm-review.sh:13` | Non : option disponible en bash 5.2+, sans elle le script fonctionne (protection contre les `&` dans les remplacements de `${//}`) |
| `git worktree remove --force … \|\| true` | `llm-review.sh:67` | Non : dans le `cleanup`, en fin de script ; un échec de nettoyage ne doit pas masquer l'erreur originale |
| `git worktree prune … \|\| true` | `llm-review.sh:68` | Idem |

NON BLOQUANT — aucune erreur ne passe en silence. Chaque `|| true` est justifié et n'empêche aucun chemin d'erreur de mourir via `die` ou de sortir avec un code non nul.

##### Constat PP-6 — `load_gitea_env` : commentaire retiré d'une valeur sans guillemets

- **Localisation** : `scripts/lib/gitea.sh:45`
- **Condition** : `value=${value%%[[:space:]]#*}` retire la partie `# …` d'une valeur sans guillemets. Si un token Gitea contient `#`, la partie après le `#` serait retirée. La procédure `gitea-token.md` documente ce comportement (l. 42), et les tokens Gitea sont des chaînes hexadécimales ou base64 qui peuvent contenir `#`
- **Conséquence** : un token avec `#` serait tronqué. Mais la probabilité est faible (les tokens Gitea sont hexadécimaux sur les versions courantes), et la procédure recommande les guillemets pour les valeurs complexes

NON BLOQUANT — cas théorique sur un token improbable, et la procédure documente les guillemets comme solution.

##### Constat PP-7 — `create-pull-request.sh` : la procédure cite `.env` lu par `scripts/lib/gitea.sh` (étape 10), mais l'ancien code lisait `.env` directement ; le code refactorisé utilise bien `load_gitea_env`

- **Localisation** : `scripts/create-pull-request.sh:76-78`, `docs/procedures/create-pull-request.md:50`
- **Vérification** : la procédure dit « par `scripts/lib/gitea.sh` » et le script fait `. "$script_dir/lib/gitea.sh"` puis `load_gitea_env "$root/.env"`

NON BLOQUANT — concordance correcte.

---

#### Résumé des constats

| # | Constat | Classement |
|---|---|---|
| ECH-8 | Titres Markdown profonds (h5+) mal abaissés — cas improbable | NON BLOQUANT |
| VG-1 | Aucun test automatisé des scripts — déjà reporté dans `deferred-work.md` | NON BLOQUANT |
| VG-2 | Ordre des vérifications changé dans `create-pull-request.sh` — intentionnel et documenté | NON BLOQUANT |
| PP-1 | Critères d'acceptation tous satisfaits dans le code | NON BLOQUANT |
| PP-2 | Aucune fuite de donnée privée, secret ou adresse | NON BLOQUANT |
| PP-3 | Skill, procédure et script concordent | NON BLOQUANT |
| PP-4 | Cohérent avec AGENTS.md et l'architecture | NON BLOQUANT |
| PP-5 | Aucune erreur silencieuse dans les scripts | NON BLOQUANT |
| PP-6 | Token avec `#` tronqué si non entre guillemets — cas théorique, documenté | NON BLOQUANT |

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur :

- ECH-8 (titres de niveau 5 ou 6) : écarté, le script n'abaisse que les niveaux 1 à 4 et laisse les autres intacts ;
- VG-1 (tests automatisés) : déjà reporté dans `deferred-work.md` ;
- VG-2 (ordre des contrôles de `create-pull-request`) : voulu et documenté, `.env` n'est lu qu'au premier appel à l'API ;
- PP-6 (jeton contenant `#`) : écarté, seul un `#` précédé d'une espace est retiré, ce que l'essai `jeton#collé` vérifie ;
- lien vers le chemin temporaire de la copie isolée dans le rapport : sans conséquence ;
- autres constats : confirmations, sans action.

Constat de l'auteur après ces deux revues : à la première revue du code d'une story, le script supprimait la ligne d'attente « Aucune revue pour l'instant. » qu'il avait écrite, alors que le commit de statut `done` n'admet que des lignes ajoutées. Non déclenché ici (apostrophe droite dans ce fichier écrit à la main), mais bloquant pour les stories suivantes. Corrigé : plus de ligne d'attente, le script n'ajoute que des lignes et refuse d'écrire si une ligne disparaîtrait ; la règle du verrou couvre aussi les décisions de l'auteur et `deferred-work.md`.

### 14/09/2026 — `e78f1ac` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 9. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 4c74619f659359cf80fcdf15

##### Revue du code — PR n° 9 (Lentilles BMAD et couche propre au projet)

**Lentille : edge-case-hunter**
NON BLOQUANT : Si la réponse JSON de l'API Gitea est malformée malgré un code HTTP 200, l'appel à `jq` échouera et l'option `set -e` provoquera l'arrêt immédiat et bruyant du script, évitant ainsi toute compromission silencieuse du flux.
NON BLOQUANT : La vérification mise en place pour faire respecter la règle du verrou lors de l'ajout au fichier de story (`diff | grep '^<'`) prévient efficacement toute suppression ou altération accidentelle des lignes existantes.

**Lentille : verification-gap**
NON BLOQUANT : L'absence de tests unitaires ou d'intégration pour les différents scripts shell constitue un manque, mais celui-ci est explicitement reconnu, assumé et reporté dans le fichier `deferred-work.md`.

**Couche propre au projet**
NON BLOQUANT : Les critères d'acceptation de la story sont intégralement remplis sans être détournés, le flux distinguant bien l'usage `--story` de l'usage PR et utilisant systématiquement un worktree strictement isolé.
NON BLOQUANT : La sécurité des données est assurée : le jeton est transmis à `curl` par l'entrée standard, aucune variable d'environnement n'est exportée inutilement, et la fonction `forge_message` masque efficacement toute URL dans les retours d'erreurs.
NON BLOQUANT : La concordance entre les procédures et l'implémentation est exacte (par exemple, le chargement retardé de `.env` figure bien à la 10e étape de `docs/procedures/create-pull-request.md` comme dans le code).
NON BLOQUANT : Les documents fondateurs `AGENTS.md` et `ARCHITECTURE-SPINE.md` ont été mis à jour de manière cohérente pour acter les deux phases de revue (spec puis code) et l'extension du commit de statut au fichier de story.
NON BLOQUANT : L'intégrité face aux erreurs est garantie par `set -euo pipefail`, les rares instructions terminées par `|| true` étant justifiées (comme le nettoyage en sortie de script) et ne masquant aucune erreur fonctionnelle.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur :

- constats edge-case-hunter et couche propre au projet : confirmations de la correction, sans action ;
- tests automatisés : déjà reportés dans `deferred-work.md`.

## Reporté

- Tests automatisés des scripts : `deferred-work.md`.
