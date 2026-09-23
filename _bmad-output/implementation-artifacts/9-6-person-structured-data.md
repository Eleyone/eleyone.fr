# Story 9.6 : Person structured data

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.6.

## Revue de spec

### 23/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `c9bf13d`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: acd6148b21c4ecb25f2d5829

Ce document a été analysé selon les principes du skill `bmad-review`. Le contenu relève de la classe *docs* (document définissant un comportement, spécifications). Le modèle de structure le plus pertinent pour l'évaluation est **Prompt/Task Definition (Functional)**.

##### Lentille Adversarial

**BLOQUANT** : L'origine de la source de données `identity` est ambiguë.
- `location` : Critères d'acceptation, 2ème bloc (`name et alternateName viennent d'identity`).
- `trigger_condition` : La spécification ne précise pas s'il s'agit d'un fichier de données (`data/identity.yaml`), de paramètres locaux au frontmatter ou globaux (`site.Params.identity`).
- `guard_snippet` : Renseigner le chemin technique exact pour la source de données.
- `potential_consequence` : Le développeur ou l'agent devra deviner l'emplacement des informations vitales, causant potentiellement un blocage.

**BLOQUANT** : La structure interne exigée pour l'adresse est invalide en format JSON-LD.
- `location` : Critères d'acceptation, 1er bloc (`avec les seules clés [...] address.addressCountry: FR`).
- `trigger_condition` : L'utilisation littérale d'une clé plate `address.addressCountry` est imposée, ce qui n'est pas sémantiquement reconnu. 
- `guard_snippet` : Exiger la construction d'un objet imbriqué : `"address": { "@type": "PostalAddress", "addressCountry": "FR" }`.
- `potential_consequence` : Le code générera un schéma JSON-LD non valide, annulant l'objectif initial de référencement.

**BLOQUANT** : L'URL pointée par `baseURL` sera erronée pour la version anglaise du site.
- `location` : Critères d'acceptation, 2ème bloc (`url de baseURL`).
- `trigger_condition` : `baseURL` sous Hugo pointe invariablement vers la racine du site (la version FR, selon AGENTS.md), sans prendre en compte le contexte linguistique (`/en/`).
- `guard_snippet` : Remplacer par l'utilisation de la variable contextuelle `.Permalink` de la page d'accueil en cours.
- `potential_consequence` : Le schéma JSON-LD anglais fournira aux moteurs de recherche l'URL de la version française comme URL canonique.

**BLOQUANT** : Aucun test en échec (fixture) n'est demandé pour le nouveau contrôle C10.
- `location` : Critères d'acceptation, 3ème bloc (`la règle [...] est active et passe`).
- `trigger_condition` : La règle 9 explicite d'AGENTS.md ("A guard gets a test that fails without it") n'est pas respectée par les critères d'acceptation.
- `guard_snippet` : Ajouter explicitement l'exigence d'un test qui vérifie que le script C10 échoue si le bloc est absent ou malformé.
- `potential_consequence` : Contradiction avec les directives globales d'assurance qualité du projet.

**BLOQUANT** : La vérification "aucune autre page n'en contient" est laissée invérifiable.
- `location` : Critères d'acceptation, 1er bloc (`Et aucune autre page n'en contient`) par rapport au 3ème bloc.
- `trigger_condition` : Le contrôle C10 tel que défini ne vérifie que "exactement un bloc conforme sur chaque accueil", il ignore les autres pages.
- `guard_snippet` : Étendre la spécification de C10 pour valider que le bloc n'existe pas sur les autres pages générées.
- `potential_consequence` : L'un des critères d'acceptation fondamentaux de la fonctionnalité ne sera couvert par aucun test.

**BLOQUANT** : Le périmètre d'action pour le script C3 (vérification de GitHub) n'est pas défini.
- `location` : Critères d'acceptation, 2ème bloc (`comparée par C3`).
- `trigger_condition` : Il est impossible de savoir si cette modification du script de contrôle C3 fait partie des tâches de développement de cette story, ou s'il s'agit d'un acquis d'une autre story.
- `guard_snippet` : Préciser si l'extension du script de contrôle C3 est une sous-tâche requise par cette story.
- `potential_consequence` : Si la règle C3 n'existe pas déjà, ce contrôle de cohérence linguistique risque d'être totalement omis.

**NON BLOQUANT** : Le nommage du dossier `_partials` n'est pas standard.
- `location` : Critères d'acceptation, 1er bloc.
- `trigger_condition` : Les partials Hugo se trouvent conventionnellement dans `layouts/partials/`.
- `guard_snippet` : Remplacer `_partials/` par `layouts/partials/`.
- `potential_consequence` : L'implémentation pourrait créer un répertoire non pris en compte automatiquement par Hugo.

