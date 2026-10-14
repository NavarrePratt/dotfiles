#!/bin/sh
# Prints OTLP headers for Claude Code's otelHeadersHelper so the Forge API key
# stays in the shell environment instead of settings.json.
set -eu

if [ -z "${WANDB_API_KEY:-}" ]; then
  echo "agent-lens-otel-headers: WANDB_API_KEY is not set" >&2
  exit 1
fi

printf '{"wandb-api-key": "%s"}\n' "$WANDB_API_KEY"
