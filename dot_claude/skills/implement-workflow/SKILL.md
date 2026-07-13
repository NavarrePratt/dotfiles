---
name: implement-workflow
description: >
  Implement an epic by burning down its beads with the deterministic
  multi-agent workflow engine: resolve the epic to a linear order, launch the
  implement-workflow Workflow (implement, commit, review, fix), then reconcile
  and draft a PR. Use when you want to implement this epic via the workflow
  engine, burn down the beads with the workflow, or run the deterministic
  implementation pipeline for an epic.
argument-hint: "<epic-id> [branch-name]"
---

# Implement Epic via Workflow Engine

Resolve an epic into a linear execution order, then hand it to the
`implement-workflow` Workflow engine, which implements each bead, groups the
work into self-verifiable commits, runs a multi-lens Codex-validated review,
and folds confirmed fixes back into their commits. This skill owns the ritual
around the engine: preconditions, worktree, epic resolution, args assembly, and
the post-run reconciliation plus PR description. It stops at an approved PR
draft; it never pushes and never creates a PR.

This skill drives the generic engine at `../../workflows/implement-workflow.js`.
The skill is the driver and customization layer; the engine is reusable and
reads its whole configuration from the `args` this skill assembles.

## Reference Files

Load each referenced file with the Read tool before executing its phase.

