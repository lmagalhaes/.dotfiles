#!/bin/bash
set -euo pipefail

# FZF-based Project Launcher for Tmux
# Provides interactive fuzzy search for project selection

PROJECTS_DIR="${HOME}/.dotfiles/tmux/projects"
LAUNCHER="${HOME}/.dotfiles/tmux/project-launcher.sh"

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed"
    echo "Install with: brew install fzf"
    exit 1
fi

# Build project list for fzf
project_list=""
for file in "$PROJECTS_DIR"/*.sh; do
    [ -f "$file" ] || continue
    [[ "$(basename "$file")" == "template.sh"* ]] && continue

    # Source project config
    source "$file"

    # Default category if not set
    CATEGORY="${PROJECT_CATEGORY:-Uncategorized}"

    # Format: [Category] Description (key) | project_name
    project_list+="[${CATEGORY}] ${PROJECT_DESCRIPTION} (${PROJECT_KEY})|${PROJECT_NAME}"$'\n'
done

# Use fzf to select project
selected=$(echo -n "$project_list" | fzf \
    --height=40% \
    --layout=reverse \
    --border=rounded \
    --prompt="Select Project: " \
    --header="Use fuzzy search to filter projects" \
    --delimiter="|" \
    --with-nth=1 \
    --no-info \
    --color='fg:#d0d0d0,bg:#1c1c1c,hl:#5f87af' \
    --color='fg+:#ffffff,bg+:#262626,hl+:#5fd7ff' \
    --color='info:#afaf87,prompt:#d7005f,pointer:#af5fff' \
    --color='marker:#87ff00,spinner:#af5fff,header:#87afaf' \
    || exit 0)

# Extract project name from selection
if [ -n "$selected" ]; then
    project_name=$(echo "$selected" | cut -d'|' -f2)
    "$LAUNCHER" "$project_name"
fi
