---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-eleyone.fr-2026-09-13/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/ux-designs/ux-eleyone.fr-2026-09-13/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-eleyone.fr-2026-09-13/EXPERIENCE.md
  - _bmad-output/planning-artifacts/briefs/brief-eleyone.fr-2026-09-13/brief.md
  - _bmad-output/planning-artifacts/briefs/brief-eleyone.fr-2026-09-13/addendum.md
  - docs/format-cas.md
  - data/stack.yaml
  - content/cases/chiliz/case-02-chiliz.fr.md
  - content/cases/chiliz/case-02-chiliz.en.md
  - scripts/check-private.sh
  - .githooks/pre-commit
  - _bmad-output/planning-artifacts/implementation-readiness.md
  - _bmad-output/planning-artifacts/sprint-change-proposal-2026-09-13.md
status: validated
created: 2026-09-13
updated: 2026-09-13
---

# eleyone.fr : découpage en epics et stories

## Présentation

Ce document découpe en epics et en stories le PRD, l'architecture et l'UX d'eleyone.fr. Il ne fixe rien de nouveau. Pour le **comment**, l'ordre de précédence est : l'architecture (`ARCHITECTURE-SPINE.md`, AD-1 à AD-24, contrôles C1 à C24), puis le PRD (FR-1 à FR-39, NFR-1 à NFR-13), puis `DESIGN.md` et `EXPERIENCE.md` (validés par Arnaud le 13/09/2026), puis `docs/format-cas.md` v0.4 et le brief. Aucune fonctionnalité n'est ajoutée. La v1.1 ne contient que ce que le PRD y place (génération des CV PDF, §8.2) et n'a aucune story ici.

Réalignement complet du 13/09/2026, sans interlocuteur (run headless). Là où l'atelier aurait posé une question, la réponse vient des documents. Ce qu'ils ne tranchent pas n'est pas décidé ici :

- une story n'est **bloquée** que par une question du PRD **encore ouverte** : Q1 (matériel vivant en v1), Q2 (période et cadre des cas), Q3 (contenu des vidéos), Q4 (signature unique), Q5 (stack du cas 03). Q13 (v1.1) ne bloque rien en v1 ;
- un contenu qu'Arnaud doit fournir (PRD §11.2, « Contenus à fournir ») est noté en **prérequis de contenu**, pas en blocage ;
- un point que les documents laissent ouvert ou contradictoire figure dans les questions de la story et dans « Tensions restantes ».

Les questions Q6 à Q12 et Q14 à Q17 sont tranchées (PRD §11.1), Q9 comprise (titre « Chiliz », sans introduction : décision D-4).

Mise à jour du 13/09/2026 (`bmad-correct-course`) : les décisions D-1 à D-17 et les corrections M-1 à M-18 du contrôle de préparation à l'implémentation (`implementation-readiness.md`) sont appliquées ; le détail est dans `sprint-change-proposal-2026-09-13.md`.

### Règles de conduite des stories

Ces règles s'appliquent à **chaque** story.

1. **Reformuler, puis questionner.** Avant chaque story, le développeur reformule ce qu'il a compris et pose ses questions à Arnaud. Mieux vaut une question de trop qu'une page à refaire. La rubrique « Questions à poser avant de commencer » liste les doutes prévisibles ; elle ne dispense pas des autres questions.
2. **Une story à la fois**, livrée seule, démontrée, terminée avant la suivante.
3. **Rien d'inventé** (NFR-10) : ni cas, chiffre, client, technologie, date, poste ou formation absents des sources. Les données de parcours, de formation, de certification et de langues viennent du CV d'Arnaud. Un contenu manquant reste un `[TODO: …]` dans un fichier en `draft: true`.
4. **Contenu et code sont séparés.** Arnaud rédige les cas avec son agent de rédaction, selon `docs/format-cas.md`. Le backlog ne contient, pour le contenu, que des stories d'**intégration** (« le contenu passe les contrôles et passe en `draft: false` »).
5. **Public.** Le dépôt est public : aucune donnée interdite par NFR-9 (ville ou adresse de résidence, téléphone, original de la photo…), aucun nom d'hôte, aucune adresse de serveur, aucun secret. Nommer `docs/private/` est autorisé ; son contenu ne l'est pas.
6. **Gabarits.** Toute story qui crée ou modifie un gabarit s'appuie sur `DESIGN.md` et `EXPERIENCE.md`, et passe la check-list manuelle d'AD-17 sur les gabarits touchés, **en mode clair et en mode sombre** : clavier et focus visible, reflow à 320 px et zoom à 200 %, contraste, cibles de 24 px, ordre de lecture, alternatives des images. Les tranches du walking skeleton (Epic 2) livrent une structure HTML sans mise en page (architecture, « Reporté ») ; la mise en page arrive à partir de l'Epic 5.
7. **Contrôles.** Dès que `scripts/check.sh` existe (story 3.2), chaque story se termine avec `scripts/check.sh` au vert.
8. **Libellés.** Les libellés d'interface viennent d'`EXPERIENCE.md` (« Voice and Tone »). Un libellé encore « à valider par Arnaud » est confirmé par lui avant commit.
9. **Flux de travail.** Chaque story se développe sur une branche issue de `dev` (`feat/*`, `fix/*`, `chore/*` ou `docs/*`), passe par `create-pull-request`, `llm-review` et `verify-and-merge-pr` (Epic 0), ou par la règle d'amorçage (règle 11) tant que ces skills n'existent pas, et se fusionne en squash vers `dev`. Aucun merge commit ; répétition sur un tag `vX.Y.Z-rc.N` posé sur `dev`, puis publication vers `main` en fast-forward par le skill `release`. Un correctif de production part de `main` sur une branche `hotfix/*` (skill `hotfix`). Les jetons et identifiants se définissent dans `.env`, jamais commité (story 0.1). Le statut de la story avance dans sa propre PR : `in-progress` au premier commit, `review` avant la revue LLM, `done` après une revue positive, juste avant la fusion (AD-24). Chaque story a son fichier de story, et commence par une revue de spec (story 0.5).
10. **Opérations manuelles.** Les stories marquées « Opération manuelle (Arnaud) » touchent le serveur Gitea et son image Docker, le serveur de production, Nginx Proxy Manager, le DNS, les secrets, la photo originale ou les CV PDF. La procédure vient de l'architecture ; Arnaud l'exécute, le développeur prépare les fichiers versionnés et la liste de vérification.
11. **Amorçage des verrous** (AD-24, décision D-1). Pour les premières PR, avant la CI et les skills de l'Epic 0 : le verrou CI vaut `absent`, admis seulement tant que `.gitea/workflows/checks.yaml` n'existe pas sur la branche de base, et il est remplacé par `scripts/check-private.sh history`, puis aussi `scripts/check.sh` dès la story 3.2, lancés sur le SHA de tête par `verify-and-merge-pr` (story 0.7), qui affiche le verrou CI « absent » avec leur résultat. La planification de sprint est faite avant la story 0.1, et la PR qui ajoute `sprint-status.yaml` est la seule fusionnée sans verrou de suivi. Avant `llm-review`, la revue se fait par `agy --mode plan`, lancé à la main dans un worktree temporaire hors du dépôt, avec le rapport collé en commentaire de PR au format d'AD-24 ; Arnaud fusionne à la main.

### Lecture des stories

- **Couvre** : exigences du PRD (FR, NFR, UJ, SM), décisions d'architecture (AD), contrôles (C) et exigences UX (UX-DR, ci-dessous).
- **Dépendances** : stories à terminer avant, et documents requis.
- **Bloquée par** : question ouverte du PRD, ou « — ».
- **Prérequis de contenu** : ce qu'Arnaud fournit avant la story.
- **Opération manuelle (Arnaud)** : ce qu'Arnaud exécute lui-même.
- Un critère *(relecture)* se vérifie par une relecture humaine. Une « copie locale non commitée » sert à une démonstration et n'est jamais poussée.

## Inventaire des exigences

### Exigences fonctionnelles

Résumé ; le texte et les conséquences testables du PRD font foi.

**Accueil CV**
- FR-1 : haut de l'accueil, dans l'ordre : ligne d'identité, titre du site, pitch de trois phrases ; texte modifiable sans gabarit.
- FR-2 : parcours du plus récent au plus ancien ; chaque poste (société, intitulé, période, ville de travail ou cadre) liste ses cas publiés par numéro et titre, sans « En bref » ; poste sans cas complet et sans zone de cas ; corps d'un poste affiché seulement sans cas ; cas 06 sous le poste April Technologies de 2017.
- FR-3 : appel à contact vers la page Contact de la même langue.
- FR-4 : bloc « En parallèle » : lien vers Ton Pote le Geek et vers le cas 01, ligne de contexte EN, aucune page d'offre.
- FR-33 : ligne d'identité « Arnaud Grousset · Eleyone », « Basé en France » seul lieu public hors mentions légales, nom dans le `<title>` de l'accueil.
- FR-34 : photo publiée sur l'accueil et « À propos », copie redimensionnée sans métadonnée (vérifiée), original hors dépôt, `alt` FR et EN, dans le budget.
- FR-35 : un seul bloc JSON-LD « Person » par accueil, données seulement (nom, pseudonyme, intitulé, pays, URL, LinkedIn, GitHub) ; seule exception à NFR-12.
- FR-36 : bloc formation, certification et langues après le parcours, données tirées du CV.
- FR-37 : premier écran mobile 390 × 844 sans défilement : identité, titre, pitch, début du premier poste avec le lien de son premier cas.
- FR-38 : CV PDF FR et EN liés depuis le pied de page de toutes les pages et en évidence sur « À propos », jamais dans l'en-tête ; publiés ensemble ou pas du tout ; contrôle du texte et des métadonnées avant l'historique et avant chaque mise en ligne ; socle possible sans PDF.

