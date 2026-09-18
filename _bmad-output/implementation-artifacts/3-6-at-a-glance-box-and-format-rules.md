# Story 3.6 : At a glance box and format rules

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.6.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `99d16bb`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 982265f7e81636b30dca37ff

Voici le rapport de revue de la spécification de la story 3.6, réalisé selon le format et les règles du skill `bmad-review` avec les lentilles `adversarial`, `structure` et `prose`.

##### 🕵️ Lentille Adversarial (Failles, cas limites et vérifiabilité)

- **Emplacement :** En-tête (`Couvre : FR-12, FR-18`)
  **Problème :** Contradiction avec la carte de couverture du fichier `epics.md`. La spécification affirme couvrir FR-12 et FR-18, mais `epics.md` ne liste pas la story 3.6 pour ces exigences (FR-12 y est assignée à 2.5, 3.5, 13.4-13.6 ; FR-18 à 0.1, 2.4, 9.1, 11.2, 11.3).
  **Correction attendue :** Retirer FR-12 et FR-18 de la ligne, ou mettre à jour `epics.md` (l'AC3 vérifie bien les variables de FR-18, donc l'oubli vient probablement d' `epics.md`).
  **Conséquence :** Suivi de sprint incohérent avec le backlog global, faussant la traçabilité des exigences.

- **Emplacement :** AC1 (Contrôle C16)
  **Problème :** L'AC1 omet l'exception pour les brouillons, contrairement à l'AC2. Or, l'AD-10 stipule explicitement : « pour un fichier en `draft: true`, une valeur qui commence par `[TODO` est acceptée par toutes les règles de forme (valeurs autorisées, longueur, comptage de l'encart...) ».
  **Correction attendue :** Ajouter « sauf valeur `[TODO…]` dans un brouillon » à la condition de l'AC1.
  **Conséquence :** Un brouillon contenant `summary: "[TODO: rédiger l'enjeu]"` fera échouer le contrôle C16, bloquant des pull requests légitimes.

- **Emplacement :** AC2 (Contrôle C18)
  **Problème :** FR-6 exige la présence de `société`, `cadre`, `rôle`, `période` et `stack`. L'AC2 vérifie `setup` (cadre), mais ignore `company`, `role` et `period`. Si C18 est responsable de valider le front-matter du cas, il lui manque une partie des exigences de FR-6.
  **Correction attendue :** Préciser si ces autres champs doivent être vérifiés par C18 ou s'ils sont déjà couverts par d'autres contrôles.
  **Conséquence :** Des valeurs invalides ou manquantes pour la société, le rôle ou la période pourraient passer en production.

- **Emplacement :** AC1 (Contrôle C16)
  **Problème :** Le critère « 3 phrases » est un critère humain sans définition technique explicite pour le script.
  **Correction attendue :** Définir l'heuristique de comptage (ex: regex comptant les `.` `!` `?` terminaux) et préciser si/comment il gère les abréviations (ex: `etc.`).
  **Conséquence :** Le contrôle sera instable, soumis à l'interprétation du développeur, et produira de faux positifs sur certaines ponctuations.

- **Emplacement :** AC2 (Contrôle C18)
  **Problème :** La règle indique de rejeter `setup`, `type`, `status` s'ils sont "hors valeurs". Cependant, la spécification ne liste pas quelles sont ces valeurs valides, ni où le script doit aller les récupérer.
  **Correction attendue :** Spécifier la source de vérité de ces valeurs (ex: à coder en dur dans le script ? à extraire de `docs/format-cas.md` ?).
  **Conséquence :** Le développeur devra deviner les valeurs autorisées, risquant un décalage avec le contenu réel.

##### 🏗️ Lentille Structure (Cohésion et organisation)

- **Emplacement :** AC3 vs Thème de la story
  **Problème :** L'AC3 ajoute la vérification des fichiers de configuration globaux (`.env.example` et `ci/legal-placeholder.env`) au sein du contrôle C18. Cela n'a aucun lien thématique avec l'encart "En bref" ou les règles de forme des cas (le titre de la story).
  **Correction attendue :** Assumer que C18 est un script de contrôle "fourre-tout" en le documentant comme tel, ou déplacer l'AC3 dans une story dédiée à la validation de l'environnement global.
  **Conséquence :** Risque de charge mentale excessive et d'oubli lors de l'implémentation, car le développeur sera concentré sur les fichiers markdown de `content/cases/`.

##### 📝 Lentille Prose (Clarté et ambiguïté)

- **Emplacement :** AC2
  **Problème :** La formulation « un numéro de fichier différent de `number` ou du suffixe du `translationKey` » est logiquement ambiguë lors d'une vérification négative. Doit-on rejeter si le numéro est différent d'un seul des deux, ou des deux à la fois ?
  **Correction attendue :** Clarifier la condition booléenne, par exemple : « dont le numéro dans le nom de fichier ne correspond pas à `number` OU ne correspond pas au suffixe de `translationKey` ».
  **Conséquence :** Erreur d'implémentation potentielle (`||` écrit au lieu d'un `&&` dans le script bash).

***

##### À trancher avant d'implémenter

- **Carte de couverture (`epics.md`) :** Faut-il supprimer FR-12 et FR-18 de la ligne « Couvre » de la spec, ou faut-il plutôt mettre à jour `epics.md` qui a oublié d'y attribuer la story 3.6 ?
- **Brouillons et C16 :** Confirmes-tu que C16 doit accepter la valeur `[TODO…]` dans les brouillons (pour le `summary`) sans appliquer les limites de longueur/phrases, comme l'exige l'AD-10 ?
- **Définition de "phrase" :** Quelle règle technique exacte (caractères, regex) le script doit-il utiliser pour délimiter et compter précisément les "3 phrases" ?
- **Valeurs valides (C18) :** Où le script C18 doit-il aller lire les listes de valeurs valides pour `setup`, `type` et `status` ? Doit-il également vérifier `company`, `role` et `period` (issus de FR-6) ?
- **Cohésion de C18 :** Est-ce délibéré de mélanger la vérification du front-matter des cas et celle des fichiers `.env` dans un seul et même contrôle (C18) ?

### Triage des constats (18/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| Définition d'une phrase | **retenu, déjà résolu** | la liste des contrôles la donne : « segment terminé par `.`, `!`, `?` ou `…` suivi d'une espace ou de la fin ». Aucune exception pour les abréviations : le critère le dit, et le pilote passe avec cette règle (354 points de code, 3 phrases, vérifié) |
| Où lire les valeurs autorisées de `setup`, `type`, `status` | **question à Arnaud** | elles vivent aujourd'hui en prose (AD-6, `docs/format-cas.md`) et en creux dans `i18n/` et le shortcode |
| `company`, `role`, `period`, `stack` d'un cas non vérifiés | **question à Arnaud** | FR-6 les exige ; ni C18 ni C19 ne les couvrent pour un cas. C19 ne vise que les postes et les formations |
| C18 mélange front matter et fichiers d'environnement | **retenu, assumé** | c'est la définition de C18 dans la liste des contrôles : « règles du format », dont `.env.example` et `ci/legal-placeholder.env`. Le contrôle ne lit que des **noms** de variables, jamais une valeur |
| Numéro de fichier, `number`, `translationKey` | **retenu** | les trois doivent concorder : un écart avec l'un **ou** l'autre est signalé. Le critère le dit sans ambiguïté |
| C16 et les brouillons | **retenu** | règle de forme : une valeur `[TODO…` passe dans un brouillon (AD-10, `checks_tolerated`) |
| Ligne « Couvre » (FR-12, FR-18) | **retenu tel quel** | FR-12 est justifié par les valeurs de `type` et `status` du matériel vivant, FR-18 par les deux fichiers d'environnement |

### Réponses d'Arnaud (18/09/2026)

- **Valeurs autorisées** : écrites dans `content.sh`, avec un renvoi à AD-6 et à `docs/format-cas.md`. Un fichier de données ferait une troisième source, à côté des clés i18n et du shortcode.
- **Encart d'un cas** : C18 vérifie désormais que `context.company`, `role`, `period` et `stack` sont renseignés sur un cas publié (FR-6). La ligne C18 de l'architecture est complétée.

## Ce qui est livré

- `scripts/checks/content.sh` gagne C16 et C18 :
  - **C16** — `summary` d'au plus 400 points de code et 3 phrases, la phrase étant définie par la liste des contrôles ; tolérance `[TODO` dans un brouillon.
  - **C18** — `title` ≤ 70 caractères ; `setup` et `status` dans leurs valeurs ; numéro du nom de fichier = `number` = suffixe du `translationKey` ; encart complet sur un cas publié ; noms de variables exacts dans `ci/legal-placeholder.env` et `.env.example`.
- Les deux fichiers d'environnement sont lus **pour leurs noms de variables seulement** : aucune valeur n'est lue ni affichée.
- `scripts/tests/test-content.sh` : dix cas de plus ; fixtures complétées d'un encart et d'un résumé conformes.
- `docs/procedures/check.md` et la ligne C18 de l'architecture portent les nouvelles règles.

### Essais

| Essai | Signalement |
| --- | --- |
| Résumé rallongé | `C16 : « En bref » de 475 points de code et 15 phrase(s) ; au plus 400 et 3` |
| Résumé de quatre phrases | `C16 : … 4 phrase(s) …` |
| `title` de 89 caractères | `C18 : title de 89 caractères ; 70 au plus` |
| `setup: stagiaire` | `C18 : setup « stagiaire » ; attendu employee, freelance, agency ou ton-pote-le-geek` |
| `number: "07"` sur `case-02-…` | `C18 : numéro « 02 » dans le nom de fichier, number « 07 »` |
| Cas publié sans `context.role` | `C18 : context.role absent ou vide (FR-6)` |
| `GITEA_USER` retiré de `.env.example` | `.env.example: C18 : variables « … » ; attendu « … »`, **code 1** (vérifié sans tuyau : `tail` masquait le code) |
| Ligne en trop dans `ci/legal-placeholder.env` | signalement équivalent, code 1 |
| Pilote et fichiers d'environnement tels que commités | code 0 |

Deux erreurs de ma part, corrigées et consignées : un exemple de test qui comptait quatre phrases au lieu de trois (le `…` termine une phrase, comme la définition de C16 le dit), et un `code=0` lu derrière un `tail` — le piège que j'avais moi-même ajouté aux pièges connus. `scripts/tests/run.sh` : 163 cas réussis (153 avant la story, 10 ajoutés).

## Revue du code

### 18/09/2026 — `33a0aba` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 41. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1691bf8aa4a41830208264c0

##### Rapport de revue BMAD

###### 🕵️ Lentille Edge-Case Hunter

- **Emplacement :** `scripts/checks/content.sh:250`
  **Condition déclencheur :** Le nom d'un fichier de cas ne contient pas la sous-chaîne attendue `case-[0-9]+-` (ex: faute de frappe `cas-01-chiliz.md` ou nom générique `_index.md`).
  **Extrait de protection :** `capture("case-(?<n>[0-9]+)-")? | .n // ""` ou `match("case-(?<n>[0-9]+)-") | .captures[0].string // ""`
  **Conséquence potentielle :** L'instruction `capture` lève une erreur fatale qui fait crasher `jq` silencieusement, masquant toutes les autres erreurs de validation et arrêtant le script brutalement.

- **Emplacement :** `scripts/checks/content.sh:262`
  **Condition déclencheur :** Les clés requises de l'encart (`company`, `role`, `period`) contiennent uniquement des espaces sans être strictement vides (ex: `role: " "`).
  **Extrait de protection :** `select(($value | tostring | test("^\\s*$")) or ...)`
  **Conséquence potentielle :** Le contrôle passe avec succès, autorisant la publication d'un cas avec un encart visuellement vide sur le site.

###### 🧪 Lentille Verification-Gap

- **Emplacement :** `scripts/checks/content.sh:285-294` (fonction `check_env_file`)
  **Condition déclencheur :** La nouvelle logique bash de vérification des fichiers `.env` n'a aucune couverture de test automatisée.
  **Extrait de protection :** Ajout de tests dans `test-content.sh` utilisant de faux fichiers d'environnement temporaires pour valider les codes de retour de `check_env_file`.
  **Conséquence potentielle :** Si la logique bash (`grep/tr/sort`) casse à l'avenir, aucun test ne le signalera. De plus, les tests actuels dépendent du vrai fichier `.env.example` du dépôt local, ce qui fera échouer la CI si le développeur modifie temporairement le sien.
  **Forme de la faille :** `regression-gap`
  **Consommateur :** `scripts/tests/test-content.sh`
  **Preuve :** Les 10 nouveaux tests ajoutés dans le diff de `test-content.sh` ciblent exclusivement les règles `jq` relatives au front-matter markdown, en ignorant totalement les fonctions shell de vérification d'environnement.

***

##### Constats projet

- BLOQUANT : L'utilisation de `capture` sans gestion d'erreur dans jq crashe le script si un nom de fichier est mal formé, ce qui enfreint directement l'AC2 qui exige que « C18 échoue en nommant le fichier et l'écart ».
- NON BLOQUANT : En dehors de ce défaut, les autres critères d'acceptation de la story sont satisfaits et leur intention technique est respectée (règles de l'encart, limites C16, etc.).
- NON BLOQUANT : Aucune donnée privée, adresse serveur ou secret n'est exposée ; le script filtre strictement via `grep` pour n'afficher que les noms des variables et jamais leurs valeurs.
- NON BLOQUANT : La procédure `docs/procedures/check.md` et les scripts concordent parfaitement sur la répartition de C16 et C18.
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les principes globaux ; l'architecture a bien été mise à jour.
- NON BLOQUANT : Aucune erreur shell ne passe sous silence : le retour non-zéro éventuel de `grep` dans `env_names` est explicitement intercepté par `found=$(...) || ...`, respectant le `set -euo pipefail`.
- NON BLOQUANT : Le manque de tests automatisés pour la vérification bash des fichiers d'environnement constitue une lacune de vérification, mais ne viole pas de critère strict du projet.

