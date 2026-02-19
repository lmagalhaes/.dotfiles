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

### refresh-worktree-index.sh

Automatically updates the file list in a worktree's docs index.md.

```bash
# Auto-detect branch from current directory
~/.claude/scripts/refresh-worktree-index.sh

# Specify branch explicitly
~/.claude/scripts/refresh-worktree-index.sh PLA-123-feature
```

**Features:**
- Scans worktree docs directory for markdown files (excludes index.md)
- Extracts descriptions from first H1 heading or first paragraph
- Updates "## Files" section in index.md with formatted list
- Preserves ticket metadata and other sections

**Token savings:** ~5k tokens per wrap-session cycle by automating file list updates

### docs-search.sh

Search across all worktree documentation directories for patterns.

```bash
# Search all worktrees
~/.claude/scripts/docs-search.sh "pattern"

# Filter by status
~/.claude/scripts/docs-search.sh "API endpoint" --active
~/.claude/scripts/docs-search.sh "migration" --completed

# Search specific branch
~/.claude/scripts/docs-search.sh "auth" --branch PLA-123-feature

# Case insensitive with context
~/.claude/scripts/docs-search.sh -i "error" -C 3
```

**Options:**
- `--active` - Only search active worktrees
- `--completed` - Only search completed worktrees
- `--all` - Search all worktrees (default)
- `--branch NAME` - Search specific branch only
- `--no-shared` - Exclude shared/ directory
- `-i, --ignore-case` - Case insensitive search
- `-C NUM` - Lines of context (default: 2)

**Features:**
- Groups results by worktree/branch
- Shows ticket IDs from index.md
- Includes line numbers and context
- Searches markdown files in .claude/docs/

**Use cases:**
- Find where a specific pattern was used before
- Locate decisions made in previous tickets
- Search for similar implementations across worktrees

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
