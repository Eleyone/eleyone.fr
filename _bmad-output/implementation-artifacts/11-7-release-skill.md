# Story 11.7 : Release skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.7.

Septième story de l'epic 11, dont l'en-tête (point 21) veut la chaîne de mise en ligne construite et
répétée tôt. Celle-ci écrit la **procédure unique** qui publie `dev` sur `main`, tague, livre et
revient en arrière — le flux linéaire d'AD-24, sans merge commit.

La story 11.6 (installation du serveur et création des secrets) la précède dans l'ordre de travail
mais ne la bloque pas : ses dépendances sont 0.2, 0.4 et 11.5, toutes livrées. Elle est prise
maintenant parce que la 11.6 est la **seule opération manuelle** de l'epic et attend Arnaud.

## Deux questions atterrissent ici, et les deux sont tranchées

### Q1 — comment le verrou de revue reconnaît un commit déjà vérifié (D-13)

La spec le dit : « à trancher par Arnaud avant de commencer cette story ». Les faits, relevés le
25/09/2026 :

- **113 commits** séparent `origin/main` de `origin/dev`, et **tous les 113** portent un marqueur
  `(#N)` — Gitea l'ajoute à tout squash. Le marqueur ne prouve donc rien ;
- sept d'entre eux ont été fusionnés **à la main**, sous la règle d'amorçage, avant que
  `verify-and-merge-pr` existe : `c2c789e` à `6cdb7b2` (PR #1 à #10), dont la PR #2 qui n'a eu
  **aucune** revue, au titre de l'exception documentaire.

**Arbitrage d'Arnaud, 25/09/2026 : une liste explicite de SHA dans le dépôt.** Elle nomme les
commits d'amorçage et dit pourquoi chacun échappe au verrou ; pour tout autre commit, la règle reste
stricte. Les trois autres options lui ont été présentées : interroger la forge PR par PR (preuve
réelle, mais 113 appels et une dépendance réseau dans un verrou de fusion, alors qu'AD-14 prévoit
explicitement que le homelab tombe), une borne d'amorçage assumée (simple, mais « tout ce qui est
avant X passe » ne dit ni combien ni lesquels), et une revue rétroactive de la plage (qui ne suffit
pas seule : le verrou vérifie la **provenance**, pas seulement l'existence d'une revue).

### Q2 — le substitut d'amorçage a-t-il encore un rôle ? (`epic-3-oq-substitut-d-amorcage`)

Cette question ouverte porte `lands_in: story 11.7`. Elle y atterrit donc, et la réponse trouvée en
la vérifiant **n'est pas celle qu'elle attendait**.

Elle était formulée ainsi : « le substitut a-t-il encore un rôle une fois la CI en place ? », et son
état disait « régime révolu mais pas mort ». Mesuré :

```
checks.yaml sur origin/dev  : présent
checks.yaml sur origin/main : ABSENT
commits sur origin/main     : 8
```

Le substitut se déclenche quand `.gitea/workflows/checks.yaml` est **absent de la base** de la PR
(`scripts/lib/merge-gates.sh:141-145`). Pour une PR vers `dev`, il est donc inatteignable — c'est
bien un régime révolu. **Mais la PR de publication a pour base `main`**, où le fichier n'existe pas
encore : le substitut ne se déclencherait pas *malgré* la CI, il se déclencherait **exactement à la
première publication**, le moment le plus critique du projet, en remplaçant la CI de la forge par un
`scripts/check.sh` lancé dans une copie locale.

Le régime n'est donc pas « révolu mais pas mort » : il est **dormant et précisément armé pour le
pire moment**.

**Correction, après avoir relu la procédure plutôt que la question** : ce n'est pas une découverte,
et le prétendre serait malhonnête. `docs/procedures/verify-and-merge-pr.md:44` le dit déjà, mot pour
mot — « ce régime ne concerne plus qu'une PR dont la base ne l'a pas encore, **la PR de mise en
ligne `dev` → `main` tant que `main` est en retard** ». La procédure était juste ; c'est l'entrée
`open_questions` qui résumait mal son propre sujet, en retenant « régime révolu » et en laissant
tomber la moitié de la phrase qui nommait le cas restant.

Ce que cette story apporte n'est donc pas le constat mais la **décision**, que personne n'avait
prise : faut-il tolérer ce régime pour une publication ? La réponse est non, et elle devait être
écrite quelque part avant la première mise en ligne.

La leçon est plutôt pour le suivi des questions ouvertes : un `state:` qui résume un document finit
par le remplacer. Celui-ci disait « régime révolu mais pas mort » là où la source disait « révolu,
**sauf pour la PR de publication** » — et c'est la partie omise qui comptait.

**Décision : `release` ne tolère pas le régime d'amorçage.** Le verrou CI d'une publication lit les
statuts de la **tête**, qui est un commit de `dev` et porte donc les statuts de `checks.yaml`, sans
se soucier de ce que la base contient. Un `absent` y est un refus, jamais une tolérance. La
justification tient en une phrase : une mise en ligne ne se valide pas sur un substitut, alors que
la CI réelle a tourné sur ce commit même.

