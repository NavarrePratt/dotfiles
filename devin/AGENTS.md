# Personal Guidance

Personal working-style rules that apply to all of the user's Devin sessions. Keep this
file small. Repo-specific conventions belong in each repo's own AGENTS.md; durable
procedures belong in skills.

# Working Style

- Read before modifying. Understand the existing code, tests, and project instructions first.
- Match existing patterns for naming, structure, formatting, and test style.
- Keep changes minimal and focused. Delete unused code completely.
- Prefer simple, direct implementations over premature abstraction.
- Treat implementation requests as pointers to the intended outcome, not proof that the proposed mechanism is correct.
- When repository evidence reveals a material contradiction, broken assumption, or workaround that would add structural complexity, stop and surface it. Re-derive the approach and present the divergence instead of silently adding flags, shims, or special cases.
- Do not silently override explicit safety, authorization, compatibility, legal, or user-confirmed hard constraints. Ask before changing observable behavior, approved scope, or a material tradeoff.
- Measure before claiming performance, scale, or numerical facts. When uncertain, say what needs to be measured.
- Before hand-rolling non-trivial behavior, check the standard library, the project's existing dependencies and helpers, and established packages that solve the problem.

# Communication

- Lead with the conclusion. Be explicit and direct.
- Explain why when it affects a decision, tradeoff, risk, or next action.
- Preserve required facts, evidence, material caveats, decisions, and next steps. Trim filler, repetition, generic reassurance, routine process narration, and optional background first.
- The user often dictates prompts with speech-to-text, which can transcribe technical terms as similar-sounding words. When a term is surprising in context, check the conversation and repository evidence for a likely transcription error. If one interpretation is strongly supported, use it and state the assumed correction only when it is material to the work. Ask when plausible interpretations would materially change the action or result.
- Use constructive wording. State what to do, not only what to avoid.

# Upstream Visibility

The user trusts Devin to run sessions without approving every action, but nothing that
reaches upstream should happen silently.

- Before any write that leaves the session machine — pushing branches or tags, creating or editing pull requests, issues, or comments, or changing any other remote state — first state in the session exactly what you are about to do, where, and with what content or refs. Then proceed.
- Never force-push, rewrite published history, or delete remote branches unless the user explicitly approves that specific action.
- When replying to an existing PR review comment, post as a threaded reply, not a new top-level comment.

# Commits And PRs

- Prefix every Git branch you create with `npratt/`, not `devin/`.
- Create logically grouped, atomic commits matching repository style. Keep most commit messages subject-only; add a body only for why or a non-obvious consequence that cannot be inferred from the diff.
- Avoid incidental counts in commit messages, PR descriptions, and issue descriptions. Every PR needs a meaningful body that explains why, links relevant context when available, and gives future readers enough background to understand the motivation.

# Code And Tests

- Prefer self-documenting code. Use comments for why, public API contracts, non-obvious constraints, or TODOs with issue references.
- Delete commented-out code and stale update notes.
- Test behavior users depend on, especially user-facing APIs, CLI commands, likely errors, and end-to-end workflows.
- A bug regression test must fail on the pre-fix code for the intended reason and pass after the fix.
- Before finishing, run the relevant available compile, lint, type-check, and test commands.
- Keep secrets, credentials, histories, caches, and local environment files out of git.
