#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local url="$2"
    local deb_file
    local tag="pre-install:$canonical_id"

    if ! deb_file="$(mktemp --suffix=.deb)"; then
        tlog_error "$tag" "Failed to create a temporary package file"

        return 1
    fi

    if ! download_file "$canonical_id" "$url" "$deb_file"; then
        tlog_error "$tag" "Failed to download the DbGate Community package"
        rm -f -- "$deb_file"

        return 2
    fi

    if ! set_state "DEB_FILE" "$deb_file" || ! save_states "$canonical_id"; then
        tlog_error "$tag" "Failed to save installation state"
        rm -f -- "$deb_file"

        return 3
    fi

    tlog_info "$tag" "Pre-install phase completed successfully"
}

main \
    "$CANONICAL_ID" \
    "https://github.com/dbgate/dbgate/releases/latest/download/dbgate-latest.deb"
