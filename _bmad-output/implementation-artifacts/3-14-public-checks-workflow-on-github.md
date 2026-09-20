# Story 3.14 : Public checks workflow on GitHub

Status: done

Spec : `_bmad-output/planning-artifacts/epics.md`, story 3.14.

## Revue de spec

### 20/09/2026 — `gemini-3.1-pro-high`, `bmad-review` (angles : adversarial, structure, prose), `dev` à `8f973e7`

Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 94f2374852edf3485021d2d2

### Rapport de Revue (BMAD)

**Document :** `REVIEW-SPEC.md` (Story 3.14 : Public checks workflow on GitHub)
**Classe :** Document définissant un comportement (`docs`)
**Objectif identifié :** Mettre en place la CI publique sur le miroir GitHub afin d'y exécuter les contrôles de parité, de chemins et de schémas, de manière sécurisée (sans fuite).
**Lecteurs cibles :** Humain (Arnaud) et LLM (Agent développeur)

---

#### 1. Revue Adversariale (`adversarial`)

*Méthode : recherche des angles morts, des effets de bord ignorés et des cas d'erreur possibles selon l'architecture (AD-11, AD-12) et l'environnement cible (GitHub Actions).*

1. **C21 et absence de liste de motifs :** Le critère exige que « C21 y tourne sans liste de motifs ». Selon l'AD-21, le contrôle C21 inspecte le texte des PDF pour y trouver des données privées en s'appuyant sur les motifs interdits. S'il s'exécute sans cette liste, va-t-il échouer brutalement, passer silencieusement, ou lever un avertissement visible ? Son comportement doit être défini pour ne pas faire échouer le pipeline public.
2. **Déclenchement sur toutes les branches (`push`) :** Le workflow se déclenche sur `push`. Sauf restriction (`branches: [dev, main]`), il s'exécutera sur chaque branche poussée par le miroir, ce qui peut générer du bruit inutile et consommer le quota GitHub Actions.
3. **Risque de Rate Limit (Docker Hub) :** Le script `checks-job.sh` fait un `docker run` de `CHECK_IMAGE` (`alpine:3.24`). Sur les runners publics GitHub non authentifiés, le tirage (pull) d'une image Docker Hub est soumis à des quotas stricts ("Too Many Requests"). Ce risque d'échec aléatoire de la CI n'est ni documenté ni géré par la spec.
4. **Absence de l'étape de Checkout :** Le critère mentionne l'appel du script mais oublie l'étape de récupération du code. D'après l'AD-11, le dépôt doit être récupéré avec `fetch-depth: 0` (historique complet requis par le garde-fou). 
5. **Privilèges du workflow (`GITHUB_TOKEN`) :** Il s'agit d'un dépôt public synchronisé par un miroir. Les bonnes pratiques exigent de réduire la surface d'attaque en forçant les permissions au strict minimum dans le fichier yaml (`permissions: contents: read`), ce que la spec omet de préciser.
6. **Vérification du comportement de Gitea :** La spec dit « Gitea n'exécute pas `.github/workflows/` ». Pour que cela soit vrai (selon AD-11), il faut s'assurer que `.gitea/workflows/` existe déjà. La dépendance à une autre story garantissant sa présence devrait être explicite.
7. **Épinglage imprécis des actions tierces :** Le critère demande des actions "épinglées par SHA". Pour ne laisser aucune ambiguïté au développeur, il faudrait préciser quelles actions tierces sont autorisées (probablement uniquement `actions/checkout@<SHA>`).
8. **Trace du garde-fou en mode historique :** Le garde-fou `history` se rabat sur le mode "chemins seulement" s'il n'a pas le fichier de motifs, mais émet un avertissement (AD-12). La spec ne dit pas si la présence de cet avertissement public dans les logs GitHub est acceptable ou s'il faut le masquer.
9. **Garantie d'absence de secrets dans les logs :** La spec impose que "le journal public ne contient ni secret ni motif privé". En cas de plantage d'un script bash (ex: `set -x`), les variables factices injectées par `ci/legal-placeholder.env` pourraient fuiter. Même si elles sont factices, est-ce que cela passe le critère ? 
10. **Synchronisation de l'opération manuelle :** L'activation manuelle des GitHub Actions doit-elle être faite *avant* le merge de la PR ou *après* ? Si le miroir pousse avant l'activation, le premier contrôle public ne sera pas déclenché.

---

#### 2. Revue de Structure (`structure`) et Prose (`prose`)

**Modèle de structure :** Spécification BDD (User Story + Étant donné / Quand / Alors)
**Réduction estimée :** ~10 mots, sans perte de compréhension.

