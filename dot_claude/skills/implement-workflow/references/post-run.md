# Post-Run: Reconcile and Draft the PR

Phase 4 of the skill. The engine has returned its report. Verify the result
against git, reconcile any conformance divergence, resolve the epic status, and
draft the PR. Stop at an approved draft - never push, never open a PR.

## Step 1: Ground-truth sanity check

Trust git, not the report. In the worktree:

```bash
git status --porcelain                         # must be empty
git log --oneline <BASE_REF>..HEAD             # must match the reported commits
```

Then re-run the real verification (`args.verify` build, then test, then lint;
skip empties). All must be green. If the tree is dirty, the commit list does not
match the report, or a verification command fails, stop and investigate before
drafting anything - a clean report over a dirty or non-building tree is a report
to distrust.

## Step 2: Reconcile a conformance divergence first

If the review outcome is `CONFORMANCE DIVERGENCE - RECONCILE BEFORE MERGE`,
surface each conformance finding (from `report.review.conformance`) to the user
before touching the PR. These are never auto-fixed: each names what the code
does and what a design record says, with both reconciliation options. Decide per
divergence with the user whether the code changes to match the record or the
record is amended, and make that change (a doc edit is a valid fix). Only once
the divergences are reconciled do you continue.

## Step 3: Resolve the epic status

Mirror the completion-based resolution. All `br` calls run in the worktree, so
use `--db "$MAIN_REPO_BEADS_DB"`. Re-query every descendant's current status
(re-derive the descendant list with the Phase 1 parent-field scan if needed) -
the report is a convenience, not the source of truth.

- **All descendant leaf beads closed**:

  ```bash
  br --db "$MAIN_REPO_BEADS_DB" close <EPIC_ID> --reason "All beads implemented"
  ```

- **Some skipped, blocked, or in progress**:

  ```bash
  br --db "$MAIN_REPO_BEADS_DB" update <EPIC_ID> --status open --notes "COMPLETED: <list>. SKIPPED: <list with reasons>. BLOCKED: <list>."
  ```

Epic status tracks whether the work is done, not the review outcome. If `br`
fails, warn but do not block the handoff.

## Step 4: Generate the PR title and body

### Title

- <=70 characters on the final serialized title, imperative mood, no trailing
  period, user-visible outcome first.
- Use a Conventional Commits prefix only when the repo clearly expects it -
  sample the base branch: `git log --format=%s --no-merges -n 30 <BASE_REF>` (or
  `origin/<BASE_REF>`). If the signal is mixed, ask the user rather than guess.
- No bead IDs, no internal codenames. Keep substantive references (RFC/AIP/
  standards) - they are part of the subject, not tracking tokens.
- Save to `$ARTIFACT_DIR/$ARTIFACT_BASENAME.txt` as a single normalized line.

### Body

Render [../templates/pr-body.md](../templates/pr-body.md), substituting:

- **CHANGES_SUMMARY**: 2-3 sentences from the epic description - what this PR
  accomplishes and why. Not a list of beads.
- **DESIGN_DECISIONS**: only the rationale not visible in the code (rejected
  alternatives, non-obvious why), sourced from the epic's `## Design Decisions`
  and any implementation-phase decisions in the report. Cut aggressively; do not
  restate the diff. Short blocks separated by blank lines, not bullets.
- **VERIFICATION_RESULTS**: a GitHub-flavored checkbox list of the `args.verify`
  commands. `[x]` for commands that passed; `[ ]` for commands deferred (not
  run). Failures must not appear - the pipeline should have stopped at Step 1.
- **FOLLOW_UP_DISCOVERIES**: aggregate the discovery text from
  `report.discoveries` into a bulleted list. STRIP the bead IDs - beads are
  local-only and must not appear in the PR. Deduplicate. If none, write "None
  identified during implementation."

Save the body to `$ARTIFACT_DIR/$ARTIFACT_BASENAME.md`.

### Present and iterate

Show the title and body to the user. Allow iterative edits and re-save the
affected file after each change. Offer to open the draft for review:
`cursor $ARTIFACT_DIR/$ARTIFACT_BASENAME.md`.

## Step 5: Stop at the approved draft

Once the user approves the draft, STOP. Leave in place:

- the clean feature branch with its per-unit commits,
- the worktree,
- the approved PR title and body in the artifact directory.

Tell the user the branch is ready and that pushing it and opening the PR are
theirs to do. Do NOT push and do NOT run `gh pr create` from this skill, even
after the draft is approved - those are out of scope here.
