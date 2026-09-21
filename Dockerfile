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
#   scripts/build-image.sh            construit l'image, contrôles au niveau standard
#   scripts/build-image.sh --release  y ajoute les contrôles de mise en ligne (epic 11)
#
# La commande s'écrit une seule fois, dans ce script : elle porte le secret BuildKit et les arguments.
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
# qui viderait l'image de sa garantie. Le secret est monté le temps de la commande et n'entre dans
# aucune couche : « docker history » ne montre aucune valeur légale (AD-9).
# TOOLS_LOCAL_DIR désigne un dossier inexistant : le .tools/ d'un poste ne peut pas entrer ici — le
# .dockerignore l'exclut —, mais la règle est écrite plutôt que supposée (story 3.13).
RUN --mount=type=secret,id=legal_env,required=true \
    ENV_MODE=release \
    LEGAL_ENV_FILE=/run/secrets/legal_env \
    TOOLS_LOCAL_DIR=/nonexistent/.tools \
    CHECK_LEVEL="${CHECK_LEVEL}" \
    ./scripts/build.sh production \
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
