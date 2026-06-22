# Claude Authored/Runtime Separation — Implementation Checklist

## Goal

Separate authored Claude configuration from Claude Code runtime state so that:

- authored files live only in dotfiles
- runtime state lives only in `~/.claude`
- new files under authored trees appear without re-stowing
- shared namespaces like `plans/` are no longer mixed
- `ls -l ~/.claude` makes authored vs runtime ownership obvious

## Target State

### Dotfiles source of truth

```text
~/.dotfiles/claude-code/
├── authored/
│   ├── CLAUDE.md
│   ├── RTK.md
│   ├── config/
│   │   └── settings.managed.json
│   ├── hooks/
│   │   ├── check-meetings.sh
│   │   └── rtk-rewrite.sh
│   ├── plans/
│   │   └── dotfiles/
│   │       └── ...
│   ├── rules/
│   │   └── *.md
│   ├── scripts/
│   │   └── *.sh
│   └── skills/
│       └── */...
└── scripts/
    ├── link-claude-entrypoints.sh
    └── render-claude-settings.sh
```

### Live `~/.claude`

```text
~/.claude/
├── authored -> ~/.dotfiles/claude-code/authored
├── CLAUDE.md -> authored/CLAUDE.md
├── RTK.md -> authored/RTK.md
├── rules -> authored/rules
├── skills -> authored/skills
├── settings.json
├── backups/
├── cache/
├── daemon/
├── downloads/
├── file-history/
├── hooks/
├── jobs/
├── paste-cache/
├── plans/
├── plugins/
├── projects/
├── review-loop/
├── session-env/
├── sessions/
└── shell-snapshots/
```

### Ownership rule

- top-level symlink in `~/.claude` = authored projection
- top-level real directory or real file in `~/.claude` = Claude Code runtime state

## Implementation Checklist

### 1. Create the new dotfiles layout

- [ ] Create `~/.dotfiles/claude-code/authored/`
- [ ] Create `~/.dotfiles/claude-code/scripts/`
- [ ] Move `CLAUDE.md` into `authored/CLAUDE.md`
- [ ] Move `RTK.md` into `authored/RTK.md`
- [ ] Move `config/` into `authored/config/`
- [ ] Move `hooks/` into `authored/hooks/`
- [ ] Move `plans/` into `authored/plans/`
- [ ] Move `rules/` into `authored/rules/`
- [ ] Move `scripts/` into `authored/scripts/`
- [ ] Move `skills/` into `authored/skills/`

### 2. Update managed settings to use authored paths

- [ ] Change `statusLine.command` to `bash ~/.claude/authored/scripts/statusline-command.sh`
- [ ] Change hook commands to `~/.claude/authored/hooks/...`
- [ ] Review all hardcoded paths in `authored/config/settings.managed.json`
- [ ] Replace any old mirrored-dotfiles paths with either `~/.claude/authored/...` or true runtime paths
- [ ] Review permissions entries for stale references to old paths

### 3. Stop projecting authored content into runtime-owned namespaces

- [ ] Remove authored content from top-level `~/.claude/plans/`
- [ ] Keep authored plans only under `~/.dotfiles/claude-code/authored/plans/`
- [ ] Remove dependence on top-level `~/.claude/hooks/` as authored storage
- [ ] Remove dependence on top-level `~/.claude/scripts/` as authored storage

### 4. Add helper scripts

- [ ] Create `~/.dotfiles/claude-code/scripts/link-claude-entrypoints.sh`
- [ ] Make it create or refresh:
  - [ ] `~/.claude/authored`
  - [ ] `~/.claude/CLAUDE.md`
  - [ ] `~/.claude/RTK.md`
  - [ ] `~/.claude/rules`
  - [ ] `~/.claude/skills`
- [ ] Make it refuse to overwrite unexpected real files or directories without an explicit force flag
- [ ] Create `~/.dotfiles/claude-code/scripts/render-claude-settings.sh`
- [ ] Make it render or copy `authored/config/settings.managed.json` to `~/.claude/settings.json`
- [ ] Validate JSON before replacing the live file

### 5. Change the Stow contract

- [ ] Stop using the current mirrored `~/.claude` source tree as the stow package shape
- [ ] Stow the repo so the helper scripts and authored tree are installed, but do not recreate runtime namespaces as per-file links
- [ ] Ensure `rules` and `skills` are installed as directory symlinks, not as real directories containing file symlinks
- [ ] Confirm that adding a new file under `authored/rules/` appears immediately in `~/.claude/rules/`
- [ ] Confirm that adding a new file under `authored/skills/<skill>/` appears immediately in `~/.claude/skills/<skill>/`

### 6. Migrate `~/.claude` safely

- [ ] Create `~/.claude/authored -> ~/.dotfiles/claude-code/authored`
- [ ] Replace top-level `~/.claude/CLAUDE.md` with a symlink to `authored/CLAUDE.md`
- [ ] Replace top-level `~/.claude/RTK.md` with a symlink to `authored/RTK.md`
- [ ] Replace top-level `~/.claude/rules` with a symlink to `authored/rules`
- [ ] Replace top-level `~/.claude/skills` with a symlink to `authored/skills`
- [ ] Render `~/.claude/settings.json`
- [ ] Remove old stowed authored projections for `plans/`, `hooks/`, and `scripts/`
- [ ] Verify that runtime directories such as `sessions/`, `projects/`, and `cache/` remain untouched

### 7. Verify Claude Code behavior

- [ ] Confirm Claude reads `~/.claude/CLAUDE.md`
- [ ] Confirm Claude loads rules from `~/.claude/rules/*.md`
- [ ] Confirm Claude loads skills from `~/.claude/skills/*/SKILL.md`
- [ ] Confirm hooks execute successfully from `~/.claude/authored/hooks/`
- [ ] Confirm the status line command executes from `~/.claude/authored/scripts/statusline-command.sh`
- [ ] Confirm `settings.local.json` and other runtime files still behave normally

### 8. Clean up the old structure

- [ ] Remove the obsolete mirrored `~/.dotfiles/claude-code/.claude/` layout once the migration is verified
- [ ] Update any README or local notes that still describe the old mirrored layout
- [ ] Update any bootstrap or machine-setup scripts to run the new helper scripts

### 9. Steady-state workflow

- [ ] Add new rule files under `authored/rules/` without re-stowing
- [ ] Add new skill files under `authored/skills/` without re-stowing
- [ ] Add new hooks under `authored/hooks/` without re-stowing
- [ ] Add new scripts under `authored/scripts/` without re-stowing
- [ ] Edit `authored/config/settings.managed.json`, then re-render `~/.claude/settings.json`
- [ ] Refresh top-level entrypoints with `scripts/link-claude-entrypoints.sh` only when those specific links change

## Acceptance Criteria

- [ ] `git status` in dotfiles never shows Claude runtime churn
- [ ] No Claude-generated files or directories exist inside the authored dotfiles tree
- [ ] `~/.claude/plans/` contains only Claude runtime plans
- [ ] New files in authored `rules/` and `skills/` appear live without `stow -R`
- [ ] `ls -l ~/.claude` clearly distinguishes symlinked authored entries from real runtime entries
- [ ] Claude behavior matches the current working setup

## Notes

- Perfect top-level segregation inside `~/.claude` is not possible because Claude requires fixed names like `rules/` and `skills/`.
- The readable convention is the important invariant: symlink means authored, real path means runtime.
- The previous migration plan was not saved in a file; it existed only in the task plan state. This document is the first persisted version.
