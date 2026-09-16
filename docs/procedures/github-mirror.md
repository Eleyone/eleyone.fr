# Procédure — Miroir push vers le dépôt public GitHub

La forge principale reste la source ; GitHub n'est qu'un miroir en lecture, qui prouve comment le site a été cadré et construit (AD-11, AD-12). Rien n'est poussé à la main vers GitHub : seul le miroir de Gitea y écrit.

**Ordre imposé (AD-12)** : le miroir n'est activé qu'après l'installation et les essais du hook `pre-receive` (story 1.2) et un audit complet propre, fait avec la liste des motifs (story 1.3), relancé juste avant l'activation. Un commit poussé sur GitHub reste accessible par son SHA, même après un push forcé.

**Rien du serveur ni du compte ne s'écrit ici** : ni jeton, ni nom d'hôte, ni chemin de machine. Le jeton du miroir ne vit que dans Gitea.

## Identité du miroir

Gitea ne sait pas pousser un miroir en SSH (documentation Gitea, constat de la story 1.4) : la clé de déploiement est écartée.

- **Compte machine GitHub**, distinct du compte d'Arnaud, invité comme **collaborateur en écriture** sur le seul dépôt public du site.
- **Jeton classique** créé sur ce compte machine, avec les seules portées **`public_repo`** (écriture sur les dépôts publics) et **`workflow`** (nécessaire dès que `.github/workflows/` est poussé, story 3.14). Ni `repo`, ni `admin:*`, ni `delete_repo`, ni `gist`, ni `user`. Noter sa date d'expiration.
- Un **jeton à grain fin ne convient pas** ici : il ne cible que les dépôts de son propriétaire de ressources, et le compte machine n'est que collaborateur d'un dépôt qui appartient à Arnaud ; GitHub réserve ce cas aux jetons classiques. Il deviendrait possible si le dépôt public appartenait à une organisation dont le compte machine est membre (« Contents » et « Workflows » en lecture et écriture) : à reconsidérer le jour où une organisation existe.
- Portée réelle du risque : ce jeton peut écrire sur tous les dépôts **publics** auxquels ce compte a accès. Le compte machine n'est donc invité nulle part ailleurs sans y repenser.
- Le jeton personnel d'Arnaud sert à ses autres miroirs, jamais à celui-ci : GitHub ne saurait pas distinguer le miroir d'Arnaud, et le refus d'un push direct deviendrait invérifiable.

## Installer

1. **Dépôt public** : le créer vide sur GitHub (ni README, ni licence, ni `.gitignore`), avec `main` en branche par défaut.
2. **Compte machine** : le créer, l'inviter comme collaborateur en écriture, accepter l'invitation depuis ce compte.
3. **Jeton** : sur le compte machine, créer le jeton classique avec les portées `public_repo` et `workflow`, noter son expiration, et ne le coller que dans Gitea à l'étape 5.
4. **Rulesets** (AD-12), sur le dépôt public :
   - *toutes les branches et tous les tags* : restreindre la création, la mise à jour et la suppression ; **contournement : le compte machine désigné nommément** (« users » dans la liste de contournement), jamais un rôle. Un contournement par *rôle* Write couvre aussi le propriétaire du dépôt, qui a ce rôle : son push direct passe alors, avec la mention `Bypassed rule violations` (constaté puis corrigé, story 1.4) ;
   - *`main` seulement* : « Block force pushes », **sans aucun contournement**, puisque `main` n'est jamais réécrite.
5. **Miroir dans Gitea** : dans les réglages du dépôt du site, ajouter un miroir push vers l'adresse HTTPS du dépôt GitHub, avec le compte machine comme identifiant et le jeton comme mot de passe, et cocher la synchronisation à chaque push. Lancer une synchronisation.

## Vérifier

À faire avec l'agent, qui note chaque résultat dans le fichier de la story 1.4, sans jeton ni information de machine.

1. **Audit juste avant l'activation** : `PRIVATE_PATTERNS_FILE=<liste> <dépôt de travail>/scripts/check-private.sh history` depuis un clone miroir frais de la forge. Attendu : code 0, aucune sortie, aucune mention « chemins seulement ».
2. **Références poussées** : comparer `git ls-remote` de la forge et de GitHub. Noter les branches communes et leurs SHA, le sort des `refs/pull/*`, et l'état affiché par Gitea pour le miroir.
3. **Audit du dépôt public** : même commande, depuis un clone miroir frais de GitHub.
4. **Push direct refusé** : Arnaud pousse un commit sans intérêt depuis son compte personnel sur une branche jetable. Attendu : refus par le ruleset. Le miroir, lui, continue de synchroniser.
5. **Réécriture** : l'agent pousse une branche jetable sur la forge, la réécrit (push forcé), et la synchronisation suit. Attendu : GitHub accepte la mise à jour non fast-forward, la synchronisation n'échoue pas. La branche est ensuite supprimée sur la forge ; la suppression ne part **pas** avec le push de suppression (voir « Supprimer une branche » ci-dessous), donc demander une synchronisation avant de vérifier qu'elle a disparu de GitHub.

## Entretenir

- **Expiration du jeton** : avant la date notée, créer un nouveau jeton classique (mêmes portées) sur le compte machine, le coller dans le miroir de Gitea, vérifier une synchronisation, puis révoquer l'ancien. Un miroir en échec se voit dans les réglages du dépôt sur la forge.
- **Avant tout autre dépôt mirroré** : le même compte machine peut servir, mais chaque jeton reste limité à son dépôt.
- **Supprimer une branche** : la synchronisation « à chaque push » de Gitea ne se déclenche pas sur la suppression d'une branche (constat de la story 1.4). La branche reste visible sur GitHub jusqu'à la synchronisation suivante : au plus tard au bout de l'intervalle de repli (8 h), ou tout de suite après le push suivant ou une synchronisation lancée à la main depuis les réglages du dépôt. Rien de privé n'est en jeu, c'est un délai d'affichage ; le savoir évite de croire à une panne du miroir.
- **Après une réécriture d'historique sur la forge** (hotfix, AD-24) : vérifier que la synchronisation est passée et que GitHub porte les mêmes SHA.

## En cas d'échec

- **Synchronisation en erreur sur `refs/pull/*`** : GitHub refuse ces références cachées. Constater ce que la synchronisation a tout de même poussé, le noter, puis décider avec Arnaud : accepter cet échec partiel, ou remplacer le miroir par un hook `post-receive` sur la forge qui ne pousse que `refs/heads/*` et `refs/tags/*`.
- **Le push direct d'Arnaud passe** (`remote: Bypassed rule violations`) : le contournement du ruleset est trop large — typiquement un *rôle* au lieu d'un compte. Le remplacer par le compte machine désigné nommément, refaire l'essai avec un **nom de branche neuf** (la branche déjà créée ne teste plus la règle de création), puis vérifier que le miroir, lui, écrit toujours.
- **Un audit signale quelque chose** : ne pas activer le miroir, ou le désactiver s'il l'est déjà. La réécriture d'historique est décidée et exécutée par Arnaud (story 1.3).
