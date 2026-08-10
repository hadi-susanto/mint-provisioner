#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/symlink.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local archive_file
    local install_path
    local tag="install:$canonical_id"

    load_states "$canonical_id" || return 1
    archive_file="$(get_state "ARCHIVE_FILE")" || return 1

    if [[ ! -f "$archive_file" ]]; then
        tlog_error "$tag" "Archive file not found: %s" "$archive_file"

        return 2
    fi

    install_path="$(expand_path "$raw_install_path")" || return $?
    if ! mkdir -p -- "$install_path"; then
        tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

        return 3
    fi

    if ! tar --overwrite -xzf "$archive_file" -C "$install_path" --strip-components=1; then
        tlog_error "$tag" "Failed to extract delta into: %s" "$install_path"

        return 4
    fi

    if ! chmod +x "$install_path/delta"; then
        tlog_error "$tag" "Failed to make delta executable"

        return 5
    fi

    if [[ "$install_path" != "$(symlink_location)" ]]; then
        symlink_binary "$canonical_id" "$install_path/delta" || return 6
    fi

    set_registry "INSTALL_PATH" "$install_path" || return 7
    save_registry "$canonical_id" || return 7
    add_system_toolkit_message "$canonical_id"

    tlog_info "$tag" "Installation completed successfully"
}

main "$CANONICAL_ID" "${DELTA_INSTALL_DIR:-$INSTALL_DIR/delta}"
