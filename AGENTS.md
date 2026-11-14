# AGENTS.md

<!--
  Source UNIQUE d'instructions pour tous les agents IA (Claude, Codex, Gemini, Copilot, Cursor…).
  Les fichiers propres à un outil (CLAUDE.md, .gemini/settings.json, .github/copilot-instructions.md)
  ne font que renvoyer ici. Garder ce fichier court (< 200 lignes) : le détail va dans docs/.
  Sections 1 à 3 : propres au projet, à adapter. Section 4 : loi commune, gérée par pattern-agent.
-->

## 1. Projet

- **Nom** : <À REMPLIR>
- **But** : <À REMPLIR : une phrase, pour qui et quel problème>
- **Stack** : <À REMPLIR : langages, frameworks, base de données>
- **Architecture** : voir `docs/architecture.md`
- **Tests concernés par zone** : voir `docs/testing.md`
- **Décisions et leur « pourquoi »** : voir `docs/adr/`

## 2. Commandes

| But | Commande |
|-----|----------|
| Vérification complète (obligatoire avant de dire « terminé ») | `sh scripts/check.sh` |
| Vérification rapide (après une modification) | `sh scripts/check.sh --quick` |
| Lancer en local | <À REMPLIR> |
| Installer les dépendances | <À REMPLIR> |

## 3. Règles propres au projet

- <À REMPLIR : règles d'architecture non négociables. Exemple : « le domaine ne dépend d'aucun framework »>
- Un `AGENTS.md` dans un sous-dossier complète celui-ci pour cette zone et prime en cas de conflit.

<!-- LOI:DEBUT pattern-agent v1.0.0 | bloc géré : ne pas modifier ici, mettre à jour via scripts/install.sh --update -->
## 4. Loi commune (tous mes projets)

### Avant de modifier
1. Lis les sections 1 à 3, puis l'`AGENTS.md` du dossier touché s'il existe.
2. Si la demande est ambiguë, ou si la bonne solution dépasse ce qui est demandé : pose la question avant d'agir.
3. Zone inconnue : lis `docs/architecture.md` et les ADR concernés avant d'écrire du code.

### À chaque modification
1. Identifie les tests concernés via `docs/testing.md`.
2. Ajoute ou mets à jour les tests du comportement modifié. Un bug corrigé = un test qui le reproduit.
3. Lance `sh scripts/check.sh` et corrige jusqu'au vert. Ne déclare jamais « terminé » sur un check rouge ou non lancé.
4. Mets à jour la documentation impactée (README, `docs/`, contrat d'API) dans le même changement.
5. Décision structurante (dépendance majeure, architecture, format de données, sécurité) : nouvel ADR dans `docs/adr/` à partir de `docs/adr/0000-template.md`.

### Definition of Done
- [ ] `sh scripts/check.sh` est vert
- [ ] Tests ajoutés ou mis à jour pour le comportement modifié
- [ ] Documentation à jour
- [ ] Aucun secret ni donnée personnelle dans le code, les logs, les tests ou les fixtures
- [ ] Diff limité à la demande (pas de refactor opportuniste non demandé)

### Interdits
- Désactiver, supprimer, ignorer (`skip`) ou affaiblir un test pour faire passer la vérification.
- Modifier un chemin listé dans `.agents/protected-paths` : demande à l'humain de le faire.
- Contourner un garde-fou : `--no-verify`, désactiver un hook, modifier la CI pour qu'elle passe.
- Ajouter une dépendance sans la justifier dans le résumé de fin de tâche.
- Inventer une API, une commande, un fichier ou un résultat de test.
- Committer un secret (`.env`, clé, token).

### Résumé de fin de tâche
Termine toujours par :
1. ce qui a changé et pourquoi ;
2. les vérifications lancées et leur résultat réel ;
3. ce qui reste à faire ou n'a pas pu être vérifié.
<!-- LOI:FIN -->
