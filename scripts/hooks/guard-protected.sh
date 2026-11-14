#!/bin/sh
# Hook Claude Code PreToolUse (Edit|Write|MultiEdit|NotebookEdit). Géré par pattern-agent.
# Bloque l'écriture dans un chemin listé dans .agents/protected-paths.
# Sortie 2 = action refusée ; le message sur stderr est transmis à l'agent.
. "$(dirname "$0")/lib.sh"

input=$(cat)
file=$(edited_file "$input")
[ -n "$file" ] || exit 0
[ -f .agents/protected-paths ] || exit 0

while IFS= read -r pattern || [ -n "$pattern" ]; do
  pattern=$(printf '%s' "$pattern" | tr -d '\r')
  case $pattern in ''|'#'*) continue ;; esac
  # shellcheck disable=SC2254  # le motif doit être interprété comme un glob
  case $file in
    $pattern)
      printf 'BLOQUÉ : "%s" est un chemin protégé (motif "%s" dans .agents/protected-paths).\n' "$file" "$pattern" >&2
      printf "Ne contourne pas ce garde-fou. Explique à l'humain la modification voulue : il la fera lui-même.\n" >&2
      exit 2
      ;;
  esac
done < .agents/protected-paths
exit 0
