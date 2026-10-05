# Story 11.12 : Hotfix skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.12.

Story de la section « Mise en ligne du socle » de l'epic 11 : le dernier skill du flux linéaire
(AD-24, D-14), utilisable dès qu'une production existe — c'est le cas depuis `v1.0.0` (11.11) et
`v1.0.1` (9.8). Il corrige la production par une branche `hotfix/*` tirée de `main`, fusionnée en
fast-forward, taguée `vX.Y.(Z+1)`, puis rebase `dev` sur `main` et la pousse en `--force-with-lease`
**seulement sur l'approbation explicite d'Arnaud au moment de l'opération**. Aucun cherry-pick.

Aînés directs (règle 8 commune) : `scripts/release.sh` (skill `release`, story 11.7 — PR vers `main`,
verrous, fusion fast-forward, relecture des branches après fusion, tag annoté poussé) et
`scripts/rehearse-release.sh` (11.8 — confirmation explicite `--run`, aucun effet avant elle).

## Revue de spec

### 05/10/2026 — `gemini-3.1-pro-high` (angles : adversarial, structure, prose), `dev` à `3145b09`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ece68a1cbd666d4d484f6cee

#### Revue de spécification (Story 11.12 : Hotfix skill)

##### Lentille : Adversarial (Cas limites et logique)

- **[BLOQUANT]** `Critères d'acceptation`
  - **Constat :** La spec décrit un enchaînement d'actions (création de branche, fusion de PR, pose de tag, rebase de `dev`) qui implique des temps d'arrêt pour le développement et la relecture, mais ne définit ni les phases ni l'interface en ligne de commande du script (ex: `hotfix.sh start`, `hotfix.sh finish`). Elle ne dit pas non plus qui effectue la fusion de la PR et la pose du tag (le script lui-même, l'utilisateur, ou une délégation à `verify-and-merge-pr` / `release.sh`).
  - **Correction attendue :** Définir explicitement l'interface du script (ses arguments ou commandes) et répartir les responsabilités (ce que le script automatise vs ce qui est délégué ou manuel).
  - **Risque :** Le développeur devra inventer l'interface et le découpage du script, risquant d'automatiser des étapes (comme la fusion) sans respecter les verrous de revue LLM.

- **[BLOQUANT]** `Critères d'acceptation`
  - **Constat :** Lors de l'étape « `dev` est rebasée sur `main` », le cas d'un conflit de fusion n'est pas traité. Un correctif sur `main` peut entrer en conflit avec les évolutions en cours sur `dev`.
  - **Correction attendue :** Définir le comportement du script en cas d'échec de `git rebase main` (ex: arrêt immédiat du script avec message expliquant comment résoudre le conflit manuellement, ou option de reprise).
  - **Risque :** Le script pourrait échouer silencieusement, continuer son exécution dans un état incohérent, ou laisser l'utilisateur bloqué au milieu d'un rebase sans instruction.

- **[BLOQUANT]** `Critères d'acceptation`
  - **Constat :** Le mécanisme de recueil de l'« approbation explicite d'Arnaud » avant le force-push n'est pas défini (argument CLI `--confirm`, saisie interactive `read -p`, etc.).
  - **Correction attendue :** Préciser techniquement comment cette approbation est demandée et vérifiée par le script.
  - **Risque :** Implémentation d'un mécanisme non adapté (ex: invite interactive qui figerait une exécution automatisée, ou flag caché non documenté).

- **[NON BLOQUANT]** `Critères d'acceptation`
  - **Constat :** Le critère « Gitea refuse le force-push d'un autre utilisateur » décrit une configuration serveur issue de la story 0.2. Le script, exécuté avec le jeton d'Arnaud, ne peut pas tester ce rejet directement.
  - **Correction attendue :** Préciser qu'il s'agit d'un rappel d'une règle de sécurité couverte par la story 0.2, vérifiable par constat manuel, plutôt que d'un test automatisé à charge du script.
  - **Risque :** Temps perdu à essayer d'automatiser un test d'usurpation d'identité avec un seul jeton Gitea.

##### Lentille : Structure

- **[BLOQUANT]** `Général`
  - **Constat :** Les critères d'acceptation regroupent des moments distincts du cycle de vie du correctif (le démarrage sur `main`, puis le retour sur `dev` après publication) sous l'entité unique « le script poursuit ». Cela renforce l'absence de définition des points d'entrée du script.
  - **Correction attendue :** Séparer les critères d'acceptation par commande ou étape d'exécution (ex: `hotfix start`, `hotfix finish`).
  - **Risque :** Architecture monolithique du script incapable de gérer la pause nécessaire à l'implémentation et à la revue du correctif.

##### Lentille : Prose

- **[NON BLOQUANT]** `Critères d'acceptation`
  - **Constat :** Les formulations « la PR vers main se fusionne en fast-forward » et « le tag vX.Y.(Z+1) est posé » masquent l'acteur (voix passive / pronominale).
  - **Correction attendue :** Utiliser la voix active pour désigner clairement qui ou quel outil (le développeur, Gitea, ou un script) exécute l'action.
  - **Risque :** Confusion sur les responsabilités exactes du script par rapport aux actions manuelles ou aux autres skills.

