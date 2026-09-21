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

Le fichier vit **dans le dépôt privé**, par défaut `docs/private/legal-release.env` (décidé par Arnaud le 21/09/2026), et porte les sept variables `HUGO_LEGAL_*`. `LEGAL_RELEASE_ENV_FILE` ou `--secret` en désignent un autre ; le défaut, lui, est absolu, pour ne pas dépendre du dossier d'où le script est lancé.

Ces sept valeurs ne sont pas des identifiants : ce sont les mentions légales, destinées à être publiées. Le mot « secret » est ici le terme de BuildKit — « n'entre dans aucune couche » — et non une affirmation de confidentialité. Elles restent hors du dépôt public parce qu'il est public, pas parce qu'elles seraient sensibles ; `docs/private/` est donc leur place, et les y versionner les sauvegarde sur la forge privée au lieu de les laisser sur une seule machine. Le penser à créer après un `git clean -ffdx` est le prix à payer ; `git -C docs/private commit` les enregistre, comme tout le reste du dépôt privé.

Quatre garde-fous indépendants les empêchent d'entrer dans le dépôt public : `.gitignore` ignore `docs/private/`, `scripts/check-private.sh` refuse ce chemin **et** le suffixe `.env` séparément, le hook `pre-receive` de la forge refuse les mêmes, et `.dockerignore` exclut le dossier du contexte de build. Ce dernier ne gêne pas la lecture du secret : `docker build --secret id=…,src=…` lit le fichier sur le disque, hors du contexte (vérifié le 21/09/2026).

Il passe par un **secret BuildKit** : monté le temps d'une instruction, il n'entre dans aucune couche, et `docker history` n'en montre rien.

```bash
# vérifier qu'aucune valeur légale n'a fui dans l'image
docker history --no-trunc eleyone-site:dev | grep -c "HUGO_LEGAL"   # attendu : 0
```

Pour un simple essai de la mécanique, un fichier jetable à valeurs quelconques suffit — sept variables, sans le mot `VALEUR-FACTICE`, que `ENV_MODE=release` refuse. Les pages légales de l'image porteront alors ces valeurs-là : c'est un essai, pas une image à servir.

## Ce que sert nginx

`deploy/nginx/site.conf` entre dans l'image et remplace la configuration par défaut (AD-13, AD-15). TLS, HSTS et la redirection HTTPS relèvent du reverse proxy, pas d'ici : il se configure à la première mise en ligne (epic 11).

- **En-têtes**, au niveau `server`, tous avec `always` — sans quoi ils manqueraient sur une 404 — et précédés d'`add_header_inherit merge;`, sans lequel un `add_header` dans un `location` effacerait tous ceux du `server` : `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, plus la CSP et le `Cache-Control`, qui dépendent de ce qui est servi.
- **La CSP n'est posée que sur le HTML**, par `map $sent_http_content_type` : les schémas D2 portent des `<style>` et des polices embarquées, qu'un `style-src 'self'` casserait. Une valeur vide supprime l'en-tête.
- **Le cache dépend du nom du fichier**, par `map $uri` : un an et `immutable` pour un fichier empreinté d'un condensat, qui ne change jamais de contenu sous le même nom ; `no-cache` pour **tout le reste** — HTML, PDF, images non empreintées (décidé par Arnaud le 21/09/2026). Le navigateur revérifie et ne retransfère rien si rien n'a changé ; une photo remplacée est vue tout de suite.
- **404 par langue** : `error_page 404 /404.html;` et, dans `location /en/`, `/en/404.html`. Le statut reste `404` : servir la bonne page en `200` ferait indexer les erreurs.
- **Journal sans adresse IP** (NFR-3, FR-19) : date, méthode, `$uri`, statut, taille. `$uri` et non `$request`, qui porterait la chaîne de requête ; ni user-agent, ni referer, et aucun module `real_ip`.

### Deux pièges du fichier lui-même

- **Une regex à accolades se met entre guillemets.** `~\.[0-9a-f]{64}\.` sans guillemets fait lire `{64}` comme l'ouverture d'un bloc, et `nginx -t` répond « unexpected "{" ».
- **`log_format` et `map` appartiennent au contexte `http`**, pas au `server` : déclarés dedans, `nginx -t` répond « directive is not allowed here ».

## Vérifier le serveur, contre un vrai conteneur

Les cas de `scripts/tests/test-nginx-conf.sh` lisent le fichier ; le comportement se vérifie en lançant l'image.

```bash
docker rm -f essai-nginx 2>/dev/null; docker run -d --name essai-nginx -p 18080:80 eleyone-site:dev
docker exec essai-nginx sh -c 'printf "body{}" > /usr/share/nginx/html/a.$(printf "%064d" 1).css
  printf img > /usr/share/nginx/html/portrait.webp; printf %%PDF > /usr/share/nginx/html/cv.pdf'

curl -sS -D - -o /dev/null http://localhost:18080/            # CSP, nosniff, referrer, no-cache
curl -sS -D - -o /dev/null http://localhost:18080/portrait.webp   # no-cache, aucune CSP
curl -sS -o /dev/null -w '%{http_code}\n' http://localhost:18080/nexiste-pas       # 404
curl -sS http://localhost:18080/en/nexiste-pas | grep -o '<html[^>]*>'              # lang=en
curl -sS -H 'Accept-Encoding: gzip' -D - -o /dev/null http://localhost:18080/sitemap.xml  # gzip
curl -sS -D - -o /dev/null http://localhost:18080/dossier | grep -i ^location       # relatif
curl -sS -o /dev/null -A espion -e http://referer.invalide/ 'http://localhost:18080/?secret=abc'
docker logs --tail 1 essai-nginx    # ni IP, ni chaîne de requête, ni user-agent, ni referer
docker rm -f essai-nginx
```

**Le seuil de compression est de 20 octets** : un fichier d'essai plus court part non compressé, et l'absence de `Content-Encoding` ne prouve alors rien.

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
