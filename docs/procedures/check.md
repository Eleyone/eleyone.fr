# Procédure — Contrôles bloquants

`scripts/check.sh` est le **seul** point d'entrée des contrôles (AD-10). La même commande tourne sur le poste, dans le job de contrôles de Gitea et dans la CI publique de GitHub : un contrôle local ne peut pas diverger de celui d'une forge.

```bash
scripts/check.sh              # contrôles standard
scripts/check.sh --release    # ajoute le niveau « release » (contrôles de mise en ligne, epic 11)
```

## Ce que fait le script

1. **Le rendu de travail**, puis **le build de production**, par `scripts/build.sh`. Les deux passent `--panicOnWarning` : un avertissement de Hugo fait échouer le build, donc les contrôles (C14). Un build en échec **arrête tout** — aucun contrôle ne lit une sortie périmée —, et la sortie de Hugo est affichée telle quelle, précédée d'une ligne qui nomme le build fautif.
2. **Tous les scripts de `scripts/checks/`**, découverts dynamiquement, triés, `lib.sh` exclu. Une story qui ajoute un contrôle dépose son script et ne touche pas à `check.sh`.
3. **Le résumé** : tous les contrôles tournent, même après un échec, tous les écarts s'affichent, puis une ligne nomme les contrôles en échec.

Codes de sortie : `0` conforme, `1` écart constaté, `2` anomalie (outil ou fichier manquant, option inconnue).

Le script n'appelle jamais `git` : il fonctionne dans un dépôt sans `.git`, par exemple dans l'image du site. Les contrôles qui lisent l'historique vivent dans `scripts/ci/checks-job.sh`, le job qui enchaîne le garde-fou, les tests des scripts et ce script dans le conteneur de contrôle (`checks-job.md`).

## Écrire un contrôle

Un contrôle est un `scripts/checks/<nom>.sh` qui charge `scripts/checks/lib.sh`, lit les manifestes du rendu de travail et rend `0`, `1` ou `2`.

```bash
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
manifests=$(checks_manifests build/work)
```

