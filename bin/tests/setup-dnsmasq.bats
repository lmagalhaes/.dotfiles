#!/usr/bin/env bats
#
# Tests for bin/setup-dnsmasq
#

bats_require_minimum_version 1.5.0

load test_helper

SCRIPT="$BIN_DIR/setup-dnsmasq"

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  export BREW_PREFIX="$TEST_ROOT/brew"
  export RESOLVER_DIR="$TEST_ROOT/resolver"
  export COMMAND_STUB_LOG="$TEST_ROOT/command-calls"
  CONF_DIR="$BREW_PREFIX/etc/dnsmasq.d"
  mkdir -p "$CONF_DIR"
  : > "$COMMAND_STUB_LOG"
  unset DNSMASQ_STUB_FAILING
  _use_stubs
}

MANAGED_MARKER="# Managed by ~/.dotfiles/bin/setup-dnsmasq"

_write_managed_resolver() {
  mkdir -p "$RESOLVER_DIR"
  printf '%s\nnameserver 127.0.0.1\n' "$MANAGED_MARKER" > "$RESOLVER_DIR/$1"
}

@test "links the dotfiles config into the dnsmasq drop-in directory" {
  run --separate-stderr "$SCRIPT"
  [ -L "$CONF_DIR/base.conf" ]
}

@test "removes the link of a config file deleted from the dotfiles" {
  ln -s "$TEST_ROOT/deleted-project.conf" "$CONF_DIR/deleted-project.conf"
  run --separate-stderr "$SCRIPT"
  [ ! -L "$CONF_DIR/deleted-project.conf" ]
}

@test "writes a resolver pointing at loopback for a local domain" {
  run --separate-stderr "$SCRIPT"
  grep -qx "nameserver 127.0.0.1" "$RESOLVER_DIR/workyard.test"
}

@test "marks the resolvers it writes as managed by the dotfiles" {
  run --separate-stderr "$SCRIPT"
  [ "$(head -1 "$RESOLVER_DIR/workyard.test")" = "$MANAGED_MARKER" ]
}

@test "removes a managed resolver whose domain has no config file" {
  _write_managed_resolver deleted-project.test
  run --separate-stderr "$SCRIPT"
  [ ! -e "$RESOLVER_DIR/deleted-project.test" ]
}

@test "keeps a resolver another tool wrote" {
  mkdir -p "$RESOLVER_DIR"
  echo "nameserver 127.0.0.1" > "$RESOLVER_DIR/other-tool.test"
  run --separate-stderr "$SCRIPT"
  [ -e "$RESOLVER_DIR/other-tool.test" ]
}

@test "writes one resolver per local domain, not per address line" {
  run --separate-stderr "$SCRIPT"
  [ "$(ls "$RESOLVER_DIR" | sort | tr '\n' ' ')" = "magamaker.test workyard.test " ]
}

@test "leaves an up-to-date resolver untouched" {
  for domain in workyard.test magamaker.test; do
    _write_managed_resolver "$domain"
  done
  run --separate-stderr "$SCRIPT"
  ! grep -q "^sudo tee" "$COMMAND_STUB_LOG"
}

@test "checks the config with the drop-in directory dnsmasq runs with" {
  run --separate-stderr "$SCRIPT"
  grep -qxF "dnsmasq --test -C $BREW_PREFIX/etc/dnsmasq.conf -7 $CONF_DIR,*.conf" "$COMMAND_STUB_LOG"
}

@test "restarts the root service after the config check passes" {
  run --separate-stderr "$SCRIPT"
  grep -qxF "sudo brew services restart dnsmasq" "$COMMAND_STUB_LOG"
}

@test "fails when the config check fails" {
  export DNSMASQ_STUB_FAILING=1
  run --separate-stderr "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "does not restart the service when the config check fails" {
  export DNSMASQ_STUB_FAILING=1
  run --separate-stderr "$SCRIPT"
  ! grep -q "services restart" "$COMMAND_STUB_LOG"
}
