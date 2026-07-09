# Git config (multi-profile)

Modular Git config with visible filenames: shared defaults, per-profile identities, optional per-host overrides, and a global ignore file.

Managed by stow with `~/.config/git` as the target (XDG Base Directory).

## Layout
- `config.template` – template for `~/.config/git/config`. Generated into a plain (non-stowed) file by `setup.sh` so tools can write machine-local data (e.g. CodeRabbit machine ID) without dirtying the repo.
- `main.gitconfig` – includes base, profiles, and host overrides via relative paths.
- `base.gitconfig` – shared defaults (pull/rebase, aliases, LFS filter, etc.).
- `profiles/` – one file per identity (`personal.gitconfig`, `workyard.gitconfig`, plus `profile-template.gitconfig` to copy).
- `hosts/` – optional per-host overrides (name files `<hostname>.gitconfig`).
- `ignore` – global ignore file; git reads `~/.config/git/ignore` automatically (no `core.excludesfile` needed).

## Setup

Run `~/.dotfiles/setup.sh`. It stows the package to `~/.config/git` and generates
`~/.config/git/config` from `config.template` if it doesn't already exist:

```bash
~/.dotfiles/setup.sh
```

### Migrating from the old stowed setup

If your machine still has the old `~/.config/git/config` symlink (pointing into the
dotfiles repo), pull may fail if tools like CodeRabbit have written to the file through
that symlink, leaving it locally modified. Clear it first:

```bash
git -C ~/.dotfiles checkout -- git/config   # discard local tool writes
git -C ~/.dotfiles pull
~/.dotfiles/setup.sh                        # converts the symlink to a plain file
```

After `setup.sh` runs, `~/.config/git/config` is a plain file and future tool writes
stay out of the repo.

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
