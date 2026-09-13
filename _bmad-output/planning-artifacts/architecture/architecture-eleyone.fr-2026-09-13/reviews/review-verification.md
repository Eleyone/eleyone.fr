---
review: verification
target: ARCHITECTURE-SPINE.md (architecture-eleyone.fr-2026-09-13)
date: 2026-09-13
lens: "Chaque décision engagée a-t-elle été vérifiée (web, projet, spike) plutôt qu'affirmée de mémoire ?"
---

# Revue : vérification des affirmations techniques

## Verdict

Le document est très bien sourcé : les points les plus risqués (Hugo, Gitea, D2, NPM) ont été vérifiés par un spike ou dans le code source. Les affirmations **non listées** dans « Sources vérifiées » tiennent pour la plupart. Quatre points restent à corriger ou à confirmer par un spike avant les stories WS-3 à WS-5 :

1. l'outillage des contrôles HTML (`xmllint`, `jq`) n'est ni épinglé ni garanti sur les runners, et le parseur HTML de libxml2 change selon la version ;
2. les en-têtes nginx : `add_header` sans `always` n'est pas envoyé sur les 404, et nginx 1.30 propose `add_header_inherit merge;` ;
3. le secret BuildKit `--secret id=legal_env` a une résolution implicite ambiguë ;
4. les contrôles par `grep` sur un HTML minifié : Hugo retire les guillemets des attributs par défaut.