##### À trancher avant d'implémenter

- L'interface en ligne de commande de `scripts/hotfix.sh` : le script doit-il avoir des sous-commandes (ex: `start` et `finish`) pour gérer les temps d'arrêt (développement, revue, PR) ?
- La responsabilité de la fusion et du tag sur `main` : le script automatise-t-il la création de PR, sa fusion et la création du tag, ou délègue-t-il certaines de ces étapes à l'utilisateur, à l'API Gitea, ou aux skills existants (`verify-and-merge-pr`, `release`) ?
- La gestion des conflits de rebase de `dev` sur `main` : arrêt du script avec intervention manuelle requise ?
- Le mode de l'approbation explicite d'Arnaud : invite interactive dans le terminal (`read`) ou argument explicite (ex: `--confirm-force-push`) ?

This structure respects all constraints:
- Starts with JETON line precisely formatted.
- Markdown output.
- BLOQUANT / NON BLOQUANT classifications.
- No VERDICT line.
- Has the "À trancher avant d'implémenter" section.
- Text in French.
- Didn't run any shell command (only view_file).

Let's double check if I'm missing any check from project layer.
"aucune donnée privée, aucun nom d'hôte ni adresse de serveur..." -> N/A here.
"skill, procédure et script concordent" -> the spec covers docs/procedures/hotfix.md and scripts/hotfix.sh.
"dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail" -> finding about git rebase failure addresses this.

Looks solid. I'll output the response now.JETON: ece68a1cbd666d4d484f6cee

#### Revue de spécification (Story 11.12 : Hotfix skill)

##### Lentille : Adversarial (Cas limites et failles logiques)

- **[BLOQUANT]** `Critères d'acceptation`
  - **Constat :** La spec décrit un enchaînement d'actions complet (création de branche, développement, fusion de PR, pose de tag, rebase de `dev`) qui implique obligatoirement des temps d'arrêt humains (pour coder le correctif et passer la revue LLM requise par les règles du projet). Or, l'interface du script n'est pas définie (pas de mention de sous-commandes comme `start` ou `finish`). Par ailleurs, on ignore qui effectue la fusion et pose le tag : le script lui-même, l'utilisateur via l'UI de la forge, ou l'utilisation d'un autre skill comme `release` ou `verify-and-merge-pr`.
  - **Correction attendue :** Définir clairement les points d'entrée du script (ses arguments ou sous-commandes) et préciser qui orchestre la PR vers `main` et la création du tag annoté incrémenté.
  - **Risque :** Le développeur devra inventer l'interface et pourrait concevoir un script monolithique qui automatise des actions humaines (fusion sans revue) ou duplique le code d'autres skills.

