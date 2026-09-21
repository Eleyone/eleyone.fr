# Story 4.2 : Nginx headers, cache, 404 and IP-free logs

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 4.2.

## Revue de spec

### 21/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `1395af1`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: ec981116e9bd5cf6a503372e

*Note sur le listage : N'ayant pas d'outil spécifique pour lister les répertoires dans mes outils de fichiers et l'exécution de toute commande shell (comme `ls`) m'étant strictement interdite, je n'ai pas pu lister le contenu du répertoire au préalable. J'ai lu directement les documents de contexte et le fichier `REVIEW-SPEC.md` avec l'outil de lecture.*

##### Rapport de revue BMAD

###### 🔍 Lentille : Adversarial (Cas limites, lacunes et contradictions)

**1. Lacune de vérification : Politique de cache des PDF**
- **Condition de déclenchement** : La liste des tâches demande un `no-cache` pour les PDF.
- **Extrait correctif / Garde-fou** : Ajouter un critère BDD vérifiant explicitement ce comportement : `Étant donné un fichier PDF... Alors la réponse porte Cache-Control: no-cache`.
- **Conséquence potentielle** : La règle est ignorée par le développement ou casse lors d'une régression (par exemple sur les CV PDF d'AD-21), et la spec ne le remarque pas.

**2. Lacune de vérification : Compression Gzip**
- **Condition de déclenchement** : La check-list exige `gzip` pour HTML, CSS, SVG, JSON et XML.
- **Extrait correctif / Garde-fou** : Ajouter un critère où la requête demande la compression (`Accept-Encoding: gzip`) et où l'on vérifie l'en-tête `Content-Encoding: gzip`.
- **Conséquence potentielle** : La compression est mal configurée ou oubliée, dégradant les performances (NFR-5) sans qu'aucun test ne bloque la story.

**3. Lacune de vérification : Code de statut de la page 404**
- **Condition de déclenchement** : Le critère 3 stipule que la 404 "sert `/404.html`".
- **Extrait correctif / Garde-fou** : Exiger que le code HTTP retourné soit bien un `404 Not Found`.
- **Conséquence potentielle** : Le serveur pourrait servir le bon fichier avec un statut HTTP `200 OK` ou `302 Found`, causant l'indexation de pages d'erreurs par les moteurs de recherche.

