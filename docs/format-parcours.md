---
title: "Format de rédaction des postes du parcours"
version: 0.1
status: draft
updated: 2026-10-03
---

# Format de rédaction des postes du parcours

Contrat entre la rédaction d'un poste du parcours et le site Hugo. Une personne ou un agent qui rédige un poste produit exactement ce format, sans toucher au code. Il tient pour les postes ce que `docs/format-cas.md` tient pour les cas, et il a été écrit sur son modèle (story 10.8, arbitrage Q6 d'Arnaud du 02/10/2026).

L'architecture reste la référence du front matter (AD-18) : ce document dit comment rédiger un poste complet, il ne redéfinit aucune clé. Il ne couvre que les **postes** ; les entrées de formation, de certification et de langue (`content/education/`) restent décrites par AD-18 seul (arbitrage d'Arnaud du 02/10/2026).

## Principe : un fichier par poste et par langue

On écrit **un poste**, pas une page. Un poste n'a pas de page à lui : l'accueil, qui est le CV, lit tous les postes et les affiche dans l'ordre de `order`, chacun suivi des cas qui le prouvent. Le poste ne liste pas ses cas : c'est le cas qui pointe vers lui par sa clé `position` (`docs/format-cas.md`), et un cas se publie sans toucher au poste.

```
content/career/position-chiliz.fr.md             ← un poste, en français
content/career/position-chiliz.en.md             ← le même poste, en anglais
content/career/_index.fr.md                      ← section technique : créée avec le site, pas par la rédaction des postes
content/career/_index.en.md
…
```

- **Identifiants de poste** : ils sont figés dans l'architecture (AD-18, règle `position-<société>`, suivie de `-<année de début>` quand la société revient dans le parcours ; `position-earlier-career` regroupe le parcours antérieur). La liste y fait foi et ce document ne la recopie pas. **Aucun poste n'est créé hors de cette liste** sans modifier AD-18 d'abord.
- **Nom de fichier** : `position-<id>.<langue>.md`, en anglais, en minuscules et en kebab-case. Le suffixe `.fr.md` / `.en.md` est la convention multilingue native de Hugo.
- **`translationKey`** : égal au nom de fichier sans la langue (`position-chiliz`), identique dans les deux fichiers d'un même poste. C'est aussi l'ancre du poste sur l'accueil (`#position-chiliz`), vers laquelle pointe le lien « Retour au parcours » de chaque cas. Un identifiant publié **n'est jamais renommé** : des cas y font référence.
- **Pas de `title` ni de `slug`** : un poste ne produit aucune page (la section `content/career/` est rendue `never`, AD-18), il n'a donc ni titre de page ni URL.

## Métadonnées (front matter YAML)

Les **clés** sont en anglais et identiques dans les deux langues. Certaines **valeurs** se traduisent, d'autres non. La source unique de ce qui ne se traduit pas est la liste du contrôle C3 pour le rôle `position`, dans `scripts/checks/parity.sh` (fonction `untranslated`) : C3 refuse toute paire FR/EN dont une de ces valeurs diffère. Le tableau ci-dessous la cite, il n'en est pas une seconde source ; en cas d'écart, c'est `parity.sh` qui a raison et ce document qui se corrige.

| Clé | Traduite | Rôle | Obligatoire |
|---|---|---|---|
| `translationKey` | non | identifiant, égal au nom de fichier | oui |
| `company` | non | l'employeur, ou le client direct quand la mission passe par une société de prestation | `company` ou `label`, l'une des deux au moins |
| `label` | **oui** | nom affiché d'un poste qui n'est pas une société (« Parcours antérieur » / « Earlier career ») ; passe devant `company` | voir `company` |
| `role` | **oui** | intitulé du poste | oui |
| `sector` | **oui** | secteur du client ou de la mission | oui dans un poste publié, depuis la story 10.10 (C19) ; un brouillon la tolère absente |
| `period` | **oui** | période donnée par l'auteur (voir plus bas) | oui |
| `location` | **oui** | ville de travail ou mode de travail (« Full remote ») | `location` ou `setup`, l'une des deux au moins |
| `setup` | non | cadre : `employee`, `freelance`, `agency` ou `ton-pote-le-geek` | voir `location` |
| `via` | non | société de prestation par laquelle passait la mission | non |
| `company_url` | non | adresse absolue en `https://` ; le nom de la société devient un lien | non |
| `stack` | non | stack complète du projet (voir plus bas) | comme `sector` : oui dans un poste publié |
| `track` | non | `main` (parcours) ou `parallel` (bloc « En parallèle ») | oui |
| `order` | non | entier, 1 pour le plus récent, unique dans son `track`, brouillons compris ; l'ordre d'affichage vient de lui, jamais d'une date | oui |
| `draft` | non | `true` tant qu'un `[TODO` reste | oui |

