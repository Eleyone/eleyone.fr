# Story 11.5 : Delivery and release workflow

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.5.

Cinquième story de l'epic 11, dont l'en-tête (point 21) veut la chaîne de mise en ligne
**construite et répétée tôt**. C'est celle qui relie les deux bouts déjà livrés : d'un côté
l'enveloppe qui construit l'image (story 11.3), de l'autre le serveur qui n'accepte que des demandes
précises (story 11.4). Entre les deux, il manquait le transport.

## Ce sur quoi la story s'appuie, déjà livré

- `scripts/release/build-image.sh <tag>` (11.3) : valide le tag, écrit les deux secrets temporaires,
  délègue à `scripts/build-image.sh --release`, nettoie même en cas d'échec. Image `eleyone-site:<tag>`.
- `deploy/remote/deploy-site.sh` (11.4) : lit `SSH_ORIGINAL_COMMAND` ; `deploy <tag>` et
  `rehearse deploy <tag>` lisent l'archive sur l'entrée standard ; `status` affiche les tags en
  service ; trois gardes séparent les canaux.
- `scripts/ci/checks-job.sh` (3.12) : le job de contrôles dans `CHECK_IMAGE`.

## Revue de spec

### 25/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `5d22834`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 84be5edebcecc74fa898bc0c

### Rapport de Revue (REVIEW-SPEC.md)

#### 1. Lentille Structure & Architecture

**Logique d'enchaînement dans le YAML (BLOQUANT)**
- **Localisation** : `Alors il fait le checkout avec fetch-depth: 0 et enchaîne checks-job.sh, build-image.sh et ship.sh.`
- **Condition déclencheur** : La spec exige que le workflow YAML enchaîne plusieurs scripts.
- **Correction / Garde** : L'architecture (ARCHITECTURE-SPINE) stipule qu'un workflow ne contient que l'appel d'un *seul* script. Le YAML ne doit pas contenir cette logique. Il faut demander la création d'un script d'orchestration (ex. : `scripts/ci/release-job.sh`) qui sera appelé par le workflow et qui se chargera de l'enchaînement et de l'arrêt en cas d'erreur.
- **Conséquence potentielle** : Violation des règles architecturales, dispersion de la logique et mauvaise gestion des codes de sortie dans le YAML.

**Absence de critères de test (BLOQUANT)**
- **Localisation** : Ensemble du document.
- **Condition déclencheur** : Les conventions exigent des tests hors ligne, mais la spec n'en demande aucun pour le nouveau script de livraison ni pour le YAML.
- **Correction / Garde** : Exiger la création de `scripts/tests/test-ship.sh` (utilisant le mécanisme du faux binaire `ssh`) et la mise à jour de `scripts/tests/test-workflows.sh` pour valider `release.yaml`.
- **Conséquence potentielle** : Le code livré ne sera pas testé automatiquement, ce qui enfreint la convention de testabilité hors ligne.

#### 2. Lentille Adversarial & Edge Cases

**Nom de l'image manquant pour docker save (BLOQUANT)**
- **Localisation** : `Alors il envoie docker save | gzip par ssh`
- **Condition déclencheur** : La commande `docker save` nécessite explicitement le nom de l'image à exporter.
- **Correction / Garde** : Spécifier explicitement l'image cible : `docker save eleyone-site:<tag> | gzip`.
- **Conséquence potentielle** : La commande échouera, bloquant la livraison.

**Passage des secrets à build-image.sh (BLOQUANT)**
- **Localisation** : Paragraphe sur l'enchaînement des scripts.
- **Condition déclencheur** : `build-image.sh` nécessite les secrets `PRIVATE_PATTERNS` et `HUGO_LEGAL_*`, mais le workflow décrit ne prévoit pas de les injecter.
- **Correction / Garde** : La spec doit exiger que le workflow déclare et passe ces secrets Gitea dans l'environnement d'exécution du script appelant.
- **Conséquence potentielle** : `build-image.sh` s'arrêtera ou produira une image incomplète par manque de ces variables.

**Gestion sécurisée de la connexion SSH (BLOQUANT)**
- **Localisation** : `(vérification stricte de l'empreinte de l'hôte)`
- **Condition déclencheur** : SSH exécuté dans un runner CI nécessite d'être configuré de manière non interactive avec les secrets Gitea.
- **Correction / Garde** : Exiger que `ship.sh` écrive le secret `DEPLOY_SSH_KEY` dans un fichier temporaire (avec droits restreints), écrive `DEPLOY_KNOWN_HOSTS` dans un autre, et qu'il nettoie la clé via `trap`.
- **Conséquence potentielle** : Sans ces préparations de fichiers temporaires, la vérification stricte échouera et l'authentification par clé sera impossible.

**Vérification de l'appartenance du tag (BLOQUANT)**
- **Localisation** : `Quand le tag [...] pointe sur un commit de main, ou [...] pointe sur un commit de dev`
- **Condition déclencheur** : L'environnement CI d'un tag ne fournit pas la branche dont il est issu.
- **Correction / Garde** : Préciser que le script doit vérifier cela techniquement dans l'historique (par exemple avec `git branch -r --contains <tag>`).
- **Conséquence potentielle** : Le développeur ne saura pas comment vérifier la branche, et le critère risque d'autoriser une livraison depuis une mauvaise branche.

