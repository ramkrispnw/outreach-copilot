---
name: setup-outreach-campaign
description: Stand up a new outreach-copilot campaign end to end — interview the user about what outreach they want to build, research and build a prospect shortlist (asking how many and confirming the selection methodology), create and seed the Google tracker, help send the BCC outreach, and install the daily reply-sweep + approve-to-send jobs. Use when the user wants to start prospecting/outreach to multiple people (hiring, vendors, investors, sales, partnerships, press, counsel, agents) and track + reply to responses.
---

# Setup an outreach-copilot campaign

You are standing up a complete multi-prospect outreach system: a Google Sheet tracker,
a daily reply-sweep that drafts replies, and an approve-to-send job. Work through the
phases in order. Confirm with the user at each decision point — never assume scope.

## Phase 0 — Preflight (do first)
Run `scripts/preflight.sh`. The hard requirement is **workspace-mcp** (Google Workspace MCP)
registered in Claude Code and authenticated to the user's Google account — it provides the
reliable Gmail/Sheets/Calendar **writes** the headless jobs need. If it's missing, stop and
walk the user through `docs/BACKENDS.md` before continuing. Do NOT try to substitute the
claude.ai cloud Google connectors — they can't do the cell-level writes the sender relies on.

## Phase 1 — Interview: "what outreach do you want to build?"
Ask the user (conversationally, or run `scripts/init.sh` which presets these by archetype):
- The **goal / archetype** (hiring, vendor selection, fundraising, sales, partnerships, press, counsel, real estate, custom).
- **Who they are** to the recipients (one-line persona) and their **reply voice/signature**.
- The **questions they want answered** by each prospect (these become the 4 tracked fields / EXTRACTION_TOPICS).
- **Scheduling**: do they want calendar-aware call scheduling? timezone, window, duration.
- **Notifications**: email | imessage | slack | none.
- **Frequency for ALL jobs**: how often the reply-sweep runs (`SWEEP_INTERVAL_HOURS`, 24=daily at a time; <24=every N hours) and how often the sender runs (`SENDER_INTERVAL_HOURS`).
Write/update `campaigns/<slug>.conf` with the answers (start from `campaigns/example.campaign.conf`).
Apply two voice rules consistently: keep the user's phone out of replies (email-only scheduling)
unless they say otherwise, and only signal comparison-shopping if `DISCLOSE_COMPARISON=true`.

## Phase 2 — Shortlist size + methodology (confirm BEFORE researching)
1. Ask **how many** prospects to shortlist (e.g. 10 / 25 / 50).
2. Confirm the **selection methodology**: based on what the user is looking for, propose a
   ranking rubric — what matters most, what matters less, and what is disqualifying. Surface
   it as an explicit weighted list and get the user's sign-off / edits. Example dimensions:
   relevance/fit, track record, credibility signals, reachability, cost, location, reviews.
3. State what you can and cannot verify, and how you'll handle unverifiable claims.
Do not start research until the count and rubric are approved.

## Phase 3 — Deep research to build the shortlist
Use the **deep-research** skill (or a fan-out of web-search + fetch agents) to find candidates,
then score each against the approved rubric and select the top N. Apply rigor:
- Distinguish **verifiable facts** from marketing/self-reported claims; label the latter.
- For high-stakes domains (money, legal, health), present a **diligence shortlist, not
  endorsements**, and flag what couldn't be verified (e.g. track record, outcomes).
- Capture, per prospect: org, contact name(s), best email, a tier/tag, and a short "why /
  best-fit" note plus anything relevant to the user's extraction topics.
Present the shortlist to the user for approval/edits before seeding.

## Phase 4 — Create + seed the tracker (workspace-mcp)
- `mcp__workspace-mcp__create_spreadsheet` titled "<Campaign> Outreach Tracker" with tabs
  `Prospects`, `Replies Log`, `Drafts`.
- Write headers (see `sheet/SETUP.md` for the exact schema) and **seed the Prospects rows**
  from the approved shortlist (col A = 1..N; remember sheet row = #+1).
- Format via `format_sheet_range` / `resize_sheet_dimensions` / `manage_conditional_formatting`
  (navy frozen headers, widths, wrap, status + tag color-coding).
- Create the dedup Gmail label `outreach-copilot/<slug>/processed` via `manage_gmail_label`.
- **Dropdown:** tell the user to open the sheet → Extensions → Apps Script → paste
  `sheet/setup-sheet.gs` → Run `setupTracker` (one-time; data-validation has no MCP tool).
- Put the new spreadsheet ID into `campaigns/<slug>.conf` (`SPREADSHEET_ID`).

## Phase 5 — Compose + send the outreach
- Draft the BCC outreach email in the user's voice (persona + the questions they want answered).
- Get the user's approval, then send via `mcp__workspace-mcp__send_gmail_message` with the
  shortlist addresses in **bcc** (To = the user themselves). Or have the user send it.
- Capture the sent message's **thread id**, **RFC Message-ID**, and final **subject**, and the
  set of **prospect domains**, into `campaigns/<slug>.conf` (OUTREACH_THREAD_ID,
  OUTREACH_RFC_MSGID, OUTREACH_SUBJECT, PROSPECT_DOMAINS). Replies thread back to this.

## Phase 6 — Render + install
- `scripts/render.sh <slug>` then `scripts/install.sh <slug>`.
- On macOS this loads launchd jobs; elsewhere it prints cron lines to add.
- Offer to trigger the first sweep now (`launchctl start com.outreach-copilot.<slug>.sweep`)
  to process any replies already in the inbox — it only emails/notifies the user, never prospects.

## Phase 7 — Handoff
Explain the loop: each sweep drafts **Pending** replies (calendar-aware, reads attachments);
the user flips **Status → Approved** in the Drafts tab; the sender mails approved drafts
(idempotent — never double-sends), and books confirmed calls on the calendar. Point them at
the tracker URL and `docs/ARCHITECTURE.md`.

## Guardrails
- Never send a prospect anything except via an **Approved** draft (or the explicit outreach the user approved).
- Never fabricate research, reviews, or contact details. Leave blanks rather than guess.
- Never commit the user's real campaign config, shortlist, or account to git (it's gitignored).
