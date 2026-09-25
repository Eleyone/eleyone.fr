# Story 11.4 : Forced deploy-site command and services

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.4.

Quatrième story de l'epic 11, dont l'en-tête (point 21) veut la chaîne de mise en ligne
**construite et répétée tôt**, sur le serveur de production et **sans DNS**. C'est cette story qui
rend la répétition possible sans toucher la production : deux canaux séparés, et un serveur qui
n'accepte que des demandes précises.

## Ce que la story doit décider avant d'écrire

**`rollback` en production fait-il partie de cette story ?** Les critères d'acceptation nomment
`deploy <tag>`, `rehearse deploy|rollback|stop` et `status`, mais **pas** `rollback` seul. AD-14,
lui, l'inscrit au protocole : « `rollback <tag>` : relance le service de production sur une image
déjà présente ». Et le dernier critère exige qu'« un argument inconnu » soit refusé — si `rollback`
n'est pas écrit, il devient un argument inconnu, ce qui contredirait AD-14.

**Décision : le protocole d'AD-14 est écrit en entier**, `rollback` compris, avec ses cas de test.
La story 11.13 (« production rollback on second deployment ») ne l'écrit pas : elle l'**exerce** en
production, sur un vrai deuxième déploiement. Écrire la commande ici n'est donc pas une
anticipation au sens du point 7 — c'est le protocole que cette story possède —, et l'omettre
obligerait la 11.13 à livrer une commande que personne n'aurait testée hors ligne.

## Revue de spec

### 25/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `af4ae89`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 3d20f343da0e08fa632ef381

##### Rapport de revue (BMAD)

###### Lentille Adverse (Adversarial)
- **BLOQUANT** : Le comportement de la commande `rollback <tag>` en production est totalement absent des critères d'acceptation, alors qu'elle est explicitement définie comme faisant partie du protocole par la décision AD-14.
- **BLOQUANT** : Le deuxième critère d'acceptation regroupe `rehearse deploy`, `rehearse rollback` et `rehearse stop` sous le même résultat (« démarre, repart sur une image `-rc` présente, puis s'arrête avec suppression »). C'est contradictoire : on ne peut pas tester un déploiement si le conteneur s'arrête et supprime l'image immédiatement. De plus, cela omet le besoin de charger l'archive depuis l'entrée standard pour `rehearse deploy`.
- **BLOQUANT** : L'injection de la variable `SITE_TAG=<tag>` lors de la relance du service (exigée par AD-14 pour pointer vers la bonne image) n'est demandée nulle part dans les critères d'acceptation, ni dans la définition des fichiers `compose.yaml`.
- **NON BLOQUANT** : L'obligation de tester en local simule `SSH_ORIGINAL_COMMAND` mais appelle potentiellement de vraies commandes `docker` (load, compose). Sans mock ou précaution explicite dans `scripts/tests/`, cela risque d'altérer le démon Docker du développeur.

###### Lentille Structurelle (Structure)
- **BLOQUANT** : La checklist indique que le réseau du proxy pour `deploy/compose.yaml` doit être nommé par une variable (conformément à NFR-9), mais la spec ne fixe pas le nom de cette variable, ce qui laisse une décision d'infrastructure orpheline.
- **BLOQUANT** : Il n'y a pas de garde ou de test explicite garantissant qu'une archive poussée vers le canal de répétition (`rehearse deploy`) n'écrase pas par accident une image de production si les noms ou les tags se chevauchent.
- **NON BLOQUANT** : La conservation des trois images les plus récentes est spécifiée pour la production, mais la règle de rétention ou de nettoyage n'est pas claire pour les images `-rc` de répétition (hors de la commande `stop`).

###### Lentille Rédactionnelle (Prose)
- **NON BLOQUANT** : L'expression « repart sur une image `-rc` présente » est ambiguë techniquement. S'agit-il d'un redémarrage de conteneur, d'un `docker compose up` ou du comportement spécifique du `rollback` ?
- **NON BLOQUANT** : Le critère mentionnant « un tag suivi d'une autre commande » gagnerait à expliciter le risque d'injection shell (ex: `; rm -rf /`) pour s'assurer que le test correspondant soit suffisamment robuste.

