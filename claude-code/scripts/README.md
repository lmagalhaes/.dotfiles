# Claude Code Scripts

Bash scripts used by Claude Code commands to minimize token usage and improve consistency.

## Architecture

**Hybrid approach:**
- **Bash scripts** handle data gathering, file I/O, and JSON output
- **Claude commands** trigger scripts, apply intelligence, format output
- **Result:** ~70% token reduction per command

## Scripts

### list-sessions.sh

Lists available sessions for the current project.

```bash
~/.claude/scripts/list-sessions.sh [count|all]
```

**Output:** JSON with session summaries

### load-session.sh

Loads session data for display.

```bash
~/.claude/scripts/load-session.sh [options] [count|session-id]

Options:
  --full     Force full display mode
  --compact  Force compact display mode
  --summary  Force summary display mode

Arguments:
  count      Number of sessions to load (default: 1)
  session-id Specific session ID to load
```

**Output:** JSON with full session data + metadata (file_size, counts)

### wrap-session.sh

Gathers environment and saves session files.

```bash
# Get environment data
~/.claude/scripts/wrap-session.sh env

# Save session (JSON from stdin)
echo '{"session_id":...}' | ~/.claude/scripts/wrap-session.sh save
```

**Env output:** session_id, timestamp, working_directory, git_branch, is_worktree, sessions_dir

**Save:** Writes session file, updates index.json, returns success confirmation

## Benefits

| Before (Claude only) | After (Hybrid) |
|----------------------|----------------|
| ~500-800 tokens | ~150-200 tokens |
| Variable output | Consistent JSON |
| Multiple API calls | Single execution |
| Complex path logic | Script handles it |

## Adding Scripts

1. Create `script-name.sh` here
2. `chmod +x script-name.sh`
3. Update corresponding command to call the script
4. Test standalone: `./script-name.sh [args]`

## Path Resolution

All scripts use `pwd -P` for canonical path resolution to handle symlinks correctly.

Git repo detection:
```bash
if git rev-parse --is-inside-work-tree &>/dev/null; then
  REPO_ROOT="$(cd "$(dirname "$(git rev-parse --git-common-dir)")" && pwd -P)"
  SESSIONS_DIR="$REPO_ROOT/.claude/sessions"
else
  SESSIONS_DIR="$(pwd -P)/.claude/sessions"
fi
```
