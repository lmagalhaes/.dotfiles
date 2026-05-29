# Git & Version Control

## Commit Messages

Not Conventional Commits — no `feat:`, `fix:` prefixes.

### Lifecycle

- **During work:** commit freely at checkpoints — progress saves, WIP states. No message quality requirements.
- **Before merging:** `git rebase -i origin/main` is required — squash noise, group related changes, write final messages. This is the gate.
- **Merge:** rebase fast-forward — original commits land on main with SHAs intact, history is linear.

### Format (final commits — post-cleanup, pre-merge)

```
Capitalize and summarize in 50 chars or less

Explain the WHY in the body if it's not obvious from the change.
Wrap body lines at 72 characters. The blank line separating
summary from body is critical — tools like rebase get confused
if they run together.

- Bullet points are fine; use hyphens or asterisks
- No blank lines between bullets
```

### Rules

- Imperative mood: "Fix bug" not "Fixed bug" or "Fixes bug"
- No ticket IDs in the message
- No AI co-author signatures
- Pass multi-line messages via HEREDOC to preserve formatting

### Staging discipline

- Never `git add .` or `git commit -a` — stage only files changed in this session
- Group related changes in one commit; unrelated changes go in separate commits
- Don't commit half-done work — each commit should leave the codebase in a working state

### No noise commits

- Incidental formatting/linting fixes belong squashed into the commit that introduced them
- Exception: intentional, broad formatting or linting changes (whole module or project) stand on their own

## Branch Naming

Format: `[ticket-id]-[concise-title]` — lowercase, hyphens, max 45 chars.
The 45-char cap is enforced by `git wt-create` via slug generation in `git-worktree-common`.

## When to rebase with origin/main

Rebase in these situations — no need to ask:

- **Starting or resuming a session** — fetch and check divergence first; rebase if behind > 0
- **Before opening or updating a PR** — ensures the branch is current and conflicts are resolved before review
- **Before `git rebase -i`** — always sync with origin/main first so interactive cleanup targets a current base

### Checking divergence

```bash
git fetch origin
git rev-list origin/main..HEAD --count   # commits ahead
git rev-list HEAD..origin/main --count   # commits behind
```

If behind > 0: `git rebase origin/main`

## Worktree Safety

- Never delete a worktree while pwd is inside it — cd out first
- Use `git wt-create` / `git wt-rm` rather than raw `git worktree` commands — preserves hook execution
- Use /start-ticket <id> to create/switch; /finish-ticket to clean up

## Dynamic Working Directory

`cd` doesn't persist between Bash tool calls. Use absolute paths in each Bash call, or chain commands with `&&`.

## Dangerous Operations

- Never force-push main/master
- Feature branches after rebase: use `--force-with-lease` over `--force`; no confirmation needed
- Before reset --hard or branch deletion: confirm with user
- Never skip hooks (--no-verify) unless explicitly requested
- Create new commits rather than amending, unless explicitly asked to amend
