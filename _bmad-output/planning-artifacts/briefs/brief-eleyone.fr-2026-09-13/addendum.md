---
title: "Addendum au brief produit : eleyone.fr"
status: validated
created: 2026-09-13
updated: 2026-09-13
---

# Addendum au brief produit : eleyone.fr

Ce document rassemble le détail qui n'a pas sa place dans le brief mais sert au PRD et à l'architecture.

## Inventaire des cas et de leur page

| Cas | Titre court | Page du site | Mis en avant sur l'accueil |
|---|---|---|---|
| 01 | Calculette de rentabilité | page dédiée | oui |
| 02 | Chiliz, source de vérité | page Chiliz, section 1 | oui |
| 03 | Chiliz, batch de transactions | page Chiliz, section 2 | non |
| 04 | Chiliz, reprise d'un sujet en dérive | page Chiliz, section 3 | non |
| 05 | Orange, performance | page dédiée | oui |
| 06 | April, hors périmètre | page dédiée | non |

Point de vigilance pour la page Chiliz : le cas 03 n'est jamais allé en production et doit rester présenté comme tel, à côté de deux cas livrés.

## Encart « Contexte mission » : contenu connu

Champs : société, cadre (salarié, freelance, ESN ou Ton Pote le Geek), rôle, période, stack. Ce qui manque reste entre crochets, à compléter par Arnaud.

