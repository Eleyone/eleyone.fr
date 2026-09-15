# Story 1.1 : Pre-receive guard fails without pattern list

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 1.1, réécrite après la revue de spec ci-dessous.

## Revue de spec

### 15/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `8c167a3`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 15ee174d8861790ba1a187a7

Voici le rapport de revue de la spécification de la story 1.1 (fichier `REVIEW-SPEC.md`), généré avec le skill `bmad-review` via les lentilles `adversarial`, `structure` et `prose`.

---

**Compréhension initiale** : Ce document existe pour définir les critères d'acceptation et les contraintes techniques de la story 1.1, afin de garantir qu'un hook `pre-receive` ne laisse jamais filtrer de données privées si sa liste de motifs n'est pas correctement configurée.

##### 🔍 Lentille : Adversarial (Recherche de failles et cas limites)

| Emplacement | Condition de déclenchement (Problème) | Garde-fou suggéré (Correction) | Conséquence potentielle |
| :--- | :--- | :--- | :--- |
| Critères d'acceptation (L17-20) | Le script `pre-receive` est exécuté sur un dépôt nu (serveur). La liste de motifs (`docs/private/forbidden-patterns.txt`) n'étant pas poussée, le script doit la trouver ailleurs. | Spécifier comment le script localise la liste en mode `pre-receive` (ex: via la variable `PRIVATE_PATTERNS_FILE` déjà mentionnée dans les procédures). | Le script chercherait un chemin local inexistant et échouerait systématiquement, bloquant tous les push légitimes. |
| Critères d'acceptation (L22-24) | Le script doit analyser le contenu des fichiers poussés dans un hook `pre-receive`. Un dépôt nu n'a pas d'arbre de travail. | Préciser que le script en mode `pre-receive` lit bien les blobs via `git grep` sur les révisions reçues sur l'entrée standard, et que les tests jetables doivent valider cette lecture sans arbre de travail. | La vérification des motifs pourrait planter ou ne rien vérifier car `git grep` sans arbre de travail nécessite des révisions spécifiques. |
| Critères d'acceptation (L17-20) | Le comportement face à un fichier de motifs présent mais vide (ou ne contenant que des commentaires) n'est défini que comme une question (L36). | Convertir la question 36 en un critère explicite : un fichier vide ou ne contenant que des commentaires est considéré comme absent et déclenche le refus. | Un hook serveur configuré avec un fichier vide par erreur désactiverait silencieusement la protection des motifs. |
| Critères d'acceptation (L26-28) | Les modes `staged` et `history` maintiennent un avertissement et se replient sur les chemins si la liste est absente. Que se passe-t-il si elle est vide ? | Ajouter que pour `staged` et `history`, un fichier de motifs vide déclenche le même comportement (avertissement + repli) qu'une liste absente. | Les CI passeraient au vert malgré un fichier de motifs vidé par erreur, sans le moindre avertissement. |
| Check-list (L30) | La check-list indique que `.env` et `assets/cv/*.pdf` sont déjà bloqués dans le script. L'AD-12 stipule que `docs/private/` et `docs/context/` le sont aussi, mais la story ne l'affirme pas clairement. | Modifier pour clarifier que tous les chemins statiques (incluant `docs/private/` et `docs/context/`) sont déjà bloqués, et qu'il n'y a qu'à le constater. | Le développeur pourrait tenter de réimplémenter inutilement le blocage de ces chemins, risquant des régressions. |
| Check-list (L31) | "Un fichier public qui nomme `docs/private/` n'est pas refusé". Un fichier légitime nommé `mon-docs-private.md` échappera-t-il bien à l'interdiction de chemin ? | S'assurer que le contrôle des chemins correspond exactement aux répertoires interdits (ex: ancrage avec `/` final) pour éviter les faux positifs. | Le push d'un fichier légitime dont le nom inclut la chaîne "docs/private" serait refusé à tort. |
| Check-list (L32) | Exécution dans `CHECK_IMAGE` (Alpine). Le serveur Gitea tourne potentiellement sur un hôte différent (Debian/Ubuntu). | S'assurer que le script s'appuie sur un standard POSIX sans dépendre d'options GNU exclusives (sauf `grep` GNU installé explicitement selon AD-1) fonctionnant de façon identique sur Alpine et sur l'hôte Gitea. | Le hook pourrait réussir en CI (Alpine) mais échouer en production lors d'un push, cassant le déploiement. |
| Critères d'acceptation (L18-19) | Le code de sortie non nul arrête le hook. Le message doit être visible par l'auteur du push. | Préciser que le message d'erreur doit être envoyé sur la sortie d'erreur standard (`stderr`) ou formaté de manière à être retransmis par git au client. | Le client git recevrait une erreur générique sans comprendre que le problème vient du fichier de motifs manquant. |
| Général | Contournement du contrôle par un renommage de fichier. | Valider dans les critères que le hook intercepte bien les renommages de fichiers (qui n'introduisent pas de nouveau blob, mais créent un nouveau chemin dans l'arbre). | Un renommage déplaçant un fichier dans un dossier interdit passerait inaperçu. |
| Général | La vérification des fichiers PDF et des images par le hook n'est pas mentionnée explicitement pour l'absence de motif. | Les PDF/Images sont bloqués par chemin (`assets/cv/*.pdf`) selon l'AD-12 (qui indique "ce dernier tant que le hook ne lit pas les PDF"). La spec de la story devrait refléter que le script ne cherche pas (ou ne plante pas) en tentant d'appliquer `git grep` sur des binaires. | Le script pourrait planter lamentablement sur le serveur s'il tente d'appliquer la liste de motifs à un flux binaire mal géré. |

