# Story 5.2 : CV home page template

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 5.2.

## Revue de spec

### 21/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `d9b140b`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 16fbab37eb5bcd2c82297942

Voici le rapport de revue de la spécification de la story 5.2 (gabarit de la page d'accueil), réalisé selon le skill `bmad-review`.

##### 🛡️ Lentille Adversarial & Edge-Case Hunter

* **Ancres des postes manquantes pour le lien de retour (AD-18)**
  * *Condition / Problème :* AD-18 spécifie que les postes doivent avoir une ancre `#position-<id>` pour que le lien « Retour au parcours » des pages de cas (FR-15) fonctionne.
  * *Garde / Correction :* Spécifier l'ajout de l'attribut `id` (par ex. `id="{{ .File.TranslationBaseName }}"`) sur le conteneur de chaque poste.
  * *Conséquence :* En l'état, les liens de retour pointeront vers le haut de l'accueil sans faire défiler jusqu'au poste concerné.

* **Marqueurs de brouillon absents (AD-5)**
  * *Condition / Problème :* En environnement de travail, AD-5 exige un marqueur « Brouillon » devant la société de chaque poste en brouillon et devant le titre des cas en brouillon.
  * *Garde / Correction :* Ajouter au gabarit la logique d'affichage conditionnel du partial/marqueur pour la société du poste et pour chaque lien de cas listé.
  * *Conséquence :* Perte de visibilité sur l'état de brouillon des contenus lors de la prévisualisation (rendu de travail).

* **Poste ne contenant que des cas en brouillon**
  * *Condition / Problème :* Si un poste a des cas rattachés, mais qu'ils sont tous en `draft: true`, aucun ne sera rendu en production.
  * *Garde / Correction :* Préciser que la condition « un poste avec cas publiés » doit filtrer les brouillons en production (`where .Pages "Draft" false`), pour retomber proprement sur l'affichage sans zone de cas.
  * *Conséquence :* Affichage d'une zone de cas vide ou d'une barre de révision orpheline en production.

* **Clé de front matter pour le lien externe de la société**
  * *Condition / Problème :* Le critère indique que "le nom de Ton Pote le Geek est un lien vers son site", mais ne précise pas dans quelle clé de front matter ce lien est renseigné.
  * *Garde / Correction :* Définir la clé (ex: `url` ou `external_link`) dans le format du poste pour héberger cette donnée.
  * *Conséquence :* Le développeur risque d'inventer une clé non standard ou d'être bloqué lors de l'intégration du contenu.

* **Bloc de parcours vide**
  * *Condition / Problème :* Aucun poste de la piste `track: parallel` n'est publié.
  * *Garde / Correction :* Préciser que le bloc « En parallèle » et son titre ne s'affichent pas s'il n'y a aucun poste à lister.
  * *Conséquence :* Affichage d'un titre « En parallèle » flottant au-dessus du néant.

##### 🏗️ Lentille Structure (Éditoriale)

* **Hiérarchie sémantique des titres (UX-DR20)**
  * *Condition / Problème :* Le DOM impose un `h1` (ligne d'identité) et un `h3` (société du poste), mais omet de qualifier les titres des blocs ("Parcours", "En parallèle").
  * *Garde / Correction :* Préciser que les libellés des blocs doivent être rendus en `h2` pour conserver un arbre d'accessibilité fluide.
  * *Conséquence :* Saut sémantique (h1 vers h3) violant les bonnes pratiques d'accessibilité WCAG du projet.

* **Sources de données du bloc identité (AD-3, AD-19)**
  * *Condition / Problème :* Les critères stipulent "ligne d'identité, titre du site, pitch", sans rappeler d'où viennent ces données.
  * *Garde / Correction :* Expliciter qu'ils sont tirés du front matter et du corps de `content/_index.{fr,en}.md`, pour s'aligner avec le paradigme (le contenu est une donnée).
  * *Conséquence :* Risque de voir un développeur écrire le texte en dur dans le fichier `layouts/home.html`.

##### ✍️ Lentille Prose (Éditoriale)

* **Clarté du rendu du poste sans cas**
  * *Analyse :* Le critère "il montre ses champs puis son corps éventuel, sans zone de cas, barre de révision, tiret ni mention d'absence" est irréprochable.
  * *Conclusion :* Aucun écart. La formulation lève toutes les ambiguïtés sur la façon dont le DOM doit réagir à l'absence de cas.

---

##### À trancher avant d'implémenter

- **Hiérarchie sémantique :** Valides-tu que les titres de blocs ("Parcours", "En parallèle") doivent être des `h2` pour faire le pont entre l'identité (`h1`) et les sociétés (`h3`) ?
- **Clé du lien externe :** Quelle clé de front matter doit-on utiliser pour renseigner l'URL d'un poste externe (ex: `external_url` pour Ton Pote le Geek) ?
- **ID des postes :** Confirmer l'ajout de l'attribut `id` (`#position-<id>`) sur les postes pour honorer AD-18.
- **Marqueurs de brouillon :** Valider que le gabarit prendra bien en charge l'affichage des marqueurs de brouillon pour la société et les cas en environnement de travail (AD-5).

### Tri des constats — 21/09/2026

Trois des cinq constats visent du code **qui existe déjà**, écrit par la story 2.7. Vérifiés un par un dans `layouts/_partials/position.html` et `layouts/home.html`.

| Constat | Décision | Raison |
|---|---|---|
| Ancre `#position-<id>` manquante | **rejeté, déjà fait** | `position.html:14` pose `id="{{ $key }}"` sur chaque poste. AD-18 le décrit, la story 2.7 l'a écrit, et C12 vérifie ces ancres. |
| Marqueurs de brouillon absents | **rejeté, déjà fait** | `position.html:16` et `:21` appellent `draft-marker.html` pour la société et pour chaque cas. |
| Titres de blocs à passer en `h2` | **rejeté, déjà fait** | `home.html:14` rend `block_career` en `h2`. La hiérarchie est bien `h1` → `h2` → `h3`. |
| Poste dont tous les cas sont en brouillon | **rejeté, déjà couvert** | `--buildDrafts` n'existe que dans le rendu de travail (`scripts/build.sh:50`). En production ces cas ne sont pas dans `site.RegularPages`, `$cases` est vide, et le `{{ else }}` rend le corps du poste — exactement le comportement voulu. Aucune barre de révision orpheline n'est possible. |
| Le bloc « En parallèle » s'afficherait vide | **retenu** | Un titre au-dessus du néant. Le bloc entier est conditionné à l'existence d'au moins un poste `track: parallel`, comme l'est déjà « Parcours ». |
| Clé de front matter pour le lien externe | **retenu** | Vrai trou : `DESIGN.md` § cv-position veut que le nom de Ton Pote le Geek soit un lien, et AD-18 ne prévoit aucune clé d'URL. Tranché par Arnaud ci-dessous. |

**Les deux questions de la story sont sans objet**, toutes deux déjà tranchées ailleurs : `cases_of_position` l'a été le 17/09/2026 (story 2.7 ; `EXPERIENCE.md` le note « décidé »), et `DESIGN.md` § cv-position fixe le format de `via` — « prestation Modis » en français, *via Modis* en anglais, donc un libellé i18n autour de la valeur. `block_parallel` est décidé de même (« En parallèle » / *Alongside*).

### Décision d'Arnaud — 21/09/2026

**Une clé `url` sur le poste**, facultative et non traduite, comme `via`. La règle devient générale : *un poste qui porte une `url` transforme le nom de sa société en lien*. C'est la seule option qui n'inscrive pas « Ton Pote le Geek » dans un gabarit générique ni une donnée de contenu dans la configuration.

Elle entre donc dans AD-18 (front matter d'un poste), dans la liste des clés non traduites de C3, et dans les valeurs que C19 contrôle.

## Mise en œuvre

### La clé s'appelle `company_url`, pas `url`

**Hugo réserve `url` en front matter** : c'est la clé qui force l'adresse d'une page, et elle refuse une valeur à protocole. Le build échoue net :

```
URLs with protocol (http*) not supported: "https://exemple.invalid/"
```

Constaté au premier build après avoir écrit le contenu d'essai. La décision d'Arnaud tient entièrement — une clé générique, facultative, non traduite, sur le poste —, seul son nom change pour cette raison technique. AD-18, C3 (`parity.sh`) et C19 (`content.sh`) portent `company_url`, et un cas de test refuse tout retour de `.Params.url` dans le gabarit, pour que la découverte ne se reperde pas.

### Ce que le gabarit fait

`position.html` sépare la période du reste : elle est le premier enfant de l'article et porte `in-margin`, le reste vit dans un `cv-position__body`. Les détails suivent l'ordre qu'impose `DESIGN.md` — `location`, puis le libellé du cadre, puis `via` par le patron i18n `via_label` (« prestation Modis » / *via Modis*).

`home.html` conditionne **chaque** bloc à l'existence d'au moins un poste de sa piste : ni « Parcours » ni « En parallèle » n'affiche un titre au-dessus du néant. Vérifié en retirant le poste parallèle du contenu d'essai — le bloc et son titre disparaissent tous les deux.

### L'alignement des colonnes

Un poste doit poser sa période dans la colonne de marge **de la page**, alors qu'il est imbriqué dans sa section : la grille de la page ne l'atteint pas. Le bloc prend donc toute la largeur du cadre (`grid-column: 1 / -1`) et chaque poste redéclare la même grille marge | texte. Les largeurs venant des mêmes tokens, les colonnes tombent au même endroit.

Un `display: contents` sur le poste aurait aplati la hiérarchie et permis à ses deux morceaux de se désolidariser quand les postes s'empilent ; il pose en outre des problèmes d'arbre d'accessibilité. Écarté.

### Vérification de comportement

Servi et mesuré au navigateur, sur un contenu d'essai local jamais commité (la story le prescrit) : un poste avec cas, un poste sans cas et avec corps, un poste `parallel` avec `company_url`, et un pitch de trois phrases.

| Ce qui est exercé | Observé |
|---|---|
| **FR-37, 390 × 844 sans défiler** | identité à 98 px, titre, « Basé en France », pitch 227 → 333, titre « Parcours », **premier poste entier 415 → 578 avec son lien de cas** |
| Plan des titres | `h1` → `h2` → `h3` → `h3` → `h2` → `h3`, aucun saut |
| Colonnes à 1024 px | période 57 → 273 alignée à droite, identité / titre de bloc / société tous à 313 px — la même colonne de texte |
| Colonnes à 1440 px | période 125 → 341, texte à 381 px ; le titre de bloc borné sur la mesure |
| Poste sans cas | corps affiché, **aucune** barre de révision, aucun tiret, aucune mention d'absence |
| Barre de révision | 2 px `accent`, sur toute la liste et non sur chaque cas |
| `company_url` | le nom « Ton Pote le Geek » est un lien souligné vers l'adresse donnée |
| Bloc « En parallèle » vide | le bloc **et son titre** disparaissent |
| 320 px, deux modes | aucun défilement horizontal, aucune paire sous 4,5:1, aucune cible sous 24 px |

Un écart trouvé et corrigé : à `lg`, le titre de bloc s'étendait jusqu'à 1301 px, dans la colonne de note, alors que le texte s'arrête à 1021. Borné sur la mesure — sans quoi `text-wrap: balance` raisonnait sur une largeur que le texte n'occupe jamais.

### Cas de test

Quatre cas nouveaux : C19 sur `company_url` (adresse absolue exigée, vide et `http://` refusés, absence tolérée), la garde contre `.Params.url`, les trois nouvelles clés i18n dans les deux langues, et la double condition des blocs de l'accueil.

## Revue du code

### 21/09/2026 — `17328d9` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 67. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 6c62eaa557dfe8420ac86ec1

Voici le rapport de relecture de la PR #67 (Story 5.2 : CV home page template), basé sur le diff fourni et les critères du projet.

##### 🛡️ Lentille Edge-Case-Hunter

* **Absence potentielle de la clé `identity` et suppression du `<h1>`**
  * *Constat* : Dans le gabarit `layouts/home.html`, la balise `<h1>` contenant le nom est conditionnée à la présence de la clé `identity` (`{{ with .Params.identity }}`). Si cette clé n'était pas renseignée dans `content/_index.md`, la page d'accueil n'aurait aucun titre de niveau 1. Cela ferait échouer silencieusement l'affichage attendu, mais serait intercepté par le contrôle d'accessibilité C11.
  NON BLOQUANT

##### 🔍 Lentille Verification-Gap

* **Validation partielle de la valeur `company_url`**
  * *Constat* : Le filtre ajouté au script `scripts/checks/content.sh` vérifie que `company_url` (si elle n'est pas vide) commence par `https://`. Il ne vérifie cependant pas la présence d'un nom de domaine qualifié après le protocole (une valeur comme `"https://"` seule validerait le test). Étant donné que le contenu est saisi manuellement et que les tests couvrent déjà l'essentiel des erreurs de saisie (HTTP sans TLS, adresses relatives), ce cas reste théorique.
  NON BLOQUANT

##### 📋 Couche Projet Spécifique (Site eleyone.fr)

* **Critères d'acceptation de la story**
  * *Constat* : Les critères de la story 5.2 sont pleinement satisfaits. Le DOM de l'accueil respecte la hiérarchie stricte (`h1` puis `h2` puis `h3`). La disparition d'un bloc de parcours si aucun poste n'est trouvé évite de polluer l'interface avec des titres vides. Les fallbacks (retomber sur le corps du poste si aucun cas n'existe) sont correctement gérés dans `layouts/_partials/position.html`. Le marqueur de brouillon s'affiche bien dans l'environnement de travail.
  NON BLOQUANT

* **Garde-fou (Fuites de données et de secrets)**
  * *Constat* : Aucune donnée privée, aucun secret et aucune adresse IP de serveur ne se trouvent dans le code ajouté. Le fichier de suivi, les tests et le document d'architecture manipulent l'URL `exemple.invalid`, conformément aux bonnes pratiques. 
  NON BLOQUANT

* **Cohérence avec l'architecture et les procédures (AGENTS.md, ARCHITECTURE-SPINE.md)**
  * *Constat* : L'ajout de la clé front-matter `company_url` est proprement documenté et justifié dans l'architecture (AD-18). La mise à jour des scripts de contrôle `content.sh` (C19) et `parity.sh` (C3) est en parfaite adéquation avec la documentation (mise à jour de `docs/procedures/check.md`).
  NON BLOQUANT

* **Robustesse des scripts Shell (`set -euo pipefail`)**
  * *Constat* : Les modifications apportées aux scripts Shell s'appuient principalement sur des déclarations de tableaux et des filtres JQ robustes. Aucune commande risquant d'échouer silencieusement ou de masquer un code d'erreur sous `set -e` n'a été ajoutée. Les tests bash ajoutés dans `scripts/tests/test-content.sh` vérifient exhaustivement la nouveauté sans introduire de faux positifs.
  NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

#### Décisions sur les deux constats — 21/09/2026

**`identity` absente ferait disparaître le `h1`** — **retenu tel quel, déjà couvert.** Le relecteur le dit lui-même : C11 exige exactement un `h1` et refuserait la page. La clé est par ailleurs dans les deux fichiers `_index` et C3 la vérifie en parité. Ajouter une garde dans le gabarit ne ferait que déplacer un échec déjà bruyant.

**`https://` seul passerait C19** — **retenu, corrigé.** Le test du préfixe ne demandait pas d'hôte. Le contrôle exige désormais `^https://[^/?#\s]+`, et un cas de test refuse le protocole nu. Théorique, mais la garde existe pour attraper une faute de frappe : elle doit la reconnaître.

### 21/09/2026 — `397f303` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 67. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 2667464f47aac17dcc94b853

##### Rapport de revue BMAD

###### 🛡️ Lentille : Edge-Case Hunter

* **Type inattendu pour la clé `company_url`**
  * *Emplacement :* `scripts/checks/content.sh:255-259`
  * *Condition de déclenchement :* La clé `company_url` est présente dans le front matter mais avec un type non-chaîne (par exemple un booléen `true` ou un entier).
  * *Garde suggérée :* Ajouter une vérification de type `(($url | type == "string") and ($url | test("^https://[^/?#\\s]+")))` ou faire un cast explicite via `tostring`.
  * *Conséquence potentielle :* La fonction `test` lève une erreur sur une entrée non-chaîne, ce qui provoque un arrêt brutal de `jq` sans afficher le retour prévu pour l'erreur C19.

###### 🔍 Lentille : Verification Gap

No verification gaps found.

###### 📋 Couche propre au projet

* NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits (rendu correct du CV et gestion des blocs sans postes) sans vider leur intention (l'ajout de la clé générique `company_url` est préférable au texte "Ton Pote le Geek" codé en dur dans le gabarit).
* NON BLOQUANT : Aucune donnée privée, aucun secret, ni aucun nom d'hôte de production n'est commité ou affiché par les scripts (seul le domaine mocké `exemple.invalid` est utilisé).
* NON BLOQUANT : Les modifications apportées à la procédure dans `docs/procedures/check.md` concordent strictement avec l'évolution des vérifications dans `scripts/checks/content.sh`.
* NON BLOQUANT : L'approche retenue s'inscrit en totale cohérence avec les documents de suivi (`AGENTS.md`) et l'architecture (`ARCHITECTURE-SPINE.md`).
* NON BLOQUANT : Aucune commande n'avale silencieusement des erreurs dans les scripts shell sous `set -euo pipefail` (la typologie problématique relevée plus haut provoque bien un crash explicite interrompant le script avec un code non-nul, et non une anomalie sourde).

VERDICT: NON BLOQUANT — aucune

## Reporté
