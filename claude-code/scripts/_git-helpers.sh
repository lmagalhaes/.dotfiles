#!/usr/bin/env bash
#
# _git-helpers.sh - Shared git utility functions
#
# Source this file from other scripts:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
#   source "${SCRIPT_DIR}/_git-helpers.sh"
#

# Find the project root - works from main branch or any worktree.
# git-common-dir always points to the main .git regardless of worktree depth.
find_project_root() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    cd "$(dirname "$(git rev-parse --git-common-dir)")" && pwd -P
  else
    pwd -P
  fi
}

# Find the .claude/sessions directory for the current project
find_sessions_dir() {
  echo "$(find_project_root)/.claude/sessions"
}

# Find the .claude/docs directory for the current project
find_docs_dir() {
  echo "$(find_project_root)/.claude/docs"
}

# Populate BRANCH and IS_WORKTREE variables
get_git_info() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
    COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)

    # In a worktree, git-dir is an absolute path inside .git/worktrees/
    # In the main repo, git-dir is ".git" (relative) or equals common-dir
    if [ "$GIT_DIR" != "$COMMON_DIR" ] && [ "$GIT_DIR" != ".git" ]; then
      IS_WORKTREE=true
    else
      IS_WORKTREE=false
    fi
  else
    BRANCH=""
    IS_WORKTREE=false
  fi
}
