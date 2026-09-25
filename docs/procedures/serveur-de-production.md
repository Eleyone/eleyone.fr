# Procédure — Installer le serveur de production et les secrets de la forge

C'est la **seule opération manuelle** de l'epic 11 (story 11.6). Elle couvre les étapes 1 et 2 de la procédure « premier déploiement » de l'architecture : le compte de déploiement, sa clé restreinte, `deploy-site` installé, les deux fichiers Compose et le `.env` du serveur, puis les **douze secrets d'Actions** du dépôt sur la forge.

Elle se fait une fois, à la main, par Arnaud. Rien ici n'est joué par un agent ni par la CI : ce que le dépôt livre, ce sont cette procédure et le contrôle qui vérifie les secrets une fois posés.

**Rien de ce qui désigne le serveur n'entre dans le dépôt** (NFR-9). Les commandes ci-dessous emploient des substituts, à remplacer au moment de les lancer, jamais à écrire dans un fichier commité :

| Substitut | Ce qu'il désigne |
| --- | --- |
| `<hôte>` | le nom ou l'adresse du serveur de production |
| `<utilisateur>` | le compte de déploiement, créé à l'étape 1 |
| `<utilisateur-admin>` | le compte d'administration d'Arnaud sur le serveur, celui qui a `sudo` |
| `<réseau-du-proxy>` | le nom du réseau Docker de Nginx Proxy Manager |
| `<dossier>` | le dossier d'installation, `deploy` dans le répertoire de `<utilisateur>` |
| `<commit>` | le SHA du commit de `dev` dont les fichiers sont installés |

## Ce que cette procédure installe

| Élément | Emplacement | Propriétaire, droits |
| --- | --- | --- |
| Le compte de déploiement, membre du groupe `docker`, sans mot de passe | — | — |
| La clé publique restreinte | `~<utilisateur>/.ssh/authorized_keys` | `<utilisateur>`, `0600` |
| La commande forcée, copie de `deploy/remote/deploy-site.sh` | `<dossier>/remote/deploy-site.sh` | `<utilisateur>`, `0700` |
| Le service de production, copie de `deploy/compose.yaml` | `<dossier>/compose.yaml` | `<utilisateur>`, `0600` |
| Le canal de répétition, copie de `deploy/compose.rehearsal.yaml` | `<dossier>/compose.rehearsal.yaml` | `<utilisateur>`, `0600` |
| Le `.env` **du serveur**, jamais commité : `PROXY_NETWORK` | `<dossier>/.env` | `<utilisateur>`, `0600` |
| Les douze secrets d'Actions | réglages du dépôt sur la forge | — |

Le service `site` est celui de la production ; le projet `site-rehearsal` est celui de la répétition (AD-22). Les deux tournent sur le même serveur et ne partagent rien : projets Compose distincts, réseaux distincts, et la répétition n'est publiée que sur la boucle locale.

## Ce qu'elle ne fait pas

Les étapes 3 à 9 du premier déploiement — répétition générale, premier tag de production, hôte proxy dans NPM, vérifications, DNS, mesures, essai du retour arrière — **ne sont pas ici**. Elles appartiennent aux stories 11.9 et 11.11. À la fin de cette procédure, aucun conteneur du site ne tourne : c'est normal, et `status` le dit.

## Prérequis

À vérifier avant de commencer ; un seul manquant arrête tout le reste.

```bash
ssh <utilisateur-admin>@<hôte> 'uname -m; bash --version | head -n 1; docker version --format "{{.Server.Version}}"; docker compose version'
```

Attendu : `x86_64` — l'architecture des runners qui construisent l'image (AD-14) ; `bash` 4.4 ou plus récent ; Docker et le greffon `compose` qui répondent tous les deux. Sinon, s'arrêter : une image `amd64` ne se charge pas ailleurs, et `deploy-site` refuse de tourner sans le greffon.

```bash
ssh <utilisateur-admin>@<hôte> 'docker network ls --format "{{.Name}}"'
```

Attendu : le réseau de Nginx Proxy Manager est dans la liste. C'est `<réseau-du-proxy>`. Il **existe déjà** : les fichiers Compose le déclarent `external: true` et Compose ne doit ni le créer ni le supprimer. Pour lever un doute sur lequel c'est :

