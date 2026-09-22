# Procédure — Hook pre-receive du garde-fou sur Gitea

La forge principale refuse côté serveur tout push qui contient un chemin ou un motif privé (AD-12). Ce hook est l'autorité du garde-fou : un poste sans hook local ne peut pas le contourner. Cette procédure l'installe sur le dépôt du site, puis l'essaie (story 1.2).

**Rien de ce qui désigne le serveur n'entre dans le dépôt** : ni nom d'hôte, ni chemin de la machine hôte, ni nom de volume. Les chemins ci-dessous sont ceux de l'intérieur du conteneur, fixés par l'image officielle de Gitea. `<conteneur>` est le nom du conteneur Gitea sur la machine hôte.

## Ce qui est installé

| Élément | Emplacement dans le conteneur (image normale) | Propriétaire, droits |
|---|---|---|
| Script du garde-fou, copie de `scripts/check-private.sh` | `/data/gitea/eleyone-check-private/check-private.sh` | `git`, `0600` |
| Liste des motifs, extraite du dépôt nu privé (`main:forbidden-patterns.txt`) | `/data/gitea/eleyone-check-private/forbidden-patterns.txt` | `git`, `0600` |
| Bibliothèque de lecture des PDF, copie de `scripts/lib/pdf.sh` | `/data/gitea/eleyone-check-private/lib/pdf.sh` | `git`, `0600` |
| Script du hook, copie de `scripts/gitea/pre-receive-check-private` | `/data/git/repositories/eleyone/eleyone.fr.git/hooks/pre-receive.d/check-private` | `git`, `0755` |

`/data/gitea` est la valeur de `GITEA_CUSTOM` dans l'image normale. Le script du hook ne connaît que cette variable : il refuse le push si elle manque, si le script du garde-fou ou la liste est absent ou illisible, puis lance `check-private.sh pre-receive` avec `PRIVATE_PATTERNS_FILE`.

Tout est dans le volume de données de Gitea (`/data`) : l'installation survit à la recréation du conteneur. `DISABLE_GIT_HOOKS` reste à `true` : ce réglage ne ferme que l'édition des hooks depuis l'interface web, pas l'exécution d'un hook posé à la main.

Le hook n'est posé que dans le dépôt nu du site. Le dépôt privé n'en a pas et n'est jamais mirroré.

## Prérequis

