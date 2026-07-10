#!/usr/bin/env bash
# Creates or refreshes the authored projection symlinks inside ~/.claude.
# Run once after cloning or whenever the authored tree changes location.
#
# Usage:
#   link-claude-entrypoints.sh [--force]
#
# Without --force the script refuses to overwrite any path that is a real
# file or real directory (i.e. not already a symlink into this tree).

set -euo pipefail

FORCE=false
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE=true
done

CLAUDE_DIR="$HOME/.claude"

resolve_authored_dir() {
  if [ -n "${ASSISTANT_CONFIG_CLAUDE_DIR:-}" ]; then
    printf '%s\n' "$ASSISTANT_CONFIG_CLAUDE_DIR"
    return
  fi

  if [ -n "${ASSISTANT_CONFIG_DIR:-}" ]; then
    printf '%s\n' "$ASSISTANT_CONFIG_DIR/claude"
    return
  fi

  if [ -d "$HOME/.assistant-config/claude" ]; then
    printf '%s\n' "$HOME/.assistant-config/claude"
    return
  fi

  return 1
}

AUTHORED_DIR="$(resolve_authored_dir || true)"

if [ ! -d "$AUTHORED_DIR" ]; then
  echo "link-claude-entrypoints: authored dir not found. Expected ~/.assistant-config/claude or ASSISTANT_CONFIG_CLAUDE_DIR." >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

link() {
  local name="$1"
  local target="$2"
  local dest="$CLAUDE_DIR/$name"

  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    if [ "$FORCE" = true ]; then
      rm -rf "$dest"
    else
      echo "link-claude-entrypoints: skipping $dest - real path exists (use --force to overwrite)" >&2
      return 1
    fi
  fi

  ln -s "$target" "$dest"
  echo "  linked ~/.claude/$name -> $target"
}

echo "Linking authored entrypoints into $CLAUDE_DIR..."
echo "  source: $AUTHORED_DIR"

link "authored" "$AUTHORED_DIR"
link "CLAUDE.md" "authored/CLAUDE.md"
link "RTK.md" "authored/RTK.md"
link "rules" "authored/rules"
link "skills" "authored/skills"

# hooks/ and tooling/ are intentionally accessed via ~/.claude/authored/...,
# not projected as top-level runtime namespaces.

echo "Done."
