#!/usr/bin/env bash
# Search across worktree documentation directories
# Usage: docs-search.sh <pattern> [options]

set -euo pipefail

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_git-helpers.sh
source "${SCRIPT_DIR}/_git-helpers.sh"

# Default options
FILTER="all"           # all, active, completed
SPECIFIC_BRANCH=""
IGNORE_CASE=""
CONTEXT_LINES=2
PATTERN=""
INCLUDE_SHARED="yes"

# Show usage
show_usage() {
    cat <<EOF
Usage: docs-search.sh <pattern> [options]

Search across worktree documentation for patterns.

Arguments:
  pattern           Text or regex pattern to search for

Options:
  --active          Only search active worktrees
  --completed       Only search completed worktrees
  --all             Search all worktrees (default)
  --branch NAME     Search specific branch only
  --no-shared       Exclude shared/ directory from search
  -i, --ignore-case Case insensitive search
  -C NUM            Lines of context (default: 2)
  -h, --help        Show this help

Examples:
  docs-search.sh "database schema"              # Search all worktrees
  docs-search.sh "API endpoint" --active        # Only active worktrees
  docs-search.sh "auth" --branch PLA-123        # Specific branch
  docs-search.sh -i "error" -C 3                # Case insensitive, 3 lines context

Output:
  Results grouped by branch/worktree with file names and line numbers
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --active)
            FILTER="active"
            shift
            ;;
        --completed)
            FILTER="completed"
            shift
            ;;
        --all)
            FILTER="all"
            shift
            ;;
        --branch)
            SPECIFIC_BRANCH="$2"
            shift 2
            ;;
        --no-shared)
            INCLUDE_SHARED="no"
            shift
            ;;
        -i|--ignore-case)
            IGNORE_CASE="-i"
            shift
            ;;
        -C)
            CONTEXT_LINES="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option '$1'"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$PATTERN" ]]; then
                PATTERN="$1"
            else
                echo "Error: Multiple patterns not supported"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate pattern provided
if [[ -z "$PATTERN" ]]; then
    echo "Error: Pattern required"
    show_usage
    exit 1
fi

# Get docs directory
DOCS_DIR="$("${SCRIPT_DIR}/project-docs.sh" docs-dir)"

if [[ ! -d "$DOCS_DIR" ]]; then
    echo "No documentation directory found"
    exit 1
fi

# Get list of branches to search
BRANCHES_TO_SEARCH=()

if [[ -n "$SPECIFIC_BRANCH" ]]; then
    # Search specific branch only
    if [[ -d "${DOCS_DIR}/${SPECIFIC_BRANCH}" ]]; then
        BRANCHES_TO_SEARCH+=("$SPECIFIC_BRANCH")
    else
        echo "Error: Branch docs not found: ${SPECIFIC_BRANCH}"
        exit 1
    fi
else
    # Get branches based on filter
    case "$FILTER" in
        active)
            # Get active worktrees from index
            ACTIVE_JSON=$("${SCRIPT_DIR}/manage-docs-index.sh" list-active 2>/dev/null || echo "[]")
            while IFS= read -r branch; do
                [[ -n "$branch" ]] && BRANCHES_TO_SEARCH+=("$branch")
            done < <(echo "$ACTIVE_JSON" | jq -r '.[].branch // empty')
            ;;
        completed)
            # Get completed worktrees from index
            ALL_JSON=$("${SCRIPT_DIR}/manage-docs-index.sh" list-all 2>/dev/null || echo "[]")
            while IFS= read -r branch; do
                [[ -n "$branch" ]] && BRANCHES_TO_SEARCH+=("$branch")
            done < <(echo "$ALL_JSON" | jq -r '.[] | select(.completed == true) | .branch // empty')
            ;;
        all)
            # Get all branch directories
            while IFS= read -r dir; do
                branch="$(basename "$dir")"
                # Skip non-directories and shared
                [[ "$branch" != "shared" ]] && BRANCHES_TO_SEARCH+=("$branch")
            done < <(find "$DOCS_DIR" -mindepth 1 -maxdepth 1 -type d -not -name "shared" | sort)
            ;;
    esac
