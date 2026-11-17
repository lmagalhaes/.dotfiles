#!/usr/bin/env bats
#
# Tests for bin/git-worktree-herdr
#

bats_require_minimum_version 1.5.0

load test_helper

SCRIPT="$BIN_DIR/git-worktree-herdr"

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  stub_herdr
  stub_claude
}

_tab_labelled_prt_3038() {
  HERDR_STUB_TABS='[{"tab_id":"w1:t4","label":"prt-3038"},{"tab_id":"w1:t5","label":"prt-4100"}]'
}

# The tab running the test (w1:t1) carries the worktree's label
_current_tab_labelled_prt_3038() {
  HERDR_STUB_TABS='[{"tab_id":"w1:t1","label":"prt-3038"}]'
}

@test "rename-tab renames the current tab" {
  run --separate-stderr "$SCRIPT" rename-tab prt-3038
  [ "$(herdr_calls)" = "tab rename w1:t1 prt-3038" ]
}

@test "open-tab focuses the tab with the same label instead of creating one" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p4","tab_id":"w1:t4","cwd":"/work/prt-3038"}]'
  run --separate-stderr "$SCRIPT" open-tab /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "tab focus w1:t4" ]
}

# Two repos' worktrees of one branch share a folder name, and so a label
@test "open-tab creates a tab when the labelled one is another checkout's" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p4","tab_id":"w1:t4","cwd":"/other/prt-3038"}]'
  run --separate-stderr "$SCRIPT" open-tab /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "tab create --workspace w1 --cwd /work/prt-3038 --label prt-3038 --focus" ]
}

@test "open-tab focuses the labelled tab of its own checkout" {
  HERDR_STUB_TABS='[{"tab_id":"w1:t4","label":"prt-3038"},{"tab_id":"w1:t5","label":"prt-3038"}]'
  HERDR_STUB_PANES='[{"pane_id":"w1:p4","tab_id":"w1:t4","cwd":"/other/prt-3038"},{"pane_id":"w1:p5","tab_id":"w1:t5","cwd":"/work/prt-3038"}]'
  run --separate-stderr "$SCRIPT" open-tab /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "tab focus w1:t5" ]
}

@test "open-tab focuses a labelled tab whose pane is in a folder of the worktree" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p4","tab_id":"w1:t4","cwd":"/work/prt-3038/bin"}]'
  run --separate-stderr "$SCRIPT" open-tab /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "tab focus w1:t4" ]
}

@test "open-tab creates a labelled tab in the worktree when none has the label" {
  HERDR_STUB_TABS='[{"tab_id":"w1:t5","label":"prt-4100"}]'
  run --separate-stderr "$SCRIPT" open-tab /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "tab create --workspace w1 --cwd /work/prt-3038 --label prt-3038 --focus" ]
}

@test "open-claude starts claude in a new tab's pane" {
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "agent start claude-w1-p9 --kind claude --pane w1:p9 --" ]
}

# `herdr agent start` needs the shell at its prompt, which a new tab's shell
# reaches only after it starts
@test "open-claude waits for a new tab's shell to reach its prompt" {
  HERDR_STUB_STARTING_PANES="w1:p9"
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$(herdr_calls | tail -n 2)" = $'pane process-info --pane w1:p9\nagent start claude-w1-p9 --kind claude --pane w1:p9 --' ]
}

@test "open-claude starts no claude in a new tab whose shell never reaches its prompt" {
  HERDR_STUB_BUSY_PANES="w1:p9"
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [[ "$(herdr_calls)" != *"agent start"* ]]
}

@test "open-claude passes its remaining arguments to claude" {
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038 /task-context:load
  [ "$(last_herdr_call)" = "agent start claude-w1-p9 --kind claude --pane w1:p9 -- /task-context:load" ]
}

# herdr agent names must be unique and match [a-z][a-z0-9_-]{0,31}, which a
# folder name such as .dotfiles, or one over 32 characters, does not
@test "open-claude names the agent after its pane, not the tab label" {
  run --separate-stderr "$SCRIPT" open-claude /work/.dotfiles .dotfiles
  [ "$(last_herdr_call)" = "agent start claude-w1-p9 --kind claude --pane w1:p9 --" ]
}

@test "open-claude only focuses a tab that already runs claude" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p4","tab_id":"w1:t4","cwd":"/work/prt-3038","agent":"claude"},{"pane_id":"w1:p5","tab_id":"w1:t4","cwd":"/work/prt-3038"}]'
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "pane list --workspace w1" ]
}

