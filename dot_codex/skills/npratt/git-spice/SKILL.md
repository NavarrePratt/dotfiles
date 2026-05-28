---
name: git-spice
description: Manage stacked branches with Git-Spice (`gs`). Use when the user asks about stacked PRs, `gs` commands, creating, navigating, restacking, syncing, or diagnosing a Git-Spice stack. Never submit branches or stacks unless the user explicitly approves that remote operation.
---

# Git Spice

Use Git-Spice (`gs`) to manage stacked branches and stacked PR workflows.

## Safety Boundary

Never run a Git-Spice submit command without explicit user approval:

- `gs branch submit`
- `gs stack submit`
- `gs bs`
- `gs ss`
- Any alias or wrapper that submits branches or stacks

Submit commands push branches to a remote and create or update PRs. Before submitting:

1. Show the user which branch or stack will be submitted.
2. Show the commits or stack shape when relevant.
3. Wait for explicit approval such as "yes", "go ahead", or "submit it".
4. Run the submit command only after approval.

Local operations are allowed unless project instructions say otherwise.

## Orientation

Before making stack changes:

```bash
git status
gs log short
```

Use `gs log long` when commit-level context matters. If the repository is not initialized for Git-Spice, ask before running `gs repo init`.

## Core Concepts

- Stack: a linear chain of branches where each branch builds on the previous one.
- Trunk: the target branch, usually `main` or `master`.
- Upstack: branches above the current branch.
- Downstack: branches below the current branch, toward trunk.
- Restacking: rebasing branches to preserve the stack after changes.

## Common Commands

| Task | Command | Alias |
|---|---|---|
| Create stacked branch | `gs branch create NAME -m "message"` | `gs bc` |
| Navigate up | `gs up` | |
| Navigate down | `gs down` | |
| Go to top | `gs top` | |
| Go to bottom | `gs bottom` | `gs b` |
| View stack | `gs log short` | `gs ls` |
| View stack with commits | `gs log long` | `gs ll` |
| Restack after changes | `gs stack restack` | `gs sr` |
| Sync after PR merge | `gs repo sync` | `gs rs` |
| Move branch to new base | `gs branch onto TARGET` | `gs bon` |
| Track existing branch | `gs branch track` | `gs btr` |
| Delete branch | `gs branch delete` | `gs bd` |

Submit commands require approval:

| Task | Command | Alias |
|---|---|---|
| Submit current branch PR | `gs branch submit` | `gs bs` |
| Submit entire stack | `gs stack submit` | `gs ss` |

## Workflow Patterns

Create stacked branches:

```bash
git checkout main
git pull
git add path/to/files
gs branch create feature-part-one -m "Add first part"
git add path/to/other-files
gs branch create feature-part-two -m "Add second part"
```

Make a mid-stack change:

```bash
gs down
git status
git add path/to/files
gs commit create -m "Fix stack issue"
```

Amend a mid-stack commit:

```bash
gs down
git status
git add path/to/files
gs commit amend
```

Resolve a restack conflict:

```bash
git status
# Resolve conflicts.
git add path/to/resolved-files
gs rebase continue
```

Abort a stuck restack:

```bash
gs rebase abort
```

## Practices

- Prefer `gs commit create` and `gs commit amend` over plain `git commit` for stack branches because they restack upstack branches.
- Keep stacks small enough to review comfortably.
- Run `gs repo sync` after PRs merge to clean merged branches and rebase remaining work.
- Use `gs up`, `gs down`, `gs top`, and `gs bottom` instead of manual checkout when moving through a stack.
- Check stack status before changing branches or submitting.
- Treat one branch as one PR unless the user asks for a different structure.
