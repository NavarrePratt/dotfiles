# Workflow Launch: Assemble args and Run the Engine

Phase 3 of the skill. Discover the repo's verification commands, pick the review
lenses, assemble the full `args` object, and launch the `implement-workflow`
Workflow engine at `../../../workflows/implement-workflow.js`.

## Step (a): Discover verification commands

Run the Verification Command Discovery query from
[../../shared/bead-workflow.md](../../shared/bead-workflow.md) to find the repo's
real build/test/lint commands (and any codegen step). Map the results into
`args.verify`:

- `build`: the compile/build command (e.g. `mise run build`, `go build ./...`,
  `npm run build`) - also used for the per-commit independent-build check
- `test`: the unit/integration test command
- `lint`: the lint/format-check command
- `generate`: optional codegen (e.g. `mise run gen`, `buf generate`,
  `sqlc generate`) - set only if the repo generates committed source; used to
  regenerate rather than hand-edit generated code, and run before the build
  check

Leave any command empty if the repo has none; the engine skips empty commands
everywhere. Per-bead, the engine prefers each bead's own `## Verification`
section and falls back to these defaults.

## Step (b): Pick the review lenses

Defaults:

- `reviewLenses`: `["correctness", "simplicity", "testing", "security", "architecture"]`
- `briefDir`: `~/.config/dotfiles/agent-review/reviewers` (pass the absolute,
  `~`-expanded path; a lens with no brief file falls back to general expertise,
  so a missing directory is non-fatal)
- `domainLens`: `null`. Set it to a domain name (e.g. a library the whole epic
  is built on) only when that domain has authoritative docs or a skill the
  reviewer should use as its rubric. The engine appends it as an extra lens with
  no brief.
- `designRecordsGlob`: `null`. Set it to a glob of decision/design records (e.g.
  `docs/<area>/decisions/*.md`) ONLY when the user names such a location.
  Setting it ENABLES the report-only conformance lens; leaving it null omits
  that lens entirely.

## Step (c): Assemble the args object

Build the object from the values recorded across Phases 0-2 plus the choices
above. Every field:

```
args = {
  epicId:            <EPIC_ID>,              // Phase 0
  epicTitle:         <EPIC_TITLE>,           // Phase 0 (optional, for logs)
  beadsDb:           <MAIN_REPO_BEADS_DB>,   // Phase 0
  worktree:          <WORKTREE>,             // Phase 2 (absolute)
  baseRef:           <BASE_REF>,             // Phase 0
  beadOrder:         <BEAD_ORDER>,           // Phase 1 (flat ordered array)
  reviewLenses:      ["correctness", "simplicity", "testing", "security", "architecture"],
  briefDir:          "<absolute path to reviewer briefs>",
  verify:            { build: "...", test: "...", lint: "...", generate: "..." },
  domainLens:        null,                   // or a domain name
  designRecordsGlob: null,                   // or "docs/<area>/decisions/*.md"
}
```

The engine's guard requires `epicId`, `beadsDb`, `worktree`, `baseRef`,
`beadOrder`, `reviewLenses`, `briefDir`, and `verify`; `beadOrder` must be a
non-empty array. Omit or null `epicTitle`, `domainLens`, and `designRecordsGlob`
when they do not apply.

## Step (d): Launch the engine

```
Workflow({ name: "implement-workflow", args })
```

The skill instructing this call IS the documented opt-in for the Workflow tool.
The engine implements each bead, commits, reviews, and fixes - all local, never
pushing.

Immediately eyeball the engine's FIRST log line, the resolved-config guard:

```
implement-workflow config resolved:
  epic:     <EPIC_ID> (<EPIC_TITLE>)
  worktree: <WORKTREE>
  base:     <BASE_REF>
  beads:    <BEAD_ORDER joined>
  lenses:   <active lens list, incl domain/conformance when set>
  verify:   build=... test=... lint=... generate=...
```

If any field there is empty, wrong, or shows `(skip)` where you expected a
command, stop and fix the args assembly before the run goes deep - this is the
cheapest place to catch a bad launch. If the engine throws
`implement-workflow: missing args.<key>`, a required field was empty; fix it and
relaunch.

## Step (e): Wait for the report

Wait for the Workflow to return its structured report (epic, beads done/skipped,
bead summaries, commits, review outcome and findings, fixes, discoveries). Carry
it into Phase 4.
