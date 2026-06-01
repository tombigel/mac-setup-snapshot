#!/usr/bin/env bats

load helpers/setup

setup() {
  make_mock_bin
  cd "$BATS_TEST_TMPDIR"
}

@test "restore requires yq or install path" {
  cat >inventory.yml <<'EOF'
version: 1
apps: []
EOF
  run "$BIN" restore -i inventory.yml --interactive=false --install-missing-tools=false
  [ "$status" -eq 1 ]
  [[ "$output" == *"yq v4 is required"* ]]
}

@test "gist push dry-run does not require local files to upload" {
  mock_command gh 'if [ "$1" = "auth" ]; then exit 0; fi; echo gh "$@"'
  run "$BIN" gist push -g abc123 --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run: would push"* ]]
}

@test "oh-my-zsh dry-run prints unattended-safe flags" {
  cat >inventory.yml <<'EOF'
version: 1
oh_my_zsh:
  installed: false
EOF
  mock_command yq 'exit 0'
  run "$BIN" restore -i inventory.yml -S oh_my_zsh --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"RUNZSH=no CHSH=no KEEP_ZSHRC=yes"* ]]
}

@test "config generator refuses existing file without yes" {
  echo "existing" > existing.yml
  run "$BIN" config generate -o existing.yml --interactive=false
  [ "$status" -eq 1 ]
  [[ "$output" == *"config not written"* ]]
}

