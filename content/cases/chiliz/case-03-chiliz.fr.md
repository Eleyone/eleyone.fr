---
title: "Batcher des transactions blockchain sans tout-ou-rien"
translationKey: "case-03"
number: "03"
slug: "chiliz-batch-transactions"
group: "chiliz"
position: "position-chiliz"
order: 2
draft: true

context:
  company: "Chiliz"
  setup: "employee"
  role: "Conception de l'architecture de chaînage et spécification du batch de transactions"
  period: "[TODO: période]"
  stack: ["[TODO: stack]"]

summary: >-
  Les traders répétaient la même opération pool par pool. J'ai conçu une saisie unique qui exécute les transactions en séquence, chacune confirmée avant la suivante, sans qu'un échec annule les autres.
  Arrivé en environnement de test, jamais mis en production : les priorités ont changé.

live_material:
  - id: "diagram-chaining-flow"
    type: "diagram"
    status: "planned"
    description: "UX → outbox → worker d'envoi → chaîne → listener d'événements → mise à jour de la transaction → suivante du batch ou clôture"
    url: ""
  - id: "callout-atomic-vs-chained"
    type: "callout"
    status: "planned"
    description: "Batch atomique contre chaînage : ce qui se passe quand une sous-transaction échoue"
    url: ""
  - id: "snippet-chaining-loop"
    type: "snippet"
    status: "planned"
    description: "Pseudo-code de la boucle de chaînage (pas de code réel, propriété de l'entreprise)"
    url: ""
---

## Contexte

Même application que le cas précédent, mais l'autre moitié du produit : au-delà des calculs, l'outil permettait au pôle finance d'exécuter lui-même toutes ses opérations on-chain sur les pools de tokens — transfert entre wallets, dépôt sur un pool, retrait, swap. Ces opérations ont été construites en premier ; les outils d'aide à la décision sont venus par-dessus.

[TODO: stack]

## Le problème

Un trader travaille sur plusieurs pools à la fois. Avec une opération à la fois, il fallait aller sur un pool, faire son dépôt, revenir, aller sur le suivant, et ainsi de suite — quatre fois, dix fois. Le besoin exprimé était simple : « je veux déposer tel montant sur ces quatre pools, en une seule saisie, et que ça parte. »

## La solution facile, et pourquoi je ne l'ai pas prise

Sur la chaîne, une transaction = une signature. Il existe bien un type de transaction « batch » qui regroupe plusieurs sous-transactions sous une seule signature — mais il est atomique : la moindre erreur d'exécution dans une sous-transaction (fonds insuffisants sur un pool, par exemple) met tout le batch en erreur. Pour un trader, perdre les trois dépôts qui étaient bons parce que le quatrième manquait de fonds, c'est pire que de signer quatre fois.

{{< live-material id="callout-atomic-vs-chained" >}}

## Ce que j'ai décidé

Un chaînage : on envoie la première transaction du batch, on attend que la chaîne la confirme, puis on envoie la suivante. Une signature par transaction, mais une seule saisie côté utilisateur, et surtout un succès partiel possible — une transaction qui échoue n'empêche pas les autres de s'exécuter.

L'architecture autour :

- Tout part en asynchrone depuis l'UX, selon le pattern outbox.
- Une entité **Batch** avec son statut, qui regroupe des entités **Transaction** ayant chacune leur statut — deux niveaux de suivi pour toujours savoir où on en est.
- Un worker qui envoie les transactions.
- En parallèle, un listener qui lit les événements de la chaîne et déclenche du code selon ce qu'elle renvoie.
- Le listener met à jour le statut de la transaction ; si elle est validée, on prend la suivante du batch ; sinon on sort et on met le batch à jour avec son état réel.

{{< live-material id="diagram-chaining-flow" >}}

{{< live-material id="snippet-chaining-loop" >}}

## Ce qui a résisté

La signature unique. Le pôle finance voulait aussi ne signer qu'une fois. Le seul moyen était le batch atomique de la chaîne, avec le tout-ou-rien qu'on venait d'écarter. Faute de solution satisfaisante et parce que les priorités ont changé, le sujet a été dépriorisé. Le chaînage couvrait l'essentiel de la valeur : la saisie unique et la résilience.

## Résultat

- Saisie multi-pools en une fois, avec exécution transaction par transaction et succès partiel possible ; suivi d'état à deux niveaux, batch et transaction.
- **Implémenté en grande partie et arrivé jusqu'en environnement de test ; jamais mis en production.** Les priorités de l'équipe ont changé et la capacité manquait pour finir. Le sujet est resté partiellement implémenté, prêt à être repris.

## Ce que ça montre

Je pars du besoin utilisateur (une saisie, pas une signature) et j'identifie ce qui a vraiment de la valeur dedans. Devant une contrainte de plateforme, je compare les options sur leurs modes de défaillance — atomique et fragile contre chaîné et résilient — et je choisis celle dont l'échec coûte le moins. Je conçois pour l'observabilité : deux niveaux de statut, un listener sur la source de vérité. Et je sais dire qu'un sujet n'est pas allé au bout — et pourquoi — sans le maquiller en « livré ».
