# Story 9.1 : Legal notice and confined address

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.1.

## Revue de spec

### 22/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `c59ce9a`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 332f82e1a17bdd5e51c1d21d

##### Lentille Adversarial (Cas extrêmes, failles et oublis)
- BLOQUANT : **Shortcode manquant.** L'architecture (AD-9) impose que le Markdown lise les variables via un shortcode (ex: `{{< legal "nom_variable" >}}`). La spec demande la création du partiel `_partials/legal-value.html` mais omet la création du shortcode indispensable qui doit l'appeler. Sans lui, le Markdown ne peut pas afficher les variables.
- BLOQUANT : **Portée du blocage par le partiel (critère impossible).** La spec exige que le partiel échoue pour "toute lecture depuis une autre page (dont `<title>`, meta `description`...)". Si le partiel se base sur la page courante (`translationKey == "legal-notice"`) pour s'autoriser à lire la variable, il ne pourra pas empêcher sa lecture accidentelle dans le `<title>` de la page `legal-notice` elle-même. La vérification pour les balises de la page courante relève donc exclusivement de C23. Attendre cette ségrégation du partiel est techniquement erroné.
- BLOQUANT : **Oubli de la mise à jour de C22 (mise en ligne).** Selon AD-9, le script de mise en ligne (C22) interdit toute donnée privée issue du garde-fou sur le site *sauf* sur la page des mentions légales, où la commune de l'adresse de l'éditeur est tolérée. La spec oublie d'inclure la modification de C22 pour implémenter cette exception. Sans cela, la mise en ligne du site échouera lors du contrôle C22.
- BLOQUANT : **C23 et l'accès à la variable testée.** Le critère indique "Quand la valeur chargée de `HUGO_LEGAL_PUBLISHER_ADDRESS` apparaît... Alors C23 échoue". Pour que C23 puisse chercher cette valeur, le script bash n'a pas d'autre choix que de charger les valeurs réelles (ou factices en CI). La spec ne précise pas que C23 doit sourcer `scripts/env.sh` (ou lire le fichier adéquat), ce qui risque de mener à un test silencieux qui cherche une chaîne vide.
- NON BLOQUANT : **Variables vides vs non définies.** L'instruction "une valeur vide fait échouer le build" doit idéalement être comprise comme "vide ou non définie", la fonction `os.Getenv` de Hugo retournant une chaîne vide dans ces deux cas.
- NON BLOQUANT : **Lien de pied de page codé en dur.** Le critère demande que le pied de page porte le lien. Bien que ce soit implicite (règle AD-2), il faudra s'assurer que l'URL est construite dynamiquement (ex. via `site.GetPage` et la clé de traduction) et non codée en dur.

##### Lentille Structure (Organisation, redondances, périmètre)
- NON BLOQUANT : **Redondance et confusion de responsabilité.** La spécification demande au partiel d'échouer s'il est lu dans un `<title>`, mais demande aussi à C23 d'échouer si la valeur s'y trouve. C'est une bonne séparation sur le principe (le partiel prévient, C23 vérifie), mais le texte amalgame "autre page" et "éléments meta de la page courante" (voir point bloquant ci-dessus). 
- NON BLOQUANT : **Libellés de contenu vs interface.** La spec mentionne "éditeur (nom, adresse...)", sans préciser s'il s'agit d'une simple rédaction Markdown ou si les intitulés doivent passer par le fichier de traduction `i18n/`. 

##### Lentille Prose (Clarté, style, ambiguïtés)
- NON BLOQUANT : **"Étant donné content/legal-notice.{fr,en}.md et les valeurs factices"** : L'expression pourrait laisser penser que le développeur doit écrire les valeurs factices *directement dans* le fichier Markdown. "Étant donné les fichiers Markdown et l'injection des valeurs factices par l'environnement" lèverait cette légère ambiguïté.
- NON BLOQUANT : **Format des contacts.** La spec indique qu'il faut afficher "contact". L'usage éventuel d'un lien cliquable `mailto:` ou `tel:` n'est pas spécifié, laissant le choix libre au développeur. 

##### À trancher avant d'implémenter
- **Partiel vs C23** : Confirmer que l'on attend du partiel `legal-value.html` qu'il interdise uniquement l'appel depuis une *autre page* (en vérifiant `translationKey`), et que l'absence de fuite dans le `<title>` et les metas de la page légale *elle-même* est laissée sous la seule responsabilité du contrôle externe C23.
- **Shortcode** : Confirmer l'ajout au périmètre de la création du fichier `_shortcodes/legal.html` qui sert de pont entre le Markdown et le partiel (conformément à l'architecture AD-9).
- **Mise à jour de C22** : Confirmer que la story doit modifier le script de contrôle C22 pour créer l'exception vitale d'AD-9 (tolérer l'adresse de l'éditeur sur les mentions légales de production).
- **Question posée dans la spec** : "Les intitulés qui entourent les valeurs sont-ils rédigés par le développeur d'après FR-18, puis relus par Arnaud ?" (Nécessite une validation avant le début du développement).

### Triage des constats (23/09/2026)

Les quatre constats bloquants ont été confrontés à AD-9 (`ARCHITECTURE-SPINE.md:210`) et au dépôt avant d'être retenus ou refusés.

**Retenus**

- **Le shortcode manquant.** Juste, et AD-9 le nomme deux fois : `_shortcodes/legal.html` est dans ses « Binds », et la règle écrit « le Markdown des pages légales l'appelle par `{{< legal "publisher_name" >}}` ». La spec de la story ne cite que le partial. Vérifié : `layouts/_shortcodes/` **n'existe pas**, et `legal-value.html` non plus. Le shortcode entre au périmètre.

- **La portée du refus du partial.** Juste sur le fond technique : un partial ne sait pas d'où on l'appelle, seulement sur quelle page. Sur la page légale elle-même, il ne peut pas distinguer un appel depuis le corps d'un appel depuis `<title>`. AD-9 a déjà tranché la répartition : le partial refuse « toute lecture […] hors d'une page de `translationKey` `legal-notice` », et « C23 le vérifie sur la sortie ». Le critère d'acceptation est donc reformulé pour dire les deux moitiés séparément, au lieu de demander au partial ce qu'il ne peut pas faire.

