# Story 1.4 : Push mirror to public GitHub repository

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 1.4, réécrite après la revue de spec ci-dessous.

## Revue de spec

### 16/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `e3b98d2`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0fe1da17bbb46fe16b97103a

### Revue de la spec (Story 1.4)

##### Plan de revue
- **Contenu** : Texte de la Story 1.4 issue du backlog (Classe : `docs`, document de comportement)
- **Lentilles appliquées** : Adversarial, Structure, Prose

---

##### 1. Lentille Adversarial (Adversarial Critique)

**1. Conflit bloquant sur les références internes de PR (Bloquant)**
- **Emplacement** : Critère d'acceptation 5 (`... références internes de PR de Gitea comprises.`)
- **Condition de déclenchement** : La spec attend que le miroir synchronise les PR internes de Gitea. Or, l'espace de noms `refs/pull/` est réservé par GitHub pour ses propres pull requests (en lecture seule).
- **Snippet de correction** : Exclure explicitement ces références de la refspec du miroir (ex: synchroniser uniquement `refs/heads/*` et `refs/tags/*`) et retirer cette exigence de la story.
- **Conséquence** : Le miroir échouera systématiquement s'il tente de pousser une référence `refs/pull/*`, bloquant ainsi toute synchronisation vers GitHub.

**2. Exécution impossible sur un "clone miroir" (Bloquant)**
- **Emplacement** : Critère d'acceptation 1 (`Quand l'audit complet... est relancé... sur un clone miroir frais`)
- **Condition de déclenchement** : Un clone de type miroir (`git clone --mirror`) crée un dépôt *bare* (sans arborescence de travail). 
- **Snippet de correction** : Exiger un clone standard (`git clone`), ou préciser qu'il faut extraire le script du dépôt bare avant exécution.
- **Conséquence** : `scripts/check-private.sh` ne sera pas présent sous forme de fichier exécutable dans un clone bare, rendant le critère invérifiable en l'état.

**3. Blocage potentiel du flag `--force` sur `main`**
- **Emplacement** : Critères d'acceptation 4 et 5 (rulesets d'AD-12)
- **Condition de déclenchement** : Le miroir Gitea devra autoriser les push forcés pour synchroniser la branche jetable réécrite (et `dev` après un hotfix). Cependant, le ruleset de `main` inclut « Block force pushes » *sans acteur de contournement* (AD-12).
- **Snippet de correction** : Valider que le client git du miroir n'utilise pas un flag `--force` global qui s'appliquerait aussi à `main` (ce que GitHub rejettera, même pour un fast-forward).
- **Conséquence** : Rejet silencieux ou erreur de synchronisation du miroir lors des mises à jour de la branche `main`.

**4. Gestion de l'expiration du jeton GitHub absente**
- **Emplacement** : Section `Opération manuelle (Arnaud)`
- **Condition de déclenchement** : Si la méthode choisie est le « compte machine avec un jeton à grain fin », ce type de jeton possède une durée de vie limitée.
- **Snippet de correction** : Ajouter une consigne pour documenter la rotation du jeton, ou recommander exclusivement une clé de déploiement (Deploy Key) SSH qui n'expire pas par défaut.
- **Conséquence** : Rupture future du miroir lorsque le jeton arrivera à expiration, sans documentation sur la façon de le remplacer.

**5. Variables d'environnement de l'audit local**
- **Emplacement** : Critère d'acceptation 3 (`Quand Arnaud lance scripts/check-private.sh history avec la liste des motifs`)
- **Condition de déclenchement** : Le dépôt GitHub ne contient pas `docs/private/`.
- **Snippet de correction** : Préciser que la commande doit être lancée avec la variable d'environnement `PRIVATE_PATTERNS_FILE` pointant vers la liste des motifs sur la machine d'Arnaud.
- **Conséquence** : En l'absence de cette variable, le script échouera sans auditer les motifs, ce qui faussera le test.

**6. Flou sur le périmètre des branches synchronisées**
- **Emplacement** : Section `Questions à poser avant de commencer`
- **Condition de déclenchement** : La spec reporte à une question le choix des branches à mirrorer, alors que ce choix dicte la configuration manuelle requise.
- **Snippet de correction** : Trancher dans les critères (ex: ne pousser que `main`, `dev`, les branches `feat/*`, etc., ou toutes les branches locales).
- **Conséquence** : Le périmètre du dépôt public est ambigu et Arnaud pourrait configurer un miroir qui expose trop ou trop peu de branches.

**7. Modalité de déclenchement du miroir non spécifiée**
- **Emplacement** : Critère d'acceptation 2 (`Quand le miroir push est configuré et synchronisé`)
- **Condition de déclenchement** : Gitea permet de synchroniser les miroirs à intervalles réguliers ou sur événement (push).
- **Snippet de correction** : Préciser que le miroir doit se déclencher au moment du push (Push Events).
- **Conséquence** : Si le miroir est configuré via un Cron (ex: toutes les 8 heures), l'attente du tech lead de trouver des éléments "tenus à jour" en temps réel ne sera pas satisfaite.

**8. Pollution par la "branche jetable"**
- **Emplacement** : Critère d'acceptation 5 (`Étant donné une branche jetable réécrite...`)
- **Condition de déclenchement** : Le critère demande de pousser une branche de test pour vérifier le non fast-forward.
- **Snippet de correction** : Ajouter l'étape de suppression de cette branche sur la forge et vérifier que la suppression est bien répercutée par le miroir sur GitHub.
- **Conséquence** : Une branche expérimentale restera visible indéfiniment sur le dépôt public.

**9. Action `params.source_url` ambiguë**
- **Emplacement** : Check-list (`L'URL du dépôt public est transmise pour params.source_url (story 9.5)`)
- **Condition de déclenchement** : Le mot "transmise" ne définit pas d'action claire pour cette story.
- **Snippet de correction** : Remplacer par "L'URL du dépôt public est conservée de côté pour être injectée dans la story 9.5".
- **Conséquence** : Le développeur pourrait modifier `config/_default/hugo.yaml` dès maintenant, introduisant du code hors périmètre.

**10. Limites de la relecture des cas bruts**
- **Emplacement** : Check-list (`Aucun artefact public ne cite de cas brut (relecture)`)
- **Condition de déclenchement** : La relecture humaine demandée ici ne précise pas sur quels fichiers elle s'applique.
- **Snippet de correction** : Restreindre explicitement cette vérification aux artefacts listés au critère 2 (`PRD`, `DESIGN.md`, `EXPERIENCE.md`, etc.).
- **Conséquence** : Périmètre de relecture démesuré ou mal ciblé au moment de cocher la case.

---

##### 2. Lentille Structure (Logic & Flow)

- **Regroupement excessif des opérations manuelles** : La ligne `Opération manuelle (Arnaud)` compile au moins quatre actions lourdes (créer le dépôt, gérer l'identité, créer les rulesets, configurer le miroir Gitea). 
  - *Recommandation* : Découper cette phrase en une liste à puces chronologique pour qu'elle serve de vraie feuille de route.
- **Séquencement du test d'audit** : Le premier critère mélange l'action de cloner et l'action d'auditer dans la même étape (`Quand l'audit complet... est relancé... sur un clone`).
  - *Recommandation* : Transformer le clonage en pré-condition (`Étant donné un clone standard frais... Quand l'audit est relancé...`).

---

##### 3. Lentille Prose (Clarity & Readability)

- **Ambiguïté sémantique** : `références internes de PR de Gitea comprises`. La concision rend la phrase trompeuse. Veut-on dire "y compris le fait que Gitea tente de les pousser" ou "doivent être incluses dans GitHub" ?
- **Lourdeur syntaxique** : `le brief, son addendum... et ce document y figurent`. L'accord est syntaxiquement juste, mais "et ce document y figurent" est très lourd.
  - *Correction suggérée* : "... ainsi que le présent document, y figurent."
- **Bruit visuel** : L'incise `(ajouté après la revue du code de la story 1.3)` insérée à la fin d'un `Alors` casse la règle métier par un rappel d'historique de projet.
  - *Correction suggérée* : Séparer cette précision dans un bloc de note hors des critères Gherkin.

---

##### À trancher avant d'implémenter

1. **Références internes de PR** : Doit-on explicitement ignorer les références `refs/pull/*` dans la refspec du miroir pour éviter un rejet systématique par GitHub ?
2. **Périmètre du miroir** : Quelles branches précisément doivent être mirrorées (seulement `main`/`dev`, ou toutes les branches de feature) ?
3. **Type de clone pour l'audit** : Remplacer « clone miroir » par « clone standard », un dépôt *bare* interdisant l'exécution directe des scripts locaux.
4. **Authentification** : Fixer le choix entre "Clé de déploiement (Deploy Key)" (qui n'expire pas) et "Jeton à grain fin" (qui nécessite une procédure de rotation).

Relevé préalable de l'auteur (16/09/2026), dans la documentation :

- le miroir push de Gitea ne prend pas les clés SSH (« Currently Gitea supports no ssh push mirrors ») : il pousse en HTTPS avec un jeton, et utilise `git push --mirror`, donc toutes les références ;
- GitHub refuse `refs/pull/*` comme références cachées ; ces références donnent seules accès à 64 commits de la forge ;
- une clé de déploiement peut être acteur de contournement d'un ruleset, mais elle suppose SSH.

Tri de l'auteur (questions tranchées par Arnaud le 16/09/2026) :

- `refs/pull/*` refusées : tranché, on configure le miroir tel quel, on observe la première synchronisation et on note ce qui est poussé ; la suite se décide sur preuve ;
- « audit impossible sur un clone miroir » : écarté, c'est ce qui a été fait en story 1.3, en appelant le script du dépôt de travail par son chemin depuis le clone nu ; la commande est écrite dans le critère ;
- push forcé sur `main` : précisé, `main` n'avance qu'en fast-forward, donc « Block force pushes » ne gêne pas le miroir ;
- expiration du jeton : tranché, compte machine avec jeton à grain fin limité au dépôt, expiration et remplacement écrits dans la procédure ;
- `PRIVATE_PATTERNS_FILE` pour l'audit du clone GitHub : corrigé dans le critère ;
- périmètre des branches : tranché, toutes les branches de la forge ;
- déclenchement du miroir : corrigé, synchronisation à chaque push ;
- branche jetable de l'essai : corrigé, supprimée ensuite sur la forge, suppression vérifiée sur GitHub ;
- `params.source_url` : corrigé, l'URL est seulement notée pour la story 9.5 ;
- relecture des cas bruts : corrigé, limitée aux artefacts publiés cités au critère 2 ;
- structure et rédaction : corrigé, opérations manuelles en liste chronologique, clone en précondition, note d'historique hors des critères, formulations allégées.

Décision d'Arnaud sur l'identité du miroir : le jeton personnel aurait confondu le miroir et Arnaud pour GitHub, rendant invérifiable le refus d'un push direct. Option A retenue : compte machine dédié à ce dépôt, avec son propre jeton, contournement des rulesets par le rôle Write ; le jeton personnel d'Arnaud reste pour ses autres miroirs.

## Essais du miroir

16/09/2026, Gitea 1.27.3. Rien du serveur ni du compte n'est noté ici : ni jeton, ni nom d'hôte, ni chemin de machine.

### 1. Audit complet juste avant l'activation

Clone miroir jetable de la forge, hors du dépôt de travail, supprimé après l'audit ; commande `PRIVATE_PATTERNS_FILE=<liste du poste> <dépôt de travail>/scripts/check-private.sh history`.

- Périmètre : 24 références (6 branches, aucun tag, 17 `refs/pull/*/head`), 94 commits.
- Résultat : **code 0, aucune sortie**, aucune mention « chemins seulement ».
- L'audit couvre bien le dernier commit poussé de chaque branche : `main` `9e14036`, `dev` `e3b98d2`, `design/dossier-architecture` `04ed986`, `design/suisse` `c7ab03e`, `experiment/d2-bilingue` `1dfe25b`, `feat/1-4-push-mirror-to-public-github-repository` `c2ea7e3`.

Étapes 1 à 4 de la procédure faites par Arnaud avant cet audit : dépôt public créé vide, compte machine invité en écriture, jeton d'écriture créé pour ce compte, deux rulesets d'AD-12 posés.

**Identité du miroir : jeton classique, pas un jeton à grain fin.** Un jeton à grain fin ne peut cibler que les dépôts *possédés* par le compte qui l'émet ; le compte machine n'est que collaborateur d'un dépôt appartenant à un autre compte, donc le dépôt public n'apparaît jamais dans la liste de sélection. Le miroir utilise donc un jeton classique portant `public_repo` et `workflow`. La portée de ce jeton et la manière de le limiter sont expliquées dans `docs/procedures/github-mirror.md`.

### 2. Références poussées vers GitHub

Comparaison des références de la forge et du dépôt public après la première synchronisation (lecture seule, `git ls-remote` des deux côtés).

| Référence | Forge | GitHub |
| --- | --- | --- |
| `main` | `9e14036` | `9e14036` |
| `dev` | `e3b98d2` | `e3b98d2` |
| `design/dossier-architecture` | `04ed986` | `04ed986` |
| `design/suisse` | `c7ab03e` | `c7ab03e` |
| `experiment/d2-bilingue` | `1dfe25b` | `1dfe25b` |
| `feat/1-4-push-mirror-to-public-github-repository` | `c2ea7e3` | `c2ea7e3` |

- Les six branches sont identiques au commit près ; `HEAD` du dépôt public pointe sur `main`, la branche par défaut voulue par AD-12.
- Aucun tag d'aucun côté.
- **`refs/pull/*` : zéro référence sur GitHub.** L'espace `refs/pull/` y est réservé aux pull requests GitHub et n'est pas inscriptible ; les 17 `refs/pull/*/head` de la forge ne sont donc pas publiées. C'est la réponse à la question laissée ouverte par la story 1.3 : le miroir n'expose pas les références internes de PR de la forge.

### 3. Audit d'un clone frais du dépôt public

Clone miroir jetable de `https://github.com/Eleyone/eleyone.fr.git`, hors du dépôt de travail, supprimé après l'audit ; commande `PRIVATE_PATTERNS_FILE=<liste du poste> <dépôt de travail>/scripts/check-private.sh history`.

