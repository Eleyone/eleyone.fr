# Procédure — Répétition générale de la mise en ligne

Une répétition générale joue **toute la chaîne de mise en ligne** sur le serveur de production, sur un canal séparé de la production, sans DNS ni port public (AD-22). Elle existe pour qu'une première mise en ligne ne découvre pas en production une erreur de chaîne : secrets, image, envoi, commande forcée, retour arrière.

`scripts/rehearse-release.sh` tient la séquence côté poste. Comme pour `release`, la livraison elle-même ne lui appartient pas : un tag `vX.Y.Z-rc.N` poussé sur `dev` déclenche le workflow `release` de la forge, qui construit l'image et l'envoie au canal de répétition (`release-workflow.md`, `deploy-site.md`).

La procédure vaut pour **tout tag `vX.Y.Z-rc.N`**, dont la première répétition sur `v0.1.0-rc.1`, avec les seules pages déjà publiées (D-5).

## Prérequis

- Le serveur installé et les secrets posés sur la forge (`serveur-de-production.md`, story 11.6).
- `git`, `ssh` et `curl` sur le poste ; `ssh-agent`, `ssh-add` et `ssh-keygen`, livrés avec OpenSSH, quand la clé du poste attend sa phrase de passe.
- `.env` à la racine du dépôt, avec **deux destinations au format `<utilisateur>@<hôte>`, sans port** :
  - `ADMIN_HOST` — le compte d'administration. Il ne sert qu'au **tunnel** et à la lecture des **journaux** ;
  - `DEPLOY_HOST` — le compte de déploiement, celui dont la clé restreinte n'accepte que les commandes de `deploy-site`. Même nom, même valeur que le secret de la forge.
- Les deux comptes joignables sans question posée **par `ssh`** : l'empreinte de l'hôte déjà dans le `known_hosts` du poste, et la clé du compte d'administration utilisable telle quelle — sans phrase de passe, ou déjà dans l'agent de l'utilisateur. Le script se connecte en `BatchMode=yes` : une question posée par `ssh` est un échec, pas une attente. La clé du poste fait exception : si elle attend sa phrase de passe, **le script la charge lui-même** dans un agent privé (« La clé du poste, et l'agent privé », plus bas).
- Pour le compte de déploiement, **la clé du poste**, pas celle de la forge : une seconde clé restreinte par la même ligne d'`authorized_keys`, que l'entrée `Match host … user …` du `~/.ssh/config` donne à ce compte seul (`serveur-de-production.md`, « La clé du poste »). La clé de la forge ne quitte jamais son secret : le poste ne l'a pas, et n'a pas à l'avoir.
- **Le fichier des valeurs légales de mise en ligne**, sur le poste : `docs/private/legal-release.env` par défaut, ou celui que désigne `LEGAL_RELEASE_ENV_FILE` — le même que `scripts/build-image.sh --release` emploie (`build-image.md`), et dont les valeurs doivent être celles des secrets de la forge. Il porte **chacun** des noms `HUGO_LEGAL_*` de `.env.example`, non vide. La répétition vérifie que les deux pages légales servies portent ces valeurs-là (« Les pages légales et leurs vraies valeurs », plus bas) ; sans lui, elle s'arrête avant tout tag.
- Le port `18080` libre sur le poste.
- Un **terminal**, si la clé du poste n'est pas déjà dans un agent : la phrase de passe s'y tape. Sans terminal — la CI, un agent IA —, le script s'arrête avant tout tag et dit quoi faire.

**Aucune valeur de `.env` ni du fichier des valeurs légales n'est affichée** par le script, ni dans un message, ni dans un journal : un message nomme la variable, jamais son contenu (NFR-9, AD-9).

## Les deux comptes, et pourquoi ils ne se mélangent pas

| Ce qui part | Par quel compte | Pourquoi |
|---|---|---|
| `status`, `rehearse rollback <tag>`, `rehearse stop` | **déploiement** (`DEPLOY_HOST`), avec la clé du poste | c'est le canal restreint : la clé est posée avec `restrict,command=`, elle n'ouvre rien d'autre |
| le tunnel `ssh -L 18080:127.0.0.1:18080` | **administration** (`ADMIN_HOST`) | `restrict` **refuse une redirection de port** — premier critère d'acceptation de la story 11.6, vérifié par le quatrième de ses quatre essais |
| `docker logs` du conteneur de répétition | **administration** (`ADMIN_HOST`) | le tunnel ne transporte que du HTTP ; un `docker logs` lancé en local parlerait au démon Docker du poste |

AD-22 (« accès par `ssh -L` ») et la story 11.6 (« la clé de déploiement refuse un tunnel ») ne se contredisent qu'en apparence : ils portent sur deux comptes différents.

