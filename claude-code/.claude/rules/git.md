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
- Always rebase with main before starting/resuming work (unless told otherwise)
- Parallel Docker containers per worktree — no need to stop main
- Use /start-ticket <id> to create/switch; /finish-ticket to clean up

## Dynamic Working Directory

`cd` doesn't persist between Bash tool calls. To change logical CWD:
```bash
/Users/lmagalhaes/.claude/set-cwd.sh "<original_workspace>" "<new_directory>"
```

## Dangerous Operations

Before force-push, reset --hard, or branch deletion: confirm with user.
Never skip hooks (--no-verify) unless explicitly requested.
Never force-push main/master.
Create new commits rather than amending, unless explicitly asked to amend.
