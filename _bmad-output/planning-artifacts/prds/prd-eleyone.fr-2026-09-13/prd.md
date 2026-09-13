---
title: "PRD : eleyone.fr"
status: draft
created: 2026-09-13
updated: 2026-09-13
---

# PRD : eleyone.fr

## 0. Objet du document

Ce PRD fixe **ce que** le site eleyone.fr doit faire en v1 : ses pages, la structure de son contenu, ses exigences et leurs critères d'acceptation. Il ne dit pas **comment** le construire. Il sert d'entrée à l'architecture, puis au découpage en stories courtes livrées une par une.

Il s'appuie sur les entrées suivantes, qu'il ne recopie pas :

- le brief produit, validé le 13/09/2026 : `_bmad-output/planning-artifacts/briefs/brief-eleyone.fr-2026-09-13/brief.md` ;
- son addendum, validé à la même date (inventaire des cas, contenu connu des encarts, matériel vivant, détail technique) : `_bmad-output/planning-artifacts/briefs/brief-eleyone.fr-2026-09-13/addendum.md` ;
- le contrat de format des cas, `docs/format-cas.md`, en version 0.3 (statut draft), et le vocabulaire contrôlé de la stack, `data/stack.yaml`. Le PRD s'y réfère sans les redéfinir ;
- l'architecture, `_bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md`, dont Arnaud a validé les recommandations le 13/09/2026. Le PRD en cite quelques décisions (AD-n) comme références, sans les détailler ;
- le cas pilote 02, rédigé en FR et en EN (§9) ;
- les décisions d'Arnaud du 13/09/2026, postérieures au brief : le titre du site, le pitch et l'ancienneté (plus de dix-huit ans), puis cinq questions ouvertes de ce PRD, tranchées (§11.1) ;
- les consignes du dépôt (`AGENTS.md`), pour le contexte du dépôt et la manière de livrer les stories.

Conventions de lecture :

- Les termes du §3 (Glossaire) sont employés tels quels dans tout le document.
- Les exigences fonctionnelles (FR) sont regroupées par fonctionnalité et numérotées globalement ; les exigences non fonctionnelles (NFR) sont transverses.
- Un critère suivi de *(relecture)* se vérifie par une relecture humaine, pas par un test automatique.
- Les inférences non confirmées portent la mention `[ASSUMPTION : …]` et sont recensées au §12.
- Les points tranchés après la première version sont au §11.1 ; les points non tranchés sont au §11.2, chacun avec ce qu'il bloque : le PRD ne les décide pas.

## 1. Vision

eleyone.fr est le portfolio et le CV en ligne d'Arnaud (Eleyone), développeur backend senior : plus de dix-huit ans de PHP, surtout Symfony. Arnaud le transmet aux recruteurs, pour un poste comme pour une mission freelance, en France et à l'international.

Arnaud ne vend plus la vitesse à laquelle il écrit du code, mais du jugement : savoir quoi construire, quand, à quel coût, et ce qui casse si on se trompe. Un CV le montre mal. Le site le montre à travers des cas réels, racontés avec leurs arbitrages, leurs limites et ce qui n'est pas allé au bout.

Le site lui-même sert de preuve. Il est statique, bilingue et sobre, parce que c'est le bon outil pour le besoin. Son dépôt est public, avec les artefacts de cadrage, et son README se lit comme un cas : un lecteur voit ce qu'Arnaud sait faire, et aussi comment le site a été cadré puis construit. La valeur ne tient à aucun avantage durable, mais à la qualité et à la sincérité des cas.

## 2. Lecteurs cibles

### 2.1 Ce que le lecteur vient faire

- **CTO, tech lead ou recruteur tech (cible principale), pour un poste ou une mission freelance, en France ou à l'étranger.** Il cherche un développeur backend senior fiable, qui travaille avec l'IA. Il veut comprendre en trente secondes ce que le candidat fait bien, puis le vérifier sur un cas concret, en deux clics au plus. Il lit en français ou en anglais.
- **Lecteur international.** Il a besoin qu'on lui explique les repères français (une entreprise, un sigle, une plateforme) pour mesurer la portée d'un cas.
- **Lecteur du dépôt public.** Souvent le même profil que la cible principale. Il veut voir le code et le cadrage, et le README l'accueille comme une seconde page d'accueil.
- **Arnaud, mainteneur.** Il veut modifier le contenu sans toucher aux gabarits ni aux scripts, et publier sans risque de fuite de contenu privé.

### 2.2 Hors cible en v1

- **Le dirigeant de TPE/PME.** Il peut s'arrêter à l'encart « En bref », mais le site ne lui est pas destiné. L'offre d'automatisation est portée par Ton Pote le Geek, qui est seulement mentionné et lié.

### 2.3 Parcours clés

- **UJ-1. Claire, CTO, décide en trente secondes si elle lit plus loin.**
  Claire cherche un backend senior pour un produit où un calcul fait foi. Elle ouvre le lien reçu avec une candidature et arrive sur l'accueil, en français. Elle lit le titre du site et le pitch, puis parcourt les trois cas mis en avant. Elle ouvre le cas 02 (« Chiliz, source de vérité »). L'encart « Contexte mission » lui donne la société, le cadre, le rôle, la période et la stack ; l'encart « En bref » lui donne l'enjeu et le résultat. Elle lit la rubrique « Ce que j'ai décidé » : elle tient sa preuve, à un clic de l'accueil. Elle revient à l'accueil et suit l'appel à contact. **Cas limite :** si elle cherche un sujet qui n'a pas abouti, la section du cas 03, sur la même page Chiliz une fois ce cas mis en ligne, dit clairement qu'il n'est jamais allé en production.

- **UJ-2. Daniel, recruteur tech pour une entreprise étrangère, lit en anglais.**
  Daniel ne lit pas le français. Arrivé sur une page en français, il utilise le sélecteur de langue et retrouve la même page en anglais. Il ouvre le cas 06 (« April, hors périmètre »). Une ligne de contexte lui explique ce qu'est April Technologies, et il ne le prend pas pour le nom d'un mois. Les chiffres, les faits et la stack sont les mêmes qu'en français.

- **UJ-3. Sam, tech lead, vérifie comment le site a été construit.**
  Depuis le site, Sam suit le lien vers le dépôt public. Le README se lit comme un cas : contexte, problème, la solution facile et pourquoi elle a été écartée, ce qui a été décidé, ce qui a résisté, résultat. Dans « ce qui a résisté », il lit que l'historique initial contenait des sources privées, repérées avant la publication sur GitHub, puis que l'historique a été réécrit et un garde-fou ajouté. Il consulte ensuite les artefacts de cadrage et les exécutions publiques des contrôles sur GitHub : les schémas sont régénérés et comparés, la parité FR/EN est vérifiée par un script. Le build de l'image, le déploiement et l'agent IA de parité, qui commente les PR sans bloquer, tournent sur la forge principale, qui reste privée.

- **UJ-4. Arnaud corrige un chiffre dans un cas.**
  Arnaud modifie un chiffre dans la version française d'un cas et oublie la version anglaise. Il ouvre une PR de contenu sur la forge principale. Le script de parité passe, puisque les métadonnées sont identiques. L'agent de parité, lui, commente la PR pour signaler un chiffre modifié d'un seul côté, sans bloquer le build. Arnaud corrige la version anglaise. S'il avait laissé une donnée personnelle ou un chemin privé, le garde-fou public/privé aurait refusé le push.

## 3. Glossaire

