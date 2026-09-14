# Story 0.2 : Main branch protections and merge styles

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.2. Fichier d'historique, écrit après coup à la story 0.5.

## Livraison

- PR n° 6 (`chore/0-2-main-branch-protections`), fusionnée en squash : `c73552b`.
- Opération manuelle d'Arnaud : création de `main` depuis `dev`, protections de `dev` et `main` dans l'interface de la forge.
- Réglages passés par l'API sur décision d'Arnaud, puis relus : mise à jour des PR par merge désactivée (bug de l'interface), clés de déploiement retirées des listes de `dev`, fusion bloquée si `main` est en retard.
- Tests sur branches temporaires (PR de test n° 3 à 5) et push refusés sur `main` : consignés dans `docs/procedures/gitea-branches.md`.

## Revue de spec

Non faite : la revue de spec par un relecteur d'un autre fournisseur n'existait pas encore. La première a été faite à la main sur la story 0.5 ; elle est systématique à partir de la story 0.6. La story a été reformulée, et ses questions posées à Arnaud, avant l'implémentation.

## Revue du code

Revue manuelle (règle d'amorçage D-1) : `agy --mode plan`, modèle `gemini-3.1-pro-high`, rapport publié en commentaire de la PR n° 6.

| SHA relu | Verdict | Constats | Décision |
|---|---|---|---|
| `060d450` | pass | Aucun. | — |

Une première tentative, lancée sans `--add-dir`, n'a trouvé aucun fichier dans la copie isolée : son rapport « bloquant » ne portait sur rien, il n'a pas été publié. Leçon reprise dans la story 0.5 (`--add-dir` obligatoire, rapport refusé sans jeton de lecture).

## Reporté

Aucun constat reporté.
