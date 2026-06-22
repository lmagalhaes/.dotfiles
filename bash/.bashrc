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
path_prepend "$HOMEBREW_PREFIX/opt/mysql@8.0/bin"
path_prepend "$HOME/.local/bin"
path_append "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

export NVM_DIR="$HOME/.nvm"
export HOMEBREW_BUNDLE_FILE="$DOTFILES_PATH/Brewfile"
export BUILDKIT_PROGRESS=plain
export SSH_OPTS="-o StrictHostKeyChecking=accept-new"
export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1

if [[ $- != *i* ]]; then
    return
fi

if [[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
    source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
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

if [[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]]; then
    source "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
fi

if command_exists pyenv; then
    eval "$(pyenv init - --no-rehash bash)"
fi

if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
    source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
fi

if command_exists aws && command_exists aws_completer; then
    complete -C "$(command -v aws_completer)" aws
fi

source_if_exists "$HOME/.aliases"
source_if_exists "$HOME/.bash/aws-sso-util-complete-create.sh"
source_if_exists "$HOME/.bash/kubectl-completion.bash"
source_if_exists "$HOME/.bash/poetry-completion.bash"
source_if_exists "$HOME/.bash/git-prompt.sh"

export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWDIRTYSTATE=true

COLOR_NC='\[\e[0m\]'
COLOR_GREEN='\[\e[0;32m\]'
COLOR_CYAN='\[\e[0;36m\]'
COLOR_LIGHT_BLUE='\[\e[1;34m\]'
COLOR_RED='\[\e[0;31m\]'
_shorten_pwd() {
    local pwd="$PWD"
    pwd="${pwd/#$HOME\/workspace\/lmagalhaes/@lm}"
    pwd="${pwd/#$HOME\/workspace\/workyard/@wy}"
    pwd="${pwd/#$HOME/~}"
    printf '%s' "$pwd"
}

_set_ps1() {
    local exit_status=$?
    local status_icon
    if [ $exit_status -eq 0 ]; then
        status_icon="${COLOR_GREEN}✓"
    else
        status_icon="${COLOR_RED}✗"
    fi
    local pre
    pre="${status_icon} ${COLOR_GREEN}\\u@${COLOR_CYAN}\\h:${COLOR_LIGHT_BLUE}$(_shorten_pwd)"
    local post="\n${COLOR_NC}\\$ "
    if declare -F __git_ps1 >/dev/null 2>&1; then
        __git_ps1 "$pre" "$post" " [ %s ]"
    else
        PS1="${pre}${post}"
    fi
}

PROMPT_COMMAND=(_set_ps1)

source "$HOME/.orbstack/shell/init.bash" 2>/dev/null || :

if command_exists orb; then
    eval "$(orb completion bash)"
fi

for completion_file in "$HOME"/.bash_completion.d/*; do
    [[ -f "$completion_file" ]] && source "$completion_file"
done

if command_exists zoxide; then
    eval "$(zoxide init bash)"
fi
if command_exists fzf; then
    eval "$(fzf  --bash)"
fi
