# Story 3.10 : Internal links, anchors and orphan pages

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.10.

## Revue de spec

### 18/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `6407d33`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 3d32728153bb6547ea67ab7a

##### BMad Review Report

###### Adversarial
- **Location** : Critères d'acceptation, "le build de production"
  - **Condition** : Le script ne cible que le build de production, ignorant les liens cassés dans les contenus en brouillon (qui ne sont rendus que dans le build de travail).
  - **Snippet** : Appliquer le contrôle sur `public-work/` en plus de `public/`.
  - **Conséquence** : Un lien cassé dans un cas en brouillon n'est détecté qu'au moment de sa publication, risquant de bloquer le déploiement sans préavis.

- **Location** : Critères d'acceptation, "atteignable depuis l'accueil"
  - **Condition** : Implémenter un algorithme de parcours de graphe (pour repérer les pages orphelines par un chemin depuis l'accueil) en pur bash est extrêmement complexe et fragile, violant l'exigence NFR-7 ("scripts simples").
  - **Snippet** : Simplifier le critère (ex. : "chaque fichier HTML généré doit être ciblé par au moins un lien interne") ou autoriser un outil tiers.
  - **Conséquence** : Création d'une usine à gaz difficile à maintenir et très sujette aux bugs.

- **Location** : Critères d'acceptation, "si le constat de la story 2.5 a échoué"
  - **Condition** : Un script bash statique ne peut pas évaluer le contexte historique d'une ancienne story pour déterminer dynamiquement sa logique.
  - **Snippet** : Expliciter que le développeur doit coder en dur le comportement décidé à l'issue de la story 2.5, sans mettre de condition historique dans le script.
  - **Conséquence** : Injonction inapplicable en code ou comportement non déterministe.

- **Location** : Critères d'acceptation, "params.source_url est vide"
  - **Condition** : Extraire `params.source_url` depuis le code bash exige de parser la configuration Hugo, ce qui est peu robuste via des regex.
  - **Snippet** : Expliciter l'utilisation d'une commande robuste (ex: `hugo config`) pour extraire la valeur.
  - **Conséquence** : Un simple `grep` plantera ou donnera des faux positifs si le fichier de configuration est reformaté (YAML/TOML).

- **Location** : Critères d'acceptation, "sauf les 404"
  - **Condition** : Le script n'exclut pas les fichiers générés par Hugo qui n'ont pas vocation à être liés dans les pages (ex. `sitemap.xml`, `index.xml` pour les flux RSS, ou les pages de redirection alias).
  - **Snippet** : Exclure explicitement les fichiers `.xml` et les redirections générées.
  - **Conséquence** : Faux positifs systématiques et blocage de la CI.

- **Location** : Critères d'acceptation, "tout lien interne"
  - **Condition** : Le texte ne précise pas si les appels à des ressources médias (les attributs `src` des images, de `<video>` ou `<source>`) sont vérifiés au même titre que les attributs `href`.
  - **Snippet** : Expliciter que la validation porte conjointement sur les `href` et les `src`.
  - **Conséquence** : Des images ou vidéos cassées pourraient être publiées sans alerter le pipeline.

- **Location** : Critères d'acceptation, "#<translationKey>-<rubrique>"
  - **Condition** : La notion de `<translationKey>` est absente des documents d'architecture (AD-4 définit le format `NN.r`).
  - **Snippet** : Remplacer par la convention définie par l'architecture (`#NN.r-titre`).
  - **Conséquence** : Le développeur ne peut pas écrire l'expression régulière du contrôle, ou crée des faux positifs.

- **Location** : Critères d'acceptation, "atteignable depuis l'accueil de sa langue"
  - **Condition** : Si l'algorithme ne traite pas le sélecteur de langue comme un chemin valide, l'arborescence anglaise entière pourrait être signalée comme orpheline en traversant le graphe depuis le point d'entrée unique (`/`).
  - **Snippet** : Imposer que la recherche démarre simultanément depuis `/` ET `/en/`.
  - **Conséquence** : Faux positifs massifs sur la totalité de la version anglaise du site.

- **Location** : Critères d'acceptation, vérification des liens CV PDF
  - **Condition** : La validation conditionnelle des liens PDF "ensemble ou rien" est déjà assignée au contrôle C21 (AD-21 de l'epic 7). L'inclure dans la story 3.10 (C12) crée un doublon.
  - **Snippet** : Retirer la mention ou laisser le soin à C21 d'inspecter l'intégrité PDF.
  - **Conséquence** : Double implémentation de la même règle ; dette technique et risque de désynchronisation.

- **Location** : Critères d'acceptation, "lien interne vers un fichier absent"
  - **Condition** : Les liens externes sont totalement ignorés. Si aucun ping HTTP n'est souhaité, l'absence de validation syntaxique peut tout de même laisser passer de graves erreurs (ex. un lien `mailto:` contenant un point d'interrogation mal encodé).
  - **Snippet** : Ajouter une validation syntaxique simple ou un avertissement pour les liens externes.
  - **Conséquence** : Dégradation de l'expérience utilisateur et liens externes morts non détectés.

###### Structure & Prose

Ce document existe pour cadrer l'implémentation de la story 3.10 (vérification des liens internes et orphelins) à destination du développeur.  
Modèle de structure évalué : Spécification technique / Critères d'acceptation.

| Pass      | Original Text                                         | Revised Text                                  | Changes                                                              |
| --------- | ----------------------------------------------------- | --------------------------------------------- | -------------------------------------------------------------------- |
| structure | `si le constat de la story 2.5 a échoué, C12 exclut les pages de groupe sans section (repli d'AD-4).` | CONDENSE : `Le script applique le repli d'AD-4 si la story 2.5 l'a acté.` | Le script statique n'évalue pas "si la story a échoué" ; le comportement attendu dépend de la décision passée que le développeur doit figer en code. |
| structure | `Étant donné le build de production de contrôle` | MERGE : `Étant donné le build de production et le build de travail` | Prendre en compte le build `public-work/` permet de détecter les liens morts de contenus en brouillon plus tôt dans le pipeline. |
| prose     | `il la signale, sauf les 404.` | `il la signale, à l'exception de la page 404.` | Clarification nécessaire ("les 404" est imprécis : parle-t-on du code d'erreur HTTP ou du fichier gabarit 404.html ?). |
| prose     | `tout lien interne vers un fichier absent et toute ancre absente, dont #case-NN, #<translationKey>-<rubrique> et #position-<id>.` | `tout lien interne vers un fichier absent et toute ancre absente, notamment #case-NN, #[...]-<rubrique> et #position-<id>.` | Remplacement de "dont" par "notamment" pour clarifier qu'il s'agit d'une liste non exhaustive. |

*Métrique : ~180 mots. Réduction estimée : ~10 mots (< 5 %).*

##### À trancher avant d'implémenter

- **Complexité du script (NFR-7) :** L'exigence de trouver des pages "non atteignables depuis l'accueil" induit un parcours de graphe complexe en bash pur. Peut-on simplifier la règle de validation (ex. : s'assurer que tout fichier généré est la cible d'au moins un lien dans tout le projet) ou accepter un outil existant ?
- **Constat de la story 2.5 :** Faut-il acter formellement du statut de ce repli (AD-4) dès maintenant pour que le développeur implémente en dur la règle actuelle, plutôt que de lui demander une implémentation conditionnelle ?
- **Doublon PDF avec C21 :** La vérification de la présence des CV PDF est régie par AD-21 via le contrôle C21. L'Epic l'exige ici pour C12. Faut-il supprimer cette vérification de la story 3.10 ?
- **Convention des ancres :** L'ancre `<translationKey>` n'est pas définie dans l'architecture (contrairement à `NN.r`). Quelle est l'expression régulière ou la convention que le script doit réellement chercher ?
- **Build de travail :** Faut-il imposer l'exécution du script `links.sh` sur le dossier `public-work/` pour sécuriser les brouillons cachés en amont ?

### Triage des constats (18/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| Parcours de graphe trop complexe : se contenter d'« un lien quelque part » | **refusé** | la règle dit ce qu'elle veut dire : une page doit être atteignable **depuis l'accueil de sa langue** (FR-15). Une page liée seulement depuis une autre page orpheline resterait injoignable. Le site compte quelques dizaines de pages : un parcours en largeur en shell suffit, sans outil de plus |
| Repli conditionnel d'AD-4 | **retenu** | le constat de la story 2.5 a **tenu** : la cascade fonctionne avec un `_index` en brouillon. Le repli n'a donc pas lieu d'être, et le critère cesse d'être conditionnel |
| Doublon avec C21 pour les CV | **refusé** | les deux contrôles ne regardent pas la même chose : C21 juge les **fichiers** PDF (en-tête, poids, motifs), C12 juge la **cohérence des liens** — les deux liens ou aucun. Le second ne dépend pas du premier |
| Convention des ancres | **retenu, sans règle spéciale** | le contrôle résout **chaque** fragment contre les identifiants réellement présents dans la page cible. `#case-02`, `#case-02-contexte` et `#position-chiliz` sont alors vérifiés sans que leur forme soit écrite nulle part |
| Lancer aussi sur le rendu de travail | **refusé** | AD-10 : les contrôles HTML portent sur le build de production. Le rendu de travail contient les brouillons, dont des pages volontairement non liées : la règle des orphelines y serait fausse |
| Validation syntaxique des liens externes | **refusé** | hors de C12, qui porte sur les liens internes et les ancres. Aucun lien externe n'est aujourd'hui rendu hors du sélecteur et du JSON-LD, et les pinger est exclu en CI |
| Prose : « les 404 », « dont » | **retenus** | « les deux pages 404 » et « notamment » |

## Ce qui est livré

- `scripts/checks/links.sh` (C12) : résolution de chaque lien interne et de chaque fragment contre les identifiants réellement présents dans la page visée, parcours en largeur depuis les accueils pour les pages orphelines, et cohérence des liens conditionnels (CV, dépôt).
- `scripts/tests/test-links.sh` : douze cas sur un petit site monté dans le dossier d'essai.
- `docs/procedures/check.md` décrit le contrôle.

### Un piège connu, reproduit et attrapé au premier essai

`grep -rl` sans correspondance rend 1 ; sous `set -euo pipefail`, l'affectation tuait le script, qui sortait en code 1 **sans aucun signalement**. C'est le même piège que la story 3.9, déjà écrit dans `docs/procedures/shell-scripts.md`. Cette fois, je l'ai vu au premier lancement, parce qu'un code 1 muet est suspect en soi : un contrôle qui échoue sans rien dire n'échoue pas pour la bonne raison.

### Essais

| Essai | Résultat |
| --- | --- |
| Production réelle | code 0 |
| Lien vers une page absente | `C12 : lien « /cas/absente/ » vers une page absente (cas/absente/index.html)` |
| Ancre absente de la page visée | signalée, avec l'ancre et la page |
| Ancre `#position-chiliz` retirée de l'accueil | le « Retour au parcours » est signalé |
| Page que rien ne lie | `C12 : page orpheline…` |
| Page liée seulement depuis une page orpheline | **les deux** sont signalées : c'est la raison du parcours depuis les accueils |
| Les deux 404 | jamais signalées |
| Liens externes et `mailto:` | ignorés |
| Lien de CV sans les deux PDF ; deux PDF sans lien | signalés séparément, et le couple cohérent passe |
| `source_url` renseignée sans lien | signalée ; avec le lien, code 0 |
| Production absente | code 2 |

`scripts/check.sh` : « 4 contrôle(s) passés ». `scripts/tests/run.sh` : 231 cas réussis (219 avant la story, 12 ajoutés).

## Revue du code

### 18/09/2026 — `795d013` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 46. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 577873b6f0dc3c99e8381010

##### BMad Review

###### Lentille : Edge-Case Hunter

**Lien interne avec paramètres de requête (`?`) non géré**
- **Location** : `scripts/checks/links.sh:284`
- **Trigger condition** : Un lien interne contenant une query string (`href="page.html?param=1"`) fera échouer la vérification de fichier car la chaîne n'est pas nettoyée avant de tester l'existence de la cible.
- **Guard snippet** : `cible=${cible%%\?*}` (à appliquer avant ou après avoir extrait le fragment).
- **Potential consequence** : Le contrôle générera un faux positif et bloquera la CI si un lien interne paramétré est ajouté à l'avenir.

###### Lentille : Verification-Gap

**Tolérance excessive sur le nom des fichiers de CV liés**
- **Location** : `scripts/checks/links.sh:337`
- **Trigger condition** : Le motif regex `href="?/assets/cv/` valide tout fichier lié dans ce répertoire, sans exiger qu'il s'agisse explicitement de `cv-fr.pdf` ou `cv-en.pdf`.
- **Guard snippet** : `grep -rlE 'href="?/assets/cv/cv-(fr|en)\.pdf"' "$public" --include='*.html'`
- **Potential consequence** : L'oubli de la mise à jour d'un lien (qui pointerait vers un ancien PDF ou un autre nom de fichier laissé dans le dossier) satisferait C12 alors que le lien est erroné.
- **Gap shape** : `regression-gap`
- **Consumer** : `scripts/checks/links.sh:338`
- **Evidence** : Le cas de test `case_links_cv_publies_sans_lien` dans `scripts/tests/test-links.sh` s'assure qu'un lien correct passe, mais aucun test ne vérifie le rejet d'un lien pointant vers un fichier nommé différemment dans le même dossier.

---

##### Couche propre au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont rigoureusement satisfaits (validation des liens, fragments, orphelines par graphe, et règles conditionnelles).
- NON BLOQUANT : Aucune donnée privée, adresse de serveur ou secret n'est divulgué ou commité.
- NON BLOQUANT : La procédure `docs/procedures/check.md` a été mise à jour en stricte concordance avec les ajouts du script `links.sh`.
- NON BLOQUANT : L'implémentation est parfaitement cohérente avec `AGENTS.md` et les décisions d'architecture (AD-10 respecté, AD-21 respecté).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (le cas des retours vides de `grep` a été brillamment anticipé et protégé avec `|| true`).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 46 (`795d013`, verdict `pass`) : aucun constat, confirmations seulement. Deuxième story de l'epic 3 à passer en une seule revue.

## Reporté
