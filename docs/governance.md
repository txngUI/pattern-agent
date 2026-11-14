# Gouvernance des agents IA

Ce document explique comment la gouvernance fonctionne et comment la faire évoluer.
Il est géré par `pattern-agent` : `scripts/install.sh --update` l'écrase.

## Deux couches

| Couche | Fichiers | Garantie |
|--------|----------|----------|
| **Instructions** : contexte, conventions, checklist | `AGENTS.md`, `docs/*.md`, `AGENTS.md` des sous-dossiers | Le modèle les suit souvent, pas toujours |
| **Garde-fous** : ce qui doit être respecté à coup sûr | `scripts/check.sh`, `.claude/settings.json`, `.githooks/`, `.github/workflows/` | Exécutés par un outil, indépendamment du modèle |

Règle : une contrainte critique ne dépend jamais seulement de la bonne volonté du modèle.
Si une règle de `AGENTS.md` est souvent ignorée, cherche d'abord à l'outiller.

## Qui lit quoi

| Outil | Fichier lu | Mécanisme |
|-------|-----------|-----------|
| Codex (OpenAI), Cursor, Windsurf, Zed, Jules, Aider… | `AGENTS.md` | Lecture native |
| Claude Code | `CLAUDE.md` | La ligne `@AGENTS.md` importe le fichier commun |
| Gemini CLI | `GEMINI.md` par défaut | `.gemini/settings.json` lui fait lire `AGENTS.md` |
| GitHub Copilot | `AGENTS.md` et `.github/copilot-instructions.md` | Le second renvoie au premier |
| ChatGPT, Claude.ai, Gemini (web) | Aucun accès au dépôt | Colle `AGENTS.md` dans les instructions du projet ou de la conversation |

## Les garde-fous

### `scripts/check.sh`
Point d'entrée unique de vérification, utilisé par l'agent, l'humain, les hooks et la CI.
- `sh scripts/check.sh` : complet.
- `sh scripts/check.sh --quick fichier…` : rapide. Les fichiers modifiés sont disponibles dans `$CHECK_FILES`.

Il lance toujours `scripts/governance-lint.sh`, qui vérifie l'intégrité de la gouvernance :
présence et taille de `AGENTS.md`, renvois des fichiers propres à chaque outil, liens vers des
fichiers inexistants, nommage des ADR, champs encore à remplir.

### Hooks Claude Code (`.claude/settings.json`)
| Événement | Script | Effet |
|-----------|--------|-------|
| `PreToolUse` sur une édition | `scripts/hooks/guard-protected.sh` | Bloque l'écriture dans un chemin de `.agents/protected-paths` |
| `PostToolUse` sur une édition | `scripts/hooks/post-edit.sh` | Lance `check.sh --quick` sur le fichier ; en cas d'échec, l'agent reçoit l'erreur |
| `Stop` | `scripts/hooks/stop-check.sh` | Si des fichiers ont changé, lance `check.sh` ; en cas d'échec, l'agent doit continuer |

Le hook `Stop` ne relance pas en boucle : au second arrêt consécutif, il laisse l'agent s'arrêter,
et la loi l'oblige alors à signaler l'échec dans son résumé.

Les autres outils n'ont pas de hooks équivalents. Pour eux, le filet est le hook git et la CI.

### Hook git (`.githooks/pre-commit`)
Lance `check.sh --quick` sur les fichiers indexés et bloque le commit en cas d'échec.
Activé par `git config core.hooksPath .githooks` (fait par `scripts/install.sh`).

### CI (`.github/workflows/governance.yml`)
Lance `check.sh` complet sur chaque push et pull request. C'est le dernier rempart : il ne dépend
ni du modèle ni de la machine locale.

### Chemins protégés (`.agents/protected-paths`)
Un motif par ligne, syntaxe `case` du shell : `*` traverse aussi les `/`.
Y figurent les secrets et les garde-fous eux-mêmes : la loi ne s'auto-modifie pas.
Limite connue : le hook protège les outils d'édition, pas une commande shell lancée par l'agent.
La CI et la revue de code couvrent ce cas.

## Faire évoluer la gouvernance

- **Boucle de correction** : quand un agent répète une erreur, ajoute une ligne précise
  (section 3 de `AGENTS.md` si c'est propre au projet, dépôt `pattern-agent` si c'est universel).
  Supprime les règles devenues inutiles.
- **Écrire** des consignes impératives et vérifiables, avec la commande exacte.
  « Écris du code propre » ne sert à rien ; « lance `sh scripts/check.sh` » sert.
- **Ne pas écrire** dans `AGENTS.md` ce qu'un formatter ou un linter impose déjà.
- **Relire** ces fichiers comme du code, en pull request.
- **Propager** la loi commune : depuis un clone de `pattern-agent`,
  `sh scripts/install.sh <projet> --update` remplace le bloc `LOI` de `AGENTS.md` et les fichiers gérés,
  sans toucher aux sections propres au projet.

## Niveau utilisateur (optionnel)

Pour appliquer aussi la loi dans des dossiers sans `AGENTS.md`, copie le bloc « Loi commune » dans le
fichier global de chaque outil : `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`.
Le fichier du projet reste prioritaire.
