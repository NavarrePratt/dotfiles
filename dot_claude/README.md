# Claude Code User Configuration

Personal `~/.claude` configuration for [Claude Code](https://code.claude.com/docs/).

## Managed surfaces

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Concise global policy loaded in every Claude session |
| `settings.json` | User-level permissions, model preferences, environment, and plugins |
| `rules/` | Modular global instructions explicitly imported by `CLAUDE.md` |
| `skills/` | On-demand workflows and detailed procedures |
| `commands/` | Lightweight user commands |
| `agents/` | Claude subagent definitions |

No global rules are currently kept separate. If `CLAUDE.md` gains an `@rules`
import, add the same rule to `dot_config/opencode/opencode.json` because OpenCode
does not resolve Claude imports.

## Maintenance

- Keep shared policy semantically aligned with `dot_codex/AGENTS.md` as required by the repo-root `AGENTS.md`.
- Keep global instructions concise; put task procedures in skills.
- Edit this chezmoi source tree, then review and apply the targeted managed files.
- Preserve explicit approval before remote writes and personal-account messages.
