# Procédure — Garde-fou public/privé

Le dépôt est public : rien de `docs/private/` ni aucune donnée personnelle ne doit entrer dans son historique. `scripts/check-private.sh` le vérifie ; c'est le seul script du garde-fou (AD-12).

## Quand le lancer

- **À chaque commit** : automatiquement, par le hook pre-commit (mode `staged`).
- **Avant tout push** : `history` sur les commits de la branche.
- **Avant l'activation du miroir GitHub**, et avant tout push vers GitHub : `history` sur tout l'historique, avec la liste des motifs (AD-12, story 1.3). Un commit poussé sur GitHub reste accessible par son SHA, même après un force-push.
- **Avant l'envoi d'un diff à un relecteur externe** (`llm-review`) : `history` sur la plage relue, dans la copie isolée (voir « Copie isolée »).
- **Après une réécriture d'historique** : `history` sur tout l'historique.

## Ce qu'il vérifie

- **Chemins interdits** : `docs/private/`, `docs/context/`, `.env` à toute profondeur, et `assets/cv/*.pdf` tant que le hook serveur ne sait pas lire les PDF (AD-21). Nommer `docs/private/` dans un fichier est permis ; y placer un fichier ne l'est pas.
- **Motifs** : des chaînes fixes, cherchées sans tenir compte de la casse, une par ligne dans le **fichier de motifs**. Les lignes vides et celles qui commencent par `#` sont ignorées. La recherche ignore les fichiers binaires : le texte des PDF et les métadonnées des images relèvent d'autres contrôles (C20, C21).
- **Un passage, puis le détail** : chaque arbre vérifié (l'index ou un commit) est d'abord cherché en un seul passage avec tous les motifs. La recherche motif par motif, qui situe chaque résultat, n'a lieu que si ce passage trouve quelque chose. Une erreur de recherche fait échouer le garde-fou : elle ne vaut jamais « rien trouvé ».

Le fichier de motifs vit hors du dépôt : `docs/private/forbidden-patterns.txt`, ou le fichier désigné par la variable `PRIVATE_PATTERNS_FILE`. **Son contenu n'est jamais recopié** : ni dans un fichier suivi, ni dans un commit, une PR, un journal de CI ou une conversation d'agent. Seul Arnaud le modifie, et il le commite dans le dépôt privé. Le nom d'Arnaud n'y figure jamais : son identité publique est voulue.

## Activer le hook local

Une fois par clone :

```bash
git config core.hooksPath .githooks
git config --get core.hooksPath   # doit afficher le chemin de .githooks
```

Le hook `.githooks/pre-commit` lance `scripts/check-private.sh staged`. Un commit refusé ne se contourne pas par `--no-verify`.

## Les trois modes

### `staged` : l'index

```bash
scripts/check-private.sh staged
```

Vérifie tous les fichiers de l'index : ce que le prochain commit contiendra. C'est le mode du hook pre-commit.

### `history` : l'historique

```bash
scripts/check-private.sh history              # tous les commits de toutes les références
scripts/check-private.sh history dev..HEAD    # les commits de la branche courante
```

Sans argument, le mode vérifie chaque commit accessible depuis toutes les références (branches locales, branches distantes connues, tags). Avec des arguments, il prend ceux de `git rev-list`.

L'**audit complet** est `scripts/check-private.sh history`, sans argument, lancé dans le dépôt de travail où `docs/private/forbidden-patterns.txt` existe. Sa sortie ne doit contenir ni alerte, ni la mention « chemins seulement ».

En CI (Gitea et GitHub), le fichier de motifs n'existe pas : le mode `history` n'y vérifie que les chemins (AD-12). Ce passage ne remplace pas l'audit complet.

### `pre-receive` : le hook serveur

```bash
scripts/check-private.sh pre-receive < lignes-reçues
```

Lit sur l'entrée standard les lignes `ancien nouveau référence` que git passe à un hook pre-receive, et vérifie chaque nouveau commit qui n'est encore accessible depuis aucune référence du serveur. Une suppression de branche est ignorée.

L'installation de ce hook sur la forge est la story 1.2. Aujourd'hui, sans fichier de motifs, ce mode se replie sur les chemins ; l'échec en l'absence de fichier de motifs est la story 1.1.

## Copie isolée

Dans un worktree créé hors du dépôt, ou dans un clone, `docs/private/` n'existe pas. Le script l'annonce sur la sortie d'erreur :

```
check-private: pas de fichier de motifs (…), chemins seulement
```

et ne vérifie alors que les chemins. **Ce passage ne vaut pas audit.** Pour auditer une copie isolée, désigner le fichier de motifs du dépôt de travail :

```bash
PRIVATE_PATTERNS_FILE=<dépôt de travail>/docs/private/forbidden-patterns.txt \
  scripts/check-private.sh history dev..<SHA>
```

Toute vérification qui affiche « chemins seulement » là où un audit est exigé (push, miroir, relecteur externe) est à refaire.

## Lire une alerte

Le script sort avec le code `1` et termine par `check-private: refusé. Retire le contenu privé avant de continuer.` Il n'affiche **jamais** le contenu trouvé ni le motif, pour qu'aucune donnée privée ne passe dans un terminal, une conversation d'agent, un journal de CI ou la réponse du hook serveur. Il donne seulement l'emplacement et le numéro de ligne du motif dans le fichier de motifs :

```
check-private: contenu privé dans l'index (contenu masqué) :
notes/brouillon.md:12 (motif ligne 7)
check-private: contenu privé dans 1a2b3c4 (contenu masqué) :
1a2b3c4d…:notes/brouillon.md:12 (motif ligne 7)
check-private: chemin privé dans l'index :
docs/private/exemple.txt
```

(Noms et numéros d'exemple.) Les messages `recherche impossible dans …` et `lecture impossible de …` ne signalent pas un contenu privé : un objet git est illisible, le garde-fou n'a pas pu vérifier cet arbre et refuse donc. Il faut réparer ou recloner le dépôt avant de relancer. Un nom de fichier qui contient un saut de ligne s'affiche sur plusieurs lignes ; la détection et le masquage n'en dépendent pas. Le numéro de motif sert à Arnaud, qui ouvre lui-même le fichier de motifs ; un agent ne l'affiche pas.

## En cas d'alerte

1. **Dans l'index** : retirer le contenu du fichier à la ligne indiquée, ou retirer le fichier de l'index, puis recommencer le commit.
2. **Dans un commit local, jamais poussé** : corriger ce commit dans la branche locale, puis relancer `history` sur la branche.
3. **Dans un commit déjà poussé sur la forge** : s'arrêter. Rien ne part vers GitHub. La réécriture de l'historique et le force-push qui la suit ne se font qu'avec l'approbation explicite d'Arnaud ; relancer ensuite l'audit complet. Si c'est un secret, suivre aussi « En cas de fuite » dans `gitea-token.md`.
4. **Un faux positif** : c'est à Arnaud de préciser le motif dans le fichier de motifs ; le garde-fou ne se contourne pas.
