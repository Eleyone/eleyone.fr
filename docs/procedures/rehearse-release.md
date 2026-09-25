# Procédure — Répétition générale de la mise en ligne

Une répétition générale joue **toute la chaîne de mise en ligne** sur le serveur de production, sur un canal séparé de la production, sans DNS ni port public (AD-22). Elle existe pour qu'une première mise en ligne ne découvre pas en production une erreur de chaîne : secrets, image, envoi, commande forcée, retour arrière.

`scripts/rehearse-release.sh` tient la séquence côté poste. Comme pour `release`, la livraison elle-même ne lui appartient pas : un tag `vX.Y.Z-rc.N` poussé sur `dev` déclenche le workflow `release` de la forge, qui construit l'image et l'envoie au canal de répétition (`release-workflow.md`, `deploy-site.md`).

La procédure vaut pour **tout tag `vX.Y.Z-rc.N`**, dont la première répétition sur `v0.1.0-rc.1`, avec les seules pages déjà publiées (D-5).

## Prérequis

- Le serveur installé et les secrets posés sur la forge (`serveur-de-production.md`, story 11.6).
- `git`, `ssh` et `curl` sur le poste.
- `.env` à la racine du dépôt, avec **deux destinations au format `<utilisateur>@<hôte>`, sans port** :
  - `ADMIN_HOST` — le compte d'administration. Il ne sert qu'au **tunnel** et à la lecture des **journaux** ;
  - `DEPLOY_HOST` — le compte de déploiement, celui dont la clé restreinte n'accepte que les commandes de `deploy-site`. Même nom, même valeur que le secret de la forge.
- Les deux comptes joignables sans question interactive : l'empreinte de l'hôte déjà dans le `known_hosts` du poste, et la clé chargée dans l'agent ou déclarée dans `~/.ssh/config`. Le script se connecte en `BatchMode=yes` : une question posée est un échec, pas une attente.
- Le port `18080` libre sur le poste.

**Aucune valeur de `.env` n'est affichée** par le script, ni dans un message, ni dans un journal : un message nomme la variable, jamais son contenu (NFR-9).

## Les deux comptes, et pourquoi ils ne se mélangent pas

| Ce qui part | Par quel compte | Pourquoi |
|---|---|---|
| `status`, `rehearse rollback <tag>`, `rehearse stop` | **déploiement** (`DEPLOY_HOST`) | c'est le canal restreint : la clé est posée avec `restrict,command=`, elle n'ouvre rien d'autre |
| le tunnel `ssh -L 18080:127.0.0.1:18080` | **administration** (`ADMIN_HOST`) | `restrict` **refuse une redirection de port** — premier critère d'acceptation de la story 11.6, vérifié par le quatrième de ses quatre essais |
| `docker logs` du conteneur de répétition | **administration** (`ADMIN_HOST`) | le tunnel ne transporte que du HTTP ; un `docker logs` lancé en local parlerait au démon Docker du poste |

AD-22 (« accès par `ssh -L` ») et la story 11.6 (« la clé de déploiement refuse un tunnel ») ne se contredisent qu'en apparence : ils portent sur deux comptes différents.

## Lancer

```bash
scripts/rehearse-release.sh v0.1.0-rc.1           # audit : vérifie tout, n'agit sur rien
scripts/rehearse-release.sh v0.1.0-rc.1 --run     # joue la répétition, deux tags poussés compris
```

Le **tag suivant se calcule** : `v0.1.0-rc.1` donne `v0.1.0-rc.2`. Il n'y a qu'un tag à donner.

`--run` ne se déduit jamais. Pousser un tag est irréversible — la forge le voit, le miroir public aussi, et le workflow part —, et une action irréversible se demande explicitement, comme `--merge` pour `release`.

Codes de sortie : `0` la répétition s'est déroulée en entier et tout est vérifié ; `1` refus (tag déjà posé, délai dépassé, serveur qui refuse) ou vérification en échec ; `2` anomalie (usage, tag mal formé, outil absent, `.env` absent ou incomplet, dépôt illisible, tunnel impossible, serveur muet).

