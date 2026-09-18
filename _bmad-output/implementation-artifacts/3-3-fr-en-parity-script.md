# Story 3.3 : FR EN parity script

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.3.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `f9678a6`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1c8fab7588c92fd41f97bfe9

Voici le rapport de revue de la spécification de la story 3.3.

##### Revue de Projet (Couche projet locale)

**Clé `github` manquante pour le contact**
- **Localisation :** Critères d'acceptation (différence sur une clé non traduite)
- **Déclencheur :** La clé `github` est absente de la liste des métadonnées de contact à vérifier. Or, l'architecture (AD-3, décision D-7 du 13/09/2026) impose que la clé `github` soit identique en FR et EN.
- **Correction :** Ajouter `github` à la liste des métadonnées `contact (email, linkedin, github)`.
- **Conséquence :** Une URL GitHub différente ou absente dans une des langues ne ferait pas échouer la CI.

**Vérification préalable de la présence du `translationKey`**
- **Localisation :** Critères d'acceptation (fichier sans son équivalent)
- **Déclencheur :** Le cas d'un fichier Markdown ne possédant *aucun* `translationKey` n'est pas évoqué. L'AD-2 rend cette clé obligatoire pour faire le lien.
- **Correction :** Ajouter un critère qui signale (et fait échouer) tout fichier n'ayant pas de `translationKey` défini avant même de chercher son jumeau.
- **Conséquence :** Échec silencieux ou comportement indéterminé du parseur JSON/bash si le `translationKey` est manquant et qu'on cherche à rapprocher les fichiers sur cette base.

##### Lentille Adverse (Adversarial)

**Ambiguïté sur la méthode de comparaison des rubriques**
- **Localisation :** Critères d'acceptation (retrait d'une rubrique) / Questions à poser
- **Déclencheur :** Le script doit détecter si une rubrique (H2) manque, mais les titres sont traduits. `checks.json` expose les H2 bruts (`findRE`). Comment le script fait-il le rapprochement sans lire le français et l'anglais ?
- **Correction :** La question posée en fin de spec est pertinente. Il faut expliciter la méthode technique : est-ce un simple comptage du nombre de H2 ? Ou une vérification de l'ordre exact selon une liste d'ancres canoniques définies par `docs/format-cas.md` ?
- **Conséquence :** Faux positifs si le script tente de comparer des textes traduits, ou validation abusive si le script ne fait que compter les H2 sans valider que l'ordre et le contenu correspondent au format attendu.

**Sensibilité à l'ordre des éléments dans `live_material`**
- **Localisation :** Critères d'acceptation (clé non traduite : `live_material`)
- **Déclencheur :** Le critère demande de vérifier "id, type, statut" pour `live_material`. Puisque c'est un tableau de blocs dans le front matter, la spécification ne précise pas si une inversion de l'ordre des éléments entre FR et EN est considérée comme une erreur mécanique.
- **Correction :** Préciser si la comparaison du `live_material` doit être stricte sur l'ordre (index par index) ou tolérante à des inversions.
- **Conséquence :** La CI pourrait rejeter un cas dont les matériels sont identiques mais déclarés dans un ordre différent.

##### Lentille Structurelle (Structure)

**Garantie des codes de retour d'erreur**
- **Localisation :** Critères d'acceptation ("il est signalé")
- **Déclencheur :** La formulation "il est signalé" est moins stricte que le premier critère ("il échoue"). L'AD-10 stipule expressément que "tout écart rend un code de sortie non nul".
- **Correction :** Uniformiser la formulation en remplaçant "il est signalé" par "le contrôle échoue en le signalant".
- **Conséquence :** Risque qu'un développeur implémente un avertissement (`echo`) sans faire échouer explicitement le script (`exit 1`), ce qui laisserait la CI au vert.

##### Lentille Éditoriale (Prose)

Aucun problème majeur de formulation ou de clarté de la pensée n'a été détecté pour cette lentille. Les idées s'enchaînent logiquement et le format du document correspond aux attentes.

---

##### À trancher avant d'implémenter

