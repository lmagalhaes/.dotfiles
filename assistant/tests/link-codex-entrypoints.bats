#!/usr/bin/env bats
#
# Tests for assistant/link-codex-entrypoints.sh, run against a throwaway HOME
# holding the authored ~/.assistant-config/shared/AGENTS.md.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/link-codex-entrypoints.sh"

setup() {
  FAKE_HOME="$(mktemp -d)"
  SHARED="$FAKE_HOME/.assistant-config/shared/AGENTS.md"
  mkdir -p "$(dirname "$SHARED")"
  echo "shared instructions" >"$SHARED"
  export CODEX_HOME="$FAKE_HOME/codex-home"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

_link() {
  run env HOME="$FAKE_HOME" bash "$SCRIPT"
}

@test "links Codex's AGENTS.md to the shared file" {
  _link
  [ "$(readlink "$CODEX_HOME/AGENTS.md")" = "$SHARED" ]
}

@test "uses ~/.codex when CODEX_HOME is unset" {
  unset CODEX_HOME
  _link
  [ "$(readlink "$FAKE_HOME/.codex/AGENTS.md")" = "$SHARED" ]
}

@test "a second run succeeds" {
  _link
  _link
  [ "$status" -eq 0 ]
}

@test "a second run keeps the link" {
  _link
  _link
  [ "$(readlink "$CODEX_HOME/AGENTS.md")" = "$SHARED" ]
}

@test "replaces a stale link" {
  mkdir -p "$CODEX_HOME"
  ln -s "$FAKE_HOME/gone/AGENTS.md" "$CODEX_HOME/AGENTS.md"
  _link
  [ "$(readlink "$CODEX_HOME/AGENTS.md")" = "$SHARED" ]
}

@test "refuses to replace a real AGENTS.md" {
  mkdir -p "$CODEX_HOME"
  echo "hand-written" >"$CODEX_HOME/AGENTS.md"
  _link
  [ "$status" -ne 0 ]
}

@test "leaves a real AGENTS.md as it was" {
  mkdir -p "$CODEX_HOME"
  echo "hand-written" >"$CODEX_HOME/AGENTS.md"
  _link
  [ "$(cat "$CODEX_HOME/AGENTS.md")" = "hand-written" ]
}

@test "skips without failing while the shared file doesn't exist" {
  rm "$SHARED"
  _link
  [ "$status" -eq 0 ]
}

@test "creates no dangling link while the shared file doesn't exist" {
  rm "$SHARED"
  _link
  [ ! -L "$CODEX_HOME/AGENTS.md" ]
}

@test "warns when a non-empty AGENTS.override.md would win over the link" {
  mkdir -p "$CODEX_HOME"
  echo "override" >"$CODEX_HOME/AGENTS.override.md"
  _link
  [[ "$output" == *"AGENTS.override.md"* ]]
}
