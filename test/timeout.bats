#!/usr/bin/env bats

load helpers/setup

setup() {
  cd "$BATS_TEST_TMPDIR"
}

@test "command capture returns success output" {
  run env PROJECT_ROOT="$PROJECT_ROOT" bash -c '
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
  run env PROJECT_ROOT="$PROJECT_ROOT" bash -c '
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

@test "command capture times out slow commands" {
  run env PROJECT_ROOT="$PROJECT_ROOT" bash -c '
    . "$PROJECT_ROOT/lib/common.sh"
    MI_COMMAND_TIMEOUT=1
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_command_capture_files "slow command" "$out" "$err" sh -c "sleep 5"
    rc=$?
    printf "%s|%s\n" "$rc" "$(cat "$out")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: slow command timed out after 1s"* ]]
  [[ "$output" == *"124|"* ]]
}

@test "command capture kills timeout child that ignores term" {
  run env PROJECT_ROOT="$PROJECT_ROOT" bash -c '
    . "$PROJECT_ROOT/lib/common.sh"
    MI_COMMAND_TIMEOUT=1
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_command_capture_files "stubborn command" "$out" "$err" sh -c "trap \"\" TERM; sleep 5"
    rc=$?
    printf "%s|%s\n" "$rc" "$(cat "$out")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: stubborn command timed out after 1s"* ]]
  [[ "$output" == *"124|"* ]]
}
