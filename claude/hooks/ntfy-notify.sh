#!/bin/bash
# Simple ntfy push notification for Claude Code events (idle_prompt, etc.)
# No response mechanism — notification only.

CONFIG_FILE="$HOME/.config/claude-push/config"
if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi
source "$CONFIG_FILE"

INPUT=$(cat)

NOTIF_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "notification"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code needs your attention"' | head -c 300)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
PROJECT=$(basename "$CWD")

if [ "$NOTIF_TYPE" = "permission_prompt" ]; then
  TITLE="[$PROJECT] Permission Required"
elif [ "$NOTIF_TYPE" = "idle_prompt" ]; then
  TITLE="[$PROJECT] Waiting for Input"
else
  TITLE="[$PROJECT] Notification"
fi

curl -s \
  -H "Title: $TITLE" \
  -H "Priority: 3" \
  -H "Tags: bell" \
  -d "$MESSAGE" \
  "https://ntfy.sh/${CLAUDE_PUSH_TOPIC}" > /dev/null 2>&1

exit 0
