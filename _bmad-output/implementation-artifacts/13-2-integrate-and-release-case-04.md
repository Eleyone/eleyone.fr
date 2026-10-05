# Story 13.2 : Integrate and release case 04

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 13.2.

Première story de l'epic 13 (« après le socle : les cas 03, 04 et 06 mis en ligne un par un sous leur
poste, chacun par son tag », point 21). Story d'intégration : le cas 04 (« Chiliz, reprise d'un sujet
en dérive ») est **rédigé par Arnaud** — `content/cases/chiliz/case-04-chiliz.{fr,en}.md`, en
brouillon, sans `[TODO]` ; l'archive remise le 03/10/2026 le porte à l'identique. Son blocage par Q2
est levé le 05/10/2026 (PR n° 146) : période « décembre 2025 – mars 2026 », confirmée par Arnaud.

Chemin : `scripts/publish-case.sh case-04` (contrôles, puis `--relu` **par Arnaud**, après sa
relecture des deux fichiers), PR, puis mise en ligne par un nouveau tag (skill `release`).

## Revue de spec

### 05/10/2026 — `gemini-3.1-pro-high` (angles : adversarial, structure, prose), `dev` à `e8884d3`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f537683c93546c064f8a7215

*Note : Il m'a été demandé de lister le répertoire de travail, mais les commandes shell m'étant strictement interdites et mon outil de lecture de fichier ne supportant pas l'affichage des répertoires, j'ai directement procédé à la lecture du fichier cible sans effectuer de listage.*

##### Revue de la spec (Lentilles : Adversarial, Structure, Prose)

BLOQUANT : Le nom de fichier cible `case-04-<nom-court>.{fr,en}.md` inclut un espace réservé, alors que l'auteur confirme l'existence du fichier sous le nom `case-04-chiliz.{fr,en}.md`, créant deux lectures contradictoires pouvant amener l'agent à renommer ou dupliquer le fichier à tort.
BLOQUANT : La spec omet de demander l'intégration de la période « décembre 2025 – mars 2026 » (validée le 05/10 lors de la levée du blocage Q2) dans le contenu du cas qui a été rédigé le 03/10, un cas oublié qui ferait perdre une donnée fraîchement validée.
BLOQUANT : Le critère exigeant que la section prenne sa place « dans l'ordre 02, 03, 04 parmi les sections publiées » suppose que le cas 03 est déjà publié ; si les cas sont mis en ligne un par un et que le 03 est encore en brouillon, ce critère correspond à un état impossible et devient invérifiable.
BLOQUANT : L'expression « sans modifier la page » admet deux lectures contradictoires : l'absence de modification du fichier de modèle parent (intention architecturale légitime) ou l'absence de modification du rendu HTML final (ce qui est matériellement faux puisqu'on y ajoute le cas 04).
BLOQUANT : Le critère « Quand Arnaud publie un nouveau tag » teste une action humaine qui survient lors de la release (hors périmètre de la PR sur `dev`), ce qui le rend totalement invérifiable par l'agent lors de la réalisation de la story.
BLOQUANT : L'attente « le cas est mis en ligne seul » est ambiguë et contredit l'architecture de site statique (le site entier est déployé à chaque tag) ; si l'intention est de s'assurer que les cas brouillons 03 et 06 ne fuitent pas, la formulation actuelle est trompeuse.
BLOQUANT : Oubli d'une règle transversale du projet (règle 8 du fichier `AGENTS.md`) exigeant de passer au présent les phrases au futur concernant ce cas une fois publié (dans le PRD ou l'architecture) ; la spec ne mentionnant pas cette mise à jour, son implémentation contredirait la méthode imposée.

##### À trancher avant d'implémenter

- Le nom du fichier : faut-il utiliser l'espace réservé `<nom-court>` de la spec ou s'aligner sur le nom exact `chiliz` du fichier existant ?
- Les dates Q2 : faut-il ajouter explicitement une consigne pour intégrer la période « décembre 2025 – mars 2026 » dans le fichier Markdown du cas ?
- L'ordre attendu : si le cas 03 n'est pas encore en ligne, le critère doit-il être ajusté pour vérifier uniquement que le cas 04 s'affiche après le 02 ?
- La modification de la page : l'attente est-elle bien « sans modifier le fichier source du modèle (template) de la page parente » ?
- Le second critère d'acceptation : doit-il être supprimé car hors périmètre de la story, ou reformulé pour vérifier localement que le build généré omet bien les autres cas brouillons (03 et 06) ?

### Tri des constats (05/10/2026, orchestrateur)

