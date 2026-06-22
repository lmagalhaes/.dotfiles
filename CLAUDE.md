# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup & Installation

```bash
# Full install (stow all packages + git config)
~/.dotfiles/setup.sh

# Install or reinstall a single package
cd ~/.dotfiles && stow -R <package>

# Dry run to preview changes
cd ~/.dotfiles && stow -nv <package>

# Remove a package's symlinks
cd ~/.dotfiles && stow -D <package>
```

Stow packages: `vim bash tmux readline ghostty`

## Package Management

```bash
# Regenerate Brewfile from currently installed packages
update-brewfile

# Install all packages from Brewfile
brew bundle --file=~/.dotfiles/Brewfile
```

## Architecture

### Stow-based symlink management

Each top-level directory is a stow **package**. Files inside mirror their destination path relative to `$HOME`. For example, `bash/.bashrc` → `~/.bashrc`.

`stow` is always run from `~/.dotfiles/` — it uses the current directory as the stow dir and `$HOME` as the target.

### Git config (not stowed)

`~/.gitconfig` is a real file (not a symlink) containing a single `[include]` pointing to `~/.dotfiles/git/main.gitconfig`. This lets tools (gh, CodeRabbit, etc.) append machine-specific config without polluting version control.

**Config load order:** `main.gitconfig` → `base.gitconfig` → profile (`profiles/*.gitconfig`) → host override (`hosts/*.gitconfig`). Profile and host files are included via `includeIf` rules in `main.gitconfig`.

To add a new identity, copy `git/profiles/profile-template.gitconfig` and add an `includeIf "gitdir:..."` in `main.gitconfig`.

### bin/ — git worktree scripts

Scripts in `bin/` are available as git subcommands (e.g., `git worktree-create`). They share logic via `git-worktree-common`, which provides:
- `get_repo_root_physical()` — symlink-resolved path (for comparisons against `git worktree list`)
- `get_repo_root_logical()` — symlink-preserving path (for display and general use)
- `get_branch_slug()` — lowercased, URL-safe slug from a branch name

Worktrees are created under `<repo>/.worktrees/<branch-name>/`. The create script also generates a Docker compose file from `templates/compose.worktree.template.yaml` for parallel container environments.

### claude-code/ directory (not stowed)

Contains all authored Claude Code configuration. Not managed by stow — `setup.sh` calls two helper scripts instead:

- `scripts/link-claude-entrypoints.sh` — creates directory-level symlinks in `~/.claude/` pointing into `authored/`
- `scripts/render-claude-settings.sh` — merges `authored/config/settings.managed.json` into `~/.claude/settings.json`

`authored/` holds rules, skills, hooks, scripts, and plans. A new file added under `authored/rules/` or `authored/skills/` appears live in `~/.claude/` immediately without re-running setup.

### macos/

- `defaults.sh` — applies macOS system defaults (Finder, trackpad, etc.)
- `install.sh` — one-time machine bootstrap (timezone, dock, etc.)

These are run manually, not via stow.
