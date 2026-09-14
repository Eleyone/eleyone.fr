---
name: check-private
description: Garde-fou public/privé du dépôt eleyone.fr. À utiliser avant tout push, avant l'activation du miroir GitHub, avant l'envoi d'un diff à un relecteur externe, après une réécriture d'historique, ou pour auditer l'historique git à la recherche de chemins et de contenus privés.
---

# check-private

Lance le garde-fou public/privé :

- avant tout push ;
- avant l'activation du miroir GitHub ;
- avant l'envoi d'un diff à un relecteur externe (`llm-review`) ;
- après une réécriture d'historique.

La procédure fait foi : `docs/procedures/check-private.md`. L'exécution est `scripts/check-private.sh` (modes `staged`, `history`, `pre-receive`).

À retenir :

- dans une copie sans `docs/private/` (worktree hors du dépôt, clone), définis `PRIVATE_PATTERNS_FILE` : un passage « chemins seulement » ne vaut pas audit ;
- n'affiche, ne copie ni ne cite jamais le fichier de motifs, ni le contenu qu'une alerte désigne ;
- une alerte bloque : suis la section « En cas d'alerte » de la procédure.