##### À trancher avant d'implémenter
- Quels sont les critères d'acceptation spécifiques à `rollback <tag>` pour le canal de production ?
- Quel est le comportement distinct et séparé pour `rehearse deploy` (qui doit charger l'archive sur STDIN), `rehearse rollback` et `rehearse stop` ?
- Quel nom de variable d'environnement doit être utilisé pour configurer le réseau du proxy dans `deploy/compose.yaml` ?
- Comment la variable `SITE_TAG` doit-elle être intégrée dans les deux fichiers Compose pour que la relance des services fonctionne correctement ?

### Triage des constats (point 20 : chacun reçoit sa décision)

| # | Constat | Décision |
| --- | --- | --- |
| A1 | `rollback <tag>` absent des critères alors qu'AD-14 l'inscrit au protocole | **Retenu**, et déjà tranché en tête de ce fichier avant la revue : le protocole est écrit en entier. Le relecteur et moi arrivons à la même conclusion par deux chemins. |
| A2 | Le deuxième critère regroupe les trois `rehearse` sous un seul résultat, ce qui est contradictoire | **Retenu.** La phrase décrit une **séquence** d'essai, pas un résultat unique. Trois comportements distincts, trois jeux de cas : `rehearse deploy <tag>` charge une archive depuis l'entrée standard et démarre le projet `site-rehearsal` ; `rehearse rollback <tag>` repart sur une image `-rc` **déjà présente**, sans rien lire sur l'entrée standard ; `rehearse stop` arrête le projet et supprime les images `-rc`. |
| A3 | `SITE_TAG` n'est demandée nulle part | **Retenu.** Décision : les deux fichiers Compose écrivent `image: eleyone-site:${SITE_TAG:?}`. La forme `:?` **fait échouer Compose** si la variable est absente, au lieu de résoudre en `eleyone-site:` et de tirer un `latest` qui n'existe pas. C'est la même famille de faute que le garde-fou qui s'ouvre en cas de panne. |
| A4 | Les tests risquent de toucher le vrai démon Docker | **Retenu, et c'est important.** Aucun cas ne lance Docker : un faux `docker` est posé en tête de `PATH`, exactement comme `scripts/tests/test-build-image.sh:7` le fait depuis la story 4.1. La suite reste hors ligne (story 0.9). |
| S1 | Le nom de la variable du réseau du proxy n'est pas fixé | **Retenu.** Décision : `PROXY_NETWORK`, lue depuis un `.env` posé à côté des fichiers Compose sur le serveur, **jamais commitée** — NFR-9 interdit qu'un nom d'infrastructure entre dans le dépôt. Le fichier Compose déclare ce réseau `external: true` : il existe déjà, c'est celui du proxy, et Compose ne doit pas le créer. |
| S2 | Rien ne garantit qu'une répétition n'écrase pas une image de production | **Retenu, et c'est la raison d'être des deux canaux.** Trois gardes séparées, chacune avec son cas : le canal de production refuse un tag portant `-rc`, le canal de répétition refuse un tag qui n'en porte pas, et chaque canal vérifie que l'archive chargée s'appelle **exactement** `eleyone-site:<tag>` demandé. Une seule de ces trois ne suffirait pas. |
| S3 | La rétention des images `-rc` n'est pas claire hors de `stop` | **Retenu.** Décision écrite : les images `-rc` ne sont **pas** soumises à la rétention des trois plus récentes, qui ne vaut que pour la production ; `rehearse stop` les supprime toutes. Une répétition est faite pour ne rien laisser. |
| P1 | « repart sur une image `-rc` présente » est ambigu | **Retenu** dans la procédure et les messages : `rollback` ne lit **rien** sur l'entrée standard, ne charge aucune archive, et relance le service sur une image déjà chargée — il refuse si elle est absente. |
| P2 | « un tag suivi d'une autre commande » gagnerait à nommer le risque d'injection | **Retenu, et c'est le cœur de la sécurité de cette story.** `SSH_ORIGINAL_COMMAND` est une chaîne **non fiable** : elle est découpée par le shell en tableau, jamais passée à `eval`, jamais interpolée dans une commande, et le développement des globs est coupé (`set -f`) avant le découpage. Un cas de test envoie `deploy v1.0.0; rm -rf /` et un autre `deploy $(id)` : les deux sont refusés sans qu'aucune commande ne s'exécute. |

### Ce que la story ne fait pas

La **livraison** (`docker save | gzip | ssh`) est la story 11.5, et l'**installation réelle** sur le
serveur — compte dédié, `authorized_keys` avec `restrict,command=`, copie des fichiers Compose — est
la story 11.6, la seule de l'epic marquée « Opération manuelle : **oui** ». Cette story-ci écrit et
éprouve le protocole **hors ligne**, avec `SSH_ORIGINAL_COMMAND` simulé et un faux `docker`.

## Ce qui est livré

| Fichier | Ce qu'il porte |
| --- | --- |
| `deploy/remote/deploy-site.sh` (755) | la commande forcée, qui lit sa demande dans `SSH_ORIGINAL_COMMAND` : `deploy`, `rollback`, `status`, `rehearse deploy|rollback|stop`, et refuse tout le reste sans toucher aux services |
| `deploy/compose.yaml` | service `site`, projet `site`, `image: "eleyone-site:${SITE_TAG:?…}"`, aucun port publié, réseau du proxy nommé par `${PROXY_NETWORK:?…}` et `external: true`, journaux `json-file` `10m` × `3` |
| `deploy/compose.rehearsal.yaml` | projet `site-rehearsal`, hors du réseau du proxy, publié sur `127.0.0.1:18080:80` seulement, mêmes journaux, même `:?` |
| `scripts/tests/test-deploy-site.sh` | 39 cas, hors ligne, aucun ne lance Docker |
| `docs/procedures/deploy-site.md` | le protocole, les trois gardes de séparation des canaux, ce qui protège la commande, l'installation attendue sur le serveur et la règle de recopie |

Le protocole d'AD-14 est écrit **en entier**, `rollback` compris, comme décidé en tête de ce fichier.

### Les décisions de structure prises en écrivant

- **Le script est autonome** : il ne charge aucune bibliothèque du dépôt (voir le tableau des jumeaux).
- **Disposition sur le serveur** : le dossier `deploy/` du dépôt est recopié tel quel ; le script trouve les fichiers Compose un cran au-dessus de lui, et Compose lit le `.env` du serveur dans ce même dossier.
- **Le nom de projet est passé explicitement** (`--project-name`) à chaque appel Compose, et il est aussi écrit en `name:` dans les deux fichiers pour qui lance Compose à la main. Un cas (`deploy_site_projets_concordent`) refuse que les deux dérivent.
- **`rehearse stop` travaille par nom de projet, sans `-f`** : `docker compose -p <projet> down` retrouve les conteneurs par leurs étiquettes (vérifié, voir les sorties). C'est ce qui évite d'exiger `SITE_TAG` pour un arrêt, que le `:?` ferait sinon échouer.
- **Une rétention en échec rend 2** après un déploiement réussi, et le message dit que le service tourne : un ménage impossible est une anomalie, pas un silence.
- **`docker load` en échec rend 1** (refus) et non 2 : l'archive vient de l'appelant.
- **Les valeurs des fichiers Compose sont entre guillemets** : le message du `:?` contenait un `: `, que le lecteur YAML lit comme un début de clé — `docker compose config` refusait les deux fichiers. Trouvé en les validant, pas en les relisant (point 10 : une règle sur un outil n'est vraie qu'une fois jouée).

## Point 19 — le brief des jumeaux

### `scripts/check-private.sh`, l'aîné « recopié sur une machine distante »

Il charge `scripts/lib/image.sh` et `scripts/lib/pdf.sh` par un chemin relatif à lui-même et **refuse de s'exécuter** si la bibliothèque manque. **Le cadet ne dépend d'aucun fichier du dépôt** : décision retenue, et écrite dans son en-tête. La raison est le coût de la copie, que `docs/procedures/gitea-pre-receive-hook.md` paie déjà — chaque bibliothèque est un fichier de plus à recopier à la main, et une occasion de plus de faire vivre sur le serveur une version qui n'est plus celle du dépôt. Ce que l'aîné lègue quand même : **ce qui manque arrête**. Les fichiers Compose attendus à côté du script sont vérifiés (`-f` et `-r`) et leur absence rend 2 (`deploy_site_compose_absent`), au lieu de laisser le script continuer sans eux. La règle de recopie a sa section dans la procédure, comme celle du hook.

### `scripts/release/build-image.sh` (story 11.3), les six gardes, une par une

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 1 | Tag validé par une expression ancrée, avant tout usage ; les quatre formes refusées ont chacune leur cas | **Oui, et plus fort.** Deux expressions **disjointes**, une par canal, parce que la séparation des canaux en dépend. Quatorze formes refusées, chacune jouée sur les deux canaux (`deploy_site_tags_malformes`), plus le tag minimal accepté pour que la garde ne soit pas un « refuse tout ». L'aîné acceptait `-rc` ou non dans une seule expression : ici c'est exactement ce qu'il ne faut pas. |
| 2 | Les refus arrivent avant tout effet de bord, et le message le dit | **Oui.** Tous les refus sont écrits avant le premier appel à Docker, `command -v docker` compris, et neuf messages finissent par « Aucun service n'a été touché ». `refus_sans_docker` l'affirme dans quinze cas : code attendu **et** aucun appel à Docker enregistré. |
| 3 | Codes 0 / 1 (refus) / 2 (anomalie), message qui nomme la cause sans afficher de valeur | **Oui**, mais la frontière n'est pas la même : ici, 1 couvre aussi l'archive illisible et l'image absente (elles viennent de l'appelant), 2 couvre l'installation incomplète, Docker absent, la mise en service impossible et la rétention en échec. Aucune valeur d'environnement ne transite, donc rien à cacher — en revanche le **mot venu du réseau** est cité par `printf %q`, ce dont l'aîné n'avait pas besoin : ses arguments viennent de la CI. |
| 4 | `set +x` en tête si des données sensibles transitent | **Oui, pour une autre raison.** Aucune valeur légale ne passe ici. Mais les messages repartent par le canal SSH jusqu'au journal d'un job de la forge, et une trace y écrirait les chemins d'installation du serveur, donc le nom du compte de déploiement, que NFR-9 tient hors de tout ce qui se lit ailleurs. Garde **éprouvée** (`deploy_site_trace_coupee` : le script lancé `bash -x` n'écrit pas la trace de ses appels à Docker). |
| 5 | Pas de `exec` quand un `trap … EXIT` doit tourner | **Oui.** Le script a un `trap … EXIT` qui supprime son dossier de travail, et **aucun `exec`** : les appels à Docker tournent en enfant, leur code est retenu. Un `exec` aurait été tentant pour `docker compose up`, c'est le dernier appel du chemin `rollback`. |
| 6 | Un fichier temporaire entre dans le tableau `temporaires` juste après sa création | **Oui, et simplifié.** Un seul temporaire, un dossier, inscrit à la ligne suivante de son `mktemp -d`. Le piège de l'epic 7 — un nom qui porte un chemin sans être celui que le nettoyage lit — ne peut pas se reproduire avec une seule entrée, mais la forme est gardée pour qu'un second temporaire n'ait qu'à s'ajouter. |

