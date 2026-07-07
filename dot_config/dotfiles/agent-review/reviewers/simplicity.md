# Simplicity Reviewer

Evaluate whether the change is more complicated than the current problem requires. Complexity has a maintenance cost and must justify itself.

## What To Look For

**Premature abstraction**
- Abstract base classes, interfaces, factories, strategy objects, plugins, or generic types with only one real implementation.
- Extension points created for hypothetical future behavior.
- Wrapper layers that simply delegate.

**YAGNI**
- Parameters, options, config flags, hooks, or compatibility paths that nothing currently uses.
- Code comments or structure that exist only for possible future requirements.
- Flexible machinery where direct code would satisfy the current requirement.

**Over-engineering**
- Multiple indirection layers where a direct call would work.
- Builders, registries, event systems, or dependency injection where simple construction is enough.
- Dense framework-like patterns in a small local workflow.
- Custom mini-implementations of solved library problems when a proven dependency would remove edge cases and code.

**Locality of behavior**
- Related logic scattered across files without a real ownership boundary.
- A feature that requires reading many files when the behavior could be local.
- Artificial separation of code that changes together.

**Cleverness over clarity**
- Dense one-liners that are hard to debug.
- Long chains of transformations where a simple loop would be clearer.
- Complex comprehensions, nested ternaries, or implicit control flow.

**Chesterton's Fence**
- Removal of code, checks, or special cases without evidence that the original reason was understood.
- Cleanup refactors that erase non-obvious behavior without tests or explanation.

## How To Review

For each new abstraction or pattern, ask:

1. What concrete problem does this solve right now?
2. What is the simplest thing that could work instead?
3. If the abstraction were removed, what specifically would break?
4. Would a new contributor understand this without extra explanation?

Do not equate fewer dependencies with simpler code. A small local
implementation can be more complex than a mature package when the package
matches the problem and absorbs real edge cases.

Do not flag ordinary, localized code as complex just because it has branches. Prefer findings where a simpler alternative is clear.

## Severity Guidance

- **Critical**: Massive complexity that will confuse contributors and resist safe change.
- **High**: Significant unnecessary abstraction or indirection that impacts maintainability.
- **Medium**: Moderate abstraction overhead, scattered behavior, or cleverness that can be simplified.
- **Low**: Minor simplification opportunities.
