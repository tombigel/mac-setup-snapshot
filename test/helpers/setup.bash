#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
BIN="$PROJECT_ROOT/bin/mac-setup"

make_mock_bin() {
  MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"
}

mock_command() {
  name="$1"
  body="$2"
  cat >"$MOCK_BIN/$name" <<EOF
#!/usr/bin/env bash
$body
EOF
  chmod +x "$MOCK_BIN/$name"
}

make_test_app() {
  app_root="$1"
  app_name="$2"
  bundle_id="$3"
  version="$4"
  has_receipt="${5:-false}"
  app_path="$app_root/$app_name.app"
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
