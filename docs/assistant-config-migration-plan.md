# Assistant Config Split Plan

## Goal

Separate assistant behavior from machine configuration without breaking the
current working setup.

Final ownership:

- `.dotfiles` owns machine bootstrap, package install, linking, and rendering
- `~/.assistant-config` owns authored assistant content only
- `~/.claude` remains the live Claude runtime directory

## Status

Current state:

- plan document created
- fake-home sandbox helper created at `bin/assistant-config-sandbox`
- Phase 1 completed: installer logic now lives under `.dotfiles/assistant/`
- setup entrypoints created at `bin/setup-assistant-config` and
  `bin/update-assistant-config`
- authored repo installed at the final `~/.assistant-config` location
- current installer reads authored source from `~/.assistant-config/claude`

Next step:

- review and commit the migration changes

Resolved decisions:

- the new repo name stays generic: `assistant-config`
- committed `plans/` content does not belong in authored source; ephemeral plans live
  only in `~/.claude/plans/`
- durable documentation should be split by purpose:
  - `docs/` for reference and operational documentation
  - `design/` for committed design decisions and architecture rationale
- machine-specific settings values should live in `~/.claude/settings.local.json`
  for now; `settings.managed.json` should stay portable and shared

Resume instructions:

- start a new session and ask the agent to read
  `docs/assistant-config-migration-plan.md`
- continue from `Phase 1: Prepare Dotfiles Installer Layer`
- use `bin/assistant-config-sandbox` before changing any installer behavior that
  writes to `~/.claude` or `~/.config`

## Final Structure

```text
~/
├── .dotfiles/
│   ├── setup.sh
│   ├── bin/
│   │   ├── setup-assistant-config
│   │   ├── update-assistant-config
│   │   └── assistant-config-sandbox
│   └── assistant/
│       ├── link-claude-entrypoints.sh
│       └── render-claude-settings.sh
│
├── .assistant-config/
│   └── claude/
│       ├── CLAUDE.md
│       ├── RTK.md
│       ├── rules/
│       ├── skills/
│       ├── hooks/
│       ├── tooling/
│       └── settings.managed.json
│
└── .claude/
    ├── authored -> ~/.assistant-config/claude
    ├── CLAUDE.md -> authored/CLAUDE.md
    ├── RTK.md -> authored/RTK.md
    ├── rules -> authored/rules
    ├── skills -> authored/skills
    ├── settings.json
    ├── settings.local.json
    ├── sessions/
    ├── plans/
    ├── plugins/
    ├── projects/
    └── cache/
```

## Ownership Rules

- `~/.assistant-config` is source, versioned, and human-authored
- `~/.dotfiles` installs that source onto the machine
- `~/.claude` is an install target plus runtime directory
- Symlinked entries in `~/.claude` are installer-managed
- Real directories and machine-local files in `~/.claude` are runtime-managed
- No runtime state should live inside `.dotfiles` or `.assistant-config`

## Scope Split

Keep in `.dotfiles`:

- shell/editor/git/tmux/homebrew/macos setup
- assistant bootstrap scripts
- link/render/install orchestration
- optional pinned assistant-config ref

Move to `~/.assistant-config/claude`:

- `claude-code/authored/CLAUDE.md`
- `claude-code/authored/RTK.md`
- `claude-code/authored/rules/`
- `claude-code/authored/skills/`
- `claude-code/authored/hooks/`
- `claude-code/authored/scripts/` renamed to `tooling/`
- `claude-code/authored/config/settings.managed.json` to `settings.managed.json`

Keep machine-local in runtime only:

- `~/.claude/settings.local.json`
- absolute local paths and machine-specific marketplace definitions
- machine-specific permission exceptions

Exception for now:

- the Workyard marketplace definition in `settings.managed.json` stays managed,
  even though it includes a local absolute path, because it is part of the
  intended standard personal setup

Remove from versioned source trees:

- repo-local `.claude/sessions/`
- repo-local `.claude/plans/`
- repo-local `.claude/settings.local.json`

## Migration Phases

### Phase 0: Sandbox First

Do all migration work against a fake home directory.

Requirements:

- real `~/.claude` must remain untouched
- real `~/.config` must remain untouched
- test installs must run with `HOME` pointing to a sandbox

Use:

```bash
~/.dotfiles/bin/assistant-config-sandbox
```

That helper opens a shell with:

