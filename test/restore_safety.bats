#!/usr/bin/env bats

load helpers/setup

setup() {
  make_mock_bin
  cd "$BATS_TEST_TMPDIR"
}

write_minimal_inventory() {
  cat >inventory.yml <<'YAML'
version: 1
brew:
  taps:
    - name: "homebrew/core"
      ref: "brew_tap:homebrew/core"
  formulae:
    - name: "wget"
      ref: "brew_formula:wget"
  casks:
    - name: "visual-studio-code"
      ref: "brew_cask:visual-studio-code"
npm:
  globals:
    - name: "typescript"
      ref: "npm:typescript"
pip:
  packages:
    - name: "black"
      ref: "pip:black"
pipx:
  packages:
    - name: "poetry"
      ref: "pipx:poetry"
dotfiles:
  files:
    - path: "~/.tool-versions"
      ref: "dotfile:tool-versions"
xcode:
  command_line_tools: true
  app_installed: true
  ignored: false
YAML
}

mock_restore_yq() {
  mock_command yq '
if [ "$1" = "--version" ]; then
  echo "yq (https://github.com/mikefarah/yq/) version v4.0.0"
  exit 0
fi
expr="$*"
case "$expr" in
  *".brew.taps"*) printf "%s\n" "homebrew/core|brew_tap:homebrew/core|false" ;;
  *".brew.formulae"*) printf "%s\n" "wget|brew_formula:wget|false" ;;
  *".brew.casks"*) printf "%s\n" "visual-studio-code|brew_cask:visual-studio-code|Visual Studio Code|false" ;;
  *".npm.globals"*) printf "%s\n" "typescript|npm:typescript|false" ;;
  *".pip.packages"*) printf "%s\n" "black|pip:black|false" ;;
  *".pipx.packages"*) printf "%s\n" "poetry|pipx:poetry|false" ;;
  *".dotfiles.files"*) printf "%s\n" "~/.tool-versions|dotfile:tool-versions|false" ;;
  *".xcode.ignored"*) printf "%s\n" "false" ;;
  *) : ;;
esac'
}

mock_restore_commands() {
  mock_command brew '
while [ "$1" = "env" ] || [ "${1#HOMEBREW_}" != "$1" ]; do shift; done
case "$1 $2 $3" in
  "tap  ") : ;;
  "tap homebrew/core ") printf "%s\n" "brew tap homebrew/core" >>"$BATS_TEST_TMPDIR/side-effects.log" ;;
  "list --formula wget") exit 1 ;;
  "list --cask visual-studio-code") exit 1 ;;
  "install wget ") printf "%s\n" "brew install wget" >>"$BATS_TEST_TMPDIR/side-effects.log" ;;
  "install --cask visual-studio-code") printf "%s\n" "brew install --cask visual-studio-code" >>"$BATS_TEST_TMPDIR/side-effects.log" ;;
  *) : ;;
esac'
  mock_command npm '
case "$1 $2 $3" in
  "list -g typescript") exit 1 ;;
  "install -g typescript") printf "%s\n" "npm install -g typescript" >>"$BATS_TEST_TMPDIR/side-effects.log" ;;
  *) : ;;
esac'
  mock_command pip3 '
case "$1 $2" in
  "show black") exit 1 ;;
  "install black") printf "%s\n" "pip3 install black" >>"$BATS_TEST_TMPDIR/side-effects.log" ;;
  *) : ;;
esac'
  mock_command pipx '
case "$1 $2" in
  "list --short") : ;;
  "install poetry") printf "%s\n" "pipx install poetry" >>"$BATS_TEST_TMPDIR/side-effects.log" ;;
  *) : ;;
esac'
  mock_command xcode-select '
case "$1" in
  -p) exit 1 ;;
  --install) printf "%s\n" "xcode-select --install" >>"$BATS_TEST_TMPDIR/side-effects.log" ;;
  *) : ;;
esac'
  mock_command mas 'printf "%s\n" "mas $*" >>"$BATS_TEST_TMPDIR/side-effects.log"'
}

@test "restore dry-run does not execute source side effects" {
  write_minimal_inventory
  mkdir -p files
  printf "nodejs 22\n" >files/.tool-versions
  mock_restore_yq
  mock_restore_commands

  run env HOME="$BATS_TEST_TMPDIR/home" "$BIN" restore --dry-run --skip-prepare=true --skip-report --inventory inventory.yml --apps=false --brew=true --npm=true --pip=true --pipx=true --oh-my-zsh=false --xcode=true --dotfiles=true --manual-apps=false
  [ "$status" -eq 0 ]
  assert_command_not_called "$BATS_TEST_TMPDIR/side-effects.log"
  assert_file_not_exists "$BATS_TEST_TMPDIR/home/.tool-versions"
}

@test "restore real run executes only additive source actions" {
  write_minimal_inventory
  mkdir -p files "$BATS_TEST_TMPDIR/home"
  printf "nodejs 22\n" >files/.tool-versions
  mock_restore_yq
  mock_restore_commands

  run env HOME="$BATS_TEST_TMPDIR/home" "$BIN" restore --skip-prepare=true --skip-report --inventory inventory.yml --apps=false --brew=true --npm=true --pip=true --pipx=true --oh-my-zsh=false --xcode=true --dotfiles=true --manual-apps=false --skip-existing=false --appstore-login=skip
  [ "$status" -eq 0 ]
  grep -q '^brew tap homebrew/core$' "$BATS_TEST_TMPDIR/side-effects.log"
  grep -q '^brew install wget$' "$BATS_TEST_TMPDIR/side-effects.log"
  grep -q '^brew install --cask visual-studio-code$' "$BATS_TEST_TMPDIR/side-effects.log"
  grep -q '^npm install -g typescript$' "$BATS_TEST_TMPDIR/side-effects.log"
  grep -q '^pip3 install black$' "$BATS_TEST_TMPDIR/side-effects.log"
  grep -q '^pipx install poetry$' "$BATS_TEST_TMPDIR/side-effects.log"
  grep -q '^xcode-select --install$' "$BATS_TEST_TMPDIR/side-effects.log"
  grep -q '^mas install 497799835$' "$BATS_TEST_TMPDIR/side-effects.log"
  [ -f "$BATS_TEST_TMPDIR/home/.tool-versions" ]
  ! grep -E ' uninstall| remove| delete| cleanup' "$BATS_TEST_TMPDIR/side-effects.log"
}
