# pattern-agent

**Kit de gouvernance pour agents IA** : les règles que tout LLM (Claude, Codex, Gemini, Copilot, Cursor…) doit respecter dans mes projets, et les garde-fous automatiques qui les font appliquer.

Ce dépôt est un modèle. On le copie dans un projet, on remplit les champs propres au projet, et la même « loi » s'applique partout.

## Le problème

- Chaque outil IA a son fichier d'instructions (`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`…). Maintenus à la main, ils finissent par diverger.
- Une consigne écrite reste une demande : le modèle la suit souvent, pas toujours.

## La solution : deux couches

| Couche | Rôle | Garantie |
|--------|------|----------|
| **Instructions** (`AGENTS.md`, `docs/`) | Expliquer le projet, ses conventions et quoi faire à chaque modification | Le modèle les suit souvent, pas toujours |
| **Garde-fous** (scripts, hooks, CI) | Imposer ce qui doit être respecté à coup sûr | Exécutés par un outil, indépendamment du modèle |

Principe : une règle critique ne dépend jamais seulement de la bonne volonté du LLM.

## Contenu

```
pattern-agent/
├── AGENTS.md                        # LA source unique d'instructions, lue par tous les agents
├── CLAUDE.md                        # Renvoi : @AGENTS.md (Claude Code)
├── .gemini/settings.json            # Renvoi : Gemini CLI lit AGENTS.md
├── .github/
│   ├── copilot-instructions.md      # Renvoi : Copilot lit AGENTS.md
│   ├── pull_request_template.md     # Definition of Done pour les PR
│   └── workflows/governance.yml     # CI : lance scripts/check.sh
├── docs/
│   ├── architecture.md              # Architecture du projet (lue à la demande)
│   ├── testing.md                   # Carte « zone modifiée → tests à lancer »
│   ├── governance.md                # Fonctionnement détaillé de la gouvernance
│   └── adr/                         # Décisions d'architecture et leur « pourquoi »
├── scripts/
│   ├── check.sh                     # Commande UNIQUE de vérification
│   ├── governance-lint.sh           # Vérifie que la gouvernance est intègre
│   ├── install.sh                   # Installe ou met à jour le kit dans un projet
│   └── hooks/                       # Hooks Claude Code
├── tests/selftest.sh                # Auto-test du kit (propre à ce dépôt)
├── .agents/protected-paths          # Chemins interdits aux agents (secrets, garde-fous)
├── .claude/settings.json            # Active les hooks Claude Code
└── .githooks/pre-commit             # Bloque un commit si la vérification échoue
```

### `AGENTS.md`, la loi

C'est le fichier lu à chaque prompt. Il reste court (moins de 200 lignes) et contient :

1. **Projet** : à quoi il sert, sa stack (à remplir).
2. **Commandes** : comment vérifier, lancer, installer (à remplir).
3. **Règles propres au projet** (à remplir).
4. **Loi commune**, identique dans tous les projets :
   - avant de modifier : lire le contexte, demander en cas de doute ;
   - à chaque modification : trouver les tests concernés, les mettre à jour, lancer `sh scripts/check.sh`, mettre la doc à jour, écrire un ADR si la décision est structurante ;
   - Definition of Done ;
   - interdits : affaiblir un test, contourner un garde-fou, toucher un chemin protégé, inventer un résultat… ;
   - résumé de fin de tâche obligatoire.

Le détail (architecture, carte des tests, décisions) est dans `docs/` et n'est lu que lorsqu'il est utile. Un `AGENTS.md` placé dans un sous-dossier complète celui de la racine pour cette zone.

### Les garde-fous

| Garde-fou | Quand | Effet |
|-----------|-------|-------|
| `scripts/check.sh` | À la demande | Lint de gouvernance et étapes du projet (lint, types, tests). Mode `--quick` pour aller vite |
| Hook `guard-protected.sh` | Avant chaque écriture de Claude | Refuse l'écriture dans un chemin de `.agents/protected-paths` |
| Hook `post-edit.sh` | Après chaque écriture de Claude | Lance `check.sh --quick` ; en cas d'échec, Claude reçoit l'erreur |
| Hook `stop-check.sh` | Quand Claude veut terminer | Lance `check.sh` ; en cas d'échec, Claude doit continuer |
| `.githooks/pre-commit` | À chaque commit | Bloque le commit si `check.sh --quick` échoue |
| CI GitHub Actions | À chaque push et PR | Lance `check.sh` complet : dernier rempart, indépendant de l'agent et de la machine |

Les hooks d'édition n'existent que dans Claude Code. Pour les autres outils, le filet est le hook git et la CI.

## Compatibilité

| Outil | Comment il lit la loi |
|-------|----------------------|
| Codex, Cursor, Windsurf, Zed, Aider… | `AGENTS.md` directement |
| Claude Code | `CLAUDE.md` importe `AGENTS.md` |
| Gemini CLI | `.gemini/settings.json` pointe vers `AGENTS.md` |
| GitHub Copilot | `AGENTS.md`, et `.github/copilot-instructions.md` y renvoie |
| ChatGPT, Claude.ai, Gemini (web) | Pas d'accès au dépôt : coller `AGENTS.md` dans les instructions du projet |

## Utilisation

### Prérequis

Un shell POSIX `sh` dans le PATH. Linux et macOS l'ont déjà. Sous Windows, installe [Git for Windows](https://git-scm.com/downloads/win) : sans lui, Claude Code ne trouve pas `sh`, et comme les hooks échouent en mode bloquant, plus aucune écriture n'est possible.

### Nouveau projet

Sur GitHub, clique sur **Use this template**, puis :

1. Remplis les champs `<À REMPLIR>` de `AGENTS.md` et de `docs/architecture.md`.
2. Remplace les exemples de `docs/testing.md` par les zones réelles du projet.
3. Ajoute les étapes du projet (lint, tests…) dans `scripts/check.sh`.
4. Active le hook git : `git config core.hooksPath .githooks`.
5. Supprime `tests/selftest.sh` et `.github/workflows/selftest.yml`, propres à ce dépôt.
6. Vérifie : `sh scripts/check.sh`.

### Projet existant

Depuis un clone de ce dépôt :

```bash
sh scripts/install.sh ../mon-projet
```

Le script copie ce qui manque, n'écrase aucun fichier existant et active le hook git.

### Mettre à jour la loi dans un projet

Quand la loi commune évolue ici :

```bash
sh scripts/install.sh ../mon-projet --update
```

Seuls le bloc `LOI` de `AGENTS.md` et les fichiers gérés (lint, hooks, `docs/governance.md`) sont remplacés. Les sections propres au projet ne sont pas touchées.

## Faire évoluer la loi

- Quand un agent répète une erreur, ajoute une règle précise : en section 3 si elle est propre au projet, ici si elle est universelle.
- Écris des consignes impératives et vérifiables, avec la commande exacte.
- N'écris pas ce qu'un linter ou un formatter impose déjà.
- Si une règle est souvent ignorée, outille-la (script, hook, CI) plutôt que de la répéter.
- Supprime les règles devenues inutiles.

Détails : [`docs/governance.md`](docs/governance.md). Décision fondatrice : [`docs/adr/0001-gouvernance-agents.md`](docs/adr/0001-gouvernance-agents.md).

> **Note pour ce dépôt** : `.agents/protected-paths` protège aussi les hooks et `.claude/settings.json`. Pour faire évoluer ces fichiers ici, modifie-les toi-même : la loi ne s'auto-modifie pas.