# Story 3.2 : Check script entry point and draft rule

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.2.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `2277b85`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 482634f1a6185a4a8f25516f

### Rapport de revue de spécification (Story 3.2)

##### 🕵️ Adversarial (Recherche de failles et cas limites)

*   **Lentille :** `adversarial`
*   **Localisation :** Critères d'acceptation, « Alors il construit le rendu de travail et le build de production »
*   **Déclencheur :** Dépendance implicite à la réussite du build.
*   **Garde-fou manquant :** Si `scripts/build.sh` échoue (erreur de syntaxe Hugo, etc.), `check.sh` doit-il lancer les scripts de contrôle ou s'arrêter immédiatement ? Le comportement en cas d'échec du build doit être défini.
*   **Conséquence potentielle :** Exécution des contrôles sur un manifeste `checks.json` potentiellement obsolète, générant de faux positifs difficiles à déboguer.

*   **Lentille :** `adversarial`
*   **Localisation :** Critères d'acceptation, « sort avec 0 ou 1 »
*   **Déclencheur :** Code de retour trop strict.
*   **Garde-fou manquant :** Remplacer par « sort avec 0 en cas de succès, et un code non nul en cas d'échec ».
*   **Conséquence potentielle :** Obligation d'ajouter `|| exit 1` sur chaque commande pour masquer les codes de retour natifs (ex: `grep` qui renvoie 2 si aucune correspondance n'est trouvée), ce qui alourdit inutilement le script.

*   **Lentille :** `adversarial`
*   **Localisation :** Critères d'acceptation, « Alors C14 échoue »
*   **Déclencheur :** Définition de l'échec C14 non explicite et format de sortie.
*   **Garde-fou manquant :** AD-5 précise que `build.sh` utilise `--panicOnWarning`. Si Hugo panique, il produit sa propre sortie d'erreur brute. La spécification doit préciser si cette sortie brute est tolérée pour C14 ou si `check.sh` doit l'intercepter pour respecter scrupuleusement le format de signalement imposé (`<fichier>: <écart>`).
*   **Conséquence potentielle :** Non-respect partiel du format de sortie imposé pour les erreurs provenant directement de Hugo.

*   **Lentille :** `adversarial`
*   **Localisation :** Questions à poser / « check.sh cumule-t-il les signalements... ? »
*   **Déclencheur :** Comportement d'accumulation vs fail-fast non tranché.
*   **Garde-fou manquant :** La réponse dicte l'architecture même de `check.sh`. Un cumul implique de collecter les codes de retour de tous les sous-scripts sans s'arrêter (`set -e` global inadapté).
*   **Conséquence potentielle :** Le développeur choisit arbitrairement, ce qui risque de s'éloigner des attentes en termes de confort de développement (voir tous les problèmes d'un coup vs cycle correction/relance).

*   **Lentille :** `adversarial`
*   **Localisation :** Critères d'acceptation, « une valeur qui commence par `[TODO` est acceptée »
*   **Déclencheur :** Responsabilité du filtrage.
*   **Garde-fou manquant :** Préciser si `lib.sh` filtre en amont, ou s'il offre simplement une fonction utilitaire (ex: `is_todo`) que chaque script de contrôle devra obligatoirement appeler.
*   **Conséquence potentielle :** Duplication de la logique d'exclusion ou oubli de vérification dans certains contrôles futurs.

##### 🏗️ Structure (Organisation et cohérence)

*   **Lentille :** `structure`
*   **Localisation :** Critères d'acceptation, « L'option `--release` est reconnue »
*   **Déclencheur :** Action concrète de l'option manquante.
*   **Garde-fou manquant :** Que fait cette option au stade de la story 3.2 ? Assigne-t-elle une variable d'environnement (ex: `CHECK_LEVEL=release`, comme mentionné implicitement dans AD-13) pour les futurs contrôles de l'Epic 11 ?
*   **Conséquence potentielle :** L'option est parsée mais sa valeur n'est ni stockée ni exploitable.

*   **Lentille :** `structure`
*   **Localisation :** Critères d'acceptation, « lance les scripts de contrôle présents »
*   **Déclencheur :** Mode de découverte ambigu.
*   **Garde-fou manquant :** Préciser s'il s'agit d'une découverte dynamique (`for script in scripts/checks/*.sh`) en ignorant `lib.sh`, ou d'appels explicitement écrits en dur dans `check.sh`.
*   **Conséquence potentielle :** Implémentations divergentes ou complexité inutile si la méthode n'est pas guidée.

##### 📝 Prose (Clarté et précision)

