# Story 5.4 : Photo preparation and image check

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 5.4.

## Revue de spec

### 21/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `05132d1`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ee4db2c8c7e901dacd06ecca

##### Revue de la spec (Story 5.4)

###### Lentille : Adversarial (Critique et cas limites)
* **Emplacement :** Critères d'acceptation, blocs 3 et 4 vs liste de vérification
  * **Déclencheur :** Contradiction majeure sur l'outillage. La spec exige que `C20` vérifie les dimensions exactes des images (640×800, 120×150, etc.) et relève la présence de métadonnées (Exif, XMP, bloc VP8X). Elle indique qu'un "outil de lecture [...] est présent dans l'environnement où tourne Gitea", mais la liste de vérification exige qu'"Aucun autre outil d'image n'est ajouté".
  * **Correction suggérée :** Clarifier l'outillage. Soit on ajoute un outil léger (`exiftool`, `imagemagick`, ou `file` s'il est assez complet) dans `tools.env` (pour `CHECK_IMAGE`) et sur le serveur Gitea, soit la vérification se fait en pur `bash`/`grep`/`hexdump`, ce qui est très fragile pour lire les dimensions d'un WebP.
  * **Conséquence potentielle :** Impossibilité technique de vérifier la largeur/hauteur et le poids par des scripts bash natifs sans outil dédié, menant à un contrôle `C20` aveugle ou instable.

* **Emplacement :** Critères d'acceptation, bloc 1 (`prepare.sh`)
  * **Déclencheur :** Dépendance implicite au binaire Hugo local.
  * **Correction suggérée :** Préciser que `prepare.sh` doit impérativement cibler le binaire `.tools/hugo` généré par `install-tools.sh --local` (AD-1), et non s'appuyer sur une version globale du système.
  * **Conséquence potentielle :** L'utilisation d'une version non épinglée de Hugo pour `.Process` pourrait produire une image différente de l'attendu, violant AD-1.

* **Emplacement :** Prérequis de contenu & Questions à poser
  * **Déclencheur :** Le contrôle `C20` nécessite une image porteuse de métadonnées pour prouver qu'il échoue. Si aucune image n'est commitée sous `tests/fixtures/`, les tests unitaires automatisés de `scripts/tests/` ne pourront pas valider `C20`.
  * **Correction suggérée :** Répondre à la question de la spec : autoriser explicitement une image de test minimaliste (ex: 1x1 pixel avec de fausses métadonnées injectées) commitée spécifiquement dans `tests/fixtures/` pour le harnais de test, puisqu'elle n'est pas traitée par le cycle de build du site.
  * **Conséquence potentielle :** Le contrôle `C20` manquera de couverture de test dans la CI.

###### Lentille : Structure
* **Emplacement :** Critères d'acceptation, bloc 4 (Hook `pre-receive`)
  * **Déclencheur :** La spec mentionne que l'interdiction temporaire des extensions d'images est levée dans la procédure du hook (étape 7), mais oublie la configuration locale.
  * **Correction suggérée :** Préciser que `scripts/check-private.sh` (le script du garde-fou local utilisé en `pre-commit` et en CI) doit également être mis à jour pour lever cette interdiction.
  * **Conséquence potentielle :** Le hook serveur acceptera la publication de la photo, mais le développeur sera bloqué localement au moment du commit par le garde-fou.

###### Lentille : Prose (Clarté et expression)
* **Emplacement :** Critères d'acceptation, bloc 3 (`C20`)
  * **Déclencheur :** Formulation trop large : "une image de `assets/images/` ou de `public/`..."
  * **Correction suggérée :** Préciser la portée exacte. Le contrôle s'applique-t-il uniquement aux fichiers `.webp` de portrait, ou va-t-il scanner les `.svg` de `assets/diagrams/` ?
  * **Conséquence potentielle :** `C20` pourrait chercher des dimensions ou des blocs `VP8X` dans des images vectorielles, causant de faux positifs.

---

##### À trancher avant d'implémenter

- **Outillage d'image :** Comment `C20` peut-il vérifier précisément les dimensions (640×800) et les métadonnées de l'image si la règle "Aucun autre outil d'image n'est ajouté" est maintenue ? Es-tu d'accord pour ajouter un outil standard (ex: `exiftool` ou `imagemagick`) à `tools.env` et au serveur Gitea, ou exiges-tu une lecture des octets en pur shell (plus risquée) ?
- **Image de test pour la CI :** Pour que les tests automatisés de `C20` prouvent son efficacité, es-tu d'accord pour commiter une image factice porteuse de faux EXIF uniquement dans `tests/fixtures/` (exclue du site) ?
- **Garde-fou local :** Confirme-t-on que la levée de l'interdiction des extensions d'images doit bien être répercutée dans le script `scripts/check-private.sh` pour débloquer les commits locaux, en plus du hook serveur ?