```bash
ssh <utilisateur-admin>@<hôte> 'docker network inspect <réseau-du-proxy> --format "{{range .Containers}}{{.Name}} {{end}}"'
```

Attendu : le conteneur de NPM est nommé dedans.

**Le déploiement passe par le port 22.** `DEPLOY_HOST` porte `<utilisateur>@<hôte>` et rien d'autre — pas de port —, et `scripts/release/ship.sh` ne passe aucun `-p` à `ssh`. Si le serveur écoute ailleurs, il faut le dire maintenant : le workflow `release` ne saurait pas s'y connecter, et il l'apprendrait au premier tag.

## 1. Le compte de déploiement

Sur le serveur, en `sudo` :

```bash
sudo useradd --create-home --shell /bin/bash --comment "deploiement eleyone.fr" <utilisateur>
sudo passwd --lock <utilisateur>
sudo usermod --append --groups docker <utilisateur>
sudo install -d -o <utilisateur> -g <utilisateur> -m 0700 ~<utilisateur>/.ssh
```

Attendu : aucune erreur. Puis :

```bash
id <utilisateur>
```

Attendu : le compte existe et le groupe `docker` figure dans ses groupes. Sinon, s'arrêter : sans ce groupe, `deploy-site` répondra « docker introuvable » ou se fera refuser l'accès au démon.

Le mot de passe est verrouillé : ce compte ne se connecte que par sa clé. Le shell reste `/bin/bash` — `command=` ne dépend pas du shell de connexion, mais un shell inexistant empêcherait aussi la commande forcée de tourner.

## 2. La clé restreinte

C'est la pièce qui compte. `restrict,command="…"` est ce qui fait qu'une clé volée ne donne rien d'autre que le protocole de `deploy-site`.

### Fabriquer la paire

Depuis le poste, dans un dossier temporaire qui ne survit pas à l'installation :

```bash
umask 077
tmp=$(mktemp -d)
ssh-keygen -t ed25519 -f "$tmp/deploy" -N '' -C "deploiement eleyone.fr"
```

Attendu : `$tmp/deploy` (clé privée) et `$tmp/deploy.pub` (clé publique). La phrase de passe est **vide** : un job de CI ne peut pas en taper une.

La clé privée n'est gardée nulle part sur le poste. Elle part dans le secret `DEPLOY_SSH_KEY` à l'étape 6, puis le dossier temporaire est supprimé à l'étape 7. Une clé perdue se refabrique en cinq minutes ; une copie gardée est un endroit de plus d'où elle peut fuir.

**Les étapes 2 à 7 se suivent dans le même shell** : `$tmp` porte la clé, les empreintes de l'hôte et la destination jusqu'à ce qu'elles soient posées en secrets. Un shell fermé entre-temps oblige à refaire l'étape 2 en entier, ligne d'`authorized_keys` comprise.

### Poser la ligne

La ligne à écrire dans `~<utilisateur>/.ssh/authorized_keys`, **en un seul morceau** :

```
restrict,command="<dossier>/remote/deploy-site.sh" ssh-ed25519 AAAA…<la clé publique fabriquée ci-dessus>… deploiement eleyone.fr
```

Mot par mot, et chacun compte :

- **`restrict`** active toutes les restrictions : redirection de ports, d'agent et X11 coupées, allocation de pseudo-terminal refusée, `~/.ssh/rc` non exécuté — et toute restriction que de futures versions d'OpenSSH ajouteront. C'est un ensemble qui *grandit*, là où une liste de `no-…` reste figée ;
- **`command="…"`** force la commande : quoi que le client demande, c'est ce script-là qui tourne, et la demande du client arrive dans `SSH_ORIGINAL_COMMAND`. Le manuel d'OpenSSH précise que cela vaut pour **un shell, une commande ou un sous-système** : `scp` et `sftp` passent donc par la commande forcée eux aussi ;
- **les deux ensemble, pas l'un ou l'autre.** Le manuel est explicite : avec `command=` seul, « the client may specify TCP and/or X11 forwarding unless they are explicitly prohibited, e.g. using the `restrict` key option ». Autrement dit, `command=` détourne la commande mais **laisse la redirection de ports ouverte** : la clé volée deviendrait un tunnel vers tout ce que le serveur peut joindre. C'est `restrict` qui ferme cette porte ;
- **le chemin est absolu**, celui de l'étape 3. Un chemin relatif serait résolu depuis le répertoire de connexion et casserait au premier changement.

