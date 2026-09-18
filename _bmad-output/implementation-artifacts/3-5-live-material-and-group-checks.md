# Story 3.5 : Live material and group checks

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.5.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `7936a98`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1c950fbde1391befb72314b6

Ce document est la spécification des contrôles continus (C7, C8) sur le matériel vivant et le groupement des cas (story 3.5). Le document sert à cadrer le comportement de la CI. 

Voici le rapport de revue appliquant les trois lentilles demandées.

##### Lentille Adverse (Adversarial)

**1. Doublons d'`order` dans un groupe multilingue**
- **location** : Critère 3
- **trigger_condition** : C8 vérifie si deux cas d'un groupe ont le même `order`, mais ignore la dimension linguistique.
- **guard_snippet** : « deux cas d'un groupe, *dans la même langue*, avec le même order »
- **potential_consequence** : Faux positifs (la CI rejettera un cas car ses traductions FR et EN partagent légitimement le même `order`).

**2. Distinction des cas autonomes (standalone)**
- **location** : Critère 3
- **trigger_condition** : Un cas autonome est rangé sous `cases/`. Son dossier parent est donc `cases`. Si C8 compare aveuglément `group` au dossier parent, un cas autonome différera de `cases`.
- **guard_snippet** : « un cas groupé dont la clé `group` diffère du dossier parent direct, ou un cas autonome possédant une clé `group` »
- **potential_consequence** : Faux positifs sur les cas hors groupe, ou lacune de vérification si un cas autonome porte une clé `group` par erreur.

**3. Validation de l'énumération du type**
- **location** : Critère 1
- **trigger_condition** : Le script signale "un préfixe qui ne correspond pas au type", mais ne contraint pas l'existence du type lui-même (limité à diagram, video, snippet, callout).
- **guard_snippet** : « un type inconnu, ou un préfixe qui ne correspond pas au type »
- **potential_consequence** : Une coquille dans la valeur (ex: `type: "vidéo"`) associée à un identifiant `video-` ne serait pas repérée.

**4. Traduction croisée des sources**
- **location** : Critère 2
- **trigger_condition** : Le critère exige une source (SVG, fichier MD) mais ne précise pas qu'elle doit correspondre à la langue du fichier contrôlé.
- **guard_snippet** : « sans source dans la langue du cas courant (SVG ou fichier MD existant, ou URL) »
- **potential_consequence** : Un cas `.en.md` pourrait être validé alors qu'il lui manque son SVG anglais, simplement car le SVG français a été trouvé dans `assets/`.

**5. Valeur de l'URL pour une vidéo**
- **location** : Critère 2
- **trigger_condition** : La clé `url` pourrait exister mais contenir une chaîne vide `""` pour une vidéo `ready`.
- **guard_snippet** : « ou une URL vide pour une vidéo »
- **potential_consequence** : Le validateur trouve la clé et passe, aboutissant à un lien mort (href vide) en production.

**6. Unicité locale d'un identifiant (répétition)**
- **location** : Critère 1
- **trigger_condition** : Le contrôle exige qu'un identifiant ne soit pas utilisé par deux cas différents, mais ne se prononce pas sur une insertion multiple dans le même texte.
- **guard_snippet** : « un identifiant utilisé par deux cas, ou placé plusieurs fois dans un même cas (si interdit) »
- **potential_consequence** : Le même schéma pourrait être inséré deux fois sur la même page sans lever d'alerte, si ce n'était pas l'intention.

**7. Matériel "planned" non placé**
- **location** : Critère 1 ("élément déclaré non placé")
- **trigger_condition** : Le texte est ambigu sur l'exemption ou non des éléments `planned` de l'obligation d'être placés via un shortcode.
- **guard_snippet** : « un élément (ready ou planned) déclaré non placé »
- **potential_consequence** : Un développeur pourrait exclure les éléments `planned` de ce contrôle, laissant du matériel orphelin dans le front matter.

**8. Robustesse face à un tableau YAML absent**
- **location** : Critère 1 ("placé non déclaré")
- **trigger_condition** : Si le YAML ne contient pas de bloc `live_material` du tout, la vérification peut échouer sur `null` ou crasher.
- **guard_snippet** : « un élément placé alors que la déclaration est absente »
- **potential_consequence** : L'outil `jq` de contrôle pourrait échouer techniquement au lieu de lever une violation métier.

