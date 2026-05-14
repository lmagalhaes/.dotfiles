---
description: Load and display context from previous session(s) for continuity
model: haiku
allowed-tools:
  - Bash
  - Read
---

# Load Session Command

Load session data using the bash script and format output for the user.

## Usage

- `/load-session` - Show 3-line hint for current branch (default)
- `/load-session --full` - Full session details
- `/load-session 3` - Hint for last 3 sessions for current branch
- `/load-session --all` - Latest session from any branch (hint)
- `/load-session --all 3` - Last 3 sessions from any branch
- `/load-session --branch main` - Latest session for specific branch
- `/load-session session-2026-01-12-143000` - Load specific session by ID
- `/load-session --compact` - Compact view
- `/load-session --summary` - Ultra-compact view

## Instructions

### 1. Run the script

```bash
~/.claude/scripts/load-session.sh $ARGUMENTS
```

### 2. Handle errors

If JSON contains `error` field:
- `no_sessions_dir`: "No sessions found. Use `/wrap-session` to create one."
- `no_index`: "No sessions recorded yet. Use `/wrap-session` after your session."
- `session_not_found`: Show message and list available sessions
- `no_sessions`: "No session files found."
- `no_branch_session`: "No session found for branch: {branch}. Available branches: {list}"
- `no_branch_sessions`: "No sessions found for branch: {branch}. Available branches: {list}"

### 3. Validate before displaying anything

Run these checks in order, stopping at the first issue (unless `--full` was explicitly passed):

**a. Suppressed session** — if `sessions[0].meta.is_suppressed` is true AND mode is not `"full"`:
```
> Session from {age_days}d ago has been auto-suppressed (>30 days old).
> Use `/load-session --full` to view it anyway, or `/wrap-session` to save a fresh one.
```
Stop here.

**b. Branch/directory mismatch** — if `branch_mismatch` or `dir_mismatch` is true, display before session content:
```markdown
> ⚠️ **Context Mismatch**
>
> You are in: `{current_branch}` ({current_dir})
> Session is from: `{session_branch}` ({session_dir})
>
> The loaded context may not apply to your current work.
> Options:
> - `/load-session --branch {current_branch}` to load current branch's session
> - Continue with caution (context may differ)
```

### 4. Determine display mode

- `mode: "full"` → FULL
- `mode: "compact"` → COMPACT
- `mode: "summary"` → SUMMARY
- `count > 1` → MULTI-SESSION (compact)
- `mode: null` → **HINT** (default)

### 5. Format output

---

**HINT MODE (default — no flags):**

```markdown
{staleness_line if is_stale}
**Session:** {branch} · {age_days}d ago{commit_delta_suffix}
**Resume:** {start_here}{phantom_suffix}
{open_questions count} open questions · {decisions count} decisions · {watch_out count} watch-outs

`/load-session --full` for complete context
```

- `commit_delta_suffix` = ` · {N} commits since save` if `commit_delta >= 0`, else omit
- `staleness_line` = `⚠ Session may be stale ({age_days}d{delta_part}) — consider /prime-context to refresh`
- `phantom_suffix` = ` ⚠ (path not found — may need /prime-context)` if `!start_here_exists`

---

**FULL MODE:**

```markdown
# 🔄 Session Restored

{staleness banner if is_stale:}
> ⚠ Session may be stale ({age_days}d, {commit_delta} commits) — consider /prime-context to refresh

{phantom banner if !start_here_exists:}
> ⚠ Resume point not found: {start_here}
> File may have moved. Run /prime-context for fresh context.

**Session:** {session_id}
**Date:** {timestamp} ({age_days}d ago{commit_delta_part})
**Branch:** {git_branch} | Worktree: {is_worktree}

## Key Decisions
- **{decision}:** {rationale}

## Dead Ends
- **{what}:** {why_abandoned}

## Watch Out
- {watch_out items}

## Assumptions
- [ ] {assumption} (confirmed: {confirmed})

## Open Questions
- {question} (→ {asked_to})

## 🎯 Next Steps
**Resume:** {start_here}{phantom_marker}

---
**Tip:** After load-session, run `/prime-context` to refresh task understanding.
```

Where `commit_delta_part` = ` · {N} commits since save` if `commit_delta >= 0`.

For sessions with **old schema** (has `summary`, `completed`, `remaining`, `patterns_learned`): show those fields instead under a "## Legacy Context" header.

---

**COMPACT MODE:**

```markdown
# 🔄 Session Restored

**Session:** {session_id}
**Date:** {date} | **Branch:** {branch} | {age_days}d ago
{staleness warning if is_stale}

## Summary / Key Context
{summary if present, else list decisions + watch_outs}

## 🎯 Next Steps
**Resume:** {start_here}{phantom_marker}

---
💡 Use `/load-session --full` for complete details
```

---

**SUMMARY MODE:**

```markdown
# 🔄 Session: {session_id}

**Branch:** {branch} · {age_days}d ago
**Resume:** {start_here}
{first watch_out or first decision}

💡 `/load-session --full` for details
```

---

**MULTI-SESSION (count > 1):**

```markdown
# 🔄 Sessions Loaded (Last {count})

## {session_id}
**Date:** {date} | **Branch:** {branch} | {age_days}d ago{stale_marker}
**Resume:** {start_here}
{decisions count} decisions · {watch_out count} watch-outs

[repeat for each session]

## 🎯 Latest Resume Point
{latest start_here}
```

Where `stale_marker` = ` ⚠ stale` if `meta.is_stale`.

---

### 6. Load into memory

Regardless of display mode, internally note:
- Current branch context
- Decisions made
- Watch-outs
- Open questions / assumptions
- Resume point (start_here)

### 7. Auto-load contexts

If session has `preload_contexts` (old schema), read those files from `~/.claude/contexts/` and confirm: "✓ Loaded contexts: {list}"

## Branch-Aware Behavior

By default, `/load-session` filters to the **current git branch**:
- In `main` → loads latest session from `main`
- In `PLA-123-feature` worktree → loads latest session from that branch
- Use `--all` to see sessions from all branches
- Use `--branch NAME` to load a specific branch's session

## Notes

- Skip empty sections (no decisions = no decisions section)
- Use relative paths in display
- Token percentage is out of 200k limit
- Always show branch info prominently to avoid confusion
- The default hint is intentionally minimal — full context loads on demand
