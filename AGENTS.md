# Working in this repo (chezmoi dotfiles source)

This repo is the **chezmoi source tree**. Files here are applied into `$HOME`;
they are not the live files. Get this wrong and your edits silently fail to take
effect or get overwritten by the next `chezmoi apply`.

## The `dot_` mapping

Source files prefixed `dot_` map to dotfiles in `$HOME`:

- `dot_claude/` → `~/.claude/`   (skills live at `dot_claude/skills/<name>/SKILL.md`)
- `dot_codex/`  → `~/.codex/`
- `dot_zshrc` → `~/.zshrc`, `dot_zshenv` → `~/.zshenv`

## Edit the source, never the applied copy

To change a managed file, edit it HERE in the source tree, then run `chezmoi apply`
to push it to `$HOME`. Editing the copy under `~/.claude/` (or any applied dotfile)
directly is wrong: it is untracked and the next `chezmoi apply` overwrites it. If
you already edited an applied file, pull it back with `chezmoi add <home-path>` and
confirm the change landed in THIS repo before committing.

## chezmoi here needs an explicit `--source`

Bare `chezmoi` commands do not work in this repo. chezmoi's configured source is
its default `~/.local/share/chezmoi`, which does not exist on this machine, so
`chezmoi source-path`, `chezmoi managed`, etc. silently report nothing useful. The
real source is this repo. Always pass it explicitly:

    chezmoi --source "$PWD" diff      # preview what apply would change
    chezmoi --source "$PWD" managed   # list managed targets

`scripts/validate.sh` wraps `chezmoi --source "$repo_root" doctor` + `diff`. Do not
trust or `cd` to whatever `chezmoi source-path` prints.

## Managed Codex config

Before applying `~/.codex/config.toml`, review its targeted
`chezmoi --source "$PWD" diff`. Preserve wanted live-only settings in
`dot_codex/private_config.toml` before applying. Use `--force` only after that
review and only for the specific Codex target.

## Don't commit runtime state

Most `dot_claude/` and `dot_codex/` subdirectories (projects/, sessions/, cache/,
plugins/, todos/, ...) are gitignored runtime state. Only config, rules, commands,
agents, and approved skills are tracked. Check `.gitignore` before `git add` under
those directories.

## This file vs the global instruction files

This file is repo-scoped: it loads only when an agent works inside this repo
(`CLAUDE.md` at the root is a symlink to it, so Claude Code and Codex both read it).
Do not confuse it with the global agent instructions this repo also manages:

- `dot_claude/CLAUDE.md` → `~/.claude/CLAUDE.md` — loaded in every Claude session everywhere
- `dot_codex/AGENTS.md` → `~/.codex/AGENTS.md` — loaded in every Codex session everywhere

Those are global and heavy; change them deliberately. This file is the place for
guidance that only matters when working on the dotfiles themselves.

## Global harness parity

Keep `dot_claude/CLAUDE.md` and `dot_codex/AGENTS.md` semantically aligned by
default. Shared behavior, quality standards, and safety boundaries belong in
both files. Diverge only for documented harness differences such as instruction
discovery, available tools or skills, workflow support, and attribution. When
changing one file, review the other and preserve equivalent policy unless the
difference is intentional. Keep both files explicit and independently readable;
do not replace them with shared generation without an explicit decision.

Technical-writing guidance intentionally uses harness-specific loading. Claude
loads `~/.claude/rules/simplified-technical-english.md` as an unconditional user
rule, and OpenCode loads the same file through its `instructions` array. Codex
keeps the detailed guidance in the `simplified-technical-english` skill and its
global `AGENTS.md` requires that skill for technical prose.

## OpenCode instruction inheritance

OpenCode automatically inherits `~/.claude/CLAUDE.md` as its global instructions
(unless `disableClaudeCodePrompt` is set in `opencode.json`). This is desirable:
it gives OpenCode the same git commit, PR, code style, and safety guidance as
Claude Code without duplication.

**OpenCode does NOT auto-load Claude rule files or resolve `@` imports.** Claude
Code loads user rules under `~/.claude/rules/` automatically and expands
`@rules/foo.md` references in CLAUDE.md. OpenCode loads CLAUDE.md as raw text:
`@rules/` references appear as literal strings, and automatically loaded Claude
rules are absent. Add each Claude rule that OpenCode should receive to the
`instructions` array in `opencode.json`.

OpenCode DOES auto-load Claude skills from `~/.claude/skills/<name>/SKILL.md`
(unless `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` is set). Skills do not need to
be duplicated in the `instructions` array.

However, `~/.config/opencode/AGENTS.md` uses **first-match-wins**, not merge.
If it exists, it completely replaces the inherited CLAUDE.md. Do NOT create
`dot_config/opencode/AGENTS.md` unless you intend to fully override CLAUDE.md.

For opencode-specific guidance that should be **additive** (merged with, not
replacing, the inherited CLAUDE.md), use the `instructions` array in
`dot_config/opencode/opencode.json` instead. This array supports three path
types:

- Relative paths (e.g. `instructions/cross-model-mcp.md`) - resolved relative to
  the opencode config directory
- Home-relative paths (e.g. `~/.claude/rules/shared-policy.md`) - resolved
  against `$HOME`; use this to share Claude rule files with OpenCode without
  duplication
- Absolute paths - resolved as-is

```json
"instructions": [
  "instructions/cross-model-mcp.md"
]
```

These are additive to the inherited CLAUDE.md, not replacements for it.
