# Story 11.6 : Production server and secrets setup

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.6.

Sixième story de l'epic 11, dont l'en-tête (point 21) veut la chaîne de mise en ligne construite et
**répétée tôt sur le serveur de production, sans DNS**. C'est la story qui donne à cette chaîne le
serveur qui lui manque.

## La seule opération manuelle de l'epic

La spec la marque « Opération manuelle (Arnaud) : **oui** ». Tout ce qu'elle demande se passe sur le
serveur de production et dans l'administration de la forge — un agent ne peut ni le faire ni le
simuler. Ce que cette story livre est donc ce qu'un agent **peut** livrer :

1. **la procédure**, écrite pour être exécutée sans rien deviner : les commandes dans l'ordre, et
   pour chacune ce qu'il faut voir avant de passer à la suivante ;
2. **un contrôle du second critère d'acceptation**. Le premier — « `status` répond, le reste est
   refusé » — se vérifie à la main, depuis le poste, avec la clé. Le second — « secrets et variables
   portent exactement les noms de l'architecture » — est **automatisable** : l'API de Gitea liste
   les **noms** des secrets d'un dépôt (jamais leurs valeurs). Un script les confronte à la liste
   attendue et nomme ce qui manque ou ce qui est en trop.

C'est le même partage que pour le hook `pre-receive` (story 1.2) : l'agent a écrit
`docs/procedures/gitea-pre-receive-hook.md`, Arnaud l'a posé sur la forge.

## Ce que la story ne fait pas

Les étapes 3 à 8 de la procédure « premier déploiement » de l'architecture — répétition générale,
premier tag de production, hôte proxy dans NPM, vérifications, DNS, mesures — **ne sont pas ici**.
La spec dit « étapes 1 et 2 », et les autres appartiennent aux stories 11.9 et 11.11.

## Où la liste des noms de secrets doit vivre

**Douze secrets**, et aucun ne doit voir son nom recopié une treizième fois (point 19) :

- les **huit** `HUGO_LEGAL_*` sont déjà nommés une seule fois, dans `ci/legal-placeholder.env`, dont
  C18 vérifie qu'il porte exactement les noms d'AD-9. `scripts/release/build-image.sh` les y lit
  déjà plutôt que de les énumérer : le contrôle de cette story fera pareil ;
- les **quatre** de déploiement — `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_KNOWN_HOSTS`,
  `PRIVATE_PATTERNS` — sont aujourd'hui nommés dans `scripts/release/ship.sh` (qui les exige) et
  dans `.gitea/workflows/release.yaml` (qui les mappe). **Deux exemplaires, donc déjà un de trop** :
  la story les ramène à une source unique que les deux lisent.

## Ce que la procédure doit dire et qui n'est pas devinable

- **`DEPLOY_HOST` porte `utilisateur@hôte`**, décidé à la story 11.5 : il n'y a pas de secret
  `DEPLOY_USER`. Un lecteur qui l'ignore posera un nom d'hôte seul et la livraison échouera sans
  que le message ne dise pourquoi.
- **Le nom du réseau du proxy n'entre pas dans le dépôt** (NFR-9) : il vit dans un fichier `.env`
  posé **sur le serveur**, à côté des fichiers Compose, avec `PROXY_NETWORK`. Ce `.env`-là n'est pas
  celui du poste de développement, et la procédure doit le dire, sans quoi quelqu'un cherchera le
  fichier au mauvais endroit.
- **Le réseau est déclaré `external: true`** : il existe déjà, c'est celui de NPM, et Compose ne
  doit pas le créer.
- **Gitea refuse un nom de secret commençant par `GITEA_`** : les variables `GITEA_*` du poste n'ont
  pas d'équivalent en CI, et les jobs emploient le jeton intégré.

## La forme de l'API, mesurée plutôt que supposée (point 10)

Écrire un script qui lit `.[]?.name` sans l'avoir observé aurait été exactement la faute que le
point 10 nomme : une règle qui décrit le comportement d'un outil n'est vraie qu'une fois vérifiée.
Mesuré le 25/09/2026, sur la forge, avec un secret jetable **créé puis supprimé dans la minute** :

```
GET  …/actions/secrets            → []            (aucun secret : la story 11.6 n'a pas encore eu lieu)
GET  …/actions/variables          → []
PUT  …/actions/secrets/ESSAI_FORME_API   → 201
GET  …/actions/secrets   → [{"name":"ESSAI_FORME_API","description":"","created_at":"…"}]
DELETE …/actions/secrets/ESSAI_FORME_API → 204
GET  …/actions/secrets            → []            (état initial retrouvé)
```

Trois faits en découlent, et ils fondent le contrôle :

- la réponse est un **tableau**, chaque entrée portant `name`, `description` et `created_at` — et
  **jamais** la valeur du secret. Lister les noms ne divulgue donc rien ;
- **aucun secret n'existe aujourd'hui** sur le dépôt : le contrôle de cette story, lancé maintenant,
  doit nommer les douze comme manquants. C'est son cas nominal de départ, et le premier à écrire ;
- la valeur se pose par `PUT` sur le nom, la suppression par `DELETE` : la procédure peut donc
  donner des commandes exactes, sans passer par l'interface web.

Le secret d'essai portait une valeur factice et n'a existé que le temps de la lecture. La forge est
revenue à zéro secret, vérifié.

## Revue de spec

### 25/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `83738fe`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: fd10c34ab0e5c6c55e51abc0

##### Rapport de Revue (bmad-review)