- **C23 ne verrait aucune valeur.** Le plus dangereux des quatre, et il est juste. Vérifié dans le dépôt : `scripts/env.sh` n'enveloppe aujourd'hui que `hugo`, appelé par `scripts/build.sh:48-50` ; `scripts/check.sh` est lancé **directement** par `scripts/ci/checks-job-container.sh:46` et sur le poste. Aucun contrôle ne voit un `HUGO_LEGAL_*` — `content.sh:297` n'en compare que les **noms**. Un C23 qui lirait une variable vide chercherait la chaîne vide et ne dirait jamais rien : un huitième garde-fou qui ne garde rien, dans une story dont c'est précisément l'objet. **Deux conséquences entrent au périmètre** : les contrôles tournent sous le chargeur unique (AD-9 : « un seul chargeur »), et **C23 rend une anomalie, jamais un succès, quand la valeur est absente** — la règle de C21 pour poppler et de `html.sh` pour xmllint.

**Refusé**

- **« La story oublie de modifier C22 ».** Faux, et la source le dit : C22 est le contrôle de la sortie de production, il vit dans le job `release`, et son exception pour les pages légales est **le deuxième critère d'acceptation de la story 11.2** (`epics.md`, « Étant donné les pages des mentions légales / Quand un motif y apparaît contenu dans une valeur `HUGO_LEGAL_*` injectée, puis hors de ces valeurs / Alors C22 passe, puis échoue »). Le relecteur a lu AD-9, qui décrit C22, sans voir que le backlog en avait déjà fait une story. Rien à ajouter ici.

**Non bloquants**

- *Variable vide ou non définie* — retenu comme précision : `os.Getenv` rend la chaîne vide dans les deux cas, et le partial traite les deux pareil.
- *Lien du pied de page construit dynamiquement* — retenu : le lien passera par la page, jamais par une URL écrite à la main (AD-2).
- *Intitulés en `i18n/` ou en Markdown* — tranché à l'implémentation : les intitulés sont de l'interface, donc `i18n/`, comme tous les libellés du site.
- *« les valeurs factices » ambigu* — retenu comme reformulation : les valeurs viennent de l'environnement, jamais du Markdown.
- *`mailto:` pour le contact* — laissé libre par la spec ; le contact sera un lien, comme sur la future page de contact.

## Arbitrages d'Arnaud (22-23/09/2026)

1. **Les intitulés** — « donne-moi les intitulés, et lance un agent qui va chercher les données sur le web ». Un agent a cherché les obligations réelles sur sources officielles (Légifrance, service-public, BOFiP, CNIL) le 22/09/2026.
2. **Le contact** — lien cliquable d'après ce que la valeur est, jamais d'après ce qu'on a décidé qu'elle serait.
3. **Le téléphone** — l'article 1-1 I 1° l'impose ; Arnaud publie un **numéro dédié à l'activité**. Son numéro personnel reste privé et **reste dans la liste des motifs interdits**.
4. **Les variables** — une par donnée. Mon option annonçait « neuf » ; le compte juste est **huit**, les deux `*_CONTACT` étant remplacées et non complétées. Correction signalée avant d'écrire.

## Ce que la recherche a changé

- **L'article 6 III de la LCEN n'existe plus.** La loi SREN du 21/05/2024 a déplacé l'identification vers l'**article 1-1** et la sanction vers l'**article 1-2**. L'architecture citait l'ancien. La fiche service-public.fr, datée du 31/07/2023, le cite encore : c'est la source qu'on prendrait pour argent comptant.
- **Le téléphone de l'hébergeur est obligatoire** (art. 1-1 I 4°), ce qu'aucune variable ne portait explicitement.
- **L'article 1-1 I 5°** (stockage des données), créé par la même loi, est sans objet ici — site statique, sans formulaire ni analytique — et la condition de réexamen est écrite dans AD-9.
- **Les formes anglaises sont attestées**, pas traduites au jugé : « Legal notice », « Publisher », « Publication Director », « Hosting provider ». Deux pièges écartés : « Legal mentions » n'est pas de l'anglais juridique, et « Editor » est un faux ami.

## Implémentation

| Pièce | Rôle |
|---|---|
| `_partials/legal-value.html` | seul lecteur des `HUGO_LEGAL_*` ; trois refus qui arrêtent le build |
| `_shortcodes/legal.html` | seul pont Markdown → partial, nommé par AD-9 et inexistant |
| `_shortcodes/legal-list.html` | le balisage des trois listes, une écriture pour les deux langues |
| `scripts/checks/legal-address.sh` | **C23**, découvert automatiquement par `check.sh` |
| `scripts/check.sh` | lance chaque contrôle sous le chargeur unique |
| `layouts/page.html` | gabarit des pages simples : cible d'évitement et grille |
| `content/legal-notice.{fr,en}.md` | le contenu, sans une seule valeur |

### Le trou que la revue de spec avait vu venir

Vérifié : **aucun contrôle ne voyait un `HUGO_LEGAL_*`**. `scripts/env.sh` n'enveloppait que `hugo` ; `check.sh` était lancé nu. C23 aurait cherché la chaîne vide et ne se serait jamais déclenché. Mesuré : variable absente sans le chargeur, définie dessous (longueur seule affichée).

### Ce que les tests ont trouvé et que la relecture n'aurait pas vu

