#!/usr/bin/env zsh

pip_backup() {
  printf 'pip:\n'
  printf '  packages:\n'
  if ! mi_has pip3; then
    return 0
  fi
  pip3 list --format=freeze 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      *"=="*) name="${line%%==*}"; version="${line#*==}" ;;
      *) name="$line"; version="" ;;
    esac
    [ -n "$name" ] || continue
    printf '    - name: %s\n' "$(mi_yaml_scalar "$name")"
    printf '      ref: %s\n' "$(mi_yaml_scalar "$(mi_pip_ref "$name")")"
    printf '      version: %s\n' "$(mi_yaml_scalar "$version")"
  done
}

pip_restore() {
  local rows name ref ignored
  mi_has pip3 || { mi_warn "pip3 missing; skipping pip restore"; return 0; }
  rows="$(yq e -r '
    (.pip.packages // [])[]? |
    (.name // "" | tostring) + "|" + (.ref // "" | tostring) + "|" + (.ignored // false | tostring)
  ' "$MI_INVENTORY" 2>/dev/null || true)"
  printf '%s\n' "$rows" | while IFS="|" read -r name ref ignored; do
    [ -n "$name" ] && [ "$name" != "null" ] || continue
    if [ "$ignored" = "true" ]; then
      mi_info "pip: ignored ${ref:-$name}; skipping"
      continue
    fi
    mi_validate_identifier "$name" || { mi_warn "invalid pip package: $name"; continue; }
    if pip3 show "$name" >/dev/null 2>&1 && [ "$MI_SKIP_EXISTING" = "true" ]; then
      mi_info "pip: $name already installed"
    else
      mi_run pip3 install "$name"
    fi
  done
}
