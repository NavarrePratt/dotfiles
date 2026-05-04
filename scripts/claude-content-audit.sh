#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

bad=0

while IFS= read -r path; do
  case "$path" in
    private_dot_claude/*|\
    dot_claude/.claude/*|\
    dot_claude/.atari/*|\
    dot_claude/.beads/*|\
    dot_claude/agent-memory/*|\
    dot_claude/agent-memory-local/*|\
    dot_claude/backups/*|\
    dot_claude/cache/*|\
    dot_claude/debug/*|\
    dot_claude/downloads/*|\
    dot_claude/file-history/*|\
    dot_claude/ide/*|\
    dot_claude/image-cache/*|\
    dot_claude/paste-cache/*|\
    dot_claude/plans/*|\
    dot_claude/plugins/*|\
    dot_claude/projects/*|\
    dot_claude/session-env/*|\
    dot_claude/sessions/*|\
    dot_claude/shell-snapshots/*|\
    dot_claude/statsig/*|\
    dot_claude/tasks/*|\
    dot_claude/teams/*|\
    dot_claude/telemetry/*|\
    dot_claude/todos/*|\
    dot_claude/usage-data/*|\
    dot_claude/history.jsonl|\
    dot_claude/policy-limits.json|\
    dot_claude/stats-cache.json|\
    dot_claude/mcp-needs-auth-cache.json|\
    dot_claude/.credentials.json|\
    dot_claude/.claude.json|\
    dot_claude/mcp-servers/.env|\
    dot_claude/*.local.json|\
    dot_claude/*.local.md|\
    dot_claude/skills/ask-o11yops/*)
      echo "claude-content-audit: forbidden tracked Claude path: $path" >&2
      bad=1
      ;;
  esac
done < <(git ls-files -co --exclude-standard)

if (( bad )); then
  exit 1
fi

echo "claude-content-audit: ok"
