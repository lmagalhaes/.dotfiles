# tmux config

Modular tmux configuration with project session management and plugin support via tpack.

Managed by stow with `~/.config/tmux` as the target (XDG Base Directory).

## Layout

- `tmux.conf` — entry point, stowed to `~/.config/tmux/tmux.conf`. Loads conf modules and binds reload.
- `conf/core.conf` — keybindings, status bar, and general settings.
- `conf/terminal.conf` — terminal colour and feature flags.
- `conf/clipboard.conf` — clipboard integration.
- `conf/plugins.conf` — plugin list and tpack bootstrap.
- `*.sh` — project launcher scripts (fzf chooser, menu, development helper).
- `projects/` — one `.sh` file per project session. See `projects/README.md`.

## Setup

Run `~/.dotfiles/setup.sh`, which stows the package to `~/.config/tmux`:

```bash
stow -R --target "$HOME/.config/tmux" tmux
```

## Plugins

Plugins are managed by [tpack](https://github.com/joshmedeski/tpack) (replaces TPM).

| Key | Action |
|---|---|
| `Prefix I` | Install / update plugins |

`tpack init` runs automatically at the bottom of `plugins.conf` and bootstraps itself on first launch.

## Project sessions

See `projects/README.md` for how to add and configure project sessions.

| Key | Action |
|---|---|
| `Prefix D` | Fuzzy project picker (fzf) |
| `Prefix P` | Traditional grouped menu |
| `Prefix j` | Switch between active sessions |

## Reload config

`Prefix r` — reloads `~/.config/tmux/tmux.conf` in place.