- `HOME=/private/tmp/.../home`
- `XDG_CONFIG_HOME=$HOME/.config`
- `XDG_DATA_HOME=$HOME/.local/share`
- `XDG_STATE_HOME=$HOME/.local/state`
- `XDG_CACHE_HOME=$HOME/.cache`
- `~/.dotfiles` pointed at the current checkout

From inside the sandbox shell, all setup work lands in the fake home.

### Phase 1: Prepare Dotfiles Installer Layer

Create installer-owned paths in `.dotfiles`:

- `assistant/link-claude-entrypoints.sh`
- `assistant/render-claude-settings.sh`
- `bin/setup-assistant-config`
- `bin/update-assistant-config`

Rules:

- installer scripts in `.dotfiles` may read from `~/.assistant-config`
- installer scripts may write only to `~/.claude`
- installer scripts must refuse to overwrite unexpected real paths unless forced

### Phase 2: Create Assistant Config Repo

Create a separate repo with only authored content:

```text
.assistant-config/
  claude/
    CLAUDE.md
    RTK.md
    rules/
    skills/
    hooks/
    tooling/
    settings.managed.json
```

Rules:

- no install scripts in this repo
- no runtime directories in this repo
- no mirrored `~/.claude/` tree in this repo
- no committed `plans/` subtree in this repo

### Phase 3: Move Content

Move current Claude-authored assets out of `.dotfiles/claude-code/authored/`:

- `CLAUDE.md`
- `RTK.md`
- `rules/`
- `skills/`
- `hooks/`
- `scripts/` to `tooling/`
- `config/settings.managed.json`

Also remove any committed authored `plans/` content. That name is reserved for
ephemeral runtime state in `~/.claude/plans/`.

If any files currently under authored `plans/` are actually durable:

- move reference and operational material to `docs/`
- move design decisions and architecture rationale to `design/`

### Phase 4: Repoint Installer

Update installer scripts so that:

- `~/.claude/authored` links to `~/.assistant-config/claude`
- `~/.claude/CLAUDE.md` links to `authored/CLAUDE.md`
- `~/.claude/RTK.md` links to `authored/RTK.md`
- `~/.claude/rules` links to `authored/rules`
- `~/.claude/skills` links to `authored/skills`
- `~/.claude/settings.json` is rendered from `settings.managed.json`
- `~/.claude/settings.local.json` remains machine-local and is not installer-managed

Keep `hooks/` and `tooling/` accessed via `~/.claude/authored/...`, not as
top-level runtime namespaces.

### Phase 5: Clean Runtime Leakage

Ensure these are not stored in the dotfiles repo checkout:

- `.claude/sessions/`
- `.claude/plans/`
- `.claude/settings.local.json`
- `.assistant-config/**/plans/`

For this repo specifically, Claude working state should live in the sandbox or
in the real `~/.claude`, not in `~/.dotfiles/.claude`.

### Phase 6: Documentation Cleanup

Update `.dotfiles` docs so they describe the new contract:

- Claude content is not a stow package
- `.dotfiles` bootstraps `~/.assistant-config`
- `~/.claude` is a mixed install target and runtime directory

## Sandbox Workflow

### Open the Sandbox

```bash
~/.dotfiles/bin/assistant-config-sandbox
```

### Verify You Are Isolated

```bash
echo "$HOME"
ls -la ~/.claude
ls -la ~/.config
```

The paths should resolve inside `/private/tmp/...`, not your real home
directory.

### Exercise the Installer

Inside the sandbox shell:

```bash
cd ~/.dotfiles
bash setup.sh
```

Once the new repo exists:

```bash
bash ~/.dotfiles/bin/setup-assistant-config
```

### Inspect Result

```bash
ls -l ~/.claude
cat ~/.claude/settings.json
```

### Reset the Sandbox

Exit the shell, then remove the temp directory:

```bash
rm -rf /private/tmp/assistant-config-sandbox
```

## Risks To Resolve During Migration

- `settings.managed.json` still includes the Workyard marketplace absolute path
  by design for now; revisit only if portability becomes a real problem
- repo-local `.claude` workflow assumptions must be removed from rules if this
  repo is no longer intended to hold live Claude state

## Acceptance Criteria

- running the installer in the sandbox does not touch the real home directory
- Claude-authored content is versioned only in `.assistant-config`
- `.dotfiles` contains only bootstrap and installer logic for Claude
- `~/.claude` clearly shows symlinked authored entries versus runtime entries
- no Claude runtime churn appears in `.dotfiles` git status
- `.assistant-config` can be developed and versioned as a standalone repo
