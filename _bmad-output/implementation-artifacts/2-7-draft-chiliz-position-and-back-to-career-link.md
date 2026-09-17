# Story 2.7 : Draft Chiliz position and back to career link

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 2.7.

## Revue de spec

### 17/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `67839a5`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9a9a1ff992b06293f807d84c

Voici le rapport de revue de la spécification de la story 2.7, établi en appliquant les lentilles du skill `bmad-review` (Adverse, Structure, Prose) après analyse du document et de son contexte architectural (`AGENTS.md`, `epics.md`, `ARCHITECTURE-SPINE.md`).

##### 🔍 Lentille : Adverse (Adversarial)

- **Emplacement :** Prérequis de contenu
  - **Problème ou condition :** La spécification indique que la période du poste reste en `[TODO: période]`. Toutefois, elle ne mentionne pas les autres champs obligatoires d'un poste selon FR-2 (société, intitulé, cadre/ville). 
  - **Correction ou garde-fou :** Préciser explicitement l'état attendu de ces champs dans le front-matter du poste `position-chiliz` (données réelles ou `[TODO: ...]`).
  - **Conséquence potentielle :** Échec lors des contrôles de forme (AD-10) si les champs sont absents, ou bien intégration prématurée de données privées/non validées par le développeur.

- **Emplacement :** Critères d'acceptation, 3e bloc (Marqueur « Brouillon »)
  - **Problème ou condition :** Le critère exige l'affichage du marqueur « Brouillon » pour le cas 02. Mais le poste Chiliz lui-même est configuré comme un brouillon. La spec omet de préciser s'il doit y avoir un marqueur devant le titre du poste sur l'accueil.
  - **Correction ou garde-fou :** Clarifier si le composant `_partials/position.html` doit également rendre ce marqueur pour le poste lui-même.
  - **Conséquence potentielle :** Incohérence visuelle en rendu de travail ; un poste non publié pourrait sembler publié si seul son contenu (les cas) porte l'indication d'ébauche.

- **Emplacement :** Critères d'acceptation, 5e bloc (Corps du poste)
  - **Problème ou condition :** L'affichage du corps du poste (`.Content`) n'est testé que dans la situation d'un poste *sans cas*. FR-2 exige que le corps soit affiché « seulement sans cas ». Le comportement n'est pas testé pour le poste Chiliz, qui, lui, possède des cas.
  - **Correction ou garde-fou :** Ajouter un critère pour s'assurer que, si un poste possède des cas (comme c'est le cas pour Chiliz), son `.Content` est strictement masqué.
  - **Conséquence potentielle :** Le texte éventuel du corps du poste fuiterait au-dessus des cas si la règle FR-2 n'est pas appliquée rigoureusement dans le gabarit.

