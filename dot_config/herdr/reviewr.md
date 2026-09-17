# Reviewr trial

Install the pinned trial version:

```sh
herdr plugin install persiyanov/herdr-reviewr --ref v0.38.0 --yes
```

The managed config is `plugins/config/persiyanov.reviewr/config.toml`.
Automatic opening is disabled. Ctrl+B, then d opens a new right split at the focused
pane's directory. Quit with `q` before opening another. Existing panes are not
closed or reused by this shortcut.

For agent-requested review, supply the actual checkout explicitly:

```sh
herdr plugin pane open --plugin persiyanov.reviewr --entrypoint pane \
  --placement split --direction right --target-pane "$HERDR_PANE_ID" \
  --cwd /absolute/path/to/worktree --no-focus
```

A checkout used inside an agent tool call is not necessarily its terminal's cwd.
Do not infer a worktree from the terminal when the task names another checkout.

Use `2` for All files, `/` to search, and `m` for Markdown preview.
Use `g` for committed changes and `G` for the commit picker.
Use `v` to select lines, `c` to comment, and `y` to copy comments back to chat.
Comments are held in memory: copy them before closing the pane.
The plugin also supports `s` to send comments; this trial uses clipboard feedback.

Exact file/line launch targeting and programmatic commit selection remain
unverified. The `herdr-review` skill documents checkout opening and manual target
selection. Plugin binaries and runtime data stay outside this repository.
