#!/usr/bin/env bash

source "$HOME/.bashrc"

if command_exists pyenv; then
    eval "$(pyenv init --path --no-rehash)"
fi
