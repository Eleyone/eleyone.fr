# syntax=docker/dockerfile:1
# check=skip=InvalidDefaultArgInFrom
# Ces deux lignes sont des **directives**, pas des commentaires : elles ne valent qu'en tête de
# fichier, avant toute autre ligne. Placées plus bas, elles sont lues comme des commentaires et
# n'ont aucun effet (constaté le 21/09/2026). « check=skip » écarte nommément l'avertissement sur
# CHECK_IMAGE, volontairement sans valeur par défaut : la seule déclaration de l'image est
# tools.env (AD-1), et un build bruyant finit par ne plus être lu.

# Image du site (AD-13) : trois étapes, dont une seule produit quelque chose qui survit. Ce qui est
# servi est exactement ce qui a passé les contrôles, et rien d'autre du dépôt n'entre dans l'image.
#
#   scripts/build-image.sh                construit l'image, contrôles au niveau standard
#   scripts/build-image.sh --release      y ajoute les contrôles de mise en ligne
#   scripts/release/build-image.sh <tag>  l'enveloppe de mise en ligne, qui appelle la précédente
#
# La commande s'écrit une seule fois, dans scripts/build-image.sh : elle porte les deux secrets
# BuildKit et les arguments. L'enveloppe, elle, ne construit rien — elle prépare et nettoie.
# Procédure : docs/procedures/build-image.md

# --- outils épinglés ------------------------------------------------------------------------------
# CHECK_IMAGE n'a pas de valeur par défaut : la seule déclaration est tools.env (AD-1), et un FROM
# sur un argument vide échouerait plutôt que de bâtir sur une image non épinglée.
ARG CHECK_IMAGE
FROM ${CHECK_IMAGE} AS tools
WORKDIR /src
# Seulement ce dont l'installation a besoin : tools.env porte les versions et les empreintes,
# scripts/ci/ l'amorçage, scripts/lib/ sa lecture. Sans eux, l'amorçage s'arrête sur « tools.env
# introuvable » (constat de la revue de spec).
COPY tools.env ./
COPY scripts/ci/ ./scripts/ci/
COPY scripts/lib/ ./scripts/lib/
RUN ./scripts/ci/install-tools-bootstrap.sh

# --- build et contrôles ---------------------------------------------------------------------------
FROM tools AS build
WORKDIR /src
COPY . .
# CHECK_LEVEL vaut « standard » ; seul scripts/build-image.sh --release passe « release » (AD-13).
ARG CHECK_LEVEL=standard
# Une seule instruction, enchaînée par « && » : un « ; » laisserait passer un contrôle en échec, ce
# qui viderait l'image de sa garantie. Les secrets sont montés le temps de la commande et n'entrent
# dans aucune couche : « docker history » ne montre ni valeur légale, ni motif (AD-9, AD-12).
#
# **« export », et surtout pas un préfixe d'affectation.** En shell, « FOO=x cmd1 && cmd2 » ne pose
# FOO que pour cmd1 : cmd2 ne la voit pas. L'instruction écrivait ainsi ENV_MODE et LEGAL_ENV_FILE
# devant scripts/build.sh, et scripts/check.sh — qui reconstruit lui-même les deux rendus — tournait
# **sans elles**, donc sans secret, avec le repli sur ci/legal-placeholder.env : l'image emportait des
# mentions légales portant « VALEUR-FACTICE » (mesuré le 25/09/2026, story 11.3). Le « if » ne le
# trahissait pas, « ${CHECK_LEVEL} » y étant interpolé par Docker avant que le shell ne le lise.
# scripts/tests/test-build-image.sh refuse désormais toute affectation qui ne soit pas un « export ».
#
# **Un seul build, celui de scripts/check.sh.** Le « scripts/build.sh production » qui précédait était
# redondant — check.sh construit le rendu de travail **et** le rendu de production avant de contrôler
# —, et c'est cette redondance qui rendait le défaut ci-dessus invisible : un build correct précédait
# le build fautif, dont sortait pourtant le public/ copié dans l'image.
#
# TOOLS_LOCAL_DIR désigne un dossier inexistant : le .tools/ d'un poste ne peut pas entrer ici — le
# .dockerignore l'exclut —, mais la règle est écrite plutôt que supposée (story 3.13).
# PRIVATE_PATTERNS_FILE désigne le second secret, **facultatif** : sans lui le fichier n'existe pas
# (vérifié, BuildKit ne monte rien), C21 se contente de la forme et C22 ne tourne pas au niveau
# standard. Au niveau release, les deux exigent la liste et l'instruction échoue sans elle (AD-12,
# AD-21) : .dockerignore exclut docs/private/ du contexte, la liste ne peut entrer que par là.
RUN --mount=type=secret,id=legal_env,required=true \
    --mount=type=secret,id=private_patterns \
    export ENV_MODE=release \
      LEGAL_ENV_FILE=/run/secrets/legal_env \
      PRIVATE_PATTERNS_FILE=/run/secrets/private_patterns \
      TOOLS_LOCAL_DIR=/nonexistent/.tools \
    && if [ "${CHECK_LEVEL}" = release ]; then ./scripts/check.sh --release; else ./scripts/check.sh; fi \
    && chmod -R a+rX public

# --- ce qui est servi -------------------------------------------------------------------------------
# Épinglée par digest ; le tag ne sert qu'à la lisibilité.
FROM nginx:1.30.4-alpine@sha256:dc5069ad14f19660b141b21236140b91656bf89bbc3e2417c70ae650cd66104c AS runtime
# Le contenu par défaut de l'image est retiré avant la copie : « COPY » écrase index.html mais
# laisserait 50x.html, une page d'erreur en anglais que le site ne sert pas et qui n'a passé aucun
# contrôle (constaté au premier build, 21/09/2026). Ce qui est servi ne vient que de public/.
RUN rm -rf /usr/share/nginx/html && mkdir -p /usr/share/nginx/html
COPY --from=build /src/public/ /usr/share/nginx/html/
# La configuration remplace celle de l'image : en-têtes, cache, 404 par langue et journal sans
# adresse IP (AD-13, AD-15). TLS et HSTS relèvent du reverse proxy, pas d'ici.
COPY deploy/nginx/site.conf /etc/nginx/conf.d/default.conf
