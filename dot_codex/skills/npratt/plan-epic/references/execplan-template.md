# ExecPlan Format

Use this format whenever `plan-epic` creates or materially updates a plan. A
future implementer must be able to use the plan without the planning
conversation.

## Required Structure

```markdown
# <Plan Title>

## Status

- Owner: unclaimed
- Claim: none
- State: design
- Active worktree: none
- Last updated: YYYY-MM-DD

## Goal

[State the outcome that must be true when the work is complete.]

## Background

[Record current architecture, behavior, constraints, and relevant evidence.]

## Scope

[List included work.]

## Non-goals

[List explicit boundaries.]

## Documentation

[Name documentation changes, including another repository when applicable.]

## Decisions

- [Decision, alternatives considered, and reason.]
- Assumption: [Evidence-backed choice delegated to the planner.]

## Open Questions

- [Only genuinely unresolved decisions. Omit this section when none remain.]

## Implementation Approach

[Describe the technical sequence, integration points, and important constraints.]

## Milestones

### Milestone 1: <Concrete outcome>

- [ ] Milestone 1 complete.

Files and patterns:

- `path/to/file`: [Change and existing pattern to follow.]

Implementation work:

- [Specific work and constraints. Use ordinary bullets, not checkboxes.]

Dependencies:

- [Ordering or prerequisite. Write "None" when explicit.]

Acceptance criteria:

- [ ] [Testable condition.]

Milestone verification:

- [ ] `[exact command]` passes

Gotchas and boundaries:

- [Include only material non-obvious constraints. Omit when empty.]

## Verification

- [ ] `[exact final command]` passes

## Risks

- [Risk and mitigation.]

## Progress Log

- YYYY-MM-DD: Plan created.
```

Write "No separate documentation changes planned" when that is an explicit
decision. Do not leave empty required sections.

## Milestone Contract

Each `### Milestone N: <title>` block is one execution unit.

- Include exactly one roll-up checkbox named `Milestone N complete`.
- Use ordinary bullets for files, patterns, implementation work, dependencies,
  gotchas, and boundaries.
- Use checkboxes for acceptance criteria and milestone-specific verification.
- Check the roll-up only after every nested acceptance and verification checkbox
  passes.
- Keep ordering and dependencies explicit.
- Put the final cross-milestone checks in `## Verification`.

Older plans can use a flat checkbox list under `## Milestones`. Lifecycle skills
remain compatible with that format. New or materially rewritten plans use the
structured milestone format.

## Carry-Forward Requirements

Carry relevant discovery and interview details into the plan. Do not replace
them with a short ticket summary. For each milestone, preserve:

- concrete files and useful anchor locations
- current patterns to follow
- chosen design and rejected material alternatives
- user-visible or operator-visible behavior
- error and recovery behavior
- dependencies and ordering
- scope boundaries
- acceptance criteria
- exact verification commands

Optional artifacts can preserve raw discovery or review output. Copy every
accepted conclusion into the top-level plan.

## Quality Gate

Before handoff, verify that a future implementer can determine:

- which files and existing patterns matter
- what must change and what is out of scope
- how milestones depend on each other
- what completion means for each milestone and the full lifecycle
- which commands verify the work
- which decisions are user-approved and which are evidence-backed assumptions
- whether documentation, rollout, release, or follow-up checks remain

Keep the plan in `State: design` while an open question prevents coherent
implementation. Only explicit user approval changes it to `State: ready`.
