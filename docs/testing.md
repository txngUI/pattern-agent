# Carte des tests

Pour chaque zone modifiée, quels tests lancer. L'agent consulte cette table au lieu de deviner.

> **À adapter par projet.** Les lignes ci-dessous sont des exemples. Remplace-les par les zones réelles.

| Zone modifiée | Tests à lancer | Remarque |
|---------------|----------------|----------|
| `backend/domain/**` | `./mvnw test -pl domain` | Rapide, sans Spring |
| `backend/adapters/persistence/**` | `./mvnw verify -pl persistence` | Testcontainers : Docker requis |
| `frontend/components/**` | `pnpm vitest related <fichiers> --run` | Calcul automatique des tests liés |
| Contrat d'API (OpenAPI) | tests back + tests front + régénérer le client | Changement des deux côtés |
| Migration de base | `./mvnw verify` complet | Ne jamais modifier une migration appliquée |
| Zone absente de cette table | `sh scripts/check.sh` complet | Puis ajouter la ligne manquante ici |

## Règles

- Un comportement modifié sans test qui le couvre n'est pas terminé.
- Un bug corrigé commence par un test qui échoue et le reproduit.
- Préfère un outil qui calcule les tests impactés à une liste écrite à la main :
  `vitest related`, `jest --findRelatedTests`, `nx affected`, `pytest --testmon`, modules Maven ou Gradle.
  Branche-le dans `scripts/check.sh --quick`, qui reçoit les fichiers modifiés dans `$CHECK_FILES`.
