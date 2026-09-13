---
title: "Réconciliation PRD / entrées : eleyone.fr"
created: 2026-09-13
scope: prd.md (draft du 13/09/2026) confronté au brief, à l'addendum, à docs/format-cas.md, au journal de décisions du brief et à la décision tardive sur le titre et le pitch
---

# Réconciliation du PRD avec ses entrées

Légende : **[MANQUE]** l'entrée dit quelque chose que le PRD omet ou affaiblit ; **[EXCÈS]** le PRD affirme ce que les entrées ne soutiennent pas ; **[CONTRADICTION]** le PRD contredit une entrée ; **[HYPOTHÈSE DÉGUISÉE]** un `[ASSUMPTION]` qui tranche en réalité une décision. Gravité : haute, moyenne, basse.

## 1. Brief (`briefs/brief-eleyone.fr-2026-09-13/brief.md`)

### Manques

- **[MANQUE, moyenne] Les traits qui distinguent Arnaud.** Brief « Le problème », point Arnaud : partir du minimum, décider sur le coût et le mode de défaillance, valider un chiffre face à une référence, reprendre un sujet sans écraser celui qui le portait. Le PRD (§1, §2, FR-16) ne garde que « du jugement » en termes généraux. FR-16 exige de dire « ce qu'Arnaud fait bien » sans rattacher ce contenu à ces traits.
- **[MANQUE, moyenne] Le lecteur cherche quelqu'un « qui travaille avec l'IA ».** Brief « Le problème » et « Ce qui distingue ce site » (« cadrer avant de construire, avec l'IA dans la boucle », « se vérifie au lieu de s'affirmer »). Le §2.1 ne cite pas ce besoin du lecteur. Le §1 parle du processus visible sans mentionner l'IA dans la boucle. FR-30 et FR-31 n'exigent pas que le README ou les artefacts rendent visible ce mode de travail.
- **[MANQUE, moyenne] « Des décisions, pas des listes » affaibli.** Le brief dit « Chaque cas dit ce qui a été écarté et pourquoi ». FR-8 écrit « Chaque cas **qui en a une** présente la solution facile », ce qui rend la chose facultative. Le PRD s'aligne sur la possibilité d'omettre une section dans `format-cas.md`, sans relever que le brief en fait un trait distinctif.
- **[MANQUE, moyenne] Honnêteté sur les limites, cas 05.** Le brief dit « Les limites d'une mesure sont nommées (cas 05) ». Le PRD n'en fait aucune FR : seul SM-C2 le cite, comme contre-indicateur. Le cas 03 a FR-10, le cas 05 n'a pas d'équivalent testable.
- **[MANQUE, moyenne] Reformulation minimale.** Brief « Contraintes, Contenu » : « reprend les cas existants en les reformulant le moins possible ». NFR-10 ne garde que « rien n'est inventé ». Le §6 parle de « leur reformulation », sans dire qu'elle est minimale.
- **[MANQUE, basse] Garde-fou « non contournable ».** Brief « La solution », README. FR-28 et FR-30 disent seulement « garde-fou » : le caractère non contournable disparaît des exigences et des critères.
- **[MANQUE, basse] Échéance de la recherche.** Le Résumé du brief fixe une échéance à la recherche. Le PRD (§1) la supprime, alors qu'elle éclaire la question 18 (critère de mise en ligne) et le séquencement du §9.
- **[MANQUE, basse] Le bon outil comme preuve de jugement.** Le brief dit que le choix technique « est lui-même un exemple du jugement mis en avant ». §1 et NFR-7 reprennent le principe, mais aucune exigence (README-cas, FR-30) ne demande que ce choix soit raconté comme une décision.

### Excès

