# Story 11.8 : Rehearse-release skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.8.

Huitième story de l'epic 11, dont l'en-tête (point 21) veut la chaîne de mise en ligne
**répétée tôt sur le serveur de production, sans DNS**. C'est la story qui écrit cette répétition —
son exécution réelle est la 11.9.

## Ce dont elle dépend, et qui est livré

Ses deux dépendances sont closes : la **11.6** (procédure du serveur, contrôle des douze secrets) et
la **11.7** (skill `release`). S'y ajoutent, du même epic :

- `deploy/remote/deploy-site.sh` (11.4) : `rehearse deploy|rollback|stop`, le canal de répétition
  — projet `site-rehearsal`, hors du réseau du proxy, publié sur `127.0.0.1:18080` **seulement** ;
- `scripts/release/ship.sh` et `.gitea/workflows/release.yaml` (11.5) : un tag `-rc.N` sur `dev`
  déclenche la même chaîne que la production, mais vers le canal de répétition ;
- `scripts/lib/release.sh` (11.7) : les expressions des deux canaux, partagées.

## Ce que la story écrit, et ce qu'elle n'exécute pas

Elle livre le skill `rehearse-release` en trois niveaux, plus ses tests. **Elle ne pose aucun tag
réel et ne touche à aucun serveur** : la spec dit « l'exécution réelle est la story 11.9 ».

Le script, lui, enchaîne : tag `-rc.1` sur `dev`, tunnel SSH, vérifications, tag `-rc.2`,
`rehearse rollback` vers `-rc.1`, vérifications, `rehearse stop`.

## Deux points que la 11.6 a déjà tranchés et qu'il ne faut pas rouvrir

- **Le tunnel passe par le compte d'administration**, jamais par le compte de déploiement : la clé
  de déploiement est restreinte par `restrict`, qui **refuse** une redirection de port — c'est le
  premier critère d'acceptation de la story 11.6, et les quatre essais de sa procédure le
  vérifient. AD-22 et ce critère ne se contredisent qu'en apparence : ils portent sur deux comptes.
