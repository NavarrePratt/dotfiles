#!/bin/bash
# Idempotently register the Codex MCP server in Claude Code's user config.
#
# ~/.claude.json is runtime state (not chezmoi-managed), so we use `claude mcp add`
# rather than templating the file directly. This script runs after chezmoi applies
# files. chezmoi only re-runs it when the script content changes.
#
# Sets a 10-minute (600000ms) tool execution timeout so Codex agent loops don't
# get killed mid-review.

set -euo pipefail

SERVER_NAME="codex"
TIMEOUT_MS=600000

# Check if codex is already in ~/.claude.json.
if python3 -c "
import json, sys, os
path = os.path.expanduser('~/.claude.json')
try:
    d = json.load(open(path))
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(1)
sys.exit(0 if '${SERVER_NAME}' in d.get('mcpServers', {}) else 1)
" 2>/dev/null; then
    # Entry exists - just ensure the timeout is set (in case it was added manually).
    python3 -c "
import json, os
path = os.path.expanduser('~/.claude.json')
with open(path) as f:
    d = json.load(f)
entry = d['mcpServers']['${SERVER_NAME}']
if entry.get('timeout') != ${TIMEOUT_MS}:
    entry['timeout'] = ${TIMEOUT_MS}
    with open(path, 'w') as f:
        json.dump(d, f, indent=2)
"
    exit 0
fi

# Not present - add it.
claude mcp add -s user "${SERVER_NAME}" -- codex mcp-server

# Set the timeout on the newly created entry.
python3 -c "
import json, os
path = os.path.expanduser('~/.claude.json')
with open(path) as f:
    d = json.load(f)
d['mcpServers']['${SERVER_NAME}']['timeout'] = ${TIMEOUT_MS}
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
"
