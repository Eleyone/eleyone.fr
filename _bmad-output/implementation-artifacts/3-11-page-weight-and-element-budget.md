# Story 3.11 : Page weight and element budget

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.11.

## Revue de spec

### 19/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `6ae8db6`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d8f4e920538a6a4307deedb8

##### Revue de la Spec (Story 3.11)

###### 1. Lentille Adversarial (Recherche de failles et cas limites)

* **Unité de mesure (Ko)**
  * **Condition :** Le critère stipule "HTML > 50 Ko", sans clarifier l'unité.
  * **Faille :** S'agit-il de kilooctets décimaux (1 000 octets) ou de kibioctets (1 024 octets) ?
  * **Conséquence :** Risque de faux positifs ou de dépassements tolérés à tort autour de la limite exacte. Un écart de 1 200 octets (pour 50 Ko) est significatif.

* **Variantes d'images (`srcset` / `<picture>`)**
  * **Condition :** La "page complète" inclut "les images référencées, photo comprise".
  * **Faille :** La photo utilise potentiellement plusieurs variantes de densité/taille (`srcset`). Le script doit-il sommer toutes les déclinaisons proposées au navigateur, ou seulement la variante par défaut / de repli ?
  * **Conséquence :** Le budget "page complète" (200 Ko) pourrait exploser artificiellement et bloquer le build si le script additionne toutes les variantes d'un `srcset` ensemble.

* **Code de sortie en cas de dépassement**
  * **Condition :** Le script "signale tout dépassement".
  * **Faille :** La consigne omet d'imposer explicitement que le script retourne un code de sortie non nul en cas d'erreur.
  * **Conséquence :** Si le développeur oublie de gérer l'`exit code`, le script pourrait avertir dans la console sans pour autant faire échouer la chaîne d'intégration continue (CI).

* **Intégration au point d'entrée unique (AD-10)**
  * **Condition :** L'exécution de `scripts/checks/budget.sh`.
  * **Faille :** L'architecture (AD-10) impose `scripts/check.sh` comme point d'entrée unique des contrôles. La spec de la story n'exige pas l'ajout de l'appel à `budget.sh` dans `check.sh`.
  * **Conséquence :** Le contrôle pourrait ne tourner qu'isolément s'il n'est pas câblé dans la boucle principale.

* **Périmètre du scan des pages HTML**
  * **Condition :** Le test s'opère sur "le build de production".
  * **Faille :** Le script doit vérifier le budget par page. Boucle-t-il systématiquement sur absolument tous les fichiers `.html` du répertoire `public/` ?
  * **Conséquence :** Si le script ne cible qu'un sous-ensemble (ex. l'accueil seul), des dépassements sur des pages annexes ou des articles longs ne seraient pas détectés.

* **Limitation des "10 ressources"**
  * **Condition :** Détection de "plus de 10 ressources".
  * **Faille :** Ce qui constitue précisément une ressource pour ce script n'est pas listé. Le fichier HTML lui-même compte-t-il pour une ressource ? Un SVG en ligne (inline) compte-t-il pour une ressource ?
  * **Conséquence :** Une interprétation erronée bloquera le build alors que la limite conceptuelle était respectée.

* **Comptage des "800 éléments"**
  * **Condition :** Détection de "plus de 800 éléments".
  * **Faille :** Est-ce le décompte absolu de tous les nœuds DOM ou seulement des balises (par `xmllint --html --xpath "count(//*)"`) ?
  * **Conséquence :** S'il inclut les commentaires ou nœuds de texte, le chiffre plafond de 800 sera atteint très vite.

* **Absence de fichiers JavaScript et de police**
  * **Condition :** Détection d'"un fichier JavaScript ou de police".
  * **Faille :** Le contrôle porte-t-il sur des balises d'appel dans le HTML (`<script>`, `<link>`), ou bien un parcours (find) des extensions `.js` et `.woff` / `.ttf` dans tout le répertoire `public/` ?
  * **Conséquence :** Un fichier `.js` résiduel de la compilation mais jamais appelé par le HTML pourrait faire échouer le test s'il balaie le dossier `public/`.

* **Différenciation des liens sortants (PDF)**
  * **Condition :** "Les PDF, simples liens, ne comptent pas."
  * **Faille :** Comment le script différencie-t-il une ressource téléchargée pour rendre la page (image, CSS) d'un lien de navigation (`<a href>`) ?
  * **Conséquence :** Un parseur HTML naïf qui additionne la taille des `href` inclura les CV PDF dans le budget global de la page. 

