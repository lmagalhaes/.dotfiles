# Git & Version Control

## Commit Messages

Style: Descriptive (not Conventional Commits)

```
Brief summary of what and why changed

Optional body when needed for clarity.
Keep succinct — the HOW is in the code.
```

- Explain WHAT changed and WHY
- No AI co-author signatures
- Atomic commits when logical; group related changes
- Pass message via HEREDOC to preserve formatting

## Worktree Safety

- Never delete a worktree while pwd is inside it — cd out first
- Always rebase with base branch before starting/resuming work (unless told otherwise)
- Use `git wt-create` / `git wt-rm` rather than raw `git worktree` commands — preserves hook execution
- Use /start-ticket <id> to create/switch; /finish-ticket to clean up

### When resuming a worktree

Show divergence before starting work:
```bash
git fetch origin
git rev-list origin/main..HEAD --count   # commits ahead
git rev-list HEAD..origin/main --count   # commits behind
```
If behind > 0 and ahead > 0, rebase before continuing.

### After rebase

Check if dependency manifests changed and warn to re-run install:
```bash
git diff ORIG_HEAD..HEAD -- composer.json package.json go.mod Gemfile 2>/dev/null
```
If any changed: warn the user before proceeding.

### .env propagation

Worktrees do not inherit `.env` from the repo root automatically. Before running any command in a new worktree:
- Verify `.env` exists in the worktree root
- If missing: copy from repo root (`cp $REPO_ROOT/.env $WORKTREE_DIR/.env`)

### Container health polling

Never use `sleep N` to wait for containers to be ready. Poll instead:
```bash
timeout 60 bash -c 'until [ "$(docker inspect --format="{{.State.Health.Status}}" CONTAINER)" = "healthy" ]; do sleep 1; done'
```

### Taskfile and worktrees

Taskfile tasks (`task <name>`) target the main branch environment. In worktrees, route commands through `git wt-docker exec <service> <cmd>` instead. Taskfile is not worktree-aware.

## Dynamic Working Directory

`cd` doesn't persist between Bash tool calls. Use absolute paths in each Bash call, or chain commands with `&&`.

## Dangerous Operations

Before force-push, reset --hard, or branch deletion: confirm with user.
Never skip hooks (--no-verify) unless explicitly requested.
Never force-push main/master.
Create new commits rather than amending, unless explicitly asked to amend.
