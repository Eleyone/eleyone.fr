# Story 10.2 : Career positions

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.2.

## Parcours du fichier aîné

Point 19 d'AGENTS.md : le fichier aîné est `content/career/position-chiliz.{fr,en}.md`, écrit par la
story 2.7 et seul poste existant avant celle-ci. Ses clés, une par une, et ce que les six nouveaux
postes en font. L'exercice n'est pas rhétorique : il a fait apparaître trois écarts, notés en fin de
section.

| Clé de l'aîné | Reprise par les nouveaux postes ? | Pourquoi |
| --- | --- | --- |
| `translationKey` | **Oui, les sept.** | Identité du poste (AD-18) : égale au nom de fichier, jamais en `[TODO`, c'est par elle que C3 rapproche FR et EN et que les cas se rattachent (`position:`). |
| `company` | **Oui, six sur sept.** | `position-earlier-career` ne l'a pas : « Parcours antérieur » n'est pas une société, et `company` n'est pas traduite (C3 la compare). C'est exactement le trou que la clé `label` comble. |
| `role` | **Oui, les sept.** | Exigée par C19. **Traduite** : l'aîné porte « Développeur backend senior » en FR et « Senior Backend Developer » en EN. Les six nouveaux suivent, en prenant l'intitulé de chaque CV dans sa langue. |
| `period` | **Oui, les sept.** | Exigée par C19. Traduite aussi : « Janvier 2020 – juin 2022 » / « January 2020 – June 2022 ». Elle est la raison du `draft: true` de l'aîné, et la raison du `draft: true` qui reste sur `position-ton-pote-le-geek` (voir plus bas). |
| `setup` | **Oui, les sept.** | `employee` pour les postes salariés, `agency` pour les trois prestations Modis, `ton-pote-le-geek` pour le septième. Non traduite (C3 la compare), valeurs closes par C19. |
| `track` | **Oui, les sept.** | `main` pour six, `parallel` pour `position-ton-pote-le-geek` — c'est cette clé, et elle seule, qui remplit le bloc « En parallèle » de `home.html`. |
| `order` | **Oui, les sept.** | 1 à 6 dans `main`, 1 dans `parallel`. Unique par `track`, brouillons compris (C19). L'ordre d'affichage ne vient d'aucune date. |
| `draft` | **Oui, les sept.** | Six passent à `false` — c'est l'objet de la story. Le septième reste `true`, faute de période dans le CV. |
| Le commentaire au-dessus de `draft` | **Non, sauf un.** | Il explique *pourquoi* le fichier est en brouillon (« tant que la période manque »). Six postes n'étant plus en brouillon, le commentaire disparaît avec sa cause ; il est **réécrit** sur `position-ton-pote-le-geek`, dont la cause, elle, subsiste. Un commentaire qui survit à sa cause est la faute du point 8. |

Clés qu'a l'un des nouveaux et que l'aîné n'a pas — donc qu'aucune lecture de l'aîné ne pouvait
signaler, et que seul AD-18 donne :

| Clé | Qui la porte | Pourquoi |
| --- | --- | --- |
| `label` | `position-earlier-career` seul | Nom affiché d'un poste qui n'est pas une société ; **traduite**, donc hors de la liste que C3 compare (AD-18, 24/09/2026). |
| `location` | Les six postes `main` | Ville de travail ou mode de travail. L'aîné ne l'avait pas et tenait par son seul `setup` (C19 exige l'un ou l'autre) ; le CV donne les deux, on écrit les deux. Traduite : « Lyon » / « Lyon, France », comme l'écrit chaque CV. |
| `via` | Mister Auto, April Technologies 2017, Orange | Société de prestation, non traduite. Rendue par l'i18n `via_label` : « prestation Modis » / « via Modis ». |
| `company_url` | `position-ton-pote-le-geek` seul | Fait du nom un lien (story 5.2). Non traduite. |

Trois écarts trouvés par ce parcours, qu'une simple copie de l'aîné aurait laissés passer :

1. **`role` est traduite, `company` ne l'est pas** — l'aîné le montre (deux intitulés, un seul nom de
   société). Un poste écrit « par symétrie » aurait eu six `role` identiques dans les deux langues.
2. **L'aîné n'a pas de `location`** : sa seule lecture aurait produit six postes sans ville de
   travail, conformes à C19 (le `setup` suffit) et pourtant amputés de ce que le CV donne.
3. **Le commentaire de `draft`** : recopié tel quel sur un poste publié, il aurait affirmé qu'une
   période manque là où elle est écrite deux lignes plus haut.

## Revue de spec

### 24/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `2818326`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 710339aa580ddd4b6a799d07

Voici le rapport de revue de la spécification de la story 10.2, exécuté en suivant le processus `bmad-review` avec les lentilles demandées.

##### 🔍 Lentille Adversarial (Critique et cas limites)

