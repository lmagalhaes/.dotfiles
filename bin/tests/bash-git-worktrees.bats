#!/usr/bin/env bats
#
# Tests for bash/bash_git_worktrees (the interactive git() wrapper)
#

WRAPPER="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../bash" && pwd)/bash_git_worktrees"

# Fake git, picker, git-worktree-claude and git-worktree-herdr, committed
# rather than written per test (see STUBS_DIR in test_helper.bash). Kept apart
# from stubs/ so the fake git never shadows the real one in other tests.
WRAPPER_STUBS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/stubs/wrapper"

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  export WORKTREES_DIR="$TEST_ROOT/worktrees"
  export GIT_STUB_ARGS="$TEST_ROOT/git-args"
  export CLAUDE_STUB_LOG="$TEST_ROOT/claude"
  export HERDR_STUB_ARGS="$TEST_ROOT/herdr-args"
  unset HERDR_TAB_ID HERDR_WORKSPACE_ID HERDR_PANE_ID
  mkdir -p "$WORKTREES_DIR/prt-3038" "$TEST_ROOT/start"
  PATH="$WRAPPER_STUBS_DIR:$PATH"
  source "$WRAPPER"
  cd "$TEST_ROOT/start"
}

@test "git wt-use changes into the picked worktree" {
  git wt-use prt-3038
  [ "$PWD" = "$WORKTREES_DIR/prt-3038" ]
}

@test "a cancelled pick leaves the directory unchanged" {
  PICKER_STUB_CANCEL=1 git wt-use || true
  [ "$PWD" = "$TEST_ROOT/start" ]
}

@test "a cancelled pick returns the picker's status" {
  PICKER_STUB_CANCEL=1 run git wt-use
  [ "$status" -eq 130 ]
}

@test "git wt-use --help prints help without changing directory" {
  git wt-use --help > /dev/null
  [ "$PWD" = "$TEST_ROOT/start" ]
}

@test "git wt-claude stays in the picked worktree after claude exits" {
  git wt-claude prt-3038
  [ "$PWD" = "$WORKTREES_DIR/prt-3038" ]
}

@test "git wt-claude starts claude in the picked worktree" {
  git wt-claude prt-3038
  [ "$(cat "$CLAUDE_STUB_LOG.pwd")" = "$WORKTREES_DIR/prt-3038" ]
}

@test "git wt-claude passes its options on with --current" {
  git wt-claude prt-3038 --continue
  [ "$(cat "$CLAUDE_STUB_LOG.args")" = $'--current\n--continue' ]
}

@test "git wt-claude does not take the --prompt text as the query" {
  git wt-claude --prompt "/review-pr now" prt-3038
  [ "$(cat "$CLAUDE_STUB_LOG.args")" = $'--current\n--prompt\n/review-pr now' ]
}

@test "git wt-claude does not start claude when the pick is cancelled" {
  PICKER_STUB_CANCEL=1 git wt-claude || true
  [ ! -e "$CLAUDE_STUB_LOG.pwd" ]
}

@test "git wt-claude --help prints help without changing directory" {
  git wt-claude --help
  [ "$PWD" = "$TEST_ROOT/start" ]
}

@test "git wt-claude --current starts claude without picking" {
  git wt-claude --current --load
  [ "$(cat "$CLAUDE_STUB_LOG.args")" = $'--current\n--load' ]
}

_inside_herdr() {
  export HERDR_TAB_ID="w1:t1" HERDR_WORKSPACE_ID="w1"
}

@test "git wt-use names the herdr tab after the worktree" {
  _inside_herdr
  git wt-use prt-3038
  [ "$(cat "$HERDR_STUB_ARGS")" = "rename-tab prt-3038" ]
}

@test "git wt-use leaves the tab name alone outside herdr" {
  git wt-use prt-3038
  [ ! -e "$HERDR_STUB_ARGS" ]
}

@test "a failed tab rename does not fail git wt-use" {
  _inside_herdr
  HERDR_STUB_FAIL=1 run git wt-use prt-3038
  [ "$status" -eq 0 ]
}

@test "git wt-claude names the herdr tab after the worktree" {
  _inside_herdr
  git wt-claude prt-3038
  [ "$(cat "$HERDR_STUB_ARGS")" = "rename-tab prt-3038" ]
}

@test "git wt-use --open inside herdr leaves this shell where it is" {
  _inside_herdr
  git wt-use prt-3038 --open
  [ "$PWD" = "$TEST_ROOT/start" ]
}

@test "git wt-use --open outside herdr changes directory as usual" {
  git wt-use prt-3038 --open
  [ "$PWD" = "$WORKTREES_DIR/prt-3038" ]
}

@test "git wt-claude --open inside herdr leaves the pick to the script" {
  _inside_herdr
  git wt-claude prt-3038 --open
  [ "$(cat "$CLAUDE_STUB_LOG.args")" = $'prt-3038\n--open' ]
}

@test "git wt-claude --open outside herdr starts claude here as usual" {
  git wt-claude prt-3038 --open
  [ "$(cat "$CLAUDE_STUB_LOG.args")" = $'--current\n--open' ]
}

@test "other git commands pass through with their arguments" {
  git log --oneline -1
  [ "$(cat "$GIT_STUB_ARGS")" = "log --oneline -1" ]
}
