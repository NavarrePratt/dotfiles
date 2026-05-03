#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v rg >/dev/null 2>&1; then
  echo "secret-audit: rg is required" >&2
  exit 2
fi

patterns=(
  'xox[a-z]-[A-Za-z0-9/+_=.-]{20,}'
  'glsa_[A-Za-z0-9_=-]{20,}'
  'csa_[A-Za-z0-9_=-]{20,}'
  'gh[pousr]_[A-Za-z0-9_]{30,}'
  'github_pat_[A-Za-z0-9_]{30,}'
  'sk-[A-Za-z0-9_-]{20,}'
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)

args=(
  --hidden
  --line-number
  --no-heading
  --glob '!.git/**'
  --glob '!dot_config/dotfiles/local/env.zsh'
  --glob '!dot_config/dotfiles/local/teleport.zsh'
  --glob '!dot_config/dotfiles/local/*.secret.zsh'
)

for pattern in "${patterns[@]}"; do
  args+=(-e "$pattern")
done

if rg "${args[@]}" "$repo_root"; then
  echo "secret-audit: possible secret material found" >&2
  exit 1
fi

echo "secret-audit: ok"
