# Story 11.10 : Thirty-second test

Status: in-progress

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.10.

Première story de la section « Mise en ligne du socle » de l'epic 11 (point 21 : le socle est
complet, il est jugé, puis mis en ligne). Ses dépendances sont closes : 9.4, 10.1 à 10.10 (epic 10
clos le 03/10/2026, PR n° 132), 11.9 (répétition jouée le 02/10/2026, PR n° 128).

Opération manuelle d'Arnaud : la répétition sur l'arbre du socle (`v1.0.0-rc.1`, `v1.0.0-rc.2`,
retour arrière), puis cinq passages du test des trente secondes (`EXPERIENCE.md`, « Test des trente
secondes »), par partage d'écran sur le site de répétition.

**Tension relevée à l'ouverture** : `scripts/rehearse-release.sh --run` enchaîne la répétition
jusqu'à `rehearse stop`, qui arrête le conteneur et supprime les images `-rc` ; le test, lui, se mène
sur le site de répétition, qui doit donc servir pendant les cinq passages. La revue de spec et
l'arbitrage d'Arnaud diront comment les deux se raccordent.

## Revue de spec

### 03/10/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `8d8eb4f`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b6f802e78a8ca4a2a61422af

Voici le rapport de la revue de spec pour la story 11.10.

##### Rapport de revue (bmad-review)

**Lentille Adverse (Edge cases & Logique)**
- BLOQUANT : Contradiction temporelle sur l'arbre testé. Le critère 1 décrit le déroulé complet de la répétition, incluant le retour arrière (`rehearse rollback v1.0.0-rc.1`) avant la fin du processus. Si le test manuel est mené après ce rollback, il portera sur la version `rc.1` annulée et non sur la version candidate finale du socle (`rc.2`). La spec doit préciser à quelle étape exacte de la séquence le test est intercalé.
- BLOQUANT : Conflit d'exécution entre l'automatisation du script et le temps humain (la tension signalée). Le critère 1 stipule que `rehearse stop` suit le dernier passage du test. Or, si la commande `rehearse-release.sh --run` enchaîne toutes les étapes jusqu'à la destruction du conteneur sans faire de pause, le test est physiquement impossible à mener. La spec doit préciser si Arnaud lance les sous-commandes `rehearse` une par une à la main (ex: `deploy`, puis test, puis `stop`) ou si le script `--run` a été prévu pour marquer une pause.
- BLOQUANT : Incohérence avec `EXPERIENCE.md` sur le périmètre du test. Le document `EXPERIENCE.md` (Test des trente secondes) exige que le test soit passé par partage d'écran sur l'environnement de répétition, **puis** "une fois après la mise en ligne du socle, sur le téléphone du testeur". La story 11.10 ayant lieu *avant* la mise en ligne du socle (story 11.11), elle ne peut pas satisfaire cette seconde exigence. Il y a un conflit de périmètre à arbitrer avec `EXPERIENCE.md`.
- BLOQUANT : Fichier de destination des mesures non spécifié. Le critère 2 exige que chaque passage soit "noté dans docs/measures/" mais ne nomme ni le fichier cible (ex: `docs/measures/thirty-second-test.md`) ni son format (liste Markdown, tableau, JSON). Ce manque rend le critère invérifiable de manière déterministe et obligera le développeur à inventer une convention de nommage.

**Lentilles Structure & Prose**
- NON BLOQUANT : Oubli du critère d'acceptation du chemin nominal (succès). Le critère 3 détaille précisément le flux de reprise en cas d'échec (moins de 4 réussites), mais aucun critère ne décrit formellement la condition de succès (4 ou 5 réussites validant la story sans retouche).
- NON BLOQUANT : La traçabilité de la revérification de FR-37 n'est pas précisée. Le critère 3 indique que "FR-37 est revérifié" en cas de retouche du haut de l'accueil, mais ne dit pas si cette vérification doit laisser une trace documentaire ou s'il s'agit d'un simple contrôle visuel d'Arnaud.

