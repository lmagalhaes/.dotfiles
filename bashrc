#!/usr/bin/env bash

export EDITOR=vim
export LC_ALL=en_AU.UTF-8

# Adding brew to path
eval "$(/opt/homebrew/bin/brew shellenv)"

DOTFILES_PATH="$HOME/.dotfiles"
if [ -d "$DOTFILES_PATH" ];
then
    source "$DOTFILES_PATH/macos/.env"
    if [ -f "$DOTFILES_PATH/secrets.env" ];
    then
	source "$DOTFILES_PATH/secrets.env"
    fi;
fi;

PATH="$HOME/.dotfiles/bin:$HOME/bin:$HOME/workspace/lmagalhaes/bin:$PATH"

eval $(keychain -q --timeout 480 --eval ~/.ssh/id_ed25519 ~/.ssh/id_rsa)
eval "$(task --completion bash)"

export NVM_DIR="$HOME/.nvm"
  # This loads nvm
  [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  # This loads nvm bash_completion
  [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

export PATH="$HOMEBREW_PREFIX/opt/libpq/bin:$PATH"
export HOMEBREW_BUNDLE_FILE=$HOME/.dotfiles/Brewfile
# Brew bash completion
[[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

# Load custom bash completions
for completion_file in ~/.bash_completion.d/*; do
    [ -f "$completion_file" ] && source "$completion_file"
done

# Pyenv configuration
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
fi;


export COLOR_NC='\[\e[0m\]' # No Color
export COLOR_WHITE='\[\e[1;37m\]'
export COLOR_BLACK='\[\e[0;30m\]'
export COLOR_BLUE='\[\e[0;34m\]'
export COLOR_LIGHT_BLUE='\[\e[1;34m\]'
export COLOR_GREEN='\[\e[0;32m\]'
export COLOR_LIGHT_GREEN='\[\e[1;32m\]'
export COLOR_CYAN='\[\e[0;36m\]'
export COLOR_LIGHT_CYAN='\[\e[1;36m\]'
export COLOR_RED='\[\e[0;31m\]'
export COLOR_LIGHT_RED='\[\e[1;31m\]'
export COLOR_PURPLE='\[\e[0;35m\]'
export COLOR_LIGHT_PURPLE='\[\e[1;35m\]'
export COLOR_BROWN='\[\e[0;33m\]'
export COLOR_YELLOW='\[\e[1;33m\]'
export COLOR_GRAY='\[\e[0;30m\]'
export COLOR_LIGHT_GRAY='\[\e[0;37m\]'

if [[ -n $(command -v aws) ]];
then
    complete -C '/opt/homebrew/bin/aws_completer' aws
fi;

source $HOME/.dotfiles/aliases

if [ -d "$HOME/.bash/" ];
then
    source $HOME/.bash/keys.sh
    source $HOME/.bash/aws-sso-util-complete-create.sh
    source $HOME/.bash/kubectl-completion.bash
    source $HOME/.bash/poetry-completion.bash
fi;

# Show git branch name at command prompt
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWCOLORHINTS=true

# Function to shorten workspace paths
_shorten_pwd() {
    local pwd="$PWD"
    pwd="${pwd/#$HOME\/workspace\/lmagalhaes/@lm}"
    pwd="${pwd/#$HOME\/workspace\/workyard/@wy}"
    pwd="${pwd/#$HOME/~}"
    echo "$pwd"
}

PS1='$(if [ $? -eq 0 ]; then echo "'$COLOR_GREEN'✓"; else echo "'$COLOR_RED'✗"; fi)'
PS1+=" $COLOR_GREEN\u"
PS1+="@$COLOR_CYAN\h"
PS1+=":$COLOR_LIGHT_BLUE"'$(_shorten_pwd)'
PS1+="$COLOR_YELLOW "'$(__git_ps1 " [ %s ]")'
PS1+="\n$COLOR_NC\$ "

export BUILDKIT_PROGRESS=plain


# Added by Toolbox App
export PATH="$PATH:/Users/lmagalhaes/Library/Application Support/JetBrains/Toolbox/scripts"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source "$HOME/.orbstack/shell/init.bash" 2>/dev/null || :

#### WORKYARD CONFIG
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"

PATH="$HOME/bin:$HOME/workspace/lmagalhaes/flux:$HOME/workspace/lmagalhaes/bin:$PATH"
_FLUX_COMPLETE=bash_source flux > ~/.bash_completion.d/flux

eval "$(orb completion bash)"

for completion_file in ~/.bash_completion.d/*; do
    [ -f "$completion_file" ] && source "$completion_file"
done

export SSH_OPTS="-o StrictHostKeyChecking=accept-new"
export PATH="$HOME/.local/bin:$PATH"