* **Calcul de la CSS totale**
  * **Condition :** Vérifier "CSS totale > 20 Ko".
  * **Faille :** Le script doit-il inspecter directement le fichier `main.css` généré dans le dossier des assets, ou extraire dynamiquement les feuilles de style référencées par chaque page ?
  * **Conséquence :** Sans directive claire, le développeur pourrait recréer un parseur d'attributs inutiles au lieu de cibler simplement l'asset global.

###### 2. Lentille Structure (Organisation et Cohérence)

* **Surcharge des critères d'acceptation**
  * **Observation :** Le bloc **Alors** contient une seule très longue phrase définissant huit limites quantitatives et qualificatives distinctes.
  * **Appréciation :** L'accumulation rend la vérification incrémentale difficile pour le développeur. Découper ces huit affirmations en une liste à puces faciliterait la construction des assertions des tests.

* **Questions de blocage ignorées**
  * **Observation :** La section "Bloquée par :" indique "—", mais la section "Questions à poser" formule des doutes fondamentaux sur la définition des unités et des règles de calcul.
  * **Appréciation :** Si la définition de ce qui est additionné dans le "budget" n'est pas connue à l'avance, la story devrait idéalement être considérée comme conceptuellement "bloquée" jusqu'à clarification pour ne pas paralyser le développement.

###### 3. Lentille Prose (Clarté de rédaction)

* **Clarté du calcul de la page complète**
  * **Observation :** "page complète (HTML, CSS, images référencées, photo comprise) > 200 Ko"
  * **Appréciation :** La précision "photo comprise" permet de rappeler le critère NFR-5, mais est superflue et potentiellement ambiguë si elle sous-entend un statut particulier pour ce fichier par rapport aux "images référencées". L'intention est claire, mais la formulation pourrait être simplifiée ("somme de la page et de tous les médias référencés pour son affichage").


##### À trancher avant d'implémenter

* **Unité de base :** 1 Ko doit-il être évalué à 1 000 octets ou 1 024 octets ?
* **Règle de comptage des variantes d'images :** Comment le script doit-il évaluer le poids d'une image gérée avec `srcset` ? Faut-il compter toutes les variantes de résolution présentes dans l'attribut, seulement l'image de repli (`src`), ou évaluer la variante la plus lourde proposée ?
* **Règle de comptage des ressources :** Le fichier HTML de la page inspectée compte-t-il pour « 1 ressource » dans le décompte de la limite de 10 ressources ?
* **Périmètre du JavaScript / des polices :** L'interdiction vise-t-elle strictement la présence de balises d'inclusion dans les pages `.html`, ou la stricte absence de fichiers d'assets correspondants (ex. `.js`, `.woff`) dans le dossier `public/` ?
* **Intégration d'exécution :** Est-il formellement acté que l'exécution de `budget.sh` doit être ajoutée dans `scripts/check.sh` au cours de cette story ?

### Triage des constats (19/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| Unité du kilo-octet | **question à Arnaud** | déjà posée par la story |
| Comptage des variantes d'une image | **question à Arnaud** | déjà posée par la story |
| Le HTML compte-t-il dans les 10 ressources | **retenu** | non : une ressource est un fichier que la page **charge en plus** d'elle-même (CSS, image, schéma). Le document est le budget HTML, mesuré à part |
| Portée de l'interdiction JS et polices | **retenu** | les deux : aucun fichier `.js`, `.woff`, `.woff2`, `.ttf`, `.otf`, `.eot` dans `public/`, et aucune référence depuis une page. Un fichier orphelin serait servi par nginx et pèserait dans l'image |
| Ajout à `check.sh` | **retenu, déjà acquis** | `check.sh` découvre les contrôles de `scripts/checks/` (story 3.2) : déposer le script suffit |
| Huit limites en une phrase | **retenu** | les critères passent en liste |
| « photo comprise » superflu | **retenu** | « la page et tous les médias qu'elle charge » |
| Story « bloquée » tant que les unités ne sont pas tranchées | **refusé** | la story n'est pas bloquée : elle porte ses questions, comme le veut le flux du dépôt — revue de spec, puis questions à Arnaud, puis implémentation |

### Réponses d'Arnaud (19/09/2026)

- **1 Ko = 1 000 octets**, l'unité des navigateurs et de PageSpeed : la mesure de mise en ligne se comparera au budget sans conversion.
- **Une image déclinée compte par sa variante la plus lourde** : un navigateur n'en télécharge qu'une, et le budget doit refléter le pire cas réel. Chaque variante reste comptée comme ressource.

AD-8 porte les deux décisions.

## Ce qui est livré