*   **Lentille :** `prose`
*   **Localisation :** Critères d'acceptation, « Alors C14 échoue »
*   **Déclencheur :** Concision excessive.
*   **Garde-fou manquant :** Expliciter : « Alors le contrôle C14 (qui vérifie l'absence d'avertissements Hugo) fait échouer le script principal ».
*   **Conséquence potentielle :** Perte de temps et de contexte pour le développeur qui doit aller chercher la définition de C14 dans `ARCHITECTURE-SPINE.md`.

*   **Lentille :** `prose`
*   **Localisation :** Critères d'acceptation, « une valeur qui commence par `[TODO` est acceptée »
*   **Déclencheur :** Formulation ambiguë sur le rôle de lib.sh.
*   **Garde-fou manquant :** Préférer : « est considérée comme valide par les fonctions de vérification de `lib.sh` ».
*   **Conséquence potentielle :** Mauvaise interprétation de la responsabilité de `lib.sh` (outil passif vs filtre actif).

***

##### À trancher avant d'implémenter

1.  **Cumul ou fail-fast :** `check.sh` doit-il s'arrêter au premier script de contrôle en échec (fail-fast), ou tous les exécuter pour cumuler les affichages d'erreurs avant de sortir avec un code d'échec ?
2.  **Code de retour assoupli :** Peut-on modifier la contrainte « sort avec 0 ou 1 » par « sort avec 0 en cas de succès, non-nul en cas d'échec » pour éviter de forcer le masquage des codes de retour natifs de bash ?
3.  **C14 et avertissements Hugo :** Hugo en mode `--panicOnWarning` génère sa propre sortie. Accepte-t-on que l'erreur remontée par Hugo ne suive pas strictement le format `<fichier>: <écart>` imposé aux scripts de contrôle personnalisés ? De plus, un échec du build doit-il bloquer immédiatement l'exécution des contrôles suivants ?
4.  **Découverte des scripts :** La liste des scripts de contrôle doit-elle être écrite en dur dans `check.sh` ou découverte dynamiquement dans le dossier `scripts/checks/` (en excluant `lib.sh`) ?
5.  **Option `--release` :** Cette option doit-elle exporter une variable précise (comme `CHECK_LEVEL=release`) en prévision de l'Epic 11 ?
6.  **Cas de tests :** Faut-il mettre en place une infrastructure avec des `tests/fixtures/` pour `lib.sh` dès maintenant, ou l'évaluation se fera-t-elle via des copies locales jetables sans polluer le dépôt (réponse à la question posée dans la story) ?

### Triage des constats (18/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — que faire si le build échoue | **retenu** | un build en échec arrête tout : les contrôles ne lisent jamais un manifeste périmé. Le critère le dit |
| A2 — « sort avec 0 ou 1 » trop strict | **retenu**, reformulé | convention du projet (`shell-scripts.md`) : **0** conforme, **1** écart constaté, **2** anomalie (outil ou fichier manquant). Ce n'est pas un assouplissement mais la règle déjà suivie par les autres scripts |
| A3 — format de la sortie de Hugo pour C14 | **retenu** | la sortie brute de Hugo est gardée telle quelle : elle nomme déjà le fichier et la ligne mieux qu'un reformatage. `check.sh` la fait précéder d'une ligne à lui qui nomme le build en échec. Le format `<fichier>: <écart>` reste la règle des scripts de `scripts/checks/` |
| A4 — cumul ou arrêt au premier échec | **question à Arnaud** | déjà posée par la story |
| A5 — `lib.sh` filtre ou outil | **retenu** | outil passif : `checks_is_todo` et `checks_skip_rule`, appelés par chaque contrôle. Un filtre en amont ne saurait pas distinguer les règles de forme (qui tolèrent `[TODO`) de la parité et des rubriques (qui s'appliquent aussi aux brouillons, AD-10) |
| S1 — que fait `--release` maintenant | **retenu** | l'option fixe le niveau (`standard` par défaut, `release` avec l'option), lisible par les contrôles ; AD-13 le passe déjà au Dockerfile par `CHECK_LEVEL`. Aucun contrôle de mise en ligne n'existe avant l'epic 11 : le niveau est posé, pas employé |
| S2 — découverte des scripts | **retenu** | découverte dynamique : `scripts/checks/*.sh` triés, `lib.sh` exclu. Une story qui ajoute un contrôle n'a pas à modifier `check.sh` |
| P1 — « Alors C14 échoue » trop court | **retenu** | le critère nomme ce que C14 vérifie |
| P2 — rôle de `lib.sh` dans la règle des brouillons | **retenu** | formulation alignée sur A5 |
| A6 — forme des cas de test | **question à Arnaud** | déjà posée par la story ; la réponse vaut pour les stories 3.3 à 3.11 et pour le test du manifeste reporté par la 3.1 |

