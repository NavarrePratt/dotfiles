#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

bad=0
while IFS= read -r path; do
  case "$path" in
    dot_config/dotfiles/local/env.zsh|\
    dot_config/dotfiles/local/teleport.zsh|\
    dot_config/dotfiles/local/*.secret.zsh|\
    dot_config/dotfiles/mcp-servers/dot_env|\
    dot_config/dotfiles/mcp-servers/.env|\
    local/*|\
    dot_codex/auth.json|\
    dot_codex/history.jsonl|\
    dot_codex/installation_id|\
    dot_codex/models_cache.json|\
    dot_codex/cloud-requirements-cache.json|\
    dot_codex/version.json|\
    dot_codex/*.sqlite|\
    dot_codex/*.sqlite-wal|\
    dot_codex/*.sqlite-shm|\
    dot_codex/cache/*|\
    dot_codex/log/*|\
    dot_codex/sessions/*|\
    dot_codex/shell_snapshots/*|\
    dot_codex/.tmp/*|\
    dot_config/opencode/auth.json|\
    dot_config/opencode/.env|\
    dot_config/opencode/*.local.json|\
    dot_config/opencode/*.sqlite|\
    dot_config/opencode/*.sqlite-wal|\
    dot_config/opencode/*.sqlite-shm|\
    dot_config/opencode/cache/*|\
    dot_local/share/opencode/*|\
    dot_local/state/opencode/*|\
    dot_cache/opencode/*|\
    private_dot_claude/*|\
    */.env|\
    *.pem|\
    *.key|\
    *history.jsonl|\
    *.sqlite|\
    *.sqlite-wal|\
    *.sqlite-shm)
      echo "tracked-file-audit: forbidden tracked path: $path" >&2
      bad=1
      ;;
  esac
done < <(git ls-files -co --exclude-standard)

while IFS= read -r path; do
  echo "tracked-file-audit: tracked file is ignored by git excludes: $path" >&2
  bad=1
done < <(git ls-files -ci --exclude-standard)

if (( bad )); then
  exit 1
fi

echo "tracked-file-audit: ok"