- `scripts/checks/budget.sh` (C13) : HTML, CSS du site, SVG, page complète, nombre de ressources, nombre d'éléments, fichiers JavaScript ou de police, ressources absentes. Les PDF liés restent hors budget (AD-21).
- `scripts/tests/test-budget.sh` : treize cas, avec des fichiers de taille choisie.
- `docs/procedures/check.md` et AD-8 portent les règles.

### Trois points tranchés sans déranger Arnaud

- **Le document n'est pas une ressource qu'il charge** : dix images passent, onze échouent. Le HTML a son propre plafond.
- **L'interdiction JavaScript et polices porte sur les fichiers autant que sur les références** : un `.js` orphelin serait servi par nginx et pèserait dans l'image.
- **`check.sh` découvre le contrôle** sans modification, depuis la story 3.2.

### Essais

| Essai | Résultat |
| --- | --- |
| Production réelle | code 0 ; les pages pèsent 700 octets pour 18 éléments, très loin des plafonds |
| HTML de 50 001 octets | signalé avec sa mesure |
| Deux CSS totalisant 21 000 octets | signalées ensemble : le plafond vaut pour le site |
| SVG de 60 001 octets | signalé |
| Photo de 199 500 puis 200 000 octets | acceptée, puis refusée : la limite est bien à 200 000 avec le document |
| Variantes 1x (120 000) et 2x (150 000) | acceptées — seule la plus lourde compte ; refusées quand la 2x passe à 199 900 |
| Onze ressources, puis dix | refusées, puis acceptées |
| 801 éléments | refusés |
| `app.js`, puis `police.woff2` | refusés tous les deux |
| Image référencée mais absente | signalée |
| PDF de 400 000 octets lié depuis la page | accepté : c'est un lien |
| Production absente | code 2 |

`scripts/check.sh` : « 5 contrôle(s) passés ». `scripts/tests/run.sh` : 244 cas réussis (231 avant la story, 13 ajoutés).

## Revue du code

### 19/09/2026 — `250ace3` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 47. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 2ddc5f0258693be293841003

##### BMad Review

###### Lentille : Edge-Case Hunter

- **location** : `scripts/checks/budget.sh:48-51`
- **trigger_condition** : Les sources d'images responsives via la balise `<picture>` sont ignorées.
- **guard_snippet** : `attributs "$page" '//source/@srcset' srcset | tr ',' '\n' | awk 'NF { print $1 }'`
- **potential_consequence** : Les déclinaisons d'images dans `<picture><source>` échappent au calcul du poids de la page.

###### Lentille : Verification Gap

