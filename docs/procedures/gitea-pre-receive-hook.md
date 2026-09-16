# Procédure — Hook pre-receive du garde-fou sur Gitea

La forge principale refuse côté serveur tout push qui contient un chemin ou un motif privé (AD-12). Ce hook est l'autorité du garde-fou : un poste sans hook local ne peut pas le contourner. Cette procédure l'installe sur le dépôt du site, puis l'essaie (story 1.2).

**Rien de ce qui désigne le serveur n'entre dans le dépôt** : ni nom d'hôte, ni chemin de la machine hôte, ni nom de volume. Les chemins ci-dessous sont ceux de l'intérieur du conteneur, fixés par l'image officielle de Gitea. `<conteneur>` est le nom du conteneur Gitea sur la machine hôte.

## Ce qui est installé

| Élément | Emplacement dans le conteneur (image normale) | Propriétaire, droits |
|---|---|---|
| Script du garde-fou, copie de `scripts/check-private.sh` | `/data/gitea/eleyone-check-private/check-private.sh` | `git`, `0600` |
| Liste des motifs, extraite du dépôt nu privé (`main:forbidden-patterns.txt`) | `/data/gitea/eleyone-check-private/forbidden-patterns.txt` | `git`, `0600` |
| Script du hook, copie de `scripts/gitea/pre-receive-check-private` | `/data/git/repositories/eleyone/eleyone.fr.git/hooks/pre-receive.d/check-private` | `git`, `0755` |

`/data/gitea` est la valeur de `GITEA_CUSTOM` dans l'image normale. Le script du hook ne connaît que cette variable : il refuse le push si elle manque, si le script du garde-fou ou la liste est absent ou illisible, puis lance `check-private.sh pre-receive` avec `PRIVATE_PATTERNS_FILE`.

Tout est dans le volume de données de Gitea (`/data`) : l'installation survit à la recréation du conteneur. `DISABLE_GIT_HOOKS` reste à `true` : ce réglage ne ferme que l'édition des hooks depuis l'interface web, pas l'exécution d'un hook posé à la main.

Le hook n'est posé que dans le dépôt nu du site. Le dépôt privé n'en a pas et n'est jamais mirroré.

## Prérequis

