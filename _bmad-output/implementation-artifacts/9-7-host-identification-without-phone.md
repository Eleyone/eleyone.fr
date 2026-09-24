# Story 9.7 : Host identification without a phone number

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.7.

## Pourquoi cette story existe

La story 9.1 a livré les mentions légales avec, pour l'hébergeur, les trois données que
l'article 1-1 I 4° de la LCEN exige : dénomination, adresse et **numéro de téléphone**. Les trois
étaient des valeurs factices, à remplir avant la mise en ligne.

La recherche du 24/09/2026 a établi que la troisième n'existe pas. L'hébergeur ne publie de numéro
de téléphone sur aucune de ses pages — contact, mentions, conditions, support, à propos, toutes
chargées et cherchées — et il l'écrit lui-même sur sa page d'aide consacrée au sujet : il n'offre
pas de support téléphonique. La seule donnée de cette forme qu'il déclare est dans un registre
public d'attribution d'adresses IP, et rien n'en fait un numéro joignable au sens de la LCEN.

Un numéro circule pourtant, sur des mentions légales françaises de sites hébergés là. Il n'a de
source chez l'hébergeur nulle part. Le reprendre aurait publié un faux dans une page dont le seul
objet est d'être exacte, et c'est le risque que cette story écarte.

Arnaud a donc tranché le 24/09/2026 : **pas de numéro, et la page le dit**. Et puisqu'une page qui
constate un manque sans rien proposer laisse le lecteur sans recours, la variable du téléphone est
remplacée par celle du courriel — l'adresse que l'hébergeur désigne lui-même pour les autorités de
l'Union européenne, donc celle qui sert le mieux ce que l'article 1-1 I 4° cherche à permettre.

Ce n'est **pas** dire que ce courriel satisfait l'obligation : le texte demande un numéro, et rien
ne permet de le requalifier. C'est un écart, assumé et écrit, faute de pouvoir faire mieux
(triage de la revue de spec, B1).

Le compte reste à huit : `HUGO_LEGAL_HOST_PHONE` sort, `HUGO_LEGAL_HOST_EMAIL` entre.

## Ce que la story touche

| Fichier | Ce qui change |
| --- | --- |
| `_bmad-output/planning-artifacts/architecture/.../ARCHITECTURE-SPINE.md` | AD-9 : la huitième variable |
| `scripts/env.sh` | `legal_variables` |
| `.env.example` | la liste des noms |
| `ci/legal-placeholder.env` | la valeur factice |
| `scripts/checks/content.sh` | `legal_names`, que C18 compare aux deux fichiers |
| `layouts/_partials/legal-value.html` | `$connus` ; le commentaire qui comptait « sept » ne compte plus rien — le nombre y est devenu faux deux fois, la liste se compte seule |
| `layouts/_shortcodes/legal-list.html` | le groupe `host` |
| `content/legal-notice.{fr,en}.md` | la phrase sur l'absence de numéro |
| `scripts/tests/test-env.sh`, `test-legal-page.sh` | les cas ; trois s'ajoutent, dont celui qui exerce `host_phone`, l'entrée refusée |

`i18n/` ne bouge pas : `legal_term_email` existe déjà pour l'éditeur et sert l'hébergeur tel quel.

## Revue de spec

### 24/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `a39a559`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 23b963ceb7d1f979bce2277c

##### Revue de spec (Lentilles : Adversarial, Structure, Prose)

###### Lentille : Adversarial (Cas limites, failles et contradictions)

* **BLOQUANT** : Contradiction légale avec l'architecture. La story demande de supprimer le téléphone de l'hébergeur, mais l'AD-9 d'`ARCHITECTURE-SPINE.md` (révisé le 23/09) affirme explicitement que ce téléphone est rendu obligatoire par la loi (art. 1-1 I 4°). Implémenter ce changement sans mettre à jour l'analyse juridique d'AD-9 introduit une faille et une contradiction dans l'architecture.
* **BLOQUANT** : Oubli de fichiers dans la mise à jour en cascade. Les critères de succès exigent la modification de `.env.example`, `ci/legal-placeholder.env` et `scripts/env.sh`, mais omettent `ARCHITECTURE-SPINE.md` (qui liste en dur les huit variables dont `HUGO_LEGAL_HOST_PHONE`). Sans instruction explicite pour mettre à jour tous les documents mentionnant cette variable, le développeur laissera des fichiers obsolètes, violant la règle 8 d'AGENTS.md.
* **BLOQUANT** : Ambiguïté sur l'emplacement du texte entraînant un risque de violation d'AD-3. La spec demande qu'une "phrase, dans chaque langue, dit que l'hébergeur ne publie pas de numéro". Si le développeur intègre cette phrase dans le code du shortcode `{{< legal-list "host" >}}`, il violera l'AD-3 ("Aucun gabarit ne contient de texte de contenu"). La spec doit exiger que cet ajout soit fait exclusivement dans le corps Markdown des fichiers `content/legal-notice.{fr,en}.md`.

