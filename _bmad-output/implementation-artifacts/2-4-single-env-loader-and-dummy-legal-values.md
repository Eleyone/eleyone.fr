# Story 2.4 : Single env loader and dummy legal values

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 2.4.

## Revue de spec

### 17/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `9855bc9`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 493c2ef9c14e5f14094f6372

### Revue LLM (BMAD Review) - Story 2.4

#### Lentille : Adversarial (Cas limites et robustesse)

- **lens**: adversarial
- **location**: Critères d'acceptation, "le chargeur ne lit que les lignes ^HUGO_LEGAL_ de .env, sans source complet ni set -a"
- **trigger_condition**: Variables contenant des espaces, des caractères spéciaux ou des guillemets.
- **guard_snippet**: Exiger une méthode d'extraction (parsing) capable de gérer nativement les valeurs complexes.
- **potential_consequence**: Interdire `source` ou `set -a` pour obliger l'utilisation d'outils comme `grep` exige de parser le contenu à la main. Une extraction naïve échouera ou tronquera la valeur si elle contient des espaces (`HUGO_LEGAL_PUBLISHER_NAME="Arnaud Grousset"`) ou si elle nécessite l'interprétation des guillemets, ce qui cassera le processus de build.

- **lens**: adversarial
- **location**: Critères d'acceptation, "scripts/build.sh et scripts/dev.sh passent par scripts/env.sh"
- **trigger_condition**: Ambiguïté architecturale entre l'utilisation comme "wrapper" (processus parent) ou fichier "sourcé".
- **guard_snippet**: Clarifier le mode d'invocation de `env.sh`.
- **potential_consequence**: Si `env.sh` est exécuté en tant que script séparé (`./scripts/env.sh`), ses variables d'environnement exportées seront perdues pour `build.sh` sauf s'il enveloppe explicitement le processus d'exécution (via l'usage de `"$@"`). À l'inverse, s'il est conçu pour être sourcé (`source scripts/env.sh`), il altère directement le contexte du shell parent. Le choix technique d'implémentation diffère radicalement selon l'approche souhaitée.

- **lens**: adversarial
- **location**: Critères d'acceptation, "Quand une variable est déjà définie... la valeur retenue est, dans l'ordre..."
- **trigger_condition**: Définition partielle dans `.env` (ex: 3 variables définies sur les 7 obligatoires).
- **guard_snippet**: Assurer une résolution granulaire (variable par variable) plutôt qu'un écrasement en bloc.
- **potential_consequence**: Si la logique de repli se fait au niveau du fichier et non de la variable, la présence d'un fichier `.env` incomplet pourrait empêcher de piocher les variables manquantes dans le fichier factice, conduisant au crash de Hugo.

#### Lentille : Structure (Cohérence et conception)

- **lens**: structure
- **location**: Critères d'acceptation, "désigne .env ou le fichier factice"
- **trigger_condition**: Identification des fichiers interdits pour `LEGAL_ENV_FILE` en mode `release`.
- **guard_snippet**: Valider l'identité réelle du fichier, au-delà de la stricte comparaison de chaînes.
- **potential_consequence**: Si le script compare uniquement par rapport aux chaînes exactes `".env"` et `"ci/legal-placeholder.env"`, le contrôle de sécurité peut être facilement déjoué par des chemins relatifs valides (ex: `./.env` ou `../copie/.env`), contournant ainsi le rejet exigé par la spec.

- **lens**: structure
- **location**: Critères d'acceptation, ".env.example (story 0.1) [...] liste exactement, sans valeur, les sept variables d'AD-9 et les trois GITEA_*"
- **trigger_condition**: Risque de déphasage avec les contrôles automatiques.
- **guard_snippet**: Aucune modification requise de la spec, mais l'implémentation du chargeur devra bien ignorer sans lever d'erreur la présence des trois variables Gitea lors de sa lecture de l'environnement, ce qui est couvert par l'instruction de ne lire que `^HUGO_LEGAL_`.
- **potential_consequence**: Confirme que le comportement attendu d'isoler les secrets Gitea du build Hugo est correctement aligné et défini.

#### Lentille : Prose (Clarté de la spécification)

- **lens**: prose
- **location**: Critères d'acceptation, "la valeur retenue est, dans l'ordre, celle déjà définie, celle de .env, celle du fichier factice."
- **trigger_condition**: Interprétation de l'expression "dans l'ordre".
- **guard_snippet**: Reformuler en "par ordre de priorité décroissant : la variable existante, sinon celle de `.env`, sinon celle du fichier factice."
- **potential_consequence**: L'expression "dans l'ordre" est ambiguë : cela pourrait aussi bien signifier l'ordre de priorité (le premier défini l'emporte) que l'ordre de chargement/surcharge (le dernier lu écrase le précédent).

#### À trancher avant d'implémenter

