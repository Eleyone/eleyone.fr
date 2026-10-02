# Story 11.9 : First release chain rehearsal

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.9.

Neuvième story de l'epic 11, dont l'en-tête (point 21) veut la chaîne de mise en ligne **construite
et répétée tôt sur le serveur de production, sans DNS** : c'est la dernière des stories 11.1 à 11.9,
celle qui **exécute** la répétition que la 11.8 a écrite. Opération manuelle d'Arnaud : les tags
`v0.1.0-rc.1` et `v0.1.0-rc.2` sur `dev`, le tunnel, les vérifications.

## Ce dont elle dépend, et qui est en place

- **11.8** (`done`) : `scripts/rehearse-release.sh`, skill `rehearse-release`.
- **Serveur et forge, installés le 02/10/2026** par Arnaud, en suivant `serveur-de-production.md`
  de bout en bout : compte de déploiement, deux clés restreintes (forge et poste), quatre essais
  passés pour chacune, `deploy/` au commit `3bdee79`, `.env` du serveur, douze secrets
  (`check-forge-secrets` : 12 sur 12).
- **Deux correctifs fusionnés avant elle**, nés de cette préparation :
  - PR n° 126 : le poste a sa propre clé du compte de déploiement (la procédure supprimait la seule) ;
  - PR n° 127 : le script charge cette clé dans un agent privé et vérifie les deux connexions
    **avant** le premier tag (il ne le faisait qu'après l'avoir poussé).
- **Runners de la forge** : un dossier de travail par runner, au même chemin des deux côtés
  (02/10/2026) ; la CI repasse.

## Revue de spec

### 02/10/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `2ef0ea4`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ebfd83fcae269367060be477

Voici le rapport de revue de la spec (story 11.9) basé sur les lentilles BMad demandées. 

Cette spec décrit l'exécution d'une répétition générale. Or, l'analyse du script `scripts/rehearse-release.sh` (livré à la story 11.8) révèle un décalage majeur : le script automatise entièrement l'enchaînement (tags, attente, tunnel, vérifications, rollback, stop) via son option `--run`, alors que la spec présente ces actions comme des étapes manuelles à la charge d'Arnaud.

##### Lentille Adversarial

- **location** : En-tête "Opération manuelle" et Critères d'acceptation 1 et 3
  **trigger_condition** : La spec décrit la pose des tags, l'ouverture du tunnel, le rollback et le stop comme des opérations manuelles d'Arnaud.
  **guard_snippet** : Préciser que ces actions sont réalisées automatiquement par l'appel au script avec l'option `--run`.
  **potential_consequence** : Confusion totale lors de l'exécution : Arnaud exécuterait à la main ce que le script est précisément censé tester, ce qui contredit l'automatisation apportée par la story 11.8.
  **Classification** : BLOQUANT

- **location** : Critère d'acceptation 2 ("les pages légales montrent les vraies valeurs")
  **trigger_condition** : La fonction `verifie_le_site` du script `rehearse-release.sh` ne contrôle que `/`, `/en/` et les 404, mais ne vérifie pas les vraies valeurs des pages légales.
  **guard_snippet** : Indiquer comment Arnaud effectue cette vérification. Si elle est manuelle, le tunnel étant refermé automatiquement à la fin de `--run`, il faudra préciser qu'Arnaud doit lancer le script en mode audit (sans `--run`) pour maintenir le tunnel ouvert, ou bien enrichir le script.
  **potential_consequence** : Critère invérifiable en l'état ; les valeurs des pages légales ne seront pas testées.
  **Classification** : BLOQUANT

- **location** : Critère d'acceptation 1 ("puisque ci/release-pages.txt ne liste que...")
  **trigger_condition** : La story est marquée "Opération manuelle : oui", mais nécessite que `ci/release-pages.txt` soit parfaitement à jour pour le commit testé.
  **guard_snippet** : S'il faut modifier ce fichier pour le socle, retirer "Opération manuelle : oui" et ajouter une étape de code. Si le fichier a déjà été préparé, le placer en prérequis strict.
  **potential_consequence** : La CI échouera sur le contrôle C15 si le fichier n'est pas à jour, bloquant la répétition complète.
  **Classification** : BLOQUANT

- **location** : Critère d'acceptation 3 ("Quand Arnaud lance rehearse rollback")
  **trigger_condition** : La commande `rehearse` n'existe pas sur le poste de développement local, c'est une commande du serveur distant.
  **guard_snippet** : Si l'action doit être manuelle, corriger en `ssh <compte_de_deploiement> 'rehearse rollback...'`. Si c'est automatisé par `--run`, corriger la phrase.
  **potential_consequence** : Arnaud tentera de lancer une commande invalide sur son terminal local.
  **Classification** : BLOQUANT

- **location** : Général (gestion des échecs de la répétition)
  **trigger_condition** : Le script de répétition précise qu'il n'arrête délibérément pas le conteneur en cas d'échec pour permettre l'inspection. La spec ne prévoit rien pour ce scénario.
  **guard_snippet** : Ajouter un critère décrivant la procédure en cas d'échec (inspection ssh puis arrêt manuel via `ssh <compte> 'rehearse stop'`).
  **potential_consequence** : En cas d'échec, le conteneur restera actif indéfiniment sur le port 18080 si Arnaud suit la spec aveuglément sans nettoyer derrière lui.
  **Classification** : BLOQUANT

