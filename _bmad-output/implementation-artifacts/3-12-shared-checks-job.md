# Story 3.12 : Shared checks job

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.12.

## Revue de spec

### 19/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `5c3ea3b`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 72fd18739068e29926556deb

**Plan d'exécution** : Contenu classifié comme document de comportement (docs). Exécution des lentilles `adversarial`, `structure` et `prose`.

##### 🛡️ Lentille : Adversarial (Chasseur de failles)

- **Localisation** : Ligne 19 (`Critères d'acceptation`, premier scénario)
  **Condition** : `docker run` sur une image Alpine avec installation `apk` à la volée, suivi d'un build Hugo dans un répertoire monté depuis l'hôte.
  **Problème** : L'installation par `install-tools.sh` via `apk add` requiert que le conteneur tourne en tant que `root`. En conséquence, les répertoires générés sur le montage hôte par `scripts/check.sh` (ex. `build/` et `public/`) appartiendront à l'utilisateur `root` de la machine hôte.
  **Correction suggérée** : Préciser le mécanisme de gestion des permissions (ex. passer l'UID/GID de l'hôte au conteneur pour faire un `chown` des fichiers générés à la fin de l'exécution, ou utiliser `su-exec` après l'installation).
  **Conséquence** : Impossible de faire un `git clean` ou de supprimer les fichiers générés localement (ainsi que sur le runner Gitea) sans utiliser `sudo`.

- **Localisation** : Ligne 19 (`Critères d'acceptation`, premier scénario)
  **Condition** : Lancement de `docker run` sur `CHECK_IMAGE`.
  **Problème** : `CHECK_IMAGE` n'existe pas dans l'environnement courant du script shell hôte par défaut.
  **Correction suggérée** : Expliciter que `scripts/ci/checks-job.sh` doit sourcer ou extraire `CHECK_IMAGE` depuis `tools.env` sur l'hôte avant l'appel à Docker.
  **Conséquence** : Échec du script avec un nom d'image vide ou manquant.

- **Localisation** : Ligne 19 (`Critères d'acceptation`, premier scénario)
  **Condition** : "avec le dépôt monté"
  **Problème** : La commande n'est pas spécifiée et un chemin de travail est requis.
  **Correction suggérée** : Préciser le paramétrage du montage et du répertoire de travail (ex: `-v "$PWD:/workspace" -w /workspace`).
  **Conséquence** : Le conteneur se lancera à la racine `/` et ne trouvera pas les scripts.

- **Localisation** : Ligne 27 (`Critères d'acceptation`, Checkboxes)
  **Condition** : "CHECK_IMAGE fournit git et jq..."
  **Problème** : C'est factuellement faux par rapport à l'architecture. AD-1 indique clairement qu'Alpine ne les fournit pas nativement, c'est `install-tools.sh` qui les installe.
  **Correction suggérée** : Reformuler en "L'environnement préparé par `install-tools.sh` fournit git et jq...".
  **Conséquence** : Contradiction architecturale.

##### 🏗️ Lentille : Structure

- **Localisation** : Lignes 13 et 22-24 (`Opération manuelle` et deuxième scénario)
  **Condition** : L'opération manuelle est à "non", mais le scénario exige de tester "un clone jetable où un commit fait sans hook ajoute un fichier sous docs/private/".
  **Problème** : Ambiguïté sur la méthode de validation.
  **Correction suggérée** : Indiquer s'il s'agit d'un scénario de recette que le développeur doit valider manuellement avant sa PR, ou d'un test automatisé à ajouter dans `scripts/tests/run.sh`.
  **Conséquence** : Le développeur risque de perdre du temps à essayer d'automatiser un clone git jetable dans les tests unitaires si cela n'est pas attendu, ou à l'inverse d'oublier de le coder si c'est exigé.

##### 📝 Lentille : Prose

- **Localisation** : Ligne 19 (`Critères d'acceptation`, premier scénario)
  **Condition** : "le chargement de ci/legal-placeholder.env (dans le seul processus du conteneur)"
  **Problème** : La tournure est ambiguë sur la méthode d'injection technique.
  **Correction suggérée** : Remplacer par une formulation claire comme "l'injection du fichier factice à Docker via `--env-file ci/legal-placeholder.env`".
  **Conséquence** : Le développeur pourrait essayer de sourcer le fichier dans le script hôte ou de le copier.

---

##### À trancher avant d'implémenter

1. **Permissions sur l'hôte (Bloquant)** : L'installation par `apk` nécessite les droits `root` dans le conteneur, ce qui rendra l'hôte (et le runner CI) propriétaire `root` des dossiers générés (`build/`, `public/`). Comment résoudre ce conflit de permissions ? (ex: `chown -R` en fin de script dans le conteneur en lui passant les UID/GID, ou utilisation d'un utilisateur sans privilèges après installation).
2. **Récupération de `CHECK_IMAGE`** : Confirmes-tu que `checks-job.sh` est censé lire manuellement `tools.env` sur l'hôte pour obtenir la valeur de l'image avant l'appel à Docker ?
3. **Périmètre du test du clone jetable** : Ce scénario doit-il être automatisé dans `scripts/tests/run.sh` ou s'agit-il simplement d'un test exploratoire manuel à réaliser par le développeur avant de livrer la PR ?

