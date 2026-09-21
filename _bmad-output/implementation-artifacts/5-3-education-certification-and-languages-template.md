# Story 5.3 : Education, certification and languages template

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 5.3.

## Revue de spec

### 21/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `a7256ac`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 7560336f3b520b629001b4f1

Ce document a pour but d'aider le développeur à implémenter la story 5.3 en levant les ambiguïtés et en alignant la spécification sur l'architecture (`ARCHITECTURE-SPINE.md`). 

##### Lecture du contexte

Ce document existe pour définir le comportement attendu de la story 5.3 (bloc Formation, certification, langues) pour les développeurs.
**Modèle de structure :** Prompt/Task Definition (Functional)

---

##### Revue Éditoriale (Structure & Prose)

| Pass | Original Text | Revised Text | Changes |
| :--- | :--- | :--- | :--- |
| structure | `Alors elle n'apparaît pas, et un bloc sans aucune entrée publiée n'est pas rendu.` et `Un bloc sans entrée publiée doit-il vraiment disparaître ?` | MERGE : clarifier le comportement attendu ou retirer la question | Contradiction : le critère d'acceptation impose un comportement que la question remet en cause. Une spécification ne devrait pas avoir de question ouverte sur un critère déjà affirmé. |
| structure | `Check-list d'AD-17 sur l'accueil.` | `La check-list manuelle d'AD-17 (mode clair/sombre, contraste, 390x844, focus clavier, cibles) passe au vert sur l'accueil.` | CONDENSE : manque de précision sur ce qui doit être vérifié. Expliciter les critères évite les oublis lors de l'implémentation. |
| prose | `(jamais rendu)` | `(jamais rendue)` | Correction d'accord (la page `_index`). |
| prose | `un sous-titre par nature` | `un sous-titre par nature (traduit via les clés i18n)` | Précision technique pour s'aligner sur la règle AD-3 (aucun texte en dur dans les gabarits). |
| prose | `quand ils existent.` | `quand ils existent, sans ponctuation orpheline.` | Précision pour éviter des erreurs visuelles (ex: une virgule isolée) si une donnée manque. |

*Total des recommandations : 5.*

---

##### Revue Adversariale