### Réponses d'Arnaud (18/09/2026)

- **Cumul** : tous les contrôles tournent, tous les écarts s'affichent, puis un résumé et un code 1.
- **Cas de test** : manifestes écrits à la main pour la logique, plus **un** site fixture construit avec le Hugo épinglé pour le contrat du manifeste — ce qui ferme le report de la story 3.1.
- **`--release`** : l'option pose le niveau (`CHECK_LEVEL`) sans l'employer avant l'epic 11.

La story est réécrite dans `epics.md` en conséquence.

## Ce qui est livré

- `scripts/check.sh` : rendu de travail puis build de production, découverte dynamique des contrôles (`scripts/checks/*.sh`, triés, `lib.sh` exclu), cumul des écarts, résumé, niveau `CHECK_LEVEL` (`--release`). Codes 0, 1, 2. Aucun appel à `git`.
- `scripts/checks/lib.sh` : `checks_report` (format `<fichier>: <écart>`), `checks_is_todo`, `checks_tolerated`, et la règle des brouillons documentée en tête.
- `docs/procedures/check.md` : ce que fait le script, comment écrire un contrôle, comment le tester, pièges connus.
- `scripts/tests/test-check.sh` (7 cas, faux dépôt et `build.sh` bouchonné), `scripts/tests/test-checks-manifest.sh` (le site fixture), trois cas ajoutés à `test-checks-lib.sh`, et `scripts/tests/fixtures/site/`.
- `scripts/verify-and-merge-pr.sh` : le substitut d'amorçage passe `TOOLS_LOCAL_DIR` à la copie de la tête (voir ci-dessous).

### Une entrée reportée qui arrivait à échéance

La story 0.7 avait consigné que le substitut d'amorçage lance `scripts/check.sh` dans une **copie de la tête sans `.tools/` ni `.env`**, tous deux ignorés par git. Cette story crée `check.sh` : l'échéance était donc maintenant. Reproduit sur une copie de la tête — aucun Hugo trouvé —, puis corrigé : le script passe à la copie les binaires épinglés du dépôt de travail, et les valeurs légales viennent du fichier factice commité (AD-9). Sans ce correctif, le verrou CI aurait bloqué **toutes** les PR dès la fusion de cette story. Entrée de clôture dans `deferred-work.md`.

### Le test du manifeste, reporté par la story 3.1, est livré ici

`scripts/tests/test-checks-manifest.sh` construit `scripts/tests/fixtures/site/` avec le Hugo épinglé, en empruntant gabarits, configuration et données au dépôt, puis vérifie le manifeste à `jq` : rôles (dont `section` et `group`), titres H2, identifiants placés, `todo`, `draft`, `translationKey`, front matter à la casse exacte et sans ce que la cascade ajoute, `error` pour un fichier sans front matter et pour un fichier sans suffixe de langue, vocabulaire à la racine. La fixture est volontairement déséquilibrée (un fichier n'existe qu'en français), écart que la parité C3 verra à la story 3.3.

### Essais

