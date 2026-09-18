# Story 3.9 : Automated accessibility checks

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.9.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `1b0a38e`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a6bff386119897cbfa187897

Voici le rapport de revue de la spec 3.9, établi en appliquant les lentilles du skill BMad Review :

##### 🕵️ Lentille Adversarial (Adversarial Lens)

- **Contradiction avec l'architecture sur le `<title>`**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** C11 doit signaler un `<title>` "sans la ligne d'identité". Or, la décision AD-2 (mise à jour du 16/09/2026, story 2.2) exempte explicitement la page d'accueil de cette ligne d'identité pour éviter la répétition du nom.
  - **Correction :** Exempter l'accueil de cette vérification spécifique.
  - **Conséquence :** Si implémenté tel quel, le contrôle échouera systématiquement sur l'accueil, bloquant un build valide.

- **Critère "nom accessible" invérifiable textuellement**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** Les scripts de contrôle utilisent `xmllint` ou `jq` (cf. AD-10) et ne calculent pas l'arbre d'accessibilité. "Lien sans nom accessible" est trop générique pour un parseur statique.
  - **Correction :** Préciser techniquement ce que le script doit chercher (ex: lien sans texte interne ET sans `aria-label` ET sans `aria-labelledby` ET sans `title` ET sans `<img>` avec `alt`).
  - **Conséquence :** Le développeur devra deviner la règle, risquant des faux positifs sur des liens iconographiques valides, ou des faux négatifs.

- **Vérification incomplète du `hreflang`**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** Exiger uniquement qu'`hreflang` ne soit pas "absent" ne garantit pas la conformité. AD-2 exige une balise par traduction PLUS `hreflang="x-default"`.
  - **Correction :** Vérifier explicitement la présence de `x-default`.
  - **Conséquence :** Déviation silencieuse de l'architecture bilingue sans alerte de la CI.

- **Valeur de `<html lang>` non contrôlée**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** Le script signale `<html lang>` "absent", mais ne semble pas vérifier sa valeur.
  - **Correction :** S'assurer que la valeur de `lang` correspond bien à la langue de la page rendue (`fr` ou `en`).
  - **Conséquence :** Une page anglaise pourrait être servie avec `lang="fr"` par erreur de gabarit sans que C11 ne bronche.

- **Cas particulier des pages 404**
  - **Emplacement :** Critères d'acceptation, 1er bloc ("404 comprises")
  - **Déclencheur :** Hugo ne génère généralement pas de `.Translations` pour les pages 404. La vérification du `hreflang` risque d'y échouer systématiquement.
  - **Correction :** Définir si la page 404 bénéficie d'une exception sur le `hreflang` (ou documenter l'astuce Hugo pour les lier).
  - **Conséquence :** La CI sera bloquée indéfiniment par la 404.

- **Source de la "ligne d'identité" non définie pour le script**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** Le script de contrôle ne doit pas coder le texte de la ligne d'identité en dur (fragilité si Arnaud modifie son _index).
  - **Correction :** Spécifier que C11 lit l'identité attendue depuis le manifeste `checks.json` défini dans AD-10.
  - **Conséquence :** Duplication de la donnée entre le contenu (`content/_index.md`) et le code source du script bash.

- **Lieu d'automatisation des fixtures manquant**
  - **Emplacement :** Critères d'acceptation, 2e bloc ("une copie locale qui introduit chaque défaut...")
  - **Déclencheur :** Le texte suggère une vérification, mais ne précise pas l'intégration à la suite de tests existante.
  - **Correction :** Exiger que cette validation soit ajoutée sous forme de fixtures dans le harnais de test hors-ligne des scripts (`scripts/tests/run.sh`).
  - **Conséquence :** Le test sera fait une fois manuellement, sans prémunir le projet contre les régressions futures du script de contrôle lui-même.