- **location** : `scripts/tests/test-budget.sh:40-49`
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh:73` (boucle additionnant la taille de la CSS au budget de la page)
- **evidence** : `case_budget_page_complete` provoque intentionnellement le dépassement du plafond uniquement avec une balise `<img>`, sans jamais vérifier que le poids de la CSS est bien inclus dans l'addition finale.
- **trigger_condition** : L'inclusion de la CSS dans le calcul de la "page complète" n'est pas testée.
- **guard_snippet** : `sortie '<link rel=stylesheet href=/a.css>'; octets "$work/public/a.css" 199500; budget`
- **potential_consequence** : Une régression dans l'extraction des balises `<link>` fausserait le budget de la page sans faire échouer les tests.

- **location** : `scripts/tests/test-budget.sh:95-105`
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh:30` (commande `find` listant les extensions interdites)
- **evidence** : `case_budget_javascript_ou_police` se limite à vérifier l'échec sur les extensions `.js` et `.woff2`.
- **trigger_condition** : Le rejet des autres extensions (`.mjs`, `.woff`, `.ttf`, `.otf`, `.eot`) n'est pas validé par le test.
- **guard_snippet** : `octets "$work/public/script.mjs" 10; budget` (et vérifier l'échec)
- **potential_consequence** : Le retrait accidentel d'une de ces extensions dans l'expression `-name` du script ne serait pas détecté.

##### Constats propres au projet (eleyone.fr)

* BLOQUANT : Les substitutions de processus `< <(find ...)` (ex. lignes 31, 37, 77 de `scripts/checks/budget.sh`) masquent le code de retour de la commande `find`, laissant passer un échec de lecture du système de fichiers en silence.
* BLOQUANT : L'utilisation de `|| true` avec `xmllint` (ligne 38) et `grep` (ligne 41) de `scripts/checks/budget.sh` masque toutes les erreurs (fichiers illisibles, crashs), alors qu'elle ne devrait ignorer que les codes de retour spécifiques à l'absence de correspondances.
* NON BLOQUANT : Les critères d'acceptation de la story sont intégralement satisfaits et leur intention est préservée (l'unité d'1 Ko = 1 000 octets est notamment respectée).
* NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte, aucune adresse de serveur ni aucun secret n'est commité, et l'affichage des scripts est sûr.
* NON BLOQUANT : Le skill, le script et la procédure (`docs/procedures/check.md`) concordent parfaitement sur les éléments vérifiés.
* NON BLOQUANT : Le changement implémenté est en parfaite cohérence avec `AGENTS.md` et les décisions de l'architecture (notamment AD-8).

VERDICT: BLOQUANT — des erreurs shell sont masquées en silence par des substitutions de processus et l'usage global de "|| true".

Décisions de l'auteur sur la revue du code de la PR n° 47 (`250ace3`, verdict `block`) : les deux constats sont **retenus, corrigés, et la correction dépasse ce fichier**.

Les codes de sortie ont d'abord été mesurés : `xmllint` rend **10** quand aucun nœud ne correspond et **1** s'il ne peut pas lire le fichier ; `grep` rend 1 sans correspondance et 2 en erreur ; `find` rend 1 sur un dossier absent. « Rien trouvé » se distingue donc d'une vraie erreur, ce que `|| true` empêchait.

Trois enveloppes communes sont ajoutées à `scripts/checks/lib.sh` — `checks_xpath`, `checks_grep`, `checks_find` — et **les quatre contrôles** les emploient : `budget.sh` (cette story), mais aussi `html.sh`, `links.sh` et `content.sh`, qui portaient le même défaut. Un fichier illisible rend désormais **2** avec un message qui le nomme, au lieu de passer pour conforme ; un cas de test le vérifie.

### 19/09/2026 — `01b0f25` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 47. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 886bb8ba6de096c716687352

##### BMad Review

###### Lentille : Edge-Case Hunter

- **location** : `scripts/checks/budget.sh:100-105` (bloc d'extraction des ressources)
- **trigger_condition** : Les sources d'images responsives via la balise `<picture>` (attributs `srcset` sur `<source>`) restent ignorées du calcul du budget.
- **guard_snippet** : `attributs "$page" '//source/@srcset' srcset | tr ',' '\n' | awk 'NF { print $1 }'`
- **potential_consequence** : Les déclinaisons d'images dans `<picture><source>` échappent toujours au calcul du poids de la page, ce qui fausserait le budget. Le constat de la revue précédente n'a pas été corrigé.

###### Lentille : Verification Gap

- **location** : `scripts/tests/test-budget.sh:55-64` (`case_budget_page_complete`)
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh` (addition de la CSS au budget de la page)
- **evidence** : `case_budget_page_complete` provoque le dépassement du plafond uniquement avec une balise `<img>`, sans jamais vérifier que le poids de la CSS est bien inclus dans l'addition finale de la page.
- **trigger_condition** : L'inclusion de la CSS dans le calcul de la "page complète" n'est toujours pas testée.
- **guard_snippet** : `sortie '<link rel=stylesheet href=/a.css>'; octets "$work/public/a.css" 199500; budget`
- **potential_consequence** : Une régression dans l'extraction des balises `<link>` fausserait le budget de la page sans faire échouer les tests. Ce constat n'a pas été corrigé.

- **location** : `scripts/tests/test-budget.sh` (`case_budget_javascript_ou_police`)
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh` (recherche des extensions interdites avec `checks_find`)
- **evidence** : L'auteur n'a pas étendu le test aux autres extensions (`.mjs`, `.ttf`, etc.) mentionnées dans la précédente revue.
- **trigger_condition** : Le rejet des autres extensions (`.mjs`, `.woff`, `.ttf`, `.otf`, `.eot`) n'est toujours pas validé par le test.
- **guard_snippet** : Ajouter des fichiers avec ces extensions dans le répertoire de test et vérifier l'échec.
- **potential_consequence** : Le retrait accidentel d'une de ces extensions dans l'expression `-name` du script ne serait pas détecté.

##### Constats propres au projet (eleyone.fr)

- BLOQUANT : Les substitutions de processus `< <(checks_find ...)` et `< <(checks_xpath ... | ...)` continuent de masquer le code de retour des commandes dans `budget.sh`, `html.sh` et `links.sh`. Bien que `checks_find` et `checks_xpath` exécutent un `exit 2` en cas d'erreur, bash ignore silencieusement le code de retour des sous-shells de substitution de processus. L'erreur passe donc toujours en silence et le script principal peut réussir avec un code 0. Le cas de test de l'auteur (`case_budget_fichier_illisible_est_une_anomalie`) réussit uniquement car il repose sur une affectation de variable avec substitution de commande (`elements=$(checks_xpath ...)`), un contexte où bash applique bien le `set -e`, contrairement aux substitutions de processus.
- NON BLOQUANT : L'encapsulation de `grep` par `checks_grep` est correcte et résout bien le masquage des erreurs par `|| true` dans les pipelines, évitant de confondre une erreur d'exécution avec une simple absence de résultat.
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (l'unité d'1 Ko = 1 000 octets est respectée, et le décompte par variante la plus lourde est appliqué).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent (la procédure mentionne explicitement C13 et ses critères).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-8 mis à jour correctement).

VERDICT: BLOQUANT — Les substitutions de processus < <(...) masquent toujours les codes d'erreur des sous-shells en ignorant leur code de retour, et les constats précédents de la revue BMAD sur les edge-cases et manques de test n'ont pas été corrigés.

Décisions de l'auteur sur la deuxième revue de la PR n° 47 (`01b0f25`, verdict `block`) : constat **retenu et corrigé**. Le relecteur a raison, et sa démonstration est juste : mes enveloppes s'arrêtent bien par `exit`, mais `exit` dans une substitution de processus `< <(…)` ne remonte pas au script — mon cas de test ne passait que parce qu'il traversait une **substitution de commande**, où `set -e` s'applique. Les **seize** boucles des trois contrôles lisent désormais leur liste dans une variable, avec `|| exit $?`, et il ne reste aucune substitution de processus dans `scripts/checks/`. C'est le motif que `docs/procedures/shell-scripts.md` prescrit depuis la story 0.6.

Vérifié en conditions réelles : une page illisible fait rendre **2** à `html.sh` comme à `links.sh`, avec le message qui la nomme. Deux cas de test l'ajoutent, en plus de celui de `budget.sh`.

### 19/09/2026 — `18df5db` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 47. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a4270ecf952cf13171f998eb

##### BMad Review

###### Lentille : Edge-Case Hunter

- **location** : `scripts/checks/budget.sh:100-105`
- **trigger_condition** : Les sources d'images responsives via la balise `<picture>` (attributs `srcset` sur `<source>`) restent ignorées du calcul du budget.
- **guard_snippet** : `attributs "$page" '//source/@srcset' srcset | tr ',' '\n' | awk 'NF { print $1 }'`
- **potential_consequence** : Les déclinaisons d'images dans `<picture><source>` échappent au calcul du poids de la page.

###### Lentille : Verification Gap

- **location** : `scripts/tests/test-budget.sh:54-63`
- **trigger_condition** : L'inclusion de la CSS dans le calcul de la "page complète" n'est toujours pas testée.
- **guard_snippet** : `sortie '<link rel=stylesheet href=/a.css>'; octets "$work/public/a.css" 199500; budget`
- **potential_consequence** : Une régression dans l'extraction des balises `<link>` fausserait le budget sans faire échouer les tests.
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh` (addition de la CSS au budget)
- **evidence** : `case_budget_page_complete` provoque le dépassement du plafond avec seulement une balise `<img>`.

- **location** : `scripts/tests/test-budget.sh:109-119`
- **trigger_condition** : Le rejet des autres extensions JS et polices (`.mjs`, `.woff`, `.ttf`, etc.) n'est toujours pas validé.
- **guard_snippet** : Ajouter `octets "$work/public/script.mjs" 10; budget` et vérifier l'échec.
- **potential_consequence** : Le retrait accidentel d'une de ces extensions dans la commande `find` ne serait pas détecté.
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh` (recherche des extensions interdites avec `checks_find`)
- **evidence** : `case_budget_javascript_ou_police` se limite toujours à vérifier l'échec sur les seules extensions `.js` et `.woff2`.

##### Couche propre au projet (eleyone.fr)

- BLOQUANT : Dans les scripts shell, une erreur passe en silence sous set -euo pipefail : la fonction `xpath_attributs` de `scripts/checks/html.sh` se termine toujours par `|| true`. Si `checks_xpath` échoue (ex: fichier illisible, code 2), le pipeline échoue, mais `|| true` force la fonction à renvoyer 0. L'appelant `liste=$(xpath_attributs ...) || exit $?` ne s'interrompt pas, avalant l'erreur.
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture.

VERDICT: BLOQUANT — une erreur shell est toujours masquée en silence par "|| true" dans xpath_attributs (html.sh), et les constats de la précédente revue (edge-case et verification gaps) n'ont pas été corrigés.

Décisions de l'auteur sur la troisième revue de la PR n° 47 (`18df5db`, verdict `block`) : constat **retenu et corrigé**. Le point est subtil et juste : un `exit` dans un **élément de pipeline** ne quitte que son sous-shell, et le `|| true` final de la fonction d'extraction transformait l'anomalie en succès — mon essai précédent ne l'avait pas vu parce qu'il empruntait un autre chemin, l'appel direct à `checks_xpath`. Les trois fonctions d'extraction (`html.sh`, `links.sh`, `budget.sh`) lisent désormais le XPath **avant** de filtrer, et propagent son code. Vérifié : avec une page illisible, les trois contrôles rendent **2**, alors que `budget.sh` et `links.sh` passaient auparavant par cette fonction sans rien dire.

**Pour la rétrospective de l'epic 3** : trois passes bloquantes sur le même thème, et chacune a trouvé un endroit de plus où une erreur se perdait — `|| true` global, substitution de processus, puis pipeline dans une fonction. La règle « aucune erreur en silence » est facile à énoncer et difficile à tenir en shell : elle mérite une entrée dédiée dans les pièges connus, avec les trois formes.

### 19/09/2026 — `f5ee67f` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 47. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1aa0219ac68247e1ec2d1677

##### BMad Review

###### Lentille : Edge-Case Hunter

- **location** : `scripts/checks/budget.sh:107-112`
- **trigger_condition** : Les sources d'images responsives via la balise `<picture>` (attributs `srcset` sur `<source>`) restent ignorées du calcul du budget.
- **guard_snippet** : `attributs "$page" '//source/@srcset' srcset | tr ',' '\n' | awk 'NF { print $1 }'`
- **potential_consequence** : Les déclinaisons d'images dans `<picture><source>` échappent au calcul du poids de la page. (Constat précédent non corrigé).

###### Lentille : Verification Gap

- **location** : `scripts/tests/test-budget.sh:54-63`
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh` (addition de la CSS au budget de la page complète)
- **evidence** : `case_budget_page_complete` provoque le dépassement du plafond uniquement avec une balise `<img>`.
- **trigger_condition** : L'inclusion de la CSS dans le calcul de la "page complète" n'est toujours pas testée.
- **guard_snippet** : `sortie '<link rel=stylesheet href=/a.css>'; octets "$work/public/a.css" 199500; budget`
- **potential_consequence** : Une régression dans l'extraction des balises `<link>` fausserait le budget sans faire échouer les tests. (Constat précédent non corrigé).

- **location** : `scripts/tests/test-budget.sh:109-119`
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh` (recherche des extensions interdites avec `checks_find`)
- **evidence** : `case_budget_javascript_ou_police` se limite toujours à vérifier l'échec sur les seules extensions `.js` et `.woff2`.
- **trigger_condition** : Le rejet des autres extensions JS et polices (`.mjs`, `.woff`, `.ttf`, etc.) n'est toujours pas validé.
- **guard_snippet** : Ajouter `octets "$work/public/script.mjs" 10; budget` et vérifier l'échec.
- **potential_consequence** : Le retrait accidentel d'une de ces extensions dans la commande `find` ne serait pas détecté. (Constat précédent non corrigé).

##### Constats propres au projet (eleyone.fr)

- BLOQUANT : Dans `scripts/checks/html.sh`, l'affectation `appels_css=$({ checks_grep ... | checks_grep ... || true; }) || exit $?` masque les erreurs de lecture. Le `|| true` final s'applique à l'ensemble du pipeline. Si le premier `checks_grep` échoue sur un fichier illisible (code 2), son `exit 2` quitte le sous-shell du pipeline, mais le `|| true` force la substitution de commande entière à réussir (code 0). Ainsi, un fichier CSS illisible passera le contrôle en silence (le cas de test ajouté ne vérifie qu'un fichier HTML, qui est intercepté plus haut par `xpath` avant d'atteindre ce bloc).
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture.

VERDICT: BLOQUANT — une erreur shell est masquée en silence par "|| true" sur un pipeline complet dans html.sh (appels_css), et les constats de la revue précédente n'ont pas été corrigés.

Décisions de l'auteur sur la quatrième revue de la PR n° 47 (`f5ee67f`, verdict `block`) : constat **retenu et corrigé**, puis **audit complet** du motif. Le `|| true` de la recherche d'appels CSS couvrait tout le pipeline : un fichier CSS illisible, que le XPath ne touche jamais, passait en silence. Le fichier est désormais lu d'abord, avec son code, et le filtrage s'applique à une chaîne déjà en mémoire ; même traitement pour la recherche des marqueurs `[TODO`.

J'ai ensuite relu **tous** les `|| true` restants des six fichiers de `scripts/checks/` : les uns portent sur une chaîne déjà lue (aucune erreur de lecture possible), les autres sur un élément de pipeline dont l'échec remonte par `pipefail`. Vérifié en conditions réelles pour les deux `grep -rl` de `links.sh` : un fichier illisible fait rendre **2**. Un cas de test couvre le CSS illisible.

### 19/09/2026 — `4639f9a` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 47. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ab0679c1d01ebf5f66abc548

##### Revue BMad

###### Lentille : Edge-Case Hunter
BLOQUANT : `location`: scripts/checks/budget.sh | `trigger_condition`: Les sources d'images via la balise `<source>` (ex: `<picture>`) restent ignorées du calcul. | `guard_snippet`: `attributs "$page" '//source/@srcset' srcset | tr ',' '\n' | awk 'NF { print $1 }'` | `potential_consequence`: Ces images échappent au calcul du poids de la page, ce qui casse le critère comptant toutes les images référencées.

###### Lentille : Verification Gap
NON BLOQUANT : `location`: scripts/tests/test-budget.sh (`case_budget_page_complete`) | `trigger_condition`: L'inclusion de la CSS dans le calcul de la "page complète" n'est toujours pas testée. | `guard_snippet`: `sortie '<link rel=stylesheet href=/a.css>'; octets "$work/public/a.css" 199500; budget` | `potential_consequence`: Une régression dans l'extraction des balises `<link>` fausserait le budget sans faire échouer les tests. | `gap_shape`: regression-gap | `consumer`: scripts/checks/budget.sh
NON BLOQUANT : `location`: scripts/tests/test-budget.sh (`case_budget_javascript_ou_police`) | `trigger_condition`: Le rejet des autres extensions JS et polices (`.mjs`, `.woff`, `.ttf`, etc.) n'est toujours pas validé. | `guard_snippet`: Ajouter `octets "$work/public/script.mjs" 10; budget` et vérifier l'échec. | `potential_consequence`: Le retrait accidentel d'une de ces extensions dans l'expression `-name` du script ne serait pas détecté. | `gap_shape`: regression-gap | `consumer`: scripts/checks/budget.sh

##### Constats propres au projet (eleyone.fr)
NON BLOQUANT : Les critères d'acceptation de la story sont globalement satisfaits et vérifiés, à l'exception notable de la balise `<source>` signalée en anomalie bloquante.
NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
NON BLOQUANT : Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure.
NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-8).
NON BLOQUANT : L'audit du développeur est un succès : dans les scripts shell, aucune erreur ne passe plus en silence sous set -euo pipefail (les éléments de pipeline et les substitutions masquant les erreurs ont été purgés de manière robuste).

