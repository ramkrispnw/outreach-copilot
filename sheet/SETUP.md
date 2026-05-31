# Tracker sheet

Each campaign uses one Google Sheet with three tabs. The `/setup-outreach-campaign`
skill creates and seeds it for you; this page documents the schema and the one
manual step (the Status dropdown).

## Tabs & columns

**Prospects** (your shortlist; row 1 = header, prospects from row 2)
| A | B | C | D | E | F | G | H | I | J–M | N | O | P |
|---|---|---|---|---|---|---|---|---|-----|---|---|---|
| # | Org | Contact(s) | Email | Tag | Notes | Sent (UTC) | Reply? | Reply Date | 4 extraction fields | Status | Notes | Last Follow-up |

> **Off-by-one:** sheet row = (column-A #) + 1, because row 1 is the header. The
> engine relies on this when updating a prospect's row.

**Replies Log** — one row per substantive reply: Date received, Org (Contact),
Email, Subject, Summary, Extra, Key points, Action needed.

**Drafts** — the approve-to-send queue: Draft #, Drafted On, Prospect, To, Cc,
Subject, Body, In-Reply-To, References, Thread ID, **Status**, Sent At, Sent Msg ID, Notes.

## The one manual step: Status dropdown

Google's data-validation (dropdown) can't be set through the MCP tools, so:

1. Open your tracker → **Extensions → Apps Script**.
2. Paste the contents of [`setup-sheet.gs`](./setup-sheet.gs).
3. **Run → `setupTracker`**, authorize once.

This installs the **Status** dropdown (Pending / Approved / Sending / Sent / Skip /
Failed) on `Drafts!K`, color-codes it, and applies header formatting + text wrapping.
(Color-coding works even before the dropdown is installed.)

## Day-to-day

Review drafts in the **Drafts** tab → set **Status = Approved** on the ones you want
sent → the sender job mails them within your configured interval and flips them to
**Sent**. A row with a Sent Msg ID is terminal and never re-sent.
