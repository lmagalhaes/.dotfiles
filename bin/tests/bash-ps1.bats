#!/usr/bin/env bats
#
# Tests for the git change marks in bash/bash_ps1's modern prompt
#

PS1_FILE="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../bash" && pwd)/bash_ps1"

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  REPO="$TEST_ROOT/repo"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_CEILING_DIRECTORIES="$TEST_ROOT"

  git init -q -b main "$REPO"
  git -C "$REPO" config user.email "leandro@example.com"
  git -C "$REPO" config user.name "Leandro Magalhaes"
  echo "first" > "$REPO/tracked.txt"
  git -C "$REPO" add tracked.txt
  git -C "$REPO" commit -q -m "initial commit"

  source "$PS1_FILE"
  cd "$REPO"
}

# The marks between the parentheses after the branch, colours stripped
_prompt_marks() {
  _set_ps1_modern
  printf '%s' "$PS1" | sed -E 's/\\\[[^]]*\\\]//g' | sed -nE 's/.*\((.*)\).*/\1/p'
}

@test "shows no change marks in a clean repo" {
  [ "$(_prompt_marks)" = "" ]
}

@test "marks unstaged changes with *" {
  echo "changed" > tracked.txt
  [ "$(_prompt_marks)" = "*" ]
}

@test "marks staged changes with +" {
  echo "changed" > tracked.txt
  git add tracked.txt
  [ "$(_prompt_marks)" = "+" ]
}

@test "marks untracked files with ?" {
  echo "new" > untracked.txt
  [ "$(_prompt_marks)" = "?" ]
}

@test "marks a stash with %" {
  echo "changed" > tracked.txt
  git stash -q
  [ "$(_prompt_marks)" = "%" ]
}

@test "shows every mark together in order" {
  echo "staged" > tracked.txt
  git add tracked.txt
  echo "unstaged" > tracked.txt
  echo "new" > untracked.txt
  [ "$(_prompt_marks)" = "*+?" ]
}
