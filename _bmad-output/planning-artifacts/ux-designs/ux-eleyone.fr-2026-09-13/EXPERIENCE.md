---
name: eleyone.fr — Expérience
status: draft
updated: 2026-09-13
sources:
  - _bmad-output/planning-artifacts/prds/prd-eleyone.fr-2026-09-13/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md
  - docs/format-cas.md (v0.3)
  - content/cases/chiliz/case-02-chiliz.fr.md
  - content/cases/chiliz/case-02-chiliz.en.md
  - décisions d'Arnaud du 13/09/2026
companions:
  - DESIGN.md
  - .memlog.md
---

# eleyone.fr — Expérience

## Foundation

- **Surface** : site web statique, multipage, responsive, mobile d'abord. Pas d'application, pas de compte, pas de formulaire (PRD §6).
- **Système d'interface** : aucun. HTML sémantique et une feuille `assets/css/main.css` ; seuls les comportements natifs du navigateur sont utilisés (liens, ancres, `<details>`). `DESIGN.md` est la référence visuelle ; ce document décrit le comportement.
- **Contraintes qui façonnent chaque interaction** :
  - zéro JavaScript, sauf le bloc de données JSON-LD de l'accueil (NFR-12, AD-20) ;
  - aucune ressource tierce, aucun cookie (NFR-3) ;
  - mode clair ou sombre selon la préférence du système, sans bouton (NFR-13) ;
  - deux langues complètes, le français à la racine et l'anglais sous `/en/`, sans redirection (FR-21) ;
  - WCAG 2.2 AA dans les deux modes (NFR-4).
- **Rendus** : la production n'affiche que le contenu publié ; le rendu de travail montre aussi les brouillons et le matériel « prévu » (AD-5).
- **Références visuelles** : les maquettes « Dossier d'architecture » (tour 1 pour la page cas, tour 2 pour l'accueil CV), restées hors du dépôt. En cas de conflit, les deux documents l'emportent.

## Information Architecture

| Surface | URL FR / EN | Atteinte depuis | Rôle | Exigences |
|---|---|---|---|---|
| Accueil (CV) | `/` · `/en/` | marque de l'en-tête, lien de retour d'une page cas, 404 | identité, pitch, parcours avec preuves, « En parallèle », formation, appel à contact | FR-1 à FR-4, FR-33 à FR-37 |
| Page cas seul | `/cas/<slug>/` · `/en/cases/<slug>/` | lien du cas sous son poste ou dans « En parallèle » | un cas : Contexte mission, En bref, cas complet | FR-5 à FR-8, FR-10 à FR-15 |
| Page Chiliz | `/cas/chiliz/` · `/en/cases/chiliz/` | lien d'un cas 02, 03 ou 04 sous le poste Chiliz (vers `#case-NN`) | cas 02, 03 et 04 publiés, dans l'ordre, un par section | FR-9, FR-10 |
| À propos | `/a-propos/` · `/en/about/` | en-tête | positionnement ; CV PDF en évidence | FR-16, FR-38 |
| Contact | `/contact/` · `/en/contact/` | en-tête, appel à contact de l'accueil | adresse mail et LinkedIn | FR-17, FR-3 |
| Mentions légales | `/mentions-legales/` · `/en/legal-notice/` | pied de page | mentions exigées par la loi | FR-18 |
| Confidentialité | `/confidentialite/` · `/en/privacy/` | pied de page | aucune collecte, liens YouTube tiers | FR-19 |
| 404 | `/404.html` · `/en/404.html` | toute URL inconnue (nginx, AD-13) | remettre le lecteur sur l'accueil | — |
| CV PDF | `/cv/cv-fr.pdf` · `/cv/cv-en.pdf` (noms décidés par Arnaud le 13/09/2026, AD-21) | pied de page de toutes les pages, À propos | garder un CV | FR-38 |
| Dépôt public | GitHub (URL à fournir) | pied de page | voir le code et le cadrage | FR-29 |

- **Pas de liste des cas** : `/cas/` n'est pas rendue (AD-4). On accède aux cas par l'accueil, qui est le CV. La page cas n'a donc pas de fil d'Ariane vers « Cas ».
- **En-tête** (toutes les pages) : marque `eleyone.fr` → accueil ; « À propos » ; « Contact » ; sélecteur de langue. Rien d'autre.
- **Pied de page** (toutes les pages) : CV PDF (si publiés), mentions légales, confidentialité, code source du site.
- **Profondeur** : tout contenu est à un clic de l'accueil au plus (SM-3). Une page cas mène à l'accueil par le lien de retour ; aucune page cas ne lie un autre cas.

### Ancres

