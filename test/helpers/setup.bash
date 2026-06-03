#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
BIN="$PROJECT_ROOT/bin/mac-setup"

make_mock_bin() {
  MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"
}

mock_command() {
  local name="$1"
  local body="$2"
  cat >"$MOCK_BIN/$name" <<EOF
#!/usr/bin/env bash
$body
EOF
  chmod +x "$MOCK_BIN/$name"
}

mock_yq_v4() {
  mock_command yq 'if [ "$1" = "--version" ]; then echo "yq (https://github.com/mikefarah/yq/) version v4.0.0"; exit 0; fi; exit 0'
}

mock_command_log() {
  local name="$1"
  local log="$2"
  mock_command "$name" 'printf "%s\n" "$0 $*" >>"'"$log"'"'
}

assert_file_not_exists() {
  local path="$1"
  [ ! -e "$path" ]
}

assert_command_not_called() {
  local log="$1"
  [ ! -s "$log" ]
}

make_test_app() {
  local app_root="$1"
  local app_name="$2"
  local bundle_id="$3"
  local version="$4"
  local has_receipt="${5:-false}"
  local app_path="$app_root/$app_name.app"
  mkdir -p "$app_path/Contents"
  cat >"$app_path/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>$app_name</string>
  <key>CFBundleIdentifier</key>
  <string>$bundle_id</string>
  <key>CFBundleShortVersionString</key>
  <string>$version</string>
</dict>
</plist>
EOF
  if [ "$has_receipt" = "true" ]; then
    mkdir -p "$app_path/Contents/_MASReceipt"
    : >"$app_path/Contents/_MASReceipt/receipt"
  fi
}
