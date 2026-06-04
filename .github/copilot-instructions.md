# Copilot Instructions

This project is a zsh-first CLI for macOS setup snapshots and additive restore. Runtime Bash compatibility is intentionally unsupported; Bats remains Bash-based for tests.

Prefer:

- Small zsh functions and modules in `lib/*.zsh` or `lib/sources/*.zsh`.
- zsh arrays for repeated internal state, with explicit splitting only for user-entered input.
- Explicit command wrappers that preserve `--dry-run`.
- Bats tests with mocked external commands.
- Clear user-facing messages before long or prompting actions.
- Additive restore flows, including GitHub project restore that clones missing repos only.
- zsh syntax validation, for example `find bin lib -type f \( -name '*.zsh' -o -name 'mac-setup' \) -print0 | xargs -0 -n1 zsh -n`.
- Validation in sandboxed shells with Homebrew paths injected, for example `PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" /opt/homebrew/bin/bats test`.

Avoid:

- `eval` on user-controlled content.
- direct `curl | sh`.
- committing generated setup snapshots, copied dotfiles, resume state, or secrets.
- destructive restore behavior.
- fetching, pulling, resetting, cleaning, overwriting, or deleting existing GitHub project folders during restore.
- timeout tests that rely on real sleepers or long-running package-manager commands.