| Ancre | Où | Forme | Stable entre FR et EN |
|---|---|---|---|
| Section d'un cas groupé | page Chiliz | `#case-02` (`translationKey`, AD-4) | oui |
| Rubrique d'un cas | page cas, page Chiliz | `#case-02-<identifiant du titre>` (hook de titres, AD-4), par exemple `#case-02-contexte` en FR et `#case-02-context` en EN | non : l'identifiant vient du titre traduit |
| Poste de l'accueil | accueil | `#position-chiliz` (`translationKey` du poste), cible de « Retour au parcours » (décidé le 13/09/2026 ; impact AD-18) | oui |
| Bloc de l'accueil | accueil | `#parcours` / `#experience`, `#contact` | non, et sans importance : jamais ciblés depuis une autre page |
| Contenu principal | toutes | `#content`, cible du lien d'évitement | oui |

- Le sélecteur de langue mène à la page équivalente, **sans ancre** : sans JavaScript, il ne connaît pas la position de lecture. Le lecteur arrive en haut de la page traduite.
- Le lien d'un cas groupé depuis l'accueil vise la section (`/cas/chiliz/#case-02`), jamais le haut de la page Chiliz.
- Le lien de retour d'une page cas vise le poste de ce cas sur l'accueil (`/#position-chiliz`) : le lecteur retrouve le CV là où il l'avait quitté.

## Voice and Tone

Microcopie de l'interface (libellés i18n, AD-3). La voix du contenu est celle d'Arnaud (première personne, factuelle) et relève du contenu, pas de ce document.

| Clé (proposée) | FR | EN | Statut |
|---|---|---|---|
| `block_career` | Parcours | Experience | décidé (13/09/2026) |
| `block_parallel` | En parallèle | Alongside | décidé (13/09/2026) |
| `block_education` | Formation, certification, langues | Education, certification, languages | décidé (13/09/2026) |
| `education_kind_*` | Formation · Certification · Langues | Education · Certification · Languages | à valider par Arnaud |
| `block_contact` | Contact | Contact | à valider par Arnaud |
| `contact_cta` | Me contacter | Get in touch | à valider par Arnaud |
| `case_number` | Cas 02 | Case 02 | décidé (13/09/2026) |
| `cases_of_position` (nom accessible de la liste) | Cas qui prouvent ce poste | Cases behind this role | à valider par Arnaud |
| `context_box` | Contexte mission | Engagement context | décidé (AD-3) |
| `summary_box` | En bref | At a glance | décidé (AD-3) |
| Champs de l'encart | Société · Cadre · Rôle · Période · Stack | Company · Engagement · Role · Period · Stack | décidé (AD-3) |
| Cadres | Salarié · Freelance · ESN · Ton Pote le Geek | Employee · Freelance · IT consultancy · Ton Pote le Geek | décidé (AD-3) |
| `based_in` | Basé en France | Based in France | décidé (AD-19) |
| `toc` | Sommaire · 6 rubriques | Contents · 6 sections | à valider par Arnaud |
| `back_to_career` | Retour au parcours | Back to experience | lien décidé (13/09/2026) ; libellé EN à valider |
| `skip_to_content` | Aller au contenu | Skip to content | à valider par Arnaud |
| `language_switch` | English | Français | décidé (13/09/2026) |
| `cv_pdf` | CV en PDF, français (NNN Ko) · CV en PDF, anglais (NNN Ko) | CV (PDF, English, NNN KB) · CV (PDF, French, NNN KB) | emplacement décidé, libellé à valider |
| `diagram_full_size` | Ouvrir en taille réelle | Open full size | à valider par Arnaud |
| `video_suffix` | (vidéo sur YouTube) | (video on YouTube) | à valider par Arnaud |
| `footer_legal` · `footer_privacy` · `footer_source` | Mentions légales · Confidentialité · Code source du site | Legal notice · Privacy · Site source code | à valider par Arnaud |
| `not_found_title` | Page introuvable | Page not found | à valider par Arnaud |

| À faire | À éviter |
|---|---|
| Des libellés courts, qui disent ce qu'il y a derrière (« CV en PDF, français (180 Ko) ») | « Télécharger », « Cliquez ici », « En savoir plus » |
| Ne rien écrire pour ce qui n'existe pas | « En bref à venir », « Aucun cas », « Bientôt disponible » |
| Nommer le tiers quand un lien quitte le site (« vidéo sur YouTube ») | Ouvrir un nouvel onglet, ou annoncer un tiers par une icône |
| Le même ton en FR et en EN, sans point d'exclamation | Un anglais plus « vendeur » que le français |
| Typographie française sur les pages FR (espaces insécables, guillemets « ») | Espaces avant la ponctuation sur les pages EN |

## Component Patterns

Comportement. L'aspect visuel est dans `DESIGN.md.Components`, sous les mêmes noms.