- **Lignes de contexte EN manquantes pour le parcours antérieur et récent**
  - **Emplacement :** `Couvre` (FR-22) et `Prérequis de contenu`
  - **Condition de déclenchement :** La spécification indique couvrir FR-22 (qui exige des lignes de contexte en anglais pour April Technologies, Orange, Systeme.io, NCS/CS et Ton Pote le Geek). Cependant, les prérequis ne demandent à Arnaud que la ligne de contexte pour Ton Pote le Geek, oubliant les quatre autres.
  - **Correction suggérée :** Ajouter aux prérequis de contenu les lignes de contexte EN pour April Technologies, Orange, Systeme.io et NCS/CS.
  - **Conséquence potentielle :** Le développeur devra soit inventer ce texte en anglais (ce qui viole formellement NFR-10), soit omettre ces lignes (ce qui fait échouer FR-22).
  - **Classification :** BLOQUANT

- **Omission de Systeme.io et NCS/CS dans les identifiants**
  - **Emplacement :** `Identifiants`
  - **Condition de déclenchement :** La spécification explique comment intégrer CGI dans `position-earlier-career`, mais oublie totalement Systeme.io et NCS/CS, pourtant explicitement listés dans FR-22 comme nécessitant une ligne de contexte.
  - **Correction suggérée :** Préciser que `position-earlier-career` doit également inclure les expériences Systeme.io et NCS/CS.
  - **Conséquence potentielle :** Ces deux postes seront complètement oubliés lors de la rédaction du fichier, faussant le CV public et empêchant l'implémentation complète de FR-22.
  - **Classification :** BLOQUANT

- **Contradiction avec le flux de travail de suivi de sprint**
  - **Emplacement :** `Critères d'acceptation`, 3ème case à cocher
  - **Condition de déclenchement :** "La PR ne touche que `content/career/`" interdit techniquement de modifier `sprint-status.yaml` et le fichier markdown de la story, ce qui est pourtant une obligation absolue du projet (règle 4 et verrou `sprint-consistency`).
  - **Correction suggérée :** Reformuler en "La PR ne touche que `content/career/` (hors fichiers de suivi de sprint et d'artefacts)".
  - **Conséquence potentielle :** Le développeur s'abstiendra de mettre à jour le statut du sprint pour respecter cette contrainte, ce qui bloquera la fusion de la PR au moment du passage des verrous.
  - **Classification :** BLOQUANT

##### 🏗️ Lentille Structure (Organisation de la spec)

- **Ambiguïté sur le nombre de fichiers créés**
  - **Emplacement :** `Critères d'acceptation`, 2ème case à cocher
  - **Condition de déclenchement :** La consigne demande "Sept fichiers de poste, un par identifiant". L'architecture multilingue de Hugo impose d'avoir un fichier `.fr.md` et un fichier `.en.md` pour chaque poste.
  - **Correction suggérée :** Remplacer par "14 fichiers (7 identifiants × 2 langues)".
  - **Conséquence potentielle :** Le développeur pourrait créer 7 fichiers sans suffixe de langue, ou ignorer l'anglais, ce qui casserait le build Hugo ou le contrôle de parité C3.
  - **Classification :** BLOQUANT

##### ✍️ Lentille Prose (Clarté et ambiguïté)

- **Critère d'acceptation invérifiable**
  - **Emplacement :** `Critères d'acceptation`, 2ème bloc ("Étant donné le build de production...")
  - **Condition de déclenchement :** Le critère stipule que le corps "peut mentionner le même projet". L'utilisation du verbe "pouvoir" ("peut") rend le test optionnel et totalement invérifiable (le test passe que la mention soit présente ou non).
  - **Correction suggérée :** Remplacer par "le corps mentionne le même projet" (obligation claire) ou retirer ce point s'il ne s'agit pas d'un critère strict.
  - **Conséquence potentielle :** Une relecture humaine ou automatique ne saura pas trancher si l'absence de cette mention constitue un échec de la story.
  - **Classification :** BLOQUANT

- **Clarté sur l'état de l'affichage du poste April 2017 en production**
  - **Emplacement :** `Critères d'acceptation`, 2ème case à cocher
  - **Condition de déclenchement :** La spec liste Synolia, Mister Auto et Earlier Career comme devant s'afficher "sans cas rattaché". Elle omet de rappeler que le poste April Technologies 2017 apparaîtra également sans son cas en production au moment de l'Epic 10 (le cas 06 n'étant publié qu'à l'Epic 13).
  - **Correction suggérée :** Ajouter une petite précision pour rappeler qu'April Technologies 2017 sera aussi affiché sans cas sur le build de production pour l'instant, son cas étant encore en brouillon.
  - **Conséquence potentielle :** Légère confusion lors de la recette si le relecteur s'attend à voir le cas 06 sous le poste April dès cette story.
  - **Classification :** NON BLOQUANT

##### À trancher avant d'implémenter

- Fournir les lignes de contexte EN manquantes pour April Technologies, Orange, Systeme.io et NCS/CS afin de couvrir pleinement FR-22.
- Confirmer que Systeme.io et NCS/CS doivent bien être intégrés comme lignes de détail dans le poste consolidé `position-earlier-career`.
- Décider si la mention du projet CGI dans le poste d'April 2017 est une obligation stricte ("doit mentionner", à conserver dans les critères) ou une simple possibilité éditoriale (à retirer des critères d'acceptation).

