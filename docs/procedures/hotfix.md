# Procédure — Corriger la production

Un correctif de production part de `main` sur une branche `hotfix/*`, revient dans `main` par une PR fusionnée en **fast-forward**, reçoit le tag `vX.Y.(Z+1)` qui le met en ligne, puis `dev` est **rebasée** sur `main` et poussée en `--force-with-lease` (AD-24, D-14). Aucun merge commit, **aucun cherry-pick** : un commit recopié dans `dev` casserait le fast-forward de la publication suivante (ADR-18). `scripts/hotfix.sh` tient toute la chaîne côté poste, en trois sous-commandes.

**Deux gestes sont des décisions humaines** : la fusion vers `main` (`publish --merge`) et le push forcé de `dev` (`sync --push`). Un agent lance librement `start`, `publish` et `sync` sans option, qui ne fusionnent, ne taguent et ne poussent rien ; il ne passe `--merge` ou `--push` qu'après l'autorisation explicite d'Arnaud, donnée pour ce correctif, au moment de l'opération (arbitrage Q2 de la story 11.12). Le script ne pose aucune question au clavier : l'option *est* l'approbation, et sans elle il s'arrête en disant l'état.

## Prérequis

- `jq` et `curl` installés ; `.env` avec `GITEA_URL`, `GITEA_USER` et `GITEA_TOKEN` pour `publish` et `sync --push` (story 0.1, `.working-method/procedures/gitea-token.md`). Une variable manquante arrête le script en renvoyant à cette procédure, sans jamais afficher une valeur.
- Le fichier de motifs (`check-private.md`), avec au moins un motif, pour `publish` : aucun correctif sans audit.
- `scripts/check-private.sh` et `.working-method/gates/sprint-consistency.sh` présents dans l'arbre de travail.
- Une production existe : au moins un tag `vX.Y.Z` atteignable depuis `main`. La première mise en ligne passe par `release`.

## Lancer

```bash
scripts/hotfix.sh start <nom>        # crée hotfix/<nom> depuis origin/main ; ne pousse rien
scripts/hotfix.sh publish            # audit : ouvre la PR hotfix/<nom> → main si besoin, affiche les verrous
scripts/hotfix.sh publish --merge    # Arnaud : fusion fast-forward-only, puis tag calculé posé et poussé
scripts/hotfix.sh sync               # rebase une dev locale, tirée de origin/dev, sur origin/main ; ne pousse rien
scripts/hotfix.sh sync --push        # Arnaud : push forcé de dev avec bail, puis liste des PR à reprendre
```

Code de sortie : `0` l'étape est faite (ou, en audit, tous les verrous passent ; ou il n'y a rien à synchroniser) ; `1` refus — nom ou branche refusés, invariant rompu, verrou bloquant, refus de la forge, conflit de rebase à résoudre, push refusé ; `2` anomalie — usage, outil absent, `.env` incomplet, fichier de motifs absent, arbre modifié, dépôt distant qui n'est pas `Eleyone/eleyone.fr`, forge injoignable, réponse illisible, état incohérent après une fusion ou un push.

Il n'existe aucune option `--force`. Le script n'envoie jamais `force_merge` ni `merge_when_checks_succeed`, ne supprime aucune branche et ne lance jamais `git cherry-pick` (un cas de test le vérifie sur chaque appel à git et sur le code lui-même). Les messages de git, qui portent l'adresse de la forge, sont tus ou affichés adresse masquée (NFR-9).

## Le déroulé complet