**Une septième garde a été prise en plus, et c'est un cas qui l'a trouvée** : l'aîné lit ses lignes avec `while IFS= read -r ligne || [[ -n $ligne ]]`. Le cadet l'avait écrite sans `|| [[ -n $ligne ]]` dans ses trois boucles. Une sortie de `docker load` qui ne finit pas par un saut de ligne y perdait sa **dernière** image — donc l'image de trop, celle qui fait le refus. Trouvée en écrivant le cas, pas en relisant le fichier. Corrigée dans les trois boucles ; cas `deploy_site_derniere_ligne_sans_saut`.

### `scripts/tests/test-build-image.sh:7` et `test-release-build-image.sh`, les aînés des tests

Le procédé est repris tel quel : un faux `docker` posé en tête de `PATH`, qui enregistre ses arguments dans un fichier. **Aucun cas ne lance Docker** — l'en-tête de l'aîné le dit, celui du cadet aussi. Gardes reprises : affirmer le code de sortie **avant** de compter quoi que ce soit ; vérifier que Docker n'a **pas** été lancé après un refus ; réduire l'environnement (`env -i`) pour qu'un cas rende le même verdict sur le poste et dans `CHECK_IMAGE` ; un `TMPDIR` qui n'appartient qu'au cas. Garde **ajoutée**, qu'aucun aîné n'avait : un faux `rm` et un faux `id` en tête de `PATH`, qui prouvent qu'une demande hostile n'a lancé aucune commande — et qui, accessoirement, empêchent la suite elle-même de jouer un `rm -rf /` si la garde du script venait à tomber.

