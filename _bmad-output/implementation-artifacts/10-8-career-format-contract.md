# Story 10.8 : Career format contract

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.8.

Première des trois stories ajoutées à l'epic 10 par la proposition de changement du 02/10/2026
(`sprint-change-proposal-2026-10-02.md`, arbitrages Q1 à Q8 d'Arnaud). L'en-tête de l'epic (point 21)
précise que 10.8 et 10.9 ne sont pas des stories d'intégration : elles préparent le terrain de la
10.10, qui intègre le contenu rédigé par Arnaud.

Elle écrit le contrat de rédaction des postes, `docs/format-parcours.md`, sur le modèle de
`docs/format-cas.md` — ce qu'Arnaud a appelé « le prompt du CV » —, et la passation privée
`docs/private/handoff-redaction-postes.md`, tirée du premier jet
`docs/private/drafts/contexte-des-missions-v0.md` (dépôt privé, `cdf95ff`).

## Revue de spec

### 02/10/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `ff9c422`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 5bf47cbd836dfd1589e8c2f4

##### Revue Adversarial
BLOQUANT : Le critère exigeant de commiter `docs/private/handoff-redaction-postes.md` dans le dépôt privé sans que la PR publique n'en recopie le contenu est invérifiable par le relecteur externe (via le skill `llm-review`). Ce relecteur ne lira que le diff public et ne pourra pas attester de l'existence de ce fichier privé, ce qui bloquera la validation de la story au moment de la fusion.
BLOQUANT : La liste des clés du front-matter précisant ce qui se traduit ou non omet des clés indispensables d'un poste : le rôle (`role` ou `title`), la période (`period`) et la localisation (`location`). Cela laisse une ambiguïté qui empêche de rédiger un modèle de contrat complet et exact.
BLOQUANT : L'ambiguïté soulevée dans les questions (le contrat couvre-t-il aussi les entrées de `content/education/` ?) crée une faille : si les formations sont incluses, le renvoi global aux règles et identifiants d'AD-18 sera en contradiction avec le format exigé, car une formation n'utilise pas nécessairement des clés comme `stack` ou `setup`.

##### Revue Structure
NON BLOQUANT : La consigne indiquant que les notions non technologiques (DEX, APIs, CI...) vont "dans le périmètre" est structurellement placée dans le bloc "Étant donné la clé `stack`", alors qu'elle définit le contenu attendu dans le corps du document Markdown (le périmètre de la mission) et non dans le front-matter.

##### Revue Prose
NON BLOQUANT : L'expression « la ligne "Renvoi" de l'architecture » est trop vague pour permettre au développeur d'identifier avec certitude la phrase exacte formulée au futur dans `ARCHITECTURE-SPINE.md` qu'il doit corriger (bien que la référence au point 8 d'AGENTS.md soit correcte).
NON BLOQUANT : La règle de rédaction imposant qu'« un sujet jamais mis en production [soit] présenté comme tel » a du sens pour un projet spécifique (un cas), mais est sémantiquement maladroite lorsqu'elle est transposée littéralement au périmètre global d'un poste.

##### À trancher avant d'implémenter
- Le contrat de rédaction (`docs/format-parcours.md`) s'applique-t-il exclusivement aux postes professionnels, ou doit-il également couvrir les entrées de formation (`content/education/`) ?
- Comment la réalisation du commit privé de `handoff-redaction-postes.md` doit-elle être prouvée au relecteur LLM de la pull request publique pour ne pas bloquer la fusion ?
- Quelles sont les consignes de traduction exactes (à traduire ou ne pas traduire) pour les clés manquantes du front-matter des postes : rôle (`role`), période (`period`) et localisation (`location`) ?

### Tri des constats (02/10/2026, auteur Claude)

| # | Constat | Décision |
|---|---|---|
| A1 | Le commit privé de la passation est invérifiable par le relecteur externe (BLOQUANT) | **Retenu comme fait, réfuté comme blocage.** Le relecteur ne voit jamais `docs/private/` : c'est voulu (AGENTS.md, point 2), et ce critère n'est pas de son ressort. Il est vérifié par l'orchestrateur, qui ouvre le dépôt privé avant la fusion (point 22). La preuve écrite ici sera le SHA du commit privé — un SHA ne révèle rien du contenu —, et rien d'autre. |
| A2 | `role`, `period`, `location` (et `label`) absents de la liste « traduit / non traduit » (BLOQUANT) | **Retenu.** Exact : la spec ne nomme que les clés non traduites et `sector`. Le contrat donnera la liste entière, clé par clé, en citant sa source unique : la liste des métadonnées non traduites des postes dans C3 (`scripts/checks/parity.sh`, rôle `position`), dont le commentaire explique pourquoi `label`, `role`, `period` et `location` se traduisent. Il la cite, il n'en devient pas une seconde source (point 19). |
| A3 | Inclure la formation ferait mentir le renvoi à AD-18 (BLOQUANT) | **Question posée à Arnaud** (celle de la spec). Si la formation entre, elle a sa propre section, avec les clés qu'AD-18 lui donne (`kind`, `order`, `draft`…), sans `stack` ni `setup`. |
| S1 | Les notions non technologiques relèvent du corps, pas de la clé `stack` | **Retenu.** Le contrat le dit dans la section du corps, et la section de la `stack` y renvoie. |
| P1 | « La ligne Renvoi de l'architecture » est vague | **Pris acte.** C'est la puce « **Renvoi** » de la section « `docs/format-cas.md` v0.4 » d'`ARCHITECTURE-SPINE.md` (ligne 776 avant la PR n° 129) ; la PR la cite précisément. |
| P2 | « Un sujet jamais mis en production » est maladroit pour tout un poste | **Retenu.** Le contrat le formule pour ce que le périmètre décrit : un chantier du poste jamais mis en production le reste dans le texte (exemple vérifiable : le batch du cas 03 chez Chiliz). |

**Arbitrage d'Arnaud sur A3 (02/10/2026) : « seulement les postes ».** Le contrat couvre les seuls
fichiers `content/career/position-*` ; la formation (`content/education/`) reste décrite par AD-18,
sans contrat. Option écartée : une section de formation dans le même contrat.

## Implémentation

### Ce qui est écrit

- **`docs/format-parcours.md`** (nouveau, v0.1) : le contrat de rédaction des postes, sur le modèle de `docs/format-cas.md`. Il ne couvre que les postes (arbitrage d'Arnaud sur A3). Emplacement et identifiants par **renvoi** à la liste figée d'AD-18, jamais recopiée ; `translationKey` égal au nom de fichier, ancre du poste, jamais renommé. Front matter **clé par clé** dans un tableau (A2) : traduites `label`, `role`, `sector`, `period`, `location` ; non traduites `translationKey`, `company`, `via`, `company_url`, `setup`, `stack`, `track`, `order`, `draft`. Le tableau **cite** la liste du rôle `position` de C3 (`scripts/checks/parity.sh`, fonction `untranslated`) comme source unique, et dit que la story 10.9 y ajoute `stack`, absente aujourd'hui. Période : texte de l'auteur, aucune durée nulle part — ni clé, ni texte de période, ni corps (Q2) —, formes lisibles de C25, période d'un cas comprise dans celle de son poste. Stack : le projet entier, termes de `data/stack.yaml` seulement, identiques FR/EN, ajout au vocabulaire avant usage, règle des versions avec la scission Zend Framework 1 / 2 énoncée comme règle et attribuée à la story 10.10. Les notions qui ne sont pas des technologies sont dites dans la section du **corps**, et la section de la stack y renvoie (S1). Corps : périmètre complet, 3 à 6 phrases, première personne, voix du jugement décrite sans citer de fichier privé, clients finaux nommés s'ils sont publiables (Q3), rendu dans un `<details>` « à partir de la story 10.9 ». Parité FR/EN, `[TODO: …]` et `draft: true`, huit règles de rédaction dont la règle 6 formulée pour un chantier du poste avec l'exemple du batch du cas 03 (P2), modèle vide.
- **`docs/format-cas.md` v0.5** : la règle « seules les technologies citées dans le cas » reste ; une phrase renvoie à `format-parcours.md` pour la stack d'un poste ; la puce du rattachement ajoute la période comprise dans celle du poste ; l'arborescence d'exemple dit que le poste est rédigé selon son contrat (elle disait « créé avec le site »).
- **`ARCHITECTURE-SPINE.md`** : AD-18 (Binds et puce « Contrat de rédaction ») renvoie au contrat au présent, avec sa portée limitée aux postes ; AD-3 aussi ; la puce « **Renvoi** » de la section « `docs/format-cas.md` v0.4 » passe au présent, l'introduction de cette section dit la v0.5 et une puce « v0.5 » la décrit ; la structure initiale et la ligne de statut sont à jour.
- **PRD** (§0 et la ligne de FR-25) : les deux mentions au futur de `format-parcours.md` passent au présent (balayage du point 13, `grep -rn "format-parcours"`).
- **Passation privée** `docs/private/handoff-redaction-postes.md` : commitée dans le dépôt privé seulement, commit **`3b7e314`**. Son contenu n'est recopié ni ici, ni dans la PR, ni dans un commit public.

### Décisions prises en implémentant

- **`status: draft`, `version: 0.1`.** C'est ainsi que `format-cas.md` a été publié la première fois (`git log --follow docs/format-cas.md` : `f5d8783`, v0.1, `draft`) ; il n'est passé `validated` qu'à la v0.4, après le contrôle de préparation. Le contrat des postes suit le même chemin : il sera validé une fois éprouvé par la rédaction des quatorze fichiers (story 10.10).
- **Titre de la section « `docs/format-cas.md` v0.4 » gardé.** La section décrit le changement de la v0.4 et elle est citée sous ce nom par la décision 26 et par le critère de cette story ; la renommer casserait ces renvois. Son introduction dit la version courante (v0.5) et une puce décrit la v0.5.
- **Aucune durée dans le corps non plus.** Q2 dit « aucune durée affichée », et le corps est affiché ; une durée écrite à côté des bornes est la seconde source qui a produit l'incohérence « quatre ans » de Chiliz.
- **Laissés hors de cette story, et pourquoi** : l'en-tête de `data/stack.yaml` (« stack des cas ») appartient à la story 10.10, dont un critère le récrit ; `AGENTS.md` (ligne du cas pilote, « v0.4 ») et la table du `README.md` (contrat des cas seul) ne disent rien de faux sur le contrat des postes et relèvent de l'orchestrateur — signalés, non modifiés.

### Fichier aîné : `docs/format-cas.md` (point 19)

| Section ou règle de l'aîné | Dans `format-parcours.md` | Pourquoi |
|---|---|---|
| Front matter du document (`title`, `version`, `status`, `updated`) | repris | même forme ; v0.1 `draft`, comme l'aîné à sa naissance |
| Introduction : contrat, emplacement fixé par l'architecture | adapté | AD-18 seul (pas d'AD-4) ; portée limitée aux postes, formation exclue |
| Principe : un fichier par cas et par langue | repris | un fichier par poste et par langue |
| Noms de fichiers en anglais, kebab-case | repris | `position-<id>.<langue>.md` |
| Cas groupé : `group` égal au dossier | sans objet | un poste n'a pas de groupe |
| Rattachement au parcours (`position`) | adapté | vu depuis le poste : il ne liste pas ses cas, c'est le cas qui pointe vers lui |
| Identifiants figés par AD-18, renvoi sans recopie | repris | même renvoi, et aucun poste hors de la liste sans modifier AD-18 |
| Suffixe `.fr.md` / `.en.md`, même `translationKey` | repris, renforcé | `translationKey` = nom de fichier (C19) et ancre du poste |
| URL publiques | remplacé | un poste n'a pas de page : ni `title` ni `slug` |
| Clés anglaises identiques, valeurs traduites sauf `stack` | adapté | tableau clé par clé ; C3 (`parity.sh`) cité comme source unique, sans le recopier |
| Note sur `featured` supprimée | sans objet | aucun historique de clé supprimée pour un poste |
| Vocabulaire de la stack : `data/stack.yaml` fait foi, non recopié | repris | même renvoi |
| « Seules les technologies citées dans le cas » | inversé | la stack d'un poste est le projet entier (Q4) ; l'aîné garde sa règle et renvoie ici |
| Une technologie s'ajoute au vocabulaire avant usage | repris | « dans la même PR ou une PR antérieure » |
| Rubriques de `data/rubrics.yaml`, mêmes sections FR/EN (C3, C4) | sans objet | le corps d'un poste n'a pas de rubriques |
| « Contexte » ne répète pas l'encart | adapté | le corps ne répète pas le front matter, ni une ligne « Stack : … » |
| Section absente de la source omise, pas reconstituée | adapté | devient « rien d'inventé » et « une question ouverte reste un `[TODO]` » |
| Pas de titre de niveau 1 ; rien au-delà de `###` (C4) | adapté, plus strict | aucun titre : le poste est déjà un `h3` sur l'accueil |
| Matériel vivant dans le texte (shortcode) | sans objet | un poste n'a pas de `live_material` |
| Sections des sources non publiées (statut, matériel vivant, deux dialectes) | adapté | annotations d'un premier jet, notes d'entretien, déroulé d'un cas |
| Marqueurs `[TODO: …]`, `draft: true` tant qu'il en reste | repris | plus le renvoi à C5 |
| Règle 1 : rien d'inventé | repris, élargi | ajoute « ni durée », et « probable » n'est pas un fait |
| Règle 2 : reformulation minimale, première personne | repris | |
| Règle 3 : mêmes faits FR/EN, l'anglais ajoute du contexte | repris | développé dans une section « Parité FR/EN » |
| Règle 4 : aucun code propriétaire | adapté | aucun code du tout : le corps est de la prose |
| Règle 5 : aucune information personnelle | repris | précise que `location` n'est jamais la ville de résidence |
| Règle 6 : jamais mis en production, explicite | adapté (P2) | formulée pour un chantier du poste ; exemple du batch du cas 03 |
| Règle 7 : ton factuel | repris | |
| Règle 8 : aucune personne physique nommée | repris | les clients finaux publiables sont nommés dans le corps (Q3) |
| Règle 9 : le texte se lit sans le matériel vivant | adapté | « le corps se lit sans les cas, et les cas sans lui » |
| Modèle vide | repris | avec `stack` jamais vide, puisque C19 refusera une clé présente mais vide |

Ajouts sans équivalent dans l'aîné : la section « Période » (Q2, formes de C25, inclusion de la période d'un cas), la section « Parité FR/EN », et le rendu dans un `<details>` (Q1).

### Vérifications

- `bash scripts/tests/run.sh scripts/tests/test-docs-headings.sh` : 4 cas réussis.
- Documents relus en entier après modification (point 8) : `docs/format-parcours.md`, `docs/format-cas.md`, AD-18 et la section « `docs/format-cas.md` v0.4 » d'`ARCHITECTURE-SPINE.md`.

## Revue du code

- **Complément de l'orchestrateur (`9399adc`)** : `AGENTS.md` (ligne du cas pilote, « v0.4 » → « v0.5 », et une phrase sur le contrat des postes) et la table du `README.md` (une ligne pour `docs/format-parcours.md`) ont été mis à jour dans cette PR, après le commit de revue : un numéro de version périmé est une phrase fausse (points 8 et 13 d'AGENTS.md). La puce ci-dessus, écrite avant, ne vaut plus pour eux.

