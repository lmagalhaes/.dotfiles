#!/usr/bin/env bash

RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD_RED='\033[1;31m'
BOLD_CYAN='\033[1;36m'

ACK_DIR="$HOME/.claude/meeting-acks"
MEETINGS_FILE="$HOME/.claude/meetings-today.json"
TODAY=$(TZ=Australia/Sydney date +%Y-%m-%d)
FILE_DATE=$(jq -r '.date // empty' "$MEETINGS_FILE" 2>/dev/null)

[ "$FILE_DATE" != "$TODAY" ] && exit 0

meeting_ack_key() {
    local combined="${1}_${2}"
    local sanitized="${combined//[^a-zA-Z0-9]/_}"
    echo "${TODAY}_${sanitized}"
}

is_meeting_acked() {
    local key
    key=$(meeting_ack_key "$1" "$2")
    [ -f "${ACK_DIR}/${key}" ]
}

CURRENT_MINS=$(( 10#$(TZ=Australia/Sydney date +%H) * 60 + 10#$(TZ=Australia/Sydney date +%M) ))
IN_PROGRESS_TITLE=""
IN_PROGRESS_START=""
IN_PROGRESS_END=""
NEXT_TITLE=""
NEXT_START=""
NEXT_DIFF=99999

while IFS= read -r meeting; do
    TITLE=$(echo "$meeting" | jq -r '.title')
    START=$(echo "$meeting" | jq -r '.start')
    END=$(echo "$meeting" | jq -r '.end // empty')
    START_HOUR=$(echo "$START" | cut -d: -f1)
    START_MIN=$(echo "$START" | cut -d: -f2)
    START_MINS=$(( 10#$START_HOUR * 60 + 10#$START_MIN ))
    DIFF=$(( START_MINS - CURRENT_MINS ))

    if [ "$DIFF" -le 0 ] && [ -n "$END" ]; then
        END_HOUR=$(echo "$END" | cut -d: -f1)
        END_MIN=$(echo "$END" | cut -d: -f2)
        END_MINS=$(( 10#$END_HOUR * 60 + 10#$END_MIN ))
        if [ "$END_MINS" -gt "$CURRENT_MINS" ]; then
            IN_PROGRESS_TITLE="$TITLE"
            IN_PROGRESS_START="$START"
            IN_PROGRESS_END="$END"
        fi
    elif [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt "$NEXT_DIFF" ]; then
        NEXT_DIFF=$DIFF
        NEXT_TITLE="$TITLE"
        NEXT_START="$START"
    fi
done < <(jq -c '.meetings[]' "$MEETINGS_FILE" 2>/dev/null)

if [ -n "$IN_PROGRESS_TITLE" ]; then
    if is_meeting_acked "$IN_PROGRESS_START" "$IN_PROGRESS_TITLE"; then
        printf "%b" "${BOLD_CYAN}▶ Now: \"${IN_PROGRESS_TITLE}\" until ${IN_PROGRESS_END}${RESET}"
    else
        printf "%b" "${BOLD_RED}🚨🚨🚨 NOW: \"${IN_PROGRESS_TITLE}\" until ${IN_PROGRESS_END} 🚨🚨🚨${RESET}"
    fi
elif [ -n "$NEXT_TITLE" ]; then
    if [ "$NEXT_DIFF" -le 5 ] && ! is_meeting_acked "$NEXT_START" "$NEXT_TITLE"; then
        printf "%b" "${YELLOW}⏰⏰⏰ IN ${NEXT_DIFF}m: \"${NEXT_TITLE}\" at ${NEXT_START} — don't miss it! ⏰⏰⏰${RESET}"
    elif [ "$NEXT_DIFF" -le 5 ]; then
        [ "$NEXT_DIFF" -eq 0 ] && countdown="now" || countdown="in ${NEXT_DIFF}m"
        printf "%b" "${BOLD_RED}🚨 Next: \"${NEXT_TITLE}\" ${countdown} at ${NEXT_START}${RESET}"
    elif [ "$NEXT_DIFF" -le 15 ]; then
        printf "%b" "${YELLOW}⏰ Next: \"${NEXT_TITLE}\" in ${NEXT_DIFF}m at ${NEXT_START}${RESET}"
    else
        printf "%b" "${GREEN}📅 Next: \"${NEXT_TITLE}\" in ${NEXT_DIFF}m at ${NEXT_START}${RESET}"
    fi
fi
