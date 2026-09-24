# Story 10.1 : Home page pitch

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.1.

## Revue de spec

### 24/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `f5ba49c`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 60ae0971cfc35ae19fc9980c

##### Rapport de revue (bmad-review)

###### 1. Lentille adverse (Adversarial) & Lacunes de vérification (Verification Gaps)

**Constat 1 : Validation de l'écran 390×844 px en l'absence de cas publiés**
- **Condition de déclenchement :** Le critère d'acceptation 2 exige de voir, sur le premier écran sans défilement, "le lien de son premier cas" sous le premier poste.
- **Conséquence potentielle :** Dans l'Epic 10, la story 10.1 intervient avant la mise en ligne des cas (les cas 01, 02 et 05 ne quitteront l'état de brouillon que lors des stories 10.4 à 10.7). Par conséquent, en rendu de production, aucun lien de cas ne s'affichera (selon FR-2). En rendu de travail, le lien s'affichera mais sera obligatoirement précédé du marqueur "Brouillon" (selon AD-5), ce qui modifie la hauteur du bloc et fausse le test de dépassement. Le critère est donc factuellement invérifiable en l'état sans désaligner l'environnement.
- **Classement : BLOQUANT**

**Constat 2 : Dépassement potentiel de la hauteur par le texte réel**
- **Condition de déclenchement :** Le développeur doit intégrer un texte final ("pitch FR et EN, trois phrases chacun") dans un espace vertical strict (844 px) partagé avec d'autres éléments.
- **Conséquence potentielle :** La taille de l'écran est fixe. Si les trois phrases fournies par Arnaud sont trop longues, le texte poussera le premier poste et son lien hors du viewport. Le troisième critère d'acceptation (et FR-25) interdisant strictement au développeur de toucher aux gabarits, ce dernier se trouverait dans l'incapacité de satisfaire à la fois l'intégration du texte et le critère de non-défilement. La spec manque d'une consigne de résolution en cas de dépassement.
- **Classement : BLOQUANT**

###### 2. Lentille structurelle et cas limites (Structure / Edge Cases)

**Constat 3 : Vérification littérale de la localisation sur la page anglaise**
- **Condition de déclenchement :** Le critère 1 stipule que sur les pages `/` **et** `/en/`, le pitch suit le titre du site et la chaîne « Basé en France ».
- **Conséquence potentielle :** Une lecture stricte du critère imposerait au développeur ou au relecteur de vérifier la présence exacte de la mention en français sur la page d'accueil anglaise. Cela contredit directement les exigences de bilinguisme (FR-20) et la parité linguistique.
- **Classement : BLOQUANT**

###### 3. Lentille rédactionnelle (Prose)

**Constat 4 : Clarté de l'intention et de la valeur ajoutée**
- **Condition de déclenchement :** Formulation du "En tant que / Je veux / Afin de".
- **Conséquence potentielle :** L'objectif visé par la fonctionnalité ("comprendre en trente secondes ce qu'Arnaud fait bien") et la contrainte éditoriale ("trois phrases chacun") sont parfaitement clairs et ne laissent aucune ambiguïté. L'ordre des idées est logique.
- **Classement : NON BLOQUANT**

---

##### À trancher avant d'implémenter

- **Environnement de test du premier écran :** Comment le développeur doit-il valider la présence du lien du premier cas sur l'espace restreint de 390×844 px, sachant qu'aucun cas n'est encore publié à l'étape 10.1 et que le rendu de travail ajoute un encombrant marqueur "Brouillon" ? Doit-il utiliser des données bouchonnées en local ?
- **Longueur du pitch :** Si le texte de trois phrases fourni par Arnaud s'avère trop long pour maintenir le premier poste dans le premier écran mobile, le développeur doit-il rejeter le contenu (et demander une version plus courte) ou est-il exceptionnellement autorisé à ajuster le CSS ?
- **Localisation du critère 1 :** Confirmer que la mention à vérifier sur `/en/` n'est pas « Basé en France » mais bien son équivalent traduit (ex. : « Based in France »).

## Revue du code

### 24/09/2026 — `e7b220a` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 108. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b1f1374cf5c993c3d0eae53f

##### Rapport de revue (bmad-review)

###### 1. Lentille Cas limites (Edge-Case Hunter)
Aucun chemin non géré, cas limite ou défaut de gestion de branchement n'a été trouvé. Le contenu ajouté (fichiers de contenu statique et mise à jour de documentation) est déclaratif et ne présente pas de logique conditionnelle ou de flux d'exécution.