- **`stack` est dans la liste de C3** depuis la story 10.9, avec son contrôle par le vocabulaire (C6 étendu aux postes) : une stack qui diffère entre FR et EN, ordre compris, ou qui cite un terme absent de `data/stack.yaml` fait échouer les contrôles.
- **`label`, `role`, `sector`, `period` et `location` se traduisent**, et c'est pour cela qu'ils n'entrent pas dans la liste de C3 : « Parcours antérieur » devient « Earlier career », « Lyon » peut devenir « Lyon, France ». `company`, au contraire, y reste, pour qu'un nom de société ne s'écrive jamais de deux façons.
- **Une clé facultative absente vaut mieux qu'une clé vide** : C19 refuse une clé écrite mais vide (`location: ""`) — pour `company`, `label`, `location`, `setup`, `via` et, depuis la story 10.9, `sector` et `stack` (une liste vide, une liste dont aucun terme ne renseigne rien, ou une valeur qui n'est pas une liste). Une clé se renseigne ou se retire. `sector` et `stack`, elles, ne se retirent que d'un brouillon : depuis la story 10.10, C19 les exige dans un poste publié, et y refuse un `sector` resté en `[TODO`.
- **`company`, `via` et le corps** se partagent les sociétés (arbitrage Q3 du 02/10/2026) : `company` porte le client direct ou l'employeur, `via` la société de prestation, et les clients finaux, s'il y en a, sont nommés dans le corps.
- **`location`** ne porte jamais la ville de résidence : seulement une ville où la mission s'est déroulée, ou un mode de travail.
- **`company_url`**, pas `url` : Hugo réserve `url` pour forcer l'adresse d'une page et refuse une valeur à protocole (AD-18).

```yaml
---
translationKey: position-chiliz       # égal au nom de fichier ; jamais renommé
company: "Chiliz"                     # non traduit ; ou label pour un poste qui n'est pas une société
role: "Développeur backend senior"    # dans la langue du fichier
sector: "[TODO: secteur]"             # dans la langue du fichier
period: "Juillet 2022 – avril 2026"   # donnée par l'auteur ; jamais calculée ; aucune durée
location: "Full remote"               # ville de travail ou mode de travail ; jamais la ville de résidence
setup: "employee"                     # employee | freelance | agency | ton-pote-le-geek
stack: ["PHP", "Symfony"]             # vocabulaire contrôlé, identique FR/EN ; le projet entier
track: "main"                         # main | parallel
order: 1                              # 1 pour le plus récent, unique dans son track
draft: true                           # passe à false quand plus aucun [TODO] ne reste et que le poste est relu
---
```

### Période

- **La période est le texte de l'auteur**, dans la langue du fichier. Elle n'est jamais calculée ni déduite, ni par un gabarit, ni par la rédaction (AD-18).
- **Aucune durée n'est écrite** (arbitrage Q2 du 02/10/2026) : ni clé de durée, ni durée dans le texte de la période, ni durée dans le corps (« près de quatre ans »). La période porte les bornes, et le lecteur en déduit la durée. Une durée écrite à côté des bornes est une seconde source qui finit par les contredire.
- **Formes de période** : celles que décrit le contrôle C25 (liste des contrôles de l'architecture), en français et en anglais — un intervalle « mois AAAA – mois AAAA » (« Juillet 2022 – avril 2026 », « July 2022 – April 2026 »), une activité en cours « depuis mois AAAA » (« Depuis février 2024 », « Since February 2024 »), une année seule « AAAA », ou un intervalle d'années « AAAA – AAAA » (« 2025 – 2026 », du 1er janvier de la première au 31 décembre de la seconde ; ajouté par la story 10.10). La période d'un poste prend une majuscule initiale, comme dans tous les postes publiés : elle s'affiche seule, dans la marge. Le séparateur est un tiret demi-cadratin entouré d'espaces. Les mois s'écrivent en toutes lettres, dans la langue du fichier ; la casse ne compte pas. Aucune autre forme : C25 (`scripts/checks/periods.sh`, story 10.9) fait échouer les contrôles sur une période qu'il ne sait pas lire, au lieu de la laisser passer — y compris un intervalle dont la fin précède le début, et une forme mêlée comme « juillet 2022 – 2026 ». Une période en `[TODO` n'est tolérée que dans un brouillon.
- **La période d'un cas est comprise dans celle de son poste**, et un cas ne couvre pas nécessairement toute la mission (règle d'Arnaud, arbitrage Q2). Un cas plus court que son poste n'est donc pas une incohérence ; un cas qui en déborde en est une. C25 le vérifie, en comparant des bornes, sans rien afficher : une année seule vaut de janvier à décembre, une activité « depuis » n'a pas de fin — un cas en cours sous un poste terminé déborde donc.

