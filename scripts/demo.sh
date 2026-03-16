#!/usr/bin/env bash
# demo.sh - Demonstrate the dev-radio sound system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVRADIO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLAY="$DEVRADIO_DIR/lib/play.sh"

echo "dev-radio - Sound System Demo"
echo "=============================="
echo ""

echo "[success] Completion sound..."
"$PLAY" success
sleep 2

echo "[fail] Error sound..."
"$PLAY" fail
sleep 2

echo "[neutral] Status sound..."
"$PLAY" neutral
sleep 2

echo "[misc] Fun sound..."
"$PLAY" misc
sleep 2

echo ""
echo "Demo complete!"
echo ""
echo "Event log: $DEVRADIO_DIR/events.log"
echo "Add sounds: drop files into $DEVRADIO_DIR/sounds/<category>/"
