---
name: team-branch-review
description: Comprehensive branch review using parallel agent reviewers with Codex validation. Use when reviewing all commits on a branch before creating a PR, especially for large or complex branches that benefit from multi-perspective review. Trigger on "review my branch", "check before I PR", "full code review", "pre-PR review", "team review", or "review before merge".
argument-hint: "[--epic <EPIC_ID>] [optional extra instructions]"
---

# Team Branch Review

Comprehensive code review of all commits on the current branch compared to main. Spawns parallel Claude (Opus) reviewer agents as background tasks - each specializing in a different review concern. Each reviewer independently validates their own findings using the Codex MCP, then the lead collects the results and synthesizes the final report.

## Context

- Working directory: !`pwd`
- Current branch: !`git branch --show-current`
- Base commit: !`git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "main"`

## Instructions

You are the lead conducting a comprehensive multi-agent code review.

Use the Agent tool to spawn Claude reviewer agents as background tasks (send all Agent calls in a single message so they run concurrently). Each reviewer is an independent Claude agent session, not a Codex MCP call - do not substitute direct mcp__codex__codex calls for reviewer agents. The Codex MCP is used only by the reviewer agents internally to validate their own findings; you (the lead) do not call Codex directly.

**This skill does NOT edit files.** It produces a review report only.

You will:
1. Spawn parallel Claude (Opus) reviewer agents as background tasks using the Agent tool
2. Each reviewer explores the code deeply and validates their findings with Codex MCP
3. You collect all validated findings and synthesize the final report

---

### Phase 0: Precondition Check

Before doing anything else, verify you have the required tool:

**Check for the Agent tool (subagent spawner).** This is the tool that launches new agent sessions with parameters like `subagent_type`, `description`, and `prompt`. Look at your available tools - if you do not have a tool called "Agent" that spawns subagents, STOP IMMEDIATELY and tell the user:

   "This skill requires the Agent tool (subagent spawner) which is not available in custom agent sessions (claude --agent). Run this skill from a plain `claude` session instead."

   Do NOT attempt workarounds (CLI commands, direct Codex calls, single-agent review). Just stop.

Do NOT proceed past this phase unless the Agent tool is confirmed available.

---

### Phase 1: Analyze Branch Scope

Substitute BASE_COMMIT from Context above, then run these git commands:

```bash
git diff --shortstat BASE_COMMIT..HEAD
git log --oneline BASE_COMMIT..HEAD
git diff --stat BASE_COMMIT..HEAD
```

**Look up PR description** (if one exists for this branch):

```bash
gh pr view --json title,body --jq '"## " + .title + "\n\n" + .body' 2>/dev/null
```

If a PR exists, save the output as **pr_context**. If the command fails (no PR exists), set **pr_context** to empty string.

**Parse arguments and resolve epic**: Check if `$ARGUMENTS` begins with `--epic <EPIC_ID>`. If so, extract the ID and strip the flag (and its value) from the remaining arguments. Then follow `~/.claude/skills/shared/planning-context.md` to produce **planning_context** — the rendered block substituted into the reviewer prompt's `PLANNING_CONTEXT` placeholder. If no `--epic` was passed, that procedure falls back to parsing the branch name and finally to the "no linked planning context" string. Do not stop the pipeline if resolution fails — the fallback is valid output.

Record:
- **lines_changed**: Total lines added + removed
- **files_changed**: List of all changed file paths
- **commit_count**: Number of commits
- **base_commit**: The exact commit hash (use this everywhere, not "main")
- **pr_context**: The PR title and body if a PR exists, otherwise empty
- **planning_context**: The rendered block from the planning-context loader
- **RUN_ID**: Compute a unique run id (used only as the findings temp-dir name): take the branch name, replace `/` with `-`, truncate to 30 chars, then prefix with `review-` and append `-` plus the first 6 chars of HEAD's commit hash. Example: branch `feat/add-auth` at commit `a1b2c3d` becomes `review-feat-add-auth-a1b2c3`. The findings directory is `/tmp/RUN_ID`.

