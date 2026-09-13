# Revue éditoriale (structure et prose) : PRD eleyone.fr

- **Document relu :** `prd.md` (même dossier), version du 13/09/2026.
- **Revue :** `bmad-review`, lentilles `structure` puis `prose`, en mode non interactif.
- **Périmètre :** forme uniquement, c'est-à-dire lisibilité, redondance, enchaînement des titres et des sections, clarté des phrases, cohérence avec le glossaire du §3 et typographie française. Le fond n'est pas touché : aucune exigence ajoutée ni retirée, aucune question tranchée, aucun identifiant ni numéro modifié, titres du site de FR-1 inchangés.

**Lecture de l'objet :** ce document sert à l'architecte, à l'agent qui découpe les stories et au lecteur du dépôt public. Il leur dit ce que le site eleyone.fr doit faire en v1 et comment on vérifie que c'est fait.

**Modèle de structure retenu :** Stratégique/Contexte (pyramide), celui qui convient à un PRD.

**Volume :** 8 699 mots avant la revue, 8 742 après (+43, soit +0,5 %). Cette hausse vient surtout de l'intro « Conventions de lecture » et de deux antécédents rendus explicites. On a gagné en clarté, pas en longueur.

**Vérifications après modification :** les FR-, NFR-, SM- et UJ-, les renvois « question N », les 14 balises `ASSUMPTION` et les 19 marqueurs *(relecture)* sont présents en même nombre qu'avant.

## 1. Corrections appliquées (15)

| # | Passe | Endroit | Texte d'origine | Texte révisé | Motif |
|---|---|---|---|---|---|
| 1 | structure | §0, dernier paragraphe | Un paragraphe de cinq conventions à la suite (glossaire, FR/NFR, *(relecture)*, `[ASSUMPTION]`, §11) | La liste « Conventions de lecture : » à cinq puces, dans les mêmes termes | CONDENSE en liste : c'est la légende du document, elle doit se parcourir d'un coup d'œil (+3 mots) |
| 2 | prose | §1 | « Il le transmet aux recruteurs » | « Arnaud le transmet aux recruteurs » | Le pronom pouvait renvoyer à eleyone.fr, sujet de la phrase précédente |
| 3 | prose | §2.1 | « **Lecteur du dépôt GitHub.** Souvent le même profil. » | « **Lecteur du dépôt public.** Souvent le même profil que la cible principale. » | Emploi du terme du glossaire (« Dépôt public ») ; « le même profil » n'avait pas de référent |
| 4 | prose | UJ-3 et FR-30 | « repérées avant publication » | « repérées avant la publication sur GitHub » | Le glossaire distingue « mise en ligne » et « publication sur GitHub » ; le mot seul était ambigu |
| 5 | prose | §3, Extrait | « pseudo-code ou extrait illustratif, jamais du code propriétaire » | « matériel vivant fait de pseudo-code ou d'un extrait illustratif, jamais de code propriétaire » | Même forme que Schéma et Vidéo ; la définition ne tourne plus en rond ; « jamais de » après négation |
| 6 | prose | §3, Pitch | « les deux au même contenu » | « les deux avec le même contenu » | Tournure incorrecte |
| 7 | prose | §3, Activité parallèle | « activité d'automatisation pour TPE/PME d'Arnaud » | « activité d'automatisation qu'Arnaud exerce pour les TPE/PME » | On pouvait lire « les TPE/PME d'Arnaud » |
| 8 | prose | FR-2, 1er critère | « L'accueil publié présente les cas 01, 02 et 05 qui ne sont pas des brouillons » | « L'accueil mis en ligne présente ceux des cas 01, 02 et 05 qui ne sont pas des brouillons » | Terme du glossaire (« mise en ligne ») ; la relative restrictive devient impossible à lire comme une incise |
| 9 | prose | §4.6, Description | « Il ajoute les lignes de contexte » | « La version anglaise ajoute les lignes de contexte » | Référent ambigu (le site ou l'anglais) ; reprend la formule de FR-22 |
| 10 | prose | §7, intro | « Le PRD nomme ces points sans les trancher. » | « Le PRD rappelle les décisions déjà prises et nomme, sans les trancher, les points restant à décider. » | La première puce du §7 donne des décisions déjà prises : l'intro les contredisait |
| 11 | prose | §7, décisions déjà prises | « avant chaque push GitHub » | « avant chaque push vers GitHub » | Même formule que la note de FR-28 |
| 12 | prose | §7, à décider | « l'endroit où tournent la CI et les PR » | « l'endroit où tourne la CI et où s'ouvrent les PR » | On ne dit pas qu'une PR « tourne » ; reprend la question 18 |
| 13 | prose | §9 | « **Validation de l'architecture sur le pilote.** » | « **Validation de l'architecture sur le cas pilote.** » | Terme du glossaire |
| 14 | prose | §11, question 2 | « *Impact :* FR-6 et FR-26 : tant qu'ils manquent… » | « *Impact :* FR-6 et FR-26 (tant qu'ils manquent…). » | Deux deux-points de suite dans la phrase ; même forme que la question 6 |

