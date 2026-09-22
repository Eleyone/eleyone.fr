# Story 6.3 : French typography applied at build

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 6.3.

## Revue de spec

### 22/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `ce1efe3`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: da2d425387289a99e007236b

#### Revue de la spec (Story 6.3)

**Plan de revue** : document classé comme `docs` (spec). Lentilles exécutées l'une après l'autre : `adversarial`, `structure`, `prose`.

##### Lentille Adverse (Adversarial Critique)

* **Entités Unicode ou caractères manquants**
  * **Condition :** La spec demande de remplacer l'espace ordinaire par "une espace fine insécable" ou "une espace insécable".
  * **Correction suggérée :** Spécifier les points de code Unicode ou entités HTML exacts à utiliser (U+202F / `&#8239;` pour l'espace fine insécable, U+00A0 / `&nbsp;` pour l'espace insécable).
  * **Conséquence :** BLOQUANT — Sans précision, le développeur peut utiliser `&nbsp;` partout, ne respectant pas `DESIGN.md` et la typographie française stricte.

* **Corruption du balisage et des attributs HTML**
  * **Condition :** Remplacement appliqué "au HTML rendu" tout en épargnant "un attribut contenant ces signes". 
  * **Correction suggérée :** Décrire comment le traitement ignore les attributs (comme `href="mailto:..."` ou `title="Note :"`) et le contenu des URL. Appliquer de simples expressions régulières (`replaceRE`) sur du HTML complet depuis un partial Hugo est dangereux et très susceptible de corrompre le balisage.
  * **Conséquence :** BLOQUANT — Cas oublié. Une approche naïve va casser les liens ou le balisage des pages FR.

* **Typographie sans espace préalable**
  * **Condition :** "aucune espace n'est insérée là où l'auteur n'en a pas mis."
  * **Correction suggérée :** Vérifier que c'est bien l'effet voulu. Si l'auteur écrit `Mot:` sans espace, aucune espace ne sera ajoutée. 
  * **Conséquence :** NON BLOQUANT — L'effet de bord existe mais il est explicitement assumé par la spec.

* **Faux négatifs dans le contrôle EN**
  * **Condition :** C24 échoue si "une page EN contient une espace insécable devant eux".
  * **Correction suggérée :** Le contrôle doit aussi faire échouer le build si une page EN contient une espace **fine** insécable, pas seulement une espace insécable standard.
  * **Conséquence :** BLOQUANT — Critère de test incomplet.

##### Lentille de Structure (Structure)

* **Méthode d'application du partial dans l'architecture Hugo**
  * **Condition :** `_partials/typo-fr.html` "appliqué au HTML rendu des pages FR (contenu, titres, encarts, libellés)".
  * **Correction suggérée :** Clarifier la portée. Hugo n'a pas de post-processeur global. Ce partial doit-il wrapper les variables individuellement (ex: `{{ partial "typo-fr" .Title }}`), ou bien s'appliquer uniquement sur la variable `.Content` ? Si appliqué partout, cela alourdit drastiquement les gabarits.
  * **Conséquence :** BLOQUANT — Deux lectures possibles impactant l'architecture de la couche de présentation. 

* **Vérification CSS dans le contrôle de typographie**
  * **Condition :** C24 (dans `typo.sh`) échoue si "la CSS contient `hyphens: auto`".
  * **Correction suggérée :** C'est testable et vérifiable par simple `grep`, même si vérifier du CSS dans un script lié à la ponctuation est atypique.
  * **Conséquence :** NON BLOQUANT — Le critère est techniquement clair.

##### Lentille Rédactionnelle (Prose)

* **Ambiguïté sur la position des espaces pour les guillemets**
  * **Condition :** La règle dit "celles à l'intérieur des « »" puis, pour C24 : "une espace insécable devant eux".
  * **Correction suggérée :** "devant eux" est ambigu pour les guillemets, puisqu'on veut tester l'espace *après* le `«` et *avant* le `»`. 
  * **Conséquence :** BLOQUANT — Formulation ambiguë qui rend le codage du contrôle C24 incertain.

---

