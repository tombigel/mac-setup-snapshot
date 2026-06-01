# Claude Instructions

Follow [AGENTS.md](AGENTS.md). Keep changes conservative and Bash-native.

Important context:

- `bin/mac-inventory` is the CLI entrypoint.
- `lib/args.sh` owns option parsing.
- `lib/workflow.sh` owns prepare/continue/status, resume state, step output, and caffeinate.
- `lib/inventory.sh` owns backup/list/restore orchestration.
- `lib/sources/*.sh` owns package-manager specific behavior.

Before changing restore, dotfiles, Gist, Homebrew bootstrap, or resume state, review the safety model in [docs/MANUAL.md](docs/MANUAL.md).