## Avant toute action

Dans cet ordre, et sans rien pousser :

1. **Le tag est une répétition.** Un `vX.Y.Z` est refusé d'entrée : c'est une mise en ligne, elle se pose sur `main` par `release` (AD-22). Les deux expressions sont disjointes et ancrées, sans zéro de tête (`scripts/lib/release.sh`).
2. **Les outils, le dépôt, les destinations.** `git`, `ssh`, `curl` ; le dépôt distant est bien celui du projet ; `ADMIN_HOST` et `DEPLOY_HOST` sont présents et suivent `<utilisateur>@<hôte>`. Une valeur qui commence par `-` est refusée à part : `ssh` y lirait une option, pas une destination.
3. **Le port `18080` est libre sur le poste.** S'il répond déjà, le tunnel ne pourrait pas s'y poser — et, surtout, les vérifications interrogeraient ce service-là en croyant parler au serveur.
4. **Les deux tags sont libres**, relus depuis la forge par un `git fetch --tags` explicite. Les **deux**, avant le premier push : découvrir le second occupé après avoir poussé le premier laisserait une répétition à moitié jouée.
5. **L'arbre de travail** : une modification en attente ne bloque pas — la répétition porte sur `origin/dev` —, mais elle est signalée, pour que personne ne croie répéter ce qu'il a sous la main.

Sans `--run`, le script affiche le programme et s'arrête là.

## L'enchaînement

1. le tag `<tag>` est posé sur `origin/dev` et poussé. Le workflow `release` fait le reste ;
2. **attente** : le script interroge `deploy-site status` jusqu'à y voir `eleyone-site:<tag>`, au plus trente minutes ;
3. le **tunnel** s'ouvre, puis les vérifications passent ;
4. le tag `<tag suivant>` est posé, poussé, attendu, vérifié ;
5. `rehearse rollback <tag>` remet le premier en service, attendu, vérifié ;
6. `rehearse stop` arrête la répétition et supprime les images `-rc`.

### L'attente passe par le serveur, jamais par la forge

Le script n'appelle pas l'API de la forge et ne suit pas le run. Deux raisons : `deploy-site status` dit l'**état vrai** — ce que le serveur sert — là où un run dit seulement qu'un job s'est terminé ; et la forge est un homelab qui peut tomber à tout moment (AD-14), alors que le serveur, lui, est ce qui compte. C'est la même règle que pour `release`, qui refuse de suivre un run et renvoie à `status`.

La comparaison porte sur le **jeton entier** `eleyone-site:<tag>` : chercher `…-rc.1` comme sous-chaîne trouverait `…-rc.11`.

Trois `status` muets **consécutifs** arrêtent l'attente : une clé refusée ou un serveur éteint ne s'améliore pas en trente minutes, et un échec isolé n'interrompt pas une attente longue.

Si le délai est dépassé : regarder le run `release` dans l'onglet **Actions** du dépôt sur la forge, puis `ssh <compte de déploiement> status`. La répétition n'est pas arrêtée pour autant.

### Le tunnel

```
ssh -o ExitOnForwardFailure=yes -N -L 18080:127.0.0.1:18080 <compte d'administration>
```

Il est lancé **en tâche de fond du script**, et non avec `-f` : avec `-f`, `ssh` se dédouble pour passer en arrière-plan, le processus lancé se termine aussitôt, et le PID retenu serait celui d'un mort — le piège tuerait un fantôme et laisserait le tunnel ouvert. Lancé en tâche de fond, `$!` est le tunnel lui-même : on peut lui demander s'il vit encore, et le piège l'arrête vraiment.

`ExitOnForwardFailure=yes` : sans lui, une redirection refusée laisserait un `ssh` vivant et muet, et les vérifications échoueraient sans dire pourquoi.

### Les vérifications

Toutes passent par le tunnel, sur `http://127.0.0.1:18080`.

