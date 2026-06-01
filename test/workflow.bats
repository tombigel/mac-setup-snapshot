#!/usr/bin/env bats

load helpers/setup

setup() {
  make_mock_bin
  cd "$BATS_TEST_TMPDIR"
}

@test "prepare dry-run prints clean step output without writing requested resume file" {
  run "$BIN" prepare --dry-run --resume-file "$BATS_TEST_TMPDIR/resume.yml" --apps=false --xcode=false --pipx=false
  [ "$status" -eq 0 ]
  [[ "$output" == *"Step 1/"* ]]
  [[ "$output" == *"Press Ctrl-C to stop safely"* ]]
  [ ! -f "$BATS_TEST_TMPDIR/resume.yml" ]
}

@test "restore preflight runs by default and fails at missing inventory" {
  run "$BIN" restore --dry-run --interactive=false --resume-file "$BATS_TEST_TMPDIR/resume.yml" --inventory "$BATS_TEST_TMPDIR/missing.yml"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Check Xcode Command Line Tools"* ]]
  [[ "$output" == *"workflow failed at step restore_inventory"* ]]
}

@test "restore can skip prepare preflight" {
  run "$BIN" restore --skip-prepare=true --dry-run --inventory "$BATS_TEST_TMPDIR/missing.yml"
  [ "$status" -eq 1 ]
  [[ "$output" != *"Check Xcode Command Line Tools"* ]]
  [[ "$output" == *"inventory not found"* ]]
}

@test "status prints existing resume state" {
  cat >"$BATS_TEST_TMPDIR/resume.yml" <<'YAML'
version: 1
workflow: "prepare"
created_at: "2026-06-01T00:00:00Z"
updated_at: "2026-06-01T00:00:00Z"
inventory: "mac-inventory.yml"
current_step: "install_yq"
steps:
  - id: "check_xcode_cli"
    status: "done"
  - id: "install_yq"
    status: "failed"
YAML
  run "$BIN" status --resume-file "$BATS_TEST_TMPDIR/resume.yml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"workflow: \"prepare\""* ]]
  [[ "$output" == *"install_yq"* ]]
}

@test "continue dry-run resumes saved workflow steps" {
  cat >"$BATS_TEST_TMPDIR/resume.yml" <<'YAML'
version: 1
workflow: "prepare"
created_at: "2026-06-01T00:00:00Z"
updated_at: "2026-06-01T00:00:00Z"
inventory: "mac-inventory.yml"
current_step: "install_yq"
steps:
  - id: "check_xcode_cli"
    status: "done"
  - id: "install_yq"
    status: "failed"
YAML
  run "$BIN" continue --dry-run --resume-file "$BATS_TEST_TMPDIR/resume.yml"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Check Xcode Command Line Tools"* ]]
  [[ "$output" == *"Install yq"* ]]
}

@test "caffeinate is used when enabled and available" {
  mock_command caffeinate 'echo caffeinate "$@" >> "$BATS_TEST_TMPDIR/caffeinate.log"; sleep 2 & wait'
  run "$BIN" prepare --dry-run --caffeinate=true --apps=false --xcode=false --pipx=false --resume-file "$BATS_TEST_TMPDIR/resume.yml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"would use caffeinate"* ]]
}