| Composant | Où | Règles de comportement |
|---|---|---|
| `link` | partout | Action par défaut du navigateur, dans le même onglet (jamais `target="_blank"`). Un lien vers un PDF annonce le format et la taille dans son texte, et porte `type="application/pdf"`. Un lien vers un autre site le dit dans son texte quand ce n'est pas évident (YouTube). |
| `focus-ring` | tout élément focalisable | Visible au clavier (`:focus-visible`), jamais masqué par un autre élément : ni en-tête ni pied de page collants (2.4.11). |
| `skip-link` | toutes les pages | Premier élément focalisable ; mène à `#content` (le `main`). |
| `site-header` | toutes les pages | Ordre de tabulation : marque, À propos, Contact, sélecteur. L'élément de la page courante porte `aria-current="page"` et reste un lien. |
| `language-switch` | en-tête | Mène à la page équivalente (`.Translations`, AD-2). Page Chiliz → page Chiliz de l'autre langue. Si une traduction manque (impossible en production, FR-20), il mène à l'accueil de l'autre langue plutôt que de disparaître. |
| `identity-block` | accueil | Aucun élément interactif. `h1` = ligne d'identité. La photo a un `alt` dans la langue de la page (FR-34). |
| `cv-position` | accueil | Porte `id="position-<id>"`. Non cliquable en entier : seuls le nom de Ton Pote le Geek et les titres de cas sont des liens. Les postes suivent `order` (AD-18). |
| `attached-case` | accueil | Cas retrouvés par leur clé `position` (format v0.4, validé ; plus de `featured` ni de cas mis en avant). Liste ordonnée par `number`, nom accessible `cases_of_position`. Chaque titre mène au cas en un clic : page cas, ou `#case-NN` de la page Chiliz. N'affiche que les cas publiés dans la langue de la page. |
| `context-box` | page cas, section Chiliz | Placé après le titre du cas et avant « En bref » dans le HTML (FR-5), quel que soit l'endroit où la grille l'affiche. Titre au niveau des rubriques, sans numéro, hors sommaire. |
| `summary-box` | page cas, section Chiliz | Toujours déplié, jamais tronqué. Titre au niveau des rubriques, sans numéro, hors sommaire. |
| `note-block` | À propos, encart thématique | Aucun comportement propre. |
| `cv-links` | pied de page, À propos | Rendu seulement si les deux PDF existent et ont passé le contrôle C21 (voir « State Patterns »). Aucun lien vers un fichier absent. |
| `toc` | page cas, page Chiliz | `nav` étiquetée « Sommaire ». Sous md : `<details>` fermé à chaque chargement ; ouvert par clic, Entrée ou Espace sur son résumé ; il reste ouvert après avoir suivi un lien. Dès md : liste visible dans la marge. Ne liste que les rubriques et sections publiées. |
| `rubric-heading` | page cas, page Chiliz | Porte l'identifiant d'ancre. Le numéro « 02.3 » est écrit dans le HTML par le hook de titres et masqué aux lecteurs d'écran (`aria-hidden="true"`) : le titre est lu sans chiffre. |
| `live-material-slot` | cas complet | « Prêt » : rendu selon son type (AD-6). « Prévu » : rien en production ; en rendu de travail, un bloc qui nomme le type, l'identifiant et la description. Le texte du cas se lit sans l'élément (FR-12). |
| `site-footer` | toutes les pages | Liens en liste. Le lien « Code source du site » mène au dépôt GitHub. |
| `legal-list` | mentions légales | Valeurs injectées au build (AD-9). Aucune valeur n'est un lien, sauf le contact de l'éditeur (`mailto:`) si la valeur injectée est une adresse mail. |

## State Patterns

