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
| Accueil (minimal) | 21/09/2026 | story 5.1 | 15,61:1 / 14,75:1 | 28 px | aucun | anneau 2 px `accent` dans les deux modes |
| Page de groupe (Chiliz) | 21/09/2026 | story 5.1 | aucune paire sous 4,5:1 | 28 px | aucun | idem |
| 404 | 21/09/2026 | story 5.1 | 15,61:1 / 14,75:1 | 28 px | aucun | idem |

Les ratios relevés au navigateur retrouvent exactement ceux de `DESIGN.md` : `ink` sur `paper` 15,61:1 en clair et 14,75:1 en sombre, `accent` sur `paper` 6,26:1 et 9,05:1, `ink-muted` sur `paper` 6,52:1 et 7,68:1.

**Gabarits pas encore vérifiés**, parce qu'ils n'existent pas : accueil CV (story 5.2), page d'un cas seul (6.2), pages simples (9.x).

## Ce que la vérification manuelle a trouvé

Trace de ce que l'automatique ne voit pas, pour que la valeur de l'exercice reste lisible.

**Story 5.1, 21/09/2026 — huit cibles sous 24 px.** La marque de l'en-tête (20 px), les liens du pied de page (22 px), le retour au parcours, les six entrées du sommaire et les deux liens de la 404 (23 px). Toutes corrigées.

La cause est la même partout et mérite d'être retenue : **un `line-height` n'agrandit pas une cible.** Il agrandit la ligne ; la zone cliquable reste la boîte en ligne du lien. Il faut un `display: inline-block` et une marge intérieure verticale. `DESIGN.md` § site-footer dit « un interligne qui garantit une cible d'au moins 24 px » — appliqué à la lettre, cela ne garantit rien.

Aucun contrôle automatique ne l'aurait vu : C11 vérifie qu'un lien a un nom accessible, pas la taille de sa cible, qui n'existe qu'au rendu.
