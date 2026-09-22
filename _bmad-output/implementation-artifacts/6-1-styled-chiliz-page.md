# Story 6.1 : Styled Chiliz page

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 6.1.

## Revue de spec

### 22/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `f5aae62`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: e82bf2d883aa4dea7e022f36

##### Rapport de revue (bmad-review)

**Lentille Adverse (Edge cases & Gaps)**
* BLOQUANT : Cible du lien « Retour au parcours » invérifiable. Le critère demande de suivre la disposition visuelle, mais ne vérifie pas la destination (`/#position-chiliz` exigée par EXPERIENCE.md). Conséquence : le retour au point exact du CV pourrait pointer vers `/` et casser l'expérience utilisateur. Correction : tester le `href` du lien.
* BLOQUANT : Absence d'introduction non testée. La décision d'architecture Q9 (via FR-9) exige que la page porte le titre « Chiliz » sans aucun texte d'introduction. Conséquence : le gabarit pourrait afficher par erreur le corps markdown du fichier `_index.md`. Correction : ajouter un critère vérifiant l'absence d'introduction.
* BLOQUANT : Texte dynamique du sommaire oublié. L'impact I-9 exige un libellé calculé par le gabarit (« Sommaire · N rubriques » avec gestion du singulier/pluriel), mais la check-list ne demande de vérifier que l'état fermé du `<details>`. Conséquence : risque fort d'implémenter un libellé statique ou d'oublier la règle d'accord. Correction : ajouter la vérification du compteur au critère.
* BLOQUANT : Validation du multi-cas impossible. La page de groupe est testée en rendu de travail avec le seul cas 02 disponible à ce stade (Epic 6). Conséquence : le cumul des rubriques dans le sommaire global et le filet séparateur `rule` entre les cas ne pourront pas être vérifiés. Correction : exiger du développeur de créer un second cas factice en local pour valider l'assemblage de la page de groupe.

**Lentille Structure**
* NON BLOQUANT : Spécificités du gabarit de groupe implicites. L'en-tête de section propre à la page Chiliz (filet plein cadre, métadonnée « Cas 02 ») est fondu dans le critère générique « suivent la disposition de DESIGN.md ». Conséquence : ces spécificités risquent d'être oubliées lors du développement.
* NON BLOQUANT : Apparence du marqueur `:target` non rappelée. Le critère vérifie que la cible est marquée, sans préciser l'attente visuelle (filet vert de 2 px dans la gouttière). Conséquence : le développeur pourrait implémenter un contournement approximatif (comme un changement de fond) satisfaisant le critère mais pas le design.

**Lentille Prose**
* NON BLOQUANT : Ambiguïté de l'incise finale. L'expression « (objectif de conception d'EXPERIENCE.md, check-list) » à la fin du critère sur le premier écran mobile n'est pas claire. Conséquence : la responsabilité de la vérification (critère automatisé ou simple rappel de passer la check-list manuelle) reste floue à la lecture.

##### À trancher avant d'implémenter
- Le lien « Retour au parcours » doit-il explicitement vérifier la présence de l'ancre `/#position-chiliz` dans les critères ?
- Faut-il ajouter un critère confirmant l'absence d'introduction sous le titre « Chiliz » (respect de Q9) ?
- La gestion dynamique et l'accord du titre du sommaire (« Sommaire · N rubriques ») doivent-ils figurer dans les critères d'acceptation ?
- Faut-il exiger dans la story la création d'un cas brouillon factice en local pour valider le comportement multi-cas de la page de groupe ?

### Tri de l'auteur (22/09/2026)

Premier rapport de revue de spec **classé** : l'action 6 de la rétrospective de l'epic 0, appliquée le matin même (`f5aae62`), demande désormais un BLOQUANT ou NON BLOQUANT par constat. Les quatre bloquants sont ci-dessous, avec ce que la vérification a donné.

**Refusé, parce que déjà vrai — la cible du lien « Retour au parcours ».** `layouts/_partials/career-url.html` est la seule construction de ce lien (AD-18) et rend `printf "%s#%s" .Site.Home.RelPermalink .Params.position`, donc `/#position-chiliz`. Le constat porte cependant juste sur un point : **rien ne garde ce comportement**. `links.sh` vérifie qu'une ancre interne résout, ce qu'un lien vers `/` sans ancre ferait tout aussi bien. Le critère est ajouté à la story et sera éprouvé.

**Refusé, parce que déjà vrai — l'absence d'introduction.** `layouts/cases/section.html` ne rend jamais le `.Content` du `_index` : il enchaîne le lien de retour, le titre, le sommaire et les sections. Même remarque : rien ne le garde, donc le critère est ajouté.

**Refusé, parce que déjà vrai — le libellé du sommaire.** `toc.html` compte les rubriques de tous les cas listés et passe le total à `i18n "toc" $count` ; `i18n/fr.yaml:28-30` et `i18n/en.yaml:27-29` portent les formes `one` et `other`. Le comptage et l'accord existent depuis la story 2.6. Le libellé change tout de même, mais pour une autre raison (voir l'arbitrage ci-dessous).