- **Cas** : récit d'une mission réelle, identifié par son numéro (01 à 06) et son titre court (voir l'addendum du brief). Un cas existe en deux fichiers, un par langue, au format de `docs/format-cas.md`. Chaque cas a un **titre du cas** dans chaque langue.
- **Page cas** : page du site qui présente un cas. Les cas 01, 05 et 06 ont chacun la leur. Les cas 02, 03 et 04 partagent la page Chiliz.
- **Page Chiliz** : page cas qui réunit les cas 02, 03 et 04, dans cet ordre, chacun dans sa section.
- **Section** : partie de la page Chiliz consacrée à un cas. Le terme ne désigne rien d'autre.
- **Rubrique** : titre de niveau 2 du cas complet, pris dans la liste fixe de `docs/format-cas.md` (par exemple « Résultat »), avec le texte qu'il introduit.
- **Encart « Contexte mission »** : bloc placé en tête d'un cas, avec cinq champs : société, cadre, rôle, période, stack.
- **Cadre** : forme de la mission. Une valeur parmi quatre : salarié, freelance, ESN, Ton Pote le Geek. `docs/format-cas.md` en fixe les identifiants stockés, en anglais ; le site affiche un libellé dans la langue de la page.
- **Stack** : liste des technologies citées dans le cas, tirée du vocabulaire contrôlé, identique en FR et en EN.
- **Vocabulaire contrôlé** : liste des technologies autorisées, une seule écriture chacune, tenue dans `data/stack.yaml`, qui fait foi.
- **Encart « En bref »** : bloc placé après l'encart « Contexte mission ». Il donne l'enjeu puis le résultat, en trois phrases et 400 caractères au plus par langue, lisibles par un dirigeant.
- **Cas complet** : corps du cas, au niveau CTO, découpé en rubriques.
- **Cas mis en avant** : cas présenté sur l'accueil. En v1, ce sont les cas 01, 02 et 05.
- **Matériel vivant** : élément qui illustre un cas. Il en existe quatre types : schéma, vidéo, extrait, encart thématique. Chaque élément a un statut, « prévu » ou « prêt ».
- **Emplacement de matériel vivant** : endroit du cas complet où un élément de matériel vivant apparaît quand il est affiché.
- **Schéma** : matériel vivant dessiné en D2 et publié en SVG, un SVG par langue.
- **Vidéo** : matériel vivant publié sous forme de simple lien vers une vidéo YouTube non répertoriée.
- **Extrait** : matériel vivant fait de pseudo-code ou d'un extrait illustratif, jamais de code propriétaire d'un client.
- **Encart thématique** : matériel vivant qui développe un point précis d'un cas (par exemple, au cas 03, la comparaison entre batch atomique et chaînage). Ce n'est ni l'encart « Contexte mission » ni l'encart « En bref ».
- **Ligne de contexte** : phrase de la version anglaise qui explique un repère inconnu d'un lecteur international. Elle n'ajoute aucun fait.
- **Parité linguistique** : chaque page existe en FR et en EN, avec les mêmes faits, les mêmes chiffres, les mêmes métadonnées et le même matériel vivant. L'anglais n'est pas une traduction littérale.
- **Contenu** : fichiers Markdown des cas et des autres pages, sources D2 des schémas, et SVG qui en sont régénérés. [ASSUMPTION : les sources D2 font partie du contenu, puisque leurs libellés sont du texte bilingue.]
- **Forge principale** : instance Gitea privée, jamais exposée publiquement, hébergée sur un homelab distinct du serveur de production. Elle porte le dépôt principal, les PR, les contrôles, le build de l'image et le déploiement (runners x86_64). Le homelab est maintenu à jour mais peut être indisponible à tout moment.
- **Serveur de production** : serveur de l'infrastructure Docker existante, derrière son reverse proxy, qui sert le site mis en ligne. Il est distinct du homelab de la forge principale.
- **Contrôles** : vérifications automatiques de la CI (par exemple le script de parité ou la régénération des SVG), par opposition au build de l'image et au déploiement.
- **PR de contenu** : PR, ouverte sur la forge principale, qui modifie au moins un fichier de contenu.
- **Script de parité** : contrôle automatique, en CI, de la partie mécanique de la parité linguistique.
- **Agent de parité** : agent IA consultatif qui, en CI, signale en commentaire de PR les écarts de parité qu'un script ne voit pas.
- **Sélecteur de langue** : lien visible, présent sur une page, qui mène à l'autre langue.
- **Marqueur TODO** : texte `[TODO: …]` qui signale une information manquante (voir `docs/format-cas.md`).
- **Brouillon** : contenu marqué `draft: true`. Un cas qui contient un marqueur TODO reste un brouillon.
- **Mise en ligne** : production des fichiers servis au public sur eleyone.fr.
- **Socle** : première mise en ligne : accueil, « À propos », Contact, pages légales, et les trois cas mis en avant (FR-32).
- **Rendu de travail** : rendu du site hors mise en ligne, qui inclut les brouillons et les éléments de matériel vivant « prévus ».
- **Dépôt public** : miroir GitHub public, en lecture seule, du dépôt de la forge principale. Il contient le code source du site et les artefacts de cadrage BMAD. Seuls des contrôles y tournent, avec des exécutions visibles publiquement : ni build d'image, ni déploiement.
- **Publication sur GitHub** : mise à jour du dépôt public à partir de la forge principale.
- **Titre du site** : titre affiché sur l'accueil, un par langue.
- **Pitch** : trois phrases placées sous le titre du site, sur l'accueil. Un pitch par langue, les deux avec le même contenu.
- **Présentation** : ensemble formé par l'accueil et la page « À propos ».
- **Activité parallèle** : activité d'automatisation qu'Arnaud exerce pour les TPE/PME, sous la marque Ton Pote le Geek.
- **Ton Pote le Geek** : marque existante de l'activité parallèle, mentionnée et liée, jamais développée sur ce site.
- **Pages légales** : les mentions légales et la politique de confidentialité.
- **README-cas** : README du dépôt public, rédigé comme un cas pour un CTO ou un tech lead.
- **Garde-fou public/privé** : contrôle qui empêche les chemins privés et les motifs privés d'entrer dans l'historique de la forge principale, et donc d'atteindre le dépôt public.
- **Cas pilote** : le cas 02, rédigé en FR et en EN avant l'architecture, qui sert à la valider.

## 4. Fonctionnalités et exigences fonctionnelles

### 4.1 Accueil

**Description.** L'accueil doit passer le test des trente secondes : dire ce qu'Arnaud fait bien, puis mener à une preuve. Il contient le titre du site, le pitch, les cas mis en avant, un appel à contact et, selon la question 8, la mention de l'activité parallèle. Réalise UJ-1.

#### FR-1 : Titre du site et pitch

L'accueil affiche, dans chaque langue, le titre du site puis le pitch. Réalise UJ-1.

**Conséquences (testables) :**
- Dans l'ordre de lecture de la page, le titre du site, puis le pitch, précèdent les cas mis en avant.
- Le titre du site et le pitch affichés sont ceux du contenu de l'accueil dans la langue de la page, modifiables sans toucher aux gabarits (FR-25).
- À la date du PRD, le titre du site retenu est « Backend senior PHP/Symfony · Architecture & fiabilisation » en FR et « Senior PHP/Symfony Backend Engineer · Architecture & reliability » en EN ; son libellé peut encore être retouché à la marge.
- Le pitch compte trois phrases, en FR comme en EN, et les deux versions disent la même chose. Son texte relève du contenu : le PRD n'en fixe que la structure.

#### FR-2 : Cas mis en avant

L'accueil présente les cas mis en avant, chacun avec un lien vers sa page cas dans la même langue. Réalise UJ-1.

**Conséquences (testables) :**
- L'accueil mis en ligne présente les cas 01, 02 et 05, et aucun autre cas (voir FR-32 pour le socle).
- Chaque cas mis en avant affiche au moins son titre du cas, dans la langue de la page. Les autres informations affichées dépendent de la question 7.
- Le lien du cas 01 mène à sa page cas, celui du cas 05 à la sienne, celui du cas 02 à la section du cas 02 sur la page Chiliz : chaque cas mis en avant est atteint en un clic.
- Aucun lien de l'accueil ne pointe vers une page ou une section absente de la mise en ligne.

#### FR-3 : Appel à contact

L'accueil comporte un appel à contact. Réalise UJ-1.

**Conséquences (testables) :**
- L'accueil FR et l'accueil EN affichent chacun un appel à contact.
- L'appel mène en un clic à la page Contact de la même langue. [ASSUMPTION : l'appel mène à la page Contact plutôt que directement à l'adresse mail.]

#### FR-4 : Mention de l'activité parallèle

La présentation mentionne l'activité parallèle, avec un lien vers Ton Pote le Geek, sans la développer.

**Conséquences (testables) :**
- La mention et le lien vers le site de Ton Pote le Geek figurent dans la présentation, en FR et en EN. La page qui les porte (accueil, « À propos », ou les deux) dépend de la question 8.
- Aucune page du site n'est consacrée à l'offre de l'activité parallèle : ni prestations, ni tarifs, ni argumentaire.
- La version EN comporte une ligne de contexte sur Ton Pote le Geek (FR-22).

### 4.2 Pages cas

**Description.** Chaque cas se présente dans un ordre fixe : l'encart « Contexte mission », l'encart « En bref », puis le cas complet. Il y a un seul texte par cas et par langue, sans bascule entre une version CTO et une version dirigeant. Les cas 02, 03 et 04 sont réunis sur la page Chiliz. Les pages cas sont servies sous `/cas/` en français et sous `/en/cases/` en anglais. Le contenu suit `docs/format-cas.md`. Réalise UJ-1 et UJ-2.

