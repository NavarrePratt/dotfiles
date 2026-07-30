# Claude Code User Configuration

Personal `~/.claude` configuration for [Claude Code](https://code.claude.com/docs/).

## Managed surfaces

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Concise global policy loaded in every Claude session |
| `settings.json` | User-level permissions, model preferences, environment, and plugins |
| `rules/` | Modular global instructions automatically loaded by Claude Code |
| `skills/` | On-demand workflows and detailed procedures |
| `commands/` | Lightweight user commands |
| `agents/` | Claude subagent definitions |

User-level rules load automatically in Claude Code. OpenCode does not discover
Claude rule files, so add each rule that OpenCode should use to the `instructions`
array in `dot_config/opencode/opencode.json`.

## Maintenance

- Keep shared policy semantically aligned with `dot_codex/AGENTS.md` as required by the repo-root `AGENTS.md`.
- Keep global instructions concise; put task procedures in skills.
- Edit this chezmoi source tree, then review and apply the targeted managed files.
- Preserve explicit approval before remote writes and personal-account messages.
