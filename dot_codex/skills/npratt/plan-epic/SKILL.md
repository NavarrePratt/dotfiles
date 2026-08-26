---
name: plan-epic
description: Create or refine deep local ExecPlans through repository-first discovery, adaptive user interviews, and bounded cross-model review. Use for architecture changes, migrations, ambiguous multi-stage work, or requests to plan together, plan and review, or investigate and return with a plan. Do not use for small routine tasks or implementation.
---

# Plan Epic

Create or refine one deep local ExecPlan. Keep the plan local and make it
specific enough for a future implementer who cannot see the planning
conversation.

Recommended invocation:

```text
/plan $plan-epic <topic>
```

If built-in Plan mode is unavailable, follow the same workflow in the current
mode.

## Plan Location

Use one top-level Markdown file as the source of truth:

```text
.codex/plans/<slug>.md
```

Optional evidence and review artifacts can use:

```text
.codex/plans/<slug>/
```

Ensure `.codex/plans/` is in the repository's local Git exclude file. Do not add
it to tracked `.gitignore` unless the user explicitly asks to track plans.

## Planning Modes

Infer the mode from the request and conversation. State the inferred mode in
one line. Do not ask the user to select a mode when the intent is clear.

- **Hybrid:** Use when the user wants to plan together or material product,
  scope, operator, or tradeoff decisions remain. This is the default when
  significant user decisions are unresolved.
- **User-only:** Use when the user explicitly excludes external model review or
  asks for decisions to come entirely from the interview. This exclusion takes
  precedence over every review rule.
- **Autonomous:** Use when the user asks Codex to investigate and return with a
  plan, with questions only for genuinely blocking decisions.

Read [modes-and-interview.md](references/modes-and-interview.md) before selecting
the mode or asking planning questions. Re-evaluate the mode after each user
turn so explicit override language applies to future work.

## Workflow

1. Review the full conversation. Record the goal, constraints, decisions,
   technical context, and questions already answered.
2. Read the repository before asking questions. Inspect relevant source, tests,
   configuration, documentation, instructions, history, and verification
   tooling.
3. Follow [modes-and-interview.md](references/modes-and-interview.md) for the
   selected mode. Ask only questions that repository evidence cannot answer
   safely.
4. Discover exact verification commands from project-native task runners,
   package metadata, continuous integration, and documentation.
5. Ask whether separate documentation work is needed when the answer is not
   already clear.
6. Create or update the plan in `State: design` using
   [execplan-template.md](references/execplan-template.md). If the current mode
   cannot write the plan file, ask the user to allow the local write or leave
   that mode. Do not substitute an unwritten draft.
7. In hybrid or autonomous mode, read and follow
   [cross-model-review.md](references/cross-model-review.md). User-only mode
   makes no cross-agent call unless the user explicitly changes the mode.
8. Verify reviewer claims against current repository evidence. Present material
   concerns and decisions to the user in hybrid mode. In autonomous mode,
   incorporate supported findings and report disputed findings at handoff unless
   a decision blocks planning.
9. Carry every accepted conclusion into the top-level plan. Review artifacts
   are evidence, not another source of truth.
10. Leave a new or materially changed plan in `State: design`. Move it to
    `State: ready` only after explicit user approval such as "ready," "looks
    good," "approve the plan," or "start implementation."

Do not implement the planned work as part of this skill.

## Delegation Boundary

Parallel repository exploration requires explicit user authorization. Keep
synthesis, user decisions, and the top-level plan in the lead session.

The single bounded background review worker defined in
[cross-model-review.md](references/cross-model-review.md) is part of the
approved cross-model planning mode and does not require a separate subagent
authorization prompt. It is not permission for exploration fan-out or
additional reviewers.

## Status Contract

Every plan must include:

```markdown
## Status

- Owner: unclaimed
- Claim: none
- State: design
- Active worktree: none
- Last updated: YYYY-MM-DD
```

Allowed states:

- `design`: Requirements or the technical approach are still being shaped.
- `ready`: The user approved the plan for implementation.
- `in_progress`: One implementation session owns the plan.
- `blocked`: A decision, dependency, or failed verification prevents progress.
- `done`: The full project lifecycle is complete.
- `archived`: The plan is retained locally but hidden from active listings.

## Safety

- Keep the ExecPlan as the only planning source of truth. Do not create Beads or
  another work tracker unless the user explicitly asks.
- Preserve explicit user constraints when reviewer advice differs.
- Keep plans and artifacts local unless the user explicitly requests
  publication.