- **[EXCÈS, moyenne] Le §6 fait de décisions « hors v1 » des non-objectifs permanents.** « Le site n'est pas une application : ni espace client, ni formulaire, ni backend » et « ne mesure pas son audience au-delà de l'effet qualitatif ». Or le brief classe espace client, formulaire et analytics avancés en **hors v1** (et le §8.4 du PRD aussi). Le brief exclut les analytics *avancés*, pas toute mesure, et la mesure qualitative y est une `[ASSUMPTION]`.
- **[EXCÈS, moyenne] SM-3 transforme l'agent de parité en porte de publication.** « Chaque commentaire de l'agent de parité est traité (corrigé ou justifié) avant publication. » Le brief dit que l'agent est consultatif et « ne bloque jamais le build ». Cette règle de process n'est pas dans les entrées.
- **[EXCÈS, moyenne] §8.1 : « les mécanismes de FR-13, FR-14 et FR-27 sont en v1 ».** Le périmètre v1 du brief ne contient que des « emplacements prévus pour le matériel vivant ». Mettre en v1 la chaîne D2 et la vérification en CI, alors qu'aucun élément ne sera peut-être « prêt » (question 1 du PRD), est une décision de périmètre non prise.
- **[EXCÈS, basse] NFR-7 durcit « dépendance lourde » en « aucun arbre de dépendances à suivre ».** Le brief dit « ni dépendance lourde à suivre ». L'absence d'arbre de dépendances est une raison du choix de Hugo (addendum), pas une règle pour toute la chaîne. La règle « tout outil ajouté doit être justifié » est aussi ajoutée. Elle peut entrer en tension avec l'outil de l'agent de parité, que le §7 laisse à l'architecture.
- **[EXCÈS, basse] NFR-3 et FR-19 : « aucun cookie » pour tout le site.** Le brief parle de l'absence de cookie YouTube et de bandeau. L'extension à tout cookie est cohérente, mais non formulée. FR-14 interdit en plus toute ressource « Google », ce qui dépasse YouTube (polices, par exemple).
- **[EXCÈS, basse] NFR-6 ajoute « sans gabarit agence » et « aucun carrousel ».** L'esprit est fidèle (« sobre, professionnel et lisible, sans effets »), mais le test est inventé.

### Contradictions

- **[CONTRADICTION, moyenne] Question 4 du PRD (signature unique).** Le brief (question 5) dit « La source du cas 02 est à corriger », et l'addendum la range dans « Corrections à apporter aux sources ». Le sens est donc fixé : le cas 03 fait foi. Le PRD écrit « À trancher avant de finaliser le cas pilote », ce qui rouvre le sens de la correction.
- **[CONTRADICTION, basse] SM-2 et FR-15 face au critère « Deux clics ».** Le brief parle d'« une preuve concrète (une page cas) accessible en deux clics au plus ». Le PRD en fait « chaque page cas en deux clics ». C'est bien marqué `[ASSUMPTION]` dans FR-15, mais SM-2 l'énonce sans marque, comme un critère validé.

### Couverture correcte (pour mémoire)

Périmètre v1, hors v1, hors v1 et v1.1, pages légales, vidéos en liens, agent consultatif, clé en secret, frontière public/privé et cas cités par numéro, encarts et ordre de page, page Chiliz, cas 01 rattaché à Ton Pote le Geek, cible et hors-cible, design sobre, cas pilote. Question 6 du brief résolue par le journal (un encart par section) et reprise dans FR-9.

## 2. Addendum (`briefs/brief-eleyone.fr-2026-09-13/addendum.md`)

### Manques

- **[MANQUE, haute] Corrections à apporter aux sources avant publication.** L'addendum signale un passage personnel à reformuler dans le contexte du cas 01, et la mise à jour « April » → « April Technologies » de la source du cas 06. Le PRD ne reprend ni l'une ni l'autre comme condition de publication (FR-26, NFR-9, §9, §11).
- **[MANQUE, moyenne] Exécution du garde-fou déjà fixée.** L'addendum, « Pages légales et contrôle public/privé », dit « Il tourne en hook local sur l'historique complet avant chaque push GitHub ; un hook côté serveur du miroir est prévu ». Le §7 et la note de FR-28 renvoient à l'architecture « l'endroit où tourne chaque contrôle (hook local, hook serveur, CI) ». Le PRD rouvre une décision prise.
- **[MANQUE, basse] Mermaid non retenu.** « Énoncés du brief initial remplacés » : Mermaid n'est pas retenu. Le §7 (« Décisions déjà prises ») ne le mentionne pas.
- **[MANQUE, basse] Détails D2 testés.** Version testée (v0.9.0) et option `--omit-version`, qui conditionne la reproductibilité à l'octet près. NFR-8 et §7 ne les citent pas. Ils sont utiles à l'architecture pour épingler la version.
- **[MANQUE, basse] README « générique ».** L'addendum dit « Le README reste générique et ne nomme aucun fichier privé ». FR-30 garde la seconde moitié, pas la première.
- **[MANQUE, basse] Indices de période « non publiés en l'état ».** Le PRD renvoie au tableau de l'addendum (FR-6), sans rappeler que ces indices ne sont pas publiables tant qu'Arnaud ne les a pas confirmés. FR-26 le couvre indirectement.
- **[MANQUE, basse] Ligne de contexte Orange.** L'addendum précise que l'époque se situe par les commerciaux terrain en 3G ou au début de la 4G. FR-22 ne cite qu'« Orange (cas 05) ». C'est acceptable si le renvoi à l'addendum suffit.

