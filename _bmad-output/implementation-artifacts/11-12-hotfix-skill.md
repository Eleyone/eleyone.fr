# Story 11.12 : Hotfix skill

Status: in-progress

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.12.

Story de la section « Mise en ligne du socle » de l'epic 11 : le dernier skill du flux linéaire
(AD-24, D-14), utilisable dès qu'une production existe — c'est le cas depuis `v1.0.0` (11.11) et
`v1.0.1` (9.8). Il corrige la production par une branche `hotfix/*` tirée de `main`, fusionnée en
fast-forward, taguée `vX.Y.(Z+1)`, puis rebase `dev` sur `main` et la pousse en `--force-with-lease`
**seulement sur l'approbation explicite d'Arnaud au moment de l'opération**. Aucun cherry-pick.

Aînés directs (règle 8 commune) : `scripts/release.sh` (skill `release`, story 11.7 — PR vers `main`,
verrous, fusion fast-forward, relecture des branches après fusion, tag annoté poussé) et
`scripts/rehearse-release.sh` (11.8 — confirmation explicite `--run`, aucun effet avant elle).

## Revue de spec

## Revue du code
