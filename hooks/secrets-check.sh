#!/usr/bin/env bash
# Claude Code PreToolUse hook — blocks git commit/push/gh pr when secrets are detected.
# Reads the Bash tool input JSON from stdin; outputs a deny decision if secrets are found.
set -euo pipefail

CMD=$(jq -r '.tool_input.command // ""' 2>/dev/null || true)

# Only inspect commit / push / PR commands. Pass --no-verify through untouched.
is_commit=false
is_push_or_pr=false

if echo "$CMD" | grep -qE '(^|[;&|])\s*git commit' && ! echo "$CMD" | grep -q -- '--no-verify'; then
  is_commit=true
fi

if echo "$CMD" | grep -qE '(^|[;&|])\s*(git push|gh pr (create|c)\b)'; then
  is_push_or_pr=true
fi

[ "$is_commit" = false ] && [ "$is_push_or_pr" = false ] && exit 0

# ── Patterns ────────────────────────────────────────────────────────────────
SECRET_RE='(AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY)'
CRED_RE='(PASSWORD|SECRET|TOKEN|API_KEY|APP_KEY|PRIVATE_KEY)\s*=\s*[A-Za-z0-9/+_-]{10,}'
SAFE_RE='(#|your-|placeholder|example|getenv|environ|os\.environ|\$\(|\$\{|=\$)'

scan_content() {
  local content="$1"
  local label="$2"
  local hit=""

  if echo "$content" | grep -qE "$SECRET_RE"; then
    hit="$label: private key or AWS access key"
  elif echo "$content" | grep -qE "$CRED_RE"; then
    local cred_lines
    cred_lines=$(echo "$content" | grep -E "$CRED_RE" || true)
    if echo "$cred_lines" | grep -qvE "$SAFE_RE"; then
      hit="$label: possible hardcoded credential"
    fi
  fi

  echo "$hit"
}

FOUND=()

if [ "$is_commit" = true ]; then
  # Scan staged files
  STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    if git show ":$file" 2>/dev/null | file - 2>/dev/null | grep -q binary; then continue; fi
    content=$(git show ":$file" 2>/dev/null || true)
    hit=$(scan_content "$content" "$file")
    [ -n "$hit" ] && FOUND+=("$hit")
  done <<< "$STAGED"
fi

if [ "$is_push_or_pr" = true ]; then
  # Scan commits not yet on the remote
  UPSTREAM=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "")
  if [ -n "$UPSTREAM" ]; then
    DIFF=$(git log "${UPSTREAM}..HEAD" -p --no-color 2>/dev/null || true)
  else
    DIFF=$(git log -3 -p --no-color 2>/dev/null || true)
  fi
  hit=$(scan_content "$DIFF" "unpushed commits")
  [ -n "$hit" ] && FOUND+=("$hit")
fi

if [ ${#FOUND[@]} -eq 0 ]; then
  exit 0
fi

REASON="Possible secrets detected — commit blocked:"
for h in "${FOUND[@]}"; do
  REASON="$REASON $h;"
done
REASON="$REASON Use --no-verify to bypass if this is a false positive."

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' \
  "$(echo "$REASON" | sed 's/"/\\"/g')"
