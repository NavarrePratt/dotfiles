# Monitoring & Repeated Checks

## Banned: Bash polling loops

NEVER use unmanaged bash `for`/`while` loops with `sleep` to poll or monitor
anything. These are flaky, inconsistent, and unreliable - timing drifts, loops
die silently, and output is hard to act on.

```bash
# NEVER do this
while true; do kubectl get pods; sleep 30; done
for i in $(seq 1 60); do curl ...; sleep 10; done
watch -n 5 "gh run view ..."
```

## Use Codex-native long-running command handling

When you need to watch a build, test suite, deploy, CI run, log stream, or
resource convergence, prefer a single targeted long-running command in a managed
tool session. Poll that session for output, stop it when done, and report the
result.

Good use cases:
- Tail a specific log file and flag errors as they appear
- Follow one CI job or deploy until it reaches a terminal state
- Watch a narrow directory or resource for changes
- Track output from a long-running test or build

## Periodic checks

For repeated checks, run explicit targeted commands at reasonable intervals from
the agent side instead of embedding sleep loops in the shell. Keep each command
scoped, especially for Kubernetes or GitHub operations, and stop once the
decision point is reached.

## Background tasks are still fine

Long-lived one-shot work - builds, test suites, large git operations - can run
in a managed background or PTY session when the tooling supports it. Do not end
the turn while a task needed for the user's request is still running.
