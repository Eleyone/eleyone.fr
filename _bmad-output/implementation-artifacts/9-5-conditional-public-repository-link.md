# Story 9.5 : Conditional public repository link

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 9.5.

## Revue de spec

### 23/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `a135540`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1e82668a2bb83fe96fe70b70

##### Rapport de revue (BMAD)

###### Lentille : Adversarial (Edge cases & Verification gaps)

- **Condition de déclenchement** : Vérification conditionnelle par C12 sans parseur YAML.
  **Extrait de correction / garde-fou** : Spécifier la méthode technique permettant au script shell C12, qui n'a pas accès à un outil comme `yq` (selon AD-1), de savoir s'il doit exiger la présence du lien. Doit-il utiliser un simple `grep` sur `hugo.yaml` ou relâcher la validation exacte du nombre de liens dans le pied de page ?
  **Conséquence potentielle** : Le développeur risque d'écrire un contrôle bash fragile qui cassera la CI, ou de rester bloqué sur l'implémentation de C12.
  **Classement** : BLOQUANT

- **Condition de déclenchement** : Valeur finale à commiter pour `params.source_url`.
  **Extrait de correction / garde-fou** : La spec demande de valider le cas vide et le cas renseigné, mais ne précise pas avec quelle valeur de configuration la PR finale doit être fusionnée (valeur vide, ou URL publique réelle `https://github.com/Eleyone/eleyone.fr` connue depuis la story 1.4).
  **Conséquence potentielle** : La story pourrait être livrée avec la valeur vide, rendant la fonctionnalité absente en production, ou avec une URL erronée.
  **Classement** : BLOQUANT

- **Condition de déclenchement** : Clarté de la sortie du site dans le libellé.
  **Extrait de correction / garde-fou** : Le composant `link` (UX-DR) exige qu'un lien vers un site tiers le précise si ce n'est pas évident. Il faut statuer si "Code source du site" se suffit à lui-même, ou s'il faut le changer en "Code source du site (sur GitHub)".
  **Conséquence potentielle** : Le visiteur est surpris de quitter le site, créant un léger défaut d'expérience utilisateur.
  **Classement** : NON BLOQUANT

- **Condition de déclenchement** : Absence pure et simple de la clé de configuration.
  **Extrait de correction / garde-fou** : Le gabarit Hugo doit vérifier l'existence de la clé (ex: utilisation correcte de `isset` ou du comportement falsy de Hugo) et ne pas seulement tester si la chaîne est vide `""`.
  **Conséquence potentielle** : Le build Hugo pourrait échouer si la ligne `source_url:` est supprimée de la configuration à l'avenir.
  **Classement** : NON BLOQUANT

- **Condition de déclenchement** : Cohérence de la langue de destination (hreflang).
  **Extrait de correction / garde-fou** : Le README-cas du dépôt étant rédigé en anglais (FR-30), le lien de la version française pourrait nécessiter l'attribut `hreflang="en"` pour des raisons sémantiques.
  **Conséquence potentielle** : Perte de précision sémantique HTML lors de la navigation vers la forge.
  **Classement** : NON BLOQUANT

###### Lentille : Structure

- **Condition de déclenchement** : Architecture logique de la spécification.
  **Extrait de correction / garde-fou** : Le format (Given/When/Then) est rigoureux et reflète correctement les contraintes d'architecture. Le cas d'absence est bien couvert. Aucune contradiction structurelle interne n'est relevée.
  **Conséquence potentielle** : Aucune.
  **Classement** : NON BLOQUANT

###### Lentille : Prose

- **Condition de déclenchement** : Clarté rédactionnelle.
  **Extrait de correction / garde-fou** : La formulation est factuelle, va droit au but, et ne présente aucune ambiguïté de lecture qui pourrait mener à une mauvaise interprétation.
  **Conséquence potentielle** : Aucune.
  **Classement** : NON BLOQUANT

---

##### À trancher avant d'implémenter