## Point 9 — chaque garde retirée une fois

Vingt mutations, jouées une par une sur une copie du fichier, suite relancée à chaque fois. **Les vingt font rougir la suite**, et chacune fait tomber le cas qui la vise.

| # | Garde retirée | Cas qui tombe |
| --- | --- | --- |
| M1 | `set -f` avant le découpage | `deploy_site_globs_coupes` |
| M2 | expression de production refusant `-rc` | `deploy_site_tag_rc_en_production` (et `retention_garde_trois_images`) |
| M3 | expression de répétition exigeant `-rc` | `deploy_site_tag_de_production_en_repetition` (et `rehearse_stop`) |
| M4 | nom de l'image chargée | `deploy_site_image_mal_nommee` |
| M5 | une seule image nommée | `deploy_site_archive_a_plusieurs_images` |
| M6 | nombre d'arguments | `deploy_site_argument_en_trop_non_recopie` |
| M7 | rétention épargne le tag en service | `deploy_site_retention_epargne_le_tag_en_service` |
| M8 | rétention réservée à la production | `deploy_site_rehearse_deploy_nominal` |
| M9 | fichier Compose présent | `deploy_site_compose_absent` |
| M10 | `command -v docker` | `deploy_site_docker_absent` |
| M11 | image présente avant un `rollback` | `deploy_site_rollback_image_absente` |
| M12 | `visible()` cite le mot venu du réseau | `deploy_site_tag_hostile_cite` |
| M13 | libellé construit des seuls mots validés | `deploy_site_argument_en_trop_non_recopie` |
| M14 | `rehearse stop` ne supprime que les `-rc` | `deploy_site_rehearse_stop` |
| M15 | `set +x` | `deploy_site_trace_coupee` |
| M16 | sortie de `docker load` citée | `deploy_site_sortie_de_load_citee` |
| M17 | `read` retient la dernière ligne | `deploy_site_derniere_ligne_sans_saut` |
| M18 | `stop` sans fichier Compose | `deploy_site_rehearse_stop` |
| M19 | `rollback` ne lit rien sur l'entrée standard | `deploy_site_rehearse_rollback_nominal` |
| M20 | NFR-9, aucune adresse dans un fichier suivi | `deploy_site_aucune_adresse` |

