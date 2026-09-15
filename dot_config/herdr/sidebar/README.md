# Sidebar summaries

This personal Herdr plugin publishes session token usage and estimated API cost
to agent sidebar rows. It does not change agent state.

- Agent rows show cumulative tokens reported by the identified Codex session.
  This includes repeated input across requests, including cached input. It is
  not context-window occupancy, a dollar charge, or an independently aggregated
  parent-and-child total. `tok ?` means no matching session usage is available.
- `~$` is estimated API-equivalent cost using the standard short-context rates in
  `pricing.json`, checked against OpenAI pricing on 2026-09-15. Cached input and
  cache writes use separate rates; reasoning is included in output. The estimate
  follows recorded model changes. It excludes Fast mode, long-context uplifts,
  tool charges, subscription billing, and independently aggregated child sessions.
  Unknown models retain the token-only display. Restart the worker after editing rates.
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
