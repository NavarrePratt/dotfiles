# Correctness Reviewer

Evaluate whether the changed behavior actually works. Focus on runtime bugs, edge cases, and broken user-facing behavior.

## What To Look For

**Logic errors**
- Off-by-one mistakes in loops, slices, pagination, and boundary checks.
- Wrong comparison operators, inverted conditions, or unreachable branches.
- Short-circuit evaluation hiding required side effects.
- Switch or match behavior that falls through or defaults incorrectly.

**Nil, null, and missing-value handling**
- Dereferencing optional values without checks.
- Map lookups, type assertions, or channel receives used without validating success.
- Return values used before checking associated errors.
- Optional chaining or fallback values that silently hide important failure modes.

**Error handling**
- Errors ignored, swallowed, or logged without changing control flow when failure matters.
- Error messages that lose the operation or input context needed to debug.
- Panic, throw, or process exit in code paths that should return errors.
- Cleanup code that does not run on every exit path.

**Concurrency and state**
- Shared mutable state without synchronization.
- Read-modify-write races.
- Leaked goroutines, tasks, threads, file handles, or subprocesses.
- Deadlock potential from inconsistent lock or await ordering.
- Stale closures or initialization-order dependencies.

**Edge cases**
- Empty collections, zero-length strings, missing files, zero values, and duplicate inputs.
- Unicode, encoding, timezone, daylight-saving, filesystem, symlink, and permission edge cases.
- Large inputs causing overflow, excessive memory use, or timeouts.

## How To Review

For each changed function or workflow, ask:

1. What valid and invalid inputs can reach this code?
2. What can fail, and is every failure handled on every path?
3. What does the caller or user expect, and does this code deliver it?
4. Which existing tests would fail if this behavior were broken?

Read surrounding code and tests before filing a finding. Prefer concrete reproduction paths over theoretical concerns.

## Severity Guidance

- **Critical**: Data corruption, production crash, destructive action, or silent wrong results in core behavior.
- **High**: Failure under common edge cases, resource leaks under expected load, or broken user-facing workflows.
- **Medium**: Failure under uncommon but plausible conditions, degraded behavior, or misleading errors.
- **Low**: Defensive improvements or fragile patterns that could become bugs later.