**Lentille Adversariale (Failles, logique, sécurité)**
* BLOQUANT : **Livrables implicites et non définis.** La spécification décrit des opérations manuelles et les comportements attendus, mais n'indique à aucun moment *quels fichiers* doivent être créés ou modifiés par l'agent (ex: un document Markdown pour la procédure, un script bash pour automatiser la vérification). Laissé tel quel, un agent de développement ne committera rien, considérant que la story est purement manuelle.
* BLOQUANT : **Critère d'acceptation 2 formulé manuellement.** Le texte indique « Quand Arnaud les consulte ». Cela contredit frontalement l'intention d'automatiser ce contrôle (rendu possible par l'API de Gitea mentionnée par l'auteur). Le critère doit impérativement exiger l'exécution d'un script dédié au lieu d'une consultation humaine.
* BLOQUANT : **Absence de liste pour les variables à contrôler.** Le CA 2 demande de vérifier que « secrets et variables portent exactement les noms de l'architecture ». Si les 12 secrets peuvent être déduits des prérequis, aucune liste de "variables" de forge n'est spécifiée. Un script automatisé ne saura pas quelles variables vérifier.
* BLOQUANT : **Omission de la note de déploiement (Règle globale).** Les règles globales imposent la création d'une note de déploiement dans `docs/deployment-notes/` dès lors qu'il y a des actions manuelles (configuration VPS, création de secrets). La spécification l'omet, ce qui fera enfreindre cette règle par l'agent.

**Lentille Structurelle (Organisation et complétude)**
* BLOQUANT : **Mélange de responsabilités (machine vs humain).** La spécification (notamment avec la case à cocher "Serveur en x86_64 confirmé") confond la documentation des actes manuels que le mainteneur devra accomplir et le code/les tests que la Pull Request doit réellement livrer pour être considérée comme terminée.
* NON BLOQUANT : **Risque de violation de NFR-9 dans la future procédure.** La mention « copie de compose.yaml [...] avec le nom du réseau de NPM » pourrait amener un agent développeur à écrire *en dur* le véritable nom de ce réseau dans la documentation, violant ainsi la NFR-9. Il faudrait préciser que la procédure écrite doit employer un "placeholder".

**Lentille Rédactionnelle (Clarté et ambiguïté - Prose)**
* NON BLOQUANT : **Ambiguïté sur "les deux services".** L'expression « les deux services en place » (dans le récit utilisateur) suppose que le lecteur devine de quels services il s'agit. Les nommer explicitement (ex: le serveur de site et le proxy) lèverait cette ambiguïté.
* NON BLOQUANT : **Formulation vague du déclencheur.** Dans le CA 2, l'expression « les réglages du dépôt sur la forge » gagnerait à être remplacée plus précisément par « la liste des secrets CI/CD configurés sur la forge ».