##### À trancher avant d'implémenter

- **Sécurité HTML** : Le filtrage par `replaceRE` sur du HTML généré étant risqué (risque de modifier un `href` ou `title`), le partial doit-il n'être appliqué qu'au texte/markdown brut *avant* le rendu HTML (ex: via les render hooks de Goldmark), ou appliqué avec une Regex extrêmement robuste ignorant les balises HTML ?
- **Architecture d'application** : Le partial `typo-fr.html` doit-il encapsuler individuellement chaque affichage de titre/encart/libellé dans les `layouts/`, ou seulement le corps principal (`.Content`) ?
- **Entités exactes** : Confirmer l'usage explicite de `U+202F` (`&#8239;`) pour la fine insécable, et non uniquement `&nbsp;`.
- **C24 sur les pages EN** : Confirmer que C24 doit traquer les espaces insécables ET les espaces fines insécables sur les pages anglaises.

### Tri de l'auteur (22/09/2026)

Cinq constats bloquants, tous fondés, tous tranchables sans Arnaud : `DESIGN.md` et AD-23 portaient déjà les réponses que la story avait omis de recopier. C'est le genre de revue qui sert — elle ne trouve pas une erreur, elle trouve ce que la spec n'a pas dit.

**Retenu — les points de code.** `DESIGN.md` § « Typographie française et anglaise » les donne : espace **fine** insécable U+202F devant `;`, `!`, `?` et à l'intérieur des guillemets, espace insécable U+00A0 devant `:`. La story ne disait que « fine insécable » et « insécable », de quoi écrire `&nbsp;` partout et croire la règle tenue. Les points de code sont maintenant dans le critère.

**Retenu — la corruption du balisage.** AD-23 prescrit d'isoler `<pre>`, `<code>` et les balises avant tout `replaceRE`, mais la story ne le disait pas — et c'est la façon la plus probable de rater cette story : un `href="mailto:…"` ou un `title="Note :"` cassé en silence. Le critère le dit, et nomme ces deux exemples.

**Retenu — C24 sur les pages anglaises.** Le critère ne traquait que l'espace insécable U+00A0. Une espace **fine** insécable U+202F sur une page EN serait tout aussi fautive et passait. Les deux sont refusées.

**Retenu — l'ambiguïté des guillemets.** « une espace insécable devant eux » ne veut rien dire pour une paire : c'est **après `«`** et **avant `»`**. Le contrôle aurait été codé au jugé. La story nomme les deux places, et une case de check-list impose la même précision dans les messages du contrôle.

**Tranché, parce que la spec en portait déjà la réponse — le point d'application.** Le relecteur demande si le partial enveloppe chaque titre, encart et libellé, ou seulement `.Content`. AD-23 dit « sur le HTML rendu des pages de langue `fr` », ce qui admet les deux lectures. Retenue : **un seul point d'application**, le corps rendu, dans `layouts/baseof.html`. Envelopper chaque valeur alourdirait tous les gabarits et, surtout, la règle serait oubliée sur le premier gabarit écrit après cette story — les pages simples de l'epic 9, les pages légales. Un point d'application unique ne s'oublie pas.

**Accepté tel quel — aucune espace ajoutée.** Le relecteur le note sans le contester : « Mot: » écrit sans espace reste tel quel. C'est voulu, et c'est ce qui rend la règle sûre : elle ne fait que remplacer.

## Revue du code

### 22/09/2026 — `bf58a93` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 81. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 10625590d5a5f8033b617ecb

##### Revue BMAD

**Plan de revue** : exécution des lentilles `edge-case-hunter` et `verification-gap` (documents considérés : `REVIEW-DIFF.patch`, classe : `diff/code`).

###### Lentille `edge-case-hunter`

- **location:** `layouts/_partials/typo-fr.html` et `scripts/checks/typo.sh`
  **trigger_condition:** Espace et signe ponctuationnel séparés par une frontière de balise (ex. : `<strong>Attention </strong>:`)
  **guard_snippet:** Sensibiliser à cette syntaxe ou permettre au parseur/contrôleur d'ignorer les balises HTML en ligne
  **potential_consequence:** Le partial n'applique pas la règle, mais C24 (qui concatène les nœuds de texte) échoue sur une page au rendu visuel correct
  **Classification :** NON BLOQUANT