- **[BLOQUANT]** `Critères d'acceptation`
  - **Constat :** Lors de l'étape « `dev` est rebasée sur `main` », le cas d'un conflit de fusion n'est pas envisagé. Un correctif urgent apporté sur `main` peut très souvent entrer en conflit avec les développements en cours sur `dev`.
  - **Correction attendue :** Définir le comportement attendu du script en cas d'échec de la commande de rebase (ex: arrêt propre en indiquant à l'utilisateur de résoudre le conflit manuellement, ou fourniture d'une commande de reprise).
  - **Risque :** Une erreur qui passe sous silence (le rebase s'arrête, mais le script tente de continuer) ou le script s'interrompt brutalement sous `set -e` en laissant le dépôt dans un état instable et sans consigne pour l'utilisateur.

- **[BLOQUANT]** `Critères d'acceptation`
  - **Constat :** La condition « seulement après l'approbation explicite d'Arnaud au moment de l'opération » pour le force-push ne spécifie pas le mécanisme technique de cette approbation.
  - **Correction attendue :** Préciser comment le script recueille cet accord : s'agit-il d'une invite interactive (`read -p`) ou de l'exigence d'un argument explicite (ex: `--confirm-force-push`) ?
  - **Risque :** Implémentation d'un mécanisme non interactif caché, ou inversement, d'un prompt interactif qui bloquerait si le script venait à être exécuté dans un contexte automatisé.

- **[NON BLOQUANT]** `Critères d'acceptation`
  - **Constat :** Le critère « Étant donné un utilisateur autre qu'Arnaud / Gitea la refuse » s'appuie sur une configuration serveur de la forge (réglages de la story 0.2). Le script n'a pas la responsabilité ni la capacité technique de tester ce rejet en exécution normale avec le jeton d'Arnaud.
  - **Correction attendue :** Préciser qu'il s'agit d'un rappel du comportement garanti par Gitea et non d'un comportement à tester par le code du script ou ses tests automatisés.
  - **Risque :** Perte de temps à essayer d'écrire un test unitaire shell simulant un second compte Gitea avec un jeton invalide.

##### Lentille : Structure

- **[BLOQUANT]** `Général`
  - **Constat :** Les critères d'acceptation écrasent la chronologie du cycle de vie du correctif. L'événement déclencheur « Quand un correctif démarre » conduit à la fusion et au tag, tandis que l'événement « Quand le script poursuit » amène au rebase. La notion de « le script poursuit » est structurellement ambiguë pour un script shell qui doit se terminer pour rendre la main.
  - **Correction attendue :** Structurer les critères d'acceptation autour des appels concrets au script (ex: **Quand** on lance `hotfix.sh start` / **Quand** on lance `hotfix.sh finish`).
  - **Risque :** Incompréhension de l'architecture du script (processus long vs appels successifs).

##### Lentille : Prose

- **[NON BLOQUANT]** `Critères d'acceptation`
  - **Constat :** L'usage de formes réflexives et passives (« la PR vers main se fusionne », « le tag [...] est posé ») obfusque délibérément l'agent de l'action.
  - **Correction attendue :** Employer la voix active pour désigner sans équivoque qui agit (ex: « le script fusionne la PR », ou « l'utilisateur fusionne manuellement »).
  - **Risque :** Flou dommageable dans l'attribution des responsabilités entre l'automatisation du script et l'action humaine.

##### À trancher avant d'implémenter

- **Interface du script :** `hotfix.sh` doit-il fonctionner par sous-commandes (comme `hotfix.sh start` pour brancher depuis `main`, et `hotfix.sh finish` ou `sync` pour rebaser `dev` après publication) afin de gérer l'interruption pour le développement du correctif ?
- **Responsabilité de fusion/tag :** Le script doit-il s'occuper de créer la PR, de la fusionner et d'incrémenter le tag annoté lui-même, ou délègue-t-il certaines de ces opérations au skill `release` et à l'humain ?
- **Gestion des conflits :** Comment `hotfix.sh` réagit-il si le rebase de `dev` sur `main` échoue pour cause de conflits ?
- **Mécanisme d'approbation :** L'approbation explicite au moment du push forcé doit-elle se faire par une confirmation au clavier dans le terminal (`read -p`) ou par l'ajout d'un flag en ligne de commande (ex: `--yes-force-push`) ?

### Tri des constats (05/10/2026, orchestrateur)

Le rapport du relecteur est publié deux fois, avec entre les deux un fragment de son raisonnement
(« This structure respects all constraints… ») : anomalie de sortie de l'outil, sans effet sur le
fond ; les deux versions portent les mêmes constats, triés ici une seule fois.

| # | Constat | Décision |
|---|---|---|
| A1 | Interface du script et partage des responsabilités non définis (BLOQUANT) | **Retenu : arbitrage d'Arnaud (Q1)** — trois sous-commandes, ci-dessous. |
| A2 | Conflit au rebase de `dev` sur `main` non traité (BLOQUANT) | **Retenu : arbitrage d'Arnaud (Q3).** |
| A3 | Mécanisme de l'approbation du push forcé non défini (BLOQUANT) | **Retenu : arbitrage d'Arnaud (Q2).** |
| A4 | « Gitea refuse un autre compte » n'est pas testable par le script | **Retenu** : c'est le réglage de la story 0.2 (liste de push de `dev`), rappelé dans la procédure et constaté à la main, pas un cas de test. |
| S1 | Les critères mêlent les moments du cycle de vie | **Retenu** : couvert par l'interface en sous-commandes. |
| P1 | Voix passive : qui fusionne, qui tague ? | **Retenu** : `publish --merge`, lancé par Arnaud, fusionne et tague ; `sync --push`, lancé par Arnaud, pousse. |

**Arbitrages d'Arnaud (05/10/2026)** — options présentées, y compris celles que l'orchestrateur écartait :

| # | Question | Réponse | Options écartées |
|---|---|---|---|
| Q1 | Interface | **Trois sous-commandes** : `start <slug>` (branche `hotfix/<slug>` depuis `origin/main`, après l'invariant « `main` ancêtre de `dev` ») ; `publish` (audit : PR `hotfix/*` → `main`, verrous) puis `publish --merge` (fusion fast-forward, relecture des branches, tag annoté poussé) ; `sync` (audit : rebase local de `dev` sur `main`) puis `sync --push` (`--force-with-lease`, puis liste des PR ouvertes vers `dev` à rebaser et relire) | un script unique à pauses interactives ; `sync` seul, le reste à la main |
| Q2 | Approbation du push forcé | **Option explicite `sync --push`, lancée par Arnaud** ; sans elle, rien n'est poussé et le script dit l'état de `dev` local | question au clavier ; option et question |
| Q3 | Conflit au rebase | **Arrêt, rebase laissé en cours**, avec la consigne : résoudre, `git rebase --continue`, relancer `sync` | arrêt et `git rebase --abort` |
| Q4 | Numéro du tag | **Calculé par le script** : le correctif suivant (`Z+1`) de la dernière version `vX.Y.Z` portée par `main` | donné par Arnaud et vérifié |

## Implémentation

### Ce qui est livré

| Fichier | Rôle |
|---|---|
| `scripts/hotfix.sh` | le script, trois sous-commandes (arbitrage Q1) |
| `scripts/lib/hotfix.sh` | ses décisions : nom du correctif, tag calculé, rebase en cours, état de synchronisation, masquage de l'adresse, liste paginée des PR vers `dev` ; charge `scripts/lib/release.sh` |
| `scripts/lib/release.sh` | quatre fonctions **factorisées** depuis `release.sh` et partagées par les deux chemins vers `main` : `release_find_open_pr`, `release_private_text`, `release_merge_response`, `release_push_tag` |
| `scripts/release.sh` | appelle ces quatre fonctions au lieu de son code en ligne ; comportement inchangé (`test-release.sh` : 41 cas verts avant et après) |
| `scripts/tests/test-hotfix.sh` | 68 cas, hors ligne |
| `.claude/skills/hotfix/SKILL.md`, liens `.agents/skills/hotfix` et `.agent/skills/hotfix` | le skill, liens symboliques relatifs vers le dossier de `.claude/skills/`, exactement comme `release` |
| `docs/procedures/hotfix.md` | la procédure, qui fait foi |
| `AGENTS.md`, `README.md`, `docs/procedures/release.md` | passés au présent : le skill existe (point 8) |

### Interface, telle qu'implémentée

```
scripts/hotfix.sh start <nom>       # hotfix/<nom> depuis origin/main relue ; ne pousse rien
scripts/hotfix.sh publish           # audit : PR hotfix/<nom> → main ouverte si besoin, cinq verrous
scripts/hotfix.sh publish --merge   # Arnaud : fast-forward-only sur la tête exacte, relecture, tag calculé posé et poussé
scripts/hotfix.sh sync              # dev locale remise sur origin/dev, rebasée sur origin/main ; ne pousse rien
scripts/hotfix.sh sync --push       # Arnaud : push --force-with-lease=dev:<origin/dev lue avant le rebase>, puis PR vers dev listées
```

Codes : `0` / `1` refus / `2` anomalie, comme `release.sh`. Aucune option `--force`, aucune question au
clavier : l'option est l'approbation (Q2).

### Décisions prises pendant l'implémentation

- **Ordre revue / PR.** La revue du code a besoin d'un numéro de PR : le premier `publish` ouvre la
  PR en audit (comme `release`), son verrou de revue bloque en nommant la commande
  `.working-method/review/llm-review.sh <PR>`, puis un second `publish` passe au vert.
- **Pas de numéro de story sur une branche `hotfix/*`** (AGENTS.md, point 1 : « a branch that
  delivers no story carries no number »). Le nom doit commencer par une lettre, ce qui l'interdit
  mécaniquement ; le verrou de suivi de sprint est le contrôle **global**
  (`sprint-consistency.sh --rev <tête>`), comme pour `release`. Pas de fichier de story : les
  décisions sur les constats de la revue vont dans un commentaire de la PR (règle 9 commune, PR sans
  story).
- **Revue sur la tête seulement.** Sans story, aucun commit de statut ne suit la revue : le rapport
  sur le parent que `verify-and-merge-pr` admet n'a pas d'objet. Un rapport `base=dev` ne compte pas.
- **Tag calculé (Q4)** : plus haut `vX.Y.Z` atteignable depuis `origin/main`, comparaison numérique,
  expression `release_tag_production` réutilisée (aucune seconde expression). Un `-rc` n'est **jamais
  retenu** comme base du calcul. La consigne « refuser si un -rc serait retenu » est lue ainsi : le
  filtre l'empêche par construction, et un test le prouve (`v1.10.7-rc.1` atteignable depuis `main`
  est ignoré). En revanche, si une répétition porte déjà le numéro calculé (`vX.Y.(Z+1)-rc.N` sur
  `dev`), c'est un **avertissement**, pas un refus : le numéro n'étant pas un paramètre, refuser
  bloquerait un correctif urgent sans issue. **À confirmer par Arnaud** (voir « Doutes »).
- **PR retrouvée quelle que soit sa base** : une PR `hotfix/<nom>` → `dev` ouverte à la main bloque
  au verrou 1 au lieu de laisser ouvrir une seconde PR.
- **Garde ajoutée, absente de `release`** : aucun commit de fusion dans `main..hotfix/<nom>` (le
  fast-forward porterait la branche telle quelle) ; la branche doit descendre de `origin/main` (sinon
  rebaser la branche du correctif, ce qui n'est pas une réécriture de branche protégée).
- **Après la fusion**, relancer `publish` ne peut plus poser le tag (la PR n'est plus ouverte) : chaque
  message d'échec post-fusion donne les commandes exactes (`git tag -a … <SHA complet>`,
  `git push origin refs/tags/…`). Le « relancer » de `release.sh` dans la même situation n'est pas
  repris ; `release.sh` n'est pas modifié sur ce point (hors périmètre, à signaler).
- **État de synchronisation** : `git rev-parse --git-path hotfix-sync` (dossier git, jamais suivi,
  propre au worktree), deux SHA écrits **avant** le rebase — `lease` (origin/dev) et `main`. Il sert
  à reprendre après un conflit (Q3) et à pousser plus tard avec le bail de l'audit. Relu, il est
  confronté à la forge : si `main` ou `dev` ont bougé, refus avec la commande pour recommencer.
- **`dev` locale** : remise sur `origin/dev` (`checkout -B`), sauf si elle porte des commits absents
  de la forge (refus : la remettre les jetterait).
- **Rebase** : `-c rebase.autoStash=false -c rebase.autoSquash=false -c rebase.updateRefs=false`,
  pour que la configuration du poste ne change pas ce qui est poussé.
- **Reprise** : rebase en cours sur `refs/heads/dev` **et** état présent → `git rebase --continue`
  (avec `GIT_EDITOR=true`) ; rebase étranger ou de `dev` commencé à la main → refus. Jamais de
  `--abort`, jamais de second rebase.
- **`--push`** : `.env` et jeton vérifiés **avant** tout geste ; push refusé dit tel quel, messages de
  git affichés adresse masquée (`hotfix_mask_remote`), sans reprise ; relecture après le push
  (`origin/dev` = dev poussée, `origin/main` ancêtre), puis l'état est effacé ; les PR vers `dev`
  sont listées avec `git rebase --onto origin/dev <ancienne tête>`, le push avec bail de la branche
  et la commande de revue.
- **Branches de base lues dans `workflow.config`** (`forge.base`, `forge.release-branch`), pas en dur
  (`shell-scripts.md`) ; `release.sh` les garde en dur, inchangé.
- La branche `hotfix/<nom>` n'est pas supprimée après la fusion (comme `release` ne supprime rien).

### Fichiers jumeaux — le parcours de la règle 8

Aîné 1 : `scripts/release.sh` (+ `scripts/lib/release.sh`, `release.md`, `SKILL.md`, `test-release.sh`).

| Garde de l'aîné | Le cadet en a-t-il besoin ? |
|---|---|
| `set +x` avant le jeton ; `die` 2 / `refuse` 1 | oui, repris |
| `require_tools` (jq, curl) | oui |
| `config_load`, `gitea_configure`, `check_origin` avant toute action | oui |
| `check-private.sh` et `sprint-consistency.sh` exécutables | oui (`publish`) |
| fichier de motifs présent et non vide (`require_patterns_file`) | oui (`publish`) ; inutile à `start` et `sync`, qui n'envoient aucun contenu nouveau |
| arbre propre avant toute action | oui, aux trois sous-commandes (sauf pendant la reprise d'un rebase, où l'index porte la résolution) |
| invariant `main` ancêtre de `dev`, code 2 de `--is-ancestor` distingué | oui : refus à `start` ; à `sync`, c'est la condition « rien à faire » ; fonction `is_ancestor` qui meurt sur un code > 1 |
| « rien à publier » (`main` = tête) | oui |
| tag libre, code de `rev-parse` lu (pas de `\|\| true`) | oui, sur le tag **calculé** |
| expression de tag `release_tag_production` | oui, réutilisée ; rc écartés par elle |
| répétition `-rc` de même arbre (AD-22) | non : un correctif n'est pas répété ; seule la collision de numéro avec une répétition est signalée |
| complétude du socle pour `v1.0.0` | non : un correctif suit toujours une mise en ligne |
| `.env` lu sans valeur affichée, pointeur vers la procédure du jeton | oui (`load_gitea_env`), à `publish` et `sync --push` |
| jeton du bon compte (`check_token_owner`) | oui |
| PR existante cherchée sur toutes les pages, plafond | oui — **factorisé** (`release_find_open_pr`), base `*` pour le cadet |
| titre et corps confrontés aux motifs | oui — **factorisé** (`release_private_text`) |
| `mergeable: null` relu avec attente bornée | oui (appel à la forge : reste dans le script, règle de `shell-scripts.md`) |
| verrou 1 : ouverte, pas brouillon, fusionnable, branches, tête = tête attendue | oui, tête = tête **poussée** |
| verrou 2 : provenance des commits (`release_unverified_commits`) | non : un correctif est relu par `llm-review` sur la tête (`read_timeline_reports`, `last_report` de `merge-gates.sh`) |
| verrou 3 : `check-private.sh history` sur la plage | oui, `origin/main..tête` |
| verrou 4 : CI, amorçage refusé | oui |
| verrou 5 : suivi de sprint global | oui |
| `--merge` explicite ; rien sans lui | oui |
| tête relue avant la fusion | oui |
| `fast-forward-only` + `head_commit_id`, ni `force_merge` ni suppression de branche | oui |
| 405 transitoire repris, 405 de style, 500 Diverging | oui — **factorisé** (`release_merge_response`) |
| PR relue après fusion | oui |
| `git fetch` avant le tag, `origin/main` = commit fusionné | oui (seulement `main` : `dev` n'est pas concernée par un correctif) |
| tag annoté, poussé, tag local retiré si le push échoue | oui — **factorisé** (`release_push_tag`) |
| adresse de la forge jamais affichée (git muet) | oui ; et `sync --push` affiche les messages du push **masqués** |
| messages de suite (Actions, `deploy-site status`) | oui, plus la suite `sync` |

Aîné 2 : `scripts/rehearse-release.sh`.

| Garde de l'aîné | Le cadet en a-t-il besoin ? |
|---|---|
| geste irréversible jamais déduit, option explicite (`--run`) | oui : `--merge` et `--push` |
| l'audit ne fait rien d'irréversible | oui : `start` ne pousse rien ; `publish` ouvre seulement la PR (comme `release`) ; `sync` rebase en local |
| toutes les vérifications avant le premier effet | oui : `.env` vérifié avant le rebase avec `--push` ; tag calculé et vérifié avant l'API |
| messages qui nomment les variables, jamais leurs valeurs | oui (`load_gitea_env`) |
| `LC_ALL=C` (plages de caractères) | non nécessaire : les expressions du cadet portent sur des noms ASCII et des SHA ; les tests posent `LC_ALL=C` |
| agent ssh, valeurs légales, tunnel | non : sans objet |

Aînés 3 et 4 : `.working-method/gates/verify-and-merge-pr.sh` refuse toute PR vers `main`
(`base_gate`) — d'où le chemin propre ; ses lectures de rapports (`read_timeline_reports`,
`last_report`) sont **réutilisées**, pas recopiées. `.working-method/gitea/create-pull-request.sh`
refuse `hotfix/*` (préfixe hors de `forge.branch-prefixes`) ; ses gardes (motifs dans le titre et le
corps, PR déjà ouverte, branche poussée au même commit) sont reprises par `publish`.

### Comportements de git vérifiés (règle 6 commune)

Lancés avec git 2.53.0, sur un dépôt nu et un clone jetables (dossier temporaire de la session) :

| Commande | Résultat constaté |
|---|---|
| `git push --force-with-lease=dev:<ancien SHA> origin dev` après un push concurrent sur la forge | `! [rejected] dev -> dev (stale info)`, code 1 |
| la même avec la valeur actuelle de la forge | `forced update`, code 0 |
| `git push --force-with-lease origin dev` (nu), forge déplacée, **sans** fetch | rejeté (`stale info`) |
| la même **après** un `git fetch` qui a recopié le commit concurrent | `+ … (forced update)`, code 0 : **le commit concurrent est écrasé** — d'où le bail explicite |
| `git ls-remote --heads origin refs/heads/inexistante` | sortie vide, code 0 |
| `git fetch origin inexistante` | `fatal: couldn't find remote ref`, code 128 — d'où `ls-remote` pour lire la tête d'une branche |
| `git rebase main` en conflit | code 1, `.git/rebase-merge/head-name` = `refs/heads/dev`, fichier en `UU` |
| `GIT_EDITOR=true git rebase --continue`, conflit non résolu | code 1, rebase toujours en cours |
| la même après `git add` | code 0, `rebase-merge` disparu, `HEAD` sur `dev` |
| `git rev-parse --git-path rebase-merge` / `hotfix-sync` | `.git/rebase-merge`, `.git/hotfix-sync` |
| `git tag --list 'v*' --merged main` | les seuls tags atteignables depuis `main` (`v1.0.2-rc.1` posé sur `dev` absent) |
| `git checkout -B dev origin/dev` | remet `dev` sur `origin/dev`, avec son suivi |

Les tests rejouent les trois premiers comportements sur un **vrai dépôt nu** (le faux git ne fait que
rediriger `fetch`, `push` et `ls-remote` par `url.<dossier>.insteadOf`), y compris le cas où un fetch a
déjà recopié le commit concurrent (mutation M43).

### Tests et mutations (règle 5 commune)

`scripts/tests/test-hotfix.sh` : 68 cas. Chaque garde ci-dessous a été retirée une fois (script de
mutation hors du dépôt, fichier restauré octet pour octet et vérifié par empreinte), le cas nommé lancé,
et **vu échouer** ; chaque cas passe sans mutation.

| # | Garde retirée | Cas qui tombe |
|---|---|---|
| M01 | nom du correctif (kebab-case, lettre en tête) | `start_nom_refuse` |
| M02 | invariant `main` ancêtre de `dev` à `start` | `start_invariant_rompu` |
| M03 | branche locale existante | `start_branche_locale_existante` |
| M04 | branche existante sur la forge | `start_branche_distante_existante` |
| M05 | branche tirée de `origin/main` relue (et non de `main` locale) | `start_nominal` |
| M06 | arbre propre à `start` | `start_arbre_sale` |
| M07 | `publish` sur une branche `hotfix/*` | `publish_hors_branche_hotfix` |
| M08 | branche poussée | `publish_branche_non_poussee` |
| M09 | tête locale = tête de la forge | `publish_tete_locale_differente` |
| M10 | branche qui descend de `origin/main` | `publish_main_a_avance` |
| M11 | aucun commit de fusion | `publish_commit_de_fusion` |
| M12 | quelque chose à publier | `publish_rien_a_publier` |
| M13 | tags `-rc` écartés du calcul | `tag_calcule_numerique` |
| M14 | comparaison numérique des versions | `tag_calcule_numerique` |
| M15 | aucun tag de production → refus | `tag_aucun_tag_de_production` |
| M16 | tag calculé libre | `tag_calcule_deja_pris` |
| M17 | répétition du même numéro avertie | `tag_repetition_du_meme_numero` |
| M18 | motifs dans le titre et le corps | `publish_motif_prive_dans_le_titre` |
| M19 | PR retrouvée quelle que soit sa base | `publish_pr_vers_dev_bloque` |
| M20 | base et branche de la PR | `publish_pr_vers_dev_bloque` |
| M21 | tête de la PR = tête poussée | `publish_tete_de_pr_decalee` |
| M22 | brouillon | `publish_pr_en_brouillon` |
| M23 | `mergeable: null` relu | `publish_mergeable_nul_puis_vrai` |
| M24 | rapport de revue exigé | `revue_absente` |
| M25 | rapport sur la base `main` | `revue_sur_une_autre_base_ne_suffit_pas` |
| M26 | verdict `pass` | `revue_bloquante` |
| M27 | garde-fou | `garde_fou_refuse` |
| M28 | amorçage refusé | `ci_absente_refuse_l_amorcage` |
| M29 | suivi de sprint | `suivi_de_sprint_incoherent` |
| M30 | `--merge` explicite | `publish_ouvre_la_pr_sans_rien_fusionner` |
| M31 | verrou bloquant arrête `--merge` | `merge_refuse_si_verrou_bloque` |
| M32 | tête relue avant fusion | `merge_tete_bougee_pendant_l_audit` |
| M33 | 405 transitoire repris | `merge_405_transitoire` |
| M34 | 405 de style non repris | `merge_405_persistant` |
| M35 | 500 Diverging nommé | `merge_500_divergence` |
| M36 | PR relue après fusion | `fusion_non_confirmee` |
| M37 | `origin/main` relue = tête avant le tag | `tag_refuse_si_main_non_relue` |
| M38 | tag local retiré si le push échoue | `push_du_tag_en_echec` |
| M39 | rien à synchroniser | `sync_rien_a_synchroniser` |
| M40 | arbre propre à `sync` | `sync_arbre_sale` |
| M41 | `dev` remise sur `origin/dev` | `sync_dev_locale_perimee_remise` |
| M42 | `dev` locale en avance refusée | `sync_dev_locale_en_avance_refusee` |
| M43 | bail **explicite** (remplacé par un bail nu) | `sync_push_bail_refuse` |
| M44 | `dev` inchangée sur la forge depuis l'audit | `sync_push_forge_a_bouge_depuis_l_audit` |
| M45 | `main` inchangée depuis l'audit | `sync_push_main_a_bouge_depuis_l_audit` |
| M46 | `main` ancêtre de `dev` locale | `sync_rebase_abandonne` |
| M47 | synchronisation poussée depuis `dev` | `sync_push_hors_de_dev` |
| M48 | conflit : arrêt, rebase laissé en cours | `sync_conflit_laisse_le_rebase_en_cours` |
| M49 | rebase en cours repris | `sync_reprise_apres_git_add` |
| M50 | aucun second rebase sur un conflit non résolu | `sync_relance_sur_conflit_non_resolu` |
| M51 | rebase d'une autre branche refusé | `sync_rebase_etranger_refuse` |
| M52 | rebase de `dev` non commencé par `sync` refusé | `sync_rebase_de_dev_non_commence_par_sync` |
| M53 | `--push` explicite | `sync_audit_ne_pousse_rien` |
| M54 | `.env` vérifié avant le rebase avec `--push` | `sync_push_env_absent` |
| M55 | push refusé : arrêt, sans reprise | `sync_push_branche_protegee` |
| M56 | `origin/dev` relue = dev poussée | `sync_push_dev_rebougee_apres_le_push` |
| M57 | adresse masquée dans les messages de git | `sync_push_bail_refuse` |
| M58 | seules les PR vers `dev` listées | `sync_push_nominal` |
| M59 | `.env` pour `publish` (renvoi à la procédure du jeton) | `publish_env_incomplet` |
| M60 | aucun `git cherry-pick` dans le code | `aucun_cherry_pick_dans_le_code` |

Première passe : M56 **survivait** — le commit poussé « après nous » ne contenait pas `main`, si bien
que la garde suivante (`main` ancêtre de `dev`) le prenait à sa place. Le cas pousse désormais `main`
elle-même, que seule la comparaison de `origin/dev` à la dev poussée voit. Le contrôle dynamique
« aucun cherry-pick » relit le journal des appels à git dans les cas nominaux de `publish --merge`,
`sync` et `sync --push` et dans la reprise après conflit.

**Trouvé par shellcheck 0.11.0** (épinglé, `.working-method/ci/ensure-shellcheck.sh`) : une apostrophe
dans une chaîne entre apostrophes (consigne 3 de `start`, « tant qu'elle n'a pas eu lieu ») rendait
« tant quelle na pas ». Corrigé, et `start_nominal` vérifie désormais le texte rendu. Balayage de la
classe (règle 7) : shellcheck n'en signale aucune autre dans les trois fichiers. shellcheck
`-x` sur `scripts/hotfix.sh`, `scripts/lib/hotfix.sh` et `scripts/tests/test-hotfix.sh` : aucun constat.
Sur `scripts/release.sh` et `scripts/lib/release.sh`, les constats sont les mêmes avant et après la
factorisation (aucun nouveau ; le projet ne lance pas shellcheck en CI).

### Doutes

- **Répétition du même numéro** : avertissement plutôt que refus (voir plus haut). À trancher par
  Arnaud si la consigne « refuser si un -rc serait retenu » voulait dire « refuser si
  `vX.Y.(Z+1)-rc.N` existe ».
- **Réglage de la story 0.2** : le refus d'un autre compte au force-push n'est pas testable (aucun
  autre compte) ; la procédure le donne comme vérification manuelle par l'API.
- **Miroir GitHub** : l'acceptation d'une réécriture de `dev` par le miroir relève de la story 1.4
  (case de la spec) ; non éprouvée ici, faute de vrai correctif.

## Revue du code

### 05/10/2026 — PR n° 145, `gemini-3.1-pro-high`, SHA `0a0efd2`, verdict `pass`

Rapport recopié de la PR (le script a tourné depuis le dépôt principal, sur une autre branche). La
branche avait été rebasée sur `dev` après la PR n° 144 ; l'orchestrateur a rejoué la suite (1007 cas,
1 ignoré faute de `docs/private/` dans la copie), la cohérence du suivi, le garde-fou, et constaté que
la forge n'a pas été touchée par l'implémentation (`main` sur `v1.0.1`, aucun tag nouveau, aucune
branche `hotfix/*`).

llm-review sha=0a0efd2f37e139e297cb26e50add7e63a0eb093a base=dev model=gemini-3.1-pro-high verdict=pass

_Revue par `review/llm-review.sh` du dépôt commun : `agy --mode plan`, copie isolée hors du dépôt au SHA relu, sans `.git` ni les chemins privés du projet (.env docs/private .pr-body.md) ; méthode de revue de la couche projet appliquée par le relecteur (angles : edge-case-hunter, verification-gap, plus la couche propre au projet). Fichiers créés ou modifiés par le relecteur dans la copie : aucun._

JETON: 41c68a591208be38063bb50b

### Revue du code (`REVIEW-DIFF.patch`)

#### Lentille : Edge-case-hunter
Aucun cas limite non géré n'a été trouvé. Le script gère l'intégralité des chemins de contrôle de manière explicite :
- Les appels potentiellement défaillants à `git` (`fetch`, `rebase`, `tag`) ou `jq` sont interceptés via des codes de retour conservés (`|| code=$?`), et les retours vides imprévus sont validés.
- Les états transitoires (405 temporaires au lieu des 405 de style) ou résiduels d'un `rebase` sont rigoureusement distingués et manipulés.
- L'utilisation de bails explicites (`--force-with-lease=dev:<valeur_precedente>`) protège contre les accès concurrents inaperçus sans provoquer de silence dangereux.

#### Lentille : Verification-gap
Aucune faille de vérification trouvée (No verification gaps found).
- **Missing-adoption gap** : La factorisation de `release.sh` vers `lib/release.sh` (`release_find_open_pr`, `release_private_text`, `release_merge_response`, `release_push_tag`) a été intégralement adoptée par `scripts/release.sh` (et par extension `hotfix.sh`), sans aucune perte de couverture sur les gardes existantes ou les comportements en cas d'erreur.
- **Regression gap** : La logique est couverte par la vaste suite de tests non connectés (68 cas dans `test-hotfix.sh`) dont le comportement simule fidèlement un dépôt nu distant. Les comportements de suppression ou de conservation d'un tag local en cas d'échec distant demeurent inchangés.

#### Contrôles propres au projet
- **Critères d'acceptation** : NON BLOQUANT. Les sous-commandes de la story 11.12 (`start`, `publish`, `publish --merge`, `sync`, `sync --push`) sont précisément implémentées ; la pause requise pour l'audit et l'intervention humaine ciblée (`--merge` et `--push`) sont respectées.
- **Données privées et secrets** : NON BLOQUANT. Aucune fuite à signaler. La fonction `hotfix_mask_remote` neutralise parfaitement les mentions à la forge dans les messages de la sortie standard et standard d'erreur. Les vérifications de titre/corps `.md` passent correctement par `release_private_text`.
- **Concordance** : NON BLOQUANT. L'implémentation de `hotfix.sh` concorde avec sa documentation (`docs/procedures/hotfix.md`) et le contenu du point d'entrée LLM (`SKILL.md`).
- **Cohérence architecture / AGENTS.md** : NON BLOQUANT. Respect intégral de la règle de rédaction (parcours 8 : les promesses rédigées au futur ont été adaptées au présent).
- **Scripts shell & `set -euo pipefail`** : NON BLOQUANT. Les exécutions en sous-shells ou conditionnelles (`if code=$(...)`) sont immunisées contre l'interruption silencieuse inopinée, les variables vides sont vérifiées en amont.

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue (orchestrateur)

Sept constats de conformité, sans demande de changement : **pris acte**, un par un — cas limites
couverts (codes conservés, 405 transitoire distingué, bail explicite) ; aucune faille de
vérification (factorisation adoptée par `release.sh`, 68 cas hors ligne sur un dépôt nu) ; critères
satisfaits ; aucune fuite (`hotfix_mask_remote`, `release_private_text`) ; concordance script,
procédure, skill ; documents au présent ; aucune erreur silencieuse.

**Arbitrage d'Arnaud sur le doute de l'implémentation (05/10/2026) : option 1.** Quand un tag de
répétition `vX.Y.(Z+1)-rc.N` existe déjà sur le numéro calculé, `publish` **avertit et continue** :
un refus bloquerait un correctif urgent sans issue, le numéro n'étant pas un paramètre (Q4). Option
écartée : refuser. Le code n'en change pas.

**Reporté, hors périmètre** : les messages de `release.sh` après une fusion réussie disent
« relancer », alors qu'une relance ne pose pas le tag d'une PR déjà fusionnée ; `hotfix` donne les
commandes manuelles. Entrée dans `deferred-work.md`.
