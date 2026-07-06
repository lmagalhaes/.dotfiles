# shellcheck shell=bash

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"

# shellcheck source=.bash_helpers
source "$DOTFILES_PATH/bash/.bash_helpers"

if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

source_if_exists "$DOTFILES_PATH/macos/.env"
source_if_exists "$DOTFILES_PATH/secrets.env"
source_if_exists "$HOME/.bash/keys.sh"

path_prepend "$HOME/workspace/lmagalhaes/bin"
path_prepend "$HOME/bin"
path_prepend "$DOTFILES_PATH/bin"
path_prepend "$HOMEBREW_PREFIX/opt/libpq/bin"
path_prepend "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin"
path_prepend "$HOMEBREW_PREFIX/opt/mysql-client@8.4/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/go/bin"
path_prepend "${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims"
path_append "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

export HOMEBREW_BUNDLE_FILE="$DOTFILES_PATH/Brewfile"
export BUILDKIT_PROGRESS=plain
export SSH_OPTS="-o StrictHostKeyChecking=accept-new"
export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1
export LESS=FRX

if [[ $- != *i* ]]; then
    return
fi

shopt -s nocaseglob

if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    shopt -s globstar
fi

shopt -s histappend
shopt -s cdspell
shopt -s no_empty_cmd_completion
shopt -s checkwinsize
shopt -s autocd
shopt -s dirspell
shopt -s cmdhist
shopt -s lithist
shopt -s extglob

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/bash/history"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '

if command_exists keychain; then
    eval "$(keychain -q --timeout 480 --eval ~/.ssh/id_ed25519 ~/.ssh/id_rsa)"
fi

if command_exists task; then
    eval "$(task --completion bash)"
fi

if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
    source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
fi

if command_exists aws && command_exists aws_completer; then
    complete -C "$(command -v aws_completer)" aws
fi

source_if_exists "$HOME/.aliases"
source_if_exists "$HOMEBREW_PREFIX/etc/bash_completion.d/git-prompt.sh"
source_if_exists "${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/git-worktree-completion.bash"

source "$DOTFILES_PATH/bash/bash_ps1"

source "$HOME/.orbstack/shell/init.bash" 2>/dev/null || :

if command_exists orb; then
    eval "$(orb completion bash)"
fi

if command_exists zoxide; then
    # eval "$(zoxide init bash)"
    eval "$(zoxide init bash)"
fi
if command_exists fzf; then
    eval "$(fzf  --bash)"
fi

if command_exists mise; then
    eval "$(mise activate bash)"
fi

