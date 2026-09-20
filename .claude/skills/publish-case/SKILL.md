---
name: publish-case
description: Publie un cas du site eleyone.fr — tous les contrôles, puis draft: false dans une PR, avec la page du groupe s'il s'agit de son premier cas. À utiliser quand Arnaud demande de publier un cas, de le sortir du brouillon ou de le mettre en ligne.
---

# publish-case

Fait passer un cas de `draft: true` à `draft: false`, toujours de la même façon.

La procédure fait foi : `docs/procedures/publish-case.md`. L'exécution est `scripts/publish-case.sh`.

À retenir :

- **deux temps.** `scripts/publish-case.sh <translationKey>` lance tous les contrôles et affiche ce qu'il changerait, sans rien toucher. Le second appel, avec `--relu`, publie ;
- **`--relu` est l'affaire d'Arnaud**, pas la tienne : ne le passe que s'il a dit avoir relu les fichiers que le premier appel a nommés. C'est la relecture humaine qu'exige le format ;
- la clé attendue est le `translationKey` du cas (`case-02`), pas un chemin de fichier : le script trouve les fichiers par le manifeste ;
- le script **ne publie jamais le poste** du cas. Un poste en brouillon fait échouer la publication, et c'est voulu : une autre story en a la charge ;
- pour le **premier cas publié d'un groupe**, la page du groupe part dans la même PR (D-3). Le script le dit, et le corps de la PR le nomme ;
- un refus ne modifie rien : corrige la cause indiquée, puis relance ;
- si les contrôles échouent **après** la modification, le commit est déjà sur la branche : corrige, recommite, relance les contrôles, puis pousse et ouvre la PR à la main.
