---
name: remove-slop-tests
description: Remove low-value tests that mirror implementation, duplicate equivalent coverage, or preserve unnecessary production seams, then simplify affected code. Use when the user wants to clean up test slop, brittle tests, duplicative tests, over-mocked tests, or test-driven complexity. Infer the working scope from the request and current session; do not widen it without explicit direction.
---

# Remove Slop Tests

Tests must justify their presence by protecting distinct, current behavior or a real contract.

## Set the Scope

- Infer the scope from the request, current task, changed files, and active modules.
- Keep an implicitly invoked audit within that scope. Loading this skill does not authorize a broader sweep.
- Ask only when a material scope ambiguity cannot be resolved from context.
- Scale subagents to the work. Use 5-30 for a repository-wide monorepo sweep, but only useful parallelism for focused work.

## Apply the Test Bar

A test is suspect when a behavior-preserving internal refactor forces it to change. Look for tests that restate source structure, duplicate equivalent coverage, assert mocked behavior, or preserve production seams used only by tests.

Keep tests that protect distinct observable behavior. Source shape can be a real contract for protocols, serialized data, schemas, migrations, generated artifacts, CLI output, security boundaries, and compatibility surfaces. When the value remains uncertain, keep the test.

## Do the Work

1. Read the applicable instructions, tests, production code, and nearby coverage. Establish the relevant test baseline.
2. For broad sweeps, partition independent areas among read-only scouts first. Synthesize their evidence before editing, then give workers non-overlapping ownership.
3. Remove high-confidence tests in reviewable batches. Run focused tests after each batch.
4. Find production helpers, exports, abstractions, or injection points that the removed tests alone required. Remove them only after checking production, dynamic, and compatibility callers.
5. Run the relevant focused checks, then the feasible broader checks. Do not preserve test or coverage counts for their own sake.
6. Update an applicable `AGENTS.md` only when the work reveals a durable current convention. Document current state, not the cleanup history.
7. Report what changed, why the remaining tests earn their place, verification results, and unresolved uncertainty.
