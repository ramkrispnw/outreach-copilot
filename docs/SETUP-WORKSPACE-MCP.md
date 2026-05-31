# Setting up workspace-mcp (the Google backend)

outreach-copilot reaches Gmail / Sheets / Calendar **only** through the Google Workspace MCP
server registered in Claude Code. This is the one piece you must stand up before anything else.
These steps are for the **local** setup that the scheduled jobs need.

> Source of truth (versions change — defer to these if a command differs):
> taylorwilsdon/google_workspace_mcp and its quick-start. Links at the bottom.

## 0. Prerequisites for the backend
- **Python 3.10+** and **`uv`/`uvx`** (`pip install uv` or `brew install uv`).
- A **Google account** (the same one you'll put in `GOOGLE_ACCOUNT`).
- A **Google Cloud project** where you can create OAuth credentials (free).

## 1. Enable the Google APIs
In the Google Cloud Console project you'll use, enable the APIs outreach-copilot touches:
**Gmail API**, **Google Sheets API**, **Google Drive API**, **Google Calendar API**.
(The MCP server supports more; enable at least these four.)

## 2. Create an OAuth client
Console → **APIs & Services → Credentials → Create credentials → OAuth client ID**.
- Application type: **Desktop application** (correct for local CLI / stdio use; no redirect URI to configure).
- Configure the **OAuth consent screen** if prompted; add your Google account as a **Test user** so consent works while the app is in "testing".
- Copy the **Client ID** and **Client secret**, then export them:
  ```bash
  export GOOGLE_OAUTH_CLIENT_ID="your-client-id.apps.googleusercontent.com"
  export GOOGLE_OAUTH_CLIENT_SECRET="your-client-secret"
  ```

## 3. Start the server and register it with Claude Code
```bash
# install + run (default port 8000)
uvx workspace-mcp --transport streamable-http

# in another shell, register it with Claude Code
claude mcp add --transport http workspace-mcp http://localhost:8000/mcp
```

## 4. Complete the one-time OAuth consent
On the **first authenticated tool call**, your browser opens to Google's consent screen — approve
it for the account in `GOOGLE_ACCOUNT`. The token is then cached locally, so future (including
headless) calls don't re-prompt.

Verify:
```bash
claude mcp list                     # should show: workspace-mcp
# or, via the bundled CLI:
workspace-mcp --cli list --json
```
`scripts/preflight.sh` also checks this.

## 5. ⚠️ Make it run for the *unattended* jobs
The daily sweep and the sender run headlessly via `claude --print`. For them to reach the tools:
- The **workspace-mcp server must be reachable when the jobs fire.** If you registered the
  **HTTP** transport above, the `uvx workspace-mcp --transport streamable-http` process must be
  **running persistently** (e.g. a macOS LaunchAgent / login item, `tmux`/`nohup`, or a service).
  If it isn't running at 6am, the sweep can't read your mail.
- Alternatively, register it over **stdio** so Claude Code launches the server itself per call
  (no separate persistent process to babysit) — see the upstream README for the exact stdio
  `claude mcp add` form and how to pass the OAuth env vars. Either way, **complete the OAuth
  consent once interactively first** so the cached token is in place before the jobs run.
- The account you authenticate **must match** `GOOGLE_ACCOUNT` in your campaign config.

## Troubleshooting
- *"tool not available / not registered"* → `claude mcp list` doesn't show workspace-mcp, or the
  HTTP server isn't running. Re-do steps 3–4.
- *Sweep works by hand but not at 6am* → the server isn't running unattended (step 5).
- *Auth prompt in logs* (`ACTION REQUIRED: Google Authentication Needed`) → the cached token
  expired/!revoked; run any tool interactively once to refresh consent.

## Sources
- [taylorwilsdon/google_workspace_mcp (GitHub)](https://github.com/taylorwilsdon/google_workspace_mcp)
- [Quick Start — Google Workspace MCP](https://workspacemcp.com/quick-start)
- [workspace-mcp on PyPI](https://pypi.org/project/workspace-mcp/)