1. **Extraction de `.env` sans `source` :** L'extracteur imposé par la spécification (`grep ^HUGO_LEGAL_`) devra-t-il explicitement gérer les guillemets ou les valeurs comportant des espaces (comme `HUGO_LEGAL_PUBLISHER_NAME="Arnaud Grousset"`), ce qui rend le parsing bash considérablement plus complexe que la simple commande `source` ?
2. **Appel de `env.sh` :** Ce chargeur doit-il agir comme un *wrapper* qui enveloppe l'exécution de Hugo (ex : `scripts/env.sh hugo ...`), ou doit-il simplement être sourcé par les autres scripts (ex : `source scripts/env.sh`) ?
3. **Logique de repli par variable :** Confirmez-vous que la hiérarchie de priorité (Environnement courant > `.env` > Fichier factice) s'applique variable par variable, afin qu'un fichier `.env` incomplet puisse être complété de manière granulaire par les valeurs factices ?
4. **Validation de `LEGAL_ENV_FILE` :** Le rejet de `.env` et du fichier factice en environnement de `release` doit-il résoudre le nom de base (`basename`) pour interdire intelligemment les contournements du type `./.env` ?

### Triage des constats (17/09/2026)

| Constat | Décision | Suite |
| --- | --- | --- |
| A1 — valeurs avec espaces ou guillemets, sans `source` | **retenu** | le dépôt a déjà un lecteur de dotenv éprouvé : `load_gitea_env` (`scripts/lib/gitea.sh`), qui retire les guillemets et le commentaire de fin. Question à Arnaud : le refaire dans `env.sh`, ou le factoriser |
| A2 — `env.sh` enveloppe ou fichier sourcé | **retenu** | question à Arnaud ; la forme enveloppe rend la garantie « `hugo` ne voit pas `GITEA_TOKEN` » vérifiable de l'extérieur |
| A3 — repli variable par variable | **retenu** | un `.env` qui ne porte que trois des sept variables doit être complété par le fichier factice, sans quoi le build casse pour rien |
| S1 — `LEGAL_ENV_FILE` contourné par `./.env` | **retenu** | comparer les chemins **canoniques**, pas les chaînes ; question à Arnaud sur le refus par nom de base |
| S2 — les trois `GITEA_*` ignorées sans erreur | **retenu, déjà couvert** | le chargeur ne lit que les lignes `^HUGO_LEGAL_` ; la story le dit déjà, un critère le prouvera |
| P1 — « dans l'ordre » ambigu | **retenu** | critère reformulé en ordre de priorité décroissant |

## Ce qui est livré

| Fichier | Rôle |
| --- | --- |
| `scripts/lib/dotenv.sh` | **seul** lecteur de dotenv du dépôt : ligne à ligne, guillemets retirés, commentaire de fin ôté, jamais par `source` |
| `scripts/lib/gitea.sh` | emploie ce lecteur ; ses 97 cas de test passent inchangés |
| `scripts/env.sh` | enveloppe : prépare l'environnement, puis `exec` la commande. `set +x` dès la deuxième ligne |
| `ci/legal-placeholder.env` | les sept valeurs factices, chacune portant `VALEUR-FACTICE` |
| `scripts/build.sh`, `scripts/dev.sh` | tout appel à `hugo` passe par le chargeur |
| `scripts/tests/test-env.sh` | 13 cas hors ligne, sur des fichiers jetables |

### La garantie qui compte, vérifiable en une commande

`.env` porte les sept valeurs légales **et** les trois variables `GITEA_*`, dont le jeton d'API. Le chargeur ne lit que les lignes `^HUGO_LEGAL_` :

```
$ scripts/env.sh sh -c 'env | grep -c "^HUGO_LEGAL_"; env | grep -c "^GITEA_" || true'
7
0
```

Sept valeurs légales atteignent Hugo, **zéro jeton**. C'est la forme « enveloppe » qui rend ce contrôle possible depuis l'extérieur, sans lire une ligne de code.

### Essais

| Règle | Essai | Résultat |
| --- | --- | --- |
| Priorité décroissante | variable déjà définie, puis `.env`, puis fichier factice | la première trouvée l'emporte |
| Repli variable par variable | `.env` ne portant qu'une des sept | les six autres viennent du fichier factice, le build ne casse pas |
| Valeur entre guillemets | `HUGO_LEGAL_PUBLISHER_NAME="Nom Avec Espaces"   # commentaire` | `[Nom Avec Espaces]` : guillemets retirés, espaces gardés, commentaire ôté |
| Jetons isolés | `.env` avec `GITEA_TOKEN` | aucune variable `GITEA_` dans l'environnement lancé |
| Mise en ligne sans `LEGAL_ENV_FILE` | — | refus, code 1 |
| Mise en ligne désignant `.env` ou le fichier factice | chemin direct **et** `./.env` détourné | refus, code 1, par chemin canonique |
| Mise en ligne désignant un `.env` hors du dépôt | `../ailleurs/.env` | refus, code 1, par nom de base |
| Mise en ligne, fichier dédié incomplet | six variables sur sept | refus nommant la variable, **sans afficher de valeur** |
| Mise en ligne, fichier dédié complet | sept valeurs réelles | acceptée, aucune `VALEUR-FACTICE` ne subsiste |

