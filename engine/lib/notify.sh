#!/bin/bash
# Pluggable notifier. Routes a one-line summary to the configured channel.
# Sourced by run-agent.sh. Channels: email | imessage | slack | none.
# For 'email', the agent itself already sends a full digest, so this is a no-op.

notify_send() {
  local channel="$1"; shift
  local msg="$*"
  [ -z "$msg" ] && return 0
  case "$channel" in
    imessage)
      [ -z "${IMESSAGE_RECIPIENT:-}" ] && return 0
      command -v osascript >/dev/null 2>&1 || return 0
      local m="${msg//\\/\\\\}"; m="${m//\"/\\\"}"
      osascript -e "tell application \"Messages\" to send \"$m\" to buddy \"$IMESSAGE_RECIPIENT\" of (1st service whose service type = iMessage)" >/dev/null 2>&1 || true
      ;;
    slack)
      [ -z "${SLACK_WEBHOOK_URL:-}" ] && return 0
      # minimal JSON string escape (backslash, quote, newline)
      local e="${msg//\\/\\\\}"; e="${e//\"/\\\"}"; e="${e//$'\n'/\\n}"
      curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"${e}\"}" "$SLACK_WEBHOOK_URL" >/dev/null 2>&1 || true
      ;;
    email|none|*)
      : # email: agent already emailed the digest; none: stay silent
      ;;
  esac
}
