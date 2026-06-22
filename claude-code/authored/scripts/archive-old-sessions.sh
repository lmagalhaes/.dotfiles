#!/bin/bash
# Archive sessions older than N days to reduce index bloat
# Usage: archive-old-sessions.sh [days] [project_path]

DAYS=${1:-14}  # Default: 14 days
PROJECT_PATH=${2:-.}

SESSIONS_DIR="$PROJECT_PATH/.claude/sessions"
ARCHIVE_DIR="$SESSIONS_DIR/archive"

if [ ! -d "$SESSIONS_DIR" ]; then
    echo "❌ No sessions directory found at: $SESSIONS_DIR"
    exit 1
fi

mkdir -p "$ARCHIVE_DIR"

# Find and move old session files
CUTOFF_DATE=$(date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || date -d "${DAYS} days ago" +%Y-%m-%d)
echo "📦 Archiving sessions older than $CUTOFF_DATE..."

ARCHIVED_COUNT=0
for session_file in "$SESSIONS_DIR"/session-*.json; do
    [ -e "$session_file" ] || continue

    # Extract date from filename (session-2026-02-12-114015.json)
    filename=$(basename "$session_file")
    session_date=$(echo "$filename" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)

    if [ "$session_date" \< "$CUTOFF_DATE" ]; then
        mv "$session_file" "$ARCHIVE_DIR/"
        echo "  → Archived: $filename"
        ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))
    fi
done

if [ $ARCHIVED_COUNT -eq 0 ]; then
    echo "✅ No sessions to archive (all within last $DAYS days)"
else
    echo "✅ Archived $ARCHIVED_COUNT sessions to: $ARCHIVE_DIR"
    echo ""
    echo "💡 Update .claude/sessions/index.json to remove archived entries if needed"
fi
