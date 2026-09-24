---
title: "De l'iframe au produit : une calculette de rentabilité en production"
translationKey: "case-01"
number: "01"
slug: "calculette-rentabilite"
position: "position-ton-pote-le-geek"
order: 1
draft: false

context:
  company: "Institut Lionne"
  setup: "ton-pote-le-geek"
  role: "Conception, développement et hébergement de l'application, de la V1 à la maintenance"
  period: "depuis mai 2025"
  stack: ["Symfony", "PostgreSQL", "Docker Compose", "Systeme.io", "Claude Code"]

summary: >-
  Une coach pour coiffeuses refaisait à la main, avec chaque cliente, le même calcul de prix de revient.
  J'ai construit un outil que ses clientes utilisent seules : environ 400 comptes créés, 300 actifs.
  Son temps de coaching sert désormais à coacher.

live_material:
  - id: "video-calculation-flow"
    type: "video"
    status: "planned"
    description: "Une coiffeuse saisit ses charges et une prestation, obtient son prix plancher et son PDF (60 à 90 secondes)"
    url: ""
  - id: "diagram-account-creation"
    type: "diagram"
    status: "planned"
    description: "Achat de la formation dans Systeme.io → tag → webhook → création du compte → envoi des accès"
    url: ""
  - id: "snippet-cost-price-test"
    type: "snippet"
    status: "planned"
    description: "Extrait de test unitaire sur le calcul du coût de revient, avec l'asymétrie sur/sous-évaluation"
    url: ""
---

## Contexte

Ma cliente est coach business pour coiffeuses, à la tête d'Institut Lionne : ancienne coiffeuse, ancienne dirigeante de salon puis de franchise. Elle vend une formation dans laquelle chaque cliente doit calculer le prix minimum de ses prestations pour ne pas perdre d'argent. Elle est arrivée par la personne qui gérait alors ses réseaux sociaux.

## Le problème

Le calcul est toujours le même — coût produit par prestation, charges mensuelles, heures réellement travaillées, salaire visé — mais elle le refaisait à la main, en rendez-vous individuel, avec chaque cliente. Des heures de coaching consommées à poser des divisions qu'elle avait déjà faites cinquante fois. Pas d'outil du marché à acheter ou louer qui fasse ça à l'époque, ni à sa connaissance ni à la mienne.

## La solution facile, et pourquoi je ne l'ai pas prise

Un tableur distribué à chaque cliente. Rejeté : il ne résout rien, elle doit encore tenir la main pour le remplir. Un outil no-code : aucun ne permettait de faire le formulaire et le calcul proprement, et au tarif estimé j'aurais perdu plus de temps à le tordre qu'à écrire une petite application.

## Ce que j'ai décidé

**V1 — le minimum qui rend autonome.** Une petite application Symfony, sans base de données, encapsulée en iframe dans la formation Systeme.io. Un formulaire, un calcul, un PDF de sortie. Pas de base volontairement : pas de RGPD, rien à héberger ni à maintenir, et l'hypothèse que les clientes faisaient leur calcul, récupéraient leur PDF et ne revenaient pas.

**L'hypothèse était fausse.** Les retours sont arrivés très vite : elles reviennent, et devoir tout ressaisir était un vrai frein. Trois mois après la mise en production, bascule vers une application complète : Symfony et PostgreSQL, dockerisée avec Docker Compose, hébergée sur un VPS. Création de compte automatique : achat de la formation dans Systeme.io, tag, webhook vers l'application, compte créé, accès envoyés par mail.

{{< live-material id="diagram-account-creation" >}}

Cette V2 a été développée en trois mois à temps partiel, en dehors de mes horaires de travail, en adoptant Claude Code pour la première fois. Il m'aurait fallu six mois à plein temps.

## Ce qui a résisté

Pas le webhook, pas l'authentification, pas l'iframe — tout ça, c'est de la documentation et de l'implémentation. Ce qui a fait mal : des bugs remontés sur le chemin critique, sur les calculs eux-mêmes, qui n'auraient jamais dû passer des tests unitaires. Pour un outil d'aide à la décision, l'erreur n'est pas symétrique : un prix surévalué fait gagner un peu plus, un prix sous-évalué fait perdre de l'argent à une coiffeuse. On ne peut pas se le permettre.

{{< live-material id="snippet-cost-price-test" >}}

Réponse : audit de qualité et de sécurité du code, mise en place d'une CI qui tient, structuration des process de développement, reprise de la stack Docker en la construisant moi-même au lieu de la consommer. Ça aurait dû venir plus tôt ; ça fait partie du jeu.

## Résultat

- En production depuis un peu plus d'un an ; version avec base de données depuis les trois mois qui ont suivi.
- Quatre itérations en production depuis : corrections de calcul, améliorations, et du travail UX.
- Environ 400 comptes créés, dont 300 actifs, qui utilisent l'outil de façon autonome. La vidéo de présentation initiale est devenue caduque au fil des versions ; elle a été remplacée par un parcours tutoriel à la première connexion et des aides contextuelles dans l'outil.
- Pour ma cliente : les heures de coaching qui partaient en calculs sont désormais des heures de gestion et de mindset — les clientes arrivent avec leurs chiffres en main.
- Modèle : un forfait pour la mise en place, un second pour la V2, puis un forfait mensuel de maintenance applicative ; hébergement sur un VPS que j'administre, refacturé à part.
- L'outil est en cours de transformation en produit vendu en mon nom, avec l'accord de la cliente : le temps investi sur le produit profite aussi à son instance.

{{< live-material id="video-calculation-flow" >}}

## Ce que ça montre

Je commence par le périmètre minimal et j'attends que le besoin réel dicte la suite. Je prends mes décisions techniques sur un coût et un risque, pas sur une préférence. Quand une hypothèse se révèle fausse, je la corrige vite. Et je raisonne en risque métier : ce qui compte n'est pas le taux de couverture, c'est de savoir quelle erreur coûte de l'argent à l'utilisatrice.
