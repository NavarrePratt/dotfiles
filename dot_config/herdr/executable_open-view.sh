#!/usr/bin/env bash
set -euo pipefail

pane_id="${HERDR_PANE_ID:-}"
if [[ "${1:-}" == --pane ]]; then
  pane_id="${2:?--pane requires a pane ID}"
  shift 2
fi

if [[ $# == 0 || -z "$pane_id" || -z "${HERDR_SOCKET_PATH:-}" ]]; then
  echo 'Usage inside Herdr: open-view.sh [--pane ID] COMMAND [ARG ...]' >&2
  exit 2
fi

herdr_bin="${HERDR_BIN_PATH:-herdr}"
command_text="$(jq -nr --args '$ARGS.positional | @sh' -- "$@")"
new_pane="$("$herdr_bin" pane split --pane "$pane_id" --direction right --no-focus |
  jq -er '.result.pane.pane_id')"

# Replace only the new shell so quitting the viewer also closes its pane.
if ! "$herdr_bin" pane run "$new_pane" "exec $command_text" >/dev/null; then
  "$herdr_bin" pane close "$new_pane" >/dev/null
  exit 1
fi
printf '%s\n' "$new_pane"
