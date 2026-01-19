#!/bin/bash
# Preview script for fzf project selection
# Shows detailed project information

PROJECT_INFO="$1"
PROJECT_NAME=$(echo "$PROJECT_INFO" | cut -d'|' -f2)
PROJECTS_DIR="${HOME}/.dotfiles/tmux/projects"

# Load project config
if [ -f "$PROJECTS_DIR/${PROJECT_NAME}.sh" ]; then
    source "$PROJECTS_DIR/${PROJECT_NAME}.sh"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Project: $PROJECT_DESCRIPTION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Category:     $PROJECT_CATEGORY"
    echo "Key:          $PROJECT_KEY"
    echo "Session:      dev-$PROJECT_NAME"
    echo "Path:         $PROJECT_ROOT"

    if [ -n "$PROJECT_CMD" ]; then
        echo "Command:      $PROJECT_CMD"
    else
        echo "Command:      (none)"
    fi

    echo ""
    echo "Windows:"
    echo "  • editor    (2 panes)"
    [ "${SKIP_RUNTIME:-false}" != "true" ] && echo "  • runtime   (runs command)"
    [ "${SKIP_LOGS:-false}" != "true" ] && echo "  • logs      (tail -f logs/*)"
    [ "${SKIP_SHELL:-false}" != "true" ] && echo "  • shell     (terminal)"

    # Check if session already exists
    if tmux has-session -t "dev-$PROJECT_NAME" 2>/dev/null; then
        echo ""
        echo "Status:       ✓ Session already exists"
    else
        echo ""
        echo "Status:       ⊕ Will create new session"
    fi
else
    echo "Project not found: $PROJECT_NAME"
fi
