# Story 0.4 : Create-pull-request skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.4. Fichier d'historique, écrit après coup à la story 0.5.

## Livraison

- PR n° 8 (`chore/0-4-create-pull-request-skill`), ouverte par `scripts/create-pull-request.sh` lui-même, fusionnée en squash : `19763e0`.
- Preuve : relance refusée (« PR déjà ouverte n° 8 »), corps publié identique au fichier octet par octet.

## Revue de spec

Non faite : la revue de spec par un relecteur d'un autre fournisseur n'existait pas encore. La première a été faite à la main sur la story 0.5 ; elle est systématique à partir de la story 0.6. La story a été reformulée, et ses questions posées à Arnaud, avant l'implémentation.

## Revue du code

Revues manuelles (règle d'amorçage D-1) : `agy --mode plan --add-dir`, modèle `gemini-3.1-pro-high`, rapports publiés en commentaire de la PR n° 8.

| SHA relu | Verdict | Constats | Décision |
|---|---|---|---|
| `1369d9a` | pass | 1. Un nom de fichier avec saut de ligne s'affiche en morceaux dans les alertes de `check-private`. 2. Le contrôle « aucune modification en attente » passait si `git status` échouait. 3. Un commentaire en fin de ligne de `.env` n'est pas retiré. | 1. Limite acceptée, déjà documentée à la story 0.3. 2. Corrigé (`f5b04de`) sur décision d'Arnaud. 3. Reporté au chargeur commun de `.env`, `scripts/lib/gitea.sh` (story 0.5). |
| `f5b04de` | pass | 1. La lecture de `FETCH_HEAD` échouait sans message. 2. Un lancement volontaire par `bash -x` afficherait le jeton. | Corrigés (`352bdc8`) sur décision d'Arnaud : message ajouté ; trace coupée dès la première ligne du script, règle écrite dans `gitea-token.md`. |
| `352bdc8` | pass | Aucun. | — |

Essai après fusion (story 0.5) : Gemini a appliqué `bmad-review` au diff de la story (angles edge-case-hunter et verification-gap). Constats : guillemets simples non retirés à la lecture de `.env`, repris dans `scripts/lib/gitea.sh` (story 0.5) ; aucun test automatisé des scripts, reporté dans `deferred-work.md`.

## Reporté

- Tests automatisés des scripts : `deferred-work.md`.
