# Story 9.3 : Contact page and call to contact

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.3.

## Revue de spec

### 23/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `0cdb218`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 9a8e792d835240661ca5970a

### Rapport de revue de la spécification (Story 9.3)

Voici les constats relevés après passage de la spécification sous les lentilles *adversarial*, *structure* et *prose*.

#### Constats

- **BLOQUANT** — *(Adversarial)* **Omission du profil GitHub exigé par l'architecture**
  - **Localisation** : `Prérequis de contenu` et `1er critère d'acceptation`
  - **Déclencheur** : La spec liste uniquement `email` et `linkedin` pour le front matter de `content/contact.{fr,en}.md`.
  - **Garde-fou / Correction** : Ajouter `github` (l'URL du profil GitHub d'Arnaud) aux prérequis et au front matter, et l'inclure dans la liste de définitions.
  - **Conséquence** : Si implémentée telle quelle, la story contredira une exigence architecturale explicite. La décision AD-3 indique formellement que `github` a été ajouté au front matter le 13/09/2026 et doit être exploité.

- **BLOQUANT** — *(Adversarial / Structure)* **Appel à contact sur l'accueil invérifiable et non localisé**
  - **Localisation** : `3ème critère d'acceptation` ("Étant donné l'accueil FR et EN... Claire suit l'appel à contact")
  - **Déclencheur** : L'emplacement exact, le composant à utiliser ou la méthode d'insertion de l'"appel à contact" sur la page d'accueil ne sont pas du tout spécifiés.
  - **Garde-fou / Correction** : Préciser dans quel bloc de la page d'accueil cet appel s'insère (ex. sous le parcours, dans l'en-tête, dans un `aside`), et s'il s'agit d'un bouton ou d'un lien textuel standard.
  - **Conséquence** : Le critère est invérifiable structurellement. Le développeur devra inventer l'emplacement et l'apparence, au risque de contredire la conception de l'UX.

- **NON BLOQUANT** — *(Structure)* **Oubli de GitHub dans la question sur le garde-fou**
  - **Localisation** : `Questions à poser avant de commencer`
  - **Déclencheur** : La liste s'interroge sur le blocage éventuel de l'adresse mail et de LinkedIn par les motifs du garde-fou, mais omet l'URL GitHub.
  - **Garde-fou / Correction** : Ajouter `github` à la question posée, pour s'assurer que son URL n'est pas inopinément refusée par le script `check-private.sh`.
  - **Conséquence** : Simple risque de blocage lors du commit si l'URL GitHub venait à déclencher un motif.

- **NON BLOQUANT** — *(Prose)* **Apparence de libellé en dur pour le lien de l'en-tête**
  - **Localisation** : `2ème critère d'acceptation` ("il porte le lien « Contact »")
  - **Déclencheur** : Le libellé du lien est mentionné en dur sans faire référence au système de traduction.
  - **Garde-fou / Correction** : Préciser formellement que ce libellé doit provenir de `i18n/` (ex. `i18n/fr.yaml` et `i18n/en.yaml`).
  - **Conséquence** : Le développeur risque d'écrire le texte "Contact" directement dans le code du gabarit `site-header`, enfreignant la règle "aucun texte dans les gabarits" d'AD-3.

- **NON BLOQUANT** — *(Prose)* **Provenance des intitulés de la liste de définitions manquante**
  - **Localisation** : `1er critère d'acceptation` ("une liste de définitions dont les valeurs sont des liens")
  - **Déclencheur** : La spécification exige implicitement des clés pour cette liste (les termes ou balises `<dt>`, comme "E-mail", "LinkedIn"), mais ne dit pas d'où elles viennent.
  - **Garde-fou / Correction** : Spécifier si les intitulés doivent être déclarés dans `i18n/` ou s'ils sont injectés d'une autre manière.
  - **Conséquence** : Risque d'écrire des termes en dur dans le gabarit pour nommer les clés de la liste.

---

#### À trancher avant d'implémenter

- **Profil GitHub** : Faut-il intégrer le profil `github` sur la page Contact comme l'exige l'architecture (AD-3), et amender la spec pour l'y ajouter officiellement ?
- **Emplacement sur l'accueil** : Où et comment très exactement (composant, position dans le contenu Markdown ou dans `home.html`) doit s'afficher l'"appel à contact" sur l'accueil ?
- **Traductions** : Les intitulés de la liste de définitions (ex: "Email", "LinkedIn", "GitHub") doivent-ils faire l'objet de nouvelles clés dans `i18n/fr.yaml` et `i18n/en.yaml` pour respecter l'interdiction de texte en dur (AD-3) ?

### Triage des constats (23/09/2026)

**Retenu — la spec oublie `github`.** Confirmé par deux sources : AD-3 écrit que le front matter de `content/contact.{fr,en}.md` porte « `email`, `linkedin` et `github`, URL du profil GitHub d'Arnaud, identiques en FR et en EN ; `github` ajoutée le 13/09/2026, D-7 », et **C3 vérifie la parité sur ces trois clés** (`ARCHITECTURE-SPINE.md`, ligne du contrôle C3 : « contact : `email`, `linkedin`, `github` »). Sans la troisième, le contrôle de parité échouerait. La story la livre donc.

À noter : `DESIGN.md:478` ne nomme que deux termes (« Courriel », « LinkedIn »). Ce sont des exemples dans une phrase, pas une énumération fermée ; AD-3 et C3 font foi sur les clés.

**Refusé — « l'appel à contact est invérifiable et non localisé ».** Faux : `DESIGN.md:451` le place dans le tableau des zones de l'accueil, **dernier bloc avant le pied de page**, et en donne la forme — « titre de bloc, puis un lien », identique de sm à lg. Ce qui manque n'est pas l'emplacement mais la **validation des deux libellés**, `block_contact` et `contact_cta`, marqués « à valider par Arnaud » dans `EXPERIENCE.md:76-77` — ce que la spec de la story demande déjà dans ses propres questions.

**Non bloquants**

- *GitHub absent de la question sur le garde-fou* — retenu : les trois valeurs sont éprouvées contre la liste des motifs avant d'être commitées, pas seulement deux.
- *Libellé « Contact » de l'en-tête en dur* et *provenance des termes de la liste* — retenus comme précisions : tous les libellés passent par `i18n/`, comme partout ailleurs dans ce dépôt. Le rappeler dans chaque spec les ferait diverger ; l'appliquer suffit.

## Arbitrages d'Arnaud (23/09/2026)

Les deux libellés qu'`EXPERIENCE.md` portait « à valider par Arnaud » depuis le 13/09 sont tranchés :

- `contact_cta` : **« Me contacter » / « Get in touch »**, ce que l'UX proposait. « Get in touch » est l'usage anglais établi, pas un calque de la forme française.
- `contact_term_email` : **« Courriel » / « Email »**, ce que `DESIGN.md` nomme.

Le bloc garde « Contact » dans les deux langues. **Le lien ne répète pas son titre** : un lien lu seul par un lecteur d'écran doit dire ce qu'il fait, et `DESIGN.md` prévoit « titre de bloc, **puis** un lien ».

## Les trois valeurs

| | |
|---|---|
| Courriel | `hello@eleyone.fr`, celui du `.env` des mentions légales |
| LinkedIn | fourni par Arnaud |
| GitHub | `https://github.com/Eleyone`, déduit du dépôt public que le site lie déjà, confirmé par Arnaud |

**Les trois ont été confrontées à la liste des motifs interdits avant d'être écrites**, dans un dépôt jetable, sans jamais ouvrir la liste : toutes trois admises. C'est la question que la spec de la story posait, et elle valait d'être posée — un push refusé après coup aurait coûté un aller-retour.

La décision de les commiter n'est pas la mienne : le PRD la tranche le 13/09/2026 — « l'adresse mail et LinkedIn sont écrits dans le contenu, dans le dépôt » (NFR-9, FR-17).

## Implémentation

- `content/contact.{fr,en}.md` — `email`, `linkedin`, `github` en front matter, identiques dans les deux langues, **ce que C3 vérifie** ;
- `layouts/_shortcodes/contact-list.html` — la liste, qui **réutilise la classe `legal-list`** plutôt que d'en déclarer une jumelle : le dépôt a déjà payé quatre fois la copie d'une même grille ;
- `layouts/_partials/site-header.html` — le lien « Contact », par `site.GetPage`, avec `aria-current="page"` sur la seule page Contact ;
- `layouts/home.html` — l'appel à contact, dernier bloc avant le pied de page (`DESIGN.md`, tableau des zones) ;
- `i18n/{fr,en}.yaml` — six clés ; `ci/release-pages.txt` gagne `contact`.

Trois gabarits passent par `site.GetPage` : l'en-tête, le pied de page et l'accueil ne montrent rien tant que la page n'existe pas. C'est la règle qui protège C12, et un cas de test la vérifie en construisant un site **sans** page Contact.

### Ce que la mesure a trouvé

**Le lien LinkedIn débordait** : 367 px dans une boîte de 328, à 360 px de large. Une URL est un seul mot insécable. `overflow-wrap: anywhere` sur la valeur le fait passer à deux lignes — ce n'est pas de la césure, aucun tiret n'est ajouté, et `hyphens` reste à `manual` : C24 et UX-DR17 restent satisfaites. La règle protège aussi l'adresse de l'éditeur sur les mentions légales, et toute valeur longue à venir.

Vérifié que la page des mentions légales n'a pas bougé : 9 couples, écart terme/valeur de 0 px, termes à 261 et valeurs à 301, comme avant.

| | 1280 px clair | 360 px sombre |
|---|---|---|
| Débordement | non | non |
| Valeur débordant de sa colonne | non | non, après correctif |
| Cibles < 24 px hors phrase | 0 | 0 |
| Contraste du lien | — | 9,05 |

## Revue du code

### 23/09/2026 — `1bad9b9` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 100. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 79da201c95447f9a81132939

##### Rapport de revue (Code)

###### Lentille : Edge-case-hunter
Aucun cas limite non géré n'a été détecté. La gestion des clés de front-matter absentes, l'itération sécurisée sur les valeurs présentes et la construction des liens conditionnels (courriel vs URL) couvrent de manière exhaustive les chemins d'exécution du code de production (le composant `contact-list` lève proprement une erreur bloquant le build si aucune clé n'est trouvée, comme exigé par AD-3).

