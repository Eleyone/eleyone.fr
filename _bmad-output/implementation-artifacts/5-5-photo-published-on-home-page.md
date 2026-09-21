# Story 5.5 : Photo published on home page

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 5.5.

## Revue de spec

### 21/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `600e9e5`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 37031d23e73364eca2928a32

Ce document existe pour aider le développeur à implémenter l'ajout de la photo sur l'accueil, en respectant les contraintes d'architecture, de design et de budget du projet.
Modèle de structure retenu : Prompt/Task Definition (Functional).

##### Structure et Prose

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| structure | `- [ ] Si une variante dépasse 40 Ko, sa qualité baisse (règle de DESIGN.md), jamais sa taille, et AD-19 le consigne.` | CONDENSER dans les Critères d'acceptation | Une condition flottante hors du format *Given/When/Then* risque d'être ignorée ; la transformer en critère explicite. |
| structure | `la photo est à droite du nom sous md et dans la colonne de marge dès md, aux tailles de DESIGN.md` | MERGE avec `DESIGN.md` (remplacer par : `placée et dimensionnée selon DESIGN.md`) | Évite de dupliquer la spécification visuelle et les points de rupture qui appartiennent à l'UX. |
| prose | `Si une variante dépasse 40 Ko, sa qualité baisse (règle de DESIGN.md), jamais sa taille...` | `Garantir un poids ≤ 40 Ko par variante. Si nécessaire, baisser la qualité (jamais la taille) selon DESIGN.md et consigner dans AD-19.` | Formulation impérative et directe, plus claire pour dicter l'action du développeur. |

##### Adversarial

- **location**: Prérequis de contenu / Critères d'acceptation
  - **trigger_condition**: `portrait_alt` est mentionné en prérequis mais son intégration dans les sources n'est pas testée.
  - **guard_snippet**: Ajouter un AC stipulant : "Le texte alternatif est lu depuis la clé `portrait_alt` de `content/_index.{fr,en}.md` (AD-19)".
  - **potential_consequence**: Le texte alternatif pourrait être codé en dur dans le gabarit au lieu d'être une donnée modifiable du front matter.

- **location**: Critères d'acceptation
  - **trigger_condition**: Les attributs HTML dictés par AD-19 (srcset 1x/2x, width, height, empreinte) sont totalement absents de la spécification.
  - **guard_snippet**: Préciser que le gabarit génère un attribut `srcset` empreinté avec les variantes 1x/2x, ainsi que `width` et `height`.
  - **potential_consequence**: Non-respect de l'architecture, ce qui dégraderait le Cumulative Layout Shift (CLS) sur mobile.

- **location**: Critères d'acceptation
  - **trigger_condition**: La photo se trouve dans le premier écran de l'accueil (FR-37) mais aucune consigne de chargement n'est donnée pour le Core Web Vitals (NFR-5).
  - **guard_snippet**: Exiger l'ajout d'un attribut de priorité (ex: `fetchpriority="high"` et/ou `loading="eager"`).
  - **potential_consequence**: Dégradation de la métrique Largest Contentful Paint (LCP).

- **location**: Opération manuelle
  - **trigger_condition**: L'acteur qui doit commiter le fichier `assets/images/portrait.webp` reste ambigu (Arnaud lance le script, mais qui versionne le résultat ?).
  - **guard_snippet**: Clarifier l'étape : "Arnaud commite l'image générée" ou "Arnaud transmet le WebP au développeur pour commit".
  - **potential_consequence**: Blocage possible si le développeur attend l'image alors qu'Arnaud pense avoir terminé.

- **location**: En-tête (Couvre)
  - **trigger_condition**: FR-34 couvre l'accueil ET la page "À propos", mais cette story ne déploie la photo que sur l'accueil.
  - **guard_snippet**: Indiquer "FR-34 (partiel, accueil uniquement)".
  - **potential_consequence**: Fausse visibilité sur l'avancement global : on pourrait croire FR-34 achevée prématurément.

- **location**: Critères d'acceptation
  - **trigger_condition**: Le gabarit partagé `_partials/portrait.html` est supposé gérer deux emplacements selon AD-19 (`home` et `about`), ce que la spec ignore.
  - **guard_snippet**: Préciser que `_partials/portrait.html` doit accepter un paramètre d'emplacement pour générer les dimensions associées (120x150 et 240x300 pour l'accueil).
  - **potential_consequence**: Le gabarit pourrait être figé pour l'accueil et nécessiter une réécriture complète lors de la création de la page "À propos".

