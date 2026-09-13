---
name: eleyone.fr — Dossier d'architecture
description: Portfolio et CV en ligne d'Arnaud Grousset (Eleyone), composé comme un dossier technique bien imprimé ; HTML statique, CSS seule, polices système, clair et sombre.
status: draft
updated: 2026-09-13
sources:
  - _bmad-output/planning-artifacts/prds/prd-eleyone.fr-2026-09-13/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md
  - docs/format-cas.md (v0.3)
  - data/stack.yaml
  - content/cases/chiliz/case-02-chiliz.fr.md
  - content/cases/chiliz/case-02-chiliz.en.md
  - branche experiment/d2-bilingue (experiments/d2-bilingue/theme.d2)
  - décisions d'Arnaud du 13/09/2026 (direction, accent, accueil CV, pages cas, CV PDF, mentions légales)
companions:
  - EXPERIENCE.md
  - .memlog.md
colors:
  # Mode clair (défaut, :root)
  paper: '#FBFBF9'
  surface: '#F0F2F4'
  plate: '#FFFFFF'
  ink: '#1C2030'
  ink-muted: '#555B6E'
  accent: '#1C6B45'
  rule: '#C9CDD8'
  border-strong: '#7B8194'
  # Mode sombre (@media (prefers-color-scheme: dark))
  paper-dark: '#14161D'
  surface-dark: '#1E222B'
  plate-dark: '#FFFFFF'
  ink-dark: '#E6E8EE'
  ink-muted-dark: '#A3A9B8'
  accent-dark: '#7CC79D'
  rule-dark: '#3A3F4D'
  border-strong-dark: '#6B7285'
typography:
  # Piles système uniquement (AD-8). « -md » = valeur à partir du point de rupture md (48rem).
  font-serif:
    fontFamily: 'Charter, "Bitstream Charter", "Sitka Text", Cambria, "Noto Serif", "DejaVu Serif", serif'
  font-mono:
    fontFamily: 'ui-monospace, "SF Mono", Menlo, Consolas, "Liberation Mono", "DejaVu Sans Mono", monospace'
  body:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.0625rem
    fontWeight: '400'
    lineHeight: '1.55'
  body-md:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.125rem
    fontWeight: '400'
    lineHeight: '1.55'
  body-sm:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1rem
    fontWeight: '400'
    lineHeight: '1.5'
  identity-name:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.625rem
    fontWeight: '700'
    lineHeight: '1.15'
    letterSpacing: -0.005em
  identity-name-md:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 2.25rem
    fontWeight: '700'
    lineHeight: '1.15'
    letterSpacing: -0.005em
  site-title:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.125rem
    fontWeight: '600'
    lineHeight: '1.3'
  site-title-md:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.3125rem
    fontWeight: '600'
    lineHeight: '1.3'
  pitch:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.0625rem
    fontWeight: '400'
    lineHeight: '1.55'
  pitch-md:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.1875rem
    fontWeight: '400'
    lineHeight: '1.55'
  page-title:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.75rem
    fontWeight: '700'
    lineHeight: '1.2'
  page-title-md:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 2.25rem
    fontWeight: '700'
    lineHeight: '1.2'
  case-title:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.5rem
    fontWeight: '700'
    lineHeight: '1.2'
  case-title-md:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.75rem
    fontWeight: '700'
    lineHeight: '1.2'
  section-heading:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.25rem
    fontWeight: '700'
    lineHeight: '1.3'
  section-heading-md:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.375rem
    fontWeight: '700'
    lineHeight: '1.3'
  entry-heading:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.1875rem
    fontWeight: '700'
    lineHeight: '1.3'
  case-link:
    fontFamily: '{typography.font-serif.fontFamily}'
    fontSize: 1.0625rem
    fontWeight: '600'
    lineHeight: '1.3'
  meta:
    fontFamily: '{typography.font-mono.fontFamily}'
    fontSize: 0.8125rem
    fontWeight: '400'
    lineHeight: '1.5'
  meta-md:
    fontFamily: '{typography.font-mono.fontFamily}'
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: '1.5'
  label:
    fontFamily: '{typography.font-mono.fontFamily}'
    fontSize: 0.8125rem
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: 0.08em
  rubric-number:
    fontFamily: '{typography.font-mono.fontFamily}'
    fontSize: 0.7em
    fontWeight: '400'
    lineHeight: '1'
rounded:
  none: '0'
  DEFAULT: '0'
spacing:
  '1': 0.25rem
  '2': 0.5rem
  '3': 0.75rem
  '4': 1rem
  '5': 1.5rem
  '6': 2.5rem
  '7': 4rem
  gutter: 1rem
  gutter-md: 2rem
  margin-column: 13.5rem
  column-gap: 2.5rem
  measure: 40rem
  aside-column: 15rem
  frame-md: 60rem
  frame-lg: 77.5rem
  bp-md: 48rem
  bp-lg: 80rem
  revision-bar: 2px
  focus-ring: 2px
  focus-offset: 3px