**9. Profondeur des dossiers de groupe**
- **location** : Critère 3
- **trigger_condition** : Le critère compare le groupe au dossier, mais ne contraint pas la profondeur (ex: sous-sous-dossier `cases/foo/bar/`).
- **guard_snippet** : « diffère du nom de son dossier parent direct, ou est rangé dans une sous-arborescence profonde »
- **potential_consequence** : L'architecture plate (un seul niveau de dossier pour les groupes) serait cassée silencieusement.

**10. Continuité de la numérotation (order)**
- **location** : Critère 3
- **trigger_condition** : Les doublons d'`order` sont signalés, mais pas les "trous" (ex: cas 1, cas 3, cas 4).
- **guard_snippet** : Décider d'ignorer explicitement ou de vérifier la contiguïté.
- **potential_consequence** : Hugo affichera bien les éléments dans l'ordre, mais un trou peut masquer l'oubli de publication d'un cas intermédiaire.

##### Lentille Structure & Prose (Editorial)

*Modèle de structure évalué : Prompt / Task Definition (Functional)*

La structure est claire, synthétique, et adaptée à la définition d'un comportement attendu. L'impact en volume de mots des recommandations suivantes est négligeable (ajouts de précisions) mais prévient toute divergence d'interprétation pour le script bash.

| Pass | Original Text | Revised Text | Changes |
| :--- | :--- | :--- | :--- |
| prose | `un élément déclaré non placé ou placé non déclaré` | `un élément (ready ou planned) déclaré non placé, ou un identifiant placé non déclaré` | Lève l'ambiguïté sur les statuts `planned` et évite la confusion de relecture. |
| prose | `un cas dont group diffère du dossier` | `un cas groupé dont group diffère du dossier parent direct, ou un cas autonome possédant une clé group` | Inclut correctement les cas hors groupe. |
| prose | `deux cas d'un groupe avec le même order` | `deux cas d'un même groupe et d'une même langue avec le même order` | Empêche la CI de bloquer une traduction légitime. |
| prose | `sans source (SVG, fichier de assets/live-material/, ou url pour une vidéo)` | `sans source valide dans sa langue (SVG, fichier markdown, ou url non vide pour une vidéo)` | Explicite la vérification de la langue courante et de la valeur de l'URL. |

Total des recommandations éditoriales : 4. Le volume est préservé.

##### À trancher avant d'implémenter

- C8 doit-il vérifier l'unicité de `order` en tenant compte de la **langue** pour ne pas rejeter les fichiers `.fr.md` et `.en.md` d'un même cas qui partagent légitimement le même ordre ?
- Comment C8 doit-il réagir face aux cas **autonomes** : faut-il simplement s'assurer que la clé `group` est totalement absente ?
- C7 doit-il s'assurer que la source correspond strictement à la **langue** du fichier contrôlé, et qu'une `url` de vidéo n'est pas une simple chaîne vide `""` ?
- Un même identifiant de matériel vivant peut-il être inséré (placé avec le shortcode) **plusieurs fois** dans un même cas, ou l'unicité s'applique-t-elle aussi à la répétition locale ?

### Triage des constats (18/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| `planned` aussi soumis au « déclaré ⇔ placé » | **retenu** | `docs/format-cas.md` le dit déjà : chaque `id` déclaré est placé, et inversement, quel que soit le statut |
| `live_material` absent du front matter | **retenu** | un cas sans matériel vivant est normal : le contrôle lit une liste vide, jamais `null` |
| Profondeur des dossiers de groupe | **retenu** | un cas groupé vit dans `cases/<groupe>/`, jamais plus profond (AD-4) ; le contrôle refuse une sous-arborescence |
| Trous dans `order` | **refusé** | rien ne les interdit : `order` donne un ordre, pas un compte. Un cas non publié laisse forcément un trou, et c'est voulu |
| Unicité d'`order` et langue | **retenu, déjà résolu** | chaque manifeste ne porte qu'une langue : la comparaison est par langue par construction. Le critère le dit |
| Cas autonome | **retenu** | un cas hors d'un dossier de groupe ne porte pas de clé `group` ; en porter une est signalé |
| Source et langue, `url` vide | **retenu** | la source se juge dans la langue du fichier, et une `url` vide vaut source absente |
| Identifiant placé deux fois dans un cas | **retenu** | refusé : l'élément serait rendu deux fois, et l'unicité d'AD-6 vaut aussi à l'intérieur d'un fichier |
| Prose (4 reformulations) | **retenues** | fondues dans les critères |