- **Le port SSH est le 22** (arbitrage d'Arnaud, 25/09/2026) : `DEPLOY_HOST` porte
  `utilisateur@hôte`, sans port.

## Les en-têtes qu'AD-13 fait vérifier

Relevés dans `deploy/nginx/site.conf` plutôt que recopiés de mémoire :
`X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`,
`Content-Security-Policy` (envoyée **sur le HTML seulement** — une valeur vide supprime l'en-tête,
et un SVG n'en porte donc pas), et `Cache-Control` (un an et `immutable` pour un fichier empreinté
d'un condensat, `no-cache` pour tout le reste).

## Revue de spec

### 25/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `c233ca3`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c0c0d83c9696a5f074e42bf0

##### Rapport de revue (Story 11.8)

**Lentille : Adversarial**

* **BLOQUANT** — `location`: Ligne 17. `trigger_condition`: Le critère Étant donné omet le fichier de skill (`.claude/skills/rehearse-release/SKILL.md`) et ses liens symboliques. `guard_snippet`: Ajouter l'exigence de la structure à trois niveaux du skill, comme dicté par les conventions du projet. `potential_consequence`: Le skill n'est pas exposé correctement aux agents.
* **BLOQUANT** — `location`: Ligne 19. `trigger_condition`: Le script exécute le tunnel SSH et les vérifications `curl` immédiatement après la pose du tag sur `dev`. `guard_snippet`: Le script doit s'assurer d'attendre (polling) que le workflow Gitea (`release.yaml`) ait terminé le build et le déploiement avant de lancer les tests. `potential_consequence`: Les requêtes échouent car la nouvelle image n'est pas encore en ligne.
* **BLOQUANT** — `location`: Ligne 19. `trigger_condition`: La commande `ssh -L 18080:127.0.0.1:18080` bloque l'exécution du script si elle n'est pas exécutée en arrière-plan. `guard_snippet`: Exiger le lancement du tunnel en arrière-plan (ex: options `-f -N`) et la fermeture garantie de ce processus à la fin (`trap`). `potential_consequence`: Le script se fige au lancement du tunnel.
* **BLOQUANT** — `location`: Ligne 19. `trigger_condition`: Le compte et l'hôte utilisés pour le tunnel SSH et la lecture des logs ne sont pas nommés. NFR-9 interdisant les valeurs en dur, et la clé de déploiement interdisant les tunnels, le script a besoin d'une variable. `guard_snippet`: Préciser quelle variable d'environnement issue de `.env` porte le compte d'administration (ex: `ADMIN_HOST`). `potential_consequence`: Implémentation avec une adresse codée en dur (violation NFR-9) ou utilisation de `DEPLOY_HOST` (rejet par le serveur).
* **BLOQUANT** — `location`: Ligne 19. `trigger_condition`: Les numéros de tag `-rc.1` et `-rc.2` sont codés en dur dans le critère, ce qui contredit la ligne 26 ("vaut pour tout tag vX.Y.Z-rc.N"). `guard_snippet`: Définir les paramètres d'entrée du script pour qu'il calcule dynamiquement le tag courant et le tag suivant. `potential_consequence`: Le script final ne sera capable de jouer la répétition que pour les tags `rc.1` et `rc.2`.
* **BLOQUANT** — `location`: Ligne 19. `trigger_condition`: La méthode d'appel de `rehearse rollback` n'est pas précisée. `guard_snippet`: Expliciter que le script doit appeler le script distant via une commande SSH utilisant la clé de déploiement (ex: `ssh $DEPLOY_HOST rehearse rollback <tag>`). `potential_consequence`: Le développeur risque d'invoquer la commande de la mauvaise façon.
* **BLOQUANT** — `location`: Lignes 19 et 23. `trigger_condition`: Le comportement en cas d'échec d'un `curl` n'est pas défini. `guard_snippet`: Exiger un mécanisme (`trap`) qui s'assure d'exécuter `rehearse stop` et de tuer le tunnel SSH même si le script s'arrête prématurément sur une erreur. `potential_consequence`: Un script qui plante laisse un tunnel ouvert sur le poste et un environnement de répétition orphelin tournant en production.
* **BLOQUANT** — `location`: Ligne 23. `trigger_condition`: Le script est local, le tunnel n'expose que le port HTTP (18080), il est donc impossible d'exécuter `docker logs` localement pour lire les logs du conteneur distant. `guard_snippet`: Préciser que la récupération des logs doit se faire par une commande SSH distante en utilisant le compte d'administration. `potential_consequence`: Le script échouera en essayant de joindre le démon Docker local.
* **BLOQUANT** — `location`: Ligne 23. `trigger_condition`: "un HTML, un SVG s'il existe, une 404". Les cibles exactes pour `curl` ne sont pas définies. `guard_snippet`: Fournir les chemins URI concrets que le script doit interroger. `potential_consequence`: Le script effectue des tests non déterministes ou oublie des chemins pertinents.

**Lentilles : Structure et Prose**

| Pass | Original Text | Revised Text | Changes | Classement |
|---|---|---|---|---|
| structure | §Critères d'acceptation, Ligne 19 : "Alors ils enchaînent : tag -rc.1 posé sur dev, tunnel SSH, vérifications, tag -rc.2 sur dev, rehearse rollback vers -rc.1, vérifications, rehearse stop." | Transformer ce long bloc en une liste à puces numérotée. | Sépare les nombreuses étapes pour une lecture et une vérification plus claires des actions séquentielles attendues du script. | NON BLOQUANT |
| prose | Ligne 23 : "un SVG s'il existe" | "un SVG (s'il existe)" | Ajout de parenthèses pour fluidifier la lecture. | NON BLOQUANT |


##### À trancher avant d'implémenter

- **Paramètres du script** : Le script prendra-t-il le tag de base (`vX.Y.Z-rc.N`) en argument afin de déterminer dynamiquement le tag suivant (N+1) et le rollback, ou bien ces comportements doivent-ils être déduits autrement ?
- **Variables d'administration** : Quelle variable de `.env` devra être utilisée pour la connexion SSH au compte d'administration (permettant de créer le tunnel et de lire les logs Docker) ?
- **Attente asynchrone** : Faut-il implémenter une boucle de polling dans le script local pour attendre que le tag poussé termine d'être déployé par la CI avant de lancer les vérifications `curl` ?
- **Nettoyage et résilience** : Confirmez-vous que le script doit inclure un bloc de nettoyage inconditionnel (`trap`) assurant la destruction du tunnel SSH local et le déclenchement distant de `rehearse stop`, même en cas d'échec en plein milieu des tests ?

### Triage des constats (point 20 : chacun reçoit sa décision)

| # | Constat | Décision |
| --- | --- | --- |
| A1 | Le `SKILL.md` et les liens symboliques manquent aux critères | **Retenu**, comme à la story 11.7 : trois niveaux plus deux liens symboliques relatifs. Le projet l'exige de tout skill. |
| A2 | Rien n'attend que le déploiement ait eu lieu avant les vérifications | **Retenu, et c'est le constat le plus utile des neuf.** Sans attente, les `curl` tombent sur l'image précédente ou sur rien. **Mais pas par l'API de la forge** : le script attend en interrogeant `deploy-site status` jusqu'à y voir le tag attendu en service, avec un délai maximal et un message qui dit quoi faire s'il expire. C'est l'**état vrai** — ce que le serveur sert — et non l'état d'un run ; et cela ne dépend pas de la forge, qu'AD-14 prévoit de voir tomber. C'est cohérent avec la story 11.7, où `release` refuse de suivre un run et renvoie à `status`. |
| A3 | `ssh -L` bloque le script | **Retenu** : `-f -N`, le PID retenu, et le tunnel tué par le `trap`. |
| A4 | Rien ne nomme le compte d'administration | **Retenu.** Décision : **`ADMIN_HOST`**, dans `.env`, au format `utilisateur@hôte` — le même que `DEPLOY_HOST`, pour qu'il n'y ait qu'une convention à retenir. Jamais commitée. `.env.example` la nomme sans valeur. C'est la seule variable nouvelle de cette story, et Arnaud devra la poser avant la 11.9. |
| A5 | `-rc.1` et `-rc.2` sont en dur, ce qui contredit « vaut pour tout tag » | **Retenu** : le script prend le tag de base en argument et calcule le suivant. `scripts/lib/release.sh` (story 11.7) porte déjà l'expression des tags de répétition : il la lit, il ne la réécrit pas. |
| A6 | La façon d'appeler `rehearse rollback` n'est pas dite | **Retenu** : par `ssh` avec la clé de **déploiement**, comme `scripts/release/ship.sh` — c'est le canal restreint, et c'est tout l'intérêt de `restrict`. Le compte d'administration ne sert qu'au tunnel et aux journaux. |
| A8 | `docker logs` ne peut pas tourner en local | **Retenu**, et le constat est juste : le tunnel ne transporte que le HTTP. Les journaux se lisent par `ssh <ADMIN_HOST> docker logs …`. |
| A9 | Les cibles des `curl` ne sont pas définies | **Retenu.** Cibles arrêtées, toutes déterministes : l'accueil `/`, l'accueil anglais `/en/`, une URL absente en FR et une en EN (pour les deux 404), et **un fichier empreinté relevé dans la page d'accueil servie** — c'est le seul moyen de vérifier le `Cache-Control: immutable` sans supposer un nom de fichier. Le SVG reste conditionnel : il n'y en a pas encore sur le site. |
| S1, P1 | Faire du bloc une liste numérotée ; « un SVG (s'il existe) » | **Retenus** dans la rédaction de la procédure, sans réécrire `epics.md`. |

### A7 — le nettoyage après un échec : je diverge du relecteur, et voici pourquoi

Le relecteur demande un `trap` qui, en cas d'échec, tue le tunnel **et** lance `rehearse stop`. Je
retiens la première moitié et **refuse la seconde**.

Le tunnel est un processus **sur le poste** : le laisser ouvert est un déchet, et le `trap` le tue
toujours. `rehearse stop`, lui, arrête le projet distant **et supprime toutes les images `-rc`**
(story 11.4). Le lancer automatiquement après un échec **détruirait exactement ce qu'il faut
inspecter** : le conteneur qui tournait, ses journaux, l'image qui a servi. Une répétition qui rate
est précisément le moment où l'on veut regarder.

Le canal de répétition est par ailleurs **isolé** — projet Compose distinct, hors du réseau du
proxy, publié sur `127.0.0.1:18080` seulement (AD-22) : un conteneur de répétition qui survit à un
échec ne « tourne pas en production », contrairement à ce que le constat suppose. Il ne gêne rien.

**Décision :** le `trap` tue le tunnel, puis **dit** que la répétition tourne encore et donne la
commande exacte pour l'arrêter. Un nettoyage qui détruit les preuves est pire que pas de nettoyage
du tout, et le script n'a pas à choisir à la place de celui qui enquête.

## Ce qui est livré

Le skill en trois niveaux, plus ses tests :

| Fichier | Rôle |
| --- | --- |
| `.claude/skills/rehearse-release/SKILL.md` | l'unique copie du skill |
| `.agents/skills/rehearse-release`, `.agent/skills/rehearse-release` | liens symboliques **relatifs** (`../../.claude/skills/rehearse-release`), forme exacte de `release` |
| `docs/procedures/rehearse-release.md` | la procédure, qui fait foi |
| `scripts/rehearse-release.sh` | l'exécution |
| `scripts/tests/test-rehearse-release.sh` | 55 cas hors ligne |
| `.env.example` | `ADMIN_HOST=` et `DEPLOY_HOST=`, nommées sans valeur |

Trois fichiers existants changent, et chacun pour une raison écrite :

- `scripts/tests/test-deploy-site.sh` : ses deux cas NFR-9 (`aucune_adresse`, `aucun_nom_de_compte`)
  couvrent maintenant les quatre fichiers de cette story, `.env.example` compris — c'est le fichier
  qui *invite* à écrire une valeur réelle. Étendre la liste existante plutôt que d'en écrire une
  seconde ailleurs est le point 19 appliqué à un contrôle ;
- `scripts/checks/content.sh` : C18 compare `.env.example` à une liste **exacte** de noms. Deux noms
  s'y ajoutent, sinon le contrôle refuse le fichier. Constaté en lançant la suite, pas supposé ;
- `AGENTS.md` : « until the last two exist, apply their rules by hand » devient « until `hotfix`
  exists » — point 8, une phrase au futur que cette story rend fausse se corrige dans sa propre PR.

Le script enchaîne exactement ce que la spec demande : tag `-rc.N` sur `origin/dev` et poussé →
attente par `deploy-site status` → tunnel → vérifications → tag `-rc.N+1` → attente → vérifications →
`rehearse rollback` vers `-rc.N` → attente → vérifications → `rehearse stop`. Sans `--run`, il
vérifie tout et n'agit sur rien.

## Le brief des jumeaux (point 19)

**L'aîné est `scripts/release.sh`** (story 11.7), le skill le plus récent. Ses sept gardes, une par
une :

| # | Garde de l'aîné | Le cadet en a-t-il besoin ? |
| --- | --- | --- |
| 1 | **Refus avant tout effet de bord**, et le message le dit (« Rien n'a été fait »). | **Oui, tel quel, et c'est la garde la plus chargée ici** : usage, canal du tag, numéro démesuré, outils, dépôt canonique, `.env` et ses deux destinations, **port local libre**, deux tags libres — tout précède le premier `git push`. Le contrôle du port est propre au cadet : un service local qui répondrait sur 18080 ferait vérifier *lui* au lieu du serveur. `aucun_effet_de_bord` (aucun push, aucun tag, aucun ssh) est affirmé dans **onze** cas. |
| 2 | **Tag validé par une expression ancrée** avant tout usage, tag déjà existant refusé, code de `git rev-parse` lu et jamais avalé par `\|\| true`. | **Oui, tel quel**, et **doublé** : le cadet exige libres **les deux** tags, le donné et le calculé, avant le premier push — découvrir le second occupé après avoir poussé le premier laisserait une répétition à moitié jouée (`rehearse_tag_deja_pose` boucle sur les deux). Les expressions sont celles de `scripts/lib/release.sh`, **réutilisées et non recopiées**. Garde ajoutée, que l'aîné n'avait pas à avoir : le numéro est calculé, donc sa **longueur** est bornée — `$((numero + 1))` sur vingt chiffres déborderait en silence. |
| 3 | **`git fetch` explicite** avant de juger l'état des branches. | **Oui, avec `--tags`** : c'est le tag, et non la branche, que le cadet juge. Un tag jugé libre sur un dépôt qui n'a pas relu ses références est peut-être déjà posé sur la forge (`rehearse_fetch_explicite`, `rehearse_fetch_en_echec`). |
| 4 | **Aucune URL de la forge affichée** : le chemin, jamais l'adresse. | **Oui**, et par un chemin différent : le cadet n'appelle pas l'API — il n'y a donc aucun message de forge à filtrer. L'adresse entrerait par la **sortie d'erreur de `git fetch` et de `git push`**, qui portent l'URL du distant : les deux l'écartent, et `rehearse_aucune_adresse_de_forge` lit les appels du script, pas les lignes qui en parlent. Le renvoi vers le run est « l'onglet Actions du dépôt sur la forge », jamais une URL. |
| 5 | **Codes 0 / 1 / 2** et un rapport lisible même quand tout passe. | **Oui, tel quel** : 0 la répétition entière et vérifiée, 1 refus ou vérification en échec, 2 anomalie. Le rapport est double — une ligne `ok`/`ÉCHEC`/`sans objet` par contrôle à chaque tournée, puis un récapitulatif final (`rehearse_sequence_nominale` l'affirme). |
| 6 | **Pas de `exec`** quand un `trap … EXIT` doit tourner. | **Oui, et davantage** : chez l'aîné, `exec` perdrait le nettoyage d'un dossier temporaire ; ici il perdrait **le tunnel**, un processus laissé ouvert sur le poste. `rehearse_aucun_exec` refuse tout `exec` du script, et `rehearse_sequence_nominale` va plus loin en constatant que le PID du tunnel est bien mort après coup. |
| 7 | **`--merge` n'est jamais déduit** : une action irréversible se demande. | **Oui, et l'irréversible du cadet est le tag poussé** — la forge le voit, le miroir public aussi, et le workflow `release` part. D'où `--run`, jamais déduit (`rehearse_audit_ne_fait_rien`), et un audit qui affiche le programme complet avant de s'arrêter. Le cadet n'a pas d'option `--force` et n'écrase aucun tag. |

Ce que l'aîné a et que le cadet **ne reprend pas**, avec la raison :

- **l'invariant `main` ancêtre de `dev`, la PR de publication et les cinq verrous** : une répétition
  ne publie rien. Elle pose un tag sur `dev`, ce qu'AD-22 demande explicitement, et ne touche ni à
  `main` ni à la forge autrement que par un `push` de tag ;
- **`load_gitea_env`, `gitea_api`, `check_token_owner`, `jq`** : aucun appel à l'API. L'attente passe
  par le serveur (décision A2), donc le jeton de la forge n'est pas même lu. De `lib/gitea.sh`, le
  cadet ne prend que `check_origin` — **réutilisé**, pas recopié ;
- **la liste des motifs privés** : l'aîné compose un titre et un corps de PR qui partent sur la
  forge. Le cadet n'envoie aucun texte : un message de tag (`Répétition générale <tag>`) fait de la
  seule constante et du tag validé.

Garde que le cadet ajoute et qu'aucun aîné n'avait : **l'identifiant de conteneur revient du serveur
et repart dans une commande distante**. Il est confronté à `^[0-9a-f]{12,64}$` avant d'y entrer,
comme `deploy/remote/deploy-site.sh` le fait d'un tag venu du réseau.

**Pour les tests, l'aîné est `scripts/tests/test-ship.sh`** (story 11.5), et `scripts/tests/test-release.sh`
en second. Gardes reprises : faux binaires en tête de `PATH` qui enregistrent leurs appels et
**échouent bruyamment** plutôt que d'avaler une erreur (`|| { echo …; exit 97; }` — le `|| true` qui
a valu un verdict bloquant à la PR n° 120 n'existe nulle part ici) ; affirmation du code de sortie
**avant** de compter quoi que ce soit ; vérification qu'aucun effet de bord n'a eu lieu après un
refus ; environnement réduit par `env -i` ; `TMPDIR` qui n'appartient qu'au cas, dont on compte les
restes ; marqueur qui ne doit apparaître ni dans un message ni sous `bash -x` ; comparaison littérale
d'une constante entre fichiers qui ne peuvent pas la partager (`depot_image`, `projet_repetition`,
le port). De `test-release.sh` : dépôt git réel et jetable, faux git qui ne dévie que pour `fetch` et
`push`, faux `sleep` qui note l'attente au lieu de la subir.

Deux gardes de `test-ship.sh` **méritaient d'être reprises et ne l'avaient pas été** — c'est la
mutation qui l'a dit, pas la relecture : `case_ship_variables_absentes` affirme le message de **la
garde éprouvée** et non un mot que le contrôle suivant produirait aussi. Deux cas du cadet faisaient
exactement cette erreur (voir les mutations ci-dessous).

Gardes ajoutées, qu'aucun aîné n'avait : un faux `ssh` qui **survit** quand on lui demande un tunnel
(il écrit son PID et dort), sans quoi aucun cas ne pourrait constater que le piège l'a tué ; un faux
`curl` qui **ne répond que lorsque le tunnel est ouvert**, comme un port que personne n'écoute ; une
réinitialisation complète de l'état entre deux itérations d'un cas qui boucle — un `tunnel-ouvert`
oublié faisait refuser l'itération suivante sur le port local, et le cas concluait sur un refus qui
n'était pas le sien (constaté en lançant la suite).

## Les mutations (point 9)

Chaque garde a été retirée ou inversée, une à la fois, et la suite rejouée. **Deux mutations ne sont
pas tombées au premier passage** ; les deux tests fautifs ont été corrigés, et les 32 mutations
tombent maintenant.

| Mutation | Cas qui tombe |
| --- | --- |
| M1 garde du tag de répétition retirée | `rehearse_tags_refuses` |
| M2 garde du croisement des canaux retirée | `rehearse_tag_de_production_refuse` |
| M3 borne du numéro retirée | `rehearse_numero_demesure` |
| M4 `check_origin` retiré | `rehearse_depot_inconnu` |
| M5 contrôle du port local retiré | `rehearse_port_deja_occupe` |
| M6 second tag non exigé libre | `rehearse_tag_deja_pose` |
| M7 `--tags` retiré du `fetch` | `rehearse_fetch_explicite` |
| M8 garde du tiret de tête retirée | `rehearse_destination_qui_commence_par_un_tiret` |
| M9 format de la destination non vérifié | `rehearse_destination_mal_formee` |
| M10 destination absente tolérée | `rehearse_variable_absente`, `rehearse_variable_vide` |
| M11 attente du tag supprimée | `rehearse_attente_avant_les_verifications` |
| M12 jeton comparé par sous-chaîne | `rehearse_attente_ne_confond_pas_rc1_et_rc11` |
| M13 échecs consécutifs de `status` non comptés | `rehearse_status_muet_trois_fois` |
| M14 CSP non exigée sur le HTML | `rehearse_csp_exigee_sur_le_html` |
| M15 CSP tolérée hors du HTML | `rehearse_csp_interdite_hors_du_html` |
| M16 **CSP exigée partout** | `rehearse_un_svg_sans_csp_passe` |
| M17 `Cache-Control` non déduit du nom | `rehearse_cache_control_du_fichier_empreinte` |
| M18 absence de fichier empreinté tolérée | `rehearse_aucun_fichier_empreinte` |
| M19 langue de la page non vérifiée | `rehearse_les_deux_404` |
| M20 code HTTP non vérifié | `rehearse_404_qui_repond_200` |
| M21 `nosniff` et `Referrer-Policy` non vérifiés | `rehearse_entetes_communs_manquants` |
| M22 version dans `Server` tolérée | `rehearse_version_de_nginx_dans_server` |
| M23 recherche d'IP désactivée | `rehearse_journal_avec_une_ip`, `rehearse_journal_ipv6` |
| M24 **motif d'IP trop large** (IPv6 sans `::`) | `rehearse_journal_sans_ip_ne_leve_rien` |
| M25 identifiant de conteneur non ancré | `rehearse_identifiant_de_conteneur_illisible` |
| M26 le piège ne tue pas le tunnel | `rehearse_sequence_nominale`, `rehearse_un_echec_narrete_pas_la_repetition` |
| M27 **le piège lance `rehearse stop`** (ce que A7 refuse) | `rehearse_un_echec_narrete_pas_la_repetition` |
| M28 `--run` déduit | `rehearse_audit_ne_fait_rien` |
| M29 `set +x` retiré | `rehearse_aucune_trace_de_shell` |
| M30 sortie d'erreur de `git push` non écartée | `rehearse_aucune_adresse_de_forge` |
| M31 tag local gardé après un push raté | `rehearse_push_en_echec_retire_le_tag_local` |
| M32 retour arrière refusé toléré | `rehearse_rollback_refuse` |

**M16 et M24 sont les deux mutations à l'envers**, et elles valent les trente autres : elles
n'enlèvent pas une garde, elles la rendent **trop stricte**. M16 exige la CSP partout — un SVG
parfaitement conforme échoue alors, puisque le `map` de nginx la supprime hors du HTML. M24 élargit
le motif d'IP jusqu'à ce qu'un horodatage `25/Sep/2026:14:03:11` ressemble à une IPv6 abrégée : le
skill refuserait alors tout journal. Les deux cas qui tombent sont ceux qui affirment qu'un site
**conforme passe**, et c'est le point 11 — mesurer aussi ce qui ne doit pas échouer.

### Les deux mutations qui ne tombaient pas, et ce qu'elles ont corrigé

Les deux sont la **même faute**, et c'est celle que `test-ship.sh` documente depuis la story 11.5 :
affirmer un mot que la garde *suivante* produirait aussi.

1. **M2, garde du croisement des canaux.** `v1.0.0` retombe sur le contrôle « ce n'est pas un tag de
   répétition », dont le message contient l'usage — donc la chaîne `rehearse-release.sh`, donc le mot
   `release`, que le cas affirmait. Le cas affirme désormais `se pose sur main par le skill release`,
   propre à cette garde-ci.
2. **M10, destination absente de `.env`.** Une destination absente est aussi une destination mal
   formée : le contrôle de forme la refusait, en nommant la variable — ce que le cas affirmait. Les
   deux cas affirment désormais `absente de .env`, propre au refus de l'absence.

Sans ces deux corrections, deux gardes du script ne gardaient rien : retirées, la suite restait
verte. C'est exactement ce que les stories 11.5 et 11.6 avaient trouvé cinq fois.

## Vérifications

Toutes lancées sur le poste, sans réseau, sans serveur, sans tag posé nulle part.

```
$ bash scripts/tests/run.sh
tests: 894 cas réussis.

$ scripts/check.sh
[…]
check: 11 contrôle(s) passés, niveau standard.

$ scripts/rehearse-release.sh
rehearse-release: usage : rehearse-release.sh <tag vX.Y.Z-rc.N> [--run]
code=2

$ scripts/rehearse-release.sh v1.2.3-rc
rehearse-release: tag v1.2.3-rc refusé : une répétition générale porte « vX.Y.Z-rc.N », sans zéro de tête (AD-22). usage : rehearse-release.sh <tag vX.Y.Z-rc.N> [--run]. Rien n'a été fait.
code=2

$ scripts/rehearse-release.sh v1.0.0
rehearse-release: tag v1.0.0 : une mise en ligne se pose sur main par le skill release, jamais ici (AD-22). Rien n'a été fait.
code=2

$ git tag --list '*-rc.*' | wc -l
0
```

Les trois refus arrivent **avant** la lecture de `.env`, avant `git fetch` et avant tout `ssh` : les
lancer sur le dépôt réel ne pouvait donc toucher ni la forge ni le serveur. L'audit complet
(`scripts/rehearse-release.sh v0.1.0-rc.1`) n'a **pas** été lancé ici : il appelle `git fetch` sur la
forge, et cette story ne touche à aucun serveur — c'est la story 11.9 qui joue la chaîne réelle.

## Revue du code

### 25/09/2026 — `0af8092` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 123. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 742d4ea56e9efa4d42988c14

**Revue BMAD - edge-case-hunter**
NON BLOQUANT : La fonction `lit_entete` concatène systématiquement les valeurs des en-têtes multiples avec « | », ce qui ferait échouer l'égalité stricte (`== no-cache`) si nginx envoyait le même en-tête en double, forçant un refus prudent mais potentiellement inattendu.
NON BLOQUANT : La fonction `releve_les_ressources` interrompt sa recherche au premier fichier CSS et au premier SVG trouvés dans le code source HTML, ignorant ainsi d'éventuels autres fichiers servis qui pourraient avoir un `Cache-Control` défectueux.
NON BLOQUANT : La boucle de `status_porte_le_tag` retourne vrai dès qu'elle trouve le tag cherché, sans vérifier s'il est l'unique version en service, ce qui est suffisant pour certifier sa présence mais reste théoriquement aveugle à d'autres conteneurs résiduels.

**Revue BMAD - verification-gap**
BLOQUANT : Le bouchon `faux_ssh` de la suite de tests n'inclut pas la destination distante dans ses messages d'erreur statiques, créant un angle mort : le test ne peut pas détecter que le script affichera les valeurs de `.env` en cas d'erreur de connexion native de la vraie commande `ssh`.
NON BLOQUANT : Le test des comptes (`case_rehearse_les_deux_comptes_ne_se_melangent_pas`) simule uniquement des appels corrects vers le compte de déploiement et ne valide pas concrètement qu'une demande fautive de tunnel sur ce compte serait effectivement rejetée par le serveur.

**Couche propre au projet**
BLOQUANT : Le script fait fuiter indirectement les valeurs privées de `ADMIN_HOST` et `DEPLOY_HOST` (violation de NFR-9) car l'erreur native de `ssh` contenant l'adresse n'est ni purgée ni redirigée : elle s'affiche directement pour le tunnel en arrière-plan et est réaffichée via `$sortie_serveur` pour les autres appels.
NON BLOQUANT : Les critères d'acceptation de la story sont intégralement satisfaits (enchaînement de répétition complet, vérifications HTTP adéquates, vérification d'absence d'IP dans les journaux Docker, et aucune altération de la production).
NON BLOQUANT : Aucune donnée privée n'est commitée (les variables de `.env.example` sont vides) et les adresses de la forge sont correctement écartées des commandes git via `2> /dev/null`.
NON BLOQUANT : La procédure documentée, les intentions du skill et l'implémentation du script concordent parfaitement, tant sur l'exécution des étapes que sur la stratégie de retour arrière.
NON BLOQUANT : Les erreurs ne sont jamais avalées en silence ; l'utilisation systématique de `|| code=$?` sous `set -euo pipefail` permet de capturer et d'auditer proprement chaque défaut d'exécution.

VERDICT: BLOQUANT — Les adresses d'administration et de déploiement lues dans .env fuiteront dans le terminal en cas d'erreur de connexion de la vraie commande ssh, une régression masquée par l'implémentation du faux ssh dans les tests.

### 25/09/2026 — `2bdd210` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 123. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 661385b78ab681be6372ef14

##### Revue de code (skill BMAD)

**Lentille : edge-case-hunter**
- NON BLOQUANT : La fonction `masque_destinations` remplace rigoureusement l'hôte et l'utilisateur dans toutes les sorties du script. Elle empêche la fuite de la destination même lorsque c'est le binaire SSH lui-même qui génère une erreur inattendue (clé refusée, hôte inconnu).
- NON BLOQUANT : Le désarmement de la trace avec `set +x` avant la lecture de `.env` protège les valeurs des hôtes et des jetons contre toute fuite si un opérateur lance le script avec `bash -x`.
- NON BLOQUANT : Le calcul du tag suivant (`-rc.N+1`) inclut une garde sur la taille du numéro, protégeant l'arithmétique du shell d'un dépassement d'entier silencieux ou d'une interprétation accidentelle comme valeur octale due à un zéro non désiré.
- NON BLOQUANT : Le tunnel `ssh` est ouvert en arrière-plan avec `&` plutôt qu'avec `-f`. Cela permet au script de retenir le PID réel et vivant du tunnel, évitant ainsi un nettoyage qui ciblerait un PID fantôme et laisserait le port bloqué.

**Lentille : verification-gap**
- NON BLOQUANT : Lors du parsing du tag de la commande `deploy-site status`, le script recherche le jeton exact (ex: `eleyone-site:v0.1.0-rc.1`) et non une sous-chaîne, comblant le risque de faux positif majeur entre un tag `-rc.1` et un tag `-rc.11`.
- NON BLOQUANT : Le test des journaux du conteneur ne se contente pas d'IPv4, il recherche activement les adresses au format IPv6 tout en excluant par conception le risque de confondre un format d'horodatage ou de condensat hexadécimal, ce qui garantit AD-15.
- NON BLOQUANT : Le script ne masque pas l'échec de la connexion aux 404 : il distingue très bien les statuts (une erreur `curl` brute de connexion et une réponse HTTP valide avec le bon code 404 dans la langue).
- NON BLOQUANT : Il n'y a pas d'arrêt aveugle automatique de l'image de répétition par le piège de fin (via `rehearse stop`) en cas d'erreur. Le nettoyage forcé supprimerait le conteneur fautif et détruirait précisément le contexte dont l'humain a besoin pour enquêter.

##### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story 11.8 sont satisfaits sans que leur intention soit vidée : l'enchaînement strict (tag `-rc.1`, tunnel, requêtes curl -I de validation AD-13, tag `-rc.2`, rollback et vérifications) est complètement suivi.
- NON BLOQUANT : Aucune donnée privée, aucun secret et aucune adresse de serveur n'est commitée. Les identifiants `ADMIN_HOST` et `DEPLOY_HOST` de `.env.example` sont vides, les erreurs de SSH sont interceptées par `masque_destinations`, et la sortie d'erreur de git (URL de forge) est neutralisée par `2> /dev/null`.
- NON BLOQUANT : Le skill, la procédure et le script concordent totalement. La procédure `docs/procedures/rehearse-release.md` décrit le cloisonnement exact entre le compte d'administration (tunnel, journaux) et le compte de déploiement (commandes du bot) que le script applique.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et l'architecture (notamment AD-22 sur la boucle locale 127.0.0.1:18080 sans toucher ni à la production ni au réseau proxy NPM, et AD-15).
- NON BLOQUANT : Sous `set -euo pipefail`, chaque commande susceptible d'échouer `ssh`, `curl`, `wait` est contrôlée de manière déterministe avec l'idiome `|| code=$?` ou attrapée dans des conditions, garantissant qu'aucune erreur critique ne passe en silence.

VERDICT: NON BLOQUANT — aucune

## Décisions

### Le `-f` du tunnel : la décision A3 appliquée, sa lettre corrigée

A3 dit « `-f -N`, le PID retenu, et le tunnel tué par le `trap` ». Les trois exigences sont tenues,
**sauf `-f`**, et pour une raison mécanique : avec `-f`, `ssh` se dédouble pour passer en
arrière-plan, et le processus que le script a lancé se termine aussitôt. « Le PID retenu » serait
alors celui d'un processus déjà mort — le piège tuerait un fantôme et **laisserait le tunnel
ouvert**, c'est-à-dire l'inverse exact de ce que A3 demande. Les deux moitiés de la décision sont
incompatibles entre elles, pas avec le script.

Le tunnel est donc lancé en **tâche de fond du script** (`ssh -N -L … &`), et `$!` est le tunnel
lui-même : on peut lui demander s'il vit (`kill -0`), le tuer vraiment, et l'attendre. S'y ajoute
`ExitOnForwardFailure=yes`, sans quoi une redirection refusée laisserait un `ssh` vivant et muet.
`rehearse_sequence_nominale` et `rehearse_un_echec_narrete_pas_la_repetition` constatent, après coup,
que le PID du faux tunnel est mort — une assertion qu'un `-f` aurait rendue impossible à écrire.

C'est le point 10 d'AGENTS.md : une règle qui décrit le comportement d'un outil n'est vraie qu'une
fois vérifiée.

### `DEPLOY_HOST` dans `.env.example` : une variable de plus que le brief n'annonçait

Le brief ne demandait que `ADMIN_HOST`. Mais la décision A6 confie `rehearse rollback`,
`rehearse stop` et `status` au **compte de déploiement**, et le script a donc besoin de sa
destination. Deux possibilités : la deviner, ce qu'aucun script du projet ne fait, ou la lire dans
`.env` comme la première.

`DEPLOY_HOST` est lue dans `.env`, et `.env.example` la nomme — sans valeur, comme les douze autres.
**Ce n'est pas un nom nouveau** : c'est exactement celui du secret de la forge (story 11.5), avec la
même valeur, si bien qu'A4 reste vraie — `ADMIN_HOST` est la seule variable *nouvelle* de la story.
La clé, elle, n'entre pas dans `.env` : sur le poste, c'est la configuration SSH d'Arnaud qui la
fournit, comme pour le `ssh <compte de déploiement> status` que `deploy-site.md` décrit déjà.

### La CSP n'est pas exigée partout, et c'est mesuré

`deploy/nginx/site.conf` envoie la CSP sur le HTML seulement (`map $sent_http_content_type $csp`,
valeur vide par défaut, et une valeur vide **supprime** l'en-tête). Le script exige donc la CSP sur
les quatre pages HTML et exige son **absence** sur les ressources — c'est le contrôle que WS-5
annonce dans AD-13. De même, `Cache-Control` attendu vaut `immutable` pour un fichier empreinté d'un
condensat et `no-cache` pour tout le reste : l'attente se déduit du nom du fichier, exactement comme
le `map` la déduit de l'URI. Lu dans la configuration, pas récité — et la mutation M16 prouve qu'une
exigence trop large ferait échouer un fichier conforme.

### Le fichier empreinté est relevé, pas deviné

Aucun nom de fichier n'est écrit dans le script : il est relevé dans la **page d'accueil servie**
(`/[A-Za-z0-9._/-]*\.[0-9a-f]{64}\.(css|svg|webp)`, le motif du `map`). Deux conséquences assumées :
l'absence de tout fichier empreinté est un **échec** — un contrôle qui ne lit rien passerait au vert
sans rien prouver — et le SVG, lui, reste **conditionnel**, le site n'en portant pas encore. Son
absence est dite (`sans objet`), jamais tue.

Les fixtures HTML sont écrites **minifiées, sans guillemets d'attribut** (`<html lang=fr>`,
`href=/css/…`), parce que c'est ce que Hugo produit : une fixture qui ne ressemble pas à la vraie
sortie fait d'un contrôle une décoration (point 16, relevé dans le `public/` du dépôt).

### `LC_ALL=C` en tête du script

Le script compare des empreintes de 64 caractères, des identifiants de conteneur et des adresses IP,
tous écrits en **plages** (`[0-9a-f]`). Le piège de la story 11.5 est explicite : une plage ne dit
pas la même chose en `fr_FR.UTF-8` et en `C`. La locale est donc fixée une fois pour toutes, et le
script rend le même verdict sur le poste et dans `CHECK_IMAGE`.

### Ce que la story ne fait pas

Aucun tag n'a été posé, ni localement ni sur la forge ; aucun serveur n'a été touché ; aucun test ne
lance `ssh`, `curl`, `docker` ni `git push` réels. L'exécution réelle de la répétition est la story
11.9.

## Décisions de l'orchestrateur

### Ma consigne sur le tunnel était auto-contradictoire, et la sous-tâche l'a vu

Mon brief reprenait la proposition du relecteur : « `-f -N`, le PID retenu, et le tunnel tué par le
`trap` ». **Les deux moitiés s'excluent.** `ssh -f` se dédouble après l'authentification : le
processus lancé rend la main aussitôt, et `$!` désigne alors un **mort**. Le `trap` tuerait un
fantôme et laisserait le tunnel ouvert — exactement l'inverse de ce que la garde veut.

Mesuré par l'orchestrateur, avec un faux `ssh` qui imite le dédoublement :

```
avec -f    : PID 2659987 DEJA MORT — le trap tuerait un fantome
sans -f    : PID 2660057 vivant — le trap peut le tuer
```

**La sous-tâche a eu raison contre le brief**, et elle a tenu l'**intention** de la garde plutôt que
sa lettre : `ssh -N -L … &`, `$!` qui est bien le tunnel, `kill -0` pour l'éprouver, plus
`ExitOnForwardFailure=yes` pour qu'un port déjà pris fasse échouer au lieu d'ouvrir une coquille.
C'est le point 10 : une règle qui décrit le comportement d'un outil n'est vraie qu'une fois
vérifiée — et ni le relecteur ni moi ne l'avions vérifiée.

### `DEPLOY_HOST` dans `.env.example` : accepté

Le brief ne nommait qu'`ADMIN_HOST`. La sous-tâche a ajouté `DEPLOY_HOST`, parce que le script en a
besoin — la décision A6 confie `rehearse rollback|stop` et `status` au **compte de déploiement**, et
aucun script du projet ne devine une destination. **Ce n'est pas un nom nouveau** : c'est celui du
secret de la forge (story 11.5), avec la même valeur. La décision A4 reste vraie, et `.env.example`
ne porte aucune valeur.

Conséquence constatée, pas supposée : **C18 compare `.env.example` à une liste exacte**, et
`scripts/check.sh` était rouge sans les deux noms. La sous-tâche l'a vu en lançant la suite.

### Les deux mutations « à l'envers », et pourquoi elles valent les trente autres

La sous-tâche rapporte deux mutations qui ne retirent pas une garde mais la rendent **plus stricte** :
CSP exigée partout, et motif d'adresse IP élargi. Les cas qui tombent alors sont ceux qui affirment
qu'un site **conforme passe**.

C'est exactement ce qui manquait aux contrôles du projet jusqu'ici : les mutations des stories
précédentes vérifiaient toutes qu'une garde **refuse** ce qu'elle doit refuser, jamais qu'elle
**laisse passer** ce qui est correct. Un contrôle trop strict est aussi faux qu'un contrôle trop
laxiste — il fait échouer une mise en ligne conforme, et on apprend à le contourner. Le cas de la
CSP le montre bien : elle n'est envoyée **que sur le HTML**, un SVG n'en porte pas par conception,
et une vérification naïve aurait bloqué la répétition sur un fichier parfaitement conforme.

### Deux tests qui ne prouvaient rien, encore

Deux mutations sur trente-deux ne tombaient pas au premier essai, et les deux portaient **la même
faute** : le cas affirmait un mot que la garde *suivante* produirait aussi. C'est la troisième story
de l'epic où la campagne de mutation révèle un test qui ne distingue pas ce qu'il prétend
distinguer — et `scripts/tests/test-ship.sh` documente cette faute depuis la story 11.5.

### Vérification du travail de la sous-tâche (point 22)

| Vérification | Résultat |
| --- | --- |
| `bash scripts/tests/run.sh` | 894 cas réussis |
| `scripts/check.sh` | 11 contrôles, code 0 |
| tags `-rc` posés localement | **0** |
| liens symboliques | mode `120000`, même cible que `release` |
| `ssh -f` : le PID retenu survit-il ? | **non**, mesuré — la lettre du brief était fausse |
| refus sans argument / `v1.2.3-rc` / `v1.0.0` / `v01.2.3-rc.1` | les quatre, avant tout effet de bord |
| `AGENTS.md`, `.env.example` | point 8 et C18, tous deux justifiés |

### Triage de la revue du code (`0af8092`, verdict `block`)

**B1 — les destinations fuient par la sortie d'erreur de `ssh`. RETENU, et le verdict est mérité.**
C'est NFR-9 **à l'exécution**, là où tout le projet ne l'avait vérifié que dans le dépôt : quand la
connexion échoue, ce n'est pas le script qui parle, c'est `ssh`, et son message porte l'adresse —
« ssh: Could not resolve hostname <hôte> », « <dest>: Permission denied ». Cela finit dans un
terminal, une capture d'écran, un collage.

Deux chemins étaient ouverts : la sortie d'erreur du tunnel partait **droit au terminal** (le
message disait même « le message de ssh est au-dessus »), et `sortie_serveur` capturait `2>&1` puis
l'affichait. Les deux passent désormais par `masque_destinations`, qui remplace chaque destination
**et sa partie hôte seule** par son rôle — `ssh` n'écrivant pas toujours le `utilisateur@`.

**B2 — le bouchon `faux_ssh` n'imitait pas la forme réelle, et rendait le test aveugle. RETENU**, et
c'est la cause du premier : un bouchon qui n'écrit pas ce que le vrai outil écrit ne peut pas
révéler une fuite. C'est le point 16, pour la troisième fois de l'epic. Le bouchon écrit maintenant
les deux formes réelles, destination comprise.

Cas ajouté, `rehearse_aucune_destination_dans_la_sortie`, qui couvre **les deux chemins** — tunnel
mort, et `status` qui ne répond jamais — et vérifie l'absence des deux destinations *et* de l'hôte
nu, sur la sortie standard comme sur la sortie d'erreur. Rejoué sans le masque :

```
la sortie d erreur porte une destination (NFR-9) : compte-admin@serveur-essai
rc=1
```

**E1 — `lit_entete` concatène des en-têtes en double par « | ». NON RETENU, et c'est assumé.** Le
relecteur le dit lui-même : le refus serait « prudent mais potentiellement inattendu ». nginx ne
double aucun de ces en-têtes ici (`add_header_inherit merge` est là précisément pour cela), et si
cela arrivait, un refus est la bonne réponse — pas un silence. Rien à changer.

**E2 — `releve_les_ressources` s'arrête au premier CSS et au premier SVG. NON RETENU.** Le but est
de vérifier la **règle** de `Cache-Control`, pas d'auditer chaque fichier du site : un empreinté
suffit à prouver `immutable`, un non-empreinté à prouver `no-cache`. Auditer tout le site est le
travail de C13 sur la sortie, pas d'une répétition qui passe par un tunnel.

**E3 — `status_porte_le_tag` ne vérifie pas l'unicité. NON RETENU** : la question posée est « le tag
attendu est-il en service ? », et c'est elle qu'il faut répondre avant de mesurer. Un conteneur
résiduel est refusé par `deploy-site` lui-même (story 11.4), qui relance le service au lieu d'en
ajouter un.

**E4 — le cas des deux comptes ne prouve pas qu'un tunnel serait refusé sur la clé de déploiement.
NON RETENU ici, car ce n'est pas ce que ce dépôt peut prouver** : le refus vient de `restrict` dans
l'`authorized_keys` du serveur, et il est vérifié par le **quatrième essai** de
`docs/procedures/serveur-de-production.md` (story 11.6), à la main, sur le vrai serveur. Un test
hors ligne ne peut que vérifier que le script n'envoie jamais de `-L` au compte de déploiement, ce
qu'il fait.

**Les quatre lignes de la couche projet** sont des confirmations.

### Triage de la seconde revue du code (`2bdd210`)

**Aucun constat.** Les huit lignes sont des confirmations, et trois d'entre elles portent sur des
points où la story avait **divergé** d'une revue précédente ou d'un brief :

- `masque_destinations` « empêche la fuite de la destination même lorsque c'est le binaire SSH
  lui-même qui génère une erreur » — le verdict bloquant précédent est refermé ;
- le tunnel « est ouvert en arrière-plan avec `&` plutôt qu'avec `-f` », ce qui « permet de retenir
  le PID réel et vivant, évitant un nettoyage qui ciblerait un PID fantôme » — c'est exactement la
  correction de la lettre de A3, validée par le relecteur suivant ;
- « il n'y a pas d'arrêt aveugle automatique … le nettoyage forcé supprimerait le conteneur fautif
  et détruirait précisément le contexte dont l'humain a besoin pour enquêter » — c'est la divergence
  A7, que le relecteur précédent demandait en sens inverse, reprise ici dans mes propres termes.

Deux relecteurs successifs ont donc jugé la même question en sens opposés. Ce n'est pas une
inconstance à corriger, c'est ce qui rend une décision **écrite** utile : la première revue a posé
la question, le triage a tranché avec sa raison, et la seconde a pu juger la raison plutôt que
redécouvrir la question.

Rien à retenir, rien à reporter.
