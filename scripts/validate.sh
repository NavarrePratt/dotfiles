#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$repo_root/scripts/codex-content-audit.sh"
"$repo_root/scripts/secret-audit.sh"
"$repo_root/scripts/tracked-file-audit.sh"

zsh -n "$repo_root/dot_zshrc"
find "$repo_root/dot_config/dotfiles/shell" -type f -name '*.zsh' -print0 |
  xargs -0 -n 1 zsh -n

if command -v chezmoi >/dev/null 2>&1; then
  chezmoi --source "$repo_root" doctor
  chezmoi --source "$repo_root" diff >/dev/null
  echo "chezmoi diff: ok"
else
  echo "validate: chezmoi not installed; skipping chezmoi doctor/diff" >&2
fi

echo "validate: ok"
