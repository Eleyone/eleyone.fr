# Story 3.8 : Zero JavaScript, no third party, no TODO

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.8.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `71179a1`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a055b1c52c85bf7152439753

### Rapport de revue BMAD : Story 3.8

**Lecture de la cible** : Ce document existe pour aider le développeur à implémenter les contrôles bloquants C10 (pureté HTML et ressources externes) et C5 (absence de TODO) dans le build de production, en définissant des critères de test vérifiables. (Modèle structurel : Spécification / Comportement).

#### Lentille : Adverse (Adversarial)

| Lens | Location | Trigger Condition | Guard Snippet | Potential Consequence |
|---|---|---|---|---|
| adversarial | Critères d'acceptation, bloc 1 | "toute ressource d'une autre origine" ne précise pas quelles balises/attributs vérifier avec XPath. | Préciser les requêtes XPath (ex: `//img[starts-with(@src,'http')]`, `//link`, etc.) pour définir l'origine tierce. | Le script laisse passer une balise inattendue (ex: `<source>`, `<track>`), violant NFR-3. |
| adversarial | Critères d'acceptation, bloc 1 | Les appels externes via CSS (`@import`, `url(...)`) dans les attributs `style=` ou les balises `<style>` ne sont pas couverts. | Ajouter une vérification par `grep` de `url(http` ou `@import` dans le code HTML/CSS. | Une ressource tierce (police, image) est chargée via CSS sans être vue par `xmllint`. |
| adversarial | Critères d'acceptation, bloc 1 (C5) | La recherche de `[TODO` par `grep` ne précise pas sur quels fichiers elle s'applique dans `public/`. | Spécifier que C5 cible tous les fichiers (ou seulement `.html`, `.xml`, `.css`) de `public/`. | Le script échoue sur un fichier binaire (PDF, image) ou pollue les journaux. |
| adversarial | Critères d'acceptation, bloc 2 | La validation "un bloc JSON invalide" ne nomme pas l'outil à utiliser (contrairement à `xmllint` pour le HTML). | Préciser l'extraction du contenu de la balise `<script>` et sa validation syntaxique via `jq`. | L'implémenteur omet la validation stricte ou perd du temps à chercher comment valider du JSON en bash. |
| adversarial | Critères d'acceptation, bloc 2 | La règle "une clé hors FR-35" impose au script de connaître la liste, mais elle n'est pas fournie dans la spec. | Lister explicitement les clés JSON-LD autorisées (issues de FR-35) dans les critères. | L'implémenteur met en place une liste incorrecte ou incomplète de clés acceptées. |
| adversarial | Critères d'acceptation, checklist finale | Le minifieur de Hugo retire les guillemets (AD-5) ; `xmllint --html` produit de nombreuses erreurs sur le HTML5 non formatté "XML strict". | Préciser de rediriger `stderr` de `xmllint` vers `/dev/null` pour ne garder que la sortie XPath. | Le job CI échoue ou ses journaux sont illisibles à cause des erreurs de parsing libxml2. |
| adversarial | Critères d'acceptation, bloc 2 | Le critère "un bloc sur une autre page que l'accueil" suppose que le script sait identifier l'accueil dans `public/`. | Spécifier que l'accueil correspond strictement aux fichiers `/index.html` et `/en/index.html`. | Le script teste incorrectement les `index.html` des sous-sections (qui sont des pages de liste). |
| adversarial | Critères d'acceptation, bloc 1 | Exécution de `scripts/checks/html.sh` alors qu'AD-10 stipule que `scripts/check.sh` est le seul point d'entrée. | Mentionner l'exécution via `scripts/check.sh` ou préciser qu'on teste le module en isolation. | Confusion sur l'intégration du script dans la chaîne globale et contradiction littérale avec AD-10. |
| adversarial | En-tête (Dépendances) | Il n'est pas fait mention des prérequis pour s'assurer que le HTML cible existe. | Confirmer que le HTML cible (fixture) a bien une structure valide minimale avec des attributs pour le test. | Les cas de test échouent parce que la fixture de la story 3.8 ne contient pas ce qui est attendu. |
| adversarial | Critères d'acceptation, bloc 2 | Le comportement transitoire ("jusqu'à la story 9.6") ne dit pas comment marquer cette dette technique dans le code. | Préciser l'ajout d'un commentaire `# TODO (story 9.6): ...` dans le script shell. | L'adaptation de la règle est oubliée lors de la story 9.6 car aucune trace n'est visible. |

