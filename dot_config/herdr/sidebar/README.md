# Sidebar summaries

This personal Herdr plugin publishes session token usage and estimated API cost
to agent sidebar rows. It does not change agent state.

- Agent rows show cumulative tokens for the identified Codex or Claude session.
  This includes repeated input across requests, including cached input. It is
  not context-window occupancy, a dollar charge, or an independently aggregated
  parent-and-child total. Claude subagent transcripts are excluded. `tok ?`
  means no matching session usage is available.
- `~$` is estimated API-equivalent cost using the standard short-context rates in
  `pricing.json`. The rates were checked against OpenAI and Claude pricing on
  2026-10-01. Cached input and cache writes use separate
  rates, and Claude 1-hour cache writes use their own rate. Reasoning is included
  in output. The estimate follows recorded model changes per request. Claude
  Fast mode uses the multiplier in `pricing.json`; Codex Fast mode is excluded.
  The estimate also excludes long-context uplifts, data-residency multipliers,
  tool charges, subscription billing, and child sessions. Unknown models retain
  the token-only display. Restart the worker after editing rates.
  `gpt-reserve` and `codex-auto-review` have no verified published rates and
  retain the token-only display.
- Claude sessions report through the Herdr Claude integration hook in
  `~/.claude/hooks/herdr-agent-state.sh`. Sessions started before the hook was
  installed show no usage until they are resumed.
- Usage refreshes every 15 seconds. Metadata expires after 60 seconds without
  a successful publication.

After applying this directory, register and start the plugin:

```sh
herdr plugin link ~/.config/herdr/sidebar
herdr plugin action invoke npratt.sidebar.start
```

The startup hook starts the worker for future Herdr server sessions. A lock
allows one worker per Herdr socket. It exits when the socket disappears.
Logs and locks live under `~/.local/state/herdr-sidebar`, outside dotfiles.

Preview values without publishing:

```sh
python3 ~/.config/herdr/sidebar/sidebar.py --preview
```

To stop the trial, stop the worker shown by `pgrep -fl 'sidebar.py --watch'`,
unlink the plugin, and remove its `$usage` row token from
source configuration before applying and reloading. Unlinking alone does not
stop an already running worker. Existing metadata expires automatically.
