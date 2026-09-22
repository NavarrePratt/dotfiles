# Reviewr trial

Pinned upstream fallback (installing it replaces the local fork trial):

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

The installed personal fork supports exact-file launch targeting.
Both managed `herdr-review` skills document the direct-opening command.
The local fork trial below records its provenance and installation. File-line launch targeting
and programmatic commit selection remain outside this patch.
Plugin binaries and runtime data stay outside this repository.

## Exact-file fork trial

Status: local fork installed for trial on 2026-09-22. The user confirmed direct
opening of the ignored `.codex/plans/herdr-customization.md` file in Reviewr.
The feature is maintained on the fork's `npratt/direct-file-open` branch.

The fork opens a known file inside Reviewr, including Git-ignored `.codex/plans`
and `.codex/artifacts` files. Agents can supply the full path without relying on
search results or expanding the file tree. The existing Files view handles the
file, its comments, and Markdown preview.

### Provenance

- Fork: https://github.com/NavarrePratt/herdr-reviewr
- Upstream: https://github.com/persiyanov/herdr-reviewr
- Upstream base: `dca1fb88a56c0d6246a2e9004ecbe27fd11a4436` (`v0.38.0`).
- Local checkout: `/Users/npratt/git/herdr-reviewr`.
- Local feature branch: `npratt/direct-file-open`.
- Patch commit: `5da32f25766175efe6333ef7c11f5fe8135f1f42` (Add direct file opening to Reviewr).
- Installed fork revision: `5da32f25766175efe6333ef7c11f5fe8135f1f42`.
- Installed binary SHA-256: `e776832d8dbe9aab3fadbd61eb9a9288ad702e14fea528392ea4ee401eb1404d`.

### Local build and use

```sh
cd /Users/npratt/git/herdr-reviewr
git switch --detach 5da32f25766175efe6333ef7c11f5fe8135f1f42
cargo build --release --locked
./target/release/herdr-reviewr /absolute/path/to/checkout \
  --open /absolute/path/to/checkout/.codex/plans/design.md
```

The argument can also be relative to the checkout root. The file must exist
inside that checkout. Missing files, directories, and paths outside the checkout
produce an error in the TUI. Use the checkout containing the draft, even when
the code under review belongs to another worktree.

The file opens in source view; `m` toggles Markdown preview. Refreshes and tab
switches retain the file. Each launch targets only its new process, so other
viewers and their pending comments stay intact. The patch does not add IPC or
change search indexing.

Agents can use the existing plugin entrypoint with the installed fork:

```sh
herdr plugin pane open --plugin persiyanov.reviewr --entrypoint pane \
  --placement split --direction right --target-pane "$HERDR_PANE_ID" \
  --cwd "$review_root" --env "HERDR_REVIEWR_OPEN=$review_file" --no-focus
```

Set `review_file` to an absolute file path. The environment variable is passed
to that launch only. CLI `--open` takes precedence over the environment variable.
Upstream v0.38.0 ignores this variable. If rolling back, update both managed
`herdr-review` skills to remove direct-opening instructions.

### Verification and installation

Run the fork's checks from its checkout:

```sh
cargo fmt --all --check
cargo clippy --all-targets --all-features -- -D warnings
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=tag.gpgSign GIT_CONFIG_VALUE_0=false \
  cargo test --all-features
uv run scripts/smoke_open_file.py --binary target/release/herdr-reviewr
```

The test-only Git override prevents the user's global tag-signing setting from
changing fixture behavior. The PTY smoke test uses `pyte` to read the actual
terminal screen. It does not open or alter Herdr panes.

Verified on 2026-09-21: formatting, Clippy, the full Rust suite, release build,
and PTY smoke test passed. The suite retains one upstream ignored test.
The direct-file tests cover ignored, untracked, and tracked files; paths with
spaces; refreshes; tab switches; comments; separate viewers; and invalid paths.
Two interleaved baseline/fork benchmark pairs, with five samples per scenario,
showed no consistent slowdown in the existing navigation scenarios. This is a
small local comparison, not a general performance guarantee.

The trial was installed with the `qa-install` recipe directly because `just`
is not installed on this machine:

```sh
cd /Users/npratt/git/herdr-reviewr
cargo build --release --locked
./scripts/qa-install.sh
```

This builds and swaps the binary into the existing `persiyanov.reviewr` plugin,
backs up the upstream binary, and signs the replacement on macOS. Record the
installed patch commit here before using the fork as the normal viewer.
Existing panes keep their old binary; copy pending comments before closing them.
Open a new viewer for a trial. Use explicit `--target-pane` for agent launches;
avoid the workspace-wide plugin open/toggle actions, which follow current focus.

Do not install the fork through `herdr plugin install` yet. Its inherited build
script downloads upstream release binaries, which do not contain this patch.

To restore the backed-up upstream binary:

```sh
cd /Users/npratt/git/herdr-reviewr
./scripts/swap-binary.sh \
  "$HOME/.config/herdr/plugins/github/persiyanov.reviewr-e87b654a74f8/bin/herdr-reviewr.release-backup" \
  "$HOME/.config/herdr/plugins/github/persiyanov.reviewr-e87b654a74f8/bin/herdr-reviewr"
```

Alternatively, reinstall the pinned upstream version with the command at the
start of this document. Close and reopen viewers after restoring the binary.

## Return to upstream

Related upstream work:

- https://github.com/persiyanov/herdr-reviewr/pull/64 proposes CLI navigation.
  Verify ignored-file handling and targeting when several viewers share a checkout.
- https://github.com/persiyanov/herdr-reviewr/issues/17 concerns ignored-file visibility.
  Visibility alone does not satisfy exact-path opening.

Recheck upstream when updating the fork. Return to a pinned upstream release once
it can open a known ignored file in the intended viewer, independently of the
search index, while preserving pending comments. Test with an ignored plan and
two viewers for the same checkout before removing the fork dependency.