## Revue de spec

### 25/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `0eae9ac`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 7a0acef8a8d9a9d1885ea5e9

### Rapport de Revue LLM (Skill bmad-review)

*Lentilles appliquées : Structure, Adversarial, Prose.*

#### Constats de la revue

- **BLOQUANT** : (Structure) Dans "applique les verrous de la publication (..., suivi de sprint tels quels)", la spécification comporte une faille logique. La PR de publication va de `dev` vers `main` (le nom de la branche entrante est donc `dev`). Or, le verrou `sprint_consistency` s'attend au format d'une branche de fonctionnalité (avec un numéro de story) pour valider l'état dans `sprint-status.yaml`. L'appliquer "tel quel" provoquera un blocage systématique. Ce verrou doit être ignoré pour une release.
- **BLOQUANT** : (Structure) Le critère "revue tenue si chaque commit de main..dev est le squash d'une PR fusionnée" contredit l'exception (déjà tranchée et actée) des commits d'amorçage exemptés par une liste explicite de SHAs. La spécification doit inclure cette clause d'exemption pour éviter que l'implémentation stricte du contrôle ne bloque sur l'historique initial.
- **BLOQUANT** : (Structure) Malgré le titre de la story ("Release skill") et la mention de `scripts/release.sh` et `docs/procedures/release.md`, les tâches oublient d'exiger la création du fichier de définition du skill (`.claude/skills/release/SKILL.md`) et de ses liens symboliques dans `.agents/skills/` et `.agent/skills/`. Ceci viole la règle d'architecture "un skill par outil, en trois niveaux".
- **BLOQUANT** : (Structure) La condition d'échec "ou que ci/release-pages.txt ne contient pas toutes les pages du socle" est invérifiable sans clarifier sa mécanique. Le script s'exécute localement, mais ce fichier est le fruit d'une construction. La spec ne précise pas si le script doit télécharger l'artefact depuis la CI de la forge ou construire le site localement au préalable.
- **BLOQUANT** : (Adversarial) Concernant la fusion "en fast-forward seulement avec --merge", l'appel à l'API Gitea pour fusionner une PR fraîchement ouverte peut renvoyer un code 405 transitoire "Please try again later" (le temps que la forge calcule la fusionnabilité). La spec omet de demander une boucle de *retry* pour gérer ce délai, ce qui causera des faux positifs d'échec.
- **BLOQUANT** : (Adversarial) L'enchaînement "fusionne en fast-forward... vérifie que main et dev pointent sur le même commit, pose le tag vX.Y.Z sur main" oublie que la fusion réalisée via l'API sur la forge ne met pas à jour le dépôt Git local. Sans exiger un `git fetch` explicite avant la vérification, le script taguera silencieusement un vieux commit de `main`.
- **BLOQUANT** : (Adversarial) Le critère d'acceptation ne décrit pas explicitement le comportement complet de la branche d'exécution sans `--merge`. Il indique qu'il fusionne "seulement avec --merge", mais omet de dire si le script doit quand même ouvrir la PR, et s'il doit s'interrompre proprement avant l'étape du tag.
- **BLOQUANT** : (Prose) L'instruction "elle appelle rollback <tag>" est inimplémentable. Aucune commande système `rollback` n'existe par défaut. Il manque la désignation de l'utilitaire cible (s'agit-il de `deploy-site rollback <tag>` ?).
- **NON BLOQUANT** : (Prose) L'instruction "suit le workflow release et deploy-site status" est ambiguë concernant l'expérience utilisateur attendue (s'agit-il de faire un *polling* bloquant de l'API avec des retours dans le terminal, ou d'afficher simplement l'URL de l'action Gitea ?).

---

#### À trancher avant d'implémenter

- **Obtention de `ci/release-pages.txt`** : Le script de publication doit-il interroger l'API Gitea pour télécharger l'artefact CI du commit de tête, ou doit-il lancer un build Hugo local pour générer le fichier ?
- **Commande de retour arrière** : Quelle est la véritable commande derrière l'expression `rollback <tag>` (ex: l'utilitaire `deploy-site`) ?
- **Comportement de l'audit (sans `--merge`)** : Jusqu'où le script doit-il aller en mode audit ? Doit-il créer la PR et afficher les verrous, puis s'arrêter formellement avant l'application du tag ?
- **Suivi du workflow** : Quelle est la profondeur de suivi souhaitée en ligne de commande (boucle d'attente active sur la progression de la CI, ou affichage ponctuel du lien) ?

### Triage des constats (point 20 : chacun reçoit sa décision)

| # | Constat | Décision |
| --- | --- | --- |
| S1 | Le verrou de suivi de sprint bloquerait, la branche entrante étant `dev` | **Retenu sur le fond, mais pas la correction proposée.** Le relecteur veut l'**ignorer** ; c'est trop fort, et le dépôt a déjà la réponse : `docs/procedures/verify-and-merge-pr.md:46` prévoit qu'« une branche sans numéro de story passe par le contrôle **global** (`--rev <SHA de tête>`) ». `release` l'applique donc en mode global — un suivi incohérent doit bloquer une publication autant qu'une story. |
| S2 | Le verrou de revue contredit l'exemption d'amorçage | **Retenu**, et déjà tranché par Arnaud le 25/09/2026 : liste explicite de SHA dans le dépôt (voir Q1 en tête de ce fichier). |
| S3 | Le `SKILL.md` et les deux liens symboliques manquent | **Retenu, et c'est un vrai oubli de la spec.** Le projet veut trois niveaux — `.claude/skills/release/SKILL.md` → `docs/procedures/release.md` → `scripts/release.sh` — plus `.agents/skills/release` et `.agent/skills/release`, **liens symboliques relatifs** vers le premier, jamais des copies. Vérifié sur `publish-case`, qui suit exactement cette forme. |
| S4 | « `ci/release-pages.txt` ne contient pas toutes les pages du socle » est invérifiable | **Réfuté pour moitié, retenu pour l'autre.** La moitié fausse : `ci/release-pages.txt` est **versionné** (`git ls-files` le confirme), ce n'est pas un artefact de CI — rien à télécharger, rien à construire, le script le lit à la tête. La moitié vraie : il manque une **source** pour « les pages du socle ». Décision : `ci/base-pages.txt`, la liste figée des neuf `translationKey` que FR-32 énumère (accueil, à propos, contact, mentions légales, confidentialité, cas 01, groupe Chiliz, cas 02, cas 05), avec un commentaire qui renvoie à FR-32. `release` vérifie, pour `v1.0.0` seulement, que chaque clé de cette liste figure dans `ci/release-pages.txt`. Une liste de référence figée, et non les neuf clés recopiées dans un script (point 19). |
| A1 | Le 405 transitoire de l'API n'est pas géré | **Retenu**, et l'architecture le documente déjà : « parfois précédé, juste après le déplacement de la base, d'un 405 transitoire "Please try again later" que `release` et `hotfix` ne prennent **pas** pour un refus ». Reprise bornée, et un 405 **non** transitoire reste un refus : les deux se distinguent par le message de la forge, pas par le code. |
| A2 | La fusion par l'API ne met pas à jour le dépôt local : le tag partirait sur un vieux `main` | **Retenu, et c'est le plus dangereux des huit.** Un tag posé sur l'ancien `main` déclencherait le workflow `release` sur un arbre qui n'est pas celui qu'on croit publier. `git fetch origin` explicite après la fusion, puis vérification que `origin/main` et `origin/dev` pointent sur le **même** commit **avant** de poser le tag. |
| A3 | Le comportement sans `--merge` n'est pas décrit | **Retenu.** Décision : sans `--merge`, `release` va jusqu'au bout de l'**audit** — il ouvre la PR si elle n'existe pas, affiche les verrous un par un — et **s'arrête là**, sans fusionner ni taguer. C'est le comportement de `verify-and-merge-pr`, et un outil de publication ne doit pas surprendre celui qui l'appelle pour voir. |
| P1 | « elle appelle `rollback <tag>` » est inimplémentable | **Retenu** : c'est `deploy-site rollback <tag>`, envoyé par `ssh` dans `SSH_ORIGINAL_COMMAND`, comme le fait `scripts/release/ship.sh` (story 11.5). La procédure le nomme au lieu de le sous-entendre. |
| P2 | Quelle profondeur de suivi du workflow ? | **Retenu.** Décision : **aucun polling bloquant**. `release` affiche le lien du run et la commande `deploy-site status` à lancer ; il ne tient pas le terminal ouvert pendant les minutes du build. Un script qui attend une CI est un script qu'on interrompt, et l'état vrai est de toute façon celui que `status` renvoie. |

### Ce que la story ne fait pas

Elle ne pose **aucun tag réel** : la spec le dit (« les tags réels sont poussés aux stories 11.9 et
11.11 »). Elle ne rappelle pas non plus `build-image.sh` ni `ship.sh` : la livraison part du **tag
poussé**, qui déclenche le workflow `release` livré à la story 11.5.

## Ce qui est livré

Le skill en trois niveaux, la bibliothèque qui porte ses décisions, les deux listes qu'il lit, et sa
suite de cas.

| Fichier | Rôle |
| --- | --- |
| `.claude/skills/release/SKILL.md` | le skill, court, qui renvoie à la procédure et au script |
| `.agents/skills/release`, `.agent/skills/release` | liens symboliques **relatifs** vers `../../.claude/skills/release` |
| `docs/procedures/release.md` | la procédure, qui fait foi : prérequis, ordre des vérifications, cinq verrous, fusion, tag, suivi, retour arrière |
| `scripts/release.sh` | l'exécution (audit par défaut, `--merge` explicite) |
| `scripts/lib/release.sh` | les décisions, éprouvées sur des fichiers et un dépôt jetable : expressions des deux canaux, `release_rc_same_tree`, `release_unverified_commits`, `release_missing_base_pages` |
| `ci/base-pages.txt` | la liste **figée** des neuf `translationKey` du socle (FR-32), avec le commentaire qui y renvoie |
| `ci/bootstrap-commits.txt` | les sept SHA d'amorçage exemptés du verrou de revue, chacun avec sa raison (arbitrage d'Arnaud du 25/09/2026) |
| `scripts/tests/test-release.sh` | 41 cas, hors ligne |
| `scripts/ci/release-job.sh` | converti : il charge la bibliothèque au lieu de porter sa propre copie de la règle `-rc` |
| `scripts/tests/test-release-job.sh` | recopie la bibliothèque dans ses deux dépôts d'essai |
| `docs/procedures/verify-and-merge-pr.md` | la phrase sur le régime d'amorçage est mise au présent : il n'est plus atteignable (points 8 et 13) |
| `AGENTS.md` | `release` n'est plus « à appliquer à la main » (point 8) |
| `sprint-status.yaml` | `epic-3-oq-substitut-d-amorcage` reçoit sa réponse et son atterrissage |

