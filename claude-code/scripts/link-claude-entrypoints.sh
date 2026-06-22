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

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTHORED_DIR="$DOTFILES_DIR/claude-code/authored"
CLAUDE_DIR="$HOME/.claude"

if [ ! -d "$AUTHORED_DIR" ]; then
  echo "link-claude-entrypoints: authored dir not found: $AUTHORED_DIR" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

link() {
  local name="$1"
  local target="$2"
  local dest="$CLAUDE_DIR/$name"

  if [ -L "$dest" ]; then
    # Already a symlink — replace regardless of current target.
    rm "$dest"
  elif [ -e "$dest" ]; then
    if [ "$FORCE" = true ]; then
      rm -rf "$dest"
    else
      echo "link-claude-entrypoints: skipping $dest — real path exists (use --force to overwrite)" >&2
      return 1
    fi
  fi

  ln -s "$target" "$dest"
  echo "  linked ~/.claude/$name -> $target"
}

echo "Linking authored entrypoints into $CLAUDE_DIR..."

# Directory symlink — the whole authored tree in one link.
link "authored" "$AUTHORED_DIR"

# Top-level files Claude requires at fixed names.
link "CLAUDE.md"   "authored/CLAUDE.md"
link "RTK.md"      "authored/RTK.md"

# Directory-level symlinks so new files appear live without re-running this script.
link "rules"  "authored/rules"
link "skills" "authored/skills"

echo "Done."