###### 2. Lentille Lacunes de vérification (Verification Gaps)
Aucune lacune de vérification n'a été trouvée. La modification relève de l'ajout de texte éditorial pur (non comportemental au sens de l'exécution du code) et la vérification visuelle/métrique a été dûment consignée manuellement dans les artefacts de la story.

##### Couche propre au projet

**Constat 1 : Oubli d'une entrée de version globale**
- **Condition de déclenchement :** La règle globale utilisateur exige obligatoirement que l'assistant ajoute une entrée de version dans `docs/CHANGELOG.md` à chaque nouveau développement ou correctif. Le diff inclut un nouveau développement (le pitch de la page d'accueil) mais ne modifie pas ce fichier.
- **Conséquence potentielle :** Le journal des modifications du projet n'est pas tenu à jour avec la livraison de cette fonctionnalité, brisant la traçabilité.
- **Classement : NON BLOQUANT** (cette omission ne casse aucun critère d'acceptation de la story, ne fait fuiter aucune donnée privée ni secret, et ne concerne pas un script shell)

VERDICT: NON BLOQUANT — absence d'une entrée dans docs/CHANGELOG.md (règle globale), aucune autre réserve.

## Reporté

### Triage de la revue de spec, 24/09/2026

Les trois constats bloquants sont **retenus**, et la spec est corrigée dans cette PR.

**C1 — le premier écran demande « le début du premier poste avec le lien de son premier cas »,
invérifiable ici.** Fondé, et vérifié sur le site construit : le bloc « Parcours » **n'existe pas**
en production (`block-career` absent de `public/index.html`), parce que le seul poste écrit,
`position-chiliz`, reste `draft: true` jusqu'à ce que la story 10.2 lui donne sa période (AD-18).
Aucun cas n'est publié avant la 10.5. Le relecteur a raison aussi sur le contournement : mesurer
dans le rendu de travail ne vaudrait rien, le marqueur « Brouillon » d'AD-5 changeant la hauteur.

La spec sépare donc ce qui est vérifiable maintenant — identité, titre, `based_in`, pitch entier —
de ce qui revient à la story 10.2, qui publie le premier poste. Le critère nommait déjà la 11.11
comme seconde vérification ; il nomme maintenant aussi la première.

**C2 — rien ne dit quoi faire si le pitch déborde.** Fondé. La réponse est écrite : **c'est le
pitch qui est raccourci, jamais la mise en forme.** La contrainte est éditoriale, et la case
d'acceptation existe précisément pour interdire de traiter un problème de contenu par un correctif
de gabarit. Le cas ne s'est pas présenté (mesures ci-dessous), mais la règle est posée pour la fois
où il se présentera.

**C3 — « Basé en France » exigé littéralement sur la page anglaise.** Fondé, et la mesure le
confirme : `p.meta` porte « Based in France » sur `/en/`. Le critère désigne maintenant la clé
`based_in` et donne les deux valeurs, au lieu de citer la française.

**Précision ajoutée en écrivant.** La case « la PR ne touche que les deux fichiers de contenu » ne
peut pas être littérale : toute PR de story touche `sprint-status.yaml` et son fichier de story. Elle
vise les **sources du site** — ni gabarit, ni CSS, ni contrôle, ni traduction — et le dit désormais.

### Mesures

Émulation 390 × 844 px, densité 3, mobile, sur le site construit aux valeurs factices.

| Élément | FR | EN |
| --- | --- | --- |
| `h1.identity-name` | 134 → 194 | 134 → 194 |
| `p.site-title` | 202 → 249 | 202 → 249 |
| `p.meta` (`based_in`) | 257 → 276 | 257 → 276 |
| **pitch** | **309 → 572** | **309 → 572** |
| `img.portrait` | 134 → 224 | 134 → 224 |

Le pitch entier tient, photo comprise, avec **272 px de marge** avant le pli. Le bloc « Contact »
commence même à 612. Aucun ajustement de mise en forme n'a été nécessaire.

Typographie vérifiée octet à octet : `jugement` suivi de U+00A0 puis `:` en français,
`judgment:` sans espace en anglais — ce que DESIGN.md demande et que C24 contrôle.

### Triage de la revue de code, 24/09/2026

Verdict `pass`. Les deux lentilles de code ne trouvent rien — le changement est du texte éditorial,
sans branche ni flux. Un seul constat propre au projet, **réfuté sur preuve déjà établie**.

**« Oubli d'une entrée dans `docs/CHANGELOG.md`. »** La règle existe, mais pas ici : elle vit dans
les mémoires globales du compte relecteur (`~/.gemini/GEMINI.md`), où elle décrit un autre projet
d'Arnaud dont la CI génère un changelog. Ce projet n'a ni `docs/CHANGELOG.md` ni
`docs/deployment-notes/`, et aucune de ses règles ne les demande. C'est la deuxième apparition du
même constat en deux PR — il reviendra sur chacune tant que cette mémoire ne sera pas restreinte au
projet qu'elle vise. Le point 20 d'AGENTS.md et `deferred-work.md` portent déjà le constat, sa
source et ses deux pistes de correction.

Le relecteur l'a lui-même classé non bloquant cette fois, alors qu'il en avait fait un verdict
bloquant à la PR n° 107. Même règle, même projet, deux classements : une raison de plus de la
traiter à la source plutôt qu'au cas par cas.