- **location**: Critères d'acceptation
  - **trigger_condition**: Aucune validation n'est faite sur les dimensions réelles des variantes générées par Hugo.
  - **guard_snippet**: Ajouter un AC confirmant que le build génère bien des fichiers d'image aux tailles exactes attendues par `DESIGN.md`.
  - **potential_consequence**: Hugo pourrait générer des variantes erronées (mauvais ratio ou tailles), gaspillant le budget alloué.

- **location**: Critères d'acceptation
  - **trigger_condition**: L'intégration de la balise `<img>` pourrait casser le plancher d'accessibilité exigé.
  - **guard_snippet**: Rappeler le critère UX-DR20 pour s'assurer que l'image ne casse pas l'ordre de navigation au clavier ni le DOM autour de l'identité.
  - **potential_consequence**: Régression silencieuse sur le respect de la norme WCAG 2.2 AA.

- **location**: Prérequis de contenu / Intégration
  - **trigger_condition**: Modifier `content/_index.md` pour y placer `portrait_alt` comporte le risque d'écraser les autres données identitaires.
  - **guard_snippet**: Inclure une précision demandant de préserver scrupuleusement `identity`, `based_in`, et `job_title` lors de l'ajout.
  - **potential_consequence**: Perte accidentelle d'éléments d'identité définis par les stories précédentes.

- **location**: En-tête (Dépendances)
  - **trigger_condition**: La story est bien liée à la 5.2 et à la 5.4, mais la spec ne lie pas l'insertion de l'image au composant conteneur `identity-block` (UX-DR7).
  - **guard_snippet**: Expliciter que le `_partials/portrait.html` est intégré au sein du composant structurant `identity-block`.
  - **potential_consequence**: Désalignement avec la structure HTML globale imposée par l'UX.

##### À trancher avant d'implémenter

- **Commit de l'image :** Qui se charge de commiter le fichier WebP généré ? Arnaud, après avoir exécuté `prepare.sh`, ou le transmet-il au développeur ?
- **Portée du gabarit partagé :** Faut-il concevoir `_partials/portrait.html` dès maintenant pour qu'il lise un paramètre d'emplacement (ex: `home` vs `about`) comme le prévoit AD-19, ou le figer temporairement sur l'accueil ?
- **Optimisation LCP :** La photo figurant dans le premier écran, faut-il inclure explicitement `fetchpriority="high"` ou `loading="eager"` dans la balise pour valider NFR-5 ?
- **Couverture de l'exigence :** Confirmer que l'affichage de la photo sur la page "À propos" (FR-34) est formellement repoussé à une story ultérieure.

### Tri des constats — 21/09/2026

| Constat | Décision | Raison |
|---|---|---|
| Qui commite le WebP ? | **tranché** | Arnaud a indiqué l'original (`docs/private/assets/arnaud.jpg`) ; l'agent lance le script et commite la copie, Arnaud arbitre le cadrage sur les images produites. C'est l'opération manuelle que la story décrit, faite à deux. |
| Le partial doit-il lire un emplacement ? | **rejeté, déjà fait** | La story 5.4 l'a écrit avec son paramètre `place`, et les deux emplacements ont été éprouvés. |
| Ajouter `fetchpriority="high"` ou `loading="eager"` | **rejeté** | `loading` vaut déjà `eager` par défaut, vérifié au navigateur (`loading: auto`). Et `fetchpriority` sert à devancer une grande image de couverture : la variante 1x pèse **6 428 octets**. Un attribut de plus n'achèterait rien de mesurable, et C13 tient déjà le budget de la page. |
| La photo d'« À propos » est-elle repoussée ? | **confirmé** | La page « À propos » relève de l'epic 9. Le partial sait déjà la servir (`place: about`, 160 × 200 et 320 × 400) ; il ne manque que la page. |

### Décisions d'Arnaud — 21/09/2026

