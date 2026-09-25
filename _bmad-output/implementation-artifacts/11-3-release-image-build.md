# Story 11.3 : Release image build

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.3.

Troisième story de l'epic 11, dont l'en-tête (point 21) veut la chaîne de mise en ligne
**construite et répétée tôt**, avant le contenu du socle : cette story produit l'image d'une mise en
ligne, avec les vraies valeurs légales et la liste des motifs passées en secret, sans qu'aucune
valeur n'entre dans le dépôt, dans l'image ou dans un journal.

## La contradiction à trancher avant tout le reste

La spec de la story nomme **`scripts/release/build-image.sh <tag>`**. Trois sources plus récentes
disent l'inverse, et elles concordent :

- `ARCHITECTURE-SPINE.md:293` : « **Une seule commande de build dans le dépôt**, `scripts/build-image.sh`
  (décidé le 21/09/2026, story 4.1) : elle porte le secret BuildKit et les arguments, et **l'epic 11
  l'appelle avec `--release` au lieu d'écrire un second script**. » ;
- `scripts/build-image.sh:2` : « une seule commande de build dans le dépôt, donc une seule à
  maintenir : **l'epic 11 appellera ce script avec `--release`** plutôt que d'en écrire un second
  (décidé par Arnaud le 21/09/2026) » ;
- le script **existe** et accepte déjà `--release`, `--tag` et `--secret`, avec ses tests
  (`scripts/tests/test-build-image.sh`).

La spec de la story 11.3 a été écrite le 13/09/2026 ; la décision d'Arnaud date du 21/09/2026 et lui
est postérieure. **Décision : la story appelle `scripts/build-image.sh --release`, et n'écrit pas de
second `docker build`.** Ce qui reste à écrire est ce que la spec demande en propre et qui n'existe
pas encore : la validation du tag, l'écriture des fichiers temporaires de secrets, l'appel de C21 et
de C22 avec la liste des motifs, et la suppression des temporaires même en cas d'échec.

> Cette décision a été **corrigée en cours de story**, et sa formulation d'origine — « n'écrit pas de
> second script » — était fausse : voir « Correction de mon propre triage (point 12) » plus bas.
> `scripts/release/build-image.sh` existe bien, mais il ne construit rien.

Les deux phrases au futur citées ci-dessus deviennent vraies dans cette PR : elles passent au
présent (point 8).

## Revue de spec

### 25/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `6ffbfde`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 99b705c0b4e335a935632493

##### Revue de la spec (Story 11.3)

###### Lentille : Adversarial (Critique adverse)

**Constat 1**
* **Emplacement :** Ligne 18
* **Condition déclenchante :** La spec demande de lancer `scripts/release/build-image.sh <tag>`.
* **Correction attendue :** Corriger la spec pour exiger l'appel du script unique existant avec ses paramètres : `scripts/build-image.sh --release --tag <tag>`.
* **Conséquence potentielle :** Le développeur risque de recréer un script dédié au lieu de réutiliser le script global existant, introduisant une duplication qui contredit l'architecture (AD-24).
* **Classement :** BLOQUANT

**Constat 2**
* **Emplacement :** Ligne 19
* **Condition déclenchante :** La spec exige que le script "lance C21 et C22 avec la liste des motifs".
* **Correction attendue :** Supprimer cette mention. Ces contrôles sont déjà exécutés automatiquement par le `Dockerfile` lors du build (via `check.sh --release`). Le script d'appel n'a pas à les lancer manuellement.
* **Conséquence potentielle :** Les contrôles seraient exécutés deux fois ou lancés en dehors du processus conteneurisé, ce qui brise l'isolation du build et fausse les vérifications.
* **Classement :** BLOQUANT

**Constat 3**
* **Emplacement :** Ligne 19
* **Condition déclenchante :** La spec omet de passer la liste des motifs (`PRIVATE_PATTERNS`) au conteneur Docker, alors que C22, qui tourne pendant le build, l'exige.
* **Correction attendue :** Ajouter à la spec un argument de secret Docker pour transmettre le fichier temporaire des motifs (par exemple `--secret id=private_patterns,src=<fichier_motifs>`) afin que C22 puisse le lire.
* **Conséquence potentielle :** Le contrôle C22 échouera systématiquement à l'intérieur du conteneur avec un code 2 (anomalie, liste introuvable), bloquant systématiquement le build de l'image.
* **Classement :** BLOQUANT

**Constat 4**
* **Emplacement :** Ligne 19
* **Condition déclenchante :** La méthode d'injection de la variable `CHECK_LEVEL=release` vers Docker n'est pas précisée.
* **Correction attendue :** Rendre explicite le fait que la variable doit être passée au conteneur (ex: `--build-arg CHECK_LEVEL=release` ou équivalent).
* **Conséquence potentielle :** La variable risque d'être définie uniquement dans l'environnement du script shell hôte et d'être ignorée par le processus Docker, désactivant ainsi de façon silencieuse les contrôles de release dans le conteneur.
* **Classement :** BLOQUANT

###### Lentille : Structure (Cas particuliers et vérifications)

**Constat 5**
* **Emplacement :** Ligne 19
* **Condition déclenchante :** La gestion de la suppression des fichiers temporaires ("écrit des fichiers temporaires ... puis supprime") manque de rigueur procédurale.
* **Correction attendue :** Exiger formellement l'utilisation du mécanisme "tableau + `trap ... EXIT`" pour éviter l'usage d'une variable chemin comme booléen, conformément aux leçons de la rétrospective (constat B1 de l'epic 7).
* **Conséquence potentielle :** Un crash inattendu du script laisserait des secrets sur le disque si le `trap` n'est pas implémenté de manière robuste.
* **Classement :** BLOQUANT

**Constat 6**
* **Emplacement :** Globale
* **Condition déclenchante :** La spec omet l'instruction de mettre à jour le changelog et de rédiger une note de déploiement (s'il y a de nouvelles manipulations manuelles de secrets liées à l'image).
* **Correction attendue :** Exiger un critère d'acceptation dédié pour l'ajout systématique d'une entrée dans `docs/CHANGELOG.md` et dans `docs/deployment-notes/`.
* **Conséquence potentielle :** Violation silencieuse d'une règle absolue de l'utilisateur global, imposant cette formalité à *chaque* nouveau développement.
* **Classement :** BLOQUANT

###### Lentille : Prose (Clarté et Édition)

**Constat 7**
* **Emplacement :** Ligne 25
* **Condition déclenchante :** L'expression "Étant donné deux constructions avec une valeur légale modifiée entre les deux" est grammaticalement ambiguë.
* **Correction attendue :** Privilégier une formulation séquentielle : "Étant donné qu'une valeur légale est modifiée entre deux exécutions consécutives du build".
* **Conséquence potentielle :** La tournure actuelle pourrait laisser croire à une obligation de lancer deux builds parallèles plutôt que séquentiels.
* **Classement :** NON BLOQUANT

