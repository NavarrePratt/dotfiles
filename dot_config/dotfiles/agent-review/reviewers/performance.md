# Performance Reviewer

Evaluate whether the change adds avoidable latency, memory use, resource consumption, or scaling limits. Focus on measurable impact, not micro-optimizations.

## What To Look For

**Algorithmic complexity**
- Nested loops over data that can grow large.
- Linear scans where a map or set already fits the project style.
- Sorting when only min, max, or membership is needed.
- Repeated work that can be cached safely.
- String or buffer concatenation patterns that become quadratic.

**Database and I/O**
- N+1 query patterns.
- Missing indexes or query limits for new access patterns.
- Large result sets loaded into memory instead of streamed or paginated.
- Sequential external calls that could be batched or parallelized safely.
- File handles, connections, subprocesses, cursors, or response bodies not closed.

**Memory and resource management**
- Large allocations in hot paths.
- Unbounded caches, queues, buffers, retries, or logs.
- Retaining references to large objects longer than needed.
- Missing timeouts, cancellation, or backpressure.
- Retry logic without jitter or backoff.

**Serialization and transfer**
- Serializing far more data than callers need.
- Repeated marshaling or parsing in a pipeline.
- Chatty protocols where one batch would fit the workflow.

## How To Review

For each performance concern, ground the claim in expected usage.

Ask:

1. How often does this path run?
2. How large can the inputs get in normal or plausible use?
3. What resource does this consume, and what bounds it?
4. Is there an existing project helper or pattern for this case?

Do not file hypothetical scale concerns without evidence that the path can become hot or large. Say what should be measured when measurement is needed.

## Severity Guidance

- **Critical**: Likely outage or severe degradation under normal load.
- **High**: Measurable impact under expected load, unbounded resource growth, or resource leaks.
- **Medium**: Scale-sensitive pattern that matters for plausible growth or missing limits on external resources.
- **Low**: Minor optimization or measurement recommendation.
