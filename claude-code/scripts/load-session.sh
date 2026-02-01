#!/bin/bash
#
# load-session.sh - Load session data and output as JSON
#
# Usage: load-session.sh [options] [count|session-id]
#
# Options:
#   --full        Force full display mode
#   --compact     Force compact display mode
#   --summary     Force summary display mode
#   --all         Load from all branches (not just current)
#   --branch NAME Load sessions for specific branch
#
# Arguments:
#   count      Number of sessions to load (default: 1)
#   session-id Specific session ID to load
#
# Output: JSON with session data and metadata for Claude to format
#

set -e

# Parse arguments
MODE=""
TARGET=""
FILTER_BRANCH=""
ALL_BRANCHES=false

for arg in "$@"; do
  case "$arg" in
    --full)    MODE="full" ;;
    --compact) MODE="compact" ;;
    --summary) MODE="summary" ;;
    --all)     ALL_BRANCHES=true ;;
    --branch)  FILTER_BRANCH="__NEXT__" ;;
    *)
      if [ "$FILTER_BRANCH" = "__NEXT__" ]; then
        FILTER_BRANCH="$arg"
      else
        TARGET="$arg"
      fi
      ;;
  esac
done

# Default to loading 1 session
[ -z "$TARGET" ] && TARGET="1"

# Determine if target is a number or session ID
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  COUNT="$TARGET"
  SESSION_ID=""
else
  COUNT="1"
  SESSION_ID="$TARGET"
fi

# Find sessions directory
if git rev-parse --is-inside-work-tree &>/dev/null; then
  REPO_ROOT="$(cd "$(dirname "$(git rev-parse --git-common-dir)")" && pwd -P)"
  SESSIONS_DIR="$REPO_ROOT/.claude/sessions"
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
else
  SESSIONS_DIR="$(pwd -P)/.claude/sessions"
  CURRENT_BRANCH=""
fi

# Fallback to global sessions
if [ ! -d "$SESSIONS_DIR" ]; then
  SESSIONS_DIR="$HOME/.claude/sessions"
fi

# Check directory exists
if [ ! -d "$SESSIONS_DIR" ]; then
  jq -n '{error: "no_sessions_dir", message: "No sessions directory found"}'
  exit 0
fi

# Check index exists
if [ ! -f "$SESSIONS_DIR/index.json" ]; then
  jq -n '{error: "no_index", message: "No sessions index found"}'
  exit 0
fi

# Get current working directory
CWD="$(pwd -P)"

# Determine which branch to filter by
if [ -n "$FILTER_BRANCH" ] && [ "$FILTER_BRANCH" != "__NEXT__" ]; then
  TARGET_BRANCH="$FILTER_BRANCH"
elif [ "$ALL_BRANCHES" = true ]; then
  TARGET_BRANCH=""
else
  TARGET_BRANCH="$CURRENT_BRANCH"
fi

# Load specific session or latest N sessions
if [ -n "$SESSION_ID" ]; then
  # Load specific session
  SESSION_FILE="$SESSIONS_DIR/$SESSION_ID.json"
  if [ ! -f "$SESSION_FILE" ]; then
    # List available sessions for error message
    AVAILABLE=$(ls -1r "$SESSIONS_DIR"/session-*.json 2>/dev/null | head -5 | xargs -I{} basename {} .json | jq -R . | jq -s .)
    jq -n --arg id "$SESSION_ID" --argjson available "$AVAILABLE" '{
      error: "session_not_found",
      message: ("Session not found: " + $id),
      available: $available
    }'
    exit 0
  fi

  # Get file size for display mode selection
  FILE_SIZE=$(wc -c < "$SESSION_FILE" | tr -d ' ')

  # Get session branch for mismatch detection
  SESSION_BRANCH=$(jq -r '.git_branch // "unknown"' "$SESSION_FILE")
  SESSION_DIR=$(jq -r '.working_directory // ""' "$SESSION_FILE")

  # Check for branch/directory mismatch
  BRANCH_MISMATCH=false
  DIR_MISMATCH=false
  [ -n "$CURRENT_BRANCH" ] && [ "$SESSION_BRANCH" != "$CURRENT_BRANCH" ] && BRANCH_MISMATCH=true
  [ -n "$SESSION_DIR" ] && [ "$SESSION_DIR" != "$CWD" ] && DIR_MISMATCH=true

  # Output single session
  jq -n \
    --arg mode "$MODE" \
    --arg cwd "$CWD" \
    --arg current_branch "$CURRENT_BRANCH" \
    --arg session_branch "$SESSION_BRANCH" \
    --arg session_dir "$SESSION_DIR" \
    --argjson branch_mismatch "$BRANCH_MISMATCH" \
    --argjson dir_mismatch "$DIR_MISMATCH" \
    --argjson size "$FILE_SIZE" \
    --argjson count 1 \
    --slurpfile session "$SESSION_FILE" \
    '{
      mode: (if $mode != "" then $mode else null end),
      cwd: $cwd,
      current_branch: $current_branch,
      count: $count,
      branch_mismatch: $branch_mismatch,
      dir_mismatch: $dir_mismatch,
      mismatch_info: (if $branch_mismatch or $dir_mismatch then {
        current_branch: $current_branch,
        session_branch: $session_branch,
        current_dir: $cwd,
        session_dir: $session_dir
      } else null end),
      sessions: [{
        data: $session[0],
        file_size: $size,
        completed_count: ($session[0].completed | length),
        remaining_count: ($session[0].remaining | length)
      }]
    }'
