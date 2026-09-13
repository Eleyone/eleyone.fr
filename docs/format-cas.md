---
title: "Format de sortie des cas clients"
version: 0.1
status: draft
updated: 2026-09-13
---

# Format de sortie des cas clients

Contrat entre la rédaction des cas et le site Hugo. Un agent ou une personne qui rédige un cas produit exactement ce format. Les noms de fichiers et l'emplacement dans le dépôt seront confirmés par l'architecture ; les métadonnées et la structure du texte sont stables.

## Principe : un fichier par cas et par langue

On écrit **un cas**, pas une page. Le site assemble les pages : les cas 02, 03 et 04 portent `group: chiliz` et le gabarit de la page Chiliz les réunit dans l'ordre de `order`. La rédaction ne dépend donc pas de la mise en page.

```
cas-01-calculette.fr.md
cas-01-calculette.en.md
cas-02-chiliz-source-de-verite.fr.md
cas-02-chiliz-source-de-verite.en.md
…
```

Le suffixe `.fr.md` / `.en.md` est la convention multilingue native de Hugo. Les deux fichiers d'un même cas partagent le même `translationKey`.

## Métadonnées (front matter YAML)

Les **clés** sont en anglais et identiques dans les deux langues. Les **valeurs** textuelles sont dans la langue du fichier, sauf `stack`, `setup` et les identifiants, qui ne se traduisent pas.

```yaml
---
title: "Titre du cas"                 # ≤ 70 caractères, dans la langue du fichier
translationKey: "cas-02"              # identique FR/EN
number: "02"
slug: "chiliz-source-de-verite"       # dans la langue du fichier
group: "chiliz"                       # facultatif : page qui regroupe plusieurs cas
order: 1                              # position dans le groupe, ou sur la liste des cas
featured: true                        # mis en avant sur l'accueil (cas 01, 02, 05)
draft: true                           # passe à false quand plus aucun [TODO] ne reste

context:                              # encart « Contexte mission »
  company: "Chiliz"
  setup: "[TODO: cadre]"              # employee | freelance | agency | ton-pote-le-geek
  role: "Rôle en une phrase"
  period: "[TODO: période]"           # ex. "2021–2023" ; pas de mois inventé
  stack: ["PHP", "Symfony", "Twig"]   # vocabulaire contrôlé, identique FR/EN

summary: >-                           # encart « En bref » : l'enjeu → le résultat
  Trois lignes au plus, lisibles par un dirigeant. Pas de jargon.

live_material:                        # matériel vivant prévu (vide si aucun)
  - id: "schema-reconciliation"       # identique FR/EN
    type: "diagram"                   # diagram | video | snippet | callout
    status: "planned"                 # planned | ready
    description: "Ce que montre l'élément, dans la langue du fichier"
    url: ""                           # vidéos seulement : lien YouTube non répertorié
---
```

### Vocabulaire de la stack

Une seule écriture par technologie. Liste actuelle :

`Claude Code` · `Docker Compose` · `Fireblocks` · `Java` · `Oracle` · `PHP` · `PostgreSQL` · `Redshift` · `SOAP` · `Symfony` · `Symfony 1.3` · `Symfony UX` · `Systeme.io` · `Twig` · `Xdebug` · `Zend Framework`

Une technologie absente de la liste s'y ajoute explicitement, dans ce fichier, avant d'être utilisée. Seules les technologies **citées dans le cas** figurent dans sa stack.

## Corps du texte

Titres de niveau 2 pris dans cette liste, dans cet ordre. Un titre peut être omis si la section est sans objet, mais **FR et EN ont exactement les mêmes sections**.

| Français | English |
|---|---|
| `## Contexte` | `## Context` |
| `## Le problème` | `## The problem` |
| `## La solution facile, et pourquoi je ne l'ai pas prise` | `## The easy way, and why I didn't take it` |
| `## Ce que j'ai décidé` | `## What I decided` |
| `## Ce qui a résisté` | `## What pushed back` |
| `## Résultat` | `## Outcome` |
| `## Ce que ça montre` | `## What it shows` |

- La section « Contexte » raconte la situation ; elle ne répète pas les faits de l'encart (société, rôle, période, stack).
- Pas de titre de niveau 1 : le titre vient de `title`.
- Les titres de niveau 3 sont libres.
- Le matériel vivant se place dans le texte avec `{{< live-material id="schema-reconciliation" >}}`, où il doit apparaître. Chaque `id` utilisé existe dans `live_material`, et inversement.

## Sections des sources qui ne sont pas publiées

- **Statut du brouillon** et notes « à traiter séparément ».
- **Matériel vivant** : devient `live_material` et les marqueurs dans le texte.
- **Les deux dialectes** : fusionnés dans `summary` (dirigeant) et dans le corps (CTO).

## Marqueurs à compléter

Tout ce qui manque s'écrit `[TODO: précision]`, dans les deux langues. Un cas qui contient encore `[TODO` reste en `draft: true`. Les passages entre crochets des sources restent des `[TODO: …]`, jamais des faits.

## Règles de rédaction

1. **Rien d'inventé** : ni cas, ni chiffre, ni client, ni technologie, ni date absents des sources.
2. **Reformulation minimale** des sources, à la première personne.
3. **Mêmes faits et mêmes chiffres en FR et en EN.** L'anglais n'est pas une traduction littérale : il ajoute les lignes de contexte dont un lecteur international a besoin (ce qu'est l'entreprise, un sigle, une plateforme).
4. **Aucun code propriétaire d'un client** : pseudo-code et extraits illustratifs seulement.
5. **Aucune information personnelle** : ni rémunération, ni lieu ou mobilité, ni auto-évaluation d'entretien, ni proches.
6. Un sujet **jamais mis en production** le reste explicitement dans le texte.

## Modèle vide

```markdown
---
title: "[TODO: titre]"
translationKey: "cas-NN"
number: "NN"
slug: "[TODO: slug]"
order: 0
featured: false
draft: true
context:
  company: "[TODO: société]"
  setup: "[TODO: cadre]"
  role: "[TODO: rôle]"
  period: "[TODO: période]"
  stack: []
summary: >-
  [TODO: l'enjeu → le résultat, 3 lignes]
live_material: []
---

## Contexte

## Le problème

## La solution facile, et pourquoi je ne l'ai pas prise

## Ce que j'ai décidé

## Ce qui a résisté

## Résultat

## Ce que ça montre
```
