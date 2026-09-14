# Story 0.1 : Gitea token in env and env example

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.1. Fichier d'historique, écrit après coup à la story 0.5.

## Livraison

- PR n° 1 (`feat/0-1-gitea-token-in-env-and-env-example`), fusionnée en squash : `c2c789e`.
- PR n° 2, rattrapage du suivi de sprint (exception documentaire, sans revue) : `9e14036`.

## Revue de spec

Non faite : la revue de spec par un relecteur d'un autre fournisseur n'existait pas encore. La première a été faite à la main sur la story 0.5 ; elle est systématique à partir de la story 0.6. La story a été reformulée, et ses questions posées à Arnaud, avant l'implémentation.

## Revue du code

Revues manuelles (règle d'amorçage D-1) : `agy --mode plan`, modèle `gemini-3.1-pro-high`, rapports publiés en commentaire de la PR n° 1.

| SHA relu | Verdict | Constats | Décision |
|---|---|---|---|
| `6e1a9c8` | pass | Aucun. | — |
| `c8750a0` | pass | Pour la suite : les futurs scripts qui utilisent le jeton devront couper la trace du shell. | Traité à la story 0.4 : `set +x` en tête de `create-pull-request.sh`, règle écrite dans `gitea-token.md`. |

Le commit `c8750a0` a été ajouté entre les deux revues, sur un constat de l'auteur : une valeur de `.env` qui contient une espace se met entre guillemets, et `.env` ne se charge jamais avec `source`.

## Reporté

Aucun constat reporté.
