# Story 7.4 : Publish CV PDFs

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 7.4.

## Revue de spec

### 22/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `e54251b`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: becf290a852759da09594638

##### Rapport de revue (BMAD Review)

###### Lentille : Adversarial (Recherche de failles et cas limites)
- BLOQUANT : Le critère d'acceptation `- [ ] Le job release rejouera C21... (story 11.3)` prescrit une vérification appartenant à une story future (11.3). S'il est interprété comme un critère de la 7.4, l'agent tentera de modifier prématurément le workflow `release`, ce qui violerait le principe d'une story à la fois et déborderait du périmètre technique (qui ne concerne ici que l'intégration du contenu).
- BLOQUANT : Le workflow de l'opération manuelle est incomplet. La spec indique « Arnaud fournit les deux fichiers et les commite » mais ne précise pas sur quelle branche. Si Arnaud commite sur `dev`, il court-circuite le flux linéaire imposé par l'Epic 0 (branche `feat/*`, PR, revue LLM). La spec doit exiger que l'agent crée d'abord la branche `feat/7.4-publish-cv-pdfs`, s'arrête, et demande explicitement à Arnaud d'y commiter les fichiers avant de reprendre la main.
- BLOQUANT : L'action de l'agent est muette sur la clôture de la story. Puisqu'il n'y a aucun code à produire, l'agent considérera sa tâche terminée dès l'arrivée des fichiers. Or, la règle 9 d'`epics.md` impose l'écriture du fichier de story (`_bmad-output/implementation-artifacts/...`) et la mise à jour de `sprint-status.yaml` pour faire passer la story à *done*. Sans cela, la fusion bloquera sur le verrou `sprint-consistency`.
- BLOQUANT : La gestion de l'échec n'est pas couverte. La spec indique que « la publication reste bloquée » si les PDF contiennent des données privées (ce qui fera échouer `C21` en pre-commit local ou pre-receive). Elle ne donne aucune consigne à l'agent sur la conduite à tenir face à cet échec prévisible de la CI (ex: se mettre en pause, notifier Arnaud de fournir des PDF expurgés, ne pas tenter de corriger le PDF avec des outils tiers).

###### Lentille : Structure (Organisation des idées et du format)
- NON BLOQUANT : L'usage d'une case à cocher (`- [ ]`) pour le point sur le job `release` casse le formalisme strict BDD (`Étant donné` / `Quand` / `Alors`) imposé aux autres critères d'acceptation du projet.
- NON BLOQUANT : Redondance sémantique entre les rubriques « Prérequis de contenu » et « Opération manuelle ». L'opération manuelle d'Arnaud est exactement ce qui satisfait le prérequis.
- NON BLOQUANT : La spec omet la section « Questions à poser avant de commencer » (recommandée par la règle 1 des stories) qui permettrait de clarifier la coordination asynchrone entre l'agent et Arnaud.

###### Lentille : Prose (Clarté, ambiguïté et vocabulaire)
- NON BLOQUANT : Dans le critère `Étant donné le build suivant`, le mot « suivant » est ambigu hors de son contexte chronologique. Une formulation comme `Étant donné le build incluant ces nouveaux PDF` lèverait toute ambiguïté.
- NON BLOQUANT : La précision « les PDF actuels en contiennent » exige du lecteur de connaître l'état du CV personnel d'Arnaud hors du dépôt. Remplacer par « les versions originales du CV contiennent ces données » serait plus universel.
- NON BLOQUANT : La phrase `ils seront mis en évidence sur « À propos » par la story 9.4` décrit une attente future dans un critère d'acceptation présent, ce qui peut troubler la compréhension immédiate de l'objectif de la story 7.4.

##### À trancher avant d'implémenter
- **Workflow de branchement** : Faut-il spécifier explicitement dans la spec que l'agent doit créer la branche de la story et se mettre en pause en attendant le commit d'Arnaud sur cette branche ?
- **Périmètre du critère `release`** : Le point mentionnant la story 11.3 doit-il être retiré de la liste des critères d'acceptation (ou converti en simple note) pour éviter que l'agent ne modifie le workflow Gitea par erreur ?
- **Consignes d'échec** : Faut-il ajouter une instruction claire indiquant à l'agent comment réagir (et ne pas réagir) si la CI échoue au contrôle des données privées sur les PDF ?

### Triage des constats (22/09/2026)

**Retenus**

- *Critère `- [ ]` renvoyant à la story 11.3* — juste : une case à cocher placée sous « Critères d'acceptation » se lit comme un critère de la story, et invitait à toucher au workflow `release`. Convertie en note « hors périmètre », qui dit en toutes lettres que cette story n'y touche pas.
- *« Les PDF actuels en contiennent »* — la phrase est devenue **fausse** le jour où Arnaud a fourni deux exports conformes. C'est exactement la règle 8 d'AGENTS.md : une story qui rend une phrase fausse la corrige dans sa propre PR. Passée au passé, avec la date de fourniture.
- *Le workflow de l'opération manuelle ne dit pas qui commite où* — corrigé : Arnaud fournit, l'agent range sur la branche de la story et commite. Et la conduite en cas de refus est désormais écrite : la story s'arrête et attend un nouvel export, **un PDF n'est jamais retouché pour faire passer un contrôle**. C'est la moitié utile du constat « gestion de l'échec ».
- *« le build suivant » ambigu* — remplacé par « le build incluant ces deux PDF ».

**Refusés**

- *« L'agent considérera sa tâche terminée dès l'arrivée des fichiers », fichier de story et `sprint-status.yaml` non mis à jour* — le relecteur décrit une règle de projet, pas un manque de cette spec. Le point 4 d'AGENTS.md impose les trois commits de statut à **toutes** les stories ; les répéter dans chaque spec les ferait diverger. Le verrou `sprint-consistency` les vérifie de toute façon.
- *Redondance entre « Prérequis de contenu » et « Opération manuelle »* — les deux rubriques répondent à deux questions différentes : *ce qu'il faut* et *qui le fournit*. Le gabarit des 40 stories du backlog les distingue ; les fusionner ici seul créerait l'exception.
- *« seront mis en évidence sur À propos par la story 9.4 »* — un renvoi explicitement daté d'une story future n'est pas une attente présente ; il évite qu'on croie la mise en évidence oubliée. Gardé.
- *Section « Questions à poser avant de commencer » absente* — les questions ont été posées à Arnaud directement (adresse de contact, localité), ce que la section aurait produit. Deux arbitrages rendus, consignés ci-dessous.

### Arbitrages d'Arnaud (22/09/2026)

Deux questions posées avant de ranger les fichiers, parce que C21 ne voit que des motifs **littéraux** et que son angle mort est tout ce qui prend une autre forme :

1. **L'adresse de contact des CV.** Le site n'en publie aucune aujourd'hui ; la commiter la rend publique et irréversible (le miroir pousse dans la seconde, et un commit poussé reste atteignable par son SHA). Elle n'est pas dans la liste des motifs, donc aucun contrôle ne l'arrêtait. → **« Oui, c'est voulu »** : l'adresse est celle qu'Arnaud expose aux recruteurs.
2. **Une localité de résidence sous une forme que la liste ne couvre pas.** → **« Non, rien de tel »**.

### Vérification des PDF avant de les ranger

C21 est vert, mais il compare à des motifs littéraux : un numéro de téléphone a des formes qu'une chaîne fixe ne couvre pas (`06 12…`, `06.12…`, `+33 6…`). Un contrôle **orthogonal** a donc été lancé sur le texte, les métadonnées et le XMP des deux fichiers, en ne rendant que des **comptes**, jamais un extrait :

| Recherche | `cv-fr.pdf` | `cv-en.pdf` |
|---|---|---|
| Forme de numéro français (toutes ponctuations, `+33`, `00 33`, `0`) | 0 | 0 |
| Suite de 5 chiffres | 1 | 1 |
| Suite de 10 chiffres | 1 | 1 |

Les deux suites de chiffres se sont révélées être la sortie de `pdfinfo` **elle-même** (`File size: ##### bytes`, `Page size: ###.### x ###.## pts`), et non le contenu des PDF — constaté en affichant ces lignes chiffres masqués. Autrement dit : zéro chiffre suspect dans les documents.

Les métadonnées sont propres : `Producer: WeasyPrint 70.0` et **rien d'autre** — ni `Title`, ni `Author`, ni `Subject`, ni `Keywords`, ni `CreationDate`, `Metadata Stream: no`, XMP de 0 octet. C'est précisément le champ que le prérequis visait : un export remplit `Author` tout seul, et personne ne le regarde.

Forme : 2 pages, A4 (595,276 × 841,89 pts), PDF 1.7, non chiffrés, sans JavaScript, 27 237 et 26 464 octets — loin des 500 000 que C21 borne.

## Implémentation

Aucun code : la story 7.2 a posé le partial, la 7.1 le contrôle, la 7.3 le garde-fou. Elle ne fait qu'apporter le contenu et rendre vraie la spec qui l'attendait.

- `assets/cv/cv-fr.pdf` et `assets/cv/cv-en.pdf`, les deux ensemble, comme AD-21 l'exige.
- `_bmad-output/planning-artifacts/epics.md` : la spec de la story 7.4, corrigée des quatre constats retenus.

### Constats sur le build

| Vérification | Résultat |
|---|---|
| `hugo --environment production --panicOnWarning` | 0, deux PDF publiés sous `public/cv/` |
| Liens dans le pied de page | présents sur **4 pages sur 4** |
| Ordre sur une page FR | `cv-fr.pdf` puis `cv-en.pdf` |
| Ordre sur une page EN | `cv-en.pdf` puis `cv-fr.pdf` |
| Libellés FR | `CV (PDF, français, 27 Ko)`, `CV (PDF, anglais, 26 Ko)` |
| Libellés EN | `CV (PDF, English, 26 KB)`, `CV (PDF, French, 27 KB)` |
| `scripts/check.sh` | 8 contrôles passés, dont C21 |
| `scripts/tests/run.sh` | 443 cas réussis |

## Revue du code

### 22/09/2026 — `a297d29` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 90. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 982974d91ee106e4964776d9

##### BMad Review Report

###### Lentille : Edge-case-hunter
- NON BLOQUANT : Les noms des fichiers et leur emplacement (`assets/cv/cv-fr.pdf` et `assets/cv/cv-en.pdf`) correspondent exactement à la convention (AD-21), évitant tout cas limite d'URL introuvable ou de fichier ignoré par le build.
- NON BLOQUANT : La taille des PDF (environ 26-27 Ko) est largement inférieure à la limite fixée (500 Ko par le contrôle C21), ce qui prévient les problèmes de performance et les échecs inattendus de la CI.

###### Lentille : Verification-gap
- NON BLOQUANT : Aucune lacune de vérification identifiée. L'angle mort du contrôle automatique C21 (qui ne cherche que des chaînes littérales exactes) a été correctement anticipé et comblé par une vérification manuelle et orthogonale très poussée sur le texte brut, les métadonnées et le XMP.

###### Couche propre au projet
- NON BLOQUANT : Les critères d'acceptation de la story sont pleinement satisfaits ; l'implémentation apporte les deux contenus attendus et les contrôles valident leur conformité.
- NON BLOQUANT : Aucune donnée privée, secret, nom d'hôte ou adresse de serveur n'est commité dans les fichiers textes de la PR. La présence de l'adresse e-mail dans les PDF a été explicitement validée par Arnaud comme étant une donnée publique souhaitée.
- NON BLOQUANT : Le changement est cohérent avec les décisions d'architecture (AD-21) et avec les règles d'AGENTS.md. En particulier, la règle 8 (mise au présent d'une spec réalisée) a été respectée dans la modification d'`epics.md`.
- NON BLOQUANT : Skill, procédure et script concordent (aucun script ou procédure n'a été modifié dans cette PR).
- NON BLOQUANT : Le suivi de sprint est cohérent ; le statut est correctement passé de `backlog` à `review` dans `sprint-status.yaml` ainsi que dans le fichier de story, respectant le flux de développement d'une story en relecture.

VERDICT: NON BLOQUANT — aucune

### Décision sur les constats

Aucun constat à traiter : les deux lentilles et la couche projet ne rendent que des observations conformes, sans réserve.

À noter pour la rétrospective de l'epic : la branche avait d'abord été nommée `feat/publish-cv-pdfs`, **sans le numéro de story**. `verify-and-merge-pr.sh` a bloqué deux verrous sur cette seule cause — il rattache la story au numéro lu dans le nom de la branche (`^[a-z]+/([0-9]+)-([0-9]+[a-z]?)-`), et sans lui il ne peut pas reconnaître le commit de tête comme le commit de statut que la règle 4 autorise. Le script n'a rien laissé passer et a nommé la cause ; c'est la convention de nommage qui n'était écrite nulle part dans AGENTS.md. La branche a été refaite sous `feat/7-4-publish-cv-pdfs`, la PR n° 89 fermée, la PR n° 90 ouverte à sa place, et la revue rejouée dans le bon ordre.

## Reporté
