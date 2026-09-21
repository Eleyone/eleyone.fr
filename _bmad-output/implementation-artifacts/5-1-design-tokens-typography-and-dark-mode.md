# Story 5.1 : Design tokens, typography and dark mode

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 5.1.

## Revue de spec

### 21/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `9f7a0bb`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: aa5ff0c914d7980347c455a6

Voici le rapport de revue de la spécification de la story 5.1, effectué via les lentilles `adversarial`, `structure` et `prose`.

##### 1. Lentille Adversarial (Recherche de failles et manques)

| Emplacement | Condition déclenchante | Correction / Garde proposée | Conséquence potentielle |
| :--- | :--- | :--- | :--- |
| **Questions** | La question "Où noter les mesures de contraste..." trouve déjà sa réponse dans l'architecture. | Retirer la question. La règle AD-17 (dans `ARCHITECTURE-SPINE.md`) indique explicitement que les mesures sont consignées dans `docs/measures/`. | Le développeur cherche une réponse ou attend une validation pour un point technique déjà tranché par l'architecture. |
| **Critères d'acceptation (Gabarits)** | Le lien d'évitement pointe vers `#content`, mais la spec ne garantit pas que cet identifiant existe. | Ajouter un critère pour s'assurer que le conteneur principal (dans `baseof.html` ou chaque gabarit) porte l'attribut `id="content"`. | Le lien d'évitement est inopérant s'il cible une ancre inexistante, dégradant l'accessibilité. |
| **Critères d'acceptation (Design)** | Les composants en-tête et pied de page doivent être conformes à `DESIGN.md`, mais sans les liens ajoutés par les stories ultérieures (case à cocher). | Préciser : "En-tête et pied de page conformes à `DESIGN.md`, amputés des liens non encore existants (A propos, Contact, etc.) pour satisfaire C12." | Contradiction qui bloquera le développeur entre respecter strictement la maquette visuelle complète ou respecter l'interdiction des liens morts. |
| **Critères d'acceptation (CSS)** | La mention "sans valeur absente de `DESIGN.md`" interdit techniquement des valeurs CSS utilitaires ou calculées (ex: `100%`, `calc()`). | Modifier en "sans valeur magique de design non issue de `DESIGN.md` (fonctions CSS ou variables système autorisées)". | Le développeur se retrouve bloqué pour écrire des règles de mise en page basiques qui nécessitent des valeurs non listées dans les tokens. |
| **Critères d'acceptation (Hugo Pipes)** | "minifiée et empreintée" exige Hugo Pipes, mais rien ne vérifie que le HTML final référence bien l'empreinte de la CSS générée. | Ajouter un critère : "La balise `<link>` dans le HTML porte l'URL avec l'empreinte générée par Hugo (`.RelPermalink` après `resources.Fingerprint`)." | Le cache long nginx prévu par l'architecture pour les CSS empêcherait les visiteurs de recevoir les mises à jour de style si l'empreinte échoue. |
| **Critères d'acceptation (Accessibilité)** | La visibilité de l'anneau de focus est requise, mais le risque de manque de contraste en mode sombre est ignoré si la couleur est fixe. | Préciser que la check-list manuelle AD-17 doit vérifier la visibilité de l'anneau de focus (hors `forced-colors`) **dans les deux modes**. | L'accessibilité au clavier est compromise en mode sombre si le focus n'est plus discernable. |
| **Critères d'acceptation (Typographie)** | "aucun fichier de police" pourrait techniquement laisser passer des appels réseau à des webfonts (`@import` CSS ou `<link>`). | Préciser : "aucun fichier de police local ni aucun appel réseau à un service externe de polices." | La NFR-5 (Core Web Vitals) et la NFR-12 pourraient être contournées par un appel réseau dégradant les performances. |
| **Tâches (Check-list)** | L'absence de césure automatique (`text-wrap`, `overflow-wrap`) est une simple case à cocher sans critère Gherkin formel associé. | Transformer la case en un critère : "**Alors** aucune césure automatique n'est appliquée, et le comportement des textes respecte `DESIGN.md`." | L'exigence de design UX-DR17 n'est pas testée formellement comme condition d'acceptation. |
| **Questions** | La question sur le libellé de `skip_to_content` doit être posée, mais son intégration dans les fichiers de langue manque à l'appel. | Ajouter une consigne : "Prévoir la création de la clé correspondante dans `i18n/fr.yaml` et `i18n/en.yaml` une fois le libellé validé." | Risque d'écrire le texte en dur dans le gabarit au lieu d'utiliser le système de traduction d'Hugo. |
| **Critères d'acceptation (C13)** | Le critère stipule "C13 s'exécute... avec une CSS totale ≤ 20 Ko", en omettant le contrôle du poids global de la page. | Aligner avec AD-8 : "C13 passe (budget respecté pour HTML, CSS, et ressources)." | Se focaliser sur le poids de la CSS masquerait un dépassement potentiel du poids HTML suite à l'intégration des nouveaux gabarits. |