- **Faux positifs potentiels sur les sauts de niveau de titre**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** L'évaluation d'un "saut de niveau" sur tout le document HTML peut échouer si un gabarit de pied de page contient par exemple un `<h2>` alors que le contenu principal s'est arrêté à `<h1>`.
  - **Correction :** Préciser comment C11 extrait les titres (parcourir l'ordre du DOM via xmllint, ou utiliser la liste `headings` du manifeste `checks.json`).
  - **Conséquence :** Signalements erronés bloquant le déploiement sur des pages architecturalement correctes.

- **Couverture des balises images**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** Le test cible explicitement `<img>`. Si la photo (AD-19) évolue un jour vers `<picture>` ou si un SVG inline était introduit, l'accessibilité ne serait plus vérifiée.
  - **Correction :** Confirmer que cibler `<img>` suffit (puisque `<picture>` contient toujours un `<img>` de repli pour le `alt`), mais le noter pour sécuriser l'approche technique.
  - **Conséquence :** Potentiel trou dans la raquette de l'accessibilité si le markup évolue.

- **Formulation ambiguë pour le H1**
  - **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** L'expression "zéro ou plusieurs `<h1>`" peut être comprise comme une tolérance mathématique ("il peut y en avoir zéro ou plusieurs") au lieu d'une condition d'alerte.
  - **Correction :** Reformuler en "absence de `<h1>` ou plus d'un `<h1>`".
  - **Conséquence :** Confusion lors de la rédaction du script (`if count == 0 || count > 1`).

##### 🏗️ Lentille Structure (Structure Lens)

- **Avis général** : Le document est dense, bien centré sur l'action et suit fidèlement les modèles de stories.
- **Trou de spécification (GAP)** : Le lien entre le comportement du script et l'outillage de test existant (`scripts/tests/run.sh`) est absent. Les critères valident le quoi, mais oublient de fixer *où* le test automatique doit résider. *(Action : CONDENSE / MOVE vers une exigence d'automatisation des tests)*.

##### ✍️ Lentille Prose (Prose Lens)

- **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** "zéro ou plusieurs `<h1>`"
  - **Fix suggéré :** Considérer : "signale l'absence de `<h1>` ou la présence de plusieurs `<h1>`" pour lever toute ambiguïté syntaxique.
- **Emplacement :** Critères d'acceptation, 1er bloc
  - **Déclencheur :** "lien sans nom accessible"
  - **Fix suggéré :** Considérer une formulation plus ancrée dans la technique du parseur : "lien vide (sans texte, `aria-label` ni `title`)".

---

##### À trancher avant d'implémenter

- **Exception pour l'accueil** : Confirmes-tu que le script C11 doit ignorer l'absence de ligne d'identité dans le `<title>` de la page d'accueil (pour respecter la décision AD-2 du 16/09) ?
- **Pages 404** : Doit-on exempter la page 404 de la vérification du `hreflang`, étant donné la difficulté de la lier comme traduction classique dans Hugo ?
- **"Nom accessible" textuel** : Comment souhaites-tu que `xmllint` évalue un lien ? (Par exemple : `texte() != ""` OU présence de `aria-label`, OU `title`, OU `<img>` avec un attribut `alt` ?)
- **Lecture de l'identité** : Es-tu d'accord pour que le script de contrôle ne code pas la ligne d'identité en dur, mais la lise dynamiquement dans le manifeste JSON (clé issue de `content/_index.md`) ?
- **Tests unitaires** : La "copie locale" du second critère doit-elle prendre la forme de fixtures automatisées dans `scripts/tests/run.sh` ?

### Triage des constats (18/09/2026)

Aucune question à Arnaud : les cinq points « à trancher » se règlent par AD-2, AD-17 ou un constat sur la sortie réelle.

| Constat | Décision | Suite |
| --- | --- | --- |
| Exception du `<title>` de l'accueil | **retenu** | AD-2, décidé le 16/09 à la story 2.2 : l'accueil fait exception, son titre portant déjà le nom. Constaté sur la sortie : `Arnaud Grousset · Développeur backend senior` en accueil, `404 Page not found · Arnaud Grousset · Eleyone` ailleurs. Sans l'exception, le contrôle refuserait les deux accueils |
| `hreflang` sur les 404 | **refusé** | constat sur la sortie réelle : les 404 portent leurs trois `link rel=alternate hreflang` (`fr`, `en`, `x-default`). Aucune exemption n'est nécessaire |
| Définition du nom accessible d'un lien | **retenu** | un lien a un nom s'il a du texte, un `aria-label`, un `title`, ou une image au `alt` non vide. Rien d'autre n'est lisible sans navigateur |
| Ligne d'identité lue, non écrite en dur | **retenu** | elle vient du manifeste (`front_matter.identity` de l'accueil), déjà produit par le rendu de travail que `check.sh` lance avant les contrôles |
| Forme des cas de test | **retenu** | fixtures HTML sous `scripts/tests/`, comme la story 3.8 ; aucun essai ne touche `content/` |
| « zéro ou plusieurs `<h1>` » ambigu | **retenu** | le critère dit « aucun `<h1>`, ou plus d'un » |

## Ce qui est livré

- `scripts/checks/html.sh` gagne C11, sur chaque page du build de production : langue déclarée, titre non vide et porteur de la ligne d'identité (accueil excepté, AD-2), un seul `h1`, aucun saut de niveau, identifiants uniques, images décrites et dimensionnées, liens nommés, `hreflang` présents, aucun `tabindex` positif.
- La ligne d'identité est **lue dans le manifeste** (`front_matter.identity` de l'accueil), jamais écrite en dur ; son absence est une anomalie.
- `scripts/tests/test-html.sh` : douze cas de plus, chacun avec son pendant conforme ; les fixtures portent leur propre manifeste, pour ne pas dépendre du build du dépôt.
- `docs/procedures/check.md` décrit les nouvelles règles.

