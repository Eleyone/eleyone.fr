# Story 11.10 : Thirty-second test

Status: in-progress

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.10.

Première story de la section « Mise en ligne du socle » de l'epic 11 (point 21 : le socle est
complet, il est jugé, puis mis en ligne). Ses dépendances sont closes : 9.4, 10.1 à 10.10 (epic 10
clos le 03/10/2026, PR n° 132), 11.9 (répétition jouée le 02/10/2026, PR n° 128).

Opération manuelle d'Arnaud : la répétition sur l'arbre du socle (`v1.0.0-rc.1`, `v1.0.0-rc.2`,
retour arrière), puis cinq passages du test des trente secondes (`EXPERIENCE.md`, « Test des trente
secondes »), par partage d'écran sur le site de répétition.

**Tension relevée à l'ouverture** : `scripts/rehearse-release.sh --run` enchaîne la répétition
jusqu'à `rehearse stop`, qui arrête le conteneur et supprime les images `-rc` ; le test, lui, se mène
sur le site de répétition, qui doit donc servir pendant les cinq passages. La revue de spec et
l'arbitrage d'Arnaud diront comment les deux se raccordent.

## Revue de spec

## Revue du code
