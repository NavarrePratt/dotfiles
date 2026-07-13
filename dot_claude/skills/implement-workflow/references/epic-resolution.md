# Epic Resolution: Flatten to a Linear Order

Phase 1 of the skill. Resolve the epic ID into ONE strict dependency-ordered
list of leaf bead IDs. The engine runs beads sequentially in a single shared
worktree, so the output is a flat ordered list (`args.beadOrder`), not parallel
waves. This phase runs in the main checkout, before the Phase 2 `cd`, so plain
`br` works (no `--db` needed yet).

## Step 1: Find all descendants of the epic

GOTCHA: `br dep tree` does NOT find children. It walks outgoing dependencies,
but parent-child links are stored child->parent, so querying from the parent
returns nothing. Use the `parent` field from `br show` instead.

```bash
br list --json --limit 0          # all bead IDs
br show <id1> <id2> ... --json    # batch fetch; includes parent, status,
                                  # dependencies, dependents
```

Build the descendant set to a fixed point: start with the epic ID; add any bead
whose `parent` is already in the set; repeat until nothing new is added; then
remove the epic itself.

## Step 2: Intersect with the ready set

```bash
br ready --json --limit 0
```

The executable beads are those in BOTH the descendant set and the ready set
(unblocked, not deferred).

## Step 3: Classify all descendants

From the batch `br show` data:

- `closed` -> already done, exclude
- `in_progress` -> warn (may be claimed by another session), exclude
- in the ready set -> include
- open/deferred but not ready -> blocked (record its blocker for the plan)

## Step 4: Compute blocking-dependency waves

For each executable bead, collect its blockers where `dependency_type ==
"blocks"` that are also descendants and not yet closed (ignore parent-child;
that is structural, not execution ordering). Wave 1 is beads with no open
blockers within the epic; wave N is beads whose blockers are all in earlier
waves. Within a wave, sort by priority ascending. If there are no blocking
dependencies, everything is one wave sorted by priority.

## Step 5: Flatten the waves into a linear order

Concatenate the waves in order, keeping the within-wave priority-ascending sort,
into ONE list of leaf bead IDs. This is **BEAD_ORDER** and becomes
`args.beadOrder`. The wave computation is still worth doing: it produces the
correct topological ordering. Flattening just collapses the parallel structure,
because the engine implements beads one at a time in the shared worktree, each
building on the prior.

## Step 6: Present the plan and confirm

Show the user the ordered plan and the excluded beads:

```
Execution order for epic <EPIC_TITLE> (<EPIC_ID>):
  1. bd-xxx: Title (P1)
  2. bd-yyy: Title (P2)
  ...

Already closed: bd-aaa
In progress (skipped): bd-bbb
Blocked (not ready): bd-ccc (blocked by bd-ddd)
```

Then AskUserQuestion for explicit confirmation:

```
questions: [{
  question: "Implement <N> beads in this order via the workflow engine?",
  header: "Execute plan",
  options: [
    { label: "Proceed", description: "Implement the beads in this order" },
    { label: "Skip some", description: "Select specific beads to implement" },
    { label: "Cancel", description: "Abort without implementing anything" }
  ],
  multiSelect: false
}]
```

- **Proceed**: continue to Phase 2.
- **Skip some**: let the user include/exclude beads, then rebuild the linear
  order from the remaining set (keeping dependency ordering).
- **Cancel**: exit with no changes. No worktree is created and the epic is not
  claimed.

Edge cases: if every descendant is closed, report "nothing to implement" and
exit. If no beads are ready, report the blockers and exit.