###### Lentille : Structure (Organisation et vérifiabilité des critères)

* **BLOQUANT** : Action déguisée en prérequis. La mention "Étant donné AD-9 révisé" masque le fait que c'est *cette* story qui doit accomplir la révision d'AD-9. Présenté comme une situation de départ (Étant donné) plutôt que comme un critère de réalisation (Quand / Alors), le développeur a toutes les chances d'oublier de le modifier.
* **NON BLOQUANT** : Le contrôle de l'échec du build ("le build échoue sur un nom inconnu") est un excellent critère. Il s'assure que le mécanisme de sécurité dans `_partials/legal-value.html` fonctionne avec la nouvelle clé et empêchera de laisser l'ancienne clé silencieusement active.

###### Lentille : Prose (Clarté, ambiguïté et ordre des idées)

* **NON BLOQUANT** : La question "La phrase sur l'absence de téléphone cite-t-elle l'hébergeur..." est pertinente, mais montre que la spec laisse volontairement une ambiguïté à lever au moment de l'implémentation. Cela respecte la règle 1 de questionnement avant démarrage.
* **NON BLOQUANT** : La consigne concernant la correction des commentaires de `legal-value.html` ("les sept") est très claire, prescriptive, et illustre parfaitement la règle 8 (relire et nettoyer un fichier entier et non juste le diff ciblé).

##### À trancher avant d'implémenter

* Comment justifier formellement dans l'AD-9 l'absence du téléphone de l'hébergeur, alors que ce même AD-9 indique que la loi l'exige (art. 1-1 I 4°) ? Faut-il acter qu'une adresse courriel spécifique type "abuse" remplit cette obligation pour cet hébergeur précis ?
* Confirmer explicitement que la phrase sur l'absence de téléphone sera ajoutée dans le contenu Markdown (`content/legal-notice.{fr,en}.md`) et non générée par le shortcode, pour respecter strictement l'AD-3.
* Répondre à la question laissée ouverte par la spec : la phrase d'explication doit-elle citer nommément l'hébergeur ou rester un constat neutre ?

### Triage de la revue de spec, 24/09/2026

Les quatre constats bloquants sont **retenus**, et la spec d'`epics.md` est corrigée dans cette PR.

**B1 — contradiction avec AD-9, qui dit la loi exiger ce téléphone.** Fondé, et c'est le constat
utile de la revue. Un critère demande désormais la révision d'AD-9 dans la même PR, et fixe sa
forme : l'obligation de l'article 1-1 I 4° **reste écrite telle quelle**, le constat du 24/09/2026
s'ajoute avec sa source, et la décision est consignée comme un **écart assumé et documenté**.

La question que le relecteur pose — « faut-il acter qu'une adresse abuse remplit cette
obligation ? » — reçoit **non**. Rien ne permet de l'affirmer : le texte demande un numéro, et
publier un courriel à la place ne le requalifie pas. AD-9 dira ce qui est vrai — l'obligation, le
fait qu'elle est inexécutable avec cet hébergeur, et ce que le site publie faute de mieux. Une
architecture qui se rassure elle-même en réinterprétant la loi vaut moins qu'une qui note l'écart.

**B2 — `ARCHITECTURE-SPINE.md` absent des critères.** Fondé. Le fichier était dans le tableau
ci-dessus mais pas dans la spec, et un tableau ne vaut pas un critère. Traité en même temps que B1,
et élargi : un critère demande le **balayage** de `HUGO_LEGAL_HOST_PHONE` et de `host_phone` dans
tout le dépôt, avec la liste des neuf fichiers vivants. Le balayage a été fait avant d'écrire le
critère ; il ne révèle rien de plus que ces neuf, plus le relevé daté du 13/09/2026, qui garde son
texte et reçoit une note.

**B3 — la phrase pourrait atterrir dans le shortcode, contre AD-3.** Fondé. C'était l'intention,
elle n'était écrite nulle part. Un critère l'exige maintenant dans le corps Markdown seul.

**B4 — « Étant donné AD-9 révisé » déguise une action en prérequis.** Fondé et bien vu : la
formulation faisait de la révision une situation de départ. Le critère commence désormais par AD-9
**tel qu'il est aujourd'hui**, et demande sa révision dans le « Alors ».

