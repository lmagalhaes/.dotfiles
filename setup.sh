#!/bin/bash
#
# Dotfiles setup script
# Uses GNU Stow for symlink management
#

set -e

DOTFILES="$HOME/.dotfiles"

echo "Setting up dotfiles..."
echo ""

# Check required tools
if ! command -v stow &> /dev/null; then
  echo "Error: GNU Stow is not installed"
  echo "Install with: brew install stow"
  exit 1
fi

# Change to dotfiles directory (stow requires this)
cd "$DOTFILES"


# Stow packages (target: $HOME)
echo "Installing packages with stow..."
PACKAGES=("vim" "bash" "tmux" "readline" "ghostty")

for package in "${PACKAGES[@]}"; do
  if [ -d "$package" ]; then
    echo "  Stowing $package..."
    stow -R "$package"
  else
    echo "  Warning: $package directory not found, skipping"
  fi
done

# Claude Code — link authored entrypoints and render settings
echo ""
echo "Setting up Claude Code..."
if [ ! -d "claude-code" ]; then
  echo "  Warning: claude-code directory not found, skipping"
elif ! command -v jq &> /dev/null; then
  echo "  Warning: jq not installed — Claude settings not rendered"
  echo "  Install with: brew install jq, then re-run setup.sh"
else
  bash "$DOTFILES/claude-code/scripts/link-claude-entrypoints.sh"
  bash "$DOTFILES/claude-code/scripts/render-claude-settings.sh"
fi

# Stow packages with non-HOME targets
echo ""
echo "Installing packages with custom stow targets..."

RTK_TARGET="$HOME/Library/Application Support/rtk"
if [ -d "rtk" ]; then
  mkdir -p "$RTK_TARGET"
  echo "  Stowing rtk -> $RTK_TARGET"
  stow -R --target "$RTK_TARGET" rtk
else
  echo "  Warning: rtk directory not found, skipping"
fi

echo ""

# Git config (special case - create file with include, not symlink)
# This allows tools to add machine-local config
echo "Setting up git config..."
if [ -L "$HOME/.gitconfig" ]; then
  echo "  Removing old symlink $HOME/.gitconfig"
  rm "$HOME/.gitconfig"
fi

if [ -f "$HOME/.gitconfig" ] && grep -q "path = ~/.dotfiles/git/main.gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
  echo "  Skipping $HOME/.gitconfig (already configured)"
elif [ -f "$HOME/.gitconfig" ] && grep -q "path = ~/.dotfiles/git-profiles/main.gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
  echo "  Updating old git-profiles path to git/"
  sed -i.bak 's|git-profiles/|git/|g' "$HOME/.gitconfig"
  rm "$HOME/.gitconfig.bak"
  echo "  Updated $HOME/.gitconfig"
else
  if [ -f "$HOME/.gitconfig" ]; then
    echo "  Backing up $HOME/.gitconfig to $HOME/.gitconfig.backup"
    mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
  fi
  cat > "$HOME/.gitconfig" << 'EOF'
# Machine-local git config
# Includes dotfiles config, keeps local/tool-generated configs separate
[include]
    path = ~/.dotfiles/git/main.gitconfig

# Machine-specific configs added below by tools (CodeRabbit, etc.)
EOF
  echo "  Created $HOME/.gitconfig"
fi

echo ""
echo "✓ Done! Dotfiles installed with stow."
echo ""
echo "Reload your shell:"
echo "  source ~/.bashrc"
echo ""
echo "To uninstall a package:"
echo "  cd ~/.dotfiles && stow -D <package-name>"