Deux choses que la story **ajoute** au brief, et pourquoi :

- **`scripts/lib/release.sh` au lieu d'une copie.** `scripts/ci/release-job.sh:104-131` portait déjà la
  règle « un tag `-rc.N` de même arbre », écrite à la story 11.5. La recopier aurait été exactement la
  faute du point 19. Elle est donc extraite, avec les deux expressions de canal, et le job de CI
  l'appelle désormais. La différence entre les deux usages est un paramètre : le job compare l'arbre
  du **tag** (il tourne après son push), le skill celui de la **tête de `dev`** (le tag reste à poser).
  `deploy/remote/deploy-site.sh` garde sa copie des expressions — il est recopié seul sur le serveur
  et ne peut rien partager —, et un cas de test tient les trois égales, comme `test-ship.sh` le fait
  pour le nom du dépôt d'images. Ce cas a d'ailleurs trouvé que les trois fichiers ne nomment pas la
  variable pareil : `motif_production` dans `ship.sh`, `tag_production` dans `deploy-site.sh`.
- **`ci/bootstrap-commits.txt` liste sept SHA, dont deux déjà sur `main`.** `c2c789e` et `9e14036` (PR
  n° 1 et n° 2) ont été publiés avant que `main` reste en arrière : ils n'apparaissent donc plus dans
  `main..dev`. Ils restent listés parce que le fichier dit **quels commits ont échappé au script**, et
  non lesquels restent à publier. Les cinq autres (`c73552b` à `6cdb7b2`, PR n° 6 à n° 10) sont bien
  dans la plage. Vérifié le 25/09/2026 : 113 commits séparent `origin/main` de `origin/dev`, et le
  premier d'entre eux est `c73552b`.

