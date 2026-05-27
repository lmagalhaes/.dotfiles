---
name: wrap-session
description: Create a session retrospective with key context and recommendations for continuity
argument-hint: "[--preview]"
model: haiku
allowed-tools:
  - Bash
  - Write
---

# Wrap Session Command

Create a session summary capturing only non-derivable context, then save via bash script.

## Usage

- `/wrap-session` - Save session to disk
- `/wrap-session --preview` - Show what would be saved without writing to disk

## Instructions

### 1. Parse Arguments

Check if `$ARGUMENTS` contains `--preview`. Set preview mode accordingly.

### 2. Get Environment

Run the script to get environment data:
```bash
~/.claude/scripts/wrap-session.sh env
```

Also get the current commit hash:
```bash
git rev-parse HEAD 2>/dev/null || echo ""
```

Environment fields:
- `session_id` - Generated ID (session-YYYY-MM-DD-HHMMSS)
- `timestamp` - ISO timestamp (use as `session_date`)
- `working_directory` - Canonical path (pwd -P)
- `git_branch` - Current branch
- `is_worktree` - Boolean
- `sessions_dir` - Where to save

### 3. Analyze Conversation

Extract **only what cannot be regenerated** from git, Linear, or re-reading the code:

**Decisions** (max 5):
- Architecture choices or approach selections made during this session
- Only include if the reasoning requires this conversation to understand — skip if self-evident from code
- Format: `decision` (what, max 20 words) + `rationale` (why, max 40 words)

**Dead Ends** (max 5):
- Approaches tried and abandoned this session; prevents future sessions repeating them
- Format: `what` (what was tried, max 30 words) + `why_abandoned` (why it failed, max 40 words)

**Watch Out** (max 5, max 50 words each):
- Active gotchas, subtle invariants, or landmines discovered; must be non-obvious from the code

**Assumptions** (max 5):
- **Primary:** If the conversation includes a prime-context synthesis with an "Assumptions Made" section, extract each assumption verbatim
- **Secondary:** Note implicit assumptions made during the session that weren't verified
- Format: `assumption` (text, max 50 words) + `confirmed: false` (unless user explicitly confirmed)

**Open Questions** (max 5):
- **Primary:** If the conversation includes a prime-context synthesis with a "Questions for Clarification" section, extract them verbatim
- **Secondary:** Note unresolved questions raised during the session
- Format: `question` (text, max 50 words) + `asked_to: "user"` (or relevant party)

**⚠ Warning:** After extracting, if BOTH `assumptions` AND `open_questions` are empty, display before saving:
> ⚠ Both arrays empty. If you ran /prime-context this session, extract assumptions and questions before saving.

**Next Session** (`start_here`):
- Most specific resume point possible: `file:line`, exact command, or concrete task
- Not a general area — specificity matters

### 4. Build Session JSON

The JSON must include both the environment fields (required by the save script) and the slim content fields:

```json
{
  "session_id": "{from env}",
  "timestamp": "{from env}",
  "working_directory": "{from env}",
  "git_branch": "{from env}",
  "is_worktree": "{from env}",
  "branch": "{git_branch}",
  "commit_hash": "{git rev-parse HEAD output}",
  "session_date": "{timestamp from env}",
  "decisions": [
    {"decision": "...", "rationale": "..."}
  ],
  "dead_ends": [
    {"what": "...", "why_abandoned": "..."}
  ],
  "watch_out": ["..."],
  "assumptions": [
    {"assumption": "...", "confirmed": false}
  ],
  "open_questions": [
    {"question": "...", "asked_to": "..."}
  ],
  "next_session": {
    "start_here": "..."
  }
}
```

**Compression rules:** Max 5 items per array; max 50 words per item text; max 40 words per rationale/why_abandoned. Quality over quantity.

### 5. Save or Preview

**If `--preview`:** Display the populated schema and stop. Do not call the save script.

```markdown
# 📦 Session Preview (not saved)

**Branch:** {branch} @ {commit_hash[:7]}

{populated session JSON, formatted}

Run `/wrap-session` (without `--preview`) to save.
```

**If saving:** Pipe the session JSON to the save script:
```bash
echo '{...session JSON...}' | ~/.claude/scripts/wrap-session.sh save
```

### 6. Update Per-Worktree Docs Index (If In Worktree)

If `is_worktree` is true:
```bash
~/.claude/scripts/refresh-worktree-index.sh
```
Skip silently if it fails.

### 7. Display Summary

```markdown
# 📦 Session Wrapped

**Branch:** {branch} @ {commit_hash[:7]}
**Saved:** {session_id}

## Captured
- Decisions: {count}
- Dead ends: {count}
- Watch outs: {count}
- Assumptions: {count}
- Open questions: {count}

## 🎯 Next Session
Start with: {start_here}

## 💾 Saved to
`{session_file}`
```

## Notes

- Decisions and dead ends have the highest value — prioritize extracting these accurately
- Skip sections with 0 items rather than noting "none"
- Exploratory sessions with no code changes are still valid to wrap
