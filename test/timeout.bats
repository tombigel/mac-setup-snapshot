#!/usr/bin/env bats

load helpers/setup

setup() {
  make_mock_bin
  cd "$BATS_TEST_TMPDIR"
}

@test "command capture returns success output" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.sh"
    MI_COMMAND_TIMEOUT=1
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_command_capture_files "test command" "$out" "$err" sh -c "printf ok"
    rc=$?
    printf "%s|%s|%s\n" "$rc" "$(cat "$out")" "$(cat "$err")"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "0|ok|" ]
}

@test "command capture returns nonzero command status" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.sh"
    MI_COMMAND_TIMEOUT=1
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_command_capture_files "test command" "$out" "$err" sh -c "printf failed >&2; exit 7"
    rc=$?
    printf "%s|%s|%s\n" "$rc" "$(cat "$out")" "$(cat "$err")"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "7||failed" ]
}

@test "command capture reports timeout status from timeout wrapper" {
  mock_command perl 'exit 124'
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.sh"
    MI_COMMAND_TIMEOUT=1
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_command_capture_files "slow command" "$out" "$err" sh -c "printf never"
    rc=$?
    printf "%s|%s\n" "$rc" "$(cat "$out")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: slow command timed out after 1s"* ]]
  [[ "$output" == *"124|"* ]]
}

@test "appstore backup treats mas timeout as unavailable without running timeout process" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.sh"
    . "$PROJECT_ROOT/lib/args.sh"
    . "$PROJECT_ROOT/lib/report.sh"
    . "$PROJECT_ROOT/lib/sources/appstore.sh"
    mi_args_init
    MI_INTERACTIVE=false
    mi_has() { [ "$1" = "mas" ] || command -v "$1" >/dev/null 2>&1; }
    mi_mas_capture() {
      mi_warn "mas $2 timed out after 1s"
      return 124
    }
    appstore_backup
  '
  [ "$status" -eq 1 ]
  [[ "$output" == *"warning: mas list timed out after 1s"* ]]
  [[ "$output" == *'status: "skipped_mas_list_failed"'* ]]
}