| Reference | Used in |
|-----------|---------|
| [ritual.md](references/ritual.md) | Phase 0 preconditions and Phase 2 worktree setup |
| [epic-resolution.md](references/epic-resolution.md) | Phase 1 - descendant scan, waves, flatten to a linear order |
| [workflow-launch.md](references/workflow-launch.md) | Phase 3 - verification discovery, lens defaults, args assembly, launch |
| [post-run.md](references/post-run.md) | Phase 4 - ground-truth sanity check, epic status, PR description |
| [../shared/br-in-worktree.md](../shared/br-in-worktree.md) | the `--db` rule for every post-cd `br` call (Phases 0, 2, 3, 4) |
| [../shared/bead-workflow.md](../shared/bead-workflow.md) | the Verification Command Discovery query (Phase 3) |

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current`
- br available: !`which br || echo "br NOT FOUND"`

## Instructions

You are implementing an epic end-to-end through the `implement-workflow` engine.
Work through the phases in order. The heavy lifting (implement, commit, review,
fix) happens inside the engine during Phase 3; the skill's job is to set the
engine up correctly and reconcile its output.

---

### Phase 0: Precondition Checks

Read [ritual.md](references/ritual.md) before executing.

Run the precondition checks from the reference in order, stopping at the first
failure:

1. `br` CLI available
2. Not already inside a worktree
3. Epic ID provided (parse from `$ARGUMENTS`; record **EPIC_ID**)
4. Epic exists (`br show`; record **EPIC_TITLE**)
5. Epic not already `in_progress` (warn and confirm before taking over)
6. No dependency cycles
7. Discover **BASE_REF** (default-branch detection)
8. Derive **MAIN_REPO_BEADS_DB** (with the shell-metacharacter rejection)

---

### Phase 1: Resolve Epic to a Linear Order

Read [epic-resolution.md](references/epic-resolution.md) before executing.

Find the epic's descendants, intersect with the ready set, classify by status,
compute dependency waves, then FLATTEN the waves into ONE strict
dependency-ordered linear list. The engine runs beads sequentially in a single
shared worktree, so there is no intra-epic parallelism - the output of this
phase is a flat ordered list of leaf bead IDs (this becomes `args.beadOrder`).

Present the plan and get explicit confirmation via AskUserQuestion (Proceed /
Skip some / Cancel) before continuing. On Cancel, exit with no changes.

---

### Phase 2: Create Worktree

Read [ritual.md](references/ritual.md) before executing (same reference as
Phase 0; the worktree steps are in its second half).

1. Slugify the branch name (from `$ARGUMENTS` or the epic title)
2. Create the worktree off **BASE_REF** and cd into it
3. Claim the epic `in_progress` with a worktree-path note
4. Create the artifact directory under `/tmp` with the symlink-safe guard

All `br` calls from here on target the main repo database via `--db
"$MAIN_REPO_BEADS_DB"`. See [../shared/br-in-worktree.md](../shared/br-in-worktree.md).

---

### Phase 3: Assemble args and Launch the Workflow

Read [workflow-launch.md](references/workflow-launch.md) before executing.

1. Discover the repo's real build/test/lint (and optional codegen) commands
   using the Verification Command Discovery query from
   [../shared/bead-workflow.md](../shared/bead-workflow.md); these become
   `args.verify`.
2. Apply the lens defaults (correctness, simplicity, testing, security,
   architecture). Set `domainLens` and `designRecordsGlob` only when they apply.
3. Assemble the full `args` object (every field listed in the reference).
4. Invoke the engine:

   ```
   Workflow({ name: "implement-workflow", args })
   ```

5. Eyeball the engine's first log line - the resolved-config guard - to confirm
   the args arrived intact (epic, worktree, base, bead IDs, active lens list)
   before the run goes deep.
6. Wait for the returned report.

---

### Phase 4: Post-Run Reconciliation and PR Description

Read [post-run.md](references/post-run.md) before executing.

1. Ground-truth sanity check IN the worktree (trust git, not the report):
   `git status` clean, `git log --oneline <BASE>..HEAD` matches the reported
   commits, and `args.verify` build/test/lint are green.
2. If the outcome is a CONFORMANCE DIVERGENCE, surface each divergence to the
   user and reconcile FIRST (never auto-fixed; the fix may be a doc edit).
3. Resolve the epic's status (close if every descendant leaf bead is closed,
   else update with notes).
4. Generate the PR title and body from
   [templates/pr-body.md](templates/pr-body.md), save to the artifact directory,
   present, and iterate.

STOP after presenting the approved PR draft. Leave the clean branch, the
worktree, and the draft in place, and tell the user it is ready for them to push
and open the PR themselves.

---

## Error Handling

| Scenario | Recovery |
|----------|----------|
| `br` CLI not installed | Stop with install instructions |
| Already in a worktree | Stop, tell the user to exit first |
| Epic not found | Stop with the verification command |
| Epic already `in_progress` | Warn with claim notes, offer abort or take-over via AskUserQuestion |
| Dependency cycles | Stop with cycle details |
| No ready beads | Report blockers, exit |
| All beads already closed | Report completion, exit |
| Worktree already exists | Offer reuse or abort |
| Branch name already exists | Offer an alternative name or reuse |
| `br` call fails in worktree | Ensure `--db "$MAIN_REPO_BEADS_DB"` is set; see shared/br-in-worktree.md |
| Workflow tool unavailable | Stop; this skill requires the Workflow tool to run the engine |
| Engine throws a missing-arg guard | A required `args` field was empty; fix the assembly in Phase 3 and relaunch |
| Engine reports skipped beads | Surface them; do not close the epic; record what remains in the epic notes |
| Review outcome is CONFORMANCE DIVERGENCE | Reconcile with the user before drafting the PR; never auto-fix |
| Ground-truth check disagrees with the report | Trust git; investigate before drafting the PR |

## Guidelines

- **Engine owns the heavy phases**: implement, commit, review, and fix run inside the Workflow engine, not in this skill. The skill sets it up and reconciles the result.
- **The skill's Workflow call is the documented opt-in**: this skill instructing the agent to call the Workflow tool IS the opt-in for that tool. No separate approval is needed to launch the engine the skill exists to drive.
- **Linear order, not waves**: the engine runs beads sequentially in one shared worktree, so Phase 1 flattens the dependency waves into a single ordered list. Concurrent agents editing one worktree would conflict.
- **Verify args before the run goes deep**: agents never see `args`; the engine interpolates every field into prompt strings and logs the resolved config first. Read that first log line to confirm the config arrived - the cheapest place to catch a bad launch.
- **Conformance is report-only**: the conformance lens (enabled only when `designRecordsGlob` is set) never auto-fixes. A confirmed divergence is reconciled by hand, and the fix may be a doc edit rather than a code edit.
- **Trust git over self-report**: the post-run sanity check reads the actual worktree state. A clean report over a dirty or non-building tree is a report to distrust.
- **The workflow never pushes**: the engine runs only local git (commit, rebase). It never pushes and never creates a PR.
- **Push and PR are out of scope**: this skill stops at an approved PR draft. Pushing the branch and opening the PR are left to the user - never do them here, even after the draft is approved.
- **Epic status tracks completion, not review quality**: close the epic when every descendant leaf bead is closed; record partial progress in the notes otherwise. Review quality lives in the PR description.
- **No bead IDs or counts in PR artifacts**: beads are local-only and counts go stale; the diff shows what changed.

$ARGUMENTS
