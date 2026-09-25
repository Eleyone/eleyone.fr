# Procédure — Mettre le site en ligne

Une mise en ligne est un **tag `vX.Y.Z` posé sur `main`** après la publication de `dev` en fast-forward (AD-14, AD-24). `scripts/release.sh` tient toute la chaîne côté poste : l'invariant, la PR de publication, les verrous, la fusion et le tag. La livraison elle-même ne lui appartient pas — c'est le workflow `release` de la forge qui construit l'image et l'envoie au serveur (`release-workflow.md`).

**Publier est une décision humaine.** Un agent lance l'audit librement ; il ne lance `--merge` qu'après l'autorisation explicite d'Arnaud, donnée pour cette mise en ligne, au moment de l'opération.

## Prérequis

- `jq` et `curl` installés ; `.env` avec `GITEA_URL`, `GITEA_USER` et `GITEA_TOKEN` (`gitea-token.md`).
- Le fichier de motifs (`check-private.md`), avec au moins un motif : aucune mise en ligne sans audit.
- `scripts/check-private.sh` et `scripts/sprint-consistency.sh` présents dans l'arbre de travail.
- Un arbre de travail sans modification en attente : ce qui n'est pas commité ne sera pas publié.
- Pour `v1.0.0` : la répétition générale déjà jouée (`rehearse-release`, AD-22).

## Lancer

```bash
scripts/release.sh v1.2.3            # audit : ouvre la PR si besoin, affiche chaque verrou, ne fusionne rien
scripts/release.sh v1.2.3 --merge    # publication, seulement si tous les verrous passent
```

Code de sortie : `0` tous les verrous passent (et, avec `--merge`, la publication est faite) ; `1` refus — un verrou bloque, l'invariant est rompu, ou la forge refuse la fusion ; `2` anomalie — usage, `jq` absent, `.env` absent, fichier de motifs absent ou sans motif, dépôt distant qui n'est pas `Eleyone/eleyone.fr`, arbre modifié, forge injoignable, réponse illisible, état incohérent après la fusion.

Il n'existe aucune option `--force`, et le script n'envoie jamais `force_merge` ni `merge_when_checks_succeed`. Il ne supprime aucune branche : une publication ne détruit pas `dev`.

Un tag `vX.Y.Z-rc.N` est refusé d'entrée : c'est une **répétition générale**, qui se pose sur `dev` par `rehearse-release` (AD-22).

## Avant toute action

Dans cet ordre, et sans appeler la forge :

1. **L'invariant d'AD-24** : `main` est un ancêtre de `dev`. Sinon le script refuse et renvoie vers `hotfix`, qui rebase `dev` sur `main` — c'est exactement l'état que laisse un correctif de production.
2. **Il y a quelque chose à publier** : `main` et `dev` ne pointent pas déjà sur le même commit.
3. **Le tag est libre** : un `vX.Y.Z` déjà posé arrête tout, plutôt que d'être poussé sur un autre commit.
4. **La répétition générale** (AD-22, D-6) : un tag `<tag>-rc.N` doit pointer sur un **arbre identique** à la tête de `dev` — l'arbre et non le commit, une signature ou un hotfix changeant le commit sans changer une ligne du site. Pour `v1.0.0`, son absence est un **refus** ; pour tout tag de production suivant, un simple **avertissement**.
5. **La complétude du socle**, pour `v1.0.0` **seulement** (FR-32, D-5) : chaque clé de `ci/base-pages.txt`, la liste figée des neuf pages du socle, doit figurer dans `ci/release-pages.txt`, la liste cumulative. Les deux sont lues **à la tête de `dev`**, l'état qui serait publié : ce sont des fichiers versionnés, pas des artefacts de CI — il n'y a rien à télécharger ni à construire.

## La PR de publication

Le script cherche une PR ouverte `dev` → `main`. S'il n'en trouve pas, il en ouvre une : titre `Mise en ligne <tag>`, corps généré, tous deux confrontés à la liste des motifs avant d'être envoyés. Juste après la création, la forge répond `mergeable: null` le temps de calculer : le script relit, avec une attente bornée, plutôt que de lire un état inconnu comme un état vert.

## Les cinq verrous

Chaque verrou s'affiche avec son état, `passe` ou `bloque`. Il n'y a **pas** d'état `absent` ici (voir le verrou CI). Les décisions vivent dans `scripts/lib/merge-gates.sh` et `scripts/lib/release.sh`, éprouvées par `scripts/tests/run.sh` (`shell-scripts.md`).