| Pass | Texte original | Texte révisé | Raison |
|---|---|---|---|
| structure | `- [ ] Le journal public ne contient ni secret ni motif privé ; C21 y tourne sans liste de motifs.` | **FUSIONNER** dans un bloc BDD :<br>« **Alors** le journal public ne contient ni secret ni motif privé... » | Une case à cocher isolée en fin de document casse le flux logique des critères d'acceptation BDD. |
| structure | `appelle checks-job.sh depuis la machine virtuelle (pas de conteneur de job), sans secret ni docker build, avec des actions tierces épinglées par SHA.` | **SÉPARER** en deux contraintes distinctes : l'exécution (`appelle checks-job.sh sur l'hôte`) et les contraintes d'environnement (`sans secret... avec des actions...`). | Le "Alors" est trop dense. Séparer le "comment ça s'exécute" du "ce qui est interdit" facilite le travail du développeur. |
| prose | `afin de vérifier que la parité, les schémas et le garde-fou des chemins sont contrôlés.` | `afin de vérifier publiquement la parité, les schémas et le garde-fou des chemins.` | Plus direct ; la notion de « sont contrôlés » fait doublon avec « vérifier ». |
| prose | `exactement un run a lieu sur Gitea et un sur GitHub` | `un seul run s'exécute sur Gitea, et un seul sur GitHub` | Formulation plus lisible et grammaticalement plus naturelle en français. |
| prose | `(pas de conteneur de job)` | `(en mode hôte)` | Utilisation de la terminologie exacte présente dans le document d'architecture (AD-11). |

---

#### À trancher avant d'implémenter

1. **Comportement de C21** : Que doit faire techniquement le script C21 s'il est lancé sans sa liste de motifs privés ? (Doit-il faire un bypass silencieux, exécuter un repli, ou échouer ?)
2. **Filtre de branches sur GitHub** : Le workflow `checks.yaml` doit-il restreindre son déclenchement à certaines branches spécifiques (`dev`, `main`) ou tourner sur absolument tous les `push` du miroir ?
3. **Permissions du workflow** : Souhaites-tu que le code impose explicitement un bloc `permissions: contents: read` au workflow pour sécuriser le token d'exécution ?
4. **Paramétrage du checkout** : Faut-il mentionner le paramètre `fetch-depth: 0` dans les critères, puisque le garde-fou en mode historique (AD-11) l'exige impérativement ?

### Triage (20/09/2026)

**Retenu — le critère sur C21 était faux.** C21 (texte des PDF, AD-21) n'existe pas : il arrive à l'epic 7, et le hook `pre-receive` refuse `assets/cv/*.pdf` en attendant. Une case qui exige qu'il « tourne sans liste de motifs » ne peut donc être vérifiée aujourd'hui. Elle est remplacée par ce qui est vrai maintenant — le garde-fou tourne en chemins seulement, la CI publique n'a pas de liste de motifs — et l'exigence sur C21 est renvoyée à la story qui l'écrira.

**Retenu — le déclencheur `push` doit nommer ses branches.** Le miroir pousse **toutes** les branches : sans filtre, chaque push d'une branche de travail lancerait un run public. Le workflow n'écoute donc que `dev` et `main`, comme celui de la forge. Les branches de travail sont déjà contrôlées sur Gitea, par `pull_request` ; ce que le dépôt public montre, c'est l'état du tronc (UJ-3). AD-11 disait « sur `push` » sans plus de précision : la décision y est écrite, datée.

**Retenu — le tirage de l'image peut échouer sur un runner public.** `CHECK_IMAGE` vient du Docker Hub, dont les tirages anonymes sont limités par adresse IP ; les runners de GitHub partagent les leurs. Un `429` ferait rougir la CI sans que rien ne soit en cause. `scripts/ci/checks-job.sh` tire donc l'image avant de la lancer, avec trois tentatives espacées, et dit laquelle échoue. La logique vit dans le script, jamais dans le YAML (AD-11).

**Retenu — le checkout et `fetch-depth: 0` sont écrits dans le critère.** Le garde-fou en mode historique lit tout l'historique : sans cela, il n'auditerait qu'un commit.

**Retenu — `permissions: contents: read`.** Le workflow n'écrit rien : il le déclare, plutôt que de dépendre du réglage du dépôt. Une ligne, et la surface du jeton est réduite à la lecture.

**Retenu — l'action tierce autorisée est nommée.** Une seule : `actions/checkout`, épinglée par SHA. Sur GitHub, `uses` ne prend pas d'URL absolue, contrairement à Gitea ; le SHA, lui, est le même des deux côtés (`gitea.com/actions/checkout` est un miroir de `github.com/actions/checkout`), ce qu'un cas de test vérifie.

**Refusé — masquer l'avertissement « chemins seulement » du garde-fou.** Il ne nomme ni motif ni contenu : il dit seulement que l'audit a tourné sans liste, ce qui est exactement ce qu'un lecteur du dépôt public doit savoir. Le masquer donnerait à croire que l'audit public est complet. Le critère l'écrit désormais comme attendu, et non toléré.

**Refusé — se soucier des valeurs légales factices dans le journal public.** Elles sont commitées dans `ci/legal-placeholder.env`, portent toutes `VALEUR-FACTICE`, et `scripts/env.sh` coupe la trace (`set +x`) avant toute lecture. Il n'y a rien à protéger.

