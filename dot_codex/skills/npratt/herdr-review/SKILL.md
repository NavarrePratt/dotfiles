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

Keep existing review panes intact: they may contain unsent comments.
Report the checkout and exact file path or commit SHA for the user to select.
The configured viewer does not have a verified direct file/line or commit launch option;
do not claim it selected a target just because the pane opened.

## Guide the review

- Documents: `2` opens All files, `/` searches, and `m` previews Markdown.
- Diffs: `u` selects uncommitted work, `b` branch changes, and `g` commit review; `G` opens the commit picker.
- Feedback: `v` selects lines, `c` comments, and `y` copies comments back to chat.
- Copy comments before `q` closes the pane; comments live in memory.

Open when the user asks or accepts an offer. Opening a viewer does not approve
publication or other external writes. Use clipboard feedback unless the user requests sending comments.
