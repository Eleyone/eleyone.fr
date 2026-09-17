# Story 2.5 : Chiliz page, case partial and planned material

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 2.5.

## Revue de spec

### 17/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `8f45f9a`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ce2a3948101c9b965540b33b

### Rapport de revue de spécification (Story 2.5)

#### Lentille : Adversarial

**1. Contradiction sur le nombre d'emplacements dans le pilote**
* **Localisation** : `Critères d'acceptation`, lignes 19 et 31.
* **Condition de déclenchement** : La ligne 19 affirme que "le cas pilote l'appelle six fois", tandis que la ligne 31 vérifie "les trois emplacements du pilote".
* **Garde-fou / Correction** : Aligner le nombre d'emplacements dans le critère de test avec la réalité du fichier pilote (6 ou 3).
* **Conséquence potentielle** : Le test échouera ou ne couvrira pas tous les appels au shortcode, rendant le critère invalide.

**2. Ambiguïté sur l'état "planned" et l'absence de déclaration**
* **Localisation** : `Critères d'acceptation`, ligne 21.
* **Condition de déclenchement** : "(id absent de live_material → errorf, rien en production, encart fixe en rendu de travail)". La parenthèse mélange la gestion de l'absence de l'identifiant (qui doit lever une erreur) avec le comportement d'un élément `planned` dûment déclaré.
* **Garde-fou / Correction** : Séparer la règle d'existence ("un identifiant non déclaré lève une erreur") de la règle d'affichage de l'état `planned` (encart en rendu de travail, rien en production).
* **Conséquence potentielle** : Le développeur risque d'implémenter un comportement où un élément non déclaré est traité de manière silencieuse comme "planned", masquant des oublis d'identifiants.

**3. Manque d'exhaustivité des contraintes AD-6 pour les éléments "ready"**
* **Localisation** : `Critères d'acceptation`, ligne 21.
* **Condition de déclenchement** : Le critère demande l'ajout de "la résolution d'un élément ready par type (diagram, video, snippet, callout, AD-6)", mais ne mentionne pas les contraintes d'implémentation fortes dictées par l'architecture.
* **Garde-fou / Correction** : Expliciter que le rendu doit respecter strictement l'AD-6 pour chaque type (ex : lien `<a href>` sans iframe pour les vidéos, conteneur focalisable avec `tabindex="0"` et nom accessible pour le schéma large).
* **Conséquence potentielle** : Le développeur pourrait utiliser une iframe pour la vidéo ou omettre les attributs d'accessibilité du schéma large.

**4. Extraction implicite du type de contenu**
* **Localisation** : `Critères d'acceptation`, ligne 21.
* **Condition de déclenchement** : La spec demande une résolution "par type" sans préciser comment ce type est détecté, alors que l'AD-6 fixe une nomenclature de préfixes (ex: `diagram-`).
* **Garde-fou / Correction** : Préciser que le shortcode déduit le type de contenu de l'élément à partir du préfixe de son identifiant (kebab-case).
* **Conséquence potentielle** : Une implémentation fragile pourrait tenter de lire un champ "type" supplémentaire dans les métadonnées au lieu d'analyser l'identifiant.

#### Lentille : Structure

**1. Lisibilité de la définition du shortcode**
* **Localisation** : `Critères d'acceptation`, lignes 19 à 22.
* **Condition de déclenchement** : L'explication du comportement attendu du shortcode complet (gestion des états `planned` et `ready`, disparition du garde-fou temporaire) est très dense et compactée en une seule phrase lourde.
* **Garde-fou / Correction** : Utiliser des tirets pour lister distinctement les comportements attendus du shortcode (ID absent, état planned, état ready).
* **Conséquence potentielle** : Perte de temps à décortiquer la phrase lors de l'implémentation et risque d'omettre un cas de figure dans le code.

#### Lentille : Prose

**1. Formulation équivoque du "repli AD-4"**
* **Localisation** : `Critères d'acceptation`, ligne 40.
* **Condition de déclenchement** : "(constat ; s'il échoue, repli d'AD-4 : C12 exclut les pages de groupe sans section)" relève d'une note d'intention conditionnelle ou d'une réflexion plutôt que d'un résultat BDD prescriptif et testable.
* **Garde-fou / Correction** : Formuler comme une affirmation claire sur la conduite à tenir en cas d'échec de la cascade.
* **Conséquence potentielle** : Incertitude du développeur lors du test sur ce qui doit être concrètement implémenté si la condition de repli se présente.

---

#### À trancher avant d'implémenter

