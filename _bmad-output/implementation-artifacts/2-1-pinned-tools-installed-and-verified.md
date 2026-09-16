# Story 2.1 : Pinned tools installed and verified

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 2.1.

## Revue de spec

### 16/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `ad9f713`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 39539d0e4da47a1606b3656d

### Rapport de Revue (BMAD Review)

#### Lentille : Adversarial (Critique et cas limites)

| Emplacement | Condition déclenchante | Extrait de garde (solution) | Conséquence potentielle |
| :--- | :--- | :--- | :--- |
| Critères 2 et 4 | Le flag `--local` ne précise pas son comportement face aux paquets système. | Expliciter que le flag `--local` installe uniquement les binaires (Hugo/D2) et désactive la tentative d'installation via `apk`. | Échec de l'installation sur le poste développeur (ex: WSL/Ubuntu) où `apk` n'est pas disponible. |
| Critère 2 | Le conteneur s'appuie sur `CHECK_IMAGE` et utilise `apk` pour les dépendances. | Spécifier quelle est l'image parente (ex: `alpine:latest`) dont le digest est épinglé. | Épinglage d'une image inadaptée ou incompatible avec la gestion des paquets attendue. |
| Critère 3 | « Quand le script, puis la vérification commune [...], s'exécutent, Alors chacun échoue ». | Séparer le critère en deux scénarios : l'un testant l'échec de `install-tools.sh`, l'autre l'échec de la vérification de version. | Scénario de test confus et impossible à valider de bout en bout, car le premier échec (exit > 0) interrompt le flux. |
| Critère 3 | Échec sur une empreinte modifiée ou une version discordante dans le `PATH`. | Préciser la stratégie de réparation : le script échoue-t-il, ou bien écrase-t-il le binaire obsolète pour corriger l'état ? | Comportement indéterminé (ou faux positifs récurrents en local) lors d'une montée de version dans `tools.env`. |
| Implicite | `tools.env` est introuvable, mal formaté, ou vide. | Définir un cas d'erreur exigeant l'arrêt immédiat avec un message indiquant que le fichier source est introuvable. | Erreurs silencieuses, téléchargements cassés ou variables vides se propageant dans la CI. |
| Questions (l. 35) | La « fonction commune de vérification de version » n'a pas d'emplacement défini. | Répondre à la question et définir son chemin (ex. `scripts/lib/version.sh`) dans la spec. | Improvistion architecturale laissée au développeur. |

#### Lentille : Structure

- La structure BDD (Gherkin : Étant donné / Quand / Alors) est appliquée et les critères sont globalement testables.
- Le lien avec les dépendances (Epic 1) et les prérequis manuels est bien explicité.
- **Faiblesse** : Le couplage de deux mécanismes de validation distincts (le script d'installation CI/local d'un côté, et la fonction commune de vérification à l'exécution de l'autre) dans le même bloc de test (Critère 3) affaiblit la lisibilité et la traçabilité des cas d'erreur.

#### Lentille : Prose (Éditoriale)

- **Ambiguïté sur les valeurs** : « Alors elles ne sont déclarées que là : Hugo v0.166.0 et D2 v0.9.0 avec leur sha256 ». La formulation laisse un doute : le critère impose-t-il la présence de ces versions exactes à la virgule près pour réussir, ou s'agit-il simplement d'un exemple pour vérifier le mécanisme d'épinglage dans `tools.env` ?
- **Clarté syntaxique** : La proposition « chacun échoue en nommant l'outil et les versions » s'appliquant à deux exécutions séquentielles est lourde. Il serait plus fluide d'écrire : « le processus concerné échoue avec un message nommant l'outil et la version attendue face à la version trouvée ».

---

#### À trancher avant d'implémenter