### Stack

La liste des technologies autorisées, avec leur écriture unique et les exclusions décidées, est tenue dans **`data/stack.yaml`**. Elle fait foi : ce document ne la recopie pas.

- **La stack d'un poste est celle du projet entier** sur lequel la mission a porté, et non la part qu'en cite un de ses cas (arbitrage Q4 du 02/10/2026). C'est la différence avec un cas, dont la stack ne porte que les technologies citées dans le cas (`docs/format-cas.md`).
- **Termes de `data/stack.yaml` seulement**, identiques en FR et en EN. Une technologie absente du vocabulaire s'y ajoute **avant** d'être utilisée dans un poste, dans la même PR ou dans une PR antérieure.
- **Une version ne s'écrit que si le vocabulaire la porte.** « Symfony » s'écrit sans numéro, et « Symfony 1.3 » n'existe que parce que la version est le sujet d'un cas. Zend Framework 1 et Zend Framework 2, en revanche, sont deux technologies que le lecteur doit pouvoir distinguer : elles forment deux entrées (arbitrage Q5 du 02/10/2026) ; la story 10.10 a scindé l'entrée unique « Zend Framework » de `data/stack.yaml`, et aucune stack ne la porte plus seule.
- **Une technologie essayée puis abandonnée n'est pas dans la stack** ; son abandon peut se raconter dans le corps, s'il dit quelque chose d'une décision (Python au départ du projet du cas 02 en est l'exemple, exclu de `data/stack.yaml` pour cette raison).
- **Une notion n'est pas une technologie** : une architecture, un protocole générique ou une pratique ne vont pas dans la stack, mais dans le corps (voir « Corps du texte »).

## Corps du texte

Le corps décrit **le périmètre complet de la mission** : ce que le poste couvrait, au-delà de la décision que racontent ses cas.

- **De 3 à 6 phrases**, en prose, à la **première personne**.
- **La voix est celle du positionnement d'Arnaud** : ce qu'il vend, c'est le jugement, pas l'exécution. Le corps dit ce qui était à décider, ce qu'il a tranché, ce qu'il a cadré ou redessiné, et ce que ça a permis ; il n'est pas une liste de tâches ni un inventaire de tickets. Ton sobre et précis, sans superlatif ni jargon de recrutement : un CTO doit pouvoir y reconnaître un pair, un recruteur l'ampleur du travail.
- **Les notions qui ne sont pas des technologies vont ici** : une architecture (microservices orientés domaines), un mécanisme de marché (DEX), des APIs, une CI, un VPS ou une infrastructure auto-hébergée. Elles s'écrivent dans une phrase qui dit ce qu'elles faisaient dans la mission, et `data/stack.yaml` les refuse (arbitrage Q5 du 02/10/2026).
- **Les clients finaux sont nommés dans le corps** quand ils sont publiables, c'est-à-dire déjà publics ou confirmés par l'auteur pour cet usage (arbitrage Q3) ; sinon, « un client ». Une personne physique, elle, n'est jamais nommée (règle 8).
- **Le corps ne répète pas le front matter** : ni la société, ni le rôle, ni la période, ni le secteur, ni une ligne « Stack : … ». Une technologie peut être nommée dans une phrase où elle porte une décision ; elle n'y est pas listée.
- **Aucun titre** : le nom du poste est déjà un titre de niveau 3 sur l'accueil, et le corps se lit sous lui.
- **Le corps se lit sans les cas**, et les cas sans lui : il peut dire qu'un chantier a fait l'objet d'un cas, il ne s'appuie pas sur lui pour être compris.

**Rendu** : le corps est rendu pour tout poste, **toujours visible**, après la liste des cas publiés du poste ; la stack du projet suit, seule, dans un bloc repliable natif (`<details>`) fermé par défaut et nommé « Stack » (arbitrages d'Arnaud du 02/10/2026, story 10.9, qui révisent l'arbitrage Q1 ; AD-18). Le secteur s'écrit sur la ligne de rôle, juste après l'intitulé. Un corps absent ou fait de blancs n'est pas rendu, une stack absente ne produit aucun bloc, et rien ne signale leur absence. Ce qui doit se lire d'un coup d'œil — société, rôle, secteur, période — est dans le front matter, pas dans le corps : le corps vient après les cas, et c'est la ligne de rôle, pas lui, qui peut repousser le lien du premier cas sous le premier écran mobile. *Révisé le 02/10/2026, story 10.9 : ce paragraphe annonçait le corps et la stack ensemble dans le bloc repliable.*

