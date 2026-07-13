---
name: git-spice
description: Manage stacked branches with Git-Spice (`gs`). Use when the user asks about stacked PRs, `gs` commands, creating or navigating stack branches, restacking, syncing, or diagnosing a Git-Spice stack. Never submit branches or stacks unless the user explicitly approves that remote operation.
---

# Git-Spice

Use Git-Spice to manage stacked branches and PR workflows.

## Protect Remote Operations

Never run a submit command without explicit user approval:

- `gs branch submit` or `gs bs`
- `gs stack submit` or `gs ss`
- Any alias or wrapper that submits branches or stacks

Before submitting:

1. Show the user which branch or stack will be submitted.
2. Show the relevant commits or stack shape.
3. Wait for explicit approval such as "yes", "go ahead", or "submit it".

Treat local Git-Spice operations as allowed unless project instructions say otherwise. Ask before initializing Git-Spice in a repository with `gs repo init`.

## Establish Stack State

Start with:

```bash
git status --short --branch
gs log short
```

Use `gs log long` when commit-level context matters. Consult `gs --help` or the relevant subcommand help before relying on a remembered flag.

## Common Operations

- Create a stack branch: `gs branch create NAME -m "message"`
- Navigate: `gs up`, `gs down`, `gs top`, or `gs bottom`
- Restack: `gs stack restack`
- Create or amend a stack commit: `gs commit create` or `gs commit amend`
- Move a branch: `gs branch onto TARGET`
- Track an existing branch: `gs branch track`
- Sync after merges: `gs repo sync`

When resolving restack conflicts, inspect `git status`, resolve and stage files, then use `gs rebase continue`. Use `gs rebase abort` to abandon the restack.

Prefer one reviewable concern per branch and one PR per branch. Draft a meaningful PR description; do not rely on generated commit-message summaries as a substitute for motivation and context.
