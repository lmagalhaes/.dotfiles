---
description: Create a session retrospective with key context and recommendations for continuity
model: haiku
allowed-tools:
  - Bash
  - Write
---

# Wrap Session Command (Hybrid)

Create a session summary by analyzing conversation and saving via bash script.

## Instructions

### 1. Get Environment

Run the script to get environment data:
```bash
~/.claude/scripts/wrap-session.sh env
```

This returns JSON with:
- `session_id` - Generated ID (session-YYYY-MM-DD-HHMMSS)
- `timestamp` - ISO timestamp
- `working_directory` - Canonical path (pwd -P)
- `git_branch` - Current branch
- `is_worktree` - Boolean
- `sessions_dir` - Where to save

### 2. Analyze Conversation

Review the conversation to extract:

**Completed Tasks** (max 5, most recent):
- Look for todo completions, git commits, successful operations
- Focus on what was actually finished

**Remaining Tasks** (max 5, priority order):
- Pending todos, mentioned next steps
- What still needs to be done

**Patterns Learned** (max 5, max 50 words each):
- Codebase conventions discovered
- Technical insights gained
- Use imperatives: "Use X for Y", "Avoid Z when..."

**Key Files** (max 5):
- Files frequently accessed or modified
- Use relative paths

**Decisions Made** (significant ones only):
- `decision`: What was decided (max 20 words)
- `rationale`: Why (max 40 words)

**Blockers** (active only, skip resolved):
- Issues still affecting work
- Status: blocked or workaround

**Metrics**:
- Extract token usage from system warnings if available
- Count approximate message exchanges

**Next Session**:
- `start_here`: Specific file:line or task
- `preload_contexts`: Context files to load
- `watch_out`: Top 5 gotchas
- `optimize`: Top 3 optimization tips

### 3. Build Session JSON

Combine environment data with analyzed content:

```json
{
  "session_id": "{from env}",
  "timestamp": "{from env}",
  "working_directory": "{from env}",
  "git_branch": "{from env}",
  "is_worktree": {from env},

  "summary": "2-3 sentence overview",

  "completed": ["task1", "task2"],
  "remaining": ["task3", "task4"],

  "context": {
    "languages": ["python", "bash"],
    "contexts_loaded": ["python.md"],
    "patterns_learned": ["pattern1", "pattern2"],
    "key_files": ["path/file.py: note"]
  },

  "decisions": [
    {"decision": "...", "rationale": "..."}
  ],

  "blockers": [],

  "metrics": {
    "tokens_used": 42000,
    "messages_exchanged": 25
  },

  "next_session": {
    "start_here": "specific starting point",
    "preload_contexts": [],
    "watch_out": ["gotcha1"],
    "optimize": ["tip1"]
  }
}
```

### 4. Save Session

Pipe the JSON to the save script:
```bash
echo '{...session JSON...}' | ~/.claude/scripts/wrap-session.sh save
```

The script will:
- Create sessions directory if needed
- Write session file
- Update index.json
- Return success confirmation

### 5. Create Task Context (Optional)

Write a compressed context file for Task agents:

```bash
# Write to .claude/task-context.md
```

Content:
```markdown
# Task Agent Context

**Project:** {project name}
**Branch:** {git_branch}
**Session:** {timestamp}

## Current Work
{summary}

## Key Patterns
{top 3 patterns}

## Critical Files
{top 3 files}

## Watch Out
{top 3 gotchas}
```

### 6. Display Summary

Show the user:
```markdown
# 📦 Session Wrapped

**Session ID:** {session_id}
**Tokens Used:** {tokens}k ({percent}%)
**Branch:** {branch} | Worktree: {yes/no}

## ✅ Completed
- {completed tasks}

## 📋 Remaining
- {remaining tasks}

## 🎯 Next Session
Start with: {start_here}
Load contexts: {contexts}

## 💾 Saved
- `{session_file}`
- Index updated
```

## Compression Rules

- **Max 5 items** per array (completed, remaining, patterns, files, watch_out)
- **Max 50 words** per pattern
- **Max 20 words** per decision, 40 for rationale
- **Relative paths** - relative to working_directory
- **Active blockers only** - skip resolved ones
- **Quality over quantity** - 5 excellent patterns > 20 mediocre ones

## Notes

- Focus on actionable context, not documentation
- Skip empty sections
- If no tasks completed, session is still valid (exploratory)
- Token percentage is out of 200k limit
