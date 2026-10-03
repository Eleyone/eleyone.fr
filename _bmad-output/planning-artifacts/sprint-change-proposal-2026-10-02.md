---
title: "Proposition de changement : le contexte complet de chaque mission sur le CV"
status: approved
created: 2026-10-02
skill: bmad-correct-course
scope: moderate
source: "Constat d'Arnaud, 02/10/2026, pendant que la story 11.9 attend sa répétition"
---

# Proposition de changement : le contexte complet de chaque mission sur le CV

## 1. Résumé du problème

**Constat d'Arnaud (02/10/2026).** Sur le CV — la page d'accueil —, les postes qui portent des cas
manquent de contexte :

1. un cas ne couvre qu'**une décision**, pas l'intégralité de la mission ;
2. un cas cite **la part de la stack qu'il mobilise**, pas la stack complète du projet.

**Ce qu'il veut.** Pour chaque poste ou mission : client ou secteur, bornes temporelles, rôle,
**périmètre complet**, **stack complète du projet** ; FR et EN complets. La durée n'est pas affichée :
les bornes de la période permettent de la calculer (arbitrage Q2). Les pages de cas ne changent pas : elles
restent centrées sur leur décision et renvoient à leur mission par la clé `position` (AD-18).

**Type.** Exigence nouvelle de la partie prenante, révélée par la lecture du site assemblé : le CV
est complet depuis l'epic 10, et c'est en le lisant comme un recruteur qu'on voit le manque.

**Preuve, dans le code et les documents validés.** Le manque n'est pas un oubli de rédaction, il est
**décidé** :

- `layouts/_partials/position.html:37-48` : `{{ with $cases }}` affiche la liste des cas,
  `{{ else }}` le corps du poste. **Un poste qui a un cas publié n'affiche pas son corps.** Chiliz,
  Orange et Ton Pote le Geek ont un corps rédigé — invisible.