**Refusé, parce que la prémisse est fausse — le second cas factice.** Le relecteur écrit que la page de groupe ne pourra être éprouvée qu'avec le seul cas 02 et propose d'en fabriquer un faux en local. Les PR n° 72 et 73 ont commité les cas 03 et 04 en brouillon : le rendu de travail sort **trois** sections (`id="case-02"`, `id="case-03"`, `id="case-04"`), avec du contenu réel. C'est précisément pourquoi ces cas ont été commités avant l'epic 6 — « un gabarit bâti contre un contenu d'essai laisse passer ce qu'un contenu réel révèle » (corps de la PR n° 72). Un faux cas aurait donné une page plus courte et plus régulière que la vraie.

**Retenus — les trois non bloquants.** L'en-tête de section propre à la page de groupe (filet plein cadre, « Cas 02 » en `meta`, titre en `case-title`) et l'apparence de la marque `:target` (barre `accent` de 2 px dans la gouttière) étaient fondus dans un « suivent la disposition de `DESIGN.md` » qui ne désigne rien ; ils sont écrits. L'incise « (objectif de conception d'`EXPERIENCE.md`, check-list) » est remplacée par ce qu'elle voulait dire : la vérification est manuelle et se consigne dans `docs/accessibility.md`.

### Ce que la revue n'a pas vu, et que le troisième cas a révélé

Le relecteur avait raison de s'inquiéter du multi-cas, mais pas pour la raison qu'il donnait. Avec les trois cas réels, le sommaire collant de la colonne de marge **ne tient pas dans la fenêtre**. Mesuré dans un navigateur à 1 280 × 800, sur le rendu de travail, dans une colonne de 13,5 rem :

| Sommaire | Entrées | Hauteur |
|---|---|---|
| Production aujourd'hui, cas 02 seul | 7 | 368 px |
| Avec 03 et 04 publiés | 22 | **1 088 px**, soit 288 px de trop |

`DESIGN.md` dit « collant » et « liste visible » dès md, sans dire ce qui se passe quand la liste dépasse la fenêtre — la question ne se posait pas quand un seul cas existait. C'est le point 11 d'`AGENTS.md` en situation : une mesure faite sur le contenu du jour ne dit rien de celui de demain.

### Arbitrages d'Arnaud (22/09/2026)

- **Sommaire trop haut** : il **défile sur lui-même**, hauteur bornée par la fenêtre. Les trois autres voies lui ont été présentées avec leur coût — un `<details>` par cas (court en toute circonstance, mais un clic de plus et un écart au design validé), une liste limitée aux cas (on perd l'accès direct à une rubrique, que `DESIGN.md` prévoit), un sommaire non collant sur cette page (on perd la navigation permanente, et le comportement diverge de la page de cas seul).
- **Résumé du `<details>` sous md** : « Sommaire · 3 cas, 19 rubriques », les deux nombres accordés. Le comptage des seules rubriques avait été tranché le 17/09/2026, quand la page ne portait qu'un cas ; avec trois, il n'annonce plus rien que le lecteur voie. La page d'un cas seul garde le comptage des rubriques seules (story 6.2).

## Revue du code

### 22/09/2026 — `d208c95` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 79. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 61503e20a056d36f4bb48378

##### Rapport de revue (bmad-review & règles du projet)

**Lentille edge-case-hunter**
BLOQUANT : Plantage de Hugo si la page de groupe ne contient aucun cas. Dans `layouts/cases/section.html`, l'appel `{{ with index $cases 0 }}` lève une erreur fatale « index out of range » si `.RegularPages` est vide, ce qui empêche techniquement de créer une page de groupe avant d'y publier un premier cas.

**Lentille verification-gap**
BLOQUANT : Vérification trop permissive de la cible du lien de retour. Dans `scripts/checks/links.sh`, la validation `shell_grep -q '#position-'` s'assure uniquement que l'URL contient la bonne ancre, mais omet de vérifier qu'elle pointe bien vers l'accueil (`/` ou `/en/`). Le critère d'acceptation perd ainsi son intention première, puisqu'un lien erroné (ex: `/mauvaise-page#position-chiliz`) passerait la CI avec succès.

**Lentille prose & structure**
NON BLOQUANT : La rédaction des critères d'acceptation dans `epics.md` et les retours ajoutés à `accessibility.md` sont clairs, argumentés et justifient bien les modifications visuelles (notamment le problème de la cible cliquable sous les 24 px).

**Règles propres au projet**
NON BLOQUANT : Les critères d'acceptation de la story sont implémentés avec soin (disposition multi-cas, sommaire borné qui défile, mise en évidence de la cible), sous réserve des deux garde-fous manquants signalés plus haut.
NON BLOQUANT : Le code est exempt de toute donnée privée, secret, ou nom d'hôte non autorisé.
NON BLOQUANT : La cohérence avec `AGENTS.md` et l'architecture (notamment Q9 pour l'absence d'introduction, et AD-18 pour l'URL) est scrupuleusement suivie.
NON BLOQUANT : Dans les scripts shell ajoutés et modifiés, les retours de commandes (comme `checks_attributes`) et les exécutions (via `run construire`) sont manipulés de manière sûre, sans laisser passer d'erreur en silence sous `set -euo pipefail`.

