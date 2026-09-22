# Story 7.2 : Conditional CV links in footer

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 7.2.

## Revue de spec

### 22/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `6841a24`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 7d364e56e00d8eca5968d119

Voici le rapport de revue de la spécification de la story 7.2, après application des trois lentilles du skill `bmad-review`.

##### Lentille adverse (Adversarial)

- **BLOQUANT** : L'en-tête indique « Couvre : [...] C21 », mais aucun critère d'acceptation ne vérifie l'implémentation ou le maintien de ce contrôle (qui concerne le contenu et les métadonnées des PDF selon AD-21). Cela crée une contradiction : si C21 relève de la story précédente (7.1), il doit être retiré de l'en-tête ; s'il fait partie de 7.2, ses critères de validation sont absents.
- **BLOQUANT** : Le récit utilisateur demande à Claire de trouver les CV « avec leur langue », mais le critère d'acceptation ne prescrit que l'affichage du libellé i18n `cv_pdf` sans indiquer comment la distinction de langue (FR ou EN) doit être matérialisée à l'écran. Implémentée telle quelle, la story afficherait deux liens visuellement identiques, ce qui empêcherait l'utilisateur de les distinguer.
- **BLOQUANT** : Le critère d'acceptation fige les chemins de destination vers `/cv/cv-fr.pdf` et `/cv/cv-en.pdf` (avec un slash initial absolu). Ceci contredit l'architecture (AD-2) qui impose l'usage de liens relatifs (générés via `.RelPermalink` sur les ressources de Hugo) et casserait le routage si l'application était déployée sur un autre chemin de base.
- **NON BLOQUANT** : Le format précis de la « taille lue au build » (unité comme Ko ou MB, formatage typographique et espace insécable) n'est pas spécifié, ce qui laisse le développeur deviner au risque de contredire les règles d'UX (UX-DR17 sur la typographie française).
- **NON BLOQUANT** : Le critère « le partial n'émet rien » en l'absence d'un PDF implique techniquement que la lecture du système de fichiers (`resources.Get` ou `os.Stat`) doit intercepter l'erreur pour ne pas faire échouer le build Hugo (`errorf`), ce qui n'est pas explicité mais reste déductible de la consigne.

##### Lentille structurelle (Structure)

- **NON BLOQUANT** : Bien que la story mentionne la validation de contraintes d'accessibilité (UX-DR6/UX-DR14), il n'est pas précisé si un attribut `download` ou un texte caché pour lecteur d'écran doit accompagner les liens PDF afin d'expliciter le téléchargement.
- **NON BLOQUANT** : Le premier bloc « Alors » concatène beaucoup trop de critères de validation hétérogènes (ordre, attribut HTML, taille, traductions, chemins), rendant la vérification unitaire complexe lors du test.

##### Lentille rédactionnelle (Prose)

