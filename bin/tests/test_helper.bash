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

# Fake fzf: selects the first row whose label (field 1, what the picker
# shows) contains --query, ignoring case, and records its input in
# $FZF_STUB_INPUT. FZF_STUB_CANCEL=1 simulates Esc.
stub_fzf() {
  local stubs="$TEST_ROOT/stubs"
  mkdir -p "$stubs"
  export FZF_STUB_INPUT="$TEST_ROOT/fzf-input"
  cat > "$stubs/fzf" <<'STUB'
#!/usr/bin/env bash
query=""
while (( $# )); do
  [[ "$1" == "--query" ]] && query="$2"
  shift
done
tee "$FZF_STUB_INPUT" > /dev/null
[[ -n "${FZF_STUB_CANCEL:-}" ]] && exit 130
shopt -s nocasematch
while IFS=$'\t' read -r label rest; do
  if [[ "$label" == *"$query"* ]]; then
    printf '%s\t%s\n' "$label" "$rest"
    exit 0
  fi
done < "$FZF_STUB_INPUT"
exit 1
STUB
  chmod +x "$stubs/fzf"
  PATH="$stubs:$PATH"
}

# The label the picker showed for a worktree folder, colours stripped
picker_label() {
  local name="$1"
  sed -E $'s/\033\\[[0-9;]*m//g' "$FZF_STUB_INPUT" |
    awk -F '\t' -v name="$name" '$2 == name { print $1 }'
}