VERDICT: BLOQUANT — Le manque de sécurité sur le capture jq provoque un crash total au lieu du rapport d'erreur formaté exigé par les critères d'acceptation.

Décisions de l'auteur sur la revue du code de la PR n° 41 (`33a0aba`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — `capture` sans correspondance ferait planter `jq` | **prémisse fausse**, constat utile | rejoué : un manifeste où le cas s'appelle `cases/groupe/essai.fr.md` sort **code 1** avec ses autres signalements, sans erreur de `jq` — `capture` ne produit simplement rien. Le trou réel était ailleurs : ce nom hors format passait **en silence**. Une règle propre le signale désormais (« nom de fichier hors format ; attendu `case-NN-<nom-court>.<langue>.md` »), avec son cas de test |
| Non bloquant — aucun test sur la lecture des fichiers d'environnement | **retenu, corrigé** | quatre cas ajoutés, sur une copie du dépôt : les deux fichiers conformes, une variable manquante, une variable en trop, un fichier absent. Un cas vérifie en plus qu'**aucune valeur** n'apparaît dans le signalement |
| Constats projet non bloquants | confirmations | aucune suite |

### 18/09/2026 — `c12e2d5` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 41. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: e09722d59a8824f47c3387e0

Voici le rapport de revue du code de la PR n° 41, réalisé en suivant les instructions du skill `bmad-review` avec les lentilles `edge-case-hunter` et `verification-gap`, complété par la vérification des règles propres au projet.