##### À trancher avant d'implémenter

- **Transmission de la liste des motifs (PRIVATE_PATTERNS) :** Pour que C22 lise la liste des motifs pendant le build, le `Dockerfile` doit-il être modifié pour monter ce second fichier temporaire via un nouveau point `--mount=type=secret,id=private_patterns`, ou ce mécanisme existe-t-il déjà ?
- **Injection de `CHECK_LEVEL` :** Le `Dockerfile` est-il configuré pour recevoir `CHECK_LEVEL=release` via une directive `ARG`, ou faut-il adapter l'appel avec un paramètre spécifique pour que `scripts/check.sh` s'exécute avec la bonne valeur à l'intérieur du build ?

### Triage des constats (point 20 : chacun reçoit sa décision, y compris ceux qu'on refuse)

| # | Constat | Décision |
| --- | --- | --- |
| 1 | La spec nomme `scripts/release/build-image.sh` | **Retenu**, et déjà tranché avant la revue (voir en tête de ce fichier) : la story appelle `scripts/build-image.sh --release`, décision d'Arnaud du 21/09/2026, postérieure à la spec. |
| 2 | « le script lance C21 et C22 » : ils tournent déjà dans le `Dockerfile` | **Retenu sur le fond.** Le script ne les lance pas : `check.sh --release`, dans l'instruction `RUN`, les découvre seul. Ce que la story doit faire, c'est **leur donner la liste des motifs**. La spec décrivait l'effet, le relecteur a raison sur le moyen. |
| 3 | La liste des motifs n'est pas transmise au conteneur | **Retenu, et c'est le cœur de la story.** Voir la mesure ci-dessous : sans un second secret, le build de mise en ligne échoue. |
| 4 | `CHECK_LEVEL` risque de rester sur l'hôte | **Réfuté sur preuve.** Le mécanisme existe depuis la story 4.1 : `Dockerfile:37` déclare `ARG CHECK_LEVEL=standard`, `Dockerfile:47` le passe à l'instruction `RUN`, et `scripts/build-image.sh:75` écrit `--build-arg "CHECK_LEVEL=$level"`. `scripts/tests/test-build-image.sh` vérifie déjà les deux niveaux. Rien à faire. |
| 5 | Le `trap` de nettoyage des temporaires | **Retenu.** Tableau `temporaires` + `trap … EXIT`, la variable qui porte le chemin ne sert jamais de booléen (constat B1, rétrospective de l'epic 7). Le montage est déjà écrit deux fois dans le dépôt : il est repris, pas réinventé. |
| 6 | Il manque une entrée dans `docs/CHANGELOG.md` et une note de déploiement | **Invalide.** Vérifié : `docs/CHANGELOG.md` et `docs/deployment-notes/` **n'existent pas**, et aucune règle du projet n'en demande — ni `AGENTS.md`, ni `docs/procedures/`, ni l'architecture. La règle est pourtant **réelle** : elle vit dans les mémoires globales du compte qui relit, où elle décrit un autre projet d'Arnaud dont la CI produit un changelog. C'est nommément le cas que documente le **point 20 d'AGENTS.md**, écrit après que la story 9.2 a reçu ce même constat. Il prévoyait qu'il reviendrait ; il est revenu. |
| 7 | « deux constructions avec une valeur légale modifiée entre les deux » est ambigu | **Retenu** dans la rédaction de la story et de la procédure — la vérification est **séquentielle**, deux builds l'un après l'autre. `epics.md` n'est pas réécrit : compléter un artefact de planification validé est un autre débat, déjà ouvert dans `open_questions`. |

### La mesure qui tranche le constat 3

`.dockerignore:7` exclut `docs/private/` du contexte de build — volontairement, AD-13. Or C22, livré
par la story 11.2, cherche la liste des motifs dans `PRIVATE_PATTERNS_FILE` avec repli sur
`docs/private/forbidden-patterns.txt`, et **au niveau `release` une liste absente est une anomalie
(code 2)**, décision écrite de cette story-là : « une mise en ligne ne se valide pas sur un
garde-fou qui n'a rien lu ».

Le `Dockerfile` ne monte aujourd'hui qu'un seul secret, `legal_env`. Il s'ensuit que
`scripts/build-image.sh --release` **échoue depuis la fusion de la story 11.2**, et c'est exactement
ce que cette story doit réparer : un second secret BuildKit `private_patterns`, monté sur la même
instruction `RUN`, et `PRIVATE_PATTERNS_FILE` posée dessus.

Ce n'est pas un reproche à la 11.2 : les dépendances de la 11.3 la nomment, et le chaînage a
fonctionné. C'est en revanche une illustration du point 22 — la vérification revient à
l'orchestrateur, et elle se fait sur le dépôt, pas sur le rapport.

## Revue du code

### 25/09/2026 — `08c24cc` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 118. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b8c7a68f0867ee8d1a813618

##### Revue de code BMAD

###### Lentille : Prose (Clarté et Édition)

**Constat 1**
* **Emplacement :** `docs/procedures/build-image.md`, section « Mettre en ligne : scripts/release/build-image.sh <tag> »
* **Condition déclenchante :** La phrase décrivant les refus mentionne : « un tag qui ne suit ni vX.Y.Z ni vX.Y.Z-rc.N, zéros de tête compris ; ». L'attachement de « compris » est syntaxiquement ambigu.
* **Correction attendue :** Lever l'ambiguïté en formulant par exemple : « un tag mal formé (par exemple avec des zéros de tête, ou sans préfixe "v") ; ».
* **Conséquence potentielle :** Un développeur ou un lecteur pourrait comprendre que les zéros de tête font partie du format autorisé, alors que la suite de tests démontre rigoureusement l'inverse (code 1 attendu).
* **Classement :** NON BLOQUANT

###### Lentille : Edge-case-hunter (Cas extrêmes)

*Aucune vulnérabilité ou cas limite non géré n'a été identifié.* 
Le script `scripts/release/build-image.sh` gère efficacement les arguments vides, les valeurs contenant des guillemets doubles, les chemins contenant des virgules (souvent mal interprétés par Docker BuildKit) et la résolution relative des chemins avec `cd`. Le piège `trap ... EXIT` garantit la suppression des secrets temporaires même si le build de l'image ou une vérification échoue avant.

###### Lentille : Verification-gap (Lacunes de vérification)

*Aucune lacune de vérification n'a été identifiée.*
La stratégie de tests modifiée valide précisément les régressions et les défauts soulevés par la story, notamment :
- L'utilisation exclusive de la directive `export` (et non d'un préfixe d'affectation) pour injecter les variables à toutes les commandes de la directive `RUN`.
- La vérification séquentielle et déterministe de la sortie d'erreur (`$err`) dans `test-legal-address.sh` pour s'assurer que seuls les avertissements liés à `C23` s'y trouvent, sans compter sur le texte exact de l'avertissement de bash.

##### Couche propre au projet

Les vérifications spécifiques au dépôt eleyone.fr aboutissent aux conclusions suivantes :
- **Critères d'acceptation :** Satisfaits. Le problème du double build redondant cachant l'absence de valeurs légales est résolu, et l'étape de génération (`build`) ne met plus en cache de manière indésirable.
- **Données privées / Secrets :** Validé. Aucune valeur réelle (comme la commune de résidence, le téléphone ou les jetons de la forge) n'est commitée. Les secrets transitent strictement de l'environnement ou des fichiers temporaires vers l'étape de build sans entrer dans les couches de l'image nginx finale.
- **Concordance skill / procédure / script :** Validé. Le script d'enveloppe ne reconstruit rien lui-même, déléguant au script principal conformément aux décisions du 21/09/2026 consignées dans la procédure et dans `epics.md`.
- **Cohérence architecture & AGENTS.md :** Validé. L'approche embrasse totalement les leçons des rétrospectives précédentes (règles de tests échouant sans garde, `set +x` pour éviter les fuites de secrets dans les journaux bash).
- **Gestion des erreurs (set -euo pipefail) :** Validé. Les substitutions de commandes (comme `cat "$work/arguments"`) sont testées dans des cadres où leur code de sortie est explicitement couvert par des assertions robustes et n'avale pas silencieusement les échecs.

VERDICT: NON BLOQUANT — aucune réserve

### 25/09/2026 — `d876413` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 118. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 6237b37a82b794b948520c94

##### Revue BMAD

###### Lentille : Edge-case-hunter (Cas extrêmes)

**Constat 1**
* **Emplacement :** `scripts/release/build-image.sh`, ligne 1221 (`printf '%s="%s"\n'`)
* **Condition déclenchante :** Les valeurs légales sont écrites dans un fichier temporaire. Bien qu'une valeur contenant un guillemet double ou un saut de ligne soit proprement refusée en amont, une valeur contenant un caractère spécial tel que `$` ou <code>\`</code> sera inscrite telle quelle. Si le lecteur de ce fichier (`scripts/lib/dotenv.sh`, hors diff) recourt à une méthode d'interprétation shell native (comme `source` ou `eval`), cela pourrait entraîner une expansion de variable inattendue.
* **Correction attendue / Garde :** La protection repose implicitement sur l'analyseur interne de `dotenv.sh`. Si celui-ci se limite à la lecture littérale (comme le laisse supposer l'absence de `eval` dans les standards du projet), le risque est nul.
* **Conséquence potentielle :** Risque très mineur d'expansion de variable si le chargeur est vulnérable, bien que ce scénario soit hautement improbable pour des données légales légitimes.
* **Classement :** NON BLOQUANT

