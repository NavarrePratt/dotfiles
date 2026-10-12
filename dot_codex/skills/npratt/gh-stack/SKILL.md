---
name: gh-stack
description: Manage stacked branches and stacked PRs with GitHub's `gh stack` CLI extension. Use when the user asks about stacked PRs, `gh stack` commands, creating, navigating, restacking, syncing, submitting, or merging a stack, or splitting large work into dependent PRs. Never run a remote-writing `gh stack` command unless the user explicitly approves that remote operation.
---

# gh stack

Use GitHub's `gh stack` extension (`github/gh-stack`) to manage stacked branches and their PRs. A stack is a linear chain of branches rooted on a trunk such as `main`. Each branch has one PR, and that PR's base is the branch below it.

- Bottom: the branch closest to trunk. It merges first.
- Top: the branch furthest from trunk. It merges last.
- Up moves toward the top. Down moves toward trunk.

This skill adapts GitHub's agent skill at https://github.com/github/gh-stack/tree/main/skills/gh-stack. Its `references/troubleshooting.md` has worked recovery examples. `gh stack <command> --help` is authoritative for flags. `gh stack help <command>` prints only the top-level help.

## Prerequisites

The dotfiles `run_after_install-gh-stack.sh` script installs the extension. If `gh stack --version` fails, install it with `gh extension install github/gh-stack`.

If the repository has more than one remote, set `git config remote.pushDefault origin` or pass `--remote <name>` to `push`, `submit`, `sync`, `rebase`, and `link`.

## Operation Boundary

Run these local operations without approval unless project instructions say otherwise:

- `gh stack view`, `init`, `add`, `up`, `down`, `top`, `bottom`, `trunk`
- `gh stack checkout <target>` (fetches, never pushes)
- `gh stack rebase`, including `--continue` and `--abort` (fetches, never pushes)
- `gh stack unstack --local`

Treat these commands as remote writes:

- `gh stack submit`: pushes every branch, creates PRs, changes PR bases, and links the stack.
- `gh stack push`: force-pushes every active branch with `--force-with-lease`.
- `gh stack sync`: force-pushes every branch. There is no pull-only mode.
- `gh stack link`: pushes branches, creates missing PRs, and links the stack.
- `gh stack merge`: merges PRs.
- `gh stack unstack` without `--local`: removes the stack grouping on GitHub.
- `gh pr edit`: changes PR titles or bodies.

Before a remote write:

1. Show the exact command.
2. Show the stack (`gh stack view --short`), the destination remote, the commits in each branch, and the expected PR effect. State when the command force-pushes.
3. Wait for explicit approval.
4. Run only the approved command.

## Run Non-Interactively

`gh stack` opens prompts or full-screen editors when stdout is a terminal, and the command can hang in an agent shell. Always use the explicit form:

| Use | Do not use | Reason |
|---|---|---|
| `gh stack view --json` or `--short` | `gh stack view` | Opens an interactive view |
| `gh stack submit --auto --open` | `gh stack submit` | Opens the PR editor |
| `gh stack init <branch>...` | `gh stack init` | Prompts for branch names |
| `gh stack add <branch>` | `gh stack add` | Prompts for a name |
| `gh stack checkout <target>` | `gh stack checkout` | Opens a picker |
| `gh stack up`, `down`, `top`, `bottom` | `gh stack switch` | Picker only |
| `gh stack merge <target> --yes` | `gh pr merge` | `gh pr merge` cannot merge a stack |
| none | `gh stack modify` | Full-screen editor only |

If a stack is left in an interrupted `modify` session (exit 10), run `gh stack modify --abort`.

## Read Stack State

Start with:

```bash
git status --short --branch
gh stack view --json
```

`view --json` writes JSON to stdout and status messages to stderr. Branch on the exit code, not on stderr text.

```text
trunk           string
currentBranch   string
branches[]      name, head, base, isCurrent, isMerged, isQueued, needsRebase
branches[].pr   number, url, state ("OPEN" | "MERGED" | "QUEUED"); absent when no PR exists
```

`branches[]` is ordered bottom to top. `base` is a commit SHA, not a branch name. A branch's parent is the previous array entry, or `trunk` for the first entry. `needsRebase` is true when the parent tip is no longer in the branch history.

