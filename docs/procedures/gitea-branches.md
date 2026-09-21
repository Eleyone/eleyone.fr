# Procédure — Branches protégées et styles de fusion

Réglages de la forge Gitea qui tiennent le flux linéaire d'AD-24 : aucun merge commit, aucun push direct sur `main`, `dev` réécrite seulement après un hotfix. Constatés sur Gitea 1.27.3 le 14/09/2026 (story 0.2).

Les réglages se font dans l'interface de la forge, sauf un, qui passe par l'API (voir « Bug de l'interface »). Ils se vérifient toujours par l'API.

## Règles

- **Aucun merge commit**, ni sur `dev`, ni sur `main`.
- **`main`** : aucun push ni force-push, pour aucun compte. Elle n'avance que par la fusion en fast-forward d'une PR, faite par l'API (skills `release` et `hotfix`).
- **`dev`** : une PR y entre en squash (skill `verify-and-merge-pr`). Le compte d'Arnaud est dans la liste de push, parce que Gitea n'accepte un force-push que d'un compte qui peut déjà pousser. **Le push direct sur `dev` reste donc techniquement possible pour ce compte ; il est interdit par la procédure.** Le force-push ne sert qu'au rebase de `dev` sur `main` après un hotfix, avec l'approbation explicite d'Arnaud au moment de l'opération.
- **Les styles de fusion se règlent par dépôt, pas par branche.** Le dépôt n'autorise que le squash et le fast-forward ; les scripts choisissent le style selon la base de la PR.
- **Ne jamais cliquer « Mettre à jour la branche » sur une PR `dev` → `main`.** La mise à jour par rebase réécrirait `dev` par un force-push, hors du skill `hotfix` et sans approbation. Après un hotfix, `dev` se rebase par le skill `hotfix`.

## Réglages du dépôt

Dans l'interface : **Paramètres → Demandes d'ajout**.

| Libellé de l'interface | Champ de l'API | Valeur |
|---|---|---|
| Créer une révision de fusion | `allow_merge_commits` | `false` |
| Rebaser puis rattraper | `allow_rebase` | `false` |
| Rebaser puis créer une révision de fusion | `allow_rebase_explicit` | `false` |
| Créer une révision de concaténation | `allow_squash_merge` | `true` |
| Avance rapide uniquement | `allow_fast_forward_only_merge` | `true` |
| Fusionner manuellement | `allow_manual_merge` | `false` |
| Détection automatique de la fusion manuelle | `autodetect_manual_merge` | `false` |
| Méthode de fusion par défaut | `default_merge_style` | `squash` |
| Mise à jour d'une PR par merge | `allow_merge_update` | `false` (**par l'API**) |
| Mise à jour d'une PR par rebase | `allow_rebase_update` | `true` |
| Style de mise à jour de la branche par défaut | `default_update_style` | `rebase` |
| Supprimer la branche après la fusion par défaut | `default_delete_branch_after_merge` | `false` |
| Branche cible par défaut | `default_branch` | `dev` |

La suppression automatique reste désactivée : sur une PR `dev` → `main`, elle proposerait de supprimer `dev`. `verify-and-merge-pr` supprime lui-même la branche d'une PR fusionnée vers `dev`, jamais `dev`.

### Bug de l'interface

L'interface en français affiche deux cases au même libellé (« Activer la mise à jour … par rebase ») : l'une règle `allow_merge_update`, l'autre `allow_rebase_update`. Décocher la mise à jour par merge puis enregistrer ne tient pas : la case revient cochée.

Le réglage se fait donc par l'API, avec un corps `{"allow_merge_update": false}` envoyé en `PATCH /api/v1/repos/Eleyone/eleyone.fr`. **Après tout enregistrement du bloc « Demandes d'ajout » dans l'interface, relire ce champ par l'API** (voir « Vérifier ») : l'enregistrement peut l'avoir réactivé.

Sans ce réglage, le bouton de mise à jour d'une PR `dev` → `main` pousserait un merge commit sur `dev`, que la publication suivante porterait jusqu'à `main`.

## Protections de branche

Dans l'interface : **Paramètres → Branches**, une règle par branche.

| Réglage | Champ de l'API | `main` | `dev` |
|---|---|---|---|
| Push | `enable_push` | désactivé | activé, liste d'autorisation |
| Comptes autorisés à pousser | `push_whitelist_usernames` | — | `Eleyone` |
| Clés de déploiement autorisées à pousser | `push_whitelist_deploy_keys` | — | `false` |
| Force-push | `enable_force_push` | désactivé | activé, liste d'autorisation |
| Comptes autorisés au force-push | `force_push_allowlist_usernames` | — | `Eleyone` |
| Clés de déploiement autorisées au force-push | `force_push_allowlist_deploy_keys` | — | `false` |
| Comptes autorisés à fusionner | `merge_whitelist_usernames` | `Eleyone` | `Eleyone` |
| Bloquer la fusion si la branche est en retard | `block_on_outdated_branch` | `true` | `true` |
| Contournement par un administrateur | `enable_bypass_allowlist` | `false` | `false` |
| Contrôles d'état requis | `enable_status_check` | `true` (21/09/2026) | `true` (21/09/2026) |
| Contextes exigés | `status_check_contexts` | `checks / checks*` | idem |

Tout compte ou toute clé de déploiement absent de ces listes est refusé. Au 14/09/2026, le dépôt n'a ni autre compte ni clé de déploiement. Un compte ou une clé ajoutés plus tard (miroir, CI) n'entrent **pas** dans ces listes.

### Les contextes exigés

