# outreach-copilot

### Reach out to many. Drown in none.

You email a batch of people — candidates, vendors, investors, journalists, lawyers — and then the replies pile up. Some answer, some go quiet, each one needs a thoughtful, tailored response and a call on the calendar. **outreach-copilot runs that entire middle for you.**

It reads every reply into a Google Sheet, **drafts a tailored response to each** — in your voice, reading any attachments they send, and offering only times you're actually free — then **sends only the ones you approve**, properly threaded and never twice, and books confirmed calls on your calendar.

**You do two things:** send the first email, and skim a column of ready-to-send drafts. It handles the tracking, drafting, scheduling, and sending — so nothing slips and every prospect gets a real reply.

Works for **any multi-prospect outreach** — hiring, vendor selection, fundraising, sales, partnerships, press, professional counsel, real-estate agents. One config file per campaign; the engine is generic.

```
prospects reply → Gmail → [SWEEP] → Google Sheet (Prospects · Replies Log · Drafts)
                                         ↑ you set Status = Approved
                                         ↓
                                    [SENDER] → threaded reply + calendar invite
```

## What you get
- **A tracker sheet** (CRM): one row per prospect, a replies log, and a Drafts queue with a Status dropdown.
- **Daily reply-sweep** that classifies replies, extracts the things you care about, **reads attachments** (engagement letters, quotes, decks) and engages with their contents, and drafts your reply.
- **Calendar-aware scheduling**: proposes only genuinely-free slots, never offers the same slot twice, and books the call once a confirmation actually sends.
- **Approve-to-send**: nothing reaches a prospect until you mark a draft Approved. The sender is idempotent — a sent row is terminal.
- **Notifications you choose**: you always get an **email digest** of new replies in your own inbox; optionally add an **instant ping** by iMessage or Slack. Plus **configurable frequency** for both jobs. (See [docs/NOTIFICATIONS.md](docs/NOTIFICATIONS.md).)

## Prerequisites
Have all of these before you start — `scripts/preflight.sh` verifies each and tells you exactly what's missing:

1. **Claude Code** — the CLI this runs on.
2. **Google Workspace MCP (`workspace-mcp`)** — registered in Claude Code and authenticated to the Google account you'll use. This is the **required backend** for reliable Gmail/Sheets/Calendar *writes*; the hosted cloud connectors are **not** sufficient for the unattended sender (see [docs/BACKENDS.md](docs/BACKENDS.md) for why). **Full walkthrough → [docs/SETUP-WORKSPACE-MCP.md](docs/SETUP-WORKSPACE-MCP.md)**: needs Python 3.10+/`uv`, a Google Cloud OAuth (Desktop) client, the Gmail/Sheets/Drive/Calendar APIs enabled, and a one-time browser consent (approve the **write** scopes). The reference setup registers it over **stdio** (`claude mcp add workspace-mcp -s user -- uvx --from workspace-mcp workspace-mcp --single-user`), so Claude Code launches the server itself per run — no persistent server or port to manage for the scheduled jobs.
3. **python3** (renders config → prompts) and **curl** (notifications).
4. A scheduler: **launchd** (macOS, automatic) or **cron** (Linux; `install.sh` prints the lines).
5. *(optional)* `ANTHROPIC_API_KEY` at `~/.outreach-copilot/<slug>/.api-key` as a retry fallback.

Run `scripts/preflight.sh` to check all of the above in one shot.

## Quick start

### Option A — guided (recommended)
In Claude Code, run the bundled skill:

```
/setup-outreach-campaign
```

It interviews you about **what outreach you want to build**, asks **how many** prospects to shortlist and **confirms the selection methodology** (what matters, what doesn't), then **researches and builds the shortlist**, creates and seeds the tracker, helps you send the BCC outreach, and installs the jobs. (Copy `skill/setup-outreach-campaign/` into your Claude Code skills directory, or point Claude at this repo.)

### Option B — manual CLI
```bash
scripts/init.sh                 # interactive wizard → campaigns/<slug>.conf
#  ... create the tracker sheet (3 tabs) and seed your prospects (see sheet/SETUP.md),
#      put SPREADSHEET_ID into the config; send your BCC outreach and paste its
#      thread id / RFC Message-ID / subject / prospect domains into the config ...
scripts/render.sh  <slug>       # fill prompts + schedule from config
scripts/install.sh <slug>       # load launchd (macOS) or print cron lines
```
Then do the one manual sheet step (Status dropdown) from **[sheet/SETUP.md](sheet/SETUP.md)**.

## Configure
Everything lives in `campaigns/<slug>.conf` (start from [`campaigns/example.campaign.conf`](campaigns/example.campaign.conf)). Highlights:
- **Persona & voice** — who you are to recipients, signature, tone; `PHONE_DISCRETION` (email-only scheduling) and `DISCLOSE_COMPARISON`.
- **Extraction topics** — the (up to 4) questions you want answered by each prospect; they become tracker columns.
- **Scheduling** — timezone, call window, duration (or turn it off).
- **Frequency for both jobs** — `SWEEP_INTERVAL_HOURS` (24 = daily at `SWEEP_HOUR:SWEEP_MIN`, or every N hours) and `SENDER_INTERVAL_HOURS`.
- **Notifications** — you always get an email digest; `NOTIFY_CHANNEL` (email | imessage | slack | none) adds an optional instant ping. Setup per channel: [docs/NOTIFICATIONS.md](docs/NOTIFICATIONS.md).

Edit the config and re-run `scripts/render.sh <slug>` (and `install.sh <slug>` if the schedule changed).

## Day-to-day
1. Sweep drafts **Pending** replies into the Drafts tab.
2. You review and set **Status = Approved** (dropdown) on the good ones — edit the body first if you like.
3. The sender mails approved drafts within your interval, marks them **Sent**, and books any confirmed call.

## Multiple campaigns
Each campaign is its own `<slug>.conf` + tracker + jobs. Run as many as you want side by side.

## Privacy
Your data stays in **your** Google account and a local `~/.outreach-copilot/` dir. Real configs, prospect lists, and logs are gitignored. See **[docs/PRIVACY.md](docs/PRIVACY.md)**.

## How it works
See **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** for the two-agent design, idempotency model, and calendar flow.

## License
MIT — see [LICENSE](LICENSE). This software automates email on your behalf; you are responsible for what you send and for complying with anti-spam, privacy, and professional-conduct rules. Not legal advice.

---
*Born from a real EB-5 immigration-counsel search that needed to track 26 lawyers' replies, draft responses, and book intro calls — generalized so you can point it at any prospecting you need to do.*