- **Emplacement :** Critères d'acceptation, 2e bloc (Lien de retour)
  - **Problème ou condition :** Il est demandé de suivre le lien « Retour au parcours » (`back_to_career`), mais son positionnement visuel ou DOM (haut du cas, bas de la page, à l'intérieur de `_partials/case.html`) n'est pas défini.
  - **Correction ou garde-fou :** Adosser l'emplacement de ce lien aux exigences UX existantes ou le décrire explicitement.
  - **Conséquence potentielle :** Le développeur risque d'inventer une structure ou de le placer à un endroit non conforme à l'expérience utilisateur voulue.

##### 🔍 Lentille : Structure

- **Emplacement :** Périmètre
  - **Problème ou condition :** Le fichier `content/career/_index.{fr,en}.md` est annoté `(jamais rendu)`.
  - **Correction ou garde-fou :** Confirmer s'il s'agit du même mécanisme que pour la page des cas (utilisation du front-matter `build: {render: never}`) afin de désactiver le rendu de la taxonomie ou section `/career/` sans casser les enfants.
  - **Conséquence potentielle :** Une section listant les postes pourrait être générée à l'insu de l'architecture si la configuration est mal reportée.

##### 🔍 Lentille : Prose (Rédaction)

- **Emplacement :** L'ensemble du document
  - **Problème ou condition :** Le texte est très clair, concis, bien formulé, et le vocabulaire est strictement aligné sur les concepts de l'architecture (`FR-2`, `rendu de travail`, `AD-4`, `case-url.html`). Il n'y a aucune ambiguïté de langage.
  - **Correction ou garde-fou :** Aucune modification rédactionnelle requise.
  - **Conséquence potentielle :** La compréhension des dépendances et du flux par le développeur sera fluide.

---

##### À trancher avant d'implémenter

- **Champs du poste :** Outre la période en `[TODO: période]`, les autres champs requis (intitulé, société, cadre/ville) du poste `position-chiliz` doivent-ils contenir de réelles données ou des marqueurs `[TODO: ...]` pour le moment ?
- **Marqueur Brouillon sur le poste :** Le poste `position-chiliz` étant en brouillon, doit-il lui-même afficher le marqueur « Brouillon » sur l'accueil de travail, en plus des marqueurs propres au cas 02 ?
- **Masquage du corps de texte :** Faut-il ajouter un critère d'acceptation s'assurant que le `.Content` du poste est bien masqué dès lors qu'il contient des cas (règle FR-2) ?
- **Lien de retour :** À quel endroit précis (en haut, en bas) le lien « Retour au parcours » doit-il être inséré dans l'interface du cas ?

### Triage des constats (17/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — champs du poste autres que la période | **retenu**, question à Arnaud | AD-18 fixe les clés : `company` « Chiliz » et `setup: employee` sont déjà dans le cas 02 ; `track: main`, `order: 1`. Le `role` d'un poste n'est écrit nulle part dans le dépôt (celui du cas 02 décrit la mission, pas l'intitulé du poste) : question. `location` est facultatif dès que `setup` existe : omis, pour ne rien inventer |
| A2 — marqueur « Brouillon » sur le poste lui-même | **question à Arnaud** | AD-5 ne le pose que devant un **cas** en brouillon (page cas, section de groupe, lien sous le poste). En rendu de travail, un poste en brouillon ressemble donc à un poste publié |
| A3 — corps masqué pour un poste qui a des cas | **retenu** | règle d'AD-18 et de `DESIGN.md` (`cv-position`) : critère ajouté, vérifié par une copie locale du poste Chiliz avec un corps |
| A4 — emplacement de « Retour au parcours » | **retenu**, question à Arnaud | `EXPERIENCE.md` (premier écran) et `DESIGN.md` (« texte, en haut ») le placent **en haut de page**, avant « Chiliz » : un seul lien par page, pas un par section, alors que le critère et AD-18 parlent de « la section du cas 02 » |
| S1 — `content/career/_index` « jamais rendu » | **retenu** | AD-18 donne le réglage exact : `build: {render: never, list: never}` et `cascade: [{build: {render: never, list: always}, target: {kind: page}}]`. Le critère le nomme, et vérifie qu'aucune page `/career/` ni poste n'est construit |
| Prose | sans objet | aucun changement demandé |

Constat de l'auteur, hors rapport : le nom accessible de la liste des cas d'un poste (`cases_of_position`, « Cas qui prouvent ce poste » / « Cases behind this role ») est « à valider par Arnaud » dans `EXPERIENCE.md`. **Question à Arnaud.** L'accueil complet (ordre des blocs, « En parallèle », barre de révision, premier écran) reste à la story 5.2 : cette story se limite au bloc « Parcours ».

### Réponses d'Arnaud (17/09/2026)

- **Rôle du poste Chiliz** : « Développeur backend sénior » ; en anglais « Senior backend developer ».
- **Marqueur sur le poste** : oui, le même marqueur précède la société d'un poste en brouillon. AD-5 et `EXPERIENCE.md` (états) sont complétés.
- **Retour au parcours** : une fois, en haut de page, avant le `h1`. AD-18 est précisé.
- **`cases_of_position`** : la proposition d'`EXPERIENCE.md`, qui passe en « décidé ».

La story est réécrite dans `epics.md` en conséquence.

## Ce qui est livré

- `content/career/_index.{fr,en}.md` : section jamais rendue ni listée, cascade qui garde les postes listés sans les rendre (AD-18).
- `content/career/position-chiliz.{fr,en}.md` : poste en brouillon, période `[TODO: période]`, rôle donné par Arnaud, cadre `employee`, sans `location` ni corps.
- `layouts/_partials/position.html` : période, société en `h3`, rôle puis lieu et cadre s'ils existent ; cas retrouvés par leur clé `position`, triés par `number`, dans une liste nommée `cases_of_position` ; corps rendu seulement sans cas.
- `layouts/_partials/case-url.html` et `career-url.html` : seules constructions des liens vers un cas et vers le poste.
- `layouts/_partials/draft-marker.html` : marqueur derrière `hugo.IsProduction`, posé devant la société d'un poste, le titre d'un cas sous son poste et le titre d'un cas sur la page de groupe.
- `layouts/home.html` : le contenu passe dans un `main`, suivi du bloc « Parcours » (postes `main` par `order`), absent s'il n'y a aucun poste.
- `layouts/cases/section.html` : « Retour au parcours » une fois, avant le `h1`.
- `i18n/` : `block_career`, `case_number`, `cases_of_position`, `back_to_career`, `draft_marker`.

Aucun CSS, aucun JavaScript. Le `via` d'un poste et le reste de l'accueil restent à la story 5.2.

### Essais, tous avec des copies locales défaites ensuite

| Essai | Constat |
| --- | --- |
| rendu de travail, tel que commité | accueil FR et EN : bloc « Parcours » / « Experience », poste `id="position-chiliz"`, « Brouillon » devant « Chiliz », « Développeur backend sénior · Salarié », « Cas 02 », marqueur, lien `/cas/chiliz/#case-02` (`/en/cases/chiliz/#case-02`), aucun « En bref ». Page Chiliz : « Retour au parcours » vers `/#position-chiliz` (`/en/#position-chiliz`) avant le `h1`, marqueur devant le titre du cas, trois emplacements « prévus » (démonstration de WS-2). Aucun dossier `career` |
| corps ajouté au poste Chiliz, rendu de travail | le corps n'apparaît pas sur l'accueil : le poste a un cas |
| build de production, tel que commité | quatre pages seulement ; aucune occurrence de `draft-marker`, de `position-chiliz` ni de Chiliz dans `public/` ; pas de bloc « Parcours » |
| poste `position-essai` publié sans cas, avec corps, build de production | FR et EN : bloc « Parcours », période, société, « Rôle essai fr · Full remote · Freelance », puis le corps ; ni liste de cas ni mention d'absence ; aucune page de poste construite |

Le corps d'essai a été retiré du poste Chiliz depuis une copie faite avant l'essai, et les fichiers `position-essai`, non suivis, supprimés. Les deux builds, refaits, sortent sans avertissement ; les tests des scripts passent (97 cas).

Remarque pour Arnaud : le titre de l'accueil écrit « Développeur backend senior », sans accent, alors que le rôle du poste, donné le 17/09/2026, écrit « sénior ». Laissé tel quel : l'harmonisation est à trancher par lui.

## Revue du code

### 17/09/2026 — `78627ec` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 32. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a819610e8950eb7fad0bc4a0

##### Revue BMAD

###### 🔍 Lentille : edge-case-hunter (Cas particuliers)

- **Emplacement :** `layouts/_partials/case-url.html`
  - **Condition de déclenchement :** Rendu de l'URL pour un cas qui n'appartient à aucun groupe.
  - **Garde-fou :** La condition `isset .Params "group"` gère ce cas limite en retournant l'URL relative native de la page au lieu d'une ancre sur une page de groupe parente inexistante.
  - **Conséquence potentielle :** Les liens restent fonctionnels, qu'un cas soit regroupé ou indépendant.

- **Emplacement :** `layouts/_partials/position.html`
  - **Condition de déclenchement :** Affichage d'un poste qui n'a aucun cas associé publié.
  - **Garde-fou :** Le bloc `{{- else }}` s'assure de basculer sur l'affichage du `.Content` du poste.
  - **Conséquence potentielle :** Aucun élément visuel vide (liste sans puces) n'est affiché. Le comportement de fallback gère gracieusement le vide.

###### 🔍 Lentille : verification-gap (Faille de vérification)

- **Emplacement :** `layouts/home.html` et rendu de travail.
  - **Condition de déclenchement :** Fuite éventuelle du contenu d'un brouillon dans le build de production.
  - **Garde-fou :** Les tests décrits dans l'artefact d'implémentation (section "Essais") couvrent rigoureusement les différentes permutations : rendu de travail avec brouillon, ajout de corps sur un brouillon, build de production avec brouillon, et build de production avec un poste publié fictif sans cas.
  - **Conséquence potentielle :** La disparition du contenu brouillon et des marqueurs `draft-marker` est avérée ; aucune faille dans les essais n'est à signaler.

##### Revue du projet

NON BLOQUANT : les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée.
NON BLOQUANT : aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
NON BLOQUANT : skill, procédure et script concordent (aucun n'est modifié par ce diff).
NON BLOQUANT : le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-18, AD-5).
NON BLOQUANT : dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail (aucun script shell modifié).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 32 (`78627ec`, verdict `pass`) : aucun constat à traiter. Les deux entrées edge-case-hunter et l'entrée verification-gap décrivent des garde-fous déjà en place (cas sans groupe, poste sans cas, essais de production) ; la couche projet ne fait que confirmer. Rien n'est reporté.

## Reporté