1. `scripts/hotfix.sh start lien-cv-casse` — la branche `hotfix/lien-cv-casse` part de `origin/main` relue sur la forge.
2. Commiter le correctif sur cette branche, puis `git push -u origin hotfix/lien-cv-casse`.
3. `scripts/hotfix.sh publish` — ouvre la PR vers `main` et affiche les verrous. La revue bloque à ce stade : elle a besoin du numéro de la PR, que ce premier `publish` vient de donner.
4. `.working-method/review/llm-review.sh <numéro de PR>` — la revue du code par un LLM d'un autre fournisseur, sur la tête de la PR (règle 1 commune). Chaque constat reçoit une décision écrite (règle 9 commune) : un correctif ne livre pas de story, donc les décisions vont dans un commentaire de la PR, pas dans un fichier de story. Un correctif poussé ensuite déplace la tête : relancer la revue.
5. `scripts/hotfix.sh publish` — tous les verrous au vert.
6. Arnaud : `scripts/hotfix.sh publish --merge` — fusion, tag, livraison.
7. `scripts/hotfix.sh sync` — rebase local de `dev` ; le script dit ce que `--push` fera.
8. Arnaud : `scripts/hotfix.sh sync --push` — `dev` réécrite sur la forge, puis la liste des PR à reprendre.
9. Rebaser chaque PR ouverte vers `dev`, la repousser et la faire relire (voir « Après le push forcé »).

## `start`

Avant de créer quoi que ce soit, dans cet ordre :

1. **Le nom** : minuscules, chiffres et tirets, une lettre en tête (`^[a-z][a-z0-9]*(-[a-z0-9]+)*$`). La lettre en tête écarte aussi un numéro de story : une branche `hotfix/*` ne livre pas de story et n'en porte jamais (AGENTS.md, point 1 : une branche sans story ne porte pas de numéro). Un nom refusé est une anomalie d'usage.
2. Aucun rebase en cours, un arbre de travail propre.
3. **L'invariant d'AD-24** : `origin/main` est un ancêtre de `origin/dev`. Sinon un correctif précédent n'a pas été synchronisé, et le script refuse : en commencer un second empilerait deux réécritures de `dev`. Lancer d'abord `sync`, puis `sync --push`.
4. `hotfix/<nom>` n'existe ni dans le dépôt local ni sur la forge.

La branche est créée sur le commit de `origin/main` relu à l'instant, sans suivi de `main`, et le script s'y place. Il ne pousse rien.

## `publish`

### Avant la forge

Sans appeler l'API :

1. Le script tourne sur une branche `hotfix/<nom>` au nom valide, sans rebase en cours, arbre propre.
2. **La tête est poussée, et c'est celle qu'on a sous les yeux** : `git ls-remote` sur la forge doit rendre exactement la tête locale. Une branche absente de la forge, ou une tête locale différente, est un refus.
3. Il y a un correctif : la tête n'est pas `origin/main`.
4. **La branche descend de `origin/main`.** Si `main` a avancé depuis `start` (une publication, un autre correctif), le fast-forward est impossible : rebaser la branche sur `origin/main`, la repousser — la revue est à refaire sur la nouvelle tête — puis relancer.
5. **Aucun commit de fusion** dans `main..hotfix/<nom>` : le fast-forward porterait la branche telle quelle jusqu'à `main`.

### Le tag, calculé

Le numéro est **calculé** par le script (arbitrage Q4) : le plus haut tag `vX.Y.Z` atteignable depuis `origin/main`, correctif + 1. Les tags sont relus sur la forge (`git fetch --tags`) ; la comparaison est numérique, champ par champ (`v1.10.0` est plus haut que `v1.9.0`). L'expression d'un tag de production est celle de `release`, écrite une seule fois dans `scripts/lib/release.sh`.

- Un tag de répétition `vX.Y.Z-rc.N` n'est **jamais** retenu comme dernière version, même s'il est atteignable depuis `main` après une publication.
- Un tag posé hors de `main` (sur `dev`) n'entre pas dans le calcul.
- Aucun `vX.Y.Z` atteignable : refus — la première mise en ligne passe par `release`.
- Le tag calculé existe déjà (hors de `main`) : refus, rien n'est ouvert.
- Une répétition porte déjà ce numéro (`vX.Y.(Z+1)-rc.N` sur `dev`) : **avertissement** seulement. Le correctif prend le numéro, et la prochaine mise en ligne de `dev` devra prendre le suivant. Refuser bloquerait un correctif urgent sans aucune issue, puisque le numéro n'est pas un paramètre.