---

##### 2. Lentilles Éditoriales (Structure et Prose)

L'audience cible de ce document est un agent développeur (LLM). L'objectif est la précision, l'absence d'ambiguïté et la cohérence de vocabulaire, justifiant un style très direct. (Les métriques de mots sont des estimations d'éditeur).

| Pass | Texte Original | Texte Révisé | Changements |
| :--- | :--- | :--- | :--- |
| structure | "et 320 px ne provoque aucun défilement horizontal." | CUT | Redondance : cette précision fait doublon avec l'exigence "reflow à 320 px" qui interdit déjà techniquement le défilement horizontal. |
| structure | "- Où noter les mesures de contraste faites dans les deux modes ?" | CUT | La question est inutile puisque l'architecture répond déjà à la question (décision AD-17 : dans `docs/measures/`). |
| structure | "- [ ] Pas de césure automatique ; `text-wrap` et `overflow-wrap` selon `DESIGN.md`." | MERGE (dans la section "Critères d'acceptation") | Les exigences fonctionnelles d'UX-DR17 doivent faire partie des critères de réussite "Étant donné/Quand/Alors", pas d'une liste de choses à faire. |
| prose | "ses tokens de couleur (clair et sombre), ses piles de polices, son échelle typographique, son échelle d'espacement et sa grille (gouttière, mesure, marge, note, cadres md et lg, points de rupture) sont traduits" | "les tokens de design de `DESIGN.md` (couleurs, polices, typographie, espacements, grille) sont traduits" | CONDENSE : Évite une énumération exhaustive alourdissant la phrase. Le LLM se référera directement à `DESIGN.md` pour l'exhaustivité. |
| prose | "sans valeur absente de `DESIGN.md`." | "sans utiliser de valeurs magiques (couleurs, dimensions) non issues de `DESIGN.md`." | Précision sémantique. Empêche le LLM d'être bloqué de manière rigoriste s'il a besoin de valeurs CSS fonctionnelles (ex: `calc()`, `100%`). |

*Bilan des recommandations (Structure) : le document gagne en densité et en lisibilité opérationnelle, aucune perte de compréhension pour l'agent.*

---

##### À trancher avant d'implémenter

- **Libellé `skip_to_content`** : Confirmer le texte exact à utiliser avec Arnaud (comme suggéré dans les questions de la spec).
- **Cible du lien d'évitement (`#content`)** : S'assurer que le conteneur englobant le cœur de page portera bien cet identifiant dans l'architecture de base (`baseof.html`).
- **Composants visuels tronqués** : Valider l'approche consistant à intégrer visuellement l'en-tête et le pied de page de `DESIGN.md`, mais en retirant volontairement les liens (Contact, À propos) pour ne pas déclencher les erreurs de liens morts (règle C12) en attendant les stories de l'Epic 9.

### Tri des constats — 21/09/2026

| Constat | Décision | Raison |
|---|---|---|
| L'ancre `#content` n'est garantie nulle part | **retenu** | Un lien d'évitement vers une ancre absente n'évite rien. Critère ajouté : chaque `<main>` porte `id="content"`. |
| L'empreinte de la CSS n'est vérifiée par rien | **retenu** | Le cache d'un an sur les fichiers empreintés (story 4.2) rendrait une empreinte manquée invisible et durable. Critère ajouté, et un cas de test lit le `<link>` du HTML produit. |
| « aucun fichier de police » n'exclut pas un appel réseau | **retenu**, déjà couvert pour moitié | C10 refuse toute ressource d'une autre origine, dans le HTML et dans le CSS : un `@import` vers Google Fonts échoue déjà. Le critère le dit désormais, plutôt que de le laisser déduire. |
| La césure mérite un critère, pas une case à cocher | **retenu** | UX-DR17 est une exigence, pas une tâche. |
| Le focus doit être visible dans les deux modes | **retenu** | Ajouté à la check-list d'accessibilité. Les ratios sont déjà calculés dans `DESIGN.md` (6,26:1 en clair, 9,05:1 en sombre sur `paper`). |
| « sans valeur absente de `DESIGN.md` » est trop rigoriste | **retenu** | La règle vise les valeurs de design, pas `100%` ni `calc()`. Reformulé en « aucune valeur de design hors `DESIGN.md` ». |
| La clé i18n du lien d'évitement manque | **retenu** | `skip_to_content` entre dans `i18n/fr.yaml` et `i18n/en.yaml`. |
| C13 porte sur tout le budget, pas la seule CSS | **retenu** | Aligné sur AD-8. |
| En-tête et pied de page amputés des liens absents | **retenu**, et résolu autrement | Voir la décision d'Arnaud sur `source_url` ci-dessous : le pied de page porte un vrai lien dès cette story. |
| « 320 px ne provoque aucun défilement » fait doublon avec « reflow à 320 px » | **rejeté** | Le reflow de WCAG 1.4.10 interdit le défilement **bidirectionnel** ; il tolère un défilement horizontal pour un contenu qui l'exige (tableau, schéma). La phrase dit autre chose et plus fort : *aucun* défilement horizontal de la page. La retirer affaiblirait le critère. |
| La question des mesures de contraste est déjà tranchée : `docs/measures/` | **rejeté, sur pièces** | Faux. `docs/measures/README.md` et AD-17 disent tous deux que ce dossier reçoit les mesures **PageSpeed du site en ligne**, une par version publiée, et qu'il appartient à l'epic 11. AD-17 impose une check-list manuelle par gabarit sans dire où la consigner : la question était bien ouverte, et Arnaud l'a tranchée (registre `docs/accessibility.md`). |

### Décisions d'Arnaud — 21/09/2026

1. **Libellé du lien d'évitement** : « Aller au contenu » / *Skip to content*, la proposition d'`EXPERIENCE.md`.
2. **Check-list d'accessibilité** : un registre `docs/accessibility.md`, une table par gabarit, mise à jour par chaque story qui y touche. Il répond à « ce gabarit a-t-il été vérifié, quand, par quelle story ? », ce que la trace éparpillée dans les fichiers de story ne permet pas.
3. **`params.source_url` renseigné dès cette story** : le dépôt public existe depuis la story 1.4, son README depuis la 3.15, et FR-29 veut que le site y renvoie. Sans lui, le pied de page serait un filet surmontant du vide — ses deux autres lignes appartiennent aux epics 7 et 9.

**Anticipation déclarée** (point 7 d'`AGENTS.md`) : `params.source_url` relève de l'impact I-2 (AD-3), que la story 9.x porte. Cette story n'ajoute que la valeur du paramètre et le lien du pied de page qui en dépend ; elle ne touche ni les pages légales, ni la page « À propos », ni aucun autre usage d'I-2.

## Mise en œuvre

`assets/css/main.css` est la seule feuille du site : 10,4 Ko à la source, **4,5 Ko servie**, minifiée et empreintée, pour un budget de 20 Ko. L'écart est le commentaire, que la minification retire : la visée d'`DESIGN.md` (≤ 14 Ko non minifiée) est tenue sur la source comme sur le résultat. Elle porte les huit rôles de couleur des deux modes, les deux piles système, les treize rôles typographiques, l'échelle d'espacement et la grille, tous recopiés du bloc de tokens en tête de `DESIGN.md`.

`frame` et `frame--columns` sont **deux classes et non une** : la première ne fait que la largeur et la gouttière, la seconde y ajoute les colonnes. L'en-tête et le pied de page n'emploient que la première — la grille aurait écrasé leur disposition en ligne, la media query `md` arrivant après dans la feuille.

Dans `baseof.html`, la ressource est saisie **avant** d'être transformée : `resources.Get … | minify` sur une ressource absente ne rend pas « rien », il fait paniquer le build. Constaté sur le site fixture de `scripts/tests/`, qui n'a pas d'`assets/`.

`layouts/_partials/site-footer.html` disparaît entièrement quand `source_url` n'est pas renseigné : un filet surmontant du vide n'apprend rien, et le HTML porterait un repère de navigation sans contenu.

### Vérification de comportement

Les trois gabarits ont été **servis et mesurés au navigateur**, à 320 px, dans les deux modes. Le détail est dans `docs/accessibility.md` ; en résumé : aucun défilement horizontal, aucune paire de texte sous 4,5:1, anneau de focus de 2 px sur chaque élément focalisable, lien d'évitement à l'écran au focus.

Les ratios relevés retrouvent exactement ceux de `DESIGN.md` — `ink` sur `paper` 15,61:1 en clair et 14,75:1 en sombre, `accent` 6,26:1 et 9,05:1, `ink-muted` 6,52:1 et 7,68:1 —, ce qui confirme que le rendu emploie bien les tokens et non des valeurs voisines.

**Ce que la mesure a trouvé et que rien d'automatique n'aurait vu : huit cibles sous les 24 px de WCAG 2.5.8** — la marque de l'en-tête à 20 px, les liens du pied de page à 22, le retour au parcours, les six entrées du sommaire et les deux liens de la 404 à 23. Une seule cause : **un `line-height` n'agrandit pas une cible.** Il agrandit la ligne ; la zone cliquable reste la boîte en ligne du lien. `DESIGN.md` § site-footer dit « un interligne qui garantit une cible d'au moins 24 px » — appliqué à la lettre, cela ne garantit rien. Corrigé par `display: inline-block` et une marge intérieure verticale, sur les blocs qui ne contiennent que des liens ; les liens du texte courant restent exemptés (AD-17).

### Cas de test

`scripts/tests/test-design-tokens.sh`, 8 cas : chaque couleur de la feuille figure dans `DESIGN.md` (une couleur fausse d'un chiffre échoue — vérifié en la falsifiant), les huit rôles existent dans les deux modes, les piles de polices sont recopiées caractère pour caractère, aucune police n'est chargée, la feuille tient dans le budget, chaque `<main>` porte `id="content"`, les trois clés i18n existent dans les deux langues, et la feuille passe bien par `minify | fingerprint`.

Ce que ces cas **ne** couvrent pas, faute de navigateur hors ligne : le contraste, le reflow, le focus et la taille des cibles. C'est précisément le partage d'AD-17, et la raison d'être de `docs/accessibility.md`.

## Revue du code

### 21/09/2026 — `3bbfba8` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 66. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9fadd41dac459d994131d639

**Revue BMAD (Lentilles Edge-Case et Verification-Gap)**

* NON BLOQUANT : Dans `scripts/tests/test-design-tokens.sh`, l'extracteur de commentaires `css_nu()` (via `awk`) ne tient pas compte des chaînes de caractères. Si un pseudo-élément CSS était ajouté avec `content: "/*";`, l'analyseur tronquerait le reste de la feuille, faussant potentiellement le test (Edge-case).
* NON BLOQUANT : Dans `scripts/tests/test-design-tokens.sh`, la fonction `case_la_feuille_est_empreintee_dans_le_gabarit` vérifie la bonne configuration du pipeline en cherchant la présence des fragments `resources.Get "css/main.css"` et `| minify | fingerprint` de manière globale dans `baseof.html`. Le test ne vérifie pas strictement l'enchaînement syntaxique, laissant une (très) légère faille si un second fichier CSS venait à être minifié à la place du premier (Verification-gap).

**Revue de la couche projet**

* NON BLOQUANT : L'ensemble des critères d'acceptation de la story 5.1 sont satisfaits. Les tokens de design sont rigoureusement isolés, le poids CSS est sous le budget (AD-8), aucune police externe n'est chargée, et le lien d'évitement est opérationnel.
* NON BLOQUANT : Aucune donnée privée, aucun secret ni aucune adresse de la forge privée locale n'est divulguée. L'URL GitHub intégrée dans `hugo.yaml` est le miroir public prévu par le projet.
* NON BLOQUANT : Skill, procédure et script concordent. La mise à jour de `docs/procedures/shell-scripts.md` cite et explique correctement la logique de `test-design-tokens.sh`, et la procédure de contrôle manuel est centralisée dans `docs/accessibility.md` comme justifié.
* NON BLOQUANT : L'implémentation est en totale cohérence avec `AGENTS.md` et les décisions d'architecture, notamment avec la gestion des ressources `assets/` et la décision AD-17 pour le registre d'accessibilité.
* NON BLOQUANT : L'exécution du script `test-design-tokens.sh` est sûre sous `set -euo pipefail`. Les évaluations de commandes potentiellement risquées (comme la comparaison mathématique `((octets <= 20480))` ou la recherche de fichiers via `find`) sont gérées de manière à éviter qu'une erreur légitime ne passe sous silence.

VERDICT: NON BLOQUANT — aucune

#### Décisions sur les deux constats — 21/09/2026

**`css_nu()` ne connaît pas les chaînes** — **retenu**, et corrigé autrement que proposé.

Le constat est classé non bloquant, mais son **sens** ne l'est pas : un `content: "/*"` ferait prendre la fin du fichier pour un commentaire, et les couleurs situées après la troncature échapperaient au contrôle. C'est un **faux vert**, le seul sens d'erreur qui ne se pardonne pas — exactement le défaut B1 de la rétrospective de l'epic 4.

Écrire un analyseur CSS pour un cas de test serait disproportionné. Une troncature déséquilibre forcément les accolades : `css_equilibre()` compte les ouvrantes et les fermantes et échoue en le disant. Trois lignes, et le faux vert devient un échec bruyant. Vérifié en injectant le piège exact que décrit le relecteur : « feuille dépouillée déséquilibrée : 46 accolades ouvrantes, 45 fermantes ».

**L'enchaînement du pipeline n'est pas vérifié** — **retenu**.

Les deux fragments étaient cherchés séparément dans `baseof.html` : une seconde feuille minifiée à la place de la première serait passée. Ils le sont désormais dans leur enchaînement, espaces normalisés.

### 21/09/2026 — `0364840` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 66. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: dfacca4bfea01fe13319b559

**Revue BMAD (Lentilles Edge-Case et Verification-Gap)**

* NON BLOQUANT : Dans `scripts/tests/test-design-tokens.sh`, la fonction `case_le_lien_devitement_et_lancre` vérifie la présence de l'ancre via la chaîne stricte `*'<main id="content"'*`. Si un attribut ou une classe (ex: `class="frame"`) devait être inséré avant `id="content"`, le test échouerait à tort (Edge-case).
* NON BLOQUANT : Dans `scripts/tests/test-design-tokens.sh`, la fonction `case_les_huit_roles_de_couleur_sont_la` extrait le bloc sombre avec un `awk` qui s'arrête à la première ligne commençant par une accolade fermante `^}`. Une modification du formatage CSS (comme une accolade en début de ligne à l'intérieur de la media query) tronquerait l'analyse prématurément (Edge-case).
* NON BLOQUANT : Dans `scripts/tests/test-design-tokens.sh`, la fonction `case_la_feuille_est_empreintee_dans_le_gabarit` vérifie la présence du pipeline `fingerprint` et du tag `<link>` dans `baseof.html`, mais ne s'assure pas que le `<link>` est bien placé dans le `<head>`. La CSS pourrait accidentellement glisser dans le `<body>` sans faire échouer le test (Verification-gap).

**Revue de la couche projet**

* NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits. Le CSS respecte le budget, les tokens de `DESIGN.md` sont traduits, le mode sombre est implémenté sans JS, et le lien d'évitement est présent.
* NON BLOQUANT : Aucune donnée privée, adresse de serveur local ou secret n'est commité. Le paramètre `source_url` utilise l'adresse du miroir public GitHub, ce qui est explicitement autorisé.
* NON BLOQUANT : Skill, procédure et script concordent. La mise à jour de `docs/procedures/check.md` explique clairement les limites des tests automatiques justifiant la création de `docs/accessibility.md`, et `shell-scripts.md` documente le nouveau script.
* NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture, notamment avec AD-8 pour la feuille unique et AD-17 pour la vérification manuelle de l'accessibilité.
* NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Les commandes sont sécurisées (ex: `assert_eq`, variables correctement testées) et les échecs provoqueront bien un arrêt explicite et non silencieux du script.

VERDICT: NON BLOQUANT — aucune

## Reporté
