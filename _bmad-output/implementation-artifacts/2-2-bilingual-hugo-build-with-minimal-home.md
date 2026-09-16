# Story 2.2 : Bilingual Hugo build with minimal home

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 2.2.

## Revue de spec

### 16/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `a8f0c2d`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 2a226a704a8b27b4228d60d0

##### Rapport de revue de spécification (Story 2.2)

###### Lentille : Adversarial (Cas limites et contradictions)

**Oubli de la vérification de la version de Hugo dans `dev.sh`**
* **Emplacement :** Critères d'acceptation (scripts)
* **Condition de déclenchement :** La spec exige la vérification de la version de Hugo pour `build.sh`, mais omet cette vérification pour `scripts/dev.sh`.
* **Correction recommandée :** Ajouter que `scripts/dev.sh` doit également sourcer `scripts/lib/tools.sh` et appeler `require_tool_version hugo`.
* **Conséquence potentielle :** Un développeur pourrait lancer le serveur local avec une version de Hugo différente de celle fixée dans `tools.env`, générant un rendu de travail désynchronisé (violation d'AD-1).

**Absence de `baseURL` dans les réglages Hugo**
* **Emplacement :** Critères d'acceptation (config/_default/hugo.yaml)
* **Condition de déclenchement :** La liste des réglages issus d'AD-2 à appliquer oublie `baseURL: https://eleyone.fr/`.
* **Correction recommandée :** Ajouter `baseURL` à la liste explicite des réglages attendus dans le premier critère.
* **Conséquence potentielle :** Sans `baseURL`, la génération statique peut produire des URL relatives ou incorrectes, ce qui casserait les permaliens ou le sitemap en production.

**Absence de `translationKey` explicite pour l'accueil**
* **Emplacement :** Critères d'acceptation (content/_index.{fr,en}.md)
* **Condition de déclenchement :** Le critère exige la création des pages d'accueil, mais sans imposer leur `translationKey`, exigé par AD-2.
* **Correction recommandée :** Préciser qu'il faut attribuer `translationKey: home` au front-matter de `_index.{fr,en}.md`.
* **Conséquence potentielle :** L'absence d'une clé explicite ou une clé mal nommée compliquerait l'association des langues et ferait échouer le contrôle cumulatif C15 qui s'attend à lire `home`.

**Comportement de `build.sh` sans argument non défini**
* **Emplacement :** Critères d'acceptation (scripts/build.sh)
* **Condition de déclenchement :** Le critère teste `production`, `work`, et "un autre argument", mais oublie le cas d'une exécution sans aucun argument.
* **Correction recommandée :** Écrire "Quand il est appelé avec production, work, sans argument, puis un autre argument".
* **Conséquence potentielle :** Le script `build.sh` pourrait produire un comportement indéfini ou silencieux au lieu d'afficher le message d'usage attendu.

###### Lentille : Structure (Cohérence de l'organisation et vérifiabilité)

**Contradiction potentielle avec AD-3 (Texte vs Gabarit)**
* **Emplacement :** Critères d'acceptation (content/_index.{fr,en}.md)
* **Condition de déclenchement :** Le critère demande d'afficher "Basé en France" et d'avoir `identity` / `based_in` sans préciser la frontière. Si ces textes sont placés dans des clés de front-matter pour être affichés par un gabarit (`index.html`), cela se rapproche d'une violation d'AD-3 qui interdit le texte de contenu dans les gabarits.
* **Correction recommandée :** Clarifier si ces éléments sont des clés de front-matter (nécessaires pour le `<title>` dans `baseof.html` selon AD-2) ou du contenu Markdown (`.Content`).
* **Conséquence potentielle :** Le développeur risque d'insérer du texte "en dur" ou de créer une logique de gabarit trop spécifique, enfreignant la séparation de contenu exigée par l'architecture.

**Option `--panicOnWarning` manquante pour `dev.sh`**
* **Emplacement :** Critères d'acceptation / Check-list
* **Condition de déclenchement :** Un critère général impose "aucun build n'émet d'avertissement". Cependant, la commande `hugo server` spécifiée pour `dev.sh` n'inclut pas le flag `--panicOnWarning` défini dans AD-5 pour le build de production.
* **Correction recommandée :** Ajouter `--panicOnWarning` à la ligne de commande attendue pour `scripts/dev.sh`.
* **Conséquence potentielle :** Les avertissements de dépréciation (ou erreurs mineures) de `hugo server` passeraient inaperçus lors du développement local, retardant la découverte du problème jusqu'au build de CI.

###### Lentille : Prose (Clarté et ambiguïté)

**Mélange de variables et de texte descriptif**
* **Emplacement :** Critères d'acceptation (Étant donné content/_index.{fr,en}.md...)
* **Condition de déclenchement :** La phrase "avec identity, based_in et le titre du site de FR-1" mélange des identifiants techniques (`identity`, `based_in`) et une expression française descriptive sans formatage.
* **Correction recommandée :** Uniformiser la typographie pour clarifier ce qui relève du code : "avec les clés de front-matter `identity`, `based_in` et `title` (titre du site de FR-1)".
* **Conséquence potentielle :** Le développeur pourrait mal orthographier la clé du titre du site ou ne pas comprendre s'il s'agit de variables de front-matter ou de contenu de fichier.

***

##### À trancher avant d'implémenter

* **Structure du contenu de l'accueil :** Confirmer si l'identité, la localisation ("Basé en France") et le titre du site doivent être implémentés strictement comme des **clés de front-matter** (`identity`, `based_in`, `title`) dans `_index.md` (pour être exploitées par `baseof.html` pour la balise `<title>`, comme demandé par AD-2), ou si une partie de ce texte doit résider dans le corps Markdown (`.Content`).
* **Gestion du pitch manquant :** Comme soulevé dans les questions de la spec, faut-il complètement omettre le pitch dans la structure HTML temporaire plutôt que d'insérer un `[TODO: pitch]` ? (Un marqueur `[TODO: …]` publié ferait échouer le contrôle C5).
* **Libellé du titre du site :** Quel est le texte exact du titre du site (FR-1) à commiter pour cette V1 ?

### Triage des constats (16/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — `dev.sh` ne vérifie pas la version de Hugo | **retenu** | `dev.sh` charge `scripts/lib/tools.sh` et appelle `require_tool_version`, comme `build.sh` : un serveur de travail lancé avec un autre Hugo produirait un rendu qui diverge |
| A2 — `baseURL` absente des réglages attendus | **retenu** | à ajouter au premier critère, avec l'adresse publique du site |
| A3 — `translationKey` de l'accueil | **retenu** | `translationKey: home` dans les deux `_index`, exigé par AD-2 et lu par le contrôle cumulatif des pages publiées |
| A4 — `build.sh` sans argument | **retenu** | le critère liste désormais `production`, `work`, **sans argument**, puis un argument inconnu |
| S1 — frontière AD-3 entre contenu et gabarit | **retenu, déjà tranché ailleurs** | AD-19 range `identity`, `based_in`, `job_title` et `portrait_alt` en **clés de front-matter** de `content/_index.{fr,en}.md`, et AD-2 fait construire le `<title>` par `baseof.html` à partir d'`identity`. AD-3 interdit le texte **en dur** dans les gabarits, pas la lecture d'une clé. Le critère doit le dire |
| S2 — `--panicOnWarning` pour `dev.sh` | **question à Arnaud** | AD-5 écrit la commande de `dev.sh` **sans** ce drapeau. L'ajouter ferait mourir le serveur de travail au premier avertissement, à chaque sauvegarde ; le laisser garde les avertissements bloquants là où ils comptent (`build.sh`, les deux CI) |
| P1 — clés techniques et texte mêlés | **retenu** | le critère nomme les clés en code (`identity`, `based_in`, `title`) |

Les deux questions déjà posées par la spec (pitch absent, libellé du titre) sont tranchées par Arnaud avant l'implémentation.

## Ce qui est livré

| Fichier | Rôle |
| --- | --- |
| `config/_default/hugo.yaml` | réglages d'AD-2 : `baseURL`, français à la racine, anglais sous `/en/`, pas de redirection implicite, `disableKinds`, permaliens et slugs par langue |
| `content/_index.{fr,en}.md` | accueil : `title` (FR-1), `identity`, `based_in`, `job_title`, `translationKey: home` ; aucun pitch tant que la story 10.1 ne l'a pas écrit |
| `layouts/baseof.html` | `<title>` construit **ici seul**, `hreflang` par traduction plus `x-default` vers le français, `noindex` hors production |
| `layouts/home.html` | accueil, sans un mot de contenu : tout vient du front-matter |
| `scripts/build.sh` | seul appel à `hugo` : `production` → `public/`, `work` → `build/work/`, version vérifiée avant |
| `scripts/dev.sh` | `hugo server --environment work --buildDrafts`, version vérifiée, sans `--panicOnWarning` |
| `ci/release-pages.txt` | liste cumulative des pages publiées attendues, première entrée `home` |
| `scripts/tests/test-build.sh` | 8 cas **hors ligne** : `hugo` bouchonné, commandes exactes d'AD-5, codes de sortie, priorité de `.tools/` |

### Trois anticipations, imposées par le contenu déjà commité

Le cas pilote `content/cases/chiliz/case-02-chiliz.{fr,en}.md` est dans le dépôt depuis le cadrage. **Aucun build ne pouvait tourner** tant que trois choses manquaient ; chacune est posée au minimum, et la story qui la possède la complétera :

| Anticipation | Pourquoi | Qui la complète |
| --- | --- | --- |
| `layouts/_shortcodes/live-material.html` | le cas appelle `{{< live-material >}}` six fois ; Hugo refuse d'assembler une page dont le shortcode n'existe pas, **même en brouillon et même en production** | story 2.5, qui ajoute la résolution par type — critère ajouté à cette story, avec l'obligation de compléter sans réécrire |
| `content/cases/_index.{fr,en}.md` | la section `cases` n'avait aucun gabarit ; ces fichiers la rendent « jamais rendue, jamais listée », et une cascade visant les seules sections fait de même pour `cases/chiliz` | stories 2.4 et 2.5 |
| `layouts/page.html` | le rendu de travail construit le cas (brouillon) et n'avait aucun gabarit de page | stories 2.4, 2.5 et 9.x |

Le stub du shortcode tient exactement la moitié « planned » d'AD-6 — `id` absent de `live_material` → `errorf`, **rien** en production, encart fixe en rendu de travail — et refuse explicitement un élément `ready`, dont la résolution appartient à la story 2.5. Aucun élément `ready` n'existe aujourd'hui.

### Trois clés de configuration corrigées par l'exécution

Hugo 0.166 refuse ce que le cadrage supposait, et `--panicOnWarning` transforme chaque dépréciation en échec — ce qui est le but :

- `languages.en.languageDirection` → **supprimée** (dépréciée depuis 0.158, remplacée par `direction`, inutile ici) ;
- `cascade._target` → `cascade.target` (déprécié depuis 0.156) ;
- `_build` → `build` (déprécié en 0.145, **supprimé** depuis).

### Essais

| Vérification | Résultat |
| --- | --- |
| `scripts/build.sh production` | `/` et `/en/` seulement, aucun avertissement |
| `scripts/build.sh work` | les deux accueils **plus** le cas pilote dans les deux langues (`/cas/chiliz-source-de-verite/`, `/en/cases/chiliz-source-of-truth/`), 3 encarts « planned » par langue |
| `build.sh` sans argument, puis avec un argument inconnu | code 2, message d'usage, `hugo` jamais lancé |
| `<title>` | `Arnaud Grousset · Développeur backend senior` et `Arnaud Grousset · Senior Backend Developer`, construits par `baseof.html` seul |
| `hreflang` | `fr`, `en`, `x-default` |
| `noindex` | présent en rendu de travail, absent en production |
| Texte de contenu dans les gabarits | aucune occurrence (recherche sur tous les `layouts/**/*.html`) |
| `scripts/tests/run.sh` | **81 cas** (73 avant la story, 8 ajoutés) |

### Le cas de `public/fr/sitemap.xml`, tranché

Le critère demande « sans dossier `public/fr/` ». Le build de production n'y met **aucune page HTML et aucune redirection** — l'intention est tenue —, mais Hugo y place le **sitemap français** (`/fr/sitemap.xml`), et l'index `/sitemap.xml` le référence. Vérifié : `sitemap.filename` renomme le fichier sans le déplacer ; Hugo 0.166 place toujours le sitemap d'une langue dans son dossier dès qu'il y a plusieurs langues. Aucune story du backlog ne possède le sitemap aujourd'hui.

**Décision d'Arnaud (16/09/2026)** : le sitemap est gardé, et le critère précisé — aucune **page** ni redirection sous `public/fr/`, l'espace d'URL français restant la racine. Supprimer un sitemap utile aux recruteurs pour satisfaire la lettre d'un critère aurait été un mauvais échange ; l'intention du critère, empêcher un espace d'URL français parallèle et la redirection `meta refresh` du spike, est tenue.

## Revue du code

### 16/09/2026 — `072c0b8` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 25. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 6bbe867eaf0d92b6fae22db0

##### Revue BMAD

###### Lentille : edge-case-hunter
- NON BLOQUANT : `scripts/build.sh` — Les arguments supplémentaires après le premier sont ignorés silencieusement sans lever d'erreur d'usage (ex: `scripts/build.sh production argument_inutile`).
- NON BLOQUANT : `layouts/_shortcodes/live-material.html` — Une valeur inattendue de `$status` (ex: faute de frappe, valeur différente de `ready` ou `planned`) est ignorée et traitée implicitement comme `planned` sans produire d'erreur explicite au moment du build.

###### Lentille : verification-gap
- NON BLOQUANT : `scripts/build.sh` — Aucun test ne vérifie que le script échoue si plusieurs arguments lui sont passés, ce qui laisse l'ignorance silencieuse des arguments supplémentaires sans couverture.
- NON BLOQUANT : `layouts/baseof.html` — Aucune vérification automatisée ne s'assure du contenu exact de la balise `<title>` générée pour l'accueil par rapport aux autres pages (régression logique non détectée).

##### Couche propre au projet

- BLOQUANT : Le titre de la page d'accueil dans `layouts/baseof.html` omet la ligne d'identité (la condition `{{ if .IsHome }}{{ .Title }}{{ else }}...` n'inclut pas `$identity` pour l'accueil), ce qui casse explicitement le critère d'acceptation exigeant que chaque `<title>` contienne la ligne d'identité (AD-2).
- NON BLOQUANT : `layouts/baseof.html` contient un bloc itératif mort (`{{ with .Site.Home.AllTranslations }} {{ range . }}{{ if eq .Site.Language.Lang "fr" }}{{ end }}{{ end }} {{ end }}`) qui ne produit rien et alourdit le code.
- NON BLOQUANT : Les autres critères d'acceptation de la story 2.2 (configuration Hugo, `build.sh` gérant `work` et `production`, vérification de la version dans `dev.sh`, absence de sitemap sous `/fr/`) sont satisfaits sans que leur intention soit vidée.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ou adresse serveur illicite, ni secret n'est commité (le domaine public eleyone.fr est autorisé), et aucun script ne peut afficher de secret.
- NON BLOQUANT : La cohérence entre scripts, skills et procédures n'est pas altérée ; aucune commande absente n'est appelée.
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (l'évaluation conditionnelle optionnelle du dossier `.tools` avec `&&` est valide et suivie d'un `export PATH` qui assure un code de retour neutre).

VERDICT: BLOQUANT — Le titre de l'accueil ne contient pas la ligne d'identité, violant le critère d'acceptation de la story 2.2 et la décision AD-2.

Décisions de l'auteur sur la revue du code de la PR n° 25 (`072c0b8`, verdict `block`) :

- **BLOQUANT — le `<title>` de l'accueil sans ligne d'identité** : constat juste sur la lettre du critère, et ma décision de coder cette exception **sans la consigner** était la vraie faute. Arnaud tranche : **la spec est réconciliée** (option b). AD-2 et le critère disent désormais que l'accueil fait exception, son titre étant le titre du site qui porte déjà le nom ; lui ajouter la ligne d'identité donnerait « Arnaud Grousset · Développeur backend senior · Arnaud Grousset · Eleyone » dans l'onglet et dans un résultat de recherche. La règle visait à ce qu'aucune page ne sorte avec un titre nu : l'accueil la tient par son titre même.
- **`build.sh` ignorait un argument surnuméraire** : corrigé, `build.sh production inutile` échoue en code 2 avec l'usage, plus un cas de test.
- **`status` inattendu traité comme `planned`** : corrigé, un `status` hors `planned`/`ready` fait échouer le build comme un `id` inconnu (AD-6).
- **Bloc mort dans `baseof.html`** : supprimé.

### Ce que la correction du `status` a révélé

En prouvant le refus sur un site jetable, j'ai constaté qu'`errorf` **signale l'erreur sans interrompre le gabarit** : sur un `id` inconnu, la suite s'exécutait sur une variable vide et ajoutait une seconde erreur illisible (`can't evaluate field status in type string`). Le build échouait bien, mais le message n'aidait personne. Le shortcode est restructuré en `if/else` imbriqués : chaque cas d'erreur produit **une seule** ligne compréhensible. Vérifié sur un site jetable avec le Hugo épinglé :

| Cas | Message | Build |
| --- | --- | --- |
| `id` absent de `live_material` | `live-material : id "…" absent de live_material dans …` | échoue |
| `status` inconnu (`plannned`) | `live-material : status "plannned" inconnu pour "…" ; attendu planned ou ready` | échoue |
| `status: ready` | `live-material : élément "…" en status ready, dont la résolution par type arrive avec la story 2.5` | échoue |
| `status: planned` | — | passe |

### 16/09/2026 — `540b654` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 25. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c8a1aabbf89f6f64eb65e3e2

##### Revue BMAD

###### Lentille : edge-case-hunter
- NON BLOQUANT : `layouts/baseof.html` — L'utilisation de `index . 0` sur le résultat du filtrage des traductions (`where .AllTranslations "Site.Language.Lang" "fr"`) provoquerait une erreur fatale de build ("index out of range") si une page n'avait exceptionnellement pas de version française. Un bloc `range` serait plus robuste face à ce cas limite.

###### Lentille : verification-gap
- NON BLOQUANT : `scripts/dev.sh` — La transmission d'arguments optionnels vers `hugo server` via `"$@"` n'est couverte par aucun test dans `test-build.sh` (qui vérifie uniquement l'appel sans argument). Une régression sur la gestion de ces arguments ne ferait échouer aucune vérification automatisée.

##### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur (hors domaine public), aucun secret n'est commité, et aucun script ne peut afficher un secret.
- NON BLOQUANT : Skill, procédure et script concordent (aucune altération constatée).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (l'exception concernant le `<title>` de l'accueil est correctement consignée dans `ARCHITECTURE-SPINE.md`).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (l'évaluation conditionnelle du dossier `.tools` avec `&&` gère correctement les codes de retour).

VERDICT: NON BLOQUANT — aucune

Décisions sur la deuxième revue (`540b654`, verdict `pass`) : les deux constats sont **reportés à la story 2.3**, qui reprend exactement ce code — sélecteur de langue et `hreflang`. Les rouvrir ici ferait une boucle de revue de plus pour une ligne, alors que la story suivante y touche de toute façon.

### 16/09/2026 — `d6b487f` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 25. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 89c20c4cf762ac6e98b18f4e

##### Revue BMAD

**Plan de revue :**
- Contenu : Diff (code et documents)
- Lentilles sélectionnées : `edge-case-hunter`, `verification-gap`

###### Lentille : Edge-Case Hunter (Recherche de cas limites)
- **Aucun chemin ou cas limite non géré n'a été détecté.** 
  Les cas limites soulevés lors de l'itération précédente (arguments supplémentaires ignorés silencieusement dans `build.sh`, gestion d'un attribut `status` inattendu dans le shortcode) ont été corrigés de manière exhaustive dans ce diff.

###### Lentille : Verification Gap (Couverture et tests)
- `layouts/_shortcodes/live-material.html:15-16`
  - **trigger_condition** : Les erreurs de validation (id manquant, status invalide) n'ont pas de test automatisé.
  - **guard_snippet** : Ajouter un cas de test dans `test-build.sh` qui compile un projet de test avec un contenu malformé et vérifie que le build échoue avec un code d'erreur non nul.
  - **potential_consequence** : Une modification qui affaiblirait ou supprimerait ce garde-fou (`errorf`) ne ferait échouer aucun test (les shortcodes invalides passeraient silencieusement au build).
  - **gap_shape** : `regression-gap`
  - **consumer** : Les appels au shortcode dans les cas clients (ex: `content/cases/chiliz/case-02-chiliz.fr.md`).
  - **evidence** : Aucun test automatisé dans `scripts/tests/test-build.sh` ne lance de build sur un contenu injectant délibérément une erreur de shortcode.

*(Note : l'absence de test pour le passage d'arguments via `"$@"` dans `scripts/dev.sh` est déjà actée et consignée dans `deferred-work.md` pour la story 2.3).*

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (l'exception pour le `<title>` de la page d'accueil est justifiée et documentée).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret (les informations d'identité publiques sont explicitement autorisées par `AGENTS.md`).
- NON BLOQUANT : Skill, procédure et script concordent (aucune divergence constatée).
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (mise à jour appropriée de `ARCHITECTURE-SPINE.md`).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (la construction `[[ -d $tools_dir ]] && PATH=...` est robuste sous `set -e` en bash, et le cas sans argument de `build.sh` échoue bruyamment comme attendu).

VERDICT: NON BLOQUANT — aucune

## Reporté

- source_spec: `_bmad-output/implementation-artifacts/2-2-bilingual-hugo-build-with-minimal-home.md`
  summary: `layouts/baseof.html` construit le `hreflang="x-default"` avec `index . 0` sur les traductions filtrées : une page sans version française ferait échouer le build sur « index out of range » au lieu d'un message utile. Un `range` suffirait.
  evidence: Angle edge-case-hunter de la revue du code de la PR n° 25 (`540b654`). Cas impossible en production (FR-20 impose les deux langues), atteignable en rendu de travail. À reprendre par la story 2.3, qui possède le sélecteur de langue et les `hreflang`.

- source_spec: `_bmad-output/implementation-artifacts/2-2-bilingual-hugo-build-with-minimal-home.md`
  summary: Le passage d'arguments à `hugo server` par `"$@"` dans `scripts/dev.sh` n'a pas de cas de test ; seule la forme sans argument est couverte.
  evidence: Angle verification-gap de la revue du code de la PR n° 25 (`540b654`). À reprendre par la story 2.3.
