# Calendar — read free/busy, book confirmed calls

## What the tool does with your calendar
- **Reads** your calendar to propose only **genuinely-free** times when a draft offers call slots
  (it ignores events whose title starts with `[Tentative`, and never offers the same slot to two
  prospects in one run).
- **Writes** exactly one thing: when a prospect confirms a time and your confirming reply actually
  sends, it **creates the event** and adds the prospect as a **guest** (so they get the invite).
- It never books anything off your approval — an event is only created after a confirmation you
  Approved goes out. Turn the whole feature off with `SCHEDULING_ENABLED="false"` (then it neither
  reads your calendar nor books anything).

## What you need to do (3 things)

### 1. Enable the Google Calendar API
In the Google Cloud project that holds your OAuth client, enable the **Google Calendar API**
(this is one of the four APIs in [SETUP-WORKSPACE-MCP.md](SETUP-WORKSPACE-MCP.md) step 1).

### 2. Grant calendar **read + write** at OAuth consent
On the workspace-mcp consent screen, approve the **Calendar** scope at **read + write** (create
events) — not read-only. If you launched the server with `--read-only`, or you skipped the
calendar scope, free/busy reads may work but **event creation will fail**. (workspace-mcp's
default tool set includes the calendar write tools; don't restrict them.)

### 3. Set the scheduling knobs in your campaign config
```
SCHEDULING_ENABLED="true"
CALENDAR_ID="primary"                 # your main calendar; or a specific calendar's ID (below)
CALL_TIMEZONE="America/New_York"      # IANA tz — slots & events use this
CALL_WINDOW="weekdays 9:00am-5:00pm; no weekends"
CALL_DURATION_MIN="30"
```
Re-render after editing: `scripts/render.sh <slug>`.

## Using a calendar other than your primary
Set `CALENDAR_ID` to that calendar's ID and make sure the authenticated account can **make
changes to events** on it (owner, or "Make changes to events" sharing).
- Find the ID: Google Calendar → hover the calendar → ⋮ → **Settings and sharing** →
  **Integrate calendar** → **Calendar ID** (e.g. `abc123@group.calendar.google.com`).
- For your own main calendar, leave it as `primary`.

## Good to know
- **Prospects receive an invite.** Because they're added as a guest, Google emails them a calendar
  invitation for the confirmed call. That's intended (it books the meeting on both sides).
- **Timezone:** all proposed slots and created events use `CALL_TIMEZONE`. Set it to your own zone.
- **Privacy:** the tool reads your busy times on the configured calendar only, to avoid
  double-booking — it doesn't copy your calendar anywhere.

## Troubleshooting
- *Drafts propose times but no event ever appears* → confirm `SCHEDULING_ENABLED=true`, the
  Calendar **write** scope was granted, and `CALENDAR_ID` is correct/writable. The sender creates
  the event right after the confirmation sends; the next sweep is a backstop that retries any miss.
- *`ACTION REQUIRED: Google Authentication Needed`* → re-run a tool interactively to refresh consent.
- *Events created in the wrong time* → check `CALL_TIMEZONE`.
