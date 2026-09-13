---
title: "Revue adversariale de la spine : paires de stories conformes mais incompatibles"
target: ../ARCHITECTURE-SPINE.md
lens: adversarial (construire deux unités qui respectent chaque AD à la lettre et ne s'assemblent pas)
date: 2026-09-13
status: draft
---

# Revue adversariale : ARCHITECTURE-SPINE eleyone.fr

## Verdict

La spine est solide sur le « quoi » (chaîne statique, CI double, garde-fou, journaux), mais elle laisse plusieurs **interfaces entre stories sans propriétaire ni forme** : destination des builds, outillage des contrôles hors Hugo et D2, portée des contrôles par type de page, identifiants HTML générés par Hugo, chargement des valeurs légales, protocole de livraison. Deux agents qui respectent chaque AD à la lettre produisent aujourd'hui des pièces qui échouent à l'intégration, souvent dès le squelette (WS-2 à WS-5). Aucun trou n'est une remise en cause du paradigme : chacun se ferme par un AD resserré ou une convention de plus.

Notation : **A** et **B** sont deux stories construites séparément ; « AD respectés » liste ce que les deux suivent ; « Resserrement » est la correction proposée.

Gravité : **Bloquant** (échec d'intégration certain ou livraison fausse), **Majeur** (échec probable dès qu'un contenu réel arrive), **Mineur** (dérive ou coût).

---

## T1. Un seul `public/` pour trois builds différents — Bloquant

- **A (WS-3, `scripts/check.sh`)** : lance `hugo --environment work --buildDrafts --panicOnWarning` puis `hugo --environment production --panicOnWarning`, sans `--destination`, donc tous deux dans `public/` (valeur par défaut), et lit `public/checks.json`.
- **B (WS-5, `Dockerfile`)** : étape `build` = `hugo --environment production --minify`, puis `scripts/check.sh --release`, puis `COPY --from=build public`.
- **AD respectés** : AD-5 (deux environnements, commandes données), AD-10 (manifeste émis par le rendu de travail, contrôles HTML sur la production de contrôle), AD-13 (étapes de l'image).
- **Collision** :
  - Hugo ne vide pas la destination par défaut : le rendu de travail laisse dans `public/` les pages des brouillons et `checks.json`, que le build de production suivant ne supprime pas. Dans l'image, `check.sh --release` réécrit `public/` après le build minifié : l'image embarque un build **non minifié** et, selon l'ordre, les résidus du rendu de travail (brouillons, manifeste). Le contrôle C5 « aucun `[TODO` dans `public/` » peut alors échouer sur un brouillon résiduel, ou passer sur un `public/` qui n'est pas celui livré.
  - Le budget C13 est mesuré en CI sur un HTML non minifié (AD-5 ne mentionne pas `--minify`) et l'image sert un HTML minifié (AD-13) : ce qui est mesuré n'est pas ce qui est servi.
  - Rien ne déclare `public/`, `resources/_gen/` ni `.hugo_build.lock` dans `.gitignore` : la première story qui fait `git add -A` après un build les commite.
- **Resserrement (nouvel AD « Build unique »)** :
  - `scripts/build.sh work|production` est la **seule** commande qui appelle `hugo` pour produire un site. Drapeaux fixes pour les deux : `--panicOnWarning --cleanDestinationDir --minify`. Destinations fixes : `build/work/` pour le travail, `public/` pour la production.
  - `scripts/check.sh` appelle `build.sh` (ou vérifie que les dossiers existent) et ne lit que ces deux chemins ; le manifeste est à `build/work/checks.json` et `build/work/en/checks.json`.
  - Le `Dockerfile` appelle `scripts/check.sh --release`, qui construit `public/` lui-même ; aucune autre ligne `hugo` dans le `Dockerfile`.
  - `.gitignore` et `.dockerignore` listent `public/`, `build/`, `resources/_gen/`, `.hugo_build.lock` (propriétaire : WS-1).

## T2. Outils des contrôles non épinglés, environnements divergents — Bloquant

- **A (WS-3, `scripts/checks/html.sh`)** : écrit et testé sur `ubuntu-24.04` (GitHub) avec GNU `grep -P`, `find -printf`, `xmllint --html` dont la sortie d'erreur fait échouer le contrôle.
- **B (WS-5, `Dockerfile`)** : étape `tools` en Alpine avec `scripts/ci/install-tools.sh`, qui n'installe que Hugo et D2 (AD-1), puis `scripts/check.sh --release` dans l'étape `build`.
- **AD respectés** : AD-1 (versions de Hugo et D2 dans `tools.env` seulement), AD-10 (`bash` + `jq`, `xmllint --html` et `grep`), AD-11 (GitHub en `ubuntu-24.04`), AD-13 (Alpine).
- **Collision** :
  - Alpine n'a par défaut ni `bash`, ni `jq`, ni `xmllint` ; ses `grep` et `find` sont ceux de BusyBox (pas de `-P`, pas de `-printf`). Les scripts qui passent sur GitHub échouent dans l'image, ou l'inverse.
  - `xmllint --html` repose sur libxml2, en 2.9 sur Ubuntu 24.04 et en version bien plus récente sur une Alpine de 2026 ; les deux parseurs HTML ne signalent pas les mêmes erreurs sur `<section>`, `<figure>` ou `<aside>`. Un même `public/` est accepté sur une forge et refusé dans l'image.
  - L'image du runner Gitea n'est fixée nulle part (`runs-on` non précisé pour Gitea) : présence de `jq`, `xmllint`, `docker` avec BuildKit, `ssh` inconnue.
- **Resserrement (AD-1 étendu)** :
  - `tools.env` déclare aussi l'environnement des contrôles : **une** image de base épinglée par digest (proposition : Debian ou Ubuntu 24.04, pour rester identique au runner GitHub) avec la liste des paquets (`bash`, `jq`, `libxml2-utils`, `coreutils`, `grep`, `findutils`) ; l'étape `tools` du `Dockerfile` part de cette image, pas d'Alpine. L'image nginx finale reste Alpine, elle n'exécute aucun script.
  - `scripts/ci/install-tools.sh` vérifie la présence et la version de `jq` et `xmllint` comme il le fait pour Hugo et D2.
  - Convention : les scripts n'utilisent que GNU coreutils, grep et findutils de cette image ; `xmllint` est appelé avec des options fixées (par exemple `--noout` et un filtre documenté des messages HTML5) dans une seule fonction partagée `scripts/checks/lib.sh`.
  - `.gitea/workflows/*.yaml` : `runs-on` fixé sur un label dont l'image est nommée dans ce document, avec `docker` (BuildKit) et `ssh` pour `release`.

## T3. Scripts qui supposent `.git`, contexte Docker qui l'exclut — Bloquant

- **A (story du pipeline D2, `scripts/diagrams/check.sh`)** : détecte « SVG manquant ou orphelin » par `git ls-files assets/diagrams` (lecture littérale de « Les SVG sont commités ») et se place à la racine par `cd "$(git rev-parse --show-toplevel)"` (« lançables depuis la racine du dépôt »).
- **B (WS-5)** : `.dockerignore` exclut `.git/` et l'étape `build` lance `scripts/check.sh --release`, qui inclut C9.
- **AD respectés** : AD-7, AD-13, conventions (scripts lançables depuis la racine).
- **Collision** : C9 échoue dans l'image faute de dépôt. Même effet si une story de gabarit active `enableGitInfo` pour une date de mise à jour.
- **Resserrement (AD-10)** : `scripts/check.sh` et tout ce qu'il appelle fonctionnent **sans `.git`** et sans réseau ; ils se situent par `cd "$(dirname "$0")/.."`. Les contrôles qui ont besoin de l'historique ou de l'index (C1, « SVG commité ») vivent seulement dans `scripts/ci/checks-job.sh`. `enableGitInfo: false` est fixé dans `hugo.yaml`.

## T4. Le manifeste ne dit pas quel type de page il décrit — Bloquant

- **A (WS-3, `content.sh` et `parity.sh`)** : applique C3, C4, C8 et C16 à chaque entrée de `checks.json`, puisque AD-10 ne distingue pas les pages.
- **B (story des pages simples)** : `content/about.fr.md` avec ses propres titres `## Parcours`, sans `summary` ni `group` ; **B' (WS-2)** : `content/cases/chiliz/_index.fr.md` (page de groupe, pas de `group`, pas de rubriques) ; **B'' (WS-1)** : `content/_index.fr.md` (accueil).
- **AD respectés** : AD-2 (tout fichier de `content/` porte un `translationKey`), AD-3, AD-4, AD-10, conventions (identifiants de page).
- **Collision** :
  - C4 refuse les titres de la page « À propos », C8 refuse la page de groupe (dossier `chiliz`, `group` vide), C16 refuse toute page sans `summary`.
  - Aucune convention de `translationKey` pour l'accueil ni pour `content/cases/_index` : une story écrit `home`, une autre rien, et `parity.sh` échoue ou ne voit pas la paire.
  - Si le gabarit du manifeste parcourt `site.RegularPages` (choix naturel), les `_index` en sont absents et la règle d'AD-2 n'est jamais contrôlée pour eux ; s'il parcourt `site.Pages`, il inclut des pages sans fichier (taxonomies) que `parity.sh` signale comme orphelines.
- **Resserrement (AD-10 et conventions)** :
  - Le manifeste parcourt `site.Pages` filtré sur `.File` non nul, et chaque entrée porte `kind` ∈ `home | case | group | cases-index | page` (dérivé de `.Kind` et du chemin, pas du front matter).
  - La « Liste des contrôles » ajoute une colonne **Portée** : C3 toutes (champs de cas pour `case` seulement), C4, C7, C8, C16 pour `case`, C8 bis (« `translationKey` = `group-<dossier>` ») pour `group`.
  - `translationKey` : `home` pour `content/_index`, `cases` pour `content/cases/_index`.
  - Le schéma JSON du manifeste (noms anglais des champs, types) est écrit dans le document ou dans `scripts/checks/manifest.schema.md`, et `scripts/checks/lib.sh` fournit les requêtes `jq` communes : sans cela, `content.sh`, `parity.sh`, `links.sh` et `diagrams/check.sh` inventent chacun `.file` ou `.path`, `.lang` ou `.language`.

## T5. Identifiants de titres dupliqués sur la page de groupe — Bloquant dès le cas 03

- **A (format des cas, cas 02, 03 et 04)** : mêmes rubriques `## Contexte`, `## Le problème`… dans chaque fichier, comme l'exige `docs/format-cas.md`.
- **B (WS-2, `layouts/cases/section.html`)** : rend les trois cas dans la même page, chacun dans `<section id="case-NN">` (AD-4), avec leur `.Content`.
- **C (WS-3, `html.sh`)** : C11 « identifiants uniques ».
- **AD respectés** : AD-3, AD-4, AD-17, format des cas.
- **Collision** :
  - Goldmark génère par défaut un `id` par titre (`id="contexte"`, `id="le-problème"`). Trois cas sur la page Chiliz donnent trois `id="contexte"` : C11 échoue dès le deuxième cas publié. Tant qu'un seul cas est publié, rien ne le montre.
  - Sur la page de groupe, le titre du cas est un H2 (AD-3) et ses rubriques restent des H2 : pas de saut de niveau, donc C11 passe, mais le plan du document met les rubriques au même niveau que les cas. `.Content` est calculé une fois par page, donc le partial ne peut pas décaler les niveaux selon le contexte d'affichage.
- **Resserrement (AD-4)** : un gabarit `layouts/_markup/render-heading.html` unique : `id` = `<translationKey>-<ancre>` ; niveau + 1 si la page porte `group` (un cas groupé n'est jamais rendu seul, donc le décalage est toujours juste). Les titres H2 du manifeste restent lus dans le Markdown brut, donc C4 n'est pas affecté. Ajouter à C11 un cas de test avec deux cas dans un groupe.

## T6. Élément « prévu » en rendu de travail : afficher quoi ? — Bloquant pour WS-2

- **A (WS-2, `_shortcodes/live-material.html`)** : lecture littérale d'AD-6 : « rendu si `ready`, ou si le rendu n'est pas de production », et le tableau de résolution donne la source ; le shortcode résout donc `assets/diagrams/<id>.<lang>.svg` pour tout élément affiché, et `errorf` si elle manque.
- **B (WS-3)** : le manifeste n'existe que si le rendu de travail réussit.
- **AD respectés** : AD-5, AD-6, AD-10.
- **Collision** : le pilote déclare trois éléments `planned` sans source ; le rendu de travail échoue, donc plus de manifeste, donc aucun contrôle ne tourne. À l'inverse, une autre lecture (« source manquante = rien ») rend un `ready` sans source silencieux en travail.
- **Resserrement (AD-6)** : un élément `planned` n'est **jamais** résolu : en rendu de travail, il produit un encart fixe `<aside class="live-material live-material-planned">` avec le type et la `description` ; en production, rien. Seul un élément `ready` résout sa source, dans les deux environnements, et échoue si elle manque.

## T7. Valeurs légales : personne ne les charge, et pas sous la même forme — Bloquant

- **A (WS-4, `scripts/ci/checks-job.sh`)** : `set -a; . ci/legal-placeholder.env` sans condition.
- **B (story des pages légales)** : `content/legal-notice.fr.md` doit afficher les valeurs ; un fichier Markdown ne peut pas appeler un partial, donc la story crée un shortcode `{{< legal "HUGO_LEGAL_PUBLISHER_NAME" >}}`. **B' (story du partial)** : `_partials/legal-value.html` prend un nom de champ `publisher_name`.
- **C (story `release`)** : met les secrets Gitea dans l'`env:` du job et lance `docker build --secret id=legal_env,env=HUGO_LEGAL_PUBLISHER_NAME` ; **C' (WS-5, `Dockerfile`)** : attend un fichier dotenv complet dans `/run/secrets/legal_env`.
- **D (développement local)** : `hugo server --environment work --buildDrafts`, commande donnée par AD-5.
- **AD respectés** : AD-3, AD-5, AD-6 (« seul point d'insertion » du matériel vivant), AD-9, AD-13, AD-14.
- **Collision** :
  - Deux interfaces pour le même partial (nom de variable complet ou nom de champ) ; aucun shortcode déclaré pour y accéder depuis le contenu.
  - L'option BuildKit `env=` transmet **une** variable, alors que l'étape `build` attend un fichier de sept variables ; rien ne dit quelle étape `RUN` monte le secret ni qui le charge (`. /run/secrets/legal_env`) avant `check.sh`.
  - Hugo ne lit pas `.env` : `hugo server` échoue en local dès que la page légale existe, et aucune règle ne dit qui charge `.env` ou le fichier factice, ni dans quel ordre de priorité (variable déjà définie, `.env`, fichier factice).
- **Resserrement (AD-9)** :
  - `_shortcodes/legal.html` est le seul accès depuis le contenu ; argument = nom de champ en `snake_case` (`publisher_name`) ; il appelle `_partials/legal-value.html`, qui construit `HUGO_LEGAL_` + majuscules.
  - `scripts/env.sh` est le seul chargeur : variables déjà définies > `.env` > `ci/legal-placeholder.env`. `scripts/build.sh` (T1), `check.sh` et un `scripts/serve.sh` (qui remplace l'appel direct à `hugo server`) le sourcent.
  - Forme du secret de build : un fichier dotenv, `--secret id=legal_env,src=<fichier>` ; `build-image.sh` reçoit ce chemin en argument (le workflow l'écrit depuis les secrets dans `$RUNNER_TEMP`, le poste de travail passe `.env`). L'unique `RUN` qui appelle `check.sh --release` monte le secret.
  - Un contrôle vérifie que les noms de `.env.example`, de `ci/legal-placeholder.env` et des appels au shortcode sont les mêmes ensembles.

## T8. Le socle ne peut pas être mis en ligne tant que le pilote est un brouillon — Majeur

- **A (WS-2)** : pilote déplacé dans `content/cases/chiliz/`, avec `_index` Chiliz, `featured: true`, `draft: true`.
- **B (story `release`, C15)** : refuse une page de groupe vide et un cas mis en avant non publié.
- **C (AD-14)** : « socle, puis un tag par cas publié ».
- **AD respectés** : AD-4, AD-14, C15, format des cas.
- **Collision** : le tag du socle échoue toujours sur C15 tant que le cas 02 est en brouillon (page Chiliz vide, cas mis en avant non publié). La mise en ligne progressive de FR-32 exige alors de retirer à la main le dossier `chiliz/` ou de publier le cas, contre l'intention « socle d'abord ».
- **Resserrement (AD-4 et C15)** : décider explicitement l'une des deux règles : (a) le socle inclut le cas 02 publié (et AD-14 le dit) ; ou (b) une page de groupe est `draft: true` tant qu'aucun de ses cas n'est publié (C3 et C8 vérifient la cohérence), et C15 ne vérifie « cas mis en avant publiés » que pour les cas dont `draft: false`. Pour (b), un spike doit confirmer le comportement de Hugo v0.166.0 sur une section brouillon et ses pages (cascade `build`).

## T9. « Pages du socle » : liste déclarée nulle part — Majeur

- **A (story `release`, C15)** : code en dur les URL du tableau « URL publiques proposées » (`/a-propos/`, `/mentions-legales/`…).
- **B (story des pages simples)** : applique les slugs validés entre-temps par Arnaud (les slugs sont **[à valider]**), par exemple `/en/legal/`.
- **AD respectés** : AD-2 (l'URL vient du `slug`), C15.
- **Collision** : C15 échoue à la mise en ligne, ou passe parce qu'une URL morte n'est cherchée que dans une langue.
- **Resserrement (C15)** : la liste du socle est une donnée unique, par `translationKey` (`home`, `about`, `contact`, `legal-notice`, `privacy`), déclarée dans `scripts/checks/release-pages.txt` (ou `data/release.yaml`) ; C15 la compare au manifeste (entrées non brouillon dans les deux langues), jamais à des URL.

## T10. Protocole `ship.sh` ↔ `deploy-site`, nom des tags — Majeur

- **A (story `release`, `scripts/release/ship.sh`)** : `docker save eleyone-site:v1.2.0 | gzip | ssh deploy@host deploy-site v1.2.0`.
- **B (story serveur, `deploy/remote/deploy-site.sh`)** : commande forcée qui lit le tag dans `$1`, `docker compose -f deploy/compose.yaml up -d`, et garde « les trois images précédentes » en triant `docker images` par tag.
- **AD respectés** : AD-12 (chemins interdits), AD-14.
- **Collision** :
  - Avec une commande forcée, les arguments arrivent dans `SSH_ORIGINAL_COMMAND`, pas dans `$1` ; sans validation, c'est une injection possible.
  - Le serveur de production n'a pas de copie du dépôt : ni `deploy/compose.yaml` ni `deploy-site.sh` n'y sont, et le flux SSH ne transporte que l'image. Leur installation et leur mise à jour ne sont décrites nulle part (même dérive que le hook pre-receive).
  - Le nom du réseau du proxy « par variable » pousse vers un `deploy/.env` commité, que `check-private.sh` refuse (`(^|/)\.env$`).
  - Format de tag libre : un tri lexical place `v10` avant `v9`, et un tag Git valide (`v1.0.0+build`) n'est pas un tag Docker valide.
- **Resserrement (AD-14)** :
  - Tags : `^v[0-9]+\.[0-9]+\.[0-9]+$`, vérifié par `release.yaml` avant tout build.
  - `deploy-site` lit `SSH_ORIGINAL_COMMAND`, le valide contre la même expression, lit l'archive sur l'entrée standard ; la rétention se fait sur un fichier d'état (tags déployés, dans l'ordre), pas sur un tri.
  - `compose.yaml` et `deploy-site.sh` sont installés sur le serveur par une procédure écrite (comme celle du hook), avec un contrôle de version : `ship.sh` envoie le sha256 attendu de `deploy-site.sh` et le script refuse s'il diffère.
  - Le réseau du proxy a une valeur par défaut dans `compose.yaml` (`${PROXY_NETWORK:-…}`) ; aucun fichier `.env` sous `deploy/`.

## T11. Unicité des identifiants de matériel vivant et code de langue — Majeur

- **A (WS-3, C7)** : « identifiants uniques dans tout le site » = aucun `id` ne figure deux fois dans l'ensemble des manifestes.
- **B (format des cas)** : le même `id` figure dans le fichier FR et le fichier EN (identique FR/EN).
- **C (story du shortcode)** : `<lang>` = `site.Language.Locale` ; **C' (`render.sh`)** : `<lang>` = nom du fichier `fr.d2`.
- **AD respectés** : AD-2 (locales **[à valider]**), AD-6, AD-7, C7.
- **Collision** : C7 refuse le pilote (chaque `id` apparaît deux fois). Si Arnaud valide la locale `fr-FR`, le shortcode cherche `diagram-x.fr-FR.svg` et `render.sh` écrit `diagram-x.fr.svg`.
- **Resserrement (AD-6)** : un `id` appartient à **un seul** `translationKey` et apparaît au plus une fois par fichier. `<lang>` désigne partout la clé de langue Hugo (`.Lang`, `fr` ou `en`), jamais la locale.

## T12. Qui lit le front matter en dehors de Hugo — Majeur

- **A (story D2, `scripts/diagrams/check.sh`)** : le graphe de dépendances autorise `scripts/diagrams → content` ; la story lit donc `live_material` par `grep` dans `content/**/*.md` pour savoir quels schémas sont déclarés (AD-7 : « dossier sans élément déclaré »).
- **B (AD-16, `run.sh`)** : « identifie les `translationKey` modifiés » sans Hugo installé, donc par `grep` ; un changement dans `assets/live-material/` n'a pas de `translationKey`.
- **C (C16)** : « trois lignes source dans `summary` », calculées depuis le manifeste ; mais `summary: >-` replie les lignes en une seule : Hugo (et donc le manifeste) ne voit qu'une ligne.
- **D (C4)** : la liste des rubriques est lue dans `docs/format-cas.md`, qu'un `.dockerignore` resserré (« au moins » laisse la porte ouverte) exclut avec le reste de `docs/`.
- **AD respectés** : AD-7, AD-10 (« métadonnées lues par Hugo »), AD-13, AD-16, ADR-6.
- **Collision** : deux parseurs du même front matter (ce qu'ADR-6 voulait éviter), un C16 impossible à calculer tel qu'écrit, un C4 qui dépend d'un fichier de documentation absent de l'image, et un agent qui se déclenche sur `assets/live-material/**` sans rien trouver à comparer.
- **Resserrement** :
  - AD-7 et le graphe : `scripts/diagrams/check.sh` lit les éléments déclarés dans le manifeste ; supprimer la flèche `scripts/diagrams → content` (garder `→ diagrams` et `→ assets/diagrams`). Ordre fixé dans `check.sh` : rendu de travail, puis C9.
  - C16 : soit `summary: |` (lignes préservées) dans le format v0.3, soit une limite en caractères ; choisir avant la story.
  - C4 : la liste des rubriques FR et EN devient une donnée (`data/case_sections.yaml`), émise dans le manifeste ; `docs/format-cas.md` y renvoie, comme pour `data/stack.yaml`.
  - AD-16 : `run.sh` associe un fichier modifié à sa paire par le chemin (`x.fr.md` ↔ `x.en.md`), y compris sous `assets/live-material/`, sans lire le front matter.

## T13. `[TODO` dans le front matter et `setup` hors vocabulaire — Majeur

- **A (WS-3, manifeste)** : « présence de `[TODO` » calculée sur `.RawContent`, qui ne contient que le corps.
- **B (WS-2, `_partials/case.html`)** : libellé du cadre par `T (printf "setup_%s" …)` ; une clé absente rend une chaîne vide, sans avertissement par défaut.
- **AD respectés** : AD-3, AD-10, C5.
- **Collision** : un cas `draft: false` avec `setup: "[TODO: cadre]"` passe C5 côté manifeste et s'affiche en production avec un champ « Cadre » vide : le `[TODO` n'atteint jamais `public/`, donc la seconde moitié de C5 ne le voit pas non plus. Même chose pour une valeur `setup` mal orthographiée.
- **Resserrement (AD-10, C5, C6)** : le manifeste cherche `[TODO` dans le corps **et** dans `.Params` sérialisé (`jsonify`) ; C6 contrôle aussi `setup`, `type` et `status` contre leurs énumérations, déclarées dans `data/` avec `stack`.

## T14. Fichiers `snippet` et `callout` : format non défini — Majeur

- **A (story du contenu d'un encart)** : `assets/live-material/callout-18-decimals.fr.md` avec un front matter, un titre `## Pourquoi 18 décimales` et un `[TODO: chiffre]`.
- **B (story du shortcode)** : `resources.Get` puis `markdownify`.
- **AD respectés** : AD-6, C5, C7, C3.
- **Collision** : le front matter s'affiche en texte (une ressource n'est pas une page), le H2 casse la hiérarchie et crée un `id` en double (T5), le `[TODO` n'est vu par aucun contrôle de manifeste, et rien ne vérifie que la version EN existe tant que l'élément est `planned`.
- **Resserrement (AD-6)** : format écrit : pas de front matter, pas de titre H1 ou H2, rendu par `.Page.RenderString` (mêmes gabarits de rendu que le cas) ; C5 et C3 couvrent `assets/live-material/` (présence des deux langues, `[TODO` ⇒ l'élément reste `planned`).

## T15. URL absolues : internes pour les uns, tierces pour les autres — Majeur

- **A (WS-1, `baseof.html`)** : `<link rel="alternate" hreflang href="{{ .Permalink }}">`, puisque les moteurs attendent une URL absolue ; `baseURL: https://eleyone.fr/`.
- **B (WS-3, `html.sh` et `links.sh`)** : C10 traite tout `href` ou `src` en `https://` d'une balise `<link>` comme une origine tierce ; C12 ne résout que les liens relatifs.
- **AD respectés** : AD-2 (aucun lien en dur, mais la forme absolue ou relative de `hreflang` n'est pas fixée), AD-8, AD-17.
- **Collision** : C10 échoue sur chaque page, ou C12 ignore les liens `hreflang` absolus (non vérifiés). En `hugo server`, `baseURL` devient `localhost` et les liens `hreflang` changent.
- **Resserrement (AD-2)** : `hreflang` (et `canonical` s'il est ajouté) en `.Permalink` ; tout le reste en `.RelPermalink`. Les contrôles classent `https://eleyone.fr/` comme interne et le résolvent dans `public/` ; C10 ne vise que les ressources chargées (`<link rel="stylesheet">`, `src`, `srcset`, `url()` dans la CSS).

## T16. Pages générées sans lien : 404, taxonomies, flux, cas non mis en avant — Majeur

- **A (WS-3, `links.sh`, C12)** : « aucune page orpheline par langue » = tout `.html` de `public/` est la cible d'au moins un lien ; C11 : « liens `hreflang` présents » sur toute page.
- **B (WS-1)** : `404.html` et `en/404.html` (non liées, sans traduction exploitable par `.Translations`) ; configuration Hugo par défaut, qui génère les taxonomies `tags` et `categories` et les flux RSS.
- **B' (story du cas 06)** : cas sans groupe et non mis en avant, alors que la navigation vers ces cas est reportée (question 6).
- **AD respectés** : AD-2, AD-4, AD-5 (`--panicOnWarning`), AD-17, C11, C12.
- **Collision** : C12 et C11 refusent la 404 ; les taxonomies donnent soit un avertissement « no layout » (fatal avec `--panicOnWarning`), soit des pages orphelines ; le cas 06 publié est orphelin par construction.
- **Resserrement (AD-2 et AD-17)** : `disableKinds: [taxonomy, term, rss]` et une décision sur `sitemap` et `robots.txt` dans `hugo.yaml` (propriétaire WS-1) ; C11 et C12 excluent nommément `404.html` ; tant que la question 6 est ouverte, C15 refuse la publication d'un cas sans groupe non mis en avant (au lieu de laisser C12 échouer sur une story de contenu).

## T17. Propriété de la configuration Hugo et du titre du site — Majeur

- **A (WS-1)** : `config/_default/hugo.yaml` avec `outputs: {home: [html]}` et `title: "Eleyone"` par langue (utilisé par `site.Title` dans `<title>`).
- **B (WS-3)** : `config/work/hugo.yaml` avec `outputs: {home: [checks]}`, en supposant une fusion des listes.
- **B' (story des pages simples)** : ajoute `config/_default/languages.yaml`, forme éclatée admise par Hugo.
- **C (AD-3)** : « le titre du site et le pitch sont dans `content/_index` ».
- **AD respectés** : AD-2, AD-3, AD-5, AD-10.
- **Collision** : une liste de `outputs` d'environnement remplace celle de `_default` : l'accueil du rendu de travail perd son HTML (invisible pour les contrôles HTML, qui visent la production, mais `hugo server` n'a plus d'accueil). Deux sources pour `languages`. Deux sources pour le titre du site (`site.Title` en configuration, contre AD-3 ; `site.Home.Title` dans le contenu), et la 404 prend l'une ou l'autre.
- **Resserrement (AD-5 et conventions)** : un seul fichier par environnement, pas de fichiers éclatés ; `config/work/hugo.yaml` répète la liste complète `outputs.home: [html, checks]` ; tableau de propriété des clés de premier niveau (langues et permaliens : WS-1 ; `outputs`, `outputFormats` : WS-3 ; `markup` : T5 ; `security` : AD-9). Titre du site : `site.Home.Title` seulement, pas de clé `title` dans la configuration.

## T18. Empreinte : algorithme libre, motif nginx fixe — Mineur

- **A (story CSS)** : `resources.Get "css/main.css" | minify | fingerprint "sha512"` avec `integrity` (idiome courant).
- **B (WS-5)** : cache immuable pour `\.[0-9a-f]{64}\.(css|svg)$`.
- **AD respectés** : AD-8 (« empreintée »), AD-13.
- **Collision** : une empreinte sha512 (128 caractères hexadécimaux) ne correspond pas au motif : la CSS est servie sans cache long, sans erreur visible.
- **Resserrement (AD-8)** : `fingerprint` sans argument (sha256) pour la CSS et les SVG ; un contrôle `html.sh` vérifie que chaque `<link rel="stylesheet">` et chaque `<img src>` local correspond au motif de `deploy/nginx/`.

## Mineurs, à noter dans le document

- **Branches poussées sur GitHub** : le miroir pousse toutes les branches ; `.github/workflows/checks.yaml` sur `push` sans filtre publie des exécutions rouges pour du travail en cours, alors que le README cite ces exécutions comme preuve. Filtrer `branches: [main]`.
- **Contrôles doublés en `release`** : `checks-job.sh` sur le runner, puis `check.sh --release` dans l'image. Acceptable, mais le dire pour qu'une story n'en retire pas un « par optimisation » (C1 n'existe que dans le premier).
- **Mode `history` de `check-private.sh`** : le mode « chemins seulement » en CI est déduit de l'absence du fichier de motifs. Une story qui rend le script fermé en cas de doute dans tous les modes casse C1. Proposer une option explicite `--paths-only` en CI.
- **Variables `HUGO_*`** : Hugo interprète aussi les variables préfixées `HUGO_` comme surcharges de configuration. Confirmer par le spike, avec `--panicOnWarning`, qu'aucune variable `HUGO_LEGAL_*` ne produit d'avertissement ni ne crée de clé de configuration.
- **`summary`** est aussi un champ de front matter reconnu par Hugo (résumé de page) : vérifier que le manifeste et `_partials/case.html` lisent la même valeur (`.Params.summary` ou `.Summary`), et que ce choix n'active pas un rendu Markdown non voulu.
- **Graphe de dépendances et mémoire** : `.memlog.md` garde une décision antérieure (« versions dans les ARG du Dockerfile », « contrôles dans `docker build --target checks` ») remplacée plus loin ; un agent qui lit la mémoire en premier peut suivre l'ancienne. Marquer les entrées remplacées.

## Synthèse des resserrements

| # | Resserrement | Où |
| --- | --- | --- |
| T1 | `scripts/build.sh` seul appel à `hugo`, drapeaux et destinations fixes, `.gitignore` | nouvel AD, AD-5, AD-13 |
| T2 | Image et paquets des contrôles épinglés ; pas d'Alpine pour les contrôles ; `runs-on` Gitea fixé | AD-1, AD-11, AD-13 |
| T3 | `check.sh` sans `.git` ; contrôles d'historique dans `checks-job.sh` seulement | AD-10 |
| T4 | Champ `kind` dans le manifeste, colonne Portée, `translationKey` de l'accueil, schéma JSON | AD-10, conventions |
| T5 | `render-heading.html` : `id` préfixé, niveau décalé pour un cas groupé | AD-4 |
| T6 | `planned` jamais résolu ; encart fixe en travail | AD-6 |
| T7 | Shortcode `legal`, chargeur `scripts/env.sh`, secret en fichier dotenv | AD-9 |
| T8 | Règle du socle face au pilote brouillon | AD-4, AD-14, C15 |
| T9 | Pages du socle par `translationKey`, dans un fichier de données | C15 |
| T10 | Format de tag, protocole `SSH_ORIGINAL_COMMAND`, installation de `deploy-site` et `compose.yaml` | AD-14 |
| T11 | `id` rattaché à un seul `translationKey` ; `<lang>` = `.Lang` | AD-6 |
| T12 | Aucun lecteur de front matter hors manifeste ; C16 et C4 réécrits | AD-7, AD-10, AD-16 |
| T13 | `[TODO` cherché dans `.Params` ; énumérations contrôlées | AD-10, C5, C6 |
| T14 | Format des fichiers `snippet` et `callout` | AD-6 |
| T15 | `hreflang` absolu, classé interne par les contrôles | AD-2, AD-17 |
| T16 | `disableKinds`, exclusions nommées, cas non mis en avant | AD-2, AD-17, C15 |
| T17 | Un fichier de configuration par environnement, propriété des clés, titre du site | AD-3, AD-5 |
| T18 | `fingerprint` sha256 imposé et contrôlé | AD-8 |
