# Git config (multi-profile)

Modular Git config with visible filenames: shared defaults, per-profile identities, optional per-host overrides, and a global ignore file.

## Layout
- `main.gitconfig` – entrypoint; include this from `~/.gitconfig`.
- `base.gitconfig` – shared defaults (pull/rebase, aliases, LFS filter, etc.).
- `profiles/` – one file per identity (`personal.gitconfig`, `workyard.gitconfig`, plus `profile-template.gitconfig` to copy).
- `hosts/` – optional per-host overrides (name files `<hostname>.gitconfig`).
- `gitignore.global` – global ignore file referenced from `base.gitconfig`.

## Setup

**Note:** Don't symlink `~/.gitconfig` - use an include pattern instead. This allows tools (CodeRabbit, gh, etc.) to add machine-specific configs.

1) Backup your existing `~/.gitconfig` if present.
2) Create `~/.gitconfig` with include:
```bash
cat > ~/.gitconfig << 'EOF'
[include]
    path = ~/.dotfiles/git/main.gitconfig
EOF
```
Or run `~/.dotfiles/setup.sh` which does this automatically.

3) Add or edit profiles under `profiles/` as needed.

## Adding a profile
1) Copy the template:  
```bash
cp ~/.dotfiles/git/profiles/profile-template.gitconfig ~/.dotfiles/git/profiles/client-foo.gitconfig
```
2) Fill in `[user]` (and signing key, if used).  
3) Add an `includeIf` in `main.gitconfig`, e.g.:
```ini
[includeIf "gitdir:~/workspace/client-foo/"]
    path = ~/.dotfiles/git/profiles/client-foo.gitconfig
```

## Optional per-host overrides
Create `hosts/<hostname>.gitconfig` for machine-specific tweaks (credential helper, tool paths) and include it in `main.gitconfig` with an `includeIf` rule that suits your needs (e.g., by branch, remote, or a catch-all include).
