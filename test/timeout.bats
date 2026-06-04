#!/usr/bin/env bats

load helpers/setup

setup() {
  make_mock_bin
  cd "$BATS_TEST_TMPDIR"
}

@test "command capture returns success output" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.zsh"
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
    . "$PROJECT_ROOT/lib/common.zsh"
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
    . "$PROJECT_ROOT/lib/common.zsh"
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

@test "command capture shows spinner line only in live mode" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.zsh"
    MI_COMMAND_TIMEOUT=1
    MI_SPINNER_INTERVAL=0
    mi_live_enabled() { return 0; }
    mi_live_line() {
      printf "live:%s\n" "$*"
      MI_LIVE_LINE_ACTIVE=true
    }
    mi_live_clear() {
      printf "clear\n"
      MI_LIVE_LINE_ACTIVE=false
    }
    mi_command_capture_files_core() {
      local _label="$1"
      local _out="$2"
      local _err="$3"
      printf ok >"$_out"
      : >"$_err"
      return 0
    }
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_command_capture_files "test command" "$out" "$err" true
    rc=$?
    printf "rc:%s out:%s\n" "$rc" "$(cat "$out")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"live:- test command"* ]]
  [[ "$output" == *"clear"* ]]
  [[ "$output" == *"rc:0 out:ok"* ]]
}

@test "command capture spinner starts below an active live step line" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.zsh"
    MI_COMMAND_TIMEOUT=1
    MI_SPINNER_INTERVAL=0
    mi_live_enabled() { return 0; }
    mi_command_capture_files_core() {
      local _label="$1"
      local _out="$2"
      local _err="$3"
      printf ok >"$_out"
      : >"$_err"
      return 0
    }
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_live_line "Current step"
    mi_command_capture_files "test command" "$out" "$err" true
  ' 2>&1
  [ "$status" -eq 0 ]
  [[ "$output" == *$'Current step\n'* ]]
  [[ "$output" == *$'\n\r\033[2K-'*"test command"* ]]
}

@test "command capture suppresses spinner line outside live mode" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.zsh"
    MI_COMMAND_TIMEOUT=1
    mi_live_enabled() { return 1; }
    mi_live_line() { printf "unexpected-live:%s\n" "$*"; }
    mi_command_capture_files_core() {
      local _label="$1"
      local _out="$2"
      local _err="$3"
      printf ok >"$_out"
      : >"$_err"
      return 0
    }
    out="$BATS_TEST_TMPDIR/out"
    err="$BATS_TEST_TMPDIR/err"
    mi_command_capture_files "test command" "$out" "$err" true
    rc=$?
    printf "rc:%s out:%s\n" "$rc" "$(cat "$out")"
  '
  [ "$status" -eq 0 ]
  [[ "$output" != *"unexpected-live"* ]]
  [[ "$output" == "rc:0 out:ok" ]]
}

@test "live line hides cursor while dynamic output is active and cleanup restores it" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.zsh"
    mi_live_enabled() { return 0; }
    mi_live_line "short"
    mi_live_line "a longer dynamic line"
    mi_live_clear
    mi_cleanup_temp_files
  ' 2>&1
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033[?25l'* ]]
  [[ "$output" == *$'\033[?25h'* ]]
  [ "$(printf "%s" "$output" | grep -o $'\033\\[?25l' | wc -l | tr -d " ")" -eq 1 ]
}

@test "appstore backup treats mas timeout as unavailable without running timeout process" {
  run env PROJECT_ROOT="$PROJECT_ROOT" zsh -f -c '
    . "$PROJECT_ROOT/lib/common.zsh"
    . "$PROJECT_ROOT/lib/args.zsh"
    . "$PROJECT_ROOT/lib/report.zsh"
    . "$PROJECT_ROOT/lib/sources/appstore.zsh"
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