###### Lentille : Verification-gap et Couche Projet

- **BLOQUANT** — *(Verification-gap / Projet)* **Erreur silencieuse d'extraction faussant le test de l'en-tête**
  - **Localisation** : `scripts/tests/test-contact-page.sh`, fonction `entete()`
  - **Déclencheur** : L'expression `html=${html#*<header class=site-header>}` ne modifie pas la chaîne si la balise est absente de la page. La fonction retourne alors silencieusement la page entière sans lever d'erreur (laissant passer une anomalie en silence sous `set -euo pipefail`).
  - **Garde-fou / Correction** : Valider la présence de l'en-tête avant son extraction, par exemple avec `[[ "$html" == *"<header class=site-header>"* ]] || return 1`.
  - **Conséquence** : Un test vérifiant la présence du lien de contact dans l'en-tête (comme `case_contact_lien_dans_len_tete`) cherchera dans la page complète. Si l'en-tête disparaît, le test trouvera le lien dans l'encart d'appel à contact de la page d'accueil et passera à tort (faux positif de vérification).

- **NON BLOQUANT** — *(Projet)* **Critères d'acceptation satisfaits**
  - **Constat** : L'appel à contact sur l'accueil, la page de contact (avec ajout formel de GitHub comme exigé par la revue de spec), et l'absence stricte de formulaire répondent pleinement aux critères et à l'intention de la story 9.3.

