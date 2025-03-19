#!/usr/bin/env bash

export EDITOR=vim
export LC_ALL=en_AU.UTF-8
DOTFILES_PATH="$HOME/.dotfiles"

if [ -d "$DOTFILES_PATH" ];
then
    source "$DOTFILES_PATH/macos/.env"
fi;

PATH="$HOME/workspace/lmagalhaes/bin/ordermentum/:$HOME/bin/:$PATH"

# Adding brew to path
eval "$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="$HOME/.nvm"
  # This loads nvm
  [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  # This loads nvm bash_completion
  [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

export PATH="$HOMEBREW_PREFIX/opt/libpq/bin:$PATH"
export HOMEBREW_BUNDLE_FILE=$HOME/.dotfiles/Brewfile
# Brew bash completion
[[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"


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
export COLOR_PURPLE='\[\e[0;35m'
export COLOR_LIGHT_PURPLE='\[\e[1;35m\]'
export COLOR_BROWN='\[\e[0;33m\]'
export COLOR_YELLOW='\[\e[1;33m\]'
export COLOR_GRAY='\[\e[0;30m]\'
export COLOR_LIGHT_GRAY='\[\e[0;37m\]'

if [[ -n $(command -v aws) ]];
then
    complete -C '/opt/homebrew/bin/aws_completer' aws
fi;

if [ -d "$HOME/.bash/" ];
then
    source $HOME/.bash/aliases.sh
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

PS1="$COLOR_GREEN\u"
PS1+="@$COLOR_CYAN\h"
PS1+=":$COLOR_LIGHT_BLUE\w"
PS1+="$COLOR_YELLOW "'$(__git_ps1 "[ %s ]")'
PS1+="$COLOR_NC\$ "

export BUILDKIT_PROGRESS=plain


# Added by Toolbox App
export PATH="$PATH:/Users/lmagalhaes/Library/Application Support/JetBrains/Toolbox/scripts"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source "$HOME/.orbstack/shell/init.bash" 2>/dev/null || :

#### WORKYARD CONFIG
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH="$HOME/workspace/workyard/crew-api/vendor/bin:$PATH" 
