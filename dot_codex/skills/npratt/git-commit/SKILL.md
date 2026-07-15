---
name: commit
description: Create logically grouped, atomic local git commits with well-formatted commit messages. Use when the user asks to commit changes, run a commit workflow, or use /commit-style behavior. Before committing, inspect current changes and recent history, group changes intentionally, and surface unresolved decisions when they materially affect the commit.
---

# Git Commit Skill

Create well-structured, atomic local git commits with commit messages that match the repository's existing style.

## Process

1. Inspect current state:
   - Run `git status`
   - Run `git diff HEAD` for unstaged and staged changes
   - Run `git log --oneline -20` to understand recent commit style
2. Identify logical groups:
   - Keep each commit to one coherent change
   - Use `git add -p` when one file contains unrelated changes
   - Do not include generated/runtime files, secrets, histories, caches, SQLite DBs, or unrelated local edits
3. Surface unresolved decisions before committing:
   - Ask the user about material judgment calls, deferred edge cases, unclear defaults, or tradeoffs that could reasonably go another way
   - Do not block on low-risk implementation details that are already clear from the approved task
4. Stage and commit each group:
   - Prefer `git commit -m "Subject"` for subject-only commits
   - Use a body only when it explains why or a non-obvious consequence
   - Verify each commit with `git show --stat --oneline HEAD`
5. Finish with `git status` and report the commit SHA(s).

Stop after creating and verifying local commits. Treat publishing those commits as a separate operation governed by the global Remote Operations policy.

## Message Style

Always check recent history first. Consistency with the repository is more important than personal preference.

If recent history uses conventional commits for most commits, use:

```text
type(optional-scope): description
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.

If recent history does not use conventional commits, use a traditional imperative subject:

```text
Add user authentication middleware
```

## Message Rules

- Keep the subject concise, ideally 50 characters or fewer.
- Use imperative mood: "Add", "Fix", "Remove", "Update".
- Do not end the subject with a period.
- Default to no body.
- Add a body only for why or a non-obvious consequence that the subject and diff do not explain.
- When a body is needed, keep it to one short paragraph unless the change is unusually risky.
- Do not turn the commit body into a PR description.
- Do not list files, functions, helpers, or implementation walkthroughs.
- Do not enumerate tests added or recap what each test asserts.
- Do not include exact counts of tests, files, functions, endpoints, or similar items.

## Examples

Good traditional subjects:

- `Manage shell and Codex config with chezmoi`
- `Remove deprecated user service methods`
- `Fix login nil pointer handling`

Good conventional subjects:

- `feat: add user authentication middleware`
- `fix: resolve login nil pointer`
- `docs: update API usage notes`
- `chore: remove deprecated user service methods`

Bad subjects:

- `fixed stuff`
- `Changes`
- `wip`
- `Update file.js`
- `feat added new feature`
- `Add 7 tests for auth module`
- `Update 3 config files for logging`

## ANSI Safety

Commit messages must be plain ASCII. Do not copy colored terminal output into commit messages. If ANSI escape codes appear in `git log`, rewrite the message before continuing.

Check the latest commit message:

```bash
git log -1 --format=%B | grep -c $'\x1b'
```

`0` means the message is clean.
