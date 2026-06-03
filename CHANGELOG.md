# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versioning is [SemVer](https://semver.org/).

## [Unreleased]
### Fixed
- **Silent-failure hardening.** The runner now trusts the agent's terminal line (`NOTIFY:`), not the
  `claude --print` exit code — which can be `0` even when the MCP tools never loaded (e.g. a cold-start
  race where workspace-mcp isn't warm yet). Prompts now emit a `RUN_FAILED: <reason>` sentinel on a
  tool/auth outage and ALWAYS emit a terminal line; the runner retries on `RUN_FAILED` or a missing
  terminal line and **always notifies on failure** — so a dropped run can no longer masquerade as a
  quiet "no new replies" day.
- **iMessage reliability.** The notifier now launches Messages first and wraps the send in a 30s
  timeout with one retry, to ride out intermittent AppleEvent timeouts (`-1712`) when Messages is cold
  or busy. (The email digest is always sent regardless, and remains the reliable channel.)

## [0.1.0] - 2026-05-31
Initial public release.

### Added
- Config-driven engine: a daily **reply-sweep** (classify, extract, read attachments, draft replies)
  and an **approve-to-send sender**, around a Google Sheet tracker (Prospects · Replies Log · Drafts).
- **Calendar-aware scheduling** — proposes only free slots, ignores `[Tentative` holds, books the
  call (prospect added as guest) after a confirmation sends.
- **Idempotent sending** — claim-before-send, `Sent Msg ID` terminal, stuck-row detection.
- **Pluggable notifications** — always-on email digest plus optional iMessage/Slack ping; `none` to mute the ping.
- **Configurable frequency** for both jobs (`SWEEP_INTERVAL_HOURS`, `SENDER_INTERVAL_HOURS`).
- **Portability** — launchd (macOS) or cron (Linux); python3-rendered templates (no gettext dependency).
- **`/setup-outreach-campaign` skill** — interview → confirm shortlist size + methodology →
  deep-research the shortlist → build/seed the tracker → send outreach → install jobs.
- **`scripts/init.sh`** interactive wizard with 8 outreach archetypes.
- Docs: README, BACKENDS, SETUP-WORKSPACE-MCP (with exact scopes), NOTIFICATIONS, CALENDAR,
  ARCHITECTURE, PRIVACY, sheet SETUP + Apps Script for the Status dropdown.
- CI (shellcheck + render smoke test + secret guard), CONTRIBUTING, issue templates, MIT license.

[0.1.0]: https://github.com/ramkrispnw/outreach-copilot/releases/tag/v0.1.0
