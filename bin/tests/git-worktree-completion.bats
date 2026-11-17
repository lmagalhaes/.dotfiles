#!/usr/bin/env bats
#
# Tests for _git_wt_use in bash/.local/share/bash-completion/completions/git-worktree-completion.bash
#

load test_helper

COMPLETION="$BIN_DIR/../bash/.local/share/bash-completion/completions/git-worktree-completion.bash"

setup() {
  setup_repo_with_worktrees
  stub_fzf
  PATH="$BIN_DIR:$PATH"
  source "$COMPLETION"
  _stub_bind
  cd "$REPO"
}

# Readline isn't active under bats; record what gets bound instead
_stub_bind() {
  BIND_CALLS="$TEST_ROOT/bind-calls"
  : > "$BIND_CALLS"
  bind() { printf '%s\n' "$*" >> "$BIND_CALLS"; }
}

# What the terminal's status reply (\e[0n) was last bound to
_status_reply_binding() {
  grep -F '"\e[0n":' "$BIND_CALLS" | tail -1
}

_complete_wt_use() {
  COMP_WORDS=(git wt-use "$@")
  COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
  COMPREPLY=()
  _git_wt_use > /dev/null
}

_complete_wt_claude() {
  COMP_WORDS=(git wt-claude "$@")
  COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
  COMPREPLY=()
  _git_wt_claude > /dev/null
}

_complete_wt_list() {
  COMP_WORDS=(git wt-list "$@")
  COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
  COMPREPLY=()
  _git_wt_list > /dev/null
}

@test "completes git wt-use with the picked worktree's folder name" {
  _complete_wt_use cost-code
  [ "${COMPREPLY[*]}" = "prt-3038-record-webhooks" ]
}

@test "keeps the typed word when the picker is cancelled" {
  FZF_STUB_CANCEL=1 _complete_wt_use 41
  [ "${COMPREPLY[*]}" = "41" ]
}

@test "does not complete a second argument" {
  _complete_wt_use prt-4100-invoice-export cost-code
  [ "${#COMPREPLY[@]}" -eq 0 ]
}

@test "after a pick, the terminal's status reply runs the line" {
  _complete_wt_use cost-code
  [ "$(_status_reply_binding)" = '"\e[0n": "\C-x\C-]\C-m"' ]
}

@test "after a cancel, the terminal's status reply only redraws the line" {
  FZF_STUB_CANCEL=1 _complete_wt_use 41
  [ "$(_status_reply_binding)" = '"\e[0n": redraw-current-line' ]
}

@test "completes git wt-claude with the picked worktree's folder name" {
  _complete_wt_claude cost-code
  [ "${COMPREPLY[*]}" = "prt-3038-record-webhooks" ]
}

@test "completes git wt-claude's worktree after an option" {
  _complete_wt_claude --continue cost-code
  [ "${COMPREPLY[*]}" = "prt-3038-record-webhooks" ]
}

@test "does not complete a worktree in place of the --prompt text" {
  _complete_wt_claude --prompt cost-code
  [ "${#COMPREPLY[@]}" -eq 0 ]
}

# git's completion is registered with -o nospace, so each candidate carries
# its own trailing space
@test "completes git wt-claude's options followed by a space" {
  _complete_wt_claude --con
  [ "${COMPREPLY[*]}" = "--continue " ]
}

@test "completes git wt-claude's --open option" {
  _complete_wt_claude --op
  [ "${COMPREPLY[*]}" = "--open " ]
}

@test "completes git wt-use's --open option" {
  _complete_wt_use --op
  [ "${COMPREPLY[*]}" = "--open " ]
}

@test "completes git wt-use's worktree after --open" {
  _complete_wt_use --open cost-code
  [ "${COMPREPLY[*]}" = "prt-3038-record-webhooks" ]
}

@test "completes git wt-list's --status option followed by a space" {
  _complete_wt_list --st
  [ "${COMPREPLY[*]}" = "--status " ]
}