- **NON BLOQUANT** — *(Projet)* **Aucune donnée privée ni secret**
  - **Constat** : Les informations ajoutées (courriel générique, liens LinkedIn et GitHub) sont expressément publiques et prévues par l'architecture. Aucun nom de serveur ou jeton secret n'est exposé.

- **NON BLOQUANT** — *(Projet)* **Cohérence skill, procédure et script**
  - **Constat** : La modification n'altère aucun script d'automatisation, skill ou procédure de l'Epic 0. L'outillage reste intègre.

- **NON BLOQUANT** — *(Projet)* **Conformité architecturale et AGENTS.md**
  - **Constat** : L'utilisation de `site.GetPage` pour vérifier que la page existe avant de rendre le lien protège le contrôle C12 (un lien vers une page absente en rendu de production). L'architecture est respectée à la lettre (tout le texte passe par `i18n`, réutilisation sémantique correcte de la classe `.legal-list`).

VERDICT: BLOQUANT — Une erreur logique d'extraction passe en silence dans la fonction entete() du script de test, compromettant la fiabilité de la vérification.

### Décision sur le constat (23/09/2026)

**Retenu, et il touche un défaut que je venais de corriger ailleurs.** `entete()` faisait `${html#*<header…>}` sans vérifier que le repère existe. Or cette forme rend la chaîne **inchangée** quand le motif manque : un en-tête disparu aurait renvoyé la page entière, et le cas du lien l'aurait trouvé dans l'appel à contact de l'accueil. Un faux positif de vérification.