- Périmètre du dépôt public : **6 références, 26 commits** (contre 24 références et 94 commits sur la forge : l'écart tient aux `refs/pull/*` absentes et aux commits qu'elles seules rendaient accessibles — les commits de PR avant squash).
- Résultat : **code 0, aucune sortie**, aucune mention « chemins seulement ».
- Présents sur GitHub (FR-31) : `_bmad-output/planning-artifacts/` complet (brief, PRD, architecture, UX, `epics.md`, `implementation-readiness.md`, la proposition de changement de sprint), `ARCHITECTURE-SPINE.md`, `AGENTS.md`.
- Absents, comme attendu : `docs/private`, `.env`, `docs/context`.

### 4. État de la synchronisation côté Gitea

Lu par l'API de la forge (`GET /repos/<dépôt>/push_mirrors`), rien d'autre n'est noté que ces champs :

- synchronisation **à chaque push** activée, intervalle de repli **8 h** ;
- dernière synchronisation sans erreur (`last_error` vide) à chaque relevé de la journée ;
- une seule cible de miroir, `https://github.com/Eleyone/eleyone.fr.git`.

### 5. Réécriture et suppression d'une branche jetable

Branche `chore/mirror-smoke-test`, un commit vide partant de `dev` (`e3b98d2`), poussée puis réécrite puis supprimée sur la forge ; rien d'autre n'a été touché.

