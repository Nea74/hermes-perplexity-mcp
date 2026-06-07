# Bridge Commands

Practical command reference for running the Hermes ↔ Perplexity MCP bridge.

This bridge controls Perplexity through a real browser session. It does **not** use the Perplexity API and does not require a Perplexity API key.

---

## 1. Project directory

After cloning the repository:

```bash
cd hermes-perplexity-mcp
```

On Windows with Git Bash, an example path may look like:

```bash
cd /c/Users/YOUR_USER/hermes-perplexity-mcp
```

On Windows Explorer / cmd-style paths, the same directory may look like:

```text
C:\Users\YOUR_USER\hermes-perplexity-mcp
```

Replace `YOUR_USER` with your Windows username.

---

## 2. Start the bridge

### Linux / macOS / WSL-style shell

```bash
./start.sh
```

### Windows

Use the included Windows wrapper:

```bat
start.bat
```

From Git Bash on Windows:

```bash
cd /c/Users/YOUR_USER/hermes-perplexity-mcp
./start.bat
```

The startup sequence launches:

- Chrome with Chrome DevTools Protocol (CDP) on port `9222`
- Perplexity in the browser
- the local MCP/FastAPI bridge on `http://127.0.0.1:3456`

On first run, sign in to Perplexity in the browser window that opens. The login is stored in a local browser profile.

Common profile locations:

```text
~/chrome-debug-profile
```

or on Windows:

```text
%USERPROFILE%\chrome-debug-profile
```

Do not commit browser profiles. They contain browser session state.

---

## 3. Check bridge status

```bash
curl http://127.0.0.1:3456/status
```

A healthy setup should look roughly like this:

```json
{
  "browser_ready": true,
  "logged_in": true,
  "mode": "CDP (real Chrome)",
  "cdp_url": "http://localhost:9222"
}
```

Important fields:

- `browser_ready: true` — the bridge can control the browser
- `logged_in: true` — Perplexity appears to be logged in
- `mode: "CDP (real Chrome)"` — the bridge is attached to a real Chrome session

---

## 4. Configure Hermes native MCP

Use Hermes' native MCP configuration command:

```bash
hermes mcp add perplexity-browser --url http://127.0.0.1:3456/mcp
```

When prompted:

```text
Auth? n
Enable all tools? y
```

Then verify the connection:

```bash
hermes mcp test perplexity-browser
```

Expected result:

```text
✓ Connected
✓ Tools discovered: 11
```

List configured MCP servers:

```bash
hermes mcp list
```

Expected shape:

```text
perplexity-browser  http://127.0.0.1:3456/mcp  enabled
```

If Hermes was already running when you added or changed the MCP server, start a new Hermes session or run this inside Hermes chat:

```text
/reset
```

MCP tools are loaded at session start.

---

## 5. Start Hermes chat

Interactive Hermes chat:

```bash
hermes
```

Single non-interactive query:

```bash
hermes chat -q "Ask Perplexity for the latest information about Hermes MCP."
```

Change model/provider interactively:

```bash
hermes model
```

Start chat with an explicit model:

```bash
hermes chat --model MODEL_NAME
```

---

## 6. How to ask Hermes to use Perplexity

You usually do not need to call MCP tool names directly. Ask naturally:

```text
Ask Perplexity to research the current status of ...
```

```text
Use Perplexity with sources for this question: ...
```

```text
Use Sonar Pro and summarize the latest information about ...
```

```text
Start a new Perplexity chat and ask ...
```

```text
Check whether Perplexity is logged in.
```

```text
Retrieve the last Perplexity response again.
```

```text
Take a screenshot of the Perplexity page.
```

```text
Upload this file to Perplexity and ask it to analyze it: ...
```

---

## 7. Available MCP tools

The bridge exposes these tools to Hermes:

```text
send_message
switch_model
upload_file
get_last_response
screenshot
new_chat
list_models
check_login
memory_set
memory_get
memory_delete
```