Les lignes 4 et 14 regroupent chacune un seul type de correction, appliqué à UJ-3 et à FR-30 pour la ligne 4. Cela fait 15 remplacements en tout.

## 2. Non appliqué, avec risque de changer le sens (à trancher par l'auteur)

| # | Passe | Endroit | Constat | Proposition | Pourquoi ce n'est pas appliqué |
|---|---|---|---|---|---|
| A | prose | §6, 5e puce | « l'effet recherché se constate de façon qualitative (SM-7) ». SM-7 s'appelle « Édition sans code » ; l'effet recherché est **SM-2** | Remplacer « (SM-7) » par « (SM-2) » | Consigne : ne pas modifier les renvois. Ce renvoi paraît périmé après une renumérotation. La correction est quasi certaine, mais c'est à l'auteur de la faire |
| B | prose | FR-28, 3e critère | « Le choix du point de contrôle […], et sa version, dépendent de la question 18. » « Sa version » peut désigner la version logicielle du contrôle ou la version du produit (v1, v1.1) | À envisager : « et la version du site qui l'inclut » ? | Il faut interpréter : la question 18 porte sur l'inclusion en v1, mais le texte ne le dit pas |
| C | prose | FR-16 | L'énoncé dit « ce qu'il ne veut pas **faire** », le critère dit « ce qu'il ne veut pas **être** » (manager, product owner, chef de projet) | À envisager : harmoniser sur un seul verbe ? | Les deux verbes n'ont pas exactement la même portée : c'est une exigence |
| D | prose | §11, question 21 | « quand tous les cas sont prêts » : dans le glossaire, « prêt » est un statut du matériel vivant | À envisager : « quand plus aucun cas n'est un brouillon » ? | « Prêts » pourrait aussi vouloir dire « avec leur matériel vivant prêt » : reformuler reviendrait à choisir |
| E | prose | §0, 4e puce | « Elles remplacent la question du brief sur ce point, et l'ancienneté retenue est de plus de dix-huit ans ; ». On ne sait pas bien si l'ancienneté fait partie de ces décisions | À envisager : « …sur ce point et retiennent une ancienneté de plus de dix-huit ans ; » ? | Rattacher l'ancienneté aux décisions d'Arnaud serait une affirmation sur la provenance |
| F | structure | §4.7, Description | « Le contenu est écrit en Markdown ». Or, d'après le glossaire, le contenu comprend aussi les sources D2 et les SVG | À envisager : « Le texte du contenu est écrit en Markdown » ? | Touche au périmètre du terme « Contenu » : c'est du fond |

## 3. Non appliqué, pour des raisons de structure (sans risque, mais hors consigne ou discutable)