1. **PR publiable** : ouverte, pas en brouillon, fusionnable pour la forge, `dev` → `main`, et sa tête est bien celle de `origin/dev`.
2. **Revue** (AD-24, D-13) : chaque commit de `main..dev` est le squash d'une PR fusionnée par `verify-and-merge-pr`. Le marqueur `(#N)` ne le prouve pas à lui seul — Gitea l'ajoute à **tout** squash —, il prouve seulement que le commit vient de la forge. Ce qui fait la différence, c'est `ci/bootstrap-commits.txt`, qui nomme les seuls squashs fusionnés à la main, avant que `verify-and-merge-pr` existe, et dit pourquoi chacun y figure (arbitrage d'Arnaud du 25/09/2026). Un commit de **fusion** bloque même avec un `(#N)` : Gitea en compose un aussi, et le flux linéaire l'interdit. Un SHA mal formé dans la liste est une anomalie, jamais une ligne ignorée.
3. **Garde-fou** : `scripts/check-private.sh history main..dev`, avec la liste des motifs.
4. **CI** : les statuts du workflow `checks` sur la tête de `dev`, lus sur la forge, avec les mêmes règles que `verify-and-merge-pr` (tous verts passent, `skipped` est écarté mais ne suffit pas, `pending` bloque en disant « en cours », tout autre état bloque en se nommant).
   - **Le régime d'amorçage est refusé ici** (story 11.7). Le substitut de `verify-and-merge-pr` se déclenche quand `.gitea/workflows/checks.yaml` manque à la **base** de la PR. Pour une publication, la base est `main`, où le fichier n'est pas encore arrivé : le régime ne se réveillerait pas *malgré* la CI, il se réveillerait **exactement à la première mise en ligne**, en remplaçant la CI de la forge par un `scripts/check.sh` relancé dans une copie locale. La tête, elle, est un commit de `dev` et porte donc les statuts de `checks.yaml`. Une mise en ligne se valide sur la CI réelle qui a tourné sur ce commit même : un `absent` y est un refus.
5. **Suivi de sprint** : `scripts/sprint-consistency.sh --rev <SHA de tête>`, le **contrôle global**, la branche entrante étant `dev`, qui ne porte aucun numéro de story. Un suivi incohérent bloque une publication comme il bloque une story.

Sans `--merge`, le script s'arrête ici, quel que soit le résultat.

## Publication et tag

Avec `--merge`, et seulement si tous les verrous passent :

1. le script relit la PR : si sa tête a bougé pendant l'audit, il s'arrête ;
2. il fusionne en **`fast-forward-only`** sur le SHA de tête exact (`head_commit_id`). Aucun commit n'est créé, donc aucun message de fusion n'est composé — il n'y a rien à confronter à la liste des motifs. Réponses constatées de la forge (AD-24) : `405` pour un style interdit, `500 DivergingFastForwardOnly` après divergence, et un `405 « Please try again later »` **transitoire** juste après le déplacement de la base, que le script ne prend pas pour un refus — il reprend, de façon bornée. Les deux 405 se distinguent par le message, jamais par le code ;
3. il relit la PR : « fusion annoncée mais la PR n'apparaît pas fusionnée » est une anomalie, pas un succès ;
4. **il relit les branches sur la forge** (`git fetch origin main dev`). La fusion a eu lieu du côté de la forge et n'a rien changé au dépôt local : sans cette relecture, `git tag` se poserait sur l'**ancien** `main`, et le workflow `release` livrerait en production un arbre qui n'est pas celui qu'on croit publier. Le script vérifie que `origin/main` **et** `origin/dev` portent le commit publié ; sinon il refuse de taguer et le dit ;
5. il pose le tag annoté `vX.Y.Z` sur ce commit et le pousse. Si le push échoue, le tag local est retiré pour qu'une reprise le repose sur le même commit.

Le tag poussé déclenche le workflow `release` : contrôles, image `eleyone-site:<tag>` avec les vraies valeurs légales, envoi par SSH (`release-workflow.md`).

## Après le tag

Le script **n'attend pas la CI** : un script qui attend est un script qu'on interrompt, et l'état vrai est celui que le serveur renvoie. Il affiche donc où regarder, et rien de plus :

- le run : onglet **Actions** du dépôt sur la forge, workflow `release`, tag `vX.Y.Z` ;
- l'état du service, une fois le run terminé : `deploy-site status`, envoyé par `ssh` au compte de déploiement dans `SSH_ORIGINAL_COMMAND`, comme le fait `scripts/release/ship.sh` (AD-14). Il affiche les tags en service en production et en répétition.

## Revenir en arrière

Le retour arrière ne passe pas par un tag : il se demande au serveur, qui relance le service de production sur une image déjà chargée (`deploy-site` garde les trois plus récentes).

```
deploy-site rollback <tag>     # envoyé par ssh au compte de déploiement, dans SSH_ORIGINAL_COMMAND
```

Le tag demandé doit être un `vX.Y.Z` dont l'image est encore présente sur le serveur ; `deploy-site` refuse un tag `-rc` en production. Le correctif qui suit, lui, passe par le skill `hotfix` : branche `hotfix/*` depuis `main`, PR vers `main`, tag `vX.Y.(Z+1)`, puis `dev` rebasée sur `main` (AD-24).

## En cas de verrou bloquant

Le script affiche la raison de chaque verrou bloquant. Corriger la cause sur `dev`, par une PR ordinaire et ses cinq verrous (`verify-and-merge-pr.md`), puis relancer l'audit. Une publication ne se rattrape pas sur sa propre branche : `dev` reste la seule porte d'entrée de `main`.
