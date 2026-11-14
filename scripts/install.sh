#!/bin/sh
# Installe ou met à jour la gouvernance pattern-agent dans un projet.
#
#   sh scripts/install.sh <dossier-projet>            installe : copie ce qui manque, n'écrase rien
#   sh scripts/install.sh <dossier-projet> --update   met à jour la loi commune et les fichiers gérés
#
# Fichiers du PROJET : copiés une fois, puis le projet se les approprie. Jamais écrasés.
# Fichiers GÉRÉS : identiques dans tous les projets, écrasés par --update.
# Bloc LOI de AGENTS.md : remplacé par --update, le reste de AGENTS.md n'est pas touché.
set -u

PROJECT_FILES="
AGENTS.md
CLAUDE.md
.gemini/settings.json
.github/copilot-instructions.md
.github/pull_request_template.md
.github/workflows/governance.yml
.claude/settings.json
.agents/protected-paths
.gitattributes
docs/architecture.md
docs/testing.md
docs/adr/0001-gouvernance-agents.md
scripts/check.sh
"
MANAGED_FILES="
docs/governance.md
docs/adr/0000-template.md
scripts/governance-lint.sh
scripts/hooks/lib.sh
scripts/hooks/guard-protected.sh
scripts/hooks/post-edit.sh
scripts/hooks/stop-check.sh
.githooks/pre-commit
"

usage() { printf 'Usage : sh scripts/install.sh <dossier-projet> [--update]\n' >&2; exit 1; }
[ $# -ge 1 ] || usage
UPDATE=0
case ${2:-} in '') ;; --update) UPDATE=1 ;; *) usage ;; esac

SRC=$(cd "$(dirname "$0")/.." && pwd)
[ -d "$1" ] || { printf 'Dossier introuvable : %s\n' "$1" >&2; exit 1; }
DEST=$(cd "$1" && pwd)
[ "$SRC" != "$DEST" ] || { printf 'La destination est le dépôt pattern-agent lui-même.\n' >&2; exit 1; }

copy() { # copy <chemin> <écraser:0|1>
  if [ -e "$DEST/$1" ] && [ "$2" -eq 0 ]; then
    printf '  =  %s (existe déjà, conservé)\n' "$1"
    return
  fi
  if [ -e "$DEST/$1" ]; then verb='~ '; else verb='+ '; fi
  mkdir -p "$DEST/$(dirname "$1")"
  cp "$SRC/$1" "$DEST/$1"
  printf '  %s %s\n' "$verb" "$1"
}

update_law() {
  target="$DEST/AGENTS.md"
  block=$(mktemp)
  sed -n '/<!-- LOI:DEBUT/,/<!-- LOI:FIN/p' "$SRC/AGENTS.md" > "$block"
  if grep -q '<!-- LOI:DEBUT' "$target"; then
    out=$(mktemp)
    awk -v bf="$block" '
      /<!-- LOI:DEBUT/ { while ((getline l < bf) > 0) print l; skip = 1; next }
      /<!-- LOI:FIN/ && skip { skip = 0; next }
      !skip { print }
    ' "$target" > "$out" && cat "$out" > "$target"
    rm -f "$out"
    printf '  ~  AGENTS.md (bloc LOI remplacé)\n'
  else
    { printf '\n'; cat "$block"; } >> "$target"
    printf '  +  AGENTS.md (bloc LOI ajouté à la fin)\n'
  fi
  rm -f "$block"
}

printf 'Source      : %s\nDestination : %s\n\n' "$SRC" "$DEST"

for f in $PROJECT_FILES; do copy "$f" 0; done
for f in $MANAGED_FILES; do copy "$f" "$UPDATE"; done
if [ "$UPDATE" -eq 1 ] || ! grep -q '<!-- LOI:DEBUT' "$DEST/AGENTS.md"; then update_law; fi

if command -v git >/dev/null 2>&1 && git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$DEST" config core.hooksPath .githooks
  printf '\n  Hook git activé (core.hooksPath = .githooks)\n'
else
  printf '\n  Pas un dépôt git : après "git init", lance "git config core.hooksPath .githooks"\n'
fi

cat <<'EOF'

Étapes suivantes :
  1. Remplis les champs <À REMPLIR> de AGENTS.md (sections 1 à 3) et docs/architecture.md.
  2. Remplace les exemples de docs/testing.md par les zones réelles du projet.
  3. Ajoute les étapes du projet dans scripts/check.sh, puis lance : sh scripts/check.sh
  4. Si un fichier marqué "=" existait déjà (ex. .claude/settings.json), fusionne-le à la main
     avec la version de pattern-agent.
EOF