**Question laissée ouverte par la spec, tranchée : la phrase attribue le fait à l'hébergeur.**
Un constat neutre (« aucun numéro n'est disponible ») se lit comme une omission du site ; une
phrase qui dit que l'hébergeur ne publie pas de numéro nomme la source et se vérifie. C'est aussi
la seule des deux formes qui reste vraie si l'hébergeur change d'avis.

Les deux constats non bloquants ne demandent rien.

## Revue du code

### 24/09/2026 — `832b522` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 105. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 606e7ccb23091cdb3860157c

##### Revue BMAD

###### Lentille : Edge-Case Hunter
* **NON BLOQUANT** : Aucun cas limite non géré n'a été trouvé. Le remplacement de la variable `HUGO_LEGAL_HOST_PHONE` par `HUGO_LEGAL_HOST_EMAIL` est exhaustif. La logique existante dans `legal-value.html` rejette correctement l'ancienne clé avec un message d'erreur, et la robustesse des déclarations bash empêche les cas de valeurs vides ou mal formatées de passer silencieusement.

###### Lentille : Verification-Gap
* **NON BLOQUANT** : Couverture incomplète (Regression gap). Dans `scripts/tests/test-legal-page.sh`, la fonction `case_legal_hebergeur_courriel_sans_ligne_telephone` (ligne 448) vérifie la présence du lien `mailto:` et l'absence de la ligne "Téléphone" *uniquement* sur la version française (`fr=$(page mentions-legales/index.html)`). Le rendu de la version anglaise (`legal-notice/index.html`) est ignoré par ce test, ce qui laisserait passer une régression silencieuse si le gabarit ou la traduction venait à afficher l'ancien terme "Phone" côté anglophone.

##### Constats Projet

* **NON BLOQUANT** : Les critères d'acceptation de la story sont tous satisfaits. L'architecture AD-9 est révisée comme prescrit, et la phrase Markdown attribuant l'absence de numéro à l'hébergeur est bien intégrée dans le corps des pages et non dans le gabarit (respect d'AD-3).
* **NON BLOQUANT** : Aucune donnée privée, nom d'hôte de production ni secret n'est commité ; `ci/legal-placeholder.env` utilise le domaine neutre et invalide `abuse@VALEUR-FACTICE.invalid`.
* **NON BLOQUANT** : Le changement est parfaitement cohérent avec `AGENTS.md`. La règle 8 (lecture entière du document) est honorée par la correction intelligente des commentaires comptant "sept" variables dans `legal-value.html`, et la règle 9 (test du garde-fou en échec) est explicitement satisfaite avec l'ajout de `case_legal_host_phone_est_un_nom_refuse`.
* **NON BLOQUANT** : Scripts, procédures et skills concordent, et aucune documentation de processus n'a été corrompue. 
* **NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail`. La séparation de la déclaration locale et de la substitution `local fr; fr=$(page ...)` évite le masquage des erreurs, et les assertions manuelles utilisent correctement le motif `[[ ... ]] || { ...; exit 1; }`.

VERDICT: NON BLOQUANT — aucune réserve majeure, le code est exceptionnellement propre et respectueux des règles d'architecture (le test manquant sur la page anglaise est une amélioration possible mais ne bloque pas la livraison).

### 24/09/2026 — `0bd3ca3` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 105. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d3f704012baa340967e8d8d6

##### Lentille : Edge-Case Hunter

* **NON BLOQUANT** : La règle du shortcode `legal-list` infère le type de lien à partir du contenu de la variable (téléphone s'il y a un chiffre, courriel s'il y a une arobase). Si l'adresse de l'hébergeur contenait un chiffre (ex. `abuse1@exemple.invalide`) et que le code du gabarit testait la présence d'un chiffre avant celle de l'arobase, le lien généré serait un `tel:` erroné au lieu d'un `mailto:`. Le jeu d'essai n'utilise pas de chiffre, laissant cette possibilité de conflit de règles dans l'angle mort.

##### Lentille : Verification-Gap

* **NON BLOQUANT** : Le test `case_legal_hebergeur_courriel_sans_ligne_telephone` prouve que l'adresse s'affiche, mais l'absence de chiffre dans la valeur de test `abuse@exemple.invalide` laisse une lacune sur la priorité des règles de typage du lien stipulées par les commentaires du gabarit. L'utilisation d'une adresse factice contenant un chiffre prouverait la préséance de l'arobase et garantirait qu'aucune régression silencieuse ne transforme l'adresse électronique en numéro de téléphone.

##### Constats Projet

* **NON BLOQUANT** : Les critères d'acceptation de la story sont tous satisfaits sans en vider l'intention. L'AD-9 documente et assume explicitement l'écart légal, et les neuf fichiers vivants ont bien été mis à jour pour remplacer la variable du téléphone de l'hébergeur.
* **NON BLOQUANT** : Aucune donnée privée, aucun nom d'hôte de production ni secret n'est commité. Le domaine `.invalid` et l'adresse factice garantissent l'absence de fuite.
* **NON BLOQUANT** : La cohérence entre skills, scripts et procédures est maintenue, aucun changement d'outillage n'ayant été introduit.
* **NON BLOQUANT** : Le changement est cohérent avec `AGENTS.md` (le garde-fou vérifie l'entrée refusée `host_phone` conformément à la règle 9) et respecte la décision AD-3 (la justification de l'absence du téléphone est rédigée exclusivement dans le contenu Markdown, sans introduire de texte dans le gabarit).
* **NON BLOQUANT** : Dans les scripts shell, aucune erreur ne passe en silence. L'utilisation d'une substitution de commande directement en argument (`verifier_rubrique_hebergeur "$(page ...)"`) ne masque pas l'éventuel échec de la fonction `page` : un retour vide fait invariablement échouer l'assertion `assert_contains` ou le test `[[ $rubrique != "$rendu" ]]` au sein de la fonction.

VERDICT: NON BLOQUANT — aucune réserve bloquante, l'implémentation est exhaustive et respecte rigoureusement l'architecture et les règles du projet (l'utilisation d'une adresse avec un chiffre dans le test solidifierait toutefois la preuve du typage des liens).

## Décisions

### Triage de la revue de code, 24/09/2026

Verdict `pass`, un seul constat actionnable, **retenu et corrigé** plutôt que reporté.

**Le cas de la rubrique de l'hébergeur ne regardait que la page française.** Fondé. Le terme vient
d'`i18n/`, où « Téléphone » et « Phone » sont deux entrées distinctes : une régression peut
n'atteindre qu'un des deux fichiers, et le cas français ne l'aurait jamais vue. Le corps du cas est
sorti dans `verifier_rubrique_hebergeur`, appelée une fois par langue avec son terme.

La vérification a demandé un détour. Remettre la ligne « Téléphone » dans le groupe `host` faisait
échouer le cas sur **la branche française**, qui s'exécute la première : l'échec ne prouvait rien de
la branche anglaise. Le cas a donc été relancé une seconde fois avec la ligne française neutralisée,
et c'est bien l'anglaise qui a parlé — « EN : la rubrique de l'hébergeur porte encore une ligne
« Phone » ». Une garde qu'une autre garde masque n'est pas une garde vérifiée.

Les autres constats sont des confirmations sans action : aucun cas limite trouvé, critères
satisfaits, AD-3 respecté, aucune donnée privée, points 8 et 9 d'AGENTS.md honorés, aucune erreur
silencieuse sous `set -euo pipefail`.

Un défaut latent **préexistant** est reporté dans `deferred-work.md` plutôt que corrigé ici : C23
tronque un fichier non-HTML au premier octet nul (`legal-address.sh:217`), ce que le job réel signale
quatre fois sur les CV PDF. La story ne touche pas ce fichier.

### Triage de la seconde revue de code, 24/09/2026

Verdict `pass`. Le seul constat actionnable est **réfuté sur pièce**, et aucun code ne change.

**« Un chiffre dans l'adresse de l'hébergeur produirait un `tel:` au lieu d'un `mailto:`. »** Le
constat suppose que le gabarit **infère** le type depuis la valeur. Il ne l'infère pas : le type est
**déclaré par entrée** dans le `dict`, et la valeur ne fait que le confirmer.

```
legal-list.html:56   (dict "terme" "legal_term_email" "valeur" "host_email" "type" "courriel")
legal-list.html:79   {{- else if and (eq .type "courriel")  (strings.Contains $valeur "@") -}}
legal-list.html:81   {{- else if and (eq .type "telephone") (findRE `[0-9]` $valeur) -}}
```

La branche `telephone` exige `.type == "telephone"`. Pour `host_email`, ce test est faux quel que
soit le contenu de la valeur : `abuse1@exemple.invalide` ne peut pas devenir un `tel:`, et il n'y a
pas de préséance à prouver entre deux règles, puisqu'une seule est atteignable. Ajouter un chiffre
au jeu d'essai aurait vérifié une condition que le code n'évalue jamais.

Ce que le gabarit décide bien d'après la valeur, c'est s'il **pose un lien ou non** — une valeur qui
ne ressemble à rien reste en clair, plutôt que de produire un lien mort. C'est déjà couvert par
`case_legal_courriel_et_telephone_sont_des_liens`.

Les autres constats sont des confirmations sans action.
