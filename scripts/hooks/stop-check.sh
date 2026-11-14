#!/bin/sh
# Hook Claude Code Stop. Géré par pattern-agent.
# Avant que l'agent ne rende la main : si des fichiers ont changé, lance la vérification complète.
# En cas d'échec, sortie 2 : l'agent reçoit l'erreur et doit continuer.
# Au second arrêt consécutif (stop_hook_active), on laisse passer pour éviter une boucle infinie :
# la loi impose alors à l'agent de signaler l'échec dans son résumé.
. "$(dirname "$0")/lib.sh"

input=$(cat)
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Aucun changement dans le dépôt : rien à vérifier.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -z "$(git status --porcelain)" ]; then
  exit 0
fi

if ! out=$(sh scripts/check.sh 2>&1); then
  printf '%s\n' "$out" | tail -n 80 >&2
  printf "\nsh scripts/check.sh échoue : la tâche n'est pas terminée. Corrige, ou explique à l'humain ce qui bloque.\n" >&2
  exit 2
fi
exit 0
