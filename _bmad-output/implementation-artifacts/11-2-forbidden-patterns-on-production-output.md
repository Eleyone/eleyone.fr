# Story 11.2 : Forbidden patterns on production output

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.2.

Deuxième story de l'epic 11, dont l'en-tête (point 21) place la chaîne de mise en ligne avant le
contenu : C22 est le dernier filet entre le build de production et le serveur, et il ne juge que la
sortie, jamais les sources — celles-ci relèvent du garde-fou (AD-12).

## Revue de spec

### 25/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `2476035`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a40a20d3b5fd546d2523f00e

##### Lentille : Adverse (Edge cases, failles de vérification, contradictions)

- **BLOQUANT** : La spec indique qu'il faut utiliser "un fichier temporaire" pour la liste des motifs. Or, la fonction partagée `pdf_confront` exige deux fichiers temporaires (numérotés et nus). La spec doit dicter l'utilisation explicite de ces deux fichiers et de `pdf_confront` pour empêcher le développeur de dupliquer la logique de recherche (faute A2 de l'epic 7).
- **BLOQUANT** : La spec stipule que "le fichier temporaire est supprimé en fin d'exécution" mais omet de préciser la leçon de l'epic 7 (erreur B1) : la variable qui porte le chemin ne doit jamais servir de condition booléenne pour vérifier si la liste est vide dans le `trap ... EXIT`, sous peine de laisser des fichiers temporaires résiduels.
- **BLOQUANT** : Le périmètre des fichiers inspectés dans la "sortie de production" (le dossier `public/`) n'est pas défini. La spec doit explicitement limiter la recherche aux fichiers texte générés (HTML, XML, JSON, CSS, etc.) et exclure les fichiers PDF (déjà couverts par C21) ainsi que les binaires, sinon `pdf_confront` échouera ou signalera des faux positifs.
- **BLOQUANT** : La spec exige que C22 "ne tourne que dans le job release", mais omet le comportement attendu dans le niveau `standard`. Pour suivre le modèle établi par C15, la spec doit exiger que le script déclare explicitement être sauté (skip) puis rende 0 lorsque `CHECK_LEVEL` n'est pas `release`.
- **BLOQUANT** : La méthode technique pour identifier "les pages des mentions légales" n'est pas définie. La spec doit imposer comment les trouver dynamiquement (par exemple en lisant l'URL correspondant à `translationKey == legal-notice` dans le manifeste `checks.json`), afin d'éviter que le développeur ne code les chemins en dur.
- **BLOQUANT** : L'algorithme pour vérifier qu'un motif est "contenu dans une valeur `HUGO_LEGAL_*` injectée, puis hors de ces valeurs" est absent. Il faut spécifier comment le script expurge les valeurs légales de la page avant de confronter le reste du texte à `pdf_confront` ; sans cela, l'implémentation sera incapable de distinguer une occurrence légitime d'une fuite accidentelle.
- **BLOQUANT** : L'utilisation de la variable `PRIVATE_PATTERNS_FILE` pour lire la liste des motifs n'est pas exigée dans la spec. Sans cette directive, l'implémentation risque d'utiliser un chemin en dur, provoquant un échec dans les environnements CI où la source diffère.
- **NON BLOQUANT** : La spec ne demande pas la création de tests hors ligne automatisés (par exemple `scripts/tests/test-output-patterns.sh`), diminuant la couverture des tests du projet.

##### Lentille : Structure

- **BLOQUANT** : La section "Étant donné" est incomplète. Elle doit faire figurer explicitement les prérequis d'environnement partagés du projet nécessaires à ce script : la variable `PRIVATE_PATTERNS_FILE`, le chargement de l'environnement légal, la disponibilité du manifeste `checks.json`, et l'outil de confrontation partagé `pdf_confront`.

##### Lentille : Prose (Éditoriale et clarté)

- **NON BLOQUANT** : L'expression "un motif factice apparaît dans une page" est ambiguë quant à sa cible. Il serait plus clair d'écrire "dans le code HTML d'une page de la sortie de production" pour éviter toute confusion avec les sources Markdown.
- **NON BLOQUANT** : Le critère d'acceptation "sans recopier le motif" omet de préciser qu'il faut afficher "le numéro de ligne", ce qui est le comportement existant de `pdf_confront` et une information essentielle pour le débogage.

##### À trancher avant d'implémenter

