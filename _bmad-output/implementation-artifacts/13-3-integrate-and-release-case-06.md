# Story 13.3 : Integrate and release case 06

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 13.3.

Story d'intégration de l'epic 13 (point 21) : le cas 06 (« April Technologies, hors périmètre ») est
**rédigé par Arnaud** — `content/cases/case-06-april-technologies.{fr,en}.md`, en brouillon. Il ne
manque qu'une ligne de contexte EN, que l'archive remise par Arnaud le 03/10/2026 fournit : « April
Technologies is the IT arm of April, a French insurance group. » Blocage Q2 levé le 05/10/2026
(PR n° 146) : période « 2017 », second passage chez April Technologies, en mission pour Modis.

Deux corrections de fait, décidées par Arnaud le 05/10/2026 :
- la mission antérieure (2013–2014) se faisait **chez CGI, pour le compte d'April** (AD-18, corrigé le
  24/09/2026), et non « pour le compte de CGI » ;
- le passage de 2017 est **en mission pour Modis**, pas une embauche.

**Mise en ligne** : arbitrage d'Arnaud du 06/10/2026 — le cas 04 (story 13.2, fusionné) et le cas 06
partent ensemble, par un seul tag, après cette story ; écart assumé avec « un par un » de l'epic 13.

## Revue de spec

### 06/10/2026 — `gemini-3.1-pro-high` (angles : adversarial, structure, prose), `dev` à `81cf2fb`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a1384f1c9e2b2ff493f711f8

**Revue de la spécification (Story 13.3)**