VERDICT: BLOQUANT — Erreur de compilation Hugo sur un groupe vide (`index $cases 0`) et contrôle insuffisant de l'URL du lien de retour dans `links.sh`.

### Décisions de l'auteur sur la revue du code de la PR n° 79

**Refusé, parce que l'outil ne se comporte pas ainsi — le plantage sur un groupe vide.** Le relecteur donne `{{ with index $cases 0 }}` pour fatal (« index out of range ») quand `.RegularPages` est vide, ce qui interdirait de créer une page de groupe avant son premier cas. **Essayé** : un site avec un `_index` de groupe et aucun cas se construit sans erreur, en FR comme en EN, avec `--panicOnWarning` ; Hugo rend `nil` et le `with` saute. La page sort avec son titre et sans lien de retour, ce qui est le comportement voulu.

Le constat était plausible et bien raisonné ; il est faux sur ce Hugo. C'est le point 10 d'`AGENTS.md` appliqué au relecteur cette fois : le comportement d'un outil n'est vrai qu'une fois vérifié. **Le cas de test reste**, parce que rien ne garantit qu'une version future se comportera de même : `case_groupe_sans_aucun_cas` construit un groupe vide et échouerait si Hugo se mettait à refuser.

**Retenu — le contrôle de la cible du lien de retour.** Le relecteur a raison sur le fond : `shell_grep -q '#position-'` vérifie l'ancre et pas la page, donc `/ailleurs#position-chiliz` passait. Le trou était plus étroit qu'annoncé — les règles de lien et d'ancre de C12 exigent déjà que la page visée existe **et** porte l'identifiant, donc il fallait une vraie page avec un vrai `id="position-…"` ailleurs sur le site — mais le critère y perdait son intention, et une page future pourrait porter cet identifiant.

La règle résout désormais la cible et exige **un accueil de langue**, seul endroit où vit le parcours (AD-18). Le cas `links_retour_vers_une_autre_page_que_laccueil` fabrique exactement la page qui manquait au scénario du relecteur ; il a été lancé une fois sans le resserrement, pour le voir échouer.

**Les quatre non bloquants sont des confirmations.** Aucune action.

### 22/09/2026 — `4efc772` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 79. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 8a6fadb3cf18d85818cb965f

##### Rapport de revue

**Lentille edge-case-hunter**
* NON BLOQUANT : Aucun chemin non géré (unhandled path), cas limite ou faille logique n'a été détecté dans le code de production modifié par la story.

**Lentille verification-gap**
* BLOQUANT : Le critère d'acceptation "l'accueil de la langue du cas" est vidé de son intention dans `scripts/checks/links.sh` (broken-verification-gap) : la condition `[[ $visee == index.html || $visee =~ ^[a-z]{2}/index\.html$ ]]` accepte tout lien pointant vers un accueil (FR ou EN) sans exiger qu'il corresponde à la langue de la page courante (`$page`), ce qui laisserait une page française pointer vers `/en/#position-chiliz` sans faire échouer la CI.

