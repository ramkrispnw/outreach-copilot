# Backends & prerequisites (the workspace-mcp question)

outreach-copilot drives Gmail, Google Sheets, and Google Calendar **through Claude Code's
MCP tools**. It does not talk to Google directly. So "what Google integration do I have in
Claude Code?" is the key setup question.

## Required: a local Google Workspace MCP (workspace-mcp)

The headless jobs must **write** to Google reliably — update sheet cells, send threaded mail,
create calendar events. The supported backend for that is **workspace-mcp** (the open-source
Google Workspace MCP server), running locally and authenticated to your Google account.

Why local workspace-mcp specifically:
- It exposes cell-level Sheets writes (`modify_sheet_values`), threaded send
  (`send_gmail_message` with in-reply-to/references/thread-id), label management, and
  Calendar create — everything the sweep and sender need.
- It runs on **your machine**, so the scheduled launchd/cron jobs can use it headlessly.

> **Heads-up from real use:** the hosted/cloud Google connectors are great for chat but were
> **not** reliable for the unattended *sender* (cell-level sheet writes failed), which is why
> sending lives locally on workspace-mcp. Don't substitute the cloud connector for the jobs.

### Install (one-time)
Full step-by-step (Python/uv, Google Cloud OAuth client, APIs to enable, `claude mcp add`,
one-time consent, and keeping it running for scheduled jobs) is in
**[SETUP-WORKSPACE-MCP.md](SETUP-WORKSPACE-MCP.md)**. In short: `uvx workspace-mcp`, create a
Desktop OAuth client, register it in Claude Code, approve consent once, and authenticate the
account that matches `GOOGLE_ACCOUNT`. Verify with `claude mcp list` (or `scripts/preflight.sh`).

## "What if a user doesn't have workspace-mcp?"
- **Recommended:** install it (above). It's free and is the path this project is built and
  tested on.
- **Different but compatible Google MCP:** the prompt templates reference tools by the
  `mcp__workspace-mcp__*` names. If you run a different server that offers equivalent
  Gmail/Sheets/Calendar tools, the agent can use the equivalents — but you'll want to adjust
  the tool names in `templates/*.tmpl` to match your server. Treat this as advanced.
- **No local MCP at all:** the unattended scheduling model won't work, because a cloud routine
  can't reach a local MCP and the cloud Google connector can't do the writes. Your options are
  to run workspace-mcp, or to use only the *interactive* parts (run the `/setup-outreach-campaign`
  skill and approve/send drafts by hand in a Claude Code session) without the launchd/cron jobs.

## Other prerequisites
- `python3` (renders config into prompts/schedules) and `curl` — `scripts/preflight.sh` checks these.
- A scheduler: **launchd** (macOS, automatic via `install.sh`) or **cron** (Linux; `install.sh`
  prints the lines to add). See `templates/cron/crontab.example`.
- Optional `ANTHROPIC_API_KEY` in `~/.outreach-copilot/<slug>/.api-key` as a retry fallback.