Le contexte d'un statut Gitea s'écrit `<workflow> / <job> (<événement>)` : le workflow des contrôles en pose deux selon ce qui l'a déclenché, `checks / checks (pull_request)` et `checks / checks (push)`. Le motif exigé est donc **`checks / checks*`**, un glob qui couvre les deux : nommer un seul événement bloquerait l'autre, et se tromper d'un caractère bloquerait toutes les fusions sans rien dire de plus qu'« en attente ».

Le réglage a été posé le 21/09/2026, après la première exécution verte : Gitea ne propose un contexte dans cette liste qu'une fois qu'il a été rapporté au moins une fois. La PR qui a introduit cette ligne a servi d'essai — elle ne pouvait se fusionner que si le motif correspondait vraiment.

Ce réglage change ce que la forge rapporte : depuis qu'il est posé, la tête d'une PR porte **deux** statuts, `checks / checks (pull_request)` vert et `checks / checks (push)` **ignoré** — le déclencheur `push` n'écoutant que `dev` et `main`. `scripts/verify-and-merge-pr.sh` a dû l'apprendre : un statut ignoré est écarté, mais ne remplace pas un run effectif (constaté en fusionnant la PR qui a introduit ce réglage).

Ce réglage est le second verrou sur la CI, côté forge. Le premier est `scripts/verify-and-merge-pr.sh`, qui refuse de fusionner sans un run `checks` vert sur le SHA de tête (`verify-and-merge-pr.md`). Les deux disent la même chose à deux endroits : le script protège l'audit, la protection de branche protège l'interface et l'API.

Modifier une règle par l'API (`PATCH /api/v1/repos/Eleyone/eleyone.fr/branch_protections/<règle>`) : un champ imbriqué n'est pris en compte que si la requête porte aussi ses champs parents. Envoyé seul, `push_whitelist_deploy_keys: false` répond `200` sans rien changer ; il faut envoyer `enable_push`, `enable_push_whitelist` et `push_whitelist_usernames` avec lui, et de même `enable_force_push`, `enable_force_push_allowlist` et `force_push_allowlist_usernames` avec `force_push_allowlist_deploy_keys`. Une réponse `200` ne prouve donc rien : relire la règle.

## Pourquoi le style n'est pas fixé par branche

Gitea fixe les styles autorisés pour tout le dépôt. Les scripts imposent le style par l'API (`POST /api/v1/repos/Eleyone/eleyone.fr/pulls/<numéro>/merge`), avec `head_commit_id` égal au SHA relu, pour que la fusion échoue si la tête a bougé :

- `verify-and-merge-pr` fusionne vers `dev` en `"Do": "squash"`, et refuse toute base `main` ;
- `release` et `hotfix` fusionnent vers `main` en `"Do": "fast-forward-only"`.

Réponses constatées de l'API de fusion :

| Situation | Réponse |
|---|---|
| Style non autorisé dans le dépôt | `405`, `<style> is not allowed an allowed merge style for this repository` |
| Fast-forward après divergence de la base | `500`, `Merge DivergingFastForwardOnly` : rien n'est fusionné |
| Juste après un déplacement de la base | `405` transitoire, `Please try again later` : réessayer, ce n'est pas un refus |

## Vérifier

Sans afficher le jeton : `.env` est lu ligne par ligne, jamais avec `source`, et le jeton passe à `curl` par l'entrée standard (voir `gitea-token.md`).

```bash
while IFS= read -r line; do
  case "$line" in
    GITEA_URL=*|GITEA_TOKEN=*) k=${line%%=*}; v=${line#*=}; v=${v%\"}; v=${v#\"}; export "$k=$v" ;;
  esac
done < .env
api_get () {
  printf 'header = "Authorization: token %s"\n' "$GITEA_TOKEN" \
    | curl -sf -K - "${GITEA_URL%/}/api/v1$1"
}
api_get /repos/Eleyone/eleyone.fr | jq '{allow_merge_commits, allow_rebase, allow_rebase_explicit,
  allow_squash_merge, allow_fast_forward_only_merge, allow_manual_merge, default_merge_style,
  allow_merge_update, allow_rebase_update, default_update_style,
  default_delete_branch_after_merge, default_branch}'
api_get /repos/Eleyone/eleyone.fr/branch_protections | jq '.[] | {rule_name, enable_push,
  push_whitelist_usernames, push_whitelist_deploy_keys, enable_force_push,
  force_push_allowlist_usernames, force_push_allowlist_deploy_keys,
  merge_whitelist_usernames, block_on_outdated_branch}'
api_get /repos/Eleyone/eleyone.fr/keys | jq length
```

Chaque valeur doit correspondre aux deux tableaux ci-dessus, et la dernière commande afficher `0` tant qu'aucune clé de déploiement n'est prévue.

## Constats de la story 0.2 (14/09/2026)

- `main` créée par Arnaud depuis `dev`, puis protégée.
- Push direct sur `main` par le compte d'Arnaud : refusé (`Not allowed to push to protected branch main`).
- Force-push sur `main` par le compte d'Arnaud : refusé (`branch main is protected from force push`).
- Sur des branches temporaires, avec une règle identique à celle de `main` (supprimées ensuite, PR de test n° 3 à 5) :
  - fusion en `merge`, `rebase` et `rebase-merge` : refusée (`405`) ;
  - fusion en `fast-forward-only` vers la base protégée : acceptée, sans nouveau commit, la base prenant le SHA de la tête ;
  - push direct et force-push sur cette base : refusés ;
  - base qui diverge par une PR de hotfix simulée, puis fast-forward : impossible (`500 DivergingFastForwardOnly`).
- Autre compte : aucun sur la forge. Les critères « un autre compte est refusé » ne sont pas testables ; ils sont tenus par les listes d'autorisation.
- Squash vers `dev` : la PR de la story 0.2 elle-même.
