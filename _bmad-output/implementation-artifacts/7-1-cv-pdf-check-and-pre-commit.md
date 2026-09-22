# Story 7.1 : CV PDF check and pre-commit

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 7.1.

## Revue de spec

### 22/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `cf039ae`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 75fe17a96695aabbf0091a50

##### Rapport de revue de spécification (Story 7.1)

**Lentille Adversarial & Gaps (Edge cases et failles)**

*   **BLOQUANT** — **Absence de `poppler-utils` en local :** Le script `pdf.sh` doit s'exécuter dans le hook local `.githooks/pre-commit`. Il s'appuie sur `pdfinfo` (et implicitement `pdftotext`), qui font partie du paquet `poppler-utils`. Or, l'architecture (AD-1) précise que `install-tools.sh --local` n'installe que Hugo et D2 en local, et `AGENTS.md` (AD-24) ne liste pas `poppler-utils` dans les prérequis de la machine de développement. Le hook de pre-commit échouera donc systématiquement en local avec une commande introuvable, bloquant les commits.
*   **BLOQUANT** — **Intégration manquante dans `scripts/check.sh` :** Un critère d'acceptation mentionne le comportement du script sur GitHub (vérification sans liste de motifs). Or, `scripts/check.sh` est le point d'entrée unique de la CI (AD-10). La spec ne demande nulle part d'appeler ou de sourcer `scripts/checks/pdf.sh` depuis `check.sh`. Sans cela, le contrôle C21 ne sera jamais déclenché lors des passages CI sur Gitea ou GitHub.
*   **BLOQUANT** — **Mode de transmission de la liste des motifs :** La spec demande de tester le script "avec la liste des motifs" ou "en l'absence de liste (GitHub)", mais ne précise pas comment le script trouve ce fichier. S'il utilise un chemin en dur, il échouera dans les environnements où la liste n'est pas présente. L'utilisation de la variable `PRIVATE_PATTERNS_FILE` (comme le fait `check-private.sh`) doit être explicitée.
*   **NON BLOQUANT** — **Outil d'extraction de texte implicite :** La spec mentionne nommément `pdfinfo` pour les métadonnées et XMP, mais dit seulement "extraie le texte" pour le contenu. Pour éviter que l'agent n'essaie d'utiliser `grep` sur un binaire (qui est bloqué par `grep -I` dans le garde-fou), il serait plus robuste de spécifier l'utilisation de `pdftotext`.
*   **NON BLOQUANT** — **Règle des 500 Ko non justifiée :** Le critère de la taille limite fixée à 500 Ko n'est pas sourcé dans l'architecture. AD-8 précise que le budget de page de 200 Ko ne s'applique pas aux PDF du CV, qui sont comptés hors budget. C'est un bon garde-fou, mais c'est une règle nouvelle introduite par la story.

**Lentille Structure**

*   **BLOQUANT** — **Démonstration du pre-commit et blocage mutuel :** La spec pose une question pertinente à la fin : tant que le chemin `assets/cv/*.pdf` est interdit par AD-21, `check-private.sh staged` bloquera le commit avant ou en même temps que `pdf.sh`. Si l'ordre d'exécution n'est pas défini, la vérification du comportement de `pdf.sh` en situation réelle de pre-commit est impossible à démontrer sans contourner temporairement les règles. 

**Lentille Prose**

