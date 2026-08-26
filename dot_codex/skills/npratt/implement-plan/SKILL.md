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

1. Read the full plan, including goal, scope, non-goals, documentation,
   decisions, open questions, implementation approach, milestones,
   verification, risks, and progress log.
2. Inspect the `## Milestones` format:
   - For structured plans, each `### Milestone` heading block is one execution
     unit. Track its roll-up checkbox, acceptance criteria, and
     milestone-specific verification together.
   - For legacy flat plans, treat each milestone checkbox as one execution unit.
3. Build the execution checklist from those units. An unchecked open question
   that prevents coherent implementation blocks the affected milestone.
4. Implement milestone by milestone. In a structured milestone, use the files,
   patterns, implementation work, dependencies, gotchas, and boundaries as the
   execution contract.
5. Use subagents only when the user explicitly authorized delegated or parallel
   implementation and write scopes are independent. Subagents write artifacts
   under `.codex/plans/<slug>/`; the lead session updates the top-level plan.
6. Run milestone-specific verification after each meaningful slice when
   practical, and run the final `## Verification` commands before handoff.
7. For a structured milestone, check `Milestone N complete` only after every
   nested acceptance and milestone-verification checkbox passes. Update legacy
   flat checkboxes according to their existing meaning.
8. Update the progress log as the lead session.
9. If blocked, set `State: blocked`, write the blocker, and record the next
   required action.

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

Produce local commits and PR artifacts as needed. Treat branch publication, PR creation, and comments as separate operations governed by the global Remote Operations policy.

## Review Boundary

Treat review as human-gated. After implementation and relevant verification,
ask whether to invoke `$review-branch` before handoff. When the current plan has
a path, pass that path so review artifacts are written under
`.codex/plans/<slug>/`.

`$review-branch` runs a parallel Codex reviewer team and is report-only. Do not
invoke it automatically from this skill unless the user explicitly asks for the
review step. If it runs, record artifact paths or known review state in the
handoff.

Codex also has a built-in review command:

```bash
codex review --uncommitted
codex review --base <branch>
codex review --commit <sha>
```

Use the built-in command only when requested or clearly appropriate. Record
output in plan artifacts. Do not treat it as a replacement for `$review-branch`
when the user asked for the local parallel review workflow.

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

- Keep plan files and artifacts local unless the user explicitly asks otherwise.
- Do not create or use `br` issues as a second source of truth.
