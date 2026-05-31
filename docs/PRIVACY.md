# Privacy & what never gets committed

This tool handles personal data (your account, your prospects, your correspondence). Keep it
out of git and out of anyone else's reach.

## Lives only in your own systems
- **Your data** (prospect shortlist, replies, drafts) lives in **your Google account** — the
  tracker Sheet and your Gmail. Nothing is sent to any third party by this repo.
- **Rendered runtime** (filled prompts, plists, logs) lives in `~/.outreach-copilot/<slug>/`
  on your machine. Logs can contain email content — they're local and gitignored.

## Never committed (enforced by .gitignore)
- `campaigns/*.conf` except the placeholder `example.campaign.conf` — your real configs
  (account, persona, prospect domains, sheet id) stay local.
- Any `*.api-key`, `.env`, `secrets/`, `prospects/*.csv`, and all `*.log`.

## If you fork/publish
- Ship only the **engine + example config**. Never the example filled with real values.
- Double-check no Sheet IDs, account emails, phone numbers, or prospect lists are in committed
  files: `git grep -iE '@gmail|spreadsheets/d/|\\+1[0-9]{10}'` before pushing.

## Sending safety
- Prospects are only ever emailed via a draft you explicitly set to **Approved** (or the one
  outreach email you approve). The agents never cold-send on your behalf.
- Keep your phone number out of replies by leaving `PHONE_DISCRETION=true` (email-only scheduling).
