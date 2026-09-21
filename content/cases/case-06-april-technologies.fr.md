---
title: "Sortir de son cadre pour comprendre le système entier"
translationKey: "case-06"
number: "06"
slug: "april-hors-perimetre"
position: "position-april-technologies-2017"
order: 6
draft: true

context:
  company: "April Technologies"
  setup: "agency"
  role: "Développeur front Symfony en prestation, puis features de bout en bout front et back"
  period: "2017"
  stack: ["Symfony 1.3", "Java", "SOAP"]

summary: >-
  Embauché pour l'écran, je suis allé comprendre la machine derrière : lire le Java pour débugger précisément, puis livrer des features de bout en bout.
  Je ne m'arrête pas à ma fiche de poste quand la qualité du résultat est en jeu.

live_material:
  - id: "diagram-official-scope-vs-explored"
    type: "diagram"
    status: "planned"
    description: "Navigateur → front Symfony → SOAP → back Java → données ; la zone « mon périmètre officiel » et la zone « là où je suis allé voir »"
    url: ""
  - id: "callout-languages-and-levels"
    type: "callout"
    status: "planned"
    description: "Les langages pratiqués au fil des missions, avec le niveau assumé pour chacun (expert / opérationnel / lu et compris)"
    url: ""
---

## Contexte

Deuxième passage sur ce projet : je l'avais déjà connu en 2013–2014, sur une mission pour le compte de CGI. Cette fois, embauché pour faire le front d'une application en Symfony 1.3. Le back était en Java et nous exposait des API SOAP. Mon périmètre : l'IHM qui affiche les données renvoyées par les services. Concrètement, de la mise en page.

{{< live-material id="diagram-official-scope-vs-explored" >}}

## Le problème

Aucun problème de production ; un problème de compréhension. Cantonné à afficher ce qu'un service m'envoyait, je ne savais pas d'où venaient les données, comment elles étaient construites, ni pourquoi elles arrivaient dans cette forme. Difficile de faire un bon front quand on ne comprend pas le back — et, pour être honnête, difficile de rester intéressé.

## Ce que j'ai décidé

Ça s'est fait en deux temps. D'abord pour débugger : quand j'avais une erreur côté front, je suis allé lire le Java pour savoir si elle venait de moi ou du service, et pouvoir dire à un développeur Java « ce truc-là ne marche pas, pour telle raison » au lieu de renvoyer un ticket vague. Je n'arrivais pas de zéro : j'avais déjà fait du Java des années plus tôt, pour de la cryptographie que PHP ne savait pas faire à l'époque.

Ensuite parce que j'avançais plus vite que ce qui était prévu pour moi. J'ai proposé de prendre des features de bout en bout : le front, et le back qui va avec — créer le champ dans l'entité Java, donc en base, ajouter les validations côté back, dans le contexte métier de l'assurance.

## Résultat

- Des features livrées de A à Z par une seule personne au lieu d'un aller-retour front/back, et des remontées de bugs précises aux développeurs Java plutôt que des « ça ne marche pas ».
- Pour moi : une vision complète de la chaîne, de la base au navigateur, et la confirmation que je ne suis pas cantonné à un langage. Je ne suis pas expert Java, et je ne le dis pas ; je sais en faire, et surtout je sais lire et comprendre un système écrit dans un langage qui n'est pas le mien.

{{< live-material id="callout-languages-and-levels" >}}

## Ce que ça montre

Je ne reste pas dans la case qu'on m'a donnée quand comprendre le reste rend mon travail meilleur. Je vais voir le back quand je fais le front. Je change de langage quand le problème le demande — Java pour de la cryptographie, Java pour comprendre une API — et demain un autre langage sur une mission qui migre depuis PHP. Le langage est un outil ; ce qui compte, c'est comprendre le système entier.
