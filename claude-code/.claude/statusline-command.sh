#!/usr/bin/env bash

input=$(cat)

# ANSI colors
RESET='\033[0m'
BOLD_WHITE='\033[1;97m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD_RED='\033[1;31m'
DIM='\033[2m'

SEP="${DIM} | ${RESET}"

# ── Row 1: Model | Thinking | Context | Total tokens | Cost ──────────────────

model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# Effort/thinking level
effort_level=$(echo "$input" | jq -r '.effort.level // empty')
thinking_enabled=$(echo "$input" | jq -r '.thinking.enabled // false')
if [ -n "$effort_level" ]; then
    thinking_val="$effort_level"
elif [ "$thinking_enabled" = "true" ]; then
    thinking_val="on"
else
    thinking_val="off"
fi

# Context used percentage
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx_used" ]; then
    ctx_used_fmt=$(printf "%.1f%%" "$ctx_used")
else
    ctx_used_fmt="0.0%"
fi

# Total input tokens
total_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
if [ "$total_tokens" -ge 1000000 ] 2>/dev/null; then
    total_fmt=$(awk -v t="$total_tokens" 'BEGIN { printf "%.1fM", t/1000000 }')
elif [ "$total_tokens" -ge 1000 ] 2>/dev/null; then
    total_fmt=$(awk -v t="$total_tokens" 'BEGIN { printf "%.1fk", t/1000 }')
else
    total_fmt="$total_tokens"
fi

cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost_raw" ]; then
    cost_val=$(awk -v c="$cost_raw" 'BEGIN { printf "$%.4f", c }')
else
    cost_val="\$0.00"
fi

row1=""
row1+="${BOLD_WHITE}Model:${RESET} ${GREEN}${model_name}${RESET}"
row1+="${SEP}${BOLD_WHITE}Thinking:${RESET} ${GREEN}${thinking_val}${RESET}"
row1+="${SEP}${BOLD_WHITE}Ctx Used:${RESET} ${GREEN}${ctx_used_fmt}${RESET}"
row1+="${SEP}${BOLD_WHITE}Total:${RESET} ${GREEN}${total_fmt}${RESET}"
row1+="${SEP}${BOLD_WHITE}Cost:${RESET} ${YELLOW}${cost_val}${RESET}"

# ── Row 2: Session (5h) | Reset | Weekly (7d) | Weekly Reset ─────────────────

# Helper: format seconds into "Xhr Ym" or "Xd Yhr Zm"
format_duration() {
    local secs=$(( $1 - $(date +%s) ))
    [ "$secs" -lt 0 ] && secs=0
    local days=$(( secs / 86400 ))
    local hrs=$(( (secs % 86400) / 3600 ))
    local mins=$(( (secs % 3600) / 60 ))
    if [ "$days" -gt 0 ]; then
        printf "%dd %dhr %dm" "$days" "$hrs" "$mins"
    else
        printf "%dhr %dm" "$hrs" "$mins"
    fi
}

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

row2=""

if [ -n "$five_pct" ]; then
    five_pct_fmt=$(printf "%.1f%%" "$five_pct")
    row2+="${BOLD_WHITE}Session:${RESET} ${GREEN}${five_pct_fmt}${RESET}"
    if [ -n "$five_resets" ]; then
        reset_fmt=$(format_duration "$five_resets")
        row2+="${SEP}${BOLD_WHITE}Reset:${RESET} ${GREEN}${reset_fmt}${RESET}"
    fi
else
    row2+="${DIM}Session: n/a${RESET}"
fi

if [ -n "$seven_pct" ]; then
    seven_pct_fmt=$(printf "%.1f%%" "$seven_pct")
    row2+="${SEP}${BOLD_WHITE}Weekly:${RESET} ${GREEN}${seven_pct_fmt}${RESET}"
    if [ -n "$seven_resets" ]; then
        weekly_reset_fmt=$(format_duration "$seven_resets")
        row2+="${SEP}${BOLD_WHITE}Weekly Reset:${RESET} ${GREEN}${weekly_reset_fmt}${RESET}"
    fi
else
    row2+="${SEP}${DIM}Weekly: n/a${RESET}"
fi

# ── Row 3: Branch/Worktree | CWD ─────────────────────────────────────────────

cwd_val=$(echo "$input" | jq -r '.cwd // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Maintain session map so set-cwd.sh can look up session_id by workspace
if [ -n "$session_id" ] && [ -n "$cwd_val" ]; then
    SESSION_MAP="/tmp/claude-sessions.json"
    existing=$(cat "$SESSION_MAP" 2>/dev/null || echo '{}')
    echo "$existing" | jq --arg dir "$cwd_val" --arg sid "$session_id" '.[$dir] = $sid' > "${SESSION_MAP}.tmp" \
        && mv "${SESSION_MAP}.tmp" "$SESSION_MAP"
fi

# Apply CWD override written by set-cwd.sh (if any); re-derive worktree info from overridden path
cwd_override=false
if [ -n "$session_id" ] && [ -f "/tmp/claude-cwd-${session_id}" ]; then
    cwd_val=$(cat "/tmp/claude-cwd-${session_id}")
    cwd_override=true
fi

if [ "$cwd_override" = true ]; then
    worktree_name=$(git -C "$cwd_val" rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null || true)
    worktree_branch=$(git -C "$cwd_val" branch --show-current 2>/dev/null || true)
else
    worktree_name=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
    worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')
fi

if [ -n "$worktree_branch" ]; then
    branch_display="$worktree_branch"
elif [ -n "$cwd_val" ]; then
    branch_display=$(git -C "$cwd_val" branch --show-current 2>/dev/null)
fi

row3=""

if [ -n "$worktree_name" ]; then
    row3+="${BOLD_WHITE}Worktree:${RESET} ${GREEN}${worktree_name}${RESET}${SEP}"
elif [ -n "$branch_display" ]; then
    row3+="${BOLD_WHITE}Branch:${RESET} ${GREEN}${branch_display}${RESET}${SEP}"
fi

if [ -n "$cwd_val" ]; then
    short_cwd="${cwd_val/#$HOME/\~}"
    row3+="${BOLD_WHITE}CWD:${RESET} ${GREEN}${short_cwd}${RESET}"
fi

printf "%b\n%b\n%b\n" "${row1}" "${row2}" "${row3}"
