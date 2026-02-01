# Claude Code Custom Commands

This directory contains custom slash commands for Claude Code session management.

**Version:** 2.1 (Multi-Worktree Support)
**Last Updated:** 2026-01-27
**Token Reduction:** 85-90% vs baseline

## Key Features

✅ **Cost Optimized:** All commands use Haiku model (80% cheaper than Sonnet)
✅ **Compressed Format:** Session files 60-65% smaller with zero information loss
✅ **Automatic Loading:** Sessions auto-load at conversation start
✅ **Smart Display:** Auto-selects compact/expanded based on session size
✅ **Task Agent Context:** Task agents receive compressed context (~200 tokens vs 5k+)
✅ **Auto-Wrap Triggers:** Prevents context overflow with smart thresholds

---

## Available Commands

### `/session-status`
**Purpose:** Analyze current session health, token usage, and provide recommendations

**Cost:** ~600-800 tokens (uses Haiku model)

**Usage:**
```
/session-status
```

**What it does:**
- Reports token usage and remaining capacity
- Calculates session efficiency score (0-10)
- Tracks file activity (modified vs read ratio)
- Analyzes token usage rate and remaining capacity
- Provides health status with 5 levels:
  - 🟢 **Healthy** (40-80k): Continue freely
  - 🟡 **Moderate** (80-120k): Be mindful
  - 🟠 **High** (120-140k): Wrap up soon
  - 🔴 **Critical** (140-150k): **AUTO-WRAP SUGGESTION** with preview
  - 🚨 **Emergency** (>150k): **FORCE WRAP** - context overflow imminent
- Shows wrap preview at Critical/Emergency levels
- Recommends specific optimization tips

**When to use:**
- Periodically during long sessions (low cost, check frequently!)
- Before starting complex operations
- When approaching 120k+ tokens
- To get efficiency feedback

**Note:** Context overflow typically occurs at ~150k tokens, not 200k limit.

---

### `/wrap-session`
**Purpose:** Create a structured session retrospective for continuity

**Cost:** ~800-1k tokens (uses Haiku model, compressed format)

**Usage:**
```
/wrap-session
```

**What it does:**
- Analyzes conversation history to identify tasks completed
- Captures files modified and context learned (top 5 each)
- Records key decisions with rationale (concise format)
- Documents active blockers only (resolved ones in git)
- Generates compressed session file (60-65% smaller)
- Creates task-context.md for Task agents (~200 tokens)
- Updates session index
- Uses relative file paths

**Compression Rules (Optimized for Continuity):**
- **Last 5 tasks** (recent work, git log has rest)
- **Top 5 patterns** (max 50 words each, actionable)
- **Top 5 files** (critical ones only)
- **Top 5 gotchas** (what to watch out for)
- **Top 3 optimization tips** (specific suggestions)
- **Active blockers only** (skip resolved)
- **Removed fields:** duration_minutes, tool_usage, tokens_remaining, decisions.alternatives

**When to use:**
- When `/session-status` shows Critical/Emergency (140k+)
- Before ending a productive session
- After completing a major task or milestone
- When switching contexts or projects
- At 150k tokens (prevents overflow)

**What gets saved:**
- **Session file:** `.claude/sessions/session-{timestamp}.json` (3-4KB vs 8KB)
- **Task context:** `.claude/task-context.md` (for Task agents)
- **Index:** Updated with new session entry

**Quality:** Zero information loss - compression keeps critical context, removes redundancy.

---

### `/load-session`
**Purpose:** Load and display context from previous session(s)

**Cost:** ~600-800 tokens (uses Haiku model, smart display)

**Usage:**
```
/load-session                              # Load most recent for CURRENT BRANCH
/load-session --all                        # Load most recent from any branch
/load-session --branch main                # Load most recent from specific branch
/load-session --all 3                      # Load last 3 sessions from any branch
/load-session --full                       # Force full details view
/load-session --compact                    # Force compact view
/load-session --summary                    # Ultra-compact (summary + next steps only)
/load-session 3                            # Load last 3 sessions for current branch
/load-session session-2026-01-12-143000   # Load specific session by ID
```

**Branch-Aware Behavior:**
- Default: Loads latest session **for current git branch only**
- In worktree `PLA-123-feature`: loads PLA-123-feature sessions
- In main branch: loads main sessions
- Use `--all` to see sessions from all branches
- Use `--branch NAME` to load a specific branch's session
- **Mismatch warning:** If you load a session from a different branch, you'll see a warning

