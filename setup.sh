#!/bin/bash
#
# Dotfiles setup script
# Creates symlinks from home directory to dotfiles
#

set -e

DOTFILES="$HOME/.dotfiles"

echo "Setting up dotfiles..."

# Helper function
link() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    echo "  Skipping $dest (symlink exists)"
  elif [ -e "$dest" ]; then
    echo "  Backing up $dest to $dest.backup"
    mv "$dest" "$dest.backup"
    ln -s "$src" "$dest"
    echo "  Linked $dest"
  else
    ln -s "$src" "$dest"
    echo "  Linked $dest"
  fi
}

# Shell
echo "Shell..."
link "$DOTFILES/bashrc" "$HOME/.bashrc"
link "$DOTFILES/bash_profile" "$HOME/.bash_profile"

# Git (create file with include, not symlink - allows tools to add machine-local config)
echo "Git..."
if [ -L "$HOME/.gitconfig" ]; then
  echo "  Removing old symlink $HOME/.gitconfig"
  rm "$HOME/.gitconfig"
fi
if [ -f "$HOME/.gitconfig" ] && grep -q "path = ~/.dotfiles/git-profiles/main.gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
  echo "  Skipping $HOME/.gitconfig (already configured)"
else
  if [ -f "$HOME/.gitconfig" ]; then
    echo "  Backing up $HOME/.gitconfig to $HOME/.gitconfig.backup"
    mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
  fi
  cat > "$HOME/.gitconfig" << 'EOF'
# Machine-local git config
# Includes dotfiles config, keeps local/tool-generated configs separate
[include]
    path = ~/.dotfiles/git-profiles/main.gitconfig

# Machine-specific configs added below by tools (CodeRabbit, etc.)
EOF
  echo "  Created $HOME/.gitconfig"
fi

# Vim
echo "Vim..."
link "$DOTFILES/vimrc" "$HOME/.vimrc"

# Tmux
echo "Tmux..."
link "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# Claude Code
echo "Claude Code..."
mkdir -p "$HOME/.claude"
link "$DOTFILES/claude-code/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude-code/scripts" "$HOME/.claude/scripts"
link "$DOTFILES/claude-code/commands" "$HOME/.claude/commands"
link "$DOTFILES/claude-code/contexts" "$HOME/.claude/contexts"

echo ""
echo "Done! Reload your shell:"
echo "  source ~/.bashrc"