1. **Méthode de comparaison des rubriques H2 :** Quelle est la mécanique exacte validée par Arnaud pour rapprocher les rubriques ? (ex: simple vérification d'égalité du nombre de H2 extraits dans `checks.json`, ou bien un appariement en dur avec les constantes de `docs/format-cas.md`).
2. **Ordre dans `live_material` :** Le script doit-il exiger que l'ordre de déclaration du matériel vivant dans les tableaux YAML soit strictement le même entre FR et EN ?
3. **Clé `github` :** Confirmer la prise en compte de la clé `github` (AD-3) dans les critères d'équivalence de la page Contact.

### Triage des constats (18/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| Projet 1 — clé `github` oubliée | **retenu** | C3 la porte déjà (`ARCHITECTURE-SPINE.md`, liste des contrôles) ; la story l'avait perdue. Ajoutée au critère |
| Projet 2 — fichier sans `translationKey` | **retenu** | un fichier de `content/` sans `translationKey` est signalé avant tout rapprochement, comme l'est déjà un fichier sans front matter ou sans suffixe de langue (manifeste, story 3.1) |
| A1 — méthode de rapprochement des rubriques | **question à Arnaud** | déjà posée par la story ; C4 (story 3.4) a besoin de la même liste |
| A2 — ordre de `live_material` | **question à Arnaud** | l'ordre du front matter ne décide de rien à l'affichage : c'est la place de l'appel dans le texte qui compte (AD-6) |
| S1 — « il est signalé » plus faible que « il échoue » | **retenu** | AD-10 : tout écart rend un code non nul. Les critères disent « le contrôle échoue en nommant… » |
| Prose | sans objet | aucun changement demandé |

### Réponses d'Arnaud (18/09/2026)

- **Rubriques** : la liste passe du document aux données, dans `data/rubrics.yaml`, avec les deux écritures de chaque rubrique. `docs/format-cas.md` y renvoie, le manifeste l'expose, C3 et C4 la lisent. AD-10 et la ligne C4 de la liste des contrôles sont mis à jour.
- **`live_material`** : même ordre exigé en FR et en EN.
- La clé `github` et le fichier sans `translationKey` sont ajoutés aux critères (constats de la revue).

## Ce qui est livré

- `data/rubrics.yaml` : les sept rubriques, dans l'ordre, avec leur écriture française et anglaise. Seule source ; `docs/format-cas.md` ne porte plus la table et renvoie ici.
- `layouts/home.checks.json` : le manifeste expose `rubrics` à la racine, à côté de `stack`.
- `scripts/checks/parity.sh` (C3) : un programme `jq` compare les deux manifestes et signale, fichier par fichier, une entrée en erreur, un `translationKey` absent ou en double, un fichier sans jumeau, un rôle différent, une clé non traduite différente (par rôle : cas, poste, formation, accueil, contact — `github` compris), un `live_material` déclaré autrement, un nombre de rubriques différent, une rubrique hors liste, et une rubrique dont l'écriture anglaise ne fait pas la paire avec la française.
- `scripts/tests/test-parity.sh` : 14 cas sur des manifestes écrits à la main ; `scripts/tests/fixtures/manifests/{fr,en}.json`.
- `docs/procedures/check.md` : tableau des contrôles livrés, et `CHECK_WORK_ROOT` pour lancer un contrôle sur des manifestes d'essai.

La parité s'applique aussi aux brouillons (AD-10) : un `[TODO` n'excuse pas un écart, les deux fichiers devant porter le même marqueur.

### Essais sur le vrai site, copies locales défaites ensuite

| Essai | Signalement |
| --- | --- |
| Pilote tel que commité | aucun : « parité FR/EN vérifiée », code 0 |
| Rubrique « What pushed back » retirée de la version anglaise | `case-02-chiliz.en.md: 5 rubrique(s) en anglais, 6 en français` (démonstration de WS-3) |
| `order: 2` côté anglais | `clé non traduite « order » : 1 en français, 2 en anglais` |
| Version anglaise déplacée hors de `content/` | `case-02-chiliz.fr.md: aucun fichier anglais ne porte le translationKey « case-02 »` |
| Deux éléments de `live_material` inversés en anglais | `live_material : … en français, … en anglais (identifiants, types et statuts, dans le même ordre)` |
| `## Outcome` renommé `## Results` en anglais | `rubrique 5 : « Results » en anglais, « Outcome » attendu en face de « Résultat »` |
| Retour à l'état commité | code 0 |

`scripts/check.sh` enchaîne les deux builds puis le contrôle : « 1 contrôle(s) passés, niveau standard ». `scripts/tests/run.sh` : 128 cas réussis (114 avant la story, 14 ajoutés).

## Revue du code

### 18/09/2026 — `d2a3413` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 37. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 79d35c6166f53d66d25a2dbb

##### Revue `bmad-review`

###### Lentille : Edge-case Hunter

**1. Contrôle des rubriques appliqué aveuglément à tous les rôles**
- **Lens** : `edge-case-hunter`
- **Location** : `scripts/checks/parity.sh:394-407`
- **Trigger condition** : Titres H2 d'une page non-cas (ex: `position`) vérifiés contre `data/rubrics.yaml`
- **Guard snippet** : Englober la sélection sous un rôle spécifique : `(select($f.role == "case" and (($f.h2 // []) | length != (($e.h2 // []) | length)))`
- **Potential consequence** : Échec abusif du script dès qu'une page classique utilise un titre H2 valide (ex: `## Expériences`) non listé dans les rubriques des cas

###### Lentille : Verification Gap

**1. Absence de test sur un fichier non-cas avec des H2**
- **Lens** : `verification-gap`
- **Location** : `scripts/checks/parity.sh:394-407`
- **Trigger condition** : Aucun test ne vérifie le comportement de la vérification des rubriques sur un rôle non-cas contenant des H2
- **Guard snippet** : Ajouter `"h2": ["## Experience"]` au fichier de rôle `position` des fixtures
- **Potential consequence** : La régression signalée ci-dessus (rejet abusif de H2 pour les autres pages) passe inaperçue car la suite de tests est aveugle à ce cas
- **Gap shape** : `regression-gap`
- **Consumer** : `scripts/checks/parity.sh` (logique de rapprochement des rubriques)
- **Evidence** : Les fixtures `en.json` et `fr.json` dans `scripts/tests/fixtures/manifests/` n'ont que `"h2": []` pour les rôles `home` et `position` (lignes 33 et 52), ce qui saute l'exécution de la boucle de validation sur ces rôles.

##### Revue de Projet (Couche projet locale)

NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (les vérifications clés, traduction et matériel vivant sont bien présentes).
NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
NON BLOQUANT — Skill, procédure et script concordent : la procédure documente correctement les spécificités du nouveau contrôle `parity.sh`.
BLOQUANT — Le changement est incohérent avec les décisions d'architecture : l'architecture (portée de C4) limite la contrainte des rubriques de `data/rubrics.yaml` aux seuls "cas". `parity.sh` (C3) applique ce filtre à tous les fichiers disposant de titres H2, interdisant leur usage sur les autres pages.
NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (le `read` est sécurisé par `|| true` et `jq` par un `|| checks_die`).

VERDICT: BLOQUANT — Le contrôle de parité applique la liste stricte des rubriques H2 à tous les fichiers (au lieu des seuls rôles "case"), ce qui contredit l'architecture et bloquera les pages classiques ayant des titres.

Décisions de l'auteur sur la revue du code de la PR n° 37 (`d2a3413`, verdict `block`) :

| Constat | Décision | Suite |
| --- | --- | --- |
| BLOQUANT — la liste des rubriques appliquée à tous les rôles | **retenu, corrigé** | reproduit sur des manifestes d'essai : un poste dont le titre est « Missions » était refusé (« rubrique absente de data/rubrics.yaml »), alors que C4 ne porte que sur les cas. Le rapprochement par la liste est désormais réservé au rôle `case` ; ailleurs, seul le **nombre** de titres de niveau 2 est comparé, ce que FR-20 demande, et le message dit « titre(s) de niveau 2 » plutôt que « rubrique(s) » |
| Verification-gap — aucun cas de test sur un rôle non-cas porteur de H2 | **retenu, corrigé** | `case_parity_titres_libres_hors_dun_cas` : des titres libres passent, et un nombre différent échoue |
| Constats projet non bloquants (4) | confirmations | aucune suite |

Le critère de la story et le tableau de `docs/procedures/check.md` portent la distinction.

### 18/09/2026 — `e453773` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 37. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c3dd089d8498f54353a1c747

##### Lentille : Edge-case Hunter

Aucun cas aux limites non géré n'a été trouvé. Les chemins conditionnels et de bord sont gérés de manière exhaustive par la requête `jq` (qui anticipe l'absence de valeurs avec `// []` et `// {}`, compare proprement les tableaux pour le matériel vivant pour préserver l'ordre, et arrête le rapprochement dès le début en cas d'erreur de manifeste).

##### Lentille : Verification Gap

No verification gaps found.

##### Couche propre au projet

NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (le rapprochement des rubriques est bien ciblé sur le rôle `case`, l'ordre de `live_material` est préservé et vérifié, et l'ajout de `github` a été pris en compte).
NON BLOQUANT — Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
NON BLOQUANT — Skill, procédure et script concordent : la liste des vérifications décrites dans la procédure `docs/procedures/check.md` reflète exactement les contrôles ajoutés à `parity.sh`.
NON BLOQUANT — Le changement est cohérent avec AGENTS.md et les décisions d'architecture (la portée de C4 est respectée).
NON BLOQUANT — Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (la commande `read -d ''` est sécurisée par `|| true` et le comportement de `jq` est borné par `|| checks_die`).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la deuxième revue de la PR n° 37 (`e453773`, verdict `pass`) : aucun constat à traiter ; le relecteur confirme la portée corrigée et le cas de test qui la couvre. Rien n'est reporté.

## Reporté