##### À trancher avant d'implémenter

- À quel moment précis de la répétition générale (avant le `rollback v1.0.0-rc.1` ?) le test doit-il être mené pour garantir qu'on teste la bonne image ?
- Quelle est la méthode exacte d'exécution ? Arnaud doit-il lancer les commandes `rehearse` étape par étape au lieu de `--run`, ou le script actuel permet-il de suspendre l'exécution en attendant les tests ?
- Quel nom de fichier exact et quel format doivent être utilisés pour stocker les verdicts dans `docs/measures/` ?
- La story 11.10 ne couvrant que la répétition, faut-il reporter la phase de test "sur le téléphone du testeur" à une story ultérieure (post-11.11), ou bien faut-il amender `EXPERIENCE.md` pour retirer cette exigence ?

### Tri des constats (03/10/2026, orchestrateur)

| # | Constat | Décision |
|---|---|---|
| A1 | Après le retour arrière, on testerait `rc.1`, « annulée », et non `rc.2` (BLOQUANT) | **Réfuté.** `rehearse-release.sh` pose les deux tags sur le **même commit** d'`origin/dev` (`pose_le_tag` sur `dev_sha`, story 11.8) : `rc.1` et `rc.2` portent le même arbre, celui du socle. Le retour arrière éprouve la mécanique, pas un contenu différent. Quelle que soit l'étape, le site de répétition sert l'arbre du socle. |
| A2 | Le script enchaîne jusqu'à `rehearse stop` : le test est impossible (BLOQUANT) | **Retenu : arbitrage demandé à Arnaud** (méthode pour garder le site de répétition en service pendant les cinq passages). |
| A3 | `EXPERIENCE.md` prévoit aussi un passage après la mise en ligne, sur le téléphone du testeur (BLOQUANT) | **Retenu : arbitrage demandé à Arnaud** (où atterrit ce second passage). La 11.10 couvre le passage sur la répétition, seul possible avant la 11.11. |
| A4 | Fichier des mesures non nommé (BLOQUANT) | **Retenu, tranché ici.** Un fichier, `docs/measures/thirty-second-test.md` : une section par session (« Répétition, `v1.0.0-rc.N`, date », plus tard « Après mise en ligne »), un tableau par session — passage, rôle du testeur, langue, appareil, réponses résumées aux trois questions, touchers jusqu'à une section de cas, verdict —, puis le compte et la décision. Aucun nom, aucune donnée personnelle. `docs/measures/README.md` le nomme à côté des mesures de performance par version. Noms de fichiers en anglais (AGENTS.md). |
| S1 | Pas de critère pour le succès | **Retenu** : quatre ou cinq réussites → la story est `done` sans retouche, et la 11.11 peut partir. |
| S2 | La revérification de FR-37 ne laisse pas de trace | **Retenu** : en cas de retouche, la mesure FR-37 (méthode de la story 10.9) est consignée dans la même section du fichier de mesures. |

**Arbitrages d'Arnaud (03/10/2026) :**

1. **A2, garder le site de répétition en service : option b, sans code.** La répétition complète se
   joue d'abord (`scripts/rehearse-release.sh v1.0.0-rc.1 --run`, qui s'arrête par `rehearse stop`) ;
   puis un tag de répétition de plus, posé à la main sur le même commit d'`origin/dev`, est livré par
   le workflow `release` au canal de répétition, où il reste en service le temps des cinq passages ;
   `rehearse stop` à la main ensuite. Marche à suivre : `docs/procedures/rehearse-release.md`,
   « Garder une répétition en service ». Options écartées : une option `--garder` du script
   (recommandée par l'orchestrateur) ; mener le test entre deux étapes du script.
2. **A3, le second passage après mise en ligne : option a.** Il devient une case de la check-list de
   la story 11.11, ses résultats dans le même `docs/measures/thirty-second-test.md`. Options
   écartées : une question ouverte pour une story future ; retirer ce passage d'`EXPERIENCE.md`.

## Revue du code