- BLOQUANT : Le troisième critère d'acceptation stipule que « le cas est mis en ligne seul ». Ceci contredit l'arbitrage d'Arnaud du 06/10/2026 mentionné dans les notes de la PR, qui indique que le cas 04 et le cas 06 partent ensemble sous un seul et même tag. Ce critère imposerait de vérifier un comportement désormais faux et contraire à la décision en vigueur.
- BLOQUANT : Les deux corrections de fait requises par Arnaud (remplacer la notion d'« embauche » par une prestation pour Modis en 2017, et préciser que la mission de 2013–2014 s'est faite chez CGI pour le compte d'April) sont absentes des critères d'acceptation. Sans critère explicite pour valider la modification du texte du cas (qui emploie actuellement le terme « embauché » dans son résumé et son contexte), le développeur risque de simplement retirer l'état de brouillon en laissant des faits erronés, ce qui violerait l'exigence NFR-10 du projet (« Rien d'inventé » / fidélité stricte au parcours).
- NON BLOQUANT : La présence de la ligne de contexte EN est assortie de la mention `*(relecture)*`, ce qui délègue le contrôle à une vérification humaine. Puisque le contenu exact de cette phrase est fourni et connu (« April Technologies is the IT arm of April, a French insurance group. »), le critère pourrait tout à fait être vérifié de manière automatisée.

##### À trancher avant d'implémenter
- Modifier le troisième critère d'acceptation de la story pour s'aligner sur la décision de mise en ligne groupée avec le cas 04.
- Ajouter explicitement des critères d'acceptation exigeant la correction du texte du cas 06 (FR et EN) concernant le statut de prestation pour Modis et le compte d'April via CGI, avant la publication effective du fichier.

### Tri des constats (06/10/2026, orchestrateur)

La revue a tourné pendant la publication (elle a demandé 15 minutes) ; ses constats portent sur le
texte du backlog et sont tous couverts par ce qui a été fait.

| # | Constat | Décision |
|---|---|---|
| 1 | « Le cas est mis en ligne seul » contredit la mise en ligne groupée avec le cas 04 (BLOQUANT) | **Retenu comme arbitrage d'Arnaud (06/10/2026)** : les cas 04 et 06 partent ensemble, par un seul tag ; le critère se lit « seuls les cas 04 et 06 apparaissent de nouveau, le cas 03 reste en brouillon ». Le texte validé d'`epics.md` n'est pas réécrit ; l'écart est écrit ici et dans l'en-tête du fichier. |
| 2 | Les deux corrections de fait ne sont pas dans les critères (BLOQUANT) | **Retenu, fait** : les quatre formulations ont été soumises à Arnaud et validées le 06/10/2026, puis appliquées avant la publication (commit « mission chez CGI pour April, passage de 2017 en mission pour Modis, contexte EN ») ; voir « Publication ». |
| 3 | La ligne de contexte EN pourrait être vérifiée mécaniquement | **Retenu, vérifié** : la phrase exacte figure une fois dans `case-06-april-technologies.en.md` (grep). |

## Publication (06/10/2026)

- **Corrections validées par Arnaud** (06/10/2026), FR et EN : « Venu » / « Brought in » à la place
  d'« Embauché » / « Hired » dans « En bref » ; mission de 2013–2014 « chez CGI, pour le compte
  d'April » / « at CGI, for April » ; passage de 2017 « en mission pour Modis » / « on assignment
  through Modis » ; ligne de contexte EN de l'archive à la place du dernier `[TODO]`.
- `scripts/publish-case.sh case-06` (audit, sur la branche de la story) : contrôles verts ; deux
  fichiers à passer hors brouillon, `case-06` à ajouter à `ci/release-pages.txt`.
- **Relecture d'Arnaud** : « relu » (06/10/2026), trace du `--relu`. Les gestes de `--relu` faits sur la
  branche de la story, comme pour les cas 05 (story 10.7) et 04 (story 13.2).
- Build de production : `/cas/april-hors-perimetre/` et `/en/cases/april-beyond-scope/` ; le poste
  April Technologies 2017 les lie depuis l'accueil, dans chaque langue ; la page du cas renvoie au
  poste ; la page Chiliz garde les sections 02 et 04, le cas 03 reste absent.
- `scripts/check.sh --release` avec les vraies valeurs légales : 13 contrôles passés.

## Revue du code

### 06/10/2026 — `79b464a` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 148. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: bf4a084502e8453c75ff199c

##### Lentille `edge-case-hunter`
NON BLOQUANT — Les modifications apportées concernent exclusivement du contenu rédactionnel (markdown), de la configuration (txt) et des fichiers de suivi (yaml). Aucun code exécutable n'est ajouté ni supprimé, par conséquent aucun cas limite ou flux logique non géré n'a été détecté.

##### Lentille `verification-gap`
NON BLOQUANT — `No verification gaps found.` Le changement est purement non-comportemental sur le plan du code. L'ajout statique à la liste de publication et les corrections de texte ne génèrent aucune lacune de vérification.

##### Contrôles du projet
NON BLOQUANT — Les critères d'acceptation de la story sont pleinement satisfaits (application précise des formulations corrigées, ajout de la phrase de contexte en anglais, suppression du statut de brouillon), sans que leur intention initiale ne soit vidée.
NON BLOQUANT — Le diff ne contient et ne fait fuiter aucune donnée privée interdite (numéro de téléphone, adresse, etc.), aucun secret ni aucune adresse de serveur.
NON BLOQUANT — La concordance entre skill, procédure et script reste intacte puisqu'aucun fichier de ce type n'est touché par la pull request.
NON BLOQUANT — Les modifications respectent `AGENTS.md` et les décisions d'architecture. Le remplacement de la mention `[TODO]` n'est pas une invention mais exploite fidèlement l'archive fournie par l'auteur, et l'entorse au principe de publication unitaire est justifiée par un arbitrage explicite documenté.
NON BLOQUANT — Le fonctionnement de `set -euo pipefail` n'est pas mis en défaut puisqu'aucun script shell n'est modifié.

VERDICT: NON BLOQUANT — aucune


#### Décisions sur la revue de `79b464a` (orchestrateur)

Sept constats de conformité, sans demande de changement : **pris acte**, un par un — aucun cas limite
(aucun code modifié) ; aucune faille de vérification ; critères satisfaits ; aucune donnée privée ;
concordance sans objet ; cohérence avec AGENTS.md, y compris la ligne EN tirée de l'archive d'Arnaud
et la mise en ligne groupée qu'il a arbitrée ; aucun script modifié.

## Mise en ligne (06/10/2026)

Publiée en `v1.1.0` avec les cas 03, 04 et 06, par un seul tag (arbitrage d'Arnaud du 06/10/2026) :
répétition `v1.1.0-rc.1` / `rc.2` verte sur `5f3538a`, audit `release` vert (PR n° 150), `--merge`
lancé par Arnaud, run `release` du tag `v1.1.0` en succès. Vérifié sur le site servi à 10:31 UTC :
la page Chiliz porte les sections `case-02`, `case-03`, `case-04` en FR et en EN, la ligne « Côté
technique » / « On the technical side » du cas 03 est servie, l'accueil FR et EN lie les cas 02, 03
et 04 sous le poste Chiliz et le cas 06 (`/cas/april-hors-perimetre/`,
`/en/cases/april-beyond-scope/`, réponse 200, une `<meta name="description">` chacune).