**Ce que les mutations ont trouvé, et qui n'était pas prévu :**

1. **M17.** La garde de lecture manquante, décrite ci-dessus. Le cas qui devait éprouver la citation de la sortie a échoué sur le script **non muté** : il a trouvé un défaut, pas une garde.
2. **Une assertion à moi qui ne gardait rien.** Le cas `rehearse_stop` affirmait `[[ $vus != *"down | "*"-f "* ]]` pour prouver que l'arrêt n'exige pas de fichier Compose. Ce motif ne peut **jamais** correspondre : `-f <fichier>` arrive **avant** `down` dans la ligne de commande, jamais après. C'est exactement la faute que la story 11.3 avait trouvée trois fois — une garde qui a l'air d'une garde. Remplacée par l'affirmation de la **ligne entière** de l'appel, que M18 fait bien tomber.
3. **Deux gardes écartées pour la même raison, et c'est la bonne.** `IFS=$' \t\n'` avant le découpage : bash réinitialise `IFS` à sa valeur par défaut au démarrage, quoi que porte l'environnement (vérifié : `IFS=x bash -c 'printf "%q\n" "$IFS"'` rend `$' \t\n'`). La garde est inatteignable, donc intestable, donc décorative — elle n'est pas écrite. `set +x`, en revanche, **est** atteignable (un opérateur qui débogue sur le serveur) et a donc son cas.

## Ce que les vérifications ont donné

```
$ bash scripts/tests/run.sh
tests: 704 cas réussis.

$ scripts/check.sh
check: 11 contrôle(s) passés, niveau standard.

$ bash scripts/ci/checks-job.sh          # dans CHECK_IMAGE, BusyBox
checks-job-container: garde-fou public/privé sur tout l'historique.
tests: 704 cas réussis.
check: 11 contrôle(s) passés, niveau standard.

$ git add -A && scripts/check-private.sh staged
(aucune sortie, code 0)
```

Les fichiers Compose, validés par Docker Compose v5.5.1 — le `:?` fait bien échouer, c'est le constat A3 :

```
$ PROXY_NETWORK=reseau-essai docker compose -f deploy/compose.yaml config
error while interpolating services.site.image: required variable SITE_TAG is missing a value: SITE_TAG absente, le tag de l'image se pose par deploy-site.sh
code=1

$ SITE_TAG=v1.2.3 docker compose -f deploy/compose.yaml config
error while interpolating networks.proxy.name: required variable PROXY_NETWORK is missing a value: PROXY_NETWORK absente, le nom du réseau du proxy se lit dans le .env du serveur
code=1

$ SITE_TAG=v1.2.3 PROXY_NETWORK=reseau-essai docker compose -f deploy/compose.yaml config
name: site
services:
  site:
    image: eleyone-site:v1.2.3
    logging:
      driver: json-file
      options:
        max-file: "3"
        max-size: 10m
    networks:
      proxy: null
    restart: unless-stopped
networks:
  proxy:
    name: reseau-essai
    external: true
code=0

$ docker compose -f deploy/compose.rehearsal.yaml config
error while interpolating services.site.image: required variable SITE_TAG is missing a value: SITE_TAG absente, le tag de l'image se pose par deploy-site.sh
code=1

$ SITE_TAG=v1.2.3-rc.1 docker compose -f deploy/compose.rehearsal.yaml config
name: site-rehearsal
services:
  site:
    image: eleyone-site:v1.2.3-rc.1
    logging:
      driver: json-file
      options:
        max-file: "3"
        max-size: 10m
    networks:
      default: null
    ports:
      - mode: ingress
        host_ip: 127.0.0.1
        target: 80
        published: "18080"
        protocol: tcp
    restart: unless-stopped
networks:
  default:
    name: site-rehearsal_default
code=0
```

