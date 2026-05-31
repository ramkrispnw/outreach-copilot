#!/bin/bash
# Render + schedule a campaign's sweep and sender jobs.
# Usage: scripts/install.sh <campaign-slug>
set -euo pipefail

SLUG="${1:-}"; [ -z "$SLUG" ] && { echo "usage: install.sh <slug>" >&2; exit 2; }
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTREACH_HOME="${OUTREACH_HOME:-$HOME/.outreach-copilot}"
CAMP_DIR="$OUTREACH_HOME/$SLUG"

"$REPO_DIR/scripts/preflight.sh" || { echo "Fix preflight issues, then re-run." >&2; exit 1; }
"$REPO_DIR/scripts/render.sh" "$SLUG"
chmod +x "$REPO_DIR/engine/run-agent.sh"

# Carry over an optional API key fallback if the user dropped one in the repo.
[ -f "$REPO_DIR/.api-key" ] && cp "$REPO_DIR/.api-key" "$CAMP_DIR/.api-key"

if [ "$(uname -s)" = "Darwin" ] && command -v launchctl >/dev/null 2>&1; then
  LA="$HOME/Library/LaunchAgents"; mkdir -p "$LA"
  for role in sweep send; do
    plist="$CAMP_DIR/com.outreach-copilot.$SLUG.$role.plist"
    dest="$LA/com.outreach-copilot.$SLUG.$role.plist"
    cp "$plist" "$dest"
    launchctl unload "$dest" 2>/dev/null || true
    launchctl load "$dest"
    echo "loaded: com.outreach-copilot.$SLUG.$role"
  done
  echo
  echo "Installed (launchd). Trigger now with:"
  echo "  launchctl start com.outreach-copilot.$SLUG.sweep"
  echo "  launchctl start com.outreach-copilot.$SLUG.send"
else
  echo
  echo "Non-macOS: add these cron lines (crontab -e). Also saved at $CAMP_DIR/crontab.txt :"
  echo "----------------------------------------------------------------"
  grep -vE '^\s*#' "$CAMP_DIR/crontab.txt" | grep -v '^\s*$'
  echo "----------------------------------------------------------------"
fi
echo "Logs: $CAMP_DIR/{sweep,sender}.run.log"
