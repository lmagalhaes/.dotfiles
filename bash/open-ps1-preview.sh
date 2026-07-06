#!/usr/bin/env bash
# Serves ps1-preview.html via a local HTTP server so Chrome can load the Nerd Font.
# Usage: bash ~/.dotfiles/bash/open-ps1-preview.sh

PORT=7743
ROOT="$HOME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REL_PATH="${SCRIPT_DIR#"$ROOT/"}"
URL="http://localhost:${PORT}/${REL_PATH}/ps1-preview.html"

python3 -m http.server "$PORT" --directory "$ROOT" &
SERVER_PID=$!

sleep 0.4
open -a "Google Chrome" "$URL"

echo "Preview: $URL"
echo "Press Ctrl-C to stop the server."

trap "kill $SERVER_PID 2>/dev/null" EXIT INT TERM
wait $SERVER_PID