##### 🕵️ Lentille Edge-Case Hunter (Failles et cas limites)

- **Emplacement :** `scripts/checks/content.sh:322`
  **Condition déclencheur :** Le cas est publié, mais l'une des clés de l'encart (comme `role` ou `period`) ne contient que des espaces (ex: `role: " "`).
  **Extrait de protection :** `select(($value | tostring | length) == 0 or ...)`
  **Conséquence potentielle :** La fonction considère la chaîne valide (car sa longueur est supérieure à 0), autorisant potentiellement la publication d'un cas avec un encart visuellement incomplet. (Note : cet écart résiduel existait déjà lors de la revue précédente).

- **Emplacement :** `scripts/checks/content.sh:187-190` (fonction `env_names`)
  **Condition déclencheur :** Le fichier d'environnement (ex: `.env.example`) est entièrement vide ou ne contient aucune déclaration de la forme `VARIABLE=...`.
  **Extrait de protection :** La chaîne de commandes `grep -oE '^[A-Z][A-Z0-9_]*=' "$1" | tr -d '=' | ...` appelée via `found=$(env_names "$1") || { checks_report ... "lecture impossible"; return 1; }`.
  **Conséquence potentielle :** `grep` échouera sans correspondances (code 1). Sous `set -euo pipefail`, le pipeline échoue et la fonction retourne 1. Bien que cela soit capturé en amont et empêche silencieusement l'erreur (le script affiche bien `lecture impossible` et bloque), le retour est générique et ne rapporte pas précisément "variables `` ; attendu `<liste>`".

