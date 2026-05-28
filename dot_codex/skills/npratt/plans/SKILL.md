---
name: plans
description: List, inspect, summarize, and lightly manage local ExecPlans under `.codex/plans/`. Use when the user asks what plans exist, what is ready, what is in progress, what is blocked, or wants to claim, release, archive, or inspect local plan state.
---

# Local Plans

Work with local ExecPlans stored under:

```text
.codex/plans/
```

The canonical plan is always a top-level Markdown file:

```text
.codex/plans/<slug>.md
```

An optional sibling artifact directory may exist:

```text
.codex/plans/<slug>/
```

## Default Listing

By default, show only active plans:

- `ready`
- `in_progress`
- `blocked`
- `design`

Hide `done` and `archived` unless the user asks for them.

For each visible plan, show a concise row with:

- state
- owner
- last updated date
- title
- plan path
- active worktree

Sort or group by state, then title or updated date.

## Parsing

Read top-level `*.md` files in `.codex/plans/`, excluding files under `.codex/plans/archive/` unless archive output was requested.

Parse this status block:

```markdown
## Status

- Owner: ...
- Claim: ...
- State: ...
- Active worktree: ...
- Last updated: ...
```

If a plan is missing fields, report it as malformed and suggest a repair. Do not rewrite it unless the user asks.

## In-Progress Health Check

For `in_progress` plans, do a light read-only health check:

- whether the active worktree path exists
- `git -C <worktree> status --branch --short` when the worktree exists
- whether the progress log has a recent signal
- whether the claim appears stale from timestamp, missing worktree, or no progress

Do not take over or release a claim without explicit user approval.

## Mutations

This skill is read-only unless the user explicitly asks to mutate plan state.

Allowed mutations after approval:

- claim a plan
- release a plan
- mark a plan blocked with a reason
- move a plan from `design` to `ready`
- archive a completed plan
- repair missing status metadata

Never delete plans from this skill. Use `$clean-plans` for archive cleanup.

## Safety

- Keep plans local-only.
- Do not push, create PRs, post comments, or perform GitHub writes.
- Do not mark a plan `done` just because local code was written or a PR was opened.
- When unsure whether a plan is complete, leave it active and record the next required step.