| # | Disposition | Endroit | Constat | Pourquoi ce n'est pas appliqué |
|---|---|---|---|---|
| G | MERGE | §2.2, §6 (puces 2 à 6) et §8.4 | Le dirigeant de TPE/PME hors cible apparaît au §2.2 et au §6. Espace client, formulaire, analytics, intégration vidéo et cas bruts apparaissent au §6 et au §8.4. On pourrait économiser environ 60 mots | Le §6 énonce des non-objectifs permanents (« le site ne publie pas les cas bruts »), le §8.4 des exclusions de la v1. Fusionner effacerait cette nuance, et les deux sections sont prévues par le modèle de PRD. Rappeler un point à deux endroits aide aussi à le retenir |
| H | MOVE | §8.3 et §8.4 | « Hors v1 et hors v1.1 » (§8.3, 8 mots) vient avant « Hors v1 » (§8.4). L'ordre naturel irait de l'exclusion la plus faible à la plus forte | Échanger les sections changerait leurs numéros, et le §6 renvoie à §8.4 |
| I | MOVE | §11, « Contenus à fournir par Arnaud » | Ce ne sont pas des questions : leur place serait plutôt au §9 (Dépendances de contenu) | FR-17 et FR-29 renvoient à « §11, contenus à fournir » : déplacer le bloc casserait ces renvois |
| J | CONDENSE | FR-28, Notes | Reprend presque mot pour mot la puce « Décisions déjà prises » du §7 (hook local sur tout l'historique, hook côté serveur du miroir) | PRESERVE : la story du garde-fou lira FR-28 sans passer par le §7. La note renvoie déjà au §7 |
| K | PRESERVE | « Réalise UJ-x » dans la description de la fonctionnalité et dans chaque FR | Répétition | Traçabilité utile au découpage en stories |
| L | PRESERVE | UJ-3 et FR-30 (plan du README), §1 et SM-C1 (« qualité et sincérité des cas ») | Répétitions | Le parcours raconte et l'exigence prescrit ; la répétition de la thèse la renforce |
| M | QUESTION | §4.4 et §4.5 | Pas de paragraphe **Description.**, contrairement aux autres fonctionnalités | En ajouter un demanderait d'écrire du fond (par exemple, quel parcours réalisent FR-18 et FR-19) |
| N | QUESTION | §5 et §10 | La forme varie : *Test :* seulement pour NFR-1, 2, 3 et 9 ; *Mesure :* en italique pour SM-3 et SM-7, pas pour SM-1 ; la question 19 n'a pas d'*Impact :* alors que l'intro du §11 l'annonce pour chaque question | Harmoniser demanderait d'écrire des tests, des mesures ou des impacts nouveaux : c'est du fond |
| O | QUESTION | Tête du document (modèle pyramide) | Rien ne résume l'état du document dès le début : statut, nombre de questions ouvertes, questions qui bloquent l'architecture (5, 7, 11, 18) | Ce serait une synthèse nouvelle, et donc une hiérarchisation des questions : à l'auteur de juger |

## 4. Typographie

- Le document suit une convention constante : espace ordinaire avant `:` `;` `?` `!` et à l'intérieur des guillemets « », apostrophes droites, aucune espace insécable. Cette convention est cohérente sur tout le texte, et aucune entorse n'a été relevée. Rien n'a été converti : remplacer toutes ces espaces par des espaces fines insécables produirait un diff massif et invisible. Si on le souhaite, c'est plutôt au rendu (Hugo) de s'en charger.
- Rien d'autre à signaler : pas de points de suspension écrits « ... », pas de double espace, pas d'espace en fin de ligne, dates toujours au format JJ/MM/AAAA.

## 5. Synthèse

- **Recommandations :** 30 au total, dont 15 appliquées, 6 non appliquées parce qu'elles risquent de changer le sens (A à F) et 9 remarques de structure non appliquées (G à O).
- **Effet sur le volume :** les corrections appliquées ajoutent 43 mots (+0,5 %). Si l'auteur accepte aussi G (fusion), il gagnerait environ 60 mots, mais perdrait la distinction entre non-objectif permanent et exclusion de la v1.
- **Contrepartie pour le lecteur :** aucune. Rien de ce qui aide à comprendre n'a été coupé (parcours, index des hypothèses, descriptions de fonctionnalités, rappels).
- **À traiter en priorité :** A, un renvoi qui paraît périmé (§6 vers SM-7 au lieu de SM-2).
