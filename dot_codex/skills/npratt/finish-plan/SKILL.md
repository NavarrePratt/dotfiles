---
name: finish-plan
description: Verify that a local ExecPlan has completed its full lifecycle, then mark it done, archive it, and optionally clean up project-local worktrees. Use when the user asks to finish, close, complete, mark done, archive, or clean up a local ExecPlan after the work is complete.
---

# Finish Plan

Close a local ExecPlan only after its project-specific lifecycle is genuinely complete. Local implementation, passing local verification, or opening a PR is not enough when review, merge, CI, deploy, release, rollout validation, documentation, or follow-up checks are still pending.

## Inputs

Accept:

- an explicit `.codex/plans/<slug>.md` path
- a `<slug>` that resolves to `.codex/plans/<slug>.md`
- no plan, in which case list likely active candidates and ask which one to finish

Prefer `in_progress` and `blocked` candidates over `ready` or `design`. The canonical plan is the top-level Markdown file. Optional supporting artifacts may live in `.codex/plans/<slug>/`.

## State Gates

Read the `## Status` block before mutating anything:

- `design`: refuse to finish by default. Ask only if the user explicitly wants to abandon or archive a design plan.
- `ready`: refuse by default because implementation has not started.
- `in_progress`: inspect lifecycle state and continue.
- `blocked`: inspect the blocker and ask whether it has been resolved before continuing.
- `done`: offer to archive if the plan is still under `.codex/plans/`.
- `archived`: report that it is already archived and do not mutate by default.

If the status block is malformed, report the missing fields and ask before repair.

## Lifecycle Verification

Read the full plan, including goal, scope, non-goals, decisions, documentation, milestones, verification, risks, and progress log. Inspect `.codex/plans/<slug>/` if it exists.

Build a checklist from the plan content:

- milestone checkboxes
- verification commands and their latest known results
- documentation decisions
- PR, review, CI, release, deploy, rollout, or follow-up references
- explicit remaining lifecycle steps recorded during handoff
- artifacts such as PR drafts, review output, or summaries

Inspect local state:

```bash
git status --branch --short
git worktree list
```

For each candidate worktree from `Active worktree` or `.codex/worktrees/<slug>`:

```bash
git -C <worktree> status --branch --short
```

Use read-only GitHub checks when the plan references GitHub lifecycle state such as PR merge status, checks, workflow runs, releases, tags, or deployments. Prefer the GitHub app, GitHub skills, `gh` reads, or API reads already available in the environment. Do not change remote state from this skill.

Treat unchecked milestones, missing verification, unresolved documentation, open follow-ups, unmerged PRs, pending CI, pending deploy, pending release, or pending rollout validation as incomplete unless the user explicitly explains why they no longer apply. Ask targeted questions for lifecycle facts that cannot be proven locally or through allowed read-only checks.

Explicit user confirmation is valid evidence when a lifecycle fact cannot be verified programmatically. Record the confirmation in the plan progress log before archiving.

## Incomplete Plans

If lifecycle work remains, report the remaining steps and ask before changing the state to `blocked`.

When blocking, update:

```markdown
- State: blocked
- Last updated: YYYY-MM-DD
```

Add a progress log entry with the blocker and the next required action. Do not archive incomplete plans.

## Completion

When lifecycle completion is established, update the active plan before moving it:

```markdown
- State: done
- Last updated: YYYY-MM-DD
```

Add a progress log entry with the evidence used to decide completion and any worktree cleanup decision.

Archived completed plans keep `State: done`; the archive path hides them from active listings.

## Archive

Archive only from the active plan path:

1. Resolve `<slug>` from `.codex/plans/<slug>.md`.
2. Ensure `.codex/plans/archive/` exists.
3. Check for collisions at `.codex/plans/archive/<slug>.md` and `.codex/plans/archive/<slug>/`.
4. Stop and ask if either destination exists. Do not overwrite or invent a new destination automatically.
5. Move `.codex/plans/<slug>.md` to `.codex/plans/archive/<slug>.md`.
6. If `.codex/plans/<slug>/` exists, move it to `.codex/plans/archive/<slug>/`.
7. Report the archived paths.

Use normal local filesystem moves only after the collision checks pass.

## Worktree Cleanup

Use the `$worktree` safety model. Determine candidates from `Active worktree` and `.codex/worktrees/<slug>`, then inspect before removal:

```bash
git worktree list
git -C <worktree> status --branch --short
```

For clean worktrees, show the path and ask before:

```bash
git worktree remove <worktree>
```

For dirty worktrees, show the status and ask whether removal is allowed for that specific worktree. Never remove a dirty worktree silently.

If cleanup is declined or deferred, leave `Active worktree` pointing to the preserved path and record the decision in the progress log. Prefer recording cleanup before archive; if cleanup happens after archive, update the archived plan explicitly.

## Output

Report:

- plan path and final state
- archived plan and artifact paths, if any
- completed lifecycle evidence
- worktree cleanup results or deferred cleanup
- any remaining manual follow-up

## Safety

- Keep plans and artifacts local-only.
- Do not create a second source of truth in `br`.
- Prefer asking over inferring completion. Missing lifecycle information keeps the plan active.
