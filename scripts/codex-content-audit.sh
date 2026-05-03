#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v rg >/dev/null 2>&1; then
  echo "codex-content-audit: rg is required" >&2
  exit 2
fi

paths=(
  "$repo_root/dot_codex/AGENTS.md"
  "$repo_root/dot_codex/private_config.toml"
  "$repo_root/dot_codex/rules"
)

patterns=(
  '\[via Claude\]'
  '@rules'
  'mcp__codex__codex'
  '/commit'
  'CronCreate'
  'Monitor\('
  'bd-xxx'
  'bd-[0-9]'
  'bd-[A-Z]'
  '`bd '
  'bd sync'
  'bd ready'
  '~/.claude'
  'CLAUDE\.md'
  'ai-source'
  'rules/claude'
  '—'
)

args=(--hidden --line-number --no-heading)
for pattern in "${patterns[@]}"; do
  args+=(-e "$pattern")
done

if rg "${args[@]}" "${paths[@]}"; then
  echo "codex-content-audit: Claude/generator/bd-specific residue found" >&2
  exit 1
fi

echo "codex-content-audit: ok"