else
  # Load latest N sessions, optionally filtered by branch
  INDEX_FILE="$SESSIONS_DIR/index.json"

  # If filtering by branch and not loading all, try to use latest_by_branch first
  if [ -n "$TARGET_BRANCH" ] && [ "$COUNT" = "1" ]; then
    # Try to get latest session for this specific branch from latest_by_branch
    BRANCH_LATEST=$(jq -r --arg branch "$TARGET_BRANCH" '.latest_by_branch[$branch] // empty' "$INDEX_FILE" 2>/dev/null)

    if [ -n "$BRANCH_LATEST" ]; then
      SESSION_FILE="$SESSIONS_DIR/$BRANCH_LATEST.json"
      if [ -f "$SESSION_FILE" ]; then
        FILE_SIZE=$(wc -c < "$SESSION_FILE" | tr -d ' ')
        SESSION_BRANCH=$(jq -r '.git_branch // "unknown"' "$SESSION_FILE")
        SESSION_DIR=$(jq -r '.working_directory // ""' "$SESSION_FILE")

        # No mismatch since we're loading the correct branch
        jq -n \
          --arg mode "$MODE" \
          --arg cwd "$CWD" \
          --arg current_branch "$CURRENT_BRANCH" \
          --arg target_branch "$TARGET_BRANCH" \
          --argjson size "$FILE_SIZE" \
          --argjson count 1 \
          --slurpfile session "$SESSION_FILE" \
          '{
            mode: (if $mode != "" then $mode else null end),
            cwd: $cwd,
            current_branch: $current_branch,
            target_branch: $target_branch,
            count: $count,
            branch_mismatch: false,
            dir_mismatch: false,
            sessions: [{
              data: $session[0],
              file_size: $size,
              completed_count: ($session[0].completed | length),
              remaining_count: ($session[0].remaining | length)
            }]
          }'
        exit 0
      fi
    fi

    # Fallback: Try to find session by filtering sessions array (for old indexes without latest_by_branch)
    # First try to match by branch field, then by checking if project path contains the branch name
    FALLBACK_SESSION=$(jq -r --arg branch "$TARGET_BRANCH" \
      '[.sessions[] | select(.branch == $branch)] | .[0].id // empty' \
      "$INDEX_FILE" 2>/dev/null)

    # If no match by branch field, check if it's an old-style index (no branch field at all)
    if [ -z "$FALLBACK_SESSION" ]; then
      # Check if any sessions have branch field
      HAS_BRANCH_FIELD=$(jq -r '[.sessions[].branch // empty] | length > 0' "$INDEX_FILE" 2>/dev/null)

      if [ "$HAS_BRANCH_FIELD" = "false" ]; then
        # Old-style index without branch tracking - load the latest session
        # and let the user know this is a legacy session
        FALLBACK_SESSION=$(jq -r '.latest // .sessions[0].id // empty' "$INDEX_FILE" 2>/dev/null)
        LEGACY_MODE=true
      fi
    fi

    if [ -n "$FALLBACK_SESSION" ]; then
      SESSION_FILE="$SESSIONS_DIR/$FALLBACK_SESSION.json"
      if [ -f "$SESSION_FILE" ]; then
        FILE_SIZE=$(wc -c < "$SESSION_FILE" | tr -d ' ')
        SESSION_BRANCH=$(jq -r '.git_branch // "unknown"' "$SESSION_FILE")
        SESSION_DIR=$(jq -r '.working_directory // ""' "$SESSION_FILE")

        # Check for mismatch in legacy mode
        BRANCH_MISMATCH=false
        DIR_MISMATCH=false
        [ -n "$CURRENT_BRANCH" ] && [ "$SESSION_BRANCH" != "$CURRENT_BRANCH" ] && [ "${LEGACY_MODE:-false}" = "true" ] && BRANCH_MISMATCH=true
        [ -n "$SESSION_DIR" ] && [ "$SESSION_DIR" != "$CWD" ] && DIR_MISMATCH=true

        jq -n \
          --arg mode "$MODE" \
          --arg cwd "$CWD" \
          --arg current_branch "$CURRENT_BRANCH" \
          --arg target_branch "$TARGET_BRANCH" \
          --arg session_branch "$SESSION_BRANCH" \
          --arg session_dir "$SESSION_DIR" \
          --argjson branch_mismatch "$BRANCH_MISMATCH" \
          --argjson dir_mismatch "$DIR_MISMATCH" \
          --argjson legacy_mode "${LEGACY_MODE:-false}" \
          --argjson size "$FILE_SIZE" \
          --argjson count 1 \
          --slurpfile session "$SESSION_FILE" \
          '{
            mode: (if $mode != "" then $mode else null end),
            cwd: $cwd,
            current_branch: $current_branch,
            target_branch: $target_branch,
            count: $count,
            branch_mismatch: $branch_mismatch,
            dir_mismatch: $dir_mismatch,
            legacy_index: $legacy_mode,
            mismatch_info: (if $branch_mismatch or $dir_mismatch then {
              current_branch: $current_branch,
              session_branch: $session_branch,
              current_dir: $cwd,
              session_dir: $session_dir
            } else null end),
            sessions: [{
              data: $session[0],
              file_size: $size,
              completed_count: ($session[0].completed | length),
              remaining_count: ($session[0].remaining | length)
            }]
          }'
        exit 0
      fi
    fi

    # No session found for this branch - show available branches
    AVAILABLE_BRANCHES=$(jq -r '(.latest_by_branch // {}) | keys[]' "$INDEX_FILE" 2>/dev/null | jq -R . | jq -s .)
    [ "$AVAILABLE_BRANCHES" = "[]" ] && AVAILABLE_BRANCHES=$(jq -r '[.sessions[].branch // empty] | unique' "$INDEX_FILE" 2>/dev/null)

    jq -n \
      --arg branch "$TARGET_BRANCH" \
      --argjson available "$AVAILABLE_BRANCHES" \
      '{
        error: "no_branch_session",
        message: ("No session found for branch: " + $branch),
        available_branches: $available
      }'
    exit 0
  fi

  # Load multiple sessions, optionally filtered by branch
  if [ -n "$TARGET_BRANCH" ]; then
    # Filter sessions by branch from index
    SESSION_IDS=$(jq -r --arg branch "$TARGET_BRANCH" --argjson count "$COUNT" \
      '[.sessions[] | select(.branch == $branch) | .id] | .[:$count] | .[]' \
      "$INDEX_FILE")
  else
    # Load latest N sessions (any branch)
    SESSION_IDS=$(jq -r --argjson count "$COUNT" \
      '[.sessions[].id] | .[:$count] | .[]' \
      "$INDEX_FILE")
  fi

  if [ -z "$SESSION_IDS" ]; then
    if [ -n "$TARGET_BRANCH" ]; then
      AVAILABLE_BRANCHES=$(jq -r '.latest_by_branch | keys[]' "$INDEX_FILE" 2>/dev/null | jq -R . | jq -s .)
      jq -n \
        --arg branch "$TARGET_BRANCH" \
        --argjson available "$AVAILABLE_BRANCHES" \
        '{
          error: "no_branch_sessions",
          message: ("No sessions found for branch: " + $branch),
          available_branches: $available
        }'
    else
      jq -n '{error: "no_sessions", message: "No session files found"}'
    fi
    exit 0
  fi

  # Build sessions array
  SESSIONS_JSON="[]"
  for sid in $SESSION_IDS; do
    SESSION_FILE="$SESSIONS_DIR/$sid.json"
    [ -f "$SESSION_FILE" ] || continue
    FILE_SIZE=$(wc -c < "$SESSION_FILE" | tr -d ' ')

    SESSION_JSON=$(jq -n \
      --argjson size "$FILE_SIZE" \
      --slurpfile session "$SESSION_FILE" \
      '{
        data: $session[0],
        file_size: $size,
        completed_count: ($session[0].completed | length),
        remaining_count: ($session[0].remaining | length)
      }')

    SESSIONS_JSON=$(echo "$SESSIONS_JSON" | jq --argjson s "$SESSION_JSON" '. + [$s]')
  done

  ACTUAL_COUNT=$(echo "$SESSIONS_JSON" | jq 'length')

  # Check for branch mismatch (only relevant if showing sessions from other branches)
  FIRST_SESSION_BRANCH=$(echo "$SESSIONS_JSON" | jq -r '.[0].data.git_branch // "unknown"')
  BRANCH_MISMATCH=false
  [ -n "$CURRENT_BRANCH" ] && [ "$FIRST_SESSION_BRANCH" != "$CURRENT_BRANCH" ] && [ "$ALL_BRANCHES" = true ] && BRANCH_MISMATCH=true

  jq -n \
    --arg mode "$MODE" \
    --arg cwd "$CWD" \
    --arg current_branch "$CURRENT_BRANCH" \
    --arg target_branch "$TARGET_BRANCH" \
    --argjson all_branches "$ALL_BRANCHES" \
    --argjson branch_mismatch "$BRANCH_MISMATCH" \
    --argjson count "$ACTUAL_COUNT" \
    --argjson sessions "$SESSIONS_JSON" \
    '{
      mode: (if $mode != "" then $mode else null end),
      cwd: $cwd,
      current_branch: $current_branch,
      target_branch: (if $target_branch != "" then $target_branch else null end),
      all_branches: $all_branches,
      branch_mismatch: $branch_mismatch,
      count: $count,
      sessions: $sessions
    }'
fi
