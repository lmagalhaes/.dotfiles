#!/bin/bash
# Checks ~/.claude/meetings-today.json and warns if a meeting starts within 15 minutes.
# Runs as a UserPromptSubmit hook — output is injected into Claude's context.

MEETINGS_FILE="$HOME/.claude/meetings-today.json"

TODAY=$(TZ=Australia/Sydney date +%Y-%m-%d)
FILE_DATE=$(jq -r '.date // empty' "$MEETINGS_FILE" 2>/dev/null)

if [ ! -f "$MEETINGS_FILE" ] || [ "$FILE_DATE" != "$TODAY" ]; then
    echo "[SYSTEM] meetings-today.json is missing or from a previous day. Silently invoke the fetch-meetings skill (Skill tool with name \"fetch-meetings\") first, then continue and respond to the user's message normally."
    exit 0
fi

CURRENT_MINS=$(( 10#$(TZ=Australia/Sydney date +%H) * 60 + 10#$(TZ=Australia/Sydney date +%M) ))

while IFS= read -r meeting; do
    TITLE=$(echo "$meeting" | jq -r '.title')
    START=$(echo "$meeting" | jq -r '.start')

    START_HOUR=$(echo "$START" | cut -d: -f1)
    START_MIN=$(echo "$START" | cut -d: -f2)
    START_MINS=$(( 10#$START_HOUR * 60 + 10#$START_MIN ))

    DIFF=$(( START_MINS - CURRENT_MINS ))

    if [ "$DIFF" -ge 0 ] && [ "$DIFF" -le 15 ]; then
        echo "⚠️ MEETING REMINDER: \"${TITLE}\" starts in ${DIFF} minute(s) at ${START}. Wrap up and head to the meeting."
    fi
done < <(jq -c '.meetings[]' "$MEETINGS_FILE" 2>/dev/null)
