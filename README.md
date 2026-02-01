# Dotfiles

Personal dotfiles for macOS development environment.

## Quick Start

```bash
# 1. Clone
git clone git@github.com:lmagalhaes/.dotfiles.git ~/.dotfiles

# 2. Install dependencies
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file=~/.dotfiles/Brewfile

# 3. Run setup
~/.dotfiles/setup.sh
```

## Manual Setup

If you prefer manual setup or need to set up individual components:

### Shell

```bash
ln -sf ~/.dotfiles/bashrc ~/.bashrc
ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
```

### Git

```bash
ln -sf ~/.dotfiles/git-profiles/main.gitconfig ~/.gitconfig
```

### Vim

```bash
ln -sf ~/.dotfiles/vimrc ~/.vimrc
```

### Tmux

```bash
ln -sf ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
```

### Claude Code

```bash
mkdir -p ~/.claude
ln -sf ~/.dotfiles/claude-code/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/.dotfiles/claude-code/scripts ~/.claude/scripts
ln -sf ~/.dotfiles/claude-code/commands ~/.claude/commands
ln -sf ~/.dotfiles/claude-code/contexts ~/.claude/contexts
```

## Structure

```
~/.dotfiles/
├── bashrc, bash_profile    # Shell configuration
├── vimrc                   # Vim configuration
├── tmux/                   # Tmux configuration
├── git-profiles/           # Git configuration (supports multiple profiles)
├── bin/                    # Custom scripts (added to PATH)
├── claude-code/            # Claude Code configuration
│   ├── CLAUDE.md           # Global AI assistant preferences
│   ├── commands/           # Custom slash commands
│   ├── scripts/            # Supporting bash scripts
│   └── contexts/           # Language/domain-specific contexts
├── Brewfile                # Homebrew dependencies
└── macos/                  # macOS-specific settings
```

## Claude Code

The `claude-code/` directory contains configuration for Claude Code CLI:

- **CLAUDE.md** - Global preferences and coding standards
- **commands/** - Custom commands like `/wrap-session`, `/load-session`
- **scripts/** - Bash scripts for session management
- **contexts/** - Language-specific contexts (python.md, bash.md, etc.)

These are symlinked to `~/.claude/` for Claude Code to pick up.
