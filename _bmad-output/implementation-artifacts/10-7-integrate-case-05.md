# Story 10.7 : Integrate case 05

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.7.

## Revue de spec

### 24/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `9f6d4f4`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b2af89df8dd8c3a1bb302557

### Rapport de revue de spécification (Story 10.7)

##### Lentille Adversarial
- BLOQUANT : La règle globale du projet exige qu'à chaque nouveau développement, une entrée de version soit obligatoirement ajoutée dans `docs/CHANGELOG.md`. Aucun critère d'acceptation ne vérifie que le fichier CHANGELOG.md sera mis à jour.
- BLOQUANT : Le critère stipulant que « la version EN porte la ligne de contexte sur Orange » (exigence FR-22) est ambigu quant à sa cible. Il laisse deux lectures contradictoires possibles : on ignore si la ligne doit être ajoutée au fichier du cas (`content/cases/case-05-<nom-court>.en.md`) ou si elle doit amender le fichier du poste de la carrière (`content/career/position-orange.en.md`).
- BLOQUANT : Le critère « Quand `publish-case` s'exécute » est invérifiable en l'état car il ne précise aucun argument. L'exécution d'un outil en ligne de commande ou d'un script nécessite qu'on spécifie sur quel cas exact il s'applique.

##### Lentille Structure
- BLOQUANT : Contradiction majeure avec la carte de couverture du document d'architecture (`epics.md`). La spécification prétend couvrir `FR-2, FR-5 à FR-8, FR-12, FR-20, FR-26`. Or, la carte de couverture de référence n'attribue à la story 10.7 que `FR-10, FR-22 et FR-25`. L'intégration d'un cas de contenu ne fait qu'utiliser les gabarits mis en place par l'epic 6, elle ne réalise pas leurs exigences fonctionnelles.
- BLOQUANT : L'exigence FR-12 (matériel vivant) est annoncée comme couverte, mais la section des critères d'acceptation est muette à ce sujet. Si le cas 05 contient des éléments de type `live-material` (schéma, extrait de code, vidéo), un critère doit exiger la vérification de leurs sources et de leur bon affichage. S'il n'en contient aucun, l'exigence FR-12 ne doit pas figurer dans la liste de couverture.

##### Lentille Prose
- NON BLOQUANT : La consigne « nomme les limites de sa mesure *(relecture)* » est claire sur le fond, mais pourrait gagner en précision en nommant la rubrique spécifique de `docs/format-cas.md` (par exemple "Ce qui a résisté" ou "Résultat") où le relecteur devra chercher l'information.
- NON BLOQUANT : Le formalisme du nom de fichier `case-05-<nom-court>.{fr,en}.md` reste abstrait. Le nom de l'entreprise étant connu (Orange), il serait plus direct de figer le nom du fichier attendu, comme `case-05-orange.{fr,en}.md`.

##### À trancher avant d'implémenter
- La question **Q2** (période et cadre du cas 05) du PRD, qui bloque la story, doit être résolue avec Arnaud.
- Préciser le fichier cible qui doit recevoir la ligne de contexte EN (FR-22) : le Markdown du cas ou celui du poste ?
- Statuer sur la présence ou non de matériel vivant (FR-12) dans le cas 05. Si oui, formuler le critère de validation technique correspondant.

## Revue du code

### 24/09/2026 — `f268839` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 112. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 4ce68d71d3f67a62a610b578

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter

```json
[
  {
    "location": "layouts/cases/page.html:271",
    "trigger_condition": ".Params.translationKey est manquant ou vide",
    "guard_snippet": "{{ with .Params.translationKey }}id=\"{{ . }}\"{{ end }}",
    "potential_consequence": "Génère un attribut id HTML invalide (id=\"\")"
  }
]
```

###### Lentille : Verification Gap

```json
[
  {
    "location": "content/cases/case-05-orange.en.md",
    "trigger_condition": "Le diff n'ajoute pas la ligne de contexte requise sur Orange",
    "guard_snippet": "assert_contains \"Orange is a...\" \"$html_en_case\"",
    "potential_consequence": "L'exigence FR-22 n'est pas remplie en production de manière silencieuse",
    "gap_shape": "missing-adoption-gap",
    "consumer": "content/cases/case-05-orange.en.md",
    "evidence": "Le diff de `case-05-orange.en.md` ne contient que des mises à jour du frontmatter et aucune phrase de contexte n'a été insérée. Aucun test ne vérifie la présence de cette ligne de contexte."
  }
]
```

