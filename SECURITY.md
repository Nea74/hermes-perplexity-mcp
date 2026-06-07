# Security notes

This bridge controls a real browser session. Treat it as local automation with access to whatever the browser profile can access.

## Network binding

Run the MCP server only on localhost:

```bash
uvicorn mcp_server:app --host 127.0.0.1 --port 3456
```

Do not bind to `0.0.0.0` unless you fully understand the risk and add authentication, firewalling, and network isolation.

## Chrome CDP risk

Chrome DevTools Protocol on port `9222` allows browser automation. Keep it local:

```text
http://localhost:9222
```

Do not expose this port to your LAN or the public internet.

## Never commit local state

These may contain cookies, login state, browsing history, prompts, uploaded files, or account data:

```text
chrome-profile/
chrome-debug-profile/
logs/
downloads/
uploads/
memory.json
.venv/
```

They are intentionally ignored by `.gitignore`.

## Perplexity terms and API usage

This project does not use the Perplexity API and does not require a Perplexity API key. It automates the web UI in a local browser session. Use responsibly and respect Perplexity's terms and rate limits.

## Publishing checklist

Before publishing a fork or release:

```bash
git status --short
git ls-files | grep -Ei 'cookie|profile|history|session|downloads|logs|memory\.json|\.env|auth|token|secret|\.venv' && echo "review tracked files" || echo "tracked files look clean"
```

Also manually review screenshots before committing them.
