# Test technique D2 : schémas bilingues et rendu déterministe

Expérimentation isolée, sans intégration Hugo. Elle tranche deux questions :
peut-on écrire la structure d'un schéma une seule fois avec des libellés FR et EN
séparés, et le rendu SVG est-il assez déterministe pour commiter les SVG et les
vérifier en CI par `git diff --exit-code` ?

## Version et installation

- **D2 v0.9.0** (dernière release publiée sur `d2lang/d2` au 2026-09-13), archive
  `d2-v0.9.0-linux-amd64.tar.gz` extraite dans un dossier temporaire, hors dépôt.
- Binaire Go **statiquement lié**, sans dépendance. Les deux moteurs gratuits sont
  embarqués et natifs en Go : dagre via le port `dagro` (surface Dagre 3.1.1),
  ELK via le port `elk-go` (profil ELK.js 0.12.0, algorithme `layered`).
  Pas de Node, pas de Chromium pour produire du SVG (Chromium ne sert qu'aux exports PNG/PDF).

```sh
D2=/chemin/vers/d2 ./render.sh             # régénère svg/
D2=/chemin/vers/d2 ./check-determinism.sh  # régénère deux fois et compare à svg/
```

## Contenu du dossier

| Chemin | Rôle |
|---|---|
| `reconciliation/structure.d2` | structure commune : identifiants, formes, liens, libellés en `${variables}` |
| `reconciliation/fr.d2`, `en.d2` | points d'entrée : bloc `vars` des libellés, puis `...@structure` |
| `theme.d2` | thème sobre proposé, importé par la structure (`...@../theme`) |
| `svg/` | SVG générés : `reconciliation.{fr,en}.{elk,dagre}.svg` |
| `render.sh` | parcourt chaque dossier contenant `structure.d2`, rend chaque langue avec chaque moteur |
| `check-determinism.sh` | deux rendus dans des dossiers temporaires, comparaison `cmp` entre eux et avec `svg/`, code retour 1 en cas d'écart |
| `approches/` | petits cas de test des approches ci-dessous |

Le schéma de test est générique : export BI → import → calcul dans l'application →
réconciliation contre un référentiel → écart dans la tolérance ? → publication, ou
alerte → analyse manuelle → nouveau calcul. 9 nœuds, un embranchement, une boucle.

## Question 1 : structure commune et libellés par langue

**Réponse : oui.** Les variables définies dans le fichier qui importe sont résolues
dans le fichier importé. Un schéma tient en trois fichiers : la structure, et un
fichier par langue qui déclare les libellés puis importe la structure.

```d2
# fr.d2
vars: {
  tolerance: "Écart dans la tolérance ?"
  oui: "oui"
}
...@structure
```

```d2
# structure.d2
tolerance: ${tolerance} { shape: diamond }
tolerance -> publication: ${oui}
```

### Approches testées

Chaque cas est dans `approches/` ; commande : `d2 --omit-version <fichier>.d2 sortie.txt`.

| Cas | Approche | Résultat |
|---|---|---|
| a1-structure | structure seule, variables non définies | **erreur** `a1-structure.d2:3:1: could not resolve variable "titre"` (une ligne par variable) |
| a1-fr | `vars` dans l'importeur, puis `...@structure` (import étalé) | **fonctionne** |
| a2-fr | idem, import non étalé `schema: @structure` | fonctionne, mais tout est enfermé dans un conteneur `schema` |
| a3-fr | fichier de libellés `vars` importé (`...@libelles-fr`), puis la structure | **fonctionne** |
| a4-fr | `vars: @libelles-fr` (le fichier ne contient que les paires clé/valeur) | **fonctionne** |
| a8-fr | `vars: { ...@libelles-fr }` | **fonctionne** |
| a5-fr | import de la structure **avant** le bloc `vars` | fonctionne : l'ordre n'importe pas |
| a13-fr | libellés communs importés (`oui`, `non`) + libellés propres au schéma | fonctionne : les deux blocs `vars` fusionnent |
| a6 | chemin d'import paramétré `...@libelles-${lang}` | **erreur** `a6-chemin-variable.d2:2:18: unexpected text after import` puis `2:23: unexpected map termination character } in file map` |
| a7-fr-avant / a7-fr-apres | valeur par défaut `vars: {titre: défaut}` dans la structure, surchargée par l'importeur | **ne surcharge pas** : la structure affiche « défaut », quel que soit l'ordre. Le `vars` le plus proche de l'usage gagne |
| a9-en-incomplet | une variable oubliée dans la langue EN | **erreur** `a1-structure.d2:3:6: could not resolve variable "suite"` : un oubli de traduction casse le rendu, c'est souhaitable |
| a10-var-superflue | variable en trop (nom mal orthographié, inutilisée) | **silencieux** : pas d'avertissement |
| a11-interpolation | variable contenant `\n`, interpolée dans une chaîne, dans un bloc markdown | fonctionne dans les trois cas |
| a12-fr | `d2-config` (thème, moteur) déclaré dans le fichier importé | appliqué |
| a15-sous | import depuis le dossier parent `...@../commun/theme-test` | fonctionne : un thème partagé entre schémas est possible |
| b-fr | structure avec libellés neutres, surchargés par clé dans le fichier de langue (`a.label: …`, `(a -> b)[0].label: …`) | fonctionne |
| b2-fr | mêmes surcharges, mais dans un fichier importé après la structure | **erreur** `b2-libelles-fr.d2:3:2: indexed edge does not exist` : chaque fichier importé est compilé seul, l'arête n'y existe pas |
| b2b-fr | surcharges de nœuds seulement dans un fichier importé | fonctionne, mais les libellés d'arêtes restent impossibles |
| b3-faute | surcharge par clé avec une faute de frappe (`c.label`) | **silencieux** : D2 crée un nœud fantôme « Fantome » |

### Conclusion sur l'approche

- **Retenue : variables** (a1). Un libellé manquant échoue avec la ligne exacte ; les
  arêtes se traduisent comme les nœuds ; la structure ne contient aucun texte.
- **Écartée : surcharge par clé** (b). Les fautes de frappe créent des nœuds fantômes
  sans erreur, et les libellés d'arêtes ne passent pas par un fichier importé.
- Le chemin d'import ne peut pas dépendre d'une variable (a6) : il faut **un point
  d'entrée par langue**. C'est aussi là que vivent les libellés, donc aucun fichier en plus.
- Règles à documenter pour la suite :
  - aucune variable de libellé déclarée dans `structure.d2` (a7), sinon elle masque la langue ;
  - une variable superflue passe inaperçue (a10). Si besoin, un contrôle shell simple
    peut comparer les clés de `fr.d2` et `en.d2` à celles de `structure.d2`.

## Question 2 : déterminisme

**Réponse : oui, à l'octet près**, avec ELK comme avec dagre.

- `check-determinism.sh` : deux rendus séparés, comparés entre eux et à `svg/`.
  Sortie : `identique : reconciliation.fr.elk.svg …` pour les quatre fichiers, puis
  `OK : rendu déterministe`, code retour 0, en moins d'une seconde.
- Test d'endurance (hors dépôt) : 20 rendus par combinaison langue × moteur, avec les
  options par défaut, puis avec `--omit-version` et un environnement qui varie
  (`GOMAXPROCS` de 1 à 4, `TZ=Pacific/Auckland`, `LANG=C`), puis depuis un autre
  répertoire courant avec un chemin absolu. Résultat : **un seul hash** par
  combinaison, et le rendu depuis un autre répertoire est identique.
- Aucun horodatage ni chemin de fichier dans le SVG (`grep` du chemin, de l'année : 0 occurrence).
- Les identifiants (`class="d2-4054731489"`) sont un hash du contenu : stables d'un
  rendu à l'autre, différents d'un schéma à l'autre. `--salt` existe si deux SVG
  identiques doivent cohabiter dans une même page.
- Contrôle négatif : un SVG de `svg/` modifié d'un octet produit
  `ÉCART avec svg/ : … (lancer ./render.sh et commiter)`, et un fichier en trop
  `OBSOLÈTE dans svg/`, avec le code retour 1.

**Seule variation trouvée : la version de D2.** Sans option, la racine du SVG
porte `data-d2-version="v0.9.0"`. `--omit-version` la retire (utilisé par
`render.sh`). Une montée de version peut aussi changer la mise en page elle-même :
la CI doit **épingler la version exacte** du binaire, et une montée de version se fait
dans un commit dédié qui régénère tous les SVG.

## Question 3 : observations

### Taille et polices

- SVG de 19 à 21 Ko pour 9 nœuds (EN un peu plus léger que FR).
- Polices **embarquées** dans chaque SVG en WOFF base64 : Source Sans Pro gras
  (libellés des nœuds) et italique (libellés des arêtes), **réduites aux glyphes
  utilisés** (9 à 11 Ko de base64 par fichier). Le rendu ne dépend donc pas des
  polices du visiteur. Les options `--font-regular`, `--font-bold`, etc. acceptent
  des fichiers `.ttf` si le site adopte une autre police.
- D2 écrit les fichiers en mode `0600`. Git ne conserve pas ce mode (seul le bit
  exécutable compte), mais une copie directe dans une image nginx devra rétablir des droits de lecture.
- `render.sh` utilise `--no-xml-tag` (SVG insérable tel quel dans du HTML) et
  `--pad 24` (la marge par défaut, 100 px, est excessive).

### Libellés longs, FR contre EN

D2 **ne coupe pas** les libellés : une boîte s'élargit à la longueur du texte.
Les retours à la ligne se placent à la main (`\n`) dans le fichier de langue, donc
différemment en FR et en EN si besoin (voir `reference`).

| Rendu (`--pad 24`) | FR | EN |
|---|---|---|
| ELK | 876 × 1344 | 760 × 1344 |
| dagre | 1010 × 1344 | 911 × 1344 |

La **topologie ne change pas** entre les langues : mêmes rangs, même ordre des
nœuds, même tracé des liens. Seule la largeur varie (FR plus large de 15 % avec ELK, 11 % avec dagre).
Les deux versions restent visuellement « le même schéma », ce qui compte pour un site bilingue.

### ELK contre dagre

- **ELK** : liens orthogonaux, rendu net et compact (le plus étroit). L'ordre des branches
  suit le source (« oui » à gauche, « non » à droite). Le lien de retour « correction puis
  nouveau calcul » longe proprement le bord droit. Défaut mineur : ce libellé est
  posé sur la ligne pointillée verticale.
- **dagre** : liens courbes, schéma plus large de 15 à 20 %. Il inverse les branches
  (« non » à gauche) et place le référentiel à droite. C'est lisible, mais moins
  structuré pour un flux de décision.

### Thèmes

- **Thème par défaut (0, Neutral Default)** : bleu soutenu sur fonds bleutés, typé « outil ».
  Correct, mais peu sobre.
- **1 (Neutral Grey)** : sobre, mais losange et cylindre gris moyen assez lourds.
- **301 (Terminal Grayscale)** : police à chasse fixe, style terminal, trop marqué.
- **303 (C4)** : aplats gris et liens pointillés, peu lisible ici.
- **8 (Colorblind Clear)**, **103 (Earth Tones)** : accents colorés, hors ton pour un portfolio sobre.

**Proposition : `theme.d2`**, base 1 et surcharges `theme-overrides` : encre ardoise
`#1F2933`, bordures et liens bleu ardoise `#334E68`, fonds `#F8FAFC` / `#E4E7EB`,
losange éclairci. Le thème est déclaré une fois et importé par chaque structure.

Précédence vérifiée (a12, a15) : l'option `--theme` en ligne de commande **écrase**
`theme-id` du fichier, mais les `theme-overrides` restent appliqués par-dessus.
`render.sh` ne passe donc pas `--theme` et neutralise `D2_THEME`. Le mode sombre
(`dark-theme-overrides`) n'a pas été testé.

## Recommandation

1. **Structure commune possible : oui.** Un dossier par schéma avec `structure.d2`
   (libellés en `${variables}`), `fr.d2` et `en.d2` (bloc `vars`, puis `...@structure`).
   Pas de deuxième fichier de structure par langue.
2. **Moteur : ELK.** Même coût que dagre, rendu orthogonal plus lisible pour des flux
   de décision, ordre des branches respecté, schéma plus compact. Dagre reste disponible
   par schéma via `layout-engine` si un cas s'y prête mieux.
3. **Thème : `theme.d2`** (Neutral Grey surchargé), partagé par tous les schémas.
4. **SVG commités : faisable.** Rendu déterministe à l'octet, avec deux conditions :
   `--omit-version` et une version de D2 épinglée dans la CI.

## Limites et points non vérifiés

- Un seul schéma testé (9 nœuds, sans conteneur imbriqué, sans icône ni lien cliquable).
- Déterminisme vérifié sur une seule machine (Linux x86_64, WSL2). Non vérifié entre
  architectures : une CI arm64 pourrait différer sur les calculs flottants. Il faut
  la même architecture en local et en CI, ou un test dédié.
- Inspection visuelle faite par conversion PNG avec `resvg`, qui ignore les polices
  embarquées : le texte a été affiché avec Segoe UI, pas Source Sans Pro. La mise en
  page est fidèle, mais le débordement exact d'un libellé (l'étape « Analyse manuelle »)
  reste à confirmer dans un navigateur.
- Mode sombre, accessibilité (contraste mesuré, `<title>`/`<desc>`) et intégration Hugo
  (inline ou `<img>`) non testés.
