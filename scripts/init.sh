#!/bin/bash
# Interactive wizard: "what outreach do you want to build?"
# Produces campaigns/<slug>.conf you can then render + install (or hand to the
# /setup-outreach-campaign Claude skill to also research + build the shortlist + sheet).
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ask() { # ask "Prompt" "default" -> echoes answer
  local p="$1" d="${2:-}" a
  if [ -n "$d" ]; then read -r -p "$p [$d]: " a; echo "${a:-$d}"; else read -r -p "$p: " a; echo "$a"; fi
}

echo "=============================================="
echo " outreach-copilot — new campaign"
echo "=============================================="
echo
echo "What kind of outreach do you want to build?"
echo "  1) Hiring / recruiting candidates"
echo "  2) Vendor / service-provider selection"
echo "  3) Fundraising / investor outreach"
echo "  4) Sales / lead outreach"
echo "  5) Partnerships / business development"
echo "  6) Press / PR / media"
echo "  7) Professional services / counsel (lawyers, advisors)"
echo "  8) Real-estate agents"
echo "  9) Home services / local quotes (contractor, landscaper, handyman, mover, plumber)"
echo " 10) Custom"
TYPE="$(ask 'Choose 1-10' '9')"

case "$TYPE" in
  1) TOPICS="Role fit and relevant experience
Compensation expectations and notice period
Work authorization / location / remote
Availability to interview"; PERSONA_HINT="I'm hiring for <role> and reaching out to strong candidates."; DISC="false" ;;
  2) TOPICS="Scope of services and approach
Pricing model and what's included vs extra
Timeline and capacity
Relevant track record / references"; PERSONA_HINT="I'm evaluating vendors for <need> and gathering proposals."; DISC="true" ;;
  3) TOPICS="Fund thesis / stage / check size fit
Process and timeline to a decision
Terms and value-add beyond capital
Portfolio relevance"; PERSONA_HINT="I'm raising <round> for <company> and reaching out to relevant investors."; DISC="true" ;;
  4) TOPICS="Fit for their use case / pain point
Decision process and stakeholders
Budget / timeline
Next-step interest"; PERSONA_HINT="I'm reaching out about <product/service> that may fit their needs."; DISC="false" ;;
  5) TOPICS="Partnership model and fit
Who owns it on their side
Commercial / integration terms
Timeline and next steps"; PERSONA_HINT="I'm exploring a partnership between <us> and their org."; DISC="true" ;;
  6) TOPICS="Beat / coverage fit
Interest in the story / angle
What they need from me (assets, exclusivity)
Timeline / deadline"; PERSONA_HINT="I'm pitching <story> and reaching out to relevant journalists."; DISC="false" ;;
  7) TOPICS="Engagement model / who handles the matter day-to-day
Fee structure: what's included across stages vs billed separately
How they support due diligence and keep it independent
Relevant experience with my specific situation"; PERSONA_HINT="I'm evaluating counsel/advisors for <matter> and want independent representation."; DISC="true" ;;
  8) TOPICS="Local market expertise and recent comparable deals
Commission and what's included
Availability and communication cadence
References"; PERSONA_HINT="I'm looking for an agent to help with <buy/sell> in <area>."; DISC="true" ;;
  9) TOPICS="Scope of the job and their approach
Itemized quote / estimate
Earliest availability and timeline
License, insurance, and reviews/references"; PERSONA_HINT="I'm getting quotes for <job> at <location> and comparing a few local pros."; DISC="true" ;;
  *) TOPICS="Topic 1
Topic 2
Topic 3
Topic 4"; PERSONA_HINT="<describe who you are and what you're asking>"; DISC="true" ;;
esac