| Essai | Résultat |
| --- | --- |
| `scripts/check.sh` dans le dépôt | code 0, deux builds, « aucun script de contrôle » : aucun contrôle n'existe encore |
| Copie exportée **sans `.git`** | code 0 : le script n'appelle jamais `git` |
| Copie locale ajoutant `languages.en.languageDirection` (clé dépréciée) | code 1, la ligne `check: le build work a échoué…` précède la sortie de Hugo, aucun contrôle lancé (C14) |
| Contrôle d'essai déposé dans `scripts/checks/` | code 1, signalement `content/essai.fr.md: écart d'essai`, résumé « 1 contrôle(s) en échec sur 1 : essai » ; retiré ensuite, code 0 |
| `scripts/tests/run.sh` | 114 cas réussis (103 avant la story, 11 ajoutés) |

Copies locales défaites : configuration restaurée depuis une copie faite avant l'essai, contrôle d'essai supprimé nommément ; `git status` ne montre que les fichiers de la story.

## Revue du code

### 18/09/2026 — `b590a2f` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 36. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 17b25d1e50b415a57369abd1

##### Rapport de revue (BMAD & Projet)

###### 🕵️ verification-gap & Couche Projet (Cohérence des critères d'acceptation)

* **Localisation** : `scripts/check.sh`, fonction `build()` (lignes 328-332) et `scripts/tests/test-check.sh` (ligne 633)
* **Condition de déclenchement** : Un build (`work` ou `production`) échoue et génère une sortie d'erreur (par exemple un avertissement de Hugo avec `--panicOnWarning`).
* **Garde-fou manquant / Correctif** : Capturer la sortie d'erreur de `build.sh` pour l'afficher *après* le `printf` de `check.sh`, ou utiliser un descripteur de fichier/redirection. Dans les tests, corriger `case_check_build_en_echec_arrete_avant_les_controles` pour qu'il affirme explicitement l'ordre d'affichage des messages, et pas seulement leur présence.
* **Conséquence potentielle** : La commande `"$root/scripts/build.sh" "$1" > /dev/null` laisse le flux `stderr` de Hugo s'afficher immédiatement. Ce n'est qu'après la fin et l'échec de ce build que le bloc `|| { printf ... }` s'exécute. L'erreur de Hugo sera donc *suivie* (et non *précédée*) par la ligne de `check.sh`. Cela vide de son intention et viole frontalement le critère d'acceptation : « la sortie de Hugo est gardée telle quelle, précédée d'une ligne de check.sh nommant le build en échec ». Le test unitaire laisse passer cette régression car il contient un *verification gap* (il utilise `assert_contains` indépendamment pour les deux chaînes sans vérifier leur séquence).
* **Classement** : BLOQUANT

###### 🛡️ edge-case-hunter (Robustesse)

* **Localisation** : `scripts/check.sh` (lignes 338-344)
* **Condition de déclenchement** : Le glob `"$root"/scripts/checks/*.sh` est utilisé pour peupler la liste des scripts de contrôle dynamiquement.
* **Garde-fou manquant / Correctif** : Aucun correctif strict n'est requis. L'expansion du glob (globbing) dans bash garantit un tri alphabétique selon `LC_COLLATE`.
* **Conséquence potentielle** : Comportement conforme aux critères d'acceptation (« découverte dynamique, triés »), car le shell bash garantit le tri lors de l'expansion. Le paramètre `nullglob` prémunit bien contre le cas où la liste est vide.
* **Classement** : NON BLOQUANT

VERDICT: BLOQUANT — Le message d'échec du build dans check.sh s'affiche après la sortie d'erreur de Hugo au lieu de la précéder (violant un critère d'acceptation formel), et le test unitaire associé souffre d'une lacune de vérification qui masque ce défaut d'ordonnancement.

Décisions de l'auteur sur la revue du code de la PR n° 36 (`b590a2f`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — la ligne de `check.sh` suit la sortie de Hugo au lieu de la précéder | **retenu, corrigé** | constat juste, et l'essai de la story le montrait déjà : j'avais lu la présence des deux lignes sans lire leur ordre. Hugo écrit sur la sortie d'erreur au fil de l'eau ; `build()` retient désormais la sortie dans un fichier temporaire, affiche la ligne de `check.sh`, puis la sortie telle quelle. Vérifié sur la vraie clé dépréciée : la ligne de `check.sh` sort en premier |
| Lacune du cas de test (deux `assert_contains` sans ordre) | **retenu, corrigé** | le cas compare désormais la sortie d'erreur **entière**, donc l'ordre |
| Tri du glob, non bloquant | confirmation | `nullglob` et le tri de l'expansion sont bien ce sur quoi la découverte repose |

### 18/09/2026 — `813690b` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 36. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: aa3bab915928cd2e628bb55b

##### Rapport de revue (BMAD & Projet)

###### 🕵️ verification-gap (Lacunes de vérification)

*   **Localisation :** `scripts/tests/test-check.sh` (cas `case_check_build_en_echec_arrete_avant_les_controles`)
*   **Déclencheur :** Ordre d'affichage des messages en cas d'échec du build.
*   **Constat :** Le test unitaire affirme désormais strictement l'ordre d'affichage des messages via un `assert_eq` sur la chaîne complète de la sortie d'erreur (`$err`), plutôt que par deux assertions indépendantes. La lacune de vérification relevée lors de la précédente revue est complètement corrigée.
*   **Classement :** NON BLOQUANT

*   **Localisation :** `scripts/tests/test-checks-manifest.sh`
*   **Déclencheur :** Vérification du site fixture construit par Hugo.
*   **Constat :** Le script de test exerce correctement les différents rôles et vérifie bien le JSON généré par l'outil réel (Hugo épinglé). Il couvre ainsi la découverte et la validation du contenu de `checks.json`, ce qui lève la dette technique reportée depuis la story 3.1.
*   **Classement :** NON BLOQUANT

###### 🛡️ edge-case-hunter (Robustesse)

*   **Localisation :** `scripts/check.sh` (lignes 338-344, boucle `for candidate in "$root"/scripts/checks/*.sh;`)
*   **Déclencheur :** Découverte dynamique de la liste des contrôles avec la possibilité qu'aucun script ne soit présent.
*   **Constat :** Le script active préventivement `shopt -s nullglob`, évitant que le globbing ne retourne le motif littéral si le dossier est vide (ce qui arrive avant que les futures stories n'ajoutent des contrôles). L'expansion assure intrinsèquement un tri robuste.
*   **Classement :** NON BLOQUANT

*   **Localisation :** `scripts/check.sh` (lignes 388-399)
*   **Déclencheur :** Exécution séquentielle des scripts accumulant à la fois des codes 1 (échec standard) et 2 (anomalie d'exécution).
*   **Constat :** L'assignation `bash "$candidate" || rc=$?` capte tous les échecs sans déclencher prématurément le `set -e`. Le script retient séparément les codes d'erreur supérieurs à 1 (variable `anomaly`) et garantit que si une anomalie se produit au milieu d'autres échecs standards, le code de retour global sera bien escaladé à `2`.
*   **Classement :** NON BLOQUANT

###### Couche propre au projet

*   **Localisation :** `scripts/check.sh` (fonction `build()`)
*   **Déclencheur :** Critère d'acceptation « la sortie de Hugo est gardée telle quelle, précédée d'une ligne de check.sh nommant le build en échec ».
*   **Constat :** L'auteur a redirigé la sortie du `build.sh` dans un fichier temporaire retenu (`$tmp/build.out`), affiché uniquement après le `printf` d'erreur propre à `check.sh`. Le critère d'acceptation est désormais formellement satisfait sans en vider l'intention. Un échec du build bloque immédiatement la suite (`build work || exit 1`), évitant de lire un manifeste périmé. L'intention fonctionnelle est validée.
*   **Classement :** NON BLOQUANT

*   **Localisation :** Fichiers modifiés
*   **Déclencheur :** Vérification des données privées et secrets.
*   **Constat :** Aucune donnée privée, aucun nom d'hôte de forge ni secret n'a été inséré. Les ajouts sous `scripts/tests/fixtures/` emploient des valeurs factices ou anonymisées (`Société`, `[TODO: période]`). Les scripts de validation n'impriment pas non plus de contenu sensible.
*   **Classement :** NON BLOQUANT

*   **Localisation :** `docs/procedures/check.md` et `scripts/check.sh`
*   **Déclencheur :** Concordance entre la documentation de la procédure et l'implémentation.
*   **Constat :** Le manuel de procédure décrit exactement ce que réalise le script : exécution des builds avec `panicOnWarning`, découverte dynamique, exclusion stricte du script `lib.sh`, flag `--release`, cumul des échecs et codes de sortie. La modification concernant `verify-and-merge-pr` (substitution de `TOOLS_LOCAL_DIR`) est également documentée conformément à l'implémentation.
*   **Classement :** NON BLOQUANT

*   **Localisation :** Ensemble des fichiers `scripts/check.sh` et `scripts/checks/lib.sh`
*   **Déclencheur :** Cohérence avec les décisions d'architecture et `AGENTS.md`.
*   **Constat :** Le point d'entrée est unique comme exigé par AD-10. La gestion des brouillons et leur tolérance face à des balises `[TODO` passe correctement par la bibliothèque partagée, en tant qu'outil consultatif (`checks_tolerated`) pour les autres contrôles, en parfaite adéquation avec l'architecture.
*   **Classement :** NON BLOQUANT

*   **Localisation :** Ensemble des scripts `.sh`
*   **Déclencheur :** Prévention des erreurs passées sous silence sous `set -euo pipefail`.
*   **Constat :** Tous les appels faillibles que le script souhaite contrôler sont suivis d'un `|| { ... }` ou de `|| rc=$?` explicite. La création du dossier temporaire échoue bruyamment (`exit 2`), tout comme l'appel au `build.sh`. Aucune anomalie n'est masquée.
*   **Classement :** NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la deuxième revue de la PR n° 36 (`813690b`, verdict `pass`) : aucun constat à traiter ; le relecteur confirme que la lacune d'ordre est fermée et que le site fixture lève la dette de la story 3.1. Rien n'est reporté.

## Reporté
