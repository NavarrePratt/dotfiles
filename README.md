# Dotfiles

Personal dotfiles managed with chezmoi.

## Layout

- `dot_zshrc`: small shell entrypoint that initializes Oh My Zsh and loads modules.
- `dot_config/dotfiles/shell/`: shell modules for paths, aliases, Kubernetes, Teleport, and AI tools.
- `dot_config/dotfiles/local/`: tracked examples for machine-local env files.
- `dot_codex/`: managed Codex config, instructions, and personal skills.
- `dot_claude/`: managed Claude Code instructions, skills, commands, and safe templates.
- `scripts/`: validation helpers.

## Secrets and Runtime State

Real tokens live outside git at:

```sh
~/.config/dotfiles/local/env.zsh
```

Use `dot_config/dotfiles/local/env.example.zsh` as the template. The live `.zshrc` sources the local file if it exists.

Runtime state, histories, auth files, caches, sessions, SQLite databases, and local env files are intentionally ignored and should not be tracked.

## Validate

Run the validation suite before applying changes:

```sh
./scripts/validate.sh
```

The validation runs shell syntax checks, Codex skill validation when the local validator is available, secret scanning, tracked-file audits, and chezmoi checks when `chezmoi` is available.

## Apply

Review a redacted diff first. The first pre-apply diff may include deleted lines from old local files, so use the redacted helper:

```sh
./scripts/chezmoi-diff-redacted.sh
```

Apply only targeted paths after the local diff is understood:

```sh
chezmoi --source "$HOME/git/dotfiles" diff "$HOME/.zshrc"
chezmoi --source "$HOME/git/dotfiles" apply "$HOME/.zshrc"
```