components:
  link:
    color: '{colors.accent}'
    textDecoration: 'underline 1px, offset 0.18em ; 2px au survol'
  focus-ring:
    outline: '{spacing.focus-ring} solid {colors.accent}'
    outlineOffset: '{spacing.focus-offset}'
  skip-link:
    background: '{colors.paper}'
    typography: '{typography.body-sm}'
  site-header:
    borderBottom: '1px {colors.rule}'
    brandTypography: '{typography.meta}'
    navTypography: '{typography.body-sm}'
  language-switch:
    typography: '{typography.body-sm}'
    color: '{colors.accent}'
  identity-block:
    nameTypography: '{typography.identity-name}'
    aliasColor: '{colors.ink-muted}'
    titleTypography: '{typography.site-title}'
    basedInTypography: '{typography.meta}'
    pitchTypography: '{typography.pitch}'
    photoSize: '4.5rem × 5.625rem ; 7.5rem × 9.375rem dès md'
  portrait:
    aspectRatio: '4 / 5'
    homeSize: '72 × 90 px sous md ; 120 × 150 px dès md'
    aboutSize: '120 × 150 px sous md ; 160 × 200 px dès md'
    border: 'none'
    maxWeightPerVariant: '40 Ko'
  cv-position:
    periodTypography: '{typography.meta}'
    periodColor: '{colors.ink-muted}'
    companyTypography: '{typography.entry-heading}'
    roleTypography: '{typography.body}'
    locationColor: '{colors.ink-muted}'
    separator: '1px {colors.rule}'
  attached-case:
    revisionBar: '{spacing.revision-bar} solid {colors.accent}'
    numberTypography: '{typography.meta}'
    numberColor: '{colors.ink-muted}'
    titleTypography: '{typography.case-link}'
  context-box:
    labelTypography: '{typography.label}'
    termTypography: '{typography.meta}'
    valueTypography: '{typography.body-sm}'
    background: '{colors.surface}'
    backgroundLg: 'none'
    borderTopLg: '{spacing.revision-bar} solid {colors.accent}'
  summary-box:
    labelTypography: '{typography.label}'
    textTypography: '{typography.body}'
    background: '{colors.surface}'
    borderLeft: '3px solid {colors.accent}'
  note-block:
    background: '{colors.surface}'
    borderLeft: '3px solid {colors.border-strong}'
  toc:
    summaryTypography: '{typography.label}'
    itemTypography: '{typography.body-sm}'
    numberColor: '{colors.ink-muted}'
  rubric-heading:
    numberTypography: '{typography.rubric-number}'
    numberColor: '{colors.ink-muted}'
  live-material-plate:
    background: '{colors.plate}'
    border: '1px solid {colors.border-strong}'
    padding: '{spacing.4}'
  live-material-planned:
    border: '1px dashed {colors.border-strong}'
    labelTypography: '{typography.label}'
  snippet:
    background: '{colors.surface}'
    typography: '{typography.meta-md}'
  site-footer:
    borderTop: '1px {colors.rule}'
    typography: '{typography.body-sm}'
  legal-list:
    termTypography: '{typography.meta}'
    valueTypography: '{typography.body}'
---

# eleyone.fr — Design

> Contrat visuel. Il dit à quoi le site ressemble. Le comportement (navigation, états, accessibilité, parcours) est dans `EXPERIENCE.md`, qui cite ces tokens par leur nom.
>
> Les maquettes « Dossier d'architecture » ont servi de base : le tour 1 pour la page cas (fichiers `cas-chiliz.html` et `style.css`, avec leurs captures), le tour 2 pour l'accueil CV (`index-vert.html`, `style.css` et captures). Elles sont restées hors du dépôt. **En cas de conflit, ce document et `EXPERIENCE.md` l'emportent sur les maquettes.**
>
> Les décisions d'Arnaud sont datées dans le texte ; celles du 13/09/2026 sur la mise en page sont récapitulées à la fin. Le document reste un brouillon jusqu'à sa relecture complète par Arnaud.

## Brand & Style

Le site se lit comme un **dossier d'architecture** : une ADR ou une RFC bien composée, qu'un CTO parcourt comme un document de travail. Arnaud vend du jugement. Le site le montre en étant sobre, exact et lisible, sans effet de séduction.