## Le brief des jumeaux (point 19)

**L'aîné est `scripts/verify-and-merge-pr.sh`, avec `scripts/lib/merge-gates.sh`.** La bibliothèque
est **réutilisée**, jamais recopiée : `ci_gate` décide du verrou CI ici comme là-bas, et
`scripts/tests/test-merge-gates.sh` continue de l'éprouver. Ses huit gardes, une par une :

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 1 | **Refus d'une base inattendue** : `main` est refusée, avec renvoi vers `release`. | **Oui, à l'envers.** Le cadet cherche la PR par `head == dev` **et** `base == main`, et son verrou « PR publiable » bloque si la PR lue n'est pas `dev → main`. Une base autre que `main` n'a rien à faire ici. Cas : la PR nominale est trouvée sur ce couple ; `release_tete_de_pr_decalee` couvre l'autre moitié de la garde, la tête qui n'est pas celle de `origin/dev`. |
| 2 | **Dépôt distant vérifié avant tout appel d'écriture**, arbre sans modification en attente, branche poussée au même commit. | **Oui pour les deux premiers**, à l'identique : `check_origin` avant tout, puis `git status --porcelain` — ce qui n'est pas commité ne sera pas publié (`release_arbre_sale`). Le troisième **change de forme** : le cadet ne publie pas `HEAD` mais `origin/dev`. L'équivalent est de ne travailler que sur les références distantes relues par `git fetch`, et d'exiger que la tête de la PR soit exactement `origin/dev`. |
| 3 | **Message de fusion confronté à la liste des motifs** avant envoi. | **Non pour le message de fusion** : `fast-forward-only` ne crée aucun commit, donc aucun message n'est composé — la procédure et le script le disent noir sur blanc, pour que l'absence de cette garde se lise comme une décision et non comme un oubli. **Oui pour ce que le cadet envoie quand même** : le titre et le corps de la PR qu'il ouvre passent la liste avant le `POST` (`release_motif_prive_dans_le_titre`). |
| 4 | **Corps de la réponse relu après la fusion** : « fusion annoncée mais la PR n'apparaît pas fusionnée » est une anomalie. | **Oui, tel quel** (`release_fusion_non_confirmee`), **et doublé** : le cadet relit ensuite les branches sur la forge et exige que `origin/main` porte le commit publié. C'est le cœur de la story. |
| 5 | **Codes HTTP distingués**, 405 transitoire ≠ refus. | **Oui, et c'est ici que ça compte** : 200 ; 405 « try again later » → reprise bornée (`release_merge_405_transitoire`) ; 405 autre → refus de style (`release_merge_405_persistant`) ; 500 `DivergingFastForwardOnly` → refus nommé (`release_merge_500_divergence`). Les deux 405 se distinguent par le **message**, jamais par le code. |
| 6 | **Aucune option `--force`**, jamais `force_merge`. | **Oui**, et une garde de plus que l'aîné n'a pas besoin d'avoir : l'aîné envoie `delete_branch_after_merge: true`, ce qui est juste pour une branche de story et **catastrophique pour `dev`**. Le corps de fusion du cadet ne porte que `Do` et `head_commit_id`, et `release_merge_nominal` refuse `force_merge`, `merge_when_checks_succeed` **et** `delete_branch_after_merge`. |
| 7 | **Codes 0 / 1 / 2** et rapport verrou par verrou, lisible même quand tout passe. | **Oui, tel quel**, y compris `report()` et `indent()`. Ces quatre lignes sont **recopiées** et non mises en commun, délibérément : `merge-gates.sh` est documentée comme la bibliothèque des **décisions**, testables sur des fichiers, et `report` n'est ni une décision ni testable sur un fichier — elle écrit sur la sortie et modifie une variable de son appelant. La mettre là-bas ferait dépendre la bibliothèque de `blocked`. |
| 8 | **`jq -n --arg`** pour composer un JSON. | **Oui**, pour les deux corps envoyés : création de la PR (`--rawfile` pour le titre et le corps) et fusion (`--arg` pour le SHA). |

