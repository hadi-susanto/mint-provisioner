#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/install-target.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local download_url="https://dl.pstmn.io/download/latest/linux64"
    local archive_file
    local install_path
    local tag="pre-install:$canonical_id"

    install_path="$(resolve_install_target "$canonical_id" "$raw_install_path")" || return $?

    if ! archive_file="$(mktemp --suffix=.tar.gz)"; then
        tlog_error "$tag" "Failed to create a temporary archive"

        return 2
    fi

    if ! download_file "$canonical_id" "$download_url" "$archive_file"; then
        tlog_error "$tag" "Failed to download the Postman archive"
        rm -f -- "$archive_file"

        return 3
    fi

    if ! set_state "ARCHIVE_FILE" "$archive_file" ||
        ! save_states "$canonical_id"; then
        tlog_error "$tag" "Failed to save installation state"
        rm -f -- "$archive_file"

        return 4
    fi

    tlog_info "$tag" "Pre-install phase completed successfully"
}

main "$CANONICAL_ID" "${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}"
