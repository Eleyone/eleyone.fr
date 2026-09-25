# Procédure — Construire l'image du site

L'image ne contient que le site construit **et contrôlé** (AD-13). Ce qui est servi est exactement ce qui a passé `scripts/check.sh` : le build de l'image lance les contrôles, et un écart fait échouer le build.

```bash
scripts/build-image.sh                        # contrôles au niveau standard, image eleyone-site:dev
scripts/build-image.sh --release              # y ajoute les contrôles de mise en ligne
scripts/build-image.sh --tag eleyone-site:essai
scripts/build-image.sh --secret <fichier>     # autre fichier de valeurs légales
scripts/build-image.sh --patterns <fichier>   # autre liste de motifs interdits
```

Codes de sortie : `0` image construite, `1` refus (build en échec, secret manquant), `2` anomalie (usage, Docker absent, `tools.env`).

Une **seule** commande de build vit dans le dépôt, dans ce script : l'enveloppe de mise en ligne l'appelle avec `--release` plutôt que d'en écrire un second (décidé par Arnaud le 21/09/2026).

## Mettre en ligne : `scripts/release/build-image.sh <tag>`

```bash
scripts/release/build-image.sh v1.0.0        # mise en ligne
scripts/release/build-image.sh v1.0.0-rc.1   # répétition générale
```

Cette enveloppe **ne construit rien elle-même**. Elle est ce qui se trouve au-dessus de la commande de build : elle valide le tag, relève les valeurs de l'environnement, les écrit dans deux fichiers temporaires, délègue à `scripts/build-image.sh --release`, et supprime ces fichiers **même en cas d'échec**. L'image s'appelle `eleyone-site:<tag>`.

Ce qu'elle exige dans l'environnement — ce que la CI livrera en secrets (story 11.5) :

| Variable | Contenu |
| --- | --- |
| les huit `HUGO_LEGAL_*` d'AD-9 | les valeurs légales réelles |
| `PRIVATE_PATTERNS` | la liste des motifs interdits, une par ligne |

**Les noms des huit variables ne sont écrits nulle part dans le script** : il les lit dans `ci/legal-placeholder.env`, dont C18 vérifie qu'il porte exactement les noms d'AD-9. Une quatrième copie de cette liste serait la faute que le point 19 d'`AGENTS.md` nomme.

Tout ce qui suit fait échouer l'enveloppe **avant** le `docker build`, sans jamais afficher une valeur :

- un tag mal formé — sans le `v` initial, avec un zéro de tête (`v01.2.3`), avec un suffixe autre que `-rc.N`, ou avec un `-rc` sans numéro ;
- une valeur légale absente ou vide — toutes les absences sont nommées d'un coup ;
- une valeur qui porte un guillemet double (le chargeur la tronquerait en silence), un saut de ligne (le fichier en lirait deux entrées), ou encore `VALEUR-FACTICE` ;
- `PRIVATE_PATTERNS` absente, ou qui ne porte que des lignes vides et des commentaires ;
- un `TMPDIR` dont le chemin contient une virgule, que `docker build --secret` lit comme un séparateur.

Codes de sortie : `0` image construite, `1` refus, `2` anomalie (usage, `TMPDIR`, écriture impossible).

**Aucun `exec` pour déléguer**, à la différence de `scripts/build-image.sh` : `exec` remplace le processus et le piège `EXIT` ne tournerait jamais, laissant sur le disque du runner deux fichiers dont l'un porte les vraies valeurs légales. Le build tourne en enfant, son code est retenu, le nettoyage a lieu quoi qu'il arrive.

## Les trois étapes

1. **`tools`** — part de `CHECK_IMAGE`, un `ARG` **sans valeur par défaut** : la seule déclaration de l'image est `tools.env` (AD-1), et un `FROM` vide échoue plutôt que de bâtir sur une image non épinglée. L'étape copie `tools.env`, `scripts/ci/` et `scripts/lib/`, puis installe les outils épinglés.
2. **`build`** — copie les sources et lance **une seule instruction**, dont les commandes sont enchaînées par `&&` : `export` des variables, puis `scripts/check.sh`, puis `chmod -R a+rX public`. Un `;` laisserait passer un contrôle en échec, ce qui viderait l'image de sa garantie. Deux règles y tiennent tout le reste, et les deux ont été apprises en lançant le build plutôt qu'en le relisant (story 11.3) :

   - **les variables sont posées par `export`, jamais en préfixe de commande.** `FOO=x cmd1 && cmd2` ne pose `FOO` que pour `cmd1` ;
   - **un seul build, celui de `scripts/check.sh`**, qui construit lui-même le rendu de travail *et* le rendu de production avant de contrôler. Un `scripts/build.sh production` avant lui est écrasé.

   `scripts/tests/test-build-image.sh` refuse l'une et l'autre : aucune affectation hors d'un `export`, aucun appel à `build.sh` dans l'instruction.