### Tri des constats — 21/09/2026

| Constat | Décision | Raison |
|---|---|---|
| Ajouter `exiftool` ou ImageMagick à `tools.env` et au serveur Gitea, la lecture d'octets étant « plus risquée » | **rejeté, sur démonstration** | AD-19 interdit un second outil d'image, et un outil de plus à installer là où tourne Gitea est une charge de plus. La démonstration du 21/09/2026 montre l'inverse du risque annoncé : `grep -a` détecte `EXIF`, `XMP` et `VP8X`, `od` lit les dimensions (640 × 800 relu correctement sur la sortie de Hugo). La lecture ne décode aucune image ; elle lit un en-tête de 30 octets et des identifiants de chunk en ASCII. |
| Commiter une image factice porteuse de faux EXIF sous `tests/fixtures/` | **rejeté** | Elle serait refusée par C20 lui-même et par le hook. Et une image sans métadonnée ne démontrerait rien — ce que la question de la story pressentait. Les octets sont fabriqués dans le cas de test, sans Python ni PIL, qui ne sont pas des dépendances déclarées de la suite. |
| Répercuter la levée de l'interdiction dans `scripts/check-private.sh` | **retenu** | Sans cela, aucune image ne pourrait être commitée, et la story n'aurait servi à rien. Périmètre arbitré par Arnaud ci-dessous. |

### Décision d'Arnaud — 21/09/2026

**L'interdiction des extensions d'images est levée sous `assets/`**, et tient partout ailleurs.

La raison de ne pas tout ouvrir : C20 sait dire qu'une image ne porte pas de données de prise de vue, **pas ce qu'elle montre**. Une capture d'écran exposant une information privée passerait le contrôle. Le périmètre étroit est ce qui borne ce risque.

## Mise en œuvre

### Le spike d'AD-19, rejoué et confirmé

Une image d'essai a été fabriquée hors dépôt avec un vrai IFD GPS (48°51′N, 2°21′E) et des champs d'appareil. Après `.Process "crop 640x800 Top webp q80"` par le Hugo épinglé : `RIFF…WEBP` + `VP8 ` simple, 640 × 800, 12 236 octets, et **zéro occurrence** d'`Exif`, `XMP`, `VP8X` ou du nom de l'appareil.

### Une correction à AD-19 : `GPS` n'est pas un marqueur

L'image d'origine porte de vraies coordonnées et **ne contient pas une seule fois la chaîne « GPS »** : les coordonnées vivent en binaire dans l'IFD EXIF. Chercher « GPS » dans les octets, comme AD-19 le suggérait, n'aurait jamais rien trouvé — un contrôle vert sur une image porteuse de GPS.

La règle juste est « aucun EXIF, aucun XMP, aucun conteneur étendu » : sans eux, pas de GPS possible. AD-19 porte la correction.

### Aucun outil, et une bibliothèque partagée

`scripts/lib/image.sh` lit les métadonnées (`grep -a` sur les identifiants de chunk) et les dimensions d'un WebP (`od` sur l'en-tête VP8 ou VP8L). Elle est **sans dépendance**, parce qu'elle est copiée sur la forge : le hook `pre-receive` porte C20, donc le refus arrive avant que le miroir ne publie.

Elle vit sous `scripts/lib/` et la forge la reçoit sous `lib/` à côté de `check-private.sh` : **le même chemin relatif des deux côtés**, pour que le script n'ait pas à deviner où il tourne. Le lanceur du hook vérifie sa présence et refuse le push en la nommant — un garde-fou qui s'ignore en silence ne garde rien.

C'est aussi ce qui évite la duplication que la rétrospective de l'epic 3 a coûtée au projet : une seule écriture de la règle, pour C20 en CI et pour le hook.

### Vérification de comportement

