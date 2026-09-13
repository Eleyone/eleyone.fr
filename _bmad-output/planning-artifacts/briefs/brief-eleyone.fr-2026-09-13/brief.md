---
title: "Brief produit : eleyone.fr"
status: validated
created: 2026-09-13
updated: 2026-09-13
---

# Brief produit : eleyone.fr

## Résumé

eleyone.fr est le portfolio et le CV en ligne d'Arnaud (Eleyone), développeur backend senior : vingt ans de PHP, surtout Symfony. Il l'envoie aux recruteurs pour une recherche de poste ou de mission freelance avant avril 2027, en France et à l'international.

Arnaud ne vend plus la vitesse à laquelle il écrit du code. Il vend du jugement : savoir quoi construire, quand, à quel coût, et ce qui casse si on se trompe. Un CV le montre mal, parce qu'il liste des technologies et des années. Le site montre ce jugement à travers des cas réels, racontés avec leurs arbitrages, leurs limites et ce qui n'est pas allé au bout.

Le site est statique, bilingue FR/EN (deux versions complètes) et sobre. Son code source est public, et son README est lui-même un cas : un lecteur peut voir ce qu'Arnaud sait faire, et aussi comment le site a été cadré puis construit.

## Le problème

- **Pour le lecteur (CTO, tech lead, recruteur tech).** Il cherche un développeur backend senior fiable, qui travaille avec l'IA. Un CV ne lui dit pas comment le candidat décide sous contrainte : face à un legacy, à un calcul financier ou à une base qu'on ne peut pas toucher.
- **Pour Arnaud.** Ce qui le distingue ne tient pas dans une ligne de CV : partir du minimum, décider sur le coût et le mode de défaillance, valider un chiffre face à une référence, reprendre un sujet sans écraser celui qui le portait. Aujourd'hui, ces preuves n'existent que dans des notes privées.
- **Pour le lecteur international.** Certains repères parlent à un lecteur français, mais pas à un lecteur étranger (par exemple April, un assureur français). Sans lignes de contexte, un cas perd sa force.

## La solution

Un site court, organisé autour des preuves :

- **Accueil.** Un titre, une phrase de positionnement, trois cas mis en avant (cas 01, « Calculette de rentabilité » ; cas 02, « Chiliz, source de vérité » ; cas 05, « Orange, performance ») et un appel à contact.
- **Pages cas.** Chaque page suit le même ordre :
  1. un encart **« Contexte mission »** : société, cadre (salarié, freelance, ESN ou Ton Pote le Geek), rôle, période, stack ;
  2. un encart **« En bref »** : l'enjeu puis le résultat, en trois lignes lisibles par un dirigeant ;
  3. le cas complet, au niveau CTO : contexte, problème, la solution facile et pourquoi elle a été écartée, ce qui a été fait, ce qui a résisté, résultat, ce que ça montre.

  Il n'y a pas de bascule entre deux versions : un texte par cas et par langue. Les trois cas Chiliz (02, 03, 04) partagent une page à plusieurs sections. Le cas 01 a été réalisé dans le cadre de Ton Pote le Geek, et sa page l'indique. Chaque cas prévoit une place pour son matériel vivant (schéma, lien vidéo, extrait).
