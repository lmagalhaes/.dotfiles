#!/usr/bin/env bats
#
# Tests for assistant/link-claude-entrypoints.sh, run against a throwaway HOME
# holding an authored ~/.assistant-config/claude tree.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/link-claude-entrypoints.sh"

setup() {
  FAKE_HOME="$(mktemp -d)"
  AUTHORED="$FAKE_HOME/.assistant-config/claude"
  mkdir -p "$AUTHORED/rules" "$AUTHORED/skills"
  echo "instructions" >"$AUTHORED/CLAUDE.md"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

_link() {
  run env -u ASSISTANT_CONFIG_DIR -u ASSISTANT_CONFIG_CLAUDE_DIR HOME="$FAKE_HOME" bash "$SCRIPT"
}

@test "links CLAUDE.md through the authored link" {
  _link
  [ "$(cat "$FAKE_HOME/.claude/CLAUDE.md")" = "instructions" ]
}

@test "no longer links RTK.md" {
  _link
  [ ! -L "$FAKE_HOME/.claude/RTK.md" ]
}

@test "removes a stale RTK.md link" {
  mkdir -p "$FAKE_HOME/.claude"
  ln -s authored/RTK.md "$FAKE_HOME/.claude/RTK.md"
  _link
  [ ! -L "$FAKE_HOME/.claude/RTK.md" ]
}

@test "leaves a real RTK.md file alone" {
  mkdir -p "$FAKE_HOME/.claude"
  echo "hand-written" >"$FAKE_HOME/.claude/RTK.md"
  _link
  [ "$(cat "$FAKE_HOME/.claude/RTK.md")" = "hand-written" ]
}
