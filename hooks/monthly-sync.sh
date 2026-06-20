#!/usr/bin/env bash
# Monthly drift check — installed as a crontab entry by setup.sh (runs 9:03am on the 1st).
# Prefers invoking a Claude agent for comprehensive drift detection.
# Falls back to bash-only implementation if the claude CLI is not available.
set -euo pipefail

REPO="$HOME/projects/personal/misc-setup"
DATE=$(date +%Y-%m-%d)

# Load env vars (crontab does not source .zshenv)
[ -f "$HOME/.zshenv" ] && source "$HOME/.zshenv"

# Read Gmail app password from Keychain (never stored in files)
GMAIL_APP_PASSWORD=$(security find-generic-password -a "$USER" -s "gmail-app-password" -w 2>/dev/null || true)

# ── Claude agent path ─────────────────────────────────────────────────────────

if command -v claude >/dev/null 2>&1; then
  PROMPT=$(DATE="$DATE" REPO="$REPO" envsubst < "$REPO/hooks/monthly-sync-prompt.md")
  echo "monthly-sync $DATE: invoking Claude agent..."
  claude --allowedTools "Bash,Read,Edit" -p "$PROMPT"
  exit 0
fi

# ── Bash fallback (used when claude CLI is not available) ─────────────────────

echo "monthly-sync $DATE: claude CLI not found, running bash fallback..."

BREWFILE="$REPO/install/Brewfile"
BRANCH="techstar-mac"
CHANGED=false
NEW_FORMULAS=""
NEW_CASKS=""

cd "$REPO"
git checkout "$BRANCH" 2>/dev/null

# Formulae
grep '^brew "' "$BREWFILE" | sed 's/brew "\([^"]*\)".*/\1/' | sort > /tmp/ms_bf_formulas.txt
brew leaves 2>/dev/null | sort > /tmp/ms_leaves.txt
NEW_FORMULAS=$(comm -23 /tmp/ms_leaves.txt /tmp/ms_bf_formulas.txt || true)

if [ -n "$NEW_FORMULAS" ]; then
  printf '\n# ── Added by monthly-sync %s ────────────────────────────────────────────────\n' "$DATE" >> "$BREWFILE"
  while IFS= read -r formula; do
    printf 'brew "%s"\n' "$formula" >> "$BREWFILE"
    echo "  + brew: $formula"
  done <<< "$NEW_FORMULAS"
  CHANGED=true
fi

# Casks
grep '^cask "' "$BREWFILE" | sed 's/cask "\([^"]*\)".*/\1/' | sort > /tmp/ms_bf_casks.txt
brew list --cask 2>/dev/null | sort > /tmp/ms_casks.txt
NEW_CASKS=$(comm -23 /tmp/ms_casks.txt /tmp/ms_bf_casks.txt || true)

if [ -n "$NEW_CASKS" ]; then
  [ "$CHANGED" = false ] && printf '\n# ── Added by monthly-sync %s ────────────────────────────────────────────────\n' "$DATE" >> "$BREWFILE"
  while IFS= read -r cask; do
    printf 'cask "%s"\n' "$cask" >> "$BREWFILE"
    echo "  + cask: $cask"
  done <<< "$NEW_CASKS"
  CHANGED=true
fi

if [ "$CHANGED" = false ]; then
  echo "monthly-sync $DATE: no drift detected."
  rm -f /tmp/ms_leaves.txt /tmp/ms_casks.txt /tmp/ms_bf_formulas.txt /tmp/ms_bf_casks.txt
  exit 0
fi

git add "$BREWFILE"
git commit -m "chore: monthly sync $DATE (bash fallback)"
git push origin "$BRANCH"

PR_URL=$(gh pr create \
  --base main --head "$BRANCH" \
  --title "chore: monthly sync $DATE" \
  --body "Auto-detected new Homebrew packages (bash fallback — claude CLI was not available)." \
  2>&1 | tail -1)

echo "PR: $PR_URL"

command -v terminal-notifier >/dev/null 2>&1 && \
  terminal-notifier -title "dotfiles: monthly sync" -message "PR: $PR_URL" -open "$PR_URL"

if [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  python3 - <<PYEOF
import smtplib, os
from email.mime.text import MIMEText
body = """PR: ${PR_URL}

New formulae:
${NEW_FORMULAS}

New casks:
${NEW_CASKS}
"""
msg = MIMEText(body)
msg['Subject'] = 'dotfiles: monthly sync ${DATE}'
msg['From'] = msg['To'] = 'isaacns98@gmail.com'
with smtplib.SMTP_SSL('smtp.gmail.com', 465) as s:
    s.login('isaacns98@gmail.com', os.environ['GMAIL_APP_PASSWORD'])
    s.send_message(msg)
PYEOF
fi

rm -f /tmp/ms_leaves.txt /tmp/ms_casks.txt /tmp/ms_bf_formulas.txt /tmp/ms_bf_casks.txt
