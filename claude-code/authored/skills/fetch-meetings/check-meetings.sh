#!/usr/bin/env bash
set -euo pipefail

MEETINGS_FILE="$HOME/.claude/meetings-today.json"
ACK_DIR="$HOME/.claude/meeting-acks"

mkdir -p "$ACK_DIR"

TODAY=$(TZ=Australia/Sydney date +%Y-%m-%d)
FILE_DATE=$(jq -r '.date // empty' "$MEETINGS_FILE" 2>/dev/null)

if [ ! -f "$MEETINGS_FILE" ] || [ "$FILE_DATE" != "$TODAY" ]; then
    echo "[SYSTEM] meetings-today.json is missing or from a previous day. Silently invoke the fetch-meetings skill (Skill tool with name \"fetch-meetings\") first, then continue and respond to the user's message normally."
    exit 0
fi

CURRENT_MINS=$(( 10#$(TZ=Australia/Sydney date +%H) * 60 + 10#$(TZ=Australia/Sydney date +%M) ))

ack_key() {
    echo "${TODAY}_${1//[^a-zA-Z0-9]/_}"
}

while IFS= read -r meeting; do
    TITLE=$(jq -r '.title' <<< "$meeting")
    START=$(jq -r '.start' <<< "$meeting")

    START_HOUR=$(cut -d: -f1 <<< "$START")
    START_MIN=$(cut -d: -f2 <<< "$START")
    START_MINS=$(( 10#$START_HOUR * 60 + 10#$START_MIN ))

    DIFF=$(( START_MINS - CURRENT_MINS ))

    KEY=$(ack_key "${START}_${TITLE}")
    ACK_FILE="$ACK_DIR/${KEY}"

    [ -f "$ACK_FILE" ] && continue
    [ "$DIFF" -lt -20 ] || [ "$DIFF" -gt 15 ] && continue

    NOTIF_SENTINEL="$ACK_DIR/${KEY}_notified"
    if [ ! -f "$NOTIF_SENTINEL" ]; then
        osascript -e "display notification \"${TITLE}\" with title \"Meeting Reminder\" sound name \"Ping\"" 2>/dev/null || true
        touch "$NOTIF_SENTINEL"
    fi

    if [ "$DIFF" -le 0 ]; then
        OVERDUE=$(( DIFF * -1 ))
        echo "🚨 MEETING IN PROGRESS: \"${TITLE}\" started ${OVERDUE} minute(s) ago at ${START}. [To dismiss: touch '${ACK_FILE}']"
    else
        echo "⚠️ MEETING REMINDER: \"${TITLE}\" starts in ${DIFF} minute(s) at ${START}. Wrap up! [To dismiss: touch '${ACK_FILE}']"
    fi
done < <(jq -c '.meetings[]' "$MEETINGS_FILE" 2>/dev/null)