* **Nombre d'appels dans le pilote** : La spécification mentionne "six fois" (ligne 19) puis "trois emplacements" (ligne 31). Lequel correspond à la réalité du cas pilote 02 qu'il faut tester ?
* **Détail de la validation AD-6** : Faut-il ajouter explicitement aux critères d'acceptation les règles d'accessibilité (tabindex, lien propre sans iframe) ou le simple renvoi à la mention "AD-6" est-il jugé suffisant pour cadrer le développeur ?
* **Mécanisme du repli AD-4** : Si le constat de la cascade avec un `_index` en brouillon échoue, la présente story doit-elle inclure la modification effective du script de contrôle C12 (qui exclura les pages de groupe sans section), ou cela fera-t-il l'objet d'une correction technique séparée ?

### Triage des constats (17/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — « six fois » contre « trois emplacements » | **retenu** | vérifié dans le pilote : **trois** emplacements par langue, donc **six** appels sur les deux fichiers. Les deux chiffres étaient justes dans des sens différents ; le critère le dira |
| A2 — identifiant non déclaré mêlé à l'état `planned` | **retenu** | deux règles séparées : un `id` absent de `live_material` fait échouer le build ; un élément `planned` **déclaré** s'affiche en encart en travail et ne laisse rien en production |
| A3 — contraintes d'AD-6 non explicitées pour `ready` | **retenu** | les critères nomment ce qui se vérifie : lien `<a href>` sans `iframe` pour une vidéo, conteneur focalisable et nom accessible pour un schéma large, `alt` venant de la `description`, source manquante = build en échec |
| A4 — type déduit du préfixe de l'identifiant | **refusé** | le pilote porte bien un champ `type` (`diagram`, `callout`, `snippet`) et AD-6 résout **par type**. Le préfixe est une règle de nommage, pas la source du type : déduire du préfixe créerait une seconde vérité et casserait au premier identifiant mal nommé |
| S1 — définition du shortcode trop dense | **retenu** | les comportements passent en liste |
| P1 — repli d'AD-4 formulé comme une intention | **retenu** | question à Arnaud, puisque C12 n'existe pas encore |

## Ce qui est livré

| Fichier | Rôle |
| --- | --- |
| `content/cases/chiliz/_index.{fr,en}.md` | la page de groupe : titre « Chiliz », `translationKey: group-chiliz`, brouillon tant que le cas 02 ne l'est pas, cascade ciblée `kind: page` |
| `content/cases/_index.{fr,en}.md` | section technique, jamais rendue — **la cascade posée par la story 2.2 est retirée** (voir ci-dessous) |
| `layouts/cases/section.html` | rend les cas triés par `order`, chacun dans `<section id="<translationKey>">` ; rien à modifier quand un cas s'ajoute |
| `layouts/_partials/case.html` | titre, encart « Contexte mission », encart « En bref », puis le cas complet ; reçoit son niveau de titre |
| `layouts/_shortcodes/live-material.html` | **complété** : résolution par type d'un élément `ready`, garde-fou temporaire retiré |
| `i18n/{fr,en}.yaml` | libellés d'encart, de cadre et du matériel vivant ; aucun mot de contenu dans un gabarit |

### Une anticipation de la story 2.2 qu'il a fallu défaire

La page Chiliz ne sortait pas du build. La cause n'était pas dans cette story : la story 2.2 avait posé sur `content/cases/_index` une cascade `render: never` **visant toutes les sections descendantes**, pour faire taire un avertissement de gabarit manquant. Elle rendait donc la page de groupe invisible. Retirée ici — ces fichiers sont dans le périmètre de cette story —, et remplacée par ce qu'AD-4 demande vraiment : une cascade **sur le `_index` du groupe**, visant les `kind: page`, pour que les cas ne soient pas rendus à leur URL propre tout en restant listés.

C'est la démonstration du coût d'une anticipation : elle débloque un build, et elle se paie deux stories plus loin.

### Essais, tous avec des copies locales défaites ensuite

| Essai | Résultat |
| --- | --- |
| Page Chiliz, rendu de travail, FR et EN | `<h1>Chiliz</h1>`, `<section id="case-02">`, titre du cas, « Contexte mission » / *Engagement context*, « En bref » / *At a glance*, puis le cas |
| Libellés d'encart | Société/Cadre/Rôle/Période/Stack et *Company/Engagement/Role/Period/Stack* ; cadre `employee` → « Salarié » / *Employee* |
| Trois emplacements « prévus », dans les deux langues | encart avec type et description, source jamais cherchée |
| Schéma `ready` large (600 px) | `<figure>` avec classe large, conteneur `tabindex="0"` étiqueté par la description, `<img>` empreinté en 450 × 300 (75 %), lien « Ouvrir en taille réelle » |
| Schéma `ready` étroit (300 px) | dimensions intrinsèques, ni classe large ni conteneur focalisable |
| Vidéo `ready` | `<a href>` vers YouTube avec « (vidéo sur YouTube) », **aucune `iframe`** |
| Extrait et encart `ready` | Markdown rendu dans `<figure>` et `<aside>` |
| Source manquante d'un élément `ready` | build en échec, code 1, fichier attendu nommé |
| Identifiant non déclaré | build en échec, identifiant nommé |
| Production, cas et groupe publiés (copie locale) | section 02 présente, **aucune trace** d'élément prévu : ni encart, ni commentaire |
| Second cas du groupe, `order: 2` (copie locale) | sa section suit celle du cas 02, sans toucher au `_index` ni aux gabarits |
| Production, tels que commités | aucune page `/cas/chiliz/` ni `/en/cases/chiliz/` ; le `_index` en brouillon ne casse ni la cascade ni le rendu |
| Aucune page séparée de cas | `public/cas/chiliz-source-de-verite/` et `public/cas/index.html` absents |
| Sélecteur de la page Chiliz | mène à `/en/cases/chiliz/` |