- **NON BLOQUANT** : La phrase contenant les exigences nominales gagnerait en clarté si elle était scindée en une liste à puces (les liens présents, puis l'ordre, puis les attributs/libellés) plutôt qu'en un bloc monolithique lourd à lire.

##### À trancher avant d'implémenter

- Le contrôle C21 fait-il partie du périmètre de cette story (auquel cas il manque ses critères) ou est-il couvert par la dépendance 7.1 (à retirer de l'en-tête) ?
- Comment la langue (FR, EN) doit-elle s'afficher visuellement pour différencier les deux liens CV ?
- Quel format et quelle unité doivent être utilisés pour l'affichage de la taille (ex. "1,4 Mo") ?
- Validation de l'usage des URL relatives dynamiques de Hugo (`.RelPermalink`) en lieu et place des URL absolues fixées dans la spec.

### Tri de l'auteur (22/09/2026)

**Retenu — la langue ne se voyait nulle part.** Le récit demande à Claire de trouver les CV « avec leur langue » et le critère ne prescrivait que « le libellé i18n `cv_pdf` », ce qui aurait donné deux liens visuellement identiques. La langue est **dans le libellé**, comme `DESIGN.md` le prévoyait sans que la story le reprenne.

**Arbitrage d'Arnaud (22/09/2026)** : les deux langues emploient **la même construction**, harmonisée sur la forme anglaise — « CV (PDF, français, 312 Ko) » et « CV (PDF, English, 298 KB) ». `DESIGN.md` portait une forme française différente (« CV en PDF, français »), corrigée dans la même PR. Trois formes lui ont été présentées avec leur coût.

**Retenu, en le nuançant — les chemins absolus.** Le relecteur y voit une contradiction avec AD-2. **Essayé** : `resources.Get "cv/cv-fr.pdf"` rend un `.RelPermalink` de `/cv/cv-fr.pdf`, exactement le chemin que la spec figeait. Il n'y a donc pas de contradiction, mais le constat vise juste : un chemin **écrit à la main** cesserait d'être exact le jour où la ressource porterait une empreinte. Le critère exige désormais `.RelPermalink`.

**Retenu comme clarification — C21 dans la ligne « Couvre ».** Le relecteur demande de choisir : soit la story implémente C21 et ses critères manquent, soit elle ne le fait pas et il doit sortir de l'en-tête. Ni l'un ni l'autre : la story est **le pendant visible** de C21. La règle « ensemble ou rien » que C21 applique aux fichiers, le partial l'applique aux liens — un seul PDF, et rien ne s'affiche. La story le dit maintenant, et garde C21 sans critère propre.

**Retenu — le format du poids.** Non spécifié, donc deviné. Arbitrage d'Arnaud : Ko entiers, minimum 1 Ko, espace insécable avant l'unité. Une seule unité, parce que C21 borne les fichiers à 500 Ko et qu'une branche « Mo » serait du code qu'aucun contenu n'atteint — et qu'aucun cas de test ne pourrait exercer avec un vrai CV.

**Accepté tel quel — le `resources.Get` sur un fichier absent.** Le relecteur note qu'il faut intercepter le cas sans faire échouer le build. C'est déjà la forme que le projet emploie depuis la story 5.1, et pour une raison chèrement apprise : `resources.Get … | minify` sur une ressource absente **fait paniquer le build** au lieu de rendre nil. Le `with` porte sur l'obtention.

**Accepté tel quel — pas d'attribut `download`.** `DESIGN.md` ne le prévoit pas, et un lien vers un PDF que le navigateur sait afficher n'a pas à forcer le téléchargement : c'est au lecteur de choisir. Le libellé dit déjà « PDF » et le poids.

## Revue du code

### 22/09/2026 — `1f3b8ce` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 85. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: f766a68f0026b092e24a05f9

##### Revue BMAD

##### Lentille des cas limites (Edge-case-hunter)
- **NON BLOQUANT** : Le calcul de la taille en Ko via `math.Max 1 (math.Round (div (len .res.Content) 1000.0))` dans le partial `cv-links.html` est robuste. Même si le fichier est anormalement petit ou presque vide, la fonction renverra `1`, empêchant l'affichage du texte "0 Ko" sur le site.
- **NON BLOQUANT** : Le contrôle de rendu dans `site-footer.html` utilisant `trim $cv " \n\t"` est solide. Puisque le partial `cv-links.html` ne génère absolument aucune balise (pas même un `<li>` vide) lorsque les deux PDF ne sont pas présents simultanément, cette condition empêche efficacement le rendu d'un footer orphelin.
- **NON BLOQUANT** : La définition du fallback `racine_depot=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)` dans `pdf.sh` gère l'arborescence correctement. L'exécution dans un sous-shell évite de modifier le dossier courant de l'appelant.

##### Lentille des écarts de vérification (Verification-gap)
- **NON BLOQUANT** : L'exhaustivité des tests dans `scripts/tests/test-cv-links.sh` est excellente. Les règles métier telles que "ensemble ou rien", le positionnement prioritaire de la langue courante et le respect de l'espace insécable sont vérifiés directement sur la sortie générée par Hugo.
- **NON BLOQUANT** : Le cas de test `case_pdf_repli_sur_la_liste_du_depot` dans `test-pdf.sh` couvre efficacement le correctif apporté au comportement du fallback de `PRIVATE_PATTERNS_FILE`, garantissant que le contrôle de contenu s'applique sur le poste de développement même sans la variable d'environnement explicite.

##### Constats propres au projet

- **NON BLOQUANT** : Les critères d'acceptation de la story 7.2 sont intégralement satisfaits : l'usage exclusif de `.RelPermalink` (plutôt que des chemins en dur) protège le système de routage, et la traduction avec le même gabarit "CV (PDF, langue, poids)" est appliquée.
- **NON BLOQUANT** : Aucun fichier PDF d'essai n'est présent dans le diff ; le dossier `assets/cv/` demeure intouché, ce qui respecte la contrainte empêchant les données brutes ou potentiellement privées de se retrouver dans l'historique public.
- **NON BLOQUANT** : Aucune information sensible (adresse, téléphone, identifiants, secrets ou IP de serveurs) n'a été exposée par ces changements.
- **NON BLOQUANT** : L'intégration respecte totalement les décisions d'architecture (AD-2, AD-21). La délégation de la règle "ensemble ou rien" depuis le contrôle des fichiers vers l'interface utilisateur est assumée formellement dans `epics.md` et appliquée sans alourdir le code des pages principales.
- **NON BLOQUANT** : L'utilisation de chaînes conditionnelles bash du type `((bourrage == 0)) || { ... }` ou `((${#pos_fr} < ${#pos_en})) || { ... }` dans les tests gère judicieusement les évaluations arithmétiques fausses sans causer d'échec furtif ni déclencher l'arrêt inopiné sous la directive `set -euo pipefail`.

VERDICT: NON BLOQUANT — aucune

### Décision de l'auteur sur la revue du code de la PR n° 85

`1f3b8ce` (pass) : aucun constat, confirmations seulement. **Premier tour**, après les six qu'avait demandés la story 7.1.

Preuves sur la tête : `scripts/tests/run.sh`, 438 cas réussis dont 7 sur un vrai build aux trois états ; `scripts/check.sh`, 8 contrôles passés ; `scripts/check-private.sh staged`, rien. `assets/cv/` reste vide dans l'historique.

## Reporté
