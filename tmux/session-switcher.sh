#!/usr/bin/env bash
set -euo pipefail

# Floating session switcher for tmux (bound to prefix + j)
# - Current session listed first, in bold
# - Enter on the current session or Esc closes the popup, no switch
# - Enter on another session switches to it

if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed"
    echo "Install with: brew install fzf"
    exit 1
fi

current_session=$(tmux display-message -p '#S')
other_sessions=$(tmux list-sessions -F '#S' | grep -v -F -x -e "$current_session" || true)

session_list=$(printf '\033[1m%s\033[0m\n' "$current_session")
while IFS= read -r session; do
    [ -n "$session" ] && session_list+=$'\n'"$session"
done <<< "$other_sessions"

mouse_bind=()
if [ "$(tmux show-options -gv mouse)" = "on" ]; then
    mouse_bind=(--bind "left-click:accept")
fi

selected=$(echo -n "$session_list" | fzf \
    --ansi \
    --layout=reverse \
    --border=rounded \
    --prompt="Switch to session: " \
    --header="Enter: switch  |  Esc: cancel" \
    --no-info \
    "${mouse_bind[@]}" \
    || true)

[ -z "$selected" ] && exit 0

# Strip the bold ANSI codes; the current row carries no extra text marker,
# so this always recovers the real session name with no ambiguity
target_session=$(printf '%s' "$selected" | sed -E 's/\x1b\[[0-9;]*m//g')

[ "$target_session" = "$current_session" ] && exit 0

tmux switch-client -t "$target_session"
