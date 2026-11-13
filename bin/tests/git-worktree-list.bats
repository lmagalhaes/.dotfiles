#!/usr/bin/env bats
#
# Tests for bin/git-worktree-list
#

bats_require_minimum_version 1.5.0

load test_helper

SCRIPT="$BIN_DIR/git-worktree-list"

setup() {
  setup_repo_with_worktrees
  echo ".worktrees/" >> "$REPO/.git/info/exclude"
  _setup_origin
  _stub_gh
  cd "$REPO"
}

# A bare "origin" that main has been pushed to, and a second clone to push
# from as someone else would
_setup_origin() {
  ORIGIN="$TEST_ROOT/origin.git"
  git init -q --bare -b main "$ORIGIN"
  git -C "$REPO" remote add origin "$ORIGIN"
  git -C "$REPO" push -q origin main
  git -C "$REPO" fetch -q origin
}

_push_to_origin_main_from_elsewhere() {
  local clone="$TEST_ROOT/other-clone"
  git clone -q "$ORIGIN" "$clone"
  git -C "$clone" -c user.name=Other -c user.email=other@example.com \
    commit -q --allow-empty -m "someone else's commit"
  git -C "$clone" push -q origin main
}

_commit_in() {
  git -C "$REPO/.worktrees/$1" commit -q --allow-empty -m "work in $1"
}

# Fake gh pr list: $GH_STUB_OUTPUT is the repo's PRs as JSON, newest first, as
# GitHub orders them; applies --head, --limit and --jq like gh does.
# GH_STUB_FAIL=1 makes it fail.
_stub_gh() {
  local stubs="$TEST_ROOT/stubs"
  mkdir -p "$stubs"
  export GH_STUB_OUTPUT='[]'
  cat > "$stubs/gh" <<'STUB'
#!/usr/bin/env bash
[[ -n "${GH_STUB_FAIL:-}" ]] && exit 1
head="" limit=30 filter="."
while (( $# )); do
  case "$1" in
    --head) head="$2" ;;
    --limit) limit="$2" ;;
    --jq) filter="$2" ;;
  esac
  shift
done
jq --arg head "$head" --argjson limit "$limit" \
  '[.[] | select($head == "" or .headRefName == $head)][:$limit]' <<< "$GH_STUB_OUTPUT" |
  jq -r "$filter"
STUB
  chmod +x "$stubs/gh"
  PATH="$stubs:$PATH"
}

# The text of a "<label>:" line listed under a worktree folder; "" names the
# main checkout, which is listed first and has no Worktree: line
_line_of() {
  local label="$1" name="$2"
  sed -E $'s/\033\\[[0-9;]*m//g' <<< "$output" | awk -v label="$label:" -v name="$name" '
    $1 == "Worktree:" { current = $2 }
    $1 == label && current == name { sub("^ *" label " ", ""); print; exit }
  '
}

_status_of() { _line_of Status "$1"; }
_pr_of() { _line_of PR "$1"; }

@test "plain wt-list output has no status line" {
  run --separate-stderr "$SCRIPT"
  [[ "$output" != *"Status:"* ]]
}

@test "plain wt-list output points to --status" {
  run --separate-stderr "$SCRIPT"
  [[ "$output" == *"git wt-list --status"* ]]
}

@test "--status output leaves out the pointer to itself" {
  run --separate-stderr "$SCRIPT" --status
  [[ "$output" != *"git wt-list --status"* ]]
}

@test "reports a worktree without changes as clean" {
  _commit_in prt-4100-invoice-export
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of prt-4100-invoice-export)" = "clean · 1 ahead" ]
}

@test "reports the number of uncommitted files" {
  _commit_in prt-4100-invoice-export
  touch "$REPO/.worktrees/prt-4100-invoice-export/"{a,b}.txt
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of prt-4100-invoice-export)" = "2 uncommitted · 1 ahead" ]
}

@test "reports commits ahead and behind origin/main after fetching" {
  _commit_in prt-3038-record-webhooks
  _commit_in prt-3038-record-webhooks
  _push_to_origin_main_from_elsewhere
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of prt-3038-record-webhooks)" = "clean · 2 ahead · 1 behind" ]
}

