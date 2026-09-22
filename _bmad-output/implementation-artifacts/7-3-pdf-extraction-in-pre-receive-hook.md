# Story 7.3 : PDF extraction in pre-receive hook

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 7.3.

## Revue de spec

### 22/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `870145f`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 986d9344e43984722deaeb4c

*Note : L'outil `view_file` ne permet pas de lister les répertoires et l'exécution de commandes shell (comme `ls`) m'est formellement interdite par la consigne. Je n'ai donc pas listé l'arborescence, mais j'ai lu directement le fichier `REVIEW-SPEC.md` et les documents de contexte.*

##### Rapport de revue (bmad-review)

**Classe de contenu :** `docs` (spécification de story)
**Lentilles appliquées :** adverse, structure, prose

###### Lentille : Adverse (Adversarial Critique)

* **BLOQUANT** : Fichier temporaire non nettoyé. La spécification indique « `git cat-file` vers un fichier temporaire » sans exiger sa suppression. Sans nettoyage explicite (par exemple via `trap` ou `rm`), chaque push d'un PDF laissera des données potentiellement privées sur le serveur et finira par saturer son disque, ce qui constitue une fuite de données et un risque d'infrastructure.
* **BLOQUANT** : Fuite potentielle par les métadonnées. L'exigence FR-38 impose le « contrôle du texte et des métadonnées ». Le critère d'acceptation 1 s'assure que `pdfinfo` est disponible, mais aucun critère ne vérifie que le hook l'utilise effectivement pour lire les métadonnées du PDF et y chercher les motifs interdits. Une donnée privée pourrait fuiter en silence par ce biais.
* **BLOQUANT** : Autorisation de chemins trop large. Le critère 3 demande de retirer `assets/cv/*.pdf` des chemins interdits. AD-21 est plus restrictif et fixe les noms exacts (`assets/cv/cv-{fr,en}.pdf`). Lever l'interdiction sur tout `*.pdf` risque d'autoriser l'entrée de documents non prévus.
* **BLOQUANT** : Implémentation fantôme de `pdf.sh`. Le critère 2 mentionne « lance `pdf.sh` » mais ne précise pas si ce script existe déjà, où il doit être placé (ex. `scripts/lib/pdf.sh`), ni s'il doit être créé dans cette story. Sans cette précision, le comportement est invérifiable et contredit le principe de spécification claire de l'architecture.

###### Lentille : Structure

* **BLOQUANT** : Incohérence chronologique des critères d'acceptation. Le critère 2 stipule que « le push est refusé » par le hook côté serveur, mais c'est seulement au critère 3 que « le script est recopié sur le serveur ». Il est logiquement impossible de vérifier le refus serveur au critère 2 si le nouveau hook n'est déployé qu'au critère 3.
* **NON BLOQUANT** : Le bloc « Opération manuelle (Arnaud) » mélange l'action attendue du mainteneur (construire et déployer l'image) et la tâche du développeur (préparer la modification et la liste de vérification), ce qui dilue la répartition des rôles.

###### Lentille : Prose