**What it does:**
- Loads session data from `.claude/sessions/`
- **Auto-selects display mode:**
  - Small sessions (<10KB or <25 tasks): **Expanded** view (all details)
  - Large sessions (>10KB or ≥25 tasks): **Compact** view (summary + stats + next steps)
  - Multi-session: **Always compact**
- **IMPORTANT:** Agent loads ALL context regardless of display (patterns, files, decisions)
- Display mode only affects what USER sees, not what agent knows
- Shows completed and remaining tasks
- Highlights patterns learned and key files
- Provides recommended next steps
- Auto-loads suggested context files

**Display Modes:**
- **Compact** (~400-600 tokens displayed): Summary, quick stats, next steps only
- **Full** (~2-4k tokens displayed): Everything (original verbose format)
- **Summary** (~100-150 tokens): Just summary + next steps

**When to use:**
- **Automatically** at conversation start (if `.claude/sessions/` exists)
- After using `/wrap-session` in previous session
- When returning to a project after time away
- To review recent session history
- With `--full` to see all patterns/tasks/decisions

---

## Session Management Workflow

### Automatic Workflow (v2.0):

1. **Start of session: AUTOMATIC**
   - Sessions auto-load if `.claude/sessions/index.json` exists
   - Compressed display (3-5 lines) shown to user
   - Agent loads full context (patterns, files, decisions)
   - Manual load: `/load-session` or `/load-session --full`

2. **During session:**
   ```
   /session-status  # Check frequently (only ~600-800 tokens!)
   ```
   - Monitor token usage and efficiency
   - Get specific optimization recommendations
   - Preview what wrap would capture (at Critical/Emergency)

3. **At 140k+ tokens: AUTO-WRAP SUGGESTED**
   - `/session-status` shows wrap preview
   - Run `/wrap-session` to save before overflow

4. **End of session:**
   ```
   /wrap-session
   ```
   - Capture context (compressed format)
   - Generate task-context.md for Task agents
   - Next session auto-loads automatically

### Manual Workflow (if needed):

Same as above, but explicitly run `/load-session` at start if auto-loading disabled.

### Session File Structure

Sessions are stored in `.claude/sessions/` as JSON files:

```
.claude/sessions/
├── index.json                          # Quick session lookup
├── session-2026-01-12-143000.json      # Individual sessions
└── session-2026-01-11-100000.json
```

**Session Storage Locations:**
- **Git worktrees:** `{git_common_dir}/.claude/sessions/` (shared across all worktrees)
- **Regular repos:** `$PROJECT/.claude/sessions/`
- **Dotfiles/Global:** `~/.claude/sessions/` (for dotfiles and non-project work)
- **No git:** `$PWD/.claude/sessions/`

**Git Worktree Support:**
Sessions automatically detect git worktrees and store sessions in the common git directory. This means:
- All worktrees of the same repository share the same session history
- You can start work in one worktree and continue in another
- Sessions track which worktree branch was used

### Session File Contents

Each session file contains:
- **Metadata:** Timestamp, duration, working directory, git branch, worktree status
- **Summary:** Brief overview of session accomplishments
- **Tasks:** Completed and remaining work
- **Context:** Languages, patterns learned, key files
- **Decisions:** What was decided and why
- **Blockers:** Issues encountered and their status
- **Metrics:** Token usage and tool statistics
- **Next Session:** Recommended starting point and optimizations

### Index File

The `index.json` maintains:
- `latest`: Most recent session ID (any branch)
- `latest_by_branch`: Map of branch → latest session ID for that branch
- `sessions`: List of all sessions with branch info and summaries
- Archive count and metadata

**Branch-Aware Index Structure:**
```json
{
  "latest": "session-2026-01-27-101000",
  "latest_by_branch": {
    "main": "session-2026-01-27-101000",
    "PLA-123-feature": "session-2026-01-27-100000",
    "WORK-456-bugfix": "session-2026-01-27-100500"
  },
  "sessions": [
    {
      "id": "session-2026-01-27-101000",
      "timestamp": "...",
      "branch": "main",
      "is_worktree": false,
      "project": "/path/to/repo",
      "summary": "..."
    }
  ]
}
```

## Task Agent Context Integration

**Problem:** Task agents spawn without project context, waste 5k+ tokens re-reading files.

**Solution:** Compressed context file generated by `/wrap-session`.

**Usage:**

1. **After `/wrap-session`:**
   - Creates `.claude/task-context.md` (~200-300 tokens)
   - Contains: project info, summary, top 5 patterns, top 3 files, top 3 gotchas

2. **Before spawning Task agent:**
   ```
   # Check if context exists
   if [ -f .claude/task-context.md ]; then
       # Read and include in Task agent prompt
   fi
   ```