VERDICT: BLOQUANT — Les images responsives utilisant la balise <source> échappent toujours au calcul du budget (cassant le critère des images référencées), et les manques de test signalés précédemment demeurent ignorés.

Décisions de l'auteur sur la cinquième revue de la PR n° 47 (`4639f9a`, verdict `block`) : les trois constats sont **retenus et corrigés**. Les images d'un `<picture><source>` échappaient au budget : `source/@src` et `source/@srcset` entrent désormais dans le calcul, avec leur cas de test. Deux règles sans test en ont un : la CSS comptée dans le total de la page, et les sept extensions interdites vérifiées une par une.

### 19/09/2026 — `7426a6e` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 47. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d38ae160daaffa3c2f272156

##### BMad Review

###### Lentille : Edge-Case Hunter

- **location** : `scripts/checks/budget.sh:120-123`
- **trigger_condition** : Une même ressource appelée plusieurs fois dans le DOM (ex: une icône SVG ou un logo répété) est comptée plusieurs fois dans la limite des 10 ressources.
- **guard_snippet** : Dédupliquer le tableau `ressources` (par exemple en comptant simplement le nombre de clés du tableau associatif `poids_par_media`) avant d'évaluer le plafond.
- **potential_consequence** : Une page affichant plusieurs occurrences d'une même image échouera à tort au contrôle du nombre maximal de ressources, alors que le navigateur ne fait pourtant qu'une seule requête HTTP pour la récupérer.

