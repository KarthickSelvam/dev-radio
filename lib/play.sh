#!/usr/bin/env bash
# play.sh - Play a random sound from a category
# Usage: ./play.sh success|fail|neutral|misc [--radio-bias N]
#
# Options:
#   --radio-bias N   Percentage chance (0-100) to prefer radio-processed
#                    versions when available. Default: 80.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=platform.sh
source "$SCRIPT_DIR/platform.sh"

CATEGORY="${1:-neutral}"
RADIO_BIAS=80

# Parse optional flags
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --radio-bias) RADIO_BIAS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

SOUND_DIR="$DEVRADIO_DIR/sounds/$CATEGORY"

if [ ! -d "$SOUND_DIR" ]; then
  echo "dev-radio: unknown category '$CATEGORY'" >&2
  echo "Available: success, fail, neutral, misc" >&2
  exit 1
fi

# Collect sound files
pick_sound() {
  local dir="$1"
  local pattern="$2"

  # Use find + sort -R for cross-platform random selection (shuf not everywhere)
  if command -v shuf &>/dev/null; then
    find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | shuf -n 1
  else
    find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | while read -r f; do
      echo "$RANDOM $f"
    done | sort -n | head -1 | cut -d' ' -f2-
  fi
}

SOUND=""

# Prefer radio-processed versions based on bias
if [ $((RANDOM % 100)) -lt "$RADIO_BIAS" ]; then
  SOUND=$(pick_sound "$SOUND_DIR" "*-radio.*")
fi

# Fallback to any non-radio sound file
if [ -z "$SOUND" ]; then
  SOUND=$(find "$SOUND_DIR" -maxdepth 1 -type f \( -name "*.aiff" -o -name "*.wav" -o -name "*.mp3" \) ! -name "*-radio.*" 2>/dev/null | if command -v shuf &>/dev/null; then shuf -n 1; else awk 'BEGIN{srand()}{print rand()"\t"$0}' | sort -n | head -1 | cut -f2-; fi)
fi

# Last resort: any sound file at all
if [ -z "$SOUND" ]; then
  SOUND=$(pick_sound "$SOUND_DIR" "*.*")
fi

if [ -z "$SOUND" ]; then
  echo "dev-radio: no sounds found in $SOUND_DIR" >&2
  echo "Run: $(dirname "$SCRIPT_DIR")/scripts/generate-sounds.sh" >&2
  exit 1
fi

devradio_play_file "$SOUND"