**4. Contradiction : Nginx Proxy Manager vs Opération manuelle**
- **Condition de déclenchement** : La story est censée couvrir l'AD-15 qui exige des journaux sans IP "dans le conteneur et dans Nginx Proxy Manager", mais la story affiche "Opération manuelle (Arnaud) : non". 
- **Extrait correctif / Garde-fou** : Soit indiquer "oui" pour configurer NPM à cette étape, soit retirer la couverture de NPM de cette story (repoussée à l'Epic 11 de mise en ligne).
- **Conséquence potentielle** : Le traçage des IP persiste côté proxy, rompant l'exigence NFR-3 et FR-19 d'anonymat.

**5. Ambiguïté d'application : Fichiers images non empreintés**
- **Condition de déclenchement** : Le critère 2 applique un cache `immutable` (1 an) sur les fichiers `webp`. La photo de profil (AD-19, `portrait.webp`) n'est pas traitée par Hugo Pipes avec empreinte dans les stories décrites.
- **Extrait correctif / Garde-fou** : Affiner la règle Nginx pour ne cibler que les assets disposant d'un hash dans le nom, ou clarifier le système d'empreinte sur les images.
- **Conséquence potentielle** : Si le portrait est mis à jour, les visiteurs garderont l'ancienne photo pendant un an en cache.

**6. Ambiguïté : CSP exacte non définie**
- **Condition de déclenchement** : Le critère 1 attend "la CSP exacte d'AD-13". AD-13 dit juste "CSP sur HTML seulement", sans fournir la chaîne (AD-6 implique `style-src 'self'`).
- **Extrait correctif / Garde-fou** : Inscrire la valeur littérale de l'en-tête `Content-Security-Policy` complet dans les critères.
- **Conséquence potentielle** : Impossibilité pour un relecteur de valider avec certitude l'implémentation.

**7. Ambiguïté : En-têtes communs**
- **Condition de déclenchement** : Le critère 2 applique les "en-têtes communs" aux assets.
- **Extrait correctif / Garde-fou** : Définir clairement s'il s'agit de `X-Content-Type-Options` et `Referrer-Policy`.
- **Conséquence potentielle** : Le développeur implémente les en-têtes à sa propre discrétion.

**8. Lacune de vérification : Absence de Set-Cookie étendue**
- **Condition de déclenchement** : Le critère 1 vérifie `sans Set-Cookie` pour le HTML, mais le critère 2 omet de vérifier cela pour les ressources statiques.
- **Extrait correctif / Garde-fou** : Ajouter `sans Set-Cookie` à la fin du critère 2.
- **Conséquence potentielle** : Fuite potentielle ou invalidation du cache sur des assets statiques si un cookie est généré.

**9. Lacune de vérification : absolute_redirect off**
- **Condition de déclenchement** : La liste de tâches inclut `absolute_redirect off;`. 
- **Extrait correctif / Garde-fou** : Tester que la redirection d'un dossier sans barre oblique finale donne bien une localisation relative et non absolue.
- **Conséquence potentielle** : Le site pourrait casser derrière un proxy si les redirections absolues portent sur le port local du conteneur.

**10. Lacune de vérification : JSON et XML**
- **Condition de déclenchement** : La liste de tâches inclut JSON et XML pour la compression gzip, mais ils ne sont couverts par aucun critère de cache ou de sécurité (contrairement à HTML et CSS/SVG).
- **Extrait correctif / Garde-fou** : Créer un critère pour valider les en-têtes servis avec le manifeste de vérification (`checks.json`) et le sitemap.
- **Conséquence potentielle** : Ces fichiers fuient des en-têtes non voulus ou restent non compressés.

###### 🏗️ Lentille : Structure (Organisation des exigences)

**Asymétrie entre Tâches et Critères BDD**
- La liste de puces en fin de document ("`server_tokens off; absolute_redirect off...`") agit comme un guide d'implémentation, mais le comportement de la majorité de ces éléments (PDF, gzip, redirections) n'est jamais validé par les critères d'acceptation de type BDD ("Étant donné... Quand... Alors"). Cela brise la structure habituelle : tout comportement implémenté doit être vérifiable formellement.

###### 📝 Lentille : Prose (Clarté, expression et présentation)

**Langage flou et externalisé**
- Les termes "en-têtes communs" et "la CSP exacte d'AD-13" forcent le lecteur ou le développeur à déduire l'attendu à partir d'autres documents au lieu d'avoir l'information testable sous les yeux. La clarté de la spec s'en trouve amoindrie.
- L'expression "démonstration de WS-5" au sein du critère 3 ressemble à une note de conception mêlée au critère d'acceptation, brouillant l'ordre des idées. 

---

##### À trancher avant d'implémenter

- **Périmètre Nginx Proxy Manager (AD-15)** : Doit-on passer la story en "Opération manuelle : oui" pour y inclure la configuration de NPM sur l'infrastructure existante, ou ce volet est-il repoussé à une story de déploiement (Epic 11) ?
- **Littéraux des en-têtes** : Faut-il inscrire dans le texte de la story les chaînes exactes pour la "CSP" et les "en-têtes communs" afin de rendre les tests déterministes ?
- **Comportements non testés** : Est-ce qu'on ajoute des critères BDD pour vérifier concrètement la compression Gzip, l'absence de cache sur les PDF, et le statut HTTP strict (404) sur les pages d'erreur ?
- **Cache agressif sur le WebP** : La photo `portrait.webp` doit-elle recevoir le même cache `immutable` d'un an que les assets empreintés, au risque de poser problème lors d'une future mise à jour ?

### Triage (21/09/2026)

**Retenu — quatre comportements exigés n'étaient vérifiés par aucun critère.** La liste de puces demandait `gzip`, `no-cache` sur les PDF, `absolute_redirect off` et une 404 « qui sert `/404.html` » sans dire avec quel **statut**. Un comportement qu'aucun critère ne vérifie finit par disparaître sans bruit : chacun devient un critère, et le statut `404` est écrit noir sur blanc — servir la bonne page en `200` ferait indexer les erreurs.

**Retenu — les littéraux entrent dans la story.** « La CSP exacte d'AD-13 » et « les en-têtes communs » obligeaient à aller lire ailleurs pour juger. Les trois en-têtes et la politique sont désormais écrits dans les critères. Leur déclaration reste unique — `deploy/nginx/` —, mais un critère invérifiable sans autre document n'est pas un critère.

**Retenu — `Set-Cookie` se vérifie aussi sur les ressources.** Le critère ne l'exigeait que sur le HTML.

**Retenu, et arbitré par Arnaud (21/09/2026) — les fichiers non empreintés.** Ni HTML, ni PDF, ni condensat : la photo en est le cas typique. Ils reçoivent **`no-cache`**, comme le HTML. Le navigateur revérifie et ne retransfère rien si rien n'a changé ; une photo remplacée est vue tout de suite. Sans cette règle, un `webp` non empreinté serait tombé soit dans l'`immutable` d'un an — une photo figée pour un an —, soit dans l'heuristique du navigateur, dont on ne peut rien dire.

**Refusé — étendre la story à Nginx Proxy Manager.** AD-15 couvre le conteneur **et** le proxy, mais le proxy n'existe pas encore : il se configure à la première mise en ligne, et l'architecture en fait l'étape 5 de sa procédure de premier déploiement (epic 11). Cette story livre ce qui tient dans l'image. La story le dit, pour qu'on ne croie pas NFR-3 acquis de bout en bout.

**Vérifié plutôt que supposé — `add_header_inherit merge`.** La directive qu'AD-13 prescrit existe bien dans l'image servie : `nginx -t` l'accepte en 1.30.4 (essayé le 21/09/2026). Sans elle, un `add_header` dans un `location` effacerait tous les en-têtes du niveau `server`.

**Corrigé au passage — une trace de la story 4.1 dans AD-14.** La décision d'Arnaud du 21/09/2026 a remplacé `scripts/release/build-image.sh` par `scripts/build-image.sh --release` ; AD-13 le disait déjà, AD-14 citait encore l'ancien chemin dans le workflow de mise en ligne.

### Réponse d'Arnaud (21/09/2026)

**Fichiers non empreintés** — ni HTML, ni PDF, ni condensat, la photo en tête : `no-cache`, comme le HTML. Le navigateur revérifie, ne retransfère rien si rien n'a changé, et une photo remplacée est vue tout de suite. Les fichiers empreintés gardent leur an d'`immutable`.

## Ce qui est livré

- `deploy/nginx/site.conf` — en-têtes au niveau `server` avec `always` et `add_header_inherit merge`, CSP sur le HTML seul par `map $sent_http_content_type`, cache par `map $uri`, 404 par langue, journal sans adresse IP, `gzip`, et les trois réglages de discrétion (`server_tokens`, `absolute_redirect`, `log_not_found`).
- `Dockerfile` — l'image emporte sa configuration.
- `docs/procedures/build-image.md` — une section sur ce que sert nginx, la recette de vérification contre un vrai conteneur, et les deux pièges du fichier.
- `scripts/tests/test-nginx-conf.sh` — 10 cas hors ligne sur la configuration elle-même.

### Quatre choses que seul un vrai conteneur pouvait montrer

1. **Une regex à accolades se met entre guillemets.** `~\.[0-9a-f]{64}\.` sans guillemets fait lire `{64}` comme l'ouverture d'un bloc : `nginx -t` répond « unexpected "{" ».
2. **`log_format` appartient au contexte `http`**, pas au `server` : « directive is not allowed here ».
3. **Le sitemap partait non compressé.** nginx sert un `.xml` en `text/xml`, et ma liste ne nommait qu'`application/xml`. AD-13 le précise désormais.
4. **Le seuil de compression est de 20 octets.** Mon premier CSS d'essai en faisait six : l'absence de `Content-Encoding` ne prouvait rien du tout.

Et une vérification plutôt qu'une supposition : **`add_header_inherit merge` existe bien** dans l'image servie (`nginx -t`, 1.30.4). Sans elle, un `add_header` dans le `location /en/` effacerait tous les en-têtes du `server`.

### Essais contre le conteneur

| Vérification | Résultat |
| --- | --- |
| page HTML | CSP exacte, `nosniff`, `Referrer-Policy`, `no-cache`, aucun `Set-Cookie` |
| fichier empreinté | `public, max-age=31536000, immutable`, **aucune CSP** |
| `portrait.webp` non empreinté, PDF | `no-cache` |
| URL absente sous `/` et `/en/` | statut **404**, corps `lang=fr` puis `lang=en`, trois en-têtes présents |
| gzip | HTML, CSS, `sitemap.xml` et JSON : `Content-Encoding: gzip` **et** `Vary` |
| dossier sans barre finale | `Location: /dossier/`, relatif |
| journal | `[date] "GET /index.html" 200 679` — ni IP, ni `?secret=…`, ni user-agent, ni referer |

`scripts/tests/run.sh` : 344 cas réussis. `scripts/check.sh` : 5 contrôles passés.

## Revue du code

### 21/09/2026 — `ad014bd` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 61. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: da0de1cdb9b9660fae66fd1e

##### Rapport de revue BMAD

###### 🔍 Lentille : Edge-case-hunter
*Aucune faille trouvée.* Les règles de mise en cache, les déclarations de type MIME et la redirection (chemins implicites, gestion du HTML vs le reste) sont couvertes de manière explicite et robuste.

###### 🔍 Lentille : Verification-gap
**Test de configuration syntaxique Nginx (Broken-verification gap)**
- **Emplacement** : `deploy/nginx/site.conf:1`
- **Condition de déclenchement** : Les tests hors ligne valident le fichier via des recherches textuelles au lieu de tester le comportement ou la syntaxe réelle.
- **Garde-fou attendu** : Une validation d'exécution de type `nginx -t` ou un appel curl sur le conteneur en CI.
- **Conséquence potentielle** : Une erreur de syntaxe Nginx, une faute de frappe ou une directive accidentellement commentée passera les tests shell de type "grep", mais fera crasher le serveur en production.
- **Consommateur** : L'image Docker au démarrage (`deploy/nginx/site.conf`)
- **Preuve** : Le fichier `scripts/tests/test-nginx-conf.sh` n'utilise que `cat` et `shell_grep_into` pour valider la configuration (choix consciemment assumé par la spec de conserver la suite hors ligne sans démon, mais constituant tout de même une lacune de vérification automatisée stricte).

##### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (en-têtes, cache, statut 404 strict et journaux anonymisés présents).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut en afficher.
- NON BLOQUANT : Skill, procédure et script concordent (la procédure `build-image.md` décrit fidèlement les comportements vérifiés).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (les documentations `ARCHITECTURE-SPINE.md` et `epics.md` sont à jour).
- NON BLOQUANT : Dans les scripts shell de test (`test-nginx-conf.sh`), aucune erreur ne passe en silence sous `set -euo pipefail` (la lecture des lignes et les vérifications d'expressions rationnelles sont sécurisées).

VERDICT: NON BLOQUANT — lacune de test assumée et documentée par l'architecture pour le hors ligne, aucune autre réserve.

## Reporté