**Identité du compte SSH non précisée (BLOQUANT)**
- **Localisation** : `il envoie docker save | gzip par ssh`
- **Condition déclencheur** : Aucun secret `DEPLOY_USER` n'est prévu. La règle NFR-9 interdit de hardcoder un nom de compte.
- **Correction / Garde** : Indiquer explicitement comment l'utilisateur est déterminé (par exemple en précisant que le secret `DEPLOY_HOST` portera la valeur `utilisateur@hôte`).
- **Conséquence potentielle** : Hardcodage de l'utilisateur SSH ou connexion refusée.

#### 3. Lentille Prose & Logique

**Ambiguïté chronologique vs conditionnelle (BLOQUANT)**
- **Localisation** : `Quand le tag est vX.Y.Z, puis vX.Y.Z-rc.N` / `avec deploy <tag>, puis rehearse deploy <tag>`
- **Condition déclencheur** : La formulation suggère un enchaînement séquentiel (l'un *puis* l'autre), alors qu'un workflow s'exécute pour un tag unique qui ne peut être que l'un *ou* l'autre.
- **Correction / Garde** : Séparer clairement la phrase en deux cas mutuellement exclusifs : "Si le tag est vX.Y.Z, la commande SSH cible est `deploy <tag>`" et "Si le tag est vX.Y.Z-rc.N, la commande cible est `rehearse deploy <tag>`".
- **Conséquence potentielle** : Une lecture stricte ferait exécuter les deux commandes à la suite pour le même tag, menant à déployer en production un tag RC ou inversement.

**Inclusion de la commande de confirmation (NON BLOQUANT)**
- **Localisation** : `et confirme par status.`
- **Condition déclencheur** : La rédaction n'est pas complètement claire sur les cas d'application.
- **Correction / Garde** : Lever l'ambiguïté en précisant que `status` est appelé à la fin dans les deux cas (production et répétition).
- **Conséquence potentielle** : Légère incompréhension du développeur qui pourrait omettre le `status` lors d'un `rehearse deploy`.

---

#### À trancher avant d'implémenter

- Le secret `DEPLOY_HOST` contient-il bien l'utilisateur (format `user@host`) pour respecter NFR-9, ou faut-il introduire un secret `DEPLOY_USER` supplémentaire ?
- Faut-il créer un script `scripts/ci/release-job.sh` pour englober les trois appels et respecter la règle interdisant la logique dans les workflows YAML ?

### Triage des constats (point 20 : chacun reçoit sa décision)

| # | Constat | Décision |
| --- | --- | --- |
| S1 | Le YAML ne doit pas enchaîner trois scripts | **Retenu.** L'architecture est explicite : « un workflow ne contient que le déclencheur, le checkout (`fetch-depth: 0`) et l'appel d'un script ». `scripts/ci/release-job.sh` porte l'enchaînement, comme `checks-job.sh` le fait pour les contrôles. Le YAML ne saura rien d'autre que son déclencheur et cet appel. |
| S2 | Aucun test demandé | **Retenu** (point 9) : `scripts/tests/test-ship.sh` et `scripts/tests/test-release-job.sh`, avec un faux `ssh`, un faux `docker` et un faux `git` posés en tête de `PATH` — procédé de `test-build-image.sh:7`, déjà repris par `test-deploy-site.sh`. `scripts/tests/test-workflows.sh` gagne les cas qui jugent `release.yaml`. **Aucun cas ne lance ssh ni Docker.** |
| A1 | `docker save` sans nom d'image | **Retenu**, évident : `docker save eleyone-site:<tag>`. |
| A2 | Les secrets ne sont pas passés à `build-image.sh` | **Retenu.** Le workflow mappe les secrets Gitea en variables d'environnement du seul pas qui lance `release-job.sh` : les huit `HUGO_LEGAL_*`, `PRIVATE_PATTERNS`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_KNOWN_HOSTS`. `scripts/release/build-image.sh` les lit déjà dans l'environnement (story 11.3) : rien à changer de son côté. |
| A3 | SSH : clé et empreintes en fichiers temporaires | **Retenu.** `ship.sh` écrit `DEPLOY_SSH_KEY` et `DEPLOY_KNOWN_HOSTS` dans deux temporaires créés en `umask 077`, et les supprime par un `trap … EXIT` — le montage exact de `scripts/release/build-image.sh`, tableau `temporaires` compris. `ssh` est lancé avec `-o StrictHostKeyChecking=yes`, `-o UserKnownHostsFile=<temporaire>`, `-o IdentitiesOnly=yes` et `-i <temporaire>`. |
| A4 | Comment vérifier qu'un tag appartient à `main` ou à `dev` | **Retenu.** Décision : `git merge-base --is-ancestor <tag> origin/<branche>`, et non `git branch -r --contains`, dont la sortie se lit et se parse. `--is-ancestor` répond par son **code de sortie** : 0 descend, 1 ne descend pas, et tout autre code est une anomalie — les trois se distinguent, ce qu'une liste à filtrer ne permet pas. C'est ce que `fetch-depth: 0` rend possible. |
| A5 | L'identité du compte SSH n'est pas prévue | **Retenu. Décision : `DEPLOY_HOST` porte `utilisateur@hôte`**, et aucun secret `DEPLOY_USER` n'est ajouté. Deux raisons : l'architecture ne liste que trois secrets de déploiement, et un nom de compte séparé n'apporte rien qu'un second secret à tenir à jour. NFR-9 est satisfait dans les deux cas — rien n'entre dans le dépôt —, mais un secret de moins est un oubli de moins. La procédure le dit noir sur blanc, puisque le format n'est pas devinable. |
| P1 | « `vX.Y.Z`, **puis** `vX.Y.Z-rc.N` » se lit comme une séquence | **Retenu, et c'est le plus dangereux des neuf.** Lu à la lettre, un même tag partirait sur les deux canaux — un `-rc` en production, ou l'inverse. Les deux cas sont **exclusifs** : un tag `vX.Y.Z` donne `deploy <tag>`, un tag `vX.Y.Z-rc.N` donne `rehearse deploy <tag>`, jamais les deux. Un cas de test vérifie qu'une livraison n'envoie **qu'une** commande. `deploy-site.sh` refuserait de toute façon le croisement (story 11.4), mais un garde-fou en aval ne dispense pas d'écrire juste en amont. |
| P2 | `status` s'applique-t-il aux deux canaux ? | **Retenu** : `status` est envoyé en fin de livraison dans les deux cas, et sa sortie est affichée — c'est la seule confirmation que le job donne de ce qui tourne réellement. |

