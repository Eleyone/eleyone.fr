# Mesures

Ce dossier reçoit les mesures de performance du site mis en ligne, une par version (AD-17) : `v1.0.0.md`, puis une par mise en ligne suivante.

Chaque fichier consigne, pour la version qu'il nomme :

- PageSpeed Insights **mobile** de chaque gabarit de page (accueil, cas, page simple, 404), avec la date et les valeurs relevées ;
- le poids réel des pages servies, à comparer au budget d'AD-8 que `scripts/checks/budget.sh` fait respecter sur le build non compressé ;
- tout écart constaté entre la mesure de mise en ligne et le contrôle local, avec son explication.

Rien n'y est encore écrit : le site n'est pas déployé. Le dossier existe parce que le README public y renvoie, et qu'un lien mort dans un dépôt public vaut moins que rien.

**Anticipation déclarée** (point 7 d'`AGENTS.md`) : ce fichier appartient à la story de première mise en ligne (epic 11, procédure « premier déploiement » de l'architecture, étape 8). La story 3.15 n'a créé que ce texte, et aucune mesure.
