#!/usr/bin/env bash
# Renders the managed authored settings into ~/.claude/settings.json.
# Managed keys win at every top-level key they define; unknown runtime keys
# (e.g. feedbackSurveyState) are preserved from the existing target.
# Nested keys (permissions, hooks, enabledPlugins) are owned by managed and
# replaced wholesale - global permissions belong in settings.managed.json.
# Approvals given with "don't ask again" land in each project's own
# .claude/settings.local.json; ~/.claude/settings.local.json is not a
# user-scope file (it applies only to sessions started in $HOME).
#
# Because of that, a render from a checkout that is behind (or a template
# that lost a rule by mistake) would silently drop live protections. So it
# refuses to render when the result would drop a deny rule or hook the live
# file has, and lists them. Pass --force to render anyway.
#
#   render-claude-settings.sh [--force]

# sed is the clearest way to indent each listed line.
# shellcheck disable=SC2001

set -euo pipefail

command -v jq >/dev/null || { echo "render-claude-settings: jq is required but not found" >&2; exit 1; }

MANAGED="$HOME/.claude/authored/settings.managed.json"
TARGET="$HOME/.claude/settings.json"
FORCE=false

usage() {
  cat <<'EOF'
usage: render-claude-settings.sh [--force]

Renders ~/.claude/authored/settings.managed.json into ~/.claude/settings.json.
Top-level keys in the template replace the live ones; other live keys are kept.

Refuses to render when that would remove a deny rule or hook the live file has,
and lists them. Allow rules are not guarded.

  --force     render anyway, and list what was removed
  -h, --help  show this help
EOF
}

case "${1:-}" in
  "") ;;
  --force) FORCE=true ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

# Prints each deny rule and hook in the live settings that the rendered
# settings ($1) would drop, one per line.
dropped_protections() {
  jq -nr --slurpfile live "$TARGET" --slurpfile rendered "$1" '
    def protections:
      [(.permissions.deny // [])[] | "deny  \(.)"]
      + [(.hooks // {}) | to_entries[] | .key as $event | .value[]
          | (if .matcher then "\($event)(\(.matcher))" else $event end) as $where
          | .hooks[] | "hook  \($where): \(.command // .prompt // tostring)"];
    ($live[0] | protections) - ($rendered[0] | protections) | .[]'
}

if [ ! -f "$MANAGED" ]; then
  echo "render-claude-settings: managed source not found: $MANAGED" >&2
  exit 1
fi

if ! jq empty "$MANAGED" 2>/dev/null; then
  echo "render-claude-settings: $MANAGED is not valid JSON - aborting" >&2
  exit 1
fi

if [ ! -f "$TARGET" ]; then
  cp "$MANAGED" "$TARGET"
  echo "render-claude-settings: created $TARGET"
  exit 0
fi

jq -s '.[0] + .[1]' "$TARGET" "$MANAGED" > "${TARGET}.tmp"
DROPPED="$(dropped_protections "${TARGET}.tmp")"

if [ -n "$DROPPED" ] && [ "$FORCE" != true ]; then
  rm -f "${TARGET}.tmp"
  {
    echo "render-claude-settings: not rendering - this would remove from $TARGET:"
    sed 's/^/  /' <<<"$DROPPED"
    echo "Re-run with --force to render anyway: bash ${BASH_SOURCE[0]} --force"
  } >&2
  exit 1
fi

mv "${TARGET}.tmp" "$TARGET"
echo "render-claude-settings: updated $TARGET"
[ -z "$DROPPED" ] || sed 's/^/  removed (--force): /' <<<"$DROPPED"
