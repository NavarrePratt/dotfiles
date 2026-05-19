---
name: implement-plan
description: Execute an approved local ExecPlan from `.codex/plans/` through milestone implementation, project-local worktree setup, verification, plan updates, and local handoff artifacts. Use when the user asks to implement, execute, or work through an existing plan without automatically pushing or creating PRs.
---

# Implement Plan

Execute an approved local ExecPlan. This skill is interactive and human-gated. Do not wrap it in `/goal`; implementation has review, PR, publication, and lifecycle decisions that require user control.

## Inputs

Accept an explicit plan path when provided:

```text
.codex/plans/<slug>.md
```

If no path is provided, list likely `ready` plans and ask which one to implement.

## State Gates

Read the `## Status` block before making changes:

- `ready`: proceed after normal confirmation and claim.
- `design`: stop and ask for explicit approval before implementation.
- `blocked`: stop and explain the blocker.
- `in_progress`: inspect the claim and active worktree, then ask before continuing or taking over.
- `done` or `archived`: refuse unless the user explicitly asks to reopen.

## Claim

Before implementation, claim the plan by updating:

```markdown
- Owner: codex
- Claim: <timestamp> session=<session-id-or-short-note>
- State: in_progress
- Active worktree: .codex/worktrees/<slug>
- Last updated: YYYY-MM-DD
```

Use an available Codex session ID when known. If not available, use a short human-readable session note.

## Worktree

Use the project-local worktree pattern from `$worktree`:

```text
.codex/worktrees/<slug>/
```

Add `.codex/worktrees/` only to the local Git exclude file. Do not create sibling worktrees under `~/git` unless the user explicitly asks.

If the worktree path exists, inspect it and ask before reuse. Do not overwrite, delete, or move it automatically.

## Execution

1. Read the full plan, including goal, scope, non-goals, decisions, milestones, verification, risks, documentation, and progress log.
2. Build an execution checklist from `## Milestones`.
3. Implement milestone by milestone.
4. Use subagents only when the user explicitly authorized delegated or parallel implementation and write scopes are independent. Subagents write artifacts under `.codex/plans/<slug>/`; the lead session updates the top-level plan.
5. Run relevant verification commands from the plan after each meaningful slice when practical, and run final verification before handoff.
6. Update milestone checkboxes and the progress log as the lead session.
7. If blocked, set `State: blocked`, write the blocker, and record the next required action.

## Artifacts

Use the optional artifact directory for supporting files:

```text
.codex/plans/<slug>/
```

Useful artifacts:

- milestone summaries
- investigation notes
- review output
- `pr-title.txt`
- `pr-body.md`

Local PR artifacts are useful, but do not push or create a PR without explicit approval.

## Review Boundary

Treat review as human-gated in this first version.

Codex has a built-in review command:

```bash
codex review --uncommitted
codex review --base <branch>
codex review --commit <sha>
```

Use it only when requested or clearly appropriate. Record output in plan artifacts. Do not treat it as a replacement for a future multi-reviewer workflow.

## Handoff

At handoff, report:

- plan path
- state
- active worktree
- branch
- completed milestones
- verification results
- PR artifact paths, if any
- known review state
- PR URL, if one already exists
- remaining lifecycle steps before `done`

Do not mark a plan `done` just because local implementation finished or a PR was opened. Leave it `in_progress` or `blocked` until the project-specific lifecycle is complete.

When implementation is handed off through a PR or another review path, suggest `$finish-plan .codex/plans/<slug>.md` as the next lifecycle tool after merge, CI, deploy, release, rollout validation, documentation, or other recorded completion checks are done. Do not invoke `$finish-plan` automatically unless the user explicitly asks to finish the plan and the lifecycle evidence is already available.

Do not archive from this skill unless the user explicitly confirms the lifecycle is complete.

## Safety

- Never push, create PRs, post comments, submit Git-Spice branches, or perform GitHub writes without explicit approval.
- Before any remote write, show exactly what will happen and wait for approval.
- Keep plan files and artifacts local unless the user explicitly asks otherwise.
- Do not create or use `br` issues as a second source of truth.
