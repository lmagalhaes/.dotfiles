#!/usr/bin/env bash
# Links Codex's global instructions and rules to the authored files:
#   ${CODEX_HOME:-~/.codex}/AGENTS.md -> ~/.assistant-config/shared/AGENTS.md
#   ${CODEX_HOME:-~/.codex}/rules/git-guard.rules
#     -> ~/.assistant-config/codex/rules/git-guard.rules
# Safe to run again. Refuses to replace a real file, and skips a link whose
# authored file doesn't exist yet, so it never leaves a dangling link.
# Codex's own rules/default.rules is never touched.
#
# Usage:
#   link-codex-entrypoints.sh

set -euo pipefail

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
AUTHORED_DIR="$HOME/.assistant-config"

warn_if_overridden() {
  [ -s "$CODEX_DIR/AGENTS.override.md" ] || return 0
  echo "link-codex-entrypoints: $CODEX_DIR/AGENTS.override.md is not empty; Codex reads it instead of AGENTS.md" >&2
}

link_authored() {
  local source="$1" dest="$2"

  if [ ! -f "$source" ]; then
    echo "link-codex-entrypoints: $source not found; skipping" >&2
    return 0
  fi

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "link-codex-entrypoints: $dest is a real file; refusing to replace it" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$source" "$dest"
  echo "  linked $dest -> $source"
}

main() {
  local status=0
  link_authored "$AUTHORED_DIR/shared/AGENTS.md" "$CODEX_DIR/AGENTS.md" || status=1
  link_authored "$AUTHORED_DIR/codex/rules/git-guard.rules" "$CODEX_DIR/rules/git-guard.rules" || status=1
  warn_if_overridden
  return "$status"
}

main "$@"
