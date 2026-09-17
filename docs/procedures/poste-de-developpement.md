# Procédure — Monter un poste de développement

Tout le travail vit dans le dépôt. Ce qui manque sur une machine neuve, c'est **ce qui n'est jamais commité** : les secrets, les sources privées, les binaires épinglés et les outils du poste. Cette procédure les remonte dans l'ordre, et se termine par des vérifications dont la sortie attendue est écrite.

## Ce qui ne vient pas avec le dépôt

| Élément | Pourquoi il manque | Comment le retrouver |
| --- | --- | --- |
| `.env` | jamais commité, refusé par le garde-fou | recréé à la main, d'après `.env.example` (dix variables, sans valeur) |
| `docs/private/` | dépôt git imbriqué, poussé sur un dépôt privé séparé de la forge | cloné dans `docs/private/` |
| `.tools/` | binaires épinglés, ignorés par git | `scripts/ci/install-tools.sh --local` |
| Outils du poste | hors dépôt | `jq`, Docker, `agy` authentifié, `uv` |

## Monter le poste

1. **Cloner le dépôt** depuis la forge, sur la branche `dev`.
2. **Activer le hook local du garde-fou**, une fois par clone :
   ```bash
   git config core.hooksPath .githooks
   ```
3. **Cloner le dépôt privé** dans `docs/private/`. Il porte les cas bruts, la mémoire de party mode et `forbidden-patterns.txt`, dont le garde-fou a besoin pour auditer autre chose que des chemins. Sans lui, `check-private.sh` se replie sur les chemins seulement, et **un passage « chemins seulement » ne vaut pas audit**.
4. **Recréer `.env`** à la racine, avec les dix variables de `.env.example` : les sept `HUGO_LEGAL_*` (AD-9) et les trois `GITEA_*` (AD-24). Les valeurs viennent de l'ancien poste ou d'un gestionnaire de mots de passe — jamais d'un canal qui les écrirait quelque part. Le fichier est déjà ignoré par git et refusé par le garde-fou.
5. **Installer les outils du poste** : `jq`, Docker utilisable dans le shell, `agy` authentifié (`agy models` répond), `uv` pour les scripts Python de BMAD.
6. **Installer les outils épinglés** :
   ```bash
   scripts/ci/install-tools.sh --local
   ```

## Vérifier

Cinq commandes, avec leur sortie attendue. Tant qu'une échoue, le poste n'est pas prêt.

| Commande | Sortie attendue |
| --- | --- |
| `scripts/tests/run.sh` | `tests: N cas réussis.` |
| `PRIVATE_PATTERNS_FILE=docs/private/forbidden-patterns.txt scripts/check-private.sh history` | rien, code 0 — **aucune mention « chemins seulement »** |
| `scripts/sprint-consistency.sh` | `cohérent dans l'arbre de travail` |
| `scripts/build.sh production` puis `scripts/build.sh work` | aucun avertissement ; la production ne contient pas les brouillons |
| `scripts/env.sh sh -c 'env \| grep -c "^HUGO_LEGAL_"; env \| grep -c "^GITEA_" \|\| true'` | `7` puis `0` — les valeurs légales passent, les jetons non |

Un appel à la forge (`scripts/verify-and-merge-pr.sh <PR>` sur une PR ouverte) confirme en plus que le jeton est bon.

## Pièges connus

- **Docker dans WSL** : si l'utilisateur vient d'être ajouté au groupe `docker`, la session shell ne le sait pas encore ; `sg docker -c '…'` évite d'avoir à rouvrir la session.
- **`agy` sans `--dangerously-skip-permissions`** : la revue tourne en `--mode plan`, et le relecteur doit se voir refuser toute commande shell. Avec ce drapeau, un simple `grep` a déjà lu un `.env` (story 0.5).
- **`.tools/` n'est pas à sauvegarder** : il se régénère, et les empreintes de `tools.env` garantissent qu'on réinstalle exactement les mêmes binaires.
- **Le dépôt privé se commite à la main** (`git -C docs/private commit`), jamais par un hook : vérifier qu'il n'a rien en attente **avant** d'abandonner une machine.
