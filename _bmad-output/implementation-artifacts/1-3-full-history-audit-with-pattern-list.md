# Story 1.3 : Full history audit with pattern list

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 1.3, réécrite après la revue de spec ci-dessous.

## Revue de spec

### 16/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `10d6dbb`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 09fb4b940a257fd3f4bc1a61

**Objectif et audience** : Ce document existe pour aider l'agent (et le mainteneur, Arnaud) à valider que l'historique Git du dépôt ne contient aucune donnée privée, afin de pouvoir activer un miroir public en toute sécurité.
**Modèle de structure** : Prompt / Task Definition (Functional)

##### Lentille Adversarial (Adversarial Lens)

1. **Emplacement** : Critères d'acceptation
   - **Condition de déclenchement** : Un "clone miroir" (`git clone --mirror`) crée un dépôt nu sans arbre de travail. Le script `scripts/check-private.sh` n'y sera donc pas présent sous forme de fichier exécutable.
   - **Garde-fou** : Préciser qu'Arnaud doit appeler le script depuis son dépôt de travail principal, en ciblant le clone miroir.
   - **Conséquence potentielle** : La commande échoue avec "fichier introuvable", bloquant l'exécution de la story.

2. **Emplacement** : Critères d'acceptation
   - **Condition de déclenchement** : Sur un clone miroir dépourvu du dossier `docs/private/`, si la variable d'environnement `PRIVATE_PATTERNS_FILE` n'est pas passée, le script ne trouve pas la liste des motifs.
   - **Garde-fou** : Exiger dans la spécification la définition explicite de la variable : `PRIVATE_PATTERNS_FILE=/chemin/vers/liste scripts/check-private.sh history`.
   - **Conséquence potentielle** : Conformément à l'AD-12, le script se repliera silencieusement en mode "chemins seulement", donnant un faux positif de succès sans avoir vérifié le contenu.

3. **Emplacement** : Opération manuelle (Arnaud)
   - **Condition de déclenchement** : La spec ne précise pas comment l'agent, qui gère la story, est censé vérifier le succès de l'action manuelle d'Arnaud.
   - **Garde-fou** : Ajouter une instruction précisant qu'Arnaud doit copier la sortie du script et son code de retour dans la discussion pour que l'agent puisse valider le critère.
   - **Conséquence potentielle** : L'agent clôture la story prématurément sans preuve, ou reste figé sans savoir quel déclencheur attendre.

4. **Emplacement** : Critères d'acceptation (Étant donné un signalement)
   - **Condition de déclenchement** : Il est demandé que "les tests de 1.2 soient rejoués" après une réécriture. La story 1.2 concerne le hook serveur, ce qui est décorrélé d'un audit et d'une réécriture locale.
   - **Garde-fou** : Clarifier la finalité (ex: s'assurer que la réécriture locale n'a pas supprimé ou désynchronisé les hooks locaux) ou retirer cette mention.
   - **Conséquence potentielle** : Confusion de l'agent qui pourrait perdre du temps à chercher des tests hors sujet ou à réinstaller des hooks inutilement.

5. **Emplacement** : Critères d'acceptation (`[ ] Le commit de tête...`)
   - **Condition de déclenchement** : L'emplacement de destination pour noter les commits et les dates n'est pas précisé.
   - **Garde-fou** : Remplacer par : "sont notés dans le fichier de statut de la story (`_bmad-output/implementation-artifacts/1-3-...`)."
   - **Conséquence potentielle** : L'information est perdue dans les logs éphémères du chat ou écrite dans le mauvais fichier, rendant la traçabilité impossible.

6. **Emplacement** : En-tête (Bloquée par)
   - **Condition de déclenchement** : Le champ vaut `—` alors que la section finale contient une liste de "Questions à poser avant de commencer".
   - **Garde-fou** : Remplir le champ avec "Attente des réponses aux questions préalables".
   - **Conséquence potentielle** : L'agent commence la phase d'implémentation sur la base d'hypothèses erronées sans attendre qu'Arnaud ne réponde.

