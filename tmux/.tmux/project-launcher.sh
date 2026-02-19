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

# Helper functions
window_exists() {
    tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | grep -qx "$1"
}

ensure_window() {
    local name="$1" dir="$2" cmd="${3:-}"
    if ! window_exists "$name"; then
        tmux new-window -t "$session" -n "$name" -c "$dir"
        [ -n "$cmd" ] && tmux send-keys -t "$session:$name" "$cmd" C-m
    fi
}

# 1) Ensure session exists
tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s "$session" -c "$PROJECT_ROOT"

# 2) Ensure base window is named correctly
tmux rename-window -t "$session:1" "editor" 2>/dev/null || true

# 3) Create standard windows (unless disabled)
[ "${SKIP_RUNTIME:-false}" != "true" ] && ensure_window "runtime" "$PROJECT_ROOT" "$PROJECT_CMD"

# 4) Split editor window if needed (only if 1 pane)
if [ "$(tmux list-panes -t "$session:editor" 2>/dev/null | wc -l | tr -d ' ')" = "1" ]; then
    tmux split-window -h -t "$session:editor" -c "$PROJECT_ROOT"
fi

# 5) Select editor window
tmux select-window -t "$session:editor"

# 6) Attach or switch
if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
else
    tmux attach -t "$session"
fi
