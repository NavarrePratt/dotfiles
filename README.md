# Dotfiles

Personal dotfiles managed with chezmoi.

This repository currently manages shell configuration and Codex configuration. Other application configs can be added incrementally after review.

## Layout

- `dot_zshrc`: small shell entrypoint that initializes Oh My Zsh and loads modules.
- `dot_config/dotfiles/shell/`: shell modules for paths, aliases, Kubernetes, Teleport, and AI tools.
- `dot_config/dotfiles/local/`: tracked templates for local-only secret and private config files.
- `dot_codex/private_config.toml`: managed `~/.codex/config.toml` with restrictive permissions.
- `dot_codex/AGENTS.md`: manually maintained global Codex instructions.
- `dot_codex/rules/`: Codex rules.
- `dot_codex/skills/npratt/`: explicitly approved personal Codex skills.
- `scripts/`: validation helpers.

## Secrets and Runtime State

Real tokens live outside git at:

```sh
~/.config/dotfiles/local/env.zsh
```

Use `dot_config/dotfiles/local/env.example.zsh` as the template. The live `.zshrc` sources the local file if it exists.

Private local configuration also lives under `~/.config/dotfiles/local/`. For example, Teleport regions, company domains, request roles, and cluster resource paths belong in `~/.config/dotfiles/local/teleport.zsh`, using `dot_config/dotfiles/local/teleport.example.zsh` as the public-safe template.

Runtime state, histories, auth files, caches, sessions, SQLite databases, and local env files are intentionally ignored and should not be tracked.

## Validate

Run the validation suite before applying changes:

```sh
./scripts/validate.sh
```

The validation runs shell syntax checks, secret scanning, tracked-file audits, and chezmoi checks when `chezmoi` is available.

## Apply

Review a redacted diff first. The first pre-apply diff may include deleted lines from old local files, so use the redacted helper:

```sh
./scripts/chezmoi-diff-redacted.sh
```

Apply only after the local diff is understood:

```sh
chezmoi --source "$HOME/git/dotfiles" apply
```
