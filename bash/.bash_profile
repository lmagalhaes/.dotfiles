# shellcheck shell=bash

export EDITOR=vim
export VISUAL=vim
export LESS='-RFX'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

source "$HOME/.bashrc"

if command_exists pyenv; then
    eval "$(pyenv init --path --no-rehash bash)"
fi