### Phase 2: Determine Team Composition

Based on lines_changed:

**Small (< 200 lines)** - 2 reviewers:

| Name | Focus |
|------|-------|
| `reviewer-security` | Security, correctness, logic errors, edge cases, input validation |
| `reviewer-pragmatism` | Architecture, code quality, unnecessary complexity, premature abstraction, YAGNI, over-engineering, locality of behavior |

**Medium (200-1000 lines)** - 4 reviewers:

| Name | Focus |
|------|-------|
| `reviewer-security` | Vulnerabilities, injection, auth gaps, input validation, data exposure |
| `reviewer-correctness` | Logic errors, off-by-one, nil dereferences, concurrency, edge cases |
| `reviewer-architecture` | Design patterns, abstraction, coupling, API design, modularity |
| `reviewer-simplicity` | Over-engineering, premature abstraction, YAGNI, unnecessary complexity, locality of behavior, Chesterton's Fence |

**Large (1000+ lines)** - 6 reviewers:

| Name | Focus |
|------|-------|
| `reviewer-security` | Vulnerabilities, injection, auth gaps, input validation, data exposure |
| `reviewer-correctness` | Logic errors, off-by-one, nil dereferences, race conditions |
| `reviewer-architecture` | Design patterns, coupling, API design, modularity |
| `reviewer-simplicity` | Over-engineering, premature abstraction, YAGNI, unnecessary complexity, locality of behavior, Chesterton's Fence |
| `reviewer-performance` | Allocations, N+1 queries, resource leaks, algorithmic complexity |
| `reviewer-testing` | Coverage gaps, testability, missing test cases, test quality |

### Phase 3: Spawn Reviewer Agents

1. **Create temp directory** for reviewer findings:
   ```bash
   mkdir -p /tmp/RUN_ID
   ```

2. **Load templates and reviewer briefs.** Before spawning, read the following files using the Read tool:

   **Prompt templates** (from `~/.claude/skills/team-branch-review/templates/`):
   - `templates/reviewer-prompt.md` - The prompt template for reviewer agents (used in step 3 below)
   - `templates/final-report.md` - The report format for Phase 5 synthesis (read now, use later)

   **Reviewer briefs** (shared dotfiles-managed source:
   `~/.config/dotfiles/agent-review/reviewers/`). This shared path must be
   installed before these staged Claude review skills are applied or used.

   | Reviewer name | Brief file |
   |---|---|
   | `reviewer-security` | `~/.config/dotfiles/agent-review/reviewers/security.md` |
   | `reviewer-correctness` | `~/.config/dotfiles/agent-review/reviewers/correctness.md` |
   | `reviewer-architecture` | `~/.config/dotfiles/agent-review/reviewers/architecture.md` |
   | `reviewer-simplicity` | `~/.config/dotfiles/agent-review/reviewers/simplicity.md` |
   | `reviewer-pragmatism` | `~/.config/dotfiles/agent-review/reviewers/pragmatism.md` |
   | `reviewer-performance` | `~/.config/dotfiles/agent-review/reviewers/performance.md` |
   | `reviewer-testing` | `~/.config/dotfiles/agent-review/reviewers/testing.md` |

   Read ALL relevant brief files and both template files.

3. **Spawn ALL reviewers in parallel** (send all Agent calls in a single message):

   For each reviewer, take the loaded reviewer prompt template and substitute all placeholders, then pass the result as the Agent prompt:

   ```
   Agent(
     subagent_type: "general-purpose",
     description: "Security review",
     prompt: "[reviewer-prompt.md with all placeholders substituted]"
   )
   ```

   Repeat for each reviewer. Send all Agent calls in a single message so they run concurrently as background tasks. Each call returns an `agentId` and completes with a `<task-notification>`; record the `agentId`s for Phase 4.

### Reviewer Prompt Template

Each reviewer receives the prompt from `~/.claude/skills/team-branch-review/templates/reviewer-prompt.md` (loaded in Phase 3, step 2).

Substitute these placeholders before passing to each reviewer:

