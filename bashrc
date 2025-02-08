export EDITOR=vim
export LC_ALL=en_AU.UTF-8
N_PREFIX="~/.n_module"
PATH="$N_PREFIX/:~/workspace/lmagalhaes/bin/ordermentum/:~/bin/:$PATH"

# Adding brew to path
eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$HOMEBREW_PREFIX/opt/libpq/bin:$PATH"
export HOMEBREW_BUNDLE_FILE=$HOME/.dotfiles/Brewfile
# Brew bash completion
[[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"


# Pyenv configuration
if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init --path)"
fi;

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWCOLORHINTS=true

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

# Show git branch name at command prompt
source $HOME/.bash/git-prompt.sh
source $HOME/.bash/aliases.sh
source $HOME/.bash/keys.sh
source $HOME/.bash/aws-sso-util-complete-create.sh
source $HOME/.bash/kubectl-completion.bash
source $HOME/.bash/poetry-completion.bash

export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWDIRTYSTATE=true

PS1="$COLOR_GREEN\u"
PS1+="@$COLOR_CYAN\h"
PS1+=":$COLOR_LIGHT_BLUE\w"
PS1+="$COLOR_YELLOW "'$(__git_ps1 "[ %s ]")'
PS1+="$COLOR_NC\$ "

export BUILDKIT_PROGRESS=plain


# Added by Toolbox App
export PATH="$PATH:/Users/lmagalhaes/Library/Application Support/JetBrains/Toolbox/scripts"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

# Ordermentum configuration
export N_PREFIX=$HOME
export PATH=$N_PREFIX/bin:$PATH