| Cible | Ce qui est vérifié |
|---|---|
| `/` | HTTP 200, HTML, en-têtes d'AD-13, `Cache-Control: no-cache`, page servie en français |
| `/en/` | les mêmes, page servie en anglais |
| une URL absente en FR | HTTP 404, page d'erreur **française** |
| une URL absente en EN | HTTP 404, page d'erreur **anglaise** — c'est le `error_page` du `location /en/` |
| un fichier empreinté | HTTP 200, en-têtes communs, **pas de CSP**, `Cache-Control: public, max-age=31536000, immutable` |
| un SVG, s'il en existe un | les mêmes, avec le `Cache-Control` que son nom commande |
| les journaux du conteneur | aucune adresse IP (AD-15) |

Le fichier empreinté n'est pas deviné : il est **relevé dans la page d'accueil servie**. C'est le seul moyen de vérifier la règle `immutable` sans inventer un nom de fichier. S'il n'y en a aucun, le contrôle échoue au lieu de passer au vert sans rien lire. Le SVG est conditionnel — le site n'en porte pas encore —, et son absence est dite, pas tue.

**La CSP n'est exigée que sur le HTML, et son absence est exigée ailleurs.** `deploy/nginx/site.conf` ne l'envoie que sur `~^text/html` : une valeur vide supprime l'en-tête, et un SVG n'en porte donc pas, par conception — les schémas D2 portent des `<style>` et des polices embarquées, qu'une politique `style-src 'self'` casserait. Une vérification qui exigerait la CSP partout échouerait sur un fichier parfaitement conforme.

De même, `Cache-Control` vaut `immutable` **seulement** pour un fichier empreinté d'un condensat, et `no-cache` pour tout le reste : l'attente se déduit du nom du fichier, exactement comme le `map` de nginx la déduit de l'URI.

Les **journaux** se lisent par `ssh <compte d'administration> docker logs …`, le conteneur étant retrouvé par son étiquette de projet Compose. Une ligne fautive est signalée par son **numéro**, jamais par son contenu : une adresse IP est précisément ce qu'on ne veut voir nulle part (AD-15, NFR-3).

Une vérification en échec arrête la répétition, à ce point de la séquence, sans rien effacer.

## Après un échec : ce que le script n'arrête pas

Le piège de sortie **tue le tunnel** — un processus laissé sur le poste est un déchet — mais **ne lance pas `rehearse stop`**.

`rehearse stop` arrête le projet distant *et supprime toutes les images `-rc`* (`deploy-site.md`). Le lancer automatiquement après un échec détruirait exactement ce qu'il faut inspecter : le conteneur qui tournait, ses journaux, l'image qui a servi. Une répétition qui rate est précisément le moment où l'on veut regarder.

Le canal de répétition est par ailleurs **isolé** — projet Compose distinct, hors du réseau du proxy, publié sur `127.0.0.1:18080` seulement (AD-22) : un conteneur qui survit à un échec ne « tourne pas en production », il ne gêne rien ni personne.

Le script dit donc, en clair, que la répétition tourne encore, et donne les deux commandes :

```
ssh <compte de déploiement> status          # ce qui tourne
ssh <compte de déploiement> 'rehearse stop' # tout arrêter, images -rc comprises
```

Un nettoyage qui détruit les preuves est pire que pas de nettoyage du tout, et le script n'a pas à choisir à la place de celui qui enquête.

## Ce que la répétition ne touche jamais

Ni le service de production, ni Nginx Proxy Manager, ni le DNS. Le seul canal employé est `rehearse …`, et `deploy-site` refuse un tag sans `-rc` sur ce canal comme il refuse un tag `-rc` en production.

## Tests

```bash
bash scripts/tests/run.sh scripts/tests/test-rehearse-release.sh
```

Les cas tournent **hors ligne** : de faux `ssh`, `curl`, `git` et `sleep` sont posés en tête de `PATH` et enregistrent leurs appels. Aucun cas ne pose de tag, ni localement ni sur la forge, n'ouvre de connexion, ni ne lit le `.env` du dépôt — chacun se lance depuis un dépôt git jetable qui porte le sien.