| État | Surface | Traitement |
|---|---|---|
| Poste sans cas publié | accueil | Le poste s'affiche normalement (société, rôle, période, lieu, cadre, via), puis plus rien : pas de zone de cas, pas de barre de révision, pas de tiret, pas de mention d'absence (décision confirmée par Arnaud le 13/09/2026, FR-2). |
| Poste dont tous les cas sont en brouillon | accueil, production | Comme un poste sans cas. |
| Cas en brouillon | production | Absent partout : aucune page, aucun lien, aucune entrée de sommaire, aucune section (FR-26). |
| Cas en brouillon | rendu de travail | Affiché, lié depuis son poste ; un marqueur `label` « Brouillon » précède le titre du cas. |
| Page Chiliz avec la seule section 02 | page Chiliz | Page complète : titre, sommaire du seul cas 02, section 02. Aucun emplacement, aucune mention des cas 03 et 04 (FR-9). |
| Cas 03 ou 04 publié plus tard | page Chiliz, accueil | La section s'insère à sa place (`order`), le sommaire gagne une entrée, le poste Chiliz gagne un lien. Les numéros « 02.x » ne changent pas. |
| Page de groupe sans cas publié | production | N'existe pas : le contrôle de mise en ligne C15 bloque. |
| CV PDF absents (socle) | pied de page, À propos | Rien n'est rendu : pas de ligne dans le pied de page, pas de bloc sur À propos, aucun lien cassé. Le socle sort ainsi (décision d'Arnaud, 13/09/2026). |
| Un seul des deux PDF valide | pied de page, À propos | Aucun lien, comme si les deux manquaient : les deux CV sont publiés ensemble ou pas du tout, pour la parité FR/EN (décidé par Arnaud le 13/09/2026). |
| PDF présent mais refusé par C21 | build | Le contrôle échoue et bloque la mise en ligne. Aucun PDF refusé n'est jamais servi. |
| Matériel « prévu » | production | Rien : ni cadre, ni espace, ni commentaire HTML (AD-6). |
| Matériel « prévu » | rendu de travail | Bloc en pointillés : type, identifiant, description. |
| Schéma « prêt », écran étroit | page cas | Si le schéma dépasse 480 px de large : défilement horizontal dans son cadre, qui peut prendre le focus au clavier et qui a un nom accessible, plus le lien « Ouvrir en taille réelle ». La page elle-même ne défile pas horizontalement. |
| Schéma « prêt », mode sombre | page cas | Cible : le SVG passe en thème sombre avec la page. Repli : planche claire encadrée (voir `DESIGN.md`). |
| Vidéo « prête » | page cas | Un lien vers YouTube, rien d'autre (FR-14). |
| Ancre inexistante | toute page | La page s'ouvre en haut. En production, les liens internes et les ancres sont vérifiés par C12 : l'état ne vient que d'un lien externe périmé. |
| URL inconnue | nginx | 404 dans la langue du préfixe (`/en/` → 404 anglaise) : titre, une phrase, lien vers l'accueil de la langue, lien vers l'autre accueil. |
| Valeur légale manquante | build de production | Le build échoue (AD-9) : la page n'est jamais servie vide. |
| Valeurs légales factices | rendu de travail, build de contrôle | La page affiche `VALEUR-FACTICE-…` telles quelles ; C15 interdit ces valeurs à la mise en ligne. |
| Mode sombre | toutes | Suit la préférence du système au chargement et à chaque changement, sans rechargement ni bouton. |
| Texte agrandi à 200 %, largeur 320 px | toutes | Une colonne, aucun défilement horizontal de page ; l'en-tête passe sur deux lignes. |

## Interaction Primitives

- **Cliquer ou toucher un lien** : c'est la seule interaction de l'interface, avec l'ouverture du `<details>` du sommaire sur mobile.
- **Suivre une ancre** : saut direct, sans défilement animé (`scroll-behavior` reste `auto`). La cible est marquée par `:target` (voir `DESIGN.md.rubric-heading`).
- **Revenir** : le bouton retour du navigateur ramène à la position précédente ; le lien « Retour au parcours » ramène au poste sur l'accueil.
- **Défiler horizontalement** : uniquement dans un schéma large ou un extrait, jamais sur la page.
- **Survol** : épaississement du soulignement, rien d'autre. Aucune information n'est réservée au survol.
- **Imprimer** : aucun engagement en v1 ; le document reste lisible par l'impression native du navigateur.
- **Interdits partout** : JavaScript (hors JSON-LD), menu repliable, en-tête collant, carrousel, onglets, fenêtre modale, bascule de thème, bascule de langue par détection, bandeau de cookies, iframe, animation, ouverture dans un nouvel onglet, formulaire.

## Accessibility Floor

Comportement. Les contrastes sont dans `DESIGN.md.Colors`. Cible : WCAG 2.2 AA en mode clair et en mode sombre (NFR-4). La vérification suit AD-17 : contrôles automatiques C11, puis check-list manuelle par gabarit.

- **Langue** : `<html lang>` par page ; `lang` et `hreflang` sur le sélecteur et sur le lien du CV de l'autre langue (3.1.2).
- **Repères** : `header`, `nav` (« Navigation principale », « Sommaire »), `main`, `footer`. Dans une page de groupe, une `section` par cas, étiquetée par son titre.
- **Plan des titres**, un seul `h1` par page et aucun saut de niveau :

  | Page | h1 | h2 | h3 |
  |---|---|---|---|
  | Accueil | ligne d'identité | Parcours, En parallèle, Formation…, Contact | société ; nature (formation, certification, langues) |
  | Page cas seul | titre du cas | Contexte mission, En bref, rubriques | titres libres du cas |
  | Page Chiliz | Chiliz | titre de chaque cas | Contexte mission, En bref, rubriques |
  | Pages simples, 404 | titre de page | sections | — |