#### Lentilles Editoriales : Structure et Prose

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| structure | *Ensemble du bloc 1* : « il signale toute balise `<script>` dont le type n'est pas exactement `application/ld+json` ou qui porte `src`, tout attribut `on*=`, toute `<iframe>`, tout `<form>`, toute ressource d'une autre origine, et toute occurrence de `[TODO`. » | MERGE (sous forme de liste à puces des contraintes) | Transforme la longue phrase accumulant les contraintes en une liste à puces claire (scripts, iframes, formulaires, origines tierces, TODO) pour faciliter la création des assertions de test par le développeur. |
| prose | « un bloc conforme passe, et l'absence de bloc passe aussi : la règle est « au plus un bloc, conforme, et seulement sur l'accueil » jusqu'à la story 9.6, qui la passe à « exactement un ». » | « Zéro ou un bloc conforme est accepté (règle : "au plus un" jusqu'à la story 9.6, puis "exactement un"). » | Suppression des répétitions ("passe", "règle"), phrase plus directe et concise. |

**Résumé éditorial** : 2 recommandations. La densité de la spec est bonne. La transformation du premier bloc de critères d'acceptation en liste à puces améliorera significativement sa lisibilité.

***

#### À trancher avant d'implémenter

- **Erreurs `xmllint` sur HTML minifié** : Le minifieur de Hugo supprime les guillemets des attributs (AD-5), ce qui fait généralement échouer le parser strict de `xmllint --html`. Doit-on masquer systématiquement son flux d'erreur (`2>/dev/null`) pour ne pas polluer les journaux de CI, voire autoriser un filtre spécifique ?
- **Ressources tierces dans le CSS** : `xmllint` ne peut pas inspecter le contenu des balises `<style>` ni des attributs `style=""`. Faut-il ajouter un `grep` ciblant spécifiquement `url(http` et `@import` pour garantir qu'aucune police ou image externe n'est chargée indirectement par le CSS ?
- **Clés JSON-LD de FR-35** : Pour faciliter le contrôle par `jq`, peux-tu confirmer la liste exacte des clés autorisées pour l'objet "Person" à coder en dur dans le script ?
- **Identification de l'accueil** : Confirmes-tu que le script doit limiter le contrôle "zéro ou un bloc JSON-LD" stricto sensu aux chemins `public/index.html` et `public/en/index.html` ?

### Triage des constats (18/09/2026)

Aucune question à Arnaud : les six points « à trancher » du rapport ont tous leur réponse dans AD-20, AD-10 ou FR-35. Les voici, avec leur source.

| Constat | Décision | Suite |
| --- | --- | --- |
| Balises à inspecter pour une origine tierce | **retenu** | le critère nomme les attributs de chargement (`src`, `srcset`, `poster`, `data`) et `link/@href`, sur **toute** balise : ce qui compte est l'attribut, pas la liste des éléments, sinon un `<source>` ou un `<track>` futur passerait |
| Ressources tierces appelées depuis le CSS | **retenu** | `xmllint` ne lit pas le CSS : un `grep` cherche `url(http` et `@import` dans le HTML et dans les feuilles publiées. Aucune feuille n'existe avant l'epic 5 ; la règle les attend |
| Portée du `[TODO` dans `public/` | **retenu** | fichiers de texte publiés (`.html`, `.xml`, `.css`, `.txt`, `.json`), jamais les binaires |
| Outil de validation du JSON-LD | **retenu, déjà écrit** | AD-20 le dit : « son contenu est un JSON valide (`jq`) de `@type` `Person` » |
| Liste des clés autorisées | **retenu, déjà écrite** | FR-35 et AD-20 : `@context`, `@type`, `name`, `alternateName`, `jobTitle`, `address` (avec `addressCountry`), `url`, `sameAs`. Rien d'autre |
| Erreurs de `xmllint` sur du HTML5 minifié | **retenu, déjà écrit** | AD-10 : « le parseur HTML de libxml2 antérieur à 2.14 signale les balises HTML5 comme invalides : ces avertissements sont ignorés ». La sortie d'erreur est donc écartée, et seule la sortie XPath est lue |
| Identification de l'accueil | **retenu** | `index.html` à la racine de chaque langue (`public/index.html`, `public/en/index.html`), jamais un `index.html` de sous-dossier |
| Point d'entrée | **retenu, déjà écrit** | `html.sh` est découvert et lancé par `check.sh` (AD-10, story 3.2) ; il se lance aussi seul pour un essai |
| Marque de la dette de la story 9.6 | **retenu** | un commentaire nommant la story 9.6 dans le script, là où la règle passera de « au plus un » à « exactement un » |
| Structure et prose (2) | **retenus** | les critères passent en liste |

