---
name: Bug report
about: Something isn't working
title: "[bug] "
labels: bug
---

**What happened**
A clear description of the bug.

**Expected**
What you expected instead.

**Which part**
- [ ] preflight / setup
- [ ] workspace-mcp connection
- [ ] sweep (reading replies / drafting)
- [ ] sender (sending approved drafts)
- [ ] calendar
- [ ] notifications
- [ ] render / install / scheduling

**Environment**
- OS + scheduler (macOS/launchd, Linux/cron):
- `scripts/preflight.sh` output:
- Relevant log tail from `~/.outreach-copilot/<slug>/*.run.log` (⚠️ redact any email content / personal data first):

**Notes**
Anything else — but **never paste OAuth secrets, account emails, prospect lists, or message bodies.**