| Étape | Forge | GitHub | Délai |
| --- | --- | --- | --- |
| 1. Création et push | `fd6c9a2` | `fd6c9a2` | moins d'une minute |
| 2. Réécriture (`--force-with-lease`, non fast-forward) | `6b51319` | `6b51319` | moins d'une minute |
| 3. Suppression sur la forge | branche absente | branche **toujours présente** 3 min plus tard | — |
| 4. Synchronisation déclenchée explicitement | — | branche absente | quelques secondes |

- La mise à jour **non fast-forward** est acceptée par GitHub : le ruleset « toutes les branches » est bien contourné par le rôle Write du compte machine, et la synchronisation ne tombe pas en erreur.
- **Constat à retenir** : la suppression d'une branche ne déclenche pas la synchronisation « à chaque push » de Gitea. Une branche supprimée sur la forge reste visible sur GitHub jusqu'à la synchronisation suivante (au plus tard au bout de l'intervalle de 8 h, ou tout de suite si une autre poussée ou une synchronisation manuelle a lieu). Aucun contenu privé n'est en jeu — c'est un délai d'affichage —, mais la procédure le dit désormais.

### 6. Push direct depuis le compte personnel d'Arnaud

Fait par Arnaud sur un clone du dépôt public, avec son compte personnel ; aucun jeton n'est noté ici.

**Premier essai — non conforme.** Le ruleset a bien vu l'infraction mais l'a contournée : `remote: Bypassed rule violations for refs/heads/<branche jetable>` … `Cannot create ref due to creations being restricted`, et la branche a tout de même été créée. Cause : la liste de contournement désignait le **rôle Write**, que le propriétaire du dépôt possède aussi. Les règles elles-mêmes étaient bien actives (lecture anonyme de `/rules/branches/main` : `creation`, `update`, `deletion`, `non_fast_forward`, `required_linear_history`).

**Correction** (Arnaud) : dans le ruleset couvrant toutes les branches, le contournement par rôle est remplacé par le **compte machine désigné nommément**. GitHub accepte des utilisateurs individuels comme acteurs de contournement d'un ruleset de dépôt depuis mai 2026.

**Second essai — conforme.** Avec un nom de branche neuf, les deux moitiés du ruleset refusent :

| Opération | Résultat |
| --- | --- |
| Création d'une branche | `GH013: Repository rule violations found` … `Cannot create ref due to creations being restricted` → `! [remote rejected]`, aucune branche créée |
| Suppression d'une branche existante | `GH013` … `Cannot delete this branch` → `! [remote rejected]` |

**Le miroir, lui, écrit toujours.** La branche créée par le premier essai n'existait que sur GitHub ; la synchronisation suivante l'a supprimée en une dizaine de secondes (`last_error` vide), ce que la règle `deletion` refuse à Arnaud. Le compte machine contourne donc bien, et lui seul. Après cette synchronisation, les six branches du dépôt public sont exactement celles de la forge.

### 7. Points de la check-list

- Le jeton du compte machine n'est stocké que dans Gitea : le poste n'a qu'un seul remote, `origin`, qui pointe vers la forge (`git remote -v`), et aucune commande de ce travail n'a poussé vers GitHub.
- L'expiration du jeton et son remplacement sont écrits dans `docs/procedures/github-mirror.md`, section « Entretenir ».
- Relecture des artefacts publiés cités au critère 2 : aucun ne nomme ni ne reprend un cas brut (aucune occurrence de `cas-client-0*`, `contexte-candidat-condense` ni `noyau-narratif` dans `_bmad-output/planning-artifacts/`).
- **URL du dépôt public, à injecter dans `params.source_url` à la story 9.5** : `https://github.com/Eleyone/eleyone.fr`. La configuration Hugo n'est pas touchée ici.

## Revue du code

### 16/09/2026 — `7133343` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 19. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 96d2e614daaf987fa730ac42

##### Lentille Edge-Case Hunter
Aucun cas limite non géré n'a été trouvé dans le périmètre de cette modification. Il s'agit exclusivement d'ajouts documentaires (fichiers de story, architecture, suivi de sprint). Les comportements potentiellement incertains du miroir (délai de propagation des suppressions de branches, blocage des push forcés par le ruleset, gestion de `refs/pull/*`) ont été anticipés, testés et explicitement traités dans le texte.

##### Lentille Verification-Gap
No verification gaps found. (La modification est strictement non-comportementale et ne contient aucun code exécutable ; l'analyse s'arrête à l'étape 1 de la lentille).

##### Couche propre au projet

- **Critères d'acceptation de la story** : Tous les critères sont pleinement satisfaits. Le récit détaillé des essais du miroir prouve que l'audit des clones réussit, que les règles GitHub sont correctement appliquées, et que le contournement via l'identité du compte machine désigné nommément fonctionne parfaitement. L'intention des critères est préservée.
  NON BLOQUANT

- **Garde-fou et fuite de données** : Le diff ne contient aucune donnée privée, aucun secret, aucun jeton, ni aucune adresse ou nom d'hôte relatif à la forge Gitea locale. L'URL GitHub publique `https://github.com/Eleyone/eleyone.fr.git` est la cible attendue.
  NON BLOQUANT

- **Concordance skill, procédure et script** : Non applicable (la modification ne touche ni scripts, ni procédures techniques, ni définition de skills).
  NON BLOQUANT

- **Cohérence avec AGENTS.md et architecture** : La mise à jour du statut à `review` à la fois dans `sprint-status.yaml` et dans l'en-tête du fichier de story correspond fidèlement au cycle de vie exigé par `AGENTS.md`. La mise à jour d'`ARCHITECTURE-SPINE.md` répercute de façon cohérente les découvertes des essais (jeton classique privilégié, impossibilité d'utiliser une clé SSH pour ce type de miroir Gitea).
  NON BLOQUANT

- **Scripts shell et erreurs silencieuses** : Non applicable (aucun script bash n'est modifié, la règle `set -euo pipefail` n'est donc pas mise en jeu).
  NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

## Reporté