Légende : **confirmé** (source consultée le 13/09/2026), **infirmé** (la source contredit ou nuance fortement), **non vérifiable** (dépend de l'instance ou demande un spike).

## Constats majeurs

### V-1. `xmllint --html` : outil non épinglé, absent du runner GitHub, comportement variable selon la version — **infirmé (en partie)**

- **Affirmation (AD-10, AD-17)** : les contrôles HTML utilisent `xmllint --html` et `grep`, lancés de la même façon en local, sur Gitea, sur GitHub et dans l'étape `build` du `Dockerfile`. AD-1 épingle seulement Hugo et D2.
- **Constaté** :
  - Le paquet Alpine `libxml2-utils` existe et fournit `xmllint` : version **2.13.9-r2** sur Alpine v3.24. <https://pkgs.alpinelinux.org/packages?name=libxml2-utils&branch=v3.24&arch=x86_64>
  - Ubuntu 24.04 fournit `libxml2-utils` **2.9.14** (noble-updates). <https://packages.ubuntu.com/noble-updates/libxml2-utils>
  - L'image du runner GitHub `ubuntu-24.04` (version 20260907.300.1) ne liste **pas** `xmllint` ni `libxml2-utils` ; `jq` 1.7 y est bien présent. <https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md>
  - libxml2 n'a un tokenizer conforme à HTML5 que depuis **2.14.0** (« Several non-standard syntax warnings were removed »). Avant, le parseur HTML signale les balises HTML5 (`nav`, `section`, `figure`, `aside`…) comme « Tag … invalid ». Les trois environnements prévus (2.9.14, 2.13.9, image Gitea inconnue) sont tous antérieurs à 2.14 ou non déterminés. <https://github.com/GNOME/libxml2/blob/master/NEWS>, <https://gitlab.gnome.org/GNOME/libxml2/-/releases/v2.14.0>
  - L'image des runners Gitea dépend de l'instance (labels `ubuntu-latest:docker://…`) : on ne sait pas si `jq`, `curl`, `xmllint` ou `docker` y sont présents. **Non vérifiable** sans l'instance. <https://docs.gitea.com/runner/reference/config-example/>
- **Risque** : bruit ou code de sortie non nul sur un HTML5 valide ; résultats différents entre GitHub, Gitea et l'image, alors qu'AD-10 promet « un contrôle local qui ne diffère pas de celui de la CI ».
- **Correction proposée** :
  - Ajouter à AD-1 les outils des contrôles (`jq`, `xmllint`, éventuellement `curl`), avec version et empreinte dans `tools.env`, ou lancer `scripts/check.sh` dans un conteneur Alpine épinglé par digest, le même que l'étape `tools` du `Dockerfile`, sur les deux forges.
  - Faire un spike dans WS-3 : `xmllint --html --noout` sur une page Hugo réelle avec la version retenue ; noter le code de sortie et les messages, puis décider s'il faut filtrer « Tag … invalid » ou limiter `xmllint` à l'extraction par XPath (`--xpath`).
  - Vérifier sur l'instance Gitea l'image des labels du runner et y confirmer `jq`, `curl` et `docker`.

### V-2. nginx : `add_header` sans `always` et nouvelle directive `add_header_inherit` — **infirmé (en partie)**

- **Affirmation (AD-13)** : « un `add_header` dans une `location` annule ceux du niveau supérieur », d'où un fichier d'en-têtes inclus dans chaque bloc. Les pages 404 sont servies par `error_page`.
- **Constaté** :
  - La règle d'héritage est exacte **par défaut** : « inherited from the previous configuration level if and only if there are no add_header directives defined on the current level ». <https://nginx.org/en/docs/http/ngx_http_headers_module.html>
  - **Nouveau** : nginx **1.29.3** (28/10/2025) ajoute `add_header_inherit` (`on` | `off` | `merge`). La branche stable 1.30.x en découle, et `nginx:1.30.4` (15/07/2026) l'inclut. `add_header_inherit merge;` au niveau `server` rend l'inclusion répétée inutile. <https://nginx.org/en/CHANGES-1.30>, <https://blog.nginx.org/blog/nginx-open-source-1-29-3-and-1-29-4>
  - `add_header` ne s'applique qu'aux codes 200, 201, 204, 206, 301, 302, 303, 304, 307 et 308, **sauf avec le paramètre `always`**. Sans `always`, les réponses 404 (`/404.html`, `/en/404.html`) partent **sans** CSP, sans `nosniff` et sans `Referrer-Policy`. Même source.
- **Correction proposée** :
  - Ajouter `always` à chaque `add_header` de sécurité, puis vérifier dans WS-5 avec `curl -I` sur une URL inexistante.
  - Remplacer « inclure le fichier dans chaque bloc » par `add_header_inherit merge;` au niveau `server`, ou le mentionner comme option. Garder l'inclusion seulement si la configuration doit rester compatible avec nginx < 1.29.3, ce qui n'est pas le cas ici puisque l'image est épinglée.

### V-3. CSP par `map $sent_http_content_type` et valeur vide non envoyée — **confirmé (sources secondaires) ; valeur exacte à vérifier**

- **Affirmation (AD-13)** : la CSP n'est envoyée que sur `text/html`, grâce à un `map` sur `$sent_http_content_type`. Cela suppose qu'un `add_header` dont la valeur est vide n'émet rien.
- **Constaté** :
  - Un `add_header` de valeur vide n'est pas émis : le comportement est connu et signalé comme absent de la documentation officielle (issue ouverte). <https://github.com/nginx/nginx.org/issues/50>
  - Le motif `map $sent_http_… → add_header` est employé couramment. <https://www.axllent.org/docs/add-nginx-headers-if-not-set/>
  - La documentation officielle ne décrit aucun des deux points : **non confirmé par la source primaire**.
- **Correction proposée** : écrire le `map` avec une regex (`~^text/html`), car la valeur peut porter `; charset=utf-8` si une directive `charset` est ajoutée. Garder la démonstration `curl -I` de WS-5 comme preuve (CSP sur le HTML, absente sur un SVG, présente sur la 404 avec `always`).

### V-4. Secret BuildKit `--secret id=legal_env` — **confirmé, mais imprécis**

- **Affirmation (AD-9)** : les valeurs passent au `docker build` en secret BuildKit (`--secret id=legal_env`), jamais en `ARG`.
- **Constaté** :
  - Avec seulement `id`, Buildx cherche d'abord **une variable d'environnement nommée `legal_env`**, puis se replie sur un **fichier `./legal_env`** du répertoire courant. <https://docs.docker.com/reference/cli/docker/buildx/build/>
  - Dans le `Dockerfile`, le secret est monté par défaut dans `/run/secrets/<id>` (mode `0400`). L'option `env=` de `RUN --mount=type=secret` existe depuis **Dockerfile 1.10.0**, et `required=true` fait échouer l'instruction si le secret manque. <https://docs.docker.com/reference/dockerfile/#run---mounttypesecret>, <https://docs.docker.com/build/building/secrets/>
- **Correction proposée** : préciser la forme exacte. Soit `--secret id=legal_env,src=<fichier temporaire hors contexte>` et `RUN --mount=type=secret,id=legal_env,required=true` (puis `set -a; . /run/secrets/legal_env`) ; soit un secret par variable, `--secret id=HUGO_LEGAL_X,env=HUGO_LEGAL_X` et `RUN --mount=type=secret,id=HUGO_LEGAL_X,env=HUGO_LEGAL_X,required=true`, avec `# syntax=docker/dockerfile:1` en tête (≥ 1.10). La seconde forme évite d'écrire un fichier sur le runner.

### V-5. Contrôles `grep` sur HTML minifié — **confirmé (risque de conception)**

- **Affirmation (AD-10, AD-13, AD-17)** : l'étape `build` fait `hugo --environment production --minify`, puis `scripts/check.sh --release` contrôle `public/` par `grep` et `xmllint`.
- **Constaté** : les valeurs par défaut du minifieur de Hugo sont `keepQuotes: false`, `keepEndTags: true`, `keepDocumentTags: true`, `keepDefaultAttrVals: true`, `keepWhitespace: false`. Les attributs perdent donc leurs guillemets (`alt=Schéma`, `width=876`). <https://gohugo.io/configuration/minify/>
- **Risque** : un motif `grep` écrit sur le build non minifié des CI (`alt="…"`) ne voit plus rien sur le build minifié de l'image. Le contrôle passe alors à tort.
- **Correction proposée** : fixer dans AD-10 un seul mode, soit contrôler toujours un build minifié, soit ajouter `minify.tdewolff.html.keepQuotes: true` à la configuration. Faire de préférence les contrôles d'attributs par XPath (V-1) plutôt que par `grep`.

## Autres affirmations vérifiées

| # | Affirmation (emplacement) | Statut | Source | Correction |
| --- | --- | --- | --- | --- |
| 6 | `--panicOnWarning` existe (AD-5, C14) | confirmé | <https://gohugo.io/commands/hugo/> (« panic on first WARNING log ») | — |
| 7 | « Les dépréciations font échouer la CI » avec `--panicOnWarning` (AD-5) | confirmé avec nuance | <https://gohugo.io/troubleshooting/deprecation/> : INFO pendant 3 versions mineures, WARN pendant les 12 suivantes, puis ERROR. `.Site.Data` (v0.156) et `languageName` (v0.158) sont bien en WARN en v0.166 | Préciser qu'une dépréciation de moins de 3 versions mineures (niveau INFO) ne fait **pas** échouer le build. Si c'est voulu, ajouter `--logLevel info` et un `grep -i deprecated` |
| 8 | Empreinte sha256, soit 64 caractères hexadécimaux, pour le motif nginx `\.[0-9a-f]{64}\.(css\|svg)$` (AD-13) | confirmé | <https://gohugo.io/functions/resources/fingerprint/> (sha256 par défaut ; l'empreinte est insérée avant l'extension) | Interdire dans AD-8 tout `fingerprint "md5"` ou `"sha512"`, qui casserait le motif |
| 9 | `findRE` sur `.RawContent` pour extraire les H2 du Markdown brut (AD-10) | confirmé | <https://gohugo.io/functions/strings/findre/> (RE2) ; <https://gohugo.io/methods/page/rawcontent/> (sans front matter, shortcodes non rendus) | Utiliser `(?m)^## ` : RE2 n'a pas de lookbehind. Attention aux `##` dans les blocs de code |
| 10 | `jq` disponible sur `ubuntu-24.04` (AD-10, AD-16) | confirmé (GitHub) / non vérifiable (Gitea) | Readme de l'image runner GitHub, jq 1.7 | Voir V-1 : épingler ou vérifier sur l'image des runners Gitea |
| 11 | `ubuntu-24.04` est x64 (AD-7) | confirmé | Readme Ubuntu2404 ; source déjà citée dans le document | — |
| 12 | Actions tierces épinglées par SHA sur GitHub (AD-11) | confirmé | <https://docs.github.com/en/actions/reference/security/secure-use> : seul moyen d'avoir une référence immuable ; une politique au niveau du dépôt ou de l'organisation peut l'imposer | Activer la politique « require SHA pinning » sur le dépôt public |
| 13 | Gitea : `continue-on-error` au niveau du job (AD-16) | confirmé | <https://blog.gitea.com/release-of-1.27.0/> : pris en compte correctement depuis 1.27.0, **avec Gitea Runner 2.0.0** | Écrire dans AD-16 que Runner ≥ 2.0.0 est un prérequis, pas seulement une version de la table Stack |
| 14 | Gitea : filtre `paths` et types `opened`, `synchronize`, `reopened` sur `pull_request` (AD-16) | confirmé | Code `modules/actions/workflows.go` (`matchPullRequestEvent`) : `paths` et `paths-ignore` appliqués aux fichiers changés depuis la merge base ; types par défaut `opened`, `reopened`, `synchronize` | — |
| 15 | Gitea : `permissions:` du `GITEA_TOKEN` (AD-16) | confirmé (cité) ; portée non vérifiée | <https://docs.gitea.com/usage/actions/token-permissions/> (déjà cité) | La portée exacte pour commenter une PR reste à fixer dans la story, a priori l'écriture sur `pull-requests` |
| 16 | `POST /repos/{owner}/{repo}/issues/{index}/comments` fonctionne sur une PR (AD-16) | confirmé | <https://docs.gitea.com/api/1.27/> (opération « Add a comment to an issue ») ; code `routers/api/v1/repo/issue_comment.go` : `CreateIssueComment` traite `issue.IsPull` via `CanReadIssuesOrPulls(issue.IsPull)` | — |
| 17 | Mermaid : rendu dans le navigateur par JavaScript, ou export par un navigateur sans interface (ADR-2) | confirmé | <https://github.com/mermaid-js/mermaid-cli> (Puppeteer et Chromium) | — |
| 18 | WCAG 2.2 : 2.4.7 Focus Visible (AA), 2.4.11 Focus Not Obscured (Minimum) (AA), 2.5.8 Target Size (Minimum) (AA), 24 × 24 px CSS (AD-17) | confirmé | <https://www.w3.org/TR/WCAG22/>, <https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html> | Ajouter à la check-list les exceptions de 2.5.8 (liens dans une phrase, espacement), sinon on risque de « corriger » des liens de texte à tort. Citer aussi 1.4.3, 1.4.10 et 1.4.11 pour le contraste et le reflow |
| 19 | Définition de l'INP et argument « sans JS » (AD-17) | confirmé avec nuance | <https://web.dev/articles/inp> : clic, tap et clavier ; délai d'entrée + traitement + délai de présentation ; bon ≤ 200 ms. Les contrôles natifs sans JS produisent aussi un INP | Écrire que l'INP reste mesuré sans JS, mais que l'absence de gestionnaire d'événements le borne au coût de rendu, déjà limité par le budget DOM. La conclusion ne change pas |
| 20 | `docker save \| gzip \| ssh` puis `docker load` (AD-14) | confirmé | <https://docs.docker.com/reference/cli/docker/image/load/> (« even if compressed with gzip, bzip2, xz or zstd … from STDIN ») | — |
| 21 | Image `nginx:1.30.4-alpine` (Stack) | confirmé | <https://nginx.org/en/CHANGES-1.30> (1.30.4 du 15/07/2026) ; tag déjà cité | — |
| 22 | API Claude : `claude-opus-5` à 5 $ / 25 $, `claude-sonnet-5` à 2 $ / 10 $, estimation d'environ 0,08 $ par paire (AD-16) | confirmé | <https://platform.claude.com/docs/en/about-claude/pricing>, <https://platform.claude.com/docs/en/models/overview> (identifiants `claude-opus-5` et `claude-sonnet-5`). Le tarif de Sonnet 5 à 2 $ / 10 $ est devenu le prix standard ; la hausse prévue au 01/09/2026 n'aura pas lieu | Remplacer la source « skill, cache juin 2026 » par ces deux URL. L'estimation de 11 000 jetons n'est pas mesurée (**non vérifiable**) : la mesurer avec l'endpoint de comptage de jetons sur la paire du cas 02, le tokenizer des modèles ≥ 4.7 produisant environ 30 % de jetons en plus |
| 23 | Alpine : paquet `libxml2-utils` pour `xmllint` (AD-13, étape `build`) | confirmé | <https://pkgs.alpinelinux.org/packages?name=libxml2-utils&branch=v3.24&arch=x86_64> | Voir V-1 (version 2.13.9, antérieure au parseur HTML5) |

## Affirmations non vérifiées, à faible risque

Directives nginx `server_tokens off`, `absolute_redirect off`, `log_not_found off`, `gzip_vary on`, et `error_page` par `location` : directives anciennes et stables, non revues ici. Les démonstrations `curl -I` de WS-5 suffisent.

- « Pas de module `realip` » (AD-15) : l'image officielle compile le module ; il n'agit que si `set_real_ip_from` ou `real_ip_header` sont configurés. Reformuler en « aucune directive `set_real_ip_from` ou `real_ip_header` ». Non vérifié en ligne, **non vérifiable** sans lire la sortie de `nginx -V` de l'image.

## Hors périmètre de cette revue (constaté en passant)

- `.memlog.md` contient deux entrées dépassées par des entrées plus récentes, sans être marquées comme telles : ligne 29 (versions dans les `ARG` du `Dockerfile`, remplacées par `tools.env`) et ligne 30 (`docker build --target checks` sur les deux forges, remplacé par l'entrée de la ligne 42). Le spine est à jour ; seul le journal peut induire en erreur.
