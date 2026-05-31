#!/bin/bash
# Remove a campaign's scheduled jobs (keeps the tracker sheet and config).
# Usage: scripts/uninstall.sh <campaign-slug>
set -euo pipefail
SLUG="${1:-}"; [ -z "$SLUG" ] && { echo "usage: uninstall.sh <slug>" >&2; exit 2; }

if [ "$(uname -s)" = "Darwin" ] && command -v launchctl >/dev/null 2>&1; then
  LA="$HOME/Library/LaunchAgents"
  for role in sweep send; do
    dest="$LA/com.outreach-copilot.$SLUG.$role.plist"
    if [ -f "$dest" ]; then
      launchctl unload "$dest" 2>/dev/null || true
      rm -f "$dest"
      echo "removed: com.outreach-copilot.$SLUG.$role"
    fi
  done
else
  echo "Non-macOS: remove the outreach-copilot lines for '$SLUG' from your crontab (crontab -e)."
fi
echo "Note: the Google Sheet, Gmail label, and campaign config are left intact."
