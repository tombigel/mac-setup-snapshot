#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$PROJECT_DIR/bin/mac-setup"
STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
ICLOUD_ROOT="${ICLOUD_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}"
ICLOUD_FOLDER="${ICLOUD_FOLDER:-Mac Setup Snapshot Manual Test $STAMP}"
REPORT="${REPORT:-$PROJECT_DIR/tmp/manual-icloud-endpoint-test-$STAMP.md}"

PASSED=0
FAILED=0
SKIPPED=0

SNAPSHOT_ARGS=(
  --interactive=false
  --icloud-root "$ICLOUD_ROOT"
  --icloud-folder "$ICLOUD_FOLDER"
  --apps=false
  --brew=false
  --npm=false
  --pip=false
  --pipx=false
  --oh-my-zsh=false
  --xcode=false
  --dotfiles=false
  --manual-apps=false
)

mkdir -p "$(dirname "$REPORT")"

write_line() {
  printf '%s\n' "$*" >>"$REPORT"
}

record_result() {
  local status="$1"
  local title="$2"
  local output="$3"

  case "$status" in
    pass)
      PASSED=$((PASSED + 1))
      write_line "### PASS: $title"
      ;;
    fail)
      FAILED=$((FAILED + 1))
      write_line "### FAIL: $title"
      ;;
    skip)
      SKIPPED=$((SKIPPED + 1))
      write_line "### SKIP: $title"
      ;;
  esac

  write_line
  write_line '```text'
  printf '%s\n' "$output" >>"$REPORT"
  write_line '```'
  write_line
}

run_step() {
  local title="$1"
  local expected="$2"
  shift 2

  local output
  local status

  output="$("$@" 2>&1)"
  status=$?

  if [[ "$expected" == "pass" && "$status" -eq 0 ]]; then
    record_result pass "$title" "$output"
    return 0
  fi

  if [[ "$expected" == "fail" && "$status" -ne 0 ]]; then
    record_result pass "$title" "$output"
    return 0
  fi

  record_result fail "$title" "exit=$status
$output"
  return 1
}

{
  printf '# Mac Setup Snapshot Manual iCloud Endpoint Test\n\n'
  printf -- '- Started: `%s`\n' "$STAMP"
  printf -- '- Project: `%s`\n' "$PROJECT_DIR"
  printf -- '- Binary: `%s`\n' "$BIN"
  printf -- '- iCloud root: `%s`\n' "$ICLOUD_ROOT"
  printf -- '- Test iCloud folder: `%s`\n' "$ICLOUD_FOLDER"
  printf -- '- Report: `%s`\n\n' "$REPORT"
} >"$REPORT"

write_line '## Environment'
write_line
write_line '```text'
{
  sw_vers 2>/dev/null || true
  printf 'shell=%s\n' "$SHELL"
  printf 'pwd=%s\n' "$PWD"
  printf 'icloud_root_exists=%s\n' "$([[ -d "$ICLOUD_ROOT" ]] && echo yes || echo no)"
  printf 'icloud_root_readable=%s\n' "$([[ -r "$ICLOUD_ROOT" ]] && echo yes || echo no)"
  printf 'icloud_root_writable=%s\n' "$([[ -w "$ICLOUD_ROOT" ]] && echo yes || echo no)"
} >>"$REPORT"
write_line '```'
write_line

if [[ ! -x "$BIN" ]]; then
  record_result fail "CLI binary is executable" "$BIN is not executable"
  printf 'Report written to %s\n' "$REPORT"
  exit 1
fi

if [[ ! -d "$ICLOUD_ROOT" ]]; then
  record_result skip "iCloud endpoint filesystem tests" "iCloud root does not exist: $ICLOUD_ROOT"
else
  run_step "Help includes endpoint flags" pass "$BIN" --help

  run_step \
    "Default iCloud backup dry-run preflight" \
    pass \
    "$BIN" backup --dry-run --skip-report "${SNAPSHOT_ARGS[@]}"

  run_step \
    "Default iCloud backup creates test bundle" \
    pass \
    "$BIN" backup --skip-report "${SNAPSHOT_ARGS[@]}"

  run_step \
    "Second iCloud backup creates history entry" \
    pass \
    "$BIN" backup --skip-report "${SNAPSHOT_ARGS[@]}"

  run_step \
    "iCloud restore dry-run from test bundle" \
    pass \
    "$BIN" restore --dry-run --skip-prepare=true --install-missing-tools=false "${SNAPSHOT_ARGS[@]}"

  run_step \
    "Explicit local target dry-run still works" \
    pass \
    "$BIN" backup --target local --dry-run --skip-report \
    --apps=false --brew=false --npm=false --pip=false --pipx=false \
    --oh-my-zsh=false --xcode=false --dotfiles=false --manual-apps=false

  run_step \
    "GitHub target dry-run does not require auth" \
    pass \
    "$BIN" backup --target github --dry-run --skip-report \
    --apps=false --brew=false --npm=false --pip=false --pipx=false \
    --oh-my-zsh=false --xcode=false --dotfiles=false --manual-apps=false

  write_line '## Created iCloud Files'
  write_line
  write_line '```text'
  if [[ -d "$ICLOUD_ROOT/$ICLOUD_FOLDER" ]]; then
    find "$ICLOUD_ROOT/$ICLOUD_FOLDER" -maxdepth 3 -print | sort >>"$REPORT"
  else
    printf 'No test bundle found at %s\n' "$ICLOUD_ROOT/$ICLOUD_FOLDER" >>"$REPORT"
  fi
  write_line '```'
  write_line
fi

write_line '## Summary'
write_line
write_line "- Passed: $PASSED"
write_line "- Failed: $FAILED"
write_line "- Skipped: $SKIPPED"

printf 'Report written to %s\n' "$REPORT"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi

