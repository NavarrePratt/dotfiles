---
name: plan-epic
description: Create or refine a deep local ExecPlan for a large unit of work under `.codex/plans/`. Use for epic-scale planning, architecture changes, migrations, ambiguous work, or implementation plans that need thorough discovery, user interview, verification planning, ownership metadata, and durable local state before coding.
---

# Plan Epic

Create a local ExecPlan for a larger unit of work. This skill is always deep by default. For small work, use normal Codex conversation or built-in Plan mode without this skill.

Recommended invocation:

```text
/plan $plan-epic <topic>
```

If invoked outside built-in Plan mode, follow the same workflow and ask concise plain-text questions when interactive question tools are unavailable.

## Plan Location

Use one top-level Markdown file as the source of truth:

```text
.codex/plans/<slug>.md
```

If supporting artifacts are useful, create an optional sibling directory:

```text
.codex/plans/<slug>/
```

Use artifacts for notes, investigation logs, review findings, PR drafts, or agent summaries. Link important artifacts from the top-level plan.

Ensure `.codex/plans/` is ignored in the current repo's local Git exclude file, not tracked `.gitignore`, unless the user explicitly asks to track plans.

## Workflow

1. Review the conversation first. Identify the goal, constraints, prior decisions, technical context, and questions already answered. Do not re-ask answered questions.
2. Read the repo before drafting. Inspect relevant source, tests, docs, project instructions, existing patterns, and verification tooling.
3. Explore broadly. If the user explicitly authorized subagents or parallel exploration, split independent exploration questions into concrete subagent tasks. Keep synthesis and user-decision work local to the lead session.
4. Interview the user. Ask targeted, non-obvious questions about requirements, scope, tradeoffs, docs, rollout, ownership, completion criteria, edge cases, assumptions, risks, dependencies, UX or operator experience, and verification.
5. Discover exact verification commands from project-native tooling: task runners, package scripts, CI, docs, or README.
6. Ask whether separate documentation changes are needed, including docs in another repository.
7. Synthesize the plan, then do a technical gap review focused on missing implementation detail, edge cases, dependencies, error handling, tests, rollout, and docs. Do not re-litigate whether the user wants the work.
8. Present material concerns and proposed changes. User decisions win. Document meaningful tradeoffs when reviewer or subagent advice differs from the selected path.
9. Write or update the plan. Keep it local-only.
10. Leave new or materially changed plans in `State: design` by default. Move to `State: ready` only after explicit user approval such as "ready", "looks good", "approve this plan", or "start implementation next".

Do not implement the work as part of this skill.

## Status Block

Every plan must include this block near the top:

```markdown
## Status

- Owner: unclaimed
- Claim: none
- State: design
- Active worktree: none
- Last updated: YYYY-MM-DD
```

Allowed states:

- `design`: requirements or approach are still being shaped.
- `ready`: user approved the plan for implementation.
- `in_progress`: one implementation session owns the plan.
- `blocked`: missing decision, dependency, or failed verification prevents progress.
- `done`: the full project lifecycle is complete, not just local implementation or PR creation.
- `archived`: retained locally for history and hidden from default active listings.

## Template

```markdown
# <Plan Title>

## Status

- Owner: unclaimed
- Claim: none
- State: design
- Active worktree: none
- Last updated: YYYY-MM-DD

## Goal

[What should be true when this plan is complete.]

## Background

[Relevant architecture, existing behavior, constraints, links, and discovered context.]

## Scope

[Included work.]

## Non-goals

[Explicit boundaries.]

## Documentation

[Whether separate docs should be created or edited. Include repo/path hints if known. Write "No documentation changes planned" when that is an explicit decision.]

## Decisions

- [Decision, alternatives considered, and why this path won.]

## Milestones

- [ ] [Milestone 1: concrete implementation outcome.]
- [ ] [Milestone 2: concrete implementation outcome.]
- [ ] [Final verification or lifecycle milestone.]

## Verification

- [ ] `[exact command]` passes

## Risks

- [Risk and mitigation.]

## Progress Log

- YYYY-MM-DD: Plan created.
```

## Quality Bar

Before finishing, verify that a future implementer can tell:

- which files or areas likely need work
- what is explicitly out of scope
- what done means beyond local code changes
- which verification commands matter
- whether docs, rollout, release, or follow-up checks are part of the lifecycle
- which decisions were made and why
