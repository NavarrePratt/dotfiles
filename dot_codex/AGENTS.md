# Global Codex Instructions

This file contains persistent global guidance for Codex. Keep it concise:
task-specific workflows belong in Codex skills.

# Working Style

- Read before modifying. Understand the existing code, tests, and project instructions first.
- Match existing patterns for naming, structure, formatting, and test style.
- Keep changes minimal and focused. Delete unused code completely.
- Prefer simple, direct implementations over premature abstraction.
- Measure before claiming performance or scale facts. When uncertain, say what needs to be measured.
- For non-trivial work, reach ground truth in the repo before coding. Ask only targeted questions when the answer cannot be safely inferred.
- When the user defines a persistent constraint such as "never X" or "always Y", write it to the active project instruction file and tell the user where it was saved.

# Communication

- Be explicit and direct.
- Explain why when context matters.
- Be concise. Avoid filler.
- Use positive framing.
- Do not use emojis.
- Do not use em dashes. Use hyphens or colons.

# Code Style

- Prefer self-documenting code over explanatory comments.
- Use comments to explain why, public API contracts, non-obvious constraints, legal requirements, or TODOs with issue references.
- Do not leave commented-out code, stale update notes, or comments that merely restate the next line of code.
- Avoid over-engineering. Three similar lines can be better than an abstraction.

## Python

- Use `uv` for Python workflows: `uv run`, `uv pip`, and `uv venv`.
- Avoid inline imports unless they are necessary or add clear value.
- Avoid excessive `try`/`catch` blocks.
- Do not catch base exceptions for normal error handling.

## Testing

- Test behavior users depend on, not implementation details.
- Prioritize user-facing APIs, CLI commands, error handling users will hit, core operations, and end-to-end workflows.
- Use coverage as a guide to find untested user-facing behavior, not as a goal by itself.
- Before committing, verify the relevant compile, lint, type-check, and test commands pass when they are available.

# Kubernetes Safety

- Assume Kubernetes clusters may be large.
- Never run broad all-namespace queries such as `kubectl get pods -A` unless the user explicitly asks for that scope.
- Scope Kubernetes queries by namespace, label, field selector, or concrete resource name.
- If the namespace or scope is unclear, ask for it before querying.
- Bounded cluster metadata such as `kubectl get nodes` is acceptable when it is directly relevant.

# Tool Preferences

- Prefer `rg` or `rg --files` for text and file search.
- Prefer `ygrep` over `grep` or complex `yq` when extracting structured blocks from YAML by key or partial path.
- Use the `git-spice` Codex skill for stacked branch work involving `gs`.

# Local Planning

Use local ExecPlan documents for durable planning. In this dotfiles repo, store them under `.codex/plans/` and keep that directory in the repo's local Git exclude file, not tracked `.gitignore`, unless the user explicitly chooses to track plans later.

- Treat the ExecPlan document as the source of truth for planned work.
- Track ownership, state, active worktree, milestones, verification, and progress in the plan itself.
- Do not create a second source of truth in `br` unless the user explicitly asks for `br` on a specific task.
- Detailed planning workflows should live in Codex skills. Do not recreate a Claude session protocol in this file.

# Commits And PRs

When asked to commit, create atomic, well-formatted local commits matching the repository style.

- Keep most commit messages subject-only.
- Add a body only for why or a non-obvious consequence that cannot be inferred from the subject and diff.
- Do not use commit bodies for PR-level context, implementation walkthroughs, or test inventories.
- Never include fragile counts in commit messages, PR descriptions, or bead descriptions. Write "Add tests for auth module", not "Add 7 tests".

Every PR must have a meaningful description. Never create PRs with empty bodies.

When writing PR descriptions:

- Explain why the change was made, not what changed.
- Link relevant Slack threads, JIRA tickets, and design documents when available.
- Write for future readers who do not know the original discussion.
- Include enough context that someone unfamiliar with the work can understand the motivation from the PR alone.

# GitHub And Remote Safety

Never perform write operations to GitHub without explicit user approval.

This includes:

- Creating issues.
- Creating PRs.
- Posting comments or replies.
- Deleting issues, PRs, or branches.
- Any other GitHub API write operation.

Before any GitHub write operation:

1. Show the user exactly what will be created or posted.
2. Wait for explicit approval, such as "yes", "go ahead", or "create it".
3. Only then execute the operation.

Never push to remote repositories without explicit user approval. This includes commits, tags, branch updates, and Git-Spice submit commands.

For this dotfiles repo, keep changes local by default. The user prefers a thorough manual review before any push or other remote publication.

Before running `git push`, `gs branch submit`, `gs stack submit`, `gs bs`, or `gs ss`:

1. Show what will be pushed or submitted.
2. Wait for explicit approval.
3. Only then execute the command.

Never run `git push --force` or `git push --force-with-lease` without explicit approval.

Local operations such as commit, branch, stash, rebase, Git-Spice branch creation, navigation, restacking, and local sync are allowed unless project instructions say otherwise.

## Comment Formatting

- Prefix GitHub comments with `[via Codex]`.
- When replying to an existing PR review comment, post as a threaded reply, not a new top-level comment.

# External Communication Tools

Treat personal-account communication tools such as Slack or Gmail as read-oriented by default.

- Do not send messages, replies, or emails unless the user explicitly asks.
- Before sending, show the exact text and destination.
- Wait for explicit approval before sending unless the user has already provided the exact text and destination in the same request.

# Configuration Hygiene

Keep local secrets, histories, SQLite databases, caches, sessions, shell snapshots, model caches, installation IDs, and local env files out of git.

Codex may update `~/.codex/config.toml` outside chezmoi, such as trusted projects, feature flags, and UI state. Before applying managed Codex config, review the targeted `chezmoi diff`; reconcile live-only settings into `dot_codex/private_config.toml` or consciously discard them. Use `chezmoi --force apply` only after that review, and only for the specific Codex files being applied.

# Model And Tool Selection

When selecting Codex models, spawning Codex subagents, or invoking Codex-backed tools:

- Do not manually specify the `model` parameter unless the user explicitly requests a specific model.
- Let Codex's global config at `~/.codex/config.toml` select the default model.
- Model fields in tool schemas can be free strings, not complete enums of available models. Do not infer that a model is unavailable from examples in a tool schema.
- If a model override is explicitly requested, use the exact model slug, for example `gpt-5.5`.
- If Codex reports a model error, quote the actual tool or runtime error rather than guessing from the schema.
