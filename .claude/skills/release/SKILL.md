---
name: release
description: Publie dev sur main pour le site eleyone.fr — invariant fast-forward, PR de publication, verrous, puis tag vX.Y.Z qui déclenche la livraison. À utiliser quand Arnaud demande de mettre le site en ligne, de publier dev sur main ou de poser un tag de version.
---

# release

Publie `dev` sur `main` en fast-forward, sans merge commit, et pose le tag qui met en ligne.

La procédure fait foi : `docs/procedures/release.md`. L'exécution est `scripts/release.sh`.

À retenir :

- **deux temps.** `scripts/release.sh <tag>` vérifie l'invariant, ouvre la PR de publication si elle
  n'existe pas, affiche chaque verrou et **s'arrête là**. Le second appel, avec `--merge`, fusionne
  et tague ;
- **`--merge` est l'affaire d'Arnaud**, pas la tienne : ne le passe que s'il l'a demandé pour cette
  mise en ligne, au moment de l'opération. Le script ne le déduit jamais, et il n'a pas d'option
  `--force` ;
- le tag s'écrit `vX.Y.Z`. Un `vX.Y.Z-rc.N` est une **répétition générale** : il se pose sur `dev`
  par le skill `rehearse-release`, jamais ici ;
- si `main` n'est pas un ancêtre de `dev`, le script refuse et renvoie vers `hotfix`. Ne contourne
  pas : c'est l'invariant qui rend la publication linéaire ;
- pour `v1.0.0` seulement, la publication exige un tag `v1.0.0-rc.N` de même arbre **et** un
  `ci/release-pages.txt` qui contient tout le socle de `ci/base-pages.txt`. Pour un tag suivant,
  l'absence de répétition n'est qu'un avertissement ;
- **le script ne suit pas la CI.** Une fois le tag poussé, il affiche où regarder le run et quelle
  commande donne l'état du service ; c'est `deploy-site status` qui dit ce qui tourne vraiment ;
- un refus ne laisse rien derrière lui : ni PR fusionnée, ni tag. Corrige la cause indiquée, puis
  relance l'audit.