### Ce que l'exception de l'accueil a évité

Avant d'écrire la règle, j'ai comparé les titres réels : `Arnaud Grousset · Développeur backend senior` en accueil, `404 Page not found · Arnaud Grousset · Eleyone` ailleurs. Appliquée à la lettre, la règle « le titre contient la ligne d'identité » aurait refusé **les deux accueils** du site. L'exception d'AD-2 est donc reprise telle quelle, avec son cas de test.

### Essais

| Essai | Résultat |
| --- | --- |
| Production réelle | code 0 : « zéro script, aucune ressource tierce, aucun marqueur, structure accessible » |
| `lang` retiré, titre vide, titre sans identité | un signalement chacun |
| Deux `h1`, aucun `h1`, saut de `h2` à `h4` | signalés, avec le compte ou les deux niveaux |
| Identifiant en double | signalé, avec son nom |
| Image sans `alt`, image sans dimensions | signalées séparément |
| Lien vide ; lien à `aria-label` ; lien contenant une image décrite | le premier refusé, les deux autres acceptés |
| `hreflang` retirés | signalé |
| `tabindex=1` refusé, `tabindex=0` accepté | conforme à 2.4.3 |
| Manifeste absent | code 2, message qui dit quoi lancer |

`scripts/check.sh` : « 3 contrôle(s) passés ». `scripts/tests/run.sh` : 218 cas réussis (206 avant la story, 12 ajoutés).

## Revue du code

### 18/09/2026 — `ee4e14d` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 45. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 5602d598467e07d3a7f8f5f7

##### Rapport de revue (BMAD Review)

###### 🕵️ Lentille Edge-Case Hunter (edge-case-hunter)

* `location`: `scripts/checks/html.sh:300` (vérification de `liens_muets`)
  * `trigger_condition`: Un lien sans texte mais avec `aria-label=""` ou `title=""` (chaîne vide).
  * `guard_snippet`: `[not(@aria-label) or normalize-space(@aria-label) = ''][not(@title) or normalize-space(@title) = '']`
  * `potential_consequence`: Un lien sans nom accessible réel échappe au contrôle.
* `location`: `scripts/checks/html.sh:309` (vérification du `tabindex`)
  * `trigger_condition`: L'attribut `tabindex` positif est précédé d'espaces, de zéros ou d'un signe plus (`+1`, ` 1 `, `01`).
  * `guard_snippet`: `[[ $(echo "$valeur" | tr -d ' +0') =~ ^[1-9] ]]`
  * `potential_consequence`: Un tabindex positif valide HTML5 perturbe la tabulation sans être signalé.

###### 🔍 Lentille Verification-Gap (verification-gap)

Aucun écart de vérification trouvé (No verification gaps found). Les nouveaux comportements ajoutés par C11 sont vérifiés par la suite de tests (`scripts/tests/test-html.sh`) qui couvre bien les cas passants et les anomalies prévues.

##### 🏗️ Couche propre au projet

* BLOQUANT : Les implémentations des contrôles pour les liens muets et le tabindex ignorent des cas marginaux (attributs vides, espaces, signes) ; l'intention des critères d'acceptation visant à bloquer le code inaccessible est donc partiellement vidée.
* NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte de serveur et aucun secret n'est commité, exposé ou affiché.
* NON BLOQUANT : La mise à jour de la documentation (`docs/procedures/check.md`) concorde fidèlement avec le script `html.sh`.
* NON BLOQUANT : L'implémentation est cohérente avec les décisions d'architecture, notamment en respectant l'exemption de la page d'accueil (AD-2) et la lecture du manifeste (AD-19).
* NON BLOQUANT : Les commandes dans les scripts shell sont gérées proprement ; aucune commande ne plante silencieusement sous `set -euo pipefail` (la bonne exécution des tests unitaires le prouve).

VERDICT: BLOQUANT — Les contrôles de liens muets et de tabindex laissent passer des anomalies (attributs vides, espaces, signes), ce qui casse l'intention des critères d'acceptation.

Décisions de l'auteur sur la revue du code de la PR n° 45 (`ee4e14d`, verdict `block`) : les deux constats sont **retenus et corrigés**. Un `aria-label` ou un `title` **vide** ne nomme rien : la règle exige désormais du texte, et deux cas de test le vérifient. Un `tabindex` s'écrit aussi `+1`, `01` ou entouré d'espaces, formes valides en HTML5 : la valeur est normalisée avant comparaison, avec quatre cas de test — `+1` et `01` refusés, `0` et `-1` acceptés.

### 18/09/2026 — `1fa0283` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 45. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: cf46ba535bb0071097625146

##### Rapport de revue (BMAD Review)

