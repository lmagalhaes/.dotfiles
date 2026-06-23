#!/bin/bash
set -euo pipefail

# FZF-based Project Launcher for Tmux
# Provides interactive fuzzy search for project selection

PROJECTS_DIR="${HOME}/.dotfiles/tmux/projects"
LAUNCHER="${HOME}/.dotfiles/tmux/project-launcher.sh"
PREVIEW_WRAPPER="${HOME}/.dotfiles/tmux/project-preview-wrapper.sh"

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed"
    echo "Install with: brew install fzf"
    exit 1
fi

# Create temporary mapping file
tmp_map=$(mktemp)
trap "rm -f $tmp_map" EXIT

# Build project list for fzf and mapping
project_list=""
for file in "$PROJECTS_DIR"/*.sh; do
    [ -f "$file" ] || continue
    [[ "$(basename "$file")" == "template.sh"* ]] && continue

    # Source project config
    source "$file"

    # Default category if not set
    CATEGORY="${PROJECT_CATEGORY:-Uncategorized}"

    # Display format (no pipe visible)
    display="[${CATEGORY}] ${PROJECT_DESCRIPTION} (${PROJECT_KEY})"
    project_list+="${display}"$'\n'

    # Save mapping: display -> project_name
    echo "${display}|${PROJECT_NAME}" >> "$tmp_map"
done

# Use fzf to select project
selected=$(echo -n "$project_list" | fzf \
    --height=40% \
    --layout=reverse \
    --border=rounded \
    --prompt="Select Project: " \
    --header="Use fuzzy search to filter projects" \
    --preview="bash -c '$PREVIEW_WRAPPER \"\$1\" $tmp_map' _ {}" \
    --preview-window=right:50%:wrap \
    --bind='ctrl-/:toggle-preview' \
    --no-info \
    --color='bg+:yellow,fg+:white' \
    --color='pointer:white,marker:white,prompt:yellow' \
    || exit 0)

# Look up project name from selection
if [ -n "$selected" ]; then
    project_name=$(grep -F "$selected" "$tmp_map" | cut -d'|' -f2)
    if [ -n "$project_name" ]; then
        "$LAUNCHER" "$project_name"
    fi
fi
