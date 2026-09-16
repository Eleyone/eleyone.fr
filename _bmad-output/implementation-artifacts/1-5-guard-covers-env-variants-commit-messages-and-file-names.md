# Story 1.5 : Guard covers env variants, commit messages and file names

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 1.5.

## Revue de spec

### 16/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `aa63ffe`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 136cb32d2834fdd9d73ce7a7

##### Lentille : Adversarial (Cas limites, Failles, Contradictions)

**1. Contradiction sur la définition des variantes `.env`**
- **Emplacement :** Section « Critères d'acceptation », 1er critère
- **Condition de déclenchement :** La spec demande de bloquer « tout autre fichier dont le nom commence par `.env` » mais d'admettre explicitement `.environment.md`.
- **Garde proposée :** Définir une règle d'exclusion stricte plutôt qu'un préfixe (ex. : l'expression `^\.env(\..+)?$`, qui cible `.env` suivi ou non d'un point et d'un suffixe).
- **Conséquence potentielle :** Le développeur va écrire une règle de préfixe qui bloquera par erreur `.environment.md`, ou devra deviner la regex exacte, entraînant un aller-retour en revue de code.

**2. Angle mort sur les contrôles du pre-commit (mode `staged`)**
- **Emplacement :** Section « Critères d'acceptation »
- **Condition de déclenchement :** Les critères couvrent le hook `pre-receive` et le mode `history` pour les nouvelles surfaces (noms de fichiers, variantes `.env`), mais omettent de préciser l'attendu pour le mode `staged` (qui ne peut pas vérifier le message de commit, mais peut vérifier les noms et fichiers ajoutés).
- **Garde proposée :** Ajouter un critère confirmant que le mode `staged` de `check-private.sh` doit lui aussi intercepter les variantes `.env` et les motifs dans les noms de fichiers.
- **Conséquence potentielle :** L'expérience développeur sera dégradée si le script en pre-commit laisse passer des fichiers interdits pour les voir ensuite refusés lors du push.

**3. Portée de la vérification des messages de commit (plage vs HEAD)**
- **Emplacement :** Section « Critères d'acceptation », 2e critère
- **Condition de déclenchement :** Le texte dit « quand un push apporte un commit dont le message... ». Or, un push contient souvent une série de nouveaux commits entre `oldrev` et `newrev`.
- **Garde proposée :** Préciser que le hook `pre-receive` doit vérifier les messages de *tous* les commits de la plage poussée, et non seulement le commit de tête.
- **Conséquence potentielle :** Le hook pourrait ignorer des données privées cachées dans le message d'un commit intermédiaire d'une PR fusionnée en local.

**4. Critère de performance invérifiable**
- **Emplacement :** Check-list, 4e puce
- **Condition de déclenchement :** L'exigence « l'audit doit rester utilisable » n'est pas mesurable et dépendra de la machine.
- **Garde proposée :** Assortir cette exigence d'un seuil chiffré vérifiable (ex. : "le surcoût sur l'audit complet est inférieur à 1 seconde" ou "le script s'exécute en moins de 3 secondes sur l'historique complet").
- **Conséquence potentielle :** Le reviewer n'aura aucune base objective pour valider cette case, ce qui pourrait causer des blocages lors de la revue du code.

##### Lentille : Structure (Organisation)

*Aucun constat. L'organisation du document en BDD, la séparation des préoccupations (contexte, dépendances, critères, check-list, questions) et les liens avec les décisions d'architecture (AD-12, AD-19) sont clairs et respectent les standards du projet.*

##### Lentille : Prose (Clarté, Ambiguïté)

**1. Détail d'implémentation prescrit dans les critères**
- **Emplacement :** Section « Critères d'acceptation », 5e critère
- **Condition de déclenchement :** La mention explicite de l'instruction shell `(case "$mode")`.
- **Garde proposée :** Exprimer l'intention métier (par exemple : "le mode est lu de manière stricte comme un argument positionnel, sans être perturbé par la présence ultérieure de drapeaux").
- **Conséquence potentielle :** Mêle les exigences fonctionnelles et les choix d'implémentation, contraignant inutilement le développeur sur la syntaxe.

---

##### À trancher avant d'implémenter

- **Règle des variantes `.env` :** Validez-vous une règle stricte (le fichier est `.env` ou commence par `.env.` avec un point) plutôt qu'un préfixe brut qui nécessiterait de lister `.environment.md` comme exception en dur ?
- **Périmètre du pre-commit (`staged`) :** Le pre-commit ne pouvant lire le message (qui n'existe pas encore), confirmez-vous qu'il doit bien vérifier les *noms de fichiers* et les *variantes `.env`* ?
- **Seuil de performance :** Quel seuil chiffré définira un audit « utilisable » pour la lecture des messages de commit (par ex. surcoût maximum toléré en secondes) ?
- **Réponse à vos questions en suspens de la spec :**
  - **Images (C20) :** Souhaitez-vous inclure un rejet temporaire des extensions d'images (`*.jpg`, `*.png`, `*.webp`) dans le hook en attendant la story 5.4, ou s'en tient-on à la discipline d'ici là ?
  - **Noms de fichiers :** La recherche des motifs interdits dans les noms de fichiers doit-elle se limiter au nom de base, ou s'appliquer au chemin complet ?

### Triage des constats (16/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — contradiction sur les variantes `.env` | **retenu** | le critère disait « tout fichier dont le nom commence par `.env` » *et* admettait `.environment.md`, qui commence par `.env` : contradiction réelle. La règle devient « le nom de base est `.env` ou commence par `.env.` » |
| A2 — angle mort du mode `staged` | **retenu** | le pre-commit doit refuser les mêmes chemins et les mêmes noms que le hook ; seul le message de commit lui échappe, puisqu'il n'existe pas encore |
| A3 — messages de **tous** les commits poussés | **retenu, précision** | le mode `pre-receive` parcourt déjà `git rev-list "$new" --not --all`, donc tous les commits nouveaux ; le critère doit le dire au lieu de le supposer |
| A4 — « l'audit doit rester utilisable » invérifiable | **retenu** | à remplacer par un seuil chiffré, mesuré sur l'historique complet et consigné dans ce fichier |
| P1 — `case "$mode"` prescrit dans un critère | **retenu en partie** | le critère exprime l'intention (le mode est lu une seule fois) et cite l'écriture attendue en exemple, pas comme exigence |
| Structure, prose | rien à reprendre | — |

Les deux questions que le relecteur renvoie (images d'ici la story 5.4, nom de base ou chemin complet) sont celles déjà posées dans la spec ; elles sont tranchées par Arnaud avant l'implémentation.

## Ce qui est livré

`scripts/check-private.sh` regarde désormais **quatre surfaces** : le contenu des fichiers, leur chemin, le chemin confronté aux motifs, et le message des commits. Le mode est lu une seule fois (`mode`), et l'aiguillage s'appuie sur cette lecture.

| Surface | `staged` | `history` | `pre-receive` | Ce que l'alerte montre |
| --- | --- | --- | --- | --- |
| Contenu d'un fichier | oui | oui | oui | commit, fichier, ligne, numéro de ligne du motif |
| Chemin interdit | oui | oui | oui | commit et chemin (aucun motif en jeu) |
| Chemin qui reprend un motif | oui | oui | oui | commit et numéro de ligne du motif ; **le chemin est masqué** |
| Message de commit | — (le message n'existe pas encore) | oui | oui, tous les commits nouveaux | commit et numéro de ligne du motif ; **le message est masqué** |

Chemins interdits, comparés sans tenir compte de la casse : `docs/private/`, `docs/context/`, `.env` seul ou suffixé, `assets/cv/*.pdf` (jusqu'à C21 dans le hook) et les extensions d'images (jusqu'à C20, story 5.4). Le SVG reste admis : les schémas D2 sont commités et se lisent comme du texte.

### Essais

Douze essais sur des dépôts jetables, hors du dépôt de travail, avant d'écrire les cas de test :

| Poussé | Attendu | Obtenu |
| --- | --- | --- |
| `.env.production`, `config/.env.local` | refusé | refusé, chemin nommé |
| `.environment.md`, `env.example`, `docs/env.md` | admis (NFR-9) | admis |
| `photo.PNG` | refusé | refusé, casse ignorée |
| `schema.svg` | admis | admis |
| Motif dans le message d'un commit non-tête | refusé | refusé, message masqué |
| Motif dans un nom de fichier, puis dans un nom de dossier | refusé | refusé, chemin masqué |
| Motif dans le contenu | refusé | refusé (témoin, comportement inchangé) |
| Rien d'interdit | admis | admis |

Huit cas de test ajoutés à `scripts/tests/test-check-private.sh` (une surface par cas, plus les admissions NFR-9) : `scripts/tests/run.sh` passe **59 cas**, contre 51 avant la story.

### Deux exceptions nommées, trouvées en lançant l'audit

L'interdiction des extensions d'images et celle des `.env` suffixés ont d'abord fait **échouer l'audit de l'historique réel**. Deux cas légitimes s'y opposaient :

- **`.env.example`** : commité par conception (AGENTS.md, point 5), il liste les noms de variables sans aucune valeur. Ma règle « `.env` seul ou suffixé » le refusait — la revue de spec parlait de `env.example`, le fichier réel s'appelle `.env.example`.
- **`design/<branche>/screenshots/`** : les **35 captures** des branches `design/suisse`, `design/dossier-architecture`, `design/cv-suisse` et `design/cv-dossier-architecture`. Ce sont les seules images de tout l'historique, déjà publiées sur GitHub, produites par un navigateur, et hors du périmètre de C20 (`assets/images/` et `public/`).

Les deux sont donc des exceptions nommées, retirées **après** la recherche des chemins interdits, avec leur propre code d'erreur : une erreur de `grep` sur l'exception fait échouer le garde-fou au lieu d'élargir ce qui passe. Une image ajoutée ailleurs (`assets/images/portrait.webp`) reste refusée, vérifié par un essai et par un cas de test.

**Point à trancher un jour, noté ici** : ces 35 captures ont été publiées sans jamais passer C20, qui n'existait pas. Elles sortent du périmètre de la story 5.4 (`assets/images/` et `public/`). À voir avec Arnaud si C20 doit un jour les couvrir, sachant qu'elles sont déjà publiques et accessibles par leur SHA.

### Rejoué là où le hook tourne

| Environnement | Périmètre | Résultat |
| --- | --- | --- |
| Poste (bash, grep GNU) | tous les fichiers de test | **59 cas réussis** |
| `alpine:3.24` | tous les fichiers de test | **59 cas réussis** |
| `gitea/gitea:1.27.3` (BusyBox grep, l'environnement réel du hook) | `test-check-private.sh`, `test-gitea-hook.sh` | **32 cas réussis** |

Les options employées par les nouvelles recherches (`grep -E -i`, `grep -q -i -F -f`, `grep -E -i -v`) existent donc aussi dans le `grep` de BusyBox : le hook ne dépend pas de GNU.

### Coût de la lecture des messages

Mesuré sur le poste, sur l'historique complet (34 commits), moyenne de trois audits : **1,30 s avant**, **1,53 s après**, soit **0,23 s de surcoût** — sous le seuil d'une seconde fixé à la revue de spec. La lecture du message se fait par commit déjà parcouru, sans passe supplémentaire sur l'arbre.

### Documents mis à jour

- `AGENTS.md` : le hook serveur et le miroir sont au présent, avec le dépôt public nommé et le renvoi aux deux procédures ; la phrase « le garde-fou *devrait* tourner en pre-receive » devient ce qu'il fait, et la conséquence est écrite (un contrôle qui ne vit qu'en CI arrive après la publication).
- AD-12 : les quatre surfaces, les deux interdictions temporaires et leur levée.
- AD-19 : C20 bloquant **aussi** dans le hook, avec l'outil de lecture des métadonnées là où tourne Gitea.
- `docs/procedures/check-private.md`, `docs/procedures/gitea-pre-receive-hook.md`, `.claude/skills/check-private/SKILL.md` : mêmes règles, au niveau de détail de chaque document.
- `docs/procedures/shell-scripts.md` : le piège d'ancre qui a dupliqué `epics.md` (action 6 de la rétrospective de l'epic 1).
- Story 5.4 : critère ajouté (C20 appelé par le hook, interdiction des extensions d'images levée).

## Revue du code

### 16/09/2026 — `bf5f49e` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 21. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f28cc97ebefc6bcc9ec6bc35

**Classe de contenu :** Diff (Code et Docs)
**Lentilles exécutées :** `edge-case-hunter`, `verification-gap`, couche propre au projet

##### Lentille : Edge-Case Hunter
Aucun cas limite non géré n'a été trouvé (`[]`). Les cas implicites (comme les exceptions `.env.example` et les captures des branches de design) sont traités de façon sécurisée par exclusion, sans élargir la surface permise en cas d'erreur de la commande `grep`. Les extensions d'images et variantes de `.env` sont exhaustivement prises en compte.

##### Lentille : Verification-Gap
No verification gaps found. Les scénarios de test rajoutés couvrent rigoureusement les nouveaux comportements attendus (variantes de `.env`, exceptions de chemins, filtrage de messages de commits, gestion du mode `staged`).

##### Couche propre au projet
- NON BLOQUANT : **Critères d'acceptation** — Tous les critères d'acceptation de la story sont satisfaits (le mode `staged` est correctement limité, tous les nouveaux commits de la plage sont vérifiés, et les variantes d'environnement sont gérées).
- NON BLOQUANT : **Données privées et secrets** — Aucune donnée n'a fuité. Les chemins reprenant un motif ainsi que les messages de commits fautifs sont explicitement masqués dans la sortie d'erreur des scripts.
- NON BLOQUANT : **Concordance** — Le skill, la procédure et le script concordent totalement. Les quatre surfaces de contrôle et les conditions exactes de leur application sont bien documentées.
- NON BLOQUANT : **Cohérence d'architecture** — Les règles ajoutées respectent `AGENTS.md` ainsi que les contraintes AD-12 et AD-19 de l'architecture.
- NON BLOQUANT : **Résilience (`set -euo pipefail`)** — Aucune erreur ne passe sous silence : toutes les commandes (notamment `grep` et `git log`) récupèrent leur code de sortie dans `prc` et `rc` afin d'éviter qu'un arrêt prématuré ne contourne les contrôles.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 21 :

- `bf5f49e` (pass) : aucun constat, confirmations seulement. Rien à reprendre.

## Reporté

Aucun constat reporté.

### Point laissé ouvert, hors périmètre de cette story

Les 35 captures des branches de design ont été publiées sans jamais passer C20, qui n'existait pas, et sortent du périmètre de la story 5.4 (`assets/images/` et `public/`). À trancher avec Arnaud, sans urgence : elles sont déjà publiques.