Ce que l'aîné a et que le cadet **ne reprend pas**, avec la raison :

- **la lecture de la timeline et le verdict `llm-review`** : le verrou de revue d'une publication ne
  cherche pas un rapport, il vérifie la **provenance** de chaque commit (D-13). Aucun appel de
  pagination, donc, ni plafond de pages pour la timeline ;
- **l'exception documentaire et la règle du commit de statut** : elles concernent une PR de story.
  Une publication n'a ni story ni commit de statut ;
- **le numéro de story tiré du nom de branche** (`scripts/lib/sprint.sh`) : la branche entrante est
  `dev`. Le cadet ne charge pas cette bibliothèque et appelle `sprint-consistency` en mode **global** ;
- **le substitut d'amorçage** : refusé explicitement, c'est la décision Q2 de cette story.

**Le second aîné est `scripts/ci/release-job.sh`** (règle `-rc` de même arbre) : sa garde n'est pas
reprise mais **extraite**, et le job l'appelle désormais (voir ci-dessus).

**Pour les tests, l'aîné est `scripts/tests/test-release-job.sh`.** Gardes reprises : dépôt git réel
et jetable dans `$work` ; faux git qui ne dévie que pour une sous-commande et délègue le reste au
vrai ; environnement réduit par `env -i` ; affirmation du code de sortie **avant** de compter quoi
que ce soit ; vérification qu'aucun effet n'a eu lieu après un refus (`aucun_appel_api`,
`aucun_tag`). Gardes ajoutées : un état de forge tenu **à part** des références locales, sans quoi le
décalage que cette story doit empêcher serait invisible ; un faux `curl` qui consomme l'entrée
standard sans jamais écrire le jeton ; un faux `sleep` qui note l'attente au lieu de la subir.
De `test-ship.sh`, une garde reprise nommément : la comparaison littérale d'une constante entre
fichiers qui ne peuvent pas la partager.

## Les mutations (point 9)

Chaque garde a été retirée ou inversée, une à la fois, et la suite rejouée. **Les 29 mutations
tombent** ; aucune n'est passée inaperçue. Le détail, avec le premier cas qui tombe :

