# 0001. Gouverner les agents IA par AGENTS.md et des garde-fous automatiques

- **Statut** : accepté
- **Date** : 2026-11-14

## Contexte

Plusieurs LLM interviennent sur le code (Claude, Codex, Gemini, Copilot, Cursor). Chacun a son propre
fichier d'instructions. Des consignes dupliquées finissent par diverger, et une consigne écrite reste
une demande : le modèle la suit souvent, pas toujours.

## Décision

1. `AGENTS.md` à la racine est la source unique d'instructions. Les fichiers propres à chaque outil ne
   font qu'y renvoyer.
2. Tout ce qui doit être respecté à coup sûr est imposé par un outil déterministe :
   `scripts/check.sh`, hooks Claude Code, hook git `pre-commit` et CI.
3. Le détail est chargé à la demande depuis `docs/` pour garder `AGENTS.md` court.

## Alternatives écartées

- Un fichier par outil, maintenu à la main : divergence garantie.
- Instructions seules, sans garde-fou : aucune garantie sur les règles critiques.

## Conséquences

- Une seule commande à connaître pour l'agent comme pour l'humain : `sh scripts/check.sh`.
- `scripts/check.sh` doit rester rapide en mode `--quick`, sinon les hooks ralentissent le travail.
- La loi commune évolue dans le dépôt `pattern-agent` et se propage avec `scripts/install.sh --update`.
