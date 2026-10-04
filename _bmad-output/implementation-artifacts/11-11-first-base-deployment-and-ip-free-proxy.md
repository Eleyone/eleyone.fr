# Story 11.11 : First base deployment and IP-free proxy

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.11.

Deuxième story de la section « Mise en ligne du socle » de l'epic 11 (point 21 : le socle, jugé,
est mis en ligne par le flux linéaire, derrière un proxy sans journal d'IP). Dépendances closes :
11.7 (skill `release`), 11.10 (répétition sur l'arbre du socle, PR n° 135), socle complet (epic 10
clos, PR n° 132). Le test des trente secondes, déplacé ici le 04/10/2026, est une case de cette story.

Opération manuelle d'Arnaud de bout en bout : publication `dev` → `main` et tag `v1.0.0` par le skill
`release`, hôte proxy dans Nginx Proxy Manager, vérifications, DNS en dernier, mesures, test.

**Point relevé à l'ouverture** : le workflow `release` exige, pour `v1.0.0`, un tag `v1.0.0-rc.N` de
**même arbre** (`release-workflow.md`). `rc.1` à `rc.3` portent `8d8eb4f` ; `dev` a reçu depuis la PR
n° 133 (outillage en sous-module) et la PR n° 135 (11.10). Une répétition sur l'état de `dev` à
publier est donc nécessaire juste avant la publication.

## Revue de spec

### 04/10/2026 — `gemini-3.1-pro-high` (angles : adversarial, structure, prose), `dev` à `35a49dc`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f427325424b33db863310cfc

##### Rapport de revue de spec (Story 11.11)

Ce document existe pour vérifier que la spécification de la story 11.11 est prête, sans failles, testable et conforme aux règles et décisions d'architecture du projet, afin de pouvoir être implémentée en toute sécurité.

###### Lentille Adversarial (Adversarial)