Vérifié sur OpenSSH 9.6p1 le 25/09/2026, dans `man sshd`, section `AUTHORIZED_KEYS FILE FORMAT`.

Pose de la ligne, depuis le poste :

```bash
ssh <utilisateur-admin>@<hôte> "sudo tee -a ~<utilisateur>/.ssh/authorized_keys > /dev/null" <<< "restrict,command=\"<dossier>/remote/deploy-site.sh\" $(cat "$tmp/deploy.pub")"
ssh <utilisateur-admin>@<hôte> 'sudo chown <utilisateur>:<utilisateur> ~<utilisateur>/.ssh/authorized_keys && sudo chmod 0600 ~<utilisateur>/.ssh/authorized_keys && sudo ls -l ~<utilisateur>/.ssh/'
```

Attendu : `authorized_keys` en `-rw-------`, propriétaire `<utilisateur>`, dans un dossier `.ssh` en `drwx------`. Sinon, s'arrêter : `sshd` ignore un `authorized_keys` trop ouvert, et l'accès échouerait sans dire pourquoi.

Les quatre essais de la restriction sont à l'étape 5 : ils ont besoin du script installé.

## 3. Le dossier `deploy/` sur le serveur

Le dossier `deploy/` du dépôt est recopié **tel quel**, à un commit donné dont on vérifie les empreintes. `deploy/nginx/site.conf` vient avec ; il ne sert pas sur le serveur — il vit dans l'image — et la copie ne cherche pas à l'exclure.

Depuis le poste, dans un clone à jour, avec `<commit>` sur `dev` :

```bash
git archive --format=tar <commit> deploy | ssh <utilisateur-admin>@<hôte> 'sudo -u <utilisateur> tar -xf - -C ~<utilisateur>'
ssh <utilisateur-admin>@<hôte> 'sudo -u <utilisateur> chmod 0700 <dossier> <dossier>/remote && sudo -u <utilisateur> chmod 0700 <dossier>/remote/deploy-site.sh && sudo -u <utilisateur> chmod 0600 <dossier>/compose.yaml <dossier>/compose.rehearsal.yaml'
ssh <utilisateur-admin>@<hôte> 'sudo -u <utilisateur> sha256sum <dossier>/remote/deploy-site.sh <dossier>/compose.yaml <dossier>/compose.rehearsal.yaml'
```

L'archive est **dépliée depuis l'entrée standard**, sans passer par un fichier intermédiaire dans
`/tmp` : un `umask` restrictif du compte d'administration donnerait à ce fichier des droits que
`<utilisateur>` ne peut pas lire, et le `tar` suivant échouerait sur « Permission denied » — un
échec d'autant plus déroutant que la première commande, elle, aurait réussi (constat de la revue du
code de la PR n° 122). Rien à nettoyer non plus.

Attendu : les trois empreintes sont celles du dépôt au même commit. Sur le poste :

```bash
git show <commit>:deploy/remote/deploy-site.sh | sha256sum
git show <commit>:deploy/compose.yaml | sha256sum
git show <commit>:deploy/compose.rehearsal.yaml | sha256sum
```

Si une empreinte diffère, s'arrêter : le serveur applique alors autre chose que ce que le dépôt dit.

Le script trouve les fichiers Compose par un chemin relatif à lui-même, un cran au-dessus de `remote/` : c'est pourquoi l'arborescence est recopiée entière et non fichier par fichier.

## 4. Le `.env` du serveur

Il porte le nom du réseau du proxy, qui ne peut pas entrer dans le dépôt (NFR-9). **Ce `.env`-là n'est pas celui du poste de développement** : il vit à côté des fichiers Compose, sur le serveur, et ne porte qu'une ligne.