- **Emplacement de la fonction commune** : Où doit vivre la fonction de vérification de version imposée par l'architecture ? (ex: `scripts/lib/version-check.sh` ?).
- **L'image de contrôle (`CHECK_IMAGE`)** : Faut-il acter et documenter qu'il s'agit d'une image basée sur Alpine, puisque le script de la story compte utiliser `apk` ?
- **Comportement de l'option `--local`** : Pouvons-nous confirmer que ce paramètre saute purement et simplement l'installation des dépendances OS (bash, git, grep, etc.), celles-ci étant déjà présentes sur le poste du développeur ?
- **Stratégie de résolution de conflit** : Si un vieux binaire Hugo/D2 existe localement avec un sha256 obsolète par rapport à `tools.env`, le script `install-tools.sh` doit-il forcer l'écrasement ou simplement échouer et demander une intervention manuelle ?

### Triage des constats (16/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — `--local` face aux paquets système | **retenu, déjà tranché ailleurs** | AD-1 dit qu'avec `--local` le script « installe seulement Hugo et D2 » : aucun `apk`. La story doit le dire au lieu de laisser deviner |
| A2 — image parente de `CHECK_IMAGE` | **retenu, déjà tranché ailleurs** | AD-1 et la table des versions disent `alpine:3.24` épinglée par digest ; à écrire dans le critère |
| A3 — critère 3 mêle deux mécanismes | **retenu** | à couper en deux : l'échec de `install-tools.sh` sur une empreinte qui ne correspond pas, et l'échec de la vérification de version à l'exécution |
| A4 — binaire local obsolète : échouer ou écraser | **retenu** | non tranché par l'architecture ; question à Arnaud |
| A5 — `tools.env` absent ou malformé | **retenu** | arrêt immédiat, code 2 (anomalie, convention du projet), message nommant le fichier et la variable manquante |
| A6 — emplacement de la fonction commune | **retenu** | c'est la question laissée ouverte par la spec ; proposition : `scripts/lib/`, où vivent déjà `gitea.sh`, `sprint.sh` et `merge-gates.sh`, avec ses cas dans `scripts/tests/` |
| Prose — versions exactes ou exemple | **retenu** | le critère doit dire que ce sont les valeurs épinglées, et qu'une montée de version se fait en modifiant `tools.env` seul |
| Prose — « chacun échoue » | **retenu** | réglé par la coupure du critère 3 |
| Structure | rien d'autre à reprendre | — |

Vérifications faites avant de répondre :