**NON BLOQUANT** : Comportement non spécifié en cas d'omission de `job_title`.
- `location` : Critères d'acceptation, 2ème bloc (`nouvelle clé job_title`).
- `trigger_condition` : La spécification ne dit pas comment le code doit réagir (erreur de build ou attribut absent) si la clé n'est pas présente dans le frontmatter.
- `guard_snippet` : Indiquer si l'absence de cette valeur doit déclencher une fonction d'erreur bloquante lors de la compilation Hugo.
- `potential_consequence` : Génération d'une valeur vide non maîtrisée si un contributeur oublie la donnée.

**NON BLOQUANT** : Cas limite non géré d'une liste `sameAs` vide.
- `location` : Critères d'acceptation, 2ème bloc (`un lien vide est omis de sameAs`).
- `trigger_condition` : Si LinkedIn et GitHub sont manquants tous les deux, on risque de générer un tableau vide.
- `guard_snippet` : Préciser que "la clé `sameAs` entière doit être omise si la liste ne contient aucune URL".
- `potential_consequence` : Rendu d'un `"sameAs": []` inoffensif mais disgracieux dans la structure de données.

**NON BLOQUANT** : Éventuelle interférence de la CSP pour les scripts inlines de données.
- `location` : Check-list, dernier point (`la CSP d'AD-13 est inchangée`).
- `trigger_condition` : Bien que non exécutable, une balise `<script type="application/ld+json">` inline peut générer des alertes selon la rigueur de la Content Security Policy en place.
- `guard_snippet` : Recommander une courte vérification de compatibilité des données avec l'actuelle CSP.
- `potential_consequence` : Risque de blocage navigateur silencieux de la donnée, ou avertissements erronés dans la console de production.

##### Lentille Structure

| Pass | Original Text | Revised Text | Changes |
| :--- | :--- | :--- | :--- |
| structure | **BLOQUANT** : `Étant donné _partials/jsonld-person.html sur l'accueil de chaque langue` | `QUESTION` : Définir explicitement le point d'injection technique (ex: bloc conditionnel dans `<head>` depuis `baseof.html`, ou directement dans `layouts/index.html`). | Scaffolding manquant. Dans le modèle de document de type Functional, le flux doit être explicite ; laisser l'emplacement cible du partial à l'interprétation risque de casser l'architecture existante. |
| structure | **NON BLOQUANT** : `- [ ] Ni ville, ni téléphone, ni photo dans le bloc` | `PRESERVE` | Bien que sémantiquement redondant vis-à-vis du terme restrictif "les seules clés", ce rappel explicite des gardes-fous sur les données privées relève d'un renforcement utile et sécuritaire à l'exécution. |

##### Lentille Prose

| Pass | Original Text | Revised Text | Changes |
| :--- | :--- | :--- | :--- |
| prose | **NON BLOQUANT** : `avec les seules clés @context, @type: Person, name, alternateName, jobTitle, address.addressCountry: FR, url et sameAs (LinkedIn et GitHub)` | `avec les seules clés : @context, @type: Person, name, alternateName, jobTitle, url, sameAs (LinkedIn et GitHub), ainsi qu'un objet address contenant addressCountry: FR` | Amélioration de la clarté et diminution du risque que l'implémentation reproduise littéralement une mauvaise syntaxe pointée. |
| prose | **NON BLOQUANT** : `sameAs de linkedin et de la nouvelle clé github (URL du profil, identique en FR et en EN, comparée par C3) de content/contact.{fr,en}.md` | `sameAs construit à partir des clés linkedin et github (nouvelle) de content/contact.{fr,en}.md. L'URL du profil GitHub doit être identique en FR et EN (ce qui est contrôlé par C3).` | Extraction de la condition imbriquée pour une meilleure lecture (et un fractionnement des responsabilités de développement). |

##### À trancher avant d'implémenter

- Dans quel fichier, paramètre technique ou dossier de données se situe exactement l'origine du champ `identity` ?
- Comment corriger la notion de `baseURL` pour que l'URL générée soit correctement contextuelle pour la version `/en/` ?
- Faut-il implémenter / modifier le script C3 de vérification de l'URL GitHub dans le périmètre de cette story (et l'ajouter aux AC), ou existe-t-il déjà ?
- Comment et dans quel fichier template le partial `jsonld-person.html` doit-il être injecté exactement ?
- La vérification globale qu'aucune autre page ne contient le bloc doit-elle être intégrée formellement dans le script C10 ?
- Quelles sont les consignes (fixtures) permettant de rédiger un test d'échec volontaire de la règle C10, conformément aux règles du projet ?