- **Signalements** : `checks_report <fichier> <écart>` écrit `<fichier>: <écart>` sur la sortie d'erreur. Un contrôle nomme toujours le fichier et l'écart, jamais seulement le nombre.
- **Brouillons** (AD-10) : sur un fichier en `draft: true`, une valeur qui commence par `[TODO` passe toutes les règles de **forme**. `checks_is_todo <valeur>` et `checks_tolerated <brouillon> <valeur>` donnent l'outil ; la bibliothèque n'écarte rien d'elle-même, parce que la parité (C3), la liste des rubriques (C4) et le garde-fou s'appliquent aussi aux brouillons.
- **Forme du manifeste** : documentée en tête de `scripts/checks/lib.sh`, définie une seule fois dans `layouts/home.checks.json`. Une entrée peut porter `error` (front matter absent, suffixe de langue absent, page introuvable) : un contrôle lit `error` avant tout le reste.
- **Niveau** : `CHECK_LEVEL` vaut `standard`, ou `release` avec `--release`. Aucun contrôle de mise en ligne n'existe avant l'epic 11.
- **Racine du rendu** : un contrôle lit `${CHECK_WORK_ROOT:-build/work}`, pour qu'un cas de test le lance sur des manifestes écrits à la main sans toucher au rendu du dépôt.
- **Une liste vide n'est pas une conformité** : un contrôle qui parcourt des fichiers vérifie qu'il en a trouvé au moins un avant de conclure, sans quoi une racine erronée ou une sortie de build vide passeraient pour un succès (rétrospective de l'epic 3).
- **Les enveloppes sont communes** : `checks_xpath`, `checks_attributes` et `checks_find` dans `scripts/checks/lib.sh`, `shell_grep` et `shell_grep_into` dans `scripts/lib/shell.sh`, partagées avec les tests et les scripts. Un contrôle n'écrit pas la sienne.

## Contrôles livrés

| Contrôle | Script | Ce qu'il refuse |
| --- | --- | --- |
| C13 | `scripts/checks/budget.sh` | un HTML de plus de 50 000 octets, une CSS de plus de 20 000 pour le site, un SVG de plus de 60 000, une page complète de plus de 200 000, plus de 10 ressources ou 800 éléments, un fichier JavaScript ou de police, une ressource chargée mais absente |
| C12 | `scripts/checks/links.sh` | un lien interne vers une page absente, un fragment sans identifiant correspondant, une page qu'aucun chemin de liens ne relie à l'accueil de sa langue (les deux 404 exceptées), un lien de CV sans les deux PDF publiés ou l'inverse, une `source_url` renseignée sans lien vers le dépôt |
| C10, C11, C5 (sortie) | `scripts/checks/html.sh` | une balise `<script>` autre que le bloc JSON-LD de l'accueil, un attribut `on…`, une `<iframe>`, un `<form>`, une ressource chargée depuis un autre hôte (HTML ou CSS), un `[TODO` dans un fichier publié, un bloc JSON-LD en double, hors de l'accueil, invalide, de `@type` autre que `Person` ou porteur d'une clé hors FR-35 ; une page sans `lang`, au `<title>` vide, sans la ligne d'identité (accueil excepté, AD-2) ou resté celui du générateur, non traduit, sans `<h1>` ou avec plusieurs, au plan de titres sauté, à identifiant dupliqué, une image sans `alt` ou sans dimensions, un lien sans nom accessible, une page sans `hreflang`, un `tabindex` positif |
| C4, C5, C6, C7, C8, C16, C18, C19 | `scripts/checks/content.sh` | une rubrique de cas hors de `data/rubrics.yaml`, écrite deux fois ou hors de l'ordre de la liste ; un titre de cas plus profond que `###` ; un `[TODO` dans un fichier publié ; une technologie de `stack` absente de `data/stack.yaml` (une valeur `[TODO…` est tolérée dans un brouillon) ; un élément de matériel vivant déclaré sans être placé ou l'inverse, en double, mal préfixé, ou `ready` sans sa source dans la langue du fichier ; une clé `group` qui ne suit pas le dossier, un cas rangé trop profond, deux cas d'un groupe au même `order` ; un « En bref » de plus de 400 points de code ou de plus de 3 phrases ; un `title` de plus de 70 caractères, un `setup` ou un `status` hors valeurs, un numéro de fichier qui ne suit pas `number` ou le `translationKey`, un encart de cas publié incomplet ; `.env.example` ou `ci/legal-placeholder.env` dont les **noms** de variables ne sont pas exactement ceux d'AD-9 et d'AD-24 ; un cas publié sans poste publié de sa langue, un poste ou une formation dont le `translationKey` ne suit pas le nom de fichier ou son préfixe, un `track`, `setup` ou `kind` hors valeurs, un poste sans `location` ni `setup`, une `company_url` de poste qui n'est pas une adresse absolue en `https://`, une clé obligatoire vide, deux `order` identiques dans un `track` ou un `kind` |
| C20 | `scripts/checks/images.sh` | une image d'`assets/` ou de `public/` porteuse de métadonnées (EXIF, XMP, conteneur WebP étendu) ; la copie commitée `assets/images/portrait.webp` hors de 640 × 800 ou au-delà de 150 000 o ; une variante publiée hors des dimensions d'AD-19 ou au-delà de 40 000 o. Le texte alternatif relève de C11, pas d'ici. Aucun outil d'image : `grep` et `od` lisent les octets (AD-19) |
| C3 | `scripts/checks/parity.sh` | un fichier de `content/` sans jumeau dans l'autre langue, un `translationKey` absent ou en double, un rôle ou une clé non traduite qui diffère (cas, poste, formation, accueil, contact), un `live_material` déclaré autrement, un nombre de titres de niveau 2 différent, et — pour un cas seulement — une rubrique hors de `data/rubrics.yaml` ou deux rubriques de même rang qui n'en sont pas les deux écritures |

## Ce que les contrôles ne voient pas

AD-17 partage la vérification d'accessibilité en deux, et `check.sh` n'en porte que la moitié. L'autre — contraste mesuré dans les deux modes, clavier, reflow à 320 px, zoom à 200 %, taille des cibles — demande un navigateur, qu'aucune CI du projet ne lance. Elle se fait à la main, à chaque story qui crée ou modifie un gabarit, et se consigne dans **`docs/accessibility.md`** (décidé par Arnaud le 21/09/2026).

Cette moitié-là n'est pas décorative : la story 5.1 y a trouvé huit cibles sous les 24 px de WCAG 2.5.8, qu'aucun contrôle automatique ne pouvait voir — la taille d'une cible n'existe qu'au rendu.

## Tester un contrôle

Les cas vivent dans `scripts/tests/test-*.sh` et suivent `docs/procedures/shell-scripts.md`.

- **La logique d'un contrôle** se teste sur des **manifestes écrits à la main** sous `scripts/tests/fixtures/` : rapide, hors ligne, sans Hugo.
- **La forme du manifeste** se teste une seule fois, par `scripts/tests/test-checks-manifest.sh` : un site fixture (`scripts/tests/fixtures/site/`) construit avec le Hugo épinglé, avec les gabarits, la configuration et les données du dépôt, puis lu à `jq`. C'est le seul cas qui lance un vrai build.
- **L'orchestration** (ordre des builds, découverte, cumul, codes de sortie) se teste sur un faux dépôt, avec un `build.sh` bouchonné : `scripts/tests/test-check.sh`.

## Pièges connus

- **Un build en échec n'est pas un écart de contrôle** : il rend 1 comme un écart, mais rien ne tourne après lui. Lire la sortie de Hugo avant de chercher un défaut de contenu.
- **La sortie de Hugo ne suit pas le format `<fichier>: <écart>`**, et c'est voulu : elle nomme déjà le fichier et la ligne mieux qu'un reformatage.
- **`scripts/checks/lib.sh` n'est pas un contrôle** : `check.sh` l'exclut par son nom. Un futur fichier partagé de ce dossier devrait être exclu lui aussi.
