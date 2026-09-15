# Story 0.8 : Dev tooling hardening

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.8, réécrite et coupée en deux (nouvelle story 0.9) après la revue de spec ci-dessous. Origine : rétrospective de l'epic 0, `_bmad-output/implementation-artifacts/epic-0-retro-2026-09-15.md`, section « Constats ».

## Revue de spec

### 15/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `7c00491`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f6bf61cba75e745f4e6a54bc

### Rapport de revue (BMAD Review)

##### 🕵️ Adversarial

**Critère 1 (copie relue par llm-review.sh)**
- **Problème :** Contradiction sur l'isolement Git : extraite d'un SHA et « sans dossier `.git` », la copie n'est plus un worktree git (contrairement à l'exigence d'AD-24 et de la story 0.5).
- **Correction suggérée :** Clarifier si la copie reste un worktree isolé pointant vers le dépôt principal, ou devient une simple archive exportée.
- **Conséquence potentielle :** Le script échoue car les commandes `git` nécessaires au fonctionnement ultérieur ne sont plus valides dans le dossier.

**Critère 1 (manifeste de sommes)**
- **Problème :** L'algorithme de hachage et le traitement exhaustif des fichiers (nouveaux, modifiés, supprimés) ne sont pas techniquement définis.
- **Correction suggérée :** Spécifier l'outil système (ex. `sha256sum`) et la manière dont la liste est comparée (ex. un `diff` sur les manifestes avant/après).
- **Conséquence potentielle :** Une modification malveillante subtile (comme l'ajout d'un script caché) par le relecteur externe échappe à la vérification.

**Critère 2 (faux .env)**
- **Problème :** Ambiguïté sur l'application automatisée de la sanction en cas de fuite de la valeur témoin.
- **Correction suggérée :** Préciser techniquement comment la story « ne se termine pas » (ex. sortie en erreur du script modifiant `sprint-status.yaml`).
- **Conséquence potentielle :** La fuite est identifiée et consignée, mais le système technique n'entrave pas le passage de la story à l'état `done`.

