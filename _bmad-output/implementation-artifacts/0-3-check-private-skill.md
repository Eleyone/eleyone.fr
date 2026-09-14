# Story 0.3 : Check-private skill

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 0.3. Fichier d'historique, écrit après coup à la story 0.5.

## Livraison

- PR n° 7 (`chore/0-3-check-private-skill`), fusionnée en squash : `1a46403`.
- Décisions d'Arnaud en cours de story : alertes du garde-fou sans contenu ni motif ; `PRIVATE_PATTERNS_FILE` obligatoire pour auditer une copie isolée ; skills du projet disponibles dans tous les outils par liens symboliques (découverte par Antigravity constatée par Arnaud).

## Revue de spec

Non faite : la revue de spec par un relecteur d'un autre fournisseur n'existait pas encore. La première a été faite à la main sur la story 0.5 ; elle est systématique à partir de la story 0.6. La story a été reformulée, et ses questions posées à Arnaud, avant l'implémentation.

## Revue du code

Revues manuelles (règle d'amorçage D-1) : `agy --mode plan --add-dir`, modèle `gemini-3.1-pro-high`, rapports publiés en commentaire de la PR n° 7.

| SHA relu | Verdict | Constats | Décision |
|---|---|---|---|
| `10f7b66` | block | 1. La découpe `tr`/`cut` sur tabulation cassait l'affichage d'une alerte pour un nom de fichier contenant une tabulation. 2. La procédure citait des commandes git absentes du script. 3. (non bloquant) `git grep` lancé une fois par motif et par commit. | 1. Corrigé : champs séparés par `\001`. 2. Corrigé : gestes décrits sans commande. 3. Corrigé sur décision d'Arnaud : un seul passage avec tous les motifs par arbre, le détail seulement en cas de résultat. |
| `49f6532` | pass | (non bloquant) `AGENTS.md` présentait encore `--mode plan` comme une lecture seule. | Reporté sur décision d'Arnaud, corrigé à la story 0.4. |

Constats de l'auteur pendant les corrections :

- un objet git illisible faisait écrire une erreur à `git grep`, mais avec le code « rien trouvé » : le garde-fou passait en silence, défaut antérieur à la story. Corrigé : toute erreur de lecture ou de recherche fait échouer le garde-fou ;
- lors de la revue de `10f7b66`, le relecteur a créé un fichier `RAPPORT_REVUE.md` dans la copie isolée : `agy --mode plan` n'est pas en lecture seule. Repris dans la story 0.5.

## Reporté

Aucun constat reporté.
