#!/usr/bin/env bats
#
# Tests for bash/bash_git_worktrees (the interactive git() wrapper)
#

WRAPPER="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../bash" && pwd)/bash_git_worktrees"

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  export WORKTREES_DIR="$TEST_ROOT/worktrees"
  export GIT_STUB_ARGS="$TEST_ROOT/git-args"
  export CLAUDE_STUB_LOG="$TEST_ROOT/claude"
  mkdir -p "$WORKTREES_DIR/prt-3038" "$TEST_ROOT/start"
  _stub_commands
  source "$WRAPPER"
  cd "$TEST_ROOT/start"
}

# Fake picker prints $WORKTREES_DIR/<query>; PICKER_STUB_CANCEL=1 simulates
# Esc. Fake git records its arguments; fake git-worktree-claude records where
# it ran and its arguments, one per line.
_stub_commands() {
  local stubs="$TEST_ROOT/stubs"
  mkdir -p "$stubs"
  cat > "$stubs/git-worktree-use" <<'STUB'
#!/usr/bin/env bash
[[ "${1:-}" == "--help" ]] && { echo "Usage: git worktree-use [query]"; exit 0; }
[[ -n "${PICKER_STUB_CANCEL:-}" ]] && exit 130
echo "$WORKTREES_DIR/${1:-main}"
STUB
  cat > "$stubs/git" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$GIT_STUB_ARGS"
STUB
  cat > "$stubs/git-worktree-claude" <<'STUB'
#!/usr/bin/env bash
pwd > "$CLAUDE_STUB_LOG.pwd"
printf '%s\n' "$@" > "$CLAUDE_STUB_LOG.args"
STUB
  chmod +x "$stubs/git-worktree-use" "$stubs/git" "$stubs/git-worktree-claude"
  PATH="$stubs:$PATH"
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

@test "other git commands pass through with their arguments" {
  git log --oneline -1
  [ "$(cat "$GIT_STUB_ARGS")" = "log --oneline -1" ]
}
