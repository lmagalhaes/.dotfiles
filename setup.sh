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

# Ensure XDG state dirs exist
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/bash"

# Change to dotfiles directory (stow requires this)
cd "$DOTFILES"


# Stow packages (target: $HOME)
echo "Installing packages with stow..."
PACKAGES=("bash")

for package in "${PACKAGES[@]}"; do
  if [ -d "$package" ]; then
    echo "  Stowing $package..."
    stow -R "$package"
  else
    echo "  Warning: $package directory not found, skipping"
  fi
done

echo "Generating shell completions..."
COMPLETIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
mkdir -p "$COMPLETIONS_DIR"
if command -v kubectl &> /dev/null; then
  echo "  kubectl..."
  kubectl completion bash > "$COMPLETIONS_DIR/kubectl"
fi
if command -v poetry &> /dev/null; then
  echo "  poetry..."
  poetry completions bash > "$COMPLETIONS_DIR/poetry"
fi

GIT_CONFIG="$HOME/.config/git/config"
GIT_CONFIG_TEMPLATE="$DOTFILES/git/config.template"

# Convert any legacy stowed symlink to a plain file BEFORE stow -R runs.
# stow -R removes the old config symlink (now in .stow-local-ignore) before our
# post-loop block could inspect it, so the migration must happen here.
if [ -L "$GIT_CONFIG" ]; then
  echo "  Migrating git/config: replacing stowed symlink with plain file (preserving content)..."
  cp -L "$GIT_CONFIG" "${GIT_CONFIG}.tmp" 2>/dev/null || cp "$GIT_CONFIG_TEMPLATE" "${GIT_CONFIG}.tmp"
  rm "$GIT_CONFIG"
  mv "${GIT_CONFIG}.tmp" "$GIT_CONFIG"
fi

echo "Installing packages with stow (XDG)..."
PACKAGES=("tmux" "git" "readline" "vim" "ghostty")

for package in "${PACKAGES[@]}"; do
  if [ -d "$package" ]; then
    PACKAGE_CONFIG_DIR="$HOME/.config/$package"
    mkdir -p "$PACKAGE_CONFIG_DIR"
    echo "  Stowing $package..."
    stow -R --target "$PACKAGE_CONFIG_DIR" "$package"
  else
    echo "  Warning: $package directory not found, skipping"
  fi
done

# Generate ~/.config/git/config from template on a fresh install.
if [ ! -f "$GIT_CONFIG" ]; then
  echo "  Generating git/config from template..."
  cp "$GIT_CONFIG_TEMPLATE" "$GIT_CONFIG"
fi

# mise — dedicated block to avoid the mise-config/ dir being mistaken for a project config
# (mise scans for mise/config.toml in the working directory; using mise/ as the package name triggers that)
if [ -d "mise-config" ]; then
  mkdir -p "$HOME/.config/mise"
  echo "  Stowing mise-config -> $HOME/.config/mise"
  stow -R --target "$HOME/.config/mise" mise-config
  if command -v mise &> /dev/null; then
    echo "  Installing mise runtimes..."
    mise trust "$HOME/.config/mise/config.toml"
    mise install
  else
    echo "  Warning: mise not found — install it then run: mise install"
  fi

  if command -v go &> /dev/null; then
    echo "  Installing tpack..."
    go install github.com/tmuxpack/tpack/cmd/tpack@latest
  else
    echo "  Warning: go not found — install it then run: go install github.com/tmuxpack/tpack/cmd/tpack@latest"
  fi
else
  echo "  Warning: mise-config directory not found, skipping"
fi

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
echo "✓ Done! Dotfiles installed with stow."
echo ""
echo "Reload your shell:"
echo "  source ~/.bashrc"
echo ""
echo "To uninstall a package:"
echo "  cd ~/.dotfiles && stow -D <package-name>"