Constat de l'auteur, hors rapport : **rien dans le manifeste ne dit si la source d'un élément `ready` existe.** Les scripts de contrôle lisent le manifeste, pas le disque, et `assets/` n'existe pas encore. **Question à Arnaud.**

### Réponses d'Arnaud (18/09/2026)

- **Source d'un élément « prêt »** : résolue par Hugo dans le manifeste (`material` : `id`, `type`, `status`, `source`, `source_found`). Les contrôles restent une lecture du manifeste, et la règle de nommage d'AD-6 n'est écrite qu'une fois.
- **Cas mal rangé** : signalé, et les autres règles du même fichier sont quand même évaluées.

## Ce qui est livré

- `layouts/home.checks.json` : clé `material` par cas, avec la source qu'AD-6 donne à chaque élément dans la langue du fichier (`assets/diagrams/<id>.<lang>.svg`, `assets/live-material/<id>.<lang>.md`, ou l'`url` d'une vidéo) et son existence, constatée par `resources.Get`.
- `scripts/checks/content.sh` : C7 (déclaré ⇔ placé, pas de doublon d'un côté ni de l'autre, préfixe égal au type, type connu, source présente pour un `ready`) et C8 (clé `group` égale au dossier parent, cas autonome sans clé `group`, aucun cas plus profond que `cases/<groupe>/`, `order` unique par groupe et par langue).
- `scripts/tests/test-content.sh` : dix cas de plus ; fixtures alignées sur `material` et `placed`.
- `docs/procedures/check.md`, AD-10 et `scripts/checks/lib.sh` décrivent la nouvelle clé.

### Essais

| Essai | Signalement |
| --- | --- |
| Élément déclaré, placement retiré | `C7 : élément « callout-18-decimals » déclaré mais jamais placé dans le texte` |
| Identifiant placé absent de `live_material` | `C7 : identifiant « diagram-fantome » placé dans le texte mais absent de live_material` |
| Identifiant renommé sans son préfixe | `C7 : identifiant « schema-ncs » non préfixé par son type : « diagram- » attendu (AD-6)` |
| Élément passé en `ready` | `C7 : élément « diagram-ncs-cs-flow » en status ready sans source : assets/diagrams/diagram-ncs-cs-flow.fr.svg est absent` — et le même en anglais, chacun dans sa langue |
| Clé `group` changée | `C8 : clé group « autre » alors que le dossier est « chiliz »` |
| Second cas au même `order` | `C8 : order 1 déjà pris dans le groupe « chiliz » par …case-02-chiliz.fr.md, …case-03.fr.md`, sur les deux fichiers |
| Pilote tel que commité | aucun signalement : ses trois éléments « prévus » sont déclarés, placés, bien préfixés |

Ces essais ont porté sur des copies du manifeste réel, transformées par `jq` : rien n'a été modifié dans `content/`. `scripts/tests/run.sh` : 151 cas réussis (141 avant la story, 10 ajoutés).

## Revue du code

### 18/09/2026 — `d52b3ea` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 40. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b2c9a19d07773f298e299877

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter

**1. Type de matériel invalide ignoré**
- **location** : `scripts/checks/content.sh:77-79`
- **trigger_condition** : Le validateur rejette les types vides (`$m.type == ""`), mais n'énumère pas explicitement les types valides. Un type inattendu non vide (ex: `image`) n'est pas rejeté.
- **guard_snippet** : `select($m.type != "diagram" and $m.type != "video" and $m.type != "snippet" and $m.type != "callout")`
- **potential_consequence** : Un élément déclaré avec un type invalide et le statut `planned` contournerait silencieusement tous les contrôles.
- **Classement** : NON BLOQUANT

**2. Absence de la clé `order` (valeur null) traitée comme collision**
- **location** : `scripts/checks/content.sh:33-35`
- **trigger_condition** : Si plusieurs cas d'un même groupe n'ont pas de clé `order` définie (`null`), l'expression `group_by` les rassemble et détecte un doublon.
- **guard_snippet** : `select(.[0].front_matter.order != null and length > 1)`
- **potential_consequence** : Le script signale une collision sur la valeur « null » au lieu de signaler l'absence de l'ordre, produisant un message d'erreur contre-intuitif.
- **Classement** : NON BLOQUANT

