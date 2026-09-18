# Story 3.1 : Checks json manifest emitted by Hugo

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.1.

## Revue de spec

### 17/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `fc8695e`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 045dca0096d3380a555202a7

Ce document vise à définir les critères d'implémentation du manifeste JSON généré par Hugo pour les contrôles, à destination de l'agent de développement.
Modèle de structure retenu : **Prompt/Task Definition (Functional)**.

##### Revue Adversarial (Adversarial Lens)

- **location** : Général
  **trigger_condition** : La déclaration explicite du format de sortie (`outputs`) dans la configuration Hugo manque.
  **guard_snippet** : Exiger l'ajout de la définition du format de sortie `checks` pour le type `home` dans `config/work/hugo.yaml`.
  **potential_consequence** : L'agent de développement pourrait créer le gabarit sans l'activer dans la configuration, et le manifeste ne serait pas généré.

- **location** : Critères d'acceptation (Alors il liste tous les fichiers...)
  **trigger_condition** : Ambiguïté sur la nature du champ "fichier".
  **guard_snippet** : Préciser que c'est "le chemin du fichier relatif à `content/`".
  **potential_consequence** : Des chemins absolus ou relatifs au dépôt pourraient casser les scripts de contrôle qui dépendent d'un format de chemin précis.

- **location** : Critères d'acceptation (Alors il liste tous les fichiers...)
  **trigger_condition** : Les clés de front matter (track, period, etc.) ne sont pas présentes sur tous les types de contenu.
  **guard_snippet** : Préciser "les clés de front matter si elles existent (les clés absentes doivent être omises ou fixées à null)".
  **potential_consequence** : Le gabarit JSON pourrait échouer ou générer des données incohérentes s'il tente d'accéder aveuglément à des variables non définies.

- **location** : Critères d'acceptation (Alors il liste tous les fichiers...)
  **trigger_condition** : La méthode d'extraction des "identifiants placés" n'est pas spécifiée.
  **guard_snippet** : Préciser qu'ils doivent être extraits du Markdown brut via expression régulière (ex: arguments du shortcode `live-material`).
  **potential_consequence** : L'agent pourrait essayer de les chercher dans le HTML rendu, ou ne pas savoir comment les récupérer.

- **location** : Critères d'acceptation (Alors il liste tous les fichiers...)
  **trigger_condition** : L'emplacement du vocabulaire de `data/stack.yaml` dans le JSON n'est pas décrit (global ou par fichier ?).
  **guard_snippet** : Préciser que le vocabulaire est injecté sous forme d'un objet global à la racine du JSON, et non répété pour chaque page.
  **potential_consequence** : Le vocabulaire pourrait être dupliqué inutilement dans chaque élément de page, alourdissant le manifeste.

- **location** : Critères d'acceptation (Alors il liste tous les fichiers...)
  **trigger_condition** : Risque de générer du JSON invalide à cause de caractères spéciaux dans les titres H2 extraits ou dans le texte.
  **guard_snippet** : Préciser "en utilisant systématiquement la fonction `jsonify` de Hugo pour garantir un échappement strict".
  **potential_consequence** : Un titre H2 avec des guillemets ou des retours à la ligne corromprait toute la structure du fichier JSON.

- **location** : Critères d'acceptation (Alors il liste tous les fichiers...)
  **trigger_condition** : La logique de détermination de la valeur `rôle` (home, case, group, etc.) n'est pas fixée.
  **guard_snippet** : Indiquer comment le rôle est déduit (par exemple : par le type Hugo, par le chemin du dossier parent, ou via `.Kind`).
  **potential_consequence** : L'implémentation du rôle pourrait être fausse ou incohérente avec l'architecture définie.

- **location** : Critères d'acceptation (Étant donné config/work/hugo.yaml)
  **trigger_condition** : La protection contre la fuite du manifeste en production n'est vérifiée qu'en fin de chaîne.
  **guard_snippet** : Préciser explicitement que le format `checks` ne doit figurer *que* dans `config/work/hugo.yaml` et en aucun cas dans `config/_default/`.
  **potential_consequence** : Si la configuration se retrouve dans `_default/`, le fichier `checks.json` fuiterait publiquement en production.