What they do:

- `send_message` — send a prompt to Perplexity and return the latest isolated response
- `switch_model` — change the active Perplexity model
- `list_models` — list available Perplexity models and the active model
- `new_chat` — open a fresh Perplexity conversation
- `get_last_response` — retrieve the last response received from Perplexity
- `screenshot` — take a screenshot of the current browser state
- `check_login` — check whether Perplexity appears to be logged in
- `upload_file` — upload a file from the bridge uploads folder into the chat
- `memory_set` — store bridge-side persistent key/value memory
- `memory_get` — retrieve bridge-side persistent memory
- `memory_delete` — delete bridge-side persistent memory

Most users should ask Hermes naturally instead of invoking these tools by name.

---

## 8. Useful Hermes slash commands

Run these inside an interactive Hermes chat session.

Show help:

```text
/help
```

Start a new session and reload startup-time tools:

```text
/reset
```

Reload MCP servers:

```text
/reload-mcp
```

Manage tools:

```text
/tools
```

List toolsets:

```text
/toolsets
```

Show session status:

```text
/status
```

Show or change model:

```text
/model
```

Start a new conversation:

```text
/new
```

Retry the last message:

```text
/retry
```

Undo the last exchange:

```text
/undo
```

Compress context manually:

```text
/compress
```

Show active agents / background tasks:

```text
/agents
```

Exit Hermes:

```text
/quit
```

---

## 9. Typical startup flow

After a reboot or fresh terminal session:

```bash
cd hermes-perplexity-mcp
./start.sh
```

On Windows Git Bash:

```bash
cd /c/Users/YOUR_USER/hermes-perplexity-mcp
./start.bat
```

Check status:

```bash
curl http://127.0.0.1:3456/status
```

Test Hermes MCP integration:

```bash
hermes mcp test perplexity-browser
```

Start Hermes:

```bash
hermes
```

If needed, reload the session inside Hermes:

```text
/reset
```

Then ask naturally:

```text
Use Perplexity with sources to research the current status of ...
```

---

## 10. Troubleshooting

### Hermes does not see the MCP tools

Check the server config and connection:

```bash
hermes mcp list
hermes mcp test perplexity-browser
```

Then in Hermes chat:

```text
/reset
```

or restart Hermes.

### The bridge is not responding

```bash
curl http://127.0.0.1:3456/status
```

If there is no response, start the bridge again:

```bash
cd hermes-perplexity-mcp
./start.sh
```

On Windows:

```bash
cd /c/Users/YOUR_USER/hermes-perplexity-mcp
./start.bat
```

### Perplexity is not logged in

1. Start the bridge.
2. Open `https://www.perplexity.ai` in the Chrome window started by the bridge.
3. Sign in.
4. Check status again:

```bash
curl http://127.0.0.1:3456/status
```

### Perplexity visibly answered, but Hermes timed out

Ask Hermes to retrieve the cached answer:

```text
Retrieve the last Perplexity response again.
```

Or call the bridge tool directly if your client exposes tool calls:

```text
get_last_response
```

---

## 11. Important URLs and ports

Bridge status:

```text
http://127.0.0.1:3456/status
```

Hermes MCP endpoint:

```text
http://127.0.0.1:3456/mcp
```

Legacy / SSE endpoint if used by another client:

```text
http://127.0.0.1:3456/sse
```

Chrome CDP:

```text
http://localhost:9222
```

Perplexity:

```text
https://www.perplexity.ai
```

---

## 12. Security notes

- Keep the MCP bridge bound to `127.0.0.1`.
- Do not expose Chrome CDP port `9222` to your LAN or the public internet.
- Do not commit browser profiles, cookies, logs, downloads, uploaded files, tokens, or `memory.json`.
- Treat CDP access as equivalent to local browser control.
- This project controls your browser session; use it only on machines you trust.