###### Lentille : Verification Gap

**3. Résolution de la source Hugo non testée (snippet/callout/video)**
- **location** : `layouts/home.checks.json:56-65`
- **trigger_condition** : La génération de la clé `source_found` pour les types autres que `diagram` n'est couverte par aucun test dans `test-checks-manifest.sh`.
- **guard_snippet** : Ajouter des fixtures pour `video` et `snippet` dans les manifestes de test pour valider la logique de `$source` et `$found`.
- **potential_consequence** : Une régression dans le gabarit Hugo (ex: faute de frappe sur le chemin `live-material/`) ne serait pas détectée par la CI.
- **gap_shape** : `regression-gap`
- **Classement** : NON BLOQUANT

###### Couche propre au projet

**4. Critères d'acceptation de la story**
- **location** : Ensemble de la PR
- **trigger_condition** : Les exigences des contrôles C7 et C8 (unicité, préfixes, validation des sources par Hugo) sont entièrement couvertes sans perdre leur intention.
- **guard_snippet** : N/A
- **potential_consequence** : La fonctionnalité livrée est conforme aux attentes de la spec `epics.md`.
- **Classement** : NON BLOQUANT

**5. Garde-fou public/privé et secrets**
- **location** : Ensemble de la PR
- **trigger_condition** : Les scripts modifiés ne manipulent, n'affichent, ni ne font fuiter aucun secret, nom d'hôte ou donnée privée.
- **guard_snippet** : N/A
- **potential_consequence** : Le cloisonnement des informations sensibles est préservé.
- **Classement** : NON BLOQUANT

**6. Concordance skill, procédure et script**
- **location** : `docs/procedures/check.md` et `scripts/checks/content.sh`
- **trigger_condition** : La documentation des contrôles C7 et C8 reflète fidèlement la logique implémentée dans le script bash.
- **guard_snippet** : N/A
- **potential_consequence** : Les procédures restent des sources de vérité fiables et exhaustives.
- **Classement** : NON BLOQUANT

**7. Cohérence avec AGENTS.md et décisions d'architecture**
- **location** : `ARCHITECTURE-SPINE.md`
- **trigger_condition** : Le recours exclusif à Hugo (via un manifeste de vérification) et à un script Bash respecte l'exigence de simplicité et d'absence d'outillage lourd.
- **guard_snippet** : N/A
- **potential_consequence** : La dette technique reste nulle, l'architecture statique est respectée.
- **Classement** : NON BLOQUANT

**8. Robustesse des scripts shell (set -euo pipefail)**
- **location** : `scripts/checks/content.sh:20` et `120`
- **trigger_condition** : L'injection de la règle `jq` via variable (here-doc) et l'exécution dans un process capturé (`lines=$(jq ...)`) empêchent toute erreur silencieuse.
- **guard_snippet** : N/A
- **potential_consequence** : Une défaillance dans le parsing JSON provoquera l'échec de la CI via `checks_die`.
- **Classement** : NON BLOQUANT

VERDICT: NON BLOQUANT — aucune


Décisions de l'auteur sur la revue du code de la PR n° 40 (`d52b3ea`, verdict `pass`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| 1 — type non énuméré : un type inattendu passait | **retenu, corrigé** | C7 compare désormais le type aux quatre valeurs d'AD-6 et nomme celui qu'il refuse ; cas de test `case_content_c7_type_inconnu` |
| 2 — `order` absent traité comme une collision | **retenu, corrigé** | l'absence est signalée pour elle-même (« clé order absente »), et les cas sans `order` sortent de la détection de doublon ; cas de test `case_content_c8_order_absent` |
| 3 — résolution des sources non testée hors `diagram` | **retenu, corrigé** | le site fixture porte maintenant un `snippet` et une `video` en plus du schéma ; le cas vérifie les trois chemins et les trois `source_found`, dont l'`url` d'une vidéo |
| 4 — critères d'acceptation satisfaits | confirmation | aucune suite |

Ces trois correctifs changent le code après la revue : une seconde revue est lancée sur la nouvelle tête, comme la règle l'exige.

