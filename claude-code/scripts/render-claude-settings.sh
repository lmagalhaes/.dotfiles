#!/usr/bin/env bash
# Renders authored/config/settings.managed.json into ~/.claude/settings.json.
# Managed keys win at every top-level key they define; unknown runtime keys
# (e.g. feedbackSurveyState) are preserved from the existing target.
# Nested keys (permissions, hooks, enabledPlugins) are owned by managed and
# replaced wholesale — user-approved permissions belong in settings.local.json.

set -euo pipefail

command -v jq >/dev/null || { echo "render-claude-settings: jq is required but not found" >&2; exit 1; }

MANAGED="$HOME/.claude/authored/config/settings.managed.json"
TARGET="$HOME/.claude/settings.json"

if [ ! -f "$MANAGED" ]; then
  echo "render-claude-settings: managed source not found: $MANAGED" >&2
  exit 1
fi

# Validate before touching the live file.
if ! jq empty "$MANAGED" 2>/dev/null; then
  echo "render-claude-settings: $MANAGED is not valid JSON — aborting" >&2
  exit 1
fi

if [ ! -f "$TARGET" ]; then
  cp "$MANAGED" "$TARGET"
  echo "render-claude-settings: created $TARGET"
  exit 0
fi

jq -s '.[0] + .[1]' "$TARGET" "$MANAGED" > "${TARGET}.tmp"
mv "${TARGET}.tmp" "$TARGET"
echo "render-claude-settings: updated $TARGET"