- Gitea 1.27.3 en conteneur, image normale (`GITEA_CUSTOM=/data/gitea`, utilisateur `git`). Pour l'image rootless, remplacer `/data/gitea` par `/var/lib/gitea/custom` et `/data/git/repositories` par `/var/lib/gitea/git/repositories`.
- Les deux scripts sont extraits du dépôt nu du site, dans le conteneur, à un commit donné dont on vérifie les empreintes sha256 : ni réseau ni identifiant.
- La liste des motifs est extraite du dépôt nu **privé**, dans le conteneur (`main:forbidden-patterns.txt`) : aucune copie de transit sur la machine hôte (décision d'Arnaud, story 1.2). **La liste n'est jamais affichée ni recopiée ailleurs**, ni dans un commit, un journal, un compte rendu ou une conversation. Le chemin du dépôt nu privé est donné par Arnaud à l'opérateur et n'est écrit nulle part dans le dépôt du site.
- Les tests du garde-fou réussissent dans l'image de Gitea (essai de la story 1.2 : `gitea/gitea:1.27.3`, `grep` de BusyBox).

## Installer

Opérations sur la machine hôte, par Arnaud ou un agent du homelab qui suit les mêmes règles. Le hook généré par Gitea n'exécute un fichier de `pre-receive.d/` que s'il est exécutable : le `chmod 0755` final active le hook, une fois la liste et le script en place et vérifiés. Avant lui, les pushs ne sont pas affectés.

Variables : `C=<conteneur>`, `R=/data/git/repositories/eleyone/eleyone.fr.git`, `P=<dépôt nu privé>`, `COMMIT=<SHA du commit à installer>`, `D=/data/gitea/eleyone-check-private`, `H=$R/hooks/pre-receive.d`.

1. **Vérifier** :

   ```bash
   docker exec -u git "$C" sh -c "echo GITEA_CUSTOM=\$GITEA_CUSTOM; id -un; command -v bash; ls -d $R; git -C $R cat-file -t $COMMIT"
   docker exec -u git "$C" sh -c "git -C $P cat-file -e main:forbidden-patterns.txt && echo 'liste présente dans le dépôt privé'"
   ```

   Attendu : `GITEA_CUSTOM=/data/gitea`, `git`, `/bin/bash`, le chemin du dépôt nu, `commit`, puis « liste présente dans le dépôt privé ».

2. **Liste et script du garde-fou**, sans effet sur les pushs :

   ```bash
   docker exec -u git "$C" sh -c "mkdir -p $D && chmod 0700 $D"
   docker exec -u git "$C" sh -c "umask 077 && git -C $P show main:forbidden-patterns.txt > $D/forbidden-patterns.txt"
   docker exec -u git "$C" sh -c "umask 077 && git -C $R show $COMMIT:scripts/check-private.sh > $D/check-private.sh"
   docker exec -u git "$C" sha256sum $D/check-private.sh
   docker exec -u git "$C" sh -c "test -r $D/forbidden-patterns.txt && test -s $D/forbidden-patterns.txt && echo 'liste lisible par git, non vide'"
   ```

   Attendu : l'empreinte de `scripts/check-private.sh` au commit installé (`git show $COMMIT:scripts/check-private.sh | sha256sum` sur le poste), puis « liste lisible par git, non vide ». Sinon, s'arrêter sans poser le hook.

3. **Hook déposé, encore inactif** :

   ```bash
   docker exec -u git "$C" sh -c "umask 022 && git -C $R show $COMMIT:scripts/gitea/pre-receive-check-private > $H/check-private.tmp && chmod 0644 $H/check-private.tmp"
   docker exec -u git "$C" sha256sum $H/check-private.tmp
   ```

   Attendu : l'empreinte de `scripts/gitea/pre-receive-check-private` au commit installé. Sinon, supprimer `check-private.tmp` et s'arrêter.

4. **Activation, en dernier** :

   ```bash
   docker exec -u git "$C" sh -c "mv $H/check-private.tmp $H/check-private && chmod 0755 $H/check-private"
   docker exec -u git "$C" ls -l $D $H
   ```

   Attendu : `check-private.sh` et `forbidden-patterns.txt` en `-rw-------`, propriétaire `git` ; `check-private` en `-rwxr-xr-x`, à côté du hook `gitea`.

5. **Seul le dépôt du site a le hook**, sans lister de nom de dépôt :

   ```bash
   docker exec -u git "$C" sh -c 'n=0; for f in /data/git/repositories/*/*.git/hooks/pre-receive.d/check-private; do [ -e "$f" ] && n=$((n+1)); done; echo "dépôts avec check-private : $n"'
   ```

   Attendu : `dépôts avec check-private : 1`.

## Essayer

Chaque essai note son résultat (refusé ou admis) dans le fichier de la story 1.2, avec la date, la version de Gitea et la variante de l'image, sans nom d'hôte ni chemin de la machine hôte.

L'agent pousse depuis un **clone jetable hors du dépôt de travail**, dont le hook local est désactivé dans ce seul clone (`git config core.hooksPath /dev/null`) : le garde-fou local refuserait sinon les commits interdits avant qu'ils atteignent la forge. Le contenu est factice, chaque essai part du même commit de `dev`, et les branches admises sont supprimées ensuite.

1. **Chemins interdits** : un push par fichier ajouté sous `docs/private/`, sous `docs/context/`, un `.env`, un PDF sous `assets/cv/`. Attendu : chaque push refusé, le message nomme le commit et le chemin.
2. **Motif factice** : Arnaud ajoute à la liste du serveur une ligne factice qu'il communique à l'agent (jamais un motif réel) ; l'agent pousse un fichier qui la contient. Attendu : refusé, sans le motif dans le message. Arnaud retire la ligne.
3. **Push propre** : un fichier sans contenu privé. Attendu : admis ; l'agent supprime la branche.
4. **Liste inaccessible** : Arnaud renomme temporairement la liste (`docker exec -u git <conteneur> mv $D/forbidden-patterns.txt $D/forbidden-patterns.txt.essai`) ; l'agent refait un push propre. Attendu : refusé. Arnaud rétablit la liste ; le même push est alors admis.
5. **Fusion depuis l'interface** : l'agent pousse une branche propre qui contient une ligne factice, et ouvre une PR vers `dev`. Arnaud ajoute cette ligne à la liste, puis tente la fusion depuis l'interface. Attendu : fusion refusée, preuve que la fusion passe par le hook. Arnaud retire la ligne ; l'agent ferme la PR et supprime la branche.
6. **Recréation du conteneur** : Arnaud recrée le conteneur Gitea (par exemple `docker compose up -d --force-recreate` dans son dossier de composition) ; l'agent refait l'essai 1 pour `docs/private/`. Attendu : refusé.
7. **Édition des hooks** : Arnaud ouvre les réglages du dépôt dans l'interface. Attendu : aucune page d'édition des hooks.
8. **Dépôt privé** : Arnaud vérifie que le dossier `hooks/pre-receive.d/` du dépôt nu privé ne contient que le hook `gitea`.

## Entretenir

- **À chaque modification de `scripts/check-private.sh` ou de `scripts/gitea/pre-receive-check-private`** fusionnée dans `dev` : réextraire le fichier au nouveau commit (étapes 2 ou 3 et 4 d'« Installer », avec vérification d'empreinte), puis refaire les essais 1 et 3.
- **À chaque modification de la liste des motifs**, poussée sur `main` du dépôt privé : réextraire la liste (étape 2, deuxième commande), puis refaire l'essai 3. Tant que ce n'est pas fait, le serveur applique l'ancienne liste.
- **À chaque mise à jour de Gitea ou régénération des hooks** : vérifier que `check-private` est toujours dans `hooks/pre-receive.d/`, puis refaire les essais 1 et 3. La régénération réécrit `pre-receive` et `pre-receive.d/gitea` sans supprimer les autres fichiers du dossier.

## Ce que le hook refuse

Quatre surfaces, depuis la story 1.5 : le contenu des fichiers, leur chemin, le chemin confronté aux motifs, et le **message des commits** (tous les commits nouveaux de la plage poussée, pas seulement la tête). Deux interdictions de chemin sont temporaires et tombent quand leur contrôle entrera dans le hook : `assets/cv/*.pdf` (C21) et les extensions d'images (C20, story 5.4), avec deux exceptions nommées, `.env.example` et `design/<branche>/screenshots/`. Aucune alerte n'affiche le motif, le contenu trouvé, le chemin fautif d'un motif ni le message de commit.

## En cas d'échec

- **Un push propre est refusé avec « GITEA_CUSTOM non définie »** : Gitea ne transmet pas cette variable au hook dans cette installation. S'arrêter et décider avec Arnaud d'un autre moyen de trouver le dossier ; ne jamais écrire de chemin du serveur dans le dépôt.
- **« script du garde-fou absent ou illisible » ou « liste des motifs absente ou illisible »** : vérifier les copies, le propriétaire `git` et les droits (`docker exec -u git <conteneur> ls -l …`).
- **Un push interdit est admis** : le hook ne s'exécute pas. Retirer tout de suite la branche admise de la forge, ne pas activer le miroir, et vérifier que `check-private` est exécutable et appartient à `git`.
- **La fusion depuis l'interface est admise malgré le motif factice** : la story s'arrête et Arnaud décide ; le miroir reste désactivé.