**Pages cas**
- FR-5 : ordre d'un cas : titre, « Contexte mission », « En bref », cas complet.
- FR-6 : « Contexte mission » : société, cadre, rôle, période, stack ; libellés par langue ; stack issue de `data/stack.yaml`.
- FR-7 : « En bref » : enjeu puis résultat, 3 phrases et 400 caractères au plus.
- FR-8 : rubriques de `docs/format-cas.md`, dans l'ordre, identiques en FR et en EN.
- FR-9 : page Chiliz (cas 02, 03, 04 dans l'ordre), correcte avec la seule section 02 ; sections adressables ; titre et introduction : Q9.
- FR-10 : non-aboutissement du cas 03 et limites de mesure du cas 05 présentés tels quels.
- FR-11 : cas 01 rattaché à Ton Pote le Geek, lié depuis « En parallèle ».
- FR-12 : matériel vivant déclaré et placé ; « prévu » invisible en production, visible en rendu de travail.
- FR-13 : schéma en SVG FR et EN, alternative textuelle ; livraison selon Q1.
- FR-14 : vidéo en simple lien YouTube ; contenu selon Q3.
- FR-15 : chaque cas publié atteint en un clic depuis l'accueil ; lien « Retour au parcours » vers son poste.

**Pages simples et légales**
- FR-16 : « À propos » : ce qu'Arnaud fait bien, ce qu'il ne veut pas être, comment il travaille ; CV PDF en évidence ; photo.
- FR-17 : Contact : adresse mail et LinkedIn écrits dans le contenu commité, sans formulaire.
- FR-18 : mentions légales ; valeurs injectées au build ; commune de l'éditeur sur cette seule page ; build de production en échec si une valeur manque.
- FR-19 : politique de confidentialité minimale, vraie sur toute la chaîne, proxy compris.

**Bilinguisme et parité**
- FR-20 : chaque page en FR et en EN ; accueils avec les mêmes postes et les mêmes liens.
- FR-21 : français à la racine, anglais sous `/en/`, sans redirection ; sélecteur visible ; `hreflang` et langue déclarées.
- FR-22 : lignes de contexte EN (April Technologies, Orange, Systeme.io, NCS/CS, Ton Pote le Geek).
- FR-23 : script de parité bloquant.
- FR-24 : agent de parité consultatif sur les PR de contenu de la forge principale.

**Contenu, mise en ligne, dépôt public**
- FR-25 : édition sans toucher aux gabarits ni aux scripts (cas, schémas, stack, postes, formation, pages).
- FR-26 : aucun brouillon ni `[TODO` en ligne ; rendu de travail avec brouillons et éléments prévus.
- FR-27 : SVG commités, régénérés et comparés en CI.
- FR-28 : garde-fou public/privé non contournable, audit complet avant GitHub ; PDF et images ont leurs propres contrôles.
- FR-29 : lien vers le dépôt public.
- FR-30 : README-cas en anglais, structuré comme un cas.
- FR-31 : artefacts de cadrage publics, sans cas brut.
- FR-32 : socle, puis cas 03, 04 et 06 un par un, par tag.
- FR-39 : répétition de toute la chaîne de mise en ligne sur le serveur de production, sans DNS, avant le premier tag du socle, retour arrière compris.

### Exigences non fonctionnelles

- NFR-1 : site statique Hugo.
- NFR-2 : conteneur nginx sur l'infrastructure existante ; une panne de la forge ne touche pas le site.
- NFR-3 : aucun cookie, aucun bandeau.
- NFR-4 : WCAG 2.2 AA, en mode clair et en mode sombre.
- NFR-5 : Core Web Vitals « bons » sur mobile et budget de poids, photo comprise.
- NFR-6 : design sobre, direction « Dossier d'architecture » avec accent vert (`DESIGN.md`, `EXPERIENCE.md`).
- NFR-7 : maintenance minimale, scripts simples.
- NFR-8 : rendu D2 identique à l'octet sur x86_64.
- NFR-9 : frontière public/privé (interdit, autorisé et public, site seulement).
- NFR-10 : rien d'inventé ; parcours tiré du CV.
- NFR-11 : clé de l'agent protégée.
- NFR-12 : zéro JavaScript, sauf le bloc JSON-LD.
- NFR-13 : mode sombre en CSS pur (`prefers-color-scheme`).

### Exigences complémentaires issues de l'architecture

Pas de gabarit de démarrage ; le dépôt part de la structure initiale de l'architecture.

- **AD-1** : versions et sha256 de Hugo v0.166.0 et D2 v0.9.0, `CHECK_IMAGE` (`alpine:3.24` par digest) dans `tools.env` seul ; `install-tools.sh` installe `bash`, `git`, `grep` GNU, `jq`, `libxml2-utils`, `poppler-utils` ; avec `--local`, Hugo et D2 sur le poste, dans `.tools/`.
- **AD-2** : langues, permaliens, slugs ; `<title>` construit par `baseof.html` seul (titre de page puis identité) ; sélecteur « English » / « Français », sans ancre.
- **AD-3** : aucun texte de contenu dans les gabarits ; mail et LinkedIn dans le front matter de `content/contact` ; `params.source_url` vide ⇒ aucun lien ; libellés dans `i18n/`.
- **AD-4** : cas groupés, cascade ciblée, `_index` de groupe en brouillon tant qu'aucun cas du groupe n'est publié ; hook de titres (préfixe d'identifiant, descente de niveau, numéro de rubrique `NN.r` par cas, classe `rubric-heading`) ; sommaire `<details>` ; `case-url.html` ; `content/cases/_index` jamais rendu.
- **AD-5** : `build.sh work|production` ; `noindex` et marqueur « Brouillon » en rendu de travail seulement.
- **AD-6** : shortcode `live-material` ; résolution par type ; schéma large sans `style` en ligne.
- **AD-7** : pipeline D2, thème clair et sombre venant de `DESIGN.md`, **spike D2 à double thème avant toute story du pipeline**, avec repli.
- **AD-8** : zéro script exécutable (exception AD-20), une CSS, mode sombre en CSS pur, budget chiffré.
- **AD-9** : sept `HUGO_LEGAL_*` ; lecture refusée hors pages `legal-notice` ; chargeur `env.sh` (`ENV_MODE=release` + `LEGAL_ENV_FILE`), qui ne transmet à Hugo que les `HUGO_LEGAL_*` ; secret BuildKit ; C22 sur la sortie.
- **AD-10** : `check.sh` unique ; manifeste (rôles `home`, `case`, `group`, `position`, `education`, `page`) ; règles de forme tolérantes aux `[TODO` des brouillons.
- **AD-11** : workflows minces ; runners Gitea en **mode hôte** pour les jobs Docker ; tags `vX.Y.Z` et `vX.Y.Z-rc.N`.
- **AD-12** : garde-fou en trois couches ; `pre-receive` fermé sans liste des motifs ; chemins interdits `docs/private/`, `docs/context/`, `.env`, `assets/cv/*.pdf` (ce dernier tant que le hook ne lit pas les PDF) ; miroir après hook et audit ; ruleset GitHub qui ne laisse écrire que l'identité du miroir.
- **AD-13** : image multi-étapes, nginx (CSP sur HTML seulement, cache long pour `css`, `svg`, `webp`, `no-cache` pour HTML et PDF, 404 par langue).
- **AD-14** : livraison `docker save | ssh` vers `deploy-site` (`deploy`, `rollback`, `status`, `rehearse …`).
- **AD-15** : journaux sans IP dans le conteneur et dans Nginx Proxy Manager.
- **AD-16** : agent de parité en script HTTP, Gitea seulement.
- **AD-17** : contrôles automatiques, check-list manuelle par gabarit en clair et en sombre, critère 390 × 844, mesures consignées dans `docs/measures/`.
- **AD-18** : `content/career/position-<id>` et `content/education/education-<id>` ; clé `position` dans le cas ; ancres `#position-<id>` et « Retour au parcours » ; `position-ton-pote-le-geek` en `track: parallel` ; identifiants de poste figés (`position-<société>`, suivi de `-<année de début>` si la société revient).
- **AD-19** : identité dans `content/_index` ; `scripts/photo/prepare.sh` (Hugo, recadrage 4:5, 640 × 800, ancrage manuel) ; variantes accueil et « À propos » ≤ 40 Ko.
- **AD-20** : JSON-LD `Person`, un bloc par accueil, champs de FR-35 seulement, sources fixées (`job_title` de `content/_index`, `linkedin` et `github` de `content/contact`, lien vide omis).
- **AD-21** : `assets/cv/cv-{fr,en}.pdf`, liens conditionnels « ensemble ou rien », C21 en pre-commit, pre-receive (après `poppler-utils` sur Gitea) et `release`.
- **AD-22** : canal de répétition `site-rehearsal` sur `127.0.0.1:18080`, accès par tunnel SSH, tags `-rc.N`, première répétition tôt sur `v0.1.0-rc.N`, jalon « répétition générale » avant `v1.0.0` ; tag `-rc` de même arbre exigé pour `v1.0.0` seulement.
- **AD-23** : typographie française appliquée au build par `_partials/typo-fr.html`, pages FR seulement.
- **AD-24** : flux de développement : `feat/*`, `fix/*`, `chore/*` et `docs/*` depuis `dev` en squash, `dev` → `main` en fast-forward, `hotfix/*` depuis `main` ; protections Gitea ; outillage en trois niveaux (neuf skills) ; revue par un LLM d'un autre fournisseur dans un worktree hors du dépôt, rapport `llm-review sha=… base=… model=… verdict=…` ; verrous de fusion, règle d'amorçage, exception documentaire sur tout `_bmad-output/` ; prérequis du poste (`jq`, `agy`, Docker dans WSL, Hugo et D2 locaux).
- **Contrôles C1 à C24** : chacun est rattaché à une story.
- **Procédures** : hook pre-receive (7 étapes, dont les PDF et l'image Gitea dérivée) ; premier déploiement (9 étapes, dont la répétition générale et la mesure).
- **Walking skeleton** : WS-0 à WS-5, puis, hors squelette : parcours et formation, photo et JSON-LD, CV PDF, typographie, spike D2 puis pipeline, pages simples et légales, `release`, répétition générale, premier déploiement, agent de parité.

### Exigences de design UX

Tirées de `DESIGN.md` et `EXPERIENCE.md` (validés le 13/09/2026). Aucune valeur n'est recopiée ici : chaque story renvoie au composant ou à la section concernée.

- UX-DR1 : tokens de couleur, huit rôles en clair et en sombre, `color-scheme: light dark`, contrastes calculés (`DESIGN.md`, « Colors ») — story 5.1.
- UX-DR2 : piles de polices système et échelle typographique en `rem` (« Typography ») — story 5.1.
- UX-DR3 : grille, gouttière, mesure, colonne de marge et de note, cadres md et lg, points de rupture 48 et 80 rem (« Layout & Spacing ») — stories 5.1, 5.2, 6.1.
- UX-DR4 : composants `link`, `focus-ring` (y compris `forced-colors`), `skip-link` — story 5.1.
- UX-DR5 : `site-header` (marque, « À propos », « Contact », sélecteur ; pas de CV) — stories 5.1, 9.3, 9.4.
- UX-DR6 : `site-footer` (CV, mentions légales, confidentialité, code source) — stories 5.1, 7.2, 9.1, 9.2, 9.5.
- UX-DR7 : `identity-block` — story 5.2.
- UX-DR8 : `cv-position` et `attached-case` (barre de révision, poste sans cas, corps affiché sans cas) — story 5.2.
- UX-DR9 : bloc formation, certification et langues en registre compact — story 5.3.
- UX-DR10 : `portrait` (4:5, tailles, variantes, budget) — stories 5.4, 5.5, 9.4.
- UX-DR11 : `context-box` et `summary-box` — story 6.1.
- UX-DR12 : `toc` et `rubric-heading` (numéros, `:target`, `scroll-margin-top`) — stories 2.6 (structure), 6.1 (forme).
- UX-DR13 : `note-block` — stories 9.4, 13.5.
- UX-DR14 : `cv-links` — stories 7.2, 9.4.
- UX-DR15 : `live-material-slot` (prêt par type, prévu en rendu de travail, schéma large, mode sombre ou repli) — stories 2.5, 13.4 à 13.6.
- UX-DR16 : `legal-list` — story 9.1.
- UX-DR17 : typographie française et anglaise (espaces insécables, pas de césure, `text-wrap`) — stories 6.3, 5.1.
- UX-DR18 : premier écran par page, dont l'accueil 390 × 844 (FR-37) — stories 5.2, 6.1, 10.1, 11.11.
- UX-DR19 : libellés d'interface de « Voice and Tone », décidés ou à valider — toute story qui en pose.
- UX-DR20 : plancher d'accessibilité (repères, plan des titres, ordre du DOM, clavier, cibles) — check-list de chaque story de gabarit.
- UX-DR21 : mise en page des pages simples et de la 404 — stories 5.1, 9.1 à 9.4.
- UX-DR22 : marqueur « Brouillon » en rendu de travail — story 2.7.
- UX-DR23 : accord des schémas D2 (N1 aligné sur `ink`, thème sombre de départ) — stories 8.1, 8.2.
- UX-DR24 : test des trente secondes (cinq testeurs, trois questions, quatre sur cinq) — story 11.10.

### Carte de couverture des FR

- FR-1 : 2.2, 5.2, 10.1
- FR-2 : 2.7, 5.2, 10.2
- FR-3 : 9.3
- FR-4 : 5.2, 10.2, 10.6
- FR-5 à FR-8 : 2.5, 3.3, 3.4, 3.6, 6.1, 6.2
- FR-9 : 2.5, 3.5, 6.1, 10.4, 11.1
- FR-10 : 10.7, 13.1
- FR-11 : 10.6
- FR-12 : 2.5, 3.5, 13.4 à 13.6
- FR-13 : 8.2, 8.3, 13.4
- FR-14 : 3.8, 13.6
- FR-15 : 2.7, 3.10, 6.2
- FR-16 : 9.4
- FR-17 : 9.3
- FR-18 : 0.1, 2.4, 9.1, 11.2, 11.3
- FR-19 : 4.2, 9.2, 11.11
- FR-20 : 2.2, 3.3, 6.3
- FR-21 : 2.3
- FR-22 : 10.2, 10.5 à 10.7, 13.3
- FR-23 : 3.3, 8.3
- FR-24 : 12.1, 12.2
- FR-25 : 2.7, 3.17, 10.2 à 10.7
- FR-26 : 2.2, 2.7, 3.2, 3.4, 11.1
- FR-27 : 8.2, 8.3
- FR-28 : 0.2, 0.3, 0.7 à 0.9, 1.1 à 1.4, 3.12, 7.3
- FR-29 : 9.5
- FR-30 : 0.2, 3.15
- FR-31 : 1.4
- FR-32 : 11.7, 11.11, 13.1 à 13.3
- FR-33 : 2.2, 5.2, 9.1
- FR-34 : 5.4, 5.5, 9.4
- FR-35 : 3.8, 9.6
- FR-36 : 5.3, 10.3
- FR-37 : 5.2, 10.1, 11.11
- FR-38 : 7.1 à 7.4, 9.4
- FR-39 : 11.4, 11.5, 11.8, 11.9, 11.10

## Liste des epics

L'ordre suit le walking skeleton, précédé de l'outillage de développement (Epic 0, décidé par Arnaud le 13/09/2026) : WS-0, puis WS-1 à WS-5, puis l'ordre « hors du squelette » de l'architecture. Deux ajustements, pour qu'aucune story ne dépende d'une story suivante : le JSON-LD vient après la page Contact, qui porte le lien LinkedIn ; les stories d'intégration du contenu du socle forment un epic placé avant la mise en ligne. Troisième ajustement (décision D-5) : les stories 11.1 à 11.9 (chaîne de mise en ligne, skills `release` et `rehearse-release`, première répétition) sont placées avant l'Epic 10, dont elles ne dépendent pas, pour répéter tôt ; les stories 11.10 à 11.13 (test des trente secondes, socle en ligne, `hotfix`, retour arrière) restent après lui. Les numéros des stories sont conservés.

### Epic 0 : Outillage de développement
Arnaud et ses agents travaillent sur un flux de branches linéaire sans merge commit, avec revue LLM d'un autre fournisseur, verrous de fusion et garde-fou avant tout envoi. Jeton Gitea dans `.env` et `.env.example`, protections des branches, skills `check-private`, `create-pull-request`, `llm-review`, `sprint-consistency`, `verify-and-merge-pr`, puis leur durcissement après la rétrospective (stories 0.8 et 0.9) ; les skills `publish-case`, `release`, `rehearse-release` et `hotfix` et le verrou « CI verte » sont placés après les stories dont ils dépendent.
**FR :** FR-28, FR-30. **NFR :** NFR-7, NFR-9, NFR-11. **AD :** AD-12, AD-24.

### Epic 1 : Garde-fou public/privé avant tout miroir (WS-0)
Arnaud peut publier le dépôt sur GitHub sans qu'aucun chemin ni motif privé y arrive.
**FR :** FR-28, FR-31. **NFR :** NFR-9. **AD :** AD-12. **C :** C2.

### Epic 2 : Site bilingue et cas pilote sous son poste (WS-1, WS-2)
Un lecteur passe du français à l'anglais, voit en rendu de travail le poste Chiliz avec le cas 02, et ouvre la section du cas sur la page Chiliz.
**FR :** FR-1, FR-2, FR-5 à FR-9, FR-12, FR-15, FR-18, FR-20, FR-21, FR-25, FR-26, FR-33. **NFR :** NFR-1, NFR-7, NFR-8. **AD :** AD-1 à AD-6, AD-9, AD-18, AD-19, AD-24.

### Epic 3 : Contrôles bloquants, CI des deux forges et README-cas (WS-3, WS-4)
Arnaud reçoit un refus explicite pour tout écart ; les mêmes contrôles tournent en local, sur Gitea et publiquement sur GitHub ; le README accueille Sam.
**FR :** FR-5 à FR-9, FR-12, FR-14, FR-15, FR-20, FR-23, FR-26, FR-28, FR-30, FR-35. **NFR :** NFR-3, NFR-4, NFR-5, NFR-7, NFR-12. **AD :** AD-10, AD-11, AD-12, AD-17, AD-20, AD-24. **C :** C1, C3 à C8, C10 à C14, C16, C18, C19. Comprend aussi le verrou « CI verte » et le skill `publish-case`.

### Epic 4 : Image du site servie par nginx (WS-5)
Le build de production est servi par un conteneur nginx avec ses en-têtes, son cache, ses 404 par langue et des journaux sans IP.
**FR :** FR-19, FR-21. **NFR :** NFR-1, NFR-2, NFR-3, NFR-5, NFR-12. **AD :** AD-13, AD-15.

### Epic 5 : Design validé et accueil CV
Claire lit sur son téléphone, en clair ou en sombre, un accueil qui est un CV : identité, photo, parcours avec les cas par poste, « En parallèle », formation.
**FR :** FR-1, FR-2, FR-4, FR-33, FR-34, FR-36, FR-37. **NFR :** NFR-4, NFR-5, NFR-6, NFR-9, NFR-13. **AD :** AD-8, AD-17, AD-18, AD-19. **C :** C13, C20.

### Epic 6 : Pages de cas mises en forme et typographie française
Claire lit un cas mis en page, avec sommaire, rubriques numérotées et retour au parcours ; les pages françaises suivent la typographie française.
**FR :** FR-5 à FR-9, FR-15, FR-20. **NFR :** NFR-4, NFR-10. **AD :** AD-3, AD-4, AD-23. **C :** C24.

### Epic 7 : CV PDF, ensemble ou rien
Claire peut garder un CV en PDF, et aucun PDF contenant un téléphone ou une ville de résidence n'entre dans l'historique.
**FR :** FR-28, FR-38. **NFR :** NFR-9. **AD :** AD-12, AD-21. **C :** C21.

### Epic 8 : Schémas D2 à double thème, régénérés et vérifiés
Un schéma bilingue suit le mode du lecteur (ou son repli validé), et la CI refuse tout SVG désynchronisé.
**FR :** FR-13, FR-23, FR-27. **NFR :** NFR-8. **AD :** AD-7. **C :** C9.

### Epic 9 : Pages légales, pages simples et données structurées
Un lecteur trouve mentions légales, confidentialité, Contact, « À propos » et le lien vers le dépôt ; les moteurs lisent l'identité d'Arnaud.
**FR :** FR-3, FR-16 à FR-19, FR-29, FR-33 à FR-35, FR-38. **NFR :** NFR-9, NFR-12. **AD :** AD-3, AD-9, AD-15, AD-20. **C :** C10, C23.

### Epic 10 : Contenu du socle
Le pitch, le parcours, la formation, la page Chiliz et les cas 01, 02 et 05 passent les contrôles et quittent l'état de brouillon.
**FR :** FR-1, FR-2, FR-4, FR-9 à FR-11, FR-22, FR-25, FR-36. **NFR :** NFR-10.

### Epic 11 : Mise en ligne, répétition générale et socle
La chaîne de mise en ligne et les skills `release`, `rehearse-release` et `hotfix` sont construits ; la chaîne est répétée sur le serveur de production, le test des trente secondes est passé, puis le socle est mis en ligne derrière un proxy sans journal d'IP. Les stories 11.1 à 11.9 se placent avant l'Epic 10, les stories 11.10 à 11.13 après lui (D-5).
**FR :** FR-18, FR-19, FR-26, FR-32, FR-37, FR-39. **NFR :** NFR-2, NFR-3, NFR-5, NFR-9. **AD :** AD-9, AD-11, AD-14, AD-15, AD-17, AD-22, AD-24. **C :** C15, C22.

### Epic 12 : Agent de parité consultatif
Sur une PR de contenu, Arnaud reçoit un commentaire qui signale un écart FR/EN, sans blocage.
**FR :** FR-24. **NFR :** NFR-11. **AD :** AD-16. **C :** C17.

### Epic 13 : Après le socle : cas 03, 04 et 06, matériel vivant prêt
Les cas 03, 04 et 06 sont mis en ligne un par un sous leur poste ; le matériel vivant retenu pour la v1 passe à « prêt ».
**FR :** FR-10, FR-12 à FR-14, FR-22, FR-32. **NFR :** NFR-3, NFR-10. **AD :** AD-6, AD-7.

## Epic 0 : Outillage de développement

Arnaud et ses agents travaillent sur un flux de branches linéaire, sans merge commit : chaque PR est relue par un LLM d'un autre fournisseur, vérifiée par des verrous, et aucun contenu privé ne sort du dépôt, ni vers GitHub, ni vers le reviewer. Décidé par Arnaud le 13/09/2026.

**Principe des skills.** Chaque skill tient en trois niveaux : `.claude/skills/<nom>/SKILL.md` (quelques lignes : quand l'utiliser, renvoi à la procédure), `docs/procedures/<nom>.md` (la procédure, lisible par tout agent ou humain), `scripts/<nom>.sh` (l'exécution, en shell simple). Documents publics, en français ; identifiants en anglais. Chaque skill est disponible quel que soit l'outil : `.agents/skills/<nom>` et `.agent/skills/<nom>` sont des liens symboliques relatifs vers `.claude/skills/<nom>/` (story 0.3).

**Identifiants.** Tous les jetons et identifiants se définissent dans le fichier `.env` à la racine, jamais commité (déjà ignoré par git et refusé par le garde-fou). Un skill qui appelle l'API de Gitea charge `.env` sans jamais afficher de valeur ; sans variable, il échoue avec un message qui renvoie à la procédure de la story 0.1, et ne demande jamais le jeton.

**Modèle de branches.** Branches de travail `feat/*`, `fix/*`, `chore/*` ou `docs/*` issues de `dev`, PR vers `dev` en **squash**. Publication de `dev` vers `main` en **fast-forward seulement** : `main` reste toujours un ancêtre de `dev`, et la publication échoue si `main` a divergé. Tags de répétition `vX.Y.Z-rc.N` sur `dev`, tags de mise en ligne `vX.Y.Z` sur `main`. Correctif en production par le skill `hotfix`, sur une branche `hotfix/*` issue de `main` (préfixe réservé à ces branches, D-14). Aucun merge commit, aucun cherry-pick. `dev` et `main` sont protégées ; le dépôt n'autorise que le squash et le fast-forward, et les scripts choisissent le style selon la base (story 0.2). Sur le miroir GitHub, la branche par défaut est `main`, `dev` est la branche de travail.

**Règle de revue.** Revue LLM obligatoire avant tout merge. **Exception documentaire** : une PR dont tous les fichiers sont sous `_bmad-output/` (artefacts de cadrage et suivi de sprint, `sprint-status.yaml` compris) n'exige qu'une CI verte, ou son substitut d'amorçage (D-2). L'exception ne couvre jamais `content/**`, `AGENTS.md`, `CLAUDE.md`, `docs/procedures/**`, `.claude/**` ni `docs/format-cas.md` ; un seul fichier hors exception rétablit la revue pour toute la PR.

**Règle d'amorçage** (AD-24, D-1). Les stories 0.1 à 0.7 se fusionnent avant que leurs propres skills et la CI existent : elles suivent la règle 11 des stories.

**Format du rapport de revue.** Un seul, celui d'AD-24 : première ligne `llm-review sha=<SHA> base=<base> model=<modèle> verdict=<pass|block>`, suivie du texte de la revue. `llm-review` l'écrit (story 0.5), `verify-and-merge-pr` le lit (story 0.7).

**Placement.** Les skills qui s'appuient sur des stories ultérieures sont placés après elles, pour qu'aucune story ne dépende d'une story suivante : le verrou « CI verte » (story 3.16) et `publish-case` (3.17) après les contrôles ; `release` (11.7), `rehearse-release` (11.8) et `hotfix` (11.12) après l'image et le déploiement.

**Stories ajoutées après la rétrospective.** La story 0.8 (durcissement de l'outillage) a été ajoutée le 15/09/2026, après la rétrospective de l'epic 0 (`_bmad-output/implementation-artifacts/epic-0-retro-2026-09-15.md`), puis coupée en deux après sa revue de spec : la story 0.9 prend la lecture commune du suivi et les tests. Les deux se font avant l'Epic 1.

### Story 0.1 : Gitea token in env and env example

En tant qu'Arnaud, mainteneur,
je veux un jeton Gitea aux portées minimales, rangé dans `.env`, et un `.env.example` qui liste les variables sans valeur,
afin que les skills appellent l'API de la forge sans qu'aucun identifiant n'entre dans le dépôt.

**Couvre :** NFR-9, NFR-11, FR-18 · AD-9, AD-12, AD-24
**Dépendances :** planification de sprint faite (`sprint-status.yaml`, règle d'amorçage)
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, première opération de l'epic : créer dans l'interface Gitea un jeton d'accès aux portées minimales (PR, fusion, commentaires) et avec une expiration ; renseigner `GITEA_URL`, `GITEA_USER` et `GITEA_TOKEN` dans `.env` à la racine, depuis son propre terminal.

**Critères d'acceptation :**

**Étant donné** `.env.example`, commité
**Quand** on le lit
**Alors** il liste, sans aucune valeur, `GITEA_URL`, `GITEA_USER`, `GITEA_TOKEN` et les sept variables `HUGO_LEGAL_*` d'AD-9.

**Étant donné** `.env` renseigné par Arnaud
**Quand** on lance `git status` puis `scripts/check-private.sh staged` après un `git add -f .env` dans un clone jetable
**Alors** `.env` n'apparaît pas comme fichier à suivre, puis le garde-fou refuse le chemin.

**Étant donné** `docs/procedures/gitea-token.md`
**Quand** on la suit
**Alors** elle décrit la création du jeton (portées, expiration, renouvellement), les trois variables de `.env`, et la règle : aucun script n'affiche ni ne demande le jeton.

- [ ] Aucune valeur de jeton, d'URL de forge ou de nom de compte n'est commitée.

**Questions à poser avant de commencer :**
- Nom de la procédure (`docs/procedures/gitea-token.md` est une proposition, aucun document ne le fixe) ?

### Story 0.2 : Main branch protections and merge styles

En tant qu'Arnaud, mainteneur,
je veux créer `main`, protéger `dev` et `main` et imposer les styles de fusion du flux linéaire,
afin qu'aucun merge commit ni push direct n'entre sur les branches publiées.

**Couvre :** FR-28, FR-30 (flux documenté par le README-cas), NFR-7 · AD-24
**Dépendances :** aucune
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, administration Gitea : création de `main` depuis `dev` ; protection de `dev` et `main` ; `main` sans aucun push ni force-push, pour aucun compte ; `dev` avec le compte d'Arnaud dans la liste de push (Gitea exige le droit de push pour autoriser un force-push) et seul dans la liste de force-push (exception tracée, utilisée par `hotfix` après son approbation explicite) ; styles de fusion du dépôt limités au squash et au fast-forward seulement, squash par défaut, mise à jour des PR par rebase seulement ; aucun style « merge commit » (D-10). Gitea fixe les styles par dépôt et non par branche : le squash vers `dev` et le fast-forward vers `main` sont imposés par les scripts (AD-24).

**Critères d'acceptation :**

**Étant donné** la configuration appliquée
**Quand** Arnaud tente un push direct, puis un force-push, sur `main`
**Alors** les deux sont refusés.

**Étant donné** un compte autre que celui d'Arnaud, s'il en existe un
**Quand** il tente un push direct sur `dev`
**Alors** il est refusé ; pour le compte d'Arnaud, le push direct sur `dev` reste techniquement possible et n'est interdit que par la procédure (D-10).

**Étant donné** une PR de test
**Quand** elle est fusionnée par l'API avec le style `merge`, `rebase` ou `rebase-merge`
**Alors** la fusion est refusée : seuls `squash` et `fast-forward-only` sont autorisés dans le dépôt.

**Étant donné** la PR de cette story vers `dev`
**Quand** elle est fusionnée
**Alors** elle l'est en squash, et l'historique de `dev` reste linéaire.

**Étant donné** une PR de test vers une base protégée comme `main` (branches temporaires)
**Quand** la base est un ancêtre de la tête, puis quand la base a divergé
**Alors** la fusion se fait en fast-forward, puis elle est impossible.

**Étant donné** un compte autre que celui d'Arnaud, s'il en existe un
**Quand** il tente un force-push sur `dev`
**Alors** il est refusé.

- [ ] Les réglages sont notés dans `docs/procedures/gitea-branches.md`, sans nom d'hôte, avec la limite du push direct d'Arnaud sur `dev`.

**Questions à poser avant de commencer :**
- La version de Gitea en service propose-t-elle le style de fusion « fast-forward only » pour les PR ? À constater avant la configuration.

### Story 0.3 : Check-private skill

En tant qu'Arnaud ou agent de développement,
je veux une procédure unique pour lancer le garde-fou et l'audit complet de l'historique,
afin de ne jamais pousser, activer le miroir ou envoyer un diff à un reviewer sans audit.

**Couvre :** FR-28, NFR-9, SM-5 · AD-12, AD-24 · C1
**Dépendances :** aucune
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `.claude/skills/check-private/SKILL.md`
**Quand** un agent le lit
**Alors** il y trouve en quelques lignes quand l'utiliser (avant tout push, avant l'activation du miroir, avant l'envoi à un reviewer) et le renvoi à `docs/procedures/check-private.md`.

**Étant donné** `docs/procedures/check-private.md`
**Quand** on la suit
**Alors** elle décrit les modes `staged`, `history` et `pre-receive` de `scripts/check-private.sh` (script existant, non dupliqué), l'activation du hook local (`git config core.hooksPath .githooks`) et l'audit complet avec la liste des motifs, sans jamais en recopier le contenu.

- [ ] Le skill n'ajoute pas de second script.
- [ ] Une alerte n'affiche que l'emplacement (commit, fichier, ligne) et le numéro de ligne du motif, jamais le contenu ni le motif ; vérifié sur les trois modes avec des motifs factices, y compris des noms de fichier contenant deux-points, tabulation ou saut de ligne.
- [ ] Chaque arbre vérifié est cherché en un seul passage avec tous les motifs ; le détail motif par motif n'a lieu qu'en cas de résultat, et une erreur de recherche fait échouer le garde-fou.
- [ ] La procédure impose `PRIVATE_PATTERNS_FILE` pour auditer une copie sans `docs/private/`.
- [ ] `.agents/skills/check-private` et `.agent/skills/check-private` sont des liens symboliques relatifs vers `.claude/skills/check-private/`.

### Story 0.4 : Create-pull-request skill

En tant qu'agent de développement,
je veux ouvrir une PR sur la forge par l'API REST de Gitea, sans exposer de secret ni abîmer le corps de la PR,
afin que chaque story arrive en revue de la même façon.

**Couvre :** NFR-7, NFR-11 · AD-24
**Dépendances :** 0.1, 0.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, constater que `jq` est installé sur le poste de développement (`command -v jq` ; présent, constat du 13/09/2026) ; l'architecture ne retient pas python3 pour ces scripts (AD-24).

**Critères d'acceptation :**

**Étant donné** `scripts/create-pull-request.sh`
**Quand** il s'exécute
**Alors** il charge `GITEA_URL`, `GITEA_USER` et `GITEA_TOKEN` depuis `.env`, sans jamais en afficher la valeur.

**Étant donné** l'absence de `.env` ou d'une des trois variables
**Quand** il s'exécute
**Alors** il échoue avec un message qui renvoie à la procédure de la story 0.1, sans demander le jeton.

**Étant donné** un corps de PR contenant guillemets, retours à la ligne et accents
**Quand** la PR est créée
**Alors** le corps est toujours écrit dans un fichier, passé par `jq --rawfile` puis envoyé par `curl --data @`, et arrive intact.

**Étant donné** un dépôt dont le nom ne correspond pas au nom canonique
**Quand** le script s'exécute
**Alors** il échoue avant tout appel d'écriture.

- [ ] Une PR vers `main` n'est pas créée par ce skill, et une branche `hotfix/*` est refusée : il renvoie vers `release` ou `hotfix`.
- [ ] La base se déduit du préfixe : `feat/*`, `fix/*`, `chore/*` et `docs/*` → `dev` ; tout autre préfixe est refusé.
- [ ] Le nom canonique `Eleyone/eleyone.fr` est une constante du script, comparée au dépôt distant `origin`.
- [ ] Le titre est obligatoire ; le corps est lu par défaut dans `.pr-body.md` à la racine (ignoré par git, réutilisé d'une PR à l'autre), ou dans `--body-file`.
- [ ] Refus avant tout appel d'écriture : modifications en attente, branche non poussée au même commit, alerte de `check-private.sh history` sur la branche (fichier de motifs exigé), motif privé dans le titre ou le corps, jeton d'un autre compte que `GITEA_USER`, PR déjà ouverte pour la branche (dont le numéro est affiché).
- [ ] La sortie donne le numéro de la PR, jamais son adresse ; le corps publié est relu et comparé octet par octet au fichier.
- [ ] La PR de cette story est ouverte par le script lui-même, avec un corps contenant guillemets, retours à la ligne et accents : preuve de fonctionnement.
- [ ] Sans `jq` dans le `PATH`, le script échoue avant tout appel, avec un message qui indique l'installation (`sudo apt install jq`).

**Questions à poser avant de commencer :**
- Où est déclaré le nom canonique du dépôt (constante du script, variable de `.env`) ? Réponse d'Arnaud (14/09/2026) : constante du script.

### Story 0.5 : LLM-review skill with cross-vendor review

En tant qu'Arnaud, mainteneur,
je veux qu'un LLM d'un autre fournisseur que l'auteur relise la spec de chaque story avant son implémentation, puis le diff de chaque PR avec un verdict explicite publié sur la PR,
afin qu'aucune spec ni aucun merge ne repose sur la seule relecture du modèle qui a écrit le code.

**Couvre :** NFR-7, NFR-9, NFR-11 · AD-12, AD-24
**Dépendances :** 0.3, 0.4
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, `agy` authentifié sur le poste : `agy models` répond (prérequis du poste d'AD-24).

**Décisions (Arnaud, 14/09/2026, après la revue de spec) :**
- deux usages du même script : `scripts/llm-review.sh --story <n.m>` (revue de spec) et `scripts/llm-review.sh <numéro de PR>` (revue du code) ;
- relecteurs en constantes du script, sans option pour en changer : auteur Claude (défaut) → `gemini-3.1-pro-high` ; `AUTHOR_LLM=gemini` → `claude-opus-4-6-thinking` ;
- c'est le relecteur qui applique le skill de revue BMAD `bmad-review`, lu comme fichier dans la copie isolée ; l'auteur ne le lance jamais à sa place ; `bmad-code-review`, qui attend des réponses, est écarté ;
- angles : revue de spec, adverse, structure et prose ; revue du code, edge-case-hunter et verification-gap, plus la couche propre au projet (critères d'acceptation, données privées et secrets, cohérence entre skill, procédure et script, `AGENTS.md` et AD) ; une PR sans code garde la couche propre au projet et prend les angles structure et prose ;
- consignes versionnées : `scripts/llm-review-prompt.md` (code) et `scripts/llm-review-spec-prompt.md` (spec) ; `--context <fichier>` y ajoute des précisions ;
- classement : est bloquant ce qui casse un critère d'acceptation, fait fuiter une donnée privée ou un secret, ou laisse passer une erreur en silence ; le reste est non bloquant ;
- lecture de `.env` et accès à l'API Gitea mis en commun dans `scripts/lib/gitea.sh`, utilisé aussi par `create-pull-request.sh` ; `.env` n'est lu que juste avant le premier appel à l'API, et jamais par la revue de spec ;
- trace de chaque revue dans le fichier de story `_bmad-output/implementation-artifacts/<clé>.md` ; constats reportés dans `deferred-work.md`.

**Critères d'acceptation :**

**Étant donné** `scripts/llm-review.sh`
**Quand** il démarre
**Alors** il coupe la trace du shell avant toute lecture de `.env`, échoue sans `jq` en indiquant `sudo apt install jq` et refuse une valeur d'`AUTHOR_LLM` autre que `claude` ou `gemini`
**Et** il refuse tout appel qui ne donne pas exactement un des deux usages : `--story <n.m>` ou un numéro de PR.

**Étant donné** un numéro de PR
**Quand** le script prépare la revue du code
**Alors** il charge `.env` par `scripts/lib/gitea.sh` sans afficher de valeur (renvoi à la procédure de la story 0.1 si une variable manque), lit par l'API la base, la branche et le SHA de tête, refuse une PR fermée, récupère ce SHA depuis la forge et crée la copie relue à ce SHA, jamais depuis l'arbre local
**Et** le diff relu est `git diff <base>...<SHA>` : la branche entière.

**Étant donné** `--story <n.m>`
**Quand** le script prépare la revue de spec
**Alors** il extrait le texte de la story d'`epics.md` à la tête de `dev` lue sur la forge ; une story introuvable le fait échouer.

**Étant donné** le contenu à relire
**Quand** le script crée la copie isolée
**Alors** c'est un worktree git temporaire **hors du dépôt**, qui ne contient que les fichiers suivis : ni `.env`, ni `docs/private/`, ni `.pr-body.md`
**Et** `scripts/check-private.sh history` passe sur la plage relue avec la liste des motifs **avant** tout envoi ; sans fichier de motifs ou en cas d'alerte, rien n'est envoyé
**Et** le script écrit en tête du fichier relu un jeton de lecture aléatoire.

**Étant donné** l'appel au relecteur
**Quand** la revue s'exécute
**Alors** le script lance `agy --mode plan` avec le modèle en constante, la consigne versionnée complétée du chemin absolu de la copie, et la copie passée par `--add-dir` (sans cela, le relecteur n'a trouvé aucun fichier : constat de la story 0.2)
**Et** la consigne demande d'appliquer `bmad-review` avec les angles de l'usage, de recopier le jeton, de classer chaque constat, et de terminer par la ligne `VERDICT:` (revue du code) ou par une section « À trancher » (revue de spec)
**Et** un délai dépassé ou un échec d'`agy` fait échouer le script sans rien publier.

**Étant donné** la réponse du relecteur
**Quand** le script la contrôle
**Alors** le rapport doit citer le jeton de lecture : sinon ce n'est pas une revue, et le script échoue sans rien publier
**Et** en revue du code, la dernière ligne non vide du rapport doit être `VERDICT: NON BLOQUANT — …` (`pass`) ou `VERDICT: BLOQUANT — …` (`block`) ; toute autre forme fait échouer le script sans rien publier, et un verdict `block` se publie normalement
**Et** le script ne retient le rapport qu'à partir de la ligne du jeton, et écarte ce qu'`agy` écrit avant
**Et** il liste, dans sa sortie et dans ce qu'il écrit, tout fichier que le relecteur a créé ou modifié dans la copie : `agy --mode plan` n'est pas en lecture seule (constat de la story 0.3).

**Étant donné** une revue du code contrôlée
**Quand** le script la publie
**Alors** il poste en commentaire de la PR le rapport, précédé d'une première ligne `llm-review sha=<SHA de tête> base=<base> model=<modèle> verdict=<pass|block>` (format d'AD-24) ; une réponse autre que HTTP 201 le fait échouer
**Et** il ajoute à la fin de la section « Revue du code » du fichier de story le SHA, le modèle, le verdict et les constats, sans modifier ni supprimer de ligne existante ; l'auteur ajoute ensuite, sous le rapport, sa décision pour chaque constat ; le script ne commite rien.

**Étant donné** une revue de spec contrôlée
**Quand** le script termine
**Alors** il affiche le rapport et l'ajoute à la section « Revue de spec » du fichier de story, qu'il crée s'il n'existe pas, avec l'en-tête `Status:` du suivi de sprint ; rien n'est publié sur la forge
**Et** l'auteur trie chaque constat (corrigé dans la story, question tranchée par Arnaud, écarté avec sa raison) avant de reformuler la story et de poser ses questions.

**Étant donné** la fin du script, en succès, en échec ou sur interruption
**Quand** il se termine
**Alors** la copie isolée et les fichiers temporaires sont supprimés.

- [ ] L'identifiant exact de chaque modèle relecteur (sortie de `agy models`) est consigné dans `docs/procedures/llm-review.md`.
- [ ] Les refus de lecture de `.env` configurés pour les agents (`.claude/settings.json`, réglage d'Antigravity sur le poste, `.antigravityignore`) ne sont qu'une défense en profondeur : ils ne remplacent pas la copie isolée.
- [ ] Preuve : la PR de cette story est relue par le script lui-même, puis une seconde fois avec `AUTHOR_LLM=gemini` ; la revue de spec de la story 0.6 est la première faite par `--story`.
- [ ] Les stories 0.1 à 0.4 ont un fichier de story d'historique, où leur revue de spec est notée « non faite, l'outil n'existait pas encore ».

### Story 0.6 : Sprint-consistency skill

En tant qu'Arnaud, mainteneur,
je veux vérifier que le suivi de sprint et les fichiers de story disent la même chose,
afin qu'aucune PR ne soit fusionnée sur une story mal suivie.

**Couvre :** NFR-7 · AD-24
**Dépendances :** 0.2, 0.5 (fichiers de story)
**Bloquée par :** —
**Prérequis de contenu :** `sprint-status.yaml` et fichiers de story dans `_bmad-output/implementation-artifacts/` (stories 0.1 à 0.5).
**Opération manuelle (Arnaud) :** non

**Décisions (Arnaud, 14/09/2026, après la revue de spec) :**
- trois niveaux, visibles dans tous les outils : `.claude/skills/sprint-consistency/SKILL.md` et ses liens, `docs/procedures/sprint-consistency.md`, `scripts/sprint-consistency.sh`, en bash seul, sans Python ni outil YAML ;
- interface : sans option, contrôle global de l'arbre de travail ; `--merge <n.m>` exige en plus la story à `done` dans le suivi et dans son fichier ; `--rev <commit>` lit le suivi et les fichiers de story dans ce commit ; le lien entre une PR et sa story (numéro tiré du nom de la branche) relève de `verify-and-merge-pr` (story 0.7) ;
- statuts d'epic vérifiés d'après leurs stories : `backlog` si aucune n'a commencé (`backlog` ou `ready-for-dev`), `done` si toutes sont à `done`, `in-progress` sinon ; les rétrospectives ne sont pas vérifiées ;
- tolérances : une story en `backlog` peut avoir un fichier de story s'il porte `Status: backlog` ; seule la première ligne `Status:` du fichier compte ; une ligne absente, mal écrite ou hors vocabulaire est un écart ;
- statuts seulement en v1, pas les branches (D-17).

**Critères d'acceptation :**

**Étant donné** `scripts/sprint-consistency.sh` sans option
**Quand** il s'exécute
**Alors** il lit la section `development_status` de `_bmad-output/implementation-artifacts/sprint-status.yaml` et les fichiers de story du même dossier (`<clé>.md`)
**Et** il signale comme écart : une story hors `backlog` sans fichier de story ; un fichier de story sans entrée dans le suivi ; un fichier dont la première ligne `Status:` manque, est mal écrite, porte une valeur hors vocabulaire ou diffère du suivi ; un statut de story ou d'epic hors vocabulaire ; un epic dont le statut ne correspond pas à ses stories, ou sans aucune story ; des stories dont l'epic n'a pas de ligne dans le suivi ; une clé non reconnue
**Et** il liste tous les écarts et sort avec le code 1 s'il y en a au moins un ; sinon il annonce la cohérence et sort avec le code 0
**Et** une story `in-progress` ou `review` n'est jamais un écart en soi : le contrôle passe pendant tout le développement.

**Étant donné** l'absence de `sprint-status.yaml`, ou une section `development_status` vide
**Quand** le script s'exécute
**Alors** il le dit explicitement et sort en échec (code 2), sans conclure à la cohérence ; de même si la liste des fichiers de story ne peut pas être lue.

**Étant donné** `--merge <n.m>`
**Quand** le script s'exécute
**Alors** en plus du contrôle global, la story `n.m` doit exister dans le suivi sous une seule clé, y être à `done` et avoir son fichier de story à `done` ; sinon c'est un écart, et la fusion est refusée.

**Étant donné** `--rev <commit>`
**Quand** le script s'exécute
**Alors** il lit le suivi et les fichiers de story dans ce commit, pas dans l'arbre de travail ; un commit introuvable le fait échouer (code 2).

- [ ] Testé sur le dépôt réel (cohérent) et sur une copie jetable présentant chaque écart et chaque tolérance.

### Story 0.7 : Verify-and-merge-pr skill

En tant qu'Arnaud, mainteneur,
je veux auditer une PR par défaut et ne la fusionner qu'avec `--merge`, seulement si tous les verrous passent,
afin qu'aucun merge ne contourne la revue, le garde-fou ou le flux linéaire.

**Couvre :** FR-28, NFR-9, NFR-11 · AD-12, AD-24
**Dépendances :** 0.5, 0.6
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non (prérequis : `jq`, constaté à la story 0.4)

**Décisions (Arnaud, 15/09/2026, après la revue de spec) :**
- trois niveaux, visibles dans tous les outils : `.claude/skills/verify-and-merge-pr/SKILL.md` et ses liens, `docs/procedures/verify-and-merge-pr.md`, `scripts/verify-and-merge-pr.sh`, qui s'appuie sur `scripts/lib/gitea.sh`, `check-private.sh` et `sprint-consistency.sh` ;
- le script lit les objets git et l'API, et n'écrit jamais dans l'arbre de travail ;
- PR fusionnable : ouverte, pas en brouillon, `mergeable`, pas déjà fusionnée, base `dev` ;
- rapport de revue retenu : le dernier commentaire `llm-review` publié par le compte `GITEA_USER`, sur le SHA de tête (ou sur son parent pour le commit de statut) et la base de la PR ; un `block` plus récent l'emporte ;
- branche sans numéro de story : le verrou de suivi devient le contrôle global de `sprint-consistency.sh` ;
- règle d'amorçage : le script lance lui-même le substitut de la CI ;
- message du commit de fusion : titre de la PR suivi de « (#N) », sujets des commits de la branche et lignes `Co-Authored-By` sans doublon.

**Critères d'acceptation :**

**Étant donné** `scripts/verify-and-merge-pr.sh <PR>` sans option
**Quand** il s'exécute
**Alors** il affiche l'état de chaque verrou (`passe`, `absent` ou `bloque`) sans rien fusionner, et sort avec le code 0 si tous passent, 1 si au moins un bloque, 2 si l'audit est impossible.

**Étant donné** les verrous d'une PR
**Quand** le script les évalue
**Alors** il vérifie, dans l'ordre :
- **PR fusionnable** : ouverte, pas en brouillon, `mergeable`, pas déjà fusionnée ; base `dev` ; une base `main` est refusée avec un renvoi vers `release` ou `hotfix`, toute autre base est refusée ;
- **revue LLM** : le dernier rapport `llm-review` de `GITEA_USER` (format d'AD-24) porte `sha=` égal au SHA de tête et `verdict=pass`, ou `sha=` égal à son parent et `verdict=pass` avec un commit de tête conforme à la règle du commit de statut ; `base=` égal à la base de la PR ;
- **garde-fou** : `scripts/check-private.sh history base..tête`, avec la liste des motifs, sur les commits récupérés depuis la forge ;
- **CI** : état combiné de la forge sur le SHA de tête ;
- **suivi de sprint** : `scripts/sprint-consistency.sh --merge <n.m> --rev <SHA de tête>`, numéro de story tiré du nom de la branche ; contrôle global `--rev <SHA de tête>` pour une branche sans numéro.

**Étant donné** `--merge`
**Quand** un verrou bloque
**Alors** rien n'est fusionné ; sinon, après avoir vérifié que la tête n'a pas bougé et que le message ne contient aucun motif privé, le script fusionne en squash sur le SHA de tête exact (`head_commit_id`), fait supprimer la branche, puis confirme la fusion.

**Étant donné** une PR dont tous les fichiers sont sous `_bmad-output/`, `sprint-status.yaml` compris (D-2)
**Quand** le script évalue la revue
**Alors** la revue LLM n'est pas exigée ; garde-fou, CI et suivi le restent ; un seul fichier hors de `_bmad-output/` (dont `content/**`, `AGENTS.md`, `CLAUDE.md`, `docs/procedures/**`, `.claude/**`, `docs/format-cas.md`) rétablit la revue.

**Étant donné** `.gitea/workflows/checks.yaml` absent de la branche de base
**Quand** la CI est absente sur la tête
**Alors** le verrou s'affiche `absent`, jamais `passe`, et le script lance le substitut d'amorçage (D-1) : le garde-fou, puis `scripts/check.sh` sur la tête dès qu'il existe (story 3.2) ; un substitut en échec bloque ; dès que ce fichier existe sur la base, une CI absente bloque (story 3.16).

**Étant donné** une PR qui ajoute `sprint-status.yaml` à une base qui ne l'a pas
**Quand** le verrou de suivi de sprint est évalué
**Alors** c'est la seule PR admise sans ce verrou (règle d'amorçage).

**Étant donné** un rapport `llm-review` à `verdict=pass` sur le parent du SHA de tête
**Quand** le commit de tête, seul après le SHA relu, ne modifie que `sprint-status.yaml` (la ligne de la story `review` → `done`, `last_updated` et, si la story clôt son epic, la ligne de l'epic → `done`) et l'en-tête `Status:` du fichier de story (`review` → `done`), et n'ajoute par ailleurs que des lignes au fichier de story et à `deferred-work.md`
**Alors** le verrou de revue passe ; tout autre changement, contrôlé ligne par ligne dans `git diff`, ou plus d'un commit après le SHA relu, exige une nouvelle revue.

- [ ] Aucune option `--force` ; `force_merge` et `merge_when_checks_succeed` ne sont jamais envoyés.
- [ ] Sans `jq` dans le `PATH`, le script échoue avant tout appel, avec un message qui indique l'installation (`sudo apt install jq`).
- [ ] Le script charge `.env` par `scripts/lib/gitea.sh` sans afficher de valeur ; sans variable Gitea, il échoue en renvoyant à la procédure de la story 0.1.
- [ ] Preuve : la PR de cette story est auditée puis fusionnée par le script lui-même, après l'autorisation d'Arnaud.

### Story 0.8 : Dev tooling hardening

**Ajoutée après la rétrospective de l'epic 0** (décision d'Arnaud, 15/09/2026), **réécrite et coupée en deux après sa revue de spec** : elle reprend les correctifs de `_bmad-output/implementation-artifacts/epic-0-retro-2026-09-15.md`, section « Constats » ; la lecture commune du suivi et les tests forment la story 0.9. Chaque critère cite le code du constat qu'il ferme. Les constats documentaires de la rétrospective restent des actions traitées au fil des stories qui touchent leurs fichiers.

En tant qu'Arnaud, mainteneur,
je veux que les scripts de l'epic 0 tiennent leurs garanties dans les cas limites relevés par la rétrospective,
afin qu'aucun secret ne soit trouvable par le relecteur externe et qu'aucun verrou ne passe, ne boucle ou ne se trompe en silence.

**Couvre :** FR-28, NFR-9, NFR-11 · AD-12, AD-24
**Dépendances :** 0.1 à 0.7, rétrospective de l'epic 0
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, préparation seulement : poser, dans un dossier jetable hors du dépôt de travail, un faux `.env` qui ne contient qu'une valeur témoin, sans aucun secret réel (la règle `deny` du poste interdit à l'agent d'écrire un `.env`). L'agent lance l'essai et consigne son résultat.

**Décisions (Arnaud, 15/09/2026, après la revue de spec) :**
- la copie de revue devient un export du SHA relu, et non plus un worktree git : `AGENTS.md` (point 2) et AD-24 sont alignés dans cette story ;
- les rapports `llm-review` sont lus par la timeline de la PR, qui pagine réellement, et non plus par la liste des commentaires, dont la forge ignore `limit` et `page` ;
- une story ne peut pas être livrée en plusieurs PR (`verify-and-merge-pr --merge <n.m>` exige la story à `done`) : la lecture commune du suivi et les tests forment la story 0.9.

**Critères d'acceptation :**

**Étant donné** la copie relue par `scripts/llm-review.sh`
**Quand** le relecteur est lancé
**Alors** la copie est un export du SHA relu (`git archive`), sans fichier ni dossier `.git`, qui donnerait le chemin du dépôt de travail ; elle ne contient ni `.env`, ni `docs/private/`, ni `.pr-body.md` ; un manifeste `sha256sum` de tous ses fichiers, fichiers cachés compris, est pris avant la revue et comparé après, et le script nomme les fichiers ajoutés, modifiés ou supprimés par le relecteur (S11).

**Étant donné** un dossier jetable où Arnaud a posé un faux `.env` à valeur témoin
**Quand** l'agent y lance le relecteur comme le fait `llm-review.sh` (`agy --mode plan`, `--dangerously-skip-permissions`), une fois en lui demandant de lire ce `.env`, une fois en lui demandant d'y chercher la valeur par une commande absente de la liste `deny` du poste (par exemple `grep`)
**Alors** le fichier de story consigne, pour chaque essai, si la valeur témoin apparaît dans la réponse ; si elle apparaît, Arnaud décide de la protection avant que la story passe à `done` (S11, `ARCHITECTURE-SPINE.md:508`).

**Étant donné** la recherche du rapport `llm-review` d'une PR par `scripts/verify-and-merge-pr.sh`
**Quand** le script lit les commentaires de la PR
**Alors** il les lit par `GET /repos/{owner}/{repo}/issues/{index}/timeline`, par pages de la taille lue dans `GET /settings/api` (`max_response_items`), s'arrête sur la première page incomplète, échoue en code 2 sur une page illisible ou au-delà d'un nombre maximal de pages, et ne retient que les éléments de type `comment` ; la procédure consigne que la liste des commentaires ignore `limit` et `page` (D1, P3).

**Étant donné** un fichier de motifs qui existe mais ne contient que des commentaires ou des lignes blanches (espaces, tabulations, retours chariot)
**Quand** `create-pull-request.sh`, `llm-review.sh` ou `verify-and-merge-pr.sh` s'exécute
**Alors** il refuse comme pour un fichier absent ; et `check-private.sh`, lancé seul, annonce « chemins seulement » comme sans fichier (D2).

**Étant donné** `scripts/check-private.sh` lancé depuis un sous-dossier du dépôt
**Quand** il audite l'index, un commit ou l'historique
**Alors** il audite tout le dépôt depuis sa racine git (`git rev-parse --show-toplevel`), avec le même résultat que lancé depuis la racine (D3).

**Étant donné** une PR dont le titre contient un antislash, un guillemet, un `$` ou un accent grave
**Quand** `verify-and-merge-pr.sh --merge` construit le titre du commit de fusion
**Alors** ce titre reprend celui de la PR octet pour octet, suivi de « (#N) », sans qu'aucun caractère soit interprété par le shell (D5).

**Étant donné** `.gitea/workflows/checks.yaml` absent de la base et des statuts de CI présents sur la tête
**Quand** leur état combiné est `pending`
**Alors** le verrou CI bloque (« en cours ») au lieu de s'afficher `absent` ; un état `failure` bloque comme aujourd'hui ; sans aucun statut sur la tête, la règle d'amorçage s'applique inchangée (S5).

**Étant donné** `docs/procedures/verify-and-merge-pr.md`, `docs/procedures/llm-review.md`, `AGENTS.md` et AD-24
**Quand** on les lit
**Alors** la procédure `verify-and-merge-pr` dit qu'une PR peut apparaître « non fusionnable » juste après un push, le temps que la forge recalcule, et qu'il suffit de relancer l'audit (P3) ; la procédure `llm-review` décrit la copie exportée, le manifeste, le résultat de l'essai du faux `.env` et le cheminement des rapports ajoutés au fichier de story jusqu'au commit `done`, y compris après un verdict `block` (P5) ; `AGENTS.md` et AD-24 décrivent la copie exportée au lieu du worktree ; les SKILL.md des scripts modifiés concordent.

- [ ] Le fichier de story renvoie à la section « Constats » de la rétrospective et consigne, pour chaque code (S11, D1, D2, D3, D5, S5, P3, P5), le commit ou l'essai qui le ferme.
- [ ] Si les ajouts sous `scripts/` dépassent ceux de la story 0.7 (312 lignes), la découpe est revue avec Arnaud avant la revue du code (action 10 de la rétrospective).

**Hors périmètre :** D6 (codes de sortie hétérogènes), par décision d'Arnaud à la rétrospective ; lecture commune du suivi (D4, D7) et tests (P1), qui forment la story 0.9.

### Story 0.9 : Shared sprint reading and script tests

**Ajoutée après la revue de spec de la story 0.8** (décision d'Arnaud, 15/09/2026), qui a coupé la story de durcissement en deux, **puis réécrite après sa propre revue de spec**. Elle reprend les constats D4, D7 et P1 de `_bmad-output/implementation-artifacts/epic-0-retro-2026-09-15.md`, section « Constats ».

En tant qu'Arnaud, mainteneur,
je veux une seule lecture du suivi de sprint et des tests bash rejouables hors ligne pour les scripts de l'epic 0, sur le poste et en CI,
afin que les pièges déjà rencontrés ne reviennent pas d'une story à l'autre et que les copies d'une même logique ne divergent plus.

**Couvre :** FR-28, NFR-7 · AD-24
**Dépendances :** 0.8
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Décisions (Arnaud, 15/09/2026, après la revue de spec) :**
- les tests tournent sur le poste de développement et en CI : ils ne dépendent que de `bash`, `git`, `jq`, `grep` GNU et des outils de base, disponibles dans `CHECK_IMAGE` ; leur lancement par le job de contrôle partagé est ajouté à la story 3.12 ;
- deux fichiers de bibliothèque, pour la lisibilité et les tests : `scripts/lib/sprint.sh` (lecture du suivi, sans `jq`) et `scripts/lib/merge-gates.sh` (décisions de `verify-and-merge-pr`) ;
- les fonctions de lecture du suivi répondent par leur code de retour, comme beaucoup de commandes : `0` trouvée, `1` absente, `2` illisible ou ambiguë, et rien sur la sortie standard en cas d'erreur ;
- le repère de taille de l'action 10 de la rétrospective ne compte que le code de production (`scripts/*.sh`, `scripts/lib/`) : les tests et leurs fixtures sont indissociables de ce qu'ils testent et ne comptent pas.

**Critères d'acceptation :**

**Étant donné** `scripts/lib/sprint.sh`
**Quand** `llm-review.sh`, `verify-and-merge-pr.sh` ou `sprint-consistency.sh` lit une clé ou un statut de story dans le texte de `sprint-status.yaml`, pris dans l'arbre de travail ou dans un commit
**Alors** il passe par les fonctions de ce fichier, sans `jq`, limitées à la section `development_status`, en gardant les tolérances actuelles de `sprint-consistency.sh` (indentation, guillemets, commentaire en fin de ligne) ; une fonction écrit la valeur trouvée et sort en `0`, sort en `1` sans rien écrire si la story est absente, et en `2` sans rien écrire si plusieurs clés correspondent ou si la valeur n'est pas un statut simple sur la ligne de la clé (par exemple un bloc sur plusieurs lignes) ; chaque script traduit ces codes en écart ou en refus (D4).

**Étant donné** `scripts/lib/merge-gates.sh`
**Quand** `verify-and-merge-pr.sh` décide d'un verrou
**Alors** la décision passe par des fonctions qui lisent des fichiers ou des commits, sans appeler la forge : lecture des rapports dans une page de timeline, rapport `llm-review` retenu pour un SHA et une base, règle du commit de statut, verrou CI, titre du commit de fusion ; les appels à la forge restent dans le script ; la lecture paginée de la timeline reçoit le nom de la fonction qui écrit une page dans un fichier, que le script fait appeler la forge et que les tests font lire des fixtures ; aucune variable d'environnement ne remplace l'appel à la forge.

**Étant donné** les logiques recopiées relevées en D7
**Quand** la story est terminée
**Alors** deux sont mises en commun, et deux seulement : le numéro de story tiré du nom de branche (`llm-review.sh`, `verify-and-merge-pr.sh`) et la lecture de la clé et du statut d'une story (D4) ; les autres copies restent en place (D7).

**Étant donné** `scripts/tests/run.sh`
**Quand** on le lance depuis la racine du dépôt, sur le poste ou dans un conteneur `CHECK_IMAGE`
**Alors** des tests en bash, sans framework, sans réseau, sans `.env` ni `docs/private/`, à partir de fixtures versionnées sous `scripts/tests/` et de dépôts git de test créés dans un dossier temporaire, rejouent :
- D2 : fichier de motifs sans motif, avec lignes blanches, illisible ; D3 : audit depuis un sous-dossier ;
- D4 : clé présente, absente, en double, valeur entre guillemets ou suivie d'un commentaire, valeur sur plusieurs lignes ;
- D5 : titre avec antislash, guillemet, `$` et accent grave ;
- le verrou CI (S5) : vert, en cours, échec, erreur, absent avec et sans `checks.yaml` sur la base ;
- la règle du commit de statut : commit admis, ligne supprimée, autre fichier modifié, deux commits après le SHA relu ;
- le rapport retenu : `block` plus récent qu'un `pass`, autre base, autre SHA, ligne mal formée ;
- la pagination de la timeline : pages pleines, page incomplète, page `null` finale, plafond de pages ;

et il s'arrête en code non nul au premier échec en nommant le cas (P1).

**Étant donné** `docs/procedures/shell-scripts.md`
**Quand** un agent ou Arnaud écrit ou modifie un script du poste ou de la CI
**Alors** sa section « Pièges connus » liste les pièges déjà rencontrés, chacun avec la story qui l'a trouvé : substitution de processus `< <(…)` qui masque un échec, bloc `{ … } || die` qui suspend `set -e`, apostrophe dans `"${…:+…}"`, regex construite depuis une variable, `jq @tsv` qui double l'antislash, pagination supposée de l'API de la forge et réponse `null` au-delà de la dernière page ; elle demande de lancer `scripts/tests/run.sh` avant toute PR qui touche `scripts/` et d'ajouter un cas pour tout nouveau piège (P1).

- [ ] L'entrée « aucun test automatisé des scripts shell » de `deferred-work.md` est close par une ligne ajoutée qui renvoie à cette story ; aucune entrée existante n'est modifiée.
- [ ] `scripts/tests/run.sh` passe sur la tête de la PR, sur le poste et dans un conteneur `alpine:3.24` avec `bash`, `grep` GNU, `git` et `jq` ; tant que la CI n'existe pas, le résultat est noté dans la PR.
- [ ] Le fichier de story consigne, pour D4, D7 et P1, le commit qui les ferme.

**Hors périmètre :** D6 (codes de sortie hétérogènes) ; ShellCheck (absent du poste, aucun nouvel outil).

## Epic 1 : Garde-fou public/privé avant tout miroir (WS-0)

Arnaud peut publier le dépôt sur GitHub sans qu'aucun chemin ni motif privé y arrive. La forge principale refuse ces contenus côté serveur, l'historique complet est audité avec la liste des motifs, et le miroir n'est activé qu'ensuite (ordre imposé par AD-12).

### Story 1.1 : Pre-receive guard fails without pattern list

En tant qu'Arnaud, mainteneur,
je veux que `scripts/check-private.sh pre-receive` refuse tout push quand la liste des motifs est absente ou vide,
afin qu'un hook serveur mal installé ne laisse jamais passer un motif privé.

**Couvre :** FR-28, NFR-9 · AD-12 · C2 (préparation)
**Dépendances :** aucune
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Décisions (Arnaud, 15/09/2026, après la revue de spec) :**
- en mode `pre-receive`, une liste présente mais sans aucun motif (commentaires ou lignes blanches) est refusée comme une liste absente ; les modes `staged` et `history` gardent leur repli sur les chemins, avec l'avertissement ;
- en mode `pre-receive`, `PRIVATE_PATTERNS_FILE` est obligatoire : un dépôt nu n'a pas de racine de travail, donc pas de chemin par défaut ; le hook installé par la story 1.2 la définit (procédure « hook pre-receive », étape 2) ;
- les tests sont des cas de `scripts/tests/test-check-private.sh`, sur un dépôt nu jetable muni d'un vrai hook `pre-receive`, rejoués sur le poste, dans `CHECK_IMAGE` et en CI.

**Critères d'acceptation :**

**Étant donné** un dépôt nu jetable, hors du dépôt du site, dont le hook `pre-receive` appelle le script sans `PRIVATE_PATTERNS_FILE`, avec une liste absente, ou avec une liste qui ne contient que des commentaires ou des lignes blanches
**Quand** un push quelconque y arrive
**Alors** le script sort avec un code non nul et écrit sur la sortie d'erreur, que git retransmet à l'auteur du push, un message qui nomme la cause (variable absente, liste absente, liste sans motif), sans afficher de motif
**Et** le push est refusé : la branche n'existe pas sur le dépôt nu.

**Étant donné** le même dépôt nu, avec une liste de test contenant un motif factice
**Quand** un push tente d'ajouter un fichier sous `docs/private/` ou `docs/context/`, un fichier `.env` à la racine ou dans un sous-dossier, un fichier `assets/cv/*.pdf`, un fichier texte qui contient le motif factice, ou de renommer un fichier existant vers `docs/private/`
**Alors** chaque push est refusé, avec le commit et le chemin, sans afficher le motif ni le contenu.

**Étant donné** le même dépôt nu et la même liste
**Quand** un push ajoute un fichier qui nomme `docs/private/` dans son texte, ou dont le chemin ressemble à un chemin interdit sans l'être (par exemple `docs/private-notes.md`)
**Alors** le push est admis (NFR-9).

**Étant donné** l'exécution du script dans ses modes `staged` ou `history`
**Quand** la liste des motifs est absente ou sans motif
**Alors** leur comportement est inchangé : repli sur les chemins, avec l'avertissement (C1 en CI en dépend).

- [ ] Les chemins interdits (`docs/private/`, `docs/context/`, `.env` à toute profondeur, `assets/cv/*.pdf`) figurent déjà dans le script : à constater, pas à réécrire.
- [ ] Le mode `pre-receive` lit les commits reçus sans arbre de travail (`git ls-tree`, `git grep <commit>`), ce que les tests prouvent sur un dépôt nu.
- [ ] Le script reste en `bash` avec `set -euo pipefail` ; `scripts/tests/run.sh` passe sur le poste et dans `alpine:3.24` ; le fonctionnement avec les outils de l'image de Gitea est vérifié par la story 1.2.
- [ ] Aucun motif réel dans le dépôt, la PR ou les journaux.
- [ ] Procédure `check-private.md` et AD-12 alignés.

### Story 1.2 : Pre-receive hook installed on main forge

En tant qu'Arnaud, mainteneur,
je veux que la forge principale refuse côté serveur tout push qui contient un chemin ou un motif privé,
afin que le garde-fou soit non contournable (UJ-4).

**Couvre :** FR-28, NFR-9, UJ-4, SM-5 · AD-12, procédure « hook pre-receive » (étapes 1 à 6) · C2
**Dépendances :** 1.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, administration du serveur Gitea (image Docker normale, Gitea 1.27.3) : copie du script du garde-fou et de la liste des motifs dans le volume de données de Gitea, pose du hook dans le dépôt nu du site, ajout et retrait du motif factice, rendu de la liste inaccessible, recréation du conteneur, fusion de test depuis l'interface. Le développeur prépare le script du hook, ses tests et la procédure, et fait les pushs de test. Aucun chemin de la machine hôte ni nom d'hôte n'est commité.

**Décisions (Arnaud, 15/09/2026, après la revue de spec) :**
- le script du hook est versionné dans `scripts/gitea/pre-receive-check-private` et testé dans `scripts/tests/` ; il trouve le script du garde-fou et la liste des motifs sous `$GITEA_CUSTOM/eleyone-check-private/`, variable définie par les images officielles de Gitea, donc sans chemin du serveur dans le dépôt ; la procédure d'installation est `docs/procedures/gitea-pre-receive-hook.md` ;
- les pushs de test sont faits par l'agent, depuis un clone jetable hors du dépôt de travail, avec le hook local désactivé dans ce seul clone, du contenu factice et des branches jetables supprimées ensuite ; Arnaud fait les opérations sur le serveur et la fusion depuis l'interface ;
- la fusion depuis l'interface est prouvée par un motif factice présent dans une branche déjà poussée, ajouté ensuite à la liste : la fusion doit être refusée ;
- les résultats sont notés dans le fichier de story (date, version de Gitea, variante de l'image, refusé ou admis), sans nom d'hôte ni chemin de la machine hôte.

**Critères d'acceptation :**

**Étant donné** `scripts/gitea/pre-receive-check-private`, posé dans `hooks/pre-receive.d/check-private` d'un dépôt nu
**Quand** un push arrive
**Alors** il lance `check-private.sh pre-receive` avec `PRIVATE_PATTERNS_FILE`, sans reprendre sa logique ; il refuse le push, avec un message qui nomme la cause, si `GITEA_CUSTOM` n'est pas définie, si le script du garde-fou ou la liste des motifs est absent ou illisible ; les cas de `scripts/tests/` le vérifient sur un dépôt nu jetable.

**Étant donné** `DISABLE_GIT_HOOKS` laissé à `true` et le hook installé selon la procédure, script et liste appartenant à l'utilisateur `git` du conteneur, liste en `0600`
**Quand** Arnaud ouvre l'édition des hooks du dépôt dans l'interface web
**Alors** elle n'est toujours pas proposée, et le hook posé à la main s'exécute malgré ce réglage (constaté par les pushs suivants).

**Étant donné** le hook installé
**Quand** l'agent pousse sur des branches jetables un commit qui ajoute un fichier sous `docs/private/`, sous `docs/context/`, un `.env`, un PDF sous `assets/cv/`, puis un commit qui contient un motif factice ajouté temporairement à la liste par Arnaud
**Alors** chaque push est refusé, avec le commit et le chemin, sans afficher le motif
**Et** un push sans contenu privé est admis
**Et** le motif factice est retiré ensuite.

**Étant donné** la liste rendue temporairement absente ou illisible par Arnaud
**Quand** l'agent pousse un commit sans contenu privé
**Alors** le push est refusé, par sécurité ; une fois la liste rétablie, le même push est admis.

**Étant donné** une branche de test déjà poussée, qui contient un motif factice, et une PR ouverte depuis cette branche
**Quand** Arnaud ajoute ce motif à la liste puis fusionne la PR depuis l'interface
**Alors** la fusion est refusée, ce qui prouve le passage par le hook ; sinon, la story s'arrête et Arnaud décide
**Et** le motif est retiré, la PR fermée et la branche supprimée.

**Étant donné** le conteneur Gitea recréé
**Quand** l'agent pousse un commit qui ajoute un fichier sous `docs/private/`
**Alors** le push est encore refusé : script, liste et hook sont dans le volume de données de Gitea.

- [ ] Le hook n'est posé que dans le dépôt nu du site : le dépôt privé n'en a pas et n'est pas mirroré.
- [ ] Le garde-fou fonctionne avec les outils de l'image de Gitea, dont le `grep` de BusyBox : les tests de `scripts/tests/test-check-private.sh` réussissent dans l'image `gitea/gitea:1.27.3`, et les pushs de test le constatent sur la forge.
- [ ] Les résultats des essais sur la forge sont notés dans le fichier de story, sans information sur le serveur.
- [ ] Procédure `check-private.md`, AD-12 et procédure « hook pre-receive » d'AD-24 alignées avec `gitea-pre-receive-hook.md`.

### Story 1.3 : Full history audit with pattern list

En tant qu'Arnaud, mainteneur,
je veux un audit propre de tout ce que la forge expose, branches, tags et références de PR comprises,
afin d'activer le miroir sans qu'un commit privé reste accessible sur GitHub par son SHA.

**Couvre :** FR-28, NFR-9, SM-5 · AD-12 · C1 (avec motifs)
**Dépendances :** 1.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non pour l'audit, lancé par l'agent sur le poste, où vit la liste des motifs. Toute réécriture d'historique reste une décision et une exécution d'Arnaud.

**Décisions (Arnaud, 16/09/2026, après la revue de spec) :**
- périmètre : toutes les références de la forge, `refs/pull/*` comprises, qu'un `git clone --mirror` récupère, et non les seules branches ;
- l'audit est lancé par l'agent dans un clone miroir jetable hors du dépôt de travail, avec `PRIVATE_PATTERNS_FILE` ;
- en cas de signalement, l'agent s'arrête et n'exécute ni réécriture d'historique ni push forcé : Arnaud décide et exécute, ou autorise chaque commande au moment voulu.

**Contraintes :** aucun signalement, motif ou contenu trouvé n'est recopié dans un fichier suivi, une PR, un commentaire ou une conversation ; seuls l'emplacement masqué et les chiffres sont notés.

**Critères d'acceptation :**

**Étant donné** un clone miroir récent du dépôt de la forge, qui contient toutes ses références
**Quand** l'agent lance `PRIVATE_PATTERNS_FILE=<liste> <dépôt de travail>/scripts/check-private.sh history` depuis ce clone
**Alors** le script sort avec le code 0, sans aucun signalement ni la mention « chemins seulement »
**Et** le nombre de références et de commits audités, le commit de tête de chaque branche et la date sont notés dans le fichier de story.

**Étant donné** un signalement
**Quand** il apparaît
**Alors** l'agent s'arrête et montre les emplacements masqués, sans jamais citer le contenu trouvé ; aucune réécriture n'est lancée sans décision d'Arnaud ; après une réécriture éventuelle, les essais 1 et 3 du hook (story 1.2) sont rejoués, puis l'audit recommencé.

- [ ] Le clone miroir jetable est supprimé après l'audit.
- [ ] Rien n'est poussé vers la forge pendant l'audit.

**Renvoyé à la story 1.4 :** le miroir push de Gitea envoie-t-il les références `refs/pull/*`, que GitHub refuse comme références cachées ? À constater lors de l'activation du miroir.

### Story 1.4 : Push mirror to public GitHub repository

En tant que Sam, tech lead (UJ-3),
je veux trouver sur GitHub le dépôt et ses artefacts de cadrage, tenus à jour depuis la forge,
afin de lire le cadrage et le code.

**Couvre :** FR-28, FR-31, UJ-3 · AD-11, AD-12
**Dépendances :** 0.2, 1.2, 1.3
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, dans cet ordre (procédure `docs/procedures/github-mirror.md`) :

1. créer le dépôt public sur GitHub, vide ;
2. créer le compte machine, l'inviter comme collaborateur en écriture, accepter l'invitation ;
3. créer sur ce compte machine un jeton d'écriture et noter son expiration (un jeton à grain fin ne convient pas : voir la décision ci-dessous) ;
4. poser les deux rulesets d'AD-12 ;
5. configurer le miroir push dans Gitea, avec le compte machine et son jeton, et la synchronisation à chaque push ;
6. lancer les essais de la story avec l'agent.

**Décisions (Arnaud, 16/09/2026, après la revue de spec) :**
- le miroir push de Gitea ne sait pas pousser en SSH (documentation Gitea) : la clé de déploiement d'AD-12 est écartée, l'identité du miroir est un **compte machine** dont le jeton n'est stocké que dans Gitea. Le jeton personnel d'Arnaud sert à ses autres miroirs, jamais à celui-ci ;
- **jeton classique, pas à grain fin** (constat de l'installation, 16/09/2026) : un jeton à grain fin ne cible que les dépôts possédés par le compte qui l'émet, et le compte machine n'est que collaborateur d'un dépôt appartenant à Arnaud ; le miroir utilise donc un jeton classique portant les seules portées `public_repo` et `workflow`, dont la portée réelle et la rotation sont écrites dans `docs/procedures/github-mirror.md` ;
- contournement des rulesets : le **compte machine désigné nommément** ; le push direct depuis le compte personnel d'Arnaud doit être refusé. *(Corrigé le 16/09/2026 : le contournement par rôle **Write** d'abord posé couvrait aussi Arnaud, propriétaire du dépôt, dont le push est passé.)* ;
- le miroir pousse par `git push --mirror`, donc toutes les références : on configure le miroir tel quel, on observe la première synchronisation et on note ce qui est réellement poussé. Si GitHub refuse les `refs/pull/*` (références cachées) au point de faire échouer la synchronisation, la suite est tranchée par Arnaud à ce moment-là ;
- toutes les branches de la forge sont mirrorées, `design/dossier-architecture`, `design/suisse` et `experiment/d2-bilingue` comprises, que le README-cas cite.

**Critères d'acceptation :**

**Étant donné** un clone miroir frais de la forge, hors du dépôt de travail
**Quand** l'agent relance l'audit complet de la story 1.3 (`PRIVATE_PATTERNS_FILE=<liste> <dépôt de travail>/scripts/check-private.sh history`), juste avant d'activer le miroir
**Alors** il sort avec le code 0, sans signalement ni mention « chemins seulement », et son résultat est noté dans le fichier de story.

*Note : un audit plus ancien que le dernier commit poussé ne vaut pas (ajouté après la revue du code de la story 1.3).*

**Étant donné** le miroir push configuré avec le compte machine et la synchronisation à chaque push
**Quand** la première synchronisation a lieu
**Alors** les branches de la forge existent sur GitHub avec les mêmes SHA, `main` en branche par défaut et `dev` en branche de travail
**Et** le brief, son addendum, le PRD, l'architecture, `DESIGN.md`, `EXPERIENCE.md`, ainsi que le présent document, y figurent (FR-31)
**Et** la liste des références effectivement poussées est notée, ainsi que le sort des `refs/pull/*` et l'état de la synchronisation affiché par Gitea.

**Étant donné** un clone miroir frais du dépôt GitHub
**Quand** l'agent lance `PRIVATE_PATTERNS_FILE=<liste> <dépôt de travail>/scripts/check-private.sh history` depuis ce clone
**Alors** il sort avec le code 0, sans signalement ni mention « chemins seulement ».

**Étant donné** les deux rulesets d'AD-12 (toutes les branches et tous les tags : création, mise à jour et suppression restreintes, contournement par le compte machine désigné nommément ; `main` en « Block force pushes », sans contournement)
**Quand** Arnaud pousse directement depuis son compte personnel
**Alors** GitHub refuse le push, et le miroir continue de synchroniser (D-9).

**Étant donné** une branche jetable réécrite sur la forge (force-push), puis synchronisée
**Quand** le miroir la pousse
**Alors** GitHub accepte la mise à jour non fast-forward et la synchronisation n'échoue pas
**Et** la branche jetable est ensuite supprimée sur la forge, et sa suppression se propage sur GitHub.

- [ ] Le jeton du compte machine n'est stocké que dans Gitea ; les remotes du poste pointent vers la forge seulement (`git remote -v`).
- [ ] L'expiration du jeton et la façon de le remplacer sont écrites dans `docs/procedures/github-mirror.md`.
- [ ] Aucun des artefacts publiés cités au critère 2 ne reprend un cas brut *(relecture)*.
- [ ] L'URL du dépôt public est notée pour la story 9.5 (`params.source_url`), sans toucher à la configuration Hugo ici.

### Story 1.5 : Guard covers env variants, commit messages and file names

*(ajoutée après la rétrospective de l'epic 1 ; constats G1, G2, G4, D1, S1, G3 et S5 de `_bmad-output/implementation-artifacts/epic-1-retro-2026-09-16.md`)*

En tant qu'Arnaud, mainteneur,
je veux que le garde-fou regarde aussi les variantes de `.env`, les messages de commit et les noms de fichiers,
afin qu'aucun motif privé ne parte sur le dépôt public par une surface qu'il ne lisait pas.

**Couvre :** FR-28, NFR-9 · AD-12, AD-19 · C2
**Dépendances :** 1.1, 1.2, 1.4
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, après la fusion : recopier `scripts/check-private.sh` dans le dossier du garde-fou sur la forge et rejouer l'essai 3 de `docs/procedures/gitea-pre-receive-hook.md` (étape 5 de la procédure, « à chaque modification du script »).

**Pourquoi maintenant :** le miroir synchronise à chaque push depuis la story 1.4. Une fois un commit accepté par la forge, il est public en quelques secondes et reste accessible par son SHA. Toute surface que le garde-fou ne lit pas devient une fuite irréversible, et tout contrôle qui ne vit qu'en CI arrive après la publication.

**Décisions (Arnaud, 16/09/2026, après la revue de spec) :**
- **variantes de `.env`** : est refusé le fichier dont le nom de base est exactement `.env` ou commence par `.env.` (`.env.production`, `.env.local`, `config/.env.staging`) ; restent admis `.environment.md`, `env.example` et `docs/env.md` (NFR-9) ;
- **mode `staged`** : le pre-commit refuse les mêmes chemins et les mêmes noms que le hook. Seul le message de commit lui échappe, puisqu'il n'existe pas encore au moment du contrôle ;
- **messages de commit en local** : rien de plus dans cette story. Le hook serveur les refuse au push, quitte à faire réécrire le commit ; un hook `commit-msg` local serait une story à part ;
- **seuil de performance** : le surcoût de la lecture des messages reste sous **1 seconde** sur l'historique complet, mesuré sur le poste et consigné dans le fichier de story (repère : l'audit complet met 1,5 s sur 33 commits avant cette story) ;
- **images d'ici la story 5.4** : le hook refuse **temporairement** les extensions d'images, puisque C20 n'existe pas encore et que la CI arriverait après la publication. Cette interdiction est levée par la story 5.4, quand C20 vit dans le hook — comme `assets/cv/*.pdf` sera levé quand C21 y sera ;
- **deux exceptions nommées**, constatées en lançant l'audit sur l'historique réel : `.env.example`, commité par conception et sans aucune valeur (AGENTS.md), et `design/<branche>/screenshots/`, les 35 captures des branches de design, déjà publiées, produites par un navigateur et hors du périmètre de C20 (`assets/images/` et `public/`). Sans elles, l'audit complet resterait rouge pour toujours ;
- **noms de fichiers** : les motifs sont cherchés dans le **chemin complet**, un dossier nommé d'après un client fuyant autant qu'un fichier ;
- **métadonnées d'images (C20)** : elles doivent bloquer **avant publication**, donc dans le hook `pre-receive`, comme les PDF (C21). Le contrôle lui-même reste construit par la story 5.4 ; cette story-ci écrit la règle et l'exigence qui pèse sur la 5.4.

**Critères d'acceptation :**

**Étant donné** le dépôt nu jetable des tests de la story 1.1, muni du vrai hook et d'une liste contenant un motif factice
**Quand** un push ajoute un fichier dont le nom de base est `.env` ou commence par `.env.` (`.env.production` à la racine, `config/.env.local`), ou un fichier dont l'extension est une extension d'image
**Alors** le push est refusé, avec le commit et le chemin
**Et** `.environment.md`, `env.example` et `docs/env.md` restent admis (NFR-9).

**Étant donné** le même dépôt nu et la même liste
**Quand** un push apporte plusieurs commits nouveaux et que le **message** de l'un d'eux, tête ou non, contient le motif factice
**Alors** le push est refusé en nommant ce commit, sans afficher le motif ni le message
**Et** tous les commits nouveaux de la plage poussée sont examinés, pas seulement la tête.

**Étant donné** le même dépôt nu et la même liste
**Quand** un push ajoute un fichier dont le **chemin** (dossier ou nom) contient le motif factice, au contenu anodin
**Alors** le push est refusé en nommant le commit et le numéro de ligne du motif, **sans afficher le chemin fautif** : l'afficher reviendrait à afficher le motif.

**Étant donné** `scripts/check-private.sh history` sur un historique qui porte l'une de ces surfaces
**Quand** l'audit tourne avec la liste des motifs
**Alors** il sort en échec et désigne le commit, comme le hook.

**Étant donné** `scripts/check-private.sh staged` avec, dans l'index, une variante de `.env`, une image, ou un chemin qui reprend le motif factice
**Quand** le pre-commit tourne
**Alors** il refuse, avec les mêmes messages que le hook ; le message de commit, lui, n'est pas contrôlé à ce stade.

**Étant donné** `scripts/check-private.sh` appelé avec un mode
**Quand** le script lit ce mode
**Alors** il ne le lit qu'**une seule fois**, pour qu'un drapeau placé un jour devant le mode ne puisse pas faire diverger le verrou `pre-receive` de l'aiguillage (par exemple en aiguillant sur la variable déjà lue).

**Étant donné** `AGENTS.md`
**Quand** on le lit après cette story
**Alors** le hook serveur et le miroir y sont décrits **au présent** (ils tournent depuis les stories 1.2 et 1.4), avec le renvoi à leurs procédures.

**Étant donné** AD-12, AD-19 et `docs/procedures/gitea-pre-receive-hook.md`
**Quand** on cherche quels contrôles bloquent avant publication
**Alors** ils disent que C21 (PDF) et C20 (métadonnées d'images) vivent dans le hook, que la CI seule ne suffit plus depuis l'activation du miroir, et que les extensions d'images sont refusées d'ici la story 5.4
**Et** la story 5.4 porte le critère correspondant, avec la levée de cette interdiction.

- [ ] Un cas de test par surface dans `scripts/tests/test-check-private.sh` : contenu, chemin, chemin qui reprend un motif, message de commit, variante de `.env`, image ; `scripts/tests/run.sh` passe.
- [ ] Aucun message n'affiche le motif, le contenu trouvé, le chemin fautif d'un motif, ni le message de commit fautif : seulement le commit, le numéro de ligne du motif, et le chemin quand il vient d'une règle de chemin (qui ne révèle aucun motif).
- [ ] La liste des motifs n'est ni lue, ni copiée, ni citée ailleurs.
- [ ] Le surcoût de la lecture des messages est mesuré sur l'historique complet et consigné : moins d'une seconde.
- [ ] `epics.md` ne contient qu'une seule copie de chaque epic après la PR (constat S5 : vérification par comptage des titres).
- [ ] Le piège d'ancre qui a produit S5 est écrit dans `docs/procedures/shell-scripts.md` (action 6 de la rétrospective de l'epic 1).

## Epic 2 : Site bilingue et cas pilote sous son poste (WS-1, WS-2)

Un lecteur passe du français à l'anglais par le sélecteur, et voit en rendu de travail le poste Chiliz avec le cas 02, puis la section du cas sur la page Chiliz. Structure HTML sans mise en page : la mise en forme vient des epics 5 et 6.

### Story 2.1 : Pinned tools installed and verified

En tant qu'Arnaud, mainteneur,
je veux que Hugo, D2 et les outils de contrôle aient la même version sur le poste, dans les deux CI et dans l'image,
afin qu'un rendu ou un contrôle ne diffère jamais d'un environnement à l'autre.

**Couvre :** NFR-7, NFR-8 · AD-1, AD-24
**Dépendances :** Epic 1 (ordre du squelette)
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **déjà faite** — Docker est disponible dans le shell WSL du poste depuis la story 0.8 (les tests de l'epic 1 ont tourné dans `alpine:3.24` et dans `gitea/gitea:1.27.3`).

**Décisions (Arnaud, 16/09/2026, après la revue de spec) :**
- la **vérification de version commune** vit dans `scripts/lib/tools.sh`, à côté de `gitea.sh`, `sprint.sh` et `merge-gates.sh`, avec ses cas dans `scripts/tests/` ;
- un binaire déjà présent dans `.tools/` dont l'empreinte ne correspond plus à `tools.env` est **réinstallé sans rien demander** : `.tools/` est un cache ignoré par git, et une montée de version doit se faire en modifiant `tools.env` seul, sans geste manuel ;
- `tools.env` absent, illisible ou privé d'une variable attendue **arrête immédiatement** le script, en **code 2** (anomalie, convention 0/1/2 du projet), avec un message qui nomme le fichier et la variable ;
- les empreintes sont calculées depuis les archives officielles et **recoupées avec les fichiers de sommes publiés** par les deux projets ; leur origine et leur date sont notées dans le fichier de story ;
- avec `--local`, le script n'installe **que** Hugo et D2 (AD-1) : aucun `apk`, puisque le poste n'en a pas.

**Critères d'acceptation :**

**Étant donné** `tools.env`
**Quand** on cherche dans le dépôt une version ou une empreinte de Hugo, de D2 ou de l'image de contrôle
**Alors** elles ne sont déclarées que là, et nulle part ailleurs : Hugo v0.166.0 et D2 v0.9.0 (linux-amd64) avec leur sha256, et `CHECK_IMAGE` = `alpine:3.24` épinglée par digest
**Et** monter une version consiste à modifier ce seul fichier.

**Étant donné** un conteneur lancé depuis `CHECK_IMAGE`
**Quand** `scripts/ci/install-tools.sh` s'exécute
**Alors** Hugo et D2 sont téléchargés et vérifiés par sha256
**Et** `bash`, `git`, `grep` GNU, `jq`, `libxml2-utils` et `poppler-utils` sont installés par `apk`
**Et** les deux binaires répondent avec la version attendue.

**Étant donné** le poste de développement, sans Hugo ni D2 dans le `PATH`
**Quand** on lance `scripts/ci/install-tools.sh --local`
**Alors** Hugo et D2 sont téléchargés, vérifiés par sha256 d'après `tools.env`, et installés dans `.tools/`, que `.gitignore` exclut (D-15)
**Et** aucun paquet système n'est installé.

**Étant donné** une empreinte attendue qui ne correspond pas à l'archive téléchargée
**Quand** `scripts/ci/install-tools.sh` s'exécute
**Alors** il échoue en nommant l'outil, sans installer le binaire, et sans afficher l'archive.

**Étant donné** un binaire déjà installé dans `.tools/` dont l'empreinte ne correspond plus à `tools.env`
**Quand** on relance `scripts/ci/install-tools.sh --local`
**Alors** il le remplace sans demander d'intervention, et la version installée est celle de `tools.env`.

**Étant donné** la vérification de version commune de `scripts/lib/tools.sh`
**Quand** le binaire trouvé annonce une version différente de celle de `tools.env`
**Alors** elle échoue avec un message nommant l'outil, la version attendue et la version trouvée.

**Étant donné** `tools.env` absent, illisible, ou privé d'une des variables attendues
**Quand** un script le charge
**Alors** il s'arrête en **code 2** avec un message nommant le fichier et la variable manquante, sans continuer avec une valeur vide.

- [ ] `scripts/tests/run.sh` passe, cas de `tools.sh` compris ; les cas d'installation sont **hors ligne** (archives factices servies depuis un dossier local, aucune requête réseau).
- [ ] `.tools/` est ignoré par git et n'entre pas dans l'historique.
- [ ] L'origine des empreintes (archives officielles, fichiers de sommes des projets, date) est notée dans le fichier de story.
- [ ] Aucune version ni empreinte n'est écrite ailleurs que dans `tools.env` *(vérification par recherche dans le dépôt)*.

### Story 2.2 : Bilingual Hugo build with minimal home

En tant qu'Arnaud, mainteneur,
je veux une commande unique qui produit le rendu de travail ou le build de production, avec un accueil minimal par langue,
afin que brouillons et éléments prévus n'arrivent jamais en production.

**Couvre :** FR-1, FR-20, FR-21, FR-26, FR-33, NFR-1 · AD-2, AD-3, AD-5, AD-19
**Dépendances :** 2.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Décisions (Arnaud, 16/09/2026, après la revue de spec) :**
- **titre du site** (FR-1), provisoire et à ajuster plus tard : FR « Arnaud Grousset · Développeur backend senior », EN « Arnaud Grousset · Senior Backend Developer », avec le séparateur « · » précédé d'une espace insécable (`DESIGN.md`) ;
- **pitch** : l'accueil l'**omet** tant que la story 10.1 ne l'a pas écrit. Un `[TODO: …]` publié ferait échouer le contrôle C5, et un accueil passé en brouillon disparaîtrait de la production — exactement ce que cette story cherche à empêcher ;
- **`dev.sh`** garde la commande d'AD-5, **sans `--panicOnWarning`** : un serveur de travail qui meurt au premier avertissement à chaque sauvegarde est inutilisable. Les avertissements restent bloquants là où ils comptent, `build.sh` et les deux CI. À ajuster si la pratique montre le contraire ;
- **frontière AD-3** : `identity`, `based_in`, `job_title` et le titre sont des **clés de front-matter** de `content/_index.{fr,en}.md` (AD-19) ; les gabarits les lisent sans écrire un seul mot de contenu.

**Critères d'acceptation :**

**Étant donné** `config/_default/hugo.yaml`
**Quand** Hugo le lit
**Alors** il porte les réglages d'AD-2 : `baseURL`, `defaultContentLanguage: fr`, `defaultContentLanguageInSubdir: false`, `disableDefaultSiteRedirect: true`, clés `label`, `locale`, `weight`, `disableKinds: [taxonomy, term, rss]`, permaliens et slugs par langue.

**Étant donné** `scripts/build.sh`
**Quand** il est appelé avec `production`, avec `work`, **sans argument**, puis avec un argument inconnu
**Alors** les deux premiers lancent exactement les commandes d'AD-5 vers `public/` puis `build/work/`, et les deux suivants échouent avec un message d'usage
**Et** dans tous les cas la version de Hugo est vérifiée avant l'appel (`scripts/lib/tools.sh`), `scripts/dev.sh` faisant de même.

**Étant donné** `content/_index.{fr,en}.md` portant les clés de front-matter `identity`, `based_in`, `job_title`, `title` (titre du site de FR-1) et `translationKey: home`
**Quand** on lance le build de production
**Alors** `/` (français) et `/en/` affichent la ligne d'identité, « Basé en France » / *Based in France* et le titre du site, **sans aucune page ni redirection sous `public/fr/`** (décidé le 16/09/2026 : Hugo place toujours le sitemap d'une langue dans son dossier dès qu'il y a plusieurs langues, et `sitemap.filename` le renomme sans le déplacer ; `public/fr/sitemap.xml` est donc normal, et l'espace d'URL français reste la racine)
**Et** chaque `<title>` est construit par `baseof.html` seul : le titre de la page suivi de la ligne d'identité, **sauf sur l'accueil**, dont le titre est le titre du site et porte déjà le nom (AD-2, précisé le 16/09/2026)
**Et** aucun gabarit ne contient de texte de contenu (AD-3).

**Étant donné** les deux environnements
**Quand** on compare leurs pages
**Alors** seul le rendu de travail contient `<meta name="robots" content="noindex">`, et aucun build n'émet d'avertissement.

- [ ] `scripts/dev.sh` lance `hugo server --environment work --buildDrafts`.
- [ ] `.gitignore` exclut `public/`, `build/`, `resources/_gen/`, `.hugo_build.lock` et `.tools/`.
- [ ] `scripts/build.sh` et `scripts/dev.sh` placent `.tools/` en tête du `PATH` quand il existe (D-15).
- [ ] `ci/release-pages.txt` est créé avec `home`, première entrée de la liste cumulative des pages publiées attendues (D-5).
- [ ] Aucun texte de contenu dans les gabarits ; ceux-ci ne testent que `hugo.IsProduction`.
- [ ] Les cas de test des scripts sont **hors ligne** : `hugo` bouchonné pour vérifier les commandes exactes, aucun appel réseau.

### Story 2.3 : Language switcher, hreflang and 404 pages

En tant que Daniel, recruteur qui lit en anglais (UJ-2),
je veux passer d'une page française à la même page en anglais par un lien visible,
afin de lire le site dans ma langue.

**Couvre :** FR-20, FR-21, NFR-4, NFR-12 · AD-2, AD-3
**Dépendances :** 2.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Décisions (Arnaud, 17/09/2026, après la revue de spec) :**
- **textes des 404**, validés : titre `not_found_title` « Page introuvable » / *Page not found* ; phrase « Cette page n'existe pas, ou elle a changé d'adresse. » / *This page doesn't exist, or it has moved.* ; premier lien « Accueil » / *Home* ; second lien vers l'accueil de l'autre langue, **avec un libellé distinct de celui du sélecteur** — « Accueil en anglais » / *Home in French* (corrigé le 17/09/2026 en constatant le rendu : l'en-tête de la 404 porte déjà le sélecteur, et deux liens nommés « English » menant ailleurs seraient ambigus, WCAG 2.4.4) ;
- **aucun lien « Contact » sur la 404** : `EXPERIENCE.md` en prévoit deux, la page Contact n'existe pas avant l'epic 9, et le projet n'écrit rien pour ce qui n'existe pas ;
- **pas d'attribut `dir`** sur `<html>` tant qu'aucune langue du site ne s'écrit de droite à gauche : ni AD-2 ni `DESIGN.md` ne l'imposent, et ce serait du bruit.

**Critères d'acceptation :**

**Étant donné** le build de production
**Quand** on inspecte chaque page
**Alors** `<html lang>` vaut `fr` ou `en`, avec une balise `<link rel="alternate" hreflang>` par traduction et une balise distincte `hreflang="x-default"` vers le français, toutes en **URL absolues**
**Et** aucune page ne porte de `meta refresh` : la racine ne redirige pas (AD-2, NFR-12).

**Étant donné** une page profonde en français, avec une ancre dans l'URL
**Quand** Daniel suit le sélecteur
**Alors** il arrive sur la page équivalente en anglais, **sans l'ancre** ; le lien s'intitule « English » sur une page FR et « Français » sur une page EN, il porte les attributs `hreflang` et `lang`, sans JavaScript
**Et** son texte suffit à le nommer : aucun autre libellé accessible n'est ajouté (`DESIGN.md`, `language-switch`).

**Étant donné** une page sans traduction, en rendu de travail (impossible en production, FR-20)
**Quand** on suit le sélecteur
**Alors** il mène à l'accueil de l'autre langue, et le build ne casse pas (AD-2).

**Étant donné** le build de production
**Quand** on cherche les pages d'erreur
**Alors** `public/404.html` est en français et `public/en/404.html` en anglais — **leur génération effective est prouvée**, Hugo ne produisant pas forcément la 404 de chaque langue
**Et** chacune porte le titre, la phrase, un lien vers l'accueil de sa langue et un lien vers l'accueil de l'autre langue, avec le même en-tête et le même pied de page que les autres pages, dans **sa** langue (`DESIGN.md`, `EXPERIENCE.md`).

- [ ] `i18n/fr.yaml` et `i18n/en.yaml` portent les clés de cette story en `snake_case` anglais : `language_switch`, `not_found_title`, la phrase de la 404 et le libellé du lien d'accueil ; aucun de ces textes n'est écrit dans un gabarit (AD-3).
- [ ] L'en-tête ne porte que ce qui existe : la marque et le sélecteur. « À propos » et « Contact » viennent avec leurs pages (epic 9).
- [ ] Les deux constats reportés par la story 2.2 sont traités : le `hreflang="x-default"` ne casse plus le build sur une page sans version française, et le passage d'arguments à `hugo server` par `scripts/dev.sh` a son cas de test.

### Story 2.4 : Single env loader and dummy legal values

En tant qu'Arnaud, mainteneur,
je veux un chargeur unique des variables `HUGO_LEGAL_*` pour tous les builds,
afin qu'aucune coordonnée réelle ne soit commitée et qu'une mise en ligne n'utilise jamais de valeur factice.

**Couvre :** FR-18, NFR-9 · AD-9
**Dépendances :** 0.1, 2.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Décisions (Arnaud, 17/09/2026, après la revue de spec) :**
- **un seul lecteur de dotenv** dans le dépôt : la lecture ligne à ligne de `load_gitea_env` est factorisée dans `scripts/lib/dotenv.sh`, employée par `scripts/lib/gitea.sh` et par le chargeur. Elle retire les guillemets et le commentaire de fin, et ne lit jamais par `source` (constat D7 de la rétrospective de l'epic 0, « logique recopiée ») ;
- **`scripts/env.sh` est une enveloppe** : `scripts/env.sh <commande…>` lance la commande avec l'environnement préparé. La garantie devient vérifiable de l'extérieur, sans lire le code ;
- **repli variable par variable** : un `.env` incomplet est complété par le fichier factice pour les variables absentes, au lieu de faire échouer le build ;
- **`LEGAL_ENV_FILE` refusé sur deux critères** en mise en ligne : chemin canonique égal à `.env` ou au fichier factice du dépôt, **et** nom de base `.env`, pour qu'aucun `./.env` ni `../ailleurs/.env` ne passe.

**Critères d'acceptation :**

**Étant donné** `.env.example` (story 0.1) et `ci/legal-placeholder.env`
**Quand** on les lit
**Alors** le premier liste exactement, sans valeur, les sept variables d'AD-9 et les trois `GITEA_*` d'AD-24 (C18), et le second exactement les sept noms légaux avec des valeurs `VALEUR-FACTICE-…`.

**Étant donné** `scripts/env.sh` hors mise en ligne, et une variable donnée
**Quand** elle est déjà définie dans l'environnement, puis seulement dans `.env`, puis dans aucun des deux
**Alors** la valeur retenue suit cet ordre de priorité décroissant : la variable déjà définie, sinon celle de `.env`, sinon celle du fichier factice
**Et** le repli se fait **variable par variable** : un `.env` qui n'en porte que trois sur sept ne fait pas échouer le build.

**Étant donné** une valeur entre guillemets ou contenant des espaces (`HUGO_LEGAL_PUBLISHER_NAME="Arnaud Grousset"`)
**Quand** le chargeur lit `.env`
**Alors** la valeur arrive entière et sans ses guillemets, comme le fait déjà `load_gitea_env`, sans `source` ni `set -a`.

**Étant donné** `ENV_MODE=release`
**Quand** `LEGAL_ENV_FILE` manque, désigne `.env` ou le fichier factice — **y compris par un chemin détourné** (`./.env`, `../ailleurs/.env`) —, ou qu'une variable manque
**Alors** le chargeur échoue en nommant la cause, sans afficher aucune valeur.

**Étant donné** un `.env` qui contient une variable `GITEA_TOKEN` factice
**Quand** `scripts/build.sh` lance `hugo`
**Alors** le processus `hugo` ne voit pas `GITEA_TOKEN` dans son environnement : le chargeur ne lit que les lignes `^HUGO_LEGAL_` de `.env`
**Et** la garantie se vérifie de l'extérieur : `scripts/env.sh env` ne montre aucune variable `GITEA_*` venue de `.env`.

- [ ] `scripts/build.sh` et `scripts/dev.sh` passent par `scripts/env.sh`.
- [ ] Aucun `set -x`.
- [ ] Aucun message du chargeur n'affiche une valeur, factice ou non ; les cas de test le vérifient.
- [ ] `scripts/lib/gitea.sh` emploie le lecteur factorisé, et ses cas de test passent inchangés.

### Story 2.5 : Chiliz page, case partial and planned material

En tant que Claire, CTO (UJ-1),
je veux voir le cas 02 dans sa section de la page Chiliz, avec « Contexte mission », « En bref » puis le cas complet,
afin de juger le cas et d'en lire la preuve.

**Couvre :** FR-5 à FR-9, FR-12, FR-20, FR-25, FR-26 · AD-3, AD-4, AD-6
**Dépendances :** 2.3
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

Périmètre : `content/cases/_index.{fr,en}.md` (jamais rendu), `content/cases/chiliz/_index.{fr,en}.md` (`translationKey: group-chiliz`, titre « Chiliz » en FR et en EN sans introduction, `draft: true` tant que le cas 02 n'est pas publié, cascade ciblée ; AD-4, D-3 et D-4), `layouts/cases/section.html`, `_partials/case.html`, `_shortcodes/live-material.html` (éléments « prévus »), libellés d'`i18n/`. Le shortcode est dans cette story parce que le pilote l'utilise.

**Décisions (Arnaud, 17/09/2026, après la revue de spec) :**
- **le type d'un élément vient du champ `type`**, pas du préfixe de son identifiant : le préfixe est une règle de nommage (AD-6), et en faire la source du type créerait une seconde vérité, qui casserait au premier identifiant mal nommé ;
- **repli d'AD-4** : si la cascade casse avec un `_index` en brouillon, cette story **constate et consigne** ; l'exigence passe à la story 3.9, qui crée C12 et la porte déjà en toutes lettres. Rien à modifier ici, faute de contrôle existant.

**Critères d'acceptation :**

**Étant donné** `layouts/_shortcodes/live-material.html`, posé en version minimale par la story 2.2 parce qu'aucun build ne pouvait tourner sans lui (le pilote l'appelle trois fois par langue, six fois en tout)
**Quand** cette story le reprend
**Alors** elle le **complète sans le réécrire**, et il tient les règles d'AD-6, distinctes l'une de l'autre :
- un `id` absent de `live_material` **fait échouer le build** en le nommant ;
- un élément **déclaré** en `planned` ne produit **rien** en production, et s'affiche en rendu de travail en encart fixe portant son type et sa `description`, sans que sa source soit cherchée ;
- un élément `ready` est **résolu par son champ `type`** : `diagram` → `<figure><img>` depuis `assets/diagrams/<id>.<lang>.svg`, `alt` venant de la `description`, dimensions lues dans le SVG ; `video` → lien `<a href>` vers YouTube, **jamais d'`iframe`** ; `snippet` et `callout` → Markdown d'`assets/live-material/<id>.<lang>.md` dans `<figure>` ou `<aside>` ;
- un élément `ready` dont la source manque **fait échouer le build** ;
- un schéma dépassant le seuil de largeur de `DESIGN.md` est enveloppé dans un conteneur **focalisable** (`tabindex="0"`) doté d'un nom accessible ;
- le garde-fou temporaire qui faisait échouer le build sur un élément `ready` disparaît.

**Étant donné** le rendu de travail
**Quand** Claire ouvre `/cas/chiliz/` puis `/en/cases/chiliz/`
**Alors** la section `id="case-02"` contient, dans l'ordre du DOM, le titre du cas, « Contexte mission » (société, cadre, rôle, période, stack), « En bref », puis le cas complet
**Et** en anglais, les libellés sont ceux d'AD-3 (*Engagement context*, *At a glance*, *Company*, *Engagement*, *Role*, *Period*, *Stack*, *Employee*).

**Étant donné** le rendu de travail
**Quand** on regarde les **trois** emplacements du pilote, dans chacune des deux langues
**Alors** chacun s'affiche en encart avec son type et sa description, sans que sa source soit cherchée.

**Étant donné** une copie locale non commitée du pilote et du `_index` Chiliz en `draft: false`
**Quand** on lance le build de production
**Alors** la section 02 est présente, et les éléments « prévus » ne laissent aucune trace dans `public/`
**Et** la copie locale est défaite ensuite : le dépôt ne garde aucun de ces changements.

**Étant donné** le pilote et le `_index` Chiliz en brouillon, tels que commités
**Quand** on lance le build de production, puis le rendu de travail
**Alors** `public/` ne contient aucune page `/cas/chiliz/` ni `/en/cases/chiliz/`, puis le rendu de travail affiche la page Chiliz avec la section 02 : le `_index` en brouillon ne casse ni la cascade ni `case-url.html`
**Et** si ce constat échoue, il est **consigné tel quel** dans le fichier de story, et l'exigence passe à la story 3.9 (repli d'AD-4 : C12 exclut les pages de groupe sans section) ; rien n'est modifié ici, faute de contrôle existant.

**Étant donné** un identifiant placé mais non déclaré (copie locale)
**Quand** on lance un build
**Alors** le build échoue en nommant l'identifiant.

**Étant donné** une copie locale d'un second cas du groupe avec `order: 2`
**Quand** on lance le rendu de travail
**Alors** sa section suit celle du cas 02 sans modifier le `_index` ni les gabarits (FR-9).

- [ ] Aucune page séparée pour le cas 02 ; aucun `/cas/index.html`.
- [ ] Le sélecteur de la page Chiliz mène à la page Chiliz de l'autre langue.
- [ ] Aucun texte de contenu dans les gabarits : les libellés d'encart viennent d'`i18n/` (AD-3).
- [ ] Les copies locales des essais sont défaites, et `git status` est propre à la fin.

### Story 2.6 : Case section numbers and table of contents

En tant que Claire, CTO (UJ-1),
je veux voir chaque rubrique numérotée par cas et un sommaire de la page,
afin d'aller directement à « Ce que j'ai décidé ».

**Couvre :** FR-8, FR-9, NFR-4 · AD-4
**Dépendances :** 2.5
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le hook `layouts/_markup/render-heading.html`
**Quand** le cas pilote est rendu dans la page Chiliz
**Alors** chaque rubrique (`##`) est rendue en `<h3>` pour ce cas groupé, avec un identifiant préfixé par le `translationKey` (`case-02-` sur le pilote), la classe `rubric-heading` et `<span class="rubric-number" aria-hidden="true">NN.r</span>`, où `NN` vient de `number` et `r` est le rang de la rubrique dans le cas : 02.1 à 02.6 sur le pilote
**Et** les numéros sont identiques en FR et en EN
**Et** les identifiants sont en ASCII (`markup.goldmark.parser.autoHeadingIDType: github-ascii`) : `case-02-le-probleme`, jamais `case-02-le-problème` (décidé par Arnaud le 17/09/2026).

**Étant donné** une copie locale d'un cas du groupe dont le corps porte un titre `###`
**Quand** on lance le rendu de travail
**Alors** ce titre est rendu en `<h4>`, avec l'identifiant préfixé, sans numéro, sans classe `rubric-heading` et sans entrée de sommaire
**Et** le hook ne descend les titres que pour un cas groupé : un cas sans groupe garde ses rubriques en `<h2>`, ce que vérifie la story 6.2 avec son gabarit.

**Étant donné** une copie locale d'un cas 03 publié dans le groupe
**Quand** on rend la page
**Alors** les numéros du cas 02 ne changent pas.

**Étant donné** `_partials/toc.html`
**Quand** la page Chiliz est rendue
**Alors** un `<nav>` au nom accessible « Sommaire » / « Contents » contient un `<details>` natif, sans JavaScript, qui liste les cas publiés du groupe dans l'ordre `order` (« Cas 02 — titre », lien vers `#case-02`), et sous chacun ses rubriques, avec leur numéro et un lien vers leur identifiant
**Et** le résumé du `<details>` est « Sommaire · N rubriques » / « Contents · N sections » (« 1 rubrique » / « 1 section » au singulier), où `N` est calculé par le gabarit : le total des rubriques des cas publiés de la page, soit 6 sur le pilote (décidé par Arnaud le 17/09/2026)
**Et** « Contexte mission » et « En bref » n'ont ni numéro ni entrée de sommaire.

- [ ] Aucun CSS dans cette story : `:target` et `scroll-margin-top` relèvent de la story 6.1 (UX-DR12).
- [ ] Aucun texte de contenu dans les gabarits : les libellés du sommaire viennent d'`i18n/` (AD-3).
- [ ] Les copies locales des essais sont défaites, et `git status` est propre à la fin.

### Story 2.7 : Draft Chiliz position and back to career link

En tant que Claire, CTO (UJ-1),
je veux voir sur l'accueil le poste Chiliz avec le lien du cas 02, et revenir au poste depuis le cas,
afin d'atteindre une preuve en un clic depuis le CV.

**Couvre :** FR-2, FR-15, FR-25, FR-26, SM-3 · AD-4, AD-5, AD-18 · UX-DR22
**Dépendances :** 2.6
**Bloquée par :** —
**Prérequis de contenu :** — (la période du poste reste `[TODO: période]` ; données réelles à la story 10.2)
**Opération manuelle (Arnaud) :** non

Périmètre : `content/career/_index.{fr,en}.md` (jamais rendu), `content/career/position-chiliz.{fr,en}.md` en brouillon, `_partials/position.html`, `_partials/case-url.html`, `_partials/career-url.html`, marqueur « Brouillon », accueil minimal qui liste les postes. Le pilote porte déjà `position: "position-chiliz"`.

**Critères d'acceptation :**

**Étant donné** `content/career/_index.{fr,en}.md` avec `build: {render: never, list: never}` et `cascade: [{build: {render: never, list: always}, target: {kind: page}}]` (AD-18)
**Quand** on lance le rendu de travail puis le build de production
**Alors** aucune page n'est construite sous `/career/` ni pour un poste, et les postes restent lisibles par l'accueil.

**Étant donné** `content/career/position-chiliz.{fr,en}.md` en brouillon : `company: "Chiliz"`, `role` « Développeur backend senior » / « Senior backend developer » (donné par Arnaud le 17/09/2026), `period: "[TODO: période]"`, `setup: employee`, `track: main`, `order: 1`, sans `location` ni corps
**Quand** Claire ouvre l'accueil en rendu de travail
**Alors** le bloc « Parcours » (i18n `block_career`) montre le poste Chiliz (`id="position-chiliz"`) avec sa période, sa société en `h3`, son rôle et le libellé de son cadre
**Et** le poste liste le cas 02 par numéro (i18n `case_number`) et titre, sans « En bref », dans une liste au nom accessible i18n `cases_of_position` (« Cas qui prouvent ce poste » / « Cases behind this role », décidé par Arnaud le 17/09/2026), avec un lien vers `/cas/chiliz/#case-02` (`/en/cases/chiliz/#case-02` en anglais) construit par `case-url.html`
**Et** le cas est retrouvé par sa clé `position`, sans liste de cas dans le poste.

**Étant donné** une copie locale du poste Chiliz avec un corps Markdown
**Quand** on lance le rendu de travail
**Alors** le corps n'est pas affiché, puisque le poste a un cas (AD-18).

**Étant donné** la page Chiliz
**Quand** Claire suit « Retour au parcours » (i18n `back_to_career`), placé **une fois, en haut de page**, avant le `h1` (`EXPERIENCE.md`, premier écran ; décidé par Arnaud le 17/09/2026)
**Alors** elle arrive sur `/#position-chiliz` (`/en/#position-chiliz`), lien construit par `career-url.html` à partir de la clé `position` des cas de la page.

**Étant donné** le rendu de travail
**Quand** on affiche le cas 02 et le poste Chiliz, tous deux en brouillon
**Alors** un marqueur « Brouillon » (i18n `draft_marker`, classe `draft-marker`) précède le titre du cas sur la page Chiliz et sous le poste, et précède aussi la société du poste (AD-5 étendu, décidé par Arnaud le 17/09/2026).

**Étant donné** le build de production avec pilote et poste en brouillon
**Quand** on inspecte l'accueil
**Alors** aucun poste ni aucun cas n'y figure, aucune page Chiliz n'est construite, et aucun `draft-marker` n'existe dans `public/`.

**Étant donné** une copie locale d'un poste publié sans cas, avec un corps
**Quand** on lance le build de production
**Alors** il affiche ses champs puis son corps, sans zone de cas ni mention d'absence.

- [ ] Démonstration de WS-2 : accueil de travail avec le poste Chiliz et le cas 02, section et trois éléments « prévus ».
- [ ] L'accueil complet (ordre des blocs, « En parallèle », barre de révision, premier écran) reste à la story 5.2 ; aucun CSS ici.
- [ ] Aucun texte de contenu dans les gabarits : les libellés viennent d'`i18n/` (AD-3).
- [ ] Les copies locales des essais sont défaites, et `git status` est propre à la fin.

## Epic 3 : Contrôles bloquants, CI des deux forges et README-cas (WS-3, WS-4)

Arnaud reçoit un refus explicite, qui nomme le fichier et l'écart ; les mêmes contrôles tournent en local, sur Gitea et publiquement sur GitHub. Le README accueille le lecteur du dépôt comme un cas.

### Story 3.1 : Checks json manifest emitted by Hugo

En tant qu'Arnaud, mainteneur,
je veux que Hugo émette la liste de tous les fichiers de contenu avec leurs métadonnées,
afin que les contrôles lisent exactement ce que Hugo voit.

**Couvre :** FR-23, FR-26 · AD-5, AD-10
**Dépendances :** 2.7
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le format de sortie `checks` et `outputs.home` déclarés dans `config/work/hugo.yaml`, et nulle part ailleurs
**Quand** on lance `scripts/build.sh work`
**Alors** `build/work/checks.json` et `build/work/en/checks.json` sont du JSON valide (`jq`), produits par un seul `jsonify` du gabarit
**Et** aucun `checks.json` n'existe dans `public/` après le build de production.

**Étant donné** le manifeste d'une langue
**Quand** on le lit
**Alors** sa racine porte `lang`, le vocabulaire de `data/stack.yaml` une seule fois (`stack`, depuis `hugo.Data`), et `files`, qui liste **tous** les fichiers Markdown de `content/` pour cette langue — y compris ceux qu'aucune collection de pages ne contient (`list: never`), atteints en parcourant `content/` puis résolus par `site.GetPage`
**Et** chaque entrée porte : `file` (chemin relatif à `content/`, séparateurs `/`), `lang`, `kind` (`home`, `section`, `page`), `role` (`home`, `group`, `case`, `position`, `education`, `section`, `page`), `translationKey`, `draft`, `front_matter`, `h2`, `placed` et `todo`.

**Étant donné** la règle de rôle
**Quand** le manifeste est écrit
**Alors** `home` vient du `kind` ; `group` est le `_index` d'un dossier de groupe sous `cases/` ; `case`, `position` et `education` sont les pages de `cases/`, `career/` et `education/` ; `section` est tout autre `_index` technique (`cases/_index`, `career/_index`) — valeur ajoutée à AD-10 le 18/09/2026 ; `page` est le reste.

**Étant donné** un fichier de `content/`
**Quand** son entrée est écrite
**Alors** `front_matter` est le front matter **tel qu'écrit dans le fichier** (relu par `os.ReadFile` et `transform.Unmarshal`, casse des clés gardée, sans ce que la cascade ou Hugo ajoutent), une clé absente du fichier restant absente de l'objet
**Et** `h2` liste les titres de niveau 2 du Markdown brut dans l'ordre, `placed` les identifiants des appels `{{< live-material id="…" >}}` (`findRESubmatch` sur `.RawContent`), et `todo` dit si `[TODO` apparaît dans le fichier, front matter compris.

**Étant donné** un fichier de `content/` sans suffixe de langue
**Quand** les manifestes sont écrits
**Alors** il figure dans les deux, avec `lang` vide et une clé `error` qui nomme l'écart (décidé par Arnaud le 18/09/2026) : aucun fichier de `content/` n'échappe aux contrôles.

- [ ] La forme n'est définie que dans `layouts/home.checks.json`, documentée en tête de `scripts/checks/lib.sh`.
- [ ] Entrée du pilote : six titres H2 tels qu'écrits, trois identifiants placés, `position-chiliz`, `draft: true`.
- [ ] Entrées de `cases/_index` et `career/_index` présentes, en rôle `section`.
- [ ] Les deux manifestes listent le même nombre de fichiers, un par langue.

### Story 3.2 : Check script entry point and draft rule

En tant qu'Arnaud, mainteneur,
je veux lancer tous les contrôles bloquants par une seule commande, identique en local et en CI,
afin qu'un contrôle local ne diffère jamais de la CI et qu'un brouillon légitime ne soit pas refusé.

**Couvre :** FR-26, NFR-7 · AD-10 · C14
**Dépendances :** 2.4, 3.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le dépôt, avec ou sans dossier `.git`
**Quand** on lance `scripts/check.sh`
**Alors** il construit le rendu de travail puis le build de production par `scripts/build.sh`, lance tous les scripts de `scripts/checks/` (découverte dynamique, triés, `lib.sh` exclu : une story qui ajoute un contrôle ne modifie pas `check.sh`), et sort avec **0** si tout passe, **1** si un écart est constaté, **2** sur une anomalie (outil ou fichier manquant)
**Et** aucun script de `scripts/checks/` n'appelle `git`.

**Étant donné** un contrôle en échec
**Quand** `check.sh` s'exécute
**Alors** il lance quand même les contrôles suivants et affiche tous les écarts, puis un résumé nommant les contrôles en échec (décidé par Arnaud le 18/09/2026) : une seule passe suffit à tout voir.

**Étant donné** une copie locale qui introduit un avertissement de Hugo
**Quand** on lance les contrôles
**Alors** le build échoue (`--panicOnWarning`, C14), `check.sh` s'arrête **avant** les contrôles — aucun ne lit un manifeste périmé — et rend 1
**Et** la sortie de Hugo est gardée telle quelle, précédée d'une ligne de `check.sh` nommant le build en échec ; le format `<fichier>: <écart>` reste la règle des scripts de `scripts/checks/`.

**Étant donné** `scripts/checks/lib.sh`
**Quand** un script de contrôle évalue une règle de forme sur un fichier en `draft: true`
**Alors** il appelle les outils de `lib.sh` (`checks_is_todo`, `checks_tolerated`), qui acceptent une valeur commençant par `[TODO` ; `lib.sh` ne filtre rien de lui-même, puisque la parité, la liste des rubriques et le garde-fou s'appliquent aussi aux brouillons (AD-10).

**Étant donné** `scripts/check.sh --release`
**Quand** on le lance
**Alors** le niveau passe de `standard` à `release` et est transmis aux contrôles (`CHECK_LEVEL`, argument du Dockerfile en AD-13) ; aucun contrôle de mise en ligne n'existant avant l'epic 11, le niveau est posé, pas employé.

**Étant donné** les cas de test des contrôles
**Quand** on les écrit, ici et dans les stories 3.3 à 3.11
**Alors** la logique d'un contrôle se teste sur des manifestes écrits à la main sous `scripts/tests/fixtures/`, et **un** site fixture construit avec le Hugo épinglé prouve que le manifeste réel a bien cette forme (décidé par Arnaud le 18/09/2026), ce qui ferme le report de la story 3.1.

- [ ] Signalements `<fichier>: <écart>` sur la sortie d'erreur.
- [ ] `check.sh` fonctionne dans une copie sans `.git` (essai consigné).

### Story 3.3 : FR EN parity script

En tant qu'Arnaud qui corrige un chiffre (UJ-4),
je veux que la CI refuse toute différence mécanique entre FR et EN,
afin qu'aucune page ne soit publiée avec une métadonnée ou une rubrique d'un seul côté.

**Couvre :** FR-20, FR-23, SM-4 · AD-10 · C3
**Dépendances :** 3.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** une copie locale où une rubrique est retirée de la version anglaise du pilote
**Quand** on lance `scripts/check.sh`
**Alors** le contrôle échoue en nommant `content/cases/chiliz/case-02-chiliz.en.md` et l'écart de rubriques (démonstration de WS-3).

**Étant donné** un fichier de `content/` sans son équivalent (même `translationKey`), ou sans `translationKey`, ou dont le `translationKey` est porté par un autre fichier de la même langue
**Quand** on lance les contrôles
**Alors** le contrôle échoue en nommant le fichier et l'écart ; une entrée que le manifeste porte déjà en `error` (front matter absent, suffixe de langue absent) est reprise telle quelle.

**Étant donné** une différence entre FR et EN sur une clé non traduite
**Quand** on lance les contrôles
**Alors** le contrôle échoue en nommant le fichier, la clé et les deux valeurs : cas (`number`, `group`, `order`, `draft`, `position`, `context.setup`, `context.stack`, et `live_material` id, type, statut **dans le même ordre**, décidé par Arnaud le 18/09/2026) ; poste (`company`, `via`, `setup`, `track`, `order`, `draft`) ; entrée de formation (`kind`, `order`, `draft`) ; accueil (`identity`) ; contact (`email`, `linkedin`, `github`)
**Et** un rôle différent entre les deux langues est signalé de la même façon.

**Étant donné** `data/rubrics.yaml`, qui porte les rubriques dans l'ordre avec leur écriture française et anglaise (décidé par Arnaud le 18/09/2026 : la liste passe de `docs/format-cas.md` aux données, et le manifeste l'expose)
**Quand** le contrôle rapproche les rubriques d'une paire de fichiers
**Alors** il échoue si les deux langues n'ont pas le même nombre de rubriques, si une rubrique est absente de la liste, ou si la rubrique anglaise de rang *n* n'est pas l'écriture anglaise de la rubrique française de même rang
**Et** ce rapprochement ne vaut que pour un **cas** : ailleurs (poste, page simple), les titres sont libres et seul leur nombre est comparé, la liste ne portant que les rubriques d'un cas (portée de C4 ; constat de la revue du code de la PR n° 37).

- [ ] Le pilote, en brouillon avec ses valeurs actuelles, passe.
- [ ] La parité s'applique aussi aux brouillons : un `[TODO` n'excuse aucun écart (AD-10).
- [ ] La logique se teste sur des manifestes écrits à la main ; aucun cas de test ne lance Hugo (story 3.2).

### Story 3.4 : Headings, TODO markers and stack vocabulary

En tant qu'Arnaud, mainteneur,
je veux que la CI refuse un cas aux rubriques hors format, un `[TODO` publié ou une technologie hors vocabulaire,
afin que le format soit tenu sans relecture mécanique.

**Couvre :** FR-6, FR-8, FR-26 · AD-10 · C4, C5 (contenu), C6
**Dépendances :** 3.3
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** un cas dont un titre de niveau 2 est hors de `data/rubrics.yaml`, écrit deux fois, ou placé hors de l'ordre de cette liste
**Quand** on lance les contrôles
**Alors** C4 échoue en nommant le fichier, la rubrique et, pour un désordre, l'ordre attendu
**Et** C4 s'applique **aussi aux brouillons** (AD-10) et ne porte que sur les cas : ailleurs, les titres sont libres.

**Étant donné** un cas dont un titre est plus profond que `###`
**Quand** on lance les contrôles
**Alors** C4 échoue en nommant le niveau et le titre (décidé par Arnaud le 18/09/2026) : un cas groupé descend chaque titre d'un niveau, et un `######` produirait un `<h7>`, qui n'existe pas. Cela ferme l'entrée reportée de la story 2.6.

**Étant donné** un fichier de `content/` qui contient `[TODO` **où que ce soit**, front matter et blocs de code compris, et qui n'est pas un brouillon (l'état vient de Hugo, qui publie un fichier sans clé `draft`)
**Quand** on lance les contrôles
**Alors** C5 échoue en nommant le fichier.

**Étant donné** un cas dont la `stack` cite une technologie absente de `data/stack.yaml`
**Quand** on lance les contrôles
**Alors** C6 échoue en nommant le fichier et la technologie ; une valeur qui commence par `[TODO` est acceptée dans un brouillon (`checks_tolerated`), refusée dans un cas publié.

**Étant donné** le manifeste
**Quand** un contrôle lit les titres
**Alors** il les prend dans `headings`, qui donne le niveau et le texte de **chaque** titre du Markdown brut (la clé `h2` de la story 3.1 est remplacée), et la parité (C3) n'en retient que les niveaux 2.

- [ ] Les trois contrôles vivent dans `scripts/checks/content.sh`, lancé par `check.sh`.
- [ ] Un fichier que le manifeste porte en `error` relève de la parité, pas de ces contrôles.
- [ ] La logique se teste sur des manifestes écrits à la main ; les essais sur le pilote sont consignés.

### Story 3.5 : Live material and group checks

En tant qu'Arnaud, mainteneur,
je veux que la CI refuse un élément de matériel vivant mal déclaré ou un cas mal rangé dans son groupe,
afin qu'aucun emplacement ni aucune section ne disparaisse par erreur.

**Couvre :** FR-9, FR-12, FR-13 · AD-4, AD-6 · C7, C8
**Dépendances :** 3.4
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** un cas dont un élément (`planned` ou `ready`) est déclaré sans être placé, un identifiant placé sans être déclaré, un identifiant placé ou déclaré deux fois, ou un identifiant qui n'est pas préfixé par son type (AD-6)
**Quand** on lance les contrôles
**Alors** C7 échoue en nommant le fichier, l'identifiant et l'écart.

**Étant donné** un élément `ready` dont la source manque **dans la langue du fichier** — `assets/diagrams/<id>.<lang>.svg`, `assets/live-material/<id>.<lang>.md`, ou une `url` vide pour une vidéo
**Quand** on lance les contrôles
**Alors** C7 échoue en donnant le chemin attendu, ou en disant qu'une vidéo n'a pas d'`url`
**Et** la source est résolue **par Hugo dans le manifeste** (clé `material` : `id`, `type`, `status`, `source`, `source_found`), seul à voir `assets/` ; la règle de nommage d'AD-6 n'est donc écrite qu'une fois (décidé par Arnaud le 18/09/2026).

**Étant donné** un cas dont la clé `group` diffère du dossier parent direct, un cas hors d'un dossier de groupe qui porte une clé `group`, ou un cas rangé plus profond que `cases/<groupe>/`
**Quand** on lance les contrôles
**Alors** C8 échoue en nommant le fichier et l'écart, et les autres règles du même fichier sont **quand même** évaluées (décidé par Arnaud le 18/09/2026) : une seule passe montre tout.

**Étant donné** deux cas d'un même groupe qui portent le même `order`
**Quand** on lance les contrôles
**Alors** C8 échoue en nommant les deux fichiers ; la comparaison est par langue, chaque manifeste n'en portant qu'une.

- [ ] Un trou dans les `order` d'un groupe n'est pas un écart : un cas non publié en laisse forcément un.
- [ ] Le pilote, avec ses trois éléments « prévus », passe.

### Story 3.6 : At a glance box and format rules

En tant que Claire, CTO (UJ-1),
je veux que chaque « En bref » tienne en trois phrases et 400 caractères au plus,
afin de saisir l'enjeu et le résultat d'un coup d'œil.

**Couvre :** FR-6, FR-7, FR-12, FR-18 · AD-9, AD-10 · C16, C18
**Dépendances :** 3.5
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le `summary` d'un cas
**Quand** il dépasse 400 points de code ou 3 phrases — une phrase étant un segment terminé par `.`, `!`, `?` ou `…` suivi d'une espace ou de la fin, sans exception pour les abréviations
**Alors** C16 échoue en donnant les deux mesures ; une valeur commençant par `[TODO` passe dans un brouillon, et le pilote passe (FR 354 points de code, EN 346, 3 phrases chacun, mesuré).

**Étant donné** un cas dont le `title` dépasse 70 caractères, dont `context.setup` sort de `employee`, `freelance`, `agency`, `ton-pote-le-geek`, dont un élément a un `status` hors de `planned`, `ready` (les listes sont écrites dans le contrôle, avec un renvoi à AD-6 et à `docs/format-cas.md` — décidé par Arnaud le 18/09/2026), ou dont le numéro du nom de fichier diffère de `number` **ou** du suffixe du `translationKey`
**Quand** on lance les contrôles
**Alors** C18 échoue en nommant le fichier et l'écart, sauf valeur `[TODO` dans un brouillon.

**Étant donné** un cas publié dont l'encart n'a pas `context.company`, `context.role`, `context.period` non vides ni `context.stack` non vide (FR-6 ; ajout décidé par Arnaud le 18/09/2026, la ligne C18 de l'architecture est complétée)
**Quand** on lance les contrôles
**Alors** C18 échoue en nommant la clé ; un brouillon peut les porter en `[TODO`.

**Étant donné** `ci/legal-placeholder.env` qui ne liste pas exactement les sept variables d'AD-9, ou `.env.example` qui ne liste pas exactement ces sept `HUGO_LEGAL_*` et les trois `GITEA_*` d'AD-24
**Quand** on lance les contrôles
**Alors** C18 échoue en affichant les **noms** trouvés et attendus ; aucune valeur n'est lue ni affichée.

- [ ] Le pilote et les deux fichiers d'environnement passent tels qu'ils sont commités.

### Story 3.7 : Career path check

En tant que Claire, CTO (UJ-1),
je veux que chaque cas publié soit rattaché à un poste publié,
afin de ne jamais trouver un cas orphelin ou un poste incohérent entre FR et EN.

**Couvre :** FR-2, FR-4, FR-11, FR-15, FR-36 · AD-18 · C19
**Dépendances :** 3.6
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** un cas publié sans clé `position`, ou dont la clé `position` ne désigne aucun poste publié **du même manifeste**, donc de sa langue
**Quand** on lance les contrôles
**Alors** C19 échoue en nommant le fichier et l'écart ; un cas en brouillon n'est pas concerné, et une valeur `[TODO` y est tolérée (AD-10).

**Étant donné** un poste ou une entrée de formation dont le `translationKey` diffère du nom de fichier, ou ne commence pas par `position-` ou `education-` (AD-18)
**Quand** on lance les contrôles
**Alors** C19 échoue en donnant le nom attendu ou le préfixe attendu.

**Étant donné** un poste dont `track` sort de `main`, `parallel`, dont `setup` sort des quatre valeurs, qui n'a ni `location` ni `setup` (FR-2), ou dont `company`, `role` ou `period` est vide (ajout décidé par Arnaud le 18/09/2026 : AD-18 les exige, la ligne C19 est complétée)
**Quand** on lance les contrôles
**Alors** C19 échoue en nommant la clé ; un brouillon peut porter ces valeurs en `[TODO`, jamais les laisser vides.

**Étant donné** une entrée de `content/education/` sans `title`, ou dont `kind` sort de `education`, `certification`, `language`
**Quand** on lance les contrôles
**Alors** C19 échoue en nommant la clé.

**Étant donné** deux postes du même `track`, ou deux entrées de formation du même `kind`, qui portent le même `order`
**Quand** on lance les contrôles
**Alors** C19 échoue en nommant les deux fichiers ; **les brouillons comptent** (décidé par Arnaud le 18/09/2026), un doublon se télescoperait à la publication.

**Étant donné** un `translationKey` en `[TODO`, même dans un brouillon
**Quand** on lance les contrôles
**Alors** C19 échoue : la tolérance des brouillons (AD-10) porte sur les **valeurs de contenu**, jamais sur les **clés d'identité** — le `translationKey` est égal au nom du fichier et sert à la parité C3 (décidé le 18/09/2026, en réponse à la quatrième revue de la PR n° 42).

**Étant donné** une valeur d'encart ou de poste faite uniquement d'espaces
**Quand** on lance les contrôles
**Alors** elle est traitée comme absente (report de la story 3.6, fermé ici).

- [ ] `[TODO` dans un fichier publié reste l'affaire de C5, qui couvre déjà tout `content/` : la ligne C19 de l'architecture perd ce doublon.
- [ ] Les `_index` techniques, de rôle `section`, n'entrent dans aucune de ces règles.
- [ ] Le pilote et `position-chiliz`, tous deux en brouillon avec `[TODO`, passent.

### Story 3.8 : Zero JavaScript, no third party, no TODO

En tant que lectrice ou lecteur,
je veux qu'aucune page n'exécute de script ni ne charge de ressource d'un autre site,
afin de lire sans cookie ni traçage.

**Couvre :** NFR-3, NFR-12, FR-14, FR-17, FR-26, FR-35, SM-6 · AD-8, AD-10, AD-20 · C10, C5 (sortie)
**Dépendances :** 3.7
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le build de production de contrôle
**Quand** `scripts/checks/html.sh` s'exécute, seul ou par `scripts/check.sh` qui le découvre (AD-10)
**Alors** il signale, en nommant la page :

- toute balise `<script>` dont le `type` n'est pas exactement `application/ld+json`, y compris sans `type`, et toute balise `<script src>` ;
- tout attribut `on…` ;
- toute `<iframe>` et tout `<form>` ;
- toute ressource **chargée** depuis un autre hôte que celui du `baseURL` : attributs `src`, `srcset`, `poster`, `data`, et `<link>` dont la relation charge (`stylesheet`, `preload`, `icon`, `manifest`…) ;
- tout appel CSS vers un autre hôte (`url(…)`, `@import`), que XPath ne voit pas ;
- toute occurrence de `[TODO` dans les fichiers de texte publiés (`.html`, `.xml`, `.css`, `.txt`, `.json`).

**Étant donné** les `hreflang` absolus vers le site lui-même (AD-2) et un lien `<a href>` vers un site tiers
**Quand** le contrôle s'exécute
**Alors** ni l'un ni l'autre n'est signalé : une déclaration ne charge rien, un lien non plus. Le premier a été constaté en faux positif sur la production réelle avant correction.

**Étant donné** le bloc JSON-LD
**Quand** le contrôle s'exécute
**Alors** il échoue s'il y en a plus d'un, s'il apparaît ailleurs que sur `index.html` d'une langue, si son contenu n'est pas un JSON valide (`jq`), si son `@type` n'est pas `Person`, ou s'il porte une clé hors de FR-35 (`@context`, `@type`, `name`, `alternateName`, `jobTitle`, `address`, `url`, `sameAs`)
**Et** l'absence de bloc passe : la règle est « au plus un » jusqu'à la story 9.6, qui la passera à « exactement un » ; le script porte un commentaire à l'endroit exact où elle changera.

- [ ] Les attributs se lisent par XPath (`xmllint --html`), la sortie d'erreur de libxml2 étant écartée (AD-10) ; `grep` ne sert qu'aux chaînes.
- [ ] `xmllint` absent est une **anomalie** (code 2), jamais un contrôle muet ; il rejoint les prérequis du poste.

### Story 3.9 : Automated accessibility checks

En tant que lectrice ou lecteur au clavier ou avec un lecteur d'écran,
je veux que chaque page ait une structure accessible,
afin de parcourir le site sans obstacle.

**Couvre :** NFR-4, SM-8 · AD-17 · C11
**Dépendances :** 3.8
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le build de production de contrôle
**Quand** C11 s'exécute dans `scripts/checks/html.sh` sur chaque page, 404 comprises
**Alors** il signale, en nommant la page :

- `<html lang>` absent (3.1.1) ;
- `<title>` vide (2.4.2), ou sans la ligne d'identité — **sauf l'accueil**, qui en est exempté depuis AD-2 (story 2.2) parce que son titre porte déjà le nom ;
- aucun `<h1>`, ou plus d'un (1.3.1) ;
- un saut de niveau de titre, `h2` suivi de `h4` (1.3.1) ;
- un identifiant en double (4.1.1) ;
- une `<img>` sans `alt` non vide (1.1.1), ou sans `width` ni `height` (CLS, AD-17) ;
- un lien sans nom accessible, c'est-à-dire sans texte, sans `aria-label`, sans `title` et sans image au `alt` non vide (2.4.4) ;
- aucun `link rel="alternate" hreflang"` (AD-2) ;
- un `tabindex` positif (2.4.3) ; `tabindex="0"` reste permis, il rend un conteneur focalisable.

**Étant donné** la ligne d'identité
**Quand** le contrôle en a besoin
**Alors** il la lit dans le manifeste du rendu de travail (`front_matter.identity` de l'accueil, AD-19), jamais écrite en dur ; son absence est une anomalie (code 2), pas un contrôle muet.

**Étant donné** des fixtures HTML qui introduisent chaque défaut à tour de rôle
**Quand** on lance `scripts/tests/run.sh`
**Alors** chaque défaut est signalé, et son pendant conforme accepté ; aucun essai ne touche `content/`.

- [ ] Les 404 portent leurs `hreflang` (constaté) : aucune exemption n'est nécessaire.

### Story 3.10 : Internal links, anchors and orphan pages

En tant que Claire, CTO (UJ-1),
je veux que tout lien mène quelque part et que toute page soit atteignable,
afin de ne jamais tomber sur une page absente.

**Couvre :** FR-2, FR-15, SM-3 · AD-3, AD-4, AD-18, AD-21 · C12
**Dépendances :** 3.9
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le build de production de contrôle (AD-10 : les contrôles HTML ne portent pas sur le rendu de travail, qui contient des brouillons volontairement non liés)
**Quand** `scripts/checks/links.sh` s'exécute
**Alors** il signale tout lien interne vers un fichier absent, en donnant la cible résolue, et tout fragment qui ne correspond à aucun identifiant de la page visée — notamment `#case-NN`, `#<translationKey>-<rubrique>` et `#position-<id>`, sans qu'aucune de ces formes soit écrite dans le script
**Et** les liens externes, `mailto:` et `tel:` sortent du périmètre.

**Étant donné** une page de `public/` qu'aucun chemin de liens ne relie à l'accueil de sa langue
**Quand** le contrôle s'exécute
**Alors** il la signale, y compris si elle est liée depuis une autre page elle-même orpheline (parcours en largeur depuis les accueils, jamais un simple comptage de liens entrants)
**Et** les deux pages 404 en sont exemptées : nginx les sert sur une URL inconnue (AD-13).

**Étant donné** les liens conditionnels
**Quand** le contrôle s'exécute
**Alors** il signale un lien de CV alors que les deux PDF ne sont pas publiés, l'absence de lien alors qu'ils le sont (AD-21), et une `params.source_url` renseignée vers laquelle aucune page ne mène.

**Étant donné** le pilote et le `_index` Chiliz en brouillon (AD-4, D-3)
**Quand** le contrôle s'exécute
**Alors** aucune page Chiliz n'existe dans `public/` et C12 passe. Le repli d'AD-4 n'a pas lieu d'être : le constat de la story 2.5 a tenu.

- [ ] C12 juge la **cohérence des liens** de CV ; C21 jugera les **fichiers** PDF. Les deux ne se recouvrent pas.

### Story 3.11 : Page weight and element budget

En tant que lectrice ou lecteur sur mobile,
je veux que chaque page reste légère,
afin qu'elle s'affiche vite.

**Couvre :** NFR-5, SM-8 · AD-8 · C13
**Dépendances :** 3.10
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le build de production de contrôle, mesuré en octets non compressés, **1 Ko valant 1 000 octets** (décidé par Arnaud le 19/09/2026 : l'unité des navigateurs et de PageSpeed, celle de la mesure de mise en ligne)
**Quand** `scripts/checks/budget.sh` s'exécute
**Alors** il signale, en donnant la mesure et le plafond :

- un HTML de page de plus de 50 000 octets ;
- une CSS de plus de 20 000 octets pour tout le site, fichiers additionnés ;
- un SVG de plus de 60 000 octets ;
- une page complète — le document, la CSS et les médias qu'il charge — de plus de 200 000 octets ;
- plus de 10 ressources chargées par une page, le document lui-même n'en étant pas une ;
- plus de 800 éléments HTML dans une page ;
- tout fichier JavaScript ou de police dans la sortie, référencé ou non ;
- toute ressource chargée mais absente de la sortie.

**Étant donné** une image déclinée en 1x et 2x
**Quand** le poids de la page est calculé
**Alors** elle ne compte qu'une fois, par sa **variante la plus lourde** (décidé par Arnaud le 19/09/2026) : un navigateur n'en télécharge qu'une, et le budget doit refléter le pire cas réel. Chaque variante reste comptée comme ressource.

**Étant donné** un PDF de CV lié depuis une page
**Quand** le contrôle s'exécute
**Alors** il ne pèse pas dans le budget : c'est un lien, pas une ressource chargée (AD-21).

- [ ] `check.sh` découvre le contrôle sans être modifié (story 3.2).

### Story 3.12 : Shared checks job

En tant qu'Arnaud, mainteneur,
je veux un seul script qui lance les contrôles dans le conteneur de contrôle, en local et dans les deux CI,
afin que Gitea et GitHub exécutent la même chose.

**Couvre :** FR-23, FR-28, NFR-7 · AD-1, AD-10, AD-11, AD-12 · C1
**Dépendances :** 0.9, 3.11
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le poste de travail avec Docker
**Quand** on lance `scripts/ci/checks-job.sh`
**Alors** il lit `CHECK_IMAGE` dans `tools.env`, seule déclaration de l'image (AD-1), et lance `docker run --rm` sur cette image, le dépôt monté et pris pour répertoire de travail, avec l'UID et le GID de l'appelant
**Et** dans le conteneur, les outils sont posés par `scripts/ci/install-tools-bootstrap.sh` en root, puisque `apk` l'exige, puis le job **redescend au compte de l'hôte** par `su-exec` pour la suite : `check-private.sh history`, `scripts/tests/run.sh` (tests des scripts, story 0.9), puis `scripts/check.sh`
**Et** les fichiers écrits dans le dépôt monté (`public/`, `build/`) appartiennent à l'appelant, jamais à root (décidé par Arnaud le 19/09/2026)
**Et** les valeurs légales sont les valeurs factices de `ci/legal-placeholder.env`, chargées par `scripts/env.sh` dans le seul processus du conteneur ; le `.env` du poste, monté avec le dépôt, n'est pas lu
**Et** tout échec rend un code non nul.

**Étant donné** un clone jetable où un commit fait sans hook ajoute un fichier sous `docs/private/`
**Quand** le garde-fou tourne en mode historique dans ce clone
**Alors** C1 échoue en nommant le commit et le chemin : un test hors ligne de `scripts/tests/` le vérifie sans Docker, et la recette du job complet est consignée dans `docs/procedures/checks-job.md` (décidé par Arnaud le 19/09/2026).

- [ ] Le job ne lit aucun secret et ne construit aucune image.
- [ ] `scripts/ci/install-tools.sh` pose dans l'image `git` et `jq`, dont dépendent `check-private.sh` et `scripts/tests/run.sh` (ajouté après la revue de spec de la story 0.9), et `su-exec`, qui rend la main au compte de l'hôte (ajouté après la revue de spec de cette story).

### Story 3.13 : Checks workflow on main forge

En tant qu'Arnaud qui ouvre une PR (UJ-4),
je veux que chaque PR et chaque push sur `dev` et sur `main` lancent les contrôles sur la forge,
afin qu'aucun écart n'arrive sur `dev` ni sur `main`.

**Couvre :** FR-23, FR-28 · AD-11
**Dépendances :** 3.12
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, administration Gitea : runner x86_64 déclaré avec un label **en mode hôte**, dont l'utilisateur accède au démon Docker ; `[actions] WORKFLOW_DIRS` à sa valeur par défaut ; version du runner (2.0.0 au minimum).

**Critères d'acceptation :**

**Étant donné** `.gitea/workflows/checks.yaml`
**Quand** on le lit
**Alors** il ne contient que les déclencheurs (`push` sur `dev` et sur `main`, `pull_request`, comme le fixe AD-11), le checkout avec `fetch-depth: 0` et l'appel de `checks-job.sh`, sur le label en mode hôte.

**Étant donné** une PR sur la forge
**Quand** elle est ouverte, puis fusionnée
**Alors** chaque événement lance exactement un run ; une PR qui retire une rubrique EN du pilote échoue et nomme le fichier.

**Questions à poser avant de commencer :**
- Nom exact du label en mode hôte, fixé dans WS-4 (l'architecture cite `linux_amd64:host` en exemple) ?

### Story 3.14 : Public checks workflow on GitHub

En tant que Sam, tech lead (UJ-3),
je veux voir sur GitHub les exécutions publiques des contrôles,
afin de vérifier que la parité, les schémas et le garde-fou des chemins sont contrôlés.

**Couvre :** FR-23, FR-28, UJ-3 · AD-11
**Dépendances :** 1.4, 3.13
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, si nécessaire : activer GitHub Actions sur le dépôt public.

**Critères d'acceptation :**

**Étant donné** `.github/workflows/checks.yaml`
**Quand** on le lit
**Alors** il se déclenche sur `push` et `workflow_dispatch`, tourne sur `ubuntu-24.04`, appelle `checks-job.sh` depuis la machine virtuelle (pas de conteneur de job), sans secret ni `docker build`, avec des actions tierces épinglées par SHA.

**Étant donné** un push sur `dev` de la forge
**Quand** le miroir le publie
**Alors** exactement un run a lieu sur Gitea et un sur GitHub (démonstration de WS-4), et Gitea n'exécute pas `.github/workflows/`.

- [ ] Le journal public ne contient ni secret ni motif privé ; C21 y tourne sans liste de motifs.

### Story 3.15 : Public repository case README

En tant que Sam, tech lead (UJ-3),
je veux que le README se lise comme un cas,
afin de comprendre comment le site a été cadré et construit.

**Couvre :** FR-30, FR-31, UJ-3 · AD-24, section « README-cas » de l'architecture
**Dépendances :** 0.2, 3.14
**Bloquée par :** —
**Prérequis de contenu :** relecture par Arnaud de la voix et des faits du premier jet (D-12).
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** la rédaction du README
**Quand** le développeur écrit le premier jet
**Alors** il l'écrit en anglais à partir des seuls documents publics (PRD UJ-3 et FR-30, AD-12, AD-24, historique git, branches `design/*` et `experiment/d2-bilingue`), sans source privée, puis Arnaud relit la voix et les faits (D-12).

**Étant donné** `README.md` à la racine
**Quand** Sam le lit sur GitHub
**Alors** il est en anglais et suit la structure des cas : contexte, problème, la solution facile et pourquoi elle a été écartée, ce qui a été décidé, ce qui a résisté, résultat
**Et** « ce qui a résisté » raconte les sources privées repérées avant publication, la réécriture de l'historique et l'ajout du garde-fou.

**Étant donné** les références du README
**Quand** Sam les suit
**Alors** elles mènent aux workflows, à `scripts/check.sh` et à la liste des contrôles, aux exécutions publiques, à l'architecture, aux artefacts de cadrage, à `docs/format-cas.md`, à `docs/measures/`, et aux branches `experiment/d2-bilingue`, `design/dossier-architecture` et `design/suisse`
**Et** il documente le modèle de branches linéaire : `feat/*`, `fix/*`, `chore/*` et `docs/*` en squash vers `dev`, `dev` vers `main` en fast-forward, `hotfix/*` depuis `main` par le skill `hotfix`, aucun merge commit.

- [ ] Aucun fichier privé nommé (nommer `docs/private/` est permis), aucune donnée de NFR-9 *(relecture)*.

### Story 3.16 : Green CI gate in verify-and-merge-pr

En tant qu'Arnaud, mainteneur,
je veux que la fusion d'une PR exige la CI verte dès que la CI existe,
afin que le verrou signalé « absent » depuis la story 0.7 devienne réel.

**Couvre :** FR-23, FR-28 · AD-11, AD-24
**Dépendances :** 0.7, 3.13
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** une PR dont le run `checks` de Gitea est en échec, en cours, ou absent pour le SHA de tête
**Quand** on lance `verify-and-merge-pr --merge`
**Alors** la fusion est refusée et le verrou nomme l'état du run.

**Étant donné** une PR dont le run `checks` est vert sur le SHA de tête et dont les autres verrous passent
**Quand** on lance `--merge`
**Alors** la PR est fusionnée selon sa base (squash vers `dev`).

**Étant donné** `.gitea/workflows/checks.yaml` présent sur la base de la PR
**Quand** aucun statut de CI n'existe pour le SHA de tête
**Alors** l'état `absent` bloque la fusion : la règle d'amorçage ne s'applique plus (D-1).

- [ ] La procédure `docs/procedures/verify-and-merge-pr.md` ne décrit plus l'état `absent` qu'au titre de la règle d'amorçage.

### Story 3.17 : Publish-case skill

En tant qu'Arnaud, mainteneur,
je veux qu'un cas passe tous ses contrôles puis passe en `draft: false` dans une PR, toujours de la même façon,
afin de publier un cas sans oublier un contrôle.

**Couvre :** FR-25, FR-26, FR-32 · AD-10, AD-18, AD-24 · C3 à C8, C16, C18, C19
**Dépendances :** 0.4, 3.12
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `scripts/publish-case.sh <translationKey>` sur un cas en brouillon
**Quand** un contrôle échoue (format, parité, stack, rattachement au poste, garde-fou) ou qu'un `[TODO` reste
**Alors** le script s'arrête sans rien modifier et nomme l'écart.

**Étant donné** un cas qui passe tout
**Quand** le script s'exécute
**Alors** il passe les deux fichiers du cas en `draft: false` et ajoute à `ci/release-pages.txt` le `translationKey` du cas et, pour un cas groupé, `group-<group>` s'il n'y figure pas (D-5), dans le même commit, sur une branche `feat/*`, relance `scripts/check.sh` et ouvre la PR par `create-pull-request`.

- [ ] Le script ne publie jamais le poste du cas à sa place : un poste en brouillon fait échouer C19, et le script le signale.
- [ ] Pour un cas groupé, le script ne publie pas non plus le `_index` du groupe : un `_index` encore en brouillon est signalé (AD-4).
- [ ] SKILL.md et `docs/procedures/publish-case.md` suivent le principe des trois niveaux.

**Questions à poser avant de commencer :**
- La relecture humaine qu'exige le format avant `draft: false` est-elle une confirmation demandée par le script, ou une case de la PR ?

## Epic 4 : Image du site servie par nginx (WS-5)

Le build de production est emballé dans une image nginx et servi localement, avec ses en-têtes, son cache, ses 404 par langue et des journaux sans donnée personnelle.

### Story 4.1 : Multi-stage site image

En tant qu'Arnaud, mainteneur,
je veux une image qui ne contient que le site construit et contrôlé,
afin de servir exactement ce qui a passé les contrôles.

**Couvre :** NFR-1, NFR-2, NFR-7, NFR-9 · AD-1, AD-5, AD-9, AD-13
**Dépendances :** 3.12
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le `Dockerfile`
**Quand** on le lit
**Alors** il enchaîne `tools` (`CHECK_IMAGE`, `install-tools.sh`), `build` (une seule instruction `RUN --mount=type=secret,id=legal_env,required=true` qui lance `ENV_MODE=release LEGAL_ENV_FILE=/run/secrets/legal_env scripts/build.sh production` puis `scripts/check.sh` au niveau `CHECK_LEVEL`, puis `chmod -R a+rX public`) et `runtime` (`nginx:1.30.4-alpine` par digest, copie de `public/`).

**Étant donné** un build d'image sans secret, puis avec un fichier dotenv en secret
**Quand** il s'exécute
**Alors** le premier échoue ; le second réussit sans aucune valeur légale dans `docker history`, et l'image ne contient que les fichiers de `public/`.

**Étant donné** une copie locale qui fait échouer un contrôle
**Quand** on construit l'image
**Alors** le build d'image échoue.

- [ ] `.dockerignore` exclut au moins `.git/`, `.env`, `docs/private/`, `_bmad*/`, `.claude/`, `.agent*/`, `experiments/`, `public/`, `build/`.

**Questions à poser avant de commencer :**
- Pour la démonstration locale, quel fichier passer en secret ? `ENV_MODE=release` refuse le fichier factice et `.env` comme `LEGAL_ENV_FILE` : faut-il un fichier local de test hors dépôt ?

### Story 4.2 : Nginx headers, cache, 404 and IP-free logs

En tant que lectrice ou lecteur,
je veux des réponses sûres, bien mises en cache, une erreur dans ma langue, et aucun enregistrement de mon adresse,
afin de lire le site vite et sans être tracé.

**Couvre :** NFR-3, NFR-5, NFR-12, FR-19, FR-21 · AD-13, AD-15 (conteneur)
**Dépendances :** 4.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le conteneur lancé en local
**Quand** on lance `curl -I` sur une page HTML
**Alors** la réponse porte `X-Content-Type-Options`, `Referrer-Policy`, la CSP exacte d'AD-13 et `Cache-Control: no-cache`, sans `Set-Cookie`.

**Étant donné** un fichier empreinté (`css`, `svg` ou `webp`)
**Quand** on lance `curl -I`
**Alors** la réponse porte `Cache-Control: public, max-age=31536000, immutable` et les en-têtes communs, **sans** CSP.

**Étant donné** une URL absente sous `/` puis sous `/en/`
**Quand** on la demande
**Alors** la 404 sert `/404.html` puis `/en/404.html`, avec les en-têtes (`always`) (démonstration de WS-5).

**Étant donné** une requête avec chaîne de requête, user-agent et referer
**Quand** on lit le journal du conteneur
**Alors** la ligne ne contient que date, méthode, `$uri`, statut et taille.

- [ ] `server_tokens off; absolute_redirect off; log_not_found off;` ; `error_log /dev/stderr crit;` ; aucun module `realip` ; `gzip` pour HTML, CSS, SVG, JSON, XML ; `no-cache` pour les PDF.

**Questions à poser avant de commencer :**
- Aucun SVG n'existe avant un schéma « prêt » (Q1) : la CSP absente se vérifie-t-elle sur un CSS ou un WebP, puis de nouveau à la story 13.4 ?

## Epic 5 : Design validé et accueil CV

Claire lit sur son téléphone, en clair ou en sombre, un accueil qui est un CV : identité, photo, parcours avec les cas par poste, « En parallèle », formation. Toutes les stories dépendent de `DESIGN.md` et `EXPERIENCE.md`, validés le 13/09/2026 ; aucune n'est bloquée.

### Story 5.1 : Design tokens, typography and dark mode

En tant que Claire, CTO (UJ-1),
je veux un site sobre et lisible, en clair comme en sombre,
afin de lire le CV et les cas sans effort, quel que soit le réglage de mon téléphone.

**Couvre :** NFR-4, NFR-5, NFR-6, NFR-12, NFR-13, SM-8 · AD-8, AD-17 · C10, C11, C13 · UX-DR1 à UX-DR6, UX-DR17, UX-DR21
**Dépendances :** 3.11 ; `DESIGN.md` et `EXPERIENCE.md`
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `DESIGN.md`
**Quand** la story est livrée
**Alors** ses tokens de couleur (clair et sombre), ses piles de polices, son échelle typographique, son échelle d'espacement et sa grille (gouttière, mesure, marge, note, cadres md et lg, points de rupture) sont traduits dans la seule feuille `assets/css/main.css`, minifiée et empreintée, en propriétés personnalisées, sans valeur absente de `DESIGN.md`.

**Étant donné** un navigateur en préférence sombre, puis claire
**Quand** on ouvre chaque gabarit existant
**Alors** le mode suit `prefers-color-scheme` en CSS pur, avec `color-scheme: light dark`, sans JavaScript ni bouton.

**Étant donné** les gabarits existants (accueil minimal, page Chiliz, 404)
**Quand** on les affiche
**Alors** ils portent l'en-tête commun (marque vers l'accueil, sélecteur de langue en dernier), le lien d'évitement vers `#content`, les liens soulignés, l'anneau de focus (couleur système en `forced-colors`), et le pied de page commun, conformes aux composants de `DESIGN.md`.

**Étant donné** le build de production
**Quand** C10, C11 et C13 s'exécutent
**Alors** ils passent, avec une CSS totale ≤ 20 Ko et aucun fichier de police.

**Étant donné** chaque gabarit existant, en clair puis en sombre
**Quand** on déroule la check-list d'AD-17
**Alors** WCAG 2.2 AA est tenu dans les deux modes (contraste mesuré, focus visible et non masqué, cibles de 24 px, reflow à 320 px, zoom à 200 %), et 320 px ne provoque aucun défilement horizontal.

- [ ] Pas de césure automatique ; `text-wrap` et `overflow-wrap` selon `DESIGN.md`.
- [ ] Les liens « À propos », « Contact », mentions légales, confidentialité, code source et CV de l'en-tête et du pied de page sont ajoutés par les stories qui créent ces cibles (9.1 à 9.5, 7.2), pour qu'aucun lien ne pointe vers une page absente (C12).

**Questions à poser avant de commencer :**
- Libellé `skip_to_content` (« à valider » dans `EXPERIENCE.md`) ?
- Où noter les mesures de contraste faites dans les deux modes ?

### Story 5.2 : CV home page template

En tant que Claire, CTO (UJ-1),
je veux voir en haut qui est Arnaud, puis ses postes du plus récent au plus ancien avec les cas qui les prouvent,
afin de passer le test des trente secondes et d'ouvrir une preuve en un clic.

**Couvre :** FR-1, FR-2, FR-4, FR-15, FR-20, FR-25, FR-33, FR-37, SM-1, SM-3 · AD-3, AD-18, AD-19, AD-17 · UX-DR3, UX-DR7, UX-DR8, UX-DR18
**Dépendances :** 5.1 ; `DESIGN.md` (« Accueil (CV) », `identity-block`, `cv-position`, `attached-case`)
**Bloquée par :** —
**Prérequis de contenu :** — (démonstration sur `position-chiliz` en brouillon et des copies locales non commitées)
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `layouts/home.html`
**Quand** l'accueil est rendu
**Alors** l'ordre du DOM est : ligne d'identité (`h1`, nom puis « · Eleyone »), titre du site, « Basé en France », pitch s'il existe, bloc « Parcours » (postes `track: main` par `order`), bloc « En parallèle » (postes `track: parallel`), emplacement du bloc formation (story 5.3)
**Et** les libellés des blocs viennent d'`i18n/` (`block_career`, `block_parallel`).

**Étant donné** un poste avec cas publiés (copie locale)
**Quand** on l'affiche
**Alors** il montre période, société (`h3`), rôle puis, dans cet ordre, `location`, cadre et `via` s'ils existent, puis la liste des cas (numéro « Cas 02 » et titre en lien, sans « En bref »), marquée par la barre de révision ; son corps n'est pas affiché.

**Étant donné** un poste sans cas publié
**Quand** on l'affiche
**Alors** il montre ses champs puis son corps éventuel, sans zone de cas, barre de révision, tiret ni mention d'absence.

**Étant donné** le poste `position-ton-pote-le-geek` en `track: parallel` (copie locale)
**Quand** on l'affiche
**Alors** il est dans « En parallèle », et le nom de Ton Pote le Geek est un lien vers son site.

**Étant donné** l'accueil sur 390 × 844 px, avec un pitch de test de trois phrases en copie locale
**Quand** la page s'ouvre sans défilement, en FR et en EN, avec Charter puis une serif de repli large
**Alors** on voit la ligne d'identité, le titre, le pitch et le début du premier poste avec le lien de son premier cas (FR-37).

- [ ] Accueils FR et EN : mêmes postes, même ordre, mêmes liens (FR-20).
- [ ] Aucune période calculée par le gabarit ; ordre par `order` seulement.
- [ ] Check-list d'AD-17 sur l'accueil, en clair et en sombre.

**Questions à poser avant de commencer :**
- Nom accessible de la liste des cas d'un poste (`cases_of_position`, « à valider ») ?
- Format du libellé `via` (« prestation Modis » / *via Modis*) : texte i18n autour de la valeur ?

### Story 5.3 : Education, certification and languages template

En tant que Claire, CTO (UJ-1),
je veux voir la formation, les certifications et les langues d'Arnaud après son parcours,
afin de compléter la lecture du CV.

**Couvre :** FR-25, FR-36 · AD-18 · C19 · UX-DR9
**Dépendances :** 5.2
**Bloquée par :** —
**Prérequis de contenu :** — (démonstration sur des copies locales)
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `content/education/_index.{fr,en}.md` (jamais rendu) et des entrées `education-<id>` en copie locale
**Quand** l'accueil est rendu
**Alors** le bloc « Formation, certification, langues » suit « En parallèle », regroupe les entrées par `kind` (`education`, `certification`, `language`) puis par `order`, avec un sous-titre par nature, `title`, `institution`, `period` et `level` quand ils existent.

**Étant donné** une entrée en brouillon
**Quand** on lance le build de production
**Alors** elle n'apparaît pas, et un bloc sans aucune entrée publiée n'est pas rendu.

- [ ] Aucun fichier de `content/education/` ne produit de page.
- [ ] Check-list d'AD-17 sur l'accueil.

**Questions à poser avant de commencer :**
- Libellés `education_kind_*` (« à valider » dans `EXPERIENCE.md`) ?
- Un bloc sans entrée publiée doit-il vraiment disparaître ? Les documents disent seulement « ne rien écrire pour ce qui n'existe pas ».

### Story 5.4 : Photo preparation and image check

En tant qu'Arnaud, mainteneur,
je veux préparer la photo par un seul script et vérifier qu'aucune métadonnée ne subsiste,
afin que ni l'original ni ses données de prise de vue n'arrivent sur le dépôt public.

**Couvre :** FR-34, NFR-5, NFR-9, SM-5 · AD-19 · C20 · UX-DR10
**Dépendances :** 2.1, 3.12
**Bloquée par :** —
**Prérequis de contenu :** — (démonstration sur une image de test porteuse d'EXIF et de GPS, créée hors dépôt)
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `scripts/photo/prepare.sh <original> <ancrage>` et une image de test avec EXIF et GPS
**Quand** on le lance avec l'ancrage `Top`, puis avec `Smart`, puis sans ancrage
**Alors** le premier écrit `assets/images/portrait.webp` en 640 × 800 (4:5), ≤ 150 Ko, par le Hugo épinglé sur un mini-projet temporaire hors dépôt ; les deux autres échouent.

**Étant donné** `_partials/portrait.html` avec l'emplacement `home`, puis `about`
**Quand** il est rendu
**Alors** il produit les variantes WebP empreintées d'AD-19 (120 × 150 et 240 × 300, puis 160 × 200 et 320 × 400) en `srcset` 1x/2x, avec `width`, `height` (taille 1x) et `alt`.

**Étant donné** `scripts/checks/images.sh`
**Quand** une image de `assets/images/` ou de `public/` contient `Exif`, XMP, `GPS` ou un bloc `VP8X`, qu'une variante sort des dimensions d'AD-19 ou dépasse 40 Ko, que la copie n'est pas en 640 × 800 ou dépasse 150 Ko, ou qu'une photo publiée n'a pas d'`alt`
**Alors** C20 échoue ; il tourne sur les deux forges.

**Étant donné** le hook `pre-receive` de la forge, qui refuse les extensions d'images depuis la story 1.5, et C20 désormais écrit
**Quand** C20 est appelé par le hook sur les images d'un push, comme C21 l'est pour les PDF
**Alors** une image porteuse de métadonnées est refusée **avant publication**, et l'interdiction temporaire des extensions d'images est levée (AD-12, AD-19 ; procédure du hook, étape 7)
**Et** l'outil de lecture des métadonnées nécessaire est présent dans l'environnement où tourne Gitea, comme `poppler-utils` pour les PDF.

- [ ] Aucun autre outil d'image n'est ajouté ; l'image de test n'est pas commitée.

**Questions à poser avant de commencer :**
- Faut-il une image de test commitée sous `tests/fixtures/` (sans métadonnée, donc sans valeur de démonstration pour C20), ou une image générée à la volée ?

### Story 5.5 : Photo published on home page

En tant que Claire, CTO (UJ-1),
je veux voir la photo d'Arnaud à côté de son nom,
afin de mettre un visage sur le CV.

**Couvre :** FR-34, FR-37, NFR-5 · AD-19 · C13, C20 · UX-DR7, UX-DR10
**Dépendances :** 5.2, 5.4
**Bloquée par :** —
**Prérequis de contenu :** photo originale d'Arnaud, hors dépôt ; `portrait_alt` FR et EN.
**Opération manuelle (Arnaud) :** **oui**, Arnaud lance `scripts/photo/prepare.sh` sur l'original, choisit l'ancrage et vérifie le cadrage à l'œil (visage et épaules, composition de `DESIGN.md`) ; l'original ne passe jamais sous le dossier du dépôt.

**Critères d'acceptation :**

**Étant donné** la copie `assets/images/portrait.webp` produite par le script
**Quand** elle est commitée
**Alors** C20 passe, et le push passe le hook.

**Étant donné** l'accueil FR et EN
**Quand** on l'affiche
**Alors** la photo est à droite du nom sous md et dans la colonne de marge dès md, aux tailles de `DESIGN.md`, avec `portrait_alt` dans la langue de la page
**Et** le critère 390 × 844 de FR-37 reste tenu, et la page reste dans le budget (C13).

- [ ] Si une variante dépasse 40 Ko, sa qualité baisse (règle de `DESIGN.md`), jamais sa taille, et AD-19 le consigne.

## Epic 6 : Pages de cas mises en forme et typographie française

Claire lit un cas mis en page selon `DESIGN.md` : « Contexte mission » en note de marge, sommaire, rubriques numérotées, retour au parcours. Les pages françaises suivent la typographie française.

### Story 6.1 : Styled Chiliz page

En tant que Claire, CTO (UJ-1),
je veux une page Chiliz composée comme un dossier technique,
afin de trouver en quelques secondes le contexte, le résumé et la décision.

**Couvre :** FR-5 à FR-9, FR-15, NFR-4 · AD-3, AD-4, AD-17 · UX-DR3, UX-DR11, UX-DR12, UX-DR18
**Dépendances :** 5.1 ; `DESIGN.md` (« Page Chiliz », `context-box`, `summary-box`, `toc`, `rubric-heading`)
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** la page Chiliz en rendu de travail
**Quand** on l'affiche sous md, en md, puis en lg
**Alors** « Contexte mission », « En bref », le sommaire, les numéros de rubrique et le lien « Retour au parcours » suivent la disposition de `DESIGN.md` pour chaque point de rupture
**Et** « Contexte mission » reste avant « En bref » dans le DOM quelle que soit sa place visuelle.

**Étant donné** une ancre `#case-02` ou de rubrique
**Quand** Claire la suit
**Alors** la cible est marquée par `:target` et ne colle pas au bord de la fenêtre.

**Étant donné** l'arrivée sur `#case-02` à 390 × 844
**Quand** la page s'ouvre
**Alors** on voit le titre du cas, « Contexte mission » et le début de « En bref » (objectif de conception d'`EXPERIENCE.md`, check-list).

- [ ] Sous md, le sommaire est un `<details>` fermé ; dès md, visible et collant dans la marge, sans recouvrir le texte.
- [ ] Check-list d'AD-17 sur la page de groupe, en clair et en sombre.

### Story 6.2 : Ungrouped case page

En tant que Claire, CTO (UJ-1),
je veux qu'un cas sans groupe ait sa page, avec les mêmes encarts et le même retour au parcours,
afin de lire les cas 01, 05 et 06 comme le cas 02.

**Couvre :** FR-5, FR-15 · AD-3, AD-4, AD-18 · UX-DR11, UX-DR12
**Dépendances :** 6.1
**Bloquée par :** —
**Prérequis de contenu :** — (démonstration sur une copie locale non commitée)
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** une copie locale d'un cas sans groupe
**Quand** on lance le rendu de travail
**Alors** le cas est rendu à `/cas/<slug>/` et `/en/cases/<slug>/` par `layouts/cases/page.html`, avec le même `_partials/case.html` au niveau de titre 1
**Et** ses `##` sont rendus en `<h2>`, numérotés « NN.r », avec numéro de cas dans la marge dès md et « Retour au parcours » vers son poste.

- [ ] La copie locale est supprimée ; seul le gabarit est commité.
- [ ] Check-list d'AD-17 sur la page de cas, en clair et en sombre.

### Story 6.3 : French typography applied at build

En tant que lectrice ou lecteur francophone,
je veux une ponctuation composée selon la typographie française,
afin de lire un texte soigné sans qu'Arnaud tape d'espaces insécables.

**Couvre :** FR-20, NFR-10 · AD-23 · C24 · UX-DR17
**Dépendances :** 6.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `_partials/typo-fr.html` appliqué au HTML rendu des pages FR (contenu, titres, encarts, libellés)
**Quand** le pilote est rendu
**Alors** l'espace ordinaire devant `;`, `!`, `?` devient une espace fine insécable, celle devant `:` une espace insécable, et celles à l'intérieur des « » une espace fine insécable, comme le prescrit `DESIGN.md`
**Et** aucune espace n'est insérée là où l'auteur n'en a pas mis.

**Étant donné** un bloc `<pre>`, un `<code>`, une URL ou un attribut contenant ces signes
**Quand** la page est rendue
**Alors** ils ne sont pas modifiés.

**Étant donné** `scripts/checks/typo.sh`
**Quand** une page FR garde une espace ordinaire devant ces signes hors `pre`, `code`, `script` et URL, qu'une page EN contient une espace insécable devant eux, ou que la CSS contient `hyphens: auto`
**Alors** C24 échoue ; il tourne sur les deux forges.

- [ ] Les pages EN ne passent jamais par le partial.

## Epic 7 : CV PDF, ensemble ou rien

Claire peut garder un CV en PDF dans sa langue ; aucun PDF contenant un téléphone ou une ville de résidence n'entre dans l'historique, et les liens n'apparaissent que si les deux fichiers ont passé leur contrôle.

### Story 7.1 : CV PDF check and pre-commit

En tant qu'Arnaud, mainteneur,
je veux qu'un script extraie le texte et les métadonnées de chaque CV PDF et les confronte à la liste des motifs,
afin qu'un PDF contenant un téléphone ou une ville de résidence soit refusé avant l'historique.

**Couvre :** FR-28, FR-38, NFR-9, SM-5 · AD-12, AD-21 · C21
**Dépendances :** 2.1, 3.12
**Bloquée par :** —
**Prérequis de contenu :** — (PDF de test générés hors dépôt ; aucun PDF commité)
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `scripts/checks/pdf.sh`
**Quand** `assets/cv/` ne contient aucun PDF, puis les deux, puis un seul
**Alors** il passe, passe, puis échoue.

**Étant donné** un PDF présent
**Quand** il n'a pas l'en-tête PDF, n'a aucune page ou dépasse 500 Ko
**Alors** C21 échoue.

**Étant donné** la liste des motifs disponible et un PDF de test dont le texte, les métadonnées (`pdfinfo`) ou le XMP (`pdfinfo -meta`) contiennent un motif factice
**Quand** le script s'exécute
**Alors** il échoue en nommant le fichier et la source (texte, métadonnée, XMP), sans recopier le motif.

**Étant donné** l'absence de liste des motifs (GitHub)
**Quand** le script s'exécute
**Alors** seules présence, en-tête, pages et taille sont vérifiées.

**Étant donné** `.githooks/pre-commit`
**Quand** un fichier de `assets/cv/` est indexé
**Alors** il lance `pdf.sh` avec la liste des motifs, en plus de `check-private.sh staged`.

- [ ] `assets/cv/*.pdf` reste un chemin interdit à l'issue de la story (AD-21).

**Questions à poser avant de commencer :**
- Tant que ce chemin est interdit, `check-private.sh staged` refuse déjà tout PDF indexé : le pre-commit se démontre-t-il sur un dépôt jetable où la règle est retirée ?

### Story 7.2 : Conditional CV links in footer

En tant que Claire, CTO (UJ-1),
je veux trouver dans le pied de page les deux CV, avec leur langue et leur taille,
afin d'en garder un sans chercher.

**Couvre :** FR-38, UJ-1 · AD-21 · C12, C21 · UX-DR6, UX-DR14
**Dépendances :** 5.1, 7.1
**Bloquée par :** —
**Prérequis de contenu :** — (démonstration avec des PDF de test non commités)
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `_partials/cv-links.html` et les deux PDF de test en local
**Quand** on construit le site
**Alors** le pied de page de chaque page, accueil compris, porte deux liens (le CV de la langue de la page en premier), avec `type="application/pdf"`, la taille lue au build et le libellé i18n `cv_pdf`, vers `/cv/cv-fr.pdf` et `/cv/cv-en.pdf`.

**Étant donné** un seul PDF, puis aucun
**Quand** on construit le site
**Alors** le partial n'émet rien : ni ligne, ni étiquette, ni mention.

- [ ] Aucun lien vers un CV dans l'en-tête ; C12 passe dans les trois cas.

**Questions à poser avant de commencer :**
- Libellés `cv_pdf` (« à valider » dans `EXPERIENCE.md`) ?

### Story 7.3 : PDF extraction in pre-receive hook

En tant qu'Arnaud, mainteneur,
je veux que la forge refuse côté serveur un PDF qui contient un motif,
afin de pouvoir commiter des CV PDF sans risque pour le dépôt public.

**Couvre :** FR-28, FR-38, NFR-9 · AD-12, AD-21, procédure « hook pre-receive » (étape 7) · C2, C21
**Dépendances :** 1.2, 7.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, Gitea tourne en Docker : construire une image dérivée de l'image Gitea en service (`apk add --no-cache poppler-utils`), la faire tourner à la place de l'officielle, et la reconstruire à chaque montée de version ; recopier le hook mis à jour. Le développeur prépare la modification de `check-private` et la liste de vérification.

**Critères d'acceptation :**

**Étant donné** le conteneur Gitea recréé depuis l'image dérivée
**Quand** l'utilisateur système de Gitea lance `pdftotext` et `pdfinfo`
**Alors** les deux commandes répondent.

**Étant donné** le hook qui extrait chaque PDF ajouté ou modifié (`git cat-file` vers un fichier temporaire) et lance `pdf.sh`
**Quand** Arnaud pousse sur une branche jetable un PDF factice contenant un motif de test ajouté temporairement à la liste
**Alors** le push est refusé, puis le motif de test est retiré.

**Étant donné** le test précédent réussi
**Quand** `assets/cv/*.pdf` est retiré des chemins interdits de `check-private.sh`
**Alors** le script est recopié sur le serveur et les tests de la story 1.2 repassent.

- [ ] L'image dérivée et sa reconstruction à chaque montée de version sont notées dans la procédure d'Arnaud, sans nom d'hôte.

### Story 7.4 : Publish CV PDFs

En tant que Claire, CTO (UJ-1),
je veux télécharger le CV d'Arnaud en PDF dans ma langue,
afin de le garder et de le transmettre.

**Couvre :** FR-38, NFR-9, SM-5 · AD-21 · C21
**Dépendances :** 7.2, 7.3
**Bloquée par :** —
**Prérequis de contenu :** deux CV PDF, FR et EN, **sans numéro de téléphone ni ville de résidence** dans le texte, les métadonnées ou le XMP. Les PDF actuels en contiennent : la publication reste bloquée jusqu'à la fourniture de versions conformes.
**Opération manuelle (Arnaud) :** **oui**, Arnaud fournit les deux fichiers et les commite.

**Critères d'acceptation :**

**Étant donné** `assets/cv/cv-fr.pdf` et `assets/cv/cv-en.pdf`
**Quand** ils sont indexés, poussés, puis contrôlés en CI
**Alors** le pre-commit, le hook pre-receive et C21 passent tous les trois.

**Étant donné** le build suivant
**Quand** on l'affiche
**Alors** les liens des deux CV apparaissent dans le pied de page de chaque page ; ils seront mis en évidence sur « À propos » par la story 9.4.

- [ ] Le job `release` rejouera C21 avec la liste des motifs à chaque mise en ligne (story 11.3).

## Epic 8 : Schémas D2 à double thème, régénérés et vérifiés

Un schéma bilingue suit le mode du lecteur (ou son repli validé), et la CI refuse tout SVG désynchronisé. Le spike passe avant toute story du pipeline (AD-7).

### Story 8.1 : Dual-theme D2 spike

En tant qu'Arnaud, mainteneur,
je veux savoir si un SVG D2 qui embarque les deux thèmes tient dans `<img>`, reste déterministe et reste léger,
afin de choisir, preuve à l'appui, entre le double thème et le repli en planche claire.

**Couvre :** FR-13, NFR-8, NFR-13 · AD-7 · C9, C13 · UX-DR23
**Dépendances :** 2.1 ; `DESIGN.md` (« Accord avec les schémas D2 »)
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **possible**, si le test dans Safari demande un appareil d'Arnaud.

**Critères d'acceptation :**

**Étant donné** le schéma de test et un `theme.d2` de spike portant le thème clair et le thème sombre de départ de `DESIGN.md` (`dark-theme-id`, `dark-theme-overrides`), sans `--theme` ni `--dark-theme`
**Quand** le SVG est chargé par `<img>` dans Firefox, Chrome et Safari, en préférence claire puis sombre
**Alors** le résultat de chaque navigateur est noté.

**Étant donné** deux rendus successifs du même schéma
**Quand** on les compare avec `cmp`
**Alors** le résultat (identique ou non) est noté.

**Étant donné** le SVG produit
**Quand** on mesure sa taille
**Alors** le résultat face à 60 Ko est noté.

**Étant donné** les trois résultats
**Quand** l'un échoue
**Alors** la conclusion est le repli (thème clair seul, planche claire encadrée) ; sinon, le double thème. La conclusion est remise à Arnaud pour mise à jour d'AD-7 ; le spike ne commite aucun SVG de production.

**Questions à poser avant de commencer :**
- Où consigner le résultat du spike (note dans `docs/measures/`, PR, `.memlog.md` de l'architecture) ?

### Story 8.2 : D2 theme and bilingual demo diagram

En tant qu'Arnaud, mainteneur,
je veux rendre un schéma en un SVG français et un anglais par un script unique, avec le thème retenu,
afin de produire des schémas identiques à l'octet sur toutes les machines x86_64.

**Couvre :** FR-13, FR-27, NFR-8 · AD-1, AD-7 · UX-DR23
**Dépendances :** 8.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `diagrams/theme.d2`
**Quand** on le lit
**Alors** il porte les valeurs de `DESIGN.md` (N1 aligné sur `ink`), avec le thème sombre seulement si le spike 8.1 l'a validé.

**Étant donné** `tests/fixtures/diagrams/<id>/` (`structure.d2` à libellés en `${variables}`, sans bloc `vars` ; `fr.d2` et `en.d2` avec leur bloc `vars` puis `...@structure`)
**Quand** `scripts/diagrams/render.sh` s'exécute sur ce dossier
**Alors** il vérifie la version de D2, rend chaque langue avec `--omit-version --no-xml-tag --pad 24 --layout elk`, neutralise `D2_THEME`, `D2_LAYOUT`, `D2_PAD`, `D2_SKETCH`, écrit `<id>.fr.svg` et `<id>.en.svg`, puis applique `chmod 0644`.

**Étant donné** deux rendus successifs, dont un avec `D2_THEME` défini
**Quand** on les compare
**Alors** ils sont identiques.

- [ ] Les SVG de démonstration ne sont jamais publiés.

**Questions à poser avant de commencer :**
- Le schéma de démonstration reprend-il celui de la branche `experiment/d2-bilingue` ?

### Story 8.3 : SVG sync check

En tant qu'Arnaud, mainteneur,
je veux que la CI refuse tout SVG qui ne correspond plus à sa source,
afin que les schémas publiés soient toujours ceux des sources.

**Couvre :** FR-23, FR-27, NFR-8 · AD-7, AD-10 · C9
**Dépendances :** 8.2, 3.12
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `scripts/diagrams/check.sh`, appelé par `scripts/check.sh`
**Quand** un libellé change sans nouveau rendu, qu'un SVG manque ou n'a pas de source, ou que les clés `vars` de `fr.d2`, `en.d2` et les variables de `structure.d2` diffèrent
**Alors** C9 échoue en nommant le fichier.

**Étant donné** un dossier de `diagrams/` sans élément `diagram` déclaré dans un cas, ou un élément `diagram` « prêt » sans dossier
**Quand** on lance les contrôles
**Alors** C9 le signale.

**Étant donné** un SVG de plus de 60 Ko (les deux thèmes compris si retenus)
**Quand** on lance les contrôles
**Alors** C9 le signale.

- [ ] Les runs Gitea et GitHub passent sur les mêmes octets.

## Epic 9 : Pages légales, pages simples et données structurées

Un lecteur trouve, dans chaque langue, les mentions légales et la confidentialité depuis toute page, la page Contact et « À propos » depuis l'en-tête, le lien vers le dépôt ; les moteurs lisent l'identité d'Arnaud.

### Story 9.1 : Legal notice and confined address

En tant que lectrice ou lecteur,
je veux trouver depuis toute page des mentions légales complètes,
afin de savoir qui édite et qui héberge le site.

**Couvre :** FR-18, FR-33, NFR-9 · AD-9 · C23 · UX-DR6, UX-DR16, UX-DR21
**Dépendances :** 2.4, 3.10, 5.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `_partials/legal-value.html`
**Quand** une page de `translationKey` `legal-notice` lit une variable `HUGO_LEGAL_*`
**Alors** la valeur est rendue ; une valeur vide fait échouer le build en nommant la variable
**Et** toute lecture depuis une autre page (dont `<title>`, meta `description`, JSON-LD, sitemap, pied de page) fait échouer le build (`errorf`).

**Étant donné** `content/legal-notice.{fr,en}.md` et les valeurs factices
**Quand** on ouvre `/mentions-legales/` et `/en/legal-notice/`
**Alors** la page affiche, en `legal-list` : éditeur (nom, adresse dans un élément `address`, contact, immatriculation), directeur de la publication (libellé `legal_publication_director` et nom de l'éditeur), hébergeur (nom, adresse, contact), sans numéro de TVA.

**Étant donné** `scripts/checks/legal-address.sh`
**Quand** la valeur chargée de `HUGO_LEGAL_PUBLISHER_ADDRESS` apparaît hors du corps des deux pages des mentions légales, ou dans un `<title>`, une meta `description`, le JSON-LD ou `sitemap.xml`
**Alors** C23 échoue ; il tourne sur les deux forges.

**Étant donné** toute page
**Quand** on regarde son pied de page
**Alors** il porte le lien vers les mentions légales de sa langue.

- [ ] C3, C11, C12 passent ; check-list d'AD-17 sur la page simple, en clair et en sombre.
- [ ] `ci/release-pages.txt` gagne `legal-notice` (D-5).

**Questions à poser avant de commencer :**
- Les intitulés qui entourent les valeurs sont-ils rédigés par le développeur d'après FR-18, puis relus par Arnaud ?

### Story 9.2 : Privacy policy

En tant que lectrice ou lecteur,
je veux savoir, depuis toute page, ce que le site collecte,
afin de lire en sachant qu'aucune donnée personnelle n'est enregistrée.

**Couvre :** FR-19, NFR-3, NFR-9 · AD-15 · UX-DR6, UX-DR21
**Dépendances :** 9.1
**Bloquée par :** —
**Prérequis de contenu :** URL de la politique de confidentialité de l'hébergeur, écrite dans le texte de la page.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `content/privacy.{fr,en}.md`
**Quand** on ouvre `/confidentialite/` et `/en/privacy/`
**Alors** la page dit : aucun cookie ; vidéos en liens vers YouTube, site tiers ; aucune donnée personnelle collectée par l'éditeur ; renvoi, par un lien écrit dans le texte, à la politique de l'hébergeur.

**Étant donné** toute page
**Quand** on regarde son pied de page
**Alors** il porte le lien vers la politique de confidentialité de sa langue.

- [ ] Rien n'est affirmé au-delà de FR-19 *(relecture)* ; la véracité sur le proxy est vérifiée à la story 11.11.
- [ ] `ci/release-pages.txt` gagne `privacy` (D-5).

### Story 9.3 : Contact page and call to contact

En tant que Claire, CTO (UJ-1),
je veux atteindre depuis l'accueil et l'en-tête une page qui donne l'adresse mail et le LinkedIn d'Arnaud,
afin de le contacter sans formulaire.

**Couvre :** FR-3, FR-17, NFR-12, SM-3 · AD-3 · C3, C10, C12 · UX-DR5, UX-DR21
**Dépendances :** 5.2, 9.2
**Bloquée par :** —
**Prérequis de contenu :** adresse mail et URL LinkedIn (PRD §11.2).
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `content/contact.{fr,en}.md` avec `email` et `linkedin` identiques en FR et en EN, commités
**Quand** on ouvre `/contact/` et `/en/contact/`
**Alors** la page affiche l'introduction du contenu, puis une liste de définitions dont les valeurs sont des liens.

**Étant donné** l'en-tête de toute page
**Quand** on le lit
**Alors** il porte le lien « Contact », avec `aria-current="page"` sur la page Contact.

**Étant donné** l'accueil FR et EN
**Quand** Claire suit l'appel à contact
**Alors** elle arrive en un clic sur la page Contact de la même langue.

- [ ] Aucun formulaire (C10) ; la page n'est pas orpheline (C12).
- [ ] `ci/release-pages.txt` gagne `contact` (D-5).

**Questions à poser avant de commencer :**
- Libellés `block_contact` et `contact_cta` (« à valider » dans `EXPERIENCE.md`) ?
- La liste des motifs du garde-fou ne contient-elle ni l'adresse mail ni l'URL LinkedIn (sinon le push serait refusé) ?

### Story 9.4 : About page

En tant que Claire, CTO (UJ-1),
je veux lire en une page ce qu'Arnaud fait bien, ce qu'il ne veut pas être et comment il travaille, avec sa photo et ses CV,
afin de situer son profil.

**Couvre :** FR-16, FR-34, FR-38, NFR-9, NFR-10 · AD-19, AD-21 · C12, C20 · UX-DR5, UX-DR10, UX-DR13, UX-DR14, UX-DR21
**Dépendances :** 5.5, 7.2, 9.3
**Bloquée par :** —
**Prérequis de contenu :** texte de la page, FR et EN, rédigé par Arnaud.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `content/about.{fr,en}.md`
**Quand** on ouvre `/a-propos/` et `/en/about/`
**Alors** l'ordre est : titre, portrait (variante « À propos »), bloc CV en `note-block` s'il existe, puis le texte
**Et** le texte traite de ce qu'Arnaud fait bien, dit qu'il ne veut être ni manager, ni product owner, ni chef de projet, et qu'il utilise Claude Code au quotidien et prépare une certification Claude *(relecture)*.

**Étant donné** les deux CV PDF publiés, puis absents
**Quand** on construit le site
**Alors** le bloc CV est rendu avec les deux liens, puis n'est pas rendu du tout.

**Étant donné** l'en-tête de toute page
**Quand** on le lit
**Alors** il porte le lien « À propos ».

- [ ] Aucune donnée interdite par NFR-9, rien d'absent des sources *(relecture)* ; C3, C11, C12, C20 passent.
- [ ] `ci/release-pages.txt` gagne `about` (D-5).

### Story 9.5 : Conditional public repository link

En tant que Sam, tech lead (UJ-3),
je veux trouver dans le pied de page un lien vers le code source du site,
afin de voir comment le site a été construit.

**Couvre :** FR-29, UJ-3 · AD-3 · C12 · UX-DR6
**Dépendances :** 5.1
**Bloquée par :** —
**Prérequis de contenu :** — (l'URL est connue après la story 1.4)
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `params.source_url` vide
**Quand** on construit le site
**Alors** aucun lien vers le dépôt n'est rendu, ni lien factice, ni `#`.

**Étant donné** `params.source_url` renseigné
**Quand** on construit le site
**Alors** le pied de page de chaque page, en FR et en EN, porte le lien « Code source du site » / *Site source code*.

- [ ] C12 passe dans les deux cas.

**Questions à poser avant de commencer :**
- Libellés `footer_source` (« à valider » dans `EXPERIENCE.md`) ?

### Story 9.6 : Person structured data

En tant qu'Arnaud, mainteneur,
je veux que l'accueil décrive mon identité pour les moteurs de recherche, par des données seulement,
afin d'être trouvé sous mon nom sans ajouter de JavaScript.

**Couvre :** FR-35, NFR-9, NFR-12 · AD-3, AD-19, AD-20 · C3, C10
**Dépendances :** 3.8, 9.3
**Bloquée par :** —
**Prérequis de contenu :** URL du profil GitHub d'Arnaud ; intitulé `job_title` FR et EN.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `_partials/jsonld-person.html` sur l'accueil de chaque langue
**Quand** on construit le site
**Alors** l'accueil contient exactement un `<script type="application/ld+json">`, construit par `jsonify` à partir du contenu, avec les seules clés `@context`, `@type: Person`, `name`, `alternateName`, `jobTitle`, `address.addressCountry: FR`, `url` et `sameAs` (LinkedIn et GitHub)
**Et** aucune autre page n'en contient.

**Étant donné** les sources d'AD-20 (D-7)
**Quand** le bloc est construit
**Alors** `name` et `alternateName` viennent d'`identity`, `jobTitle` de la nouvelle clé `job_title` de `content/_index.{fr,en}.md` dans la langue du fichier, `url` de `baseURL`, et `sameAs` de `linkedin` et de la nouvelle clé `github` (URL du profil, identique en FR et en EN, comparée par C3) de `content/contact.{fr,en}.md`
**Et** un lien vide est omis de `sameAs`, jamais remplacé par une valeur factice.

**Étant donné** C10
**Quand** on lance les contrôles
**Alors** la règle « exactement un bloc conforme sur chaque accueil » est active et passe.

- [ ] Ni ville, ni téléphone, ni photo dans le bloc ; la CSP d'AD-13 est inchangée.

## Epic 11 : Mise en ligne, répétition générale et socle

La chaîne de mise en ligne est construite et répétée tôt sur le serveur de production, sans DNS : stories 11.1 à 11.9, placées avant l'Epic 10, dont elles ne dépendent pas (décision D-5). Après le contenu du socle, le test des trente secondes est passé, puis le socle est mis en ligne par le flux linéaire, derrière un proxy sans journal d'IP : stories 11.10 à 11.13, dans la section « Mise en ligne du socle » qui suit l'Epic 10.

### Story 11.1 : Release checks and expected pages

En tant qu'Arnaud, mainteneur,
je veux qu'une mise en ligne soit refusée si une page attendue manque ou si une trace de travail reste,
afin de ne jamais publier un socle incomplet.

**Couvre :** FR-9, FR-18, FR-26, FR-32 · AD-5, AD-10 · C15
**Dépendances :** 3.11, 9.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `ci/release-pages.txt`, liste cumulative des pages publiées attendues à ce commit, par `translationKey`, sans les CV PDF (créée à la story 2.2, D-5)
**Quand** on lance `scripts/check.sh --release`
**Alors** il échoue si une page de groupe est vide, si une page ou une section listée manque en FR ou en EN, ou si `VALEUR-FACTICE`, un `checks.json`, un `noindex` ou un `draft-marker` apparaît dans `public/`.

**Étant donné** l'état actuel (pilote en brouillon, valeurs factices)
**Quand** on lance `--release`
**Alors** il échoue et liste chaque écart.

- [ ] La complétude du socle n'est pas vérifiée ici : `release` la vérifie pour `v1.0.0` seulement (stories 11.7 et 11.11).

### Story 11.2 : Forbidden patterns on production output

En tant qu'Arnaud, mainteneur,
je veux confronter la sortie de production à la liste des motifs,
afin qu'aucune donnée privée n'apparaisse sur le site, hors valeurs injectées des mentions légales.

**Couvre :** FR-18, FR-33, NFR-9 · AD-9 · C22
**Dépendances :** 11.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `scripts/checks/output-patterns.sh`, la liste des motifs dans un fichier temporaire, et un build de production
**Quand** un motif factice apparaît dans une page autre que les mentions légales
**Alors** C22 échoue en nommant la page, sans recopier le motif.

**Étant donné** les pages des mentions légales
**Quand** un motif y apparaît contenu dans une valeur `HUGO_LEGAL_*` injectée, puis hors de ces valeurs
**Alors** C22 passe, puis échoue.

- [ ] Le fichier temporaire est supprimé en fin d'exécution ; C22 ne tourne que dans le job `release`.

### Story 11.3 : Release image build

En tant qu'Arnaud, mainteneur,
je veux construire l'image d'une mise en ligne avec les vraies valeurs légales et la liste des motifs passées en secret,
afin qu'aucune valeur n'apparaisse dans le dépôt, l'image ou une page périmée.

**Couvre :** FR-18, FR-38, NFR-9 · AD-9, AD-13, AD-14, AD-21 · C21, C22
**Dépendances :** 4.2, 7.1, 11.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** les sept `HUGO_LEGAL_*` et `PRIVATE_PATTERNS` dans l'environnement
**Quand** on lance `scripts/release/build-image.sh <tag>`
**Alors** il écrit des fichiers temporaires, construit `eleyone-site:<tag>` avec `--secret id=legal_env,src=<fichier>`, `CHECK_LEVEL=release` et `--no-cache-filter build`, lance C21 et C22 avec la liste des motifs, puis supprime les fichiers même en cas d'échec.

**Étant donné** une variable manquante, ou un tag qui ne suit ni `vX.Y.Z` ni `vX.Y.Z-rc.N`
**Quand** on lance le script
**Alors** il échoue avant le `docker build`.

**Étant donné** deux constructions avec une valeur légale modifiée entre les deux
**Quand** on sert la seconde image
**Alors** la page des mentions légales affiche la nouvelle valeur.

- [ ] Aucun `set -x` ; aucune valeur dans `docker history` ni dans les journaux.

### Story 11.4 : Forced deploy-site command and services

En tant qu'Arnaud, mainteneur,
je veux que le serveur de production n'accepte que des demandes précises, sur deux canaux séparés,
afin qu'une clé volée ne permette rien d'autre et qu'une répétition ne touche jamais la production.

**Couvre :** NFR-2, FR-32, FR-39 · AD-14, AD-15, AD-22
**Dépendances :** 4.2
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `deploy/remote/deploy-site.sh`, testé en local avec `SSH_ORIGINAL_COMMAND` simulé
**Quand** la demande est `deploy <tag>` avec un tag `vX.Y.Z` et l'archive sur l'entrée standard
**Alors** il charge l'image, vérifie son nom `eleyone-site:<tag>`, relance le service `site` et garde les trois images de production les plus récentes.

**Étant donné** les demandes `rehearse deploy <tag>`, `rehearse rollback <tag>`, `rehearse stop`
**Quand** elles s'exécutent avec un tag `-rc.N`
**Alors** le conteneur `site-rehearsal` démarre, repart sur une image `-rc` présente, puis s'arrête avec suppression des images `-rc`.

**Étant donné** un tag `-rc` en production, un tag sans `-rc` en répétition, une image au mauvais nom, un argument inconnu ou un tag suivi d'une autre commande
**Quand** la demande s'exécute
**Alors** elle est refusée sans toucher aux services.

**Étant donné** `status`
**Quand** il s'exécute
**Alors** il affiche les tags en service en production et en répétition.

- [ ] `deploy/compose.yaml` : service `site` sans port publié, sur le réseau du proxy nommé par variable, journaux `json-file` 10 m × 3.
- [ ] `deploy/compose.rehearsal.yaml` : projet `site-rehearsal`, hors du réseau du proxy, publié sur `127.0.0.1:18080` seulement.

### Story 11.5 : Delivery and release workflow

En tant qu'Arnaud, mainteneur,
je veux qu'un tag de mise en ligne ou de répétition contrôle, construise et livre l'image vers le bon canal,
afin que chaque mise en ligne ou répétition soit explicite et reproductible.

**Couvre :** FR-32, FR-39, NFR-2, NFR-11 · AD-11, AD-14, AD-22
**Dépendances :** 3.13, 11.3, 11.4
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `.gitea/workflows/release.yaml`, déclenché par un tag `v*`, sur le label en mode hôte
**Quand** le tag suit `vX.Y.Z` et pointe sur un commit de `main`, ou suit `vX.Y.Z-rc.N` et pointe sur un commit de `dev`
**Alors** il fait le checkout avec `fetch-depth: 0` et enchaîne `checks-job.sh`, `build-image.sh` et `ship.sh`.

**Étant donné** `scripts/release/ship.sh <tag>`
**Quand** le tag est `vX.Y.Z`, puis `vX.Y.Z-rc.N`
**Alors** il envoie `docker save | gzip` par `ssh` (vérification stricte de l'empreinte de l'hôte) avec `deploy <tag>`, puis `rehearse deploy <tag>`, et confirme par `status`.

**Étant donné** un tag `vX.Y.Z` hors de `main`, un tag `-rc.N` hors de `dev`, ou un tag mal nommé
**Quand** le workflow démarre
**Alors** il échoue avant toute construction.

**Étant donné** le tag `v1.0.0`
**Quand** aucun tag `v1.0.0-rc.N` ne pointe sur un commit de même arbre (`git diff --quiet`)
**Alors** le workflow échoue avant toute construction ; pour un tag de production suivant, cette règle ne bloque pas (AD-22, D-6).

- [ ] Un push sur `dev` ou `main` ne déclenche pas `release` ; aucun secret affiché.

### Story 11.6 : Production server and secrets setup

En tant qu'Arnaud, mainteneur,
je veux un compte de déploiement restreint, les deux services en place et les secrets de la forge,
afin que le workflow `release` puisse livrer sans accès plus large.

**Couvre :** NFR-2, NFR-9, NFR-11 · AD-9, AD-14, AD-22, procédure « premier déploiement » (étapes 1 et 2)
**Dépendances :** 11.5
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, serveur de production et administration Gitea : utilisateur dédié du groupe `docker`, `deploy-site` installé, clé restreinte (`restrict,command=`) ; copie de `compose.yaml` et `compose.rehearsal.yaml` avec le nom du réseau de NPM ; secrets `DEPLOY_SSH_KEY`, `DEPLOY_HOST`, `DEPLOY_KNOWN_HOSTS`, `PRIVATE_PATTERNS` et les sept `HUGO_LEGAL_*`.

**Critères d'acceptation :**

**Étant donné** la clé de déploiement
**Quand** Arnaud envoie `status`, puis une autre commande, un shell ou une redirection de port
**Alors** `status` répond, le reste est refusé.

**Étant donné** les réglages du dépôt sur la forge
**Quand** Arnaud les consulte
**Alors** secrets et variables portent exactement les noms de l'architecture, sans valeur dans le dépôt ni dans un journal.

- [ ] Serveur en x86_64 confirmé ; aucun nom d'hôte, adresse ni nom de compte commité.

### Story 11.7 : Release skill

En tant qu'Arnaud, mainteneur,
je veux une procédure unique pour publier `dev` sur `main`, taguer, livrer et revenir en arrière,
afin que chaque mise en ligne suive le flux linéaire sans merge commit.

**Couvre :** FR-32, NFR-7 · AD-11, AD-14, AD-22, AD-24
**Dépendances :** 0.2, 0.4, 11.5
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non (les tags réels sont poussés aux stories 11.9 et 11.11)

**Critères d'acceptation :**

**Étant donné** `scripts/release.sh`
**Quand** il démarre
**Alors** il vérifie d'abord que `main` est un ancêtre de `dev` ; sinon, il échoue et renvoie vers `hotfix`.

**Étant donné** l'invariant vérifié
**Quand** la publication se déroule
**Alors** le script ouvre la PR `dev` vers `main`, applique les verrous de la publication (AD-24, D-13 : revue tenue si chaque commit de `main..dev` est le squash d'une PR fusionnée par `verify-and-merge-pr`, repérée par son numéro dans le message de commit ; garde-fou, CI et suivi de sprint tels quels), fusionne en fast-forward **seulement avec `--merge` lancé par Arnaud**, vérifie que `main` et `dev` pointent sur le même commit, pose le tag `vX.Y.Z` sur `main`, puis suit le workflow `release` et `deploy-site status`.

**Étant donné** le tag `v1.0.0` demandé
**Quand** aucun tag `v1.0.0-rc.N` ne pointe sur un commit de même arbre que la tête de `dev`, ou que `ci/release-pages.txt` ne contient pas toutes les pages du socle (FR-32)
**Alors** le script refuse la publication avant toute action (D-5, D-6).

**Étant donné** un tag de production suivant sans tag `-rc` de même arbre
**Quand** le script s'exécute
**Alors** il affiche un avertissement, sans bloquer (AD-22, D-6).

**Étant donné** la commande de retour arrière du skill
**Quand** Arnaud la lance avec un tag précédent
**Alors** elle appelle `rollback <tag>` (ou `rehearse rollback <tag>`) et confirme par `status`.

- [ ] La procédure `docs/procedures/release.md` renvoie aux réglages de `docs/procedures/gitea-branches.md` (story 0.2) et décrit le flux linéaire ; aucun merge commit.
- [ ] Le script charge `.env` sans afficher de valeur ; sans variable Gitea, il échoue en renvoyant à la story 0.1.

### Story 11.8 : Rehearse-release skill

En tant qu'Arnaud, mainteneur,
je veux une procédure pour la répétition générale d'AD-22,
afin de l'exécuter et de la refaire à l'identique.

**Couvre :** FR-39, NFR-7 · AD-22, AD-24
**Dépendances :** 11.6, 11.7
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non (l'exécution réelle est la story 11.9)

**Critères d'acceptation :**

**Étant donné** `docs/procedures/rehearse-release.md` et `scripts/rehearse-release.sh`
**Quand** on les suit
**Alors** ils enchaînent : tag `-rc.1` posé sur `dev`, tunnel SSH (`ssh -L 18080:127.0.0.1:18080`), vérifications, tag `-rc.2` sur `dev`, `rehearse rollback` vers `-rc.1`, vérifications, `rehearse stop`.

**Étant donné** les vérifications
**Quand** le script les lance par le tunnel
**Alors** il contrôle par `curl -I` les en-têtes d'AD-13 sur un HTML, un SVG s'il existe, une 404 FR et EN, et vérifie que `docker logs` du conteneur de répétition ne contient aucune IP.

- [ ] Le script ne touche ni au service de production, ni à NPM, ni au DNS.
- [ ] La procédure vaut pour tout tag `vX.Y.Z-rc.N`, dont une première répétition sur `v0.1.0-rc.1` avec les seules pages déjà publiées (D-5).

### Story 11.9 : First release chain rehearsal

En tant qu'Arnaud, mainteneur,
je veux exercer tôt toute la chaîne sur le serveur de production, avant le contenu du socle,
afin de découvrir une erreur de chaîne bien avant la mise en ligne.

**Couvre :** FR-39, NFR-2 · AD-22
**Dépendances :** 11.8
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, tags `v0.1.0-rc.1` et `v0.1.0-rc.2` sur `dev`, tunnel SSH, vérifications.

**Critères d'acceptation :**

**Étant donné** `v0.1.0-rc.1` posé sur `dev`
**Quand** le workflow `release` se termine
**Alors** `status` montre `v0.1.0-rc.1` en répétition, et le site répond par le tunnel sur `http://127.0.0.1:18080/`, sans DNS ni port public
**Et** les contrôles de mise en ligne passent, C15 compris, puisque `ci/release-pages.txt` ne liste que les pages publiées attendues à ce commit (D-5).

**Étant donné** les vérifications de la story 11.8
**Quand** Arnaud les lance
**Alors** les en-têtes sont conformes, les pages légales montrent les vraies valeurs, et les journaux ne contiennent aucune IP.

**Étant donné** `v0.1.0-rc.2` déployé
**Quand** Arnaud lance `rehearse rollback v0.1.0-rc.1`
**Alors** `status` montre `v0.1.0-rc.1`, vérifié par le tunnel ; puis `rehearse stop` arrête le conteneur et supprime les images `-rc`.

- [ ] Le jalon « répétition générale » d'AD-22, sur l'arbre du socle (`v1.0.0-rc.1` puis `v1.0.0-rc.2`), est déroulé à la story 11.10.

## Epic 10 : Contenu du socle

Stories d'**intégration** : le contenu fourni par Arnaud passe les contrôles et quitte l'état de brouillon. Les cas passent par le skill `publish-case` (story 3.17).

### Story 10.1 : Home page pitch

En tant que Claire, CTO (UJ-1),
je veux lire sous le titre un pitch de trois phrases,
afin de comprendre en trente secondes ce qu'Arnaud fait bien.

**Couvre :** FR-1, FR-20, FR-37, SM-1 · AD-3, AD-17
**Dépendances :** 5.5
**Bloquée par :** —
**Prérequis de contenu :** pitch FR et EN, trois phrases chacun.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le pitch ajouté à `content/_index.{fr,en}.md`
**Quand** on ouvre `/` et `/en/`
**Alors** il suit le titre du site et « Basé en France », en trois phrases, et les deux versions disent la même chose *(relecture)*.

**Étant donné** l'accueil sur 390 × 844 px, photo comprise, en FR et en EN
**Quand** la page s'ouvre sans défilement
**Alors** on voit la ligne d'identité, le titre, le pitch et le début du premier poste avec le lien de son premier cas (vérifié de nouveau à la story 11.11).

- [ ] La PR ne touche que les deux fichiers de contenu (FR-25).

### Story 10.2 : Career positions

En tant que Claire, CTO (UJ-1),
je veux lire le parcours d'Arnaud du plus récent au plus ancien,
afin de reconnaître un CV et d'y trouver les preuves.

**Couvre :** FR-2, FR-4, FR-20, FR-22, FR-25, NFR-10 · AD-18 · C3, C19
**Dépendances :** 3.7, 5.2
**Bloquée par :** —
**Prérequis de contenu :** données de parcours FR et EN tirées du CV d'Arnaud (société, intitulé, période, ville de travail ou mode, cadre, société de prestation) ; URL de Ton Pote le Geek ; ligne de contexte EN sur Ton Pote le Geek.
**Opération manuelle (Arnaud) :** non

Identifiants : exactement la liste figée d'AD-18 (D-8, précisée le 13/09/2026) : `position-chiliz`, `position-synolia`, `position-mister-auto`, `position-april-technologies-2017`, `position-orange`, `position-earlier-career` (« Parcours antérieur », 2008–2014, regroupement et non société) et `position-ton-pote-le-geek`. Aucun autre poste n'est créé. La mission de 2013–2014 chez April pour le compte de CGI est une ligne de détail de `position-earlier-career`.

**Critères d'acceptation :**

**Étant donné** les fichiers `content/career/position-<id>.{fr,en}.md`
**Quand** on lance les contrôles
**Alors** C3 et C19 passent : `order` unique par `track`, `period` renseignée, `location` ou `setup` présents, `position-ton-pote-le-geek` en `track: parallel`.

**Étant donné** le build de production
**Quand** on ouvre l'accueil FR puis EN
**Alors** les mêmes postes apparaissent dans le même ordre ; le poste April Technologies de 2017 indique la prestation Modis, et son corps peut mentionner le même projet chez April pour le compte de CGI en 2013–2014, mission qui figure comme ligne de détail de `position-earlier-career`.

- [ ] Chaque donnée figure dans le CV d'Arnaud *(relecture)* ; aucune ville de résidence.
- [ ] Sept fichiers de poste, un par identifiant d'AD-18 ; `position-synolia`, `position-mister-auto` et `position-earlier-career` sans cas rattaché.
- [ ] La PR ne touche que `content/career/` (FR-25).

**Questions à poser avant de commencer :**
- Une ville de travail qui figurerait aussi dans la liste des motifs serait refusée par le garde-fou et par C22 : Arnaud vérifie-t-il ce cas avant la saisie ?

### Story 10.3 : Education, certification and languages content

En tant que Claire, CTO (UJ-1),
je veux voir la formation, les certifications et les langues d'Arnaud,
afin de compléter la lecture du CV.

**Couvre :** FR-20, FR-25, FR-36, NFR-10 · AD-18 · C3, C19
**Dépendances :** 5.3
**Bloquée par :** —
**Prérequis de contenu :** entrées FR et EN tirées du CV d'Arnaud.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** les fichiers `content/education/education-<id>.{fr,en}.md`
**Quand** on lance les contrôles puis le build de production
**Alors** C3 et C19 passent, et le bloc s'affiche après « En parallèle » dans les deux langues.

- [ ] Chaque donnée figure dans le CV *(relecture)* ; identifiants proposés par le développeur et confirmés par Arnaud.

### Story 10.4 : Chiliz page title and introduction

En tant que Claire, CTO (UJ-1),
je veux que la page Chiliz porte son titre « Chiliz »,
afin de comprendre ce que la page réunit.

**Couvre :** FR-9, NFR-10 · AD-4
**Dépendances :** 6.1 ; **livrée dans la même PR que la story 10.5** (décision d'Arnaud du 13/09/2026)
**Bloquée par :** — (Q9 tranchée : titre « Chiliz », sans introduction)
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** la décision sur Q9 (titre « Chiliz » en FR et en EN, sans introduction en v1)
**Quand** `content/cases/chiliz/_index.{fr,en}.md` est relu, puis passé en `draft: false` dans la PR qui publie le cas 02 (story 10.5 ; AD-4, D-3)
**Alors** la page affiche le titre « Chiliz », sans introduction ni `[TODO`
**Et** aucun commit de `dev` ne contient le `_index` Chiliz hors brouillon sans le cas 02 publié : aucune page de groupe vide n'existe en production.

- [ ] Aucune introduction ajoutée (NFR-10) *(relecture)*.

### Story 10.5 : Publish pilot case 02

En tant que Claire, CTO (UJ-1),
je veux que le cas 02 soit prêt à être mis en ligne sous le poste Chiliz,
afin de trouver en un clic la preuve « Chiliz, source de vérité ».

**Couvre :** FR-2, FR-5 à FR-9, FR-12, FR-20, FR-22 (NCS/CS), FR-25, FR-26, SM-7
**Dépendances :** 3.17, 10.2 ; livre aussi la story 10.4, dans la même PR
**Bloquée par :** —
**Prérequis de contenu :** relecture et accord d'Arnaud.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** le skill `publish-case` sur `case-02`, avec `position-chiliz` publié
**Quand** il s'exécute
**Alors** tous les contrôles passent et, dans une seule PR, les deux fichiers du cas et `content/cases/chiliz/_index.{fr,en}.md` passent en `draft: false` (story 10.4), et `case-02` et `group-chiliz` sont ajoutés à `ci/release-pages.txt` (D-5).

**Étant donné** le build de production
**Quand** on ouvre l'accueil puis `/cas/chiliz/#case-02`
**Alors** le poste Chiliz liste le cas 02, la section est présente, et les trois éléments « prévus » ne laissent aucune trace.

- [ ] La PR ne touche que les fichiers du cas, le `_index` Chiliz et `ci/release-pages.txt` (SM-7).

### Story 10.6 : Integrate case 01

En tant que Claire, CTO (UJ-1),
je veux lire le cas 01 (« Calculette de rentabilité ») depuis le bloc « En parallèle »,
afin de voir un cas mené de bout en bout dans le cadre de Ton Pote le Geek.

**Couvre :** FR-4, FR-5 à FR-8, FR-11, FR-12, FR-20, FR-22 (Systeme.io, Ton Pote le Geek), FR-25, FR-26
**Dépendances :** 3.17, 6.2, 10.2
**Bloquée par :** **Q2** (période du cas 01)
**Prérequis de contenu :** cas 01 FR et EN rédigé par Arnaud selon `docs/format-cas.md` v0.4, après les corrections préalables des sources (§9 du PRD).
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `content/cases/case-01-<nom-court>.{fr,en}.md` avec `position: "position-ton-pote-le-geek"`
**Quand** `publish-case` s'exécute
**Alors** tous les contrôles passent et le cas passe en `draft: false` dans une PR.

**Étant donné** le build de production
**Quand** on ouvre l'accueil puis la page du cas
**Alors** le cas est lié depuis « En parallèle », son encart affiche le cadre Ton Pote le Geek, et la version EN porte les lignes de contexte sur Systeme.io et Ton Pote le Geek.

### Story 10.7 : Integrate case 05

En tant que Claire, CTO (UJ-1),
je veux lire le cas 05 (« Orange, performance ») sous son poste,
afin de voir comment Arnaud mesure une performance et en nomme les limites.

**Couvre :** FR-2, FR-5 à FR-8, FR-10, FR-12, FR-20, FR-22 (Orange), FR-25, FR-26
**Dépendances :** 3.17, 6.2, 10.2
**Bloquée par :** **Q2** (période et cadre du cas 05)
**Prérequis de contenu :** cas 05 FR et EN rédigé par Arnaud.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `content/cases/case-05-<nom-court>.{fr,en}.md` avec `position: "position-orange"` (AD-18)
**Quand** `publish-case` s'exécute
**Alors** tous les contrôles passent et le cas passe en `draft: false` dans une PR.

**Étant donné** le build de production
**Quand** on ouvre l'accueil puis la page du cas
**Alors** le cas est lié sous son poste, nomme les limites de sa mesure *(relecture)*, et la version EN porte la ligne de contexte sur Orange.

## Mise en ligne du socle (stories 11.10 à 11.13)

Suite de l'Epic 11, placée après l'Epic 10 (décision D-5) : ces stories demandent le contenu du socle. Les numéros sont conservés.

### Story 11.10 : Thirty-second test

En tant qu'Arnaud, mainteneur,
je veux vérifier avec cinq testeurs que l'accueil dit en trente secondes qui je suis et ce que je fais bien,
afin de retoucher le haut de l'accueil avant la mise en ligne s'il le faut.

**Couvre :** SM-1, SM-3, FR-1, FR-2, FR-37, FR-39 · AD-22, procédure « premier déploiement » (étape 3) · UX-DR24
**Dépendances :** 9.4, 10.1 à 10.7, 11.9
**Bloquée par :** **Q2** (le socle doit être complet : stories 10.6 et 10.7)
**Prérequis de contenu :** cinq testeurs selon `EXPERIENCE.md`.
**Opération manuelle (Arnaud) :** **oui**, jalon « répétition générale » d'AD-22 sur l'arbre du socle (tags `v1.0.0-rc.1` et `v1.0.0-rc.2` sur `dev`, par `rehearse-release`), puis Arnaud mène le test, par partage d'écran sur le site de répétition (canal non public).

**Critères d'acceptation :**

**Étant donné** le socle complet sur `dev`
**Quand** Arnaud déroule le jalon « répétition générale » d'AD-22 (`v1.0.0-rc.1`, vérifications, `v1.0.0-rc.2`, `rehearse rollback v1.0.0-rc.1`, vérifications)
**Alors** chaque vérification de la story 11.8 passe, et le site de répétition sert l'arbre du socle pour le test ; `rehearse stop` suit le dernier passage.

**Étant donné** la méthode d'`EXPERIENCE.md` (cinq testeurs dont au moins un CTO ou tech lead, un recruteur tech francophone et un lecteur de la version anglaise ; trente secondes ; trois questions ; une preuve demandée)
**Quand** Arnaud mène les cinq passages
**Alors** chaque passage est noté dans `docs/measures/` (rôle, langue, appareil, réponses résumées, verdict), sans nom ni donnée personnelle.

**Étant donné** les cinq verdicts
**Quand** moins de quatre testeurs réussissent
**Alors** le titre, le pitch ou le premier poste sont retouchés, FR-37 est revérifié, et le test est refait avant la story 11.11.

### Story 11.11 : First base deployment and IP-free proxy

En tant que Claire, CTO (UJ-1),
je veux ouvrir le site en ligne, en HTTPS, dans ma langue,
afin de lire le CV et les preuves depuis le lien reçu.

**Couvre :** FR-19, FR-32, FR-37, NFR-2 à NFR-5, NFR-13, SM-6, SM-8 · AD-14, AD-15, AD-17, procédure « premier déploiement » (étapes 4 à 8) · C15
**Dépendances :** 11.7, 11.10 ; socle prêt (stories 9.1 à 9.4, 10.1 à 10.7)
**Bloquée par :** **Q2** (par le socle)
**Prérequis de contenu :** ceux des stories du socle ; les CV PDF ne sont pas requis.
**Opération manuelle (Arnaud) :** **oui**, tag `v1.0.0` par le skill `release`, hôte proxy dans Nginx Proxy Manager configuré sans IP dès sa création, vérifications, DNS en dernier, mesures.

**Critères d'acceptation :**

**Étant donné** le socle prêt, répété sous un tag `v1.0.0-rc.N` de même arbre, et publié sur `main` en fast-forward
**Quand** Arnaud pose `v1.0.0` par le skill `release`
**Alors** le skill `release` a vérifié que `ci/release-pages.txt` contient toutes les pages du socle (FR-32, D-5), le workflow `release` passe (C15, C21, C22 compris) et `status` montre `v1.0.0` en production.

**Étant donné** l'hôte proxy créé (destination `site:80` ; `access_log off;` dans *Advanced* ; *Custom Location* `/` avec `access_log off; error_log /dev/null crit;` ; « Cache Assets » désactivée ; TLS et HSTS)
**Quand** Arnaud lance `nginx -t`, `nginx -T | grep access_log`, puis une requête
**Alors** la configuration est valide et le journal d'accès de l'hôte ne grossit pas ; chaque point « à tester » d'AD-15 est noté confirmé ou non, et un point non confirmé arrête la story.

**Étant donné** le site servi par le proxy, avant le DNS
**Quand** Arnaud lance `curl -I` sur un HTML, un SVG s'il existe et une 404 de chaque langue
**Alors** les en-têtes d'AD-13 sont conformes et aucune réponse ne porte `Set-Cookie`.

**Étant donné** les vérifications passées
**Quand** le domaine pointe vers le serveur de production
**Alors** `/` et `/en/` répondent en HTTPS avec toutes les pages de FR-32, et le critère 390 × 844 est vérifié sur le site en ligne.

- [ ] Directives NPM recopiées dans `deploy/proxy/npm-advanced.conf`, sans nom d'hôte ni adresse.
- [ ] Mesure PageSpeed Insights mobile de chaque gabarit (accueil CV, page de cas, page de groupe, page simple, 404) consignée dans `docs/measures/v1.0.0.md` par une PR ordinaire.
- [ ] La politique de confidentialité est vraie sur toute la chaîne.

### Story 11.12 : Hotfix skill

En tant qu'Arnaud, mainteneur,
je veux corriger la production sans merge commit ni cherry-pick,
afin de garder `main` ancêtre de `dev` après un correctif urgent.

**Couvre :** FR-32, NFR-7 · AD-11, AD-14, AD-24
**Dépendances :** 0.2, 11.7, 11.11
**Bloquée par :** — (utilisable dès qu'une production existe)
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, approbation explicite d'Arnaud au moment du push forcé de `dev`, réservé à son compte (réglage de la story 0.2).

**Critères d'acceptation :**

**Étant donné** `scripts/hotfix.sh`
**Quand** un correctif démarre
**Alors** une branche `hotfix/*` est créée depuis `main` (préfixe réservé, D-14), la PR vers `main` se fusionne en fast-forward, et le tag `vX.Y.(Z+1)` est posé sur `main`.

**Étant donné** le correctif publié
**Quand** le script poursuit
**Alors** `dev` est rebasée sur `main`, puis poussée avec `--force-with-lease` **seulement après l'approbation explicite d'Arnaud au moment de l'opération**, puis le script liste les PR ouvertes vers `dev` à rebaser puis à relire par `llm-review`, leur rapport portant sur un SHA réécrit (D-14)
**Et** aucun cherry-pick n'est utilisé ; `main` redevient un ancêtre de `dev`.

**Étant donné** l'absence d'approbation explicite d'Arnaud
**Quand** le script arrive au push forcé
**Alors** aucun push forcé n'a lieu, et le script s'arrête en indiquant l'état de `dev` local.

**Étant donné** un utilisateur autre qu'Arnaud
**Quand** il lance l'étape de force-push
**Alors** Gitea la refuse.

- [ ] `docs/procedures/hotfix.md` trace l'exception de force-push, l'approbation requise et ses conséquences (revues à refaire sur les SHA réécrits).
- [ ] Le script charge `.env` sans afficher de valeur ; sans variable Gitea, il échoue en renvoyant à la story 0.1.

- [ ] L'acceptation par le miroir d'une réécriture de `dev` est constatée à la story 1.4.

### Story 11.13 : Production rollback on second deployment

En tant qu'Arnaud, mainteneur,
je veux vérifier en production que je peux revenir à la version précédente,
afin de corriger en quelques secondes une mise en ligne ratée.

**Couvre :** NFR-2, FR-32 · AD-14, procédure « premier déploiement » (étape 9)
**Dépendances :** 11.11 et un deuxième tag de production
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, par la commande forcée.

**Critères d'acceptation :**

**Étant donné** un deuxième tag déployé
**Quand** Arnaud lance `rollback` sur le tag précédent
**Alors** `status` montre le tag précédent et le site sert la version précédente ; puis le dernier tag est redéployé.

- [ ] Au plus trois images de production restent sur le serveur.

## Epic 12 : Agent de parité consultatif

Sur une PR de contenu de la forge, Arnaud (UJ-4) reçoit un commentaire qui signale un chiffre ou une phrase modifiés d'un seul côté, sans que la CI soit bloquée ni la clé exposée.

### Story 12.1 : Parity agent script

En tant qu'Arnaud qui corrige un chiffre (UJ-4),
je veux un script qui compare FR et EN des fichiers modifiés et liste les écarts,
afin de repérer ce que le script de parité ne voit pas.

**Couvre :** FR-24, NFR-11 · AD-16
**Dépendances :** 3.13
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** deux révisions
**Quand** `scripts/parity-agent/run.sh` s'exécute
**Alors** il identifie les `translationKey` modifiés (cas, postes, formations, pages) et envoie les deux fichiers complets de chaque paire à la Messages API (`x-api-key`, `anthropic-version: 2023-06-01`, modèle `PARITY_MODEL`, `claude-sonnet-5` par défaut), en demandant les écarts de faits, de chiffres et de phrases, sans réécriture et sans compter les lignes de contexte EN.

**Étant donné** une copie locale où un chiffre du pilote change en FR seulement
**Quand** le script s'exécute avec une clé
**Alors** le rapport signale ce chiffre.

**Étant donné** l'absence de clé, une erreur ou un délai dépassé de l'API, ou aucune modification de contenu
**Quand** le script s'exécute
**Alors** il s'arrête avec un message, sort avec 0, et n'appelle pas l'API sans contenu modifié.

**Étant donné** un fichier modifié sans `translationKey`
**Quand** le script forme les paires
**Alors** il apparie par nom de fichier (AD-16) : `diagrams/<id>/fr.d2` avec `en.d2`, `assets/live-material/<id>.fr.md` avec `<id>.en.md`, `i18n/fr.yaml` avec `i18n/en.yaml`.

- [ ] Clé jamais affichée ; seuls des fichiers publics envoyés.

### Story 12.2 : Parity-agent workflow on content PRs

En tant qu'Arnaud qui ouvre une PR de contenu (UJ-4),
je veux que l'agent commente la PR sans jamais la bloquer,
afin de corriger un oubli avant la fusion.

**Couvre :** FR-24, NFR-11, SM-4 · AD-11, AD-16 · C17
**Dépendances :** 12.1
**Bloquée par :** —
**Prérequis de contenu :** —
**Opération manuelle (Arnaud) :** **oui**, secret `ANTHROPIC_API_KEY` (et variable `PARITY_MODEL` au besoin) dans Gitea.

**Critères d'acceptation :**

**Étant donné** `.gitea/workflows/parity-agent.yaml`
**Quand** on le lit
**Alors** il se déclenche sur `pull_request` (`opened`, `synchronize`, `reopened`) filtré sur `content/**`, `diagrams/**`, `assets/live-material/**`, `i18n/**`, jamais sur `pull_request_target`, en `continue-on-error: true`, avec des permissions limitées.

**Étant donné** deux PR de démonstration, l'une qui modifie un chiffre d'un seul côté, l'autre qui supprime une phrase d'un seul côté
**Quand** l'agent s'exécute
**Alors** il publie un commentaire par exécution qui signale l'écart ; une détection manquée est remontée sans rien bloquer.

**Étant donné** une PR sans fichier de contenu, puis une clé invalide
**Quand** la PR est ouverte
**Alors** l'agent ne s'exécute pas, puis échoue sans affecter les contrôles ni la fusion.

**Questions à poser avant de commencer :**
- Portée exacte des `permissions:` du jeton, laissée « à confirmer dans la story » par AD-16 ?

## Epic 13 : Après le socle : cas 03, 04 et 06, matériel vivant prêt

Les cas 03, 04 et 06 sont mis en ligne un par un sous leur poste, chacun par son tag ; le matériel vivant retenu pour la v1 passe à « prêt ».

### Story 13.1 : Integrate and release case 03

En tant que Claire, CTO (UJ-1),
je veux lire sous le poste Chiliz le cas 03 (« Chiliz, batch de transactions »), présenté comme non mis en production,
afin de voir comment Arnaud arbitre quand un sujet n'aboutit pas.

**Couvre :** FR-2, FR-5 à FR-10, FR-12, FR-20, FR-26, FR-32, SM-C2
**Dépendances :** 3.17, 11.7, 11.11
**Bloquée par :** **Q2**, **Q4**, **Q5**
**Prérequis de contenu :** cas 03 FR et EN rédigé par Arnaud.
**Opération manuelle (Arnaud) :** **oui**, tag de mise en ligne par le skill `release`.

**Critères d'acceptation :**

**Étant donné** `content/cases/chiliz/case-03-<nom-court>.{fr,en}.md` avec `group: chiliz`, `position: "position-chiliz"`, `order: 2`
**Quand** `publish-case` s'exécute puis le build de production
**Alors** sa section suit la section 02 sans modifier le `_index` ni les gabarits, le poste Chiliz gagne un lien, et les numéros « 02.x » ne changent pas.

**Étant donné** les deux versions
**Quand** on les lit
**Alors** « Résultat » et « En bref » disent que le sujet n'est pas allé en production *(relecture)*, et chaque technologie de la stack est citée dans le texte et figure dans `data/stack.yaml`.

**Étant donné** le cas publié et les contrôles au vert
**Quand** Arnaud publie un nouveau tag par `release`
**Alors** le cas est mis en ligne seul, sans modifier le contenu des autres pages.

### Story 13.2 : Integrate and release case 04

En tant que Claire, CTO (UJ-1),
je veux lire sous le poste Chiliz le cas 04 (« Chiliz, reprise d'un sujet en dérive »),
afin de voir comment Arnaud reprend un sujet sans écraser celui qui le portait.

**Couvre :** FR-2, FR-5 à FR-9, FR-12, FR-20, FR-26, FR-32
**Dépendances :** 3.17, 11.7, 11.11
**Bloquée par :** **Q2**
**Prérequis de contenu :** cas 04 FR et EN rédigé par Arnaud.
**Opération manuelle (Arnaud) :** **oui**, tag de mise en ligne.

**Critères d'acceptation :**

**Étant donné** `content/cases/chiliz/case-04-<nom-court>.{fr,en}.md` avec `group: chiliz`, `position: "position-chiliz"`, `order: 3`
**Quand** `publish-case` s'exécute puis le build de production
**Alors** sa section prend sa place dans l'ordre 02, 03, 04 parmi les sections publiées, sans modifier la page.

**Étant donné** le cas publié
**Quand** Arnaud publie un nouveau tag
**Alors** le cas est mis en ligne seul.

### Story 13.3 : Integrate and release case 06

En tant que Daniel, recruteur qui lit en anglais (UJ-2),
je veux lire sous le poste April Technologies de 2017 le cas 06 (« April, hors périmètre »), avec une ligne qui explique ce qu'est April Technologies,
afin de mesurer la portée du cas.

**Couvre :** FR-2, FR-5 à FR-8, FR-12, FR-15, FR-20, FR-22 (April Technologies), FR-26, FR-32, UJ-2
**Dépendances :** 3.17, 6.2, 11.7, 11.11
**Bloquée par :** **Q2**
**Prérequis de contenu :** cas 06 FR et EN rédigé par Arnaud, avec la ligne de contexte sur April Technologies (PRD §11.2).
**Opération manuelle (Arnaud) :** **oui**, tag de mise en ligne.

**Critères d'acceptation :**

**Étant donné** `content/cases/case-06-<nom-court>.{fr,en}.md` avec `position: "position-april-technologies-2017"`
**Quand** `publish-case` s'exécute puis le build de production
**Alors** le cas est lié sous le poste April Technologies de 2017, la société est nommée April Technologies, et la version EN porte sa ligne de contexte *(relecture)*.

**Étant donné** le cas publié
**Quand** Arnaud publie un nouveau tag
**Alors** le cas est mis en ligne seul et atteint en un clic depuis l'accueil.

### Story 13.4 : First ready diagram published

En tant que Claire, CTO (UJ-1),
je veux voir à son emplacement le schéma d'un cas, dans ma langue et dans mon mode,
afin de comprendre un flux d'un coup d'œil.

**Couvre :** FR-12, FR-13, FR-25, FR-27, NFR-4, NFR-8, NFR-13 · AD-6, AD-7, AD-13 · C7, C9, C11, C13 · UX-DR15
**Dépendances :** 8.3 ; story d'intégration du cas concerné
**Bloquée par :** **Q1**
**Prérequis de contenu :** sources D2 du schéma retenu, libellés FR et EN.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** `diagrams/<id>/` et ses SVG commités dans le même commit, statut `ready` dans les deux fichiers du cas
**Quand** on construit le site
**Alors** le shortcode rend `<figure><img src alt width height></figure>` avec le SVG de la langue, `alt` égal à la description, dimensions lues dans le SVG, fichier empreinté, et la ligne « Schéma · Ouvrir en taille réelle ».

**Étant donné** un schéma de plus de 480 px de large intrinsèque
**Quand** on l'affiche à 390 px
**Alors** il est dans un conteneur focalisable nommé qui défile horizontalement, avec l'attribut `width` d'AD-6 et le lien « taille réelle », sans attribut `style` ; la page ne défile pas horizontalement.

**Étant donné** la préférence sombre
**Quand** on l'affiche
**Alors** le schéma suit le thème sombre (si le spike 8.1 l'a validé) ou s'affiche en planche claire encadrée, sans filtre.

**Étant donné** le site servi par nginx
**Quand** on lance `curl -I` sur le SVG
**Alors** il n'a pas de CSP et porte le cache long.

- [ ] Libellés lisibles à 320 px, alternative pertinente (check-list, en clair et en sombre).

### Story 13.5 : Ready snippets and thematic boxes

En tant que Claire, CTO (UJ-1),
je veux lire l'extrait ou l'encart thématique d'un cas à son emplacement,
afin d'approfondir un point précis.

**Couvre :** FR-12, NFR-10 · AD-6 · C7 · UX-DR13, UX-DR15
**Dépendances :** 3.5, 6.1 ; story d'intégration du cas concerné
**Bloquée par :** **Q1**
**Prérequis de contenu :** `assets/live-material/<id>.{fr,en}.md` fournis par Arnaud.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** un élément `ready`
**Quand** on construit le site
**Alors** un extrait est rendu en `<figure>` avec un `pre` qui défile dans son cadre et prend le focus, un encart thématique en `note-block` titré par son Markdown.

- [ ] Un élément `ready` sans source fait échouer le build ; aucun code propriétaire *(relecture)*.

### Story 13.6 : Ready video as plain link

En tant que Claire, CTO (UJ-1),
je veux suivre un lien vers la vidéo d'un cas,
afin de la regarder sur YouTube sans cookie sur le site.

**Couvre :** FR-12, FR-14, NFR-3, NFR-12, SM-6 · AD-6, AD-8 · C7, C10 · UX-DR15
**Dépendances :** 3.8 ; story d'intégration du cas concerné
**Bloquée par :** **Q1**, **Q3**
**Prérequis de contenu :** `url` YouTube non répertoriée.
**Opération manuelle (Arnaud) :** non

**Critères d'acceptation :**

**Étant donné** une vidéo `ready`
**Quand** on construit le site
**Alors** elle est rendue comme un lien dont le texte est la description suivie de « (vidéo sur YouTube) », sans iframe ni ressource YouTube ou Google (C10).

**Questions à poser avant de commencer :**
- Libellé `video_suffix` (« à valider » dans `EXPERIENCE.md`) ?

## Synthèse

### Validation finale

- **Couverture** : chaque FR (FR-1 à FR-39), chaque NFR (NFR-1 à NFR-13), chaque contrôle (C1 à C24) et chaque AD (AD-1 à AD-24) est cité par au moins une story ; chaque UX-DR est rattachée à une story.
- **Dépendances** : aucune story ne dépend d'une story suivante. Les skills d'Epic 0 qui s'appuient sur des stories ultérieures sont placés après elles (3.16, 3.17, 11.7, 11.8, 11.12). Les stories 11.1 à 11.9 sont placées avant l'Epic 10 (D-5).
- **Note pour la planification de sprint** (décision d'Arnaud du 13/09/2026) : les numéros de stories sont conservés. `sprint-status.yaml` les trie par numéro, donc l'Epic 11 après l'Epic 10 : l'ordre de travail, stories 11.1 à 11.9 avant l'Epic 10, puis 11.10 à 11.13 après lui, est fixé lors de la planification de sprint. Les stories 10.4 et 10.5 sont livrées dans une seule PR.
- **Répétition sur les mêmes fichiers** : `layouts/` est touché par les epics 2 (structure), 5 et 6 (mise en page), 9 (pages) et 13 (matériel prêt). Le regroupement est écarté : la structure précède les contrôles (walking skeleton), et chaque epic de mise en page est démontrable seul.
- **Pas de gabarit de démarrage** ni de base de données.

### Stories bloquées par une question ouverte

| Story | Bloquée par |
| --- | --- |
| 10.6 Cas 01 | Q2 |
| 10.7 Cas 05 | Q2 |
| 11.10 Test des trente secondes | Q2 (par le socle) |
| 11.11 Premier déploiement du socle | Q2 (par le socle) |
| 13.1 Cas 03 | Q2, Q4, Q5 |
| 13.2 Cas 04 | Q2 |
| 13.3 Cas 06 | Q2 |
| 13.4 Schéma prêt | Q1 |
| 13.5 Extraits et encarts prêts | Q1 |
| 13.6 Vidéo prête | Q1, Q3 |

Q13 (v1.1) ne bloque rien. Q9 est tranchée (D-4) : les stories 10.4 et 10.5 ne sont plus bloquées. La story 11.9 (première répétition) n'est bloquée par rien, puisque `ci/release-pages.txt` est cumulative (D-5).

### Prérequis de contenu (non bloquants au sens des questions)

| Contenu à fournir par Arnaud | Stories |
| --- | --- |
| Pitch FR et EN | 10.1 |
| Données de parcours, de formation, de certification et de langues (CV) | 10.2, 10.3 |
| URL de Ton Pote le Geek, ligne de contexte EN | 10.2 |
| Photo originale, hors dépôt ; textes alternatifs | 5.5 |
| CV PDF FR et EN **sans téléphone ni ville de résidence** (les actuels en contiennent) | 7.4 |
| Adresse mail et URL LinkedIn | 9.3 |
| URL de la politique de confidentialité de l'hébergeur | 9.2 |
| Texte de « À propos » | 9.4 |
| URL du profil GitHub et intitulé `job_title` (JSON-LD) | 9.6 |
| Relecture du premier jet du README-cas (voix et faits) | 3.15 |
| Cas 01, 03, 04, 05, 06 ; ligne de contexte sur April Technologies | 10.6, 10.7, 13.1 à 13.3 |

### Stories avec opérations manuelles d'Arnaud

| Story | Opération |
| --- | --- |
| 0.1 | Gitea : jeton d'accès (portées minimales, expiration) ; `GITEA_URL`, `GITEA_USER`, `GITEA_TOKEN` dans `.env` |
| 0.4 | Poste de développement : constat de `jq` (installé), prérequis de `create-pull-request` et `verify-and-merge-pr` |
| 0.2 | Gitea : création de `main` ; `main` sans push ni force-push ; `dev` avec le compte d'Arnaud en liste de push et seul en liste de force-push ; squash vers `dev`, fast-forward seul vers `main` |
| 0.5 | Poste de développement : `agy` authentifié, `agy models` répond |
| 1.2 | Serveur Gitea (Docker) : hook pre-receive et tests |
| 1.3 | Poste d'Arnaud : audit de l'historique avec la liste des motifs |
| 1.4 | GitHub et Gitea : dépôt public (branche par défaut `main`), identité du miroir, rulesets, miroir push |
| 2.1 | Poste de développement : Docker dans le shell WSL |
| 3.13 | Gitea : runner x86_64 en mode hôte, label, `WORKFLOW_DIRS` |
| 3.14 | GitHub : activation d'Actions si nécessaire |
| 5.5 | Préparation de la photo depuis l'original, ancrage et contrôle à l'œil |
| 7.3 | Image Docker dérivée de Gitea avec `poppler-utils`, reconstruite à chaque montée de version ; hook mis à jour |
| 7.4 | Fourniture et commit des CV PDF conformes |
| 8.1 | Test dans Safari, si un appareil d'Arnaud est nécessaire |
| 11.6 | Serveur de production : compte restreint, deux fichiers compose ; secrets Gitea |
| 11.9 | Première répétition : tags `v0.1.0-rc.N`, tunnel SSH, vérifications |
| 11.10 | Répétition générale (`v1.0.0-rc.N`), puis test des trente secondes avec cinq testeurs |
| 11.11 | Tag `v1.0.0`, hôte NPM sans IP, vérifications, DNS, mesures |
| 11.12 | Approbation explicite du push forcé de `dev` lors d'un hotfix |
| 11.13 | Retour arrière en production |
| 12.2 | Secret `ANTHROPIC_API_KEY` |
| 13.1 à 13.3 | Tag de mise en ligne de chaque cas |

### Tensions restantes

Ce document ne les tranche pas ; chacune figure dans la story concernée.

1. **CV PDF** : les PDF actuels contiennent un téléphone et une commune ; FR-38 bloque leur publication jusqu'à des versions conformes (story 7.4).
2. **Epic 0 et dépendances** : les skills `release`, `rehearse-release`, `hotfix` et `publish-case`, et le verrou « CI verte », ne peuvent pas être livrés dans l'Epic 0 sans dépendre de stories ultérieures ; ils sont placés après elles.
3. **Spike D2** : le test dans Safari suppose un appareil Apple (story 8.1).

### Tensions résolues le 13/09/2026

Par les décisions D-1 à D-17 et les corrections M-1 à M-18 du contrôle de préparation à l'implémentation (`implementation-readiness.md`) :

- répétition « tôt » et C15 : liste cumulative `ci/release-pages.txt`, stories 11.1 à 11.9 avant l'Epic 10 (D-5 ; stories 2.2, 3.17, 11.1, 11.9) ;
- tags `-rc.N` sur `dev` : déjà écrits dans AD-11 et AD-22 ;
- JSON-LD : sources des champs fixées dans AD-20 (D-7 ; story 9.6) ;
- page Chiliz vide et C12 : `_index` de groupe en brouillon (D-3 ; stories 2.5, 3.10, 10.4) ;
- Q9 : titre « Chiliz », sans introduction (D-4) ;
- documents partiellement à jour : corrections M-1 à M-18 appliquées ;
- identifiants de poste : liste figée dans AD-18 (D-8 ; stories 10.2, 10.7, 13.3) ;
- verrous sans objet au démarrage : règle d'amorçage (D-1, D-2 ; règle 11, stories 0.6, 0.7, 3.16) ;
- `.env.example` et C18 : déjà résolus par AD-9 et C18 ; filtrage de `env.sh` en critère (story 2.4) ;
- hotfix et revues : préfixe `hotfix/*`, PR ouvertes relues (D-14 ; story 11.12) ; réécriture de `dev` par le miroir testée (story 1.4) ;
- outillage hors architecture : AD-24 ;
- README-cas : rédaction attribuée (D-12 ; story 3.15) ; branches déjà citées par la section « README-cas » ;
- push direct sur GitHub : rulesets (D-9 ; AD-12, story 1.4).