##### 📐 Lentille : Structure (Cohérence et efficacité)

**Modèle choisi** : Spécification comportementale (Given/When/Then).

| Pass | Texte original | Texte révisé | Changements |
| :--- | :--- | :--- | :--- |
| structure | L30: "Les chemins `.env` et `assets/cv/*.pdf` figurent déjà dans le script : à constater, pas à réécrire." | **CONDENSER / MERGE** avec le critère précédent. "Tous les chemins interdits (incluant `docs/private/` et `docs/context/` listés au critère précédent) figurent déjà dans le script." | Supprime l'ambiguïté sur le statut actuel de `docs/private/` et `docs/context/` vis-à-vis de l'existant. |
| structure | L37: "Test automatisé versionné sous `tests/`, ou démonstration dans des dépôts jetables ?" | **QUESTION** | À remonter dans les points à trancher absolument. Une spec ne doit pas laisser le type de livrable de test au hasard. |

**Résumé de la structure** : 2 recommandations. Le document est très concis et va à l'essentiel. L'application des recommandations lève une contradiction possible entre les critères et la check-list concernant l'état actuel du code.

##### ✍️ Lentille : Prose (Clarté et précision de la rédaction)

| Pass | Texte original | Texte révisé | Changements |
| :--- | :--- | :--- | :--- |
| prose | L19: "le script sort avec un code non nul et un message qui signale l'absence de la liste" | "le script sort avec un code non nul et émet un message d'erreur signalant l'absence de la liste" | Précision sur l'émission active du message, qui doit être visible par git. |
| prose | L23: "Quand un push introduit un fichier sous `docs/private/` ou `docs/context/`..." | "Quand un push tente d'ajouter un fichier sous..." | Remplace "introduit" par "tente d'ajouter" pour mieux exprimer que l'action est interceptée avant son succès. |
| prose | L26: "Étant donné les modes `staged` et `history`" | "Étant donné l'exécution du script dans ses modes `staged` ou `history`" | Formule plus naturelle et complète pour la compréhension du contexte. |

---

##### À trancher avant d'implémenter

