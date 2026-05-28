#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

chezmoi --source "$repo_root" diff |
  sed -E \
    -e 's/xox[a-z]-[A-Za-z0-9/+_=.-]{20,}/<redacted-slack-token>/g' \
    -e 's/glsa_[A-Za-z0-9_=-]{20,}/<redacted-grafana-token>/g' \
    -e 's/csa_[A-Za-z0-9_=-]{20,}/<redacted-cloudsmith-key>/g' \
    -e 's/gh[pousr]_[A-Za-z0-9_]{30,}/<redacted-github-token>/g' \
    -e 's/github_pat_[A-Za-z0-9_]{30,}/<redacted-github-token>/g' \
    -e 's/sk-[A-Za-z0-9_-]{20,}/<redacted-api-key>/g' \
    -e 's/AKIA[0-9A-Z]{16}/<redacted-aws-access-key>/g'
