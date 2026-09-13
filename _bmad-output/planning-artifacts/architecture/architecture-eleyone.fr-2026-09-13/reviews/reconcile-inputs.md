---
title: "Réconciliation des entrées avec ARCHITECTURE-SPINE.md"
target: ARCHITECTURE-SPINE.md
created: 2026-09-13
status: review
---

# Réconciliation des entrées avec la spine d'architecture

## Verdict

**Presque tout est couvert, mais pas sans réserve.** Toutes les puces « À décider par l'architecture » du PRD (§7) sont tranchées, reportées ou marquées à valider. Les trois décisions d'Arnaud du 13/09/2026 (mentions légales, journaux nginx, Nginx Proxy Manager) sont reprises presque mot pour mot. La checklist de la tâche est couverte en totalité.

Quelques exigences discrètes se sont pourtant perdues, et plusieurs règles se contredisent entre elles :

- le **séquencement du squelette** contredit le garde-fou : le miroir GitHub est actif avant le hook serveur ;
- le **`Dockerfile`** lance toujours les contrôles de mise en ligne, et le workflow `release` charge le fichier factice ;
- le point de vigilance D2 **« pas de retour à la ligne automatique »** a disparu ;
- deux cas sur la même page Chiliz produisent des **identifiants de titre en double** ;
- les journaux d'erreurs nginx gardent le **referer** ;
- des réglages Hugo par défaut (taxonomies, RSS) feront échouer `--panicOnWarning`.

