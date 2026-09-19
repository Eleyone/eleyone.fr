# Procédure — Job de contrôles partagé

`scripts/ci/checks-job.sh` est l'exécution complète des contrôles, la même sur le poste, sur Gitea et sur GitHub (AD-11). Un workflow ne contient que son déclencheur, le checkout et l'appel de ce script : aucune forge ne porte de logique à elle.

```bash
scripts/ci/checks-job.sh    # tout le job, dans le conteneur de contrôle
```

Codes de sortie : ceux du contrôle en échec (`0` conforme, `1` écart, `2` anomalie) ; `2` si Docker ou `tools.env` manque.

## Ce que fait le job

1. **Sur l'hôte**, `scripts/ci/checks-job.sh` lit `CHECK_IMAGE` dans `tools.env` — seule déclaration de l'image (AD-1) — et lance `docker run --rm` : le dépôt est monté sur `/repo`, qui est aussi le répertoire de travail, et l'UID et le GID de l'appelant sont passés au conteneur.
2. **Dans le conteneur**, `scripts/ci/checks-job-container.sh` pose les outils épinglés par `scripts/ci/install-tools-bootstrap.sh`. Cette part tourne en `root` : `apk` l'exige.
3. **Puis il redescend au compte de l'appelant** par `su-exec`, et enchaîne :
   - `scripts/check-private.sh history` — le garde-fou sur tout l'historique (C1, AD-12) ;
   - `scripts/tests/run.sh` — les tests hors ligne des scripts (story 0.9) ;
   - `scripts/check.sh` — les contrôles bloquants (AD-10, `check.md`).

Chaque étape s'annonce : le garde-fou et les tests ne disent rien quand tout va bien, et un journal de CI muet ne dirait pas ce qui a tourné.

## Pourquoi la bascule de compte

`apk` demande `root`, mais tout ce que le job écrit dans le dépôt monté — `public/`, `build/` — appartiendrait alors à `root` sur l'hôte : le `scripts/check.sh` suivant, lancé sur le poste, échouerait à vider `public/`, et il faudrait `sudo` pour réparer. Le conteneur installe donc en `root`, puis rend la main au compte de l'appelant pour tout le reste (décidé par Arnaud le 19/09/2026). Les fichiers naissent avec le bon propriétaire, et un job interrompu ne laisse rien derrière lui.

`su-exec` est déclaré dans `CHECK_BASE_PACKAGES` (`tools.env`, `tools.md`).

## Aucun secret, aucune image

- `docker run` part d'un environnement vide : rien de l'hôte n'entre, hors `HOST_UID` et `HOST_GID`.
- Le dépôt est monté tel quel, `.env` compris. Le conteneur désigne donc `ENV_FILE` sur un chemin inexistant : `scripts/env.sh` ne lit pas ce fichier, et les valeurs légales du job sont les valeurs factices de `ci/legal-placeholder.env` (AD-9), chargées dans le seul processus du conteneur.
- Le job ne construit aucune image : seul le workflow `release` de Gitea le fait (AD-11).
- Le conteneur emploie **ses** outils, pas ceux du poste : le dépôt monté peut porter un `.tools/`, que `scripts/build.sh` place en tête du `PATH`. `TOOLS_LOCAL_DIR` y désigne donc un dossier inexistant, pour que Hugo et D2 soient ceux que le job vient d'installer dans l'image (story 3.13).

## Recette

Les tests de `scripts/tests/test-checks-job.sh` couvrent la commande construite, les refus des deux scripts et le scénario du clone jetable, **sans lancer Docker** : la suite reste hors ligne (story 0.9, décidé par Arnaud le 19/09/2026). Ce qui demande un vrai conteneur s'essaie à la main.

```bash
scripts/ci/checks-job.sh                                 # doit finir par « check: N contrôle(s) passés »
find public build -printf '%u\n' | sort -u               # doit ne montrer que votre compte, jamais root
```

Le clone jetable, pour voir C1 refuser un commit fait sans hook :

```bash
tmp=$(mktemp -d) && git clone --no-local . "$tmp/clone"   # ou git init, pour un dépôt neuf
cd "$tmp/clone" && mkdir -p docs/private && echo essai > docs/private/note.md
git -c core.hooksPath=/dev/null add -A && git -c core.hooksPath=/dev/null commit -m "sans hook"
scripts/check-private.sh history                          # code 1, le commit et le chemin sont nommés
```

Le job entier dans ce clone donnerait le même refus, avant même les tests et les contrôles.

## Pièges déjà rencontrés

- **Un cas de test qui suppose son environnement** : `case_checks_job_conteneur_hors_image` comptait sur l'absence d'`apk`. Vrai sur le poste, faux dans l'image, où la suite tourne à l'intérieur du job : le cas y relançait le job entier. Même chose pour `HOST_UID`, que le conteneur définit et dont un cas héritait. Un cas réduit donc son `PATH` et retire les variables dont il veut l'absence.
- **Les divergences BusyBox / GNU** se voient à la première exécution du job, pas avant : `find -printf` et les codes de `xmllint` ont été corrigés ainsi (`tools.md`).
