#!/bin/bash
#
# list-sessions.sh - Output session data as JSON
#
# Usage: list-sessions.sh [count|all]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/_git-helpers.sh"

LIMIT="${1:-10}"
[ "$LIMIT" = "all" ] && LIMIT=9999

SESSIONS_DIR="$(find_sessions_dir)"

# Check directory exists
if [ ! -d "$SESSIONS_DIR" ]; then
  echo '{"error": "no_sessions_dir"}'
  exit 0
fi

# Get latest and total
LATEST="none"
[ -f "$SESSIONS_DIR/index.json" ] && LATEST=$(jq -r '.latest // "none"' "$SESSIONS_DIR/index.json" 2>/dev/null)
TOTAL=$(ls -1 "$SESSIONS_DIR"/session-*.json 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
  echo '{"error": "no_sessions"}'
  exit 0
fi

# Build JSON output
echo "{"
echo "  \"latest\": \"$LATEST\","
echo "  \"total\": $TOTAL,"
echo "  \"limit\": $LIMIT,"
echo "  \"sessions\": ["

first=true
for f in $(ls -1r "$SESSIONS_DIR"/session-*.json 2>/dev/null | head -n "$LIMIT"); do
  [ -f "$f" ] || continue

  $first || echo ","
  first=false

  id=$(basename "$f" .json)
  jq -c "{
    id: \"$id\",
    timestamp: .timestamp,
    branch: .git_branch,
    summary: .summary
  }" "$f"
done

echo "  ]"
echo "}"