## La clé du poste, et l'agent privé

La clé du poste porte une phrase de passe (`serveur-de-production.md`, « La clé du poste »). En `BatchMode=yes`, `ssh` ne la tape pas : elle ne sert que chargée dans un agent. Plutôt que d'exiger un agent permanent, qu'on oublie et qui garde la clé déchiffrée en mémoire, le script en démarre un **à lui**, seulement s'il en a besoin, et le tue en sortant :

1. `status` répond du premier coup — la clé est déjà dans un agent, ou n'a pas de phrase de passe : rien n'est démarré ;
2. sinon, et seulement si `ssh` n'a pas pu se connecter (code `255` ; un autre code est la réponse du serveur, qu'une clé chargée ne changerait pas), le script relève par `ssh -G` les clés que `ssh` proposerait au compte de déploiement. Le chemin de la clé n'est écrit nulle part dans le script : c'est l'entrée `Match` du `~/.ssh/config` qui le donne. `~` et `%d` y sont développés ; un chemin qui porte un autre jeton (`%r`, `%h`…) est écarté ;
3. si aucune de ces clés n'a de phrase de passe, l'échec n'est pas une affaire d'agent : le script s'arrête et montre le message de `ssh`, destinations masquées ;
4. sinon, un agent démarre, `ssh-add` y charge la ou les clés protégées — **la phrase de passe est demandée une fois**, dans le terminal —, puis `status` est redemandé. S'il échoue encore, le script s'arrête.

L'agent est **privé** à double titre :

- sa socket vit dans le dossier temporaire du script, créé en `0700`, et n'est jamais exportée : seules les connexions au **compte de déploiement** la reçoivent, avec `-o IdentityAgent=SSH_AUTH_SOCK` pour qu'une entrée du `~/.ssh/config` ne désigne pas un autre agent. Les connexions au compte d'administration gardent l'environnement de l'utilisateur, et sa clé d'administration, si elle vit dans **son** agent, continue de servir ;
- il meurt avec le script, sur **tous** les chemins de sortie — succès, refus, anomalie, `Ctrl-C`, `TERM` — par le même piège que le tunnel. Le script ne tue que l'agent qu'il a démarré, jamais celui de l'utilisateur.

Il est lancé par `ssh-agent -D -a <socket>` en tâche de fond, et non par `ssh-agent -s` : celui-ci se dédouble pour passer en arrière-plan. Le PID qu'il affiche est bien l'agent vivant, mais ce n'est plus un enfant du script — on ne peut ni l'attendre ni lire son code —, et sa socket ne se connaîtrait qu'en relisant sa sortie, voire en l'`eval`-uant. Au premier plan, `$!` est l'agent lui-même, exactement comme pour le tunnel.

**Sans terminal**, `ssh-add` ne peut rien demander : il écrit son invite sur la sortie d'erreur, lit une fin de fichier et rend `1` aussitôt, sans attendre. `SSH_ASKPASS_REQUIRE=never` écarte la fenêtre graphique qu'il ouvrirait sinon quand un affichage est disponible. Le script s'arrête alors avant tout tag, en disant de le lancer dans un terminal ou de charger la clé dans un agent avant. Ces comportements ont été vérifiés avec OpenSSH 10.2p1, le 02/10/2026 : `setsid ssh-add <clé> < /dev/null` sur une clé d'essai protégée, `ssh-add` sous un pseudo-terminal (`script`), et `ssh -G` sur une configuration d'essai.

L'audit fait la même chose que `--run` : il peut donc demander la phrase de passe, et son agent meurt avec lui. `--run` la redemande.

## Lancer

```bash
scripts/rehearse-release.sh v0.1.0-rc.1           # audit : vérifie tout, connexions comprises, ne pousse rien
scripts/rehearse-release.sh v0.1.0-rc.1 --run     # joue la répétition, deux tags poussés compris
```

Le **tag suivant se calcule** : `v0.1.0-rc.1` donne `v0.1.0-rc.2`. Il n'y a qu'un tag à donner.

`--run` ne se déduit jamais. Pousser un tag est irréversible — la forge le voit, le miroir public aussi, et le workflow part —, et une action irréversible se demande explicitement, comme `--merge` pour `release`.

Codes de sortie : `0` la répétition s'est déroulée en entier et tout est vérifié ; `1` refus (tag déjà posé, délai dépassé, serveur qui refuse) ou vérification en échec ; `2` anomalie (usage, tag mal formé, outil absent, `.env` absent ou incomplet, fichier des valeurs légales absent, incomplet ou refusé, dépôt illisible, compte injoignable ou clé du poste impossible à charger avant le premier tag, tunnel impossible, serveur muet).

