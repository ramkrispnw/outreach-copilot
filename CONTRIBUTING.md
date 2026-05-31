# Contributing to outreach-copilot

Thanks for your interest! This is a small, config-driven tool — contributions that keep it simple
and portable are very welcome.

## Ground rules
- **Never commit personal data or secrets.** No real OAuth client IDs/secrets, account emails,
  spreadsheet IDs, prospect lists, or logs. The only campaign config in git is
  `campaigns/example.campaign.conf` (placeholders only). See [docs/PRIVACY.md](docs/PRIVACY.md).
- **Keep it dependency-light.** Bash + `python3` (for rendering) + standard CLI tools. Don't add a
  runtime that users must install unless there's a strong reason.
- **Portability first.** Anything macOS-only (launchd, iMessage) needs a documented non-macOS path
  (cron, email/Slack).

## Project shape
- `templates/*.tmpl` — generic prompts + schedules; `scripts/render.sh` fills them from config.
- `engine/` — the headless runner + notifier.
- `scripts/` — init / render / install / uninstall / preflight.
- `skill/` — the Claude Code setup skill. `docs/` — setup & design docs.
- Campaign-specific values live in `campaigns/<slug>.conf` only — never hardcode them in the engine.

## Before you open a PR
Run the same checks CI runs:
```bash
for f in scripts/*.sh engine/run-agent.sh engine/lib/notify.sh; do bash -n "$f"; done
shellcheck -S error scripts/*.sh engine/run-agent.sh engine/lib/notify.sh
# render smoke test
cp campaigns/example.campaign.conf campaigns/_dev.conf
OUTREACH_HOME=/tmp/oc-dev scripts/render.sh _dev && grep -r '${' /tmp/oc-dev/_dev/ || echo "no leftover placeholders"
rm -f campaigns/_dev.conf; rm -rf /tmp/oc-dev
```
- If you add a config field, update **all four**: `campaigns/example.campaign.conf`,
  the relevant `templates/*.tmpl`, the `OC_VARS` allowlist in `scripts/render.sh`, and `scripts/init.sh`.
- If you change behavior, update the matching doc in `docs/` and the `CHANGELOG.md`.

## Reporting issues
Use the issue templates. For setup problems, include `scripts/preflight.sh` output and the relevant
`~/.outreach-copilot/<slug>/*.run.log` tail (redact any personal content first).

By contributing you agree your work is licensed under the repo's [MIT License](LICENSE).
