#!/bin/sh
# Vérifie l'intégrité de la gouvernance agent. Géré par pattern-agent.
# Erreur  = la gouvernance est cassée (code de sortie 1).
# Avertissement = à compléter, sans bloquer.
set -u
cd "$(dirname "$0")/.." || exit 1

MAX_LINES=${AGENTS_MAX_LINES:-200}
errors=0
warnings=0
err()  { printf '  ERREUR : %s\n' "$1" >&2; errors=$((errors + 1)); }
warn() { printf '  AVERTISSEMENT : %s\n' "$1"; warnings=$((warnings + 1)); }

# 1. AGENTS.md : présent, court, avec le bloc de loi commune
if [ ! -f AGENTS.md ]; then
  err "AGENTS.md absent à la racine"
  exit 1
fi
lines=$(wc -l < AGENTS.md | tr -d ' ')
[ "$lines" -le "$MAX_LINES" ] || err "AGENTS.md fait $lines lignes (max $MAX_LINES) : déplace le détail dans docs/"
{ grep -q '<!-- LOI:DEBUT' AGENTS.md && grep -q '<!-- LOI:FIN' AGENTS.md; } \
  || err "bloc de loi commune (LOI:DEBUT / LOI:FIN) absent de AGENTS.md"

# 2. Les fichiers propres à un outil renvoient à AGENTS.md, sans dupliquer
if [ -f CLAUDE.md ]; then
  grep -q '^@AGENTS.md' CLAUDE.md || err "CLAUDE.md doit commencer par la ligne @AGENTS.md"
else
  warn "CLAUDE.md absent : Claude Code ne lira pas AGENTS.md"
fi
for f in .github/copilot-instructions.md .gemini/settings.json; do
  if [ -f "$f" ] && ! grep -q 'AGENTS.md' "$f"; then
    err "$f doit renvoyer à AGENTS.md"
  fi
done

# 3. Les chemins cités entre `backticks` dans les AGENTS.md existent
broken=$(
  find . -name AGENTS.md -not -path '*/node_modules/*' -not -path './.git/*' | while IFS= read -r file; do
    dir=$(dirname "$file")
    grep -o '`[^` ]*`' "$file" | tr -d '`' | while IFS= read -r ref; do
      case $ref in */*) ;; *) continue ;; esac            # ressemble à un chemin
      case $ref in *'*'*|*'<'*|*'$'*|*://*|-*) continue ;; esac  # glob, placeholder, variable, URL, option
      [ -e "$ref" ] || [ -e "$dir/$ref" ] || printf '%s -> %s\n' "$file" "$ref"
    done
  done
)
if [ -n "$broken" ]; then
  printf '%s\n' "$broken" | while IFS= read -r b; do printf '  ERREUR : chemin introuvable : %s\n' "$b" >&2; done
  errors=$((errors + $(printf '%s\n' "$broken" | wc -l | tr -d ' ')))
fi

# 4. ADR nommés NNNN-titre.md et dotés d'un statut
if [ -d docs/adr ]; then
  for f in docs/adr/*.md; do
    [ -e "$f" ] || continue
    case $(basename "$f") in
      [0-9][0-9][0-9][0-9]-*.md) ;;
      *) err "ADR mal nommé : $f (attendu : docs/adr/NNNN-titre.md)" ;;
    esac
    grep -q 'Statut' "$f" || warn "ADR sans statut : $f"
  done
fi

# 5. Garde-fous présents
[ -f .agents/protected-paths ] || warn ".agents/protected-paths absent : aucun chemin protégé"

# 6. Champs encore à remplir
todo=$(grep -c '<À REMPLIR' AGENTS.md || true)
[ "$todo" -eq 0 ] || warn "AGENTS.md contient encore $todo champ(s) <À REMPLIR>"

if [ "$errors" -gt 0 ]; then
  printf '  %s erreur(s), %s avertissement(s)\n' "$errors" "$warnings" >&2
  exit 1
fi
printf '  Gouvernance intègre (%s avertissement(s))\n' "$warnings"
