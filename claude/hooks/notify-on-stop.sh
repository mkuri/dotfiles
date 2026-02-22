#!/bin/bash
# Notify when Claude finishes responding.
# Uses terminal-notifier for macOS notifications with tmux pane focus on click.

INPUT=$(cat)

# Extract last assistant message and truncate to 100 chars
MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' | head -c 100)
if [ -z "$MESSAGE" ]; then
  MESSAGE="Done"
fi

# Build terminal-notifier command
ARGS=(
  -title "Claude Code"
  -message "$MESSAGE"
  -sound default
)

# If running inside tmux, add click action to focus the pane
if [ -n "$TMUX_PANE" ]; then
  TMUX_CMD=$(which tmux)
  ARGS+=(-execute "$TMUX_CMD select-pane -t '$TMUX_PANE'")
fi

terminal-notifier "${ARGS[@]}" &>/dev/null &
exit 0
