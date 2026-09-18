# Story 3.4 : Headings, TODO markers and stack vocabulary

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.4.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `4135913`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9b85e37845e8be2794dae7f2

Voici le rapport de revue de la spec `REVIEW-SPEC.md` généré en appliquant les trois lentilles du skill `bmad-review` (Adversarial, Structure, Prose) :

##### Lentille Adversarial (Failles et cas limites)

*   **Absence de statut `draft` (Faux négatif potentiel) :** Dans Hugo, un fichier est considéré comme publié si `draft: false` est explicite, **mais aussi** si la clé `draft` est purement et simplement absente du front matter. Le critère C5 "porte `draft: false`" risque d'ignorer les fichiers publiés par défaut qui ne déclarent pas la clé.
*   **Action bloquante non spécifiée (CI) :** La spec dit "C4 signale le fichier" ou "C5 le signale", sans expliciter le comportement système. Pour "refuser un cas" en CI, il faut que le script de contrôle retourne un code d'erreur (exit code non nul). Ce comportement implicite peut mener à un log d'erreur sans échec de la CI.
*   **Faux positifs sur les `[TODO` (C5) :** C5 cherche la chaîne `[TODO` dans tout `content/`. Cela interdira formellement de publier un tutoriel, un article de blog ou un bout de code qui contiendrait littéralement la chaîne `[TODO` dans son texte ou dans un bloc de code.
*   **Définition d'un "cas" (C4, C6) :** Les critères ciblent "un cas" ou "un cas publié". La spec ne définit pas comment le script identifie ce qui est un "cas" (par le chemin `content/cases/` ? par un paramètre `type` dans le front matter ?). 
*   **Liste des H2 (C4) :** Le critère H2 "hors liste ou hors ordre" implique une liste de référence (probablement issue de `docs/format-cas.md`). La spec omet de préciser si cette liste doit être codée en dur dans le script de vérification (créant un risque de désynchronisation) ou lue dynamiquement.

##### Lentille Structure (Organisation et flux logique)

*   **Périmètres asymétriques :** Les trois critères n'appliquent pas les mêmes filtres de portée. C4 cible "un cas" (sans préciser si on teste les brouillons ou non), C5 cible "un fichier de `content/`" (qui n'est pas un brouillon), et C6 cible "un cas publié". C4 devrait probablement aussi ignorer les brouillons : tolérer que l'ordre des H2 soit temporairement en chantier tant que le cas n'est pas publié.
*   **Cible des contrôles ambiguë :** L'action "Quand on lance les contrôles" ne précise pas où ce code doit vivre. S'agit-il d'ajouter ces vérifications dans `scripts/check.sh` existant, dans le hook de pre-receive Gitea mentionné dans `AGENTS.md`, ou dans un script dédié appelé par la CI ?

##### Lentille Prose (Clarté et rédaction en français)

*   **Ambiguïté sur la syntaxe TODO :** La spec utilise la chaîne `[TODO` pour C5 et la chaîne `[TODO…]` (avec des points de suspension) pour C6. Dans `AGENTS.md`, la convention citée est `[TODO: …]`. Cette ambiguïté rend le critère d'acceptation de C6 ("une valeur `[TODO…]` [...] est acceptée") interprétable : accepte-t-on la valeur stricte `[TODO…]`, ou n'importe quelle valeur commençant par `[TODO` ?
*   **Manque de précision sur "signaler" :** Le verbe est trop générique. Un test CI doit idéalement afficher la ligne exacte, la technologie problématique ou le H2 intrus pour faciliter le débogage.

---

##### À trancher avant d'implémenter

*   Hugo publie par défaut les fichiers sans attribut `draft`. Doit-on traiter un fichier sans propriété `draft` comme étant "publié" (draft: false) pour les contrôles C5 et C6 ?
*   Faut-il restreindre la vérification des `[TODO` (C5) au seul dossier des cas (`content/cases/`) pour éviter des faux positifs si Arnaud publie plus tard d'autres types de contenus contenant ce mot-clé ?
*   Est-ce que le contrôle C4 (titres H2) doit s'appliquer aux brouillons, ou doit-il être limité aux cas publiés comme C6 ?
*   Les titres H2 de référence et leur ordre (FR/EN) doivent-ils être hardcodés dans le script de vérification, ou extraits dynamiquement de `docs/format-cas.md` ?
*   Ces nouveaux contrôles doivent-ils être ajoutés à `scripts/check.sh` ?
*   Quelle est la syntaxe exacte autorisée dans le front matter `stack` pour une technologie manquante : n'importe quelle chaîne commençant par `[TODO`, ou une chaîne spécifique ?