## Gardes retirées, et ce qu'on a vu

Point 9 d'AGENTS.md : chaque cas nouveau a été rejoué **une fois la garde retirée**, pour le voir
échouer. Ce qui suit est constaté, pas déduit.

| Garde retirée | Cas rejoués | Observé |
| --- | --- | --- |
| `position.html` : les deux lignes `$name` et l'usage du nom dans le `h3`, remises à `.Params.company` | les quatre cas de `test-career-position.sh` | `position_label_seule_est_affichee`, `position_label_prime_sur_company` et `position_label_devient_un_lien_avec_company_url` **échouent** (code 1). Le lien du troisième ressort en `<a href=https://exemple.invalid/></a>` : un lien au texte vide, qu'aucun contrôle du dépôt ne voit — ni C12, qui ne lit que les liens internes, ni C11. `position_company_seule_est_affichee` **passe**, et c'est voulu : c'est la contre-épreuve, elle prouve que le gabarit affiche un nom, pas qu'il choisit le bon. |
| `content.sh` : le bloc « company **ou** label » supprimé, `["role", "period"]` laissé en place | `content_c19_company_ou_label` | **Échec** au deuxième pas : un poste sans `company` ni `label` passe (code 0 attendu 1). Le pas 1 (label seule acceptée) passe toujours — la relaxation et l'exigence sont deux gardes distinctes, et une seule des deux suffit à laisser le trou. |
| `content.sh` : `["role", "period"]` remis à `["company", "role", "period"]`, bloc conservé | `content_c19_company_ou_label` | **Échec** au premier pas : `C19 : company absent ou vide (AD-18)` sur les deux langues. La deuxième moitié de la garde est donc éprouvée elle aussi. |
| `parity.sh` : `label` **ajoutée** à la liste des clés non traduites d'un poste (la garde étant ici une absence, on l'éprouve en la comblant) | `parity_label_de_poste_se_traduit` | **Échec** : `clé non traduite « label » : "Parcours antérieur" en français, "Earlier career" en anglais`. Le second pas du même cas, qui vérifie que `company` reste comparée, passe dans les deux configurations — c'est sa fonction. |

Aucun cas nouveau ne passe sans sa garde, sauf les deux contre-épreuves désignées comme telles
ci-dessus, dont c'est le rôle.

## Arbitrages, et ce qui a résisté

### Bloquant, à trancher par Arnaud — la période de Ton Pote le Geek n'existe dans aucune source

Le CV ne date pas cette activité. Ni `cv-fr.pdf` ni `cv-en.pdf` ne portent de période sous « En
parallèle — Ton Pote Le Geek (freelance) » : les six autres lignes d'expérience en ont une, celle-ci
n'en a pas. Rien ailleurs ne la donne non plus — `content/about.{fr,en}.md` mentionne l'activité sans
date, et le cas 01 porte « 2025–2026 », qui est la période **du projet**, pas celle de l'activité.

Or C19 exige une `period` non vide sur un poste publié. Les trois issues :

1. **Inventer une période** — refusé : NFR-10 et la consigne de la story l'interdisent.
2. **Publier sans période** — impossible : C19 refuse, et AD-18 lie explicitement `[TODO: période]`
   à `draft: true`.
3. **Laisser le poste en brouillon avec `[TODO: période]`** — retenu. C'est le mécanisme qu'AD-18
   prévoit pour exactement ce cas, celui-là même que la story 2.7 avait employé sur
   `position-chiliz`. Le commentaire du fichier nomme la donnée manquante et sa cause.

**Conséquence, à connaître avant de relire le build de production : le bloc « En parallèle » n'y
apparaît pas.** Il apparaît dans le rendu de travail, avec Ton Pote le Geek, son lien vers
`tonpotelegeek.fr` et sa ligne de contexte anglaise — vérifié. Dès qu'Arnaud donne la période, le
poste se publie en changeant deux lignes et rien d'autre.

Le `role` de ce poste, lui, vient du CV : « (freelance) », dans les deux langues, devient
`role: "Freelance"`. Il n'est pas en `[TODO`.

### Écarts assumés entre la consigne et le CV

- **`location` est écrite dans la langue de son fichier.** AD-18 le demande (« facultatif, dans la
  langue du fichier ») et chaque CV l'écrit à sa façon : « Lyon » en français, *Lyon, France* en
  anglais ; « Full remote » contre *Fully remote* ; « Paris & Lyon » contre *Paris & Lyon, France*.
  Le tableau de la consigne n'avait qu'une colonne ; suivre le CV de chaque langue est ce que
  demandent AD-18 et la règle « les intitulés anglais viennent de `cv-en.pdf` ».
