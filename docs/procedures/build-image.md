# Procédure — Construire l'image du site

L'image ne contient que le site construit **et contrôlé** (AD-13). Ce qui est servi est exactement ce qui a passé `scripts/check.sh` : le build de l'image lance les contrôles, et un écart fait échouer le build.

```bash
scripts/build-image.sh                        # contrôles au niveau standard, image eleyone-site:dev
scripts/build-image.sh --release              # y ajoute les contrôles de mise en ligne (epic 11)
scripts/build-image.sh --tag eleyone-site:essai
scripts/build-image.sh --secret <fichier>     # autre fichier de valeurs légales
```

Codes de sortie : `0` image construite, `1` refus (build en échec, secret manquant), `2` anomalie (usage, Docker absent, `tools.env`).

Une **seule** commande de build vit dans le dépôt, dans ce script : l'epic 11 l'appellera avec `--release` plutôt que d'en écrire un second (décidé par Arnaud le 21/09/2026).

## Les trois étapes

1. **`tools`** — part de `CHECK_IMAGE`, un `ARG` **sans valeur par défaut** : la seule déclaration de l'image est `tools.env` (AD-1), et un `FROM` vide échoue plutôt que de bâtir sur une image non épinglée. L'étape copie `tools.env`, `scripts/ci/` et `scripts/lib/`, puis installe les outils épinglés.
2. **`build`** — copie les sources et lance **une seule instruction**, dont les commandes sont enchaînées par `&&` : le build Hugo de production, puis `scripts/check.sh`, puis `chmod -R a+rX public`. Un `;` laisserait passer un contrôle en échec, ce qui viderait l'image de sa garantie.
3. **`runtime`** — `nginx:1.30.4-alpine` **épinglée par digest**, le tag ne servant qu'à la lisibilité. Le contenu par défaut de l'image est retiré avant la copie, puis `public/` est copié dans `/usr/share/nginx/html`.

La configuration nginx de `deploy/nginx/` **n'est pas là** : elle arrive avec la story 4.2. Cette image sert `public/` avec la configuration par défaut de nginx.

## Le fichier de valeurs légales

`ENV_MODE=release` exige un fichier **dédié** et refuse aussi bien le `.env` du poste que le fichier factice commité (AD-9) — c'est voulu : une image de mise en ligne ne se construit pas avec des valeurs d'essai sans qu'on l'ait décidé.

Le fichier vit **hors du dépôt**, par défaut `~/.config/eleyone/legal-release.env` (décidé par Arnaud le 21/09/2026), et porte les sept variables `HUGO_LEGAL_*`. `LEGAL_RELEASE_ENV_FILE` ou `--secret` en désignent un autre.

Il passe par un **secret BuildKit** : monté le temps d'une instruction, il n'entre dans aucune couche, et `docker history` n'en montre rien.

```bash
# vérifier qu'aucune valeur légale n'a fui dans l'image
docker history --no-trunc eleyone-site:dev | grep -c "HUGO_LEGAL"   # attendu : 0
```

Pour un simple essai de la mécanique, un fichier jetable à valeurs quelconques suffit — sept variables, sans le mot `VALEUR-FACTICE`, que `ENV_MODE=release` refuse. Les pages légales de l'image porteront alors ces valeurs-là : c'est un essai, pas une image à servir.

## Vérifier

```bash
# ce qui est servi ne vient que de public/
diff <(cd public && find . -type f | sort) \
     <(docker run --rm --entrypoint sh eleyone-site:dev -c 'cd /usr/share/nginx/html && find . -type f | sort')

# un contrôle en échec fait échouer le build : casser une rubrique, construire, puis défaire
sed -i 's/^## What pushed back$/## Resistance/' content/cases/chiliz/case-02-chiliz.en.md
scripts/build-image.sh --secret <fichier>     # attendu : code 1, le contrôle nomme le fichier
git checkout -- content/cases/chiliz/case-02-chiliz.en.md
```

**Le build sans secret n'échoue que sans cache.** `docker build` réutilise la couche `RUN` d'un build précédent et ne demande alors pas le secret : le refus ne se constate qu'avec `--no-cache` (constaté le 21/09/2026).

```bash
docker build --no-cache --build-arg CHECK_IMAGE="$(sed -n 's/^CHECK_IMAGE=//p' tools.env)" .
# attendu : ERROR: failed to solve: secret legal_env: not found
```

## Pièges déjà rencontrés

- **Une directive n'en est une qu'en tête de fichier.** `# syntax=` et `# check=` doivent être les premières lignes du `Dockerfile`, avant tout autre commentaire ; placées plus bas, elles sont lues comme des commentaires et n'ont aucun effet. L'avertissement `InvalidDefaultArgInFrom` sur `CHECK_IMAGE` est écarté nommément, parce que l'absence de valeur par défaut est voulue et qu'un build bruyant finit par ne plus être lu.
- **`COPY` n'efface pas ce qu'il ne recouvre pas.** L'image nginx apporte son `50x.html`, une page d'erreur en anglais qui n'a passé aucun contrôle ; le dossier est donc vidé avant la copie.
- **Le contexte de build est envoyé au démon** : ce que `.dockerignore` exclut ne peut ni finir dans une couche, ni être lu par une instruction. Il exclut `.git/`, `.env`, `docs/private/`, `_bmad*/`, `.claude/`, `.agent*/`, les branches de design, et les sorties de build du poste — l'image reconstruit les siennes, et une sortie périmée ferait servir des pages qui n'ont pas passé les contrôles de ce build.
