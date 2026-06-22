#!/usr/bin/env bash
# Interactive worktree selector using fzf (or fallback to numbered list)
# Usage: select-worktree.sh [--exclude-main]

set -euo pipefail

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_git-helpers.sh
source "${SCRIPT_DIR}/_git-helpers.sh"

EXCLUDE_MAIN="no"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --exclude-main)
            EXCLUDE_MAIN="yes"
            shift
            ;;
        -h|--help)
            cat <<EOF
Usage: select-worktree.sh [--exclude-main]

Interactive worktree selector using fzf (or fallback).

Options:
  --exclude-main    Exclude main branch from selection
  -h, --help        Show this help

Output (JSON):
  {
    "branch": "branch-name",
    "path": "/full/path/to/worktree",
    "is_current": true/false
  }

Exit codes:
  0 - Worktree selected
  1 - No worktrees found or selection cancelled
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo '{"error": "not_in_git_repo", "message": "Not in a git repository"}' >&2
    exit 1
fi

# Get current directory and branch
CWD="$(pwd -P)"
CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || echo "")"

# Get worktree list
WORKTREE_LIST=()
WORKTREE_PATHS=()
WORKTREE_BRANCHES=()
CURRENT_INDEX=-1

# Parse git worktree list
INDEX=0
while IFS= read -r line; do
    # Format: /path/to/worktree commit-hash [branch-name]
    # Extract path (first field)
    path=$(echo "$line" | awk '{print $1}')

    # Extract branch name (between [ and ])
    branch=""
    if [[ "$line" =~ \[([^\]]+)\] ]]; then
        branch="${BASH_REMATCH[1]}"
    fi

    # Skip if no branch (detached HEAD)
    if [[ -z "$branch" ]]; then
        continue
    fi

    # Skip main branch if requested
    if [[ "$EXCLUDE_MAIN" == "yes" ]] && [[ "$branch" == "main" || "$branch" == "master" ]]; then
        continue
    fi

    # Check if this is current worktree
    IS_CURRENT=""
    if [[ "$path" == "$CWD" ]] || [[ "$branch" == "$CURRENT_BRANCH" ]]; then
        IS_CURRENT="*"
        CURRENT_INDEX=$INDEX
    fi

    WORKTREE_BRANCHES+=("$branch")
    WORKTREE_PATHS+=("$path")
    WORKTREE_LIST+=("${IS_CURRENT}${branch} → ${path}")

    INDEX=$((INDEX + 1))
done < <(git worktree list --porcelain | awk '
    /^worktree / { path = substr($0, 10); next }
    /^HEAD / { head = $2; next }
    /^branch / {
        branch = substr($0, 8)
        gsub(/^refs\/heads\//, "", branch)
        print path " " head " [" branch "]"
        path = ""
        head = ""
        branch = ""
    }
    /^$/ {
        if (path != "") {
            print path " " head " [detached]"
            path = ""
            head = ""
        }
    }
')

# Check if any worktrees found
if [[ ${#WORKTREE_LIST[@]} -eq 0 ]]; then
    echo '{"error": "no_worktrees", "message": "No worktrees found"}' >&2
    exit 1
fi

# If only one worktree and it's current, just return it
if [[ ${#WORKTREE_LIST[@]} -eq 1 ]] && [[ $CURRENT_INDEX -eq 0 ]]; then
    jq -n \
        --arg branch "${WORKTREE_BRANCHES[0]}" \
        --arg path "${WORKTREE_PATHS[0]}" \
        --argjson is_current true \
        '{branch: $branch, path: $path, is_current: $is_current}'
    exit 0
fi

# Use fzf if available
if command -v fzf &> /dev/null; then
    # Show fzf selector
    SELECTED=$(printf '%s\n' "${WORKTREE_LIST[@]}" | \
        fzf --height=40% \
            --border \
            --header="Select worktree to finish (ESC to cancel)" \
            --prompt="Worktree: " \
            --preview-window=hidden || true)

    # Check if selection was cancelled
    if [[ -z "$SELECTED" ]]; then
        echo '{"error": "cancelled", "message": "Selection cancelled"}' >&2
        exit 1
    fi

    # Find index of selected item
    SELECTED_INDEX=-1
    for i in "${!WORKTREE_LIST[@]}"; do
        if [[ "${WORKTREE_LIST[$i]}" == "$SELECTED" ]]; then
            SELECTED_INDEX=$i
            break
        fi
    done
else
    # Fallback: numbered list
    echo "Available worktrees:" >&2
    echo "" >&2
    for i in "${!WORKTREE_LIST[@]}"; do
        echo "  $((i+1)). ${WORKTREE_LIST[$i]}" >&2
    done
    echo "" >&2
    echo -n "Select worktree (1-${#WORKTREE_LIST[@]}) or 0 to cancel: " >&2
    read -r selection

    # Validate input
    if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
        echo '{"error": "invalid_input", "message": "Invalid selection"}' >&2
        exit 1
    fi

    if [[ "$selection" -eq 0 ]]; then
        echo '{"error": "cancelled", "message": "Selection cancelled"}' >&2
        exit 1
    fi

    SELECTED_INDEX=$((selection - 1))

    if [[ $SELECTED_INDEX -lt 0 ]] || [[ $SELECTED_INDEX -ge ${#WORKTREE_LIST[@]} ]]; then
        echo '{"error": "invalid_selection", "message": "Invalid selection"}' >&2
        exit 1
    fi
fi

# Output selected worktree as JSON
IS_CURRENT_FLAG="false"
if [[ $SELECTED_INDEX -eq $CURRENT_INDEX ]]; then
    IS_CURRENT_FLAG="true"
fi

jq -n \
    --arg branch "${WORKTREE_BRANCHES[$SELECTED_INDEX]}" \
    --arg path "${WORKTREE_PATHS[$SELECTED_INDEX]}" \
    --argjson is_current "$IS_CURRENT_FLAG" \
    '{branch: $branch, path: $path, is_current: $is_current}'
