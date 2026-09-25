# Procédure — Commande forcée `deploy-site` et services du serveur

Le serveur de production n'accepte que des demandes précises, sur deux canaux séparés : la production et la répétition (AD-14, AD-22). La clé de déploiement est restreinte dans `authorized_keys` par `restrict,command="…/deploy-site.sh"` ; quoi que le client demande, c'est `deploy/remote/deploy-site.sh` qui tourne, et la demande lui arrive dans `SSH_ORIGINAL_COMMAND`. Une clé volée ne donne rien d'autre que le protocole ci-dessous.

**Rien de ce qui désigne le serveur n'entre dans le dépôt** (NFR-9) : ni nom d'hôte, ni adresse, ni nom du compte de déploiement, ni nom du réseau du proxy. Les valeurs propres au serveur vivent dans un fichier `.env` posé **sur le serveur**, à côté des fichiers Compose, et jamais commité. Ce `.env`-là n'est pas celui du poste de développement.

Cette procédure décrit le protocole et l'installation attendue. L'**installation réelle** — compte dédié, `authorized_keys`, copie des fichiers, secrets de la forge — se fait à la main, et ses commandes sont dans `serveur-de-production.md` (story 11.6). Ce qui envoie ces commandes est `scripts/release/ship.sh`, depuis le workflow de mise en ligne de la forge (`release-workflow.md`).

## Le protocole

| Demande | Canal | Entrée standard | Ce qu'elle fait |
|---|---|---|---|
| `deploy <tag>` | production | l'archive de l'image | charge l'archive, vérifie que l'image chargée s'appelle **exactement** `eleyone-site:<tag>`, relance le service `site` avec `SITE_TAG=<tag>`, puis garde les trois images de production les plus récentes |
| `rollback <tag>` | production | **rien** | relance le service sur une image **déjà présente** ; refuse si elle est absente |
| `status` | les deux | rien | affiche les tags en service, en production et en répétition |
| `rehearse deploy <tag>` | répétition | l'archive de l'image | comme `deploy`, sur le projet `site-rehearsal` ; **pas** de rétention |
| `rehearse rollback <tag>` | répétition | rien | comme `rollback`, sur le projet `site-rehearsal` |
| `rehearse stop` | répétition | rien | arrête le projet `site-rehearsal` et supprime **toutes** les images `-rc` |

Le tag de production s'écrit `vX.Y.Z`, celui de répétition `vX.Y.Z-rc.N`, sans zéro de tête. Tout autre argument, et tout tag qui ne correspond pas à son canal, est refusé **sans qu'aucun service ne soit touché**.

Codes de sortie : `0` fait ; `1` refus (demande, tag, archive, image absente) ; `2` anomalie (installation incomplète, Docker indisponible, mise en service ou suppression impossible). Un déploiement réussi dont la rétention échoue rend `2` : le service tourne — le message le dit — mais le ménage n'a pas été fait.

## Les trois gardes qui séparent les canaux

Une seule ne suffirait pas ; chacune refuse une entrée que les deux autres laisseraient passer.

1. **Le canal de production refuse un tag portant `-rc`**, et le dit : ce n'est pas une faute de frappe, c'est une erreur de canal.
2. **Le canal de répétition refuse un tag qui n'en porte pas** : une archive de production envoyée au projet de répétition mettrait en ligne, sous un autre projet, une image que la répétition croit jetable.
3. **Le nom de l'image chargée est confronté au tag demandé.** Le tag validé ne dit rien du contenu de l'archive : `docker load` doit charger une image nommée, une seule, et s'appeler exactement `eleyone-site:<tag>`. Une image sans nom (`Loaded image ID:`) est refusée pour la même raison.

Les images `-rc` ne sont **pas** soumises à la rétention des trois plus récentes, qui ne vaut que pour la production : `rehearse stop` les supprime toutes. Une répétition est faite pour ne rien laisser.

## Ce qui protège la commande

`SSH_ORIGINAL_COMMAND` vient du réseau et n'est jamais fiable.

- Elle est **découpée par le shell en tableau**, jamais passée à `eval`, jamais interpolée dans une chaîne de commande. `deploy v1.0.0; rm -rf /` devient cinq mots dont le premier seul est lu comme une commande ; le `;` n'est qu'un caractère d'un mot. `deploy $(id)` devient deux mots : une expansion de paramètre ne se relit pas.
- Le **développement des globs est coupé (`set -f`) avant le découpage**. Sans cela, `deploy v1.2.*` se développerait sur le disque du serveur et pourrait désigner un tag que personne n'a demandé. La place de cette ligne dans le fichier fait partie de la garde.
- Le **tag est validé par une expression ancrée**, sans zéro de tête, **avant** tout usage, et le **nombre d'arguments** est vérifié : `deploy v1.0.0 autre-chose` est refusé.
- Aucun refus n'arrive après un appel à Docker.
- Un mot venu du réseau ne s'affiche jamais brut : les messages le citent par `printf '%q'`, ce qui neutralise les octets de contrôle qu'un journal de CI interpréterait.
- La trace du shell est coupée (`set +x`) : les messages repartent par le canal SSH jusqu'au journal d'un job de la forge, et une trace y écrirait les chemins d'installation du serveur, donc le nom du compte de déploiement.

