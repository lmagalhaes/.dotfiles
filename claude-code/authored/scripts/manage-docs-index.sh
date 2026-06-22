#!/usr/bin/env bash
# Manage master docs index.md for project documentation
# Usage: manage-docs-index.sh <command> [args...]

set -euo pipefail

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_git-helpers.sh
source "${SCRIPT_DIR}/_git-helpers.sh"

# Get docs directory using project-docs.sh
get_docs_dir() {
    "${SCRIPT_DIR}/project-docs.sh" docs-dir
}

# Get current date in YYYY-MM-DD format
get_date() {
    date +%Y-%m-%d
}

# Create initial index.md with template
cmd_init() {
    local docs_dir
    docs_dir="$(get_docs_dir)"
    local index_file="${docs_dir}/index.md"

    if [[ -f "${index_file}" ]]; then
        echo "Index already exists at: ${index_file}"
        return 1
    fi

    mkdir -p "${docs_dir}"

    cat > "${index_file}" <<'EOF'
# Project Docs Index
_Last updated: DATE_PLACEHOLDER_

## Active Worktrees

## Completed Worktrees

## Shared
- [shared/](shared/) - Project-wide knowledge (patterns, ADRs, gotchas)
EOF

    # Update timestamp
    sed -i.bak "s/DATE_PLACEHOLDER_/$(get_date)/" "${index_file}"
    rm -f "${index_file}.bak"

    echo "Created index at: ${index_file}"
}

# Update the "Last updated" timestamp
cmd_update_timestamp() {
    local docs_dir
    docs_dir="$(get_docs_dir)"
    local index_file="${docs_dir}/index.md"

    if [[ ! -f "${index_file}" ]]; then
        echo "Index not found: ${index_file}"
        return 1
    fi

    # Update timestamp line
    sed -i.bak "s/^_Last updated:.*/_Last updated: $(get_date)_/" "${index_file}"
    rm -f "${index_file}.bak"

    echo "Updated timestamp in: ${index_file}"
}

# Add entry to Active Worktrees section
cmd_add_active() {
    local branch="$1"
    local ticket_id="$2"
    local summary="$3"

    local docs_dir
    docs_dir="$(get_docs_dir)"
    local index_file="${docs_dir}/index.md"

    # Create index if it doesn't exist
    if [[ ! -f "${index_file}" ]]; then
        cmd_init
    fi

    # Check if entry already exists
    if grep -q "^\- \*\*\[${branch}/\]" "${index_file}"; then
        echo "Entry for '${branch}' already exists in index"
        return 1
    fi

    # Create the new entry
    local entry="- **[${branch}/](${branch}/)** \`${ticket_id}\` - ${summary}"

    # Use awk to insert after "## Active Worktrees" line
    awk -v entry="${entry}" '
        /^## Active Worktrees/ {
            print
            getline
            if ($0 ~ /^$/) {
                print entry
            } else {
                print entry
                print
            }
            next
        }
        { print }
    ' "${index_file}" > "${index_file}.tmp"

    mv "${index_file}.tmp" "${index_file}"

    # Update timestamp
    cmd_update_timestamp > /dev/null

    echo "Added '${branch}' to Active Worktrees"
}

# Move entry from Active to Completed (append ✓)
cmd_mark_complete() {
    local branch="$1"

    local docs_dir
    docs_dir="$(get_docs_dir)"
    local index_file="${docs_dir}/index.md"

    if [[ ! -f "${index_file}" ]]; then
        echo "Index not found: ${index_file}"
        return 1
    fi

    # Check if entry exists in Active section
    if ! grep -q "^\- \*\*\[${branch}/\]" "${index_file}"; then
        echo "Entry for '${branch}' not found in Active Worktrees"
        return 1
    fi

    # Extract the entry and append ✓
    local entry
    entry="$(grep "^\- \*\*\[${branch}/\]" "${index_file}") ✓"

    # Remove from Active section and add to Completed section
    awk -v branch="${branch}" -v entry="${entry}" '
        BEGIN { in_active = 0; in_completed = 0; active_done = 0; completed_done = 0 }

        /^## Active Worktrees/ { in_active = 1; in_completed = 0; print; next }
        /^## Completed Worktrees/ {
            in_active = 0
            in_completed = 1
            active_done = 1
            print
            getline
            if ($0 ~ /^$/ || $0 ~ /^## /) {
                print entry
                if ($0 !~ /^$/) print
            } else {
                print entry
                print
            }
            completed_done = 1
            next
        }
        /^## / { in_active = 0; in_completed = 0 }

        # Skip the line if it matches the branch in Active section
        in_active && $0 ~ "^- \\*\\*\\[" branch "/\\]" { next }

        { print }
    ' "${index_file}" > "${index_file}.tmp"

    mv "${index_file}.tmp" "${index_file}"

    # Update timestamp
    cmd_update_timestamp > /dev/null

    echo "Moved '${branch}' to Completed Worktrees"
}