- La règle est écrite en cinq endroits validés : PRD FR-2 (« Le corps d'un poste […] ne s'affiche que
  si le poste n'a aucun cas mis en ligne »), AD-18 (ligne 411), DESIGN.md § cv-position (ligne 574) et
  décision 5, EXPERIENCE.md (ligne 134) et décision 10, UX-DR8.
- Aucun poste n'a de clé de secteur, de durée ni de stack ; la stack n'existe que dans l'encart d'un
  cas, et la règle de `data/stack.yaml` comme de `docs/format-cas.md` est « seules les technologies
  **citées dans le cas** ».
- AD-18 interdit « une période calculée ou inventée par un gabarit » ; la ligne NFR-10 de la carte
  des capacités dit « aucune période calculée ». La période reste le texte de l'auteur, et aucune
  durée n'est affichée (Q2).

## 2. Analyse d'impact

### Checklist de navigation du changement

| # | Point | État | Constat |
|---|---|---|---|
| 1.1 | Story déclenchante | [x] | Aucune : lecture du CV assemblé (epic 10 `done`), pendant la 11.9. |
| 1.2 | Problème | [x] | Exigence nouvelle ; la règle « corps seulement sans cas » la contredit. |
| 1.3 | Preuves | [x] | Voir § 1 : gabarit, cinq documents, absence de clés. |
| 2.1 | Epic courant (11) | [x] | Réalisable tel quel ; seul l'ordre 11.10 / 11.11 est concerné (§ 3). |
| 2.2 | Changements d'epic | [!] | Trois stories nouvelles (§ 4, Backlog). |
| 2.3 | Epics restants | [x] | 11.10 et 11.11 : le CV jugé et publié doit être le nouveau, si le contenu est prêt. Epic 13 : les cas 03, 04, 06 ne changent pas. Epic 8 et 12 : aucun impact. |
| 2.4 | Epic obsolète ou nouveau | [x] | Aucun obsolète ; pas d'epic nouveau : les stories vont dans l'epic 10 (Q7). |
| 2.5 | Ordre | [!] | Les deux premières stories avant la 11.10 ; la troisième dépend de la rédaction d'Arnaud. |
| 3.1 | PRD | [!] | Glossaire (Poste, Stack, encart), FR-2, FR-6, FR-23, FR-25, note de FR-37, §11.1. |
| 3.2 | Architecture | [!] | AD-18 (champs, règle du corps), C3, C6, C19, renvoi `format-parcours.md`, ligne NFR-10 conservée. |
| 3.3 | UX | [!] | DESIGN.md § cv-position et décision 5 ; EXPERIENCE.md voix et ton, états, premier écran, décision 10 ; UX-DR8. |
| 3.4 | Autres artefacts | [!] | `docs/format-parcours.md` (nouveau), `docs/format-cas.md` (règle de stack), `data/stack.yaml`, `docs/procedures/check.md`, CV PDF de la 7.4 (divergence à noter). |
| 4.1 | Ajustement direct | Viable | Stories ajoutées, aucun retour arrière. Effort moyen, risque faible hors premier écran. |
| 4.2 | Retour arrière | Non viable | Rien à défaire : les postes et les cas publiés restent justes, ils sont incomplets. |
| 4.3 | Revue du MVP | Non nécessaire | Le socle garde son périmètre ; le contenu peut glisser en temps 2. |

### Epics et stories

- **Epic 10 (`done`)** : le parcours qu'il a livré (story 10.2) reste ; il gagne des champs, et
  l'epic repasse `in-progress` pour ses trois stories nouvelles (Q7).
- **Epic 11** : 11.9 n'est pas touchée (répétition sur `v0.1.0-rc.*`). **11.10** fait juger le CV par
  cinq testeurs : idéalement sur le CV complété. **11.11** le publie : même chose.
- **Epic 13** : aucun cas ne change ; un cas publié plus tard trouvera son poste déjà complet.

### Impact technique

- **Gabarit** : `_partials/position.html` (rendu du périmètre et de la stack, y compris avec cas),
  `assets/css/main.css`, `i18n/{fr,en}.yaml` (libellés nouveaux).
- **Contrôles** : C19 (`content.sh`, clés nouvelles et crible « présente mais vide »), C6 étendu aux
  postes, C3 (`parity.sh:34`, `stack` non traduit pour les postes). Tests : `test-career-position.sh`,
  `test-content.sh`, `test-parity.sh`.
- **Budget (AD-8)** : marge large. Accueil FR mesuré sur le build courant : 9 620 o de HTML (limite
  50 000), 159 éléments (limite 800), page complète ≈ 36 ko (limite 200 000). Risque faible.
- **Premier écran mobile (FR-37)** : **le vrai risque.** Chiliz est le premier poste ; un périmètre
  et une stack déployés avant le lien « Cas 02 » le pousseraient sous la ligne de 844 px. Arbitrage Q1 :
  un bloc repliable natif (`<details>`, fermé par défaut, sans JavaScript) ; fermé, il n'occupe qu'une
  ligne.
- **Test des trente secondes (11.10)** : un testeur peut ne pas ouvrir le bloc. C'est le prix assumé
  de Q1 ; si le test le montre, le libellé du bloc fait partie de ce que la 11.10 retouche.
- **Contenu** : quatorze fichiers `content/career/position-*.{fr,en}.md`, une dizaine de termes à
  ajouter à `data/stack.yaml`.
- **Bornes des cas** : la période d'un cas doit être comprise dans celle de sa mission (règle d'Arnaud,
  Q2). Toutes les périodes publiées le sont aujourd'hui — cas 01 dans Ton Pote le Geek, 02 et 04 dans
  Chiliz, 05 dans Orange, 06 dans April 2017. Un contrôle peut le garantir (story 10.9).
- **Une page de cas change d'une métadonnée** : scinder Zend Framework (Q5) oblige à écrire
  « Zend Framework 1 » ou « 2 » dans la stack du cas 05, qui porte aujourd'hui « Zend Framework ».
  C'est la seule exception à « les pages de cas ne changent pas », et elle est une conséquence
  directe de Q5.
