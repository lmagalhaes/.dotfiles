#!/usr/bin/env bats
#
# Tests for bin/git-worktree-claude
#

bats_require_minimum_version 1.5.0

load test_helper

SCRIPT="$BIN_DIR/git-worktree-claude"

setup() {
  setup_repo_with_worktrees
  stub_fzf
  _stub_claude
  cd "$REPO"
}

# Fake claude records where it started, its arguments (one per line) and the
# GIT_DIR it inherited
_stub_claude() {
  export CLAUDE_STUB_LOG="$TEST_ROOT/claude"
  cat > "$TEST_ROOT/stubs/claude" <<'STUB'
#!/usr/bin/env bash
pwd > "$CLAUDE_STUB_LOG.pwd"
printf '%s\n' "$@" > "$CLAUDE_STUB_LOG.args"
echo "${GIT_DIR-unset}" > "$CLAUDE_STUB_LOG.git-dir"
STUB
  chmod +x "$TEST_ROOT/stubs/claude"
}

_claude_pwd() { cat "$CLAUDE_STUB_LOG.pwd"; }
_claude_args() { cat "$CLAUDE_STUB_LOG.args"; }

@test "with a query, starts claude inside the selected worktree" {
  run --separate-stderr "$SCRIPT" 4100
  [ "$(_claude_pwd)" = "$REPO/.worktrees/prt-4100-invoice-export" ]
}

@test "starts a new session by default" {
  run --separate-stderr "$SCRIPT" 4100
  [ "$(_claude_args)" = "" ]
}

@test "--continue passes --continue to claude" {
  run --separate-stderr "$SCRIPT" 4100 --continue
  [ "$(_claude_args)" = "--continue" ]
}

@test "--load starts claude with /task-context:load" {
  run --separate-stderr "$SCRIPT" 4100 --load
  [ "$(_claude_args)" = "/task-context:load" ]
}

@test "--prompt starts claude with the given text" {
  run --separate-stderr "$SCRIPT" 4100 --prompt "/review-pr now"
  [ "$(_claude_args)" = "/review-pr now" ]
}

@test "--prompt without text fails without starting claude" {
  run --separate-stderr "$SCRIPT" 4100 --prompt
  [ "$status" -ne 0 ] && [ ! -e "$CLAUDE_STUB_LOG.pwd" ]
}

@test "options may come before the query" {
  run --separate-stderr "$SCRIPT" --continue 4100
  [ "$(_claude_pwd)" = "$REPO/.worktrees/prt-4100-invoice-export" ]
}

@test "--current starts claude in the current directory without picking" {
  cd "$REPO/.worktrees/prt-3038-record-webhooks"
  run --separate-stderr "$SCRIPT" --current
  [ "$(_claude_pwd)" = "$REPO/.worktrees/prt-3038-record-webhooks" ] && [ ! -e "$FZF_STUB_INPUT" ]
}

@test "exits non-zero when the picker is cancelled" {
  FZF_STUB_CANCEL=1 run --separate-stderr "$SCRIPT"
  [ "$status" -eq 130 ]
}

@test "does not start claude when the picker is cancelled" {
  FZF_STUB_CANCEL=1 run --separate-stderr "$SCRIPT"
  [ ! -e "$CLAUDE_STUB_LOG.pwd" ]
}

# A `!` git alias exports GIT_DIR for the worktree it was run from, which
# would point claude's git commands at the wrong worktree
@test "starts claude without the GIT_DIR a git alias exports" {
  GIT_DIR="$REPO/.git" run --separate-stderr "$SCRIPT" 4100
  [ "$(cat "$CLAUDE_STUB_LOG.git-dir")" = "unset" ]
}
