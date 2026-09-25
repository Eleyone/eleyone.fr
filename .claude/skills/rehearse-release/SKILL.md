---
name: rehearse-release
description: Joue la répétition générale de la mise en ligne du site eleyone.fr — tag de répétition sur dev, attente du serveur, tunnel SSH, vérifications des en-têtes et des journaux, retour arrière, arrêt. À utiliser quand Arnaud demande de répéter la mise en ligne, de jouer une répétition générale ou de poser un tag vX.Y.Z-rc.N.
---

# rehearse-release

Joue toute la chaîne de mise en ligne sur le **canal de répétition** du serveur de production, sans
DNS ni port public (AD-22).

La procédure fait foi : `docs/procedures/rehearse-release.md`. L'exécution est
`scripts/rehearse-release.sh`.

À retenir :

- **deux temps.** `scripts/rehearse-release.sh <tag>` vérifie tout — tag, `.env`, port local, tags
  libres relus depuis la forge — affiche le programme et **s'arrête là**. Le second appel, avec
  `--run`, joue la répétition ;
- **`--run` est l'affaire d'Arnaud**, pas la tienne : il pousse deux tags, et un tag poussé ne se
  reprend pas — la forge le voit, le miroir public aussi, et le workflow part. Ne le passe que s'il
  l'a demandé pour cette répétition, au moment de l'opération ;
- le tag s'écrit `vX.Y.Z-rc.N` et se pose **sur `dev`**. Un `vX.Y.Z` est une mise en ligne : il
  appartient au skill `release`, jamais ici ;
- **un seul tag est donné** : le suivant se calcule (`v0.1.0-rc.1` → `v0.1.0-rc.2`) ;
- **deux comptes, jamais mélangés.** `DEPLOY_HOST` porte `status`, `rehearse rollback` et
  `rehearse stop` — le canal restreint ; `ADMIN_HOST` ne sert qu'au tunnel et à `docker logs`. La
  clé de déploiement **refuse** une redirection de port (story 11.6) ;
- **l'attente passe par `deploy-site status`**, jamais par l'API de la forge : c'est l'état vrai, et
  il ne dépend pas d'un homelab qui peut tomber ;
- **un échec ne nettoie pas le serveur.** Le tunnel est tué, la répétition reste en service : son
  conteneur, ses journaux et son image sont ce qu'il faut inspecter. Le script affiche la commande
  d'arrêt ; ne la lance pas avant d'avoir regardé ;
- la répétition ne touche ni la production, ni le proxy, ni le DNS.
