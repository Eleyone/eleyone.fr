---
title: "Faire d'une application la source de vérité d'un calcul financier"
translationKey: "case-02"
number: "02"
slug: "chiliz-source-de-verite"
group: "chiliz"
order: 1
featured: true
draft: true

context:
  company: "Chiliz"
  setup: "employee"
  role: "Développeur backend, owner de l'epic NCS/CS dans une équipe de quatre à cinq développeurs"
  period: "septembre 2025 – février 2026"
  stack: ["PHP", "Symfony", "Symfony UX", "Twig", "Redshift"]

summary: >-
  L'équipe finance décidait d'acheter, vendre ou staker des tokens à partir d'un export recalculé à côté par la BI.
  J'ai porté ce calcul dans l'application, prouvé qu'il était juste contre l'ancien système, et il est devenu la référence.
  Le plus dur n'a pas été la règle, mais les exceptions faites à la main dans l'historique — on les a toutes retrouvées.

live_material:
  - id: "diagram-ncs-cs-flow"
    type: "diagram"
    status: "planned"
    description: "Blockchain → rapatriement en base → calcul cumulatif NCS/CS → application → réconciliation avec la BI"
    url: ""
  - id: "callout-18-decimals"
    type: "callout"
    status: "planned"
    description: "Pourquoi un calcul cumulatif à 18 décimales ne pardonne aucune exception dans l'historique"
    url: ""
  - id: "snippet-history-replay"
    type: "snippet"
    status: "planned"
    description: "Pseudo-code du rejeu de l'historique des transactions (le code réel appartient à l'entreprise)"
    url: ""
---

## Contexte

Dernière équipe sur place : quatre à cinq développeurs back, sans front dédié, chargés de construire un nouvel outil pour la branche finance — l'équipe qui fait du trading interne sur les tokens de la société. L'outil sert à décider s'il faut acheter, vendre ou staker. Environ 90 tokens, un pool par token.

Le projet avait été démarré en Python, en interne, sur l'idée que Python est ce qui ressort le plus avec l'IA. Personne dans la société ne le maîtrisait. Retour sur ce que l'équipe savait tenir en production : PHP et Symfony. Même logique pour le front : plutôt qu'un framework JS que personne ne maîtrisait, Symfony UX et Twig, décision à laquelle j'ai contribué.

## Le problème

Au cœur de l'outil, le calcul du NCS et du CS — non-circulating supply et circulating supply — c'est-à-dire combien de nos tokens sont en circulation et combien ne le sont pas. Toutes les décisions de trading en dépendent. Jusque-là, ce calcul était fait par l'équipe BI, via un export considéré comme la source de vérité. L'objectif : que l'application prenne en charge le calcul, soit prouvée juste contre la BI, puis devienne elle-même la référence.

Particularité qui pèse sur tout le reste : le calcul est cumulatif. Chaque valeur dépend de toutes les transactions antérieures. Pour un résultat à jour, il faut rejouer l'historique complet.

{{< live-material id="diagram-ncs-cs-flow" >}}

## Ce que j'ai décidé

Le POC existait déjà. J'ai réécrit la documentation d'implémentation — comment on porte ça dans l'app — puis découpé l'epic en stories et en tâches. Le chiffrage a été fait en refinement par l'équipe. J'ai pris l'essentiel de l'implémentation et l'ownership du sujet. Première version en un mois.

La validation contre les données de prod s'est faite en binôme avec un collègue, parce que je n'avais pas les accès prod.

{{< live-material id="snippet-history-replay" >}}

## Ce qui a résisté

La règle qu'on nous avait donnée était propre. L'historique ne l'était pas. Dès les premiers tests, des écarts avec la BI : l'existant était plein d'entorses faites à la main au fil du temps, et comme le calcul est cumulatif, une seule exception dans le passé décale tout ce qui suit.

Le travail réel a donc été une chasse aux exceptions : retrouver qui, quoi, quand, pourquoi. On s'est aussi aperçu qu'il manquait des informations, qui vivaient sur la blockchain. Les requêter à chaque calcul coûtait trop cher en temps ; décision de les rapatrier dans notre base pour requêter directement dessus.

Dernière source d'écart : la précision. Les montants sont à 18 décimales, bornées. Nos librairies les traitent correctement ; Redshift, côté BI, moins bien — d'où des écarts de virgule qui s'accumulent sur un calcul cumulatif. On a défini une tolérance plutôt que de courir après une égalité parfaite qui n'était pas de notre côté.

{{< live-material id="callout-18-decimals" >}}

Côté organisation, une bonne partie du travail a consisté à s'aligner sur ce qu'on livrait avant de le construire.

## Résultat

- Septembre : démarrage. Un mois plus tard : première version. Fin février : calculs stabilisés et justes, après cinq mois de recherche d'exceptions et de fiabilisation de l'historique.
- À mon départ, les décisions de trading dans l'application se prenaient sur nos données, plus sur l'export BI.
- L'export BI continuait de tourner, en consolidation : une réconciliation qui vérifie en continu que nos calculs restent justes.

## Ce que ça montre

Je sais prendre un POC et le transformer en logiciel qui tient : doc d'implémentation, découpage, ownership de bout en bout. Je sais que la règle métier et les données réelles sont deux choses différentes, et que le travail est presque toujours dans l'écart entre les deux. Je choisis les technos sur ce que l'équipe sait maintenir, pas sur la mode. Et quand un calcul sert à décider, je ne le considère pas livré tant qu'il n'est pas prouvé contre la référence existante, avec une tolérance explicite.