Le repli d'AD-4 n'a pas eu à servir : la cascade tient avec un `_index` en brouillon. La story 3.9 garde son exigence conditionnelle, désormais sans objet.

### Une erreur de nettoyage, corrigée

En défaisant les copies locales, `git checkout -- content/cases/chiliz/` n'a pas restauré les deux `_index` du groupe : **ils ne sont pas encore suivis par git**, étant créés par cette story. Mon `draft: false` d'essai y est resté, et la page Chiliz est partie dans le build de production. Vu en relisant la sortie, corrigé, et rebâti : la production ne contient plus que les quatre pages attendues. Un `git checkout` ne défait que ce que git suit.

## Revue du code

### 17/09/2026 — `b4e00ae` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 29. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: de5012d422db377aa8977dc2

##### Rapport de revue (BMAD)

###### Lentille : Edge-case-hunter

- **location** : `layouts/_shortcodes/live-material.html` (lignes 44-48)
  **trigger_condition** : Le `viewBox` d'un fichier SVG contient des coordonnées négatives ou des séparateurs multiples/virgules (ex: `viewBox="-10 -10 100 100"` ou `viewBox="0, 0, 100, 100"`).
  **guard_snippet** : Assouplir l'expression régulière `[0-9.]+` pour inclure le signe moins `[-0-9.]+` et tolérer des espaces/virgules, ou bien s'en remettre consciemment à l'erreur Hugo qui obligera à reformater manuellement le SVG.
  **potential_consequence** : Échec du build pour un SVG sémantiquement valide mais dont le `viewBox` n'est pas formaté exactement selon les espérances strictes de l'expression régulière.

- **location** : `layouts/_partials/case.html` (ligne 16)
  **trigger_condition** : Le champ `setup` dans les paramètres du cas reçoit une valeur non prévue dans les traductions (ex: faute de frappe comme `employeee`).
  **guard_snippet** : Gérer le cas où la clé `i18n` générée est introuvable (ex: via un `default` ou un avertissement `errorf`).
  **potential_consequence** : Affichage silencieux d'une valeur `<dd>` vide ou d'une clé technique non traduite en pleine page.

###### Lentille : Verification-gap

- **location** : `layouts/_shortcodes/live-material.html` (ligne 79)
  **trigger_condition** : Le lien externe de la vidéo pointe vers YouTube avec l'attribut de sécurité `rel="noopener"`, mais ne comporte pas de `target="_blank"`.
  **guard_snippet** : Ajouter `target="_blank"` pour ouvrir la vidéo dans un nouvel onglet, si tel est le comportement voulu.
  **potential_consequence** : L'utilisateur quitte le portfolio en cliquant sur le lien de la vidéo, au risque de ne pas revenir sur le CV en ligne.

- **location** : `_bmad-output/implementation-artifacts/2-5-chiliz-page-case-partial-and-planned-material.md` (ligne 107)
  **trigger_condition** : Le tableau des essais manuels vérifie la bonne traduction de la valeur de `setup` `employee` ("Salarié" / "Employee"), mais ne vérifie pas le rendu des trois autres valeurs possibles.
  **guard_snippet** : Compléter les essais locaux pour s'assurer qu'aucune erreur typographique n'empêche la résolution des statuts `freelance`, `agency` et `ton_pote_le_geek`.
  **potential_consequence** : Un problème de traduction ou de formatage sur ces statuts pourrait ne remonter que plus tard, lors de la publication des prochains cas clients.

##### Constats de la couche projet

NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (les cas d'erreur font bien échouer le build, les éléments sont résolus correctement).
NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, et aucun secret n'est commité ou exposé par les ajouts.
NON BLOQUANT : Skill, procédure et script concordent (aucun de ces fichiers n'est modifié dans la PR).
NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-4 pour la cascade de section, AD-6 pour les balises sémantiques et le comportement du matériel vivant).
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (aucun script shell modifié).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 29 (`b4e00ae`, verdict `pass`) : aucun constat, confirmations seulement, dont la cohérence avec AD-4 (cascade de section) et AD-6 (balises sémantiques et comportement du matériel vivant).

## Reporté

Aucun constat reporté.