- **location** : Critère d'acceptation 1
  **trigger_condition** : La phrase "Quand le workflow release se termine" laisse penser qu'Arnaud doit surveiller visuellement la CI Gitea.
  **guard_snippet** : Remplacer par "Quand le script détecte que le tag est en service".
  **potential_consequence** : Fausse attente d'une surveillance manuelle de la CI, alors que le script s'occupe de l'attente (avec sa fonction `attends_le_tag`).
  **Classification** : NON BLOQUANT

- **location** : Critère d'acceptation 2
  **trigger_condition** : "les journaux ne contiennent aucune IP".
  **guard_snippet** : Préciser "les journaux, vérifiés automatiquement par le script, ne contiennent aucune IP".
  **potential_consequence** : Arnaud pourrait penser devoir inspecter les logs du conteneur à la main.
  **Classification** : NON BLOQUANT

- **location** : Critère d'acceptation 1
  **trigger_condition** : Mention brute des tags `v0.1.0-rc.1` et `v0.1.0-rc.2`.
  **guard_snippet** : Préciser explicitement que ces tags sont poussés de manière transparente par l'appel à `--run`.
  **potential_consequence** : Ambiguïté sur la méthode de pose des tags.
  **Classification** : NON BLOQUANT

- **location** : Critère d'acceptation 3
  **trigger_condition** : "Alors status montre v0.1.0-rc.1, vérifié par le tunnel".
  **guard_snippet** : Clarifier que c'est le script qui s'assure de cette vérification.
  **potential_consequence** : Redondance de test manuel inutile.
  **Classification** : NON BLOQUANT

- **location** : En-tête (Prérequis de contenu)
  **trigger_condition** : L'état exact du dépôt attendu pour le tag n'est pas identifié (Prérequis : "—").
  **guard_snippet** : Renvoyer explicitement à la définition du "socle" dans l'architecture.
  **potential_consequence** : Risque de taguer une version contenant des brouillons non voulus ou instables.
  **Classification** : NON BLOQUANT


##### Lentilles Structure et Prose

Ce document existe pour définir le protocole exact de la première répétition générale. Il est évalué ici avec l'exigence de clarté pour un lecteur humain (Arnaud).

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| structure | "Opération manuelle (Arnaud) : oui, tags v0.1.0-rc.1 et v0.1.0-rc.2 sur dev, tunnel SSH, vérifications." | **CONDENSE into** : "Opération manuelle (Arnaud) : lancement du script de répétition et vérifications visuelles." | BLOQUANT : Évite de contredire l'automatisation apportée par la story 11.8. |
| structure | Critère 1 : "C15 compris, puisque ci/release-pages.txt ne liste que les pages publiées attendues à ce commit (D-5)." | **MOVE** : Déplacer ce point dans les prérequis de contenu. | BLOQUANT : La présence/mise à jour de `ci/release-pages.txt` est un prérequis structurel au commit, pas une conséquence du workflow `release`. |
| structure | Critère 3 entier ("Étant donné v0.1.0-rc.2 déployé... Quand Arnaud lance rehearse rollback...") | **REWRITE into** : "Étant donné le lancement du script `--run`, Alors le rollback et l'arrêt sont automatisés et réussissent." | BLOQUANT : L'enchaînement est piloté par le script ; la structure de la spec doit refléter cette continuité et non le morceler en actions manuelles. |
| prose | "Quand Arnaud lance les vérifications de la story 11.8" | "Quand Arnaud lance le script de répétition avec `--run`" | BLOQUANT : Lève l'ambiguïté fondamentale sur l'action réellement attendue pour déclencher le process. |
| prose | "status montre v0.1.0-rc.1 en répétition" | "le script constate que le tag v0.1.0-rc.1 est de nouveau en service" | NON BLOQUANT : Plus précis sur le moyen de vérification. |
| prose | "vérifié par le tunnel ; puis rehearse stop arrête le conteneur" | "le script le vérifie par le tunnel, puis arrête le conteneur" | NON BLOQUANT : Clarifie que le script en est le sujet actif. |

##### À trancher avant d'implémenter

- **L'automatisation vs l'exécution manuelle** : La spec de la 11.9 décrit un processus entièrement manuel pour la pose des tags, le tunnel, le rollback et l'arrêt. Or, le script `rehearse-release.sh` créé en 11.8 (avec l'option `--run`) automatise tout cet enchaînement. Faut-il réécrire la spec pour refléter le simple appel à `--run`, ou s'agit-il vraiment d'une exécution manuelle pas-à-pas (auquel cas `--run` ne sera pas utilisé) ?
- **La vérification des pages légales** : Le script de la 11.8 ne vérifie pas le contenu des pages légales. Puisque le script ferme le tunnel à la fin de son exécution `--run`, comment Arnaud doit-il les vérifier visuellement ? Faut-il relancer le script en mode audit (sans `--run`) pour ouvrir un tunnel persistant permettant la vérification manuelle, ou faut-il plutôt enrichir la fonction `verifie_le_site` du script ?
- **La gestion de `ci/release-pages.txt`** : Ce fichier doit refléter exactement les pages du socle pour valider le contrôle C15. S'il doit être modifié pour ce commit spécifique avant le tag, cette story comporte une étape de code et n'est plus à 100% une opération manuelle. Qui s'occupe de sa mise à jour ?

### Tri des constats (02/10/2026, auteur Claude)

La spec date d'avant la 11.8 : elle décrit les gestes de la répétition, que le script de la 11.8
enchaîne depuis. `epics.md` n'est pas modifié — savoir si un artefact de planification validé se
corrige est une question ouverte en attente d'arbitrage (`open_questions`) —, la lecture retenue est
écrite ici.

