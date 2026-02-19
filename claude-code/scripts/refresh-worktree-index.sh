#!/usr/bin/env bash
# Refresh the file list in a worktree's index.md
# Usage: refresh-worktree-index.sh [branch]
#   - If branch provided, update that branch's docs
#   - If no branch, auto-detect from current git branch

set -euo pipefail

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_git-helpers.sh
source "${SCRIPT_DIR}/_git-helpers.sh"

# Show usage
show_usage() {
    cat <<EOF
Usage: refresh-worktree-index.sh [branch]

Scans a worktree's docs directory and updates the file list in index.md.

Arguments:
  branch      Optional branch name (e.g., PLA-123-feature)
              If omitted, auto-detects from current git branch

Examples:
  refresh-worktree-index.sh                    # Update current branch's docs
  refresh-worktree-index.sh PLA-123-feature    # Update specific branch

Note:
  - Called automatically by /wrap-session
  - Scans for *.md files (excluding index.md)
  - Extracts file descriptions from first H1 heading or summary
EOF
}

# Extract description from markdown file (first H1 or first paragraph)
extract_description() {
    local file="$1"
    local desc=""

    # Try to get first H1 heading
    desc="$(grep -m 1 '^# ' "$file" 2>/dev/null | sed 's/^# //' || true)"

    # If no H1, try first non-empty paragraph (skip frontmatter)
    if [[ -z "$desc" ]]; then
        desc="$(awk '
            /^---$/ { if (NR == 1) { in_frontmatter = 1; next } else if (in_frontmatter) { in_frontmatter = 0; next } }
            in_frontmatter { next }
            /^[[:space:]]*$/ { next }
            /^#/ { next }
            { print; exit }
        ' "$file" | head -c 100)"
    fi

    # Truncate if too long and clean up
    if [[ ${#desc} -gt 80 ]]; then
        desc="${desc:0:77}..."
    fi

    # If still empty, use filename
    if [[ -z "$desc" ]]; then
        desc="Documentation file"
    fi

    echo "$desc"
}

# Get branch name
BRANCH="${1:-}"
if [[ -z "$BRANCH" ]]; then
    # Auto-detect from current git branch
    if git rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH="$(git branch --show-current)"

        # If empty (detached HEAD), try to get from worktree path
        if [[ -z "$BRANCH" ]]; then
            echo "Error: Could not detect branch (detached HEAD?)"
            echo "Please specify branch explicitly: refresh-worktree-index.sh <branch>"
            exit 1
        fi
    else
        echo "Error: Not in a git repository"
        echo "Please specify branch: refresh-worktree-index.sh <branch>"
        exit 1
    fi
fi

# Handle --help
if [[ "$BRANCH" == "--help" ]] || [[ "$BRANCH" == "-h" ]]; then
    show_usage
    exit 0
fi

# Get docs directory
PROJECT_ROOT="$("${SCRIPT_DIR}/project-docs.sh" root)"
DOCS_DIR="$("${SCRIPT_DIR}/project-docs.sh" docs-dir)"
BRANCH_DOCS_DIR="${DOCS_DIR}/${BRANCH}"
INDEX_FILE="${BRANCH_DOCS_DIR}/index.md"

# Validate branch docs exist
if [[ ! -d "$BRANCH_DOCS_DIR" ]]; then
    echo "Error: Docs directory not found: ${BRANCH_DOCS_DIR}"
    echo "Run init-worktree-docs.sh first or specify correct branch name"
    exit 1
fi

if [[ ! -f "$INDEX_FILE" ]]; then
    echo "Error: index.md not found: ${INDEX_FILE}"
    echo "Run init-worktree-docs.sh first"
    exit 1
fi

# Scan for markdown files (exclude index.md, sort by name)
FILES=()
while IFS= read -r file; do
    FILES+=("$file")
done < <(find "$BRANCH_DOCS_DIR" -maxdepth 1 -name "*.md" -not -name "index.md" -type f | sort)

# Generate file list content
FILE_LIST=""
if [[ ${#FILES[@]} -eq 0 ]]; then
    FILE_LIST="_No additional documentation files yet_"
else
    for file in "${FILES[@]}"; do
        filename="$(basename "$file")"
        desc="$(extract_description "$file")"
        FILE_LIST+="- **[${filename}](${filename})** - ${desc}"$'\n'
    done
    # Remove trailing newline
    FILE_LIST="${FILE_LIST%$'\n'}"
fi

# Update index.md by replacing the Files section
# Strategy: Split file at "## Files", keep everything before it,
# add new Files section, skip old Files section content

# Create temporary file with updated content
TEMP_FILE="${INDEX_FILE}.tmp"

awk -v file_list="$FILE_LIST" '
    # Track if we are in the Files section
    /^## Files/ {
        in_files = 1
        print
        print "_This section is automatically updated by wrap-session_"
        print ""
        print file_list
        next
    }

    # When we hit next section header, exit Files section
    in_files && /^## / {
        in_files = 0
        print ""
        print
        next
    }

    # Skip content inside Files section
    in_files { next }

    # Print everything else
    { print }
' "$INDEX_FILE" > "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$INDEX_FILE"

# Count files for output
FILE_COUNT=${#FILES[@]}

echo "✓ Updated file list in: ${INDEX_FILE}"
echo "  Found ${FILE_COUNT} documentation file(s)"

# Show what was added (first 5 files)
if [[ $FILE_COUNT -gt 0 ]]; then
    echo ""
    echo "Files indexed:"
    head -5 <<<"$(printf '%s\n' "${FILES[@]}")" | while read -r file; do
        filename="$(basename "$file")"
        echo "  - ${filename}"
    done

    if [[ $FILE_COUNT -gt 5 ]]; then
        echo "  ... and $((FILE_COUNT - 5)) more"
    fi
fi
