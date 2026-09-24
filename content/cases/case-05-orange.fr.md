---
title: "De la seconde à la milliseconde sans toucher à la base"
translationKey: "case-05"
number: "05"
slug: "orange-crv-performance"
position: "position-orange"
order: 5
draft: false

context:
  company: "Orange"
  setup: "agency"
  role: "Expert Zend Framework, décisionnaire technique en l'absence de tech lead"
  period: "juillet 2014 – janvier 2016"
  stack: ["PHP", "Zend Framework", "Oracle", "Xdebug"]

summary: >-
  Des commerciaux terrain attendaient plusieurs secondes à chaque consultation, en 3G. Sans toucher à la base ni au reste du système, l'affichage est passé en millisecondes.
  En s'attaquant uniquement à ce qui coûtait vraiment, mesure à l'appui.

live_material:
  - id: "callout-magic-methods-vs-direct-access"
    type: "callout"
    status: "planned"
    description: "Méthodes magiques contre accès direct : pourquoi __get coûte cher sur des milliers d'objets, avec une micro-mesure reproductible en PHP moderne"
    url: ""
  - id: "diagram-crv-scope"
    type: "diagram"
    status: "planned"
    description: "Application CRV (lecture) → base Oracle partagée ← application d'écriture du SI ; ce qui était dans mon périmètre et ce qui ne l'était pas"
    url: ""
  - id: "snippet-illustrative"
    type: "snippet"
    status: "planned"
    description: "Extrait illustratif, pas de code d'époque"
    url: ""
---

## Contexte

Application CRV — comptes rendus de visite — utilisée par les commerciaux terrain qui vendent des équipements télécom aux TPE/PME et professionnels. Pas de tech lead à l'époque : c'est de fait le rôle que je tenais dans l'équipe.

Deux contraintes structurantes : la base de données était sous Oracle, gérée ailleurs dans le SI, intouchable ; et notre application ne faisait que de la lecture — les écritures passaient par une autre application du SI, sur laquelle nous n'avions aucune prise.

{{< live-material id="diagram-crv-scope" >}}

## Le problème

Des pages qui chargeaient en secondes, pour des commerciaux sur le terrain, en 3G et début de 4G. Chaque consultation d'un compte rendu coûtait du temps face au client.

## La solution facile, et pourquoi je ne l'ai pas prise

Refondre l'architecture de données : impossible, la base n'était pas à nous. Réécrire l'application : pas le budget, et le risque de tout casser pour un gain incertain. Il fallait gagner du temps d'exécution à structure constante.

## Ce que j'ai décidé

D'abord mesurer. Profilage avec Xdebug et un visualiseur de traces pour voir où passait réellement le temps, méthode par méthode. Le verdict : une part disproportionnée du temps partait dans les méthodes magiques — les attributs étaient privés, sans getters, et chaque accès passait par `__get`, sur des objets manipulés en masse.

Puis trancher. J'ai monté un petit process de calibration : un scénario fixe, rejoué plusieurs fois, avec les temps relevés avant et après chaque hypothèse testée. L'alternative propre — des getters explicites — restait un peu plus lente qu'un accès direct. La forme des objets ne pouvait pas changer. J'ai donc rendu les attributs publics et supprimé l'indirection. Ce n'est pas le plus beau, et je le disais tel quel : c'est le levier le moins cher, le plus sûr et réversible, pour le plus gros gain mesuré. L'équipe a suivi ; j'ai tranché.

{{< live-material id="callout-magic-methods-vs-direct-access" >}}

Limites de la mesure, assumées : environnement de développement, pas de production ; pas d'accès aux logs de production ; et le profilage lui-même alourdissait fortement chaque requête. Ce que j'avais de fiable, c'étaient les ordres de grandeur relatifs entre hypothèses, pas les temps absolus des utilisateurs.

En pratique, je suis repassé sur à peu près tous les fichiers, et j'ai reformaté certains templates au passage — sans toucher aux contrats des objets ni à la base.

{{< live-material id="snippet-illustrative" >}}

## Résultat

- Des pages qui chargeaient en secondes passées à des chargements en millisecondes, côté lecture.
- Le reste — l'écriture via l'autre application du SI — restait tributaire d'un système sur lequel nous n'avions pas la main, et c'était dit clairement aux utilisateurs.

## Ce que ça montre

Je mesure avant d'optimiser, et je ne touche que ce que la mesure désigne. Je sais faire un choix laid quand il est mesuré, réversible, et que les alternatives propres sont hors budget ou hors périmètre — et je le nomme comme un compromis, pas comme une bonne pratique. Je délimite clairement ce que je peux améliorer de ce qui ne dépend pas de moi. Et quand il n'y a pas de tech lead, je prends la décision.
