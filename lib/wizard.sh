#!/usr/bin/env bash

MI_WIZARD_DEFAULT_BACKUP_SOURCES="apps|App Store apps|true
brew|Homebrew|true
npm|npm globals|true
pip|pip packages|true
pipx|pipx packages|true
oh_my_zsh|Oh My Zsh|true
xcode|Xcode|true
dotfiles|dotfiles|true
manual_apps|manual apps|true"

MI_WIZARD_DEFAULT_RESTORE_SOURCES="apps|App Store apps|true
brew|Homebrew|true
npm|npm globals|true
pip|pip packages|true
pipx|pipx packages|true
oh_my_zsh|Oh My Zsh|true
xcode|Xcode|true
dotfiles|dotfiles|true
manual_apps|manual apps|true"

mi_wizard_valid_flow() {
  case "$1" in
    backup|restore) return 0 ;;
    *) return 1 ;;
  esac
}

mi_wizard_valid_source() {
  case "$1" in
    apps|brew|npm|pip|pipx|oh_my_zsh|xcode|dotfiles|manual_apps) return 0 ;;
    *) return 1 ;;
  esac
}

mi_wizard_valid_prompt() {
  local flow="$1"
  local prompt="$2"
  case "$flow:$prompt" in
    backup:dry_run|backup:storage|backup:sources|backup:manual_brew_match) return 0 ;;
    restore:dry_run|restore:storage|restore:sources|restore:appstore_login) return 0 ;;
    *) return 1 ;;
  esac
}

mi_wizard_source_var() {
  case "$1" in
    apps) printf 'MI_APPS' ;;
    brew) printf 'MI_BREW' ;;
    npm) printf 'MI_NPM' ;;
    pip) printf 'MI_PIP' ;;
    pipx) printf 'MI_PIPX' ;;
    oh_my_zsh) printf 'MI_OH_MY_ZSH' ;;
    xcode) printf 'MI_XCODE' ;;
    dotfiles) printf 'MI_DOTFILES' ;;
    manual_apps) printf 'MI_MANUAL_APPS' ;;
    *) return 1 ;;
  esac
}

mi_wizard_default_sources() {
  case "$1" in
    backup) printf '%s\n' "$MI_WIZARD_DEFAULT_BACKUP_SOURCES" ;;
    restore) printf '%s\n' "$MI_WIZARD_DEFAULT_RESTORE_SOURCES" ;;
    *) return 1 ;;
  esac
}

mi_wizard_config_generate() {
  local output
  output="${MI_OUTPUT:-$MI_WIZARD_CONFIG}"
  [ -n "$output" ] || output="mac-setup.wizard.yml"

  if [ "$MI_DRY_RUN" = "true" ]; then
    mi_info "dry-run: would write wizard config to $output"
    return 0
  fi

  if [ -e "$output" ] && ! mi_prompt_yes_no "Overwrite existing wizard config $output?" "no"; then
    mi_error "wizard config not written"
    return 1
  fi

  mi_mkdir_parent "$output"
  mi_wizard_default_config_content >"$output"
  mi_info "wrote $output"
}

mi_wizard_default_config_content() {
  cat <<'EOF'
version: 1
wizard:
  flows:
    backup:
      enabled: true
      label: "Create or update a setup snapshot"
      default_target: icloud
      prompts:
        dry_run: true
        storage: true
        sources: true
        manual_brew_match: true
      sources:
        - id: apps
          label: "App Store apps"
          default: true
        - id: brew
          label: "Homebrew"
          default: true
        - id: npm
          label: "npm globals"
          default: true
        - id: pip
          label: "pip packages"
          default: true
        - id: pipx
          label: "pipx packages"
          default: true
        - id: oh_my_zsh
          label: "Oh My Zsh"
          default: true
        - id: xcode
          label: "Xcode"
          default: true
        - id: dotfiles
          label: "dotfiles"
          default: true
        - id: manual_apps
          label: "manual apps"
          default: true

    restore:
      enabled: true
      label: "Restore from a setup snapshot"
      default_source: icloud
      prompts:
        dry_run: true
        storage: true
        sources: true
        appstore_login: true
      sources:
        - id: apps
          label: "App Store apps"
          default: true
        - id: brew
          label: "Homebrew"
          default: true
        - id: npm
          label: "npm globals"
          default: true
        - id: pip
          label: "pip packages"
          default: true
        - id: pipx
          label: "pipx packages"
          default: true
        - id: oh_my_zsh
          label: "Oh My Zsh"
          default: true
        - id: xcode
          label: "Xcode"
          default: true
        - id: dotfiles
          label: "dotfiles"
          default: true
        - id: manual_apps
          label: "manual apps"
          default: true
EOF
}