```json
[
  {
    "lens": "adversarial",
    "location": "Critères d'acceptation",
    "trigger_condition": "Absence de mention du mécanisme d'internationalisation (i18n) pour les sous-titres",
    "guard_snippet": "Spécifier que les sous-titres (education, certification, language) doivent utiliser des clés dans `i18n/fr.yaml` et `i18n/en.yaml`.",
    "potential_consequence": "Les sous-titres pourraient être écrits en dur dans le gabarit (violation d'AD-3) ou non traduits (violation de FR-20)."
  },
  {
    "lens": "adversarial",
    "location": "Critères d'acceptation",
    "trigger_condition": "Mécanisme d'exclusion du rendu des pages d'éducation non défini",
    "guard_snippet": "Préciser que `content/education/_index.md` doit contenir `cascade: { build: { render: never } }` ou `list: never`.",
    "potential_consequence": "Le développeur pourrait oublier de configurer Hugo correctement, provoquant la génération de pages orphelines."
  },
  {
    "lens": "adversarial",
    "location": "Critères d'acceptation",
    "trigger_condition": "Schéma des données du Frontmatter `education-<id>` non documenté",
    "guard_snippet": "Expliciter les clés attendues : `title`, `institution`, `period`, `level`, `kind`, `order`, et leur comportement si absentes.",
    "potential_consequence": "Des champs pourraient manquer, entraînant des erreurs lors du tri ou de l'affichage par le gabarit."
  },
  {
    "lens": "adversarial",
    "location": "Général",
    "trigger_condition": "Absence de mention du rôle dans le manifeste `checks.json`",
    "guard_snippet": "Vérifier que les entrées d'éducation sont correctement répertoriées avec le rôle `education` dans `checks.json` (AD-10).",
    "potential_consequence": "Les scripts de CI pourraient échouer à auditer les nouveaux fichiers ajoutés dans `content/education/`."
  },
  {
    "lens": "adversarial",
    "location": "Questions à poser avant de commencer",
    "trigger_condition": "Contradiction entre les questions et un critère d'acceptation existant",
    "guard_snippet": "Retirer la question sur le masquage du bloc vide, ou la résoudre en amont pour figer le critère.",
    "potential_consequence": "Le développeur peut hésiter et implémenter un comportement non validé par Arnaud."
  },
  {
    "lens": "adversarial",
    "location": "Général",
    "trigger_condition": "Gestion de la parité FR/EN (AD-2) pour les entrées d'éducation",
    "guard_snippet": "Mentionner explicitement que chaque fichier doit exister en `.fr.md` et `.en.md` avec le même `translationKey`.",
    "potential_consequence": "Désynchronisation de la section éducation entre la version française et la version anglaise du site."
  },
  {
    "lens": "adversarial",
    "location": "Critères d'acceptation",
    "trigger_condition": "Traitement du marqueur 'Brouillon' en environnement de travail (AD-5)",
    "guard_snippet": "Préciser si le marqueur de brouillon s'applique aux entrées d'éducation, comme c'est le cas pour les cas et les postes.",
    "potential_consequence": "En mode 'work', Arnaud pourrait ne pas distinguer les formations publiées de celles en brouillon."
  },
  {
    "lens": "adversarial",
    "location": "Critères d'acceptation",
    "trigger_condition": "Tolérance des balises `[TODO` non précisée (AD-10)",
    "guard_snippet": "Rappeler que les balises `[TODO` doivent être acceptées par les contrôles pour les fichiers d'éducation en `draft: true`.",
    "potential_consequence": "La CI pourrait bloquer prématurément le travail en cours sur les entrées d'éducation."
  },
  {
    "lens": "adversarial",
    "location": "Critères d'acceptation",
    "trigger_condition": "Affichage HTML : absence de spécification des balises sémantiques",
    "guard_snippet": "Définir la structure HTML attendue (ex: utilisation de `<section>`, `<ul>`, `<li>`) pour assurer l'accessibilité (UX-DR20).",
    "potential_consequence": "La section éducation pourrait utiliser des balises non sémantiques (`div` partout), dégradant la navigation au clavier et pour les lecteurs d'écran."
  },
  {
    "lens": "adversarial",
    "location": "Général",
    "trigger_condition": "Respect du budget de poids par page (AD-8)",
    "guard_snippet": "Vérifier que les ajouts éventuels de CSS pour cette nouvelle section respectent le budget (`CSS total ≤ 20 Ko`).",
    "potential_consequence": "Dépassement silencieux du budget de performance imposé par NFR-5 et AD-8."
  }
]
```

---

##### À trancher avant d'implémenter

- **Les libellés `education_kind_*` :** Valider les traductions de ces sous-titres dans `EXPERIENCE.md` pour pouvoir implémenter `i18n/fr.yaml` et `i18n/en.yaml` sereinement.
- **Le rendu d'un bloc vide :** Clarifier la contradiction dans la spec. Faut-il *vraiment* faire disparaître la section entière si aucune entrée n'est publiée, comme l'impose le critère d'acceptation actuel ?
- **L'application du marqueur "Brouillon" :** Les éléments d'éducation en brouillon doivent-ils afficher le marqueur `draft-marker` en rendu de travail, à l'instar des cas et des postes de parcours définis dans l'AD-5 ?

### Tri des constats — 21/09/2026

| Constat | Décision | Raison |
|---|---|---|
| Les sous-titres doivent passer par i18n | **retenu**, mais déjà imposé | AD-3 l'exige pour tout libellé d'interface, et la story le suppose. Les trois clés `education_kind_*` sont créées dans les deux langues. |
| `_index` doit porter `render: never` | **retenu**, déjà spécifié | AD-18 le décrit mot pour mot, et `content/career/_index.{fr,en}.md` en est le modèle exact à recopier. |
| Le schéma du front matter n'est pas documenté | **rejeté** | AD-18 l'énumère : `kind`, `title`, `institution` (facultatif), `period` (facultatif), `level` (facultatif), `order` unique par `kind`, `draft`. C19 valide déjà `kind`, `title` et l'unicité d'`order`. |
| Le rôle `education` du manifeste n'est pas mentionné | **rejeté, déjà fait** | `layouts/home.checks.json:50` pose `$role = "education"` pour tout fichier de `content/education/`, et `content.sh` s'en sert déjà (`$educations`). |
| Contradiction : le critère impose la disparition d'un bloc vide, la question la remet en cause | **retenu, et tranché par précédent** | Il n'y a pas de contradiction : `DESIGN.md` § Do's and Don'ts dit « laisser vide ce qui n'existe pas », et la story 5.2 a appliqué exactement cette règle au bloc « En parallèle », avec l'accord d'Arnaud. Le bloc formation suit. La question de la story est sans objet. |
| Le marqueur de brouillon sur les entrées de formation | **retenu** | AD-5 énumère les cas et les postes ; les entrées de formation n'existaient pas quand la liste a été fixée. Tranché par Arnaud ci-dessous. |
| « jamais rendu » → « jamais rendue » | **retenu** | Accord. |
| Préciser la check-list d'AD-17 dans le critère | **rejeté** | AD-17 est la source et l'énumère ; la recopier dans chaque story la ferait diverger. `docs/accessibility.md` porte désormais la trace par gabarit. |
| « sans ponctuation orpheline » | **retenu** | Une entrée sans `institution` ni `period` ne doit pas laisser un séparateur pendant. Le gabarit assemble les segments existants et ne joint que ceux-là. |

### Décisions d'Arnaud — 21/09/2026

1. **Sous-titres** : « Formation · Certification · Langues » / *Education · Certification · Languages*, la proposition d'`EXPERIENCE.md`. Le singulier reste juste avec plusieurs entrées : il nomme la nature de la rubrique, pas un décompte.
2. **Le marqueur « Brouillon » s'étend aux entrées de formation.** Extension déclarée d'AD-5, dont la liste datait du 17/09/2026 et ne pouvait pas connaître ces entrées. Le partial est déjà générique ; sans lui, le rendu de travail ne distingue pas une entrée en brouillon d'une entrée publiée.

## Mise en œuvre

`content/education/_index.{fr,en}.md` recopient le montage de `content/career/` : `render: never`, `list: never`, et une cascade qui garde les entrées listées sans les rendre. Aucune page n'en sort — vérifié, `find public -path '*education*'` ne renvoie rien.

`layouts/_partials/education.html` **énumère les trois natures dans l'ordre voulu** plutôt que de les découvrir dans les données : autrement, l'ordre des sous-titres dépendrait du contenu et changerait tout seul à la première entrée ajoutée.

Le séparateur entre l'établissement et le niveau est posé en CSS, sur un `::before` de l'élément des détails. Il n'existe donc que lorsque cet élément existe : **aucune ponctuation orpheline** n'est possible pour une entrée sans institution ni niveau (constat de la revue de spec, vérifié sur l'entrée en brouillon, qui n'a ni l'un ni l'autre).

Titre et détails sont dans un conteneur commun : deux enfants distincts du `li` tomberaient sur deux lignes séparées de la grille dès `md`.

### Vérification de comportement

Servi et mesuré, sur cinq entrées d'essai locales jamais commitées — un diplôme, une certification, deux langues et une certification en brouillon.

| Ce qui est exercé | Observé |
|---|---|
| Regroupement et ordre | Formation, puis Certification, puis Langues ; à l'intérieur, l'ordre de `order` |
| Entrée en brouillon, production | **absente** |
| Entrée en brouillon, rendu de travail | `<span class="draft-marker">Brouillon</span>` devant le titre — l'extension d'AD-5 |
| Bloc sans aucune entrée publiée | le bloc **et son titre** disparaissent |
| Pages produites par `content/education/` | aucune |
| Colonnes à 1440 px | périodes jusqu'à 341, corps à 381 — la même colonne de texte que les postes ; une entrée sans période y commence quand même |
| Sous-titre de nature | capitales, monospace, borné sur la mesure |
| Séparateur | généré en CSS ; absent quand il n'y a rien à séparer |
| 320 px, deux modes | aucun défilement, aucune paire sous 4,5:1, aucune cible sous 24 px, plan `h1→h2→h3` sans saut |

Un écart trouvé et corrigé : le sous-titre de nature débordait dans la colonne de note à `lg`, exactement comme le titre de bloc de la story 5.2. Même cause, même correctif — ce qui suggère que tout titre du cadre doit être borné sur la mesure, et non chacun à son tour.

### Cas de test

Un cas nouveau : les trois natures énumérées dans l'ordre, les sous-titres passant par i18n, le marqueur de brouillon présent, le bloc conditionné à l'existence d'une entrée, et les deux `_index` qui ne rendent ni ne listent. Les trois clés `education_kind_*` rejoignent la liste des clés vérifiées dans les deux langues.

## Revue du code

### 21/09/2026 — `1e4975a` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 68. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ab27b5a9da1e11c41565ba34

#### Revue BMAD

##### Edge-Case Hunter

```json
[]
```
*(Aucun edge-case trouvé : l'absence d'entrées, les entrées partielles sans période ou sans détail, et le cas des brouillons sont tous gérés de manière robuste par l'utilisation de `with`, du tri conditionnel, et du séparateur via le pseudo-élément CSS `::before` empêchant toute ponctuation orpheline).*

##### Verification-Gap

No verification gaps found.

#### Revue de conformité au projet

NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits sans en vider l'intention : le bloc ne s'affiche pas sans entrée, l'ordre est figé par itération explicite, et la disparition des éléments vides est respectée.
NON BLOQUANT — Aucune donnée privée, nom d'hôte, adresse de serveur ni secret n'est commité dans le diff.
NON BLOQUANT — Skill, procédure et script concordent, n'ayant pas été altérés par cette implémentation qui se concentre sur les gabarits.
NON BLOQUANT — Le changement est parfaitement cohérent avec AGENTS.md et les décisions d'architecture (l'extension du marqueur brouillon est minutieusement documentée dans `ARCHITECTURE-SPINE.md`).
NON BLOQUANT — Dans les scripts shell (`test-design-tokens.sh`), aucune erreur de `cat` ne passe sous silence : la déclaration `local contenu` est correctement séparée de l'assignation `contenu=$(cat "$partial")`, garantissant l'efficacité de `set -euo pipefail`.

VERDICT: NON BLOQUANT — aucune

## Reporté