@test "open-claude starts claude in the tab's pane that runs no agent" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p4","tab_id":"w1:t4","cwd":"/work/prt-3038","agent":"codex"},{"pane_id":"w1:p5","tab_id":"w1:t4","cwd":"/work/prt-3038"},{"pane_id":"w1:p6","tab_id":"w1:t6"}]'
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "agent start claude-w1-p5 --kind claude --pane w1:p5 --" ]
}

# A pane with no agent may still run an editor, tests, or the command that
# called this helper
@test "open-claude skips a pane whose shell is not at its prompt" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p5","tab_id":"w1:t4","cwd":"/work/prt-3038"},{"pane_id":"w1:p7","tab_id":"w1:t4","cwd":"/work/prt-3038"}]'
  HERDR_STUB_BUSY_PANES="w1:p5"
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "agent start claude-w1-p7 --kind claude --pane w1:p7 --" ]
}

@test "open-claude skips a pane whose process ids herdr doesn't know" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p5","tab_id":"w1:t4","cwd":"/work/prt-3038"},{"pane_id":"w1:p7","tab_id":"w1:t4","cwd":"/work/prt-3038"}]'
  HERDR_STUB_UNKNOWN_PANES="w1:p5"
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$(last_herdr_call)" = "agent start claude-w1-p7 --kind claude --pane w1:p7 --" ]
}

@test "open-claude fails when no pane in the tab is at its shell prompt" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p5","tab_id":"w1:t4","cwd":"/work/prt-3038"}]'
  HERDR_STUB_BUSY_PANES="w1:p5"
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$status" -ne 0 ]
}

# The pane running this is busy, so herdr can't start Claude in it
@test "open-claude starts claude in this pane when the tab is the current one" {
  _current_tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p1","tab_id":"w1:t1","cwd":"/work/prt-3038"}]'
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038 /task-context:load
  [ "$(cat "$CLAUDE_STUB_LOG.args")" = "/task-context:load" ]
}

@test "open-claude starts no second claude in the current tab" {
  _current_tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p1","tab_id":"w1:t1","cwd":"/work/prt-3038"},{"pane_id":"w1:p2","tab_id":"w1:t1","cwd":"/work/prt-3038","agent":"claude"}]'
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ ! -e "$CLAUDE_STUB_LOG.args" ]
}

@test "open-claude starts no claude in the current tab when herdr can't list its panes" {
  _current_tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p1","tab_id":"w1:t1","cwd":"/work/prt-3038"}]'
  # The first finds the tab; the second looks for a running claude
  HERDR_STUB_FAILING="pane list"
  HERDR_STUB_FAILING_CALL=2
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ ! -e "$CLAUDE_STUB_LOG.args" ]
}

@test "open-claude fails when herdr can't list the tab's panes" {
  _current_tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p1","tab_id":"w1:t1","cwd":"/work/prt-3038"}]'
  # The first finds the tab; the second looks for a running claude
  HERDR_STUB_FAILING="pane list"
  HERDR_STUB_FAILING_CALL=2
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$status" -ne 0 ]
}

# The first pane list finds the tab, the second no Claude; the one looking for a
# free pane fails
@test "open-claude says so when herdr can't list the tab's panes to find a free one" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p5","tab_id":"w1:t4","cwd":"/work/prt-3038"}]'
  HERDR_STUB_FAILING="pane list"
  HERDR_STUB_FAILING_CALL=3
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [[ "$stderr" == *"Could not list the panes in tab prt-3038"* ]]
}

@test "open-claude fails when every pane in the tab runs an agent" {
  _tab_labelled_prt_3038
  HERDR_STUB_PANES='[{"pane_id":"w1:p4","tab_id":"w1:t4","cwd":"/work/prt-3038","agent":"codex"}]'
  run --separate-stderr "$SCRIPT" open-claude /work/prt-3038 prt-3038
  [ "$status" -ne 0 ]
}

@test "fails outside herdr without calling it" {
  leave_herdr
  run --separate-stderr "$SCRIPT" rename-tab prt-3038
  [ "$status" -ne 0 ] && [ -z "$(herdr_calls)" ]
}

@test "fails on an unknown command" {
  run --separate-stderr "$SCRIPT" close-tab
  [ "$status" -ne 0 ]
}