### 02/10/2026 — PR n° 130, `gemini-3.1-pro-high`, SHA `9399adc`, verdict `pass`

Rapport recopié de la PR (le script ne l'a pas ajouté : il a tourné depuis le dépôt principal, sur une autre branche, la copie de travail de la story n'ayant pas de `.env`). Une première relance n'avait rien publié : le relecteur avait tenté une commande shell.

llm-review sha=9399adc263b74a888954741fb49602df74aa9f57 base=dev model=gemini-3.1-pro-high verdict=pass

_Revue par `scripts/llm-review.sh` : `agy --mode plan`, copie isolée hors du dépôt au SHA relu, sans `.env` ni `docs/private/` ; skill `bmad-review` appliqué par le relecteur (angles : edge-case-hunter, verification-gap, plus la couche propre au projet). Fichiers créés ou modifiés par le relecteur dans la copie : aucun._

JETON: 74ea2d3d15284f64f084c42c

### Revue BMAD

#### Lentille : edge-case-hunter
NON BLOQUANT : Condition de déclenchement : Un poste utilise seulement `label` sans `company`. Conséquence potentielle : Bien que le contrat autorise l'absence de `company` si `label` est présent, les gabarits Hugo pourraient lever une erreur ou avoir un affichage défectueux s'ils s'attendent à ce que la clé `company` soit toujours définie.
NON BLOQUANT : Condition de déclenchement : Un poste couvre plusieurs statuts successifs (ex: freelance puis employé) ou plusieurs localisations. Conséquence potentielle : Les clés `setup` et `location` n'acceptent chacune qu'une seule valeur, ce qui obligera le rédacteur à choisir une valeur principale et à simplifier l'historique de la mission.

