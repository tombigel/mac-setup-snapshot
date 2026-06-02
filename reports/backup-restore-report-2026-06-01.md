# Backup And Dry-Run Restore Report

Date: 2026-06-01

## Summary

Ran a real local backup and a dry-run restore on this Mac using the local `mac-setup` CLI.

Final backup command:

```bash
env HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_AUTO_UPDATE=1 bin/mac-setup backup --target local -i mac-setup.yml --apps=false --versions=false
```

Final dry-run restore command:

```bash
bin/mac-setup restore --source local -i mac-setup.yml --dry-run --interactive=false
```

Generated local artifacts:

- `mac-setup.yml`: generated setup snapshot, approximately 40 KB.
- `files/.zshrc`
- `files/.gitconfig`
- `files/.gitignore_global`
- `files/.ssh/config`

These generated artifacts are ignored by Git and were not committed.

## Inventory Counts

- Homebrew formulae: 47
- Homebrew casks: 43
- npm globals: 3
- pip packages: 4
- pipx packages: 0
- manual apps: 105
- dotfiles: 4
- Oh My Zsh: installed
- Xcode Command Line Tools: installed
- Xcode.app: detected by directory check

## Restore Dry Run Result

The dry-run restore completed successfully with exit code 0.

Observed behavior:

- Homebrew formulae were detected as already installed and skipped.
- Homebrew casks were detected as already installed and skipped.
- npm globals were detected as already installed and skipped.
- pip packages were detected as already installed and skipped.
- Oh My Zsh was detected as already installed and skipped.
- Xcode Command Line Tools were already selected.
- Xcode.app was detected as already installed.
- Dotfiles already existed and were skipped.
- Manual apps were reported as requiring manual restore review.

No installs, downloads, overwrites, license acceptance, shell changes, or Gist writes were performed during the restore dry run.

## Blocked Or Adjusted Sources

Mac App Store inventory was disabled for the successful backup because `mas list` hung while the machine was not signed into the App Store. `doctor` reported:

- `mas`: installed
- App Store account: not signed in

Version recording was disabled for the successful backup because npm remote version lookup blocked on `npm view corepack version`. The final backup still recorded installed package names and package-manager state.

`yq` was missing before restore testing. It was installed with Homebrew so the restore command could parse the generated YAML inventory.

## Issues Found And Fixed During Run

Two implementation issues were found while running against the real machine:

- Dotfile path expansion mishandled literal `~` paths, causing existing dotfiles to be recorded as missing.
- Homebrew formula backup used `brew leaves --versions`, which is not valid for the installed Homebrew version.

Both issues were fixed locally before the final backup and dry-run restore.

## Follow-Up Recommendations

- Add a timeout or non-blocking failure path around `mas list`.
- Avoid remote npm version lookups during backup by default, or add per-source timeout handling.
- Disable Homebrew analytics/auto-update inside inventory commands by default for faster, less network-dependent backups.
- Improve Xcode.app version detection because `mdls` did not return a usable version even though the app directory was detected.
- Add a report command or structured run summary output so future backup/restore validation does not require manual command-output review.

## Follow-Up Status

Subsequent implementation added bounded external command handling, reduced unrelated Homebrew work, and planned/implemented a clean-Mac bootstrap flow with resume state for interrupted prepare/restore runs.