3. **`runtime`** — `nginx:1.30.4-alpine` **épinglée par digest**, le tag ne servant qu'à la lisibilité. Le contenu par défaut de l'image est retiré avant la copie, puis `public/` est copié dans `/usr/share/nginx/html` et `deploy/nginx/site.conf` remplace la configuration par défaut (voir « Ce que sert nginx »).

## Le fichier de valeurs légales

`ENV_MODE=release` exige un fichier **dédié** et refuse aussi bien le `.env` du poste que le fichier factice commité (AD-9) — c'est voulu : une image de mise en ligne ne se construit pas avec des valeurs d'essai sans qu'on l'ait décidé.

Le fichier vit **dans le dépôt privé**, par défaut `docs/private/legal-release.env` (décidé par Arnaud le 21/09/2026), et porte les huit variables `HUGO_LEGAL_*`. `LEGAL_RELEASE_ENV_FILE` ou `--secret` en désignent un autre ; le défaut, lui, est absolu, pour ne pas dépendre du dossier d'où le script est lancé.

Ces huit valeurs ne sont pas des identifiants : ce sont les mentions légales, destinées à être publiées. Le mot « secret » est ici le terme de BuildKit — « n'entre dans aucune couche » — et non une affirmation de confidentialité. Elles restent hors du dépôt public parce qu'il est public, pas parce qu'elles seraient sensibles ; `docs/private/` est donc leur place, et les y versionner les sauvegarde sur la forge privée au lieu de les laisser sur une seule machine. Le penser à créer après un `git clean -ffdx` est le prix à payer ; `git -C docs/private commit` les enregistre, comme tout le reste du dépôt privé.

Quatre garde-fous indépendants les empêchent d'entrer dans le dépôt public : `.gitignore` ignore `docs/private/`, `scripts/check-private.sh` refuse ce chemin **et** le suffixe `.env` séparément, le hook `pre-receive` de la forge refuse les mêmes, et `.dockerignore` exclut le dossier du contexte de build. Ce dernier ne gêne pas la lecture du secret : `docker build --secret id=…,src=…` lit le fichier sur le disque, hors du contexte (vérifié le 21/09/2026).

Il passe par un **secret BuildKit** : monté le temps d'une instruction, il n'entre dans aucune couche, et `docker history` n'en montre rien.

```bash
# vérifier qu'aucune valeur légale n'a fui dans l'image
docker history --no-trunc eleyone-site:dev | grep -c "HUGO_LEGAL"   # attendu : 0
```

Pour un simple essai de la mécanique, un fichier jetable à valeurs quelconques suffit — huit variables, sans le mot `VALEUR-FACTICE`, que `ENV_MODE=release` refuse. Les pages légales de l'image porteront alors ces valeurs-là : c'est un essai, pas une image à servir.

## La liste des motifs interdits

`.dockerignore` exclut `docs/private/` du contexte de build : la liste des motifs ne peut entrer dans l'image que par un **second secret BuildKit**, `private_patterns`, monté sur la même instruction, et désigné par `PRIVATE_PATTERNS_FILE` (story 11.3).

Sans elle, C21 ne confronte ni le texte, ni les métadonnées, ni le XMP des deux CV, et C22 rend une anomalie. Le secret est donc **facultatif dans le `Dockerfile`** — un build ordinaire du poste n'a rien à confronter — et **obligatoire au niveau `release`**, où les deux contrôles l'exigent.

Deux régimes côté script, et c'est l'**option** qui les sépare, pas la variable :

| Comment la liste est désignée | Fichier absent |
| --- | --- |
| `--patterns <fichier>` | refus, à tout niveau : un acte explicite ne se dégrade pas en silence |
| `PRIVATE_PATTERNS_FILE`, ou le défaut `docs/private/forbidden-patterns.txt` | build ordinaire : le script le dit et continue sans second secret ; `--release` : refus |

Vérifié : quand le secret n'est pas fourni, BuildKit **ne monte rien** et le fichier n'existe pas — ce que C21 lit comme « liste absente ».

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

**Le build sans secret n'échoue que sans cache.** `docker build` réutilise la couche `RUN` d'un build précédent et ne demande alors pas le secret : le refus ne se constate qu'avec `--no-cache` (constaté le 21/09/2026). La remarque vise un `docker build` lancé à la main ; `scripts/build-image.sh` force lui-même l'étape à se rejouer, pour la raison qui suit.

