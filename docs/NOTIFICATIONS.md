# Notifications — how you hear about replies

## The model (read this first)
Two things happen on every run, and they're separate:

1. **Email digest — always on.** When the sweep finds new replies it emails you a **digest**
   (to your own `GOOGLE_ACCOUNT` inbox): who replied, a paraphrase, the extracted fields,
   attachments, and which Draft # is waiting. The sender emails a **confirmation** when it sends
   approved replies. This is your durable record and it happens regardless of the setting below.
2. **Instant ping — optional, via `NOTIFY_CHANNEL`.** A one-line summary pushed the moment a run
   finishes, so you don't have to watch your inbox.

So: you **always** get the email digest; `NOTIFY_CHANNEL` just decides whether you also get an
instant ping, and where.

| `NOTIFY_CHANNEL` | Instant ping? | What to set up |
|---|---|---|
| `email` (default) | none (the digest email is enough) | nothing |
| `imessage` | text message to your phone | macOS + `IMESSAGE_RECIPIENT` + Automation permission |
| `slack` | message in a Slack channel | `SLACK_WEBHOOK_URL` |
| `none` | no ping (you still get the digest email) | nothing |

The ping reads like: `NOTIFY: <Campaign> 2026-06-01: 2 substantive, 1 auto, 3 drafts pending. Sheet: <url>`

## Setup per channel

### email (default — zero setup)
Nothing to configure beyond `GOOGLE_ACCOUNT`. The digest/confirmation emails arrive in that inbox.
Tip: in Gmail, filter `subject:"<Campaign> digest"` into a label so they're easy to scan.

### imessage (macOS only)
1. Set in your config:
   ```
   NOTIFY_CHANNEL="imessage"
   IMESSAGE_RECIPIENT="+15551234567"   # your own number or Apple ID
   ```
2. The Mac running the jobs must be **signed into Messages** with iMessage enabled.
3. **Grant Automation permission** (one-time): the first run tries to control Messages via
   AppleScript. If macOS blocks it, go to **System Settings → Privacy & Security → Automation**
   and allow your runner (Terminal / the launchd process / `osascript`) to control **Messages**.
   Until that's granted, the ping silently no-ops (the digest email still arrives).

### slack
1. In Slack, create an **Incoming Webhook**: Slack → Apps → "Incoming Webhooks" → add to the
   channel you want → copy the webhook URL (looks like `https://hooks.slack.com/services/T.../B.../xxxx`).
2. Set in your config:
   ```
   NOTIFY_CHANNEL="slack"
   SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
   ```
The one-line summary posts to that channel after each run.

### none
No instant ping. You still receive the email digest (your record). Use this if you'd rather just
open the tracker on your own schedule.

## Changing your notification setting later
Edit `campaigns/<slug>.conf`, then **re-render** so the runtime copy updates:
```bash
scripts/render.sh <slug>
```
(No reinstall needed — the runner reads the channel from the rendered config at run time.)

## "I'm not getting anything"
- **No digest email** → the sweep found no new replies (it's silent on empty runs), or the sweep
  job isn't running. Check `~/.outreach-copilot/<slug>/sweep.run.log`.
- **Digest email but no iMessage/Slack ping** → channel/recipient not set, or (iMessage) Automation
  permission not granted, or (Slack) webhook URL wrong. The ping failing never blocks the run.
- **Nothing at all, ever** → confirm the jobs are installed (`scripts/install.sh <slug>`) and that
  workspace-mcp is connected (`scripts/preflight.sh`).