- Quel est l'algorithme exact pour expurger les occurrences légitimes des valeurs `HUGO_LEGAL_*` des pages de mentions légales avant de chercher d'éventuelles autres fuites avec `pdf_confront` ?
- Comment C22 doit-il déterminer dynamiquement le chemin des pages légales à analyser dans `public/` (lecture de `checks.json` vs chemins d'URL en dur) et comment doit-il restreindre son analyse globale aux seuls fichiers texte pertinents ?

#### Triage des constats (point 20 : chacun reçoit sa décision, y compris les non bloquants)

| # | Constat | Décision |
| --- | --- | --- |
| A1 | `pdf_confront` veut **deux** fichiers temporaires, pas un | **Retenu.** C22 reprend le montage de `scripts/checks/pdf.sh` : un fichier `numéro:motif`, un fichier de motifs nus, et `pdf_confront` pour la recherche. Aucune recherche réécrite (faute A2 de l'epic 7). |
| A2 | La variable qui porte le chemin ne doit pas servir de booléen dans le `trap` | **Retenu.** Tableau `temporaires` et `trap … EXIT` copiés de l'aîné, où confondre les deux sens laissait deux fichiers par exécution (constat B1, epic 7). |
| A3 | Périmètre des fichiers inspectés non défini | **Retenu**, mais **pas** par une liste d'extensions à inspecter : énumérer ce qu'on imagine est la faute que la rétrospective de l'epic 7 a nommée, et C23 l'a déjà tranchée dans l'autre sens. C22 lit **tout** `public/` et n'exclut que ce que d'autres contrôles couvrent déjà, par les deux **listes uniques** du dépôt : les extensions d'images de `scripts/lib/image.sh` (C20) et les PDF de `scripts/lib/pdf.sh` (C21). Un format de sortie nouveau est donc inspecté par défaut, jamais oublié par omission. |
| A4 | Comportement hors `release` non spécifié | **Retenu.** Modèle de C15 (story 11.1) : le contrôle **dit** qu'il est sauté, puis rend 0. |
| A5 | Comment trouver les pages légales | **Retenu.** Par le manifeste : l'entrée de `translationKey` `legal-notice` de chaque langue donne son `url`, clé livrée par la story 11.1. Aucun chemin en dur. `legal-address.sh` (C23), lui, code les deux chemins en dur (`pages_legales`) : la divergence est réelle et part dans `deferred-work.md` plutôt que d'élargir cette story. |
| A6 | Algorithme d'expurgation absent | **Retenu, et c'est le cœur de la story.** Voir la décision ci-dessous : on retire les **occurrences** des valeurs, on ne dispense pas le motif. |
| A7 | `PRIVATE_PATTERNS_FILE` non exigée | **Retenu**, avec le repli sur `docs/private/forbidden-patterns.txt` de l'aîné. **Et une différence assumée** : pour C21, une liste absente laisse passer le reste des règles ; pour C22, la liste **est** le contrôle. Au niveau `release`, son absence est une **anomalie** (code 2), jamais un succès — une mise en ligne ne se valide pas sur un garde-fou qui n'a rien lu. |
| A8 | Aucun test demandé | **Retenu** (point 9) : `scripts/tests/test-output-patterns.sh`, un cas par règle refusée, la suite rejouée une fois sans chaque garde. |
| S1 | La section « Étant donné » de la spec est incomplète | **Retenu sur le fond, sans réécrire `epics.md`.** Les prérequis cités — `PRIVATE_PATTERNS_FILE`, le chargeur légal, le manifeste, `pdf_confront` — sont tous portés par l'implémentation et par ce triage, qui est l'endroit où le projet consigne ce genre de complément. Modifier un artefact de planification validé pour compléter un « Étant donné » est un autre débat, déjà ouvert dans `open_questions`. |
| P1 | « un motif apparaît dans une page » est ambigu | **Retenu** dans les messages et les commentaires : C22 nomme le **fichier de la sortie de production**, jamais une source Markdown. |
| P2 | Le message devrait donner le numéro de ligne | **Retenu.** C'est déjà ce que rend `pdf_confront`, et le message de C21 en donne la forme : « motif ligne N », jamais le motif. |

#### Ce que la revue n'a pas vu, et qui est le plus dangereux

Aucune lentille n'a relevé que **`pdf_confront` cherche avec `grep -F`, ligne par ligne, dans du
texte brut**. C'est correct pour le texte d'un PDF ; appliqué tel quel à du HTML, c'est le défaut
qui a coûté **huit tours de revue** à la PR n° 98 (story 9.1, contrôle C23) :

- Hugo échappe en entités (`&#39;`, `&amp;`), le JSON-LD sérialisé par Go écrit `\u0026`, le
  minifieur redécode une partie, `libxml2` réécrit encore autrement — une même chaîne a **six**
  sérialisations constatées, et celle qu'on oublie est celle qui fuite ;
- le rendu de production est **minifié** : un motif écrit sur deux lignes dans la source arrive sur
  une seule, et l'inverse est vrai aussi — un `grep` ligne à ligne ne voit jamais une chaîne à
  cheval.

C23 a résolu exactement cela, avec `decoder_echappements` et `normaliser_blancs`. **Décision :** ces
deux fonctions sortent de `scripts/checks/legal-address.sh` vers `scripts/checks/lib.sh`, C23 les y
lit désormais, et C22 normalise chaque fichier avant de le confronter. Elles vont dans `checks/lib.sh`
et non dans un `lib/` partagé avec le garde-fou : ce dernier est recopié sur la forge, et y ajouter
un fichier imposerait un redéploiement du hook que cette story ne prévoit pas.

#### La décision d'architecture : expurger les occurrences, pas dispenser le motif

Le critère dit : « un motif y apparaît **contenu dans** une valeur `HUGO_LEGAL_*` injectée, puis
**hors de ces valeurs** → C22 passe, puis échoue ». Deux lectures sont possibles, et la naïve est
fausse :

- **(a) dispenser le motif** — s'il est sous-chaîne d'une valeur légale, on l'admet partout sur la
  page. La commune de résidence écrite dans un paragraphe de la page légale passerait alors sans
  un mot, alors que c'est précisément la fuite que FR-33 vise ;
- **(b) expurger les occurrences** — retirer du texte de la page **les huit valeurs injectées**,
  puis confronter ce qui reste. Une occurrence à l'intérieur d'une valeur disparaît avec elle ;
  la même chaîne écrite ailleurs subsiste et fait échouer le contrôle.

**(b) est retenue** : c'est ce que le critère décrit mot pour mot, et la seule qui distingue une
occurrence légitime d'une fuite. L'expurgation se fait sur le texte **déjà décodé et normalisé**,
avec les valeurs elles-mêmes normalisées : sinon une valeur échappée dans la page ne serait pas
reconnue et sa propre occurrence légitime ferait échouer la mise en ligne.

## Ce qui est livré

| Fichier | Ce qu'il porte |
| --- | --- |
| `scripts/checks/output-patterns.sh` | C22. Découvert seul par `check.sh`, qui n'est pas modifié. |
| `scripts/checks/lib.sh` | `decoder_echappements` et `normaliser_blancs`, déplacées depuis `legal-address.sh` ; `checks_page_de_url`, extraite de `release-pages.sh` ; les trois documentées en tête. |
| `scripts/checks/legal-address.sh` | Lit les deux filtres depuis `lib.sh`. Aucun changement de comportement : `scripts/tests/test-legal-address.sh` passe **sans modification** (19 cas). |
| `scripts/checks/release-pages.sh` | Appelle `checks_page_de_url` au lieu de sa copie locale. Aucun changement de comportement : `scripts/tests/test-release-pages.sh` passe **sans modification** (35 cas). |
| `scripts/tests/test-output-patterns.sh` | 36 cas, un par garde, plus les deux critères d'acceptation. |
| `docs/procedures/check.md` | Ligne C22 dans « Contrôles livrés », C22 nommé dans la règle de niveau, et deux puces neuves : « lire une chaîne dans une sortie de Hugo » et « confronter à la liste des motifs ». |
| `_bmad-output/implementation-artifacts/deferred-work.md` | Deux entrées : le repli des caractères (apostrophe typographique, espaces insécables) et la troisième copie de la résolution d'URL restée dans C12. |

La sortie de production compte 29 fichiers ; C22 en confronte 23. Les six autres sont les quatre variantes du portrait (C20) et les deux CV publiés (C21).

## Le brief des jumeaux (point 19) : les treize gardes, une par une

**Aîné 1 — `scripts/checks/legal-address.sh` (C23), pour la structure.**

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 1 | Valeur cherchée absente = **anomalie**, jamais un succès | **Oui, deux fois.** La liste des motifs absente ou vide est une anomalie (et c'est la différence assumée avec C21, ligne A7 du triage) ; l'absence de toute valeur `HUGO_LEGAL_*` en est une autre, pour la raison exacte de C23 — sans elles l'exception d'AD-9 ne s'applique nulle part et les valeurs légitimes feraient échouer la mise en ligne. |
| 2 | `decoder_echappements` | **Oui, et c'est le cœur de la story.** C22 lit les mêmes pages que C23. La fonction est **déplacée**, pas recopiée. En l'éprouvant sur le vrai build, on constate qu'il lui manquait la seule entité que la production émet vraiment : `&rsquo;`, 236 fois. Ajoutée. |
| 3 | `normaliser_blancs` | **Oui**, et pour une raison de plus que chez l'aîné : c'est elle qui ramène chaque fichier à **une seule ligne**, et c'est de là que `grep` tire sa sûreté (garde 4). |
| 4 | Comparaison `[[ $x == *"$y"* ]]` plutôt que `grep -F`, parce que grep travaille ligne par ligne | **Non, et c'est la garde à ne pas reprendre en aveugle.** C22 ne peut pas comparer en bash : il confronte **n** motifs qu'il ne connaît pas, pas une valeur unique, et la recherche partagée (`pdf_confront`) emploie `grep`. C'est sûr **uniquement parce que la normalisation précède** : après elle, le fichier n'a plus qu'une ligne, donc aucune chaîne ne peut être à cheval. Le raisonnement est écrit dans le script et éprouvé par `case_output_patterns_motif_coupe_par_un_saut_de_ligne_est_vu`, qui écrit le motif coupé là où le minifieur l'aurait recollé. |
| 5 | Le fichier est lu **avant** la condition, jamais dans un `if` | **Oui.** `contenu=$(…) \|\| checks_die` : une lecture en échec est une anomalie, jamais « aucun motif ». Cas `…_fichier_illisible_est_une_anomalie`. **Et le cadet prend un garde que l'aîné n'a pas** : `tr -d '\0'` au lieu de `cat`, parce qu'une substitution de commande coupe la chaîne au premier octet nul — c'est l'entrée de `deferred-work.md` ouverte par la story 9.7 contre `legal-address.sh:217`, appliquée ici ; elle reste ouverte pour C23, que cette story n'a pas le droit de modifier. |
| 6 | Le code de `checks_xpath` est **propagé**, jamais transformé en valeur vide | **Non applicable tel quel** : C22 ne lit aucun nœud, il confronte le fichier entier. La garde équivalente est la propagation du code de `checks_find` (`\|\| exit $?`), qui est prise — cas `…_parcours_impossible_est_une_anomalie`, où un dossier illisible arrête le contrôle au lieu de lui faire lire la liste tronquée que `find` a eu le temps d'écrire. |
| 7 | La liste des fichiers est éprouvée **non vide** avant la boucle | **Oui**, et une garde de plus que l'aîné : « non vide » ne suffit pas quand tout peut être exclu. Un `public/` qui ne contiendrait que des images et les deux CV rendrait 0 sans avoir rien confronté. Deux cas : `…_sortie_vide_est_une_anomalie` et `…_sortie_tout_exclue_est_une_anomalie`. |
| 8 | Il balaie aussi les sorties **non HTML** | **Oui, et davantage.** C23 balaie « tout sauf `*.html` et `*.pdf` » ; C22 balaie **tout**, et n'écarte que ce qu'un autre contrôle couvre, par les listes uniques du dépôt. Cas `…_motif_dans_une_sortie_non_html`, `…_les_images_ne_sont_pas_lues`, `…_les_cv_publies_ne_sont_pas_lus`, `…_un_autre_pdf_est_lu`. |

**Aîné 2 — `scripts/checks/pdf.sh` (C21), pour la mécanique des motifs.**

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 9 | Deux temporaires, tableau `temporaires`, `trap … EXIT` ; la variable du chemin n'est jamais celle qui dit « la liste est-elle vide » | **Oui, à l'identique.** `pdf_confront` exige les deux fichiers. Chez C22 le piège est même désamorcé en amont — une liste vide est une anomalie, donc rien ne pousse à vider la variable pour dire « aucun motif ». Trois cas comptent les restes après un succès, après un écart et après une anomalie. |
| 10 | `PRIVATE_PATTERNS_FILE` avec repli sur `docs/private/forbidden-patterns.txt`, racine déduite de l'emplacement du script | **Oui, la variable et le repli ; non, la conséquence.** Chez C21 un fichier absent laisse jouer les autres règles ; chez C22 c'est une anomalie. La racine vient toujours de `BASH_SOURCE`, jamais de `git` : un contrôle tourne sans dossier `.git`. |
| 11 | Deux `grep` séparés, chacun avec son test de code, jamais `a && b \|\| die` | **Oui, tel quel** : la préparation des deux fichiers de motifs est la même, et `((rc <= 1))` distingue « aucune ligne retenue » d'une lecture en échec. |
| 12 | Le code de `pdf_confront` : `0` rien, `1` trouvé, **tout autre code est un échec de recherche** | **Oui, tel quel**, y compris le cas de test qui le fabrique en dégradant la bibliothèque dans un arbre jetable (`pdf_confront() { return 7; }`). Un garde-fou ne s'ouvre pas en cas de panne. |
| 13 | `local x=$(…)` rend le code de `local` : déclarer puis affecter | **Oui**, dans `confronter`. Mutation M11 : en fusionnant les deux, `code` reste 0 et le contrôle ne détecte plus rien du tout. |

Deux gardes sont donc écartées en connaissance de cause (4 et 6), et trois sont **ajoutées** que ni l'un ni l'autre ne portait : la garde « tout est exclu » (7), `tr -d '\0'` (5), et le tri des valeurs légales par longueur décroissante, qui n'existe chez aucun aîné parce qu'aucun n'expurge.

## Chaque garde, éprouvée sans elle (point 9)

Vingt-deux gardes retirées une par une, la suite relancée à chaque fois. **Aucune n'est décorative** : chacune a fait échouer au moins un cas.

| Mutation | Ce qui échoue alors |
| --- | --- |
| M1 le contrôle juge à tous les niveaux | `…_hors_release_saute_en_le_disant` |
| M2 liste absente : retour silencieux | `…_liste_absente_est_une_anomalie` |
| M3 la garde « liste vide » (`-s`) retirée | `…_liste_sans_motif_est_une_anomalie` |
| M4 la garde « aucune valeur légale » retirée | `…_valeurs_legales_absentes_est_une_anomalie` |
| M5 valeurs expurgées dans l'ordre d'arrivée | `…_une_valeur_courte_ne_decoupe_pas_une_longue` (et, avec elle, tout cas dont la page légale est intacte) |
| M6 la garde « aucune page légale » retirée | `…_aucun_temporaire_apres_une_anomalie` |
| M7 un nom sans point traité comme une extension | `…_un_fichier_sans_extension_est_lu` |
| M8 la casse de l'extension n'est plus repliée | `…_une_extension_en_majuscules_est_une_image` |
| M9 tout PDF écarté au lieu des deux CV | `…_un_autre_pdf_est_lu` |
| M10 un code inattendu vaut « rien trouvé » | `…_un_code_inattendu_nest_pas_un_fichier_propre` |
| M11 `local lignes=$(…)` fusionné | `…_aucun_temporaire_apres_un_ecart` : le contrôle ne détecte plus rien (attendu 1, obtenu 0) |
| M12 le code de `checks_find` avalé | `…_parcours_impossible_est_une_anomalie` |
| M13 la garde « liste de fichiers vide » retirée | `…_sortie_vide_est_une_anomalie` |
| M14 un fichier illisible vaut « aucun motif » | `…_fichier_illisible_est_une_anomalie` |
| M15 ni décodage ni normalisation | `…_motif_coupe_par_un_saut_de_ligne_est_vu` |
| M16 normalisation seule | `…_motif_echappe_par_hugo_est_vu` |
| M17 décodage seul | `…_motif_coupe_par_un_saut_de_ligne_est_vu` |
| M18 valeurs légales non normalisées | `…_valeur_legale_minifiee_est_expurgee` |
| M19 la page légale dispensée au lieu d'être expurgée | `…_page_legale_motif_hors_valeur_echoue` |
| M20 l'expurgation appliquée à toutes les pages | `…_valeur_legale_sur_une_autre_page_echoue` |
| M21 le `trap` retiré | `…_aucun_temporaire_apres_un_ecart` |
| M22 la garde « aucun fichier lu » retirée | `…_sortie_tout_exclue_est_une_anomalie` |
| M23 la ligne `&rsquo;` du décodeur retirée | `…_motif_a_apostrophe_typographique_est_vu` |

Deux mutations ont d'abord paru inoffensives, et ne l'étaient pas :

- **M11**, écrite d'abord sans retirer la ligne d'origine, n'a rien fait échouer — la mutation était fausse, pas la garde. Rejouée correctement, elle éteint la détection entière.
- **M5** fait échouer le premier cas venu plutôt que celui qu'elle vise, parce que la fixture nominale porte déjà une valeur courte contenue dans une longue. Rejouée sur le cas visé seul : `attendu : 0 / obtenu : 1`, avec le signalement `motif privé hors des valeurs légales injectées` sur les deux pages légales.

## Essais sur le vrai build (point 16)

Les fixtures imitent la production ; elles ne la remplacent pas. Les essais ci-dessous tournent sur la **vraie sortie**, minifiée, avec une liste de motifs **factice** (`VILLEFACTICE-SUR-ESSAI`, `MOTIF-FACTICE-DEUX`) et une adresse légale factice injectée par l'environnement. Aucun motif réel n'a été lu ni affiché.

**Essai 1 — l'occurrence contenue dans une valeur injectée passe.** Build complet avec `HUGO_LEGAL_PUBLISHER_ADDRESS="1 rue de l'Essai & Cie, 00000 VILLEFACTICE-SUR-ESSAI"`, dont la commune **est** un motif de la liste :

```
output-patterns: 23 fichier(s) de public confrontés à la liste des motifs ; aucune occurrence hors des valeurs légales injectées des mentions légales.
check: 11 contrôle(s) passés, niveau release.
```

La page rendue, mesurée : `>Adresse</dt><dd class=legal-list__value><address>1 rue de l'Essai & Cie, 00000 VILLEFACTICE-SUR-ESSAI</address></dd>` — deux lignes pour tout le fichier.

**Essai 2 — la même chaîne, hors valeur injectée, sur la même page légale.** Copie de la sortie, un paragraphe ajouté avant le `<h1>` :

```
mentions-legales/index.html: C22 : motif privé hors des valeurs légales injectées (contenu masqué) ; motif ligne 3
code=1
```

**Essai 3 — les motifs ailleurs.** Un motif dans l'accueil français, un autre dans une page anglaise, un troisième dans `robots.txt` :

```
en/about/index.html: C22 : motif privé dans la sortie de production (contenu masqué) ; motif ligne 3
index.html: C22 : motif privé dans la sortie de production (contenu masqué) ; motif ligne 4
robots.txt: C22 : motif privé dans la sortie de production (contenu masqué) ; motif ligne 4
code=1
```

Les deux critères d'acceptation sont donc montrés sur la vraie sortie, pas seulement sur des fixtures : la page est nommée, le motif ne l'est jamais, son numéro de ligne l'est, et la même chaîne passe dans une valeur injectée puis échoue hors d'elle.

**Vérifications finales**, dépôt remis dans son état normal (valeurs légales réelles, liste réelle) :

```
scripts/tests/run.sh          → 628 cas réussis
scripts/check.sh              → 11 contrôle(s) passés, niveau standard
scripts/check.sh --release    → 11 contrôle(s) passés, niveau release
```

## Ce que la mesure a trouvé, et que personne n'avait demandé

**`&rsquo;` est la seule entité que la sortie de production émet, et le décodeur ne la connaissait pas.** En inventoriant les entités de `public/` — 236 occurrences, toutes `&rsquo;`, aucune autre —, on constate que Hugo convertit l'apostrophe droite du Markdown en apostrophe typographique et que le minifieur l'écrit en entité. Un motif portant `’` n'était donc reconnu dans **aucune** page, alors que le décodeur couvrait six sérialisations qui, elles, n'apparaissent nulle part dans le rendu minifié : la seule écriture réelle était celle qui manquait. Mesuré, pas déduit :

```
liste = « aujourd’hui, ce »      → code 0, aucun motif trouvé   (avant correctif)
liste = « aujourd&rsquo;hui, ce » → index.html signalé            (même page, même build)
```

Trois spellings ajoutés au décodeur (`&rsquo;`, `&#8217;`, `&#x2019;`, et les trois de `&lsquo;`), un cas de test qui échoue sans eux, et le résidu — une différence de **caractère** et non d'écriture, apostrophe droite contre typographique, espace ordinaire contre U+00A0 ou U+202F — consigné dans `deferred-work.md` avec sa mesure, parce que le refermer demande de replier **les deux côtés**, donc de transformer les fichiers temporaires de motifs, ce que ni C21 ni le garde-fou ne font.

C'est une modification de comportement de la fonction que C23 partage : elle ne peut qu'**ajouter** des correspondances, ne casse aucun des 19 cas de `test-legal-address.sh`, et fait de C23 un contrôle un peu moins aveugle qu'hier.

## Écarts au brief

1. **`scripts/checks/release-pages.sh` est modifié**, alors que le brief ne le listait pas. C22 avait besoin de la résolution « RelPermalink → chemin du fichier », qui existait déjà en deux exemplaires (`release-pages.sh`, `links.sh`) ; en écrire un troisième était le mécanisme exact du constat A1 de la rétrospective de l'epic 3 et de la règle « une parade s'écrit une fois » (`shell-scripts.md`). La fonction est donc extraite dans `checks/lib.sh`, C15 l'appelle, et son comportement est inchangé — `test-release-pages.sh` passe sans modification. C12 garde la sienne, entrée ouverte dans `deferred-work.md`.
2. **`scripts/checks/lib.sh` reçoit une troisième fonction**, `checks_page_de_url`, pour la même raison.
3. **Le décodeur partagé gagne trois entités** (point précédent). Le brief disait « aucun changement de comportement » pour `legal-address.sh` ; le fichier n'est pas touché au-delà du déplacement, son test passe sans modification, mais la fonction qu'il appelle décode davantage qu'hier. C'est assumé et mesuré.
4. **La liste des huit `HUGO_LEGAL_*` n'est pas écrite dans le contrôle** : les valeurs sont relevées par leur **préfixe** (`compgen -v`). Les huit noms vivent déjà dans `scripts/env.sh` et dans `scripts/checks/content.sh` ; une troisième copie était la faute du point 19. Une variable manquante ne peut pas créer de faux négatif — sa valeur n'est alors pas dans la page non plus, puisque le build et le contrôle passent par le même chargeur — et si les deux environnements divergeaient, la valeur resterait dans la page sans être expurgée et le contrôle échouerait bruyamment.

## Revue du code

### 25/09/2026 — `f36e814` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 117. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 64916a5f117eadd7f796e5cd

##### Revue BMAD

###### Lentille : Adverse (Edge cases & failles)
- **NON BLOQUANT** : `scripts/checks/output-patterns.sh` (lecture de `checks_find` ligne 81 approx.)
  - *Trigger condition* : Un fichier statique dans `public/` contient un saut de ligne dans son nom.
  - *Guard snippet* : Utiliser `checks_find "$public" -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' relatif; do`
  - *Potential consequence* : Le saut de ligne coupe le nom en deux lors de la boucle `read`, le contrôle cherche un fichier incomplet, échoue à le lire et déclenche une anomalie bruyante (code 2) arrêtant la CI.

###### Lentille : Failles de vérification (Verification-gap)
- **NON BLOQUANT** : `scripts/checks/links.sh` (C12)
  - *Trigger condition* : C12 conserve sa propre résolution de chemin (`page_visee`) au lieu d'adopter `checks_page_de_url`, alors que la nouvelle fonction mutualisée a été extraite spécifiquement pour cet usage (bien que documenté dans `deferred-work.md`).
  - *Guard snippet* : Remplacer la logique équivalente dans `links.sh` par un appel à `checks_page_de_url`.
  - *Potential consequence* : La duplication de la logique de résolution d'URL perdure. Un changement futur dans `checks_page_de_url` pourrait ne pas être répercuté dans C12.

##### Couche propre au projet

- **NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée. L'approche d'expurgation des valeurs `HUGO_LEGAL_*` (au lieu de dispenser le motif) est la seule correcte pour garantir qu'une même chaîne écrite manuellement ailleurs sur la page de mentions légales soit bien bloquée.
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge. Les fixtures de test s'appuient exclusivement sur des motifs factices (`VILLEFACTICE-SUR-ESSAI`).
- **NON BLOQUANT** : Skill, procédure et script concordent. Le fichier `docs/procedures/check.md` cite les exactes commandes implémentées (`decoder_echappements`, `normaliser_blancs`, `pdf_confront`, C22).
- **NON BLOQUANT** : Le changement est cohérent avec AGENTS.md et les décisions d'architecture. Le tri des valeurs légales par longueur décroissante (insertion sort) pour prévenir le découpage d'une valeur longue par une valeur courte prouve un excellent souci du détail et valide l'architecture défensive.
- **NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. L'usage des indirections dynamiques (`${!nom-}`) et de la substitution protégée (`${texte//"$valeur"/ }`) échappe brillamment aux erreurs `set -u` et à l'injection de glob. Les échecs de commandes (`grep`, `jq`, `tr`) sont soit protégés par des codes d'erreur assumés (`rc`), soit renvoyés vers le gestionnaire d'anomalies `checks_die`.

VERDICT: NON BLOQUANT — aucune

### 25/09/2026 — `510a334` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 117. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 60807d872434e0e9234f9fc7

##### Lentille : Adverse (Edge cases & failles de vérification)

- **NON BLOQUANT** : `scripts/checks/output-patterns.sh` (Périmètre du manifeste).
  - *Trigger condition* : Le dossier de travail ne contient aucun manifeste (le build n'a rien produit), la fonction `checks_manifests` ne renvoie aucune chaîne.
  - *Guard snippet* : Ajouter une vérification d'existence (`[[ -n $manifeste ]] || continue`) dans la boucle `for manifeste in "${fichiers_manifeste[@]}"; do`.
  - *Potential consequence* : La commande `mapfile` produit un tableau contenant un seul élément vide. L'appel à `jq` tentera alors d'ouvrir un fichier sans nom, ce qui crachera une erreur système sur la sortie d'erreur standard (`jq: error: Could not open file`) avant l'arrêt maîtrisé par `checks_die`, polluant ainsi le journal de la CI.

- **NON BLOQUANT** : `scripts/checks/lib.sh` (Fonction `normaliser_blancs`).
  - *Trigger condition* : Un fichier statique non minifié, copié tel quel dans `public/`, utilise des fins de ligne CRLF (`\r\n`) héritées d'un environnement Windows.
  - *Guard snippet* : Inclure le retour chariot `\r` aux caractères normalisés en espace : `tr '\r\n\t' '  ' | tr -s ' '`.
  - *Potential consequence* : Le retour chariot `\r` survit au filtre et subsiste dans la chaîne. Si un motif privé est adjacent à ce saut de ligne ou coupé par lui, `pdf_confront` (qui repose sur un `grep` après normalisation) pourrait ne pas détecter la chaîne. Ce risque de faux négatif est classé non bloquant car l'architecture du projet impose un environnement de développement et de CI strictement natif Linux (décision AD-17), rendant ce cas théorique dans les conditions d'exécution actuelles.

##### Couche propre au projet

- **NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée. L'approche consistant à expurger les valeurs légales du texte cible *avant* la confrontation garantit le blocage d'un motif si la même chaîne est malencontreusement reproduite hors de la valeur injectée sur la page légale.
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge. Les fixtures de tests emploient systématiquement des motifs et des variables d'environnement factices (`VILLEFACTICE-SUR-ESSAI`, `MOTIF-FACTICE-DEUX`). 
- **NON BLOQUANT** : Skill, procédure et script concordent. Les ajouts du script C22, les mécaniques de filtres `decoder_echappements` et `normaliser_blancs`, de même que l'usage de la fonction partagée `pdf_confront`, sont formellement documentés dans `docs/procedures/check.md`.
- **NON BLOQUANT** : Le changement est cohérent avec AGENTS.md et les décisions d'architecture. L'extraction de la fonction `checks_page_de_url` répond à la règle « une parade s'écrit une fois » (issue de la rétrospective de l'epic 3). L'usage des indirects dynamiques `compgen -v` pour lire les variables légales respecte le point 19 visant à empêcher l'émergence d'une deuxième vérité codée en dur. L'algorithme de tri par insertion de la longueur des valeurs pour pallier l'ordre d'expurgation prouve un excellent respect de l'architecture défensive.
- **NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Les échecs normaux de commandes (`grep` pour détecter un résultat, erreurs de `jq`) sont judicieusement encadrés par des captures de code de retour conditionnelles (`|| rc=$?` et test `((rc <= 1))`) ou dirigés vers le gestionnaire `checks_die` afin de préserver une visibilité intégrale.

VERDICT: NON BLOQUANT — aucune

### 25/09/2026 — `c927497` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 117. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 04f1ed55bdb6f300bbab349f

##### Lentille : Edge-Case Hunter
Aucun cas limite non géré trouvé. Les limites d'exécution (noms de fichiers tronqués par un saut de ligne, absence de variables légales, absence de build) sont soit formellement couvertes par des gardes (arrêt brutal et anomalies documentées), soit explicitement identifiées et consignées dans `deferred-work.md`.

##### Lentille : Verification-Gap
Aucune faille de vérification trouvée. Les évolutions comportementales subtiles, comme la prise en charge des caractères `\r` (CRLF) ignorés par Hugo sur les fichiers Windows et l'ajout de l'apostrophe typographique (`&rsquo;`), sont adossées à des cas de test dédiés qui échoueraient sans les gardes correspondantes.

##### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (l'expurgation des occurrences `HUGO_LEGAL_*` est précisément implémentée pour ne cibler que le contenu légitime sans autoriser la fuite du même motif écrit ailleurs).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (tous les tests reposent sur des constantes factices de type `VILLEFACTICE-SUR-ESSAI`).
- NON BLOQUANT : Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure (la documentation `check.md` décrit précisément les commandes mutualisées comme `decoder_echappements`).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (les failles décelées lors des premières passes de cette même story ont fait l'objet de nouvelles corrections et de nouvelles revues, respectant le processus du flux de développement).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (les codes de retour de `grep`, `checks_find` ou `pdf_confront` sont capturés dans des variables ou évalués via des instructions de branchement conditionnel directes).

VERDICT: NON BLOQUANT — aucune

### 25/09/2026 — `ea0ca0b` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 117. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0fc799d13f20b76d1faae6e8

##### Revue BMAD

###### Lentille : Edge-case-hunter
- **NON BLOQUANT** : Aucune faille ni cas limite non géré n'a été trouvé. Les limites d'exécution identifiées (noms de fichiers tronqués par un saut de ligne, absence de variables légales, absence de build) sont explicitement protégées par des gardes déclenchant des anomalies bruyantes, ou traitées et documentées dans `deferred-work.md`. L'utilisation des indirections dynamiques, de la substitution de chaînes littérales, et du tri par longueur décroissante démontrent une prise en compte exhaustive des cas limites.

###### Lentille : Verification-gap
- **NON BLOQUANT** : Aucune faille de vérification. Les tests de `test-output-patterns.sh` couvrent toutes les configurations (motifs échappés par Hugo en entités, motifs sérialisés en JSON-LD, motifs coupés par un retour chariot ou un saut de ligne). Chaque garde (comme l'expurgation par substitution) est accompagnée de tests démontrant son efficacité.

##### Couche propre au projet

- **NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée. L'approche d'expurgation des occurrences `HUGO_LEGAL_*` plutôt que la dispense pure et simple du motif garantit que le contrôle bloque bien une chaîne interdite reproduite hors de la valeur injectée.
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge. Les fixtures de test utilisent exclusivement des identifiants et des constantes factices (`VILLEFACTICE-SUR-ESSAI`, `Nom Factice`), et le script prend soin de ne jamais imprimer le motif trouvé dans la console (seulement son numéro de ligne).
- **NON BLOQUANT** : Skill, procédure et script concordent. La documentation `docs/procedures/check.md` reflète exactement l'implémentation du contrôle C22, mentionnant l'usage de `decoder_echappements`, `normaliser_blancs`, `pdf_confront`, et `checks_page_de_url` en précisant le niveau d'exécution.
- **NON BLOQUANT** : Le changement est cohérent avec AGENTS.md et les décisions d'architecture. L'extraction de `checks_page_de_url` respecte la règle « une parade s'écrit une fois », et la lecture des variables depuis l'environnement respecte l'unicité de la vérité (point 19 d'AGENTS.md).
- **NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Les commandes potentiellement faillibles (`grep`, `jq`, `checks_find` et `pdf_confront`) capturent correctement les codes d'erreurs anticipés via des alternatives de contrôle, propageant proprement les arrêts avec `checks_die` ou `exit`.

VERDICT: NON BLOQUANT — aucune

## Décisions

### Les quatre écarts de la sous-tâche, jugés

| Écart | Jugement |
| --- | --- |
| `release-pages.sh` modifié sans être au brief : la résolution « URL → chemin » extraite en `checks_page_de_url` | **Accepté.** Une troisième copie de cette règle aurait reconstitué exactement le constat A1 de la rétrospective de l'epic 3, où le même correctif avait dû être appliqué trois fois. `test-release-pages.sh` et `test-links.sh` passent sans modification. C12 garde la sienne, enveloppée dans une résolution plus large : entrée de `deferred-work.md`, à reprendre dans une story qui rouvre déjà ce contrôle. |
| Une troisième fonction dans `checks/lib.sh` | **Accepté**, même raison. |
| Le décodeur partagé décode davantage qu'avant (`&rsquo;`, `&lsquo;`), donc le comportement de C23 change | **Accepté, et c'est le meilleur apport de la story.** Voir ci-dessous : refuser, c'était garder sciemment un trou mesuré. |
| Les huit `HUGO_LEGAL_*` relevées par préfixe (`compgen -v`) au lieu d'être énumérées | **Accepté.** Point 19 : la liste vit dans `scripts/env.sh`, et la recopier en ferait une deuxième vérité — c'est la faute que l'action 55 de la rétrospective de l'epic 9 doit encore corriger dans `content.sh`. Une variable manquante ne peut produire qu'un échec bruyant, jamais un faux négatif. |

### Le faux négatif que cette story a trouvé dans C23

Le décodeur hérité de C23 couvrait six sérialisations — entités décimales, hexadécimales, nommées,
séquences `\uXXXX` du JSON-LD de Go — toutes déduites de ce qu'un encodeur *peut* produire. Mesuré
sur la sortie réelle par l'orchestrateur, indépendamment de la sous-tâche :

```
$ grep -roh '&[a-zA-Z]\+;' public --include='*.html' | sort | uniq -c
    236 &rsquo;
```

**`&rsquo;` est la seule entité que la production émette**, 236 fois, et c'était la seule que le
décodeur ignorait. Vérifié en retirant la ligne du correctif et en rejouant le contrôle sur une
liste de motifs contenant une apostrophe typographique :

- avec la ligne : `index.html: C22 : motif privé dans la sortie de production (contenu masqué) ; motif ligne 1` ;
- sans la ligne : `aucune occurrence`, **code 0**, sur la page qui porte pourtant le motif.

Un garde-fou vert sur une fuite réelle. C'est le point 10 d'AGENTS.md pris à revers : une règle
écrite d'après ce qu'un outil *devrait* produire, jamais confrontée à ce qu'il produit. Six formes
imaginées correctes, la septième réelle absente. Le trou existait dans C23 depuis la story 9.1 et
aucune des huit revues de la PR n° 98 ne l'a vu, parce que toutes raisonnaient sur la liste des
formes possibles au lieu de lire la sortie.

Le résidu — une différence de **caractère** et non d'écriture (`'` contre `’`, espace contre U+00A0
ou U+202F) — part dans `deferred-work.md` avec sa mesure : le fermer suppose de replier les deux
côtés, donc de transformer aussi les fichiers de motifs, ce que ni C21 ni le garde-fou ne font. Le
décider pour les trois est un arbitrage, pas un correctif de cette story.

### Vérification du travail de la sous-tâche (point 22)

Rejoué par l'orchestrateur sur le dépôt, sans reprendre ses mesures :

| Vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 628 cas réussis |
| `scripts/tests/test-legal-address.sh` modifié ? | non — 19 cas, fichier intact |
| `scripts/check.sh` / `--release` | 11 contrôles, code 0 des deux côtés |
| motif absent de la sortie | code 0 |
| motif sur l'accueil | code 1, page nommée, motif jamais recopié |
| motif **contenu dans** la valeur légale injectée, page des mentions légales | code 0 |
| la **même chaîne ailleurs** sur cette page | code 1, `motif privé hors des valeurs légales injectées` |
| liste des motifs absente au niveau `release` | code **2** (anomalie) |
| entité `&rsquo;` réellement émise, décodeur mutilé | code 0 sur une fuite : le faux négatif est reproduit |

Le second critère d'acceptation — « passe, puis échoue » — est donc tenu et mesuré, pas affirmé.
Aucun motif réel n'a été lu, affiché ni écrit : tous les essais emploient une liste factice.

### Triage du rapport de code (point 20 : un verdict `pass` se triage comme un `block`)

**E1 — un nom de fichier de `public/` contenant un saut de ligne coupe la boucle `read`.
Constat réel, vérifié, et reporté plutôt que corrigé à moitié.** Reproduit par l'orchestrateur en
déposant un fichier au nom coupé dans une copie de `public/` :

```
scripts/checks/output-patterns.sh: ligne 276: …/pub4/note: Aucun fichier ou dossier de ce nom
output-patterns: lecture impossible de note : rien n'est affirmé.
rc=2
```

Le contrôle **refuse** (code 2) au lieu de passer : le garde-fou ne s'ouvre pas en cas de panne,
ce qui est précisément la propriété que le projet lui demande. C'est la différence avec le constat
B5 de la rétrospective de l'epic 5, où un nom non-ASCII **échappait** à C20 — un trou, pas un refus.

La correction n'est pas faite ici parce que **le même motif vit dans C23**, vérifié sur la même
sortie :

```
cat: …/pub4/note: Aucun fichier ou dossier de ce nom
legal-address: lecture impossible de note : rien n'est affirmé.
```

Corriger C22 seul et laisser C23 derrière serait exactement la faute du point 19, celle que l'epic 9
a payée trois fois sur quatre constats. Les deux passent ensemble, dans une story qui rouvre C23 :
entrée dans `deferred-work.md`, avec la mesure.

**E2 — C12 garde sa propre résolution d'URL.** Le relecteur note lui-même que c'est déjà consigné.
**Rien à faire** : l'entrée existe dans `deferred-work.md`, écrite pendant cette story, et dit
pourquoi C12 n'est pas rouvert ici (sa boucle de liens est chaude, une substitution de commande par
lien s'y paie).

**Les cinq lignes de la couche projet** sont des confirmations, non des constats : critères tenus
sans vider leur intention, aucune donnée privée commitée, procédure et script concordants,
cohérence avec `AGENTS.md` et les décisions d'architecture, aucune erreur silencieuse sous
`set -euo pipefail`. Aucune ne demande de changement, aucune n'est reportée.

### L'incident de CI, et la vérification qui n'en était pas une

La CI a refusé la première tête : `test-docs-headings.sh` a trouvé **deux titres `## Décisions`**
dans ce fichier — le squelette en portait un, l'ajout des décisions d'orchestrateur un second. La
garde écrite après la rétrospective de l'epic 4, contre un document qui se duplique, a fait
exactement son travail.

Ce qui mérite d'être écrit n'est pas l'erreur mais **la vérification qui l'a manquée**. Avant de
commiter, l'orchestrateur avait lancé `bash scripts/tests/test-docs-headings.sh --list` et lu sa
sortie comme une validation : `--list` **énumère** les cas sans en exécuter aucun, et ne peut donc
pas échouer. La suite complète, elle, avait bien tourné — mais **avant** l'ajout de la section
fautive. Deux vérifications, aucune ne portait sur l'état final du fichier.

C'est la forme la plus discrète du contrôle qui ne contrôle rien : non pas une garde absente ou mal
écrite, mais une garde invoquée d'une manière qui ne peut pas la faire échouer. Le point 9 demande
de lancer un test une fois **sans** sa garde pour le voir échouer ; le corollaire tient pour celui
qui lance le test — une commande dont on n'a jamais vu l'échec possible ne prouve rien.

Le job de contrôles a ensuite été rejoué **en entier dans le conteneur de la CI**
(`scripts/ci/checks-job.sh`) avant de repousser : 628 cas, 11 contrôles, aucun échec.

Cette correction arrive **après** la revue du code, et elle n'entre pas dans ce que le point 4
autorise à un commit de statut — elle retire une ligne du fichier de story et corrige une référence
dans `deferred-work.md`. Elle part donc dans son propre commit, et **la revue du code est relancée**
sur la nouvelle tête. La règle vaut surtout quand le changement paraît petit.

Deux références de ligne rendues fausses par cette PR sont corrigées au passage (point 8) :
l'entrée de la story 9.7 visait `legal-address.sh:217`, où vivait le `cat` sans `tr -d '\0'` ; le
déplacement des deux filtres vers `checks/lib.sh` l'a ramené à la ligne 180.

### Triage de la seconde revue du code (`510a334`)

**E3 — « aucun manifeste : `mapfile` rend un élément vide et `jq` crache une erreur système ».
RÉFUTÉ par la mesure.** `checks_manifests` porte déjà la garde et meurt **avant** la boucle :

```
$ CHECK_WORK_ROOT=<dossier vide> … bash scripts/checks/output-patterns.sh
output-patterns: aucun manifeste dans <dossier vide> : le format checks n'a pas été émis.
rc=2
```

Aucune erreur de `jq`, aucun journal pollué : un message propre et le code 2. Le relecteur a lu la
boucle sans voir la garde qui la précède, et ne peut pas lancer le script — c'est la classe de
constat que le point 20 apprend à réfuter sur preuve plutôt qu'à ignorer.

**E4 — le retour chariot survit à `normaliser_blancs`. CONFIRMÉ, et c'était un faux négatif.**
Le relecteur le donnait pour théorique au motif que la CI est native Linux. La mesure dit autre
chose : Hugo ne produit pas de CRLF, mais il **copie sans les toucher** les fichiers de `static/`,
et ce dépôt porte déjà des artefacts Windows (`*:Zone.Identifier` dans `docs/private/context/`).
Même contenu, même motif, deux fins de ligne :

```
CRLF : aucune occurrence                                                   rc=0
LF   : note-windows.txt: C22 : motif privé … ; motif ligne 1               rc=1
```

Un garde-fou vert sur une fuite, **exactement la classe du `&rsquo;`** que cette même story venait
de fermer — une écriture non couverte, découverte une ligne plus loin. Le point 18 dit qu'un constat
d'une classe connue est un ordre de balayage, pas une ligne à classer : le corriger coûtait un
caractère, et le reporter aurait contredit tout ce que cette story écrit par ailleurs.

Correctif : `tr '\r\n\t' '   '` dans `checks/lib.sh`, donc pour C22 **et** C23. Cas de test
`output_patterns_motif_coupe_par_un_crlf_est_vu`, lancé une fois sans la garde pour le voir
échouer — `attendu : 1 / obtenu : 0`.

**Les cinq lignes de la couche projet** sont des confirmations, non des constats : critères tenus,
aucune donnée privée, procédure et script concordants, cohérence avec `AGENTS.md`, aucune erreur
silencieuse. Aucune ne demande de changement.

Ce correctif arrive lui aussi après une revue : **la revue du code est relancée une troisième fois**.

### Triage de la troisième revue du code (`c927497`)

**Aucun constat.** L'edge-case-hunter ne trouve rien — il note que les limites d'exécution (nom de
fichier coupé, valeurs légales absentes, build absent) sont soit gardées, soit consignées dans
`deferred-work.md`. La lentille des trous de vérification ne trouve rien non plus, et relève que les
deux évolutions de comportement — `\r` et `&rsquo;` — portent chacune un cas de test qui échouerait
sans sa garde. Les cinq lignes de la couche projet sont des confirmations. Rien à retenir, rien à
reporter ; c'est écrit parce qu'un rapport se triage même quand il est vide.

### Le séquencement, et ce qu'il a coûté

Le commit de statut a été fait **avant** que la revue soit définitive : la story est passée à `done`
en `2f90433`, puis deux correctifs ont suivi, chacun relancé en revue. Le verrou de revue n'accepte
un commit de tête que s'il fait passer la story de `review` à `done`
(`scripts/lib/merge-gates.sh:107`) — un commit qui se contente d'ajouter un rapport après coup le
bloque, et chaque rapport consigné appellerait alors sa propre revue, sans fin.

La règle est bien faite : **le commit de statut est le seul commit autorisé après la revue, et c'est
lui qui porte le rapport et son triage.** C'est ce qui ferme la boucle. En le posant trop tôt, on
perd cette sortie.

Réparation, sans réécrire d'historique : la story repasse à `review` dans un commit ordinaire — qui
porte aussi les deux rapports et leurs triages —, la revue est relancée sur cette tête, puis un
unique commit de statut la ramène à `done`. La séquence légale est retrouvée au prix d'une revue.

### Triage de la quatrième revue du code (`ea0ca0b`)

**Aucun constat.** Les deux lentilles ne trouvent ni cas limite non gardé ni trou de vérification,
et relèvent que chaque garde porte un test qui la démontre — motifs échappés en entités, sérialisés
en JSON-LD, coupés par un saut de ligne ou par un retour chariot. Les cinq lignes de la couche
projet sont des confirmations. Rien à retenir, rien à reporter ; c'est écrit parce qu'un rapport se
triage même quand il est vide, y compris le quatrième.