## Parité FR/EN

- **Deux fichiers complets**, un par langue, avec le même `translationKey`. L'anglais est une version entière pour les recruteurs internationaux, pas un résumé.
- **Mêmes faits, mêmes chiffres, même stack** en FR et en EN. Les valeurs non traduites (tableau ci-dessus) sont identiques à la lettre, et C3 le vérifie.
- **L'anglais n'est pas une traduction littérale** : il ajoute les lignes de contexte dont un lecteur international a besoin — ce qu'est l'entreprise, un sigle, ce qu'est une ESN quand `via` en nomme une.

## Sections des sources qui ne sont pas publiées

- Les annotations de travail d'un premier jet : provenance de chaque ligne, points « à trancher », durées calculées.
- Les notes d'entretien et tout ce qui relève de l'auto-évaluation.
- Le déroulé d'un cas, que sa page raconte : le corps du poste peut situer ce chantier dans la mission, il ne reprend pas son récit.

## Marqueurs à compléter

Tout ce qui manque s'écrit `[TODO: précision]`, dans les deux langues. Un poste qui contient encore `[TODO` reste en `draft: true` ; C5 refuse un `[TODO` dans un fichier publié. Les passages entre crochets des sources restent des `[TODO: …]`, jamais des faits, et une question encore ouverte ne se tranche pas en rédigeant : elle reste un `[TODO: …]` jusqu'à la réponse de l'auteur.

## Règles de rédaction

1. **Rien d'inventé** : ni client, ni chiffre, ni technologie, ni date, ni durée absents des sources ou non confirmés par l'auteur. Une technologie « probable » n'est pas une technologie de la stack.
2. **Reformulation minimale** des sources, à la première personne.
3. **Mêmes faits et mêmes chiffres en FR et en EN** (voir « Parité FR/EN »).
4. **Aucun code** : le corps est de la prose. Un chiffre interne à un client ne s'écrit que confirmé publiable par l'auteur (règle 1).
5. **Aucune information personnelle** : ni rémunération, ni ville de résidence, téléphone ou mobilité, ni auto-évaluation d'entretien, ni proches. Le lieu de résidence public se limite à « basé en France », porté par le site ; les villes où se sont déroulées les missions peuvent apparaître, dans `location` comme dans le corps.
6. **Un chantier du poste jamais mis en production le reste explicitement dans le texte.** Le corps d'un poste résume plusieurs chantiers, et une formule de périmètre (« architecture de traitement par lots ») peut laisser croire livré ce qui ne l'a pas été. Exemple vérifiable : le batch de transactions du cas 03, chez Chiliz, n'est jamais allé en production ; un poste qui le mentionne le dit.
7. **Ton factuel envers les anciens employeurs et clients** : le texte est public et nominatif.
8. **Une personne physique n'est pas nommée ; une entreprise peut l'être.** L'employeur ou le client direct est nommé — c'est `company` —, les clients finaux publiables aussi, dans le corps. Un dirigeant, un collègue ou un utilisateur sont désignés par leur rôle, jamais par leur prénom ou leur nom. Le dépôt est public et le miroir publie à chaque push : un prénom commité reste atteignable par son SHA, même retiré ensuite. Un nom de personne ne s'écrit qu'avec l'accord explicite de l'intéressé, demandé pour cet usage-là (décidé par Arnaud le 21/09/2026, `docs/format-cas.md`, règle 8).

## Modèle vide

```markdown
---
translationKey: position-<id>         # identifiant figé dans AD-18, égal au nom de fichier
company: "[TODO: société]"            # ou label, pour un poste qui n'est pas une société
role: "[TODO: rôle]"
sector: "[TODO: secteur]"
period: "[TODO: période]"
location: "[TODO: ville de travail ou mode de travail]"
setup: "[TODO: cadre]"                # employee | freelance | agency | ton-pote-le-geek
via: "[TODO: société de prestation]"  # à retirer si la mission ne passe par aucune
stack: ["[TODO: technologie]"]       # jamais vide : une clé écrite se renseigne
track: "main"
order: 0
draft: true
---

[TODO: périmètre complet de la mission, 3 à 6 phrases, à la première personne]
```
