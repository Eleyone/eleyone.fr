---
title: "Accueil fixture"
translationKey: home
description: "Description de l accueil fixture."
# La page « sans-front » n'a pas de front matter, donc pas de description : sans celle-ci, que la
# cascade lui donne, le build s'arrêterait sur AD-25 (story 9.8) avant d'écrire le manifeste dont
# ce site fixture éprouve justement l'entrée « front matter absent ».
cascade:
  - target:
      kind: page
    description: "Description donnée par la cascade."
identity: "Essai · Pseudo"
job_title: "Essai"
---