| Mutation | Cas qui tombe |
| --- | --- |
| M1 `git fetch` d'après-fusion retiré | `release_merge_405_transitoire` (et `release_merge_nominal`) |
| M2 égalité `origin/main` = commit publié retirée | `release_tag_refuse_si_la_relecture_ne_ramene_rien` |
| M3 invariant d'ancêtre retiré | `release_main_pas_ancetre` |
| M4 `amorçage` CI traité comme un état de la bibliothèque | `release_ci_absente_refuse_l_amorcage` |
| M5 parents multiples non vus | `release_revue_commit_de_fusion` |
| M6 marqueur `(#N)` non exigé | `release_revue_commit_sans_numero` |
| M7 SHA d'amorçage non validé | `release_revue_sha_mal_forme` |
| M8 tout 405 tenu pour transitoire | `release_merge_405_persistant` |
| M9 `delete_branch_after_merge: true` ajouté | `release_merge_nominal` |
| M10 arbre sale toléré | `release_arbre_sale` |
| M11 tag déjà existant toléré | `release_tag_deja_existant` |
| M12 socle non vérifié pour `v1.0.0` | `release_v1_socle_incomplet` |
| M13 motifs non confrontés au titre | `release_motif_prive_dans_le_titre` |
| M14 fusion non confirmée acceptée | `release_fusion_non_confirmee` |
| M15 tag local gardé après un push raté | `release_push_du_tag_en_echec` |
| M16 liste de référence vide tolérée | `release_socle_liste_de_reference_vide` |
| M17 tête de PR décalée tolérée | `release_tete_de_pr_decalee` |
| M18 `mergeable: null` lu tel quel | `release_mergeable_nul_puis_vrai` |
| M19 tag `-rc` accepté comme production | `release_usage_tag_de_repetition` |
| M20 « rien à publier » toléré | `release_rien_a_publier` |
| M21 `v1.0.0` sans répétition seulement averti | `release_v1_repetition_d_un_autre_arbre` |
| M22 suivi de sprint appelé en mode story | `release_suivi_de_sprint_global` |
| M23 garde-fou non lancé | `release_garde_fou_refuse` |
| M24 CI lue sur `main` au lieu de la tête | `release_audit_ouvre_la_pr` |
| M25 option inconnue prise pour un tag | `release_usage_option_inconnue` |
| M26 `report` ne retient pas le blocage | `release_ci_absente_refuse_l_amorcage` |
| M27 blocage sans arrêt avant la fusion | `release_ci_absente_refuse_l_amorcage` |
| M28 fusion en `squash` | `release_merge_nominal` |
| M29 `head_commit_id` omis | `release_merge_nominal` |

**Les deux moitiés du danger du tag sont éprouvées séparément**, et c'est volontaire : M1 retire la
relecture (le script refuse alors de taguer, grâce à la vérification), M2 retire la vérification (le
script tague alors l'**ancien** `main`, et `release_tag_refuse_si_la_relecture_ne_ramene_rien`
tombe). Retirer l'une seule ne suffit donc pas à livrer le mauvais arbre : il faut les deux, et
chacune a son cas.

Rien à signaler d'autre : aucune mutation n'a laissé la suite verte, donc aucune « garde » de ce
changement ne garde rien — c'est le contraire des sept trouvées dans les quatre dernières stories.

## Vérifications

```
$ bash scripts/tests/run.sh
tests: 808 cas réussis.

$ bash scripts/tests/run.sh scripts/tests/test-release.sh
tests: 41 cas réussis.

$ scripts/check.sh
check: 11 contrôle(s) passés, niveau standard.

$ bash scripts/release.sh
release: usage : release.sh <tag vX.Y.Z> [--merge]                                    (code 2)

$ bash scripts/release.sh v1.2.3-rc.1
release: tag v1.2.3-rc.1 : une répétition générale se pose sur dev par le skill
rehearse-release, jamais par release (AD-22).                                          (code 2)

$ bash scripts/release.sh v1.2.3 --force
release: option inconnue : --force. usage : release.sh <tag vX.Y.Z> [--merge]          (code 2)

$ bash scripts/release.sh v1.2.3          # arbre de travail modifié par cette story
release: modifications non commitées dans l'arbre de travail : elles ne seraient pas
publiées.                                                                              (code 2)

$ cd /tmp && bash …/scripts/release.sh v1.2.3
release: à lancer dans le dépôt.                                                       (code 2)

$ ls -l .agents/skills/release .agent/skills/release
.agent/skills/release  -> ../../.claude/skills/release
.agents/skills/release -> ../../.claude/skills/release

$ git add -A && scripts/check-private.sh staged
                                                                                       (code 0)
$ scripts/sprint-consistency.sh
sprint-consistency: cohérent dans l'arbre de travail (90 stories, 14 epics,
72 fichiers de story, 10 question(s) ouverte(s)).
```

Aucun tag n'a été posé nulle part, ni dans le dépôt du projet ni ailleurs ; aucun appel réseau n'a eu
lieu pendant la suite.

## Revue du code

### 25/09/2026 — `173a437` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 121. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 75c0e97bcba3ae98b6d2a797

##### Rapport de revue (BMAD)

