# Procédure — Mettre en ligne et répéter

Une mise en ligne est un **tag Git poussé sur la forge**, et rien d'autre (AD-14). Un push sur `dev` ou sur `main` ne met rien en ligne : il ne déclenche que les contrôles (`gitea-actions.md`).

| Tag | Branche | Canal | Ce que le serveur reçoit |
| --- | --- | --- | --- |
| `vX.Y.Z` | `main` | production | `deploy <tag>` |
| `vX.Y.Z-rc.N` | `dev` | répétition (AD-22) | `rehearse deploy <tag>` |

Les deux canaux sont **exclusifs** : un tag part sur l'un ou sur l'autre, jamais sur les deux. Dans les deux cas, la livraison se termine par un `status`, dont la sortie s'affiche dans le journal du job — c'est la seule chose que le job sache dire de ce qui tourne réellement.

```bash
git tag v0.1.0-rc.1 && git push origin v0.1.0-rc.1    # répétition, depuis un commit de dev
git tag v1.0.0      && git push origin v1.0.0         # mise en ligne, depuis un commit de main
```

## La chaîne

`.gitea/workflows/release.yaml` ne contient que son déclencheur (`push` de tags `v*`), le checkout en `fetch-depth: 0` et **un seul appel de script** (AD-11). Tout le reste vit dans `scripts/ci/release-job.sh`, qui lit le tag dans `GITHUB_REF` — le YAML ne calcule rien, pas même une expression.

1. **Le tag est vérifié, avant toute construction** :
   - `GITHUB_REF` désigne bien un tag ;
   - le nom suit `vX.Y.Z` ou `vX.Y.Z-rc.N`, sans zéro de tête ;
   - le tag **descend** de sa branche, `origin/main` ou `origin/dev` ;
   - pour `v1.0.0` seulement, un tag `v1.0.0-rc.N` de même arbre existe (voir plus bas).
2. **`scripts/release/ship.sh --check-env`** — les trois secrets de déploiement sont là et bien formés. Cette question est posée **avant** les dix minutes de contrôles : découvrir un secret manquant après la construction coûterait tout le job.
3. **`scripts/ci/checks-job.sh`** — le job de contrôles, le même que sur une PR (`checks-job.md`).
4. **`scripts/release/build-image.sh <tag>`** — l'image `eleyone-site:<tag>`, avec les vraies valeurs légales (`build-image.md`).
5. **`scripts/release/ship.sh <tag>`** — la livraison, puis `status`.

Chaque étape s'annonce dans le journal, et la chaîne s'arrête à la première en échec, avec son code : rien n'est construit après des contrôles rouges, rien n'est livré après une construction ratée.

## La livraison, sans registre

```bash
docker save eleyone-site:<tag> | gzip | ssh … "deploy <tag>"
```

Aucun registre, aucune écriture sur le disque du runner : l'image part dans un seul flux, et le serveur la lit sur son entrée standard (`deploy-site.md`). La clé du compte de déploiement est restreinte dans `authorized_keys` à la commande forcée `deploy-site`, si bien que cette ligne de commande est tout ce que la clé permet.

`ssh` est lancé avec `-o StrictHostKeyChecking=yes`, `-o UserKnownHostsFile=<temporaire>`, `-o IdentitiesOnly=yes`, `-o BatchMode=yes` et `-i <temporaire>`. La clé privée et les empreintes sont écrites en `umask 077` dans deux fichiers temporaires, supprimés par un piège `EXIT` — **même en cas d'échec**, et c'est pourquoi `ship.sh` n'emploie aucun `exec` : `exec` remplacerait le processus et laisserait la clé privée sur le disque du runner.

### Le pipeline et son code de retour

`docker save | gzip | ssh` est un pipeline de trois commandes, et le code d'un pipeline est celui de sa **dernière**. Un `docker save` interrompu enverrait donc une archive tronquée que `ssh` transmettrait sans broncher : le job passerait au vert sur une livraison incomplète. `ship.sh` lit `PIPESTATUS` dans les deux branches de son `if`, avant toute autre commande — une affectation intermédiaire l'écraserait —, et nomme l'élément fautif :

| Ce qui a lâché | Code de `ship.sh` | Ce que dit le message |
| --- | --- | --- |
| `docker save` ou `gzip` | 2 | l'archive envoyée est tronquée ; l'image n'est pas livrée |
| `ssh`, code 1 | 1 | le serveur a refusé la demande (message de `deploy-site` au-dessus) |
| `ssh`, autre code | 2 | anomalie du serveur, du transport ou de la connexion (255 = pas de connexion) |
| `status` | 2 | la livraison est passée, mais l'état du serveur n'a pas pu être lu |

## Les secrets de la forge

Ils se créent à la main, au niveau du dépôt, sous ces noms exacts : les commandes sont dans `serveur-de-production.md`, et `scripts/release/check-forge-secrets.sh` confronte ce qui est posé aux douze attendus. Le workflow les mappe dans l'environnement du **seul** pas qui lance le job ; aucune valeur n'est écrite dans le dépôt ni affichée par un script (NFR-9).

