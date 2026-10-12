#!/usr/bin/env bash
# Idempotently install the GitHub CLI stack extension used by the gh-stack skill.
#
# gh stores extensions in its own data directory, which is runtime state, so
# chezmoi uses the gh CLI to install the extension instead of managing files.

set -euo pipefail

EXTENSION="github/gh-stack"

if ! gh extension list | cut -f2 | grep -qx "${EXTENSION}"; then
  gh extension install "${EXTENSION}"
fi