### Triage (19/09/2026)

**Retenu — permissions sur l'hôte (bloquant).** `apk` exige root dans le conteneur, donc `public/` et
`build/`, écrits dans le dépôt monté, appartiendraient à root : le `scripts/check.sh` suivant, lancé
sur le poste, échouerait à vider `public/`. Arbitrage d'Arnaud (19/09/2026) parmi trois options
(redescendre au compte de l'hôte, `chown -R` en fin de conteneur, écrire les sorties hors du dépôt) :
**le conteneur redescend au compte de l'hôte** par `su-exec`, une fois les outils installés. Les
fichiers naissent avec le bon propriétaire, et un job interrompu ne laisse rien à réparer. `su-exec`
rejoint les paquets de `tools.env` et AD-1.

**Retenu — `CHECK_IMAGE` vient de `tools.env`.** Le script hôte lit le fichier par
`load_tools_env` (`scripts/lib/tools.sh`), comme `build.sh` et `install-tools.sh` : c'est la seule
déclaration des versions et de l'image (AD-1). Écrit dans les critères d'acceptation.

**Retenu — montage et répertoire de travail.** Le critère disait « avec le dépôt monté » sans dire
où : il nomme maintenant le montage et le répertoire de travail.

**Retenu — la case sur `git` et `jq` était fausse.** `alpine:3.24` ne les fournit pas ;
`install-tools.sh` les installe depuis `CHECK_PACKAGES`. La case est reformulée.

**Retenu — périmètre du clone jetable.** Arbitrage d'Arnaud (19/09/2026) parmi trois options (test
hors ligne sans Docker, test automatisé avec Docker, recette manuelle seule) : **le scénario C1
devient un test hors ligne de `scripts/tests/`**, qui monte le clone et vérifie que
`check-private.sh history` nomme le commit et le chemin ; la partie Docker est essayée à la main une
fois, et la recette est consignée dans `docs/procedures/checks-job.md`. La suite de tests reste hors
ligne et sans Docker (story 0.9).

**Refusé — injecter le fichier factice par `--env-file`.** AD-9 fait de `scripts/env.sh` le chargeur
unique des valeurs légales, et `build.sh` passe déjà par lui : il charge `ci/legal-placeholder.env`
de lui-même. Un `--env-file` ferait de Docker un second chargeur, à côté de celui qui sait refuser
une mise en ligne mal configurée. Le vrai risque que le critère visait est ailleurs : le dépôt est
monté tel quel, `.env` compris, et `env.sh` le lirait avant le fichier factice. Le conteneur désigne
donc `ENV_FILE` sur un chemin inexistant : les valeurs légales du job sont les valeurs factices, et
le `.env` du poste n'est jamais lu. Le critère le dit désormais ainsi.

### Réponses d'Arnaud (19/09/2026)

- **Propriétaire des fichiers générés** : le conteneur redescend au compte de l'hôte après l'installation, par `su-exec`. Les fichiers naissent avec le bon propriétaire, et un job interrompu ne laisse rien à réparer.
- **Scénario du clone jetable** : test hors ligne sans Docker dans `scripts/tests/`, plus une recette manuelle consignée dans `docs/procedures/checks-job.md`. La suite de tests reste hors ligne (story 0.9).

## Ce qui est livré

- `scripts/ci/checks-job.sh` — la part hôte : lit `CHECK_IMAGE` dans `tools.env` (AD-1), puis `docker run --rm` avec le dépôt monté sur `/repo`, `/repo` pour répertoire de travail, et l'UID et le GID de l'appelant. Le code du conteneur ressort tel quel : `1` écart, `2` anomalie.
- `scripts/ci/checks-job-container.sh` — la part conteneur, en sh POSIX de bout en bout, en deux temps : les outils en `root` par `install-tools-bootstrap.sh`, puisque `apk` l'exige, puis `su-exec` vers le compte de l'appelant pour le garde-fou en mode historique, `scripts/tests/run.sh` et `scripts/check.sh`. Chaque étape s'annonce : le garde-fou et les tests se taisent quand tout va bien, et un journal de CI muet ne dit pas ce qui a tourné.
- `tools.env` — `su-exec` rejoint `CHECK_BASE_PACKAGES`, `findutils` rejoint `CHECK_PACKAGES` (voir les deux divergences ci-dessous). AD-1 et AD-11 le disent aussi.
- `ENV_FILE` désigne dans le conteneur un chemin inexistant : le dépôt est monté tel quel, `.env` compris, et `scripts/env.sh` l'aurait lu avant le fichier factice. Les valeurs légales du job sont donc celles d'AD-9.
- `docs/procedures/checks-job.md` — la procédure, avec la recette manuelle et les deux pièges ; `poste-de-developpement.md` gagne une sixième vérification, `check.md`, `tools.md` et `shell-scripts.md` sont mis à jour.
- `scripts/tests/test-checks-job.sh` — 12 cas, sans Docker.

