# Travail reporté

Constats de revue reportés à plus tard, au format de `bmad-build`. Chaque entrée renvoie au fichier de la story qui l'a relevé ; on n'y modifie pas les entrées existantes.

- source_spec: `_bmad-output/implementation-artifacts/0-4-create-pull-request-skill.md`
  summary: Les scripts shell du projet (`check-private.sh`, `create-pull-request.sh`, puis `llm-review.sh`) n'ont aucun test automatisé ; leurs vérifications sont des essais manuels consignés dans les PR.
  evidence: Angle verification-gap de l'essai `bmad-review` sur le diff de la story 0.4 (14/09/2026) ; aucun fichier de test dans le dépôt. À proposer comme story à la fin de l'epic 0.

- source_spec: `_bmad-output/implementation-artifacts/0-7-verify-and-merge-pr-skill.md`
  summary: Le substitut d'amorçage de la CI de `verify-and-merge-pr.sh` lance `scripts/check.sh` dans une copie de la tête qui ne contient ni `.tools/` ni `.env` ; quand `check.sh` existera, il faudra lui donner accès à Hugo et D2, sans quoi le verrou CI bloquera à chaque audit.
  evidence: Revue du code de la PR n° 11 (`327b234`) ; `scripts/check.sh` n'existe pas encore ; à traiter avec la story 3.2, qui le crée.

- source_spec: `_bmad-output/implementation-artifacts/0-9-shared-sprint-reading-and-script-tests.md`
  summary: Clôture de l'entrée « aucun test automatisé des scripts shell » (story 0.4) : `scripts/tests/run.sh` rejoue hors ligne les tests des scripts, sur le poste et en CI (story 3.12).
  evidence: Story 0.9 (15/09/2026), après la rétrospective de l'epic 0 (constat P1).

- source_spec: `_bmad-output/implementation-artifacts/2-1-pinned-tools-installed-and-verified.md`
  summary: `scripts/ci/install-tools.sh` écrit l'archive téléchargée sous le nom donné par `tools.env` sans le réduire à son nom de base (`basename`), et ne teste pas son arrêt quand `curl`, `tar` ou `sha256sum` manque.
  evidence: Deux constats non bloquants de la revue du code de la PR n° 24 (`212885b`), reportés d'un commun accord pour fermer la PR. À reprendre à la prochaine story qui touche ce script.