```bash
docker build --no-cache --build-arg CHECK_IMAGE="$(sed -n 's/^CHECK_IMAGE=//p' tools.env)" .
# attendu : ERROR: failed to solve: secret legal_env: not found
```

### Le cache, et pourquoi `build,runtime`

C'est la même cause, vue de l'autre côté : **un secret n'entre pas dans la clé de cache de BuildKit**. Une valeur légale modifiée entre deux constructions ne change rien à cette clé, et la seconde image servirait les mentions légales de la première. `scripts/build-image.sh` passe donc `--no-cache-filter build,runtime` à chaque appel ; l'étape `tools`, la longue — elle télécharge et installe Hugo et D2 —, garde son cache, et c'est tout l'intérêt de nommer les étapes plutôt que d'écrire `--no-cache`.

**La seule étape `build` ne suffit pas**, et c'est une mesure (Docker 29.8.1, buildx 0.37.1, 25/09/2026). Avec `--no-cache-filter build`, l'instruction `RUN` se rejoue — `docker build --target build` le montre, la page porte la nouvelle valeur — mais le `COPY --from=build /src/public/` de l'étape `runtime` est servi depuis le cache : trois constructions successives avec trois valeurs différentes ont toutes exporté le manifeste `sha256:4e9d3d2d…`. Avec `build,runtime`, la même construction exporte un manifeste différent et la page porte la bonne valeur.

```bash
# la vérification, à rejouer : deux constructions, une valeur légale modifiée entre les deux
HUGO_LEGAL_PUBLISHER_NAME=EDITEUR-PREMIER scripts/release/build-image.sh v0.0.2
docker run --rm --entrypoint grep eleyone-site:v0.0.2 -o EDITEUR-PREMIER /usr/share/nginx/html/mentions-legales/index.html
HUGO_LEGAL_PUBLISHER_NAME=EDITEUR-SECOND  scripts/release/build-image.sh v0.0.2
docker run --rm --entrypoint grep eleyone-site:v0.0.2 -o EDITEUR-SECOND  /usr/share/nginx/html/mentions-legales/index.html
```

## Pièges déjà rencontrés

- **Une directive n'en est une qu'en tête de fichier.** `# syntax=` et `# check=` doivent être les premières lignes du `Dockerfile`, avant tout autre commentaire ; placées plus bas, elles sont lues comme des commentaires et n'ont aucun effet. L'avertissement `InvalidDefaultArgInFrom` sur `CHECK_IMAGE` est écarté nommément, parce que l'absence de valeur par défaut est voulue et qu'un build bruyant finit par ne plus être lu.
- **`COPY` n'efface pas ce qu'il ne recouvre pas.** L'image nginx apporte son `50x.html`, une page d'erreur en anglais qui n'a passé aucun contrôle ; le dossier est donc vidé avant la copie.
- **Un préfixe d'affectation ne vaut que pour une commande.** `FOO=x cmd1 && cmd2` ne pose `FOO` que pour `cmd1`. L'instruction `RUN` écrivait `ENV_MODE` et `LEGAL_ENV_FILE` devant `scripts/build.sh` : `scripts/check.sh`, la commande suivante, tournait sans elles et retombait sur `ci/legal-placeholder.env`. L'image emportait des mentions légales portant `VALEUR-FACTICE`. Le `if` ne trahissait rien, `${CHECK_LEVEL}` y étant interpolé par Docker avant que le shell ne le lise. Mesuré le 25/09/2026, après avoir survécu à une revue de code et à deux epics.
- **Un build redondant cache un build fautif.** Le même `scripts/build.sh production` était inutile — `scripts/check.sh` reconstruit lui-même les deux rendus — et c'est sa redondance qui rendait le défaut ci-dessus invisible : un build correct précédait le build fautif, dont sortait pourtant le `public/` copié dans l'image.
- **`--no-cache-filter <étape>` n'invalide pas ce qui copie depuis cette étape.** Voir « Le cache, et pourquoi `build,runtime` » ci-dessus.
- **Le contexte de build est envoyé au démon** : ce que `.dockerignore` exclut ne peut ni finir dans une couche, ni être lu par une instruction. Il exclut `.git/`, `.env`, `docs/private/`, `_bmad*/`, `.claude/`, `.agent*/`, les branches de design, et les sorties de build du poste — l'image reconstruit les siennes, et une sortie périmée ferait servir des pages qui n'ont pas passé les contrôles de ce build.
