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

- source_spec: `_bmad-output/implementation-artifacts/3-6-at-a-glance-box-and-format-rules.md`
  summary: C18 accepte une valeur d'encart faite uniquement d'espaces : la règle teste la longueur, pas le contenu utile (`context.company`, `role`, `period`).
  evidence: Constat non bloquant de la deuxième revue de la PR n° 41 (`c12e2d5`). À reprendre par la story 3.7, qui rouvre `content.sh` pour C19 et vérifie des clés voisines.


- source_spec: `_bmad-output/implementation-artifacts/5-5-photo-published-on-home-page.md`
  summary: La photo publiée est provisoire. Arnaud la garde « pour l'instant » et la remplacera quand il en aura une autre sous la main (décidé le 21/09/2026). Le registre du site est celui d'un dossier d'architecture, « sobre, exact, sans effet de séduction » (`DESIGN.md`) ; la photo actuelle est prise en extérieur, casquette et sac à dos, avec un logo de marque au centre du buste. Le remplacement ne demande aucune story : déposer l'original dans `docs/private/assets/`, relancer `scripts/photo/prepare.sh <original> <ancrage>`, regarder le cadrage, **réécrire `portrait_alt` dans `content/_index.{fr,en}.md`** pour décrire la nouvelle photo — sans quoi l'alternative décrirait l'ancienne, régression d'accessibilité qu'aucun contrôle ne verrait (constat de la revue de la PR n° 70) —, puis commiter.
  evidence: Question posée à Arnaud à la story 5.5, avec les deux cadrages candidats sous les yeux ; réponse « on garde celle-ci pour l'instant ».

- source_spec: `_bmad-output/planning-artifacts/epics.md`, epic 8
  summary: L'epic 8 (schémas D2 à double thème) est reporté après l'epic 9. Arnaud n'a aucun schéma à produire pour l'instant, et cet epic n'outille que des schémas. Il ne bloque rien avant la mise en ligne : seule la story 13.4 en dépend, après la release et déjà bloquée par Q1. À reprendre quand un cas aura un schéma à montrer ; la branche `experiment/d2-bilingue` porte le travail exploratoire.
  evidence: Décision d'Arnaud du 22/09/2026, après la rétrospective de l'epic 7. Absence de dépendance vérifiée en relisant toutes les lignes « Dépendances » et « Bloquée par » du backlog : seules les stories 8.2, 8.3 et 13.4 citent une story 8.x.

- source_spec: `_bmad-output/implementation-artifacts/9-1-legal-notice-and-confined-address.md`
  summary: C23 ne décode pas l'URL-encodage. Si un gabarit écrivait l'adresse de l'éditeur dans un attribut de lien, Go l'encoderait (`%27`, `%20`) et le contrôle ne la verrait pas. Constat refusé à la story 9.1 : aucun gabarit ne le fait, et `legal-value.html` refuse déjà toute lecture hors des deux pages légales, si bien que le chemin suppose un gabarit qu'il faudrait écrire exprès. À reprendre si une story pose l'adresse dans une URL — la 9.6 (données structurées `Person`) est la première qui pourrait s'en approcher. Le décodage devra porter sur `%XX` seulement : décoder `+` en espace créerait des faux positifs sur toute chaîne de requête de la page.
  evidence: Constat bloquant de la septième revue de la PR n° 98, refusé avec sa raison ; les deux autres constats du même tour ont été retenus et corrigés.

- source_spec: `_bmad-output/implementation-artifacts/9-7-host-identification-without-phone.md`
  summary: C23 tronque silencieusement un fichier non-HTML qui porte un octet nul. `contenu=$(cat …)` à `scripts/checks/legal-address.sh:217` déclenche « command substitution: ignored null byte in input » sur les quatre CV PDF, et bash **coupe la chaîne au premier octet nul** : la confrontation ne porte alors que sur le début du fichier. L'adresse de l'éditeur placée après un octet nul échapperait au contrôle. Le garde-fou de l'encodage juste au-dessus ne rattrape pas ce cas : `file` rend « binary » pour bien des formats, mais pas pour tous, et un PDF passe. À reprendre en lisant le fichier autrement qu'en substitution de commande — `grep -F -f` directement sur le fichier, ou `tr -d '\0'` avant comparaison, en disant lequel et pourquoi.
  evidence: Avertissement observé quatre fois dans le job de contrôles réel (`scripts/ci/checks-job.sh`, 24/09/2026) pendant la story 9.7. Préexistant : la story ne touche pas `legal-address.sh`. Le contrôle passe, ce qui est précisément le problème — un faux négatif ne se voit pas.

- source_spec: `_bmad-output/implementation-artifacts/epic-9-retro-2026-09-24.md`
  summary: `scripts/llm-review.sh <PR>` n'affiche jamais le corps du rapport : il le publie en commentaire de PR et ne l'écrit que dans le fichier de story. Une PR sans story — actions de rétrospective, procédure, outillage — laisse donc son auteur incapable de lire les constats qu'il doit trancher, alors que le point 20 d'AGENTS.md le lui impose. Contourné le 24/09/2026 par un script jetable lisant la timeline de la forge. À reprendre en écrivant le rapport sur la sortie standard, ou dans un fichier quand `--out` est donné, comme le fait déjà le mode `--range`.
  evidence: Constaté sur la PR n° 107 (`docs/epic-9-retro-actions`, sans story). `scripts/llm-review.sh:342` — « aucune story associée : fichier de story non mis à jour » — puis aucune autre sortie. Le mode `--range` a déjà `--out` (`llm-review.sh:32`), donc le mécanisme existe.