###### Lentille : edge-case-hunter
- NON BLOQUANT : Le filtrage initial par `git tag --list "$prefix-rc.*"` avec un globbing basique pourrait remonter des tags mal formés, mais la vérification explicite avec l'expression régulière stricte sur le suffixe (`[[ $number =~ ^(0|[1-9][0-9]*)$ ]]`) garantit qu'aucun bord de cas (comme `v1.0.0-rc.1a`) n'est traité par erreur.
- NON BLOQUANT : Le mécanisme de différenciation des erreurs `405` de Gitea (transitoire vs persistant) repose sur le texte exact du message d'erreur ("Please try again later"). Bien que fragile face à une éventuelle mise à jour de l'API Gitea, cela correspond aux spécifications existantes (AD-24) et empêchera la publication plutôt que de forcer une mauvaise fusion en cas de changement inattendu.

###### Lentille : verification-gap
- NON BLOQUANT : L'abandon délibéré de la relecture octet par octet du corps de la PR est documenté, ce qui referme ce vide de vérification : le corps de la PR étant entièrement généré par le script, le risque d'altération silencieuse présent dans `create-pull-request` n'existe pas ici.
- NON BLOQUANT : En cas de `git push` défaillant après la création du tag local, le nettoyage du tag orphelin (« au mieux ») indique désormais à l'utilisateur quelle opération échoue s'il est impossible de le supprimer, sans cacher l'erreur derrière un `|| true` muet.

###### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story 11.7 sont satisfaits (application de l'invariant `fast-forward`, vérification stricte de même arbre et des statuts CI pour la branche entrante).
- NON BLOQUANT : Le code ne commite ni donnée privée, ni nom d'hôte, ni secret. Le token et l'URL de la forge sont correctement appelés depuis l'environnement sans jamais être affichés ou écrits.
- NON BLOQUANT : L'alignement entre skill (`.claude/skills/release/SKILL.md`), procédure (`docs/procedures/release.md`) et script (`scripts/release.sh`) est vérifié (ex: la commande `deploy-site rollback <tag>` est explicitement nommée).
- NON BLOQUANT : La cohérence avec `AGENTS.md` et les décisions d'architecture (AD) est préservée, notamment en traitant le verrou CI "absent" comme un blocage strict, refusant de fait le substitut d'amorçage inadapté à une mise en production.
- NON BLOQUANT : La gestion des erreurs bash respecte `set -euo pipefail` sans étouffement silencieux ; la manipulation des codes de retour s'effectue proprement par capture explicite (`|| code_diff=$?` et `|| return`).

VERDICT: NON BLOQUANT — aucune

### Triage de la revue du code (`173a437`)

**Aucun constat n'appelle de changement**, et les quatre lignes des deux lentilles sont des
confirmations argumentées plutôt que des réserves :

- le globbing `git tag --list "$prefix-rc.*"` est rattrapé par l'expression ancrée sur le numéro,
  qui refuse `v1.0.0-rc.1a` ;
- la distinction entre un `405` transitoire et un `405` de refus repose sur le **texte** du message
  de la forge. Le relecteur la juge « fragile face à une éventuelle mise à jour de l'API », et il a
  raison sur le principe — mais il note lui-même que la conséquence d'un changement serait
  d'**empêcher** la publication, jamais de forcer une mauvaise fusion. C'est le sens dans lequel un
  garde-fou doit se tromper, et AD-24 décrit cette réponse de l'API telle quelle. **Rien à changer**,
  et rien à reporter : la fragilité est du côté sûr ;
- l'abandon de la relecture octet par octet du corps de la PR est documenté et justifié — le corps
  est entièrement produit par le script, sans le va-et-vient qui motivait cette relecture dans
  `create-pull-request` ;
- le nettoyage « au mieux » du tag orphelin **dit** désormais ce qu'il n'a pas pu faire : c'est le
  balayage du point 18 que l'orchestrateur avait fait avant la revue, et le relecteur le constate.

**Les cinq lignes de la couche projet** sont des confirmations : critères tenus, aucune donnée
privée ni adresse, skill/procédure/script alignés, cohérence avec `AGENTS.md` — « en traitant le
verrou CI *absent* comme un blocage strict, refusant de fait le substitut d'amorçage inadapté à une
mise en production » —, aucune erreur étouffée.

Rien à retenir, rien à reporter.

## Décisions

- **Le « lien du run » n'est pas une URL.** Le brief demandait d'afficher le lien du run de la CI.
  `docs/procedures/shell-scripts.md` l'interdit : « aucun message n'affiche une valeur de `.env`,
  **l'adresse de la forge** ou un contenu privé », et NFR-9 va dans le même sens. `create-pull-request`
  a déjà tranché pareil — « la sortie donne le numéro de la PR, jamais son adresse ». Le script
  affiche donc le **chemin** du run : onglet Actions du dépôt sur la forge, workflow `release`, tag.
  Un cas de test (`release_merge_nominal`) vérifie qu'aucune adresse ni jeton n'apparaît dans la
  sortie. C'est le seul écart au brief.
