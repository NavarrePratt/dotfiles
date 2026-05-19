---
name: watch-pr
description: Monitor an existing GitHub pull request with read-only GitHub checks, transition-based polling, and optional linked ExecPlan artifact updates. Use when the user asks to watch, monitor, keep an eye on, or poll an existing PR without posting comments, pushing, or otherwise writing to GitHub.
---

# Watch PR

Monitor an existing GitHub pull request and report meaningful lifecycle
transitions locally. When a local ExecPlan is linked, update that plan's local
status evidence and artifacts without performing any GitHub or remote write.

This is a continuous-first workflow. If the user only wants a one-time current
state check, collect one snapshot, summarize it, and stop.

## Safety Boundary

- Never push, create PRs, post comments, add reviews, add reactions, label PRs,
  enable auto-merge, update refs, rerun workflows, merge, close, reopen, or
  perform any other GitHub write operation.
- Never use GitHub connector write tools from this skill.
- Use only read-only `gh`, GitHub connector, git, and local filesystem
  operations.
- Local writes are allowed only for linked ExecPlan files and artifacts under
  `.codex/plans/<slug>/`, or for private temporary state when no plan is linked.
- Do not mark a linked plan `done`. Prompt the user to run `finish-plan` when
  the PR lifecycle appears complete.
- Do not run `finish-plan` automatically.
- Do not create or update `br` issues as a second source of truth.
- If the user asks to fix code, reply to review comments, push, rerun CI, merge,
  or publish anything, stop the watch and hand off to an explicit workflow with
  its own approval boundary.

## Accepted Inputs

Accept these target forms:

- PR URL: `https://github.com/<owner>/<repo>/pull/<number>`
- PR number: `123`, `#123`, or `PR #123`
- Current branch PR: "watch this PR", "monitor the current branch PR"
- Plan path: `.codex/plans/<slug>.md`

Explicit user input wins over automatic discovery. Stop and ask for a clearer
target when more than one PR is plausible, or when a bare PR number is provided
outside a GitHub checkout and no repository scope is available.

## Preflight

Resolve the local repository root when operating in a checkout:

```bash
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
```

Inspect local state before selecting the target:

```bash
git status --branch --short
```

Report unrelated local changes and leave them alone.

When a plan path is provided, verify local-only storage:

```bash
git check-ignore -v .codex/plans/example.md .codex/worktrees/example
```

If either path is not ignored through the local exclude file, warn before
writing artifacts. Keep the plan's top-level Markdown file as the source of
truth.

Check `gh` authentication before relying on `gh` reads:

```bash
gh auth status
```

If `gh` auth fails, use available GitHub connector read tools when possible.
When no read path can identify the PR and its lifecycle state, stop with a clear
read blocker. For a linked plan, write the read failure to `pr-status.md` if the
artifact directory is safe to use.

Record the resolved identity before polling:

- repository in `owner/name` form
- PR number and PR URL
- base ref and head ref
- head SHA
- linked plan path, if any
- artifact directory, if any
- state directory and state file

## Target Resolution

### PR URL

Parse owner, repo, and number from the URL:

```bash
pr_url="https://github.com/owner/repo/pull/123"
repo=$(printf '%s\n' "$pr_url" | sed -nE 's#https://github.com/([^/]+/[^/]+)/pull/[0-9]+.*#\1#p')
pr_number=$(printf '%s\n' "$pr_url" | sed -nE 's#https://github.com/[^/]+/[^/]+/pull/([0-9]+).*#\1#p')
```

Use `-R "$repo"` for all `gh` PR commands.

### PR Number

Resolve the repository from the current checkout:

```bash
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

If that fails and the user did not provide repo scope, ask for the PR URL or
`owner/repo#number`.

### Current Branch

Use the current checkout to resolve the associated PR:

```bash
gh pr view --json number,url,headRefName,headRepository,baseRefName,state
```

If no PR is associated with the branch, ask for a PR URL or number.