## Avant toute action

Dans cet ordre, et sans rien pousser :

1. **Le tag est une répétition.** Un `vX.Y.Z` est refusé d'entrée : c'est une mise en ligne, elle se pose sur `main` par `release` (AD-22). Les deux expressions sont disjointes et ancrées, sans zéro de tête (`scripts/lib/release.sh`).
2. **Les outils, le dépôt, les destinations.** `git`, `ssh`, `curl` ; le dépôt distant est bien celui du projet ; `ADMIN_HOST` et `DEPLOY_HOST` sont présents et suivent `<utilisateur>@<hôte>`. Une valeur qui commence par `-` est refusée à part : `ssh` y lirait une option, pas une destination.
3. **Le fichier des valeurs légales.** Trouvé comme `build-image.sh` le trouve — `LEGAL_RELEASE_ENV_FILE`, sinon `docs/private/legal-release.env` ; un chemin relatif se résout depuis le dossier d'appel —, et lu par `.working-method/lib/dotenv.sh`, le seul lecteur dotenv du dépôt, avec la règle de `scripts/env.sh` : une valeur vide vaut absence, la première valeur non vide d'un nom est la sienne. Sont refusés, chacun avec son message et **sans afficher aucune valeur** :
   - un fichier absent, illisible, ou qui n'est pas un fichier ;
   - le `.env` du dépôt, `ci/legal-placeholder.env`, ou tout fichier nommé `.env` (les refus de `build-image.sh` et d'`env.sh` en mode release) ;
   - un nom de `.env.example` absent ou vide — tous les manquants sont nommés d'un coup ;
   - une valeur faite de blancs : vide une fois normalisée, elle se trouverait dans toute page ;
   - une valeur **égale à la valeur factice** du même nom : une copie du fichier factice sous un autre nom ferait passer pour conforme un site construit avec les valeurs factices.

   La liste des noms vient du `.env.example` qui accompagne le script, jamais d'un nombre écrit dans le code. Une liste vide, un `.env.example` ou un `ci/legal-placeholder.env` illisibles arrêtent aussi le script.
4. **Le port `18080` est libre sur le poste.** S'il répond déjà, le tunnel ne pourrait pas s'y poser — et, surtout, les vérifications interrogeraient ce service-là en croyant parler au serveur.
5. **Les deux tags sont libres**, relus depuis la forge par un `git fetch --tags` explicite. Les **deux**, avant le premier push : découvrir le second occupé après avoir poussé le premier laisserait une répétition à moitié jouée.
6. **L'arbre de travail** : une modification en attente ne bloque pas — la répétition porte sur `origin/dev` —, mais elle est signalée, pour que personne ne croie répéter ce qu'il a sous la main.
7. **Les deux connexions.** `status` doit répondre par le compte de déploiement — au besoin après le chargement de la clé du poste dans l'agent privé — et le compte d'administration doit accepter une connexion (`true`). Sans cela, `--run` pousserait le premier tag, irréversible, puis échouerait sur trois `status` muets : une répétition à moitié jouée. Un échec arrête tout, nomme le compte par son rôle et montre le message de `ssh`, destinations masquées.

Sans `--run`, le script affiche le programme et s'arrête là : l'audit a vraiment lu le fichier des valeurs légales et éprouvé les deux connexions, et n'a rien poussé.

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
| `/mentions-legales/` | les mêmes que `/`, puis **chacune des valeurs** du fichier des valeurs légales dans le corps servi |
| `/en/legal-notice/` | les mêmes que `/en/`, puis chacune des valeurs, de même |
| un fichier empreinté | HTTP 200, en-têtes communs, **pas de CSP**, `Cache-Control: public, max-age=31536000, immutable` |
| un SVG, s'il en existe un | les mêmes, avec le `Cache-Control` que son nom commande |
| les journaux du conteneur | aucune adresse IP (AD-15) |

Le fichier empreinté n'est pas deviné : il est **relevé dans la page d'accueil servie**. C'est le seul moyen de vérifier la règle `immutable` sans inventer un nom de fichier. S'il n'y en a aucun, le contrôle échoue au lieu de passer au vert sans rien lire. Le SVG est conditionnel — le site n'en porte pas encore —, et son absence est dite, pas tue.

**La CSP n'est exigée que sur le HTML, et son absence est exigée ailleurs.** `deploy/nginx/site.conf` ne l'envoie que sur `~^text/html` : une valeur vide supprime l'en-tête, et un SVG n'en porte donc pas, par conception — les schémas D2 portent des `<style>` et des polices embarquées, qu'une politique `style-src 'self'` casserait. Une vérification qui exigerait la CSP partout échouerait sur un fichier parfaitement conforme.

De même, `Cache-Control` vaut `immutable` **seulement** pour un fichier empreinté d'un condensat, et `no-cache` pour tout le reste : l'attente se déduit du nom du fichier, exactement comme le `map` de nginx la déduit de l'URI.

### Les pages légales et leurs vraies valeurs

Les deux pages d'AD-9 — `/mentions-legales/` et `/en/legal-notice/`, écrites une fois dans `scripts/lib/legal.sh`, d'où C23 tire aussi ses chemins — doivent porter **chacune des valeurs** du fichier de mise en ligne, à **chaque** passage des vérifications : après le premier tag, après le second, après le retour arrière. Une image construite avec d'autres valeurs — un secret de la forge vide, les valeurs factices d'un build de contrôle, une ancienne valeur — se voit ainsi avant la mise en ligne, sans contrôle à l'œil (arbitrage d'Arnaud du 02/10/2026 : « la vérif doit se faire systématiquement et automatiquement »).

