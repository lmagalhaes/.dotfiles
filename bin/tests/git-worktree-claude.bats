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
  stub_claude
  cd "$REPO"
}

_claude_pwd() { cat "$CLAUDE_STUB_LOG.pwd"; }
_claude_args() { cat "$CLAUDE_STUB_LOG.args"; }

# After `git wt-use 4100` this tab carries the worktree's label and its shell,
# pane w1:p1, is in the worktree, as are the extra panes given as a JSON array
_current_tab_in_worktree() {
  local worktree="$REPO/.worktrees/prt-4100-invoice-export"
  HERDR_STUB_TABS='[{"tab_id":"w1:t1","label":"prt-4100-invoice-export"}]'
  HERDR_STUB_PANES=$(jq -nc --arg cwd "$worktree" --argjson extra "${1:-[]}" \
    '[{pane_id: "w1:p1", tab_id: "w1:t1"}] + $extra | map(. + {cwd: $cwd})')
}

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

@test "--open inside herdr starts claude in the worktree's tab with its options" {
  stub_herdr
  run --separate-stderr "$SCRIPT" 4100 --open --load
  [ "$(last_herdr_call)" = "agent start claude-w1-p9 --kind claude --pane w1:p9 -- /task-context:load" ]
}

@test "--open inside herdr does not start claude here" {
  stub_herdr
  run --separate-stderr "$SCRIPT" 4100 --open
  [ ! -e "$CLAUDE_STUB_LOG.pwd" ]
}

@test "--open with --current opens the tab for the current directory" {
  stub_herdr
  cd "$REPO/.worktrees/prt-3038-record-webhooks"
  run --separate-stderr "$SCRIPT" --current --open
  [ "$(last_herdr_call)" = "agent start claude-w1-p9 --kind claude --pane w1:p9 --" ]
}

# The script cds into the worktree before calling its herdr helper, so a
# relative $0 would no longer point beside the script
@test "--open finds its herdr helper when called by a relative path" {
  stub_herdr
  ln -s "$BIN_DIR" "$REPO/tools"
  run --separate-stderr tools/git-worktree-claude 4100 --open
  [ "$(last_herdr_call)" = "agent start claude-w1-p9 --kind claude --pane w1:p9 --" ]
}

# After `git wt-use 4100` this tab carries the worktree's label, and its only
# free pane is the one running this command
@test "--open starts claude here when the worktree's tab is the current one" {
  stub_herdr
  _current_tab_in_worktree
  run --separate-stderr "$SCRIPT" 4100 --open
  [ "$(_claude_pwd)" = "$REPO/.worktrees/prt-4100-invoice-export" ]
}

@test "--open in the worktree's tab starts claude without the GIT_DIR a git alias exports" {
  stub_herdr
  _current_tab_in_worktree
  GIT_DIR="$REPO/.git" run --separate-stderr "$SCRIPT" 4100 --open
  [ "$(cat "$CLAUDE_STUB_LOG.git-dir")" = "unset" ]
}

@test "--open in the worktree's tab starts no second claude when one runs there" {
  stub_herdr
  _current_tab_in_worktree '[{"pane_id":"w1:p2","tab_id":"w1:t1","agent":"claude"}]'
  run --separate-stderr "$SCRIPT" 4100 --open
  [ ! -e "$CLAUDE_STUB_LOG.pwd" ]
}

@test "--open outside herdr starts claude here instead" {
  run --separate-stderr "$SCRIPT" 4100 --open
  [ "$(_claude_pwd)" = "$REPO/.worktrees/prt-4100-invoice-export" ]
}

@test "--open outside herdr warns that it needs herdr" {
  run --separate-stderr "$SCRIPT" 4100 --open
  [[ "$stderr" == *"needs herdr"* ]]
}
