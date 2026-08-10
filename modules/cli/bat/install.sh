#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local deb_file
    local tag="install:$canonical_id"

    load_states "$canonical_id" || return 1
    deb_file="$(get_state "DEB_FILE")" || return 1

    if [[ ! -f "$deb_file" ]]; then
        tlog_error "$tag" "Package file not found: %s" "$deb_file"

        return 2
    fi

    if ! apt_install "$canonical_id" "$deb_file"; then
        tlog_error "$tag" "Package installation failed"

        return 3
    fi

    add_system_toolkit_message "$canonical_id"
    tlog_info "$tag" "Package installed successfully"
}

main "$CANONICAL_ID"
