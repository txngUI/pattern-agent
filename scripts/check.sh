#!/bin/sh
# Point d'entrée UNIQUE de vérification : agent, humain, hooks et CI lancent tous cette commande.
#
#   sh scripts/check.sh                  complet  (avant de dire « terminé », CI)
#   sh scripts/check.sh --quick [f ...]  rapide   (après chaque édition, pre-commit)
#                                        f = fichiers modifiés, exposés dans $CHECK_FILES
#
# Code de sortie : 0 si tout passe, 1 sinon.
set -u
cd "$(dirname "$0")/.." || exit 1

MODE=full
if [ "${1:-}" = "--quick" ]; then MODE=quick; shift; fi
CHECK_FILES="$*"
export CHECK_FILES

FAILED=""
step() {
  label=$1; shift
  printf '\n==> %s\n' "$label"
  if "$@"; then
    printf '[OK] %s\n' "$label"
  else
    printf '[ECHEC] %s\n' "$label" >&2
    FAILED="$FAILED
  - $label"
  fi
}
full()      { [ "$MODE" = full ]; }
has_files() { [ -n "$CHECK_FILES" ]; }

# --- Gouvernance (ne pas retirer) -------------------------------------------
step "Gouvernance" sh scripts/governance-lint.sh

# --- Étapes du projet (À ADAPTER) -------------------------------------------
# Ordre conseillé : format, lint, types, tests. Le mode --quick doit rester rapide.
# Exemples :
# step "Lint front"         pnpm --dir frontend lint
# step "Types front"        pnpm --dir frontend tsc --noEmit
# has_files && step "Tests liés" pnpm --dir frontend vitest related $CHECK_FILES --run
# full && step "Tests front" pnpm --dir frontend test
# full && step "Tests back"  ./mvnw -q verify
# -----------------------------------------------------------------------------

if [ -n "$FAILED" ]; then
  printf '\n[ECHEC] Vérification %s échouée :%s\n' "$MODE" "$FAILED" >&2
  exit 1
fi
printf '\n[OK] Vérification %s réussie\n' "$MODE"
