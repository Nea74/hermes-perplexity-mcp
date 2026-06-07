# Troubleshooting

Practical fixes for the Hermes ↔ Perplexity MCP bridge, especially on Windows.

## Quick health checklist

```bash
curl http://127.0.0.1:3456/status
hermes mcp test perplexity-browser
```

A healthy setup shows:

```json
{
  "browser_ready": true,
  "logged_in": true,
  "mode": "CDP (real Chrome)"
}
```

and:

```text
✓ Connected
✓ Tools discovered: 11
```

## `send_message` times out, but Perplexity visibly answered

Check the cached response:

```bash
# Through Hermes/MCP tool if available
get_last_response
```

or call the MCP endpoint directly:

```bash
python - <<'PY'
import json, urllib.request
payload = {
  'jsonrpc': '2.0',
  'id': 1,
  'method': 'tools/call',
  'params': {'name': 'get_last_response', 'arguments': {}}
}
req = urllib.request.Request(
  'http://127.0.0.1:3456/mcp',
  data=json.dumps(payload).encode('utf-8'),
  headers={'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'},
)
print(urllib.request.urlopen(req, timeout=20).read().decode())
PY
```

If the response is present but `send_message` failed with HTTP 500, inspect the server log. On Windows, a common cause is:

```text
UnicodeEncodeError: 'charmap' codec can't encode characters
```

Fix response-file writes by forcing UTF-8:

```python
async with aiofiles.open(DOWNLOADS / fname, "w", encoding="utf-8") as f:
    await f.write(...)
```

## German/localized Windows breaks port cleanup

Do not rely on:

```bat
netstat -ano | findstr LISTENING
```

`LISTENING` is localized on non-English Windows installations. Use PowerShell instead:

```powershell
Get-NetTCPConnection -LocalPort 3456 -State Listen
```

The included `start.bat` uses `Get-NetTCPConnection` to find and stop listeners on ports `3456` and `9222`.

## Hermes sees the MCP server but tools are missing in chat

MCP tool schemas are loaded at session start. After adding or changing an MCP server, start a new Hermes session or run:

```text
/reset
```

Also verify:

```bash
hermes mcp list
hermes mcp test perplexity-browser
```

## Wrong Hermes MCP config path

Do not create or edit a standalone file like:

```text
C:\Users\<YOU>\.hermes_agent\mcp_servers\hermes_mcp_config.json
```

Use Hermes' native config:

```bash
hermes mcp add perplexity-browser --url http://127.0.0.1:3456/mcp
```

The real config lives under Hermes' configured home, commonly:

```text
C:\Users\<YOU>\AppData\Local\hermes\config.yaml
```

## `/sse` vs `/mcp`

The bridge exposes both endpoints, but Hermes native MCP should use JSON-RPC:

```text
http://127.0.0.1:3456/mcp
```

Older config snippets may show SSE:

```text
http://localhost:3456/sse
```

Prefer `/mcp` for Hermes' native MCP client.

## Chrome is open but `browser_ready` is false

Give startup a few seconds, then check:

```bash
curl http://127.0.0.1:3456/status
curl http://127.0.0.1:9222/json/version
```

If CDP is not reachable, restart using `start.bat` and make sure no other Chrome instance is locking the debug profile. The wrapper removes stale `SingletonLock`, `SingletonCookie`, and `SingletonSocket` files from `%USERPROFILE%\chrome-debug-profile`.

## `os.getuid()` crashes on Windows

Windows Python does not provide `os.getuid()`. Any Unix-only user checks must be guarded:

```python
if hasattr(os, "getuid") and os.getuid() == 0:
    ...
```

## Browser profile, cookies, or logs accidentally show up in Git

Do not commit these directories/files:

```text
.venv/
chrome-profile/
chrome-debug-profile/
logs/
downloads/
uploads/*
memory.json
__pycache__/
```

The included `.gitignore` excludes them.

Before pushing, verify:

```bash
git status --short
git ls-files | grep -Ei 'cookie|profile|history|memory\.json|downloads|logs|\.venv' && echo "check these" || echo "clean"
```