### Excès

- **[EXCÈS, moyenne] FR-27 impose la version de D2 épinglée.** Pour l'addendum, ce n'est qu'une « Recommandation, à confirmer par l'architecture » (ELK, thème, version épinglée en CI). FR-27 l'écrit comme une conséquence testable, alors que le §7 la range parmi les points « à décider par l'architecture ». C'est aussi une incohérence interne.
- **[EXCÈS, basse] FR-28 : « Un commit qui ajoute… est refusé ».** Les entrées parlent d'un contrôle de l'historique avant push et d'un hook serveur, pas d'un refus au commit. Le refus au commit vient d'`AGENTS.md` (hook local), pas des quatre entrées. « La liste des motifs privés n'est jamais versionnée » vient aussi d'`AGENTS.md`. C'est fidèle au dépôt, mais cette source n'est pas citée.
- **[EXCÈS, basse] Question 16 et §7 : « dépôt principal auto-hébergé ».** Les entrées ne mentionnent qu'un « miroir ». Le fait vient d'`AGENTS.md`, source non citée au §0.
- **[EXCÈS, basse] FR-24 : « sur une PR venant d'un fork, l'agent ne tourne pas ».** L'addendum dit seulement que la clé n'est pas exposée aux forks. Ne pas lancer l'agent en est une conséquence probable, mais c'est une décision non marquée.

### Contradictions

- **[CONTRADICTION, basse] Stack en métadonnée : « piste pour plus tard (hors v1) » dans l'addendum.** Le PRD (glossaire, FR-6, FR-23) en fait le fonctionnement de la v1, avec vocabulaire contrôlé. C'est cohérent avec `format-cas.md`, postérieur (journal, ligne 42). Seule la taxonomie reste hors v1, comme le dit le §8.4. Pas d'action, sinon une phrase de traçabilité.

## 3. Contrat de format (`docs/format-cas.md`)

### Manques

- **[MANQUE, moyenne] Voix : « Reformulation minimale des sources, à la première personne »** (règle 2). Aucune FR ni NFR ne fixe la première personne ni la reformulation minimale. Le PRD cite les titres de section à la première personne (UJ-1), sans en faire une règle.
- **[MANQUE, moyenne] « L'anglais n'est pas une traduction littérale »** (règle 3). FR-20 dit « avec le même contenu », ce qui peut se lire comme une traduction littérale. Le §4.6 dit seulement que l'anglais n'est « pas un sous-ensemble ». FR-24 (phrase disparue d'un côté) devrait tolérer les lignes de contexte ajoutées en EN.
- **[MANQUE, basse] Règle 6 générale.** « Un sujet jamais mis en production le reste explicitement dans le texte » vaut pour tout cas. FR-10 la limite au cas 03.
- **[MANQUE, basse] Sections des sources non publiées.** Statut du brouillon, notes « à traiter séparément », « Les deux dialectes ». FR-26 ne couvre que brouillons et TODO, sans mentionner les notes « à traiter séparément ».
- **[MANQUE, basse] Titre ≤ 70 caractères, « pas de mois inventé » pour la période.** Non repris. C'est acceptable, puisque le PRD renvoie au contrat, mais ces règles ne sont pas testées.

### Excès

- **[EXCÈS, moyenne] FR-7 : « ni sigle non expliqué, ni nom de technologie ».** Le contrat dit « Pas de jargon ». Interdire tout nom de technologie ou de plateforme dans « En bref » est plus strict, et pourrait gêner le cas 01 (Systeme.io) ou le cas 04 (Fireblocks).
- **[HYPOTHÈSE DÉGUISÉE, moyenne] FR-7 : « trois lignes » comptées en phrases.** Le contrat et le brief disent « trois lignes au plus ». Trois phrases longues peuvent faire six lignes : l'hypothèse change une contrainte validée au lieu de l'interpréter.

### Contradictions

- **[CONTRADICTION, basse] Statut du contrat.** Le §0 du PRD le présente comme l'un des « trois documents validés le 13/09/2026 ». Son front matter indique `version: 0.1`, `status: draft`. Le §9 prévoit bien qu'il soit ajusté après le pilote : il faut aligner le statut ou la formulation.

### Couverture correcte (pour mémoire)

Un fichier par cas et par langue, assemblage de la page Chiliz par `group` et `order`, métadonnées non traduites contrôlées par le script (FR-23), titres de niveau 2 et ordre (FR-8), sections identiques FR/EN, « Contexte » sans répétition de l'encart (FR-6), matériel vivant déclaré et placé (FR-12), `[TODO: …]` et `draft` (FR-26), vocabulaire de la stack, aucun code propriétaire (NFR-10), aucune information personnelle (NFR-9), emplacement et nommage des fichiers laissés à l'architecture (§7).

## 4. Journal de décisions du brief (`.memlog.md`)

### Manques

- **[MANQUE, moyenne] Question 6 du PRD (stack du cas 03) déjà tranchée.** Journal, ligne 35 : « uniquement les technologies citées dans le cas, **sinon [à compléter]** ». Ligne 40 : « stacks relevées validées telles quelles », et le tableau de l'addendum met « [à compléter] » pour le cas 03. Le PRD rouvre le choix entre liste vide et marqueur TODO. Il reste une vraie question : un marqueur qu'aucune source ne pourra combler bloque le cas 03 en brouillon pour toujours. Il faut la reformuler dans ce sens, sans la présenter comme non tranchée.
- **[MANQUE, moyenne] Cas 01 : le client peut être nommé, et un passage personnel est à reformuler** (ligne 26). Le PRD ne reprend ni l'autorisation de nommer le client, ni la reformulation comme condition de publication (voir aussi l'addendum).
- **[MANQUE, basse] Échéance de la recherche** (ligne 8). Absente du §1 (voir brief).
- **[MANQUE, basse] Mesure qualitative marquée `(assumption)`** (ligne 17). SM-7 la dit « hypothèse reprise du brief », mais sans marque `[ASSUMPTION]` et sans entrée au §12. Le §6 la transforme ensuite en non-objectif ferme.

