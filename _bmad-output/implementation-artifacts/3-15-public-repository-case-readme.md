# Story 3.15 : Public repository case README

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.15.

## Revue de spec

### 20/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `6a15677`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0716885c6001deb7de2b2ccb

### Revue de spec : Story 3.15 (Public repository case README)

#### 1. Lentille "Adversarial" (Chasse aux failles et contradictions)

**1. Contradiction sur l'historique et les sources privées**
- **Condition :** Le développeur doit écrire, sans utiliser de source privée, le récit de "ce qui a résisté : les sources privées repérées avant publication, la réécriture de l'historique".
- **Conséquence :** Si l'historique a été réécrit pour effacer ces fuites ou si elles ont été bloquées avant d'être poussées, l'agent IA n'en a aucune trace dans l'historique public actuel ni dans les documents de cadrage. Il lui est impossible de relater ces faits sans inventer (ce qui viole NFR-10).
- **Garde manquante :** Il faut qu'Arnaud fournisse ce récit factuel précis dans les "Prérequis de contenu".

**2. Identification de la "solution facile" absente des sources**
- **Condition :** Le README doit documenter "la solution facile et pourquoi elle a été écartée".
- **Conséquence :** Si cette réflexion technique n'est pas explicitement documentée dans les documents fournis (PRD, AD-24), l'agent devra l'inventer ou bloquer l'exécution.
- **Garde manquante :** Arnaud doit préciser quelle était cette solution facile, ou confirmer que l'agent peut la déduire de l'architecture.

**3. Liens vers des ressources non garanties ou futures**
- **Condition :** Le texte exige des liens vers `docs/measures/` et vers les branches `experiment/d2-bilingue`, `design/dossier-architecture`, `design/suisse`.
- **Conséquence :** Le dossier `docs/measures/` n'est potentiellement créé et peuplé qu'à partir de l'Epic 5 (AD-17). De plus, il n'est pas garanti que les branches de design aient été poussées sur le miroir public GitHub au moment de l'Epic 3. Les liens risquent de renvoyer des 404 pour le lecteur "Sam".
- **Garde manquante :** Valider l'existence de ces ressources sur le miroir public avant de créer les liens.

**4. Incohérence avec le format canonique d'un cas**
- **Condition :** Le README "suit la structure des cas" et liste spécifiquement : contexte, problème, solution, ce qui a résisté, résultat.
- **Conséquence :** Le format officiel (`docs/format-cas.md` et FR-5) exige obligatoirement les encarts "Contexte mission" (rôle, stack, etc.) et "En bref". La story 3.15 ne les mentionne pas. L'agent risque de produire une structure hybride qui s'écarte du format imposé aux autres cas.
- **Garde manquante :** Clarifier si le README inclut ces encarts formels ou s'il s'agit d'une adaptation libre.

**5. Flou sur l'URL des exécutions publiques**
- **Condition :** Les références doivent mener "aux exécutions publiques" (la CI).
- **Conséquence :** L'agent ne connaît pas l'URL canonique exacte des GitHub Actions du projet (le chemin des workflows). Il risque de générer un lien générique erroné.
- **Garde manquante :** Fournir le schéma ou le lien exact vers l'onglet Actions du dépôt GitHub.

