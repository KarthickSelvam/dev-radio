#!/usr/bin/env bash
# generate-sounds.sh - Generate voice clip sounds using text-to-speech
#
# Creates categorized audio clips using the system TTS engine:
#   - macOS: `say` command (high quality)
#   - Linux: `espeak-ng` or `espeak`
#
# Usage: ./generate-sounds.sh [--radio]
#   --radio   Also generate radio-processed versions (requires sox)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVRADIO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/platform.sh
source "$DEVRADIO_DIR/lib/platform.sh"

GENERATE_RADIO=false
if [[ "${1:-}" == "--radio" ]]; then
  GENERATE_RADIO=true
fi

SOUNDS_DIR="$DEVRADIO_DIR/sounds"

# Voice selection
TTS=$(_devradio_detect_tts)
if [ -z "$TTS" ]; then
  echo "Error: No TTS engine found." >&2
  echo "  macOS: 'say' should be available by default" >&2
  echo "  Linux: install espeak-ng (apt install espeak-ng)" >&2
  exit 1
fi

echo "dev-radio: Generating sounds using $TTS..."
echo ""

# Determine file extension
if [ "$TTS" = "say" ]; then
  EXT="aiff"
  VOICE_NORMAL="Daniel"
  VOICE_ROBOT="Zarvox"
else
  EXT="wav"
  VOICE_NORMAL="en"
  VOICE_ROBOT="en+whisper"
fi

generate() {
  local category="$1"
  local filename="$2"
  local text="$3"
  local voice="${4:-$VOICE_NORMAL}"
  local outfile="$SOUNDS_DIR/$category/$filename.$EXT"

  if [ -f "$outfile" ]; then
    return 0  # don't overwrite existing
  fi

  devradio_tts "$text" "$outfile" "$voice"

  if [ "$GENERATE_RADIO" = true ] && devradio_has_sox; then
    local radiofile="$SOUNDS_DIR/$category/${filename}-radio.$EXT"
    if [ ! -f "$radiofile" ]; then
      sox "$outfile" "$radiofile" \
        bandpass 1500 1200 \
        compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 \
        reverb 20 50 50 50 0 0 \
        gain -n -3 \
        2>/dev/null || true
    fi
  fi
}

# --- Success sounds ---
echo "  [success]"
generate success "complete"             "Complete"
generate success "confirmed"            "Confirmed"
generate success "done"                 "Done"
generate success "all-clear"            "All clear"
generate success "solid-copy"           "Solid copy"
generate success "good-to-go"          "Good to go"
generate success "mission-complete"    "Mission complete"
generate success "task-done"           "Task done"

# --- Fail sounds ---
echo "  [fail]"
generate fail "negative"               "Negative"
generate fail "error"                  "Error"
generate fail "no-go"                  "No go"
generate fail "problem-detected"       "Problem detected"
generate fail "check-your-work"        "Check your work"
generate fail "try-again"              "Try again"

# --- Neutral sounds ---
echo "  [neutral]"
generate neutral "copy-that"           "Copy that"
generate neutral "standing-by"         "Standing by"
generate neutral "in-progress"         "In progress"
generate neutral "acknowledged"        "Acknowledged"
generate neutral "proceeding"          "Proceeding"
generate neutral "on-it"              "On it"

# --- Misc sounds (robot voice) ---
echo "  [misc]"
generate misc "systems-online"         "Systems online"            "$VOICE_ROBOT"
generate misc "ready-to-go"            "Ready to go"               "$VOICE_ROBOT"
generate misc "all-systems-nominal"    "All systems nominal"       "$VOICE_ROBOT"
generate misc "powering-up"            "Powering up"               "$VOICE_ROBOT"
generate misc "engaged"                "Engaged"                   "$VOICE_ROBOT"
generate misc "lets-roll"              "Let's roll"                "$VOICE_ROBOT"

COUNT=$(find "$SOUNDS_DIR" -type f \( -name "*.aiff" -o -name "*.wav" -o -name "*.mp3" \) | wc -l | tr -d ' ')
echo ""
echo "Generated $COUNT sound files in $SOUNDS_DIR/"

if [ "$GENERATE_RADIO" = true ] && devradio_has_sox; then
  RADIO_COUNT=$(find "$SOUNDS_DIR" -type f -name "*-radio.*" | wc -l | tr -d ' ')
  echo "  (including $RADIO_COUNT radio-processed versions)"
elif [ "$GENERATE_RADIO" = true ]; then
  echo ""
  echo "Note: sox not found, skipped radio effects."
  echo "  macOS: brew install sox"
  echo "  Linux: apt install sox"
fi

echo ""
echo "Test: $DEVRADIO_DIR/lib/play.sh success"