```bash
ssh <utilisateur-admin>@<hôte> 'sudo -u <utilisateur> sh -c "umask 077 && printf \"PROXY_NETWORK=%s\n\" \"<réseau-du-proxy>\" > <dossier>/.env"'
ssh <utilisateur-admin>@<hôte> 'sudo -u <utilisateur> ls -l <dossier>/.env && sudo -u <utilisateur> docker compose -f <dossier>/compose.yaml config > /dev/null'
```

Attendu : `.env` en `-rw-------`, propriétaire `<utilisateur>` ; et `docker compose config` qui ne dit rien. C'est la vérification qui compte : les deux variables du fichier Compose sont en `${…:?}`, donc Compose **échoue** si `PROXY_NETWORK` manque. Il se plaindra en revanche de `SITE_TAG`, qui n'est posée qu'au moment d'un déploiement :

```bash
ssh <utilisateur-admin>@<hôte> 'sudo -u <utilisateur> env SITE_TAG=v0.0.0 docker compose -f <dossier>/compose.yaml config > /dev/null && echo "composition lisible"'
```

Attendu : `composition lisible`. Si le message parle de `PROXY_NETWORK`, le `.env` n'est pas au bon endroit ou n'est pas lisible par `<utilisateur>`.

Le `.env` ne peut pas entrer dans le dépôt par accident : `scripts/check-private.sh` refuse tout chemin `.env`, seul ou suffixé, et le hook `pre-receive` de la forge le refuse aussi. `deploy/.env` n'est pas un oubli du `.gitignore`, c'est un chemin interdit.

## 5. Les quatre essais de la clé restreinte

C'est le premier critère d'acceptation de la story : `status` répond, une autre commande, un shell et une redirection de port sont refusés. Les quatre se lancent depuis le poste, avec la clé fabriquée à l'étape 2.

### Essai 1 — `status` répond

```bash
ssh -i "$tmp/deploy" <utilisateur>@<hôte> status; echo "code=$?"
```

Attendu, sur un serveur où rien n'est encore déployé :

```
deploy-site: production : aucun conteneur en service
deploy-site: répétition : aucun conteneur en service
code=0
```