1. **Cadrage `Top`**, choisi sur les deux images candidates.
2. **La photo actuelle est gardée « pour l'instant »**, et sera remplacée quand il en aura une autre. Consigné dans `deferred-work.md` : le remplacement ne demande aucune story, seulement de relancer le script.
3. **`docs/private/` n'est pas ce dépôt.** Précision d'Arnaud qui lève une contradiction entre AD-19 (« jamais placé sous le dossier du dépôt ») et `AGENTS.md` (« the original photo stays in `docs/private/assets/` »). `docs/private/` est un dépôt à part, ignoré par celui-ci et refusé par le garde-fou : l'original n'entre donc jamais dans cet historique, ce que visait AD-19.

## Mise en œuvre

### Un défaut d'AD-19, trouvé à la première vraie photo

AD-19 prescrivait `.Process "crop 640x800 <ancrage> webp q80"`. **Dans Hugo, `crop` découpe une fenêtre de 640 × 800 pixels *de l'original*, sans redimensionner.** Sur un original de 1360 × 2048, cela donne un gros plan coupé au menton, et jette les trois quarts de la photo.

L'action juste est **`fill`** : mettre à l'échelle, puis recadrer au ratio. C'est exactement ce que la phrase d'AD-19 décrit — « recadre l'original au ratio 4:5 **et le ramène** à 640 × 800 » —, mais pas ce qu'elle prescrivait. Le script et AD-19 portent la correction.

Le défaut était invisible à la story 5.4 : l'image d'essai y était un dégradé de 1200 × 1600, dont aucun cadrage ne choque l'œil. Il fallait un vrai visage pour le voir.

### Le garde-fou de l'original raisonnait en chemins, pas en dépôts

`prepare.sh` refusait tout original sous le dossier du dépôt, donc aussi `docs/private/assets/`, où `AGENTS.md` place la photo. Il excepte désormais `docs/private/`, en disant pourquoi : c'est un autre dépôt, ignoré par celui-ci, refusé par `check-private.sh` et par le hook.

### La mise en page

Les trois lignes d'identité sont regroupées dans un conteneur explicite, et la photo est leur voisine de grille. Un `grid-row: 1 / span 3` aurait compté les lignes — or « Basé en France » est facultatif, et le compte aurait changé sans prévenir.

Sous `md` : lignes à gauche, photo à droite, pitch pleine largeur dessous. Dès `md` : photo dans la colonne de marge, alignée à droite contre le texte, comme les périodes des postes.

### Vérification de comportement

| Ce qui est exercé | Observé |
|---|---|
| Copie commitée | 640 × 800, 66 858 o (limite 150 000), **aucune métadonnée** |
| Variantes publiées | 120 × 150 à 6 428 o et 240 × 300 à 16 774 o (limite 40 000) |
| Affichage | 72 × 90 sous `md`, 120 × 150 dès `md` ; attributs `width`/`height` à 120 × 150, les dimensions intrinsèques de la 1x |
| C20 et C13 | passent ; 6 contrôles verts |
| Garde-fou | la photo est admise sous `assets/`, sans métadonnée |
| **FR-37, 390 × 844** | identité 98 → 158, photo 98 → 188, pitch d'essai 256 → 379, « Parcours » 419, **premier poste entier jusqu'à 624 avec son lien de cas à 622** — il reste 222 px |
| 320 px, deux modes | aucun défilement, la photo ne déborde pas, rien sous 4,5:1 ni sous 24 px |

Le pitch réel n'existe pas encore (contenu, epic 10) : la mesure de FR-37 a été refaite avec un pitch d'essai de trois phrases, puis le pitch retiré.

## Revue du code

### 21/09/2026 — `fc23c82` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 70. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 857ad08d86ed653639569674

#### Revue de code bmad-review

##### Lens : edge-case-hunter

- **lens**: edge-case-hunter
- **location**: `scripts/photo/prepare.sh`, condition de vérification `if [[ $canonique == "$root"/* ]]`
- **trigger_condition**: Le répertoire racine du projet `$root` n'est pas converti sous sa forme canonique. Si le développeur travaille dans un répertoire accédé via un lien symbolique (comme `/home/eleyone/Workspace/eleyone` documenté dans `AGENTS.md`), la comparaison de chaîne avec `$canonique` (qui est lui résolu vers `/mnt/wsl/...`) échouera systématiquement pour n'importe quel fichier interne au dépôt.
- **guard_snippet**: Canonicaliser `$root` avant la comparaison : `root_canonique=$(readlink -f -- "$root")` puis vérifier `[[ $canonique == "$root_canonique"/* ]]`.
- **potential_consequence**: L'original de la photo (potentiellement lourd et incluant des métadonnées privées GPS/EXIF) pourra être placé n'importe où dans le dépôt (ex: `assets/arnaud.jpg`) sans être refusé par le script, ce qui contourne la sécurité et la décision AD-19.
- **classification**: BLOQUANT (laisse passer un échec de garde-fou en silence)