- **« groupe PSA » n'est pas dans `company`.** Le CV écrit « Mister Auto (groupe PSA) » et *Mister
  Auto (PSA Group)* : la mention se traduit, or `company` est comparée entre les langues par C3. Le
  nom reste « Mister Auto » des deux côtés, et le groupe passe dans le corps, où il se traduit.
- **La mission CGI n'est pas datée « 2013–2014 ».** AD-18 et le texte de la story l'écrivent ainsi,
  mais **le CV ne date pas CGI** : il date l'employeur, « FHM Solutions (2011-2014) », et liste CGI
  parmi ses missions. Le corps de `position-earlier-career` reprend la ligne du CV telle quelle —
  la mission CGI y figure bien comme ligne de détail, ce qu'exige le critère —, sans ajouter deux
  dates qu'aucune source ne porte. Si les dates 2013–2014 sont sûres, Arnaud les dira et la ligne
  les prendra.
- **Les intitulés anglais ont été alignés sur `cv-en.pdf`.** `position-chiliz.en.md` portait
  « Senior backend developer » depuis la story 2.7 ; le CV écrit *Senior Backend Developer*. La
  story fait du CV la source unique, la casse suit.
- **`company` de Ton Pote le Geek s'écrit « Ton Pote le Geek »**, avec un `l` minuscule : c'est
  l'écriture d'AD-18, d'`i18n/{fr,en}.yaml` et des pages « À propos ». Les CV écrivent « Ton Pote Le
  Geek ». Une seule écriture sur le site valait mieux qu'une septième variante ; c'est celle qui y
  était déjà.

### Une phrase rendue fausse par cette story, corrigée dans sa PR