##### 🧪 Lentille Verification-Gap (Lacunes de test)

- **Emplacement :** `scripts/tests/test-content.sh`
  **Condition déclencheur :** Échec silencieux de `grep` pour la lecture des variables dans un fichier qui existe mais qui est invalide (sans majuscules) ou entièrement vide.
  **Forme de la faille :** Test manquant
  **Conséquence potentielle :** L'affichage spécifique de "lecture impossible" par `check_env_file` dans le cas d'une anomalie interne de lecture par `env_names` n'est pas couvert par les tests (seul le test du fichier manquant ou incomplet de noms est vérifié).

***

##### Constats de la couche propre au projet

- NON BLOQUANT : les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée. L'anomalie bloquante impliquant `capture` a bien été remplacée par `match`, sans créer de plantage de `jq`. L'omission des champs remplis uniquement d'espaces laisse une marge de tolérance mais ne vide pas globalement l'intention du contrôle.
- NON BLOQUANT : aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge. L'extraction par `grep -oE` avec nettoyage par `tr -d '='` est robuste.
- NON BLOQUANT : skill, procédure et script concordent. La mise à jour du fichier `docs/procedures/check.md` traduit exactement les ajouts des contrôles C16 et C18 implémentés dans `content.sh`.
- NON BLOQUANT : le changement est cohérent avec AGENTS.md et les décisions d'architecture (la ligne C18 de `ARCHITECTURE-SPINE.md` a bien été mise à jour avec les contraintes d'encart publié).
- NON BLOQUANT : dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Le script intercepte correctement le code non nul renvoyé par la pipeline de `env_names` avec l'instruction `|| { ... return 1; }`.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la deuxième revue de la PR n° 41 (`c12e2d5`, verdict `pass`) : aucun constat bloquant. Le relecteur note une tolérance restante — une valeur d'encart faite uniquement d'espaces passerait la règle « non vide ». **Reporté** : le cas ne s'est jamais produit, et la story 3.7 reprend `content.sh` pour C19, qui vérifie des clés voisines ; entrée dans `deferred-work.md`.

Rectificatif : le `--context` envoyé au relecteur annonçait 172 cas de test ; le compte réel est **168**. Erreur de ma part, sans effet sur la revue.

## Reporté