Les noms des quatre qui ne sont pas des valeurs légales vivent dans `ci/release-secrets.txt`, lu par `ship.sh` et par le contrôle ; les huit valeurs légales sont nommées dans `ci/legal-placeholder.env` (C18). Le YAML, lui, ne lisant aucun fichier du dépôt, en porte une copie qu'un cas de `scripts/tests/test-workflows.sh` tient égale à ces deux sources.

| Secret | Contenu |
| --- | --- |
| les huit `HUGO_LEGAL_*` d'AD-9 | les valeurs légales réelles (`build-image.md`) |
| `PRIVATE_PATTERNS` | la liste des motifs interdits, une par ligne |
| `DEPLOY_SSH_KEY` | la clé **privée** du compte de déploiement, en entier |
| `DEPLOY_HOST` | la destination, **au format `utilisateur@hôte`** |
| `DEPLOY_KNOWN_HOSTS` | la ligne `known_hosts` du serveur, telle que `ssh-keyscan` la rend |

**`DEPLOY_HOST` porte le compte *et* la machine.** Il n'y a pas de secret `DEPLOY_USER` : l'architecture ne liste que trois secrets de déploiement (AD-14), et un nom de compte séparé n'ajouterait qu'un second secret à tenir à jour. Le format n'étant pas devinable, il est écrit ici. `ship.sh` refuse une valeur qui n'a pas cette forme, et refuse séparément une valeur qui commence par `-`, que `ssh` lirait comme une option.

`DEPLOY_SSH_KEY` doit porter la clé **privée** : `ship.sh` refuse une valeur où ne figure pas `-----BEGIN … PRIVATE KEY-----`, parce que déposer la clé publique par mégarde est l'erreur la plus plausible de l'installation. `DEPLOY_KNOWN_HOSTS` faite de commentaires seuls est refusée aussi : un `known_hosts` vide est syntaxiquement valide et ne vérifie rien.

Aucun message ne cite la valeur d'un secret, y compris quand il la refuse : il nomme la variable. La trace de shell est coupée (`set +x`) dès l'en-tête des deux scripts, de sorte qu'un `bash -x` n'écrit rien non plus.

## La règle du `-rc` de même arbre (AD-22, D-6)

La première mise en ligne se répète avant de se faire. Le job applique donc, **avant toute construction** :

- pour le tag **`v1.0.0` seulement** : si aucun tag `v1.0.0-rc.N` ne pointe sur un commit de **même arbre**, le job échoue ;
- pour **tout autre** tag de production : l'absence d'un `-rc` de même arbre n'est qu'un **avertissement**, écrit dans le journal, et la mise en ligne continue.

« Même arbre » et non « même commit » : la publication `dev` → `main` est un fast-forward, mais un hotfix ou une signature changeraient le commit sans changer une ligne du site. La comparaison est `git diff --quiet <tag> <rc>`, dont les codes se distinguent comme ceux de `grep` : `0` aucune différence, `1` des différences, au-delà une erreur.

## Pourquoi `fetch-depth: 0`

Les trois vérifications de tag ne répondent juste que si le checkout a ramené **tout** l'historique, les branches distantes et les tags. Sans lui, `origin/main` et les tags `-rc` seraient absents : le job s'arrête alors sur une anomalie qui le dit, plutôt que de conclure « ce tag ne descend pas de `main` » sur une information qu'il n'a pas.

L'appartenance se vérifie par `git merge-base --is-ancestor <tag> origin/<branche>`, jamais par une liste de branches à filtrer : `--is-ancestor` répond par son **code de sortie**, et les trois réponses se distinguent — `0` descend, `1` ne descend pas, tout autre code est une anomalie. Une liste, elle, rend `0` avec une sortie vide aussi bien pour « ne descend pas » que pour « la commande a échoué ».

## Rejouer sans la forge

Le homelab peut s'arrêter à tout moment ; le site, lui, continue de tourner (AD-14). Le job entier se rejoue depuis le poste, dans un clone à jour, en posant la variable que la forge pose :

```bash
GITHUB_REF=refs/tags/v1.2.3 scripts/ci/release-job.sh
```

Les secrets doivent alors être dans l'environnement — les valeurs légales, `PRIVATE_PATTERNS` et les trois `DEPLOY_*` —, et `scripts/check-private.sh history` doit être passé avec la liste de motifs locale.

Pour n'éprouver que la configuration, sans rien construire ni livrer :

```bash
scripts/release/ship.sh --check-env
```

## Recette

Les cas de `scripts/tests/test-ship.sh`, `scripts/tests/test-release-job.sh` et `scripts/tests/test-workflows.sh` couvrent les refus, l'exclusivité des canaux, les trois éléments du pipeline en échec et la forme du YAML, **sans lancer ni `ssh` ni Docker** : la suite reste hors ligne (story 0.9). Ce qui demande un vrai serveur s'éprouve à la story 11.6, puis au jalon « répétition générale ».

```bash
scripts/tests/run.sh scripts/tests/test-ship.sh scripts/tests/test-release-job.sh scripts/tests/test-workflows.sh
```

Après une répétition, le canal se vérifie par un tunnel depuis le poste, puis s'arrête sans rien laisser (`deploy-site.md`) :

```bash
ssh -L 18080:127.0.0.1:18080 <destination>      # puis curl -I http://127.0.0.1:18080/
ssh <destination> "rehearse stop"               # arrête le conteneur et supprime les images -rc
```