###### Lentille : Verification-gap (Lacunes de vérification)

**Constat 2**
* **Emplacement :** `scripts/tests/test-build-image.sh`, ligne 1403 (`case_dockerfile_aucune_affectation_hors_export`)
* **Condition déclenchante :** Le test valide rigoureusement l'obligation de la directive `export` en découpant la ligne et en vérifiant les assignations. Théoriquement, si les déclarations étaient séparées par un `;` plutôt que par `&&`, la portée des assertions de ce cas pourrait s'en trouver contournée.
* **Correction attendue / Garde :** Ce cas limite potentiel est parfaitement couvert par un autre test existant, `case_dockerfile_trois_etapes`, qui interdit explicitement la présence du caractère `;` dans l'instruction `RUN`. Le maillage croisé des tests protège de cette lacune.
* **Conséquence potentielle :** Le périmètre de vérification est hermétique grâce à la combinaison des deux cas de test.
* **Classement :** NON BLOQUANT

##### Couche propre au projet

**Constat 3**
* **Emplacement :** Critères d'acceptation et vérification d'intention (Global)
* **Condition déclenchante :** La refonte de la stratégie de cache Docker (usage de `--no-cache-filter build,runtime` pour garantir le rafraîchissement des variables légales) répond sans détour au problème d'anciennes pages servies tout en contournant intelligemment le cache. L'intention fonctionnelle n'a pas été compromise par une application littérale aveugle des critères.
* **Correction attendue :** Aucune. Le travail valide et justifie cette implémentation.
* **Conséquence potentielle :** Succès des objectifs de la story 11.3 sans régression.
* **Classement :** NON BLOQUANT

**Constat 4**
* **Emplacement :** Garde-fou privacité, secrets, adresses (Scripts et variables)
* **Condition déclenchante :** La manipulation des secrets de BuildKit et des variables environnementales est hautement sécurisée (fichiers temporaires `mktemp` isolés, nettoyés inconditionnellement par `trap ... EXIT`). Le script bloque la verbosité shell via `set +x` avant tout traitement de données réelles, empêchant ainsi la fuite de secrets dans les journaux d'exécution de la CI. Aucune valeur `VALEUR-FACTICE` ni aucun secret n'est commité ou divulgué.
* **Correction attendue :** Aucune. La procédure déployée est irréprochable.
* **Conséquence potentielle :** Maintien d'une sécurité totale sur les données privées et de la séparation public/privé.
* **Classement :** NON BLOQUANT

**Constat 5**
* **Emplacement :** Concordance script / procédure / architecture
* **Condition déclenchante :** Le parti pris technique implémenté, consistant à faire de `scripts/release/build-image.sh` une stricte enveloppe de validation déléguant l'exécution réelle à `scripts/build-image.sh --release`, est fidèle aux décisions d'architecture d'eleyone.fr. Les procédures listées reflètent rigoureusement ce fonctionnement, documentant même l'ajout des arguments liés à la liste de motifs.
* **Correction attendue :** Aucune.
* **Conséquence potentielle :** Documentation entièrement synchronisée avec la base de code existante.
* **Classement :** NON BLOQUANT

**Constat 6**
* **Emplacement :** Robustesse d'exécution et gestion silencieuse des erreurs (`set -euo pipefail`)
* **Condition déclenchante :** L'usage des commandes est défensif. L'exécution de `grep` (via `shell_grep_into`) ainsi que la délégation terminale (qui utilise un `code=$?` et une évaluation conditionnelle de sortie `((code == 0)) || exit "$code"`) s'assurent qu'aucune erreur ne peut échapper en silence à la condition de sortie stricte imposée par `pipefail`.
* **Correction attendue :** Aucune. 
* **Conséquence potentielle :** Aucun crash déguisé ni état incohérent ne peut aboutir à la création d'une fausse image de mise en ligne.
* **Classement :** NON BLOQUANT

VERDICT: NON BLOQUANT — aucune réserve

## Décisions

Les décisions prises **avant** d'écrire le code sont plus haut (triage de la revue de spec, sa
correction, l'exigence de C21 au niveau release). Celles que l'implémentation a imposées sont en bas,
sous « Ce que l'implémentation a imposé ».

## Ce qui a été livré

