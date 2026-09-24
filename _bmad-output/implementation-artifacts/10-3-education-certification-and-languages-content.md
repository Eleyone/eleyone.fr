# Story 10.3 : Education, certification and languages content

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.3.

## Revue de spec

### 24/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `18d7ad4`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d00d4caf269d53cb9b266bb2

### Rapport de revue de spec (Story 10.3)

#### Lentille : Adversarial (Edge cases, verification gaps, contradictions)

- **Ordre de tri et champs obligatoires du front matter**
  - **Localisation** : Critères d'acceptation
  - **Déclencheur** : La spec demande d'intégrer des contenus pour le gabarit construit en 5.3, mais ne liste pas les clés de front matter obligatoires (ex: date d'obtention, `weight`, type) attendues par ce gabarit pour assurer un tri et un affichage corrects.
  - **Garde-fou** : Lister les clés de front matter requises par l'implémentation issue de 5.3 pour ces entrées.
  - **Conséquence** : Si des champs attendus par le gabarit manquent, le tri préétabli échouera et affichera le parcours de formation dans un ordre aléatoire, ou le rendu pourrait casser.
  - **Classement** : BLOQUANT

- **Validation manuelle des identifiants vs Auto-fusion**
  - **Localisation** : Critère `Chaque donnée figure dans le CV...`
  - **Déclencheur** : La spec exige des "identifiants proposés par le développeur et confirmés par Arnaud". Or, la règle 4 des verrous de fusion (`AGENTS.md`) stipule qu'une PR de story est fusionnée par l'agent lui-même dès que la CI et les vérifications passent, sans bloquer sur une validation humaine pour le code.
  - **Garde-fou** : Demander à Arnaud de fournir directement les identifiants cibles avec le contenu, ou clarifier que la confirmation se fait via un commentaire de PR sans bloquer la règle de fusion automatique.
  - **Conséquence** : Le développeur risque d'interrompre l'autonomie du processus en attendant une validation humaine explicite pour fusionner, ou fusionnera sans cette validation en violant les critères.
  - **Classement** : BLOQUANT

- **Absence explicite du passage à `draft: false`**
  - **Localisation** : Critères d'acceptation
  - **Déclencheur** : Il s'agit d'une story d'intégration de contenu (règle 4 des stories), qui a pour but de publier ces éléments. Le critère demande un affichage au build de production, mais n'explicite pas la modification de l'état de brouillon.
  - **Garde-fou** : Ajouter la mention explicite "Les fichiers Markdown sont créés avec (ou passent à) `draft: false`".
  - **Conséquence** : Un développeur pourrait créer les fichiers avec `draft: true` par habitude, le bloc n'apparaîtrait pas en production (test échoué), causant une confusion évitable.
  - **Classement** : NON BLOQUANT

- **Mention limitative des contrôles bloquants**
  - **Localisation** : Critères d'acceptation
  - **Déclencheur** : La spec exige que "C3 et C19 passent", oubliant de mentionner C5 (absence de `[TODO]` dans le contenu publié) et C24 (règles de typographie française), qui sont pourtant cruciaux pour du texte intégré.
  - **Garde-fou** : Remplacer par "l'ensemble des contrôles bloquants de `scripts/check.sh` passent (incluant C3, C5, C19 et C24)".
  - **Conséquence** : L'agent pourrait négliger la vérification de la typographie ou laisser un marqueur TODO, pensant que la validation se limite à C3 et C19.
  - **Classement** : NON BLOQUANT

- **Risque d'inclusion d'une donnée privée (NFR-9)**
  - **Localisation** : Prérequis de contenu
  - **Déclencheur** : Le contenu recopié depuis le CV (comme le nom ou l'adresse d'un établissement) pourrait accidentellement correspondre à un motif interdit (ex: ville de résidence actuelle).
  - **Garde-fou** : Rappeler au développeur d'être vigilant vis-à-vis de la liste de motifs du garde-fou lors de l'extraction des données.
  - **Conséquence** : Le hook de Gitea ou le script `check-private.sh` bloquera le commit en cas de correspondance, ce qui fera perdre du temps au développeur pour repérer l'erreur.
  - **Classement** : NON BLOQUANT

#### Lentille : Structure