- Gitea 1.27.3 en conteneur, image normale (`GITEA_CUSTOM=/data/gitea`, utilisateur `git`). Pour l'image rootless, remplacer `/data/gitea` par `/var/lib/gitea/custom` et `/data/git/repositories` par `/var/lib/gitea/git/repositories`.
- **`poppler-utils` dans le conteneur**, depuis la story 7.3 : le garde-fou lit le texte, les métadonnées et le XMP de chaque CV PDF poussé, et sans `pdftotext` ni `pdfinfo` il **refuse le push** plutôt que de laisser passer un PDF non lu. L'image officielle de Gitea ne les porte pas : voir « Image dérivée » ci-dessous.
- Les deux scripts sont extraits du dépôt nu du site, dans le conteneur, à un commit donné dont on vérifie les empreintes sha256 : ni réseau ni identifiant.
- La liste des motifs est extraite du dépôt nu **privé**, dans le conteneur (`main:forbidden-patterns.txt`) : aucune copie de transit sur la machine hôte (décision d'Arnaud, story 1.2). **La liste n'est jamais affichée ni recopiée ailleurs**, ni dans un commit, un journal, un compte rendu ou une conversation. Le chemin du dépôt nu privé est donné par Arnaud à l'opérateur et n'est écrit nulle part dans le dépôt du site.
- Les tests du garde-fou réussissent dans l'image de Gitea (essai de la story 1.2 : `gitea/gitea:1.27.3`, `grep` de BusyBox).

## Image dérivée, pour poppler

L'image officielle de Gitea est sur Alpine et ne porte pas `poppler-utils`. Une image dérivée l'ajoute, sans rien changer d'autre :

```dockerfile
FROM gitea/gitea:1.27.3
RUN apk add --no-cache poppler-utils
```

Elle se construit sur la machine hôte, puis remplace l'image officielle dans la composition. **Elle se reconstruit à chaque montée de version de Gitea** — sans quoi la montée ramènerait l'image officielle, `pdftotext` disparaîtrait, et le hook refuserait tous les pushs de CV. Le refus est voulu : il vaut mieux un push bloqué qu'un PDF non lu.

Vérifier après recréation du conteneur :

```bash
docker exec -u git "$C" sh -c 'command -v pdftotext && command -v pdfinfo'
```

Attendu : les deux chemins. Sinon, l'image en service n'est pas la dérivée.

## Installer

Opérations sur la machine hôte, par Arnaud ou un agent du homelab qui suit les mêmes règles. Le hook généré par Gitea n'exécute un fichier de `pre-receive.d/` que s'il est exécutable : le `chmod 0755` final active le hook, une fois la liste et le script en place et vérifiés. Avant lui, les pushs ne sont pas affectés.

**Corollaire, et il coûte cher si on l'oublie : le répartiteur lance _tout_ fichier exécutable de `pre-receive.d/`, pas seulement celui qui porte le bon nom.** Une sauvegarde du lanceur faite dans ce dossier par `cp -p` y garde son bit d'exécution, et l'ancienne version tournerait **en plus** de la nouvelle à chaque push — deux garde-fous concurrents, dont un périmé qui ignore les bibliothèques ajoutées depuis. Une sauvegarde du lanceur se range donc dans `$D`, jamais dans `$H` ; si elle y est déjà, `chmod 0644` la neutralise sans la perdre. Constaté par l'agent du homelab au déploiement de la story 7.3, sur des consignes de déploiement fautives que j'avais écrites.

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
   docker exec -u git "$C" sh -c "mkdir -p $D/lib && chmod 0700 $D/lib"
   docker exec -u git "$C" sh -c "umask 077 && git -C $R show $COMMIT:scripts/lib/image.sh > $D/lib/image.sh"
   docker exec -u git "$C" sh -c "umask 077 && git -C $R show $COMMIT:scripts/lib/pdf.sh > $D/lib/pdf.sh"
   docker exec -u git "$C" sha256sum $D/check-private.sh $D/lib/image.sh $D/lib/pdf.sh
   docker exec -u git "$C" sh -c "test -r $D/forbidden-patterns.txt && test -s $D/forbidden-patterns.txt && echo 'liste lisible par git, non vide'"
   ```

   Attendu : les empreintes de `scripts/check-private.sh`, `scripts/lib/image.sh` et `scripts/lib/pdf.sh` au commit installé (`git show $COMMIT:<chemin> | sha256sum` sur le poste), puis « liste lisible par git, non vide ». Sinon, s'arrêter sans poser le hook.

   Le `chmod 0700` sur `lib/` est explicite parce qu'un `umask` posé dans la même commande ne s'appliquerait qu'aux créations qui le suivent : `mkdir -p $D/lib && umask 077` laissait le dossier en `0755` alors que l'étape 4 annonçait `drwx------` (constaté par l'agent du homelab au redéploiement du 22/09/2026).

   **Le sous-dossier `lib/` est obligatoire depuis la story 5.4** : `check-private.sh` y charge `image.sh`, qui porte C20, et `pdf.sh` depuis la story 7.3. Le garde-fou refuse de s'exécuter sans elle, et le lanceur refuse le push en la nommant — un contrôle qui s'ignorerait en silence ne garderait rien. Le chemin relatif est le même dans le dépôt et sur la forge, pour que le script n'ait pas à deviner où il tourne.

3. **Hook déposé, encore inactif** :

   ```bash
   docker exec -u git "$C" sh -c "umask 022 && git -C $R show $COMMIT:scripts/gitea/pre-receive-check-private > $H/check-private.tmp && chmod 0644 $H/check-private.tmp"
   docker exec -u git "$C" sha256sum $H/check-private.tmp
   ```

   Attendu : l'empreinte de `scripts/gitea/pre-receive-check-private` au commit installé. Sinon, supprimer `check-private.tmp` et s'arrêter.

4. **Activation, en dernier** :

   ```bash
   docker exec -u git "$C" sh -c "mv $H/check-private.tmp $H/check-private && chmod 0755 $H/check-private"
   docker exec -u git "$C" ls -l $D $D/lib $H
   ```

   Attendu : `check-private.sh` et `forbidden-patterns.txt` en `-rw-------`, propriétaire `git` ; le dossier `lib` en `drwx------`, `lib/image.sh` et `lib/pdf.sh` en `-rw-------` ; `check-private` en `-rwxr-xr-x`, à côté du hook `gitea`.

5. **Seul le dépôt du site a le hook**, sans lister de nom de dépôt :

   ```bash
   docker exec -u git "$C" sh -c 'n=0; for f in /data/git/repositories/*/*.git/hooks/pre-receive.d/check-private; do [ -e "$f" ] && n=$((n+1)); done; echo "dépôts avec check-private : $n"'
   ```

   Attendu : `dépôts avec check-private : 1`.

## Essayer

Chaque essai note son résultat (refusé ou admis) dans le fichier de la story 1.2, avec la date, la version de Gitea et la variante de l'image, sans nom d'hôte ni chemin de la machine hôte.

L'agent pousse depuis un **clone jetable hors du dépôt de travail**, dont le hook local est désactivé dans ce seul clone (`git config core.hooksPath /dev/null`) : le garde-fou local refuserait sinon les commits interdits avant qu'ils atteignent la forge. Le contenu est factice, et les branches admises sont supprimées ensuite.

Trois règles qu'un essai rate sans elles (constatées le 16/09/2026, au redéploiement de la story 1.5) :

- **chaque essai repart du même commit de `dev`** (`git reset --hard origin/dev`). Enchaînés sur une même branche, les commits interdits des essais précédents restent dans la plage poussée : le push « propre » est alors refusé pour le fichier d'un essai antérieur, ce qui ne prouve rien ;
- **`git add -f`** pour fabriquer un commit interdit : `.gitignore` couvre déjà `docs/private/` et `.env`, donc un `git add -A` les ignore et l'essai passe à côté du hook sans rien démontrer ;
- **jamais un motif réel**, y compris dans un message de commit. Le miroir publie à chaque push : si le hook manquait son refus, le motif serait public en quelques secondes et resterait accessible par son SHA. Tous les essais de motif passent par une ligne factice ajoutée à la liste du serveur, puis retirée.

1. **Chemins interdits** : un push par fichier ajouté sous `docs/private/`, sous `docs/context/`, un `.env`, un PDF sous `assets/cv/`. Attendu : chaque push refusé, le message nomme le commit et le chemin.
2. **Motif factice** : Arnaud ajoute à la liste du serveur une ligne factice qu'il communique à l'agent (jamais un motif réel) ; l'agent pousse un fichier qui la contient. Attendu : refusé, sans le motif dans le message. Arnaud retire la ligne.
3. **Push propre** : un fichier sans contenu privé. Attendu : admis ; l'agent supprime la branche.
3 bis. **Motif factice dans un message de commit** (surface ajoutée par la story 1.5) : avec la même ligne factice qu'à l'essai 2, l'agent pousse **deux** commits anodins dont le **premier** porte la ligne factice dans son message — le message de la tête reste anodin, pour prouver que toute la plage poussée est lue. Attendu : refusé, message « message de commit privé dans `<commit>` (message masqué) » suivi d'un numéro de ligne de motif, sans le motif ni le message. Arnaud retire la ligne.
3 ter. **Chemin qui reprend un motif factice** (story 1.5) : un fichier au contenu anodin, placé dans un dossier nommé d'après la ligne factice. Attendu : refusé, **sans le chemin fautif** dans le message — l'afficher reviendrait à afficher le motif.
4. **Liste inaccessible** : Arnaud renomme temporairement la liste (`docker exec -u git <conteneur> mv $D/forbidden-patterns.txt $D/forbidden-patterns.txt.essai`) ; l'agent refait un push propre. Attendu : refusé. Arnaud rétablit la liste ; le même push est alors admis.
5. **Fusion depuis l'interface** : l'agent pousse une branche propre qui contient une ligne factice, et ouvre une PR vers `dev`. Arnaud ajoute cette ligne à la liste, puis tente la fusion depuis l'interface. Attendu : fusion refusée, preuve que la fusion passe par le hook. Arnaud retire la ligne ; l'agent ferme la PR et supprime la branche.
6. **Recréation du conteneur** : Arnaud recrée le conteneur Gitea (par exemple `docker compose up -d --force-recreate` dans son dossier de composition) ; l'agent refait l'essai 1 pour `docs/private/`. Attendu : refusé.
7. **Édition des hooks** : Arnaud ouvre les réglages du dépôt dans l'interface. Attendu : aucune page d'édition des hooks.
8. **Dépôt privé** : Arnaud vérifie que le dossier `hooks/pre-receive.d/` du dépôt nu privé ne contient que le hook `gitea`.

### Essai des CV PDF (story 7.3)

À faire **une fois**, après le déploiement qui apporte `lib/pdf.sh` et la levée de l'interdiction de chemin. Il prouve que le garde-fou lit un PDF là où `git grep -I` ne voit rien.

L'essai est sûr parce que le PDF est **fabriqué** et le motif **factice** : si le refus manquait, ce qui serait publié n'est rien. C'est la seule façon de l'éprouver — tant que le chemin était interdit, un PDF poussé était refusé pour son chemin et l'essai ne prouvait rien de la lecture.

1. Arnaud ajoute une ligne factice à la liste du serveur et la communique.
2. L'agent fabrique deux PDF minimaux, **sans générateur**, et met la ligne factice dans les **métadonnées** de l'un — c'est là qu'un téléphone se cache dans un export, et c'est la moitié que la lecture du seul texte manquerait :

   ```bash
   ecrire_pdf() { # $1 = chemin, $2 = auteur ou rien
     f='BT /F1 12 Tf 20 150 Td (CV) Tj ET'; o=''; i=''
     o="1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
   2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
   3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 300 300]/Contents 4 0 R>>endobj
   4 0 obj<</Length ${#f}>>stream
   $f
   endstream endobj"
     [ -z "${2:-}" ] || { o="$o
   98 0 obj<</Author ($2)>>endobj"; i='/Info 98 0 R'; }
     printf '%%PDF-1.4\n%s\ntrailer<</Root 1 0 R%s/Size 100>>\n%%%%EOF\n' "$o" "$i" > "$1"
   }
   mkdir -p assets/cv
   ecrire_pdf assets/cv/cv-fr.pdf '<ligne factice>'
   ecrire_pdf assets/cv/cv-en.pdf
   ```

3. Il pousse les deux sur une branche jetable. Attendu : **refusé**, message « C21 : contenu privé dans métadonnées d'un PDF de `<commit>` (contenu masqué) : assets/cv/cv-fr.pdf ; motif ligne N », sans le motif.
4. Contre-épreuve, depuis `origin/dev` frais : les deux PDF **sans** motif. Attendu : **admis**, branche supprimée ensuite. Sans elle, un hook qui refuse tout passerait pour un hook qui marche.
5. Un PDF nommé autrement, `assets/cv/cv-ancien.pdf`. Attendu : **refusé pour son chemin** — l'interdiction n'est levée que pour les deux noms d'AD-21.
6. Arnaud retire la ligne factice.

**Si l'essai 3 est admis**, la branche est supprimée de la forge immédiatement, la version précédente du garde-fou est remise — l'interdiction de chemin avec — et l'incident remonte avant toute autre opération.

**Le compte rendu se termine par l'état de la liste**, taille en octets à l'appui : la ligne factice des essais 2, 3 bis, 3 ter et 5 est posée par Arnaud et retirée par Arnaud, donc aucun des deux ne la voit dans son propre bilan et elle reste en place. Elle y est restée après le redéploiement du 22/09/2026. Elle est inoffensive — un motif factice ne refuse que ce qu'on pousse exprès — mais la liste du serveur diverge alors de celle du dépôt privé, et cet écart-là ne se remarque qu'à la prochaine extraction. La retirer sans l'afficher :

```bash
docker exec -u git "$C" sh -c "cd $D && umask 077 && grep -vxF '<ligne factice>' forbidden-patterns.txt > .liste.tmp && test -s .liste.tmp && mv .liste.tmp forbidden-patterns.txt"
docker exec -u git "$C" sh -c "wc -c < $D/forbidden-patterns.txt"
```

Le `test -s` avant le `mv` est là pour qu'une liste vidée par accident ne remplace jamais la vraie : une liste vide refuse tous les pushs, ce qui est bruyant mais sûr, alors qu'une liste perdue ne se retrouve qu'en la réextrayant. Le `wc -c` compte sans afficher, avant et après.

## Entretenir

- **À chaque modification de `scripts/check-private.sh`, de `scripts/lib/image.sh`, de `scripts/lib/pdf.sh` ou de `scripts/gitea/pre-receive-check-private`** fusionnée dans `dev` : réextraire le fichier au nouveau commit (étapes 2 ou 3 et 4 d'« Installer », avec vérification d'empreinte : le sha256 de la copie du serveur doit être celui du fichier dans `dev`), puis refaire les essais 1 et 3, plus l'essai de chaque surface que la modification touche (3 bis pour les messages de commit, 3 ter pour les chemins). Garder l'ancienne copie du script le temps des essais : elle permet de revenir en arrière sans attendre un correctif. **Toutes les sauvegardes vont dans `$D`**, y compris celle du lanceur : voir le corollaire de la section « Installer ». **La supprimer une fois tous les essais verts**, et le dire dans le compte rendu : deux copies laissées le 21/09/2026 étaient encore là le 22, et à la troisième mise à jour plus rien ne dit laquelle est laquelle.
- **À chaque modification de la liste des motifs**, poussée sur `main` du dépôt privé : réextraire la liste (étape 2, deuxième commande), puis refaire l'essai 3. Tant que ce n'est pas fait, le serveur applique l'ancienne liste.
- **À chaque montée de version de Gitea** : reconstruire l'image dérivée (« Image dérivée »), puis vérifier que `pdftotext` et `pdfinfo` répondent dans le conteneur. Sans eux, tout push de CV est refusé.
- **À chaque mise à jour de Gitea ou régénération des hooks** : vérifier que `check-private` est toujours dans `hooks/pre-receive.d/`, puis refaire les essais 1 et 3. La régénération réécrit `pre-receive` et `pre-receive.d/gitea` sans supprimer les autres fichiers du dossier.

## Ce que le hook refuse

Cinq surfaces : le contenu des fichiers, leur chemin, le chemin confronté aux motifs, le **message des commits** (tous les commits nouveaux de la plage poussée, pas seulement la tête), et depuis la story 7.3 le **texte, les métadonnées et le XMP des CV PDF**, que `git grep -I` ne sait pas lire.

**L'interdiction de chemin des CV est levée**, et seulement pour `assets/cv/cv-fr.pdf` et `assets/cv/cv-en.pdf`, les deux noms qu'AD-21 connaît. Tout autre PDF sous `assets/cv/` reste refusé : ce que le hook ne sait pas nommer, il le refuse. **Celle des extensions d'images est levée sous `assets/` depuis la story 5.4** : C20 y lit les métadonnées de chaque image avant publication (AD-19, AD-12). Ailleurs elle tient — C20 sait dire qu'une image ne porte pas de données de prise de vue, pas ce qu'elle montre. **Quatre** exceptions nommées : `.env.example`, `design/<branche>/screenshots/`, les images d'`assets/` et les deux CV PDF ci-dessus. Aucune alerte n'affiche le motif, le contenu trouvé, le chemin fautif d'un motif ni le message de commit.

## En cas d'échec

- **Un push propre est refusé avec « GITEA_CUSTOM non définie »** : Gitea ne transmet pas cette variable au hook dans cette installation. S'arrêter et décider avec Arnaud d'un autre moyen de trouver le dossier ; ne jamais écrire de chemin du serveur dans le dépôt.
- **« bibliothèque de lecture d'images absente ou illisible »** : le sous-dossier `lib/` n'a pas été créé, ou `image.sh` n'a pas été extrait (étape 2). Le refuser est voulu : sans elle, C20 ne s'exécute pas.
- **« bibliothèque de lecture des PDF absente ou illisible »** : même cause, pour `lib/pdf.sh` (story 7.3). Même raison de refuser : sans elle, le texte et les métadonnées d'un CV ne seraient lus par personne, et le miroir publierait dans la seconde.
- **« pdftotext absent » ou « pdfinfo absent » (paquet `poppler-utils`)** : le conteneur tourne sur l'image officielle de Gitea et non sur l'image dérivée. Reconstruire `gitea-poppler:<version>` et recréer le conteneur (section « Image dérivée ») ; c'est le cas qu'une montée de version ramène si on l'oublie.
- **« script du garde-fou absent ou illisible » ou « liste des motifs absente ou illisible »** : vérifier les copies, le propriétaire `git` et les droits (`docker exec -u git <conteneur> ls -l …`).
- **Un push interdit est admis** : le hook ne s'exécute pas. Retirer tout de suite la branche admise de la forge, ne pas activer le miroir, et vérifier que `check-private` est exécutable et appartient à `git`.
- **La fusion depuis l'interface est admise malgré le motif factice** : la story s'arrête et Arnaud décide ; le miroir reste désactivé.