- BLOQUANT : Contradiction sur le tag `rc.N`. Le critère exige "un tag `v1.0.0-rc.N` de même arbre", mais la note d'ouverture indique que le dépôt a évolué et que `dev` a reçu de nouveaux commits depuis la dernière répétition. La spec ne prévoit aucune action (ni pour l'agent, ni pour l'humain) ordonnant de relancer le skill `rehearse-release` avant la mise en ligne, ce qui fera échouer le skill `release` sur son propre invariant.
- BLOQUANT : Incohérence autour de C21. Les prérequis de contenu précisent "les CV PDF ne sont pas requis", mais les critères d'acceptation exigent que le workflow `release` passe, "C21 compris". Si C21 vérifie la présence ou le contenu des PDF, le workflow de publication échouera en leur absence.
- BLOQUANT : Mise à jour fantôme de `release-pages.txt`. Le critère indique que "le skill release a vérifié que ci/release-pages.txt contient toutes les pages du socle", mais aucune étape ni case à cocher ne demande à l'agent ou à l'humain de mettre à jour ce fichier pour y lister effectivement les pages du socle.
- BLOQUANT : Lieu de consigne inconnu pour AD-15. La spec demande : "chaque point « à tester » d'AD-15 est noté confirmé ou non". Elle ne précise pas où ces validations doivent être écrites (dans un fichier dédié, dans un commentaire de la PR, dans la description ?), rendant la vérification de ce critère impossible pour l'agent.
- BLOQUANT : Flou sur le workflow agent/humain. La story est qualifiée d'"Opération manuelle (Arnaud) : oui", mais il y a des fichiers à créer et à commiter (`deploy/proxy/npm-advanced.conf`, `docs/measures/v1.0.0.md`, `docs/measures/thirty-second-test.md`). La spec ne dit pas si Arnaud commite et pousse ces fichiers lui-même sur la branche de la PR, ou s'il donne les résultats à l'agent qui se charge de les écrire. L'agent ne saura pas quand et comment lire les résultats pour clôturer la story.
- BLOQUANT : Critère d'acceptation invérifiable. "La politique de confidentialité est vraie sur toute la chaîne." Il n'y a pas de moyen de test défini pour prouver que ce critère booléen abstrait est satisfait (hormis l'absence de logs et de cookies, qui est déjà testée par ailleurs).
- BLOQUANT : Boucle infinie potentielle sur le test des 30 secondes. Si le test a moins de quatre réussites, il faut retoucher le contenu, revérifier, et publier "par une mise en ligne ordinaire (`release`)". La story 11.11 resterait donc bloquée en attente d'une nouvelle publication, ce qui entrechoque le flux linéaire d'une seule `release` par story de mise en ligne.
- NON BLOQUANT : Ambiguïté sur "sans nom d'hôte ni adresse" pour NPM. La case demande de recopier la configuration de NPM "sans nom d'hôte ni adresse", mais l'hôte proxy doit pointer vers la destination `site:80`. L'auteur doit-il également expurger la chaîne "site:80" du fichier commité ?
- NON BLOQUANT : Vérification visuelle non précisée. "le critère 390 × 844 est vérifié sur le site en ligne". La méthode de validation n'est pas spécifiée (redimensionnement du navigateur, mode responsive des devtools, ou appareil physique ?).
- NON BLOQUANT : Fardeau manuel sur AD-13. "les en-têtes d'AD-13 sont conformes" par de simples `curl -I`. Valider manuellement l'intégralité d'une Content-Security-Policy (CSP) via `curl` est lourd et très propice à l'oubli.

###### Lentille Structure (Editorial Structure)

*Modèle retenu : Prompt/Task Definition (Functional)*

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| structure | Lignes `Dépendances` et `Bloquée par` (historique des arbitrages en italique) | CONDENSE : "11.7, 11.10 ; socle prêt." (Retirer les mentions des arbitrages) | Les justifications historiques encombrent la définition des prérequis de la tâche (sauve ~40 mots). |
| structure | Checkbox du test des trente secondes (explication complète de la méthode) | MOVE vers le document de référence `EXPERIENCE.md` (ou un `docs/procedures/thirty-second-test.md`), en ne gardant ici que l'action. | Le processus détaillé du test surcharge la liste de contrôle de la story (sauve ~60 mots). |
| structure | Checkbox des directives NPM recopiées | MERGE : à remonter dans les critères *Quand Arnaud lance nginx -t ...* | Regrouper la configuration de NPM et la sauvegarde de ses directives dans la même étape. |

###### Lentille Prose (Editorial Prose)

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| prose | *Depuis le 04/10/2026 (arbitrage d'Arnaud, story 11.10), la 11.10 livre la répétition...* | *La story 11.10 livre la répétition sur l'arbre du socle.* | Supprimé le commentaire méta-éditorial qui n'apporte rien à l'action. |
| prose | *Test des trente secondes, **seul passage** (arbitrage d'Arnaud du 04/10/2026, story 11.10) :* | *Test des trente secondes :* | Supprimé l'historique décisionnel au milieu d'une instruction à exécuter. |

---

##### À trancher avant d'implémenter

- **La répétition préalable :** Faut-il ajouter une étape/case explicite ordonnant à Arnaud (ou à l'agent) de lancer `rehearse-release` sur le commit de tête actuel pour satisfaire l'invariant du "même arbre" imposé par le skill `release` ?
- **L'incohérence de C21 :** Si les PDF du CV ne sont pas requis, C21 doit-il être désactivé pour cette exécution spécifique du workflow `release`, ou bien les PDF deviennent-ils obligatoires pour publier ?
- **La mise à jour de `release-pages.txt` :** Qui ajoute les pages du socle dans ce fichier, et à quelle étape exacte de la story ?
- **La consigne d'AD-15 :** Où Arnaud doit-il écrire la mention "confirmé ou non" pour chaque point d'AD-15 (dans un fichier du dépôt, dans un commentaire de PR, dans le corps de la PR) ?
- **La boucle du test des 30 secondes :** Si ce test manuel échoue, la story 11.11 doit-elle rester ouverte pendant les corrections et nécessiter une seconde exécution du skill `release` ?
- **Le flux de travail manuel/agent :** Qui commite concrètement les 3 fichiers de la PR (`npm-advanced.conf`, `v1.0.0.md`, `thirty-second-test.md`) : Arnaud qui pousse sur la branche, ou l'agent qui attend les données d'Arnaud pour les écrire ?
- **Le critère de politique de confidentialité :** Quelle action de test précise valide que la politique est "vraie sur toute la chaîne" ? (S'il n'y en a pas d'autre que l'absence de cookies/logs, le critère doit être reformulé ou supprimé).

### Tri des constats (04/10/2026, orchestrateur)

| # | Constat | Décision |
|---|---|---|
| A1 | Aucune étape ne relance la répétition sur l'arbre à publier (BLOQUANT) | **Retenu.** Première étape de la story : `scripts/rehearse-release.sh v1.0.0-rc.4 --run` sur la tête de `dev` (le numéro libre suivant), par Arnaud ; **aucune fusion dans `dev` entre cette répétition et la publication**, sinon l'arbre change et le verrou 4 de `release.sh` refuse. Les PR de cette story ne fusionnent qu'après le tag `v1.0.0`. |
| A2 | « CV PDF non requis » contre « C21 compris » (BLOQUANT) | **Réfuté, preuve à l'appui.** `assets/cv/cv-fr.pdf` et `cv-en.pdf` existent (story 7.4) ; C21 les confronte aux motifs et a passé dans les workflows `release` des six tags de répétition (`v0.1.0-rc.2`, `rc.3`, `v1.0.0-rc.1` à `rc.3`). « Non requis » veut dire que la mise en ligne n'attend pas une nouvelle version des CV, pas que C21 est désactivé. |
| A3 | Personne ne met à jour `ci/release-pages.txt` (BLOQUANT) | **Réfuté.** Le fichier porte déjà les neuf clés du socle — chaque story qui publie une page y ajoute la sienne —, et C15 l'a vérifié contre le site au niveau `release` le 02/10/2026 (story 11.9, A3). `release.sh` vérifie à son tour, à la tête de `dev`, que chaque clé de `ci/base-pages.txt` y figure. |
| A4 | Où consigner les points « à tester » d'AD-15 ? (BLOQUANT) | **Retenu, tranché ici** : dans la section « Exécution » de ce fichier de story, point par point (« confirmé » / « non confirmé », avec la sortie qui le prouve, sans nom d'hôte ni adresse) ; les directives elles-mêmes dans `deploy/proxy/npm-advanced.conf`. |
| A5 | Qui commite les fichiers ? (BLOQUANT) | **Retenu, tranché ici** : Arnaud fait les opérations (NPM, DNS, tags, PageSpeed, test) et donne les sorties ; l'orchestrateur les consigne et commite sur la branche de la story — `deploy/proxy/npm-advanced.conf`, `docs/measures/v1.0.0.md`, `docs/measures/thirty-second-test.md`, ce fichier —, puis mène la PR. |
| A6 | « La politique de confidentialité est vraie sur toute la chaîne » est invérifiable (BLOQUANT) | **Retenu, rendu vérifiable** : la page de politique de confidentialité affirme l'absence de cookies, de mesure d'audience et de journal d'adresses IP ; la case est cochée quand chacune de ces affirmations est prouvée sur la chaîne de production — aucun `Set-Cookie` (critère 3), le journal d'accès de l'hôte NPM qui ne grossit pas (critère 2), le journal du conteneur de production sans adresse IP (`docker logs`, comme la répétition le vérifie), aucun script tiers dans les pages servies (zéro JavaScript, C13). |
| A7 | Le test des trente secondes peut boucler et retenir la story (BLOQUANT) | **Retenu : question posée à Arnaud.** |
| N1 | « Sans nom d'hôte ni adresse » : faut-il retirer `site:80` ? | **Réfuté.** `site:80` est le nom du service Compose sur le réseau du proxy, pas un nom d'hôte ni une adresse ; il est déjà écrit dans `deploy/compose.yaml`. Sont retirés : le domaine, l'adresse du serveur, toute valeur de certificat. |
| N2 | Méthode du critère 390 × 844 non précisée | **Retenu** : la méthode de la story 10.9 (Chromium sans tête, 390 × 844, densité 3), lancée par l'orchestrateur sur le site en ligne, et un coup d'œil d'Arnaud sur son téléphone. |
| N3 | Vérifier la CSP à la main par `curl -I` est fragile | **Retenu** : l'orchestrateur lance les vérifications d'en-têtes d'AD-13 en les comparant à `deploy/nginx/site.conf`, d'abord par le proxy avant le DNS (`curl --resolve`, l'adresse lue sans être écrite), puis sur le domaine. |
| S1–S3, P1–P2 | Réécritures de structure et de prose de la spec | **Écartées** : `epics.md` est validé et garde la trace datée de ses révisions, comme le reste du backlog. |

**Arbitrage d'Arnaud sur A7 (04/10/2026) : option 1.** « Sinon ça va prendre trop longtemps. » La
11.11 se termine à la mise en ligne vérifiée ; le test des trente secondes devient la story **11.11b**
(`epics.md`, juste avant la 11.12 ; `sprint-status.yaml`, en `backlog`), avec la méthode entière et le
circuit d'une retouche par mise en ligne ordinaire. La case de la 11.11 est barrée avec un renvoi.
Option écartée : garder la 11.11 ouverte jusqu'au test réussi.

## Exécution

### Étape 1 — répétition sur l'arbre à publier (04/10/2026, par Arnaud)

`scripts/rehearse-release.sh v1.0.0-rc.4 --run`, sur `origin/dev` (`35a49dc`). Workflows `release`
2532 (`rc.4`) et 2534 (`rc.5`) : succès. Les trois passages (`rc.4` ; `rc.5` ; retour arrière vers
`rc.4`) rendent chacun les onze lignes, toutes ok : accueil FR et EN 200, 404 FR et EN, mentions
légales FR et EN avec les 8 valeurs de mise en ligne, fichier empreinté, SVG sans objet, journaux
sans adresse IP. `rehearse stop` : projet arrêté, images `rc.5`, `rc.4` et `rc.3` (restée en service
depuis la 11.10) supprimées. `v1.0.0-rc.4` porte l'arbre de `dev` à publier.

### Étape 2 — publication et tag `v1.0.0` (04/10/2026, par Arnaud) — critère 1

`scripts/release.sh v1.0.0` (audit par l'orchestrateur) a ouvert la PR n° 136 `dev` → `main` ; les
cinq verrous passent : PR publiable, revue (127 commits de `main..dev`, tous squashs de PR hors
amorçage listé), garde-fou, CI verte, suivi de sprint ; répétition sur le même arbre
(`v1.0.0-rc.4`) ; socle complet (9 clés de `ci/base-pages.txt` dans `ci/release-pages.txt`).
`scripts/release.sh v1.0.0 --merge`, **lancé par Arnaud** : fusion fast-forward, `v1.0.0` posé sur
`main` (`35a49dc`) et poussé. Workflow `release` 2541 : succès — image `eleyone-site:v1.0.0`
construite au niveau `release` (C15, C21, C22 compris), livrée par « deploy v1.0.0 », puis
`deploy-site: production : eleyone-site:v1.0.0`.

### Étape 3 — hôte proxy sans journal d'IP, avant le DNS (04/10/2026) — critères 2 et 3

Hôte créé par Arnaud dans NPM selon AD-15 (destination `site:80`, *Cache Assets* désactivé,
`access_log off;` dans *Advanced*, *Custom Location* `/` avec `access_log off; error_log /dev/null
crit;`, sans SSL avant le DNS) ; directives recopiées dans `deploy/proxy/npm-advanced.conf`.
Vérifications de l'orchestrateur par le compte d'administration et par requêtes directes au serveur
(`curl --resolve`, adresse lue sans être écrite) :

- `nginx -t` dans le conteneur de NPM : « syntax is ok », « test is successful ».
- Configuration générée de l'hôte (`proxy_host/<id>.conf`) : `access_log off;` au niveau `server`,
  après l'`access_log … proxy` de NPM ; `access_log off;` et `error_log /dev/null crit;` dans
  `location /` ; `proxy_pass http://site:80` ; **aucune** `location ~` (Cache Assets bien désactivé).
- Sept requêtes (accueil FR et EN, mentions légales, 404 FR et EN, accueil, fichier empreinté) :
  `proxy-host-<id>_access.log` et `_error.log` restent à **0 octet**.
- En-têtes, comparés à `deploy/nginx/site.conf` : sur chaque page HTML et chaque 404,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, la CSP
  d'AD-13, `Cache-Control: no-cache` ; sur le fichier empreinté, `Cache-Control: public,
  max-age=31536000, immutable` et pas de CSP. **Aucun `Set-Cookie`.** Pas de SVG servi (sans objet).
- Journal du conteneur de production : les requêtes y figurent au format d'AD-15 (date, méthode,
  URI, statut, octets), **sans adresse IP**.

Points « à tester » d'AD-15 :

| Point | Résultat |
|---|---|
| *Custom Location* `/` avec `access_log off; error_log /dev/null crit;` | **Confirmé** pour le journal d'accès (0 octet après sept requêtes) et pour la présence de la directive d'erreur dans la location ; le journal d'erreurs reste à 0 octet, mais aucune requête n'a provoqué d'erreur du proxy lui-même : ce cas n'est pas éprouvé, et l'`error_log … warn` que NPM déclare au niveau `server` demeure pour les erreurs survenues hors de la location. |
| *Cache Assets* désactivé | **Confirmé** : aucune `location ~` dans la configuration générée ; le fichier empreinté n'a rien écrit. |
| Alternative par `map` dans `http_top.conf` | **Sans objet** : non nécessaire, les deux points ci-dessus suffisent. |

### Étape 4 — DNS, certificat, site en ligne (04/10/2026) — critère 4

DNS posé par Arnaud ; le domaine résout vers le serveur de production (comparé à l'adresse du
compte d'administration, sans l'écrire). Certificat Let's Encrypt (émetteur `YE2`, échéance
02/01/2027), *Force SSL*, HTTP/2 et HSTS posés dans NPM.

- `http://` → `301` vers `https://`.
- Les **16 URL des deux sitemaps** répondent `200` en HTTPS : accueil, « À propos », contact,
  mentions légales, confidentialité, page Chiliz, cas 01 et cas 05, en FR et en EN — toutes les
  pages de FR-32 ; une URL absente rend `404` dans chaque langue ; le CV PDF répond `200`.
- En-têtes en HTTPS : ceux d'AD-13, identiques à l'étape 3, plus
  `strict-transport-security: max-age=63072000; preload` ; aucun `Set-Cookie`.
- Journaux de l'hôte NPM : toujours **0 octet** après ces requêtes ; la configuration régénérée par
  la pose du certificat garde ses deux `access_log off`.
- **FR-37 sur le site en ligne** (méthode de la story 10.9, Chromium sans tête, 390 × 844,
  densité 3 ; la CSP du site, active, a refusé l'injection de police : contournée dans le navigateur
  de mesure seulement) — haut → bas du lien du premier cas, en px :

  | Police | FR | EN |
  |---|---|---|
  | pile du site (Charter absente du conteneur : repli) | 791 → 844 | 791 → 844 |
  | Noto Serif | 791 → 844 | 791 → 844 |
  | DejaVu Serif | 867 → 920 | 818 → 870 |

  Le critère tient avec la pile du site et Noto Serif ; le dépassement avec une serif de repli large
  est celui qu'Arnaud a accepté le 03/10/2026 (story 10.9).

**Remarque sur HSTS** : NPM envoie `preload` sans `includeSubDomains`. La directive est sans effet
(la liste de préchargement des navigateurs exige `includeSubDomains`, qu'il ne faut pas poser ici,
d'autres sous-domaines du serveur n'étant pas concernés) ; elle ne demande rien, et le domaine n'est
pas soumis à cette liste.

### Politique de confidentialité, sur toute la chaîne (case de la check-list)

Chaque affirmation de la page est prouvée sur la chaîne de production (triage A6) : aucun cookie
(aucun `Set-Cookie`, étapes 3 et 4) ; aucune mesure d'audience ni script tiers (aucun JavaScript,
C13 ; CSP `default-src 'none'`) ; aucun journal d'adresses IP — journal d'accès de l'hôte NPM coupé
et resté à 0 octet, journal du conteneur de production sans adresse IP (étape 3). **Case cochée.**

### Mesures PageSpeed Insights (case de la check-list)

Analyses lancées par Arnaud, lues par l'orchestrateur sur les pages de résultat et consignées dans
`docs/measures/v1.0.0.md` (dans cette PR, plutôt que dans une PR à part : la mesure appartient à la
mise en ligne qu'elle décrit). Les cinq gabarits : Performance et Accessibilité à 100 ; Bonnes
pratiques à 100, sauf la 404 (96, statut 404 en console) ; SEO de 91 à 92 (82 pour la 404) ; LCP de
0,8 à 1,1 s, TBT nul, CLS nul.

**Écart : aucune page ne porte de `<meta name="description">`**, seul audit SEO en échec. Ni le PRD,
ni l'architecture, ni les gabarits ne la prévoyaient — trou de planification, pas régression ; aucun
critère de cette story ne l'exige. **Arbitrage d'Arnaud (04/10/2026) : option 1** — la 11.11 se clôt
sans elle ; une proposition de changement ajoute l'exigence (PRD, architecture, contrôle) et une story
au backlog, publiée ensuite par une mise en ligne ordinaire (`v1.0.1`). Options écartées : l'ajouter
dans cette story avant sa clôture ; ne rien faire.

### Bilan des critères

| Critère | État |
|---|---|
| 1. `release` vérifie le socle, le workflow passe, `status` montre `v1.0.0` en production | ✅ étape 2 |
| 2. Hôte proxy : configuration valide, journal d'accès qui ne grossit pas, points « à tester » notés | ✅ étape 3 (un cas du journal d'erreurs non éprouvé, noté) |
| 3. En-têtes d'AD-13 conformes, aucun `Set-Cookie`, avant le DNS | ✅ étape 3 |
| 4. HTTPS, toutes les pages de FR-32, 390 × 844 sur le site en ligne | ✅ étape 4 |
| Directives NPM dans `deploy/proxy/npm-advanced.conf` | ✅ |
| Mesures PageSpeed dans `docs/measures/v1.0.0.md` | ✅ |
| Politique de confidentialité vraie sur toute la chaîne | ✅ |
| Test des trente secondes | ➡️ story 11.11b |

## Revue du code

### 04/10/2026 — `da414de` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 137. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 6a9c662db19660f9dd8b7e31

##### Revue `bmad-review`

**Lentilles exécutées :** `edge-case-hunter`, `verification-gap`.

###### Lentille `edge-case-hunter`

- NON BLOQUANT : Directives de la Custom Location commentées. 
  - **Emplacement :** `deploy/proxy/npm-advanced.conf:14-15`
  - **Condition :** Les directives `access_log off;` et `error_log /dev/null crit;` sont précédées d'un `#`. 
  - **Correction suggérée :** Retirer les `#` pour éviter de les copier comme commentaires lors d'une restauration. (`access_log off;\nerror_log /dev/null crit;`)
  - **Conséquence potentielle :** Lors d'une recréation de l'hôte proxy par copier-coller de ce fichier, la journalisation restera active pour la location `/`, ce qui fera fuiter les adresses IP.

- NON BLOQUANT : Comportement du journal d'erreurs non testé.
  - **Emplacement :** `_bmad-output/implementation-artifacts/11-11-first-base-deployment-and-ip-free-proxy.md:150`
  - **Condition :** Aucune erreur n'ayant été provoquée par le proxy lui-même, l'absence de fuite d'IP via le `error_log ... warn` du niveau server reste théorique.
  - **Correction suggérée :** Déclencher une erreur du proxy (ex. arrêter le conteneur `site`) pour observer ce que le proxy journalise.
  - **Conséquence potentielle :** Une erreur imprévue (502, 504) pourrait être journalisée avec l'adresse IP client si NPM la consigne.

###### Lentille `verification-gap`

- NON BLOQUANT : Aucune lacune de vérification trouvée. Les changements sont non comportementaux (documentation, suivi de sprint et fichier de configuration de sauvegarde manuel).

##### Contrôles du projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits. Le test des trente secondes a été séparé de la story avec un arbitrage formel. L'intention des critères est préservée.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte privé (seulement `pagespeed.web.dev` et `site:80`), aucune adresse IP et aucun secret n'est commité.
- NON BLOQUANT : Concordance skill, procédure et script respectée (non applicable ici).
- NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (le retrait de la balise meta description manquant est correctement documenté pour une action future ; NFR-9 est respecté).
- NON BLOQUANT : Pas d'erreur sous `set -euo pipefail` (aucun script shell modifié, non applicable).

VERDICT: NON BLOQUANT — Les directives NPM de la location sont commentées dans le fichier de sauvegarde (ce qui pourrait causer une fuite d'IP lors d'une restauration future), mais la configuration en production actuelle a été prouvée sans fuite d'IP.


#### Décisions sur la revue de `da414de` (orchestrateur)

| # | Constat | Décision |
|---|---|---|
| E1 | Dans `deploy/proxy/npm-advanced.conf`, les directives de la *Custom Location* sont commentées : recopiées telles quelles lors d'une restauration, elles laisseraient le journal de la location actif, IP comprises | **Retenu, corrigé.** Le fichier est réorganisé en deux blocs **non commentés**, chacun sous un titre qui nomme le champ de NPM où il se colle, avec la consigne de les copier tels quels. Changement après la revue : une nouvelle revue suit. |
| E2 | Le journal d'erreurs n'a été éprouvé sur aucune erreur du proxy | **Retenu, éprouvé en partie sans couper le site** : quatre requêtes que le proxy refuse lui-même — chemin avec octet nul (`400`), en-tête `Host` vide (`400`), en-tête de 20 000 octets (rejet), méthode inconnue (`405`) — laissent `proxy-host-<id>_error.log` à **0 octet**. Une erreur d'amont (`502`, `504`) n'est pas éprouvée : il faudrait arrêter le site en production ; la directive `error_log /dev/null crit;` de la location `/`, présente dans la configuration générée, la couvre en principe, et le point reste noté. |
| V1 | Aucune lacune de vérification | Pris acte. |
| P1–P5 | Critères satisfaits ; aucune donnée privée ; concordance sans objet ; cohérence ; aucun script modifié | Pris acte. |

### 04/10/2026 — `cd6d187` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 137. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a3ca51eea1a59a5fa3e8fecd

##### Revue de la PR n° 137

###### Lentille `edge-case-hunter`
- NON BLOQUANT : La redirection HTTP vers HTTPS (qui aurait pu générer ses propres logs via un bloc server distinct dans NPM) a été explicitement éprouvée et ne génère aucun journal, écartant un cas limite classique de fuite d'adresses IP.
- NON BLOQUANT : Le traitement des requêtes rejetées directement par le proxy (requêtes malformées, sans hôte) a été testé empiriquement, garantissant que le journal d'erreurs reste vide et couvrant ainsi ce cas limite de configuration.

###### Lentille `verification-gap`
- NON BLOQUANT : Le respect du budget de poids (AD-8) mentionné dans `v1.0.0.md` repose sur la mesure effectuée lors de la story 10.9 ; bien que cela représente une légère lacune de revérification formelle à l'instant T, l'absence de modifications de contenu valide cette approche.
- NON BLOQUANT : L'affirmation selon laquelle aucune adresse IP ne fuite est corroborée par une observation directe de la taille (0 octet) des journaux d'accès après sollicitation, comblant toute lacune de vérification sur ce critère de confidentialité.

###### Contrôles du projet
- NON BLOQUANT : Les critères d'acceptation de la story sont intégralement satisfaits sans être vidés de leur intention, la sortie du test des trente secondes vers la story 11.11b ayant été formellement validée par un arbitrage d'Arnaud.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte de production (hormis les références internes comme `site:80` et publiques comme `pagespeed.web.dev`), aucune adresse de serveur ni secret n'est commité.
- NON BLOQUANT : La concordance entre les skills, procédures et scripts est préservée, aucun d'eux n'ayant été modifié ou désynchronisé.
- NON BLOQUANT : Les modifications sont cohérentes avec `AGENTS.md` et les décisions d'architecture (AD-15 pour le proxy IP-free, AD-13 pour les en-têtes de sécurité, AD-8 pour le poids et NFR-9 pour la configuration aveugle).
- NON BLOQUANT : Aucun script shell n'a été modifié, empêchant toute régression ou silence sous `set -euo pipefail`.

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue de `cd6d187` (orchestrateur)

Neuf constats de conformité, sans demande de changement : **pris acte**, un par un — redirection
HTTP→HTTPS sans journal ; requêtes rejetées par le proxy sans journal ; budget d'AD-8 repris de la
mesure de la story 10.9 (aucun contenu ni gabarit modifié depuis la 10.10 qui l'aurait changé, et C13
a passé dans le workflow `release` de `v1.0.0`) ; journaux à 0 octet comme preuve ; critères
satisfaits avec l'arbitrage de la 11.11b ; aucune donnée privée ; concordance préservée ; cohérence
avec AD-8, AD-13, AD-15 et NFR-9 ; aucun script modifié.
