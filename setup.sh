#!/usr/bin/env bash
# Sets up symlinks for all dotfiles, Cursor config, and Claude Code config.
# Safe to re-run: real files are backed up with .bak before being replaced.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1"   # path inside this repo
  local dest="$2"  # where it lives on the machine
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  backup  $dest → ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi
  ln -sf "$src" "$dest"
  echo "  link    $dest"
}

echo "==> Shell dotfiles"
link "$REPO/.zshrc"     "$HOME/.zshrc"
link "$REPO/.zshenv"    "$HOME/.zshenv"
link "$REPO/.zprofile"  "$HOME/.zprofile"
link "$REPO/.functions" "$HOME/.functions"
link "$REPO/.vimrc"     "$HOME/.vimrc"

echo ""
echo "==> Cursor"
link "$REPO/cursor/mcp.json"            "$HOME/.cursor/mcp.json"
link "$REPO/cursor/user/settings.json"  "$HOME/Library/Application Support/Cursor/User/settings.json"
link "$REPO/cursor/user/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"

echo ""
echo "==> Claude Code"
link "$REPO/claude/settings.json" "$HOME/.claude/settings.json"

# commands/ is a directory — back it up and symlink the whole thing
if [ -d "$HOME/.claude/commands" ] && [ ! -L "$HOME/.claude/commands" ]; then
  echo "  backup  $HOME/.claude/commands → $HOME/.claude/commands.bak"
  mv "$HOME/.claude/commands" "$HOME/.claude/commands.bak"
fi
ln -sf "$REPO/claude/commands" "$HOME/.claude/commands"
echo "  link    $HOME/.claude/commands"

echo ""
echo "==> Git hooks"
ln -sf "$REPO/hooks/post-merge" "$REPO/.git/hooks/post-merge"
echo "  link    .git/hooks/post-merge"

echo ""
echo "==> Monthly sync (crontab)"
CRON_ENTRY="3 9 1 * * $REPO/hooks/monthly-sync.sh >> $HOME/.monthly-sync.log 2>&1"
EXISTING_CRON=$(crontab -l 2>/dev/null || true)
if echo "$EXISTING_CRON" | grep -qF "monthly-sync.sh"; then
  echo "  already installed: monthly-sync crontab entry"
else
  (echo "$EXISTING_CRON"; echo "$CRON_ENTRY") | crontab -
  echo "  installed: runs at 9:03am on the 1st of each month"
fi

echo ""
echo "Done. Open a new shell and restart Cursor to pick up changes."
echo ""
echo "Manual steps:"
echo "  1. If this is a new machine, run ./install.sh first to install all software."
echo "  2. Claude Code skill — i18n-audit: open Claude Code and run /install-skill"
echo "     then search for 'i18n-audit'. Required for the /i18n-audit slash command."
