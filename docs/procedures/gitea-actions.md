# Procédure — Actions sur la forge principale

La forge lance les contrôles à chaque PR et à chaque push sur `dev` et sur `main` (AD-11). Le workflow est `.gitea/workflows/checks.yaml` ; il ne contient que son déclencheur, le checkout et l'appel de `scripts/ci/checks-job.sh` (`checks-job.md`). Aucun contrôle ne s'écrit dans le YAML : ce qui tourne sur la forge est ce qui tourne sur le poste.

## Le runner doit être en mode hôte

En mode conteneur, le runner monte l'espace de travail dans un **volume Docker**. Le job lance ensuite `docker run -v "$PWD:/repo"` : le démon résoudrait ce chemin sur l'hôte, où il n'existe pas, et le conteneur de contrôle verrait un dossier vide. D'où le mode hôte, décidé le 13/09/2026.

Le label est déclaré **côté runner**, dans son `config.yaml`, parce que le schéma d'exécution lui appartient ; le champ de labels de l'interface de Gitea change ce qu'un runner annonce, pas la façon dont il exécute.

```yaml
runner:
  labels:
    - "ubuntu-latest:docker://…"   # les labels déjà en place
    - "linux_amd64:host"           # le mode hôte, pour ce job
```

Puis redémarrer le runner. La syntaxe d'un label est `<nom>[:<schéma>[:<arguments>]]` : **`runs-on` ne porte que le nom**, `linux_amd64`, jamais le schéma.

Prérequis de la machine du runner :

- l'utilisateur du runner accède au démon Docker **sans `sudo`** — le job lance `docker run` ;
- `node` est installé : en mode hôte, c'est le node de la machine qui exécute les actions JavaScript, celle du checkout comprise ;
- architecture x86_64, runner en version 2.0.0 au minimum.

Pour vérifier qu'un runner a bien pris le label, l'interface d'administration liste les runners, leur état et leurs labels. Le même état se lit par l'API, sur `/api/v1/admin/actions/runners` : les runners déclarés au niveau de l'instance n'apparaissent **pas** dans la liste des runners du dépôt, et chercher au mauvais niveau fait conclure à tort qu'il n'y en a aucun (constaté le 19/09/2026).

## L'action de checkout est épinglée par une URL absolue

```yaml
- uses: https://gitea.com/actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
```

L'URL absolue fixe la **source** en plus du commit : le workflow ne dépend pas du réglage `DEFAULT_ACTIONS_URL` de l'instance, qui décide sinon d'où les actions sont tirées. La `v4` est retenue parce qu'elle tourne sur node 20 ; la `v5` et au-delà demandent node 24, que le runner en mode hôte devrait fournir lui-même. Monter de version, c'est changer le SHA **et** le commentaire de version, jamais l'un sans l'autre.

## Les deux dossiers de workflows

Gitea lit `.gitea/workflows/` et **ignore** `.github/workflows/` dès que le premier existe (`[actions] WORKFLOW_DIRS`, dont la valeur par défaut est `.gitea/workflows,.github/workflows`, premier dossier présent retenu). `.gitea/workflows/` contient donc toujours au moins un workflow, et le réglage garde sa valeur par défaut. GitHub, lui, ne lit que `.github/workflows/` (story 3.14).

## Protection de branche

Une CI qui tourne sans être exigée ne verrouille rien. Après la **première exécution verte**, ajouter le statut du job `checks` aux contrôles obligatoires de `dev` et de `main` (`gitea-branches.md`) : Gitea ne propose un statut dans cette liste qu'une fois qu'il a été rapporté au moins une fois.

Le verrou « CI verte » de `scripts/verify-and-merge-pr.sh` lit ce même statut ; il passe de `absent` à bloquant dès que `.gitea/workflows/checks.yaml` existe sur la branche de base (règle d'amorçage, `verify-and-merge-pr.md`). Ce fichier ne doit donc arriver sur `dev` qu'une fois le runner prêt, sans quoi toutes les PR suivantes seraient bloquées.

## Ce qui déclenche un run

| Événement | Ce qui se passe |
| --- | --- |
| PR de `feat/*` vers `dev`, ouverte ou mise à jour | un run `pull_request`, et un seul : le déclencheur `push` n'écoute que `dev` et `main` |
| fusion de cette PR | un run `push` sur `dev` |
| PR de `dev` vers `main` (mise en ligne) | un run `pull_request` ; les pushs sur `dev` gardent en plus leurs runs `push`, ce qui est voulu |