- **Valeur de livraison :** La PR doit-elle commiter `params.source_url` avec une chaîne vide ou avec l'URL publique définitive (`https://github.com/Eleyone/eleyone.fr`) ?
- **Implémentation du contrôle C12 :** Quelle approche est attendue pour que le script bash C12 puisse vérifier conditionnellement la présence du lien sans disposer de parseur YAML ?
- **Validation du libellé :** Faut-il modifier le libellé en ajoutant explicitement la mention de la plateforme (ex: « (sur GitHub) ») pour s'aligner parfaitement avec les règles UX des liens externes ?

### Triage des constats (23/09/2026)

**Cette story était déjà livrée, et c'est le point 7 d'AGENTS.md qui a fonctionné.** La story 5.1 a posé `params.source_url` et le lien du pied de page, en **déclarant son anticipation** : « `params.source_url` relève de l'impact I-2 (AD-3), que la story 9.x porte. Cette story n'ajoute que la valeur du paramètre et le lien du pied de page qui en dépend ; elle ne touche ni les pages légales, ni la page “À propos”, ni aucun autre usage d'I-2. » La portée était nommée, la story propriétaire aussi.

**Les deux constats bloquants sont refusés, tous deux sur pièces.** Le relecteur lit la spec comme si rien n'existait — même forme qu'à la story 9.2.

- *« Spécifier comment C12 lit la YAML sans `yq` »* — déjà écrit et en service : `scripts/checks/links.sh:201` extrait la valeur par `sed`. Le contrôle n'est pas à écrire, il tourne.
- *« Avec quelle valeur la PR doit-elle être fusionnée ? »* — déjà commitée : `config/_default/hugo.yaml:57` porte `https://github.com/Eleyone/eleyone.fr` depuis la story 5.1.

**Non bloquants** — l'absence pure de la clé, la langue de destination du lien, et deux remarques de rédaction. Le premier est couvert par le même `sed` (une clé absente laisse `source_url` vide, donc pas de lien) ; le deuxième n'a pas lieu d'être, le dépôt n'ayant pas de version française.

### Ce qui reste, et que la revue n'a pas vu

Deux règles **sans aucun test**, l'une de cette story et l'autre héritée :

1. **Le premier critère d'acceptation n'est vérifié nulle part au niveau du rendu.** `test-links.sh` éprouve C12 sur du HTML fabriqué, pas le pied de page construit par Hugo. Rien ne dit qu'un `source_url` vide ne produit « ni lien factice, ni `#` ».
2. **« Le pied de page disparaît entièrement quand il n'a rien à dire »** — règle posée par la story 5.1, jamais éprouvée. Un filet surmontant du vide, ou un repère de navigation sans contenu, passerait sans un mot.

C'est là tout le contenu livrable de cette story : non pas du code, mais la vérification qui manquait à du code déjà en service.

## Implémentation

Aucun code de production : le lien, sa condition et son contrôle sont en service depuis la story 5.1, qui avait **déclaré son anticipation** en nommant cette story et sa portée exacte. Ce que la 9.5 livre, c'est la vérification qui manquait — et une question laissée ouverte, refermée.

- `scripts/tests/test-site-footer.sh` (nouveau) — cinq cas sur les **règles d'existence** du pied de page ;
- `EXPERIENCE.md` — les libellés du pied de page passent de « à valider par Arnaud » à **décidé**, et une clé mal nommée est corrigée : `footer_legal_notice`, non `footer_legal`.

### Deux règles qui tournaient sans test

| Règle | D'où elle vient | Éprouvée en dégradant |
|---|---|---|
| `source_url` vide → aucun lien, **ni factice, ni `#`** | premier critère de cette story | le lien rendu sans condition : le cas échoue |
| Le pied de page **disparaît entièrement** quand il n'a rien à dire | story 5.1, jamais testée | le pied de page rendu sans condition : le cas échoue |

Les trois autres cas sont les contre-épreuves — sans elles, un pied de page qui ne s'afficherait *jamais* passerait pour un pied de page qui disparaît à bon escient — et l'ordre des quatre entrées, vérifié d'un bout à l'autre plutôt que par paires.

### Une faute de mon test, corrigée avant la revue

Le cas du `source_url` vide cherchait `href=#` **dans toute la page** et trouvait le lien d'évitement `#content`, parfaitement légitime. Ramené au pied de page, avec la garde de présence que la revue de la PR n° 100 a imposée ailleurs — appliquée ici d'emblée plutôt qu'après coup.

