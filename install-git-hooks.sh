#!/usr/bin/env bash
# install-git-hooks.sh - Install sound hooks into the current git repo
# Usage: cd your-repo && /path/to/dev-radio/install-git-hooks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${DEVRADIO_DIR:-$HOME/.dev-radio}"

# Prefer the installed location, fall back to repo location
if [ -d "$INSTALL_DIR/hooks/git" ]; then
  SOURCE_DIR="$INSTALL_DIR/hooks/git"
else
  SOURCE_DIR="$SCRIPT_DIR/hooks/git"
fi

if [ ! -d ".git" ]; then
  echo "Error: not in a git repository" >&2
  exit 1
fi

HOOKS_DIR=".git/hooks"

echo "dev-radio: Installing git hooks..."

for hook in post-commit pre-push post-merge post-checkout; do
  if [ -f "$SOURCE_DIR/$hook" ]; then
    cat > "$HOOKS_DIR/$hook" <<HOOKEOF
#!/usr/bin/env bash
export DEVRADIO_DIR="$INSTALL_DIR"
source "$SOURCE_DIR/$hook"
HOOKEOF
    chmod +x "$HOOKS_DIR/$hook"
    echo "  $hook"
  fi
done

echo ""
echo "Done! Make a commit to hear it."