| # | Constat | Décision |
|---|---|---|
| 1 | `case-04-<nom-court>` contre `case-04-chiliz` (BLOQUANT) | **Réfuté.** `<nom-court>` est le gabarit de nommage de `docs/format-cas.md` ; le fichier existe sous `case-04-chiliz`, comme le cas pilote `case-02-chiliz`. Aucun renommage. |
| 2 | La période validée le 05/10 n'est pas demandée dans le contenu (BLOQUANT) | **Réfuté** : elle y est déjà — `context.period: "décembre 2025 – mars 2026"` (FR) et `"December 2025 – March 2026"` (EN), dans les fichiers rédigés ; la décision du 05/10 l'a confirmée, pas apportée. C25 la vérifie dans la période du poste Chiliz. |
| 3 | « Ordre 02, 03, 04 » alors que le cas 03 est en brouillon (BLOQUANT) | **Retenu comme lecture** : « parmi les sections publiées » — en production, 02 puis 04 ; la 03 (`order: 2`) s'insérera entre les deux à sa publication (story 13.1). Vérifié sur le build de production avant la PR. |
| 4 | « Sans modifier la page » : le gabarit ou le rendu ? (BLOQUANT) | **Retenu comme lecture** : sans modifier `content/cases/chiliz/_index.*.md` ni aucun gabarit ; le rendu change évidemment, il gagne la section 04. |
| 5 | « Quand Arnaud publie un nouveau tag » est hors de la PR (BLOQUANT) | **Retenu** : la mise en ligne suit la fusion (skill `release`, lancée par Arnaud), comme pour la story 9.8 ; sa vérification sur le site en ligne est faite par l'orchestrateur et consignée avec la publication. La story se clôt à la fusion. |
| 6 | « Mis en ligne seul » contredit un site déployé en entier (BLOQUANT) | **Retenu comme lecture** : seul le cas 04 apparaît de nouveau ; les cas 03 et 06, en brouillon, restent absents du build de production — vérifié avant la PR et sur le site en ligne. |
| 7 | Phrases au futur à passer au présent (règle 8) (BLOQUANT) | **Vérifié** : aucune phrase du PRD, de l'architecture ni de `docs/` n'annonce le cas 04 au futur (grep « cas 04 » avec « sera », « à venir », « plus tard ») ; le titre de l'epic 13 décrit son programme et reste juste. Rien à changer. |

Le relecteur note qu'on lui a demandé de lister un dossier et qu'il s'en est abstenu, faute d'outil : sans effet sur le fond.

## Publication (05/10/2026)

- `scripts/publish-case.sh case-04` (audit) : contrôles verts ; deux fichiers à passer hors brouillon,
  `case-04` à ajouter à `ci/release-pages.txt`, `group-chiliz` déjà présent.
- **Relecture d'Arnaud** : « relu » (05/10/2026) — c'est la trace que `--relu` porte.
- **Les gestes de `--relu` faits sur la branche de la story**, comme la story 10.7 l'avait fait pour le
  cas 05 (PR n° 112) : le script n'écrit que depuis `dev`, dans une branche `feat/publish-case-<clé>`
  sans numéro de story, que les verrous ne relieraient pas à cette story (point 1 d'AGENTS.md).
  Mêmes gestes : `draft: false` dans le front matter seul, une ligne par fichier ; `case-04` ajouté à
  `ci/release-pages.txt`.
- Build de production : `public/cas/chiliz/index.html` porte les sections `case-02` puis `case-04` ;
  aucune trace des cas 03 et 06 ; le poste Chiliz gagne le lien du cas 04 ; `_index` et gabarits
  inchangés (constats 3, 4 et 6 du tri).
- `scripts/check.sh --release` avec les vraies valeurs légales (`ENV_MODE=release`) : 13 contrôles
  passés. Sans elles, C15 refuse les valeurs factices des mentions légales, comme il le doit au niveau
  `release`.

## Revue du code

### 05/10/2026 — `f5f14eb` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 147. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a124d59473d243df090e140a

##### Revue de code

###### Lentille : edge-case-hunter

- Aucun constat. Le contenu modifié (passage de `draft: true` à `draft: false` dans un front matter, mise à jour d'un statut de suivi de sprint, ajout d'une entrée dans un fichier texte plat, ajout d'un rapport de story) ne comporte aucune logique de contrôle de flux, aucune branche conditionnelle, ni aucune boucle nécessitant la couverture d'un cas limite ou d'une erreur d'exécution. L'analyse des chemins non gérés retourne un résultat vide.

###### Lentille : verification-gap

- Aucun constat. Le changement de comportement (l'affichage en production du cas 04 suite à la suppression de son état de brouillon) est explicitement vérifié, à la fois manuellement ou par l'orchestrateur ("Build de production : public/cas/chiliz/index.html porte les sections case-02 puis case-04"), et par la chaîne de contrôle automatisée (`scripts/check.sh --release` avec les valeurs de production a passé 13 contrôles au vert). L'absence des autres cas en brouillon (03, 06) est également validée. Il n'y a donc aucune régression non couverte ni faille de vérification.

##### Contrôles propres au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits (le statut de brouillon est levé et les vérifications de publication du cas 04 documentent la réussite).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité (le diff ne touche que des configurations de mise en ligne et le statut du suivi de sprint).
- NON BLOQUANT : Skill, procédure et script concordent (aucun fichier de ce type n'est modifié).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (la publication d'un cas s'effectue bien par la modification du flag `draft` dans le front matter).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence (aucun script shell n'est modifié).

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue de `f5f14eb` (orchestrateur)

Sept constats de conformité, sans demande de changement : **pris acte**, un par un — aucun cas limite
(aucune logique modifiée) ; aucune faille de vérification (build de production et `check.sh --release`) ;
critères satisfaits ; aucune donnée privée ; concordance sans objet ; cohérence avec AD-4 et
`publish-case` ; aucun script modifié.