echo
CAMPAIGN_NAME="$(ask 'Campaign name (human label)' 'My outreach campaign')"
DEFAULT_SLUG="$(echo "$CAMPAIGN_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')"
CAMPAIGN_SLUG="$(ask 'Short slug (kebab-case)' "$DEFAULT_SLUG")"
GOOGLE_ACCOUNT="$(ask 'Google account (Gmail/Drive/Calendar)' '')"
SENDER_NAME="$(ask 'Your name (reply signature)' '')"
SENDER_EMAIL="$(ask 'Your reply email' "$GOOGLE_ACCOUNT")"
echo
echo "One-line context recipients should have about you (persona):"
PERSONA="$(ask "  persona" "$PERSONA_HINT")"
echo
DISCLOSE_COMPARISON="$(ask 'OK to acknowledge you are evaluating several providers? (true/false)' "$DISC")"
PHONE_DISCRETION="$(ask 'Keep your phone number OUT of replies (email-only scheduling)? (true/false)' 'true')"
echo
SCHEDULING_ENABLED="$(ask 'Enable calendar-aware call scheduling? (true/false)' 'true')"
CALL_TIMEZONE="$(ask '  your timezone' 'America/New_York')"
CALL_WINDOW="$(ask '  call window' 'weekdays 9:00am-5:00pm local; no weekends')"
CALL_DURATION_MIN="$(ask '  call length (min)' '30')"
echo
echo "Frequencies (you can set how often BOTH jobs run):"
SWEEP_INTERVAL_HOURS="$(ask '  reply-sweep: hours between runs (24=once daily)' '24')"
SWEEP_HOUR="$(ask '  if daily, hour of day (0-23)' '6')"
SWEEP_MIN="$(ask '  if daily, minute' '15')"
SENDER_INTERVAL_HOURS="$(ask '  sender: hours between runs' '3')"
echo
NOTIFY_CHANNEL="$(ask 'Notifications: email | imessage | slack | none' 'email')"
IMESSAGE_RECIPIENT=""; SLACK_WEBHOOK_URL=""
[ "$NOTIFY_CHANNEL" = "imessage" ] && IMESSAGE_RECIPIENT="$(ask '  iMessage recipient (+1...)' '')"
[ "$NOTIFY_CHANNEL" = "slack" ] && SLACK_WEBHOOK_URL="$(ask '  Slack webhook URL' '')"

OUT="$REPO_DIR/campaigns/$CAMPAIGN_SLUG.conf"
{
  echo "# Generated by scripts/init.sh on $(date)"
  echo "CAMPAIGN_NAME=\"$CAMPAIGN_NAME\""
  echo "CAMPAIGN_SLUG=\"$CAMPAIGN_SLUG\""
  echo "GOOGLE_ACCOUNT=\"$GOOGLE_ACCOUNT\""
  echo "SPREADSHEET_ID=\"\""
  echo "PROSPECT_TAB=\"Prospects\""
  echo "OUTREACH_SUBJECT=\"$CAMPAIGN_NAME — intro\""
  echo "OUTREACH_THREAD_ID=\"\""
  echo "OUTREACH_RFC_MSGID=\"\""
  echo "PROSPECT_DOMAINS=\"\""
  echo "DEDUP_LABEL=\"outreach-copilot/$CAMPAIGN_SLUG/processed\""
  echo "SENDER_NAME=\"$SENDER_NAME\""
  echo "SENDER_EMAIL=\"$SENDER_EMAIL\""
  echo "SIGNATURE=\"Best regards,\\n$SENDER_NAME\\n$SENDER_EMAIL\""
  echo "DRAFT_TONE=\"professional, warm, concise; 4-9 sentences; no marketing fluff\""
  echo "PHONE_DISCRETION=\"$PHONE_DISCRETION\""
  echo "DISCLOSE_COMPARISON=\"$DISCLOSE_COMPARISON\""
  echo "PERSONA=\"$PERSONA\""
  echo "EXTRACTION_TOPICS=\"$TOPICS\""
  echo "SCHEDULING_ENABLED=\"$SCHEDULING_ENABLED\""
  echo "CALENDAR_ID=\"primary\""
  echo "CALL_TIMEZONE=\"$CALL_TIMEZONE\""
  echo "CALL_WINDOW=\"$CALL_WINDOW\""
  echo "CALL_DURATION_MIN=\"$CALL_DURATION_MIN\""
  echo "SWEEP_INTERVAL_HOURS=\"$SWEEP_INTERVAL_HOURS\""
  echo "SWEEP_HOUR=\"$SWEEP_HOUR\""
  echo "SWEEP_MIN=\"$SWEEP_MIN\""
  echo "SENDER_INTERVAL_HOURS=\"$SENDER_INTERVAL_HOURS\""
  echo "NOTIFY_CHANNEL=\"$NOTIFY_CHANNEL\""
  echo "IMESSAGE_RECIPIENT=\"$IMESSAGE_RECIPIENT\""
  echo "SLACK_WEBHOOK_URL=\"$SLACK_WEBHOOK_URL\""
  echo "CLAUDE_BIN=\"\$HOME/.local/bin/claude\""
} > "$OUT"

echo
echo "Wrote $OUT"
echo
echo "Next steps:"
echo "  • Recommended: in Claude Code run  /setup-outreach-campaign $CAMPAIGN_SLUG"
echo "    — it will research and build your shortlist (it asks how many + the criteria),"
echo "      create the Google Sheet, seed prospects, and help you send the outreach."
echo "  • Or do it manually: create the sheet, fill SPREADSHEET_ID/PROSPECT_DOMAINS/outreach IDs,"
echo "    then:  scripts/render.sh $CAMPAIGN_SLUG  &&  scripts/install.sh $CAMPAIGN_SLUG"