fi

# Add shared directory if requested
SHARED_DIR="${DOCS_DIR}/shared"
SEARCH_SHARED="no"
if [[ "$INCLUDE_SHARED" == "yes" ]] && [[ -d "$SHARED_DIR" ]]; then
    SEARCH_SHARED="yes"
fi

# Check if we have anything to search
TOTAL_TARGETS=${#BRANCHES_TO_SEARCH[@]}
if [[ "$SEARCH_SHARED" == "yes" ]]; then
    TOTAL_TARGETS=$((TOTAL_TARGETS + 1))
fi

if [[ $TOTAL_TARGETS -eq 0 ]]; then
    echo "No documentation directories found to search"
    exit 0
fi

# Perform search
FOUND_RESULTS="no"

# Search each branch
for branch in "${BRANCHES_TO_SEARCH[@]}"; do
    BRANCH_DIR="${DOCS_DIR}/${branch}"

    # Search for pattern in this branch's docs
    if [[ -d "$BRANCH_DIR" ]]; then
        # Use grep with context
        GREP_RESULTS=$(grep -r -n $IGNORE_CASE -C "$CONTEXT_LINES" "$PATTERN" "$BRANCH_DIR" 2>/dev/null || true)

        if [[ -n "$GREP_RESULTS" ]]; then
            if [[ "$FOUND_RESULTS" == "no" ]]; then
                echo "# Documentation Search Results"
                echo ""
                echo "Pattern: \"$PATTERN\""
                echo "Filter: $FILTER"
                echo ""
                FOUND_RESULTS="yes"
            fi

            echo "## Branch: $branch"
            echo ""

            # Get ticket info if available
            INDEX_FILE="${BRANCH_DIR}/index.md"
            if [[ -f "$INDEX_FILE" ]]; then
                TICKET_ID=$(grep -m 1 "^\*\*Ticket ID:\*\*" "$INDEX_FILE" 2>/dev/null | sed 's/^\*\*Ticket ID:\*\* //' || echo "")
                if [[ -n "$TICKET_ID" ]]; then
                    echo "_Ticket: ${TICKET_ID}_"
                    echo ""
                fi
            fi

            # Format grep results
            # Replace full path with relative file name
            echo "$GREP_RESULTS" | sed "s|${BRANCH_DIR}/||g" | sed 's/^/  /'
            echo ""
        fi
    fi
done

# Search shared directory
if [[ "$SEARCH_SHARED" == "yes" ]]; then
    GREP_RESULTS=$(grep -r -n $IGNORE_CASE -C "$CONTEXT_LINES" "$PATTERN" "$SHARED_DIR" 2>/dev/null || true)

    if [[ -n "$GREP_RESULTS" ]]; then
        if [[ "$FOUND_RESULTS" == "no" ]]; then
            echo "# Documentation Search Results"
            echo ""
            echo "Pattern: \"$PATTERN\""
            echo ""
            FOUND_RESULTS="yes"
        fi

        echo "## Shared Documentation"
        echo ""
        echo "$GREP_RESULTS" | sed "s|${SHARED_DIR}/||g" | sed 's/^/  /'
        echo ""
    fi
fi

# No results found
if [[ "$FOUND_RESULTS" == "no" ]]; then
    echo "No matches found for pattern: \"$PATTERN\""
    echo ""
    echo "Searched:"
    echo "  - ${#BRANCHES_TO_SEARCH[@]} worktree(s)"
    [[ "$SEARCH_SHARED" == "yes" ]] && echo "  - Shared documentation"
    exit 0
fi

# Summary
echo "---"
echo ""
echo "Searched ${#BRANCHES_TO_SEARCH[@]} worktree(s)"
[[ "$SEARCH_SHARED" == "yes" ]] && echo "Searched shared documentation"
