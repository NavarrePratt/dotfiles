## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD 2>/dev/null || git diff --cached`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "No commits yet"`

## Task

Create logically grouped, atomic commits based on the above context.
Use the git-commit skill for commit message formatting and best practices.
Use partial adds (`git add -p`) when a file contains multiple unrelated changes.

## Surface Open Questions

Before creating commits, reflect on the work just completed and identify any open questions or unresolved decisions:

- Judgment calls made without checking with the user (where another reasonable choice exists)
- Inconsistencies in the codebase noticed but not fixed
- Defaults picked for configuration when multiple options were viable
- Trade-offs that could reasonably go the other way
- Edge cases or missing tests that were deferred

If any genuinely exist, use AskUserQuestion to surface them before committing. Do NOT commit silently and move on - the point is to bring these to the user's attention while context is fresh.

If nothing is genuinely unresolved, proceed directly to commit without inventing questions.

$ARGUMENTS