**Couche propre au projet**
* NON BLOQUANT : À l'exception de la faille de vérification linguistique mentionnée ci-dessus, les critères d'acceptation de la story sont satisfaits (sommaire multi-cas défilant, absence d'introduction selon Q9, cibles marquées).
* NON BLOQUANT : Aucune donnée privée, secret, nom d'hôte ou adresse de serveur n'est commité, et aucun script ne peut afficher l'adresse de la forge ou un secret.
* NON BLOQUANT : Skill, procédure et script concordent ; aucune étape n'a été altérée ou désynchronisée.
* NON BLOQUANT : Le changement est rigoureusement cohérent avec `AGENTS.md` et les décisions d'architecture (notamment AD-18 sur le lien de retour unique).
* NON BLOQUANT : Dans les scripts shell ajoutés et modifiés, aucune erreur ne passe en silence sous `set -euo pipefail` (les retours des sous-shells comme `$(page_visee ...)` sont convenablement interceptés ou propagés).

VERDICT: BLOQUANT — Le contrôle du lien de retour dans links.sh valide un lien pointant vers l'accueil d'une autre langue.

### Décisions de l'auteur sur la deuxième revue du code de la PR n° 79

**Retenu — l'accueil doit être celui de la langue de la page.** Mon resserrement précédent acceptait n'importe quel accueil : une page française qui renvoyait vers `/en/#position-chiliz` passait. Le critère dit « l'accueil de la langue du cas », et le contrôle ne le disait pas. Ramener Claire sur un CV qu'elle ne lisait pas est exactement ce que l'ancre existe pour éviter.

L'accueil attendu se déduit désormais du chemin de la page elle-même — la langue par défaut à la racine, les autres sous leur préfixe — et le message le nomme. Le cas `links_retour_vers_laccueil_de_lautre_langue` a été lancé une fois sans cette vérification, pour le voir échouer.

C'est le deuxième tour sur la même règle, et il vaut d'être noté : la première écriture ne vérifiait que l'ancre, la deuxième la page mais pas la langue. Une règle qui remplace une vérification trop large par une autre mérite qu'on liste ce qu'elle laisse encore passer avant de la croire finie.

**Les six non bloquants sont des confirmations.** Aucune action.

### 22/09/2026 — `035867a` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 79. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: e3cf7627a432d498bb50622f

##### Rapport de revue (bmad-review & règles du projet)

**Lentille edge-case-hunter**
NON BLOQUANT : La regex `^([a-z]{2})/` dans `links.sh` permettant de déduire la langue cible est trop permissive : elle identifierait à tort n'importe quel dossier de deux lettres (ex: `cv/` ou `ux/`) comme un préfixe de langue, ce qui pourrait causer des erreurs de validation bien que ce soit inoffensif aujourd'hui puisque les cas sont sous le dossier `cases/`.

**Lentille verification-gap**
NON BLOQUANT : La boucle de validation dans `links.sh` (`while IFS= read -r href`) s'interrompt via un `break` dès le premier lien `#position-` valide pointant vers l'accueil attendu ; si le gabarit émettait par erreur plusieurs liens de retour dont certains invalides, ces derniers passeraient la CI en silence.

**Couche propre au projet**
NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (le sommaire annonce correctement le compte de cas et de rubriques, le corps du `_index` n'est pas rendu, la barre `:target` est présente, et l'URL du lien de retour pointe bien vers l'accueil de la langue du cas).
NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, et aucun secret n'est commité dans la PR ; aucun ajout aux scripts ne permet d'afficher un secret ou l'adresse de la forge.
NON BLOQUANT : Skill, procédure et script concordent (aucun skill ni procédure n'est modifié ou désynchronisé par ce changement).
NON BLOQUANT : Le changement est parfaitement cohérent avec AGENTS.md et les décisions d'architecture (respect absolu de Q9 sur l'absence d'introduction de la page de groupe, et de AD-18 sur la structure du retour au parcours).
NON BLOQUANT : Dans les scripts shell (`links.sh`, `test-case-page.sh`), aucune erreur ne passe en silence sous `set -euo pipefail` (les affectations par sous-shell comme `$(page_visee)` et les commandes sans `||` interrompent scrupuleusement l'exécution en cas d'échec).

VERDICT: NON BLOQUANT — aucune

### Décision de l'auteur sur la troisième revue du code de la PR n° 79

`035867a` (pass) : aucun constat, confirmations seulement.

Preuves sur la tête : `scripts/tests/run.sh`, 386 cas réussis ; `scripts/check.sh`, 6 contrôles passés ; `scripts/check-private.sh staged`, rien. Vérification manuelle d'AD-17 consignée dans `docs/accessibility.md`, sur les trois cas du rendu de travail, en clair et en sombre.

## Reporté

- Aucun constat reporté.
