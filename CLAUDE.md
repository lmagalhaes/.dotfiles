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

Stow packages: `vim bash tmux readline ghostty herdr`

## Package Management

```bash
# Regenerate Brewfile from currently installed packages
update-brewfile

# Install all packages from Brewfile
brew bundle --file=~/.dotfiles/Brewfile
```

## Tests

```bash
# All bats suites, 8 at a time (needs GNU parallel, in the Brewfile)
bats --jobs 8 bin/tests/
```

Use this as the test command, including `/review-loop --test-cmd`. Eight jobs is
fastest on this 10-core machine (about 2.5x faster than serial); more jobs are no
faster.

## Architecture

### Stow-based symlink management

Each top-level directory is a stow **package**. Files inside mirror their destination path relative to `$HOME`. For example, `bash/.bashrc` → `~/.bashrc`.

`stow` is always run from `~/.dotfiles/` — it uses the current directory as the stow dir and `$HOME` as the target.

### Git config (stowed to `~/.config/git`)

The `git/` package is stowed with `~/.config/git` as the target — git reads this location natively via XDG. Stow is run with `stow -R --target "$HOME/.config/git" git` in `setup.sh`.

`~/.config/git/config` is the entry point (stowed symlink). It includes `main.gitconfig` and holds any machine-local tool config (e.g. CodeRabbit machine ID) that tools append directly.

**Config load order:** `config` → `main.gitconfig` → `base.gitconfig` → profile (`profiles/*.gitconfig`) → host override (`hosts/*.gitconfig`). All includes use relative paths. Profile and host files are included via `includeIf` rules in `main.gitconfig`.

`ignore` is stowed to `~/.config/git/ignore` — git reads it automatically with no `core.excludesfile` needed.

To add a new identity, copy `git/profiles/profile-template.gitconfig` and add an `includeIf "gitdir:..."` in `main.gitconfig`.

### bin/ — git worktree scripts

Scripts in `bin/` are available as git subcommands (e.g., `git worktree-create`). They share logic via `git-worktree-common`, which provides:
- `get_repo_root_physical()` — symlink-resolved path (for comparisons against `git worktree list`)
- `get_repo_root_logical()` — symlink-preserving path (for display and general use)
- `get_branch_slug()` — lowercased, URL-safe slug from a branch name

Worktrees are created under `<repo>/.worktrees/<branch-name>/`. The create script also generates a Docker compose file from `templates/compose.worktree.template.yaml` for parallel container environments.

### assistant config installer layer (not stowed)

Dotfiles now own the installer layer for Claude Code. `setup.sh` calls:

- `bin/setup-assistant-config` — refreshes `~/.claude` entrypoints and renders managed settings
- `assistant/link-claude-entrypoints.sh` — reads authored source from `~/.assistant-config/claude`
- `assistant/render-claude-settings.sh` — merges `authored/settings.managed.json` into `~/.claude/settings.json`

The authored source lives in `~/.assistant-config/claude/`. It holds rules, skills, hooks, tooling, docs, design notes, and `settings.managed.json`. A new file added under `rules/` or `skills/` appears live in `~/.claude/` immediately without re-running setup.

### dnsmasq/ (stowed into Homebrew's dnsmasq.d)

Resolves local dev domains (`*.workyard.test`, `*.magamaker.test`, ...) to
loopback. `bin/setup-dnsmasq` stows the package into `$(brew --prefix)/etc/dnsmasq.d`,
writes `/etc/resolver/<domain>` for each `address=/<domain>/` line, checks the
config and restarts the service. dnsmasq runs as root (`sudo brew services`)
because it binds port 53. Shared options live only in `base.conf`: dnsmasq
refuses to start when a keyword like `cache-size` is repeated. To add a domain,
add a `dnsmasq/<project>.conf` with only its `address=` lines and re-run
`bin/setup-dnsmasq`. To drop one, delete its file and re-run: the script removes
its link and the `/etc/resolver` file it wrote, marked `# Managed by ...`.
It leaves unmarked resolver files alone, since other tools write those.

### macos/

- `defaults.sh` — applies macOS system defaults (Finder, trackpad, etc.)

These are run manually, not via stow.
