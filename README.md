# outreach-copilot

[![CI](https://github.com/ramkrispnw/outreach-copilot/actions/workflows/ci.yml/badge.svg)](https://github.com/ramkrispnw/outreach-copilot/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Status: v0.1.0](https://img.shields.io/badge/status-v0.1.0-orange.svg)

### Reach out to many. Drown in none.

You email a batch of people — candidates, vendors, investors, journalists, lawyers — and then the replies pile up. Some answer, some go quiet, each one needs a thoughtful, tailored response and a call on the calendar. **outreach-copilot runs that entire middle for you.**

It reads every reply into a Google Sheet, **drafts a tailored response to each** — in your voice, reading any attachments they send, and offering only times you're actually free — then **sends only the ones you approve**, properly threaded and never twice, and books confirmed calls on your calendar.

**You do two things:** send the first email, and skim a column of ready-to-send drafts. It handles the tracking, drafting, scheduling, and sending — so nothing slips and every prospect gets a real reply.

Works for **any multi-prospect outreach** — hiring, vendor selection, fundraising, sales, partnerships, press, professional counsel, real-estate agents. One config file per campaign; the engine is generic.

## How it works in 30 seconds

```
prospects reply → Gmail → [SWEEP] → Google Sheet (Prospects · Replies Log · Drafts)
                                         ↑ you set Status = Approved
                                         ↓
                                    [SENDER] → threaded reply + calendar invite
```

**Setup (once, guided by the skill):** describe who you want to reach and how many — it runs **deep research**, shortlists the best matches against criteria you approve, builds the tracker, and helps you send the first outreach. Then the loop runs:

1. **You send one BCC outreach** to your prospect list (the skill helps draft + send it), and the tool notes the subject + which domains it went to.
2. **The sweep** (on your schedule) reads each reply into the sheet and writes a ready-to-send **draft** of your response — in your voice, reading their attachments, proposing only times you're actually free.
3. **You skim the Drafts tab** and flip `Status → Approved` on the ones you like (edit the wording first if you want).
4. **The sender** mails the approved ones — threaded, never twice — marks them **Sent**, and drops any confirmed call on your calendar.

<!-- Screenshot placeholder: capture the Drafts tab (showing the Pending/Approved/Sent color-coding)
     as docs/media/tracker.png, then uncomment the line below. Guidance: docs/media/README.md
![The Drafts tab — every reply becomes a Pending draft you flip to Approved](docs/media/tracker.png)
-->

## What you get
- **A researched shortlist to start from**: tell the setup skill who you're after and how many — it runs **deep research**, ranks candidates against criteria you approve, and seeds your tracker. You don't hand-build the prospect list.
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

### Option A — guided by Claude Code (recommended)
The repo ships a Claude Code **skill** that does the whole setup conversationally. Three steps:

**1. Get the repo:**
```bash
git clone https://github.com/ramkrispnw/outreach-copilot.git
cd outreach-copilot
```

**2. Install the skill** so Claude Code can find it — copy it into your personal skills folder:
```bash
mkdir -p ~/.claude/skills
cp -r skill/setup-outreach-campaign ~/.claude/skills/
```

**3. Open Claude Code in this folder and run the skill:**
```bash
claude            # starts Claude Code in the current directory
```
then, at the Claude Code prompt, type:
```
/setup-outreach-campaign
```
(Type it in full and press Enter — it shows up once the skill is in `~/.claude/skills/`.)

From there it interviews you about **what outreach you want to build**, asks **how many** prospects to shortlist and **confirms the selection methodology** (what matters, what doesn't), then **researches and builds the shortlist**, creates and seeds the tracker, helps you send the BCC outreach, and installs the scheduled jobs.

> **Don't want to install the skill?** Just open the repo in Claude Code and say:
> *"Set up an outreach-copilot campaign for me."* Claude will follow `skill/setup-outreach-campaign/SKILL.md` directly. Or use the manual CLI path in Option B.

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
- **Scheduling** — timezone, call window, duration, which calendar (or turn it off). Needs the Calendar API + read/write scope: [docs/CALENDAR.md](docs/CALENDAR.md).
- **Frequency for both jobs** — `SWEEP_INTERVAL_HOURS` (24 = daily at `SWEEP_HOUR:SWEEP_MIN`, or every N hours) and `SENDER_INTERVAL_HOURS`.
- **Notifications** — you always get an email digest; `NOTIFY_CHANNEL` (email | imessage | slack | none) adds an optional instant ping. Setup per channel: [docs/NOTIFICATIONS.md](docs/NOTIFICATIONS.md).

Edit the config and re-run `scripts/render.sh <slug>` (and `install.sh <slug>` if the schedule changed).

## Day-to-day
1. Sweep drafts **Pending** replies into the Drafts tab.
2. You review and set **Status = Approved** (dropdown) on the good ones — edit the body first if you like.
3. The sender mails approved drafts within your interval, marks them **Sent**, and books any confirmed call.

## Multiple campaigns
Each campaign is its own `<slug>.conf` + tracker + jobs. Run as many as you want side by side.

## Status & limitations
Early release. The engine is the same code proven on a real campaign, but validating a fresh
first-run setup is on you. Known constraints, up front:
- **Requires Claude Code + Anthropic usage** (the agents run via `claude --print`) and a local
  **workspace-mcp** Google backend — cloud-only Google connectors can't drive the unattended jobs.
- **Scheduling:** auto-install uses **launchd (macOS)**; Linux uses **cron** (lines printed for you);
  Windows isn't supported out of the box.
- **iMessage** pings are macOS-only; everyone can use the email digest (default) or Slack.
- **Single user, one machine** per campaign — the OAuth token and scheduled jobs live there.
- **It sends real email on your behalf.** You approve every message, but you are responsible for
  accuracy and for complying with anti-spam (CAN-SPAM/GDPR), privacy, and professional-conduct
  rules. Not legal advice.
- **Auto-shortlist quality** depends on the model and the rubric you approve — verify facts before
  acting on high-stakes outreach; the tool flags what it couldn't verify rather than inventing.

## Privacy
Your data stays in **your** Google account and a local `~/.outreach-copilot/` dir. Real configs, prospect lists, and logs are gitignored. See **[docs/PRIVACY.md](docs/PRIVACY.md)**.

## How it works
See **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** for the two-agent design, idempotency model, and calendar flow.

## License
MIT — see [LICENSE](LICENSE). This software automates email on your behalf; you are responsible for what you send and for complying with anti-spam, privacy, and professional-conduct rules. Not legal advice.

---
*Turns a pile of inbound replies into a short queue of approve-and-send drafts — so reaching out to many people stops meaning drowning in follow-up. Point it at any prospecting you need to do.*
