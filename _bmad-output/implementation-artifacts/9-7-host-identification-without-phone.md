# Story 9.7 : Host identification without a phone number

Status: backlog

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.7.

## Pourquoi cette story existe

La story 9.1 a livré les mentions légales avec, pour l'hébergeur, les trois données que
l'article 1-1 I 4° de la LCEN exige : dénomination, adresse et **numéro de téléphone**. Les trois
étaient des valeurs factices, à remplir avant la mise en ligne.

La recherche du 24/09/2026 a établi que la troisième n'existe pas. L'hébergeur ne publie de numéro
de téléphone sur aucune de ses pages — contact, mentions, conditions, support, à propos, toutes
chargées et cherchées — et il l'écrit lui-même sur sa page d'aide consacrée au sujet : il n'offre
pas de support téléphonique. La seule donnée de cette forme qu'il déclare est dans un registre
public d'attribution d'adresses IP, et rien n'en fait un numéro joignable au sens de la LCEN.

Un numéro circule pourtant, sur des mentions légales françaises de sites hébergés là. Il n'a de
source chez l'hébergeur nulle part. Le reprendre aurait publié un faux dans une page dont le seul
objet est d'être exacte, et c'est le risque que cette story écarte.

Arnaud a donc tranché le 24/09/2026 : **pas de numéro, et la page le dit**. Et puisqu'une page qui
constate un manque sans rien proposer est moins utile que la loi ne le demande, la variable du
téléphone est remplacée par celle du courriel — l'adresse que l'hébergeur désigne lui-même pour les
autorités de l'Union européenne, c'est-à-dire précisément l'usage que l'article 1-1 I 4° prévoit.

Le compte reste à huit : `HUGO_LEGAL_HOST_PHONE` sort, `HUGO_LEGAL_HOST_EMAIL` entre.

## Ce que la story touche

| Fichier | Ce qui change |
| --- | --- |
| `_bmad-output/planning-artifacts/architecture/.../ARCHITECTURE-SPINE.md` | AD-9 : la huitième variable |
| `scripts/env.sh` | `legal_variables` |
| `.env.example` | la liste des noms |
| `ci/legal-placeholder.env` | la valeur factice |
| `scripts/checks/content.sh` | `legal_names`, que C18 compare aux deux fichiers |
| `layouts/_partials/legal-value.html` | `$connus`, et les commentaires qui comptent encore sept |
| `layouts/_shortcodes/legal-list.html` | le groupe `host` |
| `content/legal-notice.{fr,en}.md` | la phrase sur l'absence de numéro |
| `scripts/tests/test-env.sh`, `test-legal-page.sh` | les cas |

`i18n/` ne bouge pas : `legal_term_email` existe déjà pour l'éditeur et sert l'hébergeur tel quel.

## Revue de spec

## Revue du code

## Décisions
