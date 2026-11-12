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
  cd "$REPO"
}

_complete_wt_use() {
  COMP_WORDS=(git wt-use "$@")
  COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
  COMPREPLY=()
  _git_wt_use > /dev/null
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