### Triage des constats (18/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — `draft` absent du front matter | **retenu, déjà résolu** | le manifeste ne lit pas la clé mais l'état calculé par Hugo (`.Draft`), qui publie par défaut. Le critère le dit, pour lever le doute |
| A2 — code de sortie non explicite | **retenu** | convention d'AD-10 et de `check.sh` : les critères disent « échoue en nommant… » |
| A3 — faux positifs de `[TODO` hors des cas | **refusé** | C5 porte sur tout `content/` (liste des contrôles), et c'est son intérêt : un `[TODO` publié dans une page simple est exactement ce qu'il faut refuser. Le site n'a ni blog ni tutoriel (hors périmètre v1) |
| A4 — définition d'un « cas » | **retenu** | le rôle du manifeste (`case`), jamais le chemin |
| A5 — d'où vient la liste des rubriques | **retenu, déjà résolu** | `data/rubrics.yaml`, exposée par le manifeste depuis la story 3.3 ; rien n'est écrit en dur |
| S1 — C4 s'applique-t-il aux brouillons | **retenu, tranché par AD-10** | oui : « seuls la parité (C3), la liste des rubriques (C4) et le garde-fou s'appliquent aux brouillons ». C5 et C6, règles de forme, tolèrent `[TODO` dans un brouillon |
| S2 — où vivent ces contrôles | **retenu** | `scripts/checks/content.sh`, découvert par `check.sh` (AD-10, liste des contrôles) |
| P1 — `[TODO`, `[TODO…]`, `[TODO: …]` | **retenu** | une seule règle : toute valeur qui **commence par** `[TODO` (`checks_is_todo`, story 3.2) |
| P2 — « signaler » trop vague | **retenu** | chaque signalement nomme le fichier, puis la rubrique, la technologie ou le titre fautif |

Constat de l'auteur, hors rapport : l'entrée reportée de la story 2.6 arrive à échéance ici — un titre trop profond dans un cas **groupé** serait rendu en `<h7>`, puisque le hook descend chaque titre d'un niveau. Le manifeste n'expose aujourd'hui que les titres de niveau 2 : il faut lui ajouter les niveaux. **Question à Arnaud** sur la règle exacte.

### Réponses d'Arnaud (18/09/2026)

- **Profondeur des titres d'un cas** : rien au-delà de `###`. La règle ferme l'entrée reportée de la story 2.6 par construction, et `docs/format-cas.md` l'écrit.
- **`[TODO` dans un fichier publié** : refusé partout dans le fichier, blocs de code compris.

## Ce qui est livré

- `layouts/home.checks.json` : `h2` laisse la place à `headings`, qui donne le **niveau** et le texte de chaque titre du Markdown brut. C4 en a besoin pour la profondeur ; la parité n'en retient que les niveaux 2.
- `scripts/checks/content.sh` : C4 (rubriques connues, dans l'ordre, sans doublon, aucun titre au-delà de `###`, cas seulement, brouillons compris), C5 (aucun `[TODO` dans un fichier publié, l'état venant de Hugo), C6 (stack ⊂ `data/stack.yaml`, avec la tolérance `[TODO` des brouillons).
- `scripts/tests/test-content.sh` : 12 cas sur des manifestes écrits à la main ; fixtures et `parity.sh` alignés sur `headings`.
- `docs/procedures/check.md`, `docs/format-cas.md`, AD-10 et la ligne C4 : la profondeur des titres et la nouvelle clé du manifeste.

### Essais

| Essai | Résultat |
| --- | --- |
| Manifestes d'essai : rubrique inconnue, désordre, doublon, titre de niveau 4, `[TODO` publié, stack hors vocabulaire | un signalement précis chacun, code 1 |
| Manifestes d'essai : sous-titre `###`, titres libres d'un poste, `[TODO` dans un brouillon, stack `[TODO` dans un brouillon | acceptés, code 0 |
| Pilote : `## Résultat` renommé `## Bilan` | `C4 : rubrique « Bilan » absente de data/rubrics.yaml` |
| Pilote : `#### Trop profond` ajouté | `C4 : titre de niveau 4 « Trop profond » : un cas n'a que des rubriques ## et des sous-titres ###…` |
| Pilote passé en `draft: false` dans les deux langues | code 0 : le pilote ne contient aucun `[TODO` et sa stack est déjà dans le vocabulaire — les trois contrôles le donnent prêt |
| Retour à l'état commité | `check.sh` : « 2 contrôle(s) passés », code 0 |
| `scripts/tests/run.sh` | 141 cas réussis (129 avant la story, 12 ajoutés) |

Copies locales défaites depuis une copie faite avant chaque essai ; `git status` ne montre que les fichiers de la story.

## Revue du code

### 18/09/2026 — `fa787bb` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 38. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 175e1a5c4b448debf9340b8c

##### Rapport de Revue (BMad)

**Contenu :** Diff (Code et Documentation)
**Lentilles appliquées :** `edge-case-hunter`, `verification-gap`

###### Lentille Edge-Case Hunter
Aucun chemin non géré ou cas limite n'a été trouvé. (Les listes de rubriques vides, les erreurs de récupération du JSON et la tolérance des `[TODO` dans les stacks des brouillons sont correctement et explicitement pris en charge par le code).

###### Lentille Verification Gap
No verification gaps found.

---

##### Constats Projet

- **NON BLOQUANT** : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (les contrôles C4, C5 et C6 sont respectés avec la distinction claire entre cas publiés et brouillons).
- **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
- **NON BLOQUANT** : Skill, procédure et script concordent : `docs/procedures/check.md` cite exactement les contrôles (C4, C5, C6) introduits dans `scripts/checks/content.sh`.
- **NON BLOQUANT** : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (conservation de l'extraction par `findRE` via Hugo et d'un manifeste unique lu par la CI).
- **NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (le code de retour des requêtes `jq` et des boucles `while read` est géré de façon sécurisée ; les pannes interrompent l'exécution).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 38 (`fa787bb`, verdict `pass`) : aucun constat à traiter, confirmations seulement. Première story de l'epic 3 à passer en une seule revue. Rien n'est reporté.

## Reporté
