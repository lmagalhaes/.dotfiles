#!/usr/bin/env bats

SCRIPT="${BATS_TEST_DIRNAME}/../render-settings.sh"

setup() {
  TEST_HOME="$(mktemp -d)"
  mkdir -p "${TEST_HOME}/.claude/config"
  export HOME="$TEST_HOME"
}

teardown() {
  rm -rf "$TEST_HOME"
}

managed() { echo "${TEST_HOME}/.claude/config/settings.managed.json"; }
target()  { echo "${TEST_HOME}/.claude/settings.json"; }

write_managed() {
  echo "$1" > "$(managed)"
}

write_target() {
  echo "$1" > "$(target)"
}

@test "exits with error when managed file is missing" {
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"managed source not found"* ]]
}

@test "creates settings.json from managed file on first run" {
  write_managed '{"theme":"dark","editorMode":"vim"}'

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"created"* ]]
  [ -f "$(target)" ]
  [ "$(jq -r '.theme' "$(target)")" = "dark" ]
}

@test "managed keys overwrite existing keys in settings.json" {
  write_target  '{"theme":"light","editorMode":"emacs"}'
  write_managed '{"theme":"dark-ansi","editorMode":"vim"}'

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.theme' "$(target)")" = "dark-ansi" ]
  [ "$(jq -r '.editorMode' "$(target)")" = "vim" ]
}

@test "runtime-only keys in existing settings.json are preserved" {
  write_target  '{"feedbackSurveyState":{"lastShownTime":12345},"theme":"light"}'
  write_managed '{"theme":"dark-ansi"}'

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.feedbackSurveyState.lastShownTime' "$(target)")" = "12345" ]
}

@test "output is valid JSON after merge" {
  write_target  '{"existing":"value","feedbackSurveyState":{}}'
  write_managed '{"theme":"dark-ansi","editorMode":"vim"}'

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  run jq '.' "$(target)"
  [ "$status" -eq 0 ]
}

@test "write is atomic — uses tmp file before replacing target" {
  write_target  '{"theme":"light"}'
  write_managed '{"theme":"dark-ansi"}'

  # Verify no leftover tmp file after successful run
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ ! -f "$(target).tmp" ]
}