##### Couche propre au projet

- BLOQUANT : Les critères d'acceptation ne sont pas satisfaits. L'exigence FR-22 (qui demande explicitement que la ligne de contexte sur Orange soit présente dans la version anglaise du cas `case-05-<nom-court>.en.md`) n'a pas été implémentée dans le fichier markdown lors de ce diff.
- NON BLOQUANT : Aucune donnée privée, aucun secret, nom d'hôte ou adresse de serveur n'a fuité ou n'est exposé.
- NON BLOQUANT : Skill, procédure et script concordent (aucun des trois n'a été dégradé ni désynchronisé).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture, notamment avec le principe de factorisation en remontant l'identifiant d'ancre manquant au niveau du gabarit partagé (story 6.2).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Les potentielles erreurs d'appel comme `cat "$page"` ou la substitution `$(page_seule)` lèveraient bien une erreur fatale au lieu d'être avalées par le script.

VERDICT: BLOQUANT — Le critère d'acceptation FR-22 (ajout de la ligne de contexte sur Orange dans le cas EN) n'est pas implémenté dans le code.

### 24/09/2026 — `978a5dd` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 112. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 66511df77537e39d3c5517f1

##### Rapport de revue BMAD

###### Lentille : Edge-Case Hunter
- NON BLOQUANT : `layouts/cases/page.html:271` — Condition de déclenchement : `.Params.translationKey` est manquant ou vide. Garde suggérée : utiliser `{{ with .Params.translationKey }}id="{{ . }}"{{ end }}`. Conséquence potentielle : génération silencieuse d'un attribut HTML invalide (`id=""`).

###### Lentille : Verification Gap
- NON BLOQUANT : `content/cases/case-05-orange.en.md` — Condition de déclenchement : aucun test automatisé ne vérifie l'exigence FR-22 (présence de la ligne de contexte). Garde suggérée : ajouter un `assert_contains` sur le HTML généré. Conséquence potentielle : la ligne pourrait être supprimée par erreur à l'avenir sans que la CI ne le détecte (missing-adoption-gap).

###### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (la ligne de contexte de l'exigence FR-22 est bien présente dans le contenu du fichier anglais existant, et l'ancre du cas seul est correctement ajoutée pour réparer le lien du sommaire).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, et aucun secret n'est commité, et aucun script n'est modifié de manière à les exposer.
- NON BLOQUANT : Skill, procédure et script concordent parfaitement (le changement se limite au contenu et à la correction d'un gabarit justifiée, sans impact sur les procédures).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (la correction de l'ancre dans `page.html` factorise le comportement existant et documente sa portée conformément au point 7 d'AGENTS.md).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (dans `test-case-page.sh`, l'appel `cat "$page"` échouera franchement si le fichier n'a pas été construit, et la substitution `$(page_seule)` est sûre).

VERDICT: NON BLOQUANT — aucune

## Reporté

### Triage de la revue de spec, 24/09/2026

Cinq constats bloquants : **quatre retenus, un réfuté**. Comptés, non déclarés (leçon de la 10.3).

**Réfuté — l'entrée dans `docs/CHANGELOG.md`.** Troisième apparition de la même règle, qui vit dans
les mémoires globales du compte relecteur et décrit un autre projet. Point 20 d'AGENTS.md.

**Retenu — la carte de couverture contredit la ligne « Couvre ».** Et c'est le constat utile : la
carte d'`epics.md` n'attribue à la 10.7 que **FR-10, FR-22 et FR-25**, quand la ligne en revendiquait
six de plus. Le raisonnement du relecteur tient : intégrer un cas **emploie** les gabarits de l'epic 6,
il ne réalise pas leurs exigences. La ligne est corrigée. **Les stories 10.5 et 10.6 portent le même
sur-affichage** ; la 10.5 est déjà fusionnée, c'est noté dans la spec.

**Retenu — FR-12 annoncée sans critère.** Résolu par ce qui précède : FR-12 sort de la couverture. Un
critère demande tout de même qu'aucun élément « prévu » ne laisse de trace, comme pour le cas 02.

**Retenu — où va la ligne de contexte Orange.** FR-22 dit « le cas concerné ou l'accueil » et nomme
« Orange (cas 05) » : elle est dans le fichier du cas, jamais dans `position-orange.en.md`. Écrit.

**Retenu — `publish-case` sans argument.** Le critère nomme `scripts/publish-case.sh case-05`.

### Ce que j'ai cru à tort, et qui a coûté du temps

**J'ai affirmé que les cas 01 et 05 n'existaient pas.** Faux deux fois : les sources brutes sont dans
`docs/private/context/` **et** les fichiers du site étaient déjà écrits dans `content/cases/`. J'ai
commencé à réécrire le cas 05 de zéro avant de m'en apercevoir ; les doublons ont été supprimés sans
laisser de trace. **Lister le dossier avant d'écrire une ligne** aurait suffi — c'est le coût d'une
commande contre celui d'un cas réécrit.

**Q2 était bien plus petite que je ne le disais.** Elle ne bloquait que trois marqueurs `[TODO` :
le cadre (`agency`, le poste Orange en prestation Modis), la période, et une ligne sur le nombre de
commerciaux que la source proposait elle-même de retirer.

### Arbitrages d'Arnaud, 24/09/2026

- **Période** : d'abord « la période du poste » (juillet 2014 – décembre 2016), puis resserrée à
  **juillet 2014 – janvier 2016** après relecture. La source dit ne pas dater la mission plus finement.
- **Relecture et accord** donnés après cette correction.

### Deux défauts trouvés en publiant

**Le slug anglais était le slug français.** Le cas 02, l'aîné, porte des slugs par langue —
`chiliz-source-de-verite` / `chiliz-source-of-truth` — et le cas 05 portait `orange-crv-performance`
des deux côtés. L'URL anglaise exposait « crv », sigle de « comptes rendus de visite », qui ne dit
rien à un lecteur anglophone. Corrigé en `orange-visit-reports-performance` — **avant** publication,
puisqu'un slug publié ne se renomme plus. Aucun contrôle ne le voyait : C3 ne compare pas `slug`, et
c'est juste, mais rien n'exige qu'il diffère.

**La page d'un cas seul n'avait pas l'ancre de son cas.** Son sommaire émet un lien vers `#case-05` ;
les ancres de rubriques existaient, celle du cas non — c'est la `section` enveloppante qui la porte
sur une page de groupe, et la page d'un cas seul employait un `div` sans identifiant. C12 l'a refusé.

Le défaut vient de la **story 6.2** et n'était visible que sur un **cas non groupé publié** : le cas 05
est le premier. Corrigé ici (point 7 d'AGENTS.md : cette story ajoute le minimum qu'une autre possède,
et écrit sa portée). `layouts/cases/page.html` pose désormais le même identifiant que la page de
groupe, ce qui rend `/cas/<slug>/#case-05` aussi valable que `/cas/chiliz/#case-02`. Un cas de test
l'exerce dans les deux langues, et échoue sans la correction.

### Vérifications

- `scripts/ci/checks-job.sh` : **555 cas** (554 → 555), 9 contrôles, verts.
- Pages produites : `public/cas/orange-crv-performance/` et `public/en/cases/orange-visit-reports-performance/`.
- Le cas est lié sous le poste Orange **dans chaque langue**.
- Aucune trace de matériel « prévu » en production, alors que le cas en déclare trois.

### Triage de la revue de code, 24/09/2026

Verdict `block`, **un seul constat, réfuté sur pièce**.

**« La ligne de contexte Orange (FR-22) n'est pas implémentée. »** Elle l'est. Première phrase de la
rubrique « Context » de `case-05-orange.en.md` :

> « Orange is France's main telecom operator. »

Et la version française ne la porte pas — son « Contexte » commence par « Application CRV ». C'est
exactement l'asymétrie que FR-22 prescrit : « la version anglaise **ajoute** une ligne de contexte là
où un repère ne parle qu'à un lecteur français ».

**La cause de l'erreur est nommée par le relecteur lui-même** : « n'a pas été implémentée dans le
fichier markdown **lors de ce diff** ». Le diff de cette PR ne touche au cas que son `draft`, son
`setup`, sa `period` et une ligne retirée ; la rubrique « Context » n'y apparaît donc pas. Le critère
porte sur **l'état du fichier**, pas sur ce que le diff modifie. La ligne existait avant cette story,
écrite avec le cas.

C'est une forme voisine de « le relecteur ne voit pas le dépôt », qui a coûté onze constats réfutés
dans l'epic 9 : ici il voit le dépôt, mais il juge le diff comme s'il était l'état.