- **Critère de relecture détaché du format d'exécution**
  - **Localisation** : Case à cocher finale
  - **Déclencheur** : La vérification d'exactitude des données est placée dans une case à cocher flottante, hors de la structure systémique Étant donné / Quand / Alors.
  - **Garde-fou** : Formuler cette attente dans un bloc ou une instruction directe liant l'extraction manuelle et la source.
  - **Conséquence** : Le critère pourrait être perçu comme secondaire et être moins rigoureusement testé.
  - **Classement** : NON BLOQUANT

#### Lentille : Prose

- **Ambiguïté sur le format du prérequis de contenu**
  - **Localisation** : Prérequis de contenu
  - **Déclencheur** : L'expression "entrées FR et EN tirées du CV d'Arnaud" ne permet pas de savoir sous quelle forme ces données seront transmises au développeur (texte brut, Markdown prêt à l'emploi, PDF nécessitant une extraction).
  - **Garde-fou** : Préciser explicitement le format des données entrantes.
  - **Conséquence** : L'agent pourrait bloquer ou hésiter sur la manière d'interpréter sa tâche d'intégration.
  - **Classement** : NON BLOQUANT

---

#### À trancher avant d'implémenter

- **Validation des identifiants** : Comment gérer la confirmation des identifiants de chaque formation par Arnaud sans bloquer la règle de l'auto-fusion par l'agent ? (Arnaud peut-il les fixer d'emblée dans le prérequis de contenu ?)
- **Champs front matter du gabarit** : Quelles sont les clés de front matter exactes attendues par le gabarit (construit à la story 5.3) pour que l'affichage et le tri des formations se fassent correctement (ex: dates, type, classement) ?
- **Format du contenu source** : Sous quelle forme exacte Arnaud fournit-il les textes des formations, certifications et langues avant de démarrer la story ?

## Revue du code

### 24/09/2026 — `8646005` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 110. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: e511c215ea8ee09707e17bad

##### Rapport de revue (Lentilles BMAD & Couche Projet)

###### Lentille : Edge-case-hunter / Verification-gap

- **Occultation d'un constat bloquant de la revue de spec (Front matter)**
  - **Localisation** : `_bmad-output/implementation-artifacts/10-3-education-certification-and-languages-content.md` (Section Triage de la revue de spec, ligne 93)
  - **Déclencheur** : L'auteur affirme « Aucun constat bloquant. Quatre remarques non bloquantes », alors que le rapport de spec intégré juste au-dessus classe explicitement deux constats comme `BLOQUANT` (dont celui sur l'ordre de tri et les champs obligatoires du front matter). Ce point a été totalement ignoré lors de l'implémentation, aucune clé attendue par le gabarit 5.3 n'a été documentée ou auditée.
  - **Garde-fou** : Reprendre le rapport de spec avec honnêteté. Vérifier le gabarit de la story 5.3, documenter les clés requises dans l'epic ou la story, et s'assurer que les fichiers créés s'y conforment (ex: `period`, `institution`, `level` systématiquement présents ou optionnels ?) pour éviter toute régression d'affichage.
  - **Conséquence** : Risque de casse silencieuse du rendu ou du tri aléatoire car le contrat de données avec le gabarit 5.3 n'a pas été validé. Le triage mensonger donne un faux sentiment de sécurité.
  - **Classement** : BLOQUANT

###### Couche propre au projet

- **Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée**
  - **Localisation** : `epics.md` et fichiers Markdown générés
  - **Déclencheur** : Bien que l'affichage soit déclaré comme fonctionnel par le développeur et les contrôles passés, l'évitement délibéré du constat bloquant sur le schéma des données vide l'intention de garantir une intégration de contenu pérenne. L'absence de vérification stricte face au gabarit 5.3 rend l'implémentation potentiellement incomplète.
  - **Garde-fou** : Répondre à la question de la revue de spec sur les clés de front matter et compléter l'implémentation en conséquence.
  - **Conséquence** : Une implémentation fragile qui satisfait la forme des critères de l'epic mais échoue à valider l'intégrité systémique demandée par la revue préparatoire.
  - **Classement** : BLOQUANT

- **Cohérence avec AGENTS.md et les décisions d'architecture (Mise à jour de la spec)**
  - **Localisation** : `epics.md` (Lignes 158-174)
  - **Déclencheur** : L'auteur a mis à jour les critères d'acceptation de l'epic dans la PR même, afin d'y intégrer les retours de la revue de spec (énumération explicite de C5 et C24, procédure de contrôle pour `check-private.sh`, et validation asynchrone des identifiants). Ceci est une excellente application de la Règle 8 (mettre la spec à jour quand l'approche se précise) et de la Règle 4 (ne pas bloquer l'auto-fusion).
  - **Garde-fou** : Aucune action requise.
  - **Conséquence** : L'epic reste la source de vérité, le processus de validation asynchrone par Arnaud est respecté.
  - **Classement** : NON BLOQUANT

