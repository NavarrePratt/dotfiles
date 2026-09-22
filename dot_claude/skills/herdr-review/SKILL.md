---
name: herdr-review
description: Open drafts, files, or Git changes for human review in a Herdr Reviewr pane. Use when the user asks to show something in Herdr or accepts an offer to open a review artifact.
---

# Herdr review

Herdr is the terminal workspace manager hosting agent sessions in tabs and panes.
Reviewr is its read-only file and diff review plugin, `persiyanov.reviewr`.
For general pane control beyond this workflow, read `herdr --skill`.

## Open Reviewr

Check the caller environment with:

```sh
printf 'HERDR_ENV=%s\nHERDR_PANE_ID=%s\n' "${HERDR_ENV:-}" "${HERDR_PANE_ID:-}"
```

macOS `printenv` accepts one variable name; passing both names only prints the first.
Do not infer a missing pane ID from that output or create a spare pane to obtain one.
Use this workflow only when `HERDR_ENV=1` and `HERDR_PANE_ID` is present.
Otherwise, provide the artifact path and explain that this session cannot open a Herdr pane.

Resolve the exact checkout containing the review material. Agents often start at
repository root but work in another worktree; pass that worktree explicitly.
For a draft, use the checkout containing the draft, which may differ from the code worktree.

Set `review_root` to that absolute checkout path, safely quoted, then run:

```sh
herdr plugin pane open --plugin persiyanov.reviewr --entrypoint pane \
  --placement split --direction right --target-pane "$HERDR_PANE_ID" \
  --cwd "$review_root" --no-focus
```

For a specific document, set `review_file` to its absolute path and add the
per-launch environment variable:

```sh
herdr plugin pane open --plugin persiyanov.reviewr --entrypoint pane \
  --placement split --direction right --target-pane "$HERDR_PANE_ID" \
  --cwd "$review_root" --env "HERDR_REVIEWR_OPEN=$review_file" --no-focus
```

The installed personal Reviewr fork opens that file directly in the Files view,
including Git-ignored plans and artifacts. The file must exist inside `review_root`.
Use this direct launch for known files instead of searching or opening a plain-text pager.
The standalone equivalent is `herdr-reviewr "$review_root" --open "$review_file"`.
Fork provenance and rollback are documented in `~/.config/herdr/reviewr.md`.

Keep existing review panes intact: they may contain unsent comments.
Report the checkout and file opened. Confirm selection from the pane output when possible.
Line-number targeting and programmatic commit selection are not implemented;
report the commit SHA for the user to select.

## Guide the review

- Documents: direct opening selects the file in source view; `m` toggles Markdown preview. `2` opens All files. `/` search can still omit ignored files; direct opening does not depend on search indexing.
- Diffs: `u` selects uncommitted work, `b` branch changes, and `g` commit review; `G` opens the commit picker.
- Feedback: `v` selects lines, `c` comments, and `y` copies comments back to chat.
- Copy comments before `q` closes the pane; comments live in memory.

Open when the user asks or accepts an offer. Opening a viewer does not approve
publication or other external writes. Use clipboard feedback unless the user requests sending comments.
