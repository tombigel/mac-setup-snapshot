# Claude Instructions

Follow [AGENTS.md](AGENTS.md). Keep changes conservative and zsh-native.

Important context:

- `bin/mac-setup` is the CLI entrypoint.
- `lib/args.zsh` owns option parsing.
- `lib/workflow.zsh` owns prepare/continue/status, resume state, step output, Git readiness checks, and caffeinate.
- `lib/inventory.zsh` owns backup/list/restore orchestration, including restore step pause/skip/abort pacing.
- `lib/sources/*.zsh` owns source-specific behavior, including package managers and opt-in GitHub project cloning.

Before changing restore, dotfiles, Gist, GitHub projects, Homebrew bootstrap, or resume state, review the safety model in [docs/MANUAL.md](docs/MANUAL.md).
