#!/bin/sh
# Auto-test du kit pattern-agent (propre à ce dépôt, non copié dans les projets).
# Installe le kit dans un projet temporaire et vérifie scripts, hooks et mise à jour de la loi.
set -u
cd "$(dirname "$0")/.." || exit 1
unset CLAUDE_PROJECT_DIR

pass=0
fail=0
ok() { printf '  [OK] %s\n' "$1"; pass=$((pass + 1)); }
ko() { printf '  [ECHEC] %s\n' "$1" >&2; fail=$((fail + 1)); }
expect_code() { # expect_code <libellé> <code attendu> <commande…>
  label=$1; want=$2; shift 2
  "$@" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then ok "$label"; else ko "$label (code $got, attendu $want)"; fi
}
has()     { grep -q "$2" "$1"; }
has_not() { ! grep -q "$2" "$1"; }

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
P="$T/projet"
mkdir -p "$P"
hook() { printf '%s' "$2" | sh "$P/scripts/hooks/$1.sh"; }

echo "== Le kit lui-même"
expect_code "check.sh complet passe" 0 sh scripts/check.sh
expect_code "check.sh --quick passe" 0 sh scripts/check.sh --quick README.md

echo "== install.sh"
expect_code "installation" 0 sh scripts/install.sh "$P"
for f in AGENTS.md CLAUDE.md .gemini/settings.json .claude/settings.json scripts/check.sh \
         scripts/governance-lint.sh scripts/hooks/guard-protected.sh .githooks/pre-commit docs/testing.md; do
  expect_code "copié : $f" 0 test -f "$P/$f"
done
expect_code "README du kit non copié" 1 test -e "$P/README.md"
expect_code "auto-test non copié" 1 test -e "$P/tests/selftest.sh"
expect_code "check.sh passe dans le projet" 0 sh "$P/scripts/check.sh"
expect_code "refus d'installer sur soi-même" 1 sh scripts/install.sh .

echo "== Mise à jour de la loi"
cat > "$P/AGENTS.md" <<'EOF'
# AGENTS.md
Règle maison
<!-- LOI:DEBUT ancienne -->
vieille loi
<!-- LOI:FIN -->
Après la loi
EOF
echo "# étape maison" >> "$P/scripts/check.sh"
sh scripts/install.sh "$P" >/dev/null 2>&1
expect_code "sans --update, la loi n'est pas touchée" 0 has "$P/AGENTS.md" "vieille loi"
sh scripts/install.sh "$P" --update >/dev/null 2>&1
expect_code "--update remplace l'ancienne loi" 0 has_not "$P/AGENTS.md" "vieille loi"
expect_code "--update insère la loi actuelle" 0 has "$P/AGENTS.md" "Loi commune"
expect_code "--update garde le texte du projet (avant)" 0 has "$P/AGENTS.md" "Règle maison"
expect_code "--update garde le texte du projet (après)" 0 has "$P/AGENTS.md" "Après la loi"
expect_code "--update ne touche pas check.sh" 0 has "$P/scripts/check.sh" "étape maison"
expect_code "un seul bloc LOI" 0 test "$(grep -c '<!-- LOI:DEBUT' "$P/AGENTS.md")" -eq 1

echo "== Hook guard-protected"
expect_code "bloque .env (chemin absolu)" 2 hook guard-protected "{\"tool_input\":{\"file_path\":\"$P/.env\"}}"
expect_code "bloque une clé en sous-dossier" 2 hook guard-protected '{"tool_input":{"file_path":"config/certs/server.pem"}}'
expect_code "bloque la modification des hooks" 2 hook guard-protected '{"tool_input":{"file_path":"scripts/hooks/post-edit.sh"}}'
expect_code "autorise un fichier normal" 0 hook guard-protected '{"tool_input":{"file_path":"src/app.ts"}}'
expect_code "ignore un file_path cité dans le contenu" 0 hook guard-protected \
  '{"tool_input":{"file_path":"src/a.md","content":"\"file_path\": \".env\""}}'
expect_code "chemin Windows" 2 env CLAUDE_PROJECT_DIR='C:\proj' sh -c \
  "printf '%s' '{\"tool_input\":{\"file_path\":\"C:\\\\proj\\\\.env\"}}' | sh '$P/scripts/hooks/guard-protected.sh'"
expect_code "sans fichier (autre outil)" 0 hook guard-protected '{"tool_input":{"command":"ls"}}'

echo "== Hooks post-edit et stop"
expect_code "post-edit passe si le check est vert" 0 hook post-edit '{"tool_input":{"file_path":"src/app.ts"}}'
expect_code "stop passe si le check est vert" 0 hook stop-check '{"stop_hook_active":false}'
printf '# CLAUDE.md sans import\n' > "$P/CLAUDE.md"
expect_code "lint : CLAUDE.md sans @AGENTS.md échoue" 1 sh "$P/scripts/governance-lint.sh"
expect_code "post-edit renvoie l'échec à l'agent" 2 hook post-edit '{"tool_input":{"file_path":"CLAUDE.md"}}'
expect_code "stop empêche de terminer" 2 hook stop-check '{"stop_hook_active":false}'
expect_code "stop ne boucle pas (stop_hook_active)" 0 hook stop-check '{"stop_hook_active": true}'
cp AGENTS.md "$P/AGENTS.md"
cp CLAUDE.md "$P/CLAUDE.md"

echo "== Lint de gouvernance"
expect_code "lint vert après réparation" 0 sh "$P/scripts/governance-lint.sh"
echo 'Voir `docs/inexistant.md`.' >> "$P/AGENTS.md"
expect_code "lien mort détecté" 1 sh "$P/scripts/governance-lint.sh"
cp AGENTS.md "$P/AGENTS.md"
touch "$P/docs/adr/mauvais-nom.md"
expect_code "ADR mal nommé détecté" 1 sh "$P/scripts/governance-lint.sh"
rm "$P/docs/adr/mauvais-nom.md"
awk 'NR == 1 { for (i = 0; i < 200; i++) print "ligne" } { print }' AGENTS.md > "$P/AGENTS.md"
expect_code "AGENTS.md trop long détecté" 1 sh "$P/scripts/governance-lint.sh"

printf '\n%s réussi(s), %s échec(s)\n' "$pass" "$fail"
[ "$fail" -eq 0 ]