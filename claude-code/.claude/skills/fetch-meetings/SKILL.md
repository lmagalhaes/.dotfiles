---
name: fetch-meetings
description: Fetch today's Google Calendar events and save to ~/.claude/meetings-today.json for the meeting reminder hook
allowed-tools:
  - Bash
  - Read
  - Write
  - mcp__claude_ai_Google_Calendar__list_events
  - mcp__claude_ai_Google_Calendar__list_calendars
---

Fetch today's calendar events and save them so the meeting reminder hook can warn you throughout the session.

## Steps

### 1. Get today's date range

Get today's date in Sydney timezone (Australia/Sydney). You need:
- `timeMin`: start of today in ISO 8601 format with timezone offset, e.g. `2026-06-16T00:00:00+10:00`
- `timeMax`: end of today in ISO 8601 format, e.g. `2026-06-16T23:59:59+10:00`

Use `TZ=Australia/Sydney date` commands to get the correct values.

### 2. Fetch events from Google Calendar

Call `mcp__claude_ai_Google_Calendar__list_events` with:
- `startTime`: start of today (Sydney time, ISO 8601)
- `endTime`: end of today (Sydney time, ISO 8601)
- `orderBy`: startTime
- `timeZone`: Australia/Sydney

If the calendar list is needed to find the right calendar ID, call `mcp__claude_ai_Google_Calendar__list_calendars` first and use the primary calendar.

### 3. Build the meetings file

For each event returned:
- Extract the title (`summary`)
- Extract the start time and convert to Sydney local time in `HH:MM` 24-hour format
- Extract the end time and convert to Sydney local time in `HH:MM` 24-hour format
- Skip all-day events (events with `date` instead of `dateTime` in start)
- Skip events that have already ended (end time is before current time) — include in-progress events

Build a JSON object in this exact shape:
```json
{
  "date": "YYYY-MM-DD",
  "meetings": [
    { "title": "Meeting Title", "start": "HH:MM", "end": "HH:MM" },
    { "title": "Another Meeting", "start": "HH:MM", "end": "HH:MM" }
  ]
}
```

### 4. Save to file

Write the JSON to `~/.claude/meetings-today.json`.

### 5. Confirm to user

Print a short summary:
```
Saved N meeting(s) for today:
  09:00 — Daily Standup
  14:00 — 1:1 with Alice
```

If no meetings, say "No meetings found for today."
