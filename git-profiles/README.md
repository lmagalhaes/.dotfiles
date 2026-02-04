# Git config (multi-profile)

Modular Git config with visible filenames: shared defaults, per-profile identities, optional per-host overrides, and a global ignore file.

## Layout
- `main.gitconfig` – entrypoint; symlink this to `~/.gitconfig`.
- `base.gitconfig` – shared defaults (pull/rebase, aliases, LFS filter, etc.).
- `profiles/` – one file per identity (`personal.gitconfig`, `workyard.gitconfig`, plus `profile-template.gitconfig` to copy).
- `hosts/` – optional per-host overrides (name files `<hostname>.gitconfig`).
- `gitignore.global` – global ignore file referenced from `base.gitconfig`.

## Setup
1) Backup your existing `~/.gitconfig` if present.  
2) Symlink the entrypoint:
```bash
ln -sfn ~/.dotfiles/gitconfig/main.gitconfig ~/.gitconfig
```
3) Add or edit profiles under `profiles/` as needed.

## Adding a profile
1) Copy the template:  
```bash
cp ~/.dotfiles/gitconfig/profiles/profile-template.gitconfig ~/.dotfiles/gitconfig/profiles/client-foo.gitconfig
```
2) Fill in `[user]` (and signing key, if used).  
3) Add an `includeIf` in `main.gitconfig`, e.g.:
```ini
[includeIf "gitdir:~/workspace/client-foo/"]
    path = ~/.dotfiles/gitconfig/profiles/client-foo.gitconfig
```

## Optional per-host overrides
Create `hosts/<hostname>.gitconfig` for machine-specific tweaks (credential helper, tool paths) and include it in `main.gitconfig` with an `includeIf` rule that suits your needs (e.g., by branch, remote, or a catch-all include).
