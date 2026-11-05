#!/usr/bin/env bash
# Links Codex's global instructions to the shared authored file:
#   ${CODEX_HOME:-~/.codex}/AGENTS.md -> ~/.assistant-config/shared/AGENTS.md
# Safe to run again. Refuses to replace a real AGENTS.md, and skips while the
# shared file doesn't exist yet, so it never leaves a dangling link.
#
# Usage:
#   link-codex-entrypoints.sh

set -euo pipefail

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
SHARED_AGENTS="$HOME/.assistant-config/shared/AGENTS.md"
DEST="$CODEX_DIR/AGENTS.md"

warn_if_overridden() {
  [ -s "$CODEX_DIR/AGENTS.override.md" ] || return 0
  echo "link-codex-entrypoints: $CODEX_DIR/AGENTS.override.md is not empty; Codex reads it instead of AGENTS.md" >&2
}

main() {
  if [ ! -f "$SHARED_AGENTS" ]; then
    echo "link-codex-entrypoints: $SHARED_AGENTS not found; skipping" >&2
    return 0
  fi

  if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
    echo "link-codex-entrypoints: $DEST is a real file; refusing to replace it" >&2
    return 1
  fi

  mkdir -p "$CODEX_DIR"
  ln -sfn "$SHARED_AGENTS" "$DEST"
  echo "  linked $DEST -> $SHARED_AGENTS"
  warn_if_overridden
}

main "$@"
