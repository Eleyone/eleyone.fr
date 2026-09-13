---
title: "Proposition de changement : décisions du contrôle de préparation à l'implémentation"
status: approved
created: 2026-09-13
skill: bmad-correct-course
scope: moderate
source: _bmad-output/planning-artifacts/implementation-readiness.md
---

# Proposition de changement : décisions du contrôle de préparation à l'implémentation

Proposition produite le 13/09/2026 par `bmad-correct-course`, en mode batch et sans interlocuteur. Arnaud a lu le contrôle de préparation à l'implémentation (`implementation-readiness.md`) et **accepté les dix-sept décisions D-1 à D-17 telles que recommandées**, le 13/09/2026. La proposition est donc approuvée d'office, et ses modifications sont appliquées aux documents dans la même passe. `sprint-status.yaml` n'est pas généré : c'est l'étape suivante.

## 1. Résumé du problème

**Déclencheur.** Aucune story n'est encore commencée. Le déclencheur est le contrôle de préparation à l'implémentation mené sur `dev` au commit `7be1451`, conclu « prêt avec réserves » (gate `CONCERNS`).

**Nature.** Écarts de cadrage relevés avant l'implémentation, pas une limite technique ni un pivot :

- un point bloquant avant la première story : aucune règle ne dit comment fusionner les premières PR, alors que les verrous supposent une CI, `sprint-status.yaml` et des skills qui n'existent pas encore (B-1, B-2) ;
- une douzaine de points à régler avant l'epic qu'ils concernent, dont des contradictions entre documents : format du rapport `llm-review`, protections Gitea, page Chiliz vide face à C12, répétition « tôt » bloquée par C15, sources du JSON-LD, identifiants de poste, push direct sur GitHub ;
- dix-huit mentions périmées (M-1 à M-18) : format v0.3, `static/cv/`, « AD-1 à AD-23 », « à valider » sur des points décidés, statuts `draft`.

**Preuves.** Toutes sont citées dans le contrôle : `epics.md` (86 stories, compte vérifié), six titres H2 dans chaque fichier du pilote, documentation Gitea sur le force-push, documentation GitHub sur les rulesets, constats du poste (`jq` et `agy` présents ; `docker`, `hugo` et `d2` absents du `PATH`).

## 2. Analyse d'impact

### Checklist de navigation du changement

| Section | État | Constat |
| --- | --- | --- |
| 1. Déclencheur et contexte | [x] | Contrôle de préparation ; écarts de cadrage documentés avec preuves |
| 2. Impact sur les epics | [x] | Epics 0, 1, 2, 3, 9, 10, 11, 12 et 13 modifiés ; aucun epic ajouté ni supprimé ; stories 11.1 à 11.9 déplacées avant l'Epic 10 |
| 3. Conflits entre artefacts | [x] | PRD, architecture, `DESIGN.md`, `EXPERIENCE.md`, `epics.md`, `AGENTS.md`, `docs/format-cas.md` |
| 4. Voie retenue | [x] | Ajustement direct |
| 5. Composants de la proposition | [x] | Sections 3 à 5 ci-dessous |
| 6. Revue finale et transmission | [x] | Approuvée d'office ; transmission à la planification de sprint |

### Epics et stories

- **Epic 0** : règle d'amorçage (D-1), exception documentaire sur tout `_bmad-output/` (D-2), format de rapport unique (E0-1), protections Gitea (D-10), revue dans le sens inverse (D-11), `sprint-consistency` limité aux statuts (D-17), `jq` constaté (M-16), question sur le périmètre de la revue retirée (M-17), AD-24 cité (E0-3), `agy` authentifié en opération manuelle.
- **Epic 1** : rulesets GitHub et test de refus d'un push direct (D-9) ; test de réécriture d'une branche par le miroir (E1-2).
- **Epic 2** : Docker dans WSL et `install-tools.sh --local` (D-15, E2-4) ; `ci/release-pages.txt` créé avec `home` (D-5) ; filtrage de `env.sh` en critère (E2-3) ; `_index` Chiliz titré « Chiliz » et en brouillon (D-3, D-4).
- **Epic 3** : six titres H2 (E3-2) ; règle JSON-LD progressive (E3-5) ; C12 et la page Chiliz en brouillon (D-3) ; déclencheurs `dev` et `main` (E3-1) ; rédaction du README-cas (D-12) ; verrou CI après amorçage (D-1) ; `publish-case` alimente `ci/release-pages.txt` (D-5).
- **Epic 9** : pages ajoutées à `ci/release-pages.txt` (D-5) ; sources du JSON-LD (D-7).
- **Epic 10** : identifiants de poste figés (D-8) ; 10.4 et 10.5 débloquées (D-4) ; 10.4 passe le `_index` hors brouillon (D-3).
- **Epic 11** : 11.1 à 11.9 avant l'Epic 10, 11.10 à 11.13 après (D-5) ; première répétition sur `v0.1.0-rc.N` (11.9) et jalon `v1.0.0-rc.N` en 11.10 ; tag `-rc` exigé pour `v1.0.0` seulement (D-6) ; verrous de la PR de publication (D-13) ; `hotfix/*` et PR relues (D-14).
- **Epic 12** : appariement par nom de fichier (E12-1).
- **Epic 13** : `position-april-technologies-2017` (D-8).