| # | Constat | Décision |
|---|---|---|
| A1 | Gestes « manuels » alors que `--run` les enchaîne (BLOQUANT) | **Retenu comme lecture, pas comme correction.** L'opération reste manuelle : Arnaud lance `scripts/rehearse-release.sh v0.1.0-rc.1 --run` **dans son terminal** — le script demande la phrase de passe de la clé du poste (PR n° 127) et refuse sans terminal. Les tags, le tunnel, le retour arrière et l'arrêt sont ceux que le script pose. |
| A2 | Le script ne vérifie pas les vraies valeurs des pages légales (BLOQUANT) | **Retenu.** Exact : `verifie_le_site` contrôle `/`, `/en/`, les 404, une ressource empreintée, un SVG et les journaux, jamais `/mentions-legales/`. Et le tunnel se ferme avec le script, l'arrêt supprime le conteneur : une vérification à l'œil après coup est impossible. Arbitrage demandé à Arnaud (voir plus bas). |
| A3 | `ci/release-pages.txt` peut-être pas à jour (BLOQUANT) | **Réfuté, preuve à l'appui.** Le socle est complet (stories 10.1 à 10.7 `done`) et la liste porte ses neuf clés. `scripts/check.sh --release` sur `dev` à `2ef0ea4`, avec les vraies valeurs légales : « release-pages: pages et sections attendues présentes en FR et en EN […] », « check: 11 contrôle(s) passés, niveau release », code 0. Aucun fichier à modifier. |
| A4 | `rehearse rollback` n'existe pas sur le poste (BLOQUANT) | **Réfuté.** Le critère nomme la demande que le script envoie au compte de déploiement (`demande_au_serveur rehearse rollback`) ; personne ne la tape. Couvert par la lecture A1. |
| A5 | Rien pour le cas d'échec (BLOQUANT) | **Retenu, sans changement de code.** Le cas est déjà écrit, et voulu : `rehearse-release.md`, « Après un échec » — le script tue le tunnel et l'agent, **n'arrête pas** la répétition pour qu'on puisse l'inspecter, et donne les deux commandes (`status`, `rehearse stop`). La story le reprend dans sa marche à suivre. Un conteneur oublié reste isolé : hors du réseau du proxy, publié sur la boucle locale du serveur seulement (AD-22). |
| A6 | « Quand le workflow release se termine » suggère de surveiller la CI (NON BLOQUANT) | **Pris acte**, lecture A1 : le script attend par `deploy-site status`, au plus trente minutes, sans suivre la forge. |
| A7 | Journaux « vérifiés automatiquement » (NON BLOQUANT) | **Pris acte** : `verifie_les_journaux` les lit par le compte d'administration et signale une ligne fautive par son numéro. |
| A8 | Tags posés par `--run` (NON BLOQUANT) | **Pris acte**, lecture A1. |
| A9 | `status` vérifié par le script (NON BLOQUANT) | **Pris acte**, lecture A1. |
| A10 | État du dépôt attendu non désigné (NON BLOQUANT) | **Pris acte.** La répétition porte sur `origin/dev` ; elle se jouera donc sur le socle complet, et non « avant le contenu du socle » comme l'en-tête de l'epic l'envisageait : l'epic 10 est passé avant. C'est plus exigeant, pas moins — et c'est justement ce que A3 a vérifié. |
| S1–S6 | Réécritures de structure et de prose de la spec | **Écartées** pour `epics.md` (question ouverte ci-dessus) ; leur fond est couvert par A1, A5 et A6. |

**Arbitrage d'Arnaud sur A2 (02/10/2026) : option 1.** « Il faut que la vérif se fasse
systématiquement et automatiquement. » Le script vérifie lui-même, à **chaque** passage de ses
vérifications, que les deux pages légales servies portent les huit vraies valeurs de
`docs/private/legal-release.env`, sans jamais les afficher. Options écartées : une pause pour un
contrôle à l'œil (repose sur une personne devant l'écran, à chaque répétition), et les deux à la fois.
La story porte donc du code — `scripts/rehearse-release.sh`, ses tests, sa procédure — avant
l'exécution par Arnaud, qui se fait avec le script de cette branche.

## Implémentation

### Ce qui est construit (arbitrage A2, option 1)

- **`scripts/rehearse-release.sh`** : `verifie_le_site` appelle `verifie_page_legale` pour
  `/mentions-legales/` et `/en/legal-notice/`. Elle fait tout ce que `verifie_html` fait (200, HTML,
  en-têtes d'AD-13, langue), puis cherche **chacune** des valeurs du fichier de mise en ligne dans le
  corps servi. Une valeur absente est un `verif_ko` qui nomme la variable et la page, jamais la
  valeur ; une page qui ne répond pas 200 en HTML n'est pas lue (« valeurs légales non vérifiées »).
  La tournée tourne aux trois passages (après rc.1, après rc.2, après le retour arrière).
- **Avant tout tag, dans l'audit comme avec `--run`** (juste après les destinations, avant le port,
  les tags et les connexions) : le fichier `LEGAL_RELEASE_ENV_FILE`, sinon
  `docs/private/legal-release.env`, est trouvé et lu ; tout défaut est un `die` (code 2) qui nomme
  la ou les variables, jamais une valeur. Refus : fichier absent, illisible ou dossier ; `.env` du
  dépôt, `ci/legal-placeholder.env`, tout fichier nommé `.env` ; un nom de `.env.example` absent ou
  vide (tous nommés d'un coup) ; une valeur faite de blancs ; une valeur égale à la valeur factice du
  même nom ; `.env.example` sans nom `HUGO_LEGAL_`, `.env.example` ou `ci/legal-placeholder.env`
  illisibles à côté du script.
- **`scripts/lib/legal.sh`** (nouveau) : les deux pages en chemins d'URL (C23 en tire désormais ses
  chemins de fichiers par `checks_page_de_url` : une seule écriture), la lecture des noms dans
  `.env.example`, la lecture des valeurs par `dotenv_read` (règle d'`env.sh` : vide = absence,
  première valeur non vide, clé comparée entière), et la forme comparable d'une valeur et d'une page.
