#!/usr/bin/env bash
# Idempotently install Codex plugins that are enabled in the managed config.
#
# Marketplace checkouts and plugin packages are runtime caches, so chezmoi
# manages the desired config and uses the Codex CLI to materialize the files.

set -euo pipefail

MARKETPLACE_NAME="cw-claude-code-plugins"
MARKETPLACE_SOURCE="coreweave/agent-plugins"
PLUGIN_ID="kynes-guide@${MARKETPLACE_NAME}"

if ! codex plugin marketplace list --json | python3 -c '
import json
import sys

name = sys.argv[1]
data = json.load(sys.stdin)
sys.exit(0 if any(item.get("name") == name for item in data.get("marketplaces", [])) else 1)
' "${MARKETPLACE_NAME}"; then
  codex plugin marketplace add "${MARKETPLACE_SOURCE}" --ref main
fi

if ! codex plugin list --marketplace "${MARKETPLACE_NAME}" --json | python3 -c '
import json
import sys

plugin_id = sys.argv[1]
data = json.load(sys.stdin)
sys.exit(0 if any(item.get("pluginId") == plugin_id for item in data.get("installed", [])) else 1)
' "${PLUGIN_ID}"; then
  codex plugin add "${PLUGIN_ID}"
fi
