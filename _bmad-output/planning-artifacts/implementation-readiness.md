---
title: "Contrôle de préparation à l'implémentation : eleyone.fr"
status: draft
created: 2026-09-13
gate: CONCERNS
skill: bmad-sprint-planning (mode readiness)
---

# Contrôle de préparation à l'implémentation : eleyone.fr

Contrôle mené le 13/09/2026, en autonomie, sur l'état de `dev` au commit `7be1451`. C'est un contrôle, pas une correction : aucun document de planification n'a été modifié et `sprint-status.yaml` n'a pas été généré.

Documents recoupés :

- PRD : `prds/prd-eleyone.fr-2026-09-13/prd.md` (FR-1 à FR-39, NFR-1 à NFR-13, questions ouvertes Q1 à Q5, Q9 et Q13) ;
- architecture : `architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md` (AD-1 à AD-24, contrôles C1 à C24) ;
- UX : `ux-designs/ux-eleyone.fr-2026-09-13/DESIGN.md` et `EXPERIENCE.md` ;
- backlog : `epics.md` (14 epics et 86 stories, compte vérifié) ;
- contrat de contenu : `docs/format-cas.md` v0.4, `data/stack.yaml`, cas pilote `content/cases/chiliz/case-02-chiliz.{fr,en}.md` ;
- règles du dépôt : `AGENTS.md`, `scripts/check-private.sh`, `.githooks/pre-commit`, `.claude/settings.json`, `.gitignore`, `.antigravityignore`.

## Verdict

**Prêt avec réserves** (gate `CONCERNS`).

Le plan est implémentable. Les exigences sont tracées jusqu'aux stories, les décisions d'architecture sur lesquelles les stories s'appuient sont écrites, et les dépendances ne remontent presque jamais vers une story suivante. Il reste un point bloquant avant la première story : **aucune règle ne dit comment fusionner les premières PR**, alors que les verrous de fusion supposent des outils (CI, `sprint-status.yaml`, skills de l'Epic 0) qui n'existent pas encore. Une douzaine de points sont à régler avant l'epic qu'ils concernent, dont trois dans l'Epic 0 lui-même. Le reste relève d'une passe de mise à jour des documents.

Chemin critique vers le socle : Q2 (période et cadre des cas 01 et 05) et Q9 (titre de la page Chiliz) bloquent les stories 10.4 à 10.7, donc 11.10 et 11.11. Aucune des deux ne bloque les epics 0 à 9.

## Couverture et contrôles standard

| Contrôle | Résultat |
| --- | --- |
| Couverture des FR | FR-1 à FR-39 figurent tous dans la carte de couverture d'`epics.md`, avec au moins une story chacun. Aucune FR orpheline. |
| Couverture des NFR, contrôles et UX | NFR-1 à NFR-13, C1 à C24 et UX-DR1 à UX-DR24 sont rattachés à des stories. |
| Couverture des AD | AD-1 à AD-23 sont cités. **AD-24 n'est cité par aucune story** : `epics.md` dit encore « AD-1 à AD-23 » (§ Présentation et § Validation finale), alors que l'Epic 0 réalise AD-24. |
| Stories orphelines | Aucune : chaque story renvoie à une FR, une NFR, un AD ou une décision d'Arnaud. |
| Taille des stories | Correcte dans l'ensemble. Deux stories sont grosses : **5.1** (tout le système CSS, l'en-tête, le pied de page et la check-list AD-17 dans les deux modes) et **11.11** (tag, hôte NPM, vérifications, DNS, mesures). Proposition de découpe : 5.1a tokens, typographie et mode sombre, puis 5.1b en-tête, pied de page, lien d'évitement et focus ; 11.11a tag `v1.0.0` et hôte proxy sans IP, puis 11.11b DNS et mesures. |
| Ordre des dépendances | Pas de dépendance vers une story suivante, sauf trois cas signalés plus bas : 0.2 renvoie à la procédure de 11.7, 3.17 alimente `ci/release-pages.txt` créé en 11.1, et 11.1 à 11.9 sont placées après l'Epic 10 sans en dépendre. Une dépendance artificielle : 2.1 dépend de tout l'Epic 1, miroir GitHub (1.4) compris. |
| Testabilité des critères | Bonne : Étant donné / Quand / Alors, avec des commandes et des sorties vérifiables ; les relectures humaines sont marquées. Deux critères sont faux ou contradictoires : 3.1 (nombre de titres H2 du pilote) et 3.13 (déclencheurs du workflow). |
| Alignement UX et architecture | Bon sur le fond. Quelques écarts de libellés et de chemins, listés parmi les points mineurs. |
| Prérequis manquants | `sprint-status.yaml` absent (attendu, puisqu'il sort de la planification de sprint) ; `docs/procedures/` absent (créé par l'Epic 0) ; branche `main` absente (story 0.2). **Constat sur le poste : Docker, Hugo et D2 sont introuvables dans le `PATH` ; `jq` et `agy` sont installés.** |

## Constats classés

Pour chaque constat : où il se trouve, le problème, une proposition de correction, et qui décide. « Arnaud » : une décision est nécessaire. « Mise à jour » : une passe d'édition suffit, sans rien trancher.

### 1. Bloquant avant la première story

#### B-1. Verrous de fusion inapplicables au démarrage (tension 8)

