#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
staged_dir="$repo_root/dot_claude"

if [[ ! -d "$staged_dir" ]]; then
  echo "claude-staged-diff: missing staged source: $staged_dir" >&2
  exit 2
fi

if ! git -C "$claude_home" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "claude-staged-diff: not a git checkout: $claude_home" >&2
  exit 2
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/claude-tracked"
git -C "$claude_home" ls-files -z |
  rsync -a --from0 --files-from=- "$claude_home/" "$tmpdir/claude-tracked/"

if git diff --no-index -- "$tmpdir/claude-tracked" "$staged_dir"; then
  echo "claude-staged-diff: staged Claude source matches tracked $claude_home"
fi
