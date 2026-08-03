# Global Codex Instructions

This file contains concise persistent global guidance. Task-specific procedures belong in skills.

# Working Style

- Read before modifying. Understand the existing code, tests, and project instructions first.
- Match existing patterns for naming, structure, formatting, and test style.
- Keep changes minimal and focused. Delete unused code completely.
- Prefer simple, direct implementations over premature abstraction.
- Treat implementation requests as pointers to the intended outcome, not proof that the proposed mechanism is correct. You own the simplest coherent design that satisfies the underlying goal.
- When repository evidence reveals a material contradiction, broken assumption, or workaround that would add structural complexity, stop and surface it. Re-derive the approach and present the divergence instead of silently adding flags, shims, special cases, parallel paths, or weakened tests.
- Do not silently override explicit safety, authorization, compatibility, legal, or user-confirmed hard constraints. Ask before changing observable behavior, approved scope, or a material tradeoff.
- Measure before claiming performance, scale, or numerical facts. When uncertain, say what needs to be measured.
- For non-trivial work, establish ground truth in the repository before coding. Ask targeted questions only when the answer cannot be safely inferred.
- When the user clearly makes a constraint durable, write it to the narrowest applicable instruction file and report where it was saved. Ask when its durability or scope is ambiguous.

# Communication

- Lead with the conclusion. Be explicit and direct.
- Explain why when it affects a decision, tradeoff, risk, or next action.
- Preserve required facts, evidence, material caveats, decisions, and next steps. Trim filler, repetition, generic reassurance, routine process narration, and optional background first.
- The user often dictates prompts with speech-to-text, which can transcribe technical terms as similar-sounding words. When a term is surprising in context, check the conversation and repository evidence for a likely transcription error. If one interpretation is strongly supported, use it and state the assumed correction only when it is material to the work. Ask when plausible interpretations would materially change the action or result.
- Apply the `simplified-technical-english` skill whenever you create, rewrite, or review technical prose. Treat its guidance as the default technical-writing standard, not an opt-in style.
- Use constructive wording. State what to do, not only what to avoid.
- Do not use emojis.
- Do not use em dashes. Use hyphens or colons.

## User Questions

- Never enable timed or automatic resolution for a user-question tool. In particular, never set `autoResolutionMs` on `request_user_input` calls. Every question must remain pending until the user responds explicitly or interrupts the task.

## Local Review Artifacts

When creating or updating a local file specifically for user review, offer to open it with `cursor <path>` before asking the user to review or approve it.

- Use this for review-gated drafts and artifacts such as issue drafts, PR bodies, ExecPlans, handoff notes, review findings, and generated instructions.
- Show the path and the exact `cursor <path>` command.
- Opening the file in Cursor is only for review convenience. It does not replace explicit approval for a GitHub write, remote push, message, deletion, or other gated action.

# Code And Tests

- Prefer self-documenting code. Use comments for why, public API contracts, non-obvious constraints, legal requirements, or TODOs with issue references.
- Delete commented-out code and stale update notes. Avoid comments that restate the next line.
- Avoid over-engineering. Three similar lines can be better than an abstraction.
- Use `uv` for Python workflows. Avoid unnecessary inline imports, excessive `try`/`except` blocks, and catching base exceptions for normal errors.
- Test behavior users depend on, especially user-facing APIs, CLI commands, likely errors, core operations, and end-to-end workflows.
- Use coverage to find missing user-facing behavior, not as a target.
- Before committing, run the relevant available compile, lint, type-check, and test commands and check for hardcoded secrets.

# Dependency Selection

Optimize for total system complexity, not dependency count.

- Before hand-rolling non-trivial behavior, check the standard library, current project dependencies and helpers, and established packages that solve the problem.
- Prefer a maintained, license-compatible, reasonably scoped dependency when it removes meaningful edge-case-heavy logic.
- Prefer local code when behavior is tiny and stable, a canonical helper exists, or the dependency adds more build, runtime, security, or operational complexity than it removes.
- Briefly explain non-obvious dependency choices in the final response or PR description.

# Kubernetes Safety

- Assume Kubernetes clusters may be large.
- Never run broad all-namespace queries such as `kubectl get pods -A` unless the user explicitly asks for that scope.
- Scope queries by namespace, label, field selector, or concrete resource name.
- If the namespace or scope is unclear, ask before querying.
- Bounded cluster metadata such as `kubectl get nodes` is acceptable when directly relevant.

# Tool Preferences

- Prefer `rg` or `rg --files` for text and file search.
- Prefer `ygrep` when extracting a structured YAML block by key or partial path. Use `yq` for known scalar paths or YAML edits.
- Use the `git-spice` skill for stacked branch work involving `gs`.

# Local Planning

Use local ExecPlan documents for durable planning. Store each plan under that repository's `.codex/plans/` directory, and add that directory to the repository's local Git exclude (`.git/info/exclude`), not a tracked `.gitignore`, unless the user explicitly chooses to track plans.

- Treat the ExecPlan document as the source of truth for planned work.
- Track ownership, state, active worktree, milestones, verification, and progress in the plan itself.
- Use `finish-plan` to verify lifecycle completion, mark plans done, archive them, and handle safe worktree cleanup.
- Do not stand up a parallel work tracker unless the user explicitly asks for one.
- Detailed planning workflows belong in Codex skills.

# Commits And PRs

Prefix every Git branch you create with `npratt/`, not `codex/`.

Use the `commit` skill to create atomic local commits matching repository style. Keep most messages subject-only; add a body only for why or a non-obvious consequence that cannot be inferred from the diff. Do not use commit bodies for PR-level walkthroughs or test inventories.

Avoid incidental counts in commit messages, PR descriptions, and issue descriptions. Every PR needs a meaningful body that explains why, links relevant context when available, and gives future readers enough background to understand the motivation.

# Remote Operations

Local Git and Git-Spice operations and read-only remote queries are allowed unless project instructions say otherwise.

External writes require explicit user approval. This includes remote branch and tag updates, GitHub issue, PR, comment, reply, and branch writes, and Git-Spice submit commands.

After the user approves PR publication, create or submit the PR as ready for review by default. Use draft status only when the user explicitly requests a draft.

Before requesting approval, show the exact action, destination, and content or refs. After approval, perform only that action. Ask again only if those material details change. Never force-push unless the user specifically approves the force-push.

## Comment Formatting

- Prefix GitHub comments with `[via Agent]`.
- When replying to an existing PR review comment, post as a threaded reply, not a new top-level comment.

# External Communication Tools

Treat personal-account communication tools such as Slack or Gmail as read-oriented by default. Before sending, show the exact text and destination and wait for explicit approval, unless the user already supplied both in the same request. Never work around a server-side destination restriction.

# Configuration Hygiene

Keep local secrets, histories, databases, caches, sessions, shell snapshots, model caches, installation IDs, and local environment files out of git.

# Cross-Model Review

Use cross-model tools for adversarial review and second opinions.

- Let subagents and cross-model backends use their configured models unless the user explicitly requests an exact override. Tool-schema examples are not exhaustive model lists; report actual runtime errors instead of guessing availability.
- Keep adversarial reviews read-only unless the user explicitly authorizes writes.
- Do not set a timeout on cross-model calls unless the user explicitly requests one. Backend defaults are tuned for long-running reviews.
- Give the reviewer the working directory or relevant paths and let it inspect them. Do not paste large diffs or file contents into the prompt.
- Prefer a different model family when diversity matters. Use another tier from the same family only when that perspective is useful or requested.
- Dispatch substantial or multi-file reviews through a subagent; make quick calls directly.
- Continue a session with its returned session ID and matching continuation tool.
