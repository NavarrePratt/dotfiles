#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$repo_root/scripts/codex-content-audit.sh"
"$repo_root/scripts/claude-content-audit.sh"
"$repo_root/scripts/secret-audit.sh"
"$repo_root/scripts/tracked-file-audit.sh"

if [ -d "$repo_root/dot_config/opencode" ]; then
  while IFS= read -r -d '' json_file; do
    jq empty "$json_file"
  done < <(find "$repo_root/dot_config/opencode" -type f -name '*.json' -print0)
fi
echo "opencode-json-validate: ok"

skill_validator="${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py"
if [ -f "$skill_validator" ] && command -v uv >/dev/null 2>&1; then
  while IFS= read -r -d '' skill_file; do
    skill_dir="${skill_file%/SKILL.md}"
    uv run --with pyyaml python "$skill_validator" "$skill_dir" >/dev/null
  done < <(find "$repo_root/dot_codex/skills/npratt" -mindepth 2 -maxdepth 2 -name SKILL.md -print0)
  echo "codex-skill-validate: ok"
else
  echo "validate: Codex skill validator not available; skipping Codex skill validation" >&2
fi

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
