# Story 9.2 : Privacy policy

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.2.

## Revue de spec

### 23/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `09a2ec0`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 3a1253a358b9c899e1088204

##### Rapport de revue (Story 9.2)

###### Lentille : Adversarial
BLOQUANT : La spec demande les URLs `/confidentialite/` et `/en/privacy/` mais omet d'exiger explicitement les clés `slug` et `title` dans le front matter de `content/privacy.{fr,en}.md`. Sans `slug`, le fichier FR générera par défaut l'URL `/privacy/` ; sans `title`, la balise `<title>` générée par `baseof.html` sera défectueuse (violation d'AD-2).
BLOQUANT : La spec ne définit pas de `translationKey` pour les deux fichiers Markdown. Sans clé commune (comme `privacy`), le sélecteur de langue natif de Hugo ne saura pas lier les versions FR et EN entre elles, ce qui contredit le fonctionnement multilingue prévu par AD-2.
BLOQUANT : Le critère d'acceptation "il porte le lien vers la politique de confidentialité de sa langue" ne précise pas le mécanisme de récupération de ce lien. Cette omission risque d'entraîner l'écriture d'un lien en dur dans le gabarit du pied de page, violant formellement l'exigence AD-3 ("Aucun lien interne n'est écrit en dur dans un gabarit").
BLOQUANT : La spec stipule que "`ci/release-pages.txt` gagne `privacy`", mais ne mentionne pas que les fichiers Markdown doivent explicitement porter `draft: false` (ou omettre `draft: true`). Sans cette précision, les fichiers pourraient rester en brouillon et ne pas être rendus en production, faisant échouer le contrôle CI.
BLOQUANT : L'ajout à `ci/release-pages.txt` en story 9.2 suppose l'existence de ce fichier. Or, le contrôle C15 qui le consomme est introduit dans l'Epic 11. Selon le séquencement (l'Epic 9 précédant l'Epic 11), ce fichier pourrait ne pas exister à ce stade, rendant le critère invérifiable sans sa création préalable.

###### Lentille : Structure
NON BLOQUANT : Dans la User Story, le segment "afin de lire en sachant..." est redondant avec l'intention "je veux savoir" de la ligne précédente et casse légèrement le rythme. Condenser en une formule plus directe comme "afin de naviguer avec l'assurance qu'aucune donnée n'est enregistrée".

###### Lentille : Prose
NON BLOQUANT : Sous "Prérequis de contenu", la consigne "URL de la politique de confidentialité de l'hébergeur, écrite dans le texte de la page." manque d'un verbe d'action clair désignant l'acteur. Clarifier en : "Arnaud doit fournir l'URL de la politique de l'hébergeur pour qu'elle soit incluse dans le corps du texte."

##### À trancher avant d'implémenter
- Quelle méthode dynamique utiliser dans le gabarit `site-footer` pour récupérer le lien vers la page sans l'écrire en dur (ex : via `site.GetPage "privacy"`) et ainsi respecter AD-3 ?
- Confirmation que la `translationKey` commune aux deux traductions est bien `privacy` et que les développeurs doivent systématiquement spécifier les clés `slug` et `title` dans le front matter.
- Le fichier `ci/release-pages.txt` existe-t-il déjà à ce stade du backlog (l'Epic 11 n'étant pas encore passé) ? Si ce n'est pas le cas, faut-il le créer lors de cette story ou différer ce critère d'acceptation ?

### Triage des constats (23/09/2026)

**Les cinq constats bloquants sont refusés, chacun sur pièces.** Le relecteur lit la spec de la story sans le dépôt : ce qu'il croit manquant est décidé ailleurs, ou fait depuis quelques heures.

- *« La spec omet `slug` et `title` »* et *« la spec ne définit pas de `translationKey` »* — les slugs des quatre pages simples sont **décidés dans l'architecture** (`ARCHITECTURE-SPINE.md`, « Slugs des pages simples : FR `/a-propos/`, `/contact/`, `/mentions-legales/`, `/confidentialite/` ; EN … », décidé le 13/09/2026), et `translationKey` est la convention de tout le contenu du dépôt. Les répéter dans chaque spec de story les ferait diverger, ce qu'AGENTS.md reproche déjà ailleurs.
- *« Risque de lien en dur dans le pied de page »* — le mécanisme existe et tourne : `site.GetPage` (`layouts/_partials/site-footer.html:27`), posé par la story 9.1 pour la même raison. La 9.2 reprend la même forme.
- *« Les fichiers pourraient rester en brouillon faute de `draft: false` »* — faux. Les pages de la story 9.1 ne portent **aucune** clé `draft` et sont rendues en production (`public/mentions-legales/index.html` existe). Le défaut de Hugo est « pas brouillon » ; exiger `draft: false` serait du bruit.
- *« `ci/release-pages.txt` pourrait ne pas exister, C15 venant de l'epic 11 »* — faux. Le fichier existe, porte son en-tête explicatif, et la story 9.1 y a déjà ajouté `legal-notice`. La liste est cumulative **par construction**, précisément pour être remplie avant que C15 ne la lise.

**Non bloquants** — deux remarques de style sur la rédaction de la story, sans effet sur le livré. Non retenues : la spec est figée dans le backlog et sa reformulation ne change rien.

**Ce que cette revue n'a pas trouvé, et qui compte** : la page doit affirmer des choses **vraies** sur la journalisation. AD-15 décrit un conteneur qui n'enregistre ni IP, ni agent utilisateur, ni référent — mais la configuration réelle du proxy n'est vérifiée qu'à la story 11.11. Le critère de la story le dit déjà (« la véracité sur le proxy est vérifiée à la story 11.11 ») ; la page se gardera donc d'affirmer ce que personne n'a encore mesuré.

## Arbitrages d'Arnaud (23/09/2026)

1. **L'URL de l'hébergeur** — « je la cherche et je te la soumets ». Un agent l'a trouvée et **vérifiée en chargeant les pages**.
2. **Les vidéos YouTube** — la page le dit dès maintenant, comme le critère d'acceptation le demande : c'est vrai aujourd'hui même si aucune vidéo n'est encore liée.

## Ce que la recherche a établi

| | |
|---|---|
| Politique de confidentialité d'Hostinger | `https://www.hostinger.com/legal/privacy-policy`, chargée et vérifiée, révision du 10/07/2026 |
| Version française | existe (`/fr/legal/politique-de-confidentialite`) mais **la page dit elle-même que seule la version anglaise fait foi** |
| `hostinger.fr` | **redirection 301** : à ne pas citer comme URL stable |
| `/fr/legal/privacy-policy` | **404** : le slug français est `politique-de-confidentialite` |

**Et un défaut dans ce que la story 9.1 a déjà fusionné.** Pour un client français, le cocontractant nommé par les CGU d'Hostinger est **Hostinger International Limited**, société chypriote, 61 Lordou Vironos str., 6023 Larnaca. « Hostinger » est une marque, pas une dénomination sociale, alors que l'article 1-1 I 4° exige « le nom, la dénomination ou la raison sociale ». C'est une **valeur de `.env`** à corriger, pas du code : `HUGO_LEGAL_HOST_NAME` et `HUGO_LEGAL_HOST_ADDRESS`. Signalé à Arnaud.

L'agent a explicitement réservé un point : aucune page chargée ne dit si Hostinger exploite ses propres centres de données ou revend de l'infrastructure. Il ne rapporte que les entités contractantes.

## Mesuré avant d'écrire

Une page de confidentialité affirme des choses ; une seule fausse la rend pire qu'inutile. Chaque affirmation a donc été mesurée sur le rendu de production :

| Affirmation de la page | Mesure |
|---|---|
| Aucun JavaScript | **0** page portant un `<script>` |
| Aucune ressource chargée depuis un tiers | la seule `src` du site est une image locale |
| Aucun cookie | **0** occurrence de `set-cookie` ou `document.cookie` |
| Journaux sans IP, ni agent, ni référent | `deploy/nginx/*.conf` : `log_format sans_ip '[$time_local] "$request_method $uri" $status $body_bytes_sent'` |

Les quatre hôtes liés — `eleyone.fr`, `github.com`, `hostinger.com`, `legifrance.gouv.fr` — le sont par des `href`, jamais par une `src` : aucune requête ne part vers eux sans un clic.

Deux de ces affirmations sont **déjà gardées par C13** (« zéro script, aucune ressource tierce ») : la page ne peut pas devenir fausse sans qu'un contrôle le dise.

**Au passage, une faute de méthode.** Mon premier relevé cherchait `src="http` avec guillemets ; le rendu de production est minifié et écrit les attributs sans guillemets. Il m'a répondu « zéro ressource tierce » pour la mauvaise raison. Troisième fois dans cette session que la minification me prend en défaut — remesuré avec les deux formes.

## La réserve sur le proxy

AD-15 décrit la journalisation de **toute la chaîne**, proxy compris. Le conteneur du site est vérifié ici, par sa configuration ; le proxy ne l'est qu'à la story 11.11. La page n'est pas publiquement fausse pour autant : elle ne sera en ligne qu'à la mise en ligne de l'epic 11, dont la story 11.11 fait partie. Personne ne peut donc la lire avant que l'affirmation soit vérifiée de bout en bout.

## Implémentation

- `content/privacy.{fr,en}.md` — les deux pages, aux slugs décidés le 13/09 ;
- `layouts/_partials/site-footer.html` — l'entrée « Confidentialité », par `site.GetPage` comme celle des mentions légales ;
- `i18n/{fr,en}.yaml` — `footer_privacy` ;
- `ci/release-pages.txt` — gagne `privacy` (D-5).

### Vérification au navigateur, sur un aperçu sans `.env`

| | 1280 px clair | 360 px sombre |
|---|---|---|
| Débordement horizontal | non | non |
| URL longue de l'hébergeur | — | 325 px dans une colonne de 360, ne déborde pas |
| Cibles < 24 px hors phrase | 0 | 0 |
| Contraste texte / lien | 15,61 / 6,26 | 14,75 / 9,05 |
| Colonne du texte | 301 px, comme la page légale | — |

## Revue du code

### 23/09/2026 — `ba5faf5` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 99. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 7241cf4afe9a655a8e4d888f

##### Revue BMAD

###### Lentille : Edge-case-hunter

- **location** : `scripts/tests/test-legal-page.sh:108`
  **trigger_condition** : `grep -o` ne trouve pas la liste `ul` du pied de page
  **guard_snippet** : `pied=$(page index.html | grep -o '<ul class=site-footer__list>.*</ul>') || echo "footer introuvable"`
  **potential_consequence** : arrêt silencieux du script de test sous `set -euo pipefail` (erreur 1 masquée)

- **location** : `scripts/tests/test-legal-page.sh:110`
  **trigger_condition** : le mot `confidentialite` est absent de la chaîne extraite `$pied` (ex: rendu ailleurs)
  **guard_snippet** : `[[ "$pied" == *confidentialite* ]] || echo "Lien manquant"`
  **potential_consequence** : l'expansion `${pied%%...}` renvoie toute la chaîne, sa longueur devient maximale et le test d'ordre passe à tort

###### Lentille : Verification-gap

- **location** : `scripts/tests/test-legal-page.sh:110`
  **trigger_condition** : l'ordre d'affichage n'est pas testé sur le pied de page anglais
  **guard_snippet** : dupliquer le test de position avec `page en/index.html` et les chaînes correspondantes
  **potential_consequence** : une inversion spécifique à la version EN (ex. un problème i18n ou un défaut de gabarit conditionnel futur) ne ferait échouer aucun test
  **gap_shape** : regression-gap
  **consumer** : `scripts/tests/test-legal-page.sh`
  **evidence** : l'assertion d'ordre n'est calculée qu'avec l'extraction de `page index.html` (page française)

##### Couche propre au projet

- **Critères d'acceptation** : Satisfaits. Les politiques stipulent explicitement ce qui n'est pas fait (aucun tracker, 3-tiers, données, etc.), l'URL de Hostinger est présente, les liens pointent vers les bons slugs traduits, et l'enregistrement IP du proxy est documenté sans être validé avant la story 11.11. 
- **Données privées / Secrets** : Aucun secret, nom d'hôte ou adresse de serveur prohibés n'est commité dans les pages. 
- **Skill, procédure et script** : Concordance respectée (les fichiers Markdown ne créent pas de dérive par rapport à une procédure).
- **Architecture** : Cohérent. Le gabarit s'appuie correctement sur `site.GetPage` sans coder en dur le lien (AD-3). La logique multilingue est suivie par la clé `translationKey`.
- **Scripts shell** : Le `grep -o` ligne 108 dans `test-legal-page.sh` viole la règle d'interdiction de laisser passer une erreur en silence sous `set -euo pipefail`.

##### Classement

BLOQUANT : `scripts/tests/test-legal-page.sh:108` — L'échec de la commande `grep -o` laisse passer une erreur en silence sous `set -euo pipefail` (arrêt muet du script).
NON BLOQUANT : `scripts/tests/test-legal-page.sh:110` — L'absence accidentelle du mot dans `$pied` valide faussement le test d'ordre (comportement non robuste de la vérification).
NON BLOQUANT : `scripts/tests/test-legal-page.sh:110` — L'ordre des éléments dans la liste du footer n'est pas vérifié sur la langue anglaise (trou de vérification).

VERDICT: BLOQUANT — Une erreur passe en silence sous set -euo pipefail dans test-legal-page.sh

### Décision sur les constats (23/09/2026)

**Les trois sont retenus, et tous portent sur mon propre code de test.** Le livré n'est pas en cause ; la vérification l'était.

- *Un `grep` nu dans une affectation* — sous `set -e`, son échec fait sortir le script **sans un mot**, et le cas échouait pour une raison qu'il n'affichait pas. L'extraction du pied de page dit désormais ce qu'elle n'a pas trouvé.
- *L'absence d'une entrée validait faussement l'ordre* — le plus sérieux. `${pied%%mot*}` rend toute la chaîne quand le mot manque, donc « très loin » : une entrée absente paraissait simplement venir en dernier, et le cas passait au vert sur un pied de page amputé. La présence de chaque entrée est maintenant affirmée **avant** de comparer les positions.
- *L'ordre n'était vérifié qu'en français* — les deux langues le sont.

Les trois corrections tiennent dans une fonction, `ordre_du_pied`, éprouvée sur deux dégradations : entrée retirée, et ordre inversé. Chacune est vue, avec son message.

### 23/09/2026 — `dac2a93` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 99. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 2dc9c3a76b287a05d7d4dcbc

##### Rapport de revue (Story 9.2)

###### Lentille : Edge-case-hunter
NON BLOQUANT : Dans `scripts/tests/test-legal-page.sh` (fonction `ordre_du_pied`), si les chaînes passées en paramètres (`$premier` ou `$second`) étaient accidentellement identiques à un autre texte HTML situé plus haut dans la balise, la troncature par substitution `${pied%%...}` s'arrêterait à la mauvaise correspondance. Ce comportement théorique n'est pas déclenché par les slugs spécifiques actuels (`mentions-legales` et `confidentialite`).

###### Lentille : Verification-gap
NON BLOQUANT : Dans `scripts/tests/test-legal-page.sh`, le test d'inclusion du lien de confidentialité (`case_legal_lien_de_confidentialite_dans_le_pied_de_page`) n'examine que `index.html` et `en/index.html`. Le critère d'acceptation qui exige la présence de ce lien « depuis toute page » n'est donc vérifié que sur l'accueil, couvrant imparfaitement l'objectif global.
NON BLOQUANT : Aucun test ne valide le contenu textuel et les affirmations de la page de confidentialité construite ("aucun cookie", mention explicite du lien Hostinger). Une erreur de manipulation du fichier `.md` ferait sauter le contenu sans alerter la CI.

##### Couche propre au projet
NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans détournement d'intention (la politique minimale est en place et dynamiquement liée au pied de page via `site.GetPage`).
NON BLOQUANT : Aucune fuite de donnée privée, aucun secret ni nom d'hôte interne n'est commité (le domaine public `hostinger.com` est autorisé et requis légalement pour cette page).
NON BLOQUANT : La concordance skill, procédure et script reste absolue puisqu'aucune procédure ni skill n'est touché par la PR.
NON BLOQUANT : Le changement est en adéquation avec les décisions d'architecture en place, notamment AD-3 et la logique de clefs de traduction.
NON BLOQUANT : En matière de scripts shell, le rattrapage opéré par la PR sur `test-legal-page.sh` bouche correctement un ancien trou. Le code est sécurisé avec de solides structures `|| exit 1`, et plus aucune erreur ne passe sous silence sous `set -euo pipefail`.
NON BLOQUANT : Les règles globales demandent obligatoirement d'ajouter une entrée de version dans `docs/CHANGELOG.md` à chaque développement ; cela n'a pas été fait dans cette PR.

VERDICT: NON BLOQUANT — manques dans la couverture de test automatisée et oubli du fichier CHANGELOG.md

## Reporté