| Fichier | Ce qui change |
| --- | --- |
| `scripts/release/build-image.sh` | **nouveau.** L'enveloppe de mise en ligne : valide le tag, relève les `HUGO_LEGAL_*` et `PRIVATE_PATTERNS` de l'environnement, écrit deux fichiers temporaires de secrets, délègue à `scripts/build-image.sh --release`, nettoie même en cas d'échec. |
| `Dockerfile` | D1 : `export` au lieu de préfixes d'affectation. D2 : plus de `scripts/build.sh` avant `check.sh`. D3 : second secret `private_patterns` et `PRIVATE_PATTERNS_FILE`. |
| `scripts/build-image.sh` | option `--patterns`, passage du second secret, `--no-cache-filter build,runtime`, gardes reprises une à une pour le nouveau chemin. |
| `scripts/checks/pdf.sh` | C21 : au niveau `release`, la liste des motifs est exigée ; son absence, ou une liste sans motif, est une anomalie. |
| `scripts/checks/legal-address.sh` | C23 : `tr -d '\0'` au lieu de `cat` — un quatrième défaut de la même classe, trouvé par le build réel (voir plus bas). |
| `scripts/tests/test-release-build-image.sh` | **nouveau**, 19 cas. |
| `scripts/tests/test-build-image.sh` | 11 cas de plus, dont celui qui refuse une affectation hors d'un `export`. |
| `scripts/tests/test-pdf.sh` | 5 cas de plus, sur le niveau `release`. |
| `scripts/tests/test-legal-address.sh` | 1 cas de plus, sur l'octet nul. |
| `docs/procedures/build-image.md` | l'enveloppe, la liste des motifs, le cache, trois pièges de plus ; les deux phrases au futur passent au présent. |

## Point 19 — le brief des jumeaux, garde par garde

L'aîné pour la **mécanique des secrets temporaires** est `scripts/checks/pdf.sh`, repris par
`scripts/checks/output-patterns.sh`. L'aîné pour la **validation d'arguments et l'appel à Docker**
est `scripts/build-image.sh`. Les deux ont été ouverts et parcourus garde par garde.

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 1 | Tableau `temporaires` + `trap … EXIT`, la variable du chemin ne servant jamais de booléen | **Oui, et plus qu'eux.** Les temporaires de C21 portent une liste de motifs ; ceux-ci portent les **vraies valeurs légales**, sur le disque d'un runner. Le tableau est repris tel quel, et deux cas vérifient qu'il ne reste rien après un succès **et** après un échec. |
| 2 | `mktemp` dont l'échec est testé, chaque fichier ajouté au tableau **juste après** sa création | **Oui, tel quel.** Ajouté avant remplissage, sans quoi un échec d'écriture laisserait le fichier. |
| 3 | Deux commandes séparées avec leur propre test plutôt que `a && b \|\| die` | **Oui.** Deux `mktemp`, deux `printf` de remplissage, chacun avec son arrêt. |
| 4 | Les valeurs ne sont jamais affichées ; un message nomme la variable | **Oui, et c'est le cœur.** Deux cas l'éprouvent : aucun marqueur sur la sortie standard ni d'erreur, y compris en échec, et aucun sous `bash -x` grâce au `set +x` d'en-tête (modèle de `scripts/env.sh`). |
| 5 | `local x=$(…)` rend le code de `local` : déclarer puis affecter | **Sans objet ici**, et la règle est respectée par construction : l'enveloppe n'a aucune fonction locale qui capture une substitution. Les affectations de haut niveau (`legal=$(mktemp)`) rendent bien le code de la substitution. |
| 6 | Le chemin d'un secret ne doit pas contenir de virgule (`--secret id=…,src=…`) | **Oui, et deux fois** (point 18 : balayer la classe, pas la ligne). Dans `scripts/build-image.sh` pour la nouvelle option `--patterns` ; dans l'enveloppe pour les chemins issus de `TMPDIR`, que l'utilisateur n'a pas écrits et qu'un message doit donc nommer autrement. |
| 7 | Le dossier d'appel est retenu avant le `cd` à la racine | **Non, sans objet.** L'enveloppe ne prend aucun chemin en argument : un tag, et des variables d'environnement. Rien à résoudre depuis le dossier d'appel. La garde est en revanche **reprise dans `scripts/build-image.sh`** pour `--patterns`, qui en prend un. |
| 8 | Un fichier de travail du dépôt (`.env`, le placeholder) est refusé comme secret de mise en ligne | **Oui, transposée.** L'enveloppe ne reçoit pas de fichier : elle en écrit un depuis l'environnement. La même faute y prend la forme d'une **valeur** factice plutôt que d'un fichier, et elle est refusée par le même raisonnement — C15 la rattraperait dans la sortie, mais cinq minutes de build plus tard, et une répétition générale serait signée de valeurs factices. |
| 9 | `exec docker build` en dernier, sans rien après | **Non — et c'est l'inverse qu'il faut.** `exec` remplace le processus : le piège `EXIT` ne tournerait jamais et les deux temporaires resteraient sur le disque. Le build tourne en enfant, son code est retenu, le nettoyage a lieu. `case_release_build_image_les_temporaires_disparaissent_apres_un_echec` échoue si quelqu'un réintroduit le `exec` — vérifié par mutation (M11). |

Deux gardes de l'aîné **manquaient au cadet et ont été écrites** en le parcourant :

- **la lisibilité du fichier de noms** : `ci/legal-placeholder.env` est lu pour obtenir les huit noms
  d'AD-9 plutôt que de les recopier une quatrième fois (`scripts/env.sh`, `scripts/checks/content.sh`
  les portent déjà, et C18 vérifie que le placeholder porte exactement ceux-là). Son absence est une
  anomalie ;
- **le fichier présent mais vide** (piège connu, story 0.8) : `PRIVATE_PATTERNS` qui ne porte que des
  lignes vides et des commentaires est refusée, comme C22 refuse une liste sans motif.

`scripts/tests/test-release-build-image.sh` est lui aussi écrit « comme » son aîné
`scripts/tests/test-build-image.sh` ; son en-tête nomme les trois gardes de cas qu'il en reprend et
la quatrième qui n'a pas d'objet.

## Ce que l'implémentation a imposé

### Un quatrième défaut, de la même classe : `--no-cache-filter build` ne suffit pas

Le critère d'acceptation nomme `--no-cache-filter build`. **Mesuré, il ne tient pas sa promesse**, et
la promesse est justement le troisième scénario du même critère — « deux constructions avec une
valeur légale modifiée entre les deux, la seconde image affiche la nouvelle valeur ».

Trois constructions successives, avec trois valeurs de `HUGO_LEGAL_PUBLISHER_NAME` différentes, ont
toutes exporté le **même manifeste**, `sha256:4e9d3d2ddea2c05b8abb68513a740c633e50b65ccbf28cee98eaf585dda89dc1`,
et la page servie portait la valeur de la première. L'instruction `RUN` se rejouait pourtant —
`docker build --target build` sur la même commande produit bien la nouvelle valeur — mais le
`COPY --from=build /src/public/` de l'étape `runtime` était servi depuis le cache.

