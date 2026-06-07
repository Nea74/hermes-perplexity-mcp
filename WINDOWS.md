# Windows setup for Hermes ↔ Perplexity MCP Bridge

These notes document a working Windows setup for using Perplexity through Hermes Agent's native MCP client via a real Chrome session and Chrome DevTools Protocol (CDP).

> This is an unofficial field guide. It does **not** use the Perplexity API. It controls the Perplexity web UI in your own browser session.

## What this gives you

- Perplexity inside Hermes as MCP tools
- No Perplexity API key or API credits
- Uses your normal Perplexity/Pro browser login
- Chrome CDP mode on `localhost:9222`
- FastAPI MCP bridge on `127.0.0.1:3456`
- Windows wrapper: `start.bat`

## Prerequisites

- Windows 10/11
- Google Chrome installed, usually:
  `C:\Program Files\Google\Chrome\Application\chrome.exe`
- Python 3.11+
- Hermes Agent installed and available as `hermes`
- Perplexity account logged in through the CDP Chrome profile

## Install dependencies

From Git Bash or another shell in the project root:

```bash
python -m venv .venv
./.venv/Scripts/python.exe -m pip install -r requirements.txt
./.venv/Scripts/python.exe -m playwright install chromium
```

If your Python installation does not provide `pip`, use your normal Python/uv workflow to create the venv and install the requirements.

## Start the bridge on Windows

Use the Windows wrapper:

```bat
C:\path\to\hermes-perplexity-mcp\start.bat
```

From Git Bash:

```bash
cd /c/path/to/hermes-perplexity-mcp
./start.bat
```

The wrapper does the Windows-specific startup sequence:

1. Stops old listeners on ports `3456` and `9222`.
2. Starts Chrome with:
   - `--remote-debugging-port=9222`
   - `--user-data-dir=%USERPROFILE%\chrome-debug-profile`
3. Opens `https://www.perplexity.ai`.
4. Starts the FastAPI MCP server on `127.0.0.1:3456`.

## First login

On first run, Chrome opens with a dedicated debug profile. Sign in to Perplexity there. The login is stored under:

```text
%USERPROFILE%\chrome-debug-profile
```

Do **not** commit this profile. It contains browser session state.

## Verify the bridge

Check server status:

```bash
curl http://127.0.0.1:3456/status
```

Expected shape:

```json
{
  "browser_ready": true,
  "logged_in": true,
  "mode": "CDP (real Chrome)",
  "cdp_url": "http://localhost:9222"
}
```

Check ports with Python:

```bash
python - <<'PY'
import socket
for host, port in [('127.0.0.1', 3456), ('127.0.0.1', 9222)]:
    s = socket.socket(); s.settimeout(2)
    try:
        s.connect((host, port)); print(f'{host}:{port} open')
    except Exception as e:
        print(f'{host}:{port} closed: {e}')
    finally:
        s.close()
PY
```

## Configure Hermes native MCP

Use Hermes' native MCP config command. Do not create a separate `.hermes_agent/hermes_mcp_config.json` file.

```bash
hermes mcp add perplexity-browser --url http://127.0.0.1:3456/mcp
```

When prompted:

- Auth: `n`
- Enable tools: `y`

Then verify:

```bash
hermes mcp test perplexity-browser
```

Expected:

```text
✓ Connected
✓ Tools discovered: 11
```

In an already-running Hermes chat, start a new session or run:

```text
/reset
```

MCP tools are loaded at session start.

## Available Hermes MCP tools

- `send_message`
- `switch_model`
- `upload_file`
- `get_last_response`
- `screenshot`
- `new_chat`
- `list_models`
- `check_login`
- `memory_set`
- `memory_get`
- `memory_delete`

## Security notes

- Keep the MCP server bound to `127.0.0.1`.
- Do not expose Chrome CDP (`9222`) to your LAN or the public internet.
- Never commit browser profiles, cookies, logs, downloads, or `memory.json`.
- Treat CDP access as equivalent to local browser control.

## Known Windows fixes included here

- `start.bat` avoids localized `netstat | findstr LISTENING` parsing and uses PowerShell `Get-NetTCPConnection` for port cleanup.
- `server/mcp_server.py` writes response files with `encoding="utf-8"` so Windows cp1252 cannot crash after a Perplexity answer arrives.
- Windows Chrome paths are handled explicitly.
