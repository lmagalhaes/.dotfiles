#!/usr/bin/env bash
#
# project-docs.sh - Project documentation path helper
#
# Usage:
#   project-docs.sh root          Print project root directory
#   project-docs.sh docs-dir      Print docs directory ({project_root}/.claude/docs)
#   project-docs.sh worktree      Print current branch name (empty if not in worktree)
#   project-docs.sh is-worktree   Print "true" or "false"
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/_git-helpers.sh"

get_worktree_name() {
  get_git_info
  if [ "$IS_WORKTREE" = "true" ]; then
    echo "$BRANCH"
  fi
}

case "${1:-root}" in
  root)
    find_project_root
    ;;
  docs-dir)
    find_docs_dir
    ;;
  worktree)
    get_worktree_name
    ;;
  is-worktree)
    get_git_info
    echo "$IS_WORKTREE"
    ;;
  *)
    echo "Usage: project-docs.sh [root|docs-dir|worktree|is-worktree]" >&2
    exit 1
    ;;
esac