C'est exactement la faute que `ordre_du_pied` de `test-legal-page.sh` venait de fermer, **reproduite dans le fichier écrit juste après**. Les points 18 et 19 d'AGENTS.md disent tous deux pourquoi : un constat d'une classe connue est un ordre de balayage, et une parade corrigée à un endroit ne se reporte pas d'elle-même.

**Le balayage a trouvé une seconde occurrence que le constat ne visait pas** : `test-cv-links.sh` comparait des positions de la même façon, depuis la story 7.2. Un lien de CV absent y passait pour un lien venant en dernier, et le cas d'ordre validait un pied de page amputé. Les deux fichiers affirment désormais la présence avant de comparer, et chacun a été éprouvé — en-tête supprimé, puis un seul CV lié : chacun échoue en nommant ce qui manque.

Les autres retraits de préfixe du dépôt ont été relus : `dotenv.sh`, `test-readme.sh`, `test-workflows.sh` et `test-shell-lib.sh` emploient `%%#*` pour retirer un commentaire, où l'absence de motif **doit** rendre la ligne entière. Ils sont corrects.

### 23/09/2026 — `db9edc9` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 100. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 791f5a32ebbb784b737b1efe

##### Rapport de revue (Code)

###### Lentille : Edge-case-hunter
Aucun constat de défaut. Le code couvre les cas limites avec rigueur : l'absence totale de clés de contact entraîne un arrêt net du build via `errorf`, l'absence partielle est gérée sans produire de balisage vide, et les appels vers la page Contact depuis l'en-tête et l'accueil (`with site.GetPage`) interdisent toute création de liens morts si la page venait à être absente.

###### Lentille : Verification-gap
Aucun constat de défaut. Le script `test-contact-page.sh` comble tous les besoins de vérification (présence des clés, absence stricte de formulaire, `aria-current`). Surtout, la faille de vérification silencieuse liée à l'extraction de chaînes (`${html#*...}`) a été supprimée.

###### Couche propre au projet
- NON BLOQUANT — Les critères d'acceptation de la story sont satisfaits (FR-3, FR-17) : l'appel à contact figure bien sur l'accueil, et la page Contact expose le courriel et LinkedIn (ainsi que GitHub) dans le contenu, strictement sans formulaire.
- NON BLOQUANT — Aucune donnée privée, aucun secret ni nom de serveur n'est exposé ; les liens et adresses email ajoutés sont précisément ceux destinés à être publics.
- NON BLOQUANT — Les scripts, procédures et skills demeurent parfaitement cohérents et intègres.
- NON BLOQUANT — Le changement est totalement aligné avec AGENTS.md et l'architecture : l'obligation de balayage d'une classe d'erreur (règle 18) a été scrupuleusement appliquée en propageant la correction de la faille Bash jusqu'au fichier `test-cv-links.sh`, et la grille CSS existante `.legal-list` a été judicieusement réutilisée.
- NON BLOQUANT — Dans les scripts shell, plus aucune erreur ne passe en silence : l'affirmation préalable de la présence d'un repère avant son extraction (`[[ $texte == *"$premier"* ]]`) garantit que toute absence inattendue fera échouer le script de test de manière explicite.

VERDICT: NON BLOQUANT — aucune

## Reporté