La répétition est bien sur son propre réseau (`site-rehearsal_default`) et publiée sur `127.0.0.1` seulement. `config` ne crée rien ; aucun conteneur n'a été démarré.

Deux comportements de Docker Compose, vérifiés plutôt que supposés (point 10) :

```
$ docker compose -p projet-qui-nexiste-pas-11-4 down
level=warning msg="Warning: No resource found to remove for project \"projet-qui-nexiste-pas-11-4\"."
rc=0
```

`down` travaille donc par nom de projet, **sans fichier Compose** : c'est ce qui permet à `rehearse stop` de ne pas dépendre de `SITE_TAG`. Ce qui reste **non vérifié ici** et l'est sur le serveur (stories 11.5 et 11.6) : le format exact de sortie de `docker load`, et l'ordre de `docker image ls`. La procédure le dit.

## Revue du code

### 25/09/2026 — `0378a07` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 119. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 42607f0187c6e6920d6ea634

##### Revue BMAD

###### Lentille : edge-case-hunter
- NON BLOQUANT : Faute de frappe mineure dans le message de refus de `deploy-site.sh` (« n attend aucun argument » au lieu de « n'attend »).
- NON BLOQUANT : La capture des erreurs Docker via `|| docker_rc=$?` est robuste car l'affectation réussit toujours (évitant l'arrêt silencieux par `set -e`), tout en permettant un contrôle explicite de l'erreur juste après pour interrompre l'exécution proprement.

###### Lentille : verification-gap
- NON BLOQUANT : Le test `case_deploy_site_argument_en_trop_non_recopie` vérifie qu'aucun octet hostile n'est copié, mais la branche d'erreur correspondante omet l'argument en surplus de toute façon ; un test injectant la charge hostile dans le nom de la commande (vers `inconnue()`) validerait plus directement la fonction d'échappement `visible()`.

##### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits (canaux totalement étanches, tags validés strictement, rétention respectée sur la seule production).
- NON BLOQUANT : Aucune donnée privée, nom d'hôte ou adresse IP n'est commité (seul `127.0.0.1` est présent et autorisé). Aucun script ne divulgue de secret.
- NON BLOQUANT : La procédure `deploy-site.md` et le script `deploy-site.sh` concordent scrupuleusement sur les 6 commandes gérées et leurs comportements.
- NON BLOQUANT : Le changement respecte strictement l'architecture (AD-14 sans port public en production, AD-15 pour la journalisation, AD-22 pour l'isolement du canal de répétition).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (chaque appel externe susceptible d'échouer est encadré et provoque un arrêt explicite avec un code de sortie d'anomalie 1 ou 2).

VERDICT: NON BLOQUANT — aucune

### 25/09/2026 — `b7025a0` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 119. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: bbb00d84625516f0262b7643

##### Revue BMAD

###### Lentille : edge-case-hunter
- NON BLOQUANT : Aucun cas limite non géré n'a été trouvé. L'analyse des branches montre que les arguments réseau sont sécurisés (pas de glob, pas de ré-évaluation), et les cas d'échecs (`mktemp` impossible, binaire `docker` absent, chargement d'image invalide) sont explicitement interceptés.

###### Lentille : verification-gap
- NON BLOQUANT : Aucune lacune de vérification trouvée (No verification gaps found). Les comportements ajoutés (vérification stricte du canal, décompte d'arguments, robustesse face aux injections shell) sont validés de manière adéquate comme le montre le rapport d'exécution inclus dans la PR.

##### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (l'étanchéité des canaux de déploiement et de répétition est totale).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur (hormis la boucle locale `127.0.0.1`), aucun secret n'est commité, et l'usage de `set +x` garantit qu'aucun script n'affiche d'informations internes au serveur ou à la forge dans les journaux.
- NON BLOQUANT : La procédure `docs/procedures/deploy-site.md` et le script `deploy/remote/deploy-site.sh` concordent parfaitement : les 6 commandes documentées sont exactement celles supportées et validées par le script.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-14 respectée par l'absence de port publié en production, AD-15 respectée par la configuration `logging` de Docker, AD-22 respectée par le réseau isolé de la répétition).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (chaque appel à Docker est encapsulé de manière à capturer l'erreur via `|| docker_rc=$?` pour la traiter explicitement avant de rendre la main).

