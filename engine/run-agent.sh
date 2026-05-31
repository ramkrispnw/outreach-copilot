#!/bin/bash
# Generic headless runner for an outreach-copilot agent.
# Usage: run-agent.sh <campaign-slug> <sweep|sender>
#
# Reads the rendered campaign at  $OUTREACH_HOME/<slug>/  (default ~/.outreach-copilot/<slug>),
# runs `claude --print` with the rendered prompt, then routes the final NOTIFY: line
# to the configured notification channel. Retries transient failures; macOS-aware
# (uses caffeinate if present) but runs fine under cron on Linux.

set -uo pipefail

SLUG="${1:-}"
ROLE="${2:-}"
if [ -z "$SLUG" ] || { [ "$ROLE" != "sweep" ] && [ "$ROLE" != "sender" ]; }; then
  echo "usage: run-agent.sh <campaign-slug> <sweep|sender>" >&2; exit 2
fi

ENGINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$ENGINE_DIR/lib/notify.sh"

OUTREACH_HOME="${OUTREACH_HOME:-$HOME/.outreach-copilot}"
CAMP_DIR="$OUTREACH_HOME/$SLUG"
CONF="$CAMP_DIR/campaign.conf"
PROMPT_FILE="$CAMP_DIR/$ROLE.prompt"
LOG_FILE="$CAMP_DIR/$ROLE.run.log"

[ -f "$CONF" ]        || { echo "FATAL: missing $CONF (run scripts/render.sh $SLUG)" >&2; exit 1; }
[ -f "$PROMPT_FILE" ] || { echo "FATAL: missing $PROMPT_FILE (run scripts/render.sh $SLUG)" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONF"
PROMPT="$(cat "$PROMPT_FILE")"
CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
API_KEY_FILE="$CAMP_DIR/.api-key"
WATCHDOG_SECONDS=$([ "$ROLE" = "sweep" ] && echo 1800 || echo 1200)

echo "========================================" >> "$LOG_FILE"
echo "$SLUG $ROLE started: $(date)" >> "$LOG_FILE"

wait_for_network() {
  local i=0
  while [ $i -lt 30 ]; do
    curl -s -o /dev/null --max-time 5 https://api.anthropic.com 2>/dev/null && return 0
    sleep 2; i=$((i + 1))
  done; return 1
}
wait_for_network || echo "WARN: network unreachable after 60s - proceeding: $(date)" >> "$LOG_FILE"

LAST_STDOUT=""
run_claude() {
  local TMP; TMP=$(mktemp)
  local PREFIX=""
  command -v caffeinate >/dev/null 2>&1 && PREFIX="caffeinate -i"
  $PREFIX "$CLAUDE_BIN" --print --dangerously-skip-permissions "$PROMPT" > "$TMP" 2>&1 &
  local PID=$!
  ( sleep "$WATCHDOG_SECONDS"; kill $PID 2>/dev/null && echo "TIMED OUT: $(date)" >> "$TMP" ) &
  local WD=$!
  wait $PID 2>/dev/null; local CODE=$?
  kill $WD 2>/dev/null; wait $WD 2>/dev/null
  LAST_STDOUT=$(cat "$TMP"); cat "$TMP" >> "$LOG_FILE"; rm -f "$TMP"
  return $CODE
}

is_retryable() {
  tail -100 "$LOG_FILE" | grep -qiE \
    "stream idle timeout|partial response|TIMED OUT|connection.*reset|ECONNRESET|ETIMEDOUT|503|502|504|rate.*limit|overloaded|not logged in|unauthenticated|unauthorized|invalid.*key|auth.*fail|please.*login|ACTION REQUIRED: Google Authentication Needed"
}

EXIT_CODE=1
for ATTEMPT in 1 2 3; do
  if [ $((ATTEMPT % 2)) -eq 1 ] || [ ! -f "$API_KEY_FILE" ]; then
    unset ANTHROPIC_API_KEY
    echo "Attempt $ATTEMPT: claude.ai creds [$(date)]" >> "$LOG_FILE"
  else
    export ANTHROPIC_API_KEY="$(cat "$API_KEY_FILE")"
    echo "Attempt $ATTEMPT: API key [$(date)]" >> "$LOG_FILE"
  fi
  run_claude; EXIT_CODE=$?
  [ $EXIT_CODE -eq 0 ] && break
  is_retryable || { echo "Non-retryable (exit $EXIT_CODE) - stop." >> "$LOG_FILE"; break; }
  [ $ATTEMPT -lt 3 ] && { echo "Retryable - backoff $((ATTEMPT*300))s" >> "$LOG_FILE"; sleep $((ATTEMPT*300)); }
done

echo "$SLUG $ROLE finished (exit $EXIT_CODE): $(date)" >> "$LOG_FILE"
if [ $EXIT_CODE -eq 0 ]; then
  LINE=$(printf '%s\n' "$LAST_STDOUT" | grep -m1 '^NOTIFY: ' | sed 's/^NOTIFY: //')
  [ -n "$LINE" ] && notify_send "${NOTIFY_CHANNEL:-email}" "$LINE"
else
  notify_send "${NOTIFY_CHANNEL:-email}" "$CAMPAIGN_NAME $ROLE FAILED $(date +%Y-%m-%d): exit $EXIT_CODE. Tail $LOG_FILE"
fi
exit $EXIT_CODE
