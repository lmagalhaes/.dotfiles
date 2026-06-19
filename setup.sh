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

# If ~/.claude is the old repo-managed symlink, migrate it to the new stow layout.
# Only handles symlinks pointing into this dotfiles repo — intentional custom
# symlinks (e.g. a synced config directory) are left untouched.
LINK_TARGET=""
if [ -L "$HOME/.claude" ]; then
  # cd -P resolves the target portably (readlink -f is GNU-only, absent on macOS).
  # Canonicalize both paths so symlinked components (e.g. macOS /var → /private/var)
  # don't prevent matching the exact old install path.
  _lt="$(cd -P "$HOME/.claude" 2>/dev/null && pwd || true)"
  _legacy="$(cd -P "$DOTFILES/claude-code/.claude" 2>/dev/null && pwd || true)"
  if [ -n "$_lt" ] && [ -n "$_legacy" ] && [ "$_lt" = "$_legacy" ]; then
    LINK_TARGET="$_lt"
  fi
fi

if [ -n "$LINK_TARGET" ]; then
  echo "  Migrating old ~/.claude install from $LINK_TARGET..."
  # Stage all untracked content before stow. Four passes: directory-level moves
  # (efficient for whole trees) then file-level moves inside tracked dirs, each
  # run twice — once for non-ignored and once for gitignored content.
  # The gitignored passes are necessary because sessions/, plugins/, projects/, and
  # settings.local.json are in .gitignore and silently omitted without --ignored.
  RUNTIME_STAGING="$(mktemp -d)"
  # Passes 1 & 3: whole untracked directories (non-ignored, then gitignored).
  for _ls_opts in "" "--ignored --exclude-standard"; do
    # shellcheck disable=SC2086
    git ls-files --others --directory --no-empty-directory $_ls_opts "claude-code/.claude/" \
    | while IFS= read -r gitpath; do
      pkg_rel="${gitpath#"claude-code/.claude/"}"
      pkg_rel="${pkg_rel%/}"
      src="$LINK_TARGET/$pkg_rel"
      [ -e "$src" ] || continue
      mkdir -p "$RUNTIME_STAGING/$(dirname "$pkg_rel")"
      mv "$src" "$RUNTIME_STAGING/$pkg_rel" 2>/dev/null || true
    done
  done
  # Passes 2 & 4: untracked files inside tracked directories (non-ignored, then gitignored).
  for _ls_opts in "" "--ignored --exclude-standard"; do
    # shellcheck disable=SC2086
    git ls-files --others $_ls_opts "claude-code/.claude/" \
    | while IFS= read -r gitpath; do
      pkg_rel="${gitpath#"claude-code/.claude/"}"
      [ -z "$pkg_rel" ] && continue
      src="$LINK_TARGET/$pkg_rel"
      [ -e "$src" ] || continue
      dst="$RUNTIME_STAGING/$pkg_rel"
      mkdir -p "$(dirname "$dst")"
      mv "$src" "$dst" 2>/dev/null || true
    done
  done
  rm "$HOME/.claude"
  mkdir -p "$HOME/.claude"
  # Restore staged files and symlinks into the new real directory at arbitrary depth.
  find "$RUNTIME_STAGING" -mindepth 1 \( -type f -o -type l \) 2>/dev/null \
  | while IFS= read -r staged_file; do
    rel="${staged_file#"$RUNTIME_STAGING/"}"
    dst="$HOME/.claude/$rel"
    mkdir -p "$(dirname "$dst")"
    mv "$staged_file" "$dst" 2>/dev/null || true
  done
  find "$RUNTIME_STAGING" -mindepth 1 -type d 2>/dev/null | sort -r \
  | while IFS= read -r d; do rmdir "$d" 2>/dev/null || true; done
  rmdir "$RUNTIME_STAGING" 2>/dev/null || true
fi

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

# claude-code uses --no-folding so ~/.claude stays a real directory
# A dangling symlink (old target deleted, e.g. after re-cloning) should be cleaned
# up so stow can proceed — it is not a live custom symlink to preserve.
if [ -L "$HOME/.claude" ] && [ ! -e "$HOME/.claude" ]; then
  echo "  Removing dangling ~/.claude symlink (old target no longer exists)..."
  rm "$HOME/.claude"
fi
CLAUDE_CODE_STOWED=false
if [ -L "$HOME/.claude" ] && [ -z "$LINK_TARGET" ]; then
  # ~/.claude is a live custom symlink we did not migrate — stow would abort here.
  echo "  Warning: ~/.claude is a custom symlink — skipping claude-code stow."
  echo "  Remove or replace ~/.claude to install the managed config."
elif [ -d "claude-code" ]; then
  # Pre-create real directories so stow --no-folding does not recreate them as symlinks.
  # Only done here (not unconditionally) to avoid mutating a custom ~/.claude symlink target.
  mkdir -p "$HOME/.claude/hooks"
  echo "  Stowing claude-code (--no-folding)..."
  stow --no-folding -R claude-code
  CLAUDE_CODE_STOWED=true
else
  echo "  Warning: claude-code directory not found, skipping"
fi

# Render managed Claude settings — only when claude-code was stowed
echo ""
echo "Rendering Claude settings..."
if [ "$CLAUDE_CODE_STOWED" = false ]; then
  echo "  Skipping (claude-code package not found)"
elif [ ! -x "$DOTFILES/claude-code/bin/render-settings.sh" ]; then
  echo "  Warning: render-settings.sh not found or not executable, skipping"
elif ! command -v jq &> /dev/null; then
  echo "  Warning: jq not installed — Claude settings not rendered"
  echo "  Install with: brew install jq, then re-run setup.sh"
else
  "$DOTFILES/claude-code/bin/render-settings.sh"
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
