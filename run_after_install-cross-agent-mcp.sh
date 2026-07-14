#!/bin/bash
# Idempotently register the cross-agent MCP server in Claude Code's user config.
#
# ~/.claude.json is runtime state (not chezmoi-managed), so we use `claude mcp add`
# rather than templating the file directly. This script runs after chezmoi applies
# files. chezmoi only re-runs it when the script content changes.
#
# Sets a 20-minute (1200000ms) tool execution timeout and selects the generic
# non-interactive read-only OpenCode agent for cross-model calls.

set -euo pipefail

SERVER_NAME="cross-agent"
INSTALL_URL="git+https://github.com/NavarrePratt/cross-agent-mcp[claude]"
TIMEOUT_MS=1200000
AGENT_ENV_KEY="CROSS_AGENT_OPENCODE_AGENT"
AGENT_NAME="cross-agent-readonly"

reconcile_entry() {
    python3 -c "
import json, os
path = os.path.expanduser('~/.claude.json')
with open(path) as f:
    d = json.load(f)
entry = d['mcpServers']['${SERVER_NAME}']
changed = False
if entry.get('timeout') != ${TIMEOUT_MS}:
    entry['timeout'] = ${TIMEOUT_MS}
    changed = True
env = entry.get('env')
if not isinstance(env, dict):
    env = {}
    entry['env'] = env
    changed = True
if env.get('${AGENT_ENV_KEY}') != '${AGENT_NAME}':
    env['${AGENT_ENV_KEY}'] = '${AGENT_NAME}'
    changed = True
if changed:
    with open(path, 'w') as f:
        json.dump(d, f, indent=2)
"
}

# Check if cross-agent is already in ~/.claude.json.
if python3 -c "
import json, sys, os
path = os.path.expanduser('~/.claude.json')
try:
    d = json.load(open(path))
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(1)
sys.exit(0 if '${SERVER_NAME}' in d.get('mcpServers', {}) else 1)
" 2>/dev/null; then
    # Entry exists - reconcile settings in case it was added manually.
    reconcile_entry
    exit 0
fi

# Not present - add it.
claude mcp add -s user "${SERVER_NAME}" -e "${AGENT_ENV_KEY}=${AGENT_NAME}" -- \
    uvx --from "${INSTALL_URL}" cross-agent-mcp

# Ensure the timeout and environment are canonical on the newly created entry.
reconcile_entry
