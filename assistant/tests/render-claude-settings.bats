#!/usr/bin/env bats
#
# Tests for assistant/render-claude-settings.sh, run against a throwaway HOME
# holding a managed template (~/.claude/authored/settings.managed.json) and a
# live ~/.claude/settings.json.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/render-claude-settings.sh"

setup() {
  FAKE_HOME="$(mktemp -d)"
  mkdir -p "$FAKE_HOME/.claude/authored"
  MANAGED="$FAKE_HOME/.claude/authored/settings.managed.json"
  LIVE="$FAKE_HOME/.claude/settings.json"
  cat >"$MANAGED" <<'EOF'
{
  "permissions": {
    "allow": ["Bash(ls *)"],
    "deny": ["Read(~/.aws/**)", "Bash(*.aws/*)"]
  },
  "hooks": {
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "rtk hook claude"}]}]
  }
}
EOF
  jq '. + {feedbackSurveyState: {seen: 1}}' "$MANAGED" >"$LIVE"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

# Applies a jq filter to the managed template.
_template() {
  jq "$1" "$MANAGED" >"$MANAGED.new" && mv "$MANAGED.new" "$MANAGED"
}

_render() {
  run env HOME="$FAKE_HOME" bash "$SCRIPT" "$@"
}

@test "renders a deny rule the template adds" {
  _template '.permissions.deny += ["Bash(*.netrc*)"]'
  _render
  jq -e '.permissions.deny | index("Bash(*.netrc*)")' "$LIVE"
}

@test "keeps runtime keys the template does not define" {
  _render
  jq -e '.feedbackSurveyState.seen == 1' "$LIVE"
}

@test "creates the live file when there is none" {
  rm "$LIVE"
  _render
  [ -f "$LIVE" ]
}

@test "refuses to render when a live deny rule would be dropped" {
  _template '.permissions.deny -= ["Bash(*.aws/*)"]'
  _render
  [ "$status" -ne 0 ]
}

@test "leaves the live file untouched when it refuses" {
  cp "$LIVE" "$FAKE_HOME/before.json"
  _template '.permissions.deny -= ["Bash(*.aws/*)"]'
  _render
  cmp "$LIVE" "$FAKE_HOME/before.json"
}

@test "leaves no temp file behind when it refuses" {
  _template '.permissions.deny -= ["Bash(*.aws/*)"]'
  _render
  [ ! -e "$LIVE.tmp" ]
}

@test "names the deny rule it would drop" {
  _template '.permissions.deny -= ["Bash(*.aws/*)"]'
  _render
  [[ "$output" == *"deny  Bash(*.aws/*)"* ]]
}

@test "refuses to render when a live hook would be dropped" {
  _template 'del(.hooks.PreToolUse)'
  _render
  [ "$status" -ne 0 ]
}

@test "names the hook it would drop" {
  _template 'del(.hooks.PreToolUse)'
  _render
  [[ "$output" == *"hook  PreToolUse(Bash): rtk hook claude"* ]]
}

@test "renders a dropped deny rule with --force" {
  _template '.permissions.deny -= ["Bash(*.aws/*)"]'
  _render --force
  jq -e '.permissions.deny | index("Bash(*.aws/*)") | not' "$LIVE"
}

@test "renders nothing when given an unknown argument" {
  cp "$LIVE" "$FAKE_HOME/before.json"
  _template '.permissions.deny += ["Bash(*.netrc*)"]'
  _render --help
  cmp "$LIVE" "$FAKE_HOME/before.json"
}

@test "renders when only an allow rule would be dropped" {
  _template '.permissions.allow = []'
  _render
  [ "$status" -eq 0 ]
}
