# Story 11.13 : Production rollback on second deployment

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 11.13.

Dernière story de la section « Mise en ligne du socle » de l'epic 11 : éprouver en production le
retour arrière que la répétition générale a éprouvé sur son canal (AD-14, AD-22). Dépendances
remplies : 11.11 (socle en ligne, `v1.0.0`, PR n° 137) et un deuxième tag de production, `v1.0.1`
(story 9.8, publiée le 04/10/2026). La 11.12 (skill `hotfix`) la précède dans l'ordre du backlog sans
qu'elle en dépende.

Opération manuelle d'Arnaud, par la commande forcée du compte de déploiement :
`rollback v1.0.0`, vérifications, puis retour à `v1.0.1`. Les deux versions se distinguent sur le site
servi : `v1.0.0` ne porte aucune `<meta name="description">`, `v1.0.1` en porte une sur chaque page.

## Revue de spec

### 05/10/2026 — `gemini-3.1-pro-high` (angles : adversarial, structure, prose), `dev` à `9c98d10`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: b1563f59fa28ec44c632ea8e

##### Lentille Adversarial
- BLOQUANT : La story est marquée comme une opération manuelle pour Arnaud, mais la spécification ne demande pas au développeur de préparer la liste de vérification documentée, ce qui contredit directement la règle 10 d'AGENTS.md (« Arnaud l'exécute, le développeur prépare les fichiers versionnés et la liste de vérification »). Sans cette exigence, le développeur n'a rien à implémenter.
- BLOQUANT : Le critère d'acceptation « Au plus trois images de production restent sur le serveur » omet de préciser avec quel outil ou quelle commande cette limite d'images doit être comptée sur le serveur. En l'état, ce critère est invérifiable.
- BLOQUANT : La distinction visuelle entre `v1.0.0` et `v1.0.1` (l'absence ou la présence de `<meta name="description">`) est expliquée dans la note d'intention de l'auteur, mais ne figure pas dans les critères d'acceptation. Le critère « le site sert la version précédente » manque d'une vérification concrète et mesurable.
- BLOQUANT : La séquence « puis le dernier tag est redéployé » ne définit pas l'action exacte requise. L'opérateur ne sait pas s'il doit lancer à nouveau un appel à `rollback` ou utiliser `deploy v1.0.1`, ce qui présente un risque d'ambiguïté lors du retour à la normale en production.

##### Lentille Structure
- NON BLOQUANT : Le bloc de dépendances mentionne génériquement « un deuxième tag de production » sans identifier la story sous-jacente (9.8). La nommer explicitement relierait mieux cette story au reste de l'historique du backlog.
- NON BLOQUANT : Le scénario BDD mélange dans sa clause **Alors** la constatation d'un état (« `status` montre le tag précédent ») et le déclenchement d'une nouvelle action (« puis le dernier tag est redéployé »). Le redéploiement devrait logiquement faire l'objet d'un nouveau bloc **Quand / Alors**.

##### Lentille Prose
- NON BLOQUANT : L'expression « par la commande forcée » manque de contexte immédiat et exige de se rappeler l'architecture (AD-14) ; préciser « la commande SSH forcée » dissiperait l'ambiguïté pour tout lecteur.
- NON BLOQUANT : La ligne « afin de corriger en quelques secondes une mise en ligne ratée » décrit la finalité de la fonction de rollback de manière générale, alors que l'intention précise de la story est d'effectuer un test de validation en production de cette mécanique.

##### À trancher avant d'implémenter
- Le développeur doit-il documenter la liste de vérification dans un fichier pérenne (ex. sous `docs/procedures/`) ou bien la fournir uniquement dans le fichier de la story ?
- Quelle est la commande technique exacte à lancer pour vérifier que seules trois images de production résident sur le serveur ?
- Quelle est la commande exacte exigée pour redéployer le dernier tag (`deploy` ou `rollback`) ?
- Doit-on intégrer la vérification de l'existence de la balise `<meta name="description">` explicitement dans les critères d'acceptation pour prouver le changement de version du site ?

### Tri des constats (05/10/2026, orchestrateur)

| # | Constat | Décision |
|---|---|---|
| A1 | « La règle 10 d'AGENTS.md » exige que le développeur prépare une liste de vérification (BLOQUANT) | **Invalide sur la règle, retenu sur le fond.** Aucune règle de ce texte n'existe : la règle 10 du bloc commun (`.working-method/agents/AGENTS.common.md`) porte sur la délégation à un sous-agent, le point 10 d'`AGENTS.md` sur le comportement des outils ; ni l'un ni l'autre, ni aucun autre point (grep « liste de vérification », « prépare les fichiers ») ne parle d'une liste à préparer — c'est le cas du relecteur qui emporte une règle d'ailleurs (règle 9 commune). Le fond est juste : la marche à suivre exacte est écrite ci-dessous, dans ce fichier, et la procédure pérenne existe déjà (`docs/procedures/deploy-site.md`, demandes `rollback <tag>` et rétention des trois images). |
| A2 | « Au plus trois images » invérifiable sans commande (BLOQUANT) | **Retenu** : `docker images eleyone-site --format '{{.Tag}}'` par le compte d'administration ; on compte les tags `vX.Y.Z` (les `-rc` en sont exclus, `deploy-site.md` : la rétention ne vaut que pour la production). |
| A3 | La preuve que le site sert la version précédente n'est pas dans les critères (BLOQUANT) | **Retenu, écrit ici** : sur `https://eleyone.fr/` et `/en/`, aucune `<meta name="description">` quand `v1.0.0` est servie, une seule quand `v1.0.1` l'est ; plus `status`. |
| A4 | « Le dernier tag est redéployé » : `deploy` ou `rollback` ? (BLOQUANT) | **Tranché** : `rollback v1.0.1`. `deploy` exige l'archive de l'image sur l'entrée standard (seul le workflow `release` la fournit) ; `rollback` relance le service sur une image **déjà présente**, ce qu'est `v1.0.1` (`deploy-site.md`, tableau du protocole). |
| S1–S2, P1–P2 | Structure et prose de la spec | **Pris acte**, sans réécriture d'`epics.md` : la marche à suivre ci-dessous lève les ambiguïtés. |

### Marche à suivre (Arnaud, depuis le poste ; l'orchestrateur vérifie le site entre chaque étape)

1. `ssh "$(sed -n 's/^DEPLOY_HOST=//p' .env)" 'rollback v1.0.0'` puis `… status` : attendu `production : eleyone-site:v1.0.0`.
2. Vérification de l'orchestrateur : l'accueil FR et EN répond `200`, **sans** meta description.
3. `ssh "$(sed -n 's/^DEPLOY_HOST=//p' .env)" 'rollback v1.0.1'` puis `… status` : attendu `production : eleyone-site:v1.0.1`.
4. Vérification de l'orchestrateur : l'accueil FR et EN répond `200`, **avec** une meta description ; images de production comptées par le compte d'administration (au plus trois).

## Exécution (05/10/2026, par Arnaud ; vérifications de l'orchestrateur)

**Premier passage.** Arnaud a enchaîné `rollback v1.0.0` puis `rollback v1.0.1` sans pause :
`status` a montré `production : eleyone-site:v1.0.0`, puis `production : eleyone-site:v1.0.1`, le
conteneur `site-site-1` étant recréé à chaque fois. Le site n'a pas pu être regardé pendant que
`v1.0.0` servait : la preuve « le site sert la version précédente » ne reposait que sur `status`.

**Second passage, pour la preuve directe** (option proposée et retenue) :

1. `rollback v1.0.0` (Arnaud).
2. Orchestrateur, à 06:09 UTC : `https://eleyone.fr/`, `/en/` et `/cas/orange-crv-performance/`
   répondent `200`, **sans** `<meta name="description">` ni balise Open Graph — la marque de `v1.0.0`.
3. `rollback v1.0.1` (Arnaud).
4. Orchestrateur : les trois mêmes pages répondent `200`, avec **une** meta description et **six**
   balises Open Graph — `v1.0.1` est de nouveau servie.

**Images de production** : `docker images eleyone-site` (compte d'administration) — `v1.0.1` et
`v1.0.0`, soit **deux** images `vX.Y.Z` : au plus trois, comme le demande la case.

| Critère | Preuve |
|---|---|
| `rollback` sur le tag précédent : `status` le montre, le site sert la version précédente | `status` (`v1.0.0`) et pages sans meta description, étape 2 |
| Le dernier tag est redéployé | `rollback v1.0.1`, `status` (`v1.0.1`) et pages avec meta description, étape 4 |
| Au plus trois images de production | deux |

## Revue du code

**Revue du code** : exception documentaire — la PR n° 143 ne touche que `_bmad-output/` (`workflow.config`, `review.exempt-paths`) ; seule la CI verte est exigée.