- **location** : Liste à cocher (Entrée du pilote)
  **trigger_condition** : Le test attend spécifiquement "trois identifiants placés" pour le pilote, ce qui est très fragile.
  **guard_snippet** : Exiger une vérification de cohérence garantissant que le nombre reflète exactement ce qui est dans `content/cases/chiliz/case-02-chiliz.fr.md`.
  **potential_consequence** : Le test d'acceptation pourrait échouer si la maquette du cas a été modifiée sans mettre à jour ce critère de la story.

- **location** : Liste à cocher (Entrée du pilote)
  **trigger_condition** : Le test exige l'apparition de `position-chiliz`, mais il faut garantir que le gabarit ne l'altère pas.
  **guard_snippet** : S'assurer que le rendu JSON retranscrit la valeur brute exacte du front matter pour `position`.
  **potential_consequence** : Si Hugo transforme la casse ou ajoute un préfixe, les scripts de contrôle échoueront à identifier la relation avec le poste.

##### Revue Éditoriale (Structure & Prose Lenses)

| Pass | Original Text | Revised Text | Changes |
| :--- | :--- | :--- | :--- |
| structure | Alors il liste tous les fichiers de `content/` avec `kind`, rôle [...], identifiants placés, titres H2 du Markdown brut, présence de `[TODO`, et le vocabulaire de `data/stack.yaml`. | CONDENSE : L'objet JSON racine contient le vocabulaire de `data/stack.yaml` et un tableau listant les fichiers de `content/`. Pour chaque fichier : `kind`, `rôle` [...], `identifiants placés` (extraits du brut), `titres H2` (du brut) et présence de `[TODO`. | Sépare clairement la donnée globale (le vocabulaire) des métadonnées répétées par page pour correspondre à une forme JSON standard. |
| prose | les clés de front matter utiles aux contrôles (dont position, order, track, period, live_material, stack, summary) | les clés de front matter utiles aux contrôles (notamment : position, order, track, period, live_material, stack, summary) | Utilisation de "notamment" pour indiquer sans ambiguïté une liste non exhaustive. |
| prose | identifiants placés | identifiants de matériel vivant placés | Plus de précision sémantique, évite la confusion avec d'autres identifiants HTML. |
| prose | et aucun `checks.json` n'existe dans `public/` après le build de production. | et s'assurer qu'aucun `checks.json` n'existe dans `public/` après le build de production. | Lève l'ambiguïté pour rendre l'action de vérification explicite pour le développeur. |

**Résumé éditorial** : 4 recommandations. L'intention de la spec est claire, mais la description de la structure des données générées prête à confusion entre ce qui appartient à la racine du document (le dictionnaire global de la stack) et les métadonnées itérées par fichier. Les suggestions lèvent ces imprécisions.

##### À trancher avant d'implémenter