###### 🕵️ Lentille Edge-Case Hunter (edge-case-hunter)

* `location`: `scripts/checks/html.sh:207`
  * `trigger_condition`: `grep -oE` retourne 1 si la page inspectée ne contient aucun titre `h1`-`h6`.
  * `guard_snippet`: `done < <(xpath "$page" '//h1|//h2|//h3|//h4|//h5|//h6' | grep -oE '<h[1-6]' | tr -d '<h' || true)`
  * `potential_consequence`: Une erreur pipeline est étouffée en silence par la substitution de processus.

###### 🔍 Lentille Verification-Gap (verification-gap)

No verification gaps found.

##### 🏗️ Couche propre au projet

* NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (les contournements signalés lors de la précédente revue avec `tabindex` ou les attributs vides sont résolus avec robustesse).
* NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur et aucun secret n'est commité, exposé ou affiché.
* NON BLOQUANT : Skill, procédure et script concordent : la mise à jour de `docs/procedures/check.md` reflète exactement les contrôles automatisés par `scripts/checks/html.sh`.
* NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (l'exemption pour la page d'accueil d'AD-2 et la lecture du manifeste d'AD-19 sont parfaitement intégrées).
* BLOQUANT : Dans `scripts/checks/html.sh` (ligne 207), l'absence de `|| true` après `grep -oE` provoque une erreur muette sous `set -euo pipefail` lorsqu'une page ne comporte aucun titre (erreur masquée par la substitution de processus `< <(...)`).

VERDICT: BLOQUANT — La commande grep traitant le plan des titres laisse passer une erreur en silence sous set -euo pipefail lorsqu'aucun titre n'est trouvé.

Décisions de l'auteur sur la deuxième revue de la PR n° 45 (`1fa0283`, verdict `block`) : constat **retenu et corrigé**, et étendu au-delà de la ligne signalée. Sans `|| true`, un `grep` sans correspondance rend 1 et l'échec passe en silence dans une substitution de processus — c'est un piège déjà écrit dans `docs/procedures/shell-scripts.md`, que j'ai reproduit trois fois dans ce fichier : le plan des titres, l'extraction des balises `link`, et la lecture de leur `rel` et de leur `href`. Les trois sont traités, avec un cas de test sur une page sans aucun titre.

### 18/09/2026 — `e6cd91b` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 45. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 4cc6e3428cc78d3e4820e222

##### Rapport de revue (BMAD Review)

###### 🕵️ Lentille Edge-Case Hunter (edge-case-hunter)

Aucun cas marginal (edge case) identifié. L'ajout de `{ grep -oE ... || true; }` aux commandes `grep` placées dans les substitutions de processus et pipelines empêche l'échec silencieux (code de retour 1 masqué) en cas d'absence de correspondance. Les valeurs de l'attribut `tabindex` et la gestion stricte du nom accessible d'un lien étaient déjà traitées de manière robuste.

###### 🔍 Lentille Verification-Gap (verification-gap)

Aucun écart de vérification trouvé (No verification gaps found). Le risque d'échec sur une page dépourvue de balises de titre est explicitement couvert par l'ajout du test unitaire `case_c11_page_sans_aucun_titre`. Ce test garantit qu'un titre manquant est signalé de façon contrôlée, sans casser le pipeline ni inventer un faux "saut de niveau". L'utilisation de la structure `|| true` sur les liens est défensive et solide.

##### 🏗️ Couche propre au projet

* NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (les contrôles d'accessibilité automatisables fonctionnent et lèvent précisément les exceptions documentées).
* NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (les tests utilisent des fixtures autonomes et locales avec des URLs invalides comme `tiers.invalide`).
* NON BLOQUANT : Skill, procédure et script concordent : la mise à jour de la documentation `docs/procedures/check.md` reflète rigoureusement le code implémenté et les contrôles passés dans `scripts/checks/html.sh`.
* NON BLOQUANT : Le changement est parfaitement cohérent avec AGENTS.md et les décisions d'architecture (respect de l'exemption de la ligne d'identité pour la page d'accueil d'après AD-2, lecture robuste du manifeste pour extraire l'identité d'après AD-19).
* NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Les 3 appels fragiles à `grep` dans des substitutions de processus et pipelines ont bien été encadrés de la protection requise pour empêcher l'arrêt muet du script.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la troisième revue de la PR n° 45 (`e6cd91b`, verdict `pass`) : aucun constat.

**Pour la rétrospective de l'epic 3** : j'ai reproduit un piège déjà écrit dans `docs/procedures/shell-scripts.md`, à trois endroits du même fichier. La liste des pièges ne sert à rien si elle n'est pas relue **en écrivant** ; à proposer comme action : relire la table des pièges avant de livrer un script, comme on relit une check-list.

## Reporté