*   **NON BLOQUANT** — **Formulation des assertions :** Le critère "il passe, passe, puis échoue" (pour les cas "aucun PDF, puis les deux, puis un seul") est compréhensible mais gagnerait à être explicite pour guider l'agent d'implémentation sur le comportement exact (vérification de la règle "ensemble ou rien" d'AD-21).

##### À trancher avant d'implémenter

*   **Prérequis locaux pour le pre-commit :** Faut-il ajouter `poppler-utils` aux prérequis explicites de la machine de dev (dans `AGENTS.md`), faire évoluer `install-tools.sh` pour l'installer en local, ou exécuter le contrôle de `pdf.sh` via Docker (`CHECK_IMAGE`) lors du pre-commit ?
*   **Intégration CI :** Confirmez-vous que l'appel à `scripts/checks/pdf.sh` doit être ajouté à l'intérieur de `scripts/check.sh` pour garantir son exécution sur GitHub et Gitea ?
*   **Méthode de démonstration :** Comment le développeur doit-il prouver le fonctionnement de `pdf.sh` dans le hook `pre-commit` (ex: dépôt jetable, ordre précis dans le hook pour afficher la sortie de `pdf.sh` avant l'échec garanti par `check-private.sh`) ?

### Tri de l'auteur (22/09/2026)

Quatre constats bloquants : deux tombent sur vérification, deux sont retenus, dont celui que la spec elle-même réservait à Arnaud.

**Refusé, parce que déjà vrai — l'intégration dans `check.sh`.** Le relecteur écrit que sans appel explicite, C21 ne tournera jamais en CI. `scripts/check.sh:50` découvre `"$root"/scripts/checks/*.sh` et lance tout ce qu'il y trouve, `lib.sh` excepté — c'est écrit dans son en-tête : « une story qui ajoute un contrôle ne modifie pas ce script ». La story 6.3 vient de le prouver : `typo.sh` a fait passer le compte de 6 à 7 contrôles sans une ligne d'appel. Le critère le dit désormais, pour que personne n'ajoute un appel en double.

**Retenu — le chemin de la liste des motifs.** Constat juste : la story disait « avec la liste des motifs » sans dire comment le script la trouve, ce qui invite un chemin en dur. Elle nomme maintenant `PRIVATE_PATTERNS_FILE`, la variable que `check-private.sh` emploie déjà.

**Retenu — `poppler-utils` absent des prérequis.** `pdftotext` et `pdfinfo` sont sur le poste en 24.02.0 et dans l'image de CI, mais `AGENTS.md` ne les liste pas : un clone frais aurait un pre-commit qui échoue sur une commande introuvable. Arnaud tranche pour le **prérequis déclaré**, contre l'installation par `install-tools.sh` (qui pose des binaires épinglés en archive, pas des paquets de distribution) et contre l'exécution via Docker (qui rendrait un commit tributaire d'un démon qui tourne). Un critère ajouté exige en outre que le script sorte en **code 2** s'ils manquent, jamais en 0 : un PDF non lu ne doit pas passer pour un PDF propre.

**Retenu — le blocage mutuel au pre-commit.** C'est la question que la spec posait. Tant que `assets/cv/*.pdf` est un chemin interdit, `check-private.sh staged` refuse tout PDF indexé avant que `pdf.sh` ait parlé. Arnaud tranche : **`pdf.sh` passe en premier dans le hook**, et la démonstration se fait sur un dépôt jetable où la règle de chemin est retirée, comme les essais du hook pre-receive. Les deux autres voies lui ont été présentées avec leur coût — un ordre non pensé (le jour où l'interdiction tombera, un PDF qui contient vraiment un téléphone se verrait reprocher son chemin), et la levée immédiate de l'interdiction (AD-21 la lie à C21 **dans le hook pre-receive**, et entre les deux un PDF privé poussé par un poste sans hook local passerait, le miroir publiant en quelques secondes).

**Retenus — les trois non bloquants.** `pdftotext` est nommé pour l'extraction du texte, là où la story disait seulement « extraie le texte ». Le seuil de 500 Ko est sourcé : il est propre à cette story, AD-8 sortant les CV du budget de page. Et « il passe, passe, puis échoue » dit maintenant ce qu'il vérifie — la règle « ensemble ou rien » vaut pour le contrôle et pas seulement pour les liens.

## Revue du code

### 22/09/2026 — `9407581` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 84. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9b55a3fe23f0606d3e6c20bd

**Plan de revue** : Contenu classé comme `diff`. Exécution des lentilles `edge-case-hunter` et `verification-gap`.

##### Lentille Edge-Case Hunter

