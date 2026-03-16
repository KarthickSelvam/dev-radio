#!/usr/bin/env bash
# claude-code.sh - Claude Code hooks handler
#
# This script is called by Claude Code hooks. It reads JSON from stdin
# and plays appropriate sounds based on the event.
#
# Usage (called automatically by Claude Code):
#   echo '{"hook_event_name":"PostToolUse",...}' | ./claude-code.sh
#
# Manual usage for testing:
#   echo '{"hook_event_name":"Stop"}' | ./claude-code.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/platform.sh
source "$LIB_DIR/platform.sh"

# Read JSON from stdin (Claude Code pipes event data)
INPUT=$(cat)

# Parse fields - use jq if available, otherwise basic extraction
if command -v jq &>/dev/null; then
  EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
  TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
  EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // "0"')
  NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
else
  # Fallback: simple grep-based parsing (handles common cases)
  EVENT=$(echo "$INPUT" | grep -o '"hook_event_name":"[^"]*"' | cut -d'"' -f4)
  TOOL=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | cut -d'"' -f4)
  EXIT_CODE=$(echo "$INPUT" | grep -o '"exit_code":[0-9]*' | cut -d: -f2)
  EXIT_CODE="${EXIT_CODE:-0}"
  NOTIFICATION_TYPE=$(echo "$INPUT" | grep -o '"notification_type":"[^"]*"' | cut -d'"' -f4)
fi

play() {
  "$LIB_DIR/play.sh" "$1" 2>/dev/null || true
}

case "$EVENT" in
  SessionStart)
    play misc
    ;;

  PostToolUse)
    case "$TOOL" in
      Bash)
        if [ "$EXIT_CODE" != "0" ]; then
          play fail
        fi
        # Don't play on every successful bash - too noisy
        ;;
      Edit|Write)
        play neutral
        ;;
    esac
    ;;

  PostToolUseFailure)
    play fail
    ;;

  Stop)
    play success
    ;;

  Notification)
    case "$NOTIFICATION_TYPE" in
      permission_prompt)
        play neutral
        ;;
    esac
    ;;

  SubagentStop)
    play neutral
    ;;

  *)
    # Unknown event - ignore silently
    ;;
esac

exit 0
