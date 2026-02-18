#!/bin/bash
#
# wrap-session.sh - Environment gathering and session saving
#
# Usage:
#   wrap-session.sh env              Output environment JSON
#   wrap-session.sh save             Write session (JSON from stdin)
#
# Env mode outputs:
#   - session_id, timestamp, working_directory
#   - git_branch, is_worktree, sessions_dir
#
# Save mode expects:
#   - Complete session JSON on stdin
#   - Writes to sessions_dir/{session_id}.json
#   - Updates index.json
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/_git-helpers.sh"

MODE="${1:-env}"

case "$MODE" in
  env)
    # Generate timestamp and session ID
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    SESSION_ID="session-$(date +"%Y-%m-%d-%H%M%S")"
    CWD="$(pwd -P)"
    SESSIONS_DIR=$(find_sessions_dir)
    get_git_info

    jq -n \
      --arg session_id "$SESSION_ID" \
      --arg timestamp "$TIMESTAMP" \
      --arg cwd "$CWD" \
      --arg branch "$BRANCH" \
      --argjson is_worktree "$IS_WORKTREE" \
      --arg sessions_dir "$SESSIONS_DIR" \
      '{
        session_id: $session_id,
        timestamp: $timestamp,
        working_directory: $cwd,
        git_branch: $branch,
        is_worktree: $is_worktree,
        sessions_dir: $sessions_dir
      }'
    ;;

  save)
    # Read session JSON from stdin
    SESSION_JSON=$(cat)

    # Extract fields from session JSON
    SESSION_ID=$(echo "$SESSION_JSON" | jq -r '.session_id')
    TIMESTAMP=$(echo "$SESSION_JSON" | jq -r '.timestamp')
    CWD=$(echo "$SESSION_JSON" | jq -r '.working_directory')
    SUMMARY=$(echo "$SESSION_JSON" | jq -r '.summary')
    BRANCH=$(echo "$SESSION_JSON" | jq -r '.git_branch // "unknown"')
    IS_WORKTREE=$(echo "$SESSION_JSON" | jq -r '.is_worktree // false')

    SESSIONS_DIR=$(find_sessions_dir)

    # Create sessions directory if needed
    mkdir -p "$SESSIONS_DIR"

    # Write session file
    SESSION_FILE="$SESSIONS_DIR/$SESSION_ID.json"
    echo "$SESSION_JSON" | jq '.' > "$SESSION_FILE"

    # Update index.json
    INDEX_FILE="$SESSIONS_DIR/index.json"

    # Create new index entry with branch info
    NEW_ENTRY=$(jq -n \
      --arg id "$SESSION_ID" \
      --arg ts "$TIMESTAMP" \
      --arg proj "$CWD" \
      --arg sum "$SUMMARY" \
      --arg branch "$BRANCH" \
      --argjson is_worktree "$IS_WORKTREE" \
      '{
        id: $id,
        timestamp: $ts,
        project: $proj,
        branch: $branch,
        is_worktree: $is_worktree,
        summary: $sum,
        archived: false
      }')

    if [ -f "$INDEX_FILE" ]; then
      # Update existing index:
      # - Add new entry at beginning
      # - Update global latest
      # - Update latest_by_branch for this branch
      UPDATED_INDEX=$(jq \
        --arg latest "$SESSION_ID" \
        --arg branch "$BRANCH" \
        --argjson entry "$NEW_ENTRY" \
        '
        .latest = $latest |
        .sessions = [$entry] + .sessions |
        .latest_by_branch[$branch] = $latest |
        # Initialize latest_by_branch if missing
        .latest_by_branch //= {}
        ' \
        "$INDEX_FILE")
      echo "$UPDATED_INDEX" | jq '.' > "$INDEX_FILE"
    else
      # Create new index with latest_by_branch
      jq -n \
        --arg latest "$SESSION_ID" \
        --arg branch "$BRANCH" \
        --argjson entry "$NEW_ENTRY" \
        '{
          latest: $latest,
          latest_by_branch: {
            ($branch): $latest
          },
          sessions: [$entry],
          archive: {
            count: 0,
            oldest_date: null
          }
        }' > "$INDEX_FILE"
    fi

    # Output result
    jq -n \
      --arg session_file "$SESSION_FILE" \
      --arg index_file "$INDEX_FILE" \
      --arg session_id "$SESSION_ID" \
      --arg branch "$BRANCH" \
      '{
        success: true,
        session_id: $session_id,
        branch: $branch,
        session_file: $session_file,
        index_file: $index_file
      }'
    ;;

  *)
    echo "Usage: wrap-session.sh [env|save]" >&2
    exit 1
    ;;
esac
