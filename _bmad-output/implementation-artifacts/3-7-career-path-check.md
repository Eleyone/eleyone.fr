# Story 3.7 : Career path check

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.7.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `a7007a1`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1e060d07557d7c65a0d23054

*Ce document (classe : docs) définit le comportement du contrôle C19. Il a pour but d'aider le développeur à implémenter les vérifications de validité du parcours et des formations, et est destiné à être lu par des humains (développeur et relecteurs).*

#### 1. Lentille adverse (Adversarial)

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` |
| :--- | :--- | :--- | :--- |
| Critères d'acceptation (général) | C19 vérifie l'absence de `[TODO` dans les postes et formations publiés, mais AD-10 indique que C5 le fait déjà pour tout fichier de `content/`. | Retirer la vérification des `[TODO` de C19 si C5 couvre déjà tout `content/`. | Duplication de la logique de contrôle et confusion sur le périmètre de C5. |
| Critère 2 (postes) | La vérification `translationKey` = nom de fichier est présente pour les postes, mais absente pour `content/education/`. | Ajouter la vérification `translationKey` = nom de fichier au critère 3 pour les formations. | Un fichier de formation pourrait avoir une clé de traduction incohérente avec son nom de fichier sans déclencher d'erreur. |
| Critère 2 (postes) | AD-18 définit des champs obligatoires par déduction (ceux sans la mention "facultatif" : `company`, `role`). Le critère de C19 ne les vérifie pas. | Ajouter le contrôle de présence pour `company` et `role`. | Un poste publié sans nom de société ou sans rôle ne serait pas signalé. |
| Critère 2 (postes) | AD-18 précise que si `period` est renseigné pour une formation, la même règle s'applique. Le critère oublie de le vérifier pour les formations. | Élargir le contrôle de la `period` vide aux entrées d'éducation. | Une formation avec une période vide passerait le contrôle. |
| Critère 2 (postes) | Le contrôle de l'absence conjointe de `location` et `setup` ne précise pas s'il s'applique aux brouillons. | Préciser si l'absence de `location` et `setup` est tolérée pour un poste en `draft: true`. | Un brouillon de poste légitimement incomplet pourrait faire échouer le contrôle. |
| Critère 2 (postes) | Répétition de `order` dans un `track` : ne précise pas si cela inclut les brouillons. | Préciser si l'unicité de `order` s'évalue uniquement sur les fichiers publiés. | Faux positif bloquant si un brouillon utilise temporairement un ordre existant. |
| Critères 2 et 3 | Les valeurs valides pour `track`, `setup` et `kind` ne sont pas explicitées. | Lister les valeurs issues d'AD-18 dans la spec ou renvoyer explicitement à la liste. | L'implémenteur risque d'en oublier ou de diverger de l'architecture. |
| Critère 3 (formations) | AD-18 définit le champ obligatoire `title` pour les formations. Le critère ne le vérifie pas. | Ajouter le contrôle de présence pour `title` dans `content/education/`. | Une formation publiée sans titre ne serait pas signalée. |
| Critère 1 (cas) | L'absence de la clé `position` dans un brouillon n'est pas définie (AD-18 accepte `[TODO: poste]`). | Préciser si la clé `position` doit au moins exister en brouillon. | Des brouillons mal formés pourraient échapper au contrôle si la clé est absente. |
| Critère 1 (cas) | Tester un poste « d'une autre langue » est impossible si C3 garantit la parité des fichiers avec un translationKey identique. | Retirer la mention « d'une autre langue » si C3 rend ce cas impossible. | Test d'un cas impossible ou redondant avec C3. |
| Critères (tous) | Les fichiers `_index.md` de `career/` et `education/` n'ont pas d'`order`, `track`, etc. | Préciser explicitement que C19 ignore ces fichiers `_index.md`. | Faux positifs bloquants sur les fichiers d'index techniques. |
| Critères d'acceptation | Aucun critère ne vérifie que le `translationKey` du poste ou de la formation commence bien par le préfixe `position-` ou `education-` imposé par AD-18. | Ajouter une vérification du préfixe. | Un poste nommé `job-chiliz` passerait si tous les autres champs sont corrects. |

#### 2. Lentilles éditoriales (Structure & Prose)

*Modèle de structure : User Story / Specification.*
*Calibrage lecteur : humain (développeur)*

| Pass | Texte original | Texte révisé | Changements |
| :--- | :--- | :--- | :--- |
| structure | `... ou un poste ou une entrée publiés qui contiennent [TODO` (Critère 3) | MERGE : À supprimer si pris en charge par C5, sinon à déplacer dans un critère dédié. | Regrouper le contrôle de `[TODO` dans un critère dédié clarifie la lecture, car cela s'applique transversalement aux deux types de contenu, contrairement à `kind` ou `order`. |
| prose | `dont position désigne un poste absent` | `dont la clé position désigne un poste absent` | Précision du vocabulaire technique. |
| prose | `dont order se répète dans son track` | `dont la valeur order n'est pas unique dans son track` | Formulation plus directe du critère d'unicité. |
| prose | `sans location ni setup` | `dépourvu à la fois de location et de setup` | Lève toute ambiguïté sur la conjonction. |

**Résumé éditorial :**
- Nombre total de recommandations : 4
- Impact estimé sur la longueur : négligeable (modifications de précision)
- Cible de longueur : N/A
- Compromis : aucun, la lisibilité et la précision sont améliorées sans perte d'information.

#### À trancher avant d'implémenter

- **Périmètre C19 vs C5** : C19 doit-il vraiment vérifier la présence de `[TODO` dans les postes et formations publiés, ou C5 le fait-il déjà pour tous les fichiers de `content/` (comme indiqué dans AD-10 et AD-18) ?
- **Champs obligatoires manquants** : Faut-il ajouter à C19 la vérification stricte de présence pour `company` et `role` (postes) ainsi que pour `title` (formations), comme défini dans AD-18 ?
- **Clé de traduction et préfixes** : La vérification `translationKey == nom de fichier` doit-elle être étendue aux formations ? Doit-on aussi vérifier que les identifiants commencent bien par `position-` et `education-` ?
- **Incomplétude et brouillons** : L'absence de `location`/`setup` fait-elle échouer C19 même si le poste est en `draft: true` ? L'unicité de `order` s'évalue-t-elle sur tous les fichiers ou seulement sur les fichiers publiés ?
- **Ignorer les index** : Confirmer que les fichiers techniques `content/career/_index.md` et `content/education/_index.md` sont explicitement exclus de C19.

### Triage des constats (18/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| `[TODO` dans un poste publié : doublon avec C5 | **retenu** | C5 le fait déjà pour **tout** fichier publié de `content/` (story 3.4, vérifié). Le critère disparaît de C19 plutôt que d'exister deux fois ; la ligne C19 de l'architecture est corrigée |
| Poste « d'une autre langue » impossible si C3 passe | **retenu, nuancé** | C3 garantit la paire de fichiers, pas que le `position` d'un cas français désigne un poste **français**. Le contrôle rapproche donc dans le manifeste de la langue courante, ce qui rend le cas impossible par construction plutôt que par hypothèse |
| `_index` techniques exclus | **retenu** | ils portent le rôle `section` : C19 ne vise que les rôles `case`, `position` et `education` |
| Préfixe `position-` / `education-` non vérifié | **retenu** | AD-18 l'impose ; la règle s'ajoute, avec l'égalité `translationKey` = nom de fichier, pour les deux |
| Présence de `company`, `role` (postes) et `title` (formations) | **question à Arnaud** | AD-18 les exige, la ligne C19 ne les liste pas — même situation que l'encart d'un cas à la story 3.6 |
| Portée de l'unicité d'`order` | **question à Arnaud** | brouillons compris ou publiés seulement |
| Prose (4 reformulations) | **retenues** | fondues dans les critères |

Rappel : cette story rouvre `content.sh`, donc elle reprend aussi l'entrée reportée de la story 3.6 — une valeur d'encart faite uniquement d'espaces passe encore la règle « non vide ».

### Réponses d'Arnaud (18/09/2026)

- **Champs obligatoires** : C19 vérifie `company`, `role` et `period` sur un poste, `title` sur une formation. La ligne C19 de l'architecture est complétée.
- **Unicité des `order`** : brouillons compris.

## Ce qui est livré

- `scripts/checks/content.sh` gagne C19 : rattachement d'un cas publié à un poste **publié du même manifeste** (donc de sa langue), `translationKey` égal au nom de fichier et préfixé par `position-` ou `education-`, valeurs de `track`, `setup` et `kind`, présence de `location` **ou** `setup`, clés obligatoires renseignées, et unicité des `order` par `track` et par `kind`.
- Le doublon de C19 avec C5 (`[TODO` dans un fichier publié) est retiré : C5 couvre déjà tout `content/`. La ligne C19 de l'architecture le dit.
- **Report de la story 3.6 fermé** : une valeur faite uniquement d'espaces est désormais traitée comme absente, par deux fonctions `jq` communes (`blank`, `todo_value`) qui servent à C18 comme à C19.
- `scripts/tests/test-content.sh` : sept cas de plus ; fixtures complétées d'un poste conforme.
- `docs/procedures/check.md` et la ligne C19 de l'architecture portent les nouvelles règles.

### Essais

| Essai | Signalement |
| --- | --- |
| Cas publié, poste resté en brouillon | `C19 : position « position-chiliz » : aucun poste publié de cette langue ne porte ce translationKey` |
| Cas publié sans clé `position` | `C19 : cas publié sans clé position (AD-18)` |
| `translationKey` du poste changé | `C19 : translationKey « position-autre » ; le nom de fichier dit « position-chiliz » (AD-18)` |
| `track: annexe` | `C19 : track « annexe » ; attendu main ou parallel` |
| Poste sans `setup` ni `location` | `C19 : ni location ni setup ; l'un des deux au moins est exigé (FR-2)` |
| Second poste au même `order` | `C19 : order 1 déjà pris dans le track « main » par …position-chiliz.fr.md, …position-autre.fr.md` |
| `context.role` réduit à des espaces | `C18 : context.role absent ou vide (FR-6)` — report de la 3.6 fermé |
| Dépôt tel que commité | code 0 : le pilote et `position-chiliz`, tous deux en brouillon avec leur `[TODO`, passent |

`scripts/tests/run.sh` : 175 cas réussis (168 avant la story, 7 ajoutés).

## Revue du code

### 18/09/2026 — `29aaaca` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 42. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 85522617cbb4785e5cf99147

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` |
| :--- | :--- | :--- | :--- |
| `scripts/checks/content.sh:234` | Un poste ou une formation n'a pas de clé `order` | `($positions \| map(select(.front_matter.order == null)) \| .[] \| [.file, "C19 : order absent"])` | L'élément sera mal trié sur le site sans déclencher d'erreur C19 (seuls les doublons échouent). |

###### Lentille : Verification-Gap

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` | `gap_shape` | `consumer` | `evidence` |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `scripts/checks/content.sh:285-288` | Absence de test vérifiant qu'un poste sans `company`, `role` ou `period` échoue bien C19 | `rendu 'del(.files[1].front_matter.company)'` vérifiant `assert_eq 1 "$rc"` | La vérification de ces clés exigées (AD-18) pourrait régresser silencieusement. | `regression-gap` | `scripts/checks/content.sh` | Le fichier `test-content.sh` ne teste la suppression d'aucune de ces trois clés (contrairement à `title` pour les formations). |
| `scripts/checks/content.sh:238-240` | Absence de test vérifiant le rejet d'un `order` en double pour les formations | `case_content_c19_formation_order_en_double() { ... }` | Le contrôle d'unicité sur le type `education` pourrait être altéré sans alerter. | `regression-gap` | `scripts/checks/content.sh` | Le test `case_content_c19_order_en_double` ne cible que les doublons de postes. |

##### Constats propres au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont entièrement satisfaits dans le code de production (les contrôles C19 sont tous implémentés, l'intention des brouillons est respectée, et les champs ne contenant que des espaces sont traités comme absents). Les manques identifiés ne concernent que la couverture exhaustive de tests et un contrôle de forme indirect (présence obligatoire de l'`order` avant son unicité).
- NON BLOQUANT : Aucune donnée privée, aucun secret, aucun nom d'hôte ou adresse de serveur n'est présent dans ce diff. Les scripts n'affichent rien d'interdit.
- NON BLOQUANT : La procédure (`docs/procedures/check.md`) et le script (`scripts/checks/content.sh`) concordent parfaitement avec les règles édictées.
- NON BLOQUANT : Le changement est parfaitement cohérent avec `AGENTS.md` et le registre d'architecture (notamment la mise à jour de la règle C19 et l'intégration de la décision du 18/09/2026).
- NON BLOQUANT : Les modifications shell portent exclusivement sur des filtres de données `jq` dont le flux de sortie est testé ; aucune erreur ne peut passer en silence sous `set -euo pipefail`.

VERDICT: NON BLOQUANT — manques de couverture de tests mineurs sur des règles effectivement implémentées.

Décisions de l'auteur sur la revue du code de la PR n° 42 (`29aaaca`, verdict `pass`) : les trois constats sont **retenus et corrigés**. Un `order` absent sur un poste ou une formation est signalé pour lui-même, et les entrées sans `order` sortent de la détection de doublon ; trois cas de test couvrent `company`, `role` et `period` d'un poste, un quatrième l'`order` absent, un cinquième le doublon d'`order` entre deux formations. Le code ayant changé après le rapport, une seconde revue suit.

### 18/09/2026 — `d8a3c90` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 42. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0411dbc8953bdce5bb0ba387

##### Revue BMAD

Lentilles appliquées : `edge-case-hunter`, `verification-gap`. Le document analysé est le diff `REVIEW-DIFF.patch`.

###### Lentille : Edge-Case Hunter

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` |
| :--- | :--- | :--- | :--- |
| `scripts/checks/content.sh:328-331` | `track` n'accepte pas `[TODO` en brouillon (manque le filtrage) | `select(($f.draft == true and ($track \| todo_value)) \| not)` | Un brouillon de poste échouera faussement si son `track` est `[TODO` |
| `scripts/checks/content.sh:348-350` | `kind` n'accepte pas `[TODO` en brouillon | `select(($f.draft == true and ($kind \| todo_value)) \| not)` | Un brouillon de formation échouera faussement si son `kind` est `[TODO` |

###### Lentille : Verification-Gap

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` | `gap_shape` | `consumer` | `evidence` |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `scripts/checks/content.sh:328-337` | Absence de test pour la tolérance de `[TODO]` sur `setup` et `track` | `rendu '.files[1].front_matter.setup = "[TODO]"' ; assert_eq 0 "$rc"` | Une régression de la permissivité des brouillons passerait inaperçue | `regression-gap` | `scripts/checks/content.sh` | Les tests `case_content_c19_valeurs_du_poste` (l. 433-446) testent l'absence et l'invalidité, pas `[TODO]` |
| `scripts/checks/content.sh:271-278` | Absence de test d'isolation entre deux `track` ou `kind` | Test avec 2 postes au même `order` mais dans `main` et `parallel` | Une collision erronée entre sous-ensembles bloquerait la CI | `regression-gap` | `scripts/checks/content.sh` | Les cas `case_content_c19_*_order_en_double` testent le conflit strict dans le même domaine |

##### Constats propres au projet

- BLOQUANT : Le critère d'acceptation de la story exigeant que « un brouillon peut porter ces valeurs en [TODO » est cassé pour la clé `track` de `content.sh`, qui la rejette même en brouillon.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte, ni aucun secret n'est commité ou exposé par les scripts.
- NON BLOQUANT : La procédure `docs/procedures/check.md` et le script `scripts/checks/content.sh` concordent parfaitement sur les règles ajoutées par C19.
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et avec les règles d'architecture mises à jour (C19).
- NON BLOQUANT : Aucune commande shell introduite ne laisse passer d'erreur en silence sous `set -euo pipefail`.

VERDICT: BLOQUANT — le script rejette la valeur [TODO pour la clé track d'un brouillon, violant un critère d'acceptation explicite de la story.

Décisions de l'auteur sur la deuxième revue de la PR n° 42 (`d8a3c90`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — `track` refusait un `[TODO` dans un brouillon | **retenu, corrigé** | incohérence entre mon code et mon propre critère : AD-10 et la story autorisent la valeur `[TODO` dans un brouillon pour **toutes** ces clés. `track` la tolère désormais comme `setup`, et le message distingue une clé absente d'une valeur fausse. Trois cas de test : `[TODO` accepté dans un brouillon, refusé dans un poste publié, absence signalée |
| Constats projet non bloquants | confirmations | aucune suite |

### 18/09/2026 — `2f9333c` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 42. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 628bdfeaaf2964d66209ff6a

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` |
| :--- | :--- | :--- | :--- |
| `scripts/checks/content.sh:392-393` | La clé `kind` d'une formation rejette la valeur `[TODO` en brouillon (l'oubli signalé lors de la revue précédente sur cette même clé n'a pas été corrigé avec `track`). | `select(($f.draft == true and ($kind \| todo_value)) \| not)` | Un brouillon de formation échouera faussement si son `kind` est `[TODO`. |
| `scripts/checks/content.sh:312-319` | Le contrôle d'unicité d'`order` (incluant désormais les brouillons) regroupe les `order` identiques sans traiter le cas des `[TODO]`. | `select(.front_matter.order \| todo_value \| not)` avant de vérifier les doublons, ou filtrer sur les entiers. | Si plusieurs brouillons d'un même groupe utilisent `[TODO: order]`, ils entreront en collision et déclencheront un faux positif. |

###### Lentille : Verification-Gap

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` | `gap_shape` | `consumer` | `evidence` |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `scripts/checks/content.sh:392-393` | Absence de test vérifiant qu'un `kind` en `[TODO]` est toléré dans un brouillon. | `rendu '.files[1].front_matter.kind = "[TODO]"' ; assert_eq 0 "$rc"` | L'oubli de correction sur `kind` n'a pas pu être détecté par la suite de tests. | `regression-gap` | `scripts/tests/test-content.sh` | Le correctif (et les tests) ajoutés à ce commit ne ciblent que `track` (et `setup`). |
| `scripts/checks/content.sh:312-319` | Absence de test de collision d'`order` entre plusieurs brouillons portant `[TODO]`. | Test avec deux postes en brouillon ayant `order: "[TODO]"`. | Un cas valide lors de la rédaction de plusieurs brouillons bloquera la CI. | `edge-case-gap` | `scripts/tests/test-content.sh` | Les cas de test de doublons d'`order` (`case_content_c19_order_en_double`, etc.) n'utilisent que des valeurs entières. |

##### Constats propres au projet

BLOQUANT : Les critères d'acceptation ne sont pas pleinement satisfaits : l'intention de tolérer la valeur `[TODO` en brouillon (AD-10) est violée pour la clé `kind` (oubli de la passe précédente), et provoque un faux positif d'unicité si la clé `order` vaut `[TODO` sur plusieurs brouillons.
NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
NON BLOQUANT : La procédure (`docs/procedures/check.md`) et les scripts concordent (C19 est bien listé avec toutes ses vérifications).
NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (mise à jour appropriée de C19 dans l'architecture).
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (le traitement est délégué à `jq` qui gère correctement ces conditions).

VERDICT: BLOQUANT — la clé kind rejette toujours la valeur [TODO dans un brouillon (oubli du correctif précédent), et le contrôle d'unicité échoue faussement sur de multiples brouillons dont l'order vaut [TODO.

Décisions de l'auteur sur la troisième revue de la PR n° 42 (`2f9333c`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — `kind` refuse un `[TODO` en brouillon, et un `order` en `[TODO` produit un faux doublon | **retenu, corrigé** ; et cause traitée, pas seulement le symptôme | trois blocages successifs sur la **même famille** de défaut : chaque règle de forme décidait seule de tolérer ou non un `[TODO`. J'ai repris **toutes** les règles du fichier — `type`, préfixe et `status` du matériel vivant, `number` et `translationKey` d'un cas, `group`, `track`, `setup`, `kind`, et l'unicité des `order` — pour appliquer la même tolérance, et ajouté un cas de test qui les passe **toutes** en revue d'un coup, plus deux cas sur `kind` et sur l'`order` en `[TODO` |
| Constats projet non bloquants | confirmations | aucune suite |

Leçon pour la rétrospective de l'epic 3 : une règle transverse (ici « un brouillon tolère `[TODO` ») doit être écrite une fois et appliquée par construction, sinon chaque nouvelle règle en refait l'oubli.

### 18/09/2026 — `2149390` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 42. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: e98a47ce6fa467a5501d74ea

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` |
| :--- | :--- | :--- | :--- |
| `scripts/checks/content.sh:431-440` | Un poste ou une formation en brouillon a pour `translationKey` la valeur `[TODO]`. | Ajouter un filtre de tolérance pour exclure les brouillons : `select(($f.draft == true and (($f.translationKey // "") \| todo_value)) \| not)` avant de vérifier la valeur. | Faux positif : le script rejettera le `[TODO]` pour le `translationKey` des postes et formations, contredisant la volonté de l'auteur d'avoir généralisé la tolérance à toutes les règles du fichier. |

###### Lentille : Verification-Gap

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` | `gap_shape` | `consumer` | `evidence` |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `scripts/tests/test-content.sh` | Absence de test vérifiant que la valeur `[TODO]` est bien tolérée pour le `translationKey` d'un brouillon (poste ou formation). | `rendu '.files[1].translationKey = "[TODO]"' ; assert_eq 0 "$rc"` | L'omission de la tolérance sur cette clé spécifique est passée inaperçue malgré la passe de refonte générale. | `regression-gap` | `scripts/checks/content.sh` | Le test ajouté par l'auteur censé passer "toutes ces clés d'un coup" n'a pas échoué, ce qui prouve que le cas `translationKey = "[TODO]"` n'a pas été inclus dans ce test global. |

##### Constats propres au projet

- BLOQUANT : L'intention de la PR était de généraliser la tolérance des `[TODO]` en brouillon à *toutes* les règles de forme pour régler définitivement les blocages précédents. L'auteur a bien adapté le contrôle du `translationKey` pour les cas (l. 400), mais l'a oublié pour le `translationKey` des postes et des formations (l. 435-439). Le script rejettera donc toujours un `translationKey` en `[TODO]` pour ces contenus.
- NON BLOQUANT : Les autres clés obligatoires (`track`, `setup`, `kind`, `order`, `company`, `role`, `period`, `title`) traitent désormais parfaitement les valeurs `[TODO]` selon qu'il s'agit d'un brouillon ou non, et détectent correctement les champs entièrement vides grâce aux filtres `blank` et `todo_value`.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité dans ce diff, et aucun script n'affiche de secret ou d'adresse de forge.
- NON BLOQUANT : Le script et la procédure (`docs/procedures/check.md`) concordent parfaitement sur les nouvelles règles de C19.
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et avec le document d'architecture mis à jour pour la story 3.7.
- NON BLOQUANT : Dans les scripts shell, le traitement des conditions étant délégué à `jq`, aucune erreur ne peut passer sous silence avec `set -euo pipefail`.

VERDICT: BLOQUANT — la généralisation de la tolérance des [TODO en brouillon a été oubliée pour la clé translationKey des postes et formations, exposant au même faux positif que lors des révisions précédentes.

Décisions de l'auteur sur la quatrième revue de la PR n° 42 (`2149390`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — le `translationKey` d'un poste ou d'une formation ne tolère pas `[TODO` en brouillon | **refusé, et la règle est écrite** | ce n'est pas un oubli de la passe précédente, c'est une limite voulue. AD-10 tolère un `[TODO` sur une **valeur de contenu** — cadre, période, société, rôle, titre, nature, ordre, type, statut. Le `translationKey` est une **clé d'identité** : il est égal au nom du fichier (AD-18) et c'est par lui que la parité C3 rapproche les deux langues. Un `[TODO` y serait un identifiant, pas un marqueur de travail. La limite est désormais écrite en commentaire du contrôle, dans le critère de la story, et verrouillée par un cas de test qui vérifie le **refus** |
| Constats projet non bloquants | confirmations | aucune suite |

### 18/09/2026 — `e7746b8` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 42. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d2a475f6c46306d1cc53bcdb

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter

Aucun cas limite non géré n'a été trouvé. Le code traite convenablement toutes les conditions attendues (champs vides, valeurs `[TODO]` selon qu'elles soient dans un brouillon ou publiées).

###### Lentille : Verification-Gap

| `location` | `trigger_condition` | `guard_snippet` | `potential_consequence` | `gap_shape` | `consumer` | `evidence` |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `scripts/tests/test-content.sh` | Absence de test pour le rejet d'un `translationKey` sans préfixe `education-` pour une formation. | Ajouter un cas ou étendre `case_content_c19_translation_key_du_poste` à `education-`. | Une régression sur la vérification du préfixe des formations passerait inaperçue. | `regression-gap` | `scripts/checks/content.sh` | Le test `case_content_c19_translation_key_du_poste` valide exclusivement le préfixe `position-`. |
| `scripts/tests/test-content.sh` | Absence de test validant la tolérance de `[TODO]` en brouillon pour les champs `company`, `role`, `period` et `title`. | Inclure ces champs dans `case_content_todo_tolere_partout_dans_un_brouillon`. | Une modification supprimant cette tolérance casserait la CI silencieusement. | `regression-gap` | `scripts/checks/content.sh` | Le test censé couvrir toutes les clés omet ces quatre champs textuels obligatoires. |

##### Constats propres au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée. L'exclusion du `translationKey` de la tolérance des `[TODO]` est conforme à l'explication (clé d'identité) et au nouveau critère explicite de la story.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent parfaitement. La procédure `docs/procedures/check.md` reflète exactement les ajouts du contrôle C19.
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (le registre `ARCHITECTURE-SPINE.md` intègre correctement C19).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (le traitement est confié aux filtres `jq` avec vérification stricte).

VERDICT: NON BLOQUANT — manques mineurs de couverture de tests sur le préfixe des formations et sur la tolérance de quelques clés textuelles en brouillon.

Décisions de l'auteur sur la cinquième revue de la PR n° 42 (`e7746b8`, verdict `pass`) : aucun constat. Le relecteur accepte la limite entre valeurs de contenu et clés d'identité.

**Pour la rétrospective de l'epic 3** : cinq passes de revue sur cette story, dont quatre bloquantes, toutes sur la même famille — une règle transverse (« un brouillon tolère `[TODO` ») laissée à l'appréciation de chaque règle. La quatrième était de trop : elle généralisait la règle au-delà de son intention, et il a fallu écrire la limite pour clore. Deux leçons : une règle transverse s'écrit une fois et s'applique par construction, et une limite tacite finit par être attaquée — mieux vaut l'écrire avant.

## Reporté
