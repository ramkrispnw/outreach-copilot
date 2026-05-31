# outreach-copilot

**Track replies from a list of prospects, draft your responses, and send the ones you approve — on autopilot.** Built for any multi-prospect outreach: hiring, vendor selection, fundraising, sales, partnerships, press, professional counsel, real-estate agents, anything.

You BCC a batch of prospects once. From then on, a daily **sweep** reads their replies into a Google Sheet, drafts your response to each (calendar-aware, and it reads their attachments), and waits. You skim the drafts, flip a few to **Approved**, and a **sender** mails them — properly threaded, never double-sent — and books confirmed calls on your calendar.

Everything campaign-specific is one config file. The engine is generic.

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
- **Pluggable notifications** (email / iMessage / Slack / none) and **configurable frequency** for both jobs.

## Prerequisites
- **Claude Code**.
- **Google Workspace MCP (workspace-mcp)** registered in Claude Code and authed to your Google account — this is what gives reliable Gmail/Sheets/Calendar writes for the headless jobs. See **[docs/BACKENDS.md](docs/BACKENDS.md)** (and why the cloud connectors aren't enough).
- `envsubst` (gettext) + `curl`. **launchd** (macOS) or **cron** (Linux) for scheduling.

Run `scripts/preflight.sh` to check all of the above.

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
- **Notifications** — `NOTIFY_CHANNEL` = email | imessage | slack | none.

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
