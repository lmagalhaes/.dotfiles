# Git config (multi-profile)

Modular Git config with visible filenames: shared defaults, per-profile identities, optional per-host overrides, and a global ignore file.

Managed by stow with `~/.config/git` as the target (XDG Base Directory).

## Layout
- `config` – entry point, stowed to `~/.config/git/config`. Contains the include for `main.gitconfig` plus any machine-local tool config (e.g. CodeRabbit machine ID).
- `main.gitconfig` – includes base, profiles, and host overrides via relative paths.
- `base.gitconfig` – shared defaults (pull/rebase, aliases, LFS filter, etc.).
- `profiles/` – one file per identity (`personal.gitconfig`, `workyard.gitconfig`, plus `profile-template.gitconfig` to copy).
- `hosts/` – optional per-host overrides (name files `<hostname>.gitconfig`).
- `ignore` – global ignore file; git reads `~/.config/git/ignore` automatically (no `core.excludesfile` needed).

## Setup

Run `~/.dotfiles/setup.sh`, which stows the package to `~/.config/git`:

```bash
stow -R --target "$HOME/.config/git" git
```

## Adding a profile
1) Copy the template:
```bash
cp ~/.dotfiles/git/profiles/profile-template.gitconfig ~/.dotfiles/git/profiles/client-foo.gitconfig
```
2) Fill in `[user]` (and signing key, if used).
3) Add an `includeIf` in `main.gitconfig`, e.g.:
```ini
[includeIf "gitdir:~/workspace/client-foo/"]
    path = ./profiles/client-foo.gitconfig
```

## Optional per-host overrides
Create `hosts/<hostname>.gitconfig` for machine-specific tweaks (credential helper, tool paths) and include it in `main.gitconfig` with an `includeIf` rule that suits your needs (e.g., by branch, remote, or a catch-all include).
