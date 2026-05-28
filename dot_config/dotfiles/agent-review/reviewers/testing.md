# Testing Reviewer

Evaluate whether the change is adequately verified. Focus on behavior users and operators depend on, not line coverage.

## What To Look For

**Missing behavior coverage**
- New public functions, CLI commands, API endpoints, jobs, or user workflows without tests.
- Changed behavior where existing tests still pass but do not assert the new contract.
- Error handling and fallback paths with no coverage.
- Boundary conditions such as empty input, duplicates, missing files, invalid values, permissions, or timeouts.

**Test quality**
- Tests that assert implementation details rather than behavior.
- Assertions that are too broad to catch regressions.
- Tests with no meaningful assertion.
- Tautological tests that pass even if the code is wrong.
- Excessive mocking that bypasses the behavior under review.

**Test design**
- Negative paths missing for validation, parsing, permissions, and failure handling.
- Shared mutable test state or ordering dependencies.
- Setup so complex it hides the behavior being tested.
- Duplicated setup that should be a helper.

**Testability**
- New code that is difficult to exercise because it is tightly coupled to global state, I/O, or time.
- Functions doing too many unrelated things to test directly.
- Behavior that can only be verified manually when an automated seam already exists.

## How To Review

For each changed behavior, ask:

1. What would a user or operator notice if this broke?
2. Which test would fail for that breakage?
3. Are important bad inputs and failure modes covered?
4. Would these tests survive a reasonable internal refactor?

Recommend tests only when they protect against a specific plausible failure. Do not ask for tests to satisfy a numeric coverage goal.

## Severity Guidance

- **Critical**: Core user-facing behavior or safety-critical behavior is untested and regression-prone.
- **High**: Important error paths, permissions, data integrity, or workflow behavior lacks coverage.
- **Medium**: Missing negative tests, edge cases, or integration checks for plausible failures.
- **Low**: Test clarity, helper extraction, or naming improvements.
