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

# One tmux invocation instead of three separate ones — each client call pays
# a fixed ~30-50ms fork/socket cost, which added up to noticeable popup lag
mapfile -t tmux_out < <(tmux display-message -p '#S' \; show-options -gv mouse \; list-sessions -F $'#{session_last_attached}\t#{session_name}')
current_session="${tmux_out[0]}"
mouse_opt="${tmux_out[1]}"
session_lines=("${tmux_out[@]:2}")

# Most-recently-attached session first, excluding the current one
sorted_sessions=$(printf '%s\n' "${session_lines[@]}" | sort -t $'\t' -k1,1 -rn)

# "* " marks the current session; other rows get a matching two-column
# blank prefix so names stay aligned
session_list=$(printf '\033[1m* %s\033[0m\n' "$current_session")
while IFS=$'\t' read -r _ session; do
    [ "$session" != "$current_session" ] && session_list+=$'\n'"  $session"
done <<< "$sorted_sessions"

mouse_bind=()
if [ "$mouse_opt" = "on" ]; then
    mouse_bind=(--bind "left-click:accept")
fi

selected=$(echo -n "$session_list" | fzf \
    --ansi \
    --layout=reverse \
    --border=rounded \
    --prompt="Switch to session: " \
    --header=$'Enter: switch  |  Esc: cancel  |  Ctrl-j/k: move\n' \
    --no-info \
    "${mouse_bind[@]}" \
    || true)

[ -z "$selected" ] && exit 0

# Strip the bold ANSI codes and the leading two-column marker ("* " or "  ")
clean_selected=$(printf '%s' "$selected" | sed -E 's/\x1b\[[0-9;]*m//g')
target_session="${clean_selected#??}"

[ "$target_session" = "$current_session" ] && exit 0

tmux switch-client -t "$target_session"
