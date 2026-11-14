#!/bin/sh
# Hook Claude Code PostToolUse (Edit|Write|MultiEdit|NotebookEdit). Géré par pattern-agent.
# Lance la vérification rapide sur le fichier modifié. En cas d'échec, sortie 2 :
# l'erreur est renvoyée à l'agent, qui doit corriger avant de continuer.
. "$(dirname "$0")/lib.sh"

input=$(cat)
file=$(edited_file "$input")

if ! out=$(sh scripts/check.sh --quick ${file:+"$file"} 2>&1); then
  printf '%s\n' "$out" | tail -n 60 >&2
  printf '\nLa vérification rapide échoue après la modification de "%s". Corrige avant de continuer.\n' "$file" >&2
  exit 2
fi
exit 0
