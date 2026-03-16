#!/usr/bin/env bash
# events.sh - Event system: log + play + notify
# Usage: ./events.sh <category> [message]
#
# Categories: success, fail, neutral, misc
# Example:  ./events.sh success "Tests passed!"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=platform.sh
source "$SCRIPT_DIR/platform.sh"

CATEGORY="${1:-neutral}"
MESSAGE="${2:-}"
LOG_FILE="$DEVRADIO_DIR/events.log"

# Log the event
echo "$(date '+%Y-%m-%d %H:%M:%S') [$CATEGORY] $MESSAGE" >> "$LOG_FILE"

# Play the sound
"$SCRIPT_DIR/play.sh" "$CATEGORY"

# Optional desktop notification
if [ -n "$MESSAGE" ]; then
  devradio_notify "dev-radio [$CATEGORY]" "$MESSAGE"
fi
