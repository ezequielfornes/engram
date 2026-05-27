#!/bin/bash
# Engram — Stop hook for Claude Code (async)
#
# 1. Exports new memories to git-synced chunks (if sync dir exists)
# 2. Marks the session as ended via the HTTP API.
# Runs async so it doesn't block Claude's response.

ENGRAM_PORT="${ENGRAM_PORT:-7437}"
ENGRAM_URL="http://127.0.0.1:${ENGRAM_PORT}"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Auto-export memories to git-synced chunks
# Check both .engram/ (default) and .atl/engram/ (team convention)
SYNC_DIR=""
if [ -f "${CWD}/.engram/manifest.json" ]; then
  SYNC_DIR="${CWD}/.engram"
elif [ -f "${CWD}/.atl/engram/manifest.json" ]; then
  SYNC_DIR="${CWD}/.atl/engram"
fi
if [ -n "$SYNC_DIR" ]; then
  engram sync --dir "$SYNC_DIR" >/dev/null 2>&1 &
fi

curl -sf "${ENGRAM_URL}/sessions/${SESSION_ID}/end" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{}' \
  > /dev/null 2>&1

exit 0