VERDICT: NON BLOQUANT — aucune

## Décisions

- **Constat de la revue d'architecture, « le réseau du proxy a une valeur par défaut dans `compose.yaml` (`${PROXY_NETWORK:-…}`) ; aucun fichier `.env` sous `deploy/` » — refusé pour moitié, retenu pour moitié.** La moitié refusée : une valeur par défaut est exactement le garde-fou qui s'ouvre en cas de panne, et elle écrirait un nom d'infrastructure dans le dépôt, ce que NFR-9 interdit ; le constat S1 de la revue de spec a tranché l'inverse, `${PROXY_NETWORK:?}`. La moitié retenue : **aucun `.env` n'est commité sous `deploy/`** — celui du serveur est créé sur le serveur, et `scripts/check-private.sh` refuse déjà ce chemin.
- **Une seule commande de mise en service pour les deux canaux.** `deploy` et `rollback` partagent le même `docker compose up -d` ; seul ce qui le précède diffère (charger et vérifier l'archive, ou vérifier que l'image est présente). Écrire deux fois la même ligne aurait été la faute que `shell-scripts.md` nomme : « une parade s'écrit une fois ».
- **Rien n'est supprimé après un refus de `deploy`.** L'image chargée sous un mauvais nom reste sur le serveur. La supprimer serait dangereux : une archive nommée `eleyone-site:v1.0.0` envoyée avec une demande `deploy v1.0.1` ferait supprimer l'image de production en service. Le message dit que l'image a été chargée mais n'a pas été mise en service ; la rétention fera le ménage au déploiement suivant si le tag est de production.

## Décisions de l'orchestrateur

### Les trois écarts au brief, jugés

| Écart | Jugement |
| --- | --- |
| La garde de lecture `\|\| [[ -n $ligne ]]` ajoutée aux trois boucles | **Accepté, et c'est le meilleur apport de la story.** Une sortie de `docker load` sans saut de ligne final perdait sa **dernière** ligne — donc la dernière image, précisément celle qui déclenche le refus. C'est la garde n° 7 de l'aîné, que mon brief ne listait pas : le point 19 demande de parcourir l'aîné garde par garde, et la sous-tâche a trouvé celle que j'avais omise. |
| Un faux `rm` et un faux `id` en tête de `PATH` | **Accepté.** Ils font deux choses à la fois : prouver qu'aucune commande n'a tourné, et empêcher la suite de jouer un vrai `rm -rf /` si une garde venait à tomber. Un test de sécurité qui n'est sûr que tant qu'il passe n'est pas un test de sécurité. |
| Un cas de glob non développé (`deploy v1.2.*` dans un dossier contenant `v1.2.3`) | **Accepté.** Il distingue vraiment `set -f` : sans lui, la demande **deviendrait un déploiement valide**. Un cas qui envoie un `*` sans fichier correspondant ne prouverait rien. |

### Une garde écartée, et c'est la bonne décision

La sous-tâche rapporte avoir **renoncé** à poser `IFS=$' \t\n'` avant le découpage : bash
réinitialise `IFS` à son démarrage quoi que porte l'environnement, donc la garde est inatteignable,
donc intestable, donc décorative. Le projet demande depuis la rétrospective de l'epic 5 qu'une garde
ait un test qui échoue sans elle ; une garde dont l'absence ne peut rien casser n'en est pas une, et
l'écrire aurait ajouté du bruit en donnant l'illusion d'une protection. `set +x`, lui, est
atteignable — quelqu'un peut lancer `bash -x` sur le serveur — et a son cas.

### Une assertion qui ne gardait rien

La sous-tâche a trouvé qu'une de ses propres assertions, `[[ $vus != *"down | "*"-f "* ]]`, ne
pouvait **jamais** correspondre, `-f <fichier>` arrivant avant `down` dans la ligne de commande.
C'est la même classe que les trois fausses gardes de la story 11.3, trouvée par la même méthode :
retirer la garde et regarder si le cas rougit. Trois stories de suite, la mutation a révélé un test
qui ne prouvait rien.

### Vérification du travail de la sous-tâche (point 22)

Rejoué par l'orchestrateur, sans reprendre ses mesures. Les demandes hostiles ont été envoyées à
`deploy-site.sh` avec un faux `docker`, un faux `rm` et un faux `id` en tête de `PATH` :