# List active worktrees (returns JSON array)
cmd_list_active() {
    local docs_dir
    docs_dir="$(get_docs_dir)"
    local index_file="${docs_dir}/index.md"

    if [[ ! -f "${index_file}" ]]; then
        echo "[]"
        return 0
    fi

    # Extract entries from Active section (BSD awk compatible)
    awk '
        BEGIN { in_active = 0; first = 1 }
        /^## Active Worktrees/ { in_active = 1; next }
        /^## / { in_active = 0 }
        in_active && /^- \*\*\[/ {
            # Extract branch: between first [ and first /]
            line = $0
            start = index(line, "[")
            if (start > 0) {
                rest = substr(line, start + 1)
                end = index(rest, "/]")
                branch = substr(rest, 1, end - 1)
            }

            # Extract ticket: between ` and `
            start = index(line, "`")
            if (start > 0) {
                rest = substr(line, start + 1)
                end = index(rest, "`")
                ticket = substr(rest, 1, end - 1)
            }

            # Extract summary: after "` - " and before optional ✓
            start = index(line, "` - ")
            if (start > 0) {
                summary = substr(line, start + 4)
                gsub(/✓$/, "", summary)
                gsub(/[ \t]+$/, "", summary)
            }

            if (first) {
                printf "["
                first = 0
            } else {
                printf ","
            }

            printf "{\"branch\":\"%s\",\"ticket\":\"%s\",\"summary\":\"%s\"}",
                   branch, ticket, summary
        }
        END { if (!first) printf "]"; else printf "[]" }
    ' "${index_file}"
}

# List all entries (active and completed) - returns JSON array
cmd_list_all() {
    local docs_dir
    docs_dir="$(get_docs_dir)"
    local index_file="${docs_dir}/index.md"

    if [[ ! -f "${index_file}" ]]; then
        echo "[]"
        return 0
    fi

    # Extract all entries (BSD awk compatible)
    awk '
        BEGIN { in_active = 0; in_completed = 0; first = 1 }
        /^## Active Worktrees/ { in_active = 1; in_completed = 0; next }
        /^## Completed Worktrees/ { in_active = 0; in_completed = 1; next }
        /^## / { in_active = 0; in_completed = 0 }

        (in_active || in_completed) && /^- \*\*\[/ {
            line = $0

            # Extract branch: between first [ and first /]
            start = index(line, "[")
            if (start > 0) {
                rest = substr(line, start + 1)
                end = index(rest, "/]")
                branch = substr(rest, 1, end - 1)
            }

            # Extract ticket: between ` and `
            start = index(line, "`")
            if (start > 0) {
                rest = substr(line, start + 1)
                end = index(rest, "`")
                ticket = substr(rest, 1, end - 1)
            }

            # Extract summary: after "` - " and before optional ✓
            start = index(line, "` - ")
            if (start > 0) {
                summary = substr(line, start + 4)
                gsub(/✓$/, "", summary)
                gsub(/[ \t]+$/, "", summary)
            }

            # Check if completed (has ✓)
            completed = (line ~ /✓$/) ? "true" : "false"

            if (first) {
                printf "["
                first = 0
            } else {
                printf ","
            }

            printf "{\"branch\":\"%s\",\"ticket\":\"%s\",\"summary\":\"%s\",\"completed\":%s}",
                   branch, ticket, summary, completed
        }
        END { if (!first) printf "]"; else printf "[]" }
    ' "${index_file}"
}

# Show usage
show_usage() {
    cat <<EOF
Usage: manage-docs-index.sh <command> [args...]

Commands:
  init                                    Create initial index.md with template
  add-active <branch> <ticket-id> <desc>  Add entry to Active Worktrees
  mark-complete <branch>                  Move entry to Completed (append ✓)
  update-timestamp                        Update "Last updated" date
  list-active                             List active worktrees (JSON)
  list-all                                List all entries (JSON)
  help                                    Show this help message

Examples:
  manage-docs-index.sh init
  manage-docs-index.sh add-active PLA-123-feature PLA-123 "Add user authentication"
  manage-docs-index.sh mark-complete PLA-123-feature
  manage-docs-index.sh list-active
EOF
}

# Main command dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local command="$1"
    shift

    case "${command}" in
        init)
            cmd_init
            ;;
        add-active)
            if [[ $# -lt 3 ]]; then
                echo "Error: add-active requires <branch> <ticket-id> <summary>"
                exit 1
            fi
            cmd_add_active "$1" "$2" "$3"
            ;;
        mark-complete)
            if [[ $# -lt 1 ]]; then
                echo "Error: mark-complete requires <branch>"
                exit 1
            fi
            cmd_mark_complete "$1"
            ;;
        update-timestamp)
            cmd_update_timestamp
            ;;
        list-active)
            cmd_list_active
            ;;
        list-all)
            cmd_list_all
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo "Error: Unknown command '${command}'"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