- **À propos.** Le positionnement, condensé : ce qu'Arnaud fait bien, ce qu'il ne veut pas (manager, product owner, chef de projet), et comment il travaille aujourd'hui (Claude Code au quotidien, certification Claude en préparation).
- **Activité parallèle.** La présentation (accueil et/ou à propos) mentionne une activité d'automatisation pour TPE/PME, avec un lien vers Ton Pote le Geek. Elle n'est pas développée sur ce site.
- **Contact.** Adresse mail et LinkedIn, sans formulaire.
- **Pages légales.** Mentions légales et politique de confidentialité, statiques. Avec des liens YouTube simples, la politique de confidentialité reste minimale.
- **Dépôt GitHub public, lié depuis le site** (« voir ce que je sais faire et comment j'en suis arrivé là »). Son README est un cas vivant destiné à un CTO ou un tech lead, avec la même structure que les cas. Exemple de « ce qui a résisté » : l'historique git initial contenait des sources privées, repérées avant publication ; l'historique a été réécrit et un garde-fou non contournable a été ajouté.

## Ce qui distingue ce site

- **Des décisions, pas des listes.** Chaque cas dit ce qui a été écarté et pourquoi (par exemple le batch atomique écarté au cas 03, « Chiliz, batch de transactions »).
- **L'honnêteté sur les limites.** Un sujet arrivé en test sans aller en production est présenté tel quel. Les limites d'une mesure sont nommées (cas 05).
- **Le processus visible.** Le dépôt public contient les artefacts de cadrage BMAD, et son README raconte la construction comme un cas. La manière de travailler (cadrer avant de construire, avec l'IA dans la boucle) se vérifie au lieu de s'affirmer.
- **L'IA intégrée dans les outils.** La parité FR/EN est vérifiée en partie par un agent IA consultatif dans la CI : le positionnement est appliqué au site lui-même.
- **Le bon outil pour le besoin.** Le choix technique du site (générateur statique, scripts simples, sans framework lourd) est lui-même un exemple du jugement mis en avant.

Il n'y a pas d'avantage concurrentiel durable à revendiquer. La valeur tient à la qualité et à la sincérité des cas.

## Pour qui

- **Cible principale : CTO, tech lead, recruteur tech**, en France ou à l'international. Il veut comprendre vite ce que fait bien le candidat, puis vérifier sur un cas concret. Il lit en français ou en anglais.
- **Lecteur du dépôt GitHub.** Souvent le même profil, qui veut voir le code et le cadrage. Le README l'accueille comme une seconde page d'accueil.
- **Lecteur non technique.** Un dirigeant peut s'arrêter à l'encart « En bref », mais le site ne lui est pas destiné. L'offre TPE/PME est portée par Ton Pote le Geek.

## Critères de succès

- **Test des trente secondes.** Après trente secondes sur l'accueil, un CTO ou un recruteur peut dire ce qu'Arnaud fait bien.
- **Deux clics.** Depuis l'accueil, une preuve concrète (une page cas) est accessible en deux clics au plus.
- **Parité linguistique.** Chaque page existe en français et en anglais, avec le même contenu. Un script en CI vérifie ce qui est mécanique (page EN pour chaque page FR, mêmes métadonnées, même stack, mêmes schémas). Un agent IA consultatif signale ce qu'un script ne voit pas (phrase disparue, chiffre modifié d'un seul côté).
- **Édition sans code.** Modifier un cas revient à éditer du Markdown, sans toucher aux gabarits ni aux scripts.
- **Maintenance minimale.** Le build se reproduit avec des scripts simples. Il n'y a ni base de données, ni backend, ni dépendance lourde à suivre.
- **Aucune fuite.** Le contrôle de contenu privé porte sur tout l'historique et s'exécute avant chaque publication sur GitHub.
- **Pas de bandeau de consentement.** Les vidéos sont de simples liens : aucune ne dépose de cookie YouTube sur le site.
- **Effet recherché** [ASSUMPTION : mesure qualitative, pas d'analytics avancés en v1]. Des prises de contact et des entretiens où le site ou un cas est cité.

## Périmètre

**Dans la v1 :** accueil, pages cas (01, page Chiliz 02-03-04, 05, 06) avec leurs encarts « Contexte mission » et « En bref », à propos, contact, mentions légales, politique de confidentialité, en français et en anglais ; emplacements prévus pour le matériel vivant ; liens vers le dépôt GitHub et vers Ton Pote le Geek ; README du dépôt rédigé comme un cas.

**Hors v1 et hors v1.1 :** page offre TPE/PME (tranché le 13/09/2026).

**Hors v1 :** blog, espace client, formulaire de contact, analytics avancés, intégration de vidéos dans les pages, bandeau de cookies, taxonomie des cas par technologie (piste pour plus tard), publication des cas bruts.

## Contraintes et décisions déjà prises

- **Architecture.** Site statique généré par Hugo, sans base de données ni backend. Le résultat est servi par un conteneur nginx, sur l'infrastructure Docker existante, derrière le reverse proxy. Scripts simples plutôt qu'un outillage lourd dans la CI ou les images Docker ; pas de Symfony ni de React.
- **Schémas.** D2, une structure commune et un point d'entrée par langue ; SVG commités, avec une vérification de régénération en CI (détail dans l'addendum).
- **Vidéos.** Simples liens vers des vidéos YouTube non répertoriées, sans intégration dans la page.
- **Contenu.** Markdown. Le contenu reprend les cas existants en les reformulant le moins possible. Rien n'est inventé : ni cas, ni chiffre, ni client, ni technologie. La stack d'un cas ne cite que les technologies nommées dans ce cas, avec les mêmes noms en FR et en EN. Les passages encore entre crochets dans les sources restent en attente et ne sont pas publiés comme des faits.
- **Agent IA de parité.** Consultatif : il commente la PR et ne bloque jamais le build. Il ne tourne que si du contenu change. Sa clé d'API est un secret GitHub non exposé aux PR venant de forks. Le choix de l'outil revient à l'architecture.
- **Design.** Sobre, professionnel et lisible, sans effets. Accessibilité et performance correctes par défaut.
- **Frontière public/privé.** Le dépôt est public : les sources brutes et les informations personnelles n'y entrent jamais. Les artefacts publics citent les cas par leur numéro et leur titre court.

## Questions tranchées le 13/09/2026

| Question | Réponse |
|---|---|
| Page offre TPE/PME | Pas de page, ni en v1 ni en v1.1 ; mention de l'activité et lien vers Ton Pote le Geek ; cas 01 rattaché à Ton Pote le Geek. |
| SVG générés | Commités, avec vérification de régénération en CI. |
| D2 et bilinguisme | Testé : une structure à libellés variables, un point d'entrée par langue, rendu reproductible à l'octet près. |
| Vidéos et consentement | Simples liens YouTube, sans iframe ni bandeau de cookies ; la façade reste possible plus tard. |
| README du dépôt | Un cas vivant, avec la structure des cas. |
| Parité FR/EN | Script en CI et agent IA consultatif. |
| Versions CTO et dirigeant | Fusionnées : « Contexte mission », « En bref », puis cas complet. |
| Pages légales | Mentions légales et politique de confidentialité en v1. |

## Questions ouvertes

1. **Titre et pitch.** Lesquels, parmi les propositions du noyau narratif, sont retenus en français et en anglais ? Le 3e titre proposé vise les PME, ce qui se discute maintenant que l'activité Ton Pote le Geek n'est qu'une mention.
2. **Matériel vivant en v1.** Quels schémas, vidéos et extraits sont livrés en v1 ? Des emplacements sont prévus dans tous les cas.
3. **Période et cadre de chaque cas.** Les sources ne les donnent pas. Ils restent entre crochets dans l'encart « Contexte mission », à compléter par Arnaud (voir l'addendum).
4. **Contenu des vidéos.** Il n'est pas encore défini.
5. **Signature unique, cas 02 / cas 03.** La source du cas 02 présente le cas 03 comme une signature unique, alors que le cas 03 dit qu'elle a été abandonnée. La source du cas 02 est à corriger.
6. **Encart « Contexte mission » sur la page Chiliz** [relevée à la rédaction]. Un encart par section, ou un encart commun aux trois cas ? À préciser au PRD.

## Suite

Le PRD (v1 puis v1.1) fixe les pages, la structure de contenu et les critères d'acceptation, sans rien ajouter au-delà de ce périmètre. En parallèle, un **cas pilote** est rédigé au format `docs/format-cas.md` : le cas 02 (Chiliz, source de vérité), en français et en anglais, choisi parce qu'il exerce le plus de mécanismes (regroupement Chiliz, mise en avant sur l'accueil, matériel vivant, ligne de contexte anglaise). L'architecture est validée sur ce pilote avant la rédaction des autres cas. Viennent ensuite l'architecture (structure du dépôt, chaîne de build, métadonnées des cas, outil de l'agent de parité), puis des stories courtes livrées une par une. Le détail technique, le contenu connu des encarts « Contexte mission » et le matériel vivant par cas sont dans `addendum.md`.