###### Lentille : Verification Gap

- **location** : `scripts/tests/test-budget.sh` (autour de `case_budget_nombre_de_ressources`)
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh:120` (calcul de la taille du tableau `ressources`)
- **evidence** : `case_budget_nombre_de_ressources` utilise 11 images distinctes (`i1.webp` à `i11.webp`) et ne teste jamais le cas où une même image serait incluse 11 fois dans la page.
- **trigger_condition** : Le décompte correct et dédupliqué des ressources réseau n'est pas vérifié par les tests.
- **guard_snippet** : `for i in {1..11}; do corps+="<img src=/unique.webp alt=x width=10 height=10>"; done; sortie "$corps"; octets "$work/public/unique.webp" 100; budget` et vérifier que le contrôle réussit avec `assert_eq 0 "$rc"`.
- **potential_consequence** : Le script actuel compte les ressources en doublon, et l'absence de ce test empêche d'identifier cette anomalie logique.

##### Constats propres au projet (eleyone.fr)

- BLOQUANT : L'intention du critère d'acceptation "plus de 10 ressources chargées par une page" n'est pas respectée car les doublons présents dans le DOM sont comptés plusieurs fois, pénalisant injustement la page alors que son nombre réel de requêtes réseau est conforme.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-8).
- NON BLOQUANT : Dans les scripts shell, plus aucune erreur ne passe en silence sous set -euo pipefail ; l'audit de l'auteur est un franc succès grâce aux enveloppes fiables `checks_xpath`, `checks_grep` et `checks_find`.

VERDICT: BLOQUANT — Les ressources appelées en plusieurs exemplaires dans une page sont comptées en double dans la limite des 10 ressources, faussant l'évaluation du budget.

Décisions de l'auteur sur la sixième revue de la PR n° 47 (`7426a6e`, verdict `block`) : constat **retenu et corrigé**. Une même URL citée deux fois dans une page n'est qu'une requête : le décompte porte désormais sur les ressources **distinctes**, avec un cas de test à douze balises pour dix ressources.

### 19/09/2026 — `13526ba` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 47. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 386de965225c5a2d1b02a4a8

##### BMad Review

###### Lentille : Edge-Case Hunter
Aucun cas limite non géré n'a été identifié. La déduplication des ressources réseau et la propagation des codes d'erreur dans les pipelines et sous-shells ont été résolues de manière exhaustive et robuste.

###### Lentille : Verification Gap

- **location** : `scripts/tests/test-budget.sh`
- **trigger_condition** : L'inclusion des images référencées via `src` sur une balise `<source>` ou via l'attribut `poster` (ex: sur une `<video>`) n'est pas testée.
- **guard_snippet** : Ajouter un cas de test avec `sortie '<video poster="/poster.webp"><source src="/grande.webp"></video>'` et vérifier que leurs poids sont bien inclus au budget global.
- **potential_consequence** : Une suppression accidentelle ou une régression sur les extractions XPath de `//source/@src` et `//*[@poster]/@poster` ne ferait échouer aucun test.
- **gap_shape** : `regression-gap`
- **consumer** : `scripts/checks/budget.sh`
- **evidence** : `case_budget_source_dune_picture` vérifie correctement l'attribut `srcset` sur `<source>`, mais les autres attributs d'images référencées explicitement extraits par `budget.sh` (comme le `poster`) demeurent sans couverture de test.