- **`deploy-site status` et `deploy-site rollback <tag>`** sont nommés dans la procédure comme des
  demandes envoyées par `ssh` dans `SSH_ORIGINAL_COMMAND`, exactement comme `scripts/release/ship.sh`
  le fait (décision P1 de la revue de spec). La procédure ne recopie ni l'hôte ni le compte, qui sont
  des secrets de la forge (AD-14).
- **`ci/` plutôt qu'un autre dossier pour les deux listes.** `ci/` porte déjà les données de la mise
  en ligne (`release-pages.txt`, lue par C15, et `legal-placeholder.env`). `base-pages.txt` et
  `bootstrap-commits.txt` les rejoignent plutôt que d'inaugurer un dossier pour deux fichiers.
- **Un arbre de travail modifié arrête le script (code 2).** Le script ne lit pourtant que des
  références distantes : la garde n'est pas technique, elle est humaine — publier n'est pas le moment
  de découvrir du travail en attente. Elle est explicite dans la procédure, et éprouvée
  (`release_arbre_sale`, mutation M10).
- **Aucune relecture octet à octet du corps de la PR publié**, là où `create-pull-request` la fait.
  Raison : ce corps est **généré par le script**, déterministe, et aucun fichier écrit à la main n'est
  en jeu. Le risque que cette garde couvre chez l'aîné — un corps rédigé par une personne, tronqué en
  silence — n'existe pas ici. Noté pour que l'absence se lise comme une décision.
- **Points 8 et 13, le balayage de ce que la décision Q2 laisse ailleurs.** Trois phrases devenaient
  fausses ou trompeuses : `docs/procedures/verify-and-merge-pr.md:44` (« ce régime ne concerne plus
  qu'une PR … la PR de mise en ligne »), `AGENTS.md` (« jusqu'à ce qu'ils existent, appliquer ces
  règles à la main », `release` compris) et `README.md` (« the tooling named above for releases and
  hotfixes is built in a later epic »). Les trois sont mises au présent dans cette PR.

## Décisions de l'orchestrateur

### L'écart au brief : le chemin du run, pas son URL

Mon brief demandait d'afficher « le lien du run ». La sous-tâche a refusé et affiché le **chemin** —
onglet Actions, workflow `release`, tag — en invoquant `docs/procedures/shell-scripts.md`, qui
interdit d'afficher l'adresse de la forge, et NFR-9.

**Elle a raison et mon brief avait tort.** `create-pull-request` a déjà tranché ainsi à la story
0.4 : « la sortie donne le numéro de la PR, jamais son adresse ». Une règle du dépôt l'emporte sur
une consigne d'orchestration, et un cas de test vérifie qu'aucune adresse ni jeton n'apparaît dans
la sortie.

### Le balayage que la revue précédente imposait (point 18)

La revue de la PR n° 120 a **bloqué** sur une classe de faute : « `|| true` avale silencieusement
une erreur ». Le point 18 dit qu'un constat d'une classe connue est un **ordre de balayage**, pas
une ligne à corriger. `scripts/release.sh` en portait deux, trouvées par l'orchestrateur **avant** la
revue plutôt qu'après :

- `git rev-parse --verify --quiet "refs/tags/$tag" || true` : le code vaut 0 si le tag existe, 1
  s'il n'existe pas — le cas nominal — et autre chose si le dépôt est illisible. Le `|| true`
  confondait les deux derniers, et une publication aurait continué sur un dépôt cassé. Les trois
  sont désormais distingués, le troisième étant une anomalie ;
- `git tag -d "$tag" || true` dans le chemin d'erreur du push : c'est un nettoyage « au mieux », et
  il reste tel — mais son code est lu, pour que le message dise à l'opérateur **laquelle** des deux
  situations il retrouvera. Un `|| true` muet lui aurait laissé un tag local sans le dire.

### Les deux modifications documentaires, jugées

`AGENTS.md` et `README.md` ne figuraient pas au brief. **Acceptées** : les deux portaient une phrase
au futur que cette story rend fausse — « `release` … vient après les stories dont il dépend » et
« the tooling named above for releases and hotfixes is built in a later epic ». C'est exactement le
point 8, et les deux retouches sont minimales et exactes.

### Vérification du travail de la sous-tâche (point 22)

Rejoué par l'orchestrateur, sans reprendre ses mesures :

| Vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 808 cas réussis |
| `scripts/check.sh` | 11 contrôles, code 0 |
| les deux liens symboliques | `-> ../../.claude/skills/release`, forme identique à `publish-case` |
| **mutation de la garde du tag** — `main_after == dev_sha` retirée | un cas tombe : `attendu 2 / obtenu 0`. Sans elle, le script **taguerait l'ancien `main`** |
| garde restaurée, suite rejouée | 808 cas |
| `\|\| true` restants dans `release.sh` | **0** (hors les deux commentaires qui disent pourquoi) |

La garde du tag est bien celle qui compte : c'est la seule dont la suppression produit une
publication silencieusement fausse plutôt qu'un refus.