C'est la preuve que la copie est en place, exécutable, et que le compte atteint le démon Docker. Si le message est `deploy-site: dossier d'installation introuvable`, le chemin de `command=` ne désigne pas le script ; si Docker se plaint des permissions, le compte n'est pas dans le groupe `docker` (refaire l'étape 1, puis se reconnecter).

### Essai 2 — une autre commande est refusée

```bash
ssh -i "$tmp/deploy" <utilisateur>@<hôte> id; echo "code=$?"
```

Attendu :

```
deploy-site: demande inconnue « id ». Commandes : deploy <tag>, rollback <tag>, status, rehearse deploy|rollback <tag>, rehearse stop. Aucun service n'a été touché.
code=1
```

La commande demandée n'est pas lancée : elle est seulement **lue** dans `SSH_ORIGINAL_COMMAND`, et le mot est cité entre guillemets par `printf '%q'`. Même chose pour une commande composée, qui n'est qu'une suite de mots :

```bash
ssh -i "$tmp/deploy" <utilisateur>@<hôte> 'status; id'; echo "code=$?"
```

Attendu : refus, code 1, et le message cite la demande sans l'exécuter — le `;` n'est qu'un caractère d'un mot.

Le transfert de fichiers passe par la même porte, parce que `command=` vaut aussi pour un sous-système :

```bash
scp -i "$tmp/deploy" /etc/hostname <utilisateur>@<hôte>:/tmp/; echo "code=$?"
```

Attendu : échec, code non nul. Rien n'est écrit sur le serveur.

### Essai 3 — un shell est refusé

```bash
ssh -i "$tmp/deploy" <utilisateur>@<hôte>; echo "code=$?"
```

Attendu :

```
deploy-site: aucune demande. Cette clé n'ouvre pas de session : elle ne porte que les commandes de deploy-site.
code=1
```

`ssh` peut écrire avant cela une ligne `PTY allocation request failed on channel 0` : c'est `restrict` qui refuse le pseudo-terminal, et c'est voulu. Aucune invite n'apparaît, et la connexion se ferme aussitôt.

### Essai 4 — une redirection de port est refusée

Dans un terminal :

```bash
ssh -i "$tmp/deploy" -N -L 18080:127.0.0.1:18080 <utilisateur>@<hôte>
```

Dans un autre, pendant que le premier tourne :

```bash
curl -sS -I http://127.0.0.1:18080/; echo "code=$?"
```

Attendu : `curl` échoue (connexion fermée, réponse vide), code non nul, et le premier terminal écrit une ligne `channel …: open failed: administratively prohibited`. Le port local s'ouvre — c'est le client qui l'ouvre —, mais **le serveur refuse d'ouvrir le canal** : rien ne passe. Fermer le premier terminal par `Ctrl-C`.

La variante qui échoue immédiatement, et qui se lit encore mieux :

```bash
ssh -i "$tmp/deploy" -N -o ExitOnForwardFailure=yes -R 19090:127.0.0.1:19090 <utilisateur>@<hôte>; echo "code=$?"
```

Attendu : `Error: remote port forwarding failed for listen port 19090`, code non nul, immédiatement.

**Si l'un de ces essais réussit là où il devrait échouer**, retirer la ligne de `authorized_keys` avant toute autre opération, et ne poser aucun secret sur la forge : une clé qui ouvre un tunnel ou un shell ne doit pas exister dans la CI.

### Ce que ces essais ne disent pas

Ils prouvent que la clé est restreinte, pas que la chaîne de mise en ligne fonctionne : ni `docker load`, ni la mise en service, ni le retour arrière ne sont exercés ici. C'est la répétition générale qui s'en charge (AD-22, stories 11.9 et 11.11).

**Le tunnel de la répétition n'emprunte pas cette clé.** AD-22 fait vérifier le canal de répétition par `ssh -L 18080:127.0.0.1:18080`, ce que l'essai 4 vient précisément de rendre impossible : ce tunnel-là passe par `<utilisateur-admin>`, le compte d'administration, jamais par le compte de déploiement. Les deux exigences ne se contredisent pas, elles s'appliquent à deux comptes différents.

## 6. Les douze secrets d'Actions

Douze, au niveau du **dépôt** (pas de l'organisation), sous ces noms exacts :

| Secret | Valeur à poser | Où elle se trouve |
| --- | --- | --- |
| les huit `HUGO_LEGAL_*` d'AD-9 | les vraies mentions légales | `docs/private/legal-release.env`, une par ligne |
| `PRIVATE_PATTERNS` | la liste des motifs interdits, une par ligne | `docs/private/forbidden-patterns.txt`, copiée telle quelle |
| `DEPLOY_SSH_KEY` | la clé **privée** fabriquée à l'étape 2, en entier | `$tmp/deploy` |
| `DEPLOY_HOST` | `<utilisateur>@<hôte>` | — |
| `DEPLOY_KNOWN_HOSTS` | la ligne `known_hosts` du serveur | voir ci-dessous |

Quatre choses qui ne se devinent pas :

- **`DEPLOY_HOST` porte le compte *et* la machine.** Il n'existe pas de secret `DEPLOY_USER` : un nom d'hôte seul ferait échouer la connexion sans que le message ne dise pourquoi. `ship.sh` refuse d'ailleurs une valeur qui n'a pas cette forme, et refuse séparément une valeur qui commence par `-`, que `ssh` lirait comme une option ;
- **`DEPLOY_SSH_KEY` porte la clé privée**, pas la publique. C'est l'erreur la plus plausible de cette installation, et `ship.sh` la refuse en cherchant `-----BEGIN … PRIVATE KEY-----` ;
- **aucune valeur ne se termine par un saut de ligne.** `ship.sh` valide `DEPLOY_HOST` par une expression ancrée `^…$`, qu'un saut de ligne final ferait échouer. Dans l'interface web, cela veut dire : ne pas appuyer sur Entrée après avoir collé ;
- **Gitea refuse un nom de secret commençant par `GITEA_`.** Les variables `GITEA_*` du poste n'ont donc pas d'équivalent en CI, et les jobs emploient le jeton intégré. Rien à poser de ce côté.

### Les huit valeurs légales, par l'interface

Réglages du dépôt → *Actions* → *Secrets* → *Add Secret*. Le nom, la valeur, valider, huit fois, en lisant chaque valeur dans `docs/private/legal-release.env`. Aucune ne passe ainsi par l'historique du shell ni par la liste des processus, et elles tiennent toutes sur une ligne.

Les quatre autres peuvent se poser de la même façon, en collant le contenu des fichiers. La section suivante fait la même chose sans l'interface, ce qui évite de manipuler une clé privée à la souris.

### Relever `DEPLOY_KNOWN_HOSTS`

La valeur se relève, et se **vérifie** : un `ssh-keyscan` seul enregistre ce que le réseau a bien voulu répondre.

```bash
ssh-keyscan -t ed25519 <hôte> > "$tmp/known_hosts" 2> /dev/null
ssh-keygen -lf "$tmp/known_hosts"
ssh <utilisateur-admin>@<hôte> 'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'
```

Attendu : les deux empreintes sont identiques. Si elles diffèrent, s'arrêter — la clé privée de déploiement partirait vers une machine que personne n'a vérifiée.

### Les quatre autres, par l'API

Le jeton passe par **l'entrée standard** de `curl`, jamais par la ligne de commande, où la liste des processus l'exposerait : c'est la garde de `scripts/lib/gitea.sh`. La valeur, elle, vient d'un **fichier**, jamais d'un argument, et le corps JSON est composé par `jq`, jamais par concaténation.

Depuis la racine du dépôt, sur le poste. `.env` n'est pas chargé par `source` — le projet ne le fait nulle part —, ses deux valeurs sont lues champ par champ, sans être affichées :

```bash
set +x                       # aucune trace de shell : le jeton et les valeurs passent par ici
forge_url=$(sed -n 's/^GITEA_URL=//p' .env | head -n 1)
forge_jeton=$(sed -n 's/^GITEA_TOKEN=//p' .env | head -n 1)
[ -n "$forge_url" ] && [ -n "$forge_jeton" ] && echo "adresse et jeton lus"

