#!/usr/bin/env zsh

pipx_backup() {
  local fields line name version
  printf 'pipx:\n'
  printf '  packages:\n'
  if ! mi_has pipx; then
    return 0
  fi
  pipx list --short 2>/dev/null | while IFS= read -r line; do
    [ -n "$line" ] || continue
    fields=("${(@s: :)line}")
    name="${fields[1]}"
    version="${fields[2]:-}"
    [ -n "$name" ] || continue
    printf '    - name: %s\n' "$(mi_yaml_scalar "$name")"
    printf '      ref: %s\n' "$(mi_yaml_scalar "$(mi_pipx_ref "$name")")"
    printf '      version: %s\n' "$(mi_yaml_scalar "$version")"
  done
}

pipx_restore() {
  local rows name ref ignored
  mi_has pipx || mi_install_brew_tool_if_allowed pipx pipx || { mi_warn "pipx missing; skipping pipx restore"; return 0; }
  rows="$(yq e -r '
    (.pipx.packages // [])[]? |
    (.name // "" | tostring) + "|" + (.ref // "" | tostring) + "|" + (.ignored // false | tostring)
  ' "$MI_INVENTORY" 2>/dev/null || true)"
  printf '%s\n' "$rows" | while IFS="|" read -r name ref ignored; do
    [ -n "$name" ] && [ "$name" != "null" ] || continue
    if [ "$ignored" = "true" ]; then
      mi_info "pipx: ignored ${ref:-$name}; skipping"
      continue
    fi
    mi_validate_identifier "$name" || { mi_warn "invalid pipx package: $name"; continue; }
    if pipx list --short 2>/dev/null | awk '{print $1}' | grep -Fxq "$name" && [ "$MI_SKIP_EXISTING" = "true" ]; then
      mi_info "pipx: $name already installed"
    else
      mi_run pipx install "$name"
    fi
  done
}
