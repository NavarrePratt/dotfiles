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