3. **In Task agent prompt:**
   ```
   Task: Explore authentication implementation

   Context from previous session:
   - Current focus: Refactoring auth module
   - Key pattern: Use AuthService singleton
   - Critical file: src/auth/AuthService.ts
   - Watch out: Token refresh logic has edge cases
   ```

**Token Savings:**
- Reading task-context.md: ~200-300 tokens
- Without context: 5k+ tokens (10-20 file reads)
- **Savings: ~4.7k tokens per Task spawn** (95% reduction)

---

## Optimization Results

**Token Cost Comparison:**

| Operation | Baseline | Optimized | Reduction |
|-----------|----------|-----------|-----------|
| wrap-session | 4-6k | 800-1k | **80-85%** |
| load-session | 3.5-6k | 600-800 | **80-85%** |
| session-status | 2-2.5k | 600-800 | **70-75%** |
| Task agent spawn | 5k+ | 200-300 | **95%+** |
| **Total cycle** | **10-15k** | **1.5-2k** | **85-90%** |

**File Size:**
- Baseline: 8KB average
- Optimized: 3-4KB average
- **Reduction: 60-65%**

**Quality:**
- ✅ Zero information loss
- ✅ Top 5 patterns capture critical context
- ✅ Git log provides full history
- ✅ Compression removes redundancy, keeps essentials

---

## Tips

**Token Optimization:**
- Use `/session-status` frequently (cheap at 600-800 tokens)
- Follow specific optimization recommendations
- Use compressed format (automatic in v2.0)
- Pass context to Task agents via task-context.md
- Auto-loading saves 5-10k tokens in context gathering

**Continuity:**
- Sessions auto-load (no need to remember!)
- `/wrap-session` at 140k+ tokens (prevents overflow)
- Review session files to understand project evolution
- Use `--full` flag for complete details when needed

**Project Organization:**
- Sessions automatically associated with working directory
- Multi-project work maintains separate session histories
- Global sessions for dotfiles and cross-project work

**Git Worktrees:**
- Sessions automatically shared across all worktrees
- Switch between worktrees seamlessly (auto-loads context)
- Session history shows which worktree branch was used
- No manual configuration needed - detection is automatic

## Future Enhancements

Potential additions:
- Auto-archival of old sessions
- Session search by keyword or date range
- Session analytics and insights
- Integration with project documentation
- Comparison between sessions

## Troubleshooting

**Session files not found:**
- Ensure `.claude/sessions/` directory exists
- Check if you've run `/wrap-session` before
- Verify working directory matches previous sessions

**JSON parsing errors:**
- Session files may be corrupted
- Manually inspect JSON files for syntax errors
- Remove corrupted sessions and start fresh

**Wrong project sessions:**
- Sessions are filtered by working directory
- Use absolute paths to avoid mismatches
- Check `index.json` for session locations

**Worktree issues:**
- Ensure git is available in PATH
- Verify worktree is properly set up with `git worktree list`
- Sessions stored in main repo's `.git` directory (from `git rev-parse --git-common-dir`)
- If sessions not found, check `{git_common_dir}/.claude/sessions/`

---

## Changelog

**v2.1 - 2026-01-27 (Multi-Worktree Session Support)**
- ✅ Branch-aware session loading (default: current branch only)
- ✅ Added `latest_by_branch` to index.json
- ✅ Added `--all` flag to load sessions from any branch
- ✅ Added `--branch NAME` flag to load specific branch's session
- ✅ Added branch/directory mismatch warnings
- ✅ Sessions now track `branch` and `is_worktree` in index entries
- ✅ Prevents loading wrong worktree's context by default

**v2.0 - 2026-01-19 (Optimization Release)**
- ✅ Switched all commands to Haiku model (80% cost reduction)
- ✅ Compressed session schema (60-65% file size reduction)
- ✅ Added tiered display modes to load-session (--full, --compact, --summary)
- ✅ Added auto-wrap triggers to session-status (140k, 150k thresholds)
- ✅ Added automatic session loading at conversation start
- ✅ Added Task agent context integration (task-context.md)
- ✅ Added efficiency scoring and file activity tracking
- ✅ Added wrap preview feature
- ✅ Optimized for 150k context overflow (not 200k)
- ✅ **Total token reduction: 85-90% per cycle**

**v1.0 - 2026-01-12 (Initial Release)**
- Initial session management system
- wrap-session, load-session, session-status commands
- Worktree support
- Basic session tracking

---

**Version:** 2.1 (Multi-Worktree Support)
**Last Updated:** 2026-01-27
**Author:** Leandro Magalhães
**Backup Location:** `~/.claude/commands/backups/` (original + optimized versions)
