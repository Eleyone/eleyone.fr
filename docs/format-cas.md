---
title: "Format de sortie des cas clients"
version: 0.4
status: validated
updated: 2026-09-13
---

# Format de sortie des cas clients

Contrat entre la rédaction des cas et le site Hugo. Un agent ou une personne qui rédige un cas produit exactement ce format. L'emplacement des fichiers est fixé par l'architecture (AD-4, AD-18) ; les métadonnées et la structure du texte sont stables.

## Principe : un fichier par cas et par langue

On écrit **un cas**, pas une page. Le site assemble les pages : un cas qui appartient à un groupe vit dans le dossier de ce groupe, et la page du groupe (la page Chiliz) réunit ses cas dans l'ordre de `order`. Sur l'accueil, qui est le CV, chaque cas apparaît sous **le poste** qu'il prouve, désigné par la clé `position`. La rédaction ne dépend donc pas de la mise en page.

```
content/cases/case-01-<nom-court>.fr.md          ← cas sans groupe
content/cases/case-01-<nom-court>.en.md
content/cases/chiliz/case-02-chiliz.fr.md        ← cas groupé : dans le dossier du groupe
content/cases/chiliz/case-02-chiliz.en.md
content/cases/chiliz/_index.fr.md                ← page du groupe : créée avec le site, pas par la rédaction des cas
content/cases/chiliz/_index.en.md
content/career/position-chiliz.fr.md             ← poste du parcours : créé avec le site, pas par la rédaction des cas
…
```

- **Noms de fichiers en anglais**, en minuscules et en kebab-case : `case-<NN>-<nom-court>.<langue>.md`. Le nom de fichier est un identifiant ; l'URL publique vient du `slug` de chaque langue.
- **Cas groupé** : le fichier est dans `content/cases/<group>/`, et la clé `group` est obligatoire et **égale au nom du dossier**. Un contrôle bloquant le vérifie.
- **Rattachement au parcours** : la clé `position` désigne le poste (`position-<id>`, par exemple `position-chiliz`). Le poste ne liste pas ses cas : c'est le cas qui pointe vers lui, et un cas se publie sans toucher au poste.
- **Identifiants de poste** : ils sont figés dans l'architecture (AD-18, règle `position-<société>`, suivie de `-<année de début>` quand la société revient dans le parcours ; `position-earlier-career` regroupe le parcours antérieur). Un cas reprend l'identifiant de cette liste et n'en invente aucun ; un identifiant publié n'est jamais renommé.
- Le suffixe `.fr.md` / `.en.md` est la convention multilingue native de Hugo. Les deux fichiers d'un même cas partagent le même `translationKey`.
- **URL** : un cas seul est publié à `/cas/<slug>/` et `/en/cases/<slug>/`. Un cas groupé est une section de la page du groupe, avec pour ancre son `translationKey` (par exemple `/cas/chiliz/#case-02`).

## Métadonnées (front matter YAML)

Les **clés** et les **identifiants** (`translationKey`, `group`, `position`, `setup`, `live_material[].id`, `type`, `status`) sont en anglais et identiques dans les deux langues. Les **valeurs** textuelles sont dans la langue du fichier, sauf `stack`, qui ne se traduit pas.

```yaml
---
title: "Titre du cas"                 # ≤ 70 caractères, dans la langue du fichier
translationKey: "case-02"             # identique FR/EN ; sert aussi d'ancre dans une page de groupe
number: "02"
slug: "chiliz-source-de-verite"       # dans la langue du fichier : c'est l'URL
group: "chiliz"                       # cas groupé seulement : égal au nom du dossier
position: "position-chiliz"           # poste du parcours prouvé par ce cas ; obligatoire si publié
order: 1                              # position dans le groupe
draft: true                           # passe à false quand plus aucun [TODO] ne reste et que le cas est relu

context:                              # encart « Contexte mission »
  company: "Chiliz"
  setup: "[TODO: cadre]"              # employee | freelance | agency | ton-pote-le-geek
  role: "Rôle en une phrase"
  period: "[TODO: période]"           # donnée par l'auteur ; jamais déduite
  stack: ["PHP", "Symfony", "Twig"]   # vocabulaire contrôlé, identique FR/EN

summary: >-                           # encart « En bref » : l'enjeu → le résultat
  3 phrases et 400 caractères au plus, par langue. Lisible par un dirigeant, sans jargon.

live_material:                        # matériel vivant prévu (vide si aucun)
  - id: "diagram-reconciliation"      # anglais, kebab-case, identique FR/EN
    type: "diagram"                   # diagram | video | snippet | callout
    status: "planned"                 # planned | ready
    description: "Ce que montre l'élément, dans la langue du fichier"
    url: ""                           # vidéos seulement : lien YouTube non répertorié
---
```

