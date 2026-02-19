---
description: Load and display context from previous session(s) for continuity
model: haiku
allowed-tools:
  - Bash
  - Read
---

# Load Session Command (Hybrid)

Load session data using the bash script and format output for the user.

## Usage

- `/load-session` - Load latest session **for current branch**
- `/load-session 3` - Load last 3 sessions for current branch
- `/load-session --all` - Load latest session from any branch
- `/load-session --all 3` - Load last 3 sessions from any branch
- `/load-session --branch main` - Load latest session for specific branch
- `/load-session session-2026-01-12-143000` - Load specific session by ID
- `/load-session --full` - Force full details view
- `/load-session --compact` - Force compact view
- `/load-session --summary` - Ultra-compact view

## Instructions

1. **Run the script** with user's arguments:
   ```bash
   ~/.claude/scripts/load-session.sh $ARGUMENTS
   ```

2. **Handle errors** - If JSON contains `error` field:
   - `no_sessions_dir`: "No sessions found. Use `/wrap-session` to create one."
   - `no_index`: "No sessions recorded yet. Use `/wrap-session` after your session."
   - `session_not_found`: Show message and list available sessions
   - `no_sessions`: "No session files found."
   - `no_branch_session`: "No session found for branch: {branch}. Available branches: {list}"
   - `no_branch_sessions`: "No sessions found for branch: {branch}. Available branches: {list}"

3. **Handle branch/directory mismatch** - If `branch_mismatch` or `dir_mismatch` is true:

   Display a warning box BEFORE the session content:
   ```markdown
   > ⚠️ **Context Mismatch**
   >
   > You are in: `{current_branch}` ({current_dir})
   > Session is from: `{session_branch}` ({session_dir})
   >
   > The loaded context may not apply to your current work.
   > Options:
   > - `cd {session_dir}` to switch to session's worktree
   > - `/load-session --branch {current_branch}` to load current branch's session
   > - Continue with caution (patterns/files may differ)
   ```

4. **Determine display mode** from JSON output:
   - If `mode` is set (--full/--compact/--summary), use it
   - If `count > 1`, use compact
   - If single session: `file_size > 10000` OR `completed_count + remaining_count >= 25` → compact, else full

5. **Format output** based on mode:

   **FULL MODE:**
   ```markdown
   # 🔄 Session Restored

   **Session:** {session_id}
   **Date:** {formatted timestamp}
   **Branch:** {git_branch} | Worktree: {is_worktree}
   **Directory:** {working_directory}
   **Tokens:** {tokens_used}k ({percent}%) | Messages: {messages}

   ## Summary
   {summary}

   ## Last Completed
   - ✅ {each completed task}

   ## Still Remaining
   - ⏳ {each remaining task}

   ## Key Context
   **Patterns Learned:**
   - {patterns_learned}

   **Important Files:**
   - {key_files}

   **Key Decisions:**
   - {decision}: {rationale}

   ## 🎯 Next Steps
   **Start Here:** {next_session.start_here}

   **Watch Out For:**
   - {watch_out items}

   **Load Contexts:** {preload_contexts}

   **Optimization Tips:**
   - {optimize items}
   ```

   **COMPACT MODE:**
   ```markdown
   # 🔄 Session Restored

   **Session:** {session_id}
   **Date:** {date} | **Branch:** {branch} | Worktree: {is_worktree}
   **Tokens:** {tokens}k | Messages: {messages}

   ## Summary
   {summary}

   ## Quick Stats
   ✅ {completed_count} completed | ⏳ {remaining_count} remaining | 📚 {patterns count} patterns

   ## 🎯 Next Steps
   **Start Here:** {start_here}

   **Watch Out:**
   - {first 3 watch_outs}

   **Contexts:** {preload_contexts}

   ---
   💡 Use `/load-session --full` for complete details
   ```

   **SUMMARY MODE:**
   ```markdown
   # 🔄 Session: {session_id}

   **Branch:** {branch}
   {summary}

   **Next:** {start_here}
   **Contexts:** {preload_contexts}
   **Watch:** {first gotcha}

   💡 `/load-session --full` for details
   ```

   **MULTI-SESSION (count > 1):**
   ```markdown
   # 🔄 Sessions Loaded (Last {count})

   ## {session_id}
   **Date:** {date} | **Branch:** {branch} | **Tokens:** {tokens}k
   {summary}
   ✅ {completed_count} tasks | Key: {first pattern}

   [repeat for each session]

   ## 🎯 Combined Context
   **Start:** {latest start_here}
   **Contexts:** {unique contexts}
   **Key Patterns:** {top patterns across sessions}
   ```

6. **CD to session directory** - If no mismatch, offer to cd:
   - If `working_directory` differs from current pwd, note: "Session directory: {path}"
   - Claude should internally track this as the working context

7. **Load into memory** - Regardless of display mode, internally note all:
   - Current branch context (which branch this session is for)
   - Patterns learned
   - Key files
   - Decisions made
   - Watch-outs

8. **Auto-load contexts** - If `preload_contexts` lists files, read them from `~/.claude/contexts/` and confirm: "✓ Loaded contexts: {list}"

## Branch-Aware Behavior

By default, `/load-session` filters to the **current git branch**:
- In `main` → loads latest session from `main`
- In `PLA-123-feature` worktree → loads latest session from that branch
- Use `--all` to see sessions from all branches
- Use `--branch NAME` to load a specific branch's session

This prevents accidentally loading context from a different worktree.

## Notes

- Skip empty sections (no blockers = no blockers section)
- Use relative paths in display
- Format timestamps in local timezone
- Token percentage is out of 200k limit
- Always show branch info prominently to avoid confusion
