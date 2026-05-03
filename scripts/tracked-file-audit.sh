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
    dot_claude/*|\
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

if (( bad )); then
  exit 1
fi

echo "tracked-file-audit: ok"
