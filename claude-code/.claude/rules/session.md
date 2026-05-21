# Session Management

## Commands
- /session-status — check token usage, health, get recommendations
- /wrap-session — save session context to branch-keyed file
- /wrap-session --preview — show what would be saved without writing
- /load-session — show 3-line hint; --full for complete content

## Auto-Load Hint (start of every conversation)

If .claude/sessions/<branch>/ exists, display:
```
Session: <branch> (saved Nd ago · M commits) — N decisions, P assumptions open
Resume: <start_here value>
Run /load-session --full for decisions and watch-outs
```

This is a resume pointer only — not a substitute for fresh task discovery.
Do NOT load full session content automatically; user runs /load-session --full if needed.

## Wrap Triggers
- 150k tokens: strongly suggest /wrap-session --preview then /wrap-session
- Context overflow occurs at ~150k, not the 200k nominal limit

## Session vs Auto-Memory

| | Session file | Auto-memory |
|---|---|---|
| Scope | Branch-local handoff | Project-wide, durable |
| Lifetime | Current ticket/branch | Across branches and sessions |
| Examples | Decisions, dead-ends, watch-outs | Repeated constraints, architecture patterns |

## Storage
- Branch-keyed: .claude/sessions/<branch>/session-YYYY-MM-DD-HHMMSS.json
- Git repos: stored at repo root .claude/sessions/
- Dotfiles: ~/.claude/sessions/<branch>/