**6. Mention d'un outillage (hotfix) non encore développé**
- **Condition :** Documenter le flux de branches, incluant "hotfix/* depuis main par le skill hotfix".
- **Conséquence :** À l'Epic 3, le skill `hotfix` n'existe pas encore (il est prévu à l'Epic 11). Le mentionner dans le README public à ce stade induira le lecteur en erreur s'il cherche à lire le script correspondant dans le dépôt.
- **Garde manquante :** Restreindre la documentation aux workflows et skills déjà implémentés, ou indiquer qu'il s'agit d'une prévision.

**7. Risque de traduction littérale des concepts BMAD**
- **Condition :** L'agent rédige en anglais à partir de documents de cadrage entièrement en français.
- **Conséquence :** Risque de traduction aléatoire ou littérale de termes spécifiques au projet (ex: "matériel vivant", "garde-fou", "parité").
- **Garde manquante :** Fixer un glossaire minimal pour la traduction de ces concepts, ou valider la terminologie anglaise choisie lors de la relecture du premier jet.

**8. Rôle et personne de la narration**
- **Condition :** Le README se lit comme un cas écrit pour le portfolio.
- **Conséquence :** Sans directive, l'agent peut rédiger de manière impersonnelle ("Le développeur a...") ou utiliser un "Je" qui prête à confusion. 
- **Garde manquante :** Spécifier formellement que le texte doit être écrit à la 1ère personne du singulier, du point de vue d'Arnaud.

#### 2. Lentille "Structure" (Organisation et testabilité)

- **Critères d'acceptation non testables :** Le premier scénario Gherkin ("Quand le développeur écrit le premier jet Alors il l'écrit en anglais à partir des seuls documents publics...") n'est pas un comportement observable du logiciel, mais une instruction de prompt pour l'agent IA. Cela relève de la description de la tâche et non des critères d'acceptation.
- **Cycle de validation incomplet :** Le prérequis mentionne "relecture par Arnaud [...] du premier jet", mais aucun critère ne verrouille la fusion de la Pull Request. Il manque un critère actant que la PR n'est fusionnée qu'après la validation explicite du contenu final par Arnaud.
- **Ambiguïté sur "la liste des contrôles" :** Le texte demande de lier "à scripts/check.sh et à la liste des contrôles". Selon AD-10, la liste des contrôles documentée se trouve dans l'architecture. Le lien pointant vers "la liste" peut donc être ambigu pour l'agent (doit-il pointer vers le script ou vers l'architecture ?).

#### 3. Lentille "Prose" (Clarté et phrasé)

- **Tension sur l'opération manuelle :** La story affiche "Opération manuelle (Arnaud) : non". Bien que cela soit justifié techniquement (aucune action serveur ou DNS requise), cela contraste fortement avec le prérequis "Arnaud relit la voix et les faits". L'agent IA pourrait y voir une contradiction sur son degré d'autonomie.
- **Ambiguïté sémantique "sans source privée" :** La formulation "sans source privée, puis [...] raconte les sources privées repérées" est difficile à interpréter pour un LLM. L'agent ne saura pas s'il a l'interdiction de *mentionner* l'existence du dossier privé, ou simplement l'interdiction d'en *lire* le contenu pour étoffer le README. 

---

#### À trancher avant d'implémenter

1. **Faits historiques inaccessibles :** L'agent IA n'ayant pas accès aux réécritures d'historique ni aux fuites bloquées, Arnaud fournira-t-il le paragraphe correspondant en prérequis de contenu ? De même pour l'explication de "la solution facile écartée".
2. **Format strict du cas :** Le README doit-il obligatoirement inclure les blocs spécifiques "Contexte mission" et "En bref", ou sa structure se limite-t-elle strictement aux titres listés dans la story ?
3. **Disponibilité des liens publics :** Les branches `design/*` et le dossier `docs/measures/` (Epic 5) sont-ils bel et bien publics et poussés sur le miroir GitHub pour permettre de créer des liens fonctionnels dès la story 3.15 ?
4. **Narration :** Confirmer que la rédaction en anglais doit se faire à la 1ère personne du singulier ("I").

### Triage (20/09/2026)

**Retenu — la « solution facile » manquait aux sources, Arnaud l'a donnée.** Elle est quadruple, et la dernière est la plus parlante : un thème de portfolio tout fait, un profil LinkedIn et un PDF, une application React ou Next — et **sa propre stack**, PHP/Symfony, celle où il est le plus à l'aise. Un framework à base de données, d'authentification et de logique métier pour servir des pages HTML qui n'ont ni base, ni compte, ni logique : c'est l'exemple le plus net du jugement que le site vend, parce qu'il se retourne contre son auteur.

**Retenu — la narration est à la première personne** (décidé par Arnaud le 20/09/2026). C'est la voix des cas du site ; un README-cas qui change de voix cesse de se lire comme un cas.

**Retenu — `docs/measures/` n'existe pas.** Le dossier arrive avec la première mise en ligne (AD-17). Un lien mort dans un README public vaut moins que rien : le dossier est donc créé avec un `README.md` qui dit ce qui y sera consigné et quand. Anticipation déclarée, au sens du point 7 d'`AGENTS.md` : elle appartient à la story de mise en ligne, et le fichier le dit.

**Vérifié plutôt que tranché — les branches citées sont bien publiques.** L'API du dépôt public liste `design/dossier-architecture`, `design/suisse` et `experiment/d2-bilingue` : les liens fonctionnent.

**Retenu — le skill `hotfix` n'existe pas encore.** Le README décrit donc la **règle** du modèle de branches, pas l'outillage : il ne promet aucun script qu'un lecteur ne trouverait pas.

**Retenu — la terminologie est fixée une fois.** `garde-fou` → *public/private guard*, `contrôles` → *checks*, `parité` → *FR/EN parity*, `matériel vivant` → *live material*, `rubrique` → *section*. Employée partout pareil, et relue par Arnaud.

**Retenu — le lien « liste des contrôles » est ambigu.** Le README mène aux deux : `scripts/checks/`, où les contrôles vivent, et la section « Liste des contrôles » de l'architecture, qui les nomme et dit ce que chacun refuse.

**Retenu — l'ambiguïté de « sans source privée ».** L'interdiction porte sur la **lecture** : le premier jet ne s'appuie que sur des documents publics. Nommer `docs/private/` reste permis (NFR-9), et le README le nomme, puisque c'est le sujet même de « ce qui a résisté ».

**Retenu — la fusion attend la validation d'Arnaud.** La relecture de la voix et des faits est un prérequis de contenu, pas une formalité : la PR ne part pas sans son accord explicite sur le texte. C'est le seul cas de cette série où la fusion ne m'appartient pas.

**Refusé — imposer les encarts « Contexte mission » et « En bref ».** Ils appartiennent au gabarit d'une page de cas du site (FR-5, `docs/format-cas.md`) : front matter, traduction, parité FR/EN, rubriques numérotées. Le README n'est pas une page du site — il n'a ni langue jumelle, ni front matter, ni gabarit. Il suit la **trame narrative** d'un cas, ce que la story demande, pas le gabarit d'une page.

**Refusé — le premier critère n'est pas testable.** Le relecteur a raison sur la forme, mais la manière d'écrire est justement ce que D-12 verrouille : il dit d'où le texte peut venir. Il reste écrit comme critère, parce que c'est là qu'on ira le relire.

**Ajouté de mon fait — un test des liens du README.** Un lien relatif qui pointe vers un fichier disparu se voit rarement à la relecture, et jamais tant qu'on ne clique pas. `scripts/tests/test-readme.sh` vérifie que chaque lien relatif mène à un chemin qui existe, et que les sections de la trame du cas sont là.

### Réponses d'Arnaud (20/09/2026)

- **Voix** : première personne, comme les cas du site.
- **Solution facile** : les quatre routes, et non une seule — le thème tout fait, le profil LinkedIn, l'application React ou Next, **et sa propre stack**. Ses mots : « même si je suis à l'aise avec ma stack, ce n'est pas forcément le bon outil pour ce que je cherche à faire (base de données, la lourdeur de Symfony juste pour afficher des pages html non dynamiques, sans auth, sans db, sans logique métier) ». C'est la quatrième qui porte le cas : le jugement qui compte est celui qui va contre ses propres habitudes.
- **Relecture du premier jet (prérequis de contenu, D-12)** : accordée sans réserve, le 20/09/2026. Les quatre faits soumis à sa confirmation — recherche jusqu'en avril 2027, six cas clients, sources privées repérées **avant** la publication sur GitHub, et la formule « nothing to keep alive at three in the morning » — sont validés tels quels.

## Ce qui est livré

- `README.md` (95 lignes) — en anglais, à la première personne, sur la trame d'un cas : Context, The problem, The easy solution and why I dropped it, What I decided, What pushed back, Outcome ; puis un tableau de références et le modèle de branches.
- `docs/measures/README.md` — le dossier que le README annonce, avec ce qui y sera consigné et par quelle story. Anticipation déclarée (point 7 d'`AGENTS.md`).
- `scripts/tests/test-readme.sh` — 6 cas : la trame et son ordre, les références exigées par la story, le modèle de branches, la langue et la voix, et surtout **chaque lien relatif mène à un chemin qui existe**.

### Ce que le README raconte dans « what pushed back »

Les trois résistances, dans cet ordre : les sources privées déjà entrées dans l'historique, repérées avant la publication, l'historique réécrit et le garde-fou en trois couches — avec la leçon qui a coûté plus cher que le correctif, *un contrôle qui ne vit qu'en CI arrive après la publication* ; puis la difficulté d'échouer bruyamment en shell (quatre passes de revue sur une seule règle) ; puis l'environnement qui ment tant qu'on n'y tourne pas (BusyBox, les codes de `xmllint`, les tests qui supposaient de ne pas être `root`).

Aucun nom de client, aucun chiffre invérifiable, ni ville, ni tarif, ni téléphone. `docs/private/` est nommé, ce que NFR-9 autorise, et c'est le sujet même de la section.

### Essais

- `scripts/tests/run.sh` : 287 cas réussis.
- `scripts/check.sh` : 5 contrôles passés.
- Les trois branches citées (`design/dossier-architecture`, `design/suisse`, `experiment/d2-bilingue`) sont bien publiques sur le miroir : vérifié par l'API avant d'écrire les liens.

## Revue du code

### 20/09/2026 — `4e8696f` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 51. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c675ed009e2f3ede444dd9de

##### Revue BMAD

###### Lens `edge-case-hunter`

- **location** : `scripts/tests/test-readme.sh:37`
  **trigger_condition** : L'utilisation de `|| true` masque le code de retour 2 de `grep` (erreur système/fichier).
  **guard_snippet** : `grep -xF -f "$work/trame" || rc=$?; ((rc <= 1)) || exit 1`
  **potential_consequence** : Une erreur de lecture de fichier fausserait silencieusement le test.

- **location** : `scripts/tests/test-readme.sh:94`
  **trigger_condition** : `|| accents=0` avale le code de retour 2 de `grep` en cas d'erreur de lecture.
  **guard_snippet** : `grep -cE ... || rc=$?; ((rc <= 1)) || exit 1; ((rc == 1)) && accents=0`
  **potential_consequence** : Un README illisible serait considéré à tort comme un succès (0 accent détecté).

*(Note : Ces deux failles contredisent directement la leçon documentée dans le README lui-même, à savoir que `|| true` avale l'erreur 2 de `grep`.)*

###### Lens `verification-gap`

No verification gaps found. (Changement non comportemental : documentation et ajouts de tests uniquement).

##### Couche projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (le contenu du README respecte la trame du cas, inclut les 4 routes et justifie les sources privées).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret (la mention de `docs/private/` respecte NFR-9).
- NON BLOQUANT : Skill, procédure et script concordent (aucun écart à signaler sur ce périmètre).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (le journal de décision de l'Epic 3 et le workflow de branches linéaire sont conformes).
- BLOQUANT : Dans les scripts shell, des erreurs passent en silence sous set -euo pipefail (dans `scripts/tests/test-readme.sh`, les retours d'erreur 2 de `grep` sont masqués par `|| true` à la ligne 37 et par `|| accents=0` à la ligne 94).

VERDICT: BLOQUANT — Les codes d'erreur 2 de grep sont masqués par "|| true" et "|| accents=0" dans le script de test.

#### Décisions sur ces constats (20/09/2026)

**Retenu, et corrigé à la racine.** Le constat est juste, et il est savoureux : le piège que le README raconte — `|| true` qui confond « rien trouvé » avec « lecture impossible » — était reproduit dans le test du README lui-même. Deux occurrences signalées, plus une troisième que la correction a mise au jour dans `test-workflows.sh`, écrit la veille.

La parade ne pouvait pas être une enveloppe rendant son résultat sur la sortie standard : appelée dans `$(…)`, elle ne peut pas arrêter le cas, son `exit` ne quittant que le sous-shell — le piège voisin, celui de la story 3.11. `tests_grep_into <variable> <arguments de grep>` remplit donc une variable de l'appelant, et s'arrête dans le shell du cas. Les trois occurrences y passent, et `docs/procedures/shell-scripts.md` la nomme parmi les outils d'un cas de test.

Ce que cette passe montre : la règle « aucune erreur en silence » est facile à énoncer, et se tient mal dès qu'on écrit vite — y compris dans un test, y compris le jour où l'on vient d'en faire le récit public.

### 20/09/2026 — `1986ce1` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 51. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0d07c4c24d278c357355e37f

##### Revue BMAD

###### Lentille `edge-case-hunter`
NON BLOQUANT : Le correctif apporté via la fonction `tests_grep_into` gère parfaitement le cas limite du code de retour 2 de `grep` (erreur de lecture) et le piège de l'`exit` silencieux dans un sous-shell `$(...)`. Le passage par référence de variable (`local -n`) contourne solidement l'obstacle.

###### Lentille `verification-gap`
NON BLOQUANT : Aucun écart de vérification n'est à signaler. Le script de test `test-readme.sh` automatise bien la vérification des critères d'acceptation (trame respectée, liens relatifs valides pour éviter les 404, absence de français/présence de la voix à la première personne, modèle de branches documenté).

###### Lentille rédactionnelle (Structure et Prose)
NON BLOQUANT : Le texte du README-cas est clair, direct, et l'ordre des idées est parfaitement logique. Le contraste entre la "solution facile" (React, Symfony) et "ce qui a été décidé" (Hugo statique) explicite très bien le niveau d'ingénierie et le jugement technique vendu par le portfolio. L'anticipation propre à `docs/measures/` pour éviter un lien mort est élégante.

##### Couche projet

NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée.
NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (nommer le dossier `docs/private/` respecte NFR-9).
NON BLOQUANT : Skill, procédure et script concordent : l'outil de test `tests_grep_into` est correctement documenté et formalisé dans `docs/procedures/shell-scripts.md`.
NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (modèle de branches respecté, anticipation déclarée).
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail (les masquages par `|| true` et `|| accents=0` ont bien été remplacés et résolus à la racine).

VERDICT: NON BLOQUANT — aucune

## Reporté