`scripts/tests/run.sh` : **97 cas** (84 avant la story), tous verts sur le poste **et** dans `alpine:3.24` — y compris sans `coreutils`, le `readlink -f` de BusyBox suffisant au chargeur.

### Un piège évité de justesse

En factorisant le lecteur, j'ai d'abord écrit `done < <(dotenv_read …)` — exactement le piège que la rétrospective de l'epic 0 a fait inscrire dans `docs/procedures/shell-scripts.md` : l'échec de la fonction est masqué et la boucle tourne sur une liste vide. Corrigé avant tout commit : la liste est lue dans une variable, avec son arrêt. La liste des pièges a servi à quelque chose.

## Revue du code

### 17/09/2026 — `062f360` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 28. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 01667ab2cb5b24ed7c6c0b5d

##### Revue LLM (BMAD Review) - Story 2.4

*Fichier relu : `REVIEW-DIFF.patch`*
*Lentilles exécutées : `edge-case-hunter`, `verification-gap`*

**Lentille : edge-case-hunter (Analyse des cas limites et chemins orphelins)**
```json
[]
```
*Le balayage exhaustif des chemins (gestion des valeurs avec guillemets simples ou doubles, avec ou sans espaces, avec commentaires `#`, existence et lisibilité des fichiers cibles, variables vides ou non définies) montre que les cas limites sont rigoureusement traités. Le fallback variable par variable (`[[ -n ${!name:-} ]] && break`) privilégie la variable si elle est définie et non vide, et l'usage des chaînes de sous-shells (ex. `lines=$(dotenv_read ...) || die`) protège le mode `set -euo pipefail`. Les tentatives de contournement de `LEGAL_ENV_FILE` (chemins relatifs comme `../.env` ou liens symboliques) sont solidement bloquées par la fonction `canonical` et le test de `basename`.*

**Lentille : verification-gap (Vérification des couvertures et non-régressions)**
```json
[]
```
*Aucune régression comportementale n'est laissée orpheline. L'extracteur factorisé dans `scripts/lib/dotenv.sh` utilise strictement la même logique que celle existante au préalable (auparavant dans `gitea.sh`). Les comportements prescrits par la story (isolation du `GITEA_TOKEN` dans le shell de Hugo, fallback per-variable, refus sur chemin trompeur, émission silencieuse du bon exit code sans lever les valeurs privées) sont entièrement vérifiés et verrouillés par les cas de test explicites ajoutés dans `scripts/tests/test-env.sh`.*

---

##### Constats propres au projet

- NON BLOQUANT : Les critères d'acceptation de la story sont entièrement satisfaits, sans aucune régression. Le chargeur ne source jamais le fichier, et l'étanchéité empêchant `GITEA_TOKEN` de contaminer le contexte du processus enfant `hugo` est confirmée par script et par test.
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte ni adresse de serveur ni secret n'est compromis. Les tests s'appuient exclusivement sur un fichier contenant `VALEUR-FACTICE` et des URLs factices du type `https://exemple.invalide`. Le script ne fait par ailleurs jamais écho d'une valeur ou d'une clé privée en cas d'erreur.
- NON BLOQUANT : Le changement est en parfaite cohérence avec `AGENTS.md` et les documents adjacents. Aucune commande mentionnée dans une procédure n'est falsifiée ou ignorée.
- NON BLOQUANT : L'implémentation respecte fidèlement les contraintes décidées dans `ARCHITECTURE-SPINE.md` (AD-9), imposant un chargeur unique agissant en "wrapper" sur le build de production et restreint à un set de 7 valeurs légales.
- NON BLOQUANT : L'utilisation de `set -euo pipefail` est honorée partout. Les commandes pouvant échouer de façon non dramatique (comme une variable vide ou absente) sont encapsulées (ex: `[[ -r ]] || ...`, test d'arithmétique `(($#)) || { ... }`), évitant toute fuite silencieuse au sein de l'enveloppe d'exécution.

VERDICT: NON BLOQUANT — aucune

Décisions de l'auteur sur la revue du code de la PR n° 28 (`062f360`, verdict `pass`) : aucun constat, confirmations seulement. Une première tentative de revue s'est arrêtée sans rien publier, le relecteur ayant voulu exécuter une commande shell que l'isolement lui refuse ; relancée, elle a rendu son rapport.

## Reporté

Aucun constat reporté.