| Exit | Meaning | Action |
|---|---|---|
| 2 | Current branch is not in a stack | `gh stack init` or `gh stack checkout <target>` |
| 3 | Rebase conflict | Resolve as described below |
| 4 | GitHub API failure | Check `gh auth status` and retry |
| 6 | Branch is in several stacks | Check out a branch that belongs to one stack |
| 7 | Rebase already in progress | `gh stack rebase --continue` or `--abort` |
| 8 | Stack file locked | Wait a few seconds and retry; do not delete lock files |
| 9 | Stacked PRs unavailable in this repository | Tell the user |

## Workflows

Create a stack:

```bash
git switch main
git pull --ff-only
gh stack init feature-part-one
git add path/to/files
git commit -m "Add first part"
gh stack add feature-part-two
git add path/to/other-files
git commit -m "Add second part"
```

`gh stack add` works only from the top branch. Branch names are used verbatim.

Change a lower branch:

```bash
gh stack checkout feature-part-one
git add path/to/files
git commit -m "Fix first part"   # or: git commit --amend --no-edit
gh stack rebase --upstack
gh stack top
```

Commit each change on the branch that owns its concern. `gh stack rebase` refuses to run while the worktree has uncommitted or untracked files. Use `--no-trunk` to rebase only between stack branches, without fetching trunk.

Resolve a rebase conflict (exit 3):

```bash
git status
# Resolve conflicts.
git add path/to/resolved-files
gh stack rebase --continue
```

`gh stack rebase --abort` restores every branch in the stack. If `gh stack sync` reports a conflict, it has already restored all branches. Run `gh stack rebase` to reproduce the conflict, then resolve it as above.

Adopt existing branches, including stacks created with another tool:

```bash
gh stack init --base main branch-one branch-two branch-three   # bottom to top
```

## Submit and Describe PRs

Submitting is a remote write. Create PRs as ready for review unless the user asks for drafts:

```bash
gh stack submit --auto --open
```

Without `--open`, `--auto` creates draft PRs. `--open` also marks existing PRs in the stack as ready for review.

`gh stack submit` generates PR titles and bodies, and it has no body flag. Draft a meaningful title and body for each new PR before submitting. Show them in the same approval request as the submit command. After submitting, apply them:

```bash
gh pr edit <number> --title "Title" --body-file path/to/body.md
```

## After a PR Merges

`gh stack sync --prune` is the documented path, and it is a remote write. It fetches, fast-forwards trunk, rebases the remaining branches past merged PRs, force-pushes, refreshes PR state, and deletes local branches for merged PRs. Squash merges need no manual handling.

If `gh stack sync` prints `Sync aborted`, the local and remote stacks have diverged and nothing changed. The exit code is still 0. Report the two chains to the user and ask which side to keep.

To update locally without pushing, run `gh stack rebase`, then push later with approval.

## Merge a Stack

Merging is a remote write:

```bash
gh stack merge <pr-number> --yes --squash   # that PR and every unmerged PR below it
gh stack merge <stack-number> --yes         # every unmerged PR in the stack
```

The merge is all-or-nothing. Without a method flag, it reuses the last method. If the base branch uses a merge queue, the stack is queued, and the queue chooses the method.

## Restructure a Stack

There is no non-interactive way to reorder, insert, rename, or remove branches. `gh stack add` works only from the top branch.

1. Rewrite Git ancestry first with `git rebase --onto`. Record the old boundary SHAs before you move any branch.
2. Rebuild the stack metadata:

   ```bash
   gh stack unstack                                  # remote write: removes the GitHub grouping
   gh stack init --base main branch-one new-branch branch-two
   gh stack submit --auto --open                     # remote write: re-links the stack
   ```

Unstacking keeps PRs and branches. `init` adopts existing branches.

## Constraints

- Stacks are linear: each branch has one parent and at most one child. Use separate stacks for parallel work.
- Stacks across forks are not supported.
- `gh stack push` is not atomic: some branches can update while others are rejected. `gh stack sync` pushes atomically.
- CI runs for every PR in the stack.

## Practices

- Keep one reviewable concern per branch and one PR per branch.
- Keep stacks small enough to review comfortably.
- Check stack state before you change branches or run a remote write.
- Write PR descriptions that explain motivation and context. Do not rely on generated summaries.