### Ce que la story ne fait pas

L'**installation** sur le serveur et la **création des secrets** sur la forge sont la story 11.6, la
seule de l'epic marquée « Opération manuelle : oui ». Cette story-ci écrit le transport et l'éprouve
**hors ligne** : aucun cas ne lance `ssh`, ni `docker`, ni ne touche un serveur.

## Ce qui est livré

| Fichier | Rôle |
| --- | --- |
| `scripts/release/ship.sh` | la livraison : `docker save \| gzip \| ssh`, puis `status`. `--check-env` n'éprouve que l'environnement |
| `scripts/ci/release-job.sh` | l'orchestration : tag, branche, répétition, puis `ship --check-env`, `checks-job`, `build-image`, `ship` |
| `.gitea/workflows/release.yaml` | déclencheur `push` de tags `v*`, checkout épinglé en `fetch-depth: 0`, **un seul** `run` et le mappage des douze secrets |
| `scripts/tests/test-ship.sh` | 32 cas, hors ligne |
| `scripts/tests/test-release-job.sh` | 22 cas, hors ligne |
| `scripts/tests/test-workflows.sh` | 9 cas ajoutés, qui jugent `release.yaml` |
| `docs/procedures/release-workflow.md` | la procédure |

Chaîne du job, dans cet ordre : `ship.sh --check-env` (les trois secrets de déploiement, **avant**
les dix minutes de contrôles), `checks-job.sh`, `build-image.sh <tag>`, `ship.sh <tag>`. Chaque étape
s'annonce avec son libellé **et son script**, et la chaîne s'arrête à la première en échec avec son
code.

### Les choix qui ne découlaient pas directement du triage

- **Le tag n'est pas un argument du YAML.** `release-job.sh` le lit dans `GITHUB_REF`, que Gitea pose
  pour un push de tag. Passer `${{ github.ref_name }}` aurait remis une expression dans le YAML, que
  le constat S1 veut vide de toute logique. Effet de bord utile : un `refs/heads/dev` est refusé par
  le script lui-même, en plus de l'être par le déclencheur.
- **`ship.sh --check-env`.** Sans lui, un `DEPLOY_HOST` manquant se découvrirait après les contrôles
  et la construction, soit tout le job perdu. Recopier les trois noms dans `release-job.sh` aurait
  été la faute du point 19 ; le mode d'éprouve laisse la liste à `ship.sh`, qui la porte seule.
- **`-o BatchMode=yes`**, en plus des quatre options décidées : sans lui, une clé refusée fait
  attendre un mot de passe et le job reste bloqué jusqu'au délai du runner au lieu d'échouer.