*   **Gestion des listes de motifs vides** : Une liste existante mais vide (ou contenant uniquement des commentaires) doit-elle déclencher le refus systématique en mode `pre-receive`, et le repli avec avertissement pour les autres modes ? (Lève l'ambiguïté de la question 36).
*   **Stratégie de test** : Le développeur doit-il livrer des tests automatisés bash sous `tests/` ou réaliser une démonstration manuelle dans un dépôt jetable lors de la PR ? (Réponse à la question 38).
*   **Emplacement de la liste sur le serveur nu** : Étant donné que `docs/private` ne sera jamais poussé sur le Gitea, comment le hook `pre-receive` est-il censé résoudre le chemin vers la liste de motifs locale au serveur ? (Utilisation explicite de `PRIVATE_PATTERNS_FILE` ?).
*   **Statut actuel du code** : Confirmer que `docs/private/` et `docs/context/` sont *déjà* filtrés par le script (au même titre que `.env`), pour éviter que le développeur croie devoir implémenter leur blocage.

Première tentative de revue, le même jour : échec du script en 59 s (« le rapport ne cite pas le jeton de lecture »), rien d'écrit ni de publié ; relancée selon la procédure, la revue ci-dessus a abouti.

Tri de l'auteur (questions tranchées par Arnaud le 15/09/2026) :

- emplacement de la liste des motifs sur le dépôt nu : tranché, `PRIVATE_PATTERNS_FILE` obligatoire en mode `pre-receive`, refus avec un message qui la nomme ; le hook de la story 1.2 la définit (procédure « hook pre-receive », étape 2) ;
- lecture sans arbre de travail : corrigé dans la story, constat sans code à écrire : le mode `pre-receive` lit les commits reçus par `git ls-tree` et `git grep <commit>`, ce que les tests prouvent sur un dépôt nu ;
- liste présente mais vide : tranché, refusée comme une liste absente en `pre-receive` ; `staged` et `history` gardent le repli annoncé de la story 0.8 ;
- chemins `docs/private/` et `docs/context/` déjà interdits : corrigé dans la formulation, tous les chemins interdits sont à constater (`check-private.sh:16`) ;
- faux positif sur un nom proche (`mon-docs-private.md`) : écarté, l'expression est ancrée (`^docs/(private|context)/`) ; cas ajouté aux tests ;
- portabilité sur l'hôte de Gitea : reporté à la story 1.2, qui constate le fonctionnement avec les outils de l'image de Gitea (case ajoutée) ; la story 1.1 garantit `CHECK_IMAGE` ;
- message visible par l'auteur du push : constat, le script écrit sur la sortie d'erreur, que git retransmet ; les tests le vérifient à travers un vrai push ;
- renommage vers un chemin interdit : constat, le script liste tout l'arbre de chaque commit reçu ; cas ajouté aux tests ;
- fichiers binaires : écarté, `git grep -I` les ignore et les PDF restent interdits par leur chemin (AD-21) ;
- stratégie de test : tranché, cas de `scripts/tests/test-check-private.sh` sur un dépôt nu jetable muni d'un vrai hook `pre-receive` ;
- structure (fusion de la case des chemins, questions remontées) et rédaction (trois reformulations) : corrigé à la réécriture.

## Revue du code

### 15/09/2026 — `0db366e` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 15. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: a0cf245969bcf0999d69f08f

##### Revue BMAD

**Contenu :** Diff (PR n° 15, `REVIEW-DIFF.patch`).
**Lentilles exécutées :** `edge-case-hunter`, `verification-gap`.

**Lentille : Edge-case-hunter**
Aucun cas limite non géré n'a été trouvé. Le script gère tous les états possibles pour la variable `PRIVATE_PATTERNS_FILE` et le contenu du fichier de motifs (absente, vide, ou fichier inexistant).

**Lentille : Verification-gap**
No verification gaps found.

##### Revue spécifique au projet

* NON BLOQUANT : Les critères d'acceptation de la story sont parfaitement satisfaits. Les conditions de refus (`PRIVATE_PATTERNS_FILE` manquante, fichier absent, fichier vide de motifs) pour le hook `pre-receive` sont respectées et testées.
* NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge.
* NON BLOQUANT : Skill, procédure et script concordent. Les ajouts sur le comportement de `pre-receive` sont documentés à l'identique dans le skill, la procédure et reflétés dans l'implémentation.
* NON BLOQUANT : Le changement est cohérent avec `AGENTS.md` et les décisions d'architecture (la modification est actée dans `ARCHITECTURE-SPINE.md` en AD-12).
* NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. Les variables potentiellement non définies sont gérées via `:-` et les conditions ou sous-shells sont sûrs.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur les revues du code de la PR n° 15 :

- `0db366e` (pass) : aucun constat, confirmations seulement.

Preuves : les trois cas « sans liste » (variable absente, liste absente, liste sans motif) échouent sur l'ancien script, push admis, puis réussissent avec le correctif ; `scripts/tests/run.sh` réussit sur la tête `0db366e`, 43 cas sur le poste et 43 cas dans `alpine:3.24` ; les tests n'emploient qu'un motif factice.

## Reporté

- Fonctionnement du script avec les outils de l'image de Gitea (dont un `grep` qui peut ne pas être celui de GNU) : story 1.2, case ajoutée après la revue de spec.
