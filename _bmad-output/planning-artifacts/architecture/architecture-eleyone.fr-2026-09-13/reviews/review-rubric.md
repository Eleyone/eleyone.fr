---
title: "Revue par grille : architecture eleyone.fr"
reviewed: ARCHITECTURE-SPINE.md (draft, 2026-09-13)
inputs: prd.md (draft), docs/format-cas.md v0.2, content/cases/case-02-chiliz.{fr,en}.md, .memlog.md
reviewer: relecteur « rubrique » (lecture seule)
date: 2026-09-13
---

# Revue par grille : architecture eleyone.fr

## Verdict

Le document est solide : les faits sont vérifiés (spike Hugo, code Gitea et NPM), toutes les exigences FR et NFR du PRD sont reliées à l'architecture, et les points de divergence du modèle de contenu sont presque tous fixés. Il n'est **pas encore prêt pour les stories**. Deux points sont critiques : les dossiers de sortie des builds ne sont pas isolés, et le miroir GitHub est activé avant le garde-fou côté serveur. Plusieurs points importants restent aussi à fixer, surtout dans l'enveloppe opérationnelle (serveur de production, environnement d'exécution des scripts) et dans l'assemblage de la page de groupe (titres, identifiants).

## Grille

| Critère | Évaluation |
| --- | --- |
| Points de divergence du niveau inférieur fixés, aucun oublié | Partiel : sorties de build, environnement des scripts, titres et identifiants sur la page de groupe, sorties Hugo implicites, chargement des variables d'environnement, emplacement des URL externes (voir C-1, H-3, H-4, M-1, M-6, M-8) |
| Chaque règle d'AD applicable et efficace contre sa divergence | Partiel : AD-5 (C-1), AD-11 (M-7), AD-13 (H-1), AD-17 (H-2), C5 et C16 (M-5) |
| Rien dans « Reporté » ne permet une divergence entre stories | Partiel : mise en page (M-9) et durcissement du conteneur (port d'écoute, H-6) |
| Technologies nommées vérifiées et à jour | Oui, sauf Gitea Runner (L-1) |
| Couverture du PRD (FR-1 à FR-32, NFR-1 à NFR-12) | Oui dans « Capacités → architecture » ; quelques conséquences testables sans contrôle (L-8) |
| Enveloppe opérationnelle (environnements, infra, exploitation) décidée, reportée ou ouverte | Partiel : provisionnement du serveur de production, protection des tags, retour arrière, `baseURL` et hôte canonique, miroir, mises à jour de sécurité (H-6, M-2, M-10, M-11) |
| Cohérence interne (AD, tableau des contrôles, arborescence, walking skeleton, memlog) | Plusieurs contradictions (C-2, H-1, H-5, M-7, L-2, L-3) |

Vérification des versions (13/09/2026) : Hugo v0.166.0 (09/09/2026), D2 v0.9.0 (07/09/2026), nginx 1.30.4 (dernière stable, 15/07/2026), Gitea 1.27.3, Nginx Proxy Manager v2.15.1 (03/06/2026), `claude-opus-5` à 5 $ / 25 $ et `claude-sonnet-5` à 2 $ / 10 $ par million de jetons, `anthropic-version: 2023-06-01` : **à jour**. Gitea Runner : le document indique 2.0.0, mais la 2.2.0 est sortie le 22/07/2026 (L-1).

---

## Critique

### C-1. Rendu de travail et build de production écrivent dans le même `public/`

- **Emplacement** : AD-5, AD-10 (« build de production de contrôle (`public/`) »), AD-13 (étape `build`), diagramme du paradigme.
- **Constat** : aucune règle ne fixe `--destination` ni `--cleanDestinationDir`. Par défaut, Hugo écrit les deux environnements dans `public/` et ne vide pas ce dossier. Dans l'étape `build` du `Dockerfile`, `hugo --environment production --minify` précède `scripts/check.sh --release`, qui doit lui-même produire le manifeste du rendu de travail (AD-10) et lancer un build avec `--panicOnWarning` (C14). Un rendu `work --buildDrafts` dans `public/`, ou des fichiers restés d'un build précédent, se retrouvent alors dans `COPY --from=build public`. L'image contiendrait brouillons, éléments « prévus », `checks.json` et `noindex`. La règle d'AD-5 « l'image n'est construite qu'à partir d'un build de production » n'a aucun moyen d'être vérifiée.
- **Correction proposée** : dans AD-5, fixer `hugo --environment work --buildDrafts --destination build/work --cleanDestinationDir` et `hugo --environment production --destination public --cleanDestinationDir`, avec `build/` dans `.gitignore` et `.dockerignore`. En mode `--release`, `check.sh` ne fait que lire `public/` et n'y écrit jamais. Ajouter à C15 : aucun `checks.json`, aucun `noindex`, aucune page dont le `translationKey` est un brouillon dans le manifeste.

### C-2. Le miroir GitHub est activé avant le garde-fou côté serveur

- **Emplacement** : walking skeleton WS-4 (« un seul run sur GitHub, par le miroir ») et paragraphe « Viennent ensuite » (hook pre-receive après le squelette) ; AD-12 ; FR-28.
- **Constat** : FR-28 fait du hook pre-receive l'autorité non contournable, et AD-12 exige un audit complet et propre avant la première publication sur GitHub. Or le squelette démontre le miroir en WS-4 et ne pose le hook qu'ensuite. Entre les deux, seuls le hook local (contournable) et le contrôle CI des chemins sur GitHub (a posteriori, sans motifs) protègent. Un commit publié sur GitHub reste accessible par son SHA (`AGENTS.md`). La fuite serait irréversible, alors que c'est le risque principal du projet.
- **Correction proposée** : créer une tranche WS-0, ou une précondition bloquante de WS-4, qui contient la modification fail-closed de `check-private.sh`, l'installation et les tests 1 à 4 de la procédure pre-receive, et un audit `history` avec la liste des motifs. Écrire dans AD-12 : « le miroir push n'est configuré qu'après le test 3 réussi ».

---

## Important

### H-1. AD-13 exige `check.sh --release` dans l'image, ce qui rend WS-5 et tout build d'image avant le socle impossibles

- **Emplacement** : AD-13 (étape `build`), C15, WS-5, AD-14 (plan de secours).
- **Constat** : C15 exige les pages du socle, les cas mis en avant publiés et aucun `VALEUR-FACTICE`. En WS-5, le pilote est encore un brouillon, les pages légales n'existent pas et aucun secret n'est disponible : le `docker build` échoue, et la démonstration de WS-5 ne peut pas passer. Une story contournera la règle à sa façon (drapeau, suppression de l'appel…).
- **Correction proposée** : sortir `--release` du `Dockerfile`, ou le paramétrer par `ARG RELEASE_CHECKS=0` que seul `scripts/release/build-image.sh` met à 1. Préciser aussi que `RUN --mount=type=secret,id=legal_env` couvre, dans la **même** instruction `RUN`, le chargement des variables, Hugo et les contrôles, puisqu'un secret BuildKit n'est monté que pour la durée d'un `RUN`.

### H-2. Tant que le pilote est un brouillon, les contrôles HTML ne voient aucun gabarit de cas

- **Emplacement** : AD-10 (« les contrôles HTML portent sur le build de production de contrôle »), AD-17, C10 à C13, « Écarts et tensions » (FR-9).
- **Constat** : le build de production exclut les brouillons. Pendant tout le squelette, et jusqu'à la mise en ligne de chaque cas, C10, C11, C12 et C13 tournent sur un site presque vide (accueil, 404, page Chiliz vide). AD-17 dit empêcher « une régression d'accessibilité introduite par une story de gabarit », mais la partie automatique ne voit ni `_partials/case.html`, ni le shortcode, ni la page de groupe. La démonstration de WS-2 repose d'ailleurs sur une copie locale non commitée en `draft: false`.
- **Correction proposée** : lancer aussi `html.sh`, `links.sh` et `budget.sh` sur `build/work/`, en tolérant seulement le `noindex` et les éléments « prévus ». Autre option : une fixture commitée hors `content/` (par exemple `tests/fixtures/content/`, construite avec `--contentDir`) qui contient un cas groupé et un cas isolé non brouillons.

### H-3. Titres et identifiants des rubriques sur la page de groupe

- **Emplacement** : AD-3 (le partial « reçoit le niveau de titre »), AD-4 (`<section id="<translationKey>">`), AD-17 (« un seul `<h1>` ; pas de saut de niveau ; identifiants uniques »), arborescence (`layouts/_markup/` absent).
- **Constat** : les rubriques d'un cas sont des `##` Markdown. Sur la page de groupe, le titre du cas est un H2 et ses rubriques restent des H2 : la structure du document est fausse (WCAG 1.3.1). Le paramètre de niveau passé au partial ne décale pas les titres rendus par Goldmark. Goldmark génère aussi des identifiants automatiques (`contexte`, `resultat`…) : ils seront dupliqués dès que le cas 03 ou le cas 04 sera publié, et C11 échouera, ou la story désactivera la vérification.
- **Correction proposée** : ajouter une règle et un fichier `layouts/_markup/render-heading.html` qui décale le niveau selon le contexte (page de cas : +0 ; section de groupe : +1) et préfixe l'`id` par le `translationKey` (`case-02-resultat`). Autre option : `markup.goldmark.parser.autoHeadingID: false`. Vérifier le résultat dans le spike avec deux cas groupés.

### H-4. AD-15 contredit la dernière entrée du memlog

- **Emplacement** : AD-15, sous-puce « Incertain » ; `.memlog.md`, entrée `(change)` finale.
- **Constat** : le memlog (mis à jour après le document) indique que la recherche retient `access_log off` dans l'onglet Advanced, une **Custom Location** `/` avec `error_log /dev/null crit` (à tester) et un `map` d'anonymisation dans `http_top.conf` (à tester), et qu'il faut **éviter** une `location /` dans Advanced ainsi que l'édition du `.conf` généré. AD-15 recommande encore la `location /` dans la configuration avancée. Les deux sources de référence divergent, et la story d'exploitation ne saura pas laquelle suivre.
- **Correction proposée** : réécrire AD-15 d'après l'entrée `(change)`, avec la liste confirmé / à tester et la vérification par `nginx -T`. Retirer la recommandation de `location /` dans Advanced. Si le journal d'erreurs ne peut pas être coupé, écrire la conséquence pour la politique de confidentialité (question 13).

### H-5. Environnement d'exécution des scripts non fixé

- **Emplacement** : AD-1 (seuls Hugo et D2 sont épinglés), AD-10 (`bash`, `jq`, `xmllint`, `grep`, `cmp`), AD-11 (`runs-on` fixé pour GitHub seulement), AD-13 (étape `tools` Alpine), AD-14 (build d'image sur un runner Gitea).
- **Constat** : les mêmes scripts tournent sur `ubuntu-24.04` (GitHub), sur une image de runner Gitea non précisée, sur Alpine (busybox, dans le `Dockerfile`) et sur le poste de travail. `jq`, `xmllint` (libxml2-utils), GNU `grep`, `sed` et coreutils, `git` et le client `docker` ne sont ni déclarés ni vérifiés. Les options de `grep` (`-P`), de `sed -i` et de `find` diffèrent entre busybox et GNU. Le label `runs-on` des workflows Gitea et l'accès du runner à Docker, requis par `release`, ne sont pas décidés. Deux stories de contrôles écriront donc pour des environnements différents.
- **Correction proposée** : étendre AD-1 avec la liste des outils système requis (et une version minimale pour `jq`), vérifiée par `scripts/ci/require-tools.sh` appelé par `check.sh`. Fixer une seule base pour l'étape `build` du `Dockerfile` et pour les jobs Gitea (par exemple, Alpine avec `apk add bash coreutils grep sed jq libxml2-utils git`, ou Debian slim), épinglée par digest, et le label `runs-on` des trois workflows Gitea. Préciser comment le job `release` accède à Docker (socket monté ou DinD).

### H-6. Serveur de production : provisionnement, protection des tags et retour arrière non décidés

- **Emplacement** : AD-14, `deploy/`, « Reporté » (durcissement du conteneur), topologie.
- **Constat** : AD-14 décrit le flux mais laisse de côté ce que deux stories (release et nginx/compose) doivent partager :
  - qui crée le compte de déploiement, installe `deploy-site.sh` et la ligne `authorized_keys` ;
  - où vit `deploy/compose.yaml` sur l'hôte et comment une modification arrive au serveur (copie à chaque livraison ou installation unique) ;
  - comment le tag passe par la commande forcée (`SSH_ORIGINAL_COMMAND`) et est validé ;
  - le port d'écoute du conteneur (80, ou 8080 si le durcissement non root reporté arrive, ce qui change la cible dans NPM) ;
  - la création de l'hôte dans NPM (domaine, certificat, HSTS) ;
  - la commande de retour arrière ;
  - la protection contre un tag `v*` posé sur un commit hors de `main`.
- **Correction proposée** : ajouter une section « Procédure : serveur de production » sur le modèle de la procédure pre-receive (installation unique, tests). Dans AD-14, écrire que la commande forcée n'accepte que `^v[0-9]+\.[0-9]+\.[0-9]+$` ; que `release.yaml` vérifie `git merge-base --is-ancestor <tag> origin/main` ; que les tags `v*` sont protégés sur Gitea ; que le compose est copié à chaque livraison ; qu'il existe une commande `deploy-site rollback <tag>`. Fixer dès maintenant le port d'écoute du conteneur (par exemple 8080), pour que le durcissement reste vraiment sans effet de cohérence.

---

## Moyen

### M-1. Sorties implicites de Hugo non décidées

- **Emplacement** : AD-2, AD-5, arborescence `config/_default/hugo.yaml`.
- **Constat** : par défaut, Hugo génère les taxonomies `tags` et `categories`, les flux RSS (`/index.xml`, `/cas/chiliz/index.xml`…), `sitemap.xml` et, selon la configuration, `robots.txt`. Le RSS intégré liste les pages `list: always` avec leur `.Permalink`, y compris les cas groupés `render: never`, dont l'URL n'existe pas. Un gabarit manquant pour un type de page produit un avertissement qui, avec `--panicOnWarning`, fait échouer le build. Chaque story tranchera à sa façon.
- **Correction proposée** : fixer `disableKinds: [taxonomy, term, rss]` (ou décider du RSS), `enableRobotsTXT` et le choix du sitemap (avec exclusion des pages `render: never`). Ajouter à C12 une liste d'autorisation des fichiers générés dans `public/`.

### M-2. `baseURL` et hôte canonique non fixés

- **Emplacement** : AD-2 (`hreflang`, `x-default`), AD-13 (`absolute_redirect off`), AD-14.
- **Constat** : les annotations `hreflang` doivent être des URL absolues, qui dépendent de `baseURL`. Ni la valeur de production, ni le traitement de `www` (redirection vers l'apex, ou l'inverse, dans NPM), ni la valeur du rendu de travail ne sont décidés.
- **Correction proposée** : dans AD-2, fixer `baseURL: https://eleyone.fr/` en production, la redirection `www` vers l'apex dans NPM, et `--baseURL` pour `hugo server`. Ajouter un contrôle : chaque `hreflang` commence par `https://eleyone.fr/` dans `public/`.

### M-3. La CSP `style-src 'self'` bloque les styles en ligne, sans contrôle en CI

- **Emplacement** : AD-13 (CSP), AD-6 (`snippet` rendu en Markdown), C10.
- **Constat** : la coloration syntaxique de Hugo (Chroma) produit par défaut des attributs `style=` (`noClasses: true`), bloqués par la CSP sans `'unsafe-inline'`. Aucun contrôle ne le détecte, puisqu'il n'y a pas de navigateur en CI. La story des extraits cassera l'affichage en silence.
- **Correction proposée** : fixer `markup.highlight.noClasses: false` et les classes dans `main.css`, ou `markup.highlight.codeFences: false`. Ajouter à C10 : aucun attribut `style=` et aucun élément `<style>` dans le HTML de `public/`.

### M-4. Rendu d'un élément « prévu » dans le rendu de travail non spécifié

- **Emplacement** : AD-6 ; démonstration de WS-2 (« montre la section et ses trois éléments prévus »).
- **Constat** : AD-6 ne décrit que la résolution d'un élément `ready`. Pour un élément `planned` en rendu de travail (sans SVG ni fichier Markdown), le balisage, la recherche éventuelle de la source et l'échec du build ne sont pas précisés.
- **Correction proposée** : ajouter une ligne au tableau d'AD-6 : `planned` (rendu de travail seulement) donne `<aside class="live-material live-material--planned">` avec le type et la `description`, sans recherche de source.

### M-5. C5 et C16 ne peuvent pas être appliqués tels qu'écrits

- **Emplacement** : AD-10 (manifeste : H2 et `[TODO` par `findRE` sur le Markdown brut), ADR-6, C5, C16 ; cas pilote (`summary: >-`).
- **Constat** :
  - `.RawContent` ne contient pas le front matter. Or `docs/format-cas.md` place ses marqueurs `[TODO: …]` dans le front matter (`setup`, `period`, `slug`…) : C5 les manquerait.
  - C16 compte des « lignes source » de `summary`, mais le pilote utilise un bloc replié `>-`, que le parseur YAML réduit à une seule ligne. Le manifeste Hugo, seule lecture autorisée par ADR-6, ne peut donc pas compter ces lignes.
  - `summary` est aussi un champ de front matter reconnu par Hugo (`.Summary`). Deux gabarits pourraient lire `.Summary` et `.Params.summary` différemment.
- **Correction proposée** : dans le manifeste, calculer la présence de `[TODO` sur `.RawContent` **et** sur `jsonify .Params`. Pour C16, choisir une mesure lisible par Hugo (nombre de phrases, ou nombre de caractères), ou autoriser par écrit une lecture brute limitée à ce contrôle. Fixer l'accesseur de l'encart « En bref » et le vérifier dans le spike.

### M-6. Chargement des variables `HUGO_LEGAL_*` sans propriétaire

- **Emplacement** : AD-9 (« poste de travail sans `.env` : charge `ci/legal-placeholder.env` »), AD-11 (`checks-job.sh`), AD-5 (`hugo server`).
- **Constat** : dès que la page légale existe, le partial fait échouer tout build dont une valeur est vide, `hugo server` compris. Aucun script ne porte la règle « `.env`, sinon valeurs factices » en local. Le format du fichier (guillemets, adresse sur plusieurs lignes) n'est pas fixé non plus. Chaque story (démo locale, `check.sh`, `Dockerfile`) écrira son propre chargement.
- **Correction proposée** : créer un seul chargeur, `scripts/lib/legal-env.sh`, appelé par `check.sh`, par un `scripts/serve.sh` (à ajouter à l'arborescence) et par l'étape `build`. Format : `KEY=value` en une ligne, lu par `set -a; . fichier`.

### M-7. Les déclencheurs Gitea `push` et `pull_request` provoquent des exécutions en double

- **Emplacement** : AD-11 (`checks.yaml` « sur `push` et `pull_request` ») contre son propre Prevents (« des exécutions en double ») et la démonstration de WS-4 (« un seul run sur Gitea »).
- **Constat** : un push sur une branche qui a une PR ouverte déclenche deux exécutions.
- **Correction proposée** : `push` limité à `main` et aux tags, et `pull_request` pour les branches. Autre option : `push` sur toutes les branches sans `pull_request`, en assumant que la PR lit le statut du commit.

### M-8. Emplacement des URL externes et des textes transverses non tranché

- **Emplacement** : AD-3, conventions (« Paramètres de site : `snake_case` sous `params` »), FR-3, FR-4, FR-17, FR-29.
- **Constat** : l'URL du dépôt public (FR-29, probablement en pied de page), l'URL de Ton Pote le Geek, le libellé et la cible de l'appel à contact, et le suffixe du `<title>` de chaque page n'ont pas d'emplacement fixé (`params`, `i18n`, contenu ou configuration des langues). Les stories de l'accueil, du pied de page et du README choisiront chacune.
- **Correction proposée** : dans AD-3, lister les URL dans `params` (`repo_url`, `side_activity_url`, `linkedin_url`), les libellés dans `i18n`, et le titre du site dans `languages.<lang>.title` pour le `<title>`, en plus du titre affiché tiré de `content/_index`.

### M-9. Mise en page reportée alors que plusieurs stories écrivent `main.css`

- **Emplacement** : « Reporté » (mise en page, question 15), AD-8, WS-1, WS-2, check-list manuelle d'AD-17.
- **Constat** : WS-1 (base), WS-2 (encarts), les pages simples et la 404 écriront chacune du CSS sans jetons communs (couleurs, espacements, point de rupture, style du focus). Le contraste est vérifié à la main, gabarit par gabarit. La divergence est ici certaine, pas seulement esthétique.
- **Correction proposée** : fixer un contrat minimal dans AD-8 : propriétés personnalisées en tête de `main.css` (`--color-text`, `--color-bg`, `--color-accent`, `--space-*`), un seul point de rupture, un style de focus commun, et l'ordre des sections du fichier. Autre option : placer l'étape UX avant WS-2.

### M-10. Aucune politique de mise à jour des versions épinglées

- **Emplacement** : AD-1, AD-13, Stack.
- **Constat** : nginx est épinglé par digest, sans mise à jour automatique. nginx 1.30.4 corrige justement une faille dans `map` avec regex, directive qu'utilise AD-13. Rien ne dit qui surveille et applique les correctifs de sécurité de nginx, d'Alpine, de Hugo, de D2 ou du runner.
- **Correction proposée** : ajouter une règle à AD-1 : revue des versions à chaque mise en ligne et à chaque annonce de sécurité nginx, dans un commit dédié (tag et digest, ou version et sha256), avec reconstruction de l'image. Mentionner Renovate comme reporté, avec cette justification.

### M-11. Configuration du miroir push non décidée

- **Emplacement** : AD-12 (« seul le miroir push de Gitea y écrit »), WS-4, topologie.
- **Constat** : seul chemin d'écriture vers le dépôt public, le miroir n'a ni option de synchronisation fixée (à chaque push ou par intervalle), ni type et portée d'identifiant (jeton à grain fin limité au dépôt, ou clé de déploiement), ni refs poussées (toutes les branches, dont `experiment/*`, et les tags).
- **Correction proposée** : dans AD-12, fixer la synchronisation à chaque push, un jeton GitHub à grain fin limité à `contents: write` sur ce dépôt (stocké dans Gitea, avec sa date d'expiration) et les refs poussées. La démonstration de WS-4 en dépend.

### M-12. Statut des AD incohérent

- **Emplacement** : titres des AD (seul AD-1 porte `[ADOPTED]`), ADR-12 `[ADOPTED]`, AD-14 « recommandation », marqueurs **[à valider]** dispersés dans AD-2, AD-3 et AD-8.
- **Constat** : une story ne sait pas si AD-2 à AD-17 s'imposent ou restent des propositions.
- **Correction proposée** : donner à chaque AD un statut `[ADOPTED]` ou `[PROPOSED]`, et distinguer dans une AD adoptée les seuls paramètres encore à valider.

---

## Faible

- **L-1. Version du runner** (Stack) : « Gitea Runner 2.0.0 », alors que la 2.2.0 est sortie le 22/07/2026. Écrire « ≥ 2.0.0 (requis pour `continue-on-error` et les résumés de job), installé : 2.2.x ».
- **L-2. Walking skeleton et tableau des contrôles** : WS-3 attribue C3 à `content.sh`, alors que le tableau le donne à `parity.sh`. C13 (`budget.sh`), C14 et C16 ne sont planifiés ni dans le squelette ni dans « Viennent ensuite ». Aligner WS-3 sur le tableau et y ajouter `budget.sh` et `--panicOnWarning`.
- **L-3. Graphe des dépendances incomplet** : AD-1 fait lire `tools.env` à tout script qui appelle `hugo` ou `d2` (donc CHK et DG, pas seulement CI). Le `Dockerfile` appelle `scripts/check.sh` directement. `scripts/parity-agent/` et `deploy/` sont absents. Compléter le diagramme.
- **L-4. AD-17** : « notée dans la PR du tag », alors qu'un tag n'a pas de PR. Écrire « notée dans la note de version du tag sur Gitea » ou dans un fichier `docs/quality/mesures-<tag>.md`.
- **L-5. AD-7 et tableau des contrôles** : le contrôle « dossier de schéma ⇔ élément `diagram` déclaré » n'apparaît ni dans C7 ni dans C9, et `scripts/diagrams/check.sh` n'a pas de source de déclarations désignée (le manifeste ?). Préciser la ligne et la source.
- **L-6. C10 « aucune origine tierce »** : distinguer les ressources chargées (`src`, `srcset`, `<link href>`, `url()` en CSS) des liens sortants `<a href>`, exigés par FR-4, FR-14, FR-17 et FR-29. Lister les attributs contrôlés.
- **L-7. Agent de parité** : traiter `stop_reason` différent de `end_turn` (dont `refusal` et `max_tokens`) avant de lire `content`. Fixer `max_tokens`. Préciser comment une modification de `diagrams/<id>/` ou `assets/live-material/<id>.*` est rattachée au `translationKey` du cas.
- **L-8. Conséquences testables sans contrôle** : liens vers les pages légales depuis chaque page (FR-18 et FR-19, hypothèse du pied de page), au moins un lien vers le dépôt public par langue (FR-29), et aucune redirection selon `Accept-Language` (FR-21). Les ajouter à C12 ou C11.
- **L-9. `.dockerignore`** : liste d'exclusion « au moins ». Préférer une liste d'autorisation (`*`, puis `!content/`, `!layouts/`…), plus sûre lors d'une construction depuis le poste de travail (plan de secours d'AD-14), où `docs/private/` est présent.
- **L-10. Étape `tools`** : l'image Alpine n'est pas épinglée par digest, contrairement à nginx. L'épingler dans le `Dockerfile`.
- **L-11. Workflows** : `permissions: contents: read` n'est pas écrit pour `.github/workflows/checks.yaml`, et l'épinglage par SHA de `actions/checkout` n'est pas écrit côté Gitea. Les ajouter à AD-11.
- **L-12. Memlog** : les entrées qui plaçaient les versions dans les `ARG` du `Dockerfile` et les contrôles dans `docker build --target checks` sont remplacées par une décision ultérieure, sans être marquées comme telles. Le document renvoie au memlog pour le détail : ajouter une entrée `(change)` qui les annule explicitement. Aucune information personnelle relevée dans le memlog.

---

## Points bien tenus

- La traçabilité est complète : les 32 FR et les 12 NFR figurent dans `binds` et dans « Capacités → architecture ».
- Le modèle de contenu est fixé avec précision : cascade `target: {kind: page}` vérifiée, ancres identiques en FR et en EN, partial unique de rendu d'un cas, `case-url.html`.
- Les faits délicats sont vérifiés dans le code ou par spike : `WORKFLOW_DIRS`, `pre-receive.d`, secrets et forks sur Gitea, découpage de `HUGO_PARAMS_`, droits `0600` de D2, CSP limitée au HTML.
- Les écarts avec les entrées sont reconnus honnêtement (NFR-9 et adresse de l'éditeur, audit NFR-4 et NFR-5, page Chiliz vide).
- La plupart des reports sont justifiés et sans effet de cohérence (limitation de débit, taxonomie par technologie, arm64, commentaire unique de l'agent).