- **Ordre de lecture** = ordre du DOM = ordre visuel sur mobile. Dès lg, « Contexte mission » se place visuellement en marge, mais reste avant « En bref » dans le DOM (FR-5) ; la grille ne réordonne rien (1.3.2, 2.4.3).
- **Clavier** : tout est atteignable à la tabulation, dans l'ordre de lecture ; pas de `tabindex` positif. Les conteneurs défilants (schéma large, extrait) prennent le focus (`tabindex="0"`), ont un nom accessible, et défilent aux flèches.
- **Focus** : toujours visible (2.4.7) et jamais masqué (2.4.11) ; le sommaire collant reste dans sa marge et ne couvre jamais le texte.
- **Cibles** : 24 × 24 px au moins pour les liens hors texte courant (en-tête, pied de page, sommaire, liens de cas, sélecteur, résumé du `<details>`) (2.5.8).
- **Liens** : soulignés (1.4.1) ; leur texte suffit à comprendre la destination (2.4.4), sans « cliquez ici ». Les liens de CV nomment la langue, le format et la taille.
- **Images** : la photo a un `alt` dans la langue de la page ; un schéma a pour `alt` la `description` de l'élément dans la langue de la page (FR-13, AD-6) ; aucune image décorative.
- **Numéros décoratifs** : les numéros de rubrique sont `aria-hidden`. Le numéro de cas « Cas 02 » reste lu : c'est l'identifiant que citent le parcours et les échanges.
- **Adaptation** : reflow à 320 px (1.4.10), zoom texte à 200 % (1.4.4), espacement du texte forcé par l'utilisateur sans perte (1.4.12) : aucune hauteur fixe sur un bloc de texte.
- **Couleurs forcées** (`forced-colors: active`) : barre de révision, filets d'encart et focus restent visibles (bordures et contours, jamais des fonds seuls).
- **Préférence de mouvement** : sans objet, il n'y a aucune animation.
- **Langue des fragments** : un terme anglais conservé dans une page FR (« owner », « staker ») n'est pas balisé ; le nom de la marque « Ton Pote le Geek » dans une page EN porte `lang="fr"`.

## Responsive & Platform

Points de rupture et grilles dans `DESIGN.md.Layout & Spacing` (`{spacing.bp-md}` 48 rem, `{spacing.bp-lg}` 80 rem).

| Largeur | Accueil | Page cas / Chiliz | Pages simples |
|---|---|---|---|
| sm (< 48 rem) | une colonne ; photo à droite du nom ; période au-dessus de la société | une colonne ; sommaire replié ; « Contexte mission » en encart sous le titre | une colonne |
| md (48–80 rem) | marge (photo, périodes) + texte | marge (numéro de cas, sommaire collant, numéros de rubrique) + texte | marge (termes de Contact et des mentions légales) + texte |
| lg (≥ 80 rem) | cadre commun ; colonne de note vide | marge + texte + « Contexte mission » en note | cadre commun ; colonne de note vide |

Navigateurs visés : les deux dernières versions de Safari (iOS et macOS), Chrome, Firefox et Edge. Les propriétés récentes (`text-wrap`, `::details-content`) sont des améliorations dont l'absence ne casse rien.

## Premier écran par page

