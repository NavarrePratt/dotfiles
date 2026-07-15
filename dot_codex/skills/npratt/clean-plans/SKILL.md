---
name: clean-plans
description: Interactively review and clean archived local ExecPlans under `.codex/plans/archive/`. Use when the user asks to clean, sweep, prune, or review archived plans and supporting artifacts while preserving anything uncertain.
---

# Clean Plans

Interactively review archived local ExecPlans and artifacts.

Archive location:

```text
.codex/plans/archive/
```

## Workflow

1. Inspect `.codex/plans/archive/`.
2. Summarize archived top-level plans and any matching artifact directories.
3. Identify candidates that look safe to remove, such as old scratch artifacts with no apparent future value.
4. Ask before deleting, moving, or rewriting anything.
5. Preserve anything uncertain, recently useful, manually marked to keep, or tied to unresolved lifecycle questions.

## Safety

- Operate only on archived repository-local plan state and artifacts.
- Never delete active plans outside `.codex/plans/archive/`.
- Never delete dirty worktrees.
- Never remove a plan or artifact directory without showing what will be removed and getting explicit approval.
- Prefer preserving over deleting when context is unclear.

## Output

Report:

- archived plans found
- artifact directories found
- items kept
- items removed, only after approval
- anything that needs human review later