- **Le lien `tel:` était mort.** La sortie d'un partial est du `template.HTML` où Go a déjà échappé le `+` en `&#43;` ; replacée dans un attribut, son `&` était échappé à son tour, donnant `tel:&amp;#43;…`. **Ma vérification à la main l'avait manqué** parce qu'elle cherchait `&#43;`, qui ne correspond pas à `&amp;#43;`. Isolé sur un harnais minimal : le défaut vient du passage par un partial, pas de la minification. `htmlUnescape` le ferme, et `safeURL` s'est révélé inutile — la forme sans lui rend le même HTML tout en gardant le filtre de schémas de Go.
- **`page.html` n'avait pas de cible d'évitement.** C12 l'a dit dès la première page rendue : ce gabarit générique n'avait jamais servi.
- **Deux liens de la liste mesuraient 23 px**, sous le seuil WCAG 2.2. Les liens vers Légifrance, dans une phrase, en restent exemptés.
- **Un décalage de 4 px** entre terme et valeur, ma marge ne s'appliquant qu'à la valeur. Passé par la gouttière de ligne.

### Vérification au navigateur, valeurs factices uniquement

Le rendu a été construit **sans `.env`**, pour qu'aucune valeur réelle n'apparaisse (18 valeurs factices, 0 réelle, compté avant d'ouvrir).

| Mesure | 1280 px clair | 360 px sombre |
|---|---|---|
| Écart terme / valeur | 0 px sur 9 couples | termes empilés au-dessus |
| Alignement | termes à 261, valeurs à 301 | — |
| Contraste terme / lien | 6,52 / 6,26 | 7,68 / 9,05 |
| Cibles < 24 px hors phrase | 0 | 0 |
| Débordement horizontal | non | non |

### Constats

| | |
|---|---|
| `scripts/tests/run.sh` | **479 cas** (469 avant) |
| `scripts/check.sh` | 9 contrôles |
| `check-private.sh` | index et historique à 0 |

## Revue du code

### 23/09/2026 — `6583a69` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 7aee3006b6ef991d4514e337

##### Rapport de revue (PR #98 - Story 9.1)

###### Lentilles BMAD (`verification-gap`, `edge-case-hunter`) et contrôles projet

- BLOQUANT : **Faille de vérification dans C23 due à l'échappement HTML.** Le contrôle `scripts/checks/legal-address.sh` cherche la valeur de `HUGO_LEGAL_PUBLISHER_ADDRESS` telle qu'elle est définie en texte brut dans l'environnement. Pour vérifier qu'elle ne fuite pas dans le corps des pages, il utilise `grep -F` sur le contenu brut des fichiers HTML (`cat "$fichier"`). Or, si l'adresse réelle contient une apostrophe (ex: `L'adresse`), une esperluette ou des guillemets, Hugo l'échappera dans son rendu (`L&#39;adresse`). Dans ce cas, `grep` ne trouvera pas la chaîne brute et laissera passer la fuite en silence. Le test unitaire `test-legal-address.sh` souffre de l'angle mort décrit dans `AGENTS.md` (règle 15) : l'adresse factice choisie comporte des parenthèses et un tiret, mais aucun caractère échappable par le moteur HTML, masquant ainsi la faille.
- NON BLOQUANT : **Titres en dur dans le Markdown (critères et architecture contournés).** Le critère d'acceptation exige l'affichage du directeur de la publication via le libellé `legal_publication_director`. La revue de spec a statué que « les intitulés sont de l'interface, donc `i18n/` ». Si les clés `legal_publisher`, `legal_publication_director` et `legal_host` ont bien été créées dans les fichiers YAML, elles constituent du code mort. Les fichiers `content/legal-notice.{fr,en}.md` écrivent ces titres en dur (`## Éditeur du site`, `## Publisher`). L'intention du critère (centraliser les libellés d'interface) est vidée.
- NON BLOQUANT : **Fragilité de l'attribut `tel:` face aux séparateurs.** Le shortcode `legal-list.html` retire uniquement les espaces pour construire le lien téléphonique (`{{ replace $valeur " " "" }}`). Si la valeur de `.env` utilise des points ou des tirets (ex: `01.23.45.67.89`), ces caractères subsisteront dans le lien `tel:`, ce qui est potentiellement non conforme avec la norme RFC 3966 et risque de rendre le lien inutilisable sur certains navigateurs.

VERDICT: BLOQUANT — Le contrôle C23 (legal-address.sh) est aveugle aux fuites de l'adresse dans le corps des pages si celle-ci contient des caractères qui sont échappés en HTML par Hugo.

### Décision sur les constats (23/09/2026)

**Retenu, bloquant — C23 était aveugle à une adresse échappée.** Le constat est juste et sévère. Une adresse portant une apostrophe ou une esperluette est rendue `L&#39;adresse` par Hugo ; `grep -F` sur le fichier brut ne la trouvait pas, et le contrôle se déclarait vert en laissant fuiter la commune. Et **ma fixture le masquait** : parenthèses et tiret, aucun caractère échappable. C'est la règle 15 d'AGENTS.md.

La parade n'est pas d'ajouter la forme échappée à la recherche : en l'essayant, on constate qu'il y en a une **troisième** — libxml2, en extrayant un nœud par XPath, laisse l'apostrophe et réécrit l'esperluette. Leur nombre est combinatoire, et celle qu'on oublie est celle qui fuite. Le texte cherché est donc **décodé** avant lecture, ce qui ramène toutes les sérialisations à une forme unique. L'adresse d'essai porte désormais une apostrophe et une esperluette, et trois cas échouent sans la normalisation.

**Retenu — la clé `legal_publication_director` était du code mort.** Le critère d'acceptation la nomme explicitement. Elle est maintenant le terme du groupe « directeur ». Les deux clés restées inemployées, `legal_publisher` et `legal_host`, sont retirées : les titres de section sont du contenu, pas de l'interface.

**Retenu — le lien `tel:` gardait la ponctuation.** La RFC 3966 n'admet que des chiffres et un `+` de tête. Un cas ajouté couvre `01.23.45.67.89` et `(+33) 1-23-45-67-89`.

### Deux défauts de ma main, trouvés en corrigeant

- **Un `sed` dont le remplacement contenait `&`**, qui y désigne toute la correspondance : le cas du titre injectait autre chose que ce qu'il croyait, et échouait sans que le contrôle soit en cause. Les pages sont désormais réécrites, jamais retouchées.
- **Un commentaire de gabarit qui citait la séquence le fermant** : il se terminait sur place, et la fin de la phrase partait dans le HTML rendu. Vu dans la sortie d'un cas de test, pas en relisant.

### 23/09/2026 — `330cb2c` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: bfa9cd23debe3022a0fe4cd2

Voici le rapport de revue structuré selon les lentilles `edge-case-hunter`, `verification-gap` et les règles propres au projet :

- BLOQUANT : **Crash par SIGPIPE avalé comme anomalie (C23)**. Dans `scripts/checks/legal-address.sh`, le pipeline `printf | decoder_entites | grep -q` est sous `set -o pipefail`. Sur un gros fichier HTML (plus grand que le tampon du pipe), si l'adresse est trouvée tôt, `grep -q` quitte et ferme le pipe. `sed` reçoit SIGPIPE et quitte avec 141. Sous `pipefail`, le pipeline renvoie 141, ce qui déclenche un faux crash via `checks_die` au lieu de signaler la fuite. (*Fix : utiliser `grep -F -e "$adresse" > /dev/null`*).
- BLOQUANT : **Erreur de `file` laissée sous silence**. Dans `scripts/checks/legal-address.sh`, la ligne `encodage=$(file ...) || encodage=binary` avale silencieusement l'échec de la commande `file` (ex: outil manquant ou fichier illisible) pour sauter l'analyse. Cela contredit formellement la règle projet exigeant qu'aucune erreur ne passe en silence sous `set -euo pipefail`.
- BLOQUANT : **Écrasement d'une variable vide (bris de critère d'acceptation)**. Dans `scripts/env.sh`, `[[ -n ${!name:-} ]]` vérifie si une variable est non vide. Si elle est explicitement définie mais vide dans l'environnement, elle sera écrasée par la valeur de `.env`. Cela casse le critère exigeant que la variable "déjà définie" (même vide) soit prioritaire. (*Fix : utiliser `[[ -v $name ]]` ou `[[ -n ${!name+x} ]]`*).
- NON BLOQUANT : **Test aveugle au SIGPIPE (verification-gap)**. Dans `scripts/tests/test-legal-address.sh`, les pages de test injectées sont trop petites pour remplir le tampon du pipe. `sed` finit de tout lire avant que `grep -q` ne ferme le pipe, masquant totalement le crash SIGPIPE qui se produira invariablement en production sur les vraies pages.
- NON BLOQUANT : **Absence de test sur un environnement vide (verification-gap)**. Dans `scripts/tests/test-env.sh`, aucun cas ne vérifie qu'une variable définie mais vide dans l'environnement bloque bien le repli sur les fichiers factices.
- NON BLOQUANT : **Message d'erreur obsolète (prose)**. Dans `layouts/_partials/legal-value.html`, le message `errorf` affiche « les sept sont %s » alors que la liste validée `$connus` contient correctement les huit variables de la révision d'architecture.

VERDICT: BLOQUANT — Le contrôle C23 plante (SIGPIPE) au lieu de signaler une fuite et masque les erreurs de la commande file, et le chargeur écrase les variables vides en violant les critères d'acceptation.

### Décision sur les constats du troisième tour (23/09/2026)

**Réfuté sur la cause, corrigé quand même — le SIGPIPE.** Le relecteur craignait qu'un `grep -q` fermant tôt tue `sed` et fasse rendre 141 au pipeline sous `pipefail`, lu comme une anomalie. **Mesuré : cela ne se produit pas**, ni sur 400 Ko ni sur 20 Mo — `grep` lit jusqu'au bout et `sed` rend 0. Le mécanisme décrit n'existe pas. La forme est néanmoins changée : le décodage est capturé dans une variable au lieu d'alimenter `grep` par un tuyau, ce qui rend le code de `sed` lisible pour lui-même. Le doute se ferme, et la lecture y gagne.

**Retenu — l'échec de `file` sortait un fichier du contrôle.** `|| encodage=binary` traitait un outil absent ou un fichier illisible comme un binaire à sauter : un garde-fou qui s'ouvre en cas de panne. Désormais un `file` en échec fait **lire** le fichier. Se tromper en lisant coûte un faux signalement ; se tromper en sautant laisse fuiter une adresse.

**Retenu — une variable définie vide était écrasée.** `[[ -n ${!name:-} ]]` traitait une variable définie mais vide comme absente, et le fichier factice la remplaçait. Le critère de la story 2.4 dit « la variable **déjà définie** » : une variable exportée vide l'est. Avec `[[ -v ]]`, un `HUGO_LEGAL_PUBLISHER_NAME=` explicite survit et arrête le build, ce que l'opérateur a demandé en la vidant. Un cas de test le couvre, et il échoue avec l'ancienne forme.

**Retenu — le test aveugle à l'environnement vide.** C'est le cas ci-dessus. Le second manque signalé, un test du SIGPIPE, n'a pas lieu d'être : le phénomène ne se reproduit pas, et un cas qui n'échoue jamais ne prouve rien.

### 23/09/2026 — `8e010f5` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f21b04c4aa8e00a35e14c166

##### Constats BMAD Review (edge-case-hunter, verification-gap) et Projet

BLOQUANT : **Erreur de lecture ignorée (laisse passer une erreur en silence).** Dans `scripts/checks/legal-address.sh`, l'appel `$(cat "$fichier")` et `$(cat "$public/$fichier_relatif")` est placé directement en argument de `contient_adresse` au sein d'une condition `if`. Sous bash, `set -e` est neutralisé pour toutes les commandes participant à l'évaluation d'un `if`. Si `cat` échoue (par exemple pour droits insuffisants), l'erreur est ignorée, la substitution renvoie une chaîne vide, et le contrôle passe au fichier suivant en concluant à tort que l'adresse est absente, laissant fuiter une adresse potentielle en cas de fichier illisible.
NON BLOQUANT : **Faille sans test de repli (verification-gap).** Dans `scripts/checks/legal-address.sh`, la logique de repli `|| file_code=$?` a été judicieusement ajoutée pour lire les fichiers même quand l'outil `file` échoue. Cependant, aucun cas dans `test-legal-address.sh` ne simule l'absence de `file`. Si quelqu'un retire ce garde-fou à l'avenir, la régression sera indétectable car `file` réussit toujours dans l'environnement de test (les fichiers non-HTML/PDF seraient alors ignorés en silence).
NON BLOQUANT : **Entité hexadécimale manquante (edge-case-hunter).** Dans `scripts/checks/legal-address.sh`, la fonction `decoder_entites` décode l'apostrophe décimale `&#39;` et nommée `&apos;`, mais oublie la forme hexadécimale `&#x27;`. Même si Hugo émet la forme décimale, un minifieur tiers ou un changement de moteur pourrait produire de l'hexadécimal, ce qui rendrait C23 de nouveau aveugle à la fuite.
NON BLOQUANT : **Ligne .env malformée (edge-case-hunter).** Dans `scripts/env.sh`, si une ligne correspond au motif `HUGO_LEGAL_*` mais ne contient aucun signe `=` (ex: `HUGO_LEGAL_PUBLISHER_NAME` écrit seul), l'expression `${line#*=}` ne trouvant pas de séparateur renverra la ligne entière. La variable sera ainsi sournoisement exportée avec son propre nom comme valeur au lieu d'être vide ou rejetée.
NON BLOQUANT : **Message d'erreur obsolète (prose).** Dans `layouts/_partials/legal-value.html`, la fonction `errorf` affiche toujours « les sept sont %s », alors que l'architecture et la liste `$connus` ont été révisées pour contenir huit valeurs. Cette erreur signalée lors d'un tour précédent n'a pas été purgée.

VERDICT: BLOQUANT — Le contrôle C23 laisse passer silencieusement une erreur de lecture de fichier car le mécanisme set -e est suspendu par la condition if, ouvrant une brèche dans le garde-fou.

### Décision sur les constats du quatrième tour (23/09/2026)

**Retenu, bloquant — l'échec de `cat` était avalé.** `if contient_adresse "$(cat "$fichier")"` : `set -e` est neutralisé dans une condition, donc un fichier illisible rendait une chaîne vide que le contrôle lisait comme « pas d'adresse ». Le fichier est désormais lu avant la condition, et un échec est une anomalie.

**Retenu — les entités hexadécimales.** `decoder_entites` ne connaissait que les formes décimale et nommée. Hugo émet du décimal, mais un autre outil peut écrire `&#x27;`. Les trois écritures sont décodées, casse comprise.

**Retenu — « les sept sont » dans le message du partial.** Un nombre écrit en dur devenu faux : **la troisième fois dans cette seule story**, après les deux cas de `test-env.sh`. Le message énumère désormais au lieu de compter.

**Retenu — le cas manquant sur l'absence de `file`.** Ajouté, et il a immédiatement montré que la condition sur le code de `file` était **redondante** : un `file` en échec rend déjà une chaîne vide, qui n'est pas « binary ». Une garde qu'aucun test ne distingue n'est pas une garde. La valeur de repli est écrite en clair — `encodage=inconnu` — et c'est elle qui porte l'intention ; le cas échoue si on la remplace par `binary`.

**Réfuté — une ligne `.env` sans `=`.** `dotenv_read` les filtre déjà (`scripts/lib/dotenv.sh:32`, `[[ $line == *=* ]] || continue`). Une telle ligne n'atteint jamais le chargeur.

### Un défaut de ma main, trouvé en corrigeant

Le passage à `[[ -v ]]` **a cassé le build du poste** : une entrée vide de `.env` était prise pour une consigne. Les deux critères se lisent ensemble — l'environnement de l'appelant l'emporte même vide, mais « un `.env` qui n'en porte qu'une partie ne fait pas échouer le build ». Le relevé des variables posées par l'appelant est donc pris **avant** toute lecture de fichier. Constaté en lançant les contrôles, pas en relisant. Et la garde que j'avais ajoutée à côté était, elle aussi, redondante : retirée.

### 23/09/2026 — `691cf6f` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 51fa6564790efb6e9fee64ce

##### Rapport de revue (BMAD Review)

###### Lentilles BMAD (`verification-gap`, `edge-case-hunter`) et contrôles projet

- BLOQUANT : **Faux négatif silencieux sur les adresses multi-lignes (verification-gap / edge-case-hunter)**. Dans `scripts/checks/legal-address.sh`, la fonction `contient_adresse` utilise `grep -q -F -e "$adresse"` pour détecter la présence de l'adresse de l'éditeur. `grep` traite l'entrée ligne par ligne. Si la variable `HUGO_LEGAL_PUBLISHER_ADDRESS` définie dans `.env` contient un retour à la ligne (ce qui est standard pour une adresse postale), `grep` ne trouvera jamais la chaîne entière puisqu'elle s'étend sur plusieurs lignes. Le contrôle C23 passera alors au vert en silence, créant un faux négatif qui laissera fuiter l'adresse complète de l'éditeur. *Correction : utiliser la recherche de sous-chaîne native de bash `[[ "$decode" == *"$adresse"* ]]` qui gère parfaitement les chaînes multi-lignes sans outil externe.*
- NON BLOQUANT : **Critères d'acceptation respectés**. Les vérifications du partial, la structure des mentions légales en `legal-list` et la non-présence de l'adresse dans les éléments `meta`, `title` et autres fichiers hors contexte sont implémentées fidèlement. L'usage de `legal_publication_director` comme terme de liste respecte parfaitement la séparation entre contenu et interface.
- NON BLOQUANT : **Absence de fuites et de secrets (Projet)**. Aucun secret ni donnée privée n'est commité (`ci/legal-placeholder.env` utilise strictement `VALEUR-FACTICE`). L'exclusion explicite des fichiers `.pdf` dans la boucle de C23 est correcte, car leur contrôle face aux motifs privés est déjà pris en charge par le garde-fou C21.
- NON BLOQUANT : **Cohérence et architecture (Projet)**. L'architecture est scrupuleusement suivie (les documents, scripts et tests reflètent tous le passage de 7 à 8 variables), et C23 s'exécute de façon sûre sous le chargeur unique `env.sh` (garantissant l'injection des valeurs) tel qu'exigé par AD-9.
- NON BLOQUANT : **Gestion des pannes et erreurs silencieuses (Projet)**. Les failles signalées dans les revues précédentes (telles que le saut des fichiers illisibles, l'avalement des codes de sortie de `cat` ou `file`) sont fermées de façon robuste. La commande de décodage `sed` est extraite du pipeline pour que sa sortie (et un éventuel échec) ne soit jamais masquée par l'exécution conditionnelle, respectant `set -euo pipefail`.

VERDICT: BLOQUANT — Le contrôle C23 (legal-address.sh) est aveugle aux adresses contenant des retours à la ligne car grep traite l'entrée ligne par ligne, risquant de laisser passer la fuite en silence.

### Décision sur le constat du cinquième tour (23/09/2026)

**Retenu sur la conclusion, réfuté sur le mécanisme.** Le relecteur voulait la comparaison native de bash plutôt que `grep -F`, et il a raison. Mais sa raison — « grep travaille ligne par ligne, une adresse multi-lignes lui échappe, faux négatif silencieux » — **est fausse** : `grep -F` avec un motif contenant un saut de ligne ne rate rien, il découpe le motif en autant d'alternatives. Constaté en essayant de faire échouer le cas multi-lignes avec `grep`, et en n'y arrivant pas.

Le vrai risque était l'inverse : un faux **positif**. Une page ne portant qu'une ligne de l'adresse aurait été signalée comme portant l'adresse. Ce que C23 garde, c'est l'adresse ; une commune seule relève de la liste des motifs interdits et de C22, faits pour elle.

Deux cas distinguent désormais les implémentations : l'adresse entière est vue, une ligne seule ne suffit pas. C'est le second que `grep` échoue.

La comparaison de bash est de toute façon la meilleure des deux : elle traite une chaîne comme une chaîne sans qu'on le demande, et elle retire un outil externe, donc un code de retour à interpréter.

### 23/09/2026 — `7f38af8` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: c7e15bfceca017bf1c323678

- BLOQUANT : **Faux négatif silencieux sur le JSON-LD (verification-gap / edge-case-hunter).** Le contrôle C23 (`scripts/checks/legal-address.sh`) décode les entités HTML (`decoder_entites`) pour retrouver la chaîne brute avant de la comparer. Or, dans le contexte d'une balise `<script type="application/ld+json">`, Hugo (via l'encodeur JSON de Go) ne produit pas d'entités HTML mais des séquences d'échappement Unicode (`\u0026` pour l'esperluette). Si l'adresse contient un `&` (comme c'est le cas dans la fixture), elle fuira sous la forme `\u0026` ; la fonction de décodage l'ignorera et le contrôle passera au vert en laissant l'adresse s'échapper en silence. Le test unitaire `case_legal_adresse_dans_le_json_ld` masque cette faille en injectant naïvement la variable brute (`$adresse`) dans le JSON au lieu d'utiliser une forme réalistement sérialisée (violation de la règle 16 d'AGENTS.md : la fixture ne ressemble pas à la vraie page).
- NON BLOQUANT : **Critères d'acceptation et cohérence (Projet).** Les critères de la story sont rigoureusement respectés et la solution est cohérente avec les décisions d'architecture (AD-9). L'introduction des huit valeurs légales via le pont du shortcode est bien implémentée, et la logique du chargeur `env.sh` gère excellemment la distinction entre les variables posées vides par l'appelant (qui survivent) et les entrées vides d'un fichier (qui déclenchent le repli).
- NON BLOQUANT : **Absence de fuite et de données privées (Projet).** Aucun secret, aucune donnée personnelle ou coordonnée réelle n'a été commité. Les espaces réservés (comme `ci/legal-placeholder.env`) utilisent strictement des valeurs factices. 
- NON BLOQUANT : **Gestion des erreurs et scripts (Projet).** Aucune erreur ne passe sous silence grâce aux interceptions explicites (`|| rc=$?`, `|| encodage=inconnu`). La lecture des fichiers via `cat` a été extraite des conditions `if` pour que `set -euo pipefail` s'applique sans être neutralisé. Procédures et scripts concordent parfaitement.

VERDICT: BLOQUANT — Le contrôle C23 ne décode pas les séquences d'échappement Unicode JSON (`\u0026`), laissant passer silencieusement une fuite d'adresse dans le JSON-LD, faille masquée par un test unitaire aveugle à la sérialisation réelle.

### Décision sur le constat du sixième tour (23/09/2026)

**Retenu, et vérifié sur pièces.** L'encodeur JSON de Go n'écrit pas d'entités HTML mais des séquences Unicode : mesuré sur un build, `jsonify` rend `\u0026` pour l'esperluette et `\u003c` / `\u003e` pour les chevrons. Le décodeur de C23 ne connaissait que les entités : une adresse portant un `&` serait passée par le JSON-LD sans un mot.

Et **ma fixture le masquait** en injectant l'adresse brute dans le JSON. Règle 16 d'AGENTS.md, troisième fois dans cette story : une fixture qui ne ressemble pas à la vraie sortie rend le contrôle décoratif.

Le décodeur couvre désormais les **deux familles** d'échappement, et la fixture sérialise comme Hugo. Le cas échoue sans le décodage Unicode.

### 23/09/2026 — `361db08` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 7848db8de0bfb357ea2b2bda

#### BMad Review

##### Lentille Edge-Case Hunter

- BLOQUANT : **Faux négatif silencieux sur l'URL-encodage.** Dans `scripts/checks/legal-address.sh`, si l'adresse fuit à l'intérieur d'un attribut de lien (ex: `href`, `src`) par l'action d'un gabarit, elle subira l'encodage URL automatique de Go (les espaces devenant `%20` ou `+`, l'apostrophe `%27`). La fonction `decoder_echappements` ne la décode pas ; C23 sera aveugle à la fuite et restera vert. (*Correction : ajouter une étape de décodage URL au pipeline de nettoyage*).
- BLOQUANT : **Faux négatif silencieux sur les balises OpenGraph et Twitter.** Le contrôle C23 limite son extraction XPath à `<meta name="description">`. Or, Hugo génère couramment les attributs OpenGraph (`og:description`) et Twitter (`twitter:description`) qui alimentent les aperçus sociaux mentionnés dans AD-9. L'adresse (qui peut se glisser dans `.Summary`) y fuitera en silence. (*Correction : étendre l'extraction XPath pour englober les attributs `property="og:description"` et `name="twitter:description"`*).

##### Lentille Verification-Gap

- BLOQUANT : **Faille masquée par l'absence de minification dans les tests (broken-verification-gap).** Le build de production minifie le HTML (`hugo --minify`), ce qui réduit les sauts de ligne et les espaces multiples d'une adresse postale à de simples espaces. Or, C23 cherche la chaîne exacte de `$adresse`. L'adresse minifiée fuira sans alerter le contrôle. Le test `case_legal_adresse_sur_plusieurs_lignes` masque totalement cette régression car il génère sa fixture avec `printf` sans utiliser le moteur de Hugo, rendant la vérification décorative. (*Correction : normaliser les espaces de `$adresse` et `$decode` avant la comparaison*).

##### Couche propre au projet

- NON BLOQUANT : **Critères d'acceptation et architecture (AD-9) satisfaits.** Le passage aux 8 variables, l'intégration du chargeur unique, et le comportement attendu des variables vides (priorité à l'environnement, repli possible sur fichier) respectent scrupuleusement les exigences.
- NON BLOQUANT : **Aucune donnée privée, aucun secret.** Le fichier factice `ci/legal-placeholder.env` utilise des identifiants `VALEUR-FACTICE` et aucun message d'erreur de C23 n'affiche l'adresse testée sur la sortie standard ou d'erreur. Les mots de passe et jetons restent inaccessibles aux processus d'analyse.
- NON BLOQUANT : **Concordance et gestion des erreurs (set -euo pipefail).** Les pannes potentielles des commandes (`file`, `cat`, `sed`, outils `xpath`) sont toutes proprement interceptées avec des fallback (`|| encodage=inconnu`, `|| rc=$?`) et ne font pas planter les pipelines de contrôle silencieusement, respectant le mode strict de bash.

VERDICT: BLOQUANT — Le contrôle C23 comporte trois angles morts majeurs (absence de décodage URL, balises OpenGraph ignorées, et faille face à la minification des espaces) masqués par un test mocké, permettant à l'adresse de fuiter silencieusement en production.

### Décision sur les constats du septième tour (23/09/2026)

**Retenu — la minification aplatit l'adresse.** Une adresse sur deux lignes arrive sur une seule dans le rendu de production ; la comparer sauts de ligne compris ne trouvait rien. Les blancs sont ramenés à une espace simple des deux côtés. Les fixtures écrites par `printf`, sans passer par Hugo, ne pouvaient pas le montrer : celle du nouveau cas écrase les blancs elle-même.

**Retenu — les balises sociales.** Ne viser que `meta[@name="description"]` laissait passer `og:description` et `twitter:description`, que Hugo pose couramment et qui nourrissent les aperçus de partage. Plutôt que d'ajouter ces deux noms, le contrôle prend **toute** balise portant un `content` : énumérer les noms qu'on imagine est la faute que la rétrospective de l'epic 7 a nommée.

**Refusé — l'URL-encodage.** Le chemin suppose un gabarit qui écrirait l'adresse dans un attribut de lien. Aucun ne le fait, et `legal-value.html` refuse déjà toute lecture hors des deux pages légales : il faudrait l'écrire exprès. Décoder `%XX` sur toute page coûterait des faux positifs sur les chaînes de requête, et décoder `+` en espace en créerait partout. Reporté dans `deferred-work.md`, pointé sur la story 9.6, qui est la première à pouvoir s'en approcher.

### Sur le nombre de tours

Sept tours, six verdicts bloquants. C'est plus que les six de la story 7.1, et le motif diffère : là-bas, les six tours poursuivaient **une seule** question — « qu'est-ce que cette condition ne voit pas ? ». Ici, chaque tour a trouvé une **sérialisation de plus** de la même chaîne : entité HTML décimale, hexadécimale, nommée, séquence Unicode du JSON, aplatissement par la minification, encodage d'URL. Le contrôle compare une chaîne à un texte que six couches peuvent réécrire.

La leçon pour la rétrospective de l'epic 9 : **un contrôle qui compare une valeur à une sortie doit d'abord se demander combien d'écritures cette valeur peut prendre en chemin**, et normaliser plutôt qu'énumérer. Les deux corrections qui ont tenu — décoder, puis aplatir les blancs — sont des normalisations ; celles qui ont dû être reprises étaient des énumérations.

### 23/09/2026 — `e806cca` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d468865bf9995629b3088311

##### Lentilles Edge-Case Hunter & Verification-Gap
- BLOQUANT : **Faux négatif silencieux sur les retours à la ligne dans le JSON-LD.** Dans `scripts/checks/legal-address.sh`, l'adresse est normalisée en remplaçant les retours à la ligne réels par des espaces via `normaliser_blancs`. Cependant, dans un bloc `<script type="application/ld+json">`, l'encodeur JSON de Go (utilisé par Hugo) sérialise un retour à la ligne sous la forme de deux caractères littéraux `\n`. La fonction `decoder_echappements` ne décode pas cette séquence. Une adresse multi-lignes fuira donc dans le JSON-LD sous la forme littérale `Ligne 1\nLigne 2`, ce qui ne correspondra pas à l'adresse normalisée `Ligne 1 Ligne 2`. C23 restera vert en laissant fuiter l'adresse en silence. Le test unitaire `case_legal_adresse_dans_le_json_ld` masque cette faille car son adresse d'essai `$adresse` tient sur une seule ligne.

##### Couche propre au projet
- NON BLOQUANT : **Critères d'acceptation respectés.** Le contrôle C23, le partial de lecture et le shortcode valident l'architecture AD-9 sans que l'intention des critères soit vidée. Les libellés relèvent bien de l'interface (traduction) et le chargeur unique applique correctement les priorités d'environnement.
- NON BLOQUANT : **Absence de données privées et secrets.** Aucune donnée réelle n'est commitée, les tests utilisent des valeurs factices, et les messages d'erreur n'affichent jamais la valeur brute de l'adresse testée sur la console ou dans les journaux.
- NON BLOQUANT : **Concordance script/procédure et architecture.** Le changement est parfaitement cohérent avec AGENTS.md et l'architecture AD-9. Les 8 variables légales sont toutes implémentées et contrôlées.
- NON BLOQUANT : **Aucune erreur ne passe en silence (set -euo pipefail).** Les échecs possibles des commandes de lecture (`cat`, `file`, commandes d'extraction `xpath`) sont explicitement gérés et interceptés (`|| rc=$?`, `|| encodage=inconnu`, `|| checks_die`) sans faire échouer les pipelines silencieusement.

VERDICT: BLOQUANT — Le contrôle C23 est aveugle aux retours à la ligne sérialisés littéralement (\n) dans le JSON-LD, permettant à une adresse multi-lignes de fuiter en silence, faille masquée par un test unitaire mono-ligne.

### Décision sur le constat du huitième tour (23/09/2026)

**Retenu, et c'est exactement la classe nommée au tour précédent.** Dans un JSON-LD, un saut de ligne s'écrit `\n` — deux caractères littéraux —, que le décodeur ignorait. Une adresse multi-lignes y fuyait sans être reconnue sous aucune forme. La sixième sérialisation de la même chaîne.

La parade suit la leçon écrite un tour plus tôt : **normaliser, pas énumérer**. Les séquences `\n`, `\r` et `\t` deviennent une espace, que `normaliser_blancs` ramènera de toute façon à une espace simple. Le cas ajouté échoue sans cette ligne — vérifié après avoir constaté qu'une première épreuve concluait à tort, son `python` ayant échoué avant d'appliquer la dégradation, si bien que le `||` imprimait « échoue » sans que rien n'ait été éprouvé.

### 23/09/2026 — `a265601` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 98. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 0e17a13440cb3c0ef182a31f

##### Lentille Edge-Case Hunter
- NON BLOQUANT : **Décodage robuste et complet.** La fonction `decoder_echappements` neutralise efficacement les encodages multiples : entités HTML (décimales, hexadécimales, nommées) et séquences Unicode du JSON-LD (ex: `\u0026`, `\n`). Couplé à la normalisation des blancs, ce mécanisme détecte l'adresse même si elle est minifiée ou rendue sur plusieurs lignes, fermant la porte aux faux négatifs.
- NON BLOQUANT : **Comparaison de chaînes sécurisée.** Dans `scripts/checks/legal-address.sh`, la vérification `[[ $decode == *"$adresse_normalisee"* ]]` évalue la chaîne littéralement grâce aux guillemets. Les caractères spéciaux éventuels de l'adresse (points, parenthèses, tirets) ne risquent pas d'être interprétés comme des expressions régulières, évitant ainsi des faux positifs sur d'autres motifs de texte.
- NON BLOQUANT : **Extraction des numéros de téléphone.** L'assainissement de la valeur dans `legal-list.html` pour la balise `tel:` (`replaceRE "[^0-9]"`) préserve intelligemment le symbole `+` en tête de chaîne tout en éliminant les autres caractères. Cela assure la production d'un lien strictement conforme à la RFC 3966.

##### Lentille Verification-Gap
- NON BLOQUANT : **Tests fidèles à la sérialisation réelle.** Les tests de `test-legal-address.sh` injectent l'adresse formatée exactement telle qu'Hugo le ferait (les séquences Unicode en JSON-LD, les entités HTML, la suppression des sauts de ligne post-minification). L'angle mort des fixtures artificielles a bien été éliminé.
- NON BLOQUANT : **Cas limites de l'environnement couverts.** Le test `case_env_variable_definie_vide_reste_prioritaire` vérifie adéquatement qu'une variable définie mais vide par l'appelant a préséance sur les fichiers d'environnement (`[[ -z ${posees_par_l_appelant[$name]:-} ]]`). L'écrasement silencieux des configurations manuelles vides est définitivement prévenu.

##### Couche propre au projet
- NON BLOQUANT : **Critères d'acceptation respectés.** Le dispositif d'injection légal (AD-9) passe sans encombre à huit variables sans perdre l'intention d'origine : l'adresse, le nom et le contact sont insérés dans les pages légales sans encombrer les balises méta ou le `<title>`, ce que le contrôle C23 vérifie de manière stricte.
- NON BLOQUANT : **Aucune donnée privée ni secret compromis.** Le recours rigoureux à `ci/legal-placeholder.env` avec ses identifiants fictifs `VALEUR-FACTICE` empêche la compromission de coordonnées réelles. Par ailleurs, la journalisation des contrôles (notamment en cas d'erreur) est conçue pour nommer les fichiers fautifs, jamais les valeurs testées.
- NON BLOQUANT : **Concordance documentaire et architecturale.** La scission du paramètre « contact » en données unitaires (`EMAIL` et `PHONE`) se reflète impeccablement à la fois dans `ARCHITECTURE-SPINE.md`, dans le script `env.sh` et dans `test-env.sh`. L'utilisation centralisée du chargeur `env.sh` dans `check.sh` confirme la volonté architecturale du point d'entrée unique.
- NON BLOQUANT : **Rigueur face aux erreurs (`set -euo pipefail`).** Tous les appels faillibles (`file`, `cat`, ou les exécutions de `xmllint` via `checks_xpath`) sont sortis des clauses conditionnelles silencieuses (`if`) pour être isolés. Les codes de retour non nuls sont interceptés explicitement (`|| rc=$?` ou `|| checks_die`), bloquant le pipeline au lieu de générer des faux positifs.

VERDICT: NON BLOQUANT — aucune.

## Reporté