- les deux archives épinglées sont **réellement disponibles** : `hugo_0.166.0_linux-amd64.tar.gz` et `d2-v0.9.0-linux-amd64.tar.gz` répondent (HTTP 206 sur une requête d'un octet, sans téléchargement complet) ;
- l'opération manuelle de la story (« rendre Docker disponible dans le shell WSL ») est **déjà faite** depuis la story 0.8 : les tests de l'epic 1 ont tourné dans `alpine:3.24` et dans `gitea/gitea:1.27.3` sur ce poste.

## Ce qui est livré

| Fichier | Rôle |
| --- | --- |
| `tools.env` | seule déclaration : versions, archives, empreintes, image de contrôle par digest, trois listes de paquets |
| `scripts/lib/tools.sh` | `load_tools_env` (code 2 si le fichier ou une variable manque), `tool_version`, `require_tool_version` |
| `scripts/ci/install-tools.sh` | installe Hugo et D2 vérifiés par sha256 ; `--local` → `.tools/`, sans aucun `apk` |
| `scripts/ci/install-tools-bootstrap.sh` | amorçage sh POSIX de l'image de contrôle : pose `bash`, puis passe la main |
| `scripts/tests/test-tools.sh` | 14 cas, **hors ligne** : archives factices servies par `file://`, `apk` bouchonné pour l'amorçage |
| `docs/procedures/tools.md` | où vivent les versions, installer, vérifier, monter une version, pièges rencontrés |
| `.gitignore` | `.tools/` |

### Origine des empreintes (16/09/2026)

| Outil | Version | Empreinte recoupée avec |
| --- | --- | --- |
| Hugo | 0.166.0 | `hugo_0.166.0_checksums.txt` publié par le projet — identique au sha256 calculé sur l'archive téléchargée |
| D2 | 0.9.0 | `SHA256SUMS` publié par le projet — identique au sha256 calculé |
| Image de contrôle | `alpine:3.24` | digest relevé par `docker inspect --format '{{index .RepoDigests 0}}' alpine:3.24` |

### Deux blocages d'amorçage, trouvés en exécutant

L'image de contrôle est nue : ni `bash`, ni `curl`, ni certificats, et un `sha256sum` BusyBox.

1. **`bash` absent** : `install-tools.sh` ne pouvait pas démarrer dans l'image (`env: can't execute 'bash'`). D'où `install-tools-bootstrap.sh`, en sh POSIX, qui lit `CHECK_BOOTSTRAP_PACKAGES` dans `tools.env` (aucune déclaration en dur), pose `bash`, puis `exec`.
2. **`curl` absent** : les paquets s'installent donc **avant** tout téléchargement, et non après.

Un troisième, plus sournois : `sha256sum -c --status` n'existe pas dans BusyBox, et l'échec de l'option produisait le message « empreinte différente » — un message **faux**, qui aurait envoyé chercher un problème de sécurité au lieu d'un problème d'option. L'empreinte est maintenant calculée puis comparée par le script lui-même, ce qui marche des deux côtés, et le message dit la vérité.

### Essais

| Environnement | Ce qui a été lancé | Résultat |
| --- | --- | --- |
| Poste (WSL) | `install-tools.sh --local` | Hugo 0.166.0 et D2 0.9.0 dans `.tools/`, aucun paquet système touché |
| `CHECK_IMAGE` (image épinglée par digest) | `install-tools-bootstrap.sh` | Hugo et D2 dans `/usr/local/bin` ; `bash`, `git`, `jq`, `xmllint`, `pdftotext`, `pdfinfo` présents, `grep (GNU grep) 3.12` |
| Poste | `scripts/tests/run.sh` | **73 cas** (59 avant la story, 14 ajoutés) |
| `alpine:3.24` | `scripts/tests/run.sh` | **73 cas** |

Vérification du premier critère : aucune version ni empreinte n'est déclarée hors de `tools.env` — recherche des chaînes de version et des empreintes dans tous les `*.sh`, `*.yaml`, `*.yml` et `Dockerfile*` du dépôt, sans résultat.

## Revue du code

### 16/09/2026 — `4a45305` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 24. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 67654ee45ee6588e9c065e3f

##### Rapport de Revue (BMAD Review)

###### Lentille : Edge-Case Hunter
- NON BLOQUANT — `scripts/ci/install-tools-bootstrap.sh:15` | **Condition** : Fichier `tools.env` contenant des retours à la ligne DOS (CRLF) sous Windows | **Garde** : Ajouter `| tr -d '\r'` à l'extraction pour sécuriser le contenu lu | **Conséquence** : La commande `apk add bash\r` échouera et stoppera le script proprement, empêchant l'amorçage.

###### Lentille : Verification-Gap
- NON BLOQUANT — `scripts/ci/install-tools.sh:35` | **Condition** : Le parcours d'installation CI avec `apk add` (sans `--local`) n'est pas exécuté par les tests de `test-tools.sh` | **Garde** : Tester la logique `apk` avec une image factice ou déléguer cette preuve formellement à la CI | **Conséquence** : Une régression (ex: typo dans `CHECK_PACKAGES`) ne sera repérée qu'au lancement de la CI. | **Shape** : `regression-gap` | **Consumer** : Les runners exécutant l'image de contrôle.

##### Couche propre au projet

- NON BLOQUANT — Les critères d'acceptation de la story sont tous satisfaits (l'arrêt en code 2 est implémenté, les installations se font sans intervention, l'image est épinglée par digest).
- NON BLOQUANT — Aucune donnée privée, aucun secret, aucun nom d'hôte ou adresse de serveur local n'est commité ni affiché (uniquement des téléchargements publics sur GitHub).
- NON BLOQUANT — Le skill, la procédure `docs/procedures/tools.md` et les scripts concordent parfaitement ; chaque étape décrite correspond à la réalité du code.
- NON BLOQUANT — Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (usage strict d'`alpine:3.24`, `.tools` exclu du suivi git, `tools.env` en source unique de vérité).
- NON BLOQUANT — Aucune erreur silencieuse dans les scripts sous `set -euo pipefail` (toutes les commandes sensibles, y compris les vérifications de versions avec grep/`|| true`, contrôlent leur retour final).

VERDICT: NON BLOQUANT — aucune réserve majeure, l'implémentation est robuste et prête à être fusionnée.

Décisions de l'auteur sur la revue du code de la PR n° 24 :

- **CRLF dans `tools.env`** (`install-tools-bootstrap.sh`) : **corrigé dans cette PR** (décision d'Arnaud). `scripts/lib/tools.sh` protégeait déjà les lectures en bash (`line=${line%$'\r'}`) ; l'amorçage POSIX ne le faisait pas. Les deux chemins de lecture lisent maintenant pareil.
- **Chemin `apk` non couvert par les tests hors ligne** : reporté, voir ci-dessous.

### 16/09/2026 — `0ffd941` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 24. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: e6e31626c2ff39a3822bf47a

##### Rapport de Revue (BMAD Review)

###### Lentille : Edge-Case Hunter
- NON BLOQUANT — `scripts/lib/tools.sh` | **Condition déclenchante** : Espace invisible accidentel en fin de ligne dans une valeur de `tools.env` | **Garde** : Enlever les espaces finaux avant affectation, par exemple avec `value="${value%"${value##*[![:space:]]}"}"` | **Conséquence** : L'empreinte stockée contiendra l'espace et la comparaison stricte d'empreinte lors de l'installation échouera toujours.

###### Lentille : Verification-Gap
- NON BLOQUANT — `scripts/ci/install-tools-bootstrap.sh` | **Condition déclenchante** : Le script d'amorçage en sh POSIX `install-tools-bootstrap.sh` n'est testé par aucun des 10 cas de tests hors ligne ajoutés. | **Garde** : Ajouter un cas de test dans `test-tools.sh` exécutant ce script avec un exécutable `apk` factice (bouchonné). | **Conséquence** : Une typo ou régression dans la lecture de la variable d'amorçage ne sera détectée qu'au lancement réel de la CI. | **Shape** : `regression-gap` | **Consumer** : L'étape `tools` du `Dockerfile` et le conteneur de contrôle `CHECK_IMAGE`.

###### Couche propre au projet
- NON BLOQUANT — Les critères d'acceptation de la story sont tous satisfaits, sans que leur intention soit vidée (le fichier `tools.env` reste la seule source de vérité pour toutes les versions épinglées).
- NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (seules les URL de téléchargement GitHub publiques sont manipulées).
- NON BLOQUANT — Skill, procédure et script concordent : la procédure documentée dans `docs/procedures/tools.md` reflète rigoureusement le comportement codé des trois scripts implémentés.
- NON BLOQUANT — Le changement est parfaitement cohérent avec `AGENTS.md` et les décisions d'architecture (volonté de script simple, sans dépendance superflue, et validation scrupuleuse des empreintes sous `alpine:3.24`).
- NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (la sortie des commandes sensibles telles que `curl`, `sha256sum`, et `tar` est systématiquement attrapée via `||` pour déclencher une erreur explicite).

VERDICT: NON BLOQUANT — aucune

Décisions sur la deuxième revue (`0ffd941`), toutes deux corrigées dans cette PR :

- **espace en fin de valeur dans `tools.env`** : `load_tools_env` retire désormais les espaces de fin, comme `load_gitea_env` le fait pour `.env`. Sans cela, une espace invisible après une empreinte aurait produit un refus permanent, avec un message accusant l'archive ;
- **amorçage POSIX non testé** : quatre cas ajoutés, avec un `apk` bouchonné qui consigne ses arguments. Ils vérifient que la liste d'amorçage est lue dans `tools.env`, que les paquets sont posés **avant** tout téléchargement, que les binaires arrivent ensuite, et que l'amorçage s'arrête en code 2 sans lancer `apk` si la variable ou le fichier manque.

Ce second correctif **ferme l'entrée « Reporté » ouverte à la revue précédente** : le chemin `apk` est maintenant couvert hors ligne pour ce qui peut l'être (lecture des listes, ordre des étapes, passage de main). Ce qu'un bouchon ne prouve pas — que les paquets existent vraiment dans l'index d'Alpine — reste prouvé par l'exécution réelle dans `CHECK_IMAGE`, consignée plus haut, et le sera à chaque PR par la story 3.12.

### 16/09/2026 — `212885b` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 24. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 869bce7f0be4d638056bd9ff

##### Rapport de Revue (BMAD Review)

###### Lentille : Edge-Case Hunter
- NON BLOQUANT — `scripts/ci/install-tools.sh` | **Condition déclenchante** : Les variables de noms d'archives (`HUGO_ARCHIVE`, `D2_ARCHIVE`) issues de `tools.env` pourraient contenir des caractères de traversée de chemin (ex: `../`), écrivant ainsi hors du répertoire temporaire sécurisé `$tmp`. | **Garde** : Utiliser `archive=$(basename "$3")` au début de la fonction `install_tool()`. | **Conséquence potentielle** : Écriture d'un fichier hors du dossier temporaire lors du téléchargement si le nom de l'archive était altéré.

###### Lentille : Verification-Gap
- NON BLOQUANT — `scripts/ci/install-tools.sh` | **Condition déclenchante** : L'échec de la vérification des prérequis de base (`curl`, `tar`, `sha256sum`) n'est pas couvert par les tests hors ligne de `test-tools.sh` (qui tournent dans un environnement de test où ces outils vitaux sont déjà présents). | **Garde** : Ajouter un cas de test avec un `PATH` restreint (ou sans ces binaires) pour prouver que `tools_die` est bien appelé avec le message approprié. | **Conséquence potentielle** : Une régression sur la détection initiale de ces dépendances passerait inaperçue lors des tests jusqu'à une exécution sur un système réellement non préparé. | **Shape** : `edge-case-gap` | **Consumer** : Les développeurs exécutant le script sur un nouveau poste.

##### Couche propre au projet

- NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (tout est testé localement, l'option `--local` évite les paquets système, le remplacement en cache se fait sans erreur, et `tools.env` reste l'unique vérité).
- NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur local, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge. L'image de contrôle (Alpine) est publique et les binaires sont téléchargés directement via les releases GitHub publiques.
- NON BLOQUANT — Skill, procédure et script concordent : la documentation `docs/procedures/tools.md` décrit fidèlement le comportement exact implémenté par les scripts, de l'amorçage à la vérification.
- NON BLOQUANT — Le changement est cohérent avec AGENTS.md et les décisions d'architecture (installation légère, stricte indépendance des outils de rendu, configuration centralisée dans `tools.env`).
- NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail (les exceptions comme `unset` de variables read-only ou les `grep` sans correspondance attrapent rigoureusement leur échec via des alternatives `||`, et les sous-shells sh POSIX contrôlent sémantiquement les résultats vides).

VERDICT: NON BLOQUANT — aucune

Décisions sur la troisième revue (`212885b`), verdict `pass` : les deux constats sont **reportés**, par une limite posée avec Arnaud — chaque passe trouve une chose vraie mais mineure, et la PR doit se fermer. Ni l'un ni l'autre n'est atteignable sans modifier `tools.env`, un fichier commité, relu et couvert par les verrous de fusion.

### 16/09/2026 — `fafc357` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 24. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a32c48793deef22de4a2bc23

##### Rapport de Revue (BMAD Review)

###### Lentille : Edge-Case Hunter
- NON BLOQUANT — `scripts/lib/tools.sh` | **Condition déclenchante** : Le binaire `hugo` ou `d2` ne parvient pas à s'exécuter (ex: dépendance système manquante) et affiche une erreur sur `stderr`. | **Garde** : L'instruction `out=$("$bin" version 2>/dev/null)` ignore silencieusement `stderr`, transformant un crash système en une simple « version illisible ». Logger `stderr` en cas d'échec permettrait d'exposer la vraie cause. | **Conséquence potentielle** : Perte de temps au débogage car le message d'erreur natif du binaire est perdu.

###### Lentille : Verification-Gap
- NON BLOQUANT — `scripts/tests/test-tools.sh` | **Condition déclenchante** : L'échec du gestionnaire de paquets (ex. dépôt indisponible, `apk add` en erreur) n'est pas couvert par les tests hors ligne. | **Garde** : Ajouter un cas de test avec un bouchon `apk` qui retourne un code d'erreur (`exit 1`) pour valider l'arrêt strict de `install-tools-bootstrap.sh` et de `install-tools.sh`. | **Conséquence potentielle** : Une régression future dans la capture d'erreur d'`apk add` passerait inaperçue lors des tests locaux. | **Shape** : error-path-gap | **Consumer** : Les exécutions de la CI (conteneur de contrôle et Dockerfile).

##### Couche propre au projet

- NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (le script d'amorçage POSIX répond intelligemment à la nudité de l'image alpine tout en honorant l'esprit de l'installation centralisée).
- NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (seules des URL de téléchargement GitHub publiques sont manipulées).
- NON BLOQUANT — Skill, procédure et script concordent : la documentation `docs/procedures/tools.md` décrit fidèlement et exactement la mécanique implémentée (amorçage, base, contrôle) ainsi que les spécificités de `--local`.
- NON BLOQUANT — Le changement est parfaitement cohérent avec `AGENTS.md` et les décisions d'architecture (installation locale dans `.tools/` non suivie, isolation stricte, source de vérité unique `tools.env`).
- NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Bien que `install-tools-bootstrap.sh` soit en sh POSIX, il effectue un contrôle explicite de non-vacuité de la variable lue (`[ -n "$packages" ]`), et les retours de commandes sensibles (`curl`, `sha256sum`, `tar`, `apk`) sont systématiquement attrapés pour stopper l'exécution.

VERDICT: NON BLOQUANT — aucune

## Reporté

- source_spec: `_bmad-output/implementation-artifacts/2-1-pinned-tools-installed-and-verified.md`
  summary: `install_tool` écrit l'archive sous le nom donné par `HUGO_ARCHIVE` ou `D2_ARCHIVE` sans le réduire à son nom de base : un nom contenant `../` écrirait hors du dossier temporaire. Parade : `archive=$(basename "$3")`.
  evidence: Angle edge-case-hunter de la revue du code de la PR n° 24 (`212885b`). Portée réelle limitée : ces valeurs viennent de `tools.env`, fichier commité et relu, et quiconque peut l'éditer peut déjà exécuter ce qu'il veut. À reprendre à la prochaine story qui touche `scripts/ci/install-tools.sh`.

- source_spec: `_bmad-output/implementation-artifacts/2-1-pinned-tools-installed-and-verified.md`
  summary: L'arrêt du script quand `curl`, `tar` ou `sha256sum` manque n'est pas couvert par un cas de test : les tests tournent là où ces outils existent.
  evidence: Angle edge-case-hunter de la revue du code de la PR n° 24 (`212885b`). Un cas avec un `PATH` restreint le couvrirait. À reprendre à la prochaine story qui touche `scripts/ci/install-tools.sh`.