#### FR-5 : Ordre d'un cas

Chaque cas, sur sa page cas ou dans sa section de la page Chiliz, présente dans cet ordre : son titre du cas, l'encart « Contexte mission », l'encart « En bref », le cas complet.

**Conséquences (testables) :**
- Pour chaque cas mis en ligne, en FR et en EN, le HTML rendu respecte cet ordre.
- Aucune page ne propose de bascule entre deux versions d'un même cas.

#### FR-6 : Encart « Contexte mission »

L'encart « Contexte mission » affiche la société, le cadre, le rôle, la période et la stack du cas.

**Conséquences (testables) :**
- Les cinq champs apparaissent, en FR et en EN, sous des libellés dans la langue de la page. En anglais, l'encart « Contexte mission » s'intitule *Engagement context* et l'encart « En bref » *At a glance* ; les cadres s'affichent *Employee*, *Freelance*, *IT consultancy* et *Ton Pote le Geek* (question 10, tranchée le 13/09/2026).
- Le cadre affiché est l'une des quatre valeurs du glossaire, avec son libellé dans la langue de la page.
- La stack ne contient que des technologies de `data/stack.yaml`, et elle est identique en FR et en EN. Seules les technologies citées dans le cas y figurent *(relecture)*.
- Une valeur manquante n'est jamais affichée comme un fait : elle reste un marqueur TODO et le cas reste un brouillon (FR-26). Le contenu connu à ce jour est dans l'addendum du brief (tableau « Encart Contexte mission ») et, pour le cas 02, dans le cas pilote.
- La rubrique « Contexte » du cas complet ne répète pas les faits de l'encart *(relecture)*.

#### FR-7 : Encart « En bref »

L'encart « En bref » donne l'enjeu puis le résultat du cas, dans des termes lisibles par un dirigeant.

**Conséquences (testables) :**
- Dans chaque langue, l'encart compte 3 phrases au plus et 400 caractères au plus. La règle se vérifie par script (question 11, tranchée le 13/09/2026).
- L'enjeu précède le résultat.
- L'encart est sans jargon *(relecture)*.

#### FR-8 : Cas complet

Le cas complet est rédigé au niveau CTO, en rubriques conformes à `docs/format-cas.md`.

**Conséquences (testables) :**
- Chaque titre de niveau 2 d'un cas appartient à la liste FR ou EN de `docs/format-cas.md`, et les titres suivent l'ordre de cette liste.
- Les versions FR et EN d'un cas ont exactement les mêmes rubriques.
- Une rubrique absente de la source est omise, jamais reconstituée (règle du format). Le cas 02, par exemple, n'a pas de rubrique « La solution facile, et pourquoi je ne l'ai pas prise ».
- Quand la source dit ce qui a été écarté et pourquoi, le cas le dit *(relecture)*.

#### FR-9 : Page Chiliz

La page Chiliz réunit les cas 02, 03 et 04, dans cet ordre, chacun dans sa section, avec son propre encart « Contexte mission » et son propre encart « En bref ».

**Conséquences (testables) :**
- Aucune page séparée n'existe pour les cas 02, 03 ou 04.
- La page Chiliz s'affiche correctement, en FR et en EN, avec la seule section du cas 02 : aucune section vide, aucun lien ni aucune mention vers une section absente.
- Quand le cas 03 ou le cas 04 est mis en ligne, sa section s'intègre à la page à sa place, sans modification de la page elle-même.
- Les sections mises en ligne apparaissent dans l'ordre 02, 03, 04. Chacune a son titre du cas, son encart « Contexte mission », son encart « En bref » et son cas complet.
- Chaque section peut être atteinte directement par un lien (voir FR-2 pour le cas 02).
- Le titre de la page et son éventuelle introduction dépendent de la question 9.

**Notes :** la page Chiliz ne peut pas être mise en ligne tant que le cas 02 est un brouillon : un contrôle de mise en ligne l'empêche (C15 dans l'architecture).

#### FR-10 : Limites présentées telles quelles

Un sujet qui n'est jamais allé en production et les limites d'une mesure sont présentés tels quels. En particulier, la section du cas 03 dit explicitement que le sujet n'est jamais allé en production, à côté de deux cas livrés.

**Conséquences (testables) :**
- En FR et en EN, la rubrique « Résultat » du cas 03 dit que le sujet n'est pas allé en production.
- En FR et en EN, l'encart « En bref » du cas 03 le dit aussi. [ASSUMPTION : le résultat donné par l'encart est ce non-aboutissement.]
- Ni le titre du cas 03, ni son encart « En bref », ni la page Chiliz ne le présentent comme livré *(relecture)*.
- En FR et en EN, le cas 05 nomme les limites de sa mesure *(relecture)*.

#### FR-11 : Cas 01 rattaché à Ton Pote le Geek

La page cas du cas 01 indique que la mission a été réalisée dans le cadre de Ton Pote le Geek.

**Conséquences (testables) :**
- Le cadre affiché dans l'encart « Contexte mission » du cas 01 est Ton Pote le Geek, en FR et en EN.
- La version EN du cas 01 comporte la ligne de contexte sur Ton Pote le Geek (FR-22).

#### FR-12 : Matériel vivant, emplacements et visibilité

Chaque cas déclare le matériel vivant prévu par ses sources et place chaque élément à son emplacement dans le cas complet. Un élément « prévu » est invisible en production. *Tranché le 13/09/2026.*

**Conséquences (testables) :**
- Chaque élément déclaré a un identifiant, un type (schéma, vidéo, extrait, encart thématique), un statut (« prévu » ou « prêt ») et une description.
- Chaque identifiant placé dans le texte est déclaré, et chaque élément déclaré est placé dans le texte, en FR comme en EN.
- Les identifiants, les types et les statuts sont identiques en FR et en EN.
- Sur le site mis en ligne, un élément « prêt » s'affiche à son emplacement, dans la langue de la page.
- Sur le site mis en ligne, un élément « prévu » est invisible : ni élément, ni mention « à venir », ni trace de son emplacement dans le HTML.
- Dans le rendu de travail, les éléments « prévus » sont visibles à leur emplacement.
- Le texte d'un cas se lit complètement sans son matériel vivant : aucune phrase ne s'appuie sur un élément de matériel vivant *(relecture)*.
- Les éléments déclarés sont ceux de l'addendum du brief (« Matériel vivant prévu par les sources ») ; aucun élément n'est ajouté sans source *(relecture)*.

#### FR-13 : Schémas bilingues

Chaque schéma existe en deux SVG, l'un avec des libellés français, l'autre avec des libellés anglais. Chaque page affiche le SVG de sa langue.

**Conséquences (testables) :**
- Pour chaque schéma « prêt », un SVG FR et un SVG EN existent dans le dépôt.
- La page FR affiche le SVG FR, la page EN le SVG EN.
- Chaque schéma affiché a une alternative textuelle dans la langue de la page (NFR-4).
- Ces critères se vérifient à la livraison du premier schéma « prêt ». Si la question 1 n'en prévoit aucun en v1, la story correspondante attend.

#### FR-14 : Vidéos en simples liens

Une vidéo est publiée sous forme de simple lien vers une vidéo YouTube non répertoriée.

**Conséquences (testables) :**
- Aucune page ne contient d'iframe, ni de ressource chargée depuis un domaine YouTube ou Google.
- Une vidéo « prête » s'affiche comme un lien vers son URL YouTube.
- Le contenu des vidéos dépend de la question 3. Ces critères se vérifient à la livraison de la première vidéo « prête ».

#### FR-15 : Accès aux pages cas

Chaque cas mis en ligne est accessible depuis l'accueil en suivant les liens du site.

**Conséquences (testables) :**
- Aucune page cas mise en ligne n'est orpheline : chacune est atteignable par des liens depuis l'accueil de sa langue.
- Les cas mis en avant sont atteints en un clic (FR-2).
- Une fois mis en ligne, les cas 03, 04 et 06 sont atteints en deux clics au plus. [ASSUMPTION : le critère des deux clics du brief vaut pour tous les cas, pas seulement pour une preuve.]
- Le moyen d'accès aux cas non mis en avant (liste des cas, menu ou autre) dépend de la question 6.

### 4.3 À propos

**Description.** La page « À propos » condense le positionnement d'Arnaud. Elle est servie à `/a-propos/` en français et à `/en/about/` en anglais. Réalise UJ-1.