##### Constats propres au projet (eleyone.fr)

- NON BLOQUANT : Les critères d'acceptation de la story sont entièrement satisfaits, y compris le décompte strict des ressources uniques par page et l'application stricte de l'unité des octets.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent : `docs/procedures/check.md` cite fidèlement les critères vérifiés par le contrôle C13 et les autres scripts.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-8).
- NON BLOQUANT : L'audit du développeur est un succès total : dans les scripts shell, aucune erreur ne passe plus en silence sous `set -euo pipefail`. Les pipelines masquant les codes de retour et les substitutions de processus fautives ont été remplacés par des structures fiables (via `checks_xpath`, `checks_grep` et `checks_find`).

VERDICT: NON BLOQUANT — un manque de test mineur sur l'extraction des attributs src et poster a été relevé, mais le code livré est conforme, déduplique correctement les ressources et ne masque plus aucune erreur shell.

Décisions de l'auteur sur la septième revue de la PR n° 47 (`13526ba`, verdict `pass`) : aucun constat.

**Pour la rétrospective de l'epic 3** : sept passes, six bloquantes, **toutes justes**. Quatre portaient sur la même règle — « aucune erreur en silence » — et chacune a trouvé une forme de plus : `|| true` global, substitution de processus, pipeline dans une fonction, pipeline dans une affectation. Les trois autres ont trouvé de vrais trous du contrôle (images d'un `<picture>`, ressources comptées en double, couverture de test). Deux enseignements : cette règle mérite l'entrée dédiée qu'elle a désormais dans les pièges connus, et un contrôle qui parcourt des fichiers demande d'emblée un essai sur un fichier illisible, comme on essaie un fichier absent.

## Reporté
