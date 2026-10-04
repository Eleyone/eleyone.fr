---
title: "Proposition de changement : meta description et aperçus de partage"
status: approved
created: 2026-10-04
skill: bmad-correct-course
scope: minor
source: "Mesures PageSpeed Insights de v1.0.0 (story 11.11, 04/10/2026)"
---

# Proposition de changement : meta description et aperçus de partage

## 1. Résumé du problème

**Constat (04/10/2026, mesures de la story 11.11).** PageSpeed Insights, sur les cinq gabarits du
site en ligne : 100 en performance et en accessibilité, mais **un seul audit SEO en échec partout —
« Document does not have a meta description »**. Vérifié sur le site servi : aucune page ne porte de
`<meta name="description">`, ni de balise Open Graph. Le `<head>` contient le titre, les `hreflang`,
la feuille de style et le JSON-LD de la personne (story 9.6), rien d'autre.

**Conséquence.** Le texte sous le titre dans un moteur de recherche est choisi par le moteur, et
l'aperçu d'un lien partagé — LinkedIn, messageries, le canal par lequel un recruteur reçoit le lien
du CV — n'a pas de description.

**Type.** Exigence manquée à la planification : ni le PRD, ni l'architecture, ni les gabarits ne la
prévoient. L'architecture ne nomme la meta `description` qu'une fois, en négatif : C23 y interdit
l'adresse légale de l'éditeur.

**Décision d'Arnaud (04/10/2026), story 11.11** : la 11.11 se clôt sans elle ; une proposition de
changement ajoute l'exigence et une story, publiée ensuite par une mise en ligne ordinaire.

## 2. Analyse d'impact

| # | Point | État | Constat |
|---|---|---|---|
| 1 | Déclencheur | [x] | Mesures PageSpeed de `v1.0.0` (`docs/measures/v1.0.0.md`). |
| 2 | Epics | [!] | Une story nouvelle, dans l'epic 9 (pages et données structurées), à côté de la 9.6 (JSON-LD) ; l'epic repasse `in-progress`. Aucun autre epic touché. |
| 3.1 | PRD | [!] | Une exigence nouvelle, FR-40. |
| 3.2 | Architecture | [!] | Un AD nouveau (le `<head>` d'une page) et un contrôle nouveau, C26 ; C23 inchangé et déjà compatible. |
| 3.3 | UX | [N/A] | Rien de visible sur la page. |
| 3.4 | Contenu | [!] | Une clé `description` dans les pages hors cas (accueil, « À propos », contact, mentions légales, confidentialité, page de groupe, 404), FR et EN ; les cas réutilisent leur `summary`. |
| 4.1 | Ajustement direct | Viable | Effort faible, risque faible. |

**Ce qui ne change pas** : les textes visibles, les gabarits de page, le budget de poids (quelques
centaines d'octets par page, très en deçà d'AD-8), la CSP (des balises `<meta>`, aucun script).

## 3. Approche recommandée

**Ajustement direct : une story, 9.8.** Arbitrages d'Arnaud du 04/10/2026, rendus avant la rédaction :

| # | Question | Réponse | Options écartées |
|---|---|---|---|
| 1 | Source de la description d'un cas | **Son `summary`** (l'encart « En bref », ≤ 400 caractères, écrit pour un dirigeant) | une clé `description` de ≤ 160 caractères par cas |
| 2 | Open Graph | **Oui, sans image** : `og:title`, `og:description`, `og:type`, `og:url`, `og:locale` (et `og:locale:alternate`) | avec la photo en `og:image` ; meta description seule |
| 3 | Qui écrit les descriptions hors cas | **Premier jet de l'agent**, tiré des textes existants, validé par Arnaud ligne par ligne (§ 4, Contenu) | rédaction par Arnaud |

## 4. Propositions de modification détaillées

### PRD — FR-40 (nouveau)

> **FR-40 : description et aperçu de chaque page.** Chaque page publiée porte, dans sa langue, une
> description qui dit ce qu'elle contient, lue par les moteurs et par les aperçus de partage.
> *Ajouté le 04/10/2026 (proposition de changement, mesures de v1.0.0).*
>
> **Conséquences (testables) :**
> - chaque page HTML publiée porte une `<meta name="description">` non vide et les balises Open
>   Graph `og:title`, `og:description`, `og:type`, `og:url`, `og:locale` ;
> - la description d'un cas est son `summary` ; celle de toute autre page est sa clé `description` ;
> - la description ne contient aucun `[TODO` dans une page publiée, et jamais l'adresse de l'éditeur
>   (C23) ;
> - FR et EN portent chacun la leur, dans leur langue.

### Architecture

