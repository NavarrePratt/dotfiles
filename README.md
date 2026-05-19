# Dotfiles

Personal dotfiles managed with chezmoi.

This repository currently manages shell configuration and Codex configuration. Other application configs can be added incrementally after review.

## Layout

- `dot_zshrc`: small shell entrypoint that initializes Oh My Zsh and loads modules.
- `dot_config/dotfiles/shell/`: shell modules for paths, aliases, Kubernetes, Teleport, and AI tools.
- `dot_config/dotfiles/local/`: tracked templates for local-only secret and private config files.
- `dot_codex/private_config.toml`: managed `~/.codex/config.toml` with restrictive permissions.
- `dot_codex/AGENTS.md`: manually maintained global Codex instructions.
- `dot_codex/exact_rules/`: keeps `~/.codex/rules` free of execpolicy files unless explicitly added later.
- `dot_codex/skills/npratt/`: explicitly approved personal Codex skills.
- `.codex/plans/`: local-only ExecPlans for larger work. This path is ignored through `.git/info/exclude`, not tracked `.gitignore`.
- `.codex/worktrees/`: local-only project worktrees for isolated Codex work. This path is ignored through `.git/info/exclude`, not tracked `.gitignore`.
- `dot_claude/`: staged Claude source files copied from the tracked surface of `~/.claude`; currently blocked from apply.
- `scripts/`: validation helpers.

## Secrets and Runtime State

Real tokens live outside git at:

```sh
~/.config/dotfiles/local/env.zsh
```

Use `dot_config/dotfiles/local/env.example.zsh` as the template. The live `.zshrc` sources the local file if it exists.

Private local configuration also lives under `~/.config/dotfiles/local/`. For example, Teleport regions, company domains, request roles, and cluster resource paths belong in `~/.config/dotfiles/local/teleport.zsh`, using `dot_config/dotfiles/local/teleport.example.zsh` as the public-safe template.

Runtime state, histories, auth files, caches, sessions, SQLite databases, and local env files are intentionally ignored and should not be tracked.

Claude source is staged under `dot_claude/`, but `.chezmoiignore` currently prevents it from being applied into `~/.claude`. This keeps the existing `~/.claude` git checkout untouched while the dotfiles copy is reviewed.

## Local Codex Plans

Larger Codex work is planned locally with ExecPlan documents under `.codex/plans/`. Each plan has a top-level Markdown file as the source of truth. Supporting notes, review output, PR drafts, or agent summaries can live in an optional sibling directory with the same slug.

These files are local working state and are not intended for git by default. Keep `.codex/plans/` and `.codex/worktrees/` in the local Git exclude file:

```sh
git check-ignore -v .codex/plans/example.md .codex/worktrees/example
```

Use the `plan-epic`, `plans`, `implement-plan`, `finish-plan`, and `clean-plans` Codex skills for this workflow.

## Validate

Run the validation suite before applying changes:

```sh
./scripts/validate.sh
```

The validation runs shell syntax checks, secret scanning, tracked-file audits, and chezmoi checks when `chezmoi` is available.

To compare the staged Claude source with the tracked files in the live `~/.claude` checkout:

```sh
./scripts/claude-staged-diff.sh
```

## Apply

Review a redacted diff first. The first pre-apply diff may include deleted lines from old local files, so use the redacted helper:

```sh
./scripts/chezmoi-diff-redacted.sh
```

Apply only after the local diff is understood:

```sh
chezmoi --source "$HOME/git/dotfiles" apply
```
