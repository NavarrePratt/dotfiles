# Planning Modes and User Interview

Use this reference whenever `plan-epic` selects a mode, asks planning
questions, or interprets a mode override.

## Discover Before Asking

Read the conversation and repository first. Separate the planning state into:

- verified repository facts
- explicit user decisions and hard constraints
- assumptions supported by evidence
- decisions that only the user can make
- unresolved implementation details that further repository reading can answer

Ask the user only about the fourth category. Do not ask the user to locate code,
recall configuration, name existing patterns, or supply verification commands
that are available in the repository.

## Infer the Mode

### Hybrid

Use hybrid mode when the user asks to plan together or material subjective
decisions remain. Examples include product behavior, operator experience, scope
boundaries, rollout policy, ownership, and acceptable tradeoffs.

Hybrid mode uses repository discovery, an adaptive interview, a local design
plan, cross-model review, and user resolution of material findings.

### User-only

Use user-only mode only when the user explicitly excludes external review or
asks to drive the decisions entirely through the interview.

An explicit exclusion always wins. Do not call a cross-agent tool for a risky
or complex user-only plan. State the review-worthy risk once, record it under
`## Risks`, and offer external review. Change modes only after the user answers
yes.

### Autonomous

Use autonomous mode when the user asks Codex to investigate and return with a
plan or asks not to be interrupted unless a decision truly blocks planning.

Autonomous mode still performs the default cross-model review. It does not pause
for synthesis confirmation or non-blocking findings. Incorporate supported
findings, record assumptions and disputed findings, and return once with:

- the plan path
- the inferred mode
- accepted and disputed review findings
- assumptions
- open decisions

Leave the plan in `State: design` until the user approves it.

## Handle Conflicting Signals

State the inferred mode before interviewing or drafting. If conflicting phrases
would materially change the interaction, ask one targeted mode question.
Otherwise, proceed without a mode-selection prompt.

Re-evaluate the mode after every user turn. An explicit override changes future
work immediately. Preserve completed discovery and accepted plan content.

If the user switches to user-only mode after a review has run, preserve accepted
findings already incorporated into the plan and make no further cross-agent
calls.

## Assess Interview Depth

Use a streamlined interview when the request follows an existing pattern, has
clear boundaries, affects few components, and introduces no sensitive external
dependency. Ask only the remaining material questions.

Use a deeper interview for ambiguous scope, cross-system changes, migrations,
security boundaries, infrastructure, concurrency, performance-critical paths,
or new operator and user experiences.

Depth adapts to unresolved decisions. Do not force a clear task through a fixed
question checklist.

## Conduct the Interview

Use `request_user_input` when it is available. Never set `autoResolutionMs`.
When the tool is unavailable, ask concise numbered questions in plain text and
wait for the response.

- Ask at most three questions in one round.
- Default to at most three rounds.
- Exceed three rounds only when the user is actively adding material decisions.
- Do not re-ask answered questions.
- Prefer non-obvious questions whose answers change scope, behavior, milestones,
  acceptance criteria, rollout, or verification.
- Challenge an assumption only when repository evidence or a concrete risk
  supports the challenge.

Relevant question areas include:

- observable user or operator behavior
- included and excluded scope
- compatibility and migration policy
- external dependencies and ownership
- error and recovery behavior
- rollout, release, and completion criteria
- verification that cannot be inferred from project tooling

## Handle Deferrals and Non-answers

If the user says "you decide" or defers a choice, select the option best
supported by repository evidence. Record it in `## Decisions` as
`Assumption: ...`, cite the evidence, and add material uncertainty to
`## Risks`. Do not ask the same question again.

If a decision remains genuinely unresolved, add it to `## Open Questions` and
leave the plan in `State: design`.

## Synthesize and Stop

In hybrid or user-only mode, summarize the proposed goal, scope, approach,
decisions, assumptions, and remaining uncertainty before the first design
draft. Confirm only interpretations that would materially change the plan.

Stop interviewing when every remaining unknown:

- can be resolved from repository evidence during implementation
- is explicitly deferred and recorded
- does not change scope, decisions, milestones, acceptance criteria, or
  verification

Write the design plan once this condition is satisfied. Do not wait for every
minor implementation detail to be known.