**Retenu — l'ordre de l'opération manuelle.** Si les Actions ne sont pas activées sur le dépôt public, aucun run n'a lieu et rien n'échoue : le constat se fait après la fusion, et l'activation est l'affaire d'un réglage. Écrit dans la story.

## Ce qui est livré

- `.github/workflows/checks.yaml` — `push` sur `dev` et `main`, `workflow_dispatch`, `ubuntu-24.04`, `permissions: contents: read`, checkout épinglé par SHA avec `fetch-depth: 0`, puis `bash scripts/ci/checks-job.sh`. Rien d'autre : ni secret, ni construction d'image, ni conteneur de job.
- `scripts/ci/checks-job.sh` — l'image est désormais tirée à part, **et seulement si elle manque**, avec trois tentatives espacées. Les runners publics partagent leurs adresses IP et le registre limite les tirages anonymes : un refus temporaire aurait fait rougir la CI sans que rien ne soit en cause. Quand l'image est déjà là, le registre n'est pas appelé du tout. `CHECKS_JOB_RETRY_DELAY` ne sert qu'aux tests.
- `scripts/tests/test-workflows.sh` — 6 cas de plus, dont un qui vérifie que le checkout est épinglé **au même commit des deux côtés** : `gitea.com/actions/checkout` est un miroir de `github.com/actions/checkout`, et les deux forges lancent donc le même code.
- `scripts/tests/test-checks-job.sh` — 3 cas de plus sur le tirage : image déjà présente (aucun appel au registre), deux refus puis reprise, trois refus et anomalie sans lancer le conteneur.
- `docs/procedures/github-mirror.md` — une section « La CI publique » ; `checks-job.md` et `gitea-actions.md` suivent.

### Une différence entre les deux forges, et une égalité

Gitea accepte une URL absolue dans `uses`, GitHub non : sur le miroir, l'action est nommée puis épinglée. Mais le SHA est le même des deux côtés, et un cas de test garde cette égalité — si l'un monte de version sans l'autre, il échoue.

### Essais

- `scripts/tests/run.sh` : 281 cas réussis.
- `scripts/ci/checks-job.sh` : code 0, avec l'image déjà présente — le registre n'est pas appelé.
- La vérification en conditions réelles — un seul run sur chaque forge après un push sur `dev` — se fait après la fusion, quand le miroir aura publié.

## Revue du code

### 20/09/2026 — `a6246fe` — `gemini-3.1-pro-high` — verdict `pass`

Rapport publié en commentaire de la PR n° 50. Angles : edge-case-hunter, verification-gap, plus la couche propre au projet. Fichiers créés ou modifiés par le relecteur : aucun.

JETON: 1bd9613a477c10bd0489f757

##### Rapport de revue (BMAD)

**Lentilles sélectionnées :** `edge-case-hunter`, `verification-gap`

###### `edge-case-hunter`
Aucun cas limite problématique trouvé. La résilience vis-à-vis des limitations de requêtes du Docker Hub (Rate Limit lié aux runners GitHub publics) est gérée avec robustesse dans le script de CI : le `docker pull` est équipé d'une boucle à 3 essais avec temporisation de repli, traitant avec grâce l'anomalie sans déstabiliser le build.

###### `verification-gap`
Aucune lacune de vérification identifiée. L'ajout du système d'essais pour Docker est soutenu par un environnement de test isolé (mock `faux_docker` très complet) qui valide précisément la présence ou l'absence de l'image locale et les tirages de réseau. L'intégrité de l'action `actions/checkout` (égalité des SHA entre Gitea et GitHub) est validée de manière automatisée.

##### Couche projet

- NON BLOQUANT : Les critères d'acceptation de la story sont satisfaits (le workflow limite intelligemment ses `push` à dev/main, s'exécute sur machine virtuelle pour sécuriser le conteneur, respecte le principe du "sans secret" et déclare des privilèges limités en lecture).
- NON BLOQUANT : Aucune donnée privée, aucun nom d'hôte, aucune adresse de la forge ni aucun secret n'est commité dans les workflows ou le shell ; le log ne laisse filtrer que des avertissements publics documentés et attendus.
- NON BLOQUANT : Les procédures, le skill et le script concordent parfaitement (la documentation décrit fidèlement la limitation des tirages anonymes sur les runners publics et la gestion afférente dans le code).
- NON BLOQUANT : Le changement est cohérent avec AGENTS.md et le document d'architecture (`ARCHITECTURE-SPINE.md`), qui consigne explicitement les décisions d'environnement hôte prises pour GitHub Actions.
- NON BLOQUANT : Dans les scripts shell, aucune erreur ne passe en silence sous `set -euo pipefail` (la structure conditionnelle et arithmétique `((rc != 0)) || return 0` est formellement solide et sécurisée face au mode d'arrêt strict de Bash).

VERDICT: NON BLOQUANT — aucune

## Reporté