### 18/09/2026 — `3b3817f` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 40. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun. Recopié ici à la main : `llm-review.sh` a refusé d'écrire dans ce fichier, dont une édition précédente avait supprimé le saut de ligne final — son garde-fou « la mise à jour supprimerait des lignes » a joué.

_Revue par `scripts/llm-review.sh` : `agy --mode plan`, copie isolée hors du dépôt au SHA relu, sans `.env` ni `docs/private/` ; skill `bmad-review` appliqué par le relecteur (angles : edge-case-hunter, verification-gap, plus la couche propre au projet). Fichiers créés ou modifiés par le relecteur dans la copie : aucun._

JETON: a8e4ce8cf9d059b2ababfd10

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter

Aucun cas limite non géré trouvé. Le script gère correctement l'absence de valeurs, les types inattendus et la profondeur de l'arborescence, en vérifiant de manière exhaustive chaque cas décrit dans la spécification. Les valeurs manquantes (`null` ou chaînes vides) sont traitées de façon robuste par Hugo et `jq`.

###### Lentille : Verification Gap

**1. Omission du type `callout` dans les tests du manifeste**
- **location** : `scripts/tests/test-checks-manifest.sh:45-66`
- **trigger_condition** : Le type `callout` est géré par la même branche que `snippet` dans le gabarit Hugo (`or (eq .type "snippet") (eq .type "callout")`), mais aucune fixture ne le teste de manière isolée.
- **guard_snippet** : Ajouter un `callout` dans les fichiers de test `case-09-fixture.*.md` et vérifier son `source_found`.
- **potential_consequence** : Une régression du manifeste affectant uniquement les `callout` pourrait ne pas être détectée par la CI.
- **gap_shape** : `regression-gap`
- **Classement** : NON BLOQUANT

##### Couche propre au projet

**2. Critères d'acceptation de la story satisfaits**
- **location** : Ensemble de la PR
- **trigger_condition** : L'implémentation répond aux exigences (unicité d'`order` limitée à la langue courante, source validée selon la langue, et évaluation complète des autres règles pour un même fichier malgré une erreur sur le groupe grâce au pipeline `jq`).
- **guard_snippet** : N/A
- **potential_consequence** : La fonctionnalité est complète et respecte strictement l'intention définie dans `epics.md`.
- **Classement** : NON BLOQUANT

**3. Garde-fou public/privé et secrets préservés**
- **location** : Ensemble de la PR
- **trigger_condition** : Les scripts modifiés ne manipulent, n'affichent, ni ne font fuiter aucune donnée privée, nom d'hôte ou secret.
- **guard_snippet** : N/A
- **potential_consequence** : Le cloisonnement des informations sensibles est totalement garanti.
- **Classement** : NON BLOQUANT

**4. Concordance skill, procédure et script (imprécision mineure)**
- **location** : `docs/procedures/check.md:321`
- **trigger_condition** : La description de ce que le script refuse a bien été mise à jour avec les règles C7 et C8, mais la première colonne du tableau Markdown liste toujours uniquement `| C4, C5, C6 |`.
- **guard_snippet** : Remplacer par `| C4, C5, C6, C7, C8 |`
- **potential_consequence** : Incohérence purement documentaire lors de la lecture du tableau.
- **Classement** : NON BLOQUANT

**5. Cohérence avec AGENTS.md et décisions d'architecture**
- **location** : `ARCHITECTURE-SPINE.md`
- **trigger_condition** : La solution exploite avec justesse les capacités natives d'Hugo (lecture du disque depuis le manifeste) et de `jq`, respectant le choix architectural de ne pas introduire d'outillage lourd.
- **guard_snippet** : N/A
- **potential_consequence** : La simplicité de la chaîne CI est préservée.
- **Classement** : NON BLOQUANT

**6. Erreurs silencieuses sous set -euo pipefail**
- **location** : `scripts/checks/content.sh`
- **trigger_condition** : L'exécution de `jq` via un process capturé garantit qu'aucune erreur de syntaxe ou d'analyse JSON ne passera inaperçue sous l'option `pipefail`.
- **guard_snippet** : N/A
- **potential_consequence** : Les contrôles CI restent très stricts et n'ignoreront aucun faux positif technique.
- **Classement** : NON BLOQUANT

VERDICT: NON BLOQUANT — ajout de C7/C8 dans le tableau de la procédure suggéré, test explicite pour callout optionnel

