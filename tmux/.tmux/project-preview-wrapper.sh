#!/bin/bash
# Wrapper for project preview that looks up project name from display

DISPLAY_NAME="$1"
MAP_FILE="$2"
PREVIEW_SCRIPT="${HOME}/.dotfiles/tmux/project-preview.sh"

# Look up project name from display name
PROJECT_NAME=$(grep -F "$DISPLAY_NAME" "$MAP_FILE" | cut -d'|' -f2)

if [ -n "$PROJECT_NAME" ]; then
    "$PREVIEW_SCRIPT" "${DISPLAY_NAME}|${PROJECT_NAME}"
else
    echo "Project not found"
fi
