#!/usr/bin/env bash
# Usage: set-cwd.sh <original_workspace> <new_directory>
# Looks up session_id by original workspace directory for multi-instance support

ORIGINAL_WORKSPACE="$1"
NEW_CWD="$2"
SESSION_MAP="/tmp/claude-sessions.json"

if [ -z "$ORIGINAL_WORKSPACE" ] || [ -z "$NEW_CWD" ]; then
    echo "Usage: set-cwd.sh <original_workspace> <new_directory>" >&2
    exit 1
fi

if [ ! -f "$SESSION_MAP" ]; then
    echo "Session map not found: $SESSION_MAP" >&2
    exit 1
fi

# Look up session_id by original workspace
SESSION_ID=$(jq -r --arg dir "$ORIGINAL_WORKSPACE" '.[$dir] // empty' "$SESSION_MAP")

if [ -z "$SESSION_ID" ]; then
    echo "No session found for workspace: $ORIGINAL_WORKSPACE" >&2
    exit 1
fi

# Update the cwd state file
echo "$NEW_CWD" > "/tmp/claude-cwd-${SESSION_ID}"
