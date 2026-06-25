# Dotfiles

Personal dotfiles for macOS development environment.

Managed with [GNU Stow](https://www.gnu.org/software/stow/) for clean symlink management.

## Quick Start

```bash
# 1. Clone
git clone git@github.com:lmagalhaes/.dotfiles.git ~/.dotfiles

# 2. Install dependencies
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file=~/.dotfiles/Brewfile

# 3. Run setup (installs all packages with stow)
~/.dotfiles/setup.sh
```

## What is Stow?

GNU Stow creates symlinks from package directories to your home directory. Each package contains files in a structure that mirrors where they should appear in `~`.

**Benefits:**
- Clean, organized package structure
- Easy to install/uninstall individual packages
- No manual symlink management
- Version control friendly

## Package Structure

```
~/.dotfiles/
├── vim/
│   └── .vimrc              → ~/.vimrc
├── bash/
│   ├── .bashrc             → ~/.bashrc
│   ├── .bash_profile       → ~/.bash_profile
│   ├── .aliases            → ~/.aliases
│   └── .bash_completion.d/ → ~/.bash_completion.d/
├── tmux/                   # Stowed to ~/.config/tmux/ (XDG)
│   ├── tmux.conf           → ~/.config/tmux/tmux.conf
│   ├── conf/               → ~/.config/tmux/conf/
│   ├── projects/           → ~/.config/tmux/projects/
│   └── *.sh                → ~/.config/tmux/*.sh
├── claude-code/
│   ├── .claude/            → ~/.claude/
│   │   ├── CLAUDE.md       # Global AI assistant preferences
│   │   ├── commands/       # Custom slash commands
│   │   ├── scripts/        # Supporting bash scripts
│   │   └── contexts/       # Language-specific contexts
│   └── .config/
│       └── claude-code/    → ~/.config/claude-code/
│           └── settings.json
├── git/                    # Stowed to ~/.config/git/ (XDG)
│   ├── config              → ~/.config/git/config
│   ├── main.gitconfig      # Shared entry point (included by config)
│   ├── base.gitconfig      # Shared defaults
│   ├── profiles/           # Per-identity configs
│   └── hosts/              # Per-host overrides
├── bin/                    # Custom scripts (in PATH)
│   └── git-worktree-*      # Git worktree commands
├── Brewfile                # Homebrew dependencies
└── macos/                  # macOS-specific settings
```

## Managing Packages

All commands should be run from `~/.dotfiles/`:

```bash
cd ~/.dotfiles

# Install HOME-target packages
stow vim bash claude-code

# Install XDG packages (tmux, git use ~/.config/<package> as target)
~/.dotfiles/setup.sh

# Reinstall/update a HOME-target package
stow -R bash

# Reinstall/update an XDG package
stow -R --target "$HOME/.config/tmux" tmux

# Uninstall a HOME-target package
stow -D bash

# Dry run (see what would happen)
stow -nv vim
```

## Manual Package Management

If you prefer granular control:

### Install Single Package

```bash
cd ~/.dotfiles
stow vim
```

Creates: `~/.vimrc → ~/.dotfiles/vim/.vimrc`

### Install Multiple Packages

```bash
cd ~/.dotfiles
stow bash claude-code
stow -R --target "$HOME/.config/tmux" tmux
```

### Uninstall Package

```bash
cd ~/.dotfiles
stow -D bash
```

Removes all symlinks created by the bash package.

## Git Configuration

Git config is stowed to `~/.config/git/` (XDG Base Directory) — git reads this location natively with no extra configuration needed.

**Setup (automatic):**
```bash
~/.dotfiles/setup.sh  # Stows git to ~/.config/git/
```

**Manual:**
```bash
stow -R --target "$HOME/.config/git" git
```

See `git/README.md` for multi-profile setup.

## Claude Code

The `claude-code/` package contains configuration for Claude Code CLI:

- **CLAUDE.md** - Global preferences and coding standards
- **commands/** - Custom commands like `/wrap-session`, `/load-session`
- **scripts/** - Bash scripts for session management
- **contexts/** - Language-specific contexts (python.md, bash.md, etc.)

Files are symlinked to:
- `~/.claude/` - User content and runtime data
- `~/.config/claude-code/` - CLI application settings

## Troubleshooting

**Conflicts:**
If stow reports conflicts (file already exists):
```bash
# Back up existing file
mv ~/.bashrc ~/.bashrc.backup

# Then restow
cd ~/.dotfiles && stow -R bash
```

**Wrong location:**
If symlinks point to wrong location:
```bash
# Remove and recreate
cd ~/.dotfiles
stow -D bash  # Remove old symlinks
stow bash     # Create new ones
```

**See what stow will do:**
```bash
stow -nv bash  # Dry run with verbose output
```

## Adding New Files

1. Add file to appropriate package with correct structure:
   ```bash
   # Example: Add new bash alias file
   echo "alias foo='bar'" > bash/.bash_aliases
   ```

2. Restow the package:
   ```bash
   cd ~/.dotfiles && stow -R bash
   ```

3. Commit:
   ```bash
   git add bash/.bash_aliases
   git commit -m "Add bash aliases file"
   ```

## Migration Notes

This dotfiles repo was migrated to stow-based management. Old manual symlinks have been replaced with stow packages. If you have an old setup:

```bash
# Run the updated setup script
~/.dotfiles/setup.sh
```

It will automatically handle the migration.
