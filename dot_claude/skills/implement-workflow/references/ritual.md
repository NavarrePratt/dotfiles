# Ritual: Preconditions and Worktree Setup

Phase 0 and Phase 2 of the skill. Phase 0 checks run in order and stop at the
first failure. Phase 2 sets up the isolated worktree once Phase 1 has confirmed
the plan.

## Phase 0: Preconditions

### Check 1: br CLI available

```bash
which br
```

If missing, stop: `br` is required and not on PATH.

### Check 2: Not already in a worktree

```bash
test -f "$(git rev-parse --show-toplevel)/.git" && echo "worktree" || echo "main-repo"
```

If `worktree`, stop: exit the current worktree first (`ExitWorktree`), then
start again from the main checkout.

### Check 3: Epic ID provided

Parse `$ARGUMENTS`. The first whitespace-delimited token is the epic ID; a
second optional token is the branch name. Record **EPIC_ID**. If absent, stop
with the usage line: `<epic-id> [branch-name]`.

### Check 4: Epic exists

```bash
br show <EPIC_ID> --json
```

If it fails, stop: verify with `br show <EPIC_ID>` or `br list --type epic`.
Record the title as **EPIC_TITLE**.

### Check 5: Epic not already claimed

Read `status` from the `br show` output. If `status == "in_progress"`, another
session may be working this epic. Surface the epic's notes (the claim marker)
and use AskUserQuestion (Abort recommended / Take over only if the other session
is confirmed dead). On Take over, the Phase 2 claim rewrites the notes.

### Check 6: No dependency cycles

```bash
br dep cycles
```

If cycles exist, report them and stop.

### Check 7: Discover BASE_REF

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If empty, fall back to the first existing local branch of `main`, `master`,
`trunk`. Record as **BASE_REF**. If neither resolves, stop and ask the user to
set `refs/remotes/origin/HEAD` or create a default branch. BASE_REF is the base
the worktree branches from and the diff/verify base handed to the engine.

### Check 8: Derive MAIN_REPO_BEADS_DB

Every `br` call after the Phase 2 `cd` targets the main repo database via the
`--db` flag, because `.beads/` is gitignored and absent in the worktree. See
[../../shared/br-in-worktree.md](../../shared/br-in-worktree.md) for the rule.
Derive the path BEFORE the `cd`, while `git rev-parse --show-toplevel` still
points at the main checkout:

```bash
MAIN_REPO_BEADS_DB="$(br where --json 2>/dev/null | jq -r '.database_path // empty' 2>/dev/null || true)"
if [ -z "$MAIN_REPO_BEADS_DB" ]; then
  MAIN_REPO_BEADS_DB="$(git rev-parse --show-toplevel)/.beads/beads.db"
fi
```

Reject shell metacharacters, since the value is rendered verbatim into
downstream Bash (and into the engine's `br` helper):

```bash
case "$MAIN_REPO_BEADS_DB" in
  *[\$\`\"\'\\]*|*$'\n'*)
    echo "Error: repo path contains shell metacharacters; cannot safely derive MAIN_REPO_BEADS_DB"
    exit 1
    ;;
esac
```

Verify the database opens with a real read-only call so Phase 0 fails fast:

```bash
[ -f "$MAIN_REPO_BEADS_DB" ] || { echo "Error: beads db not found at $MAIN_REPO_BEADS_DB"; exit 1; }
br --db "$MAIN_REPO_BEADS_DB" list --limit 1 --json >/dev/null 2>&1 || { echo "Error: cannot open beads database at $MAIN_REPO_BEADS_DB"; exit 1; }
```

Record as **MAIN_REPO_BEADS_DB**.

## Phase 2: Worktree Setup

Run after Phase 1 confirms the plan, so a Cancel never creates a worktree or
claims the epic.

### Step 1: Compute the branch slug

Take the raw input (the branch name from `$ARGUMENTS` if given, else
**EPIC_TITLE**) and slugify it - never pass raw `$ARGUMENTS` through verbatim,
since it flows into shell commands and heredocs:

- lowercase; spaces to hyphens; strip non-alphanumeric/non-hyphen characters;
  collapse repeated hyphens; trim trailing hyphens.

Record as **BRANCH_SLUG**. Also record **REPO_NAME** = `basename "$(git rev-parse
--show-toplevel)"` for the artifact path.

### Step 2: Create the worktree

Check `git worktree list` first; if `.claude/worktrees/implement-workflow-<BRANCH_SLUG>`
already exists, offer reuse or abort. Otherwise:

```bash
git worktree add .claude/worktrees/implement-workflow-<BRANCH_SLUG> -b feat/<BRANCH_SLUG> <BASE_REF>
```

Record the full path as **WORKTREE**. cd into it. All later commands run there.

### Step 3: Claim the epic

```bash
br --db "$MAIN_REPO_BEADS_DB" update <EPIC_ID> --status in_progress --notes "$(cat <<'EOF'
CLAIMED: implement-workflow session on branch feat/<BRANCH_SLUG>
Worktree: <WORKTREE>
EOF
)"
```

If the claim fails (br error, permissions), warn but do not abort - the run can
still proceed; the epic just will not show as `in_progress` to other sessions.

### Step 4: Create the artifact directory

Artifacts (PR title and body) live under `/tmp`, outside the worktree, so they
never dirty git. The path is predictable, so guard against symlink attacks:

```bash
ARTIFACT_DIR="/tmp/<REPO_NAME>-<EPIC_ID>"

if [ -e "$ARTIFACT_DIR" ] || [ -L "$ARTIFACT_DIR" ]; then
  [ -L "$ARTIFACT_DIR" ] && { echo "Error: $ARTIFACT_DIR is a symlink" >&2; exit 1; }
  [ -d "$ARTIFACT_DIR" ] || { echo "Error: $ARTIFACT_DIR exists but is not a directory" >&2; exit 1; }
  [ -O "$ARTIFACT_DIR" ] || { echo "Error: $ARTIFACT_DIR is not owned by current user" >&2; exit 1; }
  chmod 700 "$ARTIFACT_DIR"
else
  mkdir -m 700 "$ARTIFACT_DIR"
fi

if [ -L "$ARTIFACT_DIR" ] || [ ! -d "$ARTIFACT_DIR" ] || [ ! -O "$ARTIFACT_DIR" ]; then
  echo "Error: $ARTIFACT_DIR failed post-creation verification" >&2
  exit 1
fi
```

Record as **ARTIFACT_DIR** and **ARTIFACT_BASENAME** = `<EPIC_ID>-<BRANCH_SLUG>`
(the shared base name for the PR title and body files).