Le tableau des contrôles d'`ARCHITECTURE-SPINE.md` (ligne de C19) disait « `period`, `company` et
`role` non vides pour un poste ». AD-18 venait d'être amendé avec `label` ; cette ligne-là ne
l'était pas, et elle aurait décrit un contrôle qui n'existe plus (point 8 d'AGENTS.md). Elle dit
maintenant « `period` et `role` non vides […] plus `company` **ou** `label` ».

## Revue du code

### 24/09/2026 — `efcc30f` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 109. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 00544747fd7aa14b24d259b6

Voici le rapport de revue de la PR n° 109 (branche `feat/10-2-career-positions`), incluant les lentilles `edge-case-hunter` et `verification-gap`, ainsi que les vérifications spécifiques au projet.

##### Lentille : edge-case-hunter

Aucun cas limite non géré n'a été identifié. Le comportement de repli entre `company` et `label` est exhaustif et robuste : les configurations où l'une, l'autre, ou les deux clés sont absentes, vides, ou en `[TODO:` dans un brouillon sont correctement tamisées par le gabarit et par le contrôle C19.

##### Lentille : verification-gap

- `location` : `scripts/checks/parity.sh` (fonction `untranslated`)
- `trigger_condition` : La clé `via` (société de prestation) n'est pas incluse dans les clés comparées par l'agent de parité.
- `guard_snippet` : Ajouter `"via"` à la liste : `position:  ["company", "setup", "track", "order", "draft", "company_url", "via"],`
- `potential_consequence` : Une divergence sur le nom de l'ESN (ex: faute de frappe, casse différente) entre la VF et la VA passera le contrôle en silence.
- `gap_shape` : `broken-verification-gap`
- `consumer` : Le contrôle de parité C3 et le gabarit `_partials/position.html`.
- `evidence` : Le fichier de story (`10-2-career-positions.md`) documente explicitement `via` comme étant « non traduite ». Son absence de la liste `untranslated` fait échapper cette clé à la règle de parité.
BLOQUANT

##### Couche projet

**Critères d'acceptation**
Les 14 fichiers de postes sont présents, rattachés et conformes. Les clés suivent scrupuleusement la logique du CV. La clé `label` est intégrée selon le strict nécessaire, et ses cas de tests garantissent qu'elle comble bien l'exigence `company`. L'intention fonctionnelle est intacte.
NON BLOQUANT

**Données privées et secrets**
Aucune ville de résidence ou coordonnée personnelle n'est exposée (seules les villes de travail sont présentes). Le code n'introduit aucun secret et ne modifie aucun affichage qui pourrait faire fuiter l'URL de la forge.
NON BLOQUANT

**Concordance skill, procédure et script**
Aucun skill ou procédure n'est modifié par cette PR, le contrôle ne s'applique pas.
NON BLOQUANT

**Cohérence avec AGENTS.md et architecture**
Les ajustements historiques et les rectifications portées à `ARCHITECTURE-SPINE.md` concordent parfaitement avec le rendu et le document de sprint. La liste d'identifiants de AD-18 a été respectée.
NON BLOQUANT

**Erreurs silencieuses dans les scripts**
Les scripts de tests (notamment `test-career-position.sh`) évitent le piège courant du masquage des codes de retour : la déclaration `local html` et l'affectation `html=$(page "$1")` sont bien sur deux lignes distinctes. Le flag `set -euo pipefail` interceptera sans faille toute commande `hugo` ou sous-shell qui échouerait.
NON BLOQUANT

VERDICT: BLOQUANT — Omission de la clé « via » dans l'agent de parité C3, annulant la vérification d'une donnée explicitement spécifiée comme non traduite.

### 24/09/2026 — `94b0c4d` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 109. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 06023f40196d2a6da01c1959

##### Revue de code BMAD

###### 🔍 Lentille : edge-case-hunter

- **Localisation :** `scripts/checks/content.sh` (règle C19) et `layouts/_partials/position.html`
- **Condition de déclenchement :** La clé `company` est valide, mais la clé `label` est présente et composée uniquement d'espaces (ex: `"   "`).
- **Garde ou correctif manquant :** La règle `C19` ne lève une erreur que si les DEUX clés (`company` et `label`) sont simultanément invalides (`select(($vides | length) == 2)`). Elle ne vérifie pas qu'un `label` présent est valide indépendamment de `company`. Or, dans Hugo, la fonction `with .Params.label` évalue toute chaîne de longueur non nulle (y compris des espaces) comme vraie. Les tests dans `test-content.sh` ne couvrent pas ce cas car ils suppriment systématiquement `company` avant de tester un `label` composé d'espaces.
- **Conséquence potentielle :** Le gabarit va utiliser le `label` (constitué d'espaces) à la place de la `company` valide. Le titre du poste sera vide sur le site de production, et le contrôle C19 l'aura laissé passer en silence.
BLOQUANT

###### 🛡️ Lentille : verification-gap

- **Localisation :** `_bmad-output/implementation-artifacts/10-2-career-positions.md` (Triage de la revue de code) et `scripts/checks/parity.sh`
- **Condition de déclenchement :** Omission avérée de la clé `via` dans la liste `untranslated` de l'agent de parité.
- **Garde ou correctif manquant :** L'auteur affirme dans son rapport de triage que `scripts/checks/parity.sh` contient déjà `via` dans sa liste et rejette le constat du relecteur précédent (lignes 331 du diff : `scripts/checks/parity.sh:34 porte position: ["company", "via", ...]`). Pourtant, le diff de la PR (ligne 853 du patch) expose clairement : `position: ["company", "company_url", "setup", "track", "order", "draft"]`. La clé `via` y est totalement absente. L'auteur a mené un test manuel faussé (ou lu un autre fichier) et a annulé à tort une faille réelle.
- **Conséquence potentielle :** Une erreur de traduction sur la société de prestation passera toujours au vert dans la CI, laissant une faille non couverte dans la vérification de parité FR/EN.
BLOQUANT

##### Couche projet

- **Les critères d'acceptation de la story sont satisfaits :** Les 14 fichiers ont été créés et rattachés correctement, la mécanique de priorité `label` / `company` a été implémentée avec un nouveau cas de test, et la correction historique sur la mission CGI a été effectuée dans toutes les sources. L'intention de la story n'est pas vidée.
NON BLOQUANT

- **Aucune donnée privée ni secret :** Aucune ville de résidence ou adresse personnelle n'est exposée ; seules les localisations de travail stipulées par le CV le sont. Le code ne modifie aucun mécanisme de CI et n'introduit aucun token.
NON BLOQUANT

- **Concordance skill, procédure et script :** Cette PR ne modifie ni les documentations de procédures ni les définitions de skills, évitant ainsi toute désynchronisation.
NON BLOQUANT

- **Cohérence avec AGENTS.md et architecture :** La décision `AD-18` a été mise à jour en parfaite cohérence avec le choix de la clé `label` et les détails du parcours CGI. L'arbitrage documenté pour le statut `draft: false` sans date de "Ton Pote le Geek" respecte les pratiques édictées.
NON BLOQUANT

- **Aucune erreur ne passe en silence dans les scripts shell :** Le script `test-career-position.sh` sépare rigoureusement la déclaration des variables locales de l'affectation par sous-shell (ex: `local html; html=$(page "$1") || ...`), ce qui évite de masquer les codes d'erreur sous `set -euo pipefail`. L'appel à la compilation de test s'effectue via le wrapper `run` qui capture correctement les erreurs.
NON BLOQUANT

VERDICT: BLOQUANT — La règle C19 laisse passer un label vide écrasant une company valide, et la clé "via" est toujours absente de parity.sh suite à une erreur de vérification humaine de l'auteur.

### 24/09/2026 — `ee488af` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 109. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 86b76353e6ca89605a947d22

##### Revue BMAD

###### Lentille : Edge-Case Hunter
Aucun cas limite non géré n'a été identifié. Les cas d'omission de `company`, d'utilisation de `label`, de clés vides ou ne contenant que des espaces, et de brouillons contenant `[TODO` sont robustement traités et bloqués par C19 lorsque nécessaire.

###### Lentille : Verification-Gap
No verification gaps found.

##### Couche projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (quatorze fichiers de poste bien créés, clés fidèles au CV, remplacement par `label` opérationnel et couvert par les tests, mentions Modis et CGI correctement localisées).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur et aucun secret n'est commité (seules les localisations de travail figurent).
- NON BLOQUANT : Skill, procédure et script concordent (aucun skill ou procédure n'est modifié par cette PR).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-18 a été scrupuleusement respecté et mis à jour pour statuer sur l'usage de `label` et les détails de la mission CGI).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (les affectations par sous-shell sont bien séparées des déclarations `local`, ou passées directement à des fonctions d'assertion qui échoueront bruyamment si le sous-shell renvoie un contenu vide suite à une erreur).

VERDICT: NON BLOQUANT — aucune

### 24/09/2026 — `45b0fba` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 109. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a1e699773f7bc4b2d8273f38

Voici le rapport de revue de la spécification et du code de la PR n° 109, exécuté selon le processus `bmad-review`.

##### 🔍 Lentille : edge-case-hunter
Aucun cas limite non géré n'a été identifié. Les embranchements liés à la mécanique de sélection entre `company` et `label` sont exhaustivement traités. Le correctif garantit qu'une clé définie mais vide (ou faite uniquement d'espaces) est correctement refusée et ne peut plus écraser la valeur valide d'une autre clé en silence.

##### 🛡️ Lentille : verification-gap
Aucune faille de vérification trouvée (No verification gaps found). Les scénarios ajoutés dans `test-career-position.sh`, `test-content.sh` et `test-parity.sh` verrouillent fermement les comportements introduits : priorité du `label`, création de liens avec `company_url`, traitement d'une clé vide et règles de parité pour les traductions.

##### Couche projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits (14 fichiers de poste bien créés, clés fidèles au CV, remplacement par `label` opérationnel) et l'intention de la story n'est pas vidée.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur privé et aucun secret n'est commité (seules les localisations de travail figurent, et les tests utilisent l'URL de test inoffensive `exemple.invalid`).
- NON BLOQUANT : Skill, procédure et script concordent (aucun skill ou procédure n'est impacté ou modifié par cette PR).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (l'architecture `ARCHITECTURE-SPINE.md` / AD-18 a été correctement mise à jour pour statuer sur l'usage de la clé `label` et les détails historiques de la mission CGI).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (toutes les affectations de variables via des sous-shells, comme `fr=$(poste_de ...)`, sont réalisées après et séparément des instructions de déclaration `local`).

VERDICT: NON BLOQUANT — aucune

### 24/09/2026 — `f63584d` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 109. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 6128108187217d33b38d04a6

**BMad Review**

Plan de revue :
- Classe de contenu : diff
- Lentilles exécutées : edge-case-hunter, verification-gap

##### 🔍 Lentille : Edge-Case Hunter

- **location** : `scripts/checks/content.sh` (3ème bloc de la règle C19, ajout de la vérification de clé vide)
- **trigger_condition** : `label` vaut `[TODO...]` sur un poste publié avec une `company` valide (ou inversement)
- **guard_snippet** : `select(($value | blank) or (($f.draft != true) and ($value | todo_value)))` (remplace `select($value | blank)` dans le 3ème bloc)
- **potential_consequence** : La règle C19 ne signale pas spécifiquement ce champ incomplet (déléguant le blocage au contrôle global C5)

##### 🛡️ Lentille : Verification-Gap

- **location** : `scripts/tests/test-content.sh:1162` (pas 5 de `case_content_c19_company_ou_label`)
- **trigger_condition** : Le test supprime `company` avant de valider le comportement avec `label="[TODO...]"`
- **guard_snippet** : Ajouter un cas de test vérifiant `label="[TODO...]"` tout en conservant une `company` valide
- **potential_consequence** : Le test passe car les DEUX clés sont jugées invalides, masquant la faille de C19 qui laisserait passer un `[TODO...]` isolé
- **gap_shape** : `broken-verification-gap`
- **consumer** : `scripts/checks/content.sh` (règle C19)
- **evidence** : L'utilisation explicite de `del(.files[1].front_matter.company)` dans le scénario de test.

##### Couche projet

NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (les 14 fichiers sont bien créés, la priorité de `label` sur `company` est implémentée).
NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (seules les villes de travail sont exposées, conformément au CV).
NON BLOQUANT : Skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure (aucune documentation modifiée par ce diff).
NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (AD-18 est respectée et les mises à jour documentaires sont justes).
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail (les affectations par sous-shell comme `html=$(page "$1")` sont correctement séparées de la déclaration `local`).

VERDICT: NON BLOQUANT — La faille de détection spécifique d'un `[TODO...]` isolé par la règle C19 est mitigée par le verrou global C5, empêchant toute compromission de la production.

## Reporté

### Triage de la revue de spec, 24/09/2026

Cinq constats bloquants. **Trois sont retenus, deux sont réfutés sur pièce** — et les deux réfutés
portent sur le même malentendu : le relecteur a lu « FR-22 » dans la ligne « Couvre » et en a déduit
que tout FR-22 se jouait ici.

#### Réfuté — « lignes de contexte EN manquantes pour April, Orange, Systeme.io et NCS/CS »

FR-22 dit exactement où chaque ligne atterrit, et ce n'est pas l'accueil :

> « Chaque repère […] a sa ligne de contexte dans la version EN **du cas concerné ou de l'accueil** :
> April Technologies (**cas 06**), Orange (**cas 05**), Systeme.io (**cas 01**), NCS/CS (**cas 02**),
> Ton Pote le Geek (**cas 01 et bloc « En parallèle »**). »

Quatre des cinq appartiennent donc aux stories des cas — 10.5 pour la 02, 10.6 pour la 01, 10.7 pour
la 05, epic 13 pour la 06. Seul Ton Pote le Geek a une part sur l'accueil, par le bloc « En
parallèle », et c'est précisément le seul prérequis que la story demande. La spec était juste.

#### Réfuté — « Systeme.io et NCS/CS oubliés des identifiants »

**Ce ne sont pas des employeurs.** Vérifié dans le CV d'Arnaud, qui est la source de cette story :
ses sept lignes d'expérience sont Chiliz, Synolia, Mister Auto, April Technologies, Orange,
« Parcours antérieur » et « En parallèle — Ton Pote Le Geek ». Ni Systeme.io ni NCS/CS n'y figurent.
Systeme.io est la plateforme du cas 01, NCS/CS un repère du cas 02 — ce que FR-22 dit lui-même en
les rattachant à ces cas.

Les ajouter comme postes violerait AD-18, dont la table est close par une phrase explicite : « La
liste est complète : aucun autre poste n'est créé sans modifier cet AD. »

#### Retenu — la case « ne touche que `content/career/` » interdit le commit de statut

Fondé, et c'est la même faute qu'à la story 10.1 : toute PR de story touche `sprint-status.yaml` et
son fichier de story. La case vise les **sources du site** et le dit désormais.

#### Retenu — « sept fichiers » alors qu'il en faut quatorze

Fondé. Hugo veut `.fr.md` et `.en.md` par poste ; « sept fichiers » pouvait se lire comme sept
fichiers tout court, et C3 aurait refusé. La case dit « sept postes, soit quatorze fichiers ».

#### Retenu — « son corps **peut** mentionner » n'est pas vérifiable

Fondé : un critère dont le test passe que la chose soit là ou non n'est pas un critère. La mention
CGI reste obligatoire **là où AD-18 la place**, en ligne de détail de `position-earlier-career` ; la
répéter dans le corps du poste April 2017 devient une latitude éditoriale, écrite comme telle et
sortie des critères.

#### Trouvé en vérifiant, hors revue — la prestation Modis concerne trois postes, pas un

Le critère ne nommait que « le poste April Technologies de 2017 indique la prestation Modis ». Le CV
en donne **trois** : Mister Auto (2018–2020), April Technologies (2017) et Orange (2014–2016). Une
donnée du CV ne se perd pas parce qu'un critère ne l'a pas citée ; le critère demande maintenant que
chaque poste donné en prestation l'indique.

### Ce que la vérification de l'orchestrateur a changé, 24/09/2026

Le rapport du sous-agent a été confronté au dépôt avant d'être cru (point 21 d'AGENTS.md). Les
quatorze fichiers, les trois changements de code, les 554 cas et les 9 contrôles sont conformes à ce
qu'il annonçait, et l'ordre des postes a été relu sur la sortie construite dans les deux langues.
Trois choses ont bougé ensuite.

**La mission CGI : AD-18 l'écrivait à l'envers.** Le sous-agent avait refusé d'ajouter les dates
« 2013–2014 » qu'AD-18 réclamait, faute de source — et il avait repris la formulation du CV plutôt
que celle de l'AD. Arnaud a tranché le 24/09/2026 : « J'étais en prestation chez CGI pour l'ESN FHM
Solutions, et sur un projet CGI pour le compte d'April assurance. » AD-18 disait « chez April pour
le compte de CGI » : le sens était inversé, et les dates n'existaient dans aucune source. Corrigé
aux quatre endroits qui le portaient. Le contenu n'a pas bougé : il suivait déjà le CV.

**La période de Ton Pote le Geek.** Donnée par Arnaud le 24/09/2026 : février 2024. Le poste passe
de `draft: true` à publié, et le bloc « En parallèle » apparaît en production dans les deux langues,
avec son lien vers le site et sa ligne de contexte anglaise. Le commentaire du fichier dit d'où vient
la période, puisqu'elle ne vient pas du CV.

**Un doublon que seul le rendu montrait.** Publié, le poste affichait « Ton Pote le Geek /
**Freelance** · **Ton Pote le Geek** » : `role` et `setup` répétaient tous deux ce que `company`
disait déjà. Les six autres postes portent un vrai intitulé en `role` et un cadre en `setup`
— « Architecte technique / Chef de projet · Villeurbanne · ESN ». La valeur `ton-pote-le-geek` de
`setup` vient du **format des cas**, où l'encart « Contexte mission » doit nommer le cadre faute de
société ; sur un poste dont la société *est* Ton Pote le Geek, elle fait double emploi.

Corrigé avec les mots du CV, sans rien inventer : `role` devient « Automatisation et outils sur
mesure » / « Automation systems and custom tools » — la première ligne de la description dans chaque
CV — et `setup` devient `freelance`, ce que le CV écrit entre parenthèses. La ligne se lit désormais
comme les six autres. **Aucun cas de test ne voyait ce doublon** : il n'est ni une erreur de données,
ni une clé manquante, seulement deux champs justes qui se répètent. Il fallait lire la page.

### Triage de la revue de code, 24/09/2026

Verdict `block`, **un seul constat, entièrement réfuté** — et sa réfutation a failli échouer sur ma
propre mesure.

**« La clé `via` n'est pas incluse dans les clés comparées par l'agent de parité. »** La prémisse est
fausse : `scripts/checks/parity.sh:34` porte
`position: ["company", "via", "company_url", "setup", "track", "order", "draft"]`, et `via` y est,
**avant comme après cette story** — `git show dev:scripts/checks/parity.sh` le montre identique. Le
relecteur proposait d'ajouter une clé déjà présente.

Mais lire la liste ne prouve pas qu'elle agit. L'essai : `via: "Modis"` changé en `"MODIS"` dans
`position-orange.en.md`, puis C3 lancé. **Résultat :**

```
content/career/position-orange.en.md: clé non traduite « via » : "Modis" en français, "MODIS" en anglais
```

La garde tient.

#### Ce que ma première mesure disait, et pourquoi elle mentait

Le premier essai a rendu « parité FR/EN vérifiée » — C3 semblait inerte, et j'ai failli en conclure
que le relecteur avait raison sur le fond. La cause n'était pas la garde : **C3 lit le manifeste de
`build/work/`, et j'avais reconstruit `production`.** Il comparait donc deux manifestes antérieurs à
ma modification, où `via` valait « Modis » des deux côtés. Le contrôle avait raison de passer.

C'est la classe d'erreur que ce dépôt connaît déjà sous une autre forme — une mesure qui répond à
côté de la question posée. Ici elle aurait transformé un constat faux en correction inutile, et
surtout elle aurait laissé croire qu'une garde réelle ne servait à rien. **Un contrôle qu'on croit
inerte se relance sur l'entrée qu'il est censé voir, dans l'état où il la lit.**

Les autres constats du rapport sont des confirmations sans action : aucun cas limite trouvé, critères
satisfaits, aucune donnée privée, cohérence avec AGENTS.md et l'architecture.

### Triage de la seconde revue de code, 24/09/2026

Verdict `block`, deux affirmations, **toutes deux fausses** — et l'une d'elles désignait pourtant un
vrai trou, que la correction comble.

**« La clé `via` est toujours absente de `parity.sh` suite à une erreur de vérification humaine de
l'auteur. »** Non. `git show 94b0c4d:scripts/checks/parity.sh` — le commit exact que le relecteur a
reçu dans sa copie isolée — porte à la ligne 34 :

```
position:  ["company", "via", "company_url", "setup", "track", "order", "draft"],
```

Et la garde agit, ce que l'essai montre : `via: "Modis"` changé en `"MODIS"` dans
`position-orange.en.md` fait dire à C3 « clé non traduite « via » : "Modis" en français, "MODIS" en
anglais ». C'est la deuxième fois que ce constat est rendu sur cette PR, et la seconde fois il
accuse la vérification qui l'avait réfuté.

**« C19 laisse passer un label vide écrasant une company valide. »** Faux sur le mécanisme : un
`label` vide n'écrase rien, `with` traitant la chaîne vide comme fausse. Mesuré : avec
`company: "Orange"` et `label: ""`, la page affiche « Orange ».

**Mais l'intuition désignait un vrai trou, et il est comblé.** Une clé **présente mais vide** est une
faute de saisie, pas un choix — et elle est invisible, précisément parce que le gabarit retombe en
silence sur l'autre clé et que la page s'affiche juste. C'est le même tamis que celui posé le matin
même sur `state: ""` dans les questions ouvertes du suivi : deux caractères qui paraissent
renseignés. C19 refuse désormais `company` ou `label` présente et vide, chacune au même titre.

Le pas 6 du cas de test **affirmait le contraire** — il constatait le repli du gabarit et en
concluait que tout allait bien. Il est retourné, avec sa raison écrite, et un pas 7 couvre `company`
pour qu'aucune des deux clés n'hérite d'une tolérance que l'autre n'a pas. Lancée sans la garde, la
paire échoue.