- **Où** : `AGENTS.md` (§ Development workflow, points 3 et 4) ; AD-24 (verrous et exception documentaire) ; stories 0.6 et 0.7.
- **Problème** :
  - Avant la story 3.13, la CI n'existe pas. Pour une PR documentaire, le seul verrou exigé est la CI verte : elle n'a donc aucun verrou réel, et 0.7 affiche ce verrou « absent » sans dire si « absent » bloque.
  - Tant que `sprint-status.yaml` n'existe pas, 0.6 échoue : aucune PR n'est fusionnable.
  - Les stories 0.1 à 0.7 se fusionnent avant que leurs propres skills existent. `AGENTS.md` dit « apply these rules by hand », sans dire ce qui remplace la CI.
  - Le périmètre de l'exception documentaire diverge : `AGENTS.md` dit « planning documents under `_bmad-output/` », AD-24 et 0.7 disent « des `.md` sous `_bmad-output/` ». Or `sprint-status.yaml` est un `.yaml` : chaque mise à jour du suivi de sprint exigerait une revue LLM.
  - La première PR, celle de la story 0.1, touche `docs/procedures/` : elle est hors exception et exige une revue LLM avant que `llm-review` existe.
- **Proposition** : ajouter à AD-24 et à `AGENTS.md` une règle d'amorçage.
  1. **Verrou CI à trois états** `pass`, `fail` et `absent`. `absent` n'est admis que tant que `.gitea/workflows/checks.yaml` n'existe pas sur la branche de base ; le script le détecte lui-même, sans interrupteur manuel. Dès que le fichier existe, `absent` bloque.
  2. **Substitut à la CI tant qu'elle est absente** : `scripts/check-private.sh history` (C1), puis `scripts/check.sh` dès la story 3.2, lancés en local sur le SHA de tête, avec le résultat noté dans la PR. Pour une PR documentaire, ce substitut est alors le seul verrou.
  3. **Suivi de sprint** : lancer la planification de sprint juste après ce contrôle et avant la story 0.1. La PR qui ajoute `sprint-status.yaml` est la seule fusionnée sans verrou de suivi.
  4. **Avant les skills de l'Epic 0** : revue par `agy --mode plan`, lancée à la main dans un worktree temporaire hors du dépôt, avec le rapport collé en commentaire de PR au format d'AD-24. Fusion à la main par Arnaud.
  5. **Exception documentaire** : l'aligner sur un seul texte. Recommandation : tous les fichiers sous `_bmad-output/`, qui ne contient que des artefacts de cadrage et de suivi.
- **Qui décide** : Arnaud (décisions D-1 et D-2), puis mise à jour d'AD-24, d'`AGENTS.md` et des stories 0.6 et 0.7.

#### B-2. Planification de sprint non faite

- **Où** : `_bmad-output/implementation-artifacts/` (absent).
- **Problème** : la règle 9 des stories et le verrou 4 d'AD-24 supposent `sprint-status.yaml`.
- **Proposition** : après la décision sur B-1, lancer `bmad-sprint-planning` en mode complet ; `sprint-status.yaml` est la première PR fusionnée, selon la règle d'amorçage.
- **Qui décide** : Arnaud lance le skill ; le fichier lui-même se génère sans décision.

### 2. À corriger avant l'epic concerné

#### Epic 0 (le premier epic, donc à traiter tout de suite après B-1)

**E0-1. Format du rapport `llm-review` contradictoire**

- **Où** : AD-24 (« Revue par un LLM tiers ») ; stories 0.5 et 0.7.
- **Problème** :
  - AD-24 fixe la première ligne du commentaire : `llm-review sha=<SHA> base=<base> model=<modèle> verdict=<pass|block>`. La story 0.5 exige à la place une fin `VERDICT: BLOQUANT` ou `VERDICT: NON BLOQUANT`, et 0.7 lit ce second format. Deux développeurs produiraient deux formats incompatibles.
  - La story 0.5 ajoute un sens inverse (`AUTHOR_LLM=gemini`, revue par un modèle Claude) qu'AD-24 n'écrit pas.
  - La question de 0.5 sur le périmètre de la revue est déjà tranchée par AD-24 : toute la branche, `git diff <base>...<SHA>`, au SHA de tête.
- **Proposition** : aligner 0.5 et 0.7 sur l'en-tête d'AD-24, qui est lisible par script et porte déjà le SHA, la base et le modèle. Retirer la question sur le périmètre. Garder le sens inverse seulement si Arnaud le confirme, puis l'écrire dans AD-24.
- **Qui décide** : mise à jour des stories ; Arnaud pour le sens inverse (D-11).

**E0-2. Protections Gitea : un force-push réservé demande aussi le droit de push**

