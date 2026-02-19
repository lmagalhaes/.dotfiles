#!/usr/bin/env bash

# Read JSON input
input=$(cat)

# Extract session_id and default working directory (suppress errors)
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
default_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)

# Fallback to PWD if no valid input
if [ -z "$default_dir" ]; then
    default_dir="$PWD"
fi

# Write session mapping: workspace -> session_id (for multi-instance support)
session_map="/tmp/claude-sessions.json"
if [ -n "$session_id" ] && [ -n "$default_dir" ]; then
    # Create or update the session map (suppress errors)
    if [ -f "$session_map" ]; then
        jq --arg dir "$default_dir" --arg sid "$session_id" '.[$dir] = $sid' "$session_map" > "${session_map}.tmp" 2>/dev/null && mv "${session_map}.tmp" "$session_map"
    else
        jq -n --arg dir "$default_dir" --arg sid "$session_id" '{($dir): $sid}' > "$session_map" 2>/dev/null
    fi
fi

# Check for session-specific cwd override
state_file="/tmp/claude-cwd-${session_id}"
if [ -n "$session_id" ] && [ -f "$state_file" ]; then
    current_dir=$(cat "$state_file")
else
    current_dir="$default_dir"
fi

# Get username and hostname
user=$(whoami)
host=$(hostname -s)

# Detect worktree name if in a worktree
worktree_name=""
if [[ "$current_dir" == *".worktrees/"* ]]; then
    after_worktrees="${current_dir#*/.worktrees/}"
    worktree_name="${after_worktrees%%/*}"
fi

# Get git branch if in a git repository
git_info=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        # Check for dirty state
        if ! git -C "$current_dir" --no-optional-locks diff --quiet 2>/dev/null || ! git -C "$current_dir" --no-optional-locks diff --cached --quiet 2>/dev/null; then
            dirty="*"
        else
            dirty=""
        fi

        # Check for untracked files
        if [ -n "$(git -C "$current_dir" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
            untracked="%"
        else
            untracked=""
        fi

        # Build git info based on worktree status
        if [ -n "$worktree_name" ] && [ "$worktree_name" != "$branch" ]; then
            # In worktree with different branch name
            git_info=" [${worktree_name}→${branch}${dirty}${untracked}]"
        else
            # Not in worktree, or worktree name matches branch
            git_info=" [${branch}${dirty}${untracked}]"
        fi
    fi
fi

# Abbreviate path
display_path="$current_dir"
home_dir="$HOME"

# Strip .worktrees/name from path if in a worktree (show repo only)
if [[ "$display_path" == *"/.worktrees/"* ]]; then
    display_path="${display_path%/.worktrees/*}"
fi

# Apply home/workspace abbreviations
if [[ "$display_path" == "$home_dir/workspace/workyard/"* ]]; then
    display_path="~/@wy/${display_path#$home_dir/workspace/workyard/}"
elif [[ "$display_path" == "$home_dir/workspace/lmagalhaes/"* ]]; then
    display_path="~/@lm/${display_path#$home_dir/workspace/lmagalhaes/}"
elif [[ "$display_path" == "$home_dir/"* ]]; then
    display_path="~/${display_path#$home_dir/}"
elif [[ "$display_path" == "$home_dir" ]]; then
    display_path="~"
fi

# Build the prompt with colors
# Green for username, Cyan for hostname, Light Blue for path, Yellow for git
printf "\033[0;32m%s\033[0m@\033[0;36m%s\033[0m:\033[1;34m%s\033[0m" "$user" "$host" "$display_path"

if [ -n "$git_info" ]; then
    printf "\033[1;33m%s\033[0m" "$git_info"
fi