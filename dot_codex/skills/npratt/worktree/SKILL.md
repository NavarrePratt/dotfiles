---
name: worktree
description: Create and manage project-local Git worktrees under `.codex/worktrees/` for PR review, branch inspection, or edit work. Use when the user asks to review or work on a PR, branch, ref, or Git worktree while keeping worktrees inside the current repository and avoiding GitHub writes or pushes.
---

# Project-Local Git Worktrees

Create Git worktrees under the current repository root:

```text
.codex/worktrees/<slug>/
```

Use this for PR review, branch inspection, or edit work when the user wants an isolated checkout. Do not create sibling worktrees under `~/git` unless the user explicitly asks.

## Safety Boundary

- Never push, create PRs, post comments, submit Git-Spice branches, or perform any GitHub write operation as part of this skill.
- Add `.codex/worktrees/` only to the current repository's local Git exclude file, never to tracked `.gitignore` unless the user explicitly asks.
- Use `git rev-parse --show-toplevel` to resolve the current repo root.
- Use `git rev-parse --git-path info/exclude` to resolve the local exclude file because `.git` may be a file in linked worktrees.
- If the parent checkout has unrelated changes, report them and leave them alone.
- If the target worktree path already exists, inspect and report it. Do not overwrite, delete, or move it automatically.
- For review-only PR work, default to detached HEAD at the fetched PR head unless the user asks for a local branch.
- For edit or commit work, create or use an explicit local branch only after stating the branch name.

## Setup

Resolve the repo root and prepare the project-local worktree directory:

```bash
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
mkdir -p .codex/worktrees
```

Ensure the local exclude file has exactly one worktree ignore entry while preserving other local excludes:

```bash
exclude_file=$(git rev-parse --git-path info/exclude)
mkdir -p "$(dirname "$exclude_file")"
touch "$exclude_file"
entry='.codex/worktrees/'
tmp=$(mktemp)
awk -v entry="$entry" '
  $0 == entry {
    if (!seen++) print
    next
  }
  { print }
  END {
    if (!seen) print entry
  }
' "$exclude_file" > "$tmp" && mv "$tmp" "$exclude_file"
```

Check the parent checkout before creating a worktree:

```bash
git status --branch --short
```

If this shows unrelated changes, tell the user they exist and continue only if the requested worktree operation does not need to modify them.

## Target Slugs

Use stable, predictable paths:

- PRs: `.codex/worktrees/pr-<number>`
- Branches or refs: `.codex/worktrees/<sanitized-branch>`

Sanitize branch/ref names for path use:

```bash
slug=$(printf '%s' "$target_ref" | tr '/:@ ' '----' | tr -cd 'A-Za-z0-9._-')
worktree_path="$repo_root/.codex/worktrees/$slug"
```

Before creating a worktree, always check for collisions:

```bash
if [ -e "$worktree_path" ]; then
  git worktree list
  git -C "$worktree_path" status --branch --short 2>/dev/null || ls -la "$worktree_path"
  printf 'Target worktree path already exists: %s\n' "$worktree_path"
fi
```

If the path exists, stop and report what is there. Do not overwrite or delete it automatically.

## GitHub PR Workflow

Accept PR URLs or numbers. Extract the number from common GitHub PR URLs:

```bash
pr_number=123
# or, from a URL:
pr_number=$(printf '%s\n' "$pr_url" | sed -nE 's#.*github.com/[^/]+/[^/]+/pull/([0-9]+).*#\1#p')
```

Prefer read-only remote resolution:

```bash
git ls-remote origin "refs/pull/$pr_number/head"
```

If `refs/pull/<number>/head` exists, fetch the PR head without writing remotely:

```bash
git fetch origin "refs/pull/$pr_number/head:refs/remotes/origin/pr/$pr_number"
```

For review-only work, create a detached worktree:

```bash
worktree_path="$repo_root/.codex/worktrees/pr-$pr_number"
git worktree add --detach "$worktree_path" "refs/remotes/origin/pr/$pr_number"
```

If `refs/pull/<number>/head` is not available or the remote is not GitHub, use `gh pr view` only for read-only resolution:

```bash
head_ref=$(gh pr view "$pr_number" --json headRefName -q '.headRefName')
head_repo=$(gh pr view "$pr_number" --json headRepository -q '.headRepository.nameWithOwner')
```

Then fetch the head branch explicitly, still without posting or writing remotely:

```bash
git fetch "https://github.com/$head_repo.git" "$head_ref"
git worktree add --detach "$worktree_path" FETCH_HEAD
```

For edit work on a PR, state the local branch name before creating it:

```bash
branch_name="codex/pr-$pr_number"
git worktree add -b "$branch_name" "$worktree_path" "refs/remotes/origin/pr/$pr_number"
```

If the branch already exists, inspect it before reuse:

```bash
git show-ref --verify --quiet "refs/heads/$branch_name" && git log --oneline -5 "$branch_name"
```

When reusing an existing local branch after inspection, omit `-b`:

```bash
git worktree add "$worktree_path" "$branch_name"
```

## Branch Or Ref Workflow

For branch or ref review, fetch or resolve without writing remotely:

```bash
target_ref="feature/example"
git fetch origin "$target_ref"
```

For review-only branch work, use detached HEAD:

```bash
slug=$(printf '%s' "$target_ref" | tr '/:@ ' '----' | tr -cd 'A-Za-z0-9._-')
worktree_path="$repo_root/.codex/worktrees/$slug"
git worktree add --detach "$worktree_path" FETCH_HEAD
```

For local edit or commit work, state the local branch name before creating or using it:

```bash
branch_name="codex/$slug"
git worktree add -b "$branch_name" "$worktree_path" FETCH_HEAD
```

If that local branch already exists, inspect it before reuse and omit `-b`:

```bash
git show-ref --verify --quiet "refs/heads/$branch_name" && git log --oneline -5 "$branch_name"
git worktree add "$worktree_path" "$branch_name"
```

If the requested ref is already local and does not need fetching:

```bash
git rev-parse --verify "$target_ref"
git worktree add --detach "$worktree_path" "$target_ref"
```

## Verification

After creating a worktree, verify both checkouts:

```bash
git worktree list
git -C "$repo_root" status --branch --short
git -C "$worktree_path" status --branch --short
```

Report the final worktree path and use that path for all subsequent commands.

## Cleanup

List worktrees before cleanup:

```bash
git worktree list
```

Remove a worktree only when explicitly requested:

```bash
git -C "$worktree_path" status --branch --short
git worktree remove "$worktree_path"
```

Never remove a dirty worktree without showing its status and getting explicit approval.

Move an existing sibling worktree into `.codex/worktrees/` only when explicitly requested:

```bash
old_path="/path/to/existing/worktree"
new_path="$repo_root/.codex/worktrees/<slug>"
git -C "$old_path" status --branch --short
git worktree move "$old_path" "$new_path"
```

If the old worktree is dirty or the new path exists, stop and ask before proceeding.
