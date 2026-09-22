# Registre d'accessibilité

AD-17 partage la vérification en deux. **L'automatique** est dans `scripts/check.sh` (C11 : langue, titre, plan des titres, identifiants, alternatives, noms de liens, `hreflang`, `tabindex`) et bloque à chaque build. **Le manuel** ne peut pas l'être : mesurer un contraste, éprouver le clavier ou le reflow demande un navigateur, qu'aucune CI du projet ne lance (AD-17, AD-10).

Ce fichier est la trace de la part manuelle. Il répond à une question que les fichiers de story ne savent pas répondre : **ce gabarit a-t-il été vérifié, quand, et par quelle story ?** (décidé par Arnaud le 21/09/2026, rétrospective de l'epic 4 et story 5.1).

**Toute story qui crée ou modifie un gabarit met à jour sa ligne ici**, dans sa propre PR. Un gabarit dont la ligne est plus ancienne que sa dernière modification n'est pas vérifié : il est périmé.

## Ce qui est vérifié

La check-list d'AD-17, dans le **mode clair et le mode sombre** :

| Point | Critère WCAG 2.2 | Comment |
|---|---|---|
| Contraste du texte | 1.4.3 (AA) | 4,5:1 pour le texte, 3:1 pour les composants et frontières signifiantes. Les paires sont déjà calculées dans `DESIGN.md` § Contrastes calculés : la vérification confirme que le rendu emploie bien ces tokens, et mesure toute paire nouvelle. |
| Focus visible, non masqué | 2.4.7, 2.4.11 | Anneau `{spacing.focus-ring}` sur chaque élément focalisable, jamais `outline: none`. |
| Lien d'évitement | 2.4.1 | Premier élément focalisable, invisible au repos, à l'écran au focus, menant à `#content`. |
| Taille des cibles | 2.5.8 | 24 px au moins. Les liens **dans le texte courant** sont exemptés ; un lien seul dans son bloc n'en est pas. |
| Reflow | 1.4.10 | 320 px de large sans **aucun** défilement horizontal de la page. |
| Zoom | 1.4.4 | 200 % sans perte de contenu ni de fonction. |
| Ordre de lecture | 1.3.2 | L'ordre du DOM est l'ordre de lecture, la grille ne le réordonne pas. |
| Accueil à 390 × 844 | FR-37 | Sans défilement : identité, titre, pitch et début du premier poste. |

## État par gabarit

Mesures relevées au navigateur, à 320 px, sur le rendu de travail.

| Gabarit | Vérifié le | Par | Contraste min. (clair / sombre) | Cible min. | Défilement à 320 px | Focus |
|---|---|---|---|---|---|---|
| Accueil (CV) | 21/09/2026 | story 5.5 | aucune paire sous 4,5:1 | 28 px | aucun | anneau 2 px `accent` dans les deux modes |
| Page de groupe (Chiliz) | 22/09/2026 | story 6.1 | aucune paire sous 4,5:1 | 26,2 px | aucun | idem |
| 404 | 21/09/2026 | story 5.1 | 15,61:1 / 14,75:1 | 28 px | aucun | idem |

Les ratios relevés au navigateur retrouvent exactement ceux de `DESIGN.md` : `ink` sur `paper` 15,61:1 en clair et 14,75:1 en sombre, `accent` sur `paper` 6,26:1 et 9,05:1, `ink-muted` sur `paper` 6,52:1 et 7,68:1.

**Gabarits pas encore vérifiés**, parce qu'ils n'existent pas : page d'un cas seul (story 6.2), pages simples (9.x).

**Page de groupe, revérifiée le 22/09/2026 par la story 6.1**, sur les **trois** cas Chiliz du rendu de travail et non sur le seul cas 02. Relevés au navigateur :

- **320 px** : aucun défilement horizontal (`scrollWidth` 305 pour 320) ; aucun élément ne dépasse.
- **Cibles** : le résumé du sommaire est la plus petite à 26,2 px avec un libellé court, 44,4 px avec celui de la page à trois cas.
- **Contrastes**, clair puis sombre : terme de « Contexte mission » 6,02 / 7,68 ; valeur 14,41 / 14,75 ; « En bref » 14,41 / 13,00 ; lien de sommaire 6,26 / 9,05 ; numéro de cas et de rubrique 6,52 / 7,68. Aucune paire sous 4,5:1.
- **Grille à 1 280 px** : marge 216 px, texte 640 px à x = 301, note 240 px à x = 981 — la colonne de texte est au même endroit que sur l'accueil, ce que la grille existe pour tenir. Le sommaire ne recouvre jamais le texte.
- **Sommaire collant** : 768 px pour 800 px de hauteur utile, borné et défilant sur lui-même.
- **Premier écran à 390 × 844, arrivée sur `#case-02`** : numéro, titre et « Contexte mission » entier visibles, « En bref » commençant à 586 px sur 844. La section se pose à 40 px du bord, jamais collée.

**Critère mobile 390 × 844 de l'accueil** (FR-37), revérifié le 21/09/2026 par la story 5.5, **photo comprise**, sur un pitch d'essai de trois phrases : sans défiler, on voit la ligne d'identité (98 → 158 px), la photo à sa droite (98 → 188 px), le pitch (256 → 379 px), le titre « Parcours » (419 px), et le premier poste entier avec son lien de cas, qui finit à **622 px sur 844**. Il reste 222 px de marge.

La photo ne repousse donc pas le pitch hors du premier écran, ce qu'exige `DESIGN.md` : sous `md` elle occupe la colonne de droite à hauteur des seules lignes d'identité, et le pitch passe pleine largeur dessous. À revérifier à chaque modification du haut de l'accueil, du premier poste ou de la photo.

## Ce que la vérification manuelle a trouvé

Trace de ce que l'automatique ne voit pas, pour que la valeur de l'exercice reste lisible.

**Story 5.1, 21/09/2026 — huit cibles sous 24 px.** La marque de l'en-tête (20 px), les liens du pied de page (22 px), le retour au parcours, les six entrées du sommaire et les deux liens de la 404 (23 px). Toutes corrigées.

La cause est la même partout et mérite d'être retenue : **un `line-height` n'agrandit pas une cible.** Il agrandit la ligne ; la zone cliquable reste la boîte en ligne du lien. Il faut un `display: inline-block` et une marge intérieure verticale. `DESIGN.md` § site-footer dit « un interligne qui garantit une cible d'au moins 24 px » — appliqué à la lettre, cela ne garantit rien.

Aucun contrôle automatique ne l'aurait vu : C11 vérifie qu'un lien a un nom accessible, pas la taille de sa cible, qui n'existe qu'au rendu.

**Story 6.1, 22/09/2026 — le résumé du sommaire, neuvième cible sous 24 px.** Mesuré à **18 px** avec un libellé court comme « Sommaire · 6 rubriques ». Il passait inaperçu depuis la story 2.6 pour deux raisons qui se sont additionnées : ce n'est pas un lien mais une commande, et la règle des 24 px, écrite à l'epic 5, ne listait que des liens ; et le libellé de la page Chiliz, « Sommaire · 3 cas, 19 rubriques », se replie sur deux lignes à 320 px, ce qui portait la boîte à 36 px. **Mesuré sur le contenu du jour, il passait.** C'est le troisième élément que ce piège atteint, après le lien de cas rattaché de l'epic 5 — le point 11 d'`AGENTS.md` en situation.

Corrigé par l'entrée de `.toc summary` dans la même règle : 26,2 px avec un libellé court. Le marqueur natif du `<details>`, que `display: inline-block` supprime, est reposé explicitement.

**Story 6.1, 22/09/2026 — le sommaire collant ne tenait pas dans la fenêtre.** Mesuré à **1 088 px** pour les 22 entrées des trois cas, dans une colonne de 13,5 rem, contre **368 px** pour le seul cas 02 publié aujourd'hui. `DESIGN.md` ne disait pas ce qui se passe au-delà : la question ne se posait pas quand un seul cas existait. Arnaud a tranché pour un défilement interne borné par la fenêtre.
