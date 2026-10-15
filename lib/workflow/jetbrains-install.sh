#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_INSTALL_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_INSTALL_LOADED=1

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_WORKFLOW/stateful-extract-install.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local product_name="$3"
    local product_keyword="$4"
    local tag="install:$canonical_id"
    local module_id="${canonical_id##*/}"
    local install_path

    load_states "$canonical_id" || return $?
    tlog_info "$tag" "Begin %s installation" "$product_name"
    install_path="$(expand_path "$raw_install_path")" || return $?

    stateful_extract_install \
        "$canonical_id" \
        "JETBRAINS_ARCHIVE_FILE" \
        "tar.gz" \
        "$install_path" \
        "bin/$module_id" \
        "$module_id" \
        -- \
        "--strip-components=1" || return $?

    install_desktop_entry "$canonical_id" "$module_id" "$product_name" "$(symlink_location)/$module_id" \
        --exec-args "%f" \
        --comment "Develop software with $product_name" \
        --icon-file "$install_path/bin/$module_id.svg" \
        --startup-notify 1 \
        --categories "Development;IDE;" \
        --keywords "Development;IDE;Editor;JetBrains;$product_keyword;"
}
