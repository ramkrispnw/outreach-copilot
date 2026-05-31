#!/bin/bash
# Render a campaign's prompts + schedule files from its config.
# Usage: scripts/render.sh <campaign-slug>
# Output goes to  $OUTREACH_HOME/<slug>/  (default ~/.outreach-copilot/<slug>).
set -euo pipefail

SLUG="${1:-}"; [ -z "$SLUG" ] && { echo "usage: render.sh <slug>" >&2; exit 2; }
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="$REPO_DIR/campaigns/$SLUG.conf"
[ -f "$CONF" ] || { echo "No config at $CONF. Copy campaigns/example.campaign.conf to campaigns/$SLUG.conf (or run scripts/init.sh)." >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || { echo "Missing python3 (used to render templates)." >&2; exit 1; }

# shellcheck source=/dev/null
set -a; source "$CONF"; set +a

OUTREACH_HOME="${OUTREACH_HOME:-$HOME/.outreach-copilot}"
CAMP_DIR="$OUTREACH_HOME/$SLUG"
mkdir -p "$CAMP_DIR"

# Derived values
export REPO_DIR CAMP_DIR OUTREACH_HOME HOME
export SENDER_INTERVAL_SECONDS=$(( ${SENDER_INTERVAL_HOURS:-3} * 3600 ))
SWEEP_INTERVAL_HOURS="${SWEEP_INTERVAL_HOURS:-24}"
export SWEEP_INTERVAL_HOURS
# Build a Gmail "(from:a OR from:b)" clause from space-separated PROSPECT_DOMAINS
_or=""; for d in ${PROSPECT_DOMAINS:-}; do _or="${_or:+$_or OR }from:$d"; done
export PROSPECT_DOMAINS_OR="$_or"

# Sweep frequency: daily-at-time when 24h, else every-N-hours.
if [ "$SWEEP_INTERVAL_HOURS" -ge 24 ]; then
  export SWEEP_SCHEDULE_XML="<key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key><integer>${SWEEP_HOUR}</integer>
        <key>Minute</key><integer>${SWEEP_MIN}</integer>
    </dict>"
  export SWEEP_CRON_SCHEDULE="${SWEEP_MIN} ${SWEEP_HOUR} * * *"
else
  export SWEEP_SCHEDULE_XML="<key>StartInterval</key>
    <integer>$(( SWEEP_INTERVAL_HOURS * 3600 ))</integer>"
  export SWEEP_CRON_SCHEDULE="${SWEEP_MIN} */${SWEEP_INTERVAL_HOURS} * * *"
fi

# Only these ${VARS} are substituted; anything else in a template is left untouched.
export OC_VARS="CAMPAIGN_NAME CAMPAIGN_SLUG GOOGLE_ACCOUNT SPREADSHEET_ID PROSPECT_TAB \
OUTREACH_SUBJECT OUTREACH_THREAD_ID OUTREACH_RFC_MSGID PROSPECT_DOMAINS PROSPECT_DOMAINS_OR \
DEDUP_LABEL SENDER_NAME SENDER_EMAIL SIGNATURE DRAFT_TONE PHONE_DISCRETION DISCLOSE_COMPARISON \
PERSONA EXTRACTION_TOPICS SCHEDULING_ENABLED CALENDAR_ID CALL_TIMEZONE CALL_WINDOW CALL_DURATION_MIN \
REPO_DIR CAMP_DIR OUTREACH_HOME HOME SWEEP_HOUR SWEEP_MIN SENDER_INTERVAL_SECONDS SENDER_INTERVAL_HOURS \
SWEEP_INTERVAL_HOURS SWEEP_SCHEDULE_XML SWEEP_CRON_SCHEDULE"

_render() {
  python3 -c '
import os, sys, re
allow = set(os.environ["OC_VARS"].split())
t = open(sys.argv[1]).read()
t = re.sub(r"\$\{([A-Za-z0-9_]+)\}",
           lambda m: os.environ.get(m.group(1), m.group(0)) if m.group(1) in allow else m.group(0),
           t)
open(sys.argv[2], "w").write(t)
' "$1" "$2"
}

_render "$REPO_DIR/templates/sweep.prompt.tmpl"         "$CAMP_DIR/sweep.prompt"
_render "$REPO_DIR/templates/sender.prompt.tmpl"        "$CAMP_DIR/sender.prompt"
_render "$REPO_DIR/templates/launchd/sweep.plist.tmpl"  "$CAMP_DIR/com.outreach-copilot.$SLUG.sweep.plist"
_render "$REPO_DIR/templates/launchd/sender.plist.tmpl" "$CAMP_DIR/com.outreach-copilot.$SLUG.send.plist"
_render "$REPO_DIR/templates/cron/crontab.example"      "$CAMP_DIR/crontab.txt"
cp "$CONF" "$CAMP_DIR/campaign.conf"

echo "Rendered campaign '$SLUG' -> $CAMP_DIR"
echo "  - sweep.prompt / sender.prompt"
echo "  - launchd plists + crontab.txt"
[ -z "${SPREADSHEET_ID:-}" ] && echo "  NOTE: SPREADSHEET_ID is empty — create the tracker first (scripts or the /setup-outreach-campaign skill), then re-render."
[ -z "${OUTREACH_THREAD_ID:-}" ] && echo "  NOTE: OUTREACH_THREAD_ID is empty — send your BCC outreach, paste its thread id + RFC Message-ID into the config, then re-render."
echo "Next: scripts/install.sh $SLUG"