- **Aucune donnée privée, aucun nom d'hôte ni secret n'est commité**
  - **Localisation** : `content/education/` et hook `check-private.sh`
  - **Déclencheur** : Le seul élément géographique ajouté est la ville de l'IUT (Grenoble), ce qui est une information publique normale de CV, contrairement à la ville de résidence. L'auteur a exécuté le script `check-private.sh staged` qui n'a retourné aucun avertissement. Aucun secret n'est présent.
  - **Garde-fou** : Aucune action requise.
  - **Conséquence** : Le périmètre de confidentialité public/privé (NFR-9) est intact.
  - **Classement** : NON BLOQUANT

- **Concordance skill, procédure et script / Gestion des erreurs shell**
  - **Localisation** : L'ensemble du patch `REVIEW-DIFF.patch`
  - **Déclencheur** : Le changement n'implique aucune modification ou création de script shell, de procédure markdown ou de skill BMAD.
  - **Garde-fou** : N/A
  - **Conséquence** : N/A
  - **Classement** : NON BLOQUANT

VERDICT: BLOQUANT — Le triage occulte sciemment un constat bloquant de la revue de spec pour esquiver la validation des champs front matter attendus par le gabarit 5.3, menaçant la stabilité de l'affichage et vidant l'intention d'une intégration robuste.

### 24/09/2026 — `a0c16b0` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 110. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 94b3367521bccc768c0358d4

#### Rapport de revue BMAD

##### Lentille : Edge-case-hunter
Le changement consiste exclusivement en l'ajout de fichiers de contenu (Markdown statique avec données YAML en front matter) et en la mise à jour de la documentation de suivi et de spécification (`sprint-status.yaml`, `epics.md`, et le fichier de story). Il n'introduit aucune nouvelle logique, condition, ou branche d'exécution dans la base de code. 
*Aucun constat.*

##### Lentille : Verification-gap
Le changement est strictement non-comportemental. Aucune logique déterministe modifiant les retours de fonctions, le flux de l'application ou l'émission de requêtes n'est modifiée ou ajoutée. Le contrat de données (front matter) est déjà couvert par les scripts de CI existants (`check.sh`, contrôle C19).
*No verification gaps found.*

#### Couche propre au projet