@test "--no-fetch reports against the last fetched origin/main" {
  _commit_in prt-3038-record-webhooks
  _push_to_origin_main_from_elsewhere
  run --separate-stderr "$SCRIPT" --status --no-fetch
  [ "$(_status_of prt-3038-record-webhooks)" = "clean · 1 ahead" ]
}

@test "marks a branch contained in origin/main as merged" {
  _commit_in prt-4100-invoice-export
  git -C "$REPO/.worktrees/prt-4100-invoice-export" push -q origin HEAD:main
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of prt-4100-invoice-export)" = "clean · merged" ]
}

@test "never marks main itself as merged" {
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of "")" = "clean · up to date" ]
}

@test "shows the PR number and state for a matching branch" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"OPEN"},
                   {"headRefName":"PRT-9999-other","number":1300,"state":"MERGED"}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1201 open" ]
}

@test "shows the newest PR when a branch has several" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1250,"state":"OPEN"},
                   {"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"CLOSED"}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1250 open" ]
}

@test "shows an open PR waiting for review as pending approval" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"OPEN",
                    "reviewDecision":"REVIEW_REQUIRED","labels":[]}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1201 open, pending approval" ]
}

@test "shows an approved open PR as approved" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"OPEN",
                    "reviewDecision":"APPROVED","labels":[]}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1201 open, approved" ]
}

@test "shows an open PR with requested changes" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"OPEN",
                    "reviewDecision":"CHANGES_REQUESTED","labels":[]}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1201 open, changes requested" ]
}

@test "leaves out the review state of a merged PR" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"MERGED",
                    "reviewDecision":"APPROVED","labels":[]}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1201 merged" ]
}

@test "shows the local date a merged PR was merged" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"MERGED",
                    "mergedAt":"2026-11-09T20:00:00Z","labels":[{"name":"backend"}]}]'
  TZ=Australia/Sydney run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1201 merged 2026-11-10 [backend]" ]
}

@test "lists the PR's labels" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"OPEN",
                    "reviewDecision":"APPROVED","labels":[{"name":"🧪 staging"},{"name":"backend"}]}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_pr_of prt-3038-record-webhooks)" = "#1201 open, approved [🧪 staging, backend]" ]
}

@test "keeps the PR off the Status line" {
  _commit_in prt-3038-record-webhooks
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"OPEN"}]'
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of prt-3038-record-webhooks)" = "clean · 1 ahead" ]
}

@test "omits the PR line for a branch without a PR" {
  GH_STUB_OUTPUT='[{"headRefName":"PRT-3038-cost-code-events","number":1201,"state":"OPEN"}]'
  run --separate-stderr "$SCRIPT" --status
  [[ "$(sed -n '/prt-4100-invoice-export/,/^$/p' <<< "$output")" != *"PR:"* ]]
}

@test "omits the PR line when gh fails" {
  GH_STUB_FAIL=1 run --separate-stderr "$SCRIPT" --status
  [[ "$output" != *"PR:"* ]]
}

@test "omits ahead and behind when there is no origin/main" {
  git -C "$REPO" remote remove origin
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of prt-3038-record-webhooks)" = "clean" ]
}

@test "reports a worktree whose folder is gone as missing" {
  rm -rf "$REPO/.worktrees/prt-4100-invoice-export"
  run --separate-stderr "$SCRIPT" --status
  [ "$(_status_of prt-4100-invoice-export)" = "missing" ]
}

@test "--status prints no errors" {
  run --separate-stderr "$SCRIPT" --status
  [ -z "$stderr" ]
}

@test "--status leaves no temporary files behind" {
  export TMPDIR="$TEST_ROOT/tmp"
  mkdir -p "$TMPDIR"
  run --separate-stderr "$SCRIPT" --status
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "rejects an unknown option" {
  run --separate-stderr "$SCRIPT" --stats
  [ "$status" -ne 0 ]
}
