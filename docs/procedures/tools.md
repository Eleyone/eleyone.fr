# Procédure — Outils épinglés

Hugo, D2 et les outils de contrôle doivent avoir la **même version** sur le poste, dans les deux CI et dans l'image du site (AD-1, NFR-7, NFR-8) : sans cela, un rendu ou un contrôle diffère d'un environnement à l'autre, et la comparaison octet par octet des SVG n'a plus de sens.

## Où vivent les versions

`tools.env`, à la racine, est la **seule** déclaration : versions, adresses d'archive, empreintes sha256, image de contrôle épinglée par digest, listes de paquets. Aucun script, aucun workflow, aucun `Dockerfile` ne réécrit une version ou une empreinte ; ils lisent tous ce fichier.

Les paquets sont déclarés en trois temps, parce qu'`alpine:3.24` n'a ni `bash`, ni `curl`, ni certificats :

| Variable | Contenu | Qui l'installe |
| --- | --- | --- |
| `CHECK_BOOTSTRAP_PACKAGES` | `bash` | `scripts/ci/install-tools-bootstrap.sh`, en sh POSIX |
| `CHECK_BASE_PACKAGES` | `curl`, `ca-certificates`, `su-exec` | `scripts/ci/install-tools.sh`, avant tout téléchargement |
| `CHECK_PACKAGES` | `git`, `grep` et `findutils` GNU, `jq`, `libxml2-utils`, `poppler-utils` | le même, dans le même `apk` |

Leur réunion est la liste des outils de contrôle d'AD-1, plus les prérequis du job : le téléchargement (`curl`, `ca-certificates`) et la bascule du conteneur vers le compte de l'appelant (`su-exec`, `checks-job.md`).

## Installer

- **Sur le poste** : `scripts/ci/install-tools.sh --local` télécharge Hugo et D2, vérifie leur empreinte et les installe dans `.tools/`, que `.gitignore` exclut. **Aucun paquet système n'est installé** : le poste n'a pas `apk`.
- **Dans l'image de contrôle et à l'étape `tools` du `Dockerfile`** : `scripts/ci/install-tools-bootstrap.sh`. Il pose `bash` puis passe la main à `install-tools.sh`, qui installe les paquets, puis Hugo et D2 dans `/usr/local/bin`.

Dans les deux cas, le script **échoue** si une empreinte ne correspond pas (code 1, rien n'est installé) ou si `tools.env` manque une variable (code 2). Un binaire déjà présent dont l'empreinte a changé est **remplacé sans rien demander** : `.tools/` est un cache, et une montée de version doit se faire en modifiant `tools.env` seul.

## Vérifier une version à l'exécution

`scripts/lib/tools.sh` porte la vérification commune :

```bash
script_name=mon-script
. scripts/lib/tools.sh
load_tools_env tools.env
require_tool_version hugo .tools/hugo "$HUGO_VERSION"
```

`require_tool_version` échoue en nommant l'outil, la version attendue et la version trouvée : un `hugo` d'une autre version dans le `PATH` est refusé au lieu de produire un rendu qui diverge en silence.

## Monter une version

1. Relever la nouvelle version et l'empreinte de l'archive `linux-amd64` **depuis le fichier de sommes publié par le projet** (`hugo_<version>_checksums.txt`, `SHA256SUMS` pour D2), et la recalculer sur l'archive téléchargée : les deux doivent coïncider.
2. Modifier `tools.env`, et lui seul : version, nom d'archive, adresse, empreinte.
3. `scripts/ci/install-tools.sh --local`, puis vérifier que les deux binaires annoncent la nouvelle version.
4. Pour l'image de contrôle, relever le nouveau digest (`docker inspect --format '{{index .RepoDigests 0}}' alpine:3.24`) et le porter dans `CHECK_IMAGE`.
5. Rejouer `scripts/tests/run.sh`, puis la CI : c'est elle qui prouve que les trois environnements sont alignés.

## Tests hors ligne

`scripts/tests/test-tools.sh` ne touche pas au réseau : il fabrique des archives factices et les sert depuis un dossier local. Trois variables, réservées aux tests, ne sont jamais employées par la CI :

| Variable | Effet |
| --- | --- |
| `TOOLS_ENV_FILE` | lit un autre `tools.env` |
| `TOOLS_BASE_URL` | remplace l'adresse de téléchargement (par exemple `file:///…`) |
| `TOOLS_LOCAL_DIR`, `TOOLS_TARGET_DIR` | changent le dossier d'installation |

## Pièges déjà rencontrés

- **`--cleanDestinationDir` ne nettoie pas** (Hugo 0.166) : une page d'un build précédent survit dans `public/`. `scripts/build.sh` vide donc lui-même sa destination avant d'appeler Hugo. Une page retirée du site resterait servie sans cela, et le contrôle des pages publiées passerait sur une sortie sale.

- **`alpine:3.24` n'a pas `bash`** : d'où l'amorçage en sh POSIX. Appeler `install-tools.sh` directement dans l'image donne `env: can't execute 'bash'`.
- **`sha256sum` de BusyBox** ne connaît ni `--status` ni le format long de GNU : l'empreinte est donc calculée puis comparée par le script lui-même, ce qui marche des deux côtés. Une empreinte n'est pas un secret, elle peut être affichée.
- **`curl` est absent d'`alpine:3.24`** : les paquets s'installent avant tout téléchargement, jamais après.
- **Le `find` de BusyBox ignore `-printf`** (story 3.12) : `scripts/tests/run.sh` s'en sert pour relever l'état de `public/` et de `build/`, et la suite échouait dans l'image avec l'aide de `find`. D'où `findutils` dans `CHECK_PACKAGES`, comme `grep` GNU : le poste et l'image se comportent pareil.
- **`xmllint` ne rend pas le même code pour « aucun nœud »** selon la version de libxml2 (story 3.12) : 10 en 2.9 (le poste), 11 en 2.13 (l'image), qui garde 10 pour une requête mal écrite. `checks_xpath` tolère les deux ; un fichier illisible rend 1 des deux côtés.
