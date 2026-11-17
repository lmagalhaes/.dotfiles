# Shared fixture for the git-worktree-* bats tests: a throwaway repo with two
# worktrees whose folder and branch names differ, and a fake fzf on PATH.

BIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

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

# Tests run as if outside herdr, whatever terminal runs them, so none of them
# touches a real herdr tab
leave_herdr() {
  unset HERDR_TAB_ID HERDR_WORKSPACE_ID HERDR_PANE_ID
}

# Fake herdr inside workspace w1, tab w1:t1: records each call, one per line,
# in $HERDR_STUB_LOG and answers `tab list` and `pane list` from the JSON
# arrays in $HERDR_STUB_TABS and $HERDR_STUB_PANES. A created tab is w1:t9,
# with pane w1:p9. Every pane's shell is at its prompt, except the panes
# listed in $HERDR_STUB_BUSY_PANES (space-separated).
stub_herdr() {
  local stubs="$TEST_ROOT/stubs"
  mkdir -p "$stubs"
  export HERDR_TAB_ID="w1:t1" HERDR_WORKSPACE_ID="w1"
  export HERDR_STUB_LOG="$TEST_ROOT/herdr-calls"
  export HERDR_STUB_TABS='[]' HERDR_STUB_PANES='[]' HERDR_STUB_BUSY_PANES=''
  : > "$HERDR_STUB_LOG"
  cat > "$stubs/herdr" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$HERDR_STUB_LOG"
case "$1 $2" in
  "tab list") echo "{\"result\":{\"tabs\":$HERDR_STUB_TABS}}" ;;
  "pane list") echo "{\"result\":{\"panes\":$HERDR_STUB_PANES}}" ;;
  "tab create") echo '{"result":{"tab":{"tab_id":"w1:t9"},"root_pane":{"pane_id":"w1:p9"}}}' ;;
  "pane process-info")
    foreground_group=1
    [[ " ${HERDR_STUB_BUSY_PANES:-} " == *" $4 "* ]] && foreground_group=2
    echo "{\"result\":{\"process_info\":{\"foreground_process_group_id\":$foreground_group,\"shell_pid\":1}}}"
    ;;
  *) echo '{"result":{}}' ;;
esac
STUB
  chmod +x "$stubs/herdr"
  PATH="$stubs:$PATH"
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
