---
name: wy-list-sessions
description: List available sessions for the current project
argument-hint: "[<count> | all]"
model: haiku
allowed-tools:
  - Bash
---

Run the script and format the JSON output as a nice table:

```bash
~/.claude/scripts/list-sessions.sh $ARGUMENTS
```

**Arguments:** No args = last 10, number = last N, `all` = all sessions

**Format the JSON output as:**

```
# 📋 Sessions

| #  | Date             | Branch                    | Summary                              |
|----|------------------|---------------------------|--------------------------------------|
| 1  | Jan 22, 3:38 PM  | PLA-369-db-importorg      | Completed critical validation...     |
| 2  | Jan 21, 2:24 PM  | PLA-369-db-importorg      | Reset wurble database...             |

**Latest:** {latest}
**Total:** {total} sessions

💡 /task-context:load to load latest session context
```

**Rules:**
- Parse timestamp (ISO 8601) to "Mon DD, H:MM AM/PM"
- Truncate branch to ~25 chars, summary to ~40 chars
- Align columns nicely
- Handle errors: "no_sessions_dir" → "No sessions found", "no_sessions" → "No sessions recorded"