### Triage des constats (23/09/2026)

**Retenus**

- *`identity` est une source ambiguë* — juste. `identity` vaut « Arnaud Grousset · Eleyone » : la spec veut `name` **et** `alternateName` de cette seule clé, sans dire comment. Le partial la **découpe sur le séparateur** « · » que DESIGN.md prescrit, refuse (`errorf`) si elle n'en porte pas exactement un, et prend le premier segment pour `name`, le second pour `alternateName`. Deviner un découpage sans le dire aurait produit un JSON-LD faux en silence le jour où la ligne change.
- *L'adresse imbriquée est invalide* — juste, et c'est la faute la plus pénalisante : un `address` sans `@type` n'est pas une `PostalAddress` pour un moteur. Le bloc écrit `"address": {"@type": "PostalAddress", "addressCountry": "FR"}`.
- *`baseURL` serait faux pour l'anglais* — juste. `url` désigne la page canonique de la personne ; avec `baseURL`, les deux accueils annonceraient la même. Le partial prend le **permalien de la page**, donc `/` en français et `/en/` en anglais.
- *Aucun test en échec pour la nouvelle règle de C10* — juste, et c'est le point 9 d'AGENTS.md. La règle reçoit des cas qui échouent sans elle.
- *« Aucune autre page n'en contient » est invérifiable* — juste : le contrôle doit **énumérer toutes les pages**, pas seulement regarder les accueils. Borner la recherche à ce qu'on imagine est la faute que la rétrospective de l'epic 7 a nommée.

**Refusé**

- *« Le périmètre de C3 pour `github` n'est pas défini »* — faux : C3 compare déjà les trois clés `email`, `linkedin`, `github` du front matter de `content/contact` (`ARCHITECTURE-SPINE.md`, ligne du contrôle C3), et la story 9.3 les a livrées. La parité passe aujourd'hui sur les trois.

**Non bloquants** — le nom du dossier `_partials` est la convention de Hugo 0.146+ et de tout ce dépôt ; l'omission de `job_title` est retenue comme précision : elle arrête le build, comme toute donnée manquante d'un bloc qui prétend décrire une identité.

## Implémentation

- `layouts/_partials/jsonld-person.html` (nouveau) — le bloc, construit du contenu, jamais d'une chaîne écrite dedans ;
- `layouts/baseof.html` — appelé **sur les seuls accueils**, le test de la page étant fait là où toutes les pages passent, pas dans le partial, qui n'a pas à savoir où on l'appelle ;
- `scripts/checks/html.sh` — C10 gagne l'exigence **positive** et la validation du contenu ;
- `scripts/tests/test-jsonld-person.sh` (nouveau) — quinze cas.

### Trois défauts trouvés sur le rendu, pas en relisant

**Le bloc était une chaîne, pas un objet.** Dans un `script`, Go encode la sortie comme du JavaScript : le JSON-LD sortait en `"{\"@type\":…}"`, entre guillemets, et aucun moteur ne l'aurait lu. `safeJS` est le mécanisme prévu, et la documentation de Hugo en pose la condition — un contenu de source sûre, ce qu'est notre propre front matter.

**`name` portait une espace finale invisible.** Le séparateur de la ligne d'identité est précédé d'une **espace insécable** que DESIGN.md prescrit ; `trim … " "` ne coupe que l'ordinaire. `strings.TrimSpace` couvre les séparateurs Unicode — vérifié dans la documentation plutôt que supposé.

**`errorf` n'interrompt pas le rendu.** Une `identity` absente produisait trois messages en cascade. Les refus s'excluent désormais.

### C10 : l'exigence était négative, elle devient positive

Le contrôle refusait un bloc **de trop** ou **hors de l'accueil**, jamais un bloc **absent** : un accueil sans données structurées passait sans un mot. S'y ajoutent les clés requises, le type de l'adresse, le pays, et l'absence d'entrée vide dans `sameAs`.

**Une de ces six règles était muette, et c'est ma garde qui l'excusait** : `[[ -z $type || $type == PostalAddress ]]` tolérait la valeur vide, donc l'absence — exactement le cas à refuser. Constaté en dégradant le contrôle une règle à la fois, pas en le relisant. Les six mordent maintenant.

### Ce que ce changement a coûté aux fixtures

