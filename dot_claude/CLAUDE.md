# Global Instructions

This file documents workflow standards, issue tracking practices, and code quality expectations.

See detailed rules in:
- @rules/dependency-selection.md - Choose dependencies by total system complexity, not dependency count
- @rules/kubernetes-safety.md - Never run unscoped kubectl queries on large clusters

# Quick Reference

## Git Commits

Use `/commit` slash command for all commits—creates atomic, well-formatted commits matching project style.

# PR Description Standards

Every PR must have a meaningful description. Never create PRs with empty bodies.

When writing PR descriptions:
- Explain why the change was made, not what changed. We can read the code.
- Link relevant Slack threads, JIRA tickets, and design documents
- Write for the future: the on-call engineer debugging at 3am will not know about your Slack discussion. PRs serve future readers, not just current reviewers.
- Include enough context that someone unfamiliar with the work can understand the motivation from the PR alone

Commit messages are different: keep them brief. Most commits should be
subject-only. Add a body only for why or a non-obvious consequence that
cannot be inferred from the subject and diff. Do not use commit bodies
for PR-level context, implementation walkthroughs, or test inventories.
See the git-commit skill for body length rules.

# Quality Gates

Before committing:
- Code compiles/lints without errors
- All tests pass
- No hardcoded secrets
- Changes are minimal and focused

# Local Review Artifacts

When creating or updating a local file specifically for user review, offer to open it with `cursor <path>` before asking the user to review or approve it.

- Use this for review-gated drafts and artifacts such as issue drafts, PR bodies, ExecPlans, handoff notes, review findings, and generated instructions.
- Show the path and the exact `cursor <path>` command.
- Opening the file in Cursor is only for review convenience. It does not replace explicit approval for a GitHub write, remote push, message, deletion, or other gated action.

# Code Style

- Read before modifying
- Match existing patterns
- Minimal changes only
- Delete unused code completely
- No over-engineering
- No emojis. No em dashes - use hyphens or colons instead.

# Communication

- Be explicit and direct
- Provide context (why, not just what)
- Use positive framing
- Be concise

# GitHub Interactions

**NEVER perform write operations to GitHub without explicit user approval.**

This includes:
- Creating issues (`gh issue create`)
- Creating PRs (`gh pr create`)
- Posting comments or replies
- Deleting issues, PRs, branches
- Any other GitHub API write operations

Before any GitHub write operation:
1. Show the user exactly what will be created/posted
2. Wait for explicit approval (e.g., "yes", "go ahead", "create it")
3. Only then execute the API call

# Git Remote Operations

**NEVER push to remote repositories without explicit user approval.**

This includes pushing commits, tags, or any branch updates to remote.

Before running `git push`:
1. Show what will be pushed (commits, branch)
2. Wait for explicit approval
3. Only then execute the push

**ESPECIALLY CRITICAL**: Never run `git push --force` or `git push --force-with-lease` without approval, as these can destroy work on shared branches.

Local operations (commit, branch, stash, rebase) are fine without approval.

## Comment Formatting

- Always prefix comments with `[via Claude]` to indicate they were written by Claude
- When replying to an existing comment, post as a reply (not a new comment in the main thread)

## Replying to PR Review Comments

To reply to a PR review comment, POST to the pull comments endpoint with `in_reply_to`:

```bash
# CORRECT - posts as a threaded reply to an existing review comment
jq -n --arg body "[via Claude] Your reply here" '{body: $body, in_reply_to: COMMENT_ID}' | \
  gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments --input - -X POST

# WRONG - posts as a new comment in the main thread
gh api repos/OWNER/REPO/issues/PR_NUMBER/comments \
  -X POST -f body="[via Claude] Your reply here"
```

To find comment IDs, fetch PR comments first:
```bash
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments --jq '.[] | {id, user: .user.login, body: .body[:80]}'
```

# MCP Tools

## Cross-Model MCP Tools

Several MCP servers expose other AI coding agents for cross-family adversarial review and second opinions: `mcp__codex__codex` (GPT-5.5), `mcp__cross-agent__opencode_prompt` (GLM-5.2 via WANDB), and `mcp__cross-agent__claude_prompt` (Claude, different tier from your current session).

When using any of these:
- Do not manually specify the `model` parameter unless the user explicitly requests a specific model. Let each backend use its configured default.
- The MCP `model` field is a free string, not an enum of available models. Do not infer that a model is unavailable from examples in the tool schema.
- If a model override is explicitly requested, use the exact model slug, for example `gpt-5.5`.
- If a backend reports a model error, quote the actual tool/runtime error rather than guessing from the schema.
- `read_only=True` is the default and correct for adversarial review. Only set `read_only=False` if the user explicitly asks for write access.
- Do not set the `timeout` parameter on cross-model MCP tool calls. The harness and backend defaults are already tuned for long-running reviews. Setting an explicit timeout (e.g. 300s) will kill reviews mid-flight. Only override if the user explicitly requests a specific timeout.
- Do not paste large diffs or file contents into the prompt. The reviewing agent has read-only tools (Read, Glob, Grep, WebFetch) and can read files itself. Give it the working directory or file paths to review and let it explore on its own. This keeps prompts short and lets the reviewer form its own understanding.
- Use `opencode_prompt` for cross-family diversity (GLM-5.2 reviewing Claude/GPT work).
- For non-trivial cross-model calls (full reviews, multi-file analysis), dispatch the MCP call inside a subagent so the main conversation isn't blocked. For trivial calls (quick question, one-liner check), call the MCP tool directly.
- For session continuation, pass the returned `session_id` to the matching `_continue` tool.

# Principals

- Assumptions are the enemy. Never guess numerical values - benchmark instead of estimating. When uncertain, measure.
  Say "this needs to be measured" rather than inventing statistics.
- **Interaction**: Clarify unclear requests, then proceed autonomously. Only ask for help when scripts timeout (>2min) or genuine blockers arise.
- **Ground truth clarification**: For non-trivial tasks, reach ground truth understanding before coding. Simple tasks execute immediately.
  Complex tasks (refactors, new features, ambiguous requirements) require clarification first: research codebase, ask targeted questions,
  confirm understanding, persist the plan, then execute autonomously. 
- **First principals reimplementation**: Building from scratch can beat adapting legacy code when implementations are in wrong languages,
  carry historical baggage, or need architectural rewrites. Understand domain at spec level, choose optimal stack,
  implement incrementally with human verification.
- **Constraint persistence**: When user defines constraints ("never X", "always Y", "from now on"), immediately persist to projects local
  CLAUDE.md. Acknowledge, write, confirm.
