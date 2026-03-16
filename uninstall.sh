#!/usr/bin/env bash
# uninstall.sh - Remove dev-radio
#
# Usage:
#   ./uninstall.sh              # Remove ~/.dev-radio and Claude Code hooks
#   ./uninstall.sh --keep-sounds  # Remove config but keep sound files

set -euo pipefail

INSTALL_DIR="$HOME/.dev-radio"
KEEP_SOUNDS=false

if [[ "${1:-}" == "--keep-sounds" ]]; then
  KEEP_SOUNDS=true
fi

echo "dev-radio uninstaller"
echo "====================="
echo ""

# Remove Claude Code hooks
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ] && command -v jq &>/dev/null; then
  if grep -q "claude-code\.sh\|dev-radio" "$CLAUDE_SETTINGS" 2>/dev/null; then
    echo "Removing Claude Code hooks..."
    # Remove hooks that reference dev-radio
    jq 'if .hooks then .hooks |= with_entries(
      .value |= map(
        .hooks |= map(select(.command | test("dev-radio|claude-code") | not))
        | select(.hooks | length > 0)
      )
      | select(length > 0)
    ) else . end' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
    echo "  Removed from $CLAUDE_SETTINGS"
  fi
fi

# Remove global git hooks if they reference dev-radio
TEMPLATE_DIR="$HOME/.git-templates/hooks"
if [ -d "$TEMPLATE_DIR" ]; then
  for hook in post-commit pre-push post-merge post-checkout; do
    if [ -f "$TEMPLATE_DIR/$hook" ] && grep -q "dev-radio\|DEVRADIO" "$TEMPLATE_DIR/$hook" 2>/dev/null; then
      rm "$TEMPLATE_DIR/$hook"
      echo "  Removed git hook: $hook"
    fi
  done
fi

# Remove installation
if [ -d "$INSTALL_DIR" ]; then
  if [ "$KEEP_SOUNDS" = true ]; then
    echo "Keeping sounds in $INSTALL_DIR/sounds/"
    find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 ! -name sounds -exec rm -rf {} \;
  else
    rm -rf "$INSTALL_DIR"
    echo "Removed $INSTALL_DIR"
  fi
fi

echo ""
echo "dev-radio uninstalled."
