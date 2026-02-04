#!/usr/bin/env bash

# Read JSON input
input=$(cat)

# Extract session_id and default working directory
session_id=$(echo "$input" | jq -r '.session_id // empty')
default_dir=$(echo "$input" | jq -r '.workspace.current_dir')

# Write session mapping: workspace -> session_id (for multi-instance support)
session_map="/tmp/claude-sessions.json"
if [ -n "$session_id" ] && [ -n "$default_dir" ]; then
    # Create or update the session map
    if [ -f "$session_map" ]; then
        # Update existing map
        jq --arg dir "$default_dir" --arg sid "$session_id" '.[$dir] = $sid' "$session_map" > "${session_map}.tmp" && mv "${session_map}.tmp" "$session_map"
    else
        # Create new map
        jq -n --arg dir "$default_dir" --arg sid "$session_id" '{($dir): $sid}' > "$session_map"
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

# Determine repo name and worktree info
repo_name=""
worktree_name=""
display_path=""

if [[ "$current_dir" == *".worktrees/"* ]]; then
    # In a worktree: extract repo name and worktree name
    # Path like: /path/to/repo/.worktrees/worktree-name or /path/to/repo/.worktrees/worktree-name/subdir
    repo_path="${current_dir%%.worktrees/*}"
    repo_name=$(basename "$repo_path")

    # Extract worktree name (first component after .worktrees/)
    after_worktrees="${current_dir#*/.worktrees/}"
    worktree_name="${after_worktrees%%/*}"

    # Check if we're in a subdirectory of the worktree
    if [[ "$after_worktrees" == *"/"* ]]; then
        subdir="/${after_worktrees#*/}"
    else
        subdir=""
    fi

    display_path="${repo_name}/${worktree_name}${subdir}"
else
    # Not in a worktree: just show repo name (or dir name if not a git repo)
    repo_name=$(basename "$current_dir")
    display_path="$repo_name"
fi

# Get git branch if in a git repository
branch=""
dirty=""
untracked=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        # Check for dirty state
        if ! git -C "$current_dir" --no-optional-locks diff --quiet 2>/dev/null || ! git -C "$current_dir" --no-optional-locks diff --cached --quiet 2>/dev/null; then
            dirty="*"
        fi

        # Check for untracked files
        if [ -n "$(git -C "$current_dir" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
            untracked="%"
        fi
    fi
fi

# Build git info: only show branch if different from worktree name
git_info=""
if [ -n "$branch" ]; then
    if [ -n "$worktree_name" ] && [ "$branch" = "$worktree_name" ]; then
        # Branch matches worktree name, only show dirty/untracked indicators
        if [ -n "$dirty" ] || [ -n "$untracked" ]; then
            git_info=" ${dirty}${untracked}"
        fi
    else
        # Branch differs from worktree name (or not in worktree), show full branch
        git_info=" [${branch}${dirty}${untracked}]"
    fi
fi

# Build the prompt with colors
# Green for username, Cyan for hostname, Light Blue for path, Yellow for git
printf "\033[0;32m%s\033[0m@\033[0;36m%s\033[0m:\033[1;34m%s\033[0m" "$user" "$host" "$display_path"

if [ -n "$git_info" ]; then
    printf "\033[1;33m%s\033[0m" "$git_info"
fi