#### FR-16 : Contenu de la page « À propos »

La page « À propos » dit ce qu'Arnaud fait bien, ce qu'il ne veut pas être et comment il travaille aujourd'hui.

**Conséquences (testables) :**
- En FR et en EN, la page traite de ce qu'Arnaud fait bien : partir du minimum, décider sur le coût et le mode de défaillance, valider un chiffre face à une référence, reprendre un sujet sans écraser celui qui le portait *(relecture)*.
- Elle dit ce qu'il ne veut pas être : manager, product owner, chef de projet.
- Elle dit comment il travaille aujourd'hui : Claude Code au quotidien, certification Claude en préparation.
- Elle ne contient aucune information de la liste de NFR-9, et rien qui soit absent des sources (NFR-10) *(relecture)*.

### 4.4 Contact

#### FR-17 : Page Contact

La page Contact donne une adresse mail et un lien LinkedIn, sans formulaire. Elle est servie à `/contact/` en français et à `/en/contact/` en anglais. Réalise UJ-1.

**Conséquences (testables) :**
- En FR et en EN, la page affiche l'adresse mail et le lien vers le profil LinkedIn.
- Aucune page du site ne contient de formulaire.
- L'adresse mail et l'URL LinkedIn sont à fournir par Arnaud (§11.2, contenus à fournir).

### 4.5 Pages légales

#### FR-18 : Mentions légales

Le site met en ligne des mentions légales statiques, à `/mentions-legales/` en français et à `/en/legal-notice/` en anglais.

**Conséquences (testables) :**
- Une page de mentions légales existe dans chaque langue.
- Elle est accessible depuis chaque page du site. [ASSUMPTION : les pages légales sont liées depuis toutes les pages, par exemple en pied de page.]
- Sur le site mis en ligne, elle affiche, dans chaque langue, les mentions exigées par la loi. *Tranché le 13/09/2026.*
  - Éditeur : identité, adresse de l'activité déclarée, contact, numéro d'immatriculation.
  - Directeur de la publication : l'éditeur lui-même.
  - Hébergeur : raison sociale, adresse et contact, repris de sa page légale officielle.
- Elle n'affiche pas de numéro de TVA intracommunautaire.
- Ces valeurs sont fournies au build par l'environnement et ne sont jamais commitées : aucune n'apparaît dans le dépôt ni dans son historique (NFR-9, AD-9).
- Le build de production échoue si une valeur manque.

#### FR-19 : Politique de confidentialité minimale

Le site met en ligne une politique de confidentialité statique et minimale, à `/confidentialite/` en français et à `/en/privacy/` en anglais.

**Conséquences (testables) :**
- Une politique de confidentialité existe dans chaque langue et est accessible depuis chaque page du site (même hypothèse que FR-18).
- Elle indique que le site ne dépose aucun cookie et que les vidéos sont des liens vers YouTube, un site tiers.
- Elle indique que l'éditeur ne collecte aucune donnée personnelle, et renvoie à la politique de l'hébergeur pour ses propres traitements.
- Cette affirmation est vraie sur toute la chaîne de service, reverse proxy compris : aucune adresse IP n'est journalisée ; le journal d'accès est minimal, sans IP, user-agent ni referer ; le journal d'erreurs est au niveau `crit` (AD-15). *Tranché le 13/09/2026.*

### 4.6 Bilinguisme et parité linguistique

**Description.** Le site est complet en français et en anglais : l'anglais n'est pas un sous-ensemble du français, ni une traduction littérale. La version anglaise ajoute les lignes de contexte dont un lecteur international a besoin. La parité linguistique est contrôlée à deux niveaux : un script de parité pour la partie mécanique, et un agent de parité consultatif qui ne bloque jamais. Réalise UJ-2 et UJ-4.

#### FR-20 : Deux versions complètes

Chaque page du site existe en français et en anglais, avec le même contenu.