**AD-25 (nouveau) — Le `<head>` d'une page : description et Open Graph.**
- **Binds :** FR-40, NFR-9 ; `layouts/_partials/` (le partial du `<head>`), front matter des pages.
- **Rule :**
  - un seul partial écrit la `<meta name="description">` et les balises Open Graph ;
  - la description vient de `.Params.summary` pour un cas, de `.Description` (clé `description` du
    front matter, native de Hugo) pour toute autre page ; rien n'est tronqué ni calculé par le
    gabarit, et une description absente **fait échouer le build** plutôt que de produire une balise
    vide (même règle que les valeurs légales, AD-9) ;
  - `og:title` reprend le `<title>` ; `og:url` le permalien absolu ; `og:type` vaut `website` pour
    l'accueil et `article` pour toute autre page ; `og:locale` vaut `fr_FR` ou `en_US`, avec
    `og:locale:alternate` pour l'autre langue quand la traduction existe ;
  - **pas d'`og:image`** (arbitrage 2) ;
  - C23 continue d'interdire l'adresse de l'éditeur dans toute meta, ce qui couvre la description des
    mentions légales.

**C26 (nouveau)** : sur la sortie de production, chaque page HTML porte exactement une
`<meta name="description">` non vide, égale au contenu de son `og:description`, sans `[TODO`, et les
cinq balises Open Graph ; contrôle bloquant, avec un test qui échoue sans lui.

### Backlog (`epics.md`, `sprint-status.yaml`)

**Story 9.8 : Page description and share previews** — En tant que recruteur qui reçoit le lien du
CV, je veux voir dans l'aperçu du lien et dans le moteur de recherche ce que contient la page, afin
de savoir avant de cliquer si elle me concerne. *Couvre :* FR-40 · AD-25 · C26, C23. *Dépendances :*
9.6, 11.11. *Prérequis de contenu :* les descriptions hors cas, validées par Arnaud (§ Contenu).
*Opération manuelle :* la publication `v1.0.1` par le skill `release`, lancée par Arnaud.
*Critères :* AD-25 rendu sur toutes les pages, FR et EN ; C26 et son test ; C3 (parité) traite
`description` comme une clé traduite ; build en échec si une description manque ; PageSpeed SEO
revérifié après publication, consigné dans `docs/measures/v1.0.1.md`.

`sprint-status.yaml` : `9-8-page-description-and-share-previews: backlog`, `epic-9: in-progress`,
placée dans l'ordre de travail après la 11.11b.

### Contenu — premier jet des descriptions hors cas (à valider par Arnaud)

Tiré des textes publiés ; environ 160 caractères au plus. Les cas n'en ont pas besoin : leur
`summary` sert (arbitrage 1).

| Page | FR | EN |
|---|---|---|
| Accueil | Développeur backend PHP et Symfony senior depuis 2008 : architecture, flux financiers fiables, jugement technique. Le CV et des cas concrets. | Senior PHP and Symfony backend developer since 2008: architecture, reliable financial flows, technical judgment. The CV and real-world cases. |
| À propos | Ce que je vends aujourd'hui : le jugement plutôt que la frappe — quoi construire, à quel coût, et ce qui casse si on se trompe. | What I offer today: judgment rather than typing — what to build, at what cost, and what breaks if we get it wrong. |
| Contact | Écrire à Arnaud Grousset pour un poste ou une mission : le contexte, le problème et l'échéance suffisent. Je réponds moi-même. | Write to Arnaud Grousset about a role or a contract: the context, the problem and the deadline are enough. I answer myself. |
| Mentions légales | Mentions légales d'eleyone.fr : éditeur, directeur de la publication et hébergeur du site. | Legal notice for eleyone.fr: the site's publisher, publication director and host. |
| Confidentialité | Ce site ne collecte aucune donnée personnelle : pages statiques, sans cookie, sans formulaire ni mesure d'audience. | This site collects no personal data: static pages, no cookies, no forms and no analytics. |
| Page Chiliz | Des cas tirés de quatre ans chez Chiliz sur des flux financiers on-chain : ce que j'ai décidé, ce qui a résisté, le résultat. | Cases from four years at Chiliz on on-chain financial flows: what I decided, what pushed back, and the outcome. |
| 404 | Cette page n'existe pas. L'accueil mène au CV d'Arnaud Grousset, développeur backend PHP et Symfony senior. | This page does not exist. The home page leads to the CV of Arnaud Grousset, senior PHP and Symfony backend developer. |

## 5. Transmission

**Périmètre : mineur.** Une story, développée par le flux habituel (revue de spec, PR, revue du
code, cinq verrous), puis publiée en `v1.0.1` par Arnaud.

**Critère de réussite** : chaque page en ligne porte sa description et ses balises Open Graph ;
l'audit « meta description » de PageSpeed passe sur les cinq gabarits ; un lien du CV collé dans
LinkedIn montre titre et description.

**Après accord** : la proposition passe en `approved` ; PRD, architecture, `epics.md` et
`sprint-status.yaml` sont modifiés dans la PR de cette branche (exception documentaire : tous les
fichiers sous `_bmad-output/`) ; les descriptions validées sont reportées dans le fichier de la
story 9.8.

## Application (04/10/2026)

Approuvée par Arnaud le 04/10/2026, descriptions comprises. Appliquée dans cette PR :

- PRD : FR-40, après FR-39.
- Architecture : AD-25, après AD-24 ; ligne C26 dans la liste des contrôles.
- `epics.md` : story 9.8, après la 9.7.
- `sprint-status.yaml` : `epic-9` en `in-progress`, `9-8-page-description-and-share-previews` en `backlog`, placée après la 11.11b dans l'ordre de travail, avec son prérequis de contenu.