- **Cas** : `content/cases/**` (sauf la stack du cas 05, ci-dessus), `_partials/case.html`,
  `career-url.html`, `case-url.html` inchangés ;
  `ci/release-pages.txt` et `ci/base-pages.txt` inchangés (un poste n'est jamais une page).

## 3. Approche recommandée

**Ajustement direct, en trois stories, dont deux indépendantes de la rédaction d'Arnaud.**

1. **Le contrat** (`docs/format-parcours.md`) — ce que la demande d'Arnaud du 02/10/2026 appelle
   « le prompt du CV », sur le modèle de `docs/format-cas.md`. AD-18 l'avait anticipé (ligne 776 : « un
   `docs/format-parcours.md` pourra le reprendre si la rédaction du parcours est confiée à un agent »).
2. **Le gabarit et les contrôles**, avec des clés **facultatives** tant que le contenu n'est pas là :
   le site reste juste et publiable avec les postes d'aujourd'hui.
3. **Le contenu**, tiré du premier jet validé par Arnaud ligne par ligne, qui rend les clés
   obligatoires une fois les quatorze fichiers remplis.

**Calendrier.**

- Stories 1 et 2 : **avant la 11.10**, quoi qu'il arrive — elles ne dépendaient que des arbitrages du
  § 5, rendus le 02/10/2026.
- Story 3 : **avant la 11.10 si la rédaction est validée à temps** ; sinon **temps 2**, publiée juste
  après la 11.11 par une mise en ligne ordinaire (`release`), et les testeurs de la 11.10 jugent le CV
  actuel.
- **Les incohérences relevées dans le parcours déjà publié** (§ 4, Contenu) **attendent la story 3**,
  quel que soit son calendrier (arbitrage Q8) : si elle glisse en temps 2, elles sont en ligne entre la
  11.11 et sa publication, en connaissance de cause.

**Effort** : moyen (story 2 surtout). **Risque** : faible ; le premier écran mobile est tenu par le
bloc replié (Q1) et par la vérification à 390 × 844 que FR-37 impose déjà à chaque retouche du premier
poste.

## 4. Propositions de modification détaillées

Ces textes sont **proposés** : aucun document validé n'est modifié avant l'accord d'Arnaud sur la
proposition entière. Ils intègrent ses arbitrages du 02/10/2026 (§ 5).

### PRD (`prds/prd-eleyone.fr-2026-09-13/prd.md`)

**Glossaire, « Poste » (ligne 86).**

ANCIEN : « entrée du parcours professionnel : société, intitulé du poste, période, ville de travail
ou cadre …, et les liens vers les cas qui le prouvent. »

NOUVEAU : « entrée du parcours professionnel : société ou intitulé, secteur, intitulé du poste,
période donnée par l'auteur, ville de travail ou cadre, les liens vers les cas qui le prouvent, puis,
dans un bloc repliable, **le périmètre complet de la mission** et **la stack complète du projet**. »

**Glossaire, « Stack » (ligne 79).** « liste des technologies citées dans le cas » → « liste des
technologies d'un cas (celles qu'il cite) ou d'un poste (celles du projet entier), tirée du
vocabulaire contrôlé, identique en FR et en EN. »

**FR-2, conséquences (lignes 148-156).**

ANCIEN : « Le corps d'un poste (texte descriptif facultatif) ne s'affiche que si le poste n'a aucun
cas mis en ligne. »

NOUVEAU : « Chaque poste porte son périmètre (corps du poste) et la stack complète du projet, **qu'il
ait des cas ou non**, dans un bloc repliable fermé par défaut, après ses cas mis en ligne. »

Ajouts : « Chaque poste affiche son secteur. » « Aucune durée n'est affichée : la période, donnée par
l'auteur, en porte les bornes. » « La période d'un cas est comprise dans celle de son poste ; un cas
ne couvre pas nécessairement toute la mission. »

**FR-6 (ligne 258)** : inchangé pour les cas (« Seules les technologies citées dans le cas y
figurent ») ; ajout d'une phrase : « La stack d'un poste est celle du projet entier ; celle d'un cas
reste celle qu'il cite. »

**FR-23** : la stack d'un poste rejoint les métadonnées non traduites comparées. **FR-25** : « une
technologie nouvelle dans une stack » couvre aussi un poste. **FR-37** : note — le bloc replié
garde le lien du premier cas dans le premier écran. **§11.1** : « postes sans cas affichés
complets » → « tous les postes affichés complets ».