Avec `--no-cache-filter build,runtime`, la même construction exporte un manifeste différent et la
page porte la bonne valeur. L'étape `tools`, la longue, garde son cache dans les deux cas.

**Décision : le script passe `--no-cache-filter build,runtime`.** C'est un écart à la lettre du
critère, et la seule lecture qui rende vrai son troisième scénario. Docker 29.8.1, buildx 0.37.1,
25/09/2026 ; c'est le point 10 d'`AGENTS.md` — une règle qui décrit le comportement d'un outil n'est
vraie qu'une fois lancée.

### C23 écrivait quatre avertissements de bash au milieu des contrôles

Le premier build de mise en ligne réussi a montré ceci, entre `images` et `legal-address` :

```
/src/scripts/checks/legal-address.sh: line 180: warning: command substitution: ignored null byte in input
```

— quatre fois. C'est le point 19 dans l'autre sens : **C22 avait appris et écrit la parade**
(`tr -d '\0'` plutôt qu'un `cat`, « une substitution de commande avale les octets nuls en écrivant un
avertissement sur la sortie d'erreur, qu'un lecteur prendrait pour un signalement ») et C23, son
aîné, ne l'avait jamais reprise. Le défaut n'était visible que depuis ce build : le `file` de
`CHECK_IMAGE` ne classe pas binaires les mêmes fichiers que celui du poste, et jusqu'à cette story
`check.sh` tournait dans l'image **sans valeurs légales**, si bien que C23 cherchait une chaîne vide.

Corrigé, avec son cas de test. Le contenu confronté est le même : la substitution retirait déjà ces
octets, en le disant tout haut.

**Et le cas de test a d'abord été faux** : il cherchait la chaîne `null byte`, que bash traduit — le
poste écrit « octet nul ignoré ». La mutation restait verte. L'assertion porte maintenant sur
l'invariant, pas sur le texte de l'avertissement : **toute ligne écrite sur la sortie d'erreur est un
signalement de C23**, et rien d'autre.

### Deux gardes qui refusaient la même entrée, donc une seule éprouvée

Une première écriture de `scripts/build-image.sh` faisait refuser par la **même ligne** une liste
désignée introuvable et une mise en ligne sans liste. Les deux cas de test passaient ; la mutation de
la seconde garde restait **verte**. Les deux régimes ont donc été séparés, et c'est l'**option** qui
les sépare, pas la variable :

- `--patterns <fichier>` est un acte explicite : le fichier doit être là, à tout niveau ;
- `PRIVATE_PATTERNS_FILE` et le défaut sont une configuration ambiante : absents, un build ordinaire
  continue sans second secret et le script le dit ; au niveau `release`, l'absence est un refus.

Même histoire dans l'enveloppe entre « `PRIVATE_PATTERNS` absente » et « `PRIVATE_PATTERNS` sans
motif » : les deux messages nomment la variable, et une assertion sur le seul nom laissait la
première garde sans test. Les cas affirment maintenant le message **distinctif** de chacune.

## Le test de D1, et pourquoi cette forme

La garde de D1 est une propriété du **`Dockerfile`**, pas d'un script. Le cas
`case_dockerfile_aucune_affectation_hors_export` le lit donc, plutôt que de construire une image
d'essai. Deux raisons, et la seconde décide :

1. la suite est hors ligne et ne lance jamais Docker (story 0.9, en-tête de `test-build-image.sh`) ;
2. surtout, **un build réel ne prouverait la portée des variables que pour la forme écrite ce
   jour-là**, alors que la règle porte sur toutes les formes qu'une réécriture peut prendre. C'est
   une propriété du texte ; c'est le texte qu'on éprouve.

La règle : dans l'instruction `RUN` repliée en une ligne logique, aucun jeton `NOM=valeur` ne peut
apparaître ailleurs qu'en argument d'un `export`. Un `export` porte pour tout le reste du shell ; un
préfixe, pour une seule commande. Le découpage emploie `read -ra`, qui ne développe pas les jokers —
un `for jeton in $une_ligne` nu aurait fait passer `a+rX` au filtre de bash.

**Joué sans le correctif** : le `Dockerfile` remis dans sa forme d'avant (préfixes d'affectation
*et* double build), la suite rougit.

```
$ bash scripts/tests/run.sh scripts/tests/test-build-image.sh
tests: ÉCHEC scripts/tests/test-build-image.sh : dockerfile_aucune_affectation_hors_export (code 1)
  affectation « ENV_MODE=… » hors d'un export : elle ne vaudrait que pour la commande qui suit,
  et les autres commandes de l'instruction RUN ne la verraient pas (story 11.3).

$ bash scripts/tests/test-build-image.sh dockerfile_un_seul_build
l'instruction RUN appelle scripts/build.sh : ce build est écrasé par celui de check.sh
```

## Point 9 — chaque garde a été retirée, et la suite rejouée

Vingt et une mutations, une par garde livrée. Chacune remet le fichier en place après la suite.
**Les 21 sont rouges**, et trois ne l'étaient pas à la première tentative (M3, M5, M18) : c'est ce
qui a imposé la séparation des gardes décrite plus haut.

| # | Garde retirée | Cas qui rougit |
| --- | --- | --- |
| M1 | `build-image` : `--no-cache-filter` | `build_image_commande` |
| M2 | `build-image` : montage du second secret | `build_image_commande` |
| M3 | `build-image` : refus d'une liste nommée par `--patterns` et absente | `build_image_patterns_option_mais_absente` |
| M4 | `build-image` : virgule dans le chemin des motifs | `build_image_patterns_avec_virgule` |
| M5 | `build-image` : refus `release` sans liste | `build_image_release_sans_liste` |
| M6 | `Dockerfile` : `export` → préfixes d'affectation | `dockerfile_aucune_affectation_hors_export` |
| M7 | `Dockerfile` : retour du double build | `dockerfile_trois_etapes` |
| M8 | `Dockerfile` : second secret | `dockerfile_second_secret_des_motifs` |
| M9 | C21 : exigence de la liste au niveau `release` | `pdf_release_exige_la_liste` |
| M10 | enveloppe : `trap` de nettoyage | `release_build_image_les_temporaires_disparaissent` |
| M11 | enveloppe : `exec` au lieu d'un enfant | `release_build_image_les_temporaires_disparaissent` |
| M12 | enveloppe : validation du tag | `release_build_image_tags_refuses` |
| M13 | enveloppe : variables légales manquantes | `release_build_image_toutes_les_absences_dun_coup` |
| M14 | enveloppe : guillemets autour des valeurs écrites | `release_build_image_le_fichier_legal_se_relit_a_lidentique` |
| M15 | enveloppe : refus d'une valeur factice | `release_build_image_valeur_factice` |
| M16 | enveloppe : refus d'un guillemet dans une valeur | `release_build_image_valeur_avec_guillemet` |
| M17 | enveloppe : liste de motifs sans aucun motif | `release_build_image_liste_sans_aucun_motif` |
| M18 | enveloppe : `PRIVATE_PATTERNS` absente | `release_build_image_sans_liste_de_motifs` |
| M19 | enveloppe : virgule dans `TMPDIR` | `release_build_image_tmpdir_avec_virgule` |
| M20 | enveloppe : `set +x` | `release_build_image_aucune_trace_de_shell` |
| M21 | C23 : `tr -d '\0'` | `legal_un_octet_nul_nest_ni_bruyant_ni_aveuglant` |

