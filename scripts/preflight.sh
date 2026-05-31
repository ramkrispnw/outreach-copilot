#!/bin/bash
# Verify prerequisites before installing a campaign.
# Usage: scripts/preflight.sh
set -uo pipefail
ok=0; warn=0

chk() { if eval "$2" >/dev/null 2>&1; then echo "  [ok]   $1"; else echo "  [MISS] $1"; ok=1; fi; }
soft(){ if eval "$2" >/dev/null 2>&1; then echo "  [ok]   $1"; else echo "  [warn] $1 — $3"; warn=1; fi; }

echo "outreach-copilot preflight:"
chk  "Claude Code CLI (claude)" "command -v claude || [ -x \"$HOME/.local/bin/claude\" ]"
chk  "python3 (renders templates)" "command -v python3"
chk  "curl"                     "command -v curl"

echo "Google Workspace MCP (REQUIRED — gives reliable Gmail/Sheets/Calendar writes for headless jobs):"
if claude mcp list 2>/dev/null | grep -qiE "workspace-mcp|workspace_mcp"; then
  echo "  [ok]   workspace-mcp is registered with Claude Code"
else
  echo "  [MISS] workspace-mcp not found in 'claude mcp list'."
  echo "         Install it (one-time):  see docs/BACKENDS.md"
  echo "         Then authenticate it to the Google account in your campaign.conf."
  ok=1
fi

case "$(uname -s)" in
  Darwin) soft "scheduler: launchctl (macOS)" "command -v launchctl" "install.sh will use launchd" ;;
  *)      soft "scheduler: crontab"            "command -v crontab"   "install.sh will print cron lines to add" ;;
esac

echo
if [ $ok -ne 0 ]; then echo "Preflight: MISSING prerequisites above — resolve before install."; exit 1; fi
[ $warn -ne 0 ] && echo "Preflight: OK with warnings." || echo "Preflight: all good."
exit 0
