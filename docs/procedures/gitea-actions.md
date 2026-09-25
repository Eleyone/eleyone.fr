# Procédure — Actions sur la forge principale

La forge lance les contrôles à chaque PR et à chaque push sur `dev` et sur `main` (AD-11). Le workflow est `.gitea/workflows/checks.yaml` ; il ne contient que son déclencheur, le checkout et l'appel de `scripts/ci/checks-job.sh` (`checks-job.md`). Aucun contrôle ne s'écrit dans le YAML : ce qui tourne sur la forge est ce qui tourne sur le poste.

Le second workflow de la forge est `.gitea/workflows/release.yaml`, déclenché par un push de tag `v*` : il suit la même règle et n'appelle qu'un script, `scripts/ci/release-job.sh` (`release-workflow.md`). Les deux tournent sur le même label en mode hôte et épinglent le checkout au même SHA.

## Le runner doit être en mode hôte, et le mode hôte doit être la machine

En mode conteneur, le runner monte l'espace de travail dans un **volume Docker**. Le job lance ensuite `docker run -v "$PWD:/repo"` : le démon résoudrait ce chemin sur la machine, où il n'existe pas, et le conteneur de contrôle verrait un dossier vide — les contrôles passeraient au vert sans rien avoir lu. D'où le mode hôte, décidé le 13/09/2026.

Le label est déclaré **côté runner** : le schéma d'exécution lui appartient. Dans `config.yaml`, la clé `runner.labels` l'emporte sur les labels enregistrés dans `.runner`, et la liste s'écrit en entier — les existants **plus** le nouveau :

```yaml
runner:
  labels:
    - "ubuntu-latest:host"
    - "linux_amd64:host"   # celui que vise ce workflow
```

La syntaxe est `<nom>[:<schéma>[:<arguments>]]` : **`runs-on` ne porte que le nom**, `linux_amd64`, jamais le schéma.

### Deux pièges constatés le 19/09/2026

- **Le mode d'un label est invisible depuis l'administration.** Gitea ne stocke que les noms : `["docker","linux","x64","ubuntu-latest","self-hosted"]` s'affiche pareil, que chaque label soit `:host` ou `:docker://…`. Lire un mode dans cette liste mène à une conclusion fausse ; le seul endroit qui fait foi est la configuration du runner. De même, un runner déclaré au niveau de l'**instance** n'apparaît pas dans la liste des runners du dépôt : `/api/v1/admin/actions/runners` les montre tous.
- **Un runner conteneurisé n'est pas la machine.** Si `act_runner` tourne lui-même dans un conteneur, le « mode hôte » désigne l'intérieur de ce conteneur, et le problème de montage se repose à l'identique : l'espace de travail vit sous son `/tmp`, chemin absent de la machine. Il faut alors que le dossier de travail porte **le même chemin des deux côtés** :

  ```yaml
  # côté conteneur du runner : le dossier de travail des jobs
  host:
    workdir_parent: /<chemin absolu>/work
  ```

  ```yaml
  # côté composition : le même chemin de part et d'autre du deux-points
  - /<chemin absolu>/work:/<chemin absolu>/work
  ```

  Sans ce réglage, `act_runner` retombe sur `/tmp`. La preuve que le montage est bon se lit pendant un run : le dossier `…/work/docker-<run>-checks/` existe **sur la machine**.

Prérequis de l'environnement qui exécute les jobs — la machine, ou le conteneur du runner s'il est conteneurisé :

- accès au démon Docker **sans `sudo`** : le job lance `docker run` ;
- `bash` : les étapes `run:` et le job lui-même en dépendent ;
- `node` : c'est lui qui exécute les actions JavaScript, celle du checkout comprise ;
- `git`, et une architecture x86_64 ; runner en version 0.2.10 au minimum.

## L'action de checkout est épinglée par une URL absolue

```yaml
- uses: https://gitea.com/actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
```

L'URL absolue fixe la **source** en plus du commit : le workflow ne dépend pas du réglage `DEFAULT_ACTIONS_URL` de l'instance, qui décide sinon d'où les actions sont tirées. La `v4` est retenue parce qu'elle déclare node 20, le dénominateur commun ; `act_runner` exécute de toute façon les actions avec le node dont il dispose, et la `v4` a tourné sans broncher sur le node 24 du runner (constaté le 19/09/2026). Monter de version, c'est changer le SHA **et** le commentaire de version, jamais l'un sans l'autre.

## Les deux dossiers de workflows

Gitea lit `.gitea/workflows/` et **ignore** `.github/workflows/` dès que le premier existe (`[actions] WORKFLOW_DIRS`, dont la valeur par défaut est `.gitea/workflows,.github/workflows`, premier dossier présent retenu). `.gitea/workflows/` contient donc toujours au moins un workflow, et le réglage garde sa valeur par défaut. GitHub, lui, ne lit que `.github/workflows/`, où vit la CI publique, contrôles seulement (`github-mirror.md`).

## Protection de branche

Une CI qui tourne sans être exigée ne verrouille rien. Après la **première exécution verte**, ajouter le statut du job `checks` aux contrôles obligatoires de `dev` et de `main` (`gitea-branches.md`) : Gitea ne propose un statut dans cette liste qu'une fois qu'il a été rapporté au moins une fois.

Le verrou « CI verte » de `scripts/verify-and-merge-pr.sh` lit ce même statut ; il passe de `absent` à bloquant dès que `.gitea/workflows/checks.yaml` existe sur la branche de base (règle d'amorçage, `verify-and-merge-pr.md`). Ce fichier ne doit donc arriver sur `dev` qu'une fois le runner prêt, sans quoi toutes les PR suivantes seraient bloquées.

## Ce qui déclenche un run

| Événement | Ce qui se passe |
| --- | --- |
| PR de `feat/*` vers `dev`, ouverte ou mise à jour | un run `pull_request`, et un seul : le déclencheur `push` n'écoute que `dev` et `main` |
| fusion de cette PR | un run `push` sur `dev` |
| PR de `dev` vers `main` (mise en ligne) | un run `pull_request` ; les pushs sur `dev` gardent en plus leurs runs `push`, ce qui est voulu |
| push d'un tag `v*` | un run `release`, et lui seul : `checks.yaml` n'écoute pas les tags, et `release.yaml` n'écoute pas les branches (`release-workflow.md`) |