- **`scripts/lib/text.sh`** (nouveau) : `decoder_echappements` et `normaliser_blancs` **déplacés**
  sans changement depuis `scripts/checks/lib.sh` (qui les charge désormais d'ici), plus
  `decoder_espaces_insecables` et `replier_espaces_insecables`, qui ne servent qu'à la répétition :
  C22 et C23 ne replient pas les insécables, décision laissée à l'entrée de `deferred-work.md` qui
  la diffère.
- Tests : `scripts/tests/test-rehearse-release.sh`, 19 cas nouveaux et un étendu (`aucune_trace_de_shell`) ; deux fixtures,
  `scripts/tests/fixtures/rehearse-release/{mentions-legales,legal-notice}.html`, **copiées d'un vrai
  build de production** fait avec les valeurs factices. `test-check.sh` et `test-content.sh` copient
  `text.sh` dans leur dépôt d'essai, puisque `checks/lib.sh` le charge.
- Docs : `docs/procedures/rehearse-release.md` (prérequis, « Avant toute action », tableau des
  vérifications, nouvelle section « Les pages légales et leurs vraies valeurs », tests), `SKILL.md`,
  en-tête du script, `docs/procedures/check.md` et `shell-scripts.md` (emplacement des filtres et
  des deux bibliothèques), commentaires de C22 et C23 sur l'emplacement des filtres.

### Le rendu réel, vérifié (point 10)

Trois builds de production locaux, tous vers un dossier jetable (`BUILD_DESTINATION_ROOT` dans le
dossier temporaire de la session) : `public/` du dépôt n'a jamais porté de valeur de mise en ligne.

1. `ENV_MODE=release LEGAL_ENV_FILE=<fichier d'essai> BUILD_DESTINATION_ROOT=<jetable> scripts/build.sh production`,
   avec des valeurs piégées (`&`, apostrophe, `"`, `<…>`, `&amp;` littéral, ` : `, ` ; `, `« … »`,
   ` ?`, ` !`, `+33 …`, deux et trois espaces de suite). Constaté dans le HTML rendu :
   - le minifieur laisse `&`, `'`, `"`, `>` et `+` en clair, écrit `<` en `&lt;`, et `&amp;` littéral
     en `&amp;amp;` ; il replie toute suite d'espaces en une, **dans les deux langues** ;
   - sur la page FR seulement, ` :` devient U+00A0 `:`, et ` ;`, ` ?`, ` !`, `« `, ` »` prennent
     U+202F ; la page EN garde les espaces ordinaires ;
   - la sortie d'un shortcode n'est pas typographiée par Goldmark : l'apostrophe droite reste droite.

   Le matcher (page : entités d'insécables → `decoder_echappements` → repli des insécables →
   `normaliser_blancs` ; valeur : repli → `normaliser_blancs` → rognage) retrouve les **8 valeurs
   sur les 2 pages (16/16)**. Retirer une étape sur ce même build, une à la fois : sans le décodage,
   `HUGO_LEGAL_HOST_NAME` absente des deux pages ; sans le repli des insécables,
   `HUGO_LEGAL_PUBLISHER_ADDRESS` et `HUGO_LEGAL_PUBLISHER_REGISTRATION` absentes de la page FR ; sans
   la normalisation des blancs de la valeur, `HUGO_LEGAL_PUBLISHER_REGISTRATION` absente des deux.
   Chaque étape est donc nécessaire sur le vrai rendu, pas seulement sur une fixture.
2. `ENV_FILE=/nonexistent BUILD_DESTINATION_ROOT=<jetable> scripts/build.sh production` (valeurs
   factices seules) : les valeurs factices sont trouvées 16/16, les valeurs d'essai du point 1
   absentes 16/16. C'est de ce build que viennent les deux fixtures.
3. `ENV_MODE=release LEGAL_ENV_FILE=docs/private/legal-release.env BUILD_DESTINATION_ROOT=<jetable> scripts/build.sh production` :
   les **8 vraies valeurs trouvées sur les 2 pages (16/16)**, les valeurs factices absentes 16/16.
   Seul « trouvée / absente » par variable a été affiché, aucune valeur ; le dossier jetable a été
   supprimé aussitôt.

Le script lui-même n'a jamais été lancé contre le serveur ni la forge, pas même en audit.

### Gardes des aînés (point 19)

**Aîné 1 — `scripts/checks/legal-address.sh` (C23)**, qui lit une vraie valeur légale et la cherche
dans le rendu.

| Garde de C23 | Ici ? |
|---|---|
| valeur absente = anomalie (2), jamais succès | **repris** : fichier absent ou incomplet → `die` avant tout tag ; et une valeur faite de blancs vaut absence (une chaîne vide se trouve partout) |
| aucun message n'affiche la valeur | **repris** : la variable et la page, jamais la valeur ni le contenu servi ; `aucune_valeur_legale_dans_la_sortie` sur chaque cas nouveau, `bash -x` compris |
| texte décodé avant lecture (`decoder_echappements`), valeur non décodée | **repris**, même fonction (déplacée dans `text.sh`, non réécrite) |
| blancs normalisés des deux côtés | **repris**, plus les insécables de la typographie FR, que C23 n'a pas à voir |
| comparaison de bash `== *"…"*`, pas `grep -F` (multi-ligne, pas de regex) | **repris** |
| sortie de `sed` capturée, son code lu | **repris** (`texte=$(…) \|\| code=$?`) |
| fichier lu avant la condition, jamais en argument d'un `if` | **repris** |
| `tr -d '\0'` plutôt que `cat` | **repris**, testé |
| rendu absent ou vide = anomalie | **équivalent** : page non servie en HTML 200 → « valeurs légales non vérifiées » |
| pages légales écrites en dur | **factorisé** : `scripts/lib/legal.sh`, d'où C23 tire désormais ses chemins |
| extraction XPath de `<title>`, metas, JSON-LD ; balayage des sorties non HTML | **sans objet** : la répétition vérifie la présence des valeurs, pas leur confinement, que C23 tient déjà au build de l'image |

**Aîné 2 — `scripts/build-image.sh`**, qui trouve et refuse le fichier de mise en ligne, avec le
chargeur qu'il délègue, **`scripts/env.sh`**.

| Garde | Ici ? |
|---|---|
| défaut absolu `$root/docs/private/legal-release.env`, `LEGAL_RELEASE_ENV_FILE` | **repris** |
| chemin relatif résolu depuis le dossier d'appel | **repris** (`appel=$PWD` avant le `cd`) |
| `-f` et `-r` (un dossier lisible passerait `-r`) | **repris** |
| refus de `.env` et de `ci/legal-placeholder.env` par chemin canonique | **repris** |
| refus d'un fichier nommé `.env` (env.sh) | **repris** |
| toute variable manquante fait échouer, toutes nommées d'un coup | **repris** |
| pour un fichier, vide = absence ; première valeur non vide | **repris** (la même règle, sinon la page serait comparée à une valeur que le build n'aurait pas retenue) |
| clé comparée entière (préfixe de `dotenv_read`) | **repris** (garde de `rehearse-release.sh` lui-même, `lit_destination`) |
| priorité des variables posées par l'appelant (env.sh) | **non** : la référence est le fichier, pas l'environnement du shell d'Arnaud — un `HUGO_LEGAL_*` exporté chez lui ne change pas ce que la forge construit |
| virgule refusée dans le chemin | **non** : contrainte de `docker build --secret`, pas d'une lecture |
| liste de noms écrite en dur (env.sh) | **non repris** : lue dans `.env.example`, comme demandé ; C18 (`content.sh`) tient `.env.example` et `ci/legal-placeholder.env` aux mêmes noms |

**Aîné 3, trouvé pendant la marche — `scripts/release/build-image.sh`**, qui lit les valeurs de la
forge avant le build de mise en ligne.

| Garde | Ici ? |
|---|---|
| noms lus, jamais recopiés ; liste vide = `die` | **repris** (lus dans `.env.example`) |
| `set +x` en tête | **déjà là** ; le cas `bash -x` affirme désormais que les valeurs légales n'apparaissent pas |
| valeur portant `VALEUR-FACTICE` refusée | **repris sous une autre forme** : égalité avec la valeur factice du même nom, lue dans `ci/legal-placeholder.env` — aucune troisième écriture du marqueur. Une valeur dérivée du factice mais différente échouerait de toute façon à la vérification des pages, la forge refusant ce marqueur dans ses secrets |
| guillemet double refusé (dotenv tronque) | **non** : il protège un fichier **réécrit** puis relu ; ici le fichier est lu comme tout build le lirait |
| saut de ligne refusé | **sans objet** : un fichier dotenv se lit ligne à ligne |
| temporaires supprimés | **sans objet** : aucune valeur n'est écrite sur le disque ; seul le corps servi passe par le dossier temporaire, supprimé par le piège |

### Mutations (point 9)

Chaque garde nouvelle, retirée une à la fois, fait échouer au moins un cas (script de mutation dans
le dossier temporaire de la session, fichiers restaurés après chaque essai) :

| # | Garde retirée | Cas en échec |
|---|---|---|
| M1 | `-f && -r` du fichier | `fichier_legal_absent`, `fichier_legal_est_un_dossier` |
| M2 | refus de `.env` / factice par chemin | `fichier_legal_de_travail_refuse` |
| M3 | refus d'un fichier nommé `.env` | `fichier_legal_de_travail_refuse` |
| M4 | liste de noms vide | `modele_ou_factice_manquant_a_cote_du_script` |
| M5 | `.env.example` illisible | idem |
| M6 | variables manquantes | `fichier_legal_incomplet` |
| M7 | valeur faite de blancs | `valeur_faite_de_blancs` |
| M8 | valeur égale à la factice | `fichier_legal_copie_du_factice` |
| M9 | factice illisible | `modele_ou_factice_manquant_a_cote_du_script` |
| M10 | chemin relatif depuis le dossier d'appel | `fichier_legal_relatif_au_dossier_d_appel` |
| M11 | appels de `verifie_page_legale` | `pages_legales_verifiees_a_chaque_passage`, `valeurs_factices_servies` |
| M12 | page non servie en HTML 200 | `page_legale_absente_ou_pas_html` |
| M13 | recherche par nom (toujours « trouvé ») | `valeur_absente_de_la_page_fr`, `…_en`, `valeurs_factices_servies` |
| M14 | `tr -d '\0'` remplacé par `cat` | `corps_avec_octets_nuls` |
| M15 | décodage des entités | `valeur_echappee_retrouvee` |
| M16 | entités d'insécables | `insecables_de_la_typographie_retrouvees` |
| M17 | repli des insécables | idem |
| M18 | normalisation des blancs de la valeur | idem |
| M19 | rognage des espaces de bord | `espaces_de_bord_ignores` |
| M20 | première valeur non vide (la dernière gagnerait) | `premiere_valeur_non_vide` |
| M21 | clé comparée entière | `cle_comparee_entiere` |
| M22 | C23 tire ses pages de `legal.sh` (FR changée) | `test-legal-address.sh` |

Deux gardes écrites d'abord et **retirées** parce qu'aucun test ne pouvait les distinguer : un
`continue` sur valeur vide dans `legal_values_into` (couvert par la garde « première non vide »,
comme dans `env.sh`) et un compte de pages dans C23 (une liste vide y fait déjà signaler l'adresse
sur les pages légales).

**Limite écrite** : le contrôle de langue de `verifie_html`, antérieur, lit le corps par `grep`, qui
prend une page portant un octet nul pour un binaire ; le cas `corps_avec_octets_nuls` le constate et
n'affirme que la lecture des valeurs. Une page servie par nginx n'en porte pas.

### Résultats

- `bash scripts/tests/run.sh` : `tests: 928 cas réussis.` sur le poste, et dans `CHECK_IMAGE` par `scripts/ci/checks-job.sh` (code 0, `check: 11 contrôle(s) passés`) — le repli des insécables par `sed` sur les octets UTF-8 tient dans l’image, en locale C.
- `bash scripts/tests/run.sh scripts/tests/test-docs-headings.sh` : réussi.

## Exécution (02/10/2026, par Arnaud, depuis son terminal)

### Premier essai : `v0.1.0-rc.1`, échec à la livraison

- Audit (`scripts/rehearse-release.sh v0.1.0-rc.1`) : fichier légal lu (8 variables), clé du poste
  chargée dans l'agent privé, les deux connexions répondent, rien poussé.
- `--run` : `v0.1.0-rc.1` posé sur `origin/dev` (`ff9c422`) et poussé. Workflow `release`, run
  2374 : tag vérifié, contrôles passés, **image `eleyone-site:v0.1.0-rc.1` construite avec les
  vraies valeurs légales et contrôles de mise en ligne passés**, puis
  `release/ship: ssh est introuvable … Rien n'a été envoyé.` — le runner conteneurisé de la forge
  n'avait pas de client ssh. Arrêt par Ctrl-C ; rien n'avait été livré au serveur.
- **Correction** (hors dépôt, avec l'accord d'Arnaud) : `openssh-client` ajouté à l'image du runner,
  image reconstruite, runners redémarrés dans une fenêtre sans job ; `ssh -V` répond dans les deux
  conteneurs. **Dans le dépôt** : le prérequis manquait à `docs/procedures/gitea-actions.md`, ajouté
  par le commit « le runner doit porter ssh pour livrer » de cette branche.
- `v0.1.0-rc.1` reste posé (forge et miroir) : un tag poussé ne se reprend pas.

### Second essai : `v0.1.0-rc.2` puis `v0.1.0-rc.3`, réussi

**Écart avec la spec, voulu** : les critères nomment `v0.1.0-rc.1` et `v0.1.0-rc.2`. `rc.1` étant
consommé, la répétition est jouée sur la paire suivante ; le script vaut pour tout tag
`vX.Y.Z-rc.N` (story 11.8, revue de spec A5) et calcule le suivant.

`scripts/rehearse-release.sh v0.1.0-rc.2 --run`, sur `origin/dev` (`9075a59`). Workflows `release`
2384 (`rc.2`) et 2385 (`rc.3`) : succès. Sortie du script, en substance :

| Étape | Résultat |
|---|---|
| `rc.2` posé, attendu, en service sur `site-rehearsal` | ok |
| Tunnel par le compte d'administration | ouvert |
| Vérifications `rc.2` | accueil FR et EN 200 ; 404 FR et EN 404 ; mentions légales FR et EN 200, **les 8 valeurs légales présentes sur chacune** ; fichier empreinté 200 ; SVG sans objet (le site n'en porte pas) ; journaux sans adresse IP |
| `rc.3` posé, attendu, en service ; vérifications | mêmes onze lignes, toutes ok |
| `rehearse rollback v0.1.0-rc.2`, attendu, en service ; vérifications | mêmes onze lignes, toutes ok |
| `rehearse stop` | projet arrêté, images `rc.3` et `rc.2` supprimées |
| Production, proxy, DNS | non touchés (AD-22) |

### Critères d'acceptation

| Critère | Preuve |
|---|---|
| 1. `status` montre le tag en répétition ; le site répond par le tunnel, sans DNS ni port public ; contrôles de mise en ligne passés, C15 compris | « `eleyone-site:v0.1.0-rc.2` en service sur le canal de répétition » ; vérifications par `127.0.0.1:18080` ; image construite par `build-image.sh` au niveau `release` (C15 compris) dans les runs 2384 et 2385. |
| 2. En-têtes conformes, pages légales aux vraies valeurs, journaux sans IP | `verifie_html` contrôle les en-têtes d'AD-13 sur chaque page ; pages légales : 8 valeurs sur 8 en FR et en EN, trois fois (décision A2) ; journaux sans IP, trois fois. |
| 3. Retour arrière vérifié, puis arrêt qui supprime les images `-rc` | « retour arrière vers v0.1.0-rc.2, vérifié » ; « image … supprimée » pour `rc.3` et `rc.2`. |

**Ce que la répétition a appris** : deux défauts de chaîne trouvés avant toute mise en ligne — la clé
du poste que la procédure supprimait (PR n° 126) et le client ssh absent du runner (ci-dessus) —, plus
la vérification des connexions avant le premier tag (PR n° 127), née de la préparation.

## Revue du code

### 02/10/2026 — `945151b` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 128. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 6a4f0b438fe59fceb7a676f0

#### Rapport de revue (BMad & Projet)

##### Lentilles : edge-case-hunter & projet

- **lens**: `edge-case-hunter` / `projet`
  **location**: `scripts/checks/legal-address.sh:44`
  **trigger_condition**: L'affectation `pages_legales+=("$(checks_page_de_url "$url_legale")")` masque le code de retour de la commande substituée sous `set -e`.
  **guard_snippet**: `local chemin; for url in "${legal_page_urls[@]}"; do chemin=$(checks_page_de_url "$url") || exit 2; pages_legales+=("$chemin"); done`
  **potential_consequence**: Si l'URL ne correspond à aucun fichier, l'erreur passe en silence et un chemin vide est ajouté.
  **classification**: BLOQUANT

- **lens**: `edge-case-hunter` / `projet`
  **location**: `scripts/tests/test-rehearse-release.sh` (fonctions `ecris_valeurs_legales` et `nombre_de_noms`)
  **trigger_condition**: La construction `done <<< "$(noms_legaux)"` masque le code de retour de la fonction `noms_legaux`.
  **guard_snippet**: `local noms; noms=$(noms_legaux) || exit 1; while IFS= read -r nom; do ... done <<< "$noms"`
  **potential_consequence**: Si le fichier `.env.example` est illisible, l'erreur passe en silence et la boucle est ignorée.
  **classification**: BLOQUANT

##### Lentille : verification-gap

- Aucune faille de vérification identifiée. L'automatisation vérifie de bout en bout que les valeurs légales de mise en ligne sont effectivement présentes dans les pages servies, sans jamais afficher le moindre secret (conformité AD-9). Les valeurs factices sont rigoureusement distinguées des vraies.

VERDICT: BLOQUANT — erreurs masquées dans les scripts shell sous set -euo pipefail (masquage par array append et here-string).


#### Décisions de l'auteur sur la revue de `945151b` (Claude)

| # | Constat | Décision |
|---|---|---|
| R1-1 | `pages_legales+=("$(checks_page_de_url …)")` dans C23 avale le code de la substitution (BLOQUANT) | **Retenu.** `checks_page_de_url` ne peut aujourd'hui qu'écrire (`printf`), mais la forme est celle que le piège connu interdit. Le chemin est lu dans une variable avec `checks_die`, et un chemin vide est refusé. |
| R1-2 | `done <<< "$(noms_legaux)"` avale le code de `noms_legaux` (BLOQUANT) | **Retenu, et balayé (point 18).** `noms_legaux` rendait toujours 0 : elle rend désormais 1 sur un `.env.example` illisible ou sans nom, et ses cinq appelants lisent sa sortie dans une variable avec arrêt. Le balayage de la classe — une substitution en position d'argument ou de here-string — a trouvé **plus grave** que le constat : les pages légales des cas étaient posées par `pose_reponse … "$(page_legale …)"`, où la garde de `page_legale` (« la fixture ne porte pas … ») était avalée. Mesuré : avec une cible de remplacement inexistante, l'ancienne forme laissait `valeur_absente_de_la_page_en` **passer** (code 0) sur une page vide ; la nouvelle (`pose_page_legale`, corps et en-têtes lus dans des variables) l'arrête (« la fixture ne porte pas « INTROUVABLE » »). Même correction pour `$(urls_curl)`, `$(cle_http …)`, `$(cat "$fixture…")`, et, dans le script, pour `"$(legal_canonique …)"` dans le `[[ … ]]` du refus des fichiers de travail (un readlink en échec y aurait rendu le refus inopérant). Restent en argument des aides qui ne font qu'un `printf` (`legal_par_defaut`, `entetes_html` hors de `pose_page_legale`, et le code antérieur du fichier — `$(page fr)`, `$(entetes_html …)` —, que cette story ne touche pas). |
| R1-3 | Lentille verification-gap : aucune faille | Pris acte. |

### 02/10/2026 — `608d5f5` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 128. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ec9a87c7153e7c656672f1d3

##### Revue BMAD

- NON BLOQUANT : (edge-case-hunter) Les risques de masquage d'erreurs (par des appels de type `$(...)` dans des affectations de tableaux ou des `<<<`) relevés lors de la revue précédente ont été intégralement résolus. La gestion des codes de retour via des variables intermédiaires (avec `|| exit 1`, `|| return 1`, `|| die` ou `|| code=$?`) est systématique et robuste dans l'ensemble des nouveaux scripts et tests.
- NON BLOQUANT : (verification-gap) L'approche de vérification des valeurs légales ne présente aucune faille. Elle valide la présence des valeurs dans les pages françaises et anglaises après un processus rigoureux de décodage et de normalisation des espaces insécables, et rejette activement les valeurs vides, les valeurs factices résiduelles et l'usage de fichiers de configuration inappropriés.

##### Couche projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (l'automatisation du contrôle légal garantit une vérification ininterrompue).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (seul le nom des variables non trouvées est signalé).
- NON BLOQUANT : Skill, procédure et script concordent : la procédure décrit précisément les nouvelles vérifications ajoutées au script, et le skill en fait état avec exactitude.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (les filtres de traitement de texte et la mécanique d'extraction des variables légales ont été judicieusement factorisés dans `scripts/lib/text.sh` et `scripts/lib/legal.sh`).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail.

VERDICT: NON BLOQUANT — aucune


#### Décisions de l'auteur sur la revue de `608d5f5` (Claude)

Une première relance a été interrompue par `llm-review` (« le relecteur a tenté une commande shell, qui lui est refusée : rien n'est publié ») ; la seconde a rendu ce rapport. Ses sept points sont des constats de conformité, sans demande de changement :

| # | Constat | Décision |
|---|---|---|
| R2-1 | Masquages de la revue précédente résolus (NON BLOQUANT) | Pris acte ; la résolution et son balayage sont décrits sous R1-2. |
| R2-2 | Vérification des valeurs légales sans faille (NON BLOQUANT) | Pris acte. Le cas que la vérification ne couvre pas reste écrit : le contrôle de langue antérieur ne lit pas une page portant un octet nul (« Limite écrite », section Implémentation). |
| R2-3 | Critères d'acceptation satisfaits (NON BLOQUANT) | Pris acte, avec une réserve : le code satisfait l'arbitrage A2 ; les critères de la story eux-mêmes ne seront tenus qu'après la répétition jouée par Arnaud, d'où le statut `review`. |
| R2-4 | Aucune donnée privée ni secret affichable (NON BLOQUANT) | Pris acte ; `check-private.sh staged` a passé à chaque commit. |
| R2-5 | Skill, procédure et script concordent (NON BLOQUANT) | Pris acte. |
| R2-6 | Cohérence avec AGENTS.md et l'architecture (NON BLOQUANT) | Pris acte. |
| R2-7 | Aucune erreur silencieuse sous `set -euo pipefail` (NON BLOQUANT) | Pris acte. |

### 02/10/2026 — `684ad4d` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 128. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 41106ddbe20cf42d2cec47b1

Voici le rapport de revue du diff fourni (PR n° 128), basé sur les lentilles demandées et les règles du projet :

##### Revue BMAD

##### Lentille : edge-case-hunter
- NON BLOQUANT : Les risques de masquage des erreurs liées au chargement des variables légales (fichiers manquants, valeurs vides, correspondance par préfixe) ont été adressés. La gestion des codes de retour est stricte et aucune erreur n'est étouffée lors de l'extraction des données. Les valeurs avec des espaces de bord ou correspondant par erreur aux valeurs factices sont adéquatement rejetées.

##### Lentille : verification-gap
- NON BLOQUANT : La chaîne d'automatisation ne présente aucune faille de vérification. Les valeurs de mise en ligne vérifiées dans les pages FR et EN après décodage de toutes les entités HTML (ainsi que les normalisations d'espaces typographiques U+00A0 et U+202F) garantissent que ce qui est servi correspond impérativement et de façon robuste aux attentes de la répétition générale.

##### Couche Projet

- NON BLOQUANT : Les critères d'acceptation de la story 11.9 sont satisfaits (statut de répétition, tunnel actif, pages légales portant les vraies valeurs, journaux sans IP, retour arrière validé).
- NON BLOQUANT : Aucune donnée privée ni aucun secret n'est commité ou divulgué. Les scripts nomment de manière sécurisée les variables manquantes sans jamais afficher ni logger la valeur en elle-même ou l'adresse du serveur.
- NON BLOQUANT : Les mises à jour du script de répétition, de la documentation des procédures et de la description du skill concordent parfaitement.
- NON BLOQUANT : L'architecture retenue est cohérente avec les règles du dépôt (`AGENTS.md`), avec la factorisation adéquate des logiques communes d'extraction et de formatage texte dans `scripts/lib/text.sh` et `scripts/lib/legal.sh`.
- NON BLOQUANT : Toutes les erreurs d'exécution passent correctement. Les précédentes affectations problématiques masquant les codes de sortie (`array+=("$(...)")` et les boucles via `<<< "$( ... )"`) ont été refactorisées avec des variables intermédiaires interceptant explicitement le code de retour sous `set -euo pipefail`. 

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue de `684ad4d` (orchestrateur)

Les sept constats sont des constats de conformité, sans demande de changement : **pris acte**, un par un.

| # | Constat | Décision |
|---|---|---|
| 1 | Chargement des valeurs légales : aucune erreur étouffée | Pris acte ; couvert par les mutations M1 à M10 et M20, M21 (section « Implémentation »). |
| 2 | Vérification des pages après décodage et normalisation des insécables | Pris acte ; confirmé en réel : 8 valeurs sur 8, FR et EN, à chacun des trois passages de la répétition. |
| 3 | Critères d'acceptation satisfaits | Pris acte ; tableau « Critères d'acceptation » de la section « Exécution ». |
| 4 | Aucune donnée privée ni secret | Pris acte ; garde-fou rejoué par le verrou de fusion. |
| 5 | Script, procédure et skill concordent | Pris acte. |
| 6 | Cohérence avec AGENTS.md, factorisation dans `scripts/lib/` | Pris acte. |
| 7 | Plus aucune substitution n'avale un code de retour | Pris acte ; c'était le constat bloquant de la revue 1, corrigé dans `608d5f5` (avant rebase). |