La clé `featured` des versions précédentes n'existe plus : l'accueil est le CV, et chaque cas apparaît sous son poste.

### Vocabulaire de la stack

La liste des technologies autorisées, avec leur écriture unique et les exclusions décidées, est tenue dans **`data/stack.yaml`**. Elle fait foi : ce document ne la recopie pas.

Seules les technologies **citées dans le cas** figurent dans sa stack. Une technologie absente du vocabulaire s'y ajoute avant d'être utilisée.

## Corps du texte

Titres de niveau 2 pris dans **`data/rubrics.yaml`**, dans l'ordre de ce fichier, qui fait foi et porte les deux écritures de chaque rubrique. Un titre peut être omis si la section est sans objet, mais **FR et EN ont exactement les mêmes sections**. Les contrôles C3 (parité) et C4 (liste des rubriques) lisent cette liste ; ajouter ou renommer une rubrique se fait là-bas, avant d'écrire un cas.

- La section « Contexte » raconte la situation ; elle ne répète pas les faits de l'encart (société, rôle, période, stack).
- **Une section absente de la source est omise**, pas reconstituée. Elle ne s'écrit qu'avec des éléments confirmés par l'auteur.
- Pas de titre de niveau 1 : le titre vient de `title`.
- Les titres de niveau 3 sont libres.
- Le matériel vivant se place dans le texte avec `{{< live-material id="diagram-reconciliation" >}}`, où il doit apparaître. Chaque `id` utilisé existe dans `live_material`, et inversement.

## Sections des sources qui ne sont pas publiées

- **Statut du brouillon** et notes « à traiter séparément ».
- **Matériel vivant** : devient `live_material` et les marqueurs dans le texte.
- **Les deux dialectes** : fusionnés dans `summary` (dirigeant) et dans le corps (CTO).

## Marqueurs à compléter

Tout ce qui manque s'écrit `[TODO: précision]`, dans les deux langues. Un cas qui contient encore `[TODO` reste en `draft: true`. Les passages entre crochets des sources restent des `[TODO: …]`, jamais des faits.

## Règles de rédaction

1. **Rien d'inventé** : ni cas, ni chiffre, ni client, ni technologie, ni date absents des sources ou non confirmés par l'auteur.
2. **Reformulation minimale** des sources, à la première personne.
3. **Mêmes faits et mêmes chiffres en FR et en EN.** L'anglais n'est pas une traduction littérale : il ajoute les lignes de contexte dont un lecteur international a besoin (ce qu'est l'entreprise, un sigle, une plateforme).
4. **Aucun code propriétaire d'un client** : pseudo-code et extraits illustratifs seulement.
5. **Aucune information personnelle** : ni rémunération, ni ville de résidence, téléphone ou mobilité, ni auto-évaluation d'entretien, ni proches. Le lieu de résidence public se limite à « basé en France », porté par le site ; les villes où se sont déroulées les missions peuvent apparaître.
6. Un sujet **jamais mis en production** le reste explicitement dans le texte.
7. **Ton factuel envers les anciens employeurs et clients** : le texte est public et nominatif.
8. **Le texte se lit sans le matériel vivant.** Un élément `planned` est invisible en production : aucune phrase ne s'appuie sur lui (« comme le montre le schéma »).

## Modèle vide

```markdown
---
title: "[TODO: titre]"
translationKey: "case-NN"
number: "NN"
slug: "[TODO: slug]"
group: ""                             # à retirer pour un cas sans groupe
position: "[TODO: poste]"             # identifiant de poste figé dans AD-18
order: 0
draft: true
context:
  company: "[TODO: société]"
  setup: "[TODO: cadre]"
  role: "[TODO: rôle]"
  period: "[TODO: période]"
  stack: []
summary: >-
  [TODO: l'enjeu → le résultat, 3 phrases et 400 caractères au plus]
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