| Demande | Réponse |
| --- | --- |
| `deploy v1.0.0; rm -rf /` | refus : « attend exactement un tag, 4 reçu(s). Aucun service n'a été touché » |
| `deploy $(id)` | refus : tag affiché **échappé** (`\$\(id\)`), aucune substitution |
| `deploy v1.2.*` | refus : glob non développé (`v1.2.\*`) |
| `deploy v1.0.0 autre` | refus : « attend exactement un tag, 2 reçu(s) » |
| `rm -rf /` | refus : « demande inconnue « rm » » |
| `deploy v1.0.0-rc.1` | refus : « `-rc` désigne le canal de répétition » |

**Commandes réellement exécutées : aucune** — ni `docker`, ni `id`, ni `rm` autre que le nettoyage
du temporaire du script par son propre `trap`. Le tag est échappé jusque dans le message d'erreur.

| Autre vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 704 cas réussis |
| `deploy/compose.yaml` : ports publiés | **aucun** (AD-14) |
| `deploy/compose.rehearsal.yaml` | `127.0.0.1:18080:80`, projet `site-rehearsal` |
| `config` sans `SITE_TAG` | échoue, message explicite |
| `config` sans `PROXY_NETWORK` | échoue, message explicite |
| `config` avec les deux | `image: eleyone-site:v1.0.0`, `external: true`, `max-size: 10m` |
| NFR-9 : adresse IPv4 hors `127.0.0.1` dans `deploy/` et la procédure | **aucune** |
| les trois boucles portent `\|\| [[ -n $ligne ]]` | oui |
| `set -f` et `set +x` en tête | oui |

### Triage de la revue du code (`0378a07`)

**E1 — « n attend aucun argument » au lieu de « n'attend ». RETENU et corrigé**
(`deploy/remote/deploy-site.sh:141`). Une apostrophe manquante dans un message que le serveur renvoie
à l'appelant : c'est le genre de détail qu'on laisse et qui reste dix ans.

**E2 — un cas injectant la charge hostile dans le *nom de la commande* validerait `visible()` plus
directement. RETENU, et le relecteur a raison sur le fond.** Le tag est filtré par une expression
ancrée **avant** d'arriver au message ; le nom de la commande, lui, ne l'est par rien — une demande
inconnue est refusée *parce qu'*elle est inconnue, quel que soit ce qu'elle contient. C'est donc le
chemin le plus direct vers la fonction d'échappement, et le cas existant
(`argument_en_trop_non_recopie`) n'éprouvait qu'un octet de contrôle après une commande valide.

Mesuré par l'orchestrateur avant d'écrire le cas, avec un faux `docker`, un faux `rm` et un faux
`id` en tête de `PATH` :

```
$ SSH_ORIGINAL_COMMAND='$(id)`whoami`;rm' deploy/remote/deploy-site.sh
deploy-site: demande inconnue « \$\(id\)\`whoami\`\;rm ». … Aucun service n'a été touché.
commandes réellement exécutées : aucune
```

Cas ajouté (`deploy_site_nom_de_commande_hostile_cite`), puis rejoué avec `visible()` ramenée à
`printf '%s'` pour le voir échouer : `attendu dans le texte : \$\(id\)` / obtenu, le nom recopié
brut. La garde est donc éprouvée.

**Les autres lignes sont des confirmations** : canaux étanches, tags validés strictement, rétention
sur la seule production, aucune donnée privée ni adresse hors `127.0.0.1`, procédure et script
concordants sur les six commandes, conformité à AD-14, AD-15 et AD-22, aucune erreur silencieuse
sous `set -euo pipefail`. Rien à reporter.

Les deux correctifs arrivent **avant** le commit de statut, et la revue est relancée sur la nouvelle
tête — la séquence que la story 11.2 a appris à respecter.

### Triage de la seconde revue du code (`b7025a0`)

**Aucun constat.** L'edge-case-hunter ne trouve aucun cas limite non gardé — il relève que les
arguments venus du réseau ne sont ni développés ni réévalués, et que `mktemp` impossible, `docker`
absent et une image mal nommée sont tous interceptés. La lentille des trous de vérification ne
trouve rien. Les cinq lignes de la couche projet sont des confirmations : critères tenus,
étanchéité des deux canaux, aucune donnée privée hors `127.0.0.1`, procédure et script concordants
sur les six commandes, conformité à AD-14, AD-15 et AD-22, aucune erreur silencieuse.

Rien à retenir, rien à reporter ; écrit parce qu'un rapport se triage même quand il est vide.