### Excès

- **[EXCÈS, basse] §9 : « Avant chaque story, l'agent reformule ce qu'il a compris et pose ses questions ».** C'est absent du journal et du brief. Cela vient d'`AGENTS.md` : c'est fidèle, mais la source n'est pas citée.

### Contradictions

- Aucune contradiction franche. Les décisions du journal (bilingue complet, Hugo et nginx, D2 par langue, page Chiliz avec un encart par section, SVG commités, vidéos en liens, parité à deux niveaux, README-cas, pages légales, pilote 02 avant les onze autres fichiers) sont reprises.

## 5. Décision tardive : titre et pitch

- **[CONTRADICTION, basse] FR-1 : « Son libellé peut encore être retouché à la marge ».** Le titre est tranché en FR et en EN. Cette réserve affaiblit la décision sans appui dans les entrées.
- **[EXCÈS, basse] Glossaire « Pitch » : « qui disent ce qu'Arnaud vend et ce que les cas prouvent ».** La décision fixe la structure (trois phrases sous le titre, FR et EN). Décrire ce que disent les phrases est une spécification de contenu non fournie. FR-1 respecte bien la consigne (structure seule, texte non recopié).
- **Conforme.** Le titre FR est exact, le pitch fait trois phrases FR/EN au même contenu, et la question 1 du brief ne figure plus au §11. Le titre EN et l'ancienneté ont été corrigés après les entrées (décision tardive) : le PRD doit être aligné sur cette correction, qui n'est pas un écart avec le brief.

## 6. Hypothèses du §12 qui tranchent en réalité

- **FR-21, sélecteur vers la page équivalente.** Le glossaire (« Sélecteur de langue : mène à la même page ») et UJ-2 l'énoncent déjà comme un fait. L'hypothèse est donc déjà une décision dans le document.
- **FR-7, lignes comptées en phrases.** Elle modifie une contrainte validée (voir §3).
- **FR-15, deux clics pour tous les cas.** Elle durcit un critère de succès du brief, et SM-2 la reprend sans marque.
- **FR-23, script de parité bloquant.** C'est plausible, mais c'est un choix de politique de CI que le brief ne fait pas. À faire confirmer.
- **FR-16 (non marqué) : « Chaque affirmation sur une compétence renvoie à un fait présent dans un cas ».** C'est une règle inventée, et elle contredit le contenu que FR-16 exige lui-même : aucune source de cas ne porte la certification Claude en préparation, ni l'ancienneté citée au §1.
