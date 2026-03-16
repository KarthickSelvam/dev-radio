#!/usr/bin/env bash
# add-radio-effect.sh - Apply radio/walkie-talkie filter to sound files
#
# Creates "-radio" versions of all voice clips using sox.
# Effect: bandpass filter + compression + reverb = military radio style.
#
# Requires: sox (brew install sox / apt install sox)
#
# Usage:
#   ./add-radio-effect.sh              # Process all sounds
#   ./add-radio-effect.sh success      # Process one category
#   ./add-radio-effect.sh file.aiff    # Process one file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVRADIO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v sox &>/dev/null; then
  echo "Error: sox is required for radio effects." >&2
  echo "  macOS: brew install sox" >&2
  echo "  Linux: apt install sox" >&2
  exit 1
fi

apply_radio() {
  local input="$1"
  local dir
  dir=$(dirname "$input")
  local base
  base=$(basename "$input")
  local name="${base%.*}"
  local ext="${base##*.}"

  # Skip files that are already radio-processed
  if [[ "$name" == *-radio ]]; then
    return 0
  fi

  local output="$dir/${name}-radio.$ext"

  if [ -f "$output" ]; then
    return 0  # already exists
  fi

  echo "  $base -> ${name}-radio.$ext"

  sox "$input" "$output" \
    bandpass 1500 1200 \
    compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 \
    reverb 20 50 50 50 0 0 \
    gain -n -3 \
    2>/dev/null
}

SOUNDS_DIR="$DEVRADIO_DIR/sounds"

if [ $# -gt 0 ]; then
  TARGET="$1"

  # Single file
  if [ -f "$TARGET" ]; then
    apply_radio "$TARGET"
    exit 0
  fi

  # Category name
  if [ -d "$SOUNDS_DIR/$TARGET" ]; then
    echo "Processing $TARGET/..."
    find "$SOUNDS_DIR/$TARGET" -maxdepth 1 -type f \( -name "*.aiff" -o -name "*.wav" -o -name "*.mp3" \) ! -name "*-radio.*" | while read -r f; do
      apply_radio "$f"
    done
    exit 0
  fi

  echo "Error: '$TARGET' is not a file or category" >&2
  exit 1
fi

# Process all categories
for category in success fail neutral misc; do
  if [ -d "$SOUNDS_DIR/$category" ]; then
    echo "Processing $category/..."
    find "$SOUNDS_DIR/$category" -maxdepth 1 -type f \( -name "*.aiff" -o -name "*.wav" -o -name "*.mp3" \) ! -name "*-radio.*" | while read -r f; do
      apply_radio "$f"
    done
    echo ""
  fi
done

RADIO_COUNT=$(find "$SOUNDS_DIR" -type f -name "*-radio.*" | wc -l | tr -d ' ')
echo "Radio-processed versions: $RADIO_COUNT"
