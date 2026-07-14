#!/bin/bash
set -euo pipefail

# Project Session Launcher
# Usage: project-launcher.sh <project-name>
# Loads project config and creates/switches to tmux session

PROJECT_NAME="${1:-}"
PROJECTS_DIR="${HOME}/.dotfiles/tmux/projects"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: project-launcher.sh <project-name>"
    echo "Available projects:"
    for file in "$PROJECTS_DIR"/*.sh; do
        [ -f "$file" ] || continue
        [[ "$(basename "$file")" == "template.sh"* ]] && continue
        source "$file"
        echo "  - $PROJECT_NAME"
    done
    exit 1
fi

# Load project configuration
PROJECT_FILE="$PROJECTS_DIR/${PROJECT_NAME}.sh"
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project '$PROJECT_NAME' not found"
    echo "Looking for: $PROJECT_FILE"
    exit 1
fi

source "$PROJECT_FILE"

# Session name
session="${PROJECT_NAME}"

# 1) Create session if new
if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session" -c "$PROJECT_ROOT"
    tmux rename-window -t "$session:1" "editor"
    tmux split-window -h -t "$session:editor" -c "$PROJECT_ROOT"
    tmux select-pane -t "$session:editor.left"
fi

# 2) Select editor window
tmux select-window -t "$session:editor"

# 3) Attach or switch
if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
else
    tmux attach -t "$session"
fi