## Les essais, et leurs sorties exactes

### La suite et les deux niveaux de contrôle, sur le poste

```
$ bash scripts/tests/run.sh
tests: 665 cas réussis.

$ scripts/check.sh
check: 11 contrôle(s) passés, niveau standard.

$ scripts/check.sh --release
check: 11 contrôle(s) passés, niveau release.
```

### Ce qui échoue avant le `docker build`

Valeurs d'essai : `sed 's/VALEUR-FACTICE/valeur-essai/g' ci/legal-placeholder.env`, posées dans
l'environnement ; motifs **factices** (`MOTIF-DESSAI-INTROUVABLE`, `AUTRE-MOTIF-DESSAI`), jamais la
vraie liste.

```
$ scripts/release/build-image.sh 1.2.3
release/build-image: tag « 1.2.3 » refusé : une mise en ligne porte « vX.Y.Z », une répétition « vX.Y.Z-rc.N » (AD-14). Aucun build n'a été lancé.   → code 1

$ scripts/release/build-image.sh v1.2.3-beta.1      → code 1, même message
$ scripts/release/build-image.sh v01.2.3            → code 1, même message
$ scripts/release/build-image.sh v1.2.3-rc          → code 1, même message

$ env -u HUGO_LEGAL_HOST_EMAIL scripts/release/build-image.sh v0.0.1-rc.1
release/build-image: valeur(s) légale(s) absente(s) de l'environnement : HUGO_LEGAL_HOST_EMAIL (AD-9). Aucun docker build n'a été lancé.   → code 1

$ env -u PRIVATE_PATTERNS scripts/release/build-image.sh v0.0.1-rc.1
release/build-image: PRIVATE_PATTERNS absente de l'environnement : sans la liste des motifs, C21 ne confronte rien et C22 rend une anomalie (AD-12, AD-21). Aucun docker build n'a été lancé.   → code 1
```

### Le build de mise en ligne, qui réussit

```
$ scripts/release/build-image.sh v0.0.1-rc.1
release/build-image: mise en ligne v0.0.1-rc.1, image eleyone-site:v0.0.1-rc.1.
build-image: image eleyone-site:v0.0.1-rc.1, contrôles au niveau release, outils de alpine@sha256:28bd5fe…
#18 0.889 budget: poids et nombre d'éléments dans les budgets d'AD-8.
#18 0.968 content: rubriques, marqueurs [TODO, vocabulaire, matériel vivant, groupes, encarts, format et parcours vérifiés.
#18 3.828 html: zéro script, aucune ressource tierce, aucun marqueur, structure accessible.
#18 3.881 images: aucune métadonnée, dimensions et poids des images conformes à AD-19.
#18 4.006 legal-address: l adresse de l éditeur ne sort pas du corps des deux pages des mentions légales.
#18 4.434 links: liens internes, ancres, pages atteignables et liens conditionnels vérifiés.
#18 4.595 output-patterns: 23 fichier(s) de public confrontés à la liste des motifs ; aucune occurrence hors des valeurs légales injectées des mentions légales.
#18 4.618 parity: parité FR/EN vérifiée.
#18 4.701 pdf: les 2 CV PDF ont leur en-tête, leurs pages, leur poids, et aucun motif privé.
#18 4.762 release-pages: pages et sections attendues présentes en FR et en EN, aucune page de groupe vide, aucune trace de travail.
#18 5.300 typo: typographie française posée sur les pages FR, absente des pages EN, aucune césure automatique.
#18 5.300 check: 11 contrôle(s) passés, niveau release.
#21 exporting manifest sha256:ed830a8b711ec2297ae8ed6406b06f3a61c81d77ad5a79033e6246cc27827507 done
#21 naming to docker.io/library/eleyone-site:v0.0.1-rc.1 done
release/build-image: image eleyone-site:v0.0.1-rc.1 construite, contrôles de mise en ligne passés.
→ code 0 ; restes dans TMPDIR : 0
```

Les trois lignes qui manquent par rapport à la mesure d'avant la story sont celles qui la
justifiaient : plus de `liste des motifs introuvable`, plus de `C15 : trace de travail
« VALEUR-FACTICE »` sur les deux pages légales, plus de `contenu non confronté` pour les PDF. Et les
quatre avertissements d'octet nul de C23 ont disparu avec sa correction.

### Ce que l'image emporte

```
$ docker run --rm --entrypoint grep eleyone-site:v0.0.1-rc.1 -rl VALEUR-FACTICE /usr/share/nginx/html
→ code 1 (rien trouvé)

$ docker run --rm --entrypoint grep eleyone-site:v0.0.1-rc.1 -c valeur-essai-editeur-nom \
    /usr/share/nginx/html/mentions-legales/index.html /usr/share/nginx/html/en/legal-notice/index.html
/usr/share/nginx/html/mentions-legales/index.html:1
/usr/share/nginx/html/en/legal-notice/index.html:1

$ docker history --no-trunc eleyone-site:v0.0.1-rc.1 | grep -c -E "HUGO_LEGAL|valeur-essai|MOTIF-DESSAI|legal_env|private_patterns"
0

$ diff <(cd public && find . -type f | sort) \
       <(docker run --rm --entrypoint find eleyone-site:v0.0.1-rc.1 /usr/share/nginx/html -type f | sed 's|/usr/share/nginx/html|.|' | sort)
→ identique
```

`docker history` ne montre que les couches de l'étape `runtime` : les deux `COPY`, le `RUN rm -rf`,
et l'image nginx. L'instruction qui monte les secrets appartient à l'étape `build`, qui ne survit pas.

### Les deux constructions avec une valeur modifiée

```
build 1 (HUGO_LEGAL_PUBLISHER_NAME=EDITEUR-PREMIER-BUILD) : la page sert EDITEUR-PREMIER-BUILD
build 2 (HUGO_LEGAL_PUBLISHER_NAME=EDITEUR-SECOND-BUILD)  : la page sert EDITEUR-SECOND-BUILD
restes dans TMPDIR : 0
```

Avec `--no-cache-filter build` seule, le **même** essai servait `EDITEUR-PREMIER-BUILD` les deux
fois. C'est la mesure qui a imposé `build,runtime`.

