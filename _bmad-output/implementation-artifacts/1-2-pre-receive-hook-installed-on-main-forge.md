# Story 1.2 : Pre-receive hook installed on main forge

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 1.2, réécrite après la revue de spec ci-dessous.

## Revue de spec

### 15/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `d6347dc`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0b6a8c86ad9e53fc78a3c226

Ce document est une spécification comportementale (story) définissant les critères d'implémentation et de test du hook `pre-receive` sur le serveur Gitea pour interdire l'envoi de contenu privé.

##### 🔍 Lentille : Adversarial (Recherche de failles et cas limites)

| Emplacement | Condition de déclenchement (Problème) | Garde-fou suggéré (Correction) | Conséquence potentielle |
| :--- | :--- | :--- | :--- |
| L13 (Opération manuelle) | Le développeur doit préparer le fichier `check-private`, mais la spec ne dit pas où le stocker. S'il ne doit commiter "aucun chemin serveur", où place-t-il ce code de préparation ? | Définir un emplacement dans le dépôt pour le template du hook (ex: `deploy/hooks/pre-receive.template`). | Le développeur est bloqué ou invente un emplacement hors-standard. |
| L13 (Opération manuelle) | La liste des motifs doit avoir les droits `0600`. Si elle est créée par `root`, l'utilisateur `git` (qui exécute le hook dans Gitea) ne pourra pas la lire. | Préciser que la liste doit appartenir à l'utilisateur `git` du conteneur Gitea (ou `0640` avec le bon groupe). | Le hook échoue systématiquement sur un *Permission denied*, bloquant tous les pushs légitimes. |
| L17-20 (Critères) | `DISABLE_GIT_HOOKS` de Gitea empêche l'édition des hooks via l'interface web, mais le script part du principe que les hooks système s'exécutent toujours. | Expliciter que le test vise justement à valider que les scripts placés manuellement dans `hooks/pre-receive.d/` côté serveur s'exécutent malgré cette restriction. | Confusion sur le but du test, ou risque que Gitea bloque effectivement l'exécution silencieusement. |
| L20 (Critères) | "puis lance le script en mode `pre-receive`". L'expression est ambiguë : est-ce que le hook Gitea réimplémente la logique ou source-t-il un autre fichier ? | Préciser que le hook `check-private` de Gitea n'est qu'un court *wrapper* qui exécute `scripts/check-private.sh pre-receive` (ou clarifier son rôle précis). | Duplication de code critique dans un hook serveur non versionné directement. |
| L23 (Critères) | Le test cible uniquement `docs/private/`. Qu'en est-il de `.env`, `docs/context/` et `assets/cv/*.pdf` (qui sont également des chemins interdits selon AD-12) ? | Étendre les critères d'acceptation pour vérifier qu'un ajout/modification sur `.env` ou sur un PDF est tout aussi bien refusé. | Régression potentielle sur les autres chemins critiques qui ne seraient pas explicitement testés. |
| L29 (Critères) | "fermé en cas de doute". L'expression "fermé" n'a pas de sens technique standard pour un hook (qui accepte ou rejette avec un code d'erreur). | Remplacer par "rejeté par mesure de sécurité (approche *fail-closed*)". | Ambiguïté d'implémentation sur ce que signifie "fermer" un push. |
| L31-33 (Critères) | "le passage par le hook est constaté et noté". Comment prouver cela lors d'un merge UI si l'on ne peut pas aller lire les logs du serveur ? | Indiquer que la preuve doit s'appuyer sur la retransmission d'un message d'information `echo` intercepté par Gitea lors du merge, ou tracée explicitement dans `.memlog.md`. | Test invérifiable de manière asynchrone ; dépend de la mémoire de l'opérateur. |
| L36 (Check-list) | "Le dépôt privé imbriqué n'a pas ce hook". Ce dépôt se trouve dans `docs/private/`, qui est exclu de git. | Préciser la commande manuelle qu'Arnaud doit exécuter pour vérifier `.git/hooks/` dans ce sous-répertoire isolé. | Le dépôt privé devient inutilisable si le hook y est déployé par inadvertance. |
| L37 (Check-list) | "survivent à sa recréation". Si la configuration de persistance du conteneur Gitea n'est pas exhaustive, les hooks peuvent disparaître. | Confirmer que le point de montage Docker existant de Gitea couvre bien le répertoire des hooks personnalisés. | Perte silencieuse de la sécurité lors d'une mise à jour ou recréation de l'image Gitea. |
| L38 (Check-list) | Le script tourne sous Alpine. Si le binaire `grep` (BusyBox) natif ne supporte pas un drapeau (ex: `-I`), le hook plantera. | S'assurer que le développeur vérifie la syntaxe POSIX ou valide la présence de GNU grep dans le Gitea cible (comme fait en AD-1 pour les outils de dev). | Le hook échoue en production sur chaque push à cause d'une erreur de commande introuvable ou de syntaxe. |

##### 📐 Lentille : Structure (Cohérence et efficacité)

**Modèle choisi** : Spécification comportementale (Given/When/Then). 
Le document est bien structuré mais contient quelques redondances.

| Pass | Texte original | Texte révisé | Changements |
| :--- | :--- | :--- | :--- |
| structure | L27-29: "Étant donné la liste temporairement inaccessible... Alors le push est refusé..." | **MERGE** avec L17-20 ("échoue si la liste est absente") | Véritable doublon conceptuel. Unifier les scénarios "liste absente", "liste vide" et "liste inaccessible" en une seule règle consolidée *fail-closed*. (Gain de concision). |
| structure | L40-42: "Le contenu du fichier `check-private` est-il versionné dans le dépôt, et où ?" | **MOVE** vers la section *Opération manuelle (Arnaud)* (L13). | Une spec ne devrait pas déléguer une décision architecturale aussi basique. La réponse à cette question doit être fixée directement dans les consignes du développeur. |

**Résumé de la structure** : La spec est dense et orientée vers l'action. 2 recommandations (1 MERGE, 1 MOVE). L'application de ces recommandations réduira l'ambiguïté pour le développeur. 

##### ✍️ Lentille : Prose (Clarté et précision de la rédaction)

| Pass | Texte original | Texte révisé | Changements |
| :--- | :--- | :--- | :--- |
| prose | L17: "Étant donné `DISABLE_GIT_HOOKS` laissé à `true`" | "Étant donné que la variable `DISABLE_GIT_HOOKS` est définie à `true`" | Plus lisible et explicite sur le fait qu'il s'agit d'une variable de configuration Gitea. |
| prose | L20: "puis lance le script en mode `pre-receive`." | "et qu'il invoque le script `scripts/check-private.sh` en mode `pre-receive`." | Désambiguïsation (il est important de préciser *lequel* script est lancé pour éviter la réimplémentation). |
| prose | L29: "Alors le push est refusé (fermé en cas de doute)." | "Alors le push est rejeté avec un code non nul (approche sécurisée par défaut)." | Utilisation de la terminologie Git exacte ("rejeté" plutôt que "fermé"). |

---

##### À trancher avant d'implémenter

*   **Emplacement du template du hook** : Où le développeur doit-il concrètement créer/versionner le fichier `check-private` (ex: `deploy/hooks/`) sans enfreindre la règle sur les chemins serveur ?
*   **Preuve de passage du hook** : Comment et où l'agent développeur doit-il consigner le résultat du test L31-33 (ex: capture dans `.memlog.md`, trace dans un commentaire de la PR) sans divulguer d'informations serveur ?
*   **Permissions de la liste** : Confirmer explicitement que les droits `0600` de la liste des motifs (L13) appartiendront bien à l'utilisateur `git` du conteneur (pour éviter le rejet par `Permission denied`).
*   **Compatibilité `grep`** : Confirmer que le conteneur Gitea de production embarque bien la version GNU de `grep` requise par les drapeaux du script, ou si le développeur doit impérativement adapter le script pour BusyBox.

Essais préalables de l'auteur, le 15/09/2026, dans les images officielles de Gitea tirées sur le poste (aucun accès au serveur) :

- `gitea/gitea:1.27.3` (Alpine 3.24.1) : `bash` 5.3.9, `git` 2.54.0, `grep` de BusyBox, pas de `jq` ; les 16 cas de `scripts/tests/test-check-private.sh`, dont les 8 cas `pre-receive` sur un dépôt nu muni d'un vrai hook, réussissent dans cette image ;
- `GITEA_CUSTOM` vaut `/data/gitea` dans l'image normale et `/var/lib/gitea/custom` dans l'image rootless ; les deux font tourner Gitea sous l'utilisateur `git` (UID 1000) ;
- version en service lue par l'API de la forge : 1.27.3 ; variante de l'image indiquée par Arnaud : normale.

Tri de l'auteur (questions tranchées par Arnaud le 15/09/2026) :

- emplacement du script du hook : tranché, `scripts/gitea/pre-receive-check-private`, testé dans `scripts/tests/`, qui trouve script et liste sous `$GITEA_CUSTOM/eleyone-check-private/` ; procédure `docs/procedures/gitea-pre-receive-hook.md` ;
- propriétaire et droits de la liste : corrigé, propriétaire `git`, liste en `0600`, sans quoi le hook refuserait tout push ;
- rôle de `DISABLE_GIT_HOOKS` : corrigé, il ne ferme que l'édition des hooks par l'interface ; les pushs constatent que le hook posé à la main s'exécute ;
- hook sans reprise de la logique du garde-fou : corrigé, script d'appel court qui lance `check-private.sh pre-receive` ;
- essais limités à `docs/private/` : corrigé, étendus à `docs/context/`, `.env`, un PDF sous `assets/cv/` et un push propre admis ;
- « fermé en cas de doute » : corrigé, « refusé, par sécurité » ; scénarios « liste absente » et « liste inaccessible » regroupés ;
- preuve du passage par le hook lors d'une fusion depuis l'interface : tranché, motif factice présent dans une branche déjà poussée puis ajouté à la liste, fusion refusée attendue ;
- dépôt privé imbriqué : corrigé, le hook n'est posé que dans le dépôt nu du site ;
- survie à la recréation du conteneur : corrigé, script, liste et hook dans le volume de données de Gitea, essai après recréation ;
- `grep` de BusyBox : écarté, essais réussis dans l'image `gitea/gitea:1.27.3`, à constater sur la forge ;
- qui pousse : tranché, l'agent, depuis un clone jetable hors du dépôt de travail, hook local désactivé dans ce seul clone, contenu factice, branches jetables supprimées ensuite ;
- consignation des résultats : tranché, dans ce fichier, sans nom d'hôte ni chemin de la machine hôte ;
- structure (déplacement de la question d'emplacement) et rédaction (trois reformulations) : corrigé à la réécriture.

## Essais sur la forge

15 et 16/09/2026, Gitea 1.27.3, image Docker normale, `DISABLE_GIT_HOOKS` inchangé. Aucun nom d'hôte, chemin de la machine hôte ni nom de dépôt privé n'est noté ici.

Installation, faite par un agent du homelab d'Arnaud selon `docs/procedures/gitea-pre-receive-hook.md` :

- étape 1 conforme (`GITEA_CUSTOM=/data/gitea`, utilisateur `git`, `bash`, dépôt nu du site, commit `0d93a7e` présent) ;
- liste des motifs extraite du dépôt nu privé dans le conteneur (option A, aucune copie sur la machine hôte), jamais affichée ; script du garde-fou et script du hook extraits du dépôt nu du site au commit `0d93a7e`, empreintes sha256 identiques à celles du dépôt ;
- droits constatés : `check-private.sh` et `forbidden-patterns.txt` en `-rw-------`, propriétaire `git` ; `check-private` en `-rwxr-xr-x`, à côté du hook `gitea` ;
- un seul dépôt nu porte `check-private` : le dépôt privé n'a pas ce hook ;
- remarque de l'agent du homelab, retenue dans la procédure : poser le hook avant la liste aurait refusé tous les pushs ; le hook est donc déposé non exécutable et activé par `chmod 0755` en dernier.

Essais, pushs faits par l'agent de développement depuis un clone jetable hors du dépôt de travail (hook local désactivé dans ce seul clone), branches jetables `essai/garde-fou-*` :

| Essai | Opération | Résultat |
|---|---|---|
| 3 | push d'un fichier public | admis (le hook reçoit bien `GITEA_CUSTOM`) ; branche supprimée |
| 1 | push d'un fichier sous `docs/private/` | refusé, commit et chemin nommés ; branche non créée |
| 1 | push d'un fichier sous `docs/context/` | refusé, commit et chemin nommés ; branche non créée |
| 1 | push d'un `.env` | refusé, commit et chemin nommés ; branche non créée |
| 1 | push d'un PDF sous `assets/cv/` | refusé, commit et chemin nommés ; branche non créée |
| 2 | ligne factice aléatoire ajoutée à la copie serveur de la liste (vérifiée sans recouper aucun motif réel), puis push d'un fichier qui la contient | refusé ; la ligne n'apparaît pas dans les messages ; ligne retirée ensuite (liste revenue à sa taille d'origine) |
| 5 | PR n° 16 entre deux branches jetables (jamais `dev`), contenant la ligne factice ; fusion tentée depuis l'interface par Arnaud | refusée : « la soumission a été rejetée », message du garde-fou avec commit, chemin et numéro de ligne du motif, sans le motif ; PR fermée sans fusion |
| 7 | réglages du dépôt dans l'interface | aucune page d'édition des hooks |
| 4 | liste renommée temporairement, puis push d'un fichier public | refusé : « liste des motifs absente ou illisible : push refusé » ; branche non créée |
| 4 bis | liste rétablie, même push | admis |
| 6 | conteneur Gitea entièrement recréé (même image), fichiers constatés intacts (tailles, droits, dates), puis push d'un fichier sous `docs/private/` | refusé, commit et chemin nommés |

Nettoyage : PR n° 16 fermée, toutes les branches `essai/garde-fou-*` supprimées de la forge, clone jetable supprimé.

### Redéploiement après la story 1.5 (16/09/2026)

Le hook exécute sa propre copie du script : la story 1.5 l'a étendu, la copie du serveur a donc été remplacée par l'agent du homelab, selon « Entretenir ». Gitea 1.27.3, image Docker normale.

- Copie du serveur remplacée au commit `d0fd28b` de `dev` : **sha256 identique** à celui du dépôt, `-rw-------`, propriétaire `git` ; hook `pre-receive.d/check-private` toujours en place et exécutable ; ancienne copie conservée le temps des essais.
- Liste des motifs **intacte et jamais ouverte** : même taille et même horodatage qu'avant l'opération.

| Essai | Opération | Résultat |
|---|---|---|
| 1 | push d'un fichier sous `docs/private/` | refusé, commit et chemin nommés |
| 1 | push d'un `.env.production` (variante ajoutée par la story 1.5) | refusé, commit et chemin nommés |
| 3 bis | motif dans le **message** d'un commit | refusé : « message de commit privé dans `<commit>` (message masqué) », puis un numéro de ligne de motif ; ni le motif ni le message affichés |
| 3 | push anodin | admis ; branche jetable supprimée ensuite |

**Trois écarts relevés par l'agent du homelab dans les consignes que je lui avais données, tous retenus** et écrits dans la procédure (`docs/procedures/gitea-pre-receive-hook.md`, section « Essayer ») :

1. les essais enchaînés sur une même branche laissent les commits interdits précédents dans la plage poussée : chaque essai repart de `dev` ;
2. `git add -A` ne fabrique pas le commit interdit, `.gitignore` couvrant déjà `docs/private/` et `.env` : il faut `git add -f` ;
3. **mes consignes demandaient un motif réel dans le message de commit**, alors que la procédure impose une ligne factice, jamais un motif réel. C'était une erreur de ma part : le miroir publie à chaque push, donc un hook qui aurait manqué son refus aurait rendu le motif public et accessible par son SHA. L'agent a limité le risque (vérification locale hors forge d'abord, essais 1 et 1 bis passés avant, clone et branche détruits ensuite) et le motif n'a jamais été accepté. La procédure décrit désormais l'essai de message avec une ligne factice, comme l'essai 2.

### Redéploiement après la story 5.4 (21/09/2026)

La story 5.4 a fait entrer C20 dans le hook : `check-private.sh` charge désormais `scripts/lib/image.sh`, et l'interdiction des extensions d'images est levée sous `assets/`. Trois fichiers copiés, dont le sous-dossier `lib/` pour la première fois. Gitea 1.27.3, image Docker normale.

Consigné après coup, le 22/09/2026, à partir du compte rendu de l'agent du homelab transmis par Arnaud : les empreintes et l'essai 1 sont attestés, le détail des autres essais ne l'est pas et n'est donc pas reproduit ici.

- Copie du serveur remplacée au commit `600e9e5`, tête de `dev` : les **trois empreintes sha256** (garde-fou, `lib/image.sh`, lanceur) identiques à celles du dépôt.
- Droits finaux conformes à la procédure ; un seul dépôt nu porte `check-private`.
- Essai 1 (`docs/private/`) : refusé, commit et chemin nommés.

### Redéploiement après la rétrospective de l'epic 5 (22/09/2026)

Les trois actions bloquantes de la rétrospective (PR n° 74) et la factorisation de la liste d'extensions (PR n° 75) ont modifié `check-private.sh` et `lib/image.sh` ; le lanceur, inchangé, n'a pas été réextrait, seulement vérifié. Gitea 1.27.3, image Docker normale.

**Ce que ce redéploiement fermait.** Le garde-fou listait les chemins avec les réglages git par défaut, qui citent et échappent en octal tout chemin non-ASCII : une image nommée `café.webp` était listée `"assets/images/caf\303\251.webp"`, les motifs de chemin ne collaient plus, et l'image **n'était même pas sélectionnée pour C20** — elle passait avec ses métadonnées. Tant que la copie du serveur n'était pas remplacée, le trou restait ouvert du côté qui fait autorité, puisque le miroir public pousse depuis la forge.

- Copie du serveur remplacée au commit `34138c3` : trois empreintes sha256 identiques à celles du dépôt, y compris celle du lanceur non réextrait.
- Liste des motifs **non réextraite et jamais ouverte** : elle n'avait pas changé.

| Essai | Opération | Résultat |
|---|---|---|
| 1 | push d'un fichier sous `docs/private/`, sous `docs/context/`, d'un `.env`, d'un PDF sous `assets/cv/` | refusé à chaque fois, commit et chemin nommés |
| 3 ter | fichier anodin dans un dossier nommé d'après la ligne factice | refusé : « chemin qui reprend un motif dans `<commit>` (chemin masqué) », puis un numéro de ligne de motif ; ni le motif ni le chemin affichés |
| C20-a | image porteuse de métadonnées sous `assets/`, nom ASCII | refusé : « C20 : métadonnées dans une image de `<commit>` : `assets/images/simple.webp` (Exif VP8X) » |
| C20-b | **la même image sous un nom non-ASCII** | refusé, même message, chemin affiché en clair (`café été.webp`, pas `caf\303\251`) |
| C20-b | rejoué après le `chmod 0700` sur `lib/` | refusé à l'identique : le garde-fou charge encore `image.sh` à travers le dossier resserré |

C20-a et C20-b portent la **même charge utile** et ne diffèrent que par le nom du fichier : C20-a passait déjà avant le correctif et sert de témoin, C20-b est l'essai qui échouait. Témoin relevé par l'agent du homelab : `git show --stat`, dans son clone, affichait encore le chemin échappé — c'est donc bien le hook qui force `core.quotePath=false`, et non un hasard d'encodage.

Le rejeu de C20-b après le changement de droits n'était pas demandé : un `lib/` devenu illisible aurait fait échouer le hook d'une façon qui ressemble à un refus, et rien n'aurait distingué le contrôle de la panne.

**Deux défauts de la procédure, relevés à cette occasion, tous deux corrigés dans `docs/procedures/gitea-pre-receive-hook.md` :**

1. relevé par l'agent du homelab : `mkdir -p $D/lib && umask 077 && …` applique l'umask **après** le `mkdir`, donc `lib/` naissait en `0755` quand l'étape 4 annonçait `drwx------`. Rien n'était exposé — le parent est en `0700` et les fichiers en `0600` — mais l'attendu écrit était faux, et le défaut serait revenu à chaque installation neuve. La procédure pose désormais un `chmod 0700` explicite, et l'attendu du `ls -l` nomme `lib/`.
2. relevé à la lecture du compte rendu : la procédure disait de garder l'ancienne copie du script le temps des essais et **ne disait jamais de la supprimer ensuite**. Deux copies du 21/09 étaient encore là le 22. La procédure demande maintenant leur suppression une fois les essais verts, et sa mention dans le compte rendu.

**Un troisième point, qui n'appartenait à personne.** La ligne factice des essais 2, 3 bis, 3 ter et 5 est posée par Arnaud et retirée par Arnaud ; ni lui ni l'agent ne la voit dans son propre bilan, et elle est restée dans la liste du serveur après les essais. Inoffensive — un motif factice ne refuse que ce qu'on pousse exprès — mais la liste du serveur diverge alors de celle du dépôt privé, et cet écart ne se remarque qu'à la prochaine extraction. La section « Essayer » impose désormais que le compte rendu se termine par l'état de la liste, taille en octets à l'appui, et donne la commande qui retire la ligne sans l'afficher.

## Revue du code

### 16/09/2026 — `3d72ac0` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 17. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f4007b52eb9800af5e361141

#### Rapport de revue BMAD

##### Lentille : Edge-Case Hunter
Aucun cas limite non géré n'a été trouvé. Le script du hook gère correctement les variables d'environnement non définies (`GITEA_CUSTOM`) et l'absence ou l'illisibilité des fichiers requis.

##### Lentille : Verification-Gap
No verification gaps found.

#### Couche propre au projet

- NON BLOQUANT : les critères d'acceptation de la story sont satisfaits, sans que leur intention soit vidée (les comportements du hook sont couverts par les tests automatisés et documentés dans la story).
- NON BLOQUANT : aucune donnée privée, aucun nom d'hôte ni adresse de serveur, aucun secret n'est commité, et aucun script ne peut afficher un secret ou l'adresse de la forge (utilisation stricte de chemins relatifs et de la variable interne `GITEA_CUSTOM`).
- NON BLOQUANT : skill, procédure et script concordent : la procédure manuelle décrit les étapes nécessaires sur le serveur sans diverger du script du hook déployé.
- NON BLOQUANT : le changement est cohérent avec AGENTS.md et les décisions d'architecture (les mises à jour dans `ARCHITECTURE-SPINE.md` et `epics.md` s'alignent avec les principes édictés).
- NON BLOQUANT : dans les scripts shell, aucune erreur ne passe en silence sous set -euo pipefail (le script `pre-receive-check-private` vérifie explicitement les conditions avec `|| refuse` et l'exécution se fait via `exec`).

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur les revues du code de la PR n° 17 :

- `3d72ac0` (pass) : aucun constat, confirmations seulement.

Preuves sur la tête `3d72ac0` : `scripts/tests/run.sh`, 51 cas réussis sur le poste et dans `alpine:3.24` ; 24 cas du garde-fou et du hook réussis dans `gitea/gitea:1.27.3` sous l'utilisateur `git` ; essais 1 à 7 conformes sur la forge (section « Essais sur la forge »).

## Reporté

- Aucun constat reporté. Entretien du hook sur le serveur à chaque modification des scripts ou de la liste des motifs : section « Entretenir » de `docs/procedures/gitea-pre-receive-hook.md`.