| Cas | Société | Cadre | Rôle (d'après la source) | Période | Stack |
|---|---|---|---|---|---|
| 01 | Institut Lionne | Ton Pote le Geek | conception, développement et hébergement de l'application | [à compléter] | Symfony, PostgreSQL, Docker Compose, Systeme.io, Claude Code |
| 02 | Chiliz | [à compléter] | développeur back dans une équipe de quatre à cinq : documentation d'implémentation, découpage de l'epic, ownership de l'implémentation | [à compléter] | PHP, Symfony, Symfony UX, Twig, Redshift |
| 03 | Chiliz | [à compléter] | conception du chaînage asynchrone des transactions | [à compléter] | [à compléter] |
| 04 | Chiliz | [à compléter] | reprise de l'ownership du sujet d'un développeur junior et refonte du process | [à compléter] | Fireblocks |
| 05 | Orange | [à compléter] | expert Zend Framework, tech lead de fait en l'absence de tech lead | [à compléter] | PHP, Zend Framework, Oracle, Xdebug |
| 06 | April Technologies (selon Arnaud ; la source dit « April ») | [à compléter] | développeur front Symfony 1.3, puis features de bout en bout | [à compléter] | Symfony 1.3, Java, SOAP |

Le cadre du cas 01 vient de la réponse d'Arnaud du 13/09/2026, pas de la source.

**Règle de la stack.** Seules les technologies citées dans le cas concerné y figurent, sans rien déduire du profil général ni d'un autre cas. Les noms sont identiques en FR et en EN, pour que le script de parité puisse comparer les listes. Choix faits en appliquant cette règle, validés par Arnaud le 13/09/2026 :

- **Cas 01.** n8n et Stripe sont cités pour d'autres automatisations de la cliente, pas pour la calculette : ils sont exclus.
- **Cas 02.** Python est cité comme point de départ abandonné du projet : il est exclu.
- **Cas 03.** Seuls des patterns sont cités (outbox, worker, listener), aucune technologie nommée.
- **Cas 04.** Même application que le cas 02, mais seul Fireblocks est cité dans le cas.
- **Cas 06.** REST est cité comme alternative émergente, non utilisée : il est exclu.

**Indices de période présents dans les sources**, à confirmer et non publiés en l'état :

- cas 01 : 2025–2026 d'après la synthèse des cas ;
- cas 02 : de septembre à fin février, année non précisée ;
- cas 04 : de décembre à mars, année non précisée ;
- cas 05 : il y a plus de dix ans ;
- noyau narratif : quatre ans chez Chiliz.

**Piste pour plus tard (hors v1).** Pour le PRD et l'architecture : stocker la stack comme champ de métadonnées (front matter, sous forme de liste) plutôt que dans le texte, avec un vocabulaire contrôlé (une seule écriture par technologie). Hugo pourrait en tirer une taxonomie, c'est-à-dire la liste des cas par technologie.

## Matériel vivant prévu par les sources

Aucun des éléments ci-dessous n'est encore produit ; leur présence en v1 est une question ouverte (question 2 du brief). Les vidéos sont de simples liens, et leur contenu reste à définir (question 4).

- **Cas 01.** Piste de vidéo de 60 à 90 s sur le parcours de calcul. Schéma de la création de compte automatique (Systeme.io → tag → webhook → compte → accès). Extrait d'un test unitaire sur le calcul du coût de revient.
- **Cas 02.** Schéma : blockchain → rapatriement en base → calcul cumulatif NCS/CS → application → réconciliation BI. Encart sur le calcul cumulatif à 18 décimales. Pseudo-code du rejeu d'historique (le code appartient à l'entreprise).
- **Cas 03.** Schéma : UX → outbox → worker d'envoi → chaîne → listener → mise à jour de la transaction → transaction suivante ou clôture du batch. Encart comparant le batch atomique et le chaînage. Pseudo-code de la boucle de chaînage.
- **Cas 04.** Schéma du process de création de pool avec les points de validation admin Fireblocks. Encart sur la fenêtre d'ownership. Pseudo-schéma de la table d'événements.
- **Cas 05.** Encart comparant méthodes magiques et accès direct, avec une micro-mesure reproductible. Schéma du périmètre (app CRV en lecture, base Oracle partagée, application d'écriture du SI). Extrait illustratif.
- **Cas 06.** Schéma du périmètre officiel face à la zone explorée (navigateur → front Symfony → SOAP → back Java). Encart sur les langages pratiqués et le niveau assumé pour chacun.

Contrainte transversale : aucun code propriétaire d'un client n'est publié. Seuls le pseudo-code et les extraits illustratifs le sont.

## Détail des contraintes techniques

- **Hugo.** Choisi pour son multilinguisme natif, son binaire unique et l'absence d'arbre de dépendances.
- **Chaîne de build.** Rendu D2 → SVG par langue (commités) → build Hugo → fichiers statiques → image nginx.
- **SVG commités.** Ils sont visibles sur GitHub. La CI les régénère et échoue s'ils diffèrent des fichiers commités.

### D2 bilingue (tranché le 13/09/2026, test fait avec D2 v0.9.0)

- **Organisation.** Chaque schéma est un fichier `structure.d2` dont les libellés sont des variables `${…}`. Deux points d'entrée, `fr.d2` et `en.d2`, déclarent les `vars` de leur langue puis importent la structure.
- **Reproductibilité.** Le rendu est identique à l'octet près, avec le moteur de mise en page ELK comme avec dagre, en utilisant l'option `--omit-version`. C'est ce qui rend viables les SVG commités.
- **Recommandation, à confirmer par l'architecture.** Le moteur ELK, un thème commun sobre (base Neutral Grey), et la version de D2 épinglée en CI.
- **Points de vigilance.** L'architecture arm64 n'a pas été testée. D2 ne fait pas de retour à la ligne automatique dans les libellés. Les fichiers générés sont écrits avec les droits 0600, ce qui compte pour le service nginx.

### Vidéos (tranché le 13/09/2026)

- **Retenu.** Un simple lien vers la vidéo YouTube non répertoriée, sans intégration dans la page : pas d'iframe, pas de bandeau de cookies.
- **Écarté : l'intégration directe.** Elle dépose des cookies Google dès le chargement de la page et exige donc un consentement.
- **Écarté : un bandeau de cookies.** C'est un script tiers à maintenir, et il apporte peu, puisque la vidéo ne peut de toute façon pas se charger avant le consentement.
- **Possible plus tard.** Une façade (vignette, puis iframe au clic).

### Parité FR/EN (tranché le 13/09/2026)

- **Script en CI.** Il vérifie ce qui est mécanique : chaque page FR a sa page EN, avec les mêmes métadonnées, la même stack et les mêmes schémas.
- **Agent IA consultatif.** Il signale ce qu'un script ne voit pas, comme une phrase disparue ou un chiffre modifié d'un seul côté. Il commente la PR sans jamais bloquer le build, et ne tourne que si du contenu change. Sa clé d'API reste un secret de CI, jamais exposé à des contributions externes ; la CI où il tourne est un choix d'architecture.
- **Outil de l'agent.** Son choix revient à l'architecture.

### Pages légales et contrôle public/privé

- **Pages légales.** Mentions légales et politique de confidentialité, statiques, en v1. Avec des liens YouTube simples, la politique de confidentialité reste minimale.
- **Contrôle public/privé.** Un script vérifie que ni les chemins interdits ni les motifs privés n'apparaissent. Il tourne en hook local, audite l'historique complet avant la première publication sur GitHub, et est prévu en hook pre-receive côté Gitea pour ne pas pouvoir être contourné.

## README du dépôt

Le README est un cas vivant pour un CTO ou un tech lead. Il reprend la structure des cas : contexte, problème, la solution facile et pourquoi pas, ce qui a été décidé, ce qui a résisté, résultat. Exemple de « ce qui a résisté » : l'historique git initial contenait des sources privées, repérées avant publication ; l'historique a été réécrit et un garde-fou non contournable a été ajouté. Le README reste générique et ne nomme aucun fichier privé.

## Lignes de contexte pour la version anglaise

Repères qui ont besoin d'une explication pour un lecteur international, relevés dans les cas :

- April Technologies (cas 06) : la source dit seulement « April, assureur » ; la ligne de contexte est à formuler avec Arnaud.
- Orange : opérateur télécom. Les commerciaux terrain en 3G ou début de 4G situent l'époque (cas 05).
- Systeme.io : plateforme utilisée pour vendre la formation (cas 01).
- NCS/CS : non-circulating supply et circulating supply (cas 02).
- Ton Pote le Geek : l'activité d'automatisation pour TPE/PME d'Arnaud (cas 01 et présentation).

## Corrections à apporter aux sources

- **Cas 02.** La note sur le cas 03 parle d'une signature unique ; le cas 03 dit qu'elle a été abandonnée (question 5 du brief).
- **Cas 06.** La société est « April Technologies » selon Arnaud ; la source dit seulement « April ».
- **Cas 01.** Le paragraphe de contexte contient une mention personnelle à reformuler avant publication.
- **Cas 01.** Le cadre (Ton Pote le Geek) est absent de la source.

## Énoncés du brief initial remplacés

- « Français uniquement » et « multilingue hors périmètre » : remplacés par un site bilingue FR/EN complet.
- Deux audiences, dont le dirigeant de TPE/PME en cible secondaire avec une page d'offre : l'audience principale est le CTO, le tech lead ou le recruteur tech. Il n'y a pas de page d'offre, seulement une mention et un lien vers Ton Pote le Geek.
- Cas en « version CTO » et « version dirigeant » séparées : fusionnées en « Contexte mission », « En bref » et cas complet.
- Recherche orientée « mission freelance ou poste » en France : élargie à l'international.
- Décisions ouvertes du brief initial : générateur (Hugo retenu), marque (portfolio sous eleyone.fr, Ton Pote le Geek seulement lié), cas Chiliz (une page), matériel vivant (D2 avec SVG commités, liens YouTube non répertoriés ; Mermaid n'est pas retenu).