**Conséquences (testables) :**
- Pour chaque page mise en ligne en FR, la page équivalente est mise en ligne en EN, et inversement : accueil, pages cas, page Chiliz, « À propos », Contact, pages légales.
- Un cas qui est un brouillon dans une langue n'est mis en ligne dans aucune des deux.
- Les faits et les chiffres sont identiques dans les deux versions *(relecture, aidée par l'agent de parité)*.

#### FR-21 : Langues, racine du domaine et sélecteur de langue

Le français est servi à la racine du domaine, l'anglais sous `/en/`. Chaque page comporte un sélecteur de langue visible. *Tranché le 13/09/2026.* Réalise UJ-2.

**Conséquences (testables) :**
- La racine du domaine sert l'accueil en français ; l'accueil anglais est servi sous `/en/`, et toutes les pages anglaises sous ce préfixe.
- Aucune redirection automatique selon la langue du navigateur : une requête vers la racine avec un navigateur réglé en anglais reçoit l'accueil français, sans redirection.
- Chaque page mise en ligne comporte un sélecteur de langue visible. [ASSUMPTION : le sélecteur mène à la page équivalente, et non à l'accueil de l'autre langue ; sur la page Chiliz, il mène à la page Chiliz de l'autre langue.]
- Chaque page déclare, par des annotations `hreflang`, sa version française et sa version anglaise.
- Chaque page déclare sa langue dans son HTML.

#### FR-22 : Lignes de contexte pour le lecteur international

La version anglaise ajoute une ligne de contexte là où un repère ne parle qu'à un lecteur français. Réalise UJ-2.

**Conséquences (testables) :**
- Chaque repère recensé dans l'addendum du brief (« Lignes de contexte pour la version anglaise ») a sa ligne de contexte dans la version EN du cas concerné ou de la présentation : April Technologies (cas 06), Orange (cas 05), Systeme.io (cas 01), NCS/CS (cas 02), Ton Pote le Geek (cas 01 et présentation).
- Une ligne de contexte n'ajoute aucun fait absent des sources *(relecture)*. La ligne sur April Technologies reste à écrire avec Arnaud.

#### FR-23 : Script de parité

Un script de parité vérifie en CI la partie mécanique de la parité linguistique. Réalise UJ-4.

**Conséquences (testables) :**
- Le script signale toute page FR sans page EN, et inversement.
- Il signale, entre les deux fichiers d'un cas, toute différence dans les métadonnées qui ne se traduisent pas selon `docs/format-cas.md` : identifiants, numéro, groupe, ordre, mise en avant, brouillon, cadre, stack, et identifiants, types et statuts du matériel vivant.
- Il signale toute différence de rubriques entre les deux fichiers d'un cas.
- Il signale tout schéma auquel manque l'un de ses deux SVG.
- Chaque signalement nomme le fichier et l'écart.
- Un écart fait échouer la CI. [ASSUMPTION : le script est bloquant, par contraste avec l'agent de parité, que le brief dit explicitement non bloquant.]

#### FR-24 : Agent de parité consultatif

Un agent de parité signale en commentaire de PR, sur la forge principale, les écarts qu'un script ne voit pas, sans jamais bloquer. Réalise UJ-4.

**Conséquences (testables) :**
- Sur une PR de contenu, l'agent s'exécute et publie un commentaire sur la PR, dans la forge principale.
- Un échec, une erreur ou une absence de réponse de l'agent ne fait jamais échouer la CI.
- L'agent ne s'exécute pas sur une PR qui n'est pas une PR de contenu.
- Sur une PR venant d'un fork, la clé d'API de l'agent n'est pas exposée (NFR-11).
- Qualité de détection, consultative : sur deux PR de démonstration, l'une qui modifie un chiffre d'un seul côté, l'autre qui supprime une phrase d'un seul côté, le commentaire signale l'écart. Une détection manquée est remontée, mais ne bloque rien.

**Hors périmètre :** la mise en œuvre de l'agent est fixée par l'architecture (AD-16 : modèle Sonnet, sur la forge principale seulement, pas d'agent sur le dépôt public). Les commentaires restent sur la forge principale, privée, et ne sont pas visibles publiquement.

### 4.7 Contenu, mise en ligne et garde-fou

**Description.** Les textes du contenu sont écrits en Markdown, au format de `docs/format-cas.md` pour les cas. La mise en ligne ne laisse passer ni brouillon, ni marqueur TODO, ni élément « prévu », ni schéma désynchronisé, et aucun contenu privé n'entre dans l'historique. Réalise UJ-4.

#### FR-25 : Édition sans code

Arnaud modifie le contenu sans toucher aux gabarits ni aux scripts.

**Conséquences (testables) :**
- Modifier le texte ou les métadonnées d'un cas ne touche que les fichiers Markdown de ce cas.
- Ajouter ou modifier un schéma ne touche que les fichiers Markdown du cas, la source D2 du schéma et les SVG qui en sont régénérés. La régénération se fait en lançant les scripts existants, sans les modifier.
- Utiliser une technologie nouvelle dans une stack ne demande en plus que de l'ajouter à `data/stack.yaml`, comme le prévoit `docs/format-cas.md`.
- Le texte des pages hors cas (accueil, « À propos », Contact, pages légales) se modifie lui aussi en Markdown, sans toucher aux gabarits. C'est une contrainte du dépôt (`AGENTS.md` : contenu en Markdown modifiable sans toucher au code).

#### FR-26 : Brouillons et rendu de travail

Aucun brouillon et aucun marqueur TODO n'apparaît sur le site mis en ligne ; le rendu de travail, lui, montre les brouillons.

**Conséquences (testables) :**
- La recherche de la chaîne `[TODO` dans les fichiers de la mise en ligne ne renvoie rien.
- Un cas marqué `draft: true` n'apparaît sur aucune page mise en ligne (accueil, page Chiliz, liste éventuelle), et aucun lien ne pointe vers lui.
- Le rendu de travail montre le site avec ses brouillons et ses éléments de matériel vivant « prévus » (FR-12). Il sert à démontrer les stories, notamment sur le cas pilote.
- Un passage entre crochets dans les sources n'est jamais mis en ligne comme un fait *(relecture)*.

#### FR-27 : Schémas SVG commités et vérifiés

Les SVG des schémas sont commités dans le dépôt, et la CI vérifie qu'ils correspondent à leurs sources D2.

**Conséquences (testables) :**
- La CI régénère tous les SVG à partir des sources D2 et échoue si l'un d'eux diffère du fichier commité.
- Deux rendus du même commit donnent des SVG identiques à l'octet près (NFR-8).
- La CI échoue si une source D2 n'a pas ses SVG commités, ou si un SVG commité n'a pas de source. [ASSUMPTION : les fichiers orphelins sont traités comme une désynchronisation.]
- Ces critères se vérifient sur le premier schéma, réel ou de démonstration.

#### FR-28 : Garde-fou public/privé

Le garde-fou public/privé empêche les chemins privés et les motifs privés d'entrer dans l'historique de la forge principale, et donc d'atteindre le dépôt public. Il est non contournable. *Tranché le 13/09/2026 pour le côté serveur.* Réalise UJ-3 et UJ-4.

**Conséquences (testables) :**
- Côté serveur, la forge principale refuse tout push qui introduit un fichier du répertoire privé ou une chaîne de la liste des motifs privés, quel que soit le poste d'où vient le push.
- Un contrôle local, avant le push, signale les mêmes contenus au plus tôt ; le contournement du contrôle local n'empêche pas le refus côté serveur.
- Avant la première publication sur GitHub, un audit de tout l'historique, pas seulement du dernier commit, est propre.
- La liste des motifs privés n'est jamais versionnée dans le dépôt, ni sur la forge principale ni sur le dépôt public.
- Les contrôles exécutés sur le dépôt public vérifient au moins les chemins interdits. Ils ne peuvent pas vérifier les motifs privés, dont la liste n'y est pas disponible : la garantie non contournable reste celle de la forge principale.

**Notes :** la répartition exacte des contrôles entre la forge principale et le dépôt public est une tâche d'architecture (§7).

### 4.8 Dépôt public

**Description.** Le dépôt public montre le code et le cadrage, et son README se lit comme un cas. Réalise UJ-3.

#### FR-29 : Lien vers le dépôt public

Le site propose un lien vers le dépôt public, présenté comme le moyen de voir ce qu'Arnaud sait faire et comment le site a été construit.

**Conséquences (testables) :**
- Le site FR et le site EN contiennent chacun au moins un lien vers le dépôt public.
- L'URL du dépôt est à fournir (§11.2, contenus à fournir).

#### FR-30 : README-cas

Le README du dépôt public est rédigé comme un cas, pour un CTO ou un tech lead.

**Conséquences (testables) :**
- Le README suit la structure des cas : contexte, problème, la solution facile et pourquoi elle a été écartée, ce qui a été décidé, ce qui a résisté, résultat.
- Sa partie « ce qui a résisté » raconte que l'historique initial contenait des sources privées, repérées avant la publication sur GitHub, puis que l'historique a été réécrit et le garde-fou public/privé ajouté.
- Le README ne nomme aucun fichier privé et ne contient aucune information de la liste de NFR-9.
- Le README est rédigé en anglais. *Tranché le 13/09/2026.*

#### FR-31 : Artefacts de cadrage publics

Le dépôt public contient les artefacts de cadrage BMAD : brief, PRD, puis architecture et stories quand ils existeront.

**Conséquences (testables) :**
- Le brief, son addendum et ce PRD sont présents dans le dépôt public.
- Aucun artefact public ne cite de cas brut : les cas y sont désignés par leur numéro et leur titre court.

### 4.9 Mise en ligne progressive

**Description.** Le site est mis en ligne en deux temps : un socle d'abord, puis les autres cas un par un, quand chacun est prêt. *Tranché le 13/09/2026.*

#### FR-32 : Socle, puis cas un par un

La première mise en ligne est le socle ; les cas 03, 04 et 06 sont ensuite mis en ligne un par un.

**Conséquences (testables) :**
- La première mise en ligne contient, en FR et en EN : l'accueil, « À propos », Contact, les mentions légales, la politique de confidentialité, la page cas du cas 01, la page Chiliz avec la section du cas 02, et la page cas du cas 05.
- Aucun des cas 01, 02 et 05 n'est un brouillon au moment de la mise en ligne du socle.
- Les cas 03, 04 et 06 sont mis en ligne chacun indépendamment, quand il n'est plus un brouillon, sans modifier le contenu des autres pages.
- Chaque mise en ligne est déclenchée explicitement, par un tag (AD-14), et non à chaque modification du dépôt.
- À chaque étape, le site mis en ligne respecte FR-9 (page Chiliz partielle), FR-15 (aucune page orpheline) et FR-26 (aucun brouillon).

## 5. Exigences non fonctionnelles transverses

- **NFR-1. Site statique.** Le site est un ensemble de fichiers statiques générés par Hugo, sans base de données, sans backend et sans code exécuté côté serveur à la requête. *Test :* le résultat du build ne contient que des fichiers servables tels quels.
- **NFR-2. Hébergement existant.** Les fichiers sont servis par un conteneur nginx, sur l'infrastructure Docker existante, derrière le reverse proxy en place : c'est le serveur de production. Le build de l'image et le déploiement partent de la forge principale, sur un autre serveur. Une indisponibilité de la forge principale bloque les déploiements, jamais le site mis en ligne. *Test :* le site mis en ligne répond via ce reverse proxy, sans nouveau service d'hébergement, y compris quand la forge principale est arrêtée.
- **NFR-3. Aucun cookie, aucun consentement.** Aucune page ne dépose de cookie ni ne charge de ressource qui en dépose, et le site n'a donc pas de bandeau de consentement. *Test :* le chargement de chaque page, dans un navigateur vierge, ne crée aucun cookie.
- **NFR-4. Accessibilité WCAG 2.2 niveau AA.** Chaque page mise en ligne, en FR et en EN, satisfait les critères de succès WCAG 2.2 de niveaux A et AA. *Tranché le 13/09/2026.* *Test :* audit de chaque gabarit de page contre ces critères ; l'outillage relève de l'architecture.
- **NFR-5. Performance.** Chaque page mise en ligne atteint, sur mobile, les seuils « bons » des Core Web Vitals : LCP ≤ 2,5 s, CLS ≤ 0,1, INP ≤ 200 ms. Chaque page respecte le budget de poids par page chiffré dans l'architecture (AD-8). Le site n'utilise pas de framework front lourd. *Tranché le 13/09/2026.* *Test :* mesure de chaque gabarit de page contre ces seuils et ce budget ; l'outillage relève de l'architecture.
- **NFR-6. Design sobre.** Le design est professionnel et lisible, sans effets ni gabarit « agence » : c'est le contenu qui porte la page *(relecture)*. Le site utilise la police système, sans police web (AD-8).
- **NFR-7. Maintenance minimale et bon outil pour le besoin.** Le build se reproduit avec des scripts simples, sans base de données, sans backend et sans dépendance lourde à suivre. Symfony et React sont exclus. Tout outil ajouté au build ou à la CI répond à un besoin que des scripts simples ne couvrent pas *(relecture de chaque ajout)*.
- **NFR-8. Reproductibilité des schémas.** Pour une version de D2 donnée, le rendu d'un schéma est identique à l'octet près d'un build à l'autre, sur x86_64, où ce déterminisme a été testé : c'est l'architecture des runners de la forge principale, et celle des runners hébergés de GitHub, à confirmer par l'architecture. C'est ce qui rend FR-27 possible.
- **NFR-9. Frontière public/privé.** Le dépôt et son historique ne contiennent aucune information personnelle : ni prétentions de rémunération ou de taux journalier, ni lieu de vie, ni conditions de télétravail ou de mobilité, ni auto-évaluation d'entretien, ni proches, ni chemin d'un fichier privé, ni coordonnées de l'éditeur. Les pages du site ne contiennent aucune de ces informations, à une exception : les mentions légales exigées par la loi (identité, adresse, contact et immatriculation de l'éditeur ; hébergeur) apparaissent sur le site public. Ces valeurs sont injectées au build par l'environnement, jamais commitées, et le build de production échoue s'il en manque une (FR-18, AD-9). *Tranché le 13/09/2026.* *Test :* le garde-fou public/privé refuse ces contenus (FR-28), aucune valeur des mentions légales n'est présente dans le dépôt, et une relecture couvre ces catégories.
- **NFR-10. Intégrité et voix du contenu.** Rien n'est inventé : ni cas, ni chiffre, ni client, ni technologie, ni date absents des sources ou non confirmés par Arnaud. Le contenu reformule les sources le moins possible, à la première personne, sur un ton factuel envers les anciens employeurs et clients. Les faits et les chiffres sont les mêmes en FR et en EN. Aucun code propriétaire d'un client n'est publié : seulement du pseudo-code et des extraits illustratifs *(relecture)*.
- **NFR-11. Sécurité de la CI.** La clé d'API de l'agent de parité est un secret de la CI de la forge principale. Elle n'est jamais exposée aux PR venant de forks, ni affichée dans les journaux de CI. Elle n'est pas placée sur le dépôt public, où l'agent ne tourne pas (AD-16).
- **NFR-12. Zéro JavaScript en v1.** Les pages mises en ligne ne chargent aucun JavaScript, dans la mesure du possible. Toute exception est justifiée par écrit, avec le besoin qu'elle couvre et l'absence d'alternative sans JavaScript. *Tranché le 13/09/2026.* *Test :* les fichiers de la mise en ligne ne contiennent ni fichier JavaScript ni script en ligne, hors exceptions justifiées.

## 6. Non-objectifs de la v1

- Le site n'est pas une vitrine commerciale de l'activité parallèle : il n'a pas de page d'offre TPE/PME, ni en v1 ni en v1.1.
- Le site ne s'adresse pas au dirigeant de TPE/PME. L'encart « En bref » lui reste lisible, mais rien n'est conçu pour lui.
- Le site ne publie pas les cas bruts, seulement leur reformulation.
- En v1, le site n'est pas une application : ni espace client, ni formulaire, ni backend.
- En v1, le site n'a pas d'analytics avancés : l'effet recherché se constate de façon qualitative (SM-2).
- En v1, les vidéos ne sont pas intégrées dans les pages (une façade reste possible plus tard, voir §8.4).
- Le dépôt public n'est pas un lieu de travail : ni PR, ni build d'image, ni déploiement n'y ont lieu ; seuls des contrôles y tournent.
- La forge principale n'est pas exposée publiquement.

## 7. Contraintes transmises à l'architecture

Le PRD rappelle les décisions déjà prises et nomme les points confiés à l'architecture. Ces points sont désormais traités dans `ARCHITECTURE-SPINE.md` (recommandations validées par Arnaud le 13/09/2026), notamment le budget de poids et la police système (AD-8), les mentions légales (AD-9), la mise en ligne par tag (AD-14), la journalisation (AD-15) et l'agent de parité (AD-16). La liste ci-dessous reste la trace de ce qui a été confié.

- **Décisions déjà prises (brief, addendum et décisions du 13/09/2026).**
  - Le site est généré par Hugo. La chaîne de build va de D2 aux SVG par langue (commités), puis au build Hugo, aux fichiers statiques et à l'image nginx.
  - Les schémas D2 partagent une structure commune à libellés variables, avec un point d'entrée par langue. Les vidéos sont de simples liens.
  - Le français est à la racine du domaine, l'anglais sous `/en/`, sans redirection selon la langue du navigateur (FR-21).
  - Le dépôt principal et les PR sont sur la forge principale : Gitea privé, jamais exposé publiquement, sur un homelab distinct du serveur de production, avec des runners x86_64 déjà en place. Le homelab peut être indisponible à tout moment.
  - Le dépôt public est un miroir GitHub en lecture seule.
  - Répartition de la CI : sur la forge principale, les contrôles, le build de l'image et le déploiement vers le serveur de production ; sur le dépôt public, uniquement des contrôles, dont les exécutions sont visibles publiquement, sans build d'image ni déploiement.
  - Le garde-fou public/privé tourne côté serveur sur la forge principale (hook pre-receive Gitea), en plus du hook local ; la liste des motifs privés doit donc être disponible sur ce serveur sans être versionnée.
  - Le rendu D2 a été testé déterministe sur x86_64, l'architecture des runners de la forge principale.
- **Conséquences à prendre en compte sans être résolues ici :**
  - l'agent de parité commente les PR sur la forge principale : ses commentaires ne sont pas visibles publiquement ;
  - une indisponibilité du homelab bloque les déploiements, pas le site mis en ligne (NFR-2).
- **Tâche d'architecture : contrôles communs à la forge principale et au dépôt public.** Étudier comment faire tourner les mêmes contrôles sur les deux, à partir de scripts communs, sans les dupliquer. Points rattachés :
  - quels contrôles tournent sur le dépôt public : parité FR/EN, régénération des SVG, marqueurs TODO et brouillons, vocabulaire de la stack, zéro JavaScript, garde-fou des chemins ; la liste des motifs privés n'y est pas disponible ;
  - l'agent de parité tourne-t-il aussi sur le dépôt public, alors qu'il n'y a pas de PR sur le miroir et qu'il faudrait y placer une clé d'API ;
  - l'architecture x86_64 des runners hébergés de GitHub, à confirmer pour le rendu D2 ;
  - l'indisponibilité possible du homelab, qui bloque les déploiements sans affecter le site mis en ligne.
- **À décider par l'architecture :**
  - la structure du dépôt, et l'emplacement et le nommage des fichiers de contenu et des schémas (`docs/format-cas.md` propose des noms de fichiers en anglais et attend la confirmation de l'emplacement) ;
  - l'assemblage de la page Chiliz à partir des cas, y compris quand seule la section du cas 02 est mise en ligne, et la façon d'adresser chaque section ;
  - le rendu d'un emplacement de matériel vivant selon son type, et la façon de rendre un élément « prévu » invisible en production mais visible dans le rendu de travail ;
  - la production du rendu de travail (FR-26) ;
  - l'outil qui fait tourner l'agent de parité ;
  - la mise en œuvre du garde-fou public/privé côté serveur et en local ;
  - l'outillage de vérification de NFR-4 et NFR-5, en préférant des scripts à une chaîne Chrome et Node en CI ;
  - la valeur du budget de poids par page (NFR-5), à faire valider par Arnaud ;
  - la justification de toute exception à NFR-12 ;
  - le moteur de mise en page et le thème D2 (l'addendum recommande ELK et un thème sobre commun), et l'épinglage de la version de D2 ;
  - les points de vigilance D2 relevés dans l'addendum : pas de retour à la ligne automatique dans les libellés, fichiers générés avec les droits 0600 (à prendre en compte pour nginx).

## 8. Périmètre

### 8.1 Dans la v1

- L'accueil (FR-1 à FR-4).
- Les pages cas : cas 01, page Chiliz (cas 02, 03 et 04), cas 05, cas 06, chacun avec ses encarts « Contexte mission » et « En bref » et son cas complet (FR-5 à FR-11, FR-15).
- Le matériel vivant et sa visibilité (FR-12). Les exigences sur les schémas, les vidéos et les SVG vérifiés (FR-13, FR-14, FR-27) s'appliquent dès qu'un élément de leur type est « prêt » ; leur livraison en v1 dépend de la question 1.
- La page « À propos », la page Contact, les mentions légales et la politique de confidentialité (FR-16 à FR-19).
- Un site complet en FR et en EN, avec racine française, anglais sous `/en/`, sélecteur de langue, lignes de contexte, script de parité et agent de parité (FR-20 à FR-24).
- L'édition en Markdown, le rendu de travail, les brouillons exclus de la mise en ligne et le garde-fou public/privé (FR-25, FR-26, FR-28).
- Le lien vers le dépôt public, le README-cas et les artefacts de cadrage publics (FR-29 à FR-31).
- La mise en ligne en deux temps : socle, puis cas 03, 04 et 06 un par un (FR-32).
- Les liens vers Ton Pote le Geek.

### 8.2 v1.1

Les entrées ne donnent aucun contenu à la v1.1. Le brief annonce « v1 puis v1.1 » sans rien y placer, et la seule mention de la v1.1 est une exclusion : la page d'offre TPE/PME. La mise en ligne progressive des cas 03, 04 et 06 fait partie de la v1 (FR-32). Ce PRD n'invente pas le contenu de la v1.1 (question 13).

### 8.3 Hors v1 et hors v1.1

- La page d'offre TPE/PME (tranché le 13/09/2026).

### 8.4 Hors v1

- Blog.
- Espace client.
- Formulaire de contact.
- Analytics avancés.
- Intégration de vidéos dans les pages, y compris une façade (vignette, puis iframe au clic), qui reste possible plus tard.
- Bandeau de cookies.
- Taxonomie des cas par technologie : une piste pour plus tard, que permet la stack en métadonnée.
- Publication des cas bruts.

## 9. Séquencement et cas pilote

- **Cas pilote : état au 13/09/2026.** Le cas 02 (« Chiliz, source de vérité ») est rédigé en FR et en EN, conforme à `docs/format-cas.md`, sans marqueur TODO, et corrigé à la relecture. Ses deux fichiers sont placés dans `content/cases/chiliz/`. Sa rubrique « La solution facile, et pourquoi je ne l'ai pas prise » a été retirée, faute de source, et le format a gagné la règle correspondante : une rubrique absente de la source est omise. Ses identifiants sont passés en anglais, et sa stack s'appuie sur `data/stack.yaml`. À la date du PRD, son fichier reste marqué `draft: true` ; il passe à `draft: false` selon la règle du format. Il a été choisi parce qu'il fait jouer le plus de mécanismes : page Chiliz, cas mis en avant, matériel vivant, ligne de contexte EN, parité linguistique.
- **Validation de l'architecture sur le cas pilote.** L'architecture est validée sur le cas pilote avant la rédaction des dix autres fichiers de cas (les cinq autres cas, en deux langues). Les premières stories doivent pouvoir être démontrées avec ce seul cas, sur le rendu de travail : FR-2 (lien vers une section), FR-5 à FR-9 (dont la page Chiliz avec la seule section du cas 02), FR-12, FR-20 à FR-23 et FR-26. Le format peut encore être ajusté à l'issue de cette validation.
- **Stories.** Elles sont courtes et livrées une par une. Avant chaque story, l'agent reformule ce qu'il a compris et pose ses questions (`AGENTS.md`).
- **Mise en ligne (FR-32).** Le socle d'abord, puis les cas 03, 04 et 06 un par un. Le socle attend que les cas 01 et 05 ne soient plus des brouillons, donc la réponse à la question 2 pour ces deux cas.
- **Corrections préalables des sources (addendum).** Avant la rédaction des cas concernés :
  - cas 01 : reformuler une mention personnelle du contexte, et ajouter le cadre (Ton Pote le Geek) ; la société cliente peut être nommée ;
  - cas 02 : corriger la note sur la signature unique, avant la rédaction du cas 03 (question 4) ;
  - cas 06 : nommer la société April Technologies.

## 10. Indicateurs de succès

**Indicateurs de la thèse** (le site prouve-t-il le jugement ?)
- **SM-1. Test des trente secondes.** Après trente secondes sur l'accueil, un CTO ou un recruteur peut dire ce qu'Arnaud fait bien. Mesure qualitative, dont la méthode dépend de la question 14. Valide FR-1 et FR-2.
- **SM-2. Effet recherché.** Des prises de contact et des entretiens où le site ou un cas est cité. [ASSUMPTION : mesure qualitative, sans analytics avancés en v1, reprise du brief ; les mentions sont relevées à la main, sans objectif chiffré.]

**Contrôles de conformité**
- **SM-3. Deux clics.** Depuis l'accueil, chaque cas mis en avant est atteint en un clic, et chaque page cas en deux clics au plus (même hypothèse que FR-15). *Mesure :* parcours des liens du site mis en ligne. Valide FR-2 et FR-15.
- **SM-4. Parité linguistique.** Le script de parité passe sur la version mise en ligne. Les commentaires de l'agent de parité éclairent la relecture sans conditionner la mise en ligne. Valide FR-20, FR-23 et FR-24.
- **SM-5. Aucune fuite.** Aucun push contenant un chemin privé ou un motif privé n'est accepté par la forge principale, et l'audit de tout l'historique est propre avant la première publication sur GitHub. Valide FR-28 et NFR-9.
- **SM-6. Aucun cookie.** Aucune page mise en ligne ne crée de cookie. Valide NFR-3 et FR-14.
- **SM-7. Édition sans code.** Les PR de contenu ne touchent que les fichiers listés par FR-25. *Mesure :* le diff des PR de contenu. Valide FR-25.
- **SM-8. Qualité mesurée.** Chaque gabarit de page mis en ligne satisfait WCAG 2.2 AA, les seuils « bons » des Core Web Vitals sur mobile et le budget de poids, sans JavaScript hors exception justifiée. Valide NFR-4, NFR-5 et NFR-12.

**Contre-indicateurs (à ne pas optimiser)**
- **SM-C1. Volume de contenu.** Le nombre de cas, de pages ou d'éléments de matériel vivant n'est pas un objectif : la valeur tient à la qualité et à la sincérité des cas. Contrebalance SM-1 et SM-2.
- **SM-C2. Lissage des limites.** Un cas ne gagne pas en attrait en taisant un non-aboutissement ou la limite d'une mesure (FR-10). Contrebalance SM-1.
- **SM-C3. Scores techniques.** Au-delà des cibles de NFR-4 et NFR-5, aucun outillage n'est ajouté pour gagner des points d'accessibilité ou de performance aux dépens de la maintenance minimale (NFR-7). Contrebalance SM-8.

## 11. Questions

### 11.1 Questions tranchées

| Date | Question | Décision | Intégrée dans |
|---|---|---|---|
| 13/09/2026 | Titre du site et pitch (question du brief) | Titre FR et EN retenus ; pitch de trois phrases sous le titre ; ancienneté : plus de dix-huit ans | FR-1, §1 |
| 13/09/2026 | Racine du domaine (ex-question 11) | Français à la racine, anglais sous `/en/` ; pas de redirection selon la langue du navigateur ; sélecteur de langue visible ; `hreflang` dans les deux langues | FR-21, §7 |
| 13/09/2026 | CI, PR et point de contrôle non contournable (ex-question 18) | Forge principale Gitea sur un homelab distinct du serveur de production (runners x86_64) : dépôt principal, PR, contrôles, build de l'image et déploiement. GitHub en miroir public en lecture seule, avec uniquement des contrôles, visibles publiquement, sans build ni déploiement. Garde-fou côté serveur (pre-receive Gitea) en plus du hook local. Corrigé le même jour (la première version plaçait toute la CI sur Gitea, sans contrôle sur GitHub) | FR-24, FR-28, NFR-2, NFR-8, NFR-11, §7 |
| 13/09/2026 | Mentions légales et frontière public/privé (reformulation de NFR-9) | Aucune information personnelle dans le dépôt ni son historique ; les mentions légales exigées par la loi apparaissent sur le site public, injectées au build par l'environnement, jamais commitées ; le build de production échoue s'il en manque une | NFR-9, FR-18 |
| 13/09/2026 | Contenu des mentions légales (ex-question 12) | Éditeur : identité, adresse de l'activité déclarée, contact, numéro d'immatriculation ; directeur de la publication : l'éditeur lui-même ; hébergeur : raison sociale, adresse et contact, repris de sa page légale officielle ; pas de numéro de TVA intracommunautaire. Valeurs injectées au build, jamais commitées (AD-9) | FR-18 |
| 13/09/2026 | Journaux du serveur dans la politique de confidentialité (ex-question 13) | Aucune IP journalisée sur toute la chaîne, reverse proxy compris : journal d'accès minimal sans IP, user-agent ni referer, journal d'erreurs au niveau `crit` ; la politique dit que l'éditeur ne collecte aucune donnée personnelle et renvoie à celle de l'hébergeur (AD-15) | FR-19 |
| 13/09/2026 | Langue du README-cas (ex-question 14) | Anglais | FR-30 |
| 13/09/2026 | Libellés anglais des encarts et des cadres (question 10, numéro conservé) | Libellés proposés par l'architecture et validés par Arnaud : *Engagement context* (« Contexte mission »), *At a glance* (« En bref ») ; cadres *Employee*, *Freelance*, *IT consultancy*, *Ton Pote le Geek* | FR-6, FR-7 |
| 13/09/2026 | Mesure des « trois lignes » de l'encart « En bref » (question 11, numéro conservé) | 3 phrases maximum et 400 caractères maximum par langue, vérifiables par script | FR-7, §3 |
| 13/09/2026 | Adresses des pages simples et des cas | FR : `/a-propos/`, `/contact/`, `/mentions-legales/`, `/confidentialite/`, cas sous `/cas/` ; EN : `/en/about/`, `/en/contact/`, `/en/legal-notice/`, `/en/privacy/`, cas sous `/en/cases/` | §4.2, FR-16 à FR-19 |
| 13/09/2026 | Décisions d'architecture citées en référence | Budget de poids chiffré et police système (AD-8), mise en ligne par tag (AD-14), agent de parité sur un modèle Sonnet, sur la forge principale seulement (AD-16), contrôle empêchant la mise en ligne de la page Chiliz sans le cas 02 (C15) | NFR-5, NFR-6, NFR-11, FR-9, FR-24, FR-32 |
| 13/09/2026 | Exposition publique de la forge principale | Écartée : le dépôt Gitea reste privé et n'est jamais exposé publiquement, faute de disponibilité garantie du homelab et pour limiter la surface exposée. Le dépôt public reste le miroir GitHub | §3, §6, §7 |
| 13/09/2026 | Accessibilité et performance (ex-question 17) | Zéro JavaScript en v1 dans la mesure du possible, exceptions justifiées ; WCAG 2.2 AA ; Core Web Vitals « bons » sur mobile (LCP ≤ 2,5 s, CLS ≤ 0,1, INP ≤ 200 ms) et budget de poids par page ; outillage laissé à l'architecture | NFR-4, NFR-5, NFR-12, SM-8, §7 |
| 13/09/2026 | Affichage d'un élément « prévu » (ex-question 5) | Invisible en production tant qu'il est « prévu », visible dans le rendu de travail ; le texte d'un cas se lit sans son matériel vivant | FR-12, FR-26 |
| 13/09/2026 | Critère de mise en ligne (ex-question 21) | Socle d'abord (accueil, à propos, contact, pages légales, cas 01, 02 et 05), puis cas 03, 04 et 06 un par un ; page Chiliz correcte avec la seule section du cas 02 | FR-9, FR-32, §9 |

Les mentions « ex-question N » renvoient à la numérotation des versions antérieures de la liste, avant son gel ; « numéro conservé » renvoie à la numérotation figée du §11.2.

### 11.2 Questions ouvertes

Chaque question indique les exigences qu'elle touche et ce qu'elle bloque. Aucune n'est tranchée par ce PRD.

La numérotation de 1 à 14 est figée, car l'architecture y renvoie. Une question tranchée garde son numéro : elle reste à sa place, barrée, avec la mention « tranchée le JJ/MM/AAAA, voir §11.1 ». Les autres questions ne sont jamais décalées.

**Reprises du brief**

1. **Matériel vivant en v1.** Quels schémas, vidéos et extraits sont livrés en v1 ? *Impact :* FR-12, FR-13, FR-14, FR-27, et le nombre de stories consacrées au matériel vivant. Sans réponse, tous les éléments restent « prévus », donc invisibles en production. *Bloque :* les stories de schémas et de vidéos.
2. **Période et cadre des cas 01, 03, 04, 05 et 06.** Les sources ne les donnent pas ; le cadre du cas 01 est connu, et le cas pilote 02 a les siens. *Impact :* FR-6, FR-26 et FR-32 : tant qu'ils manquent, le cas reste un brouillon. *Bloque :* la mise en ligne du socle (cas 01 et 05), puis celle des cas 03, 04 et 06.
3. **Contenu des vidéos.** Il n'est pas défini. *Impact :* FR-14 et FR-12 (statut et URL des vidéos). *Bloque :* les stories de vidéos.
4. **Signature unique, cas 02 et cas 03.** La source du cas 02 présente le cas 03 comme une signature unique, alors que le cas 03 dit que cette signature a été abandonnée. Le cas pilote 02 n'en parle pas ; la correction de la source reste à confirmer et à appliquer. *Impact :* cohérence de FR-10. *Bloque :* la rédaction du cas 03.

**Relevées à la rédaction du PRD**

5. **Stack du cas 03.** Le cas ne nomme aucune technologie, seulement des patterns ; elle reste à compléter par Arnaud (`data/stack.yaml` la note en attente). Quelles technologies retenir, sachant que la règle « seules les technologies citées dans le cas » oblige alors le texte du cas à les citer ? *Impact :* FR-6 et FR-26. *Bloque :* la mise en ligne du cas 03.
6. **Accès aux cas non mis en avant.** Par une liste des cas, par un menu, ou autrement ? `docs/format-cas.md` évoque une « liste des cas » que le brief ne compte pas parmi les pages. *Impact :* FR-15 et SM-3. *Bloque :* l'architecture (navigation) et la mise en ligne du premier des cas 03, 04 et 06.
7. **Informations affichées pour un cas mis en avant.** Au-delà du titre du cas, l'accueil affiche-t-il l'encart « En bref », la stack, ou autre chose ? *Impact :* FR-2. *Bloque :* la story de l'accueil.
8. **Emplacement de la mention de l'activité parallèle.** Le brief dit « accueil et/ou à propos ». *Impact :* FR-4. *Bloque :* les stories de l'accueil et de la page « À propos ».
9. **Titre et introduction de la page Chiliz.** Les sources ne donnent ni l'un ni l'autre. La page a-t-elle un titre seul, ou aussi une introduction ? *Impact :* FR-9 et NFR-10. *Bloque :* la story de la page Chiliz.
10. ~~**Libellés anglais des encarts et des cadres.**~~ Tranchée le 13/09/2026, voir §11.1.
11. ~~**Mesure des « trois lignes » de l'encart « En bref ».**~~ Tranchée le 13/09/2026, voir §11.1.
12. **Étape UX.** La chaîne prévue (brief, PRD, architecture, stories) ne comporte pas d'étape UX. Qui tranche la mise en page sobre (NFR-6), la navigation (question 6) et le contenu des cas mis en avant (question 7) : une étape UX légère, l'architecture, ou Arnaud avant chaque story ? *Bloque :* l'organisation de la suite de la chaîne.
13. **Contenu de la v1.1.** Les entrées n'en donnent aucun. Les éléments renvoyés à « plus tard » (façade vidéo, taxonomie par technologie, matériel vivant non livré en v1) ne sont affectés à aucune version. *Impact :* §8.2. *Bloque :* rien en v1.
14. **Méthode du test des trente secondes.** Qui passe le test, et comment ? *Impact :* SM-1. *Bloque :* rien avant la mise en ligne.

**Contenus à fournir par Arnaud** (des entrées manquantes, pas des décisions)

- L'adresse mail et l'URL LinkedIn (FR-17).
- L'URL du site de Ton Pote le Geek (FR-4).
- L'URL du dépôt public (FR-29).
- La ligne de contexte EN sur April Technologies (FR-22).

## 12. Index des hypothèses

- §3 Glossaire, « Contenu » : les sources D2 font partie du contenu.
- §4.1 FR-3 : l'appel à contact mène à la page Contact.
- §4.2 FR-10 : l'encart « En bref » du cas 03 dit aussi qu'il n'est pas allé en production.
- §4.2 FR-15 (et SM-3) : le critère des deux clics vaut pour tous les cas.
- §4.5 FR-18 et FR-19 : les pages légales sont accessibles depuis chaque page.
- §4.6 FR-21 : le sélecteur de langue mène à la page équivalente, et sur la page Chiliz, à la page Chiliz de l'autre langue.
- §4.6 FR-23 : le script de parité fait échouer la CI.
- §4.7 FR-27 : une source D2 sans SVG, ou un SVG sans source, fait échouer la CI.
- §10 SM-2 : effet recherché mesuré de façon qualitative, par un relevé manuel sans objectif chiffré.