- source_spec: `_bmad-output/implementation-artifacts/epic-9-retro-2026-09-24.md`
  summary: Deux revues du **même SHA** par le **même modèle** ont rendu des verdicts opposés — `pass` puis `block` sur `edface2` (PR n° 107). Le second constat, bloquant, était juste et a été corrigé ; le premier ne l'avait pas vu. Le verrou de fusion accepte le premier rapport non bloquant qu'il trouve, donc un `pass` de hasard suffit à ouvrir la fusion. À reprendre : soit le verrou lit le rapport **le plus récent** sur le SHA plutôt qu'un rapport quelconque, soit la procédure dit qu'un second avis ne s'ignore pas.
  evidence: PR n° 107, SHA `edface2`, `gemini-3.1-pro-high` : premier rapport `verdict=pass`, second `verdict=block` avec un constat que le premier n'avait pas relevé (la section `open_questions` n'était lue par aucun outil). Les deux rapports sont publiés sur la PR.

- source_spec: `_bmad-output/implementation-artifacts/epic-9-retro-2026-09-24.md`
  summary: Le relecteur externe apporte les **mémoires globales de son compte** dans la revue isolée de ce dépôt. Un verdict bloquant de la PR n° 107 exigeait une entrée dans `docs/CHANGELOG.md` en citant une règle « globale obligatoire » : elle existe bien, mais dans `~/.gemini/GEMINI.md`, où elle décrit un autre projet d'Arnaud dont la CI génère un changelog. Ce projet n'a ni changelog ni `docs/deployment-notes/`. C'est la même classe que « le relecteur ne voit pas le dépôt » (11 constats réfutés dans l'epic 9), et elle coûte des tours de revue. À reprendre : soit la copie isolée neutralise les mémoires du compte relecteur, soit la procédure dit comment les reconnaître — un constat qui cite une règle introuvable dans le dépôt se vérifie **hors** du dépôt avant d'être qualifié d'invention. Arnaud peut aussi restreindre cette mémoire au projet qu'elle vise.
  evidence: PR n° 107, SHA `7317c70`, verdict `block` : « violation directe de la règle globale absolue (`<RULE[user_global]>`) ». Règle trouvée à `/home/eleyone/.gemini/GEMINI.md:3`. Le projet visé est vraisemblablement `calculatrice-rentabilite`, dont la copie de travail porte `.gitea/workflows/semantic-release.yml`. Le point 20 d'AGENTS.md disait « le relecteur a inventé la règle » jusqu'à ce que cette revue prouve le contraire ; il est corrigé.

- source_spec: `_bmad-output/implementation-artifacts/10-5-publish-pilot-case-02.md`
  summary: `scripts/publish-case.sh` crée une branche **sans numéro de story** — `feat/publish-case-<clé>` (`publish-case.sh:100`) — que `verify-and-merge-pr` ne sait pas rattacher à sa story : le verrou de suivi retombe alors sur le contrôle global au lieu de `--merge <n.m>`, et ne vérifie donc pas que la story est à `done`. Les deux outils du projet se contredisent : le script date de la story 3.17, écrite avant que la règle de nommage n'entre dans AGENTS.md (point 1, rétrospective de l'epic 7, 22/09/2026). À reprendre en faisant accepter au script une branche existante correctement nommée, ou en lui faisant lire la story dans le suivi pour composer `feat/<epic>-<story>-publish-case-<clé>`.
  evidence: Constaté à la story 10.5 (24/09/2026), qui a dû publier à la main sur `feat/10-5-publish-pilot-case-02` pour garder un nom de branche que le verrou reconnaît. Le script refuse aussi de partir d'une branche autre que `dev` (`publish-case.sh:97`), ce qui interdit de l'employer une fois le cadrage de la story commité.

- source_spec: `_bmad-output/implementation-artifacts/epic-10-retro-2026-09-24.md`
  summary: Aucun contrôle ne vérifie qu'un cas publié porte, côté anglais, la ligne de contexte que FR-22 lui assigne. FR-22 nomme cinq repères et le cas ou le bloc qui doit les expliquer — April Technologies (cas 06), Orange (cas 05), Systeme.io (cas 01), NCS/CS (cas 02), Ton Pote le Geek (cas 01 et bloc « En parallèle ») — mais cette correspondance ne vit que dans la prose du PRD. La faute s'est produite : la story 10.6 a découvert **à la main**, en relisant FR-22, que le cas 01 n'avait pas la ligne de Ton Pote le Geek, alors que son encart affichait ce cadre sans l'expliquer. À reprendre en portant la correspondance dans un fichier de données que le contrôle lit — `data/` ou le front matter du cas —, plutôt qu'en énumérant les repères dans un script, ce que le point 18 déconseille.
  evidence: Constat de la seconde revue de code de la PR n° 112, laissé sans décision puis tranché le 24/09/2026 (action 3 de la rétrospective de l'epic 10). Manque avéré à la story 10.6 : `content/cases/case-01-institut-lionne.en.md` n'avait pas sa ligne avant cette story, et aucun contrôle ne l'a signalé.
