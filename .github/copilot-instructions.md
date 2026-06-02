# Copilot Instructions

This project is a Bash CLI for macOS setup snapshots and additive restore.

Prefer:

- Small Bash functions.
- Explicit command wrappers that preserve `--dry-run`.
- Bats tests with mocked external commands.
- Clear user-facing messages before long or prompting actions.

Avoid:

- `eval` on user-controlled content.
- direct `curl | sh`.
- committing generated setup snapshots, copied dotfiles, resume state, or secrets.
- destructive restore behavior.
