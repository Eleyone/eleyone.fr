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

Le script n'appelle jamais `git` : il fonctionne dans un dépôt sans `.git`, par exemple dans l'image du site. Les contrôles qui lisent l'historique vivent dans `scripts/ci/checks-job.sh` (story 3.12).

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

## Contrôles livrés

| Contrôle | Script | Ce qu'il refuse |
| --- | --- | --- |
| C4, C5, C6, C7, C8 | `scripts/checks/content.sh` | une rubrique de cas hors de `data/rubrics.yaml`, écrite deux fois ou hors de l'ordre de la liste ; un titre de cas plus profond que `###` ; un `[TODO` dans un fichier publié ; une technologie de `stack` absente de `data/stack.yaml` (une valeur `[TODO…` est tolérée dans un brouillon) ; un élément de matériel vivant déclaré sans être placé ou l'inverse, en double, mal préfixé, ou `ready` sans sa source dans la langue du fichier ; une clé `group` qui ne suit pas le dossier, un cas rangé trop profond, deux cas d'un groupe au même `order` |
| C3 | `scripts/checks/parity.sh` | un fichier de `content/` sans jumeau dans l'autre langue, un `translationKey` absent ou en double, un rôle ou une clé non traduite qui diffère (cas, poste, formation, accueil, contact), un `live_material` déclaré autrement, un nombre de titres de niveau 2 différent, et — pour un cas seulement — une rubrique hors de `data/rubrics.yaml` ou deux rubriques de même rang qui n'en sont pas les deux écritures |

## Tester un contrôle

Les cas vivent dans `scripts/tests/test-*.sh` et suivent `docs/procedures/shell-scripts.md`.

- **La logique d'un contrôle** se teste sur des **manifestes écrits à la main** sous `scripts/tests/fixtures/` : rapide, hors ligne, sans Hugo.
- **La forme du manifeste** se teste une seule fois, par `scripts/tests/test-checks-manifest.sh` : un site fixture (`scripts/tests/fixtures/site/`) construit avec le Hugo épinglé, avec les gabarits, la configuration et les données du dépôt, puis lu à `jq`. C'est le seul cas qui lance un vrai build.
- **L'orchestration** (ordre des builds, découverte, cumul, codes de sortie) se teste sur un faux dépôt, avec un `build.sh` bouchonné : `scripts/tests/test-check.sh`.

## Pièges connus

- **Un build en échec n'est pas un écart de contrôle** : il rend 1 comme un écart, mais rien ne tourne après lui. Lire la sortie de Hugo avant de chercher un défaut de contenu.
- **La sortie de Hugo ne suit pas le format `<fichier>: <écart>`**, et c'est voulu : elle nomme déjà le fichier et la ligne mieux qu'un reformatage.
- **`scripts/checks/lib.sh` n'est pas un contrôle** : `check.sh` l'exclut par son nom. Un futur fichier partagé de ce dossier devrait être exclu lui aussi.