| Placeholder | Value |
|---|---|
| FOCUS_AREA | The reviewer's specialization name |
| FOCUS_DESCRIPTION | One-line description of their focus |
| FOCUS_BRIEF | Full content from the reviewer's brief file |
| BRANCH_NAME | Current branch name |
| BASE_COMMIT | Exact commit hash from Phase 1 |
| FILE_LIST | All changed file paths, one per line |
| CWD | Working directory |
| RUN_ID | The run id computed in Phase 1 (used for findings file path) |
| REVIEWER_NAME | The reviewer's name, e.g. `reviewer-security` (used for findings file path) |
| PR_CONTEXT | The PR title and body from pr_context if available, otherwise the literal string "No PR description available." |
| PLANNING_CONTEXT | The rendered planning_context block from Phase 1 (falls back to "No linked planning context available — reviewing against general code-quality heuristics only." when no epic resolved) |

### Phase 4: Wait for All Reviewers to Complete

Wait for every reviewer's background task to complete. Each spawned Agent fires a `<task-notification>` when it finishes. Do NOT poll with bash loops and sleep - this violates the monitoring rule in `~/.claude/rules/monitoring.md`.

Once ALL reviewers have completed, read each reviewer's findings file at `/tmp/RUN_ID/{reviewer-name}.md` and compile all findings into a single list tagged by reviewer. Findings come from these files - do NOT read the agent `.output` file (it is the raw JSONL transcript and will overflow your context).

This is a hard gate: do not begin synthesis until all reviewers have completed. If a reviewer completes but did not produce a findings file, note the gap in the final report and proceed with available findings. To abort a stuck reviewer, use `TaskStop` with its `agentId`.

### Phase 5: Synthesize Final Report

You (the lead) produce the final report directly using the findings read from `/tmp/RUN_ID/` files in Phase 4. Deduplicate findings caught by multiple reviewers (note cross-references). Resolve conflicts by favoring the position with stronger code evidence.

Use the report format from `~/.claude/skills/team-branch-review/templates/final-report.md` (loaded in Phase 3, step 3). Substitute BRANCH_NAME and fill in all sections with the compiled findings.

### Phase 6: Cleanup

The reviewer background tasks self-terminate when they finish, so there is nothing to shut down. Remove the temp findings directory:

```bash
rm -rf /tmp/RUN_ID
```

---

## Error Handling

| Scenario | Recovery |
|----------|----------|
| Reviewer agent fails or times out | Note the gap in the report, continue with remaining findings |
| Codex MCP unavailable for a reviewer | Reviewer reports unvalidated findings, noted in report |
| Team spawn fails | Fall back to single-agent review (run codex-branch-review instead) |
| No findings from any reviewer | Report "APPROVED - no issues found" with note about review coverage |

## Guidelines

- **Model inheritance**: Do NOT set a `model` parameter on spawned agents - they inherit the global model setting automatically
- **Parallel execution**: Spawn ALL reviewer agents simultaneously in one message
- **Fixed base commit**: Use the exact hash from Phase 1 everywhere, never "main"
- **Distributed Codex validation**: Each reviewer calls Codex MCP to validate their own findings (runs in parallel)
- **Don't embed diffs in prompts**: Let agents and Codex gather diffs via git commands themselves
- **Deep exploration**: Reviewers should use Read, Grep, Glob extensively - not just skim diffs
- **No severity inflation**: Findings should use honest, appropriate severity levels
- **Phase 4 is a hard gate**: Do NOT write the report until all reviewers have completed. This is non-negotiable.
- **Findings come from files**: Reviewers write findings to `/tmp/RUN_ID/`. Do not use message content or the agent `.output` transcript as findings.

## Next Steps

After presenting the report, if the outcome is NEEDS REVISION or MANUAL REVIEW REQUIRED, add this note:

> **Next steps:**
> - `/team-branch-fix` - Implement fixes for these findings. Choose which to fix, then agents implement changes in parallel.
> - `/team-branch-comment` - Post findings as PR review comments on specific lines. Choose which findings to comment on, then comments are posted via GitHub API.

$ARGUMENTS
