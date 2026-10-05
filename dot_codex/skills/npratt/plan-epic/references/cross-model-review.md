# Cross-Model Plan Review

Use this reference for hybrid and autonomous planning. Do not use it in
user-only mode unless the user explicitly changes the mode.

The review tests technical completeness. It does not decide whether the user
should pursue the work.

Entering hybrid or autonomous mode authorizes the bounded reviewer to receive
the task-relevant prompt, local ExecPlan, repository instructions, and named
source, test, configuration, or documentation files needed for the review. Do
not ask for redundant file-by-file approval. This authorization never includes
secrets, credentials, unrelated private data, external writes, or other state
changes. If useful review context contains any of those, omit it or ask the
user for a narrower safe alternative.

## Review Bound

One plan can use at most:

- one Claude prompt
- one Claude continuation
- one OpenCode prompt

Do not continue OpenCode. A third model supplies context, not a vote. Do not
resolve disagreement by counting reviewers.

## Prepare the Review

1. Confirm that the `State: design` plan exists on disk.
2. Resolve the absolute repository root with `git rev-parse --show-toplevel`.
3. Resolve the absolute plan path under that root.
4. Identify the repository instruction files and current implementation files
   that the reviewer must read.
5. Inspect the live Codex tool registry. Confirm the exact cross-agent tool
   names instead of deriving them from the configured server name.

The current confirmed Codex names are:

- `mcp__cross_agent__claude_prompt`
- `mcp__cross_agent__claude_continue`
- `mcp__cross_agent__claude_abort`
- `mcp__cross_agent__opencode_prompt`
- `mcp__cross_agent__opencode_continue`
- `mcp__cross_agent__opencode_abort`

If the available names differ, treat the stale name as a skill defect. Do not
silently classify a name mismatch as backend unavailability.

The plan is hidden and normally git-excluded. Tell the reviewer to read the
absolute plan path directly. Do not ask it to discover the plan with search.

The read-only Claude backend does not load project setting sources, skills,
memory, or MCP servers automatically. It also cannot run shell commands. Name
the instruction and pattern files in the prompt. Verify asserted command results
locally before accepting them.

## Review Worker

A substantial plan review can run in one background worker so the lead session
stays responsive. The worker owns only the backend call. The lead session owns
repository verification, user decisions, synthesis, and the top-level plan.

The MCP server owns the native backend session. The worker returns the parsed
session ID and findings to the lead. A later worker or the lead can issue the
single continuation with that session ID. Do not repeat the prompt because a
worker exited.

If an agent thread cannot start or the worker cannot access the cross-agent
tools, make the bounded call from the lead session. Do not add reviewers.

## Start the Claude Review

Call the confirmed Claude prompt tool with:

- `directory`: the absolute repository root
- `read_only`: `true`
- `prompt`: the review request with the absolute plan path and named source files

Omit `model` and `timeout`. Use the configured backend model and timeout.

Ask the reviewer to:

1. Read the plan directly from the absolute path.
2. Read the named repository instructions and implementation files.
3. Find missing implementation details, edge cases, dependencies, error paths,
   tests, rollout steps, documentation, and conflicts with repository patterns.
4. Give repository or plan evidence for each concern.
5. Explain the implementation impact.
6. Propose a concrete plan amendment.
7. Avoid feasibility, product-direction, and style-only review.

Require the response to cite an exact location from the plan. This proves that
the reviewer opened the ignored file.

## Parse the Response

A successful prompt response begins with:

```text
Session: <native-session-id>

<review text>
```

Extract the session ID from the first line and preserve it for the optional
continuation. A continuation returns review text without another session line.

Any response beginning with `Error: ` is a failed call, not review content.

- If the Claude tool family is absent while OpenCode is available, Claude is
  unavailable and the fallback rule can apply.
- If the skill names a tool that differs from the available family, report a
  skill defect. Do not fall back silently.
- Treat an OpenCode unattended-permission error as a configuration fault. Do not
  retry it automatically.
- Use the matching abort tool only when a native session ID is already known.
  An initial prompt that never returns provides no session ID to abort.

On failure, preserve the design plan and ask whether to retry, use an available
fallback, or continue without external review. Do not change the plan state
silently.

## Assess Findings

Verify every finding against repository evidence and explicit user decisions.
A finding is material only when it changes one of these plan elements:

- milestone
- file or existing pattern
- acceptance criterion
- verification command
- decision
- stated risk

Discard unsupported findings. Record non-material observations only when they
will help implementation.

In hybrid mode, present material accepted findings, disputed findings, and user
decision points. The user's explicit decision wins.

In autonomous mode, incorporate supported findings without pausing. Record
disputed findings and assumptions for the final handoff. Pause only when a
decision truly blocks a coherent plan.

## Continue Claude Once

Continue only after a material plan revision needs validation. Call the
confirmed Claude continuation tool with:

- the parsed `session_id`
- `directory`: the same absolute repository root
- `read_only`: `true`
- `prompt`: the revised plan path and the specific amendments to verify

Omit `timeout`. Do not start a replacement prompt when the native session ID is
available.

## Escalate to OpenCode

Use one OpenCode prompt only when at least one condition applies:

- security, migration, infrastructure, concurrency, or another unusually risky
  boundary needs independent scrutiny
- a material Claude-Codex disagreement remains after repository verification
- important uncertainty remains after the Claude continuation
- the user explicitly requests broader model diversity
- Claude is unavailable

Before the call, verify that the configured OpenCode agent enforces read-only
behavior. Use the same absolute paths, evidence requirements, and omission of
model and timeout overrides. Do not continue the OpenCode session.

When the call bound is reached, stop. Present unresolved positions, Codex's
repository-evidence-based assessment, and the decision to the user.

## Preserve Useful Evidence

Carry every accepted conclusion into the top-level ExecPlan. Store raw output
only when disagreement or detailed reasoning will help a future implementer:

```text
.codex/plans/<slug>/reviews/<timestamp>-<backend>.md
```

The artifact is evidence. The top-level ExecPlan remains the source of truth.