Le partial s'exécute sur tout accueil, donc **toute fixture qui construit un site** devait déclarer `identity` et `job_title`. Huit accueils dans quatre fichiers, plus la fixture sur disque, ont été complétés : une fixture déclare ce que la vraie page déclare (point 16 d'AGENTS.md), et un accueil réel porte toujours ces deux clés.

En revanche, **exiger une page de contact était trop strict** : `sameAs` est la seule clé qui en dépende, et la règle est déjà « un lien vide est omis ». Une page de contact absente n'est que ce cas à plus gros grain. L'exiger aurait imposé une page de contact à toute fixture sans rien garder de plus.

### Une faute de ma fixture

Mon garde-fou de construction s'arrêtait par `… && return 0` quand le journal portait une erreur — il rendait donc « réussi » précisément quand le build avait échoué. Le cas de l'`identity` sans séparateur l'a dit tout de suite.

## Revue du code

### 23/09/2026 — `52d80ed` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 102. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 478e37b35bc175d2dadbc38f

Plan de revue : Examen du diff avec les lentilles `edge-case-hunter` et `verification-gap`, puis application de la couche de règles spécifiques au projet.

##### Lentille `edge-case-hunter`

**BLOQUANT** : Un JSON invalide ou mal typé échappe au contrôle C10 via la dissimulation de l'erreur `jq`.
- `location` : `scripts/checks/html.sh` (affectations de `liste_6` et `vides`).
- `trigger_condition` : Le bloc extrait n'est pas un JSON valide ou un champ a un type inattendu (par exemple `sameAs` n'est pas un tableau), ce qui fait échouer la commande `jq`.
- `guard_snippet` : Enlever les fallback `|| liste_6=""` et `|| vides=0`. Laissez `jq` échouer de manière bruyante pour interrompre le contrôle.
- `potential_consequence` : Des données structurées invalides sont acceptées et publiées sans que la CI ne s'en rende compte, vidant C10 de sa fonction.

