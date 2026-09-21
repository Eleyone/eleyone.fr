---
title: "Reprendre un sujet en dérive sans écraser celui qui le portait"
translationKey: "case-04"
number: "04"
slug: "chiliz-reprise-creation-pool"
group: "chiliz"
position: "position-chiliz"
order: 3
draft: true

context:
  company: "Chiliz"
  setup: "employee"
  role: "Reprise de l'ownership et refonte du process de création de pool"
  period: "décembre 2025 – mars 2026"
  stack: ["Fireblocks"]

summary: >-
  Un process de création de pool en retard, porté par un développeur qui n'y arrivait plus. Je l'ai repris avec son accord, corrigé une faille qui aurait pu faire perdre le contrôle d'un pool, et livré.
  Utilisé depuis à chaque émission de token.

live_material:
  - id: "diagram-pool-creation-process"
    type: "diagram"
    status: "planned"
    description: "Allowances → création + premier dépôt (une transaction) → allowance sur le pool → indexation, avec les points de validation admin Fireblocks"
    url: ""
  - id: "callout-ownership-window"
    type: "callout"
    status: "planned"
    description: "La fenêtre d'ownership en deux appels, et pourquoi une seule transaction la ferme"
    url: ""
  - id: "diagram-event-table"
    type: "diagram"
    status: "planned"
    description: "Pseudo-schéma de la table d'événements avec statuts (pas de données réelles)"
    url: ""
---

## Contexte

Même application. Le sujet : la création de pool. Quand la société émet un nouveau token, il faut créer le pool qui va avec — token contre crypto, ou token contre token — et y faire le premier dépôt. Ce premier dépôt fixe le ratio de conversion, donc le prix de départ sur lequel le trading démarre. Objectif : un seul point d'entrée dans l'application, une seule validation, et un process aussi automatisé que possible.

Équipe saturée : chacun avec un sujet en ownership et une deadline proche. Ce sujet-là avait été conçu et porté par un développeur junior que je suivais.

## Le problème

Deux problèmes emboîtés.

**Le sujet dérivait.** Le développeur posait beaucoup de questions, ne savait plus où il allait, produisait des choses qui cassaient au test et ne parvenait pas à débugger. Le management s'en est aperçu. Un mois de retard, une pression forte pour livrer.

**Le design de départ était faux.** La V1 faisait deux appels blockchain : créer le pool, puis déposer. Entre les deux, une fenêtre : n'importe qui détenant des tokens pouvait déposer avant nous et prendre l'ownership du pool. Et le process réel était bien plus long que deux appels : allowances du wallet sur chaque token, création, allowance sur le pool, indexation — sans qu'aucune de ces étapes ne laisse de trace. On ne savait ni ce qui s'était passé, ni quand, ni pourquoi.

{{< live-material id="callout-ownership-window" >}}

## Ce que j'ai décidé

**La reprise.** J'ai d'abord aidé en renfort, sur le debug. Puis, sous la pression et parce que je perdais du temps des deux côtés — mes propres sujets et ses questions — je suis allé voir le scrum master et le tech lead pour proposer de reprendre l'ownership. Le développeur lui-même l'a demandé : trop de pression, il ne s'en sortirait pas. Je l'ai repris parce que je le suivais déjà et que j'avais une idée claire de ce qu'il fallait faire.

Il est resté dans toutes les revues. On a discuté en off : je lui ai présenté chaque choix, pourquoi, dans quelles conditions. Une partie de ce que j'ai implémenté, c'étaient les retours que je lui avais déjà faits — ajouter du log, représenter chaque événement dans une table avec un statut.

**La refonte.** Passage à une méthode qui crée le pool et fait le premier dépôt en une seule transaction : la fenêtre se ferme, on gagne une signature. Toutes les allowances intégrées comme prérequis automatisés du process. Et j'ai réappliqué sur la création de pool le mécanisme de suivi que je construisais en parallèle pour les allowances : une table d'événements par étape, chacun avec son statut, pour savoir à tout moment où en est le process.

{{< live-material id="diagram-pool-creation-process" >}}

{{< live-material id="diagram-event-table" >}}

## Ce qui a résisté

Les wallets de l'entreprise étaient gérés par Fireblocks. Certaines actions et certains wallets exigeaient la validation d'un compte admin — l'utilisateur ne signait qu'une partie, le reste passait par l'admin. S'ajoutait le whitelisting Fireblocks, lui aussi soumis à signature admin. Chaque étape du process devait composer avec ces deux couches de validation.

## Résultat

- Démarré en décembre, livré en production en mars : trois mois de retard au total, tests compris. Un des derniers sujets que j'ai traités chez Chiliz.
- Utilisé depuis à chaque émission de nouveau token : le pool est créé via ce process.
- Un seul point d'entrée, une seule validation côté utilisateur ; chaque étape tracée avec son statut.
- Fenêtre d'ownership du pool fermée.

## Ce que ça montre

Je repère quand un sujet dérive et j'agis avant que ça coule — en passant par le management, pas en le contournant. Je prends la charge sans prendre la place : le développeur a demandé à sortir, il est resté dans les revues, il a eu chaque décision expliquée. Je remets en cause un design qui « marche » quand son mode de défaillance est inacceptable. Et je conçois pour le suivi : si on ne sait pas où en est un process, on ne peut ni le débugger ni lui faire confiance.
