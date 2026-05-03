# Global Codex Instructions

This file documents workflow standards, issue tracking practices, and code quality expectations.

See detailed rules in:
- `~/.codex/rules/issue-tracking.md` - br CLI patterns and issue management
- `~/.codex/rules/session-protocol.md` - session procedures and quality gates
- `~/.codex/rules/kubernetes-safety.md` - never run unscoped kubectl queries on large clusters

# Quick Reference

## Git Commits

When asked to commit, create atomic, well-formatted commits matching project style.

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
Follow the commit body length rules from the active repository instructions when present.

# Bead Creation Boundary

After creating a bead through a planning workflow or manual `br create`:
- Report the bead ID
- Return to the previous task immediately
- Do not start working on the newly created bead
- Do not investigate, edit files, or implement anything for it

The bead will be picked up later by automation or worked on in a future session.
Exception: only continue working if the user explicitly says "and work on it now".

# Bead Content Boundary

Beads must never include instructions that involve upstream or remote operations:
- No `git push` or branch pushing
- No `gh pr create` or PR creation
- No `gh issue create` or GitHub issue creation
- No posting comments, reviews, or any GitHub API writes

Beads are for local work only: code changes, tests, and local verification.
Pushing commits and creating PRs are user-initiated actions that happen
after reviewing the local work. This applies to both manual bead creation
and planning workflows that create beads.

# Issue Tracking Summary

Track work with `br`. Create issues for test failures and bugs. Record meticulous notes for history.

**Priority levels**: 0=critical, 1=high, 2=normal, 3=low, 4=backlog

**Creating issues**: Title 50 chars max, imperative voice. Verbose descriptions with relevant files and snippets.

**Closing issues**: Always provide `--reason` with what was done and how verified. Never close if tests fail or implementation is partial.

**Dependencies**: `br dep add A B --type blocks` means A depends on B (B must complete before A can start).

# Quality Gates

Before committing:
- Code compiles/lints without errors
- All tests pass
- No hardcoded secrets
- Changes are minimal and focused

# Code Style

- Read before modifying
- Match existing patterns
- Minimal changes only
- Delete unused code completely
- No over-engineering
- No emojis. No em dashes - use hyphens or colons instead.

# Communication

- Be explicit and direct
- Provide context: why, not just what
- Use positive framing
- Be concise

# GitHub Interactions

**Never perform write operations to GitHub without explicit user approval.**

This includes:
- Creating issues (`gh issue create`)
- Creating PRs (`gh pr create`)
- Posting comments or replies
- Deleting issues, PRs, branches
- Any other GitHub API write operations

Before any GitHub write operation:
1. Show the user exactly what will be created or posted
2. Wait for explicit approval, such as "yes", "go ahead", or "create it"
3. Only then execute the API call

# Git Remote Operations

**Never push to remote repositories without explicit user approval.**

This includes pushing commits, tags, or any branch updates to remote.

Before running `git push`:
1. Show what will be pushed: commits and branch
2. Wait for explicit approval
3. Only then execute the push

Never run `git push --force` or `git push --force-with-lease` without approval,
as these can destroy work on shared branches.

Local operations such as commit, branch, stash, and rebase are fine without approval.

## Comment Formatting

- Always prefix comments with `[via Codex]` to indicate they were written by Codex
- When replying to an existing comment, post as a reply, not a new comment in the main thread

## Replying to PR Review Comments

To reply to a PR review comment, POST to the pull comments endpoint with `in_reply_to`:

```bash
# CORRECT - posts as a threaded reply to an existing review comment
jq -n --arg body "[via Codex] Your reply here" '{body: $body, in_reply_to: COMMENT_ID}' | \
  gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments --input - -X POST

# WRONG - posts as a new comment in the main thread
gh api repos/OWNER/REPO/issues/PR_NUMBER/comments \
  -X POST -f body="[via Codex] Your reply here"
```

To find comment IDs, fetch PR comments first:

```bash
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments --jq '.[] | {id, user: .user.login, body: .body[:80]}'
```

# Model and Tool Selection

## Codex

When selecting Codex models, spawning Codex subagents, or invoking Codex-backed tools:
- Do not manually specify the `model` parameter unless the user explicitly requests a specific model.
- Let Codex's global config (`~/.codex/config.toml`) select the default model.
- Model fields in tool schemas can be free strings, not complete enums of available models. Do not infer that a model is unavailable from examples in a tool schema.
- If a model override is explicitly requested, use the exact model slug, for example `gpt-5.5`.
- If Codex reports a model error, quote the actual tool/runtime error rather than guessing from the schema.

# Principles

- Assumptions are the enemy. Never guess numerical values - benchmark instead of estimating. When uncertain, measure.
  Say "this needs to be measured" rather than inventing statistics.
- **Interaction**: Clarify unclear requests, then proceed autonomously. Only ask for help when scripts timeout over two minutes or genuine blockers arise.
- **Ground truth clarification**: For non-trivial tasks, reach ground truth understanding before coding. Simple tasks execute immediately.
  Complex tasks such as refactors, new features, or ambiguous requirements require clarification first: research the codebase, ask targeted questions,
  confirm understanding, persist the plan, then execute autonomously.
- **First principles reimplementation**: Building from scratch can beat adapting legacy code when implementations are in wrong languages,
  carry historical baggage, or need architectural rewrites. Understand the domain at spec level, choose the optimal stack,
  implement incrementally with human verification.
- **Constraint persistence**: When the user defines constraints such as "never X", "always Y", or "from now on", immediately persist them to the
  project's local `AGENTS.md` or existing project AI instruction file. Acknowledge, write, confirm.

# BR Integration

Use the `br` CLI to track work across sessions.

See detailed rules in:
- `~/.codex/rules/issue-tracking.md` - br CLI patterns and issue management
- `~/.codex/rules/session-protocol.md` - session procedures and quality gates

## Quick Reference

### Session Startup

Run these commands only when the user explicitly requests session initialization, such as "start session", "check for work", or "what's ready?". Do not run automatically after context compaction. If you were working on something before compaction, continue that work.

```bash
pwd && br prime && br ready --json && git log --oneline -5 && git status
```

### Issue Workflow

```bash
br ready --json                           # Find work
br update br-xxx --status in_progress     # Claim it
# ... do work ...
br close br-xxx --reason "Completed..."   # Close with reason
```

### Git Commits

When asked to commit, create atomic, well-formatted commits matching project style.

## Issue Tracking Summary

Track all work with `br`. Create issues for test failures and bugs. Record meticulous notes for history.

**Priority levels**: 0=critical, 1=high, 2=normal, 3=low, 4=backlog

**Creating issues**: Title 50 chars max, imperative voice. Verbose descriptions with relevant files and snippets.

**Closing issues**: Always provide `--reason` with what was done and how verified. Never close if tests fail or implementation is partial.

**Dependencies**: `br dep add A B --type blocks` means A depends on B (B must complete before A can start).

## Session Protocol Summary

**Startup, user-initiated only**: `br prime` -> `br ready` -> review git state. Do not run after context compaction.

**Work**: One issue at a time. Commit only when asked. Verify end-to-end.

**Completion**: File remaining work as issues. Close completed issues. Do not push.

## Bead Closure

Close or reset beads before ending a session so they do not remain stuck in progress.

- Work complete: `br close br-xxx --reason "Completed: ..."`
- Work incomplete: `br update br-xxx --status open --notes "Needs: ..."`

Never leave beads in progress.

## Quality Gates

Before committing:
- Code compiles/lints without errors
- All tests pass
- No hardcoded secrets
- Changes are minimal and focused
