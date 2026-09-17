# Story 2.3 : Language switcher, hreflang and 404 pages

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 2.3.

## Revue de spec

### 17/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `1ebc271`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 250be6438f8d84a6c37e661c

*Plan de revue : document de type comportemental (docs), application des lentilles `adversarial`, `structure`, puis `prose` (sur la base des recommandations de structure).*

#### Lentille : Adversarial (Analyse des failles et cas limites)

| Pass | Location | Trigger Condition | Guard Snippet | Potential Consequence |
|---|---|---|---|---|
| adversarial | CA 2 (Sélecteur) | Le scénario se limite à « l'accueil français », ignorant les pages profondes et la purge des ancres exigée par l'architecture (AD-2). | Remplacer « l'accueil français » par « une page profonde avec une ancre (ex: page de groupe) ». | Le sélecteur pourrait échouer sur les pages profondes ou transmettre l'ancre de la page source de manière inappropriée. |
| adversarial | CA 1 (hreflang) | Les balises `hreflang` nécessitent des URL absolues pour être valides pour le SEO. | Préciser `avec des URL absolues` pour chaque balise `<link rel="alternate" hreflang>`. | Des URL relatives dans les `hreflang` rendraient les balises invalides et ignorées par les moteurs de recherche. |
| adversarial | CA 3 (Pages 404) | Rien ne garantit explicitement que les 404 générées utilisent bien le gabarit, l'en-tête et les menus de la bonne langue. | Ajouter « avec l'en-tête et le pied de page dans la langue correspondante » dans le `Alors`. | Une page 404 anglaise générée avec le menu de navigation et le pied de page en français. |
| adversarial | Liste de tâches | La tâche `i18n` mentionne l'existence des fichiers mais pas l'ajout effectif des libellés du sélecteur et de la page 404. | Ajouter `- [ ] Les clés du sélecteur et de la page 404 sont ajoutées à i18n/`. | Oubli d'externalisation des chaînes de caractères (textes codés en dur dans le gabarit). |
| adversarial | CA 2 (Sélecteur) | NFR-4 (WCAG 2.2 AA) est déclaré couvert, mais le sélecteur ne mentionne pas d'exigence d'accessibilité (ex: `aria-label`). | Ajouter « doté d'un nom accessible (aria-label ou texte masqué) indiquant la langue cible ». | Non-conformité potentielle aux règles d'accessibilité WCAG 2.2 AA sur la navigation. |
| adversarial | CA 1 (html lang) | L'attribut `dir` (direction du texte) n'est pas testé ni mentionné, bien qu'il s'agisse d'une bonne pratique avec `lang`. | Vérifier que `<html lang="fr" dir="ltr">` est généré. | Anomalies mineures de rendu ou d'accessibilité. |
| adversarial | CA 2 (Sélecteur) | Le critère ne teste pas le cas du repli `.Translations` vide (ex: page de groupe en brouillon en environnement de travail, cf. AD-4 et AD-2). | Ajouter un CA : `**Étant donné** une page sans traduction (rendu de travail), **Quand** on suit le sélecteur, **Alors** il mène à l'accueil de l'autre langue.` | Erreur de build Hugo lors de la rédaction si le cas n'est pas géré, ou lien brisé cliqué par un développeur. |
| adversarial | CA 3 (Pages d'erreur) | Hugo ne génère pas de 404 par langue par défaut sans configuration spécifique des permaliens ou des alias. La spec ignore ce risque technique. | Ajouter une vérification pour s'assurer que Hugo crée bien physiquement `public/en/404.html`. | La page 404 anglaise ne sera pas générée au build, et nginx affichera la 404 par défaut. |
| adversarial | Questions à poser | La question de la 404 ne demande que le texte, sans préciser qu'il le faut dans les deux langues. | Demander le texte de la 404 pour le français **ET** l'anglais. | Attente d'un contenu anglais bloquant en pleine implémentation de la PR. |
| adversarial | CA 1 (Général) | Le critère vérifiant l'absence de redirection (désactivée dans AD-2) est manquant. | Ajouter `**Alors** aucune balise meta refresh n'est générée à la racine.` | Hugo pourrait générer une redirection implicite non souhaitée à la racine, enfreignant NFR-12 (zéro JS / redirections pures). |

#### Lentilles éditoriales : Structure et Prose

*Lecture de la forme : document de type **Prompt / Task Definition (Functional)**. L'objectif est la précision technique sans ambiguïté (calibrage : lecteur LLM).*

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| structure | `En tant que Daniel, recruteur qui lit en anglais (UJ-2), je veux passer d'une page française à la même page en anglais par un lien visible, afin de lire le site dans ma langue.` | `PRESERVE` | Conservé pour garantir le contexte narratif de la user story. |
| structure | `- [ ] i18n/fr.yaml et i18n/en.yaml existent, en clés snake_case anglaises.` | `CUT` | Répète une règle d'architecture existante (AD-3) et n'apporte aucune instruction spécifique à la story. (Gain : ~12 mots) |
| prose | `avec un <link rel="alternate" hreflang> par traduction et hreflang="x-default" vers le français.` | `avec une balise <link rel="alternate" hreflang> par traduction et une balise distincte pointant vers le français avec hreflang="x-default".` | Clarification de la syntaxe attendue, évitant de laisser penser que `x-default` est combiné dans la même balise. |
| prose | `le lien s'intitule « English » sur une page FR et « Français » sur une page EN, avec hreflang et lang, sans JavaScript ni ancre.` | `le lien s'intitule « English » sur une page FR et « Français » sur une page EN ; il porte les attributs hreflang et lang, sans utiliser de JavaScript ni transmettre d'ancre.` | Séparation claire des attributs HTML structurels et des comportements fonctionnels attendus. |
| prose | `chacune avec un lien vers l'accueil de sa langue et un vers l'autre accueil` | `chacune contenant un lien vers l'accueil de sa langue et un lien vers l'accueil de l'autre langue` | Levée de l'ambiguïté de la formulation « l'autre accueil ». |

*Résumé éditorial : 2 recommandations (structure) et 3 recommandations (prose). Si elles sont acceptées, elles améliorent la précision d'implémentation pour le LLM développeur tout en optimisant très légèrement la concision de la spec.*

#### À trancher avant d'implémenter

- **Textes de la 404 :** Fournir les textes (titre i18n et phrase d'explication) pour le français **ET** pour l'anglais. Le concepteur doit également confirmer s'il y a un lien de "Contact" à proposer si l'utilisateur est perdu.
- **Génération de la 404 EN :** S'assurer de la stratégie Hugo pour bien générer `public/en/404.html` (qui n'est pas forcément actif par défaut sans configuration adéquate) afin que la directive nginx `error_page 404 /en/404.html;` définie par AD-13 puisse la trouver.
- **Comportement du sélecteur sur les brouillons :** Confirmer le repli du sélecteur de langue en rendu de travail : doit-il explicitement rediriger vers l'accueil de l'autre langue si la traduction d'une page profonde n'existe pas encore (cf. règle AD-2) ?

### Triage des constats (17/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — sélecteur testé sur l'accueil seulement, ancres non purgées | **retenu** | le critère vise une page profonde ; AD-2 dit déjà « il ne transmet aucune ancre » |
| A2 — `hreflang` en URL absolues | **retenu, déjà vrai** | `baseof.html` emploie `.Permalink`, donc absolu ; le critère doit l'exiger explicitement |
| A3 — 404 dans la langue de sa page | **retenu** | même en-tête et même pied de page que les autres pages, dans la bonne langue (`DESIGN.md`, section 404) |
| A4 — clés i18n réellement ajoutées | **retenu** | la check-list demande les clés du sélecteur et de la 404, pas seulement l'existence des fichiers |
| A5 — nom accessible du sélecteur | **retenu en partie** | `DESIGN.md` fixe le lien : « English » sur une page FR, avec `lang` et `hreflang`. Le texte du lien **est** son nom accessible ; rien à ajouter, mais le critère le dit |
| A6 — attribut `dir` | **question à Arnaud** | ni AD-2 ni `DESIGN.md` ne l'imposent ; les deux langues sont `ltr` |
| A7 — sélecteur sans traduction | **retenu** | AD-2 le dit déjà (« sans traduction, il mène à l'accueil de l'autre langue ») ; devient un critère, testable en rendu de travail |
| A8 — génération de `public/en/404.html` | **retenu** | à prouver par l'exécution : Hugo ne produit pas forcément la 404 de chaque langue |
| A9 — texte de la 404 dans les deux langues | **retenu** | question posée à Arnaud, FR **et** EN |
| A10 — aucune redirection à la racine | **retenu** | critère ajouté : aucun `meta refresh`, ce que `disableDefaultSiteRedirect` doit garantir |
| Structure — couper la ligne i18n | **refusé** | elle ne répète pas AD-3 : elle fixe *où* vivent les libellés de cette story. Reformulée pour porter les clés attendues |
| Prose — trois reformulations | **retenues** | critères réécrits |

Deux constats hérités de la story 2.2 rejoignent cette story : le `hreflang="x-default"` construit par `index . 0` (échec brut si une page n'a pas de version française) et les arguments de `dev.sh` sans cas de test.

## Ce qui est livré

| Fichier | Rôle |
| --- | --- |
| `i18n/{fr,en}.yaml` | libellés d'interface en `snake_case` anglais : `language_switch`, `home_link`, `home_link_other_language`, `not_found_title`, `not_found_message` |
| `layouts/_partials/language-switch.html` | un seul lien vers la page équivalente, `lang` et `hreflang`, sans JavaScript ; repli vers l'accueil de l'autre langue sans traduction |
| `layouts/_partials/site-header.html` | marque et sélecteur — rien de plus : « À propos » et « Contact » viendront avec leurs pages |
| `layouts/404.html` | titre, phrase, lien d'accueil, lien vers l'accueil de l'autre langue |
| `layouts/baseof.html` | `x-default` par `range` au lieu d'`index … 0` (constat reporté par la story 2.2) |
| `scripts/tests/test-build.sh` | cas ajouté pour les arguments transmis à `hugo server` (second constat reporté) |

### Deux faits établis par l'exécution, non par lecture

- **Hugo produit bien `public/en/404.html`** : le relecteur doutait qu'une 404 par langue soit générée sans configuration particulière. Elle l'est, avec le `disableKinds` et les langues déjà en place. La directive nginx d'AD-13 trouvera donc sa page.
- **Le repli du sélecteur tient** : sur une page sans traduction (rendu de travail, impossible en production par FR-20), le lien mène à l'accueil de l'autre langue et le build ne casse pas — y compris le `x-default`, qui aurait échoué en `index … 0`.

### Un défaut vu dans le rendu, pas dans la spec

Les textes validés donnaient, sur la 404 française, **deux liens intitulés « English »** menant ailleurs l'un que l'autre : celui de l'en-tête (le sélecteur, vers `/en/404.html`) et celui du corps (vers `/en/`). Deux liens de même nom et de destinations différentes sur une même page tombent sous WCAG 2.4.4, et sur une page d'erreur « English » promet la même page en anglais, qui n'existe pas.

Décision d'Arnaud : un libellé distinct pour le lien du corps, nouvelle clé `home_link_other_language` — « Accueil en anglais » / *Home in French*. Le backlog et `EXPERIENCE.md` portent la correction et sa raison ; les quatre libellés de cette story y passent de « à valider » à « décidé ».

### Essais

| Vérification | Résultat |
| --- | --- |
| Pages produites en production | `/`, `/en/`, `/404.html`, `/en/404.html` |
| 404 FR et EN | titre, phrase, deux liens, `<html lang>` correct, en-tête dans la bonne langue |
| `hreflang` | une balise par traduction plus `x-default`, **toutes en URL absolues** |
| Sélecteur | « English » sur `/`, « Français » sur `/en/`, avec `lang` et `hreflang`, aucune ancre transmise |
| Page sans traduction | sélecteur vers l'accueil de l'autre langue, build intact |
| `meta refresh` | aucun |
| `scripts/tests/run.sh` | **84 cas** (83 avant la story) |

## Revue du code

### 17/09/2026 — `bdc966a` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 27. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 91bfff6f6f1db171565ac820

##### Revue de code (Lentilles BMAD et Couche projet)

###### Lentille : edge-case-hunter
* Dans `layouts/_partials/language-switch.html`, le sélecteur utilise `index . 0` sur `.Translations`. Si le site s'étend à trois langues ou plus, il pointera toujours vers la première langue de la liste (inattendu au-delà de deux langues). NON BLOQUANT
* Dans `layouts/_partials/language-switch.html`, le repli sur page sans traduction itère sur `.Site.Home.AllTranslations` sans `break`. La variable `$target` sera écrasée jusqu'à la dernière langue (comportement prévisible pour deux langues). NON BLOQUANT
* Dans `layouts/baseof.html`, le `x-default` utilise un `range` filtré sur "fr". Si une page n'a pas de traduction française (ex: brouillon anglais), la balise est ignorée de manière sûre, remplaçant l'échec de build dû à `index . 0`. NON BLOQUANT

###### Lentille : verification-gap
* Les critères complexes comme l'absence de `meta refresh` et d'ancrage (assurée nativement par `.RelPermalink`) ont été correctement vérifiés manuellement et documentés, et le test unitaire pour `dev.sh` valide bien la présence de ses arguments. NON BLOQUANT

###### Couche propre au projet
* Les critères d'acceptation de la story sont satisfaits (liens `hreflang` en URL absolues avec `.Permalink`, sélecteur sans ancre, 404 localisées avec le pied de page correspondant et un lien d'accueil distinctif pour se conformer au WCAG). NON BLOQUANT
* Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge. NON BLOQUANT
* Skill, procédure et script concordent : l'ajout du test n'introduit aucune discordance avec l'existant. NON BLOQUANT
* Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-2, AD-3 : libellés extraits dans `i18n/` en snake_case anglais, zéro JavaScript). NON BLOQUANT
* Dans le script shell (`scripts/tests/test-build.sh`), aucune erreur ne passe en silence (utilisation correcte de `run`, `assert_eq` et `assert_contains` sous `set -euo pipefail`). NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 27 (`bdc966a`, verdict `pass`) :

- **`index . 0` sur `.Translations` et repli sans `break`** : les deux constats ne mordent qu'à partir d'une **troisième** langue. Le site est bilingue par décision (AD-2, PRD) et rien ne prévoit d'en ajouter une. **Acceptés tels quels**, plutôt que reportés : reporter donnerait une dette qui ne sera jamais due. Si une troisième langue apparaissait un jour, `_partials/language-switch.html` est l'endroit à reprendre — et le relecteur note lui-même que le comportement reste prévisible à deux langues.
- Le reste du rapport confirme les critères, l'absence de secret et la cohérence avec AD-2 et AD-3.

## Reporté

Aucun constat reporté.
