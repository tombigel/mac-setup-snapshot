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