- **Le texte porte la page.** La hiérarchie vient de la taille, de la graisse et de l'espace. Pas de carte, d'ombre, de dégradé, d'icône, d'illustration ni d'animation.
- **Deux voix typographiques.** Le serif système porte le récit : identité, pitch, postes, cas. Le monospace système porte les métadonnées : dates, numéros, stack, étiquettes d'encart. C'est la convention des documents techniques.
- **Une seule couleur signifiante, le vert sapin.** Elle marque ce qui est cliquable (liens), ce qui prouve (la barre de révision qui attache les cas à un poste) et l'endroit où l'on est (focus, cible d'ancre). Elle ne sert jamais à décorer.
- **La barre de révision.** Dans la marge d'une RFC, un filet vertical signale un passage modifié. Ici, un filet vert de 2 px signale les postes qui ont une preuve. C'est le seul motif graphique propre au site.
- **Aucun gabarit « agence »** (NFR-6) : ni bandeau plein écran, ni photo en héros, ni jauges de compétences, ni logos de clients.

## Colors

La palette compte huit rôles par mode. Les tokens sombres portent le suffixe `-dark` et remplacent leur homologue sous `@media (prefers-color-scheme: dark)`, en propriétés personnalisées CSS, sans JavaScript (NFR-13, AD-8). La déclaration `color-scheme: light dark` accompagne ces tokens pour que les contrôles natifs (barres de défilement, `<details>`) suivent le mode.

| Rôle | Clair | Sombre | Usage | N'est jamais utilisé pour |
|---|---|---|---|---|
| `paper` | `#FBFBF9` | `#14161D` | fond de page | — |
| `surface` | `#F0F2F4` | `#1E222B` | fond des encarts « En bref », du bloc CV d'« À propos », des extraits, de « Contexte mission » sous `lg` | fond de page, lignes de tableau |
| `plate` | `#FFFFFF` | `#FFFFFF` | planche des schémas D2 dans le repli à planche claire | fond d'un texte du site |
| `ink` | `#1C2030` | `#E6E8EE` | texte courant, titres | liens |
| `ink-muted` | `#555B6E` | `#A3A9B8` | périodes, lieux, pseudonyme, numéros de cas et de rubrique, étiquettes | texte long, liens |
| `accent` | `#1C6B45` | `#7CC79D` | liens, barre de révision, filet haut de « Contexte mission » en marge, filet de « En bref », anneau de focus, marque de `:target` | fonds, titres, numéros, décoration |
| `rule` | `#C9CDD8` | `#3A3F4D` | filets de séparation décoratifs (sous l'en-tête, entre postes, au-dessus du pied de page) | toute frontière qui porte une information |
| `border-strong` | `#7B8194` | `#6B7285` | cadre de la planche de schéma, bord d'un conteneur défilant, filet des encarts neutres, pointillés du matériel « prévu » (rendu de travail) | texte |

### Contrastes calculés

Ratios WCAG 2.x, calculés par la formule de luminance relative (script Python hors dépôt). Seuils : 4,5:1 pour le texte, 3:1 pour les composants et les frontières signifiantes.

**Mode clair**

| Paire | Ratio | Seuil |
|---|---|---|
| `ink` sur `paper` | 15,61:1 | texte ✔ |
| `ink` sur `surface` | 14,41:1 | texte ✔ |
| `ink` sur `plate` | 16,17:1 | texte ✔ |
| `ink-muted` sur `paper` | 6,52:1 | texte ✔ |
| `ink-muted` sur `surface` | 6,02:1 | texte ✔ |
| `ink-muted` sur `plate` | 6,76:1 | texte ✔ |
| `accent` sur `paper` | **6,26:1** | texte ✔ |
| `accent` sur `surface` | 5,78:1 | texte ✔ |
| `accent` sur `plate` | 6,48:1 | texte ✔ |
| `border-strong` sur `paper` | 3,75:1 | composant ✔ |
| `border-strong` sur `surface` | 3,46:1 | composant ✔ |
| `rule` sur `paper` | 1,53:1 | décoratif seulement |
| `accent` contre `ink` | 2,49:1 | insuffisant pour distinguer un lien par la couleur seule : les liens sont soulignés |

**Mode sombre**

| Paire | Ratio | Seuil |
|---|---|---|
| `ink-dark` sur `paper-dark` | 14,75:1 | texte ✔ |
| `ink-dark` sur `surface-dark` | 13,00:1 | texte ✔ |
| `ink-muted-dark` sur `paper-dark` | 7,68:1 | texte ✔ |
| `ink-muted-dark` sur `surface-dark` | 6,77:1 | texte ✔ |
| `accent-dark` sur `paper-dark` | **9,05:1** | texte ✔ |
| `accent-dark` sur `surface-dark` | 7,97:1 | texte ✔ |
| `border-strong-dark` sur `paper-dark` | 3,76:1 | composant ✔ |
| `border-strong-dark` sur `surface-dark` | 3,31:1 | composant ✔ |
| `border-strong-dark` sur `plate-dark` (`#FFFFFF`) | 4,80:1 | composant ✔ |
| `rule-dark` sur `paper-dark` | 1,72:1 | décoratif seulement |
| `accent-dark` contre `ink-dark` | 1,63:1 | idem : soulignement obligatoire |
| `plate-dark` (`#FFFFFF`) contre `paper-dark` | 18,07:1 | saut de luminance : c'est l'éblouissement que corrige le schéma sombre (voir « Accord avec D2 ») |

Pire paire de texte : `accent` sur `surface` en clair (5,78:1), `ink-muted-dark` sur `surface-dark` en sombre (6,77:1). Pire frontière signifiante : `border-strong-dark` sur `surface-dark` (3,31:1).

### Accord avec les schémas D2

Le thème commun `diagrams/theme.d2` (AD-7) part du thème D2 Neutral Grey, avec une encre ardoise et des bordures bleu ardoise. Il reste **neutre** : un schéma ne contient pas de lien, donc pas de vert. Le vert reste réservé au site, et le schéma ne lui fait pas concurrence.

**Thème clair actuel** (branche `experiment/d2-bilingue`), mesuré :

| Paire D2 | Ratio |
|---|---|
| N1 `#1F2933` sur N7 `#FFFFFF` | 14,76:1 |
| N1 sur B6 `#F8FAFC` | 14,10:1 |
| N1 sur B5 `#F0F4F8` | 13,35:1 |
| N1 sur B4 `#D9E2EC` | 11,27:1 |
| N2 `#3E4C59` sur N6 `#E4E7EB` | 7,10:1 |
| N3 `#616E7C` sur N7 | 5,21:1 |
| B1 `#334E68` (bordures) sur N7 | 8,64:1 |
| B2 `#486581` sur N7 | 6,08:1 |

**Décision : N1 aligné sur `ink` (`#1C2030`)** (validé par Arnaud le 13/09/2026). L'écart avec `#1F2933` est invisible, mais une seule encre simplifie le thème. Ratios : 16,17:1 sur N7, 15,46:1 sur B6, 12,35:1 sur B4. Le coût est faible tant qu'aucun SVG de production n'est commité.

**Décision : SVG D2 à double thème** (validé par Arnaud le 13/09/2026), **sous réserve d'un spike** qui vérifie le rendu dans `<img>`, le déterminisme octet par octet et un poids ≤ 60 Ko (impact AD-7). Repli si le spike échoue : planche claire encadrée. D2 accepte, dans `d2-config`, un thème sombre (`dark-theme-id` et `dark-theme-overrides`) qu'il embarque dans le SVG sous une règle `prefers-color-scheme`. Valeurs de départ pour le spike, alignées sur les tokens sombres du site :

| Clé D2 | Valeur | Paire mesurée | Ratio |
|---|---|---|---|
| N1 (texte) | `#E6E8EE` | sur N7 `#1E222B` | 13,00:1 |
| N1 | | sur B6 `#232834` | 12,03:1 |
| N1 | | sur B5 `#283040` | 10,80:1 |
| N1 | | sur B4 `#2F3848` | 9,63:1 |
| N2 | `#C5CAD5` | sur N6 `#2B2F3A` | 8,14:1 |
| N3 | `#A3A9B8` | sur N7 | 6,77:1 |
| B1 (bordures) | `#9FB3C8` | sur N7 | 7,40:1 |
| B2 | `#8DA2BB` | sur N7 | 6,08:1 |
| B3 | `#7B8BA0` | sur N7 | 4,58:1 (la valeur `#5A6B80` ne donnait que 2,92:1) |
| N7 (fond) | `#1E222B` | contre `paper-dark` | 1,13:1 : la planche garde un cadre `border-strong-dark` |

Les autres clés (N4 à N6, AA*, AB*) se fixent au spike, avec la même règle : 4,5:1 pour tout texte, 3:1 pour toute bordure qui délimite une forme.

## Typography

### Piles

- **Serif** : `{typography.font-serif.fontFamily}`. Charter sur macOS et iOS, Sitka Text ou Cambria sur Windows, Noto Serif sur Android, DejaVu Serif en dernier repli Linux.
- **Monospace** : `{typography.font-mono.fontFamily}`.
- Aucune police web (AD-8). Les tailles sont en `rem` : le réglage de taille du navigateur est respecté, et `html` n'impose aucune taille en pixels.

### Échelle

| Rôle | Token (sous md) | Token (dès md) | Où |
|---|---|---|---|
| Nom de la ligne d'identité | `identity-name` 1,625 rem | `identity-name-md` 2,25 rem | accueil |
| Titre du site | `site-title` 1,125 rem / 600 | `site-title-md` 1,3125 rem | accueil |
| Pitch | `pitch` 1,0625 rem | `pitch-md` 1,1875 rem | accueil |
| Titre de page | `page-title` 1,75 rem | `page-title-md` 2,25 rem | page Chiliz (« Chiliz »), page cas seul (titre du cas), pages simples, 404 |
| Titre de cas dans une page de groupe | `case-title` 1,5 rem | `case-title-md` 1,75 rem | page Chiliz |
| Titre de bloc, de rubrique | `section-heading` 1,25 rem | `section-heading-md` 1,375 rem | accueil (« Parcours »…), rubriques des cas, sections des pages simples |
| Société d'un poste | `entry-heading` 1,1875 rem | idem | accueil |
| Lien de cas rattaché | `case-link` 1,0625 rem / 600 | idem | accueil |
| Texte courant | `body` 1,0625 rem | `body-md` 1,125 rem | partout |
| Texte secondaire | `body-sm` 1 rem | idem | valeurs de « Contexte mission », sommaire, en-tête, pied de page |
| Métadonnées | `meta` 0,8125 rem | `meta-md` 0,875 rem | périodes, « Basé en France », numéros « Cas 02 », stack |
| Étiquettes d'encart | `label` 0,8125 rem / 600, capitales CSS, +0,08 em | idem | « En bref », « Contexte mission », « Sommaire » |
| Numéro de rubrique | `rubric-number` 0,7 em du titre | idem | « 02.3 » devant une rubrique |

- **Le style suit le rôle, pas la balise.** Le hook de titres (AD-4) descend les rubriques d'un niveau dans une page de groupe (`h2` → `h3`). Une rubrique garde pourtant la même apparence sur une page cas et sur la page Chiliz : les gabarits posent une classe de rôle (`rubric-heading`, `case-title`, etc.).
- **Capitales des étiquettes** : `text-transform: uppercase` en CSS. Le HTML garde la casse normale (« En bref »), et les lecteurs d'écran ne l'épellent pas.
- **Graisse** : 400, 600 et 700 seulement. Pas d'italique de mise en valeur hors contenu Markdown (`*…*`).
- **Chiffres** : pas de réglage `font-variant-numeric` imposé. Les périodes sont en monospace, donc déjà alignées.

### Typographie française et anglaise

Règles de composition, appliquées au rendu des pages FR (validé par Arnaud le 13/09/2026) ; impact architecture I-8 dans `EXPERIENCE.md` :

- **Pages FR** : espace fine insécable (U+202F) avant `;`, `!`, `?` et à l'intérieur des guillemets « », espace insécable (U+00A0) avant `:`. Rien dans les blocs de code, les URL ni les attributs.
- **Pages EN** : aucune espace avant la ponctuation ; guillemets “ ”.
- **Pas de césure automatique** : `hyphens: manual`. `overflow-wrap: break-word` empêche un mot long (URL, identifiant) de provoquer un défilement horizontal.
- **Retour à la ligne** : `text-wrap: balance` sur les titres, `text-wrap: pretty` sur les paragraphes, sans effet là où ce n'est pas pris en charge.
- **Périodes** : chaque date reste insécable (« septembre&nbsp;2025 »), le tiret demi-cadratin est entouré d'espaces, et la coupure n'est permise qu'après lui. Dans une colonne de marge étroite, une période longue passe donc proprement sur deux lignes.
- **Séparateur « · »** : précédé d'une espace insécable, pour qu'il ne commence jamais une ligne (ligne d'identité, titre du site, ligne rôle · lieu).

## Layout & Spacing

### Échelle d'espacement

`{spacing.1}` 0,25 · `{spacing.2}` 0,5 · `{spacing.3}` 0,75 · `{spacing.4}` 1 · `{spacing.5}` 1,5 · `{spacing.6}` 2,5 · `{spacing.7}` 4 (rem). Tout écart vertical ou horizontal vient de cette échelle.

- Entre deux blocs de premier niveau (identité → Parcours → En parallèle…) : `{spacing.6}` sous md, `{spacing.7}` dès md.
- Entre deux postes : `{spacing.4}` puis un filet `rule`, `{spacing.5}` dès md.
- Entre deux cas rattachés : `{spacing.2}`, `{spacing.3}` dès md.
- Avant une rubrique de cas : `{spacing.6}` ; après son titre : `{spacing.4}`.

### Grille, mesure, cadres

- **Gouttière latérale** : `{spacing.gutter}` (1 rem) sous md, `{spacing.gutter-md}` (2 rem) dès md. Elle ne descend jamais sous 1 rem.
- **Mesure** : colonne de texte de `{spacing.measure}` (40 rem) au plus, soit environ 70 caractères en serif à 18 px.
- **Colonne de marge** : `{spacing.margin-column}` (13,5 rem), séparée du texte par `{spacing.column-gap}` (2,5 rem). Son contenu est aligné à droite, contre le texte : périodes, numéros, sommaire, photo.
- **Colonne de note** (page cas, dès lg) : `{spacing.aside-column}` (15 rem), à droite du texte, pour « Contexte mission ».
- **Cadre unique dès lg** : toutes les pages utilisent le cadre `{spacing.frame-lg}` (77,5 rem), marge | texte | note. La colonne de texte reste donc au même endroit d'une page à l'autre. La colonne de note est vide hors des pages cas.
- **Cadre md** (48 à 80 rem) : `{spacing.frame-md}` (60 rem), marge | texte, sur toutes les pages.

### Points de rupture

| Nom | Condition | Grille |
|---|---|---|
| `sm` (défaut, mobile d'abord) | < `{spacing.bp-md}` (48 rem, 768 px) | une colonne ; les éléments de marge passent au-dessus de leur texte |
| `md` | ≥ 48 rem | marge + texte |
| `lg` | ≥ `{spacing.bp-lg}` (80 rem, 1 280 px) | marge + texte + note |

Vérifications par gabarit : 320 px de large sans défilement horizontal de la page, et 390 × 844 pour le premier écran (voir `EXPERIENCE.md`).

### Mise en page par page

Le contenu et l'ordre sont fixés par le PRD. Ce tableau fixe seulement leur disposition.

**Accueil (CV)** — `/`, `/en/`

| Zone | sm | md et lg |
|---|---|---|
| Identité | ligne d'identité sur toute la largeur moins la photo, photo `identity-block.photoSize` à droite sur les lignes nom → « Basé en France », pitch pleine largeur dessous | photo dans la colonne de marge, alignée à droite ; nom, titre du site, « Basé en France », pitch dans la colonne de texte |
| « Parcours » | titre de bloc, puis postes empilés : période (meta) au-dessus de la société | titre de bloc dans la colonne de texte ; chaque poste est une ligne de registre : période dans la marge, société, rôle, lieu et cas dans le texte |
| « En parallèle » | même composant que « Parcours » (poste `track: parallel`) | idem |
| « Formation, certification, langues » | registre compact, un sous-titre `label` par nature (formation, certification, langues) | période éventuelle dans la marge |
| Appel à contact | titre de bloc, puis un lien | idem |
| Pied de page | voir le composant | idem |

Pas de numéro de section « § » sur l'accueil (validé par Arnaud le 13/09/2026) : sur mobile, il alourdit « Parcours » sans aider à lire un CV.

**Page cas seul** (cas 01, 05, 06) — `/cas/<slug>/`, `/en/cases/<slug>/`

| Zone | sm | md | lg |
|---|---|---|---|
| Lien de retour au parcours | texte, en haut | colonne de texte | idem |
| « Cas 05 » (numéro) + titre (`page-title`) | empilés | numéro dans la marge, aligné sur la première ligne du titre | idem |
| Sommaire | `<details>` fermé, une ligne | ouvert dans la colonne de marge, collant (`position: sticky`) | idem |
| « Contexte mission » | encart `surface`, sous le titre | idem, dans la colonne de texte | dans la colonne de note, à hauteur de « En bref », filet vert en haut, sans fond |
| « En bref » | encart `surface`, filet vert à gauche | idem | idem |
| Rubriques | numéro « 05.1 » devant le titre | numéro suspendu dans la marge | idem |

**Page Chiliz** (page de groupe) — `/cas/chiliz/`, `/en/cases/chiliz/`

Même grille que la page cas seul, avec ces différences :

- `page-title` « Chiliz », suivi de l'introduction si la question 9 en prévoit une ;
- un sommaire unique qui liste chaque section publiée (« Cas 02 — titre ») et, en retrait, ses rubriques ;
- chaque section commence par un filet `rule` plein cadre, puis « Cas 02 » en `meta` et le titre en `case-title` ;
- « Contexte mission » et « En bref » se répètent dans chaque section. Dès lg, chaque « Contexte mission » se place dans la colonne de note, à hauteur de sa propre section.

**À propos** — `/a-propos/`, `/en/about/` : `page-title`, puis la version plus grande du `portrait` (sous le titre sous md, dans la marge dès md) (validé par Arnaud le 13/09/2026), puis le bloc CV (`note-block`) s'il existe, puis le texte dans la colonne de texte. Sections en `section-heading`, sans numéro.

**Contact** — `/contact/`, `/en/contact/` : `page-title`, texte d'introduction du contenu, puis une liste de définitions. Les termes (« Courriel », « LinkedIn ») sont en `meta`, dans la marge dès md ; les valeurs sont des liens en `body`.

**Mentions légales** — `/mentions-legales/`, `/en/legal-notice/` : `page-title`, puis trois groupes en `section-heading` (Éditeur, Directeur de la publication, Hébergeur), chacun en `legal-list`. C'est la seule page qui affiche l'adresse déclarée de l'éditeur, injectée au build (AD-9).

**Politique de confidentialité** — `/confidentialite/`, `/en/privacy/` : page simple, `page-title` puis sections en `section-heading`.

**404** — `/404.html`, `/en/404.html` : `page-title`, une phrase, deux liens (accueil de la langue, accueil de l'autre langue). Même en-tête et même pied de page que les autres pages.

## Elevation & Depth

Aucune élévation. Pas d'ombre, pas de flou, pas de superposition hors du focus.

- La profondeur se limite à deux plans : `paper` pour la page, `surface` pour les encarts (« En bref », bloc CV, extraits, « Contexte mission » sous lg). Dans les deux modes, `surface` est un peu plus sombre que `paper` en clair et un peu plus clair en sombre.
- La planche `plate` n'existe que dans le repli à planche claire des schémas, toujours avec un cadre `border-strong`.
- Rien n'est collant sauf le sommaire dans la colonne de marge (md et lg). Il ne recouvre jamais le texte : pas d'en-tête collant, pas de bandeau.

## Shapes

Angles droits partout : `{rounded.none}`. Un document imprimé n'a pas de coins arrondis. La photo, les encarts, la planche et l'anneau de focus sont rectangulaires.

Les seuls traits :

| Trait | Épaisseur | Couleur | Sens |
|---|---|---|---|
| Barre de révision | `{spacing.revision-bar}` | `accent` | ce poste a des preuves |
| Filet de « En bref » | 3 px à gauche | `accent` | résumé du cas |
| Filet de « Contexte mission » (lg) | 2 px en haut | `accent` | note de marge du cas |
| Filet d'encart neutre (bloc CV, encart thématique) | 3 px à gauche | `border-strong` | encart sans lien avec un cas |
| Cadre de planche, conteneur défilant | 1 px | `border-strong` | limite de l'image ou de la zone qui défile |
| Filets de séparation | 1 px | `rule` | décoratif |
| Matériel « prévu » (rendu de travail seulement) | 1 px pointillé | `border-strong` | élément absent en production |

## Components

Chaque composant a son pendant comportemental, sous le même nom, dans `EXPERIENCE.md` (« Component Patterns »).

### link

Couleur `{colors.accent}`, soulignement de 1 px décalé de 0,18 em, 2 px au survol. **Tous les liens sont soulignés**, y compris dans l'en-tête, le pied de page et le sommaire. Aucune couleur distincte pour les liens visités. Deux exceptions de couleur, soulignement conservé : la marque `eleyone.fr` et les entrées du sommaire gardent un texte `ink`, avec un soulignement `accent`, pour ne pas faire du sommaire un bloc vert.

### focus-ring

`:focus-visible` : contour `{spacing.focus-ring}` plein `{colors.accent}`, décalé de `{spacing.focus-offset}`, sans arrondi. Il est visible sur `paper` (6,26:1 et 9,05:1) comme sur `surface` (5,78:1 et 7,97:1). En `forced-colors: active`, le contour passe à la couleur système (`Highlight`) : on n'utilise ni `outline: none` ni une ombre à la place.

### skip-link

« Aller au contenu » / *Skip to content*. Hors écran tant qu'il n'a pas le focus ; au focus, il apparaît en haut à gauche sur `paper`, en `body-sm`, avec l'anneau de focus.

### site-header

Une seule ligne sur mobile à 390 px, un filet `rule` dessous. Hauteur visée : 44 px au plus.

- À gauche : la marque `eleyone.fr` en `meta`, lien vers l'accueil de la langue.
- À droite : « À propos », « Contact », puis le sélecteur de langue, en `body-sm`.
- **Pas de lien vers les CV PDF** (décision d'Arnaud du 13/09/2026) : c'est ce qui alourdissait l'en-tête mobile de la maquette.
- À 320 px, la navigation passe à la ligne sous la marque. C'est accepté ; il n'y a pas de menu repliable.

### language-switch

Un seul lien vers la page équivalente : « English » sur une page FR (`lang="en"`, `hreflang="en"`), « Français » sur une page EN (`lang="fr"`, `hreflang="fr"`) (validé par Arnaud le 13/09/2026) ; la maquette affichait « FR / EN ». C'est le dernier élément de l'en-tête. Même style que les autres liens de navigation.

### identity-block

- **Ligne d'identité** (`h1`) : « Arnaud Grousset » en `identity-name`, suivi de « · Eleyone » à 0,72 em, en graisse 400 et `ink-muted`. Le groupe « · Eleyone » est insécable : sur mobile, il passe entier à la ligne.
- **Titre du site** en `site-title`. Les deux segments autour du « · » sont insécables chacun, pour qu'aucun « · » n'ouvre une ligne.
- **« Basé en France »** en `meta`, `ink-muted`. C'est la seule mention de résidence du site hors mentions légales.
- **Pitch** en `pitch`, dans la mesure.
- **Photo** : voir le composant `portrait`. Sur l'accueil, elle est placée à droite du nom sous md et dans la colonne de marge dès md. Elle ne repousse jamais le pitch sous le premier écran mobile.
  - **Poids de l'accueil** : HTML (≤ 50 Ko), CSS (visée ≤ 14 Ko non minifiée, limite 20 Ko) et une seule variante de photo (≤ 40 Ko) restent sous 110 Ko, loin des 200 Ko d'AD-8.

### portrait

La photo d'identité est le portrait existant d'Arnaud, **recadré sur le visage et les épaules**. Le recadrage se fait dans la story de préparation de la photo, par le Hugo épinglé (`scripts/photo/prepare.sh`, AD-19). Aucun autre outil d'image n'intervient.

- **Ratio du cadrage : 4:5** (portrait vertical), le même partout. Un seul cadrage sert à toutes les tailles : aucune page ne recadre autrement.
- **Composition visée** : le haut de la tête à environ 10 % du bord supérieur, les yeux vers 40 % de la hauteur, les épaules coupées par le bord inférieur, le visage centré horizontalement. Le fond de la photo n'est pas retouché.
- **Copie commitée** : 640 × 800 px (4:5, ≤ 800 px de côté), ≤ 150 Ko. Elle est produite par recadrage puis redimensionnement de l'original, avec un point d'ancrage choisi à la préparation (`Top`, `Center`…) et vérifié à l'œil. L'ancrage automatique `Smart` n'est pas utilisé : il peut couper le haut du visage.
- **Rendu** : ni cadre, ni arrondi, ni filtre, ni ombre, identique en mode clair et en mode sombre. `alt` = `portrait_alt` dans la langue de la page. Les attributs `width` et `height` valent la taille 1x, et la CSS réduit l'image sans en changer le ratio.
- **Budget** (décidé par Arnaud le 13/09/2026) : **≤ 40 Ko par variante publiée**. Chaque page ne charge qu'une variante, et C20 mesure le poids réel.

| Emplacement | Affichage sous md | Affichage dès md | Variantes publiées (WebP, empreintées) |
|---|---|---|---|
| Accueil, `identity-block` | 72 × 90 px CSS, à droite du nom | 120 × 150 px CSS, dans la colonne de marge, alignée à droite | 1x 120 × 150 · 2x 240 × 300 |
| À propos (version plus grande, validée par Arnaud le 13/09/2026) | 120 × 150 px CSS, sous le titre, avant le bloc CV | 160 × 200 px CSS, dans la colonne de marge, à hauteur du titre | 1x 160 × 200 · 2x 320 × 400 |

- Quatre variantes au total, toutes ≤ 640 px de large (limite d'AD-19). Sous md, la page À propos réutilise la variante 160 × 200 réduite à 120 × 150 : pas de cinquième fichier.
- **Marge de budget** : à 240 × 300 px, un portrait serré en WebP qualité 80 tient largement sous 40 Ko. La variante 320 × 400 est la plus exposée. Si C20 la mesure au-dessus de 40 Ko, on baisse sa qualité (75, puis 70) plutôt que sa taille, et on le consigne dans AD-19.
- **Version À propos retenue** (13/09/2026) : les quatre variantes sont produites.

### cv-position

Un poste de « Parcours » ou d'« En parallèle ».

- **Période** en `meta` et `ink-muted`. Dans la colonne de marge dès md, au-dessus de la société sous md. **La colonne de marge ne contient que la période** : le lieu et le cadre passent dans la colonne de texte, ce qui corrige le lieu de travail en monospace qui passait mal à la ligne dans la marge de la maquette.
- **Société** (`h3`) en `entry-heading`. Pour Ton Pote le Geek, le nom est un lien vers son site.
- **Ligne de rôle** en `body` : intitulé du poste (`role`), puis « · », puis, en `ink-muted` et dans cet ordre, ceux qui existent parmi : `location` (ville de travail ou « Full remote »), le libellé du cadre `setup`, et la société de prestation `via` (« prestation Modis » / *via Modis*). Champs `location` et `via` validés par Arnaud le 13/09/2026 (AD-18).
- **Corps du poste** (Markdown facultatif, AD-18) en `body-sm`, affiché seulement pour un poste sans cas publié (validé par Arnaud le 13/09/2026). Un poste avec cas n'affiche pas son corps : ses cas en tiennent lieu.
- **Filet** `rule` entre deux postes, sur la seule colonne de texte dès md (la marge reste nette).
- **Poste sans cas** (confirmé par Arnaud le 13/09/2026) : affiché normalement, avec société, rôle, période, lieu et cadre, puis plus rien. Pas de zone de cas, pas de barre de révision, pas de tiret, pas de mention d'absence.
- **Rattachement** : la liste des cas vient de la clé `position` de chaque cas (format des cas v0.4, validé ; `featured` supprimé, il n'y a plus de cas mis en avant).

### attached-case

La sous-liste des cas publiés d'un poste.

- **Barre de révision** : `border-left` `{spacing.revision-bar}` `{colors.accent}`, retrait intérieur `{spacing.4}` (`{spacing.5}` dès md). Elle couvre toute la liste, pas chaque cas.
- **Numéro** « Cas 02 » en `meta` et `ink-muted` : au-dessus du titre sous md, dans une petite colonne de 3,75 rem dès md (retrait suspendu), pour aligner les numéros verticalement.
- **Titre du cas** : lien en `case-link`, qui mène à la page cas ou à la section de la page Chiliz.
- **Pas d'« En bref » sur l'accueil** (validé par Arnaud le 13/09/2026). Numéro et titre suffisent : le titre est rédigé comme une affirmation (≤ 70 caractères). La maquette affichait le résumé du cas 02, trop dense à côté des postes sans cas sur grand écran, et coûteux pour le premier écran mobile. « En bref » garde sa place sur la page cas (FR-5, FR-7).
- **Cas non publié** : absent. Pas de ligne « En bref à venir », pas de titre sans lien.

### context-box

Encart « Contexte mission » / *Engagement context* (format des cas, FR-6).

- **Étiquette** en `label`, `ink-muted`.
- **Liste de définitions** : cinq couples terme / valeur, dans l'ordre Société, Cadre, Rôle, Période, Stack (*Company, Engagement, Role, Period, Stack*).
  - Sous lg : fond `surface`, retrait `{spacing.4}`, grille de deux colonnes (terme de 6 rem en `meta` et `ink-muted`, valeur en `body-sm`). L'encart garde sa hauteur même quand le rôle est long.
  - Dès lg : dans la colonne de note, sans fond, filet vert de 2 px en haut, termes au-dessus des valeurs.
- **Stack** : liste en `meta`, séparée par des virgules générées en CSS, qui passe à la ligne entre les éléments et jamais au milieu d'un nom (« Symfony UX »).
- **Cadre** : libellé i18n de `setup` (« Salarié », *Employee*…).

### summary-box

Encart « En bref » / *At a glance* (FR-7).

- Étiquette en `label` ; texte en `body`, dans la mesure.
- Fond `surface`, filet vert de 3 px à gauche, retrait `{spacing.4}`.
- Sa hauteur est bornée par le format (3 phrases, 400 caractères) : aucun « Lire la suite », aucune troncature.

### note-block

Encart neutre qui ne résume pas un cas : bloc CV d'« À propos » et encart thématique du matériel vivant. Fond `surface`, filet `border-strong` de 3 px à gauche, étiquette en `label`.

### cv-links

Liens vers les CV PDF. Emplacements décidés par Arnaud le 13/09/2026 : **pied de page de toutes les pages, et en évidence sur « À propos »**, jamais dans l'en-tête.

- Un lien par fichier, avec un texte autonome : « CV en PDF, français (NNN Ko) » et « CV en PDF, anglais (NNN Ko) » ; en EN, *CV (PDF, English, NNN KB)* et *CV (PDF, French, NNN KB)*. La taille est lue au build. Le CV de la langue de la page vient en premier.
- **Pied de page** : sur sa propre ligne, en `body-sm`.
- **À propos** : dans un `note-block` placé juste sous le titre, avec l'étiquette « CV » en `label` et les deux liens en `body`, chacun sur sa ligne.
- **Fichiers absents ou refusés par le contrôle** : le composant n'est pas rendu. Rien ne le remplace : ni ligne vide, ni étiquette seule, ni mention « bientôt ».

### toc

Sommaire d'une page cas ou de la page Chiliz.

- **Sous md** : élément `<details>` fermé, avec un résumé d'une ligne en `label` (« Sommaire · 6 rubriques ») et le marqueur natif du navigateur. Ouvert, il affiche la liste en `body-sm`. Il occupe environ 2,75 rem fermé, contre environ 230 px dans la maquette (validé par Arnaud le 13/09/2026).
- **Dès md** : dans la colonne de marge, collant, liste visible. Le résumé est masqué et le contenu forcé visible par `::details-content`. Un navigateur qui ne prend pas en charge ce pseudo-élément garde le sommaire repliable dans la marge : la page reste utilisable.
- **Entrées** : numéro en `ink-muted` (« 02.3 »), texte `ink`, soulignement `accent`. Page Chiliz : un niveau par section publiée (« Cas 02 — titre »), rubriques en retrait de 2,5 ch.
- **Entrée courante** : pas de mise en évidence de défilement (il faudrait du JavaScript). La cible d'une ancre est marquée dans le texte (voir `rubric-heading`).

### rubric-heading

Titre de rubrique d'un cas, en `section-heading`.

- **Numéro** « 02.3 » : numéro du cas, point, rang de la rubrique dans le cas, en `rubric-number` et `ink-muted`. Sous md, il précède le titre, séparé par une espace de largeur fixe ; dès md, il est suspendu dans la colonne de marge, aligné à droite.
- **Numéroter par le cas, pas par la position dans la page** (validé par Arnaud le 13/09/2026) : le numéro « 02.3 » reste le même quand le cas 03 ou le cas 04 est publié sur la page Chiliz. Deux versions linguistiques ont les mêmes rubriques (C3), donc les mêmes numéros.
- **Cible d'ancre** (`:target`) : barre `accent` de 2 px à gauche du titre, dans la gouttière, sans animation. Même marque pour la section d'un cas sur la page Chiliz (`#case-02`), à gauche de son titre.
- `scroll-margin-top: {spacing.5}` : le titre ne colle pas au bord supérieur de la fenêtre.

### live-material-slot

Emplacement de matériel vivant (AD-6). En production, un élément « prévu » ne produit rien : ni cadre, ni espace réservé.

| Type (statut « prêt ») | Rendu visuel |
|---|---|
| Schéma | `figure` pleine mesure. Planche avec cadre 1 px `border-strong` et retrait `{spacing.4}`, SVG à `width: 100%` et `height: auto` s'il est étroit. S'il est large, voir « schéma large ». Sous l'image, une ligne en `meta` : « Schéma · Ouvrir en taille réelle » (le second segment est un lien vers le SVG). |
| Vidéo | Un paragraphe en `body` : lien dont le texte est la description de l'élément, suivi de « (vidéo sur YouTube) » dans le lien. Pas de vignette, pas de lecteur. |
| Extrait | `figure` avec `pre` en `meta-md` sur `surface`, retrait `{spacing.4}`, défilement horizontal dans le bloc seulement, cadre 1 px `border-strong` pour montrer la limite de la zone qui défile. |
| Encart thématique | `note-block`, avec en étiquette le titre de l'encart tiré de son Markdown. |

**Schéma large.** Le SVG garde son rapport, et ses libellés doivent rester lisibles, soit environ 12 px CSS au rendu :

- **Schéma étroit** (largeur intrinsèque ≤ 480 px) : réduit à la mesure.
- **Schéma large** : placé dans un conteneur à défilement horizontal, avec une largeur affichée égale à 75 % de sa largeur intrinsèque (attribut `width` posé par le gabarit, sans `style` en ligne à cause de la CSP), cadre `border-strong`, et le lien « Ouvrir en taille réelle ». Dès que la mesure dépasse cette largeur, le conteneur ne défile plus.
- Conseil de dessin (AD-7) : des schémas pensés en hauteur (`direction: down`), des libellés courts coupés à la main, et une largeur intrinsèque visée de 600 px au plus.

**Mode sombre.** Cible : le SVG à double thème D2 (voir « Accord avec les schémas D2 »), qui suit `prefers-color-scheme` dans l'image (validé par Arnaud le 13/09/2026), sous réserve du spike (`<img>`, déterminisme octet par octet, ≤ 60 Ko). Repli si le spike échoue : planche `plate-dark` (`#FFFFFF`) avec cadre `border-strong-dark` (4,80:1) et retrait `{spacing.4}`, **sans filtre** de luminosité. Le filtre de la maquette baissait le contraste du schéma sans supprimer l'éblouissement.

**Rendu de travail seulement** (`live-material-planned`) : bloc en pointillés `border-strong`, étiquette `label` « Prévu · schéma » (ou vidéo, extrait, encart), puis l'identifiant en `meta` et la description en `body-sm`.

### site-footer

Filet `rule` en haut, espace `{spacing.6}` au-dessus, `body-sm`, dans la colonne de texte. Lignes, dans cet ordre :

1. `cv-links`, si les fichiers existent et ont passé le contrôle ; sinon la ligne n'existe pas.
2. « Mentions légales » · « Confidentialité » · « Code source du site » (dépôt public, FR-29) ; en EN, *Legal notice* · *Privacy* · *Site source code*.

Pas de copyright, de logo ni de réseaux sociaux. Chaque lien est une entrée de liste, avec un interligne qui garantit une cible d'au moins 24 px.

### legal-list

Liste de définitions des mentions légales. Termes en `meta` et `ink-muted` (Nom, Adresse, Contact, Immatriculation), dans la marge dès md ; valeurs en `body`. L'adresse est rendue telle qu'elle est injectée, dans un élément `address`, sans lien vers une carte et sans microdonnée. **La commune de l'éditeur n'apparaît que dans cette liste** : ni dans le `<title>`, ni dans la description, ni dans le JSON-LD, ni sur une autre page.

## Do's and Don'ts

| À faire | À éviter |
|---|---|
| Hiérarchiser par taille, graisse et espace | Cartes, ombres, dégradés, icônes, illustrations |
| Réserver `accent` aux liens, à la barre de révision, aux filets d'encart de cas, au focus et à `:target` | Vert sur un titre, un numéro, un fond ou une puce |
| Souligner tous les liens | Distinguer un lien par la couleur seule |
| Mettre les métadonnées en monospace (périodes, numéros, stack, étiquettes) | Du texte long en monospace, ou des rôles et lieux dans la marge monospace |
| Laisser vide ce qui n'existe pas (poste sans cas, CV absent, matériel prévu) | « En bref à venir », « Aucun cas », tirets, espaces réservés |
| Angles droits, filets de 1 à 3 px | Coins arrondis, bordures épaisses |
| Polices système en `rem` | Police web, taille de base en pixels |
| Mesurer chaque nouvelle paire de couleurs dans les deux modes | Ajouter une couleur sans ratio calculé |
| Planche de schéma encadrée, sans filtre | `filter: brightness()` sur un schéma |
| Espaces insécables de la typographie française sur les pages FR | Césure automatique, `text-align: justify` |

## Décisions de design validées par Arnaud (13/09/2026)

1. Pas de numéro « § » sur l'accueil ; numéros de rubrique « 02.3 », par cas, sur les pages cas.
2. Pas d'« En bref » sous les cas rattachés de l'accueil : numéro et titre seulement.
3. Sommaire mobile dans un `<details>` fermé ; visible dans la marge dès 48 rem.
4. Sélecteur de langue : « English » / « Français ».
5. Corps d'un poste affiché seulement quand le poste n'a aucun cas publié.
6. Cadre unique de 77,5 rem sur toutes les pages larges : la colonne de texte ne bouge pas d'une page à l'autre.
7. N1 du thème D2 aligné sur `ink` (`#1C2030`).
8. SVG D2 à double thème, sous réserve d'un spike (`<img>`, déterminisme octet par octet, ≤ 60 Ko) ; repli : planche claire encadrée sans filtre ; schéma large dans un cadre qui défile horizontalement, avec « Ouvrir en taille réelle ».
9. Typographie française appliquée au rendu des pages FR.
10. Portrait aussi sur À propos : 160 × 200 px dès md, variantes 160 × 200 et 320 × 400.

Le statut reste `draft` jusqu'à la relecture complète d'Arnaud. Les libellés encore ouverts et les impacts d'architecture sont dans `EXPERIENCE.md`.
