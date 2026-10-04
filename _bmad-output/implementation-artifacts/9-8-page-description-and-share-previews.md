# Story 9.8 : Page description and share previews

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.8.

Ajoutée à l'epic 9 (pages légales, pages simples et données structurées) par la proposition de
changement du 04/10/2026 (`sprint-change-proposal-2026-10-04.md`), née des mesures PageSpeed de
`v1.0.0` (story 11.11) : aucune page ne portait de meta description ni de balise Open Graph. Sœur de
la story 9.6 (JSON-LD `Person`), qui écrit déjà dans le `<head>`.

Arbitrages d'Arnaud du 04/10/2026 : la description d'un cas est son `summary` ; Open Graph sans
image ; descriptions hors cas rédigées par l'agent et validées par Arnaud — le texte validé est dans
la proposition de changement, § « Contenu », et c'est lui qu'on intègre, sans retouche.

## Revue de spec

### 04/10/2026 — `gemini-3.1-pro-high` (angles : adversarial, structure, prose), `dev` à `6d311d3`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: dd3f09d6c3e9379602e1ba78

##### Rapport de revue (bmad-review)

###### Lentille : Adversarial & Edge Cases (Cas limites et contradictions)
- BLOQUANT : Le critère d'acceptation de C26 liste précisément les conditions d'échec pour la description ("n'a pas de description, en a deux, en porte une vide ou avec `[TODO`, ou qu'elle diffère de son `og:description`") mais omet de vérifier la présence et la conformité des autres balises Open Graph (`og:title`, `og:type`, `og:url`, `og:locale`, `og:locale:alternate`), laissant ces exigences de l'AD-25 non gardées.
- BLOQUANT : AD-25 interdit formellement la balise `og:image` (arbitrage 2) et le premier critère l'exige ("sans `og:image`"), mais C26 ne vérifie à aucun moment l'absence de cette balise, ce qui rend cette interdiction invérifiable par la CI.
- BLOQUANT : Le premier critère d'acceptation énumère explicitement "les balises `og:title`, `og:description`, `og:type`, `og:url`, `og:locale`" en omettant `og:locale:alternate`, ce qui contredit la mention "selon AD-25" (qui l'exige quand la traduction existe) et crée une ambiguïté sur ce qui doit être rendu sur la page.
- BLOQUANT : La spécification affirme que "C23 refuse toujours l'adresse de l'éditeur dans la description des mentions légales", mais ne demande aucun test (fixture) pour le prouver. Sans fixture plaçant l'adresse *spécifiquement* dans la balise `<meta name="description">`, on enfreint la règle 9 d'AGENTS.md exigeant qu'un garde ait un test qui échoue sans lui pour sa nouvelle portée.
- NON BLOQUANT : Le comportement attendu pour la balise `og:url` n'est pas défini pour la page 404, qui ne possède pas de permalien absolu standard (elle s'affiche pour n'importe quelle route invalide), ce qui pourrait rendre la génération de cette balise problématique.

###### Lentille : Structure (Cohérence architecturale)
- NON BLOQUANT : La mécanique de défense en profondeur (le build Hugo échoue en amont si la source manque, puis C26 vérifie le HTML final) implique que le test de C26 devra fournir une fixture HTML artificiellement mal formée, puisque Hugo ne générera jamais l'erreur. C'est cohérent avec les pratiques du projet, bien que non explicité dans la story.
- NON BLOQUANT : Les mises à jour documentaires demandées dans la checklist ("AD-25 passe au présent") sont parfaitement cohérentes avec la règle 8 du projet, l'exigence FR-40 et le contrôle C26 ayant déjà été formulés au présent lors de leur création dans la proposition.

###### Lentille : Prose (Clarté et rédaction)
- NON BLOQUANT : Le texte de la story est globalement clair et bien structuré. L'utilisation du terme "pages hors cas" pour définir les sources des descriptions est sans ambiguïté, la page de groupe Chiliz étant correctement classée comme "hors cas" dans le tableau de contenu de la proposition.