### Deux divergences trouvées par la première exécution du job

Elles ne pouvaient pas se voir sur le poste : c'est exactement ce que le job partagé est là pour attraper.

1. **`find -printf` n'existe pas chez BusyBox.** `scripts/tests/run.sh` s'en sert pour relever l'état de `public/` et de `build/` avant et après la suite (garde-fou F1 de la rétrospective de l'epic 2) : dans l'image, la suite s'arrêtait en anomalie. `findutils` rejoint `CHECK_PACKAGES`, comme `grep` GNU y est déjà, plutôt que d'écrire deux variantes du relevé.
2. **`xmllint` ne rend pas le même code pour « aucun nœud ».** libxml2 2.9 (le poste) rend `10` pour un résultat vide comme pour une requête mal écrite ; la 2.13 de `CHECK_IMAGE` sépare les deux (`11` vide, `10` requête invalide). `checks_xpath` n'acceptait que `0` et `10` : cinq contrôles tombaient en anomalie dans l'image. Les deux codes sont désormais tolérés, avec la raison écrite au-dessus de la fonction — les requêtes sont des littéraux, et les tests les rejouent toutes. Un fichier illisible rend `1` des deux côtés et reste une anomalie.

### Une faille de test, trouvée de la même façon

Deux cas de `test-checks-job.sh` supposaient leur environnement : l'un comptait sur l'absence d'`apk` (vraie sur le poste, fausse dans l'image, où il relançait le job entier), l'autre sur l'absence de `HOST_UID`, que le conteneur définit et dont le cas héritait. Les deux réduisent maintenant leur `PATH` et retirent nommément les variables. La règle est notée dans les pièges de `shell-scripts.md` : **un cas de test doit rendre le même verdict des deux côtés**.

### Essais

- `scripts/tests/run.sh` : 266 cas réussis sur le poste, et autant dans `CHECK_IMAGE`.
- `scripts/ci/checks-job.sh` : code 0, `check: 5 contrôle(s) passés`, et `find public build -printf '%u\n' | sort -u` ne montre que le compte de l'appelant — la bascule tient.
- Clone jetable : un commit fait sans hook qui ajoute `docs/private/note.md` fait échouer le garde-fou, qui nomme le commit court et le chemin (cas `checks_job_garde_fou_sur_un_clone_jetable`).

## Revue du code

### 19/09/2026 — `e6bf545` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 48. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9177d91066bb8982403e65cc

##### Revue de code (`bmad-review`)

**Plan d'exécution** : Contenu classifié comme code et documentation (diff mixte). Exécution séquentielle des lentilles `edge-case-hunter` et `verification-gap`.

###### 🛡️ Lentille : Edge-Case Hunter
Aucun cas aux limites ou chemin non géré n'a été détecté (par exemple, la présence, le format et l'intégrité de `HOST_UID` et `HOST_GID` sont correctement validés, et le code de sortie du conteneur est scrupuleusement préservé et renvoyé par l'hôte).

###### 🔍 Lentille : Verification Gap
No verification gaps found.

---

##### Constats propres au projet

- NON BLOQUANT — Les critères d'acceptation de la story sont entièrement satisfaits : l'appel à `docker run` monte le dépôt, utilise `CHECK_IMAGE` lue dans `tools.env`, bascule vers le compte hôte via `su-exec` après l'installation initiale en `root`, et `ENV_FILE` prévient la lecture du `.env` local.
- NON BLOQUANT — Aucune donnée privée, aucun secret, nom d'hôte ni adresse de serveur n'est commité. Aucun script n'affiche de secret ou d'adresse de forge.
- NON BLOQUANT — Les skills, procédures et scripts concordent parfaitement. La procédure `checks-job.md` détaille précisément le fonctionnement de `scripts/ci/checks-job.sh` et les pièges connus documentés (comme le contexte d'exécution des tests hors-image) sont accompagnés de tests correspondants.
- NON BLOQUANT — Le changement s'aligne fidèlement sur `AGENTS.md` et les décisions de l'architecture (`ARCHITECTURE-SPINE.md`), notamment sur la standardisation de l'environnement de contrôle défini par `AD-1`, `AD-11` et `AD-12`.
- NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe sous silence. L'usage approprié de `set -euo pipefail` dans l'hôte, de `set -eu` dans le script du conteneur, ainsi que la récupération sûre des codes d'erreur attendus (ex: `xmllint ... || rc=$?`) garantissent la robustesse de l'exécution.

VERDICT: NON BLOQUANT — aucune.

## Reporté