**BLOQUANT** : L'échec du build de l'environnement de travail est ignoré dans le script de tests.
- `location` : `scripts/tests/test-jsonld-person.sh`, fonction `construire`.
- `trigger_condition` : La commande `hugo --environment work ...` échoue (par exemple à cause d'une erreur de syntaxe dans un gabarit de brouillon).
- `guard_snippet` : Retirer le `|| true` final et propager le code d'erreur réel de l'exécution ou interrompre le test immédiatement.
- `potential_consequence` : Le script de tests rapportera un succès même si la création du rendu de travail a échoué. Les tests suivants s'appuieront sur un manifeste erroné ou manquant.

##### Lentille `verification-gap`

**NON BLOQUANT** : Absence de validation du type de l'objet `address`.
- `location` : `scripts/checks/html.sh`, vérification des clés du pays.
- `trigger_condition` : La présence de la clé `address` est testée, mais pas son type. Si `address` est une chaîne plutôt qu'un objet, l'évaluation de `.address.addressCountry` par `jq` échouera.
- `guard_snippet` : S'assurer que le masquage d'erreur n'existe pas, afin que ce cas limite provoque un échec explicite de la CI.
- `potential_consequence` : Fragilité du script de contrôle si la forme des données évolue.

##### Couche propre au projet

**NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits.
- L'injection du JSON-LD se fait bien uniquement sur l'accueil, les champs requis sont présents, l'URL est correcte selon la langue (`.Permalink`) et les données sont extraites du contenu, sans dénaturer l'intention originelle de la fonctionnalité. 

**NON BLOQUANT** : Sécurité et confidentialité préservées.
- Aucune donnée privée, aucun nom d'hôte ni adresse de serveur et aucun secret n'est commité (les URL Github et Linkedin utilisées dans les fixtures renvoient vers `exemple.invalide`).

**NON BLOQUANT** : Concordance documentaire.
- Les procédures, skills et scripts concordent (non impacté par ce diff en dehors du nouveau script de test).

**BLOQUANT** : Des erreurs de scripts shell passent sous silence.
- `location` : `scripts/checks/html.sh` et `scripts/tests/test-jsonld-person.sh`.
- `trigger_condition` : Le code utilise explicitement les dérivations `|| liste_6=""`, `|| vides=0` et `|| true` pour absorber le code de retour d'une commande qui échoue.
- `guard_snippet` : Supprimer ces exceptions pour garantir que toute erreur fait échouer le pipeline sous `set -euo pipefail`.
- `potential_consequence` : Violation flagrante de la directive identifiée lors des rétrospectives du projet : "aucune erreur ne passe en silence". Cette régression neutralise la fiabilité des contrôles C10.

VERDICT: BLOQUANT — Le code masque silencieusement les erreurs d'exécution de jq et de hugo via || true et ||="", ce qui annule la fiabilité des vérifications et viole la règle stricte du projet interdisant d'étouffer les erreurs shell.

### Décision sur les constats (23/09/2026)

**Les trois sont retenus, et tous portent sur la même faute : j'avais écrit trois nouvelles suppressions d'erreur**, dans la story même dont le contrôle existe pour ne rien laisser passer.

- `|| liste_6=""` et `|| vides=0` dans C10 : un bloc mal typé fait échouer `jq`, et ces replis le faisaient passer pour conforme. Les codes de `jq` sont désormais lus.
- `|| true` sur le rendu de travail de la fixture : son échec était avalé, et les cas qui éprouvent C10 auraient été jugés sur un manifeste absent. Le code est propagé.
- Le type d'`address` n'était pas vérifié : une chaîne y aurait fait échouer `jq`, masqué par les mêmes replis.

**Et en écrivant le cas du `sameAs` mal typé, une décision de plus** : le contrôle rendait **2** (anomalie) là où il fallait **1** (écart). Un bloc mal formé produit par notre propre build n'est pas une panne d'outil ; réserver `checks_die` aux vraies pannes garde au code 2 son sens. `sameAs` et `address` sont donc typés avant d'être parcourus, et chacun signale son écart avec son message.

Deux cas ajoutés, l'un pour chaque type mal formé.

### 23/09/2026 — `a35f822` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 102. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 910b565265d5500bb1f0e9e2

##### Revue de code avec le skill `bmad-review`

##### Lentille `edge-case-hunter`

**BLOQUANT** : L'utilisation de `|| true` dans un pipeline grep masque les erreurs d'exécution potentielles.
- `location` : `scripts/tests/test-jsonld-person.sh` (fonction `case_jsonld_aucun_bloc_hors_de_laccueil`).
- `trigger_condition` : Le pipeline `autres=$(grep -rl ... | grep -vE ... || true)` absorbe la totalité des codes de retour d'erreur du pipeline. Si la commande de départ `grep -rl` échoue de manière critique (code 2, par exemple si le dossier de sortie est manquant ou illisible), l'erreur est étouffée, la variable est assignée vide et le test est validé à tort.
- `guard_snippet` : Retirer le `|| true` de l'affectation et récupérer explicitement le code de retour pour ne tolérer que le code 1 (aucune ligne trouvée), par exemple en séparant les étapes ou en vérifiant le tableau `${PIPESTATUS[@]}`.
- `potential_consequence` : Les pannes internes du système de test passeront inaperçues pour ce cas de figure, laissant une exécution erronée passer pour un test réussi.

##### Lentille `verification-gap`

**NON BLOQUANT** : Lacunes dans la couverture de test des rejets du contrôle C10.
- `location` : `scripts/tests/test-jsonld-person.sh` (tests de la règle C10).
- `trigger_condition` : Le script Python embarqué `controle_sur_bloc_doctore` a été spécifiquement enrichi d'une condition `quoi == 'deux-blocs'`, mais aucune fonction de test correspondante n'a été ajoutée pour appeler ce cas. De la même façon, la fonction vérifiant l'interdiction de placer le bloc ailleurs que sur la page d'accueil ne teste pas réellement la robustesse de C10 face à une injection ciblée (par exemple un bloc dans `contact/index.html`).
- `guard_snippet` : Implémenter les fonctions manquantes (ex. `case_jsonld_c10_refuse_deux_blocs` et `case_jsonld_c10_refuse_bloc_hors_accueil`) en exploitant le mécanisme d'injection Python déjà en place pour éprouver directement le script `html.sh`.
- `potential_consequence` : Les blocs logiques de `html.sh` vérifiant la cardinalité exacte ou la présence de données structurées hors de l'accueil demeurent non validés par des tests d'échec isolés contre les régressions.

##### Couche propre au projet

**NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits.
- L'injection conditionnée par `if .IsHome` respecte l'exclusivité à la page d'accueil. La modélisation JSON-LD est correcte et exhaustive (utilisation de `.Permalink` pour garantir un lien contextuel exact en EN et en FR, structuration en objet obligatoire et gestion des valeurs vides pour `sameAs`). L'intention initiale n'est pas compromise.

**NON BLOQUANT** : Sécurité et confidentialité préservées.
- Le code source ajouté n'expose aucune coordonnée privée ni aucun secret. Les variables de test et les fixtures s'appuient sur des données manifestement factices (`Essai · Pseudo`, `exemple.invalide`).

**NON BLOQUANT** : Concordance script, procédure et skill.
- Le périmètre modifié correspond bien à son intention et n'introduit aucune rupture vis-à-vis des procédures ou skills actuels du projet.

**NON BLOQUANT** : Le changement est cohérent avec AGENTS.md et les décisions d'architecture.
- L'injection de la balise de configuration échappe validement à l'interdiction du JavaScript d'après l'architecture statique (AD-20). La gestion différenciée des retours d'erreur dans le partial (avec `errorf`) respecte bien l'exécution de Hugo sans la paralyser par de fausses alertes.

**BLOQUANT** : Des erreurs dans les scripts shell passent en silence sous `set -euo pipefail`.
- `location` : `scripts/tests/test-jsonld-person.sh` (fonction `case_jsonld_aucun_bloc_hors_de_laccueil`).
- Le `|| true` apposé au bout du pipeline grep avale toutes les erreurs du système, contredisant directement la consigne de gestion stricte des erreurs (voir le constat identifié par la lentille `edge-case-hunter`).

VERDICT: BLOQUANT — L'utilisation du repli || true sur le pipeline grep du script de tests étouffe silencieusement les codes d'erreur de dysfonctionnement (tels qu'un échec de lecture ou un répertoire absent), en violation directe de la règle interdisant de masquer les erreurs sous set -euo pipefail.

### Décision sur les constats du troisième tour (23/09/2026)

**Retenu — un `|| true` sur un pipeline de `grep`.** Il absorbe le code de **tout** le pipeline : un dossier illisible aurait rendu une liste vide que le cas aurait prise pour « rien hors des accueils ». C'est la **quatrième instance de cette classe dans cette seule story**, après les trois du tour précédent. Le code du premier `grep` est désormais lu pour lui-même.

**Retenu — une branche d'injecteur sans son cas.** J'avais ajouté `deux-blocs` au script d'injection et jamais écrit le cas qui l'emploie : du code mort dans un harnais de test, et deux règles de C10 — la cardinalité exacte, et le refus d'un bloc hors de l'accueil — sans cas isolé. Les deux sont ajoutés, le second en recopiant le bloc de l'accueil sur la page de contact.

Le reste du rapport confirme les critères d'acceptation et l'absence de fuite.

### 23/09/2026 — `120f352` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 102. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1aa4448e8941d89db67a4c01

##### Revue de code avec le skill `bmad-review`

##### Lentille `edge-case-hunter`

**NON BLOQUANT** : Un lien composé uniquement d'espaces ne sera pas filtré du tableau `sameAs`.
- `location` : `layouts/_partials/jsonld-person.html` (itération sur `linkedin` et `github`).
- `trigger_condition` : Si le front-matter de `contact.md` définit une URL comme une chaîne contenant uniquement des espaces (ex: `linkedin: " "`), la condition `{{ with . }}` l'évaluera comme vraie et l'ajoutera au tableau `sameAs`. Par ailleurs, le contrôle `html.sh` vérifie `type != "string" or . == ""` et laissera lui aussi passer une chaîne constituée d'espaces.
- `guard_snippet` : Utiliser `strings.TrimSpace` avant de vérifier l'existence de la valeur, par exemple `{{ with strings.TrimSpace . }}`.
- `potential_consequence` : Un lien vide sous forme d'espaces blancs serait publié silencieusement dans les données structurées.

##### Lentille `verification-gap`

**NON BLOQUANT** : Absence de test explicite pour le comportement du partial face à une page de contact inexistante.
- `location` : `scripts/tests/test-jsonld-person.sh` (fonction `construire`).
- `trigger_condition` : Le commentaire du partial justifie brillamment que l'absence de la page de contact ne doit pas générer d'erreur bloquante (`site.GetPage "/contact"`). Cependant, la fonction `construire` du script de test dédié crée systématiquement les pages `contact.fr.md` et `contact.en.md`, privant le harnais de test d'une vérification isolée de ce comportement. 
- `guard_snippet` : Ajouter un paramètre à `construire` permettant d'omettre volontairement la création des fichiers de contact, et écrire un test dédié (`case_jsonld_accepte_absence_page_contact`) qui vérifie la conformité du build dans cette situation.
- `potential_consequence` : Si un jour le comportement de `site.GetPage` évolue ou si le code du partial est modifié en assumant que la page existe toujours, le script de test unitaire ne détectera pas cette régression.

##### Couche propre au projet

**NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (le bloc est injecté de manière conditionnelle uniquement sur l'accueil, sans champs prohibés et avec un ciblage linguistique correct des URLs).
**NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret (les fixtures utilisent `exemple.invalide` et des noms dépersonnalisés).
**NON BLOQUANT** : Skill, procédure et script concordent.
**NON BLOQUANT** : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (le JSON-LD sans JavaScript exécutable respecte AD-20, les erreurs du partial ne bloquent pas inutilement le processus global).
**NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail (les replis `|| true` et `|| liste=""` dangereux identifiés dans les revues antérieures ont été supprimés et les codes d'erreur de `jq` et `grep` sont désormais traités).

VERDICT: NON BLOQUANT — aucune

### La CI a trouvé ce que le poste ne pouvait pas voir (23/09/2026)

La revue avait rendu `pass`, la suite passait en local, les neuf contrôles aussi — et **la CI a échoué**.

Cause : mon fichier de test doctorait le JSON en **Python**, absent de `CHECK_IMAGE`. `tools.env` ne déclare que `git grep findutils jq libxml2-utils poppler-utils`, et `scripts/tests/run.sh` n'exige pas python3 non plus. Un test qui dépend d'un outil non déclaré ne teste que la machine de celui qui l'écrit.

Réécrit avec **`jq` et `awk` seuls**, tous deux déclarés. Le remplacement dans la page se fait littéralement, par `awk` et `index`/`substr` : le JSON porte des `/` et peut porter des `&`, que `sed` interpréterait. Les deux chaînes passent par l'environnement plutôt que par `awk -v`, qui traite les séquences d'échappement de sa valeur.

**Et la leçon de méthode** : la suite a été rejouée **dans l'image de contrôle**, pas seulement sur le poste — 517 cas réussis, 7 ignorés à juste titre sous root, aucun échec. C'est la vérification que j'aurais dû faire avant de pousser un test qui manipule un format.

### 23/09/2026 — `198811c` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 102. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 671f4d7f5297bb4ed1d72f83

Revue du fichier `REVIEW-DIFF.patch` (classe de contenu : code) selon les principes du skill `bmad-review`.

##### Lentille `edge-case-hunter`

NON BLOQUANT : Un lien composé uniquement d'espaces ne sera pas filtré du tableau `sameAs`.
- `location` : `layouts/_partials/jsonld-person.html` et `scripts/checks/html.sh`.
- `trigger_condition` : (Signalé précédemment, mais toujours présent). Si le front-matter définit une URL constituée exclusivement d'espaces (ex: `linkedin: " "`), l'instruction `{{ with . }}` l'évaluera comme vraie et l'ajoutera au tableau `sameAs`. De son côté, la requête `jq` dans `C10` vérifie l'absence par `type != "string" or . == ""` et laissera donc passer une chaîne d'espaces.
- `guard_snippet` : Dans le gabarit, appliquer `strings.TrimSpace` sur le lien avant de l'ajouter (ex: `{{ with strings.TrimSpace . }}`). Dans le script de contrôle, utiliser une expression régulière de type `test("^\\s*$")` via `jq`.
- `potential_consequence` : Un lien invalide composé d'espaces blancs serait publié silencieusement dans les métadonnées.

##### Lentille `verification-gap`

NON BLOQUANT : Absence de test isolé face à une page de contact inexistante.
- `location` : `scripts/tests/test-jsonld-person.sh` (fonction `construire`).
- `trigger_condition` : Le code source justifie que l'absence de la page de contact ne doit pas déclencher d'erreur et qu'elle doit simplement omettre `sameAs`. Or, la fonction `construire` du test crée systématiquement les pages de contact, privant la suite de tests d'une vérification isolée de ce comportement.
- `guard_snippet` : Ajouter un paramètre à `construire` permettant d'omettre la création des fichiers de contact, et écrire un cas de test dédié (`case_jsonld_accepte_absence_page_contact`).
- `potential_consequence` : Si une modification future vient assumer que la page de contact existe systématiquement, le harnais de tests unitaires ne détectera pas cette régression.

##### Couche propre au projet

NON BLOQUANT : Les critères d'acceptation de la story 9.6 sont satisfaits.
- L'injection du bloc `Person` JSON-LD est bien exclusive à l'accueil et générée par `jsonify` à partir du contenu. Les champs requis y figurent, et les données privées prohibées (ville, photo, téléphone) en sont absentes. L'URL s'adapte à la langue via `.Permalink` (ce qui traduit correctement l'intention d'éviter `baseURL` qui resterait statiquement ancré à la racine). La règle de contrôle `C10` passe avec succès.

NON BLOQUANT : Sécurité et confidentialité préservées.
- Aucun secret, aucun compte, ni aucune donnée privée n'est introduit dans le dépôt. Les fixtures et les tests s'appuient sur des données factices (ex: domaine `exemple.invalide`).

NON BLOQUANT : Concordance des éléments.
- Les scripts, skills et procédures concordent et s'alignent avec les comportements documentés au sein du projet.

NON BLOQUANT : Cohérence avec l'architecture et AGENTS.md.
- L'injection JSON-LD est bien la seule exception permise à NFR-12, formellement validée sans JavaScript exécutable. Le système `errorf` de Hugo est utilisé de façon justifiée pour signaler des éléments introuvables sans interrompre l'ensemble du flux de rendu de manière abusive.

NON BLOQUANT : Aucune erreur ne passe en silence sous set -euo pipefail.
- Le développeur a identifié et expurgé toutes les occurrences absorbant dangereusement des erreurs soulevées aux tours précédents (les replis `|| true` ou les assignations silencieuses `|| liste=""`). Les requêtes shell au sein du script de contrôle récupèrent et traitent formellement l'erreur (via l'analyse explicite de `$?` ou l'arrêt de la fonction en sous-shell sans avaler le code de retour avec l'assignation `local`).

VERDICT: NON BLOQUANT — aucune

### 23/09/2026 — `74ecae3` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 102. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: e0d5ea77d0de25f45cd6e10a

Ce document est relu en respectant le skill `bmad-review`. Le contenu analysé est un patch contenant la mise à jour de la documentation de la story 9.6 ainsi que l'implémentation de la fonctionnalité (gabarits Hugo et scripts de vérification shell).

##### Lentille edge-case-hunter

- **NON BLOQUANT** : Le filtrage de la liste `sameAs` peut laisser passer des liens composés uniquement d'espaces.
  - `location` : `layouts/_partials/jsonld-person.html` et `scripts/checks/html.sh`.
  - `trigger_condition` : (Déjà signalé dans les itérations passées du patch, mais toujours présent). Si le front-matter définit une URL (ex. `linkedin: " "`) sous forme d'une chaîne composée exclusivement d'espaces, l'instruction `{{ with . }}` l'évaluera comme vraie. Côté tests, la validation de `C10` vérifie l'absence absolue via `. == ""` mais accepte une chaîne d'espaces.
  - `guard_snippet` : Appliquer `strings.TrimSpace` sur l'élément avant de l'ajouter dans le gabarit (ex. `{{ with strings.TrimSpace . }}`) et ajouter un contrôle regex ciblant `^\s*$` dans l'évaluation `jq` de `C10`.
  - `potential_consequence` : Des URLs invalides (composées d'espaces blancs) seraient publiées silencieusement dans le JSON-LD.

##### Lentille verification-gap

- **NON BLOQUANT** : La robustesse du comportement sans page de contact n'est pas testée isolément.
  - `location` : `scripts/tests/test-jsonld-person.sh` (fonction `construire`).
  - `trigger_condition` : Bien que le fichier `jsonld-person.html` soit conçu pour omettre paisiblement les liens si la page de contact manque (`site.GetPage "/contact"`), la fonction `construire` des tests génère systématiquement cette page. L'harnais n'éprouve donc pas isolément cette résilience.
  - `guard_snippet` : Ajouter un paramètre à la fonction `construire` permettant d'omettre la génération de la page de contact, et concevoir un cas de test tel que `case_jsonld_accepte_absence_page_contact`.
  - `potential_consequence` : Si le comportement de `GetPage` évolue ou qu'une modification involontaire du gabarit vient supposer la présence obligatoire de la page de contact, cette régression échappera à la suite de tests.

##### Couche propre au projet

- **NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée. L'injection du JSON-LD est strictement contenue à l'accueil (`.IsHome`), et les contrôles sur les clés et l'adresse sont rigoureusement testés.
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge. Toutes les fixtures reposent sur des données sûres (ex. `exemple.invalide`).
- **NON BLOQUANT** : Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure. L'intention et l'outillage correspondent fidèlement.
- **NON BLOQUANT** : Le changement est cohérent avec AGENTS.md et les décisions d'architecture. La génération d'une balise JSON-LD par `safeJS` (sans JavaScript exécutable client) respecte directement les directives d'AD-20 et n'enfreint pas NFR-12.
- **NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail. L'implémentation a formellement expurgé les anti-patterns `|| true` pointés dans l'historique et intercepte explicitement les codes de retour (par ex. `|| code=$?` et `|| rc_jq=$?`) lors des command substitutions et pipelines, évitant tout étouffement accidentel.

VERDICT: NON BLOQUANT — aucune

## Reporté