##### Lens : verification-gap

- **lens**: verification-gap
- **location**: `layouts/home.html` (appel du partiel) vs structure de fichiers
- **trigger_condition**: Le gabarit appelle le partiel via `{{ partial "portrait.html" (dict "place" "home") }}`. Hugo cherche par défaut dans `layouts/partials/`, or le fichier a été créé dans le dossier physique `layouts/_partials/` (nommé ainsi dans l'architecture et vérifié sur le système de fichiers).
- **guard_snippet**: Corriger l'appel en `partial "../_partials/portrait.html"` ou renommer physiquement le dossier `_partials` en `partials` (et corriger la documentation de l'architecture en conséquence).
- **potential_consequence**: Échec fatal de la compilation du site (le partiel est introuvable pour Hugo), empêchant la génération de la page d'accueil.
- **classification**: BLOQUANT (casse la compilation, donc un critère d'acceptation implicite de livraison)

- **lens**: verification-gap
- **location**: `_bmad-output/implementation-artifacts/deferred-work.md`, procédure de remplacement
- **trigger_condition**: Les instructions reportées pour l'opération manuelle d'un futur remplacement de la photo omettent la mise à jour de son texte alternatif (`portrait_alt`).
- **guard_snippet**: Ajouter "et mettre à jour la clé `portrait_alt` dans `content/_index.{fr,en}.md` pour décrire la nouvelle photo" aux instructions.
- **potential_consequence**: Lors d'un futur changement d'image, le texte alternatif décrira l'ancienne photo, créant une régression d'accessibilité (WCAG) passée sous silence.
- **classification**: NON BLOQUANT

#### Couche propre au projet

- **lens**: couche-projet
- **location**: `_bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md`
- **trigger_condition**: L'architecture exige que le partiel se nomme `_partials/portrait.html`, créant une incohérence directe avec les conventions de nommage standards de Hugo (qui attend `partials/`) menant au bogue identifié ci-dessus.
- **guard_snippet**: Mettre à jour l'architecture pour utiliser le dossier standard `partials/` et s'y conformer.
- **potential_consequence**: Incohérence entre les décisions d'architecture (AD), la procédure et le code.
- **classification**: NON BLOQUANT (l'erreur de build est couverte en bloquant par verification-gap, ceci est le constat d'incohérence documentaire)

- **lens**: couche-projet
- **location**: L'ensemble du patch (CSS, Image WebP, HTML).
- **trigger_condition**: Vérification des données privées, secrets et critères d'acceptation visuels.
- **guard_snippet**: Maintenir l'implémentation. L'image commitée a bien été purgée de ses métadonnées, aucune donnée interdite (ex: ville de résidence) n'a été ajoutée au texte alternatif, et la mise en page mobile 390x844 correspond à FR-37. Aucun secret n'est divulgué.
- **potential_consequence**: Conformité avec les règles de protection de la vie privée (NFR-9) et le design.
- **classification**: NON BLOQUANT

VERDICT: BLOQUANT — Le script prepare.sh laisse passer un original stocké dans le dépôt si le chemin du projet est un lien symbolique (contournant la règle AD-19), et l'appel du partiel portrait.html échouera à la compilation car il omet de cibler le dossier non standard _partials/.

#### Décisions sur les quatre constats — 21/09/2026

**1. `$root` n'est pas canonisé — BLOQUANT — retenu, et reproduit.**

Le constat est juste, et la démonstration l'a confirmé sans ambiguïté. `pwd` rend le chemin **logique** : atteint par un lien symbolique, `$root` garde la forme du lien tandis que `readlink -f` rend la forme réelle. La comparaison échouait alors pour *tout* fichier du dépôt.

Reproduit en posant un lien vers le dépôt et en appelant le script à travers lui, sur un original délibérément placé dans `assets/` : **le script l'a accepté et a écrit la copie**. Par le chemin réel, il le refusait. Le garde-fou ne gardait rien.

Les deux côtés sont désormais canonisés, et un cas de test rejoue le piège — par le chemin réel *et* par un lien.

**2. `layouts/_partials/` serait introuvable pour Hugo — BLOQUANT — rejeté, sur pièces.**

Le relecteur annonce un « échec fatal de la compilation ». Le site se construit, et le `<img>` du portrait est dans `public/index.html` — je l'ai relu après le rapport. `layouts/_partials/` est l'emplacement introduit par **Hugo 0.146** pour le nouveau système de gabarits ; le projet tourne sur 0.166.0, `layouts/partials/` n'existe pas, et **tous** les partials du site y vivent depuis la story 2.2. Renommer le dossier casserait le site au lieu de le réparer.

**3. Le remplacement futur de la photo oublie `portrait_alt` — retenu.** Ajouté à l'entrée de `deferred-work.md` : une alternative qui décrirait l'ancienne photo est une régression d'accessibilité qu'aucun contrôle ne verrait.

**4. L'architecture serait incohérente sur `_partials/` — rejeté**, par la même pièce que le constat 2.

### 21/09/2026 — `2110e59` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 70. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 3b9dffa39a2769fd88954a2e

##### Revue de code BMAD

###### Lens : edge-case-hunter

- **location**: `scripts/photo/prepare.sh` (logique de canonisation et d'exclusion de `docs/private/`)
- **trigger_condition**: Validation du traitement des chemins relatifs, des liens symboliques et des répertoires virtuels ou inexistants pour `$prive`.
- **guard_snippet**: Le code ajouté canonise bien des deux côtés (`$canonique` et `$racine`). Le cas où `docs/private` n'existe pas est géré en toute sécurité grâce au repli sur `printf` sans générer d'erreur sous `set -e`. Les liens symboliques qui pointent vers le dépôt sont désormais correctement identifiés et refusés.
- **potential_consequence**: L'original est maintenu hors du dépôt comme exigé par AD-19, sans faux positifs. 
- **classification**: NON BLOQUANT

###### Lens : verification-gap

- **location**: `scripts/tests/test-images.sh`, fonction `case_prepare_refuse_un_original_du_depot_meme_par_un_lien`
- **trigger_condition**: Le fichier temporaire de test `$piege` est créé directement dans l'arbre du dépôt (`$root/assets/`). Si l'assertion `assert_eq` ou `assert_contains` échoue et que le script respecte `set -e`, l'exécution de la fonction s'interrompra avant l'exécution de la ligne finale `rm -f "$piege"`.
- **guard_snippet**: Sécuriser le nettoyage du fichier de test dès sa création, par exemple en posant un `trap 'rm -f "$piege"' RETURN` au début de la fonction.
- **potential_consequence**: Risque de laisser un fichier factice non suivi dans le dossier de travail du dépôt en cas d'échec du test, ce qui pourrait polluer l'état de l'arbre git local du développeur.
- **classification**: NON BLOQUANT

###### Couche propre au projet

- **location**: L'ensemble du diff (Critères d'acceptation, confidentialité, architecture et sécurité des scripts).
- **trigger_condition**: Vérification de la conformité au PRD, aux décisions de `DESIGN.md` et aux règles de script.
- **guard_snippet**: 
  - Les critères d'acceptation de la story sont satisfaits : l'image est intégrée à la grille selon les règles de rupture mobile/bureau (`< md` et `>= md`). 
  - Aucune donnée privée, aucun secret ni aucune information de serveur n'est commité : le texte alternatif se contente d'une description physique de l'image. 
  - Skill, procédure et script concordent : l'utilisation de `fill` plutôt que `crop` est corrigée à la fois dans le script et documentée proprement dans `ARCHITECTURE-SPINE.md`.
  - Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (AD-19) ; le `srcset` et l'optimisation LCP ont déjà été justifiés et/ou implémentés.
  - Dans les scripts shell, aucune erreur silencieuse n'est introduite. Les substitutions de commandes (notamment le `readlink`) capturent les erreurs proprement sans contourner `set -euo pipefail`.
- **potential_consequence**: Le correctif du garde-fou est sûr, l'intégration HTML/CSS est robuste et respectueuse du budget d'accessibilité.
- **classification**: NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

## Reporté