- **Trois gardes de forme sur les secrets** que le triage ne nommait pas : `DEPLOY_HOST` qui commence
  par `-` (ssh y lirait une option), `DEPLOY_SSH_KEY` sans `PRIVATE KEY` (la clé publique déposée par
  mégarde, l'erreur la plus plausible de la story 11.6), `DEPLOY_KNOWN_HOSTS` faite de commentaires
  seuls (piège du « fichier présent mais vide », story 0.8). Chacune a son cas.
- **`docker image inspect` avant le pipeline** : une image absente ferait échouer `docker save` une
  fois le canal ouvert, et le serveur recevrait un flux vide.
- **L'ordre de lecture des trois codes du pipeline est celui des causes**, trouvé en relisant le
  fichier entier plutôt que ses hunks (point 8). Un `ssh` qui s'arrête ferme le tube, et
  `docker save` meurt alors d'un SIGPIPE (code 141) : lire l'amont d'abord aurait fait accuser
  l'exportation de l'image là où le transport a lâché. Le canal aval est donc jugé le premier, et le
  message « archive tronquée » ne sort que lorsque `ssh` a rendu 0 — c'est-à-dire dans le seul cas
  où le serveur a vraiment tout lu. Le cas `ship_ssh_en_echec_avec_amont_en_sigpipe` fixe cet ordre.

## Point 19 — les gardes des aînés, une par une

Aînés lus en entier : `scripts/ci/checks-job.sh` (story 3.12) pour `release-job.sh`,
`scripts/release/build-image.sh` (story 11.3) pour `ship.sh`, `.gitea/workflows/checks.yaml` (story
3.13) pour le workflow.

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 1 | Chaque étape s'annonce avant de tourner (`checks-job.sh`) | **Oui, reprise et élargie.** `release-job.sh` annonce ses quatre étapes, et nomme aussi le **script** : « échec de l'étape de construction » envoie chercher dans le journal, « échec de `scripts/release/build-image.sh` » envoie lire le bon fichier. Il annonce en outre ce qu'il a décidé du tag (canal, branche, répétition trouvée ou absente) : ces décisions-là ne laissent aucune autre trace. |
| 2 | Vérifier son environnement avant de commencer — `HOST_UID`/`HOST_GID` numériques | **Oui, transposée.** Ce que `release-job.sh` exige n'est pas un compte mais un **dépôt complet** : `git` présent, un dépôt git sous le pied, le tag et `origin/<branche>` existants. Sans ces trois-là, `merge-base` répondrait 128 et le job conclurait « ce tag ne descend pas de `main` » sur une information qu'il n'a pas. Les messages nomment `fetch-depth: 0`. Côté `ship.sh` : les trois secrets, puis `docker`, `gzip` et `ssh`. |
| 3 | Échouer à la première étape en échec, sans continuer | **Oui, reprise.** `etape()` propage le code tel quel et sort. Trois cas le vérifient, un par étape, en s'assurant que les suivantes n'ont pas tourné. |
| 4 | Tag validé par une expression **ancrée**, avant tout usage (`release/build-image.sh`) | **Oui, reprise à l'identique** — et c'est ici qu'elle porte le plus : ce sont **deux** expressions disjointes, une par canal, et c'est leur disjonction qui rend les canaux exclusifs (constat P1). Treize formes refusées, trois formes justes acceptées (point 11). Les mêmes expressions vivent dans les trois scripts de la chaîne, `deploy-site.sh` compris. |
| 5 | Les refus arrivent **avant** tout effet de bord, et le message le dit | **Oui, reprise.** Tout ce qui précède l'ouverture du canal refuse sans rien écrire ni envoyer ; chaque message finit par « Rien n'a été envoyé ». `refus_sans_rien_envoyer()` le vérifie pour chaque refus : code attendu, aucun `ssh`, aucun `docker save`, aucun temporaire resté. La garde est **remontée d'un cran** par `--check-env`, qui met les refus d'environnement avant les contrôles et la construction. |
| 6 | Tableau `temporaires` + `trap … EXIT`, chaque fichier inscrit juste après sa création ; la variable de chemin ne sert jamais de booléen | **Oui, reprise telle quelle.** Deux temporaires, la clé privée et les empreintes, inscrits juste après `mktemp`, avant d'être remplis. Le nettoyage ne lit que `temporaires`. |
| 7 | **Pas de `exec`** quand un `trap … EXIT` doit tourner | **Oui, et c'est vital ici.** L'aîné y laisserait les valeurs légales ; `ship.sh` y laisserait la **clé privée du compte de déploiement** sur le disque du runner. Deux cas le prouvent par le comportement (aucun reste après un succès, aucun après un échec) et un troisième refuse tout `exec` dans le fichier. |
| 8 | `set +x` en tête, éprouvé sous `bash -x` | **Oui, reprise dans les deux scripts.** Éprouvé en lançant réellement `bash -x` : la trace s'arrête à la deuxième ligne. Un cas le rejoue, et refuse en plus tout `set -x` réintroduit plus bas. |
| 9 | Aucune valeur de secret affichée ; un message nomme la variable | **Oui, reprise.** Y compris dans les refus de forme : « DEPLOY_HOST ne suit pas le format … Sa valeur n'est pas affichée (NFR-9) ». Deux cas posent un marqueur dans chaque secret et le cherchent dans les deux sorties. |
| 10 | Les chemins de secrets ne doivent pas contenir de virgule (piège `--secret`) | **Non, sans objet.** La virgule n'est un séparateur que pour `docker build --secret id=…,src=…`. `ship.sh` passe ses chemins à `ssh -i` et `-o UserKnownHostsFile=`, où une virgule est un caractère ordinaire ; il ne lance aucun `docker build`. Vérifié dans les pages de manuel et dans le code : aucun des deux chemins ne traverse une chaîne à champs. |

Gardes du workflow aîné (`checks.yaml`) : l'en-tête qui dit que la logique vit dans le script, le
commentaire sur le **mode hôte** du runner et le fait que `runs-on` ne porte que le nom du label,
l'URL absolue épinglée par SHA avec son commentaire de version — les trois sont reprises, et un cas
vérifie en plus que le SHA est **le même** que celui de `checks.yaml`, pour qu'aucun des deux
workflows ne dérive seul.

Gardes que l'aîné n'avait pas et que le cadet ajoute : la lecture de `PIPESTATUS` (l'aîné n'a pas de
pipeline), le faux `ssh` qui relève les **droits** du fichier de clé, et le cas qui tient égal le nom
du dépôt d'images entre `ship.sh`, `deploy-site.sh` et `release/build-image.sh` — trois fichiers qui
ne peuvent pas lire une source commune, puisque le troisième est recopié seul sur le serveur.

## Point 9 — les gardes retirées une par une

Trente-quatre mutations, chacune appliquée seule, suivie des cas censés la voir tomber. Résultat :
**trente-trois vues**, et la trente-quatrième commentée ci-dessous.

| Mutation | Cas qui tombe |
| --- | --- |
| `ship` : code de `docker save` ignoré dans le pipeline | `ship_docker_save_en_echec` |
| `ship` : code de `gzip` ignoré | `ship_gzip_en_echec` |
| `ship` : `set -o pipefail` retiré | `ship_pipefail_declare` **seulement** (voir plus bas) |
| `ship` : `umask 077` → `umask 022` | *aucun* (voir plus bas) |
| `ship` : `umask 022` **et** `mktemp` remplacé par une redirection | `ship_la_cle_nest_lisible_que_par_son_proprietaire` |
| `ship` : garde du `-` en tête de `DEPLOY_HOST` | `ship_host_qui_commence_par_un_tiret` |
| `ship` : contrôle de format de `DEPLOY_HOST` | `ship_host_mal_forme` |
| `ship` : reconnaissance de la clé privée | `ship_cle_qui_nest_pas_une_cle_privee` |
| `ship` : empreintes non vides | `ship_empreintes_sans_aucune_empreinte` |
| `ship` : relevé des variables absentes | `ship_toutes_les_absences_dun_coup` (les deux autres après correction, voir plus bas) |
| `ship` : `docker image inspect` avant le pipeline | `ship_image_absente` |
| `ship` : canal de répétition remplacé par la production | `ship_livraison_de_repetition`, `ship_un_seul_canal_par_tag` |
| `ship` : expression du tag désancrée | `ship_tags_refuses` |
| `ship` : `trap … EXIT` retiré | les deux cas de temporaires |
| `ship` : `set +x` → `set -x` | `ship_aucune_trace_de_shell` |
| `ship` : `StrictHostKeyChecking=yes` → `accept-new` | `ship_les_options_ssh` |
| `ship` : `IdentitiesOnly` et `BatchMode` retirés | `ship_les_options_ssh` |
| `ship` : `status` retiré | `ship_livraison_de_production`, `ship_status_dans_les_deux_canaux`, `ship_status_en_echec` |
| `ship` : la livraison en échec n'arrête plus la suite | `ship_ssh_en_echec` |
| `job` : `merge-base` code ≠ 1 traité comme un refus | `release_job_merge_base_en_anomalie` |
| `job` : la règle du `-rc` devient bloquante pour tous | `release_job_autre_tag_..._avertit_et_continue` |
| `job` : la règle du `-rc` ne bloque plus personne | `release_job_v1_0_0_sans_rc` |
| `job` : comparaison d'arbre supprimée (tout `-rc` compte) | `release_job_v1_0_0_avec_rc_dun_autre_arbre` |
| `job` : code anormal de `git diff` avalé | `release_job_comparaison_darbre_en_anomalie` |
| `job` : numéro de `-rc` non validé | `release_job_v1_0_0_avec_rc_a_zero_de_tete` |
| `job` : `GITHUB_REF` n'a plus à désigner un tag | `release_job_ref_qui_nest_pas_un_tag` |
| `job` : `--check-env` retiré de la chaîne | `release_job_environnement_de_livraison_incomplet` |
| `job` : présence de `origin/<branche>` non vérifiée | `release_job_sans_branche_distante` |
| `job` : présence du tag non vérifiée | `release_job_tag_absent_du_depot` |
| `job` : la chaîne ne s'arrête plus à l'étape en échec | `release_job_arret_a_la_premiere_etape_en_echec` |
| `job` : dépôt git non vérifié | `release_job_hors_depot_git` |
| `yaml` : un secret retiré du mappage | `workflow_release_secrets_exactement_ceux_attendus` |
| `yaml` : `branches: [dev]` ajouté au déclencheur | `workflow_release_declencheur` |
| `yaml` : une seconde commande `run` ajoutée | `workflow_release_une_seule_commande` |

**`umask 077` ne garde rien à lui seul, et reste.** Mesuré : `mktemp` crée en `0600` quel que soit
l'umask, si bien que la ligne retirée seule ne fait tomber aucun cas. C'est le genre de garde que le
point 9 appelle « une garde qui n'en est pas » — sauf qu'ici la seconde mutation tranche : avec un
fichier créé autrement que par `mktemp`, `umask 022` le fait naître en `0644` et le cas tombe. La
ligne garde donc la **suite** du script, pas sa ligne voisine ; le commentaire du fichier le dit avec
la mesure, comme le point 10 l'exige. Le cas de test, lui, affirme la **propriété** — la clé est en
`0600` au moment où `ssh` la lit — et non le mécanisme.

**`set -o pipefail` est doublé par `PIPESTATUS`, délibérément.** Sans `pipefail`, `ship_docker_save_en_echec`
passe encore : le script lit `PIPESTATUS` dans les deux branches de son `if`, et voit l'échec du
premier élément quoi qu'il arrive. Seul le cas textuel tombe. C'est une redondance assumée : une
archive tronquée livrée en production est le pire résultat possible de cette story, et faire reposer
ce constat sur une seule option de shell ne vaut pas le gain. Les deux gardes ont chacune son cas.

**Deux cas ont été corrigés par la mutation.** `ship_variables_absentes` et
`ship_check_env_ne_livre_rien` affirmaient le code `1` et le nom de la variable — que les **gardes de
forme** suivantes produisent aussi, une valeur vide échouant de toute façon au contrôle de format. La
mutation les a vus survivre. Ils affirment désormais le message propre à cette garde-là
(« absente(s) de l'environnement »), exactement le correctif que la story 11.3 avait dû faire pour
`PRIVATE_PATTERNS`.

## Ce que les vérifications ont donné

```
$ bash scripts/tests/run.sh
tests: 767 cas réussis.

$ scripts/check.sh
check: 11 contrôle(s) passés, niveau standard.

$ scripts/ci/checks-job.sh          # la même suite dans CHECK_IMAGE (grep GNU, BusyBox)
checks-job: contrôles dans alpine@sha256:28bd5fe8…, dépôt monté sur /repo, compte 1000:1000.
checks-job-container: garde-fou public/privé sur tout l'historique.
checks-job-container: tests des scripts.
tests: 767 cas réussis.
checks-job-container: contrôles.
check: 11 contrôle(s) passés, niveau standard.
```

`ship.sh` lancé sous `bash -x`, avec de faux `docker` et `ssh`, et des marqueurs dans les trois
secrets :

```
code=0
--- sortie standard ---
release/ship: livraison de eleyone-site:v1.2.3 vers le canal production, commande « deploy v1.2.3 ».
deploy-site: production : eleyone-site:v1.2.3
release/ship: eleyone-site:v1.2.3 livrée par « deploy v1.2.3 ».
release/ship: état du serveur après livraison.
deploy-site: production : eleyone-site:v1.2.3
--- trace (bash -x) : lignes totales = 2 ---
+ set -euo pipefail
+ set +x
--- recherche des marqueurs de secret dans sortie+trace ---
trace:0
sortie:0
--- restes dans TMPDIR ---
0
```

## Ce que la mise en œuvre a appris

- **Une affectation écrase `PIPESTATUS`.** Mesuré : `pipeline || code=$?` garde bien `$?`, mais la
  ligne suivante lit `PIPESTATUS=(0)` — l'affectation est elle-même une commande. D'où la forme
  `if pipeline; then etats=("${PIPESTATUS[@]}"); else etats=("${PIPESTATUS[@]}"); fi`, qui lit le
  tableau avant toute autre commande, dans les deux branches. C'est un piège de plus à consigner.
- **Une plage de caractères ne dit pas la même chose selon la locale.** Un premier motif du cas
  NFR-9 rendait deux verdicts selon l'endroit où la suite tournait — exactement ce que
  `shell-scripts.md` interdit. Le motif retenu exige un domaine pointé et donne le même résultat des
  deux côtés ; toute la suite passe sur le poste **et** dans l'image.

  **L'attribution de ce constat a été corrigée par l'orchestrateur** : la sous-tâche l'imputait à
  `ugrep`, qu'elle voyait répondre à `grep --version`. C'est faux, et la cause réelle est plus
  large. `/usr/bin/grep` est **GNU grep 3.11** sur le poste comme dans l'image ; ce que la
  sous-tâche interrogeait était une fonction shell propre à l'environnement de la session, qui
  n'est **pas** exportée et qu'un script lancé par `bash` ne voit donc jamais (vérifié :
  `BASH_FUNC_grep` absent de l'environnement, et un script rend « GNU grep 3.11 »).

  La vraie cause est la **locale**. Le poste tourne en `fr_FR.UTF-8`, `CHECK_IMAGE` en `C`, et une
  plage `[A-Za-z]` est lue dans l'ordre de **collation** de la locale : en français, « ô » et « é »
  tombent entre `A` et `Z`. Mesuré avec le même GNU grep des deux côtés :

  ```
  poste (fr_FR.UTF-8)  : compte@hôte-éxample
  image (locale C)     : compte@h
  poste avec LC_ALL=C  : compte@h
  ```

  `LC_ALL=C` sur le poste reproduit exactement le résultat de l'image : c'est la locale, pas le
  binaire. La conclusion pratique de la sous-tâche reste juste — écrire un motif qui ne dépend pas
  d'une plage —, mais sa cause était fausse, et une cause fausse envoie le prochain lecteur chercher
  au mauvais endroit (point 10 : une règle qui décrit le comportement d'un outil n'est vraie
  qu'une fois vérifiée).

  **Portée, mesurée mais non analysée** : 23 fichiers de `scripts/`, `deploy/` et `.githooks/`
  emploient une plage de ce genre. La plupart s'appliquent à des entrées ASCII — noms de variables,
  tags, SHA — où la divergence ne peut pas se manifester ; aucune n'a été auditée une par une, et ce
  n'est pas le périmètre de cette story. Entrée dans `deferred-work.md`, avec la mesure. Le filet
  empirique existe déjà : `scripts/ci/checks-job.sh` rejoue toute la suite dans l'image, et les deux
  côtés rendent 767 cas réussis.

## Revue du code

### 25/09/2026 — `dc62354` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 120. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 4a3938ed5707afe2e94c0f54

##### Lentille Edge Case Hunter
NON BLOQUANT — Injection de chemin dans faux_git : Dans `scripts/tests/test-release-job.sh`, la fonction `faux_git` génère l'appel final avec `printf 'exec %s "$@"\n' "$vrai"`. Si l'environnement possède un chemin absolu vers git (`$vrai`) contenant des espaces, le script généré échouera par une erreur de découpage d'arguments.

##### Lentille Verification Gap
BLOQUANT — Erreurs silencieuses dans faux_ssh : Dans `scripts/tests/test-ship.sh`, le faux binaire emploie `cp "$cle" "$w/ssh-cle.$n" 2>/dev/null || true` et une instruction identique pour `$connus`. Bien qu'ils se trouvent dans un bouchon de test, ces `|| true` avalent silencieusement de véritables erreurs de copie ou de permissions, enfreignant la règle du projet qui interdit strictement de laisser passer une erreur en silence.

##### Couche propre au projet
NON BLOQUANT — Critères d'acceptation : Le flux de mise en ligne satisfait l'intégralité de la story 11.5 (AD-11, AD-14, AD-22) en imposant l'exclusivité des canaux et la répétition préalable avec un arbre identique.
NON BLOQUANT — Données privées et secrets : La protection contre la fuite est totale (NFR-9). Les valeurs sont portées par l'environnement, écrites en temporaires `0600` détruits systématiquement par `trap EXIT`, et masquées à la trace par un `set +x` préventif.
NON BLOQUANT — Concordance skill/procédure/script : La description du flux, les variables ciblées dans `docs/procedures/release-workflow.md` et le code du script `ship.sh` s'alignent rigoureusement.
NON BLOQUANT — Cohérence architecturale : Conformément aux décisions, `.gitea/workflows/release.yaml` ne contient que son déclencheur et aucune logique opérationnelle, l'orchestration résidant intégralement dans `scripts/ci/release-job.sh`.
NON BLOQUANT — Erreurs silencieuses et robustesse : La lecture soignée du tableau `PIPESTATUS` (empêchant `docker save` d'échouer silencieusement si `ssh` retourne 0) montre que l'analyse des échecs enchaînés est scrupuleusement couverte en production.

VERDICT: BLOQUANT — présence de « || true » avalant silencieusement les erreurs de lecture/copie dans le faux binaire de test ssh.

### 25/09/2026 — `b3f2bbf` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 120. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a7b1fbdd35e4b08c43425c4f

##### Lentille Edge Case Hunter
Aucun chemin non géré ou comportement de bord inattendu n'a été identifié. Les variables vides, les formats invalides et les fermetures de pipeline (`PIPESTATUS`) sont tous convenablement gérés et bloqués au plus tôt avant tout effet de bord.

##### Lentille Verification Gap
No verification gaps found.

##### Couche propre au projet
NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée.
NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
NON BLOQUANT — Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure.
NON BLOQUANT — Le changement est cohérent avec AGENTS.md et les décisions d'architecture.
NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail.

VERDICT: NON BLOQUANT — aucune

## Décisions

- **Le tag se lit dans `GITHUB_REF`, pas dans un argument du workflow** (S1 poussé jusqu'au bout :
  le YAML ne calcule rien, pas même une expression).
- **`ship.sh --check-env`** porte les refus d'environnement avant les contrôles, sans recopier la
  liste des noms (point 19).
- **`-o BatchMode=yes`** ajouté aux quatre options décidées, contre un job bloqué sur une invite.
- **`umask 077` conservée** bien que la mutation ne la voie pas seule : elle garde la suite du
  script, et la mesure est écrite dans le fichier et ici (points 9 et 10).
- **`set -o pipefail` et `PIPESTATUS` cohabitent**, redondance assumée et documentée.
- **Les tests de `release-job.sh` emploient un vrai `git` dans un dépôt jetable**, et un faux `git`
  seulement pour forcer un code de sortie anormal : ce que le job vérifie, ce sont les codes de
  `merge-base` et de `git diff`, qu'un faux `git` ne prouverait pas. Le dépôt du projet n'est jamais
  touché, aucun tag n'y est créé. C'est l'unique écart à la consigne « faux binaires pour `ssh`,
  `docker` et `git` » ; `ssh` et `docker` ne sont jamais lancés, réels ou non.

## Décisions de l'orchestrateur

### L'écart au brief : un vrai `git` dans les tests du job

La sous-tâche emploie un **vrai** `git` dans un dépôt jetable pour `test-release-job.sh`, et un faux
`git` seulement pour forcer un code de sortie anormal. **Accepté, et c'est le bon choix** : ce que
le job vérifie, ce sont précisément les codes de sortie de `merge-base --is-ancestor`, `git diff` et
`git tag`. Un faux `git` n'aurait prouvé que le comportement du faux — le point 9 demande que le
test exerce l'entrée que la garde doit refuser, c'est-à-dire un tag qui ne descend **vraiment** pas
de `origin/main`. Le procédé (`new_repo`) est déjà celui de `test-check-private.sh`, le dépôt du
projet n'est jamais touché, et ni `ssh` ni `docker` ne sont lancés.

### Les deux mutations qui n'ont rien fait tomber, et ce qu'elles valent

**`umask 077` retirée seule ne fait tomber aucun cas** : `mktemp` crée déjà en 0600. La sous-tâche
garde la ligne et le dit, avec une seconde mutation — remplacer `mktemp` par une redirection — qui,
elle, fait tomber le cas. **Accepté** : la garde protège la *suite* du script, et la mesure est
écrite à côté d'elle plutôt que supposée (point 10). C'est le traitement honnête d'une garde dont
l'effet ne se voit pas en l'isolant.

**`set -o pipefail` retiré ne fait tomber que le cas textuel**, parce que `ship.sh` lit `PIPESTATUS`
dans les deux branches de son `if`. **Accepté** : une archive tronquée livrée en production ne doit
pas reposer sur une seule option de shell, et les deux gardes ont chacune leur cas. La redondance
est ici une décision, pas un oubli.

### Le défaut que la relecture du fichier entier a trouvé (point 8)

L'ordre de lecture des trois codes du pipeline était faux. Un `ssh` qui s'arrête ferme le tube, et
`docker save` meurt alors d'un SIGPIPE (141) : la première version accusait `docker save` —
« archive tronquée » — là où c'est le **transport** qui avait lâché. Le canal aval est désormais
jugé en premier, l'amont n'est cité qu'en conséquence, et « archive tronquée » ne sort **que** si
`ssh` a rendu 0, c'est-à-dire si le serveur a vraiment tout lu. Un message d'erreur qui accuse le
mauvais maillon envoie chercher au mauvais endroit, un soir de mise en ligne ratée.

### Vérification du travail de la sous-tâche (point 22)

Rejoué par l'orchestrateur, sans reprendre ses mesures :

| Vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 767 cas réussis |
| `scripts/check.sh` | 11 contrôles, code 0 |
| `docker save` en échec (faux binaire, code 7) | `ship.sh` rend **2**, « ne considérez pas … comme livrée » |
| marqueur planté dans `DEPLOY_SSH_KEY`, sorties standard et d'erreur | **0 occurrence** |
| le même sous `bash -x` | **0 occurrence** |
| temporaires portant le marqueur après exécution | **0** |
| plage de caractères : poste, image, poste en `LC_ALL=C` | divergence reproduite, cause **corrigée** (locale, pas binaire) |

L'attribution du constat sur les plages de caractères a été **corrigée** : voir « Ce que la mise en
œuvre a appris ». La conclusion pratique de la sous-tâche tenait, sa cause était fausse, et une
cause fausse envoie le prochain lecteur chercher au mauvais endroit. La portée réelle — 23 fichiers,
non audités — part dans `deferred-work.md` avec sa mesure.

### Triage de la revue du code (`dc62354`, verdict `block`)

**B1 — deux `|| true` dans le faux `ssh` de `test-ship.sh`. RETENU, et le verdict bloquant est
justifié.** L'objection facile serait « c'est un bouchon de test » ; elle ne tient pas. Un bouchon
fait partie du dispositif qui prouve quelque chose, et le projet a déjà payé cette classe de faute :
la rétrospective de l'epic 3 a retiré un `|| true` qui avalait les codes de `grep`, et le point 9
demande qu'une garde soit éprouvée, pas qu'elle ait l'air d'être là. Ici, une copie de clé qui
échoue laissait le faux `ssh` continuer comme s'il avait lu la clé ; un cas qui n'inspecte pas ce
fichier précis conclurait alors sur du vide.

Le bouchon **échoue** désormais, bruyamment, avec un code distinct :

```
$ (copie vers un dossier inexistant)
faux ssh : copie de la clé impossible
rc=97
```

**E1 — `printf 'exec %s "$@"'` avec un chemin de `git` portant une espace. RETENU**, et vérifié
plutôt que supposé. Le chemin vient de `command -v` : un dossier d'installation quelconque suffit à
le casser.

```
%s : exec: …/scratchpad/dos: not found
%q : git version 2.43.0
```

La forme `%q` est celle que le dépôt emploie déjà pour citer une valeur venue de l'extérieur
(`visible()` dans `deploy/remote/deploy-site.sh`, story 11.4).

**Les cinq lignes de la couche projet** sont des confirmations : critères tenus, exclusivité des
canaux, aucune fuite de secret, workflow sans logique, lecture soignée de `PIPESTATUS`. Rien à
reporter.

Les deux correctifs arrivent **avant** le commit de statut, et la revue est relancée.

### Triage de la seconde revue du code (`b3f2bbf`)

**Aucun constat.** L'edge-case-hunter ne trouve « aucun chemin non géré » et relève que les
variables vides, les formats invalides et les fermetures de pipeline sont bloqués « au plus tôt
avant tout effet de bord ». Les cinq lignes de la couche projet sont des confirmations : critères
tenus sans vider leur intention, aucune donnée privée ni adresse, procédure et script concordants,
cohérence avec `AGENTS.md` et l'architecture, aucune erreur silencieuse sous `set -euo pipefail`.

Rien à retenir, rien à reporter ; écrit parce qu'un rapport se triage même quand il est vide.
