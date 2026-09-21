# Procédure — Préparer la photo

L'original de la photo **ne descend jamais dans le dépôt** (AD-19). Le script le lit là où il est, et n'écrit que la copie contrôlée.

```bash
scripts/photo/prepare.sh ~/photos/portrait-original.jpg Top
```

Il écrit `assets/images/portrait.webp` en 640 × 800, au plus 150 000 octets, sans aucune métadonnée.

Codes de sortie : `0` copie écrite, `1` refus (ancrage inconnu, original introuvable ou dans le dépôt, résultat non conforme), `2` anomalie (usage, Hugo absent).

## L'ancrage se choisit à l'œil

Il est **obligatoire** : `Top`, `Center`, `Bottom`, `Left`, `Right`, `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight`.

`Smart` est refusé par AD-19. Sur un portrait, le cadrage automatique déplace le visage sans prévenir, et son résultat peut changer d'une version de Hugo à l'autre sans que rien ne le signale. Le bon geste est de lancer le script, **de regarder le résultat**, et de rejouer avec un autre ancrage s'il ne convient pas. Rien ne presse : le fichier se réécrit autant de fois qu'il le faut avant le commit.

## Ce que le script garantit avant d'écrire

1. L'original est **hors du dossier du dépôt** — comparaison sur le chemin canonique, donc un lien symbolique posé dedans ne passe pas.
2. Le WebP produit ne porte **aucune** métadonnée. Si Hugo en laissait une, le script refuse d'écrire et le dit : AD-19 repose entièrement sur ce comportement, et une régression doit s'arrêter là, pas être découverte après un commit.
3. Le résultat fait bien 640 × 800 et tient dans le budget.

Le travail se fait dans un mini-projet temporaire, hors du dépôt, supprimé à la sortie : un échec ne laisse jamais de fichier à moitié écrit dans `assets/`.

## Aucun outil d'image n'est installé

AD-19 l'interdit, et le tient : c'est le **Hugo épinglé de `tools.env`** qui recadre, et `grep` et `od` qui relisent le résultat (`scripts/lib/image.sh`). Ni ImageMagick, ni `exiftool`, ni sur le poste, ni en CI, ni sur la forge.

Cette bibliothèque est **copiée sur la forge**, à côté de `check-private.sh` : le hook `pre-receive` refuse une image porteuse de métadonnées **avant publication**, la CI seule arrivant après que le miroir a poussé (`gitea-pre-receive-hook.md`).

## Les variantes publiées

`layouts/_partials/portrait.html` reçoit un emplacement et produit deux variantes empreintées, en `srcset` 1x/2x, depuis la copie commitée :

| Emplacement | 1x | 2x |
|---|---|---|
| `home` | 120 × 150 | 240 × 300 |
| `about` | 160 × 200 | 320 × 400 |

Le partial ne rend **rien** tant que `assets/images/portrait.webp` n'existe pas, ou tant que `portrait_alt` est vide dans `content/_index.<lang>.md` : une photo sans alternative textuelle échouerait à C11, et un emplacement réservé vaut moins que rien.

## Vérifier

```bash
scripts/check.sh                     # C20 parmi les autres contrôles
scripts/checks/images.sh             # C20 seul
```

Pour éprouver le refus, fabriquer un WebP porteur de métadonnées — `scripts/tests/test-images.sh` en écrit un octet par octet, sans aucun outil.

## Pièges déjà rencontrés

- **Hugo reconnaît le format par l'extension du fichier.** Un original copié sous un nom sans point est rejeté comme « format non pris en charge », message qui n'oriente vers rien. Le script reporte l'extension et refuse un original qui n'en a pas.
- **`.Fingerprint` n'existe pas sur une ressource image.** L'empreinte se pose par le tube `| fingerprint`.
- **Une variable shell ne peut pas contenir un blob binaire** : le premier octet nul la tronque, et l'image paraîtrait vide donc propre. Le garde-fou écrit le blob dans un fichier temporaire avant de le lire.
