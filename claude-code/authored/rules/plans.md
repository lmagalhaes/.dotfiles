# Plans

## Storage Location

Save plans to `.claude/plans/<branch>/plan-<slug>.md`:
- Regular projects: `<repo>/.claude/plans/<branch>/`
- Dotfiles repo: `~/.claude/plans/<branch>/`

Where `<branch>` is the current git branch and `<slug>` is a short kebab-case descriptor of the plan topic.

## Rules

- Never save plans to `claude-code/plans/` or any stow-managed path — those get symlinked into `~/.claude/` and pollute the dotfiles repo
- Plans are branch-local working artifacts — not committed, not stowed
- `.claude/plans/` is gitignored globally; no need to add it per-project
- When a plan becomes irrelevant (branch merged, approach abandoned), delete it
