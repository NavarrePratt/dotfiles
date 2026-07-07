# Centralized MCP Servers

Local MCP server management via docker-compose for servers that need
persistent local containers. Slack runs in two local transports: SSE for
Claude and streamable HTTP for Codex and OpenCode. Grafana/observability is
served by a remote MCP server.

## Quick Start

```bash
cd ~/.config/dotfiles/mcp-servers
cp .env.example .env   # Fill in Slack tokens
docker compose up -d
```

## Management

```bash
docker compose up -d                          # Start
docker compose down                           # Stop
docker compose ps                             # Check status
docker compose logs -f slack-mcp              # Tail logs
docker compose logs -f slack-mcp-http         # Tail Codex HTTP logs
docker compose pull && docker compose up -d   # Update images
```

## Token Rotation

1. Edit `.env` with new token values
2. `docker compose restart slack-mcp slack-mcp-http`
3. For `SLACK_MCP_API_KEY` changes: also update the bearer token in Claude MCP
   config (`claude mcp remove --scope user slack` then re-add with new header).
   Codex and OpenCode read the same value from `SLACK_MCP_API_KEY`, so restart
   the shell that launches either client after rotation.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Connection refused | `docker compose ps` - verify the relevant container is running and port is bound |
| Auth errors (401) | Verify `SLACK_MCP_API_KEY` in `.env` matches the Claude MCP `Authorization` header and the Codex/OpenCode shell environment |
| Blank responses | `docker compose logs -f slack-mcp` - look for upstream API errors |
| Cache stale | Remove contents of `data/slack/`, then `docker compose restart slack-mcp slack-mcp-http` |

## Rollback

To stop the shared local Slack MCP services:

```bash
claude mcp remove --scope user slack
docker compose down
```

## Architecture

- **Slack for Claude**: local SSE on `127.0.0.1:3001/sse`, bearer token auth via `SLACK_MCP_API_KEY`, bound to loopback only
- **Slack for Codex and OpenCode**: local streamable HTTP on `127.0.0.1:3003/mcp`, bearer token auth via `SLACK_MCP_API_KEY`, bound to loopback only
- **Grafana/Observability**: remote MCP server (no local container, requires VPN)
