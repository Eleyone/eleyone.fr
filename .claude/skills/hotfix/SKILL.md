---
name: hotfix
description: Corrige la production du site eleyone.fr — branche hotfix/* tirée de main, PR vers main fusionnée en fast-forward, tag vX.Y.(Z+1) calculé, puis dev rebasée sur main et poussée en --force-with-lease. À utiliser quand Arnaud demande de corriger la production, de faire un hotfix, ou quand release refuse parce que main n'est plus un ancêtre de dev.
---

# hotfix

Corrige la production sans merge commit ni cherry-pick, et rend `main` de nouveau ancêtre de `dev`.

La procédure fait foi : `docs/procedures/hotfix.md`. L'exécution est `scripts/hotfix.sh`.

À retenir :

- **trois sous-commandes, dans cet ordre.** `start <nom>` crée `hotfix/<nom>` depuis `origin/main` ;
  `publish` ouvre la PR vers `main` et affiche les verrous ; `sync` rebase une `dev` locale sur
  `main`. Entre `start` et `publish`, tu commites le correctif et tu pousses la branche ; entre deux
  `publish`, tu lances `llm-review` sur la PR ;
- **`publish --merge` et `sync --push` sont l'affaire d'Arnaud**, pas la tienne : ne les passe que
  s'il les a demandés pour ce correctif, au moment de l'opération. Le second réécrit `dev` par un
  push forcé — la seule exception au flux linéaire (AD-24, D-14). Le script ne les déduit jamais
  et ne pose aucune question ;
- **le tag est calculé** : le plus haut `vX.Y.Z` atteignable depuis `main`, correctif + 1. Tu ne
  le choisis pas ;
- `create-pull-request` et `verify-and-merge-pr` **ne servent pas** pour une branche `hotfix/*` :
  le premier la refuse, le second refuse toute PR vers `main`. Les verrous, eux, sont les mêmes :
  revue du code par `llm-review` sur la tête, garde-fou, CI verte, suivi de sprint. Ni revue de spec
  ni fichier de story : un correctif ne livre pas de story ;
- **un conflit au rebase arrête `sync`** et laisse le rebase en cours. Résous, `git add`,
  `git rebase --continue`, puis relance `scripts/hotfix.sh sync`. Ne lance jamais
  `git rebase --abort` sans le dire à Arnaud ;
- **jamais de cherry-pick**, jamais de merge commit, jamais de `--force` nu : un commit recopié
  casserait le fast-forward suivant ;
- après `sync --push`, chaque PR ouverte vers `dev` est à rebaser **puis à relire** : son rapport de
  revue porte sur un SHA réécrit. Le script les liste avec les commandes.