###### Lentille `verification-gap`

- **location:** `layouts/baseof.html`
  **trigger_condition:** Les textes des métadonnées (`<meta name="description">`, attributs OpenGraph) sont exclus de la composition
  **guard_snippet:** `{{ $desc = partial "typo-fr-texte.html" .Description }}` (et étendre C24 à l'inspection d'attributs spécifiques)
  **potential_consequence:** La typographie est oubliée dans les résultats des moteurs de recherche et les cartes sociales
  **gap_shape:** `missing-adoption-gap`
  **consumer:** Attributs `content` des `<meta>` dans la balise `<head>`
  **evidence:** Le partial n'est invoqué que depuis les corps de pages, et `typo.sh` extrait via `//text()` qui ignore délibérément les attributs
  **Classification :** NON BLOQUANT (car l'Epic cible formellement et strictement le « corps rendu » de la page)

##### Constats propres au projet

- **location:** `scripts/checks/typo.sh` (lignes 55, 58, 60, etc.) et `scripts/tests/test-typo.sh`
  **trigger_condition:** L'utilisation de la forme `! shell_grep -qF ... || signaler ...`
  **guard_snippet:** `shell_grep -qF ... || rc=$?; if ((rc > 1)); then exit $rc; elif ((rc == 0)); then signaler...`
  **potential_consequence:** Un code de retour `2` de `grep` (erreur syntaxique, fichier disparu ou illisible) est inversé en `0` par le `!`. L'erreur est avalée silencieusement au lieu d'interrompre l'exécution sous `set -euo pipefail`.
  **Classification :** BLOQUANT

- **location:** `_bmad-output/planning-artifacts/epics.md`
  **trigger_condition:** Le critère d'acceptation stipule expressément une application « depuis `layouts/baseof.html` », mais l'implémentation appelle le partial dans chaque gabarit principal individuel (`home.html`, `page.html`, etc.).
  **guard_snippet:** Mettre à jour l'AC dans `epics.md` pour qu'il reflète la décision technique (limite du moteur de template Hugo) actée dans `ARCHITECTURE-SPINE.md`.
  **potential_consequence:** La livraison contredit sa propre spécification mise à jour dans la même PR.
  **Classification :** BLOQUANT

VERDICT: BLOQUANT — Erreurs masquées silencieusement dans les scripts shell (grep) et contradiction formelle avec un critère d'acceptation.

### Décisions de l'auteur sur la revue du code de la PR n° 81

**Retenu, et c'est la deuxième fois de suite — la contradiction entre le critère et l'implémentation.** Le critère disait « depuis `layouts/baseof.html` » ; la livraison appelle le partial dans chaque gabarit principal, parce que Hugo ne sait pas capturer la sortie d'un `block`. J'ai écrit le critère avant de découvrir la contrainte, j'ai écrit la contrainte dans `ARCHITECTURE-SPINE.md`, et je ne suis pas revenu sur `epics.md`.

**La story 6.2 avait exactement le même défaut, relevé par la même lentille, deux heures plus tôt.** Le point 8 d'`AGENTS.md` dit qu'un document se lit en entier, pas en diff ; il ne dit pas qu'**un critère qu'on vient d'écrire se relit quand la solution change**. Deux occurrences en deux stories, même cause : la spec est réécrite au début, la contrainte se découvre pendant, et la spec n'est plus relue. À porter dans `AGENTS.md` à la rétrospective de l'epic 6.

Le critère dit maintenant ce que la livraison fait, et un critère de plus couvre le `<title>`, que la spec ignorait.

**Refusé, preuve à l'appui — les erreurs de grep avalées par le `!`.** Le relecteur écrit qu'un code 2 de grep, inversé par le `!`, passerait en silence. C'est exactement le piège que `shell_grep` existe pour fermer : il compare le code de grep et appelle `shell_die` dès qu'il dépasse 1. Essayé, sur un fichier absent, dans la forme incriminée :

```
$ ! shell_grep -qF -- "x" /chemin/absent/xyz || signaler
grep: /chemin/absent/xyz: Aucun fichier ou dossier de ce nom
script: recherche impossible (grep, code 2) : /chemin/absent/xyz
```

Ni le signalement ni la ligne suivante ne s'exécutent : le script est déjà mort. Le `!` ne voit jamais le 2. Le constat était juste sur `grep` nu, et la bibliothèque du projet est précisément ce qui le rend faux.

**Retenu comme limite écrite — l'espace séparée de son signe par une balise.** `<strong>Attention </strong>:` n'est pas composé par le partial, qui traite chaque nœud de texte isolément, et C24 le signale, puisqu'il concatène les nœuds. Le relecteur y voit une incohérence ; c'est en réalité le bon couple : le rendu **affiche** bien une espace ordinaire devant le « : », donc le signalement est fondé, et la correction est dans la source. La limite est écrite dans le partial.

**Accepté tel quel — les métadonnées.** Le site n'a aujourd'hui aucun `<meta name="description">` ni carte sociale. Le relecteur le classe lui-même non bloquant, l'epic visant le corps rendu. À reprendre le jour où ces balises existeront.

### 22/09/2026 — `e680ffe` — `gemini-3.1-pro-high` — verdict `block`

Rapport publié en commentaire de la PR n° 81. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 33b9aca879c74ea8a32b938d

#### Revue BMAD

##### Lentille `edge-case-hunter`

- **location:** `layouts/_partials/typo-fr-texte.html`
  **trigger_condition:** Le rédacteur insère manuellement une espace insécable `&nbsp;` (U+00A0) au clavier devant un signe double nécessitant une fine insécable U+202F (`;`, `!`, `?` ou guillemets).
  **guard_snippet:** `{{- $t = replaceRE "( | )([;!?])" " $2" $t -}}` (cibler à la fois l'espace ordinaire et l'espace insécable U+00A0 pour la corriger en fine).
  **potential_consequence:** Le partial ne corrige que l'espace ordinaire. L'insécable illégitime (U+00A0) reste dans la page HTML finale. Cela contredit l'intention de la spec : « et `&nbsp;` partout serait faux ».
  **Classification :** BLOQUANT

- **location:** `layouts/_partials/typo-fr.html`
  **trigger_condition:** Un caractère `<` littéral se retrouve dans le texte sans balise fermante `>` consécutive (bien que très rare car le Markdown échappe `<` en `&lt;`).
  **guard_snippet:** `{{- $out = printf "%s<%s" $out (partial "typo-fr-texte.html" $seg) -}}`
  **potential_consequence:** Le texte résiduel `$seg` non suivi d'un `>` est concaténé tel quel sans traverser le partial `typo-fr-texte.html`, laissant ses ponctuations doubles avec des espaces ordinaires non traitées.
  **Classification :** NON BLOQUANT

##### Lentille `verification-gap`

- **location:** `scripts/checks/typo.sh`
  **trigger_condition:** Sur une page `fr`, C24 teste uniquement la présence d'espaces ordinaires (`" $signe"`), mais ne vérifie pas l'absence d'espaces insécables `U+00A0` devant `;`, `!`, `?` et dans `« »`.
  **guard_snippet:** Ajouter `! shell_grep -qF -- "$insecable$signe"` pour chaque ponctuation (ainsi que pour les guillemets) dans le bloc de contrôle des pages FR.
  **potential_consequence:** Un texte FR contenant une mauvaise insécable `U+00A0` au lieu de la fine `U+202F` exigée passera le contrôle silencieusement, rendant le garde-fou C24 aveugle au problème.
  **gap_shape:** missing-verification-gap
  **consumer:** Rendus HTML des pages FR / pipeline CI.
  **evidence:** Le code de la branche `fr` de C24 ne recherche que l'espace ordinaire.
  **Classification :** BLOQUANT

- **location:** `scripts/checks/typo.sh`
  **trigger_condition:** Sur une page `en`, C24 vérifie l'absence de fine et d'insécable devant la ponctuation, et l'absence de fine dans les guillemets, mais oublie de vérifier l'absence d'insécable `U+00A0` dans ces mêmes guillemets.
  **guard_snippet:** Ajouter `! shell_grep -qF -- "«$insecable"` et `"$insecable»"` dans la branche de contrôle `en`.
  **potential_consequence:** Une page anglaise employant des guillemets français avec des espaces `U+00A0` ne fera pas échouer le contrôle, violant la règle d'interdiction stricte dictée par l'epic.
  **gap_shape:** missing-verification-gap
  **consumer:** Rendus HTML des pages EN.
  **evidence:** La branche `else` de C24 teste `$fine` pour les guillemets mais omet `$insecable`.
  **Classification :** BLOQUANT

#### Constats propres au projet

- **location:** `REVIEW-DIFF.patch`
  **trigger_condition:** Vérification des critères du projet (fuite de données, respect de l'architecture, robustesse des scripts).
  **guard_snippet:** Maintenir l'implémentation existante sur ces points.
  **potential_consequence:** Aucune donnée privée ni secret n'est exposé. Les scripts shell gèrent correctement leurs erreurs via `shell_grep` sans les étouffer sous `set -euo pipefail`. L'architecture (AD-23) de séparation du texte et des balises est respectée.
  **Classification :** NON BLOQUANT

VERDICT: BLOQUANT — Le script de composition (typo-fr-texte.html) et le contrôle (typo.sh) laissent tous deux passer l'usage de l'espace insécable U+00A0 là où une espace fine U+202F est requise, contredisant directement le critère d'acceptation de la story.

### Décisions de l'auteur sur la deuxième revue du code de la PR n° 81

Trois constats, tous retenus, et tous sur **le même angle mort** : j'avais traité l'espace ordinaire comme la seule faute possible, alors qu'une insécable **mal choisie** en est une autre — et le partial comme le contrôle la laissaient passer.

**Retenu — une insécable mal choisie n'était pas corrigée.** Un auteur qui tape U+00A0 devant un « ? » a voulu une insécable, mais pas celle que `DESIGN.md` prescrit là. Le partial ne remplaçait que l'espace ordinaire ; le texte sortait « composé » et faux. Les quatre substitutions acceptent désormais l'espace ordinaire, l'insécable et la fine, et posent celle qui revient à chaque signe. La règle devient idempotente au passage.

**Retenu — C24 ne voyait pas cette faute sur les pages FR.** Le même angle mort, du côté du contrôle : il ne cherchait que l'espace ordinaire. Chaque signe refuse maintenant l'espace ordinaire **et** l'insécable qui n'est pas la sienne — U+00A0 devant `;`, `!`, `?` et dans les guillemets, U+202F devant `:` — et le message dit laquelle est attendue, pour que la correction soit évidente.

**Retenu — C24 ne vérifiait qu'une espèce sur les guillemets anglais.** La branche EN testait `«` + fine et fine + `»`, jamais les insécables aux mêmes places. Comblé.

**Retenu — un `<` littéral sans `>`.** Ce segment repartait sans être composé. Il traverse désormais le traitement de texte, son `<` lui étant rendu. Cas rare, correctif d'une ligne.

**Le relecteur confirme cette fois le refus précédent** sur `shell_grep` : « les scripts shell gèrent correctement leurs erreurs via `shell_grep` sans les étouffer ». La preuve valait mieux qu'un argument.

### 22/09/2026 — `a47a802` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 81. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 93090853841a7d8f8eaa437f

##### Revue BMAD

**Plan de revue** : exécution des lentilles `edge-case-hunter` et `verification-gap` sur le diff de la PR n° 81 (`REVIEW-DIFF.patch`).

###### Lentille `edge-case-hunter`

- **location:** `layouts/_partials/typo-fr-texte.html`
  **trigger_condition:** Un auteur utilise des entités HTML littérales (`&nbsp;` ou `&#8239;`) dans le Markdown au lieu des caractères Unicode pour forcer des espaces insécables avant une ponctuation double.
  **guard_snippet:** Les expressions régulières basées sur `[   ]` ne ciblent que les caractères Unicode natifs. Le partial ne corrigera pas ces entités.
  **potential_consequence:** Si l'entité saisie est erronée (ex: `&nbsp;?`), le partial la laissera intacte. Toutefois, `xmllint` décodant automatiquement ces entités lors du contrôle C24, le script `typo.sh` fera échouer le build à juste titre. Le comportement de la chaîne reste donc globalement sûr, empêchant l'erreur d'atteindre la production.
  **Classification :** NON BLOQUANT

###### Lentille `verification-gap`

- **location:** `scripts/checks/typo.sh` (contrôle de la CSS)
  **trigger_condition:** La feuille de style CSS est minifiée par Hugo (via `resources.Minify` ou un outil tiers), ce qui supprime l'espace dans la déclaration `hyphens: auto`.
  **guard_snippet:** Utiliser une expression régulière compatible comme `shell_grep -qE -- "hyphens:\s*auto" "$f"`.
  **potential_consequence:** La chaîne exacte `"hyphens: auto"` n'étant plus présente dans le livrable minifié, la règle interdite passerait le contrôle C24 silencieusement.
  **gap_shape:** missing-verification-gap
  **consumer:** Fichiers CSS et pipeline de contrôle C24
  **evidence:** Le script effectue une recherche de chaîne stricte `grep -qF -- "hyphens: auto"` qui requiert explicitement l'espace pour faire échouer le test.
  **Classification :** NON BLOQUANT (la vérification suit la lettre exacte du critère d'acceptation de l'epic, mais s'avère fragile en cas de minification).

##### Constats propres au projet

- **Critères d'acceptation :** Satisfaits. Les points de code Unicode précis exigés par `DESIGN.md` sont appliqués de façon idempotente et exclusive. Les pages anglaises traversent le processus sans modification. Les balises HTML (et donc leurs attributs/URL) sont correctement isolées avant tout remplacement. Le traitement exclusif du `<title>` hors gabarits est assuré dans `baseof.html`. 
  **Classification :** NON BLOQUANT

- **Données privées et secrets :** Aucune fuite constatée. Aucun nom d'hôte, ni donnée privée, ni secret n'est ajouté au code source. L'outillage ne divulgue aucune adresse.
  **Classification :** NON BLOQUANT

- **Concordance skill / procédure / script :** Non applicable pour ce changement spécifique, aucun skill ni procédure n'étant modifié ou désynchronisé par la PR.
  **Classification :** NON BLOQUANT

- **Cohérence architecture et `AGENTS.md` :** Excellente. Le parti pris d'isoler le texte et de compter précisément l'ouverture et la fermeture des blocs `pre` / `code` / `script` / `style` respecte l'AD-23. Le choix technique d'un appel via chaque gabarit principal (`define "main"`) a été formellement intégré à `ARCHITECTURE-SPINE.md` et sanctuarisé par un test scripté dédié, éliminant tout oubli potentiel. Le statut de sprint est correctement renseigné en `review`.
  **Classification :** NON BLOQUANT

- **Gestion des erreurs (scripts shell) :** Le code est robuste sous `set -euo pipefail`. La syntaxe `! shell_grep ... || signaler ...` est sûre, la surcouche `shell_grep` évaluant le code de sortie `>1` pour stopper le script en cas d'erreur de `grep` (fichier illisible, introuvable), comme souligné par l'auteur dans ses notes de résolution. Aucune erreur n'est étouffée silencieusement.
  **Classification :** NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

### Décision de l'auteur sur la troisième revue du code de la PR n° 81

`a47a802` (pass) : aucun constat, confirmations seulement.

Preuves sur la tête : `scripts/tests/run.sh`, 409 cas réussis dont 18 de typographie ; `scripts/check.sh`, 7 contrôles passés ; `scripts/check-private.sh staged`, rien.

## Reporté

- Aucun constat reporté. Les métadonnées (`<meta name="description">`, cartes sociales) ne sont pas composées : elles n'existent pas encore sur le site. À reprendre le jour où elles seront écrites.