##### À trancher avant d'implémenter
- Le contrôle C26 doit-il inclure la vérification de la présence et de la validité des autres balises Open Graph (`og:title`, `og:type`, `og:url`, `og:locale`, `og:locale:alternate`) ?
- Le contrôle C26 doit-il faire échouer le build si une balise `og:image` est présente ?
- Faut-il ajouter explicitement `og:locale:alternate` à la liste des balises attendues dans le premier critère d'acceptation ?
- Faut-il exiger une fixture de test dédiée pour C23 démontrant que la présence de l'adresse de l'éditeur dans la balise `<meta name="description">` fait bien échouer le contrôle ?
- Quelle valeur utiliser pour `og:url` sur la page 404 ?

### Tri des constats (04/10/2026, orchestrateur)

Tous techniques, tranchés ici ; aucun ne demande d'arbitrage d'Arnaud.

| # | Constat | Décision |
|---|---|---|
| A1 | C26 ne vérifie que la description, pas les autres balises Open Graph (BLOQUANT) | **Retenu.** C26 vérifie aussi, sur chaque page HTML : exactement une balise de chaque `og:title`, `og:type`, `og:url`, `og:locale`, non vide ; `og:title` égal au `<title>` ; `og:url` absolu en `https://` et égal à l'URL de la page dans le build (`baseURL` + chemin) ; `og:type` `website` pour l'accueil de chaque langue, `article` ailleurs ; `og:locale` cohérent avec `<html lang>` (`fr` → `fr_FR`, `en` → `en_US`). |
| A2 | Rien ne vérifie l'absence d'`og:image` (BLOQUANT) | **Retenu** : C26 refuse toute balise `og:image` (et `og:image:*`). |
| A3 | `og:locale:alternate` absent du premier critère (BLOQUANT) | **Retenu, lecture « selon AD-25 »** : la page porte `og:locale:alternate` pour l'autre langue quand sa traduction existe, et seulement alors ; C26 le vérifie dans les deux sens (présente sans traduction, absente avec). |
| A4 | Pas de test prouvant que C23 voit l'adresse dans la meta description (BLOQUANT) | **Retenu** : un cas de test place l'adresse factice de l'éditeur dans la `<meta name="description">` des mentions légales et dans `og:description` ; C23 doit échouer, et le cas est rejoué avec la garde retirée (point 9). |
| N1 | `og:url` de la page 404 | **Tranché** : son permalien Hugo (`/404.html`, `/en/404.html`), absolu. Une 404 n'est pas partagée ; la balise reste vraie pour l'URL qu'elle décrit. |
| S1 | Le test de C26 demande des pages mal formées à la main | **Pris acte** : c'est la pratique des contrôles du projet ; les jeux d'essai ressemblent à la sortie réelle (`<meta charset>`, structure d'une page du build — point 16). |
| S2, P1 | Cohérence documentaire, prose | **Pris acte.** |

## Implémentation

### Ce qui est construit

- `layouts/_partials/head-meta.html` (nouveau) — **seul** endroit qui écrit la `<meta name="description">` et les balises Open Graph. Source de la description : `summary` pour un cas (`Kind` `page` de la section `cases`), clé `not_found_description` d'`i18n/` pour la 404, `.Description` partout ailleurs. Une description absente ou blanche (`strings.TrimSpace`, qui couvre les insécables) arrête le build par `errorf`, en nommant le fichier (`content/about.fr.md (fr) n'a pas de description — « description » absente ou vide…`) ou, pour une page sans fichier, son chemin (`/404 (en)`, `/cases (fr)`). Les balises ne sont émises que si la description existe : un seul message par page, pas une cascade. `og:title` reçoit le `<title>` composé par `baseof.html` ; `og:url` le `.Permalink` ; `og:type` `website` sur `.IsHome`, `article` ailleurs ; `og:locale` d'une table `fr → fr_FR`, `en → en_US`, une langue absente de la table arrêtant le build ; `og:locale:alternate` une fois par élément de `.Translations`. En français, la description passe par `typo-fr-texte.html`, comme le `<title>`. Aucune `og:image`.
- `layouts/baseof.html` — appelle le partial juste après le `<title>`, sur toute page.
- `i18n/fr.yaml`, `i18n/en.yaml` — `not_found_description`, texte validé de la proposition (ligne « 404 »).
- **Contenu** : `description:` dans les douze fichiers hors cas (accueil, « À propos », contact, mentions légales, confidentialité, page Chiliz, FR et EN), texte validé de la proposition **à l'identique** — vérifié par un `grep -F` de chaque valeur contre le tableau de la proposition. Contact, mentions légales et confidentialité portaient déjà une `description` que rien ne lisait : elle est remplacée par le texte validé.
- `scripts/checks/head-meta.sh` (nouveau) — **C26**, découvert par `check.sh` sans le modifier. Production seule. Par page : exactement une description, non blanche, sans `[TODO` ; exactement une de chaque `og:description` (= description), `og:title` (= `<title>`), `og:type` (`website` / `article`), `og:url` (absolu `https://`, = `baseURL` + chemin, `index.html` final retiré, `%XX` décodé), `og:locale` (= locale de `<html lang>`) ; `og:locale:alternate` = locales des traductions lues dans les `hreflang` du `<head>` (hors `x-default` et la langue de la page), ni plus ni moins, sans doublon ; aucune `og:image` ni `og:image:*`. Une balise compte quelle que soit sa casse et qu'elle soit posée en `property=` ou en `name=`. Anomalies (code 2) : rendu absent, aucune page HTML, `xmllint` absent, `baseURL` introuvable ou hors `https://`, lecture XPath en échec.
- `scripts/checks/lib.sh` — `checks_est_accueil`, la règle « accueil du site ou d'une langue », qui vivait en deux copies (`html.sh` en fonction, `links.sh` en ligne) et dont C26 était le troisième lecteur ; les deux aînés l'appellent désormais (« une parade s'écrit une fois »).
- **C3** (`parity.sh`) — **aucun changement** : C3 ne compare que la liste des clés non traduites, où `description` n'est pas ; un cas de test (`parity_description_se_traduit`) le fige, avec sa paire (`identity` reste comparée). La présence d'une description de part et d'autre n'est pas l'affaire de C3 : une page rendue sans elle arrête le build.
- **C23** — aucun changement de code ; un cas de test nouveau (constat A4) : `legal_adresse_dans_la_description_rendue_par_ad25`.
- **Documentation** : AD-25 au présent (partial nommé, source de la 404, typographie, échappement, échec dans les deux rendus) ; ligne C26 avec son script ; FR-40 dans les `binds` du document d'architecture, dans l'arborescence (`head-meta`) et dans le tableau « Capacités → architecture » ; `docs/procedures/check.md` reçoit la ligne C26 ; `docs/format-cas.md` dit que `summary` est publié deux fois pour un cas qui a sa page, et qu'un tel cas sans `summary` arrête le build ; la question ouverte `epic-6-oq-typographie-des-metadonnees` de `sprint-status.yaml` est réglée par cette story. `docs/format-parcours.md` n'est pas touché : un poste n'est jamais rendu, il n'a pas de description. Documents relus en entier après modification (point 8).

### Décisions prises en cours de route

- **La 404 lit sa description dans `i18n/`.** AD-25 disait « `.Description` pour toute autre page » ; la 404 n'a pas de fichier de contenu, et son titre comme son corps viennent déjà d'`i18n/` (AD-3 ; constat C1 de la rétrospective de l'epic 4 pour le titre). AD-25 le dit désormais. Constaté en passant : Hugo comble une clé i18n absente d'une langue par celle de la langue par défaut — retirée du seul anglais, la 404 anglaise prenait le texte français et le build passait. Le cas de test retire la clé des deux langues.
- **Le refus vaut dans les deux rendus.** Le modèle vide de `docs/format-cas.md` porte un `summary` en `[TODO: …]` ; aucun brouillon du dépôt n'en manque (cas 03, 04, 06 vérifiés), et le rendu de travail se construit. Tolérer l'absence en travail aurait rendu une balise vide là où AD-25 l'interdit, pour aucun cas réel.
- **La typographie française compose la description.** C'est la règle du `<title>` (le commentaire de `baseof.html` l'argumente) et la question ouverte de l'epic 6 la posait pour ces métadonnées. La composition remplace une espace par l'insécable voulue (vérifié sur l'accueil : U+00A0 devant « : ») ; elle n'ajoute ni ne retire aucun mot. **C24 n'est pas étendu aux attributs** : la composition est éprouvée par `partial_typographie_francaise_sur_la_description` ; un contrôle de sortie sur les `content` de `<meta>` serait la moitié manquante de la remarque de la story 6.3 — à décider si l'orchestrateur le juge utile.
- **Les fixtures de neuf fichiers de test reçoivent une description** (point 16 : le site d'essai ressemble au vrai). Deux d'entre elles ne posaient pas seulement une clé : `test-career-position.sh` construisait un site **sans** les `_index` du parcours et des cas, si bien que chaque poste et la section `/cases/` devenaient des pages — il copie désormais les `_index` du dépôt ; le site fixture du manifeste (`scripts/tests/fixtures/site/`) garde sa page sans front matter, qui éprouve l'entrée « front matter absent » du manifeste, en lui donnant une description par une `cascade` de son accueil (commentée dans le fichier), et ses cas fixtures reçoivent un `summary` en `[TODO`.
- **Piège bash relevé** en écrivant le cas C23 : depuis bash 5.2 (`patsub_replacement`, actif sur le poste, bash 5.3), un `&` nu dans le remplacement de `${var//motif/remplacement}` désigne le texte trouvé — `&#39;` devenait `'#39;`, la fixture ne contenait plus l'adresse, C23 passait au vert et le cas échouait pour une raison étrangère au contrôle. Remplacements mis entre guillemets, commenté dans le cas. Le tableau des pièges vit dans `.working-method/procedures/shell-scripts.md`, hors de ce dépôt : à y porter par le dépôt commun.

### Marche du fichier jumeau (point 19)

**Aîné 1 : `layouts/_partials/jsonld-person.html` (story 9.6), l'autre partial qui écrit dans le `<head>`.**

| Garde de l'aîné | Le cadet en a-t-il besoin ? |
|---|---|
| `errorf` sur une donnée absente (`identity`, `job_title`) plutôt qu'un bloc à trous | **Oui** : `errorf` sur une description absente ou blanche, et sur une langue sans locale. Testé (`partial_*_arrete_le_build`). |
| Un seul message par défaut (`errorf` n'interrompt pas le rendu ; cascade évitée par un `else`) | **Oui** : les balises ne sont émises que dans la branche où la description existe. |
| `url` = permalien de la page, pas `baseURL` (deux accueils annonceraient la même adresse) | **Oui** : `og:url` = `.Permalink` ; testé sur `/en/about/` et sur la 404. |
| `strings.TrimSpace` plutôt que `trim " "`, pour l'insécable | **Oui** : le test de vacuité emploie `strings.TrimSpace` ; une description de blancs arrête le build (`partial_description_blanche_arrete_le_build`). |
| `safeJS` pour que le JSON reste un objet dans un `<script>` | **Non, et l'inverse** : dans un attribut, aucune fonction `safe*` — l'échappement de Hugo fait foi. Testé avec `"`, `&`, `'`, `<` relus à l'identique par un parseur HTML. |
| Le choix des pages porteuses est fait dans `baseof.html` (accueils seuls), pas dans le partial | **Adapté** : toute page porte les balises, donc `baseof.html` appelle toujours ; le partial ne choisit que la **source** (cas, 404, autre). |
| Valeurs tirées du contenu, jamais écrites dans le gabarit | **Oui**, sauf ce qu'AD-25 fixe lui-même : la table des locales et les deux valeurs d'`og:type`. |
| Page de contact absente tolérée (`sameAs` omis) | **Non** : une description absente n'est jamais tolérée (AD-25). |

**Aîné 2 : `scripts/checks/legal-address.sh` (C23) et `scripts/checks/html.sh` (C10/C11), contrôles de sortie.**

| Garde de l'aîné | Le cadet en a-t-il besoin ? |
|---|---|
| Rendu absent → anomalie (2) | **Oui** — `c26_rendu_absent_est_une_anomalie`. |
| `xmllint` absent → anomalie | **Oui** (non testé par un cas : même ligne que les aînés, qui ne le testent pas non plus). |
| Liste de pages vide → anomalie, jamais un succès | **Oui** — `c26_aucune_page_est_une_anomalie`. |
| Code de `checks_xpath` propagé hors de la substitution, jamais avalé | **Oui**, à quatre endroits : `lire`, la validation numérique de `compter`, la lecture des `hreflang` et celle des alternatives. `c26_page_illisible_est_une_anomalie` ; ces gardes se recouvrent (défense en profondeur), si bien que la mutation qui les retire toutes les quatre est celle qui fait échouer le cas — retirer la seule propagation de `lire` ne le fait pas échouer, la validation numérique de `compter` rattrapant la lecture vide. |
| Valeur requise absente → anomalie (C23 : l'adresse) | **Oui**, sous la forme `baseURL` introuvable ou hors `https://` — `c26_baseurl_en_http_est_une_anomalie`. |
| Décoder les entités avant de comparer (`decoder_echappements`) | **Non** : C26 compare des valeurs extraites par XPath `string()`, que le parseur a déjà décodées des deux côtés ; testé avec `&amp;`, `'` et `«»` dans les fixtures, et sur un vrai build dont la sortie minifiée emploie des apostrophes simples comme délimiteur. |
| Ne jamais afficher la valeur cherchée | **Non requis** : les descriptions sont publiques ; C26 n'affiche quand même aucune description, seulement titres, URL et locales, plus courts et utiles au diagnostic. |
| Sorties non HTML, octets nuls (`tr -d '\0'`) | **Non** : seule une page HTML porte un `<head>`. |
| Lire les deux rendus (`checks_roots_into`, html.sh) | **Non, volontairement** : production seule, un `summary` en `[TODO` étant légitime dans un brouillon. |
| `est_accueil` (html.sh) | **Oui, et mis en commun** : `checks_est_accueil` dans `lib.sh`, testée par `checks_est_accueil` de `test-checks-lib.sh` (accueils, et neuf chemins qui n'en sont pas). |
| Casse : `checks_attributes` sur des noms d'attributs fixes | **Renforcé** : un doublon `NAME=DESCRIPTION` ou une balise Open Graph posée en `name=` est compté (règle 15 : d'autres formes du même défaut). |

### Gardes et mutations (point 9)

Chaque cas a été lancé une fois la garde retirée (remplacée par `false`, `true ||` ou une forme affaiblie), sur une copie restaurée ensuite ; tous échouent alors, et passent avec la garde.

| Garde | Mutation | Cas qui échoue(nt) |
|---|---|---|
| C26 — une seule description | décompte ignoré | `c26_description_absente`, `c26_deux_descriptions` |
| C26 — casse ignorée | `@name='description'` exact | `c26_doublon_ecrit_dans_une_autre_casse` |
| C26 — description blanche | test retiré | `c26_description_vide` |
| C26 — `[TODO` | test retiré | `c26_description_todo` |
| C26 — `og:description` = description | test retiré | `c26_og_description_differente` |
| C26 — chaque balise exigée | décompte de `og:title`, puis de `og:url`, retiré | `c26_chaque_balise_og_absente` |
| C26 — balise posée en `name=` | `property=` seul | `c26_balise_og_en_double` |
| C26 — `og:title` = `<title>` | test retiré | `c26_og_title_different_du_titre` |
| C26 — `https://` | test retiré | `c26_og_url_relative`, `c26_og_url_en_http` |
| C26 — URL de la page | test retiré | `c26_og_url_dune_autre_page`, `c26_og_url_dun_autre_hote` |
| C26 — décodage `%XX` | URL comparée brute | `c26_og_url_encodee_dun_chemin_non_ascii` |
| C26 — `website` sur l'accueil | attendu toujours `article` | `c26_og_type_de_laccueil` |
| C26 — `article` ailleurs | test retiré | `c26_og_type_dune_page` |
| C26 — locale de `<html lang>` | test retiré | `c26_og_locale_incoherente` |
| C26 — langue sans locale | test retiré | `c26_langue_sans_locale` |
| C26 — alternatives = traductions | comparaison retirée | `c26_alternate_sans_traduction`, `c26_alternate_absente_avec_traduction`, `c26_alternate_fausse_ou_doublee` |
| C26 — aucune `og:image` | test retiré, puis `starts-with` remplacé par `=` | `c26_og_image_refusee` (les deux mutations) |
| C26 — aucune page → anomalie | garde retirée | `c26_aucune_page_est_une_anomalie` |
| C26 — `baseURL` en https | garde retirée | `c26_baseurl_en_http_est_une_anomalie` |
| C26 — lecture en échec → anomalie | les quatre propagations retirées ensemble | `c26_page_illisible_est_une_anomalie` |
| Partial — description absente arrête le build | `if false` | les cinq `partial_*_arrete_le_build` |
| Partial — description blanche | `not $description` au lieu de `TrimSpace` | `partial_description_blanche_arrete_le_build` |
| Partial — `summary` d'un cas | branche retirée | `partial_cas_sans_summary_arrete_le_build`, `partial_balises_rendues_et_c26_passe_sur_un_vrai_build` |
| Partial — 404 par `i18n/` | branche retirée | `partial_balises_rendues_et_c26_passe_sur_un_vrai_build` |
| Partial — typographie française | composition retirée | `partial_typographie_francaise_sur_la_description` |
| Partial — alternatives des seules traductions | `.AllTranslations` | `partial_balises_rendues_et_c26_passe_sur_un_vrai_build` |
| Partial — échappement de Hugo | attribut assemblé par `printf` + `safeHTMLAttr` | `partial_echappement_des_caracteres_speciaux` |
| Partial — `og:type` | toujours `article` | `partial_balises_rendues_et_c26_passe_sur_un_vrai_build` |
| C23 — toute balise `meta` lue | lecture des `meta` neutralisée | `legal_adresse_dans_la_description_rendue_par_ad25` |
| C3 — `description` traduite | `description` ajoutée aux clés non traduites de l'accueil | `parity_description_se_traduit` |

Une première mutation de l'échappement (`| safeHTML` dans l'attribut) **ne faisait rien échouer** : le cas d'échappement passait encore, le moteur de gabarits de Go ne laissant pas un `template.HTML` sortir tel quel d'un attribut. Ce n'était donc pas une garde à éprouver ; la mutation retenue est celle qui contourne réellement l'échappement.

### Pages couvertes

Production (18 pages HTML) : les deux accueils, « À propos », contact, mentions légales, confidentialité, page Chiliz, 404 — FR et EN — et les deux cas publiés à page propre (01, 05), dont la description est le `summary`. Le rendu de travail ajoute le cas 06 (brouillon, `summary` présent). **Aucune page que la proposition n'ait pas listée** : les autres sorties de `public/` (`sitemap.xml`, `robots.txt`, la feuille de style, les images, les CV PDF) ne sont pas des pages HTML.

### Le `<head>` rendu (production)

Accueil FR (`public/index.html`) — l'espace devant « : » de la description est une insécable U+00A0 :

```html
<head>
<meta name=generator content="Hugo 0.166.0">
<meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<title>Arnaud Grousset · Développeur backend senior</title>
<meta name=description content="Développeur backend PHP et Symfony senior depuis 2008 : architecture, flux financiers fiables, jugement technique. Le CV et des cas concrets.">
<meta property="og:title" content="Arnaud Grousset · Développeur backend senior">
<meta property="og:description" content="Développeur backend PHP et Symfony senior depuis 2008 : architecture, flux financiers fiables, jugement technique. Le CV et des cas concrets.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://eleyone.fr/">
<meta property="og:locale" content="fr_FR">
<meta property="og:locale:alternate" content="en_US">
<link rel=alternate hreflang=fr href=https://eleyone.fr/>
<link rel=alternate hreflang=en href=https://eleyone.fr/en/>
<link rel=alternate hreflang=x-default href=https://eleyone.fr/>
<link rel=stylesheet href=/css/main.min.2e6d86974752c434d6fee8163350870946aa73cffb57b11aa707fa7fcbaf9041.css>
<script type=application/ld+json>{…bloc Person inchangé (story 9.6)…}</script>
</head>
```

Accueil EN (`public/en/index.html`) :

```html
<title>Arnaud Grousset · Senior Backend Developer</title>
<meta name=description content="Senior PHP and Symfony backend developer since 2008: architecture, reliable financial flows, technical judgment. The CV and real-world cases.">
<meta property="og:title" content="Arnaud Grousset · Senior Backend Developer">
<meta property="og:description" content="Senior PHP and Symfony backend developer since 2008: architecture, reliable financial flows, technical judgment. The CV and real-world cases.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://eleyone.fr/en/">
<meta property="og:locale" content="en_US">
<meta property="og:locale:alternate" content="fr_FR">
```

### Vérifications lancées

- `scripts/check.sh` : 13 contrôles passés (C26 compris), builds de travail et de production sans avertissement (`--panicOnWarning`, C14).
- C22 au niveau `release` contre la liste des motifs (`PRIVATE_PATTERNS_FILE`) : 23 fichiers confrontés, aucune occurrence.
- `bash .working-method/tests/run.sh scripts/tests/test-*.sh` : 939 cas réussis, 1 ignoré (`pdf_repli_sur_la_liste_du_depot` : pas de `docs/private/` dans un worktree), sur 940 cas.
- shellcheck 0.11.0 (`-x -P SCRIPTDIR`) : aucun constat sur `scripts/checks/head-meta.sh` ni `scripts/tests/test-head-meta.sh`.

## Revue du code

### 04/10/2026 — PR n° 139, `gemini-3.1-pro-high`, SHA `856669e`, verdict `pass`

Rapport recopié de la PR (le script a tourné depuis le dépôt principal, sur une autre branche).
L'orchestrateur a rejoué la suite (939 cas, 1 ignoré faute de `docs/private/` dans la copie),
`scripts/check.sh` (13 contrôles) et vérifié les descriptions validées, mot pour mot, dans le contenu
et dans les pages construites.

llm-review sha=856669e072c67b068675d180d74e54cf06a06faf base=dev model=gemini-3.1-pro-high verdict=pass

_Revue par `review/llm-review.sh` du dépôt commun : `agy --mode plan`, copie isolée hors du dépôt au SHA relu, sans `.git` ni les chemins privés du projet (.env docs/private .pr-body.md) ; méthode de revue de la couche projet appliquée par le relecteur (angles : edge-case-hunter, verification-gap, plus la couche propre au projet). Fichiers créés ou modifiés par le relecteur dans la copie : aucun._

JETON: 9f91d32e3be1c6ba6979bd6d

### Lentille : Edge Cases (Cas limites)
- NON BLOQUANT : `scripts/checks/head-meta.sh:decoder_url` — Si l'URL évaluée contient à la fois le caractère `%` et un antislash littéral (`\`), la commande `printf '%b'` interprétera l'antislash comme une séquence d'échappement (ex: `\b` devient le caractère backspace). Cela corromprait la chaîne décodée et fausserait la comparaison. Bien qu'improbable pour les URL de ce projet, injecter `url=${url//\\/\\\\}` avant le remplacement des `%` fermerait cette branche non gérée.

### Lentille : Verification Gaps (Écarts de vérification)
- NON BLOQUANT : Aucun écart de vérification trouvé. La stratégie de test de la story comble tous les angles morts classiques : le partial est testé sur les résultats d'un vrai build Hugo (vérifiant son arrêt sur erreur), et le contrôle C26 est éprouvé sur des fixtures doctorées simulant des erreurs de gabarit que Hugo seul ne pourrait pas produire. 

### Contrôles du projet
- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits sans que leur intention soit vidée (génération des descriptions, balises Open Graph conformes à l'AD-25).
- NON BLOQUANT : Aucune donnée privée, nom d'hôte de production ni secret n'est commité, et aucun script ne peut en afficher.
- NON BLOQUANT : Skill, procédure et script concordent : C26 est listé avec précision dans `docs/procedures/check.md` et correspond aux vérifications de `head-meta.sh`.
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (mise à jour exhaustive de `ARCHITECTURE-SPINE.md`).
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (les échecs de commandes comme `xmllint` appelées dans des substitutions de sous-shells sont rigoureusement propagés via `|| exit $?`).

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue (orchestrateur)

| # | Constat | Décision |
|---|---|---|
| E1 | `decoder_url` (`scripts/checks/head-meta.sh:105`) passe l'URL à `printf '%b'` : un antislash littéral y serait interprété | **Retenu, reporté** dans `deferred-work.md`. Balayage (règle 7 commune) : c'est le seul emploi de `printf '%b'` sur une donnée dans `scripts/` ; aucun chemin du rendu ne contient d'antislash (`find public -name '*\\*'` : rien), Hugo n'en produit pas dans un slug. Le corriger rouvrirait la revue d'une PR verte pour une entrée qui ne peut pas se présenter aujourd'hui. |
| V1 | Aucun écart de vérification | Pris acte. |
| P1–P5 | Critères satisfaits ; aucune donnée privée ; `check.md` concorde ; cohérence ; erreurs propagées | Pris acte. |

**Deux points relevés par l'implémentation, reportés** (`deferred-work.md`) : C24 ne lit pas les
attributs, si bien que la typographie française des descriptions est vérifiée par un test et non par
un contrôle de la sortie ; le tableau « Contrôles livrés » de `docs/procedures/check.md` n'a pas de
ligne pour C21, C23 et C24, oubli antérieur à cette story.
