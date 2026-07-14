#!/bin/bash
# Preview script for fzf project selection
# Args: <display-name> <map-file>

DISPLAY_NAME="$1"
MAP_FILE="$2"
PROJECTS_DIR="${HOME}/.dotfiles/tmux/projects"

PROJECT_NAME=$(grep -F "$DISPLAY_NAME" "$MAP_FILE" | cut -d'|' -f2)

if [ -z "$PROJECT_NAME" ] || [ ! -f "$PROJECTS_DIR/${PROJECT_NAME}.sh" ]; then
    echo "Project not found"
    exit 0
fi

source "$PROJECTS_DIR/${PROJECT_NAME}.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project: $PROJECT_DESCRIPTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Category:     $PROJECT_CATEGORY"
echo "Key:          $PROJECT_KEY"
echo "Session:      $PROJECT_NAME"
echo "Path:         $PROJECT_ROOT"
echo ""
echo "Layout:"
echo "  • editor (2 panes)"

if tmux has-session -t "$PROJECT_NAME" 2>/dev/null; then
    echo ""
    echo "Status:       ✓ Session already exists"
else
    echo ""
    echo "Status:       ⊕ Will create new session"
fi