### Plan Path

Resolve the plan path before changing directories:

```bash
plan_path=$(realpath .codex/plans/<slug>.md)
plan_repo_root=$(git rev-parse --show-toplevel)
artifact_dir="${plan_path%.md}"
```

Read the plan status block, active worktree, progress log, and existing
artifacts. Search the plan and artifacts for PR URLs:

```bash
rg -n 'https://github.com/[^[:space:])]+/[^[:space:])]+/pull/[0-9]+' "$plan_path" "$artifact_dir" 2>/dev/null
```

If the plan has an active worktree and it exists, prefer that checkout for
current-branch PR discovery:

```bash
git -C "$plan_repo_root/.codex/worktrees/<slug>" status --branch --short
gh pr view --json number,url,headRefName,headRepository,baseRefName,state
```

If the plan contains multiple plausible PR URLs, ask the user which one to
watch.

## GitHub Read Strategy

Use hybrid read sources:

- Prefer GitHub connector reads for structured PR metadata, patch, comments,
  changed filenames, diffs, commit statuses, and summaries when the repository
  and PR number are known.
- Use `gh` for current-branch PR discovery, latest check details, Actions logs,
  GraphQL review-thread state, deployments, releases, and any state where local
  checkout context matters.
- Prefer the freshest `gh` data for checks, logs, and review-thread lifecycle
  decisions.
- Record source and timestamp in artifacts when connector and `gh` data are
  combined.

Primary PR metadata:

```bash
pr_fields="number,url,title,author,state,closed,closedAt,mergedAt,mergedBy,isDraft,baseRefName,baseRefOid,headRefName,headRefOid,headRepository,isCrossRepository,mergeable,mergeStateStatus,potentialMergeCommit,autoMergeRequest,reviewDecision,latestReviews,reviews,reviewRequests,statusCheckRollup,labels,updatedAt"
gh pr view "$pr_number" -R "$repo" --json "$pr_fields"
```

Check details:

```bash
check_fields="bucket,completedAt,description,event,link,name,startedAt,state,workflow"
gh pr checks "$pr_number" -R "$repo" --json "$check_fields"
```

`gh pr checks` can return exit code `8` while checks are pending. Treat that as
readable pending state when JSON output is available.

Read REST endpoints with explicit `GET` when using `gh api` fields:

```bash
gh api --method GET --paginate "repos/$repo/pulls/$pr_number/comments"
gh api --method GET --paginate "repos/$repo/issues/$pr_number/comments"
gh api --method GET --paginate "repos/$repo/deployments"
gh api --method GET --paginate "repos/$repo/releases"
```

Use GraphQL for review threads because flat comment APIs do not preserve enough
thread lifecycle state:

```bash
gh api graphql -f owner="$owner" -f name="$name" -F number="$pr_number" -f query='
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 20) {
            nodes {
              id
              author { login }
              createdAt
              bodyText
            }
          }
        }
      }
    }
  }
}'
```

Use `gh run view --log-failed` only when a run id or job id can be resolved from
check links or workflow-run queries. If logs cannot be fetched, record the
failing check name, state, workflow, and link.

## Snapshot Data

Each snapshot should normalize these fields:

- PR identity: `repo`, `number`, `url`, `title`, `author`, `baseRefName`,
  `baseRefOid`, `headRefName`, `headRefOid`, `headRepository`,
  `isCrossRepository`, and `updatedAt`
- PR state: `state`, `closed`, `closedAt`, `mergedAt`, `mergedBy`, `isDraft`
- Merge state: `mergeable`, `mergeStateStatus`, `potentialMergeCommit`,
  `autoMergeRequest`, and merge queue or branch protection signals when visible
- Review state: `reviewDecision`, latest non-pending reviews, review requests,
  unresolved non-outdated review threads, and top-level PR comments
- CI state: `statusCheckRollup` plus `gh pr checks` details
- Lifecycle extensions: deployment, release, tag, or rollout status only when
  the plan, PR checks, or explicit user instruction makes them relevant