| Ce qui est exercé | Observé |
|---|---|
| `prepare.sh <original> Top` | `assets/images/portrait.webp`, 640 × 800, 12 236 o, aucune métadonnée |
| `prepare.sh <original> Smart` | refusé, code 1, avec la liste des ancrages admis |
| `prepare.sh <original>` | refusé, code 2, usage affiché |
| `portrait.html` en `home` | 120 × 150 (1 936 o) et 240 × 300 (3 320 o), empreintées, `srcset` 1x/2x, `width`/`height` de la 1x |
| `portrait.html` en `about` | 160 × 200 (2 886 o) et 320 × 400 (5 968 o) |
| C20 sur une image porteuse de métadonnées | refusé, marqueurs nommés (`Exif EXIF VP8X`) |
| C20 sur une variante hors dimensions | refusé, variantes attendues listées |
| Hook `pre-receive`, image sans métadonnée sous `assets/` | **admis** |
| Hook `pre-receive`, la même avec métadonnées | **refusé**, C20 nommé, fichier nommé |
| Hook `pre-receive`, image hors `assets/` | refusé par son chemin |

Aucune image n'est commitée : le `portrait.webp` de la démonstration est mon dégradé d'essai, retiré avant le commit. Le branchement du partial sur l'accueil appartient à la story 5.5.

### Trois pièges rencontrés

- **Hugo reconnaît le format par l'extension.** Copier l'original sous `source` sans point le fait échouer en « format non pris en charge », message qui n'oriente vers rien.
- **`.Fingerprint` n'existe pas sur une ressource image** : l'empreinte se pose par le tube `| fingerprint`.
- **Une variable shell ne peut pas contenir un blob binaire** : le premier octet nul la tronque, et l'image paraîtrait vide, donc propre. Le garde-fou écrit le blob dans un fichier temporaire avant de le lire. C'est le genre d'erreur qui aurait donné un contrôle vert sur toutes les images.

### Cas de test

`scripts/tests/test-images.sh`, 6 cas, tous sur des octets fabriqués : lecture des dimensions jusqu'à la borne des 14 bits, détection des marqueurs WebP, PNG et JPEG, refus de mesurer un conteneur étendu, et les trois règles de C20. Deux cas ajoutés au hook (image admise sous `assets/`, refusée avec métadonnées, refusée hors `assets/`) et un à son installation (bibliothèque absente).

## Revue du code

### 21/09/2026 — `34c1d6e` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 69. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 46438547e019d8ab41263978

##### Revue BMAD

###### Lentille : Edge-case-hunter

* **Emplacement :** `scripts/checks/images.sh`, lignes 92-94 (filtrage des variantes)
  * **Déclencheur :** La condition de boucle `[[ $(basename "$fichier") == "$base"* ]]` avec `$base="portrait"` associe à la photo originale toute image de `public/` dont le nom commence par "portrait" (ex: `portrait-equipe.webp` ou `portrait-client.png`).
  * **Correction suggérée :** Renforcer le motif de nommage pour qu'il corresponde précisément au format d'empreinte généré par Hugo. Par exemple : `[[ $(basename "$fichier") == "${base}_"* ]]`.
  * **Conséquence potentielle :** Refus abusif (faux positif) bloquant C20 sur des images légitimes ajoutées plus tard qui ne partagent pas les dimensions strictes imposées aux variantes du portrait.
  * **Classement : NON BLOQUANT**

