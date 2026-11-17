# Shared fixture for the git-worktree-* bats tests: a throwaway repo with two
# worktrees whose folder and branch names differ, and fake commands on PATH.

BIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Fake commands are committed files, not written per test: macOS checks every
# new executable on its first run, which costs about 200 ms per file
STUBS_DIR="$BIN_DIR/tests/stubs"

setup_repo_with_worktrees() {
  TEST_ROOT="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  REPO="$TEST_ROOT/repo"
  leave_herdr
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_CEILING_DIRECTORIES="$TEST_ROOT"

  git init -q -b main "$REPO"
  git -C "$REPO" config user.email "leandro@example.com"
  git -C "$REPO" config user.name "Leandro Magalhaes"
  git -C "$REPO" commit -q --allow-empty -m "initial commit"
  _add_worktree "PRT-3038-cost-code-events" "prt-3038-record-webhooks"
  _add_worktree "PRT-4100-invoice-export" "prt-4100-invoice-export"
}

_add_worktree() {
  local branch="$1" folder="$2"
  git -C "$REPO" worktree add -q -b "$branch" "$REPO/.worktrees/$folder" main
}

_use_stubs() {
  PATH="$STUBS_DIR:$PATH"
}

# Fake fzf (stubs/fzf), recording its input in $FZF_STUB_INPUT
stub_fzf() {
  export FZF_STUB_INPUT="$TEST_ROOT/fzf-input"
  _use_stubs
}

# Fake claude (stubs/claude), recording into $CLAUDE_STUB_LOG.*
stub_claude() {
  export CLAUDE_STUB_LOG="$TEST_ROOT/claude"
  _use_stubs
}

# Tests run as if outside herdr, whatever terminal runs them, so none of them
# touches a real herdr tab
leave_herdr() {
  unset HERDR_TAB_ID HERDR_WORKSPACE_ID HERDR_PANE_ID
}

# Fake herdr (stubs/herdr) inside workspace w1, tab w1:t1, with no tabs or
# panes until a test sets $HERDR_STUB_TABS or $HERDR_STUB_PANES
stub_herdr() {
  export HERDR_TAB_ID="w1:t1" HERDR_WORKSPACE_ID="w1"
  export HERDR_STUB_LOG="$TEST_ROOT/herdr-calls"
  export HERDR_STUB_TABS='[]' HERDR_STUB_PANES='[]' HERDR_STUB_BUSY_PANES=''
  : > "$HERDR_STUB_LOG"
  _use_stubs
}

herdr_calls() {
  cat "$HERDR_STUB_LOG"
}

last_herdr_call() {
  tail -n 1 "$HERDR_STUB_LOG"
}

# The label the picker showed for a worktree folder, colours stripped
picker_label() {
  local name="$1"
  sed -E $'s/\033\\[[0-9;]*m//g' "$FZF_STUB_INPUT" |
    awk -F '\t' -v name="$name" '$2 == name { print $1 }'
}