Légende : **Manquant** (l'entrée exige quelque chose que la spine ne dit pas), **Contredit** (la spine dit l'inverse ou deux règles s'opposent), **Partiel** (la règle est là mais incomplète).

---

## 1. PRD (`prd.md`)

### 1.1 §7, « À décider par l'architecture » : état de chaque puce

| Puce du §7 | État | Où dans la spine |
| --- | --- | --- |
| Structure du dépôt, emplacement et nommage | Décidé | AD-4, AD-7, « Structure initiale » |
| Assemblage de la page Chiliz, adressage des sections | Décidé, **partiel** (voir 1.2-a) | AD-4 |
| Rendu du matériel vivant par type, « prévu » invisible | Décidé, **partiel** (voir 1.2-b) | AD-6 |
| Production du rendu de travail | Décidé | AD-5 ; hébergement reporté |
| Outil de l'agent de parité | Décidé | AD-16, ADR-8 |
| Garde-fou côté serveur et en local | Décidé, **séquencement contredit** (voir 4-a) | AD-12, procédure pre-receive |
| Outillage NFR-4 et NFR-5 sans Chrome ni Node | Décidé | AD-17, ADR-9 |
| Budget de poids | Proposé, à valider | AD-8, recommandation 1 |
| Justification des exceptions à NFR-12 | Procédure décidée | AD-8 |
| Moteur, thème et épinglage de D2 | ELK et épinglage décidés ; **thème partiel** (voir 3-c) | AD-1, AD-7 |
| Vigilance D2 : pas de retour à la ligne automatique | **Manquant** (voir 3-a) | — |
| Vigilance D2 : fichiers en 0600 | Décidé | AD-7 (`chmod 0644`), AD-13 (`chmod -R a+rX`) |

### 1.2 Écarts

**a. FR-9 : identifiants et hiérarchie des titres sur la page Chiliz** — *Contredit (en pratique)*

- **Constat.** Chaque cas rend ses rubriques en `##` avec les identifiants automatiques de Hugo (`id="contexte"`, …).
  - Dès que le cas 03 est publié dans la même page, les identifiants sont en double, et C11 (« identifiants uniques ») échoue.
  - Il faut alors modifier le gabarit, ce que FR-9 interdit (« sans modification de la page elle-même »).
  - Sur la page de groupe, le titre du cas est en H2 et ses rubriques aussi en H2 : la hiérarchie est aplatie (WCAG 1.3.1).
  - AD-3 dit que le partial « reçoit le niveau de titre », mais rien ne décale les titres du Markdown.
- **Où corriger.** AD-4, nouvelle puce, et « Conventions de cohérence », ligne « Gabarits Hugo ».
- **Formulation proposée.**
  > Un gabarit `layouts/_markup/render-heading.html` préfixe l'`id` de chaque titre du contenu par le `translationKey` de la page (`case-02-contexte`). Pour un cas groupé (`.Page.Params.group` non vide), il ajoute un niveau au titre (rubriques en `<h3>`, titres de niveau 3 en `<h4>`). C4 continue de lire le Markdown brut.

**b. FR-12 et FR-26 : aspect d'un élément « prévu » dans le rendu de travail** — *Partiel*

- **Constat.** AD-6 dit qu'un élément `planned` est rendu hors production, mais sa source n'existe pas encore. Rien ne dit ce qui s'affiche. La démonstration WS-2 (« montre ses trois éléments prévus ») repose pourtant là-dessus.
- **Où corriger.** AD-6, après la puce « Rendu si `status: ready` ».
- **Formulation proposée.**
  > Hors production, un élément `planned` est rendu par `<aside class="live-material live-material--planned">` avec son type, son `id` et sa `description`, sans chercher de source. `snippet` est rendu dans `<figure>`, `callout` dans `<aside>`.

**c. FR-27 : le schéma « de démonstration » est interdit par AD-7** — *Contredit*

- **Constat.** FR-27 se vérifie « sur le premier schéma, réel ou de démonstration », et le squelette prévoit « le pipeline D2 avec un schéma de démonstration ». Or AD-7 fait échouer tout dossier `diagrams/<id>/` qui ne correspond à aucun élément `diagram` déclaré dans un cas. Déclarer un schéma fictif dans un cas irait contre NFR-10.
- **Où corriger.** AD-7, puce « Un dossier de schéma sans élément `diagram` déclaré… », et le paragraphe qui suit le « Walking skeleton ».
- **Formulation proposée.**
  > Le premier schéma est un schéma réel déclaré dans le cas pilote (`diagram-ncs-cs-flow`), rendu et vérifié même tant qu'il reste `planned`. Sinon, un schéma de test vit dans `scripts/diagrams/fixtures/`, hors de `diagrams/`, et n'est rendu que par `scripts/diagrams/check.sh`, dans un dossier temporaire.

**d. FR-25 et SM-7 : les fichiers `assets/live-material/`** — *Contredit*

- **Constat.** Selon FR-25, une PR de contenu ne touche que « les fichiers Markdown du cas », la source D2 et les SVG. SM-7 mesure la même chose. AD-6 place pourtant extraits et encarts dans `assets/live-material/<id>.<lang>.md`, en dehors du cas.
- **Où corriger.** « Écarts et tensions avec les entrées », nouvelle puce ; ou bien la ligne FR-25 de « Capacités → architecture ».
- **Formulation proposée.**
  > FR-25 et SM-7 sont à étendre à `assets/live-material/<id>.{fr,en}.md`, qui fait partie du contenu au sens du glossaire. L'agent de parité et le filtre `paths` le traitent déjà comme tel.

**e. Questions ouvertes du §11.2 sans trace dans la spine** — *Manquant*

- **Constat.**
  - Q7 (informations d'un cas mis en avant) touche le gabarit `home.html` et le partial de carte.
  - Q8 (où mentionner l'activité parallèle) touche `home.html` ou `about`.
  - Aucune des deux n'est citée.
  - Q17 est hors architecture : on peut le dire explicitement.
- **Où corriger.** « Reporté ».
- **Formulation proposée.**
  > **Carte d'un cas mis en avant** (question 7) et **emplacement de la mention de l'activité parallèle** (question 8) : attendent la décision ; `home.html` n'affiche que le titre du cas et son lien tant qu'elle n'est pas prise. Question 17 : hors architecture.

**f. FR-17 et FR-29 : où vivent les URL externes et l'adresse de contact** — *Manquant*

- **Constat.** Le lien vers le dépôt (pied de page, donc gabarit), l'URL LinkedIn et celle de Ton Pote le Geek n'ont pas d'emplacement décidé. Or AD-3 interdit le texte de contenu dans un gabarit.
  - **Tension :** AD-9 garde le contact de l'éditeur hors du dépôt, alors que la page Contact (FR-17) commiterait une adresse mail. Si les deux adresses sont identiques, la précaution ne sert à rien.
- **Où corriger.** AD-3, nouvelle puce ; « Recommandations à valider », nouvel item.
- **Formulation proposée.**
  > Les URL externes (dépôt public, LinkedIn, Ton Pote le Geek) sont des `params` en `snake_case` de `config/_default/hugo.yaml`. L'adresse mail de la page Contact est dans `content/contact.{fr,en}.md`. Si elle est identique à `HUGO_LEGAL_PUBLISHER_CONTACT`, Arnaud décide si elle passe aussi par l'environnement **[à valider par Arnaud]**.

**g. FR-18 et FR-19 : pages légales liées depuis chaque page** — *Partiel*

- **Constat.** L'hypothèse du PRD (lien en pied de page) n'est vérifiée par aucun contrôle.
- **Où corriger.** Liste des contrôles, C12.
- **Formulation proposée.**
  > C12 : … ; chaque page HTML contient un lien vers les mentions légales et vers la politique de confidentialité de sa langue.

**h. FR-24 : les lignes de contexte ne sont pas des écarts** — *Manquant*

- **Constat.** La version anglaise ajoute des lignes de contexte (FR-22) et « n'est pas une traduction littérale ». Sans consigne, l'agent les signalera comme des écarts, et ses commentaires deviendront du bruit. Il ne reçoit pas non plus les paires `fr.d2`/`en.d2`, `assets/live-material/` et `i18n/`, qui déclenchent pourtant son exécution.
- **Où corriger.** AD-16, étapes 1 et 2.
- **Formulation proposée.**
  > 1. … envoie aussi les paires `diagrams/<id>/{fr,en}.d2`, `assets/live-material/<id>.{fr,en}.md` et `i18n/{fr,en}.yaml` modifiées ;
  > 2. … sans réécriture. Une ligne de contexte propre à l'anglais (FR-22), qui explique un repère sans ajouter de fait, n'est pas un écart.

**i. Config Hugo : types de pages par défaut, `baseURL`, sitemap** — *Manquant*

- **Constat.** Par défaut, Hugo génère les pages `taxonomy` et `term` (`/tags/`, `/categories/`) et le RSS `index.xml`.
  - Sans gabarit, il émet un avertissement « found no layout file », ce qui fait échouer `--panicOnWarning` (AD-5).
  - Avec un gabarit, ces pages sont orphelines (C12).
  - `hreflang` doit contenir des URL absolues, donc un `baseURL`. Rien n'est dit non plus de `sitemap.xml` ni de `robots.txt`.
- **Où corriger.** AD-2, première puce.
- **Formulation proposée.**
  > `baseURL: https://eleyone.fr/` ; `disableKinds: [taxonomy, term, rss]` ; `enableRobotsTXT` et sitemap par langue **[à valider par Arnaud]** ; les liens `hreflang` utilisent `.Permalink` (absolu).

**j. Doubles exécutions sur Gitea** — *Contredit (avec le « Prevents » d'AD-11)*

- **Constat.** `checks.yaml` écoute `push` et `pull_request`. Une PR ouverte depuis une branche du même dépôt lance donc deux exécutions par push, ce qu'AD-11 prétend éviter.
- **Où corriger.** AD-11, puce `.gitea/workflows/`.
- **Formulation proposée.**
  > `checks.yaml` (sur `push` vers `main` et les tags, et sur `pull_request`).

---

## 2. Décisions d'Arnaud du 13/09/2026

### (a) Mentions légales par l'environnement — reprise fidèle, trois trous

**a1. Le fichier factice est chargé dans le workflow `release`** — *Contredit*

- **Constat.** AD-9 dit : « le fichier factice n'y est jamais chargé ». Mais AD-14 fait enchaîner `scripts/ci/checks-job.sh` au workflow `release`, et AD-11 définit ce script comme celui qui charge `ci/legal-placeholder.env`.
- **Où corriger.** AD-14, première puce, et AD-11, puce « Un workflow ne contient que… ».
- **Formulation proposée.**
  > `checks-job.sh` charge `ci/legal-placeholder.env` dans un sous-shell, sans jamais l'exporter dans l'environnement du job. `scripts/release/build-image.sh` écrit le secret `legal_env` à partir des seules variables et secrets Gitea, et échoue si l'une d'elles est vide avant même `docker build`.

**a2. Cache BuildKit et secrets** — *Manquant*

- **Constat.** Un montage `--secret` ne fait pas partie de la clé de cache de BuildKit. Si seule une valeur légale change, l'étape `build` peut être reprise du cache et livrer l'ancienne page.
- **Où corriger.** AD-13, puce « Étapes ».
- **Formulation proposée.**
  > L'étape `build` est toujours reconstruite (`docker build --no-cache-filter build`) : un secret BuildKit n'invalide pas le cache.

**a3. Distinguer le build Hugo de contrôle du build d'image** — *Contredit par WS-5*

- **Constat.** Le `Dockerfile` lance `scripts/check.sh --release` dans l'étape `build`. Ce contrôle échoue tant que le socle n'existe pas (C15 : pages du socle, cas mis en avant publiés) et avec les valeurs factices (`VALEUR-FACTICE`). La démonstration WS-5 (« lancement local ») est donc impossible, et une image de travail ne peut pas se construire.
- **Où corriger.** AD-13, puce « Étapes », et WS-5.
- **Formulation proposée.**
  > L'étape `build` lance `scripts/check.sh` ; `--release` n'est ajouté que par `ARG CHECK_LEVEL=release`, que seul `scripts/release/build-image.sh` passe. WS-5 construit l'image avec `CHECK_LEVEL=control` et les valeurs factices ; cette image est marquée non livrable (tag `local-*`) et `ship.sh` la refuse.

### (b) Journaux nginx

**b1. Referer et chaîne de requête dans le journal d'erreurs** — *Contredit (règle « pas de referer »)*

- **Constat.** Les lignes du journal d'erreurs nginx ajoutent `request: "GET /…?query"` et `referrer: "…"` quand ils sont présents. La décision d'Arnaud impose `error_log warn` ; le conteneur ne voit pas l'IP du visiteur (pas de `realip`), mais il peut encore journaliser le referer. `log_not_found off` limite le volume sans supprimer ce risque.
- **Où corriger.** AD-15, sous-puce `error_log`, et « Conventions de cohérence », ligne « Données personnelles ».
- **Formulation proposée.**
  > **Résiduel assumé :** une ligne d'erreur de niveau `warn` ou plus peut contenir la requête complète et le referer (jamais l'IP du visiteur, puisque le conteneur ne voit que le proxy). Ces lignes sont rares pour un site statique, et Docker les fait tourner avec les autres. **[à valider par Arnaud : accepter ce résiduel, ou passer `error_log` à `crit`]**.

**b2. La limitation de débit, optionnelle, est mal placée** — *Partiel / Contredit*

- **Constat.** « Reporté » propose de la mettre « dans le proxy ou dans nginx ». Or le conteneur du site, sans `realip`, voit tous les visiteurs sous l'adresse du proxy : une limite par client y bloquerait tout le monde en même temps. De plus, `limit_req` journalise ses rejets au niveau `error`, avec `client: <IP>`.
- **Où corriger.** « Reporté », puce « Limitation de débit ».
- **Formulation proposée.**
  > Si elle devient nécessaire : dans Nginx Proxy Manager uniquement (`limit_req_zone $binary_remote_addr` en mémoire), avec `limit_req_log_level info` pour que les rejets passent sous le seuil du journal d'erreurs. Jamais dans le conteneur du site, qui ne voit que l'adresse du proxy.

### (c) Nginx Proxy Manager

**c1. Configuration de l'hôte non versionnée** — *Manquant*

- **Constat.** La configuration avancée à coller dans NPM n'a pas de fichier dans « Structure initiale ». Elle ne serait ni reproductible ni relisible par le lecteur du dépôt.
- **Où corriger.** « Structure initiale », sous `deploy/`, et AD-15.
- **Formulation proposée.**
  > `deploy/proxy/npm-advanced.conf` : bloc à coller dans l'onglet de configuration avancée de l'hôte (`access_log off;`, `location /` avec `error_log /dev/null crit;`), commenté avec les points incertains.

**c2. Anciens journaux et locations en expression régulière** — *Manquant*

- **Constat.**
  - Les journaux d'accès écrits avant la modification (et leurs rotations) contiennent déjà des IP.
  - Si l'option « Cache Assets » est active, NPM ajoute une `location` en expression régulière pour CSS, SVG, etc., qui l'emporte sur `location /`. Ces requêtes échappent alors au `error_log /dev/null`.
- **Où corriger.** AD-15, puces « Incertain » et « À vérifier ».
- **Formulation proposée.**
  > Après activation : supprimer les fichiers `proxy-host-<id>_access.log*` et `_error.log*` existants. Laisser « Cache Assets » et « Block Common Exploits » désactivés pour cet hôte, ou vérifier dans `/data/nginx/proxy_host/<id>.conf` qu'aucune `location` en expression régulière ne contourne `location /` **[incertain]**.

---

## 3. Brief, addendum et test D2 bilingue

**a. Pas de retour à la ligne automatique dans les libellés** — *Manquant*

- **Constat.** C'est un point de vigilance nommé par l'addendum et par le §7 du PRD. La spine n'en dit rien.
  - Les retours à la ligne se placent à la main (`\n`), dans chaque fichier de langue.
  - Le FR sort environ 15 % plus large que l'EN.
  - Le test D2 note aussi que le débordement d'un libellé reste à confirmer dans un navigateur.
- **Où corriger.** AD-7, nouvelle puce, et AD-17, check-list manuelle.
- **Formulation proposée.**
  > D2 ne coupe pas les libellés : les retours à la ligne s'écrivent `\n` dans la valeur de `vars`, séparément en FR et en EN, jamais dans `structure.d2`. Check-list AD-17 : pour chaque schéma `ready`, vérifier dans un navigateur, en FR et en EN, qu'aucun libellé ne déborde et que le SVG reste lisible à 320 px CSS (`max-width: 100%; height: auto`).

**b. Variable superflue : comparer aussi avec `structure.d2`** — *Partiel*

- **Constat.** AD-7 compare les clés `vars` de `fr.d2` et de `en.d2`. Une variable en trop des deux côtés (reste d'un nœud supprimé, même faute de frappe) passe inaperçue. Le test recommandait de comparer les clés **à celles de `structure.d2`**. La surcharge par clé (`a.label:`), écartée par le test parce qu'elle crée des nœuds fantômes, n'est pas non plus interdite explicitement.
- **Où corriger.** AD-7, puces 1 et 3 ; liste des contrôles, C9.
- **Formulation proposée.**
  > … et toute différence entre l'ensemble des `${…}` de `structure.d2` et les clés `vars` de chacun de `fr.d2` et `en.d2`. Un fichier de langue ne contient que `vars` et `...@structure` ; aucune surcharge `x.label:`.

**c. Thème : base et règle de précédence** — *Partiel*

- **Constat.** La spine nomme `diagrams/theme.d2` sans son contenu. L'addendum retient « base Neutral Grey » ; le test propose `theme-id` 1 et une palette de surcharge. La règle « l'option `--theme` écrase `theme-id` » est seulement implicite (via `D2_THEME` neutralisé). Le contraste des couleurs de ce thème n'est pas dans la check-list : AD-17 ne mesure que la feuille de style.
- **Où corriger.** AD-7, puce 1 ; AD-17, puce « contraste ».
- **Formulation proposée.**
  > `theme.d2` déclare `theme-id: 1` (Neutral Grey) et les `theme-overrides` du test D2. `render.sh` ne passe jamais `--theme` ni `D2_THEME`, qui écraseraient `theme-id`. Contraste mesuré sur la feuille de style **et sur les couleurs de `theme.d2`** (texte des libellés 4,5:1, traits 3:1).
- **Note.** `--layout elk` en ligne de commande l'emporte aussi sur un `layout-engine` déclaré dans un schéma. C'est cohérent avec le report de « dagre par schéma », mais il faudra modifier `render.sh` le jour où ce besoin viendra. À écrire dans « Reporté ».

**d. « Aucune fuite » : contrôle avant chaque publication** — *Partiel*

- **Constat.** Le brief veut un contrôle du contenu privé sur tout l'historique, exécuté avant **chaque** publication sur GitHub. Or le hook pre-receive ne contrôle que les nouveaux commits : quand la liste des motifs gagne une entrée, l'historique déjà mirroré n'est pas revérifié.
- **Où corriger.** Procédure pre-receive, étape 5.
- **Formulation proposée.**
  > À chaque ajout dans la liste des motifs : lancer `check-private.sh history` sur le serveur, avec la nouvelle liste, et suspendre le miroir push tant que l'audit n'est pas propre.

**e. Mermaid dans les artefacts publics** — *Tension de lecture*

- **Constat.** ADR-2 écarte Mermaid, mais la spine elle-même utilise des blocs Mermaid. Un lecteur du dépôt peut y voir une incohérence.
- **Où corriger.** ADR-2, colonne « Pourquoi ».
- **Formulation proposée.**
  > Mermaid reste utilisé dans les documents de cadrage, rendus par GitHub ; il est écarté pour les schémas du site, qui doivent être du SVG sans JavaScript.

---

## 4. `AGENTS.md` (décisions du dépôt)

**a. Audit avant toute publication, et hook serveur non contournable** — *Contredit par le séquencement du squelette*

- **Constat.** WS-4 active la CI GitHub « par le miroir », donc la publication sur GitHub. Le hook pre-receive (AD-12) et l'audit complet de l'historique viennent « ensuite, hors du squelette ». Or `AGENTS.md` dit qu'un commit poussé sur GitHub reste accessible par son SHA, et FR-28 fait du hook serveur la garantie non contournable.
- **Où corriger.** « Walking skeleton », WS-4, et le paragraphe qui suit.
- **Formulation proposée.**
  > **Prérequis de WS-4 :** hook `pre-receive.d/check-private` installé et testé (étapes 1 à 4 de la procédure) et `check-private.sh history` propre, avec la liste des motifs, sur toutes les références. Le miroir push vers GitHub n'est activé qu'après.

**b. Déplacement du cas pilote** — *Partiel*

- **Constat.** La recommandation 11 prévoit le format v0.3. Mais `AGENTS.md` cite aussi `content/cases/case-02-chiliz.{fr,en}.md` comme fixture, et `docs/format-cas.md` exige un `slug` pour chaque cas, alors qu'un cas groupé n'est jamais rendu à sa propre URL.
- **Où corriger.** « Recommandations à valider », item 11.
- **Formulation proposée.**
  > Passage du format des cas en v0.3 (cas groupés dans `content/cases/<group>/` ; `slug` d'un cas groupé sans effet sur l'URL) et mise à jour du chemin du cas pilote dans `AGENTS.md`, dans la même story.

**c. Outils des contrôles hors de `tools.env`** — *Partiel*

- **Constat.** « Plain scripts » est bien respecté. Mais les contrôles dépendent de `bash`, `jq`, `xmllint` (`libxml2-utils`, pas garanti sur `ubuntu-24.04` ni sur l'image du runner Gitea), `curl` et `git`. Leur installation n'est décidée ni pour les deux CI ni pour l'étape Alpine. De plus, `xmllint --html`, qui analyse du HTML 4, signale `<main>`, `<nav>` et `<figure>` comme invalides.
- **Où corriger.** AD-1, règle, et AD-10, puce « Les contrôles HTML ».
- **Formulation proposée.**
  > `scripts/ci/install-tools.sh` installe aussi, par le gestionnaire de paquets de la plateforme, `jq` et `libxml2-utils` (ou `libxml2-utils` d'Alpine), et vérifie leur présence. L'image de job des runners Gitea est nommée dans `tools.env`. `xmllint --html` sert à extraire, pas à valider : ses erreurs sur les éléments HTML5 sont filtrées.

---

## 5. `docs/format-cas.md` et `data/stack.yaml`

**Règles du format sans contrôle** — *Manquant*

- **Constat.** Plusieurs règles décidées du format ne sont vérifiées par aucun contrôle de C3 à C8 :
  - `title` ≤ 70 caractères ;
  - `setup` ∈ {`employee`, `freelance`, `agency`, `ton-pote-le-geek`} pour un cas non brouillon (sinon `T "setup_…"` rend un libellé vide, sans erreur) ;
  - `type` ∈ {`diagram`, `video`, `snippet`, `callout`} et `status` ∈ {`planned`, `ready`} ;
  - `url` non vide pour une vidéo `ready` ;
  - cohérence entre le `NN` du nom de fichier, `number` et `translationKey`.
- **Où corriger.** Liste des contrôles, C4 ou nouvelle ligne C18 (`scripts/checks/content.sh`).
- **Formulation proposée.**
  > C18 — Front matter conforme au format : `title` ≤ 70 caractères ; `setup`, `type`, `status` dans leurs valeurs autorisées (sauf `[TODO` dans un brouillon) ; `url` présent pour une vidéo `ready` ; `case-NN` du nom de fichier = `number` = `translationKey`.

`data/stack.yaml` : pas d'écart. La lecture passe par `hugo.Data.stack`, et C6 applique la règle d'inclusion.

---

## 6. Checklist de la tâche d'architecture

| Point | État |
| --- | --- |
| Structure du dépôt | Couvert ; ajouter `deploy/proxy/` (2-c1) |
| Config Hugo (langues, sous-dossier, slugs, `translationKey`, `hreflang`, sélecteur sans JS, brouillons) | Couvert ; manquent `disableKinds`, `baseURL`, sitemap (1.2-i) |
| Contenu → gabarits (encarts, shortcode, page Chiliz, ancres, cas mis en avant, i18n EN) | Couvert ; identifiants de titres et hiérarchie (1.2-a), rendu « prévu » (1.2-b) |
| Pipeline D2 (nommage, rendu, emplacement, langue, alt, droits) | Couvert ; retours à la ligne (3-a), thème (3-c), variables (3-b), schéma de démonstration (1.2-c) |
| Build et déploiement (multi-étapes, nginx, registre, Gitea, homelab arrêté) | Couvert ; niveau de contrôle dans le `Dockerfile` (2-a3), cache des secrets (2-a2) |
| CI double sans duplication, dossier des workflows Gitea vérifié | Couvert ; doubles exécutions (1.2-j), fichier factice dans `release` (2-a1) |
| Contrôles, WCAG 2.2 AA, INP sans navigateur | Couvert ; ajouter un seul `<main>` et les liens légaux (1.2-g), contraste du thème D2 (3-c) |
| Procédure pre-receive Gitea | Couvert ; audit à chaque ajout de motif (3-d), ordre avec le miroir (4-a) |
| Agent de parité (options, invocation, déclencheur, coût, secret, GitHub) | Couvert ; consigne sur les lignes de contexte (1.2-h) |
| README-cas | Couvert |
| ADR (pas Symfony, D2 plutôt que Mermaid, Gitea privé et contrôles GitHub) | Couvert ; note sur Mermaid (3-e) |
| Walking skeleton | Couvert ; ordre WS-4 / hook (4-a), WS-5 (2-a3) |

**Hypothèse non écrite (NFR-2).** L'image est construite sur des runners x86_64 et livrée par `docker save`. Le serveur de production doit donc être en amd64, ce que la spine ne dit nulle part. À ajouter dans AD-14 : « Le serveur de production est en amd64 **[à vérifier par Arnaud]** ; sinon, `build-image.sh` construit pour `--platform` de la cible. »