### La PR du correctif

Le script cherche, page par page, une PR ouverte depuis `hotfix/<nom>`, **quelle que soit sa base** : une PR `hotfix/*` → `dev` ouverte à la main est retrouvée, et bloque, au lieu de passer inaperçue à côté d'une seconde PR. S'il n'en trouve aucune, il en ouvre une vers `main`, titre `Correctif de production vX.Y.Z : <nom>`, corps généré, tous deux confrontés à la liste des motifs avant l'envoi. Juste après la création, la forge répond `mergeable: null` le temps de calculer : le script relit, avec une attente bornée.

**Ni `create-pull-request` ni `verify-and-merge-pr`** : le premier refuse une branche `hotfix/*` (son préfixe n'est pas dans `forge.branch-prefixes`, et sa base serait `dev`) ; le second refuse toute PR vers `main` (`forge.release-branch`), qui a son propre chemin — `release` pour `dev`, `hotfix` pour un correctif. Le script reprend leurs gardes : motifs dans le titre et le corps, PR existante, relecture de la PR, fonctions des verrous de `.working-method/gates/merge-gates.sh`.

### Les cinq verrous

Chaque verrou s'affiche `passe` ou `bloque`. Il n'y a ni `absent` ni `inactif` ici.

1. **PR fusionnable** : ouverte, `hotfix/<nom>` → `main`, pas en brouillon, fusionnable pour la forge, et sa tête est la tête poussée.
2. **Revue LLM** : le dernier rapport `llm-review sha=<tête> base=main model=… verdict=…` de la timeline de la PR, publié par le compte du jeton, porte `verdict=pass`. **Seul un rapport sur la tête elle-même compte** : un correctif ne livre aucune story, donc aucun commit de statut ne peut suivre la revue, et le rapport sur le parent que `verify-and-merge-pr` admet dans ce seul cas n'a pas d'objet ici. Un rapport `base=dev` ne compte pas non plus.
3. **Garde-fou** : `scripts/check-private.sh history origin/main..<tête>`, avec la liste des motifs.
4. **CI** : les statuts du workflow `checks` sur la tête (le déclencheur `pull_request` couvre toute PR, `main` comprise), avec les règles de `verify-and-merge-pr`. **Le régime d'amorçage est refusé**, comme dans `release` : la production ne se corrige pas sur un `scripts/check.sh` relancé dans une copie locale.
5. **Suivi de sprint** : `.working-method/gates/sprint-consistency.sh --rev <tête>`, le **contrôle global** — la branche ne porte aucun numéro de story.

Sans `--merge`, le script s'arrête ici, quel que soit le résultat.

### Fusion et tag

Avec `--merge`, et seulement si tous les verrous passent :

1. le script relit la PR : si sa tête a bougé pendant l'audit, il s'arrête ;
2. il fusionne en **`fast-forward-only`** sur le SHA de tête exact (`head_commit_id`). Réponses constatées de la forge (AD-24, `gitea-branches.md`) : `405` pour un style interdit ; `500 DivergingFastForwardOnly` si `main` a divergé, qui est un refus — rien n'est réécrit en silence ; `405 « Please try again later »`, **transitoire**, repris de façon bornée. La classification est commune à `release` et `hotfix` (`release_merge_response`) ;
3. il relit la PR : « fusion annoncée mais la PR n'apparaît pas fusionnée » est une anomalie ;
4. **il relit `main` sur la forge** (`git fetch origin main`) avant de taguer. La fusion a eu lieu côté forge : sans cette relecture, `git tag` se poserait sur l'ancien `main`. Si `origin/main` n'est pas la tête fusionnée, aucun tag n'est posé ;
5. il pose le tag annoté calculé sur ce commit et le pousse. Si le push échoue, le tag local est retiré.

**Le push du tag `vX.Y.Z` déclenche le workflow `release`** : contrôles, image `eleyone-site:<tag>`, envoi en production (`release-workflow.md`). Le workflow vérifie que le tag descend de `origin/main` ; pour un tag autre que `v1.0.0`, l'absence de répétition de même arbre n'y est qu'un avertissement (AD-22, D-6). Le script n'attend pas le run : il dit où le suivre et rappelle `deploy-site status` (`release.md`, « Après le tag »).

Une fois la PR fusionnée, relancer `publish` ne pose plus le tag : la PR n'est plus ouverte, et la branche pointe sur `main`. Si le tag n'a pas pu être posé après la fusion, chaque message d'échec donne les commandes qui le posent à la main, sur le commit exact.

La branche `hotfix/<nom>` n'est pas supprimée : elle pointe sur `main` et ne gêne rien ; la supprimer sur la forge est un geste à part.

## `sync` et le push forcé de `dev`

### L'exception au force-push

Le push forcé de `dev` est la **seule** réécriture d'une branche protégée du projet, tracée par AD-24 et D-14 : après un correctif, `main` porte un commit que `dev` n'a pas, la publication suivante en fast-forward est impossible, et la seule façon de rendre `main` ancêtre de `dev` sans cherry-pick ni merge commit est de rebaser `dev` sur `main`. Elle se fait **seulement** par `sync --push`, lancé par Arnaud au moment de l'opération.

**Ce que Gitea garantit** (réglage de la story 0.2, `gitea-branches.md`) : le force-push sur `dev` est limité au compte d'Arnaud (`force_push_allowlist_usernames: Eleyone`) ; tout autre compte ou clé de déploiement est refusé. **C'est une vérification manuelle, pas un cas de test** : le dépôt n'a pas d'autre compte, et le script, lancé avec le jeton d'Arnaud, ne peut pas éprouver le refus d'un autre. La règle se relit par l'API (`gitea-branches.md`, « Vérifier ») après tout changement des protections de branche. `main`, elle, refuse tout push et tout force-push, pour tous les comptes.

### Ce que fait `sync`

1. Si un rebase arrêté sur un conflit est en cours, il le **reprend** (voir « Conflit ») — il n'en commence jamais un second.
2. S'il trouve l'état d'une synchronisation terminée lors d'un lancement précédent (un conflit résolu, ou l'audit lancé avant `--push`), il passe directement à la vérification et au push.
3. Sinon, synchronisation neuve : arbre propre exigé ; lecture de la forge ; si `origin/main` est déjà un ancêtre de `origin/dev`, **rien à synchroniser**, le script le dit et sort en `0`.
4. `dev` locale est **remise** sur `origin/dev` relue à l'instant, jamais rebasée telle quelle : une `dev` locale en retard pousserait une `dev` qui a perdu des PR. Une `dev` locale **en avance** — des commits que la forge n'a pas, ce que la procédure interdit — est un refus : la remettre les jetterait. Les mettre de côté (`git branch <nom> dev`) puis relancer.
5. L'**état** est écrit, avant le rebase, dans le dossier git (`git rev-parse --git-path hotfix-sync`, jamais suivi) : la tête de `origin/dev`, qui sera la valeur du bail, et celle de `origin/main`.
6. Rebase de `dev` sur `origin/main` (`git rebase`, sans remisage automatique, sans `autosquash`, sans déplacement d'autres branches).
7. Vérification : `HEAD` est sur `dev`, arbre propre ; `origin/main` et `origin/dev` n'ont pas bougé sur la forge depuis l'écriture de l'état ; `origin/main` est un ancêtre de `dev` locale.
8. **Sans `--push`** : le script affiche le SHA de `dev` locale, le nombre de commits au-dessus de `main`, et la commande exacte que `--push` lancera. Rien n'est poussé ; l'état est gardé pour le lancement suivant.

### `--push`

Avec `--push`, `.env` et le jeton sont vérifiés **avant tout geste** : un `.env` incomplet découvert après le push forcé laisserait `dev` réécrite sans la liste des PR à reprendre. Puis, après les étapes ci-dessus :

```bash
git push --force-with-lease=dev:<tête de origin/dev lue avant le rebase> origin dev
```

**Le bail porte une valeur explicite**, celle de l'état, jamais un `--force-with-lease` nu. Un bail nu compare à `refs/remotes/origin/dev`, qu'un `git fetch` lancé entre-temps — par un éditeur, un autre terminal — aurait déjà avancée sur un commit concurrent : il l'écraserait. Comportement vérifié avec git 2.53 (fichier de story 11.12, « Comportements de git vérifiés ») et rejoué par `scripts/tests/test-hotfix.sh` sur un vrai dépôt nu.

Un push refusé est dit tel quel, messages de git affichés adresse masquée, **sans aucune reprise** :

- `stale info` : le bail a refusé, quelqu'un a poussé sur `dev` entre-temps. Rien n'a été écrasé. Recommencer (voir plus bas) ;
- tout autre refus : la forge refuse (branche protégée, compte hors de la liste du force-push). Vérifier les réglages de la story 0.2.

Après le push, le script relit la forge : `origin/dev` doit être la `dev` poussée, et `origin/main` en être un ancêtre — sinon c'est une anomalie, et l'état est gardé. Puis il efface l'état.

### Après le push forcé

Chaque PR ouverte vers `dev` repose sur l'ancienne `dev`, et son rapport `llm-review` porte sur un SHA qui n'existe plus dans `dev` (D-14). Le script les liste toutes (API de la forge, lecture seule, toutes pages), avec pour chacune les commandes :

```bash
git fetch origin && git checkout <branche> && git rebase --onto origin/dev <ancienne tête de dev>
git push --force-with-lease=<branche>:<tête de la PR> origin <branche>
.working-method/review/llm-review.sh <numéro>
```

`--onto origin/dev <ancienne tête de dev>` ne rejoue que les commits propres à la PR, même si un conflit résolu pendant le rebase de `dev` a changé un patch. La PR repasse ensuite ses cinq verrous comme toute PR (`verify-and-merge-pr`).

Le miroir GitHub remplace `dev` à la synchronisation suivante, où seul le miroir écrit (AD-12) : vérifier qu'il porte les mêmes SHA (`github-mirror.md`).

### Conflit

Un conflit pendant le rebase **arrête `sync`** et laisse le rebase en cours (arbitrage Q3) — aucun `git rebase --abort` n'est lancé, le travail de résolution n'est jamais jeté. Le script affiche exactement :

1. résoudre les conflits dans les fichiers signalés ;
2. `git add <fichiers résolus>` ;
3. `git rebase --continue` ;
4. relancer `scripts/hotfix.sh sync`.

Au lancement suivant, `sync` reconnaît le rebase en cours (il doit porter sur `dev` et avoir été commencé par `sync`, sinon c'est un refus) et lance lui-même `git rebase --continue` si l'étape 3 n'a pas été faite ; un conflit non résolu, ou un nouveau conflit sur un commit suivant, l'arrête de nouveau avec la même consigne. Si le rebase a été terminé à la main, `sync` reprend à la vérification, avec le bail enregistré avant le rebase.

### Recommencer

Quand l'état ne décrit plus la forge (`main` ou `dev` a bougé depuis le début, un push refusé par le bail, un rebase abandonné), le script le refuse et donne la commande :

```bash
rm <état> ; git fetch origin ; git checkout -B dev origin/dev   # puis relancer scripts/hotfix.sh sync
```

`<état>` est le chemin que le message affiche (`.git/hotfix-sync` dans un clone ordinaire).
