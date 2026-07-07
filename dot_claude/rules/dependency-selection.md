---
description: Choose dependencies by total system complexity, not dependency count
---

# Dependency Selection

Optimize for total system complexity, not dependency count. A well-maintained,
popular library can be simpler and safer than custom code when it solves the
exact problem and absorbs real edge cases.

Before hand-rolling non-trivial behavior, check:

- the standard library
- existing project dependencies
- project-native helpers or framework features
- mainstream ecosystem packages that solve the exact problem

Prefer adding or using a dependency when it is established, actively maintained,
license-compatible, reasonably scoped, and replaces meaningful custom logic in
an edge-case-heavy domain such as parsing, dates and time zones, validation,
auth, crypto, serialization, protocol clients, retries, file watching, diffing,
graph algorithms, or UI primitives.

Prefer local code when the behavior is tiny and stable, the dependency is broad
or risky, the project already has a canonical helper, or the package would add
more build, runtime, security, or operational complexity than it removes.

For non-obvious dependency decisions, briefly explain the tradeoff in the final
response or PR description. Include why a dependency was added, reused, or
rejected.