- **Structure racine du JSON** : Confirmer que `data/stack.yaml` est bien généré comme un objet unique à la racine du JSON (à côté d'un tableau contenant la liste des pages), pour éviter de le dupliquer dans chaque nœud de page.
- **Règle de déduction du `rôle`** : Valider la règle exacte que le gabarit doit utiliser pour distinguer les rôles (`home`, `case`, `group`, `position`, `education`, `page`), par exemple à partir du type de section Hugo ou du dossier parent.
- **Chemin relatif (`fichier`)** : Confirmer que la clé désignant le nom du fichier dans le JSON doit produire un chemin relatif exact depuis le dossier `content/` (ex: `cases/chiliz/case-02-chiliz.fr.md`).
- **Extraction Regex** : Confirmer que l'extraction des "identifiants placés" et des "titres H2" doit se faire via des expressions régulières (`findRE`) sur le `.RawContent` de Hugo.

### Triage des constats (18/09/2026)

Essai préalable sur une copie jetable, avec le Hugo épinglé (0.166.0) : format de sortie `checks` déclaré dans `config/work/hugo.yaml`, gabarit `layouts/home.checks.json`. Constats qui orientent le triage :

- `build/work/checks.json` et `build/work/en/checks.json` sont produits, et rien en production (aucun format `checks` hors de `config/work/`).
- `site.Pages` **n'inclut pas** `content/cases/_index` ni `content/career/_index` (`list: never`) ; `site.GetPage` les trouve. Lister **tous** les fichiers impose de parcourir `content/` (`os.ReadDir`, partial récursif), puis de résoudre chaque fichier par `site.GetPage`.
- `site.AllPages` est déprécié depuis 0.156 : `--panicOnWarning` le refuse.
- `.Params` met les clés en minuscules (`translationkey`) et y mêle ce que la cascade ajoute (`build`) et ce que Hugo ajoute (`iscjklanguage`). Le front matter **tel qu'écrit**, relu depuis le fichier par `os.ReadFile` et `transform.Unmarshal`, garde les clés exactes et rien d'autre.
- Sur le pilote : six H2 par `findRE` sur `.RawContent`, trois identifiants placés (`diagram-ncs-cs-flow`, `snippet-history-replay`, `callout-18-decimals`), `position-chiliz`, `draft: true`. `hugo.Data.stack.technologies` donne les 16 technologies.

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — format `outputs` non exigé dans la config | **retenu** | le critère nomme la déclaration du format `checks` et de `outputs.home` dans `config/work/hugo.yaml`, et seulement là |
| A2 — nature du champ « fichier » | **retenu** | chemin relatif à `content/`, séparateur `/` (`cases/chiliz/case-02-chiliz.fr.md`) |
| A3 — clés absentes selon le type | **retenu** | le front matter est rendu **tel qu'écrit** (`front_matter`) : une clé absente du fichier est absente de l'objet, rien n'est inventé |
| A4 — extraction des identifiants placés | **retenu** | `findRESubmatch` sur `.RawContent`, appels `{{< live-material id="…" >}}` |
| A5 — place du vocabulaire | **retenu** | une fois, à la racine (`stack`), à côté de `lang` et `files` |
| A6 — JSON invalide sur caractères spéciaux | **retenu** | tout l'objet sort d'un seul `jsonify` ; aucun JSON écrit à la main. Critère vérifié par `jq` |
| A7 — règle du rôle | **retenu**, question à Arnaud pour les sections techniques | `home` : `kind` home ; `group` : section `cases/<groupe>/_index` ; `case`, `position`, `education` : page sous `cases/`, `career/`, `education/` ; `page` : toute autre page. `cases/_index` et `career/_index` n'entrent dans aucun rôle d'AD-10 |
| A8 — format `checks` seulement dans `config/work/` | **retenu** | dit par A1 ; le critère de production reste la preuve |
| A9 — « trois identifiants » fragile | **refusé** | le critère porte sur le pilote tel que commité, qui en place trois (constaté) ; une modification du pilote relève de sa propre story et de C7 |
| A10 — valeur brute de `position` | **retenu** | couvert par A3 : valeur lue dans le fichier, non transformée |
| Structure — vocabulaire à la racine, fichiers en tableau | **retenu** | forme décrite dans le critère |
| Prose — « notamment », « matériel vivant », « s'assurer » | **retenus** les deux premiers ; **refusé** le troisième | un critère « Alors » constate, il ne prescrit pas d'action |

Constat de l'auteur, hors rapport : un fichier de `content/` sans suffixe de langue (`foo.md`) ne serait vu par aucun des deux manifestes, donc par aucun contrôle. Proposition : il figure dans les deux, avec `lang` vide et `error`, pour que la parité (C3) le signale.

### Réponses d'Arnaud (18/09/2026)

- **Rôle des sections techniques** : nouvelle valeur `section`, distincte de `group` et de `page`. AD-10 la porte.
- **Front matter** : rendu en entier, tel qu'écrit dans le fichier ; un contrôle qui a besoin d'une clé de plus n'aura pas à rouvrir le gabarit.
- **Fichier sans suffixe de langue** : listé dans les deux manifestes, avec `lang` vide et une clé `error`.

La story est réécrite dans `epics.md` en conséquence, et AD-10 porte les trois décisions.

## Ce qui est livré

- `config/work/hugo.yaml` : format de sortie `checks` et `outputs.home`, dans le rendu de travail seulement.
- `layouts/home.checks.json` : seule définition de la forme. Racine `lang`, `stack` (une fois, depuis `hugo.Data`), `files` ; une entrée par fichier avec `file`, `lang`, `kind`, `role`, `translationKey`, `draft`, `front_matter`, `h2`, `placed`, `todo`. Tout sort d'un seul `jsonify`.
- `layouts/_partials/checks-walk.html` : parcours récursif de `content/`, parce que `site.Pages` ignore les fichiers en `list: never` et que `site.AllPages` est déprécié.
- `scripts/checks/lib.sh` : la forme du manifeste documentée en tête, `checks_die` et `checks_manifests` (découverte des manifestes, code 2 si le rendu ou les manifestes manquent).
- `scripts/tests/test-checks-lib.sh` : trois cas hors ligne.

Deux pièges rencontrés, tous deux arrêtés par `--panicOnWarning` : `site.AllPages` et `site.Data` sont dépréciés depuis Hugo 0.156 ; le manifeste utilise le parcours disque et `hugo.Data`.

### Essais

| Essai | Résultat |
| --- | --- |
| `scripts/build.sh work` | `build/work/checks.json` et `build/work/en/checks.json`, JSON valide (`jq -e`), aucun avertissement |
| Contenu du manifeste FR | 6 fichiers : `_index` (home/home), `career/_index` (section/section), `career/position-chiliz` (position/page, `draft: true`, `todo: true`), `cases/_index` (section/section), `cases/chiliz/_index` (group/section, `draft: true`), `cases/chiliz/case-02-chiliz` (case/page, `draft: true`) |
| Entrée du pilote | six H2 tels qu'écrits (`## Contexte` … `## Ce que ça montre`), trois identifiants placés (`diagram-ncs-cs-flow`, `snippet-history-replay`, `callout-18-decimals`), `front_matter` aux clés exactes dont `translationKey` et `position: position-chiliz` |
| Parité | 6 fichiers dans chaque manifeste |
| Vocabulaire | 16 technologies, une seule fois, à la racine |
| `scripts/build.sh production` | aucun `checks.json` dans `public/`, aucun avertissement |
| Fichier `content/essai.md` sans suffixe de langue (copie locale) | listé dans **les deux** manifestes, `lang` vide et `error` qui nomme l'écart ; copie supprimée ensuite, `git status` propre |
| `scripts/tests/run.sh` | 103 cas réussis (100 avant la story, 3 ajoutés) |

## Revue du code

### 18/09/2026 — `82c225e` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 35. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: bb9fd42146eea6089a0bf70a

#### Rapport BMad Review

##### Edge-Case Lens

- **location**: `layouts/home.checks.json:23` (ligne d'extraction du front matter)
  **trigger_condition**: Un fichier Markdown est présent dans `content/` mais ne contient pas de bloc front matter (aucun délimiteur `---`).
  **guard_snippet**: `{{- $match := findRESubmatch "(?s)\\A---\\r?\\n(.*?)\\r?\\n---" $raw 1 -}}{{- $front := "" -}}{{- if $match -}}{{- $front = index (index $match 0) 1 -}}{{- end -}}`
  **potential_consequence**: L'appel à `index` sur un résultat vide (`[]`) lève une erreur fatale et fait échouer la compilation Hugo entière.

##### Verification-Gap Lens

- **location**: `layouts/home.checks.json`
  **trigger_condition**: La génération exacte des champs du manifeste JSON n'est validée par aucun test automatisé.
  **guard_snippet**: Un test automatisé dans `scripts/tests/` exécutant Hugo sur un dossier fixture et validant les champs de la sortie avec `jq`.
  **potential_consequence**: Une erreur logique ou de syntaxe dans le gabarit (ex: mauvaise regex des H2) passera inaperçue à la compilation et ne plantera potentiellement que plus tard.
  **gap_shape**: `regression-gap`
  **consumer**: Les futurs scripts de contrôle dépendant du manifeste (Story 3.2).
  **evidence**: `scripts/tests/test-checks-lib.sh` teste uniquement la fonction bash de découverte du fichier (`checks_manifests`), sans aucune assertion sur le contenu JSON émis.

#### Constats Projet

- BLOQUANT : **Critères d'acceptation** — L'absence de front matter dans un seul fichier Markdown fera planter le build Hugo (`index out of range`), cassant le critère exigeant que le manifeste liste toujours tous les fichiers de `content/`.
- NON BLOQUANT : **Données privées / secrets** — Aucun secret, nom d'hôte ou donnée privée n'est exposé ou susceptible de fuiter.
- NON BLOQUANT : **Concordance** — Aucune désynchronisation entre skills, procédures et scripts (aucun impact sur ceux-ci).
- NON BLOQUANT : **Architecture** — L'implémentation respecte parfaitement la règle (AD-10) déléguant la lecture des métadonnées à Hugo au lieu d'un outil externe.
- NON BLOQUANT : **Scripts shell** — Les potentielles erreurs de `find` ou l'absence de fichiers dans `checks_manifests` sont gérées explicitement et ne passeront pas sous silence avec `set -euo pipefail`.

VERDICT: BLOQUANT — Le build Hugo plantera et le manifeste ne sera pas généré si un fichier Markdown de contenu ne possède pas de front matter.

Décisions de l'auteur sur la revue du code de la PR n° 35 (`82c225e`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — build en échec sur un fichier sans front matter | **prémisse fausse**, constat utile | rejoué : `content/sans-front.fr.md`, `scripts/build.sh work` rend **0**, et l'entrée sortait avec `front_matter: null`. `index` sur une correspondance vide donne `nil` dans Hugo 0.166, pas une erreur. Le `null` silencieux restait un défaut : le gabarit teste désormais la correspondance et pose `error` (« front matter absent »), comme pour un fichier sans suffixe de langue. Vérifié : build à 0, entrée avec `error`, et aucune entrée en `error` une fois la copie retirée |
| Verification-gap — aucun test n'exerce le gabarit lui-même | **reporté** à la story 3.2 | un test qui construit un site fixture avec le vrai Hugo et lit le manifeste à `jq` vaut mieux qu'un bouchon ; la 3.2 crée `scripts/check.sh`, premier consommateur du manifeste, et ses fixtures. Entrée dans `deferred-work.md` |
| Constats projet non bloquants (4) | confirmations | aucune suite |

### 18/09/2026 — `6d846fe` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 35. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1b61030e85021b7a23cb1b82

##### BMad Review

###### Edge-Case Lens
Aucun cas limite non géré n'a été détecté. La génération du JSON (`layouts/home.checks.json`) couvre rigoureusement les cas limites potentiels soulevés par l'architecture : fichiers sans suffixe de langue, Markdown sans bloc de front matter (évitant ainsi le plantage `index out of range`), et fichiers introuvables via `site.GetPage`. Pour chaque cas, une clé `error` explicite et porteuse de sens est ajoutée à l'entrée JSON, protégeant ainsi l'exécution des futurs contrôles sans arrêter silencieusement le rendu.

###### Verification-Gap Lens
No verification gaps found.
*(Note : L'absence de tests vérifiant la structure exacte des champs du manifeste `checks.json` a été explicitement reconnue et actée dans `deferred-work.md` pour être traitée dans la story 3.2, qui introduira le premier consommateur réel de ce fichier avec des fixtures de build complètes. C'est une démarche saine qui ne constitue donc pas une faille cachée.)*

##### Constats Projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (le manifeste couvre tous les fichiers de `content/` même ceux hors collections, préserve la casse du front matter initial, et le format n'est activé qu'en environnement de travail).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent (aucun décalage introduit).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (il implémente fidèlement la décision AD-10 documentée dans `ARCHITECTURE-SPINE.md`).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (dans `scripts/checks/lib.sh`, l'appel à `find` et l'évaluation de la variable `found` gèrent explicitement leurs cas d'erreur par des branchements `|| checks_die`).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la deuxième revue de la PR n° 35 (`6d846fe`, verdict `pass`) : aucun constat à traiter ; le report du test du gabarit à la story 3.2 est confirmé par le relecteur. Une tentative de revue s'était arrêtée sans rien publier avant celle-ci, le relecteur ayant voulu lancer une commande shell que l'isolement lui refuse — même incident qu'à la story 2.4.

## Reporté
