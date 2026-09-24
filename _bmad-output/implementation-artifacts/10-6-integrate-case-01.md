# Story 10.6 : Integrate case 01

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 10.6.

## Ce que la story a trouvé en arrivant

**Le cas était déjà écrit**, et sans aucun marqueur `[TODO` — contrairement au cas 05, dont trois
restaient ouverts. Q2 (« période et cadre des cas 01 et 05 ») était donc **déjà répondue dans le
fichier** pour celui-ci : `setup: "ton-pote-le-geek"` et `period: "2025–2026"`.

La période a tout de même été resserrée sur arbitrage d'Arnaud du 24/09/2026, qui a donné le début
réel — mai 2025 — et choisi une **période ouverte**, « depuis mai 2025 » / « since May 2025 » : l'outil
est toujours en production et en itération, ce que le corps du cas dit lui-même (quatre itérations,
transformation en produit en cours). Une période fermée aurait été fausse.

**Le nom de la cliente reste publié**, arbitrage d'Arnaud du même jour : « Institut Lionne » est une
référence qui crédibilise le cas, et la source indique son accord. L'apporteuse, elle, était déjà
anonymisée en « la personne qui gérait alors ses réseaux sociaux » — la distinction était volontaire
et n'a pas été touchée.

## FR-22 : une ligne de contexte manquait

FR-22 demande la ligne de contexte anglaise pour **« Ton Pote le Geek (cas 01 et bloc En parallèle) »**
— les deux. Le bloc « En parallèle » la porte depuis la story 10.2 ; le cas ne l'avait pas, alors que
son encart « Contexte mission » affiche « Ton Pote le Geek » comme cadre, mot qui ne dit rien à un
lecteur anglophone.

Ajoutée dans la rubrique « Context », avec la formulation déjà employée par le poste, pour que les
deux endroits disent la même chose : *« I took this on under Ton Pote le Geek, my own automation
business for very small and small companies. »*

La ligne Systeme.io, elle, était bien là : *« Systeme.io is an all-in-one platform for selling online
courses »*.

## Ce que la story 10.7 lui a épargné

Deux défauts corrigés la veille dans la même session ont servi ici sans rien coûter :

- **les slugs par langue** — le cas 01 les avait déjà (`calculette-rentabilite` / `profitability-calculator`),
  le défaut était propre au cas 05 ;
- **l'ancre de la page d'un cas seul** — corrigée à la 10.7 dans `layouts/cases/page.html`, elle rend
  ici `#case-01` valide dans les deux langues sans une ligne de plus. Vérifié : une occurrence de
  chaque côté.

## Vérifications

- `scripts/ci/checks-job.sh` : 555 cas, 9 contrôles, verts.
- Pages produites : `public/cas/calculette-rentabilite/` et `public/en/cases/profitability-calculator/`.
- Le cas est lié sous le poste Ton Pote le Geek **dans chaque langue**, au bon chemin.
- Aucune trace de matériel « prévu » en production, alors que le cas en déclare trois dont une vidéo.

## Revue de spec

## Revue du code

### 24/09/2026 — `43f5787` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 113. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d1ae2ab3d154183cab5ac8af

##### Lentille edge-case-hunter
Aucun constat : le changement ne porte que sur le contenu textuel et le statut de publication du cas, sans soulever de cas limite.

##### Lentille verification-gap
Aucune faille de vérification trouvée.

##### Constats propres au projet
NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits, l'intégration du cas 01 FR et EN est complète.
NON BLOQUANT : Aucune donnée privée non autorisée, aucun nom d'hôte ni adresse de serveur et aucun secret n'est commité (la mention de "Institut Lionne" a été validée par la source).
NON BLOQUANT : Skill, procédure et script concordent (aucun des trois n'a été modifié).
NON BLOQUANT : Le changement est cohérent avec AGENTS.md et les décisions d'architecture (la mention de "Ton Pote le Geek" y est déjà autorisée).
NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence (aucun script shell n'a été modifié).

VERDICT: NON BLOQUANT — aucune

## Décisions
