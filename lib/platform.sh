#!/usr/bin/env bash
# platform.sh - Cross-platform audio playback and detection
# Source this file; do not execute directly.

# Resolve DEVRADIO_DIR from this script's location
if [ -z "$DEVRADIO_DIR" ]; then
  DEVRADIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Detect platform and set the audio play command
_devradio_detect_player() {
  if command -v afplay &>/dev/null; then
    echo "afplay"          # macOS
  elif command -v paplay &>/dev/null; then
    echo "paplay"          # Linux (PulseAudio)
  elif command -v pw-play &>/dev/null; then
    echo "pw-play"         # Linux (PipeWire)
  elif command -v aplay &>/dev/null; then
    echo "aplay"           # Linux (ALSA)
  elif command -v mpv &>/dev/null; then
    echo "mpv --no-video"  # Cross-platform fallback
  elif command -v ffplay &>/dev/null; then
    echo "ffplay -nodisp -autoexit -loglevel quiet"  # ffmpeg fallback
  else
    echo ""
  fi
}

# Play a single audio file
# Usage: devradio_play_file /path/to/sound.aiff
devradio_play_file() {
  local file="$1"
  local player
  player=$(_devradio_detect_player)

  if [ -z "$player" ]; then
    return 1  # no player available
  fi

  if [ ! -f "$file" ]; then
    return 1
  fi

  # Run in background so it doesn't block
  # Word-splitting on $player is intentional for multi-arg commands (e.g. "mpv --no-video")
  # shellcheck disable=SC2086
  $player "$file" &>/dev/null &
}

# Detect TTS engine for sound generation
_devradio_detect_tts() {
  if command -v say &>/dev/null; then
    echo "say"       # macOS
  elif command -v espeak-ng &>/dev/null; then
    echo "espeak-ng"  # Linux
  elif command -v espeak &>/dev/null; then
    echo "espeak"     # Linux (older)
  else
    echo ""
  fi
}

# Generate a TTS audio file
# Usage: devradio_tts "Hello world" /path/to/output.aiff [voice]
devradio_tts() {
  local text="$1"
  local output="$2"
  local voice="${3:-}"
  local tts
  tts=$(_devradio_detect_tts)

  case "$tts" in
    say)
      local v="${voice:-Daniel}"
      say -v "$v" -o "$output" "$text" 2>/dev/null
      ;;
    espeak-ng|espeak)
      local v="${voice:-en}"
      $tts -v "$v" -w "$output" "$text" 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

# Check if sox is available (for radio effects)
devradio_has_sox() {
  command -v sox &>/dev/null
}

# Send a desktop notification (best-effort)
devradio_notify() {
  local title="$1"
  local message="$2"

  if command -v osascript &>/dev/null; then
    osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
  elif command -v notify-send &>/dev/null; then
    notify-send "$title" "$message" 2>/dev/null || true
  fi
}
