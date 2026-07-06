#!/bin/bash
# Idempotently register the cross-agent MCP server in Claude Code's user config.
#
# ~/.claude.json is runtime state (not chezmoi-managed), so we use `claude mcp add`
# rather than templating the file directly. This script runs after chezmoi applies
# files. chezmoi only re-runs it when the script content changes.

set -euo pipefail

SERVER_NAME="cross-agent"
INSTALL_URL="git+https://github.com/NavarrePratt/cross-agent-mcp[claude]"

# Skip if already configured in ~/.claude.json.
if python3 -c "
import json, sys, os
path = os.path.expanduser('~/.claude.json')
try:
    d = json.load(open(path))
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(1)
sys.exit(0 if '${SERVER_NAME}' in d.get('mcpServers', {}) else 1)
" 2>/dev/null; then
    exit 0
fi

claude mcp add -s user "${SERVER_NAME}" -- uvx --from "${INSTALL_URL}" cross-agent-mcp
