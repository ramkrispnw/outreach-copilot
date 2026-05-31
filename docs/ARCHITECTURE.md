# Architecture

Two headless agents around one Google Sheet. Everything campaign-specific is config; the
engine is generic.

```
  Your BCC outreach email ──────────────┐
                                         ▼
  prospects reply ──► Gmail ──►  [ SWEEP agent ]  (every SWEEP_INTERVAL_HOURS)
                                   │  classify + extract (reads attachments)
                                   │  calendar-aware draft of your reply
                                   ▼
                          Google Sheet tracker
                          ├─ Prospects   (CRM view; one row per prospect)
                          ├─ Replies Log (one row per substantive reply)
                          └─ Drafts      (Status: Pending → you Approve → Sent)
                                   ▲
   you flip Status=Approved ───────┘
                                   ▼
                          [ SENDER agent ]  (every SENDER_INTERVAL_HOURS)
                            sends Approved drafts (threaded), marks Sent,
                            books confirmed calls on your Calendar
```

## Why two agents
- **Sweep** is read-heavy and creative (classify, extract, draft). Runs on your schedule.
- **Sender** is a tiny, safety-critical loop (send + mark). Separating it keeps sending
  idempotent and lets you gate every outbound message behind an explicit `Approved`.

## Idempotency (never double-send, never stuck)
- **Per-message dedup:** every processed Gmail message gets the campaign's dedup label; future
  sweeps filter it out. Handles follow-ups, OOO-then-real-reply, and downtime.
- **Claim-before-send:** the sender sets `Status=Sending` before mailing, so an overlapping
  run skips it. A non-blank `Sent Msg ID` is **terminal** — that row is never sent again.
- **Stuck detection:** a row left `Sending` > 24h is flagged `Failed`, not silently retried.

## Calendar flow
The sweep proposes only **free** slots (it reads your calendar and ignores `[Tentative` holds),
and never offers the same slot to two prospects in one run. When a draft *confirms* a specific
time, it writes a `CALENDAR_PENDING:` directive to the Drafts row. The sender creates the event
**after** that confirmation actually sends (so your calendar matches what the prospect was told);
the next sweep is a backstop that creates any event the sender missed.

## Off-by-one
Prospects sheet row = (column-A #) + 1 (row 1 is the header). The engine converts # → row when
updating a prospect; per-row writes must respect this.

## Files
- `campaigns/<slug>.conf` — the only thing you edit per campaign.
- `templates/*.tmpl` — generic prompts + schedules; `scripts/render.sh` fills them with config.
- `~/.outreach-copilot/<slug>/` — rendered prompts, plists, logs (machine-local, not in git).
- `engine/run-agent.sh` — the headless runner (retry, watchdog, notify).