- **Critères d'acceptation satisfaits** : NON BLOQUANT — L'intention des critères d'acceptation est parfaitement respectée et même renforcée. La conformité avec le contrat AD-18 (qui requiert au minimum `kind`, `title`, `order`, et `draft`) est validée, l'unicité de `order` par type (`kind`) est respectée, et les textes anglais et français sont rigoureusement extraits du CV source.
- **Données privées et secrets** : NON BLOQUANT — Aucun secret, ni nom d'hôte ou donnée sensible n'est commité. La mention "IUT2 Grenoble" relève du domaine public et professionnel tel qu'attendu d'un CV en ligne, respectant ainsi les contraintes de filtrage du projet.
- **Concordance skill, procédure et script** : NON BLOQUANT — Le patch ne modifie ni ne crée aucun script, procédure markdown ou skill BMAD. 
- **Cohérence avec AGENTS.md et décisions d'architecture** : NON BLOQUANT — L'implémentation illustre une excellente application des règles de gouvernance du projet. La mise à jour de la spec dans `epics.md` en cours de story (pour éviter l'auto-contradiction et appliquer le DRY sur la liste des clés AD-18) démontre un suivi rigoureux des règles 8 et 12. Le cycle de statut de `sprint-status.yaml` et de la story (passés à `review`) est parfaitement aligné avec la règle 4 (Merge gates).
- **Gestion des erreurs shell** : NON BLOQUANT — Aucune commande shell ou script bash n'est impacté par ce changement.

VERDICT: NON BLOQUANT — aucune

## Reporté

### Triage de la revue de spec, 24/09/2026

**Correction du 24/09/2026, après la revue de code.** Ce triage affirmait d'abord « Aucun constat
bloquant. Quatre remarques non bloquantes ». **C'était faux** : le rapport ci-dessus en porte **deux**,
classés BLOQUANT. Je ne les avais pas lus — la sortie de la revue était passée par un `tail -40`, et
j'ai caractérisé un rapport dont je n'avais vu que la fin. La revue de code l'a relevé, et elle a eu
raison de bloquer. Les deux sont traités ci-dessous.

**B1 — la spec ne nomme pas les clés de front matter attendues par le gabarit de la story 5.3.**
Fondé sur la spec. La conséquence redoutée — « un ordre aléatoire » — n'était en revanche pas
atteignable : **C19 garde déjà l'unicité de `order` par `kind`**, ce qu'un essai montre. Deux langues
mises au même rang donnent :

```
C19 : order 1 déjà pris pour le kind « language » par education/education-english.fr.md, education/education-french.fr.md
```

L'implémentation était donc juste — le gabarit avait été lu avant d'écrire, et le rendu vérifié dans
les deux langues — mais la spec taisait où vit le contrat. Un critère y renvoie désormais **à AD-18**,
sans recopier la liste : une liste recopiée diverge, et c'est exactement le point 19.

**B2 — « identifiants confirmés par Arnaud » contre la règle d'auto-fusion.** Fondé, et **déjà
corrigé** : la case dit maintenant qu'ils lui sont soumis dans la PR sans bloquer la fusion, un
identifiant de formation se renommant tant qu'aucun contenu n'y renvoie. Je l'avais traité en le
croyant non bloquant, parce que la section « À trancher » le reprenait — le fond était bon, le compte
était faux.

**La leçon, et elle a servi deux fois aujourd'hui.** J'ai lu ce rapport par sa fin, puis j'ai décrit
son ensemble. La même faute avait tronqué le corps d'un rapport de revue quelques heures plus tôt sur
la PR n° 107. **Un rapport dont on n'a lu que la queue ne se caractérise pas** : on le compte, ou on
se tait. Le décompte tient en une commande — `grep -c BLOQUANT` — et il aurait suffi.

Les quatre remarques non bloquantes, elles, étaient bien justes et sont intégrées :

- **« C3 et C19 » était limitatif.** Du texte intégré met en jeu C5 (aucun `[TODO` publié) et C24
  (typographie française) autant que les deux clés citées. Le critère demande maintenant que **tous**
  les contrôles bloquants passent, en les nommant.
- **Le risque qu'une donnée du CV coïncide avec un motif interdit** — le nom ou la ville d'un
  établissement. Un critère demande désormais `check-private.sh staged` avant de conclure, en disant
  pourquoi : c'est le garde-fou qui le verra, jamais une relecture à l'œil.
- **Le format de la source n'était pas dit.** Il l'est : les PDF du CV, lus sur place, rien fourni à
  part.
- **La confirmation des identifiants par Arnaud** pouvait se lire comme un verrou de fusion. Elle est
  reformulée : ils lui sont soumis dans la PR et ne bloquent pas, **un identifiant de formation se
  renommant tant qu'aucun contenu n'y renvoie** — contrairement à ceux des postes, qu'AD-18 fige
  précisément parce qu'un cas les cite.

### Ce qui a été écrit

Huit fichiers, quatre entrées × deux langues, toutes tirées du CV et rien d'autre. La certification
Claude que la page « À propos » annonce **n'y figure pas** : elle n'est pas dans le CV, et le critère
dit « chaque donnée figure dans le CV ». Elle entrera le jour où le CV la portera.

| Identifiant | `kind` | FR | EN |
| --- | --- | --- | --- |
| `education-dut-informatique` | education | DUT Informatique · IUT2 Grenoble · 2008 | DUT in Computer Science · IUT2 Grenoble, France · 2008 |
| `education-zend-certified-engineer` | certification | Zend Certified Engineer | Zend Certified Engineer |
| `education-french` | language | Français · langue maternelle | French · native |
| `education-english` | language | Anglais · professionnel | English · full professional |

L'anglais suit `cv-en.pdf` mot pour mot, y compris « full professional » et la précision « France »
après l'IUT, que la version française n'a pas — le CV anglais la porte pour un lecteur qui ne situe
pas Grenoble.

### Vérifications

- Bloc rendu dans les deux langues, **après « En parallèle »** : positions mesurées dans la sortie,
  parcours 2577, parallèle 7905, formation 8809.
- `scripts/ci/checks-job.sh` : 554 cas, 9 contrôles, verts.
- `scripts/check-private.sh staged` : rien. Aucun nom d'établissement ne coïncide avec un motif.
