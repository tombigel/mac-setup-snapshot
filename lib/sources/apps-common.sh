#!/usr/bin/env bash

mi_app_dirs() {
  if [ -n "${MI_APP_DIRS:-}" ]; then
    printf '%s\n' "$MI_APP_DIRS"
  else
    printf '%s\n' /Applications "$HOME/Applications"
  fi
}

mi_app_name_key() {
  printf '%s\n' "$1" | sed 's/\.app$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
}

mi_app_cask_key() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
}

mi_app_bundle_plist_value() {
  local app="$1"
  local key="$2"
  local plist="$app/Contents/Info.plist"
  [ -f "$plist" ] || return 1
  if [ -x /usr/libexec/PlistBuddy ]; then
    /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null && return 0
  fi
  defaults read "${plist%.plist}" "$key" 2>/dev/null
}

mi_app_bundle_mdls_value() {
  local app="$1"
  local key="$2"
  local value
  [ -x /usr/bin/mdls ] || return 1
  value="$(/usr/bin/mdls -name "$key" -raw "$app" 2>/dev/null || true)"
  case "$value" in
    ''|'(null)'|null|*'(null)'*) return 1 ;;
    *) printf '%s\n' "$value" ;;
  esac
}

mi_app_bundle_display_name() {
  local app="$1"
  mi_app_bundle_plist_value "$app" CFBundleDisplayName ||
    mi_app_bundle_plist_value "$app" CFBundleName ||
    basename "$app" .app
}

mi_app_bundle_id() {
  local app="$1"
  mi_app_bundle_plist_value "$app" CFBundleIdentifier ||
    mi_app_bundle_mdls_value "$app" kMDItemCFBundleIdentifier ||
    printf ''
}

mi_app_bundle_version() {
  local app="$1"
  mi_app_bundle_plist_value "$app" CFBundleShortVersionString ||
    mi_app_bundle_plist_value "$app" CFBundleVersion ||
    mi_app_bundle_mdls_value "$app" kMDItemVersion ||
    printf ''
}

mi_app_bundle_adam_id() {
  local app="$1"
  local adam_id
  adam_id="$(mi_app_bundle_mdls_value "$app" kMDItemAppStoreAdamID || true)"
  case "$adam_id" in
    ''|*[!0-9]*) printf '' ;;
    *) printf '%s\n' "$adam_id" ;;
  esac
}

mi_app_bundle_has_mas_receipt() {
  local app="$1"
  [ -f "$app/Contents/_MASReceipt/receipt" ]
}

mi_app_index_print() {
  local dir app name bundle_id version adam_id receipt
  mi_app_dirs | while IFS= read -r dir; do
    if [ ! -d "$dir" ]; then
      mi_verbose "apps: app directory missing: $dir"
      continue
    fi
    mi_verbose "apps: scanning app directory $dir"
    find "$dir" -maxdepth 1 -type d -name '*.app' 2>/dev/null | sort | while IFS= read -r app; do
      name="$(mi_app_bundle_display_name "$app")"
      bundle_id="$(mi_app_bundle_id "$app")"
      version="$(mi_app_bundle_version "$app")"
      adam_id="$(mi_app_bundle_adam_id "$app")"
      receipt="false"
      mi_app_bundle_has_mas_receipt "$app" && receipt="true"
      mi_verbose "apps: indexed $name path=$app bundle_id=${bundle_id:-unknown} version=${version:-unknown} appstore_id=${adam_id:-none} receipt=$receipt"
      printf '%s|%s|%s|%s|%s|%s\n' "$app" "$name" "$bundle_id" "$version" "$adam_id" "$receipt"
    done
  done
}

mi_app_index_ensure() {
  if [ -z "${MI_APP_INDEX_FILE:-}" ] || [ ! -f "$MI_APP_INDEX_FILE" ]; then
    MI_APP_INDEX_FILE="$(mktemp "${TMPDIR:-/tmp}/mac-setup-apps.XXXXXX")" || return 1
    export MI_APP_INDEX_FILE
    mi_verbose "apps: building installed app index at $MI_APP_INDEX_FILE"
    mi_app_index_print >"$MI_APP_INDEX_FILE"
    mi_verbose "apps: indexed $(wc -l <"$MI_APP_INDEX_FILE" | tr -d ' ') app bundle(s)"
  else
    mi_verbose "apps: reusing installed app index $MI_APP_INDEX_FILE"
  fi
}

mi_app_index_file() {
  mi_app_index_ensure || return 1
  printf '%s\n' "$MI_APP_INDEX_FILE"
}

mi_app_index_has_appstore_markers() {
  local index_file
  mi_app_index_ensure || return 1
  index_file="$MI_APP_INDEX_FILE"
  awk -F '|' '$5 != "" || $6 == "true" {found=1} END {exit found ? 0 : 1}' "$index_file"
}

mi_app_index_matches_appstore() {
  local id="$1"
  local name="$2"
  local bundle_id="$3"
  mi_app_index_match_appstore_row "$id" "$name" "$bundle_id" >/dev/null
}

mi_app_index_match_appstore_row() {
  local id="$1"
  local name="$2"
  local bundle_id="$3"
  local index_file name_key
  mi_app_index_ensure || return 1
  index_file="$MI_APP_INDEX_FILE"
  name_key="$(mi_app_name_key "$name")"
  awk -F '|' -v id="$id" -v name_key="$name_key" -v bundle_id="$bundle_id" '
    function key(value) {
      value = tolower(value)
      gsub(/\.app$/, "", value)
      gsub(/[^a-z0-9]/, "", value)
      return value
    }
    ($5 != "" && id != "" && $5 == id) ||
    ($3 != "" && bundle_id != "" && $3 == bundle_id) ||
    (($5 != "" || $6 == "true") && name_key != "" && key($2) == name_key) {
      found=1
      print
      exit
    }
    END {exit found ? 0 : 1}
  ' "$index_file"
}

mi_app_index_match_cask_row() {
  local cask="$1"
  local index_file cask_key
  [ -n "$cask" ] || return 1
  mi_app_index_ensure || return 1
  index_file="$MI_APP_INDEX_FILE"
  cask_key="$(mi_app_cask_key "$cask")"
  awk -F '|' -v cask_key="$cask_key" '
    function key(value) {
      value = tolower(value)
      gsub(/\.app$/, "", value)
      gsub(/[^a-z0-9]/, "", value)
      return value
    }
    key($2) == cask_key {
      print
      found=1
      exit
    }
    (index(key($2), cask_key) == 1 || index(cask_key, key($2)) == 1) && fallback == "" {
      fallback=$0
    }
    END {
      if (!found && fallback != "") {
        print fallback
      }
      exit (found || fallback != "") ? 0 : 1
    }
  ' "$index_file"
}

mi_app_is_appstore_app() {
  local adam_id="$1"
  local receipt="$2"
  [ -n "$adam_id" ] || [ "$receipt" = "true" ]
}