### Architecture (`ARCHITECTURE-SPINE.md`)

**AD-18, front matter d'un poste** — ajouts : `sector` (traduit, obligatoire une fois le contenu
rempli), `stack` (non traduit, ⊂ `data/stack.yaml`, identique FR/EN). **Pas de clé de durée** (Q2) :
la règle « Prevents » sur la période calculée reste entière. Règle nouvelle : la période d'un cas est
comprise dans celle de son poste.

**AD-18, ligne 411.**

ANCIEN : « Le corps Markdown, facultatif, décrit le poste ; il n'est rendu que si le poste n'a aucun
cas publié dans la langue de la page. »

NOUVEAU : « Le corps Markdown décrit le périmètre complet de la mission ; il est rendu pour tout
poste, avec la stack du projet, dans un `<details>` fermé par défaut placé après la liste de ses cas
publiés. »

**Contrôles** : C3 (`stack` des postes non traduite), C6 (`stack` ⊂ `data/stack.yaml` pour les cas
**et** les postes), C19 (clés nouvelles, crible « présente mais vide », obligatoires dès que la
story 3 les remplit), et un contrôle nouveau — **la période de chaque cas comprise dans celle de son
poste** —, qui lit les formes de période en usage (« mois AAAA – mois AAAA », « depuis mois AAAA »,
« AAAA », en FR et en EN) et refuse une forme qu'il ne sait pas lire plutôt que de la laisser passer. **Renvoi ligne 776** : « pourra le reprendre » → « est repris par
`docs/format-parcours.md` ». La ligne NFR-10 « aucune période calculée » reste vraie : le contrôle
d'inclusion compare des bornes, il n'affiche rien.

### UX

**DESIGN.md § cv-position (ligne 574) et décision 5** : « affiché seulement pour un poste sans cas
publié » → « dans un `<details>` fermé par défaut, pour tout poste, après ses cas ; le corps en
`body-sm`, puis la stack du projet en `meta` avec la classe `.stack` déjà définie pour l'encart des
cas ». Le `<summary>` est un libellé court (« Mission : périmètre et stack », à confirmer en
story 10.9), focalisable au clavier, avec un indicateur d'état visible. Secteur sur la ligne de rôle.
Rien dans la marge ne change : la période y reste seule.

**EXPERIENCE.md** : voix et ton (libellés « Secteur », « Stack du projet », libellé du bloc
repliable), états (ligne 134 : tout poste porte son bloc, ouvert ou fermé), premier écran
(ligne 212 : inchangé, garanti par le bloc replié), comportement du bloc (fermé par défaut, ouvert au
clic ou au clavier, aucun JavaScript), décision 10 révisée, et une note au test des trente secondes :
le libellé du bloc fait partie de ce qui se retouche.

**epics.md, UX-DR8** : « corps affiché sans cas » → « corps et stack de tout poste dans un bloc
repliable, après ses cas ».

### `docs/format-parcours.md` (nouveau), passation privée et `docs/format-cas.md`

