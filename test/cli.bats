#!/usr/bin/env bats

load helpers/setup

setup() {
  make_mock_bin
  cd "$BATS_TEST_TMPDIR"
}

@test "shows help with no args" {
  run "$BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "shows help with chained short help flag" {
  run "$BIN" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Commands:"* ]]
}

@test "rejects value-taking option in middle of short chain" {
  run "$BIN" backup -diq inventory.yml
  [ "$status" -eq 2 ]
  [[ "$output" == *"value option -i must be standalone or last in a chain"* ]]
}

@test "accepts chained no-argument flags" {
  run "$BIN" backup -d --apps=false --brew=false --npm=false --pip=false --pipx=false --oh-my-zsh=false --xcode=false --dotfiles=false --manual-apps=false
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run: would write inventory"* ]]
}

@test "generates config file" {
  run "$BIN" config generate -o generated.yml
  [ "$status" -eq 0 ]
  [ -f generated.yml ]
  grep -q "oh_my_zsh: true" generated.yml
  grep -q "xcode: true" generated.yml
}

@test "backup emits mocked brew and npm inventory" {
  mock_command brew 'case "$1 $2" in "tap ") echo homebrew/core ;; "leaves --versions") echo "git 2.0" ;; "list --cask") echo "visual-studio-code 1.0" ;; *) exit 0 ;; esac'
  mock_command npm 'if [ "$1" = "list" ]; then echo /prefix/lib/node_modules/typescript; elif [ "$1" = "view" ]; then echo 5.0.0; fi'

  run "$BIN" backup --apps=false --pip=false --pipx=false --oh-my-zsh=false --xcode=false --dotfiles=false --manual-apps=false
  [ "$status" -eq 0 ]
  grep -q 'name: "git"' mac-inventory.yml
  grep -q 'name: "typescript"' mac-inventory.yml
}