Normalize status buckets to:

- `pass`
- `fail`
- `pending`
- `skipped`
- `cancelled`
- `unknown`

Keep raw check names and links in artifacts.

## Polling Model

Default interval: `60` seconds. Minimum interval: `30` seconds. Clamp smaller
values to `30` and tell the user why.

Do not rely on `gh pr checks --watch` alone. It does not cover reviews, merge
state, comments, deployments, or closed and merged transitions.

Maintain a state file and compare snapshots:

- With a plan: `.codex/plans/<slug>/watch-state.json`
- Without a plan: a private temporary directory, for example from
  `mktemp -d "${TMPDIR:-/tmp}/codex-watch-pr-${safe_repo}-${pr_number}.XXXXXX"`

Verify ownership before writing any temporary state:

```bash
state_owner=$(stat -f %u "$state_dir" 2>/dev/null || stat -c %u "$state_dir")
test "$state_owner" = "$(id -u)"
```

If a durable monitor or background process tool is available, use it. Otherwise
run a foreground polling loop in a long-running shell session that can be
stopped cleanly. Track the session id or process id in the local conversation
state and do not leave orphaned processes behind.

Emit user-visible updates only on meaningful transitions:

- newly failing, cancelled, or timed-out check
- all checks newly passing
- new review submitted
- requested changes appearing or clearing
- new unresolved actionable review thread
- merge conflict appearing
- PR merged
- PR closed without merge
- deployment, release, or rollout blocker appearing or clearing
- repeated read failures crossing a clear threshold

Do not print repeated "still pending", "still failing", or "still waiting"
messages for unchanged state.

Stop on terminal PR states unless the user explicitly asks to keep watching
rollout, release, or post-merge follow-up. If the user says to stop watching,
stop the polling process cleanly and report the latest known state.

## Event Handling

### Failing Checks

Detect newly failed required checks and cancelled or timed-out checks. Write or
update `ci-findings.md` with:

- check name
- normalized bucket and raw state
- workflow
- link
- completion time
- log summary when available
- likely next action: inspect logs, run a local test, wait for a rerun, or fix
  in a separate explicit workflow

Do not rerun workflows.

### Passing Checks

Detect transition from non-green to green for required checks. Update
`pr-status.md` and `ci-findings.md`. Keep a linked plan `in_progress` unless
another PR lifecycle signal is blocked or complete.

### Review Activity

Detect new reviews, changes to `reviewDecision`, requested changes, review
requests, and unresolved actionable review threads.

Treat `CHANGES_REQUESTED` and unresolved actionable review threads as blocked PR
lifecycle states. Write `review-status.md` with:

- reviewers and latest decisions
- requested changes
- unresolved thread count
- resolved or outdated thread caveats
- review requests
- actionable comment summaries

Do not reply, submit reviews, approve, request changes, or mark threads
resolved.

### Merge Conflicts

Detect `mergeable: CONFLICTING` or merge-state signals that clearly indicate
conflicts. For linked plans, set `State: blocked` and record `Blocker class:
pr` in `pr-status.md`. The next action is an explicit rebase or merge-conflict
resolution workflow. Do not push a rebased branch.

### Merged PR

Record merge evidence in `pr-status.md`:

- URL
- merged time
- merged by
- merge commit if available
- checks and review state at merge
- remaining deployment, release, rollout, documentation, or follow-up checks

If no remaining lifecycle checks are known, prompt the user to run:

```text
$finish-plan .codex/plans/<slug>.md
```

Do not mark the plan done.

### Closed Without Merge

For linked plans, set `State: blocked` and record `Blocker class: pr` in
`pr-status.md`. Record next action choices: reopen, replace PR, abandon plan, or
update plan scope. Do not delete local branches or worktrees.

### Deployments, Releases, And Rollout

Inspect deployment, release, and rollout signals only when relevant:

