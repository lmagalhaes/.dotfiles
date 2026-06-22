# shellcheck shell=bash

source "$HOME/.bashrc"

if command_exists pyenv; then
    eval "$(pyenv init --path --no-rehash bash)"
fi