### Une décision d'Arnaud, en cours de story

`xmllint` manquait sur le poste. AD-10 l'impose pour les contrôles HTML, et son absence aurait fait échouer `check.sh` en anomalie — donc le substitut d'amorçage, donc **toute** PR. Arnaud a choisi de l'installer (`libxml2-utils`) plutôt que d'écrire le contrôle sans XPath ou de le laisser muet. Le contrôle s'arrête donc en code 2 si l'outil manque, et la procédure de montage d'un poste le liste désormais avec `jq`.

## Ce qui est livré

- `scripts/checks/html.sh` (C10 et la moitié « sortie » de C5) : scripts, attributs `on…`, `<iframe>`, `<form>`, ressources chargées depuis un autre hôte (HTML **et** CSS), marqueurs `[TODO` dans les fichiers de texte publiés, et le bloc JSON-LD (au plus un, sur l'accueil, JSON valide, `@type` `Person`, clés de FR-35).
- `scripts/tests/test-html.sh` : 15 cas sur des fixtures HTML minifiées, comme la production.
- `docs/procedures/check.md` (tableau des contrôles) et `docs/procedures/poste-de-developpement.md` (`xmllint` en prérequis).

### Un faux positif trouvé sur la production réelle

La première version signalait les `hreflang` du site : AD-2 les écrit en **URL absolue**, et `link rel="alternate"` ne charge rien. La règle distingue maintenant l'hôte du site — lu dans `baseURL` — des autres, et ne regarde que les relations qui **chargent** une ressource. Deux cas de test verrouillent cette distinction, dont un sur un `hreflang` absolu.

### Essais

| Essai | Résultat |
| --- | --- |
| Production réelle | code 0, « zéro script, aucune ressource tierce, aucun marqueur » |
| `<script>`, `<script src>`, `type=module`, `onclick`, `<iframe>`, `<form>` | un signalement chacun, code 1 |
| `<img src>` et `<link rel=stylesheet>` vers un autre hôte | signalés ; `<a href>` vers un tiers et `hreflang` absolu du site : acceptés |
| `url(https://autre-site/…)` dans une balise `<style>` | signalé ; le même vers le site lui-même : accepté |
| `[TODO` dans une page publiée | signalé avec sa ligne |
| JSON-LD : hors accueil, en double, invalide, `@type` `Organization`, clé `telephone` | un signalement chacun ; bloc conforme et absence de bloc : acceptés |
| Production absente | code 2, message qui dit quoi lancer |

`scripts/check.sh` enchaîne les deux builds puis les trois contrôles : « 3 contrôle(s) passés ». `scripts/tests/run.sh` : 198 cas réussis (183 avant la story, 15 ajoutés).

## Revue du code

### 18/09/2026 — `9d87a6a` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 43. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9969167164e4df1b406eefec

##### Rapport de revue BMAD : Story 3.8

###### Lentille : Edge-case Hunter & Verification Gap

- **BLOQUANT**
  **Location** : `scripts/checks/html.sh`, itérations sur les attributs tiers (lignes 278, 302, 311).
  **Trigger condition** : L'outil `xmllint --xpath` appelé sur des nœuds attributs (`//@src`, `//@href`) renvoie les valeurs concaténées par des espaces sur une seule ligne (ex: ` src="https://eleyone.fr/1" src="https://tiers.com/2"`). La boucle de lecture lit toute la ligne d'un coup. La fonction `origine_tierce` n'analysant que la première URL, si la ligne commence par une URL absolue légitime du site, `host` vaudra `eleyone.fr` et la fonction retournera faux pour toute la ligne.
  **Guard snippet** : Séparer les nœuds attributs par des retours à la ligne avant traitement (ex: utiliser `grep -oE 'http[^"]+'` sur le HTML, ou filtrer la sortie XPath via `| tr ' ' '\n' | grep '='`).
  **Potential consequence** : Une ressource tierce est silencieusement acceptée en production si elle est précédée sur la même page par une ressource absolue du site de même attribut, vidant de son sens le contrôle bloquant C10.

- **NON BLOQUANT**
  **Location** : `scripts/tests/test-html.sh`, tests sur les ressources tierces.
  **Trigger condition** : Les assertions n'insèrent qu'une seule balise illicite par page de test, ce qui ne confronte jamais le script aux résultats concaténés de `xmllint`.
  **Guard snippet** : Ajouter un cas de test avec balises multiples, ex: `<img src="https://eleyone.fr/1.jpg" /><img src="https://tiers.invalide/2.jpg" />`.
  **Potential consequence** : Le manque de diversité de la fixture (Verification Gap) a laissé passer le bug de concaténation en créant un faux sentiment de couverture complète.

###### Couche propre au projet

- **BLOQUANT**
  **Location** : `scripts/checks/html.sh`, lignes 327 et 334 (analyse de l'objet JSON-LD).
  **Trigger condition** : Si le bloc JSON-LD est un JSON syntaxiquement valide mais n'est pas un objet (ex: le tableau `[]` ou la chaîne `"texte"`), les commandes `jq -r '."@type"'` ou `keys[]` retournent une erreur d'indexation (code 5).
  **Guard snippet** : Protéger l'accès via `jq` en vérifiant le type en amont, par exemple `jq -r 'if type=="object" then ."@type" else "" end'`.
  **Potential consequence** : Sous l'effet de `set -euo pipefail`, l'échec de `jq` au sein de la substitution de commande `type_jsonld=$(...)` tue instantanément le script. Une erreur de contenu se traduit par un crash shell silencieux non géré au lieu du signalement textuel `checks_report` attendu.

- **NON BLOQUANT**
  **Location** : `scripts/checks/html.sh`, ligne 235 (extraction de `$site_host`).
  **Trigger condition** : La regex `sed` présuppose l'absence de guillemets autour de l'URL de `baseURL` dans `config/_default/hugo.yaml`.
  **Guard snippet** : Ajouter le traitement des guillemets optionnels : `s#^baseURL:[[:space:]]*['\"]?https\?://\([^/'\"]*\).*#\1#p`.
  **Potential consequence** : L'ajout courant de guillemets en YAML fera échouer la regex, rendant `$site_host` vide et bloquant légitimement (mais inutilement) le script sur l'assertion `[[ -n $site_host ]]`.

- **NON BLOQUANT**
  **Location** : Global (Données privées, secrets et alignement architectural).
  **Trigger condition** : Audit croisé des garde-fous, des données et de la procédure.
  **Guard snippet** : N/A
  **Potential consequence** : Les critères d'acceptation (hors failles signalées) sont respectés. Aucune donnée privée, aucun secret et aucune adresse de serveur n'a fuité. L'intégration de `xmllint` suit l'AD-10 et son ajout à la procédure concorde avec les prérequis du script.

VERDICT: BLOQUANT — Contournement de la détection des ressources tierces par concaténation XPath et crash non géré de jq sur un JSON-LD de type tableau ou scalaire.

Décisions de l'auteur sur la revue du code de la PR n° 43 (`9d87a6a`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — attributs concaténés par `xmllint`, une ressource tierce passerait derrière une ressource du site | **prémisse fausse ici, parade quand même** | rejoué : avec la libxml2 du poste, `xmllint` rend **une valeur par ligne**, et l'image tierce placée après une image du site est bien signalée. Le défaut n'existait donc pas. Mais la sortie dépend de la version : la lecture découpe désormais les attributs elle-même, ce qui rend le cas impossible partout. Cas de test ajouté, avec deux images sur la même page |
| BLOQUANT — un JSON-LD valide mais non-objet tue le script | **retenu, corrigé** | rejoué : avec `[]`, `jq` sort en **code 5** et le contrôle meurt au lieu de signaler. Le type est désormais vérifié avant toute indexation, et le cas devient un écart ordinaire. Deux cas de test, sur `[]` et sur une chaîne |
| Non bloquant — `baseURL` entre guillemets | **retenu, corrigé** | la lecture accepte les guillemets simples ou doubles ; vérifié sur les deux écritures |
| Non bloquant — fixtures à une seule balise | **retenu, corrigé** | le nouveau cas met deux ressources sur la même page |

### 18/09/2026 — `c20151f` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 43. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : ajouté test_set_e.sh.

JETON: a4cf1da37459b2c920b469f6

##### Rapport de revue BMAD

###### Lentille : Edge-case Hunter

- BLOQUANT : `scripts/checks/html.sh:414` (recherche CSS) | La déclaration CSS utilise une casse non standard (ex: `URL(...)` ou `@IMPORT(...)`). Une ressource tierce échappe au contrôle en jouant sur la casse, ce qui casse le critère d'acceptation C10. *Garde* : Ajouter le flag `-i` à `grep` (`grep -oiE "(url\(|@import..."`).
- NON BLOQUANT : `scripts/checks/html.sh:301` (`origine_tierce`) | L'URL contient une query string ou un fragment sans chemin explicite (ex: `https://eleyone.fr?q=1`). Une ressource légitime du site est bloquée en faux positif car la query string reste attachée à l'hôte extrait. *Garde* : Remplacer la découpe par `host=${host%%[/?#]*}`.

###### Lentille : Verification Gap

- NON BLOQUANT : `scripts/checks/html.sh:327` (`est_accueil`) | La regex `^[a-z]{2}/index\.html$` valide les accueils traduits, mais aucun test ne l'exécute. Une régression sur cette regex casserait l'acceptation du JSON-LD sur les traductions sans qu'aucun test ne le signale (*broken-verification-gap* pour le consommateur `html.sh:377`). *Garde* : Créer le dossier `en` dans les fixtures de test et vérifier son acceptation.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont globalement implémentés et satisfaits, à l'exception de la faille de casse CSS signalée plus haut.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte non autorisé ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent parfaitement (l'exigence de `xmllint` dans le script correspond à l'ajout dans la procédure du poste de développement).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (contrôles statiques via des utilitaires shell natifs, sans JavaScript ni usine à gaz).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (les pipelines pouvant renvoyer un statut 1 légitime sont sécurisés par `|| true`, et les erreurs non prévues feront échouer bruyamment le script).

VERDICT: BLOQUANT — L'extraction des ressources tierces dans le CSS est sensible à la casse, ce qui permet de contourner le critère d'acceptation d'isolation avec URL(...).

Décisions de l'auteur sur la deuxième revue de la PR n° 43 (`c20151f`, verdict `block`) : les trois constats sont **retenus et corrigés**. La recherche CSS est insensible à la casse, les mots-clés CSS l'étant (`URL(`, `@IMPORT`) ; l'hôte se découpe aussi sur `?` et `#`, sinon une ressource du site suivie d'une requête était refusée ; et l'accueil traduit, dont la reconnaissance n'était couverte par aucun cas, a le sien — avec son pendant, l'`index.html` d'un sous-dossier, qui doit rester refusé. Trois cas de test ajoutés.

### 18/09/2026 — `2a4367b` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 43. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c69c89dba582eaefd307c1cd

##### Rapport de revue BMAD

###### Lentille : Edge-case Hunter

- **BLOQUANT** — Location : `scripts/checks/html.sh:391` | Trigger condition : Un attribut `srcset` contenant de multiples URL séparées par des virgules (ex: `/local.webp 1x, https://tiers.invalide/ext.webp 2x`) n'est pas détecté. Le prédicat XPath `starts-with(@srcset, 'http')` l'ignore si la première URL est relative. S'il commence par l'hôte du site, la fonction `origine_tierce` n'extrait que la première URL et ignore la tierce qui suit. | Guard snippet : Extraire l'attribut `srcset` sans `starts-with`, découper les URL (ex: `tr ',' '\n' | awk '{print $1}'`) et tester chaque origine. | Potential consequence : Une ressource tierce injectée via `srcset` échappe totalement au contrôle bloquant C10.
- **BLOQUANT** — Location : `scripts/checks/html.sh:398` | Trigger condition : Une balise `<link>` chargeant une ressource avec un attribut `rel` combiné (ex: `rel="preload stylesheet"`) est ignorée car le prédicat `[@rel='$rel']` exige une correspondance exacte. | Guard snippet : Remplacer par `//link[contains(concat(' ', normalize-space(@rel), ' '), ' $rel ')]`. | Potential consequence : Une ressource tierce échappe au contrôle C10 en masquant sa déclaration de chargement dans un attribut multiple.

###### Lentille : Verification Gap

- **NON BLOQUANT** — Location : `scripts/tests/test-html.sh` | Trigger condition : L'absence de tests sur des attributs `srcset` multi-URL et des attributs `rel` combinés cache les failles de parsing associées. | Guard snippet : Ajouter des fixtures de test complexes, par exemple `<img srcset="/img.jpg 1x, https://tiers.invalide/img.jpg 2x">` et `<link rel="preload stylesheet" href="https://tiers.invalide/style.css">`. | Potential consequence : Un faux sentiment de sécurité sur la détection des ressources tierces (Verification Gap).

###### Couche propre au projet

- **BLOQUANT** — Location : `scripts/checks/html.sh:405` | Trigger condition : Si un fichier HTML est vide ou si `xmllint` ne produit aucune sortie standard (les erreurs étant redirigées vers `/dev/null`), la variable `nombre` est une chaîne vide. Sous `set -euo pipefail`, l'évaluation `((nombre > 0))` déclenche une erreur de syntaxe bash (`operand expected`). | Guard snippet : Fournir une valeur par défaut lors de l'évaluation : `((${nombre:-0} > 0))`. | Potential consequence : Une erreur passe de façon non gérée sous `set -euo pipefail` par un crash du shell, arrêtant brutalement la CI au lieu d'émettre un code d'erreur applicatif.
- **NON BLOQUANT** — Location : Global | Trigger condition : Audit des critères d'acceptation restants, données privées et architecture. | Guard snippet : N/A | Potential consequence : Les autres règles (C5, JSON-LD) sont solidement vérifiées. Aucune donnée privée ni secret ne fuite, et la cohérence avec les procédures et l'AD-10 (usage de `xmllint` et `jq`) est totale.

VERDICT: BLOQUANT — Les ressources tierces dissimulées dans des attributs multiples (`srcset`, `rel`) contournent la détection, et le script est vulnérable à un crash de syntaxe bash si l'extraction XPath du compte de JSON-LD retourne une chaîne vide.

Décisions de l'auteur sur la troisième revue de la PR n° 43 (`2a4367b`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — `srcset` à plusieurs URL | **retenu, corrigé** | réel : le prédicat XPath ne regardait que le **début** de l'attribut, et une URL tierce placée après une URL locale passait. L'attribut entier est désormais découpé sur les virgules, chaque candidat étant confronté à l'hôte du site. Deux cas de test |
| BLOQUANT — `rel` combiné (`preload stylesheet`) | **retenu, corrigé** | réel : la comparaison exacte manquait la relation. Elle porte maintenant sur les **jetons** du `rel`, insensible à la casse. Deux cas de test, dont un `rel` combiné qui ne charge rien et doit passer |
| BLOQUANT — compte vide et arithmétique bash | **prémisse fausse ici, parade quand même** | rejoué : sur un fichier HTML vide, `xmllint` rend bien `0` et le contrôle passe. La sortie dépendant de la version, les trois comptes reçoivent une valeur par défaut |
| Non bloquant — fixtures sans attributs complexes | **retenu, corrigé** | les quatre cas ci-dessus les apportent |

Trois passes bloquantes sur cette story, toutes sur la **surface d'attaque du contrôle** : un contrôle de sécurité se juge sur ce qu'il laisse passer, et chaque passe a trouvé une façon de le contourner. C'est exactement ce qu'une revue adverse doit faire, et ces trouvailles valaient les passes.

### 18/09/2026 — `6a49e20` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 43. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0563948a34ee0043ac05afa8

##### Rapport de revue BMAD : Story 3.8 (Troisième passe)

###### Lentille : Edge-case Hunter

- **BLOQUANT** — Location : `scripts/checks/html.sh:365` (fonction `origine_tierce`) | Trigger condition : Le filtrage par motif `case $url in http://*|https://*)` est sensible à la casse sous bash. Si une ressource tierce utilise un schéma en majuscules (ex: `HTTP://tiers.invalide/ext.webp`), l'URL tombe dans la branche par défaut (`*) return 1 ;;`) de la fonction. Elle n'est alors pas identifiée comme tierce et le contrôle est silencieusement contourné. | Guard snippet : Ajouter l'option bash `shopt -s nocasematch` au début de la fonction (et `shopt -u nocasematch` à la fin), ou utiliser des motifs supportant la casse : `[hH][tT][tT][pP]://*|[hH][tT][tT][pP][sS]://*)`. | Potential consequence : Une ressource malveillante ou non désirée peut être chargée sur le site en jouant sur la casse du protocole, vidant de son sens le contrôle de sécurité principal (C10).
- **NON BLOQUANT** — Location : `scripts/checks/html.sh:401` (validation du type de `<script>`) | Trigger condition : L'extraction suppose que `xmllint` précède systématiquement le nom de l'attribut par un espace (rendant la chaîne ` type="application/ld+json"`) et s'appuie sur un découpage de chaîne par indices fixes (`${type:7:-1}`). Si le parseur supprime l'espace, la condition stricte échoue et la chaîne tronquée affichée sera erronée (ex: `plication/ld+json`). | Guard snippet : Utiliser la fonction interne `xpath_attributs "$page" "//script[@type]/@type" type` pour extraire la valeur purement, indépendamment de la sérialisation, avant de la comparer avec `application/ld+json`. | Potential consequence : Le garde-fou reste efficace, mais la CI peut remonter de faux positifs accompagnés de messages d'erreurs tronqués selon la version de `libxml2`.

###### Lentille : Verification Gap

- **NON BLOQUANT** — Location : `scripts/tests/test-html.sh` | Trigger condition : L'intégralité des fixtures et des assertions sur les ressources tierces n'emploient que des URL dont le protocole est rigoureusement en minuscules (ex: `https://cdn.exemple.invalide`). | Guard snippet : Ajouter un cas de test vérifiant explicitement l'imperméabilité à un schéma mixte ou en majuscules, comme `<img src="HtTpS://tiers.invalide/photo.jpg">`. | Potential consequence : Ce manque de variété dans les cas aux limites (Verification Gap) a créé un faux sentiment de couverture totale et laissé passer la faille de sensibilité à la casse détaillée ci-dessus.

###### Couche propre au projet

- **BLOQUANT** — Location : Critères d'acceptation | Trigger condition : L'impossibilité de la fonction `origine_tierce` à détecter des protocoles en majuscules invalide l'exigence formelle. | Guard snippet : Appliquer la correction sur la casse dans l'évaluation bash. | Potential consequence : L'intention du critère (bloquer absolument toute ressource tierce sous n'importe quelle forme) est rompue, rendant la story incomplète et contournable.
- **NON BLOQUANT** — Location : Données privées et secrets | Trigger condition : Examen complet du diff, des noms d'hôtes et des tests ajoutés. | Guard snippet : N/A | Potential consequence : L'engagement de confidentialité est tenu. Les fixtures utilisent des domaines fictifs pertinents (`.invalide`), et aucun secret ou adresse réelle (autre que le domaine public) ne transparaît.
- **NON BLOQUANT** — Location : Cohérence scripts/procédures | Trigger condition : Comparaison des nouveaux besoins avec les documents ajoutés. | Guard snippet : N/A | Potential consequence : Parfaite synchronisation. Le nouveau prérequis `libxml2-utils` est proprement justifié et consigné dans `docs/procedures/poste-de-developpement.md`.
- **NON BLOQUANT** — Location : Décisions d'architecture | Trigger condition : Revue de la méthode d'analyse statique retenue (bash, xpath, jq). | Guard snippet : N/A | Potential consequence : Le changement est en pure conformité avec AGENTS.md, gardant la vérification logicielle robuste, sans JS ni dépendances abusives.
- **NON BLOQUANT** — Location : Scripts shell sous `set -euo pipefail` | Trigger condition : Audit des boucles et des exécutions de commandes en cascade (`grep`, `xmllint`). | Guard snippet : N/A | Potential consequence : Aucun crash silencieux ne passera. Les commandes sujettes à échec légitime au sein des pipelines sont convenablement traitées avec des `|| true`, garantissant la stabilité de la chaîne d'intégration continue.

VERDICT: BLOQUANT — L'extraction du domaine tierce partie est sensible à la casse (HTTP vs http) dans la fonction bash, permettant aux ressources externes de contourner entièrement le garde-fou C10.

Décisions de l'auteur sur la quatrième revue de la PR n° 43 (`6a49e20`, verdict `block`) : les deux constats sont **retenus et corrigés**. Un schéma en majuscules (`HTTP://`) échappait à la fonction, qui comparait une casse exacte : schéma et hôte se comparent désormais en minuscules, avec un cas de test sur `HtTpS://` et un autre sur le site lui-même écrit en majuscules. L'extraction du `type` d'une balise `<script>` ne découpe plus la chaîne à l'indice mais lit la valeur de l'attribut, la sérialisation de `xmllint` variant d'une version à l'autre.

### 18/09/2026 — `1340bfa` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 43. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b3f3126e54abd9eb557f5932

##### Rapport de revue BMAD (Story 3.8)

###### Lentille : Edge-case Hunter

- NON BLOQUANT — Location : `scripts/checks/html.sh` | Trigger condition : Vérification de la robustesse des garde-fous sur la casse du schéma et la sérialisation XML. | Guard snippet : N/A | Potential consequence : Les corrections sont irréprochables. L'implémentation de la fonction `xpath_attributs` avec `grep -oE` neutralise définitivement toute concaténation inattendue par `xmllint`, et la conversion `lower=${url,,}` assainit l'extraction du domaine, interdisant toute évasion par la casse. 

###### Lentille : Verification Gap

- NON BLOQUANT — Location : `scripts/tests/test-html.sh` | Trigger condition : Évaluation de la couverture des nouveaux cas aux limites. | Guard snippet : N/A | Potential consequence : L'introduction des tests `case_html_schema_en_majuscules` et des multiples ressources simulées sur une même ligne élimine complètement les angles morts (Verification Gaps) des précédentes itérations.

###### Couche propre au projet

- NON BLOQUANT — L'ensemble des critères d'acceptation de la story est satisfait avec une grande rigueur, sans jamais vider de sa substance l'intention d'origine (NFR-3).
- NON BLOQUANT — Le contrôle garantit qu'aucune donnée privée, aucun secret et aucun nom d'hôte confidentiel n'a été commité. L'hôte est déduit dynamiquement et de façon sécurisée via le fichier de configuration.
- NON BLOQUANT — La concordance entre skill, procédure et script est totale. L'ajout de l'outil `libxml2-utils` (pour `xmllint`) est dûment documenté dans la procédure de montage du poste de développement.
- NON BLOQUANT — La solution technique épouse parfaitement les décisions d'architecture d'AGENTS.md, préférant l'analyse statique par commandes shell natives (`xmllint`, `jq`) aux lourdes dépendances.
- NON BLOQUANT — Le script est robuste sous `set -euo pipefail`. Toutes les commandes légitimement faillibles (`grep`, `xpath`) sont soigneusement sécurisées par `|| true`, et les retours vides anticipés via des assignations bash par défaut (`${nombre:-0}`), évitant tout crash silencieux.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la cinquième revue de la PR n° 43 (`1340bfa`, verdict `pass`) : aucun constat.

**Pour la rétrospective de l'epic 3** : cinq passes, quatre bloquantes, et cette fois **chaque blocage a trouvé un vrai contournement** du contrôle — `srcset` à plusieurs URL, `rel` combiné, casse du CSS, casse du schéma. Ce n'est pas le même schéma que la story 3.7, où les passes revenaient sur une règle transverse oubliée : ici, la revue adverse a fait exactement son travail sur un garde-fou, et le contrôle livré est très supérieur à sa première version. À noter tout de même : trois prémisses sur neuf étaient fausses (concaténation des attributs, compte vide, plantage annoncé), toutes rejouées avant correction.

## Reporté
