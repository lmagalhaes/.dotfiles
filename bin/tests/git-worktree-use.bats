#!/usr/bin/env bats
#
# Tests for bin/git-worktree-use
#

bats_require_minimum_version 1.5.0

load test_helper

SCRIPT="$BIN_DIR/git-worktree-use"

setup() {
  setup_repo_with_worktrees
  stub_fzf
  cd "$REPO"
}

@test "prints the path of the selected worktree" {
  run --separate-stderr "$SCRIPT" 4100
  [ "$output" = "$REPO/.worktrees/prt-4100-invoice-export" ]
}

@test "matches a worktree by folder name" {
  run --separate-stderr "$SCRIPT" record-webhooks
  [ "$output" = "$REPO/.worktrees/prt-3038-record-webhooks" ]
}

@test "matches a worktree by branch name" {
  run --separate-stderr "$SCRIPT" cost-code
  [ "$output" = "$REPO/.worktrees/prt-3038-record-webhooks" ]
}

@test "lists the main checkout" {
  run --separate-stderr "$SCRIPT" main
  [ "$output" = "$REPO" ]
}

@test "labels a worktree with its branch when they differ" {
  run --separate-stderr "$SCRIPT"
  [ "$(picker_label prt-3038-record-webhooks | tr -s ' ')" = "prt-3038-record-webhooks PRT-3038-cost-code-events" ]
}

@test "leaves the branch out when it only repeats the folder name" {
  run --separate-stderr "$SCRIPT"
  [ "$(picker_label prt-4100-invoice-export)" = "prt-4100-invoice-export" ]
}

@test "aligns branches in one column" {
  _add_worktree "feature-x" "fx"

  run --separate-stderr "$SCRIPT"
  short_label=$(picker_label fx)
  long_label=$(picker_label prt-3038-record-webhooks)
  long_prefix="${long_label%%PRT-3038*}"
  [ "${short_label%%feature-x*}" = "$(printf '%-*s' "${#long_prefix}" fx)" ]
}

@test "selects an exact folder name without opening the picker" {
  FZF_STUB_CANCEL=1 run --separate-stderr "$SCRIPT" prt-4100-invoice-export
  [ "$output" = "$REPO/.worktrees/prt-4100-invoice-export" ]
}

@test "prints the worktree name instead of its path with --print-name" {
  run --separate-stderr "$SCRIPT" --print-name cost-code
  [ "$output" = "prt-3038-record-webhooks" ]
}

@test "keeps the symlinked path the repo was entered through" {
  ln -s "$REPO" "$TEST_ROOT/linked-repo"
  cd "$TEST_ROOT/linked-repo"

  run --separate-stderr "$SCRIPT" 4100
  [ "$output" = "$TEST_ROOT/linked-repo/.worktrees/prt-4100-invoice-export" ]
}

@test "exits with fzf's cancel status when the picker is cancelled" {
  FZF_STUB_CANCEL=1 run --separate-stderr "$SCRIPT"
  [ "$status" -eq 130 ]
}

@test "prints nothing when the picker is cancelled" {
  FZF_STUB_CANCEL=1 run --separate-stderr "$SCRIPT"
  [ -z "$output" ]
}

@test "reports the query when no worktree matches" {
  run --separate-stderr "$SCRIPT" no-such-worktree
  [[ "$stderr" == *"no-such-worktree"* ]]
}

@test "exits with status 1 when no worktree matches" {
  run --separate-stderr "$SCRIPT" no-such-worktree
  [ "$status" -eq 1 ]
}

@test "exits with status 1 outside a git repo" {
  mkdir "$TEST_ROOT/not-a-repo"
  cd "$TEST_ROOT/not-a-repo"

  run --separate-stderr "$SCRIPT"
  [ "$status" -eq 1 ]
}
