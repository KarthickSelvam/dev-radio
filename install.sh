#!/usr/bin/env bash
# install.sh - Install dev-radio sound system
#
# What this does:
#   1. Copies dev-radio to ~/.dev-radio (or uses it in-place with --local)
#   2. Generates sounds using your system's TTS engine
#   3. Configures Claude Code hooks in ~/.claude/settings.json
#   4. Optionally installs git hooks globally
#
# Usage:
#   ./install.sh                    # Full install to ~/.dev-radio
#   ./install.sh --local            # Use from current directory (dev mode)
#   ./install.sh --no-claude        # Skip Claude Code hooks
#   ./install.sh --no-sounds        # Skip sound generation (bring your own)
#   ./install.sh --with-git-hooks   # Also set up global git hooks
#   ./install.sh --radio            # Generate radio-processed versions (needs sox)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
INSTALL_DIR="$HOME/.dev-radio"
LOCAL_MODE=false
SETUP_CLAUDE=true
GENERATE_SOUNDS=true
SETUP_GIT_HOOKS=false
RADIO_MODE=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)          LOCAL_MODE=true; shift ;;
    --no-claude)      SETUP_CLAUDE=false; shift ;;
    --no-sounds)      GENERATE_SOUNDS=false; shift ;;
    --with-git-hooks) SETUP_GIT_HOOKS=true; shift ;;
    --radio)          RADIO_MODE=true; shift ;;
    --help|-h)
      echo "Usage: ./install.sh [--local] [--no-claude] [--no-sounds] [--with-git-hooks] [--radio]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

echo "dev-radio installer"
echo "==================="
echo ""

# ─── Preflight checks ───────────────────────────────────────────────

WARNINGS=0

# Audio player (required — the whole point)
PLAYER=""
for cmd in afplay paplay pw-play aplay mpv ffplay; do
  if command -v "$cmd" &>/dev/null; then
    PLAYER="$cmd"
    break
  fi
done
if [ -z "$PLAYER" ]; then
  echo "ERROR: No audio player found." >&2
  echo "  dev-radio needs one of: afplay (macOS), paplay, pw-play, aplay (Linux), mpv, or ffplay" >&2
  echo "  Install one and try again." >&2
  exit 1
fi
echo "  Audio player: $PLAYER"

# Claude Code (needed for hooks)
if [ "$SETUP_CLAUDE" = true ]; then
  if ! command -v claude &>/dev/null; then
    echo "  WARNING: Claude Code CLI not found in PATH."
    echo "           Hooks will be configured but won't fire until Claude Code is installed."
    echo "           Install: https://docs.anthropic.com/en/docs/claude-code"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "  Claude Code: $(claude --version 2>/dev/null || echo "found")"
  fi
fi

# jq (needed for safe settings.json editing)
if [ "$SETUP_CLAUDE" = true ] && ! command -v jq &>/dev/null; then
  echo "  WARNING: jq not found. Cannot auto-configure Claude Code hooks."
  echo "           You'll need to add hooks manually (see examples/claude-code-hooks.json)."
  echo "           Install: brew install jq / apt install jq"
  WARNINGS=$((WARNINGS + 1))
fi

# TTS engine (needed for sound generation)
if [ "$GENERATE_SOUNDS" = true ]; then
  TTS_FOUND=false
  for cmd in say espeak-ng espeak; do
    if command -v "$cmd" &>/dev/null; then
      TTS_FOUND=true
      echo "  TTS engine: $cmd"
      break
    fi
  done
  if [ "$TTS_FOUND" = false ]; then
    echo "  WARNING: No TTS engine found (say, espeak-ng, espeak)."
    echo "           Sound generation will be skipped. Shipped sounds will still work."
    echo "           Linux: apt install espeak-ng"
    GENERATE_SOUNDS=false
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# sox (only when --radio requested)
if [ "$RADIO_MODE" = true ] && ! command -v sox &>/dev/null; then
  echo "  WARNING: sox not found. Radio effects will be skipped."
  echo "           Install: brew install sox / apt install sox"
  RADIO_MODE=false
  WARNINGS=$((WARNINGS + 1))
fi

# git (needed for git hooks)
if [ "$SETUP_GIT_HOOKS" = true ] && ! command -v git &>/dev/null; then
  echo "  WARNING: git not found. Skipping git hooks setup."
  SETUP_GIT_HOOKS=false
  WARNINGS=$((WARNINGS + 1))
fi

if [ "$WARNINGS" -gt 0 ]; then
  echo ""
  echo "  $WARNINGS warning(s) above. Continuing with available features..."
fi

echo ""

# ─── Install ─────────────────────────────────────────────────────────

# Step 1: Install files
if [ "$LOCAL_MODE" = true ]; then
  INSTALL_DIR="$SCRIPT_DIR"
  echo "[1/4] Using local directory: $INSTALL_DIR"