* **Emplacement :** `scripts/photo/prepare.sh`, ligne 151
  * **Déclencheur :** Le pipeline `find "$travail/public" -type f -name '*.webp' | head -1` s'exécute sous le régime `set -euo pipefail`. Bien que Hugo ne génère qu'une seule image dans ce mini-projet, si `find` venait à retourner plusieurs fichiers, `head -1` fermerait prématurément le flux de lecture. `find` recevrait alors un `SIGPIPE` et échouerait, provoquant un arrêt brutal du pipeline (code d'erreur 141).
  * **Correction suggérée :** Préférer l'utilisation des arguments de GNU find pour s'arrêter proprement : `find "$travail/public" -type f -name '*.webp' -print -quit`.
  * **Conséquence potentielle :** Le script planterait avec un code de sortie obscur (141) au lieu de signaler l'erreur de manière explicite et gracieuse.
  * **Classement : NON BLOQUANT**

###### Lentille : Verification-gap

* **Emplacement :** `scripts/lib/image.sh`, fonction `image_webp_dimensions` (lignes 41-49)
  * **Déclencheur :** Si un fichier WebP est valablement entêté mais prématurément tronqué (moins de 30 octets), l'appel `od` de lecture lira un nombre insuffisant d'octets. La commande `set -- $octets` définira alors moins de 4 paramètres.
  * **Correction suggérée :** Ajouter une vérification stricte du nombre d'arguments obtenus (`(($# >= 4)) || return 2`) avant d'évaluer l'expression arithmétique `mot=$(( ... ))`.
  * **Conséquence potentielle :** En raison du `set -u` actif sur tout le projet, l'accès à la variable `$4` non définie provoque un crash du shell pour variable non liée. Bien que cet arrêt brutal soit rattrapé sans dommage parce que la fonction est appelée dans un sous-shell (`dims=$(image_webp_dimensions ...)`), il s'agit d'un manque de vérification des bornes de l'entrée.
  * **Classement : NON BLOQUANT**

##### Couche propre au projet

* **Emplacement :** Critères d'acceptation de la story et architecture
  * **Déclencheur :** L'intégration de `C20` sans l'ajout d'un outil d'image tiers (ImageMagick, exiftool) respecte scrupuleusement la contrainte stricte d'AD-19. La détection manuelle des marqueurs binaires par `grep -a` et `od` est juste, bien intégrée et validée par la suite exhaustive de `test-images.sh`. L'ensemble des exigences du cahier des charges (tailles, poids maximal, variantes) est pleinement testé et satisfait.
  * **Correction suggérée :** N/A
  * **Conséquence potentielle :** Succès de l'implémentation, tout en respectant l'architecture de frugalité technologique demandée sur les serveurs Gitea.
  * **Classement : NON BLOQUANT**

* **Emplacement :** Données privées et secrets
  * **Déclencheur :** Le diff ne contient aucun secret, aucune adresse de serveur et aucun nom d'hôte. La mécanique qui s'assure que l'image `portrait.webp` originelle (avec ses métadonnées GPS et EXIF potentielles) ne rentre jamais dans le dépôt est correctement verrouillée par la résolution des chemins canoniques dans `prepare.sh`.
  * **Correction suggérée :** N/A
  * **Conséquence potentielle :** Aucune fuite d'information sensible n'est possible ; le garde-fou remplit parfaitement son rôle avant publication.
  * **Classement : NON BLOQUANT**

* **Emplacement :** Concordance script, skill et procédure
  * **Déclencheur :** Les procédures et les scripts concordent à la lettre. `docs/procedures/photo.md` énonce précisément les ancrages disponibles et les commandes contrôlées par `scripts/photo/prepare.sh`. La mise à jour de `docs/procedures/gitea-pre-receive-hook.md` garantit la présence de `lib/image.sh` qui est correctement sourcée par le garde-fou du hook.
  * **Correction suggérée :** N/A
  * **Conséquence potentielle :** Les étapes décrites pour les développeurs et l'automatisation sont alignées, rendant les futures maintenances prévisibles.
  * **Classement : NON BLOQUANT**

* **Emplacement :** Gestion des erreurs (`set -euo pipefail`)
  * **Déclencheur :** Les scripts manipulent habilement le `pipefail` et les erreurs de commandes chaînées. Les retours inattendus de `grep` (code 2) ou de `od` sont systématiquement attrapés via les disjonctions `|| code=$?` et évalués sans masquer silencieusement l'échec d'un appel critique.
  * **Correction suggérée :** N/A
  * **Conséquence potentielle :** Résilience des scripts, évitant les faux-positifs verts en CI.
  * **Classement : NON BLOQUANT**

VERDICT: NON BLOQUANT — aucune réserve majeure, quelques cas limites mineurs identifiés pour consolider la fiabilité des vérifications.

#### Décisions sur les trois constats — 21/09/2026

Les trois sont non bloquants, justes, et coûtaient peu. Tous **retenus**.

| Constat | Correctif |
|---|---|
| Le préfixe `portrait*` attraperait un futur `portrait-equipe.webp` et le jugerait sur les dimensions du portrait | `portrait_hu_`, la forme exacte que Hugo donne à une ressource transformée. Un cas de test vérifie qu'une autre image passe et qu'une vraie variante est bien jugée. |
| `find … \| head -1` sous `pipefail` : SIGPIPE, code 141 qui n'explique rien | `-print -quit`. |
| Un WebP tronqué laisse `$4` indéfini, et `set -u` arrête le shell | Borne `(($# >= 4))` avant l'arithmétique, et un cas de test sur un fichier coupé. |

Le troisième a montré plus que ce que le relecteur décrivait : une lecture `od` au-delà de la fin du fichier rendait **2**, code « anomalie », alors qu'un fichier coupé n'est pas une panne mais une image invalide. Les lectures de dimensions rendent désormais **1**, et le 2 reste pour ce qui est réellement illisible. Sans quoi un fichier tronqué aurait arrêté tout `check.sh` au lieu d'être refusé.

### 21/09/2026 — `4d23914` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 69. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1974bb44bd18cff6cebc0264

##### Revue de la spec (Story 5.4)

###### Lentille : Edge-case-hunter (Critique et cas limites)
* **Emplacement :** `scripts/check-private.sh`, fonction `check_images`
  * **Déclencheur :** Si le nom d'une image légitime dans `assets/` contient un espace ou un caractère spécial (ex: `assets/images/ma photo.webp`), la commande `git ls-files` ou `git ls-tree` entourera son chemin de guillemets (comportement Git par défaut via `core.quotePath`).
  * **Correction suggérée :** Utiliser l'option `-z` de Git ou traiter les guillemets lors de la lecture du flux.
  * **Conséquence potentielle :** L'appel `git cat-file blob "$rev:$chemin"` cherchera le fichier avec les guillemets inclus littéralement. Cette recherche échouera, le garde-fou bloquera alors le commit en affichant l'erreur `lecture impossible d'une image de ...`.
  * **Classement : NON BLOQUANT** (Génère un faux positif de refus, mais ne crée aucune faille ni fuite de donnée).

###### Lentille : Verification-gap (Failles de vérification)
* **Emplacement :** `scripts/lib/image.sh`, fonction `image_metadata_markers`
* **Déclencheur :** La détection avec `grep -aqF` scanne la totalité des octets de chaque image (le fichier binaire entier y compris la partie compressée), contrairement à ce que laisse entendre l'une des remarques des décisions précédentes suggérant que seul un en-tête de 30 octets est lu.
* **Correction suggérée :** Limiter la portée de `grep` au début du fichier (ex: via un `head -c`) si les métadonnées sont assurément au début de fichier, ou assumer la stratégie de robustesse actuelle au prix d'un risque infime.
* **Conséquence potentielle :** Il existe une probabilité infinitésimale (mathématiquement très rare mais non nulle) que la suite d'octets de l'un des marqueurs (`Exif`, `VP8X`, etc.) se retrouve aléatoirement formée au milieu des pixels de l'image. Cela provoquerait un rejet erroné d'une image pourtant vierge de toute métadonnée.
* **Classement : NON BLOQUANT** (Excès de zèle infime qui garantit qu'aucune métadonnée ne fuite).

##### Couche propre au projet

* **Critères d'acceptation :**
  * **Déclencheur :** L'implémentation répond point par point à la spec. C20 vérifie efficacement les dimensions, les poids (copie et variantes) et rejette la présence de métadonnées de manière native sans outil tiers. Le hook `pre-receive` est à jour pour appliquer C20 avec succès.
  * **Classement : NON BLOQUANT**

* **Données privées, secrets et hôtes :**
  * **Déclencheur :** Aucune fuite constatée. `prepare.sh` recourt astucieusement à l'URL factice `https://exemple.invalid/` pour la génération, l'image originale reste sagement exclue du dépôt, et aucune variable ou adresse de la forge locale Gitea n'est exposée en dur.
  * **Classement : NON BLOQUANT**

* **Concordance skill, procédure et script :**
  * **Déclencheur :** Les procédures `docs/procedures/photo.md` et `docs/procedures/gitea-pre-receive-hook.md` décrivent avec fidélité les implémentations trouvées dans `prepare.sh` et `pre-receive-check-private`. L'empaquetage de `lib/image.sh` vers le hook est scrupuleusement documenté et testé.
  * **Classement : NON BLOQUANT**

* **Cohérence avec AGENTS.md et architecture :**
  * **Déclencheur :** Respect rigoureux de `ARCHITECTURE-SPINE.md` (AD-19, AD-12). La consigne stricte de n'employer aucun outil image (tel que Python, ImageMagick ou Exiftool) est adroitement contournée et honorée via l'utilisation détournée de `od`, `grep`, et le binaire statique Hugo local.
  * **Classement : NON BLOQUANT**

* **Gestion des erreurs (set -euo pipefail) :**
  * **Déclencheur :** Excellente résilience. La revue confirme le traitement correct de l'erreur 141 (remplacement de `head -1` par `-quit`). Les erreurs des utilitaires comme `grep` (non match ou anomalie) et `od` (fichier tronqué) sont interceptées sans faille via `|| code=$?` et `|| return 1`, ne permettant aucun passage silencieux sur une erreur critique.
  * **Classement : NON BLOQUANT**

VERDICT: NON BLOQUANT — aucune anomalie sérieuse, seulement deux cas limites rarissimes (espaces dans les noms et collision binaire) qui confortent la rigidité sécuritaire de l'implémentation.

## Reporté
