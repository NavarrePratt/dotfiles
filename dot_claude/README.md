# Claude Code User Configuration

Personal `~/.claude` settings for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions loaded into every conversation |
| `settings.json` | Claude Code settings (model, permissions, env vars, plugins) |
| `rules/` | Modular instruction sets referenced from CLAUDE.md |
| `skills/` | Custom slash-command skills (issue planning, code review, etc.) |
| `commands/` | Lightweight slash commands (commit, discover, codex review) |
| `agents/` | Agent definitions |

## Rules

- `comments.md` - When comments are acceptable (why, not what)
- `git-spice.md` - Stacked PR workflow with `gs`
- `grug-brain.md` - Anti-complexity development philosophy
- `python.md` - Python conventions (uv, style)
- `testing.md` - Test real behavior, not coverage numbers

## Skills

Custom skills invoked via `/skill-name`:

- **Issue planning**: `issue-plan`, `issue-plan-codex`, `issue-plan-hybrid`, `issue-plan-user`
- **Code review**: `team-branch-review`, `parallel-branch-review`, `grug-review`, `codex-*-review`
- **Review follow-up**: `team-branch-fix`, `team-branch-comment`, `pr-review-reply`, `pr-review-import`
- **Workflow**: `git-commit`, `issue-create`, `remember`, `repo-explore`, `discover`
- **Documentation**: `diataxis-documentation`, `humanizer`

## Key Conventions

- Issue tracking is opt-in via the `issue-plan*` / `issue-create` skills (backed by [`br`](https://github.com/Dicklesworthstone/beads_rust)), not a global default
- Commits created through `/commit` skill
- No git push or GitHub writes without explicit approval
- Python uses `uv` for everything