## Ce que la mesure a trouvé, et qui dépasse la revue

Le build de mise en ligne a été **lancé** avant d'écrire une ligne de code
(`scripts/build-image.sh --release --tag eleyone-site:essai-11-3 --secret <fichier d'essai>`, où le
fichier d'essai porte les huit variables d'AD-9 sans le mot `VALEUR-FACTICE`). Il échoue, et il
échoue **deux fois** :

```
output-patterns: liste des motifs introuvable (/src/docs/private/forbidden-patterns.txt) : au
  niveau « release », une mise en ligne ne se valide pas sur un garde-fou qui n'a rien lu.
mentions-legales/index.html: C15 : trace de travail « VALEUR-FACTICE » trouvée dans la page
en/legal-notice/index.html: C15 : trace de travail « VALEUR-FACTICE » trouvée dans la page
pdf: … liste des motifs absente, contenu non confronté.
check: 2 contrôle(s) en échec sur 11 : output-patterns (code 2) release-pages
```

Le premier échec est le constat 3, attendu. **Le second ne l'était pas, et c'est le vrai sujet.**

### Le `Dockerfile` ne passe ses variables qu'à la première commande

`Dockerfile:43-50` écrit une instruction unique :

```
RUN --mount=type=secret,id=legal_env,required=true \
    ENV_MODE=release LEGAL_ENV_FILE=/run/secrets/legal_env … \
    ./scripts/build.sh production \
    && if [ "${CHECK_LEVEL}" = release ]; then ./scripts/check.sh --release; else ./scripts/check.sh; fi \
    && chmod -R a+rX public
```

En shell, les affectations qui **préfixent** une commande ne valent que pour elle. Vérifié :

```
$ sh -c 'FOO=release /bin/true && if [ "${FOO:-VIDE}" = release ]; then echo vu; else echo "PAS vu : [${FOO:-VIDE}]"; fi'
PAS vu : [VIDE]
```

`check.sh` ne voit donc **ni `ENV_MODE`, ni `LEGAL_ENV_FILE`**. Le `if` fonctionne, lui, parce que
`${CHECK_LEVEL}` y est interpolé par Docker avant que le shell ne le lise — c'est ce qui a masqué le
défaut : le niveau `release` arrive bien, les valeurs légales non.

Et `scripts/check.sh:46-47` **reconstruit les deux rendus** avant de contrôler. Conséquence, en
trois temps :

1. `build.sh production` construit `public/` avec les **vraies** valeurs, par le secret ;
2. `check.sh` le **reconstruit par-dessus**, sans `ENV_MODE` ni `LEGAL_ENV_FILE`, donc en mode local
   sans `.env` (exclu du contexte) : le chargeur retombe sur `ci/legal-placeholder.env` ;
3. l'image emporte `COPY --from=build /src/public/`, c'est-à-dire **le second build**.

Autrement dit, **l'image de mise en ligne aurait servi des mentions légales portant
`VALEUR-FACTICE-editeur-nom`**, et le premier build ne servait à rien. Le défaut existe depuis la
story 4.1 ; rien ne pouvait le voir, puisque aucun contrôle ne cherchait ces chaînes dans `public/`
avant C15 — livré la veille, par la story 11.1.

### Ce que cela dit de C23

Pire que l'image : dans ce second build, `check.sh` lance aussi **C23**, dont tout le travail est de
chercher la **valeur** de l'adresse de l'éditeur dans la sortie. Avec l'environnement factice, il
cherchait `VALEUR-FACTICE-editeur-adresse` dans des pages qui, au premier build, portaient la vraie
adresse. Il ne pouvait rien trouver. C23 a donc été **vert par construction** dans tout build
d'image, depuis qu'il existe.

C'est le troisième garde-fou vert sur une fuite trouvé en deux stories, et le troisième trouvé en
**lançant** plutôt qu'en relisant : `&rsquo;` (11.2), le retour chariot (11.2), et celui-ci.

### Ce que la story doit donc faire

Au-delà du second secret que demandait le constat 3 :

- les variables d'environnement doivent valoir pour **toutes** les commandes de l'instruction `RUN`,
  pas seulement la première ;
- le double build doit disparaître : `check.sh` construit déjà les deux rendus, le `build.sh`
  préalable du `Dockerfile` est redondant — et c'est sa redondance qui a rendu le défaut invisible,
  puisqu'un build correct précédait le build fautif ;
- un cas de test doit **refuser** un `Dockerfile` dont l'instruction `RUN` laisse une commande hors
  de portée des variables, sans quoi la même faute reviendra à la première réécriture.

## Correction de mon propre triage (point 12)

Le triage ci-dessus tranche le constat 1 par « la story n'écrit pas de second script ». **En
relisant l'architecture en entier plutôt qu'à la ligne citée, c'est trop court.** Deux lignes
parlent de ce script, et elles ne disent pas la même chose :

- `ARCHITECTURE-SPINE.md:293` : « une seule commande de build dans le dépôt, `scripts/build-image.sh`
  … l'epic 11 l'appelle avec `--release` au lieu d'écrire un second script » ;
- `ARCHITECTURE-SPINE.md:727`, l'arborescence : « `release/` # build-image.sh, ship.sh ».

Les deux se réconcilient, et la lecture juste est celle-ci : **il n'y a qu'une commande de *build*,
et une enveloppe de *mise en ligne* au-dessus.** `scripts/release/build-image.sh` ne construit rien
lui-même — il valide le tag, relève les valeurs de l'environnement, écrit les fichiers temporaires
de secrets, délègue à `scripts/build-image.sh --release`, et nettoie même en cas d'échec. C'est
exactement la liste de ce que le critère d'acceptation lui demande, et rien de ce que
`build-image.sh` fait déjà.

Le constat 1 reste donc **retenu** — le script d'enveloppe ne redéfinit ni le `docker build`, ni le
secret légal, ni `--no-cache-filter`, ni les arguments —, mais sa formulation « n'écrit pas de
second script » était fausse : elle aurait conduit à mettre la préparation des secrets dans
`build-image.sh`, qui sert aussi aux builds ordinaires du poste et n'a rien à faire d'un tag de
mise en ligne. C'est le point 12 : la spec qu'on vient d'écrire se relit quand l'approche tourne.

## Une décision que la mesure impose : C21 doit exiger la liste au niveau `release`

Le build d'essai a aussi montré ceci :

```
pdf: les 2 CV PDF ont leur en-tête, leurs pages et leur poids ; liste des motifs absente, contenu non confronté.
```

C21 se contente de **dire** qu'il n'a pas confronté, et rend 0. C'est juste dans le cas général
(AD-21 : « quand la liste est disponible ») : sur GitHub, dans un clone sans `docs/private/`, la
liste n'existe pas et le reste des règles garde sa valeur. **Au niveau `release`, c'est un
garde-fou qui s'ouvre** : une mise en ligne validerait deux CV PDF dont ni le texte, ni les
métadonnées, ni le XMP n'auraient été confrontés — alors que ce sont précisément les fichiers où un
téléphone ou une commune se cachent sans qu'on les voie.