- **Où** : story 0.2 (critères « push direct sur `dev` refusé » et « force-push sur `dev` réservé à Arnaud ») ; AD-24 (« Branches »).
- **Problème** : d'après la documentation de Gitea, la liste d'autorisation du force-push ne vaut que pour un compte qui a **déjà** le droit de push sur la branche protégée. Pour qu'Arnaud puisse pousser `dev` en `--force-with-lease` après un hotfix, il doit être dans la liste de push de `dev` ; il peut alors aussi y pousser directement. Le critère « push direct sur `dev` refusé » ne peut donc pas valoir pour son compte.
- **Proposition** :
  - écrire dans AD-24 que, sur `dev`, le push direct du compte d'Arnaud reste techniquement possible et n'est interdit que par la procédure ;
  - ne garder le refus technique que pour les autres comptes ;
  - sur `main`, refuser tout push et tout force-push, et fusionner par l'API ;
  - reformuler le critère de 0.2 en conséquence ;
  - noter les réglages dans une procédure propre à la story, par exemple `docs/procedures/gitea-branches.md`, plutôt que dans la procédure `release` de la story 11.7 (ce qui est aujourd'hui une dépendance vers une story suivante).
- **Qui décide** : Arnaud (D-10), après constat sur la version de Gitea en service.

**E0-3. Écarts entre AD-24 et les stories de l'Epic 0**

- **Où** : `epics.md` (Epic 0, § Validation finale) ; AD-24 ; `AGENTS.md`.
- **Problème** :
  - aucune story de l'Epic 0 ne cite AD-24 ;
  - AD-24 décrit `sprint-consistency` comme la cohérence entre le suivi de sprint, les stories **et les branches**, alors que la story 0.6 ne vérifie que les statuts ;
  - AD-24 compte neuf outils, dont `hotfix`, alors que la liste d'`AGENTS.md` en compte huit, sans `hotfix` ;
  - AD-24 constate `jq` absent du poste et garde « [à valider par Arnaud] », alors que `jq` est désormais installé (`/usr/bin/jq`) : l'opération manuelle de 0.4 est obsolète ;
  - la story 0.5 ne liste pas en prérequis l'authentification d'`agy` auprès de Gemini, ni le réglage `deny` d'Antigravity sur le poste, qu'elle dit « faits hors backlog ».
- **Proposition** :
  - ajouter AD-24 aux lignes « Couvre » de 0.1 à 0.7, 3.16, 3.17, 11.7, 11.8 et 11.12 ;
  - trancher le périmètre de 0.6 : statuts seulement, ou branches aussi (par exemple une story `in-progress` sans branche `feat/*` signalée) ;
  - ajouter `hotfix` à `AGENTS.md` ;
  - clore la recommandation `jq` comme constatée ;
  - ajouter à 0.5 une opération manuelle : `agy` authentifié, et `agy models` qui répond.
- **Qui décide** : mise à jour ; Arnaud pour le périmètre de 0.6.

#### Epic 1

**E1-1. Rien n'empêche un push direct sur GitHub (tension 10a)**

- **Où** : AD-12 (« Aucun push ne va directement sur GitHub : seul le miroir push de Gitea y écrit ») ; story 1.4.
- **Problème** : la règle n'a aucun mécanisme. Un push direct sur GitHub contournerait le hook pre-receive, qui est la seule garantie non contournable des motifs privés.
- **Proposition** : ajouter à AD-12 et aux critères de 1.4 :
  1. un **ruleset GitHub** sur toutes les branches et tous les tags : restreindre les créations, mises à jour et suppressions, avec un seul acteur autorisé à contourner, l'identité du miroir. D'après la documentation de GitHub, une clé de déploiement peut être acteur de contournement. Il faut vérifier que le miroir push de la version de Gitea en service sait pousser en SSH ; sinon, utiliser un compte machine dédié avec un jeton à grain fin limité à ce dépôt ;
  2. `main` avec « Block force pushes », puisqu'elle n'est jamais réécrite. `dev` sans ce blocage pour le miroir, pour que le rebase après un hotfix passe (voir E11-4) ;
  3. un critère de test : un push direct depuis le compte personnel d'Arnaud est refusé par GitHub.
- **Qui décide** : Arnaud (D-9).

**E1-2. Le miroir face à la réécriture de `dev` (tension 9, volet miroir)**

- **Où** : story 1.4 ; AD-24 (« `dev` peut l'être après un hotfix, et le miroir la remplace alors sur GitHub »).
- **Problème** : aucun critère ne vérifie que le miroir accepte une mise à jour non fast-forward de `dev`, ni que les références internes de PR de Gitea ne font pas échouer la synchronisation (question déjà posée en 1.3).
- **Proposition** : ajouter à 1.4 un test sur une branche jetable réécrite puis synchronisée, et vérifier la liste des références effectivement poussées.
- **Qui décide** : mise à jour de la story ; le constat se fait dans la story.

#### Epic 2

**E2-1. Page Chiliz vide en production, C12 et C15 (tension 4, qui résout aussi la tension 1)**

- **Où** : AD-4 (« Une page de groupe sans aucun cas publié est rendue vide par Hugo… C15 l'interdit ») ; « Écarts et tensions », ligne FR-9 ; C12 ; stories 2.5 et 3.10.
- **Problème** : tant que le pilote est un brouillon, le build de production contient `/cas/chiliz/` sans section, et aucun lien de l'accueil n'y mène. C12, qui tourne à chaque CI sur `public/`, la signalera comme orpheline, de la story 3.10 jusqu'à la story 10.5. La CI serait rouge pendant six epics. C15 bloque aussi toute mise en ligne, répétition comprise.
- **Proposition** : poser la règle « **un `_index` de groupe reste en `draft: true` tant qu'aucun de ses cas n'est publié** ».
  - En production, la page de groupe n'est pas construite : ni C12 ni C15 ne la voient.
  - En rendu de travail (`--buildDrafts`), elle s'affiche avec le pilote.
  - La story 10.4 la passe en `draft: false` avant que 10.5 publie le cas 02 (ordre déjà en place). La même règle vaut pour tout groupe futur.
  - À constater dans 2.5 (question déjà posée) : un `_index` en brouillon ne casse ni la cascade, ni `case-url.html` en rendu de travail.
  - Repli si le constat échoue : C12 exclut les pages de groupe sans section, comme C15 les traite déjà.
  - Mettre à jour AD-4, la ligne FR-9 des « Écarts » et la question de 3.10.
- **Qui décide** : Arnaud (D-3), puis mise à jour.

**E2-2. Q9 ouverte, alors que DESIGN.md montre « Chiliz » (tension 5)**

- **Où** : PRD §11.2 Q9 et FR-9 ; `DESIGN.md` (« Échelle », « Page Chiliz ») ; `EXPERIENCE.md` (plan des titres, premier écran) ; stories 2.5 et 10.4.
- **Problème** : la maquette validée fixe de fait le titre « Chiliz », alors que la question reste ouverte. Q9 est sur le chemin critique du socle (10.4 → 10.5 → 11.10 → 11.11).
- **Proposition** : trancher Q9 tout de suite. Titre « Chiliz » en FR et en EN, sans introduction en v1 : les sources n'en donnent pas (NFR-10), et la ligne de contexte EN du cas 02 présente déjà l'entreprise. Q9 passe alors au §11.1 et les stories 10.4 et 10.5 sont débloquées. Le `_index` de 2.5 porte déjà ce titre, en brouillon (E2-1).
- **Qui décide** : Arnaud (D-4).

**E2-3. Chargeur `env.sh` et `.env.example` : résolu dans l'architecture, pas dans les stories (tension 2)**

- **Où** : AD-9 ; C18 ; stories 0.1, 2.4 et 3.6 ; § Tensions restantes, point 11.
- **Problème** : AD-9 fixe déjà la solution. `.env.example` liste exactement les sept `HUGO_LEGAL_*` et les trois `GITEA_*`, et `scripts/env.sh` ne transmet à Hugo que les `HUGO_LEGAL_*`. C18 contrôle déjà `.env.example` contre les noms d'AD-9 et d'AD-24. Mais :
  - le critère de 2.4 ne cite que les sept variables légales et n'exige pas le filtrage ;
  - 3.6 garde la question et un critère périmé ;
  - le point 11 des « Tensions restantes » n'a plus lieu d'être.
- **Proposition** : ajouter à 2.4 le critère « `.env` contient une variable `GITEA_TOKEN` factice ; le processus `hugo` lancé par `build.sh` ne la voit pas dans son environnement ». L'implémentation lit seulement les lignes `^HUGO_LEGAL_` de `.env`, sans `source` complet ni `set -a`. Aligner les critères de 2.4 et 3.6 sur C18, et supprimer la question de 3.6 et les questions équivalentes de 0.1 et 2.4.
- **Qui décide** : mise à jour.

**E2-4. Outils absents du poste de développement**

- **Où** : stories 2.1, 2.2, 3.12 et 4.1 ; AD-1 ; AD-10.
- **Problème** : `docker`, `hugo` et `d2` sont introuvables dans le `PATH` du poste (constat du 13/09/2026, shell WSL). `checks-job.sh`, le build d'image et `scripts/dev.sh` en dépendent ; seule 2.1 pose la question pour Hugo et D2, et aucune story ne liste Docker.
- **Proposition** : ajouter une opération manuelle d'Arnaud à 2.1, « Docker disponible dans le shell WSL », et fixer l'installation locale de Hugo et D2. Recommandation : `scripts/ci/install-tools.sh --local` installe les binaires vérifiés par sha256 dans un dossier ignoré par git (par exemple `.tools/`), que `dev.sh` et `build.sh` ajoutent au `PATH`. Une seule source de versions reste ainsi `tools.env`.
- **Qui décide** : Arnaud (D-15).

**E2-5. Dépendance artificielle de 2.1 sur tout l'Epic 1**

- **Où** : story 2.1 (« Dépendances : Epic 1 (ordre du squelette) »).
- **Problème** : le site ne peut pas démarrer tant que le miroir GitHub (1.4, opérations manuelles sur GitHub) n'est pas en place. L'ordre imposé par AD-12 porte sur l'activation du miroir, pas sur le build du site.
- **Proposition** : `Dépendances : 1.2` (garde-fou serveur installé avant les pushs de code).
- **Qui décide** : Arnaud.

#### Epic 3

**E3-1. Déclencheurs du workflow Gitea**

- **Où** : story 3.13 (« `push` sur `main`, `pull_request` ») et story 3.14 (démonstration « push sur `main` ») ; AD-11 (`checks.yaml` sur `push` de `dev` et de `main`, et sur `pull_request`) ; WS-4 (« un push sur `dev` »).
- **Problème** : la story omet `dev`, alors que les fusions en squash arrivent sur `dev` et que le verrou « CI verte » d'AD-24 lit les statuts de ces runs.
- **Proposition** : aligner 3.13 et 3.14 sur AD-11.
- **Qui décide** : mise à jour.

**E3-2. Critère faux sur le pilote**

- **Où** : story 3.1 (« Entrée du pilote : cinq titres H2 tels qu'écrits »).
- **Problème** : le pilote compte **six** titres H2 en FR et en EN (constaté), ce que confirme le spike d'AD-4 (02.1 à 02.6). Le test échouerait.
- **Proposition** : écrire « six titres H2 ».
- **Qui décide** : mise à jour.

**E3-3. `ci/release-pages.txt` est alimenté avant d'être créé**

- **Où** : AD-24 (`publish-case` ajoute le cas à `ci/release-pages.txt`) ; story 3.17 (ne le mentionne pas) ; story 11.1 (crée le fichier).
- **Problème** : c'est une dépendance vers une story suivante. Les stories 10.5 à 10.7 publient des cas avant que la liste existe, et personne n'y ajoute les pages simples.
- **Proposition** : voir E11-1. Créer le fichier dès la story 2.2 (avec `home`) ; 3.17 y ajoute le cas et, pour un cas groupé, `group-<group>` ; 9.1 à 9.4 y ajoutent leurs pages.
- **Qui décide** : Arnaud (D-5), puis mise à jour.

**E3-4. Rédaction du README-cas non attribuée (tension 10b)**

- **Où** : story 3.15 (« Prérequis de contenu : texte du README, rédigé ou validé par Arnaud ; aucune entrée n'attribue sa rédaction ») ; FR-30 ; section « README-cas » de l'architecture.
- **Problème** : la story d'intégration existe, mais personne n'est chargé du texte. Le README est hors exception documentaire, donc soumis à la revue LLM.
- **Proposition** : le développeur rédige en anglais un premier jet à partir des seuls documents publics (PRD UJ-3 et FR-30, AD-12, AD-24, historique git, branches `design/*` et `experiment/d2-bilingue`), puis Arnaud relit la voix et les faits. Aucune source privée n'est nécessaire : le fait « sources privées repérées avant publication, historique réécrit » est déjà public dans le PRD.
- **Qui décide** : Arnaud (D-12).

**E3-5. Règle JSON-LD de C10 avant la story 9.6**

- **Où** : story 3.8 (question) ; C10 ; AD-20.
- **Problème** : C10 exige « exactement un bloc sur l'accueil », qui n'existe qu'à la story 9.6. Appliquée dès 3.8, la règle rendrait la CI rouge de 3.8 à 9.6.
- **Proposition** : 3.8 implémente « au plus un bloc, conforme, et seulement sur l'accueil » ; 9.6 passe la règle à « exactement un » (critère déjà prévu en 9.6).
- **Qui décide** : mise à jour.

#### Epic 9

**E9-1. Sources du JSON-LD `Person` (tension 3)**

- **Où** : FR-35 ; AD-20 (« construit par `jsonify` à partir du contenu ») ; story 9.6 (question).
- **Problème** : trois champs n'ont pas de source écrite.
  - `name` et `alternateName` : `identity` de `content/_index` (AD-19), déjà fixé ;
  - `address.addressCountry` : constante `FR` (AD-20), déjà fixé ;
  - `url` : `baseURL`, déjà fixé ;
  - `jobTitle` : **aucune source** ;
  - LinkedIn : `linkedin` du front matter de `content/contact` (AD-3), qui existe mais n'est pas désigné comme source ;
  - GitHub : **aucune source**. `params.source_url` est l'URL du dépôt, pas un profil de personne.
- **Proposition** : écrire dans AD-20 :
  - `jobTitle` ← nouvelle clé `job_title` de `content/_index.{fr,en}.md`, dans la langue du fichier, par exemple le premier segment du titre du site ;
  - LinkedIn ← `linkedin` de `content/contact` ;
  - GitHub ← nouvelle clé `github` de `content/contact`, URL du **profil**, identique en FR et en EN et ajoutée à C3 ;
  - un lien vide est omis de `sameAs`, jamais remplacé par une valeur factice.
- **Qui décide** : Arnaud (D-7), puis mise à jour d'AD-20, C3, C10 et 9.6.

#### Epic 10 (et avant la rédaction des cas 01, 05 et 06 par Arnaud)

**E10-1. Identifiants de poste non fixés (tension 7)**

- **Où** : AD-18 (seuls `position-chiliz` et `position-ton-pote-le-geek`) ; stories 10.2 et 13.3 (`position-april-technologies`, « donné par la consigne de réalignement », sans source dans les documents) ; `docs/format-cas.md`.
- **Problème** : un cas porte la clé `position` de son poste, et AD-18 interdit de renommer un identifiant publié. Les cas 01, 05 et 06 sont rédigés par Arnaud avec son agent, en parallèle du développement : il lui faut les identifiants avant la rédaction. Arnaud a en outre deux passages chez April (2013–2014 pour le compte de CGI, 2017 en prestation Modis), d'où un risque de collision.
- **Proposition** : ajouter à AD-18 une règle de nommage.
  - `position-<société en kebab-case>` quand la société n'apparaît qu'une fois dans le parcours ;
  - `position-<société>-<année de début>` quand elle apparaît plusieurs fois ;
  - le poste du cas 06 devient alors `position-april-technologies-2017` ;
  - la liste complète des identifiants est tirée du CV et figée dans AD-18 avant la story 10.2, avec un renvoi depuis `docs/format-cas.md`.
- **Qui décide** : Arnaud (D-8).

#### Epic 11

**E11-1. Répétition « tôt » bloquée par C15 (tension 1)**

- **Où** : FR-39 (« exercée tôt ») ; AD-22 ; C15 ; `ci/release-pages.txt` ; story 11.9 (« point à trancher ») ; ordre des epics 10 et 11.
- **Problème** : C15 exige les pages de `ci/release-pages.txt` et aucune page de groupe vide. Si la liste décrit le socle, un tag `-rc` échoue tant que le contenu du socle, bloqué par Q2 et Q9, n'est pas publié.
- **Constat** : une liste propre aux tags `-rc` **n'est pas nécessaire**.
- **Proposition** :
  1. `ci/release-pages.txt` devient la liste **cumulative des pages publiées attendues à ce commit**. Elle est créée en 2.2 et alimentée par les stories qui publient une page et par `publish-case` (E3-3). C15 garde son rôle : aucune page attendue ne disparaît ;
  2. la complétude du socle se vérifie une seule fois, pour `v1.0.0` : le skill `release` refuse `v1.0.0` si la liste ne contient pas les pages de FR-32. Ce contrôle est ajouté aux critères de 11.7 et 11.11 ;
  3. la page Chiliz vide disparaît de la production grâce à E2-1 ;
  4. une première répétition peut alors avoir lieu dès la story 11.8, sur un tag `v0.1.0-rc.1` (accepté par la règle `vX.Y.Z-rc.N` d'AD-11), avec les pages déjà publiées et les vraies valeurs légales. Le jalon `v1.0.0-rc.1` / `rc.2` d'AD-22 reste la répétition générale sur l'arbre du socle ;
  5. placer 11.1 à 11.9 avant l'Epic 10, puisqu'elles n'en dépendent pas.
- **Qui décide** : Arnaud (D-5).

**E11-2. Portée de la règle « `v1.0.0` exige un tag `-rc` de même arbre »**

- **Où** : AD-22 (dans le workflow `release`, pour `v1.0.0`) ; story 11.5 (règle absente des critères) ; story 11.7 (règle étendue à tout `vX.Y.Z`, dans le script).
- **Problème** : trois textes, trois portées. Étendue à toute publication, la règle impose une répétition avant chaque cas publié (13.1 à 13.3), ce que FR-39 ne demande pas.
- **Proposition** : suivre AD-22. Contrôle bloquant dans le workflow pour `v1.0.0`, ajouté aux critères de 11.5 ; simple avertissement dans le script `release` pour les tags suivants.
- **Qui décide** : Arnaud (D-6).

**E11-3. Verrous de la PR `dev` → `main`**

- **Où** : AD-24 (« `release` et `hotfix` appliquent les mêmes verrous ») ; story 11.7 (aucun verrou dans les critères ; question « le script fusionne-t-il lui-même ? ») ; `AGENTS.md` point 4 (« merging is a human decision »).
- **Problème** : les critères de 11.7 n'appliquent pas les verrous. Une revue LLM de tout l'écart `main...dev` relirait des stories déjà relues une par une, pour un diff potentiellement très gros. Et la fusion automatique contredit la règle « fusion = décision humaine ».
- **Proposition** :
  - verrou de revue de la PR de publication tenu si chaque commit de `main..dev` est le squash d'une PR fusionnée par `verify-and-merge-pr`, repérée par le numéro de PR dans le message de commit ;
  - les verrous garde-fou, CI et suivi de sprint s'appliquent tels quels ;
  - fusion seulement avec `--merge` explicite lancé par Arnaud, comme pour `verify-and-merge-pr`.
- **Qui décide** : Arnaud (D-13).

**E11-4. Hotfix : revues périmées et nom de branche (tension 9, volet revues)**

- **Où** : AD-24 (« Hotfix », étape 3) ; story 11.12 (la case « revues à refaire » est présente, mais aucune règle ne la porte) ; `create-pull-request` (`fix/*` → `dev`).
- **Problème** :
  - le rebase de `dev` réécrit les SHA des branches `feat/*` ouvertes, et leurs rapports `llm-review`, attachés au SHA de tête, ne valent plus. AD-24 ne le dit pas ;
  - `fix/*` sert à la fois aux correctifs vers `dev` et aux hotfix vers `main`, alors que `create-pull-request` déduit la base du préfixe.
- **Proposition** :
  - écrire dans AD-24 qu'après un hotfix, chaque PR ouverte est rebasée puis relue par `llm-review` ; c'est acceptable vu le coût d'une revue ;
  - réserver le préfixe `hotfix/*` aux branches issues de `main`.
- **Qui décide** : Arnaud (D-14).

#### Epic 12

**E12-1. Paires sans `translationKey`**

- **Où** : AD-16 (filtre `diagrams/**`, `assets/live-material/**`, `i18n/**`) ; story 12.1 (question).
- **Problème** : ces fichiers n'ont pas de `translationKey`. Il faut dire comment former les paires : `fr.d2` avec `en.d2`, `<id>.fr.md` avec `<id>.en.md`, `i18n/fr.yaml` avec `i18n/en.yaml`.
- **Proposition** : écrire cette règle d'appariement par nom de fichier dans AD-16.
- **Qui décide** : mise à jour.

### 3. Mineur : documents périmés

Pour tout ce qui suit, une passe de mise à jour suffit. Les modifications d'`AGENTS.md` sont hors exception documentaire : revue LLM requise.

| # | Document et emplacement | Écart constaté | Correction proposée |
| --- | --- | --- | --- |
| M-1 | PRD, FR-23 | Cite « mise en avant » parmi les métadonnées comparées | Retirer ; ajouter `position` (C3) |
| M-2 | PRD, §3 Glossaire | L'entrée « Cas mis en avant » subsiste | Retirer l'entrée, ou la marquer obsolète avec renvoi au §11.1 |
| M-3 | PRD §0 ; `DESIGN.md` et `EXPERIENCE.md` (sources) | « format v0.3 » | « v0.4 » |
| M-4 | Architecture : front matter (« v0.3 ; v0.4 proposée ici »), AD-4 (« comme le fixe v0.3 »), AD-18 (« v0.4 (proposé) »), section « `docs/format-cas.md` v0.4 » (« faits hors de ce document ») | Le passage en v0.4 est fait | Passer à « v0.4, en place » |
| M-5 | `AGENTS.md`, l. 5 et l. 51 | « nothing has been planned or built yet » ; « format-cas.md (v0.3 …) » | Mettre à jour : planification faite, v0.4 |
| M-6 | `AGENTS.md`, liste des skills | Huit skills, sans `hotfix` (AD-24 en compte neuf) | Ajouter `hotfix` |
| M-7 | `EXPERIENCE.md`, impact I-1 | `static/cv/` | `assets/cv/` (AD-21) |
| M-8 | `EXPERIENCE.md`, « Points encore à valider » | Test des trente secondes (Q14 tranchée) ; marqueur « Brouillon » (décidé : AD-5, décision 34 de l'architecture) | Retirer ces deux points |
| M-9 | `EXPERIENCE.md`, « Voice and Tone » | `back_to_career` EN « à valider » alors que FR-15 le dit validé | Passer à « décidé » ; retirer la question de 2.7 |
| M-10 | `EXPERIENCE.md`, « Voice and Tone » | `based_in` présenté comme clé i18n, alors qu'AD-19 en fait une clé de front matter de `content/_index` | Aligner sur AD-19 (contenu, AD-3) |
| M-11 | `DESIGN.md`, `site-footer` | « Code source du site » présenté comme toujours affiché | Ajouter « si `params.source_url` est renseigné » (I-2, AD-3) |
| M-12 | Architecture, « Écarts et tensions » | « FR-33 et NFR-9 reçoivent cette exception dans la mise à jour du PRD en cours » ; « Question 16 : le PRD est mis à jour en parallèle » ; ligne FR-9 (page Chiliz vide) | Les mises à jour du PRD sont faites : retirer ; réécrire la ligne FR-9 après E2-1 |
| M-13 | Architecture, AD-24 et « Recommandations à valider » | `jq` « absent (constat du 13/09/2026) », « [à valider par Arnaud] » | `jq` installé : clore |
| M-14 | `epics.md`, § Présentation et § Validation finale | « AD-1 à AD-23 » | « AD-1 à AD-24 » |
| M-15 | `epics.md`, § Tensions restantes | Point 2 (tags `-rc` sur `main` : AD-11 et AD-22 disent déjà `dev`) ; point 11 (résolu par AD-9 et C18) ; point 13 (AD-24 existe) ; point 14, volet branches (la section « README-cas » les cite déjà) | Retirer ou réduire au reliquat |
| M-16 | `epics.md`, story 0.4 | Opération manuelle « installer `jq` » | Remplacer par « constater `jq` » |
| M-17 | `epics.md`, story 0.5 | Question sur le périmètre de la revue, tranchée par AD-24 | Retirer |
| M-18 | Tous les artefacts | `status: draft` sur des documents dits validés (PRD, architecture, UX, backlog) | Passer à `validated`, ou définir `draft` comme « vivant, fait foi » |

## Tensions connues : état vérifié

| # | Tension | État | Preuve |
| --- | --- | --- | --- |
| 1 | Répétition `-rc` impossible avant les pages du socle (C15) | **Confirmée** ; une liste propre aux tags `-rc` n'est **pas nécessaire** | C15 lit `ci/release-pages.txt` et interdit une page de groupe vide ; AD-22 fait passer un `-rc` par la même chaîne. Proposition : E11-1 et E2-1 |
| 2 | `.env.example` avec Gitea contre C18 ; `env.sh` charge le jeton | **Déjà résolue dans l'architecture** ; reliquat dans les stories | AD-9 : `.env.example` liste exactement les `HUGO_LEGAL_*` et les `GITEA_*` ; `env.sh` ne transmet à Hugo que les `HUGO_LEGAL_*`. C18 : « exactement les noms d'AD-9 et d'AD-24 ». Stories 2.4 et 3.6 et tension 11 d'`epics.md` pas à jour ; critère de filtrage absent (E2-3) |
| 3 | Sources de `jobTitle`, LinkedIn et GitHub dans le JSON-LD | **Confirmée** pour `jobTitle` et GitHub ; LinkedIn a une source (`content/contact`) mais n'est pas désignée | AD-20 : « à partir du contenu », sans source par champ. Proposition : E9-1 |
| 4 | Page Chiliz vide contre la détection d'orphelins de C12 | **Confirmée** | Architecture, « Écarts », FR-9 : page vide dans le build de production tant que le pilote est en brouillon ; C12 porte sur toutes les pages de `public/`. Proposition : E2-1 |
| 5 | Q9 ouverte, `DESIGN.md` affiche « Chiliz » | **Confirmée** | PRD §11.2 Q9 ; `DESIGN.md` : « page Chiliz (« Chiliz ») » et « `page-title` « Chiliz » » ; `EXPERIENCE.md` : `h1` « Chiliz ». Proposition : E2-2 |
| 6 | Mentions périmées | **Confirmée**, et plus large que listé | FR-23 « mise en avant » ; PRD §0, `DESIGN.md`, `EXPERIENCE.md` en v0.3 ; I-1 `static/cv/` ; « à valider » sur le test (Q14) et le marqueur. En plus : glossaire du PRD, `AGENTS.md`, architecture, `back_to_career`, `based_in`, statuts `draft` (M-1 à M-18) |
| 7 | Identifiants de poste au-delà des trois connus | **Confirmée** ; `position-april-technologies` n'a aucune source écrite | AD-18 ne fixe que `position-chiliz` et `position-ton-pote-le-geek`. Proposition : E10-1 |
| 8 | Verrous de fusion inopérants au démarrage | **Confirmée**, et aggravée par le périmètre `.md` de l'exception | AD-24 (verrou 3 « signalé absent », exception « `.md` ») contre `AGENTS.md` (« planning documents ») ; story 0.6 échoue sans `sprint-status.yaml`. Proposition : B-1 |
| 9 | Hotfix : revues périmées, miroir et réécriture de `dev` | **Confirmée** ; volet revues noté dans 11.12 mais absent d'AD-24 ; volet miroir non testé ; volet protections Gitea contradictoire | AD-24, étape 3 ; documentation Gitea : un force-push autorisé exige déjà le droit de push. Propositions : E0-2, E1-2, E11-4 |
| 10a | Aucun mécanisme contre un push direct sur GitHub | **Confirmée** | AD-12 énonce la règle sans moyen. Proposition : E1-1 |
| 10b | README-cas sans auteur | **Confirmée** pour la rédaction ; l'intégration a sa story (3.15) | Story 3.15, prérequis de contenu. Proposition : E3-4 |
| 10c | Outillage de l'Epic 0 hors AD ; AD-24 à vérifier | **Largement résolue** par AD-24 (`agy` en `--mode plan`, worktree hors dépôt, trois niveaux, verrous, exception, jeton) ; **reliquats** | Format de rapport contradictoire (E0-1), périmètre de `sprint-consistency`, `hotfix` absent d'`AGENTS.md`, AD-24 non cité par le backlog (E0-3) |

## Décisions à prendre par Arnaud

Chaque question porte une recommandation. Les deux premières sont à trancher avant la première story.

1. **D-1. Règle d'amorçage des verrous.** Tant que `.gitea/workflows/checks.yaml` n'existe pas sur la base, accepte-t-on le verrou CI « absent », remplacé par `check-private.sh history` puis `scripts/check.sh` lancés en local et notés dans la PR, et les PR de l'Epic 0 relues à la main par `agy` avant que `llm-review` existe ?
   *Recommandation : oui, détection automatique par la présence du workflow, sans interrupteur manuel (B-1).*
2. **D-2. Périmètre de l'exception documentaire.** Couvre-t-elle tous les fichiers sous `_bmad-output/` (dont `sprint-status.yaml`), ou seulement les `.md` ?
   *Recommandation : tout `_bmad-output/`, en alignant AD-24 et la story 0.7 sur `AGENTS.md`.*
3. **D-3. Page de groupe en brouillon.** Le `_index` Chiliz reste-t-il en `draft: true` jusqu'à la publication du cas 02, pour qu'aucune page de groupe vide n'existe en production ?
   *Recommandation : oui, avec constat dans 2.5 ; repli : C12 exclut les pages de groupe sans section (E2-1).*
4. **D-4. Q9.** Le titre de la page Chiliz est-il « Chiliz », sans introduction en v1 ?
   *Recommandation : oui ; cela débloque 10.4, puis 10.5.*
5. **D-5. Liste des pages de mise en ligne.** `ci/release-pages.txt` devient-il la liste cumulative des pages publiées, créée en 2.2, avec la complétude du socle vérifiée seulement pour `v1.0.0`, et les stories 11.1 à 11.9 placées avant l'Epic 10 pour répéter tôt ?
   *Recommandation : oui, plutôt qu'une liste propre aux tags `-rc` (E11-1).*
6. **D-6. Tag `-rc` de même arbre.** Est-il exigé pour `v1.0.0` seulement, comme dans AD-22, ou pour chaque publication ?
   *Recommandation : `v1.0.0` seulement, bloquant dans le workflow ; avertissement dans le script pour les suivants.*
7. **D-7. Sources du JSON-LD.** `jobTitle` vient-il d'une clé `job_title` de `content/_index`, et GitHub d'une clé `github` (profil) de `content/contact`, à côté de `linkedin` ?
   *Recommandation : oui, profil GitHub plutôt que dépôt ; lien vide omis.*
8. **D-8. Identifiants de poste.** Adopte-t-on `position-<société>`, avec `-<année de début>` en cas de société répétée (donc `position-april-technologies-2017`), la liste complète étant figée dans AD-18 avant la rédaction des cas 01, 05 et 06 ?
   *Recommandation : oui, et tout de suite, puisque la rédaction des cas se fait en parallèle.*
9. **D-9. Push direct sur GitHub.** Protège-t-on le dépôt public par un ruleset qui restreint toute écriture, avec l'identité du miroir (clé de déploiement ou compte machine) seule autorisée à contourner, et `main` en « Block force pushes » ?
   *Recommandation : oui, avec un test de refus d'un push direct dans 1.4.*
10. **D-10. Protection de `dev` sur Gitea.** Puisque le force-push autorisé suppose le droit de push, accepte-t-on que le compte d'Arnaud puisse techniquement pousser sur `dev`, l'interdiction du push direct étant alors procédurale pour lui ?
    *Recommandation : oui pour `dev` ; aucun push ni force-push sur `main`.*
11. **D-11. Revue dans le sens inverse.** Garde-t-on la revue d'un code écrit par Gemini par un modèle Claude (story 0.5), absente d'AD-24 ?
    *Recommandation : oui si Gemini écrit du code un jour, en l'écrivant dans AD-24 ; sinon, retirer de 0.5.*
12. **D-12. Rédaction du README-cas.** Qui écrit le texte ?
    *Recommandation : premier jet en anglais par le développeur, à partir des documents publics, relu par Arnaud.*
13. **D-13. Verrous de la PR de publication.** La revue de `dev` → `main` est-elle tenue quand chaque commit est le squash d'une PR déjà vérifiée, avec fusion seulement par `--merge` lancé par Arnaud ?
    *Recommandation : oui (E11-3).*
14. **D-14. Hotfix.** Réserve-t-on le préfixe `hotfix/*` aux branches issues de `main`, et relit-on chaque PR ouverte après le rebase de `dev` ?
    *Recommandation : oui aux deux.*
15. **D-15. Outils du poste.** Docker dans le shell WSL est-il un prérequis déclaré, et Hugo et D2 s'installent-ils en local par `install-tools.sh --local` dans un dossier ignoré ?
    *Recommandation : oui aux deux (E2-4).*
16. **D-16. Statut des artefacts.** Passe-t-on les documents validés de `draft` à `validated` ?
    *Recommandation : oui, au moment de la passe de mise à jour.*
17. **D-17. Périmètre de `sprint-consistency`.** Le skill vérifie-t-il aussi les branches, comme le dit AD-24, ou seulement les statuts, comme la story 0.6 ?
    *Recommandation : statuts seulement en v1 ; ajouter les branches plus tard si un écart se produit.*

## Suite recommandée

1. Arnaud tranche D-1 et D-2, puis, idéalement dans la même séance, D-3, D-4, D-5, D-8 et D-10.
2. Une passe de mise à jour applique les décisions et les corrections M-1 à M-18. Skill : `bmad-correct-course`, puisque les changements touchent le PRD, l'architecture, l'UX et le backlog.
3. `bmad-sprint-planning` en mode complet génère `sprint-status.yaml`, première PR fusionnée selon la règle d'amorçage.
4. Story 0.1.

## Sources vérifiées

- Gitea, branches protégées : un force-push par liste d'autorisation suppose le droit de push. [Protected branches, documentation Gitea](https://docs.gitea.com/usage/access-control/protected-branches/).
- GitHub, rulesets : restriction des mises à jour, blocage des force-pushes, clés de déploiement parmi les acteurs de contournement. [Managing code rulesets, documentation GitHub](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/managing-policies-for-code-governance).
- Constats locaux du 13/09/2026 : 86 stories dans `epics.md` ; six titres H2 dans chaque fichier du pilote ; branches `dev`, `design/dossier-architecture`, `design/suisse` et `experiment/d2-bilingue`, sans `main` ni tag ; `core.hooksPath` réglé sur `.githooks` ; `jq` et `agy` présents, `docker`, `hugo` et `d2` absents du `PATH` ; `docs/procedures/` et `.env.example` absents.