poser_secret() {             # $1 = nom du secret, $2 = fichier qui porte la valeur
  local corps reponse code
  corps=$(mktemp); reponse=$(mktemp)
  jq -Rs '{data: sub("\n$"; "")}' < "$2" > "$corps"
  code=$(printf 'header = "Authorization: token %s"\n' "$forge_jeton" \
    | curl -s -K - -o "$reponse" -w '%{http_code}' -X PUT \
      -H 'Content-Type: application/json' --data "@$corps" \
      "${forge_url%/}/api/v1/repos/Eleyone/eleyone.fr/actions/secrets/$1")
  rm -f "$corps" "$reponse"
  printf '%s : HTTP %s\n' "$1" "$code"
}

printf '%s' "<utilisateur>@<hôte>" > "$tmp/host"
poser_secret DEPLOY_SSH_KEY     "$tmp/deploy"
poser_secret DEPLOY_HOST        "$tmp/host"
poser_secret DEPLOY_KNOWN_HOSTS "$tmp/known_hosts"
poser_secret PRIVATE_PATTERNS   docs/private/forbidden-patterns.txt
```

Attendu : `HTTP 201` quatre fois. Le `jq -Rs` lit le fichier entier comme **une seule chaîne** — une clé privée et une liste de motifs tiennent sur plusieurs lignes — et `sub("\n$"; "")` retire le saut de ligne final, celui qui ferait échouer `DEPLOY_HOST`.

Poser une valeur déjà posée la **remplace** ; `DELETE` sur le même chemin la supprime et rend `204`. Une valeur n'est jamais relisible : la seule correction possible est de reposer la bonne.

### Vérifier

```bash
scripts/release/check-forge-secrets.sh; echo "code=$?"
```

Attendu, une fois les douze posés :

```
release/check-forge-secrets: 12 secrets attendus, 12 présents sur le dépôt, 0 variable(s).
release/check-forge-secrets: les 12 secrets attendus sont présents, sous leurs noms exacts. Aucune valeur n'a été lue.
code=0
```

Le contrôle **lit les noms**, et seulement les noms : l'API ne rend jamais la valeur d'un secret, si bien qu'il ne peut pas vérifier qu'une valeur est la bonne. Ce qu'il voit :

- un secret **manquant** est un refus (code 1) : le workflow `release` échouerait ;
- un secret **inattendu** est nommé sans bloquer — `ANTHROPIC_API_KEY` relève de l'epic 12 (AD-16) et peut être posé d'avance ;
- une **faute de frappe** se lit deux fois, une fois comme manquante et une fois comme inattendue : `DEPLOY_HOSTS` posé à la place de `DEPLOY_HOST` saute aux yeux ;
- une **variable** d'Actions, s'il en existe, est nommée sans bloquer : l'architecture n'en attend aucune, et une variable posée par erreur mérite d'être vue.

Avant cette procédure, lancé sur un dépôt vierge, il nomme les douze comme manquants et rend 1. C'est l'état de départ, et c'est normal.

Reste à éprouver ce que ce contrôle ne peut pas voir : que chaque valeur est la bonne. Le premier `release` le dira — une valeur légale fausse se lit sur la page des mentions légales, une clé fausse fait échouer la connexion.

## 7. Nettoyer le poste

Une fois les douze secrets posés et vérifiés :

```bash
rm -rf "$tmp"
unset tmp forge_url forge_jeton
```

Aucune copie de la clé privée, de la ligne `known_hosts` ni du jeton ne reste dans le shell ou sur le disque du poste. La clé privée n'existe plus que dans le secret de la forge et, sous sa forme publique, dans `authorized_keys`.

## Recopier après une modification

Comme le hook `pre-receive` de la forge, ces fichiers ne se mettent pas à jour tout seuls.

- **`deploy/remote/deploy-site.sh`, `deploy/compose.yaml` ou `deploy/compose.rehearsal.yaml` modifiés** et fusionnés dans `dev` : refaire l'étape 3 au nouveau commit, empreintes comprises, puis l'essai 1 de l'étape 5. Sans cela, le serveur continue d'appliquer la version précédente, et un contrôle ajouté dans le dépôt ne garde rien là-bas.
- **Le nom du réseau du proxy change** : refaire l'étape 4.
- **La liste des motifs interdits change** (`docs/private/forbidden-patterns.txt`) : reposer le secret `PRIVATE_PATTERNS`. Tant que ce n'est pas fait, C21 et C22 travaillent sur l'ancienne liste pendant une mise en ligne.
- **Les mentions légales changent** : reposer les valeurs `HUGO_LEGAL_*` concernées, puis relancer `scripts/release/check-forge-secrets.sh` — il confirmera les noms, pas les valeurs.
- **La clé de déploiement est refaite** : reposer `DEPLOY_SSH_KEY` **et** remplacer la ligne de `authorized_keys`, dans cet ordre ; entre les deux, aucune mise en ligne n'aboutirait.

## En cas d'échec

- **`deploy-site: dossier d'installation introuvable`** : le chemin de `command=` ne mène pas au script, ou l'arborescence `remote/` n'a pas été recopiée entière.
- **`deploy-site: fichier Compose du canal … absent ou illisible`** : l'étape 3 est incomplète, ou les droits empêchent `<utilisateur>` de lire le fichier. Le refus est voulu : sans le fichier, le script sauterait une étape au lieu de s'arrêter.
- **Docker répond « permission denied »** : le compte n'est pas dans le groupe `docker`, ou la session a été ouverte avant l'ajout au groupe.
- **`PROXY_NETWORK` manquante dans un message de Compose** : le `.env` n'est pas dans le dossier des fichiers Compose, ou il n'appartient pas à `<utilisateur>`.
- **`check-forge-secrets` refuse le jeton (401 ou 403)** : le jeton de `.env` n'a pas la portée des secrets du dépôt. Voir `gitea-token.md`.
- **`check-forge-secrets` rend 404** : le dépôt n'est pas celui que le jeton peut lire, ou la version de la forge n'a pas ce point d'API.
- **Un essai de l'étape 5 réussit alors qu'il devait échouer** : retirer la ligne de `authorized_keys` immédiatement, ne poser aucun secret, et reprendre l'étape 2.
