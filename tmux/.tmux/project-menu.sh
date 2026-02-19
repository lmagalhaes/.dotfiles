#!/bin/bash
set -euo pipefail

# Dynamic Project Menu Builder with Category Grouping
# Scans projects directory and builds grouped tmux display-menu command

PROJECTS_DIR="${HOME}/.dotfiles/tmux/projects"
LAUNCHER="${HOME}/.dotfiles/tmux/project-launcher.sh"

# Temporary file to collect project data
tmp_file=$(mktemp)
trap "rm -f $tmp_file" EXIT

# Collect all projects with their category
for file in "$PROJECTS_DIR"/*.sh; do
    [ -f "$file" ] || continue
    [[ "$(basename "$file")" == "template.sh"* ]] && continue

    # Source project config
    source "$file"

    # Default category if not set
    CATEGORY="${PROJECT_CATEGORY:-Uncategorized}"

    # Save: category|description|key|project_name
    echo "$CATEGORY|$PROJECT_DESCRIPTION|$PROJECT_KEY|$PROJECT_NAME" >> "$tmp_file"
done

# Build menu items array
menu_items=()
menu_items+=("" "" "")  # Empty line at top

# Process each category
current_category=""
while IFS='|' read -r category description key project_name; do
    # Add category header if new category
    if [ "$category" != "$current_category" ]; then
        [ -n "$current_category" ] && menu_items+=("" "" "")  # Separator between categories
        menu_items+=("$category Projects" "" "")  # Category header (no key = disabled)
        current_category="$category"
    fi

    # Add project item
    menu_items+=("  $description" "$key" "run-shell '$LAUNCHER $project_name'")
done < <(sort -t'|' -k1,1 "$tmp_file")

# Add separator and cancel option
menu_items+=("" "" "")
menu_items+=("Cancel" "q" "")

# Build tmux display-menu command
tmux display-menu -T "Development" "${menu_items[@]}"