else
  echo "[1/4] Installing to $INSTALL_DIR..."
  if [ -d "$INSTALL_DIR" ] && [ "$INSTALL_DIR" != "$SCRIPT_DIR" ]; then
    echo "  Updating existing installation..."
    # Preserve user's custom sounds
    rm -rf "/tmp/dev-radio-sounds-backup" 2>/dev/null || true
    if [ -d "$INSTALL_DIR/sounds" ]; then
      cp -r "$INSTALL_DIR/sounds" "/tmp/dev-radio-sounds-backup" 2>/dev/null || true
    fi
  fi

  mkdir -p "$INSTALL_DIR"
  cp -r "$SCRIPT_DIR/lib" "$INSTALL_DIR/"
  cp -r "$SCRIPT_DIR/hooks" "$INSTALL_DIR/"
  cp -r "$SCRIPT_DIR/scripts" "$INSTALL_DIR/"
  cp -r "$SCRIPT_DIR/sounds" "$INSTALL_DIR/"
  mkdir -p "$INSTALL_DIR/sounds"/{success,fail,neutral,misc}

  # Restore user's custom sounds (don't overwrite shipped sounds they may have modified)
  if [ -d "/tmp/dev-radio-sounds-backup" ]; then
    cp -rn /tmp/dev-radio-sounds-backup/* "$INSTALL_DIR/sounds/" 2>/dev/null || true
    rm -rf "/tmp/dev-radio-sounds-backup"
  fi

  cp "$SCRIPT_DIR/README.md" "$INSTALL_DIR/" 2>/dev/null || true
  cp "$SCRIPT_DIR/LICENSE" "$INSTALL_DIR/" 2>/dev/null || true

  # Make scripts executable
  find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
  chmod +x "$INSTALL_DIR/hooks/git/"* 2>/dev/null || true
fi

export DEVRADIO_DIR="$INSTALL_DIR"

# Step 2: Generate sounds
if [ "$GENERATE_SOUNDS" = true ]; then
  echo "[2/4] Generating sounds..."
  RADIO_FLAG=""
  if [ "$RADIO_MODE" = true ]; then
    RADIO_FLAG="--radio"
  fi
  bash "$INSTALL_DIR/scripts/generate-sounds.sh" $RADIO_FLAG
else
  echo "[2/4] Skipping sound generation (--no-sounds)"
  mkdir -p "$INSTALL_DIR/sounds"/{success,fail,neutral,misc}
fi

# Step 3: Configure Claude Code hooks
if [ "$SETUP_CLAUDE" = true ]; then
  echo "[3/4] Configuring Claude Code hooks..."

  CLAUDE_SETTINGS="$HOME/.claude/settings.json"
  mkdir -p "$HOME/.claude"

  HOOK_CMD="$INSTALL_DIR/hooks/claude-code.sh"

  if [ -f "$CLAUDE_SETTINGS" ]; then
    # Check if hooks are already configured
    if grep -q "dev-radio\|claude-code\.sh" "$CLAUDE_SETTINGS" 2>/dev/null; then
      echo "  Claude Code hooks already configured."
    else
      # Backup existing settings
      cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup"
      echo "  Backed up existing settings to settings.json.backup"

      if command -v jq &>/dev/null; then
        # Use jq to append hooks without overwriting existing ones
        HOOKS_JSON=$(cat <<EOF
{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "$HOOK_CMD", "async": true}]
    }
  ],
  "Stop": [
    {
      "hooks": [{"type": "command", "command": "$HOOK_CMD", "async": true}]
    }
  ],
  "Notification": [
    {
      "matcher": "permission_prompt",
      "hooks": [{"type": "command", "command": "$HOOK_CMD", "async": true}]
    }
  ]
}
EOF
)
        # Append to existing hook arrays rather than replacing them
        jq --argjson new_hooks "$HOOKS_JSON" '
          .hooks //= {} |
          .hooks |= reduce ($new_hooks | to_entries[]) as $entry (
            .;
            .[$entry.key] = ((.[$entry.key] // []) + $entry.value)
          )
        ' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
        echo "  Added hooks to $CLAUDE_SETTINGS"
      else
        echo "  Warning: jq not found. Please add hooks manually."
        echo "  See: $INSTALL_DIR/examples/claude-code-hooks.json"
      fi
    fi
  else
    # Create new settings file
    cat > "$CLAUDE_SETTINGS" <<EOF
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "$HOOK_CMD", "async": true}]
      }
    ],
    "Stop": [
      {
        "hooks": [{"type": "command", "command": "$HOOK_CMD", "async": true}]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [{"type": "command", "command": "$HOOK_CMD", "async": true}]
      }
    ]
  }
}
EOF
    echo "  Created $CLAUDE_SETTINGS with hooks"
  fi
else
  echo "[3/4] Skipping Claude Code hooks (--no-claude)"
fi

# Step 4: Git hooks (optional)
if [ "$SETUP_GIT_HOOKS" = true ]; then
  echo "[4/4] Setting up global git hooks..."

  TEMPLATE_DIR="$HOME/.git-templates"
  HOOKS_DIR="$TEMPLATE_DIR/hooks"
  mkdir -p "$HOOKS_DIR"

  for hook in post-commit pre-push post-merge post-checkout; do
    if [ -f "$INSTALL_DIR/hooks/git/$hook" ]; then
      # Write a wrapper that sets DEVRADIO_DIR
      cat > "$HOOKS_DIR/$hook" <<HOOKEOF
#!/usr/bin/env bash
export DEVRADIO_DIR="$INSTALL_DIR"
source "$INSTALL_DIR/hooks/git/$hook"
HOOKEOF
      chmod +x "$HOOKS_DIR/$hook"
    fi
  done

  git config --global init.templateDir "$TEMPLATE_DIR"
  echo "  Global git hooks configured."
  echo "  New repos will get sound hooks automatically."
  echo "  For existing repos: cd repo && $INSTALL_DIR/install-git-hooks.sh"
else
  echo "[4/4] Skipping git hooks (use --with-git-hooks to enable)"
fi

echo ""
echo "==========================="
echo "dev-radio installed!"
echo ""
echo "  Install dir: $INSTALL_DIR"
echo "  Test:        $INSTALL_DIR/lib/play.sh success"
echo "  Demo:        $INSTALL_DIR/scripts/demo.sh"
echo "  Add sounds:  drop files into $INSTALL_DIR/sounds/<category>/"
echo ""

if [ "$SETUP_CLAUDE" = true ]; then
  echo "Claude Code will now play sounds automatically."
fi