#### Lentille : verification-gap
NON BLOQUANT : Condition de déclenchement : Le contrat `docs/format-parcours.md` impose des règles de présence conditionnelle (« `company` ou `label` » et « `location` ou `setup` »). Garde manquante : Aucun script de contrôle (comme C19) ne vérifie que l'une ou l'autre de ces clés est présente. C19 ne fait que refuser une clé vide, ouvrant la possibilité de commiter un fichier de poste sans employeur ni lieu.
NON BLOQUANT : Condition de déclenchement : La nouvelle clé `stack` est introduite pour les postes. Garde manquante : Son contrôle de parité n'est prévu que pour la story 10.9 (C3), ce qui crée un trou de vérification temporaire garantissant son identité stricte entre les versions FR et EN.

### Couche propre au projet
NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits. Le contrat de rédaction des postes (`docs/format-parcours.md`) est défini et aligné avec le format des cas, et la documentation d'architecture a été mise à jour (à noter une simple inexactitude dans les notes de l'auteur affirmant avoir laissé `AGENTS.md` et `README.md` intacts, alors que le diff montre à juste titre leur mise à jour).
NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
NON BLOQUANT : Skill, procédure et script concordent (aucun script ou skill n'a été modifié dans cette story).
NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (AD-3 et AD-18 ont été correctement mis à jour pour renvoyer au contrat).
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (aucun script shell n'a été modifié).

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue (auteur Claude)

| # | Constat | Décision |
|---|---|---|
| E1 | Un poste avec `label` sans `company` pourrait casser le gabarit | **Réfuté, preuve à l'appui.** `_partials/position.html` lit `company` puis le remplace par `label` s'il existe ; `position-earlier-career` est publié sans `company`, avec `label`, et se rend. C19 exige l'un des deux (`scripts/checks/content.sh:249-255`). |
| E2 | `setup` et `location` n'ont qu'une valeur ; une mission à plusieurs cadres devrait choisir | **Pris acte, sans changement.** C'est le modèle d'AD-18 : un poste a un cadre. Une mission qui change de cadre devient deux postes, ce qui demande de modifier la liste figée d'AD-18 — aucun poste du parcours n'est dans ce cas. `location` est un texte libre et porte déjà plusieurs villes (« Paris & Lyon »). |
| V1 | Aucun contrôle ne vérifie « `company` ou `label` » ni « `location` ou `setup` » | **Réfuté, preuve à l'appui.** C19 les vérifie tous les deux : `content.sh:249-255` (« ni company ni label ne nomme le poste ») et `content.sh:290-292` (« ni location ni setup »). |
| V2 | La parité de `stack` n'est contrôlée qu'à partir de la 10.9 | **Retenu comme fait, sans trou réel.** Aucun poste ne porte de clé `stack` avant la 10.10, qui dépend de la 10.9 : C3 compare `stack` avant que la première soit écrite. Le contrat le dit (« la story 10.9 l'ajoute »). |
| P1 | Critères satisfaits ; note de l'auteur inexacte sur `AGENTS.md` et `README.md` | **Retenu** : la note datait d'avant le commit `9399adc`. Corrigée par le complément ci-dessus, en ajout. |
| P2 | Aucune donnée privée ni secret | **Pris acte** ; garde-fou rejoué par l'orchestrateur sur `origin/dev..origin/feat/10-8-career-format-contract`, code 0. |
| P3 | Skill, procédure et script concordent | **Pris acte** (aucun script ni skill modifié). |
| P4 | Cohérent avec AGENTS.md et AD-3, AD-18 | **Pris acte.** |
| P5 | Aucune erreur silencieuse dans un script | **Pris acte** (aucun script modifié). |

**Passation privée vérifiée par l'orchestrateur** : `docs/private/handoff-redaction-postes.md` existe dans le dépôt privé, commit `3b7e314`.
