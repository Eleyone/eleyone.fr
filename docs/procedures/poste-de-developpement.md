# Procédure — Monter un poste de développement

Tout le travail vit dans le dépôt. Ce qui manque sur une machine neuve, c'est **ce qui n'est jamais commité** : les secrets, les sources privées, les binaires épinglés et les outils du poste. Cette procédure les remonte dans l'ordre, et se termine par des vérifications dont la sortie attendue est écrite.

## Ce qui ne vient pas avec le dépôt

| Élément | Pourquoi il manque | Comment le retrouver |
| --- | --- | --- |
| `.env` | jamais commité, refusé par le garde-fou | recréé à la main, d'après `.env.example`, qui porte **tous** les noms sans aucune valeur — les compter là plutôt qu'ici, un chiffre écrit dans une procédure vieillit |
| `docs/private/` | dépôt git imbriqué, poussé sur un dépôt privé séparé de la forge | cloné dans `docs/private/` — avec `legal-release.env` **s'il y a été commité** : un fichier resté non suivi ne survit pas au poste |
| La clé du poste pour le compte de déploiement | vit dans `~/.ssh`, hors dépôt | **refaite**, jamais recopiée : `serveur-de-production.md`, « Le poste est perdu, ou sa clé refaite » |
| `.tools/` | binaires épinglés, ignorés par git | `scripts/ci/install-tools.sh --local` |
| Outils du poste | hors dépôt | `jq`, `xmllint` (paquet `libxml2-utils`, contrôles HTML d'AD-10), `pdftotext` et `pdfinfo` (paquet `poppler-utils`, C21), Docker, `agy` authentifié, `uv` |

## Monter le poste

1. **Cloner le dépôt** depuis la forge, sur la branche `dev`.
2. **Activer le hook local du garde-fou**, une fois par clone :
   ```bash
   git config core.hooksPath .githooks
   ```
3. **Cloner le dépôt privé** dans `docs/private/`. Il porte les cas bruts, la mémoire de party mode et `forbidden-patterns.txt`, dont le garde-fou a besoin pour auditer autre chose que des chemins. Sans lui, `check-private.sh` se replie sur les chemins seulement, et **un passage « chemins seulement » ne vaut pas audit**.
4. **Recréer `.env`** à la racine, avec **toutes** les variables de `.env.example` : les `HUGO_LEGAL_*` (AD-9), les `GITEA_*` (AD-24), et les deux destinations de la répétition générale, `ADMIN_HOST` et `DEPLOY_HOST` (AD-22, story 11.8). `.env.example` fait foi et ne porte aucune valeur ; un `cut -d= -f1 .env.example` en donne la liste à jour. Les valeurs viennent de l'ancien poste ou d'un gestionnaire de mots de passe — jamais d'un canal qui les écrirait quelque part. Le fichier est déjà ignoré par git et refusé par le garde-fou.
5. **Installer les outils du poste** : `jq`, `xmllint` (`sudo apt install libxml2-utils` ; sans lui, les contrôles HTML s'arrêtent en anomalie et le verrou de fusion bloque), `pdftotext` et `pdfinfo` (`sudo apt install poppler-utils` ; sans eux, C21 ne lit pas les CV PDF de l'index et le garde-fou **refuse tout commit**, quel que soit son contenu), Docker utilisable dans le shell, `agy` authentifié (`agy models` répond), `uv` pour les scripts Python de BMAD.
6. **Installer les outils épinglés** :
   ```bash
   scripts/ci/install-tools.sh --local
   ```

## Vérifier

Six commandes, avec leur sortie attendue. Tant qu'une échoue, le poste n'est pas prêt.

| Commande | Sortie attendue |
| --- | --- |
| `scripts/tests/run.sh` | `tests: N cas réussis.` |
| `PRIVATE_PATTERNS_FILE=docs/private/forbidden-patterns.txt scripts/check-private.sh history` | rien, code 0 — **aucune mention « chemins seulement »** |
| `scripts/sprint-consistency.sh` | `cohérent dans l'arbre de travail` |
| `scripts/build.sh production` puis `scripts/build.sh work` | aucun avertissement ; la production ne contient pas les brouillons |
| `scripts/env.sh sh -c 'env \| grep -c "^HUGO_LEGAL_"; env \| grep -c "^GITEA_" \|\| true'` | le nombre de `HUGO_LEGAL_*` de `.env.example`, puis `0` — les valeurs légales passent, les jetons non. **Le nombre n'est pas écrit ici** : il a changé une fois (sept, puis huit à la story 9.7) et la procédure avait gardé l'ancien. `cut -d= -f1 .env.example \| grep -c '^HUGO_LEGAL_'` donne l'attendu |
| `scripts/ci/checks-job.sh` | `check: N contrôle(s) passés` — tout le job dans le conteneur de contrôle (`checks-job.md`) ; il prouve Docker, l'image et les scripts d'un coup |

Une septième vérification touche la forge, et n'a besoin d'aucune PR ouverte : lancer l'audit sur une PR **déjà fusionnée** appelle l'API sans rien modifier.

| Commande | Sortie attendue |
| --- | --- |
| `scripts/verify-and-merge-pr.sh <numéro d'une PR fusionnée>` | `bloque  PR fusionnable   PR déjà fusionnée : rien à fusionner.` |

Ce message prouve que `GITEA_URL`, `GITEA_USER` et `GITEA_TOKEN` sont bons : sans eux, le script s'arrête plus tôt, sur « la forge refuse le jeton ou ne répond pas (HTTP …) » ou sur « le jeton n'appartient pas au compte GITEA_USER ». Sans cette vérification, une adresse erronée dans un `.env` recréé n'apparaît qu'à l'ouverture de la première PR (constaté le 17/09/2026 ; action 5 de la rétrospective de l'epic 2).

## Pièges connus

- **Le groupe `docker` et la session en cours** : si l'utilisateur vient d'être ajouté au groupe `docker`, la session shell ne le sait pas encore ; `sg docker -c '…'` évite d'avoir à rouvrir la session. Ce piège s'appelait « Docker dans WSL » ; le poste est un Linux natif (point 17 d'AGENTS.md, vérifié à la rétrospective de l'epic 7), et le conseil vaut pour n'importe quel Linux.
- **`agy` sans `--dangerously-skip-permissions`** : la revue tourne en `--mode plan`, et le relecteur doit se voir refuser toute commande shell. Avec ce drapeau, un simple `grep` a déjà lu un `.env` (story 0.5).
- **`.tools/` n'est pas à sauvegarder** : il se régénère, et les empreintes de `tools.env` garantissent qu'on réinstalle exactement les mêmes binaires.
- **Le dépôt privé se commite à la main** (`git -C docs/private commit`), jamais par un hook : vérifier qu'il n'a rien en attente **avant** d'abandonner une machine — fichiers **non suivis** compris, que `git -C docs/private status` liste à part. `legal-release.env` n'y avait jamais été commité, et il a disparu avec l'ancien poste (constaté le 02/10/2026).