Une page qui ne répond pas `200` en HTML n'est pas lue : la vérification le dit (« valeurs légales non vérifiées »), plutôt que de chercher des valeurs dans une page d'erreur.

**La page et la valeur sont ramenées à la même forme** avant d'être comparées, comme C23 le fait pour l'adresse de l'éditeur. Ce que le rendu fait d'une valeur a été mesuré sur un vrai build de production, le 02/10/2026 :

- le minifieur replie toute suite d'espaces en une seule ;
- sur la page **française** seulement, la typographie (`layouts/_partials/typo-fr-texte.html`) remplace l'espace devant `:` par U+00A0, et celle devant `;`, `!`, `?` ou à l'intérieur des guillemets par U+202F ;
- le minifieur écrit `<` en `&lt;` et laisse `&`, `'` et `"` en clair ; une autre sérialisation écrirait `&amp;`, `&#39;`, `&#43;` ou `&nbsp;`.

La page est donc décodée (entités, insécables comprises), ses insécables ramenées à une espace et ses blancs normalisés ; la valeur perd ses espaces de bord et ses blancs sont normalisés de même. Les filtres sont ceux de C22 et C23, rangés dans `scripts/lib/text.sh`, plus le repli des deux insécables, qui ne sert qu'ici (`deferred-work.md` dit pourquoi C22 et C23 ne replient pas).

Une valeur absente est signalée par **le nom de sa variable et la page**, jamais par son contenu, ni par celui de la page servie : sur une page construite avec d'autres valeurs, ce sont celles-là qu'on verrait.

Les **journaux** se lisent par `ssh <compte d'administration> docker logs …`, le conteneur étant retrouvé par son étiquette de projet Compose. Une ligne fautive est signalée par son **numéro**, jamais par son contenu : une adresse IP est précisément ce qu'on ne veut voir nulle part (AD-15, NFR-3).

Une vérification en échec arrête la répétition, à ce point de la séquence, sans rien effacer.

## Après un échec : ce que le script n'arrête pas

Le piège de sortie **tue le tunnel et l'agent privé** — un processus laissé sur le poste est un déchet, et l'agent garderait la clé déchiffrée — mais **ne lance pas `rehearse stop`**.

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
bash .working-method/tests/run.sh scripts/tests/test-rehearse-release.sh
```

Les pages légales des cas sont **les vraies pages**, copiées d'un build de production fait avec les valeurs factices (`scripts/tests/fixtures/rehearse-release/`) : minifiées, sans guillemets d'attribut, typographie française appliquée. Les valeurs d'essai en dérivent, pour que la page servie garde la forme exacte du rendu.

Les cas tournent **hors ligne** : de faux `ssh`, `curl`, `git`, `sleep`, `ssh-agent`, `ssh-add` et `ssh-keygen` sont posés en tête de `PATH` et enregistrent leurs appels. Aucun cas ne pose de tag, ni localement ni sur la forge, n'ouvre de connexion, ni ne lit le `.env` du dépôt — chacun se lance depuis un dépôt git jetable qui porte le sien.

La mort de l'agent privé est vérifiée sur chaque chemin de sortie rejouable : succès, refus, anomalie, et `SIGTERM` envoyé pendant l'attente. `SIGINT` ne l'est pas par la suite : un shell non interactif lancé en tâche de fond l'ignore, et bash ne laisse pas piéger un signal ignoré à l'entrée. Il a été vérifié une fois, le 02/10/2026, en lançant le script avec les mêmes faux binaires depuis un processus Python qui ne l'ignore pas : code `130`, agent arrêté.