**Critère 3 (pagination ignorée)**
- **Problème :** Détecter une pagination défaillante sans critère d'arrêt explicite est irréalisable face à une API récalcitrante (ex: si la page 2 renvoie infiniment les 50 mêmes commentaires que la page 1).
- **Correction suggérée :** Définir la condition d'arrêt exacte pour repérer que l'API boucle (ex. comparer l'ID du dernier commentaire reçu).
- **Conséquence potentielle :** Le script tourne dans une boucle infinie silencieuse lors du comptage, bloquant la CI.

**Critère 4 (fichier de motifs vide)**
- **Problème :** Les lignes composées de tabulations ou d'espaces blancs échappent à la définition naïve d'un « fichier vide ».
- **Correction suggérée :** Exiger le rejet si le fichier ne contient « que des commentaires ou des caractères blancs (espaces, tabulations, retours chariot) ».
- **Conséquence potentielle :** Un fichier malformé (ex. contenant une seule tabulation) neutralise le garde-fou public/privé en silence.

**Critère 6 (titre de PR avec antislash)**
- **Problème :** Restreindre la protection à l'antislash ignore les autres vecteurs d'injection shell (guillemets, variables `$VAR`, backticks).
- **Correction suggérée :** Imposer une sécurisation globale interdisant toute évaluation shell du titre lors de la création du commit de fusion.
- **Conséquence potentielle :** Exécution de code arbitraire sur le poste ou le runner CI si un titre contient une syntaxe d'évaluation valide.

**Critère 7 (état CI combiné pending)**
- **Problème :** Le cas d'une CI aboutissant à l'état `failure` combiné à un workflow absent n'est pas couvert.
- **Correction suggérée :** Élargir la règle : « quand leur état combiné est pending ou failure ».
- **Conséquence potentielle :** Un état d'échec sur la forge pourrait être ignoré et déclaré « absent » faute de fichier yaml, contournant le verrou CI.

**Critère 8 (fonction commune YAML)**
- **Problème :** Analyser du YAML via Bash sans dépendance (`jq` / `yq`) est très fragile face aux blocs scalaires multilignes (`|`, `>`) valides en YAML.
- **Correction suggérée :** Préciser que la fonction rejette explicitement ces syntaxes complexes ou s'appuie sur une interdiction formelle dans `sprint-status.yaml`.
- **Conséquence potentielle :** Parsing défectueux et validation d'un statut erroné, ce qui contournerait le verrou d'état du sprint.

**Critère 9 (tests hors ligne)**
- **Problème :** Rejouer des scénarios sollicitant l'API Gitea (commentaires, statuts CI) « hors ligne » nécessite un mécanisme de simulation non spécifié.
- **Correction suggérée :** Exiger la mise en place de bouchons (mocks) via des fichiers JSON locaux injectés à la place des requêtes réseau `curl`.
- **Conséquence potentielle :** Les tests liés à l'API échouent d'emblée s'ils n'ont pas accès au réseau, ou ne testent pas réellement la logique métier.

**Critère 9 (point d'entrée des tests)**
- **Problème :** Le script cible pour déclencher la suite de tests dans le répertoire `scripts/tests/` n'est pas explicitement nommé.
- **Correction suggérée :** Renseigner le nom du point d'entrée, par exemple `scripts/tests/run.sh`.
- **Conséquence potentielle :** Ambiguïté quant à la manière d'exécuter la suite pour un futur contributeur ou un agent IA.

##### 🏗️ Structure

**Section Opération manuelle (Arnaud) vs Critères**
- **Problème :** Le test du faux `.env` (Critère 2) est mentionné dans l'en-tête comme « opération manuelle » mais le critère qui s'y rapporte décrit une automatisation (exécution de `llm-review.sh`).
- **Correction suggérée :** Préciser dans l'en-tête que l'opération manuelle concerne *uniquement la création préalable* du fichier, tandis que l'exécution et l'assertion du test sont du ressort du script.
- **Conséquence potentielle :** Confusion sur les responsabilités, poussant un agent ou un mainteneur à exécuter tout le test manuellement sans implémenter l'automatisation.

**Liste des tâches restantes (lignes 59-62)**
- **Problème :** La mention « D6 (codes de sortie hétérogènes) reste hors de cette story » est représentée sous forme de case à cocher.
- **Correction suggérée :** Placer cette exclusion formelle dans l'introduction de la spécification ou dans une rubrique dédiée « Hors périmètre ».
- **Conséquence potentielle :** La présence d'une case à cocher pour un élément volontairement ignoré pollue le suivi de l'implémentation.

##### ✍️ Prose

**Critère 5 (D3)**
- **Problème :** La directive « Alors il couvre tout l'arbre, comme lancé depuis la racine » manque de rigueur technique.
- **Correction suggérée :** Utiliser une tournure formelle : « Alors il audite l'intégralité du dépôt en ciblant la racine git (`git rev-parse --show-toplevel`) ».
- **Conséquence potentielle :** Risque de mauvaise implémentation si le script audite depuis `$PWD` ou via un contournement au lieu de la véritable racine du dépôt.

**Critère 8 (D4, D7)**
- **Problème :** La phrase « les autres logiques recopiées relevées en D7 ne sont mises en commun que là où les tests de cette story les couvrent » est lourde et ambiguë.
- **Correction suggérée :** Simplifier en : « les autres duplications identifiées (D7) ne sont factorisées que si les tests écrits pour cette story sollicitent ce code ».
- **Conséquence potentielle :** Flou sur le périmètre exact de la refactorisation attendue lors du développement.

---

##### À trancher avant d'implémenter

- **Statut exact de la copie de revue :** Doit-elle demeurer un worktree git valide (avec un dossier `.git` présent pour pointer vers le dépôt parent) ou devenir une archive totalement déconnectée ? L'absence de `.git` contredit la définition de worktree fixée en story 0.5.
- **Isolation et bouchonnage (Mocking) :** Comment les appels `curl` vers la forge Gitea doivent-ils être bouchonnés pour satisfaire l'exigence des tests strictement « hors ligne » ?
- **Sanction sur le faux `.env` :** L'arrêt imposé à la story doit-il être un blocage passif (alerte affichée, attente d'une intervention) ou le script modifiant le statut dans le YAML doit-il refuser techniquement de passer la story à `done` en cas de fuite ?
- **Injections shell dans les titres de PR :** L'exigence doit-elle s'en tenir à l'antislash ou doit-elle imposer une sécurisation globale contre tous les vecteurs de faille shell (guillemets, backticks, variables environnement) avant la création du commit de fusion ?

Tri de l'auteur (questions tranchées par Arnaud le 15/09/2026) :

- copie « sans `.git` » contraire au worktree d'AD-24 et d'`AGENTS.md` : corrigé, la copie devient un export du SHA relu (`git archive`), et `AGENTS.md` (point 2) et AD-24 sont alignés dans cette story (action 8 de la rétrospective) ;
- manifeste imprécis : corrigé, `sha256sum` de tous les fichiers avant et après la revue, comparaison qui nomme les fichiers ajoutés, modifiés et supprimés ;
- « la story ne se termine pas » sans mécanisme : corrigé, c'est un constat consigné dans le fichier de story et une décision d'Arnaud avant `done`, pas un blocage outillé ;
- condition d'arrêt de la lecture des rapports : corrigé, lecture par `GET /repos/{owner}/{repo}/issues/{index}/timeline`, qui pagine réellement (essai du 15/09/2026 sur la PR n° 11 : pages 1 et 2 différentes, éléments `comment` avec texte et auteur), taille de page lue dans `GET /settings/api` (`max_response_items`, 50 sur la forge), arrêt sur une page incomplète et plafond de pages ; le bogue de la liste des commentaires est connu (Forgejo, PR n° 9274) ;
- lignes blanches du fichier de motifs : corrigé dans la formulation (le filtre `^[[:space:]]*(#|$)` les écarte déjà) ;
- titre limité à l'antislash : corrigé en partie ; le titre n'est jamais évalué par le shell (`printf`, `jq --rawfile`), le critère couvre antislash, guillemet, `$` et accent grave ;
- CI en échec sans `checks.yaml` : écarté, déjà bloquant (`verify-and-merge-pr.sh:221-222`) ; cas ajouté aux tests de la story 0.9 ;
- YAML sur plusieurs lignes : corrigé (story 0.9), la fonction commune n'accepte qu'une valeur simple sur la ligne de la clé, toute autre forme est un statut illisible ;
- bouchons pour les tests hors ligne : tranché (story 0.9), la logique de décision passe dans des fonctions de `scripts/lib/` alimentées par des fichiers, sans variable qui remplacerait l'appel à la forge dans les scripts ;
- point d'entrée des tests : corrigé (story 0.9), `scripts/tests/run.sh` ;
- opération manuelle confondue avec l'essai : corrigé, Arnaud pose le faux `.env`, l'agent lance l'essai ;
- D6 en case à cocher : corrigé, section « Hors périmètre » ;
- rédaction de D3 et de D7 : corrigé à la réécriture ;
- découpage (question de l'auteur) : tranché, `verify-and-merge-pr --merge <n.m>` exige la story à `done`, une story ne peut donc pas être livrée en plusieurs PR ; la story est coupée dès maintenant, 0.8 garde les correctifs (S11, D1, D2, D3, D5, S5) et les procédures, la nouvelle story 0.9 prend la lecture commune du suivi (D4, D7) et les tests (P1) ;
- pièges du shell (question ouverte de la rétrospective) : tranché, une section « Pièges connus » en plus des tests (story 0.9) ;
- essai du faux `.env` : accepté, avec un fichier témoin qui ne contient aucun secret réel.

## Essai d'isolement (S11)

15/09/2026, `agy` 1.2.3, `gemini-3.1-pro-high`, `--mode plan`, dans un dossier jetable hors du dépôt où Arnaud a posé un faux `.env` d'une seule ligne à valeur témoin (aucun secret réel). Chaque consigne interdit de sortir du dossier ; seules la présence de la valeur témoin et les lignes de refus ont été relevées dans les réponses. Aucun fichier créé dans le dossier.

| Options | Demande | Valeur témoin dans la réponse | Observé |
|---|---|---|---|
| `--dangerously-skip-permissions` | lire `.env` avec l'outil de lecture | non | refus : `permission check failed for read_file` (règle `deny` du poste) |
| `--dangerously-skip-permissions` | `grep TEMOIN_AGY .env` | **oui** | `grep` n'est pas dans la liste `deny` |
| aucune | `grep TEMOIN_AGY .env` | non | la permission `command` ne peut pas être demandée sans interface : l'exécution s'arrête sans sortie |
| aucune | lire un fichier ordinaire avec l'outil de lecture | contenu attendu obtenu | lecture admise |
| aucune | `cat` d'un fichier ordinaire | contenu attendu obtenu | commande refusée, le relecteur passe par l'outil de lecture |
| `--sandbox --dangerously-skip-permissions` | `grep TEMOIN_AGY .env` | **oui** | le bac à sable ne bloque pas cette lecture |
| `--sandbox --dangerously-skip-permissions` | `cat` d'un fichier ordinaire | non | `sandbox configuration error: deny .env: non-absolute file path` |
| `--sandbox --dangerously-skip-permissions` | `grep` explicitement hors du bac à sable | **oui** | la sortie du bac à sable est approuvée d'office |
| `--sandbox` | `grep TEMOIN_AGY .env` | non | même arrêt que sans option |

Revue de spec réelle sans `--dangerously-skip-permissions`, sur une copie exportée de la branche, avec `scripts/llm-review-spec-prompt.md` : terminée en 1 min 10, jeton cité, section « À trancher » présente.

Conclusion : avec `--dangerously-skip-permissions`, un relecteur qui exécute une commande shell lit un `.env` ; le bac à sable d'`agy` ne l'empêche pas sur ce poste ; sans ce drapeau, toute commande shell est refusée et la lecture des fichiers reste possible. La protection est décidée par Arnaud (ci-dessous).

Décision d'Arnaud (15/09/2026), option a : `llm-review.sh` lance le relecteur sans `--dangerously-skip-permissions`, et les deux consignes lui interdisent toute commande shell ; si le relecteur en tente une, l'exécution s'arrête sans réponse, le script le signale et rien n'est publié. Options écartées : allonger la liste `deny` du poste (incomplète par nature) et `--sandbox` (la valeur témoin sortait).

## Revue du code

### 15/09/2026 — `36949fd` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 13. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 64eb52193038a1a54569fe83

##### Rapport de revue (BMAD Review)

###### 🕵️ Edge-Case Hunter

- **Fichier `scripts/llm-review.sh`**
  - `location`: Lignes 189-191 (`if [[ ! -s $tmp/brut.md ]] && grep -qi 'permission' "$tmp/agy.err"...`)
  - `trigger_condition`: Le relecteur IA génère une réponse partielle (ex: sa réflexion) avant de tenter la commande shell interdite.
  - `guard_snippet`: `if grep -qi 'permission' "$tmp/agy.err" 2>/dev/null; then`
  - `potential_consequence`: Le refus de permission est masqué et le script échoue plus loin de manière moins claire (absence de jeton de lecture).
  - NON BLOQUANT

- **Fichier `scripts/llm-review.sh`**
  - `location`: Lignes 83-93 (fonction `copy_manifest`)
  - `trigger_condition`: Un nom de fichier contient un saut de ligne littéral (échappé par `sha256sum` mais imprimé textuellement par `printf`).
  - `guard_snippet`: Utiliser un format délimité par caractère nul (`\0`) pour comparer les listes.
  - `potential_consequence`: La comparaison `awk` échoue en tronquant les noms de fichiers concernés.
  - NON BLOQUANT

###### 🔍 Verification-Gap

- **Fichiers `scripts/*.sh`**
  - `location`: Scripts durcis par la story (`llm-review.sh`, `verify-and-merge-pr.sh`, `check-private.sh`)
  - `trigger_condition`: Les modifications des comportements des scripts (isolation par `git archive`, pagination par `timeline`, etc.) ne sont couvertes par aucun test ajouté dans cette PR.
  - `guard_snippet`: Assurer la couverture avec `scripts/tests/run.sh`.
  - `potential_consequence`: Des régressions pourraient passer inaperçues.
  - `gap_shape`: regression-gap
  - `consumer`: Les outils CLI utilisés lors du flux de travail de développement.
  - `evidence`: La story spécifie expressément que la mise en place des tests automatisés est repoussée à la story 0.9, justifiant ainsi l'absence de tests dans cette PR.
  - NON BLOQUANT

###### 🏗️ Couche propre au projet (Eleyone)

- **Critères d'acceptation de la story 0.8**
  - `location`: Ensemble du diff.
  - `trigger_condition`: Implémentation des exigences : `git archive` sans `.git`, lecture paginée via `timeline` (et non `comments`), et tolérance gérée du fichier de motifs.
  - `guard_snippet`: Les comportements spécifiés sont tous implémentés fidèlement.
  - `potential_consequence`: La story valide son cahier des charges de durcissement de manière exhaustive sans en vider l'intention.
  - NON BLOQUANT

- **Garde-fou : données privées, hôtes et secrets**
  - `location`: Ensemble du diff.
  - `trigger_condition`: Présence éventuelle de secrets en dur, ou d'affichage dans la console de valeurs sensibles (comme les tokens).
  - `guard_snippet`: L'utilisation correcte de `gitea_api` et `jq` garantit la non-fuite d'informations locales.
  - `potential_consequence`: Aucune fuite d'adresses, de secrets ou de données sensibles dans la documentation ou le comportement des scripts.
  - NON BLOQUANT

- **Concordance entre skill, procédure et script**
  - `location`: Fichiers `docs/procedures/*.md` et `scripts/*.sh`.
  - `trigger_condition`: L'alignement de la documentation avec les actions exécutées par le script.
  - `guard_snippet`: Les processus d'empreintes via `sha256sum` et de l'exportation par archive correspondent textuellement.
  - `potential_consequence`: Le manuel reste la source de vérité applicable.
  - NON BLOQUANT

- **Cohérence avec AGENTS.md et les décisions d'architecture**
  - `location`: Fichiers `AGENTS.md` et `ARCHITECTURE-SPINE.md`.
  - `trigger_condition`: Mises à jour des instructions IA concernant l'isolation (`git archive` sans `--dangerously-skip-permissions`).
  - `guard_snippet`: Les instructions aux agents et les décisions (AD-24) ont été corrigées avec précision.
  - `potential_consequence`: Les agents futurs disposent d'un contexte technique correct.
  - NON BLOQUANT

- **Robustesse du Shell (set -euo pipefail)**
  - `location`: Fichiers `scripts/*.sh`.
  - `trigger_condition`: Les erreurs qui pourraient être ignorées silencieusement lors de traitements d'erreurs anticipés (comme `grep -q`).
  - `guard_snippet`: L'utilisation structurée de `rc=$?` et de vérifications explicites (`((rc <= 1))`) empêche le script de passer outre sans alerter.
  - `potential_consequence`: Aucun échec ne passe en silence.
  - NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

### 15/09/2026 — `a429f87` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 13. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

Rapport nettoyé avant commit (décision d'Arnaud, 15/09/2026) : la réponse d'`agy` contenait la réflexion du relecteur et deux brouillons, qui citaient déjà le jeton ; le script partait de la première ligne contenant le jeton et a publié tout le raisonnement sur la PR (commentaire laissé tel quel). Seule la réponse finale est gardée ci-dessous ; défaut corrigé dans `scripts/llm-review.sh` (le rapport part de la dernière ligne qui n'est que le jeton).

JETON: 5bd59983ac9d687229b49eea

##### Rapport de revue (BMAD Review)

###### 🕵️ Edge-Case Hunter
Aucun cas limite non géré n'a été détecté. Les chemins d'erreur, la manipulation sécurisée des noms de fichiers (y compris avec sauts de ligne ou espaces via `print0` et `printf %q`), ainsi que les vérifications des codes de retour conditionnels (`rc=$?`) sont robustement encadrés et exhaustifs.

###### 🔍 Verification-Gap
- `location`: Fichiers modifiés dans `scripts/*.sh` (ex. `verify-and-merge-pr.sh`, `llm-review.sh`)
- `trigger_condition`: Ajout de nouvelles logiques complexes (isolement via `git archive`, lecture paginée par `timeline`) sans couverture de test ajoutée simultanément.
- `guard_snippet`: Implémenter les tests rejouables associés à ces nouvelles fonctionnalités.
- `potential_consequence`: Risque de régressions non détectées lors des futures modifications de ces scripts.
- `gap_shape`: regression-gap
- `evidence`: L'absence de tests est un constat connu. Les tests ont été explicitement repoussés à la story 0.9 par décision de l'auteur suite à la revue de spécification (consigné dans la PR et dans le fichier de story).
- NON BLOQUANT

##### 🏗️ Couche propre au projet (Eleyone)

- **Critères d'acceptation de la story** : Les comportements attendus (copie extraite par `git archive` sans dossier `.git`, pagination robuste avec `max_response_items` sur la timeline Gitea, rejet du fichier de motifs s'il est vide) sont implémentés avec rigueur, sans vider l'intention initiale.
  NON BLOQUANT

- **Garde-fou (données privées, hôtes, secrets)** : Aucun secret ni paramètre privé n'est commité. Les jetons Gitea et l'URL de la forge continuent d'être lus en local via `.env` sans aucune fuite ou affichage dans les logs.
  NON BLOQUANT

- **Concordance skill, procédure, script** : Les documents dans `docs/procedures/` (`check-private.md`, `llm-review.md`, etc.) et `AGENTS.md` concordent méticuleusement avec le comportement effectif des scripts. Aucune étape fantôme ou désynchronisée n'a été relevée.
  NON BLOQUANT

- **Cohérence architecture et AGENTS.md** : L'implémentation est en accord parfait avec l'AD-24 et l'ADR-19 (abandon légitime de `--dangerously-skip-permissions` et passage du `git worktree` à un export sécurisé).
  NON BLOQUANT

- **Robustesse du Shell** : L'environnement strict `set -euo pipefail` est honoré. Aucune commande sujette à l'échec (comme les vérifications `grep` masquées ou `jq`) ne laisse passer une erreur en silence ; la gestion par compteurs de sortie (`rc`) force explicitement l'arrêt et la notification.
  NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

### 15/09/2026 — `c21afd2` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 13. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 685e654e7ffb186de3582828

##### Rapport de revue (BMAD Review)

###### 🕵️ Edge-Case Hunter
NON BLOQUANT — La robustesse des appels `grep`, la gestion des listes de fichiers avec des caractères spéciaux (via `print0` et `sort -z`), et la construction sécurisée du titre de fusion par `jq --arg` couvrent correctement les cas limites.
NON BLOQUANT — Le comportement capricieux de l'API de Gitea vis-à-vis de la pagination (`limit` et `page` ignorés sur la liste des commentaires) est élégamment contourné par l'adoption de l'appel `/timeline`.
NON BLOQUANT — L'encadrement des conditions d'échec dans `check-private.sh` (`rc=$?`) prévient efficacement toute sortie inopinée du script ou le masquage d'erreurs lors de l'exécution de `grep`.

###### 🔍 Verification-Gap
NON BLOQUANT — Les modifications critiques (extraction par `git archive`, gestion repensée de la pagination) ne disposent d'aucune couverture de test dans cette PR, mais l'absence de tests est justifiée puisque la spécification repousse délibérément leur création à la story 0.9.

###### 🏗️ Couche propre au projet
NON BLOQUANT — Les critères d'acceptation de la story 0.8 sont tous entièrement satisfaits (abandon du mode `--dangerously-skip-permissions`, exclusion de `.git` par l'utilisation de `git archive`, tolérance du fichier de motifs), sans vider l'intention initiale de la spécification.
NON BLOQUANT — Aucune information privée, aucun mot de passe ou jeton sensible (`GITEA_TOKEN`), et aucun hôte spécifique n'est exposé en clair ni commité dans l'historique de cette PR.
NON BLOQUANT — Les fichiers de procédure (notamment `verify-and-merge-pr.md`, `llm-review.md` et `check-private.md`), les compétences et les scripts reflètent et documentent fidèlement les comportements identiques : aucune anomalie de synchronisation n'est constatée.
NON BLOQUANT — Le changement est en accord total avec les directives inscrites dans `AGENTS.md` et se plie aux décisions techniques de la maquette d'architecture (AD-24).
NON BLOQUANT — Dans les scripts shell durcis, aucune erreur ne se dissimule silencieusement sous `set -euo pipefail` : chaque état de sortie risqué (comme avec `jq -e` ou `grep -q`) est contrôlé par une condition structurée ou géré par un fallback explicite tel que `|| die`.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur les revues du code de la PR n° 13 :

- `36949fd` (pass) :
  - refus de commande shell signalé seulement quand la réponse est vide : corrigé (`a429f87`), le refus de permission est cherché dès que le jeton manque, sur décision d'Arnaud ;
  - noms de liens et de dossiers à saut de ligne imprimés bruts dans l'empreinte : corrigé (`a429f87`), `printf %q` ;
  - absence de tests : écarté, story 0.9.
- `a429f87` (pass) : confirmations seulement ; défaut de l'outil révélé par cette revue, la réflexion du relecteur publiée en entier parce que le rapport partait de la première ligne contenant le jeton : corrigé (`c21afd2`), départ à la dernière ligne qui n'est que le jeton ; bloc du fichier de story nettoyé avant commit, commentaire de la PR laissé tel quel, sur décision d'Arnaud.
- `c21afd2` (pass) : aucun constat, confirmations seulement.

Constats de l'auteur : la timeline de la forge répond `null` et non une liste vide au-delà de la dernière page, trouvé en rejouant la boucle contre la forge avant tout commit et corrigé dans `2a614a2` ; `agy --sandbox` ne protège pas un `.env` sur ce poste (essai d'isolement ci-dessus).

Constats de la rétrospective fermés par cette story (`_bmad-output/implementation-artifacts/epic-0-retro-2026-09-15.md`, section « Constats ») :

| Code | Fermé par | Preuve |
|---|---|---|
| S11 | `2a614a2`, `b6e7610`, `a429f87`, `c21afd2` | copie exportée sans `.git` ni `.env` ni `docs/private/` ; empreinte avant et après la revue ; relecteur sans commande shell après l'essai du faux `.env` ; revues de la PR n° 13 menées de bout en bout dans ces conditions |
| D1 | `2a614a2` | boucle du script rejouée contre la forge sur la PR n° 11, pages de 2, 4 et 50 : 4 rapports ; plafond dépassé en code 2 ; audit de la PR n° 13 ouverte |
| D2 | `2a614a2` | fichier de commentaires et lignes blanches : « chemins seulement » dans `check-private.sh`, refus dans les trois scripts ; fichier illisible refusé |
| D3 | `2a614a2` | motif présent seulement sous `scripts/`, trouvé depuis `_bmad-output/`, chemin de motifs relatif compris |
| D5 | `2a614a2` | titre avec antislash, guillemets, `$`, accent grave et tabulation identique après le script et `jq` |
| S5 | `2a614a2` | décision du verrou CI rejouée sur huit états |
| P3 | `2a614a2` | `docs/procedures/verify-and-merge-pr.md`, verrou 1 : état « non fusionnable » transitoire après un push |
| P5 | `2a614a2`, `c21afd2` | `docs/procedures/llm-review.md`, « Rapports dans le fichier de story » et étape 11 |

## Reporté

- Lecture commune du suivi de sprint (D4, D7), tests des scripts (P1) et section « Pièges connus » : story 0.9.
- D6 (codes de sortie hétérogènes) : hors périmètre, décision d'Arnaud à la rétrospective de l'epic 0.
