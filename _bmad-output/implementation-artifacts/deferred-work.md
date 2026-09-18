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

- source_spec: `_bmad-output/implementation-artifacts/2-2-bilingual-hugo-build-with-minimal-home.md`
  summary: `layouts/baseof.html` construit le `hreflang="x-default"` par `index . 0` (échec brut si une page n'a pas de version française), et le passage d'arguments à `hugo server` dans `scripts/dev.sh` n'a pas de cas de test.
  evidence: Deux constats non bloquants de la revue du code de la PR n° 25 (`540b654`), reportés à la story 2.3, qui possède le sélecteur de langue et les `hreflang`.

- source_spec: `_bmad-output/implementation-artifacts/2-6-case-section-numbers-and-table-of-contents.md`
  summary: `layouts/_markup/render-heading.html` descend chaque titre d'un cas groupé d'un niveau sans borne : un `######` y serait rendu en `<h7>`, balise qui n'existe pas en HTML.
  evidence: Constat non bloquant de la revue du code de la PR n° 31 (`99fe2e9`). Aucun cas n'a de titre au-delà du niveau 3. À traiter par la story 3.4 : C4 refuse un titre de niveau 6 dans un cas groupé, plutôt que le hook ne le masque.

- source_spec: `_bmad-output/implementation-artifacts/epic-2-retro-2026-09-17.md`
  summary: Deux libellés construits deux fois entre stories : le cadre `setup_…` dans `layouts/_partials/case.html:17` (story 2.5) et `layouts/_partials/position.html:13` (story 2.7) ; « Cas NN » dans les clés i18n `toc_case` (story 2.6) et `case_number` (story 2.7).
  evidence: Constats D1 et D2 de la rétrospective de l'epic 2. À traiter par la story 5.2, qui reprend `position.html` : un partial `setup-label.html`, et `toc_case` construit sur `case_number`.

- source_spec: `_bmad-output/implementation-artifacts/epic-2-retro-2026-09-17.md`
  summary: `layouts/_shortcodes/live-material.html:51` ne lit qu'un `viewBox` à coordonnées positives séparées par des espaces : un SVG dont le `viewBox` extérieur a une origine négative ou des virgules fait échouer le build (message explicite, jamais en silence).
  evidence: Constat R3 de la revue du diff de l'epic 2, non reproduit avec D2 0.9.0 (le `viewBox` extérieur vaut `0 0 …` sur un rendu ELK et sur les quatre SVG de `experiment/d2-bilingue`). À revoir par la première story qui publie un schéma « prêt ».

- source_spec: `_bmad-output/implementation-artifacts/3-1-checks-json-manifest-emitted-by-hugo.md`
  summary: Aucun test n'exerce `layouts/home.checks.json` : les cas hors ligne ne couvrent que la découverte des manifestes (`checks_manifests`), pas les champs qu'ils contiennent.
  evidence: Angle verification-gap de la revue du code de la PR n° 35 (`82c225e`). À traiter par la story 3.2, premier consommateur du manifeste : un site fixture construit avec le Hugo épinglé, puis les champs vérifiés à `jq`.

- source_spec: `_bmad-output/implementation-artifacts/3-2-check-script-entry-point-and-draft-rule.md`
  summary: Clôture de l'entrée de la story 0.7 (« le substitut d'amorçage lance `scripts/check.sh` dans une copie sans `.tools/` ni `.env` ») : `verify-and-merge-pr.sh` passe désormais `TOOLS_LOCAL_DIR` à la copie de la tête, et les valeurs légales viennent du fichier factice commité.
  evidence: Story 3.2, qui crée `scripts/check.sh` ; reproduit puis vérifié sur une copie de la tête avant et après le correctif.

- source_spec: `_bmad-output/implementation-artifacts/3-4-headings-todo-markers-and-stack-vocabulary.md`
  summary: Clôture de l'entrée de la story 2.6 (« un `######` dans un cas groupé serait rendu en `<h7>` ») : C4 refuse tout titre plus profond que `###` dans un cas, et `docs/format-cas.md` l'écrit.
  evidence: Story 3.4 (18/09/2026), règle décidée par Arnaud ; cas de test `case_content_c4_titre_trop_profond` et essai sur le pilote.

