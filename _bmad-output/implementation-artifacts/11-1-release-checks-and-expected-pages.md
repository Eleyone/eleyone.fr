# Story 11.1 : Release checks and expected pages

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.1.

Première story de l'epic 11, dont l'en-tête dit (point 21) : la chaîne de mise en ligne est
construite et **répétée tôt** sur le serveur de production, sans DNS ; les stories 11.1 à 11.9
passent avant l'Epic 10, dont elles ne dépendent pas (D-5). La liste `ci/release-pages.txt` est
donc cumulative et ne vaut que « à ce commit » : C15 ne doit jamais exiger la complétude du socle,
que seule `release` vérifie pour `v1.0.0` (stories 11.7 et 11.11).

## Revue de spec

### 24/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `94080a1`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 850c3fafad37dbd94517d051

#### Revue de spec (Story 11.1)

##### Lentille Adverse (Adversarial Critique)

- BLOQUANT : **Comportement hors release non spécifié.** La spec définit les actions pour `scripts/check.sh --release` mais reste muette sur le comportement en mode standard. Puisque `check.sh` lance automatiquement tous les scripts présents dans `scripts/checks/`, le nouveau contrôle sera exécuté sur chaque PR. Sans consigne exigeant de le restreindre à `CHECK_LEVEL=release`, il fera échouer la CI de la branche `dev` (qui contient l'état « pilote en brouillon » et les valeurs factices).
- BLOQUANT : **Critère de test manquant.** La story ajoute un garde-fou bloquant la mise en ligne, mais n'exige aucun test. Cela contredit directement la règle 9 d'`AGENTS.md` (« *A guard gets a test that fails without it* »). La spec doit exiger l'ajout d'un test dans `scripts/tests/` pour prouver le fonctionnement du contrôle.
- BLOQUANT : **Critère invérifiable pour les sections.** Le critère impose d'échouer si « une page ou une section listée manque » en lisant la liste plate `ci/release-pages.txt` (qui contient par ex. `case-02` et `group-chiliz`). La spec ne dit pas comment le script peut distinguer une page (fichier `index.html`) d'une section au sein d'une page de groupe, rendant la vérification de sa présence hasardeuse (un développeur vérifierait l'existence d'un fichier et le test échouerait faussement pour les sections).
- BLOQUANT : **Définition ambiguë de "vide".** Le critère « échoue si une page de groupe est vide » ne définit pas comment cela se traduit techniquement dans le build de production `public/`. S'agit-il de l'absence de balises `<section>` spécifiques, ou d'une information tirée du manifeste `checks.json` ? Sans définition, c'est invérifiable.

##### Lentille Structure

- NON BLOQUANT : **Séparation des responsabilités.** Les vérifications d'inclusion (vérifier que toutes les pages et sections attendues sont là) et les vérifications d'exclusion (vérifier qu'il ne reste ni valeur factice, ni `checks.json`, ni marqueur de brouillon) sont mélangées dans le même critère d'acceptation. Les scinder rendrait le plan d'implémentation et de test plus clair.

##### Lentille Rédactionnelle (Prose)

- NON BLOQUANT : **Polysémie du verbe "apparaît".** Le texte demande d'échouer « si VALEUR-FACTICE, un checks.json, un noindex ou un draft-marker apparaît dans public/ ». L'utilisation du même verbe pour désigner la présence d'une chaîne de caractères textuelle (ex: dans un fichier HTML) et l'existence physique d'un fichier à la racine (`checks.json`) est imprécise.

##### À trancher avant d'implémenter

- Le nouveau script de contrôle doit-il simplement ignorer les vérifications (code de sortie 0) lorsque `CHECK_LEVEL` est différent de `release` ?
- Faut-il spécifier dans les critères l'ajout d'un test dans `scripts/tests/` pour se conformer à la règle 9 d'`AGENTS.md` ?
- Comment le script doit-il techniquement déterminer qu'une page de groupe est "vide" ?
- Comment le script doit-il vérifier la présence d'une "section" à partir de la clé (comme `case-02`) ? (Doit-il utiliser `checks.json` avant de s'assurer qu'il est supprimé, ou faire une recherche dans le DOM de la page de groupe ?)

## Revue du code

### 25/09/2026 — `e705588` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 116. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: fcb628267e18943d26fb3eef

##### Revue BMAD

###### Lentille : Edge-Case Hunter
```json
[]
```

###### Lentille : Verification Gap
No verification gaps found.

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (les vérifications `release` rejettent effectivement les pages de groupes vides et les traces de travail, et l'écart avec les valeurs factices sur le poste est expliqué et valide).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- NON BLOQUANT : Skill, procédure et script concordent (la procédure `check.md` cite les options réelles et `build-image.md` est mis à jour avec le bon compte de variables).
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` (les règles 8, 9 et 16 sont strictement appliquées avec la preuve des 17 mutations de gardes testées) et avec les décisions d'architecture (AD-4, AD-5).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (tous les appels à `jq`, `checks_attributes`, `checks_xpath` et `checks_find` sont systématiquement adossés à `|| exit $?` ou `|| checks_die`).

VERDICT: NON BLOQUANT — aucune

## Décisions

### Le second critère d'acceptation décrit un état que l'epic 10 a fait disparaître

Le critère dit : « Étant donné l'état actuel (pilote en brouillon, valeurs factices) … alors il
échoue et liste chaque écart ». Vérifié sur le dépôt plutôt que supposé : **la première prémisse
n'existe plus**. L'ordre de travail (D-5) plaçait les stories 11.1 à 11.9 avant l'Epic 10 ; elles
ont en fait été faites après, et l'epic 10 a publié les cas 01, 02 et 05. Les neuf clés de
`ci/release-pages.txt` sont en ligne, en FR et en EN. La seconde prémisse tient, mais seulement là
où il n'y a pas de `.env` — CI, clone neuf, `CHECK_IMAGE` —, puisque `scripts/env.sh` fait passer
le `.env` du poste devant `ci/legal-placeholder.env` (AD-9).

Le critère est donc vérifié **dans l'état qu'il décrit**, reproduit explicitement, et non dans
l'état du poste. Mesuré par l'orchestrateur, indépendamment du rapport de la sous-tâche :

```
$ ENV_FILE=<absent> scripts/build.sh production && ENV_FILE=<absent> CHECK_LEVEL=release scripts/env.sh bash scripts/checks/release-pages.sh
mentions-legales/index.html: C15 : trace de travail « VALEUR-FACTICE » trouvée dans la page
en/legal-notice/index.html: C15 : trace de travail « VALEUR-FACTICE » trouvée dans la page
rc=1
```

C15 n'a **pas** été élargi pour faire échouer le poste : refuser une mise en ligne construite depuis
`.env` est le rôle d'`ENV_MODE=release` (AD-9), qui rejette nommément `.env` et le fichier factice,
et c'est la story 11.3 qui le câble. C15 ne juge que la sortie.

### Deux décomptes périmés corrigés en passant

`scripts/check.sh` et `docs/procedures/build-image.md` disaient « sept variables légales » ; AD-9 en
compte **huit** depuis sa révision du 23/09/2026, et `ci/legal-placeholder.env` en porte huit. Les
deux phrases sont fausses depuis la story 9.7, pas depuis celle-ci, mais l'une est dans un fichier
que cette PR modifie déjà et l'autre décrit le même niveau `release` : les laisser vraies au moment
où on les lit coûte deux mots (esprit du point 8 et de la rétrospective de l'epic 4).

### Vérification du travail de la sous-tâche (point 22)

Le rapport d'une sous-tâche est une affirmation, pas un fait. Rejoué par l'orchestrateur sur le
dépôt, sans reprendre ses mesures :

| Vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 592 cas réussis |
| `scripts/check.sh` | code 0, 10 contrôles, C15 écrit sa ligne de saut |
| `scripts/check.sh --release` | code 0 sur le poste |
| page attendue supprimée de `public/` | code 1, la page et la clé sont nommées |
| `id=case-02` renommé dans la page du groupe | code 1, section absente signalée |
| `class=case-section` retirée de la page EN du groupe | code 1, page de groupe vide signalée |
| `NOINDEX, nofollow` en majuscules, minifié | code 1, trace signalée |
| `checks.json` déposé dans `public/` | code 1, fichier publié signalé |
| `url` retirée des deux manifestes | code **2** (anomalie), pas un silence |

Les builds `public/` et `build/work` ont été reconstruits avec le `.env` normal après ces mesures :
aucune sortie à valeurs factices ne reste dans l'arbre.

#### Triage des constats (point 20 : chacun reçoit sa décision)

**B1 — comportement hors `release` non spécifié. RETENU.** `check.sh` découvre dynamiquement
`scripts/checks/*.sh` : le contrôle tournerait sur chaque PR et ferait échouer `dev`, dont le
pilote est justement en brouillon et les valeurs factices. Décision : `scripts/checks/release-pages.sh`
lit `CHECK_LEVEL` et, hors `release`, écrit une ligne qui **dit qu'il est sauté** puis rend 0 — un
`exit 0` muet cacherait un nom de variable mal écrit. Deux cas de test exercent les deux niveaux
sur la même sortie fautive : `standard` passe, `release` échoue.

**B2 — aucun test exigé. RETENU** (point 9 d'AGENTS.md). `scripts/tests/test-release-pages.sh`,
un cas par règle refusée, chacun exerçant l'entrée que la garde doit refuser, et la suite rejouée
une fois **sans** la garde pour la voir échouer.

**B3 — page ou section : comment distinguer. RETENU, et tranché par la mesure.** Mesuré le
24/09/2026 en ajoutant `RelPermalink` au manifeste et en construisant le rendu de travail :

```
home /            about /a-propos/       contact /contact/      legal-notice /mentions-legales/
privacy /confidentialite/                group-chiliz /cas/chiliz/
case-01 /cas/calculette-rentabilite/     case-05 /cas/orange-crv-performance/
case-02 (vide)    case-03 (vide)         case-04 (vide)
```

Hugo rend une `RelPermalink` **vide** pour un cas groupé, dont la cascade porte `render: never`
(AD-4). La distinction est donc donnée par Hugo lui-même, et n'a pas à être devinée par le script :
`url` non vide → page attendue à `public/<url>index.html` en FR et en EN ; `url` vide sur un rôle
`case` → section attendue, `id="<translationKey>"` dans la page du groupe nommé par sa clé `group`.
Décision : le manifeste gagne la clé `url`, documentée dans `layouts/home.checks.json` et dans
l'en-tête de `scripts/checks/lib.sh`. Ce n'est pas une anticipation au sens du point 7 : le
manifeste est l'interface par laquelle Hugo parle aux contrôles, et trois stories l'ont déjà
étendu ; reconstituer une URL depuis un `slug` serait une deuxième vérité.

**B4 — « page de groupe vide » indéfini. RETENU.** Définition arrêtée : une entrée de rôle `group`
dont la page de production ne contient **aucune** `<section class="case-section">`. C'est ce que le
lecteur voit — un titre de groupe sans un seul cas —, et non un décompte tiré du manifeste, qui
compterait des cas en brouillon absents de la production.

**NB1 — inclusion et exclusion mêlées. RETENU en partie.** Les critères d'acceptation ne sont pas
réécrits, mais le script sépare les deux en deux sections nommées, et les cas de test suivent la
même coupe.

**NB2 — polysémie d'« apparaît ». RETENU.** Le script et ses messages distinguent le **fichier**
présent (`checks.json` publié) de la **chaîne** trouvée dans une page (`VALEUR-FACTICE`, `noindex`,
`draft-marker`), et les messages nomment la page et la nature de l'écart.

Aucun constat ne demandait d'arbitrage d'Arnaud : les quatre bloquants sont des trous de spec que
la mesure ou une règle existante du projet referme.

## Implémentation

### Ce qui a été livré

| Fichier | Ce qu'il apporte |
| --- | --- |
| `scripts/checks/release-pages.sh` | C15. Découvert seul par `check.sh`, qui n'est pas modifié (hors son commentaire d'en-tête). |
| `layouts/home.checks.json` | la clé `url` (`.RelPermalink`) sur chaque entrée de `files`, avec le commentaire qui dit pourquoi (B3). |
| `scripts/checks/lib.sh` | `url` documentée dans la forme du manifeste, en tête du fichier. |
| `scripts/tests/test-release-pages.sh` | 35 cas, un par règle refusée. |
| `scripts/tests/test-checks-manifest.sh` | quatre assertions sur `url`, sur un **vrai build** : c'est le seul cas qui prouve la forme du manifeste. |
| `scripts/tests/fixtures/manifests/{fr,en}.json` | `url` ajoutée aux manifestes partagés, pour qu'une fixture déclare ce que le vrai manifeste déclare (point 16). |
| `docs/procedures/check.md` | ligne C15 du tableau « Contrôles livrés » ; la phrase « Aucun contrôle de mise en ligne n'existe avant l'epic 11 » est mise au présent. |
| `scripts/check.sh` | le commentaire de la ligne 5 est mis au présent : il nomme C15 au lieu d'annoncer l'epic 11. |

Les quatre décisions du triage sont appliquées telles quelles : saut **annoncé** hors `release`,
distinction page/section par `url`, « page de groupe vide » = aucune `<section class="case-section">`,
deux sections nommées (inclusion / exclusion) avec un message distinct pour un **fichier** publié et
pour une **chaîne** trouvée dans une page. Une clé de `ci/release-pages.txt` inconnue du manifeste est
signalée, dans chacune des deux langues.

### Ce que la mesure a corrigé en cours de route

Le premier jet lisait les champs du manifeste avec `IFS=$'\t'`. **La tabulation est un blanc**, et
`read` traite une suite de blancs de l'IFS comme un seul délimiteur : l'`url` vide d'un cas groupé —
le champ dont tout ce contrôle dépend — disparaissait, et `chiliz`, le nom du groupe, passait pour
l'URL de `case-02`. Le contrôle signalait alors une page `chiliz` absente. Vu en le lançant sur le
dépôt réel, jamais en le relisant. Le séparateur est désormais U+001F, qui n'est pas un blanc et
conserve les champs vides.

Le build de production est **minifié** : mesuré sur `public/cas/chiliz/index.html`, Hugo y écrit
`<section id=case-02 class=case-section>`, sans guillemets. Les identifiants sont donc lus par XPath
(`checks_attributes`), jamais par `grep`, et la fixture des tests écrit elle aussi la forme non
guillemetée, avec un cas dédié pour la forme guillemetée.

### Point 19 — le brief du jumeau : `scripts/checks/links.sh` (C12) et `scripts/tests/test-links.sh`

L'aîné parcourt `public/`, lit du HTML et croise des identifiants ; le cadet fait la même chose. Ses
gardes, une par une :

| Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- |
| 1. `[[ -d $public ]] \|\| checks_die` : production absente = anomalie (2) | **Oui**, reprise à l'identique, même message. Cas : `sans_build`. Le cadet ajoute la garde jumelle sur le **rendu de travail** (`checks_manifests` meurt si la racine ou les manifestes manquent), que l'aîné n'a pas parce qu'il ne lit pas de manifeste. Cas : `sans_rendu_de_travail`. |
| 2. `command -v xmllint`, avec le nom du paquet | **Oui**, reprise mot pour mot. Cas : `sans_xmllint`. Le cadet ajoute `command -v jq` (repris de `html.sh`), puisqu'il lit des manifestes. Cas : `sans_jq`. |
| 3. Liste éprouvée **avant** `mapfile` (`mapfile <<<` rend un tableau d'un élément vide, jamais un tableau vide) | **Oui**, trois fois : la liste attendue (`liste_vide_nest_pas_une_conformite`), les entrées d'un manifeste (`manifeste_sans_entree`) et les pages HTML (`sans_page_html`). La liste des manifestes elle-même est éprouvée par `checks_manifests`, qui meurt avant le `mapfile`. |
| 4. `checks_find` plutôt que `find` nu | **Oui**, aux deux endroits où le cadet parcourt `public/` (les `checks.json` publiés, les pages HTML). Le contrat de `checks_find` est éprouvé par `test-checks-lib.sh` ; le cadet ne le redouble pas. |
| 5. `checks_attributes` / `checks_xpath` plutôt qu'un `grep` sur du HTML ; `shell_grep*` plutôt qu'un `grep` nu | **Oui**. Identifiants : `checks_attributes`. Décompte des cas d'une page de groupe : `checks_xpath` avec `count()`. Lecture de la liste attendue et recherche des marqueurs : `shell_grep_into`. Test de présence d'un identifiant : `shell_grep -qxF` dans une condition, jamais en tête de pipeline. |
| 6. Le build de production est **minifié** ; ne jamais exiger le guillemet | **Oui, et c'est le cœur du contrôle.** Mesuré sur `public/` (voir ci-dessus) ; la fixture par défaut écrit la forme non guillemetée, et `section_guillemetee_passe_aussi` couvre l'autre. |
| 7. `CHECK_PUBLIC_ROOT` et `CHECK_WORK_ROOT` surchargeables | **Oui**, plus `CHECK_RELEASE_PAGES_FILE` (sur le modèle de `CHECK_CONFIG_FILE` de l'aîné) : sans lui, un cas de test lirait la vraie liste du dépôt. Les trois sont posées par **tous** les cas, comme l'aîné pose `CHECK_WORK_ROOT` même quand le cas ne s'en sert pas. |
| 8. Codes 0/1/2, signalements par `checks_report` qui nomme la page **et** l'écart | **Oui**, sans exception. Chaque message nomme le fichier fautif, la clé et la langue. |
| 9. Jamais `commande \| wc -l` ; passer par une variable | **Oui** : aucun pipeline dans le cadet. Les deux `checks_find` et les recherches de marqueurs écrivent dans une variable, puis sont relues par `<<<`. |
| 10. Une liste vide n'est jamais une conformité | **Oui** : voir la garde 3. Le cas du **groupe** est raisonné à part et écrit dans le script : n'avoir aucun groupe est légitime, et ce sont la liste attendue et le manifeste — tous deux éprouvés non vides — qui disent que la racine lue est la bonne. |
| 11. Point 16 : la fixture déclare ce que la vraie page déclare, `<meta charset=utf-8>` compris | **Oui**, dans `page()`, repris de l'aîné. Sans lui `xmllint` lit du Latin-1 et les motifs cessent de correspondre en silence. |
| *Gardes de l'aîné que le cadet ne reprend pas* | `checks_roots_into` (lire **les deux** rendus) : **non**. C12 en a besoin parce que les cas en brouillon n'existent que dans le rendu de travail ; C15 juge précisément ce qui est **en ligne**, et lire un brouillon le rendrait faux. L'exemption des deux pages 404 : **non**, le cadet ne juge pas l'atteignabilité. La lecture de `config/_default/hugo.yaml` : **non**, C15 ne lit aucune configuration. |
| *Gardes que le cadet ajoute* | Le manifeste doit porter `url` (un manifeste antérieur à cette story ferait passer toute page pour une section, en silence) ; le décompte de `count()` doit être un nombre (une autre version de libxml2 rendrait autre chose, et comparer une chaîne à zéro conclurait à tort). |

Cas repris de `test-links.sh` : `skip_if_root` pour la page illisible, un cas sans build, et la règle
qu'une absence totale ne rend jamais le contrôle muet.

### Point 9 — chaque garde retirée, une fois, pour la voir échouer

Dix-sept mutations, une par garde, chacune suivie de `scripts/tests/run.sh scripts/tests/test-release-pages.sh`.
**Aucune n'est passée au vert.**

| Garde retirée | Ce que la suite a répondu |
| --- | --- |
| `[[ -d $public ]]` | `release_pages_sans_build` : attendu `scripts/build.sh production`, obtenu huit signalements de pages absentes puis `parcours impossible (find, code 1)`. |
| `command -v xmllint` | `release_pages_sans_xmllint` : le message obtenu est `jq est introuvable`, pas le nom du paquet `libxml2-utils`. |
| `command -v jq` | `release_pages_sans_jq` : `grep : commande introuvable` puis `recherche impossible (grep, code 127)`. |
| `[[ -f $expected_file ]]` | `release_pages_liste_absente` : `grep: …/release-pages.txt: Aucun fichier ou dossier de ce nom`, au lieu du message qui nomme le fichier. |
| `[[ -n $liste_attendues ]]` | `release_pages_liste_vide_nest_pas_une_conformite` : attendu 2, obtenu **1**. |
| `((sans_url == 0))` | `release_pages_manifeste_sans_cle_url` : attendu 2, obtenu **1** — toute page passait pour une section. |
| `[[ -n $entrees ]]` | `release_pages_manifeste_sans_entree` : attendu 2, obtenu **1**. |
| la branche « clé inconnue du manifeste » | `release_pages_cle_inconnue_du_manifeste` : `url_de[$index] : variable sans liaison`. |
| séparateur U+001F → tabulation | `release_pages_accueil_absent` : les quatre clés deviennent « inconnues du manifeste » — c'est la faute trouvée sur le dépôt réel, et la suite la voit. |
| prédicat de classe encadré → `contains(@class, "case-section")` | `release_pages_classe_voisine_ne_compte_pas_pour_un_cas` : attendu 1, obtenu **0** — `case-section-titre` remplissait la page. |
| `[[ -n $liste_pages ]]` | `release_pages_sans_page_html` : attendu 2, obtenu **1**. |
| `--include='*.html'` | `release_pages_marqueur_hors_dune_page_ne_compte_pas` : `css/main.css: C15 : trace de travail « draft-marker »`. |
| `-i` de `grep -rliF` | `release_pages_noindex_autres_formes` : attendu 1, obtenu **0** — `NOINDEX, nofollow` passait. |
| `checks_attributes` → `grep` exigeant le guillemet | `release_pages_classe_parmi_dautres_compte` : `section « case-09 » absente` sur une sortie minifiée. |
| boucle sur les deux langues → la première seule | `release_pages_cle_inconnue_du_manifeste` : le signalement anglais disparaît. |
| `[[ $nombre =~ ^[0-9]+$ ]]` | `release_pages_decompte_illisible_est_une_anomalie` : attendu 2, obtenu **1** — un décompte illisible se lisait comme « page vide ». |
| `checks_find` → `find` nu | non muté : le contrat de `checks_find` est éprouvé par `test-checks-lib.sh`, et le dupliquer ici serait la garde en deux exemplaires que `docs/procedures/shell-scripts.md` refuse. |

### Vérifications

- `bash scripts/tests/run.sh` : **592 cas réussis** (35 nouveaux).
- `scripts/check.sh` : **10 contrôle(s) passés, niveau standard** ; C15 y écrit
  `release-pages: niveau « standard » : contrôle de mise en ligne sauté, il ne tourne qu'au niveau « release » (scripts/check.sh --release).`
- `scripts/check-private.sh staged` : silencieux, code 0.

### Le second critère d'acceptation, et ce que la mesure a changé

Le critère dit : « l'état actuel (pilote en brouillon, valeurs factices) … alors il échoue et liste
chaque écart ». **Les deux prémisses ont bougé depuis que le critère a été écrit** (point 21 : lire
l'en-tête de l'epic, et vérifier l'état plutôt que le supposer) :

1. le pilote n'est plus en brouillon — l'epic 10 a publié les cas 01, 02 et 05, et les neuf clés de
   `ci/release-pages.txt` sont toutes en ligne, en FR et en EN ;
2. les valeurs légales ne sont factices que **là où il n'y a pas de `.env`** — c'est-à-dire dans une
   CI, dans un clone neuf et dans `CHECK_IMAGE`, mais pas sur le poste d'Arnaud, dont le `.env` porte
   les vraies valeurs et que `scripts/env.sh` fait passer devant `ci/legal-placeholder.env` (AD-9).

Les deux mesures, sur le dépôt réel :

**Sur le poste, avec le `.env` d'Arnaud** — `scripts/check.sh --release`, code **0** :

```
release-pages: pages et sections attendues présentes en FR et en EN, aucune page de groupe vide, aucune trace de travail.
check: 10 contrôle(s) passés, niveau release.
```

**Dans l'état que décrit le critère (valeurs factices, donc CI et clone neuf)** —
`ENV_FILE=/nonexistent/.env scripts/check.sh --release`, code **1** :

```
budget: poids et nombre d'éléments dans les budgets d'AD-8.
content: rubriques, marqueurs [TODO, vocabulaire, matériel vivant, groupes, encarts, format et parcours vérifiés.
html: zéro script, aucune ressource tierce, aucun marqueur, structure accessible.
images: aucune métadonnée, dimensions et poids des images conformes à AD-19.
legal-address: l adresse de l éditeur ne sort pas du corps des deux pages des mentions légales.
links: liens internes, ancres, pages atteignables et liens conditionnels vérifiés.
parity: parité FR/EN vérifiée.
pdf: les 2 CV PDF ont leur en-tête, leurs pages, leur poids, et aucun motif privé.
typo: typographie française posée sur les pages FR, absente des pages EN, aucune césure automatique.
```

```
mentions-legales/index.html: C15 : trace de travail « VALEUR-FACTICE » trouvée dans la page
en/legal-notice/index.html: C15 : trace de travail « VALEUR-FACTICE » trouvée dans la page
check: 1 contrôle(s) en échec sur 10 : release-pages
```

Le critère est donc tenu là où il a un sens — C15 refuse bien une sortie construite avec les valeurs
factices, et nomme chaque page fautive —, mais **il n'est pas tenu sur le poste d'Arnaud**, parce que
le poste construit avec les vraies valeurs. Ce n'est pas un trou de C15 : refuser une mise en ligne
construite depuis `.env` est le rôle d'`ENV_MODE=release` (AD-9, story 11.3), qui exige un fichier de
secrets dédié et rejette nommément `.env` et `ci/legal-placeholder.env`. C15 ne juge que la sortie.
**À porter à la revue de code** : c'est le seul endroit où le résultat mesuré s'écarte de la lettre du
critère, et il s'en écarte parce que l'état du dépôt a changé entre l'écriture du critère et sa mise
en œuvre.

### Constats sans revue de code à ce stade

La revue du code (`scripts/llm-review.sh <PR>`) n'a pas encore tourné : la branche n'est ni commitée
ni poussée. Aucun constat de revue de code n'est donc en attente de décision.

#### Triage du rapport de code (point 20 : un verdict `pass` se triage comme un `block`)

Les deux lentilles rendent une liste vide — `[]` pour l'edge-case-hunter, « no verification gaps
found » pour la lentille des trous de vérification. Les cinq lignes de la couche propre au projet
sont des **confirmations** (critères tenus sans vider leur intention, aucune donnée privée, skill et
procédure concordants, points 8, 9 et 16 d'AGENTS.md appliqués, aucune erreur silencieuse sous
`set -euo pipefail`), et non des constats : aucune ne demande de changement, aucune n'est reportée
dans `deferred-work.md`.

**Rien à trancher, et c'est écrit plutôt que tu** — l'epic 10 a montré qu'un rapport `pass` sert de
filtre et que quatre constats y échappent au triage (action 67). Le rapport est exhaustif : chaque
ligne ci-dessus a été relue et classée.