* **NON BLOQUANT** : L'expression « Étant donné le test précédent réussi » gagnerait en clarté rédactionnelle si elle était formulée « Étant donné que le test précédent a réussi ».
* **NON BLOQUANT** : La phrase listant les opérations manuelles (« construire une image dérivée... la faire tourner à la place de l'officielle, et la reconstruire à chaque montée de version ; recopier le hook mis à jour ») est très dense. Elle mériterait d'être scindée en liste à puces pour fluidifier son exécution.

##### À trancher avant d'implémenter

- Le nettoyage du fichier temporaire créé par `git cat-file` doit-il faire l'objet d'une consigne explicite (ex. `trap`) pour prévenir toute fuite et saturation ?
- L'analyse des métadonnées via `pdfinfo` doit-il être précisée dans la spécification pour garantir la couverture totale de FR-38 ?
- Doit-on restreindre le retrait des chemins interdits aux seuls `cv-fr.pdf` et `cv-en.pdf` (selon AD-21) plutôt qu'à la règle générique `*.pdf` ?
- Où se trouve ou doit être créé le script `pdf.sh` mentionné, et quel sera son emplacement exact ?
- Faut-il réordonner les critères d'acceptation 2 et 3, ou scinder le déploiement du hook, pour que le test de refus sur le serveur (critère 2) soit testable logiquement ?

### Tri de l'auteur (22/09/2026)

Cinq constats bloquants : quatre retenus, un refusé.

**Retenu — le fichier temporaire.** La spec disait « `git cat-file` vers un fichier temporaire » sans dire qu'il fallait le supprimer. Un PDF extrait qui survit sur la forge est une fuite, et le disque finirait par saturer. Le nettoyage est posé **à la sortie du script**, pas au retour de la fonction, et couvre donc aussi un arrêt en chemin.

C'est exactement la leçon de la story 7.1, où un `exec` avait annulé un `trap` : j'y ai repensé en écrivant, et j'ai quand même posé un `trap … RETURN`. **Il était faux** — un `trap RETURN` posé dans une fonction se déclenche au retour de la *suivante*, et le nettoyage échouait sur une variable hors de portée. Constaté en éprouvant le garde-fou sur un vrai dépôt, pas en relisant.

**Retenu — les métadonnées.** Le critère ne vérifiait que la présence des outils. La story exige désormais que le PDF d'essai porte son motif **dans les métadonnées** : c'est là qu'un téléphone se cache dans un export, et c'est la moitié de FR-38 qu'une lecture du seul texte manquerait. Le cas de test du hook et l'essai de la procédure le font tous deux.

**Retenu, et c'est le plus important — l'interdiction trop large.** La story disait de retirer `assets/cv/*.pdf` des chemins interdits. AD-21 ne connaît que deux fichiers. La levée ne porte donc que sur **`cv-fr.pdf` et `cv-en.pdf`**, nommés ; tout autre PDF à cet endroit reste refusé, et un cas de test le garde. Ce que le hook ne sait pas nommer, il le refuse.

**Retenu — l'ordre des critères était impossible.** Le critère 2 éprouvait le refus côté serveur, le critère 3 déployait le script. Or tant que le chemin est interdit, un PDF poussé est refusé **pour son chemin** et l'essai ne prouve rien de la lecture. La séquence est donc inversée : le garde-fou modifié **et** l'interdiction levée partent ensemble, puis l'essai a lieu. Il est sûr parce que le PDF est fabriqué et le motif factice — si le refus manquait, ce qui serait publié n'est rien. Le retour arrière est écrit dans la procédure.

**Refusé, parce que déjà vrai — `pdf.sh` fantôme.** Le relecteur demande où ce script doit être créé. `scripts/checks/pdf.sh` existe depuis la story 7.1, fusionnée. La story le nomme désormais par son chemin. Ce qui manquait vraiment, et que le constat a fait trouver : la **lecture** d'un PDF vit maintenant dans `scripts/lib/pdf.sh`, chargée par le contrôle **et** par le garde-fou — même dessin que `lib/image.sh` pour C20, et un fichier de plus à recopier sur la forge.

## Revue du code

### 22/09/2026 — `0e9fe0d` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 86. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: bce815e588f7e74b2d6e64e1

##### Revue bmad-review et projet

**Lentille : edge-case-hunter**
* BLOQUANT : Dans `scripts/check-private.sh`, la fonction `check_pdfs` assigne un nouveau `mktemp` à la variable globale `pdf_blob` à chaque appel (par exemple pour chaque commit vérifié dans la boucle du hook). Le `trap nettoyer EXIT` ne nettoiera que le dernier fichier assigné, laissant tous les fichiers temporaires précédents s'accumuler sur le serveur, créant une fuite de données privées potentielles et une saturation du disque.

**Lentille : verification-gap**
* NON BLOQUANT : Le script `scripts/tests/test-gitea-hook.sh` ne teste les vérifications de CV que sur le push d'un unique commit à la fois. Ce manque de couverture sur des pushs de multiples commits empêche de détecter le bug de fuite des fichiers temporaires décrit ci-dessus, car le trap fonctionne correctement s'il n'y a qu'un seul appel.

**Couche propre au projet**
* BLOQUANT : Le critère d'acceptation spécifiant "Quand le fichier temporaire a servi / Alors il est supprimé" n'est pas rempli. En cas de commits multiples contenant des PDF, le fichier n'est pas supprimé après avoir servi, ce qui vide l'intention du critère (empêcher la saturation et la fuite).
* NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur et aucun secret n'est commité ; de plus, aucun script ne peut afficher un secret ou l'adresse de la forge.
* NON BLOQUANT : Skill, procédure et script concordent parfaitement. La procédure décrit bien l'installation de la nouvelle librairie `lib/pdf.sh` et les prérequis de dépendances de l'image, ce qui est strictement en accord avec les vérifications du hook.
* NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture, puisque l'interdiction de chemin n'est levée que pour les chemins précis et exacts `assets/cv/cv-fr.pdf` et `assets/cv/cv-en.pdf` définis par AD-21.
* NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence de manière indésirable sous `set -euo pipefail`. Les potentielles erreurs des commandes de lecture PDF ou les affectations dans les conditions (comme `manquant=$(pdf_missing_tool)`) sont très bien gérées.

VERDICT: BLOQUANT — Fuite de données et saturation du disque par non-suppression des fichiers temporaires précédents lorsque la fonction check_pdfs est appelée plusieurs fois (push de plusieurs commits), car la variable globale est écrasée.

### Décisions de l'auteur sur la revue du code de la PR n° 86

**Retenu — un `mktemp` par appel, et le nettoyage n'emportait que le dernier.** Le mode pre-receive appelle la lecture des PDF **une fois par commit poussé** : un push de dix commits laissait neuf CV extraits sur la forge. Le relecteur l'a vu, et a vu aussi pourquoi mes cas de test ne pouvaient pas le voir — ils ne poussaient qu'un commit à la fois.

**C'est la quatrième écriture de ce nettoyage, et les quatre ratées se ressemblent** :

| Écriture | Ce qui n'allait pas |
|---|---|
| `rm` final | ne couvre pas un arrêt en chemin |
| `trap … RETURN` | se déclenche au retour de la fonction **suivante** |
| `mktemp` par appel | écrase la variable ; seul le dernier fichier est nettoyé |
| fonction « à la demande » | appelée en `$(…)`, elle tourne dans un **sous-shell** : l'affectation est perdue, chaque appel crée un fichier que plus personne ne connaît |

La quatrième était mon propre correctif de la troisième, et je l'ai mesurée plutôt que relue : un fichier de 297 octets — exactement le PDF extrait — laissé par un seul push. La cinquième écriture est la bonne **parce qu'elle n'est plus astucieuse** : le fichier est créé une fois, tout de suite, nettoyé une fois. Coût assumé, un fichier vide quand il n'y a rien à lire ; bénéfice, il n'y a plus rien à compter.

**Retenu — le cas de test ne poussait qu'un commit.** Un nouveau cas pousse quatre commits dont trois retouchent un CV, et compte les fichiers temporaires avant et après. Il échouait sur les quatre premières écritures ; il passe sur la cinquième, et zéro fichier reste sur trois exécutions consécutives.

**Les cinq non bloquants sont des confirmations**, dont celle qui compte : l'interdiction de chemin n'est levée que pour `cv-fr.pdf` et `cv-en.pdf`, exactement comme AD-21 le prévoit.

### 22/09/2026 — `1342148` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 86. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: cf59cade42af9365d8d0f3d8

##### Revue bmad-review et projet

**Lentille : edge-case-hunter**
* NON BLOQUANT : Dans `scripts/check-private.sh`, le `trap nettoyer EXIT` fait appel à `[[ -z $patterns ]]`. Si le script venait à être interrompu de manière abrupte (ex: via un signal SIGINT) dans la micro-seconde qui sépare l'enregistrement du trap de l'initialisation de la variable avec `patterns=""`, l'option `set -u` (activée par `set -euo pipefail`) provoquerait une erreur "unbound variable" lors de l'exécution de la fonction de nettoyage. Le fichier temporaire `$blob_temporaire` serait tout de même supprimé, car son instruction précède le test. L'utilisation de `[[ -z ${patterns:-} ]]` éviterait théoriquement ce très rare cas aux limites.
* NON BLOQUANT : L'utilisation de `head -c 5` dans `pdf_has_header` (fichier `scripts/lib/pdf.sh`) n'est techniquement pas certifiée par la norme POSIX stricte (qui stipule l'usage de `-n`, bien que GNU coreutils et BusyBox supportent parfaitement `-c`). Étant donné que le hook tournera sur l'environnement d'une image Gitea (sous Alpine Linux avec BusyBox), ce choix fonctionne sans risque et est tout à fait adapté.

**Lentille : verification-gap**
* NON BLOQUANT : Le script de test `scripts/tests/test-gitea-hook.sh` teste judicieusement l'absence de la bibliothèque locale `lib/pdf.sh` via le cas `case_bibliotheque_de_pdf_absente`. Cependant, il ne contient pas de test simulant l'absence du paquet système `poppler-utils` (c'est-à-dire l'absence des commandes `pdftotext` et `pdfinfo`). Simuler ce cas demanderait d'altérer la variable `$PATH` de l'environnement durant le test. Bien que le comportement sécurisé (refus du push en cas d'outil manquant) soit traité dans le code de `pdf_missing_tool`, il subsiste un léger trou de vérification automatisée de bout en bout sur ce point précis.

**Couche propre au projet**
* NON BLOQUANT : Les critères d'acceptation de la story sont rigoureusement satisfaits, sans que leur intention ne soit vidée. Le risque de saturation du disque est élégamment écarté par la création d'un unique fichier temporaire réutilisé, et l'interdiction de chemin n'est levée que pour les chemins précis et exacts `assets/cv/cv-fr.pdf` et `assets/cv/cv-en.pdf` (conformément à l'AD-21), tout autre PDF restant fermement refusé.
* NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte, ni adresse de serveur ou secret n'est commité. Le PDF utilisé pour les tests automatisés est généré dynamiquement à partir d'une chaîne purement factice insérée dans les métadonnées. De plus, aucun script ne divulgue l'adresse de la forge ou un quelconque secret dans ses alertes.
* NON BLOQUANT : Le skill, la procédure et les scripts concordent à la perfection. La procédure `docs/procedures/gitea-pre-receive-hook.md` documente précisément la nouvelle dépendance à `poppler-utils` dans la reconstruction de l'image Docker (Alpine) et l'installation de `lib/pdf.sh`, ce qui correspond fidèlement aux actions attendues.
* NON BLOQUANT : Le changement est en totale adéquation avec AGENTS.md et les décisions d'architecture. La méthode qui consiste à analyser la conformité sans s'appuyer sur un générateur lourd et à contrôler les métadonnées pour pallier les fuites silencieuses incarne fidèlement l'esprit de l'architecture.
* NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe sous silence sous le régime de `set -euo pipefail`. Les échecs prévisibles (comme l'incapacité de lire un PDF corrompu) sont consciencieusement capturés avec l'opérateur `||` et orientés vers un rejet propre et tracé, respectant la logique qu'un fichier non lu n'est pas un fichier sûr.

VERDICT: NON BLOQUANT — aucune réserve

### Décision de l'auteur sur la deuxième revue du code de la PR n° 86

`1342148` (pass) : aucun constat, confirmations seulement.

Preuves sur la tête : `scripts/tests/run.sh`, 443 cas réussis dont 14 sur un dépôt nu muni d'un vrai hook ; `scripts/check.sh`, 8 contrôles passés ; zéro fichier temporaire laissé sur trois exécutions consécutives.

**Ce que la story livre n'est pas encore en service.** Le garde-fou, ses deux bibliothèques et le lanceur doivent être recopiés sur la forge, et le conteneur Gitea recréé depuis une image dérivée portant `poppler-utils`, avant que l'essai des CV puisse avoir lieu. Tant que ce n'est pas fait, **la forge applique l'ancienne version** : l'interdiction de chemin y tient encore, ce qui protège, mais aucun PDF ne peut être poussé.

## Reporté
