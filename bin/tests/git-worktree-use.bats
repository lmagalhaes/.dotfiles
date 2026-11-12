#!/usr/bin/env bats
#
# Tests for bin/git-worktree-use
#

bats_require_minimum_version 1.5.0

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/git-worktree-use"

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  REPO="$TEST_ROOT/repo"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_CEILING_DIRECTORIES="$TEST_ROOT"

  git init -q -b main "$REPO"
  git -C "$REPO" config user.email "leandro@example.com"
  git -C "$REPO" config user.name "Leandro Magalhaes"
  git -C "$REPO" commit -q --allow-empty -m "initial commit"
  _add_worktree "PRT-3038-cost-code-events" "prt-3038-record-webhooks"
  _add_worktree "PRT-4100-invoice-export" "prt-4100-invoice-export"

  _stub_fzf
  cd "$REPO"
}

_add_worktree() {
  local branch="$1" folder="$2"
  git -C "$REPO" worktree add -q -b "$branch" "$REPO/.worktrees/$folder" main
}

# Fake fzf: selects the first row whose name or branch (fields 1 and 2)
# contains --query, ignoring case. FZF_STUB_CANCEL=1 simulates Esc.
_stub_fzf() {
  local stubs="$TEST_ROOT/stubs"
  mkdir -p "$stubs"
  cat > "$stubs/fzf" <<'STUB'
#!/usr/bin/env bash
query=""
while (( $# )); do
  [[ "$1" == "--query" ]] && query="$2"
  shift
done
[[ -n "${FZF_STUB_CANCEL:-}" ]] && exit 130
shopt -s nocasematch
while IFS=$'\t' read -r name branch path; do
  if [[ "$name" == *"$query"* || "$branch" == *"$query"* ]]; then
    printf '%s\t%s\t%s\n' "$name" "$branch" "$path"
    exit 0
  fi
done
exit 1
STUB
  chmod +x "$stubs/fzf"
  PATH="$stubs:$PATH"
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
