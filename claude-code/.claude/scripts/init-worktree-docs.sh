#!/usr/bin/env bash
# Initialize documentation structure for a new worktree/ticket
# Usage: init-worktree-docs.sh <branch> <ticket-id> <title> <status> <linear-url> [summary]

set -euo pipefail

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_git-helpers.sh
source "${SCRIPT_DIR}/_git-helpers.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: init-worktree-docs.sh <branch> <ticket-id> <title> <status> <linear-url> [summary]

Arguments:
  branch      Branch name (e.g., PLA-123-feature)
  ticket-id   Linear ticket ID (e.g., PLA-123)
  title       Ticket title
  status      Ticket status (e.g., In Progress, Backlog)
  linear-url  Full Linear URL to the ticket
  summary     Optional 1-2 sentence summary (if omitted, uses title)

Example:
  init-worktree-docs.sh \\
    "PLA-123-add-auth" \\
    "PLA-123" \\
    "Add user authentication" \\
    "In Progress" \\
    "https://linear.app/company/issue/PLA-123" \\
    "Implement JWT-based authentication for API endpoints"
EOF
}

# Validate arguments
if [[ $# -lt 5 ]]; then
    show_usage
    exit 1
fi

BRANCH="$1"
TICKET_ID="$2"
TITLE="$3"
STATUS="$4"
LINEAR_URL="$5"
SUMMARY="${6:-$TITLE}"

# Get project root and docs directory
PROJECT_ROOT="$("${SCRIPT_DIR}/project-docs.sh" root)"
DOCS_DIR="$("${SCRIPT_DIR}/project-docs.sh" docs-dir)"
BRANCH_DOCS_DIR="${DOCS_DIR}/${BRANCH}"

# Get current date
CURRENT_DATE="$(date +%Y-%m-%d)"

# Create branch docs directory
mkdir -p "${BRANCH_DOCS_DIR}"

# Create per-worktree index.md with ticket metadata
cat > "${BRANCH_DOCS_DIR}/index.md" <<EOF
# ${TICKET_ID}: ${TITLE}

**Ticket ID:** ${TICKET_ID}
**Status:** ${STATUS}
**Linear:** [${TICKET_ID}](${LINEAR_URL})
**Created:** ${CURRENT_DATE}

## Summary
${SUMMARY}

## Files
_This section is automatically updated by wrap-session_

EOF

echo "✓ Created docs directory: ${BRANCH_DOCS_DIR}/"
echo "✓ Created index.md with ticket metadata"

# Update master docs index
"${SCRIPT_DIR}/manage-docs-index.sh" add-active "${BRANCH}" "${TICKET_ID}" "${SUMMARY}" 2>&1 | sed 's/^/  /'

# Create symlink in worktree (if worktree exists)
WORKTREE_PATH="${PROJECT_ROOT}/.worktrees/${BRANCH}"
if [[ -d "${WORKTREE_PATH}" ]]; then
    WORKTREE_CLAUDE_DIR="${WORKTREE_PATH}/.claude"
    mkdir -p "${WORKTREE_CLAUDE_DIR}"

    # Remove existing .claude/docs if it's a directory (not a symlink)
    if [[ -d "${WORKTREE_CLAUDE_DIR}/docs" ]] && [[ ! -L "${WORKTREE_CLAUDE_DIR}/docs" ]]; then
        echo "⚠️  Warning: ${WORKTREE_CLAUDE_DIR}/docs exists as directory, removing..."
        rm -rf "${WORKTREE_CLAUDE_DIR}/docs"
    fi

    # Create symlink (relative path: ../../../.claude/docs/branch)
    if [[ ! -e "${WORKTREE_CLAUDE_DIR}/docs" ]]; then
        ln -s "../../../.claude/docs/${BRANCH}" "${WORKTREE_CLAUDE_DIR}/docs"
        echo "✓ Created symlink: ${WORKTREE_CLAUDE_DIR}/docs -> .claude/docs/${BRANCH}"
    else
        echo "  Symlink already exists: ${WORKTREE_CLAUDE_DIR}/docs"
    fi
else
    echo "  Worktree not found at: ${WORKTREE_PATH}"
    echo "  Symlink will be created when worktree is set up"
fi

# Optional: Check if ticket is already referenced in codebase
if command -v rg &> /dev/null; then
    echo ""
    echo "Scanning codebase for existing references to ${TICKET_ID}..."

    # Search for ticket ID in code (excluding .git, node_modules, vendor, etc.)
    MATCHES=$(rg --count --ignore-case "${TICKET_ID}" \
        --glob '!.git/**' \
        --glob '!node_modules/**' \
        --glob '!vendor/**' \
        --glob '!*.log' \
        --glob '!.claude/**' \
        "${PROJECT_ROOT}" 2>/dev/null || true)

    if [[ -n "${MATCHES}" ]]; then
        MATCH_COUNT=$(echo "${MATCHES}" | wc -l | tr -d ' ')
        echo "  Found ${MATCH_COUNT} file(s) with existing references:"
        echo "${MATCHES}" | head -5 | while IFS=: read -r file count; do
            rel_path="${file#${PROJECT_ROOT}/}"
            echo "    - ${rel_path} (${count} matches)"
        done

        if [[ ${MATCH_COUNT} -gt 5 ]]; then
            echo "    ... and $((MATCH_COUNT - 5)) more"
        fi

        echo ""
        echo "💡 This ticket may be a continuation of previous work"
    else
        echo "  No existing references found (new ticket)"
    fi
fi

echo ""
echo "✅ Worktree docs initialized for ${TICKET_ID}"
echo ""
echo "Next steps:"
echo "  1. Switch to worktree: cd ${WORKTREE_PATH}"
echo "  2. Create additional docs in: ${BRANCH_DOCS_DIR}/"
echo "  3. Run /wrap-session to auto-update file list"
