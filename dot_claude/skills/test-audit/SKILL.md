---
name: test-audit
description: Audit tests for low-value, implementation-coupled, or duplicative coverage and the test-only production seams they require, then remove or repair them with evidence. Use when the user asks to audit, prune, sweep, or clean up tests, remove test slop, find brittle or over-mocked tests, or check whether tests earn their place. Also use for an explicitly requested repository-wide or subsystem-wide test sweep. Infer the scope from the request and current session; do not widen it without explicit direction.
---

# Test Audit

A test must justify its maintenance cost. It must protect current observable behavior, a credible regression, or an independent contract. Optimize for confidence, not deletion count.

## Set the Scope

- Infer the scope from the request, current task, changed files, and active modules.
- Keep an implicitly invoked audit within that scope. Loading this skill does not authorize a broader sweep.
- Ask only when a material scope ambiguity cannot be resolved from context.
- Choose the mode:
  - **Focused audit:** one package, module, subsystem slice, or changed-file set. Follow this file.
  - **Sweep:** a whole repository or subsystem that the user explicitly requested. Read [SWEEP.md](SWEEP.md) before you start. This file still defines the bars and evidence for every candidate.

## Read the Repository Contract

Before you judge any test, read the root and scoped `AGENTS.md` or `CLAUDE.md` files and any path-scoped test rules. Repository guidance defines the test layers, contracts, and fixture policy. When it is stricter or more specific than this file, follow the repository.

Find the validation commands in the task runner (`mise`, `make`, `just`, package scripts) and in CI configuration. Note how CI routes tests, such as path filters and build tags.

## Junk Patterns

Look for tests that:

- make no assertion, or only prove that code ran;
- compare a value with itself or with an identity copy;
- copy fixtures, inventories, manifests, or export lists from the source;
- grep source text, imports, or strings;
- test private predicates or call shapes that a real boundary test already covers;
- exercise the same contract more than once across tests or layers;
- replay the tests of a shared helper in each caller;
- exist only to keep test-only exports, globals, wrappers, or injection hooks alive;
- cover dead production code whose only callers are tests;
- compute expected values with the helper or renderer under test;
- use mocks that implement the asserted behavior, or one identical mock for different APIs;
- use fixtures that supply the result, ordering, or callback that the code under test must produce;
- assert persistence against a store that the code path never writes;
- restate declared configuration or capability flags instead of exercising the behavior they promise;
- use negative controls that pass for an unrelated reason, such as a rejection from a different guard;
- have names or fixtures that promise more than the input exercises.

A test that must change for a behavior-preserving refactor is suspect. It is not automatically deletable.

## Retention Bar

Keep a test that independently enforces a public API, CLI, protocol, schema, serialized format, configuration, default, migration, storage, security, platform, generated cross-language, package, or release contract. Also keep:

- call ordering when the order is observable behavior;
- a regression test with a credible failure mode;
- source inspection when it is the cheapest independent guard: it fails when the contract changes and survives an identifier-only refactor.

Static or slow is not a deletion reason. A test that resembles the implementation can still be the only proof of a contract. When the value remains uncertain, keep the test.

A retained test that fails on the baseline is a possible product bug. Reproduce it and report it. Do not delete or weaken it to get a passing run. Fix the product code only when the fix is in scope, and put it in a separate commit.

## Candidate Evidence

Read the complete test and its production owner, entry point, callers, callees, sibling implementations, and overlapping tests. Judge a test by its assertions, not its name. When a test claims dependency behavior, inspect the dependency source or types.

Record these fields for each candidate before you edit. A missing field means the candidate is not ready:

- test name and location;
- the failure that the test can actually detect;
- non-test callers of the production code or seam that it covers;
- the stronger proof that remains at the owner boundary, or why no contract exists;
- relevant history, from `git log` or `git blame`, that explains why the test or seam exists;
- the production or test-support code that the deletion unlocks;
- the risk and the focused validation command.

## Do the Work

1. Establish the baseline with the focused test commands for the scope.
2. For a scope with several independent areas, use read-only scout subagents per area. Combine their evidence before you edit.
3. Report the candidates and their evidence before you edit, unless the user asked for autonomous cleanup.
4. Edit one coherent batch per owner boundary. Merge assertions into existing table cases or stronger suites. Move retained regressions to their owner. Do not add replacement tests that restate the same implementation.
5. Delete test-only exports, wrappers, flags, injection hooks, and dead production paths that only the removed tests required. First check production, dynamic, reflection, and compatibility callers. Do not leave aliases.
6. After each batch, run the focused tests. When you remove a source-grep test, run the executable or dry run that owns the real contract.
7. Run formatting, lint, `git diff --check`, and the feasible broader checks.
8. Update an applicable `AGENTS.md` only when the work reveals a durable convention. Document the current state, not the cleanup history.

Commit with the `git-commit` skill when the user asks. Remote writes follow the global approval rules.

## Report

- the removed categories and why they had no independent value;
- production simplifications;
- retained false positives and why they stay;
- baseline failures and suspected product bugs;
- validation that actually ran, with results;
- remaining uncertainty and follow-ups.

Report production changes separately from test and test-support changes.
