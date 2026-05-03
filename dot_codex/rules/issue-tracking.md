# Issue Tracking with br

Track work with `br` for persistent context across sessions.

## Quick Commands

| Task | Command |
|------|---------|
| Find ready work | `br ready --json` |
| Start work | `br update br-xxx --status in_progress --json` |
| Checkpoint | `br update br-xxx --notes "COMPLETED: ...\nNEXT: ..." --json` |
| Complete work | `br close br-xxx --reason "..." --json` |
| View details | `br show br-xxx --json` |
| Add dependency | `br dep add br-A br-B --type blocks` (A depends on B) |

## Create Issue

Bead descriptions use a structured template with `## ` (double-hash) headings. The implementer's parser depends on this heading level - do not use `# ` single-hash.

**Required core sections** (always present): Goal, Why, Design, Files, Acceptance Criteria, Verification.

**Optional extras** (include when planning surfaced the content, omit otherwise): Patterns to Follow, Test Strategy, Out of Scope, Gotchas, Cross-bead Notes.

```bash
br create --title "Title" --description "$(cat <<'EOF'
## Goal
[One sentence - the outcome, not the task.]

## Why
[2-4 sentences - motivation, link to broader work.]

## Design
[Technical approach. For non-trivial choices, note alternatives considered and why this path won.]

## Files
- path/to/file.ext:45-120 - [why this file, what changes here]

## Acceptance Criteria
- [ ] [testable boolean condition]

## Verification
- [ ] `[lint command]` passes
- [ ] `[test command]` passes

If implementation reveals new issues, create separate issues for investigation.
EOF
)" --json
```

Target description length: 250-1000 words. A one-paragraph description means the plan was incomplete - investigate before creating. Include verification discovery, epic creation, dependency sequencing, and a pre-publish self-check when planning a larger bead set.

### Deferred Status for Batch Creation

When creating multiple beads under an epic, use `--status deferred` to prevent them from being picked up before dependencies are set:

```bash
# Create beads in deferred status
br create "First task" --status deferred --description "..." --json
br create "Second task" --status deferred --description "..." --json

# Set up dependencies
br dep add br-001 br-002 --type blocks

# Publish all beads when ready
br update br-001 --status open
br update br-002 --status open
```

This ensures automation will not pick up any beads until the entire plan is ready and properly sequenced.

**CRITICAL: No ANSI escape codes in issues.** Never copy colored terminal output into titles or descriptions. Write text from scratch - paraphrase rather than copy. ANSI codes (`\x1b[`, `^[[`) stored in issues propagate to commit messages as garbage characters.

## Notes Format

```
COMPLETED: What was done
KEY DECISION: Why this approach
IN PROGRESS: Current state
NEXT: Immediate next step
```

## Checkpoint Triggers

- Token usage > 70%
- Major milestone reached
- Hit a blocker
- Before asking user for input

## Priority Levels

0=critical, 1=high, 2=normal, 3=low, 4=backlog

## Do NOT Close If

- Tests failing
- Implementation partial
- Unresolved errors
- Integration tests not updated for API changes
- New features lack integration test coverage (when applicable)

Instead: `br update br-xxx --notes "BLOCKED: ..." --json`

## Integration Test Requirements

When closing issues that involve:
- **API changes**: Verify existing integration tests still pass with new patterns
- **New features**: Add integration tests if feature interacts with external services
- **Bug fixes**: Add regression test if bug was user-facing

Before closing: Run integration tests using the project-specific command (check project `AGENTS.md` or other local AI instruction file)