- the linked plan mentions deploy, deployment, release, rollout, tag,
  environment validation, documentation publication, or post-merge follow-up
- PR checks expose an obvious deployment or release blocker
- the user explicitly asks to watch those signals

Write findings to `rollout-notes.md`. If a required signal fails, set the
linked plan to `blocked`. If it is merely pending, keep the plan `in_progress`.

## Linked ExecPlan Updates

When a plan path is provided, mutate only the local plan and local artifacts.

Top-level plan updates:

- Record the PR URL in the progress log when first linked.
- Update `State` to `blocked` only for action-needed PR states.
- Update `State` back to `in_progress` when the PR blocker clears and lifecycle
  completion is not yet established.
- Update `Last updated` whenever the status block or progress log is written.
- Add concise progress log entries only for meaningful lifecycle transitions.
- Do not alter milestones unless the user explicitly asks.

Use exact ExecPlan state values only:

- `in_progress`
- `blocked`

Do not write typed states such as `blocked:pr`.

Use `State: blocked` with `Blocker class: pr` in artifacts when:

- a required check fails, times out, or is cancelled
- requested changes are active
- unresolved actionable review threads exist
- merge conflicts exist
- the PR is closed without merge
- a required deployment, release, or rollout signal fails
- GitHub read failures prevent a required lifecycle decision and cannot be
  bypassed with user confirmation

Use `State: in_progress` when:

- checks are pending
- review is pending or approvals are missing
- the PR is draft
- mergeability is unknown
- the PR is in a merge queue or waiting for branch protection
- deployment, release, or rollout signals are pending but not failed
- the PR has merged but `finish-plan` has not verified full lifecycle

Prompt to run `finish-plan` when:

- the PR is merged
- required checks were passing at merge or the merge queue accepted the PR
- required review blockers are resolved
- plan-named deployment, release, rollout, documentation, or follow-up checks
  are complete or explicitly out of scope

## Artifact Formats

Create the artifact directory only when a plan is linked:

```bash
mkdir -p "$artifact_dir"
```

Use these stable files:

```text
.codex/plans/<slug>/pr-status.md
.codex/plans/<slug>/ci-findings.md
.codex/plans/<slug>/review-status.md
.codex/plans/<slug>/rollout-notes.md
.codex/plans/<slug>/watch-state.json
```

`pr-status.md` should include:

- snapshot timestamp and read sources
- PR identity
- lifecycle state
- blocker class, if blocked
- next required action
- mergeability
- review decision
- check summary
- deployment, release, or rollout summary when in scope
- whether `finish-plan` appears appropriate

`ci-findings.md` should include current and recent check failures, log summaries,
links, and local follow-up commands if known.

`review-status.md` should include approvals, requested changes, unresolved review
threads, review requests, latest comments, and actionable review items.

`rollout-notes.md` should include deployment, release, rollout, or post-merge
follow-up signals when in scope. If these signals are out of scope, say so
briefly instead of querying every deployment or release endpoint.

Artifacts are evidence. The top-level plan remains the source of truth.

## Dry Run

For a manual read-only dry run:

1. Resolve the target and identity.
2. Run preflight, including `gh auth status` or connector read availability.
3. Collect one PR snapshot, check summary, and review-thread summary.
4. If a plan is linked, write or update the local artifact files and add one
   concise progress entry when the PR is first linked or a meaningful transition
   is observed.
5. Confirm no GitHub writes, pushes, workflow reruns, comments, reviews, labels,
   merges, or remote branch updates occurred.
6. Stop without starting a polling loop unless the user asked to continue
   watching.

## Handoff

When stopping or handing off, report:

- PR URL and latest state
- linked plan path, if any
- artifact paths written, if any
- watch state file path
- latest blocker class and next action
- whether polling is still running
- whether `finish-plan` appears appropriate

If lifecycle completion appears likely, suggest:

```text
$finish-plan .codex/plans/<slug>.md
```

Only suggest it after reporting the evidence. Do not invoke it automatically.
