# Shared fixture for the git-worktree-* bats tests: a throwaway repo with two
# worktrees whose folder and branch names differ, and a fake fzf on PATH.

BIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup_repo_with_worktrees() {
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
}

_add_worktree() {
  local branch="$1" folder="$2"
  git -C "$REPO" worktree add -q -b "$branch" "$REPO/.worktrees/$folder" main
}

# Fake fzf: selects the first row whose name or branch (fields 1 and 2)
# contains --query, ignoring case. FZF_STUB_CANCEL=1 simulates Esc.
stub_fzf() {
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