Référence : 390 × 844 px sans défilement (FR-37 pour l'accueil). Sur les autres pages, c'est un objectif de conception vérifié par la check-list manuelle d'AD-17. À vérifier avec Charter (iOS) et avec une serif large de repli (Noto Serif ou DejaVu Serif).

| Page | Visible sans défiler sur 390 × 844 | Visible sur 1 440 × 900 |
|---|---|---|
| Accueil | en-tête d'une ligne ; ligne d'identité et photo ; titre du site ; « Basé en France » ; pitch complet ; « Parcours » ; premier poste (période, société, rôle) ; « Cas 02 » et le titre du premier cas en lien | identité complète, pitch, premier poste et ses cas |
| Page Chiliz | en-tête ; retour au parcours ; « Chiliz » ; sommaire replié ; « Cas 02 » et titre ; « Contexte mission » complet ; début de « En bref » | titre, sommaire en marge, titre du cas 02, « En bref » complet, « Contexte mission » en note, début de « Contexte » |
| Arrivée sur `#case-02` | titre du cas 02 en haut de fenêtre ; « Contexte mission » ; début de « En bref » | titre, « En bref », « Contexte mission » en note |
| Page cas seul | en-tête ; retour au parcours ; « Cas 05 » ; titre ; sommaire replié ; « Contexte mission » ; début de « En bref » | idem page Chiliz, sans « Chiliz » |
| À propos | titre ; portrait 120 × 150 (si retenu) ; bloc CV (si publié) ; début du texte | titre, portrait en marge, bloc CV, premiers paragraphes |
| Contact | titre ; introduction ; adresse mail ; LinkedIn | idem |
| Mentions légales | titre ; bloc Éditeur | les trois blocs |
| Confidentialité | titre ; début du texte | idem |
| 404 | titre ; phrase ; deux liens | idem |

Le retrait de l'en-tête des liens de CV (44 px au lieu de 69 px dans la maquette) et l'absence d'« En bref » sous les cas de l'accueil libèrent environ 150 px par rapport à la maquette du tour 2, qui tenait déjà le critère.

## Inspiration & Anti-patterns

- **Repris des RFC et des ADR** : la barre de révision dans la marge, la note de marge (« Contexte mission »), les sections numérotées, le sommaire en marge, les métadonnées en chasse fixe.
- **Repris d'un CV papier** : le registre des postes, du plus récent au plus ancien, avec la période dans la marge.
- **Écarté : le portfolio « agence »** (bandeau plein écran, grille de cartes, jauges de compétences, logos de clients) : il vend l'emballage, pas le jugement (NFR-6).
- **Écarté : les cas en vitrine séparée du CV** : remplacés par les cas attachés à leur poste (PRD §11.1).
- **Écarté : les espaces réservés** (« En bref à venir », cas grisés, « aucun cas ») : ils montrent ce qui manque au lieu de ce qui existe.
- **Écarté : l'en-tête chargé** (liens de CV dans la navigation) : trop lourd sur mobile.
- **Écarté : la bascule de thème et la détection de langue** : elles demandent du JavaScript ou une redirection que le PRD exclut.
- **Écarté : le lecteur vidéo intégré** : cookies tiers et bandeau de consentement (FR-14).

## Key Flows

### Flow 1 — Claire, CTO, sur son téléphone entre deux réunions (UJ-1)

1. Claire ouvre le lien reçu avec une candidature. L'accueil FR se charge (texte, une CSS, une photo), dans le mode sombre de son téléphone.
2. Sans défiler, elle lit « Arnaud Grousset · Eleyone », « Backend senior PHP/Symfony · Architecture & fiabilisation », « Basé en France » et le pitch.
3. Sous « Parcours », elle voit le poste Chiliz, sa barre de révision verte, « Cas 02 » et le titre « Faire d'une application la source de vérité d'un calcul financier ».
4. Elle touche le titre. `/cas/chiliz/#case-02` s'ouvre sur le titre du cas.
5. « Contexte mission » lui donne la société, le cadre (Salarié), le rôle, la période (septembre 2025 – février 2026) et la stack. « En bref » lui donne l'enjeu, puis le résultat.
6. Elle ouvre le sommaire replié et touche « 02.3 Ce que j'ai décidé ». La rubrique s'affiche en haut de l'écran, marquée par le filet vert.
7. **Climax** : en trois touchers depuis le lien, elle lit la décision et ce qui a résisté. Elle tient sa preuve, et le poste d'où elle vient est toujours à un lien.
8. Elle touche « Retour au parcours », qui la ramène au poste Chiliz. En bas de page, le pied de page propose « CV en PDF, français » ; l'appel à contact mène à la page Contact.

**Échec, socle sans CV PDF** : le pied de page n'a pas de ligne de CV. Claire ne voit ni lien cassé ni mention d'absence, et passe par Contact.
**Cas limite, cas non abouti** (après publication du cas 03) : la section 03 de la même page dit, dans « En bref » et « Résultat », que le sujet n'est pas allé en production (FR-10).

### Flow 2 — Daniel, recruteur pour une entreprise étrangère, lit en anglais (UJ-2)

1. Daniel reçoit le lien racine et arrive sur l'accueil FR, sans redirection (FR-21).
2. Le dernier lien de l'en-tête dit « English ». Il le suit et arrive sur `/en/`, en haut de page.
3. Il lit l'identité, *Based in France* et le pitch anglais, puis parcourt *Experience* sur son ordinateur : les périodes dans la marge, les postes dans la colonne de texte.
4. Sous le poste April Technologies (2017, via Modis), il suit le lien *Case 06* (une fois ce cas publié).
5. **Climax** : la page cas anglaise explique en une ligne ce qu'est April Technologies. Les chiffres, la stack et l'encart *Engagement context* sont les mêmes qu'en français. Il n'a jamais eu besoin du français.
6. Dans le pied de page, il suit *CV (PDF, English, NNN KB)*.

**Échec, lien partagé vers une page FR profonde** : sur `/cas/chiliz/`, « English » mène à `/en/cases/chiliz/` (la page équivalente), pas à l'accueil anglais. S'il était déjà descendu dans la section, il remonte en haut de la page anglaise : il faut refaire le défilement, c'est la limite assumée d'un site sans JavaScript.
**Variante, recruteuse française** : même parcours sans le changement de langue ; elle trouve le CV français en premier dans le pied de page.

### Flow 3 — Sam, tech lead, vérifie comment le site est construit (UJ-3)

1. Sam lit une page cas sur son ordinateur. Il en vérifie la sobriété : aucune requête tierce, pas de bandeau, pas de JavaScript.
2. Dans le pied de page, il suit « Code source du site », qui mène au dépôt GitHub dans le même onglet.
3. Le README se lit comme un cas. Il ouvre les artefacts de cadrage, dont ce document, et les exécutions publiques des contrôles.
4. **Climax** : ce qu'il vient de voir sur le site (pas de liste de cas, liens de CV absents tant que les fichiers ne sont pas validés, matériel prévu invisible) est écrit ici comme une décision et vérifié par un contrôle. Le site et son cadrage disent la même chose.

**Échec, dépôt public pas encore en ligne** : l'URL est un contenu à fournir (FR-29). Tant qu'elle manque, le lien n'est pas rendu, comme les CV PDF, et n'est jamais un `#`.

### Flow 4 — Arnaud relit le cas pilote dans le rendu de travail (UJ-4, partie visible)

1. Arnaud lance `scripts/dev.sh` et ouvre l'accueil local.
2. Le poste Chiliz (brouillon) montre le cas 02, marqué « Brouillon ».
3. Sur la page Chiliz, les trois éléments « prévus » du cas 02 apparaissent en blocs pointillés à leur emplacement, avec leur description.
4. **Climax** : il voit exactement où chaque schéma, extrait et encart prendra place. Il vérifie aussi que le texte se lit sans eux, puisque la production n'en montrera rien.

**Échec** : un identifiant placé mais non déclaré fait échouer le build (AD-6), avant toute relecture visuelle.

## Test des trente secondes (proposition pour la question 14)

Proposition de méthode pour SM-1 [à valider par Arnaud]. Qualitative, sans outil ni analytics.

- **Quand** : une fois sur le site de répétition, par partage d'écran depuis le poste d'Arnaud (le canal de répétition n'est pas public, AD-22), puis une fois après la mise en ligne du socle, sur le téléphone du testeur.
- **Qui** : cinq personnes qui ne connaissent pas le parcours d'Arnaud dans le détail. Au moins un CTO ou tech lead, un recruteur tech qui lit en français, et un lecteur qui teste la version anglaise.
- **Déroulé** :
  1. Le testeur reçoit l'URL de l'accueil dans sa langue, comme un lien de candidature. Aucune consigne sur le site.
  2. Trente secondes chronométrées, défilement libre, puis écran masqué.
  3. Trois questions ouvertes, notées mot pour mot :
     - « Qui est cette personne, et à quel niveau ? »
     - « Qu'est-ce qu'elle fait bien ? »
     - « Où iriez-vous pour le vérifier ? »
  4. Écran rendu : « Montrez-moi une preuve. » On compte les touchers ou clics jusqu'à une section de cas.
- **Réussite pour un testeur** :
  - il nomme le métier (backend PHP/Symfony) et un niveau senior ;
  - il cite au moins une idée du titre du site ou du pitch (architecture, fiabilisation, jugement) ;
  - il désigne un cas ou un poste avec cas ;
  - il atteint une section de cas en un toucher depuis l'accueil (SM-3).
- **Seuil proposé** : quatre testeurs sur cinq. En dessous, on retouche le titre, le pitch ou le premier poste, puis on refait le test (le critère mobile FR-37 est revérifié à chaque retouche).
- **Trace** : une note par passage dans `docs/measures/`, avec le rôle du testeur, sa langue, son appareil, ses réponses résumées et le verdict. Aucun nom, aucune donnée personnelle : le fichier est public.

## Décisions validées par Arnaud (13/09/2026)

1. Pas d'« En bref » sous les cas de l'accueil : numéro et titre seulement.
2. Numéros : aucun sur l'accueil ; numérotation par cas sur les pages cas (« 02.3 »).
3. Sommaire replié dans un `<details>` sur mobile, visible en marge dès 48 rem.
4. Libellés « Parcours » / *Experience*, « En parallèle » / *Alongside*, « Formation, certification, langues », « Cas 02 », sélecteur « English » / « Français ».
5. CV PDF publiés ensemble ou pas du tout.
6. Lien « Retour au parcours » vers le poste du cas sur l'accueil (ancre `#position-<id>`).
7. Encre des schémas D2 alignée sur le texte du site.
8. SVG D2 à double thème, sous réserve d'un spike (`<img>`, déterminisme octet par octet, ≤ 60 Ko) ; repli : planche claire encadrée ; schéma large dans un cadre qui défile horizontalement, avec « Ouvrir en taille réelle ».
9. Typographie française appliquée au rendu des pages FR.
10. Corps d'un poste affiché seulement quand il n'a aucun cas.
11. Même cadre de 77,5 rem sur toutes les pages larges.
12. Portrait aussi sur la page À propos (160 × 200 et 320 × 400).

Le statut des deux documents reste `draft` jusqu'à leur relecture complète par Arnaud.

## Points encore à valider par Arnaud

1. Libellés restés « à valider » dans « Voice and Tone » (dont le libellé et le poids affichés des liens de CV).
2. Méthode du test des trente secondes (question 14).
3. Marqueur « Brouillon » dans le rendu de travail.

## Impacts sur l'architecture

À reporter dans `ARCHITECTURE-SPINE.md` (ou dans les stories de gabarits), après validation.

| # | Sujet | Impact | AD touchés |
|---|---|---|---|
| I-1 | CV PDF conditionnels | La décision d'Arnaud rend les liens conditionnels : le gabarit teste l'existence des deux fichiers de `static/cv/` et lit leur taille au build. C21 doit passer de « les deux fichiers existent, partout » à « aucun fichier, ou les deux et valides » ; C12 ne doit plus attendre les liens de CV dans le pied de page quand ils sont absents ; `ci/release-pages.txt` n'inclut pas les PDF pour le socle. Cela tranche la question 16 du PRD. | AD-21, AD-10 (C12, C15, C21) |
| I-2 | Lien du dépôt public conditionnel | Même traitement tant que l'URL n'est pas fournie : pas de lien plutôt qu'un lien factice. | AD-3, C12 |
| I-3 | Schémas en mode sombre | Cible : `dark-theme-id` et `dark-theme-overrides` dans `diagrams/theme.d2`, donc un SVG unique par langue qui embarque les deux thèmes. À vérifier par un spike : le rendu de `prefers-color-scheme` dans un SVG chargé par `<img>` (Safari, Firefox, Chrome), le déterminisme octet par octet (C9), le poids (≤ 60 Ko). Sort le « thème sombre des schémas D2 » de la section « Reporté ». Repli sans impact : planche claire encadrée. | AD-7, AD-8, « Reporté » |
| I-4 | Schéma large | Le shortcode `live-material` pose une classe et un attribut `width` à 75 % de la largeur intrinsèque quand celle-ci dépasse 480 px, enveloppe l'image d'un conteneur focalisable étiqueté, et ajoute le lien « Ouvrir en taille réelle » vers le SVG empreinté. Pas de `style` en ligne (CSP). | AD-6, AD-13 |
| I-5 | Numéros de rubrique | Le hook `render-heading.html` écrit `<span aria-hidden="true">NN.r</span>` (numéro du cas, rang de la rubrique). Le sommaire se construit à partir des mêmes titres. | AD-4 |
| I-6 | Ancres de postes et retour au parcours | `_partials/position.html` pose `id="<translationKey>"` ; la page cas construit le lien de retour depuis sa clé `position` (format des cas v0.4, validé par Arnaud le 13/09/2026). | AD-18, format v0.4 |
| I-7 | Mentions légales et commune | Décision d'Arnaud : l'adresse déclarée (son domicile) est publiée **seulement** sur la page des mentions légales, par `HUGO_LEGAL_PUBLISHER_ADDRESS`, jamais commitée. Cela tranche la question 17 en admettant cette exception à FR-33 et NFR-9 pour cette seule page. À vérifier : aucune autre sortie ne réutilise cette variable (`<title>`, description, JSON-LD, sitemap), et la commune reste dans la liste des motifs du garde-fou. Option, **non retenue ici** car C15 interdit `noindex` en production : exclure la page des moteurs de recherche. | AD-9, AD-20, C15 |
| I-8 | Typographie française | Un partial appliqué au contenu rendu des pages FR (`replaceRE` hors `pre` et `code`), ou une règle de rédaction contrôlée par script. À trancher ; aucune dépendance ajoutée. | AD-3, AD-10 |
| I-9 | Sommaire | `<details>` natif : aucun JavaScript, aucune exception CSP. Le libellé « Sommaire · N rubriques » demande un comptage par le gabarit. | AD-3, AD-8 |
| I-10 | Marqueur « Brouillon » | Rendu de travail seulement, derrière `hugo.IsProduction`. | AD-5 |
| I-11 | Portrait recadré | `scripts/photo/prepare.sh` recadre en 4:5 sur le visage et les épaules (copie commitée de 640 × 800, ancrage choisi et vérifié à l'œil) au lieu du simple redimensionnement 800 × 800 d'AD-19. `_partials/portrait.html` reçoit la taille voulue : variantes 120 × 150 et 240 × 300 pour l'accueil, plus 160 × 200 et 320 × 400 si la version À propos est retenue. C20 vérifie chaque variante (≤ 40 Ko) et le ratio 4:5. | AD-19, C20 |
