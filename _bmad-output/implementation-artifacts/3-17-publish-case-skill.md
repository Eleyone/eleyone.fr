# Story 3.17 : Publish-case skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.17.

## Revue de spec

### 21/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `2aa3bcb`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1ca891342b66dffeaac72db5

### Rapport de revue BMAD

Ce document sert à définir les exigences du script de publication de cas (story 3.17) à l'intention de l'agent de développement. 
**Modèle de structure utilisé** : Définition de tâche (Functional).

#### Lentille : Adversarial

| Emplacement | Condition déclenchante | Correction / Garde-fou suggéré | Conséquence potentielle |
| :--- | :--- | :--- | :--- |
| Critères d'acceptation | Contradiction frontale avec AD-4 (D-3) concernant la publication du `_index` de groupe. | Suivre AD-4 (D-3) : le script doit automatiser le passage de l'`_index` en `draft: false` dans la même PR s'il s'agit du premier cas publié du groupe. | Le script rejettera systématiquement la publication du 1er cas d'un groupe, forçant une intervention manuelle contraire à D-3. |
| Critères d'acceptation | Oubli du `git push` avant l'appel du skill `create-pull-request`. | Ajouter une étape explicite de `git push origin <branche>` juste avant de solliciter l'ouverture de la PR. | Le script `create-pull-request` bloquera (Story 0.4 : "branche non poussée au même commit"). |
| Critères d'acceptation | Format de nommage de la branche `feat/*` non défini. | Fixer un modèle déterministe pour nommer la branche générée, par exemple `feat/publish-case-<translationKey>`. | Multiplication de noms de branches fantaisistes ou conflits si plusieurs cas sont publiés en parallèle. |
| Critères d'acceptation | Corps et titre de la PR non définis pour `create-pull-request`. | Expliciter la création d'un `.pr-body.md` temporaire et la génération du titre de la PR. | Échec de l'ouverture de la PR (titre manquant) ou PR publiée avec un corps vide/hors-sujet. |
| Critères d'acceptation | Manque de précision sur la découverte des fichiers du cas. | Préciser comment le script trouve avec fiabilité les fichiers `.fr.md` et `.en.md` (qui peuvent être à la racine de `content/cases/` ou dans un sous-dossier). | Le script risque d'échouer à localiser un cas enfoui dans un sous-groupe. |
| Critères d'acceptation | Méthode de modification du front matter non sécurisée. | Imposer l'usage d'un parseur ou d'une regex stricte (ex: avec `sed`) pour remplacer `draft: true` sans casser le reste du YAML. | Fichiers Markdown corrompus et pipeline de build Hugo cassé. |
| Critères d'acceptation | Risque de doublons dans `ci/release-pages.txt`. | Exiger une vérification de présence avant d'ajouter une clé : ne l'ajouter que si elle est absente. | Le fichier finit rempli de doublons si le développeur doit relancer le script. |
| Critères d'acceptation | Périmètre ambigu du contrôle sur les `[TODO`. | Préciser que le script cherche l'existence de `[TODO` uniquement dans les fichiers du cas ciblé (et son groupe éventuel). | Un `[TODO` présent dans un brouillon d'un autre cas bloquera la publication du cas actuel. |
| Critères d'acceptation | Modalité de lancement des contrôles initiaux non explicitée. | Définir s'il s'agit d'exécuter `scripts/check.sh` sur tout le projet avant d'entamer les modifications, ou d'un sous-ensemble de vérifications. | Le script s'exécute sur un dépôt déjà cassé, générant des faux-positifs complexes à analyser. |
| Checklist | Contenu du `SKILL.md` (directives d'usage) non précisé. | Indiquer la description attendue (ex: "À utiliser quand l'utilisateur demande à publier un cas") pour `.claude/skills/publish-case/SKILL.md`. | L'agent de développement ignorera quand l'utiliser de manière autonome. |

#### Lentilles Éditoriales : Structure et Prose

| Passe | Texte original | Texte révisé | Changements |
| :--- | :--- | :--- | :--- |
| structure | « afin de publier un cas sans oublier un contrôle. » | *SUPPRIMER* | Information redondante avec le contexte même de la story. |
| structure | Éléments de checklist : « Le script ne publie jamais le poste... » et « Pour un cas groupé... » | *FUSIONNER* dans les clauses **Alors** des critères d'acceptation. | Consolidation des règles d'échec au même endroit. L'éparpillement nuit à l'implémentation. |
| prose | « un `_index` encore en brouillon est signalé » | « fait échouer le script avec un message d'erreur mentionnant le `_index` en brouillon. » | Lève l'ambiguïté de "signalé" (l'agent LLM ne saurait pas s'il s'agit d'un warning silencieux ou d'une erreur bloquante). |
| prose | « passe les deux fichiers du cas en `draft: false` » | « remplace la valeur de `draft:` par `false` dans le front matter des fichiers `.fr.md` et `.en.md` du cas » | Ajout de précision technique explicite. |
| prose | « ou qu'un `[TODO` reste » | « ou qu'un marqueur `[TODO` est encore présent dans les fichiers du cas ciblé » | Sécurisation du contexte (le lecteur LLM doit s'assurer que c'est restreint aux fichiers locaux ciblés). |

##### Résumé éditorial
- Recommandations totales : 5
- Impact : Gain immédiat en clarté fonctionnelle pour l'agent LLM (suppression d'ambiguïtés majeures sur les attentes techniques).

---

#### À trancher avant d'implémenter

- **Contradiction sur la publication du `_index` de groupe** : La spec indique qu'il faut échouer en le signalant, or la décision D-3 d'AD-4 stipule que le `_index` doit passer en `draft: false` dans la *même* PR que le premier cas du groupe. Le script doit-il s'en charger ou ce point manuel reste-t-il à la charge de l'auteur ?
- **Mécanique de création de la PR** : Faut-il inclure un appel à `git push origin` explicite avant le `create-pull-request` ? De plus, sous quel format le script doit-il autogénérer le titre et le corps de cette PR (`.pr-body.md`) ?
- **Recherche de `[TODO`** : Le script doit-il rechercher les `[TODO` sur l'ensemble du dépôt ou exclusivement dans les fichiers `.fr.md` et `.en.md` du cas en cours de publication ?
- **La question de la story en attente** : La relecture humaine (exigée par le format) est-elle une étape de confirmation bloquante dans le script, ou simplement une checklist case de la PR ? (Réponse requise).

### Triage (21/09/2026)

**Retenu, et c'est le constat qui valait la revue — la story se contredisait avec D-3.** Sa case « le script ne publie pas le `_index` du groupe » rendait le **premier cas d'un groupe impubliable par le script**, alors que D-3 veut le `_index` et le premier cas dans la **même PR** (AD-4, stories 10.4 et 10.5). Arbitrage d'Arnaud (21/09/2026) : **le script passe aussi le `_index` hors brouillon** quand il publie le premier cas du groupe, et le nomme dans son résumé et dans le corps de la PR.

**Retenu — la relecture humaine devient un drapeau.** Arbitrage d'Arnaud (21/09/2026) parmi trois options (drapeau explicite, case dans la PR, question interactive) : `--relu`. Sans lui, le script fait tous les contrôles, affiche ce qu'il changerait, et **ne modifie rien**. L'acte humain est explicite, reste dans l'historique du terminal, et un agent ne peut pas le franchir par inadvertance. Ce même drapeau couvre le `_index` du groupe, qui part avec le cas.

**Retenu — le poste du cas reste à part.** Le script ne publie jamais le poste ; un poste en brouillon fait échouer la publication et le script le nomme. C'est vrai aujourd'hui du cas pilote : `position-chiliz` est en brouillon, donc `publish-case case-02` refusera tant que la story qui publie le poste n'est pas passée.

**Retenu — les fichiers du cas se trouvent par le manifeste, jamais par un chemin deviné.** Le rendu de travail liste tout `content/` avec le rôle, la clé de traduction, le brouillon, le groupe, le poste et la présence de `[TODO` (AD-10). Un cas enfoui dans un sous-dossier se trouve donc sans règle de chemin.

**Retenu — `[TODO` ne se cherche que dans les fichiers concernés.** Le manifeste porte déjà le drapeau par fichier : le script regarde le cas et son `_index`, pas le reste du dépôt. Un brouillon voisin qui garde ses `[TODO` ne bloque pas une publication qui ne le touche pas — et `scripts/check.sh`, relancé après la modification, refuserait de toute façon un `[TODO` devenu public (C5).

**Retenu — la mécanique de la PR est écrite.** Branche `feat/publish-case-<clé>`, `git push` avant l'appel de `create-pull-request` (la story 0.4 exige une branche poussée au même commit), titre et corps engendrés par le script, le corps nommant les fichiers passés hors brouillon et les clés ajoutées.

**Retenu — pas de doublon dans `ci/release-pages.txt`.** Une clé n'est ajoutée que si elle est absente, ce que la story disait déjà et qu'un cas de test garde.

**Retenu — la modification du front matter est bornée.** Seule la ligne `draft:` du **front matter** est réécrite, entre les deux `---`, et le script vérifie qu'il a bien changé une ligne et une seule par fichier. Un `draft:` cité dans le corps du texte n'est pas touché.

**Retenu — les contrôles tournent avant et après.** `scripts/check.sh` d'abord, sur l'état courant : rien n'est modifié si le dépôt est déjà en écart, et les faux positifs ne se mélangent pas. Puis de nouveau après la modification, avant le push : c'est lui qui juge le cas devenu public.

**Retenu — la décision est séparée de l'exécution.** Comme pour les verrous de fusion, la logique qui lit les manifestes et décide quoi publier vit dans `scripts/lib/publish-case.sh`, éprouvée par des manifestes écrits à la main ; le script fait le build, les contrôles, git et la forge. Sans cela, aucun cas de test hors ligne n'est possible.

**Retenu — la description du SKILL.md dit quand l'employer**, comme les autres skills du dépôt.

**Refusé — supprimer « afin de publier un cas sans oublier un contrôle ».** C'est la finalité de la story, pas une redite : le script existe parce qu'une publication à la main oublie un contrôle.

### Réponses d'Arnaud (21/09/2026)

- **Relecture humaine** : un drapeau explicite, `--relu`. Sans lui, le script contrôle tout, montre ce qu'il changerait, et ne modifie rien. L'acte humain reste dans l'historique du terminal, et un agent ne peut pas le franchir par inadvertance.
- **Page du groupe** : le script la publie avec le premier cas du groupe, et le dit. C'est ce que D-3 exige — les deux dans la même PR —, et la story disait l'inverse.

## Ce qui est livré

- `scripts/lib/publish-case.sh` — la décision : lit les deux manifestes du rendu de travail, rend un plan (`case=`, `index=`, `release=`) ou refuse en nommant l'écart et le fichier. N'écrit rien, n'appelle ni git ni la forge.
- `scripts/publish-case.sh` — l'exécution : arbre propre, `scripts/check.sh` avant, plan, puis (avec `--relu`) branche, réécriture du front matter, `ci/release-pages.txt`, commit, `scripts/check.sh` après, push, PR.
- `.claude/skills/publish-case/SKILL.md` et ses deux liens, `docs/procedures/publish-case.md` — les trois niveaux.
- `scripts/tests/test-publish-case.sh` — 17 cas sur des manifestes écrits à la main, dont les trois niveaux et les liens.

### Ce que le script refuse aujourd'hui, pour de vrai

`scripts/publish-case.sh case-02` sur le dépôt tel qu'il est :

```
publish-case: contrôles sur l'état courant…
publish-case: le poste « position-chiliz » est encore en brouillon (career/position-chiliz.fr.md) :
publish-case ne le publie pas à la place de la story qui en a la charge (C19).
```

C'est le critère d'acceptation, joué sur l'état réel du dépôt : le cas pilote ne peut pas être publié tant que son poste est un brouillon.

### Deux choix d'écriture

**La réécriture est bornée au front matter**, entre les deux premiers `---`, et le script compte les lignes `draft: false` avant et après : exactement une de plus, sinon il s'arrête sans rien remplacer. Un `draft:` cité dans le corps d'un cas ne risque rien.

**La règle « partir de dev » ne vaut qu'au moment de créer la branche.** Écrite en tête, elle aurait interdit de *consulter* le plan depuis une branche de travail — alors que ce premier temps ne modifie rien. Constaté en essayant le script sur lui-même.

### Essais

- `scripts/tests/run.sh` : 309 cas réussis.
- `scripts/check.sh` : 5 contrôles passés.
- `scripts/publish-case.sh case-02` : refus attendu, sur l'état réel du dépôt.

## Revue du code

### 21/09/2026 — `6a6ba9b` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 53. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 08ac9c82e2272d27034a9c1c

##### Rapport de revue BMAD

###### Lentille : Edge-case-hunter

- **Emplacement :** `scripts/publish-case.sh` (réécriture du front matter)
  **Condition déclenchante :** Un fichier contient `draft: true` avec un commentaire sur la même ligne (ex: `draft: true # à valider`).
  **Garde-fou suggéré :** L'expression régulière `awk` (`/^draft:[[:space:]]*true[[:space:]]*$/`) ne correspondra pas à la ligne car elle n'admet aucun autre caractère.
  **Conséquence potentielle :** Le script échouera de manière propre et sécurisée lors de la vérification finale (`((apres == avant + 1))`), avec le message d'erreur indiquant un "front matter inattendu". L'arrêt est totalement sous contrôle.
  **Classification :** NON BLOQUANT

- **Emplacement :** `scripts/publish-case.sh` (récupération de la branche courante)
  **Condition déclenchante :** Le script est lancé depuis un état "detached HEAD" pointant sur le commit de `dev`.
  **Garde-fou suggéré :** La commande `git branch --show-current` renverra une chaîne vide et/ou échouera (code 1).
  **Conséquence potentielle :** Le script s'arrête immédiatement ("branche courante illisible" ou lors de la comparaison de branche), évitant la création de branches de publication dans un état incertain.
  **Classification :** NON BLOQUANT

- **Emplacement :** `scripts/publish-case.sh` (modification des fichiers en boucle)
  **Condition déclenchante :** La réécriture `awk` échoue sur le deuxième fichier de la liste (par exemple l'`_index` du groupe).
  **Garde-fou suggéré :** Aucun garde-fou technique supplémentaire nécessaire, le comportement actuel est pertinent.
  **Conséquence potentielle :** L'arbre de travail restera partiellement modifié, car le script s'arrête avant le commit. Un simple `git restore` permet à l'utilisateur de retrouver un dépôt propre.
  **Classification :** NON BLOQUANT

###### Lentille : Verification-gap

- **Emplacement :** `scripts/publish-case.sh` (écriture dans `ci/release-pages.txt`)
  **Condition déclenchante :** Le fichier `ci/release-pages.txt` ne se termine accidentellement pas par un retour à la ligne.
  **Garde-fou suggéré :** Garantir la présence d'une nouvelle ligne avant d'utiliser la redirection de concaténation `>>` ou s'appuyer sur la standardisation des fichiers du dépôt (ex: règle d'éditeur).
  **Conséquence potentielle :** Le premier élément ajouté serait concaténé à la fin de la dernière ligne existante, ce qui créerait une clé invalide et fausserait la vérification.
  **Classification :** NON BLOQUANT

- **Emplacement :** `scripts/publish-case.sh` (ouverture de la PR)
  **Condition déclenchante :** L'appel final à `scripts/create-pull-request.sh` échoue, par exemple suite à un problème réseau passager.
  **Garde-fou suggéré :** Aucun, le script s'appuie logiquement sur l'arrêt automatique.
  **Conséquence potentielle :** Grâce au `set -e`, le script s'arrête avant le `printf` de succès final. L'erreur du sous-script est bien transmise à l'utilisateur, et la branche locale ainsi que son push sur la forge sont déjà effectifs, préservant ainsi le travail réalisé.
  **Classification :** NON BLOQUANT

##### Couche propre au projet

- **Critères d'acceptation :** Les critères de la story 3.17 sont tous respectés de façon stricte. L'intention fonctionnelle est préservée : gestion du double temps par `--relu`, inclusion explicite de l'`_index` pour les cas groupés, refus systématique de publier un poste encore en brouillon, et exécution des contrôles avant et après modification.
  **Classification :** NON BLOQUANT

- **Données privées et secrets :** Aucune donnée privée, aucun nom d'hôte et aucune adresse serveur ou forge n'est introduit ou manipulé. Le script utilise l'alias implicite et sécurisé `origin`.
  **Classification :** NON BLOQUANT

- **Concordance skill / procédure / script :** L'alignement est complet. Le fichier `SKILL.md`, la documentation `docs/procedures/publish-case.md` et les retours d'exécution décrivent fidèlement les mêmes commandes et comportements, y compris les codes de sortie.
  **Classification :** NON BLOQUANT

- **Architecture et principes (`AGENTS.md`) :** La modification respecte scrupuleusement la séparation fonctionnelle avec la décision confinée dans `scripts/lib/publish-case.sh`. L'outillage imposé est respecté (`jq`, `awk` et `grep` sans extension).
  **Classification :** NON BLOQUANT

- **Gestion des erreurs (Bash / `set -euo pipefail`) :** Sous l'option stricte de Bash, aucune erreur ne passera en silence. Les commandes comme `grep -c` qui peuvent échouer de manière attendue (code 1 quand 0 résultat) sont parfaitement sécurisées par l'affectation défensive `|| rc=$?` et la validation ultérieure de `rc`.
  **Classification :** NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

#### Décisions sur ces constats (21/09/2026)

Dix constats, tous non bloquants, et huit d'entre eux disent que le comportement actuel est déjà le bon — le script s'arrête proprement, `set -e` fait son office, l'arbre reste réparable par un `git restore`. Deux appelaient un geste :

- **Retenu — `ci/release-pages.txt` sans saut de ligne final.** La première clé ajoutée se serait collée à la dernière ligne, créant une clé invalide que la vérification de doublon n'aurait pas vue. Le script ajoute le saut manquant avant d'écrire, et un cas de test rejoue l'idiome dans les deux sens.
- **Retenu — le message du front matter inattendu.** Une ligne `draft: true` suivie d'un commentaire ne correspond pas au motif : le script s'arrêtait bien, mais sans dire ce qu'il attendait. Le message donne désormais la forme attendue et rappelle que rien n'a été remplacé.

### 21/09/2026 — `05416a2` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 53. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c50d52c1bf600a72e9f8c365

##### Rapport de revue BMAD

###### Lentille : edge-case-hunter

**Emplacement :** `scripts/publish-case.sh` (réécriture du front matter)
**Condition déclenchante :** Plusieurs lignes `draft: true` sont présentes à l'intérieur du front matter du fichier à publier.
**Garde-fou snippet :** L'implémentation compte précisément les occurrences avec `grep -c` avant et après la modification (`apres == avant + 1`).
**Conséquence potentielle :** Le script s'arrête proprement avec une erreur claire ("front matter inattendu"), empêchant la corruption du fichier Markdown et l'altération involontaire de plusieurs paramètres.
Classification : NON BLOQUANT

**Emplacement :** `scripts/publish-case.sh` (récupération de la branche courante)
**Condition déclenchante :** Le script est invoqué avec le drapeau `--relu` depuis un commit spécifique ("detached HEAD") au lieu d'une branche locale.
**Garde-fou snippet :** La vérification stricte `[[ $branche_courante == dev ]]` après exécution de `git branch --show-current`.
**Conséquence potentielle :** La procédure s'interrompt immédiatement de manière sécurisée en indiquant que la publication doit partir de la branche `dev`.
Classification : NON BLOQUANT

###### Lentille : verification-gap

**Emplacement :** `scripts/publish-case.sh` (écriture dans `ci/release-pages.txt`)
**Condition déclenchante :** Le fichier de suivi `ci/release-pages.txt` ne se termine pas par un retour à la ligne.
**Garde-fou snippet :** Le test `[[ -s $pages_file && $(tail -c 1 "$pages_file") == "" ]]` détecte l'absence de retour à la ligne et effectue un `printf '\n' >> "$pages_file"`.
**Conséquence potentielle :** La clé générée est correctement ajoutée sur une nouvelle ligne, empêchant l'écriture d'une clé fusionnée avec la dernière ligne existante, ce qui casserait les validations ultérieures.
Classification : NON BLOQUANT

##### Couche propre au projet

**Critères d'acceptation :**
L'ensemble des critères de la story 3.17 sont satisfaits de manière rigoureuse. Le processus par étapes (décision puis exécution), la gestion sécurisée du retrait du statut de brouillon, la gestion coordonnée des cas de groupe (incluant `_index.{fr,en}.md`), et l'usage explicite de l'argument `--relu` garantissent que l'intention des critères d'acceptation est parfaitement préservée.
Classification : NON BLOQUANT

**Données privées et secrets :**
La PR ne contient et n'expose aucun hôte, adresse de serveur ou clé privée. Le script interagit localement et utilise les alias standards de Git (ex: branche `dev`). 
Classification : NON BLOQUANT

**Concordance skill / procédure / script :**
La définition du skill `SKILL.md`, la documentation `docs/procedures/publish-case.md` et les scripts d'exécution concordent parfaitement sur les fonctionnalités attendues, les comportements sans et avec l'argument `--relu`, et les messages ainsi que les codes d'erreur renvoyés.
Classification : NON BLOQUANT

**Cohérence avec AGENTS.md et décisions d'architecture :**
L'architecture de script en séparant la logique de décision (`scripts/lib/publish-case.sh`) de l'exécution (`scripts/publish-case.sh`) suit parfaitement les précédentes implémentations, favorise la testabilité hors ligne, et respecte l'obligation de départ de la branche de développement dictée par le workflow linéaire d'`AGENTS.md`.
Classification : NON BLOQUANT

**Robustesse des scripts shell (`set -euo pipefail`) :**
Le mode strict Bash est activé en début de script. Les commandes susceptibles de renvoyer un code de sortie non nul de façon légitime (comme `grep -c` ne trouvant aucune occurrence) sont neutralisées par précaution (`|| rc=$?`) et testées ensuite, s'assurant qu'aucune erreur inattendue ne passe sous silence et ne provoque un comportement indéfini.
Classification : NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

## Reporté
