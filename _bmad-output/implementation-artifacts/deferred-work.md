# Travail reporté

Constats de revue reportés à plus tard, au format de `bmad-build`. Chaque entrée renvoie au fichier de la story qui l'a relevé ; on n'y modifie pas les entrées existantes.

- source_spec: `_bmad-output/implementation-artifacts/0-4-create-pull-request-skill.md`
  summary: Les scripts shell du projet (`check-private.sh`, `create-pull-request.sh`, puis `llm-review.sh`) n'ont aucun test automatisé ; leurs vérifications sont des essais manuels consignés dans les PR.
  evidence: Angle verification-gap de l'essai `bmad-review` sur le diff de la story 0.4 (14/09/2026) ; aucun fichier de test dans le dépôt. À proposer comme story à la fin de l'epic 0.