Le nouveau contrat, sur le modèle de `format-cas.md` : emplacement et identifiants figés (AD-18),
front matter (clés anglaises, valeurs traduites sauf `company`, `stack`, `setup`, `via`, `track`,
`order`), corps = périmètre (3 à 6 phrases, à la première personne, la voix du noyau narratif : le
jugement, pas l'exécution), parité FR/EN, marqueurs `[TODO: …]`, règles de rédaction reprises de
`format-cas.md` (rien d'inventé, aucune information personnelle, ton factuel, une personne physique
n'est pas nommée, un sujet jamais mis en production le reste), et un modèle vide.

**Passation privée (Q6)** : `docs/private/handoff-redaction-postes.md`, sur le modèle de
`docs/private/handoff-redaction-cas.md` — décisions qui touchent les postes, ce qui manque poste par
poste (repris des `[TODO]` et `[À TRANCHER]` du premier jet), incohérences à trancher. Jamais commitée
dans ce dépôt ; commitée dans le dépôt privé.

`format-cas.md` : la règle « seules les technologies citées dans le cas » reste pour les cas ; ajout
d'un renvoi vers `format-parcours.md` pour la stack du projet. Version 0.5.

### `data/stack.yaml`

En-tête : « Seules les technologies citées dans le texte d'un cas figurent dans sa `stack` » →
« … dans la `stack` d'un cas ; la `stack` d'un poste porte celles du projet entier ». Termes
acceptés par Arnaud (Q5) : DFNS, TypeScript, viem.js, Chiliz Chain, Ethereum, SugarCRM, BackboneJS,
Marionette, n8n, Stripe. **Refusés**, parce que ce sont des notions et non des technologies : DEX,
microservices, APIs, CI, VPS ou infrastructure auto-hébergée — ils vont dans le périmètre.
**« Zend Framework » est scindé** en « Zend Framework 1 » et « Zend Framework 2 » ; la stack du cas 05
reçoit celle des deux que le cas cite, confirmée par Arnaud en story 10.10.
Les exclusions de n8n et Stripe **pour le cas 01** restent : elles portent sur ce que le cas cite.

### Backlog (`epics.md`)

Trois stories, rattachées à l'epic 10 (Q7), qui repasse `in-progress` ; placées dans l'ordre
d'exécution avant la 11.10 :

**Story 10.8 : Career format contract** — En tant qu'Arnaud, je veux un contrat de rédaction des
postes, afin qu'une personne ou un agent produise un poste complet sans toucher au code. *Couvre :*
FR-2, FR-25, NFR-10 · AD-18. *Dépendances :* — . *Opération manuelle :* non. *Critères :* `docs/format-parcours.md`
existe, suit la structure de `format-cas.md`, porte un modèle vide ; AD-18 y renvoie ;
`format-cas.md` v0.5 renvoie vers lui pour la stack d'un poste ; la passation privée
`docs/private/handoff-redaction-postes.md` existe dans le dépôt privé.

**Story 10.9 : Full mission context on the CV** — En tant que recruteur, je veux lire pour chaque
mission son secteur, son périmètre et sa stack, afin de juger l'ampleur du travail et pas
seulement une décision. *Couvre :* FR-2, FR-6, FR-23, FR-37 · AD-18 · C3, C6, C19, C13. *Dépendances :*
10.8. *Critères :* clés `sector` et `stack` lues par `position.html` ; corps et stack rendus pour tout
poste dans un `<details>` fermé par défaut, **après** ses cas, utilisable au clavier (WCAG 2.2 AA) ;
le contrôle d'inclusion des périodes refuse un cas qui déborde de son poste et une période illisible ; C6 et C3 étendus aux postes ; C19 crible les clés nouvelles ;
chaque garde a un test qui échoue sans elle ; le site actuel, sans les clés, se construit et passe
tous les contrôles ; à 390 × 844, le premier poste et le lien « Cas 02 » restent visibles sans
défilement (FR-37), mesuré sur un poste court, un poste vide et le poste Chiliz le plus long
(point 11 d'AGENTS.md).

**Story 10.10 : Mission context content** — En tant qu'Arnaud, je veux que les quatorze fichiers de
poste portent le contexte complet validé, afin que le CV jugé et publié soit le CV complet.
*Couvre :* FR-2, FR-20, NFR-10. *Dépendances :* 10.9. *Prérequis de contenu :* le premier jet
`docs/private/drafts/contexte-des-missions-v0.md` validé par Arnaud, sans `[TODO]` ni `[À TRANCHER]`.
*Critères :* les sept postes FR et EN portent secteur, périmètre et stack ; les termes
nouveaux sont dans `data/stack.yaml`, « Zend Framework » scindé et la stack du cas 05 mise à jour ;
les incohérences du § Contenu sont tranchées ; C19 rend les
clés obligatoires ; FR-37 revérifié.

**11.10 et 11.11** : une ligne d'ordre — « joue après 10.9 ; après 10.10 si son prérequis de contenu
est rempli, sinon 10.10 passe après 11.11 ».

### Contenu : incohérences relevées dans le parcours publié

Relevées par le premier jet en croisant le parcours publié et les sources ; à trancher par Arnaud en
story 10.10. L'écart entre la période d'Orange (juillet 2014 – décembre 2016) et celle du cas 05
(juillet 2014 – janvier 2016) **n'en est pas un** : un cas ne couvre pas nécessairement toute la
mission (Q2), et celle-ci est comprise dans celle-là.

- **Début de carrière** : juillet 2008 au parcours, avril 2008 à la page « À propos ».
- **Chiliz** : « quatre ans » à l'accueil, 3 ans et 10 mois d'après la période publiée.
- **Mister Auto et Synolia** se recouvrent sur janvier 2020.
- **Chiliz, « traitement par lots on-chain »** au parcours : si c'est le batch du cas 03, il n'a jamais
  été mis en production, et le parcours ne doit pas le laisser croire (règle 6 de `format-cas.md`).
- **Chiliz, « conçue from scratch »** au parcours, contre le POC existant et le départ en Python du
  cas 02.
- **Mister Auto, « Chef de projet »** : contredit le positionnement du noyau narratif (il refuse le
  rôle de chef de projet).

## 5. Transmission

**Périmètre : modéré** — réorganisation du backlog et révision de documents validés, sans
re-planification. Destinataires : Arnaud (arbitrages, rédaction et validation du contenu), l'agent de
développement (stories 10.8 à 10.10, une à la fois, par le flux habituel : revue de spec, PR, revue du
code, cinq verrous).

**Critères de réussite** : chaque poste du CV montre secteur, période, rôle, et dans son bloc repliable le périmètre et la stack du
projet en FR et en EN ; aucune page de cas ne change, hormis la stack du cas 05 (Q5) ; le premier écran mobile garde le lien du
premier cas ; aucun fait n'est inventé.

**Après accord** : cette proposition passe en `approved`, les documents validés sont modifiés dans une
PR de la branche `docs/correct-course-contexte-des-missions`, puis `sprint-status.yaml` reçoit les
trois stories.

### Arbitrages d'Arnaud (02/10/2026)

Chaque question a été posée avec toutes ses options, y compris celles que l'agent écartait.

| # | Question | Réponse | Options écartées |
|---|---|---|---|
| Q1 | Où afficher périmètre et stack d'un poste qui a des cas | **Bloc repliable natif `<details>`, fermé par défaut** | après les cas, déployé (recommandé par l'agent) ; avant les cas (FR-37 tombe) ; statu quo (c'est le problème) |
| Q2 | La durée | **Aucune durée affichée** : « les bornes temporelles permettent de la calculer ». Et : « les cas ont une période qui doit être comprise dans la période de la mission, mais ne sont pas nécessairement toute la mission » | clé `duration` écrite par l'auteur (recommandée par l'agent) ; durée dans le texte de la période ; durée calculée (interdite par AD-18) |
| Q3 | Client ou secteur | **Clé `sector` traduite** ; `company` reste le client direct, `via` la société de conseil, les clients finaux dans le périmètre | `sector` + `client` ; tout dans le corps |
| Q4 | Stack d'un poste | **Clé `stack` contrôlée par `data/stack.yaml`**, C6 étendu | liste libre ; dérivée des cas |
| Q5 | Vocabulaire | **Termes du premier jet acceptés, termes génériques refusés, Zend Framework scindé en 1 et 2** | un seul terme Zend Framework |
| Q6 | Contrat | **Contrat public `docs/format-parcours.md` et passation privée** `docs/private/handoff-redaction-postes.md` | contrat seul (recommandé par l'agent) |
| Q7 | Place des stories | **Epic 10**, stories 10.8 à 10.10 | epic 14 ; epic 11 |
| Q8 | Incohérences déjà en ligne | **Tout attend la story 10.10**, quel que soit son calendrier | extraction avant la 11.11 si 10.10 glisse (recommandée par l'agent) ; story de corrections immédiate |

## Application (02/10/2026)

Proposition approuvée par Arnaud le 02/10/2026, appliquée le même jour sur la branche `docs/correct-course-contexte-des-missions`, documents de planification seulement. `docs/format-cas.md`, `docs/format-parcours.md`, `data/stack.yaml`, le contenu, les gabarits, les scripts et `docs/private/` relèvent des stories 10.8 à 10.10 et ne sont pas touchés ici.

- **PRD** (`prds/prd-eleyone.fr-2026-09-13/prd.md`) : §0 (entrées), glossaire (« Encart Contexte mission », « Stack », « Poste »), description du §4.1, FR-2, FR-6, FR-23, FR-25, note de FR-37, §11.1 (deux lignes du 13/09/2026 annotées, une ligne du 02/10/2026 ajoutée), contenus à fournir du §11.2.
- **Architecture** (`ARCHITECTURE-SPINE.md`) : statut, AD-18 (Binds, Prevents, clés `sector` et `stack`, aucune clé de durée, corps de tout poste dans un `<details>`, période d'un cas comprise dans celle de son poste, contrat de rédaction), portée et lignes C3, C6, C19 de la liste des contrôles, **nouveau contrôle C25** (premier numéro libre, livré par la story 10.9), structure initiale, ligne « Renvoi » de la section `docs/format-cas.md` v0.4 (au futur : le contrat n'existe pas encore), carte des capacités (FR-2, NFR-10), décision 34 annotée, décision 76 ajoutée.
- **DESIGN.md** : sources, jetons de `cv-position`, échelle typographique, mise en page de l'accueil, composant `cv-position` (secteur, bloc repliable, poste sans cas ; ancienne règle gardée en note de révision), décision 5 révisée avec sa note.
- **EXPERIENCE.md** : sources, « Voice and Tone » (trois libellés à valider à la story 10.9), `cv-position` dans « Component Patterns », « State Patterns », « Interaction Primitives », note du premier écran, test des trente secondes, décision 10 révisée avec sa note.
- **epics.md** : présentation, inventaire (FR-2, FR-6, AD-18, C1 à C25, UX-DR8, UX-DR18), carte de couverture, liste des epics (ordre, Epic 10, Epic 11), stories 2.7 et 5.2 annotées, en-tête de l'Epic 10, **stories 10.8, 10.9 et 10.10**, ordre et dépendances des stories 11.10 et 11.11, synthèse.
- **sprint-status.yaml** : `epic-10: in-progress`, trois stories en `backlog`, ordre de travail, prérequis de contenu de la 10.10, `last_updated`.

## Révision (02/10/2026, story 10.9)

Arnaud a révisé l'arbitrage **Q1** le même jour, en répondant aux questions de la story 10.9, avant son implémentation : « le bloc repliable comprend uniquement la stack. Le contexte de mission doit être lisible. Le bloc se nomme stack. » Le tableau ci-dessus garde Q1 tel qu'il a été rendu ; cette section le révise.

- **Q1 révisé** : le périmètre d'un poste (son corps) est **toujours visible**, après la liste de ses cas — l'option « après les cas, déployé » du tableau, pour le périmètre seulement. La stack du projet est seule dans un `<details>` natif fermé par défaut, dont le résumé est « Stack » en FR et en EN.
- **Place du secteur** : juste après le rôle, sur la ligne de rôle — rôle · secteur · lieu · cadre · via.
- **Ce qui n'existe pas n'est pas rendu** : sans stack, pas de bloc ; sans corps, pas de périmètre ; aucune mention d'absence.
- **Effet sur FR-37** : le périmètre et le bloc suivent la liste des cas et ne repoussent pas le lien du premier cas ; la story 10.9 l'a mesuré. Elle a aussi mesuré qu'avec une serif de repli large, le lien « Cas 02 » passait déjà sous la ligne de 844 px avant elle, et qu'un secteur qui allonge la ligne de rôle le repousse encore (`docs/accessibility.md`) : la suite relève d'un arbitrage d'Arnaud.

Documents corrigés dans la PR de la story 10.9 (point 12 d'AGENTS.md) : PRD (glossaire « Poste », description du §4.1, FR-2, note de FR-37, §11.1), `ARCHITECTURE-SPINE.md` (statut, AD-18, lignes C3, C6, C19 et C25, décision 77), `DESIGN.md` et `EXPERIENCE.md` (`cv-position`, « State Patterns », premier écran, décisions 5 et 10, notes de révision datées), `epics.md` (FR-2, AD-18, UX-DR8, notes des stories 2.7, 5.2 et 10.9), `docs/format-parcours.md` et `docs/procedures/check.md`.