* **location** : `scripts/checks/pdf.sh:251` (boucle `for nom in "${attendus[@]}"; do`)
  * **trigger_condition** : Un fichier PDF inattendu (autre que `cv-fr.pdf` et `cv-en.pdf`) est ajouté dans `assets/cv/`
  * **guard_snippet** : `for nom in "$cv_dir"/*.pdf; do [[ -f $nom ]] || continue;` (et vérifier s'il fait partie des attendus)
  * **potential_consequence** : Un PDF avec des données privées est ignoré et non vérifié

##### Lentille Verification-Gap

* **location** : `scripts/tests/test-pdf.sh:449`
  * **trigger_condition** : Le test d'intégration du pre-commit vérifie le code source du hook par de simples expressions régulières au lieu de l'exécuter
  * **guard_snippet** : Exécuter un vrai `git commit` dans un `git init` jetable pour observer le comportement réel du hook
  * **potential_consequence** : Une erreur de syntaxe ou d'exécution dans le hook échapperait au test
  * **gap_shape** : `broken-verification-gap`
  * **consumer** : `scripts/tests/test-pdf.sh:449`
  * **evidence** : `test-pdf.sh:455` utilise `cat "$hook"` et `assert_contains` sur le texte source au lieu de simuler un commit

##### Couche propre au projet

- BLOQUANT : Le critère d'acceptation exigeant que "le pre-commit se démontre sur un dépôt jetable" n'est pas satisfait. Le test `case_pdf_le_pre_commit_lance_c21_avant_le_garde_fou` se contente d'un `cat` sur le script, vidant l'intention du critère (prouver le comportement en situation réelle).
- BLOQUANT : Dans `.githooks/pre-commit`, une erreur fatale de `git diff` passe en silence. Placé directement dans le `if` (`if git diff ... | grep ...; then`), un plantage de `git diff` masque son code de sortie sous `set -euo pipefail`. La condition devient fausse et le contrôle C21 est ignoré sans alerte.
- NON BLOQUANT : `AGENTS.md` est correctement mis à jour avec les prérequis `poppler-utils` de la machine de développement.
- NON BLOQUANT : Aucune donnée privée, hôte ou secret n'est commité, le script masque correctement les motifs par leur numéro de ligne.

VERDICT: BLOQUANT — Critère de test sur dépôt jetable non respecté et erreur potentiellement silencieuse (git diff) masquée dans le hook pre-commit.

### Décisions de l'auteur sur la revue du code de la PR n° 84

Trois constats, tous retenus.

**Retenu, et c'est le pire des trois — une erreur de `git diff` avalée par le `if`.** J'avais écrit `if git diff --cached … | grep -qzE …; then`. Un plantage de git rend la condition fausse, et C21 est sauté **sans un mot**. C'est exactement la classe d'erreur que ce dépôt traque partout — `shell_grep`, `checks_find`, `checks_xpath` existent pour ça — et je l'ai écrite dans le seul fichier qui n'en bénéficiait pas, faute d'y charger la bibliothèque. La liste est maintenant lue d'abord, avec son code, et un échec sort en code 2.

**Retenu — le critère du dépôt jetable n'était pas satisfait.** J'avais fait la démonstration à la main et l'avais consignée dans le corps de la PR ; le cas de test, lui, se contentait d'un `cat` sur le hook et d'un ordre de lignes. Le relecteur a raison sur le fond : une erreur de syntaxe ou un plantage à l'exécution y échappait, et le critère demandait une démonstration, pas une relecture.

Le cas monte désormais un dépôt jetable, y pose le vrai hook, et tente un **vrai commit** : un PDF porteur d'un motif dans ses métadonnées est refusé par C21, aucun commit n'est créé, le motif n'apparaît pas ; puis un PDF propre passe. Un second cas vérifie que C21 ne se réveille pas pour un commit sans fichier de `assets/cv/`.

Éprouvé deux fois. Avec une erreur de syntaxe dans le hook : le cas échoue, ce qu'un `cat` n'aurait jamais vu. Avec l'ordre inversé : le cas échoue en montrant précisément le mauvais diagnostic que l'arbitrage voulait éviter — « chemin privé » pour un PDF dont le vrai défaut est un téléphone dans ses métadonnées.

**Retenu — un fichier inattendu dans `assets/cv/`.** La boucle ne parcourait que les deux noms d'AD-21 : un `cv-ancien.pdf` oublié là, avec un téléphone dedans, n'était lu par personne. Tout fichier autre que les deux attendus est désormais refusé — plutôt que contrôlé, parce qu'il n'a rien à faire là et que le dire est plus utile que de le lire.

### 22/09/2026 — `6c1b881` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 84. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 36c9339cad2560d95109cfda

##### Revue bmad-review

**Lentille Edge-Case Hunter**

BLOQUANT — location: `.githooks/pre-commit:32` | trigger_condition: Un fichier indexé dans `assets/cv/` contient des caractères spéciaux (ex: non-ASCII), `git diff` l'entoure de guillemets. | guard_snippet: `grep -qE '^"?assets/cv/' <<< "$indexes" || rc=$?` | potential_consequence: Le chemin (débutant par `"`) ne correspond plus au regex `^assets/cv/`, le contrôle C21 est sauté silencieusement.

**Lentille Verification-Gap**

NON BLOQUANT — location: `.githooks/pre-commit:32` | trigger_condition: Aucun test ne simule l'indexation d'un fichier avec des caractères non-ASCII ou une configuration `core.quotePath` active. | guard_snippet: `pdf "$depot/assets/cv/cv-é.pdf"` | potential_consequence: La faille du regex ignorant les fichiers avec guillemets n'est détectée par aucune vérification. | gap_shape: `regression-gap` | consumer: `.githooks/pre-commit:32` | evidence: `scripts/tests/test-pdf.sh` ne teste que les noms strictement ASCII `cv-fr.pdf`, `cv-en.pdf` et `cv-ancien.pdf`.

##### Couche propre au projet

BLOQUANT — Dans `scripts/checks/pdf.sh:303`, l'appel `if printf '%s\n' "$extrait" | grep -q -i -F -e "${entry#*:}"; then` masque silencieusement une éventuelle erreur fatale de `grep` (code 2), laissant passer une erreur en silence sous `set -euo pipefail` (une récurrence de la faille de condition corrigée par l'auteur sur git diff).
NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (dépôt jetable, ordre d'exécution dans le hook, vérification de l'absence de poppler-utils en erreur).
NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et les motifs testés ne sont jamais fuis ou affichés.
NON BLOQUANT — Skill, procédure et script concordent.
NON BLOQUANT — Le changement est cohérent avec `AGENTS.md` (ajout documenté de `poppler-utils` aux prérequis de la machine de développement) et l'architecture.

VERDICT: BLOQUANT — Erreur de grep passée en silence dans pdf.sh (condition if masquant le code 2) et contournement silencieux du hook pre-commit pour les noms de fichiers avec caractères spéciaux.

### Décisions de l'auteur sur la deuxième revue du code de la PR n° 84

Deux constats bloquants, tous deux retenus — et **tous deux de la classe que je venais de corriger dans la même PR**. C'est le fait marquant de cette story, plus que le contrôle lui-même.

**Retenu — un chemin non-ASCII saute le hook.** `git diff --cached --name-only` cite et échappe en octal tout chemin non-ASCII : `assets/cv/café.pdf` sort en `"assets/cv/caf\303\251.pdf"`, le motif `^assets/cv/` ne colle plus, et C21 est sauté **en silence**. C'est mot pour mot le trou que la rétrospective de l'epic 5 avait fermé dans le garde-fou (constat B5, `core.quotePath=false`) — une leçon écrite, appliquée là où elle avait mordu, et **jamais reportée dans le script neuf**. Corrigé, avec un cas de test qui pose un `cv-café.pdf` et échoue sans le correctif.

**Retenu — `if printf … | grep -q …` avale un code 2.** Dans la boucle qui cite les motifs par leur numéro de ligne, un `grep` en erreur se lisait « pas trouvé », et le motif aurait manqué sans un mot. La deuxième occurrence était **à trois lignes de la première**, celle du hook que je venais de corriger au tour précédent. `shell_grep` s'en charge désormais : il meurt dès que grep dépasse 1.

**Ce que ces deux-là disent.** J'ai corrigé une erreur avalée par une condition, puis j'en ai laissé deux autres dans le même fichier et la même PR. Une correction ponctuelle ne cherche pas ses sœurs ; une leçon écrite dans `AGENTS.md` ne se reporte pas d'elle-même dans le script suivant. À porter à la rétrospective de l'epic 7 : **quand une revue trouve une erreur d'une classe connue, le correctif commence par chercher les autres occurrences de cette classe dans le même changement.**

**Les quatre non bloquants sont des confirmations**, y compris que les critères de la story sont satisfaits sans que leur intention soit vidée — dépôt jetable, ordre du hook, absence de poppler-utils en anomalie.

### 22/09/2026 — `c5d0dd9` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 84. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: bab7a3ca4cdf806d23d5b250

**Revue BMAD**

##### Lentille Edge-Case Hunter

BLOQUANT — location: `.githooks/pre-commit:32` | trigger_condition: Un CV PDF est supprimé de l'index (ex: `git rm assets/cv/cv-en.pdf`), laissant le second fichier seul. Le filtre `--diff-filter=ACMR` exclut les suppressions (`D`). | guard_snippet: `git -c core.quotePath=false diff --cached --name-only --diff-filter=ACDMR` | potential_consequence: La suppression d'un PDF échappe au pre-commit, permettant de créer localement un commit qui brise la règle « ensemble ou rien » sans déclencher de contrôle.

##### Lentille Verification-Gap

BLOQUANT — location: `.githooks/pre-commit:32` | trigger_condition: Aucun test ne vérifie que le pre-commit s'active lors de la suppression d'un fichier suivi dans le répertoire `assets/cv/`. | guard_snippet: `git rm "$depot/assets/cv/cv-en.pdf" && git commit -q -m "suppression"` | potential_consequence: La faille du filtre excluant les suppressions n'est pas couverte et échappe aux validations. | gap_shape: `regression-gap` | consumer: `scripts/tests/test-pdf.sh:case_pdf_le_pre_commit_ne_lance_c21_que_pour_assets_cv` | evidence: Le test s'assure que le hook ne se lance pas pour l'ajout d'un fichier extérieur, mais aucun cas ne vérifie son déclenchement (et l'échec attendu de C21) sur une suppression.

**Couche propre au projet**

BLOQUANT — Le critère d'acceptation de la story stipulant que "Quand un fichier de assets/cv/ est indexé / Alors il lance pdf.sh d'abord" est rompu : un fichier supprimé de l'index n'est pas vu par le filtre `ACMR`, ce qui vide l'intention du contrôle d'interdire un CV isolé.
NON BLOQUANT — Le reste des critères d'acceptation sont satisfaits (dépôt jetable monté et fonctionnel pour tester le hook, absence de la liste de motifs bien gérée sur GitHub, gestion explicite de l'absence de `poppler-utils`).
NON BLOQUANT — Aucune donnée privée, nom d'hôte ou secret n'est commité, et aucun script ne peut afficher un motif factice, celui-ci étant masqué et signalé uniquement par son numéro de ligne.
NON BLOQUANT — Skill, procédure et script concordent parfaitement.
NON BLOQUANT — Le changement est cohérent avec `AGENTS.md` (qui documente correctement le nouveau prérequis machine de `poppler-utils`) et les décisions d'architecture (le piège précédent des fichiers non-ASCII est résolu à la source via `core.quotePath=false`).
NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (le code de sortie de `checks_find` est proprement propagé et l'erreur fatale de code 2 de `grep` a été corrigée via `shell_grep`).

VERDICT: BLOQUANT — Le filtre git du hook pre-commit exclut les fichiers supprimés (D), ce qui empêche C21 de détecter localement une rupture de la règle "ensemble ou rien".

### Décisions de l'auteur sur la troisième revue du code de la PR n° 84

**Retenu — supprimer un CV échappait au hook.** `--diff-filter=ACMR` exclut les suppressions. Retirer `cv-en.pdf` en gardant `cv-fr.pdf` casse « ensemble ou rien » aussi sûrement que d'ajouter un mauvais fichier, et le hook ne réveillait même pas C21. `D` est entré dans le filtre, avec un cas qui commite les deux CV puis en supprime un — refusé, C21 nomme la règle. Il échoue sans le `D`.

**Appliqué à moi-même, sans attendre un quatrième tour.** Plutôt que d'ajouter la lettre manquante au filtre, la question a été reprise à l'envers : **tout** ce qui touche `assets/cv/` dans l'index réveille C21, sans filtre de type de changement. Le contrôle lit le dossier tel qu'il est ; la nature du changement ne le regarde pas. `--no-renames` avec, parce qu'un renommage hors du dossier n'aurait montré que sa destination.

La même relecture a trouvé le jumeau du défaut dans le contrôle lui-même : `checks_find -maxdepth 1` ignorait un `assets/cv/vieux/cv.pdf`, exactement la même faute — borner la recherche à ce qu'on imagine. Deux cas de test écrits dans la foulée, un changement de type et un sous-dossier, tous deux éprouvés en remettant le filtre et la profondeur.

**Troisième tour, troisième trou dans le même fichier de dix-huit lignes.** Le hook a été repris trois fois : la condition qui avalait l'erreur de `git diff`, les chemins non-ASCII, les suppressions. Chaque correctif était juste et chaque fois incomplet, parce que je corrigeais **l'occurrence signalée** au lieu de reprendre la question que le constat posait — « qu'est-ce que ce filtre ne voit pas ? ». C'est le même défaut que la deuxième revue avait déjà nommé, appliqué au même endroit. La leçon pour la rétrospective de l'epic 7 en sort renforcée, et plus précise : **un constat sur une condition de déclenchement se traite en réénumérant tout ce que cette condition laisse passer**, pas en ajoutant le cas cité.

### 22/09/2026 — `fab81fa` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 84. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 24787beb5ce186d1d7512122

##### Lentille Verification-Gap

BLOQUANT — location: `.githooks/pre-commit:54` | trigger_condition: Un CV PDF contenant un motif privé est indexé, puis le fichier est nettoyé ou supprimé du répertoire de travail avant la validation du commit. | guard_snippet: Extraire le contenu des PDF depuis l'index (via `git cat-file`) vers un dossier temporaire et y diriger `pdf.sh`, au lieu de lire le répertoire de travail. | potential_consequence: Le hook `pdf.sh` analyse la version propre du répertoire de travail et passe au vert, validant l'intégration du PDF privé indexé dans l'historique (faille effective dès la levée future de l'interdiction de chemin). | gap_shape: `broken-verification-gap` | consumer: `.githooks/pre-commit:54` | evidence: L'appel à `pdf.sh` utilise les fichiers présents sur le disque (`CHECK_CV_DIR`). Le test d'intégration `case_pdf_le_pre_commit_lance_c21_avant_le_garde_fou` écrit dans le répertoire de travail et indexe ce même fichier sans jamais tester de divergence entre l'index et l'arbre de travail.

##### Couche propre au projet

BLOQUANT — Dans `scripts/check-private.sh` (lignes 169 et 204), la structure `if printf '%s\n' "..." | grep -q -i -F -e "${entry#*:}"; then` masque le code d'erreur 2 de `grep`. Si `grep` échoue de manière inattendue, la condition est simplement évaluée à faux et la boucle passe au motif suivant. Une erreur passe ainsi en silence sous `set -euo pipefail` et un motif privé présent dans un chemin ou un message de commit échapperait à la détection sans déclencher d'alerte (il s'agit de la récurrence exacte de la faille documentée et corrigée précédemment dans `pdf.sh`).
NON BLOQUANT — Le reste des critères d'acceptation est respecté et le test sur dépôt jetable démontre correctement l'ordre du hook (hors la divergence index/arbre abordée ci-dessus).
NON BLOQUANT — Aucune donnée privée, nom d'hôte ou secret n'est commité ou exposé en clair dans la sortie des scripts.
NON BLOQUANT — Les procédures, scripts et le fichier `AGENTS.md` sont mis à jour de manière cohérente (le nouveau prérequis de `poppler-utils` est explicitement documenté).

VERDICT: BLOQUANT — Le pre-commit vérifie le répertoire de travail au lieu de l'index pour les PDF, et une erreur de grep est passée sous silence dans check-private.sh.

### Décisions de l'auteur sur la quatrième revue du code de la PR n° 84

**Retenu, et c'est le constat le plus sérieux de la story — le hook lisait l'arbre de travail.** Indexer un PDF porteur d'un téléphone, puis nettoyer le fichier sur le disque, et C21 lisait la version propre : la version privée entrait dans l'historique, le contrôle au vert. Un pre-commit qui ne lit pas l'index ne contrôle pas ce qui va être commité.

Le hook extrait désormais les objets **de l'index** dans un dossier temporaire, comme le garde-fou le fait déjà pour passer C20 sur les images.

**Et mon correctif était faux, attrapé par mon propre cas de test.** J'extrayais les chemins *modifiés* : quand le changement était une suppression, le dossier temporaire se retrouvait **vide**, « ensemble ou rien » n'y voyait plus aucun CV au lieu d'en voir un seul, et le commit passait. Le cas du dépôt jetable — celui que la deuxième revue m'avait fait écrire — a refusé le correctif. C'est exactement ce pour quoi il existe : un test qui lance un vrai commit voit ce qu'une relecture ne voit pas. L'extraction porte maintenant sur **l'état complet de l'index** sous `assets/cv/`, le listage des changements ne servant qu'à réveiller le contrôle.

**Retenu — la même erreur avalée, deux fois, dans le garde-fou lui-même.** `check-private.sh` porte le même `if … | grep -q …` aux lignes 169 et 204, dans les boucles qui citent les motifs par leur numéro. C'est le fichier d'où j'avais copié l'idiome. Les deux sont corrigées : le code de grep est lu, et un code supérieur à 1 fait échouer avec un message, au lieu de se lire « pas trouvé ».

⚠️ **`scripts/check-private.sh` change : la copie de la forge sera périmée à la fusion.** Le correctif ne protège les pushs qu'une fois la procédure du hook rejouée (`docs/procedures/gitea-pre-receive-hook.md`, « Entretenir »). Seul ce fichier change ; `lib/image.sh` et le lanceur sont inchangés.

**Quatre tours, et le motif est le même à chaque fois.** Les quatre constats bloquants de cette story sont des variantes d'une seule question : **qu'est-ce que cette condition ne voit pas ?** Un `if` qui avale un code d'erreur, un filtre qui exclut un type de changement, un motif qui rate un chemin cité, une lecture qui prend l'arbre pour l'index. À la troisième, j'ai commencé à réénumérer au lieu de rustiner, et cela a évité un cinquième tour sur le filtre — mais pas celui-ci, parce que je n'avais pas posé la question à la *source* de la lecture. À porter à la rétrospective de l'epic 7.

### 22/09/2026 — `970f090` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 84. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d00e6cc5b861d23b2d45d7e7

##### Lentille Edge-Case Hunter

BLOQUANT — location: `.githooks/pre-commit:85` | trigger_condition: Le contrôle `pdf.sh` s'achève avec succès, et le script invoque `exec "$racine/scripts/check-private.sh" staged`. | guard_snippet: Remplacer le `exec` par un appel standard, ou exécuter explicitement `rm -rf "$travail"` juste avant le `exec`. | potential_consequence: L'utilisation de `exec` remplace le processus bash courant, ce qui a pour effet d'annuler le `trap EXIT` configuré plus haut. Le dossier temporaire contenant les CV privés extraits de l'index n'est donc jamais supprimé lors d'un commit réussi, entraînant une fuite de données silencieuse et permanente dans le répertoire `/tmp`.

##### Lentille Verification-Gap

BLOQUANT — location: `.githooks/pre-commit:85` | trigger_condition: Les tests de démonstration valident la réussite du hook de pre-commit sans vérifier l'état post-exécution du système de fichiers hôte. | guard_snippet: Ajouter une assertion dans le test pour s'assurer qu'aucun dossier créé via `mktemp -d` par le hook ne survit au succès de la validation. | potential_consequence: L'absence d'exécution du `trap EXIT` due au `exec` n'est détectée par aucune vérification et les données sensibles s'accumulent au fil des commits locaux. | gap_shape: `regression-gap` | consumer: `scripts/tests/test-pdf.sh:case_pdf_le_pre_commit_lance_c21_avant_le_garde_fou` | evidence: Le test vérifie que le script réussit (`assert_eq 0 "$rc"`) mais ne recherche aucun artefact orphelin laissé sur le disque, masquant ainsi l'échec du nettoyage.

##### Couche propre au projet

- BLOQUANT : Le hook `.githooks/pre-commit` utilise `exec` pour lancer le garde-fou final, annulant de ce fait l'exécution de son propre `trap EXIT` en cas de succès, ce qui provoque une fuite de données privées en abandonnant indéfiniment les extractions de CV dans `/tmp`.
- NON BLOQUANT : Les critères d'acceptation de la story sont intégralement respectés (démonstration fonctionnelle sur un dépôt jetable, ordre d'exécution correct avec `pdf.sh` prioritaire, signalement clair de la règle "ensemble ou rien" et sortie en code 2 pour l'absence des outils).
- NON BLOQUANT : Les erreurs fatales inattendues (code 2) de `grep` sont désormais correctement interceptées dans `pdf.sh` (via `shell_grep`) et corrigées dans les boucles de `check-private.sh`, empêchant efficacement le masquage d'erreurs sous `set -euo pipefail`.
- NON BLOQUANT : Aucune donnée privée, secret ou URL de la forge n'est divulgué, le numéro de ligne du motif est le seul élément affiché en cas de compromission d'un PDF.
- NON BLOQUANT : La cohérence avec `AGENTS.md` (ajouts des paquets poppler-utils) et les décisions d'architecture (refus ferme de dépendances lourdes pour l'analyse PDF, lecture rigoureuse de l'index et non de l'arbre de travail) est assurée.

VERDICT: BLOQUANT — L'utilisation de "exec" en fin de pre-commit annule le trap EXIT en cas de succès, provoquant une fuite permanente des copies temporaires des CV privés dans le répertoire /tmp.

### Décisions de l'auteur sur la cinquième revue du code de la PR n° 84

**Retenu — `exec` annulait le nettoyage, et laissait les CV dans `/tmp`.** Le hook finissait par `exec "$racine/scripts/check-private.sh" staged`. `exec` remplace le processus : le `trap EXIT` posé quelques lignes plus haut ne s'exécute jamais, et le dossier temporaire — qui contient les CV **extraits de l'index**, c'est-à-dire exactement ce que le correctif précédent venait d'y mettre — survit à chaque commit réussi et s'accumule.

Une fuite de données privées, introduite par le correctif d'une fuite de données privées, dans le hook qui existe pour les empêcher. Le `exec` est retiré ; sous `set -e`, le code de sortie du garde-fou reste celui du hook.

**Retenu — rien ne vérifiait l'état du disque après coup.** Le cas du dépôt jetable constatait que le commit passait, jamais ce qu'il laissait derrière lui. Il compte désormais les dossiers temporaires avant et après, et échoue si le hook en abandonne un. Éprouvé en remettant le `exec`.

**Cinq tours, et le dernier vient de mon propre correctif.** Le quatrième tour m'a fait extraire les objets de l'index — bonne décision — et cette extraction a créé un objet à nettoyer que le `exec`, déjà là, rendait impossible à nettoyer. Aucune des relectures que j'avais faites ne pouvait le voir, parce que je relisais **ce que j'ajoutais** sans relire ce avec quoi cela allait vivre. C'est la forme la plus tenace du motif de cette story : un correctif change les hypothèses du code qui l'entoure.

### 22/09/2026 — `f83afc1` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 84. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ce177908a6e6307afaf54dbc

**Lentille Edge-Case Hunter**
NON BLOQUANT — `scripts/checks/pdf.sh` (ligne 91) : Si le premier appel à `mktemp` réussit mais que le second échoue, l'erreur déclenche l'arrêt via `checks_die` avant que le `trap` de nettoyage ne soit défini, ce qui abandonne le premier fichier temporaire sur le disque.

**Lentille Verification-Gap**
NON BLOQUANT — `scripts/tests/test-pdf.sh` (ligne 371) : Le test compte les dossiers `tmp.*` dans le répertoire système global `/tmp` pour vérifier l'absence de fuite ; cela expose la suite de tests à des échecs aléatoires (flakiness) si un autre processus crée un dossier temporaire simultanément, lacune qui serait comblée en forçant un `TMPDIR` local.

**Couche propre au projet**
NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée : la démonstration du hook se fait sur un véritable dépôt jetable, l'absence de `poppler-utils` lève bien une anomalie (code 2), et l'ordre d'exécution du hook est respecté.
NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et les scripts vérifient les motifs sans jamais les afficher (seul le numéro de ligne est consigné).
NON BLOQUANT — Skill, procédure et script concordent parfaitement.
NON BLOQUANT — Le changement est cohérent avec AGENTS.md (qui intègre le nouveau prérequis machine de développement) et les décisions d'architecture (les PDF sont correctement extraits de l'index et non de l'arbre de travail).
NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` : les plantages potentiels de `grep` (code 2) ou de `git diff`/`git ls-files` sont désormais interceptés proprement via des captures de code de sortie (`rc=$?` ou `trouve=$?`).

VERDICT: NON BLOQUANT — aucune

### Décision de l'auteur sur la sixième revue du code de la PR n° 84

`f83afc1` (pass) : aucun constat, confirmations seulement.

Preuves sur la tête : `scripts/tests/run.sh`, 430 cas réussis dont 19 pour C21 ; `scripts/check.sh`, 8 contrôles passés ; `scripts/check-private.sh staged`, rien. Démonstration du pre-commit sur dépôt jetable, automatisée : ordre du hook, lecture de l'index, suppression, nom non-ASCII, changement de type, absence de fuite temporaire.

**Six tours de revue, cinq verdicts bloquants, onze constats retenus.** C'est le plus long de tout le projet, et la cause est unique : chaque constat posait la même question — *qu'est-ce que cette condition ne voit pas ?* — et j'ai répondu quatre fois sur l'occurrence citée avant de commencer à réénumérer. Le cinquième est le plus instructif : il vient de mon propre correctif du quatrième, qui a créé un objet à nettoyer que le `exec` déjà présent rendait impossible à nettoyer.

## Reporté

- Aucun constat reporté.
