## Projet

Le dépôt public eleyone.fr (site statique Hugo, portfolio et CV en ligne).

## Contexte

- Revue du code : AGENTS.md ; _bmad-output/planning-artifacts/epics.md (texte de la story) ; _bmad-output/implementation-artifacts/ (fichier de la story, sprint-status.yaml) ; _bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md ; docs/procedures/ ; scripts/ ; l'outillage commun dans .working-method/ (ses scripts, ses procédures dans .working-method/procedures/, et le bloc commun d'AGENTS.md, .working-method/agents/AGENTS.common.md).
- Revue de spec : AGENTS.md ; _bmad-output/planning-artifacts/epics.md (stories voisines) ; _bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md ; _bmad-output/implementation-artifacts/ (fichiers des stories déjà faites) ; scripts/, docs/procedures/ et .working-method/ déjà livrés.
- Revue de plage : la copie contient aussi les procédures de docs/procedures/ et de .working-method/procedures/, et les artefacts de cadrage de _bmad-output/. Contexte utile : AGENTS.md ; .working-method/procedures/shell-scripts.md (règles d'écriture des scripts et pièges connus) ; _bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md.

## Méthode de revue

Applique le skill de revue BMAD : lis et suis {{WORKTREE}}/.agents/skills/bmad-review/SKILL.md comme un fichier (inutile de le découvrir comme skill).

## Contrôles du projet

- les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée ;
- aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge ;
- skill, procédure et script concordent : une procédure ne cite aucune commande absente de son script, un skill ne décrit aucune étape absente de sa procédure ;
- le changement est cohérent avec AGENTS.md et les décisions d'architecture ;
- dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail.