## Ce qui est installé sur le serveur

Le dossier `deploy/` du dépôt est recopié **tel quel**, dans un dossier appartenant au compte de déploiement :

| Fichier | Rôle |
|---|---|
| `remote/deploy-site.sh` | la commande forcée, exécutable |
| `compose.yaml` | le service de production, sur le réseau du proxy, sans port publié |
| `compose.rehearsal.yaml` | le projet `site-rehearsal`, hors du réseau du proxy, publié en `127.0.0.1:18080` |
| `.env` | **créé sur le serveur, jamais commité** : `PROXY_NETWORK=<nom du réseau Docker du proxy>` |

Le `.env` ne peut pas entrer par accident : `scripts/check-private.sh` refuse tout chemin `.env`, seul ou suffixé, et le hook `pre-receive` de la forge le refuse aussi. `deploy/.env` n'est donc pas un oubli du `.gitignore`, c'est un chemin interdit.

Le script trouve les fichiers Compose par un chemin relatif à lui-même (un cran au-dessus de `remote/`). Docker Compose lit le `.env` du dossier du fichier Compose, donc celui-là.

`deploy/nginx/site.conf` est aussi dans le dossier ; il ne sert pas sur le serveur — il vit dans l'image — et la copie ne cherche pas à l'exclure.

Prérequis sur le serveur : `bash` 4.4 ou plus récent, Docker et le greffon `compose`, le compte de déploiement membre du groupe `docker`. Architecture x86_64, comme les runners qui construisent l'image (AD-14).

**Le script ne dépend d'aucun fichier du dépôt.** C'est une décision, pas un oubli : chaque bibliothèque partagée serait un fichier de plus à recopier à la main à chaque changement, et une occasion de plus de faire vivre sur le serveur une version qui n'est plus celle du dépôt — le coût que paie déjà le hook pre-receive (`gitea-pre-receive-hook.md`). En échange, ce que le script attend **à côté de lui** est vérifié comme le garde-fou vérifie ses bibliothèques : un fichier Compose absent ou illisible arrête le script au lieu de lui faire sauter une étape.

## Recopier après une modification

Comme le hook pre-receive, ces fichiers ne se mettent pas à jour tout seuls. **Toute modification de `deploy/remote/deploy-site.sh`, de `deploy/compose.yaml` ou de `deploy/compose.rehearsal.yaml` se recopie à la main sur le serveur**, sans quoi le serveur continue d'appliquer la version précédente — et un contrôle ajouté ici ne garde rien là-bas.

Après la copie, vérifier depuis le poste :

```bash
ssh <compte de déploiement> status
```

La réponse nomme les deux canaux. Un `status` qui répond est la preuve que la copie est en place et exécutable.

## Vérifier le canal de répétition

Le conteneur de répétition n'est publié que sur la boucle locale du serveur : aucun DNS, aucun hôte proxy, aucun port public. L'accès passe par un tunnel SSH depuis le poste, puis `curl -I` et un navigateur sur `http://127.0.0.1:18080/` (AD-22).

La séquence complète — tags, attente, tunnel, vérifications, retour arrière, arrêt — est tenue par le skill `rehearse-release` (`rehearse-release.md`, story 11.8) ; ce qui suit n'en décrit que l'accès.

**Ce tunnel n'emprunte pas la clé de déploiement.** Celle-ci est posée avec l'option `restrict`, qui coupe la redirection de ports — le quatrième des quatre essais de `serveur-de-production.md` le vérifie exprès. Le tunnel passe donc par le compte d'administration du serveur, jamais par le compte de déploiement : les deux exigences d'AD-22 et de la story 11.6 ne se contredisent pas, elles s'appliquent à deux comptes différents.

## Tests

```bash
bash scripts/tests/run.sh scripts/tests/test-deploy-site.sh
```

Les cas tournent **hors ligne** : un faux `docker` est posé en tête de `PATH` et enregistre ses appels, aucun cas ne lance le vrai démon. Un faux `rm` et un faux `id` y sont posés aussi — ils prouvent qu'une demande hostile n'a lancé aucune commande, et ils empêchent la suite elle-même de jouer un `rm -rf /` si la garde du script venait à tomber.

Ce que ces cas ne prouvent pas : que Docker se comporte comme le script le suppose. Deux suppositions restent à vérifier contre un vrai démon, lors de la première répétition (stories 11.5 et 11.6) — le format de sortie de `docker load` et l'ordre de `docker image ls`, sur lequel repose la rétention. Une troisième a été vérifiée en écrivant la story, sur Compose v5.5.1 : `docker compose -p <projet> down` travaille bien par nom de projet, sans fichier Compose, ce qui est ce qui dispense `rehearse stop` de `SITE_TAG`.