## Revue du code

### 23/09/2026 — `c1ecbbe` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 101. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: d1a96984db5b7d0e8faa7de3

##### Rapport de revue (BMAD)

###### Lentille : Verification gaps
- **Condition de déclenchement** : La vérification de l'absence du lien (quand `source_url` est vide) et le contrôle de l'ordre des éléments ne ciblent que la page française (`index.html`).
  **Extrait de correction / garde-fou** : Dans les tests `case_footer_source_vide_aucun_lien_ni_factice` et `case_footer_les_quatre_entrees_dans_lordre`, ajouter les vérifications correspondantes pour la page anglaise (`en/index.html`). Il faut s'assurer de l'absence du libellé traduit "Site source code", et vérifier l'ordre des liens qui peut différer pour les CV en anglais (où l'ordre d'affichage pourrait inverser les fichiers FR et EN).
  **Conséquence potentielle** : Une régression (comme un lien mort ou un mauvais ordre) touchant spécifiquement le gabarit anglais ou les traductions anglaises ne serait pas détectée par les tests automatiques.
  **Classement** : NON BLOQUANT

###### Lentille : Edge cases
- **Condition de déclenchement** : Utilisation du délimiteur `#` dans l'instruction `sed` qui modifie `hugo.yaml`.
  **Extrait de correction / garde-fou** : L'injection de l'URL se fait via `sed -i "s#...#...: $source#"`. Si la variable de test `$source` contenait elle-même le caractère `#`, l'expression régulière échouerait.
  **Conséquence potentielle** : Rupture du test bash si l'URL factice du dépôt venait à utiliser un caractère d'ancrage (`#`). Avec la valeur actuelle (`https://exemple.invalide/depot`), ce risque est inactif.
  **Classement** : NON BLOQUANT

##### Couche propre au projet

- **Condition de déclenchement** : Les critères d'acceptation de la story sont satisfaits.
  **Extrait de correction / garde-fou** : La PR apporte formellement la couverture de test au niveau du rendu HTML (test de l'existence, de l'absence des liens factices, et de la disparition du pied de page), ce qui comble l'intention de la story 9.5 pour du code déjà en service depuis la story 5.1.
  **Conséquence potentielle** : Aucune.
  **Classement** : NON BLOQUANT

- **Condition de déclenchement** : Données privées et secrets.
  **Extrait de correction / garde-fou** : Aucun secret, token ni adresse réelle de forge privée n'est commité dans les scripts de test, l'URL employée étant explicitement factice (`https://exemple.invalide/depot`). L'utilisation du prénom Arnaud est autorisée (identité publique).
  **Conséquence potentielle** : Aucune.
  **Classement** : NON BLOQUANT

- **Condition de déclenchement** : Cohérence avec l'architecture et AGENTS.md.
  **Extrait de correction / garde-fou** : L'implémentation respecte la règle fondamentale d'éprouver le comportement dans les conditions réelles de sortie (fichiers HTML générés par Hugo) et s'aligne avec le refus de reproduire un garde-fou illusoire (le contrôle bash C12 sans parseur YAML est logiquement laissé de côté, tel qu'arbitré dans le fichier de la story).
  **Conséquence potentielle** : Aucune.
  **Classement** : NON BLOQUANT

- **Condition de déclenchement** : Gestion des erreurs dans les scripts shell sous `set -euo pipefail`.
  **Extrait de correction / garde-fou** : L'auteur manipule les appels de commandes en toute sécurité. Les assignations conditionnelles `html=$(page "$1") || { ... }` sont rigoureuses, et la déclaration locale `local pied` est volontairement séparée de l'assignation `pied=$(pied_de index.html)` pour garantir que le script intercepte un échec via `set -e`. De plus, l'absence de l'usage de `grep` (remplacé par des correspondances natives bash `[[ ... == *...* ]]`) élimine les faux positifs silencieux. Aucune erreur ne peut passer en silence.
  **Conséquence potentielle** : Aucune.
  **Classement** : NON BLOQUANT

VERDICT: NON BLOQUANT — aucune

## Reporté