##### À trancher avant d'implémenter
* Quels sont les chemins exacts des livrables attendus pour cette story (ex: `scripts/tests/test-11-6.sh` pour l'automatisation, et un fichier Markdown pour la documentation) ?
* Y a-t-il réellement des "variables" (au sens Gitea Variables) à configurer et vérifier sur la forge, ou seulement des secrets ?
* Le CA 2 doit-il être réécrit pour spécifier l'appel direct au script de contrôle des secrets via l'API (ex: appel à `scripts/lib/gitea.sh`) au lieu de reposer sur une consultation manuelle ?
* Confirmez-vous que la documentation détaillant les actions manuelles doit prendre la forme de la note exigée par les règles globales (`docs/deployment-notes/`) ?

### Triage des constats (point 20 : chacun reçoit sa décision)

| # | Constat | Décision |
| --- | --- | --- |
| A1 | Les livrables ne sont pas nommés : un agent ne commiterait rien | **Retenu**, et le constat est juste — c'est le piège d'une story « opération manuelle ». Chemins arrêtés : `docs/procedures/serveur-de-production.md` (la procédure), `scripts/release/check-forge-secrets.sh` (le contrôle), `scripts/tests/test-forge-secrets.sh` (ses cas). |
| A2 | Le critère 2 dit « quand Arnaud les consulte », ce qui contredit l'automatisation | **Retenu sur le fond, sans réécrire `epics.md`.** Le contrôle *est* la consultation : Arnaud lance une commande au lieu de lire une page web, et c'est elle qui répond. Un artefact de planification validé ne se réécrit pas depuis une story ; le triage est l'endroit où le projet consigne ce complément. |
| A3 | Aucune liste de « variables » n'est donnée | **Retenu, et la réponse est : il n'y en a aucune.** `ARCHITECTURE-SPINE.md:645` énumère les secrets et ne nomme **aucune** variable au sens Gitea. Le contrôle ne vérifie donc pas une liste de variables : il signale toute variable trouvée comme **inattendue**, sans bloquer, parce qu'une variable posée par erreur mérite d'être vue. |
| A4 | Il manque une note dans `docs/deployment-notes/` | **Invalide.** Vérifié : `docs/deployment-notes/` n'existe pas, et aucune règle du projet n'en demande — ni `AGENTS.md`, ni `docs/`, ni l'architecture. La règle est **réelle** mais vit dans les mémoires globales du compte qui relit, où elle décrit un autre projet d'Arnaud. C'est nommément le cas du **point 20 d'AGENTS.md**, déjà rencontré à la story 11.3 avec `docs/CHANGELOG.md` : le point prévoyait le retour, il a eu lieu. |
| S1 | La story confond ce qu'Arnaud fait et ce que la PR livre | **Retenu, et c'est la remarque la plus utile des huit.** La PR livre **trois fichiers** et n'installe rien ; les actes manuels y sont **décrits**, pas faits. La case « serveur en x86_64 confirmé » est une vérification qu'Arnaud coche, pas un test. La procédure sépare donc explicitement « ce que vous faites » de « ce que la commande vérifie ». |
| S2 | La procédure risque d'écrire en dur le vrai nom du réseau de NPM | **Retenu, et c'est un risque réel** — la procédure est le seul livrable de cette story qui parle du serveur. Elle emploie des substituts (`<utilisateur>@<hôte>`, `<réseau-du-proxy>`), et le contrôle NFR-9 de `scripts/tests/test-deploy-site.sh` est étendu pour couvrir ce nouveau fichier. |
| P1 | « les deux services » est à deviner | **Retenu** : la procédure nomme le service `site` (production) et le projet `site-rehearsal` (répétition). |
| P2 | « les réglages du dépôt sur la forge » est vague | **Retenu** : la procédure et le contrôle parlent des **secrets d'Actions** du dépôt, par leur nom. |

### Les douze secrets, et le treizième qui n'en est pas un

`ARCHITECTURE-SPINE.md:645` liste **cinq** secrets plus les huit valeurs légales. Mais
`ANTHROPIC_API_KEY` sert à l'**agent de parité** (AD-16), qui est l'**epic 12** : la spec de cette
story ne le nomme pas, et l'exiger ici bloquerait une installation par ailleurs complète.

**Décision :** le contrôle attend les **douze** de la story 11.6 — quatre de déploiement et huit
légales — et traite tout autre secret comme **inattendu mais non bloquant**, en le nommant. Un
`ANTHROPIC_API_KEY` posé d'avance sera donc signalé sans faire échouer, et une faute de frappe
(`DEPLOY_HOSTS`) apparaîtra deux fois : une fois comme manquant, une fois comme inattendu. C'est
exactement ce qu'on veut voir.

## Ce que la story livre

Sept fichiers, dont trois nouveaux au sens de la spec. Rien n'est installé : les actes manuels sont
**décrits**, pas faits, et aucun secret n'a été créé, modifié ni supprimé sur la forge.

| Fichier | Rôle |
| --- | --- |
| `docs/procedures/serveur-de-production.md` | **nouveau** — la procédure : prérequis, compte, clé restreinte et ses quatre essais, copie de `deploy/`, `.env` du serveur, les douze secrets, entretien, échecs |
| `scripts/release/check-forge-secrets.sh` | **nouveau** — le contrôle du second critère d'acceptation |
| `scripts/tests/test-forge-secrets.sh` | **nouveau** — ses 25 cas, hors ligne, faux `curl` en tête de `PATH` |
| `ci/release-secrets.txt` | **nouveau** — la source unique des quatre noms qui ne sont pas des valeurs légales |
| `scripts/lib/secrets.sh` | **nouveau** — la lecture de ces listes, écrite une fois pour les deux scripts qui les lisent |
| `scripts/release/ship.sh` | lit désormais ses `DEPLOY_*` dans `ci/release-secrets.txt` au lieu de les porter |
| `scripts/tests/test-ship.sh` | 5 cas de plus, pour ce que cette lecture doit refuser |
| `scripts/tests/test-workflows.sh` | le cas qui tient le YAML égal lit maintenant les deux sources, au lieu de réciter quatre noms |
| `scripts/tests/test-deploy-site.sh` | cas NFR-9 étendu au nouveau fichier (constat S2), plus la garde `compte@machine` que son jumeau portait déjà |
| `docs/procedures/deploy-site.md`, `release-workflow.md` | deux phrases au futur devenues vraies (point 8), et la précision du tunnel ci-dessous |

### Où vivent les douze noms, après cette story

Le brief demandait de ramener à **une** source les quatre noms de déploiement, écrits deux fois
(`scripts/release/ship.sh` et `.gitea/workflows/release.yaml`), ou de dire pourquoi c'est impossible
pour le YAML. Les deux, en fait :

- `ci/release-secrets.txt` porte les quatre. `ship.sh` y lit les entrées `DEPLOY_*` — un nom ajouté
  là-bas devient exigé sans qu'une ligne du script change, et un cas de test le prouve —, et
  `check-forge-secrets.sh` y lit les quatre. Les huit valeurs légales restent nommées une seule fois
  dans `ci/legal-placeholder.env`, comme `build-image.sh` les y lit déjà (C18) ;
- **le YAML ne peut pas lire ce fichier.** Un workflow d'Actions ne lit aucun fichier du dépôt, et
  `${{ secrets.NOM }}` s'écrit un nom à la fois — c'est d'ailleurs ce mappage nominatif qui fait
  qu'un job ne reçoit que les secrets qu'on lui nomme. La copie y reste donc, et
  `case_workflow_release_secrets_exactement_ceux_attendus` la tient égale aux **deux** sources. Ce
  cas récitait lui-même les quatre noms : il les lit maintenant, ce qui retire la troisième copie.

### Ce que le contrôle ne peut pas faire, et qui est écrit dans son en-tête

L'API ne rend jamais la valeur d'un secret. Le contrôle vérifie donc que les douze **existent**,
sous leurs noms exacts, et rien d'autre : une valeur fausse se voit à la mise en ligne, pas ici. Son
en-tête le dit noir sur blanc pour que personne ne croie l'inverse, et le rapport le redit à chaque
exécution réussie (« Aucune valeur n'a été lue »).

### Deux points du serveur qui ne se devinaient pas, trouvés en écrivant la procédure

- **Le déploiement passe par le port 22.** `DEPLOY_HOST` porte `utilisateur@hôte` et rien d'autre —
  l'expression de `ship.sh` refuse un port —, et `ship.sh` ne passe aucun `-p` à `ssh`. Si le serveur
  écoute ailleurs, il faut le savoir **maintenant** : le workflow `release` l'apprendrait au premier
  tag. C'est dans les prérequis de la procédure.
- **Le tunnel de la répétition n'emprunte pas la clé de déploiement.** AD-22 fait vérifier le canal
  de répétition par `ssh -L 18080:127.0.0.1:18080 <compte>` ; le premier critère de cette story-ci
  exige qu'une redirection de port soit **refusée**, et `restrict` la refuse en effet. Les deux ne se
  contredisent pas : le tunnel passe par le compte d'administration, jamais par le compte de
  déploiement. Ni AD-22 ni `deploy-site.md` ne le disaient. La procédure le dit, et
  `deploy-site.md` gagne le paragraphe correspondant — un artefact de planification validé ne se
  réécrit pas depuis une story, une procédure si.

## Le brief des jumeaux (point 19)

### Aîné du script : `scripts/verify-and-merge-pr.sh` et `scripts/lib/gitea.sh`

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 1 | Dépôt distant vérifié avant tout appel ; jeton lu sans jamais être affiché | **Oui, reprise.** `check_origin` est appelé avant `load_gitea_env`, donc avant que le jeton soit même lu : un dépôt distant qui n'est pas le canonique arrête tout sans qu'aucun appel parte (cas `origine_non_canonique`, qui vérifie aussi qu'aucun appel n'a eu lieu). `set +x` dès l'en-tête. |
| 2 | Codes HTTP distingués, un message par cause | **Oui, reprise et élargie.** `lire_liste` distingue 200, 401/403 (portée du jeton), 404 (dépôt ou point d'API), 000 (forge injoignable, message sans adresse) et tout autre code, qui cite le message de la forge par `forge_message`. Quatre cas de test, et une mutation par cause. |
| 3 | Aucune valeur de secret affichée | **Oui, et c'est le cœur.** Ici aucune valeur n'est même lisible : l'en-tête l'écrit, le rapport le redit. Rien de la réponse n'atteint la sortie hors le `name` — un cas pose une `description` marquée et vérifie qu'elle n'apparaît nulle part. Le message du 000 ne cite pas l'adresse de la forge (NFR-9). |
| 4 | Codes 0 / 1 / 2, rapport lisible même quand tout passe | **Oui, reprise.** 0 les douze sont là, 1 au moins un manque, 2 vérification impossible. Le rapport donne d'abord le compte attendu/présent/variables, puis une ligne par écart, puis une conclusion — y compris en cas de succès. |
| 5 | `jq -n --arg` pour composer un JSON | **Sans objet dans le script, repris dans la procédure.** Le contrôle n'envoie que des `GET` : il ne compose aucun corps. La procédure, elle, en compose un pour chaque `PUT`, et le fait par `jq -Rs '{data: sub("\n$"; "")}'` **lu depuis un fichier** — encore un cran au-dessus de `--arg`, puisque la valeur ne passe même pas par la ligne de commande. |

### Aîné de la procédure : `docs/procedures/gitea-pre-receive-hook.md`

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 6 | Commande exacte et attendu à chaque étape, « sinon, s'arrêter » | **Oui, reprise partout.** Chaque bloc de commandes est suivi d'un « Attendu : … », et les étapes dont l'échec est dangereux (empreintes, empreinte d'hôte, essais de la clé) disent ce qu'il faut faire au lieu de continuer. |
| 7 | Droits et propriétaires écrits, puis vérifiés | **Oui, reprise.** Tableau des propriétaires et des modes en tête, `chmod`/`install -d` explicites, `umask 077` là où un fichier naît, et des `ls -l` dont l'attendu est écrit. `authorized_keys` en `0600` a sa propre raison : `sshd` ignore un fichier trop ouvert et l'accès échoue sans dire pourquoi. |
| 8 | Dit quand recopier après une modification du dépôt | **Oui, reprise et élargie.** Cinq déclencheurs : les trois fichiers de `deploy/`, le nom du réseau, la liste des motifs, les valeurs légales, la clé refaite — ce dernier avec l'ordre des deux opérations, parce qu'entre les deux aucune mise en ligne n'aboutirait. L'aîné n'avait pas à penser aux secrets. |
| 9 | Ne nomme ni hôte ni chemin réel | **Oui, reprise, et outillée.** Tableau des substituts en tête, et le fichier entre dans le cas NFR-9 de `scripts/tests/test-deploy-site.sh` (constat S2). |

### Aîné du fichier de test : `scripts/tests/test-release.sh`

Gardes reprises : faux `curl` en tête de `PATH` qui consomme l'entrée standard sans écrire le jeton ;
trace des appels (méthode et chemin seulement) ; vérification qu'**aucun** appel n'a eu lieu après un
refus qui précède la forge ; `env -i` pour qu'un cas rende le même verdict sur le poste et dans
`CHECK_IMAGE` ; dépôt de test jetable, jamais celui du projet. Garde **ajoutée** : l'affirmation
qu'aucune méthode d'écriture n'est jamais envoyée (`que_des_lectures`) — un contrôle qui poserait ou
supprimerait un secret serait pire que pas de contrôle.

### Aîné de `case_deploy_site_aucun_nom_de_compte` : `scripts/tests/test-ship.sh`

C'est exactement le cas que le point 19 décrit. `test-ship.sh` portait **deux** gardes NFR-9 —
l'adresse IP et `compte@machine.domaine` — et `test-deploy-site.sh`, écrit « comme » lui une story
plus tard, n'avait repris que la première. La seconde est ajoutée ici, sur les cinq fichiers qui
parlent du serveur. Sans elle, étendre le cas au nouveau fichier de procédure n'aurait couvert que la
moitié des façons de nommer une machine.

### Une garde de l'aîné volontairement **non** reprise

`scripts/release/build-image.sh` lit les huit noms d'AD-9 par un `shell_grep_into … -oE
'^HUGO_LEGAL_[A-Z0-9_]+='` écrit chez lui. `scripts/lib/secrets.sh` offre maintenant la même lecture,
préfixe en paramètre, mais **`build-image.sh` n'est pas converti** : ses messages de refus sont
affirmés mot pour mot par `scripts/tests/test-release-build-image.sh`, et les changer dans une story
qui ne touche pas à la construction de l'image serait du bruit. Ce qui compte pour le point 19 est
que la **liste des noms** vive à un seul endroit — elle y vit —, la manière de la lire étant une
convention, pas une copie. À rouvrir si un troisième script doit lire ce fichier.

## Les mutations de garde (point 9)

Vingt et une gardes retirées ou inversées une à une, le cas visé relancé à chaque fois. **Toutes
tombent** — mais trois ne tombaient pas au premier essai, et c'est ce que la mesure a rapporté de plus
utile.

| # | Garde retirée | Cas visé | Résultat |
| --- | --- | --- | --- |
| M1 | le script n'accepte aucun argument | `argument_refuse` | tombe |
| M2 | `check_origin` avant tout appel | `origine_non_canonique` | tombe |
| M3 | fichier de noms absent ou illisible (bibliothèque) | `valeurs_legales_absentes` | **ne tombait pas**, voir ci-dessous ; tombe |
| M4 | aucune valeur légale dans `legal-placeholder.env` | `valeurs_legales_vides` | tombe |
| M5 | aucun nom dans `release-secrets.txt` | `liste_des_quatre_vide` | tombe |
| M6 | un nom attendu par les deux fichiers | `nom_attendu_deux_fois` | tombe |
| M7 | doublon dans une liste (bibliothèque) | `doublon_dans_la_liste` | **ne tombait pas** ; tombe |
| M8 | ligne mal formée ignorée au lieu d'arrêter | `liste_des_quatre_mal_formee` | tombe |
| M9 | 401/403 confondus avec le cas général | `jeton_sans_la_portee` | tombe |
| M10 | 404 confondu avec le cas général | `depot_ou_endpoint_absent` | tombe |
| M11 | 000 confondu avec le cas général | `forge_injoignable` | tombe |
| M12 | réponse qui n'est pas un tableau acceptée | `reponse_pas_un_tableau` | tombe |
| M13 | plafond de pagination levé à 1000 | `liste_trop_longue` | tombe |
| M14 | entrée sans nom acceptée | `entree_sans_nom` | tombe |
| M15 | nom venu de la forge affiché brut au lieu de `%q` | `nom_hostile_neutralise` | **ne tombait pas** ; tombe |
| M16 | un secret manquant ne refuse plus | `aucun_secret_les_douze_manquent` | tombe |
| M17 | un secret inattendu se met à bloquer | `inattendu_ne_bloque_pas` | tombe |
| M18 | les `DEPLOY_*` recopiés dans `ship.sh` | `ship_nom_ajoute_a_la_liste_devient_exige` | tombe |
| M19 | une liste sans entrée `DEPLOY_*` passe | `ship_liste_de_secrets_sans_deploy` | tombe |
| M20 | adresse IP réelle dans la procédure | `deploy_site_aucune_adresse` | tombe |
| M21 | `compte@machine` réel dans la procédure | `deploy_site_aucun_nom_de_compte` | tombe |

### Les trois qui ne tombaient pas, et ce qu'elles ont appris

- **M3 — deux gardes qui se ressemblent.** Sans la vérification d'existence, `shell_grep_into` échoue
  de toute façon sur un fichier absent (code 2 de `grep`) et cite le même chemin : le cas passait, la
  garde n'était pas testée. C'est le défaut que `case_ship_variables_absentes` avait déjà nommé à la
  story 11.5. Le cas affirme maintenant **le message de cette garde-ci**, « absent ou illisible ».
- **M7 — le même défaut, entre la bibliothèque et le script.** Le doublon d'un nom dans
  `release-secrets.txt` était rattrapé par la garde du script qui croise les deux fichiers, dont le
  message contient aussi « deux fois ». Chaque cas affirme désormais sa propre formulation : « ce nom
  est écrit deux fois » plus le numéro de ligne pour la bibliothèque, « est attendu deux fois » pour
  le script.
- **M15 — une fixture qui ne fabriquait pas ce qu'elle prétendait** (point 16). Le nom hostile devait
  porter un saut de ligne ; `printf '%s\n' "$@" | jq -R .` lit **ligne par ligne**, et le nom
  arrivait sur la forge factice sous la forme de **deux** secrets. La charge ne ressemblait donc à
  rien, et le cas passait même sans `%q`. La fixture passe maintenant par `jq -n … --args`, et la
  charge imite une ligne du rapport, indentation comprise — sans les deux espaces de tête, l'injection
  ne se confondait avec rien.

### Un effet de bord du harnais, relevé au passage

Un cas qui sort en **code 3** pour une raison accidentelle est compté par `scripts/tests/run.sh`
comme « ignoré », pas comme un échec : un `git remote add origin` rejoué dans une boucle rend 3, et
le cas `jeton_sans_la_portee` a d'abord été compté parmi les ignorés avec « sans raison donnée ». La
mention de la raison manquante est ce qui l'a rendu visible — la règle de `shell-scripts.md` qui veut
qu'un cas ignoré « ne se taise pas » a fonctionné. Le cas bâtit maintenant son dépôt une seule fois. Rien n'est changé
au harnais ; c'est noté ici parce que la prochaine occurrence ressemblera à celle-ci.

## Sorties exactes

### Le contrôle lancé pour de vrai contre la forge, 25/09/2026

Lecture seule, non destructive, aucun secret créé ni supprimé :

```
$ scripts/release/check-forge-secrets.sh; echo "code=$?"
release/check-forge-secrets: 12 secrets attendus, 0 présents sur le dépôt, 0 variable(s).
  manquant   HUGO_LEGAL_PUBLISHER_NAME
  manquant   HUGO_LEGAL_PUBLISHER_ADDRESS
  manquant   HUGO_LEGAL_PUBLISHER_EMAIL
  manquant   HUGO_LEGAL_PUBLISHER_PHONE
  manquant   HUGO_LEGAL_PUBLISHER_REGISTRATION
  manquant   HUGO_LEGAL_HOST_NAME
  manquant   HUGO_LEGAL_HOST_ADDRESS
  manquant   HUGO_LEGAL_HOST_EMAIL
  manquant   PRIVATE_PATTERNS
  manquant   DEPLOY_SSH_KEY
  manquant   DEPLOY_HOST
  manquant   DEPLOY_KNOWN_HOSTS
release/check-forge-secrets: 12 secret(s) manquant(s) : le workflow release échouerait. Les poser : docs/procedures/serveur-de-production.md.
code=1
```

C'est exactement ce que la mesure du 25/09/2026 annonçait : aucun secret sur le dépôt, les douze
nommés comme manquants, et rien d'autre à l'écran — ni adresse de forge, ni jeton, ni valeur.

### La suite et les contrôles

```
$ bash scripts/tests/run.sh
tests: 839 cas réussis.

$ scripts/check.sh
check: 11 contrôle(s) passés, niveau standard.

$ scripts/ci/checks-job.sh
checks-job: contrôles dans alpine@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b, dépôt monté sur /repo, compte 1000:1000.
install-tools: hugo 0.166.0 et d2 0.9.0 installés dans /usr/local/bin.
checks-job-container: garde-fou public/privé sur tout l'historique.
checks-job-container: tests des scripts.
tests: 839 cas réussis.
checks-job-container: contrôles.
check: 11 contrôle(s) passés, niveau standard.
```

La suite tourne aussi dans `CHECK_IMAGE`, avec le même verdict : c'est ce que
`docs/procedures/shell-scripts.md` exige avant de livrer un script que la CI exécute.

## Revue du code

### 25/09/2026 — `39acacc` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 122. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 5bf22849425314668f226e8f

#### Rapport BMad Review

##### Lentille : edge-case-hunter

**Constat 1**
- **Location :** `scripts/tests/test-deploy-site.sh` (`case_deploy_site_aucun_nom_de_compte`)
- **Trigger condition :** Adresse réelle sans point dans le nom de domaine (ex: `compte@serveur`).
- **Guard snippet :** `shell_grep_into trouve -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+' "$fichier"`
- **Potential consequence :** Une adresse locale ou un nom d'hôte court non qualifié échappe au contrôle NFR-9 (les chevrons `<` et `>` du substitut suffisent déjà à éviter un faux positif, le point obligatoire `\.` est donc une restriction nuisible).

**Constat 2**
- **Location :** `docs/procedures/serveur-de-production.md` (étape 3)
- **Trigger condition :** Umask restrictif (ex: `077`) du compte administrateur sur le serveur de production.
- **Guard snippet :** `git archive --format=tar <commit> deploy | ssh <utilisateur-admin>@<hôte> 'sudo -u <utilisateur> tar -xf - -C ~<utilisateur>'`
- **Potential consequence :** L'exécution de `sudo -u <utilisateur> tar` recevra un « Permission denied » en tentant de lire `/tmp/deploy.tar` créé avec les droits et le umask de l'administrateur.

##### Lentille : verification-gap

**Constat 1**
- **Location :** `scripts/tests/test-deploy-site.sh` (lignes 1285-1293)
- **Trigger condition :** Absence de validation de l'existence du fichier avant l'analyse `grep`.
- **Guard snippet :** `[[ -f $fichier ]] || { printf 'fichier attendu absent : %s\n' "$fichier" >&2; exit 1; }`
- **Potential consequence :** Le contrôle réussit silencieusement si un fichier listé est renommé, déplacé ou supprimé, ouvrant une brèche dans la vérification NFR-9.
- **Gap shape :** `broken-verification-gap`
- **Consumer :** `case_deploy_site_aucun_nom_de_compte`
- **Evidence :** Le cas aîné `case_deploy_site_aucune_adresse` vérifie rigoureusement l'existence de chaque fichier avec `[[ -f $fichier ]]`, mais sa déclinaison omet cette garde vitale.

**Constat 2**
- **Location :** `scripts/release/build-image.sh`
- **Trigger condition :** Non-adoption de la nouvelle bibliothèque d'extraction de secrets `secrets_read_env_names`.
- **Guard snippet :** `secrets_read_env_names "$root/ci/legal-placeholder.env" legaux HUGO_LEGAL_`
- **Potential consequence :** Divergence potentielle de comportement si le format des fichiers `.env` évolue, en raison du maintien de deux implémentations distinctes pour la même tâche.
- **Gap shape :** `missing-adoption-gap`
- **Consumer :** `scripts/release/build-image.sh`
- **Evidence :** Bien que la PR justifie cette omission comme "hors sujet", elle crée de facto une duplication de logique métier non couverte par la nouvelle abstraction standardisée.

---

#### Revue Projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits (la procédure d'installation est détaillée et le contrôle de l'API est automatisé).
- NON BLOQUANT : Aucune donnée privée, nom d'hôte ou secret n'est commité. Le masquage des valeurs des secrets et de l'URL de la forge est validé par les tests de non-régression.
- NON BLOQUANT : Skill, procédure et scripts concordent parfaitement ; aucune commande invoquée n'est absente ou orpheline.
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions de l'`ARCHITECTURE-SPINE.md` (séparation rigoureuse des responsabilités et respect intégral de la règle NFR-9).
- BLOQUANT : Dans les scripts shell, une erreur passe en silence sous `set -euo pipefail`. Dans `scripts/tests/test-deploy-site.sh` (`case_deploy_site_aucun_nom_de_compte`), l'absence de vérification `[[ -f $fichier ]]` dans la boucle fait qu'un fichier manquant sera ignoré (le `shell_grep_into` retournera vide), validant silencieusement le test au lieu de le faire échouer.

VERDICT: BLOQUANT — Une erreur passe en silence dans les tests (fichier manquant ignoré dans case_deploy_site_aucun_nom_de_compte).

### 25/09/2026 — `0204ba8` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 122. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a44323ca4f9f662a73533bff

###### Rapport BMAD Review

##### Lentille : edge-case-hunter
NON BLOQUANT : Les limites de l'API Gitea (pagination non gérée par choix délibéré) et les entrées vides sont traitées explicitement, ce qui garantit que le contrôle ne validera pas un succès sur la base d'une réponse partielle ou illisible.
NON BLOQUANT : La génération de la clé SSH dans la procédure manuelle utilise `umask 077` et un répertoire temporaire supprimé en fin de procédure, ce qui évite de laisser persister une donnée sensible sur le disque.

##### Lentille : verification-gap
NON BLOQUANT : L'omission de vérification d'existence du fichier `[[ -f $fichier ]]` a bien été corrigée dans les deux tests ciblés (`case_deploy_site_aucune_adresse` et `case_deploy_site_aucun_nom_de_compte`), verrouillant ainsi la conformité NFR-9 sans risque de validation silencieuse.
NON BLOQUANT : Le JSON renvoyé par la forge est activement validé (`type == "array"` et lecture explicite de la longueur) avant toute boucle, éliminant tout risque d'interprétation erronée d'une erreur serveur (code 200 avec structure inattendue).

###### Couche propre au projet

NON BLOQUANT : Les critères d'acceptation de la story 11.6 sont satisfaits (la procédure d'installation est clairement établie et le contrôle automatisé des secrets de l'API est implémenté et rigoureusement testé).
NON BLOQUANT : Aucune donnée privée, adresse IP, ni nom de compte n'est commité en clair, et le script API n'affiche jamais l'URL de la forge (respect absolu de la consigne NFR-9). 
NON BLOQUANT : Skill, procédure et scripts concordent parfaitement. Les étapes manuelles de `serveur-de-production.md` font appel aux mêmes chemins et concepts que ceux déployés et automatisés par la CI.
NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture, notamment en garantissant une source unique pour les noms des secrets de livraison (`ci/release-secrets.txt`).
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Les boucles de lecture gèrent correctement les EOF et la garde sur l'existence des fichiers a été rétablie dans la boucle `while`.

VERDICT: NON BLOQUANT — aucune

## Décisions

Les décisions du triage de la revue de spec (A1 à A4, S1, S2, P1, P2) et celle des douze secrets ont
été appliquées telles quelles, sans être rejugées. S'y ajoutent celles que l'implémentation a
demandées :

| # | Décision | Pourquoi |
| --- | --- | --- |
| I1 | Les quatre noms vivent dans `ci/release-secrets.txt`, lu par `ship.sh` et par le contrôle ; leur lecture vit dans `scripts/lib/secrets.sh` | Le brief demandait une source unique. Une parade s'écrit une fois : deux scripts liraient sinon le même fichier avec deux analyseurs. |
| I2 | La copie du YAML reste, tenue par un cas de test qui lit les **deux** sources | Un workflow d'Actions ne lit aucun fichier du dépôt. C'est le partage déjà appliqué aux huit valeurs légales. |
| I3 | `build-image.sh` n'est pas converti à `secrets_read_env_names` | Hors sujet de la story, et ses messages sont affirmés mot pour mot par ses propres cas. La liste des noms, elle, est bien à un seul endroit. |
| I4 | La pagination n'est pas gérée ; au-delà de 20 entrées, le contrôle **refuse de conclure** (code 2) | Sa forme n'a pas pu être mesurée : le dépôt n'avait aucun secret le jour de la mesure. Le projet s'est déjà fait prendre par une pagination supposée (story 0.8). Déclarer manquant ce qui serait sur la page suivante serait le pire résultat. |
| I5 | Les noms venus de la forge s'affichent par `printf '%q'` | Ils ne viennent pas du dépôt. Même garde que `deploy/remote/deploy-site.sh` pour un mot venu du réseau ; la mutation M15 montre ce qu'un saut de ligne ferait sans elle. |
| I6 | La clé privée n'est gardée nulle part sur le poste après l'installation | Une clé perdue se refabrique en cinq minutes ; une copie gardée est un endroit de plus d'où elle peut fuir. La procédure crée, pose, puis efface. |
| I7 | Les huit valeurs légales se posent par l'interface, les quatre autres par l'API | Les huit tiennent sur une ligne et se copient depuis `docs/private/legal-release.env` ; les quatre autres viennent de fichiers, et l'API évite de manipuler une clé privée à la souris. Dans les deux cas, aucune valeur ne passe par un argument de commande. |
| I8 | Le tunnel de la répétition passe par le compte d'administration | `restrict` coupe la redirection de ports, ce que le quatrième essai vérifie exprès. AD-22 et le premier critère de cette story ne se contredisent pas : ils parlent de deux comptes. |

## Décisions de l'orchestrateur

### Le port SSH — arbitrage d'Arnaud, 25/09/2026

La sous-tâche a relevé que `DEPLOY_HOST` porte `utilisateur@hôte` **sans port**, et que
`scripts/release/ship.sh` ne passe aucun `-p`. Un serveur écoutant ailleurs qu'en 22 aurait fait
échouer le workflow `release` **au premier tag**, après dix minutes de contrôles et de construction
d'image — et le message n'aurait pas dit pourquoi.

La question a été posée à Arnaud plutôt que tranchée : c'est un fait sur son infrastructure, que
personne ne peut déduire du dépôt. **Réponse : le port 22.** Rien à changer ; le prérequis reste
écrit dans la procédure, parce qu'un lecteur futur n'aura pas cette conversation.

Les deux autres options lui ont été présentées — un secret `DEPLOY_PORT`, ou `utilisateur@hôte:port`
accepté dans `DEPLOY_HOST` — ainsi que la possibilité de reporter la question dans
`open_questions` si le serveur n'était pas encore choisi.

### La contradiction apparente entre AD-22 et le premier critère

AD-22 fait vérifier la répétition par un tunnel (`ssh -L 18080:…`), et le premier critère de cette
story exige qu'une **redirection de port soit refusée**. La sous-tâche a vérifié dans `man sshd`
(OpenSSH 9.6p1) que `restrict` refuse effectivement le `-L`, puis a résolu la contradiction : le
tunnel passe par le **compte d'administration**, jamais par le compte de déploiement.

**Accepté.** Les deux règles sont justes et portent sur deux comptes différents ; ni AD-22 ni
`docs/procedures/deploy-site.md` ne le disaient, et c'est cette omission qui les faisait paraître
contradictoires. La procédure le dit, `deploy-site.md` gagne le paragraphe, et l'artefact de
planification n'est pas réécrit depuis une story.

### Les trois mutations qui ont fait corriger les tests, pas le code

La sous-tâche rapporte que trois mutations sur vingt et une ne tombaient pas au premier essai, et
que les trois ont fait corriger **le test**. La troisième mérite d'être citée : **la fixture ne
fabriquait pas ce qu'elle prétendait** — `printf | jq -R` lit ligne par ligne, si bien que le « nom
hostile » arrivait sous forme de deux secrets distincts. C'est exactement le point 16 d'`AGENTS.md`,
et c'est la deuxième fois de l'epic qu'une fixture est prise en défaut de cette façon.

Relevé au passage, et qui dépasse la story : **un cas sortant en code 3 est compté « ignoré » par
`scripts/tests/run.sh`, pas en échec.** La sous-tâche l'a vu parce que la mention « sans raison
donnée » l'a rendu visible. Ce n'est pas un défaut de cette story, et ce n'est pas son périmètre :
entrée dans `deferred-work.md`.

### Vérification du travail de la sous-tâche (point 22)

Rejoué par l'orchestrateur, sans reprendre ses mesures :

| Vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 839 cas réussis |
| `scripts/check.sh` | 11 contrôles, code 0 |
| **secrets sur la forge après le travail de la sous-tâche** | **0** — rien n'a été créé, modifié ni supprimé |
| `scripts/release/check-forge-secrets.sh` contre la forge réelle | code 1, les **douze** nommés manquants, aucune adresse ni jeton à l'écran |
| NFR-9 : adresse IPv4 dans la nouvelle procédure | **aucune** |
| substituts employés | `<utilisateur>`, `<utilisateur-admin>`, `<hôte>`, `<réseau-du-proxy>`, `<dossier>`, `<commit>`, `<tag>` |

La procédure donne pour chaque étape sa commande **et** son attendu, avec un « sinon, s'arrêter »
là où continuer serait pire que renoncer — la forme de `gitea-pre-receive-hook.md`, qui est le
précédent exact de cette story.

### Triage de la revue du code (`39acacc`, verdict `block`)

**B1 — `case_deploy_site_aucun_nom_de_compte` n'a pas la garde `[[ -f $fichier ]]` de son aîné.
RETENU, et le verdict bloquant est mérité.** Sans elle, un fichier renommé ou déplacé ne produit
aucune correspondance et le cas **passe au vert sur un contrôle qui n'a rien lu**. C'est le point 19,
et il mord ici d'une façon particulièrement ironique : le commentaire du cas **cite** le point 19
pour expliquer qu'il reprend une leçon de son jumeau `test-ship.sh`… en oubliant une garde de son
voisin immédiat, dix-huit lignes plus haut, dans le même fichier. La leçon ne se porte pas toute
seule, pas même d'une fonction à la suivante.

**E1 — le motif exige un point dans la partie droite, donc `compte@serveur` passe. RETENU.** Un nom
d'hôte court est la norme sur un réseau local, et c'est précisément le cas d'un homelab. Le point
n'était là que pour éviter un faux positif sur `<utilisateur>@<hôte>` — or les chevrons suffisent,
`<hôte>` commençant par un caractère hors de la classe. Vérifié après correction :

```
$ (ligne « compte@serveur » ajoutée à la procédure)
compte@serveur écrit en clair dans docs/procedures/serveur-de-production.md (NFR-9) : compte@serveur
rc=1
```

**E2 — le fichier intermédiaire `/tmp/deploy.tar` et l'`umask` du compte d'administration. RETENU.**
Un `umask 077` lui donnerait des droits que `<utilisateur>` ne peut pas lire, et le `tar` suivant
échouerait sur « Permission denied » — d'autant plus déroutant que la commande **précédente** aurait
réussi. L'archive se déplie désormais depuis l'entrée standard, en une seule commande : plus de
fichier intermédiaire, et rien à nettoyer. Le relecteur avait la bonne forme.

**G2 — `scripts/release/build-image.sh` n'adopte pas `secrets_read_env_names`. REPORTÉ, avec sa
raison.** Le constat est juste sur le fond — deux implémentations lisent aujourd'hui un fichier
dotenv — mais il faut distinguer ce que le point 19 vise : **la liste des noms est bien à un seul
endroit** (`ci/legal-placeholder.env`), et c'est elle qui, dupliquée, avait coûté cher au projet.
Ce qui reste en double est la mécanique de lecture, pas la vérité.

Convertir `build-image.sh` maintenant toucherait un script de mise en ligne livré et éprouvé, dont
les tests affirment les messages **mot pour mot**, pour un gain de cohérence et aucun gain de
sûreté — dans la même PR qu'un verdict bloquant à corriger. Entrée dans `deferred-work.md`, à
reprendre dans une story qui rouvre déjà ce script.

**Les quatre lignes de la couche projet** sont des confirmations : critères tenus, aucune donnée
privée, skill/procédure/scripts concordants, cohérence avec `AGENTS.md` et l'architecture.

### Triage de la troisième revue du code (`0204ba8`)

**Aucun constat.** Les neuf lignes sont des confirmations, et trois d'entre elles portent
explicitement sur ce que la revue précédente avait bloqué ou signalé : la garde `[[ -f $fichier ]]`
est « bien corrigée dans les deux tests ciblés », la pagination non gérée est « traitée
explicitement » plutôt que subie, et le JSON de la forge est validé (`type == "array"`) avant toute
boucle — de sorte qu'une réponse inattendue en HTTP 200 ne soit pas lue comme une liste vide.

Rien à retenir, rien à reporter.