7. **Emplacement** : Questions à poser avant de commencer
   - **Condition de déclenchement** : La question interroge si les PR sont "poussées par le miroir", alors que le miroir (Story 1.4) n'a pas encore été configuré.
   - **Garde-fou** : Reformuler la question pour se concentrer sur l'audit local actuel : "Faut-il auditer les `refs/pull/*` locales avant l'activation future du miroir ?"
   - **Conséquence potentielle** : Incompréhension chronologique, l'agent pourrait croire que le miroir GitHub est déjà actif et chercher à l'interroger.

8. **Emplacement** : Critères d'acceptation (`[ ] Aucun signalement ni motif n'est recopié...`)
   - **Condition de déclenchement** : Une contrainte négative et permanente est formatée comme une tâche active (case à cocher).
   - **Garde-fou** : Sortir ce point des cases à cocher pour en faire un bloc "Contraintes".
   - **Conséquence potentielle** : L'agent cherche à exécuter une action technique pour "ne pas copier" quelque chose, ce qui est illogique et interfère avec son plan d'implémentation.

9. **Emplacement** : Critères d'acceptation (la réécriture éventuelle)
   - **Condition de déclenchement** : La phrase "la réécriture éventuelle est décidée par Arnaud" est ambiguë sur qui *exécute* la réécriture.
   - **Garde-fou** : Préciser si l'agent a l'interdiction totale de réécrire l'historique et qu'Arnaud le fait manuellement de son côté.
   - **Conséquence potentielle** : Face à un signalement, l'agent pourrait prendre l'initiative de lancer des commandes destructrices (type `git filter-repo`) pour accomplir la story.

10. **Emplacement** : Critères d'acceptation
    - **Condition de déclenchement** : La consigne se fie à la mention "toutes branches et tous tags compris". Un simple `git rev-list --all` peut omettre certaines références internes (`refs/pull/*`) selon la façon dont le clone a été fait.
    - **Garde-fou** : Préciser si la commande d'Arnaud doit inclure une récupération explicite (`git fetch origin '+refs/pull/*:refs/pull/*'`) avant le lancement du script.
    - **Conséquence potentielle** : Un faux sentiment de sécurité si des commits sensibles présents uniquement dans des PR locales fermées passent sous le radar de l'audit.

##### Lentilles Éditoriales (Structure et Prose)

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| structure | `Bloquée par : —` | MERGE avec la section `Questions à poser avant de commencer` | La spec contient des questions bloquantes, elle ne peut pas être indiquée comme non bloquée. |
| structure | `Étant donné un signalement... avant un nouvel audit.` | MERGE en condition d'échec dans le critère principal | La gestion d'une erreur ne doit pas se trouver sur le même plan narratif que les critères de succès de la fonctionnalité. |
| structure | `- [ ] Aucun signalement ni motif n'est recopié...` | MOVE vers une section "Contraintes" (ou au-dessus de la liste) | Une contrainte négative n'est pas une tâche exécutable et falsifiable pour une case à cocher. |
| prose | `un clone miroir récent du dépôt de la forge (branches main, dev, design/dossier-architecture, design/suisse, experiment/d2-bilingue et toutes les autres références)` | `un clone miroir récent du dépôt de la forge (incluant toutes les branches et références)` | L'énumération spécifique de quelques branches allonge la phrase inutilement tout en devenant obsolète rapidement. |
| prose | `Le commit de tête de chaque branche auditée et la date sont notés.` | `Le commit de tête de chaque branche auditée et la date sont notés dans le fichier de la story.` | Supprime l'ambiguïté sur l'endroit exact où ce livrable attendu doit être écrit. |
| prose | `puis les tests de 1.2 sont rejoués` | `puis le fonctionnement du hook serveur (story 1.2) est vérifié` | Remplace une référence abstraite par une consigne explicite sur ce qui doit être testé. |

**Résumé éditorial** : 6 recommandations. Estimations (script non exécuté) : document très court (~200 mots) ; réduction d'environ 30 mots si toutes les modifications structurelles et de prose sont acceptées. La clarté des instructions de la tâche est améliorée au détriment d'un léger raccourcissement.

---

##### À trancher avant d'implémenter

* **Auditer les PR internes ?** Doit-on explicitement inclure les références `refs/pull/*` locales dans le périmètre de l'audit avant d'activer le miroir ?
* **Interaction Agent / Humain :** Quelle est la mécanique exacte de validation ? (ex: Arnaud s'engage-t-il à coller manuellement la sortie et le code de retour de la commande `check-private.sh history` dans la conversation pour que l'agent puisse cocher la tâche ?)
* **Variable environnementale :** Confirmez-vous que la commande à exécuter sur le clone nu devra inclure explicitement `PRIVATE_PATTERNS_FILE=/chemin...` ? Sans cela, l'audit échouera silencieusement en mode "chemins seulement".
* **Réécriture de l'historique :** En cas d'anomalie, est-ce une opération 100 % manuelle par Arnaud, ou l'agent est-il censé écrire et suggérer un script de réécriture (type `git filter-repo`) ?

Relevé préalable de l'auteur (16/09/2026), sans contenu privé : la forge expose 5 branches (`main`, `dev`, `design/dossier-architecture`, `design/suisse`, `experiment/d2-bilingue`), aucun tag et 17 références `refs/pull/*/head`, qui donnent seules accès à 64 commits (branches supprimées après squash, PR de test).

Tri de l'auteur (questions tranchées par Arnaud le 16/09/2026) :

- script absent d'un clone miroir : corrigé, le script du dépôt de travail est lancé depuis le clone miroir ; le mode `history` lit les commits sans arbre de travail, comme le mode `pre-receive` de la story 1.1 ;
- `PRIVATE_PATTERNS_FILE` sur le clone miroir : corrigé, la variable est dans la commande du critère, et la sortie ne doit pas contenir « chemins seulement » ;
- preuve de l'exécution : tranché, l'audit est lancé par l'agent, qui note code de sortie et chiffres dans ce fichier ;
- « tests de 1.2 rejoués » après une réécriture : corrigé, ce sont les essais 1 et 3 du hook, puisqu'une réécriture passe par un push forcé, donc par le hook ;
- où noter les commits et la date : corrigé, dans ce fichier de story ;
- « Bloquée par » et contrainte en case à cocher : corrigé, questions tranchées ici et section « Contraintes » ;
- question sur le miroir : corrigée pour l'audit, et renvoyée à la story 1.4 pour le comportement du miroir vis-à-vis de `refs/pull/*` ;
- qui réécrit l'historique : tranché, jamais l'agent ; Arnaud décide et exécute, ou autorise chaque commande ;
- `refs/pull/*` oubliés : tranché, périmètre = toutes les références, qu'un `git clone --mirror` récupère ;
- rédaction (trois reformulations) : corrigé à la réécriture.

## Audit de l'historique

16/09/2026, clone miroir jetable du dépôt de la forge, hors du dépôt de travail, supprimé après l'audit. Commande : `PRIVATE_PATTERNS_FILE=<liste du poste> <dépôt de travail>/scripts/check-private.sh history`, lancée depuis ce clone. Rien n'a été poussé vers la forge.

- Périmètre : 23 références (6 branches, aucun tag, 17 `refs/pull/*/head`), 89 commits accessibles.
- Résultat : **code 0, aucune sortie**, donc aucun signalement, et aucune mention « chemins seulement » : l'audit a bien tourné avec la liste des motifs.
- Durée : 4 secondes.

Têtes des branches auditées :

| Branche | Commit de tête |
|---|---|
| `main` | `9e14036` |
| `dev` | `10d6dbb` |
| `design/dossier-architecture` | `04ed986` |
| `design/suisse` | `c7ab03e` |
| `experiment/d2-bilingue` | `1dfe25b` |
| `feat/1-3-full-history-audit-with-pattern-list` | `0e0debe` (branche de cette story) |

Aucune réécriture d'historique n'a été nécessaire, donc aucune n'a été proposée ni lancée.

Second passage, 16/09/2026, après la revue du code de la PR n° 18 : nouveau clone miroir jetable, qui contient cette fois la tête de la branche de la story (`3267f5b`), soit 24 références et 90 commits. Résultat identique : **code 0, aucune sortie**, aucune mention « chemins seulement ». Clone supprimé, rien poussé.

| Branche | Commit de tête (second passage) |
|---|---|
| `main` | `9e14036` |
| `dev` | `10d6dbb` |
| `design/dossier-architecture` | `04ed986` |
| `design/suisse` | `c7ab03e` |
| `experiment/d2-bilingue` | `1dfe25b` |
| `feat/1-3-full-history-audit-with-pattern-list` | `3267f5b` |

Un audit ne couvre que ce qui existe quand il tourne : les commits suivants sont couverts par le garde-fou de chaque fusion et par le hook de la forge, et la story 1.4 relance l'audit juste avant d'activer le miroir (critère ajouté après cette revue).

## Revue du code

### 16/09/2026 — `3267f5b` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 18. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 566009e4cecc093120bb588e

##### Revue du code (BMAD Review)

###### Lentille : verification-gap

- **Emplacement** : `_bmad-output/implementation-artifacts/1-3-full-history-audit-with-pattern-list.md` (Section « Têtes des branches auditées »)
- **Condition de déclenchement** : Le rapport d'exécution indique que la tête de la branche `dev` auditée est au commit `10d6dbb`. Or, le commit de base de cette PR (indiqué par la forge pour `dev`) est `3267f5b8def67bee236fcf930ddd0f12300bc70f`. L'audit n'a donc pas été fait sur l'historique complet et récent, ou les valeurs ont été recopiées machinalement depuis la revue de spec sans véritable exécution à jour.
- **Garde-fou** : L'agent doit refaire un clone miroir véritablement à jour avec la tête actuelle de `dev` (et de toutes les autres références), relancer l'audit, et consigner les SHA réels correspondants.
- **Conséquence potentielle** : Tout commit ajouté à `dev` entre `10d6dbb` et `3267f5b` échappe à l'audit. S'il contient des données privées, celles-ci fuiront sur GitHub lors de l'activation du miroir push (story 1.4).
BLOQUANT

###### Lentille : edge-case-hunter

- **Emplacement** : `_bmad-output/implementation-artifacts/1-3-full-history-audit-with-pattern-list.md` (Section « Audit de l'historique »)
- **Condition de déclenchement** : La commande enregistrée utilise les espaces réservés `<liste du poste>` et `<dépôt de travail>` au lieu des chemins absolus locaux réels.
- **Garde-fou** : Cette pratique doit être conservée pour cet artefact.
- **Conséquence potentielle** : Masquer les chemins absolus locaux évite de faire fuiter indirectement des informations privées (comme le nom d'utilisateur du système) dans les fichiers suivis.
NON BLOQUANT

###### Lentilles éditoriales (Structure et Prose)

- **Emplacement** : `_bmad-output/implementation-artifacts/1-3-full-history-audit-with-pattern-list.md` (Section « Audit de l'historique »)
- **Condition de déclenchement** : Le compte-rendu de l'audit est rédigé de manière claire, sans ambiguïté sur le déroulement de l'opération ou ses résultats.
- **Garde-fou** : Aucun changement nécessaire.
- **Conséquence potentielle** : Une lecture rapide et fiable du suivi de sprint.
NON BLOQUANT

##### Couche propre au projet

- **Emplacement** : `_bmad-output/planning-artifacts/epics.md` et `1-3-full-history-audit-with-pattern-list.md`
- **Condition de déclenchement** : L'intention du critère d'acceptation exigeant l'audit d'un « clone miroir récent » contenant « toutes ses références » est vidée de son sens par le décalage temporel du commit de base de `dev`.
- **Garde-fou** : Vérifier systématiquement que le SHA de `dev` audité correspond au minimum au SHA de base de la PR courante.
- **Conséquence potentielle** : Un faux positif critique qui autoriserait prématurément l'activation du miroir public.
BLOQUANT

- **Emplacement** : L'ensemble du diff
- **Condition de déclenchement** : Aucune donnée privée, aucun secret, ni nom d'hôte ou adresse de serveur n'a été commité. Les modifications de statut dans `sprint-status.yaml` et de texte dans `epics.md` sont conformes aux procédures (AD-24 et exception documentaire).
- **Garde-fou** : Maintenir cette intégrité.
- **Conséquence potentielle** : Le dépôt reste propre et le flux de travail documenté est respecté.
NON BLOQUANT

VERDICT: BLOQUANT — L'audit a été réalisé ou consigné sur un historique obsolète (dev à 10d6dbb au lieu de 3267f5b), vidant de son sens la validation du garde-fou avant l'activation du miroir public.

### 16/09/2026 — `6e85d53` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 18. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 50dcfe4fb8ce30dbab69c6a8

##### Rapport de revue BMAD

###### Lentilles

**edge-case-hunter** :
Aucun cas limite non traité n'a été trouvé. Le changement étant purement documentaire et orienté sur le suivi, tous les chemins conditionnels décrits (ex: gestion d'un signalement, délégation de la réécriture) sont explicitement gérés.

**verification-gap** :
No verification gaps found. (Le correctif est non comportemental et ne concerne que les fichiers d'artefacts de projet).

###### Couche propre au projet

- **Emplacement** : `_bmad-output/implementation-artifacts/1-3-full-history-audit-with-pattern-list.md` et `_bmad-output/planning-artifacts/epics.md`
- **Condition de déclenchement** : Les explications apportées par l'auteur établissent que l'audit a bien couvert le commit de base de la PR (`10d6dbb`) ainsi que la tête de branche courante (`3267f5b`). Les critères d'acceptation sont bien satisfaits et l'ajout d'une relance d'audit pour la story 1.4 garantit que leur intention ne sera pas vidée par des commits intermédiaires.
- **Garde-fou** : Maintenir le nouveau critère sur la story 1.4 pour l'audit final avant l'activation du miroir.
- **Conséquence potentielle** : L'historique est validé sur un périmètre exact et pertinent sans bloquer la fusion.
NON BLOQUANT

- **Emplacement** : L'ensemble du diff
- **Condition de déclenchement** : Le patch ne fait fuiter aucune donnée privée, aucun secret, ni nom d'hôte ou adresse de serveur. Les chemins locaux ont bien été masqués par des variables substitutives (`<liste du poste>`, `<dépôt de travail>`).
- **Garde-fou** : Continuer à masquer systématiquement les chemins absolus locaux dans l'artefact de la story.
- **Conséquence potentielle** : L'intégrité de la séparation public/privé est maintenue et aucun secret n'est exposé.
NON BLOQUANT

- **Emplacement** : L'ensemble du diff
- **Condition de déclenchement** : La modification cible exclusivement des artefacts de planification (Markdown) et le statut de sprint (YAML). Aucun script, procédure ou skill n'est modifié ou ajouté, ce qui exclut tout décalage entre la théorie documentée et la pratique technique.
- **Garde-fou** : Aucun changement nécessaire.
- **Conséquence potentielle** : Le code et l'outillage de l'agent restent parfaitement synchronisés.
NON BLOQUANT

- **Emplacement** : `_bmad-output/planning-artifacts/epics.md` (Critères d'acceptation et décisions)
- **Condition de déclenchement** : L'interdiction stricte faite à l'agent de lancer de sa propre initiative des commandes destructrices pour l'historique (comme `git filter-repo`) est parfaitement cohérente avec les limites définies dans `AGENTS.md`. L'audit réalisé via un clone miroir jetable respecte aussi les décisions de sécurité.
- **Garde-fou** : Aucun changement nécessaire.
- **Conséquence potentielle** : Le système n'agit pas au-delà de ses attributions, assurant la sécurité du flux de développement.
NON BLOQUANT

- **Emplacement** : L'ensemble du diff
- **Condition de déclenchement** : Le patch ne modifie aucun fichier de script `.sh`. De ce fait, aucune commande vulnérable n'est introduite sous l'option `set -euo pipefail`.
- **Garde-fou** : Aucun changement nécessaire.
- **Conséquence potentielle** : Les scripts restent robustes et aucune erreur shell ne passera sous silence.
NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur les revues du code de la PR n° 18 :

- `3267f5b` (block) :
  - « audit sur un historique obsolète, dev à 10d6dbb au lieu de 3267f5b » : écarté sur le fond, la prémisse étant fausse (`3267f5b` est la tête de la branche de la story, la base de la PR est bien `dev` à `10d6dbb`, le SHA audité), mais traité sur décision d'Arnaud : audit relancé sur un clone frais contenant la tête de la branche (`6e85d53` suit ce second passage), et critère ajouté à la story 1.4 pour relancer l'audit juste avant l'activation du miroir ;
  - chemins absolus masqués par des espaces réservés : constat non bloquant, pratique conservée.
- `6e85d53` (pass) : aucun constat, confirmations seulement.


## Reporté
