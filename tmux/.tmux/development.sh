#!/bin/bash
set -euo pipefail

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
    echo "Usage: development.sh <project>"
    echo "Projects: crew-api | core | web-app | web-app-v2"
    exit 1
fi

WORKYARD_DIR="$HOME/workspace/workyard"
DEV_ENV="$WORKYARD_DIR/dev-env"

session="dev-${PROJECT}"

# Project config
root=""
run_cmd=""
case "$PROJECT" in
    crew-api)
        root="$DEV_ENV/workyard-api"
        run_cmd="task start:crew-api"
        ;;
    core)
        root="$DEV_ENV/core"
        run_cmd="task start:core"
        ;;
    web-app)
        root="$DEV_ENV/workyard-app"
        run_cmd="task start:web-app"
        ;;
    web-app-v2)
        root="$DEV_ENV/workyard-app2"
        run_cmd="task start:web-app-v2"
        ;;
    *)
        echo "Unknown project: $PROJECT"
        exit 1
        ;;
esac
#
window_exists() {
    tmux list-windows -t "$session" -F '#{window_name}' | grep -qx "$1"
}
#
ensure_window() {
    local name="$1" dir="$2" cmd="${3:-}"
    if ! window_exists "$name"; then
        tmux new-window -t "$session" -n "$name" -c "$dir"
        [ -n "$cmd" ] && tmux send-keys -t "$session:$name" "$cmd" C-m
    fi
}
#
# 1) Ensure session exists
tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s "$session" -c "$root"
#
# 2) Ensure a clean base window name (first window always exists)
tmux rename-window -t "$session:1" "editor" 2>/dev/null || true
# Optionally start editor only if this is a new session (simpler: always leave it to you)
#
# 3) Ensure the standard windows
ensure_window "runtime" "$root" "$run_cmd"
ensure_window "logs"    "$root" "tail -f logs/* 2>/dev/null || clear"
ensure_window "shell"   "$root"
#
# Optional: split editor window once (only if 1 pane)
if [ "$(tmux list-panes -t "$session:editor" 2>/dev/null | wc -l | tr -d ' ')" = "1" ]; then
    tmux split-window -h -t "$session:editor" -c "$root"
fi
#
tmux select-window -t "$session:editor"
#
# 4) Attach/switch
if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
else
    tmux attach -t "$session"
fi
