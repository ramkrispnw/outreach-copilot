# Setting up workspace-mcp (the Google backend)

outreach-copilot reaches Gmail / Sheets / Calendar **only** through the Google Workspace MCP
server registered in Claude Code. This is the one piece you must stand up first. The steps below
mirror a known-good **stdio, single-user** setup — the simplest path, and the one that works
cleanly for the unattended jobs (Claude Code launches the server itself per call, so there's **no
persistent HTTP server to keep running** and **no port** to manage).

> Source of truth (versions change — defer to these if a flag differs): taylorwilsdon/google_workspace_mcp.

## 0. Prerequisites for the backend
- **Python 3.10+** and **`uv`/`uvx`** (`brew install uv`, or `pip install uv`).
- A **Google account** (the same one you'll set as `GOOGLE_ACCOUNT`).
- A **Google Cloud project** to hold the OAuth client (free).

## 1. Enable the Google APIs
In that Cloud project, enable the four APIs outreach-copilot uses:
**Gmail API**, **Google Sheets API**, **Google Drive API**, **Google Calendar API**.

## 2. Create an OAuth client (Desktop)
Console → **APIs & Services → Credentials → Create credentials → OAuth client ID**.
- Application type: **Desktop application** (correct for local stdio; no redirect URI needed).
- Set up the **OAuth consent screen** if prompted, and add your Google account under **Test users**
  (so consent works while the app is "in testing").
- Copy the **Client ID** and **Client secret**.

## 3. Register the server with Claude Code (stdio, single-user)
One command — substitute your own client id/secret:
```bash
claude mcp add workspace-mcp -s user \
  -e GOOGLE_OAUTH_CLIENT_ID="YOUR_CLIENT_ID.apps.googleusercontent.com" \
  -e GOOGLE_OAUTH_CLIENT_SECRET="YOUR_CLIENT_SECRET" \
  -e OAUTHLIB_INSECURE_TRANSPORT=1 \
  -e WORKSPACE_MCP_PORT_FALLBACK_COUNT=25 \
  -- uvx --from workspace-mcp workspace-mcp --single-user
```
`WORKSPACE_MCP_PORT_FALLBACK_COUNT=25` widens the OAuth-callback port range to 8000–8024. The
default is just 8000–8004, which can lock up if a few orphaned server instances accumulate (the
runner also reaps orphaned servers before each scheduled run — see below).
Notes:
- `-s user` registers it for **all** your projects (so the headless jobs see it too).
- `--single-user` skips the multi-user OAuth 2.1 server — simplest for one person on one machine.
- `OAUTHLIB_INSECURE_TRANSPORT=1` allows the localhost OAuth callback.
- Don't pass `--read-only` and don't restrict `--tools` to read tiers — the engine needs the
  **write** tools (`send_gmail_message`, `modify_gmail_message_labels`, `modify_sheet_values`,
  `manage_event`/`create_event`, `create_drive_file`). The default tool set includes them.

## 4. Permission the right SCOPES (one-time browser consent)
On the **first authenticated tool call**, your browser opens Google's consent screen. **Approve
every scope it requests** — if you skip the write scopes, the tracker writes / sends will silently
fail. At the capability level you are granting:

| Service | What the engine does | Grant (write, not just read) |
|---------|----------------------|------------------------------|
| **Gmail** | search, read, read attachments, **send**, **manage/modify labels** | Gmail send + modify (not just readonly) |
| **Sheets** | read **and write** cells, formatting | Spreadsheets read **+ write** |
| **Calendar** | read free/busy, **create events** | Calendar read **+ write** |
| **Drive** | create the tracker / docs | Drive file create |

(The server maps these to its internal scope groups — `gmail_send`, `gmail_modify`, `sheets_write`,
`calendar`, `drive_file`, etc. You don't set scope strings by hand; you just approve them at consent.)
The token caches locally after consent, so future calls — including the headless jobs — don't re-prompt.

## 5. Verify
```bash
claude mcp get workspace-mcp     # Status: ✓ Connected, Type: stdio
claude mcp list                  # workspace-mcp listed
```
`scripts/preflight.sh` also checks this. The account you consent with **must match**
`GOOGLE_ACCOUNT` in your campaign config.

## Headless jobs — what's actually required
Because this is **stdio**, the scheduled sweep/sender (`claude --print`) launch the server
themselves each run. You do **not** need to keep a server process alive. You only need:
1. the server **registered at user scope** (step 3),
2. the **OAuth consent completed once** interactively (step 4) so the token is cached, and
3. the jobs running as the **same user** on the **same machine**.

## Troubleshooting
- *"tool not available"* → `claude mcp get workspace-mcp` isn't `✓ Connected`; re-do step 3.
- *Writes/sends fail but reads work* → you didn't approve the write scopes (re-consent; don't use `--read-only`).
- *`ACTION REQUIRED: Google Authentication Needed` in logs* → cached token expired/revoked; run any
  tool interactively once to refresh consent.
- *`No available port in range [8000..8004]; all in use` / server "Failed to connect" while an
  interactive session still works* → orphaned workspace-mcp servers from prior runs are squatting
  the OAuth-callback ports. Clear them: `pkill -f 'workspace-mcp'` (frees the ports; a fresh server
  respawns on next use). Prevent it: set `WORKSPACE_MCP_PORT_FALLBACK_COUNT=25` (above) and note the
  runner already reaps orphaned servers (PPID 1) before each scheduled run. Inspect with
  `lsof -nP -iTCP:8000-8024 -sTCP:LISTEN` and `pgrep -fl workspace-mcp`.
- *Want a hosted/multi-user server instead?* → the project also supports `--transport streamable-http`
  with OAuth 2.1; see the upstream README. For one person, stdio single-user (above) is simplest.

## Sources
- [taylorwilsdon/google_workspace_mcp (GitHub)](https://github.com/taylorwilsdon/google_workspace_mcp)
- [Quick Start — Google Workspace MCP](https://workspacemcp.com/quick-start)
- [workspace-mcp on PyPI](https://pypi.org/project/workspace-mcp/)
