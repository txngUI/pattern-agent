#!/bin/sh
# Fonctions communes aux hooks Claude Code. Géré par pattern-agent.
# Les hooks reçoivent un JSON sur stdin ; on l'analyse sans dépendance (pas de jq).

# Se placer à la racine du projet (les hooks sont dans scripts/hooks/).
cd "$(dirname "$0")/../.." || exit 0
PROJECT_ROOT=$(pwd)

# Normalise un chemin : antislashs Windows -> slashs, "C:/x" -> "/c/x".
norm_path() {
  printf '%s' "$1" \
    | sed -e 's#\\\\#/#g' -e 's#\\#/#g' -e 's#^\([A-Za-z]\):/#/\1/#' \
    | awk '{ if ($0 ~ /^\/[A-Za-z]\//) $0 = "/" tolower(substr($0, 2, 1)) substr($0, 3); print }'
}

# Extrait la valeur d'un champ texte du JSON d'entrée : json_field "$input" file_path
#   Première occurrence seulement : un contenu de fichier qui citerait ce champ est échappé (\").
json_field() {
  printf '%s' "$1" | tr '\n' ' ' \
    | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n 1 \
    | sed 's/^"[^"]*"[[:space:]]*:[[:space:]]*"\(.*\)"$/\1/'
}

# Chemin du fichier édité, relatif à la racine du projet (vide si aucun).
edited_file() {
  f=$(json_field "$1" file_path)
  [ -n "$f" ] || f=$(json_field "$1" notebook_path)
  [ -n "$f" ] || return 0
  f=$(norm_path "$f")
  root=$(norm_path "${CLAUDE_PROJECT_DIR:-$PROJECT_ROOT}")
  f=${f#"$root"/}
  f=${f#./}
  printf '%s' "$f"
}
