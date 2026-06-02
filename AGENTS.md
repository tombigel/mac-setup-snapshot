# Agent Instructions

This repo contains Mac Setup Snapshot, a Bash-first macOS setup snapshot and additive restore CLI.

## Safety Rules

- Keep restore additive-only: install, copy, check, and report. Do not add uninstall/delete/cleanup behavior without an explicit design update.
- Quote variables and paths.
- Do not use `eval` on config, setup snapshots, Gist, or resume state.
- Do not use direct `curl | sh`; download installers to temp files and execute only after policy allows it.
- Do not commit generated setup snapshots, copied dotfiles, resume files, Gist payloads, or secrets.
- Preserve dry-run behavior: no writes, installs, downloads, uploads, overwrites, license acceptance, or shell changes.

## Generated Files

Ignored by default:

- `mac-setup.yml`
- `mac-setup.yml.tmp.*`
- `mac-setup.config.yml`
- `files/`
- `.mac-setup/`

Runtime resume state defaults to `~/.mac-setup/resume.yml`.

## Validation

Run when available:

```bash
find bin lib -type f \( -name '*.sh' -o -name 'mac-setup' \) -print0 | xargs -0 -n1 bash -n
shellcheck bin/mac-setup lib/*.sh lib/sources/*.sh
bats test
```

If `shellcheck` or `bats` is missing, report that clearly.

## Adding A Source Module

- Add a `lib/sources/<name>.sh` file.
- Provide `<name>_backup`, `<name>_restore`, and optional `<name>_doctor`.
- Validate identifiers before package-manager commands.
- Use `mi_run`, `mi_command_capture`, or source-specific wrappers so dry-run and timeouts work.
- Add Bats coverage with mocked commands.