Décisions de l'auteur sur la deuxième revue de la PR n° 40 (`3b3817f`, verdict `pass`) : les deux suggestions sont **retenues et appliquées** — l'étiquette du tableau de `docs/procedures/check.md` nomme désormais C4 à C8, et le site fixture porte un `callout`, dont la source est vérifiée comme celle d'un extrait. Une troisième revue suit, le code ayant changé.

### 18/09/2026 — `1a5e046` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 40. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 74a37687280d91539611c33f

Voici le rapport de revue appliquant les lentilles demandées.

##### Lentille Edge-Case Hunter

Aucun cas limite non géré n'a été trouvé.
- Les valeurs manquantes (`null` pour `order` ou `group`) sont traitées correctement via `// ""` ou des filtres explicites (`select(.front_matter.order != null)`) dans l'expression `jq`.
- Les URL de vidéos composées uniquement d'espaces sont rigoureusement rejetées par le gabarit `home.checks.json` grâce à l'utilisation de `strings.TrimSpace`.
- Le groupement de `order` pour la détection des collisions ne mélange pas les langues par accident car le script boucle sur des manifestes pré-filtrés où l'unicité de la langue est garantie.

**Classement** : NON BLOQUANT

##### Lentille Verification Gap

Aucune lacune de vérification résiduelle.
- Suite aux corrections apportées par l'auteur sur la version précédente, le script de test couvre désormais de façon explicite les `callout`, `snippet` et `video`, validant la résolution des sources par Hugo pour tous les types énumérés par la règle AD-6. Le risque de régression silencieuse est écarté.

**Classement** : NON BLOQUANT

##### Couche propre au projet

**1. Critères d'acceptation de la story satisfaits**
- **location** : Ensemble de la PR
- **trigger_condition** : L'implémentation répond à toutes les exigences : unicité de la clé `order` limitée à la langue courante (par construction des manifestes), validation de la présence de la source spécifiquement dans la langue du fichier, et évaluation combinée de toutes les règles (l'array `jq` garantissant que les différentes vérifications C7 et C8 sont toutes évaluées indépendamment sans s'interrompre à la première erreur).
- **Classement** : NON BLOQUANT

**2. Garde-fou public/privé et secrets préservés**
- **location** : Ensemble de la PR
- **trigger_condition** : Aucune manipulation, exposition ou fuite de secrets, d'adresses ou de données privées. Le matériel relu est composé uniquement de scripts de validation, de gabarits internes et de fixtures de tests.
- **Classement** : NON BLOQUANT

**3. Concordance skill, procédure et script**
- **location** : `docs/procedures/check.md`
- **trigger_condition** : L'étiquette de la première colonne du tableau nomme désormais explicitement « C4, C5, C6, C7, C8 » et la description liste avec exactitude tout ce que le script `content.sh` refuse (profondeur des dossiers, matériel vivant déclaré vs placé, unicité des ordres de cas, etc.). La documentation de la procédure est à jour avec le code.
- **Classement** : NON BLOQUANT

**4. Cohérence avec AGENTS.md et décisions d'architecture**
- **location** : `ARCHITECTURE-SPINE.md` et `scripts/checks/content.sh`
- **trigger_condition** : L'approche consistant à déléguer la lecture du système de fichiers et la validation des extensions/fichiers (`assets/`) à Hugo via un manifeste JSON pour ensuite le contrôler avec `jq` respecte la doctrine `pipes-and-filters` et garantit l'absence d'outillage lourd additionnel (décisions d'architecture statique).
- **Classement** : NON BLOQUANT

**5. Robustesse des scripts shell (set -euo pipefail)**
- **location** : `scripts/checks/content.sh`
- **trigger_condition** : L'appel de l'outil JSON dans l'affectation `lines=$(jq ...)` au sein du corps de la boucle `while` plantera correctement le script et propagera l'erreur si `jq` échoue (par exemple sur un JSON malformé), car l'affectation n'est pas testée et profite pleinement de la règle `set -e`. Aucune erreur ne passe en silence.
- **Classement** : NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la troisième revue de la PR n° 40 (`1a5e046`, verdict `pass`) : aucun constat, aucune lacune résiduelle. La PR se ferme ici, dans l'esprit de la limite posée avec Arnaud à la story 2.1 : chaque passe ne trouvait plus que des points de forme, tous appliqués.

## Reporté
