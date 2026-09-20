# Procédure — Publier un cas

Un cas devient public en passant de `draft: true` à `draft: false`. `scripts/publish-case.sh` fait ce passage toujours de la même façon : tous les contrôles, la modification, le commit, la PR. Publier à la main, c'est oublier un contrôle.

```bash
scripts/publish-case.sh case-02            # contrôle et montre ce qu'il changerait ; ne modifie rien
scripts/publish-case.sh case-02 --relu     # publie, commit, pousse et ouvre la PR
```

Codes de sortie : `0` conforme, `1` refus (le message dit quoi corriger), `2` anomalie (usage, `jq` absent, manifeste illisible).

## Les deux temps, et pourquoi

Le format exige une **relecture humaine** avant qu'un cas devienne public. `--relu` en est la trace explicite (décidé par Arnaud le 21/09/2026, parmi trois options : ce drapeau, une case dans la PR, une question interactive).

Sans lui, le script va jusqu'au bout des contrôles, affiche les fichiers qu'il passerait hors brouillon et les clés qu'il ajouterait, puis s'arrête sans rien toucher. C'est cette liste qu'on relit. Un agent ne passe `--relu` que si Arnaud a dit avoir relu.

## Ce que le script fait, dans l'ordre

1. **Refuse un arbre sale.** Un commit de publication n'emporte pas des modifications étrangères.
2. **Lance `scripts/check.sh` sur l'état courant.** Rien n'est modifié si le dépôt est déjà en écart : les faux positifs ne se mêlent pas aux vrais. Ce build produit aussi les manifestes que la décision lit.
3. **Décide**, par `scripts/lib/publish-case.sh`, à partir des deux manifestes du rendu de travail (AD-10) : quels fichiers passer hors brouillon, quelles clés ajouter, quoi refuser. Les fichiers se trouvent par le **manifeste**, jamais par un chemin deviné : un cas rangé dans un sous-dossier se trouve comme les autres.
4. **Sans `--relu`, s'arrête ici.**
5. **Crée la branche** `feat/publish-case-<clé>`, depuis `dev` — la règle ne vaut qu'à partir d'ici, le premier temps se consulte depuis n'importe où.
6. **Réécrit `draft:`**, dans le **front matter seulement**, entre les deux premiers `---`. Un `draft:` cité dans le corps du texte n'est pas touché, et le script vérifie qu'il a changé une ligne, et une seule, par fichier.
7. **Ajoute à `ci/release-pages.txt`** le `translationKey` du cas et, pour un cas groupé, `group-<groupe>` — chacun seulement s'il en est absent (D-5). La liste est cumulative : C15 la comparera au site produit.
8. **Commite**, relance `scripts/check.sh` — c'est lui qui juge le cas devenu public —, pousse la branche, puis ouvre la PR par `create-pull-request`, avec un corps qui nomme les fichiers publiés et les clés ajoutées.

## Ce que le script refuse

| Refus | Pourquoi |
| --- | --- |
| le **poste** du cas est en brouillon | `publish-case` ne publie jamais le poste à la place de la story qui en a la charge (C19, AD-18) |
| un marqueur `[TODO` reste dans le cas ou dans la page de son groupe | un fichier publié n'en tolère aucun (C5) |
| le cas est déjà publié | rien à faire |
| la clé n'est pas celle d'un cas | `publish-case` ne publie que des cas |
| le cas ne désigne aucun poste | tout cas est rattaché à un poste (AD-18) |
| la page du groupe est publiée dans une langue et en brouillon dans l'autre | la parité (C3) compare l'existence des fichiers, pas leur brouillon : elle ne verrait pas ce boiteux |
| un contrôle échoue, avant ou après | ce que le contrôle dit |

## La page du groupe

Pour le **premier cas publié d'un groupe**, la page du groupe (`_index.{fr,en}.md`) passe hors brouillon **dans la même PR** : une page de groupe vide n'existe jamais en production, et un cas groupé sans sa page non plus (D-3, AD-4). Le script s'en charge et le nomme ; `--relu` couvre les deux fichiers, qui partent ensemble.

Si la page du groupe est déjà publiée, elle n'est pas retouchée — seule la clé `group-<groupe>` est proposée à `ci/release-pages.txt`, et n'y est ajoutée que si elle en est absente.

## Si les contrôles échouent après la modification

Le commit est déjà sur la branche : corriger, recommiter, relancer `scripts/check.sh`, puis pousser et ouvrir la PR à la main. Le script ne pousse ni n'ouvre rien tant que les contrôles ne passent pas.

## Pourquoi la décision vit dans une bibliothèque

`scripts/lib/publish-case.sh` ne lit que les manifestes et n'écrit rien : elle s'éprouve sur des manifestes écrits à la main, sans build, sans git et sans forge (`scripts/tests/test-publish-case.sh`). Le script, lui, fait le build, les contrôles, git et la forge. C'est la même séparation que pour les verrous de fusion (`verify-and-merge-pr.md`) — sans elle, aucun cas de test hors ligne n'est possible.
