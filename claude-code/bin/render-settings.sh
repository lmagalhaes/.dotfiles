#!/usr/bin/env bash
set -euo pipefail

command -v jq >/dev/null || { echo "render-settings: jq is required but not found" >&2; exit 1; }

MANAGED="${HOME}/.claude/config/settings.managed.json"
TARGET="${HOME}/.claude/settings.json"

if [ ! -f "$MANAGED" ]; then
  echo "render-settings: managed source not found: $MANAGED" >&2
  exit 1
fi

if [ ! -f "$TARGET" ]; then
  cp "$MANAGED" "$TARGET"
  echo "render-settings: created $TARGET"
  exit 0
fi

# Shallow merge: managed keys win at every top-level key they define,
# unknown runtime keys (e.g. feedbackSurveyState) are preserved from the target.
# Nested keys like permissions, hooks, and enabledPlugins are owned by managed and
# replaced wholesale — user-approved permissions belong in settings.local.json, not here.
jq -s '.[0] + .[1]' "$TARGET" "$MANAGED" > "${TARGET}.tmp"
mv "${TARGET}.tmp" "$TARGET"
echo "render-settings: updated $TARGET"