### Impact technique

Aucun code n'existe : l'impact porte sur les critères d'acceptation des stories à venir. Opérations manuelles nouvelles ou modifiées : Docker dans le shell WSL (2.1), `agy` authentifié (0.5), protections Gitea précisées (0.2), rulesets GitHub (1.4), tags `v0.1.0-rc.N` (11.9), jalon `v1.0.0-rc.N` (11.10).

## 3. Approche recommandée

**Ajustement direct.** Toutes les décisions modifient ou précisent des stories existantes et des AD existants. Aucun retour arrière (rien n'est construit) ni revue du périmètre MVP : aucune exigence n'est ajoutée ni retirée.

- **Effort** : une passe d'édition des documents de planification.
- **Risque** : faible. Les numéros de FR, NFR, AD, C, questions et stories sont conservés ; les décisions sont ajoutées en fin de série (décisions 39 à 55 de l'architecture).
- **Calendrier** : aucun décalage. Q9 étant tranchée, le chemin critique vers le socle ne dépend plus que de Q2.

## 4. Propositions de modification détaillées

Chaque ligne est appliquée. « Avant » résume le texte remplacé ; le texte exact est dans les documents.

### PRD (`prds/prd-eleyone.fr-2026-09-13/prd.md`)

| Emplacement | Avant | Après | Source |
| --- | --- | --- | --- |
| Front matter | `status: draft` | `status: validated` | D-16, M-18 |
| §0 | format des cas « version 0.3 (statut draft) » | « version 0.4 » ; contrôle de préparation cité parmi les entrées | M-3 |
| §3, « Cas mis en avant » | entrée active | marquée obsolète, renvoi au §11.1 | M-2 |
| FR-9 | « Le titre de la page et son éventuelle introduction dépendent de la question 9 » | titre « Chiliz » en FR et en EN, sans introduction ; page en brouillon tant qu'aucun cas n'est publié | D-4, D-3 |
| FR-23 | métadonnées comparées : « … ordre, mise en avant, brouillon … » | « … poste (`position`), ordre, brouillon … » | M-1 |
| §11.1 | — | ligne « Titre et introduction de la page Chiliz (question 9, numéro conservé) » | D-4 |
| §11.2, Q9 | question ouverte, bloque la story de la page Chiliz | barrée, « tranchée le 13/09/2026, voir §11.1 », numéro conservé | D-4 |
| §11.2, contenus à fournir | — | URL du profil GitHub (FR-35) | D-7 |

### Architecture (`architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md`)

| Emplacement | Avant | Après | Source |
| --- | --- | --- | --- |
| Front matter, statut, sources | `draft` ; « v0.3 ; v0.4 proposée ici » | `validated` ; v0.4 ; contrôle de préparation en source | D-16, M-4 |
| AD-1 | installation dans les conteneurs seulement | `install-tools.sh --local` : Hugo et D2 dans `.tools/`, placé dans le `PATH` par `build.sh` et `dev.sh` | D-15 |
| AD-3 | Contact : `email`, `linkedin` | ajoute `github` (profil) | D-7 |
| AD-4 | page de groupe vide interdite par C15 seul ; « v0.3 » ; `featured` « proposée » à la suppression ; titre selon Q9 | `_index` de groupe en brouillon tant qu'aucun cas n'est publié, constat en 2.5, repli par C12 ; v0.4 ; titre « Chiliz » | D-3, D-4, M-4 |
| AD-9, C18 | `env.sh` « ne transmet à Hugo que » les `HUGO_LEGAL_*` | lit seulement les lignes `^HUGO_LEGAL_`, sans `source` ni `set -a` : `GITEA_TOKEN` jamais visible de `hugo` ; `.env.example` avec les dix noms | E2-3 |
| AD-12 | « Aucun push ne va directement sur GitHub », sans mécanisme | rulesets : écritures restreintes, identité du miroir seule autorisée à contourner ; `main` en « Block force pushes » dans un ruleset sans contournement ; test en 1.4 | D-9 |
| AD-16 | paires par `translationKey` seulement | fichiers sans `translationKey` appariés par leur nom | E12-1 |
| AD-18 | `position-chiliz` et `position-ton-pote-le-geek` seulement ; « v0.4 (proposé) » | règle de nommage et liste figée (voir ci-dessous) ; v0.4 | D-8, M-4 |
| AD-19 | `identity`, `based_in`, `portrait_alt` | ajoute `job_title` | D-7 |
| AD-20, C10 | « construit par `jsonify` à partir du contenu » ; « exactement un bloc » | source de chaque champ, lien vide omis ; « au plus un » jusqu'à 9.6, puis « exactement un » | D-7, E3-5 |
| AD-22 | répétition générale sur `v1.0.0-rc.N` seulement | première répétition tôt sur `v0.1.0-rc.N` ; blocage `-rc` de même arbre pour `v1.0.0` seulement, avertissement ensuite | D-5, D-6 |
| AD-24, branches | `fix/*` depuis `main` pour un hotfix ; force-push de `dev` « réservé à Arnaud » | `hotfix/*` réservé ; `main` sans push ni force-push ; compte d'Arnaud en liste de push de `dev`, push direct interdit par la procédure ; PR ouvertes relues après un hotfix | D-14, D-10 |
| AD-24, outils | `sprint-consistency` : statuts, stories et branches | statuts seulement en v1 ; `create-pull-request` refuse `hotfix/*` ; `release` vérifie les pages du socle pour `v1.0.0` ; `publish-case` ajoute `group-<group>` | D-17, D-5 |
| AD-24, revue | auteur Claude → Gemini ; première ligne du rapport | sens inverse écrit ; cette ligne est le seul format, lu par `verify-and-merge-pr` | D-11, E0-1 |
| AD-24, verrous | CI « signalée absente » ; mêmes verrous pour `release` | CI à trois états ; règle d'amorçage ; verrous de la PR de publication | D-1, D-13 |
| AD-24, prérequis | `jq` absent, « [à valider par Arnaud] » | `jq` présent, `agy`, Docker dans WSL, Hugo et D2 locaux | M-13, D-15 |
| AD-24, exception documentaire | `.md` sous `_bmad-output/` | tout fichier sous `_bmad-output/`, `sprint-status.yaml` compris | D-2 |
| Liste des contrôles, C3, C15 | « pages attendues à chaque mise en ligne » | liste cumulative des pages publiées attendues ; `github` comparé par C3 | D-5, D-7 |
| Structure initiale | — | `.tools/`, `job_title`, `_index` en brouillon, `gitea-branches.md` | D-15, D-7, D-3, D-10 |
| Section `docs/format-cas.md` v0.4 | « faits hors de ce document ; contenu attendu » | « en place » ; renvoi aux identifiants d'AD-18 | M-4, D-8 |
| README-cas | rédaction non attribuée | premier jet en anglais par le développeur, relu par Arnaud | D-12 |
| Walking skeleton | `_index` Chiliz « titre seul en attendant la question 9 » | titre « Chiliz », en brouillon | D-4, D-3 |
| Décisions d'Arnaud | 1 à 38 | ajout de 39 à 55 (D-1 à D-17) ; 5 et 35 précisées | D-1 à D-17 |
| Recommandations à valider | `jq` | aucune ; recommandation close | M-13 |
| Écarts et tensions | « mise à jour du PRD en cours », « en parallèle » ; FR-9 : page vide ; statut brouillon | retirés ; FR-9 résolu par D-3 ; statut validé | M-12 |

### UX (`ux-designs/ux-eleyone.fr-2026-09-13/`)

| Document et emplacement | Avant | Après | Source |
| --- | --- | --- | --- |
| `DESIGN.md`, front matter et fin | `draft`, « reste un brouillon » ; v0.3 | `validated` ; v0.4 | D-16, M-3 |
| `DESIGN.md`, page Chiliz | « introduction si la question 9 en prévoit une » | « sans introduction en v1 (question 9, tranchée) » | D-4 |
| `DESIGN.md`, `site-footer` | « Code source du site » toujours affiché | seulement si `params.source_url` est renseigné | M-11 |
| `EXPERIENCE.md`, front matter et décisions | `draft` ; v0.3 | `validated` ; v0.4 | D-16, M-3 |
| `EXPERIENCE.md`, architecture de l'information | — | page Chiliz titrée « Chiliz », sans introduction | D-4 |
| `EXPERIENCE.md`, Voice and Tone | `back_to_career` EN « à valider » ; `based_in` présenté comme clé i18n | décidé (FR-15) ; clé de front matter de `content/_index` (AD-19, AD-3) | M-9, M-10 |
| `EXPERIENCE.md`, State Patterns | page de groupe vide bloquée par C15 | page non construite (`_index` en brouillon), C15 en dernier recours | D-3 |
| `EXPERIENCE.md`, test des trente secondes | « proposition », « [à valider par Arnaud] », « seuil proposé » | méthode validée (question 14) | M-8 |
| `EXPERIENCE.md`, points à valider | libellés, test, marqueur « Brouillon » | libellés seulement | M-8 |
| `EXPERIENCE.md`, I-1 et I-11 | `static/cv/` ; « si la version À propos est retenue » | `assets/cv/` (AD-21) ; retenue | M-7 |

### Backlog (`epics.md`)

| Emplacement | Avant | Après | Source |
| --- | --- | --- | --- |
| Front matter | `draft` | `validated` ; contrôle et proposition en entrée | D-16 |
| Présentation, Validation finale | « AD-1 à AD-23 » ; Q9 parmi les questions bloquantes | « AD-1 à AD-24 » ; Q9 tranchée | M-14, D-4 |
| Règles de conduite | règle 9 sans `hotfix/*` ni amorçage | règle 9 complétée ; règle 11 « Amorçage des verrous » | D-1, D-14 |
| Exigences issues de l'architecture | pas d'entrée AD-24 | entrée AD-24 ; AD-1, AD-4, AD-9, AD-12, AD-18, AD-20, AD-22 complétés | E0-3 |
| Liste des epics | Epic 11 entier après l'Epic 10 | 11.1 à 11.9 avant l'Epic 10 ; 11.10 à 11.13 dans « Mise en ligne du socle », après l'Epic 10 ; numéros conservés | D-5 |
| Epic 0 | exception `.md` ; aucune règle d'amorçage ; deux formats de rapport | exception sur tout `_bmad-output/` ; amorçage ; format unique | D-2, D-1, E0-1 |
| 0.1 à 0.7 | — | AD-24 dans « Couvre » ; 0.2 selon D-10 et `gitea-branches.md` ; 0.4 « constater `jq` » ; 0.5 au format d'AD-24, sens inverse, `agy` authentifié, question sur le périmètre retirée ; 0.6 statuts seulement ; 0.7 : trois états de la CI, suivi de sprint, questions retirées | E0-3, D-10, M-16, M-17, D-11, D-17, D-1 |
| 1.4 | mécanisme contre le push direct en question | rulesets, test de refus, test de réécriture par le miroir | D-9, E1-2 |
| 2.1, 2.2 | Hugo et D2 sur le poste en question ; pas de Docker | Docker dans WSL ; `install-tools.sh --local` ; `.tools/` ; `ci/release-pages.txt` créé avec `home` | D-15, D-5 |
| 2.4, 3.6 | filtrage de `env.sh` et C18 en question | critère `GITEA_TOKEN` invisible de `hugo` ; C18 à dix noms ; questions retirées | E2-3 |
| 2.5, 2.7, 3.10 | titre `[TODO]` et `_index` en brouillon en question ; libellé et marqueur « à valider » | `_index` « Chiliz » en brouillon, constat ; questions retirées ; critère C12 | D-3, D-4, M-8, M-9 |
| 3.1 | « cinq titres H2 » | « six titres H2 » | E3-2 |
| 3.8 | règle « exactement un » en question | « au plus un » jusqu'à 9.6 | E3-5 |
| 3.13, 3.14 | `push` sur `main` seulement | `push` sur `dev` et `main` ; démonstration sur `dev` | E3-1 |
| 3.15 | texte à fournir par Arnaud, rédaction en question | premier jet par le développeur, relu par Arnaud | D-12 |
| 3.16, 3.17 | — | `absent` bloque dès que le workflow existe ; `publish-case` alimente `ci/release-pages.txt` | D-1, D-5 |
| 9.1 à 9.4, 9.6 | sources du JSON-LD en question | pages ajoutées à la liste ; sources d'AD-20 en critère | D-5, D-7 |
| 10.2, 10.7, 13.3 | identifiants « à confirmer » | identifiants figés d'AD-18 | D-8 |
| 10.4, 10.5 | bloquées par Q9 | débloquées ; `_index` hors brouillon avant 10.5 | D-4, D-3 |
| 11.1, 11.5, 11.7, 11.8, 11.9, 11.10, 11.11, 11.12 | liste du socle ; « point à trancher » C15 ; fusion en question ; `fix/*` | liste cumulative ; première répétition `v0.1.0-rc.N` en 11.9, jalon `v1.0.0-rc.N` en 11.10 ; verrous de publication ; `v1.0.0` seul bloquant ; `hotfix/*`, PR relues | D-5, D-6, D-13, D-14 |
| 12.1 | appariement en question | critère par nom de fichier | E12-1 |
| Synthèse | tableaux et « Tensions restantes » (16 points) | tableaux mis à jour ; trois tensions restantes et liste des tensions résolues | M-15 |

### `AGENTS.md` (anglais, structure conservée)

- Planification faite et documents validés, au lieu de « nothing has been planned » ; format v0.4 (M-5).
- Hotfix sur `hotfix/*`, PR relues, protections Gitea précisées, rulesets GitHub (D-14, D-10, D-9).
- Revue dans le sens inverse et format du rapport (D-11, E0-1).
- Exception documentaire sur tout `_bmad-output/` (D-2) ; verrous de la PR de publication (D-13).
- Nouveaux points 6 « Bootstrap rule » (D-1) et 7 « Dev machine prerequisites » (D-15).
- Liste des skills avec `hotfix`, neuf au total (M-6).

### `docs/format-cas.md`

- Renvoi à la liste figée des identifiants de poste d'AD-18, dans « Rattachement au parcours » et dans le modèle vide (D-8). Version inchangée (0.4).

### Liste figée des identifiants de poste (AD-18, D-8)

| Identifiant | Poste | Cas rattachés |
| --- | --- | --- |
| `position-chiliz` | Chiliz | 02, 03, 04 |
| `position-synolia` | Synolia | — |
| `position-mister-auto` | Mister Auto | — |
| `position-april-technologies-2017` | April Technologies, 2017, en prestation Modis | 06 |
| `position-orange` | Orange | 05 |
| `position-earlier-career` | « Parcours antérieur », 2008–2014 : regroupement, pas une société | — |
| `position-ton-pote-le-geek` | Ton Pote le Geek (`track: parallel`) | 01 |

Liste exacte, remplacée par le complément 1 ci-dessous.

## 5. Transmission

**Portée : modérée.** Réorganisation du backlog (stories 11.1 à 11.9 avant l'Epic 10) et nouveaux critères d'acceptation, sans replanification du produit.

| Destinataire | Responsabilité |
| --- | --- |
| Arnaud | Relire la section « À décider » ci-dessous ; lancer `bmad-sprint-planning` en mode complet |
| Planification de sprint | Générer `sprint-status.yaml`, première PR fusionnée selon la règle d'amorçage (B-2) ; reporter l'ordre d'exécution de D-5 |
| Développeur | Story 0.1 ensuite, selon la règle 11 des stories |

**Critères de réussite** :

- aucune mention restante de v0.3, de « AD-1 à AD-23 », de `static/cv/` ni d'un second format de rapport dans les cinq documents ;
- les stories 10.4 et 10.5 ne sont plus bloquées ;
- aucune question retirée ne reste dans une story alors qu'une décision y répond ;
- la recherche des motifs privés sur `_bmad-output/`, `AGENTS.md` et `docs/format-cas.md` ne renvoie rien.

### À décider (hors D-1 à D-17 et M-1 à M-18, non appliqué)

1. **Postes du CV sans cas** : la liste d'AD-18 ne couvre que les postes nommés dans les documents publics. Arnaud la complète à partir de son CV avant la story 10.2. Il confirme aussi que Chiliz et Orange n'apparaissent qu'une fois dans le parcours, et que la mission de 2013–2014 se range sous April plutôt que sous CGI.
2. **Ordre dans `sprint-status.yaml`** : le script de planification trie les epics par numéro. Les stories 11.1 à 11.9 y apparaîtront donc après l'Epic 10, malgré leur place dans `epics.md`. Il faut choisir entre reporter l'ordre à la main lors de la planification et renuméroter.
3. **Écart entre 10.4 et 10.5** : si le `_index` Chiliz passe en `draft: false` dans une PR distincte de celle qui publie le cas 02, le build de production contient une page de groupe vide entre les deux fusions, et C12 la signale. Deux options : une seule PR, ou le passage fait dans la PR de 10.5.
4. **Dépendance de 2.1 sur tout l'Epic 1** (E2-5) : la proposition « Dépendances : 1.2 » demande une décision d'Arnaud, sans numéro D.
5. **Découpe des stories 5.1 et 11.11** (5.1a/5.1b, 11.11a/11.11b) : proposée par le contrôle, non décidée.
6. **SM-7 et FR-25** : une PR de publication d'un cas touche désormais `ci/release-pages.txt` en plus des fichiers du cas (D-5), alors que SM-7 limite les PR de contenu aux fichiers de FR-25.
7. **Rulesets GitHub** : un acteur de contournement échappe à toutes les règles de son ruleset. AD-12 place donc le blocage des force-pushes sur `main` dans un second ruleset, sans contournement. C'est une précision d'application de D-9, à confirmer à la story 1.4.
8. **Numéro de PR dans le squash** (D-13) : il reste à vérifier, à la story 11.7, que le message de squash de Gitea contient bien le numéro de PR.

## Compléments du 13/09/2026

Quatre décisions complémentaires d'Arnaud, qui répondent aux points 1, 2, 3 et 6 de « À décider ». Appliquées.

1. **Identifiants de poste (AD-18).** La liste figée devient exactement : `position-chiliz` (cas 02, 03, 04), `position-synolia` (sans cas), `position-mister-auto` (sans cas), `position-april-technologies-2017` (cas 06), `position-orange` (cas 05), `position-earlier-career` (« Parcours antérieur », 2008–2014, regroupement et non société, sans cas) et `position-ton-pote-le-geek` (cas 01, `track: parallel`). `position-april-technologies-2013` est supprimé : la mission de 2013–2014 chez April pour le compte de CGI est une ligne de détail de `position-earlier-career`. Chiliz et Orange n'apparaissent qu'une fois. Mis à jour : AD-18 et décision 46 de l'architecture, story 10.2, `docs/format-cas.md`, tableau de la section 4.
2. **Stories 10.4 et 10.5 : une seule PR.** Le `_index` Chiliz sort du brouillon dans la PR qui publie le cas 02, pour qu'aucune page de groupe vide n'existe en production. Mis à jour : AD-4, stories 10.4 et 10.5.
3. **Ordre dans `sprint-status.yaml`.** Les numéros de stories sont conservés ; l'ordre de travail (11.1 à 11.9 avant l'Epic 10) est fixé lors de la planification de sprint. Mis à jour : note pour la planification dans la synthèse d'`epics.md`.
4. **SM-7 élargi (PRD).** Une PR de publication peut toucher les fichiers de contenu et `ci/release-pages.txt`. FR-25 est aligné : publier un cas touche aussi `ci/release-pages.txt` et, pour le premier cas d'un groupe, la page de groupe.

Restent « à décider » : les points 4, 5, 7 et 8 de la liste ci-dessus, et un point nouveau : la clé `company` d'un poste n'est pas traduite (C3), alors que le regroupement `position-earlier-career` porte un libellé à traduire (« Parcours antérieur »). La clé qui porte ce libellé reste à fixer à la story 10.2.
