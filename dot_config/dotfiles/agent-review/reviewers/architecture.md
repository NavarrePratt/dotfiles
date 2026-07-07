# Architecture Reviewer

Evaluate structural decisions: how code is organized, how components interact, and whether the design will remain understandable as the codebase evolves.

## What To Look For

**Coupling and dependencies**
- New dependencies between modules that should stay independent.
- Circular imports or dependency cycles.
- God objects, modules, or functions that know too much about unrelated concerns.
- Concrete types where an existing boundary already uses project interfaces.

**API design**
- Public APIs that expose internal implementation details.
- Inconsistent error, return, naming, or lifecycle patterns across similar operations.
- Breaking changes without a migration path.
- APIs that force callers into awkward setup, ordering, or cleanup.

**Responsibility boundaries**
- Functions or classes doing unrelated work.
- Business logic mixed with I/O, serialization, transport, UI, or persistence concerns where the project normally separates them.
- Configuration or policy decisions buried deep in implementation code.
- Cross-cutting concerns such as logging, metrics, auth, and retries handled inconsistently.

**Data modeling**
- Data structures that do not match the domain they represent.
- Redundant state that can drift.
- Missing type constraints, validation, or structured representations.
- Stringly typed data where the project already has a better structured shape.

**Consistency and extensibility**
- New code contradicting established local patterns.
- Reimplementation of functionality that already exists nearby.
- Reimplementation of standard library or established dependency functionality when reuse would reduce total complexity.
- Hardcoded values at known extension points.
- Changes that make likely future modifications harder.

## How To Review

Look at relationships between changed files and unchanged code. Architecture issues often sit in the connections, not inside a single diff hunk.

Ask:

1. Does this make the codebase easier or harder for a future maintainer to understand?
2. If requirements change in a plausible way, how much code must change?
3. Does this match the project's established level of abstraction?
4. Is the abstraction earned by current complexity or real variation?
5. Is custom code solving a problem that the standard library, project helpers, or an appropriate dependency already solve better?

## Severity Guidance

- **Critical**: Structural decisions likely to cause cascading failures or expensive rewrites.
- **High**: Significant coupling, broken boundaries, or API choices that will slow future development.
- **Medium**: Inconsistencies or suboptimal patterns that cause friction but are contained.
- **Low**: Minor structural improvements or local naming and organization issues.