**Décision : au niveau `release`, C21 exige la liste, comme C22, et son absence est une anomalie.**
Hors `release`, son comportement ne change pas. C'est ce que le critère d'acceptation de cette
story demande en propre — « lance C21 **et** C22 avec la liste des motifs » — et la seule lecture
qui rende cette phrase vraie.

## Décisions de l'orchestrateur

### L'écart au critère d'acceptation : `--no-cache-filter build` seul ne tient pas sa promesse

Le critère dit « `--no-cache-filter build` ». La sous-tâche a mesuré que l'instruction `RUN` se
rejoue bien, mais que le `COPY --from=build /src/public/` de l'étape `runtime` est servi depuis le
cache : trois constructions avec trois valeurs différentes exportaient le même manifeste. Le script
passe donc `build,runtime`, et l'étape `tools` — la longue — garde son cache.

**Accepté.** La lettre du critère change, son intention est tenue : le troisième scénario dit « la
seconde image affiche la nouvelle valeur », et c'est cela qui est vérifié. Rejoué par
l'orchestrateur, deux mises en ligne complètes avec une seule valeur modifiée entre les deux :

```
v0.9.1-rc.1 : EDITEUR-ORCH-UN
v0.9.2-rc.1 : EDITEUR-ORCH-DEUX
```

Vider le cache de `runtime` ne coûte rien — cette étape ne fait que copier —, alors qu'un critère
tenu à la lettre aurait livré des images identiques en se croyant conforme.

### Le quatrième défaut, hors du périmètre nommé mais dans la même classe

La sous-tâche a corrigé `scripts/checks/legal-address.sh`, qui lisait un fichier par `cat` dans une
substitution de commande : les octets nuls y sont avalés **avec un avertissement sur la sortie
d'erreur**, qu'un lecteur prend pour un signalement. C22 avait appris la parade (`tr -d '\0'`) ;
C23, son aîné, ne l'avait jamais reprise.

**Accepté.** C'est le point 19 dans l'autre sens — la leçon ne remonte pas plus qu'elle ne descend —,
c'est ce build-ci qui l'a rendue visible, et l'entrée de `deferred-work.md` ouverte à la story 9.7
demandait exactement ce correctif. Le cas de test l'accompagne.

### Trois gardes qui n'en étaient pas

La sous-tâche rapporte que **trois mutations sur vingt et une sont restées vertes au premier essai** :
deux gardes refusaient la même entrée, donc une seule était éprouvée. Elles ont été séparées.
C'est exactement ce que le point 9 cherche à produire — la mutation ne sert pas à confirmer qu'un
test existe, mais à découvrir qu'il ne prouve rien —, et c'est la première fois qu'une story de cet
epic le rapporte franchement.

### Vérification du travail de la sous-tâche (point 22)

Rejoué par l'orchestrateur sur le dépôt, sans reprendre ses mesures :

| Vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 665 cas réussis |
| mise en ligne réelle, valeurs d'essai et motifs factices | code 0, 11 contrôles passés dans le conteneur |
| `VALEUR-FACTICE` dans l'image servie | **aucune** (le défaut D1/D2 est fermé) |
| la valeur d'essai est-elle servie ? | oui, sur les deux pages légales |
| deux mises en ligne, une valeur modifiée | chaque image sert **sa** valeur |
| `docker history --no-trunc` | 0 occurrence de valeur, de motif ou de nom de secret |
| tag mal formé (`1.2.3`, `v1.2.3-beta.1`, `v01.2.3`, `v1.2.3-rc`) | refusé, « Aucun build n'a été lancé » |
| variable légale absente | refusée en la nommant, avant tout `docker build`, sans afficher de valeur |
| fichiers temporaires après les essais | aucun ne survit |

Les images d'essai ont été supprimées du poste.

### Triage de la revue du code (`08c24cc`)

**Constat 1 — « zéros de tête compris » est syntaxiquement ambigu. RETENU et corrigé.** La phrase
pouvait se lire comme si les zéros de tête faisaient partie du format autorisé, alors que la suite
de tests exige l'inverse. Une procédure qui dit le contraire de ce que le code fait est précisément
ce que ce projet paie cher. `docs/procedures/build-image.md:37` énumère désormais les quatre formes
refusées, et l'énumération suit celle des cas de test.

Le correctif arrive **avant** le commit de statut, et la revue est relancée sur la nouvelle tête.
C'est la leçon de la story 11.2, où le statut `done` posé trop tôt avait coûté deux revues pour
retrouver une séquence légale : le commit de statut est la seule sortie, et il se pose en dernier.

**Les deux lentilles ne trouvent rien.** L'edge-case-hunter relève que les arguments vides, les
valeurs à guillemet double, les chemins à virgule et le piège `EXIT` sont couverts ; la lentille des
trous de vérification relève que les deux régressions de la story — l'`export` et la lecture
déterministe de la sortie d'erreur de C23 — ont chacune leur cas. **Les cinq lignes de la couche
projet** sont des confirmations. Rien à reporter.

### Triage de la seconde revue du code (`d876413`)

**Constat 1 — une valeur légale portant `$`, une accent grave ou `$(…)` serait-elle interprétée en
relisant le fichier temporaire ? RÉFUTÉ sur preuve.** Le relecteur posait lui-même la condition :
« si le chargeur se limite à la lecture littérale, le risque est nul ». Mesuré plutôt que supposé —
`scripts/lib/dotenv.sh` ne contient ni `eval`, ni `source`, ni `.`, et son en-tête dit pourquoi
(« un fichier dotenv n'est jamais lu par `source` ni `set -a` »). Essai avec les trois formes à la
fois :

```
$ printf 'HUGO_LEGAL_TEST="valeur $HOME et `id` et $(whoami)"\n' > <temp>
$ dotenv_read <temp> HUGO_LEGAL_
HUGO_LEGAL_TEST=valeur $HOME et `id` et $(whoami)
```

Rien n'est développé. Aucune garde à ajouter.

**Constat 2 — un `;` à la place d'un `&&` contournerait-il le test de l'`export` ? RÉFUTÉ, et le
relecteur le dit lui-même.** Vérifié : `scripts/tests/test-build-image.sh:145` refuse tout `;` hors
du `if` dans l'instruction `RUN` (`assert_eq "" "$(tr -cd ';' <<< "$reste")"`). Les deux cas se
tiennent l'un l'autre. Rien à faire.

**Constats 3, 4 et 5** sont des confirmations de la couche projet — intention des critères tenue
malgré la lettre changée sur le cache, aucune fuite de secret, concordance script/procédure/
architecture. Aucun changement demandé, rien à reporter